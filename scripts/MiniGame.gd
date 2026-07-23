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

# Pentatonic melodies for Melody Matcher
const MELODIES = [
	["Đô", "Rê", "Mi", "Sol", "La"],
	["Rê", "Mi", "Sol", "La", "Đô"],
	["Mi", "Sol", "La", "Đô", "Rê"],
	["Sol", "La", "Đô", "Rê", "Mi"],
	["La", "Đô", "Rê", "Mi", "Sol"]
]

# State
var current_round := 1
var max_rounds := 5
var correct_answers := 0
var score := 0
var correct_note := ""
var options : Array[String] = []
var game_active := true

# Game mode selection
var game_mode := "" # "", "note", "rhythm", "melody"

# Rhythm challenge state
var rhythm_active := false
var cursor_pos := 0.0
var rhythm_speed := 0.4
var target_beats : Array = []
var hit_beats : Array = []
var rhythm_sweep_count := 0

# Background texture
var bg_texture: Texture2D = null

# Melody matcher state
var melody_notes : Array[String] = []
var missing_idx := -1
var is_playing_melody := false
var current_play_index := -1
var melody_timer : Timer = null

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
		
	SecureDataManager.load_data()
	
	var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
	if inst == "dan_tranh":
		bg_texture = load("res://assets/textures/dan_tranh_background.png") as Texture2D
	elif inst == "sao_truc":
		bg_texture = load("res://assets/textures/sao_truc_background.png") as Texture2D
		
	_build_theme()
	_connect_buttons()
	_show_mode_selection_menu()
	
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.35)

	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()

func _draw() -> void:
	var sz := get_rect().size
	if bg_texture:
		# Draw the texture covering the screen (like expand_mode = ignore / stretch_mode = cover)
		# Actually, just drawing the rect with the texture is fine, but it might stretch if aspect differs.
		# For simplicity, we draw the texture scaled to fit.
		var tex_size := bg_texture.get_size()
		var scale_factor := maxf(sz.x / tex_size.x, sz.y / tex_size.y)
		var draw_size := tex_size * scale_factor
		var draw_pos := (sz - draw_size) / 2.0
		draw_texture_rect(bg_texture, Rect2(draw_pos, draw_size), false)
		
		# Draw a semi-transparent overlay to keep contrast
		draw_rect(Rect2(Vector2.ZERO, sz), Color(1.0, 0.98, 0.95, 0.85))
	else:
		draw_rect(Rect2(Vector2.ZERO, sz), C_BG_DARK)

func _process(delta: float) -> void:
	if game_mode == "rhythm" and rhythm_active:
		cursor_pos += delta * rhythm_speed
		
		if cursor_pos >= 1.0:
			cursor_pos = 0.0
			# Reset hit beats for the next sweep
			for i in range(hit_beats.size()):
				hit_beats[i] = false
				
			rhythm_sweep_count += 1
			_show_rhythm_feedback("Nhịp quét mới!", Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.7))
				
			if rhythm_sweep_count >= 3:
				_end_rhythm_round()
				
		var timeline = $Root/Card/CardM/GameVBox/RhythmTimeline as Control
		if timeline:
			timeline.queue_redraw()

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
	if game_mode != "":
		_show_mode_selection_menu()
	else:
		var t := create_tween()
		t.tween_property(self, "modulate:a", 0.0, 0.22)
		t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))

func _clear_game_ui() -> void:
	$Root/Card/CardM/GameVBox/HeaderRow.visible = false
	$Root/Card/CardM/GameVBox/PromptLabel.visible = false
	$Root/Card/CardM/GameVBox/PlayCircle.visible = false
	$Root/Card/CardM/GameVBox/OptionsGrid.visible = false
	$Root/Card/CardM/GameVBox/FeedbackPanel.visible = false
	
	rhythm_active = false
	is_playing_melody = false
	if melody_timer and is_instance_valid(melody_timer):
		melody_timer.stop()
		
	for child in $Root/Card/CardM/GameVBox.get_children():
		if child.name in ["MenuContainer", "RhythmTimeline", "DrumBtn", "MelodyCards", "RhythmFeedbackLabel", "EndSummaryBtn"]:
			child.queue_free()

