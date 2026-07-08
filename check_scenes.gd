extends SceneTree

func _init():
	print("--- Headless Verification for Sáo Trúc & Đàn Tranh ---")
	
	var script = load("res://scripts/PracticeSaoTruc.gd")
	if script == null:
		print("  [ERROR] FAILED to load res://scripts/PracticeSaoTruc.gd")
	else:
		print("  [OK] PracticeSaoTruc script loaded successfully.")
		var instance = script.new()
		if instance == null:
			print("  [ERROR] FAILED to instantiate res://scripts/PracticeSaoTruc.gd")
		else:
			print("  [OK] PracticeSaoTruc script instantiated successfully.")
			instance.free()

	var scene = load("res://scenes/PracticeSaoTruc.tscn")
	if scene == null:
		print("  [ERROR] FAILED to load res://scenes/PracticeSaoTruc.tscn")
	else:
		print("  [OK] PracticeSaoTruc scene loaded successfully. Instantiating...")
		var instance = scene.instantiate()
		if instance == null:
			print("  [ERROR] FAILED to instantiate res://scenes/PracticeSaoTruc.tscn")
		else:
			print("  [OK] PracticeSaoTruc scene instantiated successfully.")
			instance.queue_free()

	var script_pr = load("res://scripts/PracticeRoom.gd")
	if script_pr == null:
		print("  [ERROR] FAILED to load res://scripts/PracticeRoom.gd")
	else:
		print("  [OK] PracticeRoom script loaded successfully.")
		var instance = script_pr.new()
		if instance == null:
			print("  [ERROR] FAILED to instantiate res://scripts/PracticeRoom.gd")
		else:
			print("  [OK] PracticeRoom script instantiated successfully.")
			instance.free()

	var scene_pr = load("res://scenes/PracticeRoom.tscn")
	if scene_pr == null:
		print("  [ERROR] FAILED to load res://scenes/PracticeRoom.tscn")
	else:
		print("  [OK] PracticeRoom scene loaded successfully. Instantiating...")
		var instance = scene_pr.instantiate()
		if instance == null:
			print("  [ERROR] FAILED to instantiate res://scenes/PracticeRoom.tscn")
		else:
			print("  [OK] PracticeRoom scene instantiated successfully.")
			instance.queue_free()

	var script_db = load("res://scripts/PracticeDanBau.gd")
	if script_db == null:
		print("  [ERROR] FAILED to load res://scripts/PracticeDanBau.gd")
	else:
		print("  [OK] PracticeDanBau script loaded successfully.")
		var instance = script_db.new()
		if instance == null:
			print("  [ERROR] FAILED to instantiate res://scripts/PracticeDanBau.gd")
		else:
			print("  [OK] PracticeDanBau script instantiated successfully.")
			instance.free()

	var scene_db = load("res://scenes/PracticeDanBau.tscn")
	if scene_db == null:
		print("  [ERROR] FAILED to load res://scenes/PracticeDanBau.tscn")
	else:
		print("  [OK] PracticeDanBau scene loaded successfully. Instantiating...")
		var instance = scene_db.instantiate()
		if instance == null:
			print("  [ERROR] FAILED to instantiate res://scenes/PracticeDanBau.tscn")
		else:
			print("  [OK] PracticeDanBau scene instantiated successfully.")
			instance.queue_free()

	print("--- Verification Complete ---")
	quit()

