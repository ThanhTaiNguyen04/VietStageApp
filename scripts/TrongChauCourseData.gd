extends RefCounted
class_name TrongChauCourseData

const INSTRUMENT_ID := "trong_chau"
const LESSON_LIST_SCENE := "res://scenes/LessonTrongChau.tscn"
const LessonListScript := preload("res://scripts/LessonTrongChau.gd")

const CARD_LESSON_RANGES := {
	"basic": [0],
	"essentials": [1, 2],
	"soloist": [0, 1, 2],
	"chords": [0, 1, 2],
	"classical": [0, 1, 2],
	"pop_chords": [0, 1, 2]
}

const ROADMAP := {
	"guide": "Lộ trình học tập Trống Chầu",
	"basic_title": "Nhập Môn Trống Chầu",
	"basic_description": "Học tư thế cầm dùi, vị trí mặt da, vành trống và các âm Tịch, Cắc cơ bản.",
	"essentials_title": "Kỹ Thuật Gõ Nâng Cao",
	"essentials_description": "Luyện kỹ thuật đập Vành, trống cuộn (Roll) và nhịp Múa Lân.",
	"soloist_title": "LEVEL 3: NHỊP ĐIỆU & TỐC ĐỘ",
	"soloist_description": "✓ Luyện ngón tốc độ cao – Mã Vũ\n✓ Làm quen mật độ nốt dày hơn",
	"chords_title": "LEVEL 4: KỸ THUẬT NÂNG CAO",
	"chords_description": "✓ Mô phỏng kỹ thuật rung tay trái\n✓ Hòa tấu cùng nhạc cụ khác\n✓ Đánh đàn theo beat",
	"pop_title": "LEVEL 5: MASTER – NHẠC HIỆN ĐẠI",
	"pop_description": "✓ Nhạc hiện đại: Sứ Thanh Hoa\n✓ Boss Stage sinh tồn\n✓ Biểu diễn không gợi ý",
	"classical_title": "LEVEL 6: HỢP ÂM & HÒA ÂM",
	"classical_description": "✓ Lý thuyết & thế bấm hợp âm\n✓ Kỹ thuật gảy song âm & Arpeggio\n✓ Thực hành đệm hòa âm",
	"extended_title": "LEVEL 3: KỸ THUẬT NÂNG CAO MỞ RỘNG",
	"extended_description": "Mở rộng khả năng diễn tấu với các kỹ thuật nâng cao."
}


static func get_roadmap_configuration() -> Dictionary:
	return ROADMAP.duplicate(true)


static func get_lesson_scene() -> String:
	return LESSON_LIST_SCENE


static func get_card_status(card_type: String, save_data: Dictionary) -> Dictionary:
	var lesson_indexes: Array = CARD_LESSON_RANGES.get(card_type, [])
	var completed: Array = save_data.get("completed_lessons", {}).get(INSTRUMENT_ID, [])
	var stars: Dictionary = save_data.get("stars", {}).get(INSTRUMENT_ID, {})
	var step_ids: Array[String] = []
	for index_value in lesson_indexes:
		var index := int(index_value)
		if index < 0 or index >= LessonListScript.LESSONS.size():
			continue
		var lesson: Dictionary = LessonListScript.LESSONS[index]
		var lesson_id := str(lesson.get("id", ""))
		if not lesson_id.is_empty():
			step_ids.append(lesson_id + "_video")
			step_ids.append(lesson_id + "_practice")
	var completed_count := 0
	var total_stars := 0
	for step_id in step_ids:
		if completed.has(step_id):
			completed_count += 1
			total_stars += int(stars.get(step_id, 0))
	var percentage := 0
	if not step_ids.is_empty():
		percentage = int(float(completed_count) / float(step_ids.size()) * 100.0)
	return {
		"completed": not step_ids.is_empty() and completed_count == step_ids.size(),
		"stars": total_stars,
		"pct": percentage,
		"completed_count": completed_count,
		"step_count": step_ids.size()
	}
