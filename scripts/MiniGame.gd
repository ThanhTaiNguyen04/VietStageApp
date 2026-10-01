extends Control
class_name MiniGame

# ── Colors (Heritage Jade & Warm Gold Theme) ──────────────────────────────────
const C_BG_DARK     := Color(0.98, 0.97, 0.94, 1.0)
const C_RED_SON     := Color(0.09, 0.25, 0.18, 1.0)
const C_RED_SON_DK  := Color(0.06, 0.18, 0.13, 1.0)
const C_RED_ERR     := Color(0.72, 0.18, 0.14, 1.0)
const C_GOLD        := Color(0.77, 0.58, 0.15, 1.0)
const C_GOLD_LIGHT  := Color(0.95, 0.82, 0.45, 1.0)
const C_GOLD_DARK   := Color(0.55, 0.40, 0.08, 1.0)
const C_JADE        := Color(0.12, 0.37, 0.23, 1.0)
const C_JADE_LIGHT  := Color(0.18, 0.58, 0.38, 1.0)
const C_CREAM       := Color(1.00, 0.99, 0.96, 1.0)
const C_CARD        := Color(1.00, 1.00, 1.00, 0.95)
const C_TEXT        := Color(0.13, 0.08, 0.05, 1.0)
const C_TEXT_MUTED  := Color(0.48, 0.43, 0.38, 1.0)

# ── Notes & Frequencies ───────────────────────────────────────────────────────
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

const MELODIES = [
	["Đô", "Rê", "Mi", "Sol", "La"],
	["Rê", "Mi", "Sol", "La", "Đô"],
	["Mi", "Sol", "La", "Đô", "Rê"],
	["Sol", "La", "Đô", "Rê", "Mi"],
	["La", "Đô", "Rê", "Mi", "Sol"]
]

# ── State ─────────────────────────────────────────────────────────────────────
var current_round := 1
var max_rounds := 5
var correct_answers := 0
var score := 0
var correct_note := ""
var options : Array[String] = []
var game_active := true
var game_mode := "" # "", "note", "rhythm", "melody"

# Rhythm challenge state
var rhythm_active := false
var cursor_pos := 0.0
var rhythm_speed := 0.4
var target_beats : Array = []
var hit_beats : Array = []
var rhythm_sweep_count := 0

# Melody matcher state
var melody_notes : Array[String] = []
var missing_idx := -1
var is_playing_melody := false
var current_play_index := -1
var melody_timer : Timer = null

# ── Node Refs ─────────────────────────────────────────────────────────────────
@onready var title_pill     : PanelContainer = $Root/TopBar/TopH/TitlePill
@onready var top_title      : Label  = $Root/TopBar/TopH/TitlePill/Margin/Title
@onready var back_btn       : Button = $Root/TopBar/TopH/BackBtn
@onready var star_lbl       : Label  = $Root/TopBar/TopH/HudRow/StarChip/Margin/StarLbl
@onready var score_lbl      : Label  = $Root/TopBar/TopH/HudRow/ScoreChip/Margin/ScoreLbl
@onready var star_chip      : PanelContainer = $Root/TopBar/TopH/HudRow/StarChip
@onready var score_chip     : PanelContainer = $Root/TopBar/TopH/HudRow/ScoreChip

@onready var main_card      : PanelContainer = $Root/ContentArea/Card
@onready var game_vbox      : VBoxContainer  = $Root/ContentArea/Card/CardM/GameVBox
@onready var header_row     : HBoxContainer  = $Root/ContentArea/Card/CardM/GameVBox/HeaderRow
@onready var round_pill     : PanelContainer = $Root/ContentArea/Card/CardM/GameVBox/HeaderRow/RoundPill
@onready var score_pill     : PanelContainer = $Root/ContentArea/Card/CardM/GameVBox/HeaderRow/ScorePill
@onready var round_label    : Label  = $Root/ContentArea/Card/CardM/GameVBox/HeaderRow/RoundPill/Margin/RoundLabel
@onready var score_label    : Label  = $Root/ContentArea/Card/CardM/GameVBox/HeaderRow/ScorePill/Margin/ScoreLabel
@onready var prompt_label   : Label  = $Root/ContentArea/Card/CardM/GameVBox/PromptLabel
@onready var play_circle    : PanelContainer = $Root/ContentArea/Card/CardM/GameVBox/PlayCircle
@onready var play_btn       : Button = $Root/ContentArea/Card/CardM/GameVBox/PlayCircle/PlayBtn
@onready var option_grid    : GridContainer  = $Root/ContentArea/Card/CardM/GameVBox/OptionsGrid
@onready var feedback_pan   : PanelContainer = $Root/ContentArea/Card/CardM/GameVBox/FeedbackPanel
@onready var result_lbl     : Label  = $Root/ContentArea/Card/CardM/GameVBox/FeedbackPanel/FeedbackM/FeedbackLabel


static var start_mode: String = ""

func _ready() -> void:
	SecureDataManager.load_data()
	_build_theme()
	_update_top_hud()
	_connect_buttons()
	
	if start_mode != "":
		var m := start_mode
		start_mode = ""
		_start_game_mode(m)
	else:
		_show_mode_selection_menu()
	
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()


func _process(delta: float) -> void:
	if game_mode == "rhythm" and rhythm_active:
		if rhythm_phase == "play":
			rhythm_elapsed += delta


