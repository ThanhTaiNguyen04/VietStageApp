extends RefCounted
class_name SaoTrucCourseData

const INSTRUMENT_ID := "sao_truc"
const LESSON_LIST_SCENE := "res://scenes/LessonSaoTrucList.tscn"
const LessonListScript := preload("res://scripts/LessonSaoTrucList.gd")

# Giữ nguyên các ID mà MainMenu đã dùng để không thay đổi dữ liệu tiến độ hiện có.
const CARD_STEP_IDS := {
	"basic": ["sao_truc_level1_1_video"],
	"essentials": ["Node1", "Node2", "Node3", "Node4", "Node5", "Node6", "Node7", "Node8"],
	"soloist": ["sao_truc_level3_1", "sao_truc_level3_2"],
	"chords": ["sao_truc_level4_1", "sao_truc_level4_2"],
	"classical": ["sao_truc_level5_1", "sao_truc_level5_2"],
	"pop_chords": ["Node35", "Node36"]
}

const INTRO_LESSON_ID := "sao_truc_level1_1_video"
const INTRO_VIDEO_SEQUENCE := [
	"res://nvaore/intro1.ogv",
	"res://nvaore/intro2.ogv",
	"res://nvaore/intro3.ogv"
]

const ROADMAP := {
	"guide": "Lộ trình học tập Sáo Trúc",
	"soloist_path": "🎵 ĐƯỜNG ĐỘC TẤU (SOLOIST PATH)",
	"ensemble_path": "🎷 ĐƯỜNG HÒA TẤU (ENSEMBLE PATH)",
	"basic_title": "LEVEL 1: KHẨU HÌNH MÔI & TẠO ÂM",
	"basic_description": "Học đặt môi, lấy hơi bụng, cách bấm các lỗ sáo và thổi ra âm thanh tròn trịa.",
	"essentials_title": "LEVEL 2: BẤM NGÓN & LẤY HƠI",
	"essentials_description": "Tập bấm các nốt chuẩn thang âm sáo trúc và kiểm soát cột hơi ổn định.",
	"soloist_title": "LEVEL 3: KHÚC NHẠC VUI",
	"soloist_description": "✓ Thực hành từng khung nhạc\n✓ Luyện tập cách ghép câu\n✓ Hoàn thiện bài Khúc Nhạc Vui",
	"chords_title": "LEVEL 4: INH LẢ ƠI",
	"chords_description": "✓ Thực hành từng câu\n✓ Luyện tập chuyển ngón\n✓ Hoàn thiện bài Inh Lả Ơi",
	"pop_title": "LEVEL 5: FUTARI NO KIMOCHI",
	"pop_description": "✓ Thực hành đoạn 1\n✓ Thực hành đoạn 2\n✓ Hoàn thiện bài Futari no Kimochi",
	"classical_title": "LEVEL 6: GẶP MẸ TRONG MƠ",
	"classical_description": "✓ Thực hành giai điệu\n✓ Chơi cùng Backing Track\n✓ Hoàn thiện toàn bài"
}


static func get_roadmap_configuration() -> Dictionary:
	return ROADMAP.duplicate(true)


static func select_level(level_number: int) -> String:
	LessonListScript.selected_level = level_number
	return LESSON_LIST_SCENE


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
