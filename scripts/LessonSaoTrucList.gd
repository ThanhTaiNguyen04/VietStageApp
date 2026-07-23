extends Control

# ─── Color Palette (Synchronized Jade Green & Gold Lacquer Cream Theme)
const C_BG           := Color(0.98, 0.97, 0.94, 1.0) # Warm cream background matching the project
const C_GOLD         := Color(0.77, 0.58, 0.15, 1.0) # Lacquer gold
const C_GOLD_LIGHT   := Color(0.92, 0.76, 0.30, 1.0) # Lighter gold
const C_JADE         := Color(0.09, 0.27, 0.18, 1.0) # Premium deep jade green
const C_JADE_LIGHT   := Color(0.12, 0.37, 0.23, 1.0) # Lake jade green for active path borders
const C_TEXT         := Color(0.13, 0.08, 0.05, 1.0) # Dark charcoal
const C_TEXT_MUTED   := Color(0.13, 0.08, 0.05, 0.35)

# ─── Drag Tracking Variables
var _is_dragging_scroll: bool = false
var _drag_start_pos: Vector2 = Vector2.ZERO
var _scroll_start_x: float = 0.0
var _has_dragged_significantly: bool = false
var _drag_velocity: float = 0.0
var _last_drag_pos_x: float = 0.0
var _last_drag_time: float = 0.0

# ─── @onready Refs
@onready var bg_rect           : TextureRect      = $BG
@onready var top_bar           : PanelContainer = $Root/RightContent/TopBar
@onready var back_btn          : Button         = $Root/RightContent/TopBar/TopM/TopH/BackBtn
@onready var page_title        : Label          = $Root/RightContent/TopBar/TopM/TopH/PageTitle
@onready var change_course_btn : Button         = $Root/RightContent/TopBar/TopM/TopH/ChangeCourseBtn
@onready var scroll_container  : ScrollContainer = $Root/RightContent/ScrollContainer
@onready var lessons_hbox      : HBoxContainer  = $Root/RightContent/ScrollContainer/MarginContainer/LessonsHBox

# ─── Sidebar @onready Refs
@onready var sidebar           : PanelContainer = $Root/Sidebar
@onready var btn_menu          : Button         = $Root/Sidebar/SideM/SideV/BtnMenu
@onready var btn_courses       : Button         = $Root/Sidebar/SideM/SideV/BtnCourses
@onready var btn_room          : Button         = $Root/Sidebar/SideM/SideV/BtnRoom
@onready var btn_songs         : Button         = $Root/Sidebar/SideM/SideV/BtnSongs
@onready var btn_account       : Button         = $Root/Sidebar/SideM/SideV/BtnAccount
var btn_minigame               : Button

var _sidebar_icons_cache := {}

static var selected_level: int = 1

