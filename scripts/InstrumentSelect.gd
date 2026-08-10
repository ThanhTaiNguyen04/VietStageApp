extends Control
class_name InstrumentSelect

static var selected_instrument := "dan_tranh"

# ─── Color Palette — Warm Cream + Jade + Gold (synced with DS.gd)
const C_GOLD      := Color(0.77, 0.58, 0.15, 1.0)   # #C59626
const C_GOLD_LT   := Color(0.94, 0.80, 0.38, 1.0)

# Primary — jade CTA
const C_PRIMARY   := Color(0.09, 0.27, 0.18, 1.0)   # #173F2D
const C_PRIMARY_LT := Color(0.14, 0.37, 0.23, 1.0)  # #245F43
const C_PRIMARY_DK := Color(0.05, 0.18, 0.12, 1.0)

# Legacy alias — kept so legacy call sites don't break
const C_RED_SON   := Color(0.09, 0.27, 0.18, 1.0)   # jade (legacy alias)
const C_JADE       := Color(0.09, 0.27, 0.18, 1.0)  # #173F2D
const C_JADE_LIGHT := Color(0.09, 0.27, 0.18, 1.0)
const C_JADE_LT    := Color(0.14, 0.37, 0.23, 1.0)

# Backgrounds (cream)
const C_BG_DARK   := Color(0.98, 0.97, 0.94, 1.0)   # #FAF8F5 cream page
const C_BG_MID    := Color(0.95, 0.93, 0.89, 1.0)   # #F3EFE3 sidebar cream

# Text
const C_WHITE     := Color(0.13, 0.08, 0.05, 1.0)   # warm charcoal
const C_WHITE_DIM := Color(0.44, 0.38, 0.34, 1.0)   # muted
const C_DIM       := Color(0.44, 0.38, 0.34, 0.45)  # faint

const IMG_DAN_TRANH := "res://assets/textures/dan_tranh_asset.png"
const IMG_SAO_TRUC  := "res://assets/textures/sao_truc_asset.png"
const IMG_DAN_BAU   := "res://assets/textures/dan_bau_asset.png"

func _ready() -> void:
	_build_theme()
	_setup_images()
	_animate_in()

	($Root/TopBar/TopM/TopH/BackBtn as Button).pressed.connect(_go_back)
	_make_bouncy($Root/TopBar/TopM/TopH/BackBtn as Button)

	var dt_btn := $Root/CardsArea/CardsScroll/CardsHBox/CardDanTranh/DTRoot/DTContent/DTCVBox/DTBtn as Button
	dt_btn.pressed.connect(_go_practice_tranh)
	_make_bouncy(dt_btn)

	var st_btn := $Root/CardsArea/CardsScroll/CardsHBox/CardSaoTruc/STRoot/STContent/STCVBox/STBtn as Button
	st_btn.pressed.connect(_go_practice_sao)
	_make_bouncy(st_btn)

	var db_btn := $Root/CardsArea/CardsScroll/CardsHBox/CardDanBau/DBRoot/DBContent/DBCVBox/DBBtn as Button
	db_btn.pressed.connect(_go_practice_bau)
	_make_bouncy(db_btn)

	var tc_btn := $Root/CardsArea/CardsScroll/CardsHBox/CardTrongChau/TCRoot/TCContent/TCCVBox/TCBtn as Button
	tc_btn.pressed.connect(_go_practice_trong)
	_make_bouncy(tc_btn)

	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()

