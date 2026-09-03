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

	cards_row.add_child(_activity_card("QUIZ", "Nhận diện nốt nhạc", "Luyện nghe và chọn đúng cao độ của nốt đàn.", "5 câu · 3–5 phút", C_BLUE, "quiz"))
	cards_row.add_child(_activity_card("MINI-GAME 1", "Thử thách nhịp điệu", "Nghe mẫu, quan sát phách và gõ đúng thời điểm.", "3 vòng · 4 phút", C_GREEN, "rhythm"))
	cards_row.add_child(_activity_card("MINI-GAME 2", "Hoàn thiện giai điệu", "Nghe câu nhạc và chọn nốt còn thiếu trong giai điệu.", "3 câu · 5 phút", C_PURPLE, "melody"))


func _style_activities_header() -> void:
	# The compact glass header is supplied by the shared activity shell.
	title_label.hide()


func _activity_card(kicker: String, heading: String, description: String, metadata: String, color: Color, activity_id: String) -> PanelContainer:
	var mobile := get_viewport_rect().size.x < 600.0

	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not mobile:
		card.custom_minimum_size = Vector2(0, 378)

	# Premium glassmorphism card style
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(1.0, 0.99, 0.97, 0.68)
	card_style.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.34)
	card_style.set_border_width_all(1)
	card_style.set_corner_radius_all(24)
	card_style.shadow_color = Color(0.09, 0.25, 0.18, 0.14)
	card_style.shadow_size = 18
	card_style.shadow_offset = Vector2(0, 6)
	card_style.content_margin_left = 20
	card_style.content_margin_right = 20
	card_style.content_margin_top = 22 if mobile else 26
	card_style.content_margin_bottom = 22 if mobile else 26
	card.add_theme_stylebox_override("panel", card_style)
	var card_blur := ColorRect.new()
	card_blur.material = _glass_material()
	card_blur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_blur.show_behind_parent = true
	card_blur.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.add_child(card_blur)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10 if mobile else 12)
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
	var badge := _label(kicker, 14 if mobile else 15, color)
	badge.autowrap_mode = TextServer.AUTOWRAP_OFF
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_wrap.add_child(badge)
	body.add_child(badge_wrap)

	# Large icon
	var icon_lbl := _label("?" if activity_id == "quiz" else ("\u266b" if activity_id == "rhythm" else "\u266a"), 54 if mobile else 62, color)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	body.add_child(icon_lbl)

	# Heading
	var title := _label(heading, 22 if mobile else 26, C_NAVY)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(title)
	var detail := _label(description, 16 if mobile else 18, C_MUTED)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.custom_minimum_size.y = 48 if mobile else 54
	body.add_child(detail)
	var meta := _label(metadata, 14 if mobile else 16, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.95))
	meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(meta)

	# Divider
	var div := ColorRect.new()
	div.custom_minimum_size = Vector2(0, 1)
	div.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	div.color = Color(color.r, color.g, color.b, 0.18)
	body.add_child(div)

	# Full-width start button
	var button := _button("Bắt đầu luyện", 0, 52 if mobile else 56, C_NAVY)
	button.add_theme_font_size_override("font_size", 18 if mobile else 20)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(func() -> void: _open_activity(activity_id))
	body.add_child(button)

	return card


func _open_activity(activity_id: String) -> void:
	Context.activity = activity_id
	var target := "res://scenes/LearningQuizScreen.tscn" if activity_id == "quiz" else ("res://scenes/RhythmChallengeScreen.tscn" if activity_id == "rhythm" else "res://scenes/MelodyCompletionScreen.tscn")
	get_tree().change_scene_to_file(target)
