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
const C_MUTED        := Color("#6f6257")
const C_CARD         := Color("#fffdf8")

const QuizScreenScript := preload("res://scripts/QuizScreen.gd")

var is_unlocked: bool = true

# ─── @onready Refs
@onready var bg_rect           : ColorRect      = $BG
@onready var top_bar           : PanelContainer = $Root/RightContent/TopBar
@onready var back_btn          : Button         = $Root/RightContent/TopBar/TopM/TopH/BackBtn
@onready var page_title        : Label          = $Root/RightContent/TopBar/TopM/TopH/PageTitle
var change_course_btn : Button
@onready var scroll_container  : ScrollContainer = $Root/RightContent/ScrollContainer
@onready var lessons_hbox      : HBoxContainer  = $Root/RightContent/ScrollContainer/MarginContainer/LessonsHBox

# ─── Sidebar @onready Refs
@onready var sidebar           : PanelContainer = $Root/Sidebar
var btn_menu          : Button
@onready var btn_courses       : Button         = $Root/Sidebar/SideM/SideV/BtnCourses
@onready var btn_room          : Button         = $Root/Sidebar/SideM/SideV/BtnRoom
@onready var btn_songs         : Button         = $Root/Sidebar/SideM/SideV/BtnSongs
var btn_account       : Button
var btn_minigame               : Button
var btn_leaderboard            : Button

var _sidebar_icons_cache := {}

static var selected_level: int = 1

