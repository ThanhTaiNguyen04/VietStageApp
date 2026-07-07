extends Control

## ─────────────────────────────────────────────────────────────────────────
##  DanBauBoard  —  Vietnamese Đàn Bầu (Monochord) 2.5D Renderer
##
##  Concept-sheet proportions  (reference sprite ≈ 512 × 180 px):
##    • Body width  : height  ≈  5.5 : 1
##    • Gourd ø     : body-H  ≈  0.60
##    • Soundboard  : body-H  ≈  0.28  (light oak, top strip)
##    • Front panel : body-H  ≈  0.72  (dark walnut, main face)
##    • Bamboo rod rises ≈ 1.6× body-H above body top
##
##  ALL sizes are derived from BW (body width), never from canvas H.
##  This keeps proportions correct on any canvas aspect ratio.
##
##  Layout (left → right):
##    ① Bầu cộng hưởng (round brown gourd) + Cần đàn (bamboo rod)
##    ② Oak soundboard + walnut front panel with floral inlay
##    ③ 7 harmonic nodes along the string
##    ④ Chốt dây (tuning peg)
## ─────────────────────────────────────────────────────────────────────────

signal string_plucked(idx: int, note_name: String)
signal pitch_bent(cents_offset: float)

const NODE_COUNT := 7
const NOTES_VN : Array[String] = ["Đô", "Rê", "Mi", "Fa", "Sol", "La", "Si"]

# ── Colour palette (matches concept-sheet swatches) ───────────────────────
const C_OAK_HI    := Color("#f0d478")   # soundboard highlight
const C_OAK_MID   := Color("#c89840")   # soundboard base
const C_OAK_SHD   := Color("#8c6420")   # soundboard shadow edge
const C_WAL_HI    := Color("#5c3018")   # walnut highlight edge
const C_WAL_MID   := Color("#321808")   # walnut main
const C_WAL_DRK   := Color("#180a02")   # walnut deep shadow
const C_GOURD_HI  := Color("#9a6030")   # gourd highlight
const C_GOURD_MID := Color("#5a3010")   # gourd base
const C_GOURD_DRK := Color("#280e04")   # gourd shadow
const C_BAM_HI    := Color("#b0a058")   # bamboo highlight
const C_BAM_MID   := Color("#786830")   # bamboo base
const C_BAM_DRK   := Color("#4a4018")   # bamboo shadow/knot
const C_GOLD      := Color("#c89830")   # gold trim / inlay
const C_GOLD_HI   := Color("#f0d070")   # gold highlight
const C_GOLD_DRK  := Color("#785808")   # gold shadow
const C_STR       := Color("#c0c4d0")   # steel string
const C_STR_GLOW  := Color("#f8ee98")   # string vibration

# ── Runtime state ─────────────────────────────────────────────────────────
var _note_names : Array[String]      = []
var _streams    : Array              = []
var _freqs      : Array[float]       = []
var _pluck_amp   := 0.0
var _pluck_time  := 0.0
var _glow        : PackedFloat32Array = PackedFloat32Array()
var _pulse       := 0.0
var _is_tgt      : PackedByteArray    = PackedByteArray()
var _is_bending  := false
var _bend_px     := 0.0      # rod-tip vertical offset in pixels
var _bend_cts    := 0.0      # in cents
var _bend_vel    := 0.0
var _hov         := -1
var _tgt_idx     := 0
# Cached per-frame for input hit-testing
var _str_y       := 0.0
var _node_xs     : PackedFloat32Array = PackedFloat32Array()
var _bend_zone_x := 0.0      # everything left of this X = bend zone

# ── Public API ────────────────────────────────────────────────────────────
func init(notes: Array[String], streams: Array, freqs: Array[float]) -> void:
	_note_names = notes; _streams = streams; _freqs = freqs
	_glow.resize(NODE_COUNT); _is_tgt.resize(NODE_COUNT)
	for i in NODE_COUNT: _glow[i] = 0.0; _is_tgt[i] = 0
	queue_redraw()

func _ready() -> void:
	resized.connect(queue_redraw)
	mouse_filter = MOUSE_FILTER_STOP
	queue_redraw()

func set_target(idx: int) -> void:
	_tgt_idx = idx
	for i in NODE_COUNT: _is_tgt[i] = 1 if i == idx else 0
	queue_redraw()

