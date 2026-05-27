extends Button

enum TabType { MENU, LESSON, SONG, GAME }

@export var current_type: TabType = TabType.MENU
@export var is_active: bool = false

# Colors
const C_RED_SON     := Color(0.72, 0.12, 0.08, 1.0)
const C_RED_SON_DK  := Color(0.38, 0.06, 0.04, 0.95)
const C_GOLD        := Color(0.95, 0.72, 0.18, 1.0)
const C_GOLD_LIGHT  := Color(1.00, 0.87, 0.45, 1.0)
const C_CREAM       := Color(1.00, 0.97, 0.88, 1.0)
const C_CREAM_DIM   := Color(0.80, 0.76, 0.66, 1.0)

func _ready() -> void:
	# Shift text to the right to make room for vector drawing
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	if current_type == TabType.LESSON:
		text = "Bài học"
		add_theme_font_size_override("font_size", 20)
	elif current_type == TabType.SONG:
		text = "Bài hát"
		add_theme_font_size_override("font_size", 20)
	elif current_type == TabType.GAME:
		text = "Trò chơi"
		add_theme_font_size_override("font_size", 20)
	elif current_type == TabType.MENU:
		text = "" # No text for menu button, just custom drawn lines!
		
	# Redraw on size/process
	item_rect_changed.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	var h := size.y
	var r := Vector2(32, h / 2.0) # Position of the icon center
	
	var active_color := C_GOLD if is_active else C_CREAM_DIM
	if is_hovered():
		active_color = C_GOLD_LIGHT if is_active else C_CREAM
		
	if current_type == TabType.MENU:
		# Draw three gorgeous rounded horizontal hamburger menu bars!
		var bar_w := 26.0
		var bar_h := 3.5
		var gap := 7.0
		var mc := Vector2(size.x / 2.0, size.y / 2.0) # Centered
		
		# Shadow
		var s_color := Color(0, 0, 0, 0.35)
		draw_rect(Rect2(mc + Vector2(-bar_w/2, -bar_h/2 - gap + 1.5), Vector2(bar_w, bar_h)), s_color, true)
		draw_rect(Rect2(mc + Vector2(-bar_w/2, -bar_h/2 + 1.5), Vector2(bar_w, bar_h)), s_color, true)
		draw_rect(Rect2(mc + Vector2(-bar_w/2, -bar_h/2 + gap + 1.5), Vector2(bar_w, bar_h)), s_color, true)
		
		# Main bars
		var m_color := C_GOLD_LIGHT if is_hovered() else C_CREAM
		draw_rect(Rect2(mc + Vector2(-bar_w/2, -bar_h/2 - gap), Vector2(bar_w, bar_h)), m_color, true)
		draw_rect(Rect2(mc + Vector2(-bar_w/2, -bar_h/2), Vector2(bar_w, bar_h)), m_color, true)
		draw_rect(Rect2(mc + Vector2(-bar_w/2, -bar_h/2 + gap), Vector2(bar_w, bar_h)), m_color, true)
		
	elif current_type == TabType.LESSON:
		# Draw a beautiful graduation cap!
		# Cap shadow
		_draw_cap(r + Vector2(0, 2), Color(0.04, 0.02, 0.01, 0.45))
		# Cap main
		_draw_cap(r, active_color)
		
	elif current_type == TabType.SONG:
		# Draw a beautiful beamed double note!
		# Note shadow
		_draw_double_note(r + Vector2(0, 2), Color(0.04, 0.02, 0.01, 0.45))
		# Note main
		_draw_double_note(r, active_color)
	elif current_type == TabType.GAME:
		# Draw a beautiful retro game controller!
		_draw_controller(r + Vector2(0, 2), Color(0.04, 0.02, 0.01, 0.45))
		_draw_controller(r, active_color)

func _draw_cap(pos: Vector2, color: Color) -> void:
	# Rhombus cap board
	var pts := PackedVector2Array([
		pos + Vector2(0, -9),
		pos + Vector2(15, -2),
		pos + Vector2(0, 5),
		pos + Vector2(-15, -2)
	])
	draw_colored_polygon(pts, color)
	
	# Cap base band below
	var base_pts := PackedVector2Array([
		pos + Vector2(-8, 1),
		pos + Vector2(8, 1),
		pos + Vector2(6, 6),
		pos + Vector2(-6, 6)
	])
	draw_colored_polygon(base_pts, color)
	
	# Cute tassel hanging down right side
	draw_line(pos + Vector2(0, -2), pos + Vector2(11, 3), color, 2.0, true)
	draw_circle(pos + Vector2(11, 5), 2.5, color)

func _draw_double_note(pos: Vector2, color: Color) -> void:
	# Two note heads
	draw_circle(pos + Vector2(-6, 6), 4.0, color)
	draw_circle(pos + Vector2(6, 4), 4.0, color)
	
	# Two stems
	draw_line(pos + Vector2(-2.5, 6), pos + Vector2(-2.5, -6), color, 2.0, true)
	draw_line(pos + Vector2(9.5, 4), pos + Vector2(9.5, -8), color, 2.0, true)
	
	# Connecting diagonal beam at the top
	var beam_pts := PackedVector2Array([
		pos + Vector2(-2.5, -6),
		pos + Vector2(9.5, -8),
		pos + Vector2(9.5, -4.5),
		pos + Vector2(-2.5, -2.5)
	])
	draw_colored_polygon(beam_pts, color)

func _draw_controller(pos: Vector2, color: Color) -> void:
	# Main body (capsule/rounded rect)
	var body_rect := Rect2(pos + Vector2(-10, -5), Vector2(20, 10))
	draw_rect(body_rect, color, true)
	draw_circle(pos + Vector2(-10, 0), 5.0, color)
	draw_circle(pos + Vector2(10, 0), 5.0, color)
	
	# D-pad (small cross inside)
	var dpad_col := C_RED_SON_DK if color != Color(0.04, 0.02, 0.01, 0.45) else Color(0.12, 0.06, 0.03, 0.8)
	draw_line(pos + Vector2(-9, 0), pos + Vector2(-5, 0), dpad_col, 2.0, true)
	draw_line(pos + Vector2(-7, -2), pos + Vector2(-7, 2), dpad_col, 2.0, true)
	
	# Action buttons
	draw_circle(pos + Vector2(6, -1.5), 1.5, dpad_col)
	draw_circle(pos + Vector2(9, 1.5), 1.5, dpad_col)
