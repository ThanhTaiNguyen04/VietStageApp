extends Control

# ── Palette đỏ sẫm cổ trang ──────────────────────────────────────────────────
const C_GOLD        := Color(0.77, 0.59, 0.15, 1.0)
const C_GOLD_LT     := Color(0.94, 0.80, 0.38, 1.0)
const C_GOLD_DARK   := Color(0.06, 0.02, 0.00, 1.0)
const C_WHITE       := Color(1.00, 1.00, 1.00, 1.00)
const C_WHITE_DIM   := Color(1.00, 1.00, 1.00, 0.40)
const C_ERR         := Color(0.98, 0.32, 0.22, 1.0)
const C_GREEN_OK    := Color(0.25, 0.88, 0.55, 1.0)
# Primary brand color is now Jade Green matching Dan Tranh
const C_PRIMARY     := Color(0.09, 0.25, 0.18, 1.0)
const C_PRIMARY_LT  := Color(0.14, 0.37, 0.26, 1.0)
const C_PRIMARY_DK  := Color(0.06, 0.16, 0.11, 1.0)
# Google brand
const C_G_BLUE      := Color(0.26, 0.52, 0.96, 1.0)
# Màu hạt hoạt hình (Lá trúc & Đom đóm vàng)
const C_EMBER_1     := Color(0.98, 0.78, 0.22)   # vàng ánh sáng
const C_EMBER_2     := Color(0.22, 0.72, 0.45)   # xanh mint
const C_PETAL_1     := Color(0.12, 0.42, 0.28)   # xanh lá trúc cổ
const C_PETAL_2     := Color(0.09, 0.27, 0.18)   # xanh lục bảo đậm

const FP := "Center/Card/CardMargin/ContentVBox/"
const ApiClientScript = preload("res://scripts/ApiClient.gd")
const AuthSessionStore = preload("res://scripts/AuthSession.gd")

enum AuthMode {
	LOGIN,
	REGISTER,
	VERIFY_REGISTRATION,
	FORGOT_PASSWORD,
	RESET_PASSWORD,
}

@onready var logo_rect      : TextureRect    = get_node(FP + "LogoVBox/LogoRect")
@onready var app_name       : Label          = get_node(FP + "LogoVBox/AppName")
@onready var app_sub        : Label          = get_node(FP + "LogoVBox/AppSub")
@onready var name_edit     : LineEdit       = get_node(FP + "NameEdit")
@onready var gap_name      : Control        = get_node(FP + "GapName")
@onready var email_edit     : LineEdit       = get_node(FP + "EmailEdit")
@onready var password_edit  : LineEdit       = get_node(FP + "PasswordEdit")
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

var _pass_visible   := false
var _forgot_btn     : Button = null
var _pass_toggle_btn: Button = null
var _welcome_lbl    : Label  = null
var _welcome_sub    : Label  = null
var _email_lbl      : Label  = null
var _pass_lbl       : Label  = null
var _name_lbl       : Label  = null
var _pass_row       : HBoxContainer = null
var _otp_edit       : LineEdit = null
var _new_password_edit: LineEdit = null
var _confirm_password_edit: LineEdit = null
var _api_client = null
var _auth_mode      := AuthMode.LOGIN
var _pending_email  := ""
var _pending_name   := ""

func _ready() -> void:
	AuthSessionStore.ensure_loaded()
	_api_client = ApiClientScript.new()
	add_child(_api_client)
	name_edit.visible = false
	gap_name.visible  = false
	_style_card()
	_style_all()
	_setup_extra_ui()   # thêm welcome header, input labels, forgot, eye toggle
	_connect_all()
	_set_auth_mode(AuthMode.LOGIN)
	_spawn_bg_particles()
	_animate_in()

	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()
	call_deferred("_try_restore_session")


