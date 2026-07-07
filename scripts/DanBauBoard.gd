extends Control

## DanBauBoard — Vietnamese Monochord (Đàn Bầu) 2.5D Renderer
## Layout: LEFT = tuning peg, RIGHT = gourd + horn (exactly as real instrument)
## Designed for wide-and-short canvas (aspect ~5:1 to 8:1)

signal string_plucked(idx: int, note_name: String)
signal pitch_bent(cents_offset: float)

const NODE_COUNT := 7
const NOTES_VN : Array[String] = ["Đô", "Rê", "Mi", "Fa", "Sol", "La", "Si"]

# ─── Color Palette ──────────────────────────────────────────────────────────
const C_GOLD        := Color("#c99a3c")
const C_GOLD_LIGHT  := Color("#fce8b3")
const C_GOLD_DARK   := Color("#7a5510")
const C_LACQUER     := Color("#0d0804")   # near-black lacquer body
const C_LACQUER2    := Color("#1a0d05")   # slightly lighter lacquer
const C_ROSEWOOD    := Color("#5c1f06")   # rosewood top surface
const C_ROSEWOOD2   := Color("#8c3510")   # lighter rosewood highlight
const C_HORN_DARK   := Color("#0c0a09")   # buffalo horn dark
const C_HORN_MID    := Color("#1e1814")   # horn mid-tone
const C_HORN_EDGE   := Color("#2e2420")   # horn edge highlight
const C_GOURD_BASE  := Color("#8c4a08")   # gourd dark base
const C_GOURD_MID   := Color("#c87818")   # gourd mid golden
const C_GOURD_HIGH  := Color("#f5d060")   # gourd specular
const C_MOP         := Color("#e8ede8")   # mother-of-pearl white
const C_MOP2        := Color("#a8d4cc")   # MOP teal iridescent
const C_STRING      := Color("#d8dce8")   # steel string

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
var _bend_offset   := 0.0
var _bend_cents    := 0.0
var _bend_velocity := 0.0
var _hovered_node_idx := -1
var _target_node_idx  := 0
var _active_player : AudioStreamPlayer = null

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
	_target_node_idx = idx
	for i in NODE_COUNT:
		_is_target[i] = 1 if i == idx else 0
	queue_redraw()

func pluck(idx: int) -> void:
	if idx < 0 or idx >= NODE_COUNT: return
	_pluck_time = 0.0
	_pluck_amp  = 1.0
	_glow_alpha[idx] = 1.0
	string_plucked.emit(idx, _note_names[idx] if idx < _note_names.size() else NOTES_VN[idx])
	queue_redraw()

func _process(delta: float) -> void:
	var need := false
	if _pluck_amp > 0.0:
		_pluck_time += delta
		_pluck_amp   = maxf(0.0, _pluck_amp - delta * 2.5)
		need = true
	for i in NODE_COUNT:
		if _glow_alpha[i] > 0.0:
			_glow_alpha[i] = maxf(0.0, _glow_alpha[i] - delta * 3.0)
			need = true
	_pulse_phase += delta * 3.5
	need = true
	# Spring physics for rod return
	if not _is_bending and (_bend_offset != 0.0 or _bend_velocity != 0.0):
		var accel := -420.0 * _bend_offset - 15.0 * _bend_velocity
		_bend_velocity += accel * delta
		_bend_offset   += _bend_velocity * delta
		if abs(_bend_offset) < 0.05 and abs(_bend_velocity) < 0.05:
			_bend_offset = 0.0; _bend_velocity = 0.0; _bend_cents = 0.0
			pitch_bent.emit(0.0)
		else:
			_bend_cents = (_bend_offset / (size.y * 0.12)) * 350.0
			pitch_bent.emit(_bend_cents)
		need = true
	if need: queue_redraw()

