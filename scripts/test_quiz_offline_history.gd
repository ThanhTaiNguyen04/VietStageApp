extends SceneTree

const AuthSessionStore = preload("res://scripts/AuthSession.gd")
const Context = preload("res://scripts/LearningActivityContext.gd")
const Secure = preload("res://scripts/SecureDataManager.gd")
const QuizScreen = preload("res://scripts/LearningQuizScreen.gd")
const HistoryScreen = preload("res://scripts/ActivityHistoryScreen.gd")

var _original_local_history: Array = []
var _original_pending_attempts: Array = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	Secure.load_data()
	_original_local_history = Secure.data.get("local_activity_history", []).duplicate(true)
	_original_pending_attempts = Secure.data.get("pending_game_attempts", []).duplicate(true)
	Secure.data["local_activity_history"] = []
	# This test validates only LOCAL_ONLY entries. Keep an existing user's retry
	# queue out of the assertion, then restore it before exiting.
	Secure.data["pending_game_attempts"] = []
	# LearningQuizScreen calls load_data() during setup. Persist the isolated
	# fixture first so that reload cannot bring unrelated user history back.
	Secure.save_data()
	# Force the local/sample branch without changing the persisted auth file.
	AuthSessionStore.ensure_loaded()
	AuthSessionStore.access_token = ""
	Context.configure("dan_tranh", ["Node1"], "res://scenes/MainMenu.tscn")

	var screen := QuizScreen.new()
	get_root().add_child(screen)
	await process_frame
	assert(screen.quizzes.size() > 0)

	# The screen may receive a real quiz when a BackendReport autoload exists.
	# Force this test's first question through the bundled/local-only branch.
	var quiz: Dictionary = screen.quizzes[0].duplicate(true)
	quiz["id"] = 0
	screen.quizzes[0] = quiz
	var options: Array = screen._parse_options(quiz.get("options", []))
	var correct_index := screen._resolve_correct_index(quiz, options)
	assert(correct_index >= 0)
	var answer_button := screen.options_box.get_child(correct_index) as Button
	await screen._answer(answer_button, correct_index, str(options[correct_index]))

	var local_history: Array = Secure.get_local_activity_history()
	assert(local_history.size() == 1)
	assert(local_history[0].get("score") == 100)
	assert(screen.score == 10)

	var history := HistoryScreen.new()
	var rendered: Array = history.merge_pending_items([])
	assert(rendered.size() == 1)
	assert(rendered[0].get("type") == "QUIZ")
	assert(rendered[0].get("status") == "LOCAL_ONLY")
	assert(rendered[0].get("score") == 100)
	print("Offline quiz grading and activity history PASS")

	Secure.data["local_activity_history"] = _original_local_history
	Secure.data["pending_game_attempts"] = _original_pending_attempts
	Secure.save_data()
	quit()