# ── Image / Illustration setup ────────────────────────────────────────────────
func _setup_images() -> void:
	var cards := [
		{
			"img":    $Root/CardsArea/CardsScroll/CardsHBox/CardDanTranh/DTRoot/DTImageArea/DTImage,
			"area":   $Root/CardsArea/CardsScroll/CardsHBox/CardDanTranh/DTRoot/DTImageArea,
			"cvbox":  $Root/CardsArea/CardsScroll/CardsHBox/CardDanTranh/DTRoot/DTContent/DTCVBox,
			"path":   IMG_DAN_TRANH,
			"bg":     Color(0.059, 0.180, 0.118, 1.0), # deep jade dark
			"accent": C_GOLD,
			"kind":   "dan_tranh",
			"tag":    "Nhạc cụ dây",
		},
		{
			"img":    $Root/CardsArea/CardsScroll/CardsHBox/CardSaoTruc/STRoot/STImageArea/STImage,
			"area":   $Root/CardsArea/CardsScroll/CardsHBox/CardSaoTruc/STRoot/STImageArea,
			"cvbox":  $Root/CardsArea/CardsScroll/CardsHBox/CardSaoTruc/STRoot/STContent/STCVBox,
			"path":   IMG_SAO_TRUC,
			"bg":     Color(0.039, 0.145, 0.055, 1.0), # dark bamboo green
			"accent": C_GOLD_LT,
			"kind":   "sao_truc",
			"tag":    "Nhạc cụ hơi",
		},
		{
			"img":    $Root/CardsArea/CardsScroll/CardsHBox/CardDanBau/DBRoot/DBImageArea/DBImage,
			"area":   $Root/CardsArea/CardsScroll/CardsHBox/CardDanBau/DBRoot/DBImageArea,
			"cvbox":  $Root/CardsArea/CardsScroll/CardsHBox/CardDanBau/DBRoot/DBContent/DBCVBox,
			"path":   IMG_DAN_BAU,
			"bg":     Color(0.169, 0.094, 0.047, 1.0), # dark walnut
			"accent": C_GOLD,
			"kind":   "dan_bau",
			"tag":    "Nhạc cụ dây",
		},
		{
			"img":    $Root/CardsArea/CardsScroll/CardsHBox/CardTrongChau/TCRoot/TCImageArea/TCImage,
			"area":   $Root/CardsArea/CardsScroll/CardsHBox/CardTrongChau/TCRoot/TCImageArea,
			"cvbox":  $Root/CardsArea/CardsScroll/CardsHBox/CardTrongChau/TCRoot/TCContent/TCCVBox,
			"path":   "res://assets/textures/trong_chau_asset.png",
			"bg":     Color(0.96, 0.88, 0.88, 1.0), # soft red/pink cream
			"accent": Color(0.85, 0.18, 0.12, 1.0), # vermilion red accent
			"kind":   "trong_chau",
			"tag":    "Nhạc cụ gõ",
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
			"dan_tranh":  illus.draw.connect(func() -> void: _draw_dan_tranh(illus, accent))
			"sao_truc":   illus.draw.connect(func() -> void: _draw_sao_truc(illus, accent))
			"dan_bau":    illus.draw.connect(func() -> void: _draw_dan_bau(illus, accent))
			"trong_chau": illus.draw.connect(func() -> void: _draw_trong_chau(illus, accent))
			_:            illus.draw.connect(func() -> void: _draw_dan_bau(illus, accent))
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

# ── Đàn Bầu illustration ──────────────────────────────────────────────────────
func _draw_dan_bau(c: Control, ac: Color) -> void:
	var w := c.size.x; var h := c.size.y
	var cx := w * 0.50; var cy := h * 0.54

	# Deep warm ambient glow
	for i in range(5):
		var r := h * (0.55 - i * 0.07)
		c.draw_circle(Vector2(cx, cy), r, Color(ac.r, ac.g, ac.b, 0.022))

	# Drop shadow beneath zither body
	for i in range(3):
		c.draw_rect(Rect2(cx - w*0.30, cy + h*0.09 + i*4, w*0.60, 10.0), Color(0, 0, 0, 0.15))

	# Resonator box (rectangular body) - rich dark rosewood
	var bw := w * 0.62; var bh := h * 0.20
	var box_pts := PackedVector2Array([
		Vector2(cx - bw/2, cy + bh/2),
		Vector2(cx + bw/2, cy + bh/2),
		Vector2(cx + bw/2 - 20, cy - bh/2),
		Vector2(cx - bw/2 + 20, cy - bh/2),
	])
	c.draw_colored_polygon(box_pts, Color(0.24, 0.11, 0.04, 0.95)) # mahogany wood
	
	# Wood grain details
	for i in range(5):
		var t := float(i) / 4.0
		var gy := (cy - bh/2 + 4) + t * (bh - 8)
		var lx := cx - bw/2 + 20.0 + (1.0 - t)*5.0
		var rx := cx + bw/2 - 20.0 - (1.0 - t)*5.0
		c.draw_line(Vector2(lx, gy), Vector2(rx, gy), Color(0.55, 0.28, 0.10, 0.12), 1.0)

	# Traditional gold/ivory border outlines
	for i in range(4):
		c.draw_line(box_pts[i], box_pts[(i+1)%4], Color(0.95, 0.72, 0.18, 0.85), 2.0)

	# Sound hole on box - shiny gold bordered circle
	c.draw_circle(Vector2(cx, cy), 13.0, Color(0.04, 0.02, 0.01, 0.98))
	c.draw_arc(Vector2(cx, cy), 13.0, 0, TAU, 24, Color(0.95, 0.72, 0.18, 0.75), 1.5)

	# Neck / cần đàn - curved black buffalo horn rod on the left
	var neck_x := cx - bw * 0.38
	var rod_start := Vector2(neck_x, cy + bh * 0.2)
	var rod_control := Vector2(neck_x - 30.0, cy - h*0.1)
	var rod_end := Vector2(neck_x - 15.0, cy - h*0.35)
	
	# Draw horn rod as a thick curve
	var curve_pts := PackedVector2Array()
	for k in range(16):
		var t := float(k)/15.0
		var p_t := (1.0-t)*(1.0-t)*rod_start + 2.0*(1.0-t)*t*rod_control + t*t*rod_end
		curve_pts.append(p_t)
	c.draw_polyline(curve_pts, Color(0.12, 0.12, 0.12, 1.0), 6.0, true)

	# Golden Gourd (Bầu) at the end of the horn rod
	var gourd_center := rod_end
	c.draw_circle(gourd_center, 10.0, Color(0.77, 0.58, 0.15))
	c.draw_circle(gourd_center + Vector2(0, -6.0), 7.0, Color(0.77, 0.58, 0.15))
	c.draw_circle(gourd_center, 4.0, Color(0.95, 0.82, 0.45)) # highlight

	# Single golden string running from the gourd to the right block
	var str_start := gourd_center
	var str_end := Vector2(cx + bw * 0.45, cy + bh * 0.1)
	
	# Shadow of the string
	c.draw_line(str_start + Vector2(0, 3.0), str_end + Vector2(0, 3.0), Color(0.0, 0.0, 0.0, 0.25), 1.0)
	# Glowing aura of string
	c.draw_line(str_start, str_end, Color(0.95, 0.72, 0.18, 0.2), 3.0)
	# String core
	c.draw_line(str_start, str_end, Color(0.95, 0.82, 0.45, 1.0), 1.5)

# ── Card theming ──────────────────────────────────────────────────────────────
func _build_theme() -> void:
	# ── Top bar: cream glass with gold bottom accent ─────────────────────────
	var top_s := _flat(Color(0.95, 0.93, 0.89, 0.92), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35), 0)
	top_s.border_width_top    = 0; top_s.border_width_left  = 0
	top_s.border_width_right  = 0; top_s.border_width_bottom = 2
	top_s.shadow_size = 16; top_s.shadow_color = Color(0.13, 0.08, 0.05, 0.18)
	top_s.shadow_offset = Vector2(0, 4)
	($Root/TopBar as PanelContainer).add_theme_stylebox_override("panel", top_s)
	
	# Title: warm charcoal
	($Root/TopBar/TopM/TopH/PageTitle as Label).add_theme_color_override("font_color", C_WHITE)

	# ── Back button: muted on cream bg ───────────────────────────────────────
	var back := $Root/TopBar/TopM/TopH/BackBtn as Button
	back.add_theme_color_override("font_color",       C_WHITE_DIM)
	back.add_theme_color_override("font_hover_color", C_JADE)
	back.add_theme_stylebox_override("normal",  _flat(Color(0,0,0,0), Color(0,0,0,0), 10))
	back.add_theme_stylebox_override("hover",   _flat(Color(C_GOLD.r,C_GOLD.g,C_GOLD.b,0.08), Color(0,0,0,0), 10))
	back.add_theme_stylebox_override("pressed", _flat(Color(C_PRIMARY.r,C_PRIMARY.g,C_PRIMARY.b,0.12), Color(0,0,0,0), 10))
	back.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0), 0))

	SecureDataManager.load_data()

	# Đàn Tranh
	var dt_card := $Root/CardsArea/CardsScroll/CardsHBox/CardDanTranh
	var dt_vbox := $Root/CardsArea/CardsScroll/CardsHBox/CardDanTranh/DTRoot/DTContent/DTCVBox
	var dt_progress := SecureDataManager.get_course_progress("dan_tranh")
	var dt_unlocked := SecureDataManager.is_instrument_unlocked("dan_tranh")
	_update_card_ui(dt_card, dt_vbox, dt_progress, dt_unlocked, C_GOLD, C_PRIMARY,
		Color(1.0, 0.99, 0.97, 1.0), "DTBar", "DTBtn", "DTPct", "Học ngay")

	# Sáo Trúc
	var st_card := $Root/CardsArea/CardsScroll/CardsHBox/CardSaoTruc
	var st_vbox := $Root/CardsArea/CardsScroll/CardsHBox/CardSaoTruc/STRoot/STContent/STCVBox
	var st_progress := SecureDataManager.get_course_progress("sao_truc")
	var st_unlocked := SecureDataManager.is_instrument_unlocked("sao_truc")
	_update_card_ui(st_card, st_vbox, st_progress, st_unlocked, C_GOLD_LT, C_PRIMARY,
		Color(1.0, 0.99, 0.97, 1.0), "STBar", "STBtn", "STPct", "Bắt đầu")

	# Đàn Bầu
	var db_card := $Root/CardsArea/CardsScroll/CardsHBox/CardDanBau
	var db_vbox := $Root/CardsArea/CardsScroll/CardsHBox/CardDanBau/DBRoot/DBContent/DBCVBox
	var db_progress := SecureDataManager.get_course_progress("dan_bau")
	var db_unlocked := SecureDataManager.is_instrument_unlocked("dan_bau")
	_update_card_ui(db_card, db_vbox, db_progress, db_unlocked, C_GOLD, C_PRIMARY,
		Color(1.0, 0.99, 0.97, 1.0), "DBBar", "DBBtn", "DBPct", "Bắt đầu")

	# Trống Chầu
	var tc_card := $Root/CardsArea/CardsScroll/CardsHBox/CardTrongChau
	var tc_vbox := $Root/CardsArea/CardsScroll/CardsHBox/CardTrongChau/TCRoot/TCContent/TCCVBox
	var tc_progress := SecureDataManager.get_course_progress("trong_chau")
	var tc_unlocked := SecureDataManager.is_instrument_unlocked("trong_chau")
	_update_card_ui(tc_card, tc_vbox, tc_progress, tc_unlocked, Color(0.72, 0.12, 0.08, 1.0), Color(0.72, 0.12, 0.08, 1.0), Color(1.0, 0.99, 0.97, 1.0), "TCBar", "TCBtn", "TCPct", "Bắt đầu")

	# Custom scrollbar styling
	var scroll := $Root/CardsArea/CardsScroll as ScrollContainer
	if scroll:
		var h_scrollbar := scroll.get_h_scroll_bar()
		var bar_style := StyleBoxFlat.new()
		bar_style.bg_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.15)
		bar_style.corner_radius_top_left = 4; bar_style.corner_radius_top_right = 4
		bar_style.corner_radius_bottom_left = 4; bar_style.corner_radius_bottom_right = 4
		
		var grabber_style := StyleBoxFlat.new()
		grabber_style.bg_color = C_GOLD
		grabber_style.corner_radius_top_left = 4; grabber_style.corner_radius_top_right = 4
		grabber_style.corner_radius_bottom_left = 4; grabber_style.corner_radius_bottom_right = 4
		
		h_scrollbar.add_theme_stylebox_override("scroll", bar_style)
		h_scrollbar.add_theme_stylebox_override("grabber", grabber_style)
		h_scrollbar.add_theme_stylebox_override("grabber_highlight", grabber_style)
		h_scrollbar.add_theme_stylebox_override("grabber_pressed", grabber_style)
		h_scrollbar.custom_minimum_size = Vector2(h_scrollbar.custom_minimum_size.x, 8)