# ── Setup extra UI elements (labels, forgot, eye toggle, welcome) ──────────────
func _setup_extra_ui() -> void:
	var vbox := get_node("Center/Card/CardMargin/ContentVBox") as VBoxContainer
	var font_body := load("res://assets/fonts/BeVietnamPro-Regular.ttf") as Font
	var title_font := load("res://assets/fonts/Lora-Bold.ttf") as Font
	
	if title_font:
		app_name.add_theme_font_override("font", title_font)
	app_name.add_theme_color_override("font_color", C_PRIMARY)
	app_sub.add_theme_color_override("font_color", C_PRIMARY_LT)
	var font_title := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font

	# — Welcome header (chèn ngay dưới LogoVBox) —
	_welcome_lbl = Label.new()
	_welcome_lbl.name = "WelcomeLabel"
	_welcome_lbl.text = "Chào mừng trở lại"
	_welcome_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_title:
		_welcome_lbl.add_theme_font_override("font", font_title)
	_welcome_lbl.add_theme_font_size_override("font_size", 24)
	_welcome_lbl.add_theme_color_override("font_color", Color("#0f172a")) # Slate-900
	var logo_vbox := get_node(FP + "LogoVBox")
	var logo_vbox_idx := logo_vbox.get_index()
	vbox.add_child(_welcome_lbl)
	vbox.move_child(_welcome_lbl, logo_vbox_idx + 1)

	# — Subtitle chào mừng —
	_welcome_sub = Label.new()
	_welcome_sub.name = "WelcomeSub"
	_welcome_sub.text = "Tiếp tục hành trình khám phá âm nhạc dân tộc"
	_welcome_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_welcome_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if font_body:
		_welcome_sub.add_theme_font_override("font", font_body)
	_welcome_sub.add_theme_font_size_override("font_size", 14)
	_welcome_sub.add_theme_color_override("font_color", Color("#64748b")) # Slate-500
	vbox.add_child(_welcome_sub)
	vbox.move_child(_welcome_sub, _welcome_lbl.get_index() + 1)

	# Spacing sau welcome sub
	var gap_w := Control.new(); gap_w.custom_minimum_size = Vector2(0, 14)
	vbox.add_child(gap_w); vbox.move_child(gap_w, _welcome_sub.get_index() + 1)

	# — Label “Tên hiển thị” trước name_edit —
	_name_lbl = Label.new()
	_name_lbl.text = "Tên hiển thị"
	_name_lbl.visible = false
	if font_body:
		_name_lbl.add_theme_font_override("font", font_body)
	_name_lbl.add_theme_font_size_override("font_size", 13)
	_name_lbl.add_theme_color_override("font_color", Color("#334155")) # Slate-700
	var name_idx := name_edit.get_index()
	vbox.add_child(_name_lbl)
	vbox.move_child(_name_lbl, name_idx)

	# — Label “Email” trước email_edit —
	_email_lbl = Label.new()
	_email_lbl.text = "Email"
	if font_body:
		_email_lbl.add_theme_font_override("font", font_body)
	_email_lbl.add_theme_font_size_override("font_size", 13)
	_email_lbl.add_theme_color_override("font_color", Color("#334155")) # Slate-700
	var email_idx := email_edit.get_index()
	vbox.add_child(_email_lbl)
	vbox.move_child(_email_lbl, email_idx)

	# — Label “Mật khẩu” + nút Quên mật khẩu cùng hàng —
	_pass_row = HBoxContainer.new()
	_pass_row.name = "PassLabelRow"
	_pass_lbl = Label.new()
	_pass_lbl.text = "Mật khẩu"
	_pass_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if font_body:
		_pass_lbl.add_theme_font_override("font", font_body)
	_pass_lbl.add_theme_font_size_override("font_size", 13)
	_pass_lbl.add_theme_color_override("font_color", Color("#334155")) # Slate-700

	_forgot_btn = Button.new()
	_forgot_btn.text = "Quên mật khẩu?"
	_forgot_btn.flat = true
	if font_body:
		_forgot_btn.add_theme_font_override("font", font_body)
	_forgot_btn.add_theme_font_size_override("font_size", 13)
	_forgot_btn.add_theme_color_override("font_color", Color("#d97706")) # Amber-600
	_forgot_btn.add_theme_color_override("font_hover_color", Color("#b45309"))
	_forgot_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_forgot_btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	_forgot_btn.add_theme_stylebox_override("hover",  StyleBoxEmpty.new())
	_forgot_btn.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	_forgot_btn.add_theme_stylebox_override("focus",  StyleBoxEmpty.new())
	_forgot_btn.add_theme_color_override("font_disabled_color", Color(C_PRIMARY.r, C_PRIMARY.g, C_PRIMARY.b, 0.45))
	_forgot_btn.pressed.connect(_on_forgot_password_pressed)
	_pass_row.add_child(_pass_lbl)
	_pass_row.add_child(_forgot_btn)
	var pass_idx := password_edit.get_index()
	vbox.add_child(_pass_row)
	vbox.move_child(_pass_row, pass_idx)

	# — Nút mắt hiện/ẩn mật khẩu (overlay trong password_edit) —
	_pass_toggle_btn = Button.new()
	_pass_toggle_btn.name = "PassToggle"
	_pass_toggle_btn.flat = true
	_pass_toggle_btn.layout_mode = 1
	_pass_toggle_btn.anchor_left   = 1.0
	_pass_toggle_btn.anchor_right  = 1.0
	_pass_toggle_btn.anchor_top    = 0.5
	_pass_toggle_btn.anchor_bottom = 0.5
	_pass_toggle_btn.offset_left   = -52
	_pass_toggle_btn.offset_right  = -8
	_pass_toggle_btn.offset_top    = -18
	_pass_toggle_btn.offset_bottom = 18
	_pass_toggle_btn.add_theme_stylebox_override("normal", _pill(Color(0,0,0,0), Color(0,0,0,0), 0))
	_pass_toggle_btn.add_theme_stylebox_override("hover",  _pill(Color(0,0,0,0), Color(0,0,0,0), 0))
	_pass_toggle_btn.add_theme_stylebox_override("disabled", _pill(Color(0,0,0,0), Color(0,0,0,0), 0))
	_pass_toggle_btn.add_theme_stylebox_override("focus",  _pill(Color(0,0,0,0), Color(0,0,0,0), 0))
	
	var eye_drawing := Control.new()
	eye_drawing.name = "EyeDrawing"
	eye_drawing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	eye_drawing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	eye_drawing.draw.connect(func() -> void:
		var size_vec: Vector2 = eye_drawing.size
		var center: Vector2 = size_vec / 2.0
		var color: Color = Color(0.13, 0.08, 0.05, 0.45)
		if _pass_toggle_btn.is_hovered():
			color = Color(0.13, 0.08, 0.05, 0.8)
		
		# Kích thước icon mắt vector
		var w: float = 18.0
		var h: float = 11.0
		var steps: int = 12
		var pts_top: PackedVector2Array = PackedVector2Array()
		var pts_bottom: PackedVector2Array = PackedVector2Array()
		
		for i in range(steps + 1):
			var t: float = float(i) / steps
			var px: float = center.x - w/2.0 + t * w
			var dx: float = (t - 0.5) * 2.0
			var dy: float = 1.0 - dx*dx # Parabolic curve
			pts_top.append(Vector2(px, center.y - dy * h/2.0))
			pts_bottom.append(Vector2(px, center.y + dy * h/2.0))
		
		# Vẽ mí mắt trên và dưới
		eye_drawing.draw_polyline(pts_top, color, 1.6, true)
		eye_drawing.draw_polyline(pts_bottom, color, 1.6, true)
		
		# Vẽ lòng đen (nhãn cầu)
		eye_drawing.draw_arc(center, 3.5, 0, TAU, 24, color, 1.6, true)
		
		# Vẽ con ngươi (nhân nhỏ)
		eye_drawing.draw_circle(center, 1.2, color)
		
		# Giống trên web: nếu _pass_visible = true (đang hiện pass), icon hiển thị là EyeOff (mắt có gạch chéo)
		if _pass_visible:
			# Vẽ đường gạch chéo chéo từ góc trên-trái xuống dưới-phải
			var line_start := center + Vector2(-w/2.0 - 2, -h/2.0 - 2)
			var line_end := center + Vector2(w/2.0 + 2, h/2.0 + 2)
			eye_drawing.draw_line(line_start, line_end, color, 1.6, true)
	)
	_pass_toggle_btn.add_child(eye_drawing)

	_pass_toggle_btn.pressed.connect(func() -> void:
		_pass_visible = not _pass_visible
		password_edit.secret = not _pass_visible
		eye_drawing.queue_redraw()
	)
	_pass_toggle_btn.mouse_entered.connect(func() -> void: eye_drawing.queue_redraw())
	_pass_toggle_btn.mouse_exited.connect(func() -> void: eye_drawing.queue_redraw())
	password_edit.add_child(_pass_toggle_btn)

	# — Icon trong Email input (👤) —
	var email_icon := TextureRect.new()
	email_icon.name = "EmailIcon"
	email_icon.texture = load("res://assets/textures/lucide/user.svg")
	email_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	email_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	email_icon.custom_minimum_size = Vector2(24, 24)
	email_icon.size = Vector2(24, 24)
	email_icon.layout_mode = 1
	email_icon.anchor_top = 0.5
	email_icon.anchor_bottom = 0.5
	email_icon.offset_left = 16
	email_icon.offset_top = -12
	email_icon.offset_bottom = 12
	email_icon.self_modulate = C_PRIMARY_LT
	email_edit.add_child(email_icon)

	# — Icon trong Mật khẩu input (🔒) —
	var pass_icon := TextureRect.new()
	pass_icon.name = "PassIcon"
	pass_icon.texture = load("res://assets/textures/lucide/lock.svg")
	pass_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pass_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pass_icon.custom_minimum_size = Vector2(24, 24)
	pass_icon.size = Vector2(24, 24)
	pass_icon.layout_mode = 1
	pass_icon.anchor_top = 0.5
	pass_icon.anchor_bottom = 0.5
	pass_icon.offset_left = 16
	pass_icon.offset_top = -12
	pass_icon.offset_bottom = 12
	pass_icon.self_modulate = C_PRIMARY_LT
	password_edit.add_child(pass_icon)

	# — Icon trong Tên hiển thị input (👤) —
	var name_icon := TextureRect.new()
	name_icon.name = "NameIcon"
	name_icon.texture = load("res://assets/textures/lucide/user.svg")
	name_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	name_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	name_icon.custom_minimum_size = Vector2(24, 24)
	name_icon.size = Vector2(24, 24)
	name_icon.layout_mode = 1
	name_icon.anchor_top = 0.5
	name_icon.anchor_bottom = 0.5
	name_icon.offset_left = 16
	name_icon.offset_top = -12
	name_icon.offset_bottom = 12
	name_icon.self_modulate = C_PRIMARY_LT
	name_edit.add_child(name_icon)
	
	# — Icon trong GuestBtn (Khách) —
	guest_btn.text = ""
	var guest_icon := TextureRect.new()
	guest_icon.name = "GuestIcon"
	guest_icon.texture = load("res://assets/textures/lucide/user.svg")
	guest_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	guest_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	guest_icon.custom_minimum_size = Vector2(36, 36)
	guest_icon.size = Vector2(36, 36)
	guest_icon.layout_mode = 1
	guest_icon.anchor_left = 0.5
	guest_icon.anchor_right = 0.5
	guest_icon.anchor_top = 0.5
	guest_icon.anchor_bottom = 0.5
	guest_icon.offset_left = -18
	guest_icon.offset_top = -18
	guest_icon.offset_right = 18
	guest_icon.offset_bottom = 18
	guest_icon.self_modulate = C_PRIMARY_LT
	guest_btn.add_child(guest_icon)

	_otp_edit = _create_auth_input("Mã OTP gồm 6 chữ số", false)
	_new_password_edit = _create_auth_input("Mật khẩu mới", true)
	_confirm_password_edit = _create_auth_input("Nhập lại mật khẩu mới", true)
	for input in [_otp_edit, _new_password_edit, _confirm_password_edit]:
		vbox.add_child(input)
		vbox.move_child(input, error_label.get_index())


