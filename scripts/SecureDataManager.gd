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
static var active_lesson_id := "Node1"
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
	"active_decorations": [],
	"pending_game_attempts": []
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
		var instrument := str(resolved["instrument"])
		var node_id := str(resolved["node_id"])
		if bool(item.get("completed", false)):
			_apply_backend_completion(instrument, node_id, maxi(0, int(item.get("stars", 0))))
		else:
			_remove_backend_completion(instrument, node_id)

	save_data()


## Chỉ gọi sau khi backend xác nhận hoàn thành bài.
static func apply_confirmed_lesson_completion(
	instrument: String,
	local_lesson_id: String,
	stars: int
) -> void:
	_ensure_progress_containers()
	var normalized := _normalize_instrument_key(instrument)
	if normalized.is_empty():
		normalized = instrument
	if not data["completed_lessons"].has(normalized):
		data["completed_lessons"][normalized] = []
	if not data["stars"].has(normalized):
		data["stars"][normalized] = {}
	if not data["unlocked_lessons"].has(normalized):
		data["unlocked_lessons"][normalized] = ["Node1"]
	_record_completed(normalized, local_lesson_id, maxi(0, stars))
	var lesson_number := local_lesson_number(local_lesson_id)
	if lesson_number > 0:
		_unlock_lesson(normalized, "Node%d" % (lesson_number + 1))
	save_data()


## Đồng bộ ví sao/điểm từ response thưởng của backend.
static func apply_backend_reward(reward_data: Dictionary) -> void:
	if reward_data.has("totalStars"):
		data["stars_total"] = maxi(0, int(reward_data.get("totalStars", 0)))
	elif reward_data.has("total_stars"):
		data["stars_total"] = maxi(0, int(reward_data.get("total_stars", 0)))
	if reward_data.has("spendableStars"):
		data["spendable_stars"] = maxi(0, int(reward_data.get("spendableStars", 0)))
	elif reward_data.has("spendable_stars"):
		data["spendable_stars"] = maxi(0, int(reward_data.get("spendable_stars", 0)))
	if reward_data.has("totalPoints"):
		data["xp"] = maxi(0, int(reward_data.get("totalPoints", 0)))
	elif reward_data.has("total_points"):
		data["xp"] = maxi(0, int(reward_data.get("total_points", 0)))
	save_data()


## Persist attempts until the authoritative backend has acknowledged them.
static func enqueue_pending_game_attempt(attempt: Dictionary) -> void:
	if not data.has("pending_game_attempts") or not (data["pending_game_attempts"] is Array):
		data["pending_game_attempts"] = []
	var attempt_id := str(attempt.get("client_attempt_id", ""))
	if attempt_id.is_empty():
		return
	for existing: Variant in data["pending_game_attempts"]:
		if existing is Dictionary and str(existing.get("client_attempt_id", "")) == attempt_id:
			return
	data["pending_game_attempts"].append(attempt.duplicate(true))
	save_data()


static func get_pending_game_attempts() -> Array:
	var value: Variant = data.get("pending_game_attempts", [])
	return value.duplicate(true) if value is Array else []


static func remove_pending_game_attempt(client_attempt_id: String) -> void:
	if not data.has("pending_game_attempts") or not (data["pending_game_attempts"] is Array):
		return
	data["pending_game_attempts"] = (data["pending_game_attempts"] as Array).filter(func(item: Variant) -> bool:
		return not (item is Dictionary and str(item.get("client_attempt_id", "")) == client_attempt_id)
	)
	save_data()


static func sync_backend_summary(summary_data: Dictionary) -> void:
	if not data.has("xp"):
		data["xp"] = 0
	if not data.has("stars_total"):
		data["stars_total"] = 0
	
	data["daily_streak"] = int(summary_data.get("current_streak", summary_data.get("currentStreak", data.get("daily_streak", 1))))
	data["xp"] = int(summary_data.get("total_points", summary_data.get("totalPoints", data.get("xp", 0))))
	data["stars_total"] = int(summary_data.get("total_stars", summary_data.get("totalStars", data.get("stars_total", 0))))
	data["spendable_stars"] = int(summary_data.get(
		"spendable_stars",
		summary_data.get("spendableStars", data.get("spendable_stars", data.get("stars_total", 0)))
	))
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