func _build_theme() -> void:
	# Back button
	var btn_s := _flat(C_CARD, C_GOLD, 22, true, 2)
	back_btn.add_theme_stylebox_override("normal", btn_s)
	back_btn.add_theme_stylebox_override("hover", _flat(C_CARD, C_GOLD_LIGHT, 22, true, 2))
	back_btn.add_theme_stylebox_override("pressed", _flat(C_BG_DARK, C_GOLD, 22, false, 1))
	back_btn.add_theme_color_override("font_color", C_TEXT)
	
	# Top HUD Chips & Title Pill
	var chip_s := _flat(Color(1.0, 1.0, 1.0, 0.85), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.4), 16)
	title_pill.add_theme_stylebox_override("panel", chip_s)
	star_chip.add_theme_stylebox_override("panel", chip_s)
	score_chip.add_theme_stylebox_override("panel", chip_s)
	star_lbl.add_theme_color_override("font_color", C_GOLD_DARK)
	score_lbl.add_theme_color_override("font_color", C_JADE)
	
	# Main Glassmorphism Game Card
	var card_s := _flat(C_CARD, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35), 24, true, 4)
	main_card.add_theme_stylebox_override("panel", card_s)
	
	# Header pills
	var pill_s := _flat(Color(0.12, 0.37, 0.23, 0.12), C_JADE, 16)
	round_pill.add_theme_stylebox_override("panel", pill_s)
	score_pill.add_theme_stylebox_override("panel", pill_s)
	round_label.add_theme_color_override("font_color", C_JADE)
	score_label.add_theme_color_override("font_color", C_RED_SON)
	prompt_label.add_theme_color_override("font_color", C_TEXT)
	
	# Play sound circle
	var play_s := _flat(C_GOLD, C_GOLD_LIGHT, 44, true, 4)
	play_circle.add_theme_stylebox_override("panel", play_s)
	play_btn.add_theme_color_override("font_color", Color.WHITE)


func _update_top_hud() -> void:
	var stars_val = SecureDataManager.data.get("stars", 0)
	var pts_val = SecureDataManager.data.get("total_points", 0)
	var stars := int(str(stars_val)) if stars_val != null else 0
	var pts := int(str(pts_val)) if pts_val != null else 0
	star_lbl.text = "⭐ %d" % stars
	score_lbl.text = "🏆 %d XP" % pts


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
		t.tween_property(self, "modulate:a", 0.0, 0.2)
		t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))


func _clear_game_ui() -> void:
	header_row.visible = false
	prompt_label.visible = false
	play_circle.visible = false
	option_grid.visible = false
	feedback_pan.visible = false
	
	var card_s := _flat(C_CARD, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35), 24, true, 4)
	main_card.add_theme_stylebox_override("panel", card_s)
	
	rhythm_active = false
	is_playing_melody = false
	if melody_timer and is_instance_valid(melody_timer):
		melody_timer.stop()
		
	for child in game_vbox.get_children():
		if child.name in ["MenuContainer", "RhythmTimeline", "BeatTrack", "RhythmStatePill", "DrumBtn", "MelodyCards", "RhythmFeedbackLabel", "EndSummaryPanel"]:
			child.queue_free()


# ─── Mode Selection Menu (Minimalist 3 Bento Cards) ───────────────────────────
func _show_mode_selection_menu() -> void:
	_clear_game_ui()
	game_mode = ""
	_update_top_hud()
	
	var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
	var inst_name := _get_instrument_name(inst)
	top_title.text = "🎮 MINI GAME · %s" % inst_name.to_upper()
	
	prompt_label.text = ""
	prompt_label.visible = false
	
	var is_mobile: bool = get_viewport().get_visible_rect().size.x < 768.0
	
	var menu_container := HBoxContainer.new()
	menu_container.name = "MenuContainer"
	menu_container.add_theme_constant_override("separation", 20)
	menu_container.alignment = BoxContainer.ALIGNMENT_CENTER
	menu_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var modes_info := [
		{
			"id": "note",
			"tag": "QUIZ",
			"tag_bg": Color("#e0edff"),
			"tag_border": Color("#bfdbfe"),
			"tag_color": Color("#2563eb"),
			"icon": "?",
			"icon_color": Color("#2563eb"),
			"title": "Nhận diện\nnốt nhạc",
			"btn_bg": Color("#2563eb"),
			"btn_hover": Color("#1d4ed8")
		},
		{
			"id": "rhythm",
			"tag": "MINI-GAME 1",
			"tag_bg": Color("#dcfce7"),
			"tag_border": Color("#bbf7d0"),
			"tag_color": Color("#16a34a"),
			"icon": "🎵",
			"icon_color": Color("#16a34a"),
			"title": "Thử thách\nnhịp điệu",
			"btn_bg": Color("#489851"),
			"btn_hover": Color("#3b8243")
		},
		{
			"id": "melody",
			"tag": "MINI-GAME 2",
			"tag_bg": Color("#ede9fe"),
			"tag_border": Color("#ddd6fe"),
			"tag_color": Color("#7c3aed"),
			"icon": "🎵",
			"icon_color": Color("#7c3aed"),
			"title": "Hoàn thiện\ngiai điệu",
			"btn_bg": Color("#6b46c1"),
			"btn_hover": Color("#5b21b6")
		}
	]
	
	for m in modes_info:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(240, 240) if is_mobile else Vector2(280, 290)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		# White rounded card matching screenshot
		var card_s := _flat(Color(1.0, 1.0, 1.0, 0.95), Color(0.85, 0.88, 0.92, 0.6), 24, true, 4)
		card.add_theme_stylebox_override("panel", card_s)
		
		var card_m := MarginContainer.new()
		card_m.add_theme_constant_override("margin_left", 20)
		card_m.add_theme_constant_override("margin_right", 20)
		card_m.add_theme_constant_override("margin_top", 18)
		card_m.add_theme_constant_override("margin_bottom", 20)
		card.add_child(card_m)
		
		var card_v := VBoxContainer.new()
		card_v.add_theme_constant_override("separation", 12)
		card_v.alignment = BoxContainer.ALIGNMENT_CENTER
		card_m.add_child(card_v)
		
		# Pill Tag Header
		var tag_pill := PanelContainer.new()
		tag_pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var tag_s := StyleBoxFlat.new()
		tag_s.bg_color = m["tag_bg"]
		tag_s.border_color = m["tag_border"]
		tag_s.border_width_left = 1; tag_s.border_width_right = 1
		tag_s.border_width_top = 1; tag_s.border_width_bottom = 1
		tag_s.corner_radius_top_left = 12; tag_s.corner_radius_top_right = 12
		tag_s.corner_radius_bottom_left = 12; tag_s.corner_radius_bottom_right = 12
		tag_pill.add_theme_stylebox_override("panel", tag_s)
		
		var tag_margin := MarginContainer.new()
		tag_margin.add_theme_constant_override("margin_left", 12)
		tag_margin.add_theme_constant_override("margin_right", 12)
		tag_margin.add_theme_constant_override("margin_top", 3)
		tag_margin.add_theme_constant_override("margin_bottom", 3)
		tag_pill.add_child(tag_margin)
		
		var tag_lbl := Label.new()
		tag_lbl.text = m["tag"]
		tag_lbl.add_theme_font_size_override("font_size", 11)
		tag_lbl.add_theme_color_override("font_color", m["tag_color"])
		tag_margin.add_child(tag_lbl)
		card_v.add_child(tag_pill)
		
		# Center Icon
		var icon_lbl := Label.new()
		icon_lbl.text = m["icon"]
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.add_theme_font_size_override("font_size", 42 if is_mobile else 50)
		icon_lbl.add_theme_color_override("font_color", m["icon_color"])
		card_v.add_child(icon_lbl)
		
		# Title (2 lines)
		var title_lbl := Label.new()
		title_lbl.text = m["title"]
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_lbl.add_theme_font_size_override("font_size", 16 if is_mobile else 18)
		title_lbl.add_theme_color_override("font_color", Color("#1e293b"))
		card_v.add_child(title_lbl)
		
		var spacer := Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card_v.add_child(spacer)
		
		# Action Button
		var play_btn_card := Button.new()
		play_btn_card.text = "Bắt đầu"
		play_btn_card.custom_minimum_size = Vector2(0, 44)
		play_btn_card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		play_btn_card.add_theme_font_size_override("font_size", 15)
		
		var b_n := _flat(m["btn_bg"], Color.TRANSPARENT, 12, false)
		var b_h := _flat(m["btn_hover"], Color.TRANSPARENT, 12, false)
		var b_p := _flat(m["btn_bg"].darkened(0.15), Color.TRANSPARENT, 12, false)
		play_btn_card.add_theme_stylebox_override("normal", b_n)
		play_btn_card.add_theme_stylebox_override("hover", b_h)
		play_btn_card.add_theme_stylebox_override("pressed", b_p)
		play_btn_card.add_theme_color_override("font_color", Color.WHITE)
		
		var mode_id: String = m["id"]
		play_btn_card.pressed.connect(func() -> void: _start_game_mode(mode_id))
		_make_button_bouncy(play_btn_card)
		card_v.add_child(play_btn_card)
		
		card.pivot_offset = Vector2(140, 145)
		card.mouse_entered.connect(func() -> void:
			var t := create_tween().set_parallel(true)
			t.tween_property(card, "scale", Vector2(1.025, 1.025), 0.1).set_trans(Tween.TRANS_BACK)
		)
		card.mouse_exited.connect(func() -> void:
			var t := create_tween().set_parallel(true)
			t.tween_property(card, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_BACK)
		)
		menu_container.add_child(card)
		
	game_vbox.add_child(menu_container)
	menu_container.modulate.a = 0.0
	create_tween().tween_property(menu_container, "modulate:a", 1.0, 0.22)


