extends SceneTree


func _init() -> void:
	var course_data = load("res://scripts/SaoTrucCourseData.gd")
	var failures: Array[String] = []
	var roadmap: Dictionary = course_data.get_roadmap_configuration()
	if str(roadmap.get("guide", "")).is_empty():
		failures.append("Thiếu tiêu đề lộ trình Sáo Trúc")
	var expected_counts := {
		"basic": 1, "essentials": 8, "soloist": 2,
		"chords": 2, "classical": 2, "pop_chords": 2
	}
	for card_type in expected_counts:
		var status: Dictionary = course_data.get_card_status(card_type, {})
		if int(status.get("step_count", 0)) != int(expected_counts[card_type]):
			failures.append("Ánh xạ tiến độ thẻ %s đã thay đổi" % card_type)
		if int(status.get("pct", -1)) != 0 or bool(status.get("completed", true)):
			failures.append("Tiến độ rỗng của thẻ %s không hợp lệ" % card_type)
	for level_number in [2, 3, 4, 5, 6]:
		var scene: String = course_data.select_level(level_number)
		if scene != "res://scenes/LessonSaoTrucList.tscn":
			failures.append("Điều hướng level %d sai scene" % level_number)
		if load("res://scripts/LessonSaoTrucList.gd").selected_level != level_number:
			failures.append("Không truyền được level %d" % level_number)
	var intro_data := {}
	course_data.configure_intro(intro_data)
	if intro_data.get("custom_video_sequence", []) != course_data.INTRO_VIDEO_SEQUENCE:
		failures.append("Chuỗi video nhập môn đã thay đổi")
	if int(intro_data.get("current_sequence_index", -1)) != 0:
		failures.append("Vị trí bắt đầu chuỗi video không đúng")
	if failures.is_empty():
		print("PASS: lộ trình, tiến độ và điều hướng Sáo Trúc được giữ nguyên")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)
