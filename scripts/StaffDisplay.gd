extends Control

const NOTE_POSITIONS = {
	"Đô": -1.0,
	"Rê": -0.5,
	"Mi": 0.0,
	"Fa": 0.5,
	"Sol": 1.0,
	"La": 1.5,
	"Si": 2.0,
	"Đô2": 2.5,
	"Rê2": 3.0,
	"Mi2": 3.5,
	"Sol2": 4.5
}

var active_note = "Đô"
var line_spacing = 60.0
var clef_tex: Texture2D
var bg_tex: Texture2D

func _ready():
	if ResourceLoader.exists("res://image/khung nhav.png"):
		bg_tex = load("res://image/khung nhav.png")
	elif ResourceLoader.exists("res://assets/textures/treble_clef.svg"):
		clef_tex = load("res://assets/textures/treble_clef.svg")
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
	
	if bg_tex:
		# Calculate scale so that the image's line spacing (44.5) matches our target line_spacing (60.0)
		var s = line_spacing / 44.5
		var w = bg_tex.get_width() * s
		var h = bg_tex.get_height() * s
		# The center line of the staff in the image is at Y=435
		var dest_x = (size.x - w) / 2.0
		var dest_y = center_y - (435.0 * s)
		draw_texture_rect(bg_tex, Rect2(dest_x, dest_y, w, h), false)
	else:
		# Draw 5 lines (0 is bottom line, 4 is top line)
		for i in range(5):
			var y = center_y + (2 - i) * line_spacing
			draw_line(Vector2(start_x, y), Vector2(end_x, y), line_color, 2.0, true)
			
		# Draw treble clef
		if clef_tex:
			var clef_w = line_spacing * 3.5
			var clef_h = line_spacing * 7.5
			var clef_y = center_y - clef_h * 0.45
			# Draw clef near the left edge, before hit line
			draw_texture_rect(clef_tex, Rect2(hit_line_x - clef_w - 20, clef_y, clef_w, clef_h), false)
			
	# Draw hit line
	draw_line(Vector2(hit_line_x, center_y - 3 * line_spacing), Vector2(hit_line_x, center_y + 3 * line_spacing), Color(0.2, 0.8, 0.2, 0.5), 4.0, true)
		
	# Draw all notes
	for note_data in notes_to_draw:
		var n_name = note_data.get("note", "Đô")
		var n_x = note_data.get("x", size.x / 2.0)
		var n_color = note_data.get("color", Color(0.1, 0.1, 0.1, 1.0))
		_draw_single_note(n_name, n_x, center_y, n_color, line_color)

func _draw_single_note(note_name: String, note_x: float, center_y: float, note_color: Color, line_color: Color):
	if not NOTE_POSITIONS.has(note_name): return
	var pos_idx = NOTE_POSITIONS[note_name]
	var note_y = center_y + (2 - pos_idx) * line_spacing
	
	var note_width = line_spacing * 1.2
	var note_height = line_spacing * 0.85

	# Draw ledger lines if outside staff
	if pos_idx < 0:
		var ledgers = int(floor(-pos_idx))
		for i in range(1, ledgers + 1):
			var ly = center_y + (2 + i) * line_spacing
			draw_line(Vector2(note_x - note_width, ly), Vector2(note_x + note_width, ly), line_color, 2.0, true)
	elif pos_idx > 4:
		var ledgers = int(floor(pos_idx - 4))
		for i in range(1, ledgers + 1):
			var ly = center_y + (2 - 4 - i) * line_spacing
			draw_line(Vector2(note_x - note_width, ly), Vector2(note_x + note_width, ly), line_color, 2.0, true)
			
	# Draw note head (rotated ellipse)
	var note_rect = Rect2(note_x - note_width/2.0, note_y - note_height/2.0, note_width, note_height)
	_draw_rotated_ellipse(note_rect, deg_to_rad(-20), note_color)
	
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
