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
	custom_minimum_size = Vector2(0, 190)
	queue_redraw()

func _draw() -> void:
	var width := maxf(size.x, 320.0)
	var center_y := size.y * 0.47
	var spacing := 15.0
	var staff_color := Color("#34415e")
	for i in range(5):
		draw_line(Vector2(20, center_y + (float(i) - 2.0) * spacing), Vector2(width - 20, center_y + (float(i) - 2.0) * spacing), staff_color, 2.0, true)
	draw_arc(Vector2(48, center_y - 5), 18, -2.2, 2.0, 28, Color("#172f75"), 3.0, true)
	draw_line(Vector2(51, center_y - 42), Vector2(51, center_y + 43), Color("#172f75"), 3.0, true)

	if notes.is_empty():
		return
	var usable_width := width - 110.0
	var step_x := usable_width / float(maxi(1, notes.size() - 1))
	for i in notes.size():
		var note_value := notes[i]
		var is_missing := i == missing_index
		var x := 95.0 + step_x * float(i)
		var pitch := _pitch_step(note_value)
		var y := center_y - float(pitch) * spacing * 0.5
		var color := Color("#e7ae22") if is_missing and not answer_visible else Color("#2d76df")
		if is_missing and answer_visible:
			color = Color("#239653") if answer_correct else Color("#e04a43")
		_draw_note_head(Vector2(x, y), Vector2(11, 8), color)
		draw_line(Vector2(x + 9, y), Vector2(x + 9, y - 34), color.darkened(0.25), 3.0, true)
		if is_missing and not answer_visible:
			draw_string(ThemeDB.fallback_font, Vector2(x - 20, size.y - 18), "?", HORIZONTAL_ALIGNMENT_CENTER, 40, 18, Color("#e7ae22"))
		elif is_missing and answer_visible:
			draw_string(ThemeDB.fallback_font, Vector2(x - 35, size.y - 18), note_value, HORIZONTAL_ALIGNMENT_CENTER, 70, 15, color)
			if not answer_correct:
				draw_string(ThemeDB.fallback_font, Vector2(x - 35, size.y - 2), "Chọn: " + selected_note, HORIZONTAL_ALIGNMENT_CENTER, 100, 12, Color("#e04a43"))

func _draw_note_head(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(32):
		var angle := TAU * float(i) / 32.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)

func _pitch_step(value: String) -> int:
	var root := value.to_lower().replace("đô", "do").replace("đố", "do").replace("đồ", "do")
	var octave := 4
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
