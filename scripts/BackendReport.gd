extends Node
## BackendReport autoload — reports learner results to the VietStage backend.

signal activity_history_changed
##
## Owns a single ApiClient and routes practice/minigame/quiz/daily-challenge
## submissions. All submission methods are best-effort: when the learner is
## offline, unsigned, or the local lesson has no reliable BE binding, they
## return { "submitted": false, "reason": ... } and callers keep the local
## save file as source of truth (graceful skip).

const AuthSessionStore = preload("res://scripts/AuthSession.gd")
const ApiClientScript = preload("res://scripts/ApiClient.gd")
const LearningActivityContext = preload("res://scripts/LearningActivityContext.gd")
const LessonAssessmentCoordinator = preload("res://scripts/LessonAssessmentCoordinator.gd")

var _api: Node = null
var _retry_pending_in_progress := false
var _active_practice_session_id := 0
var _active_practice_session_key := ""
var _usage_session_id := ""
var _usage_session_user_code := ""
var _usage_session_starting := false
var _usage_session_ending := false
var _usage_session_paused := false
var _usage_session_needs_end := false
var _usage_session_retry_at := 0.0
var _usage_session_check_elapsed := 0.0
var last_minigame_fetch_succeeded := true
var last_minigame_fetch_error := ""
var last_quiz_fetch_succeeded := true
var _instrument_quizzes: Dictionary = {}


func _ready() -> void:
	_api = ApiClientScript.new()
	add_child(_api)
	call_deferred("retry_pending_game_attempts")


func _process(delta: float) -> void:
	_usage_session_check_elapsed += delta
	if _usage_session_check_elapsed < 3.0:
		return
	_usage_session_check_elapsed = 0.0
	if _usage_session_paused or _usage_session_starting or _usage_session_ending:
		return
	if _usage_session_needs_end and not _usage_session_id.is_empty() and is_signed_in():
		await end_usage_session()
		if not _usage_session_id.is_empty():
			return
	if not is_signed_in():
		_usage_session_id = ""
		_usage_session_user_code = ""
		_usage_session_needs_end = false
		_usage_session_retry_at = 0.0
		return
	var user_code := AuthSessionStore.user_code
	if not _usage_session_id.is_empty() and _usage_session_user_code != user_code:
		await end_usage_session()
	if _usage_session_id.is_empty() and Time.get_unix_time_from_system() >= _usage_session_retry_at:
		await _start_usage_session()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_usage_session_paused = true
		_usage_session_needs_end = true
		end_usage_session()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_usage_session_paused = false
		_usage_session_retry_at = 0


func _start_usage_session() -> void:
	if _usage_session_starting or _usage_session_ending or not is_signed_in():
		return
	_usage_session_starting = true
	var user_code := AuthSessionStore.user_code
	var response: Dictionary = await _api.start_usage_session()
	_usage_session_starting = false
	if _is_success(response) and response.get("body", {}).get("success", true) != false:
		var response_data: Variant = response.get("body", {}).get("data", {})
		if response_data is Dictionary:
			var session_id := str(response_data.get("sessionId", ""))
			if session_id.is_empty():
				for value: Variant in response_data.values():
					if value is String and str(value).length() == 36:
						session_id = str(value)
						break
			if not session_id.is_empty():
				_usage_session_id = session_id
				_usage_session_user_code = user_code
				if _usage_session_paused or not is_signed_in() or AuthSessionStore.user_code != user_code:
					await end_usage_session()
				return
	# Avoid creating a new session on every frame while the service is unavailable.
	_usage_session_retry_at = Time.get_unix_time_from_system() + 60


func end_usage_session() -> void:
	if _usage_session_ending or _usage_session_id.is_empty():
		return
	_usage_session_ending = true
	var session_id := _usage_session_id
	var response: Dictionary = await _api.end_usage_session(session_id)
	_usage_session_ending = false
	if _is_success(response) and response.get("body", {}).get("success", true) != false and _usage_session_id == session_id:
		_usage_session_id = ""
		_usage_session_user_code = ""
		_usage_session_needs_end = false


func is_signed_in() -> bool:
	return _api != null and AuthSessionStore.has_access_token()

# ── Catalog bootstrap ──────────────────────────────────────────────────

## Tải GET /api/instruments + GET /api/lessons và cài vào SecureDataManager.
## Được MainMenu gọi sau khi đăng nhập để sẵn sàng resolve exercise/lesson.
func fetch_and_install_catalog() -> void:
	if not is_signed_in():
		return
	var instruments_response: Dictionary = await _api.get_instruments()
	var instruments: Array = _extract_array(instruments_response)
	var lessons: Array = []
	var page := 1
	while true:
		var response: Dictionary = await _api.get_lessons(0, 0, "APPROVED", page, 100, true)
		if not _is_success(response):
			return
		var items := _extract_array(response)
		lessons.append_array(items)
		var page_data: Variant = response.get("body", {}).get("data", {})
		if items.is_empty() or not page_data is Dictionary or page >= int(page_data.get("totalPages", 1)):
			break
		page += 1
	if instruments.is_empty() and lessons.is_empty():
		return
	SecureDataManager.install_be_catalog(instruments, lessons)
	await retry_pending_game_attempts()


