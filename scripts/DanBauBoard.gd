extends Control

## DanBauBoard — Đàn Bầu (Vietnamese Monochord) 2.5D Renderer
## Layout matches the real instrument:
##   LEFT  end: Trục cuộn (tuning peg / string anchor)
##   RIGHT end: Cần đàn (horn rod) + Quả bầu (gourd resonator), rod curves up

signal string_plucked(idx: int, note_name: String)
signal pitch_bent(cents_offset: float)

const NODE_COUNT := 7
const NOTES_VN : Array[String] = ["Đô", "Rê", "Mi", "Fa", "Sol", "La", "Si"]

# ─── Color Palette ─────────────────────────────────────────────────────────────
const C_GOLD        := Color("#c99a3c")   # Antique Gold
const C_GOLD_LIGHT  := Color("#fce8b3")   # Light golden highlight
const C_GOLD_DARK   := Color("#7a5c10")   # Deep gold / bronze
const C_WOOD_DARK   := Color("#1a0902")   # Deep mahogany (frame)
const C_WOOD_MID    := Color("#4a1c06")   # Mid rosewood
const C_WOOD_LIGHT  := Color("#7a3310")   # Lighter rosewood highlight
const C_WOOD_TOP    := Color("#a04420")   # Surface highlight strip
const C_BLACK_BOX   := Color("#0d0501")   # Lacquer black (real instrument body)
const C_MOP_TEAL    := Color("#b5e2db")   # Mother-of-pearl iridescent teal
const C_MOP_PINK    := Color("#e8cde1")   # Mother-of-pearl iridescent pink
const C_MOP_WHITE   := Color("#f0ede8")   # MOP white base
const C_HORN_DARK   := Color("#0a0808")   # Dark horn/buffalo horn color
const C_HORN_MID    := Color("#1c1414")   # Mid horn
const C_GOURD_GOLD  := Color("#cf8c19")   # Gourd body golden
const C_GOURD_HIGH  := Color("#ffebad")   # Gourd specular highlight
const C_STRING      := Color("#dce0eb")   # Steel monochord string (silver-grey)
const C_STRING_VIBE := Color("#fce8b3")   # String vibration glow color

# ─── State ────────────────────────────────────────────────────────────────────
var _note_names  : Array[String]      = []
var _streams     : Array              = []
var _freqs       : Array[float]       = []

var _pluck_amp   : float              = 0.0
var _pluck_time  : float              = 0.0
var _glow_alpha  : PackedFloat32Array = PackedFloat32Array()
var _pulse_phase : float              = 0.0
var _is_target   : PackedByteArray    = PackedByteArray()

# Horn / Cần đàn bend variables (bend moves rod left/right at the right end)
var _is_bending    := false
var _bend_offset   := 0.0   # Visual Y offset of rod tip (up/down)
var _bend_cents    := 0.0   # Pitch bend in cents (-400 to +400)
var _bend_velocity := 0.0   # For spring-damper physics
var _active_player : AudioStreamPlayer = null
var _last_plucked_idx := -1

var _hovered_node_idx := -1
var _target_node_idx  := 0

# Key geometry points (recalculated each _draw)
var _peg_pos      := Vector2.ZERO   # Left end: string anchor / tuning peg
var _gourd_pos    := Vector2.ZERO   # Right end: gourd base
var _rod_base     := Vector2.ZERO   # Rod starts from gourd top
var _rod_tip      := Vector2.ZERO   # Rod tip (top of the curved horn)
var _string_start := Vector2.ZERO   # String left anchor point
var _string_end   := Vector2.ZERO   # String right anchor (at rod base)

# 2.5D perspective skew factor
const SKEW_FACTOR := 0.22  # How much the "far" (top) edge recedes

func init(notes: Array[String], streams: Array, freqs: Array[float]) -> void:
	_note_names = notes
	_streams    = streams
	_freqs      = freqs
	_glow_alpha.resize(NODE_COUNT)
	_is_target.resize(NODE_COUNT)
	for i in NODE_COUNT:
		_glow_alpha[i] = 0.0
		_is_target[i] = 0
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
	if idx < 0 or idx >= NODE_COUNT:
		return
	_last_plucked_idx = idx
	_pluck_time = 0.0
	_pluck_amp  = 1.0
	_glow_alpha[idx] = 1.0
	string_plucked.emit(idx, _note_names[idx] if idx < _note_names.size() else NOTES_VN[idx])
	queue_redraw()

func _process(delta: float) -> void:
	var need_redraw := false

	if _pluck_amp > 0.0:
		_pluck_time += delta
		_pluck_amp = maxf(0.0, _pluck_amp - delta * 2.5)
		need_redraw = true

	for i in NODE_COUNT:
		if _glow_alpha[i] > 0.0:
			_glow_alpha[i] = maxf(0.0, _glow_alpha[i] - delta * 3.0)
			need_redraw = true

	_pulse_phase += delta * 3.5
	need_redraw = true

	# Spring-damper physics for rod release
	if not _is_bending and (_bend_offset != 0.0 or _bend_velocity != 0.0):
		var k := 420.0
		var c := 15.0
		var accel := -k * _bend_offset - c * _bend_velocity
		_bend_velocity += accel * delta
		_bend_offset   += _bend_velocity * delta
		if abs(_bend_offset) < 0.05 and abs(_bend_velocity) < 0.05:
			_bend_offset   = 0.0
			_bend_velocity = 0.0
			_bend_cents    = 0.0
			pitch_bent.emit(0.0)
		else:
			var W := size.x
			var max_drag := W * 0.06 if W > 0 else 80.0
			var factor := _bend_offset / max_drag
			_bend_cents = factor * 350.0
			pitch_bent.emit(_bend_cents)
		need_redraw = true

	if need_redraw:
		queue_redraw()

