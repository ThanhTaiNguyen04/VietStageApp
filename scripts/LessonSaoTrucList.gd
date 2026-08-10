extends Control

# ─── Color Palette (Synchronized Jade Green & Gold Lacquer Cream Theme)
const C_BG           := Color(0.98, 0.97, 0.94, 1.0) # Warm cream background matching the project
const C_GOLD         := Color(0.77, 0.58, 0.15, 1.0) # Lacquer gold
const C_GOLD_LIGHT   := Color(0.92, 0.76, 0.30, 1.0) # Lighter gold
const C_GOLD_DARK    := Color(0.478, 0.36, 0.07, 1.0)
const C_JADE         := Color(0.09, 0.27, 0.18, 1.0) # Premium deep jade green
const C_JADE_LIGHT   := Color(0.12, 0.37, 0.23, 1.0) # Lake jade green for active path borders
const C_TEXT         := Color(0.13, 0.08, 0.05, 1.0) # Dark charcoal
const C_TEXT_MUTED   := Color(0.13, 0.08, 0.05, 0.35)

const QuizScreenScript := preload("res://scripts/QuizScreen.gd")
const SidebarDrawerScript := preload("res://scripts/ui/SidebarDrawer.gd")

var _drawer

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
var btn_leaderboard            : Button

var _sidebar_icons_cache := {}

static var selected_level: int = 1
var _tap_timer: float = 0.0

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
	btn_minigame.text = "Minigame"
	btn_minigame.flat = true
	btn_minigame.custom_minimum_size = Vector2(220, 100)
	side_v.add_child(btn_minigame)
	side_v.move_child(btn_minigame, 5) # after BtnSongs (index 4)
	
	btn_leaderboard = Button.new()
	btn_leaderboard.name = "BtnLeaderboard"
	btn_leaderboard.text = "Bảng xếp hạng"
	btn_leaderboard.flat = true
	btn_leaderboard.custom_minimum_size = Vector2(220, 100)
	side_v.add_child(btn_leaderboard)
	side_v.move_child(btn_leaderboard, 6)
	
	_build_theme()
	_connect_buttons()
	_build_quiz_btn()
	_build_profile_btn()
	_build_lesson_list()
	_build_sidebar()
	
	_drawer = SidebarDrawerScript.new()
	add_child(_drawer)
	_drawer.setup(sidebar, self, $Root, $Root/RightContent/TopBar/TopM/TopH)
	_drawer.desktop_width = 220.0
	
	lessons_hbox.draw.connect(_draw_connecting_lines)
	lessons_hbox.sort_children.connect(func():
		lessons_hbox.queue_redraw()
	)
	
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	lessons_hbox.mouse_filter = Control.MOUSE_FILTER_PASS
	var content_margin := lessons_hbox.get_parent() as Control
	if content_margin: content_margin.mouse_filter = Control.MOUSE_FILTER_PASS
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)

func _on_btn_leaderboard_pressed() -> void:
	_fade_to_scene("res://scenes/LeaderboardScreen.tscn")

func _process(delta: float) -> void:
	if _tap_timer > 0:
		_tap_timer -= delta

func _input(event: InputEvent) -> void:
	pass

func _build_theme() -> void:
	bg_rect.texture = load("res://assets/textures/sao_truc_background.png")
	
	var top_s := _flat(Color(1.0, 0.99, 0.97, 1.0), Color(C_GOLD, 0.28), 0, 0)
	top_s.border_width_bottom = 1
	top_s.content_margin_bottom = 0
	top_bar.add_theme_stylebox_override("panel", top_s)
	
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
	_float_back_btn()
	
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

func _float_back_btn() -> void:
	var top_h_back := back_btn.get_parent()
	if top_h_back:
		top_h_back.remove_child(back_btn)
	add_child(back_btn)
	back_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	back_btn.anchor_left = 0.0; back_btn.anchor_right = 0.0
	back_btn.anchor_top = 1.0; back_btn.anchor_bottom = 1.0
	DS.apply_round_icon_btn(back_btn)
	var sz := back_btn.custom_minimum_size.y
	back_btn.offset_top = -sz - 20.0
	back_btn.offset_bottom = -20.0
	back_btn.size_flags_horizontal = 0
	back_btn.size_flags_vertical = 0
	back_btn.move_to_front()
	_sync_back_pos()

