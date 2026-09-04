extends RefCounted
class_name DanBauCourseData

const INSTRUMENT_ID := "dan_bau"
const LESSON_LIST_SCENE := "res://scenes/LessonDanBau.tscn"
const LessonListScript := preload("res://scripts/LessonDanBau.gd")

const CARD_LEVELS := {
	"basic": 1,
	"essentials": 2,
	"soloist": 3,
	"chords": 4,
	"classical": 5,
	"pop_chords": 5
}

const ROADMAP := {
	"guide": "Lộ trình học tập Đàn Bầu",
	"basic_title": "LEVEL 1: NHẬP MÔN TẠO ÂM",
	"basic_description": "Nắm vững tư thế và cách tạo bồi âm chuẩn trên cơ chế 1 dây.",
	"essentials_title": "LEVEL 2: LINH HỒN CỦA ĐÀN",
	"essentials_description": "Dùng cần đàn (tay trái) để thay đổi cao độ và kỹ thuật căng dây.",
	"soloist_title": "LEVEL 3: UYỂN CHUYỂN",
	"soloist_description": "✓ Làm chủ kỹ thuật chùng dây\n✓ Đẩy cần đàn về phía thân người\n✓ Bài hát: Lý Cây Đa",
	"chords_title": "LEVEL 4: KỸ THUẬT LUYẾN ÂM",
	"chords_description": "✓ Đánh các nốt luyến dài\n✓ Kỹ thuật Luyến 2 chiều\n✓ Bài hát: Cò Lả & Auld Lang Syne",
	"master_title": "LEVEL 5: HÒA TẤU & THỬ THÁCH MASTER",
	"classical_description": "✓ Biểu diễn như nghệ sĩ thực thụ\n✓ Nghệ thuật Hòa tấu (Ensemble)\n✓ Boss Stage: Biểu diễn bằng tai",
	"pop_description": "✓ Biểu diễn như nghệ sĩ thực thụ\n✓ Chơi Lead cùng Backing Track\n✓ Boss Stage: Chứng nhận ảo"
}


static func get_roadmap_configuration() -> Dictionary:
	return ROADMAP.duplicate(true)


static func select_level(level_number: int) -> String:
	LessonListScript.selected_level = level_number
	return LESSON_LIST_SCENE


static func get_level_lessons(level_number: int) -> Array:
	for level_value in LessonListScript.LEVELS:
		var level: Dictionary = level_value
		if int(level.get("level", 0)) == level_number:
			return level.get("lessons", [])
	return []


static func get_card_status(card_type: String, save_data: Dictionary) -> Dictionary:
	var level_number := int(CARD_LEVELS.get(card_type, 0))
	var lessons := get_level_lessons(level_number)
	var completed: Array = save_data.get("completed_lessons", {}).get(INSTRUMENT_ID, [])
	var stars: Dictionary = save_data.get("stars", {}).get(INSTRUMENT_ID, {})
	var completed_count := 0
	var total_stars := 0
	for lesson_value in lessons:
		var lesson: Dictionary = lesson_value
		var lesson_id := str(lesson.get("id", ""))
		if not lesson_id.is_empty() and completed.has(lesson_id):
			completed_count += 1
			total_stars += int(stars.get(lesson_id, 0))
	var step_count := lessons.size()
	var percentage := 0
	if step_count > 0:
		percentage = int(float(completed_count) / float(step_count) * 100.0)
	return {
		"completed": step_count > 0 and completed_count == step_count,
		"stars": total_stars,
		"pct": percentage,
		"completed_count": completed_count,
		"step_count": step_count
	}