const LEVELS := [
	{
		"level": 1,
		"title": "LÀM QUEN VỚI ĐÀN (NHẬP MÔN)",
		"objective": "🎯 Mục tiêu: Xem video giới thiệu cấu tạo, tư thế và cách tạo âm chuẩn.",
		"lessons": [
			{
				"id": "dan_bau_level1_bai1_video",
				"title": "BÀI 1",
				"type": "video",
				"note": "Giới thiệu Đàn Bầu",
				"subtitles": [
					{"start": 0.0, "end": 2.5, "text": "Chào mừng bạn đến với Bài 1: Lịch sử ngắn và Cấu tạo Đàn Bầu."},
					{"start": 2.5, "end": 6.5, "text": "Đàn Bầu gồm Bầu vang, vòi/cần đàn, dây đàn, trạc đàn và que gảy."},
					{"start": 6.5, "end": 10.0, "text": "Hãy quan sát kỹ từng bộ phận trước khi bắt đầu tư thế ngồi nhé."}
				]
			}
		]
	},
	{
		"level": 2,
		"title": "KỸ THUẬT BỒI ÂM CƠ BẢN",
		"objective": "🎯 Mục tiêu: Biết tạo các bồi âm tự nhiên trên dây đàn.",
		"lessons": [
			{
				"id": "dan_bau_level2_bai1_practice",
				"title": "BÀI 1",
				"type": "practice",
				"note": "Bồi âm 1/2 dây (C4)",
				"subtitles": []
			},
			{
				"id": "dan_bau_level2_bai2_practice",
				"title": "BÀI 2",
				"type": "practice",
				"note": "Bồi âm 1/3 dây (G4)",
				"subtitles": []
			},
			{
				"id": "dan_bau_level2_bai3_practice",
				"title": "BÀI 3",
				"type": "practice",
				"note": "Bồi âm 1/4 dây (C5)",
				"subtitles": []
			},
			{
				"id": "dan_bau_level2_bai4_practice",
				"title": "BÀI 4",
				"type": "practice",
				"note": "Ghép chuỗi Bồi Âm",
				"subtitles": []
			},
			{
				"id": "dan_bau_level2_bai5_practice",
				"title": "BÀI 5",
				"type": "practice",
				"note": "🎮 Mini Game: Nhận diện C4",
				"subtitles": []
			}
		]
	},
	{
		"level": 3,
		"title": "ĐIỀU KHIỂN CẦN ĐÀN",
		"objective": "🎯 Mục tiêu: Làm chủ cao độ bằng tay trái uốn/nhả cần.",
		"lessons": [
			{
				"id": "dan_bau_level3_bai1_practice",
				"title": "BÀI 1",
				"type": "practice",
				"note": "Kéo cần tăng cao độ",
				"subtitles": []
			},
			{
				"id": "dan_bau_level3_bai2_practice",
				"title": "BÀI 2",
				"type": "practice",
				"note": "Nhả cần giảm cao độ",
				"subtitles": []
			},
			{
				"id": "dan_bau_level3_bai3_practice",
				"title": "BÀI 3",
				"type": "practice",
				"note": "Giữ cao độ ổn định",
				"subtitles": []
			},
			{
				"id": "dan_bau_level3_bai4_practice",
				"title": "BÀI 4",
				"type": "practice",
				"note": "Chuyển giữa các cao độ",
				"subtitles": []
			},
			{
				"id": "dan_bau_level3_bai5_practice",
				"title": "BÀI 5",
				"type": "practice",
				"note": "🎮 Mini Game: C4 → C#4 → D4",
				"subtitles": []
			}
		]
	},
	{
		"level": 4,
		"title": "KỸ THUẬT BIỂU CẢM",
		"objective": "🎯 Mục tiêu: Chơi có cảm xúc với Rung, Luyến, Vuốt, Ngắt.",
		"lessons": [
			{
				"id": "dan_bau_level4_bai1_practice",
				"title": "BÀI 1",
				"type": "practice",
				"note": "Kỹ thuật Rung (Vibrato)",
				"subtitles": []
			},
			{
				"id": "dan_bau_level4_bai2_practice",
				"title": "BÀI 2",
				"type": "practice",
				"note": "Kỹ thuật Luyến âm",
				"subtitles": []
			},
			{
				"id": "dan_bau_level4_bai3_practice",
				"title": "BÀI 3",
				"type": "practice",
				"note": "Kỹ thuật Vuốt cần",
				"subtitles": []
			},
			{
				"id": "dan_bau_level4_bai4_practice",
				"title": "BÀI 4",
				"type": "practice",
				"note": "Kỹ thuật Ngắt tiếng",
				"subtitles": []
			},
			{
				"id": "dan_bau_level4_bai5_practice",
				"title": "BÀI 5",
				"type": "practice",
				"note": "🎮 Mini Game: AI Bắt chước & Chấm điểm",
				"subtitles": []
			}
		]
	},
	{
		"level": 5,
		"title": "CHƠI BÀI HÁT DÂN CA",
		"objective": "🎯 Mục tiêu: Áp dụng toàn bộ kỹ thuật chơi hoàn chỉnh bài hát.",
		"lessons": [
			{
				"id": "dan_bau_level5_bai1_practice",
				"title": "BÀI 1",
				"type": "practice",
				"note": "Luyện từng câu nhạc",
				"subtitles": []
			},
			{
				"id": "dan_bau_level5_bai2_practice",
				"title": "BÀI 2",
				"type": "practice",
				"note": "Ghép câu & Ghép đoạn",
				"subtitles": []
			},
			{
				"id": "dan_bau_level5_bai3_practice",
				"title": "BÀI 3",
				"type": "practice",
				"note": "Bài Bèo Dạt Mây Trôi",
				"subtitles": []
			},
			{
				"id": "dan_bau_level5_bai4_practice",
				"title": "BÀI 4",
				"type": "practice",
				"note": "Bài Lý Cây Đa & Cò Lả",
				"subtitles": []
			},
			{
				"id": "dan_bau_level5_bai5_practice",
				"title": "BÀI 5",
				"type": "practice",
				"note": "🏆 Mini Game Cuối: Chơi Cả Bài (AI Chấm 100)",
				"subtitles": []
			}
		]
	}
]

func get_current_lessons() -> Array:
	var level_idx := clampi(selected_level, 1, LEVELS.size()) - 1
	return LEVELS[level_idx]["lessons"]

func _ready() -> void:
	SecureDataManager.load_data()
	btn_menu = get_node_or_null("Root/Sidebar/SideM/SideV/BtnMenu")
	btn_account = get_node_or_null("Root/Sidebar/SideM/SideV/BtnAccount")
	change_course_btn = get_node_or_null("Root/RightContent/TopBar/TopM/TopH/ChangeCourseBtn")
	
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
	
	lessons_hbox.draw.connect(_draw_connecting_lines)
	lessons_hbox.sort_children.connect(func():
		lessons_hbox.queue_redraw()
	)
	
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	lessons_hbox.mouse_filter = Control.MOUSE_FILTER_PASS
	var content_margin := lessons_hbox.get_parent() as Control
	if content_margin: content_margin.mouse_filter = Control.MOUSE_FILTER_PASS
	
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)

func _on_btn_leaderboard_pressed() -> void:
	_fade_to_scene("res://scenes/LeaderboardScreen.tscn")

func _input(event: InputEvent) -> void:
	pass

