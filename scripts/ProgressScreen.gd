extends Control

const C_GOLD       := Color(0.95, 0.72, 0.18, 1.0)
const C_GOLD_LIGHT := Color(1.00, 0.87, 0.45, 1.0)
const C_JADE       := Color(0.18, 0.62, 0.42, 1.0)
const C_RED_SON    := Color(0.72, 0.12, 0.08, 1.0)
const C_CREAM      := Color(1.00, 0.97, 0.88, 1.0)
const C_CREAM_DIM  := Color(0.80, 0.76, 0.66, 1.0)

const ACHIEVEMENTS: Array[Dictionary] = [
	{"icon":"","name":"Ngôi Sao\nĐầu Tiên",  "sub":"21/05/2025",  "earned":true,  "col":Color(0.95,0.72,0.18,1)},
	{"icon":"","name":"7 Ngày\nLiên Tiếp",   "sub":"Streak 7",    "earned":true,  "col":Color(0.92,0.45,0.10,1)},
	{"icon":"","name":"Bài 4\nHoàn Thành",   "sub":"Điểm 88",     "earned":true,  "col":Color(0.20,0.65,0.42,1)},
	{"icon":"","name":"Hoàn Hảo\n100%",       "sub":"1 lần",       "earned":true,  "col":Color(0.40,0.72,0.92,1)},
	{"icon":"","name":"10 Bài\nHoàn Thành",   "sub":"Cần 8 bài",   "earned":false, "col":Color(0.95,0.72,0.18,0.4)},
	{"icon":"","name":"Nghệ Sĩ\nNâng Cao",    "sub":"Cần lv.12",   "earned":false, "col":Color(0.72,0.12,0.08,0.4)},
	{"icon":"","name":"Hoa Mai\nMùa Xuân",    "sub":"Tháng 1/26",  "earned":false, "col":Color(0.90,0.55,0.20,0.4)},
	{"icon":"","name":"Sáo Trúc\nMaster",     "sub":"Cần lv.15",   "earned":false, "col":Color(0.18,0.62,0.42,0.4)},
]

const STAT_DATA := [
	["S1", "", "7",     "Ngày streak", Color(0.40,0.12,0.02,0.9), Color(0.90,0.40,0.08,0.7), Color(1.0,0.65,0.18,1)],
	["S2", "", "1.240", "Tổng XP",     Color(0.22,0.18,0.02,0.9), Color(C_GOLD.r,C_GOLD.g,C_GOLD.b,0.7), C_GOLD_LIGHT],
	["S3", "", "14h",   "Luyện tập",   Color(0.05,0.20,0.12,0.9), Color(C_JADE.r,C_JADE.g,C_JADE.b,0.7), Color(0.5,0.95,0.72,1)],
	["S4", "", "78%",   "Chính xác",   Color(0.08,0.08,0.22,0.9), Color(0.40,0.55,0.92,0.7), Color(0.55,0.75,0.98,1)],
]

func _ready() -> void:
	_build_theme()
	_set_labels()
	_build_achievements()
	_animate_in()
	var back_btn := $Root/TopBar/TopM/TopH/BackBtn as Button
	back_btn.pressed.connect(_go_back)
	_make_button_bouncy(back_btn)
	# Connect export button if present
	if $Root/TopBar/TopM/TopH.has_node("ExportBtn"):
		var export_btn := $Root/TopBar/TopM/TopH/ExportBtn as Button
		export_btn.pressed.connect(_export_csv)
		_make_button_bouncy(export_btn)


func _set_labels() -> void:
	($Root/TopBar/TopM/TopH/BackBtn    as Button).text = "Quay lại"
	($Root/TopBar/TopM/TopH/PageTitle  as Label ).text = "Tiến độ học tập"

	($Root/Content/ProfilePanel/ProfileM/ProfileV/PlayerName  as Label).text = "Linh"
	($Root/Content/ProfilePanel/ProfileM/ProfileV/LevelBadge/LBM/LBLabel as Label).text = "Cấp độ 8"

	($Root/Content/ProfilePanel/ProfileM/ProfileV/LvlHBox/LvlLabel as Label).text = "Cấp độ 8"
	($Root/Content/ProfilePanel/ProfileM/ProfileV/LvlHBox/XpLabel  as Label).text = "1.240 / 2.000 XP"

	($Root/Content/AchPanel/AchM/AchV/AchTitle as Label).text = "Huy hiệu thành tích"

	# Stat grid labels
	for sd in STAT_DATA:
		var sname := sd[0] as String
		($Root/Content/ProfilePanel/ProfileM/ProfileV/StatGrid.get_node(sname + "/" + sname + "M/" + sname + "V/" + sname + "Icon") as Label).text = sd[1] as String
		($Root/Content/ProfilePanel/ProfileM/ProfileV/StatGrid.get_node(sname + "/" + sname + "M/" + sname + "V/" + sname + "Val")  as Label).text = sd[2] as String
		($Root/Content/ProfilePanel/ProfileM/ProfileV/StatGrid.get_node(sname + "/" + sname + "M/" + sname + "V/" + sname + "Lbl")  as Label).text = sd[3] as String