func _start_game_mode(mode: String) -> void:
	game_mode = mode
	current_round = 1
	score = 0
	correct_answers = 0
	game_active = true
	
	match game_mode:
		"note":
			top_title.text = "👂 ĐOÁN NỐT NHẠC"
			_start_note_round()
		"rhythm":
			top_title.text = "🥁 BẮT NHỊP ĐIỆU"
			_start_rhythm_round()
		"melody":
			top_title.text = "🎼 GHÉP GIAI ĐIỆU"
			_start_melody_round()


# ─── 1. Note Game Mode (Đoán Nốt) ─────────────────────────────────────────────
func _start_note_round() -> void:
	if current_round > max_rounds:
		_show_end_summary()
		return
		
	_clear_game_ui()
	header_row.visible = true
	prompt_label.visible = true
	play_circle.visible = true
	option_grid.visible = true
	
	game_active = true
	round_label.text = "VÒNG %d / %d" % [current_round, max_rounds]
	score_label.text = "ĐIỂM: %d" % score
	
	var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
	prompt_label.text = "Lắng nghe âm sắc %s và chọn tên nốt:" % _get_instrument_name(inst)
	
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
		
	var is_mobile: bool = get_viewport().get_visible_rect().size.x < 768.0
	for opt in options:
		var btn := Button.new()
		btn.text = opt
		btn.custom_minimum_size = Vector2(200, 52) if is_mobile else Vector2(240, 60)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.add_theme_font_size_override("font_size", 18)
		btn.add_theme_stylebox_override("normal", _flat(C_CARD, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45), 18, true, 2))
		btn.add_theme_stylebox_override("hover", _flat(C_CARD, C_RED_SON, 18, true, 2))
		btn.add_theme_stylebox_override("pressed", _flat(C_BG_DARK, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45), 18, false, 1))
		btn.add_theme_color_override("font_color", C_TEXT)
		btn.add_theme_color_override("font_hover_color", C_RED_SON)
		btn.pressed.connect(func() -> void: _submit_note_answer(opt, btn))
		_make_button_bouncy(btn)
		option_grid.add_child(btn)
		
	get_tree().create_timer(0.3).timeout.connect(_play_correct_sound)


func _submit_note_answer(ans: String, btn: Button) -> void:
	if not game_active: return
	game_active = false
	
	var is_correct = ans == correct_note
	if is_correct:
		correct_answers += 1
		score += 100
		_play_synth_note(523.25)
		btn.add_theme_stylebox_override("normal", _flat(C_JADE, Color(0.35, 0.85, 0.6, 0.8), 18, true, 3))
		btn.add_theme_color_override("font_color", Color.WHITE)
		result_lbl.text = "✨ Chính xác! (+100 điểm)"
		feedback_pan.add_theme_stylebox_override("panel", _flat(C_JADE, Color(0.35, 0.85, 0.6, 0.6), 14))
	else:
		_play_synth_note(130.81)
		btn.add_theme_stylebox_override("normal", _flat(C_RED_ERR, Color(1, 1, 1, 0.3), 18, true, 3))
		btn.add_theme_color_override("font_color", Color.WHITE)
		for c in option_grid.get_children():
			var opt_btn = c as Button
			if opt_btn and opt_btn.text == correct_note:
				opt_btn.add_theme_stylebox_override("normal", _flat(C_JADE, Color(0.35, 0.85, 0.6, 0.8), 18, true, 3))
				opt_btn.add_theme_color_override("font_color", Color.WHITE)
		result_lbl.text = "❌ Chưa đúng! Đó là nốt %s" % correct_note
		feedback_pan.add_theme_stylebox_override("panel", _flat(C_BG_DARK, Color(C_RED_ERR.r, C_RED_ERR.g, C_RED_ERR.b, 0.4), 14))
		
	feedback_pan.visible = true
	get_tree().create_timer(1.6).timeout.connect(func() -> void:
		current_round += 1
		_start_note_round()
	)


