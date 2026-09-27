extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("========================================")
	print("TEST: Instrument Isolation for Quiz & Minigame")
	print("========================================")

	var SDM = preload("res://scripts/SecureDataManager.gd")
	var BackendReportScript = preload("res://scripts/BackendReport.gd")
	var backend_report = BackendReportScript.new()
	var root = Node.new()
	root.add_child(backend_report)
	get_root().add_child(root)

	# Mock catalog containing ONLY Sao Truc lessons
	var mock_instruments = [
		{"id": 1, "instrumentCode": "sao_truc", "name": "Sáo Trúc"},
		{"id": 2, "instrumentCode": "dan_tranh", "name": "Đàn Tranh"}
	]
	var mock_lessons = [
		{
			"id": 101,
			"orderIndex": 1,
			"title": "Sáo Trúc Cơ Bản 1",
			"instrument": {"id": 1, "instrumentCode": "sao_truc", "name": "Sáo Trúc"}
		},
		{
			"id": 102,
			"orderIndex": 2,
			"title": "Sáo Trúc Cơ Bản 2",
			"instrument": {"id": 1, "instrumentCode": "sao_truc", "name": "Sáo Trúc"}
		}
	]

	SDM.install_be_catalog(mock_instruments, mock_lessons)
	print("[Check 1] Catalog installed with 2 Sao Truc lessons.")

	# Test 1: resolve_be_lesson for dan_tranh when only sao_truc exists
	var resolved_dan_tranh = SDM.resolve_be_lesson("dan_tranh", "Node1")
	print("[Check 2] resolve_be_lesson for dan_tranh: ", resolved_dan_tranh)
	assert(resolved_dan_tranh.is_empty(), "FAIL: dan_tranh must NOT resolve to a sao_truc lesson!")
	print(">>> PASS: dan_tranh resolved to empty Dictionary as expected.")

	# Mock quizzes & minigames in cache for sao_truc lesson 101
	SDM.cache_be_quizzes(101, [
		{"id": 501, "question": "Câu hỏi Sáo Trúc số 1", "correctAnswer": "A"}
	])
	SDM.cache_be_minigames(101, [
		{"id": 601, "title": "Game Sáo Trúc số 1", "challengeType": "RHYTHM_MATCH"}
	])

	# Test 2: fetch_quizzes_for_level for dan_tranh
	var quizzes = await backend_report.fetch_quizzes_for_level("dan_tranh", ["Node1"])
	print("[Check 3] Quizzes fetched for dan_tranh: size = ", quizzes.size())
	assert(quizzes.is_empty(), "FAIL: dan_tranh must NOT receive quizzes of sao_truc!")
	print(">>> PASS: dan_tranh received 0 quizzes from sao_truc.")

	# Test 3: fetch_minigames_for_level for dan_tranh
	var minigames = await backend_report.fetch_minigames_for_level("dan_tranh", ["Node1"], "RHYTHM_MATCH", false)
	print("[Check 4] Minigames fetched for dan_tranh: size = ", minigames.size())
	assert(minigames.is_empty(), "FAIL: dan_tranh must NOT receive minigames of sao_truc!")
	print(">>> PASS: dan_tranh received 0 minigames from sao_truc.")

	# Test 4: resolve_be_lesson for sao_truc should succeed
	var resolved_sao_truc = SDM.resolve_be_lesson("sao_truc", "Node1")
	print("[Check 5] resolve_be_lesson for sao_truc: id = ", resolved_sao_truc.get("id"))
	assert(int(resolved_sao_truc.get("id")) == 101, "FAIL: sao_truc should resolve to lesson 101!")
	print(">>> PASS: sao_truc correctly resolved to lesson 101.")

	var sao_truc_quizzes = await backend_report.fetch_quizzes_for_level("sao_truc", ["Node1"])
	print("[Check 6] Quizzes fetched for sao_truc: size = ", sao_truc_quizzes.size())
	assert(sao_truc_quizzes.size() == 1, "FAIL: sao_truc should receive its 1 quiz!")
	print(">>> PASS: sao_truc correctly received its quiz.")

	print("========================================")
	print("ALL ISOLATION TESTS PASSED SUCCESSFULLY!")
	print("========================================")
	quit()
