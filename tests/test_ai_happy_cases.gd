extends SceneTree

const Manager = preload("res://scripts/AIManager.gd")
const AppConfig = preload("res://scripts/AppConfig.gd")

var test_cases: Array[Dictionary] = [
	{
		"name": "Kỹ thuật Á (Đàn Tranh Level 2)",
		"prompt": "Kỹ thuật Á trên Đàn Tranh là gì?",
		"instrument": "dan_tranh",
		"lesson": "DAN_TRANH_LEVEL_2_KY_THUAT_A",
		"expected_source": "DAN_TRANH_TECHNIQUE_A_THEORY"
	},
	{
		"name": "Vai trò hai tay khi chơi Đàn Tranh (Level 1)",
		"prompt": "Khi chơi Đàn Tranh thì tay phải và tay trái có vai trò gì?",
		"instrument": "dan_tranh",
		"lesson": "DAN_TRANH_LEVEL_1_BAI_1",
		"expected_source": "DAN_TRANH_RIGHT_LEFT_HAND"
	},
	{
		"name": "Kỹ thuật Nhấn dây (Level 2)",
		"prompt": "Làm thế nào để thực hiện đúng kỹ thuật Nhấn dây Đàn Tranh?",
		"instrument": "dan_tranh",
		"lesson": "DAN_TRANH_LEVEL_2_KY_THUAT_NHAN",
		"expected_source": "DAN_TRANH_TECHNIQUE_NHAN"
	},
	{
		"name": "Kỹ thuật Rung dây (Level 2)",
		"prompt": "Kỹ thuật Rung trong bài thực hành yêu cầu người học làm gì trước?",
		"instrument": "dan_tranh",
		"lesson": "DAN_TRANH_LEVEL_2_KY_THUAT_RUNG",
		"expected_source": "DAN_TRANH_TECHNIQUE_RUNG"
	},
	{
		"name": "Kỹ thuật Song thanh (Level 2)",
		"prompt": "Kỹ thuật Song thanh yêu cầu gảy mấy nốt?",
		"instrument": "dan_tranh",
		"lesson": "DAN_TRANH_LEVEL_2_SONG_THANH",
		"expected_source": "DAN_TRANH_TECHNIQUE_SONG_THANH"
	},
	{
		"name": "Kỹ thuật Vê (Level 3)",
		"prompt": "Yêu cầu của bài thực hành kỹ thuật Vê là gì?",
		"instrument": "dan_tranh",
		"lesson": "DAN_TRANH_LEVEL_3_KY_THUAT_VE",
		"expected_source": "DAN_TRANH_TECHNIQUE_VE"
	},
	{
		"name": "Giới thiệu Sáo Trúc (Level 1)",
		"prompt": "Cách tạo âm và đổi cao độ khi thổi Sáo Trúc như thế nào?",
		"instrument": "sao_truc",
		"lesson": "",
		"expected_source": "SAO_TRUC_OVERVIEW"
	}
]

func _initialize() -> void:
	print("==================================================")
	print("  BẮT ĐẦU KIỂM THỬ CÁC HAPPY CASE VỚI CÔ MAI AI")
	print("==================================================")

	var manager := Manager.new()
	root.add_child(manager)

	var passed_count := 0
	var failed_count := 0

	for i in range(test_cases.size()):
		var tc: Dictionary = test_cases[i]
		print("\n--- Test Case %d/%d: %s ---" % [i + 1, test_cases.size(), tc["name"]])
		print("  Học viên hỏi: \"%s\"" % tc["prompt"])
		print("  Ngữ cảnh: instrument=%s, lesson=%s" % [tc["instrument"], tc["lesson"]])

		manager.instrument_context = tc["instrument"]
		manager.lesson_code = tc["lesson"]
		manager.send_prompt(tc["prompt"])

		_wait_for_request(manager)

		var success: bool = (manager.last_status == "ANSWERED") and (tc["expected_source"] in manager.last_sources)
		if success:
			print("  => KẾT QUẢ: THÀNH CÔNG (ANSWERED)")
			print("  => Cô Mai đáp: \"%s\"" % manager.structured_buffer.substr(0, 120))
			print("  => Nguồn trích dẫn: %s" % str(manager.last_sources))
			passed_count += 1
		else:
			print("  => KẾT QUẢ: THẤT BẠI! Status: %s | inScope: %s | Sources: %s" % [manager.last_status, manager.last_in_scope, str(manager.last_sources)])
			failed_count += 1

	print("\n==================================================")
	print("  TỔNG KẾT: %d/%d test cases đạt yêu cầu" % [passed_count, test_cases.size()])
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
