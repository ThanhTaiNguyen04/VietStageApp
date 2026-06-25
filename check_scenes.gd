extends SceneTree

func _init():
	print("--- Headless Verification for Sáo Trúc ---")
	
	var script = load("res://scripts/PracticeSaoTruc.gd")
	if script == null:
		print("  [ERROR] FAILED to load res://scripts/PracticeSaoTruc.gd")
	else:
		print("  [OK] Script loaded successfully.")
		var instance = script.new()
		if instance == null:
			print("  [ERROR] FAILED to instantiate res://scripts/PracticeSaoTruc.gd")
		else:
			print("  [OK] Script instantiated successfully.")
			instance.free()

	var scene = load("res://scenes/PracticeSaoTruc.tscn")
	if scene == null:
		print("  [ERROR] FAILED to load res://scenes/PracticeSaoTruc.tscn")
	else:
		print("  [OK] Scene loaded successfully. Instantiating...")
		var instance = scene.instantiate()
		if instance == null:
			print("  [ERROR] FAILED to instantiate res://scenes/PracticeSaoTruc.tscn")
		else:
			print("  [OK] Scene instantiated successfully.")
			instance.queue_free()

	print("--- Verification Complete ---")
	quit()
