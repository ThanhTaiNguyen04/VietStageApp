extends SceneTree

const LearningQuizScreen = preload("res://scripts/LearningQuizScreen.gd")

func _init() -> void:
	call_deferred("_run_zero_shift_test")

func _run_zero_shift_test() -> void:
	var root := get_root()
	root.size = Vector2i(1366, 640) # Laptop screen resolution

	var screen := LearningQuizScreen.new()
	root.add_child(screen)

	var quiz1 := {
		"id": 0,
		"question": "Nốt nhạc trên khuông dưới đây là nốt nào?",
		"options": ["Đô", "Rê", "Mi", "Sol"],
		"correctAnswer": "Sol",
		"note": "G4"
	}
	var quiz2 := {
		"id": 0,
		"question": "Nốt nhạc này là nốt gì?",
		"options": ["Fa", "La", "Si", "Đô2"],
		"correctAnswer": "La",
		"note": "A4"
	}
	screen.quizzes = [quiz1, quiz2]
	screen.question_index = 0
	screen.score = 10

	screen._show_quiz_ui()
	screen._show_question()

	var frosted_stage := screen.content_box.find_child("FrostedStage", true, false) as PanelContainer
	assert(frosted_stage != null, "FrostedStage must exist")
	var stage_v := screen._quiz_stage_v
	assert(stage_v != null, "stage_v must exist")

	var initial_child_count := stage_v.get_child_count()
	var initial_stage_h := frosted_stage.get_combined_minimum_size().y
	print("[Check] Initial stage_v child count: %d, stage min_height: %f" % [initial_child_count, initial_stage_h])

	# Verify feedback slot exists with pre-allocated height
	var feedback_slot := stage_v.find_child("FeedbackSlot", true, false) as Label
	assert(feedback_slot != null, "FeedbackSlot must exist inside stage_v")
	assert(feedback_slot.custom_minimum_size.y >= 30.0, "FeedbackSlot must have pre-allocated min height")
	assert(feedback_slot.text == "", "FeedbackSlot should initially be empty")

	# Select WRONG answer: button 0 ("Đô"), correct is button 3 ("Sol")
	var options_box := stage_v.find_child("OptionsGrid", true, false) as GridContainer
	assert(options_box != null, "OptionsGrid must exist")
	var btn_wrong := options_box.get_child(0) as Button
	var btn_correct := options_box.get_child(3) as Button
	assert(btn_wrong != null and btn_correct != null, "Option buttons must exist")

	# Simulate clicking wrong answer
	btn_wrong.emit_signal("pressed")

	# Check zero layout shift: child count must NOT increase
	var after_child_count := stage_v.get_child_count()
	var after_stage_h := frosted_stage.get_combined_minimum_size().y
	print("[Check] After answer stage_v child count: %d (expected %d)" % [after_child_count, initial_child_count])
	print("[Check] After answer stage min_height: %f (expected %f)" % [after_stage_h, initial_stage_h])
	assert(after_child_count == initial_child_count, "No dynamic nodes should be added to stage_v on answer!")
	assert(abs(after_stage_h - initial_stage_h) < 0.5, "Stage combined height must remain constant (Zero layout shift)!")

	# Check button styles
	var wrong_style := btn_wrong.get_theme_stylebox("disabled") as StyleBoxFlat
	assert(wrong_style != null and wrong_style.bg_color == Color("#ffebee"), "Wrong button must turn red (#ffebee)")

	var correct_style := btn_correct.get_theme_stylebox("disabled") as StyleBoxFlat
	assert(correct_style != null and correct_style.bg_color == Color("#e8f5e9"), "Correct button must turn green (#e8f5e9)")
	print("[Check] Wrong button turned red, correct button turned green: PASS")

	# Check feedback text
	assert(feedback_slot.text.contains("Sol"), "Feedback text must display correct answer 'Sol'")
	print("[Check] Feedback text displayed: '%s'" % feedback_slot.text)

	# Check auto-advance token
	assert(screen._auto_advance_token > 0, "Auto-advance token should be set")

	# Test tapping to fast-forward auto-advance to question 2
	var tap_event := InputEventMouseButton.new()
	tap_event.pressed = true
	screen._unhandled_input(tap_event)
	# Or call _next_question
	assert(screen.question_index == 1, "Should have advanced to question 2")
	print("[Check] Auto-advanced to question 2 (index=1): PASS")

	print("\n>>> ALL ZERO-SHIFT AND AUTO-ADVANCE TESTS PASSED! <<<\n")
	screen.queue_free()
	quit()
