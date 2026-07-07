extends Control

## DanBauBoard — Vietnamese Đàn Bầu (Monochord)
## Renders a 2.5D side-view of the instrument matching the concept sheet.
##
## Layout (LEFT → RIGHT):
##   ① Bầu cộng hưởng (round gourd resonator) + Cần đàn (bamboo rod curving up)
##   ② Body: oak soundboard on top, dark walnut front panel below
##   ③ 7 harmonic touch nodes along the steel string
##   ④ Chốt dây (tuning peg) at right end
##
## IMPORTANT: All sizes are derived from BODY_W (not canvas H) so the
## instrument stays proportional on any canvas aspect ratio.

signal string_plucked(idx: int, note_name: String)
signal pitch_bent(cents_offset: float)

const NODE_COUNT := 7
const NOTES_VN : Array[String] = ["Đô", "Rê", "Mi", "Fa", "Sol", "La", "Si"]

# ── Colours (from concept-sheet palette) ────────────────────────────────────
const C_OAK_LIGHT   := Color("#e8c870")   # soundboard highlight
const C_OAK_MID     := Color("#c89840")   # soundboard mid-tone
const C_OAK_DARK    := Color("#a07428")   # soundboard shadow
const C_WALNUT_LIGHT:= Color("#6c3c18")   # front panel highlight edge
const C_WALNUT_MID  := Color("#3e2010")   # front panel mid
const C_WALNUT_DARK := Color("#1e0e06")   # front panel deep shadow
const C_GOURD_LIGHT := Color("#8a5828")   # gourd highlight
const C_GOURD_MID   := Color("#5a3414")   # gourd mid
const C_GOURD_DARK  := Color("#2c180a")   # gourd shadow
const C_BAMBOO_LIGHT:= Color("#a09050")   # bamboo rod highlight
const C_BAMBOO_MID  := Color("#706838")   # bamboo rod mid
const C_BAMBOO_DARK := Color("#48401c")   # bamboo rod shadow
const C_GOLD        := Color("#c89830")   # gold trim / inlay
const C_GOLD_LIGHT  := Color("#f0d070")   # gold highlight
const C_GOLD_DARK   := Color("#785808")   # gold shadow
const C_STRING      := Color("#c8ccd8")   # steel string (cool silver)
const C_STRING_GLOW := Color("#f8eea0")   # string vibration glow

# ── State ────────────────────────────────────────────────────────────────────
var _note_names : Array[String]      = []
var _streams    : Array              = []
var _freqs      : Array[float]       = []

var _pluck_amp   : float              = 0.0
var _pluck_time  : float              = 0.0
var _glow_alpha  : PackedFloat32Array = PackedFloat32Array()
var _pulse_phase : float              = 0.0
var _is_target   : PackedByteArray    = PackedByteArray()

var _is_bending    := false
var _bend_offset   := 0.0   # vertical offset applied to rod tip (pixels)
var _bend_cents    := 0.0
var _bend_velocity := 0.0
var _hovered_idx   := -1
var _target_idx    := 0

# Cached geometry (recomputed each frame in _draw)
var _str_start  := Vector2.ZERO
var _str_end    := Vector2.ZERO
var _str_y      := 0.0
var _node_xs    : PackedFloat32Array = PackedFloat32Array()
var _body_left  := 0.0
var _body_right := 0.0

func init(notes: Array[String], streams: Array, freqs: Array[float]) -> void:
	_note_names = notes
	_streams    = streams
	_freqs      = freqs
	_glow_alpha.resize(NODE_COUNT)
	_is_target.resize(NODE_COUNT)
	for i in NODE_COUNT:
		_glow_alpha[i] = 0.0
		_is_target[i]  = 0
	queue_redraw()

func _ready() -> void:
	resized.connect(queue_redraw)
	mouse_filter = MOUSE_FILTER_STOP
	queue_redraw()

func set_target(idx: int) -> void:
	_target_idx = idx
	for i in NODE_COUNT:
		_is_target[i] = 1 if i == idx else 0
	queue_redraw()

func pluck(idx: int) -> void:
	if idx < 0 or idx >= NODE_COUNT: return
	_pluck_time = 0.0
	_pluck_amp  = 1.0
	_glow_alpha[idx] = 1.0
	var name := _note_names[idx] if idx < _note_names.size() else NOTES_VN[idx]
	string_plucked.emit(idx, name)
	queue_redraw()

