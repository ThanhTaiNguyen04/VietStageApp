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

var _audio_players: Dictionary = {}
var audio_enabled: bool = true

# Synthetic sound streams
var _stream_tich: AudioStreamWAV = null
var _stream_cac: AudioStreamWAV = null

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
	_generate_sounds()
	_setup_audio_players()
	queue_redraw()

func set_target(hit_type: String) -> void:
	_target_hit = hit_type
	queue_redraw()

func hit(hit_type: String, pos: Vector2) -> void:
	_last_hit_pos = pos
	_last_hit_time = _time
	_last_hit_type = hit_type
	
	if hit_type == "Tịch":
		_left_hit_target = pos
		_left_stick_t = 0.0
	else:
		_right_hit_target = pos
		_right_stick_t = 0.0
		
	if audio_enabled:
		_play_audio(hit_type)
		
	drum_hit.emit(hit_type)
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	var needs_redraw := false
	
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
	var sz: Vector2 = size
	var cx: float = sz.x * 0.5
	var cy: float = sz.y * 0.5
	var center: Vector2 = Vector2(cx, cy)
	
	var rim_r: float = minf(sz.x, sz.y) * 0.42
	var head_r: float = rim_r * 0.8
	
	# Initialize hit positions dynamically if they are empty
	if _left_hit_target == Vector2.ZERO:
		_left_hit_target = Vector2(cx - head_r * 0.5, cy + head_r * 0.2)
	if _right_hit_target == Vector2.ZERO:
		_right_hit_target = Vector2(cx + head_r * 0.5, cy + head_r * 0.2)

	# 1. Draw Wood Stand (Giá đỡ trống) behind the drum
	var stand_w := rim_r * 1.8
	var stand_h := rim_r * 0.28
	var stand_rect := Rect2(cx - stand_w * 0.5, cy + rim_r * 0.72, stand_w, stand_h)
	draw_rect(stand_rect, Color(0.14, 0.08, 0.04), true) # Dark wood base
	draw_rect(stand_rect, Color(0.10, 0.05, 0.02), false, 2.0) # Border
	
	# Golden patterns on stand base
	draw_rect(Rect2(cx - stand_w * 0.46, cy + rim_r * 0.77, stand_w * 0.92, stand_h * 0.4), Color(0.77, 0.58, 0.15, 0.75), false, 1.5)
	
	# Support arms holding the drum on left and right
	var arm_w := rim_r * 0.12
	var arm_h := rim_r * 0.7
	draw_rect(Rect2(cx - rim_r * 1.02, cy + rim_r * 0.2, arm_w, arm_h), Color(0.18, 0.10, 0.05), true)
	draw_rect(Rect2(cx + rim_r * 1.02 - arm_w, cy + rim_r * 0.2, arm_w, arm_h), Color(0.18, 0.10, 0.05), true)
	
	# Gold fittings on support arms
	draw_circle(Vector2(cx - rim_r * 1.02 + arm_w*0.5, cy + rim_r * 0.35), 6.0, Color(0.77, 0.58, 0.15))
	draw_circle(Vector2(cx + rim_r * 1.02 - arm_w*0.5, cy + rim_r * 0.35), 6.0, Color(0.77, 0.58, 0.15))

	# 2. Outer Wooden Rim (Vành trống - cylinder layered)
	for i in range(10):
		var factor := float(i) / 10.0
		var r_i := rim_r - factor * (rim_r - head_r)
		var col := Color(0.15, 0.08, 0.04).lerp(Color(0.38, 0.20, 0.10), factor)
		draw_circle(center, r_i, col)
		
	# Draw concentric grain rings on the rim
	for i in range(4):
		var g_r := head_r + (rim_r - head_r) * (0.2 + 0.2 * i)
		draw_arc(center, g_r, 0.0, TAU, 64, Color(0.10, 0.05, 0.02, 0.45), 1.0, true)
		
	# Ornate outer gold ring border
	draw_arc(center, rim_r, 0.0, TAU, 64, Color(0.77, 0.58, 0.15), 3.0, true)

	# 3. Rivets (Đinh đồng)
	var rivet_count: int = 24
	for i in range(rivet_count):
		var angle: float = float(i) * TAU / float(rivet_count)
		var r_pos: Vector2 = center + Vector2(cos(angle), sin(angle)) * (head_r + (rim_r - head_r) * 0.5)
		draw_circle(r_pos + Vector2(0, 1.5), 4.5, Color(0, 0, 0, 0.35)) # shadow
		draw_circle(r_pos, 4.0, Color(0.85, 0.70, 0.20)) # gold body
		draw_circle(r_pos - Vector2(1, 1), 1.5, Color(1.0, 1.0, 0.90)) # reflection

	# 4. Drumhead (Mặt da trâu - aged cream leather)
	draw_circle(center, head_r, Color(0.94, 0.88, 0.75))
	
	# Concentric rings
	draw_arc(center, head_r * 0.88, 0.0, TAU, 48, Color(0.75, 0.65, 0.50, 0.45), 1.5, true)
	draw_arc(center, head_r * 0.75, 0.0, TAU, 48, Color(0.75, 0.65, 0.50, 0.45), 1.5, true)
	draw_arc(center, head_r * 0.58, 0.0, TAU, 40, Color(0.75, 0.65, 0.50, 0.45), 1.5, true)
	draw_arc(center, head_r * 0.46, 0.0, TAU, 36, Color(0.75, 0.65, 0.50, 0.45), 1.5, true)
	draw_arc(center, head_r * 0.3, 0.0, TAU, 24, Color(0.75, 0.65, 0.50, 0.45), 1.5, true)

	# 5. Traditional Decorative Patterns (Dong Son style)
	# Dots between outer rings
	var dot_count := 48
	for i in range(dot_count):
		var angle := float(i) * TAU / float(dot_count)
		var d_pos := center + Vector2(cos(angle), sin(angle)) * (head_r * 0.815)
		draw_circle(d_pos, 2.0, Color(0.77, 0.58, 0.15, 0.35))
		
	# Chevron triangles between middle rings
	var tooth_count := 24
	for i in range(tooth_count):
		var angle := float(i) * TAU / float(tooth_count)
		var angle_next := float(i + 0.5) * TAU / float(tooth_count)
		var angle_next2 := float(i + 1) * TAU / float(tooth_count)
		var p1 := center + Vector2(cos(angle), sin(angle)) * (head_r * 0.3)
		var p2 := center + Vector2(cos(angle_next), sin(angle_next)) * (head_r * 0.38)
		var p3 := center + Vector2(cos(angle_next2), sin(angle_next2)) * (head_r * 0.3)
		draw_colored_polygon(PackedVector2Array([p1, p2, p3]), Color(0.77, 0.58, 0.15, 0.25))

	# Starburst sun in the very center
	var star_r := head_r * 0.18
	var inner_r := head_r * 0.07
	var star_pts := PackedVector2Array()
	for i in range(24):
		var angle := float(i) * TAU / 24.0
		var curr_r := star_r if i % 2 == 1 else inner_r
		star_pts.append(center + Vector2(cos(angle), sin(angle)) * curr_r)
	draw_colored_polygon(star_pts, Color(0.77, 0.58, 0.15, 0.7))

	# 4 Flying Lac Birds
	for i in range(4):
		var angle := float(i) * TAU / 4.0 + _time * 0.1 # Slow aesthetic rotation
		_draw_lac_bird(center, head_r * 0.52, angle, Color(0.77, 0.58, 0.15, 0.6))

	# Convex shading for 3D depth
	var shade_steps := 15
	for i in range(shade_steps):
		var factor := float(i) / float(shade_steps)
		var r_i := head_r * (1.0 - factor * 0.35)
		var opacity := 0.25 * factor
		draw_circle(center, r_i, Color(0.18, 0.10, 0.05, opacity))

	# 6. Highlight Target Area (Show glow on Head if target is Tịch, or Rim if Cắc)
	if _target_hit != "":
		var pulse: float = 0.2 * sin(_time * 6.0) + 0.3
		var t_color: Color = Color(0.77, 0.58, 0.15, pulse)
		if _target_hit == "Tịch":
			draw_arc(center, head_r * 0.5, 0.0, TAU, 32, t_color, 4.0, true)
		elif _target_hit == "Cắc":
			draw_arc(center, (rim_r + head_r) * 0.5, 0.0, TAU, 48, t_color, 6.0, true)

	# 7. Ripple effects upon hitting
	var time_since_hit: float = _time - _last_hit_time
	if time_since_hit < 0.6 and _last_hit_pos != Vector2.ZERO:
		var t: float = time_since_hit / 0.6
		var ripple_r: float = 15.0 + t * 90.0
		var r_alpha: float = (1.0 - t) * 0.75
		var ripple_color: Color = Color(0.95, 0.82, 0.45, r_alpha) if _last_hit_type == "Cắc" else Color(0.85, 0.18, 0.12, r_alpha)
		draw_arc(_last_hit_pos, ripple_r, 0.0, TAU, 24, ripple_color, 3.0, true)
		draw_circle(_last_hit_pos, 5.0, Color(ripple_color.r, ripple_color.g, ripple_color.b, (1.0 - t) * 0.9))

	# 8. Interactive Dynamic Drumsticks
	# Left Stick (Tịch strike)
	var rest_pos_l := Vector2(cx - head_r * 0.8, cy + head_r * 1.0)
	var rest_rot_l := -0.6
	var stick_pos_l: Vector2 = lerp(_left_hit_target, rest_pos_l, _left_stick_t)
	var stick_rot_l: float = lerp(-0.15, rest_rot_l, _left_stick_t)
	_draw_drumstick(stick_pos_l, stick_rot_l, rim_r)
	
	# Right Stick (Cắc strike)
	var rest_pos_r := Vector2(cx + head_r * 0.8, cy + head_r * 1.0)
	var rest_rot_r := 0.6
	var stick_pos_r: Vector2 = lerp(_right_hit_target, rest_pos_r, _right_stick_t)
	var stick_rot_r: float = lerp(3.29, rest_rot_r, _right_stick_t) # pointing inwards when hitting
	_draw_drumstick(stick_pos_r, stick_rot_r, rim_r)

