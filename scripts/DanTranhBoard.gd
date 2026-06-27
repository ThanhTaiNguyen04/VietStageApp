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
var audio_enabled := true
var _hovered_idx : int                = -1
var _active_touches : Dictionary      = {}

# ─── Notes on strings properties ──────────────────────────────────────────────
var sheet_notes        : Array = []
var sheet_durations    : Array = []
var note_statuses      : Array = []
var current_note_idx   : int   = 0
var current_time_beats : float = 0.0
var is_active          : bool  = false


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
	if audio_enabled:
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
func get_bridge_x(idx: int) -> float:
	var W := size.x
	var ix := 24.0
	var iw := W - 60.0
	var t := float(idx) / float(STR_COUNT - 1)
	# Beautiful S-curve representing real Đàn Tranh nhạn arrangement
	var smooth_t := t * t * (3.0 - 2.0 * t)
	var start_pct := 0.26
	var end_pct := 0.82
	var pct := lerpf(start_pct, end_pct, smooth_t)
	return ix + iw * pct

func get_str_l(idx: int) -> float:
	var W := size.x
	var ix := 24.0
	var iw := W - 60.0
	var t := float(idx) / float(STR_COUNT - 1)
	# Curved left bridge shape from reference image: C-shape bulge to the right
	var pct := 0.14 - 0.06 * t + 0.15 * sin(t * PI)
	return ix + iw * pct

func _draw_inlay_pattern(rect: Rect2, color: Color) -> void:
	var cx := rect.position.x + rect.size.x * 0.5
	var step_y := rect.size.y / 8.0
	for j in range(1, 8):
		var y := rect.position.y + j * step_y
		# Draw a small diamond
		var pts := PackedVector2Array([
			Vector2(cx, y - 4.0),
			Vector2(cx + 3.0, y),
			Vector2(cx, y + 4.0),
			Vector2(cx - 3.0, y)
		])
		draw_colored_polygon(pts, color)
		# Draw tiny leaves
		draw_circle(Vector2(cx - 5.0, y - 2.0), 1.5, color)
		draw_circle(Vector2(cx + 5.0, y + 2.0), 1.5, color)

func _draw_key_fret_pattern(x: float, y_start: float, y_end: float, color: Color) -> void:
	var pts := PackedVector2Array()
	var step := 18.0
	var y := y_start
	var left := true
	while y < y_end:
		pts.append(Vector2(x, y))
		pts.append(Vector2(x + (3.0 if left else -3.0), y))
		pts.append(Vector2(x + (3.0 if left else -3.0), y + step * 0.5))
		pts.append(Vector2(x, y + step * 0.5))
		y += step
		left = not left
	if pts.size() >= 2:
		draw_polyline(pts, color, 1.0)

func _draw_cloud_carving(center: Vector2, size_val: float, color: Color) -> void:
	var points := PackedVector2Array()
	for step in range(30):
		var t := float(step) / 29.0
		var angle := t * 3.0 * PI
		var rad := size_val * (1.0 - t * 0.8)
		var offset := Vector2(cos(angle), sin(angle) * 0.7) * rad
		points.append(center + offset)
	draw_polyline(points, color, 1.2, true)
	
	var tail_pts := PackedVector2Array([
		center + Vector2(-size_val * 0.5, 0.0),
		center + Vector2(-size_val * 1.2, size_val * 0.3),
		center + Vector2(-size_val * 1.8, size_val * 0.1),
		center + Vector2(-size_val * 2.2, size_val * 0.6),
		center + Vector2(-size_val * 2.5, size_val * 0.5)
	])
	draw_polyline(tail_pts, color, 1.0, true)

func _draw_mop_flower(pos: Vector2, r: float, color: Color) -> void:
	# Draw a delicate 4-petal flower simulating mother-of-pearl inlay
	draw_circle(pos + Vector2(-r, 0.0), r, color)
	draw_circle(pos + Vector2(r, 0.0), r, color)
	draw_circle(pos + Vector2(0.0, -r), r, color)
	draw_circle(pos + Vector2(0.0, r), r, color)
	draw_circle(pos, r * 0.6, Color(0.95, 0.82, 0.45)) # gold center


