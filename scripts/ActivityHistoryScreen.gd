extends Control

const ApiClientScript = preload("res://scripts/ApiClient.gd")

# ── Palette: Royal Lacquer & Contemporary Duolingo/Simply Music Style ──────
const PAGE_SIZE := 20
const C_BG        := Color("#FAF8F5")
const C_CARD      := Color("#FFFFFF")
const C_JADE      := Color("#17452E")
const C_JADE_DARK := Color("#0F3020")
const C_GOLD      := Color("#C49526")
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
const C_MUTED     := Color("#6E6257")
const C_BORDER    := Color("#E5E0D3")
const C_SHADOW    := Color(0.12, 0.09, 0.05, 0.08)

var _api: Node
var _page := 0
var _total_pages := 0
var _filter := ""
var _loading := false
var _items: Array[Dictionary] = []

# Fonts
var _font_bold: Font
var _font_regular: Font
var _font_title: Font

# Node refs
var _title_lbl: Label
var _summary_lbl: Label
var _connection_banner: PanelContainer
var _connection_label: Label
var _list_container: VBoxContainer
var _load_more_btn: Button
var _filters_container: HBoxContainer
var _stats_container: HBoxContainer

# Bottom Sheet Modal refs
var _modal_overlay: Control
var _modal_card: PanelContainer
var _modal_content: VBoxContainer
var _active_modal_item: Dictionary = {}


func _ready() -> void:
	_api = ApiClientScript.new()
	add_child(_api)
	_load_fonts()
	_build_ui()
	_build_detail_sheet()

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
	if not _loading:
		call_deferred("refresh_history")


# ── UI Construction ──────────────────────────────────────────────────────────

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var is_mobile := _is_mobile()
	margin.add_theme_constant_override("margin_left", 16 if is_mobile else 32)
	margin.add_theme_constant_override("margin_right", 16 if is_mobile else 32)
	margin.add_theme_constant_override("margin_top", 16 if is_mobile else 24)
	margin.add_theme_constant_override("margin_bottom", 16 if is_mobile else 24)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10 if is_mobile else 12)
	margin.add_child(root)

	# 1. Top Bar Header
	root.add_child(_build_top_bar())

	# 2. Bento Quick Stats Strip
	_stats_container = HBoxContainer.new()
	_stats_container.add_theme_constant_override("separation", 10 if is_mobile else 14)
	_stats_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(_stats_container)
	_render_stats_strip(0, 0, 0, 0)

	# 3. Filter Segmented Pills. Keep one row and allow a short horizontal swipe.
	var filters_scroll := ScrollContainer.new()
	filters_scroll.custom_minimum_size = Vector2(0, 44)
	filters_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	filters_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	filters_scroll.scroll_deadzone = 8
	root.add_child(filters_scroll)
	_filters_container = HBoxContainer.new()
	_filters_container.add_theme_constant_override("separation", 8)
	filters_scroll.add_child(_filters_container)
	_render_filter_pills()

	# 4. Offline banner
	_connection_banner = PanelContainer.new()
	_connection_banner.visible = false
	_connection_banner.custom_minimum_size = Vector2(0, 48)
	var banner_style := StyleBoxFlat.new()
	banner_style.bg_color = C_AMBER_BG
	banner_style.border_color = Color(C_AMBER.r, C_AMBER.g, C_AMBER.b, 0.35)
	banner_style.set_border_width_all(1)
	banner_style.set_corner_radius_all(14)
	banner_style.content_margin_left = 14
	banner_style.content_margin_right = 6
	banner_style.content_margin_top = 4
	banner_style.content_margin_bottom = 4
	_connection_banner.add_theme_stylebox_override("panel", banner_style)
	var banner_row := HBoxContainer.new()
	banner_row.add_theme_constant_override("separation", 10)
	_connection_banner.add_child(banner_row)
	_connection_label = Label.new()
	_connection_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_connection_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_connection_label.add_theme_font_size_override("font_size", 13)
	_connection_label.add_theme_color_override("font_color", C_TEXT)
	if _font_regular:
		_connection_label.add_theme_font_override("font", _font_regular)
	banner_row.add_child(_connection_label)
	var retry_connection_btn := Button.new()
	retry_connection_btn.text = "Thử lại"
	retry_connection_btn.custom_minimum_size = Vector2(84, 40)
	retry_connection_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if _font_bold:
		retry_connection_btn.add_theme_font_override("font", _font_bold)
	_style_3d_button(retry_connection_btn, C_AMBER, Color.WHITE, 14, 2)
	retry_connection_btn.pressed.connect(func(): refresh_history())
	banner_row.add_child(retry_connection_btn)
	root.add_child(_connection_banner)

	# 5. Scrollable Activity Stream
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	var list_center := CenterContainer.new()
	list_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list_center)
	_list_container = VBoxContainer.new()
	_list_container.custom_minimum_size = Vector2(_content_width(), 0)
	_list_container.add_theme_constant_override("separation", 12)
	list_center.add_child(_list_container)

	# 6. Load More Button
	_load_more_btn = Button.new()
	_load_more_btn.text = "Tải thêm hoạt động cũ hơn  ▼"
	_load_more_btn.custom_minimum_size = Vector2(0, 48)
	_load_more_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_load_more_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_3d_button(_load_more_btn, Color("#F5F1E8"), C_JADE, 16, 3)
	_load_more_btn.pressed.connect(_load_next_page)
	_load_more_btn.visible = false
	root.add_child(_load_more_btn)