func _process(delta: float) -> void:
	var dirty := false

	# Pluck decay
	if _pluck_amp > 0.0:
		_pluck_time += delta
		_pluck_amp   = maxf(0.0, _pluck_amp - delta * 2.5)
		dirty = true

	# Node glow decay
	for i in NODE_COUNT:
		if _glow_alpha[i] > 0.0:
			_glow_alpha[i] = maxf(0.0, _glow_alpha[i] - delta * 3.0)
			dirty = true

	_pulse_phase += delta * 3.5
	dirty = true

	# Spring-damper return for bamboo rod
	if not _is_bending and (_bend_offset != 0.0 or _bend_velocity != 0.0):
		var spring := 400.0
		var damp   := 14.0
		var accel  := -spring * _bend_offset - damp * _bend_velocity
		_bend_velocity += accel * delta
		_bend_offset   += _bend_velocity * delta
		if abs(_bend_offset) < 0.1 and abs(_bend_velocity) < 0.1:
			_bend_offset   = 0.0
			_bend_velocity = 0.0
			_bend_cents    = 0.0
			pitch_bent.emit(0.0)
		else:
			# Max rod travel = 12% of body height (set in layout below)
			# We approximate here; real max_travel computed in _draw
			_bend_cents = clampf(_bend_offset / 18.0 * 350.0, -400.0, 400.0)
			pitch_bent.emit(_bend_cents)
		dirty = true

	if dirty:
		queue_redraw()

# ═══════════════════════════════════════════════════════════════════════════
#  DRAW
# ═══════════════════════════════════════════════════════════════════════════
func _draw() -> void:
	var W := size.x
	var H := size.y
	if W < 120.0 or H < 50.0:
		return

	# ── 1. Layout (all sizes from body WIDTH, not canvas height) ──────────
	#
	# The body occupies the horizontal middle strip of the canvas.
	# BL = left edge of wooden body box
	# BR = right edge
	# The gourd sticks out to the LEFT of BL.

	var BL : float = W * 0.16       # body left edge
	var BR : float = W * 0.97       # body right edge (tuning peg here)
	var BW : float = BR - BL        # body width

	# Total body height derived from width to keep concept-sheet proportions.
	# Concept sheet: body ≈ 512 × 160 px  →  aspect ≈ 3.2
	var BODY_H : float = minf(BW / 3.2, H * 0.58)

	# Vertical placement: centre the body in canvas, biased downward so the
	# bamboo rod has room above.
	var BODY_CY : float = H * 0.60
	var BODY_TOP: float = BODY_CY - BODY_H * 0.50   # absolute top of body
	var BODY_BOT: float = BODY_CY + BODY_H * 0.50   # absolute bottom of body

	# Soundboard (oak) = top 30 % of body height
	var SB_H   : float = BODY_H * 0.30
	var SB_TOP : float = BODY_TOP
	var SB_BOT : float = BODY_TOP + SB_H

	# Front panel (walnut) = bottom 70 %
	var FP_TOP : float = SB_BOT
	var FP_BOT : float = BODY_BOT

	# String runs along the soundboard at ~55 % from soundboard top
	var STR_Y  : float = SB_TOP + SB_H * 0.55

	# Gourd: proportional to BODY_H (NOT to H!)
	var G_R : float = BODY_H * 0.48        # gourd radius
	var G_CX: float = BL - G_R * 0.50     # gourd centre X (slightly inside BL)
	var G_CY: float = BODY_CY             # vertically centred on body

	# Bamboo rod: emerges from the top of the gourd, curves upward-right
	var ROD_BASE := Vector2(G_CX + G_R * 0.12, G_CY - G_R * 0.82)
	var ROD_TIP  := Vector2(G_CX + BW * 0.055, BODY_TOP - BODY_H * 0.55 + _bend_offset)
	var ROD_C1   := Vector2(G_CX + G_R * 0.30, ROD_BASE.y - BODY_H * 0.50)
	var ROD_C2   := Vector2(ROD_TIP.x - G_R * 0.25, ROD_TIP.y + BODY_H * 0.32)

	# String anchors
	_str_start = Vector2(G_CX, G_CY)            # attaches to gourd surface
	_str_end   = Vector2(BR - 6.0, STR_Y)       # at tuning peg
	_str_y     = STR_Y

	# Node X positions (evenly spaced between body left + margin and peg)
	var N_START : float = BL + BW * 0.035
	var N_END   : float = BR - BW * 0.03
	var N_STEP  : float = (N_END - N_START) / float(NODE_COUNT - 1)
	_node_xs.resize(NODE_COUNT)
	for i in NODE_COUNT:
		_node_xs[i] = N_START + float(i) * N_STEP

	_body_left  = BL
	_body_right = BR

	# Store max_travel for bend physics
	var _max_rod_travel := BODY_H * 0.12

	# ── 2. Draw order ─────────────────────────────────────────────────────
	# Ground shadow
	_shadow(BL, BR, BODY_BOT)
	# Wooden feet under body
	_feet(BL, BR, BODY_BOT, BODY_H)
	# Front panel (dark walnut)
	_front_panel(BL, BR, FP_TOP, FP_BOT)
	# Soundboard (light oak)
	_soundboard(BL, BR, SB_TOP, SB_BOT)
	# Side caps (depth bevel)
	_side_caps(BL, BR, SB_TOP, BODY_BOT)
	# Gold border trim
	_gold_borders(BL, BR, SB_TOP, SB_BOT, FP_BOT)
	# Floral inlay on soundboard
	_floral(BL, BW, SB_TOP, SB_BOT)
	# Bridge (ngựa đàn)
	_bridge(BL + BW * 0.50, STR_Y, SB_BOT)
	# Single string
	_string_draw()
	# 7 harmonic nodes
	_nodes(STR_Y, SB_TOP, SB_BOT)
	# Gourd resonator
	_gourd(G_CX, G_CY, G_R)
	# Bamboo rod
	_bamboo_rod(ROD_BASE, ROD_TIP, ROD_C1, ROD_C2, G_R)
	# Tuning peg
	_tuning_peg(BR, STR_Y, SB_TOP, SB_BOT)
	# Bend readout
	if _is_bending:
		var f := get_theme_font("font")
		if f:
			_cents_badge(f, ROD_TIP + Vector2(20, 0), _bend_cents)

