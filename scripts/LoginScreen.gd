extends Control

# ── Palette ───────────────────────────────────────────────────────────────────
const C_GOLD       := Color(0.95, 0.72, 0.18, 1.0)
const C_GOLD_LT    := Color(1.00, 0.87, 0.45, 1.0)
const C_GOLD_DIM   := Color(0.60, 0.45, 0.10, 1.0)
const C_RED        := Color(0.75, 0.10, 0.07, 1.0)
const C_RED_LT     := Color(0.88, 0.18, 0.10, 1.0)
const C_CREAM      := Color(1.00, 0.97, 0.91, 1.0)
const C_CREAM_DIM  := Color(0.72, 0.67, 0.56, 1.0)
const C_DARK       := Color(0.055, 0.027, 0.012, 1.0)
const C_DARK_CARD  := Color(0.065, 0.032, 0.014, 0.97)
const C_GREEN_OK   := Color(0.22, 0.74, 0.46, 1.0)
const C_ERR        := Color(0.92, 0.26, 0.18, 1.0)

enum Mode { LOGIN, REGISTER }
var _mode := Mode.LOGIN

# ── Refs ──────────────────────────────────────────────────────────────────────
@onready var phone_card   : PanelContainer = $Center/PhoneCard
@onready var app_name     : Label          = $Center/PhoneCard/Inner/VBox/AppName
@onready var logo_rect    : TextureRect    = $Center/PhoneCard/Inner/VBox/LogoRect
@onready var tab_login    : Button         = $Center/PhoneCard/Inner/VBox/Tabs/TabLogin
@onready var tab_register : Button         = $Center/PhoneCard/Inner/VBox/Tabs/TabRegister
@onready var email_field  : VBoxContainer  = $Center/PhoneCard/Inner/VBox/Form/EmailField
@onready var user_edit    : LineEdit       = $Center/PhoneCard/Inner/VBox/Form/UserField/UserEdit
@onready var email_edit   : LineEdit       = $Center/PhoneCard/Inner/VBox/Form/EmailField/EmailEdit
@onready var pass_edit    : LineEdit       = $Center/PhoneCard/Inner/VBox/Form/PassField/PassEdit
@onready var error_label  : Label          = $Center/PhoneCard/Inner/VBox/ErrorLabel
@onready var submit_btn   : Button         = $Center/PhoneCard/Inner/VBox/SubmitBtn
@onready var footer_lbl   : Label          = $Center/PhoneCard/Inner/VBox/FooterLabel

func _ready() -> void:
	_style_card()
	_style_header()
	_style_fields()
	_style_submit()
	_set_mode(Mode.LOGIN)
	_connect_all()
	_animate_in()

# ── Entrance ──────────────────────────────────────────────────────────────────
func _animate_in() -> void:
	modulate.a          = 0.0
	phone_card.scale    = Vector2(0.88, 0.88)
	phone_card.modulate = Color(1, 1, 1, 0)

	var t := create_tween().set_parallel(true)
	t.tween_property(self,       "modulate:a",         1.0,        0.3)
	t.tween_property(phone_card, "modulate:a",         1.0,        0.45).set_delay(0.1)
	t.tween_property(phone_card, "scale",   Vector2.ONE, 0.55).set_delay(0.1)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.chain().tween_callback(_start_logo_float)

func _start_logo_float() -> void:
	var lp := create_tween().set_loops()
	lp.tween_property(logo_rect, "position:y", -8.0, 2.0)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	lp.tween_property(logo_rect, "position:y",  0.0, 2.0)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

# ── Card background ───────────────────────────────────────────────────────────
func _style_card() -> void:
	# Outer card
	var cs := StyleBoxFlat.new()
	cs.bg_color    = C_DARK_CARD
	cs.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.38)
	cs.border_width_left = 1; cs.border_width_right  = 1
	cs.border_width_top  = 1; cs.border_width_bottom = 1
	cs.corner_radius_top_left     = 36
	cs.corner_radius_top_right    = 36
	cs.corner_radius_bottom_left  = 36
	cs.corner_radius_bottom_right = 36
	cs.shadow_size  = 48
	cs.shadow_color = Color(0, 0, 0, 0.70)
	phone_card.add_theme_stylebox_override("panel", cs)