func _show_mode_selection_menu() -> void:
	_clear_game_ui()
	game_mode = ""
	
	SecureDataManager.load_data()
	var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
	var inst_title := ""
	var rhythm_desc := ""
	var note_desc := ""
	var melody_desc := ""
	
	match inst:
		"dan_tranh":
			inst_title = "ĐÀN TRANH"
			rhythm_desc = "Gảy phím Đàn Tranh theo nhịp điệu khi vạch quét di chuyển qua các điểm nhịp."
			note_desc = "Lắng nghe âm sắc Đàn Tranh và đoán tên nốt nhạc ngũ cung tương ứng."
			melody_desc = "Lắng nghe chuỗi ngũ cung Đàn Tranh và tìm nốt nhạc còn thiếu [?] trong giai điệu."
		"sao_truc":
			inst_title = "SÁO TRÚC"
			rhythm_desc = "Thổi hơi Sáo Trúc theo nhịp điệu khi vạch quét di chuyển qua các điểm nhịp."
			note_desc = "Lắng nghe âm sắc Sáo Trúc và đoán tên nốt nhạc ngũ cung tương ứng."
			melody_desc = "Lắng nghe chuỗi ngũ cung Sáo Trúc và tìm nốt nhạc còn thiếu [?] trong giai điệu."
		"trong_chau":
			inst_title = "TRỐNG CHẦU"
			rhythm_desc = "Gõ mặt/vành Trống Chầu theo nhịp điệu khi vạch quét di chuyển qua các điểm nhịp."
			note_desc = "Lắng nghe âm sắc Trống Chầu (Tịch/Cắc) và đoán âm tương ứng."
			melody_desc = "Lắng nghe chuỗi tiết tấu Trống Chầu và tìm âm còn thiếu [?] trong chuỗi."
		"dan_bau", _:
			inst_title = "ĐÀN BẦU"
			rhythm_desc = "Uốn cần Đàn Bầu theo nhịp điệu khi vạch quét di chuyển qua các điểm nhịp."
			note_desc = "Lắng nghe âm bồi Đàn Bầu và đoán tên nốt nhạc ngũ cung tương ứng."
			melody_desc = "Lắng nghe chuỗi ngũ cung Đàn Bầu và tìm nốt nhạc còn thiếu [?] trong giai điệu."
			
	$Root/TopBar/TopM/TopH/Title.text = "TRÒ CHƠI NHỎ - " + inst_title
	prompt_label.text = "Chọn một trò chơi dưới đây để rèn luyện kỹ năng âm nhạc của bạn:"
	prompt_label.visible = true
	
	var is_mobile = get_viewport().size.x < get_viewport().size.y or get_viewport().size.x < 768
	
	var menu_container = BoxContainer.new()
	menu_container.name = "MenuContainer"
	menu_container.vertical = is_mobile
	menu_container.add_theme_constant_override("separation", 24)
	menu_container.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var modes_info = [
		{
			"id": "rhythm",
			"title": "Thử Thách Nhịp Điệu",
			"desc": rhythm_desc
		},
		{
			"id": "note",
			"title": "Nhận Diện Nốt Nhạc",
			"desc": note_desc
		},
		{
			"id": "melody",
			"title": "Hoàn Thiện Giai Điệu",
			"desc": melody_desc
		}
	]
	
	for m in modes_info:
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(280, 240) if is_mobile else Vector2(270, 360)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var card_s := _flat(C_CREAM, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.4), 24, true, 3)
		card.add_theme_stylebox_override("panel", card_s)
		
		var card_m := MarginContainer.new()
		card_m.add_theme_constant_override("margin_left", 20)
		card_m.add_theme_constant_override("margin_right", 20)
		card_m.add_theme_constant_override("margin_top", 20)
		card_m.add_theme_constant_override("margin_bottom", 20)
		card.add_child(card_m)
		
		var card_v := VBoxContainer.new()
		card_v.add_theme_constant_override("separation", 16)
		card_v.alignment = BoxContainer.ALIGNMENT_CENTER
		card_m.add_child(card_v)
		
		var title_lbl := Label.new()
		title_lbl.text = m["title"]
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		title_lbl.add_theme_font_size_override("font_size", 18 if is_mobile else 22)
		title_lbl.add_theme_color_override("font_color", C_RED_SON)
		card_v.add_child(title_lbl)
		
		var desc_lbl := Label.new()
		desc_lbl.text = m["desc"]
		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_lbl.add_theme_font_size_override("font_size", 12 if is_mobile else 14)
		desc_lbl.add_theme_color_override("font_color", C_TEXT_MUTED)
		card_v.add_child(desc_lbl)
		
		var spacer = Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card_v.add_child(spacer)
		
		var play_btn_card := Button.new()
		play_btn_card.text = "Chơi Ngay"
		play_btn_card.custom_minimum_size = Vector2(0, 48)
		play_btn_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		play_btn_card.add_theme_font_size_override("font_size", 14 if is_mobile else 16)
		
		var btn_normal = _flat(C_RED_SON, C_GOLD, 16, true, 2)
		var btn_hover = _flat(C_RED_SON_DK, C_GOLD_LIGHT, 16, true, 2)
		var btn_pressed = _flat(C_RED_SON, C_GOLD, 16, false, 1)
		
		play_btn_card.add_theme_stylebox_override("normal", btn_normal)
		play_btn_card.add_theme_stylebox_override("hover", btn_hover)
		play_btn_card.add_theme_stylebox_override("pressed", btn_pressed)
		play_btn_card.add_theme_color_override("font_color", Color.WHITE)
		play_btn_card.add_theme_color_override("font_hover_color", C_GOLD_LIGHT)
		
		var mode_id = m["id"]
		play_btn_card.pressed.connect(func() -> void: _start_game_mode(mode_id))
		_make_button_bouncy(play_btn_card)
		card_v.add_child(play_btn_card)
		
		card.gui_input.connect(func(e: InputEvent) -> void:
			if e is InputEventMouseButton and e.pressed:
				_start_game_mode(mode_id)
		)
		
		card.pivot_offset = Vector2(140, 180) if not is_mobile else Vector2(140, 120)
		card.mouse_entered.connect(func() -> void:
			var t := create_tween().set_parallel(true)
			t.tween_property(card, "scale", Vector2(1.04, 1.04), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			card.add_theme_stylebox_override("panel", _flat(C_CREAM, C_GOLD_LIGHT, 24, true, 5))
		)
		card.mouse_exited.connect(func() -> void:
			var t := create_tween().set_parallel(true)
			t.tween_property(card, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			card.add_theme_stylebox_override("panel", _flat(C_CREAM, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.4), 24, true, 3))
		)
		
		menu_container.add_child(card)
		
	$Root/Card/CardM/GameVBox.add_child(menu_container)
	menu_container.modulate.a = 0.0
	create_tween().tween_property(menu_container, "modulate:a", 1.0, 0.3)

func _start_game_mode(mode: String) -> void:
	game_mode = mode
	current_round = 1
	score = 0
	correct_answers = 0
	game_active = true
	
	match game_mode:
		"note":
			$Root/TopBar/TopM/TopH/Title.text = "THỬ THÁCH NHẬN DIỆN NỐT"
			_start_note_round()
		"rhythm":
			$Root/TopBar/TopM/TopH/Title.text = "THỬ THÁCH NHỊP ĐIỆU"
			_start_rhythm_round()
		"melody":
			$Root/TopBar/TopM/TopH/Title.text = "HOÀN THIỆN GIAI ĐIỆU"
			_start_melody_round()

# ─── Note Game Mode ──────────────────────────────────────────────────────────
func _start_note_round() -> void:
	if current_round > max_rounds:
		_show_end_summary()
		return
		
	_clear_game_ui()
	
	$Root/Card/CardM/GameVBox/HeaderRow.visible = true
	$Root/Card/CardM/GameVBox/PromptLabel.visible = true
	$Root/Card/CardM/GameVBox/PlayCircle.visible = true
	$Root/Card/CardM/GameVBox/OptionsGrid.visible = true
	
	game_active = true
	round_label.text = "VÒNG HỌC: %d / %d" % [current_round, max_rounds]
	score_label.text = "ĐIỂM: %d" % score
	
	SecureDataManager.load_data()
	var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
	var inst_lbl := ""
	match inst:
		"dan_tranh":
			inst_lbl = "gảy Đàn Tranh cổ truyền"
		"sao_truc":
			inst_lbl = "réo rắt của Sáo Trúc"
		"trong_chau":
			inst_lbl = "tiếng gõ Trống Chầu dân tộc"
		"dan_bau", _:
			inst_lbl = "âm bồi sâu lắng của Đàn Bầu"
			
	prompt_label.text = "Lắng nghe âm sắc %s và nhận diện xem đó là nốt nhạc dân tộc nào:" % inst_lbl
	
	var note_pool = ["Tịch", "Cắc", "Tùng", "Cộc"] if inst == "trong_chau" else NOTES
	correct_note = note_pool[randi() % note_pool.size()]
	
	options.clear()
	options.append(correct_note)
	
	while options.size() < 4:
		var extra = note_pool[randi() % note_pool.size()]
		if not options.has(extra):
			options.append(extra)
			
	options.shuffle()
	
	for child in option_grid.get_children():
		child.queue_free()
		
	var is_mobile = get_viewport().size.x < get_viewport().size.y or get_viewport().size.x < 768
	for opt in options:
		var btn := Button.new()
		btn.text = opt
		btn.custom_minimum_size = Vector2(280, 56) if is_mobile else Vector2(220, 68)
		btn.add_theme_font_size_override("font_size", 18 if is_mobile else 22)
		
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
		
		btn.pressed.connect(func() -> void: _submit_note_answer(opt, btn))
		_make_button_bouncy(btn)
		option_grid.add_child(btn)
		
	if play_btn.is_connected("pressed", _play_melody_sequence):
		play_btn.pressed.disconnect(_play_melody_sequence)
	if not play_btn.is_connected("pressed", _play_correct_sound):
		play_btn.pressed.connect(_play_correct_sound)
		
	get_tree().create_timer(0.4).timeout.connect(_play_correct_sound)

func _submit_note_answer(ans: String, btn: Button) -> void:
	if not game_active: return
	game_active = false
	
	var is_correct = ans == correct_note
	
	if is_correct:
		correct_answers += 1
		score += 100
		_play_synth_note(523.25)
		
		var t := create_tween()
		t.tween_property(btn, "scale", Vector2(1.12, 1.12), 0.12).set_trans(Tween.TRANS_BACK)
		t.tween_property(btn, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)
		
		btn.add_theme_stylebox_override("normal", _flat(C_JADE, Color(0.35, 0.85, 0.60, 0.6), 20, true, 3))
		btn.add_theme_color_override("font_color", Color(1,1,1,1))
		
		result_lbl.text = "Rất xuất sắc! Chúc mừng bạn đoán đúng nốt."
		feedback_pan.add_theme_stylebox_override("panel", _flat(C_JADE, Color(0.35, 0.85, 0.60, 0.6), 16))
	else:
		_play_synth_note(130.81)
		
		var t := create_tween()
		var ox = btn.position.x
		t.tween_property(btn, "position:x", ox - 10.0, 0.05)
		t.tween_property(btn, "position:x", ox + 10.0, 0.05)
		t.tween_property(btn, "position:x", ox,        0.05)
		
		btn.add_theme_stylebox_override("normal", _flat(C_RED_ERR, Color(1,1,1,0.2), 20, true, 3))
		btn.add_theme_color_override("font_color", Color(1,1,1,1))
		
		for c in option_grid.get_children():
			var opt_btn = c as Button
			if opt_btn and opt_btn.text == correct_note:
				opt_btn.add_theme_stylebox_override("normal", _flat(C_JADE, Color(0.35, 0.85, 0.60, 0.6), 20, true, 3))
				opt_btn.add_theme_color_override("font_color", Color(1,1,1,1))
				
		result_lbl.text = "Tiếc quá! Hãy lắng nghe kỹ âm sắc nốt nhạc."
		feedback_pan.add_theme_stylebox_override("panel", _flat(C_BG_BAR, Color(C_RED_ERR.r, C_RED_ERR.g, C_RED_ERR.b, 0.25), 16))
		
	feedback_pan.visible = true
	
	get_tree().create_timer(1.8).timeout.connect(func() -> void:
		current_round += 1
		_start_note_round()
	)

# ─── Rhythm Game Mode ────────────────────────────────────────────────────────
func _start_rhythm_round() -> void:
	if current_round > max_rounds:
		_show_end_summary()
		return
		
	_clear_game_ui()
	
	$Root/Card/CardM/GameVBox/HeaderRow.visible = true
	game_active = true
	round_label.text = "VÒNG HỌC: %d / %d" % [current_round, max_rounds]
	score_label.text = "ĐIỂM: %d" % score
	
	match current_round:
		1: target_beats = [0.25, 0.75]
		2: target_beats = [0.2, 0.5, 0.8]
		3: target_beats = [0.15, 0.4, 0.65, 0.9]
		4: target_beats = [0.3, 0.6]
		5: target_beats = [0.2, 0.4, 0.6, 0.8]
		
	hit_beats.clear()
	for i in range(target_beats.size()):
		hit_beats.append(false)
		
	cursor_pos = 0.0
	rhythm_sweep_count = 0
	rhythm_active = true
	
	var timeline := Control.new()
	timeline.name = "RhythmTimeline"
	timeline.custom_minimum_size = Vector2(0, 80)
	timeline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timeline.draw.connect(_draw_rhythm_timeline)
	$Root/Card/CardM/GameVBox.add_child(timeline)
	
	SecureDataManager.load_data()
	var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
	var action_text := ""
	var btn_text := ""
	match inst:
		"dan_tranh":
			action_text = "Gảy Đàn Tranh"
			btn_text = "🎶 GẢY ĐÀN TRANH (TAP)"
		"sao_truc":
			action_text = "Thổi Sáo Trúc"
			btn_text = "💨 THỔI SÁO TRÚC (TAP)"
		"trong_chau":
			action_text = "Gõ Trống Chầu"
			btn_text = "🥁 GÕ TRỐNG CHẦU (TAP)"
		"dan_bau", _:
			action_text = "Uốn cần Đàn Bầu"
			btn_text = "🎸 UỐN CẦN ĐÀN BẦU (TAP)"
			
	var drum_btn := Button.new()
	drum_btn.name = "DrumBtn"
	drum_btn.text = btn_text
	drum_btn.custom_minimum_size = Vector2(280, 100)
	drum_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	drum_btn.add_theme_font_size_override("font_size", 24)
	
	var drum_n := _flat(C_RED_SON, C_GOLD, 30, true, 6)
	var drum_h := _flat(C_RED_SON_DK, C_GOLD_LIGHT, 30, true, 6)
	var drum_p := _flat(C_RED_SON, C_GOLD, 30, false, 2)
	drum_btn.add_theme_stylebox_override("normal", drum_n)
	drum_btn.add_theme_stylebox_override("hover", drum_h)
	drum_btn.add_theme_stylebox_override("pressed", drum_p)
	drum_btn.add_theme_color_override("font_color", Color.WHITE)
	
	drum_btn.pressed.connect(_on_drum_pressed)
	_make_button_bouncy(drum_btn)
	$Root/Card/CardM/GameVBox.add_child(drum_btn)
	
	prompt_label.text = "%s đúng nhịp khi vạch đỏ quét qua các điểm nhịp vàng!" % action_text
	prompt_label.visible = true

func _draw_rhythm_timeline() -> void:
	var timeline = $Root/Card/CardM/GameVBox/RhythmTimeline as Control
	if not timeline: return
	
	var sz : Vector2 = timeline.size
	var r : float = sz.y * 0.5
	
	var bg_s := _flat(C_BG_BAR, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25), int(r))
	timeline.draw_style_box(bg_s, Rect2(Vector2.ZERO, sz))
	
	for i in range(target_beats.size()):
		var bx = target_beats[i] * sz.x
		var by = sz.y * 0.5
		var is_hit = hit_beats[i]
		
		var col = C_JADE if is_hit else C_GOLD
		var outer_r := 16.0
		var inner_r := 6.0
		timeline.draw_circle(Vector2(bx, by), outer_r, Color(col.r, col.g, col.b, 0.3))
		timeline.draw_circle(Vector2(bx, by), inner_r, col)
		
	var cx = cursor_pos * sz.x
	timeline.draw_line(Vector2(cx, 0), Vector2(cx, sz.y), C_RED_ERR, 6.0, true)
	timeline.draw_circle(Vector2(cx, sz.y * 0.5), 10.0, C_RED_ERR)