# ─────────────────────────────────────────────────────────────────────────────
# MAIN DRAW FUNCTION
# ─────────────────────────────────────────────────────────────────────────────
func _draw() -> void:
	var W := size.x
	var H := size.y
	if W < 80.0 or H < 60.0:
		return

	# ── Layout constants ──────────────────────────────────────────────────────
	# The instrument body sits in the lower 2/3 of the canvas.
	# We render it as a 2.5D perspective box (isometric-ish view from slightly above).
	#
	# Body runs LEFT to RIGHT across most of the width.
	# LEFT  end: Peg / trục cuộn (small metal fitting)
	# RIGHT end: Cần đàn socket + Gourd + Horn Rod curving upward

	var body_left   := W * 0.04
	var body_right  := W * 0.82   # leaves room for the horn rod on the right
	var body_w      := body_right - body_left
	var body_cx     := (body_left + body_right) * 0.5

	# The "near" (bottom) face Y range
	var near_y_top := H * 0.50   # top edge of near face
	var near_y_bot := H * 0.82   # bottom edge of near face
	var near_h     := near_y_bot - near_y_top

	# The "top" surface Y range (2.5D perspective foreshortening)
	var top_surface_h := near_h * 0.38  # how tall the top face appears
	var top_y_bot     := near_y_top
	var top_y_top     := near_y_top - top_surface_h

	# Skew: left side is closer to viewer, right side recedes slightly
	var skew_left  := 0.0
	var skew_right := top_surface_h * SKEW_FACTOR

	# Four corners of the top surface (2.5D foreshortened)
	var tl_top := Vector2(body_left,  top_y_top + skew_left)
	var tr_top := Vector2(body_right, top_y_top + skew_right)
	var tr_bot := Vector2(body_right, top_y_bot + skew_right * 0.3)
	var tl_bot := Vector2(body_left,  top_y_bot + skew_left * 0.3)

	# Four corners of the front (near) face
	var fl_top := tl_bot
	var fr_top := tr_bot
	var fl_bot := Vector2(body_left,  near_y_bot)
	var fr_bot := Vector2(body_right, near_y_bot)

	# String runs along the top surface, center Y
	var string_y_left  := (tl_top.y + tl_bot.y) * 0.5 + 4.0
	var string_y_right := (tr_top.y + tr_bot.y) * 0.5 + 4.0

	# Key positions
	_peg_pos    = Vector2(body_left  + 18.0, string_y_left)
	_gourd_pos  = Vector2(body_right + 4.0,  string_y_right)
	_string_start = _peg_pos
	_string_end   = _gourd_pos

	# Rod base sits just above the top-right corner
	_rod_base = Vector2(body_right + 2.0, tr_top.y + (tr_bot.y - tr_top.y) * 0.25)
	# Rod tip curls upward and slightly left, with bend offset applied vertically
	var rod_tip_x := body_right - W * 0.06
	var rod_tip_y := top_y_top - H * 0.35 + _bend_offset
	_rod_tip = Vector2(rod_tip_x, rod_tip_y)

	# ── Draw Order ────────────────────────────────────────────────────────────
	# 1. Ground shadow
	_draw_ground_shadow(fl_bot, fr_bot, body_left, body_right, near_y_bot)

	# 2. Front face (near side panel)
	_draw_front_face(fl_top, fr_top, fl_bot, fr_bot)

	# 3. Top surface (main playing surface)
	_draw_top_surface(tl_top, tr_top, tr_bot, tl_bot, body_left, body_right, string_y_left, string_y_right)

	# 4. Right side cap
	_draw_right_cap(tr_top, fr_top, fr_bot, near_y_bot)

	# 5. Left side cap with peg area
	_draw_left_cap(tl_top, fl_top, fl_bot, near_y_bot)

	# 6. Gold trim / inlay borders
	_draw_gold_trim(tl_top, tr_top, tr_bot, tl_bot, fl_top, fr_top, fl_bot, fr_bot)

	# 7. Mother-of-pearl decorations on front face
	_draw_mop_front(fl_top, fr_top, fl_bot, fr_bot)

	# 8. Left peg (tuning anchor)
	_draw_tuning_peg(_peg_pos, tl_top, tl_bot)

	# 9. Right socket collar (where rod connects to body)
	_draw_rod_socket(_rod_base, tr_top)

	# 10. Single monochord string (with vibration wave)
	_draw_string(_string_start, _string_end, string_y_left, string_y_right)

	# 11. 7 harmonic touch nodes on the string
	var font := get_theme_font("font")
	_draw_harmonic_nodes(string_y_left, string_y_right, body_left, body_right, font)

	# 12. Gourd resonator (Quả bầu) — right end, on body
	_draw_gourd(_gourd_pos, tr_top, tr_bot)

	# 13. Horn rod (Cần đàn) — curved upward from gourd
	_draw_horn_rod(_rod_base, _rod_tip)

	# 14. Bend gauge (shown when bending)
	if _is_bending:
		var font2 := get_theme_font("font")
		_draw_bend_gauge(_rod_tip + Vector2(-30, 0), 32.0, _bend_cents)
		_draw_cents_readout(font2, _rod_tip + Vector2(0, -26), _bend_cents)

# ─────────────────────────────────────────────────────────────────────────────
# 2.5D COMPONENT DRAWS
# ─────────────────────────────────────────────────────────────────────────────

