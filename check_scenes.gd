extends SceneTree

func _init():
	var log_file := FileAccess.open("res://scenes_check_results.log", FileAccess.WRITE)
	if not log_file:
		printerr("Cannot open log file")
		quit(1)
		return
		
	log_file.store_line("--- Headless Verification for All Scenes ---")
	
	var scenes = [
		"res://scenes/PracticeTrongChau.tscn",
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
		"res://scenes/MiniGameTrongChau.tscn",
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
			log_file.store_line("  [ERROR] FAILED to load: " + path)
			has_error = true
		else:
			log_file.store_line("  [OK] Loaded: " + path)
			var instance = scene.instantiate()
			if instance == null:
				log_file.store_line("  [ERROR] FAILED to instantiate: " + path)
				has_error = true
			else:
				log_file.store_line("  [OK] Instantiated: " + path)
				instance.queue_free()

	log_file.store_line("--- Verification Complete (has_error = " + str(has_error) + ") ---")
	log_file.close()
	quit(1 if has_error else 0)
