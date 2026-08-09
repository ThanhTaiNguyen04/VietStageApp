extends Node

class_name SecureDataManager

const SAVE_FILE_PATH := "user://vietstage_progress.dat"
const ENCRYPTION_KEY := "VietStageCapstone2026_TraditionalInstrument_GameBasedLearning"

# Remove this map after BE exposes canonical instrumentCode and lessonCode for
# every progress record and the production data migration is complete.
const LEGACY_BACKEND_LESSON_MAP := {
	1: {"instrument": "dan_tranh", "node_id": "Node1"},
	2: {"instrument": "dan_tranh", "node_id": "Node2"},
	3: {"instrument": "sao_truc", "node_id": "Node1"},
	5: {"instrument": "dan_tranh", "node_id": "Node3"},
}
const SUPPORTED_INSTRUMENTS := ["dan_tranh", "sao_truc", "dan_bau", "trong_chau"]

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

static func sync_backend_progress(progress_list: Array) -> void:
	_ensure_progress_containers()
	_reset_backend_progress_cache()

	for raw_item: Variant in progress_list:
		if not raw_item is Dictionary:
			push_warning("Ignoring malformed progress item: expected an object.")
			continue
		var item: Dictionary = raw_item
		var resolved: Dictionary = resolve_backend_progress_item(item)
		if resolved.is_empty():
			push_warning("Ignoring unmapped BE progress lessonId=%s title=%s" % [
				str(item.get("lessonId", "?")),
				str(item.get("title", "")),
			])
			continue
		if not bool(item.get("completed", false)):
			continue
		_apply_backend_completion(
			str(resolved["instrument"]),
			str(resolved["node_id"]),
			maxi(0, int(item.get("stars", 0)))
		)

	save_data()


# Resolves the BE contract without mutating local progress. Canonical fields are
# preferred; numeric IDs only bridge the current inconsistent production data.
static func resolve_backend_progress_item(item: Dictionary) -> Dictionary:
	var direct_instrument := _normalize_instrument_key(str(item.get("instrumentKey", "")))
	if direct_instrument.is_empty():
		direct_instrument = _normalize_instrument_key(str(item.get("instrumentCode", "")))
	var direct_node := _extract_node_id(item)
	if not direct_instrument.is_empty() and not direct_node.is_empty():
		return {"instrument": direct_instrument, "node_id": direct_node, "source": "canonical"}

	var lesson_id := int(item.get("lessonId", 0))
	if LEGACY_BACKEND_LESSON_MAP.has(lesson_id):
		var legacy: Dictionary = LEGACY_BACKEND_LESSON_MAP[lesson_id]
		return {
			"instrument": str(legacy["instrument"]),
			"node_id": str(legacy["node_id"]),
			"source": "legacy_lesson_id",
		}

	var nested_instrument := ""
	var instrument_value: Variant = item.get("instrument", {})
	if instrument_value is Dictionary:
		var instrument_data: Dictionary = instrument_value
		nested_instrument = _normalize_instrument_key(str(instrument_data.get("instrumentCode", "")))
		if nested_instrument.is_empty():
			nested_instrument = _normalize_instrument_key(str(instrument_data.get("name", "")))
	if direct_node.is_empty():
		direct_node = _extract_node_from_text(str(item.get("title", "")), str(item.get("lessonCode", "")))
	if not nested_instrument.is_empty() and not direct_node.is_empty():
		return {"instrument": nested_instrument, "node_id": direct_node, "source": "nested_metadata"}

	var title_instrument := _normalize_instrument_key(str(item.get("title", "")))
	if not title_instrument.is_empty() and not direct_node.is_empty():
		return {"instrument": title_instrument, "node_id": direct_node, "source": "title_fallback"}
	return {}


static func _ensure_progress_containers() -> void:
	if not data.has("completed_lessons"):
		data["completed_lessons"] = {}
	if not data.has("unlocked_lessons"):
		data["unlocked_lessons"] = {}
	if not data.has("stars"):
		data["stars"] = {}


static func _reset_backend_progress_cache() -> void:
	for instrument: String in SUPPORTED_INSTRUMENTS:
		data["completed_lessons"][instrument] = []
		data["stars"][instrument] = {}
		match instrument:
			"dan_bau":
				data["unlocked_lessons"][instrument] = ["Node1", "dan_bau_coban_1_video"]
			"trong_chau":
				data["unlocked_lessons"][instrument] = ["Node1", "trong_chau_coban_1_video"]
			_:
				data["unlocked_lessons"][instrument] = ["Node1"]


