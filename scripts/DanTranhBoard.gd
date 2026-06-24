extends Control

signal string_plucked(idx: int, note_name: String)
signal string_pressed(idx: int, pitch_cents_offset: float)

const STR_COUNT := 16

var _note_names  : Array[String]      = []
var _streams     : Array              = []
var _freqs       : Array[float]       = []

var _pluck_amp   : PackedFloat32Array = PackedFloat32Array()
var _pluck_time  : PackedFloat32Array = PackedFloat32Array()
var _glow_alpha  : PackedFloat32Array = PackedFloat32Array()
var _pulse_phase : PackedFloat32Array = PackedFloat32Array()
var _is_target   : PackedByteArray    = PackedByteArray()
var _is_pressed  : PackedByteArray    = PackedByteArray()
var _press_x     : PackedFloat32Array = PackedFloat32Array()
var _press_y     : PackedFloat32Array = PackedFloat32Array()
var _audio_players : Array            = []
var _hovered_idx : int                = -1
var _active_touches : Dictionary      = {}

# ─── Init ─────────────────────────────────────────────────────────────────────
func init(notes: Array[String], streams: Array, freqs: Array[float]) -> void:
	_note_names = notes
	_streams    = streams
	_freqs      = freqs
	_pluck_amp.resize(STR_COUNT)
	_pluck_time.resize(STR_COUNT)
	_glow_alpha.resize(STR_COUNT)
	_pulse_phase.resize(STR_COUNT)
	_is_target.resize(STR_COUNT)
	_is_pressed.resize(STR_COUNT)
	_press_x.resize(STR_COUNT)
	_press_y.resize(STR_COUNT)
	_audio_players.resize(STR_COUNT)
	for i in STR_COUNT:
		_audio_players[i] = null
	mouse_filter = MOUSE_FILTER_STOP
	queue_redraw()

func _ready() -> void:
	resized.connect(queue_redraw)
	queue_redraw()

# ─── Public API ───────────────────────────────────────────────────────────────
func set_target(idx: int) -> void:
	if _is_target.size() < STR_COUNT:
		return
	for i in STR_COUNT:
		_is_target[i] = 1 if i == idx else 0
	queue_redraw()

func pluck(idx: int) -> void:
	if idx < 0 or idx >= STR_COUNT or _pluck_amp.size() < STR_COUNT:
		return
	_pluck_time[idx] = 0.0
	_pluck_amp[idx]  = 1.0
	_glow_alpha[idx] = 1.0
	_play_audio(idx, 1.0)
	var name_idx := idx % _note_names.size()
	string_plucked.emit(idx, _note_names[name_idx])
	queue_redraw()

# ─── Process ──────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if _pluck_amp.size() < STR_COUNT:
		return
	var need := false
	for i in STR_COUNT:
		if _pluck_amp[i] > 0.0:
			_pluck_time[i] += delta
			_pluck_amp[i]   = maxf(0.0, _pluck_amp[i] - delta * 2.8)
			_glow_alpha[i]  = _pluck_amp[i]
			need             = true
		elif _glow_alpha[i] > 0.0:
			_glow_alpha[i] = maxf(0.0, _glow_alpha[i] - delta * 3.5)
			need            = true
		if _is_target[i]:
			_pulse_phase[i] += delta * 3.5
			need             = true
		if _is_pressed[i]:
			_update_press(i)
			need             = true
	if need:
		queue_redraw()

