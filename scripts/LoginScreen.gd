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
@onready var email_edit     : LineEdit       = get_node(FP + "EmailEdit")
@onready var error_label    : Label          = get_node(FP + "ErrorLabel")
@onready var sign_in_btn    : Button         = get_node(FP + "SignInBtn")
@onready var google_btn     : Button         = get_node(FP + "SocialRow/GoogleVBox/GoogleBtn")
@onready var guest_btn      : Button         = get_node(FP + "SocialRow/GuestVBox/GuestBtn")
@onready var or_label       : Label          = get_node(FP + "DivRow/OrLabel")
@onready var google_lbl     : Label          = get_node(FP + "SocialRow/GoogleVBox/GoogleLbl")
@onready var guest_lbl      : Label          = get_node(FP + "SocialRow/GuestVBox/GuestLbl")
@onready var footer_lbl     : Label          = get_node(FP + "FooterLabel")
@onready var card           : PanelContainer = $Center/Card
@onready var particle_layer : Control        = $ParticleLayer

func _ready() -> void:
	_style_card()
	_style_all()
	_connect_all()
	_spawn_bg_particles()
	_animate_in()

# ── Entrance animation ─────────────────────────────────────────────────────────
func _animate_in() -> void:
	modulate.a   = 0.0
	card.scale   = Vector2(0.92, 0.92)
	card.modulate.a = 0.0

	var t := create_tween().set_parallel(true)
	t.tween_property(self, "modulate:a", 1.0, 0.50).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(card, "scale", Vector2.ONE, 0.60).set_delay(0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(card, "modulate:a", 1.0, 0.50).set_delay(0.10).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.chain().tween_callback(_start_logo_float)

func _start_logo_float() -> void:
	if not is_instance_valid(logo_rect): return
	var lp := create_tween().set_loops()
	lp.tween_property(logo_rect, "position:y", -6.0, 2.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	lp.tween_property(logo_rect, "position:y",  0.0, 2.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

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

	t.tween_property(p, "modulate:a", 1.0, dur * 0.22).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(p, "position:y", end_y, dur).set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(p, "position:x", sx + drift, dur * 0.50).set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(p, "position:x", sx + drift * 0.40, dur * 0.50).set_delay(delay + dur * 0.50).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(p, "modulate:a", 0.0, dur * 0.28).set_delay(delay + dur * 0.72).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Khi xong: reset lại vị trí và loop
	t.chain().tween_callback(func() -> void:
		if not is_instance_valid(p) or not is_instance_valid(particle_layer): return
		var new_sx := randf_range(0.0, vp.x)
		p.position   = Vector2(new_sx, sy + randf_range(-40.0, 40.0))
		p.modulate.a = 0.0
		_animate_particle(p, new_sx, p.position.y, dur * randf_range(0.85, 1.15), 0.0, vp)
	)

# ── Card kính đỏ sẫm ─────────────────────────────────────────────────────────
func _style_card() -> void:
	var cs := StyleBoxFlat.new()
	cs.bg_color              = Color(0.14, 0.03, 0.04, 0.88)
	cs.border_color          = Color(0.95, 0.72, 0.18, 0.22)
	cs.border_width_left     = 1; cs.border_width_right  = 1
	cs.border_width_top      = 1; cs.border_width_bottom = 1
	cs.corner_radius_top_left     = 28; cs.corner_radius_top_right    = 28
	cs.corner_radius_bottom_left  = 28; cs.corner_radius_bottom_right = 28
	cs.shadow_size   = 48
	cs.shadow_color  = Color(0.0, 0.0, 0.0, 0.55)
	cs.shadow_offset = Vector2(0, 10)
	card.add_theme_stylebox_override("panel", cs)
	card.pivot_offset = card.size / 2.0
	card.resized.connect(func() -> void: card.pivot_offset = card.size / 2.0)

# ── Tô màu toàn bộ UI ─────────────────────────────────────────────────────────
func _style_all() -> void:
	app_name.add_theme_color_override("font_color",    C_GOLD)
	app_sub.add_theme_color_override("font_color",     C_WHITE_DIM)
	or_label.add_theme_color_override("font_color",    C_WHITE_DIM)
	footer_lbl.add_theme_color_override("font_color",  Color(1,1,1,0.18))
	error_label.add_theme_color_override("font_color", C_ERR)
	google_lbl.add_theme_color_override("font_color",  C_WHITE_DIM)
	guest_lbl.add_theme_color_override("font_color",   C_WHITE_DIM)

	# Email: dark glass pill với viền vàng khi focus
	var ei_n := _pill(Color(1,1,1,0.08),  Color(1,1,1,0.16), 28)
	var ei_f := _pill(Color(1,1,1,0.12),  Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.70), 28)
	ei_f.shadow_size = 12; ei_f.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.22)
	email_edit.add_theme_stylebox_override("normal", ei_n)
	email_edit.add_theme_stylebox_override("focus",  ei_f)
	email_edit.add_theme_color_override("font_color",        C_WHITE)
	email_edit.add_theme_color_override("placeholder_color", Color(1,1,1,0.30))
	email_edit.add_theme_color_override("caret_color",       C_GOLD)

	# Nút Đăng nhập: vàng rực rỡ
	var si_n := _pill(C_GOLD,                 Color(0,0,0,0), 28)
	var si_h := _pill(C_GOLD_LT,              Color(0,0,0,0), 28)
	var si_p := _pill(C_GOLD.darkened(0.14),  Color(0,0,0,0), 28)
	si_n.shadow_size = 20; si_n.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.42)
	si_h.shadow_size = 28; si_h.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.58)
	sign_in_btn.add_theme_stylebox_override("normal",  si_n)
	sign_in_btn.add_theme_stylebox_override("hover",   si_h)
	sign_in_btn.add_theme_stylebox_override("pressed", si_p)
	sign_in_btn.add_theme_stylebox_override("focus",   _pill(Color(0,0,0,0), Color(0,0,0,0), 0))
	sign_in_btn.add_theme_color_override("font_color",         C_GOLD_DARK)
	sign_in_btn.add_theme_color_override("font_hover_color",   C_GOLD_DARK)
	sign_in_btn.add_theme_color_override("font_pressed_color", C_GOLD_DARK)

	# Social buttons: kính tối
	_style_social(google_btn)
	_style_social(guest_btn)
	# Google: chữ G xanh đặc trưng
	google_btn.add_theme_color_override("font_color",         C_G_BLUE)
	google_btn.add_theme_color_override("font_hover_color",   C_G_BLUE.lightened(0.1))
	google_btn.add_theme_color_override("font_pressed_color", C_G_BLUE.darkened(0.1))
	# Guest: trắng
	guest_btn.add_theme_color_override("font_color",          C_WHITE)
	guest_btn.add_theme_color_override("font_hover_color",    C_WHITE)
	guest_btn.add_theme_color_override("font_pressed_color",  Color(1,1,1,0.75))

