extends Control

signal string_plucked(idx: int, note_name: String)
signal pitch_bent(cents_offset: float)

const NODE_COUNT := 7
const NOTES_VN : Array[String] = ["Đô", "Rê", "Mi", "Fa", "Sol", "La", "Si"]

# ─── Color Palette ─────────────────────────────────────────────────────────────
const C_GOLD       := Color("#c99a3c") # Antique Gold
const C_GOLD_LIGHT := Color("#fce8b3") # Light Golden highlight
const C_GOLD_TEXT  := Color("#8c6613") # Dark Bronze Gold for labels
const C_RED_SON    := Color("#0e3d26") # Deep Forest Green primary accent
const C_BG_WOOD    := Color("#261408") # Deep Mahogany Board
const C_ROSEWOOD   := Color("#3d1b07") # Accent Wood

# ─── State ────────────────────────────────────────────────────────────────────
var _note_names  : Array[String]      = []
var _streams     : Array              = []
var _freqs       : Array[float]       = []

var _pluck_amp   : float              = 0.0
var _pluck_time  : float              = 0.0
var _glow_alpha  : PackedFloat32Array = PackedFloat32Array()
var _pulse_phase : float              = 0.0
var _is_target   : PackedByteArray    = PackedByteArray()

# Horn bend variables
var _is_bending    := false
var _bend_offset   := 0.0  # Current visual bend X offset (pixels)
var _bend_cents    := 0.0  # Pitch bend in cents (-400 to +400)
var _bend_velocity := 0.0  # Velocity for physical spring-damper modeling
var _active_player : AudioStreamPlayer = null
var _last_plucked_idx := -1

var _hovered_node_idx := -1
var _target_node_idx  := 0

# Positions for drawing
var _rod_start   := Vector2.ZERO
var _rod_end     := Vector2.ZERO
var _gourd_pos   := Vector2.ZERO
var _string_end  := Vector2.ZERO

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
	
	# Emit signal
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
	
	if not _is_bending and (_bend_offset != 0.0 or _bend_velocity != 0.0):
		var W := size.x
		var max_drag := W * 0.08 if W > 0 else 100.0
		
		# Physical spring-damper physics constants
		var k := 400.0 # stiffness
		var c := 14.0  # damping
		
		var accel = -k * _bend_offset - c * _bend_velocity
		_bend_velocity += accel * delta
		_bend_offset += _bend_velocity * delta
		
		if abs(_bend_offset) < 0.05 and abs(_bend_velocity) < 0.05:
			_bend_offset = 0.0
			_bend_velocity = 0.0
			_bend_cents = 0.0
			pitch_bent.emit(0.0)
		else:
			var factor := _bend_offset / max_drag
			_bend_cents = -factor * 350.0
			pitch_bent.emit(_bend_cents)
			
		need_redraw = true
		
	if need_redraw:
		queue_redraw()

