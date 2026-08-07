extends Control
class_name LessonDanTranhList

const C_BG := Color("#faf8f5")
const C_SIDEBAR := Color("#f3efe3")
const C_JADE := Color("#173f2d")
const C_JADE_LIGHT := Color("#245f43")
const C_GOLD := Color("#c59626")
const C_GOLD_LIGHT := Color("#f0cb62")
const C_TEXT := Color("#21140d")
const C_MUTED := Color("#6f6257")
const C_CARD := Color("#fffdf8")

const QuizScreenScript := preload("res://scripts/QuizScreen.gd")

static var selected_level: int = 1
const REQUIRE_SEQUENTIAL_UNLOCK := false # Tạm mở toàn bộ bài; đổi thành true để khôi phục lộ trình tuần tự.
var _sidebar_icon_cache: Dictionary = {}

const LEVELS := [
	{
		"level": 1,
		"title": "NHẬP MÔN ĐÀN TRANH & CÁCH ĐỌC NỐT",
		"sessions": "Bài 1–3",
		"objective": "Làm quen tư thế ngồi, đặt đàn, giới thiệu nhạc cụ 17 dây và làm quen giao diện ứng dụng.",
		"lessons": [
			{
				"number": 1,
				"title": "Tư thế ngồi & Đặt đàn tay trên Tranh",
				"video": "Hướng dẫn tư thế ngồi thẳng lưng, cách đặt đàn lên giá đỡ, giới thiệu các bộ phận của Đàn Tranh 17 dây.",
				"practice": "Nhận biết âm sắc dây đàn: thực hành gảy các nốt cơ bản Sol1 – La1 – Đô2 – Rê2 – Mi2 lần lượt từ dây trầm.",
				"practice_title": "Tư thế & Làm quen 5 nốt cơ bản",
				"sheet": ["Sol1", "La1", "Đô2", "Rê2", "Mi2"]
			},
			{
				"number": 2,
				"title": "Học tiếp các nốt còn lại trên đàn tranh",
				"video": "Kỹ thuật gảy ngón cái, ngón trỏ và cách nhận diện hướng rơi của các nốt nhạc trên khuông nhạc ứng dụng.",
				"practice": "Luyện tập đọc nốt rơi trên màn hình: gảy các nốt nhạc tương ứng khi chạm vạch phách.",
				"practice_title": "Luyện đọc nốt rơi",
				"sheet": ["Đô2", "Rê2", "Mi2", "Rê2", "Đô2", "Mi2"]
			},
			{
				"number": 3,
				"title": "Nhận diện cao độ 17 dây đàn",
				"video": "Giới thiệu cao độ của 17 dây đàn Tranh từ trầm đến cao và mối liên hệ giữa nốt nhạc trên giấy với phím đàn thật.",
				"practice": "Thực hành đệm theo câu bài Sứ Thanh Hoa: gảy các nốt khuyết tương ứng cao độ dây để học thuộc vị trí.",
				"practice_title": "Học cao độ qua đệm Sứ Thanh Hoa",
				"sheet": [
					"Rê3", "Đô3", "La2", "Đô3", "Đô3", "La2", "Đô3", "Đô3", "La2", "Đô3", "La2", "Sol2",
					"Rê3", "Đô3", "La2", "Đô3", "Đô3", "La2", "Đô3", "Đô3", "Mi3", "Rê3", "Đô3", "Sol2", "La2", "Mi3",
					"Mi3", "Rê3", "Mi3", "Rê3", "Mi3", "Sol3", "Mi3", "Rest", "Mi3", "Mi3", "Rê3",
					"Đô3", "Mi3", "Rê3", "Rê3", "Đô3", "La2", "Đô3", "Đô3", "La2", "Đô3",
					"La2", "Sol2", "Sol2", "La2", "Mi3", "Sol3", "Sol3", "Mi3", "Sol3", "Sol3", "Mi3", "Rê3", "Đô3", "Đô3",
					"Rê3", "Đô3", "Rê3", "Mi3", "Rê3", "Rê3", "Đô3", "Rê3", "Đô3", "Rê3", "Đô3", "Đô3", "La2", "Đô3", "Rê3", "Rê3", "Rê3"
				],
				"durations": [
					0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5, 2.0,
					0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5,
					0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 1.0, 0.5, 0.5, 2.0,
					0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 3.0,
					1.0, 1.0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5,
					0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 2.0
				]
			}
		]
	},
	{
		"level": 2,
		"title": "NHẠC LÝ CƠ BẢN & PHÁCH NHỊP ĐÀN TRANH",
		"sessions": "Bài 4–6",
		"objective": "Làm quen với trường độ các nốt đen, nốt trắng, nốt móc đơn, nốt móc kép và nhịp phách 4/4.",
		"lessons": [
			{
				"number": 4,
				"title": "Làm quen nốt Đen và nốt Trắng",
				"video": "Nhạc lý về trường độ: Nốt Đen (1 phách) và Nốt Trắng (2 phách). Cách giữ âm vang cho nốt trắng trên Đàn Tranh.",
				"practice": "Thực hành gảy nốt Đen và nốt Trắng trên thang âm cơ bản với nhịp độ chậm đều.",
				"practice_title": "Luyện tập nốt Đen & Trắng",
				"sheet": ["Mi2", "Sol2", "Sol2", "Mi2", "Sol2", "Sol2", "La2", "Đô3", "La2", "Đô3", "La2", "Sol2", "Sol2"],
				"durations": [1.0, 1.0, 2.0, 1.0, 1.0, 2.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0]
			},
			{
				"number": 5,
				"title": "Làm quen nốt Móc Đơn và Móc Kép",
				"video": "Nhạc lý về nốt Móc Đơn (nửa phách) và nốt Móc Kép / Móc Đôi (một phần tư phách). Kỹ thuật gảy ngón tay linh hoạt tốc độ nhanh.",
				"practice": "Chơi các mẫu chạy nốt nhanh dần đều sử dụng kết hợp nốt móc đơn và móc kép.",
				"practice_title": "Luyện tập móc đơn & móc kép",
				"sheet": ["Sol1", "La1", "Đô2", "Rê2", "Mi2", "Sol2", "Mi2", "Rê2", "Đô2", "La1", "Sol1"],
				"durations": [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.25, 0.25, 0.25, 0.25, 1.0]
			},
			{
				"number": 6,
				"title": "Nhịp 4/4 và Khóa Sol",
				"video": "Giới thiệu về Khóa Sol trên khuông nhạc và cách đếm nhịp phách trong nhịp 4/4 tiêu chuẩn.",
				"practice": "Thực hành gảy bài nhạc điệu Nam Bộ Xàng Xê trên khuông nhạc nhịp 4/4 khóa Sol.",
				"practice_title": "Luyện tập nhịp 4/4 khóa Sol",
				"sheet": ["Đô2", "Rê2", "Mi2", "Sol2", "La2", "Sol2", "Mi2", "Rê2", "Đô2"],
				"durations": [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0]
			}
		]
	},
	{
		"level": 3,
		"title": "LUYỆN NGÓN VÀ DÂN CA CỔ TRUYỀN",
		"sessions": "Bài 7–8",
		"objective": "Luyện ngón tay linh hoạt qua các bài tập dân ca cổ truyền có tốc độ cao.",
		"lessons": [
			{
				"number": 7,
				"title": "Luyện ngón tốc độ cao – Mã Vũ",
				"video": "Kỹ thuật giữ khung bàn tay vững chãi và di chuyển ngón nhanh trên các phím đàn khi chơi điệu hành khúc Mã Vũ.",
				"practice": "Thực hành gảy bài nhạc Mã Vũ đoạn 1 đúng trường độ và nhịp độ nhanh.",
				"practice_title": "Luyện ngón: Mã Vũ",
				"sheet": ["Đô2", "Rê2", "Mi2", "Rê2", "Đô2", "La2", "Sol2", "Sol2", "Đô2", "Rê2", "Mi2", "Sol2", "Mi2", "Rê2", "Đô2", "Đô2", "La2", "Sol2", "Sol2", "Sol2", "Đô2", "Rê2", "Đô2", "Sol2"],
				"durations": [0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 1.0]
			},
			{
				"number": 8,
				"title": "Dân ca Quan họ – Lý Cây Đa",
				"video": "Kỹ thuật luyến láy và giữ nhịp lả lướt đặc trưng của dân ca Quan họ Bắc Ninh.",
				"practice": "Thực hành chơi bài dân ca Lý Cây Đa đạt độ chính xác cao.",
				"practice_title": "Lý Cây Đa",
				"sheet": ["Sol2", "Sol2", "La2", "Đô3", "Rê3", "Mi3", "Rê3", "Đô3", "La2", "Sol2", "La2", "Đô3", "Sol2"],
				"durations": [1.0, 1.0, 0.5, 0.5, 1.0, 1.0, 0.5, 0.5, 1.0, 1.0, 0.5, 0.5, 2.0]
			}
		]
	},
	{
		"level": 4,
		"title": "KỸ THUẬT TAY TRÁI & HỢP ÂM",
		"sessions": "Bài 9–10",
		"objective": "Làm chủ kỹ thuật nhấn rung tay trái và gảy song âm, hợp âm trên Đàn Tranh.",
		"lessons": [
			{
				"number": 9,
				"title": "Kỹ thuật nhấn Rung tay trái",
				"video": "Cách nhấn rung tay trái bên trái nhạn đàn để tạo âm ngân luyến truyền cảm, linh hồn Đàn Tranh.",
				"practice": "Thực hành gảy các nốt ngân dài kết hợp nhấn rung đều tay trái.",
				"practice_title": "Rung dây Đàn Tranh",
				"sheet": ["Đô2", "Đô2", "Rê2", "Rê2", "Mi2", "Mi2", "Sol2", "Sol2"],
				"durations": [2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0]
			},
			{
				"number": 10,
				"title": "Học Song âm & Hợp âm Đô Trưởng",
				"video": "Kỹ thuật gảy đồng thời hai hoặc ba dây đàn cùng lúc để tạo thành hợp âm Đô trưởng (C) vang rền.",
				"practice": "Thực hành gảy song âm và hợp âm Đô trưởng đúng kỹ thuật tay phải.",
				"practice_title": "Hợp âm Đô trưởng",
				"sheet": ["Đô2+Mi2", "Mi2+Sol2", "Đô2+Mi2+Sol2", "Đô2+Mi2+Sol2"],
				"durations": [2.0, 2.0, 4.0, 4.0]
			}
		]
	},
	{
		"level": 5,
		"title": "THỬ THÁCH TỔNG HỢP & BIỂU DIỄN",
		"sessions": "Bài 11–12",
		"objective": "Tập luyện và độc tấu trọn vẹn tác phẩm Sứ Thanh Hoa từ đầu đến cuối.",
		"lessons": [
			{
				"number": 11,
				"title": "Học Sứ Thanh Hoa – Đoạn dạo đầu",
				"video": "Hướng dẫn chi tiết cách chạy nốt, chuyển quãng rộng và kiểm soát nhịp điệu của đoạn nhạc mở đầu bài Sứ Thanh Hoa.",
				"practice": "Chơi đúng câu dạo đầu tiên của bài Sứ Thanh Hoa.",
				"practice_title": "Sứ Thanh Hoa – Đoạn mở đầu",
				"sheet": ["Rê3", "Đô3", "La2", "Đô3", "Đô3", "La2", "Đô3", "Đô3", "La2", "Đô3", "La2", "Sol2"],
				"durations": [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5, 2.0]
			},
			{
				"number": 12,
				"title": "Độc tấu trọn vẹn Sứ Thanh Hoa",
				"video": "Hướng dẫn phối hợp toàn bộ kỹ thuật tay phải (gảy ngón) và tay trái (rung nhấn) để chơi trọn vẹn tác phẩm Sứ Thanh Hoa.",
				"practice": "Thử thách độc tấu toàn bộ tác phẩm Sứ Thanh Hoa từ đầu đến cuối đạt điểm số tối đa.",
				"practice_title": "Biểu diễn trọn vẹn Sứ Thanh Hoa",
				"sheet": [
					"Rê3", "Đô3", "La2", "Đô3", "Đô3", "La2", "Đô3", "Đô3", "La2", "Đô3", "La2", "Sol2",
					"Rê3", "Đô3", "La2", "Đô3", "Đô3", "La2", "Đô3", "Đô3", "Mi3", "Rê3", "Đô3", "Sol2", "La2", "Mi3",
					"Mi3", "Rê3", "Mi3", "Rê3", "Mi3", "Sol3", "Mi3", "Rest", "Mi3", "Mi3", "Rê3",
					"Đô3", "Mi3", "Rê3", "Rê3", "Đô3", "La2", "Đô3", "Đô3", "La2", "Đô3",
					"La2", "Sol2", "Sol2", "La2", "Mi3", "Sol3", "Sol3", "Mi3", "Sol3", "Sol3", "Mi3", "Rê3", "Đô3", "Đô3",
					"Rê3", "Đô3", "Rê3", "Mi3", "Rê3", "Rê3", "Đô3", "Rê3", "Đô3", "Rê3", "Đô3", "Đô3", "La2", "Đô3", "Rê3", "Rê3", "Rê3"
				],
				"durations": [
					0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5, 2.0,
					0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5,
					0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 1.0, 0.5, 0.5, 2.0,
					0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 3.0,
					1.0, 1.0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5,
					0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 2.0
				]
			}
		]
	}
]

