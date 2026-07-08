extends Control

## ─────────────────────────────────────────────────────────────────────────
##  DanBauBoard  —  Vietnamese Đàn Bầu (Monochord) 2.5D Renderer
##
##  PHASE 2.3 - FINAL VISUAL REFINEMENT PASS:
##  - 5% horizontal zither shift to the right (`RATIO_BODY_LEFT = 0.13`, `RATIO_BODY_RIGHT = 0.97`)
##    to achieve perfect visual optical centering.
##  - 10% gourd resonator size reduction (`RATIO_GOURD_RADIUS = 0.74`).
##  - Natural bamboo rod curvature: lower 70% is straight, top curves gently outward.
##  - Taller bridge height (`RATIO_BRIDGE_HEIGHT = 1.10`) for better recognition.
##  - Thinner (0.55px) and brighter steel string with 0.65 opacity specular glint.
##  - Maintains all existing animations, gameplay, and public APIs.
## ─────────────────────────────────────────────────────────────────────────

signal string_plucked(idx: int, note_name: String)
signal pitch_bent(cents_offset: float)

const NODE_COUNT := 7
const NOTES_VN : Array[String] = ["Đô", "Rê", "Mi", "Fa", "Sol", "La", "Si"]

# ─── Layout Constants (Ratios based on Body Width) ──────────────────────────
const RATIO_BODY_LEFT          := 0.13   # Shifted right by 5% for optical balance
const RATIO_BODY_RIGHT         := 0.97   # Shifted right by 5% for optical balance
const RATIO_BODY_HEIGHT        := 0.065  # Elegant slim zither body thickness
const MIN_BODY_HEIGHT          := 32.0
const MAX_BODY_HEIGHT          := 65.0

const RATIO_SB_HEIGHT          := 0.28   # Soundboard height ratio of BH
const RATIO_FP_HEIGHT          := 0.72   # Front panel height ratio of BH

const RATIO_STRING_Y           := 0.12   # String height above soundboard ratio of BH
const RATIO_GOURD_RADIUS       := 0.74   # Gourd radius reduced by 10% (0.82 * 0.90)
const RATIO_GOURD_X_OFFSET     := 0.35   # Gourd X offset ratio of GR

const RATIO_ROD_BASE_Y         := 0.80   # Rod base Y offset ratio of GR
const RATIO_ROD_TIP_Y          := 2.6    # Rod tip Y height ratio of BH
const RATIO_ROD_LEAN_ANGLE     := 0.20   # Outward lean angle ratio
const RATIO_ROD_CTRL1_X        := 0.05   # Near 0.0 makes the lower 70% almost straight
const RATIO_ROD_CTRL1_Y        := 0.65   # Control point 1 Y offset ratio of BH
const RATIO_ROD_CTRL2_X        := 0.22   # Control point 2 X offset ratio of GR
const RATIO_ROD_CTRL2_Y        := 0.40   # Control point 2 Y offset ratio of BH

const RATIO_BRIDGE_X           := 0.08   # Bridge X position ratio of BW
const RATIO_BRIDGE_WIDTH       := 0.0065 # Bridge width ratio of total width
const RATIO_BRIDGE_HEIGHT      := 1.45   # Taller bridge — clearly supports the string

const RATIO_PEG_X              := 5.0    # Peg offset X from BR
const RATIO_PEG_HEIGHT         := 0.85   # Peg height ratio of soundboard height (taller)

const RATIO_NODES_START        := 0.16   # Node start X ratio of BW
const RATIO_NODES_END          := 0.90   # Node end X ratio of BW

# ─── Color Palette (Clean & Harmonious) ───────────────────────────────────────
const COLOR_OAK_MID    := Color("#cb9b44")   # Soundboard base oak wood
const COLOR_OAK_HI     := Color("#edd685")   # Soundboard highlight wood
const COLOR_OAK_SHD    := Color("#9e7228")   # Soundboard shadow edge
const COLOR_WAL_MID    := Color("#3d1d0c")   # Walnut zither side body
const COLOR_WAL_DRK    := Color("#1c0b03")   # Walnut deep shadow
const COLOR_WAL_HI     := Color("#5e2d14")   # Walnut light edge
const COLOR_GOURD_MID  := Color("#633818")   # Resonator coconut brown
const COLOR_GOURD_DRK  := Color("#2b1305")   # Resonator shadow
const COLOR_GOURD_HI   := Color("#9e6235")   # Resonator highlight
const COLOR_BAM_MID    := Color("#7a6c35")   # Bamboo stalk body
const COLOR_BAM_DRK    := Color("#423a18")   # Bamboo joint/shadow
const COLOR_BAM_HI     := Color("#b6a55c")   # Bamboo light segments
const COLOR_GOLD       := Color("#cc9b32")   # Gold brass decoration
const COLOR_GOLD_HI    := Color("#f2da78")   # Gold light reflection
const COLOR_GOLD_DRK   := Color("#7c5b08")   # Gold dark shadow
const COLOR_STR        := Color("#e8ecf5")   # Brighter steel string
const COLOR_STR_GLOW   := Color("#faf09e")   # String pluck glow