# ════════════════════════════════════════════════════════════════════════════
# MAIN DRAW
# ════════════════════════════════════════════════════════════════════════════
func _draw() -> void:
	var W := size.x
	var H := size.y
	if W < 100.0 or H < 40.0: return

	# ── Key geometry ──────────────────────────────────────────────────────
	# Body: horizontal rectangular box from BL to BR
	var BL := W * 0.06                  # body left X
	var BR := W * 0.82                  # body right X (leaves room for gourd)
	var BW := BR - BL                   # body width

	# 2.5D perspective: top surface visible above front face
	# TOP_Y = top edge of top surface (far edge)
	# MID_Y = edge between top surface and front face
	# BOT_Y = bottom of front face
	var TOP_Y := H * 0.06              # top surface top edge
	var MID_Y := H * 0.46             # boundary top↔front
	var BOT_Y := H * 0.88             # front face bottom

	var TOP_H := MID_Y - TOP_Y        # height of top surface
	var FRT_H := BOT_Y - MID_Y        # height of front face

	# String sits 60% into the top surface
	var STR_Y_L := TOP_Y + TOP_H * 0.60
	var STR_Y_R := TOP_Y + TOP_H * 0.64   # slight perspective drop right

	# ── Gourd and Horn positions ──────────────────────────────────────────
	var GOURD_CX := BR + H * 0.28          # gourd center X (right of body)
	var GOURD_CY := MID_Y - TOP_H * 0.25   # gourd center Y (on top surface)
	var GOURD_R  := H * 0.22               # gourd lower bulb radius — BIG

	# Horn base: top of the gourd
	var HORN_BASE := Vector2(GOURD_CX, GOURD_CY - GOURD_R - H * 0.04)
	# Horn tip: curves up and slightly left from base
	var HORN_TIP  := Vector2(GOURD_CX - H * 0.18 + _bend_offset, TOP_Y - H * 0.05)
	# Bezier control points
	var HORN_C1   := Vector2(GOURD_CX + H * 0.05, HORN_BASE.y - TOP_H * 0.60)
	var HORN_C2   := Vector2(HORN_TIP.x  + H * 0.08, HORN_TIP.y  + TOP_H * 0.40)

	# String anchor points
	var STR_START := Vector2(BL + 22.0, STR_Y_L)
	var STR_END   := Vector2(GOURD_CX,  GOURD_CY)

	# ── Draw Order ────────────────────────────────────────────────────────
	_draw_shadow(BL, BR, BOT_Y, W)
	_draw_top_surface(BL, BR, TOP_Y, MID_Y)
	_draw_front_face(BL, BR, MID_Y, BOT_Y)
	_draw_side_caps(BL, BR, TOP_Y, MID_Y, BOT_Y)
	_draw_gold_borders(BL, BR, TOP_Y, MID_Y, BOT_Y)
	_draw_mop_scenes(BL, BR, MID_Y, BOT_Y)
	_draw_peg(STR_START, TOP_Y, MID_Y)
	_draw_string(STR_START, STR_END, STR_Y_L, STR_Y_R, BL, BR)
	_draw_nodes(STR_Y_L, STR_Y_R, BL, BR)
	_draw_gourd(GOURD_CX, GOURD_CY, GOURD_R)
	_draw_horn(HORN_BASE, HORN_TIP, HORN_C1, HORN_C2)
	if _is_bending:
		var font := get_theme_font("font")
		_draw_cents_readout(font, HORN_TIP + Vector2(0, 16), _bend_cents)

# ════════════════════════════════════════════════════════════════════════════
# COMPONENT DRAWS
# ════════════════════════════════════════════════════════════════════════════

func _draw_shadow(BL: float, BR: float, BOT_Y: float, W: float) -> void:
	var shadow := PackedVector2Array([
		Vector2(BL - 12, BOT_Y + 4),
		Vector2(BR + 48, BOT_Y + 4),
		Vector2(BR + 28, BOT_Y + 14),
		Vector2(BL - 4,  BOT_Y + 14)
	])
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.20))

func _draw_top_surface(BL: float, BR: float, TOP_Y: float, MID_Y: float) -> void:
	# The playing surface — rosewood/mahogany with cylindrical shading
	var steps := 18
	for i in steps:
		var r1 := float(i)     / float(steps)
		var r2 := float(i + 1) / float(steps)
		var y1 := lerpf(TOP_Y, MID_Y, r1)
		var y2 := lerpf(TOP_Y, MID_Y, r2)
		# Cylindrical light: brightest at ~30% from top
		var light := sin(r1 * PI)
		var col   := C_LACQUER.lerp(C_ROSEWOOD2, light * 0.85)
		# Glossy specular stripe near top
		if r1 > 0.12 and r1 < 0.28:
			var f := (r1 - 0.12) / 0.16
			col = col.lerp(Color("#c06030"), sin(f * PI) * 0.55)
		# Shadow near front face edge
		elif r1 > 0.78:
			col = col.lerp(Color("#080301"), ((r1 - 0.78) / 0.22) * 0.70)
		draw_colored_polygon(PackedVector2Array([
			Vector2(BL, y1), Vector2(BR, y1), Vector2(BR, y2), Vector2(BL, y2)
		]), col)

	# Deterministic wood grain
	var rng := RandomNumberGenerator.new()
	rng.seed = 11223
	var BH := MID_Y - TOP_Y
	for _j in range(8):
		var f   := rng.randf()
		var gy  := TOP_Y + BH * f
		var pts := PackedVector2Array()
		for k in range(21):
			var t  := float(k) / 20.0
			var gx := lerpf(BL, BR, t)
			var wy := gy + sin(t * 11.0 + f * 6.0) * 1.4 + cos(t * 7.0) * 0.8
			pts.append(Vector2(gx, wy))
		var gc := C_LACQUER.lerp(C_ROSEWOOD, f)
		gc.a    = rng.randf_range(0.07, 0.20)
		draw_polyline(pts, gc, rng.randf_range(0.6, 1.6), true)