@onready var bg: TextureRect = $BG
@onready var sidebar: PanelContainer = $Root/Sidebar
@onready var btn_menu      : Button         = $Root/Sidebar/SideM/SideV/BtnMenu
@onready var btn_courses   : Button         = $Root/Sidebar/SideM/SideV/BtnCourses
@onready var btn_room      : Button         = $Root/Sidebar/SideM/SideV/BtnRoom
@onready var btn_songs     : Button         = $Root/Sidebar/SideM/SideV/BtnSongs
var btn_account   : Button
var btn_minigame : Button
var btn_leaderboard : Button

@onready var top_bar: PanelContainer = $Root/RightContent/TopBar
@onready var back_btn: Button = $Root/RightContent/TopBar/TopM/TopH/BackBtn
@onready var page_title: Label = $Root/RightContent/TopBar/TopM/TopH/TitleVBox/PageTitle
@onready var objective_label: Label = $Root/RightContent/TopBar/TopM/TopH/TitleVBox/Objective
var change_course_btn: Button
@onready var scroll_container: ScrollContainer = $Root/RightContent/ScrollContainer
@onready var lessons_hbox: HBoxContainer = $Root/RightContent/ScrollContainer/ContentMargin/LessonsHBox

func _ready() -> void:
	btn_account = get_node_or_null("Root/Sidebar/SideM/SideV/BtnAccount")
	change_course_btn = get_node_or_null("Root/RightContent/TopBar/TopM/TopH/ChangeCourseBtn")
	selected_level = clampi(selected_level, 1, LEVELS.size())
	InstrumentSelect.selected_instrument = "dan_tranh"
	SecureDataManager.data["selected_instrument"] = "dan_tranh"
	
	var side_v := $Root/Sidebar/SideM/SideV as VBoxContainer
	btn_minigame = Button.new()
	btn_minigame.name = "BtnMiniGame"
	btn_minigame.text = "Mini-game"
	btn_minigame.flat = true
	btn_minigame.custom_minimum_size = Vector2(220, 100)
	side_v.add_child(btn_minigame)
	side_v.move_child(btn_minigame, 5) # after BtnSongs (index 4)
	
	btn_leaderboard = Button.new()
	btn_leaderboard.name = "BtnLeaderboard"
	btn_leaderboard.text = "Xếp hạng"
	btn_leaderboard.flat = true
	btn_leaderboard.custom_minimum_size = Vector2(220, 100)
	side_v.add_child(btn_leaderboard)
	side_v.move_child(btn_leaderboard, 6)
	
	_build_theme()
	_build_sidebar()
	_build_lessons()
	_build_quiz_btn()
	lessons_hbox.draw.connect(_draw_lesson_path)
	lessons_hbox.sort_children.connect(func() -> void: lessons_hbox.queue_redraw())
	_connect_navigation()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	lessons_hbox.mouse_filter = Control.MOUSE_FILTER_PASS
	var content_margin := lessons_hbox.get_parent() as Control
	if content_margin: content_margin.mouse_filter = Control.MOUSE_FILTER_PASS
	create_tween().tween_property(self, "modulate:a", 1.0, 0.28)