func _draw() -> void:
	var W := size.x
	var H := size.y
	print("DEBUG_DRAW: W=", W, " H=", H, " note_count=", _note_names.size())
	if W < 16.0 or H < 16.0:
		return

	if _note_names.is_empty():
		return

	# 1. Base zither body shadow & background (Dark Rosewood)
	var base_sb := StyleBoxFlat.new()
	base_sb.bg_color = Color(0.28, 0.13, 0.03)
	base_sb.set_corner_radius_all(14)
	base_sb.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	base_sb.shadow_size = 8
	base_sb.shadow_offset = Vector2(0, 4)
	base_sb.border_width_left = 6
	base_sb.border_width_right = 6
	base_sb.border_color = Color(0.34, 0.16, 0.04)
	draw_style_box(base_sb, Rect2(0.0, 0.0, W, H))

	var ix    := 24.0
	var iy    := 10.0
	var iw    := W - 60.0
	var ih    := H - 20.0
	var rh    := ih / float(STR_COUNT)
	var str_r    := W - 24.0

	# 2. Soundboard row backgrounds and S-curve wavy wood grain
	for i in STR_COUNT:
		var ry := iy + float(i) * rh
		var cy := ry + rh * 0.5
		
		# Curved soundboard starts at get_str_l(i) + 8.0 and ends at W - 24.0
		var row_l := get_str_l(i) + 8.0
		var row_w := str_r - row_l
		
		var center_t := float(i) / float(STR_COUNT - 1)
		var curvature_light := sin(center_t * PI)
		var wood_glow := Color(0.28, 0.15, 0.07)
		var base_bg := Color(0.13, 0.06, 0.02) if (i % 2 == 0) else Color(0.17, 0.08, 0.03)
		var bg_col := base_bg.lerp(wood_glow, curvature_light * 0.38)
		
		# Cylindrical simulation gradient (3 sub-strips per row) for realistic 3D convex shape
		var h_top := rh * 0.25
		var h_mid := rh * 0.50
		var h_bot := rh * 0.25
		var col_edge := bg_col.darkened(0.14)
		var col_mid  := bg_col.lightened(0.06)
		
		draw_rect(Rect2(row_l, ry, row_w, h_top), col_edge)
		draw_rect(Rect2(row_l, ry + h_top, row_w, h_mid), col_mid)
		draw_rect(Rect2(row_l, ry + h_top + h_mid, row_w, h_bot), col_edge)
		
		# Soft lacquer sheen line horizontally across the middle of each row
		draw_line(Vector2(row_l, cy), Vector2(str_r, cy), Color(1.0, 1.0, 1.0, 0.02), 3.0)

		# S-curve wavy wood grain (3 flow lines per row for natural texture)
		for g in range(3):
			var gy_base = ry + rh * (0.2 + g * 0.3)
			var grain_pts := PackedVector2Array()
			var steps := 16
			for step in range(steps + 1):
				var ratio := float(step) / float(steps)
				# Elegant S-curve wave function
				var t_wave := ratio * PI * 2.0
				var wave := (sin(t_wave) * 0.45 + cos(t_wave * 0.5) * 0.3) * (rh * 0.22)
				grain_pts.append(Vector2(row_l + row_w * ratio, gy_base + wave))
			
			var grain_col := Color(0.08, 0.04, 0.01, 0.15) if g % 2 == 0 else Color(0.24, 0.15, 0.08, 0.08)
			draw_polyline(grain_pts, grain_col, 1.1)

		# Hover indicator
		if _hovered_idx == i:
			draw_rect(Rect2(row_l, ry, row_w, rh), Color(1.0, 0.88, 0.45, 0.05))

		# Target highlight pulse
		if _is_target[i]:
			var pulse_tint := (sin(_pulse_phase[i]) + 1.0) * 0.5
			draw_rect(Rect2(row_l, ry, row_w, rh), Color(0.95, 0.72, 0.18, 0.05 + pulse_tint * 0.05))

		# Row boundary line
		draw_line(Vector2(row_l, ry + rh - 0.5), Vector2(str_r, ry + rh - 0.5), Color(0.08, 0.04, 0.02, 0.55), 1.0)

	# 3. Top and Bottom frames overlay
	var board_sb := StyleBoxFlat.new()
	board_sb.bg_color = Color(0, 0, 0, 0)
	board_sb.border_width_top = 8
	board_sb.border_width_bottom = 8
	board_sb.border_color = Color(0.32, 0.15, 0.04)
	draw_style_box(board_sb, Rect2(24.0, 0.0, W - 48.0, H))
	
	# Gold accent frame lines
	draw_line(Vector2(24.0, 10.0), Vector2(W - 24.0, 10.0), Color(0.77, 0.58, 0.15, 0.38), 1.0)
	draw_line(Vector2(24.0, H - 10.0), Vector2(W - 24.0, H - 10.0), Color(0.77, 0.58, 0.15, 0.38), 1.0)

	# 4. Draw the curved divider frame (nhạn đầu)
	var div_pts := PackedVector2Array()
	for i in STR_COUNT:
		var ry := iy + float(i) * rh
		var cy := ry + rh * 0.5
		div_pts.append(Vector2(get_str_l(i) + 8.0, cy))
	# Draw divider shadow
	var div_pts_shadow := PackedVector2Array()
	for p in div_pts:
		div_pts_shadow.append(p + Vector2(2.5, 0.0))
	draw_polyline(div_pts_shadow, Color(0.06, 0.03, 0.01, 0.65), 7.0, true)
	# Draw main divider wood
	draw_polyline(div_pts, Color(0.30, 0.12, 0.03), 6.0, true)
	# Draw gold highlight line
	draw_polyline(div_pts, Color(0.77, 0.58, 0.15, 0.65), 1.6, true)

	# 5. Draw right-end curved tail cap / frame
	var tail_sb := StyleBoxFlat.new()
	tail_sb.bg_color = Color(0.12, 0.06, 0.02) # dark premium rosewood
	tail_sb.set_corner_radius_all(8)
	tail_sb.border_width_left = 2
	tail_sb.border_width_right = 2
	tail_sb.border_width_top = 2
	tail_sb.border_width_bottom = 2
	tail_sb.border_color = Color(0.77, 0.58, 0.15) # gold border
	tail_sb.shadow_color = Color(0.0, 0.0, 0.0, 0.4)
	tail_sb.shadow_size = 4
	tail_sb.shadow_offset = Vector2(1, 1)
	
	# Draw right tail cap block from W - 28.0 to W - 6.0
	var tail_rect := Rect2(W - 28.0, 12.0, 22.0, H - 24.0)
	draw_style_box(tail_sb, tail_rect)
	
	# Draw inner thin gold highlight line inside right tail cap
	var tail_inner_pts := PackedVector2Array([
		Vector2(tail_rect.position.x + 3.0, tail_rect.position.y + 3.0),
		Vector2(tail_rect.end.x - 3.0, tail_rect.position.y + 3.0),
		Vector2(tail_rect.end.x - 3.0, tail_rect.end.y - 3.0),
		Vector2(tail_rect.position.x + 3.0, tail_rect.end.y - 3.0),
		Vector2(tail_rect.position.x + 3.0, tail_rect.position.y + 3.0)
	])
	draw_polyline(tail_inner_pts, Color(0.77, 0.58, 0.15, 0.4), 1.0)
	
	# Draw mother-of-pearl inlay inside right tail cap
	var mop_color := Color(0.85, 0.92, 0.95, 0.8)
	_draw_inlay_pattern(Rect2(W - 26.0, 18.0, 18.0, H - 36.0), mop_color)

	# 6. Draw Left Controls Panel (Lacquered black wood & MOP inlays)
	var panel_sb := StyleBoxFlat.new()
	panel_sb.bg_color = Color(0.04, 0.03, 0.02, 0.96) # deep black lacquer
	panel_sb.set_corner_radius_all(12)
	panel_sb.border_width_left = 2
	panel_sb.border_width_right = 2
	panel_sb.border_width_top = 2
	panel_sb.border_width_bottom = 2
	panel_sb.border_color = Color(0.77, 0.58, 0.15, 0.8) # gold border
	panel_sb.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	panel_sb.shadow_size = 6
	panel_sb.shadow_offset = Vector2(2, 2)
	draw_style_box(panel_sb, Rect2(16.0, 20.0, 64.0, H - 40.0))
	
	# Draw inner thin gold frame line
	var inner_rect := Rect2(20.0, 24.0, 56.0, H - 48.0)
	var inner_pts := PackedVector2Array([
		inner_rect.position,
		Vector2(inner_rect.end.x, inner_rect.position.y),
		inner_rect.end,
		Vector2(inner_rect.position.x, inner_rect.end.y),
		inner_rect.position
	])
	draw_polyline(inner_pts, Color(0.77, 0.58, 0.15, 0.35), 1.0)

	# Draw mother-of-pearl inlays in corners of the panel
	var mop_col1 := Color(0.85, 0.92, 0.95, 0.75) # cyan-white MOP
	var mop_col2 := Color(0.95, 0.85, 0.90, 0.75) # pink-white MOP
	_draw_mop_flower(Vector2(26.0, 30.0), 1.6, mop_col1)
	_draw_mop_flower(Vector2(70.0, 30.0), 1.6, mop_col2)
	_draw_mop_flower(Vector2(26.0, H - 30.0), 1.6, mop_col2)
	_draw_mop_flower(Vector2(70.0, H - 30.0), 1.6, mop_col1)
	
	# Vector Icons inside Panel
	var px := 16.0 + 32.0
	var py_start := 20.0 + 30.0
	var py_step := (H - 100.0) / 5.0
	
	# Menu icon (three lines)
	var my := py_start
	draw_line(Vector2(px - 10.0, my - 4.0), Vector2(px + 10.0, my - 4.0), Color(0.95, 0.82, 0.45), 1.5)
	draw_line(Vector2(px - 10.0, my), Vector2(px + 10.0, my), Color(0.95, 0.82, 0.45), 1.5)
	draw_line(Vector2(px - 10.0, my + 4.0), Vector2(px + 10.0, my + 4.0), Color(0.95, 0.82, 0.45), 1.5)
	
	# Zoom icon
	var zy := py_start + py_step
	draw_circle(Vector2(px - 2.0, zy - 2.0), 5.0, Color(0.95, 0.82, 0.45), false, 1.2)
	draw_line(Vector2(px + 1.0, zy + 1.0), Vector2(px + 8.0, zy + 8.0), Color(0.95, 0.82, 0.45), 1.5)
	draw_line(Vector2(px - 4.0, zy - 2.0), Vector2(px, zy - 2.0), Color(0.95, 0.82, 0.45), 1.0)
	draw_line(Vector2(px - 2.0, zy - 4.0), Vector2(px - 2.0, zy), Color(0.95, 0.82, 0.45), 1.0)
	
	# Record icon (red dot with gold border)
	var ry_rec := py_start + 2.0 * py_step
	draw_circle(Vector2(px, ry_rec), 10.0, Color(0.72, 0.54, 0.18, 0.5), false, 1.2)
	draw_circle(Vector2(px, ry_rec), 6.0, Color(0.90, 0.15, 0.10))
	
	# Loop icon
	var ly_loop := py_start + 3.0 * py_step
	draw_circle(Vector2(px, ly_loop), 10.0, Color(0.72, 0.54, 0.18, 0.5), false, 1.2)
	var loop_color := Color(0.95, 0.82, 0.45)
	var arc_points := PackedVector2Array()
	for step in range(12):
		var angle := float(step) * (1.6 * PI / 11.0) - PI * 0.3
		arc_points.append(Vector2(px, ly_loop) + Vector2(cos(angle), sin(angle)) * 5.5)
	draw_polyline(arc_points, loop_color, 1.2)
	draw_line(Vector2(px + 4.0, ly_loop - 4.0), Vector2(px + 1.0, ly_loop - 1.0), loop_color, 1.2)
	draw_line(Vector2(px + 4.0, ly_loop - 4.0), Vector2(px + 6.0, ly_loop - 1.0), loop_color, 1.2)
	
	# Play mode button
	var py_play := py_start + 4.0 * py_step
	draw_circle(Vector2(px, py_play), 10.0, Color(0.95, 0.82, 0.45), false, 1.5)
	draw_circle(Vector2(px, py_play), 4.0, Color(0.95, 0.82, 0.45))

	# 7. Subtle wood carvings in soundboard background
	var carve_dark := Color(0.08, 0.04, 0.02, 0.28)
	var carve_gold := Color(0.72, 0.54, 0.18, 0.15)
	_draw_key_fret_pattern(W - 32.0, 15.0, H - 15.0, carve_dark)
	_draw_cloud_carving(Vector2(ix + iw * 0.78, 48.0), 12.0, carve_gold)
	_draw_cloud_carving(Vector2(ix + iw * 0.84, 76.0), 10.0, carve_dark)

	var font : Font = null
	var dtheme := ThemeDB.get_default_theme()
	if dtheme != null:
		font = dtheme.get_default_font()

	for i in STR_COUNT:
		var ry := iy + float(i) * rh
		var cy := ry + rh * 0.5
		var str_l := get_str_l(i)

		# Draw gold rivet peg on Left curve (with shiny 3D specular highlight)
		draw_circle(Vector2(str_l, cy), 3.5, Color(0.77, 0.58, 0.15)) # gold ring
		draw_circle(Vector2(str_l, cy), 1.5, Color(0.12, 0.08, 0.05)) # dark center
		draw_circle(Vector2(str_l - 1.0, cy - 1.0), 0.7, Color(1.0, 1.0, 1.0, 0.85)) # shiny reflection
		
		# Draw brass rivet on the Right end block (with shiny 3D specular highlight)
		draw_circle(Vector2(str_r, cy), 3.5, Color(0.75, 0.55, 0.15)) # gold ring
		draw_circle(Vector2(str_r, cy), 1.5, Color(0.08, 0.04, 0.02)) # inner hole
		draw_circle(Vector2(str_r - 1.0, cy - 1.0), 0.7, Color(1.0, 1.0, 1.0, 0.85)) # shiny reflection

		# Get dynamic bridge X position
		var bridge_x := get_bridge_x(i)

		# ── Inverted-V Traditional Bridge (Nhạn đàn) ──
		_draw_bridge(bridge_x, cy, rh)

		# ── Premium vibrating string lines ──
		var tc       := float(i) / float(STR_COUNT - 1)
		
		# String coloring matches zither image: 4, 10, 15 are turquoise, others silver/gold
		var base_col := Color(0.92, 0.72, 0.22).lerp(Color(0.85, 0.88, 0.92), tc)
		if i == 3 or i == 9 or i == 14:
			base_col = Color(0.05, 0.75, 0.55) # turquoise string

		var str_col := base_col
		if _pluck_amp[i] > 0.05:
			str_col = Color(1.00, 0.94, 0.75).lerp(base_col, 1.0 - _pluck_amp[i])
		elif _is_pressed[i]:
			str_col = Color(0.98, 0.42, 0.12) # orange bend highlight
		elif _is_target[i]:
			var pulse_col := (sin(_pulse_phase[i]) + 1.0) * 0.5
			str_col = base_col.lerp(Color(0.95, 0.72, 0.18), 0.25 + pulse_col * 0.25)

		var sw := lerpf(4.0, 1.8, tc)

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

		# Draw soft string drop shadow (floating higher above board)
		var shad := PackedVector2Array()
		for k in pts.size():
			shad.append(pts[k] + Vector2(-1.0, sw * 1.5 + 4.5))
		draw_polyline(shad, Color(0.0, 0.0, 0.0, 0.32), sw * 1.2, true)

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

		# Draw blue protective sleeve wrapping at Left end
		draw_line(Vector2(str_l, cy), Vector2(str_l + 12.0, cy), Color(0.1, 0.5, 0.9), sw + 1.0)

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


		# ── Pluck Target Ring & Scrolling Notes ──
		var trigger_x: float = bridge_x + 0.25 * (str_r - bridge_x)
		
		# Pluck target ring: glowing golden ring
		var ring_col := Color(0.77, 0.58, 0.15, 0.35)
		if _is_target[i]:
			var pulse := (sin(_pulse_phase[i]) + 1.0) * 0.5
			ring_col = Color(0.95, 0.72, 0.18, 0.5 + pulse * 0.4)
		draw_circle(Vector2(trigger_x, cy), 9.0, ring_col, false, 1.5)
		draw_circle(Vector2(trigger_x, cy), 4.0, Color(ring_col.r, ring_col.g, ring_col.b, ring_col.a * 0.3))
		
		# Draw scrolling notes on this string
		if is_active and not sheet_notes.is_empty():
			var PIXELS_PER_BEAT: float = 120.0
			var note_time: float = 0.0
			for k in range(sheet_notes.size()):
				var note_name = sheet_notes[k]
				var duration = sheet_durations[k] if k < sheet_durations.size() else 1.0
				
				var is_rest: bool = note_name == "Rest" or note_name == "-" or note_name == "nghỉ"
				if is_rest:
					note_time += duration
					continue
					
				var target_str_idx: int = _note_names.find(note_name)
				if target_str_idx != i:
					note_time += duration
					continue
					
				# Note X position (starts at right, scrolls to left)
				var note_x: float = trigger_x + (note_time - current_time_beats) * PIXELS_PER_BEAT
				
				# Only draw if it's visible in the playable zither area
				if note_x >= bridge_x - 100.0 and note_x <= str_r + 200.0:
					var note_width: float = float(duration) * PIXELS_PER_BEAT * 0.85
					var cap_h: float = clampf(rh * 0.72, 12.0, 26.0)
					var cap_rect: Rect2 = Rect2(note_x, cy - cap_h * 0.5, note_width, cap_h)
					
					var cap_color: Color = Color(0.12, 0.43, 0.31, 0.6) # jade/teal future note
					var border_color: Color = Color(0.18, 0.60, 0.44, 0.8)
					
					if k == current_note_idx:
						var pulse: float = (sin(Time.get_ticks_msec() * 0.008) + 1.0) * 0.5
						cap_color = Color(0.95, 0.72, 0.18, 0.85 + pulse * 0.1) # glowing gold
						border_color = Color(1.0, 0.92, 0.60, 0.95)
					elif k < current_note_idx:
						var status = note_statuses[k] if k < note_statuses.size() else "unplayed"
						if status == "correct":
							cap_color = Color(0.15, 0.68, 0.37, 0.7) # emerald green
							border_color = Color(0.18, 0.80, 0.44, 0.9)
						elif status == "missed":
							cap_color = Color(0.75, 0.22, 0.17, 0.5) # muted ruby red
							border_color = Color(0.90, 0.30, 0.25, 0.75)
						else:
							cap_color = Color(0.4, 0.4, 0.4, 0.45) # grey
							border_color = Color(0.55, 0.55, 0.55, 0.6)
							
					var cap_sb: StyleBoxFlat = StyleBoxFlat.new()
					cap_sb.bg_color = cap_color
					cap_sb.border_color = border_color
					cap_sb.border_width_left = 1; cap_sb.border_width_right = 1
					cap_sb.border_width_top = 1; cap_sb.border_width_bottom = 1
					cap_sb.set_corner_radius_all(int(cap_h * 0.5))
					
					# Shadow
					cap_sb.shadow_color = Color(0.0, 0.0, 0.0, 0.3)
					cap_sb.shadow_size = 3
					cap_sb.shadow_offset = Vector2(1, 1)
					
					draw_style_box(cap_sb, cap_rect)
					
					# Draw note text inside capsule
					if note_width > 22.0 and font != null:
						var text_color: Color = Color.WHITE
						if k == current_note_idx:
							text_color = Color("#2e180d") # dark brown for active note readability
						var txt_size: int = clamp(int(cap_h * 0.6), 8, 11)
						var txt_y: float = cy + txt_size * 0.35
						var txt_x: float = note_x + 6.0
						draw_string(font, Vector2(txt_x, txt_y), note_name, HORIZONTAL_ALIGNMENT_LEFT, note_width - 12.0, txt_size, text_color)
						
				note_time += duration

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
			var lbl_x := clampf(str_l - 22.0, 84.0, W)
			
			# Draw String Number inside left board background
			draw_string(font, Vector2(lbl_x, cy + baseline_offset),
				str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, f_size,
				Color(0.95, 0.72, 0.18, num_alpha))
			
			# Draw Note Name centered inside Right block (W - 12.0)
			var name_col := Color(0.98, 0.82, 0.20) if _is_target[i] else Color(0.95, 0.72, 0.18)
			draw_string(font, Vector2(W - 12.0, cy + name_baseline_offset),
				_note_names[i % _note_names.size()],
				HORIZONTAL_ALIGNMENT_CENTER, -1, name_f_size,
				Color(name_col.r, name_col.g, name_col.b, 0.90))

		# Press touch marker
		if _is_pressed[i]:
			var max_b := _row_h() * 0.48
			var bend  := clampf((_press_y[i] - cy) / max_b, 0.0, 1.0)
			var visual_vibrato := sin(Time.get_ticks_msec() * 0.041) * 3.5 * bend
			var marker_y = _press_y[i] + visual_vibrato
			draw_circle(Vector2(_press_x[i], marker_y), 6.0, Color(0.95, 0.22, 0.08, 0.85))
			draw_circle(Vector2(_press_x[i], marker_y), 3.0, Color(1.00, 0.75, 0.35, 0.95))