func _draw() -> void:
	var W := size.x
	var H := size.y
	if W < 50.0 or H < 50.0:
		return

	# Draw wooden zither board table/background
	draw_rect(Rect2(0.0, 0.0, W, H), C_BG_WOOD)
	
	# Bevel wooden frames
	draw_rect(Rect2(0.0, 0.0, W, 12.0), Color("#1b0c03")) # Top frame
	draw_rect(Rect2(0.0, H - 12.0, W, 12.0), Color("#1b0c03")) # Bottom frame
	draw_rect(Rect2(0.0, 0.0, 16.0, H), Color("#160a02")) # Left block
	draw_rect(Rect2(W - 16.0, 0.0, 16.0, H), Color("#160a02")) # Right block
	
	# Border highlight lines
	draw_line(Vector2(0, 12), Vector2(W, 12), Color("#c99a3c", 0.25), 1.5)
	draw_line(Vector2(0, H - 12), Vector2(W, H - 12), Color("#0d0501", 0.65), 1.5)
	draw_line(Vector2(16, 0), Vector2(16, H), Color("#c99a3c", 0.25), 1.5)
	draw_line(Vector2(W - 16, 0), Vector2(W - 16, H), Color("#0d0501", 0.65), 1.5)
	
	# Wood grains for background table
	for i in range(12):
		var gy := 12.0 + (H - 24.0) * (float(i) / 11.0)
		draw_line(Vector2(16, gy), Vector2(W - 16, gy), Color("#120803", 0.25), 1.0)

	# Traditional gold corner rivet plates
	_draw_rivets(W, H)

	# Zither Board Coordinates
	var x_left := W * 0.18
	var x_right := W * 0.94
	var body_center_y := H * 0.55
	var h_left := H * 0.28
	var h_right := H * 0.44

	# Calculate key position points
	_rod_start = Vector2(x_left, body_center_y)
	_gourd_pos = Vector2(x_left - 75.0 + _bend_offset, body_center_y)
	_rod_end = _gourd_pos
	_string_end = Vector2(x_right + 15.0, body_center_y)

	# 1. Draw tapered body with cylindrical 3D wood shading
	_draw_tapered_body(x_left, x_right, body_center_y, h_left, h_right)

	# 2. Draw mother-of-pearl scroll patterns
	_draw_mop_scrolls(x_left, x_right, body_center_y, h_left, h_right)

	# 3. Draw brass collar socket
	_draw_brass_collar(_rod_start, PI)

	# 4. Draw tapered horn rod (Cần Đàn)
	var rod_control := Vector2(x_left - 35.0 + _bend_offset * 0.5, body_center_y - 52.0)
	var rod_pts := PackedVector2Array()
	var steps := 20
	for k in range(steps + 1):
		var t := float(k) / float(steps)
		var pt := (1.0-t)*(1.0-t)*_rod_start + 2.0*(1.0-t)*t*rod_control + t*t*_gourd_pos
		rod_pts.append(pt)

	# Draw horn rod shadow
	var shadow_pts := PackedVector2Array()
	for pt in rod_pts:
		shadow_pts.append(pt + Vector2(0, 4.0))
	for k in range(steps):
		var t_mid := float(k) / float(steps)
		var thickness := lerpf(11.0, 3.5, t_mid)
		draw_line(shadow_pts[k], shadow_pts[k+1], Color(0, 0, 0, 0.25), thickness, true)
		draw_circle(shadow_pts[k], thickness * 0.5, Color(0, 0, 0, 0.25))

	# Draw actual horn rod with specular highlights
	for k in range(steps):
		var t_mid := float(k) / float(steps)
		var thickness := lerpf(10.0, 3.0, t_mid)
		var horn_color := Color("#0a0808")
		draw_line(rod_pts[k], rod_pts[k+1], horn_color, thickness, true)
		draw_circle(rod_pts[k], thickness * 0.5, horn_color)
		# Specular highlights
		var specular_color := Color(1.0, 1.0, 1.0, 0.18)
		draw_line(rod_pts[k] - Vector2(0, thickness * 0.15), rod_pts[k+1] - Vector2(0, thickness * 0.15), specular_color, thickness * 0.28, true)

	# 5. Draw pear-shaped gourd (Bầu) with radial 3D shading
	_draw_shaded_gourd(_gourd_pos, (_gourd_pos - rod_control).normalized())

	# 6. Draw string peg
	_draw_peg(_string_end)

	# 7. Draw single monochord string (with pluck vibration wave)
	var str_pts := PackedVector2Array()
	str_pts.append(_gourd_pos)
	
	if _pluck_amp > 0.005:
		var spd := 85.0
		for k in range(1, 30):
			var ratio := float(k) / 30.0
			var decay := exp(-_pluck_time * 2.2)
			var osc := sin(ratio * PI) * sin(ratio * PI * 4.0 - _pluck_time * spd) * _pluck_amp * 7.5 * decay
			str_pts.append(Vector2(lerpf(_gourd_pos.x, _string_end.x, ratio), body_center_y + osc))
	str_pts.append(_string_end)

	# Draw string shadow
	var str_shadow := PackedVector2Array()
	for pt in str_pts:
		str_shadow.append(pt + Vector2(0, 4.0))
	draw_polyline(str_shadow, Color(0.0, 0.0, 0.0, 0.4), 1.5, true)

	# Draw string glow when vibrating
	if _pluck_amp > 0.01:
		draw_polyline(str_pts, Color(C_GOLD_LIGHT.r, C_GOLD_LIGHT.g, C_GOLD_LIGHT.b, _pluck_amp * 0.45), 4.5, true)
	
	# Draw active string core (silver/steel wire)
	var string_col := C_GOLD_LIGHT if _pluck_amp > 0.1 else Color("#e0e3eb")
	if _is_bending:
		string_col = Color("#fc882b") # highlight bending
	draw_polyline(str_pts, string_col, 1.8, true)

	# 8. Draw 7 harmonic touch nodes exactly on the string path
	var start_x := x_left + 45.0
	var end_x   := x_right - 45.0
	var step_x  := (end_x - start_x) / float(NODE_COUNT - 1)
	
	var font := get_theme_font("font")

	for i in NODE_COUNT:
		var nx := start_x + float(i) * step_x
		var ny := body_center_y
		_draw_ivory_node(Vector2(nx, ny), i, _is_target[i] == 1, _hovered_node_idx == i, _glow_alpha[i], _pulse_phase, font)

	# 9. Draw pitch bending gauge and calligraphic cents display
	if _is_bending:
		_draw_bend_gauge(Vector2(x_left - 75.0, body_center_y), 45.0, _bend_cents)
		_draw_cents_readout(font, Vector2(x_left - 75.0, body_center_y - 65.0), _bend_cents)

