extends Control

## DanBauBoard — Vietnamese Đàn Bầu (Monochord) 2.5D Renderer
## Layout matches concept sheet exactly:
##   LEFT  end: Bầu cộng hưởng (round gourd resonator) + Cần đàn (bamboo rod curving up)
##   RIGHT end: Chốt dây (tuning peg)
##   Top surface: light oak soundboard with floral carvings
##   Sides: dark walnut lacquer

signal string_plucked(idx: int, note_name: String)
signal pitch_bent(cents_offset: float)

const NODE_COUNT := 7
const NOTES_VN : Array[String] = ["Đô", "Rê", "Mi", "Fa", "Sol", "La", "Si"]

# ─── Color Palette (from concept sheet) ────────────────────────────────────
# Body / sides — dark walnut
const C_WALNUT_DARK  := Color("#2a1608")
const C_WALNUT_MID   := Color("#3d2010")
const C_WALNUT_LIGHT := Color("#5c3018")
const C_WALNUT_HIGH  := Color("#7a4820")
# Soundboard — light oak
const C_OAK_BASE     := Color("#c08840")
const C_OAK_MID      := Color("#d4a050")
const C_OAK_LIGHT    := Color("#e8c070")
const C_OAK_HIGH     := Color("#f5d890")
# Floral inlay — warm gold
const C_INLAY_GOLD   := Color("#c8941c")
const C_INLAY_LIGHT  := Color("#f0c840")
# Gourd — brown lacquer
const C_GOURD_DARK   := Color("#3a1c0a")
const C_GOURD_MID    := Color("#5c3010")
const C_GOURD_LIGHT  := Color("#8a5020")
const C_GOURD_HIGH   := Color("#b87030")
# Bamboo rod
const C_BAMBOO_DARK  := Color("#4a4018")
const C_BAMBOO_MID   := Color("#6a5c28")
const C_BAMBOO_LIGHT := Color("#8a7a40")
# Gold trim / hardware
const C_GOLD         := Color("#c99a3c")
const C_GOLD_LIGHT   := Color("#fce8b3")
const C_GOLD_DARK    := Color("#7a5510")
# Metal string
const C_STRING       := Color("#c8ccd8")
const C_STRING_VIBE  := Color("#f8e898")

# ─── State ──────────────────────────────────────────────────────────────────
var _note_names  : Array[String]      = []
var _streams     : Array              = []
var _freqs       : Array[float]       = []
var _pluck_amp   : float              = 0.0
var _pluck_time  : float              = 0.0
var _glow_alpha  : PackedFloat32Array = PackedFloat32Array()
var _pulse_phase : float              = 0.0
var _is_target   : PackedByteArray    = PackedByteArray()
var _is_bending    := false
var _bend_offset   := 0.0   # rod tip Y offset
var _bend_cents    := 0.0
var _bend_velocity := 0.0
var _hovered_node_idx := -1
var _target_node_idx  := 0

func init(notes: Array[String], streams: Array, freqs: Array[float]) -> void:
	_note_names = notes; _streams = streams; _freqs = freqs
	_glow_alpha.resize(NODE_COUNT); _is_target.resize(NODE_COUNT)
	for i in NODE_COUNT: _glow_alpha[i] = 0.0; _is_target[i] = 0
	queue_redraw()

func _ready() -> void:
	resized.connect(queue_redraw)
	mouse_filter = MOUSE_FILTER_STOP
	queue_redraw()

func set_target(idx: int) -> void:
	_target_node_idx = idx
	for i in NODE_COUNT: _is_target[i] = 1 if i == idx else 0
	queue_redraw()

func pluck(idx: int) -> void:
	if idx < 0 or idx >= NODE_COUNT: return
	_pluck_time = 0.0; _pluck_amp = 1.0; _glow_alpha[idx] = 1.0
	string_plucked.emit(idx, _note_names[idx] if idx < _note_names.size() else NOTES_VN[idx])
	queue_redraw()

func _process(delta: float) -> void:
	var need := false
	if _pluck_amp > 0.0:
		_pluck_time += delta; _pluck_amp = maxf(0.0, _pluck_amp - delta * 2.5); need = true
	for i in NODE_COUNT:
		if _glow_alpha[i] > 0.0:
			_glow_alpha[i] = maxf(0.0, _glow_alpha[i] - delta * 3.0); need = true
	_pulse_phase += delta * 3.5; need = true
	if not _is_bending and (_bend_offset != 0.0 or _bend_velocity != 0.0):
		var accel := -420.0 * _bend_offset - 15.0 * _bend_velocity
		_bend_velocity += accel * delta; _bend_offset += _bend_velocity * delta
		if abs(_bend_offset) < 0.05 and abs(_bend_velocity) < 0.05:
			_bend_offset = 0.0; _bend_velocity = 0.0; _bend_cents = 0.0
			pitch_bent.emit(0.0)
		else:
			_bend_cents = (_bend_offset / maxf(size.y * 0.12, 10.0)) * 350.0
			pitch_bent.emit(_bend_cents)
		need = true
	if need: queue_redraw()

