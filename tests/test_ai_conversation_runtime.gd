extends SceneTree

const Manager = preload("res://scripts/AIManager.gd")

func _initialize() -> void:
	var manager := Manager.new()
	root.add_child(manager)
	for question: String in ["hi", "Hãy giới thiệu sơ qua về sáo trúc", "Đàn tranh là gì?"]:
		manager.instrument_context = "general"
		manager.send_prompt(question)
		var started := Time.get_ticks_msec()
		while manager.client != null and Time.get_ticks_msec() - started < 95000:
			manager._process(0.01)
			OS.delay_msec(10)
		if manager.last_status != "ANSWERED":
			push_error("AI conversation failed: " + question + " " + manager.structured_buffer)
			manager.free()
			quit(1)
			return
		print("ANSWERED: ", question, " => ", manager.structured_buffer)
		var payload: Variant = JSON.parse_string(manager.structured_buffer)
		var language_check := RegEx.new()
		language_check.compile("[\\x{3400}-\\x{9FFF}]")
		if payload == null or language_check.search(str(payload.get("answer", ""))) != null:
			push_error("Unexpected response language: " + manager.structured_buffer)
			manager.free()
			quit(1)
			return
	manager.free()
	quit(0)
