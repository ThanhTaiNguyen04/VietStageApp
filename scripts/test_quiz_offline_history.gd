extends SceneTree

const AuthSessionStore = preload("res://scripts/AuthSession.gd")
const Context = preload("res://scripts/LearningActivityContext.gd")
const Secure = preload("res://scripts/SecureDataManager.gd")
const QuizScreen = preload("res://scripts/LearningQuizScreen.gd")
const HistoryScreen = preload("res://scripts/ActivityHistoryScreen.gd")

var _original_local_history: Array = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	Secure.load_data()
	_original_local_history = Secure.data.get("local_activity_history", []).duplicate(true)
	Secure.data["local_activity_history"] = []
	# Force the local/sample branch without changing the persisted auth file.
	AuthSessionStore.ensure_loaded()
	AuthSessionStore.access_token = ""
	Context.configure("dan_tranh", ["Node1"], "res://scenes/MainMenu.tscn")

	var screen := QuizScreen.new()
	get_root().add_child(screen)
	await process_frame
	assert(screen.quizzes.size() > 0)

	var quiz: Dictionary = screen.quizzes[0]
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
	Secure.save_data()
	quit()