func _draw_ground_shadow(fl_bot: Vector2, fr_bot: Vector2, bx_l: float, bx_r: float, ny_bot: float) -> void:
	var shadow_pts := PackedVector2Array([
		Vector2(bx_l  - 20, ny_bot + 6),
		Vector2(bx_r  + 40, ny_bot + 6),
		Vector2(bx_r  + 20, ny_bot + 20),
		Vector2(bx_l  - 8,  ny_bot + 20)
	])
	draw_colored_polygon(shadow_pts, Color(0, 0, 0, 0.18))

func _draw_front_face(fl_top: Vector2, fr_top: Vector2, fl_bot: Vector2, fr_bot: Vector2) -> void:
	# The front face is the near vertical panel — dark lacquered wood
	# Base dark lacquer gradient (top lighter, bottom darker)
	var face_h := fl_bot.y - fl_top.y
	var steps  := 14
	for i in steps:
		var r1 := float(i)     / float(steps)
		var r2 := float(i + 1) / float(steps)
		var ya := fl_top.y + face_h * r1
		var yb := fl_top.y + face_h * r2
		# Interpolate left/right x along the front face
		var xa_l := fl_top.x; var xa_r := fr_top.x
		var col := C_BLACK_BOX.lerp(Color("#2a1005"), 1.0 - r1)
		# Slight highlight near top edge
		if r1 < 0.12:
			col = col.lerp(Color("#3d1908"), (0.12 - r1) / 0.12)
		var strip := PackedVector2Array([Vector2(xa_l, ya), Vector2(xa_r, ya), Vector2(xa_r, yb), Vector2(xa_l, yb)])
		draw_colored_polygon(strip, col)

func _draw_top_surface(tl_top: Vector2, tr_top: Vector2, tr_bot: Vector2, tl_bot: Vector2,
		bx_l: float, bx_r: float, sy_l: float, sy_r: float) -> void:
	# Top face: the main playing surface — rosewood/mahogany color
	# Render as gradient strips for cylindrical 3D effect

	var steps  := 20
	for i in steps:
		var r1 := float(i)     / float(steps)
		var r2 := float(i + 1) / float(steps)

		# Interpolate four corners
		var p_tl1 := tl_top.lerp(tl_bot, r1)
		var p_tr1 := tr_top.lerp(tr_bot, r1)
		var p_tl2 := tl_top.lerp(tl_bot, r2)
		var p_tr2 := tr_top.lerp(tr_bot, r2)

		# Cylindrical light model: brightest near r=0.25 (top-left light source)
		var light := sin(r1 * PI)
		var col   := C_WOOD_DARK.lerp(C_WOOD_MID, light)

		# Glossy specular near top
		if r1 > 0.08 and r1 < 0.22:
			var fac := (r1 - 0.08) / 0.14
			col = col.lerp(C_WOOD_TOP, sin(fac * PI) * 0.55)
		elif r1 > 0.75:
			var fac := (r1 - 0.75) / 0.25
			col = col.lerp(Color("#080201"), fac * 0.65)

		draw_colored_polygon(PackedVector2Array([p_tl1, p_tr1, p_tr2, p_tl2]), col)

	# Deterministic wood grain lines across top surface
	var rng := RandomNumberGenerator.new()
	rng.seed = 54321
	for _j in range(10):
		var f := rng.randf()
		var grain_pts := PackedVector2Array()
		var seg_cnt := 20
		for k in range(seg_cnt + 1):
			var t := float(k) / float(seg_cnt)
			var left_pt  := tl_top.lerp(tl_bot, f)
			var right_pt := tr_top.lerp(tr_bot, f)
			var gp := left_pt.lerp(right_pt, t)
			var wave := sin(t * 14.0 + f * 8.0) * 1.2
			gp.y += wave
			grain_pts.append(gp)
		var gc := C_WOOD_DARK.lerp(C_WOOD_MID, f)
		gc.a = rng.randf_range(0.06, 0.18)
		draw_polyline(grain_pts, gc, rng.randf_range(0.6, 1.4), true)

	# MOP (mother-of-pearl) decorative scrollwork on top surface
	_draw_mop_top(tl_top, tr_top, tr_bot, tl_bot, sy_l, sy_r)

func _draw_mop_top(tl_top: Vector2, tr_top: Vector2, tr_bot: Vector2, tl_bot: Vector2,
		sy_l: float, sy_r: float) -> void:
	# Draw subtle gold vine / floral patterns on the top surface
	# Similar to the golden inlay seen in the real dan bau photo
	var sections := 3
	for s in range(sections):
		var t0 := float(s)     / float(sections)
		var t1 := float(s + 1) / float(sections)
		var left_a  := tl_top.lerp(tr_top, t0)
		var left_b  := tl_top.lerp(tr_top, t1)

		# Thin gold vine near the top edge of surface
		var top_a := left_a
		var top_b := left_b
		var c1 := top_a + Vector2(0, (tr_top.y - tl_top.y) * t0 * 0.3 - 6)
		var c2 := top_b + Vector2(0, (tr_top.y - tl_top.y) * t1 * 0.3 + 6)
		_draw_bezier_spline(top_a, c1, c2, top_b, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35), 0.8)

		# Small lotus marker in middle of each section
		var mid_t := (t0 + t1) * 0.5
		var top_l  := tl_top.lerp(tl_bot, 0.45)
		var top_r  := tr_top.lerp(tr_bot, 0.45)
		var lotus_pt := top_l.lerp(top_r, mid_t)
		_draw_mini_lotus(lotus_pt, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.50))