func _build_theme() -> void:
	# Top bar
	var top_s := _flat(Color(0.06,0.03,0.012,0.98), Color(C_GOLD.r,C_GOLD.g,C_GOLD.b,0.22), 0)
	top_s.border_width_bottom = 3; top_s.border_width_top = 0; top_s.border_width_left = 0; top_s.border_width_right = 0
	($Root/TopBar as PanelContainer).add_theme_stylebox_override("panel", top_s)
	($Root/TopBar/TopM/TopH/PageTitle as Label).add_theme_color_override("font_color", C_GOLD)

	var back := $Root/TopBar/TopM/TopH/BackBtn as Button
	back.add_theme_color_override("font_color",       C_GOLD)
	back.add_theme_color_override("font_hover_color", C_GOLD_LIGHT)
	back.add_theme_stylebox_override("normal",  _flat(Color(0,0,0,0), Color(0,0,0,0), 8))
	back.add_theme_stylebox_override("hover",   _flat(Color(C_GOLD.r,C_GOLD.g,C_GOLD.b,0.12), Color(0,0,0,0), 8))
	back.add_theme_stylebox_override("pressed", _flat(Color(C_GOLD.r,C_GOLD.g,C_GOLD.b,0.20), Color(0,0,0,0), 8))
	back.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0), 0))

	# Profile panel
	var pp_s := _flat(Color(0.07,0.038,0.015,0.97), Color(C_GOLD.r,C_GOLD.g,C_GOLD.b,0.20), 0)
	pp_s.border_width_right = 2; pp_s.border_width_left = 0; pp_s.border_width_top = 0; pp_s.border_width_bottom = 0
	($Root/Content/ProfilePanel as PanelContainer).add_theme_stylebox_override("panel", pp_s)

	($Root/Content/ProfilePanel/ProfileM/ProfileV/PlayerName as Label).add_theme_color_override("font_color", C_CREAM)

	# Level badge pill
	var lb_s := _flat(Color(0.28,0.18,0.03,0.95), Color(C_GOLD.r,C_GOLD.g,C_GOLD.b,0.75), 30)
	lb_s.shadow_size = 8; lb_s.shadow_color = Color(C_GOLD.r,C_GOLD.g,C_GOLD.b,0.28)
	($Root/Content/ProfilePanel/ProfileM/ProfileV/LevelBadge as PanelContainer).add_theme_stylebox_override("panel", lb_s)
	($Root/Content/ProfilePanel/ProfileM/ProfileV/LevelBadge/LBM/LBLabel as Label).add_theme_color_override("font_color", C_GOLD)

	# Avatar circle
	var av_s := _flat(Color(0.20,0.13,0.04,1.0), Color(C_GOLD.r,C_GOLD.g,C_GOLD.b,0.80), 75)
	av_s.border_width_left = 5; av_s.border_width_right = 5; av_s.border_width_top = 5; av_s.border_width_bottom = 5
	av_s.shadow_size = 14; av_s.shadow_color = Color(C_GOLD.r,C_GOLD.g,C_GOLD.b,0.32)
	($Root/Content/ProfilePanel/ProfileM/ProfileV/AvatarCircle as PanelContainer).add_theme_stylebox_override("panel", av_s)

	($Root/Content/ProfilePanel/ProfileM/ProfileV/LvlHBox/LvlLabel as Label).add_theme_color_override("font_color", C_CREAM)
	($Root/Content/ProfilePanel/ProfileM/ProfileV/LvlHBox/XpLabel  as Label).add_theme_color_override("font_color", C_GOLD)

	# Level bar
	var pb := $Root/Content/ProfilePanel/ProfileM/ProfileV/LvlBar as ProgressBar
	var pf := StyleBoxFlat.new(); pf.bg_color = C_GOLD
	pf.corner_radius_top_left = 9; pf.corner_radius_top_right = 9
	pf.corner_radius_bottom_left = 9; pf.corner_radius_bottom_right = 9
	pf.shadow_size = 7; pf.shadow_color = Color(C_GOLD.r,C_GOLD.g,C_GOLD.b,0.38)
	var pbg := StyleBoxFlat.new(); pbg.bg_color = Color(0,0,0,0.4)
	pbg.corner_radius_top_left = 9; pbg.corner_radius_top_right = 9
	pbg.corner_radius_bottom_left = 9; pbg.corner_radius_bottom_right = 9
	pb.add_theme_stylebox_override("fill", pf)
	pb.add_theme_stylebox_override("background", pbg)

	# Stat cards
	for sd in STAT_DATA:
		var sname := sd[0] as String
		var card  := $Root/Content/ProfilePanel/ProfileM/ProfileV/StatGrid.get_node(sname) as PanelContainer
		var cs := _flat(sd[4] as Color, sd[5] as Color, 18)
		cs.shadow_size = 8; cs.shadow_color = Color(0,0,0,0.35)
		card.add_theme_stylebox_override("panel", cs)
		var col := sd[6] as Color
		($Root/Content/ProfilePanel/ProfileM/ProfileV/StatGrid.get_node(sname + "/" + sname + "M/" + sname + "V/" + sname + "Icon") as Label).add_theme_color_override("font_color", col)
		($Root/Content/ProfilePanel/ProfileM/ProfileV/StatGrid.get_node(sname + "/" + sname + "M/" + sname + "V/" + sname + "Val")  as Label).add_theme_color_override("font_color", C_CREAM)
		($Root/Content/ProfilePanel/ProfileM/ProfileV/StatGrid.get_node(sname + "/" + sname + "M/" + sname + "V/" + sname + "Lbl")  as Label).add_theme_color_override("font_color", C_CREAM_DIM)

	# Ach panel
	var ap_s := _flat(Color(0.09,0.05,0.02,0.95), Color(C_GOLD.r,C_GOLD.g,C_GOLD.b,0.15), 0)
	($Root/Content/AchPanel as PanelContainer).add_theme_stylebox_override("panel", ap_s)
	($Root/Content/AchPanel/AchM/AchV/AchTitle as Label).add_theme_color_override("font_color", C_GOLD)