func _create_auth_input(placeholder: String, secret_value: bool) -> LineEdit:
	var edit := LineEdit.new()
	edit.custom_minimum_size = Vector2(0, 58)
	edit.placeholder_text = placeholder
	edit.secret = secret_value
	edit.visible = false
	edit.add_theme_font_size_override("font_size", 18)
	var font := load("res://assets/fonts/BeVietnamPro-Regular.ttf") as Font
	if font:
		edit.add_theme_font_override("font", font)
	var normal := _pill(Color(0.95, 0.93, 0.89, 0.60), Color(0.13, 0.08, 0.05, 0.15), 28)
	var focus := _pill(Color.WHITE, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.88), 28)
	var read_only := _pill(Color(1.0, 1.0, 1.0, 0.76), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.28), 28)
	normal.content_margin_left = 20
	focus.content_margin_left = 20
	read_only.content_margin_left = 20
	edit.add_theme_stylebox_override("normal", normal)
	edit.add_theme_stylebox_override("focus", focus)
	edit.add_theme_stylebox_override("read_only", read_only)
	edit.add_theme_color_override("font_color", Color(0.13, 0.08, 0.05, 1.0))
	edit.add_theme_color_override("font_uneditable_color", Color(0.13, 0.08, 0.05, 0.72))
	edit.add_theme_color_override("font_placeholder_color", Color(0.13, 0.08, 0.05, 0.7))
	edit.add_theme_color_override("caret_color", C_GOLD)
	return edit

