extends Control
class_name InstrumentSelect

static var selected_instrument := "dan_tranh"

const C_GOLD      := Color(0.95, 0.72, 0.18, 1.0)
const C_GOLD_LT   := Color(1.00, 0.87, 0.45, 1.0)
const C_JADE      := Color(0.22, 0.86, 0.55, 1.0)
const C_JADE_LT   := Color(0.42, 0.95, 0.70, 1.0)
const C_WHITE     := Color(1.00, 1.00, 1.00, 1.0)
const C_WHITE_DIM := Color(1.00, 1.00, 1.00, 0.50)
const C_DIM       := Color(1.00, 1.00, 1.00, 0.24)

const IMG_DAN_TRANH := "res://assets/textures/dan_tranh.jpg"
const IMG_SAO_TRUC  := "res://assets/textures/sao_truc.jpg"
const IMG_DAN_BAU   := "res://assets/textures/dan_bau.jpg"

func _ready() -> void:
	_build_theme()
	_setup_images()
	_animate_in()

	($Root/TopBar/TopM/TopH/BackBtn as Button).pressed.connect(_go_back)
	_make_bouncy($Root/TopBar/TopM/TopH/BackBtn as Button)

	var dt_btn := $Root/CardsArea/CardsHBox/CardDanTranh/DTRoot/DTContent/DTCVBox/DTBtn as Button
	dt_btn.pressed.connect(_go_practice_tranh)
	_make_bouncy(dt_btn)

	var st_btn := $Root/CardsArea/CardsHBox/CardSaoTruc/STRoot/STContent/STCVBox/STBtn as Button
	st_btn.pressed.connect(_go_practice_sao)
	_make_bouncy(st_btn)

