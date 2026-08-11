extends Control

const ApiClientScript = preload("res://scripts/ApiClient.gd")

# Warm Cream + Jade + Gold (synced with DS.gd)
const C_BG_WARM := Color("#FAF8F5")       # cream page background
const C_CARD_BG := Color("#FFFDF8")       # elevated cream card
const C_BORDER := Color("#E5DFD3")        # warm hairline border
const C_TEXT_MAIN := Color("#21140D")     # warm charcoal text
const C_TEXT_MUTED := Color("#6F6257")    # muted warm text

const C_GOLD := Color("#C59626")
const C_JADE := Color("#173F2D")
const C_INK := Color("#261A13")
const C_MUTED := Color("#75685E")
const C_RED := Color("#A63D32")
const C_GREEN := Color("#2F8A55")

# Spot pastels for status
const C_PASTEL_GREEN_BG := Color("#EDF3EC")
const C_PASTEL_GREEN_TXT := Color("#346538")
const C_PASTEL_RED_BG := Color("#FDEBEC")
const C_PASTEL_RED_TXT := Color("#9F2F2D")

# Format: [key, title, icon_name, icon_color, pastel_bg_color]
const INFO_FIELDS := [
	["email", "Email", "mail", Color("#1F6C9F"), Color("#E1F3FE")],
	["userCode", "Mã tài khoản", "hash", Color("#956400"), Color("#FBF3DB")],
	["id", "ID hệ thống", "user", Color("#5C5870"), Color("#F1F0F5")],
	["createdAt", "Ngày tham gia", "calendar-days", Color("#4B617D"), Color("#EAEFF5")],
]

const STAT_FIELDS := [
	["total_points", "Điểm", "sparkles", Color("#956400"), Color("#FBF3DB")],
	["total_stars", "Sao", "star", Color("#956400"), Color("#FBF3DB")],
	["completed_lessons", "Bài học", "graduation-cap", Color("#346538"), Color("#EDF3EC")],
	["current_streak", "Chuỗi hiện tại", "flame", Color("#9F2F2D"), Color("#FDEBEC")],
	["longest_streak", "Kỷ lục", "trophy", Color("#956400"), Color("#FBF3DB")],
	["adaptive_difficulty", "Độ khó", "gauge", Color("#1F6C9F"), Color("#E1F3FE")],
]

@onready var back_button: Button = $FloatingMargin/BackButton
@onready var title_label: Label = $Root/ContentMargin/Scroll/Center/Content/Title
@onready var content_margin: MarginContainer = $Root/ContentMargin
@onready var content: VBoxContainer = $Root/ContentMargin/Scroll/Center/Content
@onready var state_card: PanelContainer = $Root/ContentMargin/Scroll/Center/Content/StateCard
@onready var state_icon: TextureRect = $Root/ContentMargin/Scroll/Center/Content/StateCard/StateMargin/StateRow/StateIcon
@onready var state_label: Label = $Root/ContentMargin/Scroll/Center/Content/StateCard/StateMargin/StateRow/StateLabel
@onready var retry_button: Button = $Root/ContentMargin/Scroll/Center/Content/StateCard/StateMargin/StateRow/RetryButton
@onready var profile_card: PanelContainer = $Root/ContentMargin/Scroll/Center/Content/ProfileCard
@onready var card_margin: MarginContainer = $Root/ContentMargin/Scroll/Center/Content/ProfileCard/CardMargin
@onready var hero: BoxContainer = $Root/ContentMargin/Scroll/Center/Content/ProfileCard/CardMargin/Card/Hero
@onready var avatar_frame: PanelContainer = $Root/ContentMargin/Scroll/Center/Content/ProfileCard/CardMargin/Card/Hero/AvatarFrame
@onready var avatar: TextureRect = $Root/ContentMargin/Scroll/Center/Content/ProfileCard/CardMargin/Card/Hero/AvatarFrame/Avatar
@onready var identity: VBoxContainer = $Root/ContentMargin/Scroll/Center/Content/ProfileCard/CardMargin/Card/Hero/Identity
@onready var status_pill: PanelContainer = $Root/ContentMargin/Scroll/Center/Content/ProfileCard/CardMargin/Card/Hero/Identity/StatusPill
@onready var status_dot: ColorRect = $Root/ContentMargin/Scroll/Center/Content/ProfileCard/CardMargin/Card/Hero/Identity/StatusPill/StatusMargin/StatusRow/StatusDot
@onready var status_label: Label = $Root/ContentMargin/Scroll/Center/Content/ProfileCard/CardMargin/Card/Hero/Identity/StatusPill/StatusMargin/StatusRow/StatusLabel
@onready var name_label: Label = $Root/ContentMargin/Scroll/Center/Content/ProfileCard/CardMargin/Card/Hero/Identity/Name
@onready var role_label: Label = $Root/ContentMargin/Scroll/Center/Content/ProfileCard/CardMargin/Card/Hero/Identity/Role
@onready var account_title: Label = $Root/ContentMargin/Scroll/Center/Content/ProfileCard/CardMargin/Card/AccountTitle
@onready var learning_title: Label = $Root/ContentMargin/Scroll/Center/Content/ProfileCard/CardMargin/Card/LearningTitle
@onready var info_grid: GridContainer = $Root/ContentMargin/Scroll/Center/Content/ProfileCard/CardMargin/Card/InfoGrid
@onready var stats_grid: GridContainer = $Root/ContentMargin/Scroll/Center/Content/ProfileCard/CardMargin/Card/StatsGrid
@onready var progress_state: Label = $Root/ContentMargin/Scroll/Center/Content/ProfileCard/CardMargin/Card/ProgressState
@onready var avatar_request: HTTPRequest = $AvatarRequest