# ════════════════════════════════════════════════════════════════════════════
# MAIN DRAW  —  Wide-short canvas (typical ~870 × 180 px)
# ════════════════════════════════════════════════════════════════════════════
func _draw() -> void:
	var W := size.x; var H := size.y
	if W < 120.0 or H < 50.0: return

	# ── Key dimensions ────────────────────────────────────────────────────
	# Body rectangle on screen (main wooden box)
	var BL := W * 0.18     # body left  — leaves room for gourd on LEFT
	var BR := W * 0.96     # body right — tuning peg here
	var BW := BR - BL

	# 2.5D perspective layers (top-to-bottom in canvas):
	#   TOP_Y  = top edge of soundboard (far edge)
	#   MID_Y  = boundary soundboard → front side panel
	#   BOT_Y  = bottom of front side panel
	var TOP_Y := H * 0.05
	var MID_Y := H * 0.52
	var BOT_Y := H * 0.88

	var TOP_H := MID_Y - TOP_Y   # soundboard visible height
	var FRT_H := BOT_Y - MID_Y   # front panel visible height

	# String sits on the soundboard surface
	var STR_Y := TOP_Y + TOP_H * 0.55   # Y of the single monochord string

	# Gourd center (LEFT side, partially outside body)
	var GR    := minf(H * 0.30, BW * 0.10)  # gourd radius
	var GX    := BL - GR * 0.55             # gourd center X (overlaps left end)
	var GY    := MID_Y - TOP_H * 0.30       # gourd center Y (on soundboard level)

	# Bamboo rod: emerges from top of gourd, curves upward and slightly RIGHT
	var ROD_BASE := Vector2(GX, GY - GR * 0.85)
	var ROD_TIP  := Vector2(GX + W * 0.06, TOP_Y - H * 0.08 + _bend_offset)
	var ROD_C1   := Vector2(GX + GR * 0.20, ROD_BASE.y - TOP_H * 0.55)
	var ROD_C2   := Vector2(ROD_TIP.x - GR * 0.30, ROD_TIP.y + TOP_H * 0.30)

	# String anchors
	var STR_START := Vector2(GX,        GY)          # string starts at gourd surface
	var STR_END   := Vector2(BR - 6.0,  STR_Y)       # string ends at tuning peg

	# Tuning peg (right end)
	var PEG_X := BR - 4.0
	var PEG_Y := STR_Y

	# ── Draw order ────────────────────────────────────────────────────────
	_draw_ground_shadow(BL, BR, BOT_Y)
	_draw_feet(BL, BR, BOT_Y)
	_draw_front_panel(BL, BR, MID_Y, BOT_Y)
	_draw_soundboard(BL, BR, TOP_Y, MID_Y)
	_draw_side_bevels(BL, BR, TOP_Y, MID_Y, BOT_Y)
	_draw_gold_trim(BL, BR, TOP_Y, MID_Y, BOT_Y)
	_draw_floral_inlay(BL, BR, TOP_Y, MID_Y, STR_Y)
	_draw_bridge(BL + BW * 0.50, STR_Y, MID_Y)
	_draw_string(STR_START, STR_END, STR_Y)
	_draw_nodes(STR_Y, BL, BR, STR_START.x, STR_END.x)
	_draw_gourd(GX, GY, GR)
	_draw_bamboo_rod(ROD_BASE, ROD_TIP, ROD_C1, ROD_C2, GR)
	_draw_tuning_peg(PEG_X, PEG_Y, TOP_Y, MID_Y)
	var font := get_theme_font("font")
	if _is_bending and font:
		_draw_cents_badge(font, ROD_TIP + Vector2(16, 0), _bend_cents)

# ════════════════════════════════════════════════════════════════════════════
# BODY COMPONENTS
# ════════════════════════════════════════════════════════════════════════════

func _draw_ground_shadow(BL: float, BR: float, BOT_Y: float) -> void:
	var sx := PackedVector2Array([
		Vector2(BL - 18, BOT_Y + 4), Vector2(BR + 12, BOT_Y + 4),
		Vector2(BR - 4,  BOT_Y + 16), Vector2(BL - 6,  BOT_Y + 16)
	])
	draw_colored_polygon(sx, Color(0, 0, 0, 0.22))

