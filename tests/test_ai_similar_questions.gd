extends SceneTree

const Manager = preload("res://scripts/AIManager.gd")
const AppConfig = preload("res://scripts/AppConfig.gd")

var test_cases: Array[Dictionary] = [
	{
		"name": "Số lỗ Sáo Trúc",
		"prompt": "sáo trúc có bao nhiêu lỗ bấm?",
		"instrument": "sao_truc",
		"lesson": "",
		"expected_source": "SAO_TRUC_CAU_TAO_LO",
		"expected_keyword": "6 lỗ bấm"
	},
	{
		"name": "Số dây Đàn Tranh",
		"prompt": "đàn tranh có mấy dây?",
		"instrument": "dan_tranh",
		"lesson": "",
		"expected_source": "DAN_TRANH_CAU_TAO_DAY",
		"expected_keyword": "16 dây"
	},
	{
		"name": "Tên gọi Đàn Thập Lục",
		"prompt": "tại sao đàn tranh lại gọi là đàn thập lục?",
		"instrument": "dan_tranh",
		"lesson": "",
		"expected_source": "DAN_TRANH_CAU_TAO_DAY",
		"expected_keyword": "Thập lục"
	},
	{
		"name": "Thế bấm ngón Sáo Trúc",
		"prompt": "khi bấm lỗ sáo trúc thì bấm bằng phần nào của ngón tay?",
		"instrument": "sao_truc",
		"lesson": "",
		"expected_source": "SAO_TRUC_THE_BAM_NGON",
		"expected_keyword": "đốt ngón tay thứ nhất"
	},
	{
		"name": "Cách đặt môi thổi Sáo Trúc",
		"prompt": "đặt môi như thế nào khi thổi sáo trúc?",
		"instrument": "sao_truc",
		"lesson": "",
		"expected_source": "SAO_TRUC_KY_THUAT_THOI_LAY_HOI",
		"expected_keyword": "môi dưới"
	},
	{
		"name": "Đeo móng gảy Đàn Tranh",
		"prompt": "đeo móng gảy đàn tranh ở những ngón nào?",
		"instrument": "dan_tranh",
		"lesson": "",
		"expected_source": "DAN_TRANH_DEO_MONG_GAY",
		"expected_keyword": "ba ngón tay phải"
	},
	{
		"name": "Thang âm ngũ cung Đàn Tranh",
		"prompt": "đàn tranh lên dây theo những nốt nào?",
		"instrument": "dan_tranh",
		"lesson": "",
		"expected_source": "DAN_TRANH_THANG_AM_NGU_CUNG",
		"expected_keyword": "ngũ cung"
	},
	{
		"name": "Bảo quản Sáo Trúc",
		"prompt": "làm sao để bảo quản sáo trúc không bị nứt?",
		"instrument": "sao_truc",
		"lesson": "",
		"expected_source": "SAO_TRUC_BAO_QUAN",
		"expected_keyword": "nơi khô ráo"
	},
	{
		"name": "Bảo quản Đàn Tranh di chuyển",
		"prompt": "cách bảo quản đàn tranh khi cần di chuyển xa?",
		"instrument": "dan_tranh",
		"lesson": "",
		"expected_source": "DAN_TRANH_BAO_QUAN",
		"expected_keyword": "con nhạn"
	}
]

func _initialize() -> void:
	print("==================================================")
	print("  KIỂM THỬ RUNTIME GODOT: CÁC CÂU HỎI TƯƠNG TỰ")
	print("==================================================")

	var manager := Manager.new()
	root.add_child(manager)

	var passed_count := 0
	var failed_count := 0

	for i in range(test_cases.size()):
		var tc: Dictionary = test_cases[i]
		print("\n--- Test Case %d/%d: %s ---" % [i + 1, test_cases.size(), tc["name"]])
		print("  Học viên hỏi: \"%s\"" % tc["prompt"])

		manager.instrument_context = tc["instrument"]
		manager.lesson_code = tc["lesson"]
		manager.send_prompt(tc["prompt"])

		_wait_for_request(manager)

		var success: bool = (manager.last_status == "ANSWERED") and (tc["expected_source"] in manager.last_sources) and manager.structured_buffer.contains(tc["expected_keyword"])
		if success:
			print("  => KẾT QUẢ: THÀNH CÔNG (ANSWERED)")
			print("  => Nguồn trích dẫn: %s" % str(manager.last_sources))
			passed_count += 1
		else:
			print("  => KẾT QUẢ: THẤT BẠI! Status: %s | Buffer: %s | Sources: %s" % [manager.last_status, manager.structured_buffer, str(manager.last_sources)])
			failed_count += 1

	print("\n==================================================")
	print("  TỔNG KẾT GODOT TEST: %d/%d test cases đạt" % [passed_count, test_cases.size()])
	print("==================================================")

	manager.free()
	quit(0 if failed_count == 0 else 1)

func _wait_for_request(manager: Manager) -> void:
	var start_ms := Time.get_ticks_msec()
	while manager.client != null:
		manager._process(0.01)
		OS.delay_msec(10)
		if Time.get_ticks_msec() - start_ms > 10000:
			print("FAIL: Timeout chờ phản hồi từ MaiBrain!")
			quit(1)
			return
