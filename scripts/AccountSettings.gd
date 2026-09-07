extends Control

const ApiClientScript = preload("res://scripts/ApiClient.gd")

const MAX_AVATAR_BYTES := 5 * 1024 * 1024

# Minimalist UI colors
const C_BG_WARM := Color("#F7F6F3")       # Bone background
const C_CARD_BG := Color("#FFFFFF")       # Pure White background
const C_BORDER := Color("#EAEAEA")        # Crisp light border
const C_TEXT_MAIN := Color("#111111")     # Charcoal main text
const C_TEXT_MUTED := Color("#787774")    # Gray muted text

const C_GOLD := Color("#C59626")
const C_JADE := Color("#173F2D")
const C_INK := Color("#261A13")
const C_MUTED := Color("#75685E")
const C_RED := Color("#A63D32")
const C_GREEN := Color("#2F8A55")

# Spot pastels
const C_PASTEL_GREEN_BG := Color("#EDF3EC")
const C_PASTEL_GREEN_TXT := Color("#346538")
const C_PASTEL_RED_BG := Color("#FDEBEC")
const C_PASTEL_RED_TXT := Color("#9F2F2D")
const C_PASTEL_YELLOW_BG := Color("#FBF3DB")
const C_PASTEL_YELLOW_TXT := Color("#956400")

@onready var back_button: Button = $FloatingMargin/BackButton
@onready var title_label: Label = $Root/ContentMargin/Scroll/Center/Content/Title
@onready var content_margin: MarginContainer = $Root/ContentMargin
@onready var content: VBoxContainer = $Root/ContentMargin/Scroll/Center/Content
@onready var state_card: PanelContainer = $Root/ContentMargin/Scroll/Center/Content/StateCard
@onready var state_icon: TextureRect = $Root/ContentMargin/Scroll/Center/Content/StateCard/StateMargin/StateRow/StateIcon
@onready var state_label: Label = $Root/ContentMargin/Scroll/Center/Content/StateCard/StateMargin/StateRow/StateLabel
@onready var retry_button: Button = $Root/ContentMargin/Scroll/Center/Content/StateCard/StateMargin/StateRow/RetryButton
@onready var settings_card: PanelContainer = $Root/ContentMargin/Scroll/Center/Content/SettingsCard
@onready var card_margin: MarginContainer = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin
@onready var avatar_stack: Control = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/Preview/AvatarStack
@onready var avatar_frame: PanelContainer = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/Preview/AvatarStack/AvatarFrame
@onready var avatar: TextureRect = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/Preview/AvatarStack/AvatarFrame/Avatar
@onready var edit_avatar_button: Button = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/Preview/AvatarStack/EditAvatarButton
@onready var preview_name: Label = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/Preview/PreviewCopy/Name
@onready var preview_email: Label = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/Preview/PreviewCopy/Email
@onready var preview_code: Label = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/Preview/PreviewCopy/Code
@onready var profile_tab: Button = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/Tabs/ProfileTab
@onready var security_tab: Button = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/Tabs/SecurityTab
@onready var profile_section: PanelContainer = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/ProfileSection
@onready var name_label: Label = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/ProfileSection/ProfileMargin/ProfileForm/NameLabel
@onready var name_input: LineEdit = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/ProfileSection/ProfileMargin/ProfileForm/NameInput
@onready var avatar_picker: PanelContainer = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/ProfileSection/ProfileMargin/ProfileForm/AvatarPicker
@onready var avatar_title: Label = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/ProfileSection/ProfileMargin/ProfileForm/AvatarPicker/PickerMargin/PickerRow/PickerCopy/AvatarTitle
@onready var avatar_hint: Label = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/ProfileSection/ProfileMargin/ProfileForm/AvatarPicker/PickerMargin/PickerRow/PickerCopy/AvatarHint
@onready var selected_file: Label = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/ProfileSection/ProfileMargin/ProfileForm/AvatarPicker/PickerMargin/PickerRow/PickerCopy/SelectedFile
@onready var choose_avatar_button: Button = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/ProfileSection/ProfileMargin/ProfileForm/AvatarPicker/PickerMargin/PickerRow/ChooseAvatarButton
@onready var profile_feedback: Label = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/ProfileSection/ProfileMargin/ProfileForm/ProfileFeedback
@onready var save_profile_button: Button = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/ProfileSection/ProfileMargin/ProfileForm/SaveProfileButton
@onready var security_section: PanelContainer = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/SecuritySection
@onready var security_hint: Label = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/SecuritySection/SecurityMargin/SecurityForm/SecurityHint
@onready var old_password: LineEdit = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/SecuritySection/SecurityMargin/SecurityForm/OldPassword
@onready var new_password: LineEdit = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/SecuritySection/SecurityMargin/SecurityForm/NewPassword
@onready var confirm_password: LineEdit = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/SecuritySection/SecurityMargin/SecurityForm/ConfirmPassword
@onready var password_feedback: Label = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/SecuritySection/SecurityMargin/SecurityForm/PasswordFeedback
@onready var change_password_button: Button = $Root/ContentMargin/Scroll/Center/Content/SettingsCard/CardMargin/Card/SecuritySection/SecurityMargin/SecurityForm/ChangePasswordButton
@onready var avatar_request: HTTPRequest = $AvatarRequest
@onready var avatar_file_dialog: FileDialog = $AvatarFileDialog