# 🗃️ Dynamic Lesson Data (10 Lessons for 5 Levels)
const ALL_LESSONS = [
	{
		"id": "sao_truc_level1_1", "level": 1, "title": "BÀI 1", "note": "Cầm sáo & Tư thế",
		"video": "Cách cầm sáo trúc đúng tư thế.", "practice": "Thực hành cầm sáo.", "subtitles": []
	},
	{
		"id": "sao_truc_level1_2", "level": 1, "title": "BÀI 2", "note": "Hơi thở cơ bản",
		"video": "Cách lấy hơi bụng.", "practice": "Luyện thở hơi dài.", "subtitles": []
	},
	{
		"id": "Node2", "level": 2, "title": "BÀI 1", "note": "Nốt Si (B4)",
		"video": "Hướng dẫn thổi nốt Si.", "practice": "Thực hành nốt Si.", "subtitles": []
	},
	{
		"id": "Node3", "level": 2, "title": "BÀI 2", "note": "Nốt La (A4)",
		"video": "Hướng dẫn thổi nốt La.", "practice": "Thực hành nốt La.", "subtitles": []
	},
	{
		"id": "Node4", "level": 2, "title": "BÀI 3", "note": "Nốt Sol (G4)",
		"video": "Hướng dẫn thổi nốt Sol.", "practice": "Thực hành nốt Sol.", "subtitles": []
	},
	{
		"id": "Node5", "level": 2, "title": "BÀI 4", "note": "Nốt Fa (F4)",
		"video": "Hướng dẫn thổi nốt Fa.", "practice": "Thực hành nốt Fa.", "subtitles": []
	},
	{
		"id": "Node6", "level": 2, "title": "BÀI 5", "note": "Nốt Mi (E4)",
		"video": "Hướng dẫn thổi nốt Mi.", "practice": "Thực hành nốt Mi.", "subtitles": []
	},
	{
		"id": "Node7", "level": 2, "title": "BÀI 6", "note": "Nốt Rê (D4)",
		"video": "Hướng dẫn thổi nốt Rê.", "practice": "Thực hành nốt Rê.", "subtitles": []
	},
	{
		"id": "Node8", "level": 2, "title": "BÀI 7", "note": "Nốt Đô (C4)",
		"video": "Hướng dẫn thổi nốt Đô.", "practice": "Thực hành nốt Đô.", "subtitles": []
	},
	{
		"id": "sao_truc_level3_1", "level": 3, "title": "BÀI 1", "note": "Khúc Nhạc Vui (Khung 1)"
	},
	{
		"id": "sao_truc_level3_2", "level": 3, "title": "BÀI 2", "note": "Khúc Nhạc Vui (Khung 2)"
	},
	{
		"id": "sao_truc_level3_3", "level": 3, "title": "BÀI 3", "note": "Khúc Nhạc Vui (Khung 3)"
	},
	{
		"id": "sao_truc_level3_4", "level": 3, "title": "BÀI 4", "note": "Khúc Nhạc Vui (Khung 4)"
	},
	{
		"id": "sao_truc_level3_5", "level": 3, "title": "BÀI 5", "note": "Khúc Nhạc Vui (Khung 5)"
	},
	{
		"id": "sao_truc_level3_6", "level": 3, "title": "BÀI 6", "note": "Khúc Nhạc Vui (Hoàn chỉnh)"
	},
	{
		"id": "sao_truc_level4_1", "level": 4, "title": "BÀI 1", "note": "Inh Lả Ơi (Câu 1)"
	},
	{
		"id": "sao_truc_level4_2", "level": 4, "title": "BÀI 2", "note": "Inh Lả Ơi (Câu 2)"
	},
	{
		"id": "sao_truc_level4_3", "level": 4, "title": "BÀI 3", "note": "Inh Lả Ơi (Câu 3)"
	},
	{
		"id": "sao_truc_level4_4", "level": 4, "title": "BÀI 4", "note": "Inh Lả Ơi (Câu 4)"
	},
	{
		"id": "sao_truc_level4_5", "level": 4, "title": "BÀI 5", "note": "Inh Lả Ơi (Hoàn chỉnh)"
	},
	{
		"id": "sao_truc_level5_1", "level": 5, "title": "BÀI 1", "note": "Futari no Kimochi (Đoạn 1 - P1)"
	},
	{
		"id": "sao_truc_level5_2", "level": 5, "title": "BÀI 2", "note": "Futari no Kimochi (Đoạn 1 - P2)"
	},
	{
		"id": "sao_truc_level5_3", "level": 5, "title": "BÀI 3", "note": "Futari no Kimochi (Đoạn 1 - HC)"
	},
	{
		"id": "sao_truc_level5_4", "level": 5, "title": "BÀI 4", "note": "Futari no Kimochi (Đoạn 2 - P1)"
	},
	{
		"id": "sao_truc_level5_5", "level": 5, "title": "BÀI 5", "note": "Futari no Kimochi (Đoạn 2 - P2)"
	},
	{
		"id": "sao_truc_level5_6", "level": 5, "title": "BÀI 6", "note": "Futari no Kimochi (Đoạn 2 - HC)"
	},
	{
		"id": "sao_truc_level5_7", "level": 5, "title": "BÀI 7", "note": "Futari no Kimochi (Hoàn chỉnh toàn bài)"
	}
]
var LESSONS: Array = []

