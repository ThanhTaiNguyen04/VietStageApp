extends SceneTree

const AuthSessionStore = preload("res://scripts/AuthSession.gd")
const ReportScript = preload("res://scripts/BackendReport.gd")
const Secure = preload("res://scripts/SecureDataManager.gd")

class FakeApi extends Node:
	var pages: Array[int] = []
	var quiz_requests := 0

	func get_instruments() -> Dictionary:
		return {"status": 200, "body": {"data": [{"id": 1, "instrumentCode": "dan_tranh"}]}}

	func get_lessons(_instrument_id: int, _skill_level_id: int, status: String, page: int, size: int, is_visible: bool) -> Dictionary:
		pages.append(page)
		assert(size == 100 and status == "APPROVED" and is_visible)
		var content: Array = []
		if page == 1:
			for index in 100:
				content.append({"id": index + 100, "orderIndex": index + 2, "instrument": {"id": 2, "instrumentCode": "sao_truc"}})
		else:
			content.append({"id": 50, "orderIndex": 1, "instrument": {"id": 1, "instrumentCode": "dan_tranh"}})
		return {"status": 200, "body": {"data": {"content": content, "totalPages": 2}}}

	func get_lesson_quizzes(lesson_id: int) -> Dictionary:
		quiz_requests += 1
		return {"status": 200, "body": {"data": [{"id": 500, "status": "ACTIVE", "question": "Lesson 50", "options": "[\"A\",\"B\",\"C\",\"D\"]"}] if lesson_id == 50 else []}}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	AuthSessionStore.ensure_loaded()
	AuthSessionStore.access_token = "pagination-test-token"
	var report = ReportScript.new()
	var fake = FakeApi.new()
	report._api = fake
	await report.fetch_and_install_catalog()
	var lesson: Dictionary = Secure.resolve_be_lesson("dan_tranh", "Node1")
	if fake.pages != [1, 2] or Secure.be_catalog.size() != 101 or int(lesson.get("id", 0)) != 50:
		printerr("Quiz catalog pagination FAIL")
		quit(1)
		return
	Secure.cache_be_quizzes(50, [])
	var quizzes: Array = await report.fetch_quizzes_for_level("dan_tranh", ["Node1"], true)
	if fake.quiz_requests != 1 or quizzes.size() != 1 or int(quizzes[0].get("lesson_id", 0)) != 50:
		printerr("Quiz lesson 50 refresh FAIL")
		quit(1)
		return
	report.free()
	fake.free()
	print("Quiz catalog pagination, lesson 50 binding and refresh PASS")
	quit()
