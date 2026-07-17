extends Control

# ─── Color Palette ────────────────────────────────────────────────────────────
const C_GOLD       := Color(0.77, 0.58, 0.15, 1.0)
const C_GOLD_LIGHT := Color(0.95, 0.82, 0.45, 1.0)
const C_RED_SON    := Color(0.09, 0.27, 0.18, 1.0)
const C_JADE       := Color(0.09, 0.27, 0.18, 1.0)
const C_BG_BAR     := Color(0.97, 0.95, 0.91, 0.55)
const C_CARD       := Color(1.0, 0.99, 0.97, 0.8)
const C_TEXT       := Color(0.13, 0.08, 0.05, 1.0)
const C_TEXT_MUTED := Color(0.43, 0.38, 0.33, 1.0)

# [node_id, label_text, bg, border, accent]
const STAT_CARDS := [
	["G1", "Chuỗi học liên tiếp",  Color(1.0, 1.0, 1.0, 0.65), Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.4), C_JADE],
	["G2", "Tổng điểm tích lũy",    Color(1.0, 1.0, 1.0, 0.65), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.6), C_GOLD],
	["G3", "Tiến trình khóa học",   Color(1.0, 1.0, 1.0, 0.65), Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.4), C_JADE],
	["G4", "Ngày gia nhập",         Color(1.0, 1.0, 1.0, 0.65), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.6), C_GOLD],
]

# ─── Node Refs ───────────────────────────────────────────────────────────────
@onready var back_btn   : Button         = $Root/TopBar/TopM/TopH/BackBtn
@onready var page_title : Label          = $Root/TopBar/TopM/TopH/PageTitle
@onready var name_lbl   : Label          = $Root/Content/ContentV/Card/CardM/CardV/ProfileSection/NameLabel
@onready var email_lbl  : Label          = $Root/Content/ContentV/Card/CardM/CardV/ProfileSection/EmailLabel
@onready var logout_btn : Button         = $Root/Content/ContentV/Card/CardM/CardV/LogoutBtn
@onready var ver_label  : Label          = $Root/Content/ContentV/VerLabel
@onready var grid       : GridContainer  = $Root/Content/ContentV/Card/CardM/CardV/Grid
@onready var card_node  : PanelContainer = $Root/Content/ContentV/Card
@onready var av_circle  : PanelContainer = $Root/Content/ContentV/Card/CardM/CardV/ProfileSection/AvatarCircle
@onready var divider    : HSeparator     = $Root/Content/ContentV/Card/CardM/CardV/Divider
@onready var content_m  : MarginContainer = $Root/Content
@onready var bg         : TextureRect     = $BG
@onready var bg_overlay : ColorRect       = $BGOverlay

func _ready() -> void:
	SecureDataManager.load_data()
	_populate_data()
	_enhance_ux()
	_build_theme()
	_animate_in()

	back_btn.pressed.connect(_go_back)
	logout_btn.pressed.connect(_on_logout)
	_make_btn_bouncy(back_btn)
	_make_btn_bouncy(logout_btn)

	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()

