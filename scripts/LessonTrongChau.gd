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
const SidebarDrawerScript := preload("res://scripts/ui/SidebarDrawer.gd")

var selected_level: int = 1
var is_unlocked: bool = true

var _drawer

# ─── @onready Refs
@onready var bg_rect           : ColorRect      = $BG
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

# ─── Dynamic Lesson Data (3 Lessons Course)
const LESSONS = [
	{
		"id": "trong_chau_coban_1",
		"title": "BÀI 1",
		"note": "Nhập môn Trống Chầu",
		"video": "Video hướng dẫn: Giảng viên giới thiệu Trống chầu, dùi trống và tư thế gõ.",
		"practice": "Thực hành: Làm quen với mặt trống và tang trống.",
		"subtitles": [
			{"start": 0.0, "end": 2.5, "text": "Chào mừng con đến với Bài học đầu tiên: Nhập môn Trống Chầu."},
			{"start": 2.5, "end": 6.5, "text": "Hãy làm quen với dùi trống và tư thế ngồi chuẩn xác."},
			{"start": 6.5, "end": 10.0, "text": "Bắt đầu bài học ngay nào."}
		]
	},
	{
		"id": "trong_chau_coban_2",
		"title": "BÀI 2",
		"note": "Nhịp Trống Cơ Bản",
		"video": "Video hướng dẫn: Gõ mặt trống (Tùng) và gõ tang trống (Cốc).",
		"practice": "Thực hành: Gõ theo nhịp Tùng Cốc cơ bản.",
		"subtitles": [
			{"start": 0.0, "end": 2.5, "text": "Bài 2: Nhịp Trống Cơ Bản."},
			{"start": 2.5, "end": 6.0, "text": "Tùng là tiếng giữa mặt trống. Cốc là tiếng gõ ngoài tang trống."},
			{"start": 6.0, "end": 10.0, "text": "Cùng lắng nghe và đánh theo."}
		]
	},
	{
		"id": "trong_chau_coban_3",
		"title": "BÀI 3",
		"note": "Tiếng Cốc Vành Gõ",
		"video": "Video hướng dẫn: Tổ hợp âm sắc Tùng - Cốc đan xen.",
		"practice": "Thực hành bài mẫu: Liên Khúc Trống Chầu",
		"subtitles": [
			{"start": 0.0, "end": 3.0, "text": "Bài 3: Liên Khúc Trống Chầu."},
			{"start": 3.0, "end": 6.5, "text": "Chúng ta sẽ kết hợp tiếng mặt trống và tang trống."},
			{"start": 6.5, "end": 10.0, "text": "Tạo ra một nhịp điệu hoàn chỉnh."}
		]
	}
]

func _ready() -> void:
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


func _build_theme() -> void:
	bg_rect.color = C_BG
	
	var tex_path := "res://assets/textures/trong_chau_background.png"
	if ResourceLoader.exists(tex_path):
		var bg_tex := TextureRect.new()
		bg_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg_tex.texture = load(tex_path) as Texture2D
		bg_rect.add_child(bg_tex)
	
	var top_s := StyleBoxFlat.new()
	top_s.bg_color = Color(0.96, 0.95, 0.92, 1.0)
	top_s.border_color = Color(0.8, 0.78, 0.73, 0.8)
	top_s.border_width_bottom = 2
	top_bar.add_theme_stylebox_override("panel", top_s)
	
	page_title.text = "GIÁO TRÌNH TRỐNG CHẦU CƠ BẢN"
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

