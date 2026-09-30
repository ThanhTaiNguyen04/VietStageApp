extends RefCounted
## One completion key per lesson; video and practice are parts of that lesson.
const DT = preload("res://scripts/DanTranhBundledLessonData.gd")
const ST = preload("res://scripts/SaoTrucBundledLessonData.gd")

static func lessons(instrument: String, level: int = 0) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if instrument == "dan_tranh":
		for group: Dictionary in DT.LEVELS:
			var group_id := int(group.level)
			if level != 0 and group_id != level:
				continue
			for item: Dictionary in group.lessons:
				var prefix := "dan_tranh_level_%d_bai_%d_" % [group_id, int(item.number)]
				var practice := str(item.get("practice_id", prefix + "practice"))
				var video := str(item.get("video_id", prefix + "video"))
				var key := video if str(item.get("type", "practice")) == "video" else practice
				result.append({"id": key, "aliases": [practice, video], "level": group_id})
	elif instrument == "sao_truc":
		for item: Dictionary in ST.ALL_LESSONS:
			var group_id := int(ceil(float(item.level) / 2.0))
			if level == 0 or group_id == level:
				result.append({"id": str(item.id), "aliases": [str(item.id)], "level": group_id})
	return result

static func canonical(instrument: String, key: String) -> String:
	for item: Dictionary in lessons(instrument):
		if key == item.id or key in item.aliases:
			return str(item.id)
	return key

static func completed(instrument: String, key: String, state: Dictionary) -> bool:
	var values: Array = state.get("completed_lessons", {}).get(instrument, [])
	var target := canonical(instrument, key)
	for value: Variant in values:
		if canonical(instrument, str(value)) == target:
			return true
	return false

static func level_complete(instrument: String, level: int, state: Dictionary) -> bool:
	var items := lessons(instrument, level)
	if items.is_empty():
		return false
	for item: Dictionary in items:
		if not completed(instrument, str(item.id), state):
			return false
	return true

static func level_unlocked(instrument: String, level: int, state: Dictionary) -> bool:
	var previous := level - 1
	if instrument == "dan_tranh" and level == 7:
		previous = 2
	return level == 1 or level_complete(instrument, previous, state)

static func lesson_unlocked(instrument: String, key: String, state: Dictionary) -> bool:
	var target := canonical(instrument, key)
	for item: Dictionary in lessons(instrument):
		if item.id != target:
			continue
		if not level_unlocked(instrument, int(item.level), state):
			return false
		for previous: Dictionary in lessons(instrument, int(item.level)):
			if previous.id == target:
				return true
			if not completed(instrument, str(previous.id), state):
				return false
	return false
