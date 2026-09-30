extends SceneTree

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var file := FileAccess.open_encrypted_with_pass("C:/Users/phamm/AppData/Roaming/Godot/app_userdata/VietStage/vietstage_auth.dat", FileAccess.READ, "VietStageAuthSession2026")
	if file == null:
		print("No readable saved session")
		quit()
		return
	var session: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	var http := HTTPRequest.new()
	root.add_child(http)
	http.timeout = 30
	for endpoint in ["instruments", "users/me/progress", "users/me/lessons/50/complete"]:
		var err := http.request("https://vietstage-web-backend.onrender.com/api/" + endpoint, PackedStringArray(["Authorization: Bearer " + str(session.get("access_token", ""))]))
		if err != OK:
			print("Request failed: ", err)
			continue
		var result: Array = await http.request_completed
		print(endpoint, " HTTP ", result[1])
		if int(result[1]) == 200:
			var body: Dictionary = JSON.parse_string(result[3].get_string_from_utf8())
			if endpoint == "users/me":
				print("Account matches requested: ", str(body.get("data", {}).get("email", "")) == "thanhdattb19@gmail.com")
			else:
				var out := FileAccess.open("res://scratchpad/audit_" + endpoint.split("?")[0].replace("/", "_") + ".json", FileAccess.WRITE)
				out.store_string(JSON.stringify(body, "\t"))
	quit()
