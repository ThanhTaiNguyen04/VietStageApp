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
var line_spacing = 24.0
var clef_tex: Texture2D

func _ready():
	if ResourceLoader.exists("res://assets/textures/treble_clef.svg"):
		clef_tex = load("res://assets/textures/treble_clef.svg")

func set_note(note_name: String):
	active_note = note_name
	queue_redraw()

func _draw():
	var center_y = size.y / 2.0
	# Staff has 5 lines, centered.
	# Line 3 (middle line) is at center_y.
	# Line 1 (bottom) is at center_y + 2 * line_spacing
	# Line 5 (top) is at center_y - 2 * line_spacing
	
	var staff_width = size.x * 0.8
	var start_x = (size.x - staff_width) / 2.0
	var end_x = start_x + staff_width
	
	var line_color = Color(0.1, 0.1, 0.1, 1.0)
	var note_color = Color(0.1, 0.1, 0.1, 1.0)
	
	# Draw 5 lines (0 is bottom line, 4 is top line)
	for i in range(5):
		var y = center_y + (2 - i) * line_spacing
		draw_line(Vector2(start_x, y), Vector2(end_x, y), line_color, 2.0, true)
		
	# Draw treble clef
	if clef_tex:
		# Position it on the left side of the staff
		var clef_w = line_spacing * 3.5
		var clef_h = line_spacing * 7.5
		var clef_y = center_y - clef_h * 0.45
		draw_texture_rect(clef_tex, Rect2(start_x + 20, clef_y, clef_w, clef_h), false)
		
	# Draw note
	if NOTE_POSITIONS.has(active_note):
		var pos_idx = NOTE_POSITIONS[active_note]
		var note_x = size.x / 2.0
		# pos_idx = 0 is bottom line (i=0) -> center_y + 2 * line_spacing
		var note_y = center_y + (2 - pos_idx) * line_spacing
		
		# Draw ledger lines if outside staff
		if pos_idx < 0:
			var ledgers = int(floor(-pos_idx))
			for i in range(1, ledgers + 1):
				var ly = center_y + (2 + i) * line_spacing
				draw_line(Vector2(note_x - 30, ly), Vector2(note_x + 30, ly), line_color, 2.0, true)
		elif pos_idx > 4:
			var ledgers = int(floor(pos_idx - 4))
			for i in range(1, ledgers + 1):
				var ly = center_y + (2 - 4 - i) * line_spacing
				draw_line(Vector2(note_x - 30, ly), Vector2(note_x + 30, ly), line_color, 2.0, true)
				
		# Draw note head (rotated ellipse)
		var note_rect = Rect2(note_x - 14, note_y - 10, 28, 20)
		_draw_rotated_ellipse(note_rect, deg_to_rad(-20), note_color)
		
		# Draw stem
		var stem_len = line_spacing * 3.0
		if pos_idx < 2.0:
			var stem_x = note_x + 12
			draw_line(Vector2(stem_x, note_y), Vector2(stem_x, note_y - stem_len), note_color, 3.0, true)
		else:
			var stem_x = note_x - 12
			draw_line(Vector2(stem_x, note_y), Vector2(stem_x, note_y + stem_len), note_color, 3.0, true)

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
