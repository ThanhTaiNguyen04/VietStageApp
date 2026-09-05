extends SceneTree

const AuthSessionStore = preload("res://scripts/AuthSession.gd")
const Secure = preload("res://scripts/SecureDataManager.gd")
const BackendReport = preload("res://scripts/BackendReport.gd")

class FakeApi extends Node:
	var response: Dictionary = {}

	func submit_quiz_attempt(_quiz_id: int, _selected: String, _attempt_id: String) -> Dictionary:
		return response

	func error_message(_response: Dictionary, fallback: String) -> String:
		return fallback

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	AuthSessionStore.ensure_loaded()
	AuthSessionStore.access_token = "sync-test-token"
	Secure.load_data()
	var original_pending: Array = Secure.data.get("pending_game_attempts", []).duplicate(true)
	Secure.data["pending_game_attempts"] = []

	var report := BackendReport.new()
	get_root().add_child(report)
	var fake := FakeApi.new()
	fake.response = {
		"status": 201,
		"body": {"data": {"id": 12, "isCorrect": true, "score": 100, "pointsEarned": 10, "starsEarned": 2}}
	}
	report._api = fake
	var success: Dictionary = await report.report_quiz(10, "Đô", {"score": 100, "maxScore": 100})
	assert(success.get("submitted") == true)
	assert(success.get("points_earned") == 10)
	assert(Secure.get_pending_game_attempts().is_empty())

	fake.response = {"status": 0, "body": {}, "message": "offline"}
	var failed: Dictionary = await report.report_quiz(10, "Rê", {"score": 0, "maxScore": 100})
	assert(failed.get("submitted") == false)
	assert(failed.get("queued") == true)
	assert(Secure.get_pending_game_attempts().size() == 1)

	Secure.data["pending_game_attempts"] = original_pending
	Secure.save_data()
	print("BackendReport quiz ACK and offline queue PASS")
	quit()
