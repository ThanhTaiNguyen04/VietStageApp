extends Control

const C_BG_DARK    := Color(0.07, 0.04, 0.015, 1.0)
const C_BG_MID     := Color(0.14, 0.08, 0.03, 1.0)
const C_PANEL_DARK := Color(0.09, 0.05, 0.02, 0.94)
const C_GOLD       := Color(0.95, 0.72, 0.18, 1.0)
const C_GOLD_LIGHT := Color(1.00, 0.87, 0.45, 1.0)
const C_JADE       := Color(0.18, 0.62, 0.42, 1.0)
const C_RED_SON    := Color(0.72, 0.12, 0.08, 1.0)
const C_CREAM      := Color(1.00, 0.97, 0.88, 1.0)
const C_CREAM_DIM  := Color(0.80, 0.76, 0.66, 1.0)
const C_CARD_RED   := Color(0.38, 0.10, 0.05, 0.95)
const C_CARD_JADE  := Color(0.05, 0.20, 0.12, 0.95)
const C_CARD_DARK  := Color(0.10, 0.06, 0.025, 0.95)

var _float_tween : Tween

func _ready() -> void:
	_build_theme()
	_set_labels()
	_start_float()
	_connect_buttons()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.38)

func _set_labels() -> void:
	($Root/TopBar/TopMargin/TopHBox/Logo as Label).text = "VietStage"
	($Root/TopBar/TopMargin/TopHBox/NavBtns/BtnHome     as Button).text = "Trang chủ"
	($Root/TopBar/TopMargin/TopHBox/NavBtns/BtnCourses  as Button).text = "Bài học"
	($Root/TopBar/TopMargin/TopHBox/NavBtns/BtnProgress as Button).text = "Tiến độ"
	($Root/TopBar/TopMargin/TopHBox/NavBtns/BtnAccount  as Button).text = "Tài khoản"
	($Root/TopBar/TopMargin/TopHBox/StatsHBox/StreakPill/SPMargin/SPLabel as Label).text = "7 ngày"
	($Root/TopBar/TopMargin/TopHBox/StatsHBox/XPPill/XPMargin/XPLabel    as Label).text = "1.240 XP"

	($Root/Content/LeftPanel/LeftMargin/LeftVBox/GreetLabel as Label).text = "Xin chào,"
	($Root/Content/LeftPanel/LeftMargin/LeftVBox/NameLabel  as Label).text = "Linh"
	($Root/Content/LeftPanel/LeftMargin/LeftVBox/SectionTitle as Label).text = "BÀI HỌC HÔM NAY"

	var lc := $Root/Content/LeftPanel/LeftMargin/LeftVBox/LessonList
	(lc.get_node("LCard1/LC1M/LC1H/LC1Icon") as Label).text = "•"
	(lc.get_node("LCard1/LC1M/LC1H/LC1Info/LC1Name") as Label).text = "Bài 4 — Đang học"
	(lc.get_node("LCard1/LC1M/LC1H/LC1Info/LC1Sub")  as Label).text = "Nhấn dây · Rung âm"
	(lc.get_node("LCard2/LC2M/LC2H/LC2Icon") as Label).text = "•"
	(lc.get_node("LCard2/LC2M/LC2H/LC2Info/LC2Name") as Label).text = "Bài 5 — Tiếp theo"
	(lc.get_node("LCard2/LC2M/LC2H/LC2Info/LC2Sub")  as Label).text = "Lướt âm · Song thanh"

	var fc := $Root/Content/RightPanel/RightMargin/RightVBox/FeaturedCard
	(fc.get_node("FCMargin/FCRow/FCText/CourseTag")   as Label).text = "KHÓA HỌC CƠ BẢN · ĐÀN TRANH"
	(fc.get_node("FCMargin/FCRow/FCText/CourseTitle") as Label).text = "Bài 4: Kỹ thuật nhấn dây & rung âm"
	(fc.get_node("FCMargin/FCRow/FCText/CourseSub")   as Label).text = "Luyện nhấn dây để tạo rung âm rõ và ổn định"
	(fc.get_node("FCMargin/FCRow/FCText/ProgressRow/ProgPct") as Label).text = "60% hoàn thành"
	(fc.get_node("FCMargin/FCRow/FCText/BtnContinue") as Button).text = "Tiếp tục học"

	var br := $Root/Content/RightPanel/RightMargin/RightVBox/BottomRow
	(br.get_node("MiniCard1/MC1M/MC1V/MC1Icon") as Label).text = "B4"
	(br.get_node("MiniCard1/MC1M/MC1V/MC1Name") as Label).text = "Bài 4"
	(br.get_node("MiniCard1/MC1M/MC1V/MC1Sub")  as Label).text = "Nhấn dây"
	(br.get_node("MiniCard2/MC2M/MC2V/MC2Icon") as Label).text = "B5"
	(br.get_node("MiniCard2/MC2M/MC2V/MC2Name") as Label).text = "Bài 5"
	(br.get_node("MiniCard2/MC2M/MC2V/MC2Sub")  as Label).text = "Lướt âm"
	(br.get_node("MiniCard3/MC3M/MC3V/MC3Icon") as Label).text = "B6"
	(br.get_node("MiniCard3/MC3M/MC3V/MC3Name") as Label).text = "Bài 6"
	(br.get_node("MiniCard3/MC3M/MC3V/MC3Sub")  as Label).text = "Chưa mở"
	(br.get_node("StreakCard/SCM/SCV/SCIcon")  as Label).text = "7"
	(br.get_node("StreakCard/SCM/SCV/SCValue") as Label).text = "7 ngày"
	(br.get_node("StreakCard/SCM/SCV/SCSub")   as Label).text = "Liên tiếp"

