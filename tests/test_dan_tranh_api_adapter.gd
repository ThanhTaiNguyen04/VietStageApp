extends SceneTree

const Adapter = preload("res://scripts/DanTranhApiAdapter.gd")

func _initialize() -> void:
	assert(not Adapter.REMOTE_CONTENT_ENABLED)
	var dto := {"id": 9, "lessonCode": "dan_tranh_level_1_bai_1_practice", "instrument": {"id": 3}, "skillLevel": {}, "exercises": []}
	var mapped := Adapter.map_lesson(dto, 3)
	assert(mapped["lessonId"] == 9)
	assert(mapped["lessonCode"] == dto["lessonCode"])
	assert(not mapped["practiceReady"])
	assert(Adapter.map_lesson(dto, 4).is_empty())
	assert(Adapter.unwrap_response({"success": false, "data": dto}).is_empty())
	var steps := Adapter.map_teacher_speech([
		{"content_text": "second", "order_index": 2},
		{"content_text": "first", "order_index": 1}
	])
	assert(steps[0]["text"] == "first")
	var bundled := {"local": [{"action": "speak", "text": "unchanged"}, {"action": "practice"}]}
	var copy := Adapter.bundled_dialogues("local", bundled)
	assert(copy.size() == 2)
	copy[0]["text"] = "changed"
	assert(bundled["local"][0]["text"] == "unchanged")
	assert(Adapter.bundled_dialogues("unknown", bundled).is_empty())
	print("Dan Tranh API adapter checks passed")
	quit()
