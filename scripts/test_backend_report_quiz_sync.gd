extends SceneTree

const AuthSessionStore = preload("res://scripts/AuthSession.gd")
const Secure = preload("res://scripts/SecureDataManager.gd")
const BackendReport = preload("res://scripts/BackendReport.gd")

class FakeApi extends Node:
	var response: Dictionary = {}
	var completion_response: Dictionary = {}
	var quiz_attempt_ids: Array[String] = []

	func submit_quiz_attempt(_quiz_id: int, _selected: String, attempt_id: String) -> Dictionary:
		quiz_attempt_ids.append(attempt_id)
		return response

	func error_message(_response: Dictionary, fallback: String) -> String:
		return fallback

	func complete_lesson_progress(_lesson_id: int, _attempt_id: String, _completed_at: String, _score: float) -> Dictionary:
		return completion_response

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	AuthSessionStore.ensure_loaded()
	AuthSessionStore.access_token = "sync-test-token"
	Secure.load_data()
	var original_data: Dictionary = Secure.data.duplicate(true)
	var original_catalog: Array = Secure.be_catalog.duplicate(true)
	Secure.data["pending_game_attempts"] = []

	var report := BackendReport.new()
	get_root().add_child(report)
	var fake := FakeApi.new()
	fake.response = {
		"status": 201,
		"body": {"data": {"id": 12, "isCorrect": true, "score": 100, "pointsEarned": 10, "starsEarned": 2, "spendableStars": 5}}
	}
	report._api = fake
	var success: Dictionary = await report.report_quiz(10, "Đô", {"score": 100, "maxScore": 100})
	assert(success.get("submitted") == true)
	assert(success.get("points_earned") == 10)
	assert(success.get("spendable_stars") == 5)
	assert(Secure.get_pending_game_attempts().is_empty())

	fake.response = {"status": 0, "body": {}, "message": "offline"}
	var failed: Dictionary = await report.report_quiz(10, "Rê", {"score": 0, "maxScore": 100})
	assert(failed.get("submitted") == false)
	assert(failed.get("queued") == true)
	assert(Secure.get_pending_game_attempts().size() == 1)

	# A nominal success without data.id is not a persistence acknowledgement.
	fake.response = {"status": 201, "body": {"data": {"score": 100, "pointsEarned": 10}}}
	var missing_id: Dictionary = await report.report_quiz(10, "Fa", {"score": 100, "maxScore": 100})
	assert(missing_id.get("submitted") == false)
	assert(missing_id.get("queued") == true)
	assert(Secure.get_pending_game_attempts().size() == 2)
	# HTTP 202 is not a confirmed reward, even if an intermediate response has an id.
	fake.response = {"status": 202, "body": {"data": {"id": 99, "pointsEarned": 10, "starsEarned": 2}}}
	var accepted: Dictionary = await report.report_quiz(10, "Mi")
	assert(accepted.get("submitted") == false)
	assert(Secure.get_pending_game_attempts().size() == 3)
	var queued_ids: Array[String] = []
	for item: Dictionary in Secure.get_pending_game_attempts():
		queued_ids.append(str(item.get("client_attempt_id", "")))

	# Retrying either queued item removes it only after a persisted id arrives.
	fake.response = {"status": 201, "body": {"data": {"id": 13, "score": 100, "pointsEarned": 10}}}
	await report.retry_pending_game_attempts()
	assert(Secure.get_pending_game_attempts().is_empty())
	for queued_id: String in queued_ids:
		assert(fake.quiz_attempt_ids.count(queued_id) >= 2)

	# A queued completion is not progress. It remains pending until the backend
	# explicitly returns completed=true; stars are not awarded for HTTP 202.
	Secure.be_catalog = [{"id": 99, "orderIndex": 1, "instrument": {"instrumentCode": "dan_tranh"}, "title": "Bài kiểm thử"}]
	fake.completion_response = {"status": 202, "body": {}, "message": "queued"}
	var pending_completion: Dictionary = await report.report_lesson_completion("dan_tranh", "Node1", 100.0)
	assert(pending_completion.get("submitted") == false)
	assert(pending_completion.get("queued") == true)
	assert(Secure.get_pending_game_attempts().size() == 1)
	fake.completion_response = {"status": 201, "body": {"data": {"completed": false, "lessonStars": 3}}}
	await report.retry_pending_game_attempts()
	assert(Secure.get_pending_game_attempts().size() == 1)
	fake.completion_response = {"status": 201, "body": {"data": {"completed": true, "lessonStars": 3, "starsEarned": 3, "totalStars": 3}}}
	await report.retry_pending_game_attempts()
	assert(Secure.get_pending_game_attempts().is_empty())
	# Missing bundled content is retained for later binding, without fake stars.
	Secure.be_catalog = [{"id": 50, "lessonCode": "dan_tranh_level_1_bai_1_video", "instrument": {"name": "Đàn Tranh"}}]
	var missing: Dictionary = await report.report_lesson_completion("sao_truc", "Node42", 100.0)
	assert(missing.get("queued") == true)
	assert(Secure.get_lesson_learning_status("sao_truc", "Node42") == "PENDING_SYNC")
	assert(not Secure.is_lesson_completed("sao_truc", "Node42"))
	await report.retry_pending_game_attempts()
	assert(Secure.get_pending_game_attempts().size() == 1)
	Secure.be_catalog.append({"id": 142, "lessonCode": "Node42", "instrument": {"name": "Sáo"}})
	fake.completion_response = {"status": 200, "body": {"data": {"completed": true, "lessonStars": 3}}}
	await report.retry_pending_game_attempts()
	assert(Secure.get_pending_game_attempts().is_empty())
	assert(Secure.is_lesson_completed("sao_truc", "Node42"))
	Secure.be_catalog = original_catalog

	Secure.data = original_data
	Secure.save_data()
	print("BackendReport quiz ACK and offline queue PASS")
	quit()
