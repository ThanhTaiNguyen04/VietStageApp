extends SceneTree

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	# In-memory fixtures only: never read or write a learner's saved progress.
	get_root().get_node("BackendReport").set_process(false)
	SecureDataManager._store_loaded = true
	var fixture := SecureDataManager._fresh_profile()
	fixture["unlocked_lessons"]["sao_truc"] = ["sao_truc_level1_1_video", "Node2", "Node3", "Node4", "Node5", "Node6", "Node7", "Node8"]
	fixture["completed_lessons"]["sao_truc"] = ["sao_truc_level1_1_video", "Node2", "Node3_practice"]
	SecureDataManager._profiles[SecureDataManager._active_profile_key] = fixture.duplicate(true)
	var scene := load("res://scenes/LessonSaoTrucList.tscn") as PackedScene
	var screen = scene.instantiate()
	get_root().add_child(screen)
	await process_frame
	await process_frame
	_check_completed(screen, 0, true, "intro completion")
	_check_completed(screen, 1, true, "saved lesson completion")
	_check_completed(screen, 2, true, "legacy practice completion")
	_check_completed(screen, 3, false, "unstarted lesson")

	# Backend status can be available even when completed_lessons is not populated.
	SecureDataManager.be_catalog = [{"id": 9002, "lessonCode": "Node4", "instrumentKey": "sao_truc"}]
	SecureDataManager.data["backend_lesson_access"] = {"9002": {"isUnlocked": true, "learningStatus": "COMPLETED"}}
	await _rebuild(screen)
	_check_completed(screen, 3, true, "backend completed status")
	SecureDataManager.data["backend_lesson_access"]["9002"]["learningStatus"] = "IN_PROGRESS"
	await _rebuild(screen)
	_check_completed(screen, 3, false, "in progress is not completed")
	_check(_button(screen, 3).get_theme_stylebox("normal").bg_color == screen.C_JADE, "in progress should use jade background")
	SecureDataManager.data["backend_lesson_access"]["9002"]["learningStatus"] = "NOT_STARTED"
	SecureDataManager.data["pending_game_attempts"] = [{"kind": "lesson_completion", "instrument": "sao_truc", "local_lesson_id": "Node4"}]
	await _rebuild(screen)
	_check_completed(screen, 3, false, "pending sync is not completed")
	_check(_button(screen, 3).text.contains("Chờ đồng bộ"), "pending sync should have its own label")

	SecureDataManager.data["user_email"] = SecureDataManager.TEMPORARY_FULL_ACCESS_EMAILS[0]
	await _rebuild(screen)
	for index in range(8):
		_check_completed(screen, index, true, "shared completion policy lesson %d" % index)
	screen.queue_free()
	await process_frame
	print("Sao Truc lesson list progress: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(0 if failures == 0 else 1)

func _rebuild(screen) -> void:
	screen._build_lesson_list()
	await process_frame
	await process_frame

func _button(screen, index: int) -> Button:
	return screen.lessons_hbox.get_child(index).get_node("Row/LessonBtn") as Button

func _check_completed(screen, index: int, expected: bool, label: String) -> void:
	var button := _button(screen, index)
	_check(button.text.contains("Hoàn thành") == expected, label + ": completion label")
	if expected:
		var style := button.get_theme_stylebox("normal") as StyleBoxFlat
		_check(style.bg_color == screen.C_JADE, label + ": jade background")
		_check(style.border_color == screen.C_GOLD, label + ": gold border")