func _draw_front_face(BL: float, BR: float, MID_Y: float, BOT_Y: float) -> void:
	# Front face: near-BLACK lacquer — the most visible face of the body
	var FH    := BOT_Y - MID_Y
	var steps := 14
	for i in steps:
		var r1 := float(i)     / float(steps)
		var r2 := float(i + 1) / float(steps)
		var y1 := lerpf(MID_Y, BOT_Y, r1)
		var y2 := lerpf(MID_Y, BOT_Y, r2)
		# Very dark lacquer with slight edge brightening at top
		var col := C_LACQUER
		if r1 < 0.15:
			col = col.lerp(Color("#2a1005"), (0.15 - r1) / 0.15 * 0.50)
		elif r1 > 0.80:
			col = col.lerp(Color("#000000"), (r1 - 0.80) / 0.20)
		draw_colored_polygon(PackedVector2Array([
			Vector2(BL, y1), Vector2(BR, y1), Vector2(BR, y2), Vector2(BL, y2)
		]), col)

func _draw_side_caps(BL: float, BR: float, TOP_Y: float, MID_Y: float, BOT_Y: float) -> void:
	# Left cap
	draw_colored_polygon(PackedVector2Array([
		Vector2(BL - 8, TOP_Y + 2), Vector2(BL, TOP_Y),
		Vector2(BL, BOT_Y), Vector2(BL - 8, BOT_Y - 2)
	]), Color("#120800"))
	# Right cap
	draw_colored_polygon(PackedVector2Array([
		Vector2(BR, TOP_Y), Vector2(BR + 8, TOP_Y + 2),
		Vector2(BR + 8, BOT_Y - 2), Vector2(BR, BOT_Y)
	]), Color("#120800"))

func _draw_gold_borders(BL: float, BR: float, TOP_Y: float, MID_Y: float, BOT_Y: float) -> void:
	var g  := Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.90)
	var gd := Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45)

	# Outer borders
	draw_line(Vector2(BL, TOP_Y),  Vector2(BR, TOP_Y),  g,  1.5)  # top far edge
	draw_line(Vector2(BL, MID_Y), Vector2(BR, MID_Y),   g,  1.2)  # surface/face divider
	draw_line(Vector2(BL, BOT_Y), Vector2(BR, BOT_Y),   gd, 1.0)  # bottom edge

	# Inner inlay lines on top surface
	var GAP := (MID_Y - TOP_Y) * 0.12
	draw_line(Vector2(BL + 4, TOP_Y + GAP), Vector2(BR - 4, TOP_Y + GAP), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.30), 0.8)
	draw_line(Vector2(BL + 4, MID_Y - GAP), Vector2(BR - 4, MID_Y - GAP), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25), 0.8)

	# Inner inlay lines on front face
	var FG := (BOT_Y - MID_Y) * 0.12
	draw_line(Vector2(BL + 6, MID_Y + FG), Vector2(BR - 6, MID_Y + FG), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.55), 1.0)
	draw_line(Vector2(BL + 6, BOT_Y - FG), Vector2(BR - 6, BOT_Y - FG), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.40), 0.8)

	# Corner rivet plates
	var RS := 18.0
	_rivet(Vector2(BL, TOP_Y),  RS, false, false)
	_rivet(Vector2(BR, TOP_Y),  RS, true,  false)
	_rivet(Vector2(BL, BOT_Y),  RS, false, true)
	_rivet(Vector2(BR, BOT_Y),  RS, true,  true)