# ─── Draw ─────────────────────────────────────────────────────────────────────
# ─── Draw ─────────────────────────────────────────────────────────────────────
func _draw() -> void:
	var W := size.x
	var H := size.y
	if W < 16.0 or H < 16.0:
		return

	# Board body background - rich lacquer mahogany with warm gradients
	draw_rect(Rect2(0.0, 0.0, W, H), Color(0.16, 0.08, 0.03))
	
	if _note_names.is_empty():
		return

	# Bevel wooden frames
	draw_rect(Rect2(0.0, 0.0, W, 10.0), Color(0.38, 0.18, 0.05)) # Top frame
	draw_rect(Rect2(0.0, H - 10.0, W, 10.0), Color(0.38, 0.18, 0.05)) # Bottom frame
	draw_rect(Rect2(0.0, 0.0, 14.0, H), Color(0.32, 0.15, 0.04)) # Left end block
	draw_rect(Rect2(W - 14.0, 0.0, 14.0, H), Color(0.32, 0.15, 0.04)) # Right end block
	
	# Bevel divider highlights
	draw_line(Vector2(0, 10), Vector2(W, 10), Color(0.55, 0.28, 0.10, 0.45), 1.5)
	draw_line(Vector2(0, H - 10), Vector2(W, H - 10), Color(0.18, 0.08, 0.02, 0.65), 1.5)
	draw_line(Vector2(14, 0), Vector2(14, H), Color(0.55, 0.28, 0.10, 0.45), 1.5)
	draw_line(Vector2(W - 14, 0), Vector2(W - 14, H), Color(0.18, 0.08, 0.02, 0.65), 1.5)

	var ix    := 14.0
	var iy    := 10.0
	var iw    := W - 28.0
	var ih    := H - 20.0
	var rh    := ih / float(STR_COUNT)

	var str_l    := ix + iw * 0.075
	var bridge_x := ix + iw * 0.695
	var str_r    := ix + iw * 0.945
	var lbl_x    := ix + 6.0

	var font : Font = null
	var dtheme := ThemeDB.get_default_theme()
	if dtheme != null:
		font = dtheme.get_default_font()

	for i in STR_COUNT:
		var ry := iy + float(i) * rh
		var cy := ry + rh * 0.5

		# Alternating wood texture lines in background
		var bg_col := Color(0.165, 0.09, 0.045) if (i % 2 == 0) else Color(0.21, 0.115, 0.06)
		draw_rect(Rect2(ix, ry, iw, rh), bg_col)

		# Wooden grain simulation lines
		for g in range(3):
			var gy = ry + rh * (0.2 + g * 0.3)
			draw_line(Vector2(ix, gy), Vector2(ix + iw, gy), Color(0.11, 0.05, 0.02, 0.18), 1.0)

		# Hover indicator
		if _hovered_idx == i:
			draw_rect(Rect2(ix, ry, iw, rh), Color(1.0, 0.88, 0.45, 0.06))

		# Target highlight pulse
		if _is_target[i]:
			var pulse_tint := (sin(_pulse_phase[i]) + 1.0) * 0.5
			draw_rect(Rect2(ix, ry, iw, rh), Color(0.95, 0.72, 0.18, 0.06 + pulse_tint * 0.06))

		# Row boundary line
		draw_line(Vector2(ix, ry + rh - 0.5), Vector2(ix + iw, ry + rh - 0.5), Color(0.08, 0.04, 0.02, 0.6), 1.0)

		# ── Inverted-V Traditional Bridge (Nhạn đàn) ──
		_draw_bridge(bridge_x, cy, rh)

		# ── Premium vibrating string lines ──
		var tc       := float(i) / float(STR_COUNT - 1)
		# Taper colors: low strings (bass) are gold brass, high are silver/steel
		var base_col := Color(0.92, 0.72, 0.22).lerp(Color(0.85, 0.88, 0.92), tc)

		var str_col := base_col
		if _pluck_amp[i] > 0.05:
			str_col = Color(1.00, 0.94, 0.75).lerp(base_col, 1.0 - _pluck_amp[i])
		elif _is_pressed[i]:
			str_col = Color(0.98, 0.42, 0.12) # orange bend highlight
		elif _is_target[i]:
			var pulse_col := (sin(_pulse_phase[i]) + 1.0) * 0.5
			str_col = base_col.lerp(Color(0.95, 0.72, 0.18), 0.25 + pulse_col * 0.25)

		var sw := lerpf(3.0, 1.3, tc) # thicker strings for bass notes

		var pts := PackedVector2Array()
		pts.append(Vector2(str_l, cy))
		if _is_pressed[i] and _press_x[i] > str_l and _press_x[i] < bridge_x:
			var max_b := _row_h() * 0.48
			var bend  := clampf((_press_y[i] - cy) / max_b, 0.0, 1.0)
			var visual_vibrato := sin(Time.get_ticks_msec() * 0.041) * 3.5 * bend
			pts.append(Vector2(_press_x[i], _press_y[i] + visual_vibrato))
		pts.append(Vector2(bridge_x, cy))
		
		# Vibration oscillation
		if _pluck_amp[i] > 0.005:
			var freq := _freqs[i] if i < _freqs.size() else 130.0
			var spd  := 58.0 + freq * 0.14
			for k in range(1, 11):
				var ratio := float(k) / 10.0
				var osc   := sin(ratio * PI) * sin(ratio * PI * 2.0 - _pluck_time[i] * spd) * _pluck_amp[i] * 5.0
				pts.append(Vector2(lerpf(bridge_x, str_r, ratio), cy + osc))
		pts.append(Vector2(str_r, cy))

		# Draw string drop shadow
		var shad := PackedVector2Array()
		for k in pts.size():
			shad.append(pts[k] + Vector2(0.0, sw * 0.8 + 1.5))
		draw_polyline(shad, Color(0.0, 0.0, 0.0, 0.32), sw * 0.7, true)

		# Draw motion blur vibrato lines
		if _pluck_amp[i] > 0.005:
			var blur_col := Color(str_col.r, str_col.g, str_col.b, _pluck_amp[i] * 0.28)
			var pts_up := PackedVector2Array()
			var pts_down := PackedVector2Array()
			for p_idx in pts.size():
				var offset := Vector2(0, sin(float(p_idx)/pts.size() * PI) * _pluck_amp[i] * 4.5)
				pts_up.append(pts[p_idx] + offset)
				pts_down.append(pts[p_idx] - offset)
			draw_polyline(pts_up, blur_col, sw * 0.8, true)
			draw_polyline(pts_down, blur_col, sw * 0.8, true)

		# Draw main string core
		draw_polyline(pts, str_col, sw, true)

		# Draw string glossy center highlight
		var hilit := PackedVector2Array()
		for k in pts.size():
			hilit.append(pts[k] + Vector2(0.0, -sw * 0.25))
		draw_polyline(hilit, Color(1.0, 1.0, 1.0, 0.25 * (1.0 - tc * 0.5)), sw * 0.35, true)

		# Target overlay halo
		if _is_target[i]:
			var pulse_glow := (sin(_pulse_phase[i]) + 1.0) * 0.5
			draw_polyline(pts, Color(0.95, 0.72, 0.18, 0.22 + pulse_glow * 0.20), sw + 4.5, true)

		# Pluck glow flare
		if _glow_alpha[i] > 0.01:
			draw_polyline(pts, Color(1.00, 0.92, 0.62, _glow_alpha[i] * 0.38), sw + 6.0,  true)
			draw_polyline(pts, Color(1.00, 0.95, 0.75, _glow_alpha[i] * 0.18), sw + 12.0, true)

		# ── Note Label and String Numbers ──
		if font != null:
			var num_alpha := 0.50 + _glow_alpha[i] * 0.50
			var f_size := 11
			var name_f_size := 12
			
			if rh < 18.0:
				f_size = clamp(int(rh * 0.7), 8, 10)
				name_f_size = clamp(int(rh * 0.75), 9, 11)
				
			var baseline_offset := f_size * 0.35
			var name_baseline_offset := name_f_size * 0.35
			
			draw_string(font, Vector2(lbl_x, cy + baseline_offset),
				str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, f_size,
				Color(0.95, 0.72, 0.18, num_alpha))
			var name_col := Color(0.98, 0.82, 0.20) if _is_target[i] else Color(0.95, 0.72, 0.18)
			draw_string(font, Vector2(str_r + 8.0, cy + name_baseline_offset),
				_note_names[i % _note_names.size()],
				HORIZONTAL_ALIGNMENT_LEFT, -1, name_f_size,
				Color(name_col.r, name_col.g, name_col.b, 0.90))

		# Press touch marker
		if _is_pressed[i]:
			var max_b := _row_h() * 0.48
			var bend  := clampf((_press_y[i] - cy) / max_b, 0.0, 1.0)
			var visual_vibrato := sin(Time.get_ticks_msec() * 0.041) * 3.5 * bend
			var marker_y = _press_y[i] + visual_vibrato
			draw_circle(Vector2(_press_x[i], marker_y), 6.0, Color(0.95, 0.22, 0.08, 0.85))
			draw_circle(Vector2(_press_x[i], marker_y), 3.0, Color(1.00, 0.75, 0.35, 0.95))

	# Traditional gold corner rivet plates
	var plate_size := 22.0
	var brass_col := Color(0.77, 0.58, 0.15, 0.92)
	# Top-Left
	draw_colored_polygon(PackedVector2Array([Vector2(0,0), Vector2(plate_size,0), Vector2(plate_size*0.6,plate_size*0.6), Vector2(0,plate_size)]), brass_col)
	draw_circle(Vector2(plate_size*0.35, plate_size*0.35), 2.0, Color(0.2, 0.1, 0.0, 0.8))
	# Bottom-Left
	draw_colored_polygon(PackedVector2Array([Vector2(0,H), Vector2(0,H-plate_size), Vector2(plate_size*0.6,H-plate_size*0.6), Vector2(plate_size,H)]), brass_col)
	draw_circle(Vector2(plate_size*0.35, H-plate_size*0.35), 2.0, Color(0.2, 0.1, 0.0, 0.8))
	# Top-Right
	draw_colored_polygon(PackedVector2Array([Vector2(W,0), Vector2(W-plate_size,0), Vector2(W-plate_size*0.6,plate_size*0.6), Vector2(W,plate_size)]), brass_col)
	draw_circle(Vector2(W-plate_size*0.35, plate_size*0.35), 2.0, Color(0.2, 0.1, 0.0, 0.8))
	# Bottom-Right
	draw_colored_polygon(PackedVector2Array([Vector2(W,H), Vector2(W,H-plate_size), Vector2(W-plate_size*0.6,H-plate_size*0.6), Vector2(W-plate_size,H)]), brass_col)
	draw_circle(Vector2(W-plate_size*0.35, H-plate_size*0.35), 2.0, Color(0.2, 0.1, 0.0, 0.8))

