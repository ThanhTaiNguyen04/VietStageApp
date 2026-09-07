extends Node
## Account dropdown for curriculum pages, using the roadmap's menu layout.
var pill: Control
var overlay: Control
var panel: PanelContainer
var small_avatar: TextureRect
var large_avatar: TextureRect
var api: Node
var request: HTTPRequest
var requested_url := ""
var level := 1

func _ready() -> void:
	small_avatar = pill.find_child("AvatarIcon", true, false) as TextureRect
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	overlay = preload("res://scenes/components/CurriculumAccountMenu.tscn").instantiate()
	layer.add_child(overlay)
	panel = overlay.get_node("AccountPanel")
	large_avatar = overlay.find_child("LargeAvatar", true, false) as TextureRect
	_set_avatar(small_avatar.texture)
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.995, 0.99, 0.985, 0.98)
	background.border_color = Color("#e2d8c9")
	background.set_border_width_all(2)
	background.set_corner_radius_all(20)
	background.shadow_size = 20
	background.shadow_color = Color(0.08, 0.07, 0.05, 0.16)
	panel.add_theme_stylebox_override("panel", background)
	var bold := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	var regular := load("res://assets/fonts/BeVietnamPro-Regular.ttf") as Font
	for label_name in ["HeaderName", "HeaderMeta", "OnlineLabel"]:
		var label := overlay.find_child(label_name, true, false) as Label
		label.add_theme_font_override("font", regular if label_name == "HeaderMeta" else bold)
		label.add_theme_color_override("font_color", Color("#16a34a") if label_name == "OnlineLabel" else Color("#64748b") if label_name == "HeaderMeta" else Color("#0f172a"))
	for action in [["ProfileAction", "user", "AccountScreen"], ["AchievementAction", "trophy", "ProgressScreen"], ["SettingsAction", "settings", "AccountSettings"], ["LogoutAction", "log-out", "logout"]]:
		var button := overlay.find_child(action[0], true, false) as Button
		_style_account_action(button, action[1], action[2] == "logout")
		button.add_theme_font_override("font", bold)
		button.pressed.connect(_navigate.bind(action[2]))
	var dismiss := overlay.get_node("DismissButton") as Button
	for state in ["normal", "hover", "pressed"]:
		dismiss.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	dismiss.pressed.connect(overlay.hide)
	var trigger := pill.get_node("TriggerButton") as Button
	trigger.pressed.connect(_toggle)
	get_viewport().size_changed.connect(_layout)
	api = preload("res://scripts/ApiClient.gd").new()
	add_child(api)
	request = HTTPRequest.new()
	request.timeout = 15.0
	add_child(request)
	request.request_completed.connect(_avatar_loaded)
	_update_identity()
	_load_avatar()
	_refresh()

func _update_identity() -> void:
	var names := {"dan_tranh": "Đàn Tranh", "dan_bau": "Đàn Bầu", "sao_truc": "Sáo Trúc", "trong_chau": "Trống Chầu"}
	var name_label := overlay.find_child("HeaderName", true, false) as Label
	name_label.text = str(SecureDataManager.data.get("user_name", "Học viên VietStage"))
	var meta := overlay.find_child("HeaderMeta", true, false) as Label
	meta.text = "Cấp độ %d · Đang học %s" % [level, names.get(str(SecureDataManager.data.get("selected_instrument", "dan_tranh")), "Đàn Tranh")]

func _refresh() -> void:
	var response: Dictionary = await api.get_me()
	if api._is_success(response):
		var profile: Dictionary = response.get("body", {}).get("data", {})
		var full_name := str(profile.get("fullName", "")).strip_edges()
		if not full_name.is_empty():
			SecureDataManager.data["user_name"] = full_name
		SecureDataManager.data["user_avatar_url"] = str(profile.get("avatarUrl", "")).strip_edges()
		SecureDataManager.save_data()
		_update_identity()
		_load_avatar()
	var summary: Dictionary = await api.get_my_progress_summary()
	if api._is_success(summary):
		var data: Dictionary = summary.get("body", {}).get("data", {})
		level = int(int(data.get("total_points", data.get("totalPoints", 0))) / 1000) + 1
		_update_identity()

func _load_avatar() -> void:
	var url := str(SecureDataManager.data.get("user_avatar_url", "")).strip_edges()
	if url.is_empty():
		url = str(SecureDataManager.data.get("user_avatar", "res://assets/textures/default_avatar.png"))
	if url.begins_with("res://"):
		_set_avatar(load(url) as Texture2D)
	elif (url.begins_with("https://") or url.begins_with("http://")) and url != requested_url:
		requested_url = url
		request.cancel_request()
		if request.request(url) != OK:
			requested_url = ""