# ── Image / Illustration setup ────────────────────────────────────────────────
func _setup_images() -> void:
	var cards := [
		{
			"img":    $Root/CardsArea/CardsHBox/CardDanTranh/DTRoot/DTImageArea/DTImage,
			"area":   $Root/CardsArea/CardsHBox/CardDanTranh/DTRoot/DTImageArea,
			"cvbox":  $Root/CardsArea/CardsHBox/CardDanTranh/DTRoot/DTContent/DTCVBox,
			"path":   IMG_DAN_TRANH,
			"bg":     Color(0.10, 0.03, 0.06, 1.0),
			"accent": C_GOLD,
			"kind":   "dan_tranh",
			"tag":    "Nhạc cụ dây",
		},
		{
			"img":    $Root/CardsArea/CardsHBox/CardSaoTruc/STRoot/STImageArea/STImage,
			"area":   $Root/CardsArea/CardsHBox/CardSaoTruc/STRoot/STImageArea,
			"cvbox":  $Root/CardsArea/CardsHBox/CardSaoTruc/STRoot/STContent/STCVBox,
			"path":   IMG_SAO_TRUC,
			"bg":     Color(0.03, 0.09, 0.05, 1.0),
			"accent": C_JADE,
			"kind":   "sao_truc",
			"tag":    "Nhạc cụ hơi",
		},
		{
			"img":    $Root/CardsArea/CardsHBox/CardDanBau/DBRoot/DBImageArea/DBImage,
			"area":   $Root/CardsArea/CardsHBox/CardDanBau/DBRoot/DBImageArea,
			"cvbox":  $Root/CardsArea/CardsHBox/CardDanBau/DBRoot/DBContent/DBCVBox,
			"path":   IMG_DAN_BAU,
			"bg":     Color(0.06, 0.04, 0.12, 1.0),
			"accent": Color(0.55, 0.45, 0.80, 1.0),
			"kind":   "dan_bau",
			"tag":    "Nhạc cụ dây",
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
		# ── Coloured background ───────────────────────────────────────────────
		var bg_rect := ColorRect.new()
		bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg_rect.color = bg
		bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		area.add_child(bg_rect)
		area.move_child(bg_rect, 0)

		# ── Vector illustration ───────────────────────────────────────────────
		var illus := Control.new()
		illus.set_anchors_preset(Control.PRESET_FULL_RECT)
		illus.mouse_filter = Control.MOUSE_FILTER_IGNORE
		match kind:
			"dan_tranh": illus.draw.connect(func() -> void: _draw_dan_tranh(illus, accent))
			"sao_truc":  illus.draw.connect(func() -> void: _draw_sao_truc(illus, accent))
			_:           illus.draw.connect(func() -> void: _draw_dan_bau(illus, accent))
		area.add_child(illus)

	# ── Gradient fade at bottom of image area ────────────────────────────────
	var fade := Control.new()
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var card_bg := cvbox.get_parent().get_parent().get_parent()  # DTRoot parent = card
	var fade_col := bg
	fade.draw.connect(func() -> void:
		var sz := fade.size
		var start_y := sz.y * 0.55
		var steps := 12
		for i in range(steps):
			var t := float(i) / float(steps - 1)
			var y0 := start_y + t * (sz.y - start_y)
			var y1 := start_y + (t + 1.0/steps) * (sz.y - start_y)
			var a := t * t * 0.88
			fade.draw_rect(Rect2(0, y0, sz.x, max(1, y1 - y0)),
				Color(fade_col.r, fade_col.g, fade_col.b, a))
	)
	area.add_child(fade)

	# ── Accent stripe ─────────────────────────────────────────────────────────
	var stripe := ColorRect.new()
	stripe.anchor_top = 1.0; stripe.anchor_bottom = 1.0
	stripe.anchor_left = 0.0; stripe.anchor_right  = 1.0
	stripe.offset_top = -3.0; stripe.offset_bottom = 0.0
	stripe.color = Color(accent.r, accent.g, accent.b, 0.90)
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.add_child(stripe)

	# ── Category badge (bottom-left of image) ────────────────────────────────
	var badge := Label.new()
	badge.text = tag
	badge.anchor_left   = 0.0; badge.anchor_right  = 0.0
	badge.anchor_top    = 1.0; badge.anchor_bottom = 1.0
	badge.grow_horizontal = Control.GROW_DIRECTION_END
	badge.grow_vertical   = Control.GROW_DIRECTION_BEGIN
	badge.offset_left   = 14.0; badge.offset_top    = -36.0
	badge.offset_right  = 180.0; badge.offset_bottom = -12.0
	badge.add_theme_font_size_override("font_size", 11)
	badge.add_theme_color_override("font_color", Color(accent.r, accent.g, accent.b, 0.80))
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.add_child(badge)

# ── Đàn Tranh illustration ────────────────────────────────────────────────────
func _draw_dan_tranh(c: Control, ac: Color) -> void:
	var w := c.size.x;  var h := c.size.y
	var cx := w * 0.50; var cy := h * 0.50

	# Ambient glow (multi-layer)
	for i in range(5):
		var r := h * (0.55 - i * 0.07)
		c.draw_circle(Vector2(cx, cy), r, Color(ac.r, ac.g, ac.b, 0.018))

	# Shadow beneath
	for i in range(3):
		c.draw_circle(Vector2(cx, cy + h*0.30 + i*4),
			w * (0.30 - i*0.04), Color(0, 0, 0, 0.18))

	# Body geometry
	var bw2 := w * 0.36; var bh2 := h * 0.26; var taper := w * 0.06
	var body := PackedVector2Array([
		Vector2(cx - bw2,         cy + bh2),
		Vector2(cx + bw2,         cy + bh2),
		Vector2(cx + bw2 - taper, cy - bh2),
		Vector2(cx - bw2 + taper, cy - bh2),
	])
	# Wood fill (dark amber)
	c.draw_colored_polygon(body, Color(0.28, 0.11, 0.03, 0.95))
	# Warm highlight overlay on left half
	var hi := PackedVector2Array([
		Vector2(cx - bw2,          cy + bh2),
		Vector2(cx,                cy + bh2),
		Vector2(cx - taper * 0.5,  cy - bh2),
		Vector2(cx - bw2 + taper,  cy - bh2),
	])
	c.draw_colored_polygon(hi, Color(1.0, 0.55, 0.20, 0.10))

	# Wood grain lines
	for i in range(10):
		var t := float(i) / 9.0
		var gy := (cy - bh2 + 6) + t * (bh2 * 2 - 12)
		var lx := cx - bw2 + taper * (1.0 - t) + 6
		var rx := cx + bw2 - taper * (1.0 - t) - 6
		c.draw_line(Vector2(lx, gy), Vector2(rx, gy),
			Color(0.55, 0.28, 0.10, 0.15), 1.0)

	# Inner inlay border
	var inset := 9.0
	var inlay := PackedVector2Array([
		Vector2(cx - bw2 + inset,          cy + bh2 - inset),
		Vector2(cx + bw2 - inset,          cy + bh2 - inset),
		Vector2(cx + bw2 - taper - inset,  cy - bh2 + inset),
		Vector2(cx - bw2 + taper + inset,  cy - bh2 + inset),
	])
	for i in range(4):
		c.draw_line(inlay[i], inlay[(i+1)%4], Color(ac.r, ac.g, ac.b, 0.30), 1.0)

	# Body outline
	for i in range(4):
		c.draw_line(body[i], body[(i+1)%4],
			Color(0.75, 0.45, 0.15, 0.85), 2.2)

	# Sound holes (2 circles)
	for sx in [cx - bw2*0.48, cx + bw2*0.48]:
		var sy := cy + bh2 * 0.52
		c.draw_circle(Vector2(sx, sy), 7.0, Color(0.06, 0.02, 0.00, 0.95))
		c.draw_arc(Vector2(sx, sy), 7.0, 0, TAU, 20,
			Color(ac.r, ac.g, ac.b, 0.45), 1.5)
		c.draw_arc(Vector2(sx, sy), 4.5, 0, TAU, 16,
			Color(ac.r, ac.g, ac.b, 0.20), 1.0)

	# 16 strings
	var n := 16
	var sy0 := cy - bh2 + 4.0; var sy1 := cy + bh2 - 4.0
	var sw0 := (bw2 - taper) * 2.0 - 10.0
	var sw1 := bw2 * 2.0 - 10.0
	for i in range(n):
		var t := float(i) / float(n - 1)
		var xt := cx - sw0/2 + t * sw0
		var xb := cx - sw1/2 + t * sw1
		var mid_bright : float = 1.0 - absf(t - 0.5) * 0.6
		# Glow pass (thick, dim)
		c.draw_line(Vector2(xt, sy0), Vector2(xb, sy1),
			Color(ac.r, ac.g * mid_bright, ac.b * 0.2, 0.18), 4.0)
		# Main string
		c.draw_line(Vector2(xt, sy0), Vector2(xb, sy1),
			Color(ac.r, ac.g * mid_bright * 1.1, ac.b * 0.3, 0.80), 1.3)

	# Bridges (ngựa) — teardrop markers at 40% along each string
	for i in range(n):
		var t := float(i) / float(n - 1)
		var xt := cx - sw0/2 + t * sw0
		var xb := cx - sw1/2 + t * sw1
		var bx := lerpf(xt, xb, 0.40)
		var by := lerpf(sy0, sy1, 0.40)
		c.draw_circle(Vector2(bx, by), 4.0, Color(0.92, 0.76, 0.30, 0.95))
		c.draw_circle(Vector2(bx, by), 2.0, Color(1.00, 0.95, 0.65, 1.00))

# ── Sáo Trúc illustration ─────────────────────────────────────────────────────
func _draw_sao_truc(c: Control, ac: Color) -> void:
	var w := c.size.x; var h := c.size.y

	var p0 := Vector2(w * 0.12, h * 0.30)
	var p1 := Vector2(w * 0.90, h * 0.70)
	var dir  := (p1 - p0).normalized()
	var perp := Vector2(-dir.y, dir.x)
	var hw   := 16.0  # half-width of flute

	# Ambient glow
	for i in range(4):
		var r := h * (0.40 - i * 0.06)
		var mid := p0.lerp(p1, 0.5)
		c.draw_circle(mid, r, Color(ac.r, ac.g, ac.b, 0.018))

	# Shadow beneath
	for i in range(3):
		var off := perp * (hw + 6 + i * 5)
		c.draw_line(p0 + off, p1 + off,
			Color(0, 0, 0, 0.12 - i * 0.03), (hw + i * 3) * 0.8)

	# Flute body base (dark bamboo green)
	var corners := PackedVector2Array([
		p0 + perp * hw, p1 + perp * hw,
		p1 - perp * hw, p0 - perp * hw,
	])
	c.draw_colored_polygon(corners, Color(0.08, 0.24, 0.08, 0.92))

	# Highlight strip (top edge, lighter)
	var hi_w := hw * 0.35
	var hi_corners := PackedVector2Array([
		p0 - perp * hw,       p1 - perp * hw,
		p1 - perp * (hw - hi_w * 2), p0 - perp * (hw - hi_w * 2),
	])
	c.draw_colored_polygon(hi_corners, Color(0.35, 0.68, 0.25, 0.22))

	# Bamboo nodes (6 rings across the flute)
	for i in range(1, 7):
		var t := float(i) / 7.0
		var mid := p0.lerp(p1, t)
		# Dark ring
		c.draw_line(mid + perp * (hw + 2), mid - perp * (hw + 2),
			Color(0.04, 0.10, 0.04, 0.85), 3.5)
		# Light highlight on node
		c.draw_line(mid + perp * hw * 0.6, mid - perp * hw * 0.6,
			Color(0.40, 0.72, 0.30, 0.30), 1.5)

	# Flute outline
	for i in range(4):
		c.draw_line(corners[i], corners[(i+1)%4],
			Color(ac.r, ac.g, ac.b, 0.55), 1.8)

	# Mouthpiece hole (at ~12% along flute)
	var blow := p0.lerp(p1, 0.12)
	c.draw_circle(blow, 8.0, Color(0.02, 0.06, 0.02, 0.95))
	c.draw_arc(blow, 8.0, 0, TAU, 20, Color(ac.r, ac.g, ac.b, 0.65), 2.0)
	c.draw_arc(blow, 5.0, 0, TAU, 16, Color(ac.r, ac.g, ac.b, 0.30), 1.0)

	# 6 finger holes
	for i in range(6):
		var t := 0.28 + float(i) * 0.105
		var hc := p0.lerp(p1, t)
		# Hole shadow
		c.draw_circle(hc, 6.5, Color(0.01, 0.04, 0.01, 0.95))
		# Bright ring
		c.draw_arc(hc, 6.5, 0, TAU, 18, Color(ac.r, ac.g, ac.b, 0.70), 1.8)
		# Inner highlight
		c.draw_circle(hc + Vector2(-1.5, -1.5), 2.0, Color(ac.r, ac.g, ac.b, 0.25))

	# End cap (right end of flute)
	var end_cap := p1 + dir * 4
	c.draw_circle(end_cap, hw * 0.95, Color(0.06, 0.18, 0.06, 0.85))
	c.draw_arc(end_cap, hw * 0.95, 0, TAU, 24,
		Color(ac.r, ac.g, ac.b, 0.40), 1.5)

# ── Đàn Bầu illustration (locked, dim) ───────────────────────────────────────
func _draw_dan_bau(c: Control, ac: Color) -> void:
	var w := c.size.x; var h := c.size.y
	var cx := w * 0.50; var cy := h * 0.54

	# Faint glow
	c.draw_circle(Vector2(cx, cy), h * 0.38, Color(ac.r, ac.g, ac.b, 0.025))

	# Resonator box (rectangular body)
	var bw := w * 0.60; var bh := h * 0.22
	var box_pts := PackedVector2Array([
		Vector2(cx - bw/2, cy + bh/2),
		Vector2(cx + bw/2, cy + bh/2),
		Vector2(cx + bw/2, cy - bh/2),
		Vector2(cx - bw/2, cy - bh/2),
	])
	c.draw_colored_polygon(box_pts, Color(0.20, 0.14, 0.08, 0.35))
	for i in range(4):
		c.draw_line(box_pts[i], box_pts[(i+1)%4],
			Color(ac.r, ac.g, ac.b, 0.22), 1.5)

	# Sound hole on box
	c.draw_circle(Vector2(cx, cy), 12.0, Color(0.04, 0.03, 0.08, 0.60))
	c.draw_arc(Vector2(cx, cy), 12.0, 0, TAU, 24,
		Color(ac.r, ac.g, ac.b, 0.22), 1.2)

	# Neck / cần đàn (vertical rod from box top)
	var neck_x := cx - bw * 0.38
	c.draw_line(Vector2(neck_x, cy - bh/2), Vector2(neck_x, cy - h*0.32),
		Color(ac.r, ac.g, ac.b, 0.22), 7.0)

	# Tuning peg
	c.draw_circle(Vector2(neck_x, cy - h*0.33), 6.0,
		Color(ac.r, ac.g, ac.b, 0.22))

	# Single string (horizontal across box)
	var str_y := cy - bh * 0.10
	c.draw_line(Vector2(cx - bw/2 - 20, str_y), Vector2(cx + bw/2 + 20, str_y),
		Color(ac.r, ac.g, ac.b, 0.28), 1.5)

	# Viet Tuong (đầu cần uốn cong)
	c.draw_arc(Vector2(neck_x + 18, cy - h*0.28), 18, deg_to_rad(150), deg_to_rad(340),
		16, Color(ac.r, ac.g, ac.b, 0.22), 5.0)

	# "Sắp ra mắt" ghost text
	var lbl := Label.new()
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.text = "Sắp\nra mắt"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color(ac.r, ac.g, ac.b, 0.18))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(lbl)

# ── Card theming ──────────────────────────────────────────────────────────────
func _build_theme() -> void:
	var top_s := _flat(Color(0.04, 0.024, 0.11, 0.98), Color(1, 1, 1, 0.08), 0)
	top_s.border_width_top    = 0; top_s.border_width_left  = 0
	top_s.border_width_right  = 0; top_s.border_width_bottom = 1
	($Root/TopBar as PanelContainer).add_theme_stylebox_override("panel", top_s)
	($Root/TopBar/TopM/TopH/PageTitle as Label).add_theme_color_override("font_color", C_WHITE)

	var back := $Root/TopBar/TopM/TopH/BackBtn as Button
	back.add_theme_color_override("font_color",       C_GOLD)
	back.add_theme_color_override("font_hover_color", C_GOLD_LT)
	back.add_theme_stylebox_override("normal",  _flat(Color(0,0,0,0), Color(0,0,0,0), 10))
	back.add_theme_stylebox_override("hover",   _flat(Color(1,1,1,0.07), Color(0,0,0,0), 10))
	back.add_theme_stylebox_override("pressed", _flat(Color(1,1,1,0.12), Color(0,0,0,0), 10))
	back.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0), 0))

	_style_card(
		$Root/CardsArea/CardsHBox/CardDanTranh,
		$Root/CardsArea/CardsHBox/CardDanTranh/DTRoot/DTContent/DTCVBox,
		Color(0.11, 0.03, 0.06, 0.98), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.50),
		C_GOLD, Color(0.68, 0.10, 0.07, 1.0), "DTBar", "DTBtn", "DTPct")

	_style_card(
		$Root/CardsArea/CardsHBox/CardSaoTruc,
		$Root/CardsArea/CardsHBox/CardSaoTruc/STRoot/STContent/STCVBox,
		Color(0.03, 0.10, 0.06, 0.98), Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.50),
		C_JADE, Color(0.07, 0.48, 0.30, 1.0), "STBar", "STBtn", "STPct")

	_style_card_locked(
		$Root/CardsArea/CardsHBox/CardDanBau,
		$Root/CardsArea/CardsHBox/CardDanBau/DBRoot/DBContent/DBCVBox)

