extends Control

const C_RED       := Color(0.38, 0.0, 0.0, 1.0)
const C_CHARCOAL  := Color(0.13, 0.08, 0.05, 0.70)
const C_VER       := Color(0.13, 0.08, 0.05, 0.35)

func _ready() -> void:
	_style_text()
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
		
		video_player.finished.connect(_go_loading)
		video_player.play()
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

func _go_loading() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.42).set_trans(Tween.TRANS_CUBIC)
	t.tween_callback(func() -> void:
		get_tree().change_scene_to_file("res://scenes/LoadingScreen.tscn")
	)