func _draw_tapered_body(x_left: float, x_right: float, y_center: float, h_left: float, h_right: float) -> void:
	# Calculate corners for main drop shadow
	var tl := Vector2(x_left, y_center - h_left / 2.0)
	var bl := Vector2(x_left, y_center + h_left / 2.0)
	var br := Vector2(x_right, y_center + h_right / 2.0)
	var tr := Vector2(x_right, y_center - h_right / 2.0)
	
	# Rich deep 3D drop shadow
	var shadow_offset := Vector2(0, 10.0)
	draw_colored_polygon(PackedVector2Array([tl + shadow_offset, tr + shadow_offset, br + shadow_offset, bl + shadow_offset]), Color(0.02, 0.01, 0.005, 0.55))

	# Render horizontal cylindrical wood gradient layers to simulate 3D cylinder appearance
	var steps := 22
	for i in steps:
		var ratio1 := float(i) / steps
		var ratio2 := float(i + 1) / steps
		
		# Cylindrical gradient intensity curve
		var light := sin(ratio1 * PI)
		
		# Interpolate between deep dark mahogany/rosewood sides and golden wood center highlights
		var col := Color("#1a0903").lerp(Color("#61320e"), light)
		
		# Glossy top reflection highlight
		if ratio1 > 0.14 and ratio1 < 0.24:
			var factor := (ratio1 - 0.14) / 0.10
			var highlight_strength := sin(factor * PI) * 0.28
			col = col.lerp(Color("#ffd79c"), highlight_strength)
		# Bottom shadow gradient
		elif ratio1 > 0.78:
			var factor := (ratio1 - 0.78) / 0.22
			col = col.lerp(Color("#080201"), factor * 0.70)
			
		# Calculate Y coordinates for left and right ends of the tapered body
		var y_l1 := y_center - h_left / 2.0 + h_left * ratio1
		var y_l2 := y_center - h_left / 2.0 + h_left * ratio2
		var y_r1 := y_center - h_right / 2.0 + h_right * ratio1
		var y_r2 := y_center - h_right / 2.0 + h_right * ratio2
		
		# Draw the strip segment
		var strip_pts := PackedVector2Array([
			Vector2(x_left, y_l1),
			Vector2(x_right, y_r1),
			Vector2(x_right, y_r2),
			Vector2(x_left, y_l2)
		])
		draw_colored_polygon(strip_pts, col)

	# Longitudinal organic wood grain lines
	var rand_gen = RandomNumberGenerator.new()
	rand_gen.seed = 98765 # deterministic seed to avoid flickering
	for j in range(16):
		var f := rand_gen.randf()
		var grain_pts := PackedVector2Array()
		var step_cnt := 25
		for k in range(step_cnt + 1):
			var t := float(k) / float(step_cnt)
			var gx := lerpf(x_left, x_right, t)
			var cur_h := lerpf(h_left, h_right, t)
			var wave := sin(gx * 0.05 + f * 10.0) * 1.6 + cos(gx * 0.09) * 0.9
			var gy := y_center - cur_h / 2.0 + cur_h * f + wave
			grain_pts.append(Vector2(gx, gy))
		
		var grain_color := Color("#1a0802").lerp(Color("#4a2007"), f)
		grain_color.a = rand_gen.randf_range(0.08, 0.24)
		draw_polyline(grain_pts, grain_color, rand_gen.randf_range(1.0, 2.2), true)

	# Fine gold inlay borders on top and bottom edges
	var inset := 3.0
	var tl_in := Vector2(x_left + inset, y_center - (h_left - inset * 2.0) / 2.0)
	var bl_in := Vector2(x_left + inset, y_center + (h_left - inset * 2.0) / 2.0)
	var br_in := Vector2(x_right - inset, y_center + (h_right - inset * 2.0) / 2.0)
	var tr_in := Vector2(x_right - inset, y_center - (h_right - inset * 2.0) / 2.0)
	
	draw_polyline(PackedVector2Array([tl_in, tr_in]), Color("#c99a3c", 0.85), 1.3, true)
	draw_polyline(PackedVector2Array([bl_in, br_in]), Color("#c99a3c", 0.85), 1.3, true)
	draw_polyline(PackedVector2Array([tl, tr, br, bl, tl]), Color("#080301", 0.95), 2.2, true) # Dark outer rim