func _draw_lac_bird(center: Vector2, radius: float, angle: float, col: Color) -> void:
	var b_pos := center + Vector2(cos(angle), sin(angle)) * radius
	var bird_scale := radius * 0.18
	# points representing a flying Lac bird silhouette
	var base_pts := PackedVector2Array([
		Vector2(0, -6),     # beak
		Vector2(5, -2),     # head
		Vector2(12, 0),     # neck
		Vector2(8, 6),      # wing top
		Vector2(2, 2),      # body
		Vector2(-8, 14),     # wing bottom
		Vector2(-2, 0),     # body
		Vector2(-12, -4),   # tail
		Vector2(-4, -4)     # neck back
	])
	var rotated_pts := PackedVector2Array()
	var rot_angle := angle + PI * 0.5 # flying forwards
	var cos_a := cos(rot_angle)
	var sin_a := sin(rot_angle)
	for pt in base_pts:
		var scaled := pt * (bird_scale / 12.0)
		var rot_pt := Vector2(
			scaled.x * cos_a - scaled.y * sin_a,
			scaled.x * sin_a + scaled.y * cos_a
		)
		rotated_pts.append(b_pos + rot_pt)
	draw_colored_polygon(rotated_pts, col)

func _draw_drumstick(tip_pos: Vector2, angle: float, rim_r: float) -> void:
	var stick_len := rim_r * 0.75
	var handle_pos := tip_pos - Vector2(cos(angle), sin(angle)) * stick_len
	
	# Draw Stick Shadow (behind stick, offset slightly)
	var shadow_offset := Vector2(8, 16)
	draw_line(handle_pos + shadow_offset, tip_pos + shadow_offset, Color(0, 0, 0, 0.28), 9.0, true)
	draw_circle(tip_pos + shadow_offset, 6.0, Color(0, 0, 0, 0.28))
	
	# Draw Wooden Shaft
	draw_line(handle_pos, tip_pos, Color(0.85, 0.68, 0.45), 7.0, true)
	
	# Draw Red Handle Wrap (lower 35% of the stick)
	var wrap_pos: Vector2 = lerp(handle_pos, tip_pos, 0.35)
	draw_line(handle_pos, wrap_pos, Color(0.70, 0.15, 0.10), 8.2, true)
	
	# Draw polished Tip Bead
	draw_circle(tip_pos, 5.5, Color(0.92, 0.82, 0.65))
	draw_circle(tip_pos - Vector2(1, 1), 2.0, Color(1, 1, 1, 0.8)) # Shine on bead

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var m_pos: Vector2 = event.position
		var sz: Vector2 = size
		var cx: float = sz.x * 0.5
		var cy: float = sz.y * 0.5
		var center: Vector2 = Vector2(cx, cy)
		var dist: float = m_pos.distance_to(center)
		
		var rim_r: float = minf(sz.x, sz.y) * 0.44
		var head_r: float = rim_r * 0.8
		
		if dist <= head_r:
			hit("Tịch", m_pos)
		elif dist > head_r and dist <= rim_r:
			hit("Cắc", m_pos)

