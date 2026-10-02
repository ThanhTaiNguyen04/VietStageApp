extends SceneTree

const Context = preload("res://scripts/LearningActivityContext.gd")
const AuthSessionStore = preload("res://scripts/AuthSession.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var small := OS.get_cmdline_user_args().has("small")
	root.size = Vector2i(960, 540) if small else Vector2i(1920, 886)
	if small:
		root.content_scale_size = Vector2i(960, 540)
	var compact := OS.get_cmdline_user_args().has("compact")
	root.set_meta("force_compact_layout", compact)
	AuthSessionStore._loaded = true
	AuthSessionStore.access_token = ""
	Context.configure("dan_tranh", ["Node1"], "res://scenes/MainMenu.tscn")
	Context.activity = "melody"
	var screen := (load("res://scenes/MelodyCompletionScreen.tscn") as PackedScene).instantiate()
	root.add_child(screen)
	for tick in 80:
		await process_frame
		if screen.get("practice_hud") != null and screen.get("melodies").size() > 0:
			break
	var hud := screen.get("practice_hud") as PracticeControlHud
	var backdrop := screen.get_child(0) as TextureRect
	var top_bar := screen.get("custom_top_bar") as PanelContainer
	if hud == null or backdrop == null or backdrop.texture == null or top_bar == null:
		printerr("Melody HUD failed to initialize")
		quit(1)
		return
	if backdrop.texture.resource_path != "res://assets/textures/bg_practice_room.png":
		printerr("Melody background differs from Mini-game 1")
		quit(1)
		return
	if hud.get_node_or_null("PracticeHudBack") == null or hud.get_node_or_null("PracticeHudSpeed") == null or hud.get_node_or_null("PracticeHudPause") == null:
		printerr("Shared HUD controls are missing")
		quit(1)
		return
	screen.call("_on_hud_speed_selected", 0.8)
	if not is_equal_approx(float(screen.get("selected_speed_multiplier")), 0.8):
		printerr("Melody tempo HUD does not control sample speed")
		quit(1)
		return
	if screen.find_child("MinigameTopBar", true, false) != null:
		printerr("Redundant progress bar is still visible")
		quit(1)
		return
	if screen.get("melodies").is_empty() or screen.get("melody_staff") == null:
		printerr("Melody round did not render")
		quit(1)
		return
	for tick in 4:
		await process_frame
	var staff := screen.get("melody_staff") as Control
	var staff_rect := Rect2(staff.global_position, staff.size)
	if compact and staff.custom_minimum_size.y > 148.0:
		printerr("Compact layout did not reduce notation height")
		quit(1)
		return
	var play_button := screen.get("listen_for_note_button") as Control
	if staff_rect.end.y >= play_button.global_position.y or staff_rect.size.y < 140.0 or staff.get("notes").is_empty():
		printerr("Notation is not shown before the play action")
		quit(1)
		return
	if staff_rect.position.y < top_bar.size.y or staff_rect.end.y > root.size.y or staff_rect.end.x > root.size.x:
		printerr("Melody notation is outside the activity viewport: ", staff_rect)
		quit(1)
		return
	if play_button.global_position.y + play_button.size.y > root.size.y or play_button.global_position.x + play_button.size.x > root.size.x:
		printerr("Play button is outside the activity viewport: ", play_button.get_global_rect())
		quit(1)
		return
	screen.set("microphone_armed", true)
	screen.call("_update_hud_layout")
	if not hud.get_node("PracticeHudPause").visible:
		printerr("Pause control is hidden during microphone capture")
		quit(1)
		return
	screen.call("_pause_microphone")
	if not bool(screen.get("microphone_paused")) or not hud.get_node("PracticeHudPauseOverlay").visible:
		printerr("Pause control did not stop microphone capture")
		quit(1)
		return
	screen.call("_restart_from_pause")
	if bool(screen.get("microphone_paused")) or hud.get_node("PracticeHudPauseOverlay").visible:
		printerr("Restart control did not return to the round")
		quit(1)
		return
	print("Melody shared HUD and backdrop PASS")
	screen.queue_free()
	for tick in 3:
		await process_frame
	quit(0)
