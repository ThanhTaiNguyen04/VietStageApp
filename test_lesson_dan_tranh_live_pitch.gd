extends SceneTree

const NOTES := [
	"Sol1", "La1", "Đô2", "Rê2", "Mi2",
	"Sol2", "La2", "Đô3", "Rê3", "Mi3",
	"Sol3", "La3", "Đô4", "Rê4", "Mi4", "Sol4", "La4",
]
const FREQUENCIES := [
	196.00, 220.00, 261.63, 293.66, 329.63,
	392.00, 440.00, 523.25, 587.33, 659.25,
	783.99, 880.00, 1046.50, 1174.66, 1318.51, 1567.98, 1760.00,
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://scenes/LessonDanTranh.tscn") as PackedScene
	var lesson := scene.instantiate()
	root.add_child(lesson)
	await process_frame
	var analyzer = lesson.get_node("Analyzer")
	var failures: Array[String] = []

	for index in FREQUENCIES.size():
		analyzer.current_amplitude_db = -40.0
		analyzer.current_pitch = FREQUENCIES[index]
		analyzer.current_pitch_is_reliable = true
		analyzer.instrument_gate_open = true
		lesson.time_correct = 0.0
		if not lesson._check_mic_pitch(FREQUENCIES[index], 0.20, NOTES[index]):
			failures.append("Không nhận dây %d %s" % [index + 1, NOTES[index]])

	# Same note name in another octave must never pass.
	analyzer.current_pitch = 196.0
	analyzer.instrument_gate_open = true
	lesson.time_correct = 0.0
	if lesson._check_mic_pitch(1567.98, 0.20, "Sol4"):
		failures.append("Sol1 bị nhận nhầm thành Sol4")

	# Every high string must reject the real string one octave below it.
	var high_start := 10
	for index in range(high_start, FREQUENCIES.size()):
		analyzer.current_amplitude_db = -40.0
		analyzer.current_pitch = FREQUENCIES[index] / 2.0
		analyzer.current_pitch_is_reliable = true
		analyzer.instrument_gate_open = true
		lesson.time_correct = 0.0
		if lesson._check_mic_pitch(FREQUENCIES[index], 0.20, NOTES[index]):
			failures.append("Nốt quãng tám thấp bị nhận nhầm thành %s" % NOTES[index])
	# A weak but usable high-string signal must pass the configured gate.
	analyzer.current_amplitude_db = -52.0
	analyzer.current_pitch = 1760.0
	analyzer.instrument_gate_open = true
	lesson.time_correct = 0.0
	if not lesson._check_mic_pitch(1760.0, 0.20, "La4"):
		failures.append("Âm La4 nhỏ hợp lệ bị ngưỡng micro loại")

	# Real practice feedback: silence and rejected audio stay neutral; only a
	# validated wrong attempt opens the 99+ visual feedback overlay.
	lesson.current_state = LessonDanTranh.State.PRACTICE
	lesson.current_lesson_id = "dan_tranh_level_2_bai_4_practice"
	lesson.active_falling_notes = [{
		"note": "ZT_La2",
		"x": lesson.staff_display.hit_line_x,
		"color": Color(0.6, 0.6, 0.6, 0.9),
		"hit": false,
		"missed": false
	}]
	analyzer.instrument_gate_open = false
	analyzer.current_amplitude_db = -80.0
	analyzer.current_pitch = 0.0
	lesson._update_continuous_pitch_hud(0.40)
	if lesson.error_feedback_showing:
		failures.append("Im lặng lại kích hoạt hiệu ứng báo sai")
	if lesson.pitch_status_lbl and "chờ" not in lesson.pitch_status_lbl.text.to_lower():
		failures.append("Im lặng không hiển thị trạng thái đang chờ gảy đàn")

	analyzer.current_amplitude_db = -30.0
	analyzer.current_pitch = 440.0
	lesson._update_continuous_pitch_hud(0.31)
	if lesson.error_feedback_showing:
		failures.append("Âm chưa qua bộ lọc lại kích hoạt hiệu ứng báo sai")
	if lesson.pitch_status_lbl and "chưa nghe rõ" not in lesson.pitch_status_lbl.text.to_lower():
		failures.append("Âm chưa nhận diện không hiển thị hướng dẫn gảy lại gần micro")

	lesson._show_practice_error_feedback("La2", "Cần gảy: La2", "Chưa đúng")
	if not lesson.error_feedback_showing:
		failures.append("Lỗi thực hành hợp lệ không mở hiệu ứng phản hồi 99+")
	if lesson.error_flash_note.is_empty() or str(lesson.error_flash_note.get("note", "")) != "ZT_La2":
		failures.append("Hiệu ứng báo sai không bám đúng nốt mục tiêu")

	if failures.is_empty():
		print("PASS: LessonDanTranh nhận đúng 17/17 nốt thật, không nhầm quãng tám")
		lesson.queue_free()
		await process_frame
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)