func _draw_feet(BL: float, BR: float, BOT_Y: float) -> void:
	# Small wooden feet below the body (visible in concept art)
	var foot_h : float = (BOT_Y) * 0.08
	var foot_w : float = (BR - BL) * 0.10
	var positions : Array[float] = [0.12, 0.50, 0.88]
	for p in positions:
		var fx : float = BL + (BR - BL) * p
		var foot_pts := PackedVector2Array([
			Vector2(fx - foot_w * 0.5, BOT_Y),
			Vector2(fx + foot_w * 0.5, BOT_Y),
			Vector2(fx + foot_w * 0.4, BOT_Y + foot_h),
			Vector2(fx - foot_w * 0.4, BOT_Y + foot_h)
		])
		draw_colored_polygon(foot_pts, C_WALNUT_DARK)
		draw_line(Vector2(fx - foot_w*0.5, BOT_Y), Vector2(fx + foot_w*0.5, BOT_Y),
			Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35), 0.8)

func _draw_front_panel(BL: float, BR: float, MID_Y: float, BOT_Y: float) -> void:
	# Front side panel — dark walnut with slight gradient
	var FH := BOT_Y - MID_Y
	var steps := 14
	for i in steps:
		var r1 : float = float(i) / float(steps)
		var r2 : float = float(i + 1) / float(steps)
		var y1 := lerpf(MID_Y, BOT_Y, r1)
		var y2 := lerpf(MID_Y, BOT_Y, r2)
		var col := C_WALNUT_DARK
		# Slight highlight at top, darkens toward bottom
		if r1 < 0.12: col = col.lerp(C_WALNUT_MID, (0.12 - r1) / 0.12 * 0.55)
		elif r1 > 0.75: col = col.lerp(Color("#0a0503"), (r1 - 0.75) / 0.25)
		draw_colored_polygon(PackedVector2Array([
			Vector2(BL, y1), Vector2(BR, y1), Vector2(BR, y2), Vector2(BL, y2)
		]), col)

	# Wood grain lines on front panel
	var rng := RandomNumberGenerator.new()
	rng.seed = 77331
	for _j in range(5):
		var f : float = rng.randf()
		var gy := lerpf(MID_Y + FH * 0.1, BOT_Y - FH * 0.1, f)
		var pts := PackedVector2Array()
		for k in range(18):
			var t : float = float(k) / 17.0
			var gx := lerpf(BL + 8, BR - 8, t)
			var wy := gy + sin(t * 9.0 + f * 5.0) * 0.8
			pts.append(Vector2(gx, wy))
		var gc := C_WALNUT_DARK.lerp(C_WALNUT_MID, f * 0.5)
		gc.a = rng.randf_range(0.06, 0.14)
		draw_polyline(pts, gc, 0.7, true)

func _draw_soundboard(BL: float, BR: float, TOP_Y: float, MID_Y: float) -> void:
	# Light oak soundboard — the top playing surface (most distinctive visual feature)
	var TOP_H := MID_Y - TOP_Y
	var steps  := 20
	for i in steps:
		var r1 : float = float(i)     / float(steps)
		var r2 : float = float(i + 1) / float(steps)
		var y1 := lerpf(TOP_Y, MID_Y, r1)
		var y2 := lerpf(TOP_Y, MID_Y, r2)
		# Oak grain: brightest in center strip
		var light := sin(r1 * PI)
		var col   := C_OAK_BASE.lerp(C_OAK_LIGHT, light * 0.75)
		if r1 < 0.08: col = col.lerp(C_WALNUT_MID, 0.45)       # shadow from top bevel
		elif r1 > 0.82: col = col.lerp(C_OAK_BASE, (r1 - 0.82) / 0.18 * 0.40)
		draw_colored_polygon(PackedVector2Array([
			Vector2(BL, y1), Vector2(BR, y1), Vector2(BR, y2), Vector2(BL, y2)
		]), col)
	# Wood grain on soundboard
	var rng := RandomNumberGenerator.new()
	rng.seed = 44210
	for _j in range(12):
		var f : float = rng.randf()
		var gy := lerpf(TOP_Y + 2, MID_Y - 2, f)
		var pts := PackedVector2Array()
		for k in range(22):
			var t : float = float(k) / 21.0
			var gx := lerpf(BL + 4, BR - 4, t)
			var wy := gy + sin(t * 13.0 + f * 7.0) * 1.2 + cos(t * 5.0) * 0.7
			pts.append(Vector2(gx, wy))
		var gc := C_OAK_BASE.lerp(C_OAK_MID, f)
		gc.a = rng.randf_range(0.08, 0.22)
		draw_polyline(pts, gc, rng.randf_range(0.5, 1.2), true)

func _draw_side_bevels(BL: float, BR: float, TOP_Y: float, MID_Y: float, BOT_Y: float) -> void:
	# Left end cap
	draw_colored_polygon(PackedVector2Array([
		Vector2(BL - 6, TOP_Y + 2), Vector2(BL, TOP_Y),
		Vector2(BL, BOT_Y),         Vector2(BL - 6, BOT_Y - 2)
	]), C_WALNUT_DARK.lerp(Color("#0a0503"), 0.30))
	# Right end cap
	draw_colored_polygon(PackedVector2Array([
		Vector2(BR, TOP_Y),     Vector2(BR + 6, TOP_Y + 2),
		Vector2(BR + 6, BOT_Y - 2), Vector2(BR, BOT_Y)
	]), C_WALNUT_DARK.lerp(Color("#0a0503"), 0.30))

