extends "res://scripts/LearningActivityBase.gd"

func _ready() -> void:
	super._ready()
	title_label.text = "CÁC HOẠT ĐỘNG HỌC TẬP"
	var intro := _label("Rèn luyện %s qua 1 quiz và 2 mini-game" % _instrument_title(), 18 if get_viewport_rect().size.x < 600.0 else 20, C_TEXT)
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_box.add_child(intro)
	var cards := BoxContainer.new()
	cards.vertical = get_viewport_rect().size.x < 600.0
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", 14 if cards.vertical else 20)
	content_box.add_child(cards)
	cards.add_child(_activity_card("1  QUIZ", "Nhận diện nốt nhạc", "Xác định nốt nhạc dựa trên ký hiệu hoặc âm thanh mẫu.", C_BLUE, "quiz"))
	cards.add_child(_activity_card("MINI-GAME 1", "Thử thách nhịp điệu", "Thực hiện đúng mẫu nhịp theo thời gian quy định.", C_GREEN, "rhythm"))
	cards.add_child(_activity_card("MINI-GAME 2", "Hoàn thiện giai điệu", "Xác định nốt còn thiếu để hoàn thành giai điệu.", C_PURPLE, "melody"))

func _activity_card(kicker: String, heading: String, description: String, color: Color, activity_id: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(280, 220 if get_viewport_rect().size.x < 600.0 else 240)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _panel(Color.WHITE, Color(color.r, color.g, color.b, 0.35), 20, 2))
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	card.add_child(body)
	var badge := _label(kicker, 16, color)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(badge)
	var icon := _label("?" if activity_id == "quiz" else ("♫" if activity_id == "rhythm" else "♪"), 52, color)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(icon)
	var title := _label(heading, 20, C_NAVY)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(title)
	var desc := _label(description, 15, C_MUTED)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(desc)
	var button := _button("Bắt đầu", 190, 46, color)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(func() -> void: _open_activity(activity_id))
	body.add_child(button)
	return card

func _open_activity(activity_id: String) -> void:
	Context.activity = activity_id
	var target := "res://scenes/LearningQuizScreen.tscn" if activity_id == "quiz" else ("res://scenes/RhythmChallengeScreen.tscn" if activity_id == "rhythm" else "res://scenes/MelodyCompletionScreen.tscn")
	get_tree().change_scene_to_file(target)