static func _remove_backend_completion(instrument: String, node_id: String) -> void:
	var local_ids: Array[String] = [node_id]
	if instrument == "trong_chau":
		var lesson_number := clampi(int(node_id.trim_prefix("Node")), 1, 3)
		local_ids = [
			"trong_chau_coban_%d_video" % lesson_number,
			"trong_chau_coban_%d_practice" % lesson_number,
		]
	for local_id in local_ids:
		if data["completed_lessons"].has(instrument):
			data["completed_lessons"][instrument].erase(local_id)
		if data["stars"].has(instrument):
			data["stars"][instrument].erase(local_id)


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
	#if data.unlocked_lessons.has(instrument):
	#	return data.unlocked_lessons[instrument].has(lesson_id)
	#return false

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
	# Dùng tổng sao do backend đồng bộ làm nguồn chính. Chỉ cộng dữ liệu bài học
	# cục bộ khi chưa từng nhận được summary (chế độ offline).
	if data.has("stars_total"):
		return maxi(0, int(data.get("stars_total", 0)))
	var total := 0
	if data.has("stars"):
		for inst in data.stars.keys():
			for lesson_id in data.stars[inst].keys():
				total += int(data.stars[inst][lesson_id])
	return total


## Số sao hiện còn có thể dùng để mua vật phẩm. Khi backend chưa từng trả
## spendableStars, dùng tổng sao làm fallback để tương thích dữ liệu cũ.
static func get_spendable_stars() -> int:
	if data.has("spendable_stars"):
		return maxi(0, int(data.get("spendable_stars", 0)))
	return get_total_stars()

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
	matcher.compile("(?:Node|bai|bài|lesson|coban|co_ban|cơ_bản)[ _-]*(\\d+)")
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
		for lesson: Dictionary in be_catalog:
			var id := int(lesson.get("id", 0))
			if LEGACY_BACKEND_LESSON_MAP.has(id):
				var legacy: Dictionary = LEGACY_BACKEND_LESSON_MAP[id]
				if str(legacy.get("instrument", "")) == inst and str(legacy.get("node_id", "")) == local_lesson_id:
					return lesson
		return {}
		
	if local_number > 0:
		for lesson: Dictionary in candidates:
			if int(lesson.get("orderIndex", lesson.get("order_index", 0))) == local_number:
				return lesson
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var order_a = int(a.get("orderIndex", a.get("order_index", 0)))
		var order_b = int(b.get("orderIndex", b.get("order_index", 0)))
		return order_a < order_b
	)
	return candidates[0]


## Chỉ trả lesson khi KHỚP CHÍNH XÁC (orderIndex == số bài local, hoặc legacy map).
## Trả {} nếu chỉ có fallback candidates[0] — dùng cho report_practice để
## tránh gửi điểm nhầm sang lesson khác khi BE chưa có bài tương ứng.
static func resolve_be_lesson_exact(instrument_key: String, local_lesson_id: String) -> Dictionary:
	if be_catalog.is_empty():
		return {}
	var inst := _normalize_instrument_key(instrument_key)
	var local_number := local_lesson_number(local_lesson_id)

	if local_number > 0:
		for lesson: Dictionary in be_catalog:
			if not _lesson_matches_instrument(lesson, inst):
				continue
			if int(lesson.get("orderIndex", lesson.get("order_index", 0))) == local_number:
				return lesson
	# Legacy map: khớp đúng id lesson BE
	for lesson: Dictionary in be_catalog:
		var id := int(lesson.get("id", 0))
		if LEGACY_BACKEND_LESSON_MAP.has(id):
			var legacy: Dictionary = LEGACY_BACKEND_LESSON_MAP[id]
			if str(legacy.get("instrument", "")) == inst and str(legacy.get("node_id", "")) == local_lesson_id:
				return lesson
	return {}