func _build_theme() -> void:
	# ── Top Bar ──
	var top_s := _flat(Color(0.06, 0.03, 0.012, 0.98), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.22), 0)
	top_s.border_width_bottom = 3; top_s.border_width_top = 0; top_s.border_width_left = 0; top_s.border_width_right = 0
	($Root/TopBar as PanelContainer).add_theme_stylebox_override("panel", top_s)

	# Logo
	var logo := $Root/TopBar/TopMargin/TopHBox/Logo as Label
	logo.add_theme_color_override("font_color", C_GOLD)
	logo.add_theme_color_override("font_outline_color", Color(0.4,0.25,0.03,1))
	logo.add_theme_constant_override("outline_size", 6)

	# Nav buttons (top bar horizontal style)
	var active_nav := 0
	var nav_names := ["BtnHome", "BtnCourses", "BtnProgress", "BtnAccount"]
	for i in nav_names.size():
		var btn := $Root/TopBar/TopMargin/TopHBox/NavBtns.get_node(nav_names[i]) as Button
		var is_active := i == active_nav
		var bn := _flat(Color(0,0,0,0), Color(0,0,0,0), 8)
		if is_active:
			bn.border_width_bottom = 3; bn.border_width_top = 0; bn.border_width_left = 0; bn.border_width_right = 0
			bn.border_color = C_GOLD
		var bh := _flat(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.10), Color(0,0,0,0), 8)
		btn.add_theme_stylebox_override("normal",  bn)
		btn.add_theme_stylebox_override("hover",   bh)
		btn.add_theme_stylebox_override("pressed", _flat(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.18), Color(0,0,0,0), 8))
		btn.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
		btn.add_theme_color_override("font_color",         C_GOLD if is_active else C_CREAM_DIM)
		btn.add_theme_color_override("font_hover_color",   C_GOLD_LIGHT)
		btn.add_theme_color_override("font_pressed_color", C_GOLD)

	# Stat pills
	var streak_s := _flat(Color(0.4, 0.12, 0.02, 0.9), Color(0.9, 0.40, 0.08, 0.7), 30)
	streak_s.shadow_size = 6; streak_s.shadow_color = Color(0.9,0.4,0.08,0.25)
	($Root/TopBar/TopMargin/TopHBox/StatsHBox/StreakPill as PanelContainer).add_theme_stylebox_override("panel", streak_s)
	($Root/TopBar/TopMargin/TopHBox/StatsHBox/StreakPill/SPMargin/SPLabel as Label).add_theme_color_override("font_color", Color(1.0, 0.72, 0.25, 1.0))

	var xp_s := _flat(Color(0.22, 0.18, 0.02, 0.9), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.65), 30)
	xp_s.shadow_size = 6; xp_s.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25)
	($Root/TopBar/TopMargin/TopHBox/StatsHBox/XPPill as PanelContainer).add_theme_stylebox_override("panel", xp_s)
	($Root/TopBar/TopMargin/TopHBox/StatsHBox/XPPill/XPMargin/XPLabel as Label).add_theme_color_override("font_color", C_GOLD_LIGHT)

	# ── Left Panel ──
	var lp_s := _flat(Color(0.07, 0.038, 0.015, 0.97), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.20), 0)
	lp_s.border_width_right = 2; lp_s.border_width_left = 0; lp_s.border_width_top = 0; lp_s.border_width_bottom = 0
	($Root/Content/LeftPanel as PanelContainer).add_theme_stylebox_override("panel", lp_s)

	($Root/Content/LeftPanel/LeftMargin/LeftVBox/GreetLabel as Label).add_theme_color_override("font_color", C_CREAM_DIM)
	var name_lbl := $Root/Content/LeftPanel/LeftMargin/LeftVBox/NameLabel as Label
	name_lbl.add_theme_color_override("font_color", C_GOLD)
	name_lbl.add_theme_color_override("font_outline_color", Color(0.4,0.25,0.03,1))
	name_lbl.add_theme_constant_override("outline_size", 5)
	name_lbl.add_theme_color_override("font_shadow_color", Color(0,0,0,0.6))
	name_lbl.add_theme_constant_override("shadow_offset_y", 3)

	($Root/Content/LeftPanel/LeftMargin/LeftVBox/SectionTitle as Label).add_theme_color_override("font_color", Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.65))

	# Avatar circle
	var av_s := _flat(C_CARD_DARK, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.75), 60)
	av_s.border_width_left = 4; av_s.border_width_right = 4; av_s.border_width_top = 4; av_s.border_width_bottom = 4
	av_s.shadow_size = 10; av_s.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.3)
	($Root/Content/LeftPanel/LeftMargin/LeftVBox/AvatarCircle as PanelContainer).add_theme_stylebox_override("panel", av_s)

	# Lesson list cards
	var lc := $Root/Content/LeftPanel/LeftMargin/LeftVBox/LessonList
	# Active lesson (card 1) - gold highlight
	var lc1_s := _flat(Color(0.28, 0.18, 0.03, 0.95), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.75), 16)
	lc1_s.shadow_size = 8; lc1_s.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.22)
	(lc.get_node("LCard1") as PanelContainer).add_theme_stylebox_override("panel", lc1_s)
	(lc.get_node("LCard1/LC1M/LC1H/LC1Icon") as Label).add_theme_color_override("font_color", C_GOLD)
	(lc.get_node("LCard1/LC1M/LC1H/LC1Info/LC1Name") as Label).add_theme_color_override("font_color", C_CREAM)
	(lc.get_node("LCard1/LC1M/LC1H/LC1Info/LC1Sub")  as Label).add_theme_color_override("font_color", C_GOLD)
	# Next lesson (card 2) - dim
	var lc2_s := _flat(Color(0.10, 0.06, 0.025, 0.8), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25), 16)
	(lc.get_node("LCard2") as PanelContainer).add_theme_stylebox_override("panel", lc2_s)
	(lc.get_node("LCard2/LC2M/LC2H/LC2Icon") as Label).add_theme_color_override("font_color", C_CREAM_DIM)
	(lc.get_node("LCard2/LC2M/LC2H/LC2Info/LC2Name") as Label).add_theme_color_override("font_color", C_CREAM_DIM)
	(lc.get_node("LCard2/LC2M/LC2H/LC2Info/LC2Sub")  as Label).add_theme_color_override("font_color", Color(0.55,0.50,0.38,1))

	# ── Featured Card: đỏ sơn mài ──
	var fc_s := _flat(C_CARD_RED, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.65), 22)
	fc_s.shadow_size = 22; fc_s.shadow_color = Color(0,0,0,0.5)
	($Root/Content/RightPanel/RightMargin/RightVBox/FeaturedCard as PanelContainer).add_theme_stylebox_override("panel", fc_s)

	var fc := $Root/Content/RightPanel/RightMargin/RightVBox/FeaturedCard/FCMargin/FCRow/FCText
	(fc.get_node("CourseTag") as Label).add_theme_color_override("font_color",   Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.75))
	(fc.get_node("CourseTitle") as Label).add_theme_color_override("font_color", C_CREAM)
	(fc.get_node("CourseTitle") as Label).add_theme_color_override("font_shadow_color", Color(0,0,0,0.55))
	(fc.get_node("CourseTitle") as Label).add_theme_constant_override("shadow_offset_y", 3)
	(fc.get_node("CourseSub") as Label).add_theme_color_override("font_color",   Color(C_CREAM.r, C_CREAM.g, C_CREAM.b, 0.82))
	(fc.get_node("ProgressRow/ProgPct") as Label).add_theme_color_override("font_color", C_GOLD)

	# Progress bar
	var pb := fc.get_node("ProgressRow/ProgBar") as ProgressBar
	var pf := StyleBoxFlat.new(); pf.bg_color = C_GOLD
	pf.corner_radius_top_left = 7; pf.corner_radius_top_right = 7
	pf.corner_radius_bottom_left = 7; pf.corner_radius_bottom_right = 7
	pf.shadow_size = 5; pf.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.4)
	var pbg := StyleBoxFlat.new(); pbg.bg_color = Color(0,0,0,0.35)
	pbg.corner_radius_top_left = 7; pbg.corner_radius_top_right = 7
	pbg.corner_radius_bottom_left = 7; pbg.corner_radius_bottom_right = 7
	pb.add_theme_stylebox_override("fill", pf)
	pb.add_theme_stylebox_override("background", pbg)

	# Continue button - gold CTA
	var btn_c := fc.get_node("BtnContinue") as Button
	var bn := _flat(C_GOLD, Color(1,1,1,0.20), 20)
	bn.shadow_size = 14; bn.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.40)
	var bh := _flat(C_GOLD_LIGHT, Color(1,1,1,0.35), 20)
	bh.shadow_size = 20; bh.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.50)
	btn_c.add_theme_stylebox_override("normal",  bn)
	btn_c.add_theme_stylebox_override("hover",   bh)
	btn_c.add_theme_stylebox_override("pressed", _flat(Color(0.72,0.52,0.10,1), Color(0,0,0,0), 20))
	btn_c.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	btn_c.add_theme_color_override("font_color",         Color(0.09,0.04,0.01,1))
	btn_c.add_theme_color_override("font_hover_color",   Color(0.06,0.03,0.01,1))
	btn_c.add_theme_color_override("font_pressed_color", Color(0.06,0.03,0.01,1))
	btn_c.add_theme_font_size_override("font_size", 28)

	# ── Bottom mini cards ──
	var br := $Root/Content/RightPanel/RightMargin/RightVBox/BottomRow
	var mini_data := [
		["MiniCard1", C_CARD_RED,  Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.75), C_GOLD_LIGHT],
		["MiniCard2", C_CARD_JADE, Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.75),           Color(0.5,0.95,0.72,1)],
		["MiniCard3", Color(0.10,0.08,0.05,0.75), Color(0.35,0.30,0.20,0.40),            C_CREAM_DIM],
		["StreakCard", Color(0.38,0.10,0.03,0.92), Color(0.90,0.40,0.08,0.70),            Color(1.0,0.70,0.22,1)],
	]
	for md in mini_data:
		var card := br.get_node(md[0] as String) as PanelContainer
		var cs := _flat(md[1] as Color, md[2] as Color, 18)
		cs.shadow_size = 8; cs.shadow_color = Color(0,0,0,0.35)
		card.add_theme_stylebox_override("panel", cs)
		# Color the icon
		var vbox : VBoxContainer
		if md[0] as String == "StreakCard": vbox = card.get_node("SCM/SCV") as VBoxContainer
		else: vbox = card.get_node(str(md[0] as String).replace("MiniCard","MC") + "M/MC" + str(md[0] as String).replace("MiniCard","") + "V") as VBoxContainer
		if vbox:
			for lbl in vbox.get_children():
				if lbl is Label: (lbl as Label).add_theme_color_override("font_color", md[3] as Color)