func _on_drum_pressed() -> void:
	if not rhythm_active: return
	
	SecureDataManager.load_data()
	var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
	
	var min_diff := 999.0
	var closest_idx := -1
	
	for i in range(target_beats.size()):
		var diff = abs(cursor_pos - target_beats[i])
		if diff < min_diff:
			min_diff = diff
			closest_idx = i
			
	if closest_idx != -1 and min_diff < 0.15:
		if not hit_beats[closest_idx]:
			hit_beats[closest_idx] = true
			
			if min_diff < 0.04:
				score += 150
				_show_rhythm_feedback("🎯 PERFECT! (+150)", C_GOLD)
				_play_synth_note(1000.0 if inst == "trong_chau" else 587.33)
			elif min_diff < 0.08:
				score += 80
				_show_rhythm_feedback("✨ GREAT! (+80)", C_JADE_LIGHT)
				_play_synth_note(150.0 if inst == "trong_chau" else 523.25)
			else:
				score += 40
				_show_rhythm_feedback("👍 GOOD! (+40)", C_TEXT)
				_play_synth_note(100.0 if inst == "trong_chau" else 392.00)
		else:
			_show_rhythm_feedback("Gõ trùng nhịp!", C_TEXT_MUTED)
	else:
		_show_rhythm_feedback("❌ MISS!", C_RED_ERR)
		_play_synth_note(110.0)
		
	score_label.text = "ĐIỂM: %d" % score

