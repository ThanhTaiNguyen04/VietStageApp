extends Control
class_name InstrumentSelect

static var selected_instrument := "dan_tranh"

const C_GOLD      := Color(0.95, 0.72, 0.18, 1.0)
const C_GOLD_LT   := Color(1.00, 0.87, 0.45, 1.0)
const C_RED_SON   := Color(0.09, 0.27, 0.18, 1.0)
const C_JADE       := Color(0.12, 0.37, 0.23, 1.0) # Standard dark jade
const C_JADE_LIGHT := Color(0.22, 0.86, 0.55, 1.0) # Standard light jade
const C_JADE_LT    := Color(0.42, 0.95, 0.70, 1.0) # Sage/mint overlay
const C_WHITE     := Color(1.00, 1.00, 1.00, 1.0)
const C_WHITE_DIM := Color(1.00, 1.00, 1.00, 0.50)
const C_DIM       := Color(1.00, 1.00, 1.00, 0.24)

const IMG_DAN_TRANH := "res://assets/textures/dan_tranh_asset.png"
const IMG_SAO_TRUC  := "res://assets/textures/sao_truc_asset.png"
const IMG_DAN_BAU   := "res://assets/textures/dan_bau_asset.png"

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

	var dt_btn := $Root/CardsArea/CardsScroll/CardsHBox/CardDanTranh/DTRoot/DTContent/DTCVBox/DTBtn as Button
	dt_btn.pressed.connect(_go_practice_tranh)
	DS.make_bouncy(dt_btn)

	var st_btn := $Root/CardsArea/CardsScroll/CardsHBox/CardSaoTruc/STRoot/STContent/STCVBox/STBtn as Button
	st_btn.pressed.connect(_go_practice_sao)
	DS.make_bouncy(st_btn)

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
			"bg":     Color(0.97, 0.91, 0.85, 1.0), # soft peach/gold
			"accent": C_GOLD,
			"kind":   "dan_tranh",
			"tag":    "Nhạc cụ dây",
		},
		{
			"img":    $Root/CardsArea/CardsScroll/CardsHBox/CardSaoTruc/STRoot/STImageArea/STImage,
			"area":   $Root/CardsArea/CardsScroll/CardsHBox/CardSaoTruc/STRoot/STImageArea,
			"cvbox":  $Root/CardsArea/CardsScroll/CardsHBox/CardSaoTruc/STRoot/STContent/STCVBox,
			"path":   IMG_SAO_TRUC,
			"bg":     Color(0.88, 0.94, 0.90, 1.0), # soft sage green
			"accent": C_JADE_LIGHT,
			"kind":   "sao_truc",
			"tag":    "Nhạc cụ hơi",
		},
		{
			"img":    $Root/CardsArea/CardsScroll/CardsHBox/CardDanBau/DBRoot/DBImageArea/DBImage,
			"area":   $Root/CardsArea/CardsScroll/CardsHBox/CardDanBau/DBRoot/DBImageArea,
			"cvbox":  $Root/CardsArea/CardsScroll/CardsHBox/CardDanBau/DBRoot/DBContent/DBCVBox,
			"path":   IMG_DAN_BAU,
			"bg":     Color(0.92, 0.90, 0.95, 1.0), # soft lavender/gray
			"accent": Color(0.55, 0.45, 0.80, 1.0),
			"kind":  "dan_bau",
			"tag":   "Nhạc cụ dây",
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
			"dan_tranh":  illus.draw.connect(func() -> void: _draw_dan_tranh(illus, accent))
			"sao_truc":   illus.draw.connect(func() -> void: _draw_sao_truc(illus, accent))
			"dan_bau":    illus.draw.connect(func() -> void: _draw_dan_bau(illus, accent))
			"trong_chau": illus.draw.connect(func() -> void: _draw_trong_chau(illus, accent))
			_:            illus.draw.connect(func() -> void: _draw_dan_bau(illus, accent))
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

	# End cap (right end of flute)
	var end_cap := p1 + dir * 4
	c.draw_circle(end_cap, hw * 0.95, Color(0.06, 0.18, 0.06, 0.85))
	c.draw_arc(end_cap, hw * 0.95, 0, TAU, 24,
		Color(ac.r, ac.g, ac.b, 0.40), 1.5)

# ── Đàn Bầu illustration ──────────────────────────────────────────────────────
func _draw_dan_bau(c: Control, ac: Color) -> void:
	var w := c.size.x; var h := c.size.y
	var cx := w * 0.50; var cy := h * 0.52

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

func _build_theme() -> void:
	var top_s := _flat(Color(0.95, 0.93, 0.89, 1.0), Color(0.77, 0.58, 0.15, 0.15), 0)
	top_s.border_width_top    = 0; top_s.border_width_left  = 0
	top_s.border_width_right  = 0; top_s.border_width_bottom = 1
	($Root/TopBar as PanelContainer).add_theme_stylebox_override("panel", top_s)
	($Root/TopBar/TopM/TopH/PageTitle as Label).add_theme_color_override("font_color", C_RED_SON)

	var back := $Root/TopBar/TopM/TopH/BackBtn as Button
	back.add_theme_color_override("font_color",       Color(0.13, 0.08, 0.05, 1.0))
	back.add_theme_color_override("font_hover_color", C_RED_SON)
	back.add_theme_stylebox_override("normal",  _flat(Color(0,0,0,0), Color(0,0,0,0), 10))
	back.add_theme_stylebox_override("hover",   _flat(Color(0,0,0,0.06), Color(0,0,0,0), 10))
	back.add_theme_stylebox_override("pressed", _flat(Color(0,0,0,0.12), Color(0,0,0,0), 10))
	back.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0), 0))

	SecureDataManager.load_data()

	# Đàn Tranh
	var dt_card := $Root/CardsArea/CardsScroll/CardsHBox/CardDanTranh
	var dt_vbox := $Root/CardsArea/CardsScroll/CardsHBox/CardDanTranh/DTRoot/DTContent/DTCVBox
	var dt_progress := SecureDataManager.get_course_progress("dan_tranh")
	var dt_unlocked := SecureDataManager.is_instrument_unlocked("dan_tranh")
	_update_card_ui(dt_card, dt_vbox, dt_progress, dt_unlocked, C_GOLD, C_RED_SON, "DTBar", "DTBtn", "DTPct", "Học ngay")

	# Sáo Trúc
	var st_card := $Root/CardsArea/CardsScroll/CardsHBox/CardSaoTruc
	var st_vbox := $Root/CardsArea/CardsScroll/CardsHBox/CardSaoTruc/STRoot/STContent/STCVBox
	var st_progress := SecureDataManager.get_course_progress("sao_truc")
	var st_unlocked := SecureDataManager.is_instrument_unlocked("sao_truc")
	_update_card_ui(st_card, st_vbox, st_progress, st_unlocked, C_JADE_LIGHT, C_JADE, "STBar", "STBtn", "STPct", "Bắt đầu")

	# Đàn Bầu
	var db_card := $Root/CardsArea/CardsScroll/CardsHBox/CardDanBau
	var db_vbox := $Root/CardsArea/CardsScroll/CardsHBox/CardDanBau/DBRoot/DBContent/DBCVBox
	var db_progress := SecureDataManager.get_course_progress("dan_bau")
	var db_unlocked := SecureDataManager.is_instrument_unlocked("dan_bau")
	_update_card_ui(db_card, db_vbox, db_progress, db_unlocked, C_RED_SON, C_RED_SON, "DBBar", "DBBtn", "DBPct", "Bắt đầu")

	# Trống Chầu
	var tc_card := $Root/CardsArea/CardsScroll/CardsHBox/CardTrongChau
	var tc_vbox := $Root/CardsArea/CardsScroll/CardsHBox/CardTrongChau/TCRoot/TCContent/TCCVBox
	var tc_progress := SecureDataManager.get_course_progress("trong_chau")
	var tc_unlocked := SecureDataManager.is_instrument_unlocked("trong_chau")
	_update_card_ui(tc_card, tc_vbox, tc_progress, tc_unlocked, Color(0.85, 0.18, 0.12, 1.0), Color(0.85, 0.18, 0.12, 1.0), "TCBar", "TCBtn", "TCPct", "Bắt đầu")

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
	var cs := _flat(bg, border, 24)
	cs.shadow_size = 30; cs.shadow_color = Color(0.13, 0.08, 0.05, 0.10)
	cs.border_width_top = 3; cs.border_width_left = 1
	cs.border_width_right = 1; cs.border_width_bottom = 1
	card.add_theme_stylebox_override("panel", cs)

	(cvbox.get_child(0) as Label).add_theme_color_override("font_color", Color(0.13, 0.08, 0.05, 1.0))
	(cvbox.get_child(1) as Label).add_theme_color_override("font_color", Color(0.43, 0.38, 0.33, 1.0))
	(cvbox.get_node(pct_name) as Label).add_theme_color_override("font_color", Color(0.55, 0.50, 0.45, 1.0))

	var pb  := cvbox.get_node(bar_name) as ProgressBar
	var pf  := StyleBoxFlat.new()
	pf.bg_color = accent
	pf.corner_radius_top_left = 3; pf.corner_radius_top_right    = 3
	pf.corner_radius_bottom_left = 3; pf.corner_radius_bottom_right = 3
	pf.shadow_size = 8; pf.shadow_color = Color(accent.r, accent.g, accent.b, 0.35)
	var pbg := StyleBoxFlat.new()
	pbg.bg_color = Color(0.13, 0.08, 0.05, 0.07)
	pbg.corner_radius_top_left = 3; pbg.corner_radius_top_right    = 3
	pbg.corner_radius_bottom_left = 3; pbg.corner_radius_bottom_right = 3
	pb.add_theme_stylebox_override("fill",       pf)
	pb.add_theme_stylebox_override("background", pbg)

	var btn := cvbox.get_node(btn_name) as Button
	var bn  := _flat(btn_col, Color(1, 1, 1, 0.15), 28)
	bn.shadow_size = 12; bn.shadow_color = Color(btn_col.r, btn_col.g, btn_col.b, 0.25)
	var bh  := _flat(btn_col.lightened(0.15), Color(1, 1, 1, 0.28), 28)
	bh.shadow_size = 18; bh.shadow_color = Color(btn_col.r, btn_col.g, btn_col.b, 0.38)
	btn.add_theme_stylebox_override("normal",  bn)
	btn.add_theme_stylebox_override("hover",   bh)
	btn.add_theme_stylebox_override("pressed", DS.flat(btn_col.darkened(0.15), Color.TRANSPARENT, DS.R_MD, 0))
	btn.add_theme_stylebox_override("focus",   DS.no_style())
	btn.add_theme_color_override("font_color",         DS.C_CREAM)
	btn.add_theme_color_override("font_hover_color",   DS.C_CREAM)
	btn.add_theme_color_override("font_pressed_color", DS.C_CREAM)

