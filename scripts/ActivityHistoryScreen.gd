extends Control

const ApiClientScript = preload("res://scripts/ApiClient.gd")

# ── Palette: Royal Lacquer & Contemporary Duolingo/Simply Music Style ──────
const PAGE_SIZE := 20
const C_BG        := Color("#F7F5F0")       # Warm Ivory Lacquer Paper
const C_CARD      := Color("#FFFFFF")
const C_JADE      := Color("#143826")       # Deep Royal Jade
const C_JADE_DARK := Color("#0B2217")
const C_GOLD      := Color("#C49526")       # Traditional Gold Leaf
const C_GOLD_BG   := Color("#FFF8E7")
const C_BLUE      := Color("#2D76DF")
const C_BLUE_BG   := Color("#EEF5FF")
const C_GREEN     := Color("#239653")
const C_GREEN_BG  := Color("#EAF7EE")
const C_PURPLE    := Color("#7C3AED")
const C_PURPLE_BG := Color("#F5F0FF")
const C_AMBER     := Color("#D97706")
const C_AMBER_BG  := Color("#FEF3C7")
const C_TEXT      := Color("#182449")
const C_NAVY      := Color("#182449")
const C_MUTED     := Color("#6E6257")
const C_BORDER    := Color("#E5DFD3")
const C_SHADOW    := Color(0.12, 0.09, 0.05, 0.08)

var _api: Node
var _page := 0
var _total_pages := 0
var _filter := ""
var _loading := false
var _history_changed_while_loading := false
var _items: Array[Dictionary] = []
var _icon_cache: Dictionary = {}

# Fonts
var _font_bold: Font
var _font_regular: Font
var _font_title: Font

# Node refs
var _root_margin: MarginContainer
var _title_lbl: Label
var _summary_lbl: Label
var _connection_banner: PanelContainer
var _connection_label: Label
var _list_container: VBoxContainer
var _load_more_btn: Button
var _filters_container: Container
var _stats_container: Container
var _list_scroll: ScrollContainer
var _last_rendered_items: Array = []

# Bottom Sheet Modal refs
var _modal_overlay: Control
var _modal_card: PanelContainer
var _modal_content: VBoxContainer
var _active_modal_item: Dictionary = {}


func _ready() -> void:
	SecureDataManager.load_data()
	_api = ApiClientScript.new()
	add_child(_api)
	_load_fonts()
	_build_ui()
	_build_detail_sheet()
	get_viewport().size_changed.connect(_on_viewport_size_changed)

	var backend_report := get_node_or_null("/root/BackendReport")
	if backend_report != null and backend_report.has_signal("activity_history_changed"):
		backend_report.activity_history_changed.connect(_on_activity_history_changed)
	await refresh_history()


func _load_fonts() -> void:
	if ResourceLoader.exists("res://assets/fonts/Lora-Bold.ttf"):
		_font_title = load("res://assets/fonts/Lora-Bold.ttf") as Font
	elif ResourceLoader.exists("res://assets/fonts/BeVietnamPro-Bold.ttf"):
		_font_title = load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font

	if ResourceLoader.exists("res://assets/fonts/BeVietnamPro-Bold.ttf"):
		_font_bold = load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if ResourceLoader.exists("res://assets/fonts/BeVietnamPro-Regular.ttf"):
		_font_regular = load("res://assets/fonts/BeVietnamPro-Regular.ttf") as Font


func _on_activity_history_changed() -> void:
	if _loading:
		_history_changed_while_loading = true
		return
	call_deferred("refresh_history")


# ── Icons8 Texture Helpers ──────────────────────────────────────────────────

func _icons8_texture(icon_name: String) -> Texture2D:
	if _icon_cache.has(icon_name):
		return _icon_cache[icon_name] as Texture2D
	var path := "res://assets/textures/icons8/%s.png" % icon_name
	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		_icon_cache[icon_name] = tex
		return tex
	return null


func _icons8_icon(icon_name: String, icon_size: int = 24, tint: Color = Color.WHITE) -> TextureRect:
	var tr := TextureRect.new()
	var tex := _icons8_texture(icon_name)
	if tex:
		tr.texture = tex
	tr.custom_minimum_size = Vector2(icon_size, icon_size)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if tint != Color.WHITE:
		tr.modulate = tint
	return tr


# ── UI Construction ──────────────────────────────────────────────────────────

func _build_ui() -> void:
	# Illustrated Landscape Background (identical to Quiz Screen)
	var bg := TextureRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists("res://assets/textures/dan_tranh_background.png"):
		bg.texture = load("res://assets/textures/dan_tranh_background.png") as Texture2D
	add_child(bg)

	var bg_wash := ColorRect.new()
	bg_wash.color = Color(0.04, 0.07, 0.06, 0.20)
	bg_wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg_wash)

	_root_margin = MarginContainer.new()
	_root_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root_margin.add_theme_constant_override("margin_left", _horizontal_inset())
	_root_margin.add_theme_constant_override("margin_right", _horizontal_inset())
	_root_margin.add_theme_constant_override("margin_top", _vertical_inset())
	_root_margin.add_theme_constant_override("margin_bottom", _vertical_inset())
	add_child(_root_margin)

	# Main Full-Screen Layout
	var main_vbox := VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 14)
	_root_margin.add_child(main_vbox)

	# 1. Top Bar with Large Back Button + Left-aligned Title (No white bg) + Refresh Button
	main_vbox.add_child(_build_top_bar())

	# 2. Activity Filter Buttons Bar (Below Title, with 15px left/right margins)
	var filter_margin := MarginContainer.new()
	filter_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filter_margin.add_theme_constant_override("margin_left", 15)
	filter_margin.add_theme_constant_override("margin_right", 15)
	main_vbox.add_child(filter_margin)

	_filters_container = HBoxContainer.new()
	_filters_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_filters_container.add_theme_constant_override("separation", 12)
	filter_margin.add_child(_filters_container)
	_render_filter_pills()

	# Connection / Offline Banner (Minimalist alert bar with 15px margins)
	var banner_margin := MarginContainer.new()
	banner_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	banner_margin.add_theme_constant_override("margin_left", 15)
	banner_margin.add_theme_constant_override("margin_right", 15)
	main_vbox.add_child(banner_margin)

	_connection_banner = _build_connection_banner_node()
	banner_margin.add_child(_connection_banner)

	# Hidden compatibility labels and container for test scripts
	_summary_lbl = Label.new()
	_stats_container = HBoxContainer.new()
	_stats_container.visible = false
	main_vbox.add_child(_stats_container)

	# 3. Main Centered Activity History List (Full-Width Scrollable Feed with 15px margins)
	var list_margin := MarginContainer.new()
	list_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_margin.add_theme_constant_override("margin_left", 15)
	list_margin.add_theme_constant_override("margin_right", 15)
	main_vbox.add_child(list_margin)

	_list_scroll = ScrollContainer.new()
	_list_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_list_scroll.scroll_deadzone = 8
	list_margin.add_child(_list_scroll)

	var list_outer := VBoxContainer.new()
	list_outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_outer.add_theme_constant_override("separation", 12)
	_list_scroll.add_child(list_outer)

	_list_container = VBoxContainer.new()
	_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_container.add_theme_constant_override("separation", 12)
	list_outer.add_child(_list_container)

	_load_more_btn = Button.new()
	_load_more_btn.text = "Tải thêm hoạt động cũ hơn  ▼"
	_load_more_btn.custom_minimum_size = Vector2(0, 56)
	_load_more_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_load_more_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if _font_bold:
		_load_more_btn.add_theme_font_override("font", _font_bold)
		_load_more_btn.add_theme_font_size_override("font_size", 18)
	_style_3d_button(_load_more_btn, Color(1.0, 1.0, 1.0, 0.88), C_JADE, 18, 4, Color("#cbd5e1"))
	_load_more_btn.pressed.connect(_load_next_page)
	_load_more_btn.visible = false
	list_outer.add_child(_load_more_btn)