func _draw_bridge(bx: float, cy: float, rh: float) -> void:
	var bw := 16.0
	var bh := rh * 0.72
	var top_y := cy - bh * 0.45
	var bot_y := cy + bh * 0.55
	
	# Inverted V / A-shaped bridge points
	var left_leg := Vector2(bx - bw * 0.5, bot_y)
	var right_leg := Vector2(bx + bw * 0.5, bot_y)
	var apex := Vector2(bx, top_y)
	
	# Draw legs/triangles for A-shape
	var poly := PackedVector2Array([
		left_leg,
		Vector2(bx - 2.0, top_y + 3.0),
		Vector2(bx + 2.0, top_y + 3.0),
		right_leg,
		Vector2(bx + bw * 0.2, bot_y),
		Vector2(bx, top_y + 8.0),
		Vector2(bx - bw * 0.2, bot_y)
	])
	draw_colored_polygon(poly, Color(0.36, 0.18, 0.05)) # dark mahogany wood
	
	# Draw outline for 3D depth
	draw_polyline(PackedVector2Array([left_leg, apex, right_leg]), Color(0.18, 0.08, 0.02), 2.0, true)
	
	# White/cream bone saddle cap on top of the nhạn đàn
	draw_circle(apex, 3.2, Color(0.95, 0.93, 0.88)) # bone saddle cap
	draw_circle(apex, 1.5, Color(0.77, 0.58, 0.15)) # gold guide pin