func _sync_back_pos() -> void:
	if not is_inside_tree():
		return
	var margin := DS.nav_margin(get_viewport_rect().size.x)
	var sz := back_btn.custom_minimum_size.x
	back_btn.offset_left = float(margin)
	back_btn.offset_right = float(margin) + sz

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

func _build_quiz_btn() -> void:
	var toph := $Root/RightContent/TopBar/TopM/TopH as HBoxContainer
	if toph == null:
		return
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
	s_outline_hover.bg_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.12)

	var quiz_btn := Button.new()
	quiz_btn.name = "QuizBtn"
	quiz_btn.text = "📝 Quiz"
	quiz_btn.custom_minimum_size = Vector2(148, 48)
	quiz_btn.add_theme_stylebox_override("normal", s_outline)
	quiz_btn.add_theme_stylebox_override("hover", s_outline_hover)
	quiz_btn.add_theme_stylebox_override("pressed", s_outline)
	quiz_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	quiz_btn.add_theme_color_override("font_color", C_JADE)
	quiz_btn.add_theme_color_override("font_hover_color", C_GOLD)
	quiz_btn.add_theme_font_size_override("font_size", 17)
	quiz_btn.pressed.connect(_open_quiz)
	_make_btn_bouncy(quiz_btn)
	toph.add_child(quiz_btn)
	toph.move_child(quiz_btn, change_course_btn.get_index())

func _build_profile_btn() -> void:
	var toph := $Root/RightContent/TopBar/TopM/TopH as HBoxContainer
	if toph == null:
		return
	var spacer := Control.new()
	spacer.name = "TopSpacerRight"
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toph.add_child(spacer)
	var pill := DS.build_profile_pill()
	var trigger := pill.get_node_or_null("TriggerButton") as Button
	if trigger:
		trigger.pressed.connect(func() -> void: _fade_to_scene("res://scenes/AccountScreen.tscn"))
	toph.add_child(pill)

func _open_quiz() -> void:
	var ids: Array[String] = []
	for l in LESSONS:
		ids.append(str(l.get("id", "")))
	QuizScreenScript.quiz_instrument = "sao_truc"
	QuizScreenScript.quiz_local_ids = ids
	QuizScreenScript.quiz_return_scene = "res://scenes/LessonSaoTrucList.tscn"
	_fade_to("res://scenes/QuizScreen.tscn")

func _build_sidebar() -> void:
	var side_s := _flat(Color.TRANSPARENT, C_GOLD, 0, 0)
	side_s.border_width_left = 0; side_s.border_width_top = 0; side_s.border_width_bottom = 0
	side_s.border_width_right = 2
	side_s.content_margin_right = 0
	side_s.shadow_size = 32
	side_s.shadow_color = Color(0, 0, 0, 0.12)
	side_s.shadow_offset = Vector2(4, 0)
	sidebar.add_theme_stylebox_override("panel", side_s)

	# Remove any existing GlassBlur child
	var old_blur = sidebar.get_node_or_null("GlassBlur")
	if old_blur:
		old_blur.queue_free()

	for b in [btn_menu, btn_courses, btn_room, btn_songs, btn_minigame, btn_leaderboard]:
		if b:
			b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			b.custom_minimum_size = Vector2(70, 70)

	_style_side_icon_btn(btn_menu,     false)
	_style_side_icon_btn(btn_courses,  true)
	_style_side_icon_btn(btn_room,     false)
	_style_side_icon_btn(btn_songs,    false)
	_style_side_icon_btn(btn_minigame, false)
	_style_side_icon_btn(btn_leaderboard, false)
	if btn_account:
		btn_account.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		DS.apply_round_icon_btn(btn_account)

	_attach_icon_draw(btn_menu,     0)
	_attach_icon_draw(btn_courses,  1)
	_attach_icon_draw(btn_room,     6)
	_attach_icon_draw(btn_songs,    2)
	_attach_icon_draw(btn_minigame, 3)
	_attach_icon_draw(btn_leaderboard, 4)
	_attach_icon_draw(btn_account,  5)

	for b in [btn_menu, btn_courses, btn_room, btn_songs, btn_minigame, btn_account, btn_leaderboard]:
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
	btn_leaderboard.pressed.connect(_on_btn_leaderboard_pressed)
	btn_account.pressed.connect(func() -> void:
		_fade_to_scene("res://scenes/AccountScreen.tscn")
	)