func _show_rhythm_feedback(msg: String, color: Color) -> void:
	var feedback_lbl = $Root/Card/CardM/GameVBox.get_node_or_null("RhythmFeedbackLabel") as Label
	if not feedback_lbl:
		feedback_lbl = Label.new()
		feedback_lbl.name = "RhythmFeedbackLabel"
		feedback_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		feedback_lbl.add_theme_font_size_override("font_size", 26)
		$Root/Card/CardM/GameVBox.add_child(feedback_lbl)
		$Root/Card/CardM/GameVBox.move_child(feedback_lbl, 2)
		
	feedback_lbl.text = msg
	feedback_lbl.add_theme_color_override("font_color", color)
	
	feedback_lbl.scale = Vector2(1.3, 1.3)
	feedback_lbl.pivot_offset = feedback_lbl.size / 2.0
	var t := create_tween()
	t.tween_property(feedback_lbl, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)

func _end_rhythm_round() -> void:
	rhythm_active = false
	
	$Root/Card/CardM/GameVBox/FeedbackPanel.visible = true
	result_lbl.text = "Hoàn thành vòng %d! Điểm hiện tại: %d" % [current_round, score]
	feedback_pan.add_theme_stylebox_override("panel", _flat(C_JADE, Color(0.35, 0.85, 0.60, 0.6), 16))
	
	get_tree().create_timer(2.0).timeout.connect(func() -> void:
		current_round += 1
		_start_rhythm_round()
	)