static func get_level_data(level_number: int) -> Dictionary:
	var index := clampi(level_number, 1, LEVELS.size()) - 1
	return LEVELS[index]

func _build_theme() -> void:
	bg.texture = load("res://assets/textures/dan_tranh_background.png")
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
	page_title.add_theme_color_override("font_color", C_JADE)
	objective_label.add_theme_color_override("font_color", C_MUTED)
	var heading_font := load("res://assets/fonts/Lora-Bold.ttf") as Font
	if heading_font:
		page_title.add_theme_font_override("font", heading_font)
	
	back_btn.text = ""
	back_btn.icon = load("res://assets/textures/lucide/arrow-left.svg") as Texture2D
	back_btn.expand_icon = true
	back_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	back_btn.custom_minimum_size = Vector2(48, 48)
	back_btn.add_theme_color_override("icon_normal_color", C_JADE)
	back_btn.add_theme_color_override("icon_hover_color", C_GOLD)
	back_btn.add_theme_color_override("icon_pressed_color", C_JADE)
	_style_text_btn(back_btn, C_JADE, C_GOLD)
	_make_bouncy(back_btn)
	
	if change_course_btn:
		_style_outline_button(change_course_btn)

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
			_make_bouncy(b)

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
	if _sidebar_icon_cache.has(t):
		texture = _sidebar_icon_cache[t]
	elif tex_name != "":
		texture = load("res://assets/textures/lucide/" + tex_name + ".svg") as Texture2D
		_sidebar_icon_cache[t] = texture
	
	if texture:
		var icon_sz := Vector2(36, 36)
		if t == 0:
			icon_sz = Vector2(28, 28)
		var rect := Rect2(Vector2(cx - icon_sz.x/2, cy - icon_sz.y/2), icon_sz)
		c.draw_texture_rect(texture, rect, false, col)

