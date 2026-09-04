extends SceneTree


func _init() -> void:
	var course_data = load("res://scripts/DanBauCourseData.gd")
	var failures: Array[String] = []
	var roadmap: Dictionary = course_data.get_roadmap_configuration()
	if str(roadmap.get("guide", "")).is_empty():
		failures.append("Thiếu tiêu đề lộ trình Đàn Bầu")
	for card_type in ["basic", "essentials", "soloist", "chords", "classical", "pop_chords"]:
		var status: Dictionary = course_data.get_card_status(card_type, {})
		if int(status.get("step_count", 0)) <= 0:
			failures.append("Không lấy được bài học cho thẻ %s" % card_type)
		if int(status.get("pct", -1)) != 0 or bool(status.get("completed", true)):
			failures.append("Tiến độ rỗng của thẻ %s không hợp lệ" % card_type)
	var selected_scene: String = course_data.select_level(4)
	if selected_scene != "res://scenes/LessonDanBau.tscn":
		failures.append("Điều hướng Đàn Bầu sai scene")
	if load("res://scripts/LessonDanBau.gd").selected_level != 4:
		failures.append("Không truyền được level Đàn Bầu")
	if failures.is_empty():
		print("PASS: dữ liệu, tiến độ và điều hướng Đàn Bầu đã tách khỏi MainMenu")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)
