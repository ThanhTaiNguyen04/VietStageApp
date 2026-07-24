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

static var selected_level: int = 1
const REQUIRE_SEQUENTIAL_UNLOCK := false # Tạm mở toàn bộ bài; đổi thành true để khôi phục lộ trình tuần tự.
var _sidebar_icon_cache: Dictionary = {}

const LEVELS := [
	{
		"level": 1,
		"title": "NHẬP MÔN & LÀM QUEN GIAO DIỆN",
		"sessions": "Session 1–3",
		"objective": "Hiểu về nhạc cụ, biết đọc giao diện nốt rơi và gảy những nốt cơ bản.",
		"lessons": [
			{
				"number": 1,
				"title": "Giới thiệu Đàn Tranh & App",
				"video": "Lịch sử đàn tranh, 17 dây đàn và thang ngũ cung Sol – La – Đô – Rê – Mi.",
				"practice": "Nghe mẫu và gảy lại lần lượt 5 nốt Sol – La – Đô – Rê – Mi trên đàn thật; hệ thống nhận diện cao độ, báo đúng/sai và tô xanh nốt đúng.",
				"practice_title": "Làm quen 5 nốt cơ bản",
				"sheet": ["Sol1", "La1", "Đô2", "Rê2", "Mi2"]
			},
			{
				"number": 2,
				"title": "Gảy ngón cơ bản (Ngón 1 & 2)",
				"video": "Kỹ thuật gảy ngón cái, ngón trỏ, ngón giữa và góc tiếp xúc của móng gảy.",
				"practice": "Ba lượt Hứng nốt với Đô2 – Rê2 – Mi2, ký hiệu Ngón 1/Ngón 2 và tốc độ tăng dần; đạt 80% để qua bài.",
				"practice_title": "Gảy ngón cơ bản",
				"sheet": ["Đô2", "Rê2", "Mi2", "Rê2", "Đô2", "Mi2"]
			},
			{
				"number": 3,
				"title": "Đệm theo câu – Sứ Thanh Hoa",
				"video": "Nghe từng câu nhạc, quan sát nốt kết câu và phối hợp ba ngón gảy.",
				"practice": "Cô đàn sáu câu của Sứ Thanh Hoa ở BPM 80; học viên gảy nốt cuối mỗi câu bằng ngón 1, 2, 3 luân phiên.",
				"practice_title": "Đệm Sứ Thanh Hoa",
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
		"title": "KHÚC DẠO ĐẦU – BÀI HỌC VỠ LÒNG",
		"sessions": "Session 4–9",
		"objective": "Chơi hoàn chỉnh bài nhạc đầu tiên với nhịp độ chậm.",
		"lessons": [
			{
				"number": 4,
				"title": "Tập đoạn 1 – Vào rừng hoa",
				"video": "Chia đoạn, nhịp điệu và độ ngân của bài Vào rừng hoa.",
				"practice": "Luyện đúng đoạn đầu Mi – Sol – Sol | Mi – Sol – Sol | La – Đố – La – Đố | La – Sol – Sol theo nhịp 2/4; đúng hoặc sai đều chuyển tiếp, sai lần thứ sáu sẽ làm lại.",
				"practice_title": "Vào rừng hoa – Đoạn 1",
				"sheet": [
					"Mi2", "Sol2", "Sol2", "Mi2", "Sol2", "Sol2",
					"La2", "Đô3", "La2", "Đô3", "La2", "Sol2", "Sol2"
				]
			},
			{
				"number": 5,
				"title": "Ghép hoàn chỉnh Vào rừng hoa",
				"video": "Điều tiết lực tay để giai điệu tự nhiên và giàu cảm xúc.",
				"practice": "Chơi ở BPM 70 và nhận đánh giá Perfect, Great hoặc Miss.",
				"practice_title": "Vào rừng hoa",
				"sheet": ["Sol1", "La1", "Đô2", "Rê2", "Mi2", "Sol2", "Mi2", "Rê2", "Đô2", "La1", "Sol1"]
			},
			{
				"number": 6,
				"title": "Khám phá Xàng Xê",
				"video": "Âm sắc Nam Bộ và cách gảy các nốt luyến đặc trưng của điệu Xàng Xê.",
				"practice": "Tập Xàng Xê với tên nốt hiển thị trực tiếp trên dây đàn.",
				"practice_title": "Xàng Xê",
				"sheet": ["Đô2", "Rê2", "Mi2", "Sol2", "La2", "Sol2", "Mi2", "Rê2", "Đô2"]
			}
		]
	},
	{
		"level": 3,
		"title": "THỬ THÁCH NHỊP ĐIỆU & TỐC ĐỘ",
		"sessions": "Session 10–17",
		"objective": "Chơi các bài có BPM cao hơn và mật độ nốt dày hơn.",
		"lessons": [
			{
				"number": 7,
				"title": "Luyện ngón tốc độ cao – Mã Vũ",
				"video": "Luyện scale, giữ khung tay và di chuyển ổn định giữa các quãng xa.",
				"practice": "Tập Mã Vũ đoạn 1 với tốc độ luyện tập phù hợp.",
				"practice_title": "Mã Vũ – Đoạn 1",
				"sheet": ["Đô2", "Rê2", "Mi2", "Rê2", "Đô2", "La2", "Sol2", "Sol2", "Đô2", "Rê2", "Mi2", "Sol3", "Mi2", "Rê2", "Đô2", "Đô2", "La2", "Sol2", "Sol2", "Sol2", "Đô2", "Rê2", "Đô2", "Sol2"],
				"durations": [0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 1.0]
			},
			{
				"number": 8,
				"title": "Dân ca Quan họ – Lý Cây Đa",
				"video": "Nhấn nhá và luyến láy đặc trưng của Quan họ Bắc Ninh.",
				"practice": "Luyện sheet Lý Cây Đa và hướng tới độ chính xác cao.",
				"practice_title": "Lý Cây Đa",
				"sheet": ["Sol2", "Sol2", "La2", "Đô3", "Rê3", "Mi3", "Rê3", "Đô3", "La2", "Sol2", "La2", "Đô3", "Sol2"]
			}
		]
	},
	{
		"level": 4,
		"title": "KỸ THUẬT NÂNG CAO & ĐÁNH THEO BEAT",
		"sessions": "Session 18–27",
		"objective": "Đánh đàn kết hợp với nhạc nền và làm chủ kỹ thuật tay trái.",
		"lessons": [
			{
				"number": 9,
				"title": "Mô phỏng kỹ thuật Rung",
				"video": "Cách nhấn dây, kiểm soát độ sâu và tạo độ rung bằng tay trái.",
				"practice": "Giữ các nốt dài để luyện cảm giác rung và độ ngân.",
				"practice_title": "Kỹ thuật Rung tay trái",
				"sheet": ["Đô2", "Đô2", "Rê2", "Rê2", "Mi2", "Mi2", "Sol2", "Sol2"]
			},
			{
				"number": 10,
				"title": "Hòa tấu nhạc cụ",
				"video": "Nghe nhạc nền, giữ nhịp và làm nổi bật giai điệu chính khi hòa tấu.",
				"practice": "Đóng vai trò đàn tranh lead trong một bài dân ca có sẵn.",
				"practice_title": "Lý Cây Bông",
				"sheet": ["Mi2", "Sol2", "La2", "Sol2", "Mi2", "Rê2", "Đô2", "Rê2", "Mi2", "Sol2", "La2", "Sol2"]
			}
		]
	},
	{
		"level": 5,
		"title": "MASTER – NHẠC HIỆN ĐẠI",
		"sessions": "Session 28–30",
		"objective": "Ứng dụng kỹ năng Đàn Tranh vào nhạc hiện đại và thử thách tổng hợp.",
		"lessons": [
			{
				"number": 11,
				"title": "Nhạc hiện đại – Sứ Thanh Hoa",
				"video": "Chuyển quãng, nhấn nhả nốt và giữ âm hưởng dân tộc trong bản nhạc hiện đại.",
				"practice": "Luyện sheet Sứ Thanh Hoa ở BPM 80 với các quãng rộng.",
				"practice_title": "Sứ Thanh Hoa",
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
			},
			{
				"number": 12,
				"title": "Boss Stage – Thử thách sinh tồn",
				"video": "",
				"practice": "Chọn một bài đã học và biểu diễn bằng giao diện luyện tập hiện có.",
				"practice_title": "Thử thách sinh tồn 17 dây",
				"sheet": ["Sol1", "La1", "Đô2", "Rê2", "Mi2", "Sol2", "La2", "Đô3", "Rê3", "Mi3", "Sol3", "La3", "Đô4", "Rê4", "Mi4", "Sol4", "La4"]
			}
		]
	},
	{
		"level": 6,
		"title": "HỢP ÂM CƠ BẢN",
		"sessions": "Bài 1-5",
		"objective": "Làm quen với khái niệm hợp âm, thực hành gảy song âm, hợp âm Đô trưởng, La thứ và chuyển hợp âm.",
		"lessons": [
			{
				"number": 13,
				"title": "Bài 1: Hợp âm là gì?",
				"video": "res://Video/DanBauDoan12Bai1.ogv",
				"practice": "Phân biệt nốt đơn và hợp âm. Ôn lại các nốt cơ bản và gảy thử hợp âm Đô trưởng.",
				"practice_title": "Luyện tập: Hợp âm là gì",
				"sheet": ["Sol1", "La1", "Đô2", "Rê2", "Mi2", "Mi2", "Đô2", "La1", "Sol1", "Rê2", "Đô2+Mi2+Sol2"],
				"cues": ["circle", "circle", "circle", "circle", "circle", "triangle", "triangle", "triangle", "triangle", "triangle", "circle"]
			},
			{
				"number": 14,
				"title": "Bài 2: Song âm (2 dây)",
				"video": "res://Video/DanBauDoan12Bai1.ogv",
				"practice": "Làm quen với việc gảy 2 dây cùng lúc (song âm).",
				"practice_title": "Luyện tập: Song âm",
				"sheet": [
					"Đô2+Mi2", "Đô2+Mi2", "Đô2+Mi2",
					"Mi2+Sol2", "Mi2+Sol2", "Mi2+Sol2",
					"La1+Đô2", "La1+Đô2", "La1+Đô2",
					"Đô2+Mi2", "Mi2+Sol2", "La1+Đô2"
				],
				"cues": ["circle", "circle", "circle", "triangle", "triangle", "triangle", "circle", "circle", "circle", "circle", "triangle", "circle"]
			},
			{
				"number": 15,
				"title": "Bài 3: Hợp âm Đô trưởng (C)",
				"video": "res://Video/DanBauDoan12Bai1.ogv",
				"practice": "Hợp âm 3 nốt: Đô, Mi và Sol.",
				"practice_title": "Luyện tập: Đô trưởng",
				"sheet": [
					"Đô2+Mi2+Sol2", "Đô2+Mi2+Sol2", "Đô2+Mi2+Sol2", 
					"Đô2+Mi2+Sol2", "Đô2+Mi2+Sol2",
					"Đô2+Mi2+Sol2", "Đô2+Mi2+Sol2", "Đô2+Mi2+Sol2", "Đô2+Mi2+Sol2"
				],
				"cues": ["circle", "circle", "circle", "circle", "circle", "triangle", "triangle", "triangle", "triangle"]
			},
			{
				"number": 16,
				"title": "Bài 4: Hợp âm La thứ (Am)",
				"video": "res://Video/DanBauDoan12Bai1.ogv",
				"practice": "Hợp âm 3 nốt: La, Đô và Mi.",
				"practice_title": "Luyện tập: La thứ",
				"sheet": [
					"La1+Đô2+Mi2", "La1+Đô2+Mi2", "La1+Đô2+Mi2",
					"Đô2+Mi2+Sol2", "La1+Đô2+Mi2", "Đô2+Mi2+Sol2", "La1+Đô2+Mi2",
					"La1+Đô2+Mi2", "La1+Đô2+Mi2", "La1+Đô2+Mi2", "La1+Đô2+Mi2"
				],
				"cues": ["circle", "circle", "circle", "triangle", "circle", "triangle", "circle", "circle", "circle", "circle", "circle"]
			},
			{
				"number": 17,
				"title": "Bài 5: Chuyển hợp âm",
				"video": "res://Video/DanBauDoan12Bai1.ogv",
				"practice": "Chuyển mượt mà giữa Đô trưởng (C) và La thứ (Am).",
				"practice_title": "Luyện tập: Chuyển hợp âm",
				"sheet": [
					"Đô2+Mi2+Sol2", "La1+Đô2+Mi2", "Đô2+Mi2+Sol2", "La1+Đô2+Mi2",
					"Đô2+Mi2+Sol2", "La1+Đô2+Mi2", "Đô2+Mi2+Sol2", "La1+Đô2+Mi2",
					"Đô2+Mi2+Sol2", "La1+Đô2+Mi2", "La1+Đô2+Mi2", "Đô2+Mi2+Sol2", "Đô2+Mi2+Sol2", "La1+Đô2+Mi2"
				],
				"cues": ["circle", "circle", "circle", "circle", "triangle", "triangle", "triangle", "triangle", "circle", "circle", "triangle", "triangle", "circle", "triangle"]
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
@onready var btn_account   : Button         = $Root/Sidebar/SideM/SideV/BtnAccount
var btn_minigame : Button

@onready var top_bar: PanelContainer = $Root/RightContent/TopBar
@onready var back_btn: Button = $Root/RightContent/TopBar/TopM/TopH/BackBtn
@onready var page_title: Label = $Root/RightContent/TopBar/TopM/TopH/TitleVBox/PageTitle
@onready var objective_label: Label = $Root/RightContent/TopBar/TopM/TopH/TitleVBox/Objective
@onready var change_course_btn: Button = $Root/RightContent/TopBar/TopM/TopH/ChangeCourseBtn
@onready var scroll_container: ScrollContainer = $Root/RightContent/ScrollContainer
@onready var lessons_hbox: HBoxContainer = $Root/RightContent/ScrollContainer/ContentMargin/LessonsHBox

func _ready() -> void:
	selected_level = clampi(selected_level, 1, LEVELS.size())
	InstrumentSelect.selected_instrument = "dan_tranh"
	SecureDataManager.data["selected_instrument"] = "dan_tranh"
	
	var side_v := $Root/Sidebar/SideM/SideV as VBoxContainer
	btn_minigame = Button.new()
	btn_minigame.name = "BtnMiniGame"
	btn_minigame.text = "Mini-game"
	btn_minigame.flat = true
	btn_minigame.custom_minimum_size = Vector2(220, 140)
	side_v.add_child(btn_minigame)
	side_v.move_child(btn_minigame, 5) # after BtnSongs (index 4)
	
	_build_theme()
	_build_sidebar()
	_build_lessons()
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
		_make_bouncy(b)

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
	change_course_btn.pressed.connect(_go_to_levels)
	btn_menu.pressed.connect(func() -> void: _fade_to("res://scenes/MainMenu.tscn"))
	btn_courses.pressed.connect(_go_to_levels)
	btn_room.pressed.connect(func() -> void: _fade_to("res://scenes/VirtualMusicRoom.tscn"))
	btn_songs.pressed.connect(func() -> void: _fade_to("res://scenes/SongScreen.tscn"))
	btn_minigame.pressed.connect(func() -> void: _fade_to("res://scenes/MiniGame.tscn"))
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