## Trả về danh sách lessonId của một nhạc cụ trong catalog (dùng để bỏ ràng buộc lesson khi test).
static func be_lesson_ids_for_instrument(instrument_key: String) -> Array[int]:
	var inst := _normalize_instrument_key(instrument_key)
	var ids: Array[int] = []
	for item: Variant in be_catalog:
		if not item is Dictionary:
			continue
		var lesson: Dictionary = item
		if _lesson_matches_instrument(lesson, inst):
			ids.append(int(lesson.get("id", 0)))
	return ids


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
	if not code.is_empty() and code == inst:
		return true
	var inst_id := int(lesson.get("instrumentId", lesson.get("instrument_id", 0)))
	if inst_id > 0 and inst_id == be_instrument_id(inst):
		return true
	return false

# ── Adaptive Difficulty (FE) ──────────────────────────────────────────────────
# Keeps a rolling history of the last 10 practice scores per lesson and suggests
# a tempo multiplier (0.6x–1.2x) so learners slow down when struggling and speed
# up when consistently accurate.

const ADAPTIVE_HISTORY_MAX := 10

static func record_practice_result(lesson_id: String, composite_score: float) -> void:
	if lesson_id.is_empty():
		return
	_ensure_adaptive_history()
	var inst := _adaptive_instrument_key(lesson_id)
	var history: Array = data["adaptive_history"].get(inst, [])
	var entry := {
		"lesson_id": lesson_id,
		"score": clampf(composite_score, 0.0, 100.0),
		"at": Time.get_unix_time_from_system(),
	}
	history.append(entry)
	if history.size() > ADAPTIVE_HISTORY_MAX:
		history = history.slice(history.size() - ADAPTIVE_HISTORY_MAX)
	data["adaptive_history"][inst] = history
	save_data()

static func get_rolling_accuracy(lesson_id: String) -> float:
	_ensure_adaptive_history()
	var inst := _adaptive_instrument_key(lesson_id)
	var history: Array = data["adaptive_history"].get(inst, [])
	if history.is_empty():
		return -1.0
	var total := 0.0
	var count := 0
	for entry: Variant in history:
		if entry is Dictionary:
			total += float(entry.get("score", 0.0))
			count += 1
	if count == 0:
		return -1.0
	return total / float(count)

static func get_recent_attempt_count(lesson_id: String) -> int:
	_ensure_adaptive_history()
	var inst := _adaptive_instrument_key(lesson_id)
	return int(data["adaptive_history"].get(inst, []).size())

## Tempo multiplier suggested by the last 10 attempts:
## >=90% -> 1.2x (mastered), 75–89 -> 1.0x, 60–74 -> 0.8x, <60 -> 0.6x.
static func get_adaptive_tempo_multiplier(lesson_id: String) -> float:
	var acc := get_rolling_accuracy(lesson_id)
	if acc < 0.0:
		return 1.0
	if acc >= 90.0:
		return 1.2
	if acc >= 75.0:
		return 1.0
	if acc >= 60.0:
		return 0.8
	return 0.6

## Persisted adaptive difficulty label for the profile screen (0 = Chưa đủ dữ liệu).
static func get_adaptive_difficulty(lesson_id: String = "") -> int:
	if lesson_id.is_empty():
		return int(data.get("adaptive_difficulty", 0))
	var acc := get_rolling_accuracy(lesson_id)
	if acc < 0.0:
		return int(data.get("adaptive_difficulty", 0))
	if acc >= 90.0:
		return 3
	if acc >= 75.0:
		return 2
	return 1

static func _ensure_adaptive_history() -> void:
	if not data.has("adaptive_history"):
		data["adaptive_history"] = {}

static func _adaptive_instrument_key(lesson_id: String) -> String:
	var parts := lesson_id.split("_")
	if parts.size() >= 2 and parts[0] == "dan" and parts[1] in ["tranh", "bau"]:
		return parts[0] + "_" + parts[1]
	if parts.size() >= 2 and parts[0] in ["sao", "trong"]:
		return parts[0] + "_" + parts[1]
	return "dan_tranh"
