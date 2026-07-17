extends SceneTree

func _init() -> void:
	SecureDataManager.active_lesson_id = "dan_tranh_level_1_bai_2_practice"
	InstrumentSelect.selected_instrument = "dan_tranh"
	PracticeRoom.current_song_title = ""
	PracticeRoom.current_song_sheet.clear()
	call_deferred("_run_check")

func _run_check() -> void:
	var scene := load("res://scenes/PracticeRoom.tscn") as PackedScene
	if scene == null:
		printerr("FAILED: PracticeRoom scene did not load")
		quit(1)
		return
	var instance := scene.instantiate()
	root.add_child(instance)
	await process_frame
	await process_frame
	await process_frame

	var board := instance.get_node_or_null("Root/StringsBoard/BoardM/BoardVBox/DanTranhBoard")
	var exercise_panel := instance.get_node_or_null("Root/Level1SequenceExercise")
	if board == null or int(board.call("get_display_string_count")) != 17:
		printerr("FAILED: lesson 2 did not show the complete 17-string board")
		quit(1)
		return
	if exercise_panel == null or exercise_panel.visible:
		printerr("FAILED: lesson 2 text panel remained visible")
		quit(1)
		return
	if instance.get_node("Root/TopBar").visible or instance.get_node("Root/MiddleRow").visible or instance.get_node("Root/RecordBar").visible:
		printerr("FAILED: lesson 2 navigation chrome remained visible")
		quit(1)
		return
	if instance.get_node_or_null("Lesson2PauseFAB") == null or instance.get_node_or_null("Lesson2SpeedBar") == null:
		printerr("FAILED: lesson 2 focus controls were not created")
		quit(1)
		return
	var initial_speed_bar := instance.get_node("Lesson2SpeedBar") as Control
	if initial_speed_bar.size.x < 108.0 or initial_speed_bar.size.y < 252.0:
		printerr("FAILED: lesson 2 speed bar is not large enough")
		quit(1)
		return
	var speed_rect := initial_speed_bar.get_global_rect()
	for string_index in range(17):
		var string_number_center: Vector2 = board.global_position + Vector2(float(board.call("get_str_l", string_index)) - 16.0, float(board.call("_row_cy", string_index)))
		var string_number_rect := Rect2(string_number_center - Vector2(11.0, 11.0), Vector2(22.0, 22.0))
		if speed_rect.intersects(string_number_rect):
			printerr("FAILED: speed bar overlaps a string-number circle")
			quit(1)
			return

	var speed_buttons: Array = instance.get("_level1_speed_buttons")
	if speed_buttons.size() != 4:
		printerr("FAILED: lesson 2 did not create four speed choices")
		quit(1)
		return
	var speed_values: Array[float] = []
	for button in speed_buttons:
		if button.icon != null or not button.text in ["60%", "80%", "100%", "120%"] or button.tooltip_text.is_empty():
			printerr("FAILED: lesson 2 speed controls must use text percentages without icons")
			quit(1)
			return
		speed_values.append(float(button.get_meta("speed_value", 0.0)))
	if speed_values != [0.6, 0.8, 1.0, 1.2]:
		printerr("FAILED: lesson 2 speed values are incorrect")
		quit(1)
		return
	var cues: Array = board.get("note_cues")
	var config: Dictionary = instance.get("_level1_config")
	var missing_indices: Array = config.get("missing_indices", [])
	var cue_count := 0
	for cue in cues:
		if not str(cue).is_empty():
			cue_count += 1
	if str(config.get("mode", "")) != "fill_melody" or cues.size() != 24 or missing_indices.size() != 6 or cue_count != 6:
		printerr("FAILED: lesson 2 melody finger cues were not loaded")
		quit(1)
		return
	board.current_note_idx = 3
	if bool(board.call("should_draw_scrolling_note", 0)) or not bool(board.call("should_draw_scrolling_note", 3)) or bool(board.call("should_draw_scrolling_note", 7)):
		printerr("FAILED: the board did not hide sample notes or limit display to one missing note")
		quit(1)
		return
	if float(board.get("note_spacing_pixels")) < 180.0 or float(board.get("note_marker_scale")) < 1.25:
		printerr("FAILED: lesson 2 notes are not enlarged and spaced farther apart")
		quit(1)
		return

	instance.set("_level1_state", "playing")
	instance.set("_level1_speed", 1.0)
	instance.set("_current_note_elapsed", 60.0 / 72.0 * 1.35 * 0.5)
	instance.call("_set_level1_speed", 0.6)
	var expected_elapsed := 60.0 / (72.0 * 0.6) * 1.35 * 0.5
	if absf(float(instance.get("_current_note_elapsed")) - expected_elapsed) > 0.001:
		printerr("FAILED: changing speed did not preserve melody position")
		quit(1)
		return
	instance.set("_note_idx", 0)
	instance.set("_current_note_elapsed", 0.0)
	instance.set("_level1_auto_note_played", false)
	instance.call("_process_level1_sequence", 0.01)
	var pluck_amplitudes: PackedFloat32Array = board.get("_pluck_amp")
	var note_statuses: Array = instance.get("note_statuses")
	if not bool(instance.get("_level1_auto_note_played")) or pluck_amplitudes.is_empty() or pluck_amplitudes[0] <= 0.0 or note_statuses[0] != "correct":
		printerr("FAILED: a supplied melody note was not played automatically")
		quit(1)
		return
	instance.set("_current_note_elapsed", float(instance.call("_get_level1_seconds_per_note", 0.6)))
	instance.call("_process_level1_fill_melody", 0.0)
	if int(instance.get("_note_idx")) != 1:
		printerr("FAILED: the automatic melody did not continue to the next note")
		quit(1)
		return

	instance.set("_note_idx", 3)
	instance.set("_current_note_elapsed", 0.0)
	instance.set("_level1_auto_note_played", false)
	instance.set("_level1_backing_guard", 0.0)
	instance.set("_level1_wait_for_silence", false)
	var visualizer := instance.get_node("Root/RecordBar/RecordM/RecordH/WaveformVisualizer")
	visualizer.current_amplitude_db = -20.0
	visualizer.current_pitch = float(instance.call("_get_string_frequency", 1))
	var lead_beats := float(board.call("get_note_entry_lead_beats"))
	instance.call("_process_level1_fill_melody", 0.0)
	if float(instance.get("_current_time_beats")) >= 3.0 or bool(instance.get("_level1_waiting_for_note")):
		printerr("FAILED: the missing note did not begin outside the right edge")
		quit(1)
		return
	instance.set("_current_note_elapsed", lead_beats * float(instance.call("_get_level1_seconds_per_note", 0.6)))
	instance.call("_process_level1_fill_melody", 0.0)
	if not bool(instance.get("_level1_waiting_for_note")):
		printerr("FAILED: the missing note did not stop at the yellow playhead")
		quit(1)
		return
	instance.call("_process_level1_fill_melody", 0.2)
	if int(instance.get("_note_idx")) != 4 or int(instance.get("_level1_correct_count")) != 1:
		printerr("FAILED: the melody did not wait for and accept the missing student note")
		quit(1)
		return
	if instance.get_node("Root/TopBar").visible:
		printerr("FAILED: playing a melody note restored the hidden navigation")
		quit(1)
		return

	instance.set("_note_idx", 3)
	instance.call("_update_level1_progress")
	var progress_bar := instance.get_node("Lesson2Progress").get_child(0).get_child(0) as ProgressBar
	if int(progress_bar.value) != 3:
		printerr("FAILED: lesson 2 progress did not follow the melody")
		quit(1)
		return
	root.size = Vector2i(720, 1280)
	await process_frame
	await process_frame
	var speed_bar := instance.get_node("Lesson2SpeedBar") as Control
	var progress_panel := instance.get_node("Lesson2Progress") as Control
	var pause_fab := instance.get_node("Lesson2PauseFAB") as Control
	if not bool(board.get("is_portrait_mode")):
		printerr("FAILED: lesson 2 did not switch the board to portrait layout")
		quit(1)
		return
	if pause_fab.get_global_rect().intersects(speed_bar.get_global_rect()) or speed_bar.get_global_rect().intersects(progress_panel.get_global_rect()):
		printerr("FAILED: lesson 2 portrait controls overlap each other")
		quit(1)
		return
	var speed_column := speed_bar.get_child(0)
	if not speed_column is VBoxContainer or speed_column.get_child_count() != 4:
		printerr("FAILED: lesson 2 speeds are not arranged as one vertical column")
		quit(1)
		return
	instance.call("_open_level2_pause")
	if str(instance.get("_level1_state")) != "paused" or not instance.get_node("Lesson2PauseOverlay").visible:
		printerr("FAILED: lesson 2 pause did not stop the melody")
		quit(1)
		return

	print("OK: lesson 2 plays a nearly complete 24-note melody and waits at six student notes")
	quit(0)
