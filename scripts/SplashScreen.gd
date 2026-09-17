extends Control

const C_RED       := Color(0.38, 0.0, 0.0, 1.0)
const C_CHARCOAL  := Color(0.13, 0.08, 0.05, 0.70)
const C_VER       := Color(0.13, 0.08, 0.05, 0.35)

var _is_loading := false
var _skip_hint: Label
var _intro_video_player: VideoStreamPlayer

func _ready() -> void:
	_style_text()
	_create_skip_hint()
	ResourceLoader.load_threaded_request("res://scenes/LoadingScreen.tscn")
	_try_play_startup_video()


func _try_play_startup_video() -> void:
	# This is the original VietStage startup film. Keep the branded splash as a
	# safe fallback so a missing/corrupt video never blocks app startup.
	var stream := load("res://assets/theme/introtong.ogv") as VideoStream
	if stream == null:
		_animate()
		return

	if has_node("Center"):
		$Center.visible = false
	if has_node("VersionLabel"):
		$VersionLabel.visible = false
	if _skip_hint:
		_skip_hint.visible = false

	_intro_video_player = VideoStreamPlayer.new()
	_intro_video_player.name = "StartupVideo"
	_intro_video_player.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_intro_video_player.expand = true
	_intro_video_player.stream = stream
	_intro_video_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_intro_video_player)
	_intro_video_player.finished.connect(_go_loading)
	_intro_video_player.play()

func _input(event: InputEvent) -> void:
	if _is_loading:
		return
	if event is InputEventKey and event.pressed:
		_go_loading()
	elif event is InputEventMouseButton and event.pressed:
		_go_loading()
	elif event is InputEventScreenTouch and event.pressed:
		_go_loading()

func _create_skip_hint() -> void:
	_skip_hint = Label.new()
	_skip_hint.text = "Chạm để tiếp tục ›"
	_skip_hint.add_theme_font_size_override("font_size", 14)
	_skip_hint.add_theme_color_override("font_color", Color(0.13, 0.08, 0.05, 0.40))
	_skip_hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_skip_hint.offset_left = -180.0
	_skip_hint.offset_top = -46.0
	_skip_hint.offset_right = -24.0
	_skip_hint.offset_bottom = -16.0
	_skip_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_skip_hint.modulate.a = 0.0
	add_child(_skip_hint)

func _style_text() -> void:
	if has_node("Center/AppName"):
		($Center/AppName as Label).add_theme_color_override("font_color", C_RED)
	if has_node("Center/Tagline"):
		($Center/Tagline as Label).add_theme_color_override("font_color", C_CHARCOAL)
	if has_node("VersionLabel"):
		($VersionLabel as Label).add_theme_color_override("font_color", C_VER)

func _animate() -> void:
	modulate.a = 0.0
	if has_node("Center"):
		$Center.position.y += 20.0
	if has_node("Center/Tagline"):
		($Center/Tagline as Label).modulate.a = 0.0
	if has_node("VersionLabel"):
		($VersionLabel as Label).modulate.a = 0.0

	var t := create_tween().set_parallel(true)

	# Screen fades in
	t.tween_property(self, "modulate:a", 1.0, 0.45)

	# Logo + name block slides up
	if has_node("Center"):
		t.tween_property($Center, "position:y", $Center.position.y - 20.0, 0.60)\
			.set_delay(0.08).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Tagline fades in
	if has_node("Center/Tagline"):
		t.tween_property($Center/Tagline, "modulate:a", 1.0, 0.40).set_delay(0.35)

	# Version & skip hint fade in
	if has_node("VersionLabel"):
		t.tween_property($VersionLabel, "modulate:a", 1.0, 0.35).set_delay(0.50)
	if _skip_hint:
		t.tween_property(_skip_hint, "modulate:a", 1.0, 0.35).set_delay(0.60)

	# Hold then transition
	t.chain()
	t.tween_interval(1.6)
	t.tween_callback(_go_loading)

func _go_loading() -> void:
	if _is_loading:
		return
	_is_loading = true
	if is_instance_valid(_intro_video_player):
		_intro_video_player.stop()
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.30).set_trans(Tween.TRANS_CUBIC)
	t.tween_callback(func() -> void:
		var status := ResourceLoader.load_threaded_get_status("res://scenes/LoadingScreen.tscn")
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var res = ResourceLoader.load_threaded_get("res://scenes/LoadingScreen.tscn")
			if res is PackedScene:
				get_tree().change_scene_to_packed(res)
				return
		get_tree().change_scene_to_file("res://scenes/LoadingScreen.tscn")
	)
