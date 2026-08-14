extends Control

const NOTE_POSITIONS = {
	"Đồ": -1.0,
	"Đổ": -1.0,
	"Đô": -1.0,
	"Rề": -0.5,
	"Rê": -0.5,
	"Mì": 0.0,
	"Mi": 0.0,
	"Fà": 0.5,
	"Fa": 0.5,
	"Sò": 1.0,
	"Sol": 1.0,
	"Là": 1.5,
	"La": 1.5,
	"Sì": 2.0,
	"Si": 2.0,
	"Đố": 2.5,
	"Đô2": 2.5,
	"Rế": 3.0,
	"Rê2": 3.0,
	"Mí": 3.5,
	"Mi2": 3.5,
	"Sól": 4.5,
	"Sol2": 4.5,
	"Lá": 5.0,
	"La2": 5.0,
	
	# Dan Tranh 17 dây - Chuẩn Treble Clef (Khóa Sol chuẩn: E4 = Dòng 1 = 0.0)
	"Sol_1": -2.5,   # G3: dưới dòng phụ 2 (La_1), cần 2 dòng phụ
	"La_1": -2.0,    # A3: dòng phụ 2 dưới, cần 2 dòng phụ
	"Đô_2": -1.0,    # C4: dòng phụ 1 dưới (Middle C), cần 1 dòng phụ
	"Rê_2": -0.5,    # D4: khe dưới dòng 1, không cần dòng phụ
	"Mi_2": 0.0,     # E4: Dòng 1
	"Fa_2": 0.5,     # F4: Khe 1
	"Sol_2": 1.0,    # G4: Dòng 2
	"La_2": 1.5,     # A4: Khe 2
	"Si_2": 2.0,     # B4: Dòng 3
	"Đô_3": 2.5,     # C5: Khe 3
	"Rê_3": 3.0,     # D5: Dòng 4
	"Mi_3": 3.5,     # E5: Khe 4
	"Fa_3": 4.0,     # F5: Dòng 5
	"Sol_3": 4.5,    # G5: trên dòng 5 (khe trên)
	"La_3": 5.0,     # A5: dòng phụ 1 trên
	"Si_3": 5.5,     # B5: Khe trên dòng phụ 1
	"Đô_4": 6.0,     # C6: dòng phụ 2 trên
	"Rê_4": 6.5,     # D6: khe trên dòng phụ 2
	"Mi_4": 7.0,     # E6: dòng phụ 3 trên
	"Sol_4": 8.0,    # G6: dòng phụ 4 trên
	"La_4": 8.5      # A6: khe trên dòng phụ 4
}

var active_note = "Đô"
var line_spacing = 65.0
var clef_tex: Texture2D

func _ready():
	if ResourceLoader.exists("res://image/khung nhav.png"):
		clef_tex = load("res://image/khung nhav.png")
	resized.connect(queue_redraw)

var notes_to_draw: Array = []
var hit_line_x: float = 300.0 # Will be updated in _draw
var beats_per_measure: int = 4
var show_metronome: bool = true
var show_hit_line: bool = true
var show_clef: bool = true          # set false to hide the treble clef
var show_time_sig: bool = true      # set false to hide the time signature
var clef_highlight: bool = false    # draw clef in gold when teaching it
var time_sig_highlight: bool = false # draw time signature in gold when teaching it
var time_sig_denominator: int = 4   # bottom number of the time signature
var use_note_colors: bool = false
var hit_line_color := Color(0.2, 0.85, 0.3, 0.95)
var hit_line_glow_color := Color(0.3, 0.9, 0.4, 0.3)
var glissando_arrow_mode := ""

func set_note(note_name: String):
	active_note = note_name
	queue_redraw()

func set_notes(notes: Array):
	notes_to_draw = notes
	queue_redraw()