# ─── Melody Matcher Game Mode ────────────────────────────────────────────────
func _start_melody_round() -> void:
	if current_round > max_rounds:
		_show_end_summary()
		return
		
	_clear_game_ui()
	
	$Root/Card/CardM/GameVBox/HeaderRow.visible = true
	$Root/Card/CardM/GameVBox/PromptLabel.visible = true
	$Root/Card/CardM/GameVBox/PlayCircle.visible = true
	$Root/Card/CardM/GameVBox/OptionsGrid.visible = true
	
	game_active = true
	round_label.text = "VÒNG HỌC: %d / %d" % [current_round, max_rounds]
	score_label.text = "ĐIỂM: %d" % score
	
	SecureDataManager.load_data()
	var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
	var inst_name := ""
	match inst:
		"dan_tranh":
			inst_name = "Đàn Tranh"
		"sao_truc":
			inst_name = "Sáo Trúc"
		"trong_chau":
			inst_name = "Trống Chầu"
		"dan_bau", _:
			inst_name = "Đàn Bầu"
			
	prompt_label.text = "Giai điệu ngũ cung của %s dưới đây đang khuyết một nốt nhạc. Nhấn nút Loa phát giai điệu rồi tìm nốt còn thiếu [?]:" % inst_name
	
	var melodies_pool = [
		["Tịch", "Cắc", "Tùng", "Cắc", "Tịch"],
		["Tùng", "Tịch", "Cắc", "Tịch", "Tùng"],
		["Cắc", "Tùng", "Tịch", "Tùng", "Cắc"],
		["Tịch", "Tùng", "Cắc", "Tịch", "Cắc"],
		["Tùng", "Cắc", "Tịch", "Cắc", "Tùng"]
	] if inst == "trong_chau" else MELODIES
	var note_pool = ["Tịch", "Cắc", "Tùng", "Cộc"] if inst == "trong_chau" else NOTES
	
	var raw_mel = melodies_pool[randi() % melodies_pool.size()]
	melody_notes.clear()
	for n in raw_mel:
		melody_notes.append(n)
		
	missing_idx = randi() % 5
	correct_note = melody_notes[missing_idx]
	
	var cards_hbox := HBoxContainer.new()
	cards_hbox.name = "MelodyCards"
	cards_hbox.add_theme_constant_override("separation", 16)
	cards_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	$Root/Card/CardM/GameVBox.add_child(cards_hbox)
	$Root/Card/CardM/GameVBox.move_child(cards_hbox, 2)
	
	for i in range(5):
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(80, 100)
		var is_missing = (i == missing_idx)
		
		var card_s := _flat(C_BG_BAR if is_missing else C_CARD, C_GOLD if is_missing else Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25), 16, true, 2)
		card.add_theme_stylebox_override("panel", card_s)
		
		var card_lbl := Label.new()
		card_lbl.name = "NoteLabel"
		card_lbl.text = "?" if is_missing else melody_notes[i]
		card_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		card_lbl.add_theme_font_size_override("font_size", 24 if is_missing else 20)
		card_lbl.add_theme_color_override("font_color", C_RED_SON if is_missing else C_TEXT)
		card.add_child(card_lbl)
		
		cards_hbox.add_child(card)
		
	options.clear()
	options.append(correct_note)
	while options.size() < 4:
		var extra = note_pool[randi() % note_pool.size()]
		if not options.has(extra):
			options.append(extra)
	options.shuffle()
	
	for child in option_grid.get_children():
		child.queue_free()
		
	var is_mobile = get_viewport().size.x < get_viewport().size.y or get_viewport().size.x < 768
	for opt in options:
		var btn := Button.new()
		btn.text = opt
		btn.custom_minimum_size = Vector2(280, 56) if is_mobile else Vector2(220, 68)
		btn.add_theme_font_size_override("font_size", 18 if is_mobile else 22)
		
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
		
		btn.pressed.connect(func() -> void: _submit_melody_answer(opt, btn))
		_make_button_bouncy(btn)
		option_grid.add_child(btn)
		
	if play_btn.is_connected("pressed", _play_correct_sound):
		play_btn.pressed.disconnect(_play_correct_sound)
	if not play_btn.is_connected("pressed", _play_melody_sequence):
		play_btn.pressed.connect(_play_melody_sequence)
		
	get_tree().create_timer(0.5).timeout.connect(_play_melody_sequence)

