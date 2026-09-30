extends SceneTree

const Manager = preload("res://scripts/AIManager.gd")
const AppConfig = preload("res://scripts/AppConfig.gd")

func _initialize() -> void:
	print("--- Bắt đầu Live Test AI Chat Box ---")
	var configured_url := AppConfig.get_maibrain_chat_url()
	print("URL từ AppConfig: ", configured_url)
	assert(not configured_url.is_empty(), "AppConfig phải có MAIBRAIN_CHAT_URL!")

	var manager := Manager.new()
	manager.api_url = configured_url
	manager.request_failed.connect(func(reason: String): print(">>> LỖI REQUEST: ", reason))
	root.add_child(manager)

	# Test 1: OUT_OF_SCOPE
	print("\n[Bước 1] Test câu hỏi ngoài phạm vi (OUT_OF_SCOPE)...")
	manager.instrument_context = "dan_tranh"
	manager.send_prompt("Thời tiết hôm nay thế nào?")
	_wait_for_request(manager)
	print("  Status: ", manager.last_status, " | inScope: ", manager.last_in_scope)
	assert(manager.last_status == "OUT_OF_SCOPE", "Bước 1 phải trả OUT_OF_SCOPE")
	assert(manager.last_in_scope == false, "Bước 1 inScope phải là false")

	# Test 2: INSUFFICIENT_KNOWLEDGE
	print("\n[Bước 2] Test câu hỏi thiếu tài liệu (INSUFFICIENT_KNOWLEDGE)...")
	manager.instrument_context = "dan_tranh"
	manager.send_prompt("Cách chơi đàn nguyệt?")
	_wait_for_request(manager)
	print("  Status: ", manager.last_status, " | inScope: ", manager.last_in_scope)
	assert(manager.last_status == "INSUFFICIENT_KNOWLEDGE", "Bước 2 phải trả INSUFFICIENT_KNOWLEDGE")
	assert(manager.last_in_scope == true, "Bước 2 inScope phải là true")

	# Test 3: ANSWERED
	print("\n[Bước 3] Test câu hỏi hợp lệ trong phạm vi (ANSWERED)...")
	manager.instrument_context = "dan_tranh"
	manager.lesson_code = "DAN_TRANH_LEVEL_2_KY_THUAT_A"
	manager.send_prompt("Á xuống của Đàn Tranh dùng ngón nào và đi theo hướng nào?")
	_wait_for_request(manager)
	print("  Status: ", manager.last_status, " | inScope: ", manager.last_in_scope, " | Sources: ", manager.last_sources)
	assert(manager.last_status == "ANSWERED", "Bước 3 phải trả ANSWERED")
	assert(manager.last_in_scope == true, "Bước 3 inScope phải là true")
	assert(not manager.last_sources.is_empty(), "Bước 3 phải có sources trích dẫn")

	print("\n=== TẤT CẢ 3 BƯỚC LIVE TEST ĐỀU THÀNH CÔNG ===")
	manager.free()
	quit(0)

func _wait_for_request(manager: Manager) -> void:
	var start_ms := Time.get_ticks_msec()
	while manager.client != null:
		manager._process(0.01)
		OS.delay_msec(10)
		if Time.get_ticks_msec() - start_ms > 10000:
			print("FAIL: Timeout chờ phản hồi từ MaiBrain!")
			quit(1)
			return
