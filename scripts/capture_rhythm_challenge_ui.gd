extends SceneTree

const Context = preload("res://scripts/LearningActivityContext.gd")
const AuthSession = preload("res://scripts/AuthSession.gd")

const PLAYING := 4
const FINAL_RESULT := 7

var screen: Control
var capture_dir := "E:/VietStage_web/.tools/captures"
var capture_prefix := "desktop"


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
	get_root().content_scale_size = Vector2i(width, height)
	DisplayServer.window_set_size(Vector2i(width, height))
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

	screen.call("_start_round")
	if not await _wait_for_state(PLAYING, 4.0):
		push_error("Không vào được PLAYING khi chụp UI")
		quit(1)
		return
	await create_timer(0.35).timeout
	await _wait_frames(2)
	_save_capture("playing")

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
	var image := get_root().get_texture().get_image()
	var target := "%s/rhythm_%s_%s.png" % [capture_dir, capture_prefix, state_name]
	var error := image.save_png(target)
	if error != OK:
		push_error("Không thể lưu ảnh %s: %s" % [target, error_string(error)])
	else:
		print("[RhythmCapture] %s" % target)
