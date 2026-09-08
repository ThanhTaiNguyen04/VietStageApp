extends SceneTree

func _init() -> void:
	print("--- Testing Scene Instantiation ---")
	var scenes := [
		"res://scenes/SplashScreen.tscn",
		"res://scenes/LoadingScreen.tscn",
		"res://scenes/LoginScreen.tscn",
		"res://scenes/MainMenu.tscn",
		"res://scenes/LearningActivitiesScreen.tscn",
		"res://scenes/LearningQuizScreen.tscn",
		"res://scenes/RhythmChallengeScreen.tscn",
		"res://scenes/MelodyCompletionScreen.tscn",
		"res://scenes/ActivityHistoryScreen.tscn"
	]

	for scn_path in scenes:
		if not ResourceLoader.exists(scn_path):
			print("  [WARN] Scene does not exist: ", scn_path)
			continue
		var ps := load(scn_path) as PackedScene
		if ps == null:
			print("  [FAIL] Failed to load PackedScene: ", scn_path)
			quit(1)
			return
		var node = ps.instantiate()
		if node == null:
			print("  [FAIL] Failed to instantiate: ", scn_path)
			quit(1)
			return
		print("  [PASS] Successfully instantiated: ", scn_path, " (type: ", node.get_class(), ")")
		node.free()

	print("=== ALL SCENES INSTANTIATED CLEANLY ===")
	quit(0)