func _build_top_bar() -> HBoxContainer:
	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 14)

	# 3D Back Button
	var back_btn := Button.new()
	back_btn.text = "‹"
	back_btn.tooltip_text = "Quay lại tài khoản"
	back_btn.custom_minimum_size = Vector2(46, 46)
	back_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	back_btn.add_theme_font_size_override("font_size", 28)
	if _font_bold:
		back_btn.add_theme_font_override("font", _font_bold)
	_style_3d_button(back_btn, Color.WHITE, C_JADE, 23, 4)
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/AccountScreen.tscn"))
	top_bar.add_child(back_btn)

	# Title block
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 2)
	top_bar.add_child(title_box)

	_title_lbl = Label.new()
	_title_lbl.text = "LỊCH SỬ HOẠT ĐỘNG"
	_title_lbl.add_theme_font_size_override("font_size", 20 if _is_mobile() else 24)
	_title_lbl.add_theme_color_override("font_color", C_JADE)
	if _font_title:
		_title_lbl.add_theme_font_override("font", _font_title)
	title_box.add_child(_title_lbl)

	_summary_lbl = Label.new()
	_summary_lbl.text = "Đang tải dữ liệu luyện tập..."
	_summary_lbl.add_theme_font_size_override("font_size", 13)
	_summary_lbl.add_theme_color_override("font_color", C_MUTED)
	if _font_regular:
		_summary_lbl.add_theme_font_override("font", _font_regular)
	title_box.add_child(_summary_lbl)

	# Refresh 3D Button
	var refresh_btn := Button.new()
	refresh_btn.text = "↻"
	refresh_btn.tooltip_text = "Làm mới lịch sử"
	refresh_btn.custom_minimum_size = Vector2(46, 46)
	refresh_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	refresh_btn.add_theme_font_size_override("font_size", 22)
	if _font_bold:
		refresh_btn.add_theme_font_override("font", _font_bold)
	_style_3d_button(refresh_btn, Color.WHITE, C_JADE, 23, 4)
	refresh_btn.pressed.connect(func(): refresh_history())
	top_bar.add_child(refresh_btn)

	return top_bar


# ── Bento Stats Strip (Quick KPI Header) ───────────────────────────────────

func _render_stats_strip(total_xp: int, avg_accuracy: int, total_stars: int, total_count: int) -> void:
	_clear(_stats_container)

	# Four compact, equal cards are deliberately retained in landscape.
	_stats_container.add_child(_make_bento_item("⚡", "%d" % total_xp, "Tổng XP", C_BLUE, C_BLUE_BG))
	_stats_container.add_child(_make_bento_item("🎯", "%d%%" % avg_accuracy if avg_accuracy > 0 else "—", "Độ chính xác", C_GREEN, C_GREEN_BG))
	_stats_container.add_child(_make_bento_item("★", "%d" % total_stars, "Tổng sao", C_GOLD, C_GOLD_BG))
	_stats_container.add_child(_make_bento_item("📚", "%d" % total_count, "Bài hoàn thành", C_PURPLE, C_PURPLE_BG))


