extends Control

# Colors
const C_BG_DARK     := Color(0.98, 0.97, 0.93, 1.0)
const C_RED_SON     := Color(0.09, 0.27, 0.18, 1.0)
const C_RED_SON_DK  := Color(0.05, 0.16, 0.11, 0.96)
const C_RED_ERR     := Color(0.70, 0.12, 0.08, 1.0)
const C_GOLD        := Color(0.77, 0.58, 0.15, 1.0)
const C_GOLD_LIGHT  := Color(0.95, 0.82, 0.45, 1.0)
const C_JADE        := Color(0.12, 0.37, 0.23, 1.0)
const C_JADE_LIGHT  := Color(0.18, 0.58, 0.38, 1.0)
const C_CREAM       := Color(1.00, 0.97, 0.88, 1.0)
const C_CREAM_DIM   := Color(0.80, 0.76, 0.66, 1.0)

const C_BG         := Color(0.98, 0.97, 0.93, 1.0)
const C_BG_BAR     := Color(0.95, 0.93, 0.89, 1.0)
const C_CARD       := Color(1.00, 1.00, 1.00, 1.0)
const C_TEXT       := Color(0.13, 0.08, 0.05, 1.0)
const C_TEXT_MUTED := Color(0.43, 0.38, 0.33, 1.0)

# Notes mapping to frequencies
const NOTES = ["Đô", "Rê", "Mi", "Fa", "Sol", "La", "Si"]
const FREQS = {
	"Đô": 261.63,     # C4
	"Rê": 293.66,     # D4
	"Mi": 329.63,     # E4
	"Fa": 349.23,     # F4
	"Sol": 392.00,    # G4
	"La": 440.00,     # A4
	"Si": 493.88      # B4
}

# State
var current_round := 1
var max_rounds := 5
var correct_answers := 0
var score := 0
var correct_note := ""
var options : Array[String] = []
var game_active := true

# Refs
@onready var round_label   : Label = $Root/Card/CardM/GameVBox/HeaderRow/RoundLabel
@onready var score_label   : Label = $Root/Card/CardM/GameVBox/HeaderRow/ScoreLabel
@onready var prompt_label  : Label = $Root/Card/CardM/GameVBox/PromptLabel
@onready var play_btn      : Button = $Root/Card/CardM/GameVBox/PlayCircle/PlayBtn
@onready var option_grid   : GridContainer = $Root/Card/CardM/GameVBox/OptionsGrid
@onready var result_lbl    : Label = $Root/Card/CardM/GameVBox/FeedbackPanel/FeedbackM/FeedbackLabel
@onready var feedback_pan  : PanelContainer = $Root/Card/CardM/GameVBox/FeedbackPanel
@onready var back_btn      : Button = $Root/TopBar/TopM/TopH/BackBtn

func _ready() -> void:
	if has_node("BG"):
		get_node("BG").queue_free()
		
	_build_theme()
	_connect_buttons()
	_start_new_round()
	
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.35)

	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()

func _draw() -> void:
	# Draw Mahogany heritage background
	draw_rect(Rect2(Vector2.ZERO, size), C_BG_DARK)

func _build_theme() -> void:
	# Top bar
	var top_s := _flat(C_BG_BAR, Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.15), 0)
	top_s.border_width_bottom = 2
	$Root/TopBar.add_theme_stylebox_override("panel", top_s)
	
	$Root/TopBar/TopM/TopH/Title.add_theme_color_override("font_color", C_RED_SON)
	
	# Back Button
	var btn_s := _flat(C_CARD, C_RED_SON, 16, true, 2)
	back_btn.add_theme_stylebox_override("normal", btn_s)
	back_btn.add_theme_stylebox_override("hover", _flat(C_CARD, C_RED_SON.lightened(0.15), 16, true, 2))
	back_btn.add_theme_stylebox_override("pressed", _flat(C_BG_BAR, C_RED_SON, 16, false, 1))
	back_btn.add_theme_color_override("font_color", C_TEXT)
	
	# Main Game Card
	var card_s := _flat(C_CARD, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35), 28, true, 4)
	$Root/Card.add_theme_stylebox_override("panel", card_s)
	
	# Header styling
	round_label.add_theme_color_override("font_color", C_RED_SON)
	score_label.add_theme_color_override("font_color", C_JADE)
	prompt_label.add_theme_color_override("font_color", C_TEXT)
	
	# Play sound button circle 3D
	var play_s := _flat(C_GOLD, C_GOLD_LIGHT, 64, true, 4)
	$Root/Card/CardM/GameVBox/PlayCircle.add_theme_stylebox_override("panel", play_s)
	play_btn.add_theme_color_override("font_color", Color(1,1,1,1))
	
	# Feedback panel
	var feed_s := _flat(C_BG_BAR, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35), 16)
	feedback_pan.add_theme_stylebox_override("panel", feed_s)
	result_lbl.add_theme_color_override("font_color", C_TEXT)
	feedback_pan.visible = false