func _build_connection_banner_node() -> PanelContainer:
	var banner := PanelContainer.new()
	banner.visible = false
	banner.custom_minimum_size = Vector2(0, 38)
	var banner_style := StyleBoxFlat.new()
	banner_style.bg_color = Color(1.0, 0.99, 0.95, 0.90)
	banner_style.border_color = Color(C_AMBER.r, C_AMBER.g, C_AMBER.b, 0.45)
	banner_style.set_border_width_all(1)
	banner_style.border_width_bottom = 2
	banner_style.set_corner_radius_all(12)
	banner_style.shadow_color = Color(C_AMBER.r, C_AMBER.g, C_AMBER.b, 0.08)
	banner_style.shadow_size = 4
	banner_style.shadow_offset = Vector2(0, 2)
	banner_style.content_margin_left = 10
	banner_style.content_margin_right = 8
	banner_style.content_margin_top = 4
	banner_style.content_margin_bottom = 4
	banner.add_theme_stylebox_override("panel", banner_style)

	var banner_row := HBoxContainer.new()
	banner_row.add_theme_constant_override("separation", 8)
	banner.add_child(banner_row)

	var banner_icon_panel := PanelContainer.new()
	banner_icon_panel.custom_minimum_size = Vector2(26, 26)
	banner_icon_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var banner_icon_style := StyleBoxFlat.new()
	banner_icon_style.bg_color = C_AMBER_BG
	banner_icon_style.set_corner_radius_all(13)
	banner_icon_panel.add_theme_stylebox_override("panel", banner_icon_style)
	banner_icon_panel.add_child(_icons8_icon("lock", 14, C_AMBER))
	banner_row.add_child(banner_icon_panel)

	_connection_label = Label.new()
	_connection_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_connection_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_connection_label.add_theme_font_size_override("font_size", 11)
	_connection_label.add_theme_color_override("font_color", C_TEXT)
	_connection_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if _font_bold:
		_connection_label.add_theme_font_override("font", _font_bold)
	banner_row.add_child(_connection_label)

	var retry_connection_btn := Button.new()
	retry_connection_btn.text = "Thử lại"
	retry_connection_btn.custom_minimum_size = Vector2(68, 28)
	retry_connection_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if _font_bold:
		retry_connection_btn.add_theme_font_override("font", _font_bold)
	_style_3d_button(retry_connection_btn, C_AMBER, Color.WHITE, 10, 2, Color("#B45309"))
	retry_connection_btn.pressed.connect(func(): refresh_history())
	banner_row.add_child(retry_connection_btn)

	return banner


