extends Control

const C_GOLD       := Color(0.77, 0.58, 0.15, 1.0)
const C_GOLD_LIGHT := Color(0.95, 0.82, 0.45, 1.0)
const C_JADE       := Color(0.12, 0.37, 0.23, 1.0)
const C_RED_SON    := Color(0.09, 0.27, 0.18, 1.0)
const C_CREAM      := Color(1.00, 0.97, 0.88, 1.0)
const C_CREAM_DIM  := Color(0.80, 0.76, 0.66, 1.0)

const C_BG         := Color(0.98, 0.97, 0.93, 1.0)
const C_BG_BAR     := Color(0.95, 0.93, 0.89, 1.0)
const C_CARD       := Color(1.00, 1.00, 1.00, 1.0)
const C_TEXT       := Color(0.13, 0.08, 0.05, 1.0)
const C_TEXT_MUTED := Color(0.43, 0.38, 0.33, 1.0)

var _filter_earned_only := false
var empty_state_panel : PanelContainer = null

const ACHIEVEMENTS: Array[Dictionary] = [
	{"icon":"⭐", "name":"Ngôi Sao\nĐầu Tiên",  "sub":"21/05/2025",  "earned":true,  "col":Color(0.77,0.58,0.15,1)},
	{"icon":"🔥", "name":"7 Ngày\nLiên Tiếp",   "sub":"Streak 7",    "earned":true,  "col":Color(0.90,0.45,0.10,1)},
	{"icon":"🎓", "name":"Bài 4\nHoàn Thành",   "sub":"Điểm 88",     "earned":true,  "col":Color(0.12,0.37,0.23,1)},
	{"icon":"💯", "name":"Hoàn Hảo\n100%",       "sub":"1 lần",       "earned":true,  "col":Color(0.20,0.40,0.80,1)},
	{"icon":"🏆", "name":"10 Bài\nHoàn Thành",   "sub":"Cần 8 bài",   "earned":false, "col":Color(0.77,0.58,0.15,0.4)},
	{"icon":"🎻", "name":"Nghệ Sĩ\nNâng Cao",    "sub":"Cần lv.12",   "earned":false, "col":Color(0.09,0.27,0.18,0.4)},
	{"icon":"🌸", "name":"Hoa Mai\nMùa Xuân",    "sub":"Tháng 1/26",  "earned":false, "col":Color(0.90,0.55,0.20,0.4)},
	{"icon":"🎵", "name":"Sáo Trúc\nMaster",     "sub":"Cần lv.15",   "earned":false, "col":Color(0.12,0.37,0.23,0.4)},
]

const STAT_DATA := [
	["S1", "🔥", "7",     "Ngày streak", Color(0.99, 0.94, 0.90, 1.0), Color(0.95, 0.75, 0.60, 0.6), Color(0.90, 0.45, 0.10, 1.0)],
	["S2", "✨", "1.240", "Tổng XP",     Color(0.99, 0.97, 0.90, 1.0), Color(0.92, 0.85, 0.60, 0.6), Color(0.77, 0.58, 0.15, 1.0)],
	["S3", "⏱️", "14h",   "Luyện tập",   Color(0.93, 0.97, 0.94, 1.0), Color(0.75, 0.88, 0.80, 0.6), Color(0.12, 0.37, 0.23, 1.0)],
	["S4", "🎯", "78%",   "Chính xác",   Color(0.94, 0.95, 0.99, 1.0), Color(0.78, 0.82, 0.95, 0.6), Color(0.20, 0.40, 0.80, 1.0)],
]

func _ready() -> void:
	SecureDataManager.load_data()
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

	# Dynamic check button filter
	var filter_btn := CheckButton.new()
	filter_btn.text = "Chỉ hiển thị đã đạt"
	filter_btn.add_theme_font_size_override("font_size", 14)
	filter_btn.add_theme_color_override("font_color", C_TEXT_MUTED)
	filter_btn.focus_mode = Control.FOCUS_NONE
	$Root/Content/AchPanel/AchM/AchV.add_child(filter_btn)
	$Root/Content/AchPanel/AchM/AchV.move_child(filter_btn, 1)
	filter_btn.toggled.connect(func(button_pressed: bool) -> void:
		_filter_earned_only = button_pressed
		_build_achievements()
	)

	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()