# ── Entrance animation ───────────────────────────────────────────────────────────────────────
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
	
	var content_vbox := get_node("Center/Card/CardMargin/ContentVBox") as VBoxContainer
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
	cs.bg_color              = Color(0.995, 0.99, 0.985, 0.98) # High-opacity warm ivory
	cs.border_color          = Color("#e2d8c9")
	cs.border_width_left     = 2; cs.border_width_right  = 2
	cs.border_width_top      = 2; cs.border_width_bottom = 2
	cs.corner_radius_top_left     = 28; cs.corner_radius_top_right    = 28
	cs.corner_radius_bottom_left  = 28; cs.corner_radius_bottom_right = 28
	cs.shadow_size   = 24
	cs.shadow_color  = Color(0.08, 0.07, 0.05, 0.14)
	cs.shadow_offset = Vector2(0, 8)
	card.add_theme_stylebox_override("panel", cs)
	card.pivot_offset = card.size / 2.0
	card.resized.connect(func() -> void: card.pivot_offset = card.size / 2.0)

	# Screen-texture blur can render as opaque rectangles on mobile renderers.
	for c in card.get_children():
		if c is ColorRect and c.name == "BlurRect":
			c.queue_free()

# ── Tô màu toàn bộ UI theo Cream/Espresso ─────────────────────────────────────
func _style_all() -> void:
	# Show App Name and Sub with clean styling
	app_name.visible = true
	app_sub.visible = true
	footer_lbl.visible = true
	
	var title_font := load("res://assets/fonts/Lora-Bold.ttf") as Font
	var font_reg := load("res://assets/fonts/BeVietnamPro-Regular.ttf") as Font
	var font_bold := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	
	if title_font:
		app_name.add_theme_font_override("font", title_font)
	app_name.add_theme_color_override("font_color", Color("#0f172a")) # Slate-900 (High contrast)
	app_sub.add_theme_color_override("font_color", Color("#64748b")) # Slate-500

	# Hide Google login VBox
	var google_vbox := get_node_or_null(FP + "SocialRow/GoogleVBox")
	if google_vbox:
		google_vbox.visible = false
	
	if font_reg:
		email_edit.add_theme_font_override("font", font_reg)
		name_edit.add_theme_font_override("font", font_reg)
		password_edit.add_theme_font_override("font", font_reg)
		or_label.add_theme_font_override("font", font_reg)
		toggle_mode_btn.add_theme_font_override("font", font_reg)
		guest_lbl.add_theme_font_override("font", font_reg)
		google_lbl.add_theme_font_override("font", font_reg)
		error_label.add_theme_font_override("font", font_reg)
		footer_lbl.add_theme_font_override("font", font_reg)
	if font_bold:
		sign_in_btn.add_theme_font_override("font", font_bold)

	or_label.add_theme_color_override("font_color",    Color("#64748b"))
	error_label.add_theme_color_override("font_color", Color("#dc2626"))
	error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guest_lbl.add_theme_color_override("font_color",   Color("#475569"))
	footer_lbl.add_theme_color_override("font_color",  Color("#94a3b8"))

	# Name, Email, Password: Solid White 3D input box for high contrast
	var ei_n := StyleBoxFlat.new()
	ei_n.bg_color = Color.WHITE
	ei_n.border_color = Color("#cbd5e1")
	ei_n.set_border_width_all(2)
	ei_n.set_corner_radius_all(16)
	ei_n.content_margin_left = 48
	ei_n.content_margin_right = 44
	ei_n.content_margin_top = 8
	ei_n.content_margin_bottom = 8
	
	var ei_f := ei_n.duplicate() as StyleBoxFlat
	ei_f.border_color = Color("#d97706") # Amber on focus
	ei_f.shadow_size = 8
	ei_f.shadow_color = Color(0.85, 0.55, 0.1, 0.15)
	
	var ei_ro := ei_n.duplicate() as StyleBoxFlat
	ei_ro.bg_color = Color("#f8fafc")
	
	email_edit.add_theme_stylebox_override("normal", ei_n)
	email_edit.add_theme_stylebox_override("focus",  ei_f)
	email_edit.add_theme_stylebox_override("read_only", ei_ro)
	email_edit.add_theme_color_override("font_color",        Color("#0f172a"))
	email_edit.add_theme_color_override("font_uneditable_color", Color("#64748b"))
	email_edit.add_theme_color_override("font_placeholder_color", Color("#94a3b8"))
	email_edit.add_theme_color_override("caret_color",       Color("#d97706"))
	email_edit.add_theme_font_size_override("font_size", 16)

	name_edit.add_theme_stylebox_override("normal", ei_n)
	name_edit.add_theme_stylebox_override("focus",  ei_f)
	name_edit.add_theme_stylebox_override("read_only", ei_ro)
	name_edit.add_theme_color_override("font_color",        Color("#0f172a"))
	name_edit.add_theme_color_override("font_uneditable_color", Color("#64748b"))
	name_edit.add_theme_color_override("font_placeholder_color", Color("#94a3b8"))
	name_edit.add_theme_color_override("caret_color",       Color("#d97706"))
	name_edit.add_theme_font_size_override("font_size", 16)

	password_edit.add_theme_stylebox_override("normal", ei_n)
	password_edit.add_theme_stylebox_override("focus",  ei_f)
	password_edit.add_theme_stylebox_override("read_only", ei_ro)
	password_edit.add_theme_color_override("font_color",        Color("#0f172a"))
	password_edit.add_theme_color_override("font_uneditable_color", Color("#64748b"))
	password_edit.add_theme_color_override("font_placeholder_color", Color("#94a3b8"))
	password_edit.add_theme_color_override("caret_color",       Color("#d97706"))
	password_edit.add_theme_font_size_override("font_size", 16)

	# Nút Đăng nhập: 3D Navy button matching taste skill
	var si_n := StyleBoxFlat.new()
	si_n.bg_color = Color("#0f172a") # Slate-900
	si_n.border_color = Color("#020617")
	si_n.set_border_width_all(2)
	si_n.border_width_bottom = 4
	si_n.set_corner_radius_all(16)
	si_n.shadow_size = 12
	si_n.shadow_color = Color(0.06, 0.09, 0.16, 0.20)
	
	var si_h := si_n.duplicate() as StyleBoxFlat
	si_h.bg_color = Color("#1e293b")
	si_h.border_color = Color("#d97706")
	
	var si_p := si_n.duplicate() as StyleBoxFlat
	si_p.bg_color = Color("#020617")
	si_p.border_width_top = 3
	si_p.border_width_bottom = 1
	
	var si_d := si_n.duplicate() as StyleBoxFlat
	si_d.bg_color = Color("#64748b")
	si_d.border_color = Color("#475569")
	
	sign_in_btn.add_theme_stylebox_override("normal",  si_n)
	sign_in_btn.add_theme_stylebox_override("hover",   si_h)
	sign_in_btn.add_theme_stylebox_override("pressed", si_p)
	sign_in_btn.add_theme_stylebox_override("disabled", si_d)
	sign_in_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	sign_in_btn.add_theme_color_override("font_color", Color.WHITE)
	sign_in_btn.add_theme_color_override("font_hover_color", Color("#fef3c7"))
	sign_in_btn.add_theme_color_override("font_disabled_color", Color(1.0, 1.0, 1.0, 0.6))
	sign_in_btn.add_theme_font_size_override("font_size", 18)
	sign_in_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	# Nút Chuyển chế độ: Flat link button
	toggle_mode_btn.add_theme_color_override("font_color",         Color("#d97706"))
	toggle_mode_btn.add_theme_color_override("font_hover_color",   Color("#b45309"))
	toggle_mode_btn.add_theme_color_override("font_pressed_color", Color("#92400e"))
	toggle_mode_btn.add_theme_color_override("font_disabled_color", Color("#94a3b8"))
	toggle_mode_btn.add_theme_stylebox_override("normal",  StyleBoxEmpty.new())
	toggle_mode_btn.add_theme_stylebox_override("hover",   StyleBoxEmpty.new())
	toggle_mode_btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	toggle_mode_btn.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	toggle_mode_btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
	toggle_mode_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	# Guest button
	var g_n := StyleBoxFlat.new()
	g_n.bg_color = Color.WHITE
	g_n.border_color = Color("#cbd5e1")
	g_n.set_border_width_all(2)
	g_n.border_width_bottom = 4
	g_n.set_corner_radius_all(16)
	
	var g_h := g_n.duplicate() as StyleBoxFlat
	g_h.bg_color = Color("#f8fafc")
	g_h.border_color = Color("#d97706")
	
	var g_p := g_n.duplicate() as StyleBoxFlat
	g_p.bg_color = Color("#f1f5f9")
	g_p.border_width_top = 3
	g_p.border_width_bottom = 1
	
	guest_btn.add_theme_stylebox_override("normal", g_n)
	guest_btn.add_theme_stylebox_override("hover", g_h)
	guest_btn.add_theme_stylebox_override("pressed", g_p)
	guest_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	guest_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

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
	var d := _pill(Color(1.0, 1.0, 1.0, 0.38), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.12), 18)
	n.shadow_size = 6; n.shadow_color = Color(0.13, 0.08, 0.05, 0.08)
	h.shadow_size = 10; h.shadow_color = Color(0.13, 0.08, 0.05, 0.12)
	btn.add_theme_stylebox_override("normal",  n)
	btn.add_theme_stylebox_override("hover",   h)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_stylebox_override("disabled", d)
	btn.add_theme_stylebox_override("focus",   _pill(Color(0,0,0,0), Color(0,0,0,0), 0))
	btn.add_theme_color_override("font_disabled_color", Color(0.13, 0.08, 0.05, 0.38))

