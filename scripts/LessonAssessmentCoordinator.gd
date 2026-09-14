extends RefCounted

## Durable client-side draft for one canonical lesson assessment.  Individual
## screens update this draft; only the complete draft is posted to the API.
class_name LessonAssessmentCoordinator

const SecureDataManager = preload("res://scripts/SecureDataManager.gd")

static func register_content(lesson_id: int, quizzes: Array, minigames: Array) -> Dictionary:
	var draft := _draft(lesson_id)
	draft["quiz_ids"] = _ids(quizzes)
	draft["minigame_ids"] = _ids(minigames)
	var minigame_types := {}
	for value: Variant in minigames:
		if value is Dictionary:
			var item: Dictionary = value
			var item_id := int(item.get("id", 0))
			if item_id > 0:
				minigame_types[str(item_id)] = str(item.get("challengeType", item.get("challenge_type", "")))
	draft["minigame_types"] = minigame_types
	_save(draft)
	return draft

static func record_quiz(lesson_id: int, quiz_id: int, selected_answer: String) -> void:
	if lesson_id <= 0 or quiz_id <= 0:
		return
	var draft := _draft(lesson_id)
	draft["quiz_answers"][str(quiz_id)] = selected_answer
	_save(draft)

static func record_minigame(lesson_id: int, challenge_id: int, score: int, started_at: String, completed_at: String) -> void:
	if lesson_id <= 0 or challenge_id <= 0:
		return
	var draft := _draft(lesson_id)
	draft["minigame_results"][str(challenge_id)] = {"score": score, "startedAt": started_at, "completedAt": completed_at}
	_save(draft)

static func is_complete(lesson_id: int) -> bool:
	var draft := _find(lesson_id)
	if draft.is_empty():
		return false
	var quiz_ids: Array = draft.get("quiz_ids", [])
	var minigame_ids: Array = draft.get("minigame_ids", [])
	var quiz_answers: Dictionary = draft.get("quiz_answers", {})
	var minigame_results: Dictionary = draft.get("minigame_results", {})
	var total: int = quiz_ids.size() + minigame_ids.size()
	if total == 0:
		return false
	return quiz_answers.size() == quiz_ids.size() and minigame_results.size() == minigame_ids.size()

static func activity_state(lesson_id: int, activity: String) -> String:
	var draft := _find(lesson_id)
	if draft.is_empty():
		return "NOT_STARTED"
	var expected: Array = draft.get("quiz_ids", []) if activity == "quiz" else _minigame_ids_for(activity, draft)
	if expected.is_empty():
		return "UNAVAILABLE"
	var completed: Dictionary = draft.get("quiz_answers", {}) if activity == "quiz" else draft.get("minigame_results", {})
	var done_count := 0
	for id_value: Variant in expected:
		if completed.has(str(int(id_value))):
			done_count += 1
	if done_count == expected.size():
		return "COMPLETE"
	if done_count > 0:
		return "IN_PROGRESS"
	return "NOT_STARTED"

static func progress(lesson_id: int) -> Dictionary:
	var draft := _find(lesson_id)
	if draft.is_empty():
		return {"done": 0, "total": 0}
	var quiz_ids: Array = draft.get("quiz_ids", [])
	var minigame_ids: Array = draft.get("minigame_ids", [])
	var quiz_answers: Dictionary = draft.get("quiz_answers", {})
	var minigame_results: Dictionary = draft.get("minigame_results", {})
	var total: int = quiz_ids.size() + minigame_ids.size()
	var done: int = quiz_answers.size() + minigame_results.size()
	return {"done": mini(done, total), "total": total}

static func payload(lesson_id: int) -> Dictionary:
	var draft := _find(lesson_id)
	if draft.is_empty() or not is_complete(lesson_id):
		return {}
	var quiz_answers: Array = []
	for id_value: Variant in draft.get("quiz_ids", []):
		var quiz_id := int(id_value)
		quiz_answers.append({"quizId": quiz_id, "selectedAnswer": str(draft["quiz_answers"].get(str(quiz_id), ""))})
	var minigame_results: Array = []
	for id_value: Variant in draft.get("minigame_ids", []):
		var challenge_id := int(id_value)
		var result: Dictionary = draft["minigame_results"].get(str(challenge_id), {})
		minigame_results.append({"challengeId": challenge_id, "score": int(result.get("score", 0)), "startedAt": str(result.get("startedAt", "")), "completedAt": str(result.get("completedAt", ""))})
	return {"clientSessionId": str(draft.get("client_session_id", "")), "startedAt": str(draft.get("started_at", "")), "quizAnswers": quiz_answers, "minigameResults": minigame_results}

static func clear(lesson_id: int) -> void:
	var drafts: Array = _drafts()
	SecureDataManager.data["lesson_assessment_drafts"] = drafts.filter(func(value: Variant) -> bool:
		return not (value is Dictionary and int((value as Dictionary).get("lesson_id", 0)) == lesson_id)
	)
	SecureDataManager.save_data()

static func submit_if_complete(report: Node, lesson_id: int) -> Dictionary:
	var request := payload(lesson_id)
	if request.is_empty():
		return {"submitted": false, "reason": "incomplete"}
	var result: Dictionary = await report.report_lesson_assessment(lesson_id, request)
	if bool(result.get("submitted", false)):
		clear(lesson_id)
	return result

static func _draft(lesson_id: int) -> Dictionary:
	var existing := _find(lesson_id)
	if not existing.is_empty():
		return existing
	return {"lesson_id": lesson_id, "client_session_id": _uuid(), "started_at": Time.get_datetime_string_from_system(true, true), "quiz_ids": [], "minigame_ids": [], "quiz_answers": {}, "minigame_results": {}}

static func _find(lesson_id: int) -> Dictionary:
	for value: Variant in _drafts():
		if value is Dictionary and int((value as Dictionary).get("lesson_id", 0)) == lesson_id:
			return (value as Dictionary).duplicate(true)
	return {}

static func _save(draft: Dictionary) -> void:
	var drafts: Array = _drafts().filter(func(value: Variant) -> bool:
		return not (value is Dictionary and int((value as Dictionary).get("lesson_id", 0)) == int(draft.get("lesson_id", 0)))
	)
	drafts.append(draft.duplicate(true))
	SecureDataManager.data["lesson_assessment_drafts"] = drafts
	SecureDataManager.save_data()

static func _drafts() -> Array:
	var value: Variant = SecureDataManager.data.get("lesson_assessment_drafts", [])
	return value.duplicate(true) if value is Array else []

static func _ids(items: Array) -> Array:
	var result: Array = []
	for value: Variant in items:
		if value is Dictionary:
			var id := int((value as Dictionary).get("id", 0))
			if id > 0 and not result.has(id):
				result.append(id)
	return result

static func _minigame_ids_for(activity: String, draft: Dictionary) -> Array:
	var result: Array = []
	var type_map: Dictionary = draft.get("minigame_types", {})
	for id_value: Variant in draft.get("minigame_ids", []):
		var type := str(type_map.get(str(int(id_value)), "")).to_upper()
		if activity == "rhythm" and type in ["RHYTHM_MATCH", "RHYTHM_MATCHING", "RHYTHM"]:
			result.append(id_value)
		elif activity == "melody" and type in ["MELODY_COMPLETION", "MELODY_COMPLETE", "MELODY"]:
			result.append(id_value)
	return result

static func _uuid() -> String:
	return "%s-%s" % [str(Time.get_unix_time_from_system()), str(Time.get_ticks_usec())]