func _rivet(pos: Vector2, s: float, fx: bool, fy: bool) -> void:
	var sx := -1.0 if fx else 1.0
	var sy := -1.0 if fy else 1.0
	var pts := PackedVector2Array([pos,
		pos + Vector2(sx*s, 0), pos + Vector2(sx*s*0.5, sy*s*0.5), pos + Vector2(0, sy*s)])
	draw_colored_polygon(pts, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.70))
	var rv := pos + Vector2(sx*s*0.35, sy*s*0.35)
	draw_circle(rv, 2.0, Color(0.12, 0.06, 0.0, 0.90))
	draw_circle(rv, 0.9, Color(1, 0.95, 0.7, 0.50))

func _draw_mop_scenes(BL: float, BR: float, MID_Y: float, BOT_Y: float) -> void:
	# Mother-of-pearl (xà cừ) inlay scenes on the BLACK lacquer front face
	# Mimicking the real dan bau: cranes, clouds, pine trees, pavilions
	var FW  := BR - BL
	var FCY := (MID_Y + BOT_Y) * 0.5
	var FH  := (BOT_Y - MID_Y)

	# Gold vine scrollwork dividing sections
	var gold_scroll := Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.55)
	for i in range(1, 4):
		var sx := BL + FW * (float(i) / 4.0)
		draw_line(Vector2(sx, MID_Y + FH*0.15), Vector2(sx, BOT_Y - FH*0.15), gold_scroll, 0.8)

	# Scene 1 (leftmost): Crane in flight
	_mop_crane(BL + FW * 0.12, FCY, FH * 0.38, C_MOP)
	# Scene 2: Mountain / landscape
	_mop_mountain(BL + FW * 0.36, FCY, FH * 0.40, C_MOP2)
	# Scene 3: Lotus flowers
	_mop_lotus_group(BL + FW * 0.62, FCY, FH * 0.35, C_MOP)
	# Scene 4 (rightmost): Boat on water
	_mop_boat(BL + FW * 0.85, FCY, FH * 0.32, C_MOP2)

func _mop_crane(cx: float, cy: float, size: float, col: Color) -> void:
	# Body
	draw_circle(Vector2(cx, cy), size * 0.18, col)
	# Head + neck
	draw_circle(Vector2(cx + size*0.12, cy - size*0.22), size*0.09, col)
	draw_line(Vector2(cx + size*0.06, cy - size*0.04), Vector2(cx + size*0.12, cy - size*0.16), col, size*0.06, true)
	# Wings spread
	var wl := PackedVector2Array([
		Vector2(cx, cy - size*0.04),
		Vector2(cx - size*0.42, cy - size*0.18),
		Vector2(cx - size*0.28, cy + size*0.08)
	])
	draw_colored_polygon(wl, Color(col.r, col.g, col.b, col.a * 0.80))
	var wr := PackedVector2Array([
		Vector2(cx, cy - size*0.04),
		Vector2(cx + size*0.38, cy - size*0.14),
		Vector2(cx + size*0.22, cy + size*0.10)
	])
	draw_colored_polygon(wr, Color(col.r, col.g, col.b, col.a * 0.80))
	# Legs
	draw_line(Vector2(cx - size*0.06, cy + size*0.16), Vector2(cx - size*0.06, cy + size*0.36), col, size*0.04)
	draw_line(Vector2(cx + size*0.06, cy + size*0.16), Vector2(cx + size*0.06, cy + size*0.36), col, size*0.04)
	# Red crown dot
	draw_circle(Vector2(cx + size*0.14, cy - size*0.28), size*0.05, Color("#cc2222", 0.85))

func _mop_mountain(cx: float, cy: float, size: float, col: Color) -> void:
	# Three mountain peaks
	var y_bot := cy + size * 0.40
	var peaks := [
		PackedVector2Array([Vector2(cx - size*0.38, y_bot), Vector2(cx - size*0.10, cy - size*0.30), Vector2(cx + size*0.18, y_bot)]),
		PackedVector2Array([Vector2(cx - size*0.10, y_bot), Vector2(cx + size*0.18, cy - size*0.45), Vector2(cx + size*0.44, y_bot)]),
		PackedVector2Array([Vector2(cx + size*0.16, y_bot), Vector2(cx + size*0.42, cy - size*0.20), Vector2(cx + size*0.60, y_bot)])
	]
	for i in peaks.size():
		var a := 0.75 - i * 0.10
		draw_colored_polygon(peaks[i], Color(col.r, col.g, col.b, a))
	# Moon
	draw_circle(Vector2(cx - size*0.22, cy - size*0.38), size*0.10, Color(col.r, col.g, col.b, 0.65))
	# Pine tree silhouette
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx - size*0.46, y_bot),
		Vector2(cx - size*0.36, cy + size*0.05),
		Vector2(cx - size*0.26, y_bot)
	]), Color(col.r, col.g, col.b, 0.55))