# ─── Data ────────────────────────────────────────────────────────────────────
func _populate_data() -> void:
	# Override scene text with real UTF-8 labels
	page_title.text = "Tài Khoản Của Tôi"
	back_btn.text   = " Quay Lại"
	var back_icon = load("res://assets/textures/lucide/arrow-left.svg") as Texture2D
	if back_icon:
		back_btn.icon = back_icon
		back_btn.expand_icon = true
	logout_btn.text = "Đăng Xuất"
	ver_label.text  = "VietStage v1.0.0 · Đồ Án Tốt Nghiệp · Khoa CNTT"

	name_lbl.text  = SecureDataManager.data.get("user_name",  "Google User")
	email_lbl.text = SecureDataManager.data.get("user_email", "google.user@gmail.com")

	# Stats
	var streak : int   = int(SecureDataManager.data.get("daily_streak", 1))
	var psecs  : int   = int(SecureDataManager.data.get("practice_time_seconds", 0))
	var xp     : int   = 1240 + int(psecs / 6.0)
	var inst   : String = SecureDataManager.data.get("selected_instrument", "dan_tranh")
	var prog   : float  = SecureDataManager.get_course_progress(inst)
	var join   : String = SecureDataManager.data.get("join_date", "")
	if join == "":
		var d := Time.get_date_dict_from_system()
		join = "%02d/%02d/%d" % [d.day, d.month, d.year]
		SecureDataManager.data["join_date"] = join
		SecureDataManager.save_data()

	# Stat icons, values, labels
	var stat_icons  := ["flame", "star", "trending-up", "calendar-days"]
	var stat_values := [
		"%d Ngày" % streak,
		"%d XP"   % xp,
		"%.0f%%" % prog,
		join,
	]

	for i in STAT_CARDS.size():
		var id  : String = STAT_CARDS[i][0] as String
		var lbl : String = STAT_CARDS[i][1] as String
		var icon_lbl = _get_stat_node(id, "Icon")
		icon_lbl.hide()
		var parent = icon_lbl.get_parent()
		if not parent.has_node("IconTex"):
			var tex_rect = TextureRect.new()
			tex_rect.name = "IconTex"
			tex_rect.texture = load("res://assets/textures/lucide/" + stat_icons[i] + ".svg") as Texture2D
			tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.custom_minimum_size = Vector2(24, 24)
			tex_rect.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			tex_rect.modulate = STAT_CARDS[i][4] as Color
			parent.add_child(tex_rect)
			parent.move_child(tex_rect, 0)
		_get_stat_node(id, "Val").text  = stat_values[i]
		_get_stat_node(id, "Lbl").text  = lbl

# ─── UX Enhancements ────────────────────────────────────────────────────────
func _enhance_ux() -> void:
	# 1. Move Logout Button to TopBar right
	var toph = $Root/TopBar/TopM/TopH
	if logout_btn.get_parent():
		logout_btn.get_parent().remove_child(logout_btn)
	toph.add_child(logout_btn)
	logout_btn.text = " Thoát"
	var logout_icon = load("res://assets/textures/lucide/log-out.svg") as Texture2D
	if logout_icon:
		logout_btn.icon = logout_icon
		logout_btn.expand_icon = true
	logout_btn.custom_minimum_size = Vector2(110, 42)
	logout_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# 2. Add Edit button next to Name
	var name_parent = name_lbl.get_parent()
	var name_box = HBoxContainer.new()
	name_box.alignment = BoxContainer.ALIGNMENT_CENTER
	name_box.add_theme_constant_override("separation", 16)
	name_parent.add_child(name_box)
	name_parent.move_child(name_box, name_lbl.get_index())
	name_parent.remove_child(name_lbl)
	name_box.add_child(name_lbl)
	
	var edit_btn = Button.new()
	edit_btn.text = " Sửa"
	var edit_icon = load("res://assets/textures/lucide/settings.svg") as Texture2D
	if edit_icon:
		edit_btn.icon = edit_icon
		edit_btn.expand_icon = true
	edit_btn.custom_minimum_size = Vector2(90, 32)
	var bold_f = load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if bold_f:
		edit_btn.add_theme_font_override("font", bold_f)
	var eb_style = StyleBoxFlat.new()
	eb_style.bg_color = Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.1)
	eb_style.corner_radius_top_left = 6; eb_style.corner_radius_top_right = 6
	eb_style.corner_radius_bottom_left = 6; eb_style.corner_radius_bottom_right = 6
	eb_style.border_color = C_JADE; eb_style.border_width_bottom = 2
	edit_btn.add_theme_stylebox_override("normal", eb_style)
	edit_btn.add_theme_stylebox_override("hover", eb_style)
	edit_btn.add_theme_color_override("font_color", C_JADE)
	name_box.add_child(edit_btn)
	_make_btn_bouncy(edit_btn)
	
	# 3. Add Progress Bar to G3
	var g3v = _get_stat_node("G3", "Val").get_parent()
	var prog = ProgressBar.new()
	prog.custom_minimum_size = Vector2(0, 8)
	prog.show_percentage = false
	var inst = SecureDataManager.data.get("selected_instrument", "dan_tranh")
	prog.value = SecureDataManager.get_course_progress(inst)
	g3v.add_child(prog)
	
	var p_bg = StyleBoxFlat.new(); p_bg.bg_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.2); p_bg.corner_radius_top_left = 4; p_bg.corner_radius_bottom_right = 4; p_bg.corner_radius_top_right = 4; p_bg.corner_radius_bottom_left = 4
	var p_fg = StyleBoxFlat.new(); p_fg.bg_color = C_JADE; p_fg.corner_radius_top_left = 4; p_fg.corner_radius_bottom_right = 4; p_fg.corner_radius_top_right = 4; p_fg.corner_radius_bottom_left = 4
	prog.add_theme_stylebox_override("background", p_bg)
	prog.add_theme_stylebox_override("fill", p_fg)
	
	# 4. Guest Banner
	var user_name = SecureDataManager.data.get("user_name", "Google User")
	if user_name == "Khách" or user_name == "Guest":
		var banner = PanelContainer.new()
		var b_style = StyleBoxFlat.new()
		b_style.bg_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.15)
		b_style.border_color = C_GOLD; b_style.border_width_left = 2; b_style.border_width_top = 2; b_style.border_width_right = 2; b_style.border_width_bottom = 2
		b_style.corner_radius_top_left = 8; b_style.corner_radius_top_right = 8; b_style.corner_radius_bottom_left = 8; b_style.corner_radius_bottom_right = 8
		banner.add_theme_stylebox_override("panel", b_style)
		
		var b_lbl = Label.new()
		b_lbl.text = "⚠️ Hãy đăng ký tài khoản để lưu lại tiến trình học tập"
		b_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b_lbl.add_theme_color_override("font_color", C_TEXT)
		b_lbl.add_theme_font_size_override("font_size", 13)
		var m_lbl = MarginContainer.new()
		m_lbl.add_theme_constant_override("margin_top", 10); m_lbl.add_theme_constant_override("margin_bottom", 10)
		m_lbl.add_child(b_lbl)
		banner.add_child(m_lbl)
		name_parent.add_child(banner)
		name_parent.move_child(banner, 0)

