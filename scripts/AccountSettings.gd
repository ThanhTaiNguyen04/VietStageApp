extends Control

const ApiClientScript = preload("res://scripts/ApiClient.gd")

const C_GOLD := Color("#C59626")
const C_JADE := Color("#173F2D")
const C_INK := Color("#261A13")
const C_MUTED := Color("#75685E")
const C_RED := Color("#A63D32")
const C_GREEN := Color("#2F8A55")

@onready var top_bar: PanelContainer = $Root/TopBar
@onready var top_margin: MarginContainer = $Root/TopBar/TopMargin
@onready var back_button: Button = $Root/TopBar/TopMargin/TopRow/BackButton
@onready var refresh_button: Button = $Root/TopBar/TopMargin/TopRow/RefreshButton
@onready var title_label: Label = $Root/TopBar/TopMargin/TopRow/Title
@onready var content_margin: MarginContainer = $Root/ContentMargin
@onready var content: VBoxContainer = $Root/ContentMargin/Scroll/Center/Content
@onready var state_card: PanelContainer = $Root/ContentMargin/Scroll/Center/Content/StateCard
@onready var state_icon: TextureRect = $Root/ContentMargin/Scroll/Center/Content/StateCard/StateMargin/StateRow/StateIcon
@onready var state_label: Label = $Root/ContentMargin/Scroll/Center/Content/StateCard/StateMargin/StateRow/StateLabel
@onready var retry_button: Button = $Root/ContentMargin/Scroll/Center/Content/StateCard/StateMargin/StateRow/RetryButton
@onready var settings_card: PanelContainer = $Root/ContentMargin/Scroll/Center/Content/SettingsCard
@onready var card_margin: MarginContainer = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin
@onready var avatar_frame: PanelContainer = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/Preview/AvatarFrame
@onready var avatar: TextureRect = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/Preview/AvatarFrame/Avatar
@onready var preview_name: Label = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/Preview/PreviewCopy/Name
@onready var preview_email: Label = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/Preview/PreviewCopy/Email
@onready var preview_code: Label = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/Preview/PreviewCopy/Code
@onready var profile_section: PanelContainer = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/ProfileSection
@onready var profile_icon: TextureRect = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/ProfileSection/ProfileMargin/ProfileForm/Header/Icon
@onready var profile_title: Label = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/ProfileSection/ProfileMargin/ProfileForm/Header/Title
@onready var name_label: Label = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/ProfileSection/ProfileMargin/ProfileForm/NameLabel
@onready var name_input: LineEdit = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/ProfileSection/ProfileMargin/ProfileForm/NameInput
@onready var avatar_label: Label = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/ProfileSection/ProfileMargin/ProfileForm/AvatarLabel
@onready var avatar_input: LineEdit = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/ProfileSection/ProfileMargin/ProfileForm/AvatarInput
@onready var profile_hint: Label = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/ProfileSection/ProfileMargin/ProfileForm/ProfileHint
@onready var profile_feedback: Label = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/ProfileSection/ProfileMargin/ProfileForm/ProfileFeedback
@onready var save_profile_button: Button = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/ProfileSection/ProfileMargin/ProfileForm/SaveProfileButton
@onready var security_section: PanelContainer = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/SecuritySection
@onready var security_icon: TextureRect = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/SecuritySection/SecurityMargin/SecurityForm/Header/Icon
@onready var security_title: Label = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/SecuritySection/SecurityMargin/SecurityForm/Header/Title
@onready var old_password: LineEdit = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/SecuritySection/SecurityMargin/SecurityForm/OldPassword
@onready var new_password: LineEdit = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/SecuritySection/SecurityMargin/SecurityForm/NewPassword
@onready var confirm_password: LineEdit = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/SecuritySection/SecurityMargin/SecurityForm/ConfirmPassword
@onready var password_hint: Label = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/SecuritySection/SecurityMargin/SecurityForm/PasswordHint
@onready var password_feedback: Label = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/SecuritySection/SecurityMargin/SecurityForm/PasswordFeedback
@onready var change_password_button: Button = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/SecuritySection/SecurityMargin/SecurityForm/ChangePasswordButton
@onready var avatar_request: HTTPRequest = $AvatarRequest

