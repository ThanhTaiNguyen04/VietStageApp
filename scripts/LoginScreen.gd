extends Control

# ── Palette đỏ sẫm cổ trang ──────────────────────────────────────────────────
const C_GOLD        := Color(0.95, 0.72, 0.18, 1.0)
const C_GOLD_LT     := Color(1.00, 0.87, 0.45, 1.0)
const C_GOLD_DARK   := Color(0.06, 0.02, 0.00, 1.0)
const C_WHITE       := Color(1.00, 1.00, 1.00, 1.00)
const C_WHITE_DIM   := Color(1.00, 1.00, 1.00, 0.40)
const C_ERR         := Color(0.98, 0.32, 0.22, 1.0)
const C_GREEN_OK    := Color(0.25, 0.88, 0.55, 1.0)
# Google brand
const C_G_BLUE      := Color(0.26, 0.52, 0.96, 1.0)
# Màu hạt hoạt hình
const C_EMBER_1     := Color(0.98, 0.78, 0.22)   # vàng ánh lửa
const C_EMBER_2     := Color(0.95, 0.45, 0.10)   # cam đỏ
const C_PETAL_1     := Color(0.85, 0.20, 0.12)   # đỏ sẫm cổ
const C_PETAL_2     := Color(0.70, 0.12, 0.08)   # đỏ thẫm

const FP := "Center/Card/CardMargin/ContentVBox/"

@onready var logo_rect      : TextureRect    = get_node(FP + "LogoVBox/LogoRect")
@onready var app_name       : Label          = get_node(FP + "LogoVBox/AppName")
@onready var app_sub        : Label          = get_node(FP + "LogoVBox/AppSub")
@onready var name_edit     : LineEdit       = get_node(FP + "NameEdit")
@onready var gap_name      : Control        = get_node(FP + "GapName")
@onready var email_edit     : LineEdit       = get_node(FP + "EmailEdit")
@onready var error_label    : Label          = get_node(FP + "ErrorLabel")
@onready var sign_in_btn    : Button         = get_node(FP + "SignInBtn")
@onready var toggle_mode_btn: Button         = get_node(FP + "ToggleModeBtn")

var is_register_mode := false
@onready var google_btn     : Button         = get_node(FP + "SocialRow/GoogleVBox/GoogleBtn")
@onready var guest_btn      : Button         = get_node(FP + "SocialRow/GuestVBox/GuestBtn")
@onready var or_label       : Label          = get_node(FP + "DivRow/OrLabel")
@onready var google_lbl     : Label          = get_node(FP + "SocialRow/GoogleVBox/GoogleLbl")
@onready var guest_lbl      : Label          = get_node(FP + "SocialRow/GuestVBox/GuestLbl")
@onready var footer_lbl     : Label          = get_node(FP + "FooterLabel")
@onready var card           : PanelContainer = $Center/Card
@onready var particle_layer : Control        = $ParticleLayer

func _ready() -> void:
	name_edit.visible = false
	gap_name.visible = false
	_style_card()
	_style_all()
	_connect_all()
	_spawn_bg_particles()
	_animate_in()

	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()

# ── Entrance animation ─────────────────────────────────────────────────────────
func _animate_in() -> void:
	modulate.a   = 0.0
	card.scale   = Vector2(0.92, 0.92)
	card.modulate.a = 0.0

	var t := create_tween().set_parallel(true)
	t.tween_property(self, "modulate:a",    1.0,        0.50)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(card, "scale",         Vector2.ONE, 0.60).set_delay(0.10)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(card, "modulate:a",    1.0,         0.50).set_delay(0.10)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.chain().tween_callback(_start_logo_float)