func _build_lessons() -> void:
	for child in lessons_hbox.get_children():
		child.queue_free()
	var level_data := get_level_data(selected_level)
	page_title.text = "GIÁO TRÌNH ĐÀN TRANH · LEVEL %d" % selected_level
	objective_label.text = "%s · %s · %s" % [level_data["title"], level_data["sessions"], level_data["objective"]]
	var completed: Array = SecureDataManager.data.completed_lessons.get("dan_tranh", [])
	var lessons: Array = level_data["lessons"]
	for index in range(lessons.size()):
		var lesson_value = lessons[index]
		var lesson: Dictionary = lesson_value
		lessons_hbox.add_child(_create_lesson_path(lesson, index, lessons, completed))

func _create_lesson_path(lesson: Dictionary, index: int, lessons: Array, completed: Array) -> VBoxContainer:
	var lesson_number := int(lesson["number"])
	var practice_id := _lesson_id(lesson_number, "practice")
	var lesson_ready: bool = not REQUIRE_SEQUENTIAL_UNLOCK or index == 0
	if REQUIRE_SEQUENTIAL_UNLOCK and index > 0:
		var previous: Dictionary = lessons[index - 1]
		lesson_ready = completed.has(_lesson_id(int(previous["number"]), "practice"))
	var practice_completed := completed.has(practice_id)
	var practice_unlocked: bool = not REQUIRE_SEQUENTIAL_UNLOCK or practice_completed or lesson_ready

	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2.ZERO
	column.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 24)

	var title := Label.new()
	title.text = "BÀI %d" % lesson_number
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", C_TEXT if lesson_ready else Color(C_MUTED, 0.45))
	var bold_font := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if bold_font:
		title.add_theme_font_override("font", bold_font)
	column.add_child(title)

	var lesson_button := _create_circle_button("Vào bài", str(lesson["title"]), practice_unlocked, practice_completed)
	lesson_button.name = "LessonBtn"
	lesson_button.pressed.connect(_open_lesson.bind(lesson))
	column.add_child(lesson_button)
	return column

