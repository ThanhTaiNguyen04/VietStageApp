extends SceneTree

const Auth = preload("res://scripts/AuthSession.gd")
const Context = preload("res://scripts/LearningActivityContext.gd")
const Secure = preload("res://scripts/SecureDataManager.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var token := OS.get_environment("VIETSTAGE_TEST_LEARNER_TOKEN")
	if token.is_empty():
		printerr("Missing learner token")
		quit(1)
		return
	Auth.ensure_loaded()
	Auth.access_token = token
	Secure.be_catalog.clear()
	Secure.be_quizzes.clear()
	var lesson_ids: Array = ["dan_tranh_level_1_bai_1_video"]
	if OS.get_environment("VIETSTAGE_TEST_ROUTE") == "level_quiz":
		lesson_ids = ["dan_tranh_level_1_bai_1_video", "dan_tranh_level_1_bai_2_video", "dan_tranh_level_1_bai_3_video"]
	elif OS.get_environment("VIETSTAGE_TEST_ROUTE") == "node1":
		lesson_ids = ["Node1"]
	Context.configure("dan_tranh", lesson_ids, "res://scenes/MainMenu.tscn")
	for activity in ["quiz_note", "quiz_knowledge"]:
		Context.activity = activity
		var scene = load("res://scenes/LearningQuizScreen.tscn").instantiate()
		root.add_child(scene)
		var deadline := Time.get_ticks_msec() + 40000
		while (scene.get("quizzes") as Array).is_empty() and Time.get_ticks_msec() < deadline:
			await process_frame
		var quizzes: Array = scene.get("quizzes")
		var options: GridContainer = scene.get("options_box")
		if quizzes.is_empty() or options == null or options.get_child_count() != 4 or not options.is_visible_in_tree():
			printerr("FAIL: ", activity, " quiz not rendered; count=", quizzes.size(), " lesson=", Context.backend_lesson_id)
			quit(1)
			return
		print("PASS: ", activity, " quiz_id=", quizzes[0].get("id"), " lesson=", Context.backend_lesson_id, " options=4")
		if activity == "quiz_note" and OS.get_environment("VIETSTAGE_TEST_SUBMIT") == "1":
			var first_option := options.get_child(0) as Button
			var selected := str(first_option.get_meta("option_text", first_option.text))
			await scene._answer(first_option, 0, selected)
			if int(scene.get("submitted_attempt_count")) != 1 or int(scene.get("unsynced_attempt_count")) != 0:
				printerr("FAIL: learner answer was not confirmed by the server")
				quit(1)
				return
			print("PASS: learner submitted quiz_id=", quizzes[0].get("id"), " through Godot")
		scene.queue_free()
		await process_frame
	print("PASS: learner can read both live Quiz types; optional submission verified when enabled")
	quit(0)
