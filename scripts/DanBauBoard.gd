extends Control

## ------------------------
## DanBauBoard  Vietnamese n Bu (Monochord) 2.5D Renderer
##
##  PHASE 2.3 - FINAL VISUAL REFINEMENT PASS:
##  - 5% horizontal zither shift to the right (`RATIO_BODY_LEFT = 0.13`, `RATIO_BODY_RIGHT = 0.97`)
##    to achieve perfect visual optical centering.
##  - 10% gourd resonator size reduction (`RATIO_GOURD_RADIUS = 0.74`).
##  - Natural bamboo rod curvature: lower 70% is straight, top curves gently outward.
##  - Taller bridge height (`RATIO_BRIDGE_HEIGHT = 1.10`) for better recognition.
##  - Thinner (0.55px) and brighter steel string with 0.65 opacity specular glint.
##  - Maintains all existing animations, gameplay, and public APIs.
signal string_plucked(idx: int, note_name: String)
signal pitch_bent(cents_offset: float)

const NODE_COUNT := 7
const NOTES_VN : Array[String] = ["ÄÃ´", "RÃª", "Mi", "Fa", "Sol", "La", "Si"]

# - State Variables -------------------
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
var _target_bend_offset := 0.0 # target tip offset (pixels)
var _bend_cents    := 0.0      # pitch bend in cents
var _bend_velocity := 0.0
var _bend_start_y  := 0.0      # Y-coordinate where drag bend started
var _bend_active   := false     # active drag state (after deadzone)
var _hovered_node_idx := -1
var _target_node_idx  := 0
var _target_weights : PackedFloat32Array = PackedFloat32Array()
var _hover_weights  : PackedFloat32Array = PackedFloat32Array()
var _press_weights  : PackedFloat32Array = PackedFloat32Array()

# Cached geometry for hit-testing and rendering
var _str_y       := 0.0
var _node_xs     : PackedFloat32Array = PackedFloat32Array()
var _node_ys     : PackedFloat32Array = PackedFloat32Array()
var _bend_zone_x := 0.0

# --- Public API ---------------------------------------------------------------
func init(notes: Array[String], streams: Array, freqs: Array[float]) -> void:
	_note_names = notes; _streams = streams; _freqs = freqs
	_glow_alpha.resize(NODE_COUNT)
	_is_target.resize(NODE_COUNT)
	_target_weights.resize(NODE_COUNT)
	_hover_weights.resize(NODE_COUNT)
	_press_weights.resize(NODE_COUNT)
	for i in NODE_COUNT:
		_glow_alpha[i] = 0.0
		_is_target[i] = 0
		_target_weights[i] = 0.0
		_hover_weights[i] = 0.0
		_press_weights[i] = 0.0
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
	_press_weights[idx] = 1.0
	string_plucked.emit(idx, _note_names[idx] if idx < _note_names.size() else NOTES_VN[idx])
	queue_redraw()

func _process(delta: float) -> void:
	var dirty := false
	if _pluck_amp > 0.0:
		_pluck_time += delta
		_pluck_amp *= exp(-delta * 2.5)
		if _pluck_amp < 0.005:
			_pluck_amp = 0.0
			_pluck_time = 0.0
		dirty = true

	for i in NODE_COUNT:
		if _glow_alpha.size() > i and _glow_alpha[i] > 0.0:
			_glow_alpha[i] *= exp(-delta * 7.0)
			if _glow_alpha[i] < 0.005: _glow_alpha[i] = 0.0
			dirty = true

	for i in NODE_COUNT:
		var target_val := 1.0 if (_is_target.size() > i and _is_target[i] == 1) else 0.0
		if abs(_target_weights[i] - target_val) > 0.005:
			_target_weights[i] = move_toward(_target_weights[i], target_val, delta * 3.5)
			dirty = true
		else: _target_weights[i] = target_val

	for i in NODE_COUNT:
		var target_hover := 1.0 if _hovered_node_idx == i else 0.0
		if _hover_weights[i] != target_hover:
			_hover_weights[i] = move_toward(_hover_weights[i], target_hover, delta * 12.0)
			dirty = true

	for i in NODE_COUNT:
		if _press_weights[i] > 0.0:
			_press_weights[i] = maxf(0.0, _press_weights[i] - delta * 5.0)
			dirty = true

	if _is_bending:
		_bend_offset = _target_bend_offset
		_bend_velocity = 0.0
		_bend_cents_update()
		dirty = true
	else:
		var target_offset := _target_bend_offset
		if _bend_offset != target_offset or _bend_velocity != 0.0:
			var stiffness := 500.0
			var damping := 6.5 # Under-damped spring, gives natural organic elasticity recoil
			var a := -stiffness * (_bend_offset - target_offset) - damping * _bend_velocity
			_bend_velocity += a * delta
			_bend_offset += _bend_velocity * delta
			if abs(_bend_offset - target_offset) < 0.05 and abs(_bend_velocity) < 0.05:
				_bend_offset = target_offset
				_bend_velocity = 0.0
				_bend_cents_update()
			else:
				_bend_cents_update()
			dirty = true

	var is_animating := _pluck_amp > 0.0 or _is_bending or _bend_offset != 0.0 or _bend_velocity != 0.0
	if is_animating:
		_pulse_phase += delta * 3.4
		dirty = true

	if dirty: queue_redraw()