func _build_top_bar() -> HBoxContainer:
	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 14)
	top_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# 1. Tactile 3D Circular Back Button (76x76)
	var back_btn := Button.new()
	back_btn.custom_minimum_size = Vector2(76, 76)
	back_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	back_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back_btn.icon = load("res://assets/textures/lucide/arrow-left.svg") as Texture2D
	back_btn.expand_icon = true
	back_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	back_btn.add_theme_constant_override("icon_max_width", 38)
	back_btn.tooltip_text = "Quay lại"

	var style_n := StyleBoxFlat.new()
	style_n.bg_color = Color(1.0, 1.0, 1.0, 0.90)
	style_n.set_corner_radius_all(38)
	style_n.set_border_width_all(2)
	style_n.border_width_bottom = 5
	style_n.border_color = Color(0.85, 0.88, 0.92, 0.85)
	style_n.shadow_color = Color(0, 0, 0, 0.08)
	style_n.shadow_size = 6
	style_n.shadow_offset = Vector2(0, 3)

	var style_h := style_n.duplicate() as StyleBoxFlat
	style_h.bg_color = Color(1.0, 1.0, 1.0, 0.98)
	style_h.border_color = Color("#94a3b8")

	var style_p := style_n.duplicate() as StyleBoxFlat
	style_p.bg_color = Color(0.95, 0.94, 0.92, 0.92)
	style_p.border_width_bottom = 2
	style_p.border_width_top = 4

	back_btn.add_theme_stylebox_override("normal", style_n)
	back_btn.add_theme_stylebox_override("hover", style_h)
	back_btn.add_theme_stylebox_override("pressed", style_p)
	back_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	back_btn.add_theme_color_override("icon_normal_color", C_JADE)

	back_btn.pivot_offset = Vector2(38, 38)
	back_btn.mouse_entered.connect(func() -> void:
		create_tween().tween_property(back_btn, "scale", Vector2(1.06, 1.06), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	back_btn.mouse_exited.connect(func() -> void:
		create_tween().tween_property(back_btn, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/AccountScreen.tscn"))
	top_bar.add_child(back_btn)

	# 2. Left-aligned Title with Frosted Glass Plaque for supreme contrast & readability
	var title_panel := PanelContainer.new()
	title_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var t_style := StyleBoxFlat.new()
	t_style.bg_color = Color(1.0, 1.0, 1.0, 0.85)
	t_style.set_corner_radius_all(18)
	t_style.set_border_width_all(2)
	t_style.border_width_bottom = 4
	t_style.border_color = Color(0.85, 0.88, 0.92, 0.75)
	t_style.shadow_color = Color(0, 0, 0, 0.05)
	t_style.shadow_size = 6
	t_style.shadow_offset = Vector2(0, 2)
	t_style.content_margin_left = 18
	t_style.content_margin_right = 20
	t_style.content_margin_top = 8
	t_style.content_margin_bottom = 8
	title_panel.add_theme_stylebox_override("panel", t_style)
	top_bar.add_child(title_panel)

	_title_lbl = Label.new()
	_title_lbl.text = "LỊCH SỬ HOẠT ĐỘNG"
	_title_lbl.add_theme_font_override("font", load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font)
	_title_lbl.add_theme_font_size_override("font_size", 24)
	_title_lbl.add_theme_color_override("font_color", C_NAVY)
	_title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_panel.add_child(_title_lbl)

	# 3. Flexible spacer to separate title from KPI Stats
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)

	# 4. Top KPI Stats Strip
	_stats_container = HBoxContainer.new()
	_stats_container.add_theme_constant_override("separation", 8)
	_stats_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top_bar.add_child(_stats_container)

	# 5. Tactile 3D Circular Refresh Button (76x76)
	var refresh_btn := Button.new()
	refresh_btn.custom_minimum_size = Vector2(76, 76)
	refresh_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	refresh_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	refresh_btn.icon = load("res://assets/textures/lucide/rotate-cw.svg") as Texture2D
	refresh_btn.expand_icon = true
	refresh_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	refresh_btn.add_theme_constant_override("icon_max_width", 34)
	refresh_btn.tooltip_text = "Làm mới lịch sử"

	refresh_btn.add_theme_stylebox_override("normal", style_n)
	refresh_btn.add_theme_stylebox_override("hover", style_h)
	refresh_btn.add_theme_stylebox_override("pressed", style_p)
	refresh_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	refresh_btn.add_theme_color_override("icon_normal_color", C_JADE)

	refresh_btn.pivot_offset = Vector2(38, 38)
	refresh_btn.mouse_entered.connect(func() -> void:
		create_tween().tween_property(refresh_btn, "scale", Vector2(1.06, 1.06), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	refresh_btn.mouse_exited.connect(func() -> void:
		create_tween().tween_property(refresh_btn, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	refresh_btn.pressed.connect(func(): refresh_history())
	top_bar.add_child(refresh_btn)

	return top_bar


# ── Bento Stats Strip (Hero KPIs with Icons8) ───────────────────────────────

func _render_stats_strip(total_xp: int, avg_accuracy: int, total_stars: int, total_count: int) -> void:
	_clear(_stats_container)

	_stats_container.add_child(_make_bento_item("progress", "%d" % total_xp, "Tổng XP", C_BLUE, C_BLUE_BG))
	_stats_container.add_child(_make_bento_item("game", "%d%%" % avg_accuracy if avg_accuracy > 0 else "—", "Chính xác", C_GREEN, C_GREEN_BG))
	_stats_container.add_child(_make_bento_item("songs", "%d" % total_stars, "Tổng sao", C_GOLD, C_GOLD_BG))
	_stats_container.add_child(_make_bento_item("course", "%d" % total_count, "Hoàn thành", C_PURPLE, C_PURPLE_BG))


func _make_bento_item(icon_name: String, val_text: String, label_text: String, accent_color: Color, bg_color: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.custom_minimum_size = Vector2(0, 42)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 1.0, 0.88)
	style.set_corner_radius_all(14)
	style.set_border_width_all(1)
	style.border_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.35)
	style.border_width_bottom = 3
	style.shadow_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.08)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	style.content_margin_left = 8
	style.content_margin_right = 10
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	p.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(hbox)

	# Icon Badge with Icons8 rich texture
	var icon_badge := PanelContainer.new()
	var badge_size := 28
	icon_badge.custom_minimum_size = Vector2(badge_size, badge_size)
	icon_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var icon_style := StyleBoxFlat.new()
	icon_style.bg_color = bg_color
	icon_style.set_corner_radius_all(badge_size / 2)
	icon_badge.add_theme_stylebox_override("panel", icon_style)
	icon_badge.add_child(_icons8_icon(icon_name, 18))
	hbox.add_child(icon_badge)

	# Text column
	var text_vbox := VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.add_theme_constant_override("separation", -2)
	text_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(text_vbox)

	var val_lbl := Label.new()
	val_lbl.text = val_text
	val_lbl.add_theme_font_size_override("font_size", 14)
	val_lbl.add_theme_color_override("font_color", C_TEXT)
	if _font_bold:
		val_lbl.add_theme_font_override("font", _font_bold)
	text_vbox.add_child(val_lbl)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", C_MUTED)
	if _font_bold:
		lbl.add_theme_font_override("font", _font_bold)
	text_vbox.add_child(lbl)

	return p


# ── Filter Segmented Pills (Icons8 Integrated) ─────────────────────────────

func _render_filter_pills(items: Array = _last_rendered_items) -> void:
	_clear(_filters_container)
	var filter_options := [
		{"label": "Tất cả", "value": "", "icon": "menu"},
		{"label": "Câu hỏi", "value": "QUIZ", "icon": "course"},
		{"label": "Nhịp điệu", "value": "MINIGAME", "icon": "game"},
		{"label": "Luyện tập", "value": "PRACTICE", "icon": "songs"}
	]

	for opt: Dictionary in filter_options:
		var val := str(opt["value"])
		var is_active := val == _filter
		var count := items.size() if val.is_empty() else items.filter(func(item: Variant) -> bool: return item is Dictionary and str((item as Dictionary).get("type", "")).to_upper() == val).size()

		var pill := PanelContainer.new()
		pill.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pill.custom_minimum_size = Vector2(0, 58)

		# Frosted Glass Card Styling
		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(16)
		style.set_border_width_all(2)
		style.border_width_bottom = 4
		style.content_margin_left = 14
		style.content_margin_right = 14
		style.content_margin_top = 6
		style.content_margin_bottom = 6

		if is_active:
			style.bg_color = Color(0.18, 0.49, 0.20, 0.94) # Frosted glowing jade glass
			style.border_color = Color(0.10, 0.35, 0.15, 0.95)
			style.shadow_color = Color(0.18, 0.49, 0.20, 0.30)
			style.shadow_size = 6
			style.shadow_offset = Vector2(0, 2)
		else:
			style.bg_color = Color(1.0, 1.0, 1.0, 0.86) # Frosted white glass
			style.border_color = Color(0.85, 0.88, 0.92, 0.75)
			style.shadow_color = Color(0, 0, 0, 0.05)
			style.shadow_size = 4
			style.shadow_offset = Vector2(0, 2)

		pill.add_theme_stylebox_override("panel", style)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pill.add_child(hbox)

		# Large Icons8 Icon
		var icon_rect := _icons8_icon(str(opt["icon"]), 26)
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(icon_rect)

		# Label
		var label_node := Label.new()
		label_node.text = str(opt["label"])
		label_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label_node.add_theme_font_size_override("font_size", 16)
		label_node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if is_active:
			label_node.add_theme_color_override("font_color", Color.WHITE)
		else:
			label_node.add_theme_color_override("font_color", C_NAVY)
		if _font_bold:
			label_node.add_theme_font_override("font", _font_bold)
		hbox.add_child(label_node)

		# Square Badge Count Card
		var badge := PanelContainer.new()
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.custom_minimum_size = Vector2(34, 34)
		badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var badge_style := StyleBoxFlat.new()
		badge_style.set_corner_radius_all(8) # Square card shape with subtle corners
		badge_style.set_border_width_all(1)
		badge_style.content_margin_left = 3
		badge_style.content_margin_right = 3
		badge_style.content_margin_top = 2
		badge_style.content_margin_bottom = 2
		if is_active:
			badge_style.bg_color = C_GOLD
			badge_style.border_color = Color(1.0, 1.0, 1.0, 0.40)
		else:
			badge_style.bg_color = Color(0.92, 0.94, 0.97, 0.85)
			badge_style.border_color = Color(0.80, 0.84, 0.88, 0.50)
		badge.add_theme_stylebox_override("panel", badge_style)

		var count_lbl := Label.new()
		count_lbl.text = str(count)
		count_lbl.add_theme_font_size_override("font_size", 14)
		count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		count_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if is_active:
			count_lbl.add_theme_color_override("font_color", Color.WHITE)
		else:
			count_lbl.add_theme_color_override("font_color", C_NAVY)
		if _font_bold:
			count_lbl.add_theme_font_override("font", _font_bold)
		badge.add_child(count_lbl)
		hbox.add_child(badge)

		# Clickable Button overlay
		var btn := Button.new()
		btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		btn.flat = true
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var empty_sb := StyleBoxEmpty.new()
		btn.add_theme_stylebox_override("normal", empty_sb)
		btn.add_theme_stylebox_override("hover", empty_sb)
		btn.add_theme_stylebox_override("pressed", empty_sb)
		btn.add_theme_stylebox_override("focus", empty_sb)
		btn.pressed.connect(_set_filter.bind(val))
		pill.add_child(btn)

		pill.pivot_offset = Vector2(80, 29)
		pill.mouse_entered.connect(func() -> void:
			create_tween().tween_property(pill, "scale", Vector2(1.02, 1.02), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		)
		pill.mouse_exited.connect(func() -> void:
			create_tween().tween_property(pill, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		)

		_filters_container.add_child(pill)


func _set_filter(value: String) -> void:
	_filter = value
	_render_filter_pills()
	await refresh_history()


# ── Data Fetching & State ──────────────────────────────────────────────────

func refresh_history() -> void:
	if _loading:
		return
	_loading = true
	_history_changed_while_loading = false
	_page = 0
	_total_pages = 0
	_items.clear()
	_connection_banner.visible = false
	_render_loading_skeleton()

	var backend_report := get_node_or_null("/root/BackendReport")
	if backend_report != null and backend_report.has_method("retry_pending_game_attempts"):
		await backend_report.retry_pending_game_attempts()

	await _fetch_page(true)
	_loading = false
	if _history_changed_while_loading:
		_history_changed_while_loading = false
		call_deferred("refresh_history")


func _load_next_page() -> void:
	if _loading or (_total_pages > 0 and _page + 1 >= _total_pages):
		return
	_loading = true
	_page += 1
	await _fetch_page(false)
	_loading = false


func _fetch_page(replace: bool) -> void:
	var response: Dictionary = await _api.get_activity_history(_page, PAGE_SIZE, _filter)
	if not _api._is_success(response):
		_connection_label.text = "Chưa có kết nối — dữ liệu vẫn được lưu trên thiết bị"
		_connection_banner.visible = true
		_render(merge_pending_items([]))
		return

	var page_data := _extract_data(response)
	var content: Array = page_data.get("content", []) as Array
	var mapped: Array[Dictionary] = []
	for value: Variant in content:
		if value is Dictionary:
			mapped.append(value as Dictionary)

	if replace:
		_items = mapped
	else:
		_items.append_array(mapped)

	_total_pages = int(page_data.get("totalPages", 0))
	var merged := merge_pending_items(_items)
	var pending_count := _pending_count(merged)
	if pending_count > 0:
		_connection_label.text = "%d hoạt động chờ đồng bộ — dữ liệu vẫn được lưu trên thiết bị" % pending_count
		_connection_banner.visible = true
	else:
		_connection_banner.visible = false
	_render(merged)


func merge_pending_items(confirmed: Array) -> Array:
	var merged: Array = []
	# Sample/offline quiz attempts have no backend id, so they cannot be retried
	# but must still be visible to the learner on the history screen.
	for local_value: Variant in SecureDataManager.get_local_activity_history():
		if local_value is Dictionary:
			var local_item := _map_local(local_value as Dictionary)
			if _filter.is_empty() or local_item.get("type") == _filter:
				merged.append(local_item)
	for pending: Variant in SecureDataManager.get_pending_game_attempts():
		if pending is Dictionary:
			var item := _map_pending(pending as Dictionary)
			if _filter.is_empty() or item.get("type") == _filter:
				merged.append(item)
	for item: Variant in confirmed:
		if item is Dictionary:
			merged.append(item as Dictionary)
	merged.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _history_timestamp(a) > _history_timestamp(b)
	)
	return merged


func _map_pending(pending: Dictionary) -> Dictionary:
	var kind := str(pending.get("kind", "minigame")).to_lower()
	var activity_type := "QUIZ" if kind == "quiz" else "MINIGAME"
	var completed_at := str(pending.get("completed_at", pending.get("started_at", "")))
	return {
		"eventId": "PENDING:" + str(pending.get("client_attempt_id", "local")),
		"type": activity_type,
		"title": str(pending.get("title", "Câu hỏi" if activity_type == "QUIZ" else "Mini Game")),
		"lessonTitle": str(pending.get("lessonTitle", pending.get("lesson_title", ""))),
		"score": pending.get("score", null),
		"maxScore": pending.get("maxScore", pending.get("max_score", 100)) if pending.get("score", null) != null else null,
		"completedAt": str(pending.get("completedAt", completed_at)),
		"status": "PENDING_SYNC",
		"isCorrect": pending.get("isCorrect", pending.get("is_correct", null)),
		"selectedAnswer": pending.get("selectedAnswer", pending.get("selected_answer", "")),
		"correctAnswer": pending.get("correctAnswer", pending.get("correct_answer", "")),
		"previewStars": pending.get("previewStars", pending.get("preview_stars", null)),
		"previewPoints": pending.get("previewPoints", pending.get("preview_points", null)),
		"pendingPayload": pending
	}


func _map_local(local: Dictionary) -> Dictionary:
	return {
		"eventId": "LOCAL:" + str(local.get("client_attempt_id", local.get("eventId", "local"))),
		"type": "QUIZ",
		"title": str(local.get("title", "Câu hỏi")),
		"lessonTitle": str(local.get("lessonTitle", local.get("lesson_title", ""))),
		"score": local.get("score", null),
		"maxScore": local.get("maxScore", local.get("max_score", 100)) if local.get("score", null) != null else null,
		"completedAt": str(local.get("completedAt", local.get("completed_at", ""))),
		"status": "LOCAL_ONLY",
		"isCorrect": local.get("isCorrect", local.get("is_correct", null)),
		"selectedAnswer": local.get("selectedAnswer", local.get("selected_answer", "")),
		"correctAnswer": local.get("correctAnswer", local.get("correct_answer", "")),
		"previewStars": local.get("previewStars", local.get("preview_stars", null)),
		"previewPoints": local.get("previewPoints", local.get("preview_points", null)),
		"question": str(local.get("question", "")),
		"pendingPayload": local
	}


# ── Render Stream & Timeline Groups ─────────────────────────────────────────

func _render(items: Array) -> void:
	_clear(_list_container)
	_last_rendered_items = items.duplicate(true)
	_render_filter_pills(items)

	# Calculate Stats
	var total_xp := 0
	var total_stars := 0
	var accuracy_sum := 0.0
	var accuracy_count := 0
	for item_val: Variant in items:
		if not item_val is Dictionary:
			continue
		var item: Dictionary = item_val
		# Local and pending rewards are previews only. They must not inflate the
		# confirmed XP/star KPIs before the backend acknowledges the attempt.
		if _is_confirmed_item(item):
			total_xp += int(item.get("pointsEarned", 0))
			total_stars += int(item.get("starsEarned", 0))
		if item.has("score") and item.get("score") != null:
			var sc = float(item.get("score", 0.0))
			var m_sc = float(item.get("maxScore", 100.0))
			if m_sc > 0:
				accuracy_sum += (sc / m_sc) * 100.0
				accuracy_count += 1

	var avg_acc := int(round(accuracy_sum / float(maxi(1, accuracy_count)))) if accuracy_count > 0 else 0
	var pending_count := _pending_count(items)
	var local_count := _local_count(items)
	var completed_count := maxi(items.size() - pending_count - local_count, 0)
	_render_stats_strip(total_xp, avg_acc, total_stars, completed_count)
	_summary_lbl.text = "%d hoạt động đã ghi nhận%s" % [
		completed_count,
		" · %d chờ đồng bộ" % pending_count if pending_count > 0 else ""
	]
	if local_count > 0:
		_summary_lbl.text += " · %d chỉ trên thiết bị" % local_count

	if items.is_empty():
		_list_container.add_child(_build_empty_state())
		_load_more_btn.visible = false
		return

	# Group items by date section (Hôm nay, Hôm qua, Tuần này, Cũ hơn)
	var groups := _group_items_by_date(items)
	for group_title: String in groups.keys():
		var group_items: Array = groups[group_title]
		if group_items.is_empty():
			continue

		# Section Header Badge Ribbon
		var section_box := HBoxContainer.new()
		section_box.add_theme_constant_override("separation", 10)
		_list_container.add_child(section_box)

		var section_badge := PanelContainer.new()
		var sb_style := StyleBoxFlat.new()
		sb_style.bg_color = Color(1.0, 1.0, 1.0, 0.88)
		sb_style.set_corner_radius_all(10)
		sb_style.set_border_width_all(1)
		sb_style.border_color = Color(0.85, 0.88, 0.92, 0.75)
		sb_style.content_margin_left = 12
		sb_style.content_margin_right = 12
		sb_style.content_margin_top = 4
		sb_style.content_margin_bottom = 4
		section_badge.add_theme_stylebox_override("panel", sb_style)
		section_box.add_child(section_badge)

		var section_lbl := Label.new()
		section_lbl.text = group_title.to_upper()
		section_lbl.add_theme_font_size_override("font_size", 12)
		section_lbl.add_theme_color_override("font_color", C_NAVY)
		if _font_bold:
			section_lbl.add_theme_font_override("font", _font_bold)
		section_badge.add_child(section_lbl)

		var line := ColorRect.new()
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		line.custom_minimum_size = Vector2(0, 2)
		line.color = Color(1.0, 1.0, 1.0, 0.35)
		section_box.add_child(line)

		# Render cards in this section
		for item_val: Variant in group_items:
			if item_val is Dictionary:
				_list_container.add_child(_make_3d_activity_card(item_val as Dictionary))

	_load_more_btn.visible = _total_pages > 0 and _page + 1 < _total_pages


func _render_loading_skeleton() -> void:
	_clear(_list_container)
	_last_rendered_items = []
	_render_filter_pills([])
	_render_stats_strip(0, 0, 0, 0)
	_summary_lbl.text = "Đang tải lịch sử hoạt động…"
	_load_more_btn.visible = false
	for _index in 3:
		_list_container.add_child(_make_loading_skeleton())


func _make_loading_skeleton() -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 72)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#EFEBE2")
	style.set_corner_radius_all(18)
	card.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var dot := ColorRect.new()
	dot.color = Color("#DFD8CB")
	dot.custom_minimum_size = Vector2(42, 42)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(dot)
	for width in [0.44, 0.14, 0.14, 0.14, 0.14]:
		var bar := ColorRect.new()
		bar.color = Color("#DFD8CB")
		bar.custom_minimum_size = Vector2(0, 16)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_stretch_ratio = width
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(bar)
	return card


func _pending_count(items: Array) -> int:
	var count := 0
	for item: Variant in items:
		if item is Dictionary and str((item as Dictionary).get("status", "")).to_upper() in ["PENDING_SYNC", "SYNCING", "FAILED_SYNC"]:
			count += 1
	return count


func _local_count(items: Array) -> int:
	var count := 0
	for item: Variant in items:
		if item is Dictionary and str((item as Dictionary).get("status", "")).to_upper() == "LOCAL_ONLY":
			count += 1
	return count


func _is_confirmed_item(item: Dictionary) -> bool:
	var status := str(item.get("status", "")).to_upper()
	return status not in ["PENDING_SYNC", "SYNCING", "FAILED_SYNC", "LOCAL_ONLY"]


func _group_items_by_date(items: Array) -> Dictionary:
	var groups := {
		"Hôm nay": [],
		"Hôm qua": [],
		"Tuần này": [],
		"Hoạt động trước đó": []
	}

	var now_unix := Time.get_unix_time_from_system()
	for item in items:
		var date_str := str(item.get("completedAt", item.get("startedAt", "")))
		var status := str(item.get("status", "")).to_upper()
		if date_str.is_empty() or status in ["PENDING_SYNC", "SYNCING", "FAILED_SYNC", "LOCAL_ONLY"]:
			groups["Hôm nay"].append(item)
			continue

		var item_unix := _parse_iso_to_unix(date_str)
		var diff_seconds := now_unix - item_unix
		if diff_seconds < 86400: # < 24h
			groups["Hôm nay"].append(item)
		elif diff_seconds < 172800: # < 48h
			groups["Hôm qua"].append(item)
		elif diff_seconds < 604800: # < 7 days
			groups["Tuần này"].append(item)
		else:
			groups["Hoạt động trước đó"].append(item)

	return groups


func _history_timestamp(item: Dictionary) -> int:
	var date_str := str(item.get("completedAt", item.get("startedAt", "")))
	if date_str.is_empty():
		return 0
	return _parse_iso_to_unix(date_str)


func _parse_iso_to_unix(iso_str: String) -> int:
	var clean := iso_str.replace("T", " ").left(19)
	var parts := clean.split(" ")
	if parts.size() < 2:
		return 0
	var date_parts := parts[0].split("-")
	var time_parts := parts[1].split(":")
	if date_parts.size() < 3 or time_parts.size() < 3:
		return 0
	var dict := {
		"year": int(date_parts[0]),
		"month": int(date_parts[1]),
		"day": int(date_parts[2]),
		"hour": int(time_parts[0]),
		"minute": int(time_parts[1]),
		"second": int(time_parts[2])
	}
	return Time.get_unix_time_from_datetime_dict(dict)


# ── 3D Activity Card (Icons8 Integrated) ───────────────────────────────────

func _make_3d_activity_card(item: Dictionary) -> Button:
	var type_code := str(item.get("type", "PRACTICE")).to_upper()
	var accent := _color_for_type(type_code)
	var bg_accent := _bg_color_for_type(type_code)

	var card := Button.new()
	card.custom_minimum_size = Vector2(0, 84)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	# 3D Frosted Glass Card Styling
	_style_3d_card(card, Color(1.0, 1.0, 1.0, 0.88), Color(0.85, 0.88, 0.92, 0.80), 18, 4)

	# Content layout
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 14)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(hbox)

	# 1. Left Round Icon Box with Icons8 Texture (56x56)
	var icon_panel := PanelContainer.new()
	icon_panel.custom_minimum_size = Vector2(56, 56)
	icon_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var icon_box_style := StyleBoxFlat.new()
	icon_box_style.bg_color = Color(bg_accent.r, bg_accent.g, bg_accent.b, 0.90)
	icon_box_style.set_corner_radius_all(28)
	icon_box_style.set_border_width_all(2)
	icon_box_style.border_color = Color(accent.r, accent.g, accent.b, 0.45)
	icon_panel.add_theme_stylebox_override("panel", icon_box_style)

	var icon_name := _icon_name_for_type(type_code)
	icon_panel.add_child(_icons8_icon(icon_name, 36))
	hbox.add_child(icon_panel)

	# 2. Activity title & category
	var content_vbox := VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.size_flags_stretch_ratio = 1.0
	content_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	content_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(content_vbox)

	var title_lbl := Label.new()
	title_lbl.text = str(item.get("title", item.get("lessonTitle", "Hoạt động")))
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", C_NAVY)
	title_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	if _font_bold:
		title_lbl.add_theme_font_override("font", _font_bold)
	content_vbox.add_child(title_lbl)

	var subtitle := Label.new()
	subtitle.text = "%s · %s" % [_type_name(type_code), _relative_time(str(item.get("completedAt", item.get("startedAt", ""))))]
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", accent)
	subtitle.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	subtitle.autowrap_mode = TextServer.AUTOWRAP_OFF
	if _font_bold:
		subtitle.add_theme_font_override("font", _font_bold)
	elif _font_regular:
		subtitle.add_theme_font_override("font", _font_regular)
	content_vbox.add_child(subtitle)

	# 3. Result columns: prominent essential metrics
	var metrics := HBoxContainer.new()
	metrics.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	metrics.add_theme_constant_override("separation", 8)
	metrics.alignment = BoxContainer.ALIGNMENT_END
	metrics.size_flags_stretch_ratio = 1.0
	hbox.add_child(metrics)

	# Metric 1: Score Badge (Large & Bold)
	if item.has("score") and item.get("score") != null:
		metrics.add_child(_make_activity_metric("Điểm", _score_text(item), C_BLUE, 88, C_BLUE_BG))

	# Metric 2: Achievement Reward (Stars, XP, or Accuracy)
	var stars: int = int(item.get("starsEarned", item.get("previewStars", 0)))
	var xp: int = int(item.get("pointsEarned", item.get("previewPoints", 0)))
	if stars > 0:
		metrics.add_child(_make_activity_metric("Thành tích", _stars_display(stars), C_GOLD, 88, C_GOLD_BG))
	elif xp > 0:
		metrics.add_child(_make_activity_metric("Thưởng", "+%d XP" % xp, C_PURPLE, 84, C_PURPLE_BG))
	elif item.has("score") and item.get("score") != null:
		metrics.add_child(_make_activity_metric("Chính xác", _accuracy_text(item), C_GREEN, 84, C_GREEN_BG))

	# Metric 3: Sync Status Alert
	var sync_status_upper := str(item.get("status", "")).to_upper()
	if sync_status_upper in ["PENDING_SYNC", "SYNCING"]:
		metrics.add_child(_make_activity_metric("Trạng thái", "Chờ sync", C_AMBER, 94, C_AMBER_BG))
	elif sync_status_upper in ["FAILED_SYNC", "SYNC_FAILED", "FAILED"]:
		metrics.add_child(_make_activity_metric("Trạng thái", "Lỗi sync", Color("#DC2626"), 94, Color("#FEE2E2")))
	elif sync_status_upper == "LOCAL_ONLY":
		metrics.add_child(_make_activity_metric("Trạng thái", "Thiết bị", C_MUTED, 88, Color("#F3F4F6")))

	# Chevron indicator
	var chevron := Label.new()
	chevron.text = "›"
	chevron.add_theme_font_size_override("font_size", 28)
	chevron.add_theme_color_override("font_color", Color("#94a3b8"))
	if _font_bold:
		chevron.add_theme_font_override("font", _font_bold)
	hbox.add_child(chevron)

	card.pressed.connect(_open_detail.bind(item))
	return card


func _format_card_subtitle(item: Dictionary) -> String:
	var score_str := _score_text(item)
	var time_str := _relative_time(str(item.get("completedAt", item.get("startedAt", ""))))
	if not score_str.is_empty():
		return "%s · %s" % [score_str, time_str]
	return time_str


func _make_activity_metric(label_text: String, value_text: String, value_color: Color, width: float, bg_color: Color = Color.TRANSPARENT) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(width, 48)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var pstyle := StyleBoxFlat.new()
	pstyle.bg_color = Color(bg_color.r, bg_color.g, bg_color.b, 0.88) if bg_color != Color.TRANSPARENT else Color(0.96, 0.96, 0.98, 0.88)
	pstyle.set_corner_radius_all(12)
	pstyle.set_border_width_all(1)
	pstyle.border_color = Color(value_color.r, value_color.g, value_color.b, 0.28)
	pstyle.content_margin_left = 8
	pstyle.content_margin_right = 8
	pstyle.content_margin_top = 3
	pstyle.content_margin_bottom = 3
	panel.add_theme_stylebox_override("panel", pstyle)

	var metric := VBoxContainer.new()
	metric.alignment = BoxContainer.ALIGNMENT_CENTER
	metric.add_theme_constant_override("separation", 0)
	panel.add_child(metric)

	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", C_MUTED)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _font_bold:
		label.add_theme_font_override("font", _font_bold)
	metric.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 16)
	value.add_theme_color_override("font_color", value_color)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if _font_bold:
		value.add_theme_font_override("font", _font_bold)
	metric.add_child(value)
	return panel


func _build_empty_state() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 160)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 1.0, 0.86)
	style.set_corner_radius_all(22)
	style.border_color = Color(0.85, 0.88, 0.92, 0.75)
	style.set_border_width_all(2)
	style.border_width_bottom = 5
	style.shadow_color = Color(0, 0, 0, 0.06)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 3)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	# Decorative circular emblem with Icons8 songs/music
	var emblem := PanelContainer.new()
	emblem.custom_minimum_size = Vector2(58, 58)
	emblem.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var emblem_style := StyleBoxFlat.new()
	emblem_style.bg_color = Color("#FFF8E7")
	emblem_style.set_corner_radius_all(29)
	emblem_style.set_border_width_all(1)
	emblem_style.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.4)
	emblem.add_theme_stylebox_override("panel", emblem_style)
	emblem.add_child(_icons8_icon("songs", 38))
	vbox.add_child(emblem)

	var title := Label.new()
	title.text = "Chưa có hoạt động phù hợp"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", C_JADE)
	if _font_title:
		title.add_theme_font_override("font", _font_title)
	elif _font_bold:
		title.add_theme_font_override("font", _font_bold)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = "Hoàn thành Câu hỏi, Mini Game hoặc Luyện tập để ghi dấu hành trình âm nhạc của bạn ở đây."
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", C_MUTED)
	if _font_regular:
		desc.add_theme_font_override("font", _font_regular)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	var explore_btn := Button.new()
	explore_btn.text = "Khám phá bài học ngay  →"
	explore_btn.custom_minimum_size = Vector2(220, 44)
	explore_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	explore_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if _font_bold:
		explore_btn.add_theme_font_override("font", _font_bold)
	_style_3d_button(explore_btn, C_JADE, Color.WHITE, 16, 3, C_JADE_DARK)
	explore_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	vbox.add_child(explore_btn)

	return panel


