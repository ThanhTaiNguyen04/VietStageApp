extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	# Mock AuthSession to simulate being signed in
	var AuthSessionStore = preload("res://scripts/AuthSession.gd")
	AuthSessionStore.access_token = "mock_token"
	AuthSessionStore.session_id = "mock_session"
	AuthSessionStore.refresh_token = "mock_refresh"
	
	var Context = preload("res://scripts/LearningActivityContext.gd")
	Context.ensure_defaults()
	
	var BackendReport = preload("res://scripts/BackendReport.gd").new()
	var root = Node.new()
	root.add_child(BackendReport)
	get_root().add_child(root)
	
	print("--- STARTING TEST ---")
	
	await BackendReport.fetch_and_install_catalog()
	
	print("be_catalog size: ", preload("res://scripts/SecureDataManager.gd").be_catalog.size())
	
	var quizzes = await BackendReport.fetch_quizzes_for_level("dan_tranh", Context.local_lesson_ids)
	
	print("Fetched quizzes size: ", quizzes.size())
	for q in quizzes:
		print("Quiz: ", q)
		
	quit()
