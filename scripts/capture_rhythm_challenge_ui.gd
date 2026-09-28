extends SceneTree

const Context = preload("res://scripts/LearningActivityContext.gd")
const AuthSession = preload("res://scripts/AuthSession.gd")

const PLAYING := 4
const FINAL_RESULT := 7

var screen: Control
var capture_dir := "E:/VietStage_web/.tools/captures"
var capture_prefix := "desktop"
var force_compact := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var width := 1366
	var height := 768
	var args := OS.get_cmdline_user_args()
	for index in args.size():
		if args[index] == "--width" and index + 1 < args.size():
			width = int(args[index + 1])
		elif args[index] == "--height" and index + 1 < args.size():
			height = int(args[index + 1])
		elif args[index] == "--prefix" and index + 1 < args.size():
			capture_prefix = args[index + 1]
		elif args[index] == "--compact":
			force_compact = true
	get_root().content_scale_size = Vector2i(width, height)
	DisplayServer.window_set_size(Vector2i(width, height))
	if force_compact:
		get_root().set_meta("force_compact_layout", true)
	DirAccess.make_dir_recursive_absolute(capture_dir)

	AuthSession.access_token = ""
	AuthSession.refresh_token = ""
	AuthSession.session_id = ""
	AuthSession._loaded = true
	Context.configure("dan_tranh", ["Node1"], "res://scenes/MainMenu.tscn")

	var scene_resource := load("res://scenes/RhythmChallengeScreen.tscn") as PackedScene
	if scene_resource == null:
		push_error("Không thể load RhythmChallengeScreen")
		quit(1)
		return
	screen = scene_resource.instantiate() as Control
	get_root().add_child(screen)
	await _wait_frames(5)
	_save_capture("intro")
	if force_compact:
		await _save_scroll_bottom("intro_bottom")

	screen.call("_start_round")
	if not await _wait_for_state(PLAYING, 4.0):
		push_error("Không vào được PLAYING khi chụp UI")
		quit(1)
		return
	await create_timer(0.35).timeout
	await _wait_frames(2)
	_save_capture("playing")
	if force_compact:
		await _save_scroll_bottom("playing_bottom")
	screen.call("_pause_round")
	await _wait_frames(2)
	_save_capture("paused")
	screen.call("_resume_round")

	var beats: Array = screen.get("beat_times")
	for beat_value: Variant in beats:
		var target := float(beat_value)
		while float(Time.get_ticks_msec() - int(screen.get("round_started_at_ms"))) / 1000.0 < target:
			await process_frame
		screen.call("_tap")
	if not await _wait_for_state(FINAL_RESULT, 5.0):
		push_error("Không vào được FINAL_RESULT khi chụp UI")
		quit(1)
		return
	await _wait_frames(4)
	_save_capture("result")
	if force_compact:
		await _save_scroll_bottom("result_bottom")
	print("[RhythmCapture] PASS: %s" % capture_prefix)
	screen.queue_free()
	await _wait_frames(2)
	quit(0)


func _wait_for_state(expected: int, timeout_seconds: float) -> bool:
	var started := Time.get_ticks_msec()
	while float(Time.get_ticks_msec() - started) / 1000.0 < timeout_seconds:
		if is_instance_valid(screen) and int(screen.get("flow_state")) == expected:
			return true
		await process_frame
	return false


func _wait_frames(count: int) -> void:
	for _index in count:
		await process_frame


func _save_capture(state_name: String) -> void:
	if state_name in ["intro", "playing"]:
		for node_name in ["RhythmCustomTopBar", "RhythmTitlePlaque", "RhythmPreviewStaff", "RhythmStaff", "RhythmCompactFooter"]:
			var node := screen.find_child(node_name, true, false) as Control
			if node != null:
				print("[RhythmCapture] %s %s %s" % [state_name, node_name, node.get_global_rect()])
		if force_compact:
			var footer_geometry := screen.find_child("RhythmCompactFooter", true, false) as Control
			if footer_geometry != null:
				print("[RhythmCapture] footer minimum=%s root=%s viewport=%s" % [footer_geometry.get_combined_minimum_size(), screen.get("root_box").get_combined_minimum_size(), get_root().size])
		assert(screen.find_child("RhythmProfilePill", true, false) == null, "Profile must not obstruct the game HUD")
		if force_compact and get_root().content_scale_size.x >= 600:
			var app_root := screen.get("root_box") as Control
			assert(app_root.get_global_rect().size.x <= get_root().size.x + 0.5, "Game content exceeds viewport width")
			var hud := screen.get("practice_hud") as Control
			assert(hud != null, "Shared HUD is missing")
			var back := hud.find_child("PracticeHudBack", true, false) as Control
			var speed := hud.find_child("PracticeHudSpeed", true, false) as Control
			var pause := hud.find_child("PracticeHudPause", true, false) as Control
			var footer := screen.find_child("RhythmCompactFooter", true, false) as Control
			var notation := screen.find_child("RhythmPreviewStaff" if state_name == "intro" else "RhythmStaff", true, false) as Control
			assert(back != null and speed != null and pause != null and footer != null and notation != null)
			assert(back.get_global_rect().end.x + 8.0 <= speed.get_global_rect().position.x, "Back overlaps speed")
			assert(speed.get_global_rect().end.x + 8.0 <= pause.get_global_rect().position.x, "Speed overlaps Pause")
			assert(notation.get_global_rect().end.y + 8.0 <= footer.get_global_rect().position.y, "Notation is clipped by footer")
	var image := get_root().get_texture().get_image()
	var target := "%s/rhythm_%s_%s.png" % [capture_dir, capture_prefix, state_name]
	var error := image.save_png(target)
	if error != OK:
		push_error("Không thể lưu ảnh %s: %s" % [target, error_string(error)])
	else:
		print("[RhythmCapture] %s" % target)


func _save_scroll_bottom(state_name: String) -> void:
	var scroll := screen.find_child("RhythmCardScroll", true, false) as ScrollContainer
	if scroll == null:
		var all_scrolls := screen.find_children("*", "ScrollContainer", true, false)
		if not all_scrolls.is_empty():
			scroll = all_scrolls[-1] as ScrollContainer
	if scroll == null:
		push_error("Khong tim thay ScrollContainer de kiem tra noi dung cuoi")
		return
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
	await _wait_frames(3)
	_save_capture(state_name)
