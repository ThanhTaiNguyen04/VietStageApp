extends SceneTree

func _init():
	print("Checking PracticeRoom...")
	var script = load("res://scripts/PracticeRoom.gd")
	if script:
		print("Script loaded successfully!")
	else:
		print("Failed to load script!")
	
	var scene = load("res://scenes/PracticeRoom.tscn")
	if scene:
		print("Scene loaded successfully!")
	else:
		print("Failed to load scene!")
	
	quit()