# ── Header: logo + name + sub ────────────────────────────────────────────────
func _style_header() -> void:
	app_name.add_theme_color_override("font_color",         C_GOLD)
	app_name.add_theme_color_override("font_outline_color", Color(0.38, 0.22, 0.02, 1.0))
	app_name.add_theme_constant_override("outline_size",    5)
	app_name.add_theme_color_override("font_shadow_color",  Color(0, 0, 0, 0.55))
	app_name.add_theme_constant_override("shadow_offset_y", 4)

	($Center/PhoneCard/Inner/VBox/AppSub as Label)\
		.add_theme_color_override("font_color", C_CREAM_DIM)

	footer_lbl.add_theme_color_override("font_color", Color(0.38, 0.34, 0.24, 0.9))

	# Field tracker labels (uppercase caps)
	for p in [
		"Center/PhoneCard/Inner/VBox/Form/UserField/UserLabel",
		"Center/PhoneCard/Inner/VBox/Form/EmailField/EmailLabel",
		"Center/PhoneCard/Inner/VBox/Form/PassField/PassLabel",
	]:
		(get_node(p) as Label).add_theme_color_override("font_color",
			Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.62))

# ── Inputs ─────────────────────────────────────────────────────────────────────
func _style_fields() -> void:
	var base := _sbox(Color(0.04, 0.018, 0.007, 0.80),
					  Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.20), 18)
	var focus := _sbox(Color(0.05, 0.022, 0.010, 0.90),
					   Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.72), 18)
	focus.shadow_size  = 10
	focus.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.16)

	for e in [user_edit, email_edit, pass_edit]:
		e.add_theme_stylebox_override("normal", base)
		e.add_theme_stylebox_override("focus",  focus)
		e.add_theme_color_override("font_color",        C_CREAM)
		e.add_theme_color_override("placeholder_color", Color(0.42, 0.37, 0.26, 1.0))

	error_label.add_theme_color_override("font_color", C_ERR)

# ── Submit button ─────────────────────────────────────────────────────────────
func _style_submit() -> void:
	var n := _sbox(C_RED,                 Color(1.0, 0.75, 0.25, 0.55), 24)
	var h := _sbox(C_RED_LT,             Color(1.0, 0.85, 0.35, 0.88), 24)
	var p := _sbox(C_RED.darkened(0.18), Color(C_GOLD.r,C_GOLD.g,C_GOLD.b,0.25), 24)
	var f := _sbox(Color(0,0,0,0),        Color(0,0,0,0), 0)
	n.shadow_size = 16; n.shadow_color = Color(C_RED.r, C_RED.g, C_RED.b, 0.38)
	h.shadow_size = 24; h.shadow_color = Color(C_RED.r, C_RED.g, C_RED.b, 0.52)

	submit_btn.add_theme_stylebox_override("normal",  n)
	submit_btn.add_theme_stylebox_override("hover",   h)
	submit_btn.add_theme_stylebox_override("pressed", p)
	submit_btn.add_theme_stylebox_override("focus",   f)
	submit_btn.add_theme_color_override("font_color",         C_GOLD)
	submit_btn.add_theme_color_override("font_hover_color",   C_GOLD_LT)
	submit_btn.add_theme_color_override("font_pressed_color", C_GOLD)

# ── Tab switching ─────────────────────────────────────────────────────────────
func _set_mode(m: Mode) -> void:
	_mode = m
	error_label.text = ""

	var on  := _sbox(Color(0.22, 0.13, 0.04, 1.0),   C_GOLD,                                     16)
	var off := _sbox(Color(0.04, 0.018, 0.007, 0.0),  Color(C_GOLD.r,C_GOLD.g,C_GOLD.b, 0.0),    16)
	var hov := _sbox(Color(0.12, 0.07, 0.025, 0.6),   Color(C_GOLD.r,C_GOLD.g,C_GOLD.b, 0.28),   16)
	var foc := _sbox(Color(0,0,0,0), Color(0,0,0,0), 0)

	if _mode == Mode.LOGIN:
		_apply_tab(tab_login,    on,  on,  foc, C_GOLD)
		_apply_tab(tab_register, off, hov, foc, C_CREAM_DIM)
		email_field.visible = false
		submit_btn.text = "Bắt đầu học"
	else:
		_apply_tab(tab_register, on,  on,  foc, C_GOLD)
		_apply_tab(tab_login,    off, hov, foc, C_CREAM_DIM)
		email_field.visible = true
		submit_btn.text = "Tạo tài khoản"

