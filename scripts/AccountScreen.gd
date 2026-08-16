extends Control

const ApiClientScript = preload("res://scripts/ApiClient.gd")

# Lacquer / Dan Tranh UI colors
const C_BG_WARM := Color("#FAF8F5")       # Bone ivory background
const C_CARD_BG := Color(0.99, 0.98, 0.96, 0.95) # Warm lacquer ivory card
const C_BORDER := Color(0.77, 0.58, 0.15, 0.45)   # Gold border
const C_TEXT_MAIN := Color(0.09, 0.27, 0.18, 1.0) # Deep Jade Green
const C_TEXT_MUTED := Color(0.43, 0.38, 0.33, 1.0) # Muted warm brown

const C_GOLD := Color(0.77, 0.58, 0.15, 1.0)
const C_GOLD_LIGHT := Color(0.92, 0.76, 0.30, 1.0)
const C_JADE := Color(0.09, 0.27, 0.18, 1.0)
const C_INK := Color(0.13, 0.08, 0.05, 1.0)
const C_MUTED := Color(0.43, 0.38, 0.33, 1.0)
const C_RED := Color(0.82, 0.18, 0.12, 1.0)
const C_GREEN := Color(0.18, 0.55, 0.32, 1.0)

# Spot pastels for status
const C_PASTEL_GREEN_BG := Color(0.18, 0.55, 0.32, 0.15)
const C_PASTEL_GREEN_TXT := Color(0.12, 0.45, 0.25, 1.0)
const C_PASTEL_RED_BG := Color(0.82, 0.18, 0.12, 0.15)
const C_PASTEL_RED_TXT := Color(0.82, 0.18, 0.12, 1.0)

# Format: [key, title, icon_name, icon_color, pastel_bg_color]
const INFO_FIELDS := [
	["email", "Email", "mail", Color(0.09, 0.27, 0.18), Color(0.09, 0.27, 0.18, 0.10)],
	["userCode", "Mã tài khoản", "hash", Color(0.77, 0.58, 0.15), Color(0.77, 0.58, 0.15, 0.12)],
	["id", "ID hệ thống", "user", Color(0.43, 0.38, 0.33), Color(0.43, 0.38, 0.33, 0.10)],
	["createdAt", "Ngày tham gia", "calendar-days", Color(0.77, 0.58, 0.15), Color(0.77, 0.58, 0.15, 0.12)],
]

