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
		text = "Phòng nhạc"
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
	var r := Vector2(38, h / 2.0) # Position of the icon center
	
	var is_prem : bool = SecureDataManager.data.get("is_premium", false)
	var is_locked : bool = (current_type == TabType.SONG and not is_prem)

	var active_color := C_GOLD if is_active else (C_CREAM_DIM.darkened(0.35) if is_locked else C_CREAM_DIM)
	if is_hovered():
		active_color = C_GOLD_LIGHT if is_active else (C_CREAM_DIM.darkened(0.2) if is_locked else C_CREAM)
		
	var tex : Texture2D = null
	match current_type:
		TabType.MENU:
			tex = load("res://assets/textures/icons8/menu.png") as Texture2D
		TabType.LESSON:
			tex = load("res://assets/textures/icons8/course.png") as Texture2D
		TabType.SONG:
			tex = load("res://assets/textures/icons8/songs.png") as Texture2D
		TabType.GAME:
			tex = load("res://assets/textures/icons8/game.png") as Texture2D
		TabType.ACCOUNT:
			tex = load("res://assets/textures/icons8/account.png") as Texture2D
		TabType.ROOM:
			tex = load("res://assets/textures/icons8/room.png") as Texture2D

	if tex:
		# Draw icon with shadow/offset first
		var icon_size := Vector2(32, 32)
		# For MENU type, let's keep it centered horizontally in the button since it has no text
		var draw_pos := r
		if current_type == TabType.MENU:
			draw_pos = Vector2(size.x / 2.0, size.y / 2.0)
			
		var shadow_rect := Rect2(draw_pos - icon_size / 2.0 + Vector2(0, 1.5), icon_size)
		draw_texture_rect(tex, shadow_rect, false, Color(0, 0, 0, 0.45))
		
		# Draw main icon
		var main_rect := Rect2(draw_pos - icon_size / 2.0, icon_size)
		draw_texture_rect(tex, main_rect, false, active_color)

	# Overlay lock icon if locked
	if is_locked:
		var tex_lock := load("res://assets/textures/icons8/lock.png") as Texture2D
		if tex_lock:
			var lock_size := Vector2(16, 16)
			var lock_rect := Rect2(r + Vector2(6, 4), lock_size)
			draw_texture_rect(tex_lock, lock_rect, false, C_GOLD)
