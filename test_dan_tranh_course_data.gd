extends SceneTree


func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var course_data = load("res://scripts/DanTranhCourseData.gd")
	var failures: Array[String] = []
	_check_completion_contract(failures)
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


func _check_completion_contract(failures: Array[String]) -> void:
	var secure = load("res://scripts/SecureDataManager.gd")
	var original_data: Dictionary = secure.data.duplicate(true)
	var original_catalog: Array = secure.be_catalog.duplicate(true)
	var original_instruments: Array = secure.be_instruments.duplicate(true)
	var instrument := {"id": 1, "instrumentCode": "INS-ĐÀ-205", "name": "Đàn Tranh"}
	secure.be_catalog = [
		{"id": 61, "lessonCode": "dan_tranh_level_7_bai_18_practice", "orderIndex": 1, "instrument": instrument},
		{"id": 50, "lessonCode": "dan_tranh_level_1_bai_1_video", "orderIndex": 1, "instrument": instrument},
		{"id": 51, "lessonCode": "dan_tranh_level_1_bai_5_practice", "orderIndex": 2, "instrument": instrument},
		{"id": 4, "lessonCode": "LESSON_SAO_10", "orderIndex": 10, "instrument": {"name": "Sáo", "instrumentCode": "INS-SÁ-241"}},
	]
	for pair: Array in [["dan_tranh_level_1_bai_1_practice", 50], ["dan_tranh_level_1_bai_5_practice", 51], ["dan_tranh_level_7_bai_18_practice", 61]]:
		if int(secure.resolve_be_lesson_exact("dan_tranh", pair[0]).get("id", 0)) != pair[1]:
			failures.append("Sai ánh xạ lessonCode: " + str(pair[0]))
	if int(secure.resolve_be_lesson_exact("sao_truc", "sao_truc_level1_1_video").get("id", 0)) != 4:
		failures.append("Sai ánh xạ video giới thiệu Sáo")
	if not secure.resolve_be_lesson_exact("sao_truc", "Node2").is_empty():
		failures.append("Không được đoán ID cho bài chưa có trên server")
	var resolved: Dictionary = secure.resolve_backend_progress_item({"lessonId": 50, "lessonCode": "dan_tranh_level_1_bai_1_video", "instrumentCode": "INS-ĐÀ-205", "orderIndex": 1})
	if resolved.get("node_id") != "dan_tranh_level_1_bai_1_video":
		failures.append("Tiến độ API phải dùng cùng ID với danh sách bài")
	secure.data["completed_lessons"] = {"dan_tranh": [], "sao_truc": []}
	secure.data["stars"] = {"dan_tranh": {}, "sao_truc": {}}
	secure.data["backend_course_access_loaded"] = false
	for email: String in ["phuclong2710@gmail.com", "thanhdattb19@gmail.com"]:
		secure.data["user_email"] = email
		for inst: String in ["dan_tranh", "sao_truc"]:
			if not secure.is_lesson_unlocked(inst, "any_lesson"):
				failures.append("Tài khoản kiểm thử phải mở hết bài: " + email)
		if secure.is_lesson_completed("dan_tranh", "dan_tranh_level_1_bai_1_video"):
			failures.append("Mở khóa không được tự hoàn thành bài")
	secure.data["completed_lessons"]["dan_tranh"] = ["dan_tranh_level_1_bai_1_practice"]
	secure.data["stars"]["dan_tranh"] = {"dan_tranh_level_1_bai_1_practice": 3}
	var stats: Dictionary = load("res://scripts/DanTranhCourseData.gd").get_level_status(1, secure.data)
	if stats.completed_count != 1 or stats.stars != 3 or stats.completed or stats.step_count != 11:
		failures.append("Một bài chỉ tính một lần; hoàn thành bài 1 chưa hoàn thành level 1")
	secure.data = original_data
	secure.be_catalog = original_catalog
	secure.be_instruments = original_instruments