## Làm mới lộ trình và tổng sao từ backend.
func refresh_progress_from_backend() -> Dictionary:
	if not is_signed_in():
		return {"synced": false, "reason": "not_signed_in"}
	if SecureDataManager.be_catalog.is_empty():
		await fetch_and_install_catalog()
	var course_response: Dictionary = await _api.get_app_course_progress()
	var progress_response: Dictionary = await _api.get_my_progress()
	var summary_response: Dictionary = await _api.get_my_progress_summary()
	var progress_synced := false
	var summary_synced := false
	if _is_success(course_response):
		var course_data: Variant = course_response.get("body", {}).get("data", {})
		if course_data is Dictionary:
			progress_synced = SecureDataManager.sync_backend_course_progress(course_data)
	if _is_success(progress_response):
		var progress_data: Variant = progress_response.get("body", {}).get("data", [])
		if progress_data is Array:
			SecureDataManager.sync_backend_progress(progress_data)
			progress_synced = true
	if _is_success(summary_response):
		var summary_data: Variant = summary_response.get("body", {}).get("data", {})
		if summary_data is Dictionary:
			SecureDataManager.sync_backend_summary(summary_data)
			summary_synced = true
	return {"synced": progress_synced and summary_synced}


## Ghi nhận bắt đầu bài qua backend. Khi offline/lỗi mạng, caller vẫn có thể
## mở dữ liệu bundled làm backup nhưng không tự đổi trạng thái server.
func start_lesson(instrument: String, local_lesson_id: String) -> Dictionary:
	if not is_signed_in():
		return {"submitted": false, "reason": "not_signed_in"}
	if SecureDataManager.be_catalog.is_empty():
		await fetch_and_install_catalog()
	var lesson := SecureDataManager.resolve_be_lesson_exact(instrument, local_lesson_id)
	var lesson_id := int(lesson.get("id", 0))
	if lesson_id <= 0:
		return {"submitted": false, "reason": "lesson_binding_mismatch"}
	var response: Dictionary = await _api.start_app_course_lesson(lesson_id)
	if not _is_success(response):
		return {"submitted": false, "reason": "server_rejected", "status": int(response.get("status", 0))}
	var access: Variant = response.get("body", {}).get("data", {})
	if access is Dictionary and bool(access.get("isUnlocked", false)):
		var cached := SecureDataManager.get_backend_lesson_access(instrument, local_lesson_id)
		cached.merge(access, true)
		cached["lessonId"] = lesson_id
		var all_access: Variant = SecureDataManager.data.get("backend_lesson_access", {})
		if not all_access is Dictionary:
			all_access = {}
		SecureDataManager.data["backend_lesson_access"] = all_access
		all_access[str(lesson_id)] = cached
		SecureDataManager.save_data()
		return {"submitted": true, "access": cached}
	return {"submitted": false, "reason": "locked"}


## Hoàn thành một bài giáo trình hard-code bằng lessonId backend.
## Chỉ response thành công mới được ghi sao và mở khóa bài tiếp theo ở local cache.
func report_lesson_completion(
	instrument: String,
	local_lesson_id: String,
	score: float = -1.0
) -> Dictionary:
	if not is_signed_in():
		return {"submitted": false, "reason": "not_signed_in"}
	if SecureDataManager.be_catalog.is_empty():
		await fetch_and_install_catalog()
	var lesson: Dictionary = SecureDataManager.resolve_be_lesson_exact(instrument, local_lesson_id)
	if lesson.is_empty():
		SecureDataManager.enqueue_pending_game_attempt({
			"kind": "lesson_completion", "lesson_id": 0,
			"client_attempt_id": _uuid(), "completed_at": _iso_now(),
			"score": score, "instrument": instrument, "local_lesson_id": local_lesson_id,
			"title": "Hoàn thành bài học", "lessonTitle": local_lesson_id,
		})
		activity_history_changed.emit()
		return {"submitted": false, "queued": true, "reason": "lesson_binding_mismatch", "message": "Đã lưu kết quả bài học dự phòng. Máy chủ chưa có mã bài tương ứng; sao và tiến độ đang chờ đồng bộ."}
	var lesson_id := int(lesson.get("id", 0))
	var client_attempt_id := _uuid()
	var completed_at := _iso_now()
	var response: Dictionary = await _api.complete_lesson_progress(
		lesson_id,
		client_attempt_id,
		completed_at,
		score
	)
	var completion_data: Variant = response.get("body", {}).get("data", {})
	if not completion_data is Dictionary:
		completion_data = {}
	# HTTP 202 is an app-side queued request, never an acknowledgement. A lesson
	# only changes local progress once BE explicitly confirms completed=true.
	if _is_pending_response(response) or int(response.get("status", 0)) >= 500 or int(response.get("status", 0)) == 404:
		SecureDataManager.enqueue_pending_game_attempt({
			"kind": "lesson_completion", "lesson_id": lesson_id,
			"client_attempt_id": client_attempt_id, "completed_at": completed_at,
			"score": score, "instrument": instrument, "local_lesson_id": local_lesson_id,
			"title": "Hoàn thành bài học", "lessonTitle": str(lesson.get("title", "Bài học")),
		})
		activity_history_changed.emit()
		return {"submitted": false, "queued": true, "reason": "completion_pending", "message": "Kết quả đang chờ đồng bộ."}
	if not _is_server_acknowledged(response) or not bool(completion_data.get("completed", false)):
		return {
			"submitted": false,
			"reason": "completion_failed",
			"status": int(response.get("status", 0)),
			"message": _api.error_message(response, "Không thể ghi nhận hoàn thành bài học."),
		}
	var lesson_stars := int(completion_data.get(
		"lessonStars",
		completion_data.get("stars", completion_data.get("starsEarned", 0))
	))
	SecureDataManager.apply_confirmed_lesson_completion(instrument, local_lesson_id, lesson_stars)
	SecureDataManager.apply_backend_reward(completion_data)
	await refresh_progress_from_backend()
	return {
		"submitted": true,
		"lesson_id": lesson_id,
		"stars_earned": int(completion_data.get("starsEarned", completion_data.get("stars_earned", 0))),
		"lesson_stars": lesson_stars,
	}


