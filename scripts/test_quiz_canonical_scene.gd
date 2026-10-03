extends SceneTree

const Auth = preload("res://scripts/AuthSession.gd")
const Context = preload("res://scripts/LearningActivityContext.gd")
const Secure = preload("res://scripts/SecureDataManager.gd")

class FakeApi extends Node:
	var requested: Array[int] = []
	var catalog_requests := 0
	var fail_quiz_reads := false
	func get_lessons(_instrument_id: int, _skill_level_id: int, status: String, page: int, size: int, is_visible: bool, search: String = "") -> Dictionary:
		catalog_requests += 1
		if status != "APPROVED" or page != 1 or size != 20 or not is_visible or search != "Tìm hiểu nhạc cụ Đàn tranh":
			return {"status": 400, "body": {}}
		return {"status": 200, "body": {"data": {"content": [{
			"id": 1597, "orderIndex": 1, "lessonCode": "dan_tranh_level_1_bai_1_practice",
			"title": "Tìm hiểu nhạc cụ Đàn tranh", "instrument": {"instrumentCode": "dan_tranh"}
		}], "totalPages": 1}}}
	func submit_quiz_attempt(_quiz_id: int, _selected_answer: String, _attempt_id: String) -> Dictionary:
		return {"status": 503, "body": {}}
	func error_message(_response: Dictionary, fallback: String) -> String:
		return fallback
	func get_lesson_quizzes(lesson_id: int) -> Dictionary:
		requested.append(lesson_id)
		if fail_quiz_reads:
			return {"status": 0, "body": {}}
		await get_tree().create_timer(8.2).timeout
		return {"status": 200, "body": {"data": [{
			"id": 9001, "status": "ACTIVE", "questionType": "NOTE_IDENTIFICATION",
			"question": "Not tren khuong nhac la not gi?", "note": "Sol",
			"options": "[\"Sol\",\"La\",\"Do\",\"Re\"]", "correctAnswer": null
		}] if lesson_id == 1597 else []}}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	Auth.ensure_loaded()
	Auth.access_token = "test-only"
	Context.configure("dan_tranh", ["dan_tranh_level_1_bai_1_video"], "res://scenes/MainMenu.tscn")
	Context.activity = "quiz_note"
	Secure.be_catalog = [
		{"id": 50, "orderIndex": 1, "lessonCode": "LSN-DT-001", "title": "Bài khác", "instrument": {"instrumentCode": "dan_tranh"}},
		{"id": 1597, "orderIndex": 1, "lessonCode": "LSN-DT-1597", "title": "Tìm hiểu nhạc cụ Đàn tranh", "instrument": {"instrumentCode": "dan_tranh"}}
	]
	var duplicate := {"id": 1598, "orderIndex": 1, "lessonCode": "LSN-DT-1598", "title": "Tìm hiểu nhạc cụ Đàn tranh", "instrument": {"instrumentCode": "dan_tranh"}}
	Secure.be_catalog.append(duplicate)
	if not Secure.resolve_be_lesson_exact("dan_tranh", "dan_tranh_level_1_bai_1_video").is_empty():
		printerr("FAIL: duplicate lesson titles must not select an arbitrary quiz")
		quit(1)
		return
	Secure.be_catalog.pop_back()
	if int(Secure.resolve_be_lesson_exact("dan_tranh", "Node1").get("id", 0)) != 1597:
		printerr("FAIL: legacy Node1 did not resolve the first instructor lesson")
		quit(1)
		return
	Secure.be_catalog.clear()
	Secure.be_quizzes.clear()
	var report = root.get_node("BackendReport")
	var fake = FakeApi.new()
	report.add_child(fake)
	report.set("_api", fake)
	var screen = load("res://scenes/LearningQuizScreen.tscn").instantiate()
	root.add_child(screen)
	await create_timer(8.1).timeout
	if not screen.get("_backend_fetch_timed_out"):
		printerr("FAIL: delayed response did not exercise waiting state")
		quit(1)
		return
	await create_timer(0.5).timeout
	if fake.catalog_requests != 1 or fake.requested != [1597] or screen.get("quizzes").size() != 1:
		printerr("FAIL: canonical lesson quiz did not load after waiting: ", fake.requested)
		quit(1)
		return
	var options: GridContainer = screen.get("options_box")
	if options.get_child_count() != 4 or not options.is_visible_in_tree():
		printerr("FAIL: learner options are not visible")
		quit(1)
		return
	print("PASS: canonical lesson 1597, repeated orderIndex, hidden answer, delayed response and four visible options")
	screen.queue_free()
	await process_frame
	fake.fail_quiz_reads = true
	var cached_screen = load("res://scenes/LearningQuizScreen.tscn").instantiate()
	root.add_child(cached_screen)
	await process_frame
	if (cached_screen.get("quizzes") as Array).size() != 1 or fake.requested != [1597]:
		printerr("FAIL: a second network failure hid the quiz cached by the activity screen")
		quit(1)
		return
	print("PASS: cached quiz remains visible when the next API request fails")
	cached_screen.queue_free()
	quit(0)
