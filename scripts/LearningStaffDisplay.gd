extends Control

var note_name := "Sol"
var note_octave := 4

func set_note(value: String) -> void:
	note_name = value
	var digits := RegEx.new()
	digits.compile("[0-9]+")
	var match := digits.search(value)
	if match:
		note_octave = clampi(int(match.get_string()), 3, 6)
	queue_redraw()

func _ready() -> void:
	custom_minimum_size = Vector2(0, 138)
	queue_redraw()

func _draw() -> void:
	var width := maxf(size.x, 260.0)
	var center_y := size.y * 0.52
	var spacing := 15.0
	var staff_color := Color("#34415e")
	for i in range(5):
		var y := center_y + (float(i) - 2.0) * spacing
		draw_line(Vector2(30, y), Vector2(width - 30, y), staff_color, 2.0, true)

	# Treble-clef approximation kept intentionally light and readable at phone size.
	draw_arc(Vector2(58, center_y - 5), 18, -2.2, 2.0, 28, Color("#172f75"), 3.0, true)
	draw_line(Vector2(61, center_y - 42), Vector2(61, center_y + 43), Color("#172f75"), 3.0, true)

	var pitch_step := _pitch_step(note_name)
	var note_y := center_y - pitch_step * (spacing * 0.5)
	var note_x := clampf(width * 0.58, 150.0, width - 100.0)
	_draw_note_head(Vector2(note_x, note_y), Vector2(12, 8), Color("#2d76df"))
	draw_line(Vector2(note_x + 10, note_y), Vector2(note_x + 10, note_y - 38), Color("#172f75"), 3.0, true)
	if note_y < center_y - spacing * 2.0:
		draw_line(Vector2(note_x - 17, center_y + spacing * 2.0), Vector2(note_x + 17, center_y + spacing * 2.0), Color("#34415e"), 2.0, true)

func _draw_note_head(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(32):
		var angle := TAU * float(i) / 32.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)

func _pitch_step(value: String) -> int:
	var root := value.to_lower().replace("đô", "do").replace("đố", "do").replace("đồ", "do")
	var octave := note_octave
	var digits := RegEx.new()
	digits.compile("[0-9]+")
	var match := digits.search(root)
	if match:
		octave = int(match.get_string())
	var step := 0
	if root.begins_with("do"): step = 0
	elif root.begins_with("rê") or root.begins_with("re"): step = 1
	elif root.begins_with("mi"): step = 2
	elif root.begins_with("fa"): step = 3
	elif root.begins_with("sol"): step = 4
	elif root.begins_with("la"): step = 5
	else: step = 6
	return (octave - 4) * 7 + step - 2