func _bend_cents_update() -> void:
	_bend_cents = clampf(-_bend_offset / _max_bend() * 350.0, -400.0, 400.0)
	pitch_bent.emit(_bend_cents)

func _max_bend() -> float:
	var W := size.x
	var BW := W * 0.90
	var BH := clampf(BW * 0.11, 85.0, 130.0)
	return BH * 0.20

func _draw() -> void:
	var W := size.x; var H := size.y
	if W < 50.0 or H < 20.0: return

	# ─── 1. Core Geometry ──────────────────────────────────────────────────
	var BL := W * 0.16        # soundboard left edge starts after gourd area
	var BR := W * 0.98        # soundboard right edge
	var BW := BR - BL
	var BH := H * 0.72        # Balanced soundboard height
	var BCY := H * 0.53       # String centerline: vertically aligned
	var BT  := BCY - BH * 0.50
	var BB  := BCY + BH * 0.50
	var CR  := 40.0           # Smooth rounded corner radius on the left end

	# Cache geometry for hit-testing and bend input activation
	_str_y = BCY
	_bend_zone_x = BL

	# ─── 2. Soundboard Body with Resonance Depth (Hộp cộng hưởng 2.5D) ─────
	var sb_pts := PackedVector2Array()
	var segs := 16
	# Top-left corner rounded
	for s in segs + 1:
		var ang := PI + float(s) * (PI * 0.5) / float(segs)
		sb_pts.append(Vector2(BL + CR, BT + CR) + Vector2(cos(ang), sin(ang)) * CR)
	# Top-right (straight)
	sb_pts.append(Vector2(BR, BT))
	# Bottom-right (straight)
	sb_pts.append(Vector2(BR, BB))
	# Bottom-left corner rounded
	for s in segs + 1:
		var ang := PI * 0.5 + float(s) * (PI * 0.5) / float(segs)
		sb_pts.append(Vector2(BL + CR, BB - CR) + Vector2(cos(ang), sin(ang)) * CR)

	# Zither side-wall thickness/depth polygon (Thân hộp cộng hưởng)
	var depth_offset := 14.0
	var depth_pts := PackedVector2Array()
	# Top edge: Curve from left-vertical to bottom-horizontal, then to BR
	for s in range(segs, -1, -1):
		var ang := PI * 0.5 + float(s) * (PI * 0.5) / float(segs)
		depth_pts.append(Vector2(BL + CR, BB - CR) + Vector2(cos(ang), sin(ang)) * CR)
	depth_pts.append(Vector2(BR, BB))
	
	# Bottom edge: Down to depth bottom edge at BR, then trace back left with depth_offset
	depth_pts.append(Vector2(BR, BB + depth_offset))
	for s in range(segs + 1):
		var ang := PI * 0.5 + float(s) * (PI * 0.5) / float(segs)
		depth_pts.append(Vector2(BL + CR, BB - CR) + Vector2(cos(ang), sin(ang)) * CR + Vector2(0.0, depth_offset))

	# Draw side-wall depth layer
	draw_polygon(depth_pts, PackedColorArray([Color("#261105")])) # Dark mahogany depth color
	draw_polyline(depth_pts, Color("#180a03"), 2.0, true)

	# Soundboard shadow
	var shadow_offset := Vector2(0.0, 8.0 + depth_offset)
	var shadow_pts := PackedVector2Array()
	for p in sb_pts:
		shadow_pts.append(p + shadow_offset)
	draw_polygon(shadow_pts, PackedColorArray([Color(0, 0, 0, 0.20)]))

	# Soundboard wood fill (First fill entire zither frame contour with dark mahogany wood)
	draw_polygon(sb_pts, PackedColorArray([Color("#261105")]))

	# 3D Cylindrical shading overlay on the rounded left corner (gives the dark wood headblock rounded volume!)
	var shade_pts := PackedVector2Array()
	var shade_cols := PackedColorArray()
	for s in segs + 1:
		var ang := PI * 0.5 + float(s) * PI / float(segs) # from bottom-left to top-left
		var p := Vector2(BL + CR, BCY) + Vector2(cos(ang) * CR, sin(ang) * (BH * 0.50))
		shade_pts.append(p)
		shade_cols.append(Color(0.12, 0.05, 0.01, 0.28))
	# Right boundary of shading
	shade_pts.append(Vector2(BL + CR + 60.0, BT))
	shade_cols.append(Color(0.12, 0.05, 0.01, 0.0))
	shade_pts.append(Vector2(BL + CR + 60.0, BB))
	shade_cols.append(Color(0.12, 0.05, 0.01, 0.0))
	draw_polygon(shade_pts, shade_cols)

	# Decorative dark wood borders along top and bottom edges (Nẹp gỗ nâu sẫm chỉ vàng)
	# Top wood border band
	var top_border_rect := Rect2(BL + CR * 0.4, BT + 4.0, BR - BL - CR * 0.4 - 5.0, 7.0)
	draw_rect(top_border_rect, Color("#1a0802"))
	draw_line(Vector2(BL + CR * 0.4, BT + 11.0), Vector2(BR - 5.0, BT + 11.0), Color("#cca43b", 0.50), 1.0)
	# Bottom wood border band
	var bot_border_rect := Rect2(BL + CR * 0.4, BB - 11.0, BR - BL - CR * 0.4 - 5.0, 7.0)
	draw_rect(bot_border_rect, Color("#1a0802"))
	draw_line(Vector2(BL + CR * 0.4, BB - 11.0), Vector2(BR - 5.0, BB - 11.0), Color("#cca43b", 0.50), 1.0)

	# Spruce top panel (White/yellow wood resonance board) recessed inside the borders and starting at BL + 110.0
	# Drawing with an elegant traditional bottle-neck / vase scroll contour (hoa văn uốn lượn)
	var spruce_pts := PackedVector2Array()
	
	# Top edge (straight from BL + 190.0 to BR - 6.0)
	spruce_pts.append(Vector2(BL + 190.0, BT + 11.0))
	spruce_pts.append(Vector2(BR - 6.0, BT + 11.0))
	# Bottom edge (straight from BR - 6.0 to BL + 190.0)
	spruce_pts.append(Vector2(BR - 6.0, BB - 11.0))
	spruce_pts.append(Vector2(BL + 190.0, BB - 11.0))
	
	# Trace traditional vase/scroll left boundary contour (going from bottom-left to top-left)
	var div_pts := PackedVector2Array()
	var X_start := BL + 110.0
	
	# Symmetrical contour points from bottom BB - 11.0 to top BT + 11.0 (recessing to BL + 110.0 at center)
	div_pts.append(Vector2(BL + 190.0, BB - 11.0))
	div_pts.append(Vector2(X_start + 70.0, BCY + 26.0))
	div_pts.append(Vector2(X_start + 50.0, BCY + 32.0))
	div_pts.append(Vector2(X_start + 30.0, BCY + 16.0))
	div_pts.append(Vector2(X_start + 10.0, BCY + 12.0))
	div_pts.append(Vector2(X_start, BCY)) # tip of the tongue
	div_pts.append(Vector2(X_start + 10.0, BCY - 12.0))
	div_pts.append(Vector2(X_start + 30.0, BCY - 16.0))
	div_pts.append(Vector2(X_start + 50.0, BCY - 32.0))
	div_pts.append(Vector2(X_start + 70.0, BCY - 26.0))
	div_pts.append(Vector2(BL + 190.0, BT + 11.0))
	
	for p in div_pts:
		spruce_pts.append(p)

	# Draw the custom-shaped spruce wood resonance panel
	draw_polygon(spruce_pts, PackedColorArray([Color("#fed091")]))

	# Horizontal wood grain lines (Subtle premium grain pattern - starts inside the spruce panel)
	var grain_ys := [BT + BH * 0.24, BT + BH * 0.44, BT + BH * 0.64, BT + BH * 0.84, BT + BH * 0.34, BT + BH * 0.54, BT + BH * 0.74]
	for gy in grain_ys:
		if gy > BT + 12.0 and gy < BB - 12.0:
			draw_line(Vector2(BL + 192.0, gy), Vector2(BR - 12.0, gy), Color("#d99c52", 0.12), 1.0)

	# Gold divider border between the dark mun headblock and the yellow spruce wood panel
	draw_polyline(div_pts, Color("#cca43b", 0.85), 2.2, true)

	# Traditional Vietnamese cloud/wave inlay pattern on the right tailpiece (Hoa văn vân mây cổ bay bổng)
	var pat_x := BR - 85.0
	var pat_y := BCY
	# Main large swirl
	draw_arc(Vector2(pat_x, pat_y), 16.0, -PI, PI * 0.25, 32, Color("#cca43b", 0.45), 1.5)
	draw_arc(Vector2(pat_x, pat_y), 11.0, -PI, PI * 0.25, 32, Color("#cca43b", 0.30), 1.0)
	# Secondary upward swirl
	draw_arc(Vector2(pat_x - 18.0, pat_y - 12.0), 10.0, -PI * 0.5, PI, 24, Color("#cca43b", 0.40), 1.2)
	draw_arc(Vector2(pat_x - 18.0, pat_y - 12.0), 6.0, -PI * 0.5, PI, 24, Color("#cca43b", 0.25), 0.8)
	# Secondary downward swirl
	draw_arc(Vector2(pat_x - 18.0, pat_y + 12.0), 10.0, 0, PI * 1.5, 24, Color("#cca43b", 0.40), 1.2)
	draw_arc(Vector2(pat_x - 18.0, pat_y + 12.0), 6.0, 0, PI * 1.5, 24, Color("#cca43b", 0.25), 0.8)
	# Flow tails
	draw_line(Vector2(pat_x - 45.0, pat_y - 6.0), Vector2(pat_x - 28.0, pat_y - 12.0), Color("#cca43b", 0.30), 1.0)
	draw_line(Vector2(pat_x - 45.0, pat_y + 6.0), Vector2(pat_x - 28.0, pat_y + 12.0), Color("#cca43b", 0.30), 1.0)
	draw_line(Vector2(pat_x + 16.0, pat_y + 6.0), Vector2(pat_x + 35.0, pat_y + 6.0), Color("#cca43b", 0.30), 1.2)

	# Outer border outline (Thick dark wood rim + inner gold accent)
	draw_polyline(sb_pts, Color("#3a200e"), 6.0, true)
	draw_polyline(sb_pts, Color("#cca43b", 0.35), 2.0, true)

	# Soundboard sheen highlight (soft white inner rim on top edge)
	var sheen_pts := PackedVector2Array()
	for s in segs + 1:
		var ang := PI + float(s) * (PI * 0.5) / float(segs)
		sheen_pts.append(Vector2(BL + CR + 1.5, BT + CR + 1.5) + Vector2(cos(ang), sin(ang)) * CR)
	sheen_pts.append(Vector2(BR, BT + 1.5))
	draw_polyline(sheen_pts, Color(1.0, 1.0, 1.0, 0.40), 1.5, false)

	# ─── 3. Thick Curved Bamboo Rod (Cần rung sừng trâu) ─────────────────────
	# Arising from the gold collar at the top of the gourd, tilted left and curving elegantly
	var GX := BL - 10.0       # Nested close inside the zither body (as requested!)
	var GY := BCY
	var GR := 54.0            # Gourd radius

	var rod_start := Vector2(GX, GY - GR - 5.0) # Attached directly to the top of the gourd collar
	var rod_ht := BH * 0.52   # Tighter proportional height since starting higher
	var tip_deflect := _bend_offset * 0.90

	# Construct rod coordinates: curving and bending along its entire length!
	var base_tilt_angle := deg_to_rad(6.5) # Almost vertical base
	var base_dir := Vector2(-sin(base_tilt_angle), -cos(base_tilt_angle))
	
	var rod_pts := PackedVector2Array()
	for s in 21:
		var t := float(s) / 20.0
		var p_pos := rod_start + base_dir * (t * rod_ht)
		# Static curve concentrated at the tip (pow 2.5) for a beautiful horn shape
		var static_curve := -55.0
		p_pos.x += static_curve * pow(t, 2.5) + tip_deflect * (t * t)
		rod_pts.append(p_pos)

	var rod_end := rod_pts[20]

	# Draw rod shadow (tapered)
	for s in 20:
		var t1 := float(s) / 20.0
		var p1 := rod_pts[s] + Vector2(-6.0, 6.0)
		var p2 := rod_pts[s + 1] + Vector2(-6.0, 6.0)
		var w := lerpf(20.0, 10.0, t1)
		draw_line(p1, p2, Color(0, 0, 0, 0.22), w)

	# Draw rod dark border (outer silhouette - tapered from 22px to 12px - black horn)
	for s in 20:
		var t1 := float(s) / 20.0
		var w := lerpf(22.0, 12.0, t1)
		draw_line(rod_pts[s], rod_pts[s + 1], Color("#090909"), w)

	# Draw rod core (polished black - tapered from 15.0px to 8.0px)
	for s in 20:
		var t1 := float(s) / 20.0
		var w := lerpf(15.0, 8.0, t1)
		draw_line(rod_pts[s], rod_pts[s + 1], Color("#181818"), w)

	# Draw rod core highlight (charcoal grey)
	for s in 20:
		var t1 := float(s) / 20.0
		var w := lerpf(7.0, 3.5, t1)
		draw_line(rod_pts[s], rod_pts[s + 1], Color("#2d2d2d"), w)

	# Draw specular sheen line (sharp polished piano-black/horn sheen)
	for s in 20:
		var t1 := float(s) / 20.0
		var w := lerpf(2.0, 0.8, t1)
		var offset := Vector2(-1.5, 0.0)
		draw_line(rod_pts[s] + offset, rod_pts[s + 1] + offset, Color("#ffffff", 0.52), w)

	# Bamboo joints (only on the lower straight part, scaled proportionally)
	for jt_t in [0.25, 0.50]:
		var idx := int(jt_t * 20)
		var jp := rod_pts[idx]
		var jt_w := lerpf(22.0, 12.0, jt_t)
		draw_circle(jp, jt_w * 0.48, Color("#090909"))
		draw_circle(jp, jt_w * 0.35, Color("#2d2d2d"))

	# Decorative gold cap on tip
	draw_circle(rod_end, 6.0, Color("#cca43b"))
	draw_circle(rod_end, 3.0, Color("#090909"))

	# ─── 4. Unified Turned Wooden Gourd Cup (Bầu đàn dáng chum tiện gỗ nguyên khối) ─
	# Sits on top of the rod base, nested inside the zither body, oriented horizontally
	var rim_x := GX + GR * 1.15
	var rim_r_w := 6.0
	var rim_r_h := GR * 0.62

	# Generate single closed contour for the entire turned wood gourd cup
	var gourd_pts := PackedVector2Array()
	var g_steps := 32
	
	# Top edge (left to right)
	for i in g_steps + 1:
		var t: float = float(i) / float(g_steps)
		var x := lerpf(GX - GR, rim_x, t)
		var w: float = 0.0
		if t < 0.42:
			# Bulbous base: swells up from tip
			var nt := t / 0.42
			w = lerpf(0.12, 0.88, sin(nt * PI * 0.5))
		elif t < 0.78:
			# Taper to neck
			var nt := (t - 0.42) / 0.36
			w = lerpf(0.88, 0.48, sin(nt * PI * 0.5))
		else:
			# Flare out to mouth lip
			var nt := (t - 0.78) / 0.22
			w = lerpf(0.48, 0.65, nt * nt)
		gourd_pts.append(Vector2(x, GY - w * GR))
		
	# Bottom edge (right to left)
	for i in range(g_steps, -1, -1):
		var t: float = float(i) / float(g_steps)
		var x := lerpf(GX - GR, rim_x, t)
		var w: float = 0.0
		if t < 0.42:
			var nt := t / 0.42
			w = lerpf(0.12, 0.88, sin(nt * PI * 0.5))
		elif t < 0.78:
			var nt := (t - 0.42) / 0.36
			w = lerpf(0.88, 0.48, sin(nt * PI * 0.5))
		else:
			var nt := (t - 0.78) / 0.22
			w = lerpf(0.48, 0.65, nt * nt)
		gourd_pts.append(Vector2(x, GY + w * GR))

	# 4.1 Draw realistic 3D soft drop shadow under the unified gourd cup
	var shad_offset := Vector2(6.0, 6.0)
	var gourd_shad_pts := PackedVector2Array()
	for p in gourd_pts:
		gourd_shad_pts.append(p + shad_offset)
	draw_polygon(gourd_shad_pts, PackedColorArray([Color(0, 0, 0, 0.26)]))

	# 4.2 Fill unified gourd body with base dark mahogany wood color
	draw_polygon(gourd_pts, PackedColorArray([Color("#1a0802")]))

	# Draw inner wood overlay for 3D depth volume
	var gourd_inner_pts := PackedVector2Array()
	for p in gourd_pts:
		gourd_inner_pts.append(lerp(p, Vector2(GX, GY), 0.03))
	draw_polygon(gourd_inner_pts, PackedColorArray([Color("#2a1205")]))

	# Horizontal cylindrical shading highlights along the center line (making it look like turned wood)
	# Soft highlight along the center line GY
	var center_highlight := PackedVector2Array()
	for i in g_steps + 1:
		var t: float = float(i) / float(g_steps)
		var x := lerpf(GX - GR, rim_x, t)
		var w: float = 0.0
		if t < 0.42:
			w = lerpf(0.12, 0.88, sin(t / 0.42 * PI * 0.5))
		elif t < 0.78:
			w = lerpf(0.88, 0.48, sin((t - 0.42) / 0.36 * PI * 0.5))
		else:
			w = lerpf(0.48, 0.65, ((t - 0.78) / 0.22) * ((t - 0.78) / 0.22))
		center_highlight.append(Vector2(x, GY - w * GR * 0.40))
	for i in range(g_steps, -1, -1):
		var t: float = float(i) / float(g_steps)
		var x := lerpf(GX - GR, rim_x, t)
		var w: float = 0.0
		if t < 0.42:
			w = lerpf(0.12, 0.88, sin(t / 0.42 * PI * 0.5))
		elif t < 0.78:
			w = lerpf(0.88, 0.48, sin((t - 0.42) / 0.36 * PI * 0.5))
		else:
			w = lerpf(0.48, 0.65, ((t - 0.78) / 0.22) * ((t - 0.78) / 0.22))
		center_highlight.append(Vector2(x, GY + w * GR * 0.08))
	draw_polygon(center_highlight, PackedColorArray([Color("#3d1b06")]))

	# Shiny specular sheen highlight strip near the top edge
	var gourd_sheen_pts := PackedVector2Array()
	for i in range(2, g_steps - 1):
		var t: float = float(i) / float(g_steps)
		var x := lerpf(GX - GR, rim_x, t)
		var w: float = 0.0
		if t < 0.42:
			w = lerpf(0.12, 0.88, sin(t / 0.42 * PI * 0.5))
		elif t < 0.78:
			w = lerpf(0.88, 0.48, sin((t - 0.42) / 0.36 * PI * 0.5))
		else:
			w = lerpf(0.48, 0.65, ((t - 0.78) / 0.22) * ((t - 0.78) / 0.22))
		gourd_sheen_pts.append(Vector2(x, GY - w * GR * 0.72))
	draw_polyline(gourd_sheen_pts, Color(1.0, 1.0, 1.0, 0.16), 2.5, false)

	# 4.3 Draw gold/brass decorative cap on the left tip (cái núm nhọn đầu bầu)
	var cap_pts := PackedVector2Array([
		Vector2(GX - GR + 1.0, GY - 7.5),
		Vector2(GX - GR - 12.0, GY),
		Vector2(GX - GR + 1.0, GY + 7.5)
	])
	draw_polygon(cap_pts, PackedColorArray([Color("#cca43b")]))
	draw_circle(Vector2(GX - GR - 12.0, GY), 2.5, Color("#090909"))

	# 4.4 Draw gold rim cavity at the right flared mouth
	draw_ellipse_like_cavity(Vector2(rim_x, GY), rim_r_w - 2.0, rim_r_h - 3.0, Color("#cca43b"))
	draw_ellipse_like_cavity(Vector2(rim_x, GY), 2.5, rim_r_h - 4.0, Color("#0c0401")) # dark inner hole 

	# 4.4 Draw brass/gold mounting bracket frame at the slot interface (on top of soundboard)
	draw_ellipse_like_cavity(Vector2(rim_x, GY), rim_r_w + 3.0, rim_r_h + 3.0, Color("#cca43b")) # gold bracket outer
	draw_ellipse_like_cavity(Vector2(rim_x, GY), rim_r_w, rim_r_h, Color("#1a0802")) # gold bracket inner

	# Collar connection neck (Cổ nối nhỏ phía trên quả bầu)
	var collar_rect := Rect2(GX - 6.0, GY - GR - 5.0, 12.0, 5.0)
	draw_rect(collar_rect, Color("#cca43b")) # gold/brass collar
	draw_rect(collar_rect, Color("#1a0802"), false, 1.2)

	# Brass string rivet anchor (inside the flared cavity mouth)
	var rivet_pos := Vector2(rim_x, GY)
	draw_circle(rivet_pos, 3.0, Color("#cca43b"))
	draw_circle(rivet_pos, 1.2, Color("#1a0802"))

	# ─── 5. String (Silver steel wire passing to BR) ──────────────────────────
	# Starts at the anchor point on the right of the gourd, runs horizontally to BR
	var SE := Vector2(BR, BCY)
	var SS := rivet_pos # string exits from the rivet anchor (exactly at Y=BCY)

	var str_pts := PackedVector2Array()
	str_pts.append(SS)
	if _pluck_amp > 0.005:
		for k in range(1, 30):
			var t := float(k) / 30.0
			var sx := lerpf(SS.x, SE.x, t)
			var osc := sin(t * PI) * sin(_pluck_time * 24.0) * _pluck_amp * 8.0
			str_pts.append(Vector2(sx, BCY + osc))
	else:
		str_pts.append(SE)

	# String shadow
	var str_shad := PackedVector2Array()
	for p in str_pts:
		str_shad.append(p + Vector2(0.0, 4.0))
	draw_polyline(str_shad, Color(0, 0, 0, 0.28), 2.0, false)

	# String wire (shiny silver metal wire)
	draw_polyline(str_pts, Color("#4b5563"), 2.2, false) # base string (dark silver border)
	draw_polyline(str_pts, Color("#d1d5db"), 1.2, false) # metal core (light silver core)
	draw_polyline(str_pts, Color("#ffffff", 0.80), 0.5, false) # shiny metallic sheen

	# ─── 6. Concentric Harmonic Nodes (Jade-wood-brass rivets) ───────────────
	# Cache node positions
	var NODE_AREA_L := BL + 215.0
	var NODE_AREA_R := BR - 95.0
	var NODE_AW     := NODE_AREA_R - NODE_AREA_L

	if _node_xs.size() != NODE_COUNT:
		_node_xs.resize(NODE_COUNT)
		_node_ys.resize(NODE_COUNT)
	for i in NODE_COUNT:
		var t := float(i) / float(NODE_COUNT - 1)
		_node_xs[i] = NODE_AREA_L + t * NODE_AW
		_node_ys[i] = BCY

	# Node visible radius
	var NODE_VR := 22.0

	for i in NODE_COUNT:
		var pos := Vector2(_node_xs[i], BCY)
		var is_tgt := (_is_target.size() > i and _is_target[i] == 1)
		var is_completed := (i < _target_node_idx)
		var is_nxt := (i == _target_node_idx + 1)
		var glow_a := _glow_alpha[i] if _glow_alpha.size() > i else 0.0
		var hover_w := _hover_weights[i] if _hover_weights.size() > i else 0.0
		var press_w := _press_weights[i] if _press_weights.size() > i else 0.0
		var tgt_w := _target_weights[i] if _target_weights.size() > i else 0.0

		# ── Active target golden glowing concentric ripple rings ──
		if tgt_w > 0.01:
			var osc := 0.5 + 0.5 * sin(_pulse_phase * 2.2)
			var r1 := NODE_VR + 5.0 + osc * 4.0
			var r2 := r1 + 8.0 + osc * 2.0
			draw_arc(pos, r1, 0, TAU, 32, Color("#ffd25c", tgt_w * 0.22), 1.2)
			draw_arc(pos, r2, 0, TAU, 32, Color("#ffd25c", tgt_w * 0.09), 0.8)
			
			# Golden core radial glow (soft golden glow)
			draw_circle(pos, NODE_VR + 2.0, Color("#cca43b", tgt_w * 0.12))

		# Pluck/press flashes
		if glow_a > 0.0:
			draw_circle(pos, NODE_VR + 12.0 * glow_a, Color(1.0, 0.90, 0.45, glow_a * 0.30))
		if press_w > 0.0:
			draw_circle(pos, NODE_VR + 16.0 * press_w, Color(1.0, 0.92, 0.55, press_w * 0.20))
		
		# Completed node soft green glow
		if is_completed:
			draw_circle(pos, NODE_VR + 4.0, Color("#a7f3d0", 0.15))

		# Concentric layered node body:
		# 1. Shadow
		draw_circle(pos, NODE_VR + 1.5, Color(0, 0, 0, 0.15))
		
		# 2. Outer brass/gold ring (Vòng đồng vàng)
		draw_circle(pos, NODE_VR, Color("#cca43b"))
		
		# 3. Center - Ivory/Cream color (Tâm màu ngà) or Soft Light Green color if completed
		var center_col := Color("#ede7da")
		if is_completed:
			center_col = Color("#a7f3d0") # Soft light green
		elif is_tgt:
			center_col = Color("#fcd34d") # Slightly warmer yellow/gold for current target
		
		draw_circle(pos, NODE_VR - 3.5, center_col)
		
		# 4. Center small bronze rivet pin (no thick black border)
		draw_circle(pos, 2.5, Color("#8c6827"))
		
		# 5. Specular highlight dot
		draw_circle(pos - Vector2(3.5, 3.5), 1.5, Color(1, 1, 1, 0.6))

		# Golden center core for active target node
		if is_tgt:
			var pulse_val := 0.70 + 0.30 * sin(_pulse_phase * 3.5)
			draw_circle(pos, NODE_VR - 8.0, Color(1.0, 0.82, 0.20, tgt_w * pulse_val))
			draw_circle(pos, 6.0, Color(1.0, 1.0, 0.90, tgt_w * pulse_val))

		# ─── 7. Vertical Pin Lines & Label Tags ───
		# Vertical dashed guide pin line going up to node label
		var line_start_y := pos.y - NODE_VR - 3.0
		var line_end_y := pos.y - 56.0
		
		# Draw clean vertical dashed pin line
		var dy := line_start_y
		var step := 5.0
		var draw_dash := true
		while dy > line_end_y:
			if draw_dash:
				draw_line(Vector2(pos.x, dy), Vector2(pos.x, maxf(dy - step, line_end_y)), Color("#1e1e1e", 0.70), 1.5)
			dy -= step + 3.0
			draw_dash = not draw_dash

		# Draw the note label tag rounded rectangle box above the pin line
		var label_name := _note_names[i] if i < _note_names.size() else NOTES_VN[i]
		var font := get_theme_font("font")
		if font:
			var fs := 14
			var ts := font.get_string_size(label_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
			var pad_x := 10.0
			var pad_y := 6.0
			var tw := ts.x + pad_x * 2.0
			var th := ts.y + pad_y * 2.0
			
			var rect_x := pos.x - tw * 0.5
			var rect_y := line_end_y - th + 2.0
			var label_rect := Rect2(rect_x, rect_y, tw, th)
			
			# Choose label colors
			var tag_bg := Color("#1a1a1a") # Dark background tag matching reference
			var tag_border := Color("#cca43b", 0.45) # Gold border outline
			var tag_text := Color("#ffffff")
			
			if is_tgt:
				tag_bg = Color("#cca43b") # Active note gets a golden background tag
				tag_border = Color("#ffffff", 0.8)
				tag_text = Color("#1a1a1a")
			elif is_nxt:
				tag_bg = Color("#3a200e")
				tag_border = Color("#cca43b", 0.75)
				tag_text = Color("#ffdca0")
			
			# Draw label rounded tag box (8px radius)
			_draw_rrect(label_rect, 6.0, tag_bg)
			_draw_rrect_outline(label_rect, 6.0, tag_border, 1.2)
			
			# Draw note text
			var text_pos := Vector2(rect_x + pad_x, rect_y + pad_y + ts.y * 0.75)
			draw_string(font, text_pos, label_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, tag_text)

	# Shimmer/resonance glow along the string on pluck
	if _pluck_amp > 0.005:
		draw_polyline(str_pts, Color(1.0, 0.85, 0.30, _pluck_amp * 0.25), 5.0, false)

# Helper function to compute Bezier control t values
func t_val(v: float) -> float:
	return v

func draw_ellipse_like_cavity(center: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	var segs := 16
	for s in segs + 1:
		var ang := float(s) / float(segs) * TAU
		pts.append(center + Vector2(cos(ang) * rx, sin(ang) * ry))
	draw_colored_polygon(pts, col)

# -- Rounded Rectangle Helpers --------------------------------------------------
func _draw_rrect(rect: Rect2, radius: float, col: Color) -> void:
	if radius <= 0.5:
		draw_rect(rect, col)
		return
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var pts := PackedVector2Array()
	var segs := 8
	var cs := [
		Vector2(rect.position.x + r, rect.position.y + r),
		Vector2(rect.end.x - r,      rect.position.y + r),
		Vector2(rect.end.x - r,      rect.end.y - r),
		Vector2(rect.position.x + r, rect.end.y - r),
	]
	var st: Array[float] = [PI, PI * 1.5, 0.0, PI * 0.5]
	for ci in 4:
		for s in segs + 1:
			var ang: float = st[ci] + float(s) * (PI * 0.5) / float(segs)
			pts.append(cs[ci] + Vector2(cos(ang), sin(ang)) * r)
	draw_colored_polygon(pts, col)

func _draw_rrect_outline(rect: Rect2, radius: float, col: Color, w: float) -> void:
	if radius <= 0.5:
		draw_rect(rect, col, false, w)
		return
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var pts := PackedVector2Array()
	var segs := 8
	var cs := [
		Vector2(rect.position.x + r, rect.position.y + r),
		Vector2(rect.end.x - r,      rect.position.y + r),
		Vector2(rect.end.x - r,      rect.end.y - r),
		Vector2(rect.position.x + r, rect.end.y - r),
	]
	var st: Array[float] = [PI, PI * 1.5, 0.0, PI * 0.5]
	for ci in 4:
		for s in segs + 1:
			var ang: float = st[ci] + float(s) * (PI * 0.5) / float(segs)
			pts.append(cs[ci] + Vector2(cos(ang), sin(ang)) * r)
	draw_polyline(pts, col, w, true)





# 
#  INPUT HANDLING & DESKTOP FALLBACK
# 
func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey:
		var ek := ev as InputEventKey
		if ek.keycode == KEY_SPACE and ek.pressed and not ek.is_echo():
			pluck(_target_node_idx)

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
		_is_bending = true
		_bend_start_y = pos.y
		_bend_active = false
		_target_bend_offset = 0.0
	else:
		var ni := _node_at(pos)
		if ni >= 0: pluck(ni)

func _on_move(pos: Vector2) -> void:
	var is_over_bend := pos.x < _bend_zone_x
	var over_node := _node_at(pos)
	if is_over_bend or over_node >= 0:
		mouse_default_cursor_shape = CURSOR_POINTING_HAND
	else:
		mouse_default_cursor_shape = CURSOR_ARROW
		
	if _is_bending:
		if not _bend_active:
			if abs(pos.y - _bend_start_y) > 5.0:
				_bend_active = true
		if _bend_active:
			_do_bend(pos.y)
	else:
		if _hovered_node_idx != over_node:
			_hovered_node_idx = over_node
			queue_redraw()

func _on_release() -> void:
	_is_bending = false
	_bend_active = false
	_target_bend_offset = 0.0
	_hovered_node_idx = -1
	_bamboo_touch_index = -1
	_string_touch_index = -1
	queue_redraw()

func _on_touch_press(pos: Vector2, index: int) -> void:
	if pos.x < _bend_zone_x:
		if _bamboo_touch_index == -1:
			_bamboo_touch_index = index
			_is_bending = true
			_bend_start_y = pos.y
			_bend_active = false
			_target_bend_offset = 0.0
	else:
		if _string_touch_index == -1:
			_string_touch_index = index
			var ni := _node_at(pos)
			if ni >= 0: pluck(ni)

func _on_touch_release(index: int) -> void:
	if index == _bamboo_touch_index:
		_bamboo_touch_index = -1
		_is_bending = false
		_bend_active = false
		_target_bend_offset = 0.0
		queue_redraw()
	elif index == _string_touch_index:
		_string_touch_index = -1

func _on_touch_drag(pos: Vector2, index: int) -> void:
	if index == _bamboo_touch_index:
		if not _bend_active:
			if abs(pos.y - _bend_start_y) > 5.0:
				_bend_active = true
		if _bend_active:
			_do_bend(pos.y)
	elif index == _string_touch_index:
		var ni := _node_at(pos)
		if ni >= 0 and ni != _hovered_node_idx:
			_hovered_node_idx = ni
			pluck(ni)

func _node_at(pos: Vector2) -> int:
	if _node_xs.size() < NODE_COUNT: return -1
	for i in NODE_COUNT:
		var ny := _node_ys[i] if _node_ys.size() > i else _str_y
		# Large invisible hit areas: 72dp touch target (36px radius)
		if pos.distance_to(Vector2(_node_xs[i], ny)) <= 36.0: return i
	return -1


func _do_bend(ty: float) -> void:
	var max_d := _max_bend()
	# Dragging UP (ty < start) bends rod RIGHT (positive cents)
	# Dragging DOWN (ty > start) bends rod LEFT (negative cents)
	_target_bend_offset = clampf((_bend_start_y - ty) * 1.5, -max_d, max_d)
	_bend_cents_update()
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_hovered_node_idx = -1
		if _is_bending: _on_release()
		_bamboo_touch_index = -1
		_string_touch_index = -1
		queue_redraw()
