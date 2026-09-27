extends SceneTree

const Manager = preload("res://scripts/AIManager.gd")
var spoken: Array = []
var errors: Array = []

func _initialize() -> void:
	var manager := Manager.new()
	manager.response_chunk_received.connect(func(text: String, _emotion: String): spoken.append(text))
	manager.request_failed.connect(func(text: String): errors.append(text))
	var valid := {"success": true, "status": "ANSWERED", "inScope": true, "answer": "Sáo Trúc là nhạc cụ hơi.", "sources": ["SAO_TRUC_OVERVIEW"]}
	manager._http_status = 200
	manager.structured_buffer = JSON.stringify(valid)
	manager._finish_structured_response()
	assert(spoken.size() == 1)
	assert(manager.last_status == "ANSWERED")
	var invalid := valid.duplicate(true)
	invalid.erase("status")
	manager.structured_buffer = JSON.stringify(invalid)
	manager._finish_structured_response()
	assert(spoken.size() == 1 and errors.size() == 1)
	invalid = valid.duplicate(true)
	invalid["inScope"] = "true"
	assert(not Manager.is_valid_chat_response(invalid))
	invalid = valid.duplicate(true)
	invalid["sources"] = []
	assert(not Manager.is_valid_chat_response(invalid))
	for status: String in ["OUT_OF_SCOPE", "INSUFFICIENT_KNOWLEDGE"]:
		var refusal := {"success": true, "status": status, "inScope": status == "INSUFFICIENT_KNOWLEDGE", "answer": "Mai chưa thể trả lời câu hỏi này.", "sources": []}
		manager.structured_buffer = JSON.stringify(refusal)
		manager._finish_structured_response()
	assert(spoken.size() == 3)
	manager._http_status = 404
	manager._finish_structured_response()
	assert(manager.client == null and spoken.size() == 3)
	manager.api_url = "http://127.0.0.1:3000/api/chat"
	manager.use_structured_json = false
	assert(manager._parse_api_target()["path"] == "/api/chat/json")
	manager.free()
	print("AI chat contract: passed")
	quit()