func _draw_front_mop_pattern(cx: float, cy: float, scale: float, col: Color) -> void:
	# Stylized crane/bird silhouette (xà cừ) as seen on real instrument
	draw_circle(Vector2(cx, cy), scale * 2.5, col)
	# Wing right
	var wing_pts := PackedVector2Array([
		Vector2(cx, cy - scale),
		Vector2(cx + scale * 3.5, cy - scale * 0.5),
		Vector2(cx + scale * 2.0, cy + scale * 0.5)
	])
	draw_colored_polygon(wing_pts, col)
	# Wing left
	var wing_l := PackedVector2Array([
		Vector2(cx, cy - scale),
		Vector2(cx - scale * 2.0, cy - scale * 0.5),
		Vector2(cx - scale * 1.2, cy + scale * 0.5)
	])
	draw_colored_polygon(wing_l, col)

func _draw_mop_front(fl_top: Vector2, fr_top: Vector2, fl_bot: Vector2, fr_bot: Vector2) -> void:
	# Draw mother-of-pearl (xà cừ) decorations on the front lacquered face
	# In real dan bau: white/silver cranes, clouds, pine trees inlaid into black lacquer
	var mop := Color(C_MOP_WHITE.r, C_MOP_WHITE.g, C_MOP_WHITE.b, 0.70)
	var mop2 := Color(C_MOP_TEAL.r, C_MOP_TEAL.g, C_MOP_TEAL.b, 0.60)

	var face_w := fr_top.x - fl_top.x
	var cy_mid := (fl_top.y + fl_bot.y) * 0.5

	# Three crane/bird motif clusters
	var positions : Array[float] = [0.20, 0.50, 0.78]
	for i in positions.size():
		var px : float = fl_top.x + face_w * positions[i]
		var py : float = cy_mid
		var sc : float = 3.5
		_draw_front_mop_pattern(px, py, sc, mop if i % 2 == 0 else mop2)

	# Gold outline decorative lines near top and bottom of front face
	var gold_line := Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45)
	draw_line(fl_top + Vector2(8, 4), fr_top + Vector2(-8, 4), gold_line, 0.8)
	draw_line(fl_bot + Vector2(8, -4), fr_bot + Vector2(-8, -4), gold_line, 0.8)

	# Scroll patterns at thirds
	for i in range(1, 3):
		var sx := fl_top.x + face_w * (float(i) / 3.0)
		var st := Vector2(sx, fl_top.y + 6)
		var sb := Vector2(sx, fl_bot.y - 6)
		draw_line(st, sb, gold_line, 0.6)
		draw_circle(Vector2(sx, cy_mid), 2.5, gold_line)

func _draw_right_cap(tr_top: Vector2, fr_top: Vector2, fr_bot: Vector2, ny_bot: float) -> void:
	# Right end cap (a narrow panel) — where the rod socket is
	var pts := PackedVector2Array([tr_top, fr_top, fr_bot, Vector2(tr_top.x, ny_bot)])
	draw_colored_polygon(pts, Color("#1a0a03"))
	draw_polyline(pts, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.30), 0.8)

func _draw_left_cap(tl_top: Vector2, fl_top: Vector2, fl_bot: Vector2, ny_bot: float) -> void:
	# Left end cap
	var pts := PackedVector2Array([tl_top, fl_top, fl_bot, Vector2(tl_top.x, ny_bot)])
	draw_colored_polygon(pts, Color("#1a0a03"))
	draw_polyline(pts, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25), 0.8)

func _draw_gold_trim(tl_top: Vector2, tr_top: Vector2, tr_bot: Vector2, tl_bot: Vector2,
		fl_top: Vector2, fr_top: Vector2, fl_bot: Vector2, fr_bot: Vector2) -> void:
	var gold := Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.85)
	var gold_dim := Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.40)

	# Top surface borders
	draw_polyline(PackedVector2Array([tl_top, tr_top]), gold, 1.2)         # far edge (top)
	draw_polyline(PackedVector2Array([tl_bot, tr_bot]), gold_dim, 1.0)     # near edge of top surface
	draw_polyline(PackedVector2Array([tl_top, tl_bot]), gold_dim, 0.8)     # left edge of top
	draw_polyline(PackedVector2Array([tr_top, tr_bot]), gold_dim, 0.8)     # right edge of top

	# Front face borders
	draw_polyline(PackedVector2Array([fl_top, fr_top]), gold, 1.2)
	draw_polyline(PackedVector2Array([fl_bot, fr_bot]), gold_dim, 1.0)

	# Corner rivet plates
	_draw_corner_rivet(tl_top, C_GOLD, 14.0, false, false)
	_draw_corner_rivet(tr_top, C_GOLD, 14.0, true,  false)
	_draw_corner_rivet(fl_bot, C_GOLD, 14.0, false, true)
	_draw_corner_rivet(fr_bot, C_GOLD, 14.0, true,  true)

func _draw_corner_rivet(pos: Vector2, col: Color, size: float, flip_x: bool, flip_y: bool) -> void:
	var sx := -1.0 if flip_x else 1.0
	var sy := -1.0 if flip_y else 1.0
	var pts := PackedVector2Array([
		pos,
		pos + Vector2(sx * size, 0),
		pos + Vector2(sx * size * 0.55, sy * size * 0.55),
		pos + Vector2(0, sy * size)
	])
	draw_colored_polygon(pts, Color(col.r, col.g, col.b, 0.75))
	var rivet_pos := pos + Vector2(sx * size * 0.38, sy * size * 0.38)
	draw_circle(rivet_pos, 2.2, Color(0.15, 0.08, 0.0, 0.9))
	draw_circle(rivet_pos, 1.0, Color(1, 0.95, 0.7, 0.5))