func _draw():
	var center_y = size.y / 2.0
	
	# Shift staff center downward slightly if zither notes are present
	# to accommodate the high octave ledger lines (G3-A6 range is shifted upward).
	var has_zither_notes = false
	for note_data in notes_to_draw:
		if note_data.get("note", "").begins_with("ZT_"):
			has_zither_notes = true
			break
	if has_zither_notes:
		center_y += line_spacing * 0.45
		
	var start_x = 35.0
	var end_x = size.x - 35.0
	hit_line_x = size.x * 0.25 # Hit line at 25% of screen
	
	var line_color = Color(0.2, 0.18, 0.15, 0.95)
	
	# Draw 5 lines (0 is bottom line, 4 is top line)
	for i in range(5):
		var y = center_y + (2 - i) * line_spacing
		draw_line(Vector2(start_x, y), Vector2(end_x, y), line_color, 3.2, true)
			
	# Draw Clef and Time signature on the left
	var font = ThemeDB.fallback_font
	if font:
		if show_clef:
			var clef_col := Color(0.9, 0.55, 0.1, 1.0) if clef_highlight else Color.BLACK
			# Adjust 𝄞 position so the swirl circles the G line (2nd line from bottom)
			draw_string(font, Vector2(10, center_y + line_spacing * 2.35), "𝄞", HORIZONTAL_ALIGNMENT_LEFT, -1, int(line_spacing * 6.5), clef_col)
		
		if show_time_sig:
			# Time signature dynamic
			var ts = str(beats_per_measure)
			var ts_size = int(line_spacing * 2.3)
			var ts_color := Color(0.9, 0.55, 0.1, 0.95) if time_sig_highlight else Color(0.15, 0.15, 0.15, 0.95)
			var ts_x = 220.0
			# The standard time signature uses numbers that fill exactly two staff spaces each.
			# Top digit: occupies top two spaces (between line 3 and line 5). Baseline sits near the middle line.
			draw_string(font, Vector2(ts_x, center_y + line_spacing * 0.05), ts, HORIZONTAL_ALIGNMENT_LEFT, -1, ts_size, ts_color)
			# Bottom digit: occupies bottom two spaces (between line 1 and line 3). Baseline sits near the bottom line.
			draw_string(font, Vector2(ts_x, center_y + line_spacing * 2.05), str(time_sig_denominator), HORIZONTAL_ALIGNMENT_LEFT, -1, ts_size, ts_color)
			
	# Draw hit line with modern glowing effect (kept as it is for timing)
	if show_hit_line:
		draw_line(Vector2(hit_line_x, center_y - 3.2 * line_spacing), Vector2(hit_line_x, center_y + 3.2 * line_spacing), hit_line_glow_color, 8.0, true)
		draw_line(Vector2(hit_line_x, center_y - 3.2 * line_spacing), Vector2(hit_line_x, center_y + 3.2 * line_spacing), hit_line_color, 3.5, true)
		
	# Draw all notes
	for note_data in notes_to_draw:
		var n_name = note_data.get("note", "Đô")
		var n_x = note_data.get("x", size.x / 2.0)
		var n_color = note_data.get("color", Color.BLACK) if use_note_colors else Color.BLACK
		var n_tail = note_data.get("tail", 0.0)
		var n_cue = note_data.get("cue", "")
		var n_type = note_data.get("type", "quarter")
		_draw_single_note(n_name, n_x, center_y, n_color, line_color, n_tail, n_cue, n_type)
		if note_data.has("press_target"):
			_draw_press_curve(note_data, center_y, n_color)
		if n_cue == "tremolo_single":
			_draw_single_tremolo_mark(note_data, center_y, n_color)
		if note_data.has("tremolo_pair_target"):
			_draw_octave_tremolo_mark(note_data, center_y, n_color)
		if note_data.get("bar_after", false):
			var bar_x := float(note_data.get("bar_x", n_x + line_spacing * 1.55))
			draw_line(
				Vector2(bar_x, center_y - 2.0 * line_spacing),
				Vector2(bar_x, center_y + 2.0 * line_spacing),
				line_color,
				3.0,
				true
			)

	if glissando_arrow_mode != "":
		_draw_glissando_arrow(center_y)
		
	# Draw 4-beat Metronome above the hit line
	if show_metronome:
		var bpm = 60.0
		var beat_time_total = Time.get_ticks_msec() / 1000.0 * (bpm / 60.0)
		var current_beat = int(floor(beat_time_total)) % beats_per_measure
		var beat_fraction = fmod(beat_time_total, 1.0)
		
		var metro_start_x = hit_line_x - 60.0
		var metro_y = center_y - 3.8 * line_spacing
		for b in range(beats_per_measure):
			var bx = metro_start_x + b * 40.0
			var c = Color(0.5, 0.5, 0.5, 0.3)
			var r = 8.0
			if b == current_beat:
				c = Color(0.9, 0.2, 0.2, 1.0 - beat_fraction * 0.3)
				r = 12.0 + sin(beat_fraction * PI) * 4.0
			elif b == 0:
				c = Color(0.9, 0.5, 0.2, 0.6) # Highlight the first beat of the measure
			draw_circle(Vector2(bx, metro_y), r, c)
			if b == current_beat:
				draw_arc(Vector2(bx, metro_y), r + 4.0, 0, TAU, 32, Color(0.9, 0.2, 0.2, 0.5), 2.0, true)

