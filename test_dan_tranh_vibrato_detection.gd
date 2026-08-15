extends SceneTree


func _make_vibrato(center_cents: float, amplitude_cents: float, rate_hz: float, duration: float) -> Array[float]:
	var history: Array[float] = []
	var sample_count := int(duration / 0.025)
	for i in sample_count:
		var time := float(i) * 0.025
		history.append(center_cents + amplitude_cents * sin(TAU * rate_hz * time))
	return history


func _init() -> void:
	var lesson = load("res://scripts/LessonDanTranh.gd").new()
	var failures: Array[String] = []
	var valid_sol_attack := {
		"active": true,
		"string_index": 5,
		"note_name": "Sol2",
		"generation": 21,
		"confidence": 0.92
	}

	if not lesson._is_vibrato_source_attack_valid(valid_sol_attack, "Sol2"):
		failures.append("Không nhận tiếng gảy hợp lệ trên đúng dây Sol2")

	var wrong_string := valid_sol_attack.duplicate()
	wrong_string["string_index"] = 6
	if lesson._is_vibrato_source_attack_valid(wrong_string, "Sol2"):
		failures.append("Sai: cao độ Sol2 trên sai dây vẫn mở lượt Rung")

	var vocal_without_pluck := valid_sol_attack.duplicate()
	vocal_without_pluck["active"] = false
	if lesson._is_vibrato_source_attack_valid(vocal_without_pluck, "Sol2"):
		failures.append("Sai: giọng ngân không có onset đàn vẫn mở lượt Rung")

	if not lesson._is_vibrato_contour_session_valid(valid_sol_attack, "Sol2", 21):
		failures.append("Không theo dõi được đúng dây và đúng lần gảy ban đầu")
	if lesson._is_vibrato_contour_session_valid(valid_sol_attack, "Sol2", 20):
		failures.append("Sai: âm của lần khác được nối vào quá trình Rung")

	var string_vibrato := _make_vibrato(22.0, 20.0, 5.0, 1.20)
	var string_result: Dictionary = lesson._analyze_vibrato_cents(string_vibrato)
	if not string_result.get("detected", false):
		failures.append("Bỏ sót rung dây một phía, đều 5 Hz và kéo dài hơn 1 giây")

	var vocal_vibrato := _make_vibrato(0.0, 20.0, 5.0, 1.20)
	if lesson._analyze_vibrato_cents(vocal_vibrato).get("detected", false):
		failures.append("Sai: vocal vibrato đối xứng quanh nốt hát vẫn được tính là Rung dây")

	var too_short := _make_vibrato(22.0, 20.0, 5.0, 0.70)
	if lesson._analyze_vibrato_cents(too_short).get("detected", false):
		failures.append("Sai: rung chưa đủ thời gian vẫn được hoàn thành")

	if not lesson._is_vibrato_added_sound_level(-31.0, -40.0, 0.35):
		failures.append("Không phát hiện giọng hoặc âm mới chồng lên đuôi tiếng đàn")
	if lesson._is_vibrato_added_sound_level(-34.0, -40.0, 0.35):
		failures.append("Sai: dao động âm lượng nhỏ của dây đàn bị xem là giọng chồng")

	lesson.free()
	if failures.is_empty():
		print("PASS: Rung bắt buộc đúng tiếng gảy, cùng dây và loại vocal vibrato")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)