func _draw_bridge(bx: float, cy: float, rh: float) -> void:
	var bw := 20.0
	var bh := clampf(rh * 0.90, 14.0, 42.0) # scale with row height but keep sensible limits
	var top_y := cy - bh * 0.45
	var bot_y := cy + bh * 0.55
	
	var left_foot := Vector2(bx - bw * 0.5, bot_y)
	var right_foot := Vector2(bx + bw * 0.5, bot_y)
	var apex := Vector2(bx, top_y)
	
	# ── 3D Drop Shadow for the bridge on the soundboard ──
	var sh_off := Vector2(rh * 0.22, rh * 0.16)
	var shadow_l := left_foot + sh_off
	var shadow_r := right_foot + sh_off
	var shadow_apex := apex + sh_off
	
	var poly_shadow := PackedVector2Array([
		shadow_l,
		Vector2(bx + sh_off.x - bw * 0.2, bot_y + sh_off.y),
		Vector2(bx + sh_off.x + bw * 0.2, bot_y + sh_off.y),
		shadow_r,
		shadow_apex
	])
	draw_colored_polygon(poly_shadow, Color(0.0, 0.0, 0.0, 0.35))
	
	# ── Draw the bridge body (A-shape / inverted V) ──
	# Left leg (shadowed/dark side)
	var poly_l := PackedVector2Array([
		left_foot,
		Vector2(bx - bw * 0.2, bot_y),
		Vector2(bx - 1.5, top_y + bh * 0.2),
		Vector2(bx - 3.0, top_y + bh * 0.2)
	])
	draw_colored_polygon(poly_l, Color(0.24, 0.10, 0.03)) 
	
	# Right leg (lit/bright side)
	var poly_r := PackedVector2Array([
		right_foot,
		Vector2(bx + bw * 0.2, bot_y),
		Vector2(bx + 1.5, top_y + bh * 0.2),
		Vector2(bx + 3.0, top_y + bh * 0.2)
	])
	draw_colored_polygon(poly_r, Color(0.36, 0.16, 0.05)) 
	
	# Apex block (connects legs)
	var poly_top := PackedVector2Array([
		Vector2(bx - 3.0, top_y + bh * 0.2),
		Vector2(bx + 3.0, top_y + bh * 0.2),
		Vector2(bx + 2.5, top_y),
		Vector2(bx - 2.5, top_y)
	])
	draw_colored_polygon(poly_top, Color(0.30, 0.12, 0.04))
	
	# Highlight edges
	draw_line(left_foot, apex, Color(0.65, 0.40, 0.15, 0.55), 1.2, true)
	draw_line(apex, right_foot, Color(0.12, 0.06, 0.02, 0.65), 1.0, true)
	
	# White saddle (nhạn cap)
	var saddle_poly := PackedVector2Array([
		Vector2(bx - 3.0, top_y + 1.0),
		Vector2(bx - 2.0, top_y - 2.0),
		Vector2(bx + 2.0, top_y - 2.0),
		Vector2(bx + 3.0, top_y + 1.0)
	])
	draw_colored_polygon(saddle_poly, Color(0.96, 0.94, 0.88)) # cream ivory bone
	
	# Small string guide notch in the saddle
	draw_line(Vector2(bx, top_y - 2.0), Vector2(bx, top_y + 0.5), Color(0.12, 0.06, 0.02), 1.0)
	
	# Tiny golden highlight dot on the apex saddle
	draw_circle(Vector2(bx, top_y - 1.5), 0.8, Color(0.95, 0.82, 0.45))

