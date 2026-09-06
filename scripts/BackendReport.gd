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

var _api: Node = null
var _retry_pending_in_progress := false


func _ready() -> void:
	_api = ApiClientScript.new()
	add_child(_api)
	call_deferred("retry_pending_game_attempts")


func is_signed_in() -> bool:
	return _api != null and AuthSessionStore.has_access_token()

# ── Catalog bootstrap ──────────────────────────────────────────────────

## Tải GET /api/instruments + GET /api/lessons và cài vào SecureDataManager.
## Được MainMenu gọi sau khi đăng nhập để sẵn sàng resolve exercise/lesson.
func fetch_and_install_catalog() -> void:
	if not is_signed_in():
		return
	await retry_pending_game_attempts()
	var instruments_response: Dictionary = await _api.get_instruments()
	var lessons_response: Dictionary = await _api.get_lessons()
	var instruments: Array = _extract_array(instruments_response)
	var lessons: Array = _extract_array(lessons_response)
	if instruments.is_empty() and lessons.is_empty():
		return
	SecureDataManager.install_be_catalog(instruments, lessons)


## Làm mới lộ trình và tổng sao từ backend.
func refresh_progress_from_backend() -> Dictionary:
	if not is_signed_in():
		return {"synced": false, "reason": "not_signed_in"}
	var progress_response: Dictionary = await _api.get_my_progress()
	var summary_response: Dictionary = await _api.get_my_progress_summary()
	var progress_synced := false
	var summary_synced := false
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
		return {"submitted": false, "reason": "lesson_binding_mismatch"}
	var lesson_id := int(lesson.get("id", 0))
	var response: Dictionary = await _api.complete_lesson_progress(
		lesson_id,
		_uuid(),
		_iso_now(),
		score
	)
	if not _is_success(response):
		return {
			"submitted": false,
			"reason": "completion_failed",
			"status": int(response.get("status", 0)),
			"message": _api.error_message(response, "Không thể ghi nhận hoàn thành bài học."),
		}
	var completion_data: Variant = response.get("body", {}).get("data", {})
	if not completion_data is Dictionary:
		completion_data = {}
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
func ensure_quizzes(lesson_id: int) -> Array:
	if SecureDataManager.be_quizzes.has(lesson_id):
		return SecureDataManager.be_quizzes[lesson_id]
	var response: Dictionary = await _api.get_lesson_quizzes(lesson_id)
	if not _is_success(response):
		return []
	var quizzes: Array = _extract_array(response)
	SecureDataManager.cache_be_quizzes(lesson_id, quizzes)
	return quizzes


## Gom toàn bộ câu hỏi trắc nghiệm của các bài nội bộ (cùng level) để ôn tập.
## Nếu không binding được lesson nào theo local id, tự quét toàn bộ lesson cùng nhạc cụ
## để FE vẫn lấy được quiz thật của BE (bỏ ràng buộc với bài học khi test giao diện).
func fetch_quizzes_for_level(instrument: String, local_lesson_ids: Array) -> Array:
	if SecureDataManager.be_catalog.is_empty():
		await fetch_and_install_catalog()
	var result: Array = []
	var bound_ids: Array[int] = []
	print("[QuizDebug] fetching for local_ids: ", local_lesson_ids, " instrument: ", instrument)
	for local_id: Variant in local_lesson_ids:
		var lesson: Dictionary = SecureDataManager.resolve_be_lesson(instrument, str(local_id))
		print("[QuizDebug] resolve_be_lesson for ", local_id, " returned id: ", lesson.get("id", "EMPTY"))
		if lesson.is_empty():
			continue
		var lesson_id := int(lesson.get("id", 0))
		bound_ids.append(lesson_id)
		var quizzes: Array = await ensure_quizzes(lesson_id)
		print("[QuizDebug] ensure_quizzes returned size: ", quizzes.size())
		for quiz: Variant in quizzes:
			if quiz is Dictionary:
				result.append(quiz)
	if result.is_empty():
		var instrument_lesson_ids := SecureDataManager.be_lesson_ids_for_instrument(instrument)
		if not instrument_lesson_ids.is_empty():
			push_warning("[Quiz] Không lấy được quiz theo lesson local, quét toàn bộ %d lesson của %s để lấy quiz." % [instrument_lesson_ids.size(), instrument])
		var seen_quiz_ids: Dictionary = {}
		for quiz: Variant in result:
			if quiz is Dictionary:
				seen_quiz_ids[int(quiz.get("id", 0))] = true
		for lesson_id: int in instrument_lesson_ids:
			if bound_ids.has(lesson_id):
				continue
			var quizzes: Array = await ensure_quizzes(lesson_id)
			for quiz: Variant in quizzes:
				if not quiz is Dictionary:
					continue
				var quiz_id := int(quiz.get("id", 0))
				if seen_quiz_ids.has(quiz_id):
					continue
				seen_quiz_ids[quiz_id] = true
				result.append(quiz)
	return result


