extends SceneTree

func _init():
	var file = FileAccess.open("res://scripts/PracticeRoom.gd", FileAccess.READ)
	var content = file.get_as_text()
	file.close()

	var mapping = {
		"Sol": "Sol1", "La": "La1", "Đô": "Đô2", "Rê": "Rê2", "Mi": "Mi2",
		"Sol2": "Sol2", "La2": "La2", "Đô2": "Đô3", "Rê2": "Rê3", "Mi2": "Mi3",
		"Sol3": "Sol3", "La3": "La3", "Đô3": "Đô4", "Rê3": "Rê4", "Mi3": "Mi4",
		"Sol4": "Sol4"
	}

	var parts = content.split("\"Giấc Mơ Trưa\"")
	if parts.size() > 1:
		var old_part = parts[1]
		for note_key in mapping:
			# Replace backwards to avoid replacing 'Sol' inside 'Sol2'
			# Wait, replacing exact strings is better
			old_part = old_part.replace("\"" + note_key + "\"", "\"____" + note_key + "____\"")
			
		for note_key in mapping:
			old_part = old_part.replace("\"____" + note_key + "____\"", "\"" + mapping[note_key] + "\"")
			
		content = parts[0] + "\"Giấc Mơ Trưa\"" + old_part
		
	var out = FileAccess.open("res://scripts/PracticeRoom.gd", FileAccess.WRITE)
	out.store_string(content)
	out.close()
	print("Done replacing notes!")
	quit()