# ─── Theme ───────────────────────────────────────────────────────────────────
func _build_theme() -> void:
	# Fonts
	var lora_bold = load("res://assets/fonts/Lora-Bold.ttf") as Font
	var bevietnam_bold = load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	var bevietnam_reg = load("res://assets/fonts/BeVietnamPro-Regular.ttf") as Font
	if lora_bold:
		page_title.add_theme_font_override("font", lora_bold)
		name_lbl.add_theme_font_override("font", lora_bold)
	if bevietnam_bold:
		logout_btn.add_theme_font_override("font", bevietnam_bold)
		back_btn.add_theme_font_override("font", bevietnam_bold)
		for sc in STAT_CARDS:
			_get_stat_node(sc[0], "Val").add_theme_font_override("font", bevietnam_bold)
	if bevietnam_reg:
		email_lbl.add_theme_font_override("font", bevietnam_reg)
		ver_label.add_theme_font_override("font", bevietnam_reg)
		for sc in STAT_CARDS:
			_get_stat_node(sc[0], "Lbl").add_theme_font_override("font", bevietnam_reg)

	if bg:
		bg.texture = load("res://assets/textures/bon_nhac_cu_background.png") as Texture2D
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if bg_overlay:
		bg_overlay.color = Color(0, 0, 0, 0) # Không làm tối ảnh nền

	# TopBar
	var top_s : StyleBoxFlat = _flat(C_BG_BAR, Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.25), 0)
	top_s.border_width_bottom = 2
	top_s.border_width_top = 0; top_s.border_width_left = 0; top_s.border_width_right = 0
	($Root/TopBar as PanelContainer).add_theme_stylebox_override("panel", top_s)
	page_title.add_theme_color_override("font_color", C_JADE)
	
	# TopBar Blur
	var blur_mat = ShaderMaterial.new()
	var blur_shader = Shader.new()
	blur_shader.code = """
	shader_type canvas_item;
	uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
	uniform float lod: hint_range(0.0, 5.0) = 2.0;
	void fragment() {
		COLOR = textureLod(screen_texture, SCREEN_UV, lod);
	}
	"""
	blur_mat.shader = blur_shader
	var blur_rect = ColorRect.new()
	blur_rect.material = blur_mat
	blur_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blur_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blur_rect.show_behind_parent = true
	$Root/TopBar.add_child(blur_rect)
	$Root/TopBar.move_child(blur_rect, 0)

	# Back button
	back_btn.add_theme_color_override("font_color", C_JADE)
	back_btn.add_theme_color_override("font_hover_color", C_GOLD)
	back_btn.add_theme_stylebox_override("normal",  _flat(Color(0,0,0,0), Color(0,0,0,0), 8))
	back_btn.add_theme_stylebox_override("hover",   _flat(Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.1), Color(0,0,0,0), 8))
	back_btn.add_theme_stylebox_override("pressed", _flat(Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.18), Color(0,0,0,0), 8))
	back_btn.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0), 0))

	# Main card (Glassmorphism Light)
	var cs : StyleBoxFlat = _flat(C_CARD, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.6), 24)
	cs.border_width_top = 2; cs.border_width_left = 2; cs.border_width_right = 2; cs.border_width_bottom = 2
	cs.shadow_size = 32; cs.shadow_color = Color(0.0, 0.0, 0.0, 0.15)
	cs.shadow_offset = Vector2(0, 12)
	card_node.add_theme_stylebox_override("panel", cs)
	
	var card_blur = blur_rect.duplicate()
	card_node.add_child(card_blur)
	card_node.move_child(card_blur, 0)

	# Avatar circle (Glow Effect)
	var av_s : StyleBoxFlat = _flat(Color(0.97, 0.95, 0.91, 0.95), C_GOLD, 48)
	av_s.border_width_left = 3; av_s.border_width_right = 3
	av_s.border_width_top  = 3; av_s.border_width_bottom = 3
	av_s.shadow_size = 16; av_s.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25)
	av_circle.add_theme_stylebox_override("panel", av_s)

	# Name & email
	name_lbl.add_theme_color_override("font_color", C_TEXT)
	email_lbl.add_theme_color_override("font_color", C_TEXT_MUTED)

	# Divider
	var div_s : StyleBoxFlat = StyleBoxFlat.new()
	div_s.bg_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35)
	div_s.content_margin_top = 1; div_s.content_margin_bottom = 1
	divider.add_theme_stylebox_override("separator", div_s)

	# Stat cards
	for sc in STAT_CARDS:
		var id  : String = sc[0] as String
		var bg_c  : Color  = sc[2] as Color
		var brd : Color  = sc[3] as Color
		var acc : Color  = sc[4] as Color
		var nc  : PanelContainer = grid.get_node(id) as PanelContainer
		var card_s : StyleBoxFlat = _flat(bg_c, brd, 16)
		card_s.border_width_top = 2; card_s.border_width_left = 2
		card_s.border_width_right = 2; card_s.border_width_bottom = 2
		card_s.shadow_size = 8; card_s.shadow_color = Color(0, 0, 0, 0.08)
		nc.add_theme_stylebox_override("panel", card_s)
		_get_stat_node(id, "Icon").add_theme_color_override("font_color", acc)
		_get_stat_node(id, "Val").add_theme_color_override("font_color", C_TEXT)
		_get_stat_node(id, "Lbl").add_theme_color_override("font_color", C_TEXT_MUTED)

	# Logout button
	var lg_n : StyleBoxFlat = _flat(Color(1.0, 1.0, 1.0, 0.5), Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.5), 14)
	lg_n.border_width_left = 2; lg_n.border_width_right = 2
	lg_n.border_width_top = 2; lg_n.border_width_bottom = 2
	var lg_h : StyleBoxFlat = lg_n.duplicate() as StyleBoxFlat
	lg_h.bg_color = Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.15)
	lg_h.border_color = C_JADE
	lg_h.shadow_size = 8; lg_h.shadow_color = Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.15)
	logout_btn.add_theme_stylebox_override("normal",  lg_n)
	logout_btn.add_theme_stylebox_override("hover",   lg_h)
	logout_btn.add_theme_stylebox_override("pressed", _flat(Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.25), C_JADE, 14))
	logout_btn.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	logout_btn.add_theme_color_override("font_color",         C_TEXT)
	logout_btn.add_theme_color_override("font_hover_color",   C_JADE)
	logout_btn.add_theme_color_override("font_pressed_color", C_JADE)

	# Version label
	ver_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.6))

