extends Control
class_name QuizScreen
## Màn hình Quiz - Hỗ Trợ 2 Dạng: Nhận Diện Nốt Trên Khuôn Nhạc & Trả Lời Câu Hỏi

const C_JADE        := Color("#173f2d")
const C_JADE_LIGHT  := Color("#245f43")
const C_GOLD        := Color("#c59626")
const C_GOLD_LIGHT  := Color("#f0cb62")
const C_CARD        := Color("#ffffff")
const C_TEXT        := Color("#1e293b")
const C_TEXT_MUTED  := Color("#64748b")
const C_OK          := Color("#16a34a")
const C_OK_BG       := Color("#dcfce7")
const C_BAD         := Color("#dc2626")
const C_BAD_BG      := Color("#fee2e2")

# Context properties
var quiz_instrument: String = ""

var _quizzes: Array = []
var _index := 0
var _score := 0
var _correct_count := 0
var _answered := false
var _current_note_pitch := "C4"
var _current_note_freq := 261.63

@onready var back_btn       : Button = $Root/TopBar/TopH/BackBtn
@onready var title_pill     : PanelContainer = $Root/TopBar/TopH/TitlePill
@onready var top_title      : Label  = $Root/TopBar/TopH/TitlePill/Margin/Title
@onready var stat_chip      : PanelContainer = $Root/TopBar/TopH/StatChip
@onready var stat_lbl       : Label  = $Root/TopBar/TopH/StatChip/Margin/StatLbl

@onready var card           : PanelContainer = $Root/ContentMargin/CenterBox/Card
@onready var game_vbox      : VBoxContainer  = $Root/ContentMargin/CenterBox/Card/CardM/GameVBox
@onready var header_row     : HBoxContainer  = $Root/ContentMargin/CenterBox/Card/CardM/GameVBox/HeaderRow
@onready var progress_pill  : PanelContainer = $Root/ContentMargin/CenterBox/Card/CardM/GameVBox/HeaderRow/ProgressPill
@onready var type_pill      : PanelContainer = $Root/ContentMargin/CenterBox/Card/CardM/GameVBox/HeaderRow/TypePill
@onready var score_pill     : PanelContainer = $Root/ContentMargin/CenterBox/Card/CardM/GameVBox/HeaderRow/ScorePill
@onready var progress_lbl   : Label  = $Root/ContentMargin/CenterBox/Card/CardM/GameVBox/HeaderRow/ProgressPill/M/ProgressLbl
@onready var type_lbl       : Label  = $Root/ContentMargin/CenterBox/Card/CardM/GameVBox/HeaderRow/TypePill/M/TypeLbl
@onready var score_lbl      : Label  = $Root/ContentMargin/CenterBox/Card/CardM/GameVBox/HeaderRow/ScorePill/M/ScoreLbl

@onready var question_lbl   : Label  = $Root/ContentMargin/CenterBox/Card/CardM/GameVBox/QuestionLbl
@onready var staff_container: PanelContainer = $Root/ContentMargin/CenterBox/Card/CardM/GameVBox/StaffContainer
@onready var staff_view     : Control = $Root/ContentMargin/CenterBox/Card/CardM/GameVBox/StaffContainer/StaffM/StaffHBox/StaffView
@onready var play_note_btn  : Button = $Root/ContentMargin/CenterBox/Card/CardM/GameVBox/StaffContainer/StaffM/StaffHBox/PlayNoteBtn
@onready var options_grid   : GridContainer  = $Root/ContentMargin/CenterBox/Card/CardM/GameVBox/OptionsGrid
@onready var feedback_pan   : PanelContainer = $Root/ContentMargin/CenterBox/Card/CardM/GameVBox/FeedbackPanel
@onready var feedback_lbl   : Label  = $Root/ContentMargin/CenterBox/Card/CardM/GameVBox/FeedbackPanel/FeedbackM/FeedbackLbl
@onready var bottom_row     : HBoxContainer  = $Root/ContentMargin/CenterBox/Card/CardM/GameVBox/BottomRow
@onready var next_btn       : Button = $Root/ContentMargin/CenterBox/Card/CardM/GameVBox/BottomRow/NextBtn

