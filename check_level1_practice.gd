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
	if panel == null:
		printerr("FAILED: Level 1 lesson panel was not created")
		quit(1)
		return
	var visualizer := instance.get_node_or_null("Root/RecordBar/RecordM/RecordH/WaveformVisualizer")
	if visualizer == null:
		printerr("FAILED: Audio analyzer was not created")
		quit(1)
		return
	instance.call("_toggle_record")
	visualizer.set("current_amplitude_db", -20.0)
	visualizer.set("current_pitch", instance.call("_get_string_frequency", 1))
	for frame in range(20):
		instance.call("_process_level1_lesson1_audio", 0.02)
	if int(instance.get("_note_idx")) != 0:
		printerr("FAILED: Wrong note advanced exercise")
		quit(1)
		return
	visualizer.set("current_amplitude_db", -80.0)
	visualizer.set("current_pitch", 0.0)
	for frame in range(3):
		instance.call("_process_level1_lesson1_audio", 0.05)
	for note_index in range(5):
		visualizer.set("current_amplitude_db", -20.0)
		visualizer.set("current_pitch", instance.call("_get_string_frequency", note_index))
		for frame in range(20):
			instance.call("_process_level1_lesson1_audio", 0.02)
		visualizer.set("current_amplitude_db", -80.0)
		visualizer.set("current_pitch", 0.0)
		for frame in range(3):
			instance.call("_process_level1_lesson1_audio", 0.05)
		if int(instance.get("_note_idx")) != note_index + 1:
			printerr("FAILED: Correct note did not advance exercise")
			quit(1)
			return
	print("OK: Wrong note was rejected and all five stable notes were accepted")
	quit(0)
