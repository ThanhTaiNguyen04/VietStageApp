extends RefCounted
class_name DanTranhApiAdapter

# Preparation only. No HTTP, cache writes, progress migration or reward calls.
# OpenAPI supplied 2026-09-16: response camelCase, content request snake_case.
const REMOTE_CONTENT_ENABLED := false
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

## Safe staging hook. Retains every bundled action including practice cues.
## Deliberately ignores remote data until practice schema/cache are approved.
static func bundled_dialogues(lesson_code: String, bundled: Dictionary) -> Array:
	var steps: Variant = bundled.get(lesson_code, [])
	return steps.duplicate(true) if steps is Array else []