# ── Kết nối sự kiện ──────────────────────────────────────────────────────────
func _connect_all() -> void:
	sign_in_btn.pressed.connect(_on_auth_submit)
	email_edit.text_submitted.connect(func(_s: String) -> void: _on_auth_submit())
	password_edit.text_submitted.connect(func(_s: String) -> void: _on_auth_submit())
	name_edit.text_submitted.connect(func(_s: String) -> void: _on_auth_submit())
	_otp_edit.text_submitted.connect(func(_s: String) -> void: _on_auth_submit())
	_new_password_edit.text_submitted.connect(func(_s: String) -> void: _on_auth_submit())
	_confirm_password_edit.text_submitted.connect(func(_s: String) -> void: _on_auth_submit())
	toggle_mode_btn.pressed.connect(_on_auth_toggle)
	guest_btn.pressed.connect(_on_guest_pressed)
	_make_bouncy(sign_in_btn)
	_make_bouncy(google_btn)
	_make_bouncy(guest_btn)
	_make_bouncy(toggle_mode_btn)


func _set_auth_mode(mode: int) -> void:
	_auth_mode = mode
	is_register_mode = mode == AuthMode.REGISTER
	var show_name := mode == AuthMode.REGISTER
	var show_password := mode in [AuthMode.LOGIN, AuthMode.REGISTER]
	var show_otp := mode in [AuthMode.VERIFY_REGISTRATION, AuthMode.RESET_PASSWORD]
	var show_new_password := mode == AuthMode.RESET_PASSWORD

	_name_lbl.visible = show_name
	name_edit.visible = show_name
	gap_name.visible = show_name
	_pass_row.visible = show_password
	password_edit.visible = show_password
	get_node(FP + "GapPassword").visible = show_password
	_otp_edit.visible = show_otp
	_new_password_edit.visible = show_new_password
	_confirm_password_edit.visible = show_new_password

	var show_guest := mode == AuthMode.LOGIN
	get_node(FP + "DivRow").visible = show_guest
	get_node(FP + "Gap3").visible = show_guest
	get_node(FP + "Gap4").visible = show_guest
	get_node(FP + "SocialRow").visible = show_guest
	_forgot_btn.visible = mode == AuthMode.LOGIN
	error_label.text = ""

	match mode:
		AuthMode.LOGIN:
			sign_in_btn.text = "ĐĂNG NHẬP"
			toggle_mode_btn.text = "Chưa có tài khoản? Đăng ký ngay"
			_welcome_lbl.text = "Chào mừng trở lại"
			_welcome_sub.text = "Tiếp tục hành trình khám phá âm nhạc dân tộc"
		AuthMode.REGISTER:
			sign_in_btn.text = "ĐĂNG KÝ"
			toggle_mode_btn.text = "Đã có tài khoản? Đăng nhập"
			_welcome_lbl.text = "Tạo tài khoản mới"
			_welcome_sub.text = "Mã xác nhận sẽ được gửi đến email của bạn"
		AuthMode.VERIFY_REGISTRATION:
			sign_in_btn.text = "XÁC NHẬN OTP"
			toggle_mode_btn.text = "Quay lại đăng nhập"
			_welcome_lbl.text = "Xác nhận tài khoản"
			_welcome_sub.text = "Nhập mã OTP 6 chữ số đã gửi qua email"
		AuthMode.FORGOT_PASSWORD:
			sign_in_btn.text = "GỬI MÃ XÁC NHẬN"
			toggle_mode_btn.text = "Quay lại đăng nhập"
			_welcome_lbl.text = "Quên mật khẩu"
			_welcome_sub.text = "Nhập email để nhận mã đặt lại mật khẩu"
		AuthMode.RESET_PASSWORD:
			sign_in_btn.text = "ĐẶT LẠI MẬT KHẨU"
			toggle_mode_btn.text = "Quay lại đăng nhập"
			_welcome_lbl.text = "Tạo mật khẩu mới"
			_welcome_sub.text = "Mã xác nhận có hiệu lực trong 5 phút"

	_welcome_sub.visible = true
	_set_busy(false)