func show_lesson_completion_result(parent: Node, result: Dictionary) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Kết quả bài học"
	dialog.ok_button_text = "Đóng"
	dialog.unresizable = true
	dialog.add_theme_font_size_override("title_font_size", 24)
	dialog.add_theme_font_size_override("font_size", 20)
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("#f8f5eb")
	panel.border_color = Color("#d8aa3e")
	panel.set_border_width_all(3)
	panel.set_corner_radius_all(14)
	panel.set_content_margin_all(24)
	dialog.add_theme_stylebox_override("panel", panel)
	dialog.add_theme_color_override("font_color", Color("#193e30"))
	dialog.add_theme_color_override("title_color", Color("#193e30"))
	if bool(result.get("submitted", false)):
		dialog.dialog_text = "Đã hoàn thành bài học!\nSao của bài: %d/3\nSao nhận thêm: %d" % [int(result.get("lesson_stars", 0)), int(result.get("stars_earned", 0))]
	elif bool(result.get("queued", false)):
		dialog.dialog_text = str(result.get("message", "Đã lưu kết quả, đang chờ đồng bộ.")) + "\nSao và tiến độ sẽ cập nhật khi máy chủ xác nhận."
	else:
		dialog.dialog_text = str(result.get("message", "Chưa ghi nhận được kết quả. Vui lòng đăng nhập và thử lại."))
	parent.add_child(dialog)
	dialog.popup_centered(Vector2i(620, 260))
	await dialog.visibility_changed
	dialog.queue_free()


## Đảm bảo exercises của một lesson được cache vào SecureDataManager.
func ensure_exercises(lesson_id: int) -> Dictionary:
	if SecureDataManager.be_exercises.has(lesson_id):
		var cached: Array = SecureDataManager.be_exercises[lesson_id]
		return cached[0] if not cached.is_empty() else {}
	var response: Dictionary = await _api.get_lesson_exercises(lesson_id)
	if not _is_success(response):
		return {}
	var exercises: Array = _extract_array(response)
	SecureDataManager.cache_be_exercises(lesson_id, exercises)
	return exercises[0] if not exercises.is_empty() else {}


## Đảm bảo quizzes của một lesson được cache vào SecureDataManager.
func _active_activity_items(items: Array) -> Array:
	var active: Array = []
	for value: Variant in items:
		if value is Dictionary and str(value.get("status", "ACTIVE")).to_upper() == "ACTIVE":
			active.append(value)
	return active


func ensure_quizzes(lesson_id: int, force_refresh: bool = false) -> Array:
	if not force_refresh and SecureDataManager.be_quizzes.has(lesson_id):
		return SecureDataManager.be_quizzes[lesson_id]
	var response: Dictionary = await _api.get_lesson_quizzes(lesson_id)
	if not _is_success(response):
		last_quiz_fetch_succeeded = false
		return []
	var quizzes: Array = _active_activity_items(_extract_array(response))
	SecureDataManager.cache_be_quizzes(lesson_id, quizzes)
	return quizzes


## Resolve the selected quiz lessons with a small title query. A full catalog
## response can exceed the API timeout, leaving the quiz screen waiting.
func ensure_quiz_catalog(instrument: String, local_lesson_ids: Array) -> void:
	for local_id: Variant in local_lesson_ids:
		if not SecureDataManager.resolve_be_lesson_exact(instrument, str(local_id)).is_empty():
			continue
		var title := SecureDataManager.bundled_lesson_title(instrument, str(local_id))
		if title.is_empty():
			if SecureDataManager.be_catalog.is_empty():
				await fetch_and_install_catalog()
			continue
		var response: Dictionary = await _api.get_lessons(0, 0, "APPROVED", 1, 20, true, title)
		if not _is_success(response):
			last_quiz_fetch_succeeded = false
			continue
		var page_data: Variant = response.get("body", {}).get("data", {})
		if page_data is Dictionary and int(page_data.get("totalPages", 1)) > 1:
			last_quiz_fetch_succeeded = false
			continue
		for lesson: Variant in _extract_array(response):
			if lesson is Dictionary and not SecureDataManager.be_catalog.any(func(item: Variant) -> bool:
				return item is Dictionary and int(item.get("id", 0)) == int(lesson.get("id", 0))
			):
				SecureDataManager.be_catalog.append(lesson)


func cached_quizzes_for_level(instrument: String, _local_lesson_ids: Array) -> Array:
	return _active_activity_items(_instrument_quizzes.get(instrument, []))


## Instrument quizzes are independent of lesson completion assessments.
func fetch_quizzes_for_level(instrument: String, _local_lesson_ids: Array, _force_refresh: bool = false) -> Array:
	last_quiz_fetch_succeeded = false
	var instrument_id := SecureDataManager.be_instrument_id(instrument)
	if instrument_id <= 0:
		var instruments_response: Dictionary = await _api.get_instruments()
		if not _is_success(instruments_response):
			return []
		SecureDataManager.be_instruments = _extract_array(instruments_response)
		instrument_id = SecureDataManager.be_instrument_id(instrument)
	if instrument_id <= 0:
		return []
	var response: Dictionary = await _api.get_instrument_quizzes(instrument_id)
	if not _is_success(response):
		return []
	last_quiz_fetch_succeeded = true
	var quizzes: Array = _active_activity_items(_extract_array(response))
	_instrument_quizzes[instrument] = quizzes.duplicate(true)
	return quizzes


