extends Control

## ─────────────────────────────────────────────────────────────────────────
##  DanBauBoard  —  Vietnamese Đàn Bầu (Monochord) 2.5D Renderer
##
##  Designed to match the hand-painted 2D game asset concept sheet:
##    • Perfect side-view orientation:
##      - LEFT end: Tuning peg (chốt dây), bridge (ngựa đàn), string start.
##      - RIGHT end: Gourd resonator (bầu cộng hưởng), bamboo rod (cần đàn).
##    • Slender zither body ratio:
##      - Body width : height ≈ 14 : 1 (slender, elegant, NOT thick like a bench)
##      - Soundboard (top face): Light oak with gold floral lotus engravings.
##      - Front face: Dark walnut wood with gold borders and detailing.
##      - 3 small feet at the bottom supporting the body.
##    • Animation support:
##      - Bamboo rod rotates/bends dynamically when dragging Y-axis on the right.
##      - Steel string vibrates organically when plucked.
##      - The main zither body remains static.
##    • Proportional scaling: All sizes are derived from body width (BW),
##      ensuring correct proportions on any canvas size.
## ─────────────────────────────────────────────────────────────────────────

signal string_plucked(idx: int, note_name: String)
signal pitch_bent(cents_offset: float)

const NODE_COUNT := 7
const NOTES_VN : Array[String] = ["Đô", "Rê", "Mi", "Fa", "Sol", "La", "Si"]

# ── Colour Palette (Concept Art Swatches) ─────────────────────────────────
const C_OAK_HI     := Color("#f2da84")   # Soundboard highlight
const C_OAK_MID    := Color("#cb9b44")   # Soundboard base oak
const C_OAK_SHD    := Color("#906622")   # Soundboard shadow edge
const C_WAL_HI     := Color("#62341c")   # Walnut highlight
const C_WAL_MID    := Color("#361b0a")   # Walnut main body
const C_WAL_DRK    := Color("#1c0b03")   # Walnut deep shadow
const C_GOURD_HI   := Color("#a26838")   # Gourd lacquer highlight
const C_GOURD_MID  := Color("#5e3212")   # Gourd base lacquer
const C_GOURD_DRK  := Color("#2b0f05")   # Gourd deep lacquer shadow
const C_BAM_HI     := Color("#b6a65c")   # Bamboo light nodes
const C_BAM_MID    := Color("#7a6b32")   # Bamboo stalk mid
const C_BAM_DRK    := Color("#4d421a")   # Bamboo joints / shadow
const C_GOLD       := Color("#cc9b32")   # Gold trim/inlay
const C_GOLD_HI    := Color("#f4d674")   # Gold light
const C_GOLD_DRK   := Color("#7c5b08")   # Gold dark
const C_STR        := Color("#c4c8d2")   # Steel string core
const C_STR_GLOW   := Color("#faf09e")   # String pluck vibration glow

# ── Runtime State ─────────────────────────────────────────────────────────
var _note_names : Array[String]      = []
var _streams    : Array              = []
var _freqs      : Array[float]       = []

var _pluck_amp   := 0.0
var _pluck_time  := 0.0
var _glow        : PackedFloat32Array = PackedFloat32Array()
var _pulse       := 0.0
var _is_tgt      : PackedByteArray    = PackedByteArray()

var _is_bending  := false
var _bend_px     := 0.0      # vertical offset of bamboo rod tip (pixels)
var _bend_cts    := 0.0      # pitch bend in cents
var _bend_vel    := 0.0
var _hov         := -1
var _tgt_idx     := 0

# Cached geometry for hit-testing and rendering
var _str_y       := 0.0
var _node_xs     : PackedFloat32Array = PackedFloat32Array()
var _bend_zone_x := 0.0      # everything to the right of this X is the bend zone

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
		var spring := 350.0
		var damp := 12.0
		var a := -spring * _bend_px - damp * _bend_vel
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
	# Proportional bend travel
	return maxf(size.y * 0.15, 12.0)