# ═══════════════════════════════════════════════════════════════════════════
#  BODY
# ═══════════════════════════════════════════════════════════════════════════

func _shadow(BL: float, BR: float, BOT: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(BL - 14, BOT + 3),  Vector2(BR + 16, BOT + 3),
		Vector2(BR + 8,  BOT + 13), Vector2(BL - 6,  BOT + 13)
	]), Color(0, 0, 0, 0.20))

func _feet(BL: float, BR: float, BOT: float, BH: float) -> void:
	var FH : float = BH * 0.09
	var FW : float = BH * 0.22
	var positions : Array[float] = [0.12, 0.50, 0.88]
	for p in positions:
		var fx : float = BL + (BR - BL) * p
		var top_pts := PackedVector2Array([
			Vector2(fx - FW * 0.50, BOT),
			Vector2(fx + FW * 0.50, BOT),
			Vector2(fx + FW * 0.40, BOT + FH),
			Vector2(fx - FW * 0.40, BOT + FH)
		])
		draw_colored_polygon(top_pts, C_WALNUT_DARK)
		# Gold edge on top of foot
		draw_line(Vector2(fx - FW*0.50, BOT),
				  Vector2(fx + FW*0.50, BOT),
				  Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.40), 0.8)

func _front_panel(BL: float, BR: float, TOP: float, BOT: float) -> void:
	# Dark walnut front panel — gradient from lighter at top to darker at bottom
	var FH    := BOT - TOP
	var STEPS := 16
	for i in STEPS:
		var r1 : float = float(i)     / float(STEPS)
		var r2 : float = float(i + 1) / float(STEPS)
		var y1 := lerpf(TOP, BOT, r1)
		var y2 := lerpf(TOP, BOT, r2)
		var col := C_WALNUT_MID
		# Slight bevel highlight at very top
		if r1 < 0.10:
			col = col.lerp(C_WALNUT_LIGHT, (0.10 - r1) / 0.10 * 0.45)
		# Deepen toward bottom
		elif r1 > 0.70:
			col = col.lerp(C_WALNUT_DARK, (r1 - 0.70) / 0.30 * 0.60)
		draw_colored_polygon(PackedVector2Array([
			Vector2(BL, y1), Vector2(BR, y1), Vector2(BR, y2), Vector2(BL, y2)
		]), col)
	# Subtle wood-grain lines
	var rng := RandomNumberGenerator.new()
	rng.seed = 8877
	for _j in range(5):
		var f   : float = rng.randf()
		var gy  : float = lerpf(TOP + FH * 0.08, BOT - FH * 0.08, f)
		var pts := PackedVector2Array()
		for k in range(18):
			var t  : float = float(k) / 17.0
			var gx : float = lerpf(BL + 8.0, BR - 8.0, t)
			pts.append(Vector2(gx, gy + sin(t * 8.0 + f * 4.0) * 0.8))
		var gc := C_WALNUT_DARK.lerp(C_WALNUT_MID, f * 0.4)
		gc.a    = rng.randf_range(0.05, 0.12)
		draw_polyline(pts, gc, 0.6, true)