func ensure_minigame_list(lesson_id: int, force_refresh: bool = false) -> Array:
	if not force_refresh and SecureDataManager.be_minigames.has(lesson_id):
		return SecureDataManager.be_minigames[lesson_id]
	var response: Dictionary = await _api.get_lesson_minigames(lesson_id)
	if not _is_success(response):
		last_minigame_fetch_succeeded = false
		last_minigame_fetch_error = _api.error_message(response, "Không thể tải danh sách minigame từ máy chủ.")
		return []
	var minigames: Array = _active_activity_items(_extract_array(response))
	SecureDataManager.cache_be_minigames(lesson_id, minigames)
	return minigames


func fetch_minigames_for_level(instrument: String, local_lesson_ids: Array, expected_challenge_type: String = "", force_refresh: bool = true) -> Array:
	last_minigame_fetch_succeeded = true
	last_minigame_fetch_error = ""
	if SecureDataManager.be_catalog.is_empty():
		await fetch_and_install_catalog()
	var result: Array = []
	var bound_ids: Array[int] = []
	var seen_ids: Dictionary = {}
	var normalized_expected := expected_challenge_type.to_upper().replace("-", "_").replace(" ", "_")

	# 1. Quét theo các local lesson ID được truyền vào từ Context
	for lesson_position in local_lesson_ids.size():
		var local_id: Variant = local_lesson_ids[lesson_position]
		var lesson: Dictionary = SecureDataManager.resolve_be_lesson(instrument, str(local_id))
		if lesson.is_empty():
			continue
		var lesson_id := int(lesson.get("id", 0))
		if lesson_id <= 0:
			continue
		LearningActivityContext.set_backend_lesson(lesson)
		bound_ids.append(lesson_id)
		var minigames: Array = await ensure_minigame_list(lesson_id, force_refresh)
		for item_value: Variant in minigames:
			if not item_value is Dictionary:
				continue
			var item: Dictionary = item_value
			var actual := str(item.get("challengeType", item.get("challenge_type", ""))).to_upper().replace("-", "_").replace(" ", "_")
			if not normalized_expected.is_empty():
				var matches := false
				if normalized_expected == "RHYTHM_MATCH" and actual in ["RHYTHM_MATCH", "RHYTHM_MATCHING", "RHYTHM"]:
					matches = true
				elif normalized_expected in ["MELODY_COMPLETION", "MELODY_COMPLETE"] and actual in ["MELODY_COMPLETION", "MELODY_COMPLETE", "MELODY"]:
					matches = true
				elif actual == normalized_expected:
					matches = true
				if not matches:
					continue
			var item_id := int(item.get("id", 0))
			if item_id > 0 and seen_ids.has(item_id):
				continue
			if item_id > 0:
				seen_ids[item_id] = true
			var enriched := item.duplicate(true)
			enriched["lesson_id"] = lesson_id
			enriched["_lesson_position"] = lesson_position
			result.append(enriched)

	# 2. Nếu chưa tìm thấy minigame nào, tự động quét toàn bộ bài học của nhạc cụ đó
	# Assessment content must remain bound to the selected canonical lesson.
	if false and result.is_empty():
		var instrument_lesson_ids := SecureDataManager.be_lesson_ids_for_instrument(instrument)
		for lesson_id: int in instrument_lesson_ids:
			if bound_ids.has(lesson_id):
				continue
			var minigames: Array = await ensure_minigame_list(lesson_id, force_refresh)
			for item_value: Variant in minigames:
				if not item_value is Dictionary:
					continue
				var item: Dictionary = item_value
				var actual := str(item.get("challengeType", item.get("challenge_type", ""))).to_upper().replace("-", "_").replace(" ", "_")
				if not normalized_expected.is_empty():
					var matches := false
					if normalized_expected == "RHYTHM_MATCH" and actual in ["RHYTHM_MATCH", "RHYTHM_MATCHING", "RHYTHM"]:
						matches = true
					elif normalized_expected in ["MELODY_COMPLETION", "MELODY_COMPLETE"] and actual in ["MELODY_COMPLETION", "MELODY_COMPLETE", "MELODY"]:
						matches = true
					elif actual == normalized_expected:
						matches = true
					if not matches:
						continue
				var item_id := int(item.get("id", 0))
				if item_id > 0 and seen_ids.has(item_id):
					continue
				if item_id > 0:
					seen_ids[item_id] = true
				var enriched := item.duplicate(true)
				enriched["lesson_id"] = lesson_id
				result.append(enriched)


	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var lesson_a := int(a.get("_lesson_position", 0))
		var lesson_b := int(b.get("_lesson_position", 0))
		if lesson_a != lesson_b:
			return lesson_a < lesson_b
		return int(a.get("orderIndex", a.get("order_index", 0))) < int(b.get("orderIndex", b.get("order_index", 0)))
	)

	return result


func ensure_minigame_by_type(lesson_id: int, challenge_type: String) -> Dictionary:
	var minigames := await ensure_minigame_list(lesson_id)
	var expected := challenge_type.to_upper().replace("-", "_").replace(" ", "_")
	for item: Variant in minigames:
		if item is Dictionary:
			var actual := str(item.get("challengeType", item.get("challenge_type", ""))).to_upper().replace("-", "_").replace(" ", "_")
			var is_note_alias := expected == "NOTE_RECOGNITION" and actual in ["NOTE_IDENTIFICATION", "NOTE_RECOGNITION_QUIZ"]
			var is_melody_alias := (expected in ["MELODY_COMPLETION", "MELODY_COMPLETE"]) and (actual in ["MELODY_COMPLETION", "MELODY_COMPLETE"])
			if actual == expected or is_note_alias or is_melody_alias:
				return item
	return {}


