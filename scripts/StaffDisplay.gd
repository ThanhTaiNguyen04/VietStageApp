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

func _ready():
	if ResourceLoader.exists("res://image/khung nhav.png"):
		clef_tex = load("res://image/khung nhav.png")
	resized.connect(queue_redraw)

var notes_to_draw: Array = []
var hit_line_x: float = 300.0 # Will be updated in _draw
var beats_per_measure: int = 4
var show_metronome: bool = true
var current_bpm: float = 60.0  # Updated by LessonSaoTruc to match bpm_multiplier
var bar_lines: Array = []

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
		# Adjust 𝄞 position so the swirl circles the G line (2nd line from bottom)
		draw_string(font, Vector2(10, center_y + line_spacing * 2.35), "𝄞", HORIZONTAL_ALIGNMENT_LEFT, -1, int(line_spacing * 6.5), Color.BLACK)
		
		# Time signature dynamic
		var ts = str(beats_per_measure)
		draw_string(font, Vector2(120, center_y - line_spacing * 0.05), ts, HORIZONTAL_ALIGNMENT_LEFT, -1, int(line_spacing * 1.6), Color.BLACK)
		draw_string(font, Vector2(120, center_y + line_spacing * 1.95), "4", HORIZONTAL_ALIGNMENT_LEFT, -1, int(line_spacing * 1.6), Color.BLACK)
			
	# Draw hit line with modern glowing effect (kept as it is for timing)
	draw_line(Vector2(hit_line_x, center_y - 3.2 * line_spacing), Vector2(hit_line_x, center_y + 3.2 * line_spacing), Color(0.3, 0.9, 0.4, 0.3), 8.0, true)
	draw_line(Vector2(hit_line_x, center_y - 3.2 * line_spacing), Vector2(hit_line_x, center_y + 3.2 * line_spacing), Color(0.2, 0.85, 0.3, 0.95), 3.5, true)
		
	# Draw all notes
	for note_data in notes_to_draw:
		var n_name = note_data.get("note", "Đô")
		var n_x = note_data.get("x", size.x / 2.0)
		var n_color = Color.BLACK # Force note color to black for all level 2 lessons
		var n_tail = note_data.get("tail", 0.0)
		var n_cue = note_data.get("cue", "")
		var n_type = note_data.get("type", "quarter")
		var flash_t = note_data.get("flash_trigger", 0.0)
		_draw_single_note(n_name, n_x, center_y, n_color, line_color, n_tail, n_cue, n_type, flash_t)
		
	# Draw measure bar lines
	for bx in bar_lines:
		var top_y = center_y - 2 * line_spacing
		var bot_y = center_y + 2 * line_spacing
		draw_line(Vector2(bx, top_y), Vector2(bx, bot_y), line_color, 2.0, true)
		
	# Draw 4-beat Metronome above the hit line
	if show_metronome:
		var beat_time_total = Time.get_ticks_msec() / 1000.0 * (current_bpm / 60.0)
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

func _draw_single_note(note_name: String, note_x: float, center_y: float, note_color: Color, line_color: Color, tail_w: float = 0.0, cue: String = "", note_type: String = "quarter", flash_t: float = 0.0):
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
	
	var scale_mod = 1.0
	if flash_t > 0.0:
		var elapsed = Time.get_ticks_msec() - flash_t
		if elapsed < 400: # 400ms flash
			var progress = elapsed / 400.0
			scale_mod = 1.0 + sin(progress * PI) * 0.6 # Pulses up to 1.6x size
			note_color = Color(1.0, 0.3, 0.3).lerp(note_color, progress)
			
	var note_width = line_spacing * (1.15 if is_zither else 1.35) * scale_mod
	var note_height = line_spacing * (0.8 if is_zither else 0.95) * scale_mod

	# Draw ledger lines for notes outside the 5-line staff
	if pos_idx < -0.9: # below first ledger line threshold (pos_idx <= -1.0)
		var num_ledgers = int(abs(ceil(pos_idx)))
		for i in range(1, num_ledgers + 1):
			var ld = -i
			var ly = center_y + (2 - ld) * line_spacing
			draw_line(Vector2(note_x - note_width * 0.8, ly), Vector2(note_x + note_width * 0.8, ly), line_color, 3.0, true)
	elif pos_idx > 4.9: # above first ledger line threshold (pos_idx >= 5.0)
		var num_ledgers = int(floor(pos_idx)) - 4
		for i in range(1, num_ledgers + 1):
			var ld = 4 + i
			var ly = center_y + (2 - ld) * line_spacing
			draw_line(Vector2(note_x - note_width * 0.8, ly), Vector2(note_x + note_width * 0.8, ly), line_color, 3.0, true)
			
	# Draw duration tail
	if tail_w > 0.0:
		var tail_y = note_y
		var tail_color = note_color
		tail_color.a = 0.35 # Semi-transparent
		var tail_h = line_spacing * 0.4
		draw_rect(Rect2(note_x + note_width / 2.5, tail_y - tail_h / 2.0, tail_w, tail_h), tail_color)
			
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
			var flag_h = stem_len * 0.4
			var hook_dir = 1.0 if is_stem_up else -1.0
			
			# Flag 1
			var f1_start = Vector2(stem_x, stem_end_y)
			var f1_end = Vector2(stem_x + flag_w, stem_end_y + flag_h * hook_dir)
			draw_line(f1_start, f1_end, note_color, stem_w, true)
			
			# Flag 2
			if note_type == "sixteenth":
				var f2_start = Vector2(stem_x, stem_end_y + stem_len * 0.2 * hook_dir)
				var f2_end = Vector2(stem_x + flag_w, f2_start.y + flag_h * hook_dir)
				draw_line(f2_start, f2_end, note_color, stem_w, true)

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