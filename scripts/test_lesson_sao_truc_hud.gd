extends SceneTree
## Automated test verifying LessonSaoTruc HUD synchronization with Dan Tranh.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("--- Running LessonSaoTruc HUD Synchronization Test ---")

	var scene_res = load("res://scenes/LessonSaoTruc.tscn") as PackedScene
	assert(scene_res != null, "Failed to load LessonSaoTruc.tscn")

	var node = scene_res.instantiate()
	assert(node != null, "Failed to instantiate LessonSaoTruc.tscn")
	get_root().add_child(node)
	await process_frame
	await process_frame

	# 1. Verify practice_hud is instantiated and added as child
	var practice_hud = node.practice_hud
	assert(practice_hud != null, "practice_hud should be instantiated in LessonSaoTruc")
	assert(practice_hud is PracticeControlHud, "practice_hud should be an instance of PracticeControlHud")
	print("  [PASS] practice_hud instantiated correctly")

	# 2. Verify legacy buttons are hidden
	var legacy_back = node.get_node_or_null("BackBtn") as Button
	if legacy_back:
		assert(not legacy_back.visible, "Legacy BackBtn must be hidden")
		print("  [PASS] Legacy BackBtn is hidden")

	var legacy_bpm = node.bpm_controls_row
	if legacy_bpm:
		assert(not legacy_bpm.visible, "Legacy bpm_controls_row must be hidden")
		print("  [PASS] Legacy bpm_controls_row is hidden")

	# 3. Verify PracticeHud controls exist
	var hud_back = practice_hud.find_child("PracticeHudBack", true, false) as Button
	assert(hud_back != null, "PracticeHudBack button missing")
	print("  [PASS] PracticeHudBack button exists")

	var hud_pause = practice_hud.find_child("PracticeHudPause", true, false) as Button
	assert(hud_pause != null, "PracticeHudPause button missing")
	print("  [PASS] PracticeHudPause button exists")

	var hud_speed = practice_hud.find_child("PracticeHudSpeed", true, false)
	assert(hud_speed != null, "PracticeHudSpeed panel missing")
	print("  [PASS] PracticeHudSpeed panel exists")

	for label in ["Speed60", "Speed80", "Speed100", "Speed120"]:
		var btn = practice_hud.find_child(label, true, false) as Button
		assert(btn != null, "Speed button %s missing" % label)
	print("  [PASS] All 4 speed buttons exist (60%, 80%, 100%, 120%)")

	# 4. Verify speed selection alters bpm_multiplier
	var speed_120 = practice_hud.find_child("Speed120", true, false) as Button
	speed_120.pressed.emit()
	assert(is_equal_approx(node.bpm_multiplier, 1.2), "bpm_multiplier should be 1.2 after selecting Speed120")
	var speed_80 = practice_hud.find_child("Speed80", true, false) as Button
	speed_80.pressed.emit()
	assert(is_equal_approx(node.bpm_multiplier, 0.8), "bpm_multiplier should be 0.8 after selecting Speed80")
	print("  [PASS] Speed buttons update bpm_multiplier accurately")

	# 5. Verify Pause toggles state and displays pause overlay
	hud_pause.pressed.emit()
	assert(node.is_paused == true, "Lesson should be paused when pause button is pressed")
	var overlay = practice_hud.find_child("PracticeHudPauseOverlay", true, false) as Control
	assert(overlay != null and overlay.visible, "PracticeHudPauseOverlay must be visible when paused")
	print("  [PASS] Pause button pauses playback and reveals pause overlay")

	# 6. Verify Resume from pause overlay
	var resume_btn = practice_hud.find_child("Tiếp tục", true, false) as Button
	assert(resume_btn != null, "Resume button missing from pause overlay")
	resume_btn.pressed.emit()
	assert(node.is_paused == false, "Lesson should resume when Tiếp tục is pressed")
	assert(not overlay.visible, "Pause overlay should hide on resume")
	print("  [PASS] Resume button unpauses playback and hides overlay")

	# 7. Verify Restart from pause overlay
	hud_pause.pressed.emit()
	assert(node.is_paused == true)
	var restart_btn = practice_hud.find_child("Chơi lại", true, false) as Button
	assert(restart_btn != null, "Restart button missing from pause overlay")
	restart_btn.pressed.emit()
	assert(node.is_paused == false, "Lesson should resume on restart")
	assert(not overlay.visible, "Pause overlay should hide on restart")
	print("  [PASS] Restart button restarts practice and hides overlay")

	# 8. Verify Sample button from pause overlay
	hud_pause.pressed.emit()
	var sample_btn = practice_hud.find_child("Nghe mẫu", true, false) as Button
	assert(sample_btn != null, "Sample button missing from pause overlay")
	sample_btn.pressed.emit()
	assert(node.is_paused == false, "Lesson should not be paused when playing sample")
	assert(not overlay.visible, "Pause overlay should hide when playing sample")
	assert(node.sample_active == true, "Sample playback should be active")
	print("  [PASS] Sample button launches sample playback")
	
	# Cleanup sample player
	if node.sample_player:
		node.sample_player.stop()
		node.sample_active = false

	node.queue_free()
	await process_frame
	print("=== ALL LESSON SAO TRUC HUD TESTS PASSED ===")
	quit(0)