func pluck(idx: int) -> void:
	if idx < 0 or idx >= NODE_COUNT: return
	_pluck_time = 0.0; _pluck_amp = 1.0; _glow[idx] = 1.0
	string_plucked.emit(idx, _note_names[idx] if idx < _note_names.size() else NOTES_VN[idx])
	queue_redraw()

func _process(delta: float) -> void:
	var dirty := false
	if _pluck_amp > 0.0:
		_pluck_time += delta
		_pluck_amp   = maxf(0.0, _pluck_amp - delta * 2.2)
		dirty = true
	for i in NODE_COUNT:
		if _glow[i] > 0.0:
			_glow[i] = maxf(0.0, _glow[i] - delta * 2.8)
			dirty = true
	_pulse += delta * 3.4; dirty = true
	if not _is_bending and (_bend_px != 0.0 or _bend_vel != 0.0):
		var a := -380.0 * _bend_px - 13.0 * _bend_vel
		_bend_vel += a * delta; _bend_px += _bend_vel * delta
		if abs(_bend_px) < 0.08 and abs(_bend_vel) < 0.08:
			_bend_px = 0.0; _bend_vel = 0.0; _bend_cts = 0.0
			pitch_bent.emit(0.0)
		else:
			_bend_cts = clampf(_bend_px / _max_bend() * 350.0, -400.0, 400.0)
			pitch_bent.emit(_bend_cts)
		dirty = true
	if dirty: queue_redraw()

func _max_bend() -> float:
	return maxf(size.x * 0.81 * 0.175 * 0.12, 8.0)

# ══════════════════════════════════════════════════════════════════════════
#  DRAW
# ══════════════════════════════════════════════════════════════════════════
func _draw() -> void:
	var W := size.x; var H := size.y
	if W < 120.0 or H < 40.0: return

	# ── Geometry (ALL derived from BW) ───────────────────────────────────
	#   BL/BR = left/right edge of the wooden box body
	var BL  := W * 0.14
	var BR  := W * 0.97
	var BW  := BR - BL

	# Total body height from concept-sheet aspect (5.5 : 1)
	var BH  := BW / 5.5      # e.g. BW=830 → BH=151 px
	# Soundboard (oak, top strip) = 28 % of body height
	var SBH := BH * 0.28
	# Vertical placement: body centred at 62 % of canvas height
	var BCY := H * 0.62      # body-centre Y
	var BT  := BCY - BH * 0.5   # body top
	var BB  := BCY + BH * 0.5   # body bottom
	var SBT := BT              # soundboard top
	var SBB := BT + SBH        # soundboard bottom (= front-panel top)
	var FPB := BB              # front-panel bottom

	# String: horizontal, sits 55 % into soundboard
	var SY  := SBT + SBH * 0.55
	_str_y  = SY

	# Gourd: radius = 29 % of BH so diameter ≈ 58 % of body height
	var GR  := BH * 0.52
	# Gourd centre: mostly LEFT of body (overlaps body left edge by 15 % GR)
	var GX  := BL - GR * 0.85
	var GY  := BCY              # vertically centred on body

	# Bamboo rod: from top of gourd, curves up-right, stays in canvas
	var RB  := Vector2(GX + GR * 0.15, GY - GR * 0.80)  # rod base
	var RT_y := maxf(H * 0.04, BT - BH * 1.50 + _bend_px)
	var RT  := Vector2(GX + BW * 0.045, RT_y)              # rod tip
	var RC1 := Vector2(GX + GR * 0.40, RB.y - BH * 0.65)
	var RC2 := Vector2(RT.x - GR * 0.30, RT.y  + BH * 0.40)

	# Nodes: 7 equally spaced, clear of gourd
	var N0  := BL + BW * 0.03
	var N1  := BR - BW * 0.02
	var NST := (N1 - N0) / float(NODE_COUNT - 1)
	_node_xs.resize(NODE_COUNT)
	for i in NODE_COUNT: _node_xs[i] = N0 + float(i) * NST

	# String endpoints (horizontal)
	var SS := Vector2(GX + GR * 0.60, SY)   # at gourd right surface
	var SE := Vector2(BR - 5.0, SY)          # at tuning peg

	# Bend zone = everything left of the body (gourd area)
	_bend_zone_x = BL + BW * 0.05

	# ── Draw order ───────────────────────────────────────────────────────
	_d_shadow(BL, BR, BB)
	_d_feet(BL, BR, BB, BH)
	_d_front_panel(BL, BR, SBB, FPB)
	_d_soundboard(BL, BR, SBT, SBB)
	_d_side_caps(BL, BR, SBT, FPB)
	_d_gold_trim(BL, BR, SBT, SBB, FPB)
	_d_floral(BL, BW, SBT, SBB)
	_d_bridge(BL + BW * 0.50, SY, SBB)
	_d_string(SS, SE)
	_d_nodes(SY)
	_d_gourd(GX, GY, GR)
	_d_bamboo(RB, RT, RC1, RC2, GR)
	_d_peg(BR, SY, SBT, SBB)
	if _is_bending:
		var f := get_theme_font("font")
		if f: _d_cents(f, RT + Vector2(18.0, 0.0), _bend_cts)