# ── Modern Centered Lacquer Modal View ────────────────────────────────────────

func _build_detail_sheet() -> void:
	_modal_overlay = Control.new()
	_modal_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_overlay.visible = false
	_modal_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_modal_overlay)

	# Rich Lacquer Dark Scrim
	var scrim := ColorRect.new()
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(0.04, 0.07, 0.05, 0.68)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal_overlay.add_child(scrim)
	scrim.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_close_detail_sheet()
	)

	# CenterContainer to guarantee 100% dead-center positioning
	var center_wrapper := CenterContainer.new()
	center_wrapper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center_wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_modal_overlay.add_child(center_wrapper)

	# Modal Plaque Container (Doppelrand Architecture)
	_modal_card = PanelContainer.new()
	var vp := get_viewport_rect().size
	var card_w := minf(580.0, vp.x - 32.0)
	var max_scroll_h := minf(vp.y - 40.0, 460.0)
	_modal_card.custom_minimum_size = Vector2(card_w, 0)
	_modal_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_modal_card.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var sheet_style := StyleBoxFlat.new()
	sheet_style.bg_color = Color("#FCFAF6")
	sheet_style.set_corner_radius_all(24)
	sheet_style.set_border_width_all(1)
	sheet_style.border_color = Color(0.85, 0.82, 0.76)
	sheet_style.border_width_bottom = 5
	sheet_style.shadow_color = Color(0, 0, 0, 0.35)
	sheet_style.shadow_size = 32
	sheet_style.shadow_offset = Vector2(0, 8)
	sheet_style.content_margin_left = 22
	sheet_style.content_margin_right = 22
	sheet_style.content_margin_top = 18
	sheet_style.content_margin_bottom = 18
	_modal_card.add_theme_stylebox_override("panel", sheet_style)
	center_wrapper.add_child(_modal_card)

	var modal_scroll := ScrollContainer.new()
	modal_scroll.custom_minimum_size = Vector2(0, minf(max_scroll_h, 440.0))
	modal_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	modal_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_modal_card.add_child(modal_scroll)

	_modal_content = VBoxContainer.new()
	_modal_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_modal_content.add_theme_constant_override("separation", 14)
	modal_scroll.add_child(_modal_content)