func _draw_mop_scrolls(x_left: float, x_right: float, y_center: float, h_left: float, h_right: float) -> void:
	# Beautiful multi-colored iridescent mother-of-pearl (xà cừ) scroll effect
	var mop_color1 := Color("#b5e2db") # Iridescent Turquoise MOP
	mop_color1.a = 0.55
	var mop_color2 := Color("#e8cde1") # Iridescent Pink MOP
	mop_color2.a = 0.55
	var mop_gold   := Color("#c99a3c", 0.75) # Fine gold highlight
	
	var sections := 4
	var step_x := (x_right - x_left) / float(sections)
	
	for s in range(sections):
		var sec_x_start := x_left + s * step_x
		var sec_x_end := sec_x_start + step_x
		
		var t_start := float(s) / float(sections)
		var t_end := float(s + 1) / float(sections)
		var h_start := lerpf(h_left, h_right, t_start)
		var h_end := lerpf(h_left, h_right, t_end)
		
		# Upper MOP vine
		var uy_start := y_center - h_start * 0.24
		var uy_end := y_center - h_end * 0.24
		var u_ctrl1 := Vector2(sec_x_start + step_x * 0.25, uy_start - 12.0)
		var u_ctrl2 := Vector2(sec_x_start + step_x * 0.75, uy_end + 12.0)
		_draw_bezier_vine(Vector2(sec_x_start, uy_start), u_ctrl1, u_ctrl2, Vector2(sec_x_end, uy_end), mop_color1, 1.2)
		
		# Lower MOP vine
		var ly_start := y_center + h_start * 0.24
		var ly_end := y_center + h_end * 0.24
		var l_ctrl1 := Vector2(sec_x_start + step_x * 0.25, ly_start + 12.0)
		var l_ctrl2 := Vector2(sec_x_start + step_x * 0.75, ly_end - 12.0)
		_draw_bezier_vine(Vector2(sec_x_start, ly_start), l_ctrl1, l_ctrl2, Vector2(sec_x_end, ly_end), mop_color2, 1.2)
		
		# Traditional Lotus flowers in MOP
		if s < sections - 1:
			var lotus_x := sec_x_end
			var lotus_h := lerpf(h_left, h_right, t_end)
			_draw_stylized_lotus(Vector2(lotus_x, y_center - lotus_h * 0.24), mop_color1, mop_gold)
			_draw_stylized_lotus(Vector2(lotus_x, y_center + lotus_h * 0.24), mop_color2, mop_gold)