func _start_logo_float() -> void:
	if not is_instance_valid(logo_rect): return
	var lp := create_tween().set_loops()
	lp.tween_property(logo_rect, "position:y", -6.0, 2.5)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	lp.tween_property(logo_rect, "position:y",  0.0, 2.5)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _on_viewport_size_changed() -> void:
	var size = get_viewport().size
	var is_mobile = size.x < size.y or size.x < 768
	
	var content_vbox := get_node(FP) as VBoxContainer
	var card_margin := $Center/Card/CardMargin as MarginContainer
	
	if is_mobile:
		content_vbox.custom_minimum_size = Vector2(0, content_vbox.custom_minimum_size.y)
		card.custom_minimum_size = Vector2(size.x - 32, card.custom_minimum_size.y)
		card_margin.add_theme_constant_override("margin_left", 20)
		card_margin.add_theme_constant_override("margin_right", 20)
		card_margin.add_theme_constant_override("margin_top", 32)
		card_margin.add_theme_constant_override("margin_bottom", 32)
		app_name.add_theme_font_size_override("font_size", 42)
	else:
		content_vbox.custom_minimum_size = Vector2(460, content_vbox.custom_minimum_size.y)
		card.custom_minimum_size = Vector2(0, card.custom_minimum_size.y)
		card_margin.add_theme_constant_override("margin_left", 64)
		card_margin.add_theme_constant_override("margin_right", 64)
		card_margin.add_theme_constant_override("margin_top", 52)
		card_margin.add_theme_constant_override("margin_bottom", 52)
		app_name.add_theme_font_size_override("font_size", 58)

# ── Hệ thống hạt hoạt hình nền ────────────────────────────────────────────────
func _spawn_bg_particles() -> void:
	var vp := get_viewport_rect().size

	# 14 hạt ánh lửa nhỏ (vàng/cam)
	for _i in range(14):
		var sz    := randf_range(5.0, 16.0)
		var t_col := C_EMBER_1.lerp(C_EMBER_2, randf())
		t_col.a   = randf_range(0.10, 0.30)
		_create_particle(vp, sz, t_col, randf_range(3.5, 7.0), randf_range(0.0, 7.0))

	# 8 cánh hoa lớn hơn (đỏ sẫm mờ)
	for _i in range(8):
		var sz    := randf_range(28.0, 65.0)
		var t_col := C_PETAL_1.lerp(C_PETAL_2, randf())
		t_col.a   = randf_range(0.05, 0.14)
		_create_particle(vp, sz, t_col, randf_range(6.0, 12.0), randf_range(0.0, 9.0))

	# 5 hạt ánh vàng lớn (hào quang)
	for _i in range(5):
		var sz    := randf_range(70.0, 130.0)
		var t_col := C_GOLD
		t_col.a   = randf_range(0.02, 0.07)
		_create_particle(vp, sz, t_col, randf_range(9.0, 16.0), randf_range(0.0, 12.0))

func _create_particle(vp: Vector2, sz: float, col: Color, dur: float, delay: float) -> void:
	var p  := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	var r := int(sz / 2.0)
	sb.corner_radius_top_left     = r; sb.corner_radius_top_right    = r
	sb.corner_radius_bottom_left  = r; sb.corner_radius_bottom_right = r
	sb.border_width_left = 0; sb.border_width_right  = 0
	sb.border_width_top  = 0; sb.border_width_bottom = 0
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(sz, sz)
	p.size                = Vector2(sz, sz)
	p.mouse_filter        = Control.MOUSE_FILTER_IGNORE
	# Bắt đầu ngẫu nhiên trên/dưới màn hình để không đồng đều
	var sx := randf_range(0.0, vp.x)
	var sy := randf_range(vp.y * 0.35, vp.y + sz + 20.0)
	p.position    = Vector2(sx, sy)
	p.modulate.a  = 0.0
	particle_layer.add_child(p)
	_animate_particle(p, sx, sy, dur, delay, vp)

func _animate_particle(p: Panel, sx: float, sy: float, dur: float, delay: float, vp: Vector2) -> void:
	if not is_instance_valid(p) or not is_instance_valid(particle_layer):
		return
	var drift  := randf_range(-55.0, 55.0)
	var end_y  := -p.size.y - 30.0

	var t := create_tween().set_parallel(true)

	# Fade vào (20% đầu)
	t.tween_property(p, "modulate:a", 1.0, dur * 0.22).set_delay(delay)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Bay lên
	t.tween_property(p, "position:y", end_y, dur).set_delay(delay)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Lắc lư nửa đầu
	t.tween_property(p, "position:x", sx + drift, dur * 0.50).set_delay(delay)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Lắc lư nửa sau (về phía kia)
	t.tween_property(p, "position:x", sx + drift * 0.40, dur * 0.50).set_delay(delay + dur * 0.50)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Fade ra (25% cuối)
	t.tween_property(p, "modulate:a", 0.0, dur * 0.28).set_delay(delay + dur * 0.72)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Khi xong: reset lại vị trí và loop
	t.chain().tween_callback(func() -> void:
		if not is_instance_valid(p) or not is_instance_valid(particle_layer): return
		var new_sx := randf_range(0.0, vp.x)
		p.position   = Vector2(new_sx, sy + randf_range(-40.0, 40.0))
		p.modulate.a = 0.0
		_animate_particle(p, new_sx, p.position.y, dur * randf_range(0.85, 1.15), 0.0, vp)
	)

