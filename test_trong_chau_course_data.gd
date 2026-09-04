extends SceneTree


func _init() -> void:
	var course_data = load("res://scripts/TrongChauCourseData.gd")
	var failures: Array[String] = []
	var roadmap: Dictionary = course_data.get_roadmap_configuration()
	if str(roadmap.get("guide", "")).is_empty():
		failures.append("Thiếu tiêu đề lộ trình Trống Chầu")
	var basic: Dictionary = course_data.get_card_status("basic", {})
	var essentials: Dictionary = course_data.get_card_status("essentials", {})
	if int(basic.get("step_count", 0)) != 2:
		failures.append("Thẻ nhập môn phải gồm video và thực hành bài 1")
	if int(essentials.get("step_count", 0)) != 4:
		failures.append("Thẻ nâng cao phải gồm video và thực hành bài 2-3")
	var completed_data := {
		"completed_lessons": {"trong_chau": ["trong_chau_coban_1_video", "trong_chau_coban_1_practice"]},
		"stars": {"trong_chau": {"trong_chau_coban_1_video": 2, "trong_chau_coban_1_practice": 3}}
	}
	var completed_basic: Dictionary = course_data.get_card_status("basic", completed_data)
	if not completed_basic.get("completed", false) or int(completed_basic.get("pct", 0)) != 100:
		failures.append("Không tính đúng hoàn thành Trống Chầu")
	if int(completed_basic.get("stars", 0)) != 5:
		failures.append("Không cộng đúng sao Trống Chầu")
	if course_data.get_lesson_scene() != "res://scenes/LessonTrongChau.tscn":
		failures.append("Điều hướng Trống Chầu sai scene")
	if failures.is_empty():
		print("PASS: dữ liệu, tiến độ và điều hướng Trống Chầu đã tách khỏi MainMenu")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)