func _ready() -> void:
	SecureDataManager.load_data()
	_build_theme()
	_update_header_stats()
	
	back_btn.pressed.connect(_go_back)
	_make_btn_bouncy(back_btn)
	next_btn.pressed.connect(_on_next_pressed)
	_make_btn_bouncy(next_btn)
	play_note_btn.pressed.connect(func() -> void: _play_synth(_current_note_freq))
	_make_btn_bouncy(play_note_btn)
	
	staff_view.draw.connect(_on_draw_staff)
	
	quiz_instrument = str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
		
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.22)
	
	_begin_quiz()

func _go_back() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.18)
	t.tween_callback(func() -> void:
		get_tree().change_scene_to_file("res://scenes/LearningActivitiesScreen.tscn")
	)

func _build_theme() -> void:
	# Back Button
	var btn_s := _flat(Color(1.0, 1.0, 1.0, 0.95), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.4), 24, true, 2)
	back_btn.add_theme_stylebox_override("normal", btn_s)
	back_btn.add_theme_stylebox_override("hover", _flat(Color.WHITE, C_GOLD_LIGHT, 24, true, 2))
	back_btn.add_theme_stylebox_override("pressed", _flat(Color(0.94, 0.92, 0.88), C_GOLD, 24, false, 1))
	back_btn.add_theme_color_override("font_color", C_JADE)
	back_btn.add_theme_color_override("font_hover_color", C_JADE)

	# Pills
	var chip_s := _flat(Color(1.0, 1.0, 1.0, 0.92), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35), 18, true, 1)
	title_pill.add_theme_stylebox_override("panel", chip_s)
	stat_chip.add_theme_stylebox_override("panel", chip_s)
	
	var pill_inner := _flat(Color(0.95, 0.96, 0.98), Color("#cbd5e1"), 12, true, 1)
	progress_pill.add_theme_stylebox_override("panel", pill_inner)
	type_pill.add_theme_stylebox_override("panel", _flat(Color("#eff6ff"), Color("#3b82f6"), 12, true, 1))
	score_pill.add_theme_stylebox_override("panel", _flat(Color("#fef3c7"), Color("#f59e0b"), 12, true, 1))
	
	var font_bold: Font = load("res://assets/fonts/BeVietnamPro-Bold.ttf")
	if font_bold:
		top_title.add_theme_font_override("font", font_bold)
		stat_lbl.add_theme_font_override("font", font_bold)
		progress_lbl.add_theme_font_override("font", font_bold)
		type_lbl.add_theme_font_override("font", font_bold)
		score_lbl.add_theme_font_override("font", font_bold)
		question_lbl.add_theme_font_override("font", font_bold)
		next_btn.add_theme_font_override("font", font_bold)
		play_note_btn.add_theme_font_override("font", font_bold)
		
	top_title.add_theme_color_override("font_color", C_JADE)
	stat_lbl.add_theme_color_override("font_color", C_GOLD)
	progress_lbl.add_theme_color_override("font_color", C_JADE)
	type_lbl.add_theme_color_override("font_color", Color("#1d4ed8"))
	score_lbl.add_theme_color_override("font_color", Color("#b45309"))
	question_lbl.add_theme_color_override("font_color", C_TEXT)

	# Main Card Surface
	var card_s := _flat(Color(1.0, 1.0, 1.0, 0.96), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.3), 24, true, 2)
	card.add_theme_stylebox_override("panel", card_s)

	# Staff Container Surface
	var staff_s := _flat(Color(0.99, 0.99, 0.98, 0.9), Color("#e2d8c9"), 16, true, 1)
	staff_container.add_theme_stylebox_override("panel", staff_s)

	# Play Note Button
	var pnb_s := _flat(Color("#f0fdf4"), Color("#16a34a"), 14, true, 2)
	play_note_btn.add_theme_stylebox_override("normal", pnb_s)
	play_note_btn.add_theme_stylebox_override("hover", _flat(Color.WHITE, Color("#22c55e"), 14, true, 2))
	play_note_btn.add_theme_stylebox_override("pressed", _flat(Color("#dcfce7"), Color("#15803d"), 14, false, 1))
	play_note_btn.add_theme_color_override("font_color", Color("#15803d"))

	# Next Button
	next_btn.add_theme_stylebox_override("normal", _flat(C_JADE, C_GOLD, 16, true, 2))
	next_btn.add_theme_stylebox_override("hover", _flat(C_JADE_LIGHT, C_GOLD_LIGHT, 16, true, 2))
	next_btn.add_theme_stylebox_override("pressed", _flat(C_JADE.darkened(0.15), C_GOLD, 16, false, 1))
	next_btn.add_theme_color_override("font_color", Color.WHITE)

