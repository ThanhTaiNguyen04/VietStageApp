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

	var no_generation := valid_sol_attack.duplicate()
	no_generation["generation"] = 0
	if lesson._is_vibrato_source_attack_valid(no_generation, "Sol2"):
		failures.append("Sai: lượt Rung được mở khi không có generation tiếng gảy hợp lệ")
	var no_confidence := valid_sol_attack.duplicate()
	no_confidence["confidence"] = 0.0
	if lesson._is_vibrato_source_attack_valid(no_confidence, "Sol2"):
		failures.append("Sai: lượt Rung được mở khi bộ lọc tiếng đàn có độ tin cậy bằng 0")
	var mismatched_name := valid_sol_attack.duplicate()
	mismatched_name["note_name"] = "La2"
	if lesson._is_vibrato_source_attack_valid(mismatched_name, "Sol2"):
		failures.append("Sai: tên nốt không khớp vẫn mở lượt Rung trên dây Sol2")

	for target_note in lesson.VIBRATO_NOTES:
		var target_identity := {
			"active": true,
			"string_index": int(lesson.NOTE_TO_STRING[target_note]),
			"note_name": target_note,
			"generation": 30,
			"confidence": 0.90
		}
		if not lesson._is_vibrato_source_attack_valid(target_identity, target_note):
			failures.append("Không mở được lượt Rung hợp lệ cho nốt %s" % target_note)

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
	var steady_pitch := _make_vibrato(0.0, 0.0, 5.0, 1.20)
	if lesson._analyze_vibrato_cents(steady_pitch).get("detected", false):
		failures.append("Sai: cao độ giữ nguyên vẫn được tính là kỹ thuật Rung")
	var too_slow := _make_vibrato(22.0, 20.0, 2.0, 1.50)
	if lesson._analyze_vibrato_cents(too_slow).get("detected", false):
		failures.append("Sai: dao động quá chậm vẫn được tính là kỹ thuật Rung")
	var too_fast := _make_vibrato(22.0, 20.0, 11.0, 1.20)
	if lesson._analyze_vibrato_cents(too_fast).get("detected", false):
		failures.append("Sai: dao động quá nhanh vẫn được tính là kỹ thuật Rung")
	var too_deep := _make_vibrato(80.0, 80.0, 5.0, 1.20)
	if lesson._analyze_vibrato_cents(too_deep).get("detected", false):
		failures.append("Sai: rung quá sâu vượt vùng cao độ đàn vẫn được chấp nhận")

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
