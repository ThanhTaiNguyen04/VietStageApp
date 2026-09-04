extends SceneTree


func _init() -> void:
	var course_data = load("res://scripts/DanTranhCourseData.gd")
	var failures: Array[String] = []
	var roadmap: Dictionary = course_data.get_roadmap_configuration()
	var levels: Dictionary = roadmap.get("levels", {})
	for level_number in [1, 2, 7]:
		if not levels.has(level_number):
			failures.append("Thiếu cấu hình roadmap Đàn Tranh level %d" % level_number)
			continue
		if str(levels[level_number].get("title", "")).is_empty():
			failures.append("Level %d thiếu tiêu đề" % level_number)
		if str(levels[level_number].get("description", "")).is_empty():
			failures.append("Level %d thiếu mô tả" % level_number)

	var empty_status: Dictionary = course_data.get_level_status(1, {})
	if int(empty_status.get("pct", -1)) != 0 or int(empty_status.get("stars", -1)) != 0:
		failures.append("Tiến độ rỗng phải bằng 0")
	if bool(empty_status.get("completed", true)):
		failures.append("Level chưa học không được đánh dấu hoàn thành")
	if int(empty_status.get("step_count", 0)) <= 0:
		failures.append("Không lấy được danh sách hoạt động của level 1")

	var selected_scene: String = course_data.select_level(2)
	if selected_scene != "res://scenes/LessonDanTranhList.tscn":
		failures.append("Điều hướng Đàn Tranh không trỏ tới scene danh sách bài")
	if load("res://scripts/LessonDanTranhList.gd").selected_level != 2:
		failures.append("Module không truyền level được chọn sang danh sách bài")

	if failures.is_empty():
		print("PASS: dữ liệu, tiến độ và điều hướng Đàn Tranh đã tách khỏi MainMenu")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)
