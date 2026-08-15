extends SceneTree


func _init() -> void:
	var lesson = load("res://scripts/LessonDanTranh.gd").new()
	var failures: Array[String] = []
	var valid_mi_attack := {
		"active": true,
		"string_index": 4,
		"note_name": "Mi2",
		"generation": 12,
		"confidence": 0.91
	}

	if not lesson._is_press_source_attack_valid(valid_mi_attack, "Mi2"):
		failures.append("Không nhận lần gảy đúng dây Mi2 trước khi nhấn")

	var wrong_string := valid_mi_attack.duplicate()
	wrong_string["string_index"] = 5
	if lesson._is_press_source_attack_valid(wrong_string, "Mi2"):
		failures.append("Sai: cao độ Mi2 trên sai dây vẫn được mở lượt Nhấn")

	var vocal_without_pluck := valid_mi_attack.duplicate()
	vocal_without_pluck["active"] = false
	if lesson._is_press_source_attack_valid(vocal_without_pluck, "Mi2"):
		failures.append("Sai: giọng hát không có onset tiếng đàn vẫn được mở lượt Nhấn")

	if not lesson._is_press_contour_session_valid(valid_mi_attack, "Mi2", 12):
		failures.append("Không giữ được lượt Nhấn thuộc đúng lần gảy ban đầu")
	if lesson._is_press_contour_session_valid(valid_mi_attack, "Mi2", 11):
		failures.append("Sai: đường cao độ của lần âm khác được nối vào lần gảy cũ")
	if lesson._is_press_added_sound_level(-31.0, -40.0, 0.35) != true:
		failures.append("Không phát hiện âm giọng mới tăng lên trên đuôi tiếng đàn")
	if lesson._is_press_added_sound_level(-34.0, -40.0, 0.35):
		failures.append("Sai: dao động âm lượng nhỏ của dây đàn bị xem là giọng chồng")
	if lesson._is_press_added_sound_level(-25.0, -40.0, 0.05):
		failures.append("Sai: chính đỉnh tấn công ban đầu bị xem là âm giọng chồng")

	var smooth_press: Array[float] = [
		0.0, 1.0, 5.0, 13.0, 25.0, 40.0, 56.0, 72.0,
		86.0, 96.0, 100.0, 101.0, 100.0, 99.0, 100.0, 100.0
	]
	var smooth_result: Dictionary = lesson._analyze_press_contour(smooth_press, 100.0)
	if not smooth_result.get("detected", false):
		failures.append("Bỏ sót đường Nhấn Mi2 lên Fa2 mượt và giữ đủ lâu")

	var late_glide: Array[float] = [
		0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
		0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
		0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
		0.0, 0.0, 0.0, 0.0, 0.0, 10.0, 25.0, 45.0, 65.0, 85.0,
		98.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0
	]
	if lesson._analyze_press_contour(late_glide, 100.0).get("detected", false):
		failures.append("Sai: âm ngân lâu rồi mới luyến vẫn được tính là Nhấn")

	lesson.free()
	if failures.is_empty():
		print("PASS: Nhấn bắt buộc đúng dây, đúng lần gảy và đường cao độ liên tục")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)