func _make_bento_item(icon: String, val_text: String, label_text: String, accent_color: Color, bg_color: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.custom_minimum_size = Vector2(0, 62)

	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.set_corner_radius_all(16)
	style.set_border_width_all(1)
	style.border_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.25)
	style.border_width_bottom = 4
	style.shadow_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.08)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 2)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	p.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(hbox)

	# Icon Badge
	var icon_panel := PanelContainer.new()
	icon_panel.custom_minimum_size = Vector2(34, 34)
	var icon_style := StyleBoxFlat.new()
	icon_style.bg_color = bg_color
	icon_style.set_corner_radius_all(17)
	icon_panel.add_theme_stylebox_override("panel", icon_style)
	var icon_lbl := Label.new()
	icon_lbl.text = icon
	icon_lbl.add_theme_font_size_override("font_size", 18)
	icon_lbl.add_theme_color_override("font_color", accent_color)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_panel.add_child(icon_lbl)
	hbox.add_child(icon_panel)

	# Texts
	var text_vbox := VBoxContainer.new()
	text_vbox.add_theme_constant_override("separation", 0)
	text_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(text_vbox)

	var val_lbl := Label.new()
	val_lbl.text = val_text
	val_lbl.add_theme_font_size_override("font_size", 15)
	val_lbl.add_theme_color_override("font_color", C_TEXT)
	if _font_bold:
		val_lbl.add_theme_font_override("font", _font_bold)
	text_vbox.add_child(val_lbl)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", C_MUTED)
	if _font_regular:
		lbl.add_theme_font_override("font", _font_regular)
	text_vbox.add_child(lbl)

	return p


# ── Filter Segmented Pills ─────────────────────────────────────────────────

func _render_filter_pills() -> void:
	_clear(_filters_container)
	var filter_options := [
		{"label": "Tất cả", "value": "", "icon": "★"},
		{"label": "Câu hỏi", "value": "QUIZ", "icon": "🎯"},
		{"label": "Nhịp điệu", "value": "MINIGAME", "icon": "🥁"},
		{"label": "Luyện tập", "value": "PRACTICE", "icon": "🎻"}
	]

	for opt: Dictionary in filter_options:
		var val := str(opt["value"])
		var is_active := val == _filter
		var btn := Button.new()
		btn.text = "%s  %s" % [str(opt["icon"]), str(opt["label"])]
		btn.toggle_mode = true
		btn.button_pressed = is_active
		btn.custom_minimum_size = Vector2(0, 40)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.add_theme_font_size_override("font_size", 13)
		if _font_bold:
			btn.add_theme_font_override("font", _font_bold)

		if is_active:
			_style_3d_button(btn, C_JADE, Color.WHITE, 20, 3, C_JADE_DARK)
		else:
			_style_3d_button(btn, Color("#F2EDE2"), C_MUTED, 20, 2, Color("#DCD5C5"))

		btn.pressed.connect(_set_filter.bind(val))
		_filters_container.add_child(btn)


func _set_filter(value: String) -> void:
	_filter = value
	_render_filter_pills()
	await refresh_history()


# ── Data Fetching & State ──────────────────────────────────────────────────

func refresh_history() -> void:
	if _loading:
		return
	_loading = true
	_page = 0
	_items.clear()
	_connection_banner.visible = false

	var backend_report := get_node_or_null("/root/BackendReport")
	if backend_report != null and backend_report.has_method("retry_pending_game_attempts"):
		await backend_report.retry_pending_game_attempts()

	await _fetch_page(true)
	_loading = false


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
		_connection_label.text = "Chưa có kết nối — dữ liệu sẽ tự đồng bộ khi có mạng"
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
	_connection_banner.visible = false
	_render(merge_pending_items(_items))


func merge_pending_items(confirmed: Array) -> Array:
	var merged: Array = []
	for pending: Variant in SecureDataManager.get_pending_game_attempts():
		if pending is Dictionary:
			var item := _map_pending(pending as Dictionary)
			if _filter.is_empty() or item.get("type") == _filter:
				merged.append(item)
	for item: Variant in confirmed:
		if item is Dictionary:
			merged.append(item as Dictionary)
	return merged