func _update_header_stats() -> void:
	var total_stars: int = SecureDataManager.get_total_stars()
	stat_lbl.text = "⭐ %d Sao" % total_stars

func _begin_quiz() -> void:
	_quizzes = _get_default_quizzes()
	_index = 0
	_score = 0
	_correct_count = 0
	_show_question()

func _get_default_quizzes() -> Array:
	return [
		# ── DẠNG 1: NHẬN DIỆN NỐT TRÊN KHUÔN NHẠC (5-line Staff Note Recognition) ──
		{
			"type": "staff_note",
			"pitch": "C4",
			"freq": 261.63,
			"question": "Nốt nhạc đang hiển thị trên dòng kẻ phụ dưới khuôn nhạc là nốt gì?",
			"options": ["Nốt Đô (C4) · Hò", "Nốt Rê (D4) · Xự", "Nốt Mi (E4) · Xang", "Nốt Son (G4) · Xê"],
			"answer": 0,
			"explanation": "Nốt Đô trung (C4 / Hò) nằm trên dòng kẻ phụ thứ nhất phía dưới khuôn nhạc khóa Sol."
		},
		{
			"type": "staff_note",
			"pitch": "G4",
			"freq": 392.00,
			"question": "Nốt nhạc nằm chính giữa dòng kẻ thứ 2 (dòng khóa Sol) là nốt gì?",
			"options": ["Nốt Son (G4) · Xê", "Nốt Mi (E4) · Xự", "Nốt La (A4) · Cống", "Nốt Fa (F4) · Xang"],
			"answer": 0,
			"explanation": "Dòng kẻ thứ 2 từ dưới lên là dòng chuẩn của Khóa Sol, mang cao độ nốt Son (G4 / Xê)."
		},
		{
			"type": "staff_note",
			"pitch": "E4",
			"freq": 329.63,
			"question": "Nốt nhạc nằm chính giữa dòng kẻ thứ 1 (dòng dưới cùng) là nốt gì?",
			"options": ["Nốt Mi (E4) · Xự", "Nốt Đô (C4) · Hò", "Nốt Fa (F4) · Xang", "Nốt La (A4) · Cống"],
			"answer": 0,
			"explanation": "Dòng kẻ thứ nhất (dưới cùng của khuôn nhạc) biểu thị nốt Mi (E4 / Xự)."
		},
		{
			"type": "staff_note",
			"pitch": "A4",
			"freq": 440.00,
			"question": "Nốt nhạc nằm trong khe thứ 2 (giữa dòng 2 và dòng 3) là nốt gì?",
			"options": ["Nốt La (A4) · Cống", "Nốt Son (G4) · Xê", "Nốt Si (B4) · Phan", "Nốt Đô cao (C5)"],
			"answer": 0,
			"explanation": "Khe thứ 2 từ dưới lên mang cao độ nốt La chuẩn 440Hz (A4 / Cống)."
		},
		# ── DẠNG 2: CÂU HỎI LÝ THUYẾT ÂM NHẠC TRUYỀN THỐNG (Music Theory) ─────────
		{
			"type": "theory",
			"pitch": "",
			"freq": 0.0,
			"question": "Hệ thống thang âm ngũ cung truyền thống Việt Nam bao gồm những nốt nào?",
			"options": ["Hò, Xự, Xang, Xê, Cống", "Đồ, Rê, Mi, Pha, Son", "La, Si, Đô, Rê, Mi", "Hò, Lự, Sang, Tịch, Cắc"],
			"answer": 0,
			"explanation": "Thang âm ngũ cung truyền thống gồm 5 bậc cơ bản: Hò, Xự, Xang, Xê, Cống."
		},
		{
			"type": "theory",
			"pitch": "",
			"freq": 0.0,
			"question": "Đàn Tranh truyền thống Việt Nam thuộc họ nhạc cụ nào?",
			"options": ["Nhạc cụ bộ dây gảy", "Nhạc cụ bộ hơi (thổi)", "Nhạc cụ bộ gõ", "Nhạc cụ bộ kéo"],
			"answer": 0,
			"explanation": "Đàn Tranh là nhạc cụ dây gảy với các con nhạn đỡ dây và móng gảy trên dây."
		},
		{
			"type": "theory",
			"pitch": "",
			"freq": 0.0,
			"question": "Trong nghệ thuật biểu diễn Đàn Bầu, âm thanh độc đáo được tạo ra chủ yếu bằng kỹ thuật gì?",
			"options": ["Gảy nốt bồi & uốn cần đàn", "Bấm phím kim loại", "Gõ búa vào dây", "Thổi luồng hơi qua cần"],
			"answer": 0,
			"explanation": "Đàn Bầu sử dụng kỹ thuật gảy chạm tay tạo nốt bồi kết hợp uốn cần để luyến láy cung bậc."
		}
	]

