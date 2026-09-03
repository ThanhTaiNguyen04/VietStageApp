extends Control

# ── Colors (Jade & Gold Lacquer Cream Theme) ──────────────────────────────
const C_BG        := Color("#faf8f5")
const C_GREEN     := Color("#173f2d")  # C_JADE
const C_GREEN_MID := Color("#245f43")  # C_JADE_LIGHT
const C_GOLD      := Color("#c59626")  # C_GOLD
const C_GOLD_LT   := Color("#f0cb62")  # C_GOLD_LIGHT
const C_CREAM     := Color("#fffdf8")  # C_CARD
const C_TEXT      := Color("#21140d")  # C_TEXT
const C_TEXT_MUT  := Color("#6f6257")  # C_MUTED
const C_CARD      := Color("#fffdf8")  # C_CARD
const C_OK        := Color("#3e8e63")
const C_OK_BG     := Color("#e7f4ec")
const C_BAD       := Color("#c0392b")
const C_BAD_BG    := Color("#fbeae8")

# ── Context (set by caller screens before changing scene) ────────────────
static var quiz_instrument: String = ""
static var quiz_local_ids: Array[String] = []
static var quiz_return_scene: String = "res://scenes/MainMenu.tscn"

# ── Node refs ─────────────────────────────────────────────────────────────
@onready var back_btn   : Button = $Root/TopBar/TopM/TopH/BackBtn
@onready var top_title  : Label  = $Root/TopBar/TopM/TopH/Title
@onready var progress_lbl : Label = $Root/Card/CardM/GameVBox/HeaderRow/ProgressLbl
@onready var score_lbl    : Label = $Root/Card/CardM/GameVBox/HeaderRow/ScoreLbl
@onready var question_lbl : Label = $Root/Card/CardM/GameVBox/QuestionLbl
@onready var options_vbox : VBoxContainer = $Root/Card/CardM/GameVBox/OptionsVBox
@onready var feedback_pan : PanelContainer = $Root/Card/CardM/GameVBox/FeedbackPanel
@onready var feedback_lbl : Label = $Root/Card/CardM/GameVBox/FeedbackPanel/FeedbackM/FeedbackLbl
@onready var next_btn     : Button = $Root/Card/CardM/GameVBox/BottomRow/NextBtn

var font_bold    : Font = null
var font_regular : Font = null

var _quizzes: Array = []
var _index: int = 0
var _score: int = 0
var _correct_count: int = 0
var _api_stars_earned: int = 0
var _submitted_correct_answer: String = ""
var _answered: bool = false
var _busy: bool = false

func _ready() -> void:
	SecureDataManager.load_data()
	font_bold    = load("res://assets/fonts/BeVietnamPro-Bold.ttf")
	font_regular = load("res://assets/fonts/BeVietnamPro-Regular.ttf")

	_build_topbar()
	_build_theme()

	back_btn.pressed.connect(_go_back)
	next_btn.pressed.connect(_next)
	_make_btn_bouncy(back_btn)
	_make_btn_bouncy(next_btn)

	_begin_quiz()

	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.35)

func _draw() -> void:
	var sz := get_rect().size
	draw_rect(Rect2(Vector2.ZERO, sz), C_BG)

# ── Theme ──────────────────────────────────────────────────────────────────
func _build_topbar() -> void:
	var top_bar := $Root/TopBar as PanelContainer
	if not top_bar.has_node("BlurRect"):
		var blur_mat := ShaderMaterial.new()
		var blur_sh := Shader.new()
		blur_sh.code = """
		shader_type canvas_item;
		uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
		uniform float lod : hint_range(0.0, 5.0) = 2.0;
		void fragment() { COLOR = textureLod(screen_texture, SCREEN_UV, lod); }
		"""
		blur_mat.shader = blur_sh
		var blur := ColorRect.new()
		blur.name = "BlurRect"
		blur.material = blur_mat
		blur.mouse_filter = Control.MOUSE_FILTER_IGNORE
		blur.show_behind_parent = true
		blur.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		blur.offset_bottom = -1
		top_bar.add_child(blur)

	var top_s := _flat(Color(1.0, 0.99, 0.97, 0.7), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.28), 0)
	top_s.border_width_bottom = 1
	top_s.content_margin_bottom = 0
	top_bar.add_theme_stylebox_override("panel", top_s)

	top_title.text = "KIỂM TRA KIẾN THỨC"
	top_title.add_theme_color_override("font_color", C_GREEN)
	if font_bold:
		top_title.add_theme_font_override("font", font_bold)

	back_btn.add_theme_font_size_override("font_size", 20)
	back_btn.add_theme_stylebox_override("normal", _flat(Color(1.0, 1.0, 1.0, 0.85), C_GREEN, 16))
	back_btn.add_theme_stylebox_override("hover", _flat(Color(1.0, 1.0, 1.0, 1.0), C_GOLD, 16))
	back_btn.add_theme_stylebox_override("pressed", _flat(Color(0.95, 0.93, 0.89, 1.0), C_GOLD, 16))
	back_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	back_btn.add_theme_color_override("font_color", C_GREEN)
	back_btn.add_theme_color_override("font_hover_color", C_GREEN)