# ─── 2. Rhythm Game Mode (Thử Thách Nhịp Điệu · Listen & Repeat) ───────────────
var rhythm_combo := 0
var rhythm_phase := "idle" # "listen", "countdown", "play", "round_end"
var rhythm_beats: Array[float] = []
var rhythm_beat_judgements: Array[String] = []
var rhythm_round_duration := 2.8
var rhythm_elapsed := 0.0
var rhythm_listen_idx := 0
var rhythm_listen_timer: Timer = null

func _start_rhythm_round() -> void:
	if current_round > max_rounds:
		_show_end_summary()
		return
		
	_clear_game_ui()
	top_title.text = "🥁 THỬ THÁCH NHỊP ĐIỆU"
	
	header_row.visible = true
	prompt_label.visible = true
	
	# Khung thẻ kính mờ sang trọng
	var card_s := _flat(Color(1.0, 1.0, 1.0, 0.94), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.4), 22, true, 2)
	main_card.add_theme_stylebox_override("panel", card_s)
	
	game_active = true
	round_label.text = "VÒNG %d / %d" % [current_round, max_rounds]
	score_label.text = "ĐIỂM: %d" % score
	prompt_label.text = "Lắng nghe tiết tấu mẫu, sau đó gõ lại thật chính xác:"
	prompt_label.add_theme_color_override("font_color", Color("#1e293b"))
	
	# Tạo mẫu nhịp phong phú cho từng vòng (4 phách)
	var patterns: Array[Array] = [
		[0.4, 1.0, 1.6, 2.2],
		[0.4, 0.9, 1.5, 2.1],
		[0.3, 0.8, 1.3, 1.9, 2.4]
	]
	rhythm_beats.clear()
	for b in patterns[(current_round - 1) % patterns.size()]:
		rhythm_beats.append(float(b))
	rhythm_beat_judgements.clear()
	for _b in rhythm_beats:
		rhythm_beat_judgements.append("")
	rhythm_round_duration = rhythm_beats[-1] + 0.8
	
	# 1. Huy hiệu trạng thái giai đoạn (Listen vs Play)
	var state_pill := PanelContainer.new()
	state_pill.name = "RhythmStatePill"
	state_pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var sp_s := _flat(Color("#fef3c7"), Color("#f59e0b"), 16, true, 1)
	state_pill.add_theme_stylebox_override("panel", sp_s)
	
	var sp_m := MarginContainer.new()
	sp_m.add_theme_constant_override("margin_left", 18); sp_m.add_theme_constant_override("margin_right", 18)
	sp_m.add_theme_constant_override("margin_top", 6); sp_m.add_theme_constant_override("margin_bottom", 6)
	state_pill.add_child(sp_m)
	
	var state_lbl := Label.new()
	state_lbl.name = "StateLabel"
	state_lbl.text = "🎧 GIAI ĐOẠN 1: LẮNG NGHE TIẾT TẤU MẪU..."
	state_lbl.add_theme_font_size_override("font_size", 14)
	state_lbl.add_theme_color_override("font_color", Color("#b45309"))
	var font_bold: Font = load("res://assets/fonts/BeVietnamPro-Bold.ttf")
	if font_bold: state_lbl.add_theme_font_override("font", font_bold)
	sp_m.add_child(state_lbl)
	game_vbox.add_child(state_pill)
	
	# 2. Băng nhịp thị giác (Beat Blocks)
	var beat_track := HBoxContainer.new()
	beat_track.name = "BeatTrack"
	beat_track.alignment = BoxContainer.ALIGNMENT_CENTER
	beat_track.add_theme_constant_override("separation", 16)
	game_vbox.add_child(beat_track)
	
	for i in range(rhythm_beats.size()):
		var b_card := PanelContainer.new()
		b_card.name = "Beat_%d" % i
		b_card.custom_minimum_size = Vector2(80, 80)
		b_card.add_theme_stylebox_override("panel", _flat(Color.WHITE, Color("#cbd5e1"), 18, true, 2))
		
		var b_v := VBoxContainer.new()
		b_v.alignment = BoxContainer.ALIGNMENT_CENTER
		b_v.add_theme_constant_override("separation", 4)
		b_card.add_child(b_v)
		
		var b_icon := Label.new()
		b_icon.name = "Icon"
		b_icon.text = "♩"
		b_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b_icon.add_theme_font_size_override("font_size", 28)
		b_icon.add_theme_color_override("font_color", Color("#64748b"))
		b_v.add_child(b_icon)
		
		var b_num := Label.new()
		b_num.name = "Num"
		b_num.text = "Phách %d" % (i + 1)
		b_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b_num.add_theme_font_size_override("font_size", 12)
		b_num.add_theme_color_override("font_color", Color("#94a3b8"))
		b_v.add_child(b_num)
		
		beat_track.add_child(b_card)
		
	# 3. Phản hồi nhịp & Combo nổi bật
	var fb_lbl := Label.new()
	fb_lbl.name = "RhythmFeedbackLabel"
	fb_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fb_lbl.add_theme_font_size_override("font_size", 16)
	fb_lbl.text = "Lắng nghe thật kỹ nhé..."
	fb_lbl.add_theme_color_override("font_color", Color("#64748b"))
	game_vbox.add_child(fb_lbl)
	
	# 4. Bàn gõ nhịp lớn duy nhất (Big Tactile Tap Pad)
	var tap_btn := Button.new()
	tap_btn.name = "DrumBtn"
	tap_btn.text = "🥁 CHẠM ĐÚNG PHÁCH"
	tap_btn.custom_minimum_size = Vector2(300, 64)
	tap_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tap_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tap_btn.add_theme_font_size_override("font_size", 17)
	
	var btn_s := _flat(C_JADE, C_GOLD, 20, true, 3)
	tap_btn.add_theme_stylebox_override("normal", btn_s)
	tap_btn.add_theme_stylebox_override("hover", _flat(C_JADE_LIGHT, C_GOLD_LIGHT, 20, true, 3))
	tap_btn.add_theme_stylebox_override("pressed", _flat(C_JADE.darkened(0.2), C_GOLD, 20, false, 1))
	tap_btn.add_theme_color_override("font_color", Color.WHITE)
	tap_btn.disabled = true # Vô hiệu hóa trong giai đoạn nghe
	tap_btn.pressed.connect(_on_tap_pad_hit)
	_make_button_bouncy(tap_btn)
	game_vbox.add_child(tap_btn)
	
	# Bắt đầu phát mẫu nhịp (Giai đoạn 1)
	rhythm_phase = "listen"
	rhythm_listen_idx = 0
	rhythm_elapsed = 0.0
	rhythm_active = true
	_play_listen_sequence()