func _on_auth_toggle() -> void:
	if _auth_mode == AuthMode.LOGIN:
		_set_auth_mode(AuthMode.REGISTER)
	else:
		_set_auth_mode(AuthMode.LOGIN)


func _on_forgot_password_pressed() -> void:
	_set_auth_mode(AuthMode.FORGOT_PASSWORD)


func _on_auth_submit() -> void:
	if sign_in_btn.disabled:
		return
	match _auth_mode:
		AuthMode.LOGIN:
			await _submit_login()
		AuthMode.REGISTER:
			await _submit_registration()
		AuthMode.VERIFY_REGISTRATION:
			await _submit_registration_otp()
		AuthMode.FORGOT_PASSWORD:
			await _submit_forgot_password()
		AuthMode.RESET_PASSWORD:
			await _submit_reset_password()


func _submit_login() -> void:
	var email := email_edit.text.strip_edges()
	if not _validate_email(email) or not _validate_password(password_edit.text):
		return
	_set_busy(true)
	var response: Dictionary = await _api_client.login(email, password_edit.text)
	if _response_ok(response):
		_pending_email = email
		_pending_name = ""
		await _finish_auth(response)
		return
	_set_busy(false)
	_show_api_error(response, "Đăng nhập thất bại. Vui lòng thử lại.")