func _get_note_position_index(note_name: String) -> float:
	var clean_name := note_name
	var is_zither := clean_name.begins_with("ZT_")
	if is_zither:
		clean_name = clean_name.right(-3)
	var mapped_name := clean_name
	if is_zither or not NOTE_POSITIONS.has(mapped_name):
		for i in range(clean_name.length() - 1, -1, -1):
			if clean_name[i].is_valid_int():
				var alternate := clean_name.left(i) + "_" + clean_name.right(-i)
				if NOTE_POSITIONS.has(alternate):
					mapped_name = alternate
					break
	return float(NOTE_POSITIONS.get(mapped_name, 0.0))

func _draw_glissando_arrow(center_y: float) -> void:
	if notes_to_draw.is_empty():
		return
	var arrow_color := Color(0.08, 0.075, 0.065, 1.0)
	var stem_top: float = center_y - 2.55 * float(line_spacing)
	var stem_bottom: float = center_y + 1.55 * float(line_spacing)
	for note_data in notes_to_draw:
		var note_x := float(note_data.get("x", size.x / 2.0))
		# Ký hiệu Á nằm trước từng nốt như sheet mẫu, không nối các nốt với nhau.
		var cue_x := note_x - maxf(20.0, line_spacing * 0.72)
		if glissando_arrow_mode == "up":
			var up_tip := Vector2(cue_x, stem_top)
			var up_from := Vector2(cue_x, stem_bottom)
			draw_line(up_from, up_tip + Vector2(0, 12.0), arrow_color, 3.2, true)
			_draw_glissando_arrow_head(up_from, up_tip, arrow_color, 15.0, 8.0)
		elif glissando_arrow_mode == "round":
			_draw_glissando_round_mark(cue_x, stem_top, stem_bottom, arrow_color)
		else:
			var down_from := Vector2(cue_x, stem_top)
			var down_tip := Vector2(cue_x, stem_bottom)
			draw_line(down_from, down_tip - Vector2(0, 12.0), arrow_color, 3.2, true)
			_draw_glissando_arrow_head(down_from, down_tip, arrow_color, 15.0, 8.0)


func _draw_glissando_round_mark(cue_x: float, top_y: float, bottom_y: float, color: Color) -> void:
	var left_arrow_x := cue_x - 7.0
	var right_arrow_x := cue_x + 7.0
	var top_left := Vector2(left_arrow_x, top_y)
	var bottom_left := Vector2(left_arrow_x, bottom_y)
	var top_right := Vector2(right_arrow_x, top_y)
	var bottom_right := Vector2(right_arrow_x, bottom_y)

	# Á vòng theo ký hiệu (↓ ↑): xuống ở bên trái, lên ở bên phải.
	draw_line(top_left, bottom_left - Vector2(0, 12.0), color, 3.0, true)
	_draw_glissando_arrow_head(top_left, bottom_left, color, 14.0, 7.0)
	draw_line(bottom_right, top_right + Vector2(0, 12.0), color, 3.0, true)
	_draw_glissando_arrow_head(bottom_right, top_right, color, 14.0, 7.0)
	_draw_glissando_parenthesis(cue_x - 17.0, top_y, bottom_y, true, color)
	_draw_glissando_parenthesis(cue_x + 17.0, top_y, bottom_y, false, color)


func _draw_glissando_parenthesis(x: float, top_y: float, bottom_y: float, is_left: bool, color: Color) -> void:
	var points := PackedVector2Array()
	var center_y := (top_y + bottom_y) * 0.5
	var radius_y := (bottom_y - top_y) * 0.5 + 5.0
	var radius_x := 6.0
	var start_angle := PI * 0.5 if is_left else -PI * 0.5
	var end_angle := PI * 1.5 if is_left else PI * 0.5
	for i in range(17):
		var ratio := float(i) / 16.0
		var angle := lerpf(start_angle, end_angle, ratio)
		points.append(Vector2(x + cos(angle) * radius_x, center_y + sin(angle) * radius_y))
	draw_polyline(points, color, 2.6, true)