var _api_client: Node
var _profile: Dictionary = {}
var _loading := false
var _selected_avatar_bytes := PackedByteArray()
var _selected_avatar_name := ""
var _selected_avatar_mime := ""


func _ready() -> void:
	_api_client = ApiClientScript.new()
	add_child(_api_client)
	_build_theme()
	back_button.pressed.connect(_go_back)

	retry_button.pressed.connect(_load_profile)
	profile_tab.pressed.connect(func() -> void: _show_tab(true))
	security_tab.pressed.connect(func() -> void: _show_tab(false))
	edit_avatar_button.pressed.connect(_open_avatar_picker)
	choose_avatar_button.pressed.connect(_open_avatar_picker)
	avatar_file_dialog.file_selected.connect(_on_avatar_file_selected)
	save_profile_button.pressed.connect(_save_profile)
	change_password_button.pressed.connect(_change_password)
	avatar_request.request_completed.connect(_on_avatar_loaded)
	get_viewport().size_changed.connect(_apply_responsive_layout)
	
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
	
	_show_tab(true)
	_apply_responsive_layout()
	call_deferred("_load_profile")


func _load_profile() -> void:
	if _loading:
		return
	_loading = true

	settings_card.visible = false
	_show_state("hourglass", "Đang tải tài khoản...", false)
	var response: Dictionary = await _api_client.get_me()
	_loading = false

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
	preview_name.text = full_name
	preview_email.text = email
	preview_email.tooltip_text = email
	preview_code.text = _value_or_dash(_profile.get("userCode"))
	name_input.text = str(_profile.get("fullName", ""))
	profile_feedback.visible = false
	password_feedback.visible = false
	_clear_selected_avatar()
	avatar.texture = load("res://assets/textures/default_avatar.png") as Texture2D
	_load_remote_avatar(str(_profile.get("avatarUrl", "")))


func _open_avatar_picker() -> void:
	_show_tab(true)
	profile_feedback.visible = false
	avatar_file_dialog.popup_centered_ratio(0.88)


func _on_avatar_file_selected(path: String) -> void:
	profile_feedback.visible = false
	var extension := path.get_extension().to_lower()
	var mime_types := {"png": "image/png", "jpg": "image/jpeg", "jpeg": "image/jpeg", "webp": "image/webp"}
	if not mime_types.has(extension):
		_show_feedback(profile_feedback, "Chỉ hỗ trợ ảnh PNG, JPG hoặc WebP.", false)
		return
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		_show_feedback(profile_feedback, "Không thể đọc ảnh đã chọn.", false)
		return
	if bytes.size() > MAX_AVATAR_BYTES:
		_show_feedback(profile_feedback, "Ảnh vượt quá 5 MB. Vui lòng chọn ảnh nhẹ hơn.", false)
		return
	var image := Image.new()
	if _decode_image(image, bytes, extension) != OK or image.is_empty():
		_show_feedback(profile_feedback, "Tệp đã chọn không phải ảnh hợp lệ.", false)
		return
	if image.get_width() < 128 or image.get_height() < 128:
		_show_feedback(profile_feedback, "Ảnh cần có kích thước tối thiểu 128 × 128 px.", false)
		return
	_selected_avatar_bytes = bytes
	_selected_avatar_name = path.get_file()
	_selected_avatar_mime = str(mime_types[extension])
	avatar_request.cancel_request()
	avatar.texture = ImageTexture.create_from_image(image)
	selected_file.text = "%s • %s" % [_selected_avatar_name, _format_file_size(bytes.size())]
	selected_file.add_theme_color_override("font_color", C_PASTEL_GREEN_TXT)
	choose_avatar_button.text = "Đổi ảnh"
	_show_feedback(profile_feedback, "Ảnh đã sẵn sàng. Nhấn “Lưu thay đổi” để cập nhật.", true)