func _submit_registration() -> void:
	var email := email_edit.text.strip_edges()
	var full_name := name_edit.text.strip_edges()
	if not _validate_email(email) or not _validate_password(password_edit.text):
		return
	if full_name.length() < 2:
		_show_error("Tên hiển thị phải có ít nhất 2 ký tự.")
		_shake(name_edit)
		return
	_set_busy(true)
	var response: Dictionary = await _api_client.register(email, password_edit.text, full_name)
	_set_busy(false)
	if not _response_ok(response):
		_show_api_error(response, "Không thể đăng ký tài khoản.")
		return
	_pending_email = email
	_pending_name = full_name
	_otp_edit.text = ""
	_set_auth_mode(AuthMode.VERIFY_REGISTRATION)
	_show_success("Đã gửi mã OTP đến " + email)
	_otp_edit.grab_focus()


func _submit_registration_otp() -> void:
	var otp := _otp_edit.text.strip_edges()
	if not _validate_otp(otp):
		return
	_set_busy(true)
	var response: Dictionary = await _api_client.verify_registration(_pending_email, otp)
	if _response_ok(response):
		await _finish_auth(response)
		return
	_set_busy(false)
	_show_api_error(response, "Mã OTP không đúng hoặc đã hết hạn.")


func _submit_forgot_password() -> void:
	var email := email_edit.text.strip_edges()
	if not _validate_email(email):
		return
	_set_busy(true)
	var response: Dictionary = await _api_client.forgot_password(email)
	_set_busy(false)
	if not _response_ok(response):
		_show_api_error(response, "Không thể gửi mã đặt lại mật khẩu.")
		return
	_pending_email = email
	_otp_edit.text = ""
	_new_password_edit.text = ""
	_confirm_password_edit.text = ""
	_set_auth_mode(AuthMode.RESET_PASSWORD)
	_show_success("Đã gửi mã xác nhận đến " + email)
	_otp_edit.grab_focus()


func _submit_reset_password() -> void:
	var otp := _otp_edit.text.strip_edges()
	var new_password := _new_password_edit.text
	if not _validate_otp(otp) or not _validate_password(new_password, _new_password_edit):
		return
	if new_password != _confirm_password_edit.text:
		_show_error("Mật khẩu nhập lại chưa khớp.")
		_shake(_confirm_password_edit)
		return
	_set_busy(true)
	var response: Dictionary = await _api_client.reset_password(_pending_email, otp, new_password)
	_set_busy(false)
	if not _response_ok(response):
		_show_api_error(response, "Không thể đặt lại mật khẩu.")
		return
	password_edit.text = ""
	email_edit.text = _pending_email
	_set_auth_mode(AuthMode.LOGIN)
	_show_success("Đổi mật khẩu thành công. Bạn có thể đăng nhập ngay.")
	password_edit.grab_focus()


func _finish_auth(response: Dictionary) -> void:
	var body: Dictionary = response.get("body", {})
	var auth_data: Dictionary = body.get("data", {})
	if not AuthSessionStore.apply_auth_response(auth_data):
		_set_busy(false)
		_show_error("Máy chủ trả về phiên đăng nhập không hợp lệ.")
		return

	var profile_response: Dictionary = await _api_client.get_me()
	if _response_ok(profile_response):
		_save_profile(profile_response)
	else:
		_save_profile_fallback()
	_show_success("Đăng nhập thành công!")
	_go_main()