func _mop_lotus_group(cx: float, cy: float, size: float, col: Color) -> void:
	# Three lotus flowers
	for i in range(-1, 2):
		var lx := cx + float(i) * size * 0.32
		var ly := cy + float(abs(i)) * size * 0.06
		# Stem
		draw_line(Vector2(lx, ly + size*0.35), Vector2(lx, ly + size*0.10), col, size*0.04)
		# Petals
		var petal_col := Color(col.r, col.g, col.b, 0.75)
		for ang in [0.0, 60.0, 120.0, 180.0, 240.0, 300.0]:
			var rad  := deg_to_rad(ang)
			var pdx  := cos(rad) * size * 0.14
			var pdy  := sin(rad) * size * 0.10
			draw_circle(Vector2(lx + pdx, ly + pdy), size * 0.07, petal_col)
		# Center
		draw_circle(Vector2(lx, ly), size * 0.07, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.70))

func _mop_boat(cx: float, cy: float, size: float, col: Color) -> void:
	# Boat hull
	var hull := PackedVector2Array([
		Vector2(cx - size*0.40, cy + size*0.10),
		Vector2(cx + size*0.40, cy + size*0.10),
		Vector2(cx + size*0.30, cy + size*0.35),
		Vector2(cx - size*0.30, cy + size*0.35)
	])
	draw_colored_polygon(hull, Color(col.r, col.g, col.b, 0.65))
	# Sail
	var sail := PackedVector2Array([
		Vector2(cx, cy + size*0.12),
		Vector2(cx + size*0.30, cy - size*0.30),
		Vector2(cx, cy - size*0.30)
	])
	draw_colored_polygon(sail, Color(col.r, col.g, col.b, 0.55))
	# Water ripples
	for ri in range(3):
		var ry := cy + size * (0.42 + ri * 0.08)
		draw_arc(Vector2(cx + float(ri-1) * size * 0.20, ry), size*0.12, 0.0, PI, 8, Color(col.r, col.g, col.b, 0.30), 0.7)

func _draw_peg(str_start: Vector2, TOP_Y: float, MID_Y: float) -> void:
	# Trục cuộn (tuning peg) at left end
	var px := str_start.x
	var py := str_start.y
	var ph := (MID_Y - TOP_Y) * 0.55

	# Mount block on body
	draw_colored_polygon(PackedVector2Array([
		Vector2(px - 8, py - 5), Vector2(px + 5, py - 5),
		Vector2(px + 5, py + 5), Vector2(px - 8, py + 5)
	]), Color("#1e1006"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(px - 6, py - 3.5), Vector2(px + 3.5, py - 3.5),
		Vector2(px + 3.5, py + 3.5), Vector2(px - 6, py + 3.5)
	]), Color("#2e1808"))

	# Vertical pin
	draw_line(Vector2(px, py - ph * 0.5), Vector2(px, py - ph - 4), Color("#3a3028"), 4.0)

	# Peg knob (3D sphere shading)
	var kc := Vector2(px, py - ph - 4)
	for i in range(10):
		var r_ratio := float(10 - i) / 10.0
		var r := 6.5 * r_ratio
		var col := Color("#1a1412").lerp(Color("#4a3c30"), r_ratio)
		if r_ratio > 0.82: col = col.lerp(Color("#8a7060"), (r_ratio - 0.82) / 0.18 * 0.70)
		draw_circle(kc + Vector2(-r_ratio*0.8, -r_ratio*0.8) * 0.5, r, col)
	draw_circle(kc + Vector2(-1.8, -2.0), 1.4, Color(1, 1, 1, 0.45))

	# Gold collar
	draw_arc(Vector2(px, py), 6.0, 0.0, TAU, 14, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.65), 1.4)

