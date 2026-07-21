extends SceneTree

func _init() -> void:
	SecureDataManager.active_lesson_id = "dan_tranh_level_1_bai_1_practice"
	InstrumentSelect.selected_instrument = "dan_tranh"
	PracticeRoom.current_song_title = "Làm quen 5 nốt cơ bản"
	PracticeRoom.current_song_sheet.assign(["Sol1", "La1", "Đô2", "Rê2", "Mi2"])
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
	var panel := instance.get_node_or_null("Root/Level1Lesson1Exercise")
	if panel == null or panel.visible:
		printerr("FAILED: text instruction panel was not hidden")
		quit(1)
		return
	var visualizer := instance.get_node_or_null("Root/RecordBar/RecordM/RecordH/WaveformVisualizer")
	if visualizer == null:
		printerr("FAILED: Audio analyzer was not created")
		quit(1)
		return
	var board := instance.get_node_or_null("Root/StringsBoard/BoardM/BoardVBox/DanTranhBoard")
	if board == null or int(board.call("get_lesson_marker_state", 0)) != 2:
		printerr("FAILED: first string did not show the active circle cue")
		quit(1)
		return
	if str(board.call("get_finger_shape", "1")) != "circle" or str(board.call("get_finger_shape", "2")) != "square" or str(board.call("get_finger_shape", "3")) != "triangle":
		printerr("FAILED: legacy numeric finger cues are not converted safely")
		quit(1)
		return
	if int(board.call("get_display_string_count")) != 17:
		printerr("FAILED: full-screen board did not retain all 17 strings")
		quit(1)
		return
	var compact_row_height := float(board.call("_row_h"))
	for display_row in range(17):
		var mapped_string := int(board.call("_row_at", 10.0 + (float(display_row) + 0.5) * compact_row_height))
		if mapped_string != display_row:
			printerr("FAILED: touch row did not map to its original string index")
			quit(1)
			return
	if instance.get_node("Root/TopBar").visible or instance.get_node("Root/MiddleRow").visible or instance.get_node("Root/RecordBar").visible:
		printerr("FAILED: navigation or instructional chrome remained visible")
		quit(1)
		return
	var pause_button := instance.get_node_or_null("Lesson1PauseFAB")
	var pause_overlay := instance.get_node_or_null("Lesson1PauseOverlay")
	if pause_button == null or pause_overlay == null or pause_overlay.visible:
		printerr("FAILED: minimal pause controls were not initialized")
		quit(1)
		return
	await process_frame
	if not bool(instance.get("_recording")) or int(instance.get("_lesson1_focus_state")) != 1:
		printerr("FAILED: microphone did not start after the headless voice guide")
		quit(1)
		return
	instance.call("_open_level1_pause")
	if bool(instance.get("_recording")) or int(instance.get("_lesson1_focus_state")) != 3 or not pause_overlay.visible:
		printerr("FAILED: pause did not stop listening and open its overlay")
		quit(1)
		return
	instance.call("_resume_level1_from_pause")
	if not bool(instance.get("_recording")) or int(instance.get("_lesson1_focus_state")) != 1 or pause_overlay.visible:
		printerr("FAILED: resume did not restore listening")
		quit(1)
		return
	visualizer.set("current_amplitude_db", -20.0)
	visualizer.set("current_pitch", instance.call("_get_string_frequency", 1))
	for frame in range(20):
		instance.call("_process_level1_lesson1_audio", 0.02)
	if int(instance.get("_note_idx")) != 0:
		printerr("FAILED: Wrong note advanced exercise")
		quit(1)
		return
	if int(board.call("get_lesson_marker_state", 0)) != 4:
		printerr("FAILED: wrong note did not turn the active marker red")
		quit(1)
		return
	await process_frame
	visualizer.set("current_amplitude_db", -80.0)
	visualizer.set("current_pitch", 0.0)
	for frame in range(3):
		instance.call("_process_level1_lesson1_audio", 0.05)
	for finger_round in range(3):
		if int(instance.get("_level1_finger_round")) != finger_round:
			printerr("FAILED: finger round did not advance")
			quit(1)
			return
		var expected_finger_names := ["ngón cái", "ngón trỏ", "ngón giữa"]
		var expected_shapes := ["circle", "square", "triangle"]
		var expected_shape_names := ["hình tròn", "hình vuông", "hình tam giác"]
		var expected_symbols := ["●", "■", "▲"]
		if str(instance.call("_level1_current_finger_name")) != expected_finger_names[finger_round]:
			printerr("FAILED: finger shape mapped to the wrong finger name")
			quit(1)
			return
		if str(instance.call("_level1_current_finger_shape")) != expected_shapes[finger_round] or str(instance.call("_level1_current_shape_name")) != expected_shape_names[finger_round]:
			printerr("FAILED: lesson 1 did not expose the expected geometric cue")
			quit(1)
			return
		if str(board.call("get_lesson_marker_label", 0)) != expected_shapes[finger_round]:
			printerr("FAILED: marker did not use the expected geometric cue")
			quit(1)
			return
		var round_label = instance.get("_level1_finger_round_label") as Label
		var note_buttons: Array = instance.get("_level1_note_buttons")
		var lesson_target = instance.get("target_label") as Label
		if round_label == null or expected_symbols[finger_round] not in round_label.text or expected_shape_names[finger_round].to_upper() not in round_label.text or "NÚT" in round_label.text:
			printerr("FAILED: round label still uses a numbered finger button")
			quit(1)
			return
		if note_buttons.is_empty() or not str(note_buttons[0].text).begins_with(expected_symbols[finger_round]):
			printerr("FAILED: note button does not show the current finger shape")
			quit(1)
			return
		if lesson_target == null or expected_symbols[finger_round] not in lesson_target.text or expected_shape_names[finger_round].capitalize() not in lesson_target.text:
			printerr("FAILED: target label does not explain shape and finger")
			quit(1)
			return
		for note_index in range(5):
			visualizer.set("current_amplitude_db", -20.0)
			visualizer.set("current_pitch", instance.call("_get_string_frequency", note_index))
			for frame in range(20):
				instance.call("_process_level1_lesson1_audio", 0.02)
			visualizer.set("current_amplitude_db", -80.0)
			visualizer.set("current_pitch", 0.0)
			for frame in range(3):
				instance.call("_process_level1_lesson1_audio", 0.05)
			if note_index < 4:
				if int(instance.get("_note_idx")) != note_index + 1:
					printerr("FAILED: correct note did not advance")
					quit(1)
					return
				if int(board.call("get_lesson_marker_state", note_index)) != 3:
					printerr("FAILED: completed marker did not turn blue")
					quit(1)
					return
				if int(board.call("get_lesson_marker_state", note_index + 1)) != 2:
					printerr("FAILED: next marker was not activated")
					quit(1)
					return
			elif finger_round < 2:
				if int(instance.get("_note_idx")) != 0 or int(instance.get("_level1_finger_round")) != finger_round + 1:
					printerr("FAILED: next finger round did not start at Sol")
					quit(1)
					return
				if str(board.call("get_lesson_marker_label", 0)) != expected_shapes[finger_round + 1]:
					printerr("FAILED: next round marker shape is wrong")
					quit(1)
					return
	for string_index in range(5):
		if int(board.call("get_lesson_marker_state", string_index)) != 3 or str(board.call("get_lesson_marker_label", string_index)) != "triangle":
			printerr("FAILED: final triangle cue did not remain blue")
			quit(1)
			return
	if int(instance.get("_lesson1_focus_state")) != 4:
		printerr("FAILED: exercise did not enter the completed state")
		quit(1)
		return
	root.size = Vector2i(720, 1280)
	await process_frame
	await process_frame
	if not bool(board.get("is_portrait_mode")) or int(board.call("get_display_string_count")) != 17:
		printerr("FAILED: portrait layout did not retain the 17-string board")
		quit(1)
		return
	var source := FileAccess.get_file_as_string("res://scripts/PracticeRoom.gd").to_lower()
	for forbidden_text in ["nút số", "số ngón", "ngón có số", "level1_finger_numbers"]:
		if forbidden_text in source:
			printerr("FAILED: obsolete numbered-finger wording remains: %s" % forbidden_text)
			quit(1)
			return
	print("OK: full-screen 17-string lesson completed circle, square and triangle finger cues")
	quit(0)
