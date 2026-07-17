extends Control

const C_GOLD = Color(0.83, 0.68, 0.21, 1.0)
const C_CREAM = Color(0.99, 0.97, 0.91, 1.0)
const C_DARK_BROWN = Color(0.29, 0.23, 0.19, 1.0)
const C_LIGHT_GREY = Color(0.5, 0.5, 0.5, 1.0)
const C_LOCKED_TXT = Color(0.7, 0.7, 0.7, 1.0)

var _lessons_box: HBoxContainer
var _is_dragging_scroll := false
var _drag_start_x := 0.0
var _scroll_start_x := 0
var _scroll_node: ScrollContainer


func _ready() -> void:
	# 1. Background (No modulate, keep it bright)
	var bg_tex = TextureRect.new()
	bg_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if ResourceLoader.exists("res://image/imagesao.png"):
		bg_tex.texture = load("res://image/imagesao.png")
	elif ResourceLoader.exists("res://assets/textures/bg_practice_room.png"):
		bg_tex.texture = load("res://assets/textures/bg_practice_room.png")
	add_child(bg_tex)
	
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	
	# Header HBox
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	vbox.add_child(header)
	
	# Back Button (Cream style)
	var btn_back = Button.new()
	btn_back.text = "< Quay Lại"
	btn_back.custom_minimum_size = Vector2(140, 50)
	var sb_back = StyleBoxFlat.new()
	sb_back.bg_color = C_CREAM
	sb_back.border_width_left = 2; sb_back.border_width_right = 2
	sb_back.border_width_top = 2; sb_back.border_width_bottom = 2
	sb_back.border_color = C_GOLD
	sb_back.corner_radius_top_left = 15; sb_back.corner_radius_top_right = 15
	sb_back.corner_radius_bottom_left = 15; sb_back.corner_radius_bottom_right = 15
	btn_back.add_theme_stylebox_override("normal", sb_back)
	btn_back.add_theme_stylebox_override("hover", sb_back)
	btn_back.add_theme_stylebox_override("pressed", sb_back)
	btn_back.add_theme_stylebox_override("focus", sb_back)
	btn_back.add_theme_color_override("font_color", C_DARK_BROWN)
	btn_back.add_theme_color_override("font_hover_color", C_GOLD)
	btn_back.add_theme_font_size_override("font_size", 18)
	btn_back.pressed.connect(_on_back_pressed)
	header.add_child(btn_back)
	
	# Titles VBox
	var titles_vbox = VBoxContainer.new()
	titles_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titles_vbox)
	
	var title_label = Label.new()
	title_label.text = SecureDataManager.active_course_title
	if title_label.text == "": title_label.text = "Bấm Ngón & Lấy Hơi"
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", C_GOLD)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titles_vbox.add_child(title_label)
	
	var subtitle = Label.new()
	subtitle.text = "◈ Hành trình chinh phục sáo trúc ◈"
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", C_DARK_BROWN)
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
	_scroll_node = scroll
	scroll.gui_input.connect(_on_scroll_gui_input)
	
	var scroll_margin = MarginContainer.new()
	scroll_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_margin.add_theme_constant_override("margin_top", 0)
	scroll_margin.add_theme_constant_override("margin_bottom", 20)
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
	
	var thumbs = [
		"res://assets/textures/lessons/thumb_flute_base.jpg",
		"res://assets/textures/lessons/thumb_flute_hands.jpg",
		"res://assets/textures/lessons/thumb_flute_notes.jpg",
		"res://assets/textures/lessons/thumb_flute_wind.jpg",
		"res://assets/textures/lessons/thumb_flute_magic.jpg"
	]
	
	for i in range(lesson_count):
		var node_id = start_node + i
		var is_locked = (node_id > unlocked_up_to)
		var is_completed = (node_id < unlocked_up_to)
		var is_active = (node_id == unlocked_up_to)
		
		# Wrapper (to align vertically begin/top to shift up)
		var card_wrapper = Control.new()
		card_wrapper.mouse_filter = Control.MOUSE_FILTER_PASS
		card_wrapper.custom_minimum_size = Vector2(530, 700)
		card_wrapper.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		
		# Build Ornate Card using card.png
		var card = PanelContainer.new()
		card.mouse_filter = Control.MOUSE_FILTER_PASS
		card.set_anchors_preset(Control.PRESET_FULL_RECT)
		
		var sb_card = StyleBoxTexture.new()
		if ResourceLoader.exists("res://image/card.png"):
			sb_card.texture = load("res://image/card.png")
			sb_card.texture_margin_left = 90
			sb_card.texture_margin_right = 90
			sb_card.texture_margin_top = 100
			sb_card.texture_margin_bottom = 85
		
		card.add_theme_stylebox_override("panel", sb_card)
		card_wrapper.add_child(card)
		
		var card_vbox = VBoxContainer.new()
		card_vbox.mouse_filter = Control.MOUSE_FILTER_PASS
		card_vbox.add_theme_constant_override("separation", 15)
		card.add_child(card_vbox)
		
		# Badge Top (Now placed INSIDE the card at the top of the VBox)
		var badge_panel = PanelContainer.new()
		var badge_sb = StyleBoxFlat.new()
		badge_sb.bg_color = C_CREAM
		badge_sb.border_width_left = 2; badge_sb.border_width_right = 2
		badge_sb.border_width_top = 2; badge_sb.border_width_bottom = 2
		badge_sb.border_color = C_GOLD
		badge_sb.corner_radius_top_left = 32; badge_sb.corner_radius_top_right = 32
		badge_sb.corner_radius_bottom_left = 32; badge_sb.corner_radius_bottom_right = 32
		badge_panel.add_theme_stylebox_override("panel", badge_sb)
		badge_panel.custom_minimum_size = Vector2(64, 64)
		badge_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		
		var badge = Label.new()
		badge.text = "%02d" % (i + 1)
		badge.add_theme_font_size_override("font_size", 24)
		badge.add_theme_color_override("font_color", C_DARK_BROWN)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge_panel.add_child(badge)
		card_vbox.add_child(badge_panel)
		
		# Thumbnail Image (Circular)
		var thumb_container = MarginContainer.new()
		var thumb_panel = PanelContainer.new()
		thumb_panel.mouse_filter = Control.MOUSE_FILTER_PASS
		var thumb_sb = StyleBoxFlat.new()
		# Circular clip
		thumb_sb.corner_radius_top_left = 120; thumb_sb.corner_radius_top_right = 120
		thumb_sb.corner_radius_bottom_left = 120; thumb_sb.corner_radius_bottom_right = 120
		thumb_panel.add_theme_stylebox_override("panel", thumb_sb)
		thumb_panel.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
		thumb_panel.custom_minimum_size = Vector2(230, 230)
		thumb_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		
		var thumb_tex = TextureRect.new()
		thumb_tex.mouse_filter = Control.MOUSE_FILTER_PASS
		thumb_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumb_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		thumb_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
		var tex_path = thumbs[i % thumbs.size()]
		if ResourceLoader.exists(tex_path):
			thumb_tex.texture = load(tex_path)
		
		thumb_panel.add_child(thumb_tex)
		thumb_container.add_child(thumb_panel)
		card_vbox.add_child(thumb_container)
		
		# Title & Desc
		var texts_vbox = VBoxContainer.new()
		texts_vbox.mouse_filter = Control.MOUSE_FILTER_PASS
		texts_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		texts_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		texts_vbox.add_theme_constant_override("separation", 6)
		
		var title_text = "Bài Học"
		var desc_text = "Khúc nhạc mới"
		
		var ls = load("res://scripts/LessonSaoTruc.gd")
		if ls and ls.LESSON_NOTES.has("Node" + str(node_id)):
			var data = ls.LESSON_NOTES["Node" + str(node_id)]
			var n = data["note"]
			title_text = data.get("title", "Nốt " + n)
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
		
		var course_name = SecureDataManager.active_course_title
		if "Trống Cơm" in course_name:
			if i == 0: title_text = "Lấy hơi nhanh"; desc_text = "Kỹ thuật ngắt hơi"
			elif i == 1: title_text = "Nhịp điệu dân ca"; desc_text = "Thổi đúng nhịp 2/4"
			elif i == 2: title_text = "Hoàn thành bài"; desc_text = "Ghép toàn bộ bài Trống Cơm"
		elif "Bèo Dạt Mây Trôi" in course_name:
			if i == 0: title_text = "Luyến ngón"; desc_text = "Tạo độ mềm mại cho nốt"
			elif i == 1: title_text = "Vuốt ngón (Glissando)"; desc_text = "Vuốt mượt mà giữa 2 nốt"
			elif i == 2: title_text = "Hoàn thành bài"; desc_text = "Thể hiện trọn vẹn cảm xúc"
		elif "Lý Hoài Nam" in course_name:
			if i == 0: title_text = "Đánh rưỡi cơ bản"; desc_text = "Kỹ thuật rung lưỡi (Flutter)"
			elif i == 1: title_text = "Đánh rưỡi liên tục"; desc_text = "Kết hợp luồng hơi mạnh"
			elif i == 2: title_text = "Hoàn thành bài"; desc_text = "Biểu diễn Lý Hoài Nam"
		elif "Xuân Về Bản Mèo" in course_name:
			if i == 0: title_text = "Reo lưỡi kép"; desc_text = "T-K T-K"
			elif i == 1: title_text = "Phi yến"; desc_text = "Vút ngón nhanh"
			elif i == 2: title_text = "Tiết tấu Tây Bắc"; desc_text = "Nhịp điệu đặc trưng"
			elif i == 3: title_text = "Tốc độ cao"; desc_text = "Rèn luyện ngón bấm nhanh"
			elif i == 4: title_text = "Hoàn thành tác phẩm"; desc_text = "Biểu diễn chuyên nghiệp"
		elif "Cây Trúc Xinh" in course_name:
			if i == 0: title_text = "Nhịp phách cơ bản"; desc_text = "Nghe và theo nhịp trống"
			elif i == 1: title_text = "Thổi đệm"; desc_text = "Phối hợp với ca sĩ"
			elif i == 2: title_text = "Hoàn thành bài"; desc_text = "Biểu diễn Hòa Tấu"
		elif "Gặp Mẹ Trong Mơ" in course_name:
			if i == 0: title_text = "Câu A1 (Thấp)"; desc_text = "re re re re la sol..."
			elif i == 1: title_text = "Câu A2 (Rê2)"; desc_text = "re re re re la sol, do2..."
			elif i == 2: title_text = "Câu B1 (Trung)"; desc_text = "la la re2 do2 re2..."
			elif i == 3: title_text = "Câu B2 (Mẹ dịu hiền)"; desc_text = "fa fa fa fa do2 la..."
			elif i == 4: title_text = "Điệp khúc C1 (Cao)"; desc_text = "la la la la fa2 re2..."
			elif i == 5: title_text = "Điệp khúc C2"; desc_text = "fa fa fa fa do2 la..."
			elif i == 6: title_text = "Dạo nhạc (Gian tấu)"; desc_text = "re fa sol la do2 sol-la..."
			elif i == 7: title_text = "Hòa tấu trọn vẹn"; desc_text = "Ghép toàn bộ bài Gặp Mẹ Trong Mơ"
		
		var lbl_title = Label.new()
		lbl_title.mouse_filter = Control.MOUSE_FILTER_PASS
		lbl_title.text = title_text
		lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_title.add_theme_font_size_override("font_size", 28)
		lbl_title.add_theme_color_override("font_color", C_DARK_BROWN if not is_locked else C_LOCKED_TXT)
		lbl_title.autowrap_mode = TextServer.AUTOWRAP_WORD
		var title_sb = StyleBoxEmpty.new()
		lbl_title.add_theme_stylebox_override("normal", title_sb)
		texts_vbox.add_child(lbl_title)
		
		var lbl_desc = Label.new()
		lbl_desc.mouse_filter = Control.MOUSE_FILTER_PASS
		lbl_desc.text = desc_text
		lbl_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_desc.add_theme_font_size_override("font_size", 18)
		lbl_desc.add_theme_color_override("font_color", C_LIGHT_GREY if not is_locked else C_LOCKED_TXT)
		lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
		texts_vbox.add_child(lbl_desc)
		
		card_vbox.add_child(texts_vbox)
		
		# Bottom Action
		var bottom_margin = MarginContainer.new()
		bottom_margin.add_theme_constant_override("margin_left", 70)
		bottom_margin.add_theme_constant_override("margin_right", 70)
		bottom_margin.add_theme_constant_override("margin_bottom", 15)
		
		if is_locked:
			var lock_hb = HBoxContainer.new()
			lock_hb.alignment = BoxContainer.ALIGNMENT_CENTER
			var lock_lbl = Label.new()
			lock_lbl.text = "🔒 Hoàn thành Bài " + str(i) + " để mở khóa"
			lock_lbl.add_theme_font_size_override("font_size", 16)
			lock_lbl.add_theme_color_override("font_color", C_LOCKED_TXT)
			lock_hb.add_child(lock_lbl)
			bottom_margin.add_child(lock_hb)
		else:
			var btn_start = Button.new()
			btn_start.text = "Bắt đầu ►" if not is_completed else "Ôn lại ►"
			btn_start.custom_minimum_size = Vector2(0, 56)
			btn_start.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			
			var sb_btn = StyleBoxFlat.new()
			sb_btn.corner_radius_top_left = 28; sb_btn.corner_radius_top_right = 28
			sb_btn.corner_radius_bottom_left = 28; sb_btn.corner_radius_bottom_right = 28
			sb_btn.bg_color = C_GOLD
			btn_start.add_theme_color_override("font_color", Color.WHITE)
				
			btn_start.add_theme_stylebox_override("normal", sb_btn)
			var sb_btn_hover = sb_btn.duplicate() as StyleBoxFlat
			sb_btn_hover.bg_color = sb_btn.bg_color.lightened(0.2)
			btn_start.add_theme_stylebox_override("hover", sb_btn_hover)
			btn_start.add_theme_stylebox_override("pressed", sb_btn)
			btn_start.add_theme_stylebox_override("focus", sb_btn)
			btn_start.add_theme_font_size_override("font_size", 20)
			
			btn_start.pressed.connect(func():
				_on_lesson_selected(node_id)
			)
			bottom_margin.add_child(btn_start)
			
		card_vbox.add_child(bottom_margin)
		_lessons_box.add_child(card_wrapper)