func _show_question() -> void:
	if _index >= _quizzes.size():
		_show_victory_summary()
		return
		
	_answered = false
	header_row.visible = true
	question_lbl.visible = true
	options_grid.visible = true
	feedback_pan.visible = false
	next_btn.visible = false

	var quiz: Dictionary = _quizzes[_index]
	var q_type: String = str(quiz.get("type", "theory"))
	
	progress_lbl.text = "CÂU %d / %d" % [_index + 1, _quizzes.size()]
	score_lbl.text = "ĐIỂM: %d" % _score
	question_lbl.text = str(quiz.get("question", ""))

	if q_type == "staff_note":
		type_lbl.text = "🎼 NHẬN DIỆN NỐT"
		type_pill.add_theme_stylebox_override("panel", _flat(Color("#eff6ff"), Color("#3b82f6"), 12, true, 1))
		type_lbl.add_theme_color_override("font_color", Color("#1d4ed8"))
		
		staff_container.visible = true
		_current_note_pitch = str(quiz.get("pitch", "C4"))
		_current_note_freq = float(quiz.get("freq", 261.63))
		staff_view.queue_redraw()
	else:
		type_lbl.text = "📖 LÝ THUYẾT"
		type_pill.add_theme_stylebox_override("panel", _flat(Color("#f0fdf4"), Color("#16a34a"), 12, true, 1))
		type_lbl.add_theme_color_override("font_color", Color("#15803d"))
		
		staff_container.visible = false

	for child in options_grid.get_children():
		child.queue_free()

	var options: Array = quiz.get("options", [])
	var correct_idx: int = int(quiz.get("answer", 0))

	for i in range(options.size()):
		var opt_text := str(options[i])
		var btn := Button.new()
		btn.text = "%s. %s" % ["ABCD"[i] if i < 4 else str(i + 1), opt_text]
		btn.custom_minimum_size = Vector2(380, 52)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.add_theme_font_size_override("font_size", 15)
		
		var b_norm := _flat(Color(1.0, 1.0, 1.0, 0.98), Color("#cbd5e1"), 16, true, 1)
		btn.add_theme_stylebox_override("normal", b_norm)
		btn.add_theme_stylebox_override("hover", _flat(Color.WHITE, C_GOLD, 16, true, 2))
		btn.add_theme_stylebox_override("pressed", _flat(Color(0.94, 0.96, 0.98), C_JADE, 16, false, 1))
		btn.add_theme_color_override("font_color", C_TEXT)
		btn.add_theme_color_override("font_hover_color", C_JADE)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		btn.pressed.connect(func() -> void: _on_option_selected(i, correct_idx, btn))
		_make_btn_bouncy(btn)
		options_grid.add_child(btn)

