extends Control
class_name InstrumentSelect

static var selected_instrument := "dan_tranh"

# ── Paths ─────────────────────────────────────────────────────────────────────
const _CARDS_ROOT := "Root/ScrollArea/CardsArea/CardsVBox/"
const _DT := _CARDS_ROOT + "CardDanTranh/DTRoot/"
const _ST := _CARDS_ROOT + "CardSaoTruc/STRoot/"
const _DB := _CARDS_ROOT + "CardDanBau/DBRoot/"

const IMG_DAN_TRANH := "res://assets/textures/dan_tranh.jpg"
const IMG_SAO_TRUC  := "res://assets/textures/sao_truc.jpg"
const IMG_DAN_BAU   := "res://assets/textures/dan_bau.jpg"

# Instrument-specific accent colours
const C_JADE    := Color(0.22, 0.86, 0.55, 1.0)
const C_JADE_LT := Color(0.42, 0.95, 0.70, 1.0)

func _ready() -> void:
	_build_theme()
	_setup_images()
	_animate_in()

	var back := $Root/TopBar/TopM/TopH/BackBtn as Button
	back.pressed.connect(_go_back)
	DS.make_bouncy(back)

	var dt_btn := get_node(_DT + "DTContent/DTCVBox/DTBtn") as Button
	dt_btn.pressed.connect(_go_practice_tranh)
	DS.make_bouncy(dt_btn)

	var st_btn := get_node(_ST + "STContent/STCVBox/STBtn") as Button
	st_btn.pressed.connect(_go_practice_sao)
	DS.make_bouncy(st_btn)

# ── Image / Illustration setup ────────────────────────────────────────────────

func _setup_images() -> void:
	var cards := [
		{
			"img":   get_node(_DT + "DTImageArea/DTImage"),
			"area":  get_node(_DT + "DTImageArea"),
			"cvbox": get_node(_DT + "DTContent/DTCVBox"),
			"path":  IMG_DAN_TRANH,
			"bg":    Color(0.10, 0.03, 0.06, 1.0),
			"accent": DS.C_GOLD,
			"kind":  "dan_tranh",
			"tag":   "Nhạc cụ dây",
		},
		{
			"img":   get_node(_ST + "STImageArea/STImage"),
			"area":  get_node(_ST + "STImageArea"),
			"cvbox": get_node(_ST + "STContent/STCVBox"),
			"path":  IMG_SAO_TRUC,
			"bg":    Color(0.03, 0.09, 0.05, 1.0),
			"accent": C_JADE,
			"kind":  "sao_truc",
			"tag":   "Nhạc cụ hơi",
		},
		{
			"img":   get_node(_DB + "DBImageArea/DBImage"),
			"area":  get_node(_DB + "DBImageArea"),
			"cvbox": get_node(_DB + "DBContent/DBCVBox"),
			"path":  IMG_DAN_BAU,
			"bg":    Color(0.06, 0.04, 0.12, 1.0),
			"accent": Color(0.55, 0.45, 0.80, 1.0),
			"kind":  "dan_bau",
			"tag":   "Nhạc cụ dây",
		},
	]
	for d in cards:
		_setup_card_image(d["img"], d["area"], d["cvbox"],
			d["path"], d["bg"], d["accent"], d["kind"], d["tag"])