# ─── State Variables ──────────────────────────────────────────────────────────
var _note_names : Array[String]      = []
var _streams    : Array              = []
var _freqs      : Array[float]       = []

var _pluck_amp   := 0.0
var _pluck_time  := 0.0
var _glow_alpha  : PackedFloat32Array = PackedFloat32Array()
var _pulse_phase := 0.0
var _is_target   : PackedByteArray    = PackedByteArray()

var _is_bending    := false
var _bamboo_touch_index := -1
var _string_touch_index := -1
var _bend_offset   := 0.0      # vertical offset of bamboo rod tip (pixels)
var _bend_cents    := 0.0      # pitch bend in cents
var _bend_velocity := 0.0
var _hovered_node_idx := -1
var _target_node_idx  := 0

# Cached geometry for hit-testing and rendering
var _str_y       := 0.0
var _node_xs     : PackedFloat32Array = PackedFloat32Array()
var _bend_zone_x := 0.0      # everything to the left of this X is the bend zone

# ─── Public API ───────────────────────────────────────────────────────────────
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
	var dirty := false
	if _pluck_amp > 0.0:
		_pluck_time += delta
		_pluck_amp   = maxf(0.0, _pluck_amp - delta * 2.85) # Decays in exactly 0.35s
		dirty = true
	for i in NODE_COUNT:
		if _glow_alpha[i] > 0.0:
			_glow_alpha[i] = maxf(0.0, _glow_alpha[i] - delta * 4.5) # Decays in 0.22s
			dirty = true

	var is_animating := _pluck_amp > 0.0 or _is_bending or _bend_offset != 0.0 or _bend_velocity != 0.0
	for i in NODE_COUNT:
		if _glow_alpha[i] > 0.0:
			is_animating = true

	if is_animating:
		_pulse_phase += delta * 3.4
		dirty = true

	if not _is_bending and (_bend_offset != 0.0 or _bend_velocity != 0.0):
		var spring := 200.0
		var damp := 24.0
		var a := -spring * _bend_offset - damp * _bend_velocity
		_bend_velocity += a * delta; _bend_offset += _bend_velocity * delta
		if abs(_bend_offset) < 0.08 and abs(_bend_velocity) < 0.08:
			_bend_offset = 0.0; _bend_velocity = 0.0; _bend_cents = 0.0
			pitch_bent.emit(0.0)
		else:
			_bend_cents_update()
		dirty = true
	if dirty: queue_redraw()

func _bend_cents_update() -> void:
	_bend_cents = clampf(_bend_offset / _max_bend() * 350.0, -400.0, 400.0)
	pitch_bent.emit(_bend_cents)

func _max_bend() -> float:
	return maxf(size.y * 0.15, 12.0)

