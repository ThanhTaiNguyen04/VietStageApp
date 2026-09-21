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
var next_button: Button = null
var floating_back_button: Button
var score_label: Label
var _quiz_stage_v: VBoxContainer = null
var _auto_advance_token := 0

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
	title_label.text = "QUIZ - %s" % ("KIẾN THỨC NHẠC CỤ" if Context.activity == "quiz_knowledge" else "NHẬN DIỆN NỐT NHẠC")

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
	var btn_height := 84.0
	var font_size_option := 22
	var badge_size := Vector2(52, 52)
	var badge_font_size := 20
	var badge_radius := 26

	if v_height < 500.0:
		btn_height = 74.0
		font_size_option = 20
		badge_size = Vector2(46, 46)
		badge_font_size = 18
		badge_radius = 23
	elif v_height >= 750.0:
		btn_height = 92.0
		font_size_option = 24
		badge_size = Vector2(56, 56)
		badge_font_size = 22
		badge_radius = 28
	else:
		btn_height = 82.0
		font_size_option = 22
		badge_size = Vector2(50, 50)
		badge_font_size = 20
		badge_radius = 25

	var button := Button.new()
	button.custom_minimum_size = Vector2(0, btn_height)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.set_meta("option_text", text_value)
	button.set_meta("option_index", index)

	# Normal state (3D border bottom 5px)
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color.WHITE
	normal_style.border_color = Color("#cbd5e1") # slate-300
	normal_style.set_border_width_all(2)
	normal_style.border_width_bottom = 5
	normal_style.set_corner_radius_all(22)
	button.add_theme_stylebox_override("normal", normal_style)

	# Hover state
	var hover_style := normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color("#f8fafc") # slate-50
	hover_style.border_color = Color(0.77, 0.58, 0.15, 0.85) # Gold accent on hover
	button.add_theme_stylebox_override("hover", hover_style)

	# Pressed state
	var pressed_style := normal_style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color("#f1f5f9") # slate-100
	pressed_style.border_color = Color(0.77, 0.58, 0.15, 1.0)
	pressed_style.border_width_top = 4
	pressed_style.border_width_bottom = 2
	button.add_theme_stylebox_override("pressed", pressed_style)

	var disabled_style := normal_style.duplicate() as StyleBoxFlat
	button.add_theme_stylebox_override("disabled", disabled_style)

	# Internal layout container
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
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
	badge_style.set_border_width_all(2)
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
		if not button.disabled and not answered:
			create_tween().tween_property(button, "scale", Vector2(1.02, 1.02), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	)
	button.mouse_exited.connect(func() -> void:
		if not button.disabled and not answered:
			create_tween().tween_property(button, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	)

	return button

func _style_option_button_state(button: Button, state: String) -> void:
	var style := button.get_theme_stylebox("disabled") as StyleBoxFlat
	if style == null:
		style = StyleBoxFlat.new()
		style.set_corner_radius_all(22)
		style.set_border_width_all(2)
		style.border_width_bottom = 5
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

		# Taste micro-bounce
		var tw := create_tween()
		tw.tween_property(button, "scale", Vector2(1.025, 1.025), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(button, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

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
				await _install_backend_quizzes(_backend_quizzes)
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
	await _install_backend_quizzes(valid)

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

func _create_frosted_stage(is_mobile: bool) -> Dictionary:
	var viewport_size := get_viewport_rect().size
	var is_compact := viewport_size.y < 750.0
	var stage_panel := PanelContainer.new()
	stage_panel.name = "FrostedStage"
	stage_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL if is_mobile else Control.SIZE_SHRINK_CENTER
	stage_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if not is_mobile:
		var target_w := clampf(viewport_size.x * 0.94, 1100.0, 1360.0)
		stage_panel.custom_minimum_size = Vector2(target_w, 0)

	var stage_sb := StyleBoxFlat.new()
	stage_sb.bg_color = Color(1.0, 0.99, 0.97, 0.62) # Soft translucent frosted glass
	stage_sb.border_color = Color(0.77, 0.58, 0.15, 0.50) # Antique lacquer gold border
	stage_sb.set_border_width_all(2)
	stage_sb.set_corner_radius_all(30)
	stage_sb.shadow_color = Color(0.04, 0.08, 0.06, 0.12)
	stage_sb.shadow_size = 28
	stage_sb.shadow_offset = Vector2(0, 8)
	stage_panel.add_theme_stylebox_override("panel", stage_sb)

	# Frosted Blur Rect (hint_screen_texture)
	var stage_blur := ColorRect.new()
	stage_blur.name = "StageBlurRect"
	stage_blur.show_behind_parent = true
	stage_blur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_blur.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var mat := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
void fragment() {
	COLOR = textureLod(screen_texture, SCREEN_UV, 2.4);
}"""
	mat.shader = shader
	stage_blur.material = mat
	stage_panel.add_child(stage_blur)

	var stage_margin := MarginContainer.new()
	stage_margin.add_theme_constant_override("margin_left", 20 if is_mobile else (28 if is_compact else 36))
	stage_margin.add_theme_constant_override("margin_right", 20 if is_mobile else (28 if is_compact else 36))
	stage_margin.add_theme_constant_override("margin_top", 18 if is_mobile else (18 if is_compact else 26))
	stage_margin.add_theme_constant_override("margin_bottom", 18 if is_mobile else (18 if is_compact else 26))
	stage_panel.add_child(stage_margin)

	var stage_v := VBoxContainer.new()
	stage_v.add_theme_constant_override("separation", 12 if is_mobile else (14 if is_compact else 18))
	stage_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_margin.add_child(stage_v)

	return {"panel": stage_panel, "vbox": stage_v}

func _show_question() -> void:
	for child in content_box.get_children():
		child.queue_free()

	answered = false
	audio_button = null

	var quiz: Dictionary = quizzes[question_index]
	var viewport_size := get_viewport_rect().size
	var mobile := viewport_size.x < 600.0
	var v_height := viewport_size.y
	var is_compact := v_height < 750.0

	var staff_height := 240.0
	var staff_spacing := 42.0
	var font_size_prompt := 26

	if v_height < 500.0: # Mobile Landscape
		staff_height = 190.0
		staff_spacing = 34.0
		font_size_prompt = 22
	elif is_compact: # Standard Laptop / Compact Viewport
		staff_height = 205.0
		staff_spacing = 38.0
		font_size_prompt = 24
	else: # Large Desktop / Tablet
		staff_height = 240.0
		staff_spacing = 42.0
		font_size_prompt = 26

	_set_bottom_feedback_waiting()

	# Smoothly tween progress bar value
	var target_value := float(question_index + 1) / float(quizzes.size()) * 100.0
	var progress_tween := create_tween()
	progress_tween.tween_property(progress_bar, "value", target_value, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Update score label in top bar
	if score_label and is_instance_valid(score_label):
		score_label.text = str(score)

	content_box.alignment = BoxContainer.ALIGNMENT_CENTER
	var stage := _create_frosted_stage(mobile)
	content_box.add_child(stage["panel"])
	var stage_v := stage["vbox"] as VBoxContainer
	_quiz_stage_v = stage_v

	# 1. Question Prompt Card (dedicated highlight card on top of frosted stage)
	var question_card := PanelContainer.new()
	question_card.name = "QuestionPromptCard"
	question_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var q_style := StyleBoxFlat.new()
	q_style.bg_color = Color(1.0, 1.0, 1.0, 0.92)
	q_style.border_color = Color(0.77, 0.58, 0.15, 0.45)
	q_style.set_border_width_all(2)
	q_style.border_width_bottom = 4
	q_style.set_corner_radius_all(18)
	q_style.shadow_color = Color(0, 0, 0, 0.04)
	q_style.shadow_size = 5
	q_style.shadow_offset = Vector2(0, 2)
	q_style.content_margin_left = 22 if is_compact else 28
	q_style.content_margin_right = 22 if is_compact else 28
	q_style.content_margin_top = 12 if is_compact else 16
	q_style.content_margin_bottom = 12 if is_compact else 16
	question_card.add_theme_stylebox_override("panel", q_style)
	stage_v.add_child(question_card)

	var prompt := Label.new()
	prompt.text = str(quiz.get("question", "Nhận diện nốt nhạc"))
	prompt.add_theme_font_override("font", load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font)
	prompt.add_theme_font_size_override("font_size", font_size_prompt)
	prompt.add_theme_color_override("font_color", C_NAVY)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt.add_theme_constant_override("line_spacing", 4)
	question_card.add_child(prompt)

	# 2. Staff Display (whiteboard card on top of frosted stage)
	var show_staff := _is_note_question(quiz)
	if show_staff:
		var staff_card := PanelContainer.new()
		staff_card.name = "QuizStaffCard"
		staff_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		staff_card.add_theme_stylebox_override("panel", _practice_staff_style())
		stage_v.add_child(staff_card)

		var whiteboard_vbox := VBoxContainer.new()
		whiteboard_vbox.add_theme_constant_override("separation", 2)
		staff_card.add_child(whiteboard_vbox)

		# Top header row inside the staff card with audio button
		var card_header := HBoxContainer.new()
		card_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		whiteboard_vbox.add_child(card_header)

		var card_header_spacer := Control.new()
		card_header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_header.add_child(card_header_spacer)

		# Large audio button in top-right of staff card
		var audio_btn_size := 48 if is_compact else 54
		audio_button = Button.new()
		audio_button.custom_minimum_size = Vector2(audio_btn_size, audio_btn_size)
		audio_button.icon = load("res://assets/textures/lucide/volume-2.svg") as Texture2D
		audio_button.expand_icon = true
		audio_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		audio_button.add_theme_constant_override("icon_max_width", int(audio_btn_size * 0.5))
		audio_button.size_flags_horizontal = Control.SIZE_SHRINK_END
		audio_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		var btn_style_n := StyleBoxFlat.new()
		btn_style_n.bg_color = Color.WHITE
		btn_style_n.border_color = Color("#cbd5e1")
		btn_style_n.set_border_width_all(2)
		btn_style_n.border_width_bottom = 3
		btn_style_n.set_corner_radius_all(int(audio_btn_size * 0.5))

		var btn_style_h := btn_style_n.duplicate() as StyleBoxFlat
		btn_style_h.bg_color = Color("#f8fafc")
		btn_style_h.border_color = Color("#94a3b8")

		var btn_style_p := btn_style_n.duplicate() as StyleBoxFlat
		btn_style_p.bg_color = Color("#f1f5f9")
		btn_style_p.border_color = Color("#64748b")
		btn_style_p.border_width_top = 2
		btn_style_p.border_width_bottom = 1

		audio_button.add_theme_stylebox_override("normal", btn_style_n)
		audio_button.add_theme_stylebox_override("hover", btn_style_h)
		audio_button.add_theme_stylebox_override("pressed", btn_style_p)
		audio_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		audio_button.add_theme_color_override("icon_normal_color", C_NAVY)

		audio_button.pivot_offset = Vector2(audio_btn_size * 0.5, audio_btn_size * 0.5)
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

	# 3. Options Grid (on top of frosted stage)
	options_box = GridContainer.new()
	options_box.name = "OptionsGrid"
	options_box.columns = 1 if mobile else 2
	options_box.add_theme_constant_override("h_separation", 16 if is_compact else 20)
	options_box.add_theme_constant_override("v_separation", 12 if is_compact else 16)
	options_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_v.add_child(options_box)

	var options: Array = _parse_options(quiz.get("options", ""))
	for i in range(options.size()):
		var option_text := str(options[i])
		var button := _create_option_button(i, option_text)
		button.pressed.connect(func() -> void: _answer(button, i, option_text))
		options_box.add_child(button)

	# 4. Status / Feedback slot (pre-allocated height so layout NEVER shifts or jumps)
	var feedback_slot := Label.new()
	feedback_slot.name = "FeedbackSlot"
	feedback_slot.custom_minimum_size = Vector2(0, 30 if is_compact else 34)
	feedback_slot.add_theme_font_override("font", load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font)
	feedback_slot.add_theme_font_size_override("font_size", 16 if is_compact else 18)
	feedback_slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_slot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	feedback_slot.text = ""
	feedback_slot.modulate.a = 0.0
	stage_v.add_child(feedback_slot)
	feedback_label = feedback_slot

func _add_quiz_scrim() -> void:
	var scrim := ColorRect.new()
	scrim.name = "QuizBackgroundScrim"
	scrim.color = Color(0.04, 0.07, 0.06, 0.20)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scrim)
	move_child(scrim, root_box.get_index())

func _practice_staff_style() -> StyleBoxFlat:
	var v_height := get_viewport_rect().size.y
	var is_compact := v_height < 750.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#ffffff")
	style.border_color = Color(0.77, 0.58, 0.15, 0.40)
	style.set_border_width_all(2)
	style.border_width_bottom = 3 if is_compact else 4
	style.set_corner_radius_all(20 if is_compact else 24)
	style.shadow_color = Color(0.20, 0.15, 0.08, 0.06)
	style.shadow_size = 8 if is_compact else 10
	style.shadow_offset = Vector2(0, 3 if is_compact else 4)
	style.content_margin_left = 18 if is_compact else 22
	style.content_margin_right = 18 if is_compact else 22
	style.content_margin_top = 10 if is_compact else 16
	style.content_margin_bottom = 10 if is_compact else 16
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
	var quiz_id := int(quiz.get("id", 0))
	var is_backend_quiz := quiz_id > 0
	# Preserve locally known grading for offline history; the server remains authoritative.
	var pending_preview := _pending_quiz_preview(quiz, selected_index, selected_text)

	var report := _report()
	var result: Dictionary = {}
	if is_backend_quiz and report != null and report.is_signed_in():
		result = await report.report_quiz(quiz_id, selected_text, pending_preview)
		_record_quiz_submission(result)

	# The server response is authoritative when it arrives. Sample/offline quizzes
	# have no server attempt, so grade them locally instead of marking every choice
	# as incorrect.
	var grading := _grade_answer(quiz, selected_index, selected_text, result)
	var is_correct := bool(grading.get("is_correct", false))
	var earned_points := 0
	var correct_text := str(grading.get("correct_answer", ""))
	if bool(result.get("submitted", false)):
		earned_points = int(result.get("points_earned", 0))
		api_stars_earned += maxi(0, int(result.get("stars_earned", 0)))

	if is_correct:
		correct_count += 1
		if bool(result.get("submitted", false)):
			score += maxi(0, earned_points)
		elif not is_backend_quiz:
			score += int(pending_preview.get("previewPoints", QUIZ_PREVIEW_POINTS))
			local_preview_count += 1
		_style_option_button_state(button, "correct")
	else:
		_style_option_button_state(button, "incorrect")

	if not is_backend_quiz:
		# Sample/offline quiz only
		var local_attempt := pending_preview.duplicate(true)
		local_attempt["kind"] = "quiz_local"
		local_attempt["client_attempt_id"] = _client_attempt_id("local-quiz")
		local_attempt["quiz_id"] = 0
		local_attempt["selected_answer"] = selected_text
		SecureDataManager.record_local_activity(local_attempt)

	if not is_correct and not correct_text.is_empty():
		for child: Node in options_box.get_children():
			if child is Button:
				var opt_btn := child as Button
				var opt_lbl := opt_btn.find_child("TextLabel", true, false) as Label
				var opt_str := opt_lbl.text if opt_lbl else opt_btn.text
				if opt_btn.has_meta("option_text"):
					opt_str = str(opt_btn.get_meta("option_text"))
				if _normalize_answer(opt_str) == _normalize_answer(correct_text) or _normalize_answer(opt_str).contains(_normalize_answer(correct_text)) or _normalize_answer(correct_text).contains(_normalize_answer(opt_str)):
					_style_option_button_state(opt_btn, "correct")
					break

	var feedback_text := ""
	if is_correct:
		if is_backend_quiz and not bool(result.get("submitted", false)):
			feedback_text = "Bạn đã chọn đáp án này. Kết quả sẽ được đồng bộ khi có mạng."
		elif not is_backend_quiz:
			feedback_text = "Chính xác! (Dữ liệu mẫu/Offline)"
		else:
			feedback_text = "Bạn đã trả lời chính xác! +%d điểm" % (earned_points if earned_points > 0 else 10)
	else:
		if is_backend_quiz and not bool(result.get("submitted", false)):
			feedback_text = "Chưa thể đồng bộ đáp án. Đã lưu để thử lại khi có mạng."
		elif not correct_text.is_empty():
			feedback_text = "Chưa chính xác. Đáp án đúng là: %s" % correct_text
		else:
			feedback_text = "Chưa thể chấm câu trả lời này. Hãy thử lại khi có mạng."

	# Update score pill label immediately
	if score_label and is_instance_valid(score_label):
		score_label.text = str(score)

	# Display feedback in pre-allocated slot without expanding or shifting layout
	var feedback_color := Color("#2e7d32") if is_correct else (Color("#d97706") if (is_backend_quiz and not bool(result.get("submitted", false))) else Color("#c62828"))
	if feedback_label and is_instance_valid(feedback_label):
		feedback_label.text = feedback_text
		feedback_label.add_theme_color_override("font_color", feedback_color)
		var fb_tw := create_tween()
		fb_tw.tween_property(feedback_label, "modulate:a", 1.0, 0.15)

	_set_bottom_feedback_answered(is_correct, feedback_text)

	# Auto-advance to next question (0.9s for correct, 1.5s for incorrect)
	var auto_advance_delay := 0.9 if is_correct else 1.5
	_auto_advance_token += 1
	var current_token := _auto_advance_token
	var advance_timer := get_tree().create_timer(auto_advance_delay)
	advance_timer.timeout.connect(func() -> void:
		if current_token == _auto_advance_token and is_instance_valid(self):
			_next_question()
	)

func _next_question() -> void:
	if not answered:
		return
	_auto_advance_token += 1
	question_index += 1
	if question_index >= quizzes.size():
		_show_quiz_result()
		return

	# Smooth cross-fade transition into the next question
	if _quiz_stage_v and is_instance_valid(_quiz_stage_v):
		var stage_panel = _quiz_stage_v.get_parent().get_parent()
		if stage_panel and is_instance_valid(stage_panel) and stage_panel is Control:
			var tw := create_tween()
			tw.tween_property(stage_panel, "modulate:a", 0.0, 0.10)
			tw.tween_callback(func() -> void:
				_show_question()
				if _quiz_stage_v and is_instance_valid(_quiz_stage_v):
					var next_panel = _quiz_stage_v.get_parent().get_parent()
					if next_panel and is_instance_valid(next_panel) and next_panel is Control:
						next_panel.modulate.a = 0.0
						var tw2 := create_tween()
						tw2.tween_property(next_panel, "modulate:a", 1.0, 0.14)
			)
			return
	_show_question()

func _unhandled_input(event: InputEvent) -> void:
	if answered and (event is InputEventMouseButton or event is InputEventScreenTouch):
		if event.is_pressed():
			_auto_advance_token += 1
			_next_question()

func _go_back() -> void:
	_auto_advance_token += 1
	super._go_back()

func _show_quiz_result() -> void:
	if progress_bar:
		progress_bar.get_parent().visible = false
	if bottom_feedback_panel:
		bottom_feedback_panel.visible = false
	if floating_back_button:
		floating_back_button.visible = false

	var report := _report()
	if report != null and report.is_signed_in() and not _using_sample_quizzes:
		await report.refresh_progress_from_backend()
		if unsynced_attempt_count == 0 and submitted_attempt_count > 0:
			result_sync_status = "be"
		elif unsynced_attempt_count > 0:
			result_sync_status = "failed"
		else:
			result_sync_status = "pending"
	else:
		result_sync_status = "offline"

	var preview_stars := _stars(score, maxi(1, quizzes.size() * QUIZ_PREVIEW_POINTS))
	var stars := clampi(api_stars_earned if api_stars_earned > 0 else (preview_stars if _using_sample_quizzes else 0), 0, 3)
	var detail_text := "Bạn trả lời đúng %d / %d câu." % [correct_count, quizzes.size()]
	if result_sync_status == "offline" or _using_sample_quizzes:
		detail_text += " (Dữ liệu mẫu/Offline)"
	elif result_sync_status == "failed":
		detail_text += " Có %d câu chưa đồng bộ được lên máy chủ." % unsynced_attempt_count
	_show_result("Quiz hoàn thành!", detail_text, score, stars, _restart, float(correct_count) / float(maxi(1, quizzes.size())) * 100.0)


## Trạng thái đồng bộ ở trang kết quả phải phản ánh attempt đã nộp, không chỉ
## phản ánh việc câu hỏi được tải từ backend.
func _record_quiz_submission(result: Dictionary) -> void:
	if bool(result.get("submitted", false)):
		submitted_attempt_count += 1
		result_sync_status = "be"
		return
	if str(result.get("reason", "")) == "incomplete":
		result_sync_status = "pending"
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
	if int(quiz.get("id", 0)) > 0:
		return {
			"is_correct": false,
			"correct_answer": "",
			"source": "server_failed"
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
			if not _matches_selected_quiz_type(quiz):
				continue
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

func _matches_selected_quiz_type(quiz: Dictionary) -> bool:
	var question_type := str(quiz.get("questionType", quiz.get("question_type", "NOTE_IDENTIFICATION"))).to_upper().strip_edges()
	if Context.activity == "quiz_knowledge":
		return question_type != "NOTE_IDENTIFICATION"
	return question_type == "NOTE_IDENTIFICATION"

func _resolve_correct_index(quiz: Dictionary, options: Array) -> int:
	return Context.resolve_correct_index(quiz, options)

func _normalize_answer(value: String) -> String:
	return Context.normalize_answer(value)