func fetch_lesson_assets(lesson_id: int) -> Array:
	var response: Dictionary = await _api.get_lesson_assets(lesson_id)
	if not _is_success(response):
		return []
	return _extract_array(response)


## Tải lời hướng dẫn của đúng bài đang mở. Không thay đổi dữ liệu bundled;
## caller vẫn dùng bundled khi endpoint thiếu dữ liệu hoặc trả lỗi.
func fetch_lesson_teacher_speech(instrument: String, local_lesson_id: String) -> Array:
	if not is_signed_in():
		return []
	if SecureDataManager.be_catalog.is_empty():
		await fetch_and_install_catalog()
	var lesson := SecureDataManager.resolve_be_lesson_exact(instrument, local_lesson_id)
	if lesson.is_empty():
		return []
	var lesson_code := str(lesson.get("lessonCode", ""))
	if lesson_code.is_empty():
		return []
	var cached := SecureDataManager.get_be_teacher_speech(lesson_code)
	if not cached.is_empty():
		return cached
	var response: Dictionary = await _api.get_lesson_contents(int(lesson.get("id", 0)))
	if not _is_success(response):
		return []
	var steps := _teacher_speech_steps(_extract_array(response))
	if not steps.is_empty():
		SecureDataManager.cache_be_teacher_speech(lesson_code, steps)
		SecureDataManager.cache_be_teacher_speech(SecureDataManager.canonical_lesson_id(instrument, local_lesson_id), steps)
	return steps


func _teacher_speech_steps(contents: Array) -> Array:
	var ordered: Array[Dictionary] = []
	for raw_item: Variant in contents:
		if not raw_item is Dictionary:
			continue
		var item: Dictionary = raw_item
		var content_type := str(item.get("contentType", item.get("content_type", ""))).to_upper()
		# VIDEO_CUE/PRACTICE_INSTRUCTION must never replace bundled teacher
		# dialogue. They describe a separate activity, not a line spoken by Mai.
		if content_type not in ["TEACHER_SPEECH", "THEORY_TEXT", "TEXT"]:
			continue
		var text := str(item.get("contentText", item.get("content_text", item.get("text", "")))).strip_edges()
		if text.is_empty():
			continue
		var parsed: Variant = JSON.parse_string(text) if text.begins_with("{") else null
		if parsed is Dictionary:
			var document: Dictionary = parsed
			var blocks: Variant = document.get("blocks", [])
			if blocks is Array:
				for block_value: Variant in blocks:
					if block_value is Dictionary:
						var block: Dictionary = block_value
						var block_type := str(block.get("type", "")).to_upper()
						if block_type not in ["TEACHER_SPEECH", "THEORY_TEXT", "TEXT"]:
							continue
						var block_text := str(block.get("text", "")).strip_edges()
						if not block_text.is_empty():
							ordered.append({"order": int(item.get("orderIndex", item.get("order_index", 0))), "action": "speak", "text": block_text})
				continue
		ordered.append({"order": int(item.get("orderIndex", item.get("order_index", 0))), "action": "speak", "text": text})
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["order"]) < int(b["order"]))
	var steps: Array = []
	for item: Dictionary in ordered:
		steps.append({"action": "speak", "text": str(item["text"])})
	return steps


# ── Practice attempts ──────────────────────────────────────────────────

## Nộp kết quả lượt tập. scores keys: pitch, rhythm, dynamics,
## tonal_quality, breath (0..100). Returns Dictionary { submitted, ... }.
## Opens a session when the learner enters practice. The session remains open
## until submission or the practice scene exits, so duration is meaningful.
func begin_practice_session(instrument: String, local_lesson_id: String) -> Dictionary:
	if not is_signed_in():
		return {"started": false, "reason": "not_signed_in"}
	var lesson: Dictionary = SecureDataManager.resolve_be_lesson_exact(instrument, local_lesson_id)
	if lesson.is_empty():
		return {"started": false, "reason": "lesson_binding_mismatch"}
	var key := "%s:%s" % [instrument, local_lesson_id]
	if _active_practice_session_id > 0 and _active_practice_session_key == key:
		return {"started": true, "session_id": _active_practice_session_id}
	if _active_practice_session_id > 0:
		await _finish_active_practice_session()
	var response: Dictionary = await _api.start_practice_session()
	if not _is_success(response):
		return {"started": false, "reason": "session_failed", "status": int(response.get("status", 0))}
	var body: Dictionary = response.get("body", {})
	var session_data: Dictionary = body.get("data", {}) if body.get("data", {}) is Dictionary else {}
	var session_id := int(session_data.get("id", 0))
	if session_id <= 0:
		return {"started": false, "reason": "invalid_session"}
	_active_practice_session_id = session_id
	_active_practice_session_key = key
	return {"started": true, "session_id": session_id}


func end_practice_session(instrument: String, local_lesson_id: String) -> void:
	var key := "%s:%s" % [instrument, local_lesson_id]
	if _active_practice_session_key == key:
		await _finish_active_practice_session()


func _finish_active_practice_session() -> void:
	var session_id := _active_practice_session_id
	_active_practice_session_id = 0
	_active_practice_session_key = ""
	if session_id > 0 and is_signed_in():
		await _api.end_practice_session(session_id)