func _get_max_unlocked_node(inst: String) -> int:
	return 99 # Temporarily unlocked all

func _on_lesson_selected(node_id: int) -> void:
	SecureDataManager.active_lesson_id = "Node" + str(node_id)
	var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
	
	if inst == "sao_truc":
		# Dynamically load song data for PracticeRoom
		# Nodes 19-28 are Trống Cơm sequence lessons inside LessonSaoTruc.tscn,
		# so they do not need PracticeRoom initialization here.
		if node_id == 29:
			PracticeSaoTruc.current_song_title = "Bèo Dạt Mây Trôi - Luyến ngón"
			PracticeSaoTruc.current_song_sheet = ["Mi", "Sol", "La", "Sol", "Mi"]
			PracticeSaoTruc.current_song_durations = [1.0, 1.0, 2.0, 1.0, 2.0]
		elif node_id == 30:
			PracticeSaoTruc.current_song_title = "Bèo Dạt Mây Trôi - Vuốt ngón"
			PracticeSaoTruc.current_song_sheet = ["Rê", "Mi", "Rê", "Đô"]
			PracticeSaoTruc.current_song_durations = [1.0, 1.0, 1.0, 3.0]
		elif node_id == 31:
			PracticeSaoTruc.current_song_title = "Bèo Dạt Mây Trôi - Toàn bài"
			PracticeSaoTruc.current_song_sheet = ["Đô", "Mi", "Sol", "La", "Sol", "Mi", "Rê", "Mi", "Rê", "Đô", "Đô"]
			PracticeSaoTruc.current_song_durations = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0]
		elif node_id == 32:
			PracticeSaoTruc.current_song_title = "Cây Trúc Xinh - Mở đầu"
			PracticeSaoTruc.current_song_sheet = ["La", "Đô2", "La", "Sol", "Mi"]
			PracticeSaoTruc.current_song_durations = [1.0, 1.0, 1.0, 1.0, 2.0]
		elif node_id == 33:
			PracticeSaoTruc.current_song_title = "Cây Trúc Xinh - Phân đoạn 2"
			PracticeSaoTruc.current_song_sheet = ["Sol", "La", "Sol", "Mi", "Rê", "Đô"]
			PracticeSaoTruc.current_song_durations = [1.0, 1.0, 1.0, 1.0, 1.0, 2.0]
		elif node_id == 34:
			PracticeSaoTruc.current_song_title = "Cây Trúc Xinh - Toàn bài"
			PracticeSaoTruc.current_song_sheet = ["La", "Đô2", "La", "Sol", "Mi", "Sol", "La", "Sol", "Mi", "Rê", "Đô"]
			PracticeSaoTruc.current_song_durations = [1.0, 1.0, 1.0, 1.0, 2.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0]
		elif node_id == 35:
			PracticeSaoTruc.current_song_title = "Gặp Mẹ Trong Mơ - Câu 1"
			PracticeSaoTruc.current_song_sheet = ["Rê", "Rê", "Rê", "Rê", "La", "Sol", "Mi", "Mi", "Mi", "Mi", "Fa", "Rê"]
			PracticeSaoTruc.current_song_durations = [1.0, 1.0, 1.0, 1.0, 1.0, 2.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0]
		elif node_id == 36:
			PracticeSaoTruc.current_song_title = "Gặp Mẹ Trong Mơ - Câu 2"
			PracticeSaoTruc.current_song_sheet = ["Rê", "Rê", "Rê", "Rê", "La", "Sol", "Đô2", "Đô2", "Đô2", "Đô2", "Rê2", "La"]
			PracticeSaoTruc.current_song_durations = [1.0, 1.0, 1.0, 1.0, 1.0, 2.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0]
		elif node_id == 37:
			PracticeSaoTruc.current_song_title = "Gặp Mẹ Trong Mơ - Câu 3"
			PracticeSaoTruc.current_song_sheet = ["La", "La", "Rê2", "Đô2", "Rê2", "Rê2", "Đô2", "Rê2", "Đô2", "La", "Sol"]
			PracticeSaoTruc.current_song_durations = [1.0, 1.0, 1.0, 1.0, 1.0, 2.0, 1.0, 1.0, 1.0, 1.0, 2.0]
		elif node_id == 38:
			PracticeSaoTruc.current_song_title = "Gặp Mẹ Trong Mơ - Câu 4"
			PracticeSaoTruc.current_song_sheet = ["Fa", "Fa", "Fa", "Fa", "Đô2", "La", "Đô2", "Sol", "Sol", "La", "Rê"]
			PracticeSaoTruc.current_song_durations = [1.0, 1.0, 1.0, 1.0, 1.0, 2.0, 1.0, 1.0, 1.0, 1.0, 2.0]
		elif node_id == 39:
			PracticeSaoTruc.current_song_title = "Gặp Mẹ Trong Mơ - Điệp khúc 1"
			PracticeSaoTruc.current_song_sheet = ["La", "La", "La", "La", "Fa2", "Rê2", "Đô2", "Rê2", "Đô2", "La", "Sol"]
			PracticeSaoTruc.current_song_durations = [1.0, 1.0, 1.0, 1.0, 1.0, 2.0, 1.0, 1.0, 1.0, 1.0, 2.0]
		elif node_id == 40:
			PracticeSaoTruc.current_song_title = "Gặp Mẹ Trong Mơ - Điệp khúc 2"
			PracticeSaoTruc.current_song_sheet = ["Fa", "Fa", "Fa", "Fa", "Đô2", "La", "Đô2", "Sol", "Sol", "La", "Rê"]
			PracticeSaoTruc.current_song_durations = [1.0, 1.0, 1.0, 1.0, 1.0, 2.0, 1.0, 1.0, 1.0, 1.0, 2.0]
		elif node_id == 41:
			PracticeSaoTruc.current_song_title = "Gặp Mẹ Trong Mơ - Dạo nhạc"
			PracticeSaoTruc.current_song_sheet = ["Rê", "Fa", "Sol", "La", "Đô2", "Sol", "La", "Rê", "Fa", "La", "Sol", "La", "Fa", "Rê", "Rê2", "La", "Fa2", "Mi2", "Rê2", "Đô2", "Rê2", "Sol", "La", "Rê", "Fa", "La", "Sol", "La", "Fa", "Rê"]
			PracticeSaoTruc.current_song_durations = [0.5, 0.5, 0.5, 0.5, 1.0, 0.5, 1.5, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 1.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.5, 0.5, 1.5, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 2.0]
		elif node_id == 42:
			PracticeSaoTruc.current_song_title = "Gặp Mẹ Trong Mơ - Toàn bài"
			PracticeSaoTruc.current_song_sheet = ["Rê", "Rê", "Rê", "Rê", "La", "Sol", "Mi", "Mi", "Mi", "Mi", "Fa", "Rê", "Rê", "Rê", "Rê", "La", "Sol", "Đô2", "Đô2", "Đô2", "Đô2", "Rê2", "La", "La", "La", "Rê2", "Đô2", "Rê2", "Rê2", "Đô2", "Rê2", "Đô2", "La", "Sol", "Fa", "Fa", "Fa", "Fa", "Đô2", "La", "Đô2", "Sol", "Sol", "La", "Rê", "La", "La", "La", "La", "Fa2", "Rê2", "Đô2", "Rê2", "Đô2", "La", "Sol", "Fa", "Fa", "Fa", "Fa", "Đô2", "La", "Đô2", "Sol", "Sol", "La", "Rê", "Fa", "Fa", "Fa", "Đô2", "La", "Đô2", "Sol", "La", "Rê2"]
			PracticeSaoTruc.current_song_durations = [0.5, 0.5, 0.5, 0.5, 1.0, 1.5, 0.5, 0.5, 0.5, 0.5, 1.0, 1.5, 0.5, 0.5, 0.5, 0.5, 1.0, 1.5, 0.5, 0.5, 0.5, 0.5, 1.0, 1.5, 0.5, 0.5, 1.0, 0.5, 1.0, 1.0, 0.5, 0.5, 0.5, 1.0, 1.5, 0.5, 0.5, 0.5, 0.5, 1.0, 1.0, 0.5, 0.5, 0.5, 1.0, 1.5, 0.5, 0.5, 0.5, 0.5, 1.0, 1.5, 0.5, 0.5, 0.5, 1.0, 1.5, 0.5, 0.5, 0.5, 0.5, 1.0, 1.0, 0.5, 0.5, 0.5, 1.0, 1.5, 0.5, 0.5, 0.5, 1.0, 1.0, 0.5, 1.0, 2.0]
		elif node_id == 43:
			PracticeSaoTruc.current_song_title = "Lý Hoài Nam - Flutter 1"
			PracticeSaoTruc.current_song_sheet = ["Đô", "Đô", "Rê", "Mi", "Mi"]
			PracticeSaoTruc.current_song_durations = [1.0, 1.0, 1.0, 1.0, 2.0]
		elif node_id == 44:
			PracticeSaoTruc.current_song_title = "Lý Hoài Nam - Flutter 2"
			PracticeSaoTruc.current_song_sheet = ["Fa", "Sol", "Fa", "Mi", "Rê", "Đô"]
			PracticeSaoTruc.current_song_durations = [1.0, 1.0, 1.0, 1.0, 1.0, 2.0]
		elif node_id == 45:
			PracticeSaoTruc.current_song_title = "Lý Hoài Nam - Toàn bài"
			PracticeSaoTruc.current_song_sheet = ["Đô", "Đô", "Rê", "Mi", "Mi", "Fa", "Sol", "Fa", "Mi", "Rê", "Đô"]
			PracticeSaoTruc.current_song_durations = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0]
		elif node_id == 46:
			PracticeSaoTruc.current_song_title = "Xuân Về Bản Mèo - Phân đoạn 1"
			PracticeSaoTruc.current_song_sheet = ["Mi2", "Rê2", "Đô2", "La", "Đô2"]
			PracticeSaoTruc.current_song_durations = [1.0, 1.0, 1.0, 1.0, 2.0]
		elif node_id == 47:
			PracticeSaoTruc.current_song_title = "Xuân Về Bản Mèo - Phân đoạn 2"
			PracticeSaoTruc.current_song_sheet = ["Mi2", "Sol2", "Mi2", "Rê2", "Mi2"]
			PracticeSaoTruc.current_song_durations = [1.0, 1.0, 1.0, 1.0, 2.0]
		elif node_id == 48:
			PracticeSaoTruc.current_song_title = "Xuân Về Bản Mèo - Phân đoạn 3"
			PracticeSaoTruc.current_song_sheet = ["La", "Đô2", "Rê2", "Mi2", "Rê2"]
			PracticeSaoTruc.current_song_durations = [1.0, 1.0, 1.0, 1.0, 2.0]
		elif node_id == 49:
			PracticeSaoTruc.current_song_title = "Xuân Về Bản Mèo - Phân đoạn 4"
			PracticeSaoTruc.current_song_sheet = ["Rê2", "Đô2", "La", "Sol", "La"]
			PracticeSaoTruc.current_song_durations = [1.0, 1.0, 1.0, 1.0, 2.0]
		elif node_id == 50:
			PracticeSaoTruc.current_song_title = "Xuân Về Bản Mèo - Toàn bài"
			PracticeSaoTruc.current_song_sheet = ["Mi2", "Rê2", "Đô2", "La", "Đô2", "Mi2", "Sol2", "Mi2", "Rê2", "Mi2", "La", "Đô2", "Rê2", "Mi2", "Rê2", "Đô2", "La", "Sol", "La"]
			PracticeSaoTruc.current_song_durations = [0.5, 0.5, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 1.0]
		else:
			PracticeSaoTruc.current_song_title = ""
			PracticeSaoTruc.current_song_sheet.clear()
			PracticeSaoTruc.current_song_durations.clear()
	
	var t = create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.25)
	t.tween_callback(func() -> void: 
		if node_id == 1:
			get_tree().change_scene_to_file("res://scenes/VideoPlayer.tscn")
		else:
			if inst == "dan_tranh":
				get_tree().change_scene_to_file("res://scenes/PracticeRoom.tscn")
			elif inst == "dan_bau":
				get_tree().change_scene_to_file("res://scenes/PracticeDanBau.tscn")
			elif inst == "trong_chau":
				get_tree().change_scene_to_file("res://scenes/PracticeTrongChau.tscn")
			else:
				if node_id <= 28 or (node_id >= 35 and node_id <= 42):
					get_tree().change_scene_to_file("res://scenes/LessonSaoTruc.tscn")
				else:
					get_tree().change_scene_to_file("res://scenes/PracticeSaoTruc.tscn")
	)

func _on_back_pressed() -> void:
	var t = create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.25)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/VirtualMusicRoom.tscn"))

func _on_scroll_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_is_dragging_scroll = true
				_drag_start_x = event.global_position.x
				_scroll_start_x = _scroll_node.scroll_horizontal
			else:
				_is_dragging_scroll = false
	elif event is InputEventMouseMotion:
		if _is_dragging_scroll:
			var diff = event.global_position.x - _drag_start_x
			_scroll_node.scroll_horizontal = _scroll_start_x - int(diff)
