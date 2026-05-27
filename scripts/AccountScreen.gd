extends Control

# ─── Vietnamese Traditional Color Palette ──────────────────────────────────────
const C_GOLD       := Color(0.95, 0.72, 0.18, 1.0)
const C_GOLD_LIGHT := Color(1.00, 0.87, 0.45, 1.0)
const C_JADE       := Color(0.18, 0.62, 0.42, 1.0)
const C_RED_SON    := Color(0.72, 0.12, 0.08, 1.0)
const C_CREAM      := Color(1.00, 0.97, 0.88, 1.0)
const C_CREAM_DIM  := Color(0.80, 0.76, 0.66, 1.0)

const GRID_DATA := [
	["G1", "", "7 Ngày", "Chuỗi học liên tiếp", Color(0.40,0.12,0.02,0.9), Color(0.90,0.40,0.08,0.7), Color(1.0,0.65,0.18,1)],
	["G2", "", "1.240 XP", "Tổng điểm tích lũy", Color(0.22,0.18,0.02,0.9), Color(C_GOLD.r,C_GOLD.g,C_GOLD.b,0.7), C_GOLD_LIGHT],
	["G3", "", "Cấp Độ 8", "Hạng vàng tuần này", Color(0.05,0.20,0.12,0.9), Color(C_JADE.r,C_JADE.g,C_JADE.b,0.7), Color(0.5,0.95,0.72,1)],
	["G4", "", "26/05/2026", "Ngày gia nhập", Color(0.08,0.08,0.22,0.9), Color(0.40,0.55,0.92,0.7), Color(0.55,0.75,0.98,1)],
]

@onready var back_btn: Button        = $Root/TopBar/TopM/TopH/BackBtn
@onready var page_title: Label       = $Root/TopBar/TopM/TopH/PageTitle
@onready var name_edit: LineEdit     = $Root/Content/LeftCard/LeftM/LeftV/NameEdit
@onready var email_lbl: Label        = $Root/Content/LeftCard/LeftM/LeftV/EmailLabel
@onready var status_lbl: Label       = $Root/Content/LeftCard/LeftM/LeftV/StatusPill/SPM/SPLabel
@onready var logout_btn: Button      = $Root/Content/LeftCard/LeftM/LeftV/LogoutBtn
@onready var stats_title: Label      = $Root/Content/RightCard/RightM/RightV/StatsTitle
@onready var ver_label: Label        = $Root/Content/RightCard/RightM/RightV/Version

func _ready() -> void:
	_build_theme()
	_set_labels()
	_animate_in()
	back_btn.pressed.connect(_go_back)
	logout_btn.pressed.connect(_on_logout)
	_make_button_bouncy(back_btn)
	_make_button_bouncy(logout_btn)
	
	# Connect Status Pill to toggle premium
	var status_pill := $Root/Content/LeftCard/LeftM/LeftV/StatusPill as PanelContainer
	status_pill.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	status_pill.pivot_offset = Vector2(100, 16) # default half size estimate
	status_pill.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			var current_premium : bool = SecureDataManager.data.get("is_premium", false)
			SecureDataManager.data["is_premium"] = not current_premium
			SecureDataManager.save_data()
			_update_premium_status()
			
			# Pop animation
			var t := create_tween()
			t.tween_property(status_pill, "scale", Vector2(1.08, 1.08), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			t.tween_property(status_pill, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_BACK)
	)

func _set_labels() -> void:
	page_title.text = "Tài Khoản Của Tôi"
	name_edit.text = "Linh"
	email_lbl.text = "linh.vietstage@gmail.com"
	_update_premium_status()
	logout_btn.text = "Đăng Xuất"
	stats_title.text = "Thông Tin & Tiến Trình Học"
	ver_label.text = "VietStage v1.0.0 · Đồ Án Tốt Nghiệp · Khoa CNTT"

	for gd in GRID_DATA:
		var name_node := gd[0] as String
		($Root/Content/RightCard/RightM/RightV/Grid.get_node(name_node + "/" + name_node + "M/" + name_node + "V/Icon") as Label).text = gd[1] as String
		($Root/Content/RightCard/RightM/RightV/Grid.get_node(name_node + "/" + name_node + "M/" + name_node + "V/Val")  as Label).text = gd[2] as String
		($Root/Content/RightCard/RightM/RightV/Grid.get_node(name_node + "/" + name_node + "M/" + name_node + "V/Lbl")  as Label).text = gd[3] as String

func _update_premium_status() -> void:
	var is_prem : bool = SecureDataManager.data.get("is_premium", false)
	var status_pill := $Root/Content/LeftCard/LeftM/LeftV/StatusPill as PanelContainer
	if is_prem:
		status_lbl.text = "⭐ TÀI KHOẢN PREMIUM"
		var status_s := _flat(Color(0.28, 0.18, 0.03, 0.95), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.75), 30)
		status_s.shadow_size = 8
		status_s.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25)
		status_pill.add_theme_stylebox_override("panel", status_s)
		status_lbl.add_theme_color_override("font_color", C_GOLD)
	else:
		status_lbl.text = "🔒 NÂNG CẤP PREMIUM (CLICK)"
		var status_s := _flat(Color(0.12, 0.06, 0.04, 0.5), Color(C_CREAM_DIM.r, C_CREAM_DIM.g, C_CREAM_DIM.b, 0.4), 30)
		status_s.shadow_size = 0
		status_pill.add_theme_stylebox_override("panel", status_s)
		status_lbl.add_theme_color_override("font_color", C_CREAM_DIM)