func _save_profile() -> void:
	var full_name := name_input.text.strip_edges()
	profile_feedback.visible = false
	if full_name.is_empty():
		_show_feedback(profile_feedback, "Họ và tên không được để trống.", false)
		return
	_set_profile_form_enabled(false)
	var avatar_url := str(_profile.get("avatarUrl", "")).strip_edges()
	if not _selected_avatar_bytes.is_empty():
		save_profile_button.text = "Đang tải ảnh..."
		var upload_response: Dictionary = await _api_client.upload_file(_selected_avatar_bytes, _selected_avatar_name, _selected_avatar_mime)
		if not _api_client._is_success(upload_response):
			_set_profile_form_enabled(true)
			_show_feedback(profile_feedback, _response_message(upload_response, "Không thể tải ảnh lên."), false)
			return
		var upload_body: Variant = upload_response.get("body", {})
		if upload_body is Dictionary:
			avatar_url = str(upload_body.get("data", "")).strip_edges()
		if not _is_web_url(avatar_url):
			_set_profile_form_enabled(true)
			_show_feedback(profile_feedback, "Máy chủ chưa trả về URL ảnh hợp lệ.", false)
			return
		save_profile_button.text = "Đang lưu..."
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
	SecureDataManager.data["user_name"] = str(_profile.get("fullName", full_name))
	SecureDataManager.data["user_avatar_url"] = str(_profile.get("avatarUrl", avatar_url)).strip_edges()
	SecureDataManager.save_data()
	_render_profile()
	_show_feedback(profile_feedback, "Đã cập nhật hồ sơ và ảnh đại diện.", true)


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


func _load_remote_avatar(avatar_url: String) -> void:
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
	var image := Image.new()
	var extension := "jpg" if "jpeg" in content_type or "jpg" in content_type else ("webp" if "webp" in content_type else "png")
	if _decode_image(image, body, extension) == OK:
		avatar.texture = ImageTexture.create_from_image(image)


func _decode_image(image: Image, bytes: PackedByteArray, extension: String) -> Error:
	match extension:
		"jpg", "jpeg":
			return image.load_jpg_from_buffer(bytes)
		"webp":
			return image.load_webp_from_buffer(bytes)
		_:
			return image.load_png_from_buffer(bytes)


func _clear_selected_avatar() -> void:
	_selected_avatar_bytes.clear()
	_selected_avatar_name = ""
	_selected_avatar_mime = ""
	selected_file.text = "Chưa chọn ảnh mới"
	selected_file.add_theme_color_override("font_color", C_TEXT_MUTED)
	choose_avatar_button.text = "Chọn ảnh"


func _show_tab(show_profile: bool) -> void:
	profile_section.visible = show_profile
	security_section.visible = not show_profile
	_apply_tab_style(profile_tab, show_profile, C_TEXT_MAIN)
	_apply_tab_style(security_tab, not show_profile, C_TEXT_MAIN)


func _set_profile_form_enabled(enabled: bool) -> void:
	name_input.editable = enabled
	choose_avatar_button.disabled = not enabled
	edit_avatar_button.disabled = not enabled
	save_profile_button.disabled = not enabled
	save_profile_button.text = "Lưu thay đổi" if enabled else "Đang lưu..."


