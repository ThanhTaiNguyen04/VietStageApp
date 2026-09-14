extends SceneTree


func _init() -> void:
	var lesson_list = load("res://scripts/LessonDanTranhList.gd")
	var lesson_scene = load("res://scripts/LessonDanTranh.gd")
	var failures: Array[String] = []
	var lesson_6: Dictionary = {}
	for lesson_value in lesson_list.get_level_data(1).get("lessons", []):
		var lesson: Dictionary = lesson_value
		if str(lesson.get("display_number", "")) == "6":
			lesson_6 = lesson
			break

	var expected_notes: Array[String] = ["Sol3", "La3", "Đô4", "Rê4", "Mi4", "Sol4", "La4"]
	var expected_frequencies: Array[float] = [783.99, 880.00, 1046.50, 1174.66, 1318.51, 1567.98, 1760.00]
	var actual_notes: Array[String] = []
	actual_notes.assign(lesson_6.get("sheet", []))
	if actual_notes != expected_notes:
		failures.append("Bài 6 phải luyện đúng 7 nốt từ Sol3 đến La4")
	if int(lesson_6.get("number", 0)) != 3:
		failures.append("ID nội bộ của bài 6 phải giữ là bài 3")
	if "micro" not in str(lesson_6.get("practice", "")).to_lower():
		failures.append("Mô tả bài 6 chưa yêu cầu nhận diện đàn thật bằng micro")
	var expected_fingerings: Array[String] = ["3", "2", "1", "3", "2", "1", "3"]
	var actual_fingerings: Array[String] = []
	actual_fingerings.assign(lesson_6.get("fingerings", []))
	if actual_fingerings != expected_fingerings:
		failures.append("Bài 6 phải luân phiên ngón 3, 2, 1 từ nốt đầu tiên")

	var dialogue_notes: Array[String] = []
	for step_value in lesson_scene.LESSON_DIALOGUES.get("dan_tranh_level_1_bai_3_practice", []):
		var step: Dictionary = step_value
		if step.has("note"):
			dialogue_notes.append(str(step["note"]))
	if dialogue_notes != expected_notes:
		failures.append("Lời cô Mai chưa chờ nhận diện lần lượt đủ 7 dây")

	for index in range(expected_notes.size()):
		var note_name := expected_notes[index]
		var expected_string_index := index + 10
		if int(lesson_scene.NOTE_TO_STRING.get(note_name, -1)) != expected_string_index:
			failures.append("Sai ánh xạ dây %d của nốt %s" % [expected_string_index + 1, note_name])
		if not is_equal_approx(float(lesson_scene.NOTE_FREQS.get(note_name, 0.0)), expected_frequencies[index]):
			failures.append("Sai tần số nhận diện của nốt %s" % note_name)

	if failures.is_empty():
		print("PASS: bài 6 nhận diện đúng 7 nốt trên dây 11 đến 17")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)