# ── Card kính sáng Alabaster Glass ───────────────────────────────────────────
func _style_card() -> void:
	var cs := StyleBoxFlat.new()
	cs.bg_color              = Color(1.0, 1.0, 1.0, 0.88)
	cs.border_color          = Color(0.77, 0.58, 0.15, 0.25)
	cs.border_width_left     = 1; cs.border_width_right  = 1
	cs.border_width_top      = 1; cs.border_width_bottom = 1
	cs.corner_radius_top_left     = 28; cs.corner_radius_top_right    = 28
	cs.corner_radius_bottom_left  = 28; cs.corner_radius_bottom_right = 28
	cs.shadow_size   = 40
	cs.shadow_color  = Color(0.13, 0.08, 0.05, 0.12)
	cs.shadow_offset = Vector2(0, 10)
	card.add_theme_stylebox_override("panel", cs)
	card.pivot_offset = card.size / 2.0
	card.resized.connect(func() -> void: card.pivot_offset = card.size / 2.0)

# ── Tô màu toàn bộ UI theo Cream/Espresso ─────────────────────────────────────
func _style_all() -> void:
	app_name.add_theme_color_override("font_color",    C_PETAL_2) # đỏ thẫm sơn mài
	app_sub.add_theme_color_override("font_color",     Color(0.43, 0.38, 0.33, 1.0))
	or_label.add_theme_color_override("font_color",    Color(0.43, 0.38, 0.33, 1.0))
	footer_lbl.add_theme_color_override("font_color",  Color(0.13, 0.08, 0.05, 0.35))
	error_label.add_theme_color_override("font_color", C_ERR)
	google_lbl.add_theme_color_override("font_color",  Color(0.43, 0.38, 0.33, 1.0))
	guest_lbl.add_theme_color_override("font_color",   Color(0.43, 0.38, 0.33, 1.0))

	# Name & Email: Light warm glass pill
	var ei_n := _pill(Color(0.95, 0.93, 0.89, 0.60),  Color(0.13, 0.08, 0.05, 0.15), 28)
	var ei_f := _pill(Color(1.00, 1.00, 1.00, 1.00),  Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.88), 28)
	ei_f.shadow_size = 12; ei_f.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.18)
	
	email_edit.add_theme_stylebox_override("normal", ei_n)
	email_edit.add_theme_stylebox_override("focus",  ei_f)
	email_edit.add_theme_color_override("font_color",        Color(0.13, 0.08, 0.05, 1.0))
	email_edit.add_theme_color_override("placeholder_color", Color(0.43, 0.38, 0.33, 0.55))
	email_edit.add_theme_color_override("caret_color",       C_GOLD)

	name_edit.add_theme_stylebox_override("normal", ei_n)
	name_edit.add_theme_stylebox_override("focus",  ei_f)
	name_edit.add_theme_color_override("font_color",        Color(0.13, 0.08, 0.05, 1.0))
	name_edit.add_theme_color_override("placeholder_color", Color(0.43, 0.38, 0.33, 0.55))
	name_edit.add_theme_color_override("caret_color",       C_GOLD)

	# Nút Đăng nhập: Vàng đồng rực rỡ
	var si_n := _pill(C_GOLD,                 Color(0,0,0,0), 28)
	var si_h := _pill(C_GOLD_LT,              Color(0,0,0,0), 28)
	var si_p := _pill(C_GOLD.darkened(0.14),  Color(0,0,0,0), 28)
	si_n.shadow_size = 16; si_n.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35)
	si_h.shadow_size = 24; si_h.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.48)
	sign_in_btn.add_theme_stylebox_override("normal",  si_n)
	sign_in_btn.add_theme_stylebox_override("hover",   si_h)
	sign_in_btn.add_theme_stylebox_override("pressed", si_p)
	sign_in_btn.add_theme_stylebox_override("focus",   _pill(Color(0,0,0,0), Color(0,0,0,0), 0))
	sign_in_btn.add_theme_color_override("font_color",         C_GOLD_DARK)
	sign_in_btn.add_theme_color_override("font_hover_color",   C_GOLD_DARK)
	sign_in_btn.add_theme_color_override("font_pressed_color", C_GOLD_DARK)

	# Nút Chuyển chế độ: Flat link button
	toggle_mode_btn.add_theme_color_override("font_color",         Color(0.43, 0.38, 0.33, 1.0))
	toggle_mode_btn.add_theme_color_override("font_hover_color",   C_PETAL_1)
	toggle_mode_btn.add_theme_color_override("font_pressed_color", C_PETAL_2)
	toggle_mode_btn.add_theme_stylebox_override("normal",  _pill(Color(0,0,0,0), Color(0,0,0,0), 0))
	toggle_mode_btn.add_theme_stylebox_override("hover",   _pill(Color(0,0,0,0), Color(0,0,0,0), 0))
	toggle_mode_btn.add_theme_stylebox_override("pressed", _pill(Color(0,0,0,0), Color(0,0,0,0), 0))
	toggle_mode_btn.add_theme_stylebox_override("focus",   _pill(Color(0,0,0,0), Color(0,0,0,0), 0))

	# Social buttons: Social pills sáng màu
	_style_social(google_btn)
	_style_social(guest_btn)
	# Google: chữ G xanh đặc trưng
	google_btn.add_theme_color_override("font_color",         C_G_BLUE)
	google_btn.add_theme_color_override("font_hover_color",   C_G_BLUE.lightened(0.1))
	google_btn.add_theme_color_override("font_pressed_color", C_G_BLUE.darkened(0.1))
	# Guest: Nâu sẫm
	guest_btn.add_theme_color_override("font_color",          Color(0.13, 0.08, 0.05, 1.0))
	guest_btn.add_theme_color_override("font_hover_color",    Color(0.13, 0.08, 0.05, 1.0))
	guest_btn.add_theme_color_override("font_pressed_color",  Color(0.13, 0.08, 0.05, 0.75))

