extends SceneTree
func _init():
	print("Checking AccountScreen...")
	var scene = load("res://scenes/AccountScreen.tscn")
	if scene:
		print("AccountScreen loaded!")
		var instance = scene.instantiate()
		if instance:
			print("AccountScreen instantiated!")
	quit()