# ─── Sound Generators ──────────────────────────────────────────────────────────
func _setup_audio_players() -> void:
	var p_tich: AudioStreamPlayer = AudioStreamPlayer.new()
	p_tich.stream = _stream_tich
	p_tich.name = "PlayerTich"
	add_child(p_tich)
	_audio_players["Tịch"] = p_tich
	
	var p_cac: AudioStreamPlayer = AudioStreamPlayer.new()
	p_cac.stream = _stream_cac
	p_cac.name = "PlayerCac"
	add_child(p_cac)
	_audio_players["Cắc"] = p_cac

func _play_audio(hit_type: String) -> void:
	if _audio_players.has(hit_type):
		var player: AudioStreamPlayer = _audio_players[hit_type] as AudioStreamPlayer
		if player:
			player.play()

func _generate_sounds() -> void:
	_stream_tich = _generate_tich()
	_stream_cac = _generate_cac()

func _generate_tich() -> AudioStreamWAV:
	# "Tịch" - Deep drumhead hit sound (rapid pitch drop: 160Hz -> 80Hz)
	const SAMPLE_RATE: int = 44100
	const DURATION: float  = 0.5
	var sample_count: int  = int(SAMPLE_RATE * DURATION)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(sample_count)
	
	var phase: float = 0.0
	for i in range(sample_count):
		var t: float = float(i) / float(SAMPLE_RATE)
		# Pitch drop envelope
		var freq: float = lerpf(160.0, 78.0, 1.0 - exp(-t * 22.0))
		phase += freq * TAU / float(SAMPLE_RATE)
		
		var env: float = exp(-t * 8.0) # Decay envelope
		var val: float = sin(phase) * env
		
		# Add initial noise burst for stick strike impact
		if t < 0.02:
			val = lerpf(randf_range(-0.5, 0.5), val, t / 0.02)
			
		samples[i] = val
		
	return _create_wav_stream(samples)