func _draw_gold_trim(BL: float, BR: float, TOP_Y: float, MID_Y: float, BOT_Y: float) -> void:
	var g  := Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.85)
	var gd := Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45)

	# Main border lines
	draw_line(Vector2(BL, TOP_Y),  Vector2(BR, TOP_Y),  g,  1.5)  # top far edge
	draw_line(Vector2(BL, MID_Y), Vector2(BR, MID_Y),   g,  1.2)  # soundboard edge
	draw_line(Vector2(BL, BOT_Y), Vector2(BR, BOT_Y),   gd, 1.0)  # bottom

	# Inner frame on soundboard (inset border)
	var inset : float = minf((MID_Y - TOP_Y) * 0.10, 5.0)
	draw_polyline(PackedVector2Array([
		Vector2(BL + 12, TOP_Y + inset),
		Vector2(BR - 12, TOP_Y + inset),
		Vector2(BR - 12, MID_Y - inset),
		Vector2(BL + 12, MID_Y - inset),
		Vector2(BL + 12, TOP_Y + inset)
	]), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.40), 0.8, true)

	# Inner frame on front panel
	var f_inset : float = minf((BOT_Y - MID_Y) * 0.12, 5.0)
	draw_polyline(PackedVector2Array([
		Vector2(BL + 10, MID_Y + f_inset),
		Vector2(BR - 10, MID_Y + f_inset),
		Vector2(BR - 10, BOT_Y - f_inset),
		Vector2(BL + 10, BOT_Y - f_inset),
		Vector2(BL + 10, MID_Y + f_inset)
	]), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35), 0.8, true)

	# Corner brass rivets
	var rs : float = minf(14.0, (MID_Y - TOP_Y) * 0.25)
	_rivet(Vector2(BL, TOP_Y),  rs, false, false)
	_rivet(Vector2(BR, TOP_Y),  rs, true,  false)
	_rivet(Vector2(BL, BOT_Y),  rs, false, true)
	_rivet(Vector2(BR, BOT_Y),  rs, true,  true)

func _rivet(pos: Vector2, s: float, fx: bool, fy: bool) -> void:
	var sx := -1.0 if fx else 1.0; var sy := -1.0 if fy else 1.0
	draw_colored_polygon(PackedVector2Array([
		pos, pos + Vector2(sx*s, 0),
		pos + Vector2(sx*s*0.55, sy*s*0.55), pos + Vector2(0, sy*s)
	]), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.70))
	var rv := pos + Vector2(sx*s*0.35, sy*s*0.35)
	draw_circle(rv, 1.8, Color(0.12, 0.06, 0.0, 0.90))
	draw_circle(rv, 0.8, Color(1, 0.95, 0.7, 0.50))

func _draw_floral_inlay(BL: float, BR: float, TOP_Y: float, MID_Y: float, STR_Y: float) -> void:
	# Golden floral carvings on the oak soundboard
	# Inspired by concept sheet: lotus + vines running along the length
	var BW := BR - BL
	var cy := (TOP_Y + MID_Y) * 0.5
	var fh := (MID_Y - TOP_Y) * 0.32  # floral pattern height

	# Central lotus flower cluster
	_floral_lotus(BL + BW * 0.50, cy, fh, C_INLAY_GOLD)
	# Side vine scrolls
	_floral_vine_left(BL  + BW * 0.10, BL + BW * 0.44, cy, fh)
	_floral_vine_right(BL + BW * 0.56, BL + BW * 0.90, cy, fh)
	# Small accent lotuses
	_floral_lotus(BL + BW * 0.22, cy, fh * 0.62, Color(C_INLAY_GOLD.r, C_INLAY_GOLD.g, C_INLAY_GOLD.b, 0.65))
	_floral_lotus(BL + BW * 0.78, cy, fh * 0.62, Color(C_INLAY_GOLD.r, C_INLAY_GOLD.g, C_INLAY_GOLD.b, 0.65))

func _floral_lotus(cx: float, cy: float, size: float, col: Color) -> void:
	# Central circle
	draw_circle(Vector2(cx, cy), size * 0.18, Color(col.r, col.g, col.b, col.a * 0.80))
	draw_circle(Vector2(cx, cy), size * 0.10, col)
	# Six petals
	for pi in range(6):
		var rad := deg_to_rad(float(pi) * 60.0)
		var px  := cx + cos(rad) * size * 0.28
		var py  := cy + sin(rad) * size * 0.28
		draw_circle(Vector2(px, py), size * 0.12, Color(col.r, col.g, col.b, col.a * 0.75))
		draw_circle(Vector2(px, py), size * 0.06, col)
	# Outer ring
	draw_arc(Vector2(cx, cy), size * 0.44, 0.0, TAU, 24,
		Color(col.r, col.g, col.b, col.a * 0.45), 0.8)

