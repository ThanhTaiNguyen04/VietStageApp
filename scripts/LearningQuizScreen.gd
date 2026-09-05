extends "res://scripts/LearningActivityBase.gd"

const DanTranhAudio = preload("res://scripts/DanTranhAudio.gd")
const QUIZ_PREVIEW_POINTS := 10
const QUIZ_FETCH_GRACE_SECONDS := 8.0

signal _backend_fetch_gate

var quizzes: Array = []
var question_index := 0
var score := 0
var correct_count := 0
var api_stars_earned := 0
var submitted_attempt_count := 0
var unsynced_attempt_count := 0
var local_preview_count := 0
var answered := false
var question_card: PanelContainer # Reserved for compatibility, though we don't use it directly now
var options_box: GridContainer
var feedback_label: Label # Reserved for compatibility
var progress_bar: ProgressBar
var data_source_badge: Label
var retry_button: Button
var audio_button: Button
var audio_player: AudioStreamPlayer
var _audio_stream_cache: Dictionary = {}
var _retry_in_progress := false
var _backend_fetch_finished := false
var _backend_fetch_timed_out := false
var _backend_quizzes: Array = []
var _using_sample_quizzes := false

# New persistent UI components
var bottom_feedback_panel: PanelContainer
var feedback_hbox: HBoxContainer
var feedback_text_vbox: VBoxContainer
var feedback_icon_container: CenterContainer
var feedback_icon: TextureRect
var feedback_title_label: Label
var feedback_desc_label: Label
var next_button: Button
var floating_back_button: Button
var score_label: Label

func _find_scroll_container(parent: Node) -> ScrollContainer:
	for child in parent.get_children():
		if child is ScrollContainer:
			return child
		var res := _find_scroll_container(child)
		if res:
			return res
	return null

func _ready() -> void:
	SecureDataManager.load_data()
	super._ready()
	_add_quiz_scrim()
	title_label.text = "QUIZ - NHẬN DIỆN NỐT NHẠC"

	# Hide the inherited top panel navbar
	var top_panel = root_box.get_child(0)
	if top_panel:
		top_panel.visible = false

	# Optimize scroll container padding
	var scroll = _find_scroll_container(root_box)
	if scroll and scroll.get_child_count() > 0:
		var scroll_margin = scroll.get_child(0) as MarginContainer
		if scroll_margin:
			scroll_margin.add_theme_constant_override("margin_top", 4)
			scroll_margin.add_theme_constant_override("margin_bottom", 8)
			scroll_margin.add_theme_constant_override("margin_left", 16)
			scroll_margin.add_theme_constant_override("margin_right", 16)

	# Build persistent elements
	_build_sticky_progress_bar()
	_build_bottom_feedback_panel()

	# Hide initially during loading
	if progress_bar:
		progress_bar.get_parent().visible = false
	if bottom_feedback_panel:
		bottom_feedback_panel.visible = false
	if floating_back_button:
		floating_back_button.visible = false

	_show_loading()
	_begin_quiz()