func _style_social(btn: Button) -> void:
	var n := _pill(Color(0.95, 0.93, 0.89, 0.60),  Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.20), 18)
	var h := _pill(Color(0.95, 0.93, 0.89, 0.90),  Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.36), 18)
	var p := _pill(Color(0.90, 0.87, 0.82, 1.00),  Color(0,0,0,0), 18)
	n.shadow_size = 6; n.shadow_color = Color(0.13, 0.08, 0.05, 0.08)
	h.shadow_size = 10; h.shadow_color = Color(0.13, 0.08, 0.05, 0.12)
	btn.add_theme_stylebox_override("normal",  n)
	btn.add_theme_stylebox_override("hover",   h)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_stylebox_override("focus",   _pill(Color(0,0,0,0), Color(0,0,0,0), 0))

# ── Kết nối sự kiện ──────────────────────────────────────────────────────────
func _connect_all() -> void:
	sign_in_btn.pressed.connect(_on_sign_in)
	email_edit.text_submitted.connect(func(_s: String) -> void: _on_sign_in())
	name_edit.text_submitted.connect(func(_s: String) -> void: _on_sign_in())
	toggle_mode_btn.pressed.connect(_on_toggle_mode)
	google_btn.pressed.connect(_on_google_pressed)
	guest_btn.pressed.connect(_on_guest_pressed)
	_make_bouncy(sign_in_btn)
	_make_bouncy(google_btn)
	_make_bouncy(guest_btn)
	_make_bouncy(toggle_mode_btn)

func _on_toggle_mode() -> void:
	is_register_mode = not is_register_mode
	if is_register_mode:
		name_edit.visible = true
		gap_name.visible = true
		name_edit.modulate.a = 0.0
		name_edit.scale = Vector2(0.95, 0.95)
		var t := create_tween().set_parallel(true)
		t.tween_property(name_edit, "modulate:a", 1.0, 0.15)
		t.tween_property(name_edit, "scale", Vector2.ONE, 0.15)
		sign_in_btn.text = "ĐĂNG KÝ"
		toggle_mode_btn.text = "Đã có tài khoản? Đăng nhập"
	else:
		var t := create_tween().set_parallel(true)
		t.tween_property(name_edit, "modulate:a", 0.0, 0.1)
		t.tween_property(name_edit, "scale", Vector2(0.95, 0.95), 0.1)
		t.chain().tween_callback(func() -> void:
			name_edit.visible = false
			gap_name.visible = false
		)
		sign_in_btn.text = "ĐĂNG NHẬP"
		toggle_mode_btn.text = "Chưa có tài khoản? Đăng ký ngay"

