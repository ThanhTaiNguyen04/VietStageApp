extends Control

signal drum_hit(hit_type: String)

var _target_hit: String = ""
var _last_hit_pos: Vector2 = Vector2.ZERO
var _last_hit_time: float = -999.0
var _last_hit_type: String = ""
var _time: float = 0.0

var _left_hit_target: Vector2 = Vector2.ZERO
var _right_hit_target: Vector2 = Vector2.ZERO
var _left_stick_t: float = 1.0
var _right_stick_t: float = 1.0
var _use_left_stick: bool = true

var _is_rolling: bool = false
var _roll_timer: float = 0.0

var _swipe_started: bool = false
var _last_swipe_pos: Vector2 = Vector2.ZERO
var _rim_triggered_this_swipe: bool = false

var audio_enabled: bool = true
var audio_engine: TrongChauAudioEngine

func init(notes: Array[String], streams: Array, freqs: Array[float]) -> void:
	# Keep compatible with generic Board initialization
	queue_redraw()

func set_target_note(note_name: String) -> void:
	# Map sheet music note name to target drum hit (Tịch/Cắc)
	_target_hit = note_name
	queue_redraw()

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	resized.connect(queue_redraw)
	
	audio_engine = TrongChauAudioEngine.new()
	add_child(audio_engine)
	
	queue_redraw()

func set_target(hit_type: String) -> void:
	_target_hit = hit_type
	queue_redraw()



func _draw_drumstick(tip_pos: Vector2, angle: float, rim_r: float) -> void:
	var stick_len := rim_r * 1.2 # Even longer stick
	var handle_pos := tip_pos - Vector2(cos(angle), sin(angle)) * stick_len
	
	var shadow_offset := Vector2(10, 25)
	draw_line(handle_pos + shadow_offset, tip_pos + shadow_offset, Color(0, 0, 0, 0.4), 30.0, true)
	draw_circle(tip_pos + shadow_offset, 22.0, Color(0, 0, 0, 0.4))
	
	draw_line(handle_pos, tip_pos, Color(0.85, 0.68, 0.45), 26.0, true) # Super thick stick
	
	var wrap_pos: Vector2 = lerp(handle_pos, tip_pos, 0.35)
	draw_line(handle_pos, wrap_pos, Color(0.70, 0.15, 0.10), 28.0, true) # Thick wrap
	
	draw_circle(tip_pos, 22.0, Color(0.92, 0.82, 0.65)) # Huge tip
	draw_circle(tip_pos - Vector2(4, 4), 8.0, Color(1, 1, 1, 0.8))

func hit_lane(lane: int) -> void:
	if lane == 0:
		hit("Tịch", Vector2(size.x * 0.5, size.y * 0.5))
	else:
		var rim_r = clamp(size.x * 0.28, 200.0, 300.0)
		hit("Cắc", Vector2(size.x * 0.5 + rim_r, size.y * 0.5))

func hit(hit_type: String, pos: Vector2) -> void:
	_last_hit_pos = pos
	_last_hit_time = _time
	_last_hit_type = hit_type
	
	# Apply inverse transform to Y so the stick visual hits the exact screen coordinate
	var t_pos = Vector2(pos.x, pos.y / 0.45)
	
	if hit_type == "Roll":
		_is_rolling = true
		_roll_timer = 1.2 # Duration of the roll
		_left_hit_target = t_pos + Vector2(-40, 0)
		_right_hit_target = t_pos + Vector2(40, 0)
	else:
		if _use_left_stick:
			_left_hit_target = t_pos
			_left_stick_t = 0.0
		else:
			_right_hit_target = t_pos
			_right_stick_t = 0.0
			
		_use_left_stick = !_use_left_stick
		
	if audio_enabled:
		_play_audio(hit_type)
		
	drum_hit.emit(hit_type)
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	var needs_redraw := false
	
	if _is_rolling:
		_roll_timer -= delta
		if _roll_timer <= 0:
			_is_rolling = false
			_left_stick_t = 1.0
			_right_stick_t = 1.0
		else:
			# Vibrate sticks rapidly using sin waves
			var freq = 45.0
			_left_stick_t = 0.3 + 0.3 * sin(_time * freq)
			_right_stick_t = 0.3 + 0.3 * sin(_time * freq + PI)
		needs_redraw = true
	else:
		if _left_stick_t < 1.0:
			_left_stick_t = minf(1.0, _left_stick_t + delta * 6.0)
			needs_redraw = true
		if _right_stick_t < 1.0:
			_right_stick_t = minf(1.0, _right_stick_t + delta * 6.0)
			needs_redraw = true
		
	if _time - _last_hit_time < 0.6:
		needs_redraw = true
		
	if needs_redraw:
		queue_redraw()