func _setup_card_image(img: TextureRect, area: Control, cvbox: VBoxContainer,
		path: String, bg: Color, accent: Color, kind: String, tag: String) -> void:
	if FileAccess.file_exists(path + ".import"):
		img.texture = load(path)
	else:
		var bg_rect := ColorRect.new()
		bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg_rect.color = bg
		bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		area.add_child(bg_rect)
		area.move_child(bg_rect, 0)

		var illus := Control.new()
		illus.set_anchors_preset(Control.PRESET_FULL_RECT)
		illus.mouse_filter = Control.MOUSE_FILTER_IGNORE
		match kind:
			"dan_tranh": illus.draw.connect(func() -> void: _draw_dan_tranh(illus, accent))
			"sao_truc":  illus.draw.connect(func() -> void: _draw_sao_truc(illus, accent))
			_:           illus.draw.connect(func() -> void: _draw_dan_bau(illus, accent))
		area.add_child(illus)

	# Gradient fade at bottom edge (blends into card bg)
	var fade := Control.new()
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fade_col := bg
	fade.draw.connect(func() -> void:
		var sz := fade.size
		var start_y := sz.y * 0.50
		var steps := 10
		for i in range(steps):
			var t  := float(i) / float(steps - 1)
			var y0 := start_y + t * (sz.y - start_y)
			var y1 := start_y + (t + 1.0 / steps) * (sz.y - start_y)
			fade.draw_rect(Rect2(0, y0, sz.x, max(1, y1 - y0)),
				Color(fade_col.r, fade_col.g, fade_col.b, t * t * 0.85))
	)
	area.add_child(fade)

	# Accent stripe at bottom of illustration
	var stripe := ColorRect.new()
	stripe.anchor_top = 1.0; stripe.anchor_bottom = 1.0
	stripe.anchor_left = 0.0; stripe.anchor_right  = 1.0
	stripe.offset_top = -3.0; stripe.offset_bottom = 0.0
	stripe.color = Color(accent.r, accent.g, accent.b, 0.90)
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.add_child(stripe)

	# Category badge bottom-left
	var badge := Label.new()
	badge.text = tag
	badge.anchor_left   = 0.0; badge.anchor_right  = 0.0
	badge.anchor_top    = 1.0; badge.anchor_bottom = 1.0
	badge.grow_horizontal = Control.GROW_DIRECTION_END
	badge.grow_vertical   = Control.GROW_DIRECTION_BEGIN
	badge.offset_left   = 10.0; badge.offset_top    = -30.0
	badge.offset_right  = 130.0; badge.offset_bottom = -8.0
	badge.add_theme_font_size_override("font_size", 10)
	badge.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 0.85))
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.add_child(badge)

# ── Illustrations ─────────────────────────────────────────────────────────────
# (All use c.size for auto-scaling — work at any size including 130×160)

func _draw_dan_tranh(c: Control, ac: Color) -> void:
	var w := c.size.x; var h := c.size.y
	var cx := w * 0.50; var cy := h * 0.50

	for i in range(4):
		c.draw_circle(Vector2(cx, cy), h * (0.50 - i * 0.07), Color(ac.r, ac.g, ac.b, 0.018))

	var bw2 := w * 0.38; var bh2 := h * 0.28; var taper := w * 0.06
	var body := PackedVector2Array([
		Vector2(cx - bw2,         cy + bh2),
		Vector2(cx + bw2,         cy + bh2),
		Vector2(cx + bw2 - taper, cy - bh2),
		Vector2(cx - bw2 + taper, cy - bh2),
	])
	c.draw_colored_polygon(body, Color(0.28, 0.11, 0.03, 0.95))
	var hi := PackedVector2Array([
		Vector2(cx - bw2,         cy + bh2),
		Vector2(cx,               cy + bh2),
		Vector2(cx - taper * 0.5, cy - bh2),
		Vector2(cx - bw2 + taper, cy - bh2),
	])
	c.draw_colored_polygon(hi, Color(1.0, 0.55, 0.20, 0.10))

	for i in range(8):
		var t := float(i) / 7.0
		var gy := (cy - bh2 + 5) + t * (bh2 * 2 - 10)
		var lx := cx - bw2 + taper * (1.0 - t) + 5
		var rx := cx + bw2 - taper * (1.0 - t) - 5
		c.draw_line(Vector2(lx, gy), Vector2(rx, gy), Color(0.55, 0.28, 0.10, 0.15), 1.0)

	for i in range(4):
		c.draw_line(body[i], body[(i+1)%4], Color(0.75, 0.45, 0.15, 0.85), 2.0)

	var n := 16
	var sy0 := cy - bh2 + 3.0; var sy1 := cy + bh2 - 3.0
	var sw0 := (bw2 - taper) * 2.0 - 8.0
	var sw1 := bw2 * 2.0 - 8.0
	for i in range(n):
		var t := float(i) / float(n - 1)
		var xt := cx - sw0/2 + t * sw0
		var xb := cx - sw1/2 + t * sw1
		var mb : float = 1.0 - absf(t - 0.5) * 0.6
		c.draw_line(Vector2(xt, sy0), Vector2(xb, sy1),
			Color(ac.r, ac.g * mb, ac.b * 0.2, 0.18), 3.5)
		c.draw_line(Vector2(xt, sy0), Vector2(xb, sy1),
			Color(ac.r, ac.g * mb * 1.1, ac.b * 0.3, 0.80), 1.2)

	for i in range(n):
		var t := float(i) / float(n - 1)
		var xt := cx - sw0/2 + t * sw0
		var xb := cx - sw1/2 + t * sw1
		var bx := lerpf(xt, xb, 0.40)
		var by := lerpf(sy0, sy1, 0.40)
		c.draw_circle(Vector2(bx, by), 3.0, Color(0.92, 0.76, 0.30, 0.95))