func _build_theme() -> void:
	bg_rect.color = C_BG
	
	var tex_path := "res://assets/textures/dan_bau_background.png"
	if ResourceLoader.exists(tex_path):
		var bg_tex := TextureRect.new()
		bg_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg_tex.texture = load(tex_path) as Texture2D
		bg_rect.add_child(bg_tex)
	
	var top_s := StyleBoxFlat.new()
	top_s.bg_color = Color(0.93, 0.91, 0.87, 0.6) # Glassmorphism opacity
	top_s.border_color = Color(0.8, 0.78, 0.73, 0.8)
	top_s.border_width_bottom = 2
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
	
	var level_idx := clampi(selected_level, 1, LEVELS.size()) - 1
	var level_info: Dictionary = LEVELS[level_idx]
	page_title.text = "GIÁO TRÌNH ĐÀN BẦU · LEVEL %d: %s" % [selected_level, level_info["title"]]
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
	
	if change_course_btn:
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
	
	if change_course_btn:
		change_course_btn.pressed.connect(func() -> void:
			var t := create_tween()
			t.tween_property(self, "modulate:a", 0.0, 0.22)
			t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
		)

func _build_quiz_btn() -> void:
	var toph := $Root/RightContent/TopBar/TopM/TopH as HBoxContainer
	if toph == null or change_course_btn == null:
		return
	var quiz_btn := Button.new()
	quiz_btn.name = "QuizBtn"
	quiz_btn.text = "📝 Quiz"
	quiz_btn.custom_minimum_size = Vector2(148, 48)
	quiz_btn.add_theme_font_size_override("font_size", 17)
	quiz_btn.add_theme_stylebox_override("normal", _flat(Color(0, 0, 0, 0), C_JADE, 24))
	quiz_btn.add_theme_stylebox_override("hover", _flat(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.12), C_GOLD, 24))
	quiz_btn.add_theme_stylebox_override("pressed", _flat(Color(0, 0, 0, 0), C_JADE, 24))
	quiz_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	quiz_btn.add_theme_color_override("font_color", C_JADE)
	quiz_btn.add_theme_color_override("font_hover_color", C_GOLD)
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
	for lesson: Dictionary in get_current_lessons():
		var lid := str(lesson.get("id", ""))
		if not lid.is_empty():
			ids.append(lid)
	QuizScreenScript.quiz_instrument = "dan_bau"
	QuizScreenScript.quiz_local_ids = ids
	QuizScreenScript.quiz_return_scene = "res://scenes/LessonDanBau.tscn"
	_fade_to_scene("res://scenes/QuizScreen.tscn")

func _build_sidebar() -> void:
	var side_s := StyleBoxFlat.new()
	side_s.bg_color = Color(0.93, 0.91, 0.87, 0.6) # Glassmorphism opacity
	side_s.border_color = Color(0.8, 0.78, 0.73, 0.8)
	side_s.border_width_right = 2
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

	if btn_menu: _style_side_icon_btn(btn_menu,     false)
	if btn_courses: _style_side_icon_btn(btn_courses,  true)
	if btn_room: _style_side_icon_btn(btn_room,     false)
	if btn_songs: _style_side_icon_btn(btn_songs,    false)
	if btn_minigame: _style_side_icon_btn(btn_minigame, false)
	if btn_leaderboard: _style_side_icon_btn(btn_leaderboard, false)
	if btn_account: _style_side_icon_btn(btn_account,  false)

	if btn_menu: _attach_icon_draw(btn_menu,     0)
	if btn_courses: _attach_icon_draw(btn_courses,  1)
	if btn_room: _attach_icon_draw(btn_room,     6)
	if btn_songs: _attach_icon_draw(btn_songs,    2)
	if btn_minigame: _attach_icon_draw(btn_minigame, 3)
	if btn_leaderboard: _attach_icon_draw(btn_leaderboard, 4)
	if btn_account: _attach_icon_draw(btn_account,  5)

	for b in [btn_menu, btn_courses, btn_room, btn_songs, btn_minigame, btn_account, btn_leaderboard]:
		if b:
			_make_btn_bouncy(b)

	if btn_menu:
		btn_menu.pressed.connect(func() -> void:
			_fade_to_scene("res://scenes/MainMenu.tscn")
		)
	if btn_courses:
		btn_courses.pressed.connect(func() -> void:
			_fade_to_scene("res://scenes/MainMenu.tscn")
		)
	if btn_room:
		btn_room.pressed.connect(func() -> void:
			_fade_to_scene("res://scenes/VirtualMusicRoom.tscn")
		)
	if btn_songs:
		btn_songs.pressed.connect(func() -> void:
			_fade_to_scene("res://scenes/SongScreen.tscn")
		)
	if btn_minigame:
		btn_minigame.pressed.connect(func() -> void:
			_fade_to_scene("res://scenes/MiniGame.tscn")
		)
	btn_leaderboard.pressed.connect(_on_btn_leaderboard_pressed)
	if btn_account:
		btn_account.pressed.connect(func() -> void:
			_fade_to_scene("res://scenes/AccountScreen.tscn")
		)