func report_practice(instrument: String, local_lesson_id: String, scores: Dictionary) -> Dictionary:
	if not is_signed_in():
		return {"submitted": false, "reason": "not_signed_in"}

	var lesson: Dictionary = SecureDataManager.resolve_be_lesson_exact(instrument, local_lesson_id)
	if lesson.is_empty():
		push_warning("[Practice] Không khớp lesson BE chính xác (orderIndex/legacy) cho %s — bỏ qua submit để tránh gửi nhầm lesson." % str(local_lesson_id))
		return {"submitted": false, "reason": "lesson_binding_mismatch"}
	var lesson_id := int(lesson.get("id", 0))

	var exercise: Dictionary = await ensure_exercises(lesson_id)
	if exercise.is_empty():
		return {"submitted": false, "reason": "no_exercise_binding"}
	var exercise_id := int(exercise.get("id", 0))

	var session_key := "%s:%s" % [instrument, local_lesson_id]
	var session_id := _active_practice_session_id if _active_practice_session_key == session_key else 0
	if session_id <= 0:
		var session_result := await begin_practice_session(instrument, local_lesson_id)
		if not bool(session_result.get("started", false)):
			return {"submitted": false, "reason": str(session_result.get("reason", "session_failed")), "status": int(session_result.get("status", 0))}
		session_id = int(session_result.get("session_id", 0))

	var attempt_response: Dictionary = await _api.submit_practice_attempt(
		session_id,
		exercise_id,
		float(scores.get("pitch", 0.0)),
		float(scores.get("rhythm", 0.0)),
		float(scores.get("dynamics", 0.0)),
		float(scores.get("tonal_quality", 0.0)),
		float(scores.get("breath", 0.0)),
		_uuid(),
		_iso_now()
	)
	await _finish_active_practice_session()

	if not _is_success(attempt_response):
		return {
			"submitted": false,
			"reason": "attempt_failed",
			"status": int(attempt_response.get("status", 0)),
			"message": _api.error_message(attempt_response, "Không thể đồng bộ lượt tập."),
		}

	var attempt_data: Dictionary = attempt_response.get("body", {}).get("data", {})
	if not attempt_data is Dictionary:
		attempt_data = {}
	SecureDataManager.apply_backend_reward(attempt_data)
	activity_history_changed.emit()
	return {
		"submitted": true,
		"lesson_id": lesson_id,
		"exercise_id": exercise_id,
		"session_id": session_id,
		"attempt_id": int(attempt_data.get("id", 0)),
		"stars": int(attempt_data.get("stars", 0)),
		"points_earned": int(attempt_data.get("points_earned", 0)),
		"total_score": float(attempt_data.get("total_score", 0.0)),
	}


## Luồng trọn vẹn cho một bài thực hành: lưu attempt trước, sau đó mới hoàn thành bài.
## Hàm nằm trong autoload để tiếp tục đồng bộ dù scene bài học đã chuyển đi.
func report_practice_and_complete(
	instrument: String,
	local_lesson_id: String,
	scores: Dictionary,
	completion_score: float
) -> Dictionary:
	var practice_result := await report_practice(instrument, local_lesson_id, scores)
	if not bool(practice_result.get("submitted", false)):
		return practice_result
	return await report_lesson_completion(instrument, local_lesson_id, completion_score)


# ── Minigame attempts ──────────────────────────────────────────────────

## Nộp kết quả khi client đã chọn chính xác challenge từ BE.
## Dùng cho các màn chơi có nhiều challenge trong cùng một lesson.
func report_minigame_by_id(minigame_id: int, score: int, _client_preview_stars: int, started_at: String = "", completed_at: String = "", client_attempt_id: String = "", play_data: String = "") -> Dictionary:
	if not is_signed_in():
		return {"submitted": false, "reason": "not_signed_in"}
	if minigame_id <= 0:
		return {"submitted": false, "reason": "invalid_minigame_id"}

	var start_value := started_at if not started_at.is_empty() else _iso_now()
	var complete_value := completed_at if not completed_at.is_empty() else _iso_now()
	var attempt_id := client_attempt_id if not client_attempt_id.is_empty() else _uuid()
	var response: Dictionary = await _api.submit_minigame_attempt(
		minigame_id,
		score,
		attempt_id,
		start_value,
		complete_value,
		play_data
	)
	var attempt_data := _attempt_data(response)
	# A 2xx response is not an acknowledgement unless it identifies the persisted
	# attempt. Without data.id the app must retain the same client id for retry.
	if not _is_success(response) or attempt_data.is_empty() or int(attempt_data.get("id", 0)) <= 0:
		SecureDataManager.enqueue_pending_game_attempt({
			"kind": "minigame", "minigame_id": minigame_id, "score": score,
			"started_at": start_value, "completed_at": complete_value, "client_attempt_id": attempt_id, "play_data": play_data,
		})
		activity_history_changed.emit()
		return {
			"submitted": false,
			"queued": true,
			"reason": "attempt_failed",
			"status": int(response.get("status", 0)),
			"message": _api.error_message(response, "Không thể đồng bộ điểm minigame."),
		}

	SecureDataManager.apply_backend_reward(attempt_data)
	activity_history_changed.emit()
	return {
		"submitted": true,
		"minigame_id": minigame_id,
		"attempt_id": int(attempt_data.get("id", 0)),
		"points_earned": int(attempt_data.get("pointsEarned", attempt_data.get("points_earned", 0))),
		"stars_earned": int(attempt_data.get("starsEarned", attempt_data.get("stars_earned", 0))),
	}


# ── Quiz attempts ──────────────────────────────────────────────────────