func _draw_sao_truc(c: Control, ac: Color) -> void:
	var w := c.size.x; var h := c.size.y
	var p0  := Vector2(w * 0.12, h * 0.28)
	var p1  := Vector2(w * 0.90, h * 0.72)
	var dir  := (p1 - p0).normalized()
	var perp := Vector2(-dir.y, dir.x)
	var hw   := 14.0

	for i in range(3):
		var mid := p0.lerp(p1, 0.5)
		c.draw_circle(mid, h * (0.38 - i * 0.06), Color(ac.r, ac.g, ac.b, 0.018))

	var corners := PackedVector2Array([
		p0 + perp * hw, p1 + perp * hw,
		p1 - perp * hw, p0 - perp * hw,
	])
	c.draw_colored_polygon(corners, Color(0.08, 0.24, 0.08, 0.92))

	var hi_w := hw * 0.35
	var hi_corners := PackedVector2Array([
		p0 - perp * hw,              p1 - perp * hw,
		p1 - perp * (hw - hi_w * 2), p0 - perp * (hw - hi_w * 2),
	])
	c.draw_colored_polygon(hi_corners, Color(0.35, 0.68, 0.25, 0.22))

	for i in range(1, 7):
		var t := float(i) / 7.0
		var mid := p0.lerp(p1, t)
		c.draw_line(mid + perp * (hw + 2), mid - perp * (hw + 2),
			Color(0.04, 0.10, 0.04, 0.85), 3.0)
		c.draw_line(mid + perp * hw * 0.6, mid - perp * hw * 0.6,
			Color(0.40, 0.72, 0.30, 0.30), 1.2)

	for i in range(4):
		c.draw_line(corners[i], corners[(i+1)%4], Color(ac.r, ac.g, ac.b, 0.55), 1.5)

	var blow := p0.lerp(p1, 0.12)
	c.draw_circle(blow, 7.0, Color(0.02, 0.06, 0.02, 0.95))
	c.draw_arc(blow, 7.0, 0, TAU, 18, Color(ac.r, ac.g, ac.b, 0.65), 2.0)

	for i in range(6):
		var t  := 0.28 + float(i) * 0.105
		var hc := p0.lerp(p1, t)
		c.draw_circle(hc, 6.0, Color(0.01, 0.04, 0.01, 0.95))
		c.draw_arc(hc, 6.0, 0, TAU, 16, Color(ac.r, ac.g, ac.b, 0.70), 1.6)