func _ready() -> void:
	LESSONS = []
	for l in ALL_LESSONS:
		if l.get("level", 1) == selected_level:
			LESSONS.append(l)
			
	SecureDataManager.load_data()
	
	var side_v := $Root/Sidebar/SideM/SideV as VBoxContainer
	btn_minigame = Button.new()
	btn_minigame.name = "BtnMiniGame"
	btn_minigame.text = "Mini-game"
	btn_minigame.flat = true
	btn_minigame.custom_minimum_size = Vector2(220, 140)
	side_v.add_child(btn_minigame)
	side_v.move_child(btn_minigame, 5) # after BtnSongs (index 4)
	
	_build_theme()
	_connect_buttons()
	_build_lesson_list()
	_build_sidebar()
	
	lessons_hbox.draw.connect(_draw_connecting_lines)
	lessons_hbox.sort_children.connect(func():
		lessons_hbox.queue_redraw()
	)
	
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)

func _input(event: InputEvent) -> void:
	if not scroll_container or not is_instance_valid(scroll_container):
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if scroll_container.get_global_rect().has_point(event.global_position):
				_is_dragging_scroll = true
				_drag_start_pos = event.global_position
				_scroll_start_x = scroll_container.scroll_horizontal
				_has_dragged_significantly = false
				_drag_velocity = 0.0
				_last_drag_pos_x = event.global_position.x
				_last_drag_time = Time.get_ticks_msec() / 1000.0
		else:
			if _is_dragging_scroll:
				_is_dragging_scroll = false
				if _has_dragged_significantly and absf(_drag_velocity) > 50.0:
					var max_scroll := maxf(0.0, lessons_hbox.size.x - scroll_container.size.x)
					var target_x := clampf(scroll_container.scroll_horizontal - _drag_velocity * 0.35, 0.0, max_scroll)
					create_tween().tween_property(scroll_container, "scroll_horizontal", int(target_x), 0.45).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	elif event is InputEventScreenTouch:
		if event.pressed:
			if scroll_container.get_global_rect().has_point(event.position):
				_is_dragging_scroll = true
				_drag_start_pos = event.position
				_scroll_start_x = scroll_container.scroll_horizontal
				_has_dragged_significantly = false
				_drag_velocity = 0.0
				_last_drag_pos_x = event.position.x
				_last_drag_time = Time.get_ticks_msec() / 1000.0
		else:
			if _is_dragging_scroll:
				_is_dragging_scroll = false
				if _has_dragged_significantly and absf(_drag_velocity) > 50.0:
					var max_scroll := maxf(0.0, lessons_hbox.size.x - scroll_container.size.x)
					var target_x := clampf(scroll_container.scroll_horizontal - _drag_velocity * 0.35, 0.0, max_scroll)
					create_tween().tween_property(scroll_container, "scroll_horizontal", int(target_x), 0.45).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	elif _is_dragging_scroll:
		var current_x: float = 0.0
		if event is InputEventMouseMotion:
			current_x = event.global_position.x
		elif event is InputEventScreenDrag:
			current_x = event.position.x
		else:
			return
		var delta_x := current_x - _drag_start_pos.x
		if absf(delta_x) > 8.0:
			_has_dragged_significantly = true
		if _has_dragged_significantly:
			var max_scroll := maxf(0.0, lessons_hbox.size.x - scroll_container.size.x)
			scroll_container.scroll_horizontal = int(clampf(_scroll_start_x - delta_x, 0.0, max_scroll))
			var now := Time.get_ticks_msec() / 1000.0
			var dt := maxf(0.001, now - _last_drag_time)
			_drag_velocity = (current_x - _last_drag_pos_x) / dt
			_last_drag_pos_x = current_x
			_last_drag_time = now

