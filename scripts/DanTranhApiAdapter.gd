extends RefCounted
class_name DanTranhApiAdapter

# API content is selected only after BackendReport has validated and cached a
# response for the exact lessonCode. Bundled content remains the fallback.
const REMOTE_CONTENT_ENABLED := true
const LESSONS_PATH := "/api/lessons"
const CONTENTS_PATH := "/api/lessons/%d/contents"
const EXERCISES_PATH := "/api/lessons/%d/exercises"
const COMPLETION_PATH := "/api/users/me/lessons/%d/complete"

static func unwrap_response(response: Dictionary) -> Dictionary:
	if response.get("success", false) != true:
		return {}
	var data: Variant = response.get("data", {})
	return data.duplicate(true) if data is Dictionary else {}

## Pure boundary mapping; accepted instrument ID must come from master data,
## never from guessing that the first instrument is Dan Tranh.
static func map_lesson(dto: Dictionary, dan_tranh_instrument_id: int) -> Dictionary:
	var instrument: Variant = dto.get("instrument", {})
	var lesson_code := str(dto.get("lessonCode", "")).strip_edges()
	var lesson_id := int(dto.get("id", 0))
	if not instrument is Dictionary or dan_tranh_instrument_id <= 0:
		return {}
	if int(instrument.get("id", 0)) != dan_tranh_instrument_id or lesson_id <= 0 or lesson_code.is_empty():
		return {}
	var skill_level: Variant = dto.get("skillLevel", {})
	var exercises: Variant = dto.get("exercises", [])
	if not skill_level is Dictionary or not exercises is Array:
		return {}
	return {
		"lessonId": lesson_id,
		"lessonCode": lesson_code,
		"title": str(dto.get("title", "")),
		"description": str(dto.get("description", "")),
		"status": str(dto.get("status", "")),
		"orderIndex": int(dto.get("orderIndex", 0)),
		"instrument": instrument.duplicate(true),
		"skillLevel": skill_level.duplicate(true),
		"exercises": exercises.duplicate(true),
		# Not supplied by current OpenAPI: never claim this metadata is playable.
		"practiceReady": false
	}

static func map_teacher_speech(contents: Array) -> Array[Dictionary]:
	var ordered: Array[Dictionary] = []
	for item in contents:
		if item is Dictionary and item.get("content_text", "") is String:
			ordered.append(item.duplicate(true))
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("order_index", 0)) < int(b.get("order_index", 0)))
	var steps: Array[Dictionary] = []
	for item in ordered:
		steps.append({"action": "speak", "text": item["content_text"], "highlight": -1})
	return steps

## Uses API teacher speech when it was fetched for the exact canonical code.
## Practice cues remain bundled until the API publishes a structured practice
## contract; this prevents a partial API record from breaking recognition.
static func bundled_dialogues(lesson_code: String, bundled: Dictionary) -> Array:
	var remote := SecureDataManager.get_be_teacher_speech(lesson_code)
	if not remote.is_empty():
		return remote
	var steps: Variant = bundled.get(lesson_code, [])
	return steps.duplicate(true) if steps is Array else []