func _on_sign_in() -> void:
	var em := email_edit.text.strip_edges()
	if em.length() < 5 or not "@" in em:
		error_label.add_theme_color_override("font_color", C_ERR)
		error_label.text = "Vui lòng nhập đúng định dạng email"
		_shake(email_edit)
		return
	
	if is_register_mode:
		var nm := name_edit.text.strip_edges()
		if nm.length() < 2:
			error_label.add_theme_color_override("font_color", C_ERR)
			error_label.text = "Tên hiển thị phải có ít nhất 2 ký tự"
			_shake(name_edit)
			return
		SecureDataManager.data["user_name"] = nm
		SecureDataManager.data["user_email"] = em
		SecureDataManager.save_data()
	else:
		# Login mode: check if we already have this user registered.
		# If yes, keep their name. If not, auto-register them using their email prefix!
		var saved_email = SecureDataManager.data.get("user_email", "")
		if em.to_lower() == saved_email.to_lower():
			# Keep existing user name
			pass
		else:
			# Auto-register new email: prefix from email
			var prefix := em.split("@")[0]
			var nm := prefix.capitalize()
			SecureDataManager.data["user_name"] = nm
			SecureDataManager.data["user_email"] = em
			SecureDataManager.save_data()
			
	error_label.add_theme_color_override("font_color", C_GREEN_OK)
	error_label.text = "Chào mừng!"
	sign_in_btn.disabled = true
	email_edit.editable  = false
	if is_register_mode:
		name_edit.editable = false
	_go_main()

func _on_google_pressed() -> void:
	SecureDataManager.data["user_name"] = "Google User"
	SecureDataManager.data["user_email"] = "google.user@gmail.com"
	SecureDataManager.save_data()
	_go_main()

func _on_guest_pressed() -> void:
	SecureDataManager.data["user_name"] = "Khách"
	SecureDataManager.data["user_email"] = "khach@vietstage.vn"
	SecureDataManager.save_data()
	_go_main()

func _go_main() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.40).set_trans(Tween.TRANS_CUBIC)
	t.tween_callback(func() -> void:
		get_tree().change_scene_to_file("res://scenes/InstrumentSelect.tscn"))

# ── Hiệu ứng lắc khi nhập sai ────────────────────────────────────────────────
func _shake(node: Control) -> void:
	var ox := node.position.x
	var t  := create_tween()
	for d in [-12.0, 12.0, -7.0, 7.0, -3.0, 3.0, 0.0]:
		t.tween_property(node, "position:x", ox + d, 0.045).set_trans(Tween.TRANS_SINE)

# ── Helpers ───────────────────────────────────────────────────────────────────
func _pill(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color    = bg
	s.border_color = border
	s.border_width_left   = 1; s.border_width_right  = 1
	s.border_width_top    = 1; s.border_width_bottom = 1
	s.corner_radius_top_left     = radius; s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius; s.corner_radius_bottom_right = radius
	return s

func _make_bouncy(btn: Button) -> void:
	btn.pivot_offset = btn.size / 2.0
	btn.resized.connect(func() -> void: btn.pivot_offset = btn.size / 2.0)
	btn.mouse_entered.connect(func() -> void:
		create_tween().tween_property(btn, "scale", Vector2(1.06, 1.06), 0.14)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
	btn.mouse_exited.connect(func() -> void:
		create_tween().tween_property(btn, "scale", Vector2.ONE, 0.14)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
	btn.button_down.connect(func() -> void:
		create_tween().tween_property(btn, "scale", Vector2(0.93, 0.93), 0.08)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT))
	btn.button_up.connect(func() -> void:
		var target := Vector2(1.06, 1.06) if btn.is_hovered() else Vector2.ONE
		create_tween().tween_property(btn, "scale", target, 0.14)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
