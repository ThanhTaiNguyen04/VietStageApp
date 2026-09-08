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
	assert(screen_instance._sync_status_text({"status": "FAILED_SYNC"}) == "Đồng bộ lỗi")
	assert(screen_instance._connection_label != null)
	print("[Check 3] Compact stats and Vietnamese activity labels are present.")

	var long_item := {
		"type": "MINIGAME",
		"title": "Thử thách nhịp điệu ngũ cung với một tên bài học rất dài để kiểm tra ellipsis trên màn hình ngang",
		"score": null,
		"status": "FAILED_SYNC"
	}
	var compact_card := screen_instance._make_3d_activity_card(long_item)
	assert(compact_card.custom_minimum_size.y >= 70)
	assert(screen_instance._icons8_texture("game") != null)
	assert(screen_instance._icons8_texture("songs") != null)
	assert(screen_instance._icons8_texture("course") != null)
	assert(screen_instance._icons8_texture("progress") != null)
	assert(screen_instance._score_text(long_item) == "—")
	assert(screen_instance._accuracy_text(long_item) == "—")
	assert(screen_instance._activity_time_text(long_item) == "—")
	assert(screen_instance._is_compact_landscape_size(Vector2(640, 360)))
	assert(screen_instance._is_compact_landscape_size(Vector2(932, 430)))
	assert(not screen_instance._is_compact_landscape_size(Vector2(430, 932)))
	print("[Check 4] Compact card and Icons8 textures verified.")

	screen_instance._render_loading_skeleton()
	assert(screen_instance._list_container.get_child_count() == 3)
	print("[Check 5] Loading skeleton renders three lightweight rows.")

	# Check empty state rendering
	var empty_panel := screen_instance._build_empty_state()
	assert(empty_panel != null)
	print("[Check 5b] Empty state with CTA button renders cleanly.")

	# Check detail modal open
	screen_instance._open_detail(mock_items[0])
	print("[Check 6] _open_detail executed successfully.")

	screen_instance._close_detail_sheet()
	print("[Check 7] _close_detail_sheet executed successfully.")

	print("========================================")
	print("ACTIVITY HISTORY SCREEN TEST PASSED!")
	print("========================================")
	quit()