## Nộp đáp án trắc nghiệm. Returns Dictionary { submitted, ... }.
func report_quiz(quiz_id: int, selected_answer: String, pending_preview: Dictionary = {}) -> Dictionary:
	if not is_signed_in():
		return {"submitted": false, "reason": "not_signed_in"}
	if quiz_id <= 0:
		return {"submitted": false, "reason": "invalid_quiz_id"}
	var attempt_id := _uuid()
	var response: Dictionary = await _api.submit_quiz_attempt(quiz_id, selected_answer, attempt_id)
	var attempt_data := _attempt_data(response)
	# A network failure is represented by status 0. ApiClient deliberately does
	# not convert quiz POSTs into a generic 202 queue response; still require a
	# response body so a future async/empty 202 cannot be mistaken for a graded
	# attempt.
	# A 2xx response is not an acknowledgement unless it identifies the persisted
	# attempt. Without data.id the app must retain the same client id for retry.
	if not _is_server_acknowledged(response) or attempt_data.is_empty() or int(attempt_data.get("id", 0)) <= 0:
		_log_quiz_sync_failure("submit", quiz_id, response)
		var pending_attempt := pending_preview.duplicate(true)
		pending_attempt.merge({
			"kind": "quiz", "quiz_id": quiz_id, "selected_answer": selected_answer,
			"client_attempt_id": attempt_id,
		}, true)
		SecureDataManager.enqueue_pending_game_attempt(pending_attempt)
		activity_history_changed.emit()
		return {
			"submitted": false,
			"queued": true,
			"reason": "attempt_failed",
			"status": int(response.get("status", 0)),
			"message": _api.error_message(response, "Không thể nộp câu trắc nghiệm."),
		}
	SecureDataManager.apply_backend_reward(attempt_data)
	activity_history_changed.emit()
	return {
		"submitted": true,
		"quiz_id": quiz_id,
		"is_correct": bool(attempt_data.get("isCorrect", attempt_data.get("is_correct", false))),
		"points_earned": int(attempt_data.get("pointsEarned", attempt_data.get("points_earned", 0))),
		"stars_earned": int(attempt_data.get("starsEarned", attempt_data.get("stars_earned", 0))),
		"spendable_stars": int(attempt_data.get("spendableStars", attempt_data.get("spendable_stars", -1))),
		"correct_answer": str(attempt_data.get("correctAnswer", attempt_data.get("correct_answer", ""))),
		"score": float(attempt_data.get("score", 0.0)),
		"max_score": 100.0,
		"attempt_id": int(attempt_data.get("id", 0)),
		"completed_at": str(attempt_data.get("attemptedAt", attempt_data.get("attempted_at", ""))),
	}


## Submits the only authoritative assessment for one lesson. The payload is
## queued unchanged on any non-acknowledged response so retries are idempotent.
func report_lesson_assessment(lesson_id: int, payload: Dictionary) -> Dictionary:
	if not is_signed_in():
		return {"submitted": false, "reason": "not_signed_in"}
	if lesson_id <= 0:
		return {"submitted": false, "reason": "invalid_lesson_id"}
	var client_session_id := str(payload.get("clientSessionId", ""))
	if client_session_id.is_empty():
		return {"submitted": false, "reason": "missing_client_session_id"}
	var response: Dictionary = await _api.submit_lesson_assessment(lesson_id, payload)
	var assessment := _attempt_data(response)
	if not _is_success(response) or assessment.is_empty() or int(assessment.get("id", 0)) <= 0:
		SecureDataManager.enqueue_pending_game_attempt({
			"kind": "lesson_assessment", "lesson_id": lesson_id,
			"client_attempt_id": client_session_id, "payload": payload.duplicate(true),
			"instrument": LearningActivityContext.instrument,
			"local_lesson_id": LearningActivityContext.local_lesson_ids[0] if not LearningActivityContext.local_lesson_ids.is_empty() else "",
			"completed_at": str(payload.get("completedAt", _iso_now())),
			"title": "Đánh giá bài học",
			"lessonTitle": SecureDataManager.active_course_title if not SecureDataManager.active_course_title.is_empty() else "Bài học",
		})
		activity_history_changed.emit()
		return {"submitted": false, "queued": true, "reason": "assessment_failed", "status": int(response.get("status", 0)), "message": _api.error_message(response, "Đồng bộ đánh giá bài học thất bại.")}
	SecureDataManager.apply_backend_reward(assessment)
	_apply_assessment_completion(assessment, LearningActivityContext.instrument, LearningActivityContext.local_lesson_ids[0] if not LearningActivityContext.local_lesson_ids.is_empty() else "")
	activity_history_changed.emit()
	return {"submitted": true, "assessment_id": int(assessment.get("id", 0)), "score": assessment.get("score", 0), "max_score": assessment.get("maxScore", 0), "accuracy": assessment.get("accuracy", 0), "stars_earned": int(assessment.get("starsEarned", 0)), "points_earned": int(assessment.get("pointsEarned", 0)), "completed": bool(assessment.get("completed", false)), "lesson_stars": int(assessment.get("lessonStars", 0))}


