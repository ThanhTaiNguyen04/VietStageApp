extends SceneTree


func _init() -> void:
	var contract = load("res://scripts/DanTranhApiCourseContract.gd")
	var failures: Array[String] = []
	if contract.is_remote_content_enabled():
		failures.append("Không được bật API content khi giáo trình cứng chưa ổn định")
	for test_case in [
		[{"levelCode": "BEGINNER"}, 1],
		[{"levelCode": "INTERMEDIATE"}, 2],
		[{"levelCode": "ADVANCED"}, 7]
	]:
		if contract.skill_level_to_local_level(test_case[0]) != test_case[1]:
			failures.append("Ánh xạ skill level không đúng")
	var lessons := [
		{"status": "HIDDEN", "orderIndex": 1},
		{"status": "PUBLISHED", "orderIndex": 3},
		{"status": "ACTIVE", "orderIndex": 2}
	]
	var visible: Array[Dictionary] = contract.visible_lessons(lessons)
	if visible.size() != 2 or int(visible[0]["orderIndex"]) != 2:
		failures.append("Lọc hoặc sắp xếp bài hiển thị không đúng")
	var content := contract.decode_lesson_content({
		"content_text": JSON.stringify({"schema_version": 1, "blocks": [{"type": "TEACHER_SPEECH", "text": "Xin chào"}]})
	})
	if not contract.validate_content_document(content).is_empty():
		failures.append("Contract lời cô Mai không hợp lệ")
	if failures.is_empty():
		print("PASS: contract API Đàn Tranh đã sẵn sàng nhưng chưa bật runtime")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)