func _draw_glissando_arrow_head(from_point: Vector2, tip: Vector2, color: Color, head_length: float = 24.0, head_width: float = 13.0) -> void:
	var direction := (tip - from_point).normalized()
	if direction.length_squared() <= 0.001:
		return
	var perpendicular := Vector2(-direction.y, direction.x)
	var base := tip - direction * head_length
	var triangle := PackedVector2Array([
		tip,
		base + perpendicular * head_width,
		base - perpendicular * head_width
	])
	draw_colored_polygon(triangle, color)

func _draw_press_curve(note_data: Dictionary, center_y: float, color: Color) -> void:
	var source_name := str(note_data.get("note", "ZT_Mi2"))
	var target_name := str(note_data.get("press_target", "ZT_Fa2"))
	var source_x := float(note_data.get("x", size.x * 0.4))
	var target_x := float(note_data.get("press_target_x", source_x + line_spacing * 1.8))
	var source_pos := _get_note_position_index(source_name)
	var target_pos := _get_note_position_index(target_name)
	var source_y: float = center_y + (2.0 - source_pos) * line_spacing
	var target_y: float = center_y + (2.0 - target_pos) * line_spacing
	var start := Vector2(source_x + line_spacing * 0.34, source_y - line_spacing * 0.20)
	var tip := Vector2(target_x - line_spacing * 0.34, target_y - line_spacing * 0.20)
	var control := Vector2((start.x + tip.x) * 0.5, minf(start.y, tip.y) - line_spacing * 0.78)
	var points := PackedVector2Array()
	var segments := 24
	for i in range(segments + 1):
		var ratio := float(i) / float(segments)
		var inv := 1.0 - ratio
		points.append(inv * inv * start + 2.0 * inv * ratio * control + ratio * ratio * tip)
	draw_polyline(points, Color(color.r, color.g, color.b, 0.22), 9.0, true)
	draw_polyline(points, color, 3.2, true)
	_draw_glissando_arrow_head(points[points.size() - 2], tip, color)
	var font := ThemeDB.fallback_font
	if font:
		draw_string(
			font,
			Vector2(control.x - line_spacing * 0.48, control.y - 5.0),
			"NHẤN",
			HORIZONTAL_ALIGNMENT_CENTER,
			line_spacing * 0.96,
			maxi(11, int(line_spacing * 0.23)),
			color
		)

