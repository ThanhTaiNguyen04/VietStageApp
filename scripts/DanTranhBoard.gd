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
	if need:
		queue_redraw()

# ─── Draw ─────────────────────────────────────────────────────────────────────
func _draw() -> void:
	var W := size.x
	var H := size.y
	if W < 16.0 or H < 16.0:
		return

	# Board body background (no PanelContainer parent providing this any more)
	draw_rect(Rect2(0.0, 0.0, W, H), Color(0.14, 0.075, 0.030))

	if _note_names.is_empty():
		return

	# Outer wooden frame
	draw_rect(Rect2(0.0,      0.0,     W,    8.0),  Color(0.52, 0.30, 0.08))
	draw_rect(Rect2(0.0,      H - 8.0, W,    8.0),  Color(0.52, 0.30, 0.08))
	draw_rect(Rect2(0.0,      0.0,     12.0, H),     Color(0.42, 0.24, 0.06))
	draw_rect(Rect2(W - 12.0, 0.0,     12.0, H),     Color(0.42, 0.24, 0.06))

	var ix    := 12.0
	var iy    := 8.0
	var iw    := W - 24.0
	var ih    := H - 16.0
	var rh    := ih / float(STR_COUNT)

	var str_l    := ix + iw * 0.075
	var bridge_x := ix + iw * 0.695
	var str_r    := ix + iw * 0.945
	var lbl_x    := ix + 6.0

	# Try to get default font for labels
	var font : Font = null
	var dtheme := ThemeDB.get_default_theme()
	if dtheme != null:
		font = dtheme.get_default_font()

	for i in STR_COUNT:
		var ry := iy + float(i) * rh
		var cy := ry + rh * 0.5

		# ── Row background ────────────────────────────────────────────────────
		var bg_col := Color(0.155, 0.088, 0.042) if (i % 2 == 0) else Color(0.205, 0.118, 0.058)
		draw_rect(Rect2(ix, ry, iw, rh), bg_col)

		# Hover tint
		if _hovered_idx == i:
			draw_rect(Rect2(ix, ry, iw, rh), Color(1.0, 0.9, 0.5, 0.07))

		# Target pulse (unique variable name: pulse_tint)
		if _is_target[i]:
			var pulse_tint := (sin(_pulse_phase[i]) + 1.0) * 0.5
			draw_rect(Rect2(ix, ry, iw, rh), Color(0.98, 0.82, 0.20, 0.06 + pulse_tint * 0.07))

		# Row separator
		draw_line(
			Vector2(ix, ry + rh - 0.5), Vector2(ix + iw, ry + rh - 0.5),
			Color(0.0, 0.0, 0.0, 0.5), 1.0
		)

		# ── Bridge (nhạn đàn) ─────────────────────────────────────────────────
		_draw_bridge(bridge_x, cy, rh)

		# ── String line ───────────────────────────────────────────────────────
		var tc       := float(i) / float(STR_COUNT - 1)
		var str_r_ch := lerpf(0.92, 0.78, tc)
		var str_g_ch := lerpf(0.70, 0.82, tc)
		var str_b_ch := lerpf(0.25, 0.80, tc)
		var base_col := Color(str_r_ch, str_g_ch, str_b_ch, 1.0)

		# Target pulse tint on string colour (unique: pulse_col)
		var str_col := base_col
		if _pluck_amp[i] > 0.05:
			str_col = Color(1.00, 0.92, 0.60).lerp(base_col, 1.0 - _pluck_amp[i])
		elif _is_pressed[i]:
			str_col = Color(1.00, 0.55, 0.15)
		elif _is_target[i]:
			var pulse_col := (sin(_pulse_phase[i]) + 1.0) * 0.5
			str_col = base_col.lerp(Color(0.98, 0.82, 0.20), 0.3 + pulse_col * 0.25)

		var sw := lerpf(2.8, 1.2, tc)

		# Build vibrating polyline
		var pts := PackedVector2Array()
		pts.append(Vector2(str_l, cy))
		if _is_pressed[i] and _press_x[i] > str_l and _press_x[i] < bridge_x:
			pts.append(Vector2(_press_x[i], _press_y[i]))
		pts.append(Vector2(bridge_x, cy))
		if _pluck_amp[i] > 0.005:
			var freq := _freqs[i] if i < _freqs.size() else 130.0
			var spd  := 55.0 + freq * 0.12
			for k in range(1, 11):
				var ratio := float(k) / 10.0
				var osc   := sin(ratio * PI) * sin(ratio * PI * 2.0 - _pluck_time[i] * spd) * _pluck_amp[i] * 4.5
				pts.append(Vector2(lerpf(bridge_x, str_r, ratio), cy + osc))
		pts.append(Vector2(str_r, cy))

		# Shadow
		var shad := PackedVector2Array()
		for k in pts.size():
			shad.append(pts[k] + Vector2(0.0, sw * 0.6))
		draw_polyline(shad, Color(0.0, 0.0, 0.0, 0.20), sw * 0.5, true)

		# Main string
		draw_polyline(pts, str_col, sw, true)

		# Highlight stripe
		var hilit := PackedVector2Array()
		for k in pts.size():
			hilit.append(pts[k] + Vector2(0.0, -sw * 0.25))
		draw_polyline(hilit, Color(1.0, 1.0, 1.0, 0.20 * (1.0 - tc * 0.5)), sw * 0.35, true)

		# Target glow on string (unique: pulse_glow)
		if _is_target[i]:
			var pulse_glow := (sin(_pulse_phase[i]) + 1.0) * 0.5
			draw_polyline(pts, Color(0.98, 0.82, 0.20, 0.30 + pulse_glow * 0.22), sw + 5.0, true)

		# Pluck glow
		if _glow_alpha[i] > 0.01:
			draw_polyline(pts, Color(1.00, 0.92, 0.60, _glow_alpha[i] * 0.35), sw + 7.0,  true)
			draw_polyline(pts, Color(1.00, 0.95, 0.70, _glow_alpha[i] * 0.16), sw + 14.0, true)

		# ── Labels ────────────────────────────────────────────────────────────
		if font != null:
			var num_alpha := 0.55 + _glow_alpha[i] * 0.45
			draw_string(font, Vector2(lbl_x, cy + 5.0),
				str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
				Color(0.95, 0.72, 0.18, num_alpha))
			var name_col := Color(0.98, 0.82, 0.20) if _is_target[i] else Color(0.95, 0.72, 0.18)
			draw_string(font, Vector2(str_r + 5.0, cy + 5.0),
				_note_names[i % _note_names.size()],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
				Color(name_col.r, name_col.g, name_col.b, 0.90))

		# Press indicator
		if _is_pressed[i]:
			draw_circle(Vector2(_press_x[i], _press_y[i]), 5.5, Color(0.95, 0.25, 0.10, 0.85))
			draw_circle(Vector2(_press_x[i], _press_y[i]), 3.0, Color(1.00, 0.70, 0.40, 0.90))