func _connect_buttons() -> void:
	back_btn.pressed.connect(_go_back)
	_make_button_bouncy(back_btn)
	
	play_btn.pressed.connect(_play_correct_sound)
	_make_button_bouncy(play_btn)

func _go_back() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.22)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/CourseMap.tscn"))

func _start_new_round() -> void:
	if current_round > max_rounds:
		_show_end_summary()
		return
		
	game_active = true
	feedback_pan.visible = false
	round_label.text = "VÒNG HỌC: %d / %d" % [current_round, max_rounds]
	score_label.text = "ĐIỂM: %d" % score
	
	# Pick a correct note
	correct_note = NOTES[randi() % NOTES.size()]
	
	# Build options (4 unique options)
	options.clear()
	options.append(correct_note)
	
	while options.size() < 4:
		var extra = NOTES[randi() % NOTES.size()]
		if not options.has(extra):
			options.append(extra)
			
	options.shuffle()
	
	# Rebuild option buttons dynamically
	for child in option_grid.get_children():
		child.queue_free()
		
	var is_mobile = get_viewport().size.x < get_viewport().size.y or get_viewport().size.x < 768
	for opt in options:
		var btn := Button.new()
		btn.text = opt
		btn.custom_minimum_size = Vector2(280, 56) if is_mobile else Vector2(220, 68)
		btn.add_theme_font_size_override("font_size", 18 if is_mobile else 22)
		
		# Build gorgeous bubble styleboxes for options
		var b_n := _flat(C_CARD, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45), 20, true, 3)
		var b_h := _flat(C_CARD, C_RED_SON, 20, true, 3)
		var b_p := _flat(C_BG_BAR, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45), 20, false, 1)
		
		btn.add_theme_stylebox_override("normal", b_n)
		btn.add_theme_stylebox_override("hover", b_h)
		btn.add_theme_stylebox_override("pressed", b_p)
		btn.add_theme_stylebox_override("focus", _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
		
		btn.add_theme_color_override("font_color", C_TEXT)
		btn.add_theme_color_override("font_hover_color", C_RED_SON)
		btn.add_theme_color_override("font_pressed_color", C_TEXT)
		
		btn.pressed.connect(func() -> void: _submit_answer(opt, btn))
		_make_button_bouncy(btn)
		option_grid.add_child(btn)
		
	# Play sound automatically
	get_tree().create_timer(0.4).timeout.connect(_play_correct_sound)

func _play_correct_sound() -> void:
	if not FREQS.has(correct_note): return
	_play_synth_note(FREQS[correct_note])

func _play_synth_note(freq: float) -> void:
	# Real-time procedural sinewave DSP synthesiser!
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 44100
	stream.buffer_length = 0.5
	
	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	player.play()
	
	var playback : AudioStreamGeneratorPlayback = player.get_stream_playback()
	if playback:
		var sample_count := int(44100 * 0.45)
		var increment := freq * TAU / 44100.0
		var phase := 0.0
		
		var frames := PackedVector2Array()
		for i in range(sample_count):
			# Damping amplitude over time for a nice instrument pluck decay!
			var decay = 1.0 - (float(i) / float(sample_count))
			var sample = sin(phase) * 0.3 * decay
			frames.append(Vector2(sample, sample))
			phase += increment
			
		playback.push_buffer(frames)
		
	# Clean up player after sound completes
	get_tree().create_timer(0.55).timeout.connect(player.queue_free)

func _submit_answer(ans: String, btn: Button) -> void:
	if not game_active: return
	game_active = false
	
	var is_correct = ans == correct_note
	
	if is_correct:
		correct_answers += 1
		score += 100
		_play_synth_note(523.25) # Play high correct tone!
		
		# Bouncy win effect
		var t := create_tween()
		t.tween_property(btn, "scale", Vector2(1.12, 1.12), 0.12).set_trans(Tween.TRANS_BACK)
		t.tween_property(btn, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)
		
		btn.add_theme_stylebox_override("normal", _flat(C_JADE, Color(0.35, 0.85, 0.60, 0.6), 20, true, 3))
		btn.add_theme_color_override("font_color", Color(1,1,1,1))
		
		result_lbl.text = "Rất xuất sắc! Chúc mừng bạn gán đúng nốt."
		feedback_pan.add_theme_stylebox_override("panel", _flat(C_JADE, Color(0.35, 0.85, 0.60, 0.6), 16))
	else:
		_play_synth_note(130.81) # Play low wrong tone!
		
		# Shaking mistake effect
		var t := create_tween()
		var ox = btn.position.x
		t.tween_property(btn, "position:x", ox - 10.0, 0.05)
		t.tween_property(btn, "position:x", ox + 10.0, 0.05)
		t.tween_property(btn, "position:x", ox,        0.05)
		
		btn.add_theme_stylebox_override("normal", _flat(C_RED_ERR, Color(1,1,1,0.2), 20, true, 3))
		btn.add_theme_color_override("font_color", Color(1,1,1,1))
		
		# Highlight the correct one
		for c in option_grid.get_children():
			var opt_btn = c as Button
			if opt_btn and opt_btn.text == correct_note:
				opt_btn.add_theme_stylebox_override("normal", _flat(C_JADE, Color(0.35, 0.85, 0.60, 0.6), 20, true, 3))
				opt_btn.add_theme_color_override("font_color", Color(1,1,1,1))
				
		result_lbl.text = "Tiếc quá! Hãy gập lại hơi và lắng nghe nốt."
		feedback_pan.add_theme_stylebox_override("panel", _flat(C_BG_BAR, Color(C_RED_ERR.r, C_RED_ERR.g, C_RED_ERR.b, 0.25), 16))
		
	feedback_pan.visible = true
	
	# Advance to next round after delay
	get_tree().create_timer(1.8).timeout.connect(func() -> void:
		current_round += 1
		_start_new_round()
	)

func _show_end_summary() -> void:
	option_grid.visible = false
	prompt_label.visible = false
	$Root/Card/CardM/GameVBox/PlayCircle.visible = false
	
	round_label.text = "KẾT THÚC THỬ THÁCH"
	score_label.text = "ĐIỂM CHUNG CUỘC: %d" % score
	
	feedback_pan.visible = true
	feedback_pan.add_theme_stylebox_override("panel", _flat(C_GOLD, C_GOLD_LIGHT, 20, true, 4))
	
	# Save progress points secure offline!
	var inst := InstrumentSelect.selected_instrument
	if score >= 300:
		SecureDataManager.complete_lesson(inst, "Node3", 3) # Unlocks Node 4!
		result_lbl.text = "Bạn đạt được %d điểm! Rất đáng khen ngợi.\n+ 300 XP  ·  Mở Khóa Học Tiếp!" % score
	else:
		result_lbl.text = "Bạn đạt được %d điểm! Hãy cố gắng luyện tập thêm tai nhạc nữa nhé." % score
		
	result_lbl.add_theme_color_override("font_color", C_TEXT)
	
	# Re-style play button to go back
	var btn := Button.new()
	btn.text = "Quay Lại Bản Đồ"
	btn.custom_minimum_size = Vector2(280, 68)
	var is_mobile_end = get_viewport().size.x < get_viewport().size.y or get_viewport().size.x < 768
	btn.add_theme_font_size_override("font_size", 18 if is_mobile_end else 22)
	btn.add_theme_stylebox_override("normal", _flat(C_RED_SON, C_GOLD, 20, true, 3))
	btn.add_theme_stylebox_override("hover", _flat(C_RED_SON_DK, C_GOLD_LIGHT, 20, true, 3))
	btn.add_theme_color_override("font_color", Color(1,1,1,1))
	btn.pressed.connect(_go_back)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_make_button_bouncy(btn)
	$Root/Card/CardM/GameVBox.add_child(btn)

func _flat(bg: Color, border: Color, radius: int, shadow: bool = false, offset_bottom: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.border_color = border
	s.border_width_left = 3
	s.border_width_right = 3
	s.border_width_top  = 3
	s.border_width_bottom = 3 + offset_bottom
	s.corner_radius_top_left     = radius; s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius; s.corner_radius_bottom_right = radius
	if shadow:
		s.shadow_size = 6
		s.shadow_color = Color(0, 0, 0, 0.22)
		s.shadow_offset = Vector2(0, 4)
	return s

func _make_button_bouncy(btn: Button) -> void:
	btn.pivot_offset = btn.size / 2.0
	btn.resized.connect(func() -> void: btn.pivot_offset = btn.size / 2.0)
	btn.mouse_entered.connect(func() -> void:
		var t := create_tween()
		t.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func() -> void:
		var t := create_tween()
		t.tween_property(btn, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	btn.button_down.connect(func() -> void:
		var t := create_tween()
		t.tween_property(btn, "scale", Vector2(0.95, 0.95), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	btn.button_up.connect(func() -> void:
		var t := create_tween()
		t.tween_property(btn, "scale", Vector2(1.05, 1.05) if btn.is_hovered() else Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)

func _on_viewport_size_changed() -> void:
	var size = get_viewport().size
	var is_mobile = size.x < size.y or size.x < 768
	
	# Reflow Card size
	var card := $Root/Card as PanelContainer
	if is_mobile:
		card.custom_minimum_size = Vector2(size.x - 32, 0)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		card.custom_minimum_size = Vector2(1000, 640)
		card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	# Options grid columns reflow
	option_grid.columns = 1 if is_mobile else 2

	# UI Margins and spacing adjustments
	if is_mobile:
		$Root/TopBar/TopM.add_theme_constant_override("margin_left", 16)
		$Root/TopBar/TopM.add_theme_constant_override("margin_right", 16)
		$Root/Card/CardM.add_theme_constant_override("margin_left", 16)
		$Root/Card/CardM.add_theme_constant_override("margin_right", 16)
		$Root/Card/CardM.add_theme_constant_override("margin_top", 20)
		$Root/Card/CardM.add_theme_constant_override("margin_bottom", 20)
		
		$Root/TopBar/TopM/TopH/Title.add_theme_font_size_override("font_size", 18)
		round_label.add_theme_font_size_override("font_size", 16)
		score_label.add_theme_font_size_override("font_size", 16)
		prompt_label.add_theme_font_size_override("font_size", 16)
		result_lbl.add_theme_font_size_override("font_size", 16)
		
		# Shrink BackBtn on mobile
		back_btn.custom_minimum_size = Vector2(120, 40)
		back_btn.add_theme_font_size_override("font_size", 14)
	else:
		$Root/TopBar/TopM.add_theme_constant_override("margin_left", 48)
		$Root/TopBar/TopM.add_theme_constant_override("margin_right", 48)
		$Root/Card/CardM.add_theme_constant_override("margin_left", 48)
		$Root/Card/CardM.add_theme_constant_override("margin_right", 48)
		$Root/Card/CardM.add_theme_constant_override("margin_top", 32)
		$Root/Card/CardM.add_theme_constant_override("margin_bottom", 32)
		
		$Root/TopBar/TopM/TopH/Title.add_theme_font_size_override("font_size", 26)
		round_label.add_theme_font_size_override("font_size", 22)
		score_label.add_theme_font_size_override("font_size", 22)
		prompt_label.add_theme_font_size_override("font_size", 24)
		result_lbl.add_theme_font_size_override("font_size", 20)
		
		back_btn.custom_minimum_size = Vector2(180, 48)
		back_btn.add_theme_font_size_override("font_size", 20)