func _floral_vine_left(x0: float, x1: float, cy: float, fh: float) -> void:
	# Winding vine from left toward center
	var col := Color(C_INLAY_GOLD.r, C_INLAY_GOLD.g, C_INLAY_GOLD.b, 0.50)
	var pts := PackedVector2Array()
	var steps := 20
	for k in range(steps + 1):
		var t : float = float(k) / float(steps)
		var vx := lerpf(x0, x1, t)
		var vy := cy + sin(t * TAU * 1.5) * fh * 0.45
		pts.append(Vector2(vx, vy))
	draw_polyline(pts, col, 1.0, true)
	# Leaf buds along vine
	for k in range(0, steps + 1, 5):
		var t : float = float(k) / float(steps)
		var vx : float = lerpf(x0, x1, t)
		var vy : float = cy + sin(t * TAU * 1.5) * fh * 0.45
		draw_circle(Vector2(vx, vy), fh * 0.09, Color(col.r, col.g, col.b, 0.65))

func _floral_vine_right(x0: float, x1: float, cy: float, fh: float) -> void:
	var col := Color(C_INLAY_GOLD.r, C_INLAY_GOLD.g, C_INLAY_GOLD.b, 0.50)
	var pts := PackedVector2Array()
	var steps := 20
	for k in range(steps + 1):
		var t : float = float(k) / float(steps)
		var vx := lerpf(x0, x1, t)
		var vy := cy + sin(t * TAU * 1.5 + PI) * fh * 0.45
		pts.append(Vector2(vx, vy))
	draw_polyline(pts, col, 1.0, true)
	for k in range(0, steps + 1, 5):
		var t : float = float(k) / float(steps)
		var vx : float = lerpf(x0, x1, t)
		var vy : float = cy + sin(t * TAU * 1.5 + PI) * fh * 0.45
		draw_circle(Vector2(vx, vy), fh * 0.09, Color(col.r, col.g, col.b, 0.65))

func _draw_bridge(bx: float, str_y: float, mid_y: float) -> void:
	# Ngựa đàn — small bridge piece sitting on soundboard holding the string up
	var bw : float = size.x * 0.015
	var bh : float = (mid_y - str_y) * 0.55
	draw_colored_polygon(PackedVector2Array([
		Vector2(bx - bw, str_y), Vector2(bx + bw, str_y),
		Vector2(bx + bw * 0.7, mid_y - (mid_y - str_y) * 0.08),
		Vector2(bx - bw * 0.7, mid_y - (mid_y - str_y) * 0.08)
	]), C_WALNUT_MID)
	draw_line(Vector2(bx - bw, str_y), Vector2(bx + bw, str_y),
		Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.60), 1.0)

# ════════════════════════════════════════════════════════════════════════════
# STRING & NODES
# ════════════════════════════════════════════════════════════════════════════

func _draw_string(str_start: Vector2, str_end: Vector2, str_y: float) -> void:
	var pts := PackedVector2Array()
	pts.append(str_start)
	if _pluck_amp > 0.005:
		for k in range(1, 36):
			var ratio : float = float(k) / 36.0
			var px    : float = lerpf(str_start.x, str_end.x, ratio)
			var py    : float = lerpf(str_start.y, str_end.y, ratio)
			var decay : float = exp(-_pluck_time * 1.8)
			var osc   : float = sin(ratio * PI) * sin(ratio * PI * 5.0 - _pluck_time * 85.0) * _pluck_amp * 6.5 * decay
			pts.append(Vector2(px, py + osc))
	pts.append(str_end)
	# Shadow
	var shd := PackedVector2Array()
	for pt in pts: shd.append(pt + Vector2(0, 2.5))
	draw_polyline(shd, Color(0, 0, 0, 0.30), 1.2, true)
	# Vibration glow
	if _pluck_amp > 0.01:
		draw_polyline(pts, Color(C_STRING_VIBE.r, C_STRING_VIBE.g, C_STRING_VIBE.b, _pluck_amp * 0.55), 4.5, true)
	# String core
	var sc := C_STRING_VIBE if _pluck_amp > 0.12 else C_STRING
	if _is_bending: sc = Color("#fc882b")
	draw_polyline(pts, sc, 1.5, true)

