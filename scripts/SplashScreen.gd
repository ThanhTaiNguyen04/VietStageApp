extends Control

const C_RED       := Color(0.38, 0.0, 0.0, 1.0)
const C_CHARCOAL  := Color(0.13, 0.08, 0.05, 0.70)
const C_VER       := Color(0.13, 0.08, 0.05, 0.35)

func _ready() -> void:
	_style_text()
	ResourceLoader.load_threaded_request("res://scenes/LoadingScreen.tscn")
	_try_play_video()

func _try_play_video() -> void:
	var ogv_path := "res://assets/theme/introtong.ogv"
	var stream = load(ogv_path) as VideoStream

	if stream:
		$Center.visible = false
		$VersionLabel.visible = false

		var video_player = VideoStreamPlayer.new()
		video_player.set_anchors_preset(Control.PRESET_FULL_RECT)
		video_player.expand = true
		video_player.stream = stream
		add_child(video_player)

		video_player.finished.connect(_go_loading, CONNECT_ONE_SHOT)
		video_player.play()
		
		# Fallback in case VideoStreamPlayer finished signal fails on export
		var dur = stream.get_length() if stream.has_method("get_length") else 10.0
		# fallback to a reasonable time if length is 0 or unavailable
		if dur <= 0.1: dur = 15.0 
		get_tree().create_timer(dur + 0.5).timeout.connect(_go_loading)
	else:
		# Fallback to the original animation if the video cannot be loaded
		_animate()

func _style_text() -> void:
	($Center/AppName    as Label).add_theme_color_override("font_color", C_RED)
	($Center/Tagline    as Label).add_theme_color_override("font_color", C_CHARCOAL)
	($VersionLabel      as Label).add_theme_color_override("font_color", C_VER)

func _animate() -> void:
	modulate.a = 0.0
	$Center.position.y += 28.0
	($Center/Tagline as Label).modulate.a  = 0.0
	($VersionLabel   as Label).modulate.a  = 0.0

	var t := create_tween().set_parallel(true)

	# Screen fades in
	t.tween_property(self, "modulate:a", 1.0, 0.55)

	# Logo + name block slides up
	t.tween_property($Center, "position:y", $Center.position.y - 28.0, 0.70)\
		.set_delay(0.10).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Tagline fades in
	t.tween_property($Center/Tagline, "modulate:a", 1.0, 0.45).set_delay(0.50)

	# Version fades in
	t.tween_property($VersionLabel, "modulate:a", 1.0, 0.40).set_delay(0.70)

	# Hold then transition
	t.chain()
	t.tween_interval(1.9)
	t.tween_callback(_go_loading)

var _is_loading = false
func _go_loading() -> void:
	if _is_loading: return
	_is_loading = true
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.42).set_trans(Tween.TRANS_CUBIC)
	t.tween_callback(func() -> void:
		var res = ResourceLoader.load_threaded_get("res://scenes/LoadingScreen.tscn")
		if res is PackedScene:
			get_tree().change_scene_to_packed(res)
		else:
			get_tree().change_scene_to_file("res://scenes/LoadingScreen.tscn")
	)
