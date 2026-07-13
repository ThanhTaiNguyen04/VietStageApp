extends Control

const C_GOLD = Color(0.85, 0.65, 0.35, 1.0)
const C_CREAM = Color(0.95, 0.90, 0.80, 1.0)
const C_TERRACOTTA = Color(0.76, 0.42, 0.23, 1.0)
const C_WOOD_BG = Color(0.12, 0.09, 0.06, 1.0)
const C_LOCKED_TXT = Color(0.5, 0.45, 0.4, 1.0)

var _lessons_box: HBoxContainer

func _ready() -> void:
	# 1. Background
	var bg_tex = TextureRect.new()
	bg_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	# Load a premium background if available, else fallback
	if ResourceLoader.exists("res://assets/textures/bg_main_menu.png"):
		bg_tex.texture = load("res://assets/textures/bg_main_menu.png")
	elif ResourceLoader.exists("res://assets/textures/bg_practice_room.png"):
		bg_tex.texture = load("res://assets/textures/bg_practice_room.png")
	# Darken the background
	bg_tex.modulate = Color(1.0, 1.0, 1.0, 1.0)
	add_child(bg_tex)
	
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)
	
	# Header HBox
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	vbox.add_child(header)
	
	# Back Button
	var btn_back = Button.new()
	btn_back.text = "< Quay Lại"
	btn_back.custom_minimum_size = Vector2(140, 50)
	var sb_back = StyleBoxFlat.new()
	sb_back.bg_color = Color(0,0,0,0)
	sb_back.border_width_left = 2; sb_back.border_width_right = 2
	sb_back.border_width_top = 2; sb_back.border_width_bottom = 2
	sb_back.border_color = C_GOLD
	sb_back.corner_radius_top_left = 25; sb_back.corner_radius_top_right = 25
	sb_back.corner_radius_bottom_left = 25; sb_back.corner_radius_bottom_right = 25
	btn_back.add_theme_stylebox_override("normal", sb_back)
	btn_back.add_theme_stylebox_override("hover", sb_back)
	btn_back.add_theme_stylebox_override("pressed", sb_back)
	btn_back.add_theme_stylebox_override("focus", sb_back)
	btn_back.add_theme_color_override("font_color", C_CREAM)
	btn_back.add_theme_color_override("font_hover_color", C_TERRACOTTA)
	btn_back.add_theme_font_size_override("font_size", 18)
	btn_back.pressed.connect(_on_back_pressed)
	header.add_child(btn_back)
	
	# Titles VBox
	var titles_vbox = VBoxContainer.new()
	titles_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titles_vbox)
	
	var title_label = Label.new()
	title_label.text = SecureDataManager.active_course_title
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", C_GOLD)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titles_vbox.add_child(title_label)
	
	var subtitle = Label.new()
	subtitle.text = "◈ Hành trình chinh phục sáo trúc ◈"
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", C_CREAM)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titles_vbox.add_child(subtitle)
	
	var chapter_badge = Label.new()
	chapter_badge.text = "Chương 1"
	chapter_badge.add_theme_font_size_override("font_size", 22)
	chapter_badge.add_theme_color_override("font_color", C_GOLD)
	chapter_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sb_badge = StyleBoxFlat.new()
	sb_badge.bg_color = Color(0,0,0,0)
	sb_badge.border_width_bottom = 2
	sb_badge.border_color = C_GOLD
	sb_badge.content_margin_left = 20; sb_badge.content_margin_right = 20
	sb_badge.content_margin_bottom = 5
	chapter_badge.add_theme_stylebox_override("normal", sb_badge)
	chapter_badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	titles_vbox.add_child(chapter_badge)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(140, 50)
	header.add_child(spacer)
	
	# Scroll area
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	
	var scroll_margin = MarginContainer.new()
	scroll_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_margin.add_theme_constant_override("margin_top", 40)
	scroll_margin.add_theme_constant_override("margin_bottom", 40)
	scroll.add_child(scroll_margin)
	
	_lessons_box = HBoxContainer.new()
	_lessons_box.add_theme_constant_override("separation", 30)
	scroll_margin.add_child(_lessons_box)
	
	_build_lessons()