func _set_labels() -> void:
	($Root/TopBar/TopM/TopH/BackBtn    as Button).text = "Quay lại"
	($Root/TopBar/TopM/TopH/PageTitle  as Label ).text = "Tiến độ học tập"

	($Root/Content/ProfilePanel/ProfileM/ProfileV/PlayerName  as Label).text = SecureDataManager.data.get("user_name", "Khách")
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
	# Main Background ColorRect
	var bg_rect := get_node_or_null("BG") as ColorRect
	if bg_rect:
		bg_rect.color = C_BG

	# Top bar
	var top_s := _flat(C_BG_BAR, Color(C_RED_SON.r,C_RED_SON.g,C_RED_SON.b,0.15), 0)
	top_s.border_width_bottom = 2; top_s.border_width_top = 0; top_s.border_width_left = 0; top_s.border_width_right = 0
	($Root/TopBar as PanelContainer).add_theme_stylebox_override("panel", top_s)
	($Root/TopBar/TopM/TopH/PageTitle as Label).add_theme_color_override("font_color", C_RED_SON)

	var back := $Root/TopBar/TopM/TopH/BackBtn as Button
	back.add_theme_color_override("font_color",       C_RED_SON)
	back.add_theme_color_override("font_hover_color", C_RED_SON.lightened(0.15))
	back.add_theme_stylebox_override("normal",  _flat(Color(0,0,0,0), Color(0,0,0,0), 8))
	back.add_theme_stylebox_override("hover",   _flat(Color(C_RED_SON.r,C_RED_SON.g,C_RED_SON.b,0.12), Color(0,0,0,0), 8))
	back.add_theme_stylebox_override("pressed", _flat(Color(C_RED_SON.r,C_RED_SON.g,C_RED_SON.b,0.20), Color(0,0,0,0), 8))
	back.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0), 0))

	# Profile panel
	var pp_s := _flat(C_BG_BAR, Color(C_RED_SON.r,C_RED_SON.g,C_RED_SON.b,0.1), 0)
	pp_s.border_width_right = 2; pp_s.border_width_left = 0; pp_s.border_width_top = 0; pp_s.border_width_bottom = 0
	($Root/Content/ProfilePanel as PanelContainer).add_theme_stylebox_override("panel", pp_s)

	($Root/Content/ProfilePanel/ProfileM/ProfileV/PlayerName as Label).add_theme_color_override("font_color", C_TEXT)

	# Level badge pill
	var lb_s := _flat(C_RED_SON, Color(1, 1, 1, 0.15), 30)
	($Root/Content/ProfilePanel/ProfileM/ProfileV/LevelBadge as PanelContainer).add_theme_stylebox_override("panel", lb_s)
	($Root/Content/ProfilePanel/ProfileM/ProfileV/LevelBadge/LBM/LBLabel as Label).add_theme_color_override("font_color", Color(1,1,1,1))

	# Avatar circle
	var av_s := _flat(C_CARD, Color(C_GOLD.r,C_GOLD.g,C_GOLD.b,0.65), 75)
	av_s.border_width_left = 4; av_s.border_width_right = 4; av_s.border_width_top = 4; av_s.border_width_bottom = 4
	av_s.shadow_size = 10; av_s.shadow_color = Color(C_GOLD.r,C_GOLD.g,C_GOLD.b,0.15)
	($Root/Content/ProfilePanel/ProfileM/ProfileV/AvatarCircle as PanelContainer).add_theme_stylebox_override("panel", av_s)

	($Root/Content/ProfilePanel/ProfileM/ProfileV/LvlHBox/LvlLabel as Label).add_theme_color_override("font_color", C_TEXT)
	($Root/Content/ProfilePanel/ProfileM/ProfileV/LvlHBox/XpLabel  as Label).add_theme_color_override("font_color", C_TEXT_MUTED)

	# Level bar
	var pb := $Root/Content/ProfilePanel/ProfileM/ProfileV/LvlBar as ProgressBar
	var pf := StyleBoxFlat.new(); pf.bg_color = C_GOLD
	pf.corner_radius_top_left = 9; pf.corner_radius_top_right = 9
	pf.corner_radius_bottom_left = 9; pf.corner_radius_bottom_right = 9
	pf.shadow_size = 4; pf.shadow_color = Color(C_GOLD.r,C_GOLD.g,C_GOLD.b,0.2)
	var pbg := StyleBoxFlat.new(); pbg.bg_color = Color(0,0,0,0.08)
	pbg.corner_radius_top_left = 9; pbg.corner_radius_top_right = 9
	pbg.corner_radius_bottom_left = 9; pbg.corner_radius_bottom_right = 9
	pb.add_theme_stylebox_override("fill", pf)
	pb.add_theme_stylebox_override("background", pbg)

	# Stat cards
	for sd in STAT_DATA:
		var sname := sd[0] as String
		var card  := $Root/Content/ProfilePanel/ProfileM/ProfileV/StatGrid.get_node(sname) as PanelContainer
		var cs := _flat(sd[4] as Color, sd[5] as Color, 18)
		cs.shadow_size = 5; cs.shadow_color = Color(0,0,0,0.06)
		card.add_theme_stylebox_override("panel", cs)
		var col := sd[6] as Color
		($Root/Content/ProfilePanel/ProfileM/ProfileV/StatGrid.get_node(sname + "/" + sname + "M/" + sname + "V/" + sname + "Icon") as Label).add_theme_color_override("font_color", col)
		($Root/Content/ProfilePanel/ProfileM/ProfileV/StatGrid.get_node(sname + "/" + sname + "M/" + sname + "V/" + sname + "Val")  as Label).add_theme_color_override("font_color", C_TEXT)
		($Root/Content/ProfilePanel/ProfileM/ProfileV/StatGrid.get_node(sname + "/" + sname + "M/" + sname + "V/" + sname + "Lbl")  as Label).add_theme_color_override("font_color", C_TEXT_MUTED)

	# Ach panel
	var ap_s := _flat(C_BG, Color(0, 0, 0, 0), 0)
	($Root/Content/AchPanel as PanelContainer).add_theme_stylebox_override("panel", ap_s)
	($Root/Content/AchPanel/AchM/AchV/AchTitle as Label).add_theme_color_override("font_color", C_RED_SON)

