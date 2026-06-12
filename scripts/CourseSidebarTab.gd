extends Button

enum TabType { MENU, LESSON, SONG, GAME, ACCOUNT, ROOM }

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
	
	# Cleanly override content margin to push text away from the drawn icon
	for style_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb := get_theme_stylebox(style_name)
		if sb:
			var sb_dup := sb.duplicate()
			sb_dup.content_margin_left = 76
			add_theme_stylebox_override(style_name, sb_dup)

	var is_prem : bool = SecureDataManager.data.get("is_premium", false)
	var is_locked : bool = (current_type == TabType.SONG and not is_prem)

	if current_type == TabType.LESSON:
		text = "Khóa học"
		add_theme_font_size_override("font_size", 24)
	elif current_type == TabType.SONG:
		text = "Bài hát"
		add_theme_font_size_override("font_size", 24)
	elif current_type == TabType.GAME:
		text = "Trò chơi"
		add_theme_font_size_override("font_size", 24)
	elif current_type == TabType.ACCOUNT:
		text = "Hồ sơ"
		add_theme_font_size_override("font_size", 24)
	elif current_type == TabType.ROOM:
		text = "Phòng ảo"
		add_theme_font_size_override("font_size", 24)
	elif current_type == TabType.MENU:
		text = "" # No text for menu button, just custom drawn lines!

	add_theme_color_override("font_color", C_GOLD if is_active else (C_CREAM_DIM.darkened(0.35) if is_locked else C_CREAM_DIM))
	add_theme_color_override("font_hover_color", C_CREAM_DIM.darkened(0.2) if is_locked else C_CREAM)
	add_theme_color_override("font_pressed_color", C_GOLD if not is_locked else C_CREAM_DIM.darkened(0.35))
		
	# Redraw on size/process
	item_rect_changed.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	var h := size.y
	var r := Vector2(38, h / 2.0) # Position of the icon center (shifted right for scale)
	
	var is_prem : bool = SecureDataManager.data.get("is_premium", false)
	var is_locked : bool = (current_type == TabType.SONG and not is_prem)

	var active_color := C_GOLD if is_active else (C_CREAM_DIM.darkened(0.35) if is_locked else C_CREAM_DIM)
	if is_hovered():
		active_color = C_GOLD_LIGHT if is_active else (C_CREAM_DIM.darkened(0.2) if is_locked else C_CREAM)
		
	if current_type == TabType.MENU:
		# Draw three gorgeous rounded horizontal hamburger menu bars!
		var bar_w := 32.0
		var bar_h := 4.5
		var gap := 9.0
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

		# Overlay lock icon if locked
		if is_locked:
			var lx := r.x + 12.0
			var ly := r.y + 10.0
			# draw small lock
			draw_rect(Rect2(lx - 5, ly - 2, 10, 8), C_GOLD, true) # golden lock body
			draw_rect(Rect2(lx - 5, ly - 2, 10, 8), Color(0.07, 0.04, 0.015, 1.0), false, 1.0)
			draw_arc(Vector2(lx, ly - 2), 3.5, PI, TAU, 8, C_GOLD, 1.5, true)

	elif current_type == TabType.GAME:
		# Draw a beautiful retro game controller!
		_draw_controller(r + Vector2(0, 2), Color(0.04, 0.02, 0.01, 0.45))
		_draw_controller(r, active_color)
	elif current_type == TabType.ACCOUNT:
		# Draw a beautiful head-and-shoulders person profile icon!
		_draw_person(r + Vector2(0, 2), Color(0.04, 0.02, 0.01, 0.45))
		_draw_person(r, active_color)
	elif current_type == TabType.ROOM:
		# Draw a beautiful traditional gate/house outline!
		_draw_house(r + Vector2(0, 2), Color(0.04, 0.02, 0.01, 0.45))
		_draw_house(r, active_color)

func _draw_cap(pos: Vector2, color: Color) -> void:
	# Rhombus cap board
	var pts := PackedVector2Array([
		pos + Vector2(0, -12),
		pos + Vector2(20, -3),
		pos + Vector2(0, 7),
		pos + Vector2(-20, -3)
	])
	draw_colored_polygon(pts, color)
	
	# Cap base band below
	var base_pts := PackedVector2Array([
		pos + Vector2(-11, 1),
		pos + Vector2(11, 1),
		pos + Vector2(8, 8),
		pos + Vector2(-8, 8)
	])
	draw_colored_polygon(base_pts, color)
	
	# Cute tassel hanging down right side
	draw_line(pos + Vector2(0, -3), pos + Vector2(15, 4), color, 2.8, true)
	draw_circle(pos + Vector2(15, 7), 3.5, color)

func _draw_double_note(pos: Vector2, color: Color) -> void:
	# Two note heads
	draw_circle(pos + Vector2(-8, 8), 5.5, color)
	draw_circle(pos + Vector2(8, 5), 5.5, color)
	
	# Two stems
	draw_line(pos + Vector2(-3.5, 8), pos + Vector2(-3.5, -8), color, 2.8, true)
	draw_line(pos + Vector2(12.5, 5), pos + Vector2(12.5, -11), color, 2.8, true)
	
	# Connecting diagonal beam at the top
	var beam_pts := PackedVector2Array([
		pos + Vector2(-3.5, -8),
		pos + Vector2(12.5, -11),
		pos + Vector2(12.5, -6.5),
		pos + Vector2(-3.5, -3.5)
	])
	draw_colored_polygon(beam_pts, color)

func _draw_controller(pos: Vector2, color: Color) -> void:
	# Main body (capsule/rounded rect)
	var body_rect := Rect2(pos + Vector2(-14, -7), Vector2(28, 14))
	draw_rect(body_rect, color, true)
	draw_circle(pos + Vector2(-14, 0), 7.0, color)
	draw_circle(pos + Vector2(14, 0), 7.0, color)
	
	# D-pad (small cross inside)
	var dpad_col := C_RED_SON_DK if color != Color(0.04, 0.02, 0.01, 0.45) else Color(0.12, 0.06, 0.03, 0.8)
	draw_line(pos + Vector2(-13, 0), pos + Vector2(-7, 0), dpad_col, 2.8, true)
	draw_line(pos + Vector2(-10, -3), pos + Vector2(-10, 3), dpad_col, 2.8, true)
	
	# Action buttons
	draw_circle(pos + Vector2(8, -2), 2.2, dpad_col)
	draw_circle(pos + Vector2(12, 2), 2.2, dpad_col)

func _draw_person(pos: Vector2, color: Color) -> void:
	# Head circle
	draw_circle(pos + Vector2(0, -6), 6.5, color)
	# Shoulders arc
	draw_arc(pos + Vector2(0, 10), 10.0, PI, TAU, 16, color, 3.0, true)

func _draw_house(pos: Vector2, color: Color) -> void:
	# Pitched roof (triangle)
	var roof_pts := PackedVector2Array([
		pos + Vector2(0, -12),
		pos + Vector2(16, -2),
		pos + Vector2(-16, -2)
	])
	draw_colored_polygon(roof_pts, color)
	# House body (rectangle)
	draw_rect(Rect2(pos + Vector2(-12, -2), Vector2(24, 14)), color, true)
	# Door cutout (darker color)
	var door_col := C_RED_SON_DK if color != Color(0.04, 0.02, 0.01, 0.45) else Color(0.12, 0.06, 0.03, 0.8)
	draw_rect(Rect2(pos + Vector2(-3, 4), Vector2(6, 8)), door_col, true)