func _build_sticky_progress_bar() -> void:
	var mobile := get_viewport_rect().size.x < 600.0

	var progress_container := MarginContainer.new()
	progress_container.name = "QuizProgressContainer"
	progress_container.add_theme_constant_override("margin_left", 16 if mobile else 28)
	progress_container.add_theme_constant_override("margin_right", 16 if mobile else 28)
	progress_container.add_theme_constant_override("margin_top", 12 if mobile else 16)
	progress_container.add_theme_constant_override("margin_bottom", 6)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 18)
	progress_container.add_child(hbox)

	# 1. Large Sticky Back Button (84x84 circular 3D button)
	floating_back_button = Button.new()
	floating_back_button.custom_minimum_size = Vector2(84, 84)
	floating_back_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	floating_back_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(floating_back_button)

	floating_back_button.icon = load("res://assets/textures/lucide/arrow-left.svg") as Texture2D
	floating_back_button.expand_icon = true
	floating_back_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	floating_back_button.add_theme_constant_override("icon_max_width", 42)

	var style_n := StyleBoxFlat.new()
	style_n.bg_color = Color.WHITE
	style_n.set_corner_radius_all(42)
	style_n.border_width_bottom = 5
	style_n.border_color = Color("#cbd5e1")
	style_n.shadow_color = Color(0, 0, 0, 0.06)
	style_n.shadow_size = 6
	style_n.shadow_offset = Vector2(0, 3)

	var style_h := style_n.duplicate() as StyleBoxFlat
	style_h.bg_color = Color("#FDFCF9")
	style_h.border_color = Color("#94a3b8")

	var style_p := style_n.duplicate() as StyleBoxFlat
	style_p.bg_color = Color("#F5F0E5")
	style_p.border_width_bottom = 1
	style_p.border_width_top = 4

	floating_back_button.add_theme_stylebox_override("normal", style_n)
	floating_back_button.add_theme_stylebox_override("hover", style_h)
	floating_back_button.add_theme_stylebox_override("pressed", style_p)
	floating_back_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	floating_back_button.add_theme_color_override("icon_normal_color", C_NAVY)

	floating_back_button.pressed.connect(_go_back)

	floating_back_button.pivot_offset = Vector2(42, 42)
	floating_back_button.mouse_entered.connect(func() -> void:
		create_tween().tween_property(floating_back_button, "scale", Vector2(1.06, 1.06), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	floating_back_button.mouse_exited.connect(func() -> void:
		create_tween().tween_property(floating_back_button, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)

	# 2. Progress Bar (Thick Duolingo style)
	progress_bar = ProgressBar.new()
	progress_bar.max_value = 100.0
	progress_bar.value = 0.0
	progress_bar.show_percentage = false
	progress_bar.custom_minimum_size = Vector2(0, 20 if mobile else 24)
	progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var bar_radius := 10 if mobile else 12
	progress_bar.add_theme_stylebox_override("background", _panel(Color("#e9edf5"), Color("#e9edf5"), bar_radius, 0))
	progress_bar.add_theme_stylebox_override("fill", _panel(C_BLUE, C_BLUE, bar_radius, 0))
	hbox.add_child(progress_bar)

	# 3. Large Score Pill Capsule (3x larger, gamified Duolingo style)
	var s_pill := PanelContainer.new()
	s_pill.name = "ScorePill"
	var s_style := StyleBoxFlat.new()
	s_style.bg_color = Color("#edf3ec") # jade bg
	s_style.border_color = Color("#2e7d32")
	s_style.set_border_width_all(2)
	s_style.border_width_bottom = 5
	s_style.set_corner_radius_all(24)
	s_style.content_margin_left = 20
	s_style.content_margin_right = 24
	s_style.content_margin_top = 10
	s_style.content_margin_bottom = 10
	s_style.shadow_color = Color(0, 0, 0, 0.05)
	s_style.shadow_size = 4
	s_style.shadow_offset = Vector2(0, 2)
	s_pill.add_theme_stylebox_override("panel", s_style)
	s_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(s_pill)

	var s_hbox := HBoxContainer.new()
	s_hbox.add_theme_constant_override("separation", 10)
	s_pill.add_child(s_hbox)

	var s_icon := TextureRect.new()
	s_icon.texture = load("res://assets/textures/lucide/trophy.svg") as Texture2D
	s_icon.custom_minimum_size = Vector2(32, 32)
	s_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	s_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	s_icon.modulate = Color("#e7ae22") # Gold trophy icon
	s_hbox.add_child(s_icon)

	score_label = Label.new()
	score_label.text = str(score)
	score_label.add_theme_font_override("font", load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font)
	score_label.add_theme_font_size_override("font_size", 24)
	score_label.add_theme_color_override("font_color", Color("#1b5e20"))
	s_hbox.add_child(score_label)

	# Insert in root_box as the second child, below the top panel
	root_box.add_child(progress_container)
	root_box.move_child(progress_container, 1)

func _build_bottom_feedback_panel() -> void:
	pass

func _set_bottom_feedback_waiting() -> void:
	pass

func _set_bottom_feedback_answered(is_correct: bool, feedback_desc: String) -> void:
	pass

func _create_option_button(index: int, text_value: String) -> Button:
	var v_height := get_viewport_rect().size.y
	var btn_height := 72.0
	var font_size_option := 18
	var badge_size := Vector2(42, 42)
	var badge_font_size := 16
	var badge_radius := 21

	if v_height < 500.0:
		btn_height = 64.0
		font_size_option = 17
		badge_size = Vector2(38, 38)
		badge_font_size = 15
		badge_radius = 19
	elif v_height >= 700.0:
		btn_height = 80.0
		font_size_option = 20
		badge_size = Vector2(48, 48)
		badge_font_size = 18
		badge_radius = 24

	var button := Button.new()
	button.custom_minimum_size = Vector2(0, btn_height)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	# Normal state (3D border bottom 5px)
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color.WHITE
	normal_style.border_color = Color("#cbd5e1") # slate-300
	normal_style.set_border_width_all(2)
	normal_style.border_width_bottom = 5
	normal_style.set_corner_radius_all(18)
	button.add_theme_stylebox_override("normal", normal_style)

	# Hover state
	var hover_style := normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color("#f8fafc") # slate-50
	hover_style.border_color = Color("#94a3b8") # slate-400
	button.add_theme_stylebox_override("hover", hover_style)

	# Pressed state
	var pressed_style := normal_style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color("#f1f5f9") # slate-100
	pressed_style.border_color = Color("#64748b") # slate-500
	pressed_style.border_width_top = 4
	pressed_style.border_width_bottom = 2
	button.add_theme_stylebox_override("pressed", pressed_style)

	var disabled_style := normal_style.duplicate() as StyleBoxFlat
	button.add_theme_stylebox_override("disabled", disabled_style)

	# Internal layout container
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(hbox)

	# Circle badge container for letter (A, B, C, D)
	var badge_panel := PanelContainer.new()
	badge_panel.name = "Badge"
	badge_panel.custom_minimum_size = badge_size
	badge_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color("#f1f5f9")
	badge_style.border_color = Color("#cbd5e1")
	badge_style.set_border_width_all(1)
	badge_style.set_corner_radius_all(badge_radius) # circular
	badge_panel.add_theme_stylebox_override("panel", badge_style)

	var badge_label := Label.new()
	badge_label.text = char(65 + index)
	badge_label.add_theme_font_override("font", load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font)
	badge_label.add_theme_font_size_override("font_size", badge_font_size)
	badge_label.add_theme_color_override("font_color", C_NAVY)
	badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge_panel.add_child(badge_label)
	hbox.add_child(badge_panel)

	# Answer text label
	var text_label := Label.new()
	text_label.name = "TextLabel"
	text_label.text = text_value
	text_label.add_theme_font_override("font", load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font)
	text_label.add_theme_font_size_override("font_size", font_size_option)
	text_label.add_theme_color_override("font_color", C_NAVY)
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hbox.add_child(text_label)

	# Hover bouncy micro-interaction
	button.pivot_offset = Vector2(100, 32)
	button.mouse_entered.connect(func() -> void:
		if not button.disabled:
			create_tween().tween_property(button, "scale", Vector2(1.02, 1.02), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	)
	button.mouse_exited.connect(func() -> void:
		if not button.disabled:
			create_tween().tween_property(button, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	)

	return button

func _style_option_button_state(button: Button, state: String) -> void:
	var style := button.get_theme_stylebox("disabled") as StyleBoxFlat
	if style == null:
		style = StyleBoxFlat.new()
		style.set_corner_radius_all(14)
		style.set_border_width_all(1)
		style.border_width_bottom = 4
	else:
		style = style.duplicate() as StyleBoxFlat

	var badge_panel := button.find_child("Badge", true, false) as PanelContainer
	var text_label := button.find_child("TextLabel", true, false) as Label

	if state == "correct":
		style.bg_color = Color("#e8f5e9")
		style.border_color = Color("#4caf50")
		button.add_theme_stylebox_override("disabled", style)
		button.add_theme_color_override("font_disabled_color", Color("#2e7d32"))

		if badge_panel:
			var badge_style := badge_panel.get_theme_stylebox("panel") as StyleBoxFlat
			if badge_style:
				badge_style = badge_style.duplicate() as StyleBoxFlat
				badge_style.bg_color = Color("#4caf50")
				badge_style.border_color = Color("#2e7d32")
				badge_panel.add_theme_stylebox_override("panel", badge_style)
			var badge_label := badge_panel.get_child(0) as Label
			if badge_label:
				badge_label.add_theme_color_override("font_color", Color.WHITE)

		if text_label:
			text_label.add_theme_color_override("font_color", Color("#2e7d32"))

	elif state == "incorrect":
		style.bg_color = Color("#ffebee")
		style.border_color = Color("#f44336")
		button.add_theme_stylebox_override("disabled", style)
		button.add_theme_color_override("font_disabled_color", Color("#c62828"))

		if badge_panel:
			var badge_style := badge_panel.get_theme_stylebox("panel") as StyleBoxFlat
			if badge_style:
				badge_style = badge_style.duplicate() as StyleBoxFlat
				badge_style.bg_color = Color("#f44336")
				badge_style.border_color = Color("#c62828")
				badge_panel.add_theme_stylebox_override("panel", badge_style)
			var badge_label := badge_panel.get_child(0) as Label
			if badge_label:
				badge_label.add_theme_color_override("font_color", Color.WHITE)

		if text_label:
			text_label.add_theme_color_override("font_color", Color("#c62828"))

func _show_loading() -> void:
	var loading := _label("Đang tải câu hỏi từ bài học...", 17, C_MUTED)
	loading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_box.add_child(loading)

func _begin_quiz() -> void:
	var report := _report()
	if report != null and report.is_signed_in():
		_backend_fetch_finished = false
		_backend_fetch_timed_out = false
		_backend_quizzes = []
		var fetch_timer := get_tree().create_timer(QUIZ_FETCH_GRACE_SECONDS)
		fetch_timer.timeout.connect(func() -> void:
			if not _backend_fetch_finished:
				_backend_fetch_timed_out = true
			_backend_fetch_gate.emit()
		)
		call_deferred("_fetch_backend_quizzes", report)
		await _backend_fetch_gate
		if _backend_fetch_finished:
			if _backend_quizzes.is_empty():
				_load_sample_quizzes(true)
				_set_source_badge("Dữ liệu mẫu · BE chưa có quiz", true)
			else:
				_install_backend_quizzes(_backend_quizzes)
		else:
			_backend_fetch_timed_out = true
			_load_sample_quizzes(true)
			_set_source_badge("Dữ liệu mẫu · BE chậm", true)
	else:
		_load_sample_quizzes(false)

func _load_sample_quizzes(fetching_be: bool) -> void:
	result_sync_status = "offline"
	var samples: Dictionary = _sample_data()
	quizzes = _filter_valid_quizzes(samples.get("quiz", []))
	_sort_quizzes()
	question_index = 0
	score = 0
	correct_count = 0
	api_stars_earned = 0
	submitted_attempt_count = 0
	unsynced_attempt_count = 0
	local_preview_count = 0
	_using_sample_quizzes = true
	if quizzes.is_empty():
		_show_message("Bài học này chưa có câu hỏi trắc nghiệm.")
		return
	_show_quiz_ui()
	_set_source_badge("Dữ liệu mẫu" if not fetching_be else "Dữ liệu mẫu · đang tải BE", false)
	_show_question()

func _show_quiz_ui() -> void:
	if progress_bar:
		progress_bar.get_parent().visible = true
	if bottom_feedback_panel:
		bottom_feedback_panel.visible = true
	if floating_back_button:
		floating_back_button.visible = true

func _fetch_backend_quizzes(report: Node) -> void:
	var loaded: Array = await report.fetch_quizzes_for_level(Context.instrument, Context.local_lesson_ids)
	_backend_quizzes = _filter_valid_quizzes(loaded)
	_backend_fetch_finished = true
	_backend_fetch_gate.emit()
	if _backend_fetch_timed_out:
		_set_source_badge("Dữ liệu mẫu · BE chậm", true)

func _install_backend_quizzes(valid: Array) -> void:
	quizzes = valid.duplicate(true)
	_sort_quizzes()
	result_sync_status = "be"
	_using_sample_quizzes = false
	question_index = 0
	score = 0
	correct_count = 0
	api_stars_earned = 0
	submitted_attempt_count = 0
	unsynced_attempt_count = 0
	local_preview_count = 0
	_show_quiz_ui()
	_set_source_badge("Dữ liệu BE", false)
	_show_question()

func _fetch_from_backend() -> void:
	var report := _report()
	if report == null or not report.is_signed_in():
		return
	var loaded: Array = await report.fetch_quizzes_for_level(Context.instrument, Context.local_lesson_ids)
	var valid: Array = _filter_valid_quizzes(loaded)
	if valid.is_empty():
		_set_source_badge("Dữ liệu mẫu · BE chưa có quiz", true)
		return
	if not _using_sample_quizzes or question_index > 0 or answered or score > 0 or correct_count > 0:
		_set_source_badge("Dữ liệu BE đã tải", false)
		return
	_install_backend_quizzes(valid)

func _retry_fetch() -> void:
	if _retry_in_progress:
		return
	_retry_in_progress = true
	if retry_button:
		retry_button.disabled = true
	_set_source_badge("Đang tải BE...", false)
	await _fetch_from_backend()
	_retry_in_progress = false
	if retry_button:
		retry_button.disabled = false

func _set_source_badge(text_value: String, show_retry: bool) -> void:
	if data_source_badge and is_instance_valid(data_source_badge):
		data_source_badge.text = text_value
	if retry_button and is_instance_valid(retry_button):
		retry_button.visible = show_retry and not _retry_in_progress

func _sort_quizzes() -> void:
	quizzes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("orderIndex", 0)) < int(b.get("orderIndex", 0)))

func _show_message(message: String) -> void:
	if progress_bar:
		progress_bar.get_parent().visible = false
	if bottom_feedback_panel:
		bottom_feedback_panel.visible = false
	if floating_back_button:
		floating_back_button.visible = false

	for child in content_box.get_children():
		child.queue_free()
	var message_label := _label(message, 22, C_MUTED)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_box.add_child(message_label)
	var back := _button("Quay lại", 180, 50, C_NAVY)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_go_back)
	content_box.add_child(back)

func _show_question() -> void:
	for child in content_box.get_children():
		child.queue_free()

	answered = false
	audio_button = null

	var quiz: Dictionary = quizzes[question_index]
	var viewport_size := get_viewport_rect().size
	var mobile := viewport_size.x < 600.0
	var v_height := viewport_size.y

	var staff_height := 240.0
	var staff_spacing := 40.0
	var font_size_prompt := 24

	if v_height < 500.0: # Mobile Landscape
		staff_height = 190.0
		staff_spacing = 34.0
		font_size_prompt = 22
	elif v_height < 700.0: # Portrait Mobile
		staff_height = 200.0
		staff_spacing = 36.0
		font_size_prompt = 24
	else: # Desktop / Tablet
		staff_height = 240.0
		staff_spacing = 40.0
		font_size_prompt = 26

	_set_bottom_feedback_waiting()

	# Smoothly tween progress bar value
	var target_value := float(question_index + 1) / float(quizzes.size()) * 100.0
	var progress_tween := create_tween()
	progress_tween.tween_property(progress_bar, "value", target_value, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Update score label in top bar
	if score_label and is_instance_valid(score_label):
		score_label.text = str(score)

	# 1. Question Prompt Card (dedicated highlight card synchronized with staff & options)
	var question_card := PanelContainer.new()
	question_card.name = "QuestionPromptCard"
	question_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var q_style := StyleBoxFlat.new()
	q_style.bg_color = Color.WHITE
	q_style.border_color = Color("#cbd5e1")
	q_style.set_border_width_all(2)
	q_style.border_width_bottom = 5
	q_style.set_corner_radius_all(18)
	q_style.shadow_color = Color(0, 0, 0, 0.05)
	q_style.shadow_size = 6
	q_style.shadow_offset = Vector2(0, 3)
	q_style.content_margin_left = 20
	q_style.content_margin_right = 20
	q_style.content_margin_top = 12
	q_style.content_margin_bottom = 12
	question_card.add_theme_stylebox_override("panel", q_style)
	content_box.add_child(question_card)

	var prompt := Label.new()
	prompt.text = str(quiz.get("question", "Nhận diện nốt nhạc"))
	prompt.add_theme_font_override("font", load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font)
	prompt.add_theme_font_size_override("font_size", font_size_prompt)
	prompt.add_theme_color_override("font_color", C_NAVY)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt.add_theme_constant_override("line_spacing", 4)
	question_card.add_child(prompt)

	# 2. Staff Display (whiteboard card)
	var show_staff := _is_note_question(quiz)
	if show_staff:
		var staff_card := PanelContainer.new()
		staff_card.name = "QuizStaffCard"
		staff_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		staff_card.add_theme_stylebox_override("panel", _practice_staff_style())
		content_box.add_child(staff_card)

		var whiteboard_vbox := VBoxContainer.new()
		whiteboard_vbox.add_theme_constant_override("separation", 4)
		staff_card.add_child(whiteboard_vbox)

		# Top header row inside the staff card with audio button
		var card_header := HBoxContainer.new()
		card_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		whiteboard_vbox.add_child(card_header)

		var card_header_spacer := Control.new()
		card_header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_header.add_child(card_header_spacer)

		# Large audio button in top-right of staff card
		audio_button = Button.new()
		audio_button.custom_minimum_size = Vector2(48, 48)
		audio_button.icon = load("res://assets/textures/lucide/volume-2.svg") as Texture2D
		audio_button.expand_icon = true
		audio_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		audio_button.add_theme_constant_override("icon_max_width", 24)
		audio_button.size_flags_horizontal = Control.SIZE_SHRINK_END
		audio_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		var btn_style_n := StyleBoxFlat.new()
		btn_style_n.bg_color = Color.WHITE
		btn_style_n.border_color = Color("#cbd5e1")
		btn_style_n.set_border_width_all(2)
		btn_style_n.border_width_bottom = 4
		btn_style_n.set_corner_radius_all(24)

		var btn_style_h := btn_style_n.duplicate() as StyleBoxFlat
		btn_style_h.bg_color = Color("#f8fafc")
		btn_style_h.border_color = Color("#94a3b8")

		var btn_style_p := btn_style_n.duplicate() as StyleBoxFlat
		btn_style_p.bg_color = Color("#f1f5f9")
		btn_style_p.border_color = Color("#64748b")
		btn_style_p.border_width_top = 3
		btn_style_p.border_width_bottom = 1

		audio_button.add_theme_stylebox_override("normal", btn_style_n)
		audio_button.add_theme_stylebox_override("hover", btn_style_h)
		audio_button.add_theme_stylebox_override("pressed", btn_style_p)
		audio_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		audio_button.add_theme_color_override("icon_normal_color", C_NAVY)

		audio_button.pivot_offset = Vector2(24, 24)
		audio_button.mouse_entered.connect(func() -> void:
			create_tween().tween_property(audio_button, "scale", Vector2(1.08, 1.08), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		)
		audio_button.mouse_exited.connect(func() -> void:
			create_tween().tween_property(audio_button, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		)

		audio_button.pressed.connect(func() -> void: _play_quiz_audio(quiz))
		card_header.add_child(audio_button)

		# Staff display inside card
		var staff: Control = load("res://scripts/StaffDisplay.gd").new()
		staff.line_spacing = staff_spacing
		staff.show_time_sig = true
		staff.beats_per_measure = 4
		staff.time_sig_denominator = 4
		staff.show_metronome = false
		staff.show_hit_line = false
		staff.show_clef = true
		staff.custom_minimum_size = Vector2(0, staff_height)
		staff.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		staff.set_notes([{"note": _quiz_note(quiz), "color": Color.BLACK, "type": "quarter"}])
		whiteboard_vbox.add_child(staff)

	# 3. Options Grid (2 columns on landscape/desktop, 1 column on narrow portrait)
	options_box = GridContainer.new()
	options_box.columns = 1 if mobile else 2
	options_box.add_theme_constant_override("h_separation", 16)
	options_box.add_theme_constant_override("v_separation", 12)
	options_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_box.add_child(options_box)

	var options: Array = _parse_options(quiz.get("options", ""))
	for i in range(options.size()):
		var option_text := str(options[i])
		var button := _create_option_button(i, option_text)
		button.pressed.connect(func() -> void: _answer(button, i, option_text))
		options_box.add_child(button)

	# 4. Next Button (inline, below options)
	next_button = _button("Xem kết quả" if question_index + 1 >= quizzes.size() else "Tiếp theo →", 200, 50, C_NAVY)
	next_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	next_button.visible = false
	next_button.pressed.connect(_next_question)
	content_box.add_child(next_button)

func _add_quiz_scrim() -> void:
	var scrim := ColorRect.new()
	scrim.name = "QuizBackgroundScrim"
	scrim.color = Color(0.04, 0.07, 0.06, 0.20)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scrim)
	move_child(scrim, root_box.get_index())

func _practice_staff_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fdfbf7")
	style.border_color = Color("#dfb15b")
	style.set_border_width_all(2)
	style.border_width_bottom = 5
	style.set_corner_radius_all(20)
	style.shadow_color = Color(0.20, 0.15, 0.08, 0.10)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 4)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 12
	return style

func _visual_hint(quiz: Dictionary) -> String:
	var content := str(quiz.get("question", ""))
	if content.to_lower().contains("khuông") or content.to_lower().contains("khuong"):
		return "────  ♩  ────"
	return "♫"

func _is_note_question(quiz: Dictionary) -> bool:
	var question_type := str(quiz.get("questionType", "NOTE_IDENTIFICATION")).to_upper().strip_edges()
	if question_type == "GENERAL":
		return false
	if question_type == "NOTE_IDENTIFICATION":
		return true
	return not str(quiz.get("note", "")).strip_edges().is_empty()

func _quiz_note(quiz: Dictionary) -> String:
	var options: Array = _parse_options(quiz.get("options", []))
	return Context.resolve_staff_note(quiz, options)

func _play_quiz_audio(quiz: Dictionary) -> void:
	if audio_player and is_instance_valid(audio_player):
		audio_player.queue_free()
	var audio_url := str(quiz.get("audioUrl", "")).strip_edges()
	if not audio_url.is_empty():
		_play_reference_audio(audio_url)
		return
	var frequency := _frequency_for_note(_quiz_note(quiz))
	if Context.instrument == "dan_tranh":
		var zither_stream: AudioStreamWAV = DanTranhAudio.load_recorded_sample(_quiz_note(quiz))
		if zither_stream == null:
			zither_stream = DanTranhAudio.generate_pluck_stream(frequency)
		audio_player = AudioStreamPlayer.new()
		audio_player.stream = zither_stream
		add_child(audio_player)
		audio_player.play()
		get_tree().create_timer(DanTranhAudio.DURATION + 0.1).timeout.connect(func() -> void:
			if is_instance_valid(audio_player):
				audio_player.queue_free()
		)
		return
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 44100
	stream.buffer_length = 0.65
	audio_player = AudioStreamPlayer.new()
	audio_player.stream = stream
	add_child(audio_player)
	audio_player.play()
	var playback := audio_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	var frames := PackedVector2Array()
	for i in range(22000):
		var t := float(i) / 44100.0
		var sample := sin(TAU * frequency * t) * exp(-t * 3.2) * 0.20
		frames.append(Vector2(sample, sample))
	playback.push_buffer(frames)
	get_tree().create_timer(0.7).timeout.connect(func() -> void:
		if is_instance_valid(audio_player):
			audio_player.queue_free()
	)

func _play_reference_audio(url: String) -> void:
	if _audio_stream_cache.has(url):
		_play_stream(_audio_stream_cache[url] as AudioStream)
		return
	var request := HTTPRequest.new()
	add_child(request)
	var error := request.request(url)
	if error != OK:
		request.queue_free()
		return
	var response: Array = await request.request_completed
	request.queue_free()
	if response.size() < 4 or int(response[1]) < 200 or int(response[1]) >= 300:
		return
	var stream := AudioStreamMP3.load_from_buffer(response[3] as PackedByteArray)
	if stream == null:
		return
	_audio_stream_cache[url] = stream
	_play_stream(stream)

func _play_stream(stream: AudioStream) -> void:
	if audio_player and is_instance_valid(audio_player):
		audio_player.queue_free()
	audio_player = AudioStreamPlayer.new()
	audio_player.stream = stream
	add_child(audio_player)
	audio_player.play()

func _frequency_for_note(value: String) -> float:
	var root := value.to_lower().replace("đô", "do").replace("đố", "do").replace("đồ", "do")
	if root.begins_with("do"): return 261.63
	if root.begins_with("rê") or root.begins_with("re"): return 293.66
	if root.begins_with("mi"): return 329.63
	if root.begins_with("fa"): return 349.23
	if root.begins_with("sol"): return 392.0
	if root.begins_with("la"): return 440.0
	return 493.88

func _answer(button: Button, selected_index: int, selected_text: String) -> void:
	if answered:
		return
	answered = true
	for child in options_box.get_children():
		if child is Button:
			(child as Button).disabled = true
	var quiz: Dictionary = quizzes[question_index]
	# Preserve locally known grading for offline history; the server remains authoritative.
	var pending_preview := _pending_quiz_preview(quiz, selected_index, selected_text)

	var report := _report()
	var result: Dictionary = {}
	if report != null and report.is_signed_in() and int(quiz.get("id", 0)) > 0:
		result = await report.report_quiz(int(quiz.get("id", 0)), selected_text, pending_preview)
		_record_quiz_submission(result)

	# The server response is authoritative when it arrives. Sample/offline quizzes
	# have no server attempt, so grade them locally instead of marking every choice
	# as incorrect.
	var grading := _grade_answer(quiz, selected_index, selected_text, result)
	var is_correct := bool(grading.get("is_correct", false))
	var graded_locally := str(grading.get("source", "")) == "local"
	var earned_points := 0
	var correct_text := str(grading.get("correct_answer", ""))
	if bool(result.get("submitted", false)):
		earned_points = int(result.get("points_earned", 0))
		api_stars_earned += maxi(0, int(result.get("stars_earned", 0)))

	if is_correct:
		correct_count += 1
		# A confirmed response is the only source of backend XP. For sample or
		# temporarily offline questions, keep a clearly provisional local score so
		# the learner still receives a meaningful result and history entry.
		if bool(result.get("submitted", false)):
			score += maxi(0, earned_points)
		else:
			score += int(pending_preview.get("previewPoints", QUIZ_PREVIEW_POINTS))
			local_preview_count += 1
		_style_option_button_state(button, "correct")
	else:
		_style_option_button_state(button, "incorrect")

	if not bool(result.get("submitted", false)) and int(quiz.get("id", 0)) <= 0:
		# Bundled questions do not have a backend quiz id. Persist them separately
		# so they remain visible in Activity History without being retried forever.
		var local_attempt := pending_preview.duplicate(true)
		local_attempt["kind"] = "quiz_local"
		local_attempt["client_attempt_id"] = _client_attempt_id("local-quiz")
		local_attempt["quiz_id"] = int(quiz.get("id", 0))
		local_attempt["selected_answer"] = selected_text
		SecureDataManager.record_local_activity(local_attempt)

	if not is_correct and not correct_text.is_empty():
		for child: Node in options_box.get_children():
			if child is Button and _normalize_answer(str((child as Button).text)).contains(_normalize_answer(correct_text)):
				_style_option_button_state(child as Button, "correct")
				break

	var feedback_text := ""
	if is_correct:
		if graded_locally:
			feedback_text = "Bạn đã trả lời chính xác! Kết quả sẽ được đồng bộ khi có mạng." if int(quiz.get("id", 0)) > 0 else "Bạn đã trả lời chính xác! Đây là câu hỏi mẫu."
		else:
			feedback_text = "Bạn đã trả lời chính xác! +%d điểm" % (earned_points if earned_points > 0 else 10)
	else:
		feedback_text = "Chưa chính xác. Đáp án đúng là: %s" % correct_text if not correct_text.is_empty() else "Chưa thể chấm câu trả lời này. Hãy thử lại khi có mạng."

	# Update score pill label immediately
	if score_label and is_instance_valid(score_label):
		score_label.text = str(score)

	# Display feedback text below the options box
	var feedback_color := Color("#2e7d32") if is_correct else Color("#c62828")
	var ans_label := _label(feedback_text, 16, feedback_color)
	ans_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_box.add_child(ans_label)

	# Make inline next button visible
	if next_button:
		next_button.visible = true
		content_box.move_child(next_button, content_box.get_child_count() - 1)

	_set_bottom_feedback_answered(is_correct, feedback_text)

func _next_question() -> void:
	if not answered:
		return
	question_index += 1
	if question_index >= quizzes.size():
		_show_quiz_result()
	else:
		_show_question()

func _show_quiz_result() -> void:
	if progress_bar:
		progress_bar.get_parent().visible = false
	if bottom_feedback_panel:
		bottom_feedback_panel.visible = false
	if floating_back_button:
		floating_back_button.visible = false

	var report := _report()
	if report != null and report.is_signed_in():
		await report.refresh_progress_from_backend()
	var preview_stars := _stars(score, maxi(1, quizzes.size() * QUIZ_PREVIEW_POINTS))
	var stars := clampi(api_stars_earned if api_stars_earned > 0 else preview_stars, 0, 3)
	_show_result("Quiz hoàn thành!", "Bạn trả lời đúng %d / %d câu." % [correct_count, quizzes.size()], score, stars, _restart, float(correct_count) / float(maxi(1, quizzes.size())) * 100.0)


## Trạng thái đồng bộ ở trang kết quả phải phản ánh attempt đã nộp, không chỉ
## phản ánh việc câu hỏi được tải từ backend.
func _record_quiz_submission(result: Dictionary) -> void:
	if bool(result.get("submitted", false)):
		submitted_attempt_count += 1
		if unsynced_attempt_count == 0:
			result_sync_status = "be"
		return
	unsynced_attempt_count += 1
	result_sync_status = "failed"

func _restart() -> void:
	if progress_bar:
		progress_bar.get_parent().visible = true
	if bottom_feedback_panel:
		bottom_feedback_panel.visible = true
	if floating_back_button:
		floating_back_button.visible = true

	question_index = 0
	score = 0
	correct_count = 0
	api_stars_earned = 0
	submitted_attempt_count = 0
	unsynced_attempt_count = 0
	local_preview_count = 0
	result_sync_status = "offline"
	_show_question()

func _parse_options(raw: Variant) -> Array:
	return Context.parse_options(raw)

func _is_correct(index: int, selected: String, quiz: Dictionary) -> bool:
	var options: Array = _parse_options(quiz.get("options", []))
	return _resolve_correct_index(quiz, options) == index or _normalize_answer(selected) == _normalize_answer(str(quiz.get("correctAnswer", quiz.get("correct_answer", ""))))


func _grade_answer(quiz: Dictionary, selected_index: int, selected_text: String, result: Dictionary) -> Dictionary:
	if bool(result.get("submitted", false)):
		return {
			"is_correct": bool(result.get("is_correct", false)),
			"correct_answer": str(result.get("correct_answer", "")),
			"source": "server"
		}
	return {
		"is_correct": _is_correct(selected_index, selected_text, quiz),
		"correct_answer": str(quiz.get("correctAnswer", quiz.get("correct_answer", ""))),
		"source": "local"
	}


## Do not invent a score when the learner did not receive the correct answer.
func _pending_quiz_preview(quiz: Dictionary, selected_index: int, selected_text: String = "") -> Dictionary:
	var options: Array = _parse_options(quiz.get("options", []))
	var correct_index := _resolve_correct_index(quiz, options)
	if correct_index < 0:
		return {
			"title": str(quiz.get("title", "Câu hỏi")),
			"lessonTitle": _instrument_title(),
			"question": str(quiz.get("question", "")),
			"selectedAnswer": selected_text,
			"completedAt": _now_iso(),
		}
	var is_correct := selected_index == correct_index
	return {
		"title": str(quiz.get("title", "Câu hỏi")),
		"lessonTitle": _instrument_title(),
		"question": str(quiz.get("question", "")),
		"selectedAnswer": selected_text,
		"correctAnswer": str(options[correct_index]),
		"score": 100 if is_correct else 0,
		"maxScore": 100,
		"isCorrect": is_correct,
		"previewPoints": QUIZ_PREVIEW_POINTS if is_correct else 0,
		"previewStars": _stars(100 if is_correct else 0, 100),
		"completedAt": _now_iso(),
	}

func _filter_valid_quizzes(source: Array) -> Array:
	var valid: Array = []
	for item: Variant in source:
		if item is Dictionary:
			var quiz: Dictionary = item
			var options: Array = _parse_options(quiz.get("options", []))
			# Quiz BE không gửi correctAnswer cho LEARNER trước khi nộp bài. Chỉ
			# cần options hợp lệ; backend là nơi chấm điểm sau khi người dùng chọn.
			# Quiz mẫu (id <= 0) phải giữ đáp án để có thể chấm offline.
			var is_backend_quiz := int(quiz.get("id", 0)) > 0
			var has_local_answer := _resolve_correct_index(quiz, options) >= 0
			if options.size() >= 2 and (is_backend_quiz or has_local_answer):
				valid.append(quiz)
			else:
				print("[QuizDebug] Bỏ qua Quiz id=%s (options=%s, expected=%s)" % [
					str(quiz.get("id")),
					str(options),
					str(quiz.get("correctAnswer", quiz.get("correct_answer", ""))),
				])
	return valid

func _resolve_correct_index(quiz: Dictionary, options: Array) -> int:
	return Context.resolve_correct_index(quiz, options)

func _normalize_answer(value: String) -> String:
	return Context.normalize_answer(value)