func _soundboard(BL: float, BR: float, TOP: float, BOT: float) -> void:
	# Light oak soundboard — the main playing surface, warm honey-gold
	var SH    := BOT - TOP
	var STEPS := 18
	for i in STEPS:
		var r1 : float = float(i)     / float(STEPS)
		var r2 : float = float(i + 1) / float(STEPS)
		var y1 := lerpf(TOP, BOT, r1)
		var y2 := lerpf(TOP, BOT, r2)
		# Cylindrical shading: brightest in upper-centre
		var light := sin(r1 * PI)
		var col   := C_OAK_MID.lerp(C_OAK_LIGHT, light * 0.70)
		# Shadow near top edge (cast by soundboard rim)
		if r1 < 0.09:
			col = col.lerp(C_WALNUT_DARK, (0.09 - r1) / 0.09 * 0.50)
		elif r1 > 0.82:
			col = col.lerp(C_OAK_DARK, (r1 - 0.82) / 0.18 * 0.45)
		draw_colored_polygon(PackedVector2Array([
			Vector2(BL, y1), Vector2(BR, y1), Vector2(BR, y2), Vector2(BL, y2)
		]), col)
	# Wood grain
	var rng := RandomNumberGenerator.new()
	rng.seed = 3344
	for _j in range(10):
		var f   : float = rng.randf()
		var gy  : float = lerpf(TOP + 2.0, BOT - 2.0, f)
		var pts := PackedVector2Array()
		for k in range(22):
			var t  : float = float(k) / 21.0
			var gx : float = lerpf(BL + 4.0, BR - 4.0, t)
			pts.append(Vector2(gx, gy + sin(t * 12.0 + f * 6.0) * 1.0 + cos(t * 4.0) * 0.5))
		var gc := C_OAK_DARK.lerp(C_OAK_MID, f)
		gc.a    = rng.randf_range(0.06, 0.18)
		draw_polyline(pts, gc, rng.randf_range(0.4, 1.0), true)

func _side_caps(BL: float, BR: float, TOP: float, BOT: float) -> void:
	# Thin depth-bevel on left and right ends
	var d : float = 5.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(BL - d, TOP + d * 0.4), Vector2(BL, TOP),
		Vector2(BL, BOT), Vector2(BL - d, BOT - d * 0.4)
	]), C_WALNUT_DARK)
	draw_colored_polygon(PackedVector2Array([
		Vector2(BR, TOP), Vector2(BR + d, TOP + d * 0.4),
		Vector2(BR + d, BOT - d * 0.4), Vector2(BR, BOT)
	]), C_WALNUT_DARK)

func _gold_borders(BL: float, BR: float, SB_TOP: float, SB_BOT: float, FP_BOT: float) -> void:
	var g  := Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.88)
	var gd := Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.42)

	draw_line(Vector2(BL, SB_TOP), Vector2(BR, SB_TOP), g,  1.5)   # top far edge
	draw_line(Vector2(BL, SB_BOT), Vector2(BR, SB_BOT), g,  1.2)   # soundboard bottom
	draw_line(Vector2(BL, FP_BOT), Vector2(BR, FP_BOT), gd, 0.9)   # bottom edge

	# Inset frame on soundboard
	var si : float = (SB_BOT - SB_TOP) * 0.12
	draw_polyline(PackedVector2Array([
		Vector2(BL + 12, SB_TOP + si), Vector2(BR - 12, SB_TOP + si),
		Vector2(BR - 12, SB_BOT - si), Vector2(BL + 12, SB_BOT - si),
		Vector2(BL + 12, SB_TOP + si)
	]), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35), 0.7, true)

	# Inset frame on front panel
	var fi : float = (FP_BOT - SB_BOT) * 0.12
	draw_polyline(PackedVector2Array([
		Vector2(BL + 10, SB_BOT + fi), Vector2(BR - 10, SB_BOT + fi),
		Vector2(BR - 10, FP_BOT - fi), Vector2(BL + 10, FP_BOT - fi),
		Vector2(BL + 10, SB_BOT + fi)
	]), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.32), 0.7, true)

	# Corner rivets
	var rs : float = minf((SB_BOT - SB_TOP) * 0.45, 12.0)
	_rivet(Vector2(BL, SB_TOP), rs, false, false)
	_rivet(Vector2(BR, SB_TOP), rs, true,  false)
	_rivet(Vector2(BL, FP_BOT), rs, false, true)
	_rivet(Vector2(BR, FP_BOT), rs, true,  true)

func _rivet(pos: Vector2, s: float, fx: bool, fy: bool) -> void:
	var sx := -1.0 if fx else 1.0
	var sy := -1.0 if fy else 1.0
	draw_colored_polygon(PackedVector2Array([
		pos,
		pos + Vector2(sx * s, 0.0),
		pos + Vector2(sx * s * 0.55, sy * s * 0.55),
		pos + Vector2(0.0, sy * s)
	]), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.72))
	var rp := pos + Vector2(sx * s * 0.35, sy * s * 0.35)
	draw_circle(rp, 1.7, Color(0.10, 0.05, 0.0, 0.92))
	draw_circle(rp, 0.7, Color(1.0, 0.95, 0.7, 0.50))

