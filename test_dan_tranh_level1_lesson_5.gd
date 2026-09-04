extends SceneTree


func _init() -> void:
	var lesson_list = load("res://scripts/LessonDanTranhList.gd")
	var lesson_scene = load("res://scripts/LessonDanTranh.gd")
	var failures: Array[String] = []
	var lesson_5: Dictionary = {}
	for lesson_value in lesson_list.get_level_data(1).get("lessons", []):
		var lesson: Dictionary = lesson_value
		if str(lesson.get("display_number", "")) == "5":
			lesson_5 = lesson
			break

	var expected_notes: Array[String] = ["Sol1", "La1", "Đô2", "Rê2", "Mi2", "Sol2", "La2", "Đô3", "Rê3", "Mi3"]
	var expected_frequencies: Array[float] = [196.00, 220.00, 261.63, 293.66, 329.63, 392.00, 440.00, 523.25, 587.33, 659.25]
	var actual_notes: Array[String] = []
	actual_notes.assign(lesson_5.get("sheet", []))
	if actual_notes != expected_notes:
		failures.append("Bài 5 phải luyện đúng 10 nốt từ Sol1 đến Mi3")
	if int(lesson_5.get("number", 0)) != 2:
		failures.append("ID nội bộ của bài 5 phải giữ là bài 2")
	if "micro" not in str(lesson_5.get("practice", "")).to_lower():
		failures.append("Mô tả bài 5 chưa yêu cầu nhận diện đàn thật bằng micro")

	var dialogue_notes: Array[String] = []
	for step_value in lesson_scene.LESSON_DIALOGUES.get("dan_tranh_level_1_bai_2_practice", []):
		var step: Dictionary = step_value
		if step.has("note"):
			dialogue_notes.append(str(step["note"]))
	if dialogue_notes != expected_notes:
		failures.append("Lời cô Mai chưa chờ nhận diện lần lượt đủ 10 dây")

	for index in range(expected_notes.size()):
		var note_name := expected_notes[index]
		if int(lesson_scene.NOTE_TO_STRING.get(note_name, -1)) != index:
			failures.append("Sai ánh xạ dây %d của nốt %s" % [index + 1, note_name])
		if not is_equal_approx(float(lesson_scene.NOTE_FREQS.get(note_name, 0.0)), expected_frequencies[index]):
			failures.append("Sai tần số nhận diện của nốt %s" % note_name)

	if failures.is_empty():
		print("PASS: bài 5 nhận diện đúng 10 nốt trên dây 1 đến 10")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)