func _style_side_icon_btn(btn: Button, is_active: bool, is_locked: bool = false) -> void:
	var bg_n := StyleBoxFlat.new()
	bg_n.set_corner_radius_all(35)
	bg_n.draw_center = true
	if is_active:
		bg_n.bg_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.15)
		bg_n.border_width_left = 2; bg_n.border_width_right = 2
		bg_n.border_width_top = 2; bg_n.border_width_bottom = 2
		bg_n.border_color = C_GOLD_LIGHT # Bright border!
	else:
		bg_n.bg_color = Color(1.0, 1.0, 1.0, 0.03)
		bg_n.border_width_left = 1; bg_n.border_width_right = 1
		bg_n.border_width_top = 1; bg_n.border_width_bottom = 1
		bg_n.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25) # Muted bright border
		
	var bg_h := StyleBoxFlat.new()
	bg_h.set_corner_radius_all(35)
	bg_h.bg_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.08)
	bg_h.border_width_left = 2; bg_h.border_width_right = 2
	bg_h.border_width_top = 2; bg_h.border_width_bottom = 2
	bg_h.border_color = C_GOLD_LIGHT
	
	var bg_p := StyleBoxFlat.new()
	bg_p.set_corner_radius_all(35)
	bg_p.bg_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25)
	bg_p.border_width_left = 2; bg_p.border_width_right = 2
	bg_p.border_width_top = 2; bg_p.border_width_bottom = 2
	bg_p.border_color = C_GOLD_LIGHT

	btn.add_theme_stylebox_override("normal",  bg_n)
	btn.add_theme_stylebox_override("hover",   bg_h)
	btn.add_theme_stylebox_override("pressed", bg_p)
	btn.add_theme_stylebox_override("focus",   _flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0))
	btn.add_theme_color_override("font_color",         C_GOLD_LIGHT if is_active else (Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35) if is_locked else C_GOLD))
	btn.add_theme_color_override("font_hover_color",   Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.50) if is_locked else C_GOLD_LIGHT)
	btn.add_theme_color_override("font_pressed_color", C_GOLD_LIGHT if not is_locked else Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35))
	btn.add_theme_font_size_override("font_size", 22)

func _attach_icon_draw(btn: Button, icon_type: int, is_locked: bool = false) -> void:
	btn.text = ""
	var old_ic := btn.get_node_or_null("IconDraw")
	if old_ic:
		old_ic.queue_free()
	var ic := Control.new()
	ic.name = "IconDraw"
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic.layout_mode = 1
	ic.anchors_preset = Control.PRESET_CENTER
	ic.anchor_left = 0.5; ic.anchor_right = 0.5
	ic.anchor_top = 0.5;  ic.anchor_bottom = 0.5
	
	var ic_offset := 20
	if icon_type == 5:
		ic_offset = 32
	ic.offset_left = -ic_offset; ic.offset_right = ic_offset
	ic.offset_top = -ic_offset;  ic.offset_bottom = ic_offset
	ic.draw.connect(func() -> void: _draw_sidebar_icon(ic, icon_type, is_locked))
	btn.add_child(ic)

func _draw_sidebar_icon(c: Control, t: int, is_locked: bool = false) -> void:
	var sz := c.size
	var cx := sz.x * 0.5
	var cy := sz.y * 0.5

	if t == 5:
		var shader = load("res://assets/shaders/circular_avatar.gdshader") as Shader
		if shader:
			var mat = ShaderMaterial.new()
			mat.shader = shader
			c.material = mat
			
		var avatar_source := str(SecureDataManager.data.get("user_avatar_url", "")).strip_edges()
		if avatar_source.is_empty():
			avatar_source = str(SecureDataManager.data.get("user_avatar", "res://assets/textures/default_avatar.png"))
		var avatar_tex : Texture2D = null
		if avatar_source.begins_with("res://"):
			avatar_tex = load(avatar_source) as Texture2D
		if avatar_tex == null:
			avatar_tex = load("res://assets/textures/default_avatar.png") as Texture2D
			
		if avatar_tex:
			c.draw_texture_rect(avatar_tex, Rect2(0, 0, sz.x, sz.y), false)
		return

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
		btn.mouse_filter = Control.MOUSE_FILTER_PASS
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
			_open_lesson(id)
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
	if _drawer:
		_drawer.set_viewport_mode(not mobile)
	else:
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
	_sync_back_pos()

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

func _open_lesson(node_id: String) -> void:
	SecureDataManager.active_lesson_id = node_id
	SecureDataManager.data["current_song_title"] = node_id
	_fade_to("res://scenes/LessonSaoTruc.tscn")