func _avatar_loaded(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code < 200 or code >= 300:
		requested_url = ""
		return
	var image := Image.new()
	var error := image.load_png_from_buffer(body)
	if error != OK:
		error = image.load_jpg_from_buffer(body)
	if error != OK:
		error = image.load_webp_from_buffer(body)
	if error == OK:
		_set_avatar(ImageTexture.create_from_image(image))
	else:
		requested_url = ""

func _set_avatar(texture: Texture2D) -> void:
	if texture:
		small_avatar.texture = texture
		large_avatar.texture = texture

func _toggle() -> void:
	if overlay.visible:
		overlay.hide()
		return
	_update_identity()
	_layout()
	overlay.show()
	panel.scale = Vector2(0.96, 0.96)
	overlay.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(overlay, "modulate:a", 1.0, 0.16)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var width := minf(370.0, viewport_size.x - 32.0)
	panel.custom_minimum_size.x = width
	panel.size = Vector2(width, panel.get_combined_minimum_size().y)
	if viewport_size.x < 768 or viewport_size.x < viewport_size.y:
		panel.position = (viewport_size - panel.size) * 0.5
	else:
		panel.position = Vector2(viewport_size.x - width - 24.0, minf(pill.global_position.y + pill.size.y + 10.0, viewport_size.y - panel.size.y - 16.0))

func _navigate(destination: String) -> void:
	overlay.hide()
	if destination == "logout":
		var confirmation := ConfirmationDialog.new()
		confirmation.title = "Đăng xuất"
		confirmation.dialog_text = "Kết thúc phiên đăng nhập hiện tại?"
		confirmation.ok_button_text = "Đăng xuất"
		confirmation.cancel_button_text = "Ở lại"
		add_child(confirmation)
		confirmation.canceled.connect(confirmation.queue_free)
		confirmation.confirmed.connect(_logout)
		confirmation.popup_centered()
		return
	SecureDataManager.data["navigation_return_scene"] = get_tree().current_scene.scene_file_path
	SecureDataManager.save_data()
	get_tree().change_scene_to_file("res://scenes/" + destination + ".tscn")

func _logout() -> void:
	await api.logout()
	get_tree().change_scene_to_file("res://scenes/LoginScreen.tscn")

func _style_account_action(button: Button, icon_name: String, is_danger: bool) -> void:
	button.icon = load("res://assets/textures/lucide/" + icon_name + ".svg") as Texture2D
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 22)
	button.add_theme_constant_override("h_separation", 14)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var text_col := Color("#dc2626") if is_danger else Color("#1e293b")
	var text_h_col := Color("#b91c1c") if is_danger else Color("#0f172a")
	var icon_col := Color("#ef4444") if is_danger else Color("#d97706")
	var icon_h_col := Color("#dc2626") if is_danger else Color("#b45309")
	var hover_bg := Color("#fef2f2") if is_danger else Color("#f8fafc")
	var pressed_bg := Color("#fee2e2") if is_danger else Color("#f1f5f9")
	
	button.add_theme_color_override("font_color", text_col)
	button.add_theme_color_override("font_hover_color", text_h_col)
	button.add_theme_color_override("font_pressed_color", text_h_col)
	button.add_theme_color_override("icon_normal_color", icon_col)
	button.add_theme_color_override("icon_hover_color", icon_h_col)
	button.add_theme_color_override("icon_pressed_color", icon_h_col)
	
	var style_n := StyleBoxFlat.new()
	style_n.bg_color = Color.WHITE
	style_n.border_color = Color("#f1f5f9")
	style_n.set_border_width_all(1)
	style_n.set_corner_radius_all(14)
	style_n.content_margin_left = 14
	style_n.content_margin_right = 14
	style_n.content_margin_top = 8
	style_n.content_margin_bottom = 8
	
	var style_h := style_n.duplicate() as StyleBoxFlat
	style_h.bg_color = hover_bg
	style_h.border_color = Color("#ef4444") if is_danger else Color("#e2d8c9")
	
	var style_p := style_n.duplicate() as StyleBoxFlat
	style_p.bg_color = pressed_bg
	style_p.border_color = Color("#dc2626") if is_danger else Color("#cbd5e1")
	
	button.add_theme_stylebox_override("normal", style_n)
	button.add_theme_stylebox_override("hover", style_h)
	button.add_theme_stylebox_override("pressed", style_p)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