# ══════════════════════════════════════════════════════════════════════════
#  SHADOW + FEET
# ══════════════════════════════════════════════════════════════════════════
func _d_shadow(BL: float, BR: float, BB: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(BL - 12, BB + 3),  Vector2(BR + 14, BB + 3),
		Vector2(BR + 6,  BB + 12), Vector2(BL - 5,  BB + 12)
	]), Color(0, 0, 0, 0.22))

func _d_feet(BL: float, BR: float, BB: float, BH: float) -> void:
	var FW : float = BH * 0.22
	var FH : float = BH * 0.09
	var pos : Array[float] = [0.12, 0.50, 0.88]
	for p in pos:
		var fx : float = BL + (BR - BL) * p
		draw_colored_polygon(PackedVector2Array([
			Vector2(fx - FW * 0.50, BB),       Vector2(fx + FW * 0.50, BB),
			Vector2(fx + FW * 0.42, BB + FH),  Vector2(fx - FW * 0.42, BB + FH)
		]), C_WAL_DRK)
		draw_line(Vector2(fx - FW*0.50, BB), Vector2(fx + FW*0.50, BB),
				  Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.40), 0.9)

# ══════════════════════════════════════════════════════════════════════════
#  BODY FACES
# ══════════════════════════════════════════════════════════════════════════
func _d_front_panel(BL: float, BR: float, TOP: float, BOT: float) -> void:
	# Dark walnut — gradient: slightly lighter at very top bevel, darkens down
	var H2 := BOT - TOP
	for i in 16:
		var r1 : float = float(i)      / 16.0
		var r2 : float = float(i + 1)  / 16.0
		var y1 := lerpf(TOP, BOT, r1)
		var y2 := lerpf(TOP, BOT, r2)
		var c  := C_WAL_MID
		if r1 < 0.10: c = c.lerp(C_WAL_HI,  (0.10 - r1) / 0.10 * 0.55)
		elif r1 > 0.72: c = c.lerp(C_WAL_DRK, (r1 - 0.72) / 0.28 * 0.65)
		draw_colored_polygon(PackedVector2Array([
			Vector2(BL, y1), Vector2(BR, y1), Vector2(BR, y2), Vector2(BL, y2)
		]), c)
	# Wood grain
	var rng := RandomNumberGenerator.new(); rng.seed = 55443
	for _j in 5:
		var f   : float = rng.randf()
		var gy  : float = lerpf(TOP + H2*0.08, BOT - H2*0.08, f)
		var pts := PackedVector2Array()
		for k in 18:
			var t  : float = float(k) / 17.0
			pts.append(Vector2(lerpf(BL+8, BR-8, t), gy + sin(t*8.0+f*4.5)*0.8))
		var gc := C_WAL_DRK.lerp(C_WAL_MID, f * 0.4)
		gc.a    = rng.randf_range(0.05, 0.12)
		draw_polyline(pts, gc, 0.6, true)

