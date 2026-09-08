extends SceneTree

const LessonAssessmentCoordinator = preload("res://scripts/LessonAssessmentCoordinator.gd")
const SecureDataManager = preload("res://scripts/SecureDataManager.gd")
const LearningActivityContext = preload("res://scripts/LearningActivityContext.gd")

func _init() -> void:
	print("--- Running Assessment Flow & Offline Isolation Tests ---")
	_test_offline_isolation()
	_test_draft_lifecycle()
	_test_exact_be_resolution()
	_test_queue_idempotency_and_unlock()
	print("=== ALL ASSESSMENT FLOW TESTS PASSED ===")
	quit(0)

func _test_offline_isolation() -> void:
	# 1. Lesson with no BE binding (id = 0)
	var draft := LessonAssessmentCoordinator.register_content(0, [], [])
	assert(draft.get("lesson_id") == 0)
	assert(not LessonAssessmentCoordinator.is_complete(0))
	assert(LessonAssessmentCoordinator.payload(0).is_empty())
	print("  [PASS] Offline lesson with id=0 does not create valid assessment payload")

func _test_draft_lifecycle() -> void:
	var lesson_id := 999
	LessonAssessmentCoordinator.clear(lesson_id)

	# Register content: 2 quizzes, 1 rhythm minigame, 1 melody minigame
	var quizzes := [
		{"id": 10, "question": "Q1"},
		{"id": 11, "question": "Q2"}
	]
	var minigames := [
		{"id": 20, "challengeType": "RHYTHM_MATCH"},
		{"id": 21, "challengeType": "MELODY_COMPLETE"}
	]

	LessonAssessmentCoordinator.register_content(lesson_id, quizzes, minigames)

	# Initial state: NOT_STARTED for all
	assert(LessonAssessmentCoordinator.activity_state(lesson_id, "quiz") == "NOT_STARTED")
	assert(LessonAssessmentCoordinator.activity_state(lesson_id, "rhythm") == "NOT_STARTED")
	assert(LessonAssessmentCoordinator.activity_state(lesson_id, "melody") == "NOT_STARTED")
	assert(not LessonAssessmentCoordinator.is_complete(lesson_id))

	var p0 := LessonAssessmentCoordinator.progress(lesson_id)
	assert(p0.get("done") == 0 and p0.get("total") == 4)

	# Record 1 quiz -> quiz state becomes IN_PROGRESS
	LessonAssessmentCoordinator.record_quiz(lesson_id, 10, "Đô")
	assert(LessonAssessmentCoordinator.activity_state(lesson_id, "quiz") == "IN_PROGRESS")
	assert(not LessonAssessmentCoordinator.is_complete(lesson_id))

	# Record 2nd quiz -> quiz state becomes COMPLETE
	LessonAssessmentCoordinator.record_quiz(lesson_id, 11, "Sol")
	assert(LessonAssessmentCoordinator.activity_state(lesson_id, "quiz") == "COMPLETE")
	assert(not LessonAssessmentCoordinator.is_complete(lesson_id))

	# Record rhythm minigame
	LessonAssessmentCoordinator.record_minigame(lesson_id, 20, 95, "2026-09-07T10:00:00Z", "2026-09-07T10:02:00Z")
	assert(LessonAssessmentCoordinator.activity_state(lesson_id, "rhythm") == "COMPLETE")
	assert(not LessonAssessmentCoordinator.is_complete(lesson_id))

	# Record melody minigame -> all completed!
	LessonAssessmentCoordinator.record_minigame(lesson_id, 21, 100, "2026-09-07T10:02:00Z", "2026-09-07T10:05:00Z")
	assert(LessonAssessmentCoordinator.activity_state(lesson_id, "melody") == "COMPLETE")
	assert(LessonAssessmentCoordinator.is_complete(lesson_id))

	var p_full := LessonAssessmentCoordinator.progress(lesson_id)
	assert(p_full.get("done") == 4 and p_full.get("total") == 4)

	var payload := LessonAssessmentCoordinator.payload(lesson_id)
	assert(not payload.is_empty())
	assert((payload.get("quizAnswers") as Array).size() == 2)
	assert((payload.get("minigameResults") as Array).size() == 2)
	assert(not str(payload.get("clientSessionId", "")).is_empty())

	# Clear draft
	LessonAssessmentCoordinator.clear(lesson_id)
	assert(not LessonAssessmentCoordinator.is_complete(lesson_id))
	assert(LessonAssessmentCoordinator.progress(lesson_id).get("total") == 0)
	print("  [PASS] Draft registration, partial/full progress, payload and clearing work properly")

