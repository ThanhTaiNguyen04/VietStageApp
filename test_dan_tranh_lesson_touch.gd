extends Node

class SlowBackend extends Node:
	var starts := 0
	func start_lesson(_instrument: String, _id: String) -> Dictionary:
		starts += 1
		await get_tree().create_timer(10.0).timeout
		return {"submitted": false, "reason": "server_rejected", "status": 404}

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var original_data := SecureDataManager.data.duplicate(true)
	var backend := get_node("/root/BackendReport")
	get_tree().root.remove_child(backend)
	var slow := SlowBackend.new()
	slow.name = "BackendReport"
	get_tree().root.add_child(slow)
	for email: String in ["phuclong2710@gmail.com", "thanhdattb19@gmail.com"]:
		for use_touch: bool in [false, true]:
			SecureDataManager.data["user_email"] = email
			SecureDataManager.data["backend_course_access_loaded"] = false
			LessonDanTranhList.selected_level = 1
			var lesson_list := load("res://scenes/LessonDanTranhList.tscn").instantiate() as LessonDanTranhList
			add_child(lesson_list)
			await get_tree().process_frame
			await get_tree().process_frame
			var row := lesson_list.get_node("Root/RightContent/ScrollContainer/ContentMargin/LessonsHBox")
			var button := row.get_child(0).get_node("LessonBtn") as Button
			if button.disabled:
				push_error("FAIL: bài 1 bị khóa")
				get_tree().quit(1)
				return
			SecureDataManager.active_lesson_id = ""
			var event: InputEvent
			if use_touch:
				var touch := InputEventScreenTouch.new()
				touch.position = button.get_global_rect().get_center()
				touch.pressed = true
				event = touch
			else:
				var click := InputEventMouseButton.new()
				click.position = button.get_global_rect().get_center()
				click.button_index = MOUSE_BUTTON_LEFT
				click.pressed = true
				event = click
			get_viewport().push_input(event, true)
			if SecureDataManager.active_lesson_id != "dan_tranh_level_1_bai_1_video":
				push_error("FAIL: click/touch không mở ngay bài 1 khi API chậm")
				get_tree().quit(1)
				return
			print("PASS: ", email, " touch=" , use_touch, " opens lesson before API response")
			lesson_list.queue_free()
			await get_tree().process_frame
	SecureDataManager.data = original_data
	get_tree().root.remove_child(slow)
	slow.queue_free()
	get_tree().root.add_child(backend)
	get_tree().quit(0)