func _d_soundboard(BL: float, BR: float, TOP: float, BOT: float) -> void:
	# Light oak — cylindrical shading + wood grain
	for i in 18:
		var r1 : float = float(i)      / 18.0
		var r2 : float = float(i + 1)  / 18.0
		var y1 := lerpf(TOP, BOT, r1)
		var y2 := lerpf(TOP, BOT, r2)
		var lt := sin(r1 * PI)
		var c  := C_OAK_MID.lerp(C_OAK_HI, lt * 0.72)
		if r1 < 0.09:  c = c.lerp(C_WAL_DRK, (0.09 - r1) / 0.09 * 0.55)
		elif r1 > 0.80: c = c.lerp(C_OAK_SHD, (r1 - 0.80) / 0.20 * 0.45)
		draw_colored_polygon(PackedVector2Array([
			Vector2(BL, y1), Vector2(BR, y1), Vector2(BR, y2), Vector2(BL, y2)
		]), c)
	var rng := RandomNumberGenerator.new(); rng.seed = 99123
	for _j in 10:
		var f   : float = rng.randf()
		var gy  : float = lerpf(TOP + 2.0, BOT - 2.0, f)
		var pts := PackedVector2Array()
		for k in 22:
			var t  : float = float(k) / 21.0
			pts.append(Vector2(lerpf(BL+4, BR-4, t), gy + sin(t*12.0+f*6.0)*1.0+cos(t*4.0)*0.5))
		var gc := C_OAK_SHD.lerp(C_OAK_MID, f)
		gc.a    = rng.randf_range(0.06, 0.18)
		draw_polyline(pts, gc, rng.randf_range(0.4, 1.0), true)

func _d_side_caps(BL: float, BR: float, TOP: float, BOT: float) -> void:
	var d := 5.0
	# Left bevel
	draw_colored_polygon(PackedVector2Array([
		Vector2(BL-d, TOP+d*0.4), Vector2(BL, TOP),
		Vector2(BL, BOT),         Vector2(BL-d, BOT-d*0.4)
	]), C_WAL_DRK)
	# Right bevel
	draw_colored_polygon(PackedVector2Array([
		Vector2(BR, TOP),         Vector2(BR+d, TOP+d*0.4),
		Vector2(BR+d, BOT-d*0.4), Vector2(BR, BOT)
	]), C_WAL_DRK)

# ══════════════════════════════════════════════════════════════════════════
#  GOLD TRIM + RIVETS + FLORAL INLAY
# ══════════════════════════════════════════════════════════════════════════
func _d_gold_trim(BL: float, BR: float, SBT: float, SBB: float, FPB: float) -> void:
	var g  := Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.90)
	var gd := Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45)
	draw_line(Vector2(BL, SBT), Vector2(BR, SBT), g,  1.5)
	draw_line(Vector2(BL, SBB), Vector2(BR, SBB), g,  1.2)
	draw_line(Vector2(BL, FPB), Vector2(BR, FPB), gd, 0.9)
	# Inner frame on soundboard
	var si := (SBB - SBT) * 0.14
	draw_polyline(PackedVector2Array([
		Vector2(BL+12, SBT+si), Vector2(BR-12, SBT+si),
		Vector2(BR-12, SBB-si), Vector2(BL+12, SBB-si), Vector2(BL+12, SBT+si)
	]), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35), 0.7, true)
	# Inner frame on front panel
	var fi := (FPB - SBB) * 0.10
	draw_polyline(PackedVector2Array([
		Vector2(BL+10, SBB+fi), Vector2(BR-10, SBB+fi),
		Vector2(BR-10, FPB-fi), Vector2(BL+10, FPB-fi), Vector2(BL+10, SBB+fi)
	]), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.30), 0.7, true)
	# Rivets at 4 corners
	var rs := minf((SBB - SBT) * 0.48, 13.0)
	_rivet(Vector2(BL, SBT), rs, false, false)
	_rivet(Vector2(BR, SBT), rs, true,  false)
	_rivet(Vector2(BL, FPB), rs, false, true)
	_rivet(Vector2(BR, FPB), rs, true,  true)

func _rivet(p: Vector2, s: float, fx: bool, fy: bool) -> void:
	var sx := -1.0 if fx else 1.0; var sy := -1.0 if fy else 1.0
	draw_colored_polygon(PackedVector2Array([
		p, p+Vector2(sx*s,0.0), p+Vector2(sx*s*0.55,sy*s*0.55), p+Vector2(0.0,sy*s)
	]), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.72))
	var r := p + Vector2(sx*s*0.35, sy*s*0.35)
	draw_circle(r, 1.7, Color(0.10,0.05,0.0,0.92))
	draw_circle(r, 0.7, Color(1.0,0.95,0.7,0.50))

