extends SceneTree

func _init() -> void:
	SecureDataManager.active_lesson_id = "dan_tranh_level_2_bai_4_practice"
	InstrumentSelect.selected_instrument = "dan_tranh"
	PracticeRoom.current_song_title = ""
	PracticeRoom.current_song_sheet.clear()
	call_deferred("_run_check")

func _fail(message: String) -> void:
	printerr("FAILED: " + message)
	quit(1)

func _run_check() -> void:
	var scene := load("res://scenes/PracticeRoom.tscn") as PackedScene
	if scene == null:
		_fail("PracticeRoom scene did not load")
		return
	var instance := scene.instantiate()
	root.add_child(instance)
	for _i in 5:
		await process_frame

	var config: Dictionary = instance.get("_level1_config")
	var notes: Array = instance.get("sheet_notes")
	var durations: Array = instance.get("sheet_durations")
	var cues: Array = config.get("cues", [])
	var board := instance.get_node_or_null("Root/StringsBoard/BoardM/BoardVBox/DanTranhBoard")
	if str(config.get("mode", "")) != "wait_sequence" or float(config.get("bpm", 0.0)) != 60.0:
		_fail("lesson 4 mode or BPM is incorrect")
		return
	var expected_notes := [
		"Mi1", "Sol2", "Sol2", "Mi1", "Sol2", "Sol2",
		"La2", "Đô2", "La2", "Đô2", "La2", "Sol2", "Sol2"
	]
	var expected_durations := [
		0.5, 0.5, 1.0, 0.5, 0.5, 1.0,
		0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0
	]
	var expected_cues := [
		"circle", "square", "triangle", "circle", "square", "triangle", "circle", "square",
		"circle", "square", "triangle", "circle", "square"
	]
	if notes != expected_notes or durations != expected_durations or cues != expected_cues:
		_fail("lesson 4 melody, pitch or duration does not match the score")
		return
	var expected_starts := [0.0, 0.5, 1.0, 2.0, 2.5, 3.0, 4.0, 4.5, 5.0, 5.5, 6.0, 6.5, 7.0]
	for note_index in expected_starts.size():
		if not is_equal_approx(float(instance.call("_get_level1_note_start_beat", note_index)), expected_starts[note_index]):
			_fail("note %d is not placed on the correct 2/4 timeline" % (note_index + 1))
			return
	if board == null or int(board.call("get_display_string_count")) != 17:
		_fail("lesson 4 did not keep all 17 strings visible")
		return
	if not bool(board.get("show_note_duration_glyphs")) or str(board.call("get_note_duration_glyph", 0)) != "♪" or str(board.call("get_note_duration_glyph", 2)) != "♩":
		_fail("lesson 4 does not visually distinguish eighth and quarter notes")
		return
	if str(board.call("get_finger_shape", cues[0])) != "circle" or str(board.call("get_finger_shape", cues[1])) != "square" or str(board.call("get_finger_shape", cues[2])) != "triangle":
		_fail("lesson 4 still uses finger numbers instead of geometric shapes")
		return
	var score_legend := instance.get_node("Root/StringsBoard/BoardM/BoardVBox/BoardLabel") as Label
	if not score_legend.visible or "NHỊP 2/4" not in score_legend.text or "1/2 PHÁCH" not in score_legend.text:
		_fail("lesson 4 score legend is incomplete (visible=%s, text=%s)" % [str(score_legend.visible), score_legend.text])
		return
	var label_overrides: Dictionary = board.get("note_label_overrides")
	if str(label_overrides.get(4, "")) != "Mi·E4" or str(label_overrides.get(5, "")) != "Sol·G4" or str(label_overrides.get(6, "")) != "La·A4" or str(label_overrides.get(7, "")) != "Đố·C5":
		_fail("lesson 4 does not label the four authored pitches explicitly")
		return
	if instance.get_node_or_null("Lesson4PauseFAB") == null or instance.get_node_or_null("Lesson4SpeedBar") == null or instance.get_node_or_null("Lesson4Progress") == null:
		_fail("lesson 4 focus controls were not created")
		return
	var optional_samples := ["G3.wav", "A3.wav", "C4.wav", "D4.wav", "E4.wav", "G4.wav", "A4.wav", "C5.wav"]
	for i in 17:
		var expected_source := "synth"
		if i < optional_samples.size() and ResourceLoader.exists("res://assets/audio/dan_tranh_cc0/%s" % optional_samples[i]):
			expected_source = "cc0"
		if str(instance.call("get_string_stream_source", i)) != expected_source:
			_fail("string %d did not choose the expected recorded/synth source" % i)
			return

	# Demo playback is isolated from exercise metrics and restores the paused cue.
	instance.set("_level1_state", "paused")
	instance.set("_note_idx", 7)
	instance.set("_current_note_elapsed", 0.4)
	instance.set("_current_time_beats", 7.5)
	instance.set("_level1_waiting_for_note", true)
	instance.set("_level1_correct_count", 4)
	instance.set("_level1_wrong_count", 2)
	instance.call("_start_level4_demo")
	if str(instance.get("_level1_state")) != "demo_playback" or bool(instance.get("_recording")):
		_fail("sample demo did not enter an isolated non-recording state")
		return
	instance.call("_process_level4_demo", 0.1)
	var amplitudes: PackedFloat32Array = board.get("_pluck_amp")
	if amplitudes[4] <= 0.0:
		_fail("sample demo did not play and animate its first note")
		return
	instance.call("_finish_level4_demo")
	if str(instance.get("_level1_state")) != "paused" or int(instance.get("_note_idx")) != 7:
		_fail("sample demo did not restore the paused exercise position")
		return
	if int(instance.get("_level1_correct_count")) != 4 or int(instance.get("_level1_wrong_count")) != 2:
		_fail("sample demo changed exercise metrics")
		return

	var visualizer := instance.get_node("Root/RecordBar/RecordM/RecordH/WaveformVisualizer")
	# A correct note advances once and waits for silence before accepting another onset.
	instance.set("_level1_state", "playing")
	instance.set("_note_idx", 0)
	instance.set("_level1_waiting_for_note", true)
	instance.set("_level1_wait_for_silence", false)
	instance.set("_level1_correct_count", 0)
	instance.set("_level1_wrong_count", 0)
	instance.set("_level1_total_attempts", 0)
	visualizer.current_amplitude_db = -20.0
	visualizer.current_pitch = float(instance.call("_get_string_frequency", 4))
	instance.call("_process_level1_guided_song_audio", 0.2)
	if int(instance.get("_note_idx")) != 1 or int(instance.get("_level1_correct_count")) != 1:
		_fail("correct first note did not advance the wait sequence")
		return
	instance.call("_process_level1_guided_song_audio", 0.2)
	if int(instance.get("_note_idx")) != 1:
		_fail("one sustained onset was accepted for two notes")
		return

	# Wrong notes also advance; the sixth wrong note restarts the whole exercise.
	instance.set("_note_idx", 1)
	instance.set("_level1_state", "playing")
	instance.set("_level1_waiting_for_note", true)
	instance.set("_level1_wait_for_silence", false)
	instance.set("_level1_wrong_count", 0)
	visualizer.current_pitch = float(instance.call("_get_string_frequency", 2))
	instance.call("_process_level1_guided_song_audio", 0.2)
	if int(instance.get("_note_idx")) != 2 or int(instance.get("_level1_wrong_count")) != 1:
		_fail("wrong note did not advance and increment the error count")
		return
	instance.set("_note_idx", 10)
	instance.set("_level1_state", "playing")
	instance.set("_level1_waiting_for_note", true)
	instance.set("_level1_wait_for_silence", false)
	instance.set("_level1_wrong_count", 5)
	visualizer.current_pitch = float(instance.call("_get_string_frequency", 5))
	instance.call("_process_level1_guided_song_audio", 0.2)
	if str(instance.get("_level1_state")) != "countdown" or int(instance.get("_note_idx")) != 0 or int(instance.get("_level1_wrong_count")) != 0:
		_fail("sixth wrong note did not restart the lesson")
		return

	root.size = Vector2i(720, 1280)
	await process_frame
	await process_frame
	if not bool(board.get("is_portrait_mode")):
		_fail("lesson 4 did not adapt its 17-string board to portrait mode")
		return
	var pause_fab := instance.get_node("Lesson4PauseFAB") as Control
	var speed_bar := instance.get_node("Lesson4SpeedBar") as Control
	var progress_panel := instance.get_node("Lesson4Progress") as Control
	if pause_fab.get_global_rect().intersects(speed_bar.get_global_rect()) or speed_bar.get_global_rect().intersects(progress_panel.get_global_rect()):
		_fail("lesson 4 portrait controls overlap")
		return

	# Completing the 13th attempted note produces a passing result and records it.
	var statuses: Array = instance.get("note_statuses")
	for completed_index in range(12):
		statuses[completed_index] = "correct"
	statuses[12] = "unplayed"
	instance.set("note_statuses", statuses)
	instance.set("_note_idx", 12)
	instance.set("_level1_state", "playing")
	instance.set("_level1_waiting_for_note", true)
	instance.set("_level1_wait_for_silence", false)
	instance.set("_level1_correct_count", 12)
	instance.set("_level1_wrong_count", 0)
	instance.set("_level1_total_attempts", 12)
	visualizer.current_amplitude_db = -20.0
	visualizer.current_pitch = float(instance.call("_get_string_frequency", 5))
	instance.call("_process_level1_guided_song_audio", 0.2)
	if str(instance.get("_level1_state")) != "result" or int(instance.get("_level1_correct_count")) != 13:
		_fail("lesson 4 did not complete after all 13 attempted notes")
		return

	print("OK: level 2 lesson 4 matches the 13-note 2/4 score, pitch labels, durations and sample demo")
	quit(0)