func _open_detail(item: Dictionary) -> void:
	_active_modal_item = item
	_clear(_modal_content)
	_modal_overlay.visible = true
	_modal_overlay.modulate.a = 0.0

	var tw := create_tween()
	tw.tween_property(_modal_overlay, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_SINE)

	var type_code := str(item.get("type", "PRACTICE")).to_upper()
	var accent := _color_for_type(type_code)

	# 1. Header with Category, Title, and Circular Close Button
	var header_hbox := HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 12)
	_modal_content.add_child(header_hbox)

	var icon_badge := PanelContainer.new()
	icon_badge.custom_minimum_size = Vector2(44, 44)
	icon_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var icon_badge_style := StyleBoxFlat.new()
	icon_badge_style.bg_color = _bg_color_for_type(type_code)
	icon_badge_style.set_corner_radius_all(22)
	icon_badge_style.set_border_width_all(1)
	icon_badge_style.border_color = Color(accent.r, accent.g, accent.b, 0.35)
	icon_badge.add_theme_stylebox_override("panel", icon_badge_style)
	icon_badge.add_child(_icons8_icon(_icon_name_for_type(type_code), 26))
	header_hbox.add_child(icon_badge)

	var title_vbox := VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_vbox.add_theme_constant_override("separation", 2)
	header_hbox.add_child(title_vbox)

	var act_type := Label.new()
	act_type.text = _type_name(type_code).to_upper()
	act_type.add_theme_font_size_override("font_size", 11)
	act_type.add_theme_color_override("font_color", accent)
	if _font_bold:
		act_type.add_theme_font_override("font", _font_bold)
	title_vbox.add_child(act_type)

	var title_lbl := Label.new()
	title_lbl.text = str(item.get("title", "Chi tiết hoạt động"))
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", C_JADE)
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if _font_title:
		title_lbl.add_theme_font_override("font", _font_title)
	elif _font_bold:
		title_lbl.add_theme_font_override("font", _font_bold)
	title_vbox.add_child(title_lbl)

	var lesson_lbl := Label.new()
	var lesson_title_str := str(item.get("lessonTitle", ""))
	lesson_lbl.text = "%s · %s" % [lesson_title_str if not lesson_title_str.is_empty() else "Bài học âm nhạc", _relative_time(str(item.get("completedAt", item.get("startedAt", ""))))]
	lesson_lbl.add_theme_font_size_override("font_size", 12)
	lesson_lbl.add_theme_color_override("font_color", C_MUTED)
	if _font_regular:
		lesson_lbl.add_theme_font_override("font", _font_regular)
	title_vbox.add_child(lesson_lbl)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(36, 36)
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if _font_bold:
		close_btn.add_theme_font_override("font", _font_bold)
	_style_3d_button(close_btn, Color("#F0ECE1"), C_MUTED, 18, 2)
	close_btn.pressed.connect(_close_detail_sheet)
	header_hbox.add_child(close_btn)

	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 1)
	divider.color = Color("#EBE4D8")
	_modal_content.add_child(divider)

	# 2. Results Highlights 3-Capsule Bento Row
	var score_val := _score_text(item)
	var stars_val := _stars_display(int(item.get("previewStars", item.get("starsEarned", 0))))
	var xp_val := "+%d XP" % int(item.get("previewPoints", item.get("pointsEarned", 0)))

	var bento_row := HBoxContainer.new()
	bento_row.add_theme_constant_override("separation", 8)
	bento_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_modal_content.add_child(bento_row)

	bento_row.add_child(_make_modal_stat_box("ĐIỂM SỐ", score_val, C_BLUE, C_BLUE_BG))
	bento_row.add_child(_make_modal_stat_box("NGÔI SAO", stars_val, C_GOLD, C_GOLD_BG))
	bento_row.add_child(_make_modal_stat_box("KINH NGHIỆM", xp_val, C_PURPLE, C_PURPLE_BG))

	# 3. Content Breakdown based on status & type
	if str(item.get("status", "")).to_upper() in ["PENDING_SYNC", "SYNCING", "FAILED_SYNC"]:
		_render_modal_sync_banner("Chờ đồng bộ lên máy chủ. Phần thưởng sẽ được ghi nhận khi có kết nối.", C_AMBER, C_AMBER_BG)
		_render_quiz_or_game_details(item, type_code)
		_add_modal_actions(item)
		return

	if str(item.get("status", "")).to_upper() == "LOCAL_ONLY":
		_render_modal_sync_banner("Hoạt động lưu trên thiết bị này.", C_MUTED, Color("#F3F4F6"))
		_render_quiz_or_game_details(item, type_code)
		_add_modal_actions(item)
		return

	var loading_row := Label.new()
	loading_row.text = "Đang tải thêm chi tiết..."
	loading_row.add_theme_font_size_override("font_size", 12)
	loading_row.add_theme_color_override("font_color", C_MUTED)
	_modal_content.add_child(loading_row)

	var response: Dictionary = await _api.get_activity_history_detail(str(item.get("eventId", "")))
	_clear(_modal_content)
	_modal_content.add_child(header_hbox)
	_modal_content.add_child(divider)

	var detail := _extract_data(response) if _api._is_success(response) else item
	var live_score := _score_text(detail)
	var live_stars := _stars_display(int(detail.get("starsEarned", item.get("previewStars", 0))))
	var live_xp := "+%d XP" % int(detail.get("pointsEarned", item.get("previewPoints", 0)))

	var bento_row_live := HBoxContainer.new()
	bento_row_live.add_theme_constant_override("separation", 8)
	bento_row_live.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_modal_content.add_child(bento_row_live)
	bento_row_live.add_child(_make_modal_stat_box("ĐIỂM SỐ", live_score, C_BLUE, C_BLUE_BG))
	bento_row_live.add_child(_make_modal_stat_box("NGÔI SAO", live_stars, C_GOLD, C_GOLD_BG))
	bento_row_live.add_child(_make_modal_stat_box("KINH NGHIỆM", live_xp, C_PURPLE, C_PURPLE_BG))

	_render_quiz_or_game_details(detail, type_code)
	_add_modal_actions(item)