func _style_card_locked(card: PanelContainer, cvbox: VBoxContainer, btn_name: String) -> void:
	var cs := _flat(Color(0.95, 0.93, 0.89, 0.65), Color(0.13, 0.08, 0.05, 0.08), 24)
	cs.shadow_size = 10; cs.shadow_color = Color(0.13, 0.08, 0.05, 0.05)
	cs.border_width_top = 1; cs.border_width_left = 1
	cs.border_width_right = 1; cs.border_width_bottom = 1
	card.add_theme_stylebox_override("panel", cs)
	card.modulate.a = 0.68

	for child in cvbox.get_children():
		if child is Label:
			(child as Label).add_theme_color_override("font_color", Color(0.43, 0.38, 0.33, 0.50))

	var btn := cvbox.get_node(btn_name) as Button
	btn.add_theme_stylebox_override("normal",   _flat(Color(0,0,0,0.03), Color(0.13, 0.08, 0.05, 0.10), 28))
	btn.add_theme_stylebox_override("disabled", _flat(Color(0,0,0,0.01), Color(0.13, 0.08, 0.05, 0.05), 28))
	btn.add_theme_color_override("font_color",          Color(0.13, 0.08, 0.05, 0.35))
	btn.add_theme_color_override("font_disabled_color", Color(0.13, 0.08, 0.05, 0.25))

func _update_card_ui(card: PanelContainer, cvbox: VBoxContainer, progress: float, is_unlocked: bool, accent: Color, btn_col: Color, bar_name: String, btn_name: String, pct_name: String, default_btn_text: String) -> void:
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
		_style_card(card, cvbox, Color(1.0, 1.0, 1.0, 0.95), Color(accent.r, accent.g, accent.b, 0.25), accent, btn_col, bar_name, btn_name, pct_name)
	else:
		btn.disabled = true
		btn.text = "Chưa mở khóa"
		_style_card_locked(card, cvbox, btn_name)

# ── Entrance animation ─────────────────────────────────────────────────────────

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
	var size = get_viewport().size
	var is_mobile = size.x < size.y or size.x < 768
	
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
<<<<<<< HEAD
	DS.fade_to(self, "res://scenes/LoginScreen.tscn")
=======
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
>>>>>>> origin/dat