func _floral(BL: float, BW: float, SB_TOP: float, SB_BOT: float) -> void:
	# Gold floral inlay carved into the oak soundboard.
	# Matches concept sheet: central lotus cluster flanked by vine scrolls.
	var cy  : float = (SB_TOP + SB_BOT) * 0.50
	var fh  : float = (SB_BOT - SB_TOP) * 0.38   # pattern radius
	var gc  := Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.52)
	var gc2 := Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.36)

	# Central lotus
	_lotus(BL + BW * 0.50, cy, fh, gc)
	# Two smaller accent lotuses
	_lotus(BL + BW * 0.22, cy, fh * 0.58, gc2)
	_lotus(BL + BW * 0.78, cy, fh * 0.58, gc2)
	# Vine lines linking them
	_vine(BL + BW * 0.10, BL + BW * 0.44, cy, fh * 0.42, gc2)
	_vine(BL + BW * 0.56, BL + BW * 0.90, cy, fh * 0.42, gc2)

func _lotus(cx: float, cy: float, r: float, col: Color) -> void:
	draw_circle(Vector2(cx, cy), r * 0.20, col)
	draw_circle(Vector2(cx, cy), r * 0.10, Color(col.r, col.g, col.b, 1.0))
	for pi in range(6):
		var ang : float = deg_to_rad(float(pi) * 60.0)
		var px  : float = cx + cos(ang) * r * 0.38
		var py  : float = cy + sin(ang) * r * 0.38
		draw_circle(Vector2(px, py), r * 0.14, Color(col.r, col.g, col.b, col.a * 0.75))
	draw_arc(Vector2(cx, cy), r * 0.52, 0.0, TAU, 20,
			 Color(col.r, col.g, col.b, col.a * 0.45), 0.7)

func _vine(x0: float, x1: float, cy: float, amp: float, col: Color) -> void:
	var pts := PackedVector2Array()
	var S   := 20
	for k in range(S + 1):
		var t  : float = float(k) / float(S)
		var vx : float = lerpf(x0, x1, t)
		var vy : float = cy + sin(t * TAU * 1.5) * amp
		pts.append(Vector2(vx, vy))
	draw_polyline(pts, col, 0.9, true)
	for k in range(0, S + 1, 4):
		var t  : float = float(k) / float(S)
		var vx : float = lerpf(x0, x1, t)
		var vy : float = cy + sin(t * TAU * 1.5) * amp
		draw_circle(Vector2(vx, vy), amp * 0.12, Color(col.r, col.g, col.b, col.a * 0.70))

func _bridge(bx: float, str_y: float, sb_bot: float) -> void:
	# Ngựa đàn — tiny wooden bridge sitting on soundboard (subtle, not huge)
	var bw : float = size.x * 0.008
	var bh : float = (sb_bot - str_y) * 0.60
	draw_colored_polygon(PackedVector2Array([
		Vector2(bx - bw, str_y),
		Vector2(bx + bw, str_y),
		Vector2(bx + bw * 0.65, str_y + bh),
		Vector2(bx - bw * 0.65, str_y + bh)
	]), C_WALNUT_MID)
	draw_line(Vector2(bx - bw, str_y), Vector2(bx + bw, str_y),
			  Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.55), 0.9)

# ═══════════════════════════════════════════════════════════════════════════
#  STRING
# ═══════════════════════════════════════════════════════════════════════════

func _string_draw() -> void:
	var pts := PackedVector2Array()
	pts.append(_str_start)

	if _pluck_amp > 0.005:
		var spd : float = 88.0
		for k in range(1, 36):
			var ratio  : float = float(k) / 36.0
			var px     : float = lerpf(_str_start.x, _str_end.x, ratio)
			var base_y : float = lerpf(_str_start.y, _str_end.y, ratio)
			var decay  : float = exp(-_pluck_time * 1.8)
			var osc    : float = sin(ratio * PI) * sin(ratio * PI * 5.0 - _pluck_time * spd) * _pluck_amp * 6.5 * decay
			pts.append(Vector2(px, base_y + osc))

	pts.append(_str_end)

	# Drop shadow
	var shd := PackedVector2Array()
	for pt in pts:
		shd.append(pt + Vector2(0.0, 2.5))
	draw_polyline(shd, Color(0.0, 0.0, 0.0, 0.28), 1.1, true)

	# Glow when vibrating
	if _pluck_amp > 0.01:
		draw_polyline(pts,
				Color(C_STRING_GLOW.r, C_STRING_GLOW.g, C_STRING_GLOW.b, _pluck_amp * 0.55),
				4.5, true)

	# String core
	var col := C_STRING_GLOW if _pluck_amp > 0.12 else C_STRING
	if _is_bending:
		col = Color("#fc8820")
	draw_polyline(pts, col, 1.5, true)

# ═══════════════════════════════════════════════════════════════════════════
#  HARMONIC NODES
# ═══════════════════════════════════════════════════════════════════════════

func _nodes(str_y: float, sb_top: float, sb_bot: float) -> void:
	var font := get_theme_font("font")
	for i in NODE_COUNT:
		var nx : float = _node_xs[i]
		_node(Vector2(nx, str_y), i,
			  _is_target[i] == 1,
			  _hovered_idx == i,
			  _glow_alpha[i],
			  sb_top, sb_bot, font)