func _d_floral(BL: float, BW: float, SBT: float, SBB: float) -> void:
	# Gold inlay on oak soundboard — lotus + vines (matches concept)
	var cy  : float = (SBT + SBB) * 0.50
	var r   : float = (SBB - SBT) * 0.38
	var gc  := Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.54)
	var gc2 := Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.34)
	_lotus(BL + BW*0.50, cy, r, gc)
	_lotus(BL + BW*0.22, cy, r*0.58, gc2)
	_lotus(BL + BW*0.78, cy, r*0.58, gc2)
	_vine(BL+BW*0.09, BL+BW*0.44, cy, r*0.44, gc2)
	_vine(BL+BW*0.56, BL+BW*0.91, cy, r*0.44, gc2)

func _lotus(cx: float, cy: float, r: float, c: Color) -> void:
	draw_circle(Vector2(cx,cy), r*0.20, c)
	draw_circle(Vector2(cx,cy), r*0.10, Color(c.r,c.g,c.b,1.0))
	for pi in 6:
		var a := deg_to_rad(float(pi)*60.0)
		draw_circle(Vector2(cx+cos(a)*r*0.38, cy+sin(a)*r*0.38), r*0.13, Color(c.r,c.g,c.b,c.a*0.76))
	draw_arc(Vector2(cx,cy), r*0.53, 0.0, TAU, 20, Color(c.r,c.g,c.b,c.a*0.45), 0.7)

func _vine(x0: float, x1: float, cy: float, amp: float, c: Color) -> void:
	var pts := PackedVector2Array()
	for k in 21:
		var t : float = float(k) / 20.0
		pts.append(Vector2(lerpf(x0,x1,t), cy + sin(t*TAU*1.5)*amp))
	draw_polyline(pts, c, 0.9, true)
	for k in range(0,21,4):
		var t : float = float(k) / 20.0
		draw_circle(Vector2(lerpf(x0,x1,t), cy+sin(t*TAU*1.5)*amp),
					amp*0.12, Color(c.r,c.g,c.b,c.a*0.70))

func _d_bridge(bx: float, sy: float, sb_bot: float) -> void:
	# Tiny ngựa đàn — minimal, does not dominate
	var bw : float = size.x * 0.007
	var bh : float = (sb_bot - sy) * 0.65
	draw_colored_polygon(PackedVector2Array([
		Vector2(bx-bw, sy), Vector2(bx+bw, sy),
		Vector2(bx+bw*0.65, sy+bh), Vector2(bx-bw*0.65, sy+bh)
	]), C_WAL_MID)
	draw_line(Vector2(bx-bw,sy),Vector2(bx+bw,sy), Color(C_GOLD.r,C_GOLD.g,C_GOLD.b,0.55),0.9)

# ══════════════════════════════════════════════════════════════════════════
#  STRING
# ══════════════════════════════════════════════════════════════════════════
func _d_string(ss: Vector2, se: Vector2) -> void:
	# Build wave points (vibration when plucked)
	var pts := PackedVector2Array()
	pts.append(ss)
	if _pluck_amp > 0.005:
		for k in range(1, 36):
			var t   : float = float(k) / 36.0
			var px  : float = lerpf(ss.x, se.x, t)
			var py  : float = lerpf(ss.y, se.y, t)   # horizontal → same Y
			var osc : float = sin(t*PI)*sin(t*PI*5.0 - _pluck_time*88.0) * _pluck_amp * 6.0 * exp(-_pluck_time*1.8)
			pts.append(Vector2(px, py + osc))
	pts.append(se)
	# Shadow
	var shd := PackedVector2Array()
	for p in pts: shd.append(p + Vector2(0.0, 2.5))
	draw_polyline(shd, Color(0,0,0,0.28), 1.1, true)
	# Glow
	if _pluck_amp > 0.01:
		draw_polyline(pts, Color(C_STR_GLOW.r,C_STR_GLOW.g,C_STR_GLOW.b,_pluck_amp*0.55), 4.5, true)
	# Core
	var sc := C_STR_GLOW if _pluck_amp > 0.12 else C_STR
	if _is_bending: sc = Color("#fc8820")
	draw_polyline(pts, sc, 1.5, true)