func _build_theme() -> void:
	var card_s := _flat(C_CARD, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35), 20)
	card_s.shadow_size = 16
	card_s.shadow_color = Color(0.13, 0.08, 0.05, 0.12)
	card_s.shadow_offset = Vector2(0, 4)
	$Root/Card.add_theme_stylebox_override("panel", card_s)

	for lbl in [progress_lbl, score_lbl]:
		lbl.add_theme_color_override("font_color", C_TEXT_MUT)
		if font_bold:
			lbl.add_theme_font_override("font", font_bold)

	question_lbl.add_theme_color_override("font_color", C_TEXT)
	if font_bold:
		question_lbl.add_theme_font_override("font", font_bold)

	next_btn.add_theme_stylebox_override("normal", _flat(C_GREEN, Color.TRANSPARENT, 16))
	next_btn.add_theme_stylebox_override("hover", _flat(C_GREEN_MID, C_GOLD, 16))
	next_btn.add_theme_stylebox_override("pressed", _flat(C_GREEN.darkened(0.12), Color.TRANSPARENT, 16))
	next_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	next_btn.add_theme_color_override("font_color", Color.WHITE)
	if font_bold:
		next_btn.add_theme_font_override("font", font_bold)

# ── Flow ───────────────────────────────────────────────────────────────────
func _begin_quiz() -> void:
	if quiz_instrument.is_empty() or quiz_local_ids.is_empty():
		_show_empty("Chưa chọn bài học để kiểm tra kiến thức.")
		return
	if not BackendReport.is_signed_in():
		_show_empty("Hãy đăng nhập để tham gia kiểm tra kiến thức.")
		return
	_quizzes = await BackendReport.fetch_quizzes_for_level(quiz_instrument, quiz_local_ids)
	if _quizzes.is_empty():
		_show_empty("Bài học này chưa có câu hỏi trắc nghiệm nào.")
		return
	_index = 0
	_score = 0
	_correct_count = 0
	_show_question()

func _show_question() -> void:
	_answered = false
	_submitted_correct_answer = ""
	question_lbl.visible = true
	options_vbox.visible = true
	feedback_pan.visible = false
	next_btn.visible = false

	var quiz: Dictionary = _quizzes[_index]
	progress_lbl.text = "CÂU %d / %d" % [_index + 1, _quizzes.size()]
	question_lbl.text = str(quiz.get("question", ""))

	for child in options_vbox.get_children():
		child.queue_free()
	var options := _parse_options(quiz.get("options", ""))
	for i in range(options.size()):
		var option_text := str(options[i])
		var btn := Button.new()
		btn.name = "OptBtn"
		btn.text = "%s. %s" % ["ABCDEFGHIJK"[i], option_text]
		btn.custom_minimum_size = Vector2(0, 56)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 18)
		btn.add_theme_stylebox_override("normal", _flat(Color(0.97, 0.95, 0.91, 1.0), Color(C_GREEN.r, C_GREEN.g, C_GREEN.b, 0.45), 14))
		btn.add_theme_stylebox_override("hover", _flat(Color(1.0, 1.0, 1.0, 1.0), C_GREEN, 14))
		btn.add_theme_stylebox_override("pressed", _flat(Color(0.93, 0.91, 0.87, 1.0), C_GREEN, 14))
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		btn.add_theme_color_override("font_color", C_TEXT)
		btn.add_theme_color_override("font_hover_color", C_GREEN)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_option.bind(btn, i, option_text))
		_make_btn_bouncy(btn)
		options_vbox.add_child(btn)
		btn.modulate.a = 0.0
		create_tween().tween_property(btn, "modulate:a", 1.0, 0.25).set_delay(i * 0.04)

