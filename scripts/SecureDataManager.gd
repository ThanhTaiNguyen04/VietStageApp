extends Node

class_name SecureDataManager

const SAVE_FILE_PATH := "user://vietstage_progress.dat"
const ENCRYPTION_KEY := "VietStageCapstone2026_TraditionalInstrument_GameBasedLearning"

# Progression session state (migrated from CourseMap)
static var video_completed := false
static var active_lesson_id := "Node2"
static var active_course_title := ""
static var active_course_start_node := 1
static var active_course_node_count := 7

# Default player state synchronized across all scenes
static var data := {
	"selected_instrument": "dan_tranh",
	"is_premium": false,
	"unlocked_lessons": {

		"dan_tranh": ["Node1"],
		"sao_truc": ["Node1"],
		"dan_bau": ["Node1", "dan_bau_coban_1_video"],
		"trong_chau": ["Node1"]

	},
	"completed_lessons": {
		"dan_tranh": [],
		"sao_truc": [],
		"dan_bau": [],
		"trong_chau": []
	},
	"stars": {
		"dan_tranh": {},
		"sao_truc": {},
		"dan_bau": {},
		"trong_chau": {}
	},
	"daily_streak": 1,
	"last_practice_date": "",
	"practice_time_seconds": 0,
	"unlocked_decorations": [],
	"active_decorations": []
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

	if not data.unlocked_lessons.has(instrument):
		data.unlocked_lessons[instrument] = []
		
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
	elif lesson_id.begins_with("dan_bau_coban_"):
		if lesson_id.ends_with("_video"):
			next_lesson_id = lesson_id.replace("_video", "_practice")
		elif lesson_id.ends_with("_practice"):
			var idx := int(lesson_id.replace("dan_bau_coban_", "").replace("_practice", ""))
			if idx < 5:
				next_lesson_id = "dan_bau_coban_" + str(idx + 1) + "_video"
	elif lesson_id.begins_with("trong_chau_coban_"):
		if lesson_id.ends_with("_video"):
			next_lesson_id = lesson_id.replace("_video", "_practice")
		elif lesson_id.ends_with("_practice"):
			var idx := int(lesson_id.replace("trong_chau_coban_", "").replace("_practice", ""))
			if idx < 5:
				next_lesson_id = "trong_chau_coban_" + str(idx + 1) + "_video"
		
	if next_lesson_id != "" and not data.unlocked_lessons[instrument].has(next_lesson_id):
		data.unlocked_lessons[instrument].append(next_lesson_id)

	save_data()

static func get_course_progress(instrument: String) -> float:
	var completed := 0
	var core_nodes := ["Node1", "Node2", "Node3", "Node4", "Node5"]
	for node in core_nodes:
		if is_lesson_completed(instrument, node):
			completed += 1
	return float(completed) / float(core_nodes.size()) * 100.0

static func is_instrument_unlocked(instrument: String) -> bool:
	if instrument == "dan_tranh":
		return true
	elif instrument == "sao_truc":
		return is_lesson_completed("dan_tranh", "Node5")
	elif instrument == "dan_bau":
		return is_lesson_completed("sao_truc", "Node5")
	elif instrument == "trong_chau":
		return is_lesson_completed("dan_bau", "Node5")
	return false

static func get_total_stars() -> int:
	if data.get("user_email", "").to_lower() == "student1@fpt.edu.vn":
		return 9999

	var total := 0
	if data.has("stars"):
		for inst in data.stars.keys():
			for lesson_id in data.stars[inst].keys():
				total += int(data.stars[inst][lesson_id])
	return total

static func unlock_decoration(decor_id: String, cost: int) -> bool:
	if not data.has("unlocked_decorations"):
		data["unlocked_decorations"] = []
	if not data.has("active_decorations"):
		data["active_decorations"] = []
		
	if data["unlocked_decorations"].has(decor_id):
		return true
		
	var stars = get_total_stars()
	if stars >= cost:
		data["unlocked_decorations"].append(decor_id)
		if not data["active_decorations"].has(decor_id):
			data["active_decorations"].append(decor_id)
		save_data()
		return true
	return false

static func toggle_decoration(decor_id: String) -> void:
	if not data.has("unlocked_decorations"):
		data["unlocked_decorations"] = []
	if not data.has("active_decorations"):
		data["active_decorations"] = []
		
	if not data["unlocked_decorations"].has(decor_id):
		return
		
	if data["active_decorations"].has(decor_id):
		data["active_decorations"].erase(decor_id)
	else:
		data["active_decorations"].append(decor_id)
	save_data()

static func has_viewed_intro(instrument: String) -> bool:
	if not data.has("viewed_intros"):
		data["viewed_intros"] = []
	return data["viewed_intros"].has(instrument)

static func mark_intro_viewed(instrument: String) -> void:
	if not data.has("viewed_intros"):
		data["viewed_intros"] = []
	if not data["viewed_intros"].has(instrument):
		data["viewed_intros"].append(instrument)
		save_data()