func _draw_dan_bau(c: Control, ac: Color) -> void:
	var w := c.size.x; var h := c.size.y
	var cx := w * 0.50; var cy := h * 0.52

	c.draw_circle(Vector2(cx, cy), h * 0.36, Color(ac.r, ac.g, ac.b, 0.025))

	var bw := w * 0.62; var bh := h * 0.22
	var box_pts := PackedVector2Array([
		Vector2(cx - bw/2, cy + bh/2), Vector2(cx + bw/2, cy + bh/2),
		Vector2(cx + bw/2, cy - bh/2), Vector2(cx - bw/2, cy - bh/2),
	])
	c.draw_colored_polygon(box_pts, Color(0.20, 0.14, 0.08, 0.35))
	for i in range(4):
		c.draw_line(box_pts[i], box_pts[(i+1)%4], Color(ac.r, ac.g, ac.b, 0.22), 1.5)

	c.draw_circle(Vector2(cx, cy), 10.0, Color(0.04, 0.03, 0.08, 0.60))
	c.draw_arc(Vector2(cx, cy), 10.0, 0, TAU, 22, Color(ac.r, ac.g, ac.b, 0.22), 1.2)

	var neck_x := cx - bw * 0.38
	c.draw_line(Vector2(neck_x, cy - bh/2), Vector2(neck_x, cy - h*0.30),
		Color(ac.r, ac.g, ac.b, 0.22), 6.0)
	c.draw_circle(Vector2(neck_x, cy - h*0.31), 5.0, Color(ac.r, ac.g, ac.b, 0.22))

	var str_y := cy - bh * 0.10
	c.draw_line(Vector2(cx - bw/2 - 15, str_y), Vector2(cx + bw/2 + 15, str_y),
		Color(ac.r, ac.g, ac.b, 0.28), 1.5)

	# Ghost "Sắp ra mắt" text — only add child once
	if c.get_child_count() == 0:
		var lbl := Label.new()
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl.text = "Sắp\nra mắt"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 22)
		lbl.add_theme_color_override("font_color", Color(ac.r, ac.g, ac.b, 0.18))
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(lbl)

# ── Card theming ───────────────────────────────────────────────────────────────

func _build_theme() -> void:
	# TopBar
	var top_s := DS.flat(Color(0.04, 0.024, 0.11, 0.98), Color(1, 1, 1, 0.08), 0, 0)
	top_s.border_width_bottom = 1
	($Root/TopBar as PanelContainer).add_theme_stylebox_override("panel", top_s)

	($Root/TopBar/TopM/TopH/PageTitle as Label).add_theme_color_override("font_color", DS.C_CREAM)

	($Root/SubBox/SubTitle as Label).add_theme_color_override("font_color", DS.C_CREAM_DIM)

	var back := $Root/TopBar/TopM/TopH/BackBtn as Button
	DS.apply_ghost(back, 15)

	_style_card(
		get_node(_CARDS_ROOT + "CardDanTranh"),
		get_node(_DT + "DTContent/DTCVBox"),
		Color(0.11, 0.03, 0.06, 0.98), Color(DS.C_GOLD.r, DS.C_GOLD.g, DS.C_GOLD.b, 0.50),
		DS.C_GOLD, Color(0.68, 0.10, 0.07, 1.0), "DTBar", "DTBtn", "DTPct")

	_style_card(
		get_node(_CARDS_ROOT + "CardSaoTruc"),
		get_node(_ST + "STContent/STCVBox"),
		Color(0.03, 0.10, 0.06, 0.98), Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.50),
		C_JADE, Color(0.07, 0.48, 0.30, 1.0), "STBar", "STBtn", "STPct")

	_style_card_locked(
		get_node(_CARDS_ROOT + "CardDanBau"),
		get_node(_DB + "DBContent/DBCVBox"))