func _generate_cac() -> AudioStreamWAV:
	# "Cắc" - Wood rim click (high frequency: ~1100Hz, rapid decay)
	const SAMPLE_RATE: int = 44100
	const DURATION: float  = 0.15
	var sample_count: int  = int(SAMPLE_RATE * DURATION)
	var samples: PackedFloat32Array = PackedFloat32Array()
	samples.resize(sample_count)
	
	var phase: float = 0.0
	for i in range(sample_count):
		var t: float = float(i) / float(SAMPLE_RATE)
		var freq: float = 1150.0
		phase += freq * TAU / float(SAMPLE_RATE)
		
		var env: float = exp(-t * 32.0) # Sharp decay
		var val: float = sin(phase) * env
		
		# Add click impact noise
		if t < 0.015:
			val += randf_range(-0.3, 0.3) * env
			
		samples[i] = val
		
	return _create_wav_stream(samples)

func _create_wav_stream(samples: PackedFloat32Array) -> AudioStreamWAV:
	# Normalize
	var max_amp: float = 0.0
	for s in samples:
		max_amp = maxf(max_amp, absf(s))
	if max_amp < 0.0001:
		max_amp = 1.0
	var norm: float = 0.9 / max_amp
	
	var data: PackedByteArray = PackedByteArray()
	data.resize(samples.size() * 2)
	for i in range(samples.size()):
		var val: int = int(samples[i] * norm * 32767.0)
		val = clamp(val, -32768, 32767)
		data.encode_s16(i * 2, val)
		
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	stream.stereo = false
	return stream