func _start_float() -> void:
	var char_img := $Root/Content/RightPanel/RightMargin/RightVBox/FeaturedCard/FCMargin/FCRow/FCChar as TextureRect
	if not char_img: return
	_float_tween = create_tween().set_loops()
	_float_tween.tween_property(char_img, "position:y", -16.0, 2.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_float_tween.tween_property(char_img, "position:y", 0.0,   2.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _connect_buttons() -> void:
	var btn_courses  := $Root/TopBar/TopMargin/TopHBox/NavBtns/BtnCourses  as Button
	var btn_progress := $Root/TopBar/TopMargin/TopHBox/NavBtns/BtnProgress as Button
	var btn_account  := $Root/TopBar/TopMargin/TopHBox/NavBtns/BtnAccount  as Button
	var btn_home     := $Root/TopBar/TopMargin/TopHBox/NavBtns/BtnHome     as Button
	var btn_continue := $Root/Content/RightPanel/RightMargin/RightVBox/FeaturedCard/FCMargin/FCRow/FCText/BtnContinue as Button

	btn_courses.pressed.connect(_go_instruments)
	btn_progress.pressed.connect(_go_progress)
	btn_account.pressed.connect(_go_account)
	btn_home.pressed.connect(func() -> void: pass)
	btn_continue.pressed.connect(_go_practice)

	_make_button_bouncy(btn_courses)
	_make_button_bouncy(btn_progress)
	_make_button_bouncy(btn_account)
	_make_button_bouncy(btn_home)
	_make_button_bouncy(btn_continue)
	
	# Also make LeftPanel's AvatarCircle clickable to open the Account page!
	var av_panel := $Root/Content/LeftPanel/LeftMargin/LeftVBox/AvatarCircle as PanelContainer
	av_panel.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed: _go_account()
	)

	# Lesson list cards clickable
	var lc := $Root/Content/LeftPanel/LeftMargin/LeftVBox/LessonList
	(lc.get_node("LCard1") as PanelContainer).gui_input.connect(func(e: InputEvent)->void:
		if e is InputEventMouseButton and e.pressed: _go_practice())
	(lc.get_node("LCard2") as PanelContainer).gui_input.connect(func(e: InputEvent)->void:
		if e is InputEventMouseButton and e.pressed: _go_practice())

	# Mini cards
	var br := $Root/Content/RightPanel/RightMargin/RightVBox/BottomRow
	for n in ["MiniCard1", "MiniCard2"]:
		var c := br.get_node(n) as PanelContainer
		c.gui_input.connect(func(e: InputEvent)->void:
			if e is InputEventMouseButton and e.pressed: _go_practice())

func _go_practice()    -> void: _fade_to("res://scenes/PracticeRoom.tscn")
func _go_instruments() -> void: _fade_to("res://scenes/InstrumentSelect.tscn")
func _go_progress()    -> void: _fade_to("res://scenes/ProgressScreen.tscn")
func _go_account()     -> void: _fade_to("res://scenes/AccountScreen.tscn")

func _fade_to(path: String) -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.25)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file(path))

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