# ══════════════════════════════════════════════════════════════════════════
#  MAIN DRAW ORCHESTRATOR
# ══════════════════════════════════════════════════════════════════════════
func _draw() -> void:
	var W := size.x; var H := size.y
	if W < 120.0 or H < 40.0: return

	# Calculate Geometry Values based on layout ratios
	var BL  := W * RATIO_BODY_LEFT
	var BR  := W * RATIO_BODY_RIGHT
	var BW  := BR - BL

	# Perfectly horizontal zither body
	var BH  := clampf(BW * RATIO_BODY_HEIGHT, MIN_BODY_HEIGHT, MAX_BODY_HEIGHT)
	var SBH := BH * RATIO_SB_HEIGHT

	# Balanced screen layout: shifted zither body slightly below vertical center
	var BCY := H * 0.55
	var BT  := BCY - BH * 0.5
	var BB  := BCY + BH * 0.5

	var SBT := BT
	var SBB := BT + SBH
	var FPB := BB

	# Completely horizontal string line
	var SY  := SBT - BH * RATIO_STRING_Y
	_str_y  = SY

	# Gourd resonator (bầu cộng hưởng) on the LEFT side
	# Center at string height — lower half overlaps body left end, matching real đàn bầu
	var GR  := BH * RATIO_GOURD_RADIUS
	var GX  := BL - GR * RATIO_GOURD_X_OFFSET
	var GY  := SY  # Gourd center aligned with string: sits on body, upper half above

	# Bamboo rod (cần đàn) on the LEFT side leaning OUTWARD (to the left) by ~11.5°
	# Base anchors from the top of the resonator
	var RB   := Vector2(GX, GY - GR * RATIO_ROD_BASE_Y)

	# Bamboo rod leans to the LEFT (outward)
	var rod_height_val := BH * RATIO_ROD_TIP_Y
	var rod_lean := rod_height_val * RATIO_ROD_LEAN_ANGLE

	# Resting tip and resting curve control points (for stable base & lower 65% curvature)
	var RT_rest := Vector2(GX - rod_lean, BT - BH * RATIO_ROD_TIP_Y)
	var RC1  := Vector2(GX - rod_lean * RATIO_ROD_CTRL1_X, RB.y - BH * RATIO_ROD_CTRL1_Y)
	var RC2  := Vector2(RT_rest.x + GR * RATIO_ROD_CTRL2_X, RT_rest.y + BH * RATIO_ROD_CTRL2_Y)

	# Generate 8 stable points representing the bending bamboo rod
	# Lower 65% remains stable, only upper 35% flexes with tip_offset (max 6-8px)
	# Restricts Y movement entirely to prevent rubbery stretching/compression
	var SEG_ROD := 7
	var rod_pts := PackedVector2Array()
	var tip_offset := _bend_offset * 0.12 # ~6-8px lateral displacement at max bend
	for k in SEG_ROD + 1:
		var t := float(k) / float(SEG_ROD)
		var p_rest := _cbez(RB, RC1, RC2, RT_rest, t)
		var flex_t := 0.0
		if t > 0.65:
			flex_t = pow((t - 0.65) / 0.35, 3.0) # Cubic ease for natural tip flex
		var p := p_rest + Vector2(tip_offset * flex_t, 0.0) # Fixed Y to avoid stretching
		rod_pts.append(p)

	var RT := rod_pts[SEG_ROD]

	# String: slight downward slope from resonator side to chốt dây at right end
	# Left end (near gourd) is slightly higher; right end terminates at chốt dây
	var SS := Vector2(GX + GR * 0.22, SY - BH * 0.05)  # Left end slightly raised
	var SE := Vector2(BR - RATIO_PEG_X, SY)             # Ends at chốt dây (not bridge)

	# Harmonic Nodes: start near gourd (left) and end near bridge (right)
	var N0  := BL + BW * RATIO_NODES_START
	var N1  := BR - BW * (1.0 - RATIO_NODES_END)
	var NST := (N1 - N0) / float(NODE_COUNT - 1)
	_node_xs.resize(NODE_COUNT)
	for i in NODE_COUNT:
		_node_xs[i] = N0 + float(i) * NST

	# Bend zone on the LEFT side
	_bend_zone_x = BL + BW * (1.0 - RATIO_NODES_END)

	# Execute Clean Render Stack (Back-to-Front Order)
	_draw_shadow(BL, BR, BB)
	_draw_feet(BL, BR, BB, BH)
	_draw_front_panel(BL, BR, SBB, FPB)
	_draw_soundboard(BL, BR, SBT, SBB)
	_draw_side_caps(BL, BR, SBT, FPB)
	_draw_gold_borders(BL, BR, SBT, SBB, FPB)
	_draw_end_block(BR, SBT, FPB)
	_draw_bridge(BR - BW * RATIO_BRIDGE_X, SY, SBB) # Bridge on the RIGHT
	_draw_string(SS, SE)
	_draw_nodes(SY)
	_draw_gourd(GX, GY, GR)
	_draw_bamboo_rod(rod_pts, GR)
	_draw_tuning_peg(BR - RATIO_PEG_X, SY, SBT, SBB) # Tuning peg on the RIGHT

	if _is_bending:
		var f := get_theme_font("font")
		if f: _draw_cents_badge(f, RT + Vector2(18.0, 0.0), _bend_cents)

# ══════════════════════════════════════════════════════════════════════════
#  MODULAR DRAW PIECES
# ══════════════════════════════════════════════════════════════════════════

func _draw_shadow(BL: float, BR: float, BB: float) -> void:
	var W := size.x
	var BH := clampf((BR - BL) * RATIO_BODY_HEIGHT, MIN_BODY_HEIGHT, MAX_BODY_HEIGHT)
	var GR := BH * RATIO_GOURD_RADIUS
	var start_x := BL - GR * 1.5 # Extend left under gourd resonator
	var end_x := BR + 15.0
	var sy := BB + 4.5

	# Outer soft ambient shadow
	draw_line(Vector2(start_x, sy), Vector2(end_x, sy), Color(0, 0, 0, 0.04), 16.0, true)

	# Mid soft ambient shadow
	draw_line(Vector2(start_x + 15.0, sy), Vector2(end_x - 10.0, sy), Color(0, 0, 0, 0.08), 10.0, true)

	# Inner dark occlusion shadow (tighter, closer to zither base)
	draw_line(Vector2(BL - 10.0, sy - 1.0), Vector2(BR + 10.0, sy - 1.0), Color(0, 0, 0, 0.16), 5.0, true)