func _apply_tab(btn: Button, n: StyleBoxFlat, h: StyleBoxFlat,
				f: StyleBoxFlat, color: Color) -> void:
	btn.add_theme_stylebox_override("normal",  n)
	btn.add_theme_stylebox_override("hover",   h)
	btn.add_theme_stylebox_override("pressed", n)
	btn.add_theme_stylebox_override("focus",   f)
	btn.add_theme_color_override("font_color", color)

# ── Connections ───────────────────────────────────────────────────────────────
func _connect_all() -> void:
	tab_login.pressed.connect(   func() -> void: _set_mode(Mode.LOGIN))
	tab_register.pressed.connect(func() -> void: _set_mode(Mode.REGISTER))
	submit_btn.pressed.connect(_on_submit)
	pass_edit.text_submitted.connect(func(_s: String) -> void: _on_submit())

	_make_button_bouncy(tab_login)
	_make_button_bouncy(tab_register)
	_make_button_bouncy(submit_btn)

# ── Submit logic ──────────────────────────────────────────────────────────────
func _on_submit() -> void:
	var user  := user_edit.text.strip_edges()
	var pass_w:= pass_edit.text.strip_edges()
	var email := email_edit.text.strip_edges()

	if user.length() < 3:
		error_label.text = "Tên đăng nhập phải có ít nhất 3 ký tự"
		_shake(); return
	if pass_w.length() < 4:
		error_label.text = "Mật khẩu phải có ít nhất 4 ký tự"
		_shake(); return
	if _mode == Mode.REGISTER:
		if email.length() == 0 or not "@" in email or not "." in email:
			error_label.text = "Vui lòng nhập đúng định dạng email"
			_shake(); return

	# Success state
	error_label.add_theme_color_override("font_color", C_GREEN_OK)
	error_label.text = "Xin chào, " + user + "!"
	user_edit.editable  = false
	email_edit.editable = false
	pass_edit.editable  = false
	submit_btn.disabled = true

	var t := create_tween()
	t.tween_property(submit_btn, "scale", Vector2(1.05, 0.96), 0.07)
	t.tween_property(submit_btn, "scale", Vector2.ONE,         0.14)\
		.set_trans(Tween.TRANS_BACK)
	t.tween_property(self, "modulate:a", 0.0, 0.38).set_delay(0.22)
	t.tween_callback(func() -> void:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))

# ── Card shake on error ───────────────────────────────────────────────────────
func _shake() -> void:
	var ox := phone_card.position.x
	var t  := create_tween()
	for d in [-14.0, 14.0, -9.0, 9.0, 0.0]:
		t.tween_property(phone_card, "position:x", ox + d, 0.052)\
			.set_trans(Tween.TRANS_SINE)

# ── Stylebox factory ──────────────────────────────────────────────────────────
func _sbox(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color     = bg
	s.border_color = border
	s.border_width_left   = 1; s.border_width_right  = 1
	s.border_width_top    = 1; s.border_width_bottom = 1
	s.corner_radius_top_left     = radius
	s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius
	s.corner_radius_bottom_right = radius
	return s

func _make_button_bouncy(btn: Button) -> void:
	btn.pivot_offset = btn.size / 2.0
	btn.resized.connect(func() -> void: btn.pivot_offset = btn.size / 2.0)
	btn.mouse_entered.connect(func() -> void:
		var t := create_tween()
		t.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func() -> void:
		var t := create_tween()
		t.tween_property(btn, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	btn.button_down.connect(func() -> void:
		var t := create_tween()
		t.tween_property(btn, "scale", Vector2(0.95, 0.95), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	btn.button_up.connect(func() -> void:
		var t := create_tween()
		t.tween_property(btn, "scale", Vector2(1.05, 1.05) if btn.is_hovered() else Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
