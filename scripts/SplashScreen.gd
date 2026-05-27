extends Control

const C_GOLD       := Color(0.95, 0.72, 0.18, 1.0)
const C_GOLD_LIGHT := Color(1.00, 0.87, 0.45, 1.0)
const C_CREAM      := Color(1.00, 0.97, 0.88, 1.0)
const C_CREAM_DIM  := Color(0.75, 0.70, 0.58, 1.0)

func _ready() -> void:
	_style_text()
	_animate()

func _style_text() -> void:
	var app_name := $Center/AppName as Label
	app_name.add_theme_color_override("font_color",         C_GOLD)
	app_name.add_theme_color_override("font_outline_color", Color(0.55, 0.38, 0.05, 1.0))
	app_name.add_theme_color_override("font_shadow_color",  Color(0.0, 0.0, 0.0, 0.7))
	app_name.add_theme_constant_override("outline_size", 8)
	app_name.add_theme_constant_override("shadow_offset_x", 0)
	app_name.add_theme_constant_override("shadow_offset_y", 6)

	var tagline := $Center/Tagline as Label
	tagline.add_theme_color_override("font_color", C_CREAM_DIM)

	var version := $Center/VersionLabel as Label
	version.add_theme_color_override("font_color", Color(0.55, 0.50, 0.38, 1.0))

func _animate() -> void:
	# Start invisible/small
	modulate.a = 0.0
	$Center.scale          = Vector2(0.72, 0.72)
	$Center/Tagline.modulate.a  = 0.0
	$Center/OrnamentLine.modulate.a = 0.0
	$Center/VersionLabel.modulate.a = 0.0

	var t := create_tween().set_parallel(true)

	# BG fade in first
	t.tween_property(self, "modulate:a", 1.0, 0.4)

	# Logo + name bounce in
	t.tween_property($Center, "scale", Vector2.ONE, 0.65).set_delay(0.2)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Tagline slide in
	t.tween_property($Center/Tagline, "modulate:a", 1.0, 0.5).set_delay(0.70)

	# Ornament line expand
	t.tween_property($Center/OrnamentLine, "modulate:a", 1.0, 0.4).set_delay(0.85)

	# Version
	t.tween_property($Center/VersionLabel, "modulate:a", 1.0, 0.4).set_delay(1.0)

	# Gold shimmer pulse, then continue
	t.chain().tween_callback(func() -> void:
		var pulse := create_tween().set_loops(2).set_parallel(false)
		pulse.tween_property($Center/AppName, "modulate", Color(1.5, 1.2, 0.7, 1.0), 0.4)
		pulse.tween_property($Center/AppName, "modulate", Color.WHITE, 0.4)
		pulse.tween_callback(func() -> void: _go_loading())
	).set_delay(0.6)

func _go_loading() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.45)
	t.tween_callback(func() -> void:
		get_tree().change_scene_to_file("res://scenes/LoadingScreen.tscn")
	)