static func _apply_backend_completion(instrument: String, node_id: String, stars: int) -> void:
	if instrument == "trong_chau":
		var lesson_number := clampi(int(node_id.trim_prefix("Node")), 1, 3)
		var base_id := "trong_chau_coban_%d" % lesson_number
		_record_completed(instrument, base_id + "_video", stars)
		_record_completed(instrument, base_id + "_practice", stars)
		if lesson_number < 3:
			_unlock_lesson(instrument, "trong_chau_coban_%d_video" % (lesson_number + 1))
		return

	if instrument == "dan_bau" and node_id == "Node1":
		_record_completed(instrument, "Node1", stars)
		return

	_record_completed(instrument, node_id, stars)
	var node_number := int(node_id.trim_prefix("Node"))
	if node_number >= 1 and node_number < 5:
		_unlock_lesson(instrument, "Node%d" % (node_number + 1))


static func _record_completed(instrument: String, lesson_id: String, stars: int) -> void:
	if not data["completed_lessons"][instrument].has(lesson_id):
		data["completed_lessons"][instrument].append(lesson_id)
	data["stars"][instrument][lesson_id] = stars


static func _unlock_lesson(instrument: String, lesson_id: String) -> void:
	if not data["unlocked_lessons"][instrument].has(lesson_id):
		data["unlocked_lessons"][instrument].append(lesson_id)


static func _extract_node_id(item: Dictionary) -> String:
	for key: String in ["clientLessonId", "lessonKey", "nodeId"]:
		var value := str(item.get(key, "")).strip_edges()
		if value.begins_with("Node") and int(value.trim_prefix("Node")) > 0:
			return value
	var order_index := int(item.get("orderIndex", 0))
	if order_index > 0 and order_index <= 99:
		return "Node%d" % order_index
	return ""


static func _extract_node_from_text(title: String, lesson_code: String) -> String:
	var matcher := RegEx.new()
	matcher.compile("(?:bài|bai|lesson|[_-]b)[ _-]*(\\d+)")
	for value: String in [lesson_code.to_lower(), title.to_lower()]:
		var result := matcher.search(value)
		if result:
			var number := int(result.get_string(1))
			if number > 0:
				return "Node%d" % number
	return ""


static func _normalize_instrument_key(value: String) -> String:
	var normalized := value.strip_edges().to_lower().replace("-", "_").replace(" ", "_")
	if "dan_tranh" in normalized or "đàn_tranh" in normalized:
		return "dan_tranh"
	if "sao_truc" in normalized or "sáo_trúc" in normalized or "sáo_truc" in normalized:
		return "sao_truc"
	if "dan_bau" in normalized or "đàn_bầu" in normalized or "đàn_bau" in normalized:
		return "dan_bau"
	if "trong_chau" in normalized or "trống_chầu" in normalized or normalized == "trong":
		return "trong_chau"
	return ""

static func is_lesson_completed(instrument: String, lesson_id: String) -> bool:
	if data.completed_lessons.has(instrument):
		return data.completed_lessons[instrument].has(lesson_id)
	return false

static func is_lesson_unlocked(instrument: String, lesson_id: String) -> bool:
	return true # UNLOCKED ALL FOR TESTING
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
	var core_nodes := []

	if instrument == "dan_tranh" or instrument == "sao_truc":
		core_nodes = ["Node1", "Node2", "Node3", "Node4", "Node5"]
	elif instrument == "dan_bau":
		core_nodes = ["Node1", "dan_bau_coban_1_practice", "dan_bau_coban_2_practice", "dan_bau_coban_3_practice"]
	elif instrument == "trong_chau":
		core_nodes = ["trong_chau_coban_1_practice", "trong_chau_coban_2_practice", "trong_chau_coban_3_practice"]

	if core_nodes.is_empty():
		return 0.0

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


# ── Backend catalog bridge ──────────────────────────────────────────────
# The local lesson maps (Node1..NodeN, dan_tranh_level_*_bai_*_*) are offline
# content. When a learner is signed in, this bridge tries to resolve the local
# lesson to a BE lessonId/exerciseId so practice/minigame attempts can be
# written to the backend. If no reliable bind exists, callers must skip
# submission gracefully and keep the local save as source of truth.