func _build_achievements() -> void:
	var grid := $Root/Content/AchPanel/AchM/AchV/AchGrid as GridContainer
	for c in grid.get_children(): c.queue_free()

	for ach: Dictionary in ACHIEVEMENTS:
		var earned : bool  = ach["earned"]
		var col    : Color = ach["col"]

		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.size_flags_vertical   = Control.SIZE_EXPAND_FILL
		card.modulate.a = 0.0

		var cs := _flat(
			Color(col.r * 0.28, col.g * 0.28, col.b * 0.28, 0.90 if earned else 0.50),
			Color(col.r, col.g, col.b, 0.80 if earned else 0.28), 22
		)
		if earned: cs.shadow_size = 14; cs.shadow_color = Color(col.r, col.g, col.b, 0.35)
		card.add_theme_stylebox_override("panel", cs)

		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 8)
		vb.alignment = BoxContainer.ALIGNMENT_CENTER

		var il := Label.new()
		il.text = ach["icon"] as String
		il.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		il.add_theme_font_size_override("font_size", 44 if earned else 30)
		if not earned: il.modulate.a = 0.35
		vb.add_child(il)

		var nl := Label.new()
		nl.text = ach["name"] as String
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.add_theme_font_size_override("font_size", 15)
		nl.add_theme_color_override("font_color", C_CREAM if earned else C_CREAM_DIM)
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD
		vb.add_child(nl)

		var sl := Label.new()
		sl.text = ach["sub"] as String
		sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sl.add_theme_font_size_override("font_size", 13)
		sl.add_theme_color_override("font_color", col if earned else Color(0.38,0.34,0.26,0.7))
		vb.add_child(sl)

		card.add_child(vb)
		grid.add_child(card)

func _animate_in() -> void:
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.35)
	var grid := $Root/Content/AchPanel/AchM/AchV/AchGrid as GridContainer
	var delay := 0.12
	for card in grid.get_children():
		var c := card as Control
		var t := create_tween().set_parallel(true)
		t.tween_property(c, "modulate:a", 1.0, 0.38).set_delay(delay)
		t.tween_property(c, "scale", Vector2.ONE, 0.42).from(Vector2(0.72,0.72)).set_delay(delay)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		delay += 0.065

func _go_back() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.22)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))

func _export_csv() -> void:
	# Export a simple CSV summary to user://progress_export.csv
	var path := "user://progress_export.csv"
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		print("Failed to open file for export")
		return
	# Header
	f.store_line("metric,value,detail")
	# Stats
	for sd in STAT_DATA:
		var key := sd[0] as String
		var val := sd[2] as String
		var lbl := sd[3] as String
		f.store_line("%s,%s,%s" % [key, val, lbl])
	# Achievements
	f.store_line("\nachievement,earned,info")
	for ach in ACHIEVEMENTS:
		f.store_line("%s,%s,%s" % [ach["name"], ach["earned"], ach["sub"]])
	f.flush()
	# Small visual confirmation by briefly changing title
	var old := ($Root/TopBar/TopM/TopH/PageTitle as Label).text
	($Root/TopBar/TopM/TopH/PageTitle as Label).text = "Đã xuất: %s" % path
	var t := create_tween()
	t.tween_property($Root/TopBar/TopM/TopH/PageTitle, "modulate:a", 0.6, 0.0)
	t.tween_property($Root/TopBar/TopM/TopH/PageTitle, "modulate:a", 1.0, 0.4).set_delay(0.0)
	t.set_delay(1.6).tween_callback(func() -> void: ($Root/TopBar/TopM/TopH/PageTitle as Label).text = old)

func _flat(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.border_color = border
	s.border_width_left = 2; s.border_width_right  = 2
	s.border_width_top  = 2; s.border_width_bottom = 2
	s.corner_radius_top_left     = radius; s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius; s.corner_radius_bottom_right = radius
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