# ─── Responsive ───────────────────────────────────────────────────────────────
func _on_viewport_size_changed() -> void:
	var sz     : Vector2 = get_viewport().size
	var mobile : bool    = sz.x < sz.y or sz.x < 768.0

	grid.columns = 1 if mobile else 2

	var pad : int = 20 if mobile else 48
	content_m.add_theme_constant_override("margin_left",   pad)
	content_m.add_theme_constant_override("margin_right",  pad)
	content_m.add_theme_constant_override("margin_top",    24 if mobile else 36)
	content_m.add_theme_constant_override("margin_bottom", 24 if mobile else 36)

	var card_m : MarginContainer = $Root/Content/ContentV/Card/CardM as MarginContainer
	var inner : int = 36 if mobile else 72
	card_m.add_theme_constant_override("margin_left",   inner)
	card_m.add_theme_constant_override("margin_right",  inner)
	card_m.add_theme_constant_override("margin_top",    inner - 16)
	card_m.add_theme_constant_override("margin_bottom", inner - 16)

	page_title.add_theme_font_size_override("font_size", 22 if mobile else 28)
	name_lbl.add_theme_font_size_override("font_size",   20 if mobile else 26)
	email_lbl.add_theme_font_size_override("font_size",  13 if mobile else 15)


# ─── Animation ───────────────────────────────────────────────────────────────
func _animate_in() -> void:
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.30)
	var delay : float = 0.10
	for sc in STAT_CARDS:
		var node : Control = grid.get_node(sc[0] as String) as Control
		node.modulate.a = 0.0
		node.scale = Vector2(0.88, 0.88)
		var t : Tween = create_tween().set_parallel(true)
		t.tween_property(node, "modulate:a", 1.0, 0.28).set_delay(delay)
		t.tween_property(node, "scale", Vector2.ONE, 0.32).set_delay(delay) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		delay += 0.06