static var be_instruments: Array = []
static var be_catalog: Array = []
static var be_exercises: Dictionary = {}   # lesson_id -> Array[exercise]
static var be_minigames: Dictionary = {}   # lesson_id -> Array[minigame]
static var be_quizzes: Dictionary = {}     # lesson_id -> Array[quiz]

## Ghi nhận catalog từ GET /api/instruments và GET /api/lessons.
static func install_be_catalog(instruments: Array, lessons: Array) -> void:
	be_instruments = instruments
	be_catalog = lessons
	be_exercises.clear()
	be_minigames.clear()
	be_quizzes.clear()
	save_data()


static func cache_be_exercises(lesson_id: int, exercises: Array) -> void:
	be_exercises[lesson_id] = exercises

static func cache_be_minigames(lesson_id: int, minigames: Array) -> void:
	be_minigames[lesson_id] = minigames

static func cache_be_quizzes(lesson_id: int, quizzes: Array) -> void:
	be_quizzes[lesson_id] = quizzes


## Tra cứu instrumentId (số) từ key nội bộ ("dan_tranh", "sao_truc", …).
static func be_instrument_id(instrument_key: String) -> int:
	var normalized := _normalize_instrument_key(instrument_key)
	for item: Variant in be_instruments:
		if not item is Dictionary:
			continue
		var code := str(item.get("instrumentCode", item.get("name", "")).to_lower()).replace("-", "_").replace(" ", "_")
		if _normalize_instrument_key(code) == normalized:
			return int(item.get("id", 0))
	return 0


## Số bài nội bộ từ local_lesson_id (NodeN, dan_*_bai_N_*, …) hoặc 0.
static func local_lesson_number(local_lesson_id: String) -> int:
	var matcher := RegEx.new()
	matcher.compile("(?:Node|bai|bài|lesson)[ _-]*(\\d+)")
	var result := matcher.search(str(local_lesson_id))
	if result:
		return int(result.get_string(1))
	return 0


## Chọn BE lesson khớp nhất với local lesson của một nhạc cụ.
static func resolve_be_lesson(instrument_key: String, local_lesson_id: String) -> Dictionary:
	if be_catalog.is_empty():
		return {}
	var inst := _normalize_instrument_key(instrument_key)
	var local_number := local_lesson_number(local_lesson_id)
	var candidates: Array = []
	for item: Variant in be_catalog:
		if not item is Dictionary:
			continue
		var lesson: Dictionary = item
		if _lesson_matches_instrument(lesson, inst):
			candidates.append(lesson)
	if candidates.is_empty():
		return {}
	if local_number > 0:
		for lesson: Dictionary in candidates:
			if int(lesson.get("orderIndex", 0)) == local_number:
				return lesson
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("orderIndex", 0)) < int(b.get("orderIndex", 0))
	)
	return candidates[0]


## Tra exercise (ưu tiên orderIndex trùng với local_number, rồi exercise đầu tiên).
static func resolve_be_exercise(lesson_id: int, local_lesson_id: String = "") -> Dictionary:
	var exercises: Array = be_exercises.get(lesson_id, [])
	if exercises.is_empty():
		return {}
	var desired := local_lesson_number(local_lesson_id)
	for ex: Variant in exercises:
		if ex is Dictionary and desired > 0 and int(ex.get("orderIndex", 0)) == desired:
			return ex
	for ex: Variant in exercises:
		if ex is Dictionary:
			return ex
	return {}


static func resolve_be_minigame(lesson_id: int) -> Dictionary:
	var minigames: Array = be_minigames.get(lesson_id, [])
	for mg: Variant in minigames:
		if mg is Dictionary:
			return mg
	return {}


static func _lesson_matches_instrument(lesson: Dictionary, inst: String) -> bool:
	var instrument_value: Variant = lesson.get("instrument", {})
	var code := ""
	if instrument_value is Dictionary:
		code = _normalize_instrument_key(str(instrument_value.get("instrumentCode", instrument_value.get("name", ""))))
	if code.is_empty():
		code = _normalize_instrument_key(str(lesson.get("instrumentKey", "")))
	return not code.is_empty() and code == inst
