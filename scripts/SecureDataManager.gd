extends Node

class_name SecureDataManager

const SAVE_FILE_PATH := "user://vietstage_progress.dat"
const ENCRYPTION_KEY := "VietStageCapstone2026_TraditionalInstrument_GameBasedLearning"

# Default player state synchronized across all scenes
static var data := {
	"selected_instrument": "dan_tranh",
	"is_premium": false,
	"unlocked_lessons": {
		"dan_tranh": ["Node1", "Node2"],
		"sao_truc": ["Node1", "Node2"]
	},
	"completed_lessons": {
		"dan_tranh": [],
		"sao_truc": []
	},
	"stars": {
		"dan_tranh": {},
		"sao_truc": {}
	},
	"daily_streak": 1,
	"last_practice_date": "",
	"practice_time_seconds": 0
}

static func save_data() -> void:
	var json_str := JSON.stringify(data)
	var file := FileAccess.open_encrypted_with_pass(SAVE_FILE_PATH, FileAccess.WRITE, ENCRYPTION_KEY)
	if file:
		file.store_string(json_str)
		file.close()
	else:
		printerr("Failed to save secure offline data.")

static func load_data() -> void:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		# Default initialization
		save_data()
		return
		
	var file := FileAccess.open_encrypted_with_pass(SAVE_FILE_PATH, FileAccess.READ, ENCRYPTION_KEY)
	if file:
		var json_str := file.get_as_text()
		file.close()
		
		var json := JSON.new()
		var parse_err := json.parse(json_str)
		if parse_err == OK:
			var parsed_data = json.get_data()
			if parsed_data is Dictionary:
				for key in parsed_data.keys():
					data[key] = parsed_data[key]
			else:
				save_data()
		else:
			printerr("Secure save file corrupted. Resetting data.")
			save_data()
	else:
		printerr("Failed to decrypt secure offline data. Resetting data.")
		save_data()

static func is_lesson_completed(instrument: String, lesson_id: String) -> bool:
	if data.completed_lessons.has(instrument):
		return data.completed_lessons[instrument].has(lesson_id)
	return false

static func is_lesson_unlocked(instrument: String, lesson_id: String) -> bool:
	if data.unlocked_lessons.has(instrument):
		return data.unlocked_lessons[instrument].has(lesson_id)
	return false

static func complete_lesson(instrument: String, lesson_id: String, stars: int) -> void:
	if not data.completed_lessons.has(instrument):
		data.completed_lessons[instrument] = []
	if not data.completed_lessons[instrument].has(lesson_id):
		data.completed_lessons[instrument].append(lesson_id)
		
	if not data.stars.has(instrument):
		data.stars[instrument] = {}
	data.stars[instrument][lesson_id] = max(stars, data.stars[instrument].get(lesson_id, 0))
	
	# Unlock the next lesson in sequence (e.g. Node1 -> unlocks Node2, Node2 -> unlocks Node3)
	var next_lesson_id := ""
	if lesson_id == "Node1":
		next_lesson_id = "Node2"
	elif lesson_id == "Node2":
		next_lesson_id = "Node3"
	elif lesson_id == "Node3":
		next_lesson_id = "Node4"
	elif lesson_id == "Node4":
		next_lesson_id = "Node5"
		
	if next_lesson_id != "" and not data.unlocked_lessons[instrument].has(next_lesson_id):
		data.unlocked_lessons[instrument].append(next_lesson_id)
		
	save_data()
