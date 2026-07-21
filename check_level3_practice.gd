extends SceneTree

func _init() -> void:
	SecureDataManager.active_lesson_id = "dan_tranh_level_1_bai_3_practice"
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

	var board := instance.get_node_or_null("Root/StringsBoard/BoardM/BoardVBox/DanTranhBoard")
	var config: Dictionary = instance.get("_level1_config")
	var notes: Array = instance.get("sheet_notes")
	var durations: Array = instance.get("sheet_durations")
	var missing: Array = config.get("missing_indices", [])
	var cues: Array = config.get("cues", [])
	if board == null or int(board.call("get_display_string_count")) != 17:
		_fail("lesson 3 did not show all 17 strings")
		return
	if str(config.get("mode", "")) != "phrase_accompaniment" or notes.size() != 78 or durations.size() != 78:
		_fail("Sứ Thanh Hoa sheet or durations were not loaded (mode=%s, notes=%d, durations=%d)" % [str(config.get("mode", "")), notes.size(), durations.size()])
		return
	if missing != [11, 25, 36, 46, 60, 77]:
		_fail("phrase-ending student positions are incorrect")
		return
	var expected_cue_beats: Array[float] = [6.0, 15.5, 22.0, 29.0, 39.5, 48.0]
	for i in missing.size():
		var actual_beat := float(instance.call("_get_level1_note_start_beat", int(missing[i])))
		if not is_equal_approx(actual_beat, expected_cue_beats[i]):
			_fail("student cue %d is off the authored melody timeline: %.2f" % [i + 1, actual_beat])
			return
	var actual_cues: Array[String] = []
	for index in missing:
		actual_cues.append(str(cues[int(index)]))
	if actual_cues != ["circle", "square", "triangle", "circle", "square", "triangle"]:
		_fail("lesson 3 finger cues do not rotate circle-square-triangle")
		return
	if instance.get_node("Root/TopBar").visible or instance.get_node("Root/MiddleRow").visible or instance.get_node("Root/RecordBar").visible:
		_fail("lesson 3 navigation chrome remained visible")
		return
	if instance.get_node_or_null("Lesson3PauseFAB") == null or instance.get_node_or_null("Lesson3SpeedBar") == null or instance.get_node_or_null("Lesson3Progress") == null:
		_fail("lesson 3 focus controls were not created")
		return
	var pause_overlay := instance.get_node("Lesson3PauseOverlay") as ColorRect
	var pause_card := pause_overlay.find_child("PauseCard", true, false) as PanelContainer
	var pause_actions := pause_overlay.find_child("Actions", true, false) as GridContainer
	if pause_card == null or pause_actions == null or pause_overlay.color.get_luminance() < 0.8:
		_fail("pause navigation did not use the light mobile card design")
		return
	if pause_card.custom_minimum_size.x < 248.0 or pause_card.custom_minimum_size.x > 320.0 or pause_actions.get_child_count() != 4:
		_fail("pause navigation width or action count is not mobile-safe")
		return
	for action in pause_actions.get_children():
		var action_button := action as Button
		if action_button == null or action_button.custom_minimum_size.y < 72.0:
			_fail("pause navigation contains a touch target smaller than 72 pixels")
			return
		if not action_button.text.is_empty() or action_button.icon == null or action_button.tooltip_text.is_empty():
			_fail("pause navigation is not icon-only or lacks an accessible tooltip")
			return
	var speed_buttons: Array = instance.get("_level1_speed_buttons")
	var speed_values: Array[float] = []
	for button in speed_buttons:
		if button.icon != null or not button.text in ["60%", "80%", "100%", "120%"] or button.tooltip_text.is_empty():
			_fail("lesson 3 speed controls must use text percentages without icons")
			return
		speed_values.append(float(button.get_meta("speed_value", 0.0)))
	if speed_values != [0.6, 0.8, 1.0, 1.2]:
		_fail("lesson 3 speed controls are incorrect")
		return

	board.current_note_idx = 11
	if bool(board.call("should_draw_scrolling_note", 0)) or not bool(board.call("should_draw_scrolling_note", 11)) or not bool(board.call("should_draw_scrolling_note", 25)):
		_fail("non-cued melody notes were visible or upcoming student cues were hidden")
		return

	var native_available := bool(instance.get("_native_audio_available"))
	if native_available:
		var native_engine := instance.get_node_or_null("DanTranhAudioEngine")
		var native_analyzer: Variant = instance.get_node("Root/RecordBar/RecordM/RecordH/WaveformVisualizer").get("_analyzer")
		if native_engine == null or int(native_engine.call("get_sample_count")) != 17:
			_fail("native sample engine did not receive all 17 streams")
			return
		if native_analyzer == null:
			_fail("real-time microphone analysis did not use the C++ AudioAnalyzer")
			return
		if not bool(native_engine.call("play_sample", 5, -80.0, 1.0)):
			_fail("native engine could not play a configured sample")
			return
		native_engine.call("stop_all")
	else:
		if str(instance.get("_level1_state")) == "paused" or instance.get_node("Lesson3PauseOverlay").visible:
			_fail("lesson 3 was blocked when the optional C++ extension was unavailable")
			return
		if not bool(instance.call("_play_native_level3_sample", 5)):
			_fail("GDScript sample fallback could not play a configured sample")
			return
		instance.call("_stop_native_level3_audio")

	# Rest advances with its authored duration and never requests a native sample.
	instance.set("_level1_state", "playing")
	instance.set("_note_idx", 33)
	instance.set("_current_note_elapsed", 0.0)
	instance.set("_level1_auto_note_played", false)
	instance.call("_process_level1_phrase_accompaniment", 0.0)
	var statuses: Array = instance.get("note_statuses")
	if not bool(instance.get("_level1_auto_note_played")) or statuses[33] != "correct":
		_fail("Rest was not handled as a silent authored step")
		return
	var rest_seconds := float(instance.call("_get_level1_current_step_seconds", 1.0))
	instance.set("_current_note_elapsed", rest_seconds)
	instance.call("_process_level1_phrase_accompaniment", 0.0)
	if int(instance.get("_note_idx")) != 34:
		_fail("Rest did not advance according to its duration")
		return

	# A phrase-ending cue reaches the playhead on its authored melody beat.
	instance.set("_note_idx", 11)
	instance.set("_current_note_elapsed", 0.0)
	instance.set("_level1_waiting_for_note", false)
	instance.set("_level1_backing_guard", 0.0)
	instance.set("_level1_wait_for_silence", false)
	instance.call("_set_level1_target")
	var cue_start := float(instance.call("_get_level1_note_start_beat", 11))
	instance.call("_process_level1_phrase_accompaniment", 0.0)
	if not bool(instance.get("_level1_waiting_for_note")) or not is_equal_approx(float(instance.get("_current_time_beats")), cue_start):
		_fail("student cue did not reach the yellow playhead on its authored beat")
		return
	var visualizer := instance.get_node("Root/RecordBar/RecordM/RecordH/WaveformVisualizer")
	visualizer.current_amplitude_db = -20.0
	visualizer.current_pitch = float(instance.call("_get_string_frequency", 5))
	instance.call("_process_level1_phrase_accompaniment", 0.2)
	if int(instance.get("_note_idx")) != 12 or int(instance.get("_level1_correct_count")) != 1 or not is_equal_approx(float(instance.get("_current_note_elapsed")), -1.5) or not is_equal_approx(float(instance.get("_current_time_beats")), cue_start):
		_fail("real-time pitch did not preserve the student note duration before resuming")
		return

	instance.call("_update_level1_progress")
	var progress_bar := instance.get_node("Lesson3Progress").get_child(0).get_child(0) as ProgressBar
	if int(progress_bar.max_value) != 6 or int(progress_bar.value) != 1:
		_fail("lesson 3 progress does not count only student notes")
		return

	# Wrong notes continue the melody; only the sixth wrong note restarts it.
	instance.set("_note_idx", 25)
	instance.set("_level1_state", "playing")
	instance.set("_level1_waiting_for_note", true)
	instance.set("_level1_wait_for_silence", false)
	instance.set("_level1_wrong_count", 0)
	instance.set("_level1_total_attempts", 0)
	visualizer.current_amplitude_db = -20.0
	visualizer.current_pitch = float(instance.call("_get_string_frequency", 6))
	instance.call("_process_level1_guided_song_audio", 0.2)
	if int(instance.get("_note_idx")) != 26 or int(instance.get("_level1_wrong_count")) != 1:
		_fail("lesson 3 did not continue after a wrong student note")
		return
	instance.set("_note_idx", 77)
	instance.set("_level1_state", "playing")
	instance.set("_level1_waiting_for_note", true)
	instance.set("_level1_wait_for_silence", false)
	instance.set("_level1_wrong_count", 5)
	visualizer.current_amplitude_db = -20.0
	visualizer.current_pitch = float(instance.call("_get_string_frequency", 6))
	instance.call("_process_level1_guided_song_audio", 0.2)
	if str(instance.get("_level1_state")) != "countdown" or int(instance.get("_note_idx")) != 0 or int(instance.get("_level1_wrong_count")) != 0:
		_fail("lesson 3 did not restart from the beginning after the sixth wrong note")
		return

	root.size = Vector2i(720, 1280)
	await process_frame
	await process_frame
	var speed_bar := instance.get_node("Lesson3SpeedBar") as Control
	var progress_panel := instance.get_node("Lesson3Progress") as Control
	var pause_fab := instance.get_node("Lesson3PauseFAB") as Control
	if not bool(board.get("is_portrait_mode")):
		_fail("lesson 3 did not switch the 17-string board to portrait layout")
		return
	if pause_fab.get_global_rect().intersects(speed_bar.get_global_rect()) or speed_bar.get_global_rect().intersects(progress_panel.get_global_rect()):
		_fail("lesson 3 portrait controls overlap")
		return

	statuses = instance.get("note_statuses")
	for completed_index in [11, 25, 36, 46, 60]:
		statuses[completed_index] = "correct"
	statuses[77] = "unplayed"
	instance.set("note_statuses", statuses)
	instance.set("_note_idx", 77)
	instance.set("_level1_correct_count", 5)
	instance.set("_level1_total_attempts", 5)
	instance.set("_level1_state", "playing")
	instance.call("_register_level1_correct", "✓ Rê · Hoàn thành")
	if str(instance.get("_level1_state")) != "result" or int(instance.get("_level1_correct_count")) != 6:
		_fail("lesson 3 did not complete after all six student notes")
		return

	print("OK: lesson 3 uses Sứ Thanh Hoa, six phrase cues and an audio fallback when GDExtension is absent")
	quit(0)
