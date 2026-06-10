extends Control

# ─── Vietnamese Traditional Color Palette ──────────────────────────────────────
const C_GOLD       := Color(0.77, 0.58, 0.15, 1.0)
const C_GOLD_LIGHT := Color(0.95, 0.82, 0.45, 1.0)
const C_JADE       := Color(0.12, 0.37, 0.23, 1.0)
const C_RED_SON    := Color(0.70, 0.12, 0.08, 1.0)
const C_CREAM      := Color(1.00, 0.97, 0.88, 1.0)
const C_CREAM_DIM  := Color(0.80, 0.76, 0.66, 1.0)

const C_BG         := Color(0.98, 0.97, 0.93, 1.0)
const C_BG_BAR     := Color(0.95, 0.93, 0.89, 1.0)
const C_CARD       := Color(1.00, 1.00, 1.00, 1.0)
const C_TEXT       := Color(0.13, 0.08, 0.05, 1.0)
const C_TEXT_MUTED := Color(0.43, 0.38, 0.33, 1.0)

const GRID_DATA := [
	["G1", "🔥", "7 Ngày", "Chuỗi học liên tiếp", Color(0.99, 0.94, 0.90, 1.0), Color(0.95, 0.75, 0.60, 0.6), Color(0.90, 0.45, 0.10, 1.0)],
	["G2", "✨", "1.240 XP", "Tổng điểm tích lũy", Color(0.99, 0.97, 0.90, 1.0), Color(0.92, 0.85, 0.60, 0.6), Color(0.77, 0.58, 0.15, 1.0)],
	["G3", "🏆", "Cấp Độ 8", "Hạng vàng tuần này", Color(0.93, 0.97, 0.94, 1.0), Color(0.75, 0.88, 0.80, 0.6), Color(0.12, 0.37, 0.23, 1.0)],
	["G4", "📅", "26/05/2026", "Ngày gia nhập", Color(0.94, 0.95, 0.99, 1.0), Color(0.78, 0.82, 0.95, 0.6), Color(0.20, 0.40, 0.80, 1.0)],
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
		var status_s := _flat(C_GOLD, Color(1, 1, 1, 0.15), 30)
		status_pill.add_theme_stylebox_override("panel", status_s)
		status_lbl.add_theme_color_override("font_color", Color(1,1,1,1))
	else:
		status_lbl.text = "🔒 NÂNG CẤP PREMIUM (CLICK)"
		var status_s := _flat(C_BG_BAR, Color(C_TEXT_MUTED.r, C_TEXT_MUTED.g, C_TEXT_MUTED.b, 0.4), 30)
		status_pill.add_theme_stylebox_override("panel", status_s)
		status_lbl.add_theme_color_override("font_color", C_TEXT_MUTED)

func _build_theme() -> void:
	# Main Background ColorRect
	var bg_rect := get_node_or_null("BG") as ColorRect
	if bg_rect:
		bg_rect.color = C_BG

	# Top bar style
	var top_s := _flat(C_BG_BAR, Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.15), 0)
	top_s.border_width_bottom = 2; top_s.border_width_top = 0; top_s.border_width_left = 0; top_s.border_width_right = 0
	($Root/TopBar as PanelContainer).add_theme_stylebox_override("panel", top_s)
	page_title.add_theme_color_override("font_color", C_RED_SON)

	# Back button style
	back_btn.add_theme_color_override("font_color", C_RED_SON)
	back_btn.add_theme_color_override("font_hover_color", C_RED_SON.lightened(0.15))
	back_btn.add_theme_stylebox_override("normal",  _flat(Color(0,0,0,0), Color(0,0,0,0), 8))
	back_btn.add_theme_stylebox_override("hover",   _flat(Color(C_RED_SON.r,C_RED_SON.g,C_RED_SON.b,0.12), Color(0,0,0,0), 8))
	back_btn.add_theme_stylebox_override("pressed", _flat(Color(C_RED_SON.r,C_RED_SON.g,C_RED_SON.b,0.20), Color(0,0,0,0), 8))
	back_btn.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	back_btn.text = "Quay Lại"

	# Left panel / card style - beige panel with right border
	var left_s := _flat(C_BG_BAR, Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.1), 0)
	left_s.border_width_right = 2; left_s.border_width_left = 0; left_s.border_width_top = 0; left_s.border_width_bottom = 0
	($Root/Content/LeftCard as PanelContainer).add_theme_stylebox_override("panel", left_s)

	# Avatar Circle
	var av_s := _flat(C_CARD, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.65), 80)
	av_s.border_width_left = 4; av_s.border_width_right = 4; av_s.border_width_top = 4; av_s.border_width_bottom = 4
	av_s.shadow_size = 10; av_s.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.15)
	($Root/Content/LeftCard/LeftM/LeftV/AvatarCircle as PanelContainer).add_theme_stylebox_override("panel", av_s)

	# Name LineEdit
	var name_s := StyleBoxFlat.new()
	name_s.bg_color = Color(0, 0, 0, 0.05)
	name_s.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35)
	name_s.border_width_bottom = 2
	name_s.corner_radius_top_left = 6; name_s.corner_radius_top_right = 6
	name_edit.add_theme_stylebox_override("normal", name_s)
	name_edit.add_theme_stylebox_override("focus", name_s)
	name_edit.add_theme_color_override("font_color", C_TEXT)

	# Email label
	email_lbl.add_theme_color_override("font_color", C_TEXT_MUTED)

	# Logout Button - light container with red border
	var btn_s := _flat(C_CARD, Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.45), 18)
	var btn_s_h := _flat(C_CARD, Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.85), 18)
	btn_s_h.shadow_size = 5; btn_s_h.shadow_color = Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.15)
	
	logout_btn.add_theme_stylebox_override("normal", btn_s)
	logout_btn.add_theme_stylebox_override("hover", btn_s_h)
	logout_btn.add_theme_stylebox_override("pressed", _flat(Color(0.95, 0.93, 0.89, 1.0), Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.5), 18))
	logout_btn.add_theme_stylebox_override("focus", _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	logout_btn.add_theme_color_override("font_color", C_TEXT)
	logout_btn.add_theme_color_override("font_hover_color", C_RED_SON)

	# Right panel style
	var right_s := _flat(C_BG, Color(0, 0, 0, 0), 0)
	($Root/Content/RightCard as PanelContainer).add_theme_stylebox_override("panel", right_s)
	stats_title.add_theme_color_override("font_color", C_RED_SON)
	ver_label.add_theme_color_override("font_color", C_TEXT_MUTED)

	# Stat cards
	for gd in GRID_DATA:
		var name_node := gd[0] as String
		var card := $Root/Content/RightCard/RightM/RightV/Grid.get_node(name_node) as PanelContainer
		var cs := _flat(gd[4] as Color, gd[5] as Color, 18)
		cs.shadow_size = 5; cs.shadow_color = Color(0,0,0,0.06)
		card.add_theme_stylebox_override("panel", cs)
		
		var col := gd[6] as Color
		($Root/Content/RightCard/RightM/RightV/Grid.get_node(name_node + "/" + name_node + "M/" + name_node + "V/Icon") as Label).add_theme_color_override("font_color", col)
		($Root/Content/RightCard/RightM/RightV/Grid.get_node(name_node + "/" + name_node + "M/" + name_node + "V/Val")  as Label).add_theme_color_override("font_color", C_TEXT)
		($Root/Content/RightCard/RightM/RightV/Grid.get_node(name_node + "/" + name_node + "M/" + name_node + "V/Lbl")  as Label).add_theme_color_override("font_color", C_TEXT_MUTED)

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