func _draw_feet(BL: float, BR: float, BB: float, BH: float) -> void:
	var FW : float = BH * 0.26
	var FH : float = BH * 0.08
	var positions : Array[float] = [0.15, 0.85] # Exactly two support feet
	for p in positions:
		var fx : float = BL + (BR - BL) * p
		# Shadow under foot
		draw_circle(Vector2(fx, BB + FH + 1.0), FW * 0.40, Color(0, 0, 0, 0.20))
		
		var foot_poly := PackedVector2Array([
			Vector2(fx - FW * 0.50, BB),       Vector2(fx + FW * 0.50, BB),
			Vector2(fx + FW * 0.40, BB + FH),  Vector2(fx - FW * 0.40, BB + FH)
		])
		draw_colored_polygon(foot_poly, COLOR_WAL_DRK)
		draw_polyline(foot_poly, COLOR_WAL_DRK, 0.8, true)
		
		draw_line(Vector2(fx - FW * 0.45, BB), Vector2(fx + FW * 0.45, BB), COLOR_WAL_MID, 0.8)

func _draw_front_panel(BL: float, BR: float, TOP: float, BOT: float) -> void:
	var front_poly := PackedVector2Array([
		Vector2(BL, TOP), Vector2(BR, TOP), Vector2(BR, BOT), Vector2(BL, BOT)
	])
	draw_colored_polygon(front_poly, COLOR_WAL_MID)
	draw_polyline(front_poly, COLOR_WAL_MID, 1.0, true)
	
	draw_line(Vector2(BL, BOT - 1.0), Vector2(BR, BOT - 1.0), COLOR_WAL_DRK, 1.2, true)
	draw_line(Vector2(BL, TOP + 1.0), Vector2(BR, TOP + 1.0), COLOR_WAL_HI, 0.8, true)

	var h := BOT - TOP
	var rng := RandomNumberGenerator.new(); rng.seed = 66554
	for _j in 5:
		var f   : float = rng.randf()
		var gy  := lerpf(TOP + 3.0, BOT - 3.0, f)
		var pts := PackedVector2Array()
		for k in 24:
			var t  := float(k) / 23.0
			pts.append(Vector2(lerpf(BL+6, BR-6, t), gy + sin(t * 9.0 + f * 5.0) * (0.6 + f * 0.3)))
		var gc := COLOR_WAL_DRK.lerp(COLOR_WAL_MID, f * 0.3)
		gc.a    = rng.randf_range(0.04, 0.10)
		draw_polyline(pts, gc, 0.6, true)

func _draw_soundboard(BL: float, BR: float, TOP: float, BOT: float) -> void:
	var sb_poly := PackedVector2Array([
		Vector2(BL, TOP), Vector2(BR, TOP), Vector2(BR, BOT), Vector2(BL, BOT)
	])
	draw_colored_polygon(sb_poly, COLOR_OAK_MID)
	draw_polyline(sb_poly, COLOR_OAK_MID, 1.0, true)

	# Draw a narrow darker walnut frame border around the soundboard
	draw_rect(Rect2(BL, TOP, BR - BL, BOT - TOP), COLOR_WAL_DRK, false, 1.8)

	draw_line(Vector2(BL, TOP + 0.5), Vector2(BR, TOP + 0.5), COLOR_OAK_SHD, 1.0, true)
	draw_line(Vector2(BL, BOT - 0.5), Vector2(BR, BOT - 0.5), COLOR_OAK_HI, 0.8, true)

	var h := BOT - TOP
	var rng := RandomNumberGenerator.new(); rng.seed = 12345
	for _j in 3:
		var f   : float = rng.randf()
		var gy  := lerpf(TOP + 2.0, BOT - 2.0, f)
		var pts := PackedVector2Array()
		for k in 26:
			var t  := float(k) / 25.0
			pts.append(Vector2(lerpf(BL+4, BR-4, t), gy + sin(t*14.0+f*6.0)*1.1 + cos(t*5.0)*0.3))
		var gc := COLOR_OAK_SHD.lerp(COLOR_OAK_MID, f * 0.5)
		gc.a    = rng.randf_range(0.05, 0.12)
		draw_polyline(pts, gc, 0.6, true)

func _draw_side_caps(BL: float, BR: float, TOP: float, BOT: float) -> void:
	var d := 5.0
	# Left cap (beveled dark walnut)
	var cap_l := PackedVector2Array([
		Vector2(BL - d, TOP + 2.0), Vector2(BL, TOP),
		Vector2(BL, BOT),             Vector2(BL - d, BOT - 2.0)
	])
	draw_colored_polygon(cap_l, COLOR_WAL_DRK)
	draw_polyline(cap_l, COLOR_WAL_DRK, 0.8, true)
	# Top highlight on left cap
	draw_line(Vector2(BL - d, TOP + 2.0), Vector2(BL, TOP), COLOR_WAL_HI, 0.8, true)
	
	# Right cap (beveled dark walnut)
	var cap_r := PackedVector2Array([
		Vector2(BR, TOP),             Vector2(BR + d, TOP + 2.0),
		Vector2(BR + d, BOT - 2.0), Vector2(BR, BOT)
	])
	draw_colored_polygon(cap_r, COLOR_WAL_DRK)
	draw_polyline(cap_r, COLOR_WAL_DRK, 0.8, true)
	# Top highlight on right cap
	draw_line(Vector2(BR, TOP), Vector2(BR + d, TOP + 2.0), COLOR_WAL_HI, 0.8, true)