func _build_empty_state_node() -> void:
	if empty_state_panel: return
	
	empty_state_panel = PanelContainer.new()
	empty_state_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	empty_state_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var es := StyleBoxFlat.new()
	es.bg_color = Color(0.95, 0.93, 0.89, 0.5)
	es.corner_radius_top_left = 22; es.corner_radius_top_right = 22
	es.corner_radius_bottom_left = 22; es.corner_radius_bottom_right = 22
	empty_state_panel.add_theme_stylebox_override("panel", es)
	
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 12)
	
	var icon := Label.new()
	icon.text = "🏆"
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 54)
	icon.modulate.a = 0.35
	
	var title := Label.new()
	title.text = "Chưa có huy hiệu"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", C_TEXT)
	
	var desc := Label.new()
	desc.text = "Hoàn thành các bài học để mở khóa huy hiệu."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", C_TEXT_MUTED)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	
	vb.add_child(icon)
	vb.add_child(title)
	vb.add_child(desc)
	empty_state_panel.add_child(vb)
	$Root/Content/AchPanel/AchM/AchV.add_child(empty_state_panel)

func _build_achievements() -> void:
	var grid := $Root/Content/AchPanel/AchM/AchV/AchGrid as GridContainer
	for c in grid.get_children(): c.queue_free()

	var count := 0
	for ach: Dictionary in ACHIEVEMENTS:
		var earned : bool  = ach["earned"]
		if _filter_earned_only and not earned:
			continue
			
		count += 1
		var col    : Color = ach["col"]

		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.size_flags_vertical   = Control.SIZE_EXPAND_FILL
		card.modulate.a = 0.0

		var cs : StyleBoxFlat
		if earned:
			cs = _flat(Color(col.r, col.g, col.b, 0.06), Color(col.r, col.g, col.b, 0.5), 22)
			cs.shadow_size = 8; cs.shadow_color = Color(col.r, col.g, col.b, 0.12)
		else:
			cs = _flat(Color(0.95, 0.93, 0.89, 0.6), Color(0.85, 0.82, 0.75, 0.4), 22)
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
		nl.add_theme_color_override("font_color", C_TEXT if earned else Color(C_TEXT_MUTED.r, C_TEXT_MUTED.g, C_TEXT_MUTED.b, 0.6))
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD
		vb.add_child(nl)

		var sl := Label.new()
		sl.text = ach["sub"] as String
		sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sl.add_theme_font_size_override("font_size", 13)
		sl.add_theme_color_override("font_color", col if earned else Color(0.5,0.45,0.4,0.6))
		vb.add_child(sl)

		card.add_child(vb)
		grid.add_child(card)

	if count == 0:
		_build_empty_state_node()
		empty_state_panel.visible = true
		grid.visible = false
	else:
		if empty_state_panel:
			empty_state_panel.visible = false
		grid.visible = true
		_animate_in()

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
	t.tween_property($Root/TopBar/TopM/TopH/PageTitle, "modulate:a", 1.0, 0.4)
	t.tween_interval(1.6)
	t.tween_callback(func() -> void: ($Root/TopBar/TopM/TopH/PageTitle as Label).text = old)

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