func _set_password_form_enabled(enabled: bool) -> void:
	old_password.editable = enabled
	new_password.editable = enabled
	confirm_password.editable = enabled
	change_password_button.disabled = not enabled
	change_password_button.text = "Đổi mật khẩu" if enabled else "Đang cập nhật..."


func _show_feedback(label: Label, message: String, success: bool) -> void:
	label.text = message
	label.add_theme_color_override("font_color", C_PASTEL_GREEN_TXT if success else C_PASTEL_RED_TXT)
	label.visible = true


func _build_theme() -> void:
	settings_card.add_theme_stylebox_override("panel", _main_card_style())
	state_card.add_theme_stylebox_override("panel", _flat(Color(1, 0.99, 0.96, 0.96), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.30), 16, 1))
	profile_section.add_theme_stylebox_override("panel", _section_style(C_TEXT_MAIN))
	security_section.add_theme_stylebox_override("panel", _section_style(C_TEXT_MAIN))
	avatar_picker.add_theme_stylebox_override("panel", _flat(C_PASTEL_GREEN_BG, C_BORDER, 14, 1))
	avatar_frame.add_theme_stylebox_override("panel", _avatar_style())
	title_label.add_theme_font_override("font", _font_display())
	title_label.add_theme_color_override("font_color", C_TEXT_MAIN)
	preview_name.add_theme_font_override("font", _font_display())
	preview_name.add_theme_color_override("font_color", C_TEXT_MAIN)
	for label: Label in [name_label, avatar_title]:
		label.add_theme_font_override("font", _font_bold())
		label.add_theme_color_override("font_color", C_TEXT_MAIN)
	for label: Label in [preview_email, preview_code, avatar_hint, selected_file, security_hint, profile_feedback, password_feedback, state_label]:
		label.add_theme_font_override("font", _font_regular())
	preview_email.add_theme_color_override("font_color", C_TEXT_MUTED)
	preview_code.add_theme_color_override("font_color", C_PASTEL_YELLOW_TXT)
	avatar_hint.add_theme_color_override("font_color", C_TEXT_MUTED)
	selected_file.add_theme_color_override("font_color", C_TEXT_MUTED)
	security_hint.add_theme_color_override("font_color", C_TEXT_MUTED)
	state_label.add_theme_color_override("font_color", C_PASTEL_GREEN_TXT)
	state_icon.texture = _icon("hourglass")
	state_icon.modulate = C_GOLD
	_style_back_button(back_button, C_TEXT_MAIN)

	_set_icon_button(retry_button, "rotate-cw", C_TEXT_MAIN)
	_set_icon_button(edit_avatar_button, "camera", Color.WHITE, C_TEXT_MAIN)
	choose_avatar_button.icon = _icon("camera")
	choose_avatar_button.add_theme_constant_override("icon_max_width", 18)
	_style_secondary_button(choose_avatar_button)
	for field: LineEdit in [name_input, old_password, new_password, confirm_password]:
		_style_field(field)
	_style_primary_button(save_profile_button, C_TEXT_MAIN)
	_style_primary_button(change_password_button, C_TEXT_MAIN)