func _on_option(_btn: Button, idx: int, selected: String) -> void:
	if _answered or _busy:
		return
	_answered = true
	var quiz: Dictionary = _quizzes[_index]

	for child in options_vbox.get_children():
		if child is Button:
			(child as Button).disabled = true

	var selected_index := idx

	_busy = true
	var result: Dictionary = await BackendReport.report_quiz(int(quiz.get("id", 0)), selected)
	_busy = false

	var is_correct := false
	var earned := int(result.get("points_earned", 0))
	if result.get("submitted", false):
		is_correct = bool(result.get("is_correct", false))
		_submitted_correct_answer = str(result.get("correct_answer", ""))
		_api_stars_earned += maxi(0, int(result.get("stars_earned", 0)))
		_score += earned

	if is_correct:
		_correct_count += 1

	_style_option_feedback(selected_index, is_correct)
	_show_feedback(is_correct, quiz)

	score_lbl.text = "ĐIỂM: %d" % _score
	score_lbl.modulate = Color(1, 0.8, 0.3, 1)
	score_lbl.scale = Vector2(1.15, 1.15)
	var tw := create_tween()
	tw.tween_property(score_lbl, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(score_lbl, "modulate", Color.WHITE, 0.3)

	next_btn.text = "Xem Kết Quả" if _index + 1 >= _quizzes.size() else "Câu Tiếp Theo →"
	next_btn.visible = true
	next_btn.modulate.a = 0.0
	create_tween().tween_property(next_btn, "modulate:a", 1.0, 0.25)

func _next() -> void:
	if _answered:
		_index += 1
	if _index >= _quizzes.size():
		_show_summary()
	else:
		_show_question()

func _show_summary() -> void:
	if BackendReport.is_signed_in():
		await BackendReport.refresh_progress_from_backend()
	_answered = true
	question_lbl.visible = false
	options_vbox.visible = false
	feedback_pan.visible = false
	next_btn.visible = false

	var total := _quizzes.size()
	var all_correct := _correct_count == total
	progress_lbl.text = "HOÀN THÀNH"

	var emoji := "🏆" if all_correct else ("👍" if _correct_count >= ceil(total / 2.0) else "💪")
	question_lbl.text = "%s\n\nBạn trả lời đúng %d / %d câu." % [emoji, _correct_count, total]
	question_lbl.visible = true
	question_lbl.add_theme_font_size_override("font_size", 28)

	var sub := Label.new()
	sub.text = "Phần thưởng từ hệ thống: +%d điểm · +%d sao" % [_score, _api_stars_earned]
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", C_TEXT_MUT)
	options_vbox.add_child(sub)
	options_vbox.visible = true

	var done_btn := Button.new()
	done_btn.text = "Quay Lại"
	done_btn.custom_minimum_size = Vector2(240, 56)
	done_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	done_btn.add_theme_font_size_override("font_size", 20)
	done_btn.add_theme_stylebox_override("normal", _flat(C_GREEN, Color.TRANSPARENT, 16))
	done_btn.add_theme_stylebox_override("hover", _flat(C_GREEN_MID, C_GOLD, 16))
	done_btn.add_theme_stylebox_override("pressed", _flat(C_GREEN.darkened(0.12), Color.TRANSPARENT, 16))
	done_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	done_btn.add_theme_color_override("font_color", Color.WHITE)
	done_btn.pressed.connect(_go_back)
	_make_btn_bouncy(done_btn)
	options_vbox.add_child(done_btn)

	if all_correct:
		question_lbl.modulate = Color(1, 1, 1, 0)
		var tw := create_tween()
		tw.tween_property(question_lbl, "modulate", Color.WHITE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(question_lbl, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _show_empty(message: String) -> void:
	question_lbl.text = "📖\n\n" + message
	question_lbl.visible = true
	options_vbox.visible = false
	feedback_pan.visible = false
	next_btn.visible = false
	progress_lbl.text = ""

	var back := Button.new()
	back.text = "Quay Lại"
	back.custom_minimum_size = Vector2(240, 56)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.add_theme_font_size_override("font_size", 20)
	back.add_theme_stylebox_override("normal", _flat(C_GREEN, Color.TRANSPARENT, 16))
	back.add_theme_stylebox_override("hover", _flat(C_GREEN_MID, C_GOLD, 16))
	back.add_theme_stylebox_override("pressed", _flat(C_GREEN.darkened(0.12), Color.TRANSPARENT, 16))
	back.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	back.add_theme_color_override("font_color", Color.WHITE)
	back.pressed.connect(_go_back)
	_make_btn_bouncy(back)
	options_vbox.add_child(back)
	options_vbox.visible = true

func _style_option_feedback(selected_index: int, is_correct: bool) -> void:
	var i := 0
	for child in options_vbox.get_children():
		var btn := child as Button
		if btn == null:
			continue
		if _option_is_correct_index(i):
			btn.add_theme_stylebox_override("normal", _flat(C_OK, Color.TRANSPARENT, 14))
			btn.add_theme_color_override("font_color", Color.WHITE)
		elif i == selected_index and not is_correct:
			btn.add_theme_stylebox_override("normal", _flat(C_BAD, Color.TRANSPARENT, 14))
			btn.add_theme_color_override("font_color", Color.WHITE)
		i += 1

func _option_is_correct_index(i: int) -> bool:
	if _submitted_correct_answer.is_empty():
		return false
	var quiz: Dictionary = _quizzes[_index]
	var options := _parse_options(quiz.get("options", ""))
	if i < options.size():
		return _normalize_option(str(options[i])) == _normalize_option(_submitted_correct_answer)
	return false

func _show_feedback(is_correct: bool, quiz: Dictionary) -> void:
	feedback_pan.visible = true
	if is_correct:
		feedback_pan.add_theme_stylebox_override("panel", _flat(C_OK_BG, C_OK, 16))
		feedback_lbl.text = "Đúng rồi, xuất sắc! 🎉"
		feedback_lbl.add_theme_color_override("font_color", C_OK)
	else:
		feedback_pan.add_theme_stylebox_override("panel", _flat(C_BAD_BG, C_BAD, 16))
		feedback_lbl.text = "Chưa đúng. Đáp án đúng: %s" % str(quiz.get("correctAnswer", ""))
		feedback_lbl.add_theme_color_override("font_color", C_BAD)
	feedback_pan.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(feedback_pan, "modulate:a", 1.0, 0.25)

# ── Helpers ────────────────────────────────────────────────────────────────
## Đối chiếu đáp án đã chọn với correctAnswer của BE. Chấp nhận cả dạng
## chữ cái ("A"), dạng có tiền tố ("A. ...") và dạng chuẩn hóa ("...").
func _is_correct(idx: int, selected: String, quiz: Dictionary) -> bool:
	var correct := str(quiz.get("correctAnswer", "")).strip_edges().to_lower()
	var sel := _normalize_option(selected)
	if sel == _normalize_option(correct):
		return true
	if correct.length() == 1 and "a" <= correct and correct <= "j":
		return correct == "abcdefghij"[idx]
	return false

func _normalize_option(s: String) -> String:
	var t := s.strip_edges().to_lower()
	if t.length() >= 2 and t[0] in ["a", "b", "c", "d", "e"] and t[1] in [".", ":", "-", " ", ")", "）"]:
		t = t.substr(1).strip_edges()
		if t.begins_with(".") or t.begins_with(":") or t.begins_with("-") or t.begins_with(")") or t.begins_with("）"):
			t = t.substr(1).strip_edges()
	return t

func _parse_options(raw: String) -> Array:
	var text := str(raw).strip_edges()
	if text.is_empty():
		return []
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Array:
		var options: Array = []
		for item: Variant in parsed:
			options.append(str(item).strip_edges())
		return options
	var sep := "\n"
	if not text.contains(sep):
		sep = ";"
	if not text.contains(sep):
		sep = "|"
	var options: Array = []
	for item: Variant in text.split(sep):
		options.append(str(item).strip_edges())
	return options

func _go_back() -> void:
	var target := quiz_return_scene
	if target.is_empty():
		target = "res://scenes/MainMenu.tscn"
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func() -> void: get_tree().change_scene_to_file(target))

func _make_btn_bouncy(btn: Button) -> void:
	btn.pivot_offset = btn.size / 2.0
	btn.resized.connect(func() -> void: btn.pivot_offset = btn.size / 2.0)
	btn.mouse_entered.connect(func() -> void:
		if not btn.disabled:
			create_tween().tween_property(btn, "scale", Vector2(1.04, 1.04), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func() -> void:
		if not btn.disabled:
			create_tween().tween_property(btn, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	btn.button_down.connect(func() -> void:
		if not btn.disabled:
			create_tween().tween_property(btn, "scale", Vector2(0.95, 0.95), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	btn.button_up.connect(func() -> void:
		if not btn.disabled:
			var target := Vector2(1.04, 1.04) if btn.is_hovered() else Vector2.ONE
			create_tween().tween_property(btn, "scale", target, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)

func _flat(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left = 2
	s.border_width_right = 2
	s.border_width_top = 2
	s.border_width_bottom = 2
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	return s
