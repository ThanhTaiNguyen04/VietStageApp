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

	# Assert that QuestionPromptCard and QuizStaffCard exist in content_box
	var found_prompt_card := false
	var found_staff_card := false
	for child in screen.content_box.get_children():
		if child is PanelContainer:
			if child.name == "QuestionPromptCard":
				found_prompt_card = true
			elif child.name == "QuizStaffCard":
				found_staff_card = true

	assert(found_prompt_card, "QuestionPromptCard must exist in content_box")
	assert(found_staff_card, "QuizStaffCard must exist in content_box")

	print("[LayoutTest] LearningQuizScreen UI Layout and Structure PASS!")
	screen.queue_free()
	quit()