func _build_theme() -> void:
	bg_rect.texture = load("res://assets/textures/sao_truc_background.png")
	
	var top_s := _flat(Color(1.0, 0.99, 0.97, 0.7), Color(C_GOLD, 0.28), 0, 0)
	top_s.border_width_bottom = 1
	top_s.content_margin_bottom = 0
	top_bar.add_theme_stylebox_override("panel", top_s)
	
	var top_blur_mat = ShaderMaterial.new()
	var top_blur_shader = Shader.new()
	top_blur_shader.code = """
	shader_type canvas_item;
	uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
	uniform float lod: hint_range(0.0, 5.0) = 2.0;
	void fragment() {
		COLOR = textureLod(screen_texture, SCREEN_UV, lod);
	}
	"""
	top_blur_mat.shader = top_blur_shader
	var top_blur_rect = ColorRect.new()
	top_blur_rect.material = top_blur_mat
	top_blur_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top_blur_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_blur_rect.show_behind_parent = true
	top_bar.add_child(top_blur_rect)
	top_bar.move_child(top_blur_rect, 0)
	
	page_title.text = "GIÁO TRÌNH SÁO TRÚC - LEVEL %d" % selected_level
	page_title.add_theme_color_override("font_color", C_JADE)
	
	var f_title := load("res://assets/fonts/Lora-Bold.ttf") as Font
	if f_title:
		page_title.add_theme_font_override("font", f_title)
		
	back_btn.text = ""
	back_btn.icon = load("res://assets/textures/lucide/arrow-left.svg") as Texture2D
	back_btn.expand_icon = true
	back_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	back_btn.custom_minimum_size = Vector2(48, 48)
	back_btn.add_theme_color_override("icon_normal_color", C_JADE)
	back_btn.add_theme_color_override("icon_hover_color", C_GOLD)
	back_btn.add_theme_color_override("icon_pressed_color", C_JADE)
	_style_text_btn(back_btn, C_JADE, C_GOLD)
	_make_btn_bouncy(back_btn)
	
	# Outlined style for ChangeCourseBtn
	var s_outline := StyleBoxFlat.new()
	s_outline.bg_color = Color(0, 0, 0, 0)
	s_outline.border_color = C_JADE
	s_outline.border_width_left = 3
	s_outline.border_width_right = 3
	s_outline.border_width_top = 3
	s_outline.border_width_bottom = 3
	s_outline.corner_radius_top_left = 24
	s_outline.corner_radius_top_right = 24
	s_outline.corner_radius_bottom_left = 24
	s_outline.corner_radius_bottom_right = 24
	
	var s_outline_hover := s_outline.duplicate() as StyleBoxFlat
	s_outline_hover.bg_color = Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.08)
	
	change_course_btn.text = "Đổi khóa học"
	change_course_btn.add_theme_stylebox_override("normal", s_outline)
	change_course_btn.add_theme_stylebox_override("hover", s_outline_hover)
	change_course_btn.add_theme_stylebox_override("pressed", s_outline)
	change_course_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	change_course_btn.add_theme_color_override("font_color", C_JADE)
	change_course_btn.add_theme_color_override("font_hover_color", C_GOLD)
	_make_btn_bouncy(change_course_btn)

func _connect_buttons() -> void:
	back_btn.pressed.connect(func() -> void:
		var t := create_tween()
		t.tween_property(self, "modulate:a", 0.0, 0.22)
		t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	)
	
	change_course_btn.pressed.connect(func() -> void:
		var t := create_tween()
		t.tween_property(self, "modulate:a", 0.0, 0.22)
		t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	)