var _api_client: Node
var _profile: Dictionary = {}
var _loading := false


func _ready() -> void:
	_api_client = ApiClientScript.new()
	add_child(_api_client)
	_build_theme()
	back_button.pressed.connect(_go_back)
	refresh_button.pressed.connect(_load_profile)
	retry_button.pressed.connect(_load_profile)
	save_profile_button.pressed.connect(_save_profile)
	change_password_button.pressed.connect(_change_password)
	avatar_input.text_submitted.connect(func(_value: String) -> void: _preview_avatar())
	avatar_input.focus_exited.connect(_preview_avatar)
	avatar_request.request_completed.connect(_on_avatar_loaded)
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	call_deferred("_load_profile")


func _load_profile() -> void:
	if _loading:
		return
	_loading = true
	refresh_button.disabled = true
	settings_card.visible = false
	_show_state("hourglass", "Đang tải tài khoản...", false)
	var response: Dictionary = await _api_client.get_me()
	_loading = false
	refresh_button.disabled = false
	if not _api_client._is_success(response):
		_show_state("rotate-cw", _response_message(response, "Không thể tải tài khoản."), true)
		return
	_profile = _extract_data(response)
	_render_profile()
	state_card.visible = false
	settings_card.visible = true
	_animate_in()


func _render_profile() -> void:
	var full_name := _value_or_dash(_profile.get("fullName"))
	var email := _value_or_dash(_profile.get("email"))
	var user_code := _value_or_dash(_profile.get("userCode"))
	preview_name.text = full_name
	preview_email.text = email
	preview_email.tooltip_text = email
	preview_code.text = user_code
	name_input.text = str(_profile.get("fullName", ""))
	avatar_input.text = str(_profile.get("avatarUrl", ""))
	profile_feedback.visible = false
	password_feedback.visible = false
	avatar.texture = load("res://assets/textures/default_avatar.png") as Texture2D
	_preview_avatar()


func _save_profile() -> void:
	var full_name := name_input.text.strip_edges()
	var avatar_url := avatar_input.text.strip_edges()
	profile_feedback.visible = false
	if full_name.is_empty():
		_show_feedback(profile_feedback, "Họ và tên không được để trống.", false)
		return
	if not avatar_url.is_empty() and not _is_web_url(avatar_url):
		_show_feedback(profile_feedback, "URL ảnh đại diện phải bắt đầu bằng http:// hoặc https://.", false)
		return
	_set_profile_form_enabled(false)
	var response: Dictionary = await _api_client.update_profile(full_name, avatar_url)
	_set_profile_form_enabled(true)
	if not _api_client._is_success(response):
		_show_feedback(profile_feedback, _response_message(response, "Không thể lưu hồ sơ."), false)
		return
	var returned_profile := _extract_data(response)
	if not returned_profile.is_empty():
		_profile = returned_profile
	else:
		_profile["fullName"] = full_name
		_profile["avatarUrl"] = avatar_url
	_render_profile()
	_show_feedback(profile_feedback, "Đã cập nhật hồ sơ.", true)


func _change_password() -> void:
	var old_value := old_password.text
	var new_value := new_password.text
	var confirm_value := confirm_password.text
	password_feedback.visible = false
	if old_value.is_empty() or new_value.is_empty() or confirm_value.is_empty():
		_show_feedback(password_feedback, "Vui lòng nhập đủ ba trường mật khẩu.", false)
		return
	if new_value.length() < 8 or " " in new_value:
		_show_feedback(password_feedback, "Mật khẩu mới cần ít nhất 8 ký tự và không có khoảng trắng.", false)
		return
	if new_value != confirm_value:
		_show_feedback(password_feedback, "Mật khẩu xác nhận chưa khớp.", false)
		return
	_set_password_form_enabled(false)
	var response: Dictionary = await _api_client.change_password(old_value, new_value, confirm_value)
	_set_password_form_enabled(true)
	if not _api_client._is_success(response):
		_show_feedback(password_feedback, _response_message(response, "Không thể đổi mật khẩu."), false)
		return
	old_password.clear()
	new_password.clear()
	confirm_password.clear()
	_show_feedback(password_feedback, "Đổi mật khẩu thành công.", true)


