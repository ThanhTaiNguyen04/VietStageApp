extends Control

const Context = preload("res://scripts/LearningActivityContext.gd")
const C_BG := Color("#f7f5ef")
const C_NAVY := Color("#172f75")
const C_BLUE := Color("#2d76df")
const C_GREEN := Color("#4b9c55")
const C_PURPLE := Color("#6852d9")
const C_GOLD := Color("#e7ae22")
const C_TEXT := Color("#182449")
const C_MUTED := Color("#66708b")
const C_CARD := Color("#ffffff")
const C_OK := Color("#239653")
const C_BAD := Color("#e04a43")

var root_box: VBoxContainer
var content_box: VBoxContainer
var title_label: Label
var result_sync_status := "offline"

func _ready() -> void:
	Context.ensure_defaults()
	_build_shell()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), C_BG)

func _build_shell() -> void:
	var mobile := get_viewport_rect().size.x < 600.0
	var background := TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.modulate = Color.WHITE
	var background_path := _instrument_background_path()
	if not background_path.is_empty():
		background.texture = load(background_path)
	add_child(background)
	root_box = VBoxContainer.new()
	root_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_box.add_theme_constant_override("separation", 0)
	add_child(root_box)

	var top := PanelContainer.new()
	top.custom_minimum_size = Vector2(0, 68 if mobile else 82)
	top.add_theme_stylebox_override("panel", _panel(Color(0.98, 0.96, 0.90, 0.90), C_GOLD, 0, 1))
	root_box.add_child(top)
	var top_margin := MarginContainer.new()
	top_margin.add_theme_constant_override("margin_left", 12 if mobile else 28)
	top_margin.add_theme_constant_override("margin_right", 12 if mobile else 28)
	top_margin.add_theme_constant_override("margin_top", 8 if mobile else 14)
	top_margin.add_theme_constant_override("margin_bottom", 8 if mobile else 14)
	top.add_child(top_margin)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 18)
	top_margin.add_child(top_row)
	
	# Transparent, bouncy, icon-only back button similar to AccountScreen
	var back := Button.new()
	back.custom_minimum_size = Vector2(42 if mobile else 48, 42 if mobile else 48)
	back.icon = load("res://assets/textures/lucide/arrow-left.svg") as Texture2D
	back.expand_icon = true
	back.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	back.add_theme_color_override("icon_normal_color", C_NAVY)
	back.add_theme_color_override("icon_hover_color", C_BLUE)
	back.add_theme_color_override("icon_pressed_color", C_NAVY)
	back.add_theme_color_override("icon_focus_color", C_NAVY)
	back.add_theme_constant_override("icon_max_width", 24 if mobile else 30)

	var empty := StyleBoxEmpty.new()
	back.add_theme_stylebox_override("normal", empty)
	back.add_theme_stylebox_override("hover", empty)
	back.add_theme_stylebox_override("pressed", empty)
	back.add_theme_stylebox_override("focus", empty)

	# Bouncy hover/press micro-interactions
	back.pivot_offset = Vector2(21 if mobile else 24, 21 if mobile else 24)
	back.mouse_entered.connect(func() -> void:
		create_tween().tween_property(back, "scale", Vector2(1.15, 1.15), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	back.mouse_exited.connect(func() -> void:
		create_tween().tween_property(back, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	back.button_down.connect(func() -> void:
		create_tween().tween_property(back, "scale", Vector2(0.9, 0.9), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	back.button_up.connect(func() -> void:
		var tgt := Vector2(1.15, 1.15) if back.is_hovered() else Vector2.ONE
		create_tween().tween_property(back, "scale", tgt, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)

	back.pressed.connect(_go_back)
	top_row.add_child(back)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)
	title_label = Label.new()
	title_label.text = "HOẠT ĐỘNG HỌC TẬP"
	title_label.add_theme_font_size_override("font_size", 20 if mobile else 24)
	title_label.add_theme_color_override("font_color", C_NAVY)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_row.add_child(title_label)
	var spacer_right := Control.new()
	spacer_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer_right)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_box.add_child(scroll)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16 if mobile else 42)
	margin.add_theme_constant_override("margin_right", 16 if mobile else 42)
	margin.add_theme_constant_override("margin_top", 18 if mobile else 28)
	margin.add_theme_constant_override("margin_bottom", _bottom_inset(mobile))
	scroll.add_child(margin)
	content_box = VBoxContainer.new()
	content_box.add_theme_constant_override("separation", 22)
	content_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var available_width := get_viewport_rect().size.x - (32.0 if mobile else 84.0)
	content_box.custom_minimum_size = Vector2(minf(available_width, 1120.0), 0)
	margin.add_child(content_box)

func _go_back() -> void:
	get_tree().change_scene_to_file(Context.return_scene)

func _bottom_inset(mobile: bool) -> int:
	var base := 24 if mobile else 34
	var safe_area := DisplayServer.get_display_safe_area()
	if safe_area.size.y <= 0:
		return base
	var window_size := DisplayServer.window_get_size()
	var inset := maxi(0, int(window_size.y - (safe_area.position.y + safe_area.size.y)))
	return maxi(base, inset + 16)

func _button(text_value: String, width: float, height: float, color: Color) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(width, maxf(height, 48.0))
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_stylebox_override("normal", _panel(color, color.lightened(0.18), 14, 1))
	button.add_theme_stylebox_override("hover", _panel(color.lightened(0.10), C_GOLD, 14, 2))
	button.add_theme_stylebox_override("pressed", _panel(color.darkened(0.10), C_GOLD, 14, 1))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	return button

func _secondary_button(text_value: String, width: float, height: float, color: Color) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(width, maxf(height, 48.0))
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_stylebox_override("normal", _panel(Color.WHITE, Color(color.r, color.g, color.b, 0.55), 14, 1))
	button.add_theme_stylebox_override("hover", _panel(Color(color.r, color.g, color.b, 0.08), color, 14, 1))
	button.add_theme_stylebox_override("pressed", _panel(Color(color.r, color.g, color.b, 0.14), color, 14, 1))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_hover_color", color.darkened(0.15))
	return button

func _label(text_value: String, font_size: int, color: Color = C_TEXT) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _panel(bg: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(clampi(border_width, 0, 1))
	style.set_corner_radius_all(clampi(radius, 8, 18))
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func _instrument_title() -> String:
	match Context.instrument:
		"dan_bau": return "ĐÀN BẦU"
		"sao_truc": return "SÁO TRÚC"
		"trong_chau": return "TRỐNG CHẦU"
		_: return "ĐÀN TRANH"

func _instrument_background_path() -> String:
	return "res://assets/textures/bg_practice_room.png"

func _now_iso() -> String:
	return Time.get_datetime_string_from_system(true)

func _report() -> Node:
	return get_node_or_null("/root/BackendReport")

func _normalize_type(value: String) -> String:
	return value.to_upper().replace("-", "_").replace(" ", "_")

func _extract_json(value: Variant) -> Variant:
	if value is Dictionary or value is Array:
		return value
	var raw := str(value)
	return JSON.parse_string(raw) if not raw.is_empty() else null

func _sample_data() -> Dictionary:
	if not FileAccess.file_exists("res://data/learning_activity_samples.json"):
		return {}
	var file := FileAccess.open("res://data/learning_activity_samples.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return {}
	var all_samples: Dictionary = parsed
	var instrument_samples: Variant = all_samples.get(Context.instrument, all_samples.get("dan_tranh", {}))
	return instrument_samples if instrument_samples is Dictionary else {}

func _stars(score: int, max_score: int) -> int:
	var maximum := maxi(1, max_score)
	return 3 if score * 100 >= maximum * 80 else (2 if score * 100 >= maximum * 55 else (1 if score > 0 else 0))

func _show_result(title: String, detail: String, score: int, stars: int, retry: Callable, accuracy: float = -1.0) -> void:
	for child in content_box.get_children():
		child.queue_free()
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _panel(Color.WHITE, C_GOLD, 26, 3))
	content_box.add_child(card)
	var body := VBoxContainer.new()
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 14)
	card.add_child(body)
	var icon := _label("✓" if stars > 0 else "!", 58, C_OK if stars > 0 else C_BAD)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(icon)
	var heading := _label(title, 21 if get_viewport_rect().size.x < 600.0 else 24, C_NAVY)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(heading)
	var result := _label(detail, 16 if get_viewport_rect().size.x < 600.0 else 17, C_MUTED)
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(result)
	var metrics := GridContainer.new()
	metrics.columns = 2 if get_viewport_rect().size.x < 600.0 else 4
	metrics.add_theme_constant_override("h_separation", 10)
	metrics.add_theme_constant_override("v_separation", 10)
	body.add_child(metrics)
	var xp := maxi(0, score / 10)
	var coins := stars * 5 + maxi(0, score / 50)
	metrics.add_child(_metric_card("⚡", "XP", "+%d" % xp, C_BLUE))
	metrics.add_child(_metric_card("◉", "Coin", "+%d" % coins, C_GOLD))
	metrics.add_child(_metric_card("%", "Accuracy", "%.0f%%" % (accuracy if accuracy >= 0.0 else float(stars) / 3.0 * 100.0), C_GREEN))
	metrics.add_child(_metric_card("★", "Stars", "%d / 3" % stars, C_GOLD))
	var sync := _label(_sync_status_text(), 14, C_OK if result_sync_status == "be" else C_MUTED)
	sync.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(sync)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 14)
	body.add_child(actions)
	var retry_button := _button("Chơi lại", 180, 52, C_BLUE)
	retry_button.pressed.connect(retry)
	actions.add_child(retry_button)
	var back_button := _secondary_button("Về hoạt động", 180, 52, C_NAVY)
	back_button.pressed.connect(_go_back)
	actions.add_child(back_button)

func _metric_card(icon: String, label_text: String, value: String, color: Color) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(120, 78)
	card.add_theme_stylebox_override("panel", _panel(Color("#f7f9fc"), Color(color.r, color.g, color.b, 0.35), 14, 1))
	var body := VBoxContainer.new()
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 2)
	card.add_child(body)
	var icon_label := _label(icon, 22, color)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(icon_label)
	var value_label := _label(value, 17, C_TEXT)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(value_label)
	var name_label := _label(label_text, 12, C_MUTED)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(name_label)
	return card

func _sync_status_text() -> String:
	if result_sync_status == "be":
		return "✓ Đã đồng bộ kết quả với BE"
	return "○ Offline · kết quả mẫu lưu trên thiết bị"
