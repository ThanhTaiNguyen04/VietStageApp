extends SceneTree

const DO2 := 261.63
const MI2 := 329.63


func _init() -> void:
	var lesson = load("res://scripts/LessonDanTranh.gd").new()
	var target := PackedStringArray(["Đô2", "Mi2"])
	var failures: Array[String] = []

	var both_notes := func(frequency: float) -> float:
		if absf(frequency - DO2) < 1.0 or absf(frequency - MI2) < 1.0:
			return -30.0
		return -80.0
	var only_do := func(frequency: float) -> float:
		return -30.0 if absf(frequency - DO2) < 1.0 else -80.0
	var only_mi := func(frequency: float) -> float:
		return -30.0 if absf(frequency - MI2) < 1.0 else -80.0
	var weak_second_note := func(frequency: float) -> float:
		if absf(frequency - DO2) < 1.0:
			return -30.0
		if absf(frequency - MI2) < 1.0:
			return -60.0
		return -80.0

	if not lesson._are_all_chord_fundamentals_present(target, both_notes):
		failures.append("Không nhận khi đủ cả Đô2 và Mi2")
	if lesson._are_all_chord_fundamentals_present(target, only_do):
		failures.append("Sai: chỉ Đô2 vẫn được tính đúng")
	if lesson._are_all_chord_fundamentals_present(target, only_mi):
		failures.append("Sai: chỉ Mi2 vẫn được tính đúng")
	if lesson._are_all_chord_fundamentals_present(target, weak_second_note):
		failures.append("Sai: nốt thứ hai dưới ngưỡng vẫn được tính đúng")
	if lesson._are_all_chord_fundamentals_present(PackedStringArray(["Đô2"]), both_notes):
		failures.append("Sai: bộ nhận song thanh chấp nhận mục tiêu một nốt")

	lesson.current_lesson_id = "dan_tranh_level_7_bai_20_practice"
	if not lesson._should_score_song_thanh_component("Đô2+Mi2", 0):
		failures.append("Sai: thành phần đầu của nhóm Song thanh không được chấm")
	if lesson._should_score_song_thanh_component("Đô2+Mi2", 1):
		failures.append("Sai: thành phần thứ hai làm bộ đếm tăng hai lần mỗi frame")

	lesson.time_correct = 0.0
	for _frame in 6:
		if lesson._advance_song_thanh_confirmation(true, 0.016):
			failures.append("Sai: Song thanh hoàn thành trước 0,10 giây")
	if not lesson._advance_song_thanh_confirmation(true, 0.016):
		failures.append("Không hoàn thành sau khi đủ hơn 0,10 giây liên tục")

	lesson.time_correct = 0.0
	for _frame in 4:
		lesson._advance_song_thanh_confirmation(true, 0.016)
	lesson._advance_song_thanh_confirmation(false, 0.016)
	for _frame in 3:
		if lesson._advance_song_thanh_confirmation(true, 0.016):
			failures.append("Sai: thời gian trước khi mất một nốt vẫn bị cộng dồn")
	if lesson.time_correct > 0.049:
		failures.append("Bộ đếm Song thanh không đặt lại khi thiếu một nốt")

	lesson.free()
	if failures.is_empty():
		print("PASS: Song thanh chỉ đúng khi đủ hai tần số đồng thời")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)