func _create_circle_button(action: String, lesson_title: String, unlocked: bool, completed: bool) -> Button:
	var button := Button.new()
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.custom_minimum_size = Vector2(250, 250)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if unlocked else Control.CURSOR_ARROW
	button.disabled = not unlocked

	if completed:
		button.text = "✓\n%s\nHoàn thành" % action
	elif unlocked:
		var icon := "🎬" if action == "Hướng dẫn" else "🎵"
		button.text = "%s\n%s\n(%s)" % [icon, action, lesson_title]
	else:
		button.text = "🔒"

	var bg_color := Color(0.95, 0.93, 0.89, 0.6)
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
	s_normal.corner_radius_top_left = 125; s_normal.corner_radius_top_right = 125
	s_normal.corner_radius_bottom_left = 125; s_normal.corner_radius_bottom_right = 125
	
	if unlocked and not completed:
		s_normal.shadow_size = 24
		s_normal.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35)
		
	var s_hover := s_normal.duplicate() as StyleBoxFlat
	if unlocked:
		if completed:
			s_hover.bg_color = bg_color.lightened(0.1)
		else:
			s_hover.bg_color = Color(0.97, 0.97, 0.97, 1.0)

	button.add_theme_stylebox_override("normal", s_normal)
	button.add_theme_stylebox_override("hover", s_hover)
	button.add_theme_stylebox_override("pressed", s_normal)
	button.add_theme_stylebox_override("disabled", s_normal)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", C_JADE if (unlocked and not completed) else text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_disabled_color", text_color)
	var bold_font := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if bold_font:
		button.add_theme_font_override("font", bold_font)
	button.add_theme_font_size_override("font_size", 21)
	_make_bouncy(button)
	return button

