extends "res://scripts/LearningActivityBase.gd"

func _ready() -> void:
	super._ready()
	title_label.text = "CÁC HOẠT ĐỘNG HỌC TẬP"
	_style_activities_header()

	var mobile := get_viewport_rect().size.x < 600.0

	# Vertically center cards in the available space
	content_box.alignment = BoxContainer.ALIGNMENT_CENTER
	content_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_box.add_theme_constant_override("separation", 0)

	var cards_row := BoxContainer.new()
	cards_row.vertical = mobile
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_row.add_theme_constant_override("separation", 16 if mobile else 24)
	content_box.add_child(cards_row)

	cards_row.add_child(_activity_card("QUIZ", "Nhận diện\nnốt nhạc", C_BLUE, "quiz"))
	cards_row.add_child(_activity_card("MINI-GAME 1", "Thử thách\nnhịp điệu", C_GREEN, "rhythm"))
	cards_row.add_child(_activity_card("MINI-GAME 2", "Hoàn thiện\ngiai điệu", C_PURPLE, "melody"))


func _style_activities_header() -> void:
	var top := root_box.get_child(0) as PanelContainer
	if top == null:
		return
	var blur_material := ShaderMaterial.new()
	var blur_shader := Shader.new()
	blur_shader.code = """
	shader_type canvas_item;
	uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
	uniform float lod: hint_range(0.0, 5.0) = 2.0;
	void fragment() { COLOR = textureLod(screen_texture, SCREEN_UV, lod); }
	"""
	blur_material.shader = blur_shader
	var blur := ColorRect.new()
	blur.name = "ActivitiesHeaderBlur"
	blur.material = blur_material
	blur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blur.show_behind_parent = true
	blur.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top.add_child(blur)
	top.move_child(blur, 0)
	top.add_theme_stylebox_override("panel", _panel(Color(0.93, 0.91, 0.87, 0.72), C_GOLD, 18, 1))
	var mobile := get_viewport_rect().size.x < 600.0
	title_label.add_theme_color_override("font_color", Color("#261A13"))
	title_label.add_theme_font_override("font", load("res://assets/fonts/Lora-Bold.ttf") as Font)
	title_label.add_theme_font_size_override("font_size", 19 if mobile else 25)


func _activity_card(kicker: String, heading: String, color: Color, activity_id: String) -> PanelContainer:
	var mobile := get_viewport_rect().size.x < 600.0

	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not mobile:
		card.custom_minimum_size = Vector2(0, 300)

	# Premium glassmorphism card style
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(1.0, 1.0, 1.0, 0.92)
	card_style.border_color = Color(color.r, color.g, color.b, 0.55)
	card_style.set_border_width_all(2)
	card_style.set_corner_radius_all(22)
	card_style.shadow_color = Color(color.r, color.g, color.b, 0.22)
	card_style.shadow_size = 16
	card_style.shadow_offset = Vector2(0, 6)
	card_style.content_margin_left = 20
	card_style.content_margin_right = 20
	card_style.content_margin_top = 28 if mobile else 32
	card_style.content_margin_bottom = 28 if mobile else 32
	card.add_theme_stylebox_override("panel", card_style)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 12 if mobile else 16)
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(body)

	# Pill badge
	var badge_wrap := PanelContainer.new()
	badge_wrap.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(color.r, color.g, color.b, 0.12)
	badge_style.border_color = Color(color.r, color.g, color.b, 0.30)
	badge_style.set_border_width_all(1)
	badge_style.set_corner_radius_all(20)
	badge_style.content_margin_left = 14
	badge_style.content_margin_right = 14
	badge_style.content_margin_top = 5
	badge_style.content_margin_bottom = 5
	badge_wrap.add_theme_stylebox_override("panel", badge_style)
	var badge := _label(kicker, 12, color)
	badge.autowrap_mode = TextServer.AUTOWRAP_OFF
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_wrap.add_child(badge)
	body.add_child(badge_wrap)

	# Large icon
	var icon_lbl := _label("?" if activity_id == "quiz" else ("\u266b" if activity_id == "rhythm" else "\u266a"), 56 if mobile else 68, color)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	body.add_child(icon_lbl)

	# Heading
	var title := _label(heading, 17 if mobile else 20, Color("#1a2a5a"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(title)

	# Divider
	var div := ColorRect.new()
	div.custom_minimum_size = Vector2(0, 1)
	div.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	div.color = Color(color.r, color.g, color.b, 0.18)
	body.add_child(div)

	# Full-width start button
	var button := _button("Bắt đầu", 0, 52 if mobile else 56, color)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(func() -> void: _open_activity(activity_id))
	body.add_child(button)

	return card


func _open_activity(activity_id: String) -> void:
	Context.activity = activity_id
	var target := "res://scenes/LearningQuizScreen.tscn" if activity_id == "quiz" else ("res://scenes/RhythmChallengeScreen.tscn" if activity_id == "rhythm" else "res://scenes/MelodyCompletionScreen.tscn")
	get_tree().change_scene_to_file(target)
