extends SceneTree


func _init() -> void:
	var lesson_list = load("res://scripts/LessonDanTranhList.gd")
	var failures: Array[String] = []
	var lesson_4_1: Dictionary = {}
	for lesson_value in lesson_list.get_level_data(1).get("lessons", []):
		var lesson: Dictionary = lesson_value
		if str(lesson.get("display_number", "")) == "4.1":
			lesson_4_1 = lesson
			break

	var notes: Array = lesson_4_1.get("sheet", [])
	var fingerings: Array = lesson_4_1.get("fingerings", [])
	if notes.size() != 5 or fingerings.size() != notes.size():
		failures.append("Bài 4.1 phải có một số ngón cho mỗi nốt")
	for fingering in fingerings:
		if str(fingering) != "2":
			failures.append("Mọi nốt của bài 4.1 phải hiển thị ngón 2")

	if failures.is_empty():
		print("PASS: bài 4.1 hiển thị số 2 dưới cả 5 nốt")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)
