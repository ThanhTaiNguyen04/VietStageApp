extends SceneTree

func _init():
	print("--- Headless Verification for All Scenes ---")
	
	var scenes = [
		"res://scenes/SplashScreen.tscn",
		"res://scenes/LoadingScreen.tscn",
		"res://scenes/LoginScreen.tscn",
		"res://scenes/InstrumentSelect.tscn",
		"res://scenes/MainMenu.tscn",
		"res://scenes/VirtualMusicRoom.tscn",
		"res://scenes/PracticeRoom.tscn",
		"res://scenes/PracticeSaoTruc.tscn",
		"res://scenes/PracticeDanBau.tscn",
		"res://scenes/MiniGame.tscn",
		"res://scenes/MiniGameDanTranh.tscn",
		"res://scenes/MiniGameSaoTruc.tscn",
		"res://scenes/MiniGameDanBau.tscn",
		"res://scenes/SongScreen.tscn",
		"res://scenes/AccountScreen.tscn",
		"res://scenes/ProgressScreen.tscn",
		"res://scenes/VideoPlayer.tscn",
		"res://scenes/CustomPopup.tscn",
		"res://scenes/LessonDanBau.tscn"
	]
	
	var has_error = false
	
	for path in scenes:
		var scene = load(path)
		if scene == null:
			print("  [ERROR] FAILED to load: ", path)
			has_error = true
		else:
			print("  [OK] Loaded: ", path)
			var instance = scene.instantiate()
			if instance == null:
				print("  [ERROR] FAILED to instantiate: ", path)
				has_error = true
			else:
				print("  [OK] Instantiated: ", path)
				instance.queue_free()

	print("--- Verification Complete (has_error = ", has_error, ") ---")
	quit(1 if has_error else 0)