func _draw_string(str_start: Vector2, str_end: Vector2, SY_L: float, SY_R: float,
		BL: float, BR: float) -> void:
	var pts := PackedVector2Array()
	pts.append(str_start)
	if _pluck_amp > 0.005:
		for k in range(1, 34):
			var ratio : float = float(k) / 34.0
			var px    : float = lerpf(str_start.x, str_end.x, ratio)
			var py    : float = lerpf(str_start.y, str_end.y, ratio)
			var decay : float = exp(-_pluck_time * 2.0)
			var osc   : float = sin(ratio * PI) * sin(ratio * PI * 5.0 - _pluck_time * 88.0) * _pluck_amp * 7.0 * decay
			pts.append(Vector2(px, py + osc))
	pts.append(str_end)
	# Shadow
	var shd := PackedVector2Array()
	for pt in pts: shd.append(pt + Vector2(0, 3))
	draw_polyline(shd, Color(0, 0, 0, 0.35), 1.3, true)
	# Glow
	if _pluck_amp > 0.01:
		draw_polyline(pts, Color(C_GOLD_LIGHT.r, C_GOLD_LIGHT.g, C_GOLD_LIGHT.b, _pluck_amp*0.55), 5.0, true)
	# Core string
	var sc := C_GOLD_LIGHT if _pluck_amp > 0.12 else C_STRING
	if _is_bending: sc = Color("#fc882b")
	draw_polyline(pts, sc, 1.7, true)

func _draw_nodes(SY_L: float, SY_R: float, BL: float, BR: float) -> void:
	var font    := get_theme_font("font")
	var START_X := BL + (BR - BL) * 0.04
	var END_X   := BL + (BR - BL) * 0.93
	var STEP_X  := (END_X - START_X) / float(NODE_COUNT - 1)
	for i in NODE_COUNT:
		var nx     : float = START_X + float(i) * STEP_X
		var ratio  : float = (nx - BL) / (BR - BL)
		var ny     : float = lerpf(SY_L, SY_R, ratio)
		_draw_node(Vector2(nx, ny), i, _is_target[i] == 1, _hovered_node_idx == i, _glow_alpha[i], font)

func _draw_node(pos: Vector2, idx: int, is_tgt: bool, is_hov: bool, glow: float, font: Font) -> void:
	# Shadow
	draw_circle(pos + Vector2(0, 2.5), 12.0, Color(0, 0, 0, 0.32))
	# Target glow pulse
	if is_tgt:
		var pulse := (sin(_pulse_phase * 2.0) + 1.0) * 0.5
		draw_circle(pos, 17.0 + pulse * 5.0, Color(0.79, 0.60, 0.24, 0.13 + pulse*0.13))
		draw_arc(pos, 17.0 + pulse*5.0, 0.0, TAU, 28, Color(0.79, 0.60, 0.24, 0.38 + pulse*0.25), 1.3)
	# Pluck glow
	if glow > 0.01:
		draw_circle(pos, 12.0 + glow * 22.0, Color(1, 0.95, 0.75, glow * 0.45))
		draw_arc(pos,   12.0 + glow * 22.0, 0.0, TAU, 24, Color(1, 0.9, 0.5, glow*0.55), 1.5)
	# Node layers (ivory + brass)
	var R := 9.5 + (1.5 if is_hov else (1.0 if is_tgt else 0.0))
	draw_circle(pos, R,       C_GOLD)
	draw_circle(pos, R - 1.6, Color("#faf5e6"))
	draw_circle(pos, R - 4.0, C_GOLD)
	draw_circle(pos, R - 6.0, Color("#1a0c04"))
	draw_circle(pos, 1.3,     Color(1, 1, 1, 0.80))
	# Label above
	if font != null:
		var text    := _note_names[idx] if idx < _note_names.size() else NOTES_VN[idx]
		var fsz     := 13 if (is_tgt or is_hov) else 11
		var tcol    := Color("#faf6eb") if is_tgt else (Color.WHITE if is_hov else Color("#c8b8a0"))
		var ts      := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, fsz)
		var tp      := Vector2(pos.x - ts.x * 0.5, pos.y - R - 7.0)
		draw_string(font, tp + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, Color(0, 0, 0, 0.70))
		draw_string(font, tp, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, tcol)