func _build_sidebar() -> void:
	var side_s := _flat(Color(0.95, 0.93, 0.89, 0.6), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.15), 0, 0)
	side_s.border_width_left = 0; side_s.border_width_top = 0; side_s.border_width_bottom = 0
	side_s.border_width_right = 2
	side_s.content_margin_right = 0
	side_s.shadow_size = 12
	side_s.shadow_color = Color(0.13, 0.08, 0.05, 0.15)
	side_s.shadow_offset = Vector2(4, 0)
	sidebar.add_theme_stylebox_override("panel", side_s)

	var blur_mat = ShaderMaterial.new()
	var blur_shader = Shader.new()
	blur_shader.code = """
	shader_type canvas_item;
	uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
	uniform float lod: hint_range(0.0, 5.0) = 2.0;
	void fragment() {
		COLOR = textureLod(screen_texture, SCREEN_UV, lod);
	}
	"""
	blur_mat.shader = blur_shader
	var blur_rect = ColorRect.new()
	blur_rect.material = blur_mat
	blur_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blur_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blur_rect.show_behind_parent = true
	sidebar.add_child(blur_rect)
	sidebar.move_child(blur_rect, 0)

	_style_side_icon_btn(btn_menu,     false)
	_style_side_icon_btn(btn_courses,  true)
	_style_side_icon_btn(btn_room,     false)
	_style_side_icon_btn(btn_songs,    false)
	_style_side_icon_btn(btn_minigame, false)
	_style_side_icon_btn(btn_account,  false)

	_attach_icon_draw(btn_menu,     0)
	_attach_icon_draw(btn_courses,  1)
	_attach_icon_draw(btn_room,     6)
	_attach_icon_draw(btn_songs,    2)
	_attach_icon_draw(btn_minigame, 3)
	_attach_icon_draw(btn_account,  5)

	for b in [btn_menu, btn_courses, btn_room, btn_songs, btn_minigame, btn_account]:
		_make_btn_bouncy(b)

	btn_menu.pressed.connect(func() -> void:
		_fade_to_scene("res://scenes/MainMenu.tscn")
	)
	btn_courses.pressed.connect(func() -> void:
		_fade_to_scene("res://scenes/MainMenu.tscn")
	)
	btn_room.pressed.connect(func() -> void:
		_fade_to_scene("res://scenes/VirtualMusicRoom.tscn")
	)
	btn_songs.pressed.connect(func() -> void:
		_fade_to_scene("res://scenes/SongScreen.tscn")
	)
	btn_minigame.pressed.connect(func() -> void:
		_fade_to_scene("res://scenes/MiniGame.tscn")
	)
	btn_account.pressed.connect(func() -> void:
		_fade_to_scene("res://scenes/AccountScreen.tscn")
	)

func _style_side_icon_btn(btn: Button, is_active: bool, is_locked: bool = false) -> void:
	var bg_n := _flat(Color(0, 0, 0, 0) if not is_active else Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.12), Color(0, 0, 0, 0), 18, 0)
	var bg_h := _flat(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.08) if not is_locked else Color(0, 0, 0, 0), Color(0, 0, 0, 0), 18, 0)
	var bg_p := _flat(Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.20) if not is_locked else Color(0, 0, 0, 0), Color(0, 0, 0, 0), 18, 0)

	bg_n.content_margin_top = 96
	bg_n.content_margin_bottom = 8
	bg_h.content_margin_top = 96
	bg_h.content_margin_bottom = 8
	bg_p.content_margin_top = 96
	bg_p.content_margin_bottom = 8

	if is_active:
		bg_n.border_width_left = 6
		bg_n.border_width_right = 0; bg_n.border_width_top = 0; bg_n.border_width_bottom = 0
		bg_n.border_color = C_GOLD

	btn.add_theme_stylebox_override("normal",  bg_n)
	btn.add_theme_stylebox_override("hover",   bg_h)
	btn.add_theme_stylebox_override("pressed", bg_p)
	btn.add_theme_stylebox_override("focus",   _flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0))
	btn.add_theme_color_override("font_color",         C_JADE if is_active else (Color(0.43, 0.38, 0.33, 0.40) if is_locked else Color(0.43, 0.38, 0.33, 1.0)))
	btn.add_theme_color_override("font_hover_color",   Color(0.43, 0.38, 0.33, 0.8) if is_locked else Color(0.13, 0.08, 0.05, 1.0))
	btn.add_theme_color_override("font_pressed_color", C_JADE if not is_locked else Color(0.43, 0.38, 0.33, 0.40))
	btn.add_theme_font_size_override("font_size", 22)