func _draw() -> void:
	var cx := size.x * 0.5
	var cy := size.y * 0.5
	var center := Vector2(cx, cy)
	
	# Basic size - massive and clear
	var rim_r : float = clamp(size.x * 0.28, 200.0, 300.0)
	var head_r : float = rim_r * 0.88
	
	# Apply 2.5D squashing transform
	draw_set_transform(Vector2.ZERO, 0, Vector2(1.0, 0.45))
	var scaled_cy = cy / 0.45
	center.y = scaled_cy
	cy = scaled_cy
	
	# Initialize target positions dynamically based on new lane layout
	if _left_hit_target == Vector2.ZERO:
		_left_hit_target = Vector2(cx, cy) # Center (Tịch)
	if _right_hit_target == Vector2.ZERO:
		_right_hit_target = Vector2(cx + rim_r, cy) # Right rim (Cắc)
	
	# Draw red drum body (Solid barrel shape)
	var body_color = Color(0.85, 0.12, 0.12) # Bright glossy red
	var body_dark = Color(0.6, 0.05, 0.05)
	
	# Solid barrel polygon
	var barrel_pts = PackedVector2Array([
		Vector2(cx - rim_r, cy),
		Vector2(cx + rim_r, cy),
		Vector2(cx + rim_r * 1.05, cy + rim_r * 0.75),
		Vector2(cx + rim_r, cy + rim_r * 1.5),
		Vector2(cx - rim_r, cy + rim_r * 1.5),
		Vector2(cx - rim_r * 1.05, cy + rim_r * 0.75)
	])
	draw_colored_polygon(barrel_pts, body_color)
	draw_polyline(barrel_pts, body_dark, 4.0, true)
	draw_arc(Vector2(cx, cy + rim_r * 1.5), rim_r, 0, PI, 64, body_color, 4.0)
	
	# Soft curved gradient shadow on the body instead of clouds
	var body_shadow_color = Color(0.5, 0.0, 0.0, 0.3)
	draw_arc(Vector2(cx, cy + rim_r * 0.8), rim_r * 0.9, 0, PI, 64, body_shadow_color, 12.0)
	draw_arc(Vector2(cx, cy + rim_r * 1.2), rim_r * 0.95, 0, PI, 64, body_shadow_color, 18.0)
	
	# 1. (Removed Drum Stand)

	# 2. Thick Black Wooden Rim
	var rim_color = Color(0.12, 0.1, 0.1) # Very dark black/brown
	draw_circle(center, rim_r, rim_color)
	draw_arc(center, rim_r, 0.0, TAU, 64, Color(0.05, 0.05, 0.05), 8.0, true)

	# 3. Pegs (Ghim đen đinh viền)
	var peg_count: int = 48
	for i in range(peg_count):
		var angle: float = float(i) * TAU / float(peg_count)
		var r_pos: Vector2 = center + Vector2(cos(angle), sin(angle)) * (rim_r * 0.94)
		draw_circle(r_pos, 4.5, Color(0.05, 0.05, 0.05)) # dark peg hole
		draw_circle(r_pos + Vector2(0, -1), 2.5, Color(0.3, 0.3, 0.3)) # peg highlight

	# 4. Drumhead (Mặt da trâu - worn leather)
	var leather_base = Color(0.95, 0.88, 0.75) # Very light pale tan/yellow hide color
	draw_circle(center, head_r, leather_base)
	
	# Draw wear and tear (vết sờn rách nhẹ của da trâu)
	for i in range(30):
		var factor := float(i) / 30.0
		var r_i : float = head_r * (1.0 - factor)
		var opacity := 0.05 + 0.1 * (i % 3)
		var l_col = leather_base.lightened(0.1) if (i % 2 == 0) else leather_base.darkened(0.1)
		l_col.a = opacity
		draw_circle(center, r_i, l_col)
	
	# Scratches/texture lines
	for i in range(12):
		var angle = float(i) * TAU / 12.0
		var p1 = center + Vector2(cos(angle), sin(angle)) * (head_r * 0.2)
		var p2 = center + Vector2(cos(angle + 0.5), sin(angle + 0.5)) * (head_r * 0.8)
		draw_line(p1, p2, Color(0.6, 0.45, 0.3, 0.15), 3.0)
		
	# Subtle inner ring (often present on real drums as skin layers)
	draw_arc(center, head_r * 0.85, 0.0, TAU, 64, Color(0.5, 0.4, 0.3, 0.4), 4.0, true)

	# Convex shading for 3D depth around the rim - keeping it very soft so it doesn't darken the wood
	var shade_steps := 8
	for i in range(shade_steps):
		var factor := float(i) / float(shade_steps)
		var r_i : float = head_r * (1.0 - factor * 0.15)
		var opacity := 0.25 * (1.0 - factor)
		draw_circle(center, r_i, Color(0.2, 0.1, 0.0, opacity))

	# 6. Highlight Target Area (REMOVED as requested)

	# 7. Ripple effects
	var time_since_hit: float = _time - _last_hit_time
	if time_since_hit < 0.6 and _last_hit_pos != Vector2.ZERO:
		var t: float = time_since_hit / 0.6
		var ripple_r: float = 15.0 + t * 90.0
		var r_alpha: float = (1.0 - t) * 0.75
		var ripple_color: Color = Color(0.95, 0.82, 0.45, r_alpha) if _last_hit_type in ["Rim", "Edge"] else Color(0.85, 0.18, 0.12, r_alpha)
		
		# Map absolute ripple pos to transformed space for drawing
		var t_pos = Vector2(_last_hit_pos.x, _last_hit_pos.y / 0.45)
		draw_arc(t_pos, ripple_r, 0.0, TAU, 24, ripple_color, 3.0, true)
		draw_circle(t_pos, 5.0, Color(ripple_color.r, ripple_color.g, ripple_color.b, (1.0 - t) * 0.9))

	# 8. Interactive Drumsticks
	var rest_pos_l := Vector2(cx - head_r * 0.8, cy + head_r * 1.0)
	var rest_rot_l := -0.6
	var stick_pos_l: Vector2 = lerp(_left_hit_target, rest_pos_l, _left_stick_t)
	var stick_rot_l: float = lerp(-0.15, rest_rot_l, _left_stick_t)
	_draw_drumstick(stick_pos_l, stick_rot_l, rim_r)
	
	var rest_pos_r := Vector2(cx + head_r * 0.8, cy + head_r * 1.0)
	var rest_rot_r := -2.6 # Pointing from bottom-right to top-left
	var stick_pos_r: Vector2 = lerp(_right_hit_target, rest_pos_r, _right_stick_t)
	var stick_rot_r: float = lerp(-2.9, rest_rot_r, _right_stick_t)
	_draw_drumstick(stick_pos_r, stick_rot_r, rim_r)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_swipe_started = true
			_rim_triggered_this_swipe = false
			_last_swipe_pos = event.position
			var z = _get_zone(event.position)
			if z != "": hit(z, event.position)
		else:
			_swipe_started = false
			
	elif (event is InputEventMouseMotion or event is InputEventScreenDrag) and _swipe_started:
		var diff = event.position - _last_swipe_pos
		var m_pos = event.position
		
		# Update last pos for continuous dragging calculation
		_last_swipe_pos = m_pos
		
		if not _rim_triggered_this_swipe:
			var sz: Vector2 = size
			var cy: float = sz.y * 0.5
			var rim_r: float = minf(sz.x, sz.y) * 0.44
			
			# Check if touch is on the drum body (below the center rim, up to bottom of the body)
			var is_on_body = m_pos.y > cy and m_pos.y < (cy + rim_r * 1.6)
			
			# Check if the motion is mostly horizontal (swipe left/right) and long enough
			var is_horizontal_swipe = abs(diff.x) > 5.0 and abs(diff.x) > abs(diff.y) * 1.5
			
			if is_on_body and is_horizontal_swipe:
				hit("Rim", m_pos)
				_rim_triggered_this_swipe = true

func _get_zone(m_pos: Vector2) -> String:
	var sz: Vector2 = size
	var cx: float = sz.x * 0.5
	var cy: float = sz.y * 0.5
	var center: Vector2 = Vector2(cx, cy)
	var dist: float = m_pos.distance_to(center)
	
	var rim_r: float = minf(sz.x, sz.y) * 0.44
	var head_r: float = rim_r * 0.8
	
	if dist <= head_r * 0.35: return "Center"
	if dist <= head_r * 0.75: return "OffCenter"
	if dist <= head_r: return "Edge"
	if dist <= rim_r * 1.1: return "Rim"
	return ""

# ─── Sound Generators ──────────────────────────────────────────────────────────
func _play_audio(hit_type: String) -> void:
	if hit_type == "Center" or hit_type == "Tịch":
		audio_engine.play_center()
	elif hit_type == "OffCenter":
		audio_engine.play_soft()
	elif hit_type == "Edge" or hit_type == "Cắc":
		audio_engine.play_edge()
	elif hit_type == "Rim":
		audio_engine.play_rim()
	elif hit_type == "Roll":
		audio_engine.play_roll()
	elif hit_type == "Hard":
		audio_engine.play_hard()