func _map_pending(pending: Dictionary) -> Dictionary:
	var kind := str(pending.get("kind", "minigame")).to_lower()
	var activity_type := "QUIZ" if kind == "quiz" else "MINIGAME"
	var completed_at := str(pending.get("completed_at", pending.get("started_at", "")))
	return {
		"eventId": "PENDING:" + str(pending.get("client_attempt_id", "local")),
		"type": activity_type,
		"title": "Câu hỏi đang chờ đồng bộ" if activity_type == "QUIZ" else "Mini Game đang chờ đồng bộ",
		"lessonTitle": "Chưa xác nhận từ máy chủ",
		"score": pending.get("score", null),
		"completedAt": completed_at,
		"status": "PENDING_SYNC",
		"pendingPayload": pending
	}


# ── Render Stream & Timeline Groups ─────────────────────────────────────────

func _render(items: Array) -> void:
	_clear(_list_container)

	# Calculate Stats
	var total_xp := 0
	var total_stars := 0
	var accuracy_sum := 0.0
	var accuracy_count := 0
	for item_val: Variant in items:
		if not item_val is Dictionary:
			continue
		var item: Dictionary = item_val
		total_xp += int(item.get("pointsEarned", 0))
		total_stars += int(item.get("starsEarned", 0))
		if item.has("score") and item.get("score") != null:
			var sc = float(item.get("score", 0.0))
			var m_sc = float(item.get("maxScore", 100.0))
			if m_sc > 0:
				accuracy_sum += (sc / m_sc) * 100.0
				accuracy_count += 1

	var avg_acc := int(round(accuracy_sum / float(maxi(1, accuracy_count)))) if accuracy_count > 0 else 0
	_render_stats_strip(total_xp, avg_acc, total_stars, items.size())

	var pending_count := maxi(items.size() - _items.size(), 0)
	_summary_lbl.text = "%d hoạt động đã ghi nhận%s" % [
		_items.size(),
		" · %d đang chờ đồng bộ" % pending_count if pending_count > 0 else ""
	]

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

		# Section Header
		var section_lbl := Label.new()
		section_lbl.text = group_title.to_upper()
		section_lbl.add_theme_font_size_override("font_size", 12)
		section_lbl.add_theme_color_override("font_color", C_MUTED)
		if _font_bold:
			section_lbl.add_theme_font_override("font", _font_bold)
		_list_container.add_child(section_lbl)

		# Render cards in this section
		for item_val: Variant in group_items:
			if item_val is Dictionary:
				_list_container.add_child(_make_3d_activity_card(item_val as Dictionary))

	_load_more_btn.visible = _total_pages > 0 and _page + 1 < _total_pages


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
		if date_str.is_empty() or str(item.get("status", "")) == "PENDING_SYNC":
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


# ── 3D Activity Card (Duolingo Style) ───────────────────────────────────────