# ─── Input helpers ────────────────────────────────────────────────────────────
func _row_h() -> float:
	var ih := size.y - 20.0
	if ih <= 0.0:
		return 20.0
	return ih / float(STR_COUNT)

func _row_at(pos: Vector2) -> int:
	var ih := size.y - 20.0
	if ih <= 0.0:
		return -1
	var rel_y := pos.y - 10.0
	if rel_y < 0.0 or rel_y >= ih:
		return -1
	return clamp(int(rel_y / (ih / float(STR_COUNT))), 0, STR_COUNT - 1)

func _row_cy(idx: int) -> float:
	var rh := _row_h()
	return 10.0 + float(idx) * rh + rh * 0.5

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
	var str_l    := get_str_l(idx)
	var str_r    := W - 24.0
	var bridge_x := get_bridge_x(idx)
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
	var str_l    := get_str_l(idx)
	var str_r    := W - 24.0
	var bridge_x := get_bridge_x(idx)
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
	pl.volume_db   = -3.0  # Slightly quieter to avoid clipping with multiple notes
	pl.bus         = "Master"
	add_child(pl)
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

	# ── Nhấn rung (vibrato) — authentic đàn tranh feel ───────────────────────
	# Vibrato starts with a short delay then grows in depth (like a real player)
	var t_ms := Time.get_ticks_msec()
	var vibrato := 0.0
	if bend > 0.05:
		# 5.5 Hz vibrato rate (typical for đàn tranh nhấn rung)
		var rate_hz := 5.5
		# Vibrato depth: max ~1.5 semitone swing (±0.022), scaled by bend
		var max_depth := 0.022 * bend
		# Vibrato onset: ramp up over first 200ms of press for natural feel
		var press_time_sec := float(_pluck_time[idx]) if _pluck_time.size() > idx else 0.3
		var onset := clampf(press_time_sec / 0.2, 0.0, 1.0)
		vibrato = onset * max_depth * sin(t_ms * 0.001 * rate_hz * TAU)

	return 1.0 + bend * 0.12246 + vibrato


func _update_press(idx: int) -> void:
	var scale := _get_pitch_scale(idx)
	var p_ref  = _audio_players[idx]
	if p_ref != null and is_instance_valid(p_ref):
		var player := p_ref as AudioStreamPlayer
		if player.playing:
			player.pitch_scale = scale
	string_pressed.emit(idx, (scale - 1.0) * 1630.0)
