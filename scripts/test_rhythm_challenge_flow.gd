extends SceneTree

const Context = preload("res://scripts/LearningActivityContext.gd")
const AuthSession = preload("res://scripts/AuthSession.gd")

const INTRO := 1
const PREVIEW := 2
const PLAYING := 4
const FINAL_RESULT := 7

var failures := 0
var screen: Control


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	AuthSession.access_token = ""
	AuthSession.refresh_token = ""
	AuthSession.session_id = ""
	AuthSession._loaded = true
	Context.configure("dan_tranh", ["Node1"], "res://scenes/MainMenu.tscn")
	var scene_resource := load("res://scenes/RhythmChallengeScreen.tscn") as PackedScene
	_check(scene_resource != null, "phải load được RhythmChallengeScreen.tscn")
	if scene_resource == null:
		_finish()
		return
	screen = scene_resource.instantiate() as Control
	get_root().add_child(screen)
	await process_frame
	await process_frame

	_check(int(screen.get("flow_state")) == INTRO, "offline phải vào màn intro")
	_check((screen.get("rhythms") as Array).size() > 0, "intro phải có dữ liệu mẫu")
	_check(_find_button(screen, "▶  Nghe mẫu") != null, "intro phải có nút Nghe mẫu")
	_check(_find_button(screen, "Bắt đầu  →") != null, "intro phải có nút Bắt đầu")

	screen.call("_play_sample")
	_check(int(screen.get("flow_state")) == PREVIEW, "Nghe mẫu phải chuyển sang PREVIEW")
	screen.call("_play_sample")
	_check(int(screen.get("flow_state")) == INTRO, "Dừng mẫu phải trở lại INTRO")

	screen.call("_start_round")
	var playing_ready := await _wait_for_state(PLAYING, 4.0)
	_check(playing_ready, "countdown phải chuyển sang PLAYING")
	if playing_ready:
		var beats: Array = screen.get("beat_times")
		for beat_value: Variant in beats:
			var target := float(beat_value)
			while float(Time.get_ticks_msec() - int(screen.get("round_started_at_ms"))) / 1000.0 < target:
				await process_frame
			screen.call("_tap")
		_check(await _wait_for_state(FINAL_RESULT, 5.0), "kết thúc vòng phải hiển thị FINAL_RESULT")

	_check(int(screen.get("total_score")) > 0, "tap đúng phải tạo điểm")
	_check(int(screen.get("total_max_score")) > 0, "kết quả phải có max score")
	_check(_find_button(screen, "Chơi lại") != null, "kết quả phải có nút Chơi lại")
	_check(_find_button(screen, "Về hoạt động") != null, "kết quả phải có nút Về hoạt động")
	_finish()


func _wait_for_state(expected: int, timeout_seconds: float) -> bool:
	var started := Time.get_ticks_msec()
	while float(Time.get_ticks_msec() - started) / 1000.0 < timeout_seconds:
		if not is_instance_valid(screen):
			return false
		if int(screen.get("flow_state")) == expected:
			return true
		await process_frame
	return false


func _find_button(node: Node, text_value: String) -> Button:
	if node is Button and (node as Button).text == text_value:
		return node as Button
	for child in node.get_children():
		var found := _find_button(child, text_value)
		if found != null:
			return found
	return null


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error("[RhythmChallengeFlow] %s" % message)


func _finish() -> void:
	if is_instance_valid(screen):
		screen.queue_free()
		await process_frame
		await process_frame
	if failures == 0:
		print("[RhythmChallengeFlow] PASS")
		quit(0)
		return
	push_error("[RhythmChallengeFlow] FAIL: %d assertion(s)" % failures)
	quit(1)