func _on_btn_leaderboard_pressed() -> void:
	_fade_to("res://scenes/LeaderboardScreen.tscn")

func _draw_lesson_path() -> void:
	if lessons_hbox.size.x <= 0.0:
		return
	var centers: Array[Vector2] = []
	var node_unlocked: Array[bool] = []
	
	for child in lessons_hbox.get_children():
		var col := child as VBoxContainer
		if not col: continue
		var l_btn := col.get_node_or_null("LessonBtn") as Button
		if l_btn:
			var l_center: Vector2 = col.position + l_btn.position + l_btn.size / 2.0
			centers.append(l_center)
			node_unlocked.append(not l_btn.disabled)
			
	if centers.is_empty():
		return
		
	# Ensure all circles lie on the exact same horizontal straight line (Y coordinate)
	var line_y := centers[0].y
	for idx in range(centers.size() - 1):
		var p1 := Vector2(centers[idx].x, line_y)
		var p2 := Vector2(centers[idx + 1].x, line_y)
		var active := node_unlocked[idx + 1]
		var line_color := C_JADE if active else Color(0.13, 0.08, 0.05, 0.08)
		var line_thickness := 14.0 if active else 7.0
		lessons_hbox.draw_line(p1, p2, line_color, line_thickness, true)

func _create_lesson_card(lesson: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(430, 560)
	var card_style := _flat(C_CARD, Color(C_GOLD, 0.36), 26, 2)
	card_style.shadow_size = 18
	card_style.shadow_color = Color(0.13, 0.08, 0.05, 0.12)
	card_style.shadow_offset = Vector2(0, 7)
	card.add_theme_stylebox_override("panel", card_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_bottom", 26)
	card.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	margin.add_child(content)

	var badge := Label.new()
	badge.text = "BÀI %d" % lesson["number"]
	badge.add_theme_color_override("font_color", C_GOLD)
	badge.add_theme_font_size_override("font_size", 17)
	content.add_child(badge)

	var title := Label.new()
	title.text = lesson["title"]
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_color_override("font_color", C_JADE)
	title.add_theme_font_size_override("font_size", 25)
	var heading_font := load("res://assets/fonts/Lora-Bold.ttf") as Font
	if heading_font:
		title.add_theme_font_override("font", heading_font)
	content.add_child(title)

	var divider := HSeparator.new()
	divider.add_theme_constant_override("separation", 2)
	content.add_child(divider)

	if str(lesson["video"]) != "":
		content.add_child(_create_description("VIDEO HƯỚNG DẪN", str(lesson["video"]), "🎬"))
	content.add_child(_create_description("THỰC HÀNH TRÊN ĐÀN ẢO", str(lesson["practice"]), "🎵"))

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	content.add_child(actions)
	var practice_btn := _create_action_button("Bắt đầu bài học", true)
	practice_btn.pressed.connect(_open_lesson.bind(lesson))
	actions.add_child(practice_btn)
	return card

func _create_description(label_text: String, description: String, icon: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _flat(Color(C_JADE, 0.045), Color(C_JADE, 0.10), 16, 1))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 13)
	margin.add_theme_constant_override("margin_bottom", 13)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)
	var heading := Label.new()
	heading.text = "%s  %s" % [icon, label_text]
	heading.add_theme_color_override("font_color", C_GOLD)
	heading.add_theme_font_size_override("font_size", 13)
	box.add_child(heading)
	var body := Label.new()
	body.text = description
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_color_override("font_color", C_TEXT)
	body.add_theme_font_size_override("font_size", 16)
	box.add_child(body)
	return panel

