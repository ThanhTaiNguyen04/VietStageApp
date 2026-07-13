extends Control

# ─── Color Palette ────────────────────────────────────────────────────────────
const C_GOLD       := Color(0.77, 0.58, 0.15, 1.0)
const C_GOLD_LIGHT := Color(0.95, 0.82, 0.45, 1.0)
const C_RED_SON    := Color(0.09, 0.27, 0.18, 1.0)
const C_BG_BAR     := Color(0.95, 0.93, 0.89, 1.0)
const C_CARD       := Color(1.00, 1.00, 1.00, 0.97)
const C_TEXT       := Color(0.13, 0.08, 0.05, 1.0)
const C_TEXT_MUTED := Color(0.43, 0.38, 0.33, 1.0)

# [node_id, label_text, bg, border, accent]
const STAT_CARDS := [
	["G1", "Chuỗi học liên tiếp",  Color(0.99, 0.94, 0.90, 1.0), Color(0.95, 0.75, 0.60, 0.5), Color(0.90, 0.45, 0.10, 1.0)],
	["G2", "Tổng điểm tích lũy",    Color(0.99, 0.97, 0.90, 1.0), Color(0.92, 0.85, 0.60, 0.5), Color(0.77, 0.58, 0.15, 1.0)],
	["G3", "Tiến trình khóa học",   Color(0.93, 0.97, 0.94, 1.0), Color(0.75, 0.88, 0.80, 0.5), Color(0.12, 0.37, 0.23, 1.0)],
	["G4", "Ngày gia nhập",         Color(0.94, 0.95, 0.99, 1.0), Color(0.78, 0.82, 0.95, 0.5), Color(0.20, 0.40, 0.80, 1.0)],
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

func _ready() -> void:
	SecureDataManager.load_data()
	_populate_data()
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
	back_btn.text   = "← Quay Lại"
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
	var stat_icons  := ["🔥", "✨", "🏆", "📅"]
	var stat_values := [
		"%d Ngày" % streak,
		"%d XP"   % xp,
		"%.0f%%" % prog,
		join,
	]

	for i in STAT_CARDS.size():
		var id  : String = STAT_CARDS[i][0] as String
		var lbl : String = STAT_CARDS[i][1] as String
		_get_stat_node(id, "Icon").text = stat_icons[i]
		_get_stat_node(id, "Val").text  = stat_values[i]
		_get_stat_node(id, "Lbl").text  = lbl

# ─── Theme ───────────────────────────────────────────────────────────────────
func _build_theme() -> void:
	# TopBar
	var top_s : StyleBoxFlat = _flat(C_BG_BAR, Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.15), 0)
	top_s.border_width_bottom = 2
	top_s.border_width_top = 0; top_s.border_width_left = 0; top_s.border_width_right = 0
	($Root/TopBar as PanelContainer).add_theme_stylebox_override("panel", top_s)
	page_title.add_theme_color_override("font_color", C_RED_SON)

	# Back button
	back_btn.add_theme_color_override("font_color", C_RED_SON)
	back_btn.add_theme_color_override("font_hover_color", C_RED_SON.lightened(0.2))
	back_btn.add_theme_stylebox_override("normal",  _flat(Color(0,0,0,0), Color(0,0,0,0), 8))
	back_btn.add_theme_stylebox_override("hover",   _flat(Color(C_RED_SON.r,C_RED_SON.g,C_RED_SON.b,0.1), Color(0,0,0,0), 8))
	back_btn.add_theme_stylebox_override("pressed", _flat(Color(C_RED_SON.r,C_RED_SON.g,C_RED_SON.b,0.18), Color(0,0,0,0), 8))
	back_btn.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0), 0))

	# Main card
	var cs : StyleBoxFlat = _flat(C_CARD, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.28), 22)
	cs.border_width_top = 4
	cs.shadow_size = 24; cs.shadow_color = Color(0.05, 0.02, 0.01, 0.12)
	cs.shadow_offset = Vector2(0, 8)
	card_node.add_theme_stylebox_override("panel", cs)

	# Avatar circle
	var av_s : StyleBoxFlat = _flat(Color(0.97, 0.92, 0.84, 1.0), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.75), 48)
	av_s.border_width_left = 3; av_s.border_width_right = 3
	av_s.border_width_top  = 3; av_s.border_width_bottom = 3
	av_s.shadow_size = 8; av_s.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.2)
	av_circle.add_theme_stylebox_override("panel", av_s)

	# Name & email
	name_lbl.add_theme_color_override("font_color", C_TEXT)
	email_lbl.add_theme_color_override("font_color", C_TEXT_MUTED)

	# Divider
	var div_s : StyleBoxFlat = StyleBoxFlat.new()
	div_s.bg_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.18)
	div_s.content_margin_top = 1; div_s.content_margin_bottom = 1
	divider.add_theme_stylebox_override("separator", div_s)

	# Stat cards
	for sc in STAT_CARDS:
		var id  : String = sc[0] as String
		var bg  : Color  = sc[2] as Color
		var brd : Color  = sc[3] as Color
		var acc : Color  = sc[4] as Color
		var nc  : PanelContainer = grid.get_node(id) as PanelContainer
		var card_s : StyleBoxFlat = _flat(bg, brd, 16)
		card_s.border_width_top = 3
		card_s.shadow_size = 4; card_s.shadow_color = Color(0, 0, 0, 0.05)
		nc.add_theme_stylebox_override("panel", card_s)
		_get_stat_node(id, "Icon").add_theme_color_override("font_color", acc)
		_get_stat_node(id, "Val").add_theme_color_override("font_color", C_TEXT)
		_get_stat_node(id, "Lbl").add_theme_color_override("font_color", C_TEXT_MUTED)

	# Logout button
	var lg_n : StyleBoxFlat = _flat(C_CARD, Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.4), 14)
	var lg_h : StyleBoxFlat = _flat(C_BG_BAR, Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.75), 14)
	lg_h.shadow_size = 4; lg_h.shadow_color = Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.1)
	logout_btn.add_theme_stylebox_override("normal",  lg_n)
	logout_btn.add_theme_stylebox_override("hover",   lg_h)
	logout_btn.add_theme_stylebox_override("pressed", _flat(C_BG_BAR, Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.5), 14))
	logout_btn.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	logout_btn.add_theme_color_override("font_color",         C_TEXT)
	logout_btn.add_theme_color_override("font_hover_color",   C_RED_SON)
	logout_btn.add_theme_color_override("font_pressed_color", C_RED_SON)

	# Version label
	ver_label.add_theme_color_override("font_color", Color(C_TEXT_MUTED.r, C_TEXT_MUTED.g, C_TEXT_MUTED.b, 0.45))

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
	var inner : int = 28 if mobile else 56
	card_m.add_theme_constant_override("margin_left",   inner)
	card_m.add_theme_constant_override("margin_right",  inner)

	page_title.add_theme_font_size_override("font_size", 20 if mobile else 26)
	name_lbl.add_theme_font_size_override("font_size",   18 if mobile else 24)
	email_lbl.add_theme_font_size_override("font_size",  12 if mobile else 14)


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