func ensure_minigame_list(lesson_id: int, force_refresh: bool = false) -> Array:
	if not force_refresh and SecureDataManager.be_minigames.has(lesson_id):
		return SecureDataManager.be_minigames[lesson_id]
	var response: Dictionary = await _api.get_lesson_minigames(lesson_id)
	if not _is_success(response):
		return []
	var minigames: Array = _extract_array(response)
	SecureDataManager.cache_be_minigames(lesson_id, minigames)
	return minigames


func fetch_minigames_for_level(instrument: String, local_lesson_ids: Array, expected_challenge_type: String = "", force_refresh: bool = true) -> Array:
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
	if result.is_empty():
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


# ── Practice attempts ──────────────────────────────────────────────────

## Nộp kết quả lượt tập. scores keys: pitch, rhythm, dynamics,
## tonal_quality, breath (0..100). Returns Dictionary { submitted, ... }.
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

	var session_response: Dictionary = await _api.start_practice_session()
	if not _is_success(session_response):
		return {"submitted": false, "reason": "session_failed", "status": int(session_response.get("status", 0))}
	var session_body: Dictionary = session_response.get("body", {})
	var session_data: Dictionary = session_body.get("data", {}) if session_body.get("data", {}) is Dictionary else {}
	var session_id := int(session_data.get("id", 0))

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
	await _api.end_practice_session(session_id)

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
func report_minigame_by_id(minigame_id: int, score: int, _client_preview_stars: int, started_at: String = "", completed_at: String = "", client_attempt_id: String = "") -> Dictionary:
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
		complete_value
	)
	var attempt_data := _attempt_data(response)
	# A 2xx response is not an acknowledgement unless it identifies the persisted
	# attempt. Without data.id the app must retain the same client id for retry.
	if not _is_success(response) or attempt_data.is_empty() or int(attempt_data.get("id", 0)) <= 0:
		SecureDataManager.enqueue_pending_game_attempt({
			"kind": "minigame", "minigame_id": minigame_id, "score": score,
			"started_at": start_value, "completed_at": complete_value, "client_attempt_id": attempt_id,
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
	if not _is_success(response) or attempt_data.is_empty() or int(attempt_data.get("id", 0)) <= 0:
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
		"correct_answer": str(attempt_data.get("correctAnswer", attempt_data.get("correct_answer", ""))),
		"score": float(attempt_data.get("score", 0.0)),
		"max_score": 100.0,
		"attempt_id": int(attempt_data.get("id", 0)),
		"completed_at": str(attempt_data.get("attemptedAt", attempt_data.get("attempted_at", ""))),
	}


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
			response = await _api.submit_minigame_attempt(int(item.get("minigame_id", 0)), int(item.get("score", 0)), str(item.get("client_attempt_id", "")), str(item.get("started_at", "")), str(item.get("completed_at", "")))
		else:
			continue
		var reward := _attempt_data(response)
		if _is_success(response) and not reward.is_empty() and int(reward.get("id", 0)) > 0:
			SecureDataManager.apply_backend_reward(reward)
			SecureDataManager.remove_pending_game_attempt(str(item.get("client_attempt_id", "")))
			activity_history_changed.emit()
		else:
			if str(item.get("kind", "")) == "quiz":
				_log_quiz_sync_failure("retry", int(item.get("quiz_id", 0)), response)
	_retry_pending_in_progress = false


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
