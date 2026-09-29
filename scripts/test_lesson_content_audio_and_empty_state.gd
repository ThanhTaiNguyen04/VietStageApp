extends SceneTree

const Context = preload("res://scripts/LearningActivityContext.gd")
const AuthSession = preload("res://scripts/AuthSession.gd")
const DanTranhAudio = preload("res://scripts/DanTranhAudio.gd")
const BackendReportScript = preload("res://scripts/BackendReport.gd")
const InstrumentSamplePlayer = preload("res://scripts/InstrumentSamplePlayer.gd")

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition:
		print("  [PASS] " + message)
	else:
		failures += 1
		printerr("  [FAIL] " + message)

func _find_child_text(node: Node, text: String) -> Node:
	if node is Label and (node as Label).text.contains(text):
		return node
	if node is Button and (node as Button).text.contains(text):
		return node
	for child in node.get_children():
		var found := _find_child_text(child, text)
		if found != null:
			return found
	return null

func _run() -> void:
	print("--- Running Verification for Lesson Consistency, Empty State, and Audio Timbre ---")
	await _test_dan_tranh_audio_consistency()
	await _test_rhythm_challenge_empty_and_error_states()
	await _test_activities_multi_lesson_discovery()

	if failures == 0:
		print("[ALL FIXES VERIFIED SUCCESSFULLY]")
	else:
		printerr("[FAILURES ENCOUNTERED: %d]" % failures)
	quit(failures)

func _test_dan_tranh_audio_consistency() -> void:
	print("Testing Dan Tranh audio timbre unification...")
	Context.configure("dan_tranh", ["Node1"], "res://scenes/MainMenu.tscn")
	var quiz_scene := load("res://scenes/LearningQuizScreen.tscn") as PackedScene
	_check(quiz_scene != null, "LearningQuizScreen.tscn loaded")
	var quiz_screen: Control = quiz_scene.instantiate()
	get_root().add_child(quiz_screen)
	await process_frame

	# Simulate playing quiz audio for Dan Tranh
	var sample_quiz := {
		"note": "C4",
		"question": "Nốt này là nốt gì?",
		"options": ["Đô", "Rê", "Mi", "Sol"],
		"correctAnswer": "Đô"
	}
	quiz_screen._play_quiz_audio(sample_quiz)
	var player: AudioStreamPlayer = quiz_screen.get("audio_player")
	_check(player != null and is_instance_valid(player), "Audio player created for quiz")
	_check(player.stream != null, "Audio stream loaded")
	_check(player.stream is AudioStreamWAV, "Stream is AudioStreamWAV synthesized pluck")
	
	# Verify that InstrumentSamplePlayer also uses generate_pluck_stream for dan_tranh
	var sample_player := InstrumentSamplePlayer.new()
	quiz_screen.add_child(sample_player)
	var stream: AudioStream = sample_player._stream_for("dan_tranh", "c4")
	_check(stream != null and stream is AudioStreamWAV, "InstrumentSamplePlayer generates AudioStreamWAV for dan_tranh")
	_check((stream as AudioStreamWAV).mix_rate == DanTranhAudio.SAMPLE_RATE, "Sample rate matches DanTranhAudio SAMPLE_RATE (44100)")

	quiz_screen.queue_free()
	await process_frame

func _test_rhythm_challenge_empty_and_error_states() -> void:
	print("Testing RhythmChallengeScreen online empty state & error handling...")
	var rhythm_scene := load("res://scenes/RhythmChallengeScreen.tscn") as PackedScene
	_check(rhythm_scene != null, "RhythmChallengeScreen.tscn loaded")
	var rhythm_screen: Control = rhythm_scene.instantiate()
	get_root().add_child(rhythm_screen)
	await process_frame

	# Test _build_empty_state directly
	rhythm_screen._set_flow_state(rhythm_screen.FlowState.ERROR)
	rhythm_screen._build_empty_state("Chưa có thử thách nhịp điệu", "Bài học này hiện chưa có nội dung thử thách nhịp điệu trên hệ thống.", true)
	await process_frame

	_check(_find_child_text(rhythm_screen, "Chưa có thử thách nhịp điệu") != null, "Empty state heading rendered")
	_check(_find_child_text(rhythm_screen, "Quay lại") != null, "Empty state 'Quay lại' button rendered")
	_check(_find_child_text(rhythm_screen, "Chơi thử offline") != null, "Empty state 'Chơi thử offline' button rendered")

	# Test _build_load_error directly
	rhythm_screen._build_load_error("Lỗi tải thử thách", "Không thể tải dữ liệu thử thách từ máy chủ.", true)
	await process_frame
	_check(_find_child_text(rhythm_screen, "Lỗi tải thử thách") != null, "Load error heading rendered")
	_check(_find_child_text(rhythm_screen, "Thử tải lại") != null, "Load error 'Thử tải lại' button rendered")
	_check(_find_child_text(rhythm_screen, "Chơi offline") != null, "Load error 'Chơi offline' button rendered")

	rhythm_screen.queue_free()
	await process_frame