func _make_modal_stat_box(label_str: String, val_str: String, text_color: Color, bg_color: Color) -> PanelContainer:
	var box := PanelContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.custom_minimum_size = Vector2(0, 48)
	var bstyle := StyleBoxFlat.new()
	bstyle.bg_color = bg_color
	bstyle.set_corner_radius_all(12)
	bstyle.content_margin_left = 10
	bstyle.content_margin_right = 10
	bstyle.content_margin_top = 6
	bstyle.content_margin_bottom = 6
	box.add_theme_stylebox_override("panel", bstyle)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 0)
	box.add_child(vbox)

	var l := Label.new()
	l.text = label_str
	l.add_theme_font_size_override("font_size", 9)
	l.add_theme_color_override("font_color", Color(text_color.r, text_color.g, text_color.b, 0.75))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _font_bold:
		l.add_theme_font_override("font", _font_bold)
	vbox.add_child(l)

	var v := Label.new()
	v.text = val_str
	v.add_theme_font_size_override("font_size", 14)
	v.add_theme_color_override("font_color", text_color)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _font_bold:
		v.add_theme_font_override("font", _font_bold)
	vbox.add_child(v)

	return box


func _render_modal_sync_banner(text: String, text_color: Color, bg_color: Color) -> void:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(12)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)

	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", text_color)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(lbl)
	_modal_content.add_child(panel)