# ─────────────────────────────────────────────────────────────────────────────
# INSTRUMENT COMPONENTS
# ─────────────────────────────────────────────────────────────────────────────

func _draw_tuning_peg(peg_pos: Vector2, tl_top: Vector2, tl_bot: Vector2) -> void:
	# Trục cuộn: small metal fitting at the left end anchoring the string
	# Sits ON the top surface, partially sticking up

	# Peg block (dark wood mount)
	var block_w := 10.0
	var block_h := 8.0
	draw_rect(Rect2(peg_pos.x - block_w * 0.5, peg_pos.y - block_h, block_w, block_h), Color("#1a0a02"))
	draw_rect(Rect2(peg_pos.x - block_w * 0.5 + 1, peg_pos.y - block_h + 1, block_w - 2, block_h - 2), Color("#2e1508"))

	# Metal pin
	draw_rect(Rect2(peg_pos.x - 2, peg_pos.y - block_h - 4, 4, 10), Color("#3a3028"))

	# Metal cap with 3D shading (top knob)
	draw_circle(Vector2(peg_pos.x, peg_pos.y - block_h - 4), 4.5, Color("#252020"))
	draw_circle(Vector2(peg_pos.x, peg_pos.y - block_h - 4), 3.2, Color("#4a3c30"))
	draw_circle(Vector2(peg_pos.x - 1, peg_pos.y - block_h - 5), 1.2, Color(1, 1, 1, 0.40))  # specular

	# Gold collar ring
	draw_arc(peg_pos + Vector2(0, -block_h * 0.5), 5.5, 0, TAU, 12, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.65), 1.2)

func _draw_rod_socket(rod_base: Vector2, tr_top: Vector2) -> void:
	# Socket collar where the horn rod inserts into the body (right end, top)
	var sx := rod_base.x
	var sy := rod_base.y

	# Cylindrical socket (brass/copper look)
	var sock_h := 14.0
	var sock_w := 10.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(sx - sock_w * 0.5, sy),
		Vector2(sx + sock_w * 0.5, sy),
		Vector2(sx + sock_w * 0.6, sy - sock_h),
		Vector2(sx - sock_w * 0.6, sy - sock_h)
	]), C_GOLD_DARK)
	draw_colored_polygon(PackedVector2Array([
		Vector2(sx - sock_w * 0.35, sy),
		Vector2(sx + sock_w * 0.35, sy),
		Vector2(sx + sock_w * 0.4, sy - sock_h + 2),
		Vector2(sx - sock_w * 0.4, sy - sock_h + 2)
	]), C_GOLD)
	draw_polyline(PackedVector2Array([
		Vector2(sx - sock_w * 0.5, sy - sock_h),
		Vector2(sx + sock_w * 0.5, sy - sock_h),
		Vector2(sx + sock_w * 0.6, sy),
		Vector2(sx - sock_w * 0.6, sy)
	]), C_GOLD_LIGHT, 0.8, true)

func _draw_string(str_start: Vector2, str_end: Vector2, sy_l: float, sy_r: float) -> void:
	# Single monochord string with vibration wave if recently plucked
	var str_pts := PackedVector2Array()
	str_pts.append(str_start)

	if _pluck_amp > 0.005:
		var spd := 90.0
		for k in range(1, 32):
			var ratio := float(k) / 32.0
			var px := lerpf(str_start.x, str_end.x, ratio)
			var py := lerpf(str_start.y, str_end.y, ratio)  # interpolate y along perspective
			var decay := exp(-_pluck_time * 2.0)
			var osc   := sin(ratio * PI) * sin(ratio * PI * 5.0 - _pluck_time * spd) * _pluck_amp * 8.0 * decay
			str_pts.append(Vector2(px, py + osc))
	str_pts.append(str_end)

	# Shadow
	var shadow_pts := PackedVector2Array()
	for pt in str_pts:
		shadow_pts.append(pt + Vector2(0, 3))
	draw_polyline(shadow_pts, Color(0, 0, 0, 0.35), 1.2, true)

	# Glow when vibrating
	if _pluck_amp > 0.01:
		draw_polyline(str_pts, Color(C_STRING_VIBE.r, C_STRING_VIBE.g, C_STRING_VIBE.b, _pluck_amp * 0.50), 4.5, true)

	# String core
	var str_col := C_STRING_VIBE if _pluck_amp > 0.1 else C_STRING
	if _is_bending:
		str_col = Color("#fc882b")
	draw_polyline(str_pts, str_col, 1.6, true)

func _draw_harmonic_nodes(sy_l: float, sy_r: float, bx_l: float, bx_r: float, font: Font) -> void:
	# 7 harmonic touch nodes arranged along the string path
	var start_x := bx_l + W_safe() * 0.10
	var end_x   := bx_r - W_safe() * 0.04
	var step_x  := (end_x - start_x) / float(NODE_COUNT - 1)

	for i in NODE_COUNT:
		var t_x  := start_x + float(i) * step_x
		# Y follows the string perspective (interpolated)
		var t_ratio := (t_x - bx_l) / (bx_r - bx_l)
		var ny := lerpf(sy_l, sy_r, t_ratio)
		_draw_ivory_node(Vector2(t_x, ny), i,
			_is_target[i] == 1, _hovered_node_idx == i, _glow_alpha[i], _pulse_phase, font)

