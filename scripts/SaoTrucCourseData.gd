extends RefCounted
class_name SaoTrucCourseData

const INSTRUMENT_ID := "sao_truc"
const LESSON_LIST_SCENE := "res://scenes/LessonSaoTrucList.tscn"
const LessonListScript := preload("res://scripts/LessonSaoTrucList.gd")

# Ba chặng hiển thị mới. Các giá trị là level cũ trong dữ liệu bài học; giữ nguyên
# ID bài học để tiến độ và sao đã lưu của học viên không bị mất.
const LEVEL_GROUPS := {
	1: [1, 2],
	2: [3, 4],
	3: [5, 6]
}

const LEVEL_LESSON_COUNTS := {
	1: 8,
	2: 11,
	3: 15
}

const CARD_STEP_IDS := {
	"basic": ["sao_truc_level1_1_video", "Node2", "Node3", "Node4", "Node5", "Node6", "Node7", "Node8"],
	"intermediate": ["sao_truc_level3_1", "sao_truc_level3_2", "sao_truc_level3_3", "sao_truc_level3_4", "sao_truc_level3_5", "sao_truc_level3_6", "sao_truc_level4_1", "sao_truc_level4_2", "sao_truc_level4_3", "sao_truc_level4_4", "sao_truc_level4_5"],
	"advanced": ["sao_truc_level5_1", "sao_truc_level5_2", "sao_truc_level5_3", "sao_truc_level5_4", "sao_truc_level5_5", "sao_truc_level5_6", "sao_truc_level5_7", "Node35", "Node36", "Node37", "Node38", "Node39", "Node40", "Node41", "Node42"]
}

const INTRO_LESSON_ID := "sao_truc_level1_1_video"
const INTRO_VIDEO_SEQUENCE := [
	"res://nvaore/intro1.ogv",
	"res://nvaore/intro2.ogv",
	"res://nvaore/intro3.ogv"
]

const ROADMAP := {
	"guide": "Lộ trình học tập Sáo Trúc",
	"basic_title": "LEVEL 1: NHẬP MÔN VÀ LÀM QUEN NHẠC CỤ",
	"basic_description": "Khẩu hình, hơi thở, tư thế cầm sáo và 7 nốt nền tảng.",
	"intermediate_title": "LEVEL 2: LUYỆN CÁC BÀI CƠ BẢN",
	"intermediate_description": "Ghép câu, chuyển ngón, giữ nhịp và hoàn thiện Khúc Nhạc Vui, Inh Lả Ơi.",
	"advanced_title": "LEVEL 3: LUYỆN CÁC BÀI NÂNG CAO",
	"advanced_description": "Luyện bài dài, kiểm soát hơi và biểu diễn Futari no Kimochi, Gặp Mẹ Trong Mơ."
}


static func get_roadmap_configuration() -> Dictionary:
	return ROADMAP.duplicate(true)


static func select_level(level_number: int) -> String:
	LessonListScript.selected_level = level_number
	var group: Array = LEVEL_GROUPS.get(level_number, [level_number])
	var source_levels: Array = []
	for lvl in group:
		source_levels.append(int(lvl))
	LessonListScript.selected_source_levels = source_levels
	return LESSON_LIST_SCENE


static func get_level_lesson_count(level_number: int) -> int:
	return int(LEVEL_LESSON_COUNTS.get(level_number, 0))


static func configure_intro(save_data: Dictionary) -> void:
	save_data["custom_video_sequence"] = INTRO_VIDEO_SEQUENCE.duplicate()
	save_data["current_sequence_index"] = 0


static func get_card_status(card_type: String, save_data: Dictionary) -> Dictionary:
	var step_ids: Array = CARD_STEP_IDS.get(card_type, [])
	var completed: Array = save_data.get("completed_lessons", {}).get(INSTRUMENT_ID, [])
	var stars: Dictionary = save_data.get("stars", {}).get(INSTRUMENT_ID, {})
	var completed_count := 0
	var total_stars := 0
	for step_id_value in step_ids:
		var step_id := str(step_id_value)
		if completed.has(step_id):
			completed_count += 1
			total_stars += int(stars.get(step_id, 0))
	var step_count := step_ids.size()
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
