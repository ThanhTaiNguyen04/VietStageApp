extends SceneTree

func _init():
	print("Checking MainMenu...")
	var scene = load("res://scenes/MainMenu.tscn")
	if scene:
		print("MainMenu loaded!")
		var instance = scene.instantiate()
		if instance:
			print("MainMenu instantiated!")
	quit()