# ─── Input helpers ────────────────────────────────────────────────────────────
func _row_h() -> float:
	var ih := size.y - 16.0
	if ih <= 0.0:
		return 20.0
	return ih / float(STR_COUNT)

func _row_at(pos: Vector2) -> int:
	var ih := size.y - 16.0
	if ih <= 0.0:
		return -1
	var rel_y := pos.y - 8.0
	if rel_y < 0.0 or rel_y >= ih:
		return -1
	return clamp(int(rel_y / (ih / float(STR_COUNT))), 0, STR_COUNT - 1)

func _row_cy(idx: int) -> float:
	var rh := _row_h()
	return 8.0 + float(idx) * rh + rh * 0.5

# ─── GUI Input ────────────────────────────────────────────────────────────────
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var ev := event as InputEventMouseButton
		if ev.button_index == MOUSE_BUTTON_LEFT:
			if ev.pressed:
				_handle_touch_start(-1, ev.position)
			else:
				_handle_touch_end(-1)
	elif event is InputEventMouseMotion:
		var ev := event as InputEventMouseMotion
		var new_hov := _row_at(ev.position)
		if new_hov != _hovered_idx:
			_hovered_idx = new_hov
			queue_redraw()
		_handle_touch_move(-1, ev.position)
	elif event is InputEventScreenTouch:
		var ev := event as InputEventScreenTouch
		if ev.pressed:
			_handle_touch_start(ev.index, ev.position)
		else:
			_handle_touch_end(ev.index)
	elif event is InputEventScreenDrag:
		var ev := event as InputEventScreenDrag
		_handle_touch_move(ev.index, ev.position)