func _style_card(card: PanelContainer, cvbox: VBoxContainer,
		bg: Color, border: Color, accent: Color, btn_col: Color,
		bar_name: String, btn_name: String, pct_name: String) -> void:
	var cs := _flat(bg, border, 24)
	cs.shadow_size = 40; cs.shadow_color = Color(0, 0, 0, 0.60)
	cs.border_width_top = 3; cs.border_width_left = 1
	cs.border_width_right = 1; cs.border_width_bottom = 1
	card.add_theme_stylebox_override("panel", cs)

	(cvbox.get_child(0) as Label).add_theme_color_override("font_color", C_WHITE)
	(cvbox.get_child(1) as Label).add_theme_color_override("font_color", C_WHITE_DIM)
	(cvbox.get_node(pct_name) as Label).add_theme_color_override("font_color", C_DIM)

	var pb  := cvbox.get_node(bar_name) as ProgressBar
	var pf  := StyleBoxFlat.new()
	pf.bg_color = accent
	pf.corner_radius_top_left = 3; pf.corner_radius_top_right    = 3
	pf.corner_radius_bottom_left = 3; pf.corner_radius_bottom_right = 3
	pf.shadow_size = 8; pf.shadow_color = Color(accent.r, accent.g, accent.b, 0.50)
	var pbg := StyleBoxFlat.new()
	pbg.bg_color = Color(1, 1, 1, 0.07)
	pbg.corner_radius_top_left = 3; pbg.corner_radius_top_right    = 3
	pbg.corner_radius_bottom_left = 3; pbg.corner_radius_bottom_right = 3
	pb.add_theme_stylebox_override("fill", pf)
	pb.add_theme_stylebox_override("background", pbg)

	var btn := cvbox.get_node(btn_name) as Button
	var bn  := _flat(btn_col, Color(1, 1, 1, 0.15), 28)
	bn.shadow_size = 16; bn.shadow_color = Color(btn_col.r, btn_col.g, btn_col.b, 0.45)
	var bh  := _flat(btn_col.lightened(0.22), Color(1, 1, 1, 0.28), 28)
	bh.shadow_size = 26; bh.shadow_color = Color(btn_col.r, btn_col.g, btn_col.b, 0.60)
	btn.add_theme_stylebox_override("normal",  bn)
	btn.add_theme_stylebox_override("hover",   bh)
	btn.add_theme_stylebox_override("pressed", _flat(btn_col.darkened(0.15), Color(0,0,0,0), 28))
	btn.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	btn.add_theme_color_override("font_color",         C_WHITE)
	btn.add_theme_color_override("font_hover_color",   C_WHITE)
	btn.add_theme_color_override("font_pressed_color", C_WHITE)