func _draw_gourd(GX: float, GY: float, GR: float) -> void:
	# Quả bầu: double-gourd shape — LOWER big bulb + UPPER smaller bulb
	# This is the iconic round resonator on the right side of the instrument

	var NECK_R := GR * 0.58   # upper bulb radius
	var NECK_Y := GY - GR - NECK_R * 0.85  # upper bulb center Y

	# ── Lower bulb shadow ──
	draw_circle(Vector2(GX, GY + 5), GR + 4, Color(0, 0, 0, 0.38))

	# ── Lower bulb: 3D sphere gradient ──
	var steps := 22
	for i in range(steps):
		var r_ratio := float(steps - i) / float(steps)
		var r := GR * r_ratio
		var offset := Vector2(-0.9, -0.9) * (1.0 - r_ratio)
		var col := C_GOURD_BASE.lerp(C_GOURD_MID, r_ratio)
		if r_ratio > 0.78:
			col = col.lerp(C_GOURD_HIGH, (r_ratio - 0.78) / 0.22 * 0.88)
		draw_circle(Vector2(GX, GY) + offset, r, col)
	# Specular
	draw_circle(Vector2(GX - GR*0.32, GY - GR*0.34), GR * 0.14, Color(1, 1, 1, 0.80))
	draw_circle(Vector2(GX - GR*0.20, GY - GR*0.22), GR * 0.07, Color(1, 1, 1, 0.55))
	# Engraved ring
	draw_arc(Vector2(GX, GY), GR * 0.66, 0.0, TAU, 28, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.55), 1.2)
	# Gold lotus engraving on front
	draw_arc(Vector2(GX, GY), GR * 0.38, 0.0, TAU, 16, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.40), 0.9)
	for ang in [0.0, 72.0, 144.0, 216.0, 288.0]:
		var r2 := deg_to_rad(ang)
		draw_circle(Vector2(GX + cos(r2)*GR*0.52, GY + sin(r2)*GR*0.52), GR*0.07,
			Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45))

	# ── Red silk cord between two bulbs ──
	var cord_y := GY - GR + NECK_R * 0.12
	draw_arc(Vector2(GX, cord_y),             NECK_R * 0.40, 0.0, TAU, 14, Color("#cc1111", 0.90), NECK_R*0.13)
	draw_arc(Vector2(GX, cord_y + NECK_R*0.18), NECK_R * 0.30, 0.0, TAU, 12, Color("#ee3322", 0.80), NECK_R*0.10)

	# ── Upper bulb shadow ──
	draw_circle(Vector2(GX, NECK_Y + 3), NECK_R + 3, Color(0, 0, 0, 0.32))

	# ── Upper bulb ──
	for i in range(steps):
		var r_ratio := float(steps - i) / float(steps)
		var r := NECK_R * r_ratio
		var offset := Vector2(-0.7, -0.7) * (1.0 - r_ratio)
		var col := C_GOURD_BASE.lerp(C_GOURD_MID, r_ratio * 0.88)
		if r_ratio > 0.80:
			col = col.lerp(C_GOURD_HIGH, (r_ratio - 0.80) / 0.20 * 0.80)
		draw_circle(Vector2(GX, NECK_Y) + offset, r, col)
	draw_circle(Vector2(GX - NECK_R*0.28, NECK_Y - NECK_R*0.30), NECK_R * 0.12, Color(1, 1, 1, 0.72))
	draw_arc(Vector2(GX, NECK_Y), NECK_R * 0.60, 0.0, TAU, 20, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.50), 1.0)

	# ── Tip knob at top of upper bulb ──
	var tip := Vector2(GX, NECK_Y - NECK_R - 2)
	draw_circle(tip, NECK_R * 0.20, Color("#3a1a06"))
	draw_circle(tip, NECK_R * 0.12, Color("#c07818"))
	draw_circle(tip + Vector2(-1, -1.2), NECK_R * 0.05, Color(1, 1, 1, 0.55))

func _draw_horn(HORN_BASE: Vector2, HORN_TIP: Vector2, C1: Vector2, C2: Vector2) -> void:
	# Cần đàn: polished buffalo horn rod — dark, elegant, curved like a fishing rod
	var seg_cnt := 28
	var rod_pts := PackedVector2Array()
	for k in range(seg_cnt + 1):
		var t := float(k) / float(seg_cnt)
		rod_pts.append(_cbez(HORN_BASE, C1, C2, HORN_TIP, t))

	# Shadow
	var shd := PackedVector2Array()
	for pt in rod_pts: shd.append(pt + Vector2(3, 4))
	for k in range(seg_cnt):
		var t := float(k) / float(seg_cnt)
		draw_line(shd[k], shd[k+1], Color(0, 0, 0, 0.22), lerpf(10.0, 2.0, t), true)

	# Main rod — dark horn with subtle shading
	for k in range(seg_cnt):
		var t   : float = float(k) / float(seg_cnt)
		var th  : float = lerpf(9.5, 2.0, t)
		var col : Color = C_HORN_DARK.lerp(C_HORN_MID, 0.35 + 0.30 * sin(t * PI))
		draw_line(rod_pts[k], rod_pts[k+1], col, th, true)
		if k == 0: draw_circle(rod_pts[k], th * 0.5, col)

	# Specular highlight on top edge of rod
	for k in range(seg_cnt):
		var t   : float = float(k) / float(seg_cnt)
		var th  : float = lerpf(9.5, 2.0, t)
		var spec_off := Vector2(-th * 0.18, -th * 0.18)
		draw_line(rod_pts[k] + spec_off, rod_pts[k+1] + spec_off,
			Color(1.0, 1.0, 1.0, 0.13 * (1.0 - t)), th * 0.22, true)

	# Rod tip cap
	draw_circle(HORN_TIP, 3.0, C_HORN_EDGE)
	draw_circle(HORN_TIP + Vector2(-0.8, -0.8), 1.0, Color(1, 1, 1, 0.42))

	# Brass socket where horn enters body (at base)
	var sock := HORN_BASE
	for i in range(8):
		var r_ratio := float(8 - i) / 8.0
		var col := C_GOLD_DARK.lerp(C_GOLD, r_ratio)
		draw_circle(sock + Vector2(-r_ratio*0.5, -r_ratio*0.5), 7.0 * r_ratio, col)
	draw_circle(sock + Vector2(-1.5, -1.5), 2.0, Color(1, 1, 1, 0.50))