func _on_draw_staff() -> void:
	var sz := staff_view.size
	if sz.x < 50.0: return
	
	var cy := sz.y * 0.48
	var line_spacing := 10.0
	var staff_width := sz.x - 32.0
	var start_x := 16.0
	var end_x := start_x + staff_width
	
	# 5 lines of musical staff (Line 1 bottom to Line 5 top)
	# Y coordinates: Line 5 (cy - 20), Line 4 (cy - 10), Line 3 (cy), Line 2 (cy + 10), Line 1 (cy + 20)
	for i in range(5):
		var ly: float = cy + (2 - i) * line_spacing
		staff_view.draw_line(Vector2(start_x, ly), Vector2(end_x, ly), Color(0.2, 0.25, 0.3, 0.85), 1.5)
		
	# Khóa Sol (Treble Clef 𝄞) on the left
	var font_bold: Font = load("res://assets/fonts/BeVietnamPro-Bold.ttf")
	if font_bold:
		staff_view.draw_string(font_bold, Vector2(start_x + 12.0, cy + 16.0), "𝄞", HORIZONTAL_ALIGNMENT_LEFT, -1, 38, Color(0.12, 0.37, 0.23))
		
	# Note positioning calculation
	# Pitch -> vertical position relative to lines
	# Line 1 (E4) = cy + 20.0
	# Line 2 (G4) = cy + 10.0
	# Line 3 (B4) = cy
	# Line 4 (D5) = cy - 10.0
	# Line 5 (F5) = cy - 20.0
	# Space 1 (F4) = cy + 15.0
	# Space 2 (A4) = cy + 5.0
	# Space 3 (C5) = cy - 5.0
	# Space below Line 1 (D4) = cy + 25.0
	# Middle C (C4) = cy + 30.0 (with ledger line at cy + 30.0)
	
	var note_y := cy + 30.0
	var has_ledger := false
	match _current_note_pitch:
		"C4":
			note_y = cy + 30.0
			has_ledger = true
		"D4":
			note_y = cy + 25.0
		"E4":
			note_y = cy + 20.0
		"F4":
			note_y = cy + 15.0
		"G4":
			note_y = cy + 10.0
		"A4":
			note_y = cy + 5.0
		"B4":
			note_y = cy
		"C5":
			note_y = cy - 5.0
		"D5":
			note_y = cy - 10.0
		"E5":
			note_y = cy - 15.0
		"F5":
			note_y = cy - 20.0
			
	var note_x := start_x + staff_width * 0.52
	
	# Draw ledger line if below or above staff
	if has_ledger:
		staff_view.draw_line(Vector2(note_x - 16, note_y), Vector2(note_x + 16, note_y), Color(0.2, 0.25, 0.3, 0.9), 1.5)
		
	# Draw notehead (Oval solid circle with angle)
	var note_color := Color("#173f2d")
	staff_view.draw_circle(Vector2(note_x, note_y), 6.5, note_color)
	
	# Draw stem (đuôi nốt)
	var stem_up := (note_y >= cy)
	var stem_x: float = note_x + (5.5 if stem_up else -5.5)
	var stem_y: float = note_y - (26.0 if stem_up else -26.0)
	staff_view.draw_line(Vector2(stem_x, note_y), Vector2(stem_x, stem_y), note_color, 2.0)

func _on_option_selected(chosen_idx: int, correct_idx: int, btn: Button) -> void:
	if _answered: return
	_answered = true

	var is_correct := (chosen_idx == correct_idx)
	if is_correct:
		_correct_count += 1
		_score += 100
		_play_synth(523.25)
		btn.add_theme_stylebox_override("normal", _flat(C_OK_BG, C_OK, 16, true, 2))
		btn.add_theme_color_override("font_color", C_OK)
		
		feedback_lbl.text = "✨ Chính xác! (+100 điểm)"
		feedback_lbl.add_theme_color_override("font_color", C_OK)
		feedback_pan.add_theme_stylebox_override("panel", _flat(C_OK_BG, C_OK, 14, true, 1))
	else:
		_play_synth(164.81)
		btn.add_theme_stylebox_override("normal", _flat(C_BAD_BG, C_BAD, 16, true, 2))
		btn.add_theme_color_override("font_color", C_BAD)
		
		# Highlight correct button
		var children := options_grid.get_children()
		if correct_idx < children.size():
			var cor_btn = children[correct_idx] as Button
			if cor_btn:
				cor_btn.add_theme_stylebox_override("normal", _flat(C_OK_BG, C_OK, 16, true, 2))
				cor_btn.add_theme_color_override("font_color", C_OK)
				
		var expl := str(_quizzes[_index].get("explanation", ""))
		feedback_lbl.text = "❌ Chưa đúng! %s" % expl
		feedback_lbl.add_theme_color_override("font_color", C_BAD)
		feedback_pan.add_theme_stylebox_override("panel", _flat(C_BAD_BG, C_BAD, 14, true, 1))

	score_lbl.text = "ĐIỂM: %d" % _score
	feedback_pan.visible = true
	next_btn.visible = true

func _on_next_pressed() -> void:
	_index += 1
	_show_question()