func _play_listen_sequence() -> void:
	if not is_inside_tree(): return
	var beat_track = game_vbox.get_node_or_null("BeatTrack") as HBoxContainer
	
	for i in range(rhythm_beats.size()):
		var b_time: float = rhythm_beats[i]
		get_tree().create_timer(b_time).timeout.connect(func() -> void:
			if rhythm_phase != "listen": return
			_play_synth_note(392.0) # Sound phách
			if beat_track and i < beat_track.get_child_count():
				var card = beat_track.get_child(i) as PanelContainer
				card.add_theme_stylebox_override("panel", _flat(Color("#fef3c7"), Color("#f59e0b"), 18, true, 3))
				var ic = card.find_child("Icon", true, false) as Label
				if ic: ic.add_theme_color_override("font_color", Color("#d97706"))
				
				var t := create_tween()
				t.tween_property(card, "scale", Vector2(1.15, 1.15), 0.08).set_trans(Tween.TRANS_BACK)
				t.tween_property(card, "scale", Vector2.ONE, 0.12)
		)
		
	# Khi phát mẫu xong -> Đếm ngược chuyển sang lượt người chơi
	get_tree().create_timer(rhythm_round_duration).timeout.connect(func() -> void:
		if not is_inside_tree(): return
		_start_player_turn()
	)


func _start_player_turn() -> void:
	rhythm_phase = "play"
	rhythm_elapsed = 0.0
	
	# Cập nhật huy hiệu trạng thái
	var sp = game_vbox.get_node_or_null("RhythmStatePill") as PanelContainer
	if sp:
		sp.add_theme_stylebox_override("panel", _flat(Color("#dcfce7"), Color("#16a34a"), 16, true, 1))
		var lbl = sp.find_child("StateLabel", true, false) as Label
		if lbl:
			lbl.text = "🎯 GIAI ĐOẠN 2: LƯỢT CỦA BẠN · GÕ ĐÚNG THEO NHỊP!"
			lbl.add_theme_color_override("font_color", Color("#15803D"))
			
	# Reset màu các ô phách
	var beat_track = game_vbox.get_node_or_null("BeatTrack") as HBoxContainer
	if beat_track:
		for card in beat_track.get_children():
			(card as PanelContainer).add_theme_stylebox_override("panel", _flat(Color.WHITE, Color("#cbd5e1"), 18, true, 2))
			var ic = card.find_child("Icon", true, false) as Label
			if ic: ic.add_theme_color_override("font_color", Color("#64748b"))
			
	# Bật nút gõ
	var btn = game_vbox.get_node_or_null("DrumBtn") as Button
	if btn:
		btn.disabled = false
		btn.text = "🥁 CHẠM ĐÚNG PHÁCH NGAY!"
		
	_show_rhythm_feedback("Bắt đầu gõ nào!", Color("#16a34a"))
	
	# Đặt timer kết thúc lượt
	get_tree().create_timer(rhythm_round_duration).timeout.connect(func() -> void:
		if rhythm_phase == "play":
			_finish_player_turn()
	)


func _on_tap_pad_hit() -> void:
	if rhythm_phase != "play": return
	_play_synth_note(392.0)
	
	var closest_idx := -1
	var min_diff := 999.0
	for i in range(rhythm_beats.size()):
		if rhythm_beat_judgements[i].is_empty():
			var diff = abs(rhythm_elapsed - rhythm_beats[i])
			if diff < min_diff:
				min_diff = diff
				closest_idx = i
				
	var beat_track = game_vbox.get_node_or_null("BeatTrack") as HBoxContainer
	if closest_idx >= 0 and min_diff <= 0.22:
		var is_perfect = (min_diff <= 0.09)
		rhythm_beat_judgements[closest_idx] = "PERFECT" if is_perfect else "GOOD"
		rhythm_combo += 1
		
		if is_perfect:
			score += 100
			_show_rhythm_feedback("✨ PERFECT! (+100) · 🔥 COMBO x%d" % rhythm_combo, Color("#16a34a"))
		else:
			score += 70
			_show_rhythm_feedback("👍 GOOD! (+70) · 🔥 COMBO x%d" % rhythm_combo, Color("#d97706"))
			
		score_label.text = "ĐIỂM: %d" % score
		
		# Đổi màu ô phách tương ứng
		if beat_track and closest_idx < beat_track.get_child_count():
			var card = beat_track.get_child(closest_idx) as PanelContainer
			var col = Color("#22c55e") if is_perfect else Color("#eab308")
			card.add_theme_stylebox_override("panel", _flat(Color("#f0fdf4") if is_perfect else Color("#fefce8"), col, 18, true, 3))
			var ic = card.find_child("Icon", true, false) as Label
			if ic:
				ic.text = "✓"
				ic.add_theme_color_override("font_color", col)
			var t := create_tween()
			t.tween_property(card, "scale", Vector2(1.18, 1.18), 0.08).set_trans(Tween.TRANS_BACK)
			t.tween_property(card, "scale", Vector2.ONE, 0.12)
	else:
		rhythm_combo = 0
		_show_rhythm_feedback("Hụt nhịp!", Color("#dc2626"))