func _draw_bezier_vine(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, col: Color, width: float) -> void:
	var pts := PackedVector2Array()
	var steps := 16
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var pt := p0.cubic_interpolate(p1, p2, p3, t)
		pts.append(pt)
	draw_polyline(pts, col, width, true)
	
	for i in range(1, steps, 5):
		var t := float(i) / float(steps)
		var pt := p0.cubic_interpolate(p1, p2, p3, t)
		var next_pt := p0.cubic_interpolate(p1, p2, p3, t + 0.05)
		var dir := (next_pt - pt).normalized()
		var normal := Vector2(-dir.y, dir.x)
		
		var leaf_tip := pt + normal * 5.0 + dir * 2.0
		draw_line(pt, leaf_tip, col, width * 0.8, true)
		draw_circle(leaf_tip, 1.2, col)

func _draw_stylized_lotus(center: Vector2, petal_col: Color, center_col: Color) -> void:
	draw_circle(center, 2.5, center_col)
	var petal_dist := 3.8
	var petal_radius := 2.0
	var angles := [0.0, 72.0, 144.0, 216.0, 288.0]
	for a in angles:
		var rad := deg_to_rad(a)
		var p_pos := center + Vector2(cos(rad), sin(rad)) * petal_dist
		draw_circle(p_pos, petal_radius, petal_col)
		draw_circle(p_pos + Vector2(cos(rad), sin(rad)) * 1.2, 0.8, center_col)

func _draw_shaded_gourd(pos: Vector2, direction: Vector2) -> void:
	# Concentric radial gradient rendering for bulb and neck of the gourd
	# 1. Bulb shadow
	draw_circle(pos + Vector2(0, 3.5), 13.5, Color(0, 0, 0, 0.35))
	
	# 2. Bulb (Bầu lớn) 3D Sphere Shading
	var bulb_r := 12.0
	var steps := 18
	for i in range(steps):
		var r_ratio := float(steps - i) / steps
		var r := bulb_r * r_ratio
		
		# Offset center slightly towards top-left to simulate light source
		var offset := direction * -1.5 * (1.0 - r_ratio) + Vector2(-0.8, -0.8) * (1.0 - r_ratio)
		var center := pos + offset
		
		# Interpolate dried gourd colors from dark rim to golden highlight
		var col := Color("#3d1b03").lerp(Color("#cf8c19"), r_ratio)
		if r_ratio > 0.8:
			col = col.lerp(Color("#ffebad"), (r_ratio - 0.8) / 0.2 * 0.85)
		
		draw_circle(center, r, col)
		
	# Glossy specular highlight spot
	draw_circle(pos - direction * 3.5 + Vector2(-2.5, -2.5), 2.0, Color(1, 1, 1, 0.75))

	# 3. Neck (Cổ bầu) 3D Shading
	var neck_center_base := pos + direction * 8.0
	draw_circle(neck_center_base + Vector2(0, 2.5), 9.0, Color(0, 0, 0, 0.30))
	
	var neck_r := 8.0
	for i in range(steps):
		var r_ratio := float(steps - i) / steps
		var r := neck_r * r_ratio
		var offset := direction * -1.0 * (1.0 - r_ratio) + Vector2(-0.6, -0.6) * (1.0 - r_ratio)
		var center := neck_center_base + offset
		
		var col := Color("#3d1b03").lerp(Color("#d69322"), r_ratio)
		if r_ratio > 0.8:
			col = col.lerp(Color("#ffecb8"), (r_ratio - 0.8) / 0.2 * 0.75)
		draw_circle(center, r, col)

	# 4. Tip (Núm bầu)
	var tip_center_base := pos + direction * 14.0
	var tip_r := 4.5
	for i in range(steps):
		var r_ratio := float(steps - i) / steps
		var r := tip_r * r_ratio
		var center := tip_center_base + Vector2(-0.3, -0.3) * (1.0 - r_ratio)
		var col := Color("#3a1d07").lerp(Color("#bd7c13"), r_ratio)
		draw_circle(center, r, col)
		
	# 5. String wrap where horn rod joins gourd
	var wrap_pos := pos + direction * -3.0
	draw_rect(Rect2(wrap_pos.x - 3.5, wrap_pos.y - 4.5, 7.0, 9.0), Color("#100c08"))
	draw_rect(Rect2(wrap_pos.x - 1.5, wrap_pos.y - 4.5, 3.0, 9.0), Color("#c99a3c"))

