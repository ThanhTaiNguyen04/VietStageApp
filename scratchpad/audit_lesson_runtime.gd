extends Node

class PitchJumpCapture extends AudioCaptureAnalyzer:
	func _capture_samples() -> PackedFloat32Array:
		return PackedFloat32Array([0.2, -0.2, 0.2, -0.2])
	func _detect_onset(_samples: PackedFloat32Array) -> bool:
		return false
	func _update_instrument_sound_gate(_samples: PackedFloat32Array, _is_onset: bool, _delta: float) -> void:
		instrument_gate_open = true
	func _estimate_pitch(_samples: PackedFloat32Array) -> float:
		return 329.63

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
	get_tree().root.add_child(lesson)
	lesson.set_process(false)
	await get_tree().process_frame
	var analyzer = lesson.get_node("Analyzer")
	analyzer.set_process(false)
	var failures: Array[String] = []
	var jump := PitchJumpCapture.new()
	jump.pitch_profile = analyzer.pitch_profile
	jump._analyzer = ClassDB.instantiate("AudioAnalyzer")
	jump._effect = AudioEffectCapture.new()
	jump.onset_detected = true
	jump.current_pitch = 196.0
	jump.current_pitch_is_reliable = true
	jump._pitch_candidates.assign([196.0, 196.0])
	jump._process(0.016)
	if jump.pitch_estimation_done or jump.current_pitch_is_reliable:
		failures.append("Cao độ mới chưa ổn định nhưng bị chốt theo khung trước")
	jump._process(0.016)
	if not jump.current_pitch_is_reliable or not jump.pitch_estimation_done:
		failures.append("Không nhận lại Mi2 sau khi cao độ tiếng gảy ổn định")
	jump.free()

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
	analyzer._instrument_gate_generation = 5
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

	# Correct pitch must actually complete the waiting note and move its successor.
	lesson.ai_audio.tts_started.emit()
	if not lesson._is_micro_scoring_blocked():
		failures.append("TTS không khóa chấm trong lesson")
	lesson.ai_audio.stop_speech()
	if not lesson._is_micro_scoring_blocked():
		failures.append("Micro mở trước cooldown sau khi dừng TTS")
	await get_tree().create_timer(lesson.TTS_MIC_RESUME_DELAY_SEC + 0.05).timeout
	if lesson._is_micro_scoring_blocked():
		failures.append("Micro không mở sau cooldown khi dừng TTS")
	lesson.ai_audio.queue_free()
	lesson.ai_audio = null
	lesson._tts_resume_token += 1
	lesson._set_micro_scoring_locked(false)
	lesson.error_feedback_showing = false
	lesson.mic_cooldown = 0.0
	lesson.wrong_note_cooldown = 0.0
	lesson.time_correct = 0.0
	var hit_x: float = lesson.staff_display.hit_line_x
	lesson.active_falling_notes = [
		{"note": "ZT_Sol1", "target_string": 0, "x": hit_x, "is_missing": true, "hit": false, "color": Color.GRAY},
		{"note": "ZT_La1", "target_string": 1, "x": hit_x + 350.0, "is_missing": true, "hit": false, "color": Color.GRAY}
	]
	analyzer.instrument_gate_open = true
	analyzer.current_pitch = 196.0
	analyzer.current_pitch_is_reliable = true
	analyzer.current_amplitude_db = -40.0
	lesson._process_practice(0.016)
	if lesson.active_falling_notes[0].hit:
		failures.append("Nốt hoàn tất trước thời gian xác nhận")
	lesson._process_practice(0.016)
	if not lesson.active_falling_notes[0].hit:
		failures.append("Đúng nốt Sol1 nhưng không đánh dấu hoàn tất")
	lesson._process_practice(0.016)
	if lesson.active_falling_notes[1].x >= hit_x + 350.0:
		failures.append("Nốt tiếp theo không tiến sau khi Sol1 hoàn tất")
	if lesson.active_falling_notes[1].hit:
		failures.append("Tiếng Sol1 hoàn tất nhầm nốt La1 kế tiếp")
	lesson.active_falling_notes[1].x = hit_x
	lesson.mic_cooldown = 0.0
	lesson._process_practice(0.20)
	if lesson.error_feedback_showing:
		failures.append("Tiếng ngân Sol1 đã hoàn tất lại báo sai La1")
	analyzer._instrument_gate_generation = 6
	analyzer.current_pitch = 220.0
	lesson._process_practice(0.032)
	if not lesson.active_falling_notes[1].hit:
		failures.append("Lần gảy La1 mới không hoàn tất nốt kế tiếp")
	lesson.active_falling_notes = [{"note": "ZT_Sol1", "target_string": 0, "x": hit_x, "is_missing": true, "hit": false, "color": Color.GRAY}]
	lesson.mic_cooldown = 0.0
	lesson.wrong_note_cooldown = 0.0
	lesson.wrong_note_time = 0.0
	analyzer._instrument_gate_generation = 7
	lesson._process_practice(0.032)
	if lesson.error_feedback_showing:
		failures.append("Âm sai thoáng qua 32 ms đã báo lỗi ở bài nhập môn")
	lesson._process_practice(0.20)
	if not lesson.error_feedback_showing:
		failures.append("Âm sai rõ ràng quá 180 ms không được phản hồi")
	# Upper-octave Sol2 must not pass lower physical string Sol1.
	analyzer.current_pitch = 392.0
	if lesson._is_pitch_match_robust(196.0, "Sol1", 392.0):
		failures.append("Dây Sol2 bị nhận nhầm thành Sol1")
	var relaxed_pitch := 196.0 * pow(2.0, 75.0 / 1200.0)
	if not lesson._is_pitch_match_robust(196.0, "Sol1", relaxed_pitch):
		failures.append("Nhập môn không chấp nhận sai số 75 cents")
	if lesson._is_pitch_match_robust(196.0, "Sol1", 196.0 * pow(2.0, 90.0 / 1200.0)):
		failures.append("Nhập môn chấp nhận sai số ngoài 80 cents")
	if lesson._is_pitch_match_robust(196.0, "Sol1", 220.0):
		failures.append("Nhập môn nhận nhầm La1 thành Sol1")
	lesson.current_lesson_id = "dan_tranh_level_3_bai_10_practice"
	if lesson._is_pitch_match_robust(196.0, "Sol1", relaxed_pitch):
		failures.append("Ngưỡng của Level 3 bị nới theo nhập môn")
	lesson.current_lesson_id = "dan_tranh_level_2_bai_4_practice"
	if lesson._wrong_note_confirmation_sec() != 0.18:
		failures.append("Nhập môn không có thời gian xác nhận báo sai 0.18 giây")
	analyzer.current_pitch = 313.6
	if not lesson._is_pitch_match_robust(329.63, "Mi2", 313.6):
		failures.append("Mi2 thật lệch khoảng -86 cents chưa được chấp nhận ở nhập môn")
	for wrong_frequency in [293.66, 349.23, 659.25]:
		analyzer.current_pitch = wrong_frequency
		if lesson._is_pitch_match_robust(329.63, "Mi2", wrong_frequency):
			failures.append("Mi2 chấp nhận nhầm Rê2/Fa2/quãng tám: %s" % wrong_frequency)
	lesson.current_lesson_id = "dan_tranh_level_3_bai_10_practice"
	analyzer.current_pitch = 313.6
	if lesson._is_pitch_match_robust(329.63, "Mi2", 313.6):
		failures.append("Biên Mi2 nhập môn làm nới nhầm Level 3")

	if failures.is_empty():
		print("PASS: 17 synthetic pitches, octave rejection, TTS cooldown, confirmation and next-note movement")
		lesson.queue_free()
		await get_tree().process_frame
		get_tree().quit(0)
	else:
		for failure in failures:
			printerr(failure)
		get_tree().quit(1)