func _finish_player_turn() -> void:
	rhythm_phase = "round_end"
	var btn = game_vbox.get_node_or_null("DrumBtn") as Button
	if btn: btn.disabled = true
	
	# Kiểm tra các phách chưa đánh
	var beat_track = game_vbox.get_node_or_null("BeatTrack") as HBoxContainer
	for i in range(rhythm_beats.size()):
		if rhythm_beat_judgements[i].is_empty():
			rhythm_beat_judgements[i] = "MISS"
			if beat_track and i < beat_track.get_child_count():
				var card = beat_track.get_child(i) as PanelContainer
				card.add_theme_stylebox_override("panel", _flat(Color("#fef2f2"), Color("#ef4444"), 18, true, 2))
				var ic = card.find_child("Icon", true, false) as Label
				if ic:
					ic.text = "✗"
					ic.add_theme_color_override("font_color", Color("#ef4444"))
					
	get_tree().create_timer(1.2).timeout.connect(func() -> void:
		current_round += 1
		_start_rhythm_round()
	)


func _show_rhythm_feedback(msg: String, color: Color) -> void:
	var fb = game_vbox.get_node_or_null("RhythmFeedbackLabel") as Label
	if fb:
		fb.text = msg
		fb.add_theme_color_override("font_color", color)
		fb.pivot_offset = fb.size / 2.0
		var t := create_tween()
		t.tween_property(fb, "scale", Vector2(1.1, 1.1), 0.08)
		t.tween_property(fb, "scale", Vector2.ONE, 0.1)


# ─── 3. Melody Game Mode (Ghép Giai Điệu - MINI-GAME 2) ─────────────────────────
func _start_melody_round() -> void:
	if current_round > max_rounds:
		_show_end_summary()
		return
		
	_clear_game_ui()
	top_title.text = "🎼 MINI-GAME 2 · HOÀN THIỆN GIAI ĐIỆU"
	
	header_row.visible = true
	prompt_label.visible = true
	play_circle.visible = true
	option_grid.visible = true
	
	var purple_play_s := _flat(Color("#7c3aed"), Color("#c4b5fd"), 40, true, 3)
	play_circle.add_theme_stylebox_override("panel", purple_play_s)
	
	game_active = true
	round_label.text = "VÒNG %d / %d" % [current_round, max_rounds]
	score_label.text = "ĐIỂM: %d" % score
	prompt_label.text = "Lắng nghe chuỗi ngũ cung và chọn nốt còn thiếu [?]:"
	prompt_label.add_theme_color_override("font_color", Color("#1e293b"))
	
	var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
	var melodies_pool = [
		["Tịch", "Cắc", "Tùng", "Cắc", "Tịch"],
		["Tùng", "Tịch", "Cắc", "Tịch", "Tùng"],
		["Cắc", "Tùng", "Tịch", "Tùng", "Cắc"]
	] if inst == "trong_chau" else MELODIES
	var note_pool = ["Tịch", "Cắc", "Tùng", "Cộc"] if inst == "trong_chau" else NOTES
	
	var raw_mel = melodies_pool[randi() % melodies_pool.size()]
	melody_notes.clear()
	for n in raw_mel:
		melody_notes.append(n)
		
	missing_idx = randi() % 5
	correct_note = melody_notes[missing_idx]
	
	# Băng nốt 5 ô ngang
	var cards_hbox := HBoxContainer.new()
	cards_hbox.name = "MelodyCards"
	cards_hbox.add_theme_constant_override("separation", 14)
	cards_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	game_vbox.add_child(cards_hbox)
	game_vbox.move_child(cards_hbox, 2)
	
	for i in range(5):
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(70, 86)
		var is_missing = (i == missing_idx)
		
		var card_s: StyleBoxFlat
		if is_missing:
			card_s = _flat(Color("#f5f3ff"), Color("#7c3aed"), 16, true, 3)
		else:
			card_s = _flat(Color(1.0, 1.0, 1.0, 0.95), Color("#c4b5fd"), 16, true, 2)
		card.add_theme_stylebox_override("panel", card_s)
		
		var card_v := VBoxContainer.new()
		card_v.alignment = BoxContainer.ALIGNMENT_CENTER
		card_v.add_theme_constant_override("separation", 2)
		card.add_child(card_v)
		
		var card_icon := Label.new()
		card_icon.text = "❓" if is_missing else "🎵"
		card_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card_icon.add_theme_font_size_override("font_size", 14)
		card_v.add_child(card_icon)
		
		var card_lbl := Label.new()
		card_lbl.name = "NoteLabel"
		card_lbl.text = "?" if is_missing else melody_notes[i]
		card_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card_lbl.add_theme_font_size_override("font_size", 18 if is_missing else 16)
		card_lbl.add_theme_color_override("font_color", Color("#7c3aed") if is_missing else Color("#1e293b"))
		card_v.add_child(card_lbl)
		
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
		
	var is_mobile: bool = get_viewport().get_visible_rect().size.x < 768.0
	for opt in options:
		var btn := Button.new()
		btn.text = opt
		btn.custom_minimum_size = Vector2(180, 52) if is_mobile else Vector2(220, 58)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.add_theme_font_size_override("font_size", 17)
		
		var b_n := _flat(Color.WHITE, Color("#c4b5fd"), 16, true, 2)
		var b_h := _flat(Color("#f5f3ff"), Color("#7c3aed"), 16, true, 2)
		var b_p := _flat(Color("#ede9fe"), Color("#7c3aed"), 16, false, 1)
		btn.add_theme_stylebox_override("normal", b_n)
		btn.add_theme_stylebox_override("hover", b_h)
		btn.add_theme_stylebox_override("pressed", b_p)
		btn.add_theme_color_override("font_color", Color("#4c1d95"))
		btn.add_theme_color_override("font_hover_color", Color("#7c3aed"))
		
		btn.pressed.connect(func() -> void: _submit_melody_answer(opt, btn))
		_make_button_bouncy(btn)
		option_grid.add_child(btn)
		
	if play_btn.is_connected("pressed", _play_correct_sound):
		play_btn.pressed.disconnect(_play_correct_sound)
	if not play_btn.is_connected("pressed", _play_melody_sequence):
		play_btn.pressed.connect(_play_melody_sequence)
		
	get_tree().create_timer(0.35).timeout.connect(_play_melody_sequence)