func _draw_brass_collar(pos: Vector2, angle: float) -> void:
	var width := 14.0
	var height := 8.0
	var rect_pts := PackedVector2Array([
		Vector2(-width/2.0, 0),
		Vector2(width/2.0, 0),
		Vector2(width/2.0 + 1.5, -height),
		Vector2(-width/2.0 - 1.5, -height)
	])
	
	for i in range(rect_pts.size()):
		rect_pts[i] = rect_pts[i].rotated(angle) + pos
		
	draw_colored_polygon(rect_pts, Color("#a37d22"))
	draw_polyline(rect_pts, Color("#fce8b3"), 1.0, true)

func _draw_peg(pos: Vector2) -> void:
	draw_rect(Rect2(pos.x - 3, pos.y - 10, 6, 20), Color("#301808"))
	draw_circle(Vector2(pos.x, pos.y - 10), 3.5, C_GOLD)
	draw_circle(Vector2(pos.x, pos.y + 10), 3.5, C_GOLD)
	draw_circle(pos, 2.5, C_GOLD)

func _draw_bend_gauge(center: Vector2, radius: float, cents: float) -> void:
	var steps := 32
	var angle_start := -PI * 0.75
	var angle_end := -PI * 0.25
	
	var bg_pts := PackedVector2Array()
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var angle := lerpf(angle_start, angle_end, t)
		bg_pts.append(center + Vector2(cos(angle), sin(angle)) * radius)
	
	draw_polyline(bg_pts, Color(1, 1, 1, 0.12), 3.5, true)
	
	# Add ticks for calibration values
	var tick_count := 7
	for j in range(tick_count):
		var t := float(j) / float(tick_count - 1)
		var tick_angle := lerpf(angle_start, angle_end, t)
		var t_start := center + Vector2(cos(tick_angle), sin(tick_angle)) * (radius - 3.0)
		var t_end := center + Vector2(cos(tick_angle), sin(tick_angle)) * (radius + 3.0)
		draw_line(t_start, t_end, Color("#c99a3c", 0.45), 1.0)
	
	var mid_angle := (angle_start + angle_end) * 0.5
	var tick_start := center + Vector2(cos(mid_angle), sin(mid_angle)) * (radius - 5.0)
	var tick_end := center + Vector2(cos(mid_angle), sin(mid_angle)) * (radius + 5.0)
	draw_line(tick_start, tick_end, Color(0.85, 0.72, 0.35, 0.7), 1.5)
	
	if abs(cents) > 2.0:
		var target_angle := mid_angle
		var color := Color.WHITE
		if cents > 0.0:
			target_angle = lerpf(mid_angle, angle_end, clampf(cents / 350.0, 0.0, 1.0))
			color = Color("#27ae60") # Success Green
		else:
			target_angle = lerpf(mid_angle, angle_start, clampf(-cents / 350.0, 0.0, 1.0))
			color = Color("#d35400") # Warning Orange/Red
			
		var fill_pts := PackedVector2Array()
		var fill_steps := 16
		for i in range(fill_steps + 1):
			var t := float(i) / float(fill_steps)
			var angle := lerpf(mid_angle, target_angle, t)
			fill_pts.append(center + Vector2(cos(angle), sin(angle)) * radius)
			
		draw_polyline(fill_pts, Color(color.r, color.g, color.b, 0.25), 7.0, true)
		draw_polyline(fill_pts, color, 2.5, true)
		
		var end_pt := center + Vector2(cos(target_angle), sin(target_angle)) * radius
		draw_circle(end_pt, 3.5, Color.WHITE)
		draw_circle(end_pt, 5.0, Color(color.r, color.g, color.b, 0.5))

