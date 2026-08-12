extends SceneTree

func _init() -> void:
	print("--- STARTING TEST ---")
	
	var http = HTTPRequest.new()
	var root = Node.new()
	root.add_child(http)
	get_root().add_child(root)
	
	http.request_completed.connect(self._on_completed)
	
	var err = http.request("https://vietstage-web-backend.onrender.com/api/lessons")
	if err != OK:
		print("Failed to request: ", err)
		quit()
		return

func _on_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	print("Result: ", result)
	print("Code: ", response_code)
	var text = body.get_string_from_utf8()
	
	var file = FileAccess.open("e:\\VietStageApp\\api_lessons.json", FileAccess.WRITE)
	if file:
		file.store_string(text)
		file.close()
		print("Saved to api_lessons.json")
	else:
		print("Failed to save.")
		
	quit()
