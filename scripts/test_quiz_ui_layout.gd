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
	assert(screen.floating_back_button != null, "Back button must exist")
	assert(screen.floating_back_button.custom_minimum_size == Vector2(84, 84), "Back button should be large 84x84")
	assert(screen.progress_bar != null, "Progress bar must exist")
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
	quit()