func _cbez(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	return u*u*u*p0 + 3.0*u*u*t*p1 + 3.0*u*t*t*p2 + t*t*t*p3

func _draw_cents_readout(font: Font, pos: Vector2, cents: float) -> void:
	if font == null: return
	var sign := "+" if cents > 0 else ""
	var txt  := "%s%d ¢" % [sign, int(cents)]
	var col  := C_GOLD
	if cents > 5.0:    col = Color("#2ecc71")
	elif cents < -5.0: col = Color("#e74c3c")
	var ts := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 13)
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(0.04, 0.02, 0.01, 0.90)
	bs.border_color = Color(col.r, col.g, col.b, 0.55)
	bs.border_width_left = 1; bs.border_width_right = 1
	bs.border_width_top  = 1; bs.border_width_bottom = 1
	bs.corner_radius_top_left = 7; bs.corner_radius_top_right = 7
	bs.corner_radius_bottom_left = 7; bs.corner_radius_bottom_right = 7
	var bw := ts.x + 14.0; var bh := ts.y + 4.0
	draw_style_box(bs, Rect2(pos.x - bw*0.5, pos.y - bh*0.5, bw, bh))
	draw_string(font, pos + Vector2(-ts.x*0.5, ts.y*0.5 - 2), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col)

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
	# Bend zone: right 20% of canvas (near the gourd/horn)
	if pos.x > size.x * 0.80:
		_is_bending = true
		_update_bend(pos.y)
	else:
		var ni := _node_at(pos)
		if ni != -1: pluck(ni)

func _touch_move(pos: Vector2) -> void:
	if _is_bending:
		_update_bend(pos.y)
	else:
		var ni := _node_at(pos)
		if ni != _hovered_node_idx:
			_hovered_node_idx = ni
			queue_redraw()

func _touch_end() -> void:
	_is_bending = false
	_hovered_node_idx = -1
	queue_redraw()

func _node_at(pos: Vector2) -> int:
	var W      := size.x; var H := size.y
	var BL     : float = W * 0.06; var BR : float = W * 0.82
	var TOP_Y  : float = H * 0.06; var MID_Y : float = H * 0.46
	var TOP_H  : float = MID_Y - TOP_Y
	var SY_L   : float = TOP_Y + TOP_H * 0.60
	var SY_R   : float = TOP_Y + TOP_H * 0.64
	var START_X: float = BL + (BR - BL) * 0.04
	var END_X  : float = BL + (BR - BL) * 0.93
	var STEP_X : float = (END_X - START_X) / float(NODE_COUNT - 1)
	for i in NODE_COUNT:
		var nx    : float = START_X + float(i) * STEP_X
		var ratio : float = (nx - BL) / (BR - BL)
		var ny    : float = lerpf(SY_L, SY_R, ratio)
		if pos.distance_to(Vector2(nx, ny)) <= 28.0:
			return i
	return -1

func _update_bend(touch_y: float) -> void:
	var mid_y  : float = size.y * 0.20
	var max_d  : float = size.y * 0.12
	_bend_offset   = clampf(touch_y - mid_y, -max_d, max_d)
	_bend_velocity = 0.0
	_bend_cents    = (_bend_offset / max_d) * 350.0
	pitch_bent.emit(_bend_cents)
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_hovered_node_idx = -1
		if _is_bending: _touch_end()
		queue_redraw()
