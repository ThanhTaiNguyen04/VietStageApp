extends "res://scripts/LearningActivityBase.gd"

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

func _ready() -> void:
	super._ready()
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
		quizzes = loaded
	if quizzes.is_empty():
		result_sync_status = "offline"
		var samples: Dictionary = _sample_data()
		quizzes = samples.get("quiz", [])
	if quizzes.is_empty():
		_show_message("Bài học này chưa có câu hỏi trắc nghiệm.")
		return
	question_index = 0
	score = 0
	correct_count = 0
	_show_question()

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
	var quiz: Dictionary = quizzes[question_index]
	var progress := _label("CÂU %d / %d                         ĐIỂM: %d" % [question_index + 1, quizzes.size(), score], 18, C_MUTED)
	content_box.add_child(progress)
	question_card = PanelContainer.new()
	question_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	question_card.add_theme_stylebox_override("panel", _panel(Color.WHITE, C_BLUE, 22, 2))
	content_box.add_child(question_card)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	question_card.add_child(body)
	var prompt := _label(str(quiz.get("question", "Nhận diện nốt nhạc")), 20 if get_viewport_rect().size.x < 600.0 else 22, C_NAVY)
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
	var staff := Control.new()
	staff.set_script(load("res://scripts/LearningStaffDisplay.gd"))
	staff.set("note_name", _quiz_note(quiz))
	staff.custom_minimum_size = Vector2(0, 138)
	staff.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(staff)
	audio_button = _button("▶  Nghe âm thanh mẫu", 235, 48, C_BLUE)
	audio_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	audio_button.pressed.connect(func() -> void: _play_quiz_audio(quiz))
	body.add_child(audio_button)
	var hint := _label("Chọn đáp án đúng trong các lựa chọn bên dưới.", 16, C_MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(hint)
	options_box = GridContainer.new()
	options_box.columns = 1 if get_viewport_rect().size.x < 600.0 else 2
	options_box.add_theme_constant_override("separation", 10)
	body.add_child(options_box)
	var options: Array = _parse_options(quiz.get("options", ""))
	for i in range(options.size()):
		var option_text := str(options[i])
		var button := _button("%s. %s" % [char(65 + i), option_text], 0, 58, C_BLUE)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(func() -> void: _answer(button, i, option_text))
		options_box.add_child(button)

func _visual_hint(quiz: Dictionary) -> String:
	var content := str(quiz.get("question", ""))
	if content.to_lower().contains("khuông") or content.to_lower().contains("khuong"):
		return "────  ♩  ────"
	return "♫"

func _quiz_note(quiz: Dictionary) -> String:
	var explicit := str(quiz.get("note", quiz.get("targetNote", "")))
	if not explicit.is_empty():
		return explicit
	return str(quiz.get("correctAnswer", "Sol"))

func _play_quiz_audio(quiz: Dictionary) -> void:
	if audio_player and is_instance_valid(audio_player):
		audio_player.queue_free()
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
	var frequency := _frequency_for_note(_quiz_note(quiz))
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
	if bool(result.get("submitted", false)):
		is_correct = bool(result.get("is_correct", fallback_correct))
	if is_correct:
		correct_count += 1
		score += int(result.get("points_earned", 10)) if int(result.get("points_earned", 0)) > 0 else 10
		button.add_theme_stylebox_override("normal", _panel(C_OK, C_OK, 14, 1))
	else:
		button.add_theme_stylebox_override("normal", _panel(C_BAD, C_BAD, 14, 1))
	feedback_label = _label("Chính xác! +XP" if is_correct else "Chưa đúng. Đáp án: %s" % str(quiz.get("correctAnswer", "")), 18, C_OK if is_correct else C_BAD)
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
	if raw is Array:
		return raw
	var text := str(raw).strip_edges()
	var parsed: Variant = JSON.parse_string(text) if not text.is_empty() else null
	if parsed is Array:
		return parsed
	return text.split("|") if text.contains("|") else text.split(",")

func _is_correct(index: int, selected: String, quiz: Dictionary) -> bool:
	var expected := str(quiz.get("correctAnswer", "")).strip_edges().to_lower()
	var chosen := selected.strip_edges().to_lower()
	return expected == chosen or expected == char(65 + index).to_lower() or expected.begins_with(char(65 + index).to_lower() + ".")