func _open_quiz() -> void:
	var ids: Array[String] = []
	for lesson: Dictionary in LESSONS:
		var lid := str(lesson.get("id", ""))
		if not lid.is_empty():
			ids.append(lid)
	QuizScreenScript.quiz_instrument = "trong_chau"
	QuizScreenScript.quiz_local_ids = ids
	QuizScreenScript.quiz_return_scene = "res://scenes/LessonTrongChau.tscn"
	_fade_to_scene("res://scenes/QuizScreen.tscn")

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
		
	var inst := "trong_chau"
	var completed_lessons : Array = SecureDataManager.data.get("completed_lessons", {}).get(inst, [])
	var unlocked_lessons : Array = SecureDataManager.data.get("unlocked_lessons", {}).get(inst, ["trong_chau_coban_1_video"])
	
	var f_bold := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	
	for i in range(LESSONS.size()):
		var lesson_item : Dictionary = LESSONS[i]
		var id := lesson_item["id"] as String
		
		# Define task status keys
		var v_id := id + "_video"
		var p_id := id + "_practice"
		
		# Unlocking checks
		var is_v_unlocked := false
		if i == 0:
			is_v_unlocked = true
		else:
			var prev_id := LESSONS[i - 1]["id"] as String
			is_v_unlocked = unlocked_lessons.has(v_id) or completed_lessons.has(prev_id + "_practice")
			
		var is_p_unlocked := is_v_unlocked and (completed_lessons.has(v_id) or unlocked_lessons.has(p_id))
		
		var is_v_completed := completed_lessons.has(v_id)
		var is_p_completed := completed_lessons.has(p_id)
		
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
		title_lbl.add_theme_color_override("font_color", C_TEXT if is_v_unlocked else C_TEXT_MUTED)
		title_lbl.add_theme_font_size_override("font_size", 20)
		if f_bold:
			title_lbl.add_theme_font_override("font", f_bold)
		col.add_child(title_lbl)
		
		# Center: Row of circles connected horizontally
		var row := HBoxContainer.new()
		row.name = "Row"
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 100)
		col.add_child(row)
		
		# 1. Hướng Dẫn Button (Left circle)
		var v_btn := Button.new()
		v_btn.mouse_filter = Control.MOUSE_FILTER_PASS
		v_btn.name = "VideoBtn"
		v_btn.custom_minimum_size = Vector2(220, 220)
		v_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		v_btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		_setup_circle_btn(v_btn, "Hướng dẫn", lesson_item["note"], is_v_unlocked, is_v_completed, "video")
		row.add_child(v_btn)
		
		v_btn.pressed.connect(_on_video_pressed.bind(v_id, lesson_item["subtitles"], is_v_unlocked))
		
		# 2. Thực Hành Button (Right circle)
		var p_btn := Button.new()
		p_btn.mouse_filter = Control.MOUSE_FILTER_PASS
		p_btn.name = "PracticeBtn"
		p_btn.custom_minimum_size = Vector2(220, 220)
		p_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		p_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		p_btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		_setup_circle_btn(p_btn, "Thực hành", lesson_item["note"], is_p_unlocked, is_p_completed, "practice")
		row.add_child(p_btn)
		
		p_btn.pressed.connect(_on_practice_pressed.bind(p_id, is_p_unlocked))
		
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
	t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/PracticeTrongChau.tscn"))

func _setup_circle_btn(btn: Button, action: String, lesson_title: String, unlocked: bool, completed: bool, type: String) -> void:
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if unlocked else Control.CURSOR_ARROW
	btn.disabled = not unlocked

	if completed:
		btn.text = "✓\n%s\nHoàn thành" % action
	elif unlocked:
		var icon := "🎬" if type == "video" else "🎵"
		btn.text = "%s\n%s\n(%s)" % [icon, action, lesson_title]
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
	var inst := "trong_chau"
	var completed_lessons : Array = SecureDataManager.data.get("completed_lessons", {}).get(inst, [])
	var unlocked_lessons : Array = SecureDataManager.data.get("unlocked_lessons", {}).get(inst, ["trong_chau_coban_1_video"])

	var centers : Array[Vector2] = []
	var node_unlocked : Array[bool] = []

	var cols := lessons_hbox.get_children()
	for i in range(cols.size()):
		var col := cols[i] as VBoxContainer
		if not col: continue
		var row := col.get_node_or_null("Row") as HBoxContainer
		if not row: continue
		
		var v_btn := row.get_node_or_null("VideoBtn") as Button
		var p_btn := row.get_node_or_null("PracticeBtn") as Button
		if not v_btn or not p_btn: continue
		
		# Compute centers in HBox local coordinates
		var v_center := col.position + row.position + v_btn.position + v_btn.size / 2.0
		var p_center := col.position + row.position + p_btn.position + p_btn.size / 2.0
		
		centers.append(v_center)
		centers.append(p_center)
		
		var lesson_id := LESSONS[i]["id"] as String
		var p_id := lesson_id + "_practice"
		var is_v_unlocked := false
		if i == 0:
			is_v_unlocked = true
		else:
			var prev_id := LESSONS[i - 1]["id"] as String
			is_v_unlocked = unlocked_lessons.has(lesson_id + "_video") or completed_lessons.has(prev_id + "_practice")
			
		var is_p_unlocked := is_v_unlocked and (completed_lessons.has(lesson_id + "_video") or unlocked_lessons.has(p_id))
		
		node_unlocked.append(is_v_unlocked)
		node_unlocked.append(is_p_unlocked)

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
				for btn in row.get_children():
					if btn is Button:
						var sz := Vector2(145, 145) if mobile else Vector2(180, 180)
						btn.custom_minimum_size = sz

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

func _on_btn_leaderboard_pressed() -> void:
	_fade_to_scene("res://scenes/LeaderboardScreen.tscn")

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