func _draw_single_note(note_name: String, note_x: float, center_y: float, note_color: Color, line_color: Color, tail_w: float = 0.0, cue: String = "", note_type: String = "quarter"):
	var clean_name = note_name
	if clean_name.begins_with("ZT_"):
		clean_name = clean_name.right(-3)
	
	var is_zither = note_name.begins_with("ZT_")
	var mapped_name = clean_name
	
	# For zither notes, prioritize the underscore mapping (e.g. "Đô_2" over "Đô2")
	# to avoid colliding with old non-zither keys in NOTE_POSITIONS.
	if is_zither:
		for i in range(clean_name.length() - 1, -1, -1):
			if clean_name[i].is_valid_int():
				var prefix = clean_name.left(i)
				var suffix = clean_name.right(-i)
				var alt = prefix + "_" + suffix
				if NOTE_POSITIONS.has(alt):
					mapped_name = alt
					break
	else:
		if not NOTE_POSITIONS.has(mapped_name):
			for i in range(clean_name.length() - 1, -1, -1):
				if clean_name[i].is_valid_int():
					var prefix = clean_name.left(i)
					var suffix = clean_name.right(-i)
					var alt = prefix + "_" + suffix
					if NOTE_POSITIONS.has(alt):
						mapped_name = alt
						break
					
	if not NOTE_POSITIONS.has(mapped_name): return
	var pos_idx = NOTE_POSITIONS[mapped_name]
	var note_y = center_y + (2 - pos_idx) * line_spacing
	
	var display_name = clean_name
	if is_zither:
		# Use unicode subscripts for octave registers on zither notes
		if display_name.ends_with("1"):
			display_name = display_name.left(-1) + "₁"
		elif display_name.ends_with("2"):
			display_name = display_name.left(-1) + "₂"
		elif display_name.ends_with("3"):
			display_name = display_name.left(-1) + "₃"
		elif display_name.ends_with("4"):
			display_name = display_name.left(-1) + "₄"
	else:
		# Standard layout cleans up numbers entirely
		for i in range(display_name.length() - 1, -1, -1):
			var char_val = display_name[i]
			if char_val.is_valid_int() or char_val == "_":
				display_name = display_name.left(i)
			else:
				break
	
	var note_width = line_spacing * (1.15 if is_zither else 1.35)
	var note_height = line_spacing * (0.8 if is_zither else 0.95)

	# Draw ledger lines for notes outside the 5-line staff
	if pos_idx < -0.9: # below first ledger line threshold (pos_idx <= -1.0)
		var num_ledgers = int(ceil(abs(pos_idx)))
		for i in range(1, num_ledgers + 1):
			var ld = -i
			var ly = center_y + (2 - ld) * line_spacing
			draw_line(Vector2(note_x - note_width * 0.8, ly), Vector2(note_x + note_width * 0.8, ly), line_color, 3.0, true)
	elif pos_idx > 4.9: # above first ledger line threshold (pos_idx >= 5.0)
		var num_ledgers = int(ceil(pos_idx)) - 4
		for i in range(1, num_ledgers + 1):
			var ld = 4 + i
			var ly = center_y + (2 - ld) * line_spacing
			draw_line(Vector2(note_x - note_width * 0.8, ly), Vector2(note_x + note_width * 0.8, ly), line_color, 3.0, true)
			
	# Duration tail drawing removed per user request
			
	# Draw soft radiating halo around notes removed since notes are now black
			
	# Draw note head (rotated ellipse)
	var note_rect = Rect2(note_x - note_width/2.0, note_y - note_height/2.0, note_width, note_height)
	if note_type == "whole" or note_type == "half":
		_draw_rotated_ellipse(note_rect, deg_to_rad(-18), note_color)
		# Make it hollow
		var inner_rect = Rect2(note_x - note_width/2.5, note_y - note_height/2.5, note_width * 0.8, note_height * 0.8)
		var bg_color = Color(0.995, 0.98, 0.93, 1.0) # Matches StaffCard bg
		_draw_rotated_ellipse(inner_rect, deg_to_rad(-18), bg_color)
	else:
		_draw_rotated_ellipse(note_rect, deg_to_rad(-18), note_color)
	
	# Draw stem and flags
	if note_type != "whole":
		var stem_len = line_spacing * 2.2
		var stem_w = max(2.5, line_spacing * 0.08)
		var stem_x = 0.0
		var stem_end_y = 0.0
		var is_stem_up = pos_idx < 2.0
		
		if is_stem_up:
			stem_x = note_x + note_width/2.0 - 2.0
			stem_end_y = note_y - stem_len
			draw_line(Vector2(stem_x, note_y), Vector2(stem_x, stem_end_y), note_color, stem_w, true)
		else:
			stem_x = note_x - note_width/2.0 + 2.0
			stem_end_y = note_y + stem_len
			draw_line(Vector2(stem_x, note_y), Vector2(stem_x, stem_end_y), note_color, stem_w, true)
			
		# Draw flags (móc)
		if note_type == "eighth" or note_type == "sixteenth":
			var flag_w = note_width * 0.8
			var flag_h = stem_len * 0.42
			var hook_dir = 1.0 if is_stem_up else -1.0
			
			# Flag 1
			var f1_start = Vector2(stem_x, stem_end_y)
			_draw_flag(f1_start, hook_dir, flag_w, flag_h, note_color, stem_w)
			
			# Flag 2
			if note_type == "sixteenth":
				var f2_start = Vector2(stem_x, stem_end_y + stem_len * 0.22 * hook_dir)
				_draw_flag(f2_start, hook_dir, flag_w, flag_h, note_color, stem_w)

	if cue == "vibrato":
		var mark_y: float = note_y - line_spacing * (2.65 if pos_idx < 2.0 else 1.25)
		_draw_vibrato_mark(Vector2(note_x, mark_y), note_color, line_spacing)

func _draw_vibrato_mark(center: Vector2, color: Color, spacing: float) -> void:
	var points := PackedVector2Array()
	var width := spacing * 1.25
	var amplitude := maxf(3.5, spacing * 0.10)
	var segments := 32
	for i in range(segments + 1):
		var ratio := float(i) / float(segments)
		var x := center.x - width * 0.5 + width * ratio
		var y := center.y + sin(ratio * TAU * 3.0) * amplitude
		points.append(Vector2(x, y))
	draw_polyline(points, color, maxf(2.4, spacing * 0.065), true)

