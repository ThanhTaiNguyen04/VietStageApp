extends Node

const Course := preload("res://scripts/DanTranhCourseData.gd")
const LessonList := preload("res://scripts/LessonDanTranhList.gd")

func _ready() -> void:
	var target := "dan_tranh_level_8_bai_33_practice"
	var lessons: Array = LessonList.get_level_data(8).get("lessons", [])
	var selected := Course.quiz_lesson_for_lessons(lessons, target)
	if selected != target:
		push_error("Quiz selected %s instead of %s" % [selected, target])
		get_tree().quit(1)
		return
	if Course.current_quiz_lesson(target) != target:
		push_error("Main menu did not retain current lesson")
		get_tree().quit(1)
		return
	SecureDataManager.be_catalog = [{"id": 1622, "lessonCode": "LSN-1622", "title": "Hợp âm La thứ", "instrument": {"name": "Đàn tranh"}}]
	var resolved := SecureDataManager.resolve_be_lesson_exact("dan_tranh", target)
	if int(resolved.get("id", 0)) != 1622:
		push_error("Quiz lesson did not resolve to backend lesson 1622")
		get_tree().quit(1)
		return
	print("PASS quiz current lesson -> backend lesson 1622")
	get_tree().quit()
