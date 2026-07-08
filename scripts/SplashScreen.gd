extends Control

const C_JADE      := Color(0.09, 0.27, 0.18, 1.0)  # Brand deep jade green
const C_GREY_DK   := Color(0.43, 0.38, 0.33, 1.0)  # Primary charcoal text
const C_GREY_LT   := Color(0.43, 0.38, 0.33, 0.50) # Muted grey for version

func _ready() -> void:
	_style_text()
	_animate()

func _style_text() -> void:
	($Center/AppName    as Label).add_theme_color_override("font_color", C_JADE)
	($Center/Tagline    as Label).add_theme_color_override("font_color", C_GREY_DK)
	($VersionLabel      as Label).add_theme_color_override("font_color", C_GREY_LT)

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