func _style_social(btn: Button) -> void:
	var n := _pill(Color(1,1,1,0.08),  Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.20), 18)
	var h := _pill(Color(1,1,1,0.14),  Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.36), 18)
	var p := _pill(Color(1,1,1,0.04),  Color(0,0,0,0), 18)
	n.shadow_size = 10; n.shadow_color = Color(0,0,0,0.35)
	h.shadow_size = 16; h.shadow_color = Color(0,0,0,0.40)
	btn.add_theme_stylebox_override("normal",  n)
	btn.add_theme_stylebox_override("hover",   h)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_stylebox_override("focus",   _pill(Color(0,0,0,0), Color(0,0,0,0), 0))

# ── Kết nối sự kiện ──────────────────────────────────────────────────────────
func _connect_all() -> void:
	sign_in_btn.pressed.connect(_on_sign_in)
	email_edit.text_submitted.connect(func(_s: String) -> void: _on_sign_in())
	google_btn.pressed.connect(_go_main)
	guest_btn.pressed.connect(_go_main)
	_make_bouncy(sign_in_btn)
	_make_bouncy(google_btn)
	_make_bouncy(guest_btn)

func _on_sign_in() -> void:
	var em := email_edit.text.strip_edges()
	if em.length() < 5 or not "@" in em:
		error_label.add_theme_color_override("font_color", C_ERR)
		error_label.text = "Vui lòng nhập đúng định dạng email"
		_shake(email_edit)
		return
	error_label.add_theme_color_override("font_color", C_GREEN_OK)
	error_label.text = "Chào mừng!"
	sign_in_btn.disabled = true
	email_edit.editable  = false
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
		create_tween().tween_property(btn, "scale", Vector2(1.06, 1.06), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func() -> void:
		create_tween().tween_property(btn, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	btn.button_down.connect(func() -> void:
		create_tween().tween_property(btn, "scale", Vector2(0.93, 0.93), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	btn.button_up.connect(func() -> void:
		var target := Vector2(1.06, 1.06) if btn.is_hovered() else Vector2.ONE
		create_tween().tween_property(btn, "scale", target, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