func _render_quiz_or_game_details(detail: Dictionary, type_code: String) -> void:
	var card := PanelContainer.new()
	var cstyle := StyleBoxFlat.new()
	cstyle.bg_color = Color("#F6F3EC")
	cstyle.set_corner_radius_all(14)
	cstyle.set_border_width_all(1)
	cstyle.border_color = Color("#EBE4D8")
	cstyle.content_margin_left = 14
	cstyle.content_margin_right = 14
	cstyle.content_margin_top = 10
	cstyle.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", cstyle)
	_modal_content.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	card.add_child(vbox)

	if type_code == "QUIZ":
		var question_str := str(detail.get("question", ""))
		if not question_str.is_empty():
			var q_box := VBoxContainer.new()
			q_box.add_theme_constant_override("separation", 2)
			var q_tag := Label.new()
			q_tag.text = "CÂU HỎI"
			q_tag.add_theme_font_size_override("font_size", 10)
			q_tag.add_theme_color_override("font_color", C_MUTED)
			if _font_bold:
				q_tag.add_theme_font_override("font", _font_bold)
			q_box.add_child(q_tag)

			var q_lbl := Label.new()
			q_lbl.text = question_str
			q_lbl.add_theme_font_size_override("font_size", 13)
			q_lbl.add_theme_color_override("font_color", C_JADE)
			q_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			if _font_bold:
				q_lbl.add_theme_font_override("font", _font_bold)
			q_box.add_child(q_lbl)
			vbox.add_child(q_box)

		var sel_ans := str(detail.get("selectedAnswer", ""))
		var cor_ans := str(detail.get("correctAnswer", ""))
		var is_cor: Variant = detail.get("isCorrect", null)
		var is_correct_bool: bool = (is_cor == true) or (not sel_ans.is_empty() and sel_ans == cor_ans)

		var ans_row := HBoxContainer.new()
		ans_row.add_theme_constant_override("separation", 10)
		ans_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_child(ans_row)

		# Selected Answer Pill
		var sel_panel := PanelContainer.new()
		sel_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sp_style := StyleBoxFlat.new()
		sp_style.bg_color = C_GREEN_BG if is_correct_bool else Color("#FEE2E2")
		sp_style.set_corner_radius_all(10)
		sp_style.content_margin_left = 10
		sp_style.content_margin_right = 10
		sp_style.content_margin_top = 6
		sp_style.content_margin_bottom = 6
		sel_panel.add_theme_stylebox_override("panel", sp_style)
		ans_row.add_child(sel_panel)

		var sel_vbox := VBoxContainer.new()
		sel_vbox.add_theme_constant_override("separation", 0)
		sel_panel.add_child(sel_vbox)

		var sel_title := Label.new()
		sel_title.text = "Bạn đã chọn:"
		sel_title.add_theme_font_size_override("font_size", 10)
		sel_title.add_theme_color_override("font_color", C_MUTED)
		sel_vbox.add_child(sel_title)

		var sel_val := Label.new()
		sel_val.text = "%s %s" % [sel_ans if not sel_ans.is_empty() else "—", "✓" if is_correct_bool else "✗"]
		sel_val.add_theme_font_size_override("font_size", 13)
		sel_val.add_theme_color_override("font_color", C_GREEN if is_correct_bool else Color("#DC2626"))
		if _font_bold:
			sel_val.add_theme_font_override("font", _font_bold)
		sel_vbox.add_child(sel_val)

		# Correct Answer Pill (if different)
		if not is_correct_bool and not cor_ans.is_empty():
			var cor_panel := PanelContainer.new()
			cor_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var cp_style := StyleBoxFlat.new()
			cp_style.bg_color = C_GREEN_BG
			cp_style.set_corner_radius_all(10)
			cp_style.content_margin_left = 10
			cp_style.content_margin_right = 10
			cp_style.content_margin_top = 6
			cp_style.content_margin_bottom = 6
			cor_panel.add_theme_stylebox_override("panel", cp_style)
			ans_row.add_child(cor_panel)

			var cor_vbox := VBoxContainer.new()
			cor_vbox.add_theme_constant_override("separation", 0)
			cor_panel.add_child(cor_vbox)

			var cor_title := Label.new()
			cor_title.text = "Đáp án chính xác:"
			cor_title.add_theme_font_size_override("font_size", 10)
			cor_title.add_theme_color_override("font_color", C_MUTED)
			cor_vbox.add_child(cor_title)

			var cor_val := Label.new()
			cor_val.text = "%s ✓" % cor_ans
			cor_val.add_theme_font_size_override("font_size", 13)
			cor_val.add_theme_color_override("font_color", C_GREEN)
			if _font_bold:
				cor_val.add_theme_font_override("font", _font_bold)
			cor_vbox.add_child(cor_val)

	elif type_code == "MINIGAME":
		if detail.has("challengeType"):
			_add_modal_row_inside(vbox, "Loại thử thách", str(detail.get("challengeType", "—")), C_TEXT)
		_add_modal_row_inside(vbox, "Thời gian thực hiện", _duration_text(str(detail.get("startedAt", "")), str(detail.get("completedAt", ""))), C_MUTED)
	else:
		_add_modal_row_inside(vbox, "Điểm cao độ (Pitch)", str(detail.get("pitchScore", "—")), C_GREEN)
		_add_modal_row_inside(vbox, "Điểm nhịp điệu (Rhythm)", str(detail.get("rhythmScore", "—")), C_BLUE)
		_add_modal_row_inside(vbox, "Điểm sắc thái (Dynamics)", str(detail.get("dynamicsScore", "—")), C_PURPLE)


func _add_modal_row_inside(parent: VBoxContainer, label_text: String, value_text: String, val_color: Color) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var lbl := Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", C_MUTED)
	row.add_child(lbl)

	var val := Label.new()
	val.text = value_text
	val.add_theme_font_size_override("font_size", 13)
	val.add_theme_color_override("font_color", val_color)
	if _font_bold:
		val.add_theme_font_override("font", _font_bold)
	row.add_child(val)

	parent.add_child(row)


func _add_modal_actions(item: Dictionary) -> void:
	var action_hbox := HBoxContainer.new()
	action_hbox.add_theme_constant_override("separation", 10)
	action_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var type_code := str(item.get("type", "PRACTICE")).to_upper()
	var retry_btn := Button.new()
	retry_btn.text = "Luyện tập lại bài này  →"
	retry_btn.custom_minimum_size = Vector2(0, 46)
	retry_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	retry_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if _font_bold:
		retry_btn.add_theme_font_override("font", _font_bold)
	_style_3d_button(retry_btn, C_JADE, Color.WHITE, 16, 4, C_JADE_DARK)
	retry_btn.pressed.connect(func():
		_close_detail_sheet()
		_retry_activity(type_code)
	)
	action_hbox.add_child(retry_btn)

	var close_btn := Button.new()
	close_btn.text = "Đóng"
	close_btn.custom_minimum_size = Vector2(100, 46)
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if _font_bold:
		close_btn.add_theme_font_override("font", _font_bold)
	_style_3d_button(close_btn, Color("#EDE7DC"), C_MUTED, 16, 3, Color("#DCD3C3"))
	close_btn.pressed.connect(_close_detail_sheet)
	action_hbox.add_child(close_btn)

	_modal_content.add_child(action_hbox)