func _style_card(card: PanelContainer, cvbox: VBoxContainer,
		bg: Color, border: Color, accent: Color, btn_col: Color,
		bar_name: String, btn_name: String, pct_name: String) -> void:
	# Card panel: cream card, gold/accent border, warm glow shadow
	var cs := _flat(bg, border, 20)
	cs.shadow_size = 32; cs.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.18)
	cs.border_width_top = 2; cs.border_width_left = 2
	cs.border_width_right = 2; cs.border_width_bottom = 2
	card.add_theme_stylebox_override("panel", cs)

	# Text: warm charcoal title, muted desc, gold percent
	(cvbox.get_child(0) as Label).add_theme_color_override("font_color", C_WHITE)    # name
	(cvbox.get_child(1) as Label).add_theme_color_override("font_color", C_WHITE_DIM) # desc
	(cvbox.get_node(pct_name) as Label).add_theme_color_override("font_color", C_GOLD)

	# Progress bar: gold fill on cream track
	var pb  := cvbox.get_node(bar_name) as ProgressBar
	var pf  := StyleBoxFlat.new()
	pf.bg_color = C_GOLD
	pf.corner_radius_top_left = 4; pf.corner_radius_top_right    = 4
	pf.corner_radius_bottom_left = 4; pf.corner_radius_bottom_right = 4
	pf.shadow_size = 8; pf.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.40)
	var pbg := StyleBoxFlat.new()
	pbg.bg_color = Color(0.13, 0.08, 0.05, 0.08)
	pbg.corner_radius_top_left = 4; pbg.corner_radius_top_right    = 4
	pbg.corner_radius_bottom_left = 4; pbg.corner_radius_bottom_right = 4
	pb.add_theme_stylebox_override("fill", pf)
	pb.add_theme_stylebox_override("background", pbg)

	# CTA Button: jade gradient, gold glow border, large radius
	var btn := cvbox.get_node(btn_name) as Button
	var bn  := _flat(C_PRIMARY, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.40), 28)
	bn.shadow_size = 16; bn.shadow_color = Color(C_PRIMARY.r, C_PRIMARY.g, C_PRIMARY.b, 0.35)
	var bh  := _flat(C_PRIMARY_LT, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.70), 28)
	bh.shadow_size = 22; bh.shadow_color = Color(C_PRIMARY.r, C_PRIMARY.g, C_PRIMARY.b, 0.50)
	var bp  := _flat(C_PRIMARY_DK, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.20), 28)
	btn.add_theme_stylebox_override("normal",  bn)
	btn.add_theme_stylebox_override("hover",   bh)
	btn.add_theme_stylebox_override("pressed", bp)
	btn.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), C_GOLD, 28))
	btn.add_theme_color_override("font_color",         Color(1, 1, 1, 1))
	btn.add_theme_color_override("font_hover_color",   Color(1, 1, 1, 1))
	btn.add_theme_color_override("font_pressed_color", C_GOLD_LT)