## Retries persisted game attempts after startup/login. Rewards are applied only
## once this API acknowledgement succeeds, then the queue entry is deleted.
func retry_pending_game_attempts() -> void:
	if not is_signed_in():
		return
	if _retry_pending_in_progress:
		return
	_retry_pending_in_progress = true
	for value: Variant in SecureDataManager.get_pending_game_attempts():
		if not value is Dictionary:
			continue
		var item: Dictionary = value
		var response: Dictionary = {}
		if str(item.get("kind", "")) == "quiz":
			response = await _api.submit_quiz_attempt(int(item.get("quiz_id", 0)), str(item.get("selected_answer", "")), str(item.get("client_attempt_id", "")))
		elif str(item.get("kind", "")) == "minigame":
			response = await _api.submit_minigame_attempt(int(item.get("minigame_id", 0)), int(item.get("score", 0)), str(item.get("client_attempt_id", "")), str(item.get("started_at", "")), str(item.get("completed_at", "")), str(item.get("play_data", "")))
		elif str(item.get("kind", "")) == "lesson_assessment":
			var payload: Dictionary = item.get("payload", {})
			response = await _api.submit_lesson_assessment(int(item.get("lesson_id", 0)), payload)
		elif str(item.get("kind", "")) == "lesson_completion":
			var target_id := int(item.get("lesson_id", 0))
			if target_id <= 0:
				var binding := SecureDataManager.resolve_be_lesson_exact(str(item.get("instrument", "")), str(item.get("local_lesson_id", "")))
				target_id = int(binding.get("id", 0))
				if target_id <= 0:
					continue
			response = await _api.complete_lesson_progress(
				target_id, str(item.get("client_attempt_id", "")),
				str(item.get("completed_at", "")), float(item.get("score", -1.0))
			)
		else:
			continue
		var reward := _attempt_data(response)
		if str(item.get("kind", "")) == "lesson_completion":
			if _is_server_acknowledged(response) and bool(reward.get("completed", false)):
				SecureDataManager.apply_confirmed_lesson_completion(str(item.get("instrument", "")), str(item.get("local_lesson_id", "")), int(reward.get("lessonStars", 0)))
				SecureDataManager.apply_backend_reward(reward)
				SecureDataManager.remove_pending_game_attempt(str(item.get("client_attempt_id", "")))
				activity_history_changed.emit()
			continue
		if _is_server_acknowledged(response) and not reward.is_empty() and int(reward.get("id", 0)) > 0:
			SecureDataManager.apply_backend_reward(reward)
			if str(item.get("kind", "")) == "lesson_assessment":
				_apply_assessment_completion(reward, str(item.get("instrument", "")), str(item.get("local_lesson_id", "")))
				LessonAssessmentCoordinator.clear(int(item.get("lesson_id", 0)))
			SecureDataManager.remove_pending_game_attempt(str(item.get("client_attempt_id", "")))
			activity_history_changed.emit()
		else:
			if str(item.get("kind", "")) == "quiz":
				_log_quiz_sync_failure("retry", int(item.get("quiz_id", 0)), response)
	_retry_pending_in_progress = false

func _apply_assessment_completion(assessment: Dictionary, instrument: String, local_lesson_id: String) -> void:
	if bool(assessment.get("completed", false)) and not instrument.is_empty() and not local_lesson_id.is_empty():
		SecureDataManager.apply_confirmed_lesson_completion(instrument, local_lesson_id, int(assessment.get("lessonStars", 0)))


## Log ở cả Output và Debugger/Warnings. Không in access token hay đáp án.
func _log_quiz_sync_failure(action: String, quiz_id: int, response: Dictionary) -> void:
	var status := int(response.get("status", 0))
	var message: String = str(_api.error_message(response, "Không có thông tin lỗi từ máy chủ."))
	var log_line := "[QuizSync] %s quiz_id=%d | HTTP=%d | %s" % [action, quiz_id, status, message]
	print(log_line)
	push_warning(log_line)


func get_activity_history(page: int = 0, size: int = 20, activity_type: String = "") -> Dictionary:
	if not is_signed_in():
		return {}
	return await _api.get_activity_history(page, size, activity_type)


func get_activity_history_detail(event_id: String) -> Dictionary:
	if not is_signed_in():
		return {}
	return await _api.get_activity_history_detail(event_id)


# ── Daily challenges ───────────────────────────────────────────────────

func fetch_daily_challenges() -> Array:
	if not is_signed_in():
		return []
	var response: Dictionary = await _api.get_daily_challenges()
	if not _is_success(response):
		return []
	return _extract_array(response)


func complete_daily_challenge(challenge_id: int) -> Dictionary:
	if not is_signed_in():
		return {"submitted": false, "reason": "not_signed_in"}
	var response: Dictionary = await _api.complete_daily_challenge(challenge_id)
	if not _is_success(response):
		return {
			"submitted": false,
			"status": int(response.get("status", 0)),
			"message": _api.error_message(response, "Không thể nhận thưởng thử thách."),
		}
	return {"submitted": true}


# ── Helpers ────────────────────────────────────────────────────────────

func _extract_array(response: Dictionary) -> Array:
	var body: Variant = response.get("body", {})
	if not body is Dictionary:
		return []
	var data: Variant = body.get("data", [])
	if data is Array:
		return data
	if data is Dictionary and data.get("content", null) is Array:
		return data["content"]
	return []


func _is_success(response: Dictionary) -> bool:
	var status := int(response.get("status", 0))
	return status >= 200 and status < 300


func _is_server_acknowledged(response: Dictionary) -> bool:
	var status := int(response.get("status", 0))
	return status >= 200 and status < 300 and status != 202


func _is_pending_response(response: Dictionary) -> bool:
	return int(response.get("status", 0)) in [0, 202]


func _attempt_data(response: Dictionary) -> Dictionary:
	var body: Variant = response.get("body", {})
	if not body is Dictionary:
		return {}
	var data: Variant = (body as Dictionary).get("data", {})
	return data as Dictionary if data is Dictionary else {}


static func _uuid() -> String:
	var random := [
		"%04x" % randi_range(0, 0xFFFF),
		"%04x" % randi_range(0, 0xFFFF),
		"%04x" % randi_range(0, 0xFFFF),
		"%04x" % randi_range(0, 0xFFFF),
	]
	return "%d-%s-%s-%s-%s" % [Time.get_unix_time_from_system(), random[0], random[1], random[2], random[3]]


static func _iso_now() -> String:
	var current_time = Time.get_datetime_dict_from_system()
	return "%d-%02d-%02dT%02d:%02d:%02dZ" % [
		current_time.year, current_time.month, current_time.day,
		current_time.hour, current_time.minute, current_time.second
	]