# ─── Navigation ───────────────────────────────────────────────────────────────
func _go_back() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.22)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))

func _on_logout() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.25)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/LoginScreen.tscn"))

# ─── Helpers ──────────────────────────────────────────────────────────────────
func _get_stat_node(id: String, child: String) -> Label:
	var path := id + "/" + id + "M/" + id + "V/" + child
	var node := grid.get_node_or_null(path)
	if node == null:
		push_warning("AccountScreen: stat node not found: " + path)
		return Label.new()
	return node as Label

func _flat(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.border_color = border
	s.border_width_left = 1; s.border_width_right = 1
	s.border_width_top  = 1; s.border_width_bottom = 1
	s.corner_radius_top_left    = radius; s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left = radius; s.corner_radius_bottom_right = radius
	return s

func _make_btn_bouncy(btn: Button) -> void:
	btn.pivot_offset = btn.size / 2.0
	btn.resized.connect(func() -> void: btn.pivot_offset = btn.size / 2.0)
	btn.mouse_entered.connect(func() -> void:
		create_tween().tween_property(btn, "scale", Vector2(1.05, 1.05), 0.12)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func() -> void:
		create_tween().tween_property(btn, "scale", Vector2.ONE, 0.12)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	btn.button_down.connect(func() -> void:
		create_tween().tween_property(btn, "scale", Vector2(0.95, 0.95), 0.08)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	btn.button_up.connect(func() -> void:
		var target := Vector2(1.05, 1.05) if btn.is_hovered() else Vector2.ONE
		create_tween().tween_property(btn, "scale", target, 0.12)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
