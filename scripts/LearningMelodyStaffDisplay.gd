extends Control

var notes: Array[String] = []
var missing_index := -1
var answer_visible := false
var answer_correct := false
var selected_note := ""

func configure(note_values: Array, missing: int) -> void:
	notes.clear()
	for value: Variant in note_values:
		notes.append(str(value))
	missing_index = missing
	answer_visible = false
	queue_redraw()

func show_answer(correct: bool, selected: String) -> void:
	answer_visible = true
	answer_correct = correct
	selected_note = selected
	queue_redraw()

func _ready() -> void:
	custom_minimum_size = Vector2(0, 260)
	queue_redraw()

func _draw() -> void:
	var width := maxf(size.x, 320.0)
	var center_y := size.y * 0.45
	var spacing := 30.0
	var staff_color := Color.BLACK
	for i in range(5):
		draw_line(Vector2(20, center_y + (float(i) - 2.0) * spacing), Vector2(width - 20, center_y + (float(i) - 2.0) * spacing), staff_color, 3.5, true)

	var font := ThemeDB.fallback_font
	if not font:
		var dt = ThemeDB.get_default_theme()
		if dt:
			font = dt.get_default_font()

	if font:
		# Draw Treble Clef in solid black
		var clef_font_size := int(spacing * 6.5)
		var clef_y_offset := clef_font_size * 0.20
		draw_string(font, Vector2(20, center_y + clef_y_offset), "𝄞", HORIZONTAL_ALIGNMENT_LEFT, -1, clef_font_size, Color.BLACK)

		# Draw 4/4 Time Signature in solid black, shifted right to prevent overlap
		var ts_size := int(spacing * 1.5)
		var ts_x := 135.0
		# Top "4"
		var top_str := "4"
		var top_w := font.get_string_size(top_str, HORIZONTAL_ALIGNMENT_CENTER, -1, ts_size).x
		var top_pos := Vector2(ts_x - top_w/2.0, center_y - 0.05 * spacing)
		draw_string(font, top_pos, top_str, HORIZONTAL_ALIGNMENT_CENTER, -1, ts_size, Color.BLACK)
		# Bottom "4"
		var bottom_str := "4"
		var bottom_w := font.get_string_size(bottom_str, HORIZONTAL_ALIGNMENT_CENTER, -1, ts_size).x
		var bottom_pos := Vector2(ts_x - bottom_w/2.0, center_y + 1.35 * spacing)
		draw_string(font, bottom_pos, bottom_str, HORIZONTAL_ALIGNMENT_CENTER, -1, ts_size, Color.BLACK)

	if notes.is_empty():
		return
	var usable_width := width - 260.0
	var step_x := usable_width / float(maxi(1, notes.size() - 1))
	for i in notes.size():
		var note_value := notes[i]
		var is_missing := i == missing_index
		var x := 210.0 + step_x * float(i)
		var pitch := _pitch_step(note_value)
		var y := center_y - float(pitch - 4) * spacing * 0.5
		
		# Draw ledger lines below staff (e.g. Middle C / pitch = -2)
		if pitch <= -2:
			var num_ledgers := int(abs(pitch) / 2)
			for j in range(1, num_ledgers + 1):
				var ly := center_y + float(2 + j) * spacing
				draw_line(Vector2(x - 28, ly), Vector2(x + 28, ly), Color.BLACK, 3.5, true)
				
		# Draw ledger lines above staff (e.g. C6 / pitch = 12)
		elif pitch >= 10:
			var num_ledgers := int((pitch - 8) / 2)
			for j in range(1, num_ledgers + 1):
				var ly := center_y - float(2 + j) * spacing
				draw_line(Vector2(x - 28, ly), Vector2(x + 28, ly), Color.BLACK, 3.5, true)
		
		# Solid black for normal notes, golden for missing note, green/red for feedback
		var color := Color("#e7ae22") if is_missing and not answer_visible else Color.BLACK
		if is_missing and answer_visible:
			color = Color("#239653") if answer_correct else Color("#e04a43")
			
		# Rotated note head style for standard musical notation (large size 40x28)
		_draw_rotated_ellipse(Rect2(x - 20, y - 14, 40, 28), deg_to_rad(-20), color)
		
		# Stem line drawing (thick and long)
		draw_line(Vector2(x + 16, y), Vector2(x + 16, y - 60), color if is_missing else Color.BLACK, 5.0, true)
		
		if font:
			if is_missing and not answer_visible:
				draw_string(font, Vector2(x - 20, size.y - 24), "?", HORIZONTAL_ALIGNMENT_CENTER, 40, 26, Color("#e7ae22"))
			elif is_missing and answer_visible:
				draw_string(font, Vector2(x - 35, size.y - 24), note_value, HORIZONTAL_ALIGNMENT_CENTER, 70, 20, color)
				if not answer_correct:
					draw_string(font, Vector2(x - 45, size.y - 4), "Chọn: " + selected_note, HORIZONTAL_ALIGNMENT_CENTER, 100, 15, Color("#e04a43"))

func _draw_rotated_ellipse(rect: Rect2, angle: float, color: Color) -> void:
	var points := PackedVector2Array()
	var center := rect.get_center()
	var rx := rect.size.x / 2.0
	var ry := rect.size.y / 2.0
	var segments := 32
	for i in range(segments):
		var t := float(i) * TAU / float(segments)
		var p := Vector2(cos(t) * rx, sin(t) * ry)
		var rotated_p := Vector2(
			p.x * cos(angle) - p.y * sin(angle),
			p.x * sin(angle) + p.y * cos(angle)
		)
		points.append(center + rotated_p)
	draw_colored_polygon(points, color)

func _draw_note_head(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(32):
		var angle := TAU * float(i) / 32.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)

func _pitch_step(value: String) -> int:
	var root := value.to_lower().strip_edges()
	
	# Strip zither prefix if present
	if root.begins_with("zt_"):
		root = root.substr(3)
		
	var octave := 4
	var digits := RegEx.new()
	digits.compile("[0-9]+")
	var match := digits.search(root)
	if match:
		octave = int(match.get_string())
		
	# Shift zither-style octave (1, 2, 3, 4) to scientific notation octave (3, 4, 5, 6)
	if octave <= 4:
		octave += 2
		
	var step := 0
	if root.begins_with("c") or root.begins_with("do") or root.begins_with("đô") or root.begins_with("đồ") or root.begins_with("đố"):
		step = 0
	elif root.begins_with("d") or root.begins_with("re") or root.begins_with("rê") or root.begins_with("rề") or root.begins_with("rế"):
		step = 1
	elif root.begins_with("e") or root.begins_with("mi"):
		step = 2
	elif root.begins_with("f") or root.begins_with("fa"):
		step = 3
	elif root.begins_with("g") or root.begins_with("sol"):
		step = 4
	elif root.begins_with("a") or root.begins_with("la"):
		step = 5
	elif root.begins_with("b") or root.begins_with("si"):
		step = 6
	else:
		step = 4 # default to Sol if unrecognized
		
	return (octave - 4) * 7 + step - 2