func _preview_avatar() -> void:
	var avatar_url := avatar_input.text.strip_edges()
	if avatar_url.is_empty():
		avatar.texture = load("res://assets/textures/default_avatar.png") as Texture2D
		return
	if _is_web_url(avatar_url):
		avatar_request.cancel_request()
		avatar_request.request(avatar_url)


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


func _set_profile_form_enabled(enabled: bool) -> void:
	name_input.editable = enabled
	avatar_input.editable = enabled
	save_profile_button.disabled = not enabled
	save_profile_button.text = "Lưu hồ sơ" if enabled else "Đang lưu..."


func _set_password_form_enabled(enabled: bool) -> void:
	old_password.editable = enabled
	new_password.editable = enabled
	confirm_password.editable = enabled
	change_password_button.disabled = not enabled
	change_password_button.text = "Đổi mật khẩu" if enabled else "Đang cập nhật..."


func _show_feedback(label: Label, message: String, success: bool) -> void:
	label.text = message
	label.add_theme_color_override("font_color", C_GREEN if success else C_RED)
	label.visible = true


func _build_theme() -> void:
	top_bar.add_theme_stylebox_override("panel", _flat(Color(1.0, 0.985, 0.94, 0.93), Color(1, 1, 1, 0.25), 0, 0))
	settings_card.add_theme_stylebox_override("panel", _main_card_style())
	state_card.add_theme_stylebox_override("panel", _flat(Color(1, 0.99, 0.96, 0.96), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.30), 16, 1))
	profile_section.add_theme_stylebox_override("panel", _section_style(C_JADE))
	security_section.add_theme_stylebox_override("panel", _section_style(C_GOLD))
	avatar_frame.add_theme_stylebox_override("panel", _avatar_style())
	title_label.add_theme_font_override("font", _font_display())
	preview_name.add_theme_font_override("font", _font_display())
	for label: Label in [profile_title, security_title, name_label, avatar_label]:
		label.add_theme_font_override("font", _font_bold())
		label.add_theme_color_override("font_color", C_INK)
	for label: Label in [preview_email, preview_code, profile_hint, password_hint, profile_feedback, password_feedback, state_label]:
		label.add_theme_font_override("font", _font_regular())
	preview_email.add_theme_color_override("font_color", C_MUTED)
	preview_code.add_theme_color_override("font_color", C_GOLD)
	profile_hint.add_theme_color_override("font_color", C_MUTED)
	password_hint.add_theme_color_override("font_color", C_MUTED)
	state_label.add_theme_color_override("font_color", C_JADE)
	profile_icon.texture = _icon("user")
	profile_icon.modulate = C_JADE
	security_icon.texture = _icon("lock")
	security_icon.modulate = C_GOLD
	state_icon.texture = _icon("hourglass")
	state_icon.modulate = C_GOLD
	_set_icon_button(back_button, "arrow-left", C_JADE)
	_set_icon_button(refresh_button, "rotate-cw", C_JADE)
	_set_icon_button(retry_button, "rotate-cw", C_JADE)
	for field: LineEdit in [name_input, avatar_input, old_password, new_password, confirm_password]:
		_style_field(field)
	_style_primary_button(save_profile_button, C_JADE)
	_style_primary_button(change_password_button, C_GOLD)


func _apply_responsive_layout() -> void:
	var width := get_viewport_rect().size.x
	var mobile := width < 720.0 or OS.has_feature("mobile") or OS.has_feature("android")
	var side := 12 if mobile else 30
	content.custom_minimum_size.x = minf(680.0, maxf(292.0, width - float(side * 2)))
	content_margin.add_theme_constant_override("margin_left", side)
	content_margin.add_theme_constant_override("margin_right", side)
	content_margin.add_theme_constant_override("margin_top", 12 if mobile else 20)
	top_margin.add_theme_constant_override("margin_left", 10 if mobile else 22)
	top_margin.add_theme_constant_override("margin_right", 10 if mobile else 22)
	card_margin.add_theme_constant_override("margin_left", 14 if mobile else 24)
	card_margin.add_theme_constant_override("margin_right", 14 if mobile else 24)
	card_margin.add_theme_constant_override("margin_top", 18 if mobile else 22)
	card_margin.add_theme_constant_override("margin_bottom", 20 if mobile else 26)
	title_label.add_theme_font_size_override("font_size", 21 if mobile else 25)
	preview_name.add_theme_font_size_override("font_size", 19 if mobile else 21)
	avatar_frame.custom_minimum_size = Vector2(68, 68) if mobile else Vector2(76, 76)


