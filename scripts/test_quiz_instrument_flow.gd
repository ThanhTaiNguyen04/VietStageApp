extends SceneTree
const Auth = preload("res://scripts/AuthSession.gd")
const Context = preload("res://scripts/LearningActivityContext.gd")
const LegacyQuiz = preload("res://scripts/QuizScreen.gd")
class FakeApi extends Node:
	var requested: Array[int] = []
	var submitted: Array = []
	var question_type := "NOTE_IDENTIFICATION"
	var fail := false
	func get_instruments() -> Dictionary:
		return {"status": 200, "body": {"data": SecureDataManager.be_instruments}}
	func get_lessons(_instrument: int, _level: int, _status: String, _page: int, _size: int, _visible: bool, _search: String = "") -> Dictionary:
		return {"status": 200, "body": {"data": {"content": [], "totalPages": 1}}}
	func get_lesson_minigames(_id: int) -> Dictionary:
		return {"status": 200, "body": {"data": []}}
	func get_instrument_quizzes(id: int) -> Dictionary:
		requested.append(id)
		if fail:
			return {"status": 503, "body": {}}
		return {"status": 200, "body": {"data": [{"id": 9001, "status": "ACTIVE", "questionType": question_type, "note": "C4", "question": "Instrument question", "options": "[\"Do\",\"Re\",\"Mi\",\"Fa\"]"}, {"id": 9002, "status": "INACTIVE"}]}}
	func submit_quiz_attempt(id: int, answer: String, attempt: String) -> Dictionary:
		submitted.append([id, answer, attempt])
		return {"status": 201, "body": {"data": {"id": 100, "isCorrect": true, "pointsEarned": 10, "starsEarned": 2, "correctAnswer": "Do"}}}
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	Auth.ensure_loaded()
	Auth.access_token = "test-only"
	Context.configure("dan_tranh", ["no_backend_lesson"], "res://scenes/MainMenu.tscn")
	Context.activity = "quiz_note"
	SecureDataManager.be_catalog = []
	SecureDataManager.be_instruments = [{"id": 7, "instrumentCode": "dan_tranh"}, {"id": 8, "instrumentCode": "sao_truc"}]
	var report = root.get_node("BackendReport")
	var fake = FakeApi.new()
	report.add_child(fake)
	report.set("_api", fake)
	var screen = load("res://scenes/LearningQuizScreen.tscn").instantiate()
	root.add_child(screen)
	await create_timer(0.4).timeout
	assert(fake.requested == [7])
	assert(screen.quizzes.size() == 1)
	assert(screen.options_box.get_child_count() == 4)
	assert(screen.options_box.is_visible_in_tree())
	var button = screen.options_box.get_child(0)
	await screen._answer(button, 0, "Do")
	assert(fake.submitted.size() == 1)
	assert(fake.submitted[0][0] == 9001 and fake.submitted[0][1] == "Do")
	assert(screen.correct_count == 1 and screen.score == 10)
	assert(screen.api_stars_earned == 2)
	await report.fetch_quizzes_for_level("sao_truc", [])
	assert(fake.requested == [7, 8])
	print("PASS instrument quiz scene: no lesson binding, ACTIVE filter, four visible answers, submitted answer and server rewards, separate instrument IDs")
	screen.queue_free()
	await process_frame
	fake.question_type = "GENERAL"
	Context.activity = "quiz_knowledge"
	var knowledge = load("res://scenes/LearningQuizScreen.tscn").instantiate()
	root.add_child(knowledge)
	await create_timer(0.4).timeout
	assert(fake.requested == [7, 8, 7])
	assert(knowledge.quizzes.size() == 1)
	assert(knowledge.quizzes[0].questionType == "GENERAL")
	knowledge.queue_free()
	await process_frame
	var picker = load("res://scenes/LearningActivitiesScreen.tscn").instantiate()
	root.add_child(picker)
	await create_timer(0.5).timeout
	assert(picker._available.quiz_knowledge and not picker._available.quiz_note)
	assert(picker._knowledge_quiz_count == 1)
	print("PASS activity picker discovers instrument knowledge quiz without lesson binding")
	picker.queue_free()
	await process_frame
	LegacyQuiz.quiz_instrument = "dan_tranh"
	LegacyQuiz.quiz_local_ids = ["no_backend_lesson"]
	var legacy = load("res://scenes/QuizScreen.tscn").instantiate()
	root.add_child(legacy)
	await create_timer(0.4).timeout
	assert(legacy._quizzes.size() == 1)
	await legacy._on_option(legacy.options_vbox.get_child(0), 0, "Do")
	assert(legacy._correct_count == 1 and legacy._score == 10)
	print("PASS legacy QuizScreen submits instrument quiz directly")
	legacy.queue_free()
	await process_frame
	fake.fail = true
	var failed: Array = await report.fetch_quizzes_for_level("dan_tranh", [])
	assert(failed.is_empty() and not report.last_quiz_fetch_succeeded)
	print("PASS fresh fetch on reopen, knowledge quiz type and fetch failure state")
	quit(0)
