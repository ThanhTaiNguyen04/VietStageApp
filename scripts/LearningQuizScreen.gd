extends "res://scripts/LearningActivityBase.gd"

const DanTranhAudio = preload("res://scripts/DanTranhAudio.gd")

var quizzes: Array = []
var question_index := 0
var score := 0
var correct_count := 0
var answered := false
var question_card: PanelContainer
var options_box: GridContainer
var feedback_label: Label
var next_button: Button
var progress_bar: ProgressBar
var audio_button: Button
var audio_player: AudioStreamPlayer
var _audio_stream_cache: Dictionary = {}

func _ready() -> void:
	super._ready()
	_add_quiz_scrim()
	title_label.text = "QUIZ - NHẬN DIỆN NỐT NHẠC"
	_show_loading()
	_begin_quiz()

func _show_loading() -> void:
	var loading := _label("Đang tải câu hỏi từ bài học...", 17, C_MUTED)
	loading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_box.add_child(loading)

func _begin_quiz() -> void:
	var report := _report()
	if report != null and report.is_signed_in():
		result_sync_status = "be"
		var loaded: Array = await report.fetch_quizzes_for_level(Context.instrument, Context.local_lesson_ids)
		print("[QuizDebug] Backend returned %d quizzes." % loaded.size())
		print("[CatalogDebug] be_catalog = ", SecureDataManager.be_catalog)
		quizzes = _filter_valid_quizzes(loaded)
		print("[QuizDebug] Filtered down to %d valid quizzes." % quizzes.size())
	else:
		result_sync_status = "offline"
		var samples: Dictionary = _sample_data()
		quizzes = _filter_valid_quizzes(samples.get("quiz", []))
	_sort_quizzes()
	if quizzes.is_empty():
		_show_message("Bài học này chưa có câu hỏi trắc nghiệm.")
		return
	question_index = 0
	score = 0
	correct_count = 0
	_show_question()

func _sort_quizzes() -> void:
	quizzes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("orderIndex", 0)) < int(b.get("orderIndex", 0)))