func _style_side_icon_btn(btn: Button, is_active: bool, is_locked: bool = false) -> void:
	var bg_n := _flat(Color(0, 0, 0, 0) if not is_active else Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.12), Color(0, 0, 0, 0), 18, 0)
	var bg_h := _flat(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.08) if not is_locked else Color(0, 0, 0, 0), Color(0, 0, 0, 0), 18, 0)
	var bg_p := _flat(Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.20) if not is_locked else Color(0, 0, 0, 0), Color(0, 0, 0, 0), 18, 0)

	bg_n.content_margin_top = 64
	bg_n.content_margin_bottom = 8
	bg_h.content_margin_top = 64
	bg_h.content_margin_bottom = 8
	bg_p.content_margin_top = 64
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
	ic.offset_top = 8;   ic.offset_bottom = 64
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
	lessons_hbox.add_theme_constant_override("separation", 100)
	# Clear existing children
	for child in lessons_hbox.get_children():
		child.queue_free()
		
	var inst := "dan_bau"
	var completed_lessons : Array = SecureDataManager.data.get("completed_lessons", {}).get(inst, [])
	var unlocked_lessons : Array = SecureDataManager.data.get("unlocked_lessons", {}).get(inst, ["dan_bau_level1_bai1_video"])
	
	var f_bold := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	var lessons_data := get_current_lessons()
	
	for i in range(lessons_data.size()):
		var lesson_item : Dictionary = lessons_data[i]
		var id := lesson_item["id"] as String
		var type := lesson_item["type"] as String
		
		# Unlocking checks
		var is_unlocked := false
		if i == 0:
			is_unlocked = true
		else:
			var prev_id := lessons_data[i - 1]["id"] as String
			is_unlocked = unlocked_lessons.has(id) or completed_lessons.has(prev_id)
			
		var is_completed := completed_lessons.has(id)
		
		# Column layout for each lesson
		var col := VBoxContainer.new()
		col.custom_minimum_size = Vector2.ZERO
		col.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 16)
		
		# Top: Lesson Title Label (BÀI 1, BÀI 2, BÀI 3...)
		var title_lbl := Label.new()
		title_lbl.text = lesson_item["title"]
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_lbl.add_theme_color_override("font_color", C_TEXT if is_unlocked else C_TEXT_MUTED)
		title_lbl.add_theme_font_size_override("font_size", 20)
		if f_bold:
			title_lbl.add_theme_font_override("font", f_bold)
		col.add_child(title_lbl)
		
		# Center: Row containing EXACTLY 1 Circle Button per Lesson
		var row := HBoxContainer.new()
		row.name = "Row"
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_child(row)
		
		var btn := Button.new()
		btn.name = "LessonBtn"
		btn.custom_minimum_size = Vector2(220, 220)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		_setup_circle_btn(btn, lesson_item["title"], lesson_item["note"], is_unlocked, is_completed, type)
		row.add_child(btn)
		
		if type == "video":
			btn.pressed.connect(_on_video_pressed.bind(id, lesson_item.get("subtitles", []), is_unlocked))
		else:
			btn.pressed.connect(_on_practice_pressed.bind(id, is_unlocked))
			
		lessons_hbox.add_child(col)

func _on_video_pressed(v_id: String, subtitles: Array, is_unlocked: bool) -> void:
	if not is_unlocked: return
	SecureDataManager.active_lesson_id = v_id
	VideoPlayer.custom_video_path = "res://Video/DanBauDoan12Bai1.ogv"
	VideoPlayer.custom_subtitles = subtitles
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.22)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/VideoPlayer.tscn"))

func _on_practice_pressed(p_id: String, is_unlocked: bool) -> void:
	if not is_unlocked: return
	SecureDataManager.active_lesson_id = p_id
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.22)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/PracticeDanBau.tscn"))