func _play_melody_sequence() -> void:
	if is_playing_melody: return
	is_playing_melody = true
	current_play_index = 0
	
	if not melody_timer:
		melody_timer = Timer.new()
		add_child(melody_timer)
		melody_timer.timeout.connect(_on_melody_timer_timeout)
		
	melody_timer.wait_time = 0.55
	melody_timer.start()
	_on_melody_timer_timeout()


func _on_melody_timer_timeout() -> void:
	var cards_hbox = game_vbox.get_node_or_null("MelodyCards") as HBoxContainer
	if cards_hbox:
		for i in range(5):
			var card = cards_hbox.get_child(i) as PanelContainer
			var is_missing = (i == missing_idx)
			var card_s := _flat(Color("#f5f3ff") if is_missing else Color(1.0, 1.0, 1.0, 0.95), Color("#7c3aed") if is_missing else Color("#c4b5fd"), 16, true, 2)
			card.add_theme_stylebox_override("panel", card_s)
			card.scale = Vector2.ONE
			
	if current_play_index >= 5:
		melody_timer.stop()
		is_playing_melody = false
		return
		
	if cards_hbox and current_play_index < cards_hbox.get_child_count():
		var card = cards_hbox.get_child(current_play_index) as PanelContainer
		var is_missing = (current_play_index == missing_idx)
		var highlight_s := _flat(Color("#7c3aed"), Color("#ddd6fe"), 16, true, 3)
		card.add_theme_stylebox_override("panel", highlight_s)
		
		var t := create_tween()
		t.tween_property(card, "scale", Vector2(1.1, 1.1), 0.08)
		t.tween_property(card, "scale", Vector2.ONE, 0.1)
		
	var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
	var drum_freqs = {"Tịch": 100.0, "Cắc": 1000.0, "Tùng": 150.0, "Cộc": 800.0}
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
	var cards_hbox = game_vbox.get_node_or_null("MelodyCards") as HBoxContainer
	if cards_hbox and missing_idx < cards_hbox.get_child_count():
		var card = cards_hbox.get_child(missing_idx) as PanelContainer
		var label = card.find_child("NoteLabel", true, false) as Label
		if label:
			label.text = correct_note
			label.add_theme_color_override("font_color", C_JADE if is_correct else C_RED_ERR)
		
	if is_correct:
		correct_answers += 1
		score += 120
		_play_synth_note(523.25)
		btn.add_theme_stylebox_override("normal", _flat(C_JADE, Color(0.35, 0.85, 0.6, 0.8), 16, true, 3))
		btn.add_theme_color_override("font_color", Color.WHITE)
		result_lbl.text = "✨ Tuyệt vời! Bạn ghép đúng nốt."
		feedback_pan.add_theme_stylebox_override("panel", _flat(C_JADE, Color(0.35, 0.85, 0.6, 0.6), 14))
	else:
		_play_synth_note(130.81)
		btn.add_theme_stylebox_override("normal", _flat(C_RED_ERR, Color(1, 1, 1, 0.3), 16, true, 3))
		btn.add_theme_color_override("font_color", Color.WHITE)
		for c in option_grid.get_children():
			var opt_btn = c as Button
			if opt_btn and opt_btn.text == correct_note:
				opt_btn.add_theme_stylebox_override("normal", _flat(C_JADE, Color(0.35, 0.85, 0.6, 0.8), 16, true, 3))
				opt_btn.add_theme_color_override("font_color", Color.WHITE)
		result_lbl.text = "❌ Nốt khuyết trong câu là %s" % correct_note
		feedback_pan.add_theme_stylebox_override("panel", _flat(C_BG_DARK, Color(C_RED_ERR.r, C_RED_ERR.g, C_RED_ERR.b, 0.4), 14))
		
	feedback_pan.visible = true
	get_tree().create_timer(1.8).timeout.connect(func() -> void:
		current_round += 1
		_start_melody_round()
	)


