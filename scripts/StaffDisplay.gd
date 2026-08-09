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
	"Sol_2": 1.0,    # G4: Dòng 2
	"La_2": 1.5,     # A4: Khe 2
	"Đô_3": 2.5,     # C5: Khe 3
	"Rê_3": 3.0,     # D5: Dòng 4
	"Mi_3": 3.5,     # E5: Khe 4
	"Sol_3": 4.5,    # G5: trên dòng 5 (khe trên)
	"La_3": 5.0,     # A5: dòng phụ 1 trên
	"Đô_4": 6.0,     # C6: dòng phụ 2 trên
	"Rê_4": 6.5,     # D6: khe trên dòng phụ 2
	"Mi_4": 7.0,     # E6: dòng phụ 3 trên
	"Sol_4": 8.0,    # G6: dòng phụ 4 trên
	"La_4": 8.5      # A6: khe trên dòng phụ 4
}

var active_note = "Đô"
var line_spacing = 65.0
var clef_tex: Texture2D
var treble_clef_tex: Texture2D
var four_four_tex: Texture2D

func _ready():
	if ResourceLoader.exists("res://image/khung nhav.png"):
		clef_tex = load("res://image/khung nhav.png")
	if ResourceLoader.exists("res://icons8/icons8-treble-clef-120.png"):
		treble_clef_tex = load("res://icons8/icons8-treble-clef-120.png")
	if ResourceLoader.exists("res://icons8/icons8-four-four-120.png"):
		four_four_tex = load("res://icons8/icons8-four-four-120.png")
	resized.connect(queue_redraw)

var notes_to_draw: Array = []
var hit_line_x: float = 300.0 # Will be updated in _draw

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
			
	# Draw Treble clef and Time Signature 4/4 at the start of the staff
	# We place it before the hit line so it remains static
	var clef_x = start_x + 15.0
	
	if four_four_tex:
		# Since icons8's four-four texture contains BOTH the Treble clef and the 4/4 time signature,
		# drawing it alone is sufficient and avoids duplicate clef rendering.
		var ts_h = line_spacing * 5.2
		var ts_w = ts_h * (float(four_four_tex.get_width()) / four_four_tex.get_height())
		var ts_y = center_y - ts_h * 0.52
		draw_texture_rect(four_four_tex, Rect2(clef_x, ts_y, ts_w, ts_h), false, line_color)
	else:
		# Fallback: Draw Treble Clef and Time Signature separately
		var clef_w = line_spacing * 1.5
		if treble_clef_tex:
			var clef_h = line_spacing * 5.2
			clef_w = clef_h * (float(treble_clef_tex.get_width()) / treble_clef_tex.get_height())
			var clef_y = center_y - clef_h * 0.52
			draw_texture_rect(treble_clef_tex, Rect2(clef_x, clef_y, clef_w, clef_h), false, line_color)
		else:
			_draw_vector_clef(clef_x, center_y, line_color, line_spacing)
			
		# Draw Time Signature 4/4 (text fallback)
		var ts_x = clef_x + clef_w + 12.0
		var font = ThemeDB.fallback_font
		if font:
			var ts_font_size = int(line_spacing * 1.5)
			var ts_string = "4"
			var ts_w = font.get_string_size(ts_string, HORIZONTAL_ALIGNMENT_CENTER, -1, ts_font_size).x
			
			# Top 4: from line 2 to line 4, vertical center is center_y - line_spacing
			var top_y = center_y - line_spacing * 1.0 + font.get_string_size(ts_string, HORIZONTAL_ALIGNMENT_CENTER, -1, ts_font_size).y * 0.35
			draw_string(font, Vector2(ts_x - ts_w/2.0, top_y), ts_string, HORIZONTAL_ALIGNMENT_CENTER, -1, ts_font_size, line_color)
			
			# Bottom 4: from line 0 to line 2, vertical center is center_y + line_spacing
			var bottom_y = center_y + line_spacing * 1.0 + font.get_string_size(ts_string, HORIZONTAL_ALIGNMENT_CENTER, -1, ts_font_size).y * 0.35
			draw_string(font, Vector2(ts_x - ts_w/2.0, bottom_y), ts_string, HORIZONTAL_ALIGNMENT_CENTER, -1, ts_font_size, line_color)
			
	# Draw hit line with modern glowing effect
	draw_line(Vector2(hit_line_x, center_y - 3.2 * line_spacing), Vector2(hit_line_x, center_y + 3.2 * line_spacing), Color(0.3, 0.9, 0.4, 0.3), 8.0, true)
	draw_line(Vector2(hit_line_x, center_y - 3.2 * line_spacing), Vector2(hit_line_x, center_y + 3.2 * line_spacing), Color(0.2, 0.85, 0.3, 0.95), 3.5, true)
		
	# Draw all notes
	for note_data in notes_to_draw:
		var n_name = note_data.get("note", "Đô")
		var n_x = note_data.get("x", size.x / 2.0)
		var n_color = note_data.get("color", Color(0.96, 0.75, 0.25, 1.0))
		var n_tail = note_data.get("tail", 0.0)
		var n_cue = note_data.get("cue", "")
		var n_duration = note_data.get("duration", 1.0)
		_draw_single_note(n_name, n_x, center_y, n_color, line_color, n_tail, n_cue, n_duration)