func _attach_icon_draw(btn: Button, icon_type: int, is_locked: bool = false) -> void:
	var ic := Control.new()
	ic.name = "IconDraw"
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic.layout_mode = 1
	ic.anchors_preset = Control.PRESET_CENTER_TOP
	ic.anchor_left = 0.5; ic.anchor_right = 0.5
	ic.anchor_top = 0.0;  ic.anchor_bottom = 0.0
	ic.offset_left = -40; ic.offset_right = 40
	ic.offset_top = 12;   ic.offset_bottom = 92
	ic.draw.connect(func() -> void: _draw_sidebar_icon(ic, icon_type, is_locked))
	btn.add_child(ic)

func _draw_sidebar_icon(c: Control, t: int, is_locked: bool = false) -> void:
	var sz := c.size
	var cx := sz.x * 0.5
	var cy := sz.y * 0.5
	var col : Color = c.get_parent().get_theme_color("font_color", "Button")

	var tex_name := ""
	match t:
		0: tex_name = "menu"
		1: tex_name = "graduation-cap"
		2: tex_name = "music"
		3: tex_name = "gamepad-2"
		4: tex_name = "trending-up"
		5: tex_name = "user"
		6: tex_name = "home"
	
	var texture : Texture2D = null
	if _sidebar_icons_cache.has(t):
		texture = _sidebar_icons_cache[t]
	elif tex_name != "":
		texture = load("res://assets/textures/lucide/" + tex_name + ".svg") as Texture2D
		_sidebar_icons_cache[t] = texture
	
	if texture:
		var icon_sz := Vector2(36, 36)
		if t == 0:
			icon_sz = Vector2(28, 28)
		var rect := Rect2(Vector2(cx - icon_sz.x/2, cy - icon_sz.y/2), icon_sz)
		c.draw_texture_rect(texture, rect, false, col)

func _fade_to_scene(path: String) -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.22)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file(path))

func _fade_to(path: String) -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.22)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file(path))

func _flat(bg: Color, border: Color, radius: int, border_width: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	return s

func _build_lesson_list() -> void:
	lessons_hbox.add_theme_constant_override("separation", 120)
	# Clear existing children
	for child in lessons_hbox.get_children():
		child.queue_free()
		
	var inst := "sao_truc"
	var completed_lessons : Array = SecureDataManager.data.get("completed_lessons", {}).get(inst, [])
	var unlocked_lessons : Array = SecureDataManager.data.get("unlocked_lessons", {}).get(inst, ["sao_truc_level1_1_video"])
	
	var f_bold := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	
	for i in range(LESSONS.size()):
		var lesson_item : Dictionary = LESSONS[i]
		var id := lesson_item["id"] as String
		
		# Unlocking checks
		var is_unlocked := false
		if i == 0:
			is_unlocked = true
		else:
			var prev_id := LESSONS[i - 1]["id"] as String
			is_unlocked = true # FORCE UNLOCK
			
		var is_completed := completed_lessons.has(id) or completed_lessons.has(id + "_practice")
		
		# Column layout for each lesson
		var col := VBoxContainer.new()
		col.custom_minimum_size = Vector2.ZERO
		col.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 24)
		
		# Top: Lesson Title Label
		var title_lbl := Label.new()
		title_lbl.text = lesson_item["title"]
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_lbl.add_theme_color_override("font_color", C_TEXT if is_unlocked else C_TEXT_MUTED)
		title_lbl.add_theme_font_size_override("font_size", 20)
		if f_bold:
			title_lbl.add_theme_font_override("font", f_bold)
		col.add_child(title_lbl)
		
		# Center: Single Circle Button
		var row := HBoxContainer.new()
		row.name = "Row"
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 100)
		col.add_child(row)
		
		var btn := Button.new()
		btn.name = "LessonBtn"
		btn.custom_minimum_size = Vector2(250, 250)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		if is_completed:
			btn.text = "✔️\n%s\nHoàn thành" % lesson_item["note"]
		elif not is_unlocked:
			btn.text = "🔒"
		else:
			btn.text = "🎵\n%s" % lesson_item["note"]
			
		_style_circle_btn(btn, is_unlocked, is_completed)
		_make_btn_bouncy(btn)
		row.add_child(btn)
		
		btn.pressed.connect(func() -> void:
			if _has_dragged_significantly or not is_unlocked: return
			SecureDataManager.active_lesson_id = id
			
			SecureDataManager.data["current_song_title"] = lesson_item.get("note", "Bài Tập Cơ Bản")
			_fade_to("res://scenes/LessonSaoTruc.tscn")
		)
		
		lessons_hbox.add_child(col)

