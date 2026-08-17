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

# _draw override removed — background is handled by TextureRect child

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
	top.custom_minimum_size = Vector2(0, 84 if mobile else 96)
	top.add_theme_stylebox_override("panel", _panel(Color(0.98, 0.96, 0.90, 0.90), C_GOLD, 0, 1))
	root_box.add_child(top)
	var top_margin := MarginContainer.new()
	top_margin.add_theme_constant_override("margin_left", 12 if mobile else 28)
	top_margin.add_theme_constant_override("margin_right", 12 if mobile else 28)
	top_margin.add_theme_constant_override("margin_top", 10 if mobile else 16)
	top_margin.add_theme_constant_override("margin_bottom", 10 if mobile else 16)
	top.add_child(top_margin)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 18)
	top_margin.add_child(top_row)
	
	# Game-style: large filled back button, jade accent, white arrow icon
	var back := Button.new()
	back.custom_minimum_size = Vector2(56 if mobile else 64, 56 if mobile else 64)
	back.icon = load("res://assets/textures/lucide/arrow-left.svg") as Texture2D
	back.expand_icon = true
	back.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	back.add_theme_color_override("icon_normal_color", C_NAVY)
	back.add_theme_color_override("icon_hover_color", C_NAVY.darkened(0.15))
	back.add_theme_color_override("icon_pressed_color", C_NAVY.darkened(0.3))
	back.add_theme_color_override("icon_focus_color", C_NAVY)
	back.add_theme_constant_override("icon_max_width", 28 if mobile else 32)

	var sb_n := StyleBoxFlat.new()
	sb_n.bg_color = Color.WHITE
	sb_n.set_corner_radius_all(32)
	sb_n.border_width_bottom = 4
	sb_n.border_color = Color("#EBE5D8")
	
	var sb_h := sb_n.duplicate()
	sb_h.bg_color = Color("#FDFCF9")
	
	var sb_p := sb_n.duplicate()
	sb_p.bg_color = Color("#F5F0E5")
	sb_p.border_width_bottom = 0
	sb_p.content_margin_top = 4
	
	back.add_theme_stylebox_override("normal", sb_n)
	back.add_theme_stylebox_override("hover", sb_h)
	back.add_theme_stylebox_override("pressed", sb_p)
	back.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	# Bouncy hover/press micro-interactions
	back.pivot_offset = Vector2(28 if mobile else 32, 28 if mobile else 32)
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
	title_label.add_theme_font_size_override("font_size", 22 if mobile else 26)
	title_label.add_theme_font_override("font", load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font)
	title_label.add_theme_color_override("font_color", C_NAVY)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	top_row.add_child(title_label)
	var spacer_right := Control.new()
	spacer_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer_right)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_box.add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 16 if mobile else 42)
	margin.add_theme_constant_override("margin_right", 16 if mobile else 42)
	margin.add_theme_constant_override("margin_top", 18 if mobile else 28)
	margin.add_theme_constant_override("margin_bottom", _bottom_inset(mobile))
	scroll.add_child(margin)
	content_box = VBoxContainer.new()
	content_box.add_theme_constant_override("separation", 22)
	content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	return "res://assets/textures/dan_tranh_background.png"

func _now_iso() -> String:
	return Time.get_datetime_string_from_system(true)

func _report() -> Node:
	return get_node_or_null("/root/BackendReport")