func _retry_activity(type_code: String) -> void:
	match type_code:
		"QUIZ":
			get_tree().change_scene_to_file("res://scenes/LearningQuizScreen.tscn")
		"MINIGAME":
			get_tree().change_scene_to_file("res://scenes/RhythmChallengeScreen.tscn")
		_:
			get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _close_detail_sheet() -> void:
	var tw := create_tween()
	tw.tween_property(_modal_overlay, "modulate:a", 0.0, 0.15).set_trans(Tween.TRANS_SINE)
	tw.finished.connect(func():
		_modal_overlay.visible = false
	)


# ── Styling Helpers ─────────────────────────────────────────────────────────

func _style_3d_button(btn: Button, bg: Color, text_color: Color, radius: int = 16, border_depth: int = 4, border_color: Color = Color.TRANSPARENT) -> void:
	var border_b := border_color if border_color != Color.TRANSPARENT else Color(bg.r * 0.80, bg.g * 0.80, bg.b * 0.80, 1.0)

	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.set_corner_radius_all(radius)
	normal.border_width_bottom = border_depth
	normal.border_color = border_b
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = bg.lightened(0.06)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.border_width_bottom = 1
	pressed.content_margin_top = 11
	pressed.content_margin_bottom = 5

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	var focus := normal.duplicate() as StyleBoxFlat
	focus.set_border_width_all(2)
	focus.border_color = C_GOLD
	btn.add_theme_stylebox_override("focus", focus)
	btn.add_theme_color_override("font_color", text_color)
	btn.add_theme_color_override("font_hover_color", text_color)
	btn.add_theme_color_override("font_pressed_color", text_color)


func _style_3d_card(btn: Button, bg: Color, border_c: Color, radius: int = 20, border_depth: int = 5) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.set_corner_radius_all(radius)
	normal.set_border_width_all(2)
	normal.border_width_bottom = border_depth
	normal.border_color = border_c
	normal.shadow_color = Color(0, 0, 0, 0.06)
	normal.shadow_size = 8
	normal.shadow_offset = Vector2(0, 3)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(1.0, 1.0, 1.0, 0.95)
	hover.border_color = Color(0.70, 0.76, 0.84, 0.90)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.94, 0.94, 0.96, 0.90)
	pressed.border_width_bottom = 2
	pressed.border_width_top = 3

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	var focus := normal.duplicate() as StyleBoxFlat
	focus.set_border_width_all(2)
	focus.border_color = C_GOLD
	btn.add_theme_stylebox_override("focus", focus)


func _color_for_type(type_code: String) -> Color:
	match type_code:
		"QUIZ": return C_BLUE
		"MINIGAME": return C_GREEN
		"PRACTICE": return C_AMBER
		_: return C_PURPLE


func _bg_color_for_type(type_code: String) -> Color:
	match type_code:
		"QUIZ": return C_BLUE_BG
		"MINIGAME": return C_GREEN_BG
		"PRACTICE": return C_AMBER_BG
		_: return C_PURPLE_BG


func _icon_name_for_type(type_code: String) -> String:
	match type_code:
		"QUIZ": return "course"
		"MINIGAME": return "game"
		"PRACTICE": return "songs"
		_: return "menu"


func _icon_for_type(type_code: String) -> String:
	match type_code:
		"QUIZ": return "🎯"
		"MINIGAME": return "🥁"
		"PRACTICE": return "🎻"
		_: return "🎵"


func _type_name(type_code: String) -> String:
	match type_code:
		"QUIZ": return "Câu hỏi"
		"MINIGAME": return "Mini Game"
		"PRACTICE": return "Luyện tập"
		_: return "Hoạt động"


func _score_text(item: Dictionary) -> String:
	if item.get("score", null) == null:
		return "—"
	var sc_val: Variant = item.get("score")
	var max_val: Variant = item.get("maxScore", null)
	var sc_str := _clean_number_str(sc_val)
	if max_val != null:
		var max_str := _clean_number_str(max_val)
		return "%s/%s" % [sc_str, max_str]
	return sc_str


func _clean_number_str(val: Variant) -> String:
	if val is int:
		return str(val)
	var f := float(val)
	if is_equal_approx(f, roundf(f)):
		return str(int(roundf(f)))
	return "%.1f" % f


func _accuracy_text(item: Dictionary) -> String:
	if item.get("score", null) == null:
		return "—"
	var max_score := float(item.get("maxScore", 0.0))
	return "%d%%" % int(round((float(item.get("score", 0.0)) / max_score) * 100.0)) if max_score > 0.0 else "—"


func _activity_time_text(item: Dictionary) -> String:
	var started := str(item.get("startedAt", ""))
	var completed := str(item.get("completedAt", ""))
	if not started.is_empty() and not completed.is_empty():
		var duration := _parse_iso_to_unix(completed) - _parse_iso_to_unix(started)
		if duration > 0 and duration < 3600:
			return "%d phút" % maxi(1, int(round(float(duration) / 60.0)))
	return "—"


func _sync_status_text(item: Dictionary) -> String:
	match str(item.get("status", "")).to_upper():
		"PENDING_SYNC", "SYNCING": return "Chờ đồng bộ"
		"FAILED_SYNC", "SYNC_FAILED", "FAILED": return "Đồng bộ lỗi"
		"LOCAL_ONLY": return "Trên thiết bị"
		_: return "Đã đồng bộ"


func _sync_color(item: Dictionary) -> Color:
	match str(item.get("status", "")).to_upper():
		"PENDING_SYNC", "SYNCING": return C_AMBER
		"FAILED_SYNC", "SYNC_FAILED", "FAILED": return Color("#C2410C")
		"LOCAL_ONLY": return C_MUTED
		_: return C_GREEN


func _filter_label(value: String) -> String:
	return _type_name(value)


func _stars_display(value: int) -> String:
	return "★".repeat(clampi(value, 0, 3)) if value > 0 else "0 sao"


func _relative_time(value: String) -> String:
	if value.is_empty():
		return "—"
	return value.replace("T", " ").left(16)


func _duration_text(started: String, completed: String) -> String:
	return "%s → %s" % [_relative_time(started), _relative_time(completed)] if not started.is_empty() and not completed.is_empty() else "—"


func _extract_data(response: Dictionary) -> Dictionary:
	var body: Variant = response.get("body", {})
	return body.get("data", {}) as Dictionary if body is Dictionary else {}


func _clear(node: Node) -> void:
	for child: Node in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _is_mobile() -> bool:
	return get_viewport_rect().size.x < 640.0


func _is_compact_landscape() -> bool:
	return _is_compact_landscape_size(get_viewport_rect().size)


func _is_compact_landscape_size(viewport: Vector2) -> bool:
	return viewport.x >= viewport.y and viewport.y <= 430.0


func _horizontal_inset() -> int:
	var safe := DisplayServer.get_display_safe_area()
	var viewport := get_viewport_rect().size
	var safe_left := maxi(0, int(safe.position.x))
	var safe_right := maxi(0, int(viewport.x - (safe.position.x + safe.size.x)))
	return maxi(16 if _is_compact_landscape() else 24, maxi(safe_left, safe_right) + 8)


func _vertical_inset() -> int:
	var safe := DisplayServer.get_display_safe_area()
	var viewport := get_viewport_rect().size
	var safe_top := maxi(0, int(safe.position.y))
	var safe_bottom := maxi(0, int(viewport.y - (safe.position.y + safe.size.y)))
	return maxi(8 if _is_compact_landscape() else 16, maxi(safe_top, safe_bottom) + 6)


func _on_viewport_size_changed() -> void:
	if _root_margin != null:
		_root_margin.add_theme_constant_override("margin_left", _horizontal_inset())
		_root_margin.add_theme_constant_override("margin_right", _horizontal_inset())
		_root_margin.add_theme_constant_override("margin_top", _vertical_inset())
		_root_margin.add_theme_constant_override("margin_bottom", _vertical_inset())
	if not _last_rendered_items.is_empty() and not _loading:
		call_deferred("_render", _last_rendered_items)