func _style_circle_btn(btn: Button, is_unlocked: bool, is_completed: bool) -> void:
	# Jade Green & Gold Traditional Lacquer Theme
	var bg_color := Color(0.95, 0.93, 0.89, 0.6) # Light warm gray-cream for locked
	var border_color := Color(0.85, 0.82, 0.78, 1.0) # Gray border for locked
	var text_color := C_TEXT_MUTED # Translucent charcoal text for locked
	
	if is_completed:
		bg_color = C_JADE # Solid Jade Green for completed
		border_color = C_GOLD # Gold border
		text_color = Color.WHITE # White checkmark/text inside
	elif is_unlocked:
		bg_color = Color(1.0, 1.0, 1.0, 0.8) # semi-transparent white for glass effect
		border_color = C_JADE_LIGHT # Jade border
		text_color = C_TEXT # Dark charcoal text
		
	var s_normal := StyleBoxFlat.new()
	s_normal.bg_color = bg_color
	s_normal.border_color = border_color
	s_normal.border_width_left = 6; s_normal.border_width_right = 6
	s_normal.border_width_top = 6; s_normal.border_width_bottom = 6
	s_normal.corner_radius_top_left = 125; s_normal.corner_radius_top_right = 125
	s_normal.corner_radius_bottom_left = 125; s_normal.corner_radius_bottom_right = 125
	
	# Glow effect for active step (using softer, wider gold shadow)
	if is_unlocked and not is_completed:
		s_normal.shadow_size = 24
		s_normal.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35)
		
	var s_hover := s_normal.duplicate() as StyleBoxFlat
	if is_unlocked:
		if is_completed:
			s_hover.bg_color = bg_color.lightened(0.1)
		else:
			s_hover.bg_color = Color(1.0, 1.0, 1.0, 0.95)
		
	btn.add_theme_stylebox_override("normal", s_normal)
	btn.add_theme_stylebox_override("hover", s_hover)
	btn.add_theme_stylebox_override("pressed", s_normal)
	btn.add_theme_stylebox_override("disabled", s_normal)
	btn.add_theme_color_override("font_color", text_color)
	btn.add_theme_color_override("font_hover_color", C_JADE if (is_unlocked and not is_completed) else text_color)
	btn.add_theme_color_override("font_pressed_color", text_color)
	btn.add_theme_color_override("font_disabled_color", text_color)
	
	var f_bold := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if f_bold:
		btn.add_theme_font_override("font", f_bold)
	btn.add_theme_font_size_override("font_size", 21)
	
	btn.disabled = not is_unlocked