func _apply_responsive_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var safe := _safe_insets()
	var mobile := viewport_size.x < 760.0 or OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")
	var side := 12.0 if mobile else 30.0
	var usable_width := viewport_size.x - safe.x - safe.z - side * 2.0
	content.custom_minimum_size.x = minf(740.0, maxf(360.0, usable_width))
	content_margin.add_theme_constant_override("margin_left", int(safe.x + side))
	content_margin.add_theme_constant_override("margin_right", int(safe.z + side))
	content_margin.add_theme_constant_override("margin_top", 112 if mobile else 120) # Push content below floating back button
	content_margin.add_theme_constant_override("margin_bottom", int(safe.w + (12 if mobile else 20)))
	card_margin.add_theme_constant_override("margin_left", 14 if mobile else 22)
	card_margin.add_theme_constant_override("margin_right", 14 if mobile else 22)
	card_margin.add_theme_constant_override("margin_top", 16 if mobile else 20)
	card_margin.add_theme_constant_override("margin_bottom", 18 if mobile else 24)
	title_label.add_theme_font_size_override("font_size", 30 if mobile else 40) # Larger size
	preview_name.add_theme_font_size_override("font_size", 24 if mobile else 28)
	avatar_stack.custom_minimum_size = Vector2(100, 100)
	for label: Label in [name_label, avatar_title]:
		label.add_theme_font_size_override("font_size", 14 if mobile else 16)
	for label: Label in [preview_email, preview_code]:
		label.add_theme_font_size_override("font_size", 14 if mobile else 16)
	for label: Label in [avatar_hint, security_hint]:
		label.add_theme_font_size_override("font_size", 12 if mobile else 14)
	for label: Label in [selected_file, profile_feedback, password_feedback, state_label]:
		label.add_theme_font_size_override("font_size", 13 if mobile else 15)
	for btn: Button in [profile_tab, security_tab]:
		btn.add_theme_font_size_override("font_size", 15 if mobile else 17)
		btn.custom_minimum_size.y = 52.0 if mobile else 60.0
	for btn: Button in [choose_avatar_button]:
		btn.add_theme_font_size_override("font_size", 14 if mobile else 16)
		btn.custom_minimum_size.y = 48.0 if mobile else 56.0
	for btn: Button in [save_profile_button, change_password_button]:
		btn.add_theme_font_size_override("font_size", 16 if mobile else 18)
		btn.custom_minimum_size.y = 56.0 if mobile else 64.0
	for field: LineEdit in [name_input, old_password, new_password, confirm_password]:
		field.add_theme_font_size_override("font_size", 15 if mobile else 17)
		field.custom_minimum_size.y = 56.0 if mobile else 64.0


func _safe_insets() -> Vector4:
	var viewport_size := get_viewport_rect().size
	var screen_size := Vector2(DisplayServer.screen_get_size())
	var safe_area := DisplayServer.get_display_safe_area()
	if screen_size.x <= 0.0 or screen_size.y <= 0.0 or safe_area.size.x <= 0:
		return Vector4.ZERO
	var scale_x := viewport_size.x / screen_size.x
	var scale_y := viewport_size.y / screen_size.y
	return Vector4(
		maxf(0.0, float(safe_area.position.x) * scale_x),
		maxf(0.0, float(safe_area.position.y) * scale_y),
		maxf(0.0, float(screen_size.x - safe_area.end.x) * scale_x),
		maxf(0.0, float(screen_size.y - safe_area.end.y) * scale_y)
	)


func _show_state(icon_name: String, message: String, can_retry: bool) -> void:
	state_icon.texture = _icon(icon_name)
	state_label.text = message
	retry_button.visible = can_retry
	state_card.visible = true


func _animate_in() -> void:
	settings_card.modulate.a = 0.0
	if is_inside_tree():
		await get_tree().process_frame
	settings_card.position.y += 8.0
	var target_y := settings_card.position.y - 8.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(settings_card, "modulate:a", 1.0, 0.20)
	tween.tween_property(settings_card, "position:y", target_y, 0.28).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)


func _go_back() -> void:
	var return_scene := str(SecureDataManager.data.get("navigation_return_scene", ""))
	if return_scene == "res://scenes/VirtualMusicRoom.tscn":
		SecureDataManager.data.erase("navigation_return_scene")
		SecureDataManager.save_data()
		get_tree().change_scene_to_file(return_scene)
		return
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


func _is_web_url(value: String) -> bool:
	return value.begins_with("https://") or value.begins_with("http://")


func _format_file_size(byte_count: int) -> String:
	return "%.1f MB" % (float(byte_count) / 1048576.0) if byte_count >= 1048576 else "%.0f KB" % (float(byte_count) / 1024.0)


func _style_field(field: LineEdit) -> void:
	field.add_theme_font_override("font", _font_regular())
	field.add_theme_color_override("font_color", C_TEXT_MAIN)
	field.add_theme_color_override("font_placeholder_color", Color(C_TEXT_MUTED.r, C_TEXT_MUTED.g, C_TEXT_MUTED.b, 0.72))
	field.add_theme_stylebox_override("normal", _flat(Color.WHITE, C_BORDER, 12, 1))
	field.add_theme_stylebox_override("focus", _flat(Color.WHITE, C_GOLD, 12, 2))
	field.add_theme_stylebox_override("read_only", _flat(C_BG_WARM, C_BORDER, 12, 1))