# ══════════════════════════════════════════════════════════════════════════
#  RENDER DRAWING
# ══════════════════════════════════════════════════════════════════════════
func _draw() -> void:
	var W := size.x; var H := size.y
	if W < 120.0 or H < 40.0: return

	# ── 1. Geometry Calculations (derived from Body Width for proportions)
	var BL  := W * 0.04       # Body left edge
	var BR  := W * 0.85       # Body right edge (leaves space for gourd and rod tip)
	var BW  := BR - BL

	# Aspect ratio of zither body is ~14 : 1 (slender zither box)
	var BH  := clampf(BW * 0.07, 34.0, 72.0)
	var SBH := BH * 0.28      # Soundboard (top oak face) is 28% of body height
	var FPH := BH * 0.72      # Front panel (walnut face) is 72% of body height

	# Vertical center of body on canvas
	var BCY := H * 0.62
	var BT  := BCY - BH * 0.5  # Body top
	var BB  := BCY + BH * 0.5  # Body bottom

	var SBT := BT
	var SBB := BT + SBH
	var FPB := BB

	# String height: runs horizontally, parallel to body, 7px above soundboard
	var SY  := SBT - BH * 0.12
	_str_y  = SY

	# Gourd resonator (bầu cộng hưởng): sitting on right end
	var GR  := BH * 0.50       # diameter is 100% of body height, fits perfectly
	var GX  := BR + GR * 0.40  # overlaps the right end of the body slightly
	var GY  := BCY             # centered vertically

	# Bamboo rod (cần đàn): emerges from gourd at right, curves up and left
	var RB   := Vector2(GX, GY - GR * 0.82)
	var RT_y := maxf(H * 0.05, BT - BH * 2.2 + _bend_px)
	var RT   := Vector2(GX - BW * 0.055, RT_y) # tip curves left, towards center
	var RC1  := Vector2(GX - GR * 0.35, RB.y - BH * 0.65)
	var RC2  := Vector2(RT.x + GR * 0.25, RT.y + BH * 0.40)

	# String endpoints
	var SS := Vector2(BL + BW * 0.08, SY)      # Starts at bridge on the left
	var SE := Vector2(GX - GR * 0.25, SY)      # Ends at bamboo rod on the right

	# Harmonic nodes spacing (clear of bridge and gourd)
	var N0  := BL + BW * 0.16
	var N1  := BR - BW * 0.10
	var NST := (N1 - N0) / float(NODE_COUNT - 1)
	_node_xs.resize(NODE_COUNT)
	for i in NODE_COUNT:
		_node_xs[i] = N0 + float(i) * NST

	# Pitch bend interaction zone: everything to the right of 82% of width
	_bend_zone_x = BR - BW * 0.08

	# ── 2. Render Stack (Layers stacked together)
	_d_shadow(BL, BR, BB)
	_d_feet(BL, BR, BB, BH)
	_d_front_panel(BL, BR, SBB, FPB)
	_d_soundboard(BL, BR, SBT, SBB)
	_d_side_caps(BL, BR, SBT, FPB)
	_d_gold_trim(BL, BR, SBT, SBB, FPB)
	_d_floral(BL, BW, SBT, SBB)
	_d_bridge(BL + BW * 0.08, SY, SBB)  # Bridge (ngựa đàn) at the LEFT end
	_d_string(SS, SE)
	_d_nodes(SY)
	_d_gourd(GX, GY, GR)
	_d_bamboo(RB, RT, RC1, RC2, GR)
	_d_peg(BL + 5.0, SY, SBT, SBB)     # Tuning peg (chốt dây) at the LEFT end
	if _is_bending:
		var f := get_theme_font("font")
		if f: _d_cents(f, RT + Vector2(18.0, 0.0), _bend_cts)

# ══════════════════════════════════════════════════════════════════════════
#  COMPONENT LAYERS
# ══════════════════════════════════════════════════════════════════════════

func _d_shadow(BL: float, BR: float, BB: float) -> void:
	# Ground shadow layer
	draw_colored_polygon(PackedVector2Array([
		Vector2(BL - 10, BB + 3),  Vector2(BR + 12, BB + 3),
		Vector2(BR + 4,  BB + 11), Vector2(BL - 4,  BB + 11)
	]), Color(0, 0, 0, 0.20))