func _make_3d_activity_card(item: Dictionary) -> Button:
	var type_code := str(item.get("type", "PRACTICE")).to_upper()
	var accent := _color_for_type(type_code)
	var bg_accent := _bg_color_for_type(type_code)

	var card := Button.new()
	card.custom_minimum_size = Vector2(0, 94)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	# 3D Card Styling
	_style_3d_card(card, Color.WHITE, C_BORDER, 20, 4)

	# Content layout
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 12)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(hbox)

	# 1. Left Round Icon Box
	var icon_panel := PanelContainer.new()
	icon_panel.custom_minimum_size = Vector2(48, 48)
	icon_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var icon_box_style := StyleBoxFlat.new()
	icon_box_style.bg_color = bg_accent
	icon_box_style.set_corner_radius_all(24)
	icon_box_style.set_border_width_all(1)
	icon_box_style.border_color = Color(accent.r, accent.g, accent.b, 0.4)
	icon_panel.add_theme_stylebox_override("panel", icon_box_style)

	var icon_lbl := Label.new()
	icon_lbl.text = _icon_for_type(type_code)
	icon_lbl.add_theme_font_size_override("font_size", 22)
	icon_lbl.add_theme_color_override("font_color", accent)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_panel.add_child(icon_lbl)
	hbox.add_child(icon_panel)

	# 2. Name and mode. It is kept compact so the result columns remain readable.
	var content_vbox := VBoxContainer.new()
	content_vbox.custom_minimum_size = Vector2(260, 0)
	content_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	content_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(content_vbox)

	# Title Row
	var title_lbl := Label.new()
	title_lbl.text = str(item.get("title", item.get("lessonTitle", "Hoạt động")))
	title_lbl.add_theme_font_size_override("font_size", 15)
	title_lbl.add_theme_color_override("font_color", C_JADE)
	title_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if _font_bold:
		title_lbl.add_theme_font_override("font", _font_bold)
	content_vbox.add_child(title_lbl)

	# Subtitle Row: type and lesson / mini-game context.
	var sub_hbox := HBoxContainer.new()
	sub_hbox.add_theme_constant_override("separation", 6)
	content_vbox.add_child(sub_hbox)

	var type_pill := Label.new()
	type_pill.text = _type_name(type_code)
	type_pill.add_theme_font_size_override("font_size", 12)
	type_pill.add_theme_color_override("font_color", accent)
	if _font_bold:
		type_pill.add_theme_font_override("font", _font_bold)
	sub_hbox.add_child(type_pill)

	var lesson_lbl := Label.new()
	lesson_lbl.text = str(item.get("lessonTitle", ""))
	lesson_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lesson_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	lesson_lbl.add_theme_font_size_override("font_size", 12)
	lesson_lbl.add_theme_color_override("font_color", C_MUTED)
	if _font_regular:
		lesson_lbl.add_theme_font_override("font", _font_regular)
	sub_hbox.add_child(lesson_lbl)

	# 3. Landscape result columns: score, accuracy, time, and sync state.
	var metrics := HBoxContainer.new()
	metrics.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	metrics.add_theme_constant_override("separation", 8)
	metrics.alignment = BoxContainer.ALIGNMENT_END
	hbox.add_child(metrics)
	metrics.add_child(_make_activity_metric("Điểm số", _score_text(item), C_BLUE, 100))
	metrics.add_child(_make_activity_metric("Độ chính xác", _accuracy_text(item), C_GREEN, 112))
	metrics.add_child(_make_activity_metric("Thời gian", _activity_time_text(item), C_MUTED, 120))
	var is_pending := str(item.get("status", "")) == "PENDING_SYNC"
	metrics.add_child(_make_activity_metric("Đồng bộ", _sync_status_text(item), C_AMBER if is_pending else C_GREEN, 118))

	# Chevron
	var chevron := Label.new()
	chevron.text = "›"
	chevron.add_theme_font_size_override("font_size", 22)
	chevron.add_theme_color_override("font_color", Color("#cbd5e1"))
	hbox.add_child(chevron)

	card.pressed.connect(_open_detail.bind(item))
	return card


func _format_card_subtitle(item: Dictionary) -> String:
	var score_str := _score_text(item)
	var time_str := _relative_time(str(item.get("completedAt", item.get("startedAt", ""))))
	if not score_str.is_empty():
		return "%s · %s" % [score_str, time_str]
	return time_str


func _make_activity_metric(label_text: String, value_text: String, value_color: Color, width: float) -> VBoxContainer:
	var metric := VBoxContainer.new()
	metric.custom_minimum_size = Vector2(width, 0)
	metric.alignment = BoxContainer.ALIGNMENT_CENTER
	metric.add_theme_constant_override("separation", 1)

	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", C_MUTED)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	metric.add_child(label)

	var value := Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 12)
	value.add_theme_color_override("font_color", value_color)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if _font_bold:
		value.add_theme_font_override("font", _font_bold)
	metric.add_child(value)
	return metric


func _build_empty_state() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 132)
	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.set_corner_radius_all(20)
	style.border_color = C_BORDER
	style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var icon := Label.new()
	icon.text = "🎵"
	icon.add_theme_font_size_override("font_size", 30)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(icon)

	var title := Label.new()
	title.text = "Chưa có hoạt động phù hợp"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", C_JADE)
	if _font_bold:
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

	return panel


# ── Modern Bottom Sheet Detail View ──────────────────────────────────────────