func W_safe() -> float:
	return maxf(size.x, 80.0)

func _draw_gourd(gourd_pos: Vector2, tr_top: Vector2, tr_bot: Vector2) -> void:
	# Quả bầu: the golden gourd resonator that sits at the right end of the instrument
	# Rests partially on the top surface and partially hanging off the right side
	# Shape: large spherical bulb (bottom) + smaller neck (top) — iconic double-gourd shape

	var gx := gourd_pos.x + 12.0   # offset from body edge
	var gy := gourd_pos.y - 8.0    # slightly above string line (on top surface level)

	var bulb_r  := 16.0
	var neck_r  := 9.5
	var neck_dy := -22.0  # neck is above bulb

	# ── Bulb shadow ──
	draw_circle(Vector2(gx, gy + 4), bulb_r + 3, Color(0, 0, 0, 0.30))

	# ── Lower bulb (3D sphere shading) ──
	var steps := 20
	for i in range(steps):
		var r_ratio := float(steps - i) / float(steps)
		var r := bulb_r * r_ratio
		var offset := Vector2(-0.8, -0.8) * (1.0 - r_ratio)
		var center  := Vector2(gx, gy) + offset
		var col := C_WOOD_DARK.lerp(C_GOURD_GOLD, r_ratio)
		if r_ratio > 0.80:
			col = col.lerp(C_GOURD_HIGH, (r_ratio - 0.80) / 0.20 * 0.85)
		draw_circle(center, r, col)

	# Bulb specular
	draw_circle(Vector2(gx - 4.5, gy - 5.5), 2.8, Color(1, 1, 1, 0.72))

	# Bulb decorative engraved ring
	draw_arc(Vector2(gx, gy), bulb_r * 0.62, 0.0, TAU, 24, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.55), 1.0)

	# ── Connection: small red silk cord between gourd and rod ──
	draw_arc(Vector2(gx, gy + neck_dy * 0.5), 3.0, 0.0, TAU, 12, Color("#cc2222", 0.85), 1.8)
	draw_arc(Vector2(gx, gy + neck_dy * 0.5 + 4), 2.5, 0.0, TAU, 10, Color("#cc2222", 0.85), 1.5)

	# ── Upper neck bulb (smaller, sits on top of lower) ──
	var nc := Vector2(gx, gy + neck_dy)
	draw_circle(nc + Vector2(0, 2.5), neck_r + 2, Color(0, 0, 0, 0.28))
	for i in range(steps):
		var r_ratio := float(steps - i) / float(steps)
		var r := neck_r * r_ratio
		var offset := Vector2(-0.6, -0.6) * (1.0 - r_ratio)
		var center  := nc + offset
		var col := C_WOOD_DARK.lerp(C_GOURD_GOLD, r_ratio * 0.90)
		if r_ratio > 0.82:
			col = col.lerp(C_GOURD_HIGH, (r_ratio - 0.82) / 0.18 * 0.75)
		draw_circle(center, r, col)
	draw_circle(nc + Vector2(-2.5, -3.0), 1.8, Color(1, 1, 1, 0.65))  # specular

	# Engraved floral on neck
	draw_arc(nc, neck_r * 0.65, 0.0, TAU, 16, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.50), 0.8)

	# ── Top knob / tip ──
	var tip_c := nc + Vector2(0, -neck_r - 3.5)
	draw_circle(tip_c, 3.5, Color("#3d1b03"))
	draw_circle(tip_c, 2.0, Color("#c07010"))
	draw_circle(tip_c + Vector2(-0.8, -1.0), 0.7, Color(1, 1, 1, 0.55))

func _draw_horn_rod(rod_base: Vector2, rod_tip: Vector2) -> void:
	# Cần đàn: the horn/buffalo horn rod that curves elegantly upward from the gourd
	# In real dan bau: made from polished buffalo horn, dark near-black color,
	# curving in an elegant S/crescent shape.

	# Bezier control points for the curved rod
	var gx := rod_base.x + 14.0  # rod actually starts from above the gourd neck
	var gy := rod_base.y - 36.0  # above the gourd
	var start := Vector2(gx, gy)

	# The curve arcs up and slightly left, ending with the tip pointing up
	var ctrl1 := Vector2(gx + 8,  gy  - 30)  # first bend, pulls outward
	var ctrl2 := Vector2(rod_tip.x + 15, rod_tip.y + 20)
	var tip    := rod_tip

	# Build polyline from cubic bezier
	var rod_pts := PackedVector2Array()
	var seg_cnt := 24
	for k in range(seg_cnt + 1):
		var t := float(k) / float(seg_cnt)
		rod_pts.append(_cubic_bezier(start, ctrl1, ctrl2, tip, t))

	# Shadow
	var shd_pts := PackedVector2Array()
	for pt in rod_pts:
		shd_pts.append(pt + Vector2(2, 3))
	for k in range(seg_cnt):
		var t_mid := float(k) / float(seg_cnt)
		var thick := lerpf(9.0, 2.5, t_mid)
		draw_line(shd_pts[k], shd_pts[k+1], Color(0, 0, 0, 0.22), thick, true)

	# Main rod body (dark horn, slightly graduated)
	for k in range(seg_cnt):
		var t_mid := float(k) / float(seg_cnt)
		var thick := lerpf(8.5, 2.0, t_mid)
		var col   := C_HORN_DARK.lerp(C_HORN_MID, 0.4 + 0.3 * sin(t_mid * PI))
		draw_line(rod_pts[k], rod_pts[k+1], col, thick, true)
		draw_circle(rod_pts[k], thick * 0.5, col)

		# Specular highlight on top edge
		var specular := Color(1.0, 1.0, 1.0, 0.14 * (1.0 - t_mid))
		var pt_offset := rod_pts[k] - Vector2(0, thick * 0.2)
		var pt2_off   := rod_pts[k+1] - Vector2(0, thick * 0.2)
		draw_line(pt_offset, pt2_off, specular, thick * 0.22, true)

	# Tip cap (small rounded end)
	draw_circle(tip, 2.8, C_HORN_MID)
	draw_circle(tip + Vector2(-0.6, -0.6), 0.9, Color(1, 1, 1, 0.40))

