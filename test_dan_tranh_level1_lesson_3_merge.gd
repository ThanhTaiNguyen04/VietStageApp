extends SceneTree


func _init() -> void:
	var lesson_list = load("res://scripts/LessonDanTranhList.gd")
	var lesson_scene = load("res://scripts/LessonDanTranh.gd")
	var failures: Array[String] = []
	var level_1: Dictionary = lesson_list.get_level_data(1)
	var lesson_3: Dictionary = {}
	for lesson_value in level_1.get("lessons", []):
		var lesson: Dictionary = lesson_value
		var display_number := str(lesson.get("display_number", ""))
		if display_number == "3":
			lesson_3 = lesson
		elif display_number == "5.1":
			failures.append("Bài 5.1 vẫn còn trong danh sách Level 1")

	if lesson_3.is_empty():
		failures.append("Không tìm thấy bài 3 của Level 1")
	elif "âm vực" not in str(lesson_3.get("video", "")).to_lower():
		failures.append("Mô tả bài 3 chưa có lý thuyết âm vực")

	if "5.1" in str(level_1.get("sessions", "")):
		failures.append("Tổng quan Level 1 vẫn còn nhắc tới bài 5.1")

	var spoken_text := ""
	for step_value in lesson_scene.LESSON_DIALOGUES.get("dan_tranh_level_1_bai_4_practice", []):
		var step: Dictionary = step_value
		spoken_text += " " + str(step.get("text", ""))
	for required_text in ["Âm vực trầm", "dây 1 đến 5", "dây 6 đến 10", "dây 11 đến 17"]:
		if required_text not in spoken_text:
			failures.append("Lời cô Mai ở bài 3 thiếu nội dung: %s" % required_text)

	if failures.is_empty():
		print("PASS: lý thuyết âm vực đã nhập vào bài 3 và bài 5.1 đã được xóa")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)