func _style_card_locked(card: PanelContainer, cvbox: VBoxContainer) -> void:
	var cs := _flat(Color(0.07, 0.05, 0.13, 0.88), Color(1, 1, 1, 0.08), 24)
	cs.shadow_size = 12; cs.shadow_color = Color(0, 0, 0, 0.28)
	cs.border_width_top = 1; cs.border_width_left = 1
	cs.border_width_right = 1; cs.border_width_bottom = 1
	card.add_theme_stylebox_override("panel", cs)
	card.modulate.a = 0.52

	for child in cvbox.get_children():
		if child is Label:
			(child as Label).add_theme_color_override("font_color", C_DIM)

	var btn := cvbox.get_node("DBBtn") as Button
	btn.add_theme_stylebox_override("normal",   _flat(Color(1,1,1,0.05), Color(1,1,1,0.08), 28))
	btn.add_theme_stylebox_override("disabled", _flat(Color(1,1,1,0.03), Color(1,1,1,0.05), 28))
	btn.add_theme_color_override("font_color",          Color(1,1,1,0.26))
	btn.add_theme_color_override("font_disabled_color", Color(1,1,1,0.20))

# ── Entrance animation ────────────────────────────────────────────────────────
func _animate_in() -> void:
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.32)
	var delay := 0.08
	for card in ($Root/CardsArea/CardsHBox as HBoxContainer).get_children():
		var c := card as Control
		c.modulate.a = 0.0
		c.position.y += 44.0
		var t := create_tween().set_parallel(true)
		t.tween_property(c, "modulate:a", 1.0, 0.48).set_delay(delay)
		t.tween_property(c, "position:y", 0.0, 0.58).set_delay(delay)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		delay += 0.13