func _build_theme() -> void:
	# Top bar style
	var top_s := _flat(Color(0.06, 0.03, 0.012, 0.98), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.22), 0)
	top_s.border_width_bottom = 3; top_s.border_width_top = 0; top_s.border_width_left = 0; top_s.border_width_right = 0
	($Root/TopBar as PanelContainer).add_theme_stylebox_override("panel", top_s)
	page_title.add_theme_color_override("font_color", C_GOLD)

	# Back button style
	back_btn.add_theme_color_override("font_color", C_GOLD)
	back_btn.add_theme_color_override("font_hover_color", C_GOLD_LIGHT)
	back_btn.add_theme_stylebox_override("normal",  _flat(Color(0,0,0,0), Color(0,0,0,0), 8))
	back_btn.add_theme_stylebox_override("hover",   _flat(Color(C_GOLD.r,C_GOLD.g,C_GOLD.b,0.12), Color(0,0,0,0), 8))
	back_btn.add_theme_stylebox_override("pressed", _flat(Color(C_GOLD.r,C_GOLD.g,C_GOLD.b,0.20), Color(0,0,0,0), 8))
	back_btn.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	back_btn.text = "Quay Lại"

	# Left panel / card style - lacquer dark wood style
	var left_s := _flat(Color(0.07, 0.038, 0.015, 0.97), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.20), 0)
	left_s.border_width_right = 2; left_s.border_width_left = 0; left_s.border_width_top = 0; left_s.border_width_bottom = 0
	($Root/Content/LeftCard as PanelContainer).add_theme_stylebox_override("panel", left_s)

	# Avatar Circle
	var av_s := _flat(Color(0.20, 0.13, 0.04, 1.0), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.80), 80)
	av_s.border_width_left = 5; av_s.border_width_right = 5; av_s.border_width_top = 5; av_s.border_width_bottom = 5
	av_s.shadow_size = 14; av_s.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.32)
	($Root/Content/LeftCard/LeftM/LeftV/AvatarCircle as PanelContainer).add_theme_stylebox_override("panel", av_s)

	# Name LineEdit
	var name_s := StyleBoxFlat.new()
	name_s.bg_color = Color(0, 0, 0, 0.25)
	name_s.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25)
	name_s.border_width_bottom = 2
	name_s.corner_radius_top_left = 6; name_s.corner_radius_top_right = 6
	name_edit.add_theme_stylebox_override("normal", name_s)
	name_edit.add_theme_stylebox_override("focus", name_s)
	name_edit.add_theme_color_override("font_color", C_CREAM)

	# Email label
	email_lbl.add_theme_color_override("font_color", C_CREAM_DIM)

	# Logout Button - red lacquer gold
	var btn_s := _flat(Color(0.12, 0.06, 0.04, 0.5), Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.5), 18)
	var btn_s_h := _flat(C_RED_SON, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.6), 18)
	btn_s_h.shadow_size = 10; btn_s_h.shadow_color = Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.3)
	
	logout_btn.add_theme_stylebox_override("normal", btn_s)
	logout_btn.add_theme_stylebox_override("hover", btn_s_h)
	logout_btn.add_theme_stylebox_override("pressed", _flat(C_RED_SON.darkened(0.2), Color(0,0,0,0), 18))
	logout_btn.add_theme_stylebox_override("focus", _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	logout_btn.add_theme_color_override("font_color", C_CREAM_DIM)
	logout_btn.add_theme_color_override("font_hover_color", C_GOLD)

	# Right panel style
	var right_s := _flat(Color(0.09, 0.05, 0.02, 0.95), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.15), 0)
	($Root/Content/RightCard as PanelContainer).add_theme_stylebox_override("panel", right_s)
	stats_title.add_theme_color_override("font_color", C_GOLD)
	ver_label.add_theme_color_override("font_color", Color(0.40, 0.36, 0.26, 1.0))

	# Stat cards
	for gd in GRID_DATA:
		var name_node := gd[0] as String
		var card := $Root/Content/RightCard/RightM/RightV/Grid.get_node(name_node) as PanelContainer
		var cs := _flat(gd[4] as Color, gd[5] as Color, 18)
		cs.shadow_size = 8; cs.shadow_color = Color(0,0,0,0.3)
		card.add_theme_stylebox_override("panel", cs)
		
		var col := gd[6] as Color
		($Root/Content/RightCard/RightM/RightV/Grid.get_node(name_node + "/" + name_node + "M/" + name_node + "V/Icon") as Label).add_theme_color_override("font_color", col)
		($Root/Content/RightCard/RightM/RightV/Grid.get_node(name_node + "/" + name_node + "M/" + name_node + "V/Val")  as Label).add_theme_color_override("font_color", C_CREAM)
		($Root/Content/RightCard/RightM/RightV/Grid.get_node(name_node + "/" + name_node + "M/" + name_node + "V/Lbl")  as Label).add_theme_color_override("font_color", C_CREAM_DIM)

func _animate_in() -> void:
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.35)
	
	# Small delay stagger for stat grid items
	var delay := 0.15
	for gd in GRID_DATA:
		var name_node := gd[0] as String
		var card := $Root/Content/RightCard/RightM/RightV/Grid.get_node(name_node) as Control
		card.modulate.a = 0.0
		card.scale = Vector2(0.8, 0.8)
		var t := create_tween().set_parallel(true)
		t.tween_property(card, "modulate:a", 1.0, 0.35).set_delay(delay)
		t.tween_property(card, "scale", Vector2.ONE, 0.4).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		delay += 0.08

func _go_back() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.22)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))

func _on_logout() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.25)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/LoginScreen.tscn"))

func _flat(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.border_color = border
	s.border_width_left = 2; s.border_width_right = 2
	s.border_width_top = 2; s.border_width_bottom = 2
	s.corner_radius_top_left = radius; s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius; s.corner_radius_bottom_right = radius
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