func _create_action_button(text_value: String, primary: bool) -> Button:
	var button := Button.new()
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 54)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 15)
	if primary:
		button.add_theme_stylebox_override("normal", _flat(C_JADE, C_GOLD, 18, 2))
		button.add_theme_stylebox_override("hover", _flat(C_JADE_LIGHT, C_GOLD_LIGHT, 18, 2))
		button.add_theme_color_override("font_color", Color.WHITE)
	else:
		button.add_theme_stylebox_override("normal", _flat(Color.TRANSPARENT, C_JADE, 18, 2))
		button.add_theme_stylebox_override("hover", _flat(Color(C_JADE, 0.08), C_GOLD, 18, 2))
		button.add_theme_color_override("font_color", C_JADE)
	button.add_theme_stylebox_override("pressed", _flat(Color(C_GOLD, 0.18), C_GOLD, 18, 2))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_make_bouncy(button)
	return button

func _connect_navigation() -> void:
	back_btn.pressed.connect(_go_to_levels)
	if change_course_btn:
		change_course_btn.pressed.connect(_go_to_levels)
	btn_menu.pressed.connect(func() -> void: _fade_to("res://scenes/MainMenu.tscn"))
	btn_courses.pressed.connect(_go_to_levels)
	btn_room.pressed.connect(func() -> void: _fade_to("res://scenes/VirtualMusicRoom.tscn"))
	btn_songs.pressed.connect(func() -> void: _fade_to("res://scenes/SongScreen.tscn"))
	btn_minigame.pressed.connect(func() -> void: _fade_to("res://scenes/MiniGame.tscn"))
	btn_leaderboard.pressed.connect(_on_btn_leaderboard_pressed)
	if btn_account:
		btn_account.pressed.connect(func() -> void: _fade_to("res://scenes/AccountScreen.tscn"))

func _go_to_levels() -> void:
	_fade_to("res://scenes/MainMenu.tscn")

func _open_lesson(lesson: Dictionary) -> void:
	var lesson_number := int(lesson["number"])
	
	# Load current lesson data so LessonDanTranh can read it
	PracticeRoom.current_song_title = str(lesson["title"])
	var typed_sheet: Array[String] = []
	typed_sheet.assign(lesson.get("sheet", []))
	PracticeRoom.current_song_sheet = typed_sheet
	
	var typed_durations: Array[float] = []
	typed_durations.assign(lesson.get("durations", []))
	LessonDanTranh.current_song_durations = typed_durations
	
	var typed_cues: Array[String] = []
	typed_cues.assign(lesson.get("cues", []))
	LessonDanTranh.current_song_cues = typed_cues
	
	if selected_level == 1 and lesson_number in [1, 2, 3]:
		SecureDataManager.active_lesson_id = _lesson_id(lesson_number, "video")
		var VP = load("res://scripts/VideoPlayer.gd")
		VP.custom_video_path = "res://Video/DT_LV1_B" + str(lesson_number) + ".ogv"
		VP.custom_subtitles = VP.SUBTITLES_DAN_TRANH
		_fade_to("res://scenes/VideoPlayer.tscn")
	else:
		SecureDataManager.active_lesson_id = _lesson_id(lesson_number, "practice")
		_fade_to("res://scenes/LessonDanTranh.tscn")

func _lesson_id(lesson_number: int, activity: String) -> String:
	return "dan_tranh_level_%d_bai_%d_%s" % [selected_level, lesson_number, activity]