# ─── Victory End Summary ──────────────────────────────────────────────────────
func _show_end_summary() -> void:
	_clear_game_ui()
	top_title.text = "🎉 HOÀN THÀNH THỬ THÁCH"
	
	var earned_xp := int(score * 0.5)
	var earned_stars := 3 if score >= 400 else (2 if score >= 200 else 1)
	
	if earned_xp > 0:
		var cur_pts = SecureDataManager.data.get("total_points", 0)
		var cur_stars = SecureDataManager.data.get("stars", 0)
		var pts_int := int(str(cur_pts)) if cur_pts != null else 0
		var stars_int := int(str(cur_stars)) if cur_stars != null else 0
		SecureDataManager.data["total_points"] = pts_int + earned_xp
		SecureDataManager.data["stars"] = stars_int + earned_stars
		SecureDataManager.save_data()
		_update_top_hud()
		
	var summary_panel := PanelContainer.new()
	summary_panel.name = "EndSummaryPanel"
	summary_panel.custom_minimum_size = Vector2(360, 240)
	summary_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	summary_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	summary_panel.add_theme_stylebox_override("panel", _flat(C_CREAM, C_GOLD, 24, true, 4))
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	summary_panel.add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	var star_str := "⭐ ⭐ ⭐" if earned_stars == 3 else ("⭐ ⭐" if earned_stars == 2 else "⭐")
	var star_display := Label.new()
	star_display.text = star_str
	star_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star_display.add_theme_font_size_override("font_size", 32)
	vbox.add_child(star_display)
	
	var score_final := Label.new()
	score_final.text = "Tổng điểm: %d" % score
	score_final.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_final.add_theme_font_size_override("font_size", 20)
	score_final.add_theme_color_override("font_color", C_RED_SON)
	vbox.add_child(score_final)
	
	var reward_lbl := Label.new()
	reward_lbl.text = "Thưởng: +%d XP  ·  +%d Sao ⭐" % [earned_xp, earned_stars]
	reward_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_lbl.add_theme_font_size_override("font_size", 14)
	reward_lbl.add_theme_color_override("font_color", C_GOLD_DARK)
	vbox.add_child(reward_lbl)
	
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)
	
	var retry_btn := Button.new()
	retry_btn.text = "🔄 Chơi Lại"
	retry_btn.custom_minimum_size = Vector2(130, 44)
	retry_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	retry_btn.add_theme_font_size_override("font_size", 14)
	retry_btn.add_theme_stylebox_override("normal", _flat(C_CARD, C_GOLD, 14, true, 2))
	retry_btn.add_theme_stylebox_override("hover", _flat(C_CARD, C_GOLD_LIGHT, 14, true, 2))
	retry_btn.add_theme_color_override("font_color", C_TEXT)
	retry_btn.pressed.connect(func() -> void: _start_game_mode(game_mode))
	_make_button_bouncy(retry_btn)
	btn_row.add_child(retry_btn)
	
	var home_btn := Button.new()
	home_btn.text = "➔ Danh Mục"
	home_btn.custom_minimum_size = Vector2(130, 44)
	home_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	home_btn.add_theme_font_size_override("font_size", 14)
	home_btn.add_theme_stylebox_override("normal", _flat(C_RED_SON, C_GOLD, 14, true, 2))
	home_btn.add_theme_stylebox_override("hover", _flat(C_RED_SON_DK, C_GOLD_LIGHT, 14, true, 2))
	home_btn.add_theme_color_override("font_color", Color.WHITE)
	home_btn.pressed.connect(_show_mode_selection_menu)
	_make_button_bouncy(home_btn)
	btn_row.add_child(home_btn)
	
	game_vbox.add_child(summary_panel)


# ─── Sound Synthesis ─────────────────────────────────────────────────────────
func _play_correct_sound() -> void:
	var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
	var drum_freqs = {"Tịch": 100.0, "Cắc": 1000.0, "Tùng": 150.0, "Cộc": 800.0}
	if inst == "trong_chau":
		if drum_freqs.has(correct_note):
			_play_synth_note(drum_freqs[correct_note])
	else:
		if FREQS.has(correct_note):
			_play_synth_note(FREQS[correct_note])


func _play_synth_note(freq: float) -> void:
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
		var sample_count := int(44100 * 0.45)
		var playback_phase := 0.0
		var frames := PackedVector2Array()
		
		for i in range(sample_count):
			var t := float(i) / 44100.0
			var sample := 0.0
			var amplitude_envelope := 1.0
			var current_freq := freq
			
			match inst:
				"dan_tranh":
					amplitude_envelope = exp(-t * 6.0)
					sample = sin(playback_phase) + 0.5 * sin(playback_phase * 2.0) + 0.25 * sin(playback_phase * 3.0)
					sample *= 0.25
				"sao_truc":
					amplitude_envelope = (t / 0.08) if t < 0.08 else exp(-(t - 0.08) * 1.8)
					var vibrato = 1.0 + 0.008 * sin(t * 6.0 * TAU)
					current_freq = freq * vibrato
					sample = sin(playback_phase) + 0.15 * sin(playback_phase * 3.0)
					sample = (sample * 0.25) + ((randf() * 2.0 - 1.0) * 0.02)
				"trong_chau":
					if freq == 100.0:
						amplitude_envelope = exp(-t * 12.0)
						sample = sin(playback_phase)
					elif freq == 1000.0:
						amplitude_envelope = exp(-t * 26.0)
						sample = sin(playback_phase)
					else:
						amplitude_envelope = exp(-t * 8.0)
						sample = sin(playback_phase)
					sample *= 0.35
				"dan_bau", _:
					amplitude_envelope = exp(-t * 3.2)
					var slide = (0.94 + 0.06 * (t / 0.15)) if t < 0.15 else 1.0
					var vibrato = 1.0 + 0.016 * sin(t * 5.0 * TAU)
					current_freq = freq * slide * vibrato
					sample = sin(playback_phase) + 0.45 * sin(playback_phase * 2.0) + 0.3 * sin(playback_phase * 3.0)
					sample *= 0.25
					
			frames.append(Vector2(sample * amplitude_envelope, sample * amplitude_envelope))
			playback_phase += current_freq * TAU / 44100.0
			
		playback.push_buffer(frames)
		
	get_tree().create_timer(0.5).timeout.connect(player.queue_free)


func _get_instrument_name(inst: String) -> String:
	match inst:
		"dan_bau": return "Đàn Bầu"
		"sao_truc": return "Sáo Trúc"
		"trong_chau": return "Trống Chầu"
		_: return "Đàn Tranh"


# ─── Style & Helpers ──────────────────────────────────────────────────────────
func _flat(bg: Color, border: Color, radius: int, shadow: bool = false, offset_bottom: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left = 2
	s.border_width_right = 2
	s.border_width_top = 2
	s.border_width_bottom = 2 + offset_bottom
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	if shadow:
		s.shadow_size = 6
		s.shadow_color = Color(0.05, 0.1, 0.08, 0.12)
		s.shadow_offset = Vector2(0, 3)
	return s


func _make_button_bouncy(btn: Button) -> void:
	btn.pivot_offset = btn.size / 2.0
	btn.resized.connect(func() -> void: btn.pivot_offset = btn.size / 2.0)
	btn.mouse_entered.connect(func() -> void:
		var t := create_tween()
		t.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1).set_trans(Tween.TRANS_BACK)
	)
	btn.mouse_exited.connect(func() -> void:
		var t := create_tween()
		t.tween_property(btn, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_BACK)
	)


func _on_viewport_size_changed() -> void:
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var is_mobile: bool = vp_size.x < vp_size.y or vp_size.x < 768.0
	option_grid.columns = 1 if is_mobile else 2