func _node(pos: Vector2, idx: int, is_tgt: bool, is_hov: bool,
		   glow: float, sb_top: float, sb_bot: float, font: Font) -> void:
	# Drop shadow
	draw_circle(pos + Vector2(0.0, 2.5), 11.5, Color(0.0, 0.0, 0.0, 0.28))

	# Target pulse glow ring
	if is_tgt:
		var p := (sin(_pulse_phase * 2.0) + 1.0) * 0.5
		draw_circle(pos, 15.5 + p * 5.0,
				Color(0.78, 0.60, 0.18, 0.12 + p * 0.12))
		draw_arc(pos, 15.5 + p * 5.0, 0.0, TAU, 28,
				Color(0.78, 0.60, 0.18, 0.36 + p * 0.24), 1.2)

	# Pluck flash
	if glow > 0.01:
		var gr : float = 11.0 + glow * 20.0
		draw_circle(pos, gr, Color(1.0, 0.96, 0.76, glow * 0.44))
		draw_arc(pos,   gr, 0.0, TAU, 24, Color(1.0, 0.90, 0.50, glow * 0.54), 1.4)

	# Node itself: gold ring → ivory face → gold centre ring → dark core
	var R : float = 9.0 + (1.5 if is_hov else (1.0 if is_tgt else 0.0))
	draw_circle(pos, R,        C_GOLD)
	draw_circle(pos, R - 1.5,  Color("#faf5e4"))   # ivory
	draw_circle(pos, R - 4.0,  C_GOLD)
	draw_circle(pos, R - 6.0,  Color("#1c0c04"))   # dark core
	draw_circle(pos, 1.1, Color(1.0, 1.0, 1.0, 0.82))  # glint

	# Note label above node
	if font == null:
		return
	var text    := _note_names[idx] if idx < _note_names.size() else NOTES_VN[idx]
	var fsz     := 13 if (is_tgt or is_hov) else 11
	var tcol    : Color
	if is_tgt:     tcol = Color("#faf6e8")
	elif is_hov:   tcol = Color.WHITE
	else:          tcol = Color("#c0a878")
	var ts  := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, fsz)
	var tp  := Vector2(pos.x - ts.x * 0.5, pos.y - R - 6.0)
	draw_string(font, tp + Vector2(1.0, 1.0), text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, Color(0.0, 0.0, 0.0, 0.70))
	draw_string(font, tp, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, tcol)

# ═══════════════════════════════════════════════════════════════════════════
#  GOURD  (Bầu cộng hưởng)
# ═══════════════════════════════════════════════════════════════════════════

func _gourd(GX: float, GY: float, GR: float) -> void:
	# Round lacquered brown gourd — proportional to BODY_H, NOT to canvas H
	# This is a single sphere (NOT a double-gourd / not gold)

	# Drop shadow
	draw_circle(Vector2(GX + 3.5, GY + 5.5), GR + 3.0, Color(0.0, 0.0, 0.0, 0.32))

	# 3-D sphere shading — dark brown lacquer with warm highlight
	var STEPS := 22
	for i in range(STEPS):
		var r_ratio : float = float(STEPS - i) / float(STEPS)
		var r       : float = GR * r_ratio
		var ofs     := Vector2(-0.75, -0.75) * (1.0 - r_ratio)
		var col     := C_GOURD_DARK.lerp(C_GOURD_LIGHT, r_ratio * 0.80)
		if r_ratio > 0.78:
			col = col.lerp(Color("#c07828"), (r_ratio - 0.78) / 0.22 * 0.55)
		draw_circle(Vector2(GX, GY) + ofs, r, col)

	# Primary specular highlight (top-left)
	draw_circle(Vector2(GX - GR * 0.28, GY - GR * 0.30), GR * 0.13,
				Color(1.0, 1.0, 1.0, 0.72))
	draw_circle(Vector2(GX - GR * 0.17, GY - GR * 0.19), GR * 0.06,
				Color(1.0, 1.0, 1.0, 0.50))

	# Decorative carved rings (lacquerware detail)
	draw_arc(Vector2(GX, GY), GR * 0.72, 0.0, TAU, 28,
			 Color(C_GOURD_DARK.r, C_GOURD_DARK.g, C_GOURD_DARK.b, 0.45), 1.0)
	draw_arc(Vector2(GX, GY), GR * 0.52, 0.0, TAU, 22,
			 Color(C_GOURD_DARK.r, C_GOURD_DARK.g, C_GOURD_DARK.b, 0.30), 0.7)

	# Small floral dots on equator
	for fi in range(4):
		var ang : float = deg_to_rad(float(fi) * 90.0 + 45.0)
		draw_circle(Vector2(GX + cos(ang) * GR * 0.58, GY + sin(ang) * GR * 0.58),
					GR * 0.055, Color(C_GOURD_LIGHT.r, C_GOURD_LIGHT.g, C_GOURD_LIGHT.b, 0.55))

	# Brass collar ring where gourd attaches to body
	var collar_y : float = GY + GR * 0.68
	for ci in range(6):
		var rr : float = float(6 - ci) / 6.0
		draw_circle(
			Vector2(GX, collar_y) + Vector2(-rr, -rr) * 0.3,
			GR * 0.22 * rr,
			C_GOLD_DARK.lerp(C_GOLD, rr))
	draw_circle(Vector2(GX - GR * 0.07, collar_y - GR * 0.07),
				GR * 0.07, Color(1.0, 1.0, 1.0, 0.45))