func _style_card(card: PanelContainer, cvbox: VBoxContainer,
		bg: Color, border: Color, accent: Color, btn_col: Color,
		bar_name: String, btn_name: String, pct_name: String) -> void:
	var cs := DS.flat(bg, border, DS.R_LG)
	cs.shadow_size = 32; cs.shadow_color = Color(0, 0, 0, 0.55)
	cs.border_width_left = 3; cs.border_width_top    = 3
	cs.border_width_right = 1; cs.border_width_bottom = 1
	card.add_theme_stylebox_override("panel", cs)

	(cvbox.get_child(0) as Label).add_theme_color_override("font_color", DS.C_CREAM)
	(cvbox.get_child(1) as Label).add_theme_color_override("font_color", DS.C_CREAM_DIM)
	(cvbox.get_node(pct_name) as Label).add_theme_color_override("font_color",
		Color(accent.r, accent.g, accent.b, 0.70))

	var pb  := cvbox.get_node(bar_name) as ProgressBar
	var pf  := StyleBoxFlat.new()
	pf.bg_color = accent
	pf.corner_radius_top_left = 3; pf.corner_radius_top_right    = 3
	pf.corner_radius_bottom_left = 3; pf.corner_radius_bottom_right = 3
	pf.shadow_size = 6; pf.shadow_color = Color(accent.r, accent.g, accent.b, 0.50)
	var pbg := StyleBoxFlat.new()
	pbg.bg_color = Color(1, 1, 1, 0.07)
	pbg.corner_radius_top_left = 3; pbg.corner_radius_top_right    = 3
	pbg.corner_radius_bottom_left = 3; pbg.corner_radius_bottom_right = 3
	pb.add_theme_stylebox_override("fill",       pf)
	pb.add_theme_stylebox_override("background", pbg)

	var btn := cvbox.get_node(btn_name) as Button
	var bn  := DS.flat(btn_col, Color(1, 1, 1, 0.15), DS.R_MD, 1)
	bn.shadow_size = 14; bn.shadow_color = Color(btn_col.r, btn_col.g, btn_col.b, 0.45)
	var bh  := DS.flat(btn_col.lightened(0.22), Color(1, 1, 1, 0.28), DS.R_MD, 1)
	bh.shadow_size = 22; bh.shadow_color = Color(btn_col.r, btn_col.g, btn_col.b, 0.60)
	btn.add_theme_stylebox_override("normal",  bn)
	btn.add_theme_stylebox_override("hover",   bh)
	btn.add_theme_stylebox_override("pressed", DS.flat(btn_col.darkened(0.15), Color.TRANSPARENT, DS.R_MD, 0))
	btn.add_theme_stylebox_override("focus",   DS.no_style())
	btn.add_theme_color_override("font_color",         DS.C_CREAM)
	btn.add_theme_color_override("font_hover_color",   DS.C_CREAM)
	btn.add_theme_color_override("font_pressed_color", DS.C_CREAM)

func _style_card_locked(card: PanelContainer, cvbox: VBoxContainer) -> void:
	var cs := DS.flat(Color(0.07, 0.05, 0.13, 0.88), Color(1, 1, 1, 0.08), DS.R_LG)
	cs.shadow_size = 10; cs.shadow_color = Color(0, 0, 0, 0.28)
	card.add_theme_stylebox_override("panel", cs)
	card.modulate.a = 0.52

	for child in cvbox.get_children():
		if child is Label:
			(child as Label).add_theme_color_override("font_color", DS.C_CREAM_DIM)

	var btn := cvbox.get_node("DBBtn") as Button
	btn.add_theme_stylebox_override("normal",   DS.flat(Color(1,1,1,0.05), Color(1,1,1,0.08), DS.R_MD))
	btn.add_theme_stylebox_override("disabled", DS.flat(Color(1,1,1,0.03), Color(1,1,1,0.05), DS.R_MD))
	btn.add_theme_color_override("font_color",          Color(1,1,1,0.26))
	btn.add_theme_color_override("font_disabled_color", Color(1,1,1,0.20))

# ── Entrance animation ─────────────────────────────────────────────────────────

func _animate_in() -> void:
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.32)

	var vbox := get_node(_CARDS_ROOT.trim_suffix("/")) as VBoxContainer
	if vbox == null:
		return
	var delay := 0.10
	for card in vbox.get_children():
		var c := card as Control
		var target_a := c.modulate.a  # giữ nguyên alpha locked (0.52) hoặc bình thường (1.0)
		c.modulate.a = 0.0
		create_tween().tween_property(c, "modulate:a", target_a, 0.44).set_delay(delay)
		delay += 0.12

# ── Navigation ─────────────────────────────────────────────────────────────────

func _go_practice_tranh() -> void:
	selected_instrument = "dan_tranh"
	SecureDataManager.data["selected_instrument"] = "dan_tranh"
	SecureDataManager.save_data()
	DS.fade_to(self, "res://scenes/MainMenu.tscn")

func _go_practice_sao() -> void:
	selected_instrument = "sao_truc"
	SecureDataManager.data["selected_instrument"] = "sao_truc"
	SecureDataManager.save_data()
	DS.fade_to(self, "res://scenes/MainMenu.tscn")

func _go_back() -> void:
	DS.fade_to(self, "res://scenes/LoginScreen.tscn")