func _draw_bridge(bx: float, cy: float, rh: float) -> void:
	var bw := 12.0
	var bh := rh * 0.65
	var top_y := cy - bh * 0.30
	var bot_y := cy + bh * 0.70
	# Main body
	draw_rect(Rect2(bx - bw * 0.35, top_y, bw * 0.70, bot_y - top_y), Color(0.50, 0.28, 0.08))
	# Saddle top cap
	draw_rect(Rect2(bx - bw * 0.22, top_y - 2.0, bw * 0.44, 4.5), Color(0.94, 0.91, 0.84))
	# Highlight edge
	draw_line(Vector2(bx - bw * 0.35, top_y), Vector2(bx - bw * 0.35, bot_y), Color(0.75, 0.50, 0.18, 0.55), 1.5)

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
	if _is_pressed.size() < STR_COUNT:
		return
	var W        := size.x
	var iw       := W - 24.0
	var str_l    := 12.0 + iw * 0.075
	var bridge_x := 12.0 + iw * 0.695
	var str_r    := 12.0 + iw * 0.945
	var rh       := _row_h()

	if event is InputEventMouseButton:
		var ev  := event as InputEventMouseButton
		var idx := _row_at(ev.position)
		if idx < 0:
			return
		var cy := _row_cy(idx)
		if ev.button_index == MOUSE_BUTTON_LEFT:
			if ev.pressed:
				if ev.position.x >= bridge_x - 10.0 and ev.position.x <= str_r + 10.0:
					pluck(idx)
				elif ev.position.x >= str_l - 5.0 and ev.position.x < bridge_x:
					_is_pressed[idx] = 1
					_press_x[idx] = clamp(ev.position.x, str_l + 5.0, bridge_x - 5.0)
					_press_y[idx] = clamp(ev.position.y, cy, cy + rh * 0.48)
					_update_press(idx)
					queue_redraw()
			else:
				if _is_pressed[idx]:
					_is_pressed[idx] = 0
					_update_press(idx)
					queue_redraw()

	elif event is InputEventMouseMotion:
		var ev      := event as InputEventMouseMotion
		var new_hov := _row_at(ev.position)
		if new_hov != _hovered_idx:
			_hovered_idx = new_hov
			queue_redraw()
		if new_hov >= 0 and _is_pressed[new_hov]:
			var cy := _row_cy(new_hov)
			_press_x[new_hov] = clamp(ev.position.x, str_l + 5.0, bridge_x - 5.0)
			_press_y[new_hov] = clamp(ev.position.y, cy, cy + rh * 0.48)
			_update_press(new_hov)

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
			pl.queue_free()
	)

func _get_pitch_scale(idx: int) -> float:
	if not _is_pressed[idx]:
		return 1.0
	var cy    := _row_cy(idx)
	var max_b := _row_h() * 0.48
	var bend  := clampf((_press_y[idx] - cy) / max_b, 0.0, 1.0)
	return 1.0 + bend * 0.12246

func _update_press(idx: int) -> void:
	var scale := _get_pitch_scale(idx)
	var p_ref  = _audio_players[idx]
	if p_ref != null and is_instance_valid(p_ref):
		var player := p_ref as AudioStreamPlayer
		if player.playing:
			create_tween().tween_property(p_ref, "pitch_scale", scale, 0.04)
	string_pressed.emit(idx, (scale - 1.0) * 1630.0)