func _style_primary_button(button: Button, _color: Color) -> void:
	button.add_theme_font_override("font", _font_bold())
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _flat(C_TEXT_MAIN, C_TEXT_MAIN, 12, 0))
	button.add_theme_stylebox_override("hover", _flat(C_TEXT_MAIN.lightened(0.15), C_TEXT_MAIN, 12, 0))
	button.add_theme_stylebox_override("pressed", _flat(C_TEXT_MAIN.darkened(0.15), C_TEXT_MAIN, 12, 0))


func _style_secondary_button(button: Button) -> void:
	button.add_theme_font_override("font", _font_bold())
	button.add_theme_color_override("font_color", C_TEXT_MAIN)
	button.add_theme_color_override("icon_normal_color", C_TEXT_MAIN)
	button.add_theme_stylebox_override("normal", _flat(C_CARD_BG, C_BORDER, 12, 1))
	button.add_theme_stylebox_override("hover", _flat(C_BG_WARM, C_BORDER, 12, 1))
	button.add_theme_stylebox_override("pressed", _flat(C_BORDER, C_BORDER, 12, 1))


func _apply_tab_style(button: Button, selected: bool, accent: Color) -> void:
	button.add_theme_font_override("font", _font_bold())
	button.add_theme_color_override("font_color", Color.WHITE if selected else C_TEXT_MUTED)
	button.add_theme_color_override("font_hover_color", Color.WHITE if selected else C_TEXT_MAIN)
	var bg := C_TEXT_MAIN if selected else C_CARD_BG
	var brd := C_TEXT_MAIN if selected else C_BORDER
	button.add_theme_stylebox_override("normal", _flat(bg, brd, 14, 1))
	button.add_theme_stylebox_override("hover", _flat(C_TEXT_MAIN.lightened(0.12) if selected else C_BG_WARM, brd, 14, 1))
	button.add_theme_stylebox_override("pressed", _flat(C_TEXT_MAIN.darkened(0.12) if selected else C_BORDER, brd, 14, 1))


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


func _set_icon_button(button: Button, icon_name: String, color: Color, background := Color.TRANSPARENT) -> void:
	button.icon = _icon(icon_name)
	button.expand_icon = true
	button.add_theme_color_override("icon_normal_color", color)
	button.add_theme_color_override("icon_hover_color", color.lightened(0.08))
	button.add_theme_color_override("icon_pressed_color", color.darkened(0.08))
	button.add_theme_constant_override("icon_max_width", 20)
	var bg := background if background != Color.TRANSPARENT else Color(color.r, color.g, color.b, 0.055)
	button.add_theme_stylebox_override("normal", _flat(bg, Color(color.r, color.g, color.b, 0.22), 15, 1))
	button.add_theme_stylebox_override("hover", _flat(bg.lightened(0.08), Color(color.r, color.g, color.b, 0.40), 15, 1))
	button.add_theme_stylebox_override("pressed", _flat(bg.darkened(0.08), color, 15, 1))


func _icon(icon_name: String) -> Texture2D:
	return load("res://assets/textures/lucide/%s.svg" % icon_name) as Texture2D


func _font_display() -> Font:
	return load("res://assets/fonts/Lora-Bold.ttf") as Font


func _font_bold() -> Font:
	return load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font


func _font_regular() -> Font:
	return load("res://assets/fonts/BeVietnamPro-Regular.ttf") as Font


func _main_card_style() -> StyleBoxFlat:
	var style := _flat(Color(0.99, 0.99, 0.98, 0.85), Color(0, 0, 0, 0.08), 20, 1)
	style.shadow_color = Color(0, 0, 0, 0.02)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 4)
	return style


func _section_style(accent: Color) -> StyleBoxFlat:
	return _flat(C_CARD_BG, C_BORDER, 16, 1)


func _avatar_style() -> StyleBoxFlat:
	var style := _flat(Color.WHITE, C_BORDER, 38, 2)
	style.shadow_color = Color(0, 0, 0, 0.04)
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