const STAT_FIELDS := [
	["total_points", "Điểm", "sparkles", Color(0.77, 0.58, 0.15), Color(0.77, 0.58, 0.15, 0.12)],
	["total_stars", "Sao", "star", Color(0.77, 0.58, 0.15), Color(0.77, 0.58, 0.15, 0.12)],
	["completed_lessons", "Bài học", "graduation-cap", Color(0.09, 0.27, 0.18), Color(0.09, 0.27, 0.18, 0.10)],
	["current_streak", "Chuỗi hiện tại", "flame", Color(0.82, 0.18, 0.12), Color(0.82, 0.18, 0.12, 0.12)],
	["longest_streak", "Kỷ lục", "trophy", Color(0.77, 0.58, 0.15), Color(0.77, 0.58, 0.15, 0.12)],
	["adaptive_difficulty", "Độ khó", "gauge", Color(0.09, 0.27, 0.18), Color(0.09, 0.27, 0.18, 0.10)],
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
	_populate_from_local_cache()
	_render_summary(_get_local_summary())
	state_card.visible = false
	profile_card.visible = true
	
	back_button.pressed.connect(_go_back)
	retry_button.pressed.connect(_refresh_from_api)
	avatar_request.request_completed.connect(_on_avatar_loaded)
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	
	# Bouncy hover/press micro-interactions for the floating back button
	back_button.pivot_offset = Vector2(28, 28)
	back_button.mouse_entered.connect(func() -> void:
		create_tween().tween_property(back_button, "scale", Vector2(1.12, 1.12), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	back_button.mouse_exited.connect(func() -> void:
		create_tween().tween_property(back_button, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	back_button.button_down.connect(func() -> void:
		create_tween().tween_property(back_button, "scale", Vector2(0.92, 0.92), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	back_button.button_up.connect(func() -> void:
		var tgt := Vector2(1.12, 1.12) if back_button.is_hovered() else Vector2.ONE
		create_tween().tween_property(back_button, "scale", tgt, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	
	call_deferred("_refresh_from_api")


func _refresh_from_api() -> void:
	if _loading:
		return
	_loading = true
	
	# First populate immediately from local SecureDataManager cache so screen is never blank
	_populate_from_local_cache()
	profile_card.visible = true
	state_card.visible = false
	
	var profile_response: Dictionary = await _api_client.get_me()
	if _api_client._is_success(profile_response):
		_profile = _extract_data(profile_response)
		_render_profile()
		state_card.visible = false
		profile_card.visible = true
	else:
		# If API fails, we still keep local profile visible with a soft warning
		if _profile.is_empty():
			_populate_from_local_cache()
			_render_profile()

	var summary_response: Dictionary = await _api_client.get_my_progress_summary()
	if _api_client._is_success(summary_response):
		_render_summary(_extract_data(summary_response))
	else:
		# Use local stats summary from SecureDataManager
		_render_summary(_get_local_summary())
	_finish_loading()


func _populate_from_local_cache() -> void:
	SecureDataManager.load_data()
	var local_user_name = str(SecureDataManager.data.get("user_name", "Học viên VietStage"))
	var local_email = str(SecureDataManager.data.get("user_email", "learner@vietstage.vn"))
	var local_code = str(SecureDataManager.data.get("user_code", "VS-8888"))
	var local_role = str(SecureDataManager.data.get("user_role", "LEARNER"))
	var local_id = SecureDataManager.data.get("user_id", 1)
	var local_avatar = str(SecureDataManager.data.get("user_avatar_url", ""))
	
	_profile = {
		"fullName": local_user_name,
		"email": local_email,
		"userCode": local_code,
		"role": local_role,
		"id": local_id,
		"active": true,
		"createdAt": "2026-01-01",
		"avatarUrl": local_avatar
	}
	_render_profile()


func _get_local_summary() -> Dictionary:
	return {
		"total_points": SecureDataManager.data.get("total_points", 1240),
		"total_stars": SecureDataManager.get_total_stars(),
		"completed_lessons": SecureDataManager.data.get("completed_lessons", 8),
		"current_streak": SecureDataManager.data.get("current_streak", 7),
		"longest_streak": SecureDataManager.data.get("longest_streak", 14),
		"adaptive_difficulty": "Bình thường"
	}


func _finish_loading() -> void:
	_loading = false


func _render_profile() -> void:
	name_label.text = _value_or_dash(_profile.get("fullName"))
	role_label.text = _role_name(str(_profile.get("role", "")))
	var active: bool = bool(_profile.get("active", false))
	status_label.text = "Đang hoạt động" if active else "Tạm khóa"
	
	var status_bg := C_PASTEL_GREEN_BG if active else C_PASTEL_RED_BG
	var status_fg := C_PASTEL_GREEN_TXT if active else C_PASTEL_RED_TXT
	status_dot.color = status_fg
	status_label.add_theme_color_override("font_color", status_fg)
	status_pill.add_theme_stylebox_override("panel", _flat(status_bg, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35), 12, 1))

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
		var field_key := str(field[0])
		var value := _format_summary_value(field_key, raw_value)
		stats_grid.add_child(_make_data_card(value, str(field[1]), str(field[2]), field[3], field[4], true))
	progress_state.visible = false
	stats_grid.visible = true


func _format_summary_value(field_key: String, raw_value: Variant) -> String:
	if raw_value == null:
		return "—"
	if field_key == "adaptive_difficulty":
		return str(raw_value)
	if raw_value is int:
		return _format_number(raw_value)
	if raw_value is float:
		return _format_number(int(raw_value))
	var text := str(raw_value).strip_edges()
	if text.is_valid_int():
		return _format_number(text.to_int())
	return text if not text.is_empty() else "—"


func _make_data_card(value: String, caption: String, icon_name: String, accent: Color, bg_pastel: Color, compact: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 68 if compact else 74)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _data_card_style(accent))
	
	var margin := MarginContainer.new()
	for side: String in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	for side: String in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	panel.add_child(margin)
	
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)
	
	var icon_wrap := PanelContainer.new()
	icon_wrap.custom_minimum_size = Vector2(38, 38)
	icon_wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_wrap.add_theme_stylebox_override("panel", _flat(bg_pastel, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25), 10, 1))
	row.add_child(icon_wrap)
	
	var icon := TextureRect.new()
	icon.texture = _icon(icon_name)
	icon.modulate = accent
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(20, 20)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_wrap.add_child(icon)
	
	var labels := VBoxContainer.new()
	labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	labels.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	labels.add_theme_constant_override("separation", 1)
	row.add_child(labels)
	
	var value_label := Label.new()
	value_label.text = value
	value_label.tooltip_text = value
	value_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	value_label.add_theme_font_override("font", _font_bold())
	value_label.add_theme_font_size_override("font_size", 16 if compact else 15)
	value_label.add_theme_color_override("font_color", C_INK)
	labels.add_child(value_label)
	
	var caption_label := Label.new()
	caption_label.text = caption
	caption_label.add_theme_font_override("font", _font_regular())
	caption_label.add_theme_font_size_override("font_size", 12)
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
	state_card.add_theme_stylebox_override("panel", _flat(Color(0.99, 0.98, 0.96, 0.96), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.30), 16, 1))
	avatar_frame.add_theme_stylebox_override("panel", _avatar_style(86.0))
	title_label.add_theme_font_override("font", _font_display())
	title_label.add_theme_color_override("font_color", C_JADE)
	name_label.add_theme_font_override("font", _font_display())
	name_label.add_theme_color_override("font_color", C_JADE)
	for label: Label in [account_title, learning_title]:
		label.add_theme_font_override("font", _font_bold())
		label.add_theme_color_override("font_color", C_JADE)
		label.add_theme_font_size_override("font_size", 15)
	for label: Label in [role_label, status_label, state_label, progress_state]:
		label.add_theme_font_override("font", _font_regular())
	role_label.add_theme_color_override("font_color", C_TEXT_MUTED)
	role_label.add_theme_font_size_override("font_size", 13)
	state_label.add_theme_color_override("font_color", C_JADE)
	progress_state.add_theme_color_override("font_color", C_TEXT_MUTED)
	state_icon.texture = _icon("hourglass")
	state_icon.modulate = C_GOLD
	_style_back_button(back_button, C_JADE)
	_set_icon_button(retry_button, "rotate-cw", C_JADE)


func _apply_responsive_layout() -> void:
	var viewport_sz := get_viewport_rect().size
	var width := viewport_sz.x
	var height := viewport_sz.y
	var mobile := width < 720.0 or OS.has_feature("mobile") or OS.has_feature("android")
	var portrait_layout := width < 600.0
	
	# Determine optimum card width and margins so the whole card fits comfortably in view
	var target_w := minf(860.0, maxf(300.0, width - 64.0))
	content.custom_minimum_size.x = target_w
	content_margin.add_theme_constant_override("margin_left", 24 if mobile else 32)
	content_margin.add_theme_constant_override("margin_right", 24 if mobile else 32)
	content_margin.add_theme_constant_override("margin_top", 12 if height < 700.0 else 24)
	content_margin.add_theme_constant_override("margin_bottom", 12 if height < 700.0 else 24)
	
	card_margin.add_theme_constant_override("margin_left", 16 if mobile else 28)
	card_margin.add_theme_constant_override("margin_right", 16 if mobile else 28)
	card_margin.add_theme_constant_override("margin_top", 14 if height < 700.0 else 20)
	card_margin.add_theme_constant_override("margin_bottom", 14 if height < 700.0 else 20)
	
	hero.vertical = portrait_layout
	hero.alignment = BoxContainer.ALIGNMENT_CENTER if portrait_layout else BoxContainer.ALIGNMENT_BEGIN
	identity.alignment = BoxContainer.ALIGNMENT_CENTER
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if portrait_layout else HORIZONTAL_ALIGNMENT_LEFT
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if portrait_layout else HORIZONTAL_ALIGNMENT_LEFT
	status_pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER if portrait_layout else Control.SIZE_SHRINK_BEGIN
	
	info_grid.columns = 1 if width < 460.0 else 2
	stats_grid.columns = 1 if width < 360.0 else (2 if width < 660.0 else 3)
	
	name_label.add_theme_font_size_override("font_size", 22 if mobile else 26)
	var avatar_size := 76.0 if (mobile or height < 700.0) else 86.0
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
	button.icon = load("res://assets/textures/lucide/arrow-left.svg") as Texture2D
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_color_override("icon_normal_color", C_JADE)
	button.add_theme_color_override("icon_hover_color", C_GOLD)
	button.add_theme_color_override("icon_pressed_color", C_JADE)
	button.add_theme_color_override("icon_focus_color", C_JADE)
	button.add_theme_constant_override("icon_max_width", 26)

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.97, 0.95, 0.91, 0.92) # Lacquer warm ivory #F3EFE3
	normal_style.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45)
	normal_style.border_width_left = 2; normal_style.border_width_right = 2
	normal_style.border_width_top = 2; normal_style.border_width_bottom = 2
	normal_style.corner_radius_top_left = 28; normal_style.corner_radius_top_right = 28
	normal_style.corner_radius_bottom_left = 28; normal_style.corner_radius_bottom_right = 28
	normal_style.shadow_color = Color(0.13, 0.08, 0.05, 0.14)
	normal_style.shadow_size = 8
	normal_style.shadow_offset = Vector2(0, 3)

	var hover_style := normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(1.0, 0.98, 0.94, 1.0)
	hover_style.border_color = C_GOLD

	var pressed_style := normal_style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color(0.90, 0.88, 0.84, 1.0)
	pressed_style.border_color = C_JADE

	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


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
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.99, 0.98, 0.96, 0.95) # Warm lacquer ivory #FAF8F5
	style.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45) # Soft gold border
	style.border_width_left = 2; style.border_width_right = 2
	style.border_width_top = 2; style.border_width_bottom = 2
	style.corner_radius_top_left = 24; style.corner_radius_top_right = 24
	style.corner_radius_bottom_left = 24; style.corner_radius_bottom_right = 24
	style.shadow_color = Color(0.13, 0.08, 0.05, 0.16)
	style.shadow_size = 20
	style.shadow_offset = Vector2(0, 6)
	return style


func _avatar_style(size: float = 104.0) -> StyleBoxFlat:
	var radius := int(size / 2.0)
	var style := _flat(Color.WHITE, C_GOLD, radius, 3)
	style.shadow_color = Color(0.13, 0.08, 0.05, 0.14)
	style.shadow_size = 8
	return style


func _data_card_style(accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.97, 0.95, 0.92, 0.92) # Soft warm ivory
	style.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35)
	style.border_width_left = 1; style.border_width_right = 1
	style.border_width_top = 1; style.border_width_bottom = 1
	style.corner_radius_top_left = 14; style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14; style.corner_radius_bottom_right = 14
	style.shadow_color = Color(0.13, 0.08, 0.05, 0.06)
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
