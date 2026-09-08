extends SceneTree


func _init() -> void:
	var lesson_list = load("res://scripts/LessonDanTranhList.gd")
	var lesson_scene = load("res://scripts/LessonDanTranh.gd")
	var failures: Array[String] = []
	var lesson_4_2: Dictionary = {}
	for lesson_value in lesson_list.get_level_data(1).get("lessons", []):
		var lesson: Dictionary = lesson_value
		if str(lesson.get("display_number", "")) == "4.2":
			lesson_4_2 = lesson
			break

	var expected_notes: Array[String] = ["Sol2", "La2", "Đô3", "Rê3", "Mi3"]
	var actual_notes: Array[String] = []
	actual_notes.assign(lesson_4_2.get("sheet", []))
	if actual_notes != expected_notes:
		failures.append("Bài 4.2 phải thực hành đúng 5 nốt Sol2, La2, Đô3, Rê3, Mi3")
	var fingerings: Array = lesson_4_2.get("fingerings", [])
	if fingerings.size() != expected_notes.size():
		failures.append("Bài 4.2 phải có một số ngón cho mỗi nốt")
	for fingering in fingerings:
		if str(fingering) != "1":
			failures.append("Mỗi nốt bài 4.2 phải hiển thị ngón 1")
	if int(lesson_4_2.get("number", 0)) != 7:
		failures.append("ID tương thích của bài 4.2 đã bị thay đổi")
	var expected_frequencies := {
		"Sol2": 392.00,
		"La2": 440.00,
		"Đô3": 523.25,
		"Rê3": 587.33,
		"Mi3": 659.25
	}
	for note_name in expected_notes:
		var actual_frequency := float(lesson_scene.NOTE_FREQS.get(note_name, 0.0))
		if not is_equal_approx(actual_frequency, float(expected_frequencies[note_name])):
			failures.append("Sai tần số nhận diện %s" % note_name)
		var expected_string := expected_notes.find(note_name) + 5
		if int(lesson_scene.NOTE_TO_STRING.get(note_name, -1)) != expected_string:
			failures.append("Sai ánh xạ dây của %s" % note_name)

	if failures.is_empty():
		print("PASS: bài 4.2 gảy ngón 1 nhận diện đúng dây 6 đến 10")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)