func _d_feet(BL: float, BR: float, BB: float, BH: float) -> void:
	# Feet layer (3 small wooden supports visible under body)
	var FW : float = BH * 0.25
	var FH : float = BH * 0.08
	var pos : Array[float] = [0.12, 0.50, 0.88]
	for p in pos:
		var fx : float = BL + (BR - BL) * p
		draw_colored_polygon(PackedVector2Array([
			Vector2(fx - FW * 0.50, BB),       Vector2(fx + FW * 0.50, BB),
			Vector2(fx + FW * 0.40, BB + FH),  Vector2(fx - FW * 0.40, BB + FH)
		]), C_WAL_DRK)
		draw_line(Vector2(fx - FW*0.50, BB), Vector2(fx + FW*0.50, BB),
				  Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35), 0.8)

func _d_front_panel(BL: float, BR: float, TOP: float, BOT: float) -> void:
	# Dark walnut front panel with vertical shading gradient
	var H2 := BOT - TOP
	for i in 14:
		var r1 : float = float(i)      / 14.0
		var r2 : float = float(i + 1)  / 14.0
		var y1 := lerpf(TOP, BOT, r1)
		var y2 := lerpf(TOP, BOT, r2)
		var c  := C_WAL_MID
		if r1 < 0.12: c = c.lerp(C_WAL_HI,  (0.12 - r1) / 0.12 * 0.50)
		elif r1 > 0.70: c = c.lerp(C_WAL_DRK, (r1 - 0.70) / 0.30 * 0.60)
		draw_colored_polygon(PackedVector2Array([
			Vector2(BL, y1), Vector2(BR, y1), Vector2(BR, y2), Vector2(BL, y2)
		]), c)

	# Hand-painted wood grain lines
	var rng := RandomNumberGenerator.new(); rng.seed = 66554
	for _j in 4:
		var f   : float = rng.randf()
		var gy  : float = lerpf(TOP + H2*0.1, BOT - H2*0.1, f)
		var pts := PackedVector2Array()
		for k in 18:
			var t  : float = float(k) / 17.0
			pts.append(Vector2(lerpf(BL+8, BR-8, t), gy + sin(t*7.0+f*5.0)*0.7))
		var gc := C_WAL_DRK.lerp(C_WAL_MID, f * 0.3)
		gc.a    = rng.randf_range(0.04, 0.10)
		draw_polyline(pts, gc, 0.6, true)

func _d_soundboard(BL: float, BR: float, TOP: float, BOT: float) -> void:
	# Soundboard (light oak zither top surface)
	for i in 16:
		var r1 : float = float(i)      / 16.0
		var r2 : float = float(i + 1)  / 16.0
		var y1 := lerpf(TOP, BOT, r1)
		var y2 := lerpf(TOP, BOT, r2)
		var lt := sin(r1 * PI)
		var c  := C_OAK_MID.lerp(C_OAK_HI, lt * 0.75)
		if r1 < 0.08:  c = c.lerp(C_WAL_DRK, (0.08 - r1) / 0.08 * 0.50)
		elif r1 > 0.80: c = c.lerp(C_OAK_SHD, (r1 - 0.80) / 0.20 * 0.40)
		draw_colored_polygon(PackedVector2Array([
			Vector2(BL, y1), Vector2(BR, y1), Vector2(BR, y2), Vector2(BL, y2)
		]), c)

	# Soundboard wood grain
	var rng := RandomNumberGenerator.new(); rng.seed = 12345
	for _j in 8:
		var f   : float = rng.randf()
		var gy  : float = lerpf(TOP + 2.0, BOT - 2.0, f)
		var pts := PackedVector2Array()
		for k in 22:
			var t  : float = float(k) / 21.0
			pts.append(Vector2(lerpf(BL+4, BR-4, t), gy + sin(t*11.0+f*7.0)*0.9+cos(t*4.0)*0.4))
		var gc := C_OAK_SHD.lerp(C_OAK_MID, f)
		gc.a    = rng.randf_range(0.05, 0.15)
		draw_polyline(pts, gc, rng.randf_range(0.4, 0.8), true)