func _build_detail_sheet() -> void:
	_modal_overlay = Control.new()
	_modal_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_overlay.visible = false
	_modal_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_modal_overlay)

	# Dark Scrim
	var scrim := ColorRect.new()
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(0, 0, 0, 0.45)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal_overlay.add_child(scrim)
	scrim.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_close_detail_sheet()
	)

	# Sheet Container Card
	_modal_card = PanelContainer.new()
	_modal_card.custom_minimum_size = Vector2(minf(680.0, get_viewport_rect().size.x - 32.0), 0)
	_modal_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_modal_card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_modal_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

	var sheet_style := StyleBoxFlat.new()
	sheet_style.bg_color = Color.WHITE
	sheet_style.set_corner_radius_all(24)
	sheet_style.shadow_color = Color(0, 0, 0, 0.20)
	sheet_style.shadow_size = 24
	sheet_style.shadow_offset = Vector2(0, 8)
	sheet_style.content_margin_left = 24
	sheet_style.content_margin_right = 24
	sheet_style.content_margin_top = 22
	sheet_style.content_margin_bottom = 22
	_modal_card.add_theme_stylebox_override("panel", sheet_style)
	_modal_overlay.add_child(_modal_card)

	_modal_content = VBoxContainer.new()
	_modal_content.add_theme_constant_override("separation", 14)
	_modal_card.add_child(_modal_content)


func _open_detail(item: Dictionary) -> void:
	_active_modal_item = item
	_clear(_modal_content)
	_modal_overlay.visible = true
	_modal_overlay.modulate.a = 0.0

	var tw := create_tween()
	tw.tween_property(_modal_overlay, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_SINE)

	var type_code := str(item.get("type", "PRACTICE")).to_upper()
	var accent := _color_for_type(type_code)

	# Header with Close Button
	var header_hbox := HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 12)
	_modal_content.add_child(header_hbox)

	var title_vbox := VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_vbox.add_theme_constant_override("separation", 2)
	header_hbox.add_child(title_vbox)

	var act_type := Label.new()
	act_type.text = "%s %s" % [_icon_for_type(type_code), _type_name(type_code).to_upper()]
	act_type.add_theme_font_size_override("font_size", 12)
	act_type.add_theme_color_override("font_color", accent)
	if _font_bold:
		act_type.add_theme_font_override("font", _font_bold)
	title_vbox.add_child(act_type)

	var title_lbl := Label.new()
	title_lbl.text = str(item.get("title", "Chi tiết hoạt động"))
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", C_JADE)
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if _font_bold:
		title_lbl.add_theme_font_override("font", _font_bold)
	title_vbox.add_child(title_lbl)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(38, 38)
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_3d_button(close_btn, Color("#F5F1E8"), C_MUTED, 19, 2)
	close_btn.pressed.connect(_close_detail_sheet)
	header_hbox.add_child(close_btn)

	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 1)
	divider.color = C_BORDER
	_modal_content.add_child(divider)

	# Content loading state
	if str(item.get("status", "")) == "PENDING_SYNC":
		_add_modal_row("Trạng thái", "Chờ đồng bộ lên máy chủ. Phần thưởng sẽ được ghi nhận khi có kết nối.", C_AMBER)
		if item.has("score") and item.get("score") != null:
			_add_modal_row("Điểm số tạm tính", str(item.get("score")), C_TEXT)
		_add_modal_actions(item)
		return

	var loading_row := Label.new()
	loading_row.text = "Đang tải chi tiết từ máy chủ..."
	loading_row.add_theme_color_override("font_color", C_MUTED)
	_modal_content.add_child(loading_row)

	var response: Dictionary = await _api.get_activity_history_detail(str(item.get("eventId", "")))
	_clear(_modal_content)
	_modal_content.add_child(header_hbox)
	_modal_content.add_child(divider)

	if not _api._is_success(response):
		_add_modal_row("Thông báo", "Không thể lấy thêm chi tiết trực tuyến. Bạn vẫn có thể xem lại kết quả đã lưu.", C_MUTED)
		_add_modal_actions(item)
		return

	var detail := _extract_data(response)
	_add_modal_row("Bài học", str(detail.get("lessonTitle", "—")), C_TEXT)
	_add_modal_row("Kết quả", "%s  ·  %s  ·  +%d XP" % [
		_score_text(detail),
		_stars_display(int(detail.get("starsEarned", 0))),
		int(detail.get("pointsEarned", 0))
	], accent)

	if type_code == "QUIZ":
		if detail.has("question") and not str(detail.get("question", "")).is_empty():
			_add_modal_row("Câu hỏi", str(detail.get("question", "")), C_TEXT)
		_add_modal_row("Bạn đã chọn", str(detail.get("selectedAnswer", "—")), C_BLUE)
		if detail.has("correctAnswer"):
			_add_modal_row("Đáp án chính xác", str(detail.get("correctAnswer", "—")), C_GREEN)
	elif type_code == "MINIGAME":
		if detail.has("challengeType"):
			_add_modal_row("Loại thử thách", str(detail.get("challengeType", "—")), C_TEXT)
		_add_modal_row("Thời gian thực hiện", _duration_text(str(detail.get("startedAt", "")), str(detail.get("completedAt", ""))), C_MUTED)
	else:
		_add_modal_row("Điểm cao độ (Pitch)", str(detail.get("pitchScore", "—")), C_GREEN)
		_add_modal_row("Điểm nhịp điệu (Rhythm)", str(detail.get("rhythmScore", "—")), C_BLUE)
		_add_modal_row("Điểm sắc thái (Dynamics)", str(detail.get("dynamicsScore", "—")), C_PURPLE)

	_add_modal_actions(item)


