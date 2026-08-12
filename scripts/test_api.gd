extends SceneTree

func _init() -> void:
	var api = preload("res://scripts/ApiClient.gd").new()
	var root = Node.new()
	root.add_child(api)
	get_root().add_child(root)
	
	print("Fetching lessons...")
	var response = await api.get_lessons()
	print(response)
	
	quit()