func _d_side_caps(BL: float, BR: float, TOP: float, BOT: float) -> void:
	var d := 4.0
	# Left end caps
	draw_colored_polygon(PackedVector2Array([
		Vector2(BL-d, TOP+d*0.4), Vector2(BL, TOP),
		Vector2(BL, BOT),         Vector2(BL-d, BOT-d*0.4)
	]), C_WAL_DRK)
	# Right end caps
	draw_colored_polygon(PackedVector2Array([
		Vector2(BR, TOP),         Vector2(BR+d, TOP+d*0.4),
		Vector2(BR+d, BOT-d*0.4), Vector2(BR, BOT)
	]), C_WAL_DRK)

func _d_gold_trim(BL: float, BR: float, SBT: float, SBB: float, FPB: float) -> void:
	var g  := Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.85)
	var gd := Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.40)

	draw_line(Vector2(BL, SBT), Vector2(BR, SBT), g,  1.2)   # top edge
	draw_line(Vector2(BL, SBB), Vector2(BR, SBB), g,  1.0)   # divider edge
	draw_line(Vector2(BL, FPB), Vector2(BR, FPB), gd, 0.8)   # bottom edge

	# Soundboard inlay frame
	var si := (SBB - SBT) * 0.15
	draw_polyline(PackedVector2Array([
		Vector2(BL+10, SBT+si), Vector2(BR-10, SBT+si),
		Vector2(BR-10, SBB-si), Vector2(BL+10, SBB-si), Vector2(BL+10, SBT+si)
	]), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.32), 0.7, true)

	# Front panel inlay frame
	var fi := (FPB - SBB) * 0.11
	draw_polyline(PackedVector2Array([
		Vector2(BL+9, SBB+fi), Vector2(BR-9, SBB+fi),
		Vector2(BR-9, FPB-fi), Vector2(BL+9, FPB-fi), Vector2(BL+9, SBB+fi)
	]), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.28), 0.7, true)

	# Corner rivets
	var rs := minf((SBB - SBT) * 0.45, 11.0)
	_rivet(Vector2(BL, SBT), rs, false, false)
	_rivet(Vector2(BR, SBT), rs, true,  false)
	_rivet(Vector2(BL, FPB), rs, false, true)
	_rivet(Vector2(BR, FPB), rs, true,  true)

func _rivet(p: Vector2, s: float, fx: bool, fy: bool) -> void:
	var sx := -1.0 if fx else 1.0; var sy := -1.0 if fy else 1.0
	draw_colored_polygon(PackedVector2Array([
		p, p+Vector2(sx*s,0.0), p+Vector2(sx*s*0.55,sy*s*0.55), p+Vector2(0.0,sy*s)
	]), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.68))
	var r := p + Vector2(sx*s*0.35, sy*s*0.35)
	draw_circle(r, 1.5, Color(0.10,0.05,0.0,0.90))
	draw_circle(r, 0.6, Color(1.0,0.95,0.7,0.50))

func _d_floral(BL: float, BW: float, SBT: float, SBB: float) -> void:
	# Gold floral carvings on the soundboard (lotus vines)
	var cy  : float = (SBT + SBB) * 0.50
	var r   : float = (SBB - SBT) * 0.38
	var gc  := Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.50)
	var gc2 := Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.30)
	_lotus(BL + BW*0.50, cy, r, gc)
	_lotus(BL + BW*0.25, cy, r*0.58, gc2)
	_lotus(BL + BW*0.75, cy, r*0.58, gc2)
	_vine(BL+BW*0.12, BL+BW*0.44, cy, r*0.42, gc2)
	_vine(BL+BW*0.56, BL+BW*0.88, cy, r*0.42, gc2)

func _lotus(cx: float, cy: float, r: float, c: Color) -> void:
	draw_circle(Vector2(cx,cy), r*0.20, c)
	draw_circle(Vector2(cx,cy), r*0.10, Color(c.r,c.g,c.b,1.0))
	for pi in 6:
		var a := deg_to_rad(float(pi)*60.0)
		draw_circle(Vector2(cx+cos(a)*r*0.38, cy+sin(a)*r*0.38), r*0.12, Color(c.r,c.g,c.b,c.a*0.70))
	draw_arc(Vector2(cx,cy), r*0.53, 0.0, TAU, 18, Color(c.r,c.g,c.b,c.a*0.40), 0.7)

