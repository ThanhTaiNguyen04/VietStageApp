extends SceneTree

const AuthSessionStore = preload("res://scripts/AuthSession.gd")
const Context = preload("res://scripts/LearningActivityContext.gd")
const Secure = preload("res://scripts/SecureDataManager.gd")

class FakeApi extends Node:
	var fetched_lesson_ids: Array[int] = []
	var submitted_quiz_ids: Array[int] = []
	var empty_mode := false
	var submit_failure_mode := false

	func get_lesson_quizzes(lesson_id: int) -> Dictionary:
		fetched_lesson_ids.append(lesson_id)
		if empty_mode:
			return {"status": 200, "body": {"data": []}}
		return {"status": 200, "body": {"data": [{
			"id": 500, "status": "ACTIVE", "title": "Nốt La", "questionType": "GENERAL",
			"question": "Nốt La là đáp án nào?", "options": "[\"La\",\"Si\",\"Đô\",\"Rê\"]",
			"orderIndex": 1
		}]}}

	func submit_quiz_attempt(quiz_id: int, selected_answer: String, _attempt_id: String) -> Dictionary:
		submitted_quiz_ids.append(quiz_id)
		if submit_failure_mode:
			return {"status": 0, "body": {}}
		return {"status": 201, "body": {"data": {
			"id": 900, "quizId": quiz_id, "selectedAnswer": selected_answer,
			"isCorrect": true, "correctAnswer": "La", "score": 100,
			"pointsEarned": 10, "starsEarned": 2
		}}}

	func error_message(_response: Dictionary, fallback: String) -> String:
		return fallback

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	AuthSessionStore.ensure_loaded()
	AuthSessionStore.access_token = "quiz-scene-test-token"
	Context.configure("dan_tranh", ["Node1"], "res://scenes/MainMenu.tscn")
	Context.activity = "quiz_knowledge"
	Secure.be_catalog = [{"id": 50, "orderIndex": 1, "instrument": {"id": 1, "instrumentCode": "dan_tranh"}}]
	Secure.be_quizzes.clear()
	var report: Node = get_root().get_node("BackendReport")
	var fake = FakeApi.new()
	report.set("_api", fake)
	var scene = load("res://scenes/LearningQuizScreen.tscn") as PackedScene
	var screen = scene.instantiate()
	get_root().add_child(screen)
	for tick in 60:
		if screen.get("quizzes").size() > 0:
			break
		await process_frame
	if fake.fetched_lesson_ids != [50] or screen.get("quizzes").size() != 1:
		printerr("Lesson 50 quiz scene FAIL: quiz was not loaded")
		quit(1)
		return
	var options_box: GridContainer = screen.get("options_box")
	var first_option := options_box.get_child(0) as Button
	await screen._answer(first_option, 0, "La")
	var feedback: Label = screen.get("feedback_label")
	if fake.submitted_quiz_ids != [500] or int(screen.get("correct_count")) != 1 or int(screen.get("score")) != 10 or feedback == null or not feedback.text.contains("chính xác"):
		printerr("Lesson 50 quiz scene FAIL: attempt or result was not applied")
		quit(1)
		return
	screen.queue_free()
	await process_frame
	Secure.be_quizzes.clear()
	fake.empty_mode = true
	var empty_screen = scene.instantiate()
	get_root().add_child(empty_screen)
	for tick in 60:
		if bool(empty_screen.get("_backend_fetch_finished")):
			break
		await process_frame
	await process_frame
	if not (empty_screen.get("quizzes") as Array).is_empty() or not str((empty_screen.get("content_box") as Node).get_child(0).text).contains("chưa có câu hỏi"):
		printerr("Lesson 50 quiz scene FAIL: empty backend showed sample quiz")
		quit(1)
		return
	empty_screen.queue_free()
	await process_frame
	Secure.be_quizzes.clear()
	fake.empty_mode = false
	fake.submit_failure_mode = true
	var pending_screen = scene.instantiate()
	get_root().add_child(pending_screen)
	for tick in 60:
		if (pending_screen.get("quizzes") as Array).size() > 0:
			break
		await process_frame
	var pending_option := (pending_screen.get("options_box") as GridContainer).get_child(0) as Button
	await pending_screen._answer(pending_option, 0, "La")
	var pending_feedback: Label = pending_screen.get("feedback_label")
	if pending_feedback == null or not pending_feedback.text.contains("đồng bộ") or int(pending_screen.get("correct_count")) != 0:
		printerr("Lesson 50 quiz scene FAIL: unavailable grading was shown as a wrong answer")
		quit(1)
		return
	print("Lesson 50 quiz scene load, submit, result, empty and pending states PASS")
	pending_screen.queue_free()
	fake.free()
	quit()