func _draw_cents_readout(font: Font, pos: Vector2, cents: float) -> void:
	if font == null: return
	var sign_str := "+" if cents > 0 else ""
	var txt := "%s%d ¢" % [sign_str, int(cents)]
	
	var color := Color("#c99a3c")
	if cents > 5.0:
		color = Color("#2ecc71")
	elif cents < -5.0:
		color = Color("#e74c3c")
		
	var text_size := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 13)
	var badge_w := text_size.x + 14.0
	var badge_h := text_size.y + 4.0
	var badge_rect := Rect2(pos.x - badge_w/2.0, pos.y - badge_h/2.0, badge_w, badge_h)
	
	# Glassmorphism badge styling
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(0.04, 0.02, 0.01, 0.85)
	badge_style.border_color = Color(color.r, color.g, color.b, 0.45)
	badge_style.border_width_left = 1; badge_style.border_width_right = 1
	badge_style.border_width_top = 1; badge_style.border_width_bottom = 1
	badge_style.corner_radius_top_left = 8; badge_style.corner_radius_top_right = 8
	badge_style.corner_radius_bottom_left = 8; badge_style.corner_radius_bottom_right = 8
	
	draw_style_box(badge_style, badge_rect)
	
	var text_pos := pos + Vector2(0, text_size.y/2.0 - 2.0)
	draw_string(font, text_pos - Vector2(text_size.x/2.0, 0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, color)

func _draw_ivory_node(pos: Vector2, idx: int, is_target: bool, is_hovered: bool, glow_alpha: float, pulse_phase: float, font: Font) -> void:
	var brass_col  := Color("#c99a3c")
	var ivory_col  := Color("#faf5e6") # Polished Ivory
	var shadow_col := Color(0, 0, 0, 0.3)
	
	draw_circle(pos + Vector2(0, 2), 11.0, shadow_col)
	
	if is_target:
		# Premium glow pulses
		var pulse := (sin(pulse_phase * 2.0) + 1.0) * 0.5
		var glow_r := 15.0 + pulse * 4.5
		var glow_col := Color(0.79, 0.60, 0.24, 0.15 + pulse * 0.15)
		draw_circle(pos, glow_r, glow_col)
		draw_arc(pos, glow_r, 0.0, TAU, 28, Color(0.79, 0.60, 0.24, 0.35 + pulse * 0.25), 1.2)
		
	if glow_alpha > 0.01:
		var pluck_r := 10.0 + glow_alpha * 20.0
		draw_circle(pos, pluck_r, Color(1, 0.95, 0.75, glow_alpha * 0.45))
		draw_arc(pos, pluck_r, 0.0, TAU, 24, Color(1, 0.90, 0.5, glow_alpha * 0.55), 1.5)
		
	var base_r := 9.5
	if is_hovered:
		base_r = 11.0
	elif is_target:
		base_r = 10.0
		
	# Inlaid ivory node rendering
	draw_circle(pos, base_r, brass_col)
	draw_circle(pos, base_r - 1.5, ivory_col)
	draw_circle(pos, base_r - 4.5, brass_col)
	draw_circle(pos, 2.5, Color("#261408")) # dark core
	draw_circle(pos, 1.0, Color.WHITE) # high point reflection
	
	if font != null:
		var label_y := pos.y - 18.0
		var text := _note_names[idx] if idx < _note_names.size() else NOTES_VN[idx]
		var text_color := Color("#faf6eb") if is_target else (Color(1.0, 1.0, 1.0) if is_hovered else Color("#cbbdaf"))
		var font_size := 13 if (is_target or is_hovered) else 11
		
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var text_pos := Vector2(pos.x - text_size.x / 2.0, label_y)
		
		draw_string(font, text_pos + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, 0.75))
		draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)