func _vine(x0: float, x1: float, cy: float, amp: float, c: Color) -> void:
	var pts := PackedVector2Array()
	for k in 21:
		var t : float = float(k) / 20.0
		pts.append(Vector2(lerpf(x0,x1,t), cy + sin(t*TAU*1.5)*amp))
	draw_polyline(pts, c, 0.8, true)
	for k in range(0,21,4):
		var t : float = float(k) / 20.0
		draw_circle(Vector2(lerpf(x0,x1,t), cy+sin(t*TAU*1.5)*amp),
					amp*0.10, Color(c.r,c.g,c.b,c.a*0.65))

func _d_bridge(bx: float, sy: float, sb_bot: float) -> void:
	# Wooden bridge (ngựa đàn) located at the LEFT end
	var bw : float = size.x * 0.006
	var bh : float = (sb_bot - sy) * 0.65
	draw_colored_polygon(PackedVector2Array([
		Vector2(bx-bw, sy), Vector2(bx+bw, sy),
		Vector2(bx+bw*0.65, sy+bh), Vector2(bx-bw*0.65, sy+bh)
	]), C_WAL_MID)
	draw_line(Vector2(bx-bw,sy), Vector2(bx+bw,sy), Color(C_GOLD.r,C_GOLD.g,C_GOLD.b,0.50), 0.8)

# ══════════════════════════════════════════════════════════════════════════
#  STRING + HARMONIC NODES
# ══════════════════════════════════════════════════════════════════════════

func _d_string(ss: Vector2, se: Vector2) -> void:
	var pts := PackedVector2Array()
	pts.append(ss)
	if _pluck_amp > 0.005:
		for k in range(1, 36):
			var t   : float = float(k) / 36.0
			var px  : float = lerpf(ss.x, se.x, t)
			var py  : float = lerpf(ss.y, se.y, t)   # Horizontal layout
			var osc : float = sin(t*PI) * sin(t*PI*5.0 - _pluck_time*88.0) * _pluck_amp * 5.5 * exp(-_pluck_time*1.8)
			pts.append(Vector2(px, py + osc))
	pts.append(se)

	# Shadow
	var shd := PackedVector2Array()
	for p in pts: shd.append(p + Vector2(0.0, 2.0))
	draw_polyline(shd, Color(0,0,0,0.25), 1.0, true)

	# Glow
	if _pluck_amp > 0.01:
		draw_polyline(pts, Color(C_STR_GLOW.r,C_STR_GLOW.g,C_STR_GLOW.b,_pluck_amp*0.50), 4.0, true)

	# Steel String Core
	var sc := C_STR_GLOW if _pluck_amp > 0.12 else C_STR
	if _is_bending: sc = Color("#fc8820")
	draw_polyline(pts, sc, 1.4, true)

func _d_nodes(sy: float) -> void:
	var font := get_theme_font("font")
	for i in NODE_COUNT:
		_d_node(Vector2(_node_xs[i], sy), i, _is_tgt[i]==1, _hov==i, _glow[i], font)