# ══════════════════════════════════════════════════════════════════════════
#  HARMONIC NODES
# ══════════════════════════════════════════════════════════════════════════
func _d_nodes(sy: float) -> void:
	var font := get_theme_font("font")
	for i in NODE_COUNT:
		_d_node(Vector2(_node_xs[i], sy), i, _is_tgt[i]==1, _hov==i, _glow[i], font)

func _d_node(pos: Vector2, idx: int, tgt: bool, hov: bool, glow: float, font: Font) -> void:
	draw_circle(pos+Vector2(0,2.5), 11.5, Color(0,0,0,0.28))
	if tgt:
		var p := (sin(_pulse*2.0)+1.0)*0.5
		draw_circle(pos, 15.5+p*5.0, Color(0.78,0.60,0.18,0.12+p*0.12))
		draw_arc(pos, 15.5+p*5.0, 0.0, TAU, 28, Color(0.78,0.60,0.18,0.36+p*0.24), 1.2)
	if glow > 0.01:
		draw_circle(pos, 11.0+glow*20.0, Color(1.0,0.96,0.76,glow*0.44))
		draw_arc(pos,   11.0+glow*20.0, 0.0, TAU, 24, Color(1.0,0.90,0.50,glow*0.54), 1.4)
	var R : float = 9.0 + (1.5 if hov else (1.0 if tgt else 0.0))
	draw_circle(pos, R,        C_GOLD)
	draw_circle(pos, R-1.5,    Color("#faf5e4"))
	draw_circle(pos, R-4.0,    C_GOLD)
	draw_circle(pos, R-6.0,    C_WAL_DRK)
	draw_circle(pos, 1.1,      Color(1,1,1,0.82))
	if font == null: return
	var text := _note_names[idx] if idx < _note_names.size() else NOTES_VN[idx]
	var fsz  := 13 if (tgt or hov) else 11
	var tc   := (Color("#faf6e8") if tgt else (Color.WHITE if hov else Color("#c0a878")))
	var ts   := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, fsz)
	var tp   := Vector2(pos.x - ts.x*0.5, pos.y - R - 6.0)
	draw_string(font, tp+Vector2(1,1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, Color(0,0,0,0.70))
	draw_string(font, tp,             text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, tc)

# ══════════════════════════════════════════════════════════════════════════
#  GOURD  (Bầu cộng hưởng)
# ══════════════════════════════════════════════════════════════════════════
func _d_gourd(gx: float, gy: float, gr: float) -> void:
	# Drop shadow
	draw_circle(Vector2(gx+3.5, gy+5.5), gr+3.0, Color(0,0,0,0.30))
	# 3-D sphere gradient (dark brown lacquer)
	for i in 22:
		var rr : float = float(22-i) / 22.0
		var r  : float = gr * rr
		var o  := Vector2(-0.7,-0.7)*(1.0-rr)
		var c  := C_GOURD_DRK.lerp(C_GOURD_HI, rr*0.82)
		if rr > 0.80: c = c.lerp(Color("#c07028"), (rr-0.80)/0.20*0.55)
		draw_circle(Vector2(gx,gy)+o, r, c)
	# Specular
	draw_circle(Vector2(gx-gr*0.28, gy-gr*0.30), gr*0.13, Color(1,1,1,0.72))
	draw_circle(Vector2(gx-gr*0.17, gy-gr*0.18), gr*0.06, Color(1,1,1,0.50))
	# Carved rings
	draw_arc(Vector2(gx,gy), gr*0.72, 0.0, TAU, 28, Color(C_GOURD_DRK.r,C_GOURD_DRK.g,C_GOURD_DRK.b,0.45), 1.0)
	draw_arc(Vector2(gx,gy), gr*0.52, 0.0, TAU, 22, Color(C_GOURD_DRK.r,C_GOURD_DRK.g,C_GOURD_DRK.b,0.30), 0.7)
	# Floral dots
	for fi in 4:
		var a := deg_to_rad(float(fi)*90.0+45.0)
		draw_circle(Vector2(gx+cos(a)*gr*0.58, gy+sin(a)*gr*0.58), gr*0.055,
					Color(C_GOURD_HI.r,C_GOURD_HI.g,C_GOURD_HI.b,0.55))
	# Brass collar at body attachment point
	var cy2 := gy + gr*0.68
	for ci in 6:
		var rr : float = float(6-ci)/6.0
		draw_circle(Vector2(gx,cy2)+Vector2(-rr,-rr)*0.3, gr*0.20*rr, C_GOLD_DRK.lerp(C_GOLD,rr))
	draw_circle(Vector2(gx-gr*0.07, cy2-gr*0.07), gr*0.07, Color(1,1,1,0.45))

# ══════════════════════════════════════════════════════════════════════════
#  BAMBOO ROD  (Cần đàn)
# ══════════════════════════════════════════════════════════════════════════
func _d_bamboo(rb: Vector2, rt: Vector2, c1: Vector2, c2: Vector2, gr: float) -> void:
	var SEG := 28
	var pts := PackedVector2Array()
	for k in SEG+1:
		pts.append(_cbez(rb, c1, c2, rt, float(k)/float(SEG)))
	# Shadow
	var shd := PackedVector2Array()
	for p in pts: shd.append(p+Vector2(2.5,3.5))
	for k in SEG:
		draw_line(shd[k], shd[k+1], Color(0,0,0,0.18), lerpf(6.0,1.5,float(k)/float(SEG)),true)
	# Rod
	for k in SEG:
		var t  : float = float(k)/float(SEG)
		var th : float = lerpf(6.0, 1.5, t)
		var c  := C_BAM_DRK.lerp(C_BAM_MID, 0.40+0.30*sin(t*PI))
		draw_line(pts[k], pts[k+1], c, th, true)
		if k == 0: draw_circle(pts[k], th*0.5, c)
	# Bamboo knots
	for kp in [0.25, 0.52, 0.76]:
		var ki := int(kp*float(SEG))
		var t  : float = kp
		var th : float = lerpf(6.0, 1.5, t)
		if ki < pts.size():
			draw_circle(pts[ki], th*0.70, C_BAM_DRK)
			draw_circle(pts[ki], th*0.52, C_BAM_MID)
			draw_circle(pts[ki]+Vector2(-th*0.13,-th*0.13), th*0.17, Color(1,1,1,0.28))
	# Specular
	for k in SEG:
		var t  : float = float(k)/float(SEG)
		var th : float = lerpf(6.0, 1.5, t)
		draw_line(pts[k]+Vector2(-th*0.16,-th*0.16), pts[k+1]+Vector2(-th*0.16,-th*0.16),
				  Color(C_BAM_HI.r,C_BAM_HI.g,C_BAM_HI.b,0.26*(1.0-t*0.6)), th*0.18, true)
	draw_circle(rt, 1.4, C_BAM_DRK)
	# Gold collar at base
	draw_arc(rb, gr*0.16, 0.0, TAU, 12, Color(C_GOLD.r,C_GOLD.g,C_GOLD.b,0.65), 1.4)
	draw_arc(rb-Vector2(0,gr*0.05), gr*0.12, 0.0, TAU, 10, Color(C_GOLD.r,C_GOLD.g,C_GOLD.b,0.48), 1.1)

# ══════════════════════════════════════════════════════════════════════════
#  TUNING PEG  (Chốt dây) — right end
# ══════════════════════════════════════════════════════════════════════════
func _d_peg(BR: float, sy: float, sbt: float, sbb: float) -> void:
	var px  : float = BR - 4.0
	var ph  : float = (sbb - sbt) * 0.60
	draw_colored_polygon(PackedVector2Array([
		Vector2(px-7, sy-4.5), Vector2(px+2.5, sy-4.5),
		Vector2(px+2.5, sy+4.5), Vector2(px-7, sy+4.5)
	]), C_WAL_MID)
	draw_line(Vector2(px-2.0, sy-ph*0.30), Vector2(px-2.0, sy-ph-3.0), Color("#484030"), 3.5)
	draw_line(Vector2(px-2.0, sy-ph*0.30), Vector2(px-2.0, sy-ph-3.0), Color("#706050"), 1.4)
	var kc := Vector2(px-2.0, sy-ph-3.0)
	for ci in 10:
		var rr : float = float(10-ci)/10.0
		var c  := C_WAL_DRK.lerp(C_WAL_MID, rr*0.65)
		if rr > 0.78: c = c.lerp(C_WAL_HI, (rr-0.78)/0.22*0.55)
		draw_circle(kc+Vector2(-rr*0.5,-rr*0.5)*0.4, 5.0*rr, c)
	draw_circle(kc+Vector2(-1.4,-1.7), 1.2, Color(1,1,1,0.42))
	draw_arc(Vector2(px-2.0, sy), 5.0, 0.0, TAU, 14, Color(C_GOLD.r,C_GOLD.g,C_GOLD.b,0.68), 1.2)

# ══════════════════════════════════════════════════════════════════════════
#  CENTS BADGE
# ══════════════════════════════════════════════════════════════════════════
func _d_cents(font: Font, pos: Vector2, cents: float) -> void:
	var txt := ("%s%d ¢") % ["+" if cents > 0 else "", int(cents)]
	var col := C_GOLD
	if cents >  5.0: col = Color("#28cc70")
	elif cents < -5.0: col = Color("#e43c3c")
	var ts := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 13)
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(0.06,0.03,0.01,0.90)
	bs.border_color = Color(col.r,col.g,col.b,0.55)
	bs.border_width_left=1; bs.border_width_right=1
	bs.border_width_top=1;  bs.border_width_bottom=1
	bs.corner_radius_top_left=7; bs.corner_radius_top_right=7
	bs.corner_radius_bottom_left=7; bs.corner_radius_bottom_right=7
	draw_style_box(bs, Rect2(pos.x-ts.x*0.5-7, pos.y-ts.y*0.5-2, ts.x+14, ts.y+4))
	draw_string(font, pos+Vector2(-ts.x*0.5, ts.y*0.5-2), txt, HORIZONTAL_ALIGNMENT_LEFT,-1,13,col)

