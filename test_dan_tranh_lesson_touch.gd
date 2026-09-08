extends Node


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	LessonDanTranhList.selected_level = 2
	var lesson_list := load("res://scenes/LessonDanTranhList.tscn").instantiate() as LessonDanTranhList
	add_child(lesson_list)
	await get_tree().process_frame
	await get_tree().process_frame

	var lessons_hbox := lesson_list.get_node("Root/RightContent/ScrollContainer/ContentMargin/LessonsHBox") as HBoxContainer
	assert(lessons_hbox.get_child_count() > 0, "Danh sách Level 2 không tạo được thẻ bài học")
	var lesson_button := lessons_hbox.get_child(0).get_node("LessonBtn") as Button
	assert(not lesson_button.disabled, "Thẻ bài học Level 2 đang bị khóa")
	assert(lesson_button.size.x > 0.0 and lesson_button.size.y > 0.0, "Thẻ bài học không có vùng bấm")
	var lesson_data := lesson_button.get_meta("lesson_data", {}) as Dictionary
	var expected_id := str(lesson_data.get("practice_id", "dan_tranh_level_2_bai_%d_practice" % int(lesson_data.get("number", 0))))

	SecureDataManager.active_lesson_id = ""
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = lesson_button.get_global_rect().get_center()
	touch.pressed = true
	lesson_list._input(touch)
	assert(SecureDataManager.active_lesson_id == expected_id, "Chạm đã mở sai bài: mong đợi %s, nhận %s" % [expected_id, SecureDataManager.active_lesson_id])

	print("PASS dan_tranh_touch: ", SecureDataManager.active_lesson_id)
	print("PASS emulate_mouse_from_touch: ", ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch"))
	get_tree().quit(0)