func _draw_nodes(str_y: float, BL: float, BR: float, sx: float, ex: float) -> void:
	var font    := get_theme_font("font")
	# Distribute 7 nodes along the string between sx and ex, skipping gourd area
	var START_X : float = maxf(sx + (ex - sx) * 0.03, BL + (BR - BL) * 0.04)
	var END_X   : float = ex - (ex - sx) * 0.03
	var STEP_X  : float = (END_X - START_X) / float(NODE_COUNT - 1)
	for i in NODE_COUNT:
		var nx : float = START_X + float(i) * STEP_X
		_draw_node(Vector2(nx, str_y), i, _is_target[i] == 1, _hovered_node_idx == i, _glow_alpha[i], font)

func _draw_node(pos: Vector2, idx: int, is_tgt: bool, is_hov: bool, glow: float, font: Font) -> void:
	draw_circle(pos + Vector2(0, 2.5), 11.5, Color(0, 0, 0, 0.30))
	# Target pulse
	if is_tgt:
		var p := (sin(_pulse_phase * 2.0) + 1.0) * 0.5
		draw_circle(pos, 16.0 + p*5.0, Color(0.79, 0.60, 0.24, 0.12 + p*0.12))
		draw_arc(pos, 16.0 + p*5.0, 0.0, TAU, 28, Color(0.79, 0.60, 0.24, 0.38 + p*0.25), 1.3)
	# Pluck glow
	if glow > 0.01:
		draw_circle(pos, 11.0 + glow*20.0, Color(1, 0.95, 0.75, glow*0.44))
		draw_arc(pos, 11.0 + glow*20.0, 0.0, TAU, 24, Color(1, 0.9, 0.5, glow*0.54), 1.5)
	var R : float = 9.5 + (1.5 if is_hov else (1.0 if is_tgt else 0.0))
	draw_circle(pos, R,       C_GOLD)
	draw_circle(pos, R - 1.6, Color("#faf5e6"))
	draw_circle(pos, R - 4.0, C_GOLD)
	draw_circle(pos, R - 6.0, C_WALNUT_DARK)
	draw_circle(pos, 1.2, Color(1, 1, 1, 0.80))
	if font != null:
		var text  := _note_names[idx] if idx < _note_names.size() else NOTES_VN[idx]
		var fsz   := 13 if (is_tgt or is_hov) else 11
		var tcol  := Color("#faf6eb") if is_tgt else (Color.WHITE if is_hov else Color("#c8b090"))
		var ts    := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, fsz)
		var tp    := Vector2(pos.x - ts.x * 0.5, pos.y - R - 7.0)
		draw_string(font, tp + Vector2(1,1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, Color(0,0,0,0.70))
		draw_string(font, tp, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, tcol)

# ════════════════════════════════════════════════════════════════════════════
# GOURD (BẦU CỘNG HƯỞNG) — LEFT SIDE, SPHERICAL
# ════════════════════════════════════════════════════════════════════════════

func _draw_gourd(GX: float, GY: float, GR: float) -> void:
	# Single round gourd (brown lacquered) — Bầu cộng hưởng
	# Per concept sheet: spherical, sits at left end, bamboo rod emerges from top

	# Drop shadow
	draw_circle(Vector2(GX + 3, GY + 5), GR + 3, Color(0, 0, 0, 0.35))

	# 3D sphere shading — dark brown lacquer
	var steps := 24
	for i in range(steps):
		var r_ratio : float = float(steps - i) / float(steps)
		var r       : float = GR * r_ratio
		var offset  := Vector2(-0.8, -0.8) * (1.0 - r_ratio)
		var col : Color = C_GOURD_DARK.lerp(C_GOURD_LIGHT, r_ratio * 0.85)
		if r_ratio > 0.75: col = col.lerp(C_GOURD_HIGH, (r_ratio - 0.75) / 0.25 * 0.60)
		draw_circle(Vector2(GX, GY) + offset, r, col)

	# Primary specular highlight (top-left)
	draw_circle(Vector2(GX - GR*0.30, GY - GR*0.32), GR * 0.13, Color(1, 1, 1, 0.72))
	draw_circle(Vector2(GX - GR*0.18, GY - GR*0.20), GR * 0.06, Color(1, 1, 1, 0.50))

	# Decorative ring grooves (typical on Vietnamese lacquerware)
	draw_arc(Vector2(GX, GY), GR * 0.70, 0.0, TAU, 28,
		Color(C_GOURD_DARK.r, C_GOURD_DARK.g, C_GOURD_DARK.b, 0.55), 1.2)
	draw_arc(Vector2(GX, GY), GR * 0.50, 0.0, TAU, 24,
		Color(C_GOURD_DARK.r, C_GOURD_DARK.g, C_GOURD_DARK.b, 0.40), 0.8)

	# Small decorative floral accent on front face
	for fi in range(4):
		var ang : float = deg_to_rad(float(fi) * 90.0 + 45.0)
		draw_circle(
			Vector2(GX + cos(ang) * GR*0.52, GY + sin(ang) * GR*0.52),
			GR * 0.06, Color(C_GOURD_HIGH.r, C_GOURD_HIGH.g, C_GOURD_HIGH.b, 0.55))

	# Metal ring collar where gourd meets body (brass fitting)
	var collar_y := GY + GR * 0.72
	for ci in range(7):
		var r_ratio : float = float(7 - ci) / 7.0
		var r       : float = GR * 0.24 * r_ratio
		draw_circle(Vector2(GX, collar_y) + Vector2(-r_ratio, -r_ratio) * 0.4,
			r, C_GOLD_DARK.lerp(C_GOLD, r_ratio))
	draw_circle(Vector2(GX - GR*0.08, collar_y - GR*0.09), GR*0.07, Color(1,1,1,0.45))

# ════════════════════════════════════════════════════════════════════════════
# BAMBOO ROD (CẦN ĐÀN) — emerges from gourd top, curves up-right
# ════════════════════════════════════════════════════════════════════════════

func _draw_bamboo_rod(BASE: Vector2, TIP: Vector2, C1: Vector2, C2: Vector2, GR: float) -> void:
	# Bamboo rod — thin, natural bamboo color, with knot nodes along its length
	var seg := 30
	var pts := PackedVector2Array()
	for k in range(seg + 1):
		var t : float = float(k) / float(seg)
		pts.append(_cbez(BASE, C1, C2, TIP, t))

	# Shadow
	var shd := PackedVector2Array()
	for pt in pts: shd.append(pt + Vector2(2, 3))
	for k in range(seg):
		var t : float = float(k) / float(seg)
		draw_line(shd[k], shd[k+1], Color(0, 0, 0, 0.20), lerpf(7.0, 2.0, t), true)

	# Rod body — bamboo gradient (slightly lighter in center of cylinder)
	for k in range(seg):
		var t  : float = float(k) / float(seg)
		var th : float = lerpf(7.0, 1.8, t)
		var col := C_BAMBOO_DARK.lerp(C_BAMBOO_MID, 0.40 + 0.30 * sin(t * PI))
		draw_line(pts[k], pts[k+1], col, th, true)
		if k == 0: draw_circle(pts[k], th * 0.5, col)

	# Bamboo knot rings (characteristic feature of bamboo rods)
	var knot_positions : Array[float] = [0.28, 0.52, 0.72]
	for kp in knot_positions:
		var ki := int(kp * float(seg))
		if ki < pts.size():
			var t  : float = kp
			var th : float = lerpf(7.0, 1.8, t)
			# Dark ring at knot
			draw_circle(pts[ki], th * 0.72, C_BAMBOO_DARK)
			draw_circle(pts[ki], th * 0.55, C_BAMBOO_MID)
			# Slight specular at knot
			draw_circle(pts[ki] + Vector2(-th*0.15, -th*0.15), th * 0.18, Color(1,1,1,0.30))

	# Specular highlight along rod
	for k in range(seg):
		var t   : float = float(k) / float(seg)
		var th  : float = lerpf(7.0, 1.8, t)
		var so  := Vector2(-th*0.16, -th*0.16)
		draw_line(pts[k] + so, pts[k+1] + so,
			Color(C_BAMBOO_LIGHT.r, C_BAMBOO_LIGHT.g, C_BAMBOO_LIGHT.b, 0.28 * (1.0 - t * 0.5)),
			th * 0.20, true)

	# Tip of rod (thin pointed end)
	draw_circle(TIP, 1.5, C_BAMBOO_DARK)

	# String attachment wrap at base (where rod inserts into gourd top)
	var wrap := BASE + Vector2(0, GR * 0.05)
	draw_arc(wrap, GR * 0.16, 0.0, TAU, 12, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.65), 1.5)
	draw_arc(wrap - Vector2(0, GR*0.05), GR * 0.14, 0.0, TAU, 10, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.50), 1.2)