func _build_quiz_btn() -> void:
	var toph := $Root/RightContent/TopBar/TopM/TopH as HBoxContainer
	if toph == null or change_course_btn == null:
		return
	var quiz_btn := Button.new()
	quiz_btn.name = "QuizBtn"
	quiz_btn.text = "📝 Quiz"
	quiz_btn.custom_minimum_size = Vector2(148, 48)
	quiz_btn.add_theme_font_size_override("font_size", 17)
	quiz_btn.add_theme_stylebox_override("normal", _flat(Color.TRANSPARENT, C_JADE, 18, 2))
	quiz_btn.add_theme_stylebox_override("hover", _flat(Color(C_GOLD, 0.12), C_GOLD, 18, 2))
	quiz_btn.add_theme_stylebox_override("pressed", _flat(Color(C_GOLD, 0.15), C_GOLD, 18, 2))
	quiz_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	quiz_btn.add_theme_color_override("font_color", C_JADE)
	quiz_btn.add_theme_color_override("font_hover_color", C_GOLD)
	quiz_btn.pressed.connect(_open_quiz)
	_make_bouncy(quiz_btn)
	toph.add_child(quiz_btn)
	toph.move_child(quiz_btn, change_course_btn.get_index())

func _open_quiz() -> void:
	var ids: Array[String] = []
	var level_data := get_level_data(selected_level)
	for lesson: Dictionary in level_data.get("lessons", []):
		var number := int(lesson.get("number", 0))
		if number > 0:
			ids.append(_lesson_id(number, "practice"))
	QuizScreenScript.quiz_instrument = "dan_tranh"
	QuizScreenScript.quiz_local_ids = ids
	QuizScreenScript.quiz_return_scene = "res://scenes/LessonDanTranhList.tscn"
	_fade_to("res://scenes/QuizScreen.tscn")

func _apply_responsive_layout() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var mobile: bool = viewport_size.x < 850.0 or viewport_size.x < viewport_size.y
	sidebar.visible = not mobile
	var top_margin := $Root/RightContent/TopBar/TopM as MarginContainer
	top_margin.add_theme_constant_override("margin_left", 16 if mobile else 36)
	top_margin.add_theme_constant_override("margin_right", 16 if mobile else 36)
	top_margin.add_theme_constant_override("margin_top", 16 if mobile else 24)
	top_margin.add_theme_constant_override("margin_bottom", 12 if mobile else 16)
	page_title.add_theme_font_size_override("font_size", 19 if mobile else 25)
	objective_label.visible = not mobile
	if change_course_btn:
		change_course_btn.custom_minimum_size.x = 108 if mobile else 164
		change_course_btn.text = "Levels" if mobile else "Đổi khóa học"
	var content_margin := $Root/RightContent/ScrollContainer/ContentMargin as MarginContainer
	content_margin.add_theme_constant_override("margin_left", 18 if mobile else 48)
	var sep := 32 if mobile else 64
	lessons_hbox.add_theme_constant_override("separation", sep)
	for col in lessons_hbox.get_children():
		if col is VBoxContainer:
			col.custom_minimum_size = Vector2.ZERO
			col.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			var btn := col.get_node_or_null("LessonBtn") as Button
			if btn:
				var sz := Vector2(180, 180) if mobile else Vector2(250, 250)
				btn.custom_minimum_size = sz
				btn.add_theme_font_size_override("font_size", 18 if mobile else 21)

func _style_text_btn(btn: Button, normal_color: Color, hover_color: Color) -> void:
	btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_color_override("font_color", normal_color)
	btn.add_theme_color_override("font_hover_color", hover_color)
	btn.add_theme_color_override("font_pressed_color", hover_color.darkened(0.15))

func _style_outline_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _flat(Color.TRANSPARENT, C_JADE, 18, 2))
	button.add_theme_stylebox_override("hover", _flat(Color(C_JADE, 0.08), C_GOLD, 18, 2))
	button.add_theme_stylebox_override("pressed", _flat(Color(C_GOLD, 0.15), C_GOLD, 18, 2))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", C_JADE)
	_make_bouncy(button)

func _flat(background: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.border_width_top = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style

func _make_bouncy(button: Button) -> void:
	button.resized.connect(func() -> void: button.pivot_offset = button.size * 0.5)
	button.mouse_entered.connect(func() -> void: create_tween().tween_property(button, "scale", Vector2(1.025, 1.025), 0.10))
	button.mouse_exited.connect(func() -> void: create_tween().tween_property(button, "scale", Vector2.ONE, 0.10))
	button.button_down.connect(func() -> void: create_tween().tween_property(button, "scale", Vector2(0.97, 0.97), 0.07))
	button.button_up.connect(func() -> void: create_tween().tween_property(button, "scale", Vector2.ONE, 0.10))

func _fade_to(path: String) -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.20)
	tween.tween_callback(func() -> void: get_tree().change_scene_to_file(path))
