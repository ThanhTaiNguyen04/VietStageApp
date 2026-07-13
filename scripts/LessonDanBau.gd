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

var _sidebar_icons_cache := {}

# ─── Dynamic Lesson Data (3 Lessons Course)
const LESSONS = [
	{
		"id": "dan_bau_coban_1",
		"title": "BÀI 1",
		"note": "Khám phá \"Độc Huyền Cầm\"",
		"video": "Video hướng dẫn: Giảng viên giới thiệu cấu tạo (Bầu vang, cần đàn, dây, que gảy), tư thế ngồi và cách cầm que gảy tay phải.",
		"practice": "Thực hành (Tạm thời ở phòng luyện Đàn Bầu ảo): Chế độ \"Exploration\". Người dùng làm quen giao diện màn hình: chạm vào dây đàn ảo để nghe âm thanh dây buông.",
		"subtitles": [
			{"start": 0.0, "end": 2.5, "text": "Chào mừng con đến với Bài học đầu tiên: Khám phá Độc Huyền Cầm."},
			{"start": 2.5, "end": 6.5, "text": "Đàn Bầu gồm Bầu vang, cần đàn, dây, que gảy. Hãy lưu ý tư thế ngồi và cách cầm que gảy tay phải."},
			{"start": 6.5, "end": 10.0, "text": "Hãy sẵn sàng để bước vào thế giới của Độc Huyền Cầm nhé."}
		]
	},
	{
		"id": "dan_bau_coban_2",
		"title": "BÀI 2",
		"note": "Kỹ thuật tạo Bồi Âm",
		"video": "Video hướng dẫn: Bí quyết dùng cạnh bàn tay phải chặn nhẹ lên dây và gảy để tạo ra các bồi âm (Harmonics) ở các vị trí nốt khác nhau.",
		"practice": "Thực hành (Tạm thời ở phòng luyện Đàn Bầu ảo): Mini-game \"Dò đúng nốt\". Ứng dụng chia dây đàn ảo thành các vạch điểm chạm (Nodes). Chạm đúng vạch sáng trên màn hình.",
		"subtitles": [
			{"start": 0.0, "end": 2.5, "text": "Chào mừng con đến với Bài 2: Kỹ thuật tạo Bồi Âm."},
			{"start": 2.5, "end": 6.0, "text": "Bí quyết là dùng cạnh bàn tay phải chặn nhẹ lên dây và gảy."},
			{"start": 6.0, "end": 10.0, "text": "Điều này sẽ tạo ra các bồi âm ở các vị trí nốt khác nhau. Cùng thử nhé."}
		]
	},
	{
		"id": "dan_bau_coban_3",
		"title": "BÀI 3",
		"note": "Nốt Rê & Mi",
		"video": "Xem video hướng dẫn nốt Rê & Mi",
		"practice": "Luyện gảy nốt Rê và Mi",
		"subtitles": [
			{"start": 0.0, "end": 3.0, "text": "Chào mừng con đến với Bài 3: Hài âm nốt Rê và Mi."},
			{"start": 3.0, "end": 6.5, "text": "Vị trí hài âm nốt Rê và Mi nằm dịch về phía bên phải một chút so với nốt Đô."},
			{"start": 6.5, "end": 10.0, "text": "Hãy chạm nhẹ và gảy chính xác để nghe âm vang của hai nốt nhạc này."}
		]
	},
	{
		"id": "dan_bau_coban_4",
		"title": "BÀI 4",
		"note": "Uốn vòi",
		"video": "Xem video hướng dẫn uốn vòi đàn",
		"practice": "Luyện uốn vòi đổi âm",
		"subtitles": [
			{"start": 0.0, "end": 3.0, "text": "Chào mừng con đến với Bài 4: Học kỹ thuật Uốn vòi cần đàn Đàn Bầu."},
			{"start": 3.0, "end": 6.5, "text": "Tay trái uốn cần đàn sang trái để kéo căng dây giúp nâng cao cao độ nốt nhạc."},
			{"start": 6.5, "end": 10.0, "text": "Ngược lại, thả lỏng cần sang phải để giảm độ căng giúp hạ thấp cao độ."}
		]
	},
	{
		"id": "dan_bau_coban_5",
		"title": "BÀI 5",
		"note": "Bài mẫu",
		"video": "Xem video hướng dẫn chơi bài mẫu",
		"practice": "Luyện chơi bài Bèo Dạt Mây Trôi",
		"subtitles": [
			{"start": 0.0, "end": 3.0, "text": "Chào mừng con đến với Bài 5: Luyện tập bài Bèo Dạt Mây Trôi."},
			{"start": 3.0, "end": 6.5, "text": "Kết hợp kỹ thuật gảy hài âm nốt Đô, Rê, Mi và uốn cần nhịp nhàng."},
			{"start": 6.5, "end": 10.0, "text": "Hãy cố gắng liên kết các âm vang mềm mại và đúng nhịp điệu bài học nhé."}
		]
	}
]