# ── Navigation ────────────────────────────────────────────────────────────────
func _go_practice_tranh() -> void:
	selected_instrument = "dan_tranh"
	_fade_to("res://scenes/MainMenu.tscn")

func _go_practice_sao() -> void:
	selected_instrument = "sao_truc"
	_fade_to("res://scenes/MainMenu.tscn")

func _go_back() -> void:
	_fade_to("res://scenes/LoginScreen.tscn")

func _fade_to(scene: String) -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.22)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file(scene))

# ── Helpers ───────────────────────────────────────────────────────────────────
func _flat(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.border_color = border
	s.border_width_left = 1; s.border_width_right  = 1
	s.border_width_top  = 1; s.border_width_bottom = 1
	s.corner_radius_top_left     = radius; s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius; s.corner_radius_bottom_right = radius
	return s

func _make_bouncy(btn: Button) -> void:
	btn.pivot_offset = btn.size / 2.0
	btn.resized.connect(func() -> void: btn.pivot_offset = btn.size / 2.0)
	btn.mouse_entered.connect(func() -> void:
		create_tween().tween_property(btn, "scale", Vector2(1.05, 1.05), 0.12)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
	btn.mouse_exited.connect(func() -> void:
		create_tween().tween_property(btn, "scale", Vector2.ONE, 0.12)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
	btn.button_down.connect(func() -> void:
		create_tween().tween_property(btn, "scale", Vector2(0.95, 0.95), 0.08)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT))
	btn.button_up.connect(func() -> void:
		var target := Vector2(1.05, 1.05) if btn.is_hovered() else Vector2.ONE
		create_tween().tween_property(btn, "scale", target, 0.12)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