func _cbez(p0:Vector2,p1:Vector2,p2:Vector2,p3:Vector2,t:float)->Vector2:
	var u:=1.0-t; return u*u*u*p0+3.0*u*u*t*p1+3.0*u*t*t*p2+t*t*t*p3

# ══════════════════════════════════════════════════════════════════════════
#  INPUT
# ══════════════════════════════════════════════════════════════════════════
func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		var e := ev as InputEventMouseButton
		if e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed: _on_press(e.position)
			else:         _on_release()
	elif ev is InputEventMouseMotion:
		_on_move((ev as InputEventMouseMotion).position)
	elif ev is InputEventScreenTouch:
		var e := ev as InputEventScreenTouch
		if e.pressed: _on_press(e.position)
		else:         _on_release()
	elif ev is InputEventScreenDrag:
		_on_move((ev as InputEventScreenDrag).position)

func _on_press(pos: Vector2) -> void:
	if pos.x < _bend_zone_x:
		_is_bending = true; _do_bend(pos.y)
	else:
		var ni := _node_at(pos)
		if ni >= 0: pluck(ni)

func _on_move(pos: Vector2) -> void:
	if _is_bending: _do_bend(pos.y)
	else:
		var ni := _node_at(pos)
		if ni != _hov: _hov = ni; queue_redraw()

func _on_release() -> void:
	_is_bending = false; _hov = -1; queue_redraw()

func _node_at(pos: Vector2) -> int:
	if _node_xs.size() < NODE_COUNT: return -1
	for i in NODE_COUNT:
		if pos.distance_to(Vector2(_node_xs[i], _str_y)) <= 28.0: return i
	return -1

func _do_bend(ty: float) -> void:
	var BW    : float = size.x * 0.83
	var BH    : float = BW / 5.5
	var BCY   : float = size.y * 0.62
	var BT    : float = BCY - BH * 0.5
	var GR    : float = BH * 0.52
	var GY    : float = BCY
	var RB_y  : float = GY - GR * 0.80
	var rest_y: float = RB_y    # rod base = natural rest Y of rod
	var max_d : float = _max_bend()
	_bend_px  = clampf(ty - rest_y, -max_d, max_d)
	_bend_vel = 0.0
	_bend_cts = (_bend_px / max_d) * 350.0
	pitch_bent.emit(_bend_cts)
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_hov = -1
		if _is_bending: _on_release()
		queue_redraw()