func _setup_circle_btn(btn: Button, action: String, lesson_title: String, unlocked: bool, completed: bool, type: String) -> void:
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if unlocked else Control.CURSOR_ARROW
	btn.disabled = not unlocked

	if completed:
		btn.text = "✓\n%s\nHoàn thành" % lesson_title
	elif unlocked:
		var icon := "🎬" if type == "video" else "🎵"
		var act := "Hướng dẫn" if type == "video" else "Luyện tập"
		btn.text = "%s\n%s\n(%s)" % [icon, act, lesson_title]
	else:
		btn.text = "🔒"

	var bg_color := Color(0.95, 0.93, 0.89, 0.6) # Locked
	var border_color := Color(0.85, 0.82, 0.78, 1.0)
	var text_color := Color(C_MUTED, 0.8)
	
	if completed:
		bg_color = C_JADE
		border_color = C_GOLD
		text_color = Color.WHITE
	elif unlocked:
		bg_color = Color.WHITE
		border_color = C_JADE_LIGHT
		text_color = C_TEXT

	var s_normal := StyleBoxFlat.new()
	s_normal.bg_color = bg_color
	s_normal.border_color = border_color
	s_normal.border_width_left = 6; s_normal.border_width_right = 6
	s_normal.border_width_top = 6; s_normal.border_width_bottom = 6
	s_normal.corner_radius_top_left = 110; s_normal.corner_radius_top_right = 110
	s_normal.corner_radius_bottom_left = 110; s_normal.corner_radius_bottom_right = 110
	
	if unlocked and not completed:
		s_normal.shadow_size = 24
		s_normal.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35)
		
	var s_hover := s_normal.duplicate() as StyleBoxFlat
	if unlocked:
		if completed:
			s_hover.bg_color = bg_color.lightened(0.1)
		else:
			s_hover.bg_color = Color(0.97, 0.97, 0.97, 1.0)

	btn.add_theme_stylebox_override("normal", s_normal)
	btn.add_theme_stylebox_override("hover", s_hover)
	btn.add_theme_stylebox_override("pressed", s_normal)
	btn.add_theme_stylebox_override("disabled", s_normal)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_color_override("font_color", text_color)
	
	var hover_color = text_color
	if unlocked and not completed: hover_color = C_JADE
	btn.add_theme_color_override("font_hover_color", hover_color)
	btn.add_theme_color_override("font_pressed_color", text_color)
	btn.add_theme_color_override("font_disabled_color", text_color)
	
	var f_bold := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if f_bold:
		btn.add_theme_font_override("font", f_bold)
	btn.add_theme_font_size_override("font_size", 16)
	_make_btn_bouncy(btn)

func _draw_connecting_lines() -> void:
	var inst := "dan_bau"
	var completed_lessons : Array = SecureDataManager.data.get("completed_lessons", {}).get(inst, [])
	var unlocked_lessons : Array = SecureDataManager.data.get("unlocked_lessons", {}).get(inst, ["dan_bau_level1_bai1_video"])

	var centers : Array[Vector2] = []
	var node_unlocked : Array[bool] = []

	var lessons_data := get_current_lessons()
	var cols := lessons_hbox.get_children()
	for i in range(cols.size()):
		if i >= lessons_data.size(): break
		var col := cols[i] as VBoxContainer
		if not col: continue
		var row := col.get_node_or_null("Row") as HBoxContainer
		if not row: continue
		
		var btn := row.get_node_or_null("LessonBtn") as Button
		if not btn: continue
		
		# Compute center in HBox local coordinates
		var center := col.position + row.position + btn.position + btn.size / 2.0
		centers.append(center)
		
		var lesson_id := lessons_data[i]["id"] as String
		var is_unlocked := false
		if i == 0:
			is_unlocked = true
		else:
			var prev_id := lessons_data[i - 1]["id"] as String
			is_unlocked = unlocked_lessons.has(lesson_id) or completed_lessons.has(prev_id)
			
		node_unlocked.append(is_unlocked)

	if centers.is_empty():
		return
	var line_y := centers[0].y
	# Draw lines between nodes
	for idx in range(centers.size() - 1):
		var p1 := Vector2(centers[idx].x, line_y)
		var p2 := Vector2(centers[idx + 1].x, line_y)
		
		var active := node_unlocked[idx + 1]
		if active:
			lessons_hbox.draw_line(p1, p2, Color(C_JADE, 0.15), 24.0, true)
			lessons_hbox.draw_line(p1, p2, Color(C_JADE, 0.4), 14.0, true)
			lessons_hbox.draw_line(p1, p2, Color(1.0, 1.0, 1.0, 0.6), 4.0, true)
		else:
			lessons_hbox.draw_line(p1, p2, Color(1.0, 1.0, 1.0, 0.2), 8.0, true)

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
	if change_course_btn:
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
				for btn in row.get_children():
					if btn is Button:
						var sz := Vector2(145, 145) if mobile else Vector2(180, 180)
						btn.custom_minimum_size = sz

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
