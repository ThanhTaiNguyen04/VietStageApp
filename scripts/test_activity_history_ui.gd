extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("========================================")
	print("TEST: ActivityHistoryScreen UI & Script")
	print("========================================")

	var screen_script = preload("res://scripts/ActivityHistoryScreen.gd")
	var screen_instance = screen_script.new()
	get_root().add_child(screen_instance)

	print("[Check 1] Screen instantiated successfully.")

	# Mock some data
	var mock_items = [
		{
			"eventId": "evt_001",
			"type": "QUIZ",
			"title": "Nhận diện nốt Đô",
			"lessonTitle": "Đàn Tranh Cơ Bản 1",
			"score": 100,
			"maxScore": 100,
			"starsEarned": 2,
			"pointsEarned": 10,
			"completedAt": Time.get_datetime_string_from_system(true)
		},
		{
			"eventId": "evt_002",
			"type": "MINIGAME",
			"title": "Bắt nhịp Ngũ Cung",
			"lessonTitle": "Đàn Tranh Cơ Bản 2",
			"score": 480,
			"maxScore": 500,
			"starsEarned": 3,
			"pointsEarned": 15,
			"completedAt": Time.get_datetime_string_from_system(true)
		},
		{
			"eventId": "evt_003",
			"type": "PRACTICE",
			"title": "Luyện ngón bài Lý Cây Bông",
			"lessonTitle": "Sáo Trúc Cơ Bản 1",
			"score": 92,
			"maxScore": 100,
			"starsEarned": 3,
			"pointsEarned": 25,
			"completedAt": "2026-09-02T10:30:00"
		}
	]

	screen_instance._render(mock_items)
	print("[Check 2] _render executed with 3 items without crashing.")
	assert(screen_instance._stats_container.get_child_count() == 4)
	assert(screen_instance._type_name("QUIZ") == "Câu hỏi")
	assert(screen_instance._accuracy_text(mock_items[0]) == "100%")
	assert(screen_instance._sync_status_text({"status": "PENDING_SYNC"}) == "Chờ đồng bộ")
	assert(screen_instance._connection_label != null)
	print("[Check 3] Compact stats and Vietnamese activity labels are present.")

	# Check detail modal open
	screen_instance._open_detail(mock_items[0])
	print("[Check 4] _open_detail executed successfully.")

	screen_instance._close_detail_sheet()
	print("[Check 5] _close_detail_sheet executed successfully.")

	print("========================================")
	print("ACTIVITY HISTORY SCREEN TEST PASSED!")
	print("========================================")
	quit()
