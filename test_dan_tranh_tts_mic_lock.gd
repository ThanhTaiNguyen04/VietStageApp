extends SceneTree


func _init() -> void:
	var failures: Array[String] = []
	var analyzer = load("res://scripts/AudioCaptureAnalyzer.gd").new()
	analyzer.current_pitch = 440.0
	analyzer.current_pitch_is_reliable = true
	analyzer.current_amplitude_db = -12.0
	analyzer._analysis_buffer = PackedFloat32Array([0.5, -0.5])
	analyzer._rapid_attack_pending = true
	analyzer._dan_tranh_note_active = true
	analyzer.current_dan_tranh_note = {"note_name": "La2"}
	analyzer.set_analysis_suspended(true)

	if not analyzer.analysis_suspended:
		failures.append("Analyzer không chuyển sang trạng thái tạm dừng")
	if analyzer.current_pitch != 0.0 or analyzer.current_pitch_is_reliable:
		failures.append("Cao độ cũ chưa bị xóa khi cô Mai bắt đầu nói")
	if analyzer.current_amplitude_db > -79.0:
		failures.append("Biên độ cũ chưa bị xóa khi cô Mai bắt đầu nói")
	if not analyzer._analysis_buffer.is_empty() or analyzer._rapid_attack_pending:
		failures.append("Buffer hoặc lần gảy nhanh cũ chưa bị xóa")
	if analyzer._dan_tranh_note_active or not analyzer.current_dan_tranh_note.is_empty():
		failures.append("Nốt đang theo dõi chưa bị hủy khi khóa analyzer")

	analyzer.set_analysis_suspended(false)
	if analyzer.analysis_suspended:
		failures.append("Analyzer không mở lại sau thời gian chờ")

	var lesson = load("res://scripts/LessonDanTranh.gd").new()
	lesson.time_correct = 0.08
	lesson.wrong_note_time = 0.10
	lesson.glissando_detected_strings.assign([1, 2, 3])
	lesson.press_base_note_heard = true
	lesson.vibrato_base_note_heard = true
	lesson.tremolo_attack_times.assign([0.0, 0.1])
	lesson._set_micro_scoring_locked(true)
	if not lesson._is_micro_scoring_blocked():
		failures.append("Lesson vẫn cho phép chấm khi TTS bắt đầu")
	if lesson.time_correct != 0.0 or lesson.wrong_note_time != 0.0:
		failures.append("Bộ đếm nốt thường chưa được đặt lại")
	if not lesson.glissando_detected_strings.is_empty() or lesson.press_base_note_heard \
			or lesson.vibrato_base_note_heard or not lesson.tremolo_attack_times.is_empty():
		failures.append("Dữ liệu kỹ thuật trước TTS chưa được xóa")
	lesson._set_micro_scoring_locked(false)
	if lesson._is_micro_scoring_blocked():
		failures.append("Lesson vẫn khóa chấm sau khi mở lại")

	lesson.free()
	analyzer.free()
	if failures.is_empty():
		print("PASS: TTS khóa analyzer, xóa âm cũ và chỉ mở lại sau cooldown")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)
