extends Control

signal string_plucked(idx: int, note_name: String)
signal string_pressed(idx: int, pitch_cents_offset: float)

var string_index: int = 0
var note_name: String = ""
var base_frequency: float = 130.81

# Visual states
var is_plucked := false
var is_pressed := false
var is_target := false
var press_pos := Vector2.ZERO
var pluck_effect_time := 0.0
var pluck_amplitude := 0.0

# Audio player
var audio_player: AudioStreamPlayer = null
var base_stream: AudioStreamWAV = null

# Colors
const C_GOLD := Color(0.95, 0.72, 0.18, 1.0)
const C_GOLD_LIGHT := Color(1.00, 0.87, 0.45, 1.0)
const C_WOOD_DARK := Color(0.18, 0.10, 0.05, 1.0)
const C_WOOD_LIGHT := Color(0.28, 0.16, 0.08, 1.0)

func init(idx: int, note: String, freq: float, stream: AudioStreamWAV) -> void:
	string_index = idx
	note_name = note
	base_frequency = freq
	base_stream = stream
	custom_minimum_size = Vector2(0, 18) # Comfortable height for touch targets
	size_flags_horizontal = SIZE_EXPAND_FILL

func _ready() -> void:
	queue_redraw()

func _process(delta: float) -> void:
	if pluck_effect_time > 0.0:
		pluck_effect_time -= delta
		# Decrease pluck amplitude for vibration animation decay
		pluck_amplitude = max(0.0, pluck_amplitude - delta * 3.5)
		queue_redraw()

func _draw() -> void:
	var w = size.x
	var h = size.y
	var cy = h / 2.0
	var left_x = 0.08 * w
	var right_x = 0.92 * w
	var bridge_x = 0.70 * w
	
	# 1. Draw wood background lane for the string
	var lane_color = C_WOOD_DARK if string_index % 2 == 0 else C_WOOD_LIGHT
	draw_rect(Rect2(0, 0, w, h), lane_color)
	
	# Draw a subtle separator line at the bottom
	draw_line(Vector2(0, h), Vector2(w, h), Color(0.08, 0.04, 0.02, 0.6), 1.0)

	# 2. Draw bridge (nhạn đàn)
	var bridge_width = 18.0
	var bridge_height = 14.0
	var b_pts = PackedVector2Array([
		Vector2(bridge_x - bridge_width/2.0, h - 2.0),
		Vector2(bridge_x, cy - 2.0), # peak just below string center
		Vector2(bridge_x + bridge_width/2.0, h - 2.0)
	])
	draw_polygon(b_pts, PackedColorArray([Color(0.55, 0.30, 0.10), Color(0.72, 0.45, 0.20), Color(0.40, 0.22, 0.06)]))
	
	# Draw bone/plastic saddle at the peak
	draw_circle(Vector2(bridge_x, cy - 2.0), 2.0, Color(0.95, 0.95, 0.90))

	# 3. Draw string line
	var string_color = Color(1.0, 0.88, 0.50) if is_plucked else Color(0.85, 0.68, 0.35)
	if is_pressed:
		string_color = Color(1.0, 0.65, 0.25)
	elif is_target:
		string_color = Color(1.0, 0.85, 0.20)
		
	# Lower strings are thicker than treble strings
	var string_width = 1.0 + (15 - string_index) * 0.12
	
	# Determine string path points
	var pts = PackedVector2Array()
	pts.append(Vector2(left_x, cy))
	
	if is_pressed and press_pos.x > left_x and press_pos.x < bridge_x:
		pts.append(press_pos)
		pts.append(Vector2(bridge_x, cy))
	else:
		pts.append(Vector2(bridge_x, cy))
		
	# Right side of the bridge (plucked part) with vibrating wave animation
	if pluck_amplitude > 0.0:
		var divisions = 8
		for k in range(1, divisions):
			var ratio = float(k) / float(divisions)
			var sx = lerp(bridge_x, right_x, ratio)
			var offset_y = sin(ratio * PI) * pluck_amplitude * 3.5 * sin(pluck_effect_time * 75.0)
			pts.append(Vector2(sx, cy + offset_y))
			
	pts.append(Vector2(right_x, cy))
	
	# Draw the string polyline
	draw_polyline(pts, string_color, string_width, true)

	# Draw target glow outline if this is the target string
	if is_target:
		draw_polyline(pts, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25), string_width + 4.0, true)

	# 4. Draw string visual feedback / glow when plucked
	if pluck_amplitude > 0.0:
		var glow_color = Color(1.0, 0.87, 0.45, pluck_amplitude * 0.18)
		draw_polyline(pts, glow_color, string_width + 4.0, true)

	# 5. Draw labels (String number on left, Note name on right)
	var font = ThemeDB.get_default_theme().get_default_font()
	var font_size = 12
	
	# Render string number
	draw_string(font, Vector2(12, cy + 4), str(string_index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.6))
	# Render note name
	draw_string(font, Vector2(w - 42, cy + 4), note_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.85))

	# Draw small visual indicator if string is target note
	if is_pressed:
		draw_circle(press_pos, 4.0, Color(1, 0.3, 0.2, 0.9))