# ═══════════════════════════════════════════════════════════════════════════
#  BAMBOO ROD  (Cần đàn)
# ═══════════════════════════════════════════════════════════════════════════

func _bamboo_rod(BASE: Vector2, TIP: Vector2, C1: Vector2, C2: Vector2, GR: float) -> void:
	var SEG := 28
	var pts := PackedVector2Array()
	for k in range(SEG + 1):
		var t : float = float(k) / float(SEG)
		pts.append(_cbez(BASE, C1, C2, TIP, t))

	# Shadow
	var shd := PackedVector2Array()
	for pt in pts:
		shd.append(pt + Vector2(2.5, 3.5))
	for k in range(SEG):
		var t  : float = float(k) / float(SEG)
		draw_line(shd[k], shd[k + 1],
				  Color(0.0, 0.0, 0.0, 0.18),
				  lerpf(6.5, 1.6, t), true)

	# Bamboo rod body
	for k in range(SEG):
		var t   : float = float(k) / float(SEG)
		var th  : float = lerpf(6.5, 1.6, t)
		var col := C_BAMBOO_DARK.lerp(C_BAMBOO_MID, 0.40 + 0.30 * sin(t * PI))
		draw_line(pts[k], pts[k + 1], col, th, true)
		if k == 0:
			draw_circle(pts[k], th * 0.5, col)

	# Bamboo knot rings (3 evenly spaced)
	var knots : Array[float] = [0.25, 0.52, 0.75]
	for kp in knots:
		var ki  := int(kp * float(SEG))
		var t   : float = kp
		var th  : float = lerpf(6.5, 1.6, t)
		if ki < pts.size():
			draw_circle(pts[ki], th * 0.70, C_BAMBOO_DARK)
			draw_circle(pts[ki], th * 0.52, C_BAMBOO_MID)
			draw_circle(pts[ki] + Vector2(-th * 0.14, -th * 0.14),
						th * 0.18, Color(1.0, 1.0, 1.0, 0.28))

	# Specular highlight along top edge
	for k in range(SEG):
		var t   : float = float(k) / float(SEG)
		var th  : float = lerpf(6.5, 1.6, t)
		var ofs := Vector2(-th * 0.16, -th * 0.16)
		draw_line(pts[k] + ofs, pts[k + 1] + ofs,
				  Color(C_BAMBOO_LIGHT.r, C_BAMBOO_LIGHT.g, C_BAMBOO_LIGHT.b,
						0.26 * (1.0 - t * 0.6)),
				  th * 0.18, true)

	# Tip
	draw_circle(TIP, 1.4, C_BAMBOO_DARK)

	# Gold collar at base (where rod enters gourd)
	draw_arc(BASE, GR * 0.15, 0.0, TAU, 12,
			 Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.65), 1.4)
	draw_arc(BASE - Vector2(0.0, GR * 0.04), GR * 0.12, 0.0, TAU, 10,
			 Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.48), 1.1)

# ═══════════════════════════════════════════════════════════════════════════
#  TUNING PEG  (Chốt dây) — right end
# ═══════════════════════════════════════════════════════════════════════════

func _tuning_peg(BR: float, str_y: float, sb_top: float, sb_bot: float) -> void:
	var px  : float = BR - 4.0
	var ph  : float = (sb_bot - sb_top) * 0.58   # peg height above string

	# Mount block on body
	draw_colored_polygon(PackedVector2Array([
		Vector2(px - 7.0, str_y - 4.5), Vector2(px + 2.5, str_y - 4.5),
		Vector2(px + 2.5, str_y + 4.5), Vector2(px - 7.0, str_y + 4.5)
	]), C_WALNUT_MID)
	draw_colored_polygon(PackedVector2Array([
		Vector2(px - 5.5, str_y - 3.0), Vector2(px + 1.0, str_y - 3.0),
		Vector2(px + 1.0, str_y + 3.0), Vector2(px - 5.5, str_y + 3.0)
	]), C_WALNUT_LIGHT)

	# Shaft
	draw_line(Vector2(px - 2.0, str_y - ph * 0.30),
			  Vector2(px - 2.0, str_y - ph - 3.0),
			  Color("#484030"), 3.5)
	draw_line(Vector2(px - 2.0, str_y - ph * 0.30),
			  Vector2(px - 2.0, str_y - ph - 3.0),
			  Color("#706050"), 1.4)

	# Knob (small sphere)
	var kc := Vector2(px - 2.0, str_y - ph - 3.0)
	for ci in range(10):
		var rr  : float = float(10 - ci) / 10.0
		var r   : float = 5.0 * rr
		var col := C_WALNUT_DARK.lerp(C_WALNUT_MID, rr * 0.65)
		if rr > 0.78:
			col = col.lerp(C_WALNUT_LIGHT, (rr - 0.78) / 0.22 * 0.55)
		draw_circle(kc + Vector2(-rr * 0.5, -rr * 0.5) * 0.4, r, col)
	draw_circle(kc + Vector2(-1.4, -1.7), 1.2, Color(1.0, 1.0, 1.0, 0.42))

	# Gold collar
	draw_arc(Vector2(px - 2.0, str_y), 5.0, 0.0, TAU, 14,
			 Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.68), 1.2)