func _draw_single_note(note_name: String, note_x: float, center_y: float, note_color: Color, line_color: Color, tail_w: float = 0.0, cue: String = "", duration: float = 1.0):
	var clean_name = note_name
	if clean_name.begins_with("ZT_"):
		clean_name = clean_name.right(-3)
	
	var is_zither = note_name.begins_with("ZT_")
	var is_rest = clean_name.to_lower() == "rest"
	
	# Smoothly fade out notes as they scroll past the hit line to the left (approaching the static Clef/Time Signature zone)
	var note_alpha = 1.0
	var start_x = 35.0
	var fade_end = start_x + 180.0
	if note_x < hit_line_x:
		note_alpha = clamp((note_x - fade_end) / (hit_line_x - fade_end), 0.0, 1.0)
		if note_alpha <= 0.0:
			return # fully invisible note, skip drawing
			
	# Parse duration base and dotted values
	var is_dotted = false
	var base_duration = duration
	if abs(duration - 1.5) < 0.1:
		base_duration = 1.0
		is_dotted = true
	elif abs(duration - 3.0) < 0.1:
		base_duration = 2.0
		is_dotted = true
	elif abs(duration - 0.75) < 0.1:
		base_duration = 0.5
		is_dotted = true
		
	var is_whole = base_duration >= 4.0
	var is_half = base_duration >= 2.0 and base_duration < 4.0
	var is_quarter = base_duration >= 1.0 and base_duration < 2.0
	var is_eighth = base_duration >= 0.5 and base_duration < 1.0
	var is_sixteenth = base_duration < 0.5
	
	var note_y = center_y
	var pos_idx = 2.0
	
	if not is_rest:
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
		pos_idx = NOTE_POSITIONS[mapped_name]
		note_y = center_y + (2 - pos_idx) * line_spacing
	
	# Handle Rest drawing
	if is_rest:
		var rest_color = note_color
		rest_color.a *= note_alpha
		var w = line_spacing * 0.25
		
		if is_whole:
			# Whole rest: filled rectangle hanging from line index 3 (second line from top)
			var ry = center_y - line_spacing
			var r_rect = Rect2(note_x - w, ry, w * 2.0, line_spacing * 0.28)
			draw_rect(r_rect, rest_color, true)
		elif is_half:
			# Half rest: filled rectangle sitting on line index 2 (middle line, y = center_y)
			var ry = center_y - line_spacing * 0.28
			var r_rect = Rect2(note_x - w, ry, w * 2.0, line_spacing * 0.28)
			draw_rect(r_rect, rest_color, true)
		elif is_quarter:
			# Quarter rest: zigzag line
			var points = PackedVector2Array([
				Vector2(note_x - w * 0.6, center_y - line_spacing * 0.8),
				Vector2(note_x + w * 0.6, center_y - line_spacing * 0.3),
				Vector2(note_x - w * 0.8, center_y + line_spacing * 0.2),
				Vector2(note_x + w * 0.2, center_y + line_spacing * 0.6),
				Vector2(note_x - w * 0.4, center_y + line_spacing * 0.8)
			])
			draw_polyline(points, rest_color, 4.0, true)
		else: # Eighth / Sixteenth rest
			# Eighth rest: slash with a hook
			var hook_center = Vector2(note_x - w * 0.5, center_y - line_spacing * 0.2)
			draw_circle(hook_center, line_spacing * 0.08, rest_color)
			draw_line(Vector2(note_x, center_y - line_spacing * 0.1), Vector2(note_x - w, center_y + line_spacing * 0.6), rest_color, 4.0, true)
		return
		
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
		var num_ledgers = int(abs(ceil(pos_idx)))
		for i in range(1, num_ledgers + 1):
			var ld = -i
			var ly = center_y + (2 - ld) * line_spacing
			var led_col = line_color
			led_col.a *= note_alpha
			draw_line(Vector2(note_x - note_width * 0.8, ly), Vector2(note_x + note_width * 0.8, ly), led_col, 3.0, true)
	elif pos_idx > 4.9: # above first ledger line threshold (pos_idx >= 5.0)
		var num_ledgers = int(floor(pos_idx)) - 4
		for i in range(1, num_ledgers + 1):
			var ld = 4 + i
			var ly = center_y + (2 - ld) * line_spacing
			var led_col = line_color
			led_col.a *= note_alpha
			draw_line(Vector2(note_x - note_width * 0.8, ly), Vector2(note_x + note_width * 0.8, ly), led_col, 3.0, true)
			
	# Draw duration tail if present (as a clean, thin, elegant semi-transparent line)
	if tail_w > 0.0:
		var tail_col = note_color
		tail_col.a = 0.4 * note_alpha
		var tail_start = note_x + note_width / 2.0 - 4.0
		var actual_tail_w = max(0.0, tail_w - (note_width / 2.0))
		if actual_tail_w > 0.0:
			var end_x_pos = tail_start + actual_tail_w
			draw_line(Vector2(tail_start, note_y), Vector2(end_x_pos, note_y), tail_col, 3.0, true)
			var tick_h = line_spacing * 0.3
			draw_line(Vector2(end_x_pos, note_y - tick_h), Vector2(end_x_pos, note_y + tick_h), tail_col, 3.0, true)
			
	# Draw soft radiating golden halo around notes
	var glow_color = note_color
	glow_color.a = 0.22 * note_alpha
	draw_circle(Vector2(note_x, note_y), note_height * 0.82, glow_color)
	glow_color.a = 0.08 * note_alpha
	draw_circle(Vector2(note_x, note_y), note_height * 1.25, glow_color)
			
	# Draw note head (rotated ellipse) - hollow for whole and half notes
	var note_rect = Rect2(note_x - note_width/2.0, note_y - note_height/2.0, note_width, note_height)
	var col_head = note_color
	col_head.a *= note_alpha
	var is_hollow = is_whole or is_half
	_draw_rotated_ellipse(note_rect, deg_to_rad(-18), col_head, is_hollow, 4.0)
	
	# Draw dot if dotted note
	if is_dotted:
		var dot_col = note_color
		dot_col.a *= note_alpha
		var dot_y = note_y
		if abs(pos_idx - round(pos_idx)) < 0.1:
			dot_y -= line_spacing * 0.25
		draw_circle(Vector2(note_x + note_width * 0.65, dot_y), line_spacing * 0.08, dot_col)
	
	# Draw fingering cues inside the note if available, else draw text
	if cue != "":
		var center_pt = Vector2(note_x, note_y)
		var symbol_color = Color.WHITE
		symbol_color.a *= note_alpha
		if cue == "circle":
			draw_circle(center_pt, note_height * 0.35, symbol_color)
		elif cue == "square":
			var sz = note_height * 0.6
			draw_rect(Rect2(center_pt.x - sz/2.0, center_pt.y - sz/2.0, sz, sz), symbol_color, true)
		elif cue == "triangle":
			var sz = note_height * 0.4
			var p1 = center_pt + Vector2(0, -sz)
			var p2 = center_pt + Vector2(-sz, sz * 0.8)
			var p3 = center_pt + Vector2(sz, sz * 0.8)
			draw_polygon(PackedVector2Array([p1, p2, p3]), PackedColorArray([symbol_color, symbol_color, symbol_color]))
	else:
		# Draw bold note name text inside note head
		var font = ThemeDB.fallback_font
		if font:
			var font_size = int(line_spacing * (0.42 if is_zither else 0.48))
			var str_size = font.get_string_size(display_name, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
			var text_pos = Vector2(note_x - str_size.x / 2.0, note_y + str_size.y * 0.35)
			var text_color = Color.WHITE
			if is_hollow:
				# Use dark text for hollow notes to keep it readable against cream backgrounds
				text_color = line_color
			text_color.a *= note_alpha
			draw_string(font, text_pos, display_name, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_color)
	
	# Draw stem and flags
	if not is_whole:
		var stem_len = line_spacing * 2.2
		var stem_w = max(2.5, line_spacing * 0.08)
		var stem_up = pos_idx < 2.0
		var stem_x = 0.0
		var stem_tip = Vector2.ZERO
		var col_stem = note_color
		col_stem.a *= note_alpha
		
		if stem_up:
			stem_x = note_x + note_width/2.0 - 2.0
			stem_tip = Vector2(stem_x, note_y - stem_len)
			draw_line(Vector2(stem_x, note_y), stem_tip, col_stem, stem_w, true)
		else:
			stem_x = note_x - note_width/2.0 + 2.0
			stem_tip = Vector2(stem_x, note_y + stem_len)
			draw_line(Vector2(stem_x, note_y), stem_tip, col_stem, stem_w, true)
			
		# Draw flags for eighth / sixteenth notes
		if is_eighth or is_sixteenth:
			_draw_flag(stem_tip, stem_up, col_stem, line_spacing, is_sixteenth)

func _draw_flag(stem_tip: Vector2, stem_up: bool, color: Color, spacing: float, double_flag: bool = false):
	var dir = 1.0 if stem_up else -1.0
	
	# Draw first flag
	_draw_single_filled_flag(stem_tip, stem_up, color, spacing)
	
	# If double flag (sixteenth note), draw the second flag shifted along the stem
	if double_flag:
		var second_flag_tip = stem_tip + Vector2(0, dir * spacing * 0.36)
		_draw_single_filled_flag(second_flag_tip, stem_up, color, spacing)

func _draw_single_filled_flag(tip_pos: Vector2, stem_up: bool, color: Color, spacing: float):
	var stem_x = tip_pos.x
	var stem_y = tip_pos.y
	var points = PackedVector2Array()
	
	points.append(Vector2(stem_x, stem_y))
	
	if stem_up:
		# Flag curves down-right
		var out_ctrl1 = Vector2(stem_x + spacing * 0.36, stem_y + spacing * 0.3)
		var out_ctrl2 = Vector2(stem_x + spacing * 0.43, stem_y + spacing * 0.8)
		var tip = Vector2(stem_x + spacing * 0.25, stem_y + spacing * 1.35)
		for i in range(1, 11):
			var t = i / 10.0
			var mt = 1.0 - t
			var pt = mt*mt*mt * Vector2(stem_x, stem_y) + 3.0*mt*mt*t * out_ctrl1 + 3.0*mt*t*t * out_ctrl2 + t*t*t * tip
			points.append(pt)
			
		var stem_attach = Vector2(stem_x, stem_y + spacing * 0.55)
		var in_ctrl1 = Vector2(stem_x + spacing * 0.24, stem_y + spacing * 0.95)
		var in_ctrl2 = Vector2(stem_x + spacing * 0.20, stem_y + spacing * 0.65)
		for i in range(1, 11):
			var t = i / 10.0
			var mt = 1.0 - t
			var pt = mt*mt*mt * tip + 3.0*mt*mt*t * in_ctrl1 + 3.0*mt*t*t * in_ctrl2 + t*t*t * stem_attach
			points.append(pt)
	else:
		# Flag curves up-right
		var out_ctrl1 = Vector2(stem_x + spacing * 0.36, stem_y - spacing * 0.3)
		var out_ctrl2 = Vector2(stem_x + spacing * 0.43, stem_y - spacing * 0.8)
		var tip = Vector2(stem_x + spacing * 0.25, stem_y - spacing * 1.35)
		for i in range(1, 11):
			var t = i / 10.0
			var mt = 1.0 - t
			var pt = mt*mt*mt * Vector2(stem_x, stem_y) + 3.0*mt*mt*t * out_ctrl1 + 3.0*mt*t*t * out_ctrl2 + t*t*t * tip
			points.append(pt)
			
		var stem_attach = Vector2(stem_x, stem_y - spacing * 0.55)
		var in_ctrl1 = Vector2(stem_x + spacing * 0.24, stem_y - spacing * 0.95)
		var in_ctrl2 = Vector2(stem_x + spacing * 0.20, stem_y - spacing * 0.65)
		for i in range(1, 11):
			var t = i / 10.0
			var mt = 1.0 - t
			var pt = mt*mt*mt * tip + 3.0*mt*mt*t * in_ctrl1 + 3.0*mt*t*t * in_ctrl2 + t*t*t * stem_attach
			points.append(pt)
			
	points.append(Vector2(stem_x, stem_y))
	draw_colored_polygon(points, color)

func _draw_rotated_ellipse(rect: Rect2, angle: float, color: Color, hollow: bool = false, line_width: float = 4.0):
	var points = PackedVector2Array()
	var center = rect.get_center()
	var rx = rect.size.x / 2.0
	var ry = rect.size.y / 2.0
	var segments = 32
	
	for i in range(segments + 1):
		var t = (i % segments) * TAU / segments
		var px = rx * cos(t)
		var py = ry * sin(t)
		
		var rx_rot = px * cos(angle) - py * sin(angle)
		var ry_rot = px * sin(angle) + py * cos(angle)
		
		points.append(center + Vector2(rx_rot, ry_rot))
		
	if hollow:
		var inner_points = PackedVector2Array()
		var irx = rx - line_width
		var iry = ry - line_width * 0.7
		for i in range(segments):
			var t = i * TAU / segments
			var px = irx * cos(t)
			var py = iry * sin(t)
			var rx_rot = px * cos(angle) - py * sin(angle)
			var ry_rot = px * sin(angle) + py * cos(angle)
			inner_points.append(center + Vector2(rx_rot, ry_rot))
		draw_colored_polygon(inner_points, Color(0.96, 0.95, 0.92, 1.0))
		draw_polyline(points, color, line_width, true)
	else:
		draw_colored_polygon(points, color)

func _draw_vector_clef(x: float, center_y: float, color: Color, spacing: float):
	var stem_x = x + spacing * 0.7
	var stem_top = center_y - spacing * 3.1
	var stem_bottom = center_y + spacing * 2.1
	
	# Draw main vertical stem
	draw_line(Vector2(stem_x, stem_top), Vector2(stem_x, stem_bottom), color, max(3.5, spacing * 0.08), true)
	
	# Part 1: Bottom hook curl
	var hook_points = PackedVector2Array()
	var h0 = Vector2(stem_x, stem_bottom)
	var h1 = h0 + Vector2(0, spacing * 0.5)
	var h2 = h0 + Vector2(-spacing * 0.6, spacing * 0.4)
	var h3 = h0 + Vector2(-spacing * 0.5, 0.0)
	for i in range(11):
		var t = i / 10.0
		var mt = 1.0 - t
		var pt = mt*mt*mt * h0 + 3.0*mt*mt*t * h1 + 3.0*mt*t*t * h2 + t*t*t * h3
		hook_points.append(pt)
	draw_polyline(hook_points, color, max(3.5, spacing * 0.08), true)
	draw_circle(h3, spacing * 0.12, color) # hook terminal dot
	
	# Part 2: Top loop going right and down to crossing point
	var loop_points = PackedVector2Array()
	var l0 = Vector2(stem_x, stem_top)
	var l1 = l0 + Vector2(spacing * 0.7, spacing * 0.4)
	var l2 = l0 + Vector2(spacing * 0.6, spacing * 1.8)
	# Cross stem at center_y + spacing * 0.8
	var l3 = Vector2(stem_x - spacing * 0.35, center_y + spacing * 0.8)
	for i in range(11):
		var t = i / 10.0
		var mt = 1.0 - t
		var pt = mt*mt*mt * l0 + 3.0*mt*mt*t * l1 + 3.0*mt*t*t * l2 + t*t*t * l3
		loop_points.append(pt)
	draw_polyline(loop_points, color, max(3.5, spacing * 0.08), true)
	
	# Part 3: Big bottom loop & curl around Sol line (center_y + spacing)
	# Curve from l3 down and right, crossing stem going up
	var g_points = PackedVector2Array()
	var g0 = l3
	var g1 = g0 + Vector2(-spacing * 0.8, spacing * 1.6)
	var g2 = g0 + Vector2(spacing * 1.4, spacing * 1.5)
	# Cross stem going up around center_y + spacing * 0.3
	var g3 = Vector2(stem_x + spacing * 0.4, center_y + spacing * 0.3)
	for i in range(11):
		var t = i / 10.0
		var mt = 1.0 - t
		var pt = mt*mt*mt * g0 + 3.0*mt*mt*t * g1 + 3.0*mt*t*t * g2 + t*t*t * g3
		g_points.append(pt)
	
	# Curl around Sol line: E4 (y = center_y + 2*spacing) and Sol4 (y = center_y + spacing)
	var curl_points = PackedVector2Array()
	var c0 = g3
	# Loop left and down around the second line (y = center_y + spacing)
	var c1 = c0 + Vector2(-spacing * 1.1, -spacing * 0.9)
	var c2 = c0 + Vector2(-spacing * 0.9, spacing * 0.9)
	var c3 = Vector2(stem_x - spacing * 0.1, center_y + spacing * 1.25)
	for i in range(11):
		var t = i / 10.0
		var mt = 1.0 - t
		var pt = mt*mt*mt * c0 + 3.0*mt*mt*t * c1 + 3.0*mt*t*t * c2 + t*t*t * c3
		curl_points.append(pt)
		
	# Terminating inner curl loop
	var term_points = PackedVector2Array()
	var d0 = c3
	var d1 = d0 + Vector2(spacing * 0.5, -spacing * 0.4)
	var d2 = d0 + Vector2(spacing * 0.4, spacing * 0.4)
	var d3 = Vector2(stem_x, center_y + spacing * 1.0)
	for i in range(11):
		var t = i / 10.0
		var mt = 1.0 - t
		var pt = mt*mt*mt * d0 + 3.0*mt*mt*t * d1 + 3.0*mt*t*t * d2 + t*t*t * d3
		term_points.append(pt)
		
	var all_g_curves = PackedVector2Array()
	all_g_curves.append_array(g_points)
	all_g_curves.append_array(curl_points)
	all_g_curves.append_array(term_points)
	draw_polyline(all_g_curves, color, max(3.5, spacing * 0.08), true)

