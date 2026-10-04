extends Node

# Replace only the microphone source; run the production _process pipeline.
class RecordingCapture extends AudioCaptureAnalyzer:
	var recording := PackedFloat32Array()
	var cursor := 0
	var frame_size := 735

	func _capture_samples() -> PackedFloat32Array:
		var chunk := recording.slice(cursor, mini(cursor + frame_size, recording.size()))
		cursor += chunk.size()
		_analysis_buffer.append_array(chunk)
		if _analysis_buffer.size() > INSTRUMENT_ATTACK_ANALYSIS_SAMPLES:
			_analysis_buffer = _analysis_buffer.slice(-INSTRUMENT_ATTACK_ANALYSIS_SAMPLES)
		return chunk

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var lesson = load("res://scenes/LessonDanTranh.tscn").instantiate()
	get_tree().root.add_child(lesson)
	lesson.set_process(false)
	lesson.analyzer.set_process(false)
	var profile = lesson.analyzer.pitch_profile
	lesson.ai_audio.stop_speech()
	lesson.ai_audio.queue_free()
	lesson.ai_audio = null
	lesson._tts_resume_token += 1
	lesson._set_micro_scoring_locked(false)
	lesson.current_state = lesson.State.PRACTICE
	# Preserve the 65-cent regression; optional beginner mode verifies relaxation.
	var beginner := "--beginner" in OS.get_cmdline_user_args()
	var finger2_final := "--finger2-final" in OS.get_cmdline_user_args()
	beginner = beginner or finger2_final
	lesson.current_lesson_id = "dan_tranh_level_1_bai_8_practice" if beginner else "dan_tranh_level_3_bai_10_practice"
	var failures: Array[String] = []
	var tested_count := 0
	var expected_pass := [1, 2, 3, 4, 6, 8, 9, 17]
	if beginner:
		expected_pass.append(5)
	print("Audio mix rate: ", AudioServer.get_mix_rate())
	for index in range(1, 18):
		if finger2_final and index != 5:
			continue
		if beginner and index > 6:
			continue
		var path := "res://test_fixtures/dan_tranh_user_recordings/string_%d.wav" % index
		if not FileAccess.file_exists(path):
			continue
		tested_count += 1
		var wav := AudioStreamWAV.load_from_file(path)
		var bytes := wav.data
		var source := PackedFloat32Array()
		for i in range(0, bytes.size(), 2):
			source.append(float(bytes.decode_s16(i)) / 32768.0)
		var capture := RecordingCapture.new()
		if "--slow-frames" in OS.get_cmdline_user_args():
			capture.frame_size = 2205
		capture._analyzer = null if "--fallback" in OS.get_cmdline_user_args() else ClassDB.instantiate("AudioAnalyzer")
		capture._effect = AudioEffectCapture.new()
		capture.pitch_profile = profile
		capture.min_frequency = profile.min_frequency
		capture.max_frequency = profile.max_frequency
		capture.volume_threshold_db = profile.volume_threshold_db
		var ratio: float = float(wav.mix_rate) / AudioServer.get_mix_rate()
		capture.recording.resize(int(source.size() / ratio))
		for i in capture.recording.size():
			var pos := float(i) * ratio
			var left := mini(int(pos), source.size() - 1)
			capture.recording[i] = lerpf(source[left], source[mini(left + 1, source.size() - 1)], pos - float(left))
		lesson.analyzer = capture
		lesson.time_correct = 0.0
		lesson._last_completed_beginner_attack = -1
		if finger2_final:
			capture._instrument_gate_generation = 4
			lesson._last_completed_beginner_attack = 4
		lesson.mic_cooldown = 0.0
		lesson.wrong_note_cooldown = 0.0
		var note_name: String = lesson.ALL_17_NOTES[index - 1]
		lesson.active_falling_notes = [{"note": "ZT_" + note_name, "target_string": index - 1, "x": lesson.staff_display.hit_line_x, "is_missing": true, "hit": false, "color": Color.GRAY}]
		if finger2_final:
			var entry: Dictionary = {}
			for candidate in load("res://scripts/LessonDanTranhList.gd").get_level_data(1).lessons:
				if candidate.number == 8:
					entry = candidate
			lesson.lesson_sheet.assign(entry.sheet)
			lesson.lesson_durations.assign(entry.durations)
			lesson.current_song_fingerings.assign(entry.fingerings)
			# Reproduce an already-open lesson retaining its old half-note Mi2.
			lesson.lesson_durations[4] = 2.0
			capture.calibration_succeeded = true
			await lesson._start_practice()
			for previous_index in range(4):
				lesson.active_falling_notes[previous_index].hit = true
				lesson.active_falling_notes[previous_index].x = lesson.staff_display.hit_line_x - 100.0
			lesson.active_falling_notes[4].x = lesson.staff_display.hit_line_x
			if float(entry.durations[4]) != 1.0:
				failures.append("Mi2 cuối bài ngón 2 không có trường độ nốt đen")
			if str(lesson.active_falling_notes[4].get("type", "")) != "quarter":
				failures.append("Khuông nhạc thực hành không tạo nốt đen cho Mi2 cuối")
		var target_note: Dictionary = lesson.active_falling_notes.back()
		var seen: Dictionary = {}
		var gate_frames := 0
		var passed := false
		while capture.cursor < capture.recording.size():
			capture._process(float(capture.frame_size) / AudioServer.get_mix_rate())
			if capture.instrument_gate_open:
				gate_frames += 1
			if capture.current_pitch_is_reliable:
				var detected: Dictionary = profile.match_pitch(capture.current_pitch)
				seen[str(detected.get("note_name", "None"))] = snappedf(capture.current_pitch, 0.1)
			if not passed:
				lesson._process_practice(float(capture.frame_size) / AudioServer.get_mix_rate())
				passed = bool(target_note.hit)
			if "--trace" in OS.get_cmdline_user_args() and (capture.current_pitch > 0.0 or capture.instrument_gate_open):
				print("TRACE t=", snappedf(capture.cursor / AudioServer.get_mix_rate(), 0.01), " pitch=", snappedf(capture.current_pitch, 0.1), " gate=", capture.instrument_gate_open, " gen=", capture._instrument_gate_generation, " used=", lesson._last_completed_beginner_attack, " wrong_cd=", lesson.wrong_note_cooldown, " mic_cd=", lesson.mic_cooldown, " hold=", lesson.time_correct, " passed=", passed)
		print("Dây ", index, " target=", note_name, " passed=", passed, " gate_frames=", gate_frames, " pitches=", seen, " reject=", capture._instrument_last_rejection_reason)
		if passed != (index in expected_pass):
			failures.append("Dây %d: expected=%s actual=%s" % [index, index in expected_pass, passed])
		capture.free()
	lesson.analyzer = null
	lesson.queue_free()
	for failure in failures:
		printerr(failure)
	if failures.is_empty():
		print("PASS: %d real recordings through production capture pipeline and lesson pitch constraints" % tested_count)
	get_tree().quit(0 if failures.is_empty() else 1)
