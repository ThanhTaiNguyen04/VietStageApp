extends RefCounted
class_name DanTranhCourseData

const INSTRUMENT_ID := "dan_tranh"
const LESSON_LIST_SCENE := "res://scenes/LessonDanTranhList.tscn"
const LessonListScript := preload("res://scripts/LessonDanTranhList.gd")

const ROADMAP := {
	1: {
		"title": "LEVEL 1: NHẬP MÔN & LÀM QUEN",
		"description": "Làm quen với đàn tranh, đọc nhạc cơ bản và luyện các ngón gảy đầu tiên."
	},
	2: {
		"title": "LEVEL 2: KỸ THUẬT DIỄN TẤU",
		"description": "Tìm hiểu về các kỹ thuật Á, nhấn, song thanh và rung dây."
	},
	7: {
		"title": "LEVEL 3: KỸ THUẬT NÂNG CAO MỞ RỘNG",
		"description": "Mở rộng khả năng diễn tấu với kỹ thuật vê và hợp âm ba âm cơ bản."
	}
}


static func get_roadmap_configuration() -> Dictionary:
	return {
		"guide": "Lộ trình học tập Đàn Tranh",
		"levels": ROADMAP.duplicate(true)
	}


static func select_level(level_number: int) -> String:
	LessonListScript.selected_level = level_number
	return LESSON_LIST_SCENE


static func quiz_lesson_for_lessons(lessons: Array, active_id: String) -> String:
	var best_id := ""
	var best_rank := -1
	for lesson_value: Variant in lessons:
		if not lesson_value is Dictionary:
			continue
		var lesson: Dictionary = lesson_value
		var quiz_id := str(lesson.get("quiz_lesson_id", lesson.get("practice_id", lesson.get("video_id", ""))))
		if quiz_id.is_empty():
			continue
		var canonical := SecureDataManager.canonical_lesson_id(INSTRUMENT_ID, quiz_id)
		if canonical == SecureDataManager.canonical_lesson_id(INSTRUMENT_ID, active_id):
			return quiz_id
		var status := SecureDataManager.get_lesson_learning_status(INSTRUMENT_ID, quiz_id)
		var rank := 2 if status == "IN_PROGRESS" else (1 if SecureDataManager.is_lesson_unlocked(INSTRUMENT_ID, quiz_id) else 0)
		if rank > best_rank or rank == best_rank:
			best_rank = rank
			best_id = quiz_id
	return best_id


static func current_quiz_lesson(active_id: String) -> String:
	for level: Dictionary in preload("res://scripts/DanTranhBundledLessonData.gd").LEVELS:
		for lesson_value: Variant in level.get("lessons", []):
			if lesson_value is Dictionary:
				var lesson: Dictionary = lesson_value
				var quiz_id := str(lesson.get("quiz_lesson_id", lesson.get("practice_id", lesson.get("video_id", ""))))
				if SecureDataManager.canonical_lesson_id(INSTRUMENT_ID, quiz_id) == SecureDataManager.canonical_lesson_id(INSTRUMENT_ID, active_id):
					return quiz_id
	var best_id := ""
	var best_rank := -1
	for level: Dictionary in preload("res://scripts/DanTranhBundledLessonData.gd").LEVELS:
		for lesson_value: Variant in level.get("lessons", []):
			if not lesson_value is Dictionary:
				continue
			var lesson: Dictionary = lesson_value
			var quiz_id := str(lesson.get("quiz_lesson_id", lesson.get("practice_id", lesson.get("video_id", ""))))
			var status := SecureDataManager.get_lesson_learning_status(INSTRUMENT_ID, quiz_id)
			var rank := 2 if status == "IN_PROGRESS" else (1 if SecureDataManager.is_lesson_unlocked(INSTRUMENT_ID, quiz_id) else 0)
			if rank > best_rank or rank == best_rank:
				best_rank = rank
				best_id = quiz_id
	return best_id


static func get_level_status(level_number: int, save_data: Dictionary) -> Dictionary:
	var level_data: Dictionary = LessonListScript.get_level_data(level_number)
	if level_data.is_empty() or not level_data.has("lessons"):
		return {"completed": false, "stars": 0, "pct": 0, "completed_count": 0, "step_count": 0}

	var step_ids: Array[String] = []
	for lesson_value in level_data["lessons"]:
		var lesson: Dictionary = lesson_value
		var lesson_number := int(lesson["number"])
		var prefix := "%s_level_%d_bai_%d_" % [INSTRUMENT_ID, level_number, lesson_number]
		if str(lesson.get("type", "practice")) == "video":
			step_ids.append(str(lesson.get("video_id", prefix + "video")))
		else:
			step_ids.append(str(lesson.get("practice_id", prefix + "practice")))

	var completed_count := 0
	var total_stars := 0
	for step_id in step_ids:
		if SecureDataManager.is_lesson_completed(INSTRUMENT_ID, step_id):
			completed_count += 1
			total_stars += SecureDataManager.get_lesson_stars(INSTRUMENT_ID, step_id)
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
