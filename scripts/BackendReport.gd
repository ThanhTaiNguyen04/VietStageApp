extends Node
## BackendReport autoload — reports learner results to the VietStage backend.
##
## Owns a single ApiClient and routes practice/minigame/quiz/daily-challenge
## submissions. All submission methods are best-effort: when the learner is
## offline, unsigned, or the local lesson has no reliable BE binding, they
## return { "submitted": false, "reason": ... } and callers keep the local
## save file as source of truth (graceful skip).

const AuthSessionStore = preload("res://scripts/AuthSession.gd")
const ApiClientScript = preload("res://scripts/ApiClient.gd")

var _api: Node = null


func _ready() -> void:
	_api = ApiClientScript.new()
	add_child(_api)


func is_signed_in() -> bool:
	return AuthSessionStore.has_access_token()


# ── Catalog bootstrap ──────────────────────────────────────────────────

## Tải GET /api/instruments + GET /api/lessons và cài vào SecureDataManager.
## Được MainMenu gọi sau khi đăng nhập để sẵn sàng resolve exercise/lesson.
func fetch_and_install_catalog() -> void:
	if not is_signed_in():
		return
	var instruments_response: Dictionary = await _api.get_instruments()
	var lessons_response: Dictionary = await _api.get_lessons()
	var instruments: Array = _extract_array(instruments_response)
	var lessons: Array = _extract_array(lessons_response)
	if instruments.is_empty() and lessons.is_empty():
		return
	SecureDataManager.install_be_catalog(instruments, lessons)


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
func fetch_quizzes_for_level(instrument: String, local_lesson_ids: Array) -> Array:
	var result: Array = []
	for local_id: Variant in local_lesson_ids:
		var lesson: Dictionary = SecureDataManager.resolve_be_lesson(instrument, str(local_id))
		if lesson.is_empty():
			continue
		var lesson_id := int(lesson.get("id", 0))
		var quizzes: Array = await ensure_quizzes(lesson_id)
		for quiz: Variant in quizzes:
			if quiz is Dictionary:
				result.append(quiz)
	return result


## Đảm bảo minigames của một lesson được cache vào SecureDataManager.
func ensure_minigames(lesson_id: int) -> Dictionary:
	if SecureDataManager.be_minigames.has(lesson_id):
		var cached: Array = SecureDataManager.be_minigames[lesson_id]
		return cached[0] if not cached.is_empty() else {}
	var response: Dictionary = await _api.get_lesson_minigames(lesson_id)
	if not _is_success(response):
		return {}
	var minigames: Array = _extract_array(response)
	SecureDataManager.cache_be_minigames(lesson_id, minigames)
	return minigames[0] if not minigames.is_empty() else {}


# ── Practice attempts ──────────────────────────────────────────────────

## Nộp kết quả lượt tập. scores keys: pitch, rhythm, dynamics,
## tonal_quality, breath (0..100). Returns Dictionary { submitted, ... }.
func report_practice(instrument: String, local_lesson_id: String, scores: Dictionary) -> Dictionary:
	if not is_signed_in():
		return {"submitted": false, "reason": "not_signed_in"}

	var lesson: Dictionary = SecureDataManager.resolve_be_lesson(instrument, local_lesson_id)
	if lesson.is_empty():
		return {"submitted": false, "reason": "no_lesson_binding"}
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


# ── Minigame attempts ──────────────────────────────────────────────────

## Nộp kết quả minigame của một lesson. Returns Dictionary { submitted, ... }.
func report_minigame(instrument: String, local_lesson_id: String, score: int, stars: int) -> Dictionary:
	if not is_signed_in():
		return {"submitted": false, "reason": "not_signed_in"}

	var lesson: Dictionary = SecureDataManager.resolve_be_lesson(instrument, local_lesson_id)
	if lesson.is_empty():
		return {"submitted": false, "reason": "no_lesson_binding"}
	var lesson_id := int(lesson.get("id", 0))

	var minigame: Dictionary = await ensure_minigames(lesson_id)
	if minigame.is_empty():
		return {"submitted": false, "reason": "no_minigame_binding"}
	var minigame_id := int(minigame.get("id", 0))

	var response: Dictionary = await _api.submit_minigame_attempt(
		minigame_id,
		score,
		stars,
		_iso_now(),
		_iso_now()
	)
	if not _is_success(response):
		return {
			"submitted": false,
			"reason": "attempt_failed",
			"status": int(response.get("status", 0)),
			"message": _api.error_message(response, "Không thể đồng bộ điểm minigame."),
		}
	return {"submitted": true, "minigame_id": minigame_id}


# ── Quiz attempts ──────────────────────────────────────────────────────

## Nộp đáp án trắc nghiệm. Returns Dictionary { submitted, ... }.
func report_quiz(quiz_id: int, selected_answer: String) -> Dictionary:
	if not is_signed_in():
		return {"submitted": false, "reason": "not_signed_in"}
	var response: Dictionary = await _api.submit_quiz_attempt(quiz_id, selected_answer)
	if not _is_success(response):
		return {
			"submitted": false,
			"reason": "attempt_failed",
			"status": int(response.get("status", 0)),
			"message": _api.error_message(response, "Không thể nộp câu trắc nghiệm."),
		}
	var attempt_data: Dictionary = response.get("body", {}).get("data", {})
	if not attempt_data is Dictionary:
		attempt_data = {}
	return {
		"submitted": true,
		"quiz_id": quiz_id,
		"is_correct": bool(attempt_data.get("isCorrect", false)),
		"points_earned": int(attempt_data.get("points_earned", 0)),
	}


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