func _d_node(pos: Vector2, idx: int, tgt: bool, hov: bool, glow: float, font: Font) -> void:
	draw_circle(pos+Vector2(0,2.0), 10.5, Color(0,0,0,0.25))
	if tgt:
		var p := (sin(_pulse*2.0)+1.0)*0.5
		draw_circle(pos, 14.5+p*4.0, Color(0.78,0.60,0.18,0.10+p*0.10))
		draw_arc(pos, 14.5+p*4.0, 0.0, TAU, 24, Color(0.78,0.60,0.18,0.30+p*0.20), 1.0)
	if glow > 0.01:
		draw_circle(pos, 10.0+glow*18.0, Color(1.0,0.96,0.76,glow*0.40))
		draw_arc(pos,   10.0+glow*18.0, 0.0, TAU, 20, Color(1.0,0.90,0.50,glow*0.50), 1.2)
	var R : float = 8.5 + (1.2 if hov else (0.8 if tgt else 0.0))
	draw_circle(pos, R,        C_GOLD)
	draw_circle(pos, R-1.4,    Color("#faf5e4"))
	draw_circle(pos, R-3.5,    C_GOLD)
	draw_circle(pos, R-5.2,    C_WAL_DRK)
	draw_circle(pos, 1.0,      Color(1,1,1,0.80))
	if font == null: return
	var text := _note_names[idx] if idx < _note_names.size() else NOTES_VN[idx]
	var fsz  := 12 if (tgt or hov) else 10
	var tc   := (Color("#faf6e8") if tgt else (Color.WHITE if hov else Color("#c0a878")))
	var ts   := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, fsz)
	var tp   := Vector2(pos.x - ts.x*0.5, pos.y - R - 5.0)
	draw_string(font, tp+Vector2(1,1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, Color(0,0,0,0.70))
	draw_string(font, tp,             text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, tc)

# ══════════════════════════════════════════════════════════════════════════
#  GOURD & BAMBOO ROD  (Right End Resonator)
# ══════════════════════════════════════════════════════════════════════════

func _d_gourd(gx: float, gy: float, gr: float) -> void:
	# Gourd resonator (bầu cộng hưởng) shadow
	draw_circle(Vector2(gx+3.0, gy+4.5), gr+2.5, Color(0,0,0,0.28))
	# Glossy spherical brown lacquer rendering
	for i in 20:
		var rr : float = float(20-i) / 20.0
		var r  : float = gr * rr
		var o  := Vector2(-0.7,-0.7)*(1.0-rr)
		var c  := C_GOURD_DRK.lerp(C_GOURD_HI, rr*0.80)
		if rr > 0.80: c = c.lerp(Color("#bd6c24"), (rr-0.80)/0.20*0.50)
		draw_circle(Vector2(gx,gy)+o, r, c)
	# Highlights
	draw_circle(Vector2(gx-gr*0.28, gy-gr*0.30), gr*0.13, Color(1,1,1,0.70))
	draw_circle(Vector2(gx-gr*0.17, gy-gr*0.18), gr*0.06, Color(1,1,1,0.48))
	# Carved lines
	draw_arc(Vector2(gx,gy), gr*0.70, 0.0, TAU, 24, Color(C_GOURD_DRK.r,C_GOURD_DRK.g,C_GOURD_DRK.b,0.40), 0.9)
	draw_arc(Vector2(gx,gy), gr*0.50, 0.0, TAU, 18, Color(C_GOURD_DRK.r,C_GOURD_DRK.g,C_GOURD_DRK.b,0.25), 0.6)
	# Small details
	for fi in 4:
		var a := deg_to_rad(float(fi)*90.0+45.0)
		draw_circle(Vector2(gx+cos(a)*gr*0.58, gy+sin(a)*gr*0.58), gr*0.05,
					Color(C_GOURD_HI.r,C_GOURD_HI.g,C_GOURD_HI.b,0.50))
	# Brass collar ring connecting to zither body
	var cy2 := gy + gr*0.68
	for ci in 5:
		var rr : float = float(5-ci)/5.0
		draw_circle(Vector2(gx,cy2)+Vector2(-rr,-rr)*0.3, gr*0.18*rr, C_GOLD_DRK.lerp(C_GOLD,rr))

func _d_bamboo(rb: Vector2, rt: Vector2, c1: Vector2, c2: Vector2, gr: float) -> void:
	# Flexible bamboo rod (cần đàn) drawn via a smooth Bezier spline
	var SEG := 28
	var pts := PackedVector2Array()
	for k in SEG+1:
		pts.append(_cbez(rb, c1, c2, rt, float(k)/float(SEG)))

	# Bamboo shadow
	var shd := PackedVector2Array()
	for p in pts: shd.append(p+Vector2(2.0, 3.0))
	for k in SEG:
		draw_line(shd[k], shd[k+1], Color(0,0,0,0.15), lerpf(5.5,1.4,float(k)/float(SEG)), true)

	# Bamboo body stalk with gradient coloring
	for k in SEG:
		var t  : float = float(k)/float(SEG)
		var th : float = lerpf(5.5, 1.4, t)
		var c  := C_BAM_DRK.lerp(C_BAM_MID, 0.40+0.30*sin(t*PI))
		draw_line(pts[k], pts[k+1], c, th, true)
		if k == 0: draw_circle(pts[k], th*0.5, c)

	# Bamboo Joint Knots (proportional knot rings)
	for kp in [0.26, 0.52, 0.76]:
		var ki := int(kp*float(SEG))
		var t  : float = kp
		var th : float = lerpf(5.5, 1.4, t)
		if ki < pts.size():
			draw_circle(pts[ki], th*0.72, C_BAM_DRK)
			draw_circle(pts[ki], th*0.50, C_BAM_MID)
			draw_circle(pts[ki]+Vector2(-th*0.12,-th*0.12), th*0.16, Color(1,1,1,0.25))

	# Specular stalk highlight
	for k in SEG:
		var t  : float = float(k)/float(SEG)
		var th : float = lerpf(5.5, 1.4, t)
		draw_line(pts[k]+Vector2(-th*0.14,-th*0.14), pts[k+1]+Vector2(-th*0.14,-th*0.14),
				  Color(C_BAM_HI.r,C_BAM_HI.g,C_BAM_HI.b,0.24*(1.0-t*0.6)), th*0.16, true)
	draw_circle(rt, 1.2, C_BAM_DRK)

	# Gold/brass wrap where the bamboo meets the gourd
	draw_arc(rb, gr*0.15, 0.0, TAU, 10, Color(C_GOLD.r,C_GOLD.g,C_GOLD.b,0.60), 1.2)

# ══════════════════════════════════════════════════════════════════════════
#  TUNING PEG  (Chốt Dây) — Left End
# ══════════════════════════════════════════════════════════════════════════

func _d_peg(px: float, sy: float, sbt: float, sbb: float) -> void:
	# Tuning peg (chốt dây) at the LEFT end
	var ph : float = (sbb - sbt) * 0.60
	draw_colored_polygon(PackedVector2Array([
		Vector2(px-6, sy-4.0), Vector2(px+2.0, sy-4.0),
		Vector2(px+2.0, sy+4.0), Vector2(px-6, sy+4.0)
	]), C_WAL_MID)

	# Metal shaft
	draw_line(Vector2(px-2.0, sy-ph*0.30), Vector2(px-2.0, sy-ph-2.5), Color("#484030"), 3.0)
	draw_line(Vector2(px-2.0, sy-ph*0.30), Vector2(px-2.0, sy-ph-2.5), Color("#706050"), 1.2)

	# Wooden peg knob
	var kc := Vector2(px-2.0, sy-ph-2.5)
	for ci in 8:
		var rr : float = float(8-ci)/8.0
		var c  := C_WAL_DRK.lerp(C_WAL_MID, rr*0.65)
		if rr > 0.78: c = c.lerp(C_WAL_HI, (rr-0.78)/0.22*0.50)
		draw_circle(kc+Vector2(-rr*0.5,-rr*0.5)*0.4, 4.5*rr, c)
	draw_circle(kc+Vector2(-1.2,-1.5), 1.0, Color(1,1,1,0.38))

	# Gold metal collar
	draw_arc(Vector2(px-2.0, sy), 4.5, 0.0, TAU, 12, Color(C_GOLD.r,C_GOLD.g,C_GOLD.b,0.60), 1.0)

# ══════════════════════════════════════════════════════════════════════════
#  CENTS BADGE & MATHS
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
#  TOUCH & MOUSE INPUT
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
	# Bend zone: RIGHT side of the zither (bamboo rod side)
	if pos.x > _bend_zone_x:
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
	var BW    : float = size.x * 0.81
	var BH    : float = clampf(BW * 0.07, 34.0, 72.0)
	var BCY   : float = size.y * 0.62
	var BT    : float = BCY - BH * 0.5
	var GR    : float = BH * 0.50
	var GY    : float = BCY
	var RB_y  : float = GY - GR * 0.82
	var rest_y: float = RB_y
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