func _handle_touch_start(finger_idx: int, pos: Vector2) -> void:
	if _is_pressed.size() < STR_COUNT: return
	var idx := _row_at(pos)
	if idx < 0: return

	var W        := size.x
	var iw       := W - 24.0
	var str_l    := 12.0 + iw * 0.075
	var bridge_x := 12.0 + iw * 0.695
	var str_r    := 12.0 + iw * 0.945
	var rh       := _row_h()
	var cy       := _row_cy(idx)

	var interaction := "none"
	if pos.x >= bridge_x - 10.0 and pos.x <= str_r + 10.0:
		interaction = "pluck"
		pluck(idx)
	elif pos.x >= str_l - 5.0 and pos.x < bridge_x:
		interaction = "press"
		_is_pressed[idx] = 1
		_press_x[idx] = clamp(pos.x, str_l + 5.0, bridge_x - 5.0)
		_press_y[idx] = clamp(pos.y, cy, cy + rh * 0.48)
		_update_press(idx)
		queue_redraw()

	_active_touches[finger_idx] = {
		"last_string_idx": idx,
		"interaction_type": interaction
	}

func _handle_touch_move(finger_idx: int, pos: Vector2) -> void:
	if not _active_touches.has(finger_idx): return
	var touch_info = _active_touches[finger_idx]
	var idx := _row_at(pos)
	if idx < 0: return

	var W        := size.x
	var iw       := W - 24.0
	var str_l    := 12.0 + iw * 0.075
	var bridge_x := 12.0 + iw * 0.695
	var str_r    := 12.0 + iw * 0.945
	var rh       := _row_h()
	var cy       := _row_cy(idx)

	if touch_info["interaction_type"] == "pluck":
		# String crossing check for glissando / swipe
		if idx != touch_info["last_string_idx"]:
			if pos.x >= bridge_x - 10.0 and pos.x <= str_r + 10.0:
				pluck(idx)
				touch_info["last_string_idx"] = idx
	elif touch_info["interaction_type"] == "press":
		# Move bending point
		_press_x[idx] = clamp(pos.x, str_l + 5.0, bridge_x - 5.0)
		_press_y[idx] = clamp(pos.y, cy, cy + rh * 0.48)
		_update_press(idx)
		queue_redraw()

func _handle_touch_end(finger_idx: int) -> void:
	if not _active_touches.has(finger_idx): return
	var touch_info = _active_touches[finger_idx]
	if touch_info["interaction_type"] == "press":
		var idx = touch_info["last_string_idx"]
		if idx >= 0 and idx < STR_COUNT:
			_is_pressed[idx] = 0
			_update_press(idx)
			queue_redraw()
	_active_touches.erase(finger_idx)

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_hovered_idx = -1
		if _is_pressed.size() >= STR_COUNT:
			for i in STR_COUNT:
				if _is_pressed[i]:
					_is_pressed[i] = 0
					_update_press(i)
		queue_redraw()

# ─── Audio ────────────────────────────────────────────────────────────────────
func _play_audio(idx: int, pitch: float) -> void:
	if idx >= _streams.size() or _streams[idx] == null:
		return
	var old = _audio_players[idx]
	if old != null and is_instance_valid(old):
		(old as AudioStreamPlayer).stop()
		old.queue_free()
	var pl := AudioStreamPlayer.new()
	pl.stream      = _streams[idx]
	pl.pitch_scale = pitch
	pl.volume_db   = 0.0
	pl.bus         = "Master"
	get_tree().current_scene.add_child(pl)
	pl.play()
	_audio_players[idx] = pl
	var t := get_tree().create_timer(3.5)
	t.timeout.connect(func() -> void:
		if is_instance_valid(pl):
			if _audio_players[idx] == pl:
				_audio_players[idx] = null
			pl.queue_free()
	)

func _get_pitch_scale(idx: int) -> float:
	if not _is_pressed[idx]:
		return 1.0
	var cy    := _row_cy(idx)
	var max_b := _row_h() * 0.48
	var bend  := clampf((_press_y[idx] - cy) / max_b, 0.0, 1.0)
	
	var vibrato := 0.0
	if bend > 0.05:
		vibrato = sin(Time.get_ticks_msec() * 0.041) * 0.015 * bend
		
	return 1.0 + bend * 0.12246 + vibrato

func _update_press(idx: int) -> void:
	var scale := _get_pitch_scale(idx)
	var p_ref  = _audio_players[idx]
	if p_ref != null and is_instance_valid(p_ref):
		var player := p_ref as AudioStreamPlayer
		if player.playing:
			player.pitch_scale = scale
	string_pressed.emit(idx, (scale - 1.0) * 1630.0)
