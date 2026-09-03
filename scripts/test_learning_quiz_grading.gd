extends SceneTree

const LearningQuizScreen = preload("res://scripts/LearningQuizScreen.gd")

func _init() -> void:
	var screen := LearningQuizScreen.new()
	var quiz := {
		"id": 0,
		"options": ["Đô", "Rê", "Mi", "Fa"],
		"correctAnswer": "Đô"
	}

	var local_correct := screen._grade_answer(quiz, 0, "Đô", {})
	assert(local_correct.get("is_correct") == true)
	assert(local_correct.get("source") == "local")

	var local_wrong := screen._grade_answer(quiz, 1, "Rê", {})
	assert(local_wrong.get("is_correct") == false)
	assert(local_wrong.get("correct_answer") == "Đô")

	var server_result := screen._grade_answer(quiz, 0, "Đô", {
		"submitted": true,
		"is_correct": false,
		"correct_answer": "Rê"
	})
	assert(server_result.get("is_correct") == false)
	assert(server_result.get("correct_answer") == "Rê")
	assert(server_result.get("source") == "server")

	screen.result_sync_status = "offline"
	screen._record_quiz_submission({"submitted": true})
	assert(screen.submitted_attempt_count == 1)
	assert(screen.unsynced_attempt_count == 0)
	assert(screen.result_sync_status == "be")

	screen._record_quiz_submission({"submitted": false, "queued": true})
	assert(screen.submitted_attempt_count == 1)
	assert(screen.unsynced_attempt_count == 1)
	assert(screen.result_sync_status == "failed")

	print("LearningQuizScreen grading and sync status PASS")
	quit()