func _test_exact_be_resolution() -> void:
	# Install a test catalog
	var instruments := [{"id": 1, "instrumentCode": "dan_tranh", "name": "Đàn tranh"}]
	var lessons := [
		{"id": 1, "instrument": {"id": 1, "instrumentCode": "dan_tranh"}, "orderIndex": 1, "title": "Bài 1"},
		{"id": 2, "instrument": {"id": 1, "instrumentCode": "dan_tranh"}, "orderIndex": 2, "title": "Bài 2"},
		{"id": 5, "instrument": {"id": 1, "instrumentCode": "dan_tranh"}, "orderIndex": 3, "title": "Bài 3"}
	]
	SecureDataManager.install_be_catalog(instruments, lessons)

	# Exact matches
	var resolved_node1 := SecureDataManager.resolve_be_lesson_exact("dan_tranh", "Node1")
	assert(int(resolved_node1.get("id")) == 1)

	var resolved_node2 := SecureDataManager.resolve_be_lesson_exact("dan_tranh", "Node2")
	assert(int(resolved_node2.get("id")) == 2)

	# Non-existent node in catalog -> must return empty dictionary, NOT fallback
	var resolved_unknown := SecureDataManager.resolve_be_lesson_exact("dan_tranh", "Node99")
	assert(resolved_unknown.is_empty())

	# Different instrument without match -> must return empty dictionary
	var resolved_wrong_inst := SecureDataManager.resolve_be_lesson_exact("sao_truc", "Node10")
	assert(resolved_wrong_inst.is_empty())

	print("  [PASS] resolve_be_lesson_exact strictly matches without fallback to incorrect lessons")

func _test_queue_idempotency_and_unlock() -> void:
	var client_id := "test-session-12345"
	SecureDataManager.remove_pending_game_attempt(client_id)

	var attempt := {
		"kind": "lesson_assessment",
		"lesson_id": 100,
		"client_attempt_id": client_id,
		"payload": {"score": 90}
	}

	# Enqueue once
	SecureDataManager.enqueue_pending_game_attempt(attempt)
	var count1 := _count_attempts(client_id)
	assert(count1 == 1)

	# Enqueue same attempt again -> idempotency prevents duplicate
	SecureDataManager.enqueue_pending_game_attempt(attempt)
	var count2 := _count_attempts(client_id)
	assert(count2 == 1)

	# Test confirmed completion unlocks next node
	SecureDataManager.apply_confirmed_lesson_completion("dan_tranh", "Node1", 3)
	assert(SecureDataManager.is_lesson_completed("dan_tranh", "Node1"))
	assert(SecureDataManager.data.get("stars", {}).get("dan_tranh", {}).get("Node1", 0) == 3)
	assert(SecureDataManager.data.get("unlocked_lessons", {}).get("dan_tranh", []).has("Node2"))

	# Clean up
	SecureDataManager.remove_pending_game_attempt(client_id)
	assert(_count_attempts(client_id) == 0)
	print("  [PASS] Queue idempotency, deduplication and confirmed unlocks work as expected")

func _count_attempts(client_attempt_id: String) -> int:
	var count := 0
	for item: Variant in SecureDataManager.get_pending_game_attempts():
		if item is Dictionary and str((item as Dictionary).get("client_attempt_id", "")) == client_attempt_id:
			count += 1
	return count