func _style_card_locked(card: PanelContainer, cvbox: VBoxContainer, btn_name: String) -> void:
	# Muted cream card for locked instruments
	var cs := _flat(Color(0.92, 0.90, 0.86, 0.85), Color(0.44, 0.38, 0.34, 0.25), 20)
	cs.shadow_size = 10; cs.shadow_color = Color(0.13, 0.08, 0.05, 0.12)
	cs.border_width_top = 1; cs.border_width_left = 1
	cs.border_width_right = 1; cs.border_width_bottom = 1
	card.add_theme_stylebox_override("panel", cs)
	card.modulate.a = 0.72

	for child in cvbox.get_children():
		if child is Label:
			(child as Label).add_theme_color_override("font_color", C_DIM)

	var btn := cvbox.get_node(btn_name) as Button
	btn.add_theme_stylebox_override("normal",   _flat(Color(0.44,0.38,0.34,0.06), Color(0.44,0.38,0.34,0.15), 28))
	btn.add_theme_stylebox_override("disabled", _flat(Color(0.44,0.38,0.34,0.04), Color(0.44,0.38,0.34,0.10), 28))
	btn.add_theme_color_override("font_color",          C_DIM)
	btn.add_theme_color_override("font_disabled_color", C_DIM)

func _update_card_ui(card: PanelContainer, cvbox: VBoxContainer, progress: float, is_unlocked: bool, accent: Color, btn_col: Color, bg: Color, bar_name: String, btn_name: String, pct_name: String, default_btn_text: String) -> void:
	var pb := cvbox.get_node(bar_name) as ProgressBar
	pb.value = progress
	
	var pct_lbl := cvbox.get_node(pct_name) as Label
	if progress == 0.0:
		pct_lbl.text = "Chưa bắt đầu"
	elif progress == 100.0:
		pct_lbl.text = "Đã hoàn thành"
	else:
		pct_lbl.text = str(int(progress)) + "% hoàn thành"
		
	var btn := cvbox.get_node(btn_name) as Button
	
	var root := card.get_child(0) as VBoxContainer
	var area_name := root.name.left(2) + "ImageArea"
	var area := root.get_node_or_null(area_name) as Control
	
	if area:
		var old_overlay := area.get_node_or_null("LockOverlay")
		if old_overlay:
			old_overlay.queue_free()
			
		if not is_unlocked:
			var overlay := Control.new()
			overlay.name = "LockOverlay"
			overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
			overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
			overlay.draw.connect(func() -> void:
				var lock_tex := load("res://assets/textures/icons8/lock.png") as Texture2D
				if lock_tex:
					var sz := overlay.size
					var lock_sz := Vector2(48, 48)
					var rect := Rect2(sz/2 - lock_sz/2, lock_sz)
					overlay.draw_circle(sz/2, 36.0, Color(0, 0, 0, 0.45))
					overlay.draw_texture_rect(lock_tex, rect, false, Color.WHITE)
			)
			area.add_child(overlay)
			
	if is_unlocked:
		btn.disabled = false
		btn.text = default_btn_text
		card.modulate.a = 1.0
		# Dark card with instrument-colored bg, gold border
		_style_card(card, cvbox,
			bg,                                             # dark instrument bg
			Color(accent.r, accent.g, accent.b, 0.40),     # gold/accent border
			accent,                                         # progress bar fill
			C_PRIMARY,                                      # CTA button terracotta
			bar_name, btn_name, pct_name)
	else:
		btn.disabled = true
		btn.text = "Chưa mở khóa"
		_style_card_locked(card, cvbox, btn_name)