func _draw_rivets(W: float, H: float) -> void:
	var plate_size := 22.0
	var brass_col := Color("#c99a3c")
	draw_colored_polygon(PackedVector2Array([Vector2(0,0), Vector2(plate_size,0), Vector2(plate_size*0.6,plate_size*0.6), Vector2(0,plate_size)]), brass_col)
	draw_circle(Vector2(plate_size*0.35, plate_size*0.35), 2.0, Color(0.2, 0.1, 0.0, 0.8))
	draw_colored_polygon(PackedVector2Array([Vector2(0,H), Vector2(0,H-plate_size), Vector2(plate_size*0.6,H-plate_size*0.6), Vector2(plate_size,H)]), brass_col)
	draw_circle(Vector2(plate_size*0.35, H-plate_size*0.35), 2.0, Color(0.2, 0.1, 0.0, 0.8))
	draw_colored_polygon(PackedVector2Array([Vector2(W,0), Vector2(W-plate_size,0), Vector2(W-plate_size*0.6,plate_size*0.6), Vector2(W,plate_size)]), brass_col)
	draw_circle(Vector2(W-plate_size*0.35, plate_size*0.35), 2.0, Color(0.2, 0.1, 0.0, 0.8))
	draw_colored_polygon(PackedVector2Array([Vector2(W,H), Vector2(W,H-plate_size), Vector2(W-plate_size*0.6,H-plate_size*0.6), Vector2(W-plate_size,H)]), brass_col)
	draw_circle(Vector2(W-plate_size*0.35, H-plate_size*0.35), 2.0, Color(0.2, 0.1, 0.0, 0.8))

# ─── Input Logic ──────────────────────────────────────────────────────────────
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var ev := event as InputEventMouseButton
		if ev.button_index == MOUSE_BUTTON_LEFT:
			if ev.pressed:
				_handle_touch_start(ev.position)
			else:
				_handle_touch_end()
	elif event is InputEventMouseMotion:
		var ev := event as InputEventMouseMotion
		_handle_touch_move(ev.position)
	elif event is InputEventScreenTouch:
		var ev := event as InputEventScreenTouch
		if ev.pressed:
			_handle_touch_start(ev.position)
		else:
			_handle_touch_end()
	elif event is InputEventScreenDrag:
		var ev := event as InputEventScreenDrag
		_handle_touch_move(ev.position)

func _handle_touch_start(pos: Vector2) -> void:
	var W := size.x
	var x_left := W * 0.18
	if pos.x < x_left + 15.0:
		_is_bending = true
		_update_bend(pos.x)
	else:
		var node_idx := _get_node_at(pos)
		if node_idx != -1:
			pluck(node_idx)

func _handle_touch_move(pos: Vector2) -> void:
	if _is_bending:
		_update_bend(pos.x)
	else:
		var node_idx := _get_node_at(pos)
		if node_idx != _hovered_node_idx:
			_hovered_node_idx = node_idx
			queue_redraw()

func _handle_touch_end() -> void:
	if _is_bending:
		_is_bending = false
		# Release and let the physical spring-damper model oscillate the rod
	_hovered_node_idx = -1
	queue_redraw()

func _get_node_at(pos: Vector2) -> int:
	var W := size.x
	var H := size.y
	var x_left := W * 0.18
	var x_right := W * 0.94
	var body_center_y := H * 0.55
	
	var start_x := x_left + 45.0
	var end_x   := x_right - 45.0
	var step_x  := (end_x - start_x) / float(NODE_COUNT - 1)
	
	var click_radius := 26.0
	
	for i in NODE_COUNT:
		var nx := start_x + float(i) * step_x
		var ny := body_center_y
		if pos.distance_to(Vector2(nx, ny)) <= click_radius:
			return i
	return -1

func _update_bend(touch_x: float) -> void:
	var W := size.x
	var x_left := W * 0.18
	var max_drag := W * 0.08
	
	var drag_diff := touch_x - x_left
	_bend_offset = clampf(drag_diff, -max_drag, max_drag)
	_bend_velocity = 0.0 # Clear velocity while manual touch is active
	
	var factor := _bend_offset / max_drag
	_bend_cents = -factor * 350.0
	
	pitch_bent.emit(_bend_cents)
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_hovered_node_idx = -1
		if _is_bending:
			_handle_touch_end()
		queue_redraw()