func _draw_connecting_lines() -> void:
	var inst := "sao_truc"
	var completed_lessons : Array = SecureDataManager.data.get("completed_lessons", {}).get(inst, [])
	var unlocked_lessons : Array = SecureDataManager.data.get("unlocked_lessons", {}).get(inst, ["sao_truc_coban_1_video"])

	var centers : Array[Vector2] = []
	var node_unlocked : Array[bool] = []

	var cols := lessons_hbox.get_children()
	for i in range(cols.size()):
		var col := cols[i] as VBoxContainer
		if not col: continue
		var row := col.get_node_or_null("Row") as HBoxContainer
		if not row: continue
		
		var btn := row.get_node_or_null("LessonBtn") as Button
		if not btn: continue
		
		# Compute centers in HBox local coordinates
		var center := col.position + row.position + btn.position + btn.size / 2.0
		
		centers.append(center)
		
		# Determine unlock status - currently forcing true to match UI
		node_unlocked.append(true)

	if centers.is_empty():
		return
	var line_y := centers[0].y
	# Draw lines between nodes
	for idx in range(centers.size() - 1):
		var p1 := Vector2(centers[idx].x, line_y)
		var p2 := Vector2(centers[idx + 1].x, line_y)
		
		var active := node_unlocked[idx + 1]
		var line_color := C_JADE if active else Color(0.13, 0.08, 0.05, 0.08)
		var line_thickness := 14.0 if active else 7.0
		
		lessons_hbox.draw_line(p1, p2, line_color, line_thickness, true)

func _apply_responsive_layout() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var mobile: bool = viewport_size.x < 850.0 or viewport_size.x < viewport_size.y
	sidebar.visible = not mobile
	var top_margin := $Root/RightContent/TopBar/TopM as MarginContainer
	top_margin.add_theme_constant_override("margin_left", 16 if mobile else 36)
	top_margin.add_theme_constant_override("margin_right", 16 if mobile else 36)
	top_margin.add_theme_constant_override("margin_top", 16 if mobile else 24)
	top_margin.add_theme_constant_override("margin_bottom", 12 if mobile else 16)
	page_title.add_theme_font_size_override("font_size", 20 if mobile else 28)
	change_course_btn.custom_minimum_size.x = 110 if mobile else 180
	var sep := 65 if mobile else 100
	lessons_hbox.add_theme_constant_override("separation", sep)
	for col in lessons_hbox.get_children():
		if col is VBoxContainer:
			col.custom_minimum_size = Vector2.ZERO
			col.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			var row := col.get_node_or_null("Row") as HBoxContainer
			if row:
				row.add_theme_constant_override("separation", sep)
				var btn := row.get_node_or_null("LessonBtn") as Button
				if btn:
					var sz := Vector2(180, 180) if mobile else Vector2(250, 250)
					btn.custom_minimum_size = sz
					btn.add_theme_font_size_override("font_size", 18 if mobile else 21)
					var s_normal := btn.get_theme_stylebox("normal") as StyleBoxFlat
					if s_normal:
						var rad := 90 if mobile else 125
						s_normal.corner_radius_top_left = rad; s_normal.corner_radius_top_right = rad
						s_normal.corner_radius_bottom_left = rad; s_normal.corner_radius_bottom_right = rad

# ─── Helper Functions ─────────────────────────────────────────────────────────
func _style_text_btn(btn: Button, normal_color: Color, hover_color: Color) -> void:
	btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_color_override("font_color", normal_color)
	btn.add_theme_color_override("font_hover_color", hover_color)
	btn.add_theme_color_override("font_pressed_color", hover_color.darkened(0.15))

func _make_btn_bouncy(btn: Button) -> void:
	btn.pivot_offset = btn.size / 2.0
	btn.resized.connect(func() -> void: btn.pivot_offset = btn.size / 2.0)
	btn.mouse_entered.connect(func() -> void:
		if not btn.disabled:
			create_tween().tween_property(btn, "scale", Vector2(1.05, 1.05), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func() -> void:
		if not btn.disabled:
			create_tween().tween_property(btn, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	btn.button_down.connect(func() -> void:
		if not btn.disabled:
			create_tween().tween_property(btn, "scale", Vector2(0.95, 0.95), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	btn.button_up.connect(func() -> void:
		if not btn.disabled:
			var target := Vector2(1.05, 1.05) if btn.is_hovered() else Vector2.ONE
			create_tween().tween_property(btn, "scale", target, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
