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
	
	# Dan Tranh specific mappings (ZT_)
	"ZT_Sol1": -2.0,
	"ZT_La1": -1.5,
	"ZT_Đô2": -1.0,
	"ZT_Rê2": -0.5,
	"ZT_Mi2": 0.0,
	"ZT_Sol2": 1.0,
	"ZT_La2": 1.5,
	"ZT_Đô3": 2.5,
	"ZT_Rê3": 3.0,
	"ZT_Mi3": 3.5,
	"ZT_Sol3": 4.5,
	"ZT_La3": 5.0,
	"ZT_Đô4": 6.0,
	"ZT_Rê4": 6.5,
	"ZT_Mi4": 7.0,
	"ZT_Sol4": 8.0,
	"ZT_La4": 8.5
}

var active_note = "Đô"
var line_spacing = 110.0
var clef_tex: Texture2D

func _ready():
	if ResourceLoader.exists("res://image/khungnhac.png"):
		clef_tex = load("res://image/khungnhac.png")
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
	
	var start_x = 0.0
	var end_x = size.x
	hit_line_x = size.x * 0.25 # Hit line at 25% of screen
	
	var line_color = Color(0.1, 0.1, 0.1, 1.0)
	
	# Draw 5 lines (0 is bottom line, 4 is top line)
	for i in range(5):
		var y = center_y + (2 - i) * line_spacing
		draw_line(Vector2(start_x, y), Vector2(end_x, y), line_color, 3.5, true)
			
		# Draw treble clef
		if clef_tex:
			var clef_w = line_spacing * 3.5
			var clef_h = line_spacing * 7.5
			var clef_y = center_y - clef_h * 0.45
			# Draw clef near the left edge, before hit line
			draw_texture_rect(clef_tex, Rect2(hit_line_x - clef_w - 20, clef_y, clef_w, clef_h), false)
			
	# Draw hit line
	draw_line(Vector2(hit_line_x, center_y - 3 * line_spacing), Vector2(hit_line_x, center_y + 3 * line_spacing), Color(0.2, 0.8, 0.2, 0.6), 5.0, true)
		
	# Draw all notes
	for note_data in notes_to_draw:
		var n_name = note_data.get("note", "Đô")
		var n_x = note_data.get("x", size.x / 2.0)
		var n_color = note_data.get("color", Color(0.1, 0.1, 0.1, 1.0))
		var n_tail = note_data.get("tail", 0.0)
		var n_cue = note_data.get("cue", "")
		_draw_single_note(n_name, n_x, center_y, n_color, line_color, n_tail, n_cue)

func _draw_single_note(note_name: String, note_x: float, center_y: float, note_color: Color, line_color: Color, tail_w: float = 0.0, cue: String = ""):
	if not NOTE_POSITIONS.has(note_name): return
	var pos_idx = NOTE_POSITIONS[note_name]
	var note_y = center_y + (2 - pos_idx) * line_spacing
	
	var note_width = line_spacing * 1.35
	var note_height = line_spacing * 0.95

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
			
	# Draw duration tail
	if tail_w > 0.0:
		var tail_start = note_x + note_width / 2.0 - 5.0 # slightly inside to avoid gaps
		var actual_tail_w = max(0.0, tail_w - (note_width / 2.0))
		if actual_tail_w > 0.0:
			var tail_rect = Rect2(tail_start, note_y - note_height/6.0, actual_tail_w + 5.0, note_height/3.0)
			var tail_color = note_color
			tail_color.a = 0.4
			draw_rect(tail_rect, tail_color, true)
			# Draw end marker
			draw_line(Vector2(tail_start + actual_tail_w + 5.0, note_y - note_height/2.0), Vector2(tail_start + actual_tail_w + 5.0, note_y + note_height/2.0), note_color, 4.0, true)
			
	# Draw note head (rotated ellipse)
	var note_rect = Rect2(note_x - note_width/2.0, note_y - note_height/2.0, note_width, note_height)
	_draw_rotated_ellipse(note_rect, deg_to_rad(-20), note_color)
	
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
			var font_size = int(line_spacing * 0.48)
			var str_size = font.get_string_size(note_name, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
			var text_pos = Vector2(note_x - str_size.x / 2.0, note_y + str_size.y * 0.35)
			draw_string(font, text_pos, note_name, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.WHITE)
	
	# Draw stem
	var stem_len = line_spacing * 3.0
	var stem_w = max(2.0, line_spacing * 0.1)
	if pos_idx < 2.0:
		var stem_x = note_x + note_width/2.0 - 2.0
		draw_line(Vector2(stem_x, note_y), Vector2(stem_x, note_y - stem_len), note_color, stem_w, true)
	else:
		var stem_x = note_x - note_width/2.0 + 2.0
		draw_line(Vector2(stem_x, note_y), Vector2(stem_x, note_y + stem_len), note_color, stem_w, true)

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