func _test_activities_multi_lesson_discovery() -> void:
	print("Testing multi-lesson discovery in LearningActivitiesScreen and BackendReport...")
	var report := BackendReportScript.new()
	var root := Node.new()
	root.add_child(report)
	get_root().add_child(root)
	await process_frame

	# Mock signed in session
	AuthSession.access_token = "mock_token"
	AuthSession.session_id = "mock_session"
	AuthSession.refresh_token = "mock_refresh"

	# Populate mock catalog with 2 lessons: lesson 1 and lesson 2
	var mock_catalog := [
		{"id": 101, "orderIndex": 1, "lessonCode": "TR_01", "instrument": {"id": 1, "instrumentCode": "dan_tranh", "name": "Đàn Tranh"}},
		{"id": 102, "orderIndex": 2, "lessonCode": "TR_02", "instrument": {"id": 1, "instrumentCode": "dan_tranh", "name": "Đàn Tranh"}}
	]
	var SecureDataManager = preload("res://scripts/SecureDataManager.gd")
	SecureDataManager.be_catalog = mock_catalog

	# Mock minigames: lesson 101 has 0 rhythm, lesson 102 has 1 rhythm
	SecureDataManager.cache_be_minigames(101, [])
	SecureDataManager.cache_be_minigames(102, [
		{"id": 501, "challengeType": "RHYTHM_MATCH", "title": "Bài 2 Nhịp điệu"}
	])

	# Mock quizzes: lesson 101 has 1 quiz, lesson 102 has 1 quiz (with duplicate id to verify deduplication)
	SecureDataManager.cache_be_quizzes(101, [
		{"id": 601, "quizType": "NOTE_IDENTIFICATION", "question": "Q1"}
	])
	SecureDataManager.cache_be_quizzes(102, [
		{"id": 601, "quizType": "NOTE_IDENTIFICATION", "question": "Q1 (dup)"},
		{"id": 602, "quizType": "NOTE_IDENTIFICATION", "question": "Q2"}
	])

	# fetch_quizzes_for_level across both lessons should deduplicate id 601
	var quizzes: Array = await report.fetch_quizzes_for_level("dan_tranh", ["Node1", "Node2"])
	_check(quizzes.size() == 2, "fetch_quizzes_for_level deduplicates quizzes (expected 2, got %d)" % quizzes.size())

	# fetch_minigames_for_level across both lessons should discover the rhythm challenge in Node2
	var minigames: Array = await report.fetch_minigames_for_level("dan_tranh", ["Node1", "Node2"], "RHYTHM_MATCH", false)
	_check(minigames.size() == 1, "fetch_minigames_for_level finds minigame from Node2 (expected 1, got %d)" % minigames.size())

	# Test LearningActivitiesScreen with multi-lesson context
	Context.configure("dan_tranh", ["Node1", "Node2"], "res://scenes/MainMenu.tscn")
	var act_scene := load("res://scenes/LearningActivitiesScreen.tscn") as PackedScene
	var act_screen: Control = act_scene.instantiate()
	get_root().add_child(act_screen)
	await act_screen._load_activity_content()

	_check(act_screen.get("_rhythm_count") == 1, "LearningActivitiesScreen discovered 1 rhythm challenge across lessons")
	_check(bool((act_screen.get("_available") as Dictionary).get("rhythm", false)) == true, "Rhythm card is available because lesson 2 contains rhythm challenge")
	_check(act_screen.get("_quiz_count") == 2, "LearningActivitiesScreen counted 2 unique quizzes across lessons")

	act_screen.queue_free()
	root.queue_free()
	await process_frame