func _show_victory_summary() -> void:
	header_row.visible = false
	question_lbl.visible = false
	staff_container.visible = false
	options_grid.visible = false
	feedback_pan.visible = false
	next_btn.visible = false

	# Save progress
	var stars := 3 if _correct_count >= 5 else (2 if _correct_count >= 3 else 1)
	SecureDataManager.data["stars_total"] = SecureDataManager.get_total_stars() + stars
	SecureDataManager.record_quiz_result(1, _correct_count, _quizzes.size(), stars, _score)
	_update_header_stats()

	var vic_v := VBoxContainer.new()
	vic_v.name = "VictoryContainer"
	vic_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vic_v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vic_v.alignment = BoxContainer.ALIGNMENT_CENTER
	vic_v.add_theme_constant_override("separation", 16)

	var icon_circle := PanelContainer.new()
	icon_circle.custom_minimum_size = Vector2(88, 88)
	icon_circle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_circle.add_theme_stylebox_override("panel", _flat(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.15), C_GOLD, 44, true, 2))
	var ic_lbl := Label.new()
	ic_lbl.text = "🏆"
	ic_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ic_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ic_lbl.add_theme_font_size_override("font_size", 42)
	icon_circle.add_child(ic_lbl)
	vic_v.add_child(icon_circle)

	var title_l := Label.new()
	title_l.text = "HOÀN THÀNH BÀI KIỂM TRA!"
	title_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_l.add_theme_font_size_override("font_size", 22)
	title_l.add_theme_color_override("font_color", C_JADE)
	vic_v.add_child(title_l)

	var stars_l := Label.new()
	stars_l.text = "⭐".repeat(stars)
	stars_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars_l.add_theme_font_size_override("font_size", 26)
	vic_v.add_child(stars_l)

	var score_l := Label.new()
	score_l.text = "Đúng %d / %d câu  ·  Tổng điểm: +%d XP" % [_correct_count, _quizzes.size(), _score]
	score_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_l.add_theme_font_size_override("font_size", 16)
	score_l.add_theme_color_override("font_color", C_TEXT_MUTED)
	vic_v.add_child(score_l)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	vic_v.add_child(btn_row)

	var retry_btn := Button.new()
	retry_btn.text = "🔄 Làm Lại"
	retry_btn.custom_minimum_size = Vector2(160, 48)
	retry_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	retry_btn.add_theme_font_size_override("font_size", 15)
	retry_btn.add_theme_stylebox_override("normal", _flat(Color.WHITE, Color("#cbd5e1"), 16, true, 2))
	retry_btn.add_theme_color_override("font_color", C_TEXT)
	retry_btn.pressed.connect(_begin_quiz)
	_make_btn_bouncy(retry_btn)
	btn_row.add_child(retry_btn)

	var back_menu_btn := Button.new()
	back_menu_btn.text = "➔ Danh Mục"
	back_menu_btn.custom_minimum_size = Vector2(160, 48)
	back_menu_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	back_menu_btn.add_theme_font_size_override("font_size", 15)
	back_menu_btn.add_theme_stylebox_override("normal", _flat(C_JADE, C_GOLD, 16, true, 2))
	back_menu_btn.add_theme_color_override("font_color", Color.WHITE)
	back_menu_btn.pressed.connect(_go_back)
	_make_btn_bouncy(back_menu_btn)
	btn_row.add_child(back_menu_btn)

	game_vbox.add_child(vic_v)

func _play_synth(freq: float) -> void:
	if freq <= 0.0: return
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050.0
	var player := AudioStreamPlayer.new()
	player.stream = gen
	add_child(player)
	player.play()
	var pb = player.get_stream_playback()
	if pb:
		var frames := int(22050.0 * 0.4)
		for i in range(frames):
			var t := float(i) / 22050.0
			var env := exp(-t * 6.0)
			var s := sin(TAU * freq * t) * 0.35 * env
			pb.push_frame(Vector2(s, s))
	get_tree().create_timer(0.45).timeout.connect(func() -> void: player.queue_free())

func _flat(bg: Color, border: Color, radius: int, has_border: bool = true, border_w: int = 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	if has_border:
		s.border_width_left = border_w; s.border_width_right = border_w
		s.border_width_top = border_w; s.border_width_bottom = border_w
	s.corner_radius_top_left = radius; s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius; s.corner_radius_bottom_right = radius
	return s

func _make_btn_bouncy(btn: Button) -> void:
	btn.pivot_offset = btn.size / 2.0
	btn.resized.connect(func() -> void: btn.pivot_offset = btn.size / 2.0)
	btn.mouse_entered.connect(func() -> void:
		var t := create_tween()
		t.tween_property(btn, "scale", Vector2(1.03, 1.03), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func() -> void:
		var t := create_tween()
		t.tween_property(btn, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