func _draw_gold_borders(BL: float, BR: float, SBT: float, SBB: float, FPB: float) -> void:
	draw_line(Vector2(BL, SBT), Vector2(BR, SBT), COLOR_GOLD, 0.8, true)
	draw_line(Vector2(BL, SBB), Vector2(BR, SBB), COLOR_GOLD, 1.0, true)
	draw_line(Vector2(BL, FPB), Vector2(BR, FPB), COLOR_GOLD_DRK, 0.8, true)

	var si := (SBB - SBT) * 0.15
	draw_polyline(PackedVector2Array([
		Vector2(BL + 14, SBT + si), Vector2(BR - 14, SBT + si),
		Vector2(BR - 14, SBB - si), Vector2(BL + 14, SBB - si),
		Vector2(BL + 14, SBT + si)
	]), Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.52), 0.7, true)

	var rs := minf((SBB - SBT) * 0.45, 9.0)
	_rivet(Vector2(BL, SBT), rs, false, false)
	_rivet(Vector2(BR, SBT), rs, true,  false)
	_rivet(Vector2(BL, FPB), rs, false, true)
	_rivet(Vector2(BR, FPB), rs, true,  true)

func _rivet(p: Vector2, s: float, fx: bool, fy: bool) -> void:
	var sx := -1.0 if fx else 1.0; var sy := -1.0 if fy else 1.0
	var rivet_poly := PackedVector2Array([
		p, p + Vector2(sx * s, 0.0),
		p + Vector2(sx * s * 0.5, sy * s * 0.5), p + Vector2(0.0, sy * s)
	])
	draw_colored_polygon(rivet_poly, COLOR_GOLD_DRK.lerp(COLOR_GOLD, 0.3))
	draw_polyline(rivet_poly, COLOR_GOLD_DRK.lerp(COLOR_GOLD, 0.3), 0.8, true)
	
	draw_circle(p + Vector2(sx * s * 0.35, sy * s * 0.35), 1.0, COLOR_GOLD_HI)

func _draw_end_block(br: float, sbt: float, fpb: float) -> void:
	var w := 12.0
	# Base block polygon
	var e_poly := PackedVector2Array([
		Vector2(br - w, sbt - 1.0), Vector2(br, sbt - 1.0),
		Vector2(br, fpb + 1.0), Vector2(br - w, fpb + 1.0)
	])
	draw_colored_polygon(e_poly, COLOR_WAL_DRK)
	draw_polyline(e_poly, COLOR_WAL_MID, 0.8, true)
	
	# Highlight edge on left side of the end-block
	draw_line(Vector2(br - w, sbt - 1.0), Vector2(br - w, fpb + 1.0), COLOR_WAL_HI, 1.0, true)

func _draw_bridge(bx: float, sy: float, sb_bot: float) -> void:
	var bw := size.x * RATIO_BRIDGE_WIDTH
	var bh := (sb_bot - sy) * RATIO_BRIDGE_HEIGHT
	
	# Main dark wood bridge support block (trapezoid body)
	var bridge_poly := PackedVector2Array([
		Vector2(bx - bw, sy + 1.0), Vector2(bx + bw, sy + 1.0),
		Vector2(bx + bw * 0.65, sy + bh),
		Vector2(bx + bw * 0.20, sy + bh),
		Vector2(bx, sy + bh * 0.40), # Arched cutout
		Vector2(bx - bw * 0.20, sy + bh),
		Vector2(bx - bw * 0.65, sy + bh)
	])
	draw_colored_polygon(bridge_poly, COLOR_WAL_DRK)
	draw_polyline(bridge_poly, COLOR_WAL_MID, 0.8, true)
	
	# Lighter saddle plate on top with a center V-notch
	var saddle_poly := PackedVector2Array([
		Vector2(bx - bw, sy), Vector2(bx - 1.5, sy),
		Vector2(bx, sy + 1.2), # notch cutout
		Vector2(bx + 1.5, sy), Vector2(bx + bw, sy),
		Vector2(bx + bw, sy + 1.8), Vector2(bx - bw, sy + 1.8)
	])
	draw_colored_polygon(saddle_poly, COLOR_OAK_HI)
	draw_polyline(saddle_poly, COLOR_OAK_MID, 0.6, true)

