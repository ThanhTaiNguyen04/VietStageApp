extends Control
class_name InstrumentSelect

static var selected_instrument := "dan_tranh"

const C_GOLD       := Color(0.95, 0.72, 0.18, 1.0)
const C_GOLD_LIGHT := Color(1.00, 0.87, 0.45, 1.0)
const C_JADE       := Color(0.18, 0.62, 0.42, 1.0)
const C_RED_SON    := Color(0.72, 0.12, 0.08, 1.0)
const C_CREAM      := Color(1.00, 0.97, 0.88, 1.0)
const C_CREAM_DIM  := Color(0.80, 0.76, 0.66, 1.0)

func _ready() -> void:
	_build_theme()
	_set_labels()
	_animate_in()
	var back_btn := $Root/TopBar/TopM/TopH/BackBtn as Button
	back_btn.pressed.connect(_go_back)
	_make_button_bouncy(back_btn)

	var dt_btn := $Root/CardsArea/CardsHBox/CardDanTranh/DTMargin/DTVBox/DTBtn as Button
	dt_btn.pressed.connect(_go_practice_tranh)
	_make_button_bouncy(dt_btn)

	var st_btn := $Root/CardsArea/CardsHBox/CardSaoTruc/STMargin/STVBox/STBtn as Button
	st_btn.pressed.connect(_go_practice_sao)
	_make_button_bouncy(st_btn)

func _set_labels() -> void:
	($Root/TopBar/TopM/TopH/BackBtn    as Button).text = "Quay lại"
	($Root/TopBar/TopM/TopH/PageTitle  as Label ).text = "Chọn nhạc cụ"

	var dt := "Root/CardsArea/CardsHBox/CardDanTranh/DTMargin/DTVBox/"
	(get_node(dt + "DTIcon") as Label).text = "DT"
	(get_node(dt + "DTName") as Label).text = "Đàn Tranh"
	(get_node(dt + "DTDesc") as Label).text = "16 dây  ·  72 bài học  ·  3 cấp độ"
	(get_node(dt + "DTPct")  as Label).text = "60% hoàn thành"
	(get_node(dt + "DTBtn")  as Button).text = "Học ngay"

	var st := "Root/CardsArea/CardsHBox/CardSaoTruc/STMargin/STVBox/"
	(get_node(st + "STIcon") as Label).text = "ST"
	(get_node(st + "STName") as Label).text = "Sáo Trúc"
	(get_node(st + "STDesc") as Label).text = "Sáo tre  ·  58 bài học  ·  2 cấp độ"
	(get_node(st + "STPct")  as Label).text = "Chưa bắt đầu"
	(get_node(st + "STBtn")  as Button).text = "Bắt đầu"

	var db := "Root/CardsArea/CardsHBox/CardDanBau/DBMargin/DBVBox/"
	(get_node(db + "DBIcon")   as Label).text = "DB"
	(get_node(db + "DBName")   as Label).text = "Đàn Bầu"
	(get_node(db + "DBDesc")   as Label).text = "Độc huyền cầm  ·  45 bài học"
	(get_node(db + "DBLocked") as Label).text = "Khoá"
	(get_node(db + "DBSub")    as Label).text = "Sắp ra mắt"
	(get_node(db + "DBBtn")    as Button).text = "Sắp Ra Mắt"

func _build_theme() -> void:
	# Top bar
	var top_s := _flat(Color(0.06, 0.03, 0.012, 0.98), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.22), 0)
	top_s.border_width_bottom = 3; top_s.border_width_top = 0; top_s.border_width_left = 0; top_s.border_width_right = 0
	($Root/TopBar as PanelContainer).add_theme_stylebox_override("panel", top_s)
	($Root/TopBar/TopM/TopH/PageTitle as Label).add_theme_color_override("font_color", C_GOLD)

	var back := $Root/TopBar/TopM/TopH/BackBtn as Button
	back.add_theme_color_override("font_color",         C_GOLD)
	back.add_theme_color_override("font_hover_color",   C_GOLD_LIGHT)
	back.add_theme_stylebox_override("normal",  _flat(Color(0,0,0,0), Color(0,0,0,0), 8))
	back.add_theme_stylebox_override("hover",   _flat(Color(C_GOLD.r,C_GOLD.g,C_GOLD.b,0.12), Color(0,0,0,0), 8))
	back.add_theme_stylebox_override("pressed", _flat(Color(C_GOLD.r,C_GOLD.g,C_GOLD.b,0.20), Color(0,0,0,0), 8))
	back.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0), 0))

	# Cards
	_style_card("CardDanTranh", "DTMargin/DTVBox",
		Color(0.40, 0.10, 0.04, 0.95), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.70),
		Color(0.72, 0.12, 0.08, 1.0),  Color(1.0, 0.78, 0.35, 1.0),
		C_GOLD, "DTBar", "DTBtn")

	_style_card("CardSaoTruc", "STMargin/STVBox",
		Color(0.04, 0.20, 0.12, 0.95), Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.70),
		Color(0.08, 0.48, 0.30, 1.0),  Color(0.50, 0.95, 0.72, 1.0),
		Color(0.38, 0.90, 0.62, 1.0),  "STBar", "STBtn")

	_style_card_locked("CardDanBau", "DBMargin/DBVBox")