# ═══════════════════════════════════════════════════════════════════════════
#  CENTS BADGE
# ═══════════════════════════════════════════════════════════════════════════

func _cents_badge(font: Font, pos: Vector2, cents: float) -> void:
	var sign := "+" if cents > 0.0 else ""
	var txt  := "%s%d ¢" % [sign, int(cents)]
	var col  := C_GOLD
	if cents >  5.0: col = Color("#28cc70")
	elif cents < -5.0: col = Color("#e43c3c")
	var ts := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 13)
	var bw := ts.x + 14.0
	var bh := ts.y + 4.0
	var bs := StyleBoxFlat.new()
	bs.bg_color          = Color(0.06, 0.03, 0.01, 0.90)
	bs.border_color      = Color(col.r, col.g, col.b, 0.55)
	bs.border_width_left = 1; bs.border_width_right  = 1
	bs.border_width_top  = 1; bs.border_width_bottom = 1
	bs.corner_radius_top_left    = 7; bs.corner_radius_top_right    = 7
	bs.corner_radius_bottom_left = 7; bs.corner_radius_bottom_right = 7
	draw_style_box(bs, Rect2(pos.x - bw * 0.5, pos.y - bh * 0.5, bw, bh))
	draw_string(font, pos + Vector2(-ts.x * 0.5, ts.y * 0.5 - 2.0),
				txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col)

func _cbez(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	return u*u*u*p0 + 3.0*u*u*t*p1 + 3.0*u*t*t*p2 + t*t*t*p3

# ═══════════════════════════════════════════════════════════════════════════
#  INPUT
# ═══════════════════════════════════════════════════════════════════════════

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var ev := event as InputEventMouseButton
		if ev.button_index == MOUSE_BUTTON_LEFT:
			if ev.pressed: _touch_start(ev.position)
			else:          _touch_end()
	elif event is InputEventMouseMotion:
		_touch_move((event as InputEventMouseMotion).position)
	elif event is InputEventScreenTouch:
		var ev := event as InputEventScreenTouch
		if ev.pressed: _touch_start(ev.position)
		else:          _touch_end()
	elif event is InputEventScreenDrag:
		_touch_move((event as InputEventScreenDrag).position)

func _touch_start(pos: Vector2) -> void:
	# Bend zone = left 18 % (near gourd / bamboo rod)
	if pos.x < size.x * 0.18:
		_is_bending = true
		_update_bend(pos.y)
	else:
		var ni := _node_at(pos)
		if ni != -1:
			pluck(ni)

func _touch_move(pos: Vector2) -> void:
	if _is_bending:
		_update_bend(pos.y)
	else:
		var ni := _node_at(pos)
		if ni != _hovered_idx:
			_hovered_idx = ni
			queue_redraw()

func _touch_end() -> void:
	_is_bending  = false
	_hovered_idx = -1
	queue_redraw()

func _node_at(pos: Vector2) -> int:
	if _node_xs.size() < NODE_COUNT:
		return -1
	for i in NODE_COUNT:
		if pos.distance_to(Vector2(_node_xs[i], _str_y)) <= 28.0:
			return i
	return -1

func _update_bend(ty: float) -> void:
	# Rod tip moves up (negative Y) when the player pushes/pulls down
	var W      := size.x
	var BW     : float = W * 0.81
	var BH     : float = minf(BW / 3.2, size.y * 0.58)
	var max_d  : float = BH * 0.12
	var mid_y  : float = size.y * 0.60 - BH * 0.50 - BH * 0.55   # approx rod rest Y
	_bend_offset   = clampf(ty - mid_y, -max_d, max_d)
	_bend_velocity = 0.0
	_bend_cents    = (_bend_offset / max_d) * 350.0
	pitch_bent.emit(_bend_cents)
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_hovered_idx = -1
		if _is_bending:
			_touch_end()
		queue_redraw()