func _cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	return u*u*u*p0 + 3*u*u*t*p1 + 3*u*t*t*p2 + t*t*t*p3

# ─────────────────────────────────────────────────────────────────────────────
# HARMONIC NODE
# ─────────────────────────────────────────────────────────────────────────────
func _draw_ivory_node(pos: Vector2, idx: int, is_target: bool, is_hovered: bool,
		glow_alpha: float, pulse_phase: float, font: Font) -> void:
	var brass_col  := C_GOLD
	var ivory_col  := Color("#faf5e6")
	var shadow_col := Color(0, 0, 0, 0.28)

	# Drop shadow
	draw_circle(pos + Vector2(0, 2.5), 11.5, shadow_col)

	# Target pulse glow
	if is_target:
		var pulse  := (sin(pulse_phase * 2.0) + 1.0) * 0.5
		var glow_r := 16.0 + pulse * 5.0
		draw_circle(pos, glow_r, Color(0.79, 0.60, 0.24, 0.14 + pulse * 0.14))
		draw_arc(pos, glow_r, 0.0, TAU, 28, Color(0.79, 0.60, 0.24, 0.35 + pulse * 0.25), 1.3)

	# Pluck glow
	if glow_alpha > 0.01:
		var pluck_r := 11.0 + glow_alpha * 22.0
		draw_circle(pos, pluck_r, Color(1, 0.95, 0.75, glow_alpha * 0.42))
		draw_arc(pos, pluck_r, 0.0, TAU, 24, Color(1, 0.90, 0.5, glow_alpha * 0.52), 1.5)

	# Node size
	var base_r := 9.5
	if is_hovered: base_r = 11.0
	elif is_target: base_r = 10.5

	# Layered ivory node (brass outer ring → ivory face → brass inner ring → dark core)
	draw_circle(pos, base_r,        brass_col)
	draw_circle(pos, base_r - 1.5,  ivory_col)
	draw_circle(pos, base_r - 4.0,  brass_col)
	draw_circle(pos, base_r - 6.0,  Color("#1e1008"))
	draw_circle(pos, 1.2,           Color(1, 1, 1, 0.75))  # glint

	# Label above node
	if font != null:
		var text := _note_names[idx] if idx < _note_names.size() else NOTES_VN[idx]
		var label_y := pos.y - 20.0
		var text_col := Color("#faf6eb") if is_target else (Color.WHITE if is_hovered else Color("#ccbfaf"))
		var font_sz  := 13 if (is_target or is_hovered) else 11
		var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_sz)
		var tp := Vector2(pos.x - ts.x * 0.5, label_y)
		draw_string(font, tp + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_sz, Color(0, 0, 0, 0.70))
		draw_string(font, tp, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_sz, text_col)

# ─────────────────────────────────────────────────────────────────────────────
# BEND GAUGE & CENTS READOUT
# ─────────────────────────────────────────────────────────────────────────────
func _draw_bend_gauge(center: Vector2, radius: float, cents: float) -> void:
	var angle_start := -PI * 0.75
	var angle_end   := -PI * 0.25
	var steps := 32

	var bg_pts := PackedVector2Array()
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var a := lerpf(angle_start, angle_end, t)
		bg_pts.append(center + Vector2(cos(a), sin(a)) * radius)
	draw_polyline(bg_pts, Color(1, 1, 1, 0.12), 3.5, true)

	var tick_cnt := 7
	for j in range(tick_cnt):
		var t  := float(j) / float(tick_cnt - 1)
		var ta := lerpf(angle_start, angle_end, t)
		draw_line(center + Vector2(cos(ta), sin(ta)) * (radius - 3), center + Vector2(cos(ta), sin(ta)) * (radius + 3), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45), 1.0)

	var mid_a := (angle_start + angle_end) * 0.5
	draw_line(center + Vector2(cos(mid_a), sin(mid_a)) * (radius - 5), center + Vector2(cos(mid_a), sin(mid_a)) * (radius + 5), Color(0.85, 0.72, 0.35, 0.7), 1.5)

	if abs(cents) > 2.0:
		var target_a := mid_a
		var color := Color.WHITE
		if cents > 0.0:
			target_a = lerpf(mid_a, angle_end, clampf(cents / 350.0, 0, 1))
			color = Color("#27ae60")
		else:
			target_a = lerpf(mid_a, angle_start, clampf(-cents / 350.0, 0, 1))
			color = Color("#d35400")
		var fill_pts := PackedVector2Array()
		var fsteps := 16
		for i in range(fsteps + 1):
			var t := float(i) / float(fsteps)
			var a := lerpf(mid_a, target_a, t)
			fill_pts.append(center + Vector2(cos(a), sin(a)) * radius)
		draw_polyline(fill_pts, Color(color.r, color.g, color.b, 0.25), 7.0, true)
		draw_polyline(fill_pts, color, 2.5, true)
		var ep := center + Vector2(cos(target_a), sin(target_a)) * radius
		draw_circle(ep, 3.5, Color.WHITE)
		draw_circle(ep, 5.0, Color(color.r, color.g, color.b, 0.50))