func _play_melody_sequence() -> void:
	if is_playing_melody: return
	is_playing_melody = true
	current_play_index = 0
	
	if not melody_timer:
		melody_timer = Timer.new()
		add_child(melody_timer)
		melody_timer.timeout.connect(_on_melody_timer_timeout)
		
	melody_timer.wait_time = 0.58
	melody_timer.start()
	_on_melody_timer_timeout()

func _on_melody_timer_timeout() -> void:
	var cards_hbox = $Root/Card/CardM/GameVBox.get_node_or_null("MelodyCards") as HBoxContainer
	
	if cards_hbox:
		for i in range(5):
			var card = cards_hbox.get_child(i) as PanelContainer
			var is_missing = (i == missing_idx)
			var card_s := _flat(C_BG_BAR if is_missing else C_CARD, C_GOLD if is_missing else Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25), 16, true, 2)
			card.add_theme_stylebox_override("panel", card_s)
			card.scale = Vector2.ONE
			
	if current_play_index >= 5:
		melody_timer.stop()
		is_playing_melody = false
		return
		
	if cards_hbox and current_play_index < cards_hbox.get_child_count():
		var card = cards_hbox.get_child(current_play_index) as PanelContainer
		var is_missing = (current_play_index == missing_idx)
		var highlight_s := _flat(C_GOLD if is_missing else C_RED_SON, C_GOLD_LIGHT, 16, true, 4)
		card.add_theme_stylebox_override("panel", highlight_s)
		
		card.pivot_offset = card.size / 2.0
		var t := create_tween()
		t.tween_property(card, "scale", Vector2(1.15, 1.15), 0.1)
		t.tween_property(card, "scale", Vector2.ONE, 0.12)
		
	var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
	var drum_freqs = {
		"Tịch": 100.0,
		"Cắc": 1000.0,
		"Tùng": 150.0,
		"Cộc": 800.0
	}
	if current_play_index != missing_idx:
		var note_name = melody_notes[current_play_index]
		if inst == "trong_chau":
			if drum_freqs.has(note_name):
				_play_synth_note(drum_freqs[note_name])
		else:
			if FREQS.has(note_name):
				_play_synth_note(FREQS[note_name])
	else:
		_play_synth_note(150.0 if inst != "trong_chau" else 100.0)
		
	current_play_index += 1

