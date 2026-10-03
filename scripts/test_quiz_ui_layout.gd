extends SceneTree

const LearningQuizScreen = preload("res://scripts/LearningQuizScreen.gd")

func _init() -> void:
	call_deferred("_run_layout_test")

func _run_layout_test() -> void:
	var screen := LearningQuizScreen.new()
	get_root().add_child(screen)

	# Simulate sample quiz data
	var quiz := {
		"id": 1,
		"question": "Nốt nhạc hiển thị trên khuông nhạc là nốt gì?",
		"options": ["Đô", "Rê", "Mi", "Fa"],
		"correctAnswer": "Đô",
		"note": "C4"
	}
	screen.quizzes = [quiz]
	screen.question_index = 0
	screen.score = 20

	# Test building the sticky top bar & question layout
	screen._show_quiz_ui()
	screen._show_question()

	# Assertions on elements
	assert(screen.floating_back_button == null, "Quiz must not create a second back button")
	assert((screen.root_box.get_child(0) as Control).visible, "Shared activity header must be visible")
	assert(screen.title_label.get_parent().visible, "Quiz title must be visible in the header")
	assert((screen.get_child(0) as TextureRect).texture.resource_path.ends_with("bg_practice_room.png"), "Quiz must reuse practice-room artwork")
	assert((screen.get_child(1) as ColorRect).color.a >= 0.85, "Cream wash must keep question content readable")
	assert(screen.progress_bar != null, "Progress bar must exist")
	assert(screen.progress_count_label.text == "1 / 1", "Question position must be visible")
	assert(screen.score_label != null, "Score label must exist")
	assert(screen.score_label.text == "20", "Score label should display score 20")
	assert(screen.options_box != null, "Options box must exist")
	assert(screen.options_box.get_child_count() == 4, "Should have 4 option buttons")

	# Assert that FrostedStage, QuestionPromptCard, and QuizStaffCard exist
	var frosted_stage := screen.content_box.find_child("FrostedStage", true, false) as Control
	assert(frosted_stage != null, "FrostedStage must exist inside content_box")

	var prompt_card := screen.content_box.find_child("QuestionPromptCard", true, false) as PanelContainer
	assert(prompt_card != null, "QuestionPromptCard must exist inside FrostedStage")

	var staff_card := screen.content_box.find_child("QuizStaffCard", true, false) as PanelContainer
	assert(staff_card != null, "QuizStaffCard must exist inside FrostedStage")

	# Check enlarged option button dimensions
	var first_btn := screen.options_box.get_child(0) as Button
	assert(first_btn != null, "First option button must exist")
	assert(first_btn.custom_minimum_size.y >= 74.0, "Option button min height must be >= 74px")

	print("[LayoutTest] LearningQuizScreen UI Layout and Structure PASS!")
	screen.queue_free()
	await process_frame
	get_root().set_meta("force_compact_layout", true)
	var compact := LearningQuizScreen.new()
	get_root().add_child(compact)
	compact.quizzes = [quiz]
	compact.question_index = 0
	compact._show_quiz_ui()
	compact._show_question()
	assert(compact.floating_back_button == null, "Compact quiz must not create a second back button")
	compact._restart()
	assert(compact.floating_back_button == null, "Restart must not restore a second back button")
	assert((compact.root_box.get_child(0) as Control).visible, "Header must stay visible on compact layout")
	compact.queue_free()
	get_root().remove_meta("force_compact_layout")
	quit()