func _show_state(icon_name: String, message: String, can_retry: bool) -> void:
	state_icon.texture = _icon(icon_name)
	state_label.text = message
	retry_button.visible = can_retry
	state_card.visible = true


func _animate_in() -> void:
	settings_card.modulate.a = 0.0
	settings_card.position.y += 10.0
	var target_y := settings_card.position.y - 10.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(settings_card, "modulate:a", 1.0, 0.22)
	tween.tween_property(settings_card, "position:y", target_y, 0.30).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)


func _go_back() -> void:
	get_tree().change_scene_to_file("res://scenes/AccountScreen.tscn")


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


func _is_web_url(value: String) -> bool:
	return value.begins_with("https://") or value.begins_with("http://")


func _style_field(field: LineEdit) -> void:
	field.add_theme_font_override("font", _font_regular())
	field.add_theme_color_override("font_color", C_INK)
	field.add_theme_color_override("font_placeholder_color", Color(C_MUTED.r, C_MUTED.g, C_MUTED.b, 0.72))
	field.add_theme_stylebox_override("normal", _flat(Color.WHITE, Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.22), 13, 1))
	field.add_theme_stylebox_override("focus", _flat(Color.WHITE, C_GOLD, 13, 2))
	field.add_theme_stylebox_override("read_only", _flat(Color(0.95, 0.95, 0.92, 1.0), Color(C_MUTED.r, C_MUTED.g, C_MUTED.b, 0.18), 13, 1))


func _style_primary_button(button: Button, color: Color) -> void:
	button.add_theme_font_override("font", _font_bold())
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _flat(color, color, 14, 0))
	button.add_theme_stylebox_override("hover", _flat(color.lightened(0.08), color.lightened(0.14), 14, 1))
	button.add_theme_stylebox_override("pressed", _flat(color.darkened(0.08), color, 14, 0))


func _set_icon_button(button: Button, icon_name: String, color: Color) -> void:
	button.icon = _icon(icon_name)
	button.expand_icon = true
	button.add_theme_color_override("icon_normal_color", color)
	button.add_theme_color_override("icon_hover_color", color.lightened(0.08))
	button.add_theme_color_override("icon_pressed_color", color.darkened(0.08))
	button.add_theme_constant_override("icon_max_width", 21)
	button.add_theme_stylebox_override("normal", _flat(Color(color.r, color.g, color.b, 0.055), Color(color.r, color.g, color.b, 0.18), 15, 1))
	button.add_theme_stylebox_override("hover", _flat(Color(color.r, color.g, color.b, 0.11), Color(color.r, color.g, color.b, 0.34), 15, 1))
	button.add_theme_stylebox_override("pressed", _flat(Color(color.r, color.g, color.b, 0.17), color, 15, 1))


func _icon(name: String) -> Texture2D:
	return load("res://assets/textures/lucide/%s.svg" % name) as Texture2D


func _font_display() -> Font:
	return load("res://assets/fonts/Lora-Bold.ttf") as Font


func _font_bold() -> Font:
	return load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font


func _font_regular() -> Font:
	return load("res://assets/fonts/BeVietnamPro-Regular.ttf") as Font


func _main_card_style() -> StyleBoxFlat:
	var style := _flat(Color(1.0, 0.992, 0.965, 0.97), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.42), 24, 1)
	style.shadow_color = Color(0.02, 0.06, 0.035, 0.28)
	style.shadow_size = 22
	style.shadow_offset = Vector2(0, 9)
	return style


func _section_style(accent: Color) -> StyleBoxFlat:
	return _flat(Color.WHITE, Color(accent.r, accent.g, accent.b, 0.20), 17, 1)


func _avatar_style() -> StyleBoxFlat:
	var style := _flat(Color.WHITE, C_GOLD, 38, 2)
	style.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.20)
	style.shadow_size = 6
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
