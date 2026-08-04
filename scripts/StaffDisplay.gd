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
	
	# Dan Tranh specific mappings ()
	"Sol_1": -2.0,
	"La_1": -1.5,
	"Đô_2": -1.0,
	"Rê_2": -0.5,
	"Mi_2": 0.0,
	"Sol_2": 1.0,
	"La_2": 1.5,
	"Đô_3": 2.5,
	"Rê_3": 3.0,
	"Mi_3": 3.5,
	"Sol_3": 4.5,
	"La_3": 5.0,
	"Đô_4": 6.0,
	"Rê_4": 6.5,
	"Mi_4": 7.0,
	"Sol_4": 8.0,
	"La_4": 8.5
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

func set_note(note_name: String):
	active_note = note_name
	queue_redraw()

func set_notes(notes: Array):
	notes_to_draw = notes
	queue_redraw()

func _draw():
	var center_y = size.y / 2.0
	
	var start_x = 35.0
	var end_x = size.x - 35.0
	hit_line_x = size.x * 0.25 # Hit line at 25% of screen
	
	var line_color = Color(0.2, 0.18, 0.15, 0.95)
	
	# Draw 5 lines (0 is bottom line, 4 is top line)
	for i in range(5):
		var y = center_y + (2 - i) * line_spacing
		draw_line(Vector2(start_x, y), Vector2(end_x, y), line_color, 3.2, true)
			
	# Treble clef drawing removed for synchronized clean staff design
			
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
		_draw_single_note(n_name, n_x, center_y, n_color, line_color, n_tail, n_cue)

func _draw_single_note(note_name: String, note_x: float, center_y: float, note_color: Color, line_color: Color, tail_w: float = 0.0, cue: String = ""):
	var clean_name = note_name
	if clean_name.begins_with("ZT_"):
		clean_name = clean_name.right(-3)
	
	var mapped_name = clean_name
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
	
	var is_zither = note_name.begins_with("ZT_")
	
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

	# Draw ledger lines if outside staff
	if pos_idx < 0:
		var ledgers = int(floor(-pos_idx))
		for i in range(1, ledgers + 1):
			var ly = center_y + (2 + i) * line_spacing
			draw_line(Vector2(note_x - note_width * 0.8, ly), Vector2(note_x + note_width * 0.8, ly), line_color, 3.0, true)
	elif pos_idx > 4:
		var ledgers = int(floor(pos_idx - 4))
		for i in range(1, ledgers + 1):
			var ly = center_y + (2 - 4 - i) * line_spacing
			draw_line(Vector2(note_x - note_width * 0.8, ly), Vector2(note_x + note_width * 0.8, ly), line_color, 3.0, true)
			
	# Draw duration tail (crisp horizontal bar with vertical tick marker)
	if tail_w > 0.0:
		var tail_start = note_x + note_width / 2.0 - 4.0 # slightly inside to avoid gaps
		var actual_tail_w = max(0.0, tail_w - (note_width / 2.0))
		if actual_tail_w > 0.0:
			var end_x_pos = tail_start + actual_tail_w
			draw_line(Vector2(tail_start, note_y), Vector2(end_x_pos, note_y), note_color, 4.5, true)
			var tick_h = line_spacing * 0.42
			draw_line(Vector2(end_x_pos, note_y - tick_h), Vector2(end_x_pos, note_y + tick_h), note_color, 4.0, true)
			
	# Draw soft radiating golden halo around notes
	var glow_color = note_color
	glow_color.a = 0.25
	draw_circle(Vector2(note_x, note_y), note_height * 0.82, glow_color)
	glow_color.a = 0.10
	draw_circle(Vector2(note_x, note_y), note_height * 1.25, glow_color)
			
	# Draw note head (rotated ellipse)
	var note_rect = Rect2(note_x - note_width/2.0, note_y - note_height/2.0, note_width, note_height)
	_draw_rotated_ellipse(note_rect, deg_to_rad(-18), note_color)
	
	# Draw fingering cues inside the note if available, else draw text
	if cue != "":
		var center_pt = Vector2(note_x, note_y)
		var symbol_color = Color.WHITE
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
			draw_string(font, text_pos, display_name, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.WHITE)
	
	# Draw stem only for short melodic notes without duration tail
	if tail_w <= 0.0:
		var stem_len = line_spacing * 2.2
		var stem_w = max(2.5, line_spacing * 0.08)
		if pos_idx < 2.0:
			var stem_x = note_x + note_width/2.0 - 2.0
			draw_line(Vector2(note_x + note_width/2.0 - 2.0, note_y), Vector2(note_x + note_width/2.0 - 2.0, note_y - stem_len), note_color, stem_w, true)
		else:
			var stem_x = note_x - note_width/2.0 + 2.0
			draw_line(Vector2(note_x - note_width/2.0 + 2.0, note_y), Vector2(note_x - note_width/2.0 + 2.0, note_y + stem_len), note_color, stem_w, true)

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
