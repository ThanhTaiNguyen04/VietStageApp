extends RefCounted

static var instrument := "dan_tranh"
static var local_lesson_ids: Array[String] = []
static var return_scene := "res://scenes/MainMenu.tscn"
static var activity := ""

static func configure(instrument_key: String, lesson_ids: Array, scene_path: String) -> void:
	instrument = instrument_key
	local_lesson_ids.clear()
	for lesson_id: Variant in lesson_ids:
		local_lesson_ids.append(str(lesson_id))
	return_scene = scene_path
	activity = ""

static func ensure_defaults() -> void:
	if local_lesson_ids.is_empty():
		local_lesson_ids.append("Node1")