func _try_restore_session() -> void:
	if not AuthSessionStore.has_access_token() and not AuthSessionStore.can_refresh():
		return
	_set_busy(true)
	_show_success("Đang khôi phục phiên đăng nhập...")
	var response: Dictionary = await _api_client.get_me()
	if _response_ok(response):
		_save_profile(response)
		_go_main()
		return
	_set_busy(false)
	if int(response.get("status", 0)) in [401, 403]:
		AuthSessionStore.clear_session()
		error_label.text = ""
	else:
		_show_api_error(response, "Không thể khôi phục phiên đăng nhập.")


func _save_profile(response: Dictionary) -> void:
	var body: Dictionary = response.get("body", {})
	var profile: Dictionary = body.get("data", {})
	var full_name := str(profile.get("fullName", "")).strip_edges()
	var email := str(profile.get("email", _pending_email)).strip_edges()
	if full_name.is_empty():
		full_name = _name_from_email(email)
	SecureDataManager.data["user_id"] = profile.get("id", 0)
	SecureDataManager.data["user_name"] = full_name
	SecureDataManager.data["user_email"] = email
	SecureDataManager.data["user_code"] = str(profile.get("userCode", AuthSessionStore.user_code))
	SecureDataManager.data["user_role"] = str(profile.get("role", AuthSessionStore.role))
	SecureDataManager.data["user_avatar_url"] = str(profile.get("avatarUrl", "")).strip_edges()
	SecureDataManager.save_data()


func _save_profile_fallback() -> void:
	var email := _pending_email
	var full_name := _pending_name if not _pending_name.is_empty() else _name_from_email(email)
	SecureDataManager.data["user_name"] = full_name
	SecureDataManager.data["user_email"] = email
	SecureDataManager.data["user_code"] = AuthSessionStore.user_code
	SecureDataManager.data["user_role"] = AuthSessionStore.role
	SecureDataManager.save_data()


func _set_busy(busy: bool) -> void:
	sign_in_btn.disabled = busy
	toggle_mode_btn.disabled = busy
	_forgot_btn.disabled = busy
	guest_btn.disabled = busy
	_pass_toggle_btn.disabled = busy
	email_edit.editable = not busy and _auth_mode not in [AuthMode.VERIFY_REGISTRATION, AuthMode.RESET_PASSWORD]
	name_edit.editable = not busy
	password_edit.editable = not busy
	_otp_edit.editable = not busy
	_new_password_edit.editable = not busy
	_confirm_password_edit.editable = not busy
	if busy:
		sign_in_btn.text = "ĐANG XỬ LÝ..."
	else:
		match _auth_mode:
			AuthMode.LOGIN:
				sign_in_btn.text = "ĐĂNG NHẬP"
			AuthMode.REGISTER:
				sign_in_btn.text = "ĐĂNG KÝ"
			AuthMode.VERIFY_REGISTRATION:
				sign_in_btn.text = "XÁC NHẬN OTP"
			AuthMode.FORGOT_PASSWORD:
				sign_in_btn.text = "GỬI MÃ XÁC NHẬN"
			AuthMode.RESET_PASSWORD:
				sign_in_btn.text = "ĐẶT LẠI MẬT KHẨU"


func _validate_email(email: String) -> bool:
	if email.length() >= 5 and "@" in email:
		return true
	_show_error("Vui lòng nhập đúng định dạng email.")
	_shake(email_edit)
	return false


func _validate_password(password: String, input: LineEdit = null) -> bool:
	if password.length() >= 6:
		return true
	_show_error("Mật khẩu phải có ít nhất 6 ký tự.")
	var target := input if input != null else password_edit
	_shake(target)
	return false


func _validate_otp(otp: String) -> bool:
	if otp.length() == 6 and otp.is_valid_int():
		return true
	_show_error("Mã OTP phải gồm đúng 6 chữ số.")
	_shake(_otp_edit)
	return false


func _response_ok(response: Dictionary) -> bool:
	var status := int(response.get("status", 0))
	return status >= 200 and status < 300


func _show_api_error(response: Dictionary, fallback: String) -> void:
	_show_error(_api_client.error_message(response, fallback))


func _show_error(message: String) -> void:
	error_label.add_theme_color_override("font_color", C_ERR)
	error_label.text = message


func _show_success(message: String) -> void:
	error_label.add_theme_color_override("font_color", C_GREEN_OK)
	error_label.text = message


func _name_from_email(email: String) -> String:
	if "@" not in email:
		return "Học viên VietStage"
	return email.split("@")[0].replace(".", " ").capitalize()

func _on_guest_pressed() -> void:
	AuthSessionStore.clear_session()
	SecureDataManager.data["user_name"] = "Khách"
	SecureDataManager.data["user_email"] = "khach@vietstage.vn"
	# Xóa trang trí khỏi phòng nhạc để tài khoản khách luôn bắt đầu sạch
	SecureDataManager.data["active_decorations"] = []
	SecureDataManager.data.erase("active_decorations_synced")
	SecureDataManager.save_data()
	_go_main()

func _go_main() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.40).set_trans(Tween.TRANS_CUBIC)
	t.tween_callback(func() -> void:
		SecureDataManager.load_data()
		get_tree().change_scene_to_file("res://scenes/VirtualMusicRoom.tscn")
	)

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