func _draw_cents_readout(font: Font, pos: Vector2, cents: float) -> void:
	if font == null: return
	var sign_str := "+" if cents > 0 else ""
	var txt := "%s%d ¢" % [sign_str, int(cents)]
	var color := C_GOLD
	if cents > 5.0:   color = Color("#2ecc71")
	elif cents < -5.0: color = Color("#e74c3c")
	var ts := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 13)
	var bw := ts.x + 14.0; var bh := ts.y + 4.0
	var br := Rect2(pos.x - bw * 0.5, pos.y - bh * 0.5, bw, bh)
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(0.04, 0.02, 0.01, 0.88)
	bs.border_color = Color(color.r, color.g, color.b, 0.50)
	bs.border_width_left = 1; bs.border_width_right = 1
	bs.border_width_top = 1; bs.border_width_bottom = 1
	bs.corner_radius_top_left = 8; bs.corner_radius_top_right = 8
	bs.corner_radius_bottom_left = 8; bs.corner_radius_bottom_right = 8
	draw_style_box(bs, br)
	draw_string(font, pos + Vector2(-ts.x * 0.5, ts.y * 0.5 - 2), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, color)

# ─────────────────────────────────────────────────────────────────────────────
# DECORATIVE HELPERS
# ─────────────────────────────────────────────────────────────────────────────
func _draw_bezier_spline(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, col: Color, w: float) -> void:
	var pts := PackedVector2Array()
	var steps := 14
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		pts.append(_cubic_bezier(p0, p1, p2, p3, t))
	draw_polyline(pts, col, w, true)

func _draw_mini_lotus(center: Vector2, col: Color) -> void:
	draw_circle(center, 2.0, col)
	var angles := [0.0, 72.0, 144.0, 216.0, 288.0]
	for a in angles:
		var rad := deg_to_rad(a)
		draw_circle(center + Vector2(cos(rad), sin(rad)) * 3.2, 1.4, Color(col.r, col.g, col.b, col.a * 0.70))

# ─────────────────────────────────────────────────────────────────────────────
# INPUT HANDLING
# ─────────────────────────────────────────────────────────────────────────────
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var ev := event as InputEventMouseButton
		if ev.button_index == MOUSE_BUTTON_LEFT:
			if ev.pressed: _handle_touch_start(ev.position)
			else:          _handle_touch_end()
	elif event is InputEventMouseMotion:
		var ev := event as InputEventMouseMotion
		_handle_touch_move(ev.position)
	elif event is InputEventScreenTouch:
		var ev := event as InputEventScreenTouch
		if ev.pressed: _handle_touch_start(ev.position)
		else:          _handle_touch_end()
	elif event is InputEventScreenDrag:
		var ev := event as InputEventScreenDrag
		_handle_touch_move(ev.position)

func _handle_touch_start(pos: Vector2) -> void:
	# Bend zone: top-right area near the gourd/rod
	var W := size.x
	var bend_zone_x := W * 0.75
	if pos.x > bend_zone_x:
		_is_bending = true
		_update_bend(pos.y)
	else:
		var node_idx := _get_node_at(pos)
		if node_idx != -1:
			pluck(node_idx)

func _handle_touch_move(pos: Vector2) -> void:
	if _is_bending:
		_update_bend(pos.y)
	else:
		var node_idx := _get_node_at(pos)
		if node_idx != _hovered_node_idx:
			_hovered_node_idx = node_idx
			queue_redraw()

func _handle_touch_end() -> void:
	_is_bending = false
	_hovered_node_idx = -1
	queue_redraw()

func _get_node_at(pos: Vector2) -> int:
	var W  := size.x
	var bx_l := W * 0.04
	var bx_r := W * 0.82
	var start_x := bx_l + W * 0.10
	var end_x   := bx_r - W * 0.04
	var step_x  := (end_x - start_x) / float(NODE_COUNT - 1)
	# String Y follows perspective
	var H  := size.y
	var top_surface_h := (H * 0.82 - H * 0.50) * 0.38
	var top_y_bot     := H * 0.50
	var top_y_top     := top_y_bot - top_surface_h
	var skew_right    := top_surface_h * SKEW_FACTOR
	var sy_l := (top_y_top + top_y_bot) * 0.5 + 4.0
	var sy_r := (top_y_top + skew_right + top_y_bot + skew_right * 0.3) * 0.5 + 4.0

	var click_r := 28.0
	for i in NODE_COUNT:
		var t_x    := start_x + float(i) * step_x
		var t_ratio := (t_x - bx_l) / (bx_r - bx_l)
		var ny     := lerpf(sy_l, sy_r, t_ratio)
		if pos.distance_to(Vector2(t_x, ny)) <= click_r:
			return i
	return -1

func _update_bend(touch_y: float) -> void:
	# Bend the rod vertically (push down or pull up)
	var H := size.y
	var mid_y := H * 0.30   # resting rod tip approximate Y
	var max_drag := H * 0.10

	_bend_offset   = clampf(touch_y - mid_y, -max_drag, max_drag)
	_bend_velocity = 0.0

	var factor := _bend_offset / max_drag
	_bend_cents = factor * 350.0
	pitch_bent.emit(_bend_cents)
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_hovered_node_idx = -1
		if _is_bending:
			_handle_touch_end()
		queue_redraw()