func _submit_melody_answer(ans: String, btn: Button) -> void:
	if not game_active: return
	game_active = false
	
	var is_correct = ans == correct_note
	
	var cards_hbox = $Root/Card/CardM/GameVBox.get_node_or_null("MelodyCards") as HBoxContainer
	if cards_hbox and missing_idx < cards_hbox.get_child_count():
		var card = cards_hbox.get_child(missing_idx) as PanelContainer
		var label = card.get_node("NoteLabel") as Label
		label.text = correct_note
		label.add_theme_color_override("font_color", C_JADE if is_correct else C_RED_ERR)
		
	if is_correct:
		correct_answers += 1
		score += 120
		_play_synth_note(523.25)
		
		var t := create_tween()
		t.tween_property(btn, "scale", Vector2(1.12, 1.12), 0.12).set_trans(Tween.TRANS_BACK)
		t.tween_property(btn, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)
		
		btn.add_theme_stylebox_override("normal", _flat(C_JADE, Color(0.35, 0.85, 0.60, 0.6), 20, true, 3))
		btn.add_theme_color_override("font_color", Color(1,1,1,1))
		
		result_lbl.text = "Tuyệt vời! Bạn đã hoàn thành đúng giai điệu."
		feedback_pan.add_theme_stylebox_override("panel", _flat(C_JADE, Color(0.35, 0.85, 0.60, 0.6), 16))
	else:
		_play_synth_note(130.81)
		
		var t := create_tween()
		var ox = btn.position.x
		t.tween_property(btn, "position:x", ox - 10.0, 0.05)
		t.tween_property(btn, "position:x", ox + 10.0, 0.05)
		t.tween_property(btn, "position:x", ox,        0.05)
		
		btn.add_theme_stylebox_override("normal", _flat(C_RED_ERR, Color(1,1,1,0.2), 20, true, 3))
		btn.add_theme_color_override("font_color", Color(1,1,1,1))
		
		for c in option_grid.get_children():
			var opt_btn = c as Button
			if opt_btn and opt_btn.text == correct_note:
				opt_btn.add_theme_stylebox_override("normal", _flat(C_JADE, Color(0.35, 0.85, 0.60, 0.6), 20, true, 3))
				opt_btn.add_theme_color_override("font_color", Color(1,1,1,1))
				
		result_lbl.text = "Tiếc quá! Nốt khuyết trong giai điệu chính là %s." % correct_note
		feedback_pan.add_theme_stylebox_override("panel", _flat(C_BG_BAR, Color(C_RED_ERR.r, C_RED_ERR.g, C_RED_ERR.b, 0.25), 16))
		
	feedback_pan.visible = true
	
	get_tree().create_timer(2.2).timeout.connect(func() -> void:
		current_round += 1
		_start_melody_round()
	)

# ─── Sound Synthesis ─────────────────────────────────────────────────────────
func _play_correct_sound() -> void:
	var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
	var drum_freqs = {
		"Tịch": 100.0,
		"Cắc": 1000.0,
		"Tùng": 150.0,
		"Cộc": 800.0
	}
	if inst == "trong_chau":
		if drum_freqs.has(correct_note):
			_play_synth_note(drum_freqs[correct_note])
	else:
		if not FREQS.has(correct_note): return
		_play_synth_note(FREQS[correct_note])