func _gui_input(event: InputEvent) -> void:
	var w = size.x
	var h = size.y
	var cy = h / 2.0
	var left_x = 0.08 * w
	var right_x = 0.92 * w
	var bridge_x = 0.70 * w

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var pos = event.position
				if pos.x >= bridge_x and pos.x <= right_x:
					# Pluck Zone!
					pluck()
				elif pos.x >= left_x and pos.x < bridge_x:
					# Press Zone!
					is_pressed = true
					press_pos = pos
					# Limit bend vertical range
					press_pos.y = clamp(press_pos.y, cy, cy + 16.0)
					_update_press()
					queue_redraw()
			else:
				# Release
				if is_pressed:
					is_pressed = false
					_update_press()
					queue_redraw()
				
	elif event is InputEventMouseMotion and is_pressed:
		var pos = event.position
		press_pos.x = clamp(pos.x, left_x + 10.0, bridge_x - 10.0)
		press_pos.y = clamp(pos.y, cy, cy + 16.0) # only bend downwards
		_update_press()
		queue_redraw()

func pluck() -> void:
	is_plucked = true
	pluck_effect_time = 0.6
	pluck_amplitude = 1.0
	
	# Instantiate and play AudioStreamPlayer
	if audio_player and is_instance_valid(audio_player):
		audio_player.stop()
		audio_player.queue_free()
		
	audio_player = AudioStreamPlayer.new()
	audio_player.stream = base_stream
	audio_player.pitch_scale = _get_current_pitch_scale()
	add_child(audio_player)
	audio_player.play()
	
	# Safe clean up after decay
	var temp_player = audio_player
	get_tree().create_timer(2.2).timeout.connect(func() -> void:
		if is_instance_valid(temp_player):
			temp_player.queue_free()
	)
	
	string_plucked.emit(string_index, note_name)
	queue_redraw()

func _get_current_pitch_scale() -> float:
	if not is_pressed:
		return 1.0
	var h = size.y
	var cy = h / 2.0
	var max_bend = 16.0
	var bend_amount = clamp((press_pos.y - cy) / max_bend, 0.0, 1.0)
	# Map bend to up to +200 cents (1.1224 pitch_scale)
	return 1.0 + bend_amount * 0.1224

func _update_press() -> void:
	var scale = _get_current_pitch_scale()
	if audio_player and is_instance_valid(audio_player) and audio_player.playing:
		# Smoothly slide pitch scale to simulate real string stretching!
		var t = create_tween()
		t.tween_property(audio_player, "pitch_scale", scale, 0.05)
		
	var cents_offset = (scale - 1.0) * 1630.0 # Map back to cents display
	string_pressed.emit(string_index, cents_offset)