func _add_modal_row(label_text: String, value_text: String, val_color: Color) -> void:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 1)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", C_MUTED)
	if _font_regular:
		lbl.add_theme_font_override("font", _font_regular)
	row.add_child(lbl)

	var val := Label.new()
	val.text = value_text
	val.add_theme_font_size_override("font_size", 14)
	val.add_theme_color_override("font_color", val_color)
	val.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if _font_bold:
		val.add_theme_font_override("font", _font_bold)
	row.add_child(val)

	_modal_content.add_child(row)


func _add_modal_actions(item: Dictionary) -> void:
	var action_hbox := HBoxContainer.new()
	action_hbox.add_theme_constant_override("separation", 10)
	action_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var type_code := str(item.get("type", "PRACTICE")).to_upper()
	var retry_btn := Button.new()
	retry_btn.text = "Luyện tập lại bài này  →"
	retry_btn.custom_minimum_size = Vector2(0, 48)
	retry_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	retry_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_3d_button(retry_btn, C_JADE, Color.WHITE, 16, 4, C_JADE_DARK)
	retry_btn.pressed.connect(func():
		_close_detail_sheet()
		_retry_activity(type_code)
	)
	action_hbox.add_child(retry_btn)

	var close_btn := Button.new()
	close_btn.text = "Đóng"
	close_btn.custom_minimum_size = Vector2(100, 48)
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_3d_button(close_btn, Color("#F5F1E8"), C_MUTED, 16, 3)
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
	var border_b := border_color if border_color != Color.TRANSPARENT else Color(bg.r * 0.82, bg.g * 0.82, bg.b * 0.82, 1.0)

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
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_color_override("font_color", text_color)
	btn.add_theme_color_override("font_hover_color", text_color)
	btn.add_theme_color_override("font_pressed_color", text_color)


func _style_3d_card(btn: Button, bg: Color, border_c: Color, radius: int = 18, border_depth: int = 4) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.set_corner_radius_all(radius)
	normal.set_border_width_all(1)
	normal.border_color = border_c
	normal.border_width_bottom = border_depth
	normal.border_color = Color(0.85, 0.82, 0.76)
	normal.shadow_color = C_SHADOW
	normal.shadow_size = 6
	normal.shadow_offset = Vector2(0, 2)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(1.0, 0.99, 0.97)
	hover.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.6)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.97, 0.95, 0.91)
	pressed.border_width_bottom = 1
	pressed.border_width_top = 2

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


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
		return ""
	var max_score: Variant = item.get("maxScore", null)
	return "%s/%s điểm" % [str(item.get("score")), str(max_score)] if max_score != null else "%s điểm" % str(item.get("score"))


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
	return _relative_time(completed if not completed.is_empty() else started)


func _sync_status_text(item: Dictionary) -> String:
	return "Chờ đồng bộ" if str(item.get("status", "")) == "PENDING_SYNC" else "Đã đồng bộ"


func _filter_label(value: String) -> String:
	return _type_name(value)


func _stars_display(value: int) -> String:
	return "★".repeat(clampi(value, 0, 3)) if value > 0 else "0 sao"


func _relative_time(value: String) -> String:
	if value.is_empty():
		return "Đang chờ đồng bộ"
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


func _content_width() -> float:
	var available := get_viewport_rect().size.x - (32.0 if _is_mobile() else 64.0)
	return clampf(available, 0.0, 1360.0)