func _draw_string(ss: Vector2, se: Vector2) -> void:
	# Thinner 0.55px steel string with brighter specular glint
	var pts := PackedVector2Array()
	pts.append(ss)
	
	if _pluck_amp > 0.005:
		for k in range(1, 36):
			var t   : float = float(k) / 36.0
			var px  : float = lerpf(ss.x, se.x, t)
			var py  : float = lerpf(ss.y, se.y, t)
			var osc : float = sin(t * PI) * sin(t * PI * 5.0 - _pluck_time * 88.0) * _pluck_amp * 4.5 * exp(-_pluck_time * 1.8)
			pts.append(Vector2(px, py + osc))
			
	pts.append(se)

	# Clean thin shadow
	var shd := PackedVector2Array()
	for p in pts: shd.append(p + Vector2(0.0, 1.0))
	draw_polyline(shd, Color(0, 0, 0, 0.12), 0.5, true)

	# Main wire core (clean solid color, orange when bending, anti-aliased)
	var sc_glow := COLOR_STR_GLOW if _pluck_amp > 0.12 else COLOR_STR
	if _is_bending:
		sc_glow = Color("#ff9418")
	draw_polyline(pts, sc_glow, 0.55, true) # Thinner 0.55px
	
	# Specular bright white glint overlay (increased brightness/opacity to 0.65)
	var spec_pts := PackedVector2Array()
	for p in pts: spec_pts.append(p - Vector2(0.0, 0.3))
	draw_polyline(spec_pts, Color(1, 1, 1, 0.65), 0.35, true)

func _draw_nodes(sy: float) -> void:
	var font := get_theme_font("font")
	for i in NODE_COUNT:
		_draw_node(Vector2(_node_xs[i], sy), i, _is_target[i] == 1, _hovered_node_idx == i, _glow_alpha[i], font)

func _draw_node(pos: Vector2, idx: int, tgt: bool, hov: bool, glow: float, font: Font) -> void:
	# Subtle drop shadow
	draw_circle(pos + Vector2(0, 1.0), 6.5, Color(0, 0, 0, 0.18))
	
	if glow > 0.01:
		draw_circle(pos, 6.5 + glow * 8.0, Color(COLOR_STR_GLOW.r, COLOR_STR_GLOW.g, COLOR_STR_GLOW.b, glow * 0.35))

	if tgt:
		var p := (sin(_pulse_phase * 2.0) + 1.0) * 0.5
		draw_arc(pos, 10.0 + p * 2.0, 0.0, TAU, 16, Color(COLOR_GOLD.r, COLOR_GOLD.g, COLOR_GOLD.b, 0.25 + p * 0.20), 0.8)

	var R : float = (5.8 + (0.8 if hov else (0.4 if tgt else 0.0))) * (1.0 + glow * 0.15)
	draw_circle(pos, R,        COLOR_GOLD)
	draw_circle(pos, R * 0.83,  Color("#FAF7EC"))
	draw_circle(pos, R * 0.62,  COLOR_GOLD_DRK)
	draw_circle(pos, R * 0.45,  COLOR_WAL_DRK)
	draw_circle(pos, 0.6,      Color.WHITE)

	if font == null: return
	var text := _note_names[idx] if idx < _note_names.size() else NOTES_VN[idx]
	var fsz  := 11 if (tgt or hov) else 9
	var tc   := (COLOR_OAK_HI if tgt else (Color.WHITE if hov else Color("#cbb085")))
	var ts   := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, fsz)
	var tp   := Vector2(pos.x - ts.x * 0.5, pos.y - R - 4.5)

	draw_string(font, tp + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, Color(0, 0, 0, 0.65))
	draw_string(font, tp,             text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, tc)

func _draw_gourd(gx: float, gy: float, gr: float) -> void:
	# gy is at string height (SY): lower half of gourd overlaps body left end — correct for real đàn bầu

	# 1. Decorative gold collar ring where gourd meets body left edge
	var W   := size.x
	var BL  := W * RATIO_BODY_LEFT
	draw_circle(Vector2(BL, gy), 3.5, COLOR_GOLD)
	draw_circle(Vector2(BL, gy), 2.0, COLOR_GOLD_DRK)

	# 2. Horizontal tuning peg protruding from the left side of the resonator
	var peg_x := gx - gr * 0.90
	draw_line(Vector2(peg_x, gy), Vector2(peg_x - 7.0, gy), COLOR_WAL_DRK, 2.2, true) # shaft
	# Peg head/knob
	var k_pos := Vector2(peg_x - 7.0, gy)
	draw_circle(k_pos, 2.5, COLOR_WAL_MID)
	draw_circle(k_pos - Vector2(0.5, 0.5), 1.8, COLOR_WAL_HI)
	draw_circle(k_pos, 0.8, COLOR_GOLD, true) # gold core pin

	# 3. Resonator body shadow
	draw_circle(Vector2(gx + 2.0, gy + 3.5), gr + 1.5, Color(0, 0, 0, 0.22))
	
	var pts := PackedVector2Array()
	var STEPS := 24
	for k in STEPS:
		var a := float(k) / float(STEPS) * TAU
		var r := gr
		if sin(a) < 0.0:
			r = gr * (0.65 + 0.35 * abs(cos(a)))
		pts.append(Vector2(gx + cos(a) * r, gy + sin(a) * r * 1.05))
		
	# Resonator body base color
	draw_colored_polygon(pts, COLOR_GOURD_MID)
	draw_polyline(pts, COLOR_GOURD_MID, 0.9, true)
	
	# Volumetric shadow overlay
	var shd_pts := PackedVector2Array()
	var center := Vector2(gx, gy)
	for p in pts:
		shd_pts.append(center + (p - center) * 0.94 + Vector2(gr * 0.06, gr * 0.06))
	draw_colored_polygon(shd_pts, COLOR_GOURD_DRK)
	draw_polyline(shd_pts, COLOR_GOURD_DRK, 0.9, true)
	
	# Warm highlight on upper-left area
	draw_circle(Vector2(gx - gr * 0.24, gy - gr * 0.26), gr * 0.13, Color(1, 1, 1, 0.55))
	draw_circle(Vector2(gx - gr * 0.14, gy - gr * 0.16), gr * 0.06, Color(1, 1, 1, 0.35))