# ════════════════════════════════════════════════════════════════════════════
# TUNING PEG (CHỐT DÂY) — RIGHT END
# ════════════════════════════════════════════════════════════════════════════

func _draw_tuning_peg(px: float, py: float, TOP_Y: float, MID_Y: float) -> void:
	# Chốt dây: small cylindrical metal tuning peg on the right end
	var ph : float = (MID_Y - TOP_Y) * 0.60

	# Peg mount block
	draw_colored_polygon(PackedVector2Array([
		Vector2(px - 7, py - 4), Vector2(px + 2, py - 4),
		Vector2(px + 2, py + 4), Vector2(px - 7, py + 4)
	]), C_WALNUT_MID)
	draw_colored_polygon(PackedVector2Array([
		Vector2(px - 5, py - 2.5), Vector2(px + 0.5, py - 2.5),
		Vector2(px + 0.5, py + 2.5), Vector2(px - 5, py + 2.5)
	]), C_WALNUT_LIGHT)

	# Vertical pin shaft
	draw_line(Vector2(px - 2.5, py - ph*0.3), Vector2(px - 2.5, py - ph - 3),
		Color("#4a4030"), 3.5)
	draw_line(Vector2(px - 2.5, py - ph*0.3), Vector2(px - 2.5, py - ph - 3),
		Color("#6a5c40"), 1.5)

	# Peg knob — spherical, dark wood + gold accent
	var kc := Vector2(px - 2.5, py - ph - 3)
	for i in range(10):
		var r_ratio : float = float(10 - i) / 10.0
		var r       : float = 5.5 * r_ratio
		var col     : Color = C_WALNUT_DARK.lerp(C_WALNUT_MID, r_ratio * 0.70)
		if r_ratio > 0.80: col = col.lerp(C_WALNUT_HIGH, (r_ratio-0.80)/0.20*0.60)
		draw_circle(kc + Vector2(-r_ratio*0.6, -r_ratio*0.6)*0.5, r, col)
	draw_circle(kc + Vector2(-1.5, -1.8), 1.3, Color(1, 1, 1, 0.42))

	# Gold collar ring at base of peg
	draw_arc(Vector2(px - 2.5, py), 5.0, 0.0, TAU, 14,
		Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.70), 1.3)

