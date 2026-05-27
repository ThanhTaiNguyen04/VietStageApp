extends PanelContainer

enum IconType { PLAY, CHECK, LOCK, MUSIC }

var current_type: IconType = IconType.LOCK

# Colors
const C_RED_SON     := Color(0.72, 0.12, 0.08, 1.0)
const C_RED_SON_DK  := Color(0.38, 0.06, 0.04, 0.95)
const C_GOLD        := Color(0.95, 0.72, 0.18, 1.0)
const C_GOLD_LIGHT  := Color(1.00, 0.87, 0.45, 1.0)
const C_JADE        := Color(0.18, 0.62, 0.42, 1.0)
const C_JADE_LIGHT  := Color(0.35, 0.85, 0.60, 1.0)
const C_CREAM       := Color(1.00, 0.97, 0.88, 1.0)

func _ready() -> void:
	# Hide the Label if it exists
	if has_node("IconText"):
		get_node("IconText").visible = false
	
	# Redraw
	queue_redraw()

func set_type(type: IconType) -> void:
	current_type = type
	queue_redraw()

func _draw() -> void:
	var r := size / 2.0
	
	if current_type == IconType.PLAY:
		# Draw a beautiful sharp play triangle pointing right
		var pts := PackedVector2Array([
			r + Vector2(-5, -7),
			r + Vector2(8, 0),
			r + Vector2(-5, 7)
		])
		draw_colored_polygon(pts, C_RED_SON_DK)
	elif current_type == IconType.CHECK:
		# Draw a clean vector checkmark
		var pts := PackedVector2Array([
			r + Vector2(-8, 0),
			r + Vector2(-2, 6),
			r + Vector2(8, -4),
			r + Vector2(8, -1),
			r + Vector2(-2, 9),
			r + Vector2(-8, 3)
		])
		draw_colored_polygon(pts, C_CREAM)
	elif current_type == IconType.LOCK:
		# Draw a gorgeous cartoon-style padlock
		var body_color := Color(C_CREAM.r, C_CREAM.g, C_CREAM.b, 0.5)
		# Padlock shackle (u-shape line)
		draw_arc(r + Vector2(0, -2), 5.0, PI, 0, 12, body_color, 2.0, true)
		draw_line(r + Vector2(-5, -2), r + Vector2(-5, 1), body_color, 2.0, true)
		draw_line(r + Vector2(5, -2), r + Vector2(5, 1), body_color, 2.0, true)
		# Padlock body (rounded rect)
		var body_rect := Rect2(r + Vector2(-7, 0), Vector2(14, 10))
		draw_rect(body_rect, body_color, true)
	elif current_type == IconType.MUSIC:
		# Draw a stylized vector eighth note
		var note_color := C_CREAM
		# Note head
		draw_circle(r + Vector2(-3, 4), 3.5, note_color)
		# Stem
		draw_line(r + Vector2(0.5, 4), r + Vector2(0.5, -6), note_color, 2.0, true)
		# Flag
		var flag_pts := PackedVector2Array([
			r + Vector2(0.5, -6),
			r + Vector2(5.5, -3.5),
			r + Vector2(0.5, -1),
		])
		draw_colored_polygon(flag_pts, note_color)