func _draw_bamboo_rod(pts: PackedVector2Array, gr: float) -> void:
	var SEG := pts.size() - 1
	if SEG < 1: return

	# Draw drop shadow
	var shd := PackedVector2Array()
	for p in pts: shd.append(p + Vector2(1.5, 2.5))
	for k in SEG:
		draw_line(shd[k], shd[k + 1], Color(0, 0, 0, 0.08), lerpf(4.5, 2.0, float(k) / float(SEG)), true)

	# Pass 1: Dark brown outer stroke (fixed positive widths, anti-aliased)
	for k in SEG:
		var t := float(k) / float(SEG)
		var th := lerpf(4.5, 2.0, t)
		draw_line(pts[k], pts[k + 1], COLOR_BAM_DRK, th, true)

	# Pass 2: Lighter warm bamboo inner stroke (fixed positive widths, anti-aliased)
	for k in SEG:
		var t := float(k) / float(SEG)
		var th := lerpf(2.8, 0.8, t)
		var col := COLOR_BAM_MID.lerp(COLOR_BAM_HI, t * 0.4)
		draw_line(pts[k], pts[k + 1], col, th, true)

	# Bamboo node joints (only 2 subtle nodes, matted color, placed exactly at segment boundaries)
	for kp: float in [0.38, 0.72]:
		var ki := int(kp * float(SEG))
		if ki < pts.size():
			var t : float = kp
			var th := lerpf(2.8, 0.8, t)
			draw_circle(pts[ki], th * 0.75, COLOR_BAM_DRK)
			draw_circle(pts[ki], th * 0.45, COLOR_BAM_HI)

	# Clean brass mount collar at gourd base
	draw_arc(pts[0], gr * 0.14, 0.0, TAU, 10, COLOR_GOLD, 1.0, true)

func _draw_tuning_peg(px: float, sy: float, sbt: float, sbb: float) -> void:
	var ph := (sbb - sbt) * RATIO_PEG_HEIGHT
	var is_on_right := px > size.x * 0.5
	var dir := 1.0 if is_on_right else -1.0
	
	var peg_base_poly := PackedVector2Array([
		Vector2(px - 1.5 * dir, sy - 3.5), Vector2(px + 5.0 * dir, sy - 3.5),
		Vector2(px + 5.0 * dir, sy + 3.5), Vector2(px - 1.5 * dir, sy + 3.5)
	])
	draw_colored_polygon(peg_base_poly, COLOR_WAL_MID)
	draw_polyline(peg_base_poly, COLOR_WAL_MID, 0.8, true)

	draw_line(Vector2(px + 1.8 * dir, sy - ph * 0.30), Vector2(px + 1.8 * dir, sy - ph - 2.0), COLOR_WAL_DRK, 2.5, true)

	# Carved peg handle
	var kc := Vector2(px + 1.8 * dir, sy - ph - 2.0)
	var handle_poly := PackedVector2Array([
		kc + Vector2(-3.5 * dir, -1.8),
		kc + Vector2(3.5 * dir, -1.8),
		kc + Vector2(4.5 * dir, 0.0),
		kc + Vector2(3.5 * dir, 1.8),
		kc + Vector2(-3.5 * dir, 1.8),
		kc + Vector2(-4.5 * dir, 0.0)
	])
	draw_colored_polygon(handle_poly, COLOR_WAL_MID)
	draw_polyline(handle_poly, COLOR_WAL_MID, 0.8, true)
	
	draw_polyline(PackedVector2Array([
		kc + Vector2(-3.5 * dir, -1.8),
		kc + Vector2(3.5 * dir, -1.8),
		kc + Vector2(4.5 * dir, 0.0)
	]), COLOR_WAL_HI, 0.8, true)

	draw_arc(Vector2(px + 1.8 * dir, sy), 3.8, 0.0, TAU, 10, COLOR_GOLD, 0.8, true)