func _draw_single_tremolo_mark(note_data: Dictionary, center_y: float, color: Color) -> void:
	var note_name := str(note_data.get("note", "ZT_Đô2"))
	var note_x := float(note_data.get("x", size.x * 0.5))
	var pos_idx := _get_note_position_index(note_name)
	var note_y: float = center_y + (2.0 - pos_idx) * line_spacing
	var note_width: float = line_spacing * 1.15
	var stem_len: float = line_spacing * 2.2
	var stem_up := pos_idx < 2.0
	var stem_x: float = note_x + note_width * 0.5 - 2.0 if stem_up else note_x - note_width * 0.5 + 2.0
	var stem_end_y: float = note_y - stem_len if stem_up else note_y + stem_len
	var center := Vector2(stem_x, lerpf(note_y, stem_end_y, 0.52))
	var stroke_length: float = line_spacing * 0.82
	var stroke_rise: float = line_spacing * 0.28
	var stroke_gap: float = line_spacing * 0.29
	for i in range(3):
		var offset := (float(i) - 1.0) * stroke_gap * (1.0 if stem_up else -1.0)
		var from := center + Vector2(-stroke_length * 0.5, offset - stroke_rise * 0.5)
		var to := center + Vector2(stroke_length * 0.5, offset + stroke_rise * 0.5)
		draw_line(from, to, Color(color.r, color.g, color.b, 0.20), 10.0, true)
		draw_line(from, to, color, maxf(4.0, line_spacing * 0.085), true)

func _draw_octave_tremolo_mark(note_data: Dictionary, center_y: float, color: Color) -> void:
	var source_name := str(note_data.get("note", "ZT_Đô2"))
	var target_name := str(note_data.get("tremolo_pair_target", "ZT_Đô3"))
	var source_x := float(note_data.get("x", size.x * 0.43))
	var target_x := float(note_data.get("tremolo_pair_target_x", size.x * 0.57))
	var source_pos := _get_note_position_index(source_name)
	var target_pos := _get_note_position_index(target_name)
	var source_y: float = center_y + (2.0 - source_pos) * line_spacing
	var target_y: float = center_y + (2.0 - target_pos) * line_spacing
	var note_width: float = line_spacing * 1.15
	var stem_len: float = line_spacing * 2.2
	var left := Vector2(source_x + note_width * 0.5 - 2.0, source_y - stem_len * 0.48)
	var right := Vector2(target_x - note_width * 0.5 + 2.0, target_y + stem_len * 0.48)
	var gap: float = line_spacing * 0.30
	for i in range(3):
		var y_offset := (float(i) - 1.0) * gap
		var from := left + Vector2(0.0, y_offset)
		var to := right + Vector2(0.0, y_offset)
		draw_line(from, to, Color(color.r, color.g, color.b, 0.20), 11.0, true)
		draw_line(from, to, color, maxf(4.2, line_spacing * 0.09), true)

func _draw_rotated_ellipse(rect: Rect2, angle: float, color: Color):
	var points = PackedVector2Array()
	var center = rect.get_center()
	var rx = rect.size.x / 2.0
	var ry = rect.size.y / 2.0
	var segments = 32
	
	for i in range(segments):
		var t = i * TAU / segments
		var px = rx * cos(t)
		var py = ry * sin(t)
		
		var rx_rot = px * cos(angle) - py * sin(angle)
		var ry_rot = px * sin(angle) + py * cos(angle)
		
		points.append(center + Vector2(rx_rot, ry_rot))
		
	draw_colored_polygon(points, color)

func _draw_flag(start_pos: Vector2, hook_dir: float, flag_w: float, flag_h: float, color: Color, width: float) -> void:
	var p0 := start_pos
	var p1 := start_pos + Vector2(flag_w * 0.45, flag_h * 0.05 * hook_dir)
	var p2 := start_pos + Vector2(flag_w * 1.05, flag_h * 0.45 * hook_dir)
	var p3 := start_pos + Vector2(flag_w * 0.65, flag_h * 1.0 * hook_dir)
	
	var points := PackedVector2Array()
	var steps := 16
	for i in range(steps + 1):
		var t := i / float(steps)
		var t_inv := 1.0 - t
		var pt := t_inv * t_inv * t_inv * p0 + 3.0 * t_inv * t_inv * t * p1 + 3.0 * t_inv * t * t * p2 + t * t * t * p3
		points.append(pt)
	draw_polyline(points, color, width * 1.35, true)