# ── Entrance animation ────────────────────────────────────────────────────────
func _animate_in() -> void:
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.32)
	var delay := 0.08
	for card in ($Root/CardsArea/CardsScroll/CardsHBox as HBoxContainer).get_children():
		var c := card as Control
		c.modulate.a = 0.0
		c.position.y += 44.0
		var t := create_tween().set_parallel(true)
		t.tween_property(c, "modulate:a", 1.0, 0.48).set_delay(delay)
		t.tween_property(c, "position:y", 0.0, 0.58).set_delay(delay)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		delay += 0.13

func _on_viewport_size_changed() -> void:
	var viewport_size = get_viewport().size
	var is_mobile = viewport_size.x < viewport_size.y or viewport_size.x < 768
	
	# Cards scaling
	var cards_hbox := $Root/CardsArea/CardsScroll/CardsHBox as HBoxContainer
	for card in cards_hbox.get_children():
		var c := card as Control
		if is_mobile:
			c.custom_minimum_size = Vector2(300, 0)
			c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		else:
			c.custom_minimum_size = Vector2(0, 0)
			c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
	# TopBar padding
	var top_m := $Root/TopBar/TopM as MarginContainer
	var cards_area := $Root/CardsArea as MarginContainer
	if is_mobile:
		top_m.add_theme_constant_override("margin_left", 16)
		top_m.add_theme_constant_override("margin_right", 16)
		cards_area.add_theme_constant_override("margin_left", 16)
		cards_area.add_theme_constant_override("margin_right", 16)
		cards_area.add_theme_constant_override("margin_top", 16)
		cards_area.add_theme_constant_override("margin_bottom", 16)
		var back_btn := $Root/TopBar/TopM/TopH/BackBtn as Button
		back_btn.custom_minimum_size = Vector2(100, back_btn.custom_minimum_size.y)
		($Root/TopBar/TopM/TopH/PageTitle as Label).add_theme_font_size_override("font_size", 20)
	else:
		top_m.add_theme_constant_override("margin_left", 36)
		top_m.add_theme_constant_override("margin_right", 36)
		cards_area.add_theme_constant_override("margin_left", 44)
		cards_area.add_theme_constant_override("margin_right", 44)
		cards_area.add_theme_constant_override("margin_top", 36)
		cards_area.add_theme_constant_override("margin_bottom", 36)
		var back_btn := $Root/TopBar/TopM/TopH/BackBtn as Button
		back_btn.custom_minimum_size = Vector2(140, back_btn.custom_minimum_size.y)
		($Root/TopBar/TopM/TopH/PageTitle as Label).add_theme_font_size_override("font_size", 28)