var _api_client: Node
var _profile: Dictionary = {}
var _loading := false


func _ready() -> void:
	_api_client = ApiClientScript.new()
	add_child(_api_client)
	_build_theme()
	back_button.pressed.connect(_go_back)
	retry_button.pressed.connect(_refresh_from_api)
	avatar_request.request_completed.connect(_on_avatar_loaded)
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	
	# Bouncy hover/press micro-interactions for the floating back button
	back_button.pivot_offset = Vector2(40, 40)
	back_button.mouse_entered.connect(func() -> void:
		create_tween().tween_property(back_button, "scale", Vector2(1.15, 1.15), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	back_button.mouse_exited.connect(func() -> void:
		create_tween().tween_property(back_button, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	back_button.button_down.connect(func() -> void:
		create_tween().tween_property(back_button, "scale", Vector2(0.9, 0.9), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	back_button.button_up.connect(func() -> void:
		var tgt := Vector2(1.15, 1.15) if back_button.is_hovered() else Vector2.ONE
		create_tween().tween_property(back_button, "scale", tgt, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	
	call_deferred("_refresh_from_api")


func _refresh_from_api() -> void:
	if _loading:
		return
	_loading = true
	profile_card.visible = false
	_show_state("hourglass", "Đang tải hồ sơ...", false)

	var profile_response: Dictionary = await _api_client.get_me()
	if not _api_client._is_success(profile_response):
		_finish_loading()
		_show_state("rotate-cw", _response_message(profile_response, "Không thể tải hồ sơ."), true)
		return

	_profile = _extract_data(profile_response)
	_render_profile()
	state_card.visible = false
	profile_card.visible = true
	progress_state.text = "Đang tải chỉ số học tập..."
	progress_state.visible = true
	stats_grid.visible = false
	_animate_profile()

	var summary_response: Dictionary = await _api_client.get_my_progress_summary()
	if _api_client._is_success(summary_response):
		_render_summary(_extract_data(summary_response))
	else:
		stats_grid.visible = false
		progress_state.text = _response_message(summary_response, "Chưa thể tải chỉ số học tập. Hãy thử làm mới.")
		progress_state.add_theme_color_override("font_color", C_RED)
		progress_state.visible = true
	_finish_loading()


func _finish_loading() -> void:
	_loading = false


func _render_profile() -> void:
	name_label.text = _value_or_dash(_profile.get("fullName"))
	role_label.text = _role_name(str(_profile.get("role", "")))
	var active: bool = bool(_profile.get("active", false))
	status_label.text = "Hoạt động" if active else "Tạm khóa"
	
	var status_bg := C_PASTEL_GREEN_BG if active else C_PASTEL_RED_BG
	var status_fg := C_PASTEL_GREEN_TXT if active else C_PASTEL_RED_TXT
	status_dot.color = status_fg
	status_label.add_theme_color_override("font_color", status_fg)
	status_pill.add_theme_stylebox_override("panel", _flat(status_bg, C_BORDER, 14, 1))

	_clear_children(info_grid)
	for field: Array in INFO_FIELDS:
		var value := _format_profile_value(str(field[0]), _profile.get(field[0]))
		info_grid.add_child(_make_data_card(value, str(field[1]), str(field[2]), field[3], field[4], false))

	avatar.texture = load("res://assets/textures/default_avatar.png") as Texture2D
	var avatar_url := str(_profile.get("avatarUrl", "")).strip_edges()
	if _is_web_url(avatar_url):
		avatar_request.cancel_request()
		avatar_request.request(avatar_url)


func _render_summary(summary: Dictionary) -> void:
	_clear_children(stats_grid)
	for field: Array in STAT_FIELDS:
		var raw_value: Variant = summary.get(field[0], null)
		var value := "—" if raw_value == null else _format_number(int(raw_value))
		if field[0] == "adaptive_difficulty" and raw_value == null:
			# FE adaptive difficulty from the last 10 local attempts (0 = chưa đủ dữ liệu)
			var local_diff := SecureDataManager.get_adaptive_difficulty()
			value = "Chưa có" if local_diff == 0 else ("Cao" if local_diff >= 3 else ("Trung bình" if local_diff == 2 else "Thấp"))
		stats_grid.add_child(_make_data_card(value, str(field[1]), str(field[2]), field[3], field[4], true))
	progress_state.visible = false
	stats_grid.visible = true


func _make_data_card(value: String, caption: String, icon_name: String, accent: Color, bg_pastel: Color, compact: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 92 if compact else 96)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _data_card_style(accent))
	var margin := MarginContainer.new()
	for side: String in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	for side: String in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	margin.add_child(row)
	var icon_wrap := PanelContainer.new()
	icon_wrap.custom_minimum_size = Vector2(46, 46)
	icon_wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_wrap.add_theme_stylebox_override("panel", _flat(bg_pastel, Color.TRANSPARENT, 12, 0))
	row.add_child(icon_wrap)
	var icon := TextureRect.new()
	icon.texture = _icon(icon_name)
	icon.modulate = accent
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_wrap.add_child(icon)
	var labels := VBoxContainer.new()
	labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	labels.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	labels.add_theme_constant_override("separation", 3)
	row.add_child(labels)
	var value_label := Label.new()
	value_label.text = value
	value_label.tooltip_text = value
	value_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	value_label.add_theme_font_override("font", _font_bold())
	value_label.add_theme_font_size_override("font_size", 22 if compact else 18)
	value_label.add_theme_color_override("font_color", C_TEXT_MAIN)
	labels.add_child(value_label)
	var caption_label := Label.new()
	caption_label.text = caption
	caption_label.add_theme_font_override("font", _font_regular())
	caption_label.add_theme_font_size_override("font_size", 13)
	caption_label.add_theme_color_override("font_color", C_TEXT_MUTED)
	labels.add_child(caption_label)
	return panel


func _format_profile_value(key: String, value: Variant) -> String:
	if value == null or str(value).strip_edges().is_empty():
		return "—"
	match key:
		"id":
			return str(int(value))
		"createdAt":
			return _format_api_date(str(value))
		_:
			return str(value)


func _format_api_date(value: String) -> String:
	var date_part := value.strip_edges().replace(" ", "T").get_slice("T", 0)
	if date_part.length() >= 10 and date_part[4] == "-" and date_part[7] == "-":
		return "%s/%s/%s" % [date_part.substr(8, 2), date_part.substr(5, 2), date_part.substr(0, 4)]
	return value


func _role_name(role: String) -> String:
	match role.to_upper():
		"ADMIN":
			return "Quản trị viên"
		"INSTRUCTOR", "TEACHER":
			return "Giảng viên"
		"LEARNER", "STUDENT", "USER":
			return "Học viên"
		_:
			return _value_or_dash(role)


func _on_avatar_loaded(_result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code < 200 or response_code >= 300 or body.is_empty():
		return
	var content_type := ""
	for header: String in headers:
		if header.to_lower().begins_with("content-type:"):
			content_type = header.to_lower()
			break
	var avatar_image := Image.new()
	var error := ERR_FILE_UNRECOGNIZED
	if "jpeg" in content_type or "jpg" in content_type:
		error = avatar_image.load_jpg_from_buffer(body)
	elif "webp" in content_type:
		error = avatar_image.load_webp_from_buffer(body)
	else:
		error = avatar_image.load_png_from_buffer(body)
	if error == OK:
		avatar.texture = ImageTexture.create_from_image(avatar_image)


func _build_theme() -> void:
	profile_card.add_theme_stylebox_override("panel", _profile_style())
	state_card.add_theme_stylebox_override("panel", _flat(Color(1, 0.99, 0.96, 0.96), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.30), 16, 1))
	avatar_frame.add_theme_stylebox_override("panel", _avatar_style(120.0))
	title_label.add_theme_font_override("font", _font_display())
	title_label.add_theme_color_override("font_color", C_TEXT_MAIN)
	name_label.add_theme_font_override("font", _font_display())
	name_label.add_theme_color_override("font_color", C_TEXT_MAIN)
	for label: Label in [account_title, learning_title]:
		label.add_theme_font_override("font", _font_bold())
		label.add_theme_color_override("font_color", C_TEXT_MAIN)
	for label: Label in [role_label, status_label, state_label, progress_state]:
		label.add_theme_font_override("font", _font_regular())
	role_label.add_theme_color_override("font_color", C_TEXT_MUTED)
	state_label.add_theme_color_override("font_color", C_JADE)
	progress_state.add_theme_color_override("font_color", C_TEXT_MUTED)
	state_icon.texture = _icon("hourglass")
	state_icon.modulate = C_GOLD
	_style_back_button(back_button, C_TEXT_MAIN)
	_set_icon_button(retry_button, "rotate-cw", C_TEXT_MAIN)


func _apply_responsive_layout() -> void:
	var width := get_viewport_rect().size.x
	var mobile := width < 720.0 or OS.has_feature("mobile") or OS.has_feature("android")
	var portrait_layout := width < 600.0
	var side := 12 if mobile else 30
	content.custom_minimum_size.x = minf(780.0, maxf(292.0, width - float(side * 2)))
	content_margin.add_theme_constant_override("margin_left", side)
	content_margin.add_theme_constant_override("margin_right", side)
	content_margin.add_theme_constant_override("margin_top", 112 if mobile else 120) # Push content below floating back button
	card_margin.add_theme_constant_override("margin_left", 16 if mobile else 28)
	card_margin.add_theme_constant_override("margin_right", 16 if mobile else 28)
	card_margin.add_theme_constant_override("margin_top", 20 if mobile else 26)
	card_margin.add_theme_constant_override("margin_bottom", 22 if mobile else 28)
	hero.vertical = portrait_layout
	hero.alignment = BoxContainer.ALIGNMENT_CENTER if portrait_layout else BoxContainer.ALIGNMENT_BEGIN
	identity.alignment = BoxContainer.ALIGNMENT_CENTER
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if portrait_layout else HORIZONTAL_ALIGNMENT_LEFT
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if portrait_layout else HORIZONTAL_ALIGNMENT_LEFT
	status_pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER if portrait_layout else Control.SIZE_SHRINK_BEGIN
	info_grid.columns = 1 if width < 440.0 else 2
	stats_grid.columns = 1 if width < 340.0 else (2 if width < 660.0 else 3)
	title_label.add_theme_font_size_override("font_size", 30 if mobile else 40)
	name_label.add_theme_font_size_override("font_size", 28 if mobile else 34)
	var avatar_size := 104.0 if mobile else 120.0
	avatar_frame.custom_minimum_size = Vector2(avatar_size, avatar_size)
	avatar_frame.add_theme_stylebox_override("panel", _avatar_style(avatar_size))


func _show_state(icon_name: String, message: String, can_retry: bool) -> void:
	state_icon.texture = _icon(icon_name)
	state_label.text = message
	retry_button.visible = can_retry
	state_card.visible = true


func _animate_profile() -> void:
	profile_card.modulate.a = 0.0
	profile_card.position.y += 10.0
	var target_y := profile_card.position.y - 10.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(profile_card, "modulate:a", 1.0, 0.22)
	tween.tween_property(profile_card, "position:y", target_y, 0.30).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)


func _go_back() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _extract_data(response: Dictionary) -> Dictionary:
	var body: Variant = response.get("body", {})
	if body is Dictionary:
		var data: Variant = body.get("data", {})
		if data is Dictionary:
			return data
	return {}


func _response_message(response: Dictionary, fallback: String) -> String:
	var body: Variant = response.get("body", {})
	if body is Dictionary:
		var message := str(body.get("message", "")).strip_edges()
		if not message.is_empty():
			return message
	var direct := str(response.get("message", "")).strip_edges()
	return direct if not direct.is_empty() else fallback


func _value_or_dash(value: Variant) -> String:
	if value == null:
		return "—"
	var text := str(value).strip_edges()
	return text if not text.is_empty() else "—"


func _format_number(value: int) -> String:
	var source := str(value)
	var output := ""
	while source.length() > 3:
		output = "." + source.right(3) + output
		source = source.left(source.length() - 3)
	return source + output


func _is_web_url(value: String) -> bool:
	return value.begins_with("https://") or value.begins_with("http://")


func _clear_children(parent: Node) -> void:
	for child: Node in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


func _style_back_button(button: Button, color: Color) -> void:
	button.icon = _icon("arrow-left")
	button.expand_icon = true
	button.add_theme_color_override("icon_normal_color", color)
	button.add_theme_color_override("icon_hover_color", Color.WHITE.darkened(0.15))
	button.add_theme_color_override("icon_pressed_color", Color.WHITE.darkened(0.3))
	button.add_theme_color_override("icon_focus_color", color)
	button.add_theme_constant_override("icon_max_width", 78)

	var empty := _flat(Color.TRANSPARENT, Color.TRANSPARENT, 0, 0)
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("hover", empty)
	button.add_theme_stylebox_override("pressed", empty)
	button.add_theme_stylebox_override("focus", empty)


func _set_icon_button(button: Button, icon_name: String, color: Color) -> void:
	button.icon = _icon(icon_name)
	button.expand_icon = true
	button.add_theme_color_override("icon_normal_color", color)
	button.add_theme_color_override("icon_hover_color", color.darkened(0.12))
	button.add_theme_color_override("icon_pressed_color", color.darkened(0.25))
	button.add_theme_color_override("icon_focus_color", color)
	button.add_theme_constant_override("icon_max_width", 26)

	var normal_style := _flat(Color(0.96, 0.94, 0.88, 0.96), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.40), 28, 1)
	normal_style.shadow_color = Color(0.10, 0.08, 0.04, 0.16)
	normal_style.shadow_size = 6
	normal_style.shadow_offset = Vector2(0, 2)

	var hover_style := _flat(Color(1.0, 0.992, 0.95, 0.99), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.65), 28, 1)
	hover_style.shadow_color = Color(0.10, 0.08, 0.04, 0.24)
	hover_style.shadow_size = 8
	hover_style.shadow_offset = Vector2(0, 3)

	var pressed_style := _flat(Color(0.90, 0.87, 0.80, 0.98), C_GOLD, 28, 2)

	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("focus", normal_style)


func _icon(name: String) -> Texture2D:
	return load("res://assets/textures/lucide/%s.svg" % name) as Texture2D


func _font_display() -> Font:
	return load("res://assets/fonts/Lora-Bold.ttf") as Font


func _font_bold() -> Font:
	return load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font


func _font_regular() -> Font:
	return load("res://assets/fonts/BeVietnamPro-Regular.ttf") as Font


func _profile_style() -> StyleBoxFlat:
	var style := _flat(Color(1.0, 0.99, 0.97, 0.92), Color(0, 0, 0, 0.06), 20, 1)
	style.shadow_color = Color(0.09, 0.27, 0.18, 0.06)
	style.shadow_size = 14
	style.shadow_offset = Vector2(0, 4)
	return style


func _avatar_style(size: float = 104.0) -> StyleBoxFlat:
	var radius := int(size / 2.0)
	var style := _flat(Color(1.0, 0.99, 0.97, 1.0), C_BORDER, radius, 2)
	style.shadow_color = Color(0.09, 0.27, 0.18, 0.05)
	style.shadow_size = 8
	return style


func _data_card_style(accent: Color) -> StyleBoxFlat:
	var style := _flat(C_CARD_BG, C_BORDER, 12, 1)
	style.shadow_color = Color(0.09, 0.27, 0.18, 0.04)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	return style


func _flat(background: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.border_width_top = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style
