extends SceneTree


func _init() -> void:
	var lesson_list = load("res://scripts/LessonDanTranhList.gd")
	var lesson_scene = load("res://scripts/LessonDanTranh.gd")
	var failures: Array[String] = []
	var lesson_4_1: Dictionary = {}
	for lesson_value in lesson_list.get_level_data(1).get("lessons", []):
		var lesson: Dictionary = lesson_value
		if str(lesson.get("display_number", "")) == "4.1":
			lesson_4_1 = lesson
			break

	var expected_notes: Array[String] = ["Sol1", "La1", "Đô2", "Rê2", "Mi2"]
	var actual_notes: Array[String] = []
	actual_notes.assign(lesson_4_1.get("sheet", []))
	if actual_notes != expected_notes:
		failures.append("Bài 4.1 phải thực hành đúng 5 nốt Sol1, La1, Đô2, Rê2, Mi2")
	if int(lesson_4_1.get("number", 0)) != 8:
		failures.append("ID tương thích của bài 4.1 đã bị thay đổi")
	var expected_frequencies := {
		"Sol1": 196.00,
		"La1": 220.00,
		"Đô2": 261.63,
		"Rê2": 293.66,
		"Mi2": 329.63
	}
	for note_name in expected_notes:
		var actual_frequency := float(lesson_scene.NOTE_FREQS.get(note_name, 0.0))
		if not is_equal_approx(actual_frequency, float(expected_frequencies[note_name])):
			failures.append("Sai tần số nhận diện %s" % note_name)
		var expected_string := expected_notes.find(note_name)
		if int(lesson_scene.NOTE_TO_STRING.get(note_name, -1)) != expected_string:
			failures.append("Sai ánh xạ dây của %s" % note_name)

	if failures.is_empty():
		print("PASS: bài 4.1 gảy ngón 2 nhận diện đúng 5 dây đầu")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)
