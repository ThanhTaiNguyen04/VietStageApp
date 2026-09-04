extends RefCounted
class_name DanTranhApiCourseContract

# Contract chuẩn bị cho giáo trình điều khiển từ web. Chưa được phép dùng làm
# nguồn runtime cho đến khi giáo trình cứng và API backend hoàn thiện.
const REMOTE_CONTENT_ENABLED := false
const INSTRUMENT_KEY := "dan_tranh"

const SKILL_LEVELS := {
	"BEGINNER": {"name": "Sơ cấp", "order_index": 1, "local_level": 1},
	"INTERMEDIATE": {"name": "Trung cấp", "order_index": 2, "local_level": 2},
	"ADVANCED": {"name": "Cao cấp", "order_index": 3, "local_level": 7}
}

# App chỉ hiển thị bài đã xuất bản. HIDDEN/ARCHIVED vẫn phải được backend giữ
# lại để bảo toàn progress, sao và lịch sử attempt của người học.
const VISIBLE_LESSON_STATUSES := ["PUBLISHED", "ACTIVE"]
const NON_DESTRUCTIVE_LESSON_STATUSES := ["DRAFT", "PENDING", "PUBLISHED", "ACTIVE", "HIDDEN", "ARCHIVED"]

# Hai loại đầu đang có trong OpenAPI. Các loại còn lại là contract cần backend
# bổ sung trước khi bật REMOTE_CONTENT_ENABLED.
const CURRENT_API_ASSET_TYPES := ["REFERENCE_AUDIO", "SHEET_MUSIC"]
const REQUIRED_ASSET_TYPES := [
	"LESSON_VIDEO",
	"REFERENCE_AUDIO",
	"SHEET_MUSIC",
	"ANIMATION",
	"BEAT_MAP",
	"VOICE_OVER"
]

const CONTENT_BLOCK_TYPES := [
	"THEORY_TEXT",
	"TEACHER_SPEECH",
	"VIDEO_CUE",
	"ANIMATION_CUE",
	"PRACTICE_INSTRUCTION",
	"WAIT_FOR_NOTE",
	"WAIT_FOR_GESTURE"
]


static func is_remote_content_enabled() -> bool:
	return REMOTE_CONTENT_ENABLED


static func skill_level_to_local_level(skill_level: Dictionary) -> int:
	var code := str(skill_level.get("levelCode", skill_level.get("code", ""))).to_upper()
	if SKILL_LEVELS.has(code):
		return int(SKILL_LEVELS[code]["local_level"])
	var name := str(skill_level.get("levelName", skill_level.get("level_name", ""))).to_lower()
	if "sơ cấp" in name or "so cap" in name:
		return 1
	if "trung cấp" in name or "trung cap" in name:
		return 2
	if "cao cấp" in name or "cao cap" in name:
		return 7
	return 0


static func is_lesson_visible(lesson: Dictionary) -> bool:
	return str(lesson.get("status", "")).to_upper() in VISIBLE_LESSON_STATUSES


static func visible_lessons(api_lessons: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for lesson_value in api_lessons:
		if lesson_value is Dictionary and is_lesson_visible(lesson_value):
			result.append(lesson_value)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("orderIndex", 0)) < int(b.get("orderIndex", 0))
	)
	return result


# Với API hiện tại, nội dung có cấu trúc được đặt tạm trong content_text dưới
# dạng JSON. Web phải gửi object có schema_version và blocks. Khi backend có
# cột JSON riêng, adapter này có thể đổi mà không ảnh hưởng scene bài học.
static func decode_lesson_content(content_response: Dictionary) -> Dictionary:
	var raw := str(content_response.get("content_text", content_response.get("contentText", "")))
	if raw.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(raw)
	if parsed is Dictionary:
		return parsed
	return {
		"schema_version": 1,
		"blocks": [{"type": "THEORY_TEXT", "text": raw}]
	}


static func validate_content_document(document: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if int(document.get("schema_version", 0)) < 1:
		errors.append("Thiếu schema_version")
	var blocks: Variant = document.get("blocks", [])
	if not blocks is Array:
		errors.append("blocks phải là Array")
		return errors
	for index in range(blocks.size()):
		var block: Variant = blocks[index]
		if not block is Dictionary:
			errors.append("blocks[%d] phải là Dictionary" % index)
			continue
		var block_type := str(block.get("type", ""))
		if block_type not in CONTENT_BLOCK_TYPES:
			errors.append("blocks[%d].type không được hỗ trợ: %s" % [index, block_type])
	return errors


static func make_note_sequence_exercise(
	title: String,
	notes: Array[String],
	durations: Array[float],
	pass_threshold: float = 60.0,
	practice_mode: String = "pitch_sequence"
) -> Dictionary:
	return {
		"schema_version": 1,
		"type": "NOTE_SEQUENCE",
		"title": title,
		"practice_mode": practice_mode,
		"notes": notes.duplicate(),
		"durations": durations.duplicate(),
		"pass_threshold": clampf(pass_threshold, 0.0, 100.0)
	}