func _style_card(card_name: String, vbox_path: String, bg: Color, border: Color,
		btn_col: Color, icon_col: Color, accent: Color, bar_name: String, btn_name: String) -> void:
	var card := $Root/CardsArea/CardsHBox.get_node(card_name) as PanelContainer
	var cs := _flat(bg, border, 24)
	cs.shadow_size = 18; cs.shadow_color = Color(0,0,0,0.42)
	card.add_theme_stylebox_override("panel", cs)

	var prefix := "Root/CardsArea/CardsHBox/" + card_name + "/" + vbox_path + "/"
	# Icon
	var icon_node := get_node(prefix.left(-1)) as VBoxContainer
	if icon_node:
		for child in icon_node.get_children():
			if child is Label: (child as Label).add_theme_color_override("font_color", C_CREAM)

	# Use a simpler approach — style children directly
	var vb := card.get_node(vbox_path) as VBoxContainer
	for child in vb.get_children():
		if child is Label: (child as Label).add_theme_color_override("font_color", C_CREAM)
	# Icon override
	(vb.get_child(0) as Label).add_theme_color_override("font_color", icon_col)
	# Name bold
	var name_lbl := vb.get_child(1) as Label
	name_lbl.add_theme_color_override("font_color", C_CREAM)
	name_lbl.add_theme_color_override("font_shadow_color", Color(0,0,0,0.5))
	name_lbl.add_theme_constant_override("shadow_offset_y", 2)

	# Progress bar
	var pb := vb.get_node(bar_name) as ProgressBar
	var pf := StyleBoxFlat.new(); pf.bg_color = accent
	pf.corner_radius_top_left = 7; pf.corner_radius_top_right = 7
	pf.corner_radius_bottom_left = 7; pf.corner_radius_bottom_right = 7
	pf.shadow_size = 5; pf.shadow_color = Color(accent.r, accent.g, accent.b, 0.38)
	var pbg := StyleBoxFlat.new(); pbg.bg_color = Color(0,0,0,0.35)
	pbg.corner_radius_top_left = 7; pbg.corner_radius_top_right = 7
	pbg.corner_radius_bottom_left = 7; pbg.corner_radius_bottom_right = 7
	pb.add_theme_stylebox_override("fill", pf)
	pb.add_theme_stylebox_override("background", pbg)

	# Button
	var btn := vb.get_node(btn_name) as Button
	var bn := _flat(btn_col, Color(1,1,1,0.20), 18)
	bn.shadow_size = 10; bn.shadow_color = Color(btn_col.r, btn_col.g, btn_col.b, 0.35)
	var bh := _flat(btn_col.lightened(0.18), Color(1,1,1,0.30), 18)
	bh.shadow_size = 16; bh.shadow_color = Color(btn_col.r, btn_col.g, btn_col.b, 0.45)
	btn.add_theme_stylebox_override("normal",  bn)
	btn.add_theme_stylebox_override("hover",   bh)
	btn.add_theme_stylebox_override("pressed", _flat(btn_col.darkened(0.15), Color(0,0,0,0.1), 18))
	btn.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	btn.add_theme_color_override("font_color", Color(1,1,1,1))

func _style_card_locked(card_name: String, vbox_path: String) -> void:
	var card := $Root/CardsArea/CardsHBox.get_node(card_name) as PanelContainer
	var cs := _flat(Color(0.10,0.07,0.04,0.75), Color(0.35,0.30,0.20,0.35), 24)
	cs.shadow_size = 8; cs.shadow_color = Color(0,0,0,0.28)
	card.add_theme_stylebox_override("panel", cs)

	var vb := card.get_node(vbox_path) as VBoxContainer
	for child in vb.get_children():
		if child is Label: (child as Label).add_theme_color_override("font_color", C_CREAM_DIM)
	(vb.get_child(0) as Label).modulate.a = 0.5  # dim icon

	var btn := vb.get_node("DBBtn") as Button
	btn.add_theme_stylebox_override("normal",   _flat(Color(0.12,0.09,0.05,0.5), Color(0.3,0.26,0.18,0.3), 18))
	btn.add_theme_stylebox_override("disabled", _flat(Color(0.10,0.07,0.04,0.4), Color(0.25,0.20,0.14,0.2), 18))
	btn.add_theme_color_override("font_color", Color(0.40,0.36,0.28,0.7))

func _animate_in() -> void:
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.35)
	var hbox := $Root/CardsArea/CardsHBox as HBoxContainer
	var delay := 0.12
	for card in hbox.get_children():
		var c := card as Control
		c.modulate.a = 0.0
		c.position.y += 36.0
		var t := create_tween().set_parallel(true)
		t.tween_property(c, "modulate:a", 1.0, 0.42).set_delay(delay)
		t.tween_property(c, "position:y", 0.0, 0.48).set_delay(delay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		delay += 0.12

func _go_practice_tranh() -> void:
	selected_instrument = "dan_tranh"
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.22)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/CourseMap.tscn"))

func _go_practice_sao() -> void:
	selected_instrument = "sao_truc"
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.22)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/CourseMap.tscn"))

func _go_back() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.22)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))

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