# ── Navigation ────────────────────────────────────────────────────────────────
func _go_practice_tranh() -> void:
	selected_instrument = "dan_tranh"
	SecureDataManager.data["selected_instrument"] = "dan_tranh"
	SecureDataManager.save_data()
	_fade_to("res://scenes/MainMenu.tscn")

func _go_practice_sao() -> void:
	selected_instrument = "sao_truc"
	SecureDataManager.data["selected_instrument"] = "sao_truc"
	SecureDataManager.save_data()
	_fade_to("res://scenes/MainMenu.tscn")

func _go_practice_bau() -> void:
	selected_instrument = "dan_bau"
	SecureDataManager.data["selected_instrument"] = "dan_bau"
	SecureDataManager.save_data()
	_fade_to("res://scenes/MainMenu.tscn")

func _go_practice_trong() -> void:
	selected_instrument = "trong_chau"
	SecureDataManager.data["selected_instrument"] = "trong_chau"
	SecureDataManager.save_data()
	_fade_to("res://scenes/MainMenu.tscn")

func _go_back() -> void:
	_fade_to("res://scenes/LoginScreen.tscn")

func _draw_trong_chau(c: Control, ac: Color) -> void:
	var w := c.size.x;  var h := c.size.y
	var cx := w * 0.50; var cy := h * 0.50

	# Ambient glow
	for i in range(5):
		var r := h * (0.55 - i * 0.07)
		c.draw_circle(Vector2(cx, cy), r, Color(ac.r, ac.g, ac.b, 0.018))

	# Shadow
	for i in range(3):
		c.draw_circle(Vector2(cx, cy + h*0.28 + i*4),
			w * (0.28 - i*0.04), Color(0, 0, 0, 0.18))

	# Stand base line
	c.draw_line(Vector2(cx - w*0.2, cy + h*0.25), Vector2(cx + w*0.2, cy + h*0.25), Color(0.24, 0.14, 0.06), 6.0)

	# Drum Body (Flared ellipse barrel)
	var dr_r := w * 0.22
	var dr_h := h * 0.28
	var dc := Vector2(cx, cy - h*0.02)
	
	var drum_pts := PackedVector2Array()
	var steps := 24
	for i in range(steps + 1):
		var t := float(i) / steps
		var py = dc.y + dr_h * 0.5 - t * dr_h
		var w_fac = 1.0
		if t > 0.2 and t < 0.8:
			w_fac = 0.8 + 0.2 * absf(t - 0.5) / 0.3
		drum_pts.append(Vector2(cx - dr_r * w_fac, py))
	for i in range(steps, -1, -1):
		var t := float(i) / steps
		var py = dc.y + dr_h * 0.5 - t * dr_h
		var w_fac = 1.0
		if t > 0.2 and t < 0.8:
			w_fac = 0.8 + 0.2 * absf(t - 0.5) / 0.3
		drum_pts.append(Vector2(cx + dr_r * w_fac, py))
		
	c.draw_colored_polygon(drum_pts, Color(0.28, 0.16, 0.10)) # Wood brown drum body
	c.draw_polyline(drum_pts, ac, 2.0, true)

	# Drum skin (Leather top head)
	var top_pts := PackedVector2Array()
	var trx := dr_r * 1.0
	var try := h * 0.075
	var tc := dc - Vector2(0, dr_h * 0.5)
	for step in range(24):
		var a := float(step) * (TAU / 24.0)
		top_pts.append(tc + Vector2(cos(a) * trx, sin(a) * try))
	c.draw_colored_polygon(top_pts, Color(0.93, 0.85, 0.72))
	c.draw_polyline(top_pts, Color(0.75, 0.60, 0.40), 2.0, true)

	# Drumsticks
	c.draw_line(Vector2(cx - w*0.14, cy + h*0.1), Vector2(cx + w*0.12, cy - h*0.15), Color(0.92, 0.84, 0.72), 4.5, true)
	c.draw_line(Vector2(cx + w*0.14, cy + h*0.1), Vector2(cx - w*0.12, cy - h*0.15), Color(0.92, 0.84, 0.72), 4.5, true)

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