func _build_lessons() -> void:
	var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
	var unlocked_up_to = _get_max_unlocked_node(inst)
	var start_node = SecureDataManager.active_course_start_node
	var lesson_count = SecureDataManager.active_course_node_count
	
	for i in range(lesson_count):
		var node_id = start_node + i
		var is_locked = (node_id > unlocked_up_to)
		var is_completed = (node_id < unlocked_up_to)
		var is_active = (node_id == unlocked_up_to)
		
		# Build Premium Card
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(360, 580)
		card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var sb_card = StyleBoxFlat.new()
		sb_card.bg_color = C_WOOD_BG
		sb_card.corner_radius_top_left = 30; sb_card.corner_radius_top_right = 30
		sb_card.corner_radius_bottom_left = 30; sb_card.corner_radius_bottom_right = 30
		sb_card.border_width_left = 3; sb_card.border_width_right = 3
		sb_card.border_width_top = 3; sb_card.border_width_bottom = 3
		sb_card.border_color = Color(0.25, 0.2, 0.15, 1.0)
		
		if is_active:
			sb_card.border_color = C_GOLD
			sb_card.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.4)
			sb_card.shadow_size = 25
			sb_card.bg_color = Color(0.18, 0.13, 0.08, 1.0)
		
		card.add_theme_stylebox_override("panel", sb_card)
		
		var card_vbox = VBoxContainer.new()
		card.add_child(card_vbox)
		
		# Badge Top (e.g. 01)
		var badge_margin = MarginContainer.new()
		badge_margin.add_theme_constant_override("margin_top", 15)
		var badge = Label.new()
		badge.text = "%02d" % (i + 1)
		badge.add_theme_font_size_override("font_size", 36)
		badge.add_theme_color_override("font_color", C_GOLD if is_active else C_LOCKED_TXT)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge_margin.add_child(badge)
		card_vbox.add_child(badge_margin)
		
		# Icon or Spacer instead of Image
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 10)
		card_vbox.add_child(spacer)
		
		# Title & Desc
		var texts_vbox = VBoxContainer.new()
		texts_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		texts_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var title_text = "Bài Học"
		var desc_text = "Khúc nhạc mới"
		
		var ls = load("res://scripts/LessonSaoTruc.gd")
		if ls and ls.LESSON_NOTES.has("Node" + str(node_id)):
			var data = ls.LESSON_NOTES["Node" + str(node_id)]
			var n = data["note"]
			title_text = "Nốt " + n
			desc_text = data["desc"]
			
			if "Thi Đấu" in data["desc"]:
				title_text = data["desc"]
				desc_text = "Rhythm Game"
			elif "Câu" in data["desc"]:
				title_text = data["desc"]
				desc_text = "Ghép câu nhạc"
				
		if node_id == 2: title_text = "Làm quen với nốt Si"; desc_text = "Giới thiệu nốt Si trên sáo trúc"
		elif node_id == 3: title_text = "Nốt La"; desc_text = "Hướng dẫn cầm và bấm nốt La"
		elif node_id == 4: title_text = "Nốt Sol"; desc_text = "Lấy hơi đúng cách thổi nốt Sol"
		elif node_id == 5: title_text = "Nốt Fa"; desc_text = "Học vị trí ngón tay nốt Fa"
		elif node_id == 6: title_text = "Nốt Mi"; desc_text = "Luyện tập nốt Mi chuẩn"
		elif node_id == 7: title_text = "Nốt Rê"; desc_text = "Cảm nhận âm sắc nốt Rê"
		elif node_id == 8: title_text = "Nốt Đô"; desc_text = "Ôn tập và hoàn thành nốt Đô"
		
		var lbl_title = Label.new()
		lbl_title.text = title_text
		lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_title.add_theme_font_size_override("font_size", 32)
		lbl_title.add_theme_color_override("font_color", C_CREAM if not is_locked else C_LOCKED_TXT)
		lbl_title.autowrap_mode = TextServer.AUTOWRAP_WORD
		texts_vbox.add_child(lbl_title)
		
		var lbl_desc = Label.new()
		lbl_desc.text = desc_text
		lbl_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_desc.add_theme_font_size_override("font_size", 22)
		lbl_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0) if not is_locked else C_LOCKED_TXT)
		lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
		texts_vbox.add_child(lbl_desc)
		
		card_vbox.add_child(texts_vbox)
		
		# Bottom Action
		var bottom_margin = MarginContainer.new()
		bottom_margin.add_theme_constant_override("margin_left", 20)
		bottom_margin.add_theme_constant_override("margin_right", 20)
		bottom_margin.add_theme_constant_override("margin_bottom", 25)
		
		if is_locked:
			var lock_hb = HBoxContainer.new()
			lock_hb.alignment = BoxContainer.ALIGNMENT_CENTER
			var lock_lbl = Label.new()
			lock_lbl.text = "🔒 Hoàn thành Bài " + str(i) + " để mở khóa"
			lock_lbl.add_theme_font_size_override("font_size", 20)
			lock_lbl.add_theme_color_override("font_color", C_LOCKED_TXT)
			lock_hb.add_child(lock_lbl)
			bottom_margin.add_child(lock_hb)
		else:
			var btn_start = Button.new()
			btn_start.text = "Bắt đầu ►" if not is_completed else "Ôn lại ►"
			btn_start.custom_minimum_size = Vector2(0, 60)
			btn_start.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			
			var sb_btn = StyleBoxFlat.new()
			sb_btn.corner_radius_top_left = 15; sb_btn.corner_radius_top_right = 15
			sb_btn.corner_radius_bottom_left = 15; sb_btn.corner_radius_bottom_right = 15
			if is_active:
				sb_btn.bg_color = C_GOLD
				btn_start.add_theme_color_override("font_color", C_WOOD_BG)
				sb_btn.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.5)
				sb_btn.shadow_size = 20
			else:
				sb_btn.bg_color = Color(0.3, 0.3, 0.3, 1.0)
				btn_start.add_theme_color_override("font_color", C_CREAM)
				
			btn_start.add_theme_stylebox_override("normal", sb_btn)
			var sb_btn_hover = sb_btn.duplicate() as StyleBoxFlat
			sb_btn_hover.bg_color = sb_btn.bg_color.lightened(0.2)
			btn_start.add_theme_stylebox_override("hover", sb_btn_hover)
			btn_start.add_theme_stylebox_override("pressed", sb_btn)
			btn_start.add_theme_stylebox_override("focus", sb_btn)
			btn_start.add_theme_font_size_override("font_size", 26)
			
			btn_start.pressed.connect(func():
				_on_lesson_selected(node_id)
			)
			bottom_margin.add_child(btn_start)
			
		card_vbox.add_child(bottom_margin)
		_lessons_box.add_child(card)

func _get_max_unlocked_node(inst: String) -> int:
	return 99 # Temporarily unlocked all

func _on_lesson_selected(node_id: int) -> void:
	SecureDataManager.active_lesson_id = "Node" + str(node_id)
	var t = create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.25)
	t.tween_callback(func() -> void: 
		if node_id == 1:
			get_tree().change_scene_to_file("res://scenes/VideoPlayer.tscn")
		else:
			var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
			if inst == "dan_tranh":
				get_tree().change_scene_to_file("res://scenes/PracticeRoom.tscn")
			elif inst == "dan_bau":
				get_tree().change_scene_to_file("res://scenes/PracticeDanBau.tscn")
			else:
				get_tree().change_scene_to_file("res://scenes/LessonSaoTruc.tscn")
	)

func _on_back_pressed() -> void:
	var t = create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.25)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