# ════════════════════════════════════════════════════════════════════════════
# CENTS READOUT BADGE
# ════════════════════════════════════════════════════════════════════════════

func _draw_cents_badge(font: Font, pos: Vector2, cents: float) -> void:
	if font == null: return
	var sign := "+" if cents > 0 else ""
	var txt  := "%s%d ¢" % [sign, int(cents)]
	var col  := C_GOLD
	if cents > 5.0:    col = Color("#2ecc71")
	elif cents < -5.0: col = Color("#e74c3c")
	var ts := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 13)
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(0.06, 0.03, 0.01, 0.90)
	bs.border_color = Color(col.r, col.g, col.b, 0.55)
	bs.border_width_left = 1; bs.border_width_right = 1
	bs.border_width_top  = 1; bs.border_width_bottom = 1
	bs.corner_radius_top_left = 7; bs.corner_radius_top_right = 7
	bs.corner_radius_bottom_left = 7; bs.corner_radius_bottom_right = 7
	var bw := ts.x + 14.0; var bh := ts.y + 4.0
	draw_style_box(bs, Rect2(pos.x - bw*0.5, pos.y - bh*0.5, bw, bh))
	draw_string(font, pos + Vector2(-ts.x*0.5, ts.y*0.5 - 2),
		txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col)

func _cbez(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	return u*u*u*p0 + 3.0*u*u*t*p1 + 3.0*u*t*t*p2 + t*t*t*p3

# ════════════════════════════════════════════════════════════════════════════
# INPUT
# ════════════════════════════════════════════════════════════════════════════

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
	# Bend zone: LEFT 20% (near the gourd and rod)
	if pos.x < size.x * 0.20:
		_is_bending = true
		_update_bend(pos.y)
	else:
		var ni := _node_at(pos)
		if ni != -1: pluck(ni)

func _touch_move(pos: Vector2) -> void:
	if _is_bending: _update_bend(pos.y)
	else:
		var ni := _node_at(pos)
		if ni != _hovered_node_idx:
			_hovered_node_idx = ni; queue_redraw()

func _touch_end() -> void:
	_is_bending = false; _hovered_node_idx = -1; queue_redraw()

func _node_at(pos: Vector2) -> int:
	var W      := size.x; var H := size.y
	var BL     : float = W * 0.18; var BR : float = W * 0.96
	var TOP_Y  : float = H * 0.05; var MID_Y : float = H * 0.52
	var GR     : float = minf(H * 0.30, (BR - BL) * 0.10)
	var GX     : float = BL - GR * 0.55
	var GY     : float = MID_Y - (MID_Y - TOP_Y) * 0.30
	var STR_Y  : float = TOP_Y + (MID_Y - TOP_Y) * 0.55
	var sx     : float = GX
	var ex     : float = BR - 6.0
	var START_X: float = maxf(sx + (ex - sx) * 0.03, BL + (BR - BL) * 0.04)
	var END_X  : float = ex - (ex - sx) * 0.03
	var STEP_X : float = (END_X - START_X) / float(NODE_COUNT - 1)
	for i in NODE_COUNT:
		var nx : float = START_X + float(i) * STEP_X
		if pos.distance_to(Vector2(nx, STR_Y)) <= 28.0: return i
	return -1

func _update_bend(ty: float) -> void:
	var mid_y : float = size.y * 0.20
	var max_d : float = size.y * 0.12
	_bend_offset   = clampf(ty - mid_y, -max_d, max_d)
	_bend_velocity = 0.0
	_bend_cents    = (_bend_offset / max_d) * 350.0
	pitch_bent.emit(_bend_cents)
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_hovered_node_idx = -1
		if _is_bending: _touch_end()
		queue_redraw()