# ── Helper Drawings ──────────────────────────────────────────────────────────

func _draw_cents_badge(font: Font, pos: Vector2, cents: float) -> void:
	var txt := ("%s%d ¢") % ["+" if cents > 0 else "", int(cents)]
	var col := COLOR_GOLD
	if cents >  5.0: col = Color("#28cc70")
	elif cents < -5.0: col = Color("#e43c3c")
	var ts := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 13)
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(0.06, 0.03, 0.01, 0.90)
	bs.border_color = Color(col.r, col.g, col.b, 0.55)
	bs.border_width_left = 1; bs.border_width_right = 1
	bs.border_width_top = 1;  bs.border_width_bottom = 1
	bs.corner_radius_top_left = 7; bs.corner_radius_top_right = 7
	bs.corner_radius_bottom_left = 7; bs.corner_radius_bottom_right = 7
	draw_style_box(bs, Rect2(pos.x - ts.x * 0.5 - 7, pos.y - ts.y * 0.5 - 2, ts.x + 14, ts.y + 4))
	draw_string(font, pos + Vector2(-ts.x * 0.5, ts.y * 0.5 - 2), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col)

func _cbez(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var u := 1.0 - t; return u * u * u * p0 + 3.0 * u * u * t * p1 + 3.0 * u * t * t * p2 + t * t * t * p3

# ══════════════════════════════════════════════════════════════════════════
#  INPUT HANDLING & DESKTOP FALLBACK
# ══════════════════════════════════════════════════════════════════════════
func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey:
		var ek := ev as InputEventKey
		if ek.keycode == KEY_SPACE and ek.pressed and not ek.is_echo():
			pluck(_target_node_idx) # Desktop testing spacebar plucking fallback

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
		if e.pressed:
			_on_touch_press(e.position, e.index)
		else:
			_on_touch_release(e.index)
	elif ev is InputEventScreenDrag:
		var e := ev as InputEventScreenDrag
		_on_touch_drag(e.position, e.index)

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
		if ni != _hovered_node_idx: _hovered_node_idx = ni; queue_redraw()

func _on_release() -> void:
	_is_bending = false; _hovered_node_idx = -1; queue_redraw()

func _on_touch_press(pos: Vector2, index: int) -> void:
	# Check if touch falls in left bend zone
	if pos.x < _bend_zone_x:
		if _bamboo_touch_index == -1:
			_bamboo_touch_index = index
			_is_bending = true
			_do_bend(pos.y)
	else:
		if _string_touch_index == -1:
			_string_touch_index = index
			var ni := _node_at(pos)
			if ni >= 0: pluck(ni)

func _on_touch_release(index: int) -> void:
	if index == _bamboo_touch_index:
		_bamboo_touch_index = -1
		_is_bending = false
		queue_redraw()
	elif index == _string_touch_index:
		_string_touch_index = -1

func _on_touch_drag(pos: Vector2, index: int) -> void:
	if index == _bamboo_touch_index:
		_do_bend(pos.y)
	elif index == _string_touch_index:
		# Dragging finger on notes can trigger a pluck if crossing a node boundary
		var ni := _node_at(pos)
		if ni >= 0 and ni != _hovered_node_idx:
			_hovered_node_idx = ni
			pluck(ni)

func _node_at(pos: Vector2) -> int:
	if _node_xs.size() < NODE_COUNT: return -1
	for i in NODE_COUNT:
		if pos.distance_to(Vector2(_node_xs[i], _str_y)) <= 28.0: return i
	return -1

func _do_bend(ty: float) -> void:
	var BW    : float = size.x * (RATIO_BODY_RIGHT - RATIO_BODY_LEFT)
	var BH    : float = clampf(BW * RATIO_BODY_HEIGHT, MIN_BODY_HEIGHT, MAX_BODY_HEIGHT)
	
	var BCY   : float = size.y * 0.55
	var BT    : float = BCY - BH * 0.5
	var SBT   : float = BT
	var GR    : float = BH * RATIO_GOURD_RADIUS
	var SY    : float = SBT - BH * RATIO_STRING_Y
	var GY    : float = SY  # Matches gourd position in _draw()
	var RB_y  : float = GY - GR * RATIO_ROD_BASE_Y
	var rest_y: float = RB_y
	var max_d : float = _max_bend()
	_bend_offset = clampf(ty - rest_y, -max_d, max_d)
	_bend_velocity = 0.0
	_bend_cents_update()
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_hovered_node_idx = -1
		if _is_bending: _on_release()
		_bamboo_touch_index = -1
		_string_touch_index = -1
		queue_redraw()