func _show_message(message: String) -> void:
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
	feedback_label = null
	next_button = null
	var quiz: Dictionary = quizzes[question_index]
	var progress_row := HBoxContainer.new()
	progress_row.add_theme_constant_override("separation", 12)
	var progress_spacer := Control.new()
	progress_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_row.add_child(progress_spacer)
	var score_text := _label("Điểm %d" % score, 17, C_MUTED)
	score_text.custom_minimum_size = Vector2(110, 32)
	score_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	score_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	progress_row.add_child(score_text)
	content_box.add_child(progress_row)
	question_card = PanelContainer.new()
	question_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	question_card.add_theme_stylebox_override("panel", _panel(Color(0.98, 0.96, 0.90, 0.94), C_GOLD, 20, 1))
	content_box.add_child(question_card)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	question_card.add_child(body)
	var prompt := _label(str(quiz.get("question", "Nhận diện nốt nhạc")), 26 if get_viewport_rect().size.x < 600.0 else 30, C_NAVY)
	prompt.add_theme_font_override("font", load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(prompt)
	progress_bar = ProgressBar.new()
	progress_bar.max_value = 100.0
	progress_bar.value = float(question_index + 1) / float(quizzes.size()) * 100.0
	progress_bar.show_percentage = false
	progress_bar.custom_minimum_size = Vector2(0, 8)
	progress_bar.add_theme_stylebox_override("background", _panel(Color("#e9edf5"), Color("#e9edf5"), 5, 0))
	progress_bar.add_theme_stylebox_override("fill", _panel(C_BLUE, C_BLUE, 5, 0))
	body.add_child(progress_bar)
	var show_staff := _is_note_question(quiz)
	if show_staff:
		var staff_card := PanelContainer.new()
		staff_card.name = "QuizStaffCard"
		staff_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		staff_card.add_theme_stylebox_override("panel", _practice_staff_style())
		body.add_child(staff_card)
		var staff: Control = load("res://scripts/StaffDisplay.gd").new()
		var mobile := get_viewport_rect().size.x < 600.0
		staff.line_spacing = 34.0 if mobile else 48.0
		staff.show_time_sig = true
		staff.beats_per_measure = 4
		staff.time_sig_denominator = 4
		staff.show_metronome = false
		staff.show_hit_line = false
		staff.show_clef = true
		staff.custom_minimum_size = Vector2(0, 240 if mobile else 320)
		staff.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		staff.set_notes([{"note": _quiz_note(quiz), "color": Color.BLACK, "type": "quarter"}])
		staff_card.add_child(staff)
		audio_button = _secondary_button("Nghe mẫu", 190, 52, C_NAVY)
		audio_button.add_theme_font_size_override("font_size", 17)
		audio_button.icon = load("res://assets/textures/lucide/volume-2.svg") as Texture2D
		audio_button.expand_icon = true
		audio_button.add_theme_constant_override("icon_max_width", 18)
		audio_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		audio_button.pressed.connect(func() -> void: _play_quiz_audio(quiz))
		body.add_child(audio_button)
	options_box = GridContainer.new()
	options_box.columns = 1 if get_viewport_rect().size.x < 600.0 else 2
	options_box.add_theme_constant_override("separation", 10)
	body.add_child(options_box)
	var options: Array = _parse_options(quiz.get("options", ""))
	var mobile_options := get_viewport_rect().size.x < 600.0
	for i in range(options.size()):
		var option_text := str(options[i])
		var button := _secondary_button("%s. %s" % [char(65 + i), option_text], 0, 68 if mobile_options else 72, C_NAVY)
		button.add_theme_font_size_override("font_size", 20 if mobile_options else 22)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(func() -> void: _answer(button, i, option_text))
		options_box.add_child(button)

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
	style.bg_color = Color(0.995, 0.98, 0.93, 0.96)
	style.border_color = Color(0.88, 0.72, 0.38, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0.45, 0.30, 0.12, 0.20)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 5)
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
	var fallback_correct := _is_correct(selected_index, selected_text, quiz)
	var report := _report()
	var result: Dictionary = {}
	if report != null and report.is_signed_in() and int(quiz.get("id", 0)) > 0:
		result = await report.report_quiz(int(quiz.get("id", 0)), selected_text)
	var is_correct := fallback_correct
	var earned_points := 0
	if bool(result.get("submitted", false)):
		is_correct = bool(result.get("is_correct", fallback_correct))
		earned_points = int(result.get("points_earned", 0))
	if is_correct:
		correct_count += 1
		score += earned_points if earned_points > 0 else 10
		button.add_theme_stylebox_override("normal", _panel(C_OK, C_OK, 14, 1))
	else:
		button.add_theme_stylebox_override("normal", _panel(C_BAD, C_BAD, 14, 1))
	var quiz_options: Array = _parse_options(quiz.get("options", []))
	var correct_index := _resolve_correct_index(quiz, quiz_options)
	var correct_text := str(quiz_options[correct_index]) if correct_index >= 0 else str(quiz.get("correctAnswer", ""))
	var feedback_text := "Chính xác! +%d điểm" % (earned_points if earned_points > 0 else 10) if is_correct else "Chưa đúng. Đáp án: %s" % correct_text
	feedback_label = _label(feedback_text, 18, C_OK if is_correct else C_BAD)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question_card.get_child(0).add_child(feedback_label)
	next_button = _button("Xem kết quả" if question_index + 1 >= quizzes.size() else "Câu tiếp theo →", 240, 52, C_NAVY)
	next_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	next_button.pressed.connect(_next_question)
	question_card.get_child(0).add_child(next_button)

func _next_question() -> void:
	if not answered:
		return
	question_index += 1
	if question_index >= quizzes.size():
		_show_quiz_result()
	else:
		_show_question()

func _show_quiz_result() -> void:
	var stars := _stars(score, maxi(1, quizzes.size() * 10))
	_show_result("Quiz hoàn thành!", "Bạn trả lời đúng %d / %d câu." % [correct_count, quizzes.size()], score, stars, _restart, float(correct_count) / float(maxi(1, quizzes.size())) * 100.0)

func _restart() -> void:
	question_index = 0
	score = 0
	correct_count = 0
	_show_question()

func _parse_options(raw: Variant) -> Array:
	return Context.parse_options(raw)

func _is_correct(index: int, selected: String, quiz: Dictionary) -> bool:
	var options: Array = _parse_options(quiz.get("options", []))
	return _resolve_correct_index(quiz, options) == index or _normalize_answer(selected) == _normalize_answer(str(quiz.get("correctAnswer", "")))

func _filter_valid_quizzes(source: Array) -> Array:
	var valid: Array = []
	for item: Variant in source:
		if item is Dictionary:
			var quiz: Dictionary = item
			var options: Array = _parse_options(quiz.get("options", []))
			var has_note := not str(quiz.get("note", quiz.get("targetNote", ""))).strip_edges().is_empty()
			if _resolve_correct_index(quiz, options) >= 0 or has_note:
				valid.append(quiz)
			else:
				print("[QuizDebug] Bỏ qua Quiz id=%s, options=%s, expected=%s, parsed_options=%s" % [
					str(quiz.get("id")),
					str(quiz.get("options")),
					str(quiz.get("correctAnswer")),
					str(options)
				])
	return valid

func _resolve_correct_index(quiz: Dictionary, options: Array) -> int:
	return Context.resolve_correct_index(quiz, options)

func _normalize_answer(value: String) -> String:
	return Context.normalize_answer(value)