func _on_viewport_size_changed() -> void:
	var size = get_viewport().size
	var is_mobile = size.x < size.y or size.x < 768
	
	var content_box := $Root/Content as BoxContainer
	content_box.vertical = is_mobile
	
	var profile_panel := $Root/Content/ProfilePanel as PanelContainer
	var grid := $Root/Content/AchPanel/AchM/AchV/AchGrid as GridContainer
	var pp_s = profile_panel.get_theme_stylebox("panel") as StyleBoxFlat
	
	if is_mobile:
		profile_panel.custom_minimum_size = Vector2(0, profile_panel.custom_minimum_size.y)
		$Root/TopBar/TopM.add_theme_constant_override("margin_left", 16)
		$Root/TopBar/TopM.add_theme_constant_override("margin_right", 16)
		if pp_s:
			pp_s.border_width_right = 0
			pp_s.border_width_bottom = 2
		grid.columns = 2
		
		var back_btn := $Root/TopBar/TopM/TopH/BackBtn as Button
		back_btn.custom_minimum_size = Vector2(100, back_btn.custom_minimum_size.y)
		($Root/TopBar/TopM/TopH/PageTitle as Label).add_theme_font_size_override("font_size", 20)
	else:
		profile_panel.custom_minimum_size = Vector2(340, profile_panel.custom_minimum_size.y)
		$Root/TopBar/TopM.add_theme_constant_override("margin_left", 32)
		$Root/TopBar/TopM.add_theme_constant_override("margin_right", 32)
		if pp_s:
			pp_s.border_width_right = 2
			pp_s.border_width_bottom = 0
		grid.columns = 4
		
		var back_btn := $Root/TopBar/TopM/TopH/BackBtn as Button
		back_btn.custom_minimum_size = Vector2(160, back_btn.custom_minimum_size.y)
		($Root/TopBar/TopM/TopH/PageTitle as Label).add_theme_font_size_override("font_size", 32)