func _ready() -> void:
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
	bg_rect.color = C_BG
	
	top_bar.add_theme_stylebox_override("panel", _flat(Color("#fffdf8"), Color(C_GOLD, 0.28), 0, 1))
	
	page_title.text = "GIÁO TRÌNH ĐÀN BẦU CƠ BẢN"
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
	var side_s := _flat(Color(0.95, 0.93, 0.89, 1.0), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.15), 0, 0)
	side_s.border_width_left = 0; side_s.border_width_top = 0; side_s.border_width_bottom = 0
	side_s.border_width_right = 2
	side_s.shadow_size = 12
	side_s.shadow_color = Color(0.13, 0.08, 0.05, 0.15)
	side_s.shadow_offset = Vector2(4, 0)
	sidebar.add_theme_stylebox_override("panel", side_s)

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
		
	var inst := "dan_bau"
	var completed_lessons : Array = SecureDataManager.data.get("completed_lessons", {}).get(inst, [])
	var unlocked_lessons : Array = SecureDataManager.data.get("unlocked_lessons", {}).get(inst, ["dan_bau_coban_1_video"])
	
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
		v_btn.name = "VideoBtn"
		v_btn.custom_minimum_size = Vector2(180, 180)
		v_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		v_btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		if is_v_completed:
			v_btn.text = "🎬\nHướng dẫn\n✓"
		elif not is_v_unlocked:
			v_btn.text = "🔒"
		else:
			v_btn.text = "🎬\nHướng dẫn\n(%s)" % lesson_item["note"]
			
		_style_circle_btn(v_btn, is_v_unlocked, is_v_completed)
		_make_btn_bouncy(v_btn)
		row.add_child(v_btn)
		
		v_btn.pressed.connect(_on_video_pressed.bind(v_id, lesson_item["subtitles"], is_v_unlocked))
		
		# 2. Thực Hành Button (Right circle)
		var p_btn := Button.new()
		p_btn.name = "PracticeBtn"
		p_btn.custom_minimum_size = Vector2(180, 180)
		p_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		p_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		p_btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		if is_p_completed:
			p_btn.text = "🎵\nThực hành\n✓"
		elif not is_p_unlocked:
			p_btn.text = "🔒"
		else:
			p_btn.text = "🎵\nThực hành\n(%s)" % lesson_item["note"]
			
		_style_circle_btn(p_btn, is_p_unlocked, is_p_completed)
		_make_btn_bouncy(p_btn)
		row.add_child(p_btn)
		
		p_btn.pressed.connect(_on_practice_pressed.bind(p_id, is_p_unlocked))
		
		lessons_hbox.add_child(col)

func _on_video_pressed(v_id: String, subtitles: Array, is_unlocked: bool) -> void:
	if _has_dragged_significantly or not is_unlocked: return
	SecureDataManager.active_lesson_id = v_id
	VideoPlayer.custom_video_path = "res://Video/coMai_danBau.ogv"
	VideoPlayer.custom_subtitles = subtitles
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.22)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/VideoPlayer.tscn"))

func _on_practice_pressed(p_id: String, is_unlocked: bool) -> void:
	if _has_dragged_significantly or not is_unlocked: return
	SecureDataManager.active_lesson_id = p_id
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.22)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/PracticeDanBau.tscn"))

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
		bg_color = Color.WHITE # Solid white for active
		border_color = C_JADE_LIGHT # Jade border
		text_color = C_TEXT # Dark charcoal text
		
	var s_normal := StyleBoxFlat.new()
	s_normal.bg_color = bg_color
	s_normal.border_color = border_color
	s_normal.border_width_left = 6; s_normal.border_width_right = 6
	s_normal.border_width_top = 6; s_normal.border_width_bottom = 6
	s_normal.corner_radius_top_left = 90; s_normal.corner_radius_top_right = 90
	s_normal.corner_radius_bottom_left = 90; s_normal.corner_radius_bottom_right = 90
	
	# Glow effect for active step (using softer, wider gold shadow)
	if is_unlocked and not is_completed:
		s_normal.shadow_size = 24
		s_normal.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35)
		
	var s_hover := s_normal.duplicate() as StyleBoxFlat
	if is_unlocked:
		if is_completed:
			s_hover.bg_color = bg_color.lightened(0.1)
		else:
			s_hover.bg_color = Color(0.97, 0.97, 0.97, 1.0)
		
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
	btn.add_theme_font_size_override("font_size", 18)
	
	btn.disabled = not is_unlocked

func _draw_connecting_lines() -> void:
	var inst := "dan_bau"
	var completed_lessons : Array = SecureDataManager.data.get("completed_lessons", {}).get(inst, [])
	var unlocked_lessons : Array = SecureDataManager.data.get("unlocked_lessons", {}).get(inst, ["dan_bau_coban_1_video"])

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
