extends SceneTree

const PracticeControlHudScript = preload("res://scripts/PracticeControlHud.gd")

var selected_speed := 0.0
var events: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var hud = PracticeControlHudScript.new()
	get_root().add_child(hud)
	await process_frame
	hud.speed_selected.connect(func(value: float) -> void: selected_speed = value)
	hud.back_requested.connect(func() -> void: events.append("back"))
	hud.pause_requested.connect(func() -> void: events.append("pause"))
	hud.resume_requested.connect(func() -> void: events.append("resume"))
	hud.restart_requested.connect(func() -> void: events.append("restart"))
	hud.sample_requested.connect(func() -> void: events.append("sample"))

	for speed in {"Speed60": 0.6, "Speed80": 0.8, "Speed100": 1.0, "Speed120": 1.2}:
		var button := hud.find_child(speed, true, false) as Button
		assert(button != null, "Missing speed button %s" % speed)
		button.pressed.emit()
		assert(is_equal_approx(selected_speed, float({"Speed60": 0.6, "Speed80": 0.8, "Speed100": 1.0, "Speed120": 1.2}[speed])), "Incorrect multiplier for %s" % speed)
	# Exercise every exposed action through its button signal.
	(hud.get_node("PracticeHudBack") as Button).pressed.emit()
	(hud.get_node("PracticeHudPause") as Button).pressed.emit()
	hud.set_pause_visible(true)
	(hud.find_child("Tiếp tục", true, false) as Button).pressed.emit()
	(hud.find_child("Chơi lại", true, false) as Button).pressed.emit()
	(hud.find_child("Nghe mẫu", true, false) as Button).pressed.emit()
	assert(events == ["back", "pause", "resume", "restart", "sample"])
	assert(hud.get_node("PracticeHudPauseOverlay").visible)
	print("Practice control HUD: PASS")
	quit()