func _play_synth_note(freq: float) -> void:
	SecureDataManager.load_data()
	var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
	
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 44100
	stream.buffer_length = 0.5
	
	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	player.play()
	
	var playback : AudioStreamGeneratorPlayback = player.get_stream_playback()
	if playback:
		var sample_count := int(44100 * 0.48)
		var playback_phase := 0.0
		
		var frames := PackedVector2Array()
		for i in range(sample_count):
			var t := float(i) / 44100.0
			var sample := 0.0
			var amplitude_envelope := 1.0
			var current_freq := freq
			
			match inst:
				"dan_tranh":
					# Bright pluck string with rapid decay and rich harmonics
					amplitude_envelope = exp(-t * 6.0) # fast decay
					# Add 2nd, 3rd, and 4th harmonics
					sample = sin(playback_phase) \
						+ 0.5 * sin(playback_phase * 2.0) \
						+ 0.25 * sin(playback_phase * 3.0) \
						+ 0.1 * sin(playback_phase * 4.0)
					sample *= 0.25
					
				"sao_truc":
					# Flute: slow attack (soft blow), gentle decay, light pitch vibrato
					if t < 0.08:
						amplitude_envelope = t / 0.08
					else:
						amplitude_envelope = exp(-(t - 0.08) * 1.8)
					
					# 6Hz frequency vibrato (flute breath shake)
					var vibrato = 1.0 + 0.008 * sin(t * 6.0 * TAU)
					current_freq = freq * vibrato
					
					# Soft tone with mostly fundamental and a weak 3rd harmonic
					sample = sin(playback_phase) + 0.15 * sin(playback_phase * 3.0)
					
					# Add very light noise to simulate breath/air blowing
					var noise = (randf() * 2.0 - 1.0) * 0.02
					sample = (sample * 0.25) + noise
					
				"trong_chau":
					# Drum synthesis based on incoming frequency parameter
					if freq == 100.0: # Tịch
						amplitude_envelope = exp(-t * 12.0)
						sample = sin(playback_phase)
						if t < 0.02:
							sample += (randf() * 2.0 - 1.0) * 0.4
					elif freq == 1000.0: # Cắc
						amplitude_envelope = exp(-t * 26.0)
						sample = sin(playback_phase)
						if t < 0.015:
							sample += (randf() * 2.0 - 1.0) * 0.5
					elif freq == 150.0: # Tùng
						amplitude_envelope = exp(-t * 6.0)
						sample = sin(playback_phase)
						if t < 0.03:
							sample += (randf() * 2.0 - 1.0) * 0.3
					else: # Cộc
						amplitude_envelope = exp(-t * 18.0)
						sample = sin(playback_phase)
						if t < 0.02:
							sample += (randf() * 2.0 - 1.0) * 0.4
					sample *= 0.35
					
				"dan_bau", _:
					# Dan Bau: pitch slide-up at start and deep 5Hz vibrato (uốn cần)
					amplitude_envelope = exp(-t * 3.2)
					
					# Slide up from 6% lower pitch during first 150ms
					var slide := 1.0
					if t < 0.15:
						slide = 0.94 + 0.06 * (t / 0.15)
						
					# Rich 5Hz pitch vibrato simulating rod uốn cần bending
					var vibrato = 1.0 + 0.016 * sin(t * 5.0 * TAU)
					current_freq = freq * slide * vibrato
					
					# Warm hollow string tone (mostly odd harmonics)
					sample = sin(playback_phase) \
						+ 0.45 * sin(playback_phase * 2.0) \
						+ 0.3 * sin(playback_phase * 3.0)
					sample *= 0.25
			
			frames.append(Vector2(sample * amplitude_envelope, sample * amplitude_envelope))
			
			var increment := current_freq * TAU / 44100.0
			playback_phase += increment
			
		playback.push_buffer(frames)
		
	get_tree().create_timer(0.55).timeout.connect(player.queue_free)

# ─── End Summary ─────────────────────────────────────────────────────────────
func _show_end_summary() -> void:
	_clear_game_ui()
	
	$Root/Card/CardM/GameVBox/HeaderRow.visible = true
	round_label.text = "KẾT THÚC THỬ THÁCH"
	score_label.text = "ĐIỂM CHUNG CUỘC: %d" % score
	
	feedback_pan.visible = true
	feedback_pan.add_theme_stylebox_override("panel", _flat(C_GOLD, C_GOLD_LIGHT, 20, true, 4))
	
	var inst := InstrumentSelect.selected_instrument
	
	var earned_xp = int(score * 0.5)
	if earned_xp > 0:
		SecureDataManager.data.practice_time_seconds = SecureDataManager.data.get("practice_time_seconds", 0.0) + (earned_xp * 6)
		SecureDataManager.save_data()
		
	if score >= 200:
		SecureDataManager.complete_lesson(inst, "Node3", 3) # Unlocks Node 4!
		result_lbl.text = "Bạn đạt được %d điểm! Rất đáng khen ngợi.\n+ %d XP  ·  Mở Khóa Học Tiếp!" % [score, earned_xp]
	else:
		result_lbl.text = "Bạn đạt được %d điểm! Hãy cố gắng luyện tập thêm tai nhạc nữa nhé." % score
		
	result_lbl.add_theme_color_override("font_color", C_TEXT)
	
	var btn := Button.new()
	btn.name = "EndSummaryBtn"
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

# ─── Style & Helpers ──────────────────────────────────────────────────────────
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
	var viewport_size = get_viewport().size
	var is_mobile = viewport_size.x < viewport_size.y or viewport_size.x < 768
	
	var card := $Root/Card as PanelContainer
	if is_mobile:
		card.custom_minimum_size = Vector2(viewport_size.x - 32, 0)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		card.custom_minimum_size = Vector2(1000, 640)
		card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	option_grid.columns = 1 if is_mobile else 2

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
