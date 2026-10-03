extends SceneTree

const Quiz = preload("res://scripts/LearningQuizScreen.gd")
const Context = preload("res://scripts/LearningActivityContext.gd")
const Auth = preload("res://scripts/AuthSession.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	Auth.ensure_loaded()
	Auth.access_token = ""
	Context.activity = "quiz_note"
	root.set_meta("force_compact_layout", true)
	var original_size := root.content_scale_size
	for phone_size in [Vector2i(900, 420), Vector2i(420, 840)]:
		root.size = phone_size
		var screen := (load("res://scenes/LearningQuizScreen.tscn") as PackedScene).instantiate() as Quiz
		root.add_child(screen)
		screen.quizzes = [{"id": 0, "question": "Nốt trên khuông nhạc là nốt gì?", "note": "Sol", "options": ["Sol", "La", "Đô", "Rê"], "correctAnswer": "Sol"}]
		screen.question_index = 0
		screen._show_quiz_ui()
		screen._show_question()
		for tick in 8:
			await process_frame
		var back := screen.find_child("ActivityBackButton", true, false) as Button
		assert(back != null and back.is_visible_in_tree())
		assert(screen.floating_back_button == null)
		for button: Button in screen.options_box.get_children():
			assert(button.size.y >= 48)
			assert(button.get_global_rect().end.x <= screen.get_viewport_rect().size.x + 1)
			assert(button.get_global_rect().end.y <= screen.get_viewport_rect().size.y + 1, "Answers must fit the phone viewport")
		screen._restart()
		assert(screen.floating_back_button == null)
		for tick in 8:
			await process_frame
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			var snapshot := root.get_texture().get_image()
			assert(snapshot.save_png("user://quiz_phone_%dx%d.png" % [phone_size.x, phone_size.y]) == OK)
		assert(_back_actions(screen) == 1)
		screen._show_message("Chưa thể tải câu hỏi. Vui lòng thử lại.", true)
		await process_frame
		assert(_back_actions(screen) == 1, "Error state must use only header navigation")
		await screen._show_quiz_result()
		await process_frame
		assert(_back_actions(screen) == 1, "Result state must use only header navigation")
		screen.quizzes = [{"id": 0, "questionType": "GENERAL", "question": "Đàn tranh có bao nhiêu dây?", "options": ["17", "16", "15", "14"], "correctAnswer": "17"}]
		screen._restart()
		for tick in 8:
			await process_frame
		assert(_back_actions(screen) == 1)
		for button: Button in screen.options_box.get_children():
			assert(button.get_global_rect().end.y <= screen.get_viewport_rect().size.y + 1)
		screen.queue_free()
		await process_frame
		await process_frame
	assert(root.content_scale_size == original_size)
	root.remove_meta("force_compact_layout")
	print("PASS: phone portrait/landscape, visible answers, touch targets and restart navigation")
	quit()

func _back_actions(node: Node) -> int:
	var count := 0
	if node is Button and (node as Button).is_visible_in_tree():
		for connection: Dictionary in node.get_signal_connection_list("pressed"):
			if (connection["callable"] as Callable).get_method() == "_go_back":
				count += 1
	for child in node.get_children():
		count += _back_actions(child)
	return count
