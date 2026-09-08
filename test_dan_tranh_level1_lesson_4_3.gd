extends SceneTree


func _init() -> void:
	var lesson_list = load("res://scripts/LessonDanTranhList.gd")
	var lesson_scene = load("res://scripts/LessonDanTranh.gd")
	var failures: Array[String] = []
	var lesson_4_3: Dictionary = {}
	for lesson_value in lesson_list.get_level_data(1).get("lessons", []):
		var lesson: Dictionary = lesson_value
		if str(lesson.get("display_number", "")) == "4.3":
			lesson_4_3 = lesson
			break

	var expected_notes: Array[String] = ["Sol3", "La3", "Đô4", "Rê4", "Mi4", "Sol4", "La4"]
	var actual_notes: Array[String] = []
	actual_notes.assign(lesson_4_3.get("sheet", []))
	if actual_notes != expected_notes:
		failures.append("Bài 4.3 phải thực hành đúng 7 nốt Sol3 đến La4")
	var fingerings: Array = lesson_4_3.get("fingerings", [])
	if fingerings.size() != expected_notes.size():
		failures.append("Bài 4.3 phải có một số ngón cho mỗi nốt")
	for fingering in fingerings:
		if str(fingering) != "3":
			failures.append("Mỗi nốt bài 4.3 phải hiển thị ngón 3")
	if int(lesson_4_3.get("number", 0)) != 9:
		failures.append("ID tương thích của bài 4.3 đã bị thay đổi")
	var expected_frequencies := {
		"Sol3": 783.99,
		"La3": 880.00,
		"Đô4": 1046.50,
		"Rê4": 1174.66,
		"Mi4": 1318.51,
		"Sol4": 1567.98,
		"La4": 1760.00
	}
	for note_name in expected_notes:
		var actual_frequency := float(lesson_scene.NOTE_FREQS.get(note_name, 0.0))
		if not is_equal_approx(actual_frequency, float(expected_frequencies[note_name])):
			failures.append("Sai tần số nhận diện %s" % note_name)
		var expected_string := expected_notes.find(note_name) + 10
		if int(lesson_scene.NOTE_TO_STRING.get(note_name, -1)) != expected_string:
			failures.append("Sai ánh xạ dây của %s" % note_name)

	if failures.is_empty():
		print("PASS: bài 4.3 gảy ngón 3 nhận diện đúng dây 11 đến 17")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)