## Sinh khóa idempotency cho một lần nộp kết quả (minigame), để retry không tạo bản ghi trùng.
func _client_attempt_id(prefix: String = "") -> String:
	var suffix := "%04x%04x" % [randi_range(0, 0xFFFF), randi_range(0, 0xFFFF)]
	var base := "%d-%s" % [Time.get_unix_time_from_system(), suffix]
	return prefix + "-" + base if not prefix.is_empty() else base

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
	# Vertically center the result card in the available space
	content_box.alignment = BoxContainer.ALIGNMENT_CENTER
	content_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_box.add_theme_constant_override("separation", 0)

	var mobile := get_viewport_rect().size.x < 600.0
	var icon_color := C_OK if stars > 0 else C_BAD

	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(1, 1, 1, 0.94)
	card_style.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.7)
	card_style.set_border_width_all(2)
	card_style.set_corner_radius_all(24)
	card_style.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.20)
	card_style.shadow_size = 18
	card_style.shadow_offset = Vector2(0, 6)
	card_style.content_margin_left = 24 if mobile else 44
	card_style.content_margin_right = 24 if mobile else 44
	card_style.content_margin_top = 32 if mobile else 40
	card_style.content_margin_bottom = 32 if mobile else 40
	card.add_theme_stylebox_override("panel", card_style)
	content_box.add_child(card)

	var body := VBoxContainer.new()
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 16 if mobile else 20)
	card.add_child(body)

	# Large result icon
	var icon := _label("\u2713" if stars > 0 else "\u2717", 76 if mobile else 88, icon_color)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(icon)

	# Heading
	var heading := _label(title, 24 if mobile else 28, C_NAVY)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(heading)

	# Detail
	var result := _label(detail, 16 if mobile else 18, C_MUTED)
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(result)

	# Divider
	var div := ColorRect.new()
	div.custom_minimum_size = Vector2(0, 1)
	div.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	div.color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.28)
	body.add_child(div)

	# Metrics grid — always 4 wide on desktop, 2×2 on mobile
	var metrics := GridContainer.new()
	metrics.columns = 2 if mobile else 4
	metrics.add_theme_constant_override("h_separation", 12)
	metrics.add_theme_constant_override("v_separation", 12)
	metrics.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(metrics)
	var xp := maxi(0, score / 10)
	var coins := stars * 5 + maxi(0, score / 50)
	metrics.add_child(_metric_card("\u26a1", "XP", "+%d" % xp, C_BLUE))
	metrics.add_child(_metric_card("\u25c9", "Coin", "+%d" % coins, C_GOLD))
	metrics.add_child(_metric_card("%", "Accuracy", "%.0f%%" % (accuracy if accuracy >= 0.0 else float(stars) / 3.0 * 100.0), C_GREEN))
	metrics.add_child(_metric_card("\u2605", "Stars", "%d / 3" % stars, C_GOLD))

	# Sync status
	var sync := _label(_sync_status_text(), 13 if mobile else 14, C_OK if result_sync_status == "be" else (C_BAD if result_sync_status == "failed" else C_MUTED))
	sync.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(sync)

	# Action buttons — full-width, tall touch targets
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 14)
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(actions)
	var retry_button := _button("Ch\u01a1i l\u1ea1i", 0, 58 if mobile else 64, C_BLUE)
	retry_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	retry_button.pressed.connect(retry)
	actions.add_child(retry_button)
	var back_button := _secondary_button("V\u1ec1 ho\u1ea1t \u0111\u1ed9ng", 0, 58 if mobile else 64, C_NAVY)
	back_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back_button.pressed.connect(_go_back)
	actions.add_child(back_button)

func _metric_card(icon: String, label_text: String, value: String, color: Color) -> PanelContainer:
	var mobile := get_viewport_rect().size.x < 600.0
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 96 if mobile else 108)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(color.r, color.g, color.b, 0.08)
	card_style.border_color = Color(color.r, color.g, color.b, 0.28)
	card_style.set_border_width_all(1)
	card_style.set_corner_radius_all(16)
	card_style.shadow_color = Color(color.r, color.g, color.b, 0.10)
	card_style.shadow_size = 6
	card_style.content_margin_left = 10
	card_style.content_margin_right = 10
	card_style.content_margin_top = 14
	card_style.content_margin_bottom = 14
	card.add_theme_stylebox_override("panel", card_style)
	var body := VBoxContainer.new()
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 3)
	card.add_child(body)
	var icon_label := _label(icon, 26 if mobile else 30, color)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(icon_label)
	var value_label := _label(value, 19 if mobile else 22, C_TEXT)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(value_label)
	var name_label := _label(label_text, 12 if mobile else 13, C_MUTED)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(name_label)
	return card

func _sync_status_text() -> String:
	if result_sync_status == "be":
		return "✓ Đã đồng bộ kết quả với BE"
	if result_sync_status == "failed":
		return "⚠ Không đồng bộ được · kết quả đã lưu trên thiết bị"
	return "○ Offline · kết quả mẫu lưu trên thiết bị"
