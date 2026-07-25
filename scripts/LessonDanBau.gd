extends Control

# ─── Color Palette (Synchronized Jade Green & Gold Lacquer Cream Theme)
const C_BG           := Color(0.98, 0.97, 0.94, 1.0) # Warm cream background
const C_GOLD         := Color(0.77, 0.58, 0.15, 1.0) # Lacquer gold
const C_GOLD_LIGHT   := Color(0.92, 0.76, 0.30, 1.0) # Lighter gold
const C_JADE         := Color(0.09, 0.27, 0.18, 1.0) # Premium deep jade green
const C_JADE_LIGHT   := Color(0.12, 0.37, 0.23, 1.0) # Lake jade green
const C_TEXT         := Color(0.13, 0.08, 0.05, 1.0) # Dark charcoal
const C_TEXT_MUTED   := Color(0.13, 0.08, 0.05, 0.35)
const C_MUTED        := Color("#6f6257")
const C_CARD         := Color("#fffdf8")

<<<<<<< HEAD
# ─── Dan Bau Note Map: pitch (Hz) → Vietnamese note name
# Covers boi am (harmonics) range of Dan Bau: ~130Hz – 1200Hz
const DANBAU_NOTE_MAP: Array[Dictionary] = [
	{"min": 123.0,  "max": 135.0,  "name": "Đố thấp",  "solfege": "Do"},
	{"min": 135.0,  "max": 150.0,  "name": "Rê thấp",  "solfege": "Re"},
	{"min": 150.0,  "max": 168.0,  "name": "Mi thấp",  "solfege": "Mi"},
	{"min": 168.0,  "max": 185.0,  "name": "Fa thấp",  "solfege": "Fa"},
	{"min": 185.0,  "max": 207.0,  "name": "Sol thấp", "solfege": "Sol"},
	{"min": 207.0,  "max": 232.0,  "name": "La thấp",  "solfege": "La"},
	{"min": 232.0,  "max": 260.0,  "name": "Si thấp",  "solfege": "Si"},
	{"min": 260.0,  "max": 295.0,  "name": "Đô",       "solfege": "Do"},
	{"min": 295.0,  "max": 330.0,  "name": "Rê",       "solfege": "Re"},
	{"min": 330.0,  "max": 370.0,  "name": "Mi",       "solfege": "Mi"},
	{"min": 370.0,  "max": 415.0,  "name": "Fa",       "solfege": "Fa"},
	{"min": 415.0,  "max": 465.0,  "name": "Sol",      "solfege": "Sol"},
	{"min": 465.0,  "max": 520.0,  "name": "La",       "solfege": "La"},
	{"min": 520.0,  "max": 585.0,  "name": "Si",       "solfege": "Si"},
	{"min": 585.0,  "max": 655.0,  "name": "Đố",       "solfege": "Do"},
	{"min": 655.0,  "max": 740.0,  "name": "Rế",       "solfege": "Re"},
	{"min": 740.0,  "max": 830.0,  "name": "Mí",       "solfege": "Mi"},
	{"min": 830.0,  "max": 930.0,  "name": "Fá",       "solfege": "Fa"},
	{"min": 930.0,  "max": 1050.0, "name": "Sól",      "solfege": "Sol"},
	{"min": 1050.0, "max": 1200.0, "name": "Lá",       "solfege": "La"},
]

# ─── Drag Tracking Variables
var _is_dragging_scroll: bool = false
var _drag_start_pos: Vector2 = Vector2.ZERO
var _scroll_start_x: float = 0.0
var _has_dragged_significantly: bool = false
var _drag_velocity: float = 0.0
var _last_drag_pos_x: float = 0.0
var _last_drag_time: float = 0.0
=======
var is_unlocked: bool = true
>>>>>>> 5ea47272736d1865d1f7c912053cc34462e3caaf

# ─── Audio Recognition State
var _audio_panel_visible := false
var _mic_active := false
var _audio_analyzer: AudioCaptureAnalyzer = null
var _current_detected_note := ""
var _audio_panel: PanelContainer = null
var _note_display_label: Label = null
var _status_label: Label = null
var _waveform_control: Control = null
var _mic_btn: Button = null
var _hold_timer := 0.0
const NOTE_HOLD_REQUIRED := 0.4 # seconds a note must be held to confirm

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

<<<<<<< HEAD
# ─── Dynamic Lesson Data (5 Lessons Course)
const LESSONS = [
	{
		"id": "dan_bau_coban_1",
		"title": "BÀI 1",
		"note": "Khám phá\nĐộc Huyền Cầm",
		"short_note": "Khám phá",
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
		"note": "Kỹ thuật\ntạo Bồi Âm",
		"short_note": "Bồi âm",
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
		"short_note": "Rê & Mi",
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
		"note": "Uốn vòi cần",
		"short_note": "Uốn vòi",
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
		"short_note": "Bèo Dạt",
		"video": "Xem video hướng dẫn chơi bài mẫu",
		"practice": "Luyện chơi bài Bèo Dạt Mây Trôi",
		"subtitles": [
			{"start": 0.0, "end": 3.0, "text": "Chào mừng con đến với Bài 5: Luyện tập bài Bèo Dạt Mây Trôi."},
			{"start": 3.0, "end": 6.5, "text": "Kết hợp kỹ thuật gảy hài âm nốt Đô, Rê, Mi và uốn cần nhịp nhàng."},
			{"start": 6.5, "end": 10.0, "text": "Hãy cố gắng liên kết các âm vang mềm mại và đúng nhịp điệu bài học nhé."}
=======
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
>>>>>>> 92a30cf66a46caceb8970d060858dafbfbaa7dd8
		]
	}
]

func get_current_lessons() -> Array:
	var level_idx := clampi(selected_level, 1, LEVELS.size()) - 1
	return LEVELS[level_idx]["lessons"]

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
	_build_audio_panel()

	lessons_hbox.draw.connect(_draw_connecting_lines)
	lessons_hbox.sort_children.connect(func():
		lessons_hbox.queue_redraw()
	)

	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()
<<<<<<< HEAD

=======
	lessons_hbox.mouse_filter = Control.MOUSE_FILTER_PASS
	var content_margin := lessons_hbox.get_parent() as Control
	if content_margin: content_margin.mouse_filter = Control.MOUSE_FILTER_PASS
	
>>>>>>> 5ea47272736d1865d1f7c912053cc34462e3caaf
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)

func _process(delta: float) -> void:
	if _mic_active and _audio_analyzer and _waveform_control:
		_update_audio_display(delta)

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
	top_s.bg_color = Color(0.93, 0.91, 0.87, 0.6)
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
<<<<<<< HEAD

	page_title.text = "GIÁO TRÌNH ĐÀN BẦU CƠ BẢN"
=======
	
	var level_idx := clampi(selected_level, 1, LEVELS.size()) - 1
	var level_info: Dictionary = LEVELS[level_idx]
	page_title.text = "GIÁO TRÌNH ĐÀN BẦU · LEVEL %d: %s" % [selected_level, level_info["title"]]
>>>>>>> 92a30cf66a46caceb8970d060858dafbfbaa7dd8
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

	# Mic Button (added to TopBar before ChangeCourseBtn)
	var top_h := $Root/RightContent/TopBar/TopM/TopH as HBoxContainer
	_mic_btn = Button.new()
	_mic_btn.name = "MicBtn"
	_mic_btn.text = ""
	_mic_btn.custom_minimum_size = Vector2(48, 48)
	_mic_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_mic_btn.flat = true
	var mic_icon_path := "res://assets/textures/lucide/mic.svg"
	if ResourceLoader.exists(mic_icon_path):
		_mic_btn.icon = load(mic_icon_path) as Texture2D
	_mic_btn.expand_icon = true
	_mic_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mic_btn.add_theme_color_override("icon_normal_color", C_JADE)
	_mic_btn.add_theme_color_override("icon_hover_color", C_GOLD)
	_mic_btn.tooltip_text = "Nhận diện âm thanh Đàn Bầu"
	_style_text_btn(_mic_btn, C_JADE, C_GOLD)
	_make_btn_bouncy(_mic_btn)
	# Insert before ChangeCourseBtn (last child)
	top_h.add_child(_mic_btn)
	top_h.move_child(_mic_btn, top_h.get_child_count() - 2)
	_mic_btn.pressed.connect(_on_mic_toggled)

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

# ─── Audio Recognition Panel ────────────────────────────────────────────────

func _build_audio_panel() -> void:
	# Floating panel anchored bottom-right of screen
	_audio_panel = PanelContainer.new()
	_audio_panel.name = "AudioRecognitionPanel"
	_audio_panel.custom_minimum_size = Vector2(300, 220)
	_audio_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	_audio_panel.layout_mode = 1
	_audio_panel.anchor_left = 1.0
	_audio_panel.anchor_right = 1.0
	_audio_panel.anchor_top = 1.0
	_audio_panel.anchor_bottom = 1.0
	_audio_panel.offset_left = -324
	_audio_panel.offset_right = -16
	_audio_panel.offset_top = -240
	_audio_panel.offset_bottom = -16
	_audio_panel.visible = false
	_audio_panel.z_index = 10

	# Glass panel style
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.96, 0.95, 0.91, 0.96)
	panel_style.border_color = C_JADE
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 20
	panel_style.corner_radius_top_right = 20
	panel_style.corner_radius_bottom_left = 20
	panel_style.corner_radius_bottom_right = 20
	panel_style.shadow_size = 16
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.18)
	_audio_panel.add_theme_stylebox_override("panel", panel_style)

	# Inner margin container
	var panel_margin := MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 16)
	panel_margin.add_theme_constant_override("margin_right", 16)
	panel_margin.add_theme_constant_override("margin_top", 14)
	panel_margin.add_theme_constant_override("margin_bottom", 14)
	_audio_panel.add_child(panel_margin)

	var panel_vbox := VBoxContainer.new()
	panel_vbox.add_theme_constant_override("separation", 10)
	panel_margin.add_child(panel_vbox)

	# Header row: icon + title
	var header_hbox := HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 8)
	panel_vbox.add_child(header_hbox)

	var mic_icon_lbl := Label.new()
	mic_icon_lbl.text = "🎵"
	mic_icon_lbl.add_theme_font_size_override("font_size", 20)
	header_hbox.add_child(mic_icon_lbl)

	var panel_title := Label.new()
	panel_title.text = "NHẬN DIỆN ÂM THANH ĐÀN BẦU"
	panel_title.add_theme_color_override("font_color", C_JADE)
	panel_title.add_theme_font_size_override("font_size", 13)
	panel_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var f_bold := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if f_bold:
		panel_title.add_theme_font_override("font", f_bold)
	header_hbox.add_child(panel_title)

	# Waveform oscilloscope area
	_waveform_control = Control.new()
	_waveform_control.name = "WaveformDisplay"
	_waveform_control.custom_minimum_size = Vector2(0, 56)
	_waveform_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_waveform_control.draw.connect(_draw_waveform)

	# Waveform background
	var wave_bg := StyleBoxFlat.new()
	wave_bg.bg_color = Color(0.08, 0.14, 0.10, 0.90)
	wave_bg.corner_radius_top_left = 10
	wave_bg.corner_radius_top_right = 10
	wave_bg.corner_radius_bottom_left = 10
	wave_bg.corner_radius_bottom_right = 10
	var wave_panel := PanelContainer.new()
	wave_panel.add_theme_stylebox_override("panel", wave_bg)
	wave_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wave_panel.custom_minimum_size = Vector2(0, 56)
	wave_panel.add_child(_waveform_control)
	_waveform_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_vbox.add_child(wave_panel)

	# Note display row
	var note_row := HBoxContainer.new()
	note_row.alignment = BoxContainer.ALIGNMENT_CENTER
	note_row.add_theme_constant_override("separation", 16)
	panel_vbox.add_child(note_row)

	var note_icon := Label.new()
	note_icon.text = "🎼"
	note_icon.add_theme_font_size_override("font_size", 24)
	note_row.add_child(note_icon)

	_note_display_label = Label.new()
	_note_display_label.text = "—"
	_note_display_label.add_theme_color_override("font_color", C_JADE)
	_note_display_label.add_theme_font_size_override("font_size", 32)
	_note_display_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if f_bold:
		_note_display_label.add_theme_font_override("font", f_bold)
	note_row.add_child(_note_display_label)

	# Status label
	_status_label = Label.new()
	_status_label.text = "Đang lắng nghe..."
	_status_label.add_theme_color_override("font_color", C_MUTED)
	_status_label.add_theme_font_size_override("font_size", 13)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel_vbox.add_child(_status_label)

	add_child(_audio_panel)

func _on_mic_toggled() -> void:
	_audio_panel_visible = not _audio_panel_visible

	if _audio_panel_visible:
		# Create AudioCaptureAnalyzer if not yet created
		if not _audio_analyzer:
			_audio_analyzer = AudioCaptureAnalyzer.new()
			add_child(_audio_analyzer)

		_mic_active = true
		_audio_panel.visible = true
		_audio_panel.modulate.a = 0.0
		create_tween().tween_property(_audio_panel, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		# Animate panel sliding up from bottom
		_audio_panel.offset_top = -200
		var slide_tw := create_tween()
		slide_tw.tween_property(_audio_panel, "offset_top", -240, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		slide_tw.parallel().tween_property(_audio_panel, "offset_bottom", -16, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		# Update mic button to active state (gold)
		_mic_btn.add_theme_color_override("icon_normal_color", C_GOLD)
		_status_label.text = "🎤 Đang lắng nghe..."
		_status_label.add_theme_color_override("font_color", C_JADE)
	else:
		_mic_active = false
		var t := create_tween()
		t.tween_property(_audio_panel, "modulate:a", 0.0, 0.2)
		t.tween_callback(func(): _audio_panel.visible = false)

		# Restore mic button normal color
		_mic_btn.add_theme_color_override("icon_normal_color", C_JADE)

		# Clean up analyzer
		if _audio_analyzer:
			_audio_analyzer.queue_free()
			_audio_analyzer = null

func _update_audio_display(delta: float) -> void:
	if not _audio_analyzer or not _note_display_label:
		return

	var pitch := _audio_analyzer.current_pitch
	var amplitude := _audio_analyzer.current_amplitude_db
	var is_playing := amplitude > _audio_analyzer.volume_threshold_db

	# Queue waveform redraw
	if _waveform_control:
		_waveform_control.queue_redraw()

	if is_playing and pitch > 80.0:
		var note_info := _pitch_to_dan_bau_note(pitch)
		var note_name := note_info.get("name", "?") as String

		if note_name != _current_detected_note:
			_current_detected_note = note_name
			_hold_timer = 0.0

		_hold_timer += delta

		# Update display immediately with current note
		_note_display_label.text = note_name
		_note_display_label.add_theme_color_override("font_color", C_JADE)

		# Show solfege info
		var solfege := note_info.get("solfege", "") as String
		var freq_str := "%.0f Hz" % pitch
		_status_label.text = "🎵 %s  ·  %s" % [solfege, freq_str]
		_status_label.add_theme_color_override("font_color", C_JADE_LIGHT)

		# Pulse animation on note change
		if _hold_timer < delta * 2.0:
			var pulse := create_tween()
			pulse.tween_property(_note_display_label, "scale", Vector2(1.15, 1.15), 0.08)
			pulse.tween_property(_note_display_label, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_note_display_label.pivot_offset = _note_display_label.size / 2.0
	else:
		_current_detected_note = ""
		_hold_timer = 0.0
		_note_display_label.text = "—"
		_note_display_label.add_theme_color_override("font_color", C_MUTED)
		_status_label.text = "🎤 Đang lắng nghe..."
		_status_label.add_theme_color_override("font_color", C_MUTED)

func _pitch_to_dan_bau_note(hz: float) -> Dictionary:
	# Find matching note from the Dan Bau harmonic map
	for entry in DANBAU_NOTE_MAP:
		if hz >= entry["min"] and hz < entry["max"]:
			return entry
	# Fallback: outside mapped range
	if hz < 123.0:
		return {"name": "Thấp", "solfege": "—"}
	return {"name": "Cao", "solfege": "—"}

func _draw_waveform() -> void:
	if not _waveform_control or not _audio_analyzer:
		return
	var w := _waveform_control.size.x
	var h := _waveform_control.size.y
	if w <= 0 or h <= 0:
		return

	var history := _audio_analyzer._sample_history
	if history.size() < 2:
		return

	var is_active := _audio_analyzer.current_amplitude_db > _audio_analyzer.volume_threshold_db
	var line_color := C_JADE_LIGHT if is_active else Color(C_JADE_LIGHT, 0.35)
	var glow_color := Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.22) if is_active else Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.08)

	var points := PackedVector2Array()
	var size_h := history.size()
	for i in range(size_h):
		var x := w * (float(i) / float(size_h - 1))
		var amp := h * 0.38 if is_active else h * 0.04
		var y := h * 0.5 + history[i] * amp
		points.append(Vector2(x, y))

	if points.size() > 1:
		_waveform_control.draw_polyline(points, glow_color, 6.0, true)
		_waveform_control.draw_polyline(points, line_color, 1.8, true)

	# Center baseline
	_waveform_control.draw_line(
		Vector2(0, h * 0.5), Vector2(w, h * 0.5),
		Color(1.0, 1.0, 1.0, 0.08), 1.0
	)

# ─── Sidebar ─────────────────────────────────────────────────────────────────

func _build_sidebar() -> void:
	var side_s := StyleBoxFlat.new()
	side_s.bg_color = Color(0.93, 0.91, 0.87, 0.6)
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

# ─── Lesson List ─────────────────────────────────────────────────────────────

func _build_lesson_list() -> void:
	lessons_hbox.add_theme_constant_override("separation", 100)
	# Clear existing children
	for child in lessons_hbox.get_children():
		child.queue_free()

	var inst := "dan_bau"
	var completed_lessons : Array = SecureDataManager.data.get("completed_lessons", {}).get(inst, [])
<<<<<<< HEAD
	var unlocked_lessons : Array = SecureDataManager.data.get("unlocked_lessons", {}).get(inst, ["dan_bau_coban_1_video"])

	var f_bold := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font

	for i in range(LESSONS.size()):
		var lesson_item : Dictionary = LESSONS[i]
		var id := lesson_item["id"] as String

		# Define task status keys
		var v_id := id + "_video"
		var p_id := id + "_practice"

=======
	var unlocked_lessons : Array = SecureDataManager.data.get("unlocked_lessons", {}).get(inst, ["dan_bau_level1_bai1_video"])
	
	var f_bold := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	var lessons_data := get_current_lessons()
	
	for i in range(lessons_data.size()):
		var lesson_item : Dictionary = lessons_data[i]
		var id := lesson_item["id"] as String
		var type := lesson_item["type"] as String
		
>>>>>>> 92a30cf66a46caceb8970d060858dafbfbaa7dd8
		# Unlocking checks
		var is_unlocked := false
		if i == 0:
			is_unlocked = true
		else:
<<<<<<< HEAD
			var prev_id := LESSONS[i - 1]["id"] as String
			is_v_unlocked = unlocked_lessons.has(v_id) or completed_lessons.has(prev_id + "_practice")

		var is_p_unlocked := is_v_unlocked and (completed_lessons.has(v_id) or unlocked_lessons.has(p_id))

		var is_v_completed := completed_lessons.has(v_id)
		var is_p_completed := completed_lessons.has(p_id)

=======
			var prev_id := lessons_data[i - 1]["id"] as String
			is_unlocked = unlocked_lessons.has(id) or completed_lessons.has(prev_id)
			
		var is_completed := completed_lessons.has(id)
		
>>>>>>> 92a30cf66a46caceb8970d060858dafbfbaa7dd8
		# Column layout for each lesson
		var col := VBoxContainer.new()
		col.custom_minimum_size = Vector2.ZERO
		col.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		col.alignment = BoxContainer.ALIGNMENT_CENTER
<<<<<<< HEAD
		col.add_theme_constant_override("separation", 20)

		# Top: Lesson Title Label
		var title_lbl := Label.new()
		title_lbl.text = lesson_item["title"]
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_lbl.add_theme_color_override("font_color", C_TEXT if is_v_unlocked else C_TEXT_MUTED)
		title_lbl.add_theme_font_size_override("font_size", 18)
		if f_bold:
			title_lbl.add_theme_font_override("font", f_bold)
		col.add_child(title_lbl)

		# Short note subtitle label (separate from button — no overflow)
		var sub_lbl := Label.new()
		sub_lbl.text = lesson_item.get("short_note", "") as String
		sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub_lbl.add_theme_color_override("font_color", C_TEXT_MUTED if not is_v_unlocked else Color(C_TEXT, 0.65))
		sub_lbl.add_theme_font_size_override("font_size", 13)
		sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sub_lbl.custom_minimum_size = Vector2(180, 0)
		col.add_child(sub_lbl)

		# Center: Row of circles connected horizontally
=======
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
>>>>>>> 92a30cf66a46caceb8970d060858dafbfbaa7dd8
		var row := HBoxContainer.new()
		row.name = "Row"
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_child(row)
<<<<<<< HEAD

		# 1. Hướng Dẫn Button (Left circle)
		var v_btn := Button.new()
		v_btn.name = "VideoBtn"
		v_btn.custom_minimum_size = Vector2(165, 165)
		v_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER

		_setup_circle_btn(v_btn, "Hướng dẫn", is_v_unlocked, is_v_completed, "video")
		row.add_child(v_btn)

		v_btn.pressed.connect(_on_video_pressed.bind(v_id, lesson_item["subtitles"], is_v_unlocked))

		# 2. Thực Hành Button (Right circle)
		var p_btn := Button.new()
		p_btn.name = "PracticeBtn"
		p_btn.custom_minimum_size = Vector2(165, 165)
		p_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		p_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER

		_setup_circle_btn(p_btn, "Thực hành", is_p_unlocked, is_p_completed, "practice")
		row.add_child(p_btn)

		p_btn.pressed.connect(_on_practice_pressed.bind(p_id, is_p_unlocked))

=======
		
		var btn := Button.new()
		btn.name = "LessonBtn"
		btn.custom_minimum_size = Vector2(180, 180)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		_setup_circle_btn(btn, lesson_item["title"], lesson_item["note"], is_unlocked, is_completed, type)
		row.add_child(btn)
		
		if type == "video":
			btn.pressed.connect(_on_video_pressed.bind(id, lesson_item.get("subtitles", []), is_unlocked))
		else:
			btn.pressed.connect(_on_practice_pressed.bind(id, is_unlocked))
			
>>>>>>> 92a30cf66a46caceb8970d060858dafbfbaa7dd8
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

# ─── Circle Button Setup (Fixed: no lesson title in button text) ──────────────

func _setup_circle_btn(btn: Button, action: String, unlocked: bool, completed: bool, type: String) -> void:
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if unlocked else Control.CURSOR_ARROW
	btn.disabled = not unlocked

	# Short, clean text — no long lesson title inside circle
	if completed:
<<<<<<< HEAD
		btn.text = "\n\n%s\n✓ Xong" % action
	elif unlocked:
		btn.text = "\n\n%s" % action
=======
		btn.text = "\n\n%s\nHoàn thành" % lesson_title
	elif unlocked:
		btn.text = "\n\n%s" % lesson_title
>>>>>>> 92a30cf66a46caceb8970d060858dafbfbaa7dd8
	else:
		btn.text = ""

	var bg_color := Color(0.95, 0.93, 0.89, 0.35) # Locked glassmorphism
	var border_color := Color(0.85, 0.82, 0.78, 0.5)
	var text_color := Color(C_MUTED, 0.8)

	if completed:
		bg_color = C_JADE
		border_color = C_GOLD
		text_color = Color.WHITE
	elif unlocked:
		bg_color = C_CARD
		border_color = C_JADE
		text_color = C_TEXT

	var s_normal := StyleBoxFlat.new()
	s_normal.bg_color = bg_color
	s_normal.border_color = border_color
	s_normal.border_width_left = 5; s_normal.border_width_right = 5
	s_normal.border_width_top = 5; s_normal.border_width_bottom = 5
	s_normal.corner_radius_top_left = 90; s_normal.corner_radius_top_right = 90
	s_normal.corner_radius_bottom_left = 90; s_normal.corner_radius_bottom_right = 90
	# Inner padding so text never touches border
	s_normal.content_margin_left = 12
	s_normal.content_margin_right = 12
	s_normal.content_margin_top = 0
	s_normal.content_margin_bottom = 10

	if unlocked and not completed:
		s_normal.shadow_size = 20
		s_normal.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.30)

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
	btn.add_theme_color_override("font_color", text_color)

	var hover_color = text_color
	if unlocked and not completed: hover_color = C_JADE
	btn.add_theme_color_override("font_hover_color", hover_color)
	btn.add_theme_color_override("font_pressed_color", text_color)
	btn.add_theme_color_override("font_disabled_color", text_color)

	var f_bold := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if f_bold:
		btn.add_theme_font_override("font", f_bold)
	# Font size: smaller so text fits in circle with padding
	btn.add_theme_font_size_override("font_size", 15)

	btn.draw.connect(func():
		var tex_name = ""
		if not unlocked: tex_name = "lock"
		elif completed: tex_name = "check-circle"
		else: tex_name = "play-circle" if type == "video" else "music"

		var tex = load("res://assets/textures/lucide/" + tex_name + ".svg") as Texture2D
		if tex:
			var w = 30.0
			var rect = Rect2((btn.size.x - w) / 2.0, 28.0, w, w)

			var draw_color = text_color
			if unlocked and not completed and btn.is_hovered():
				draw_color = C_JADE

			btn.draw_texture_rect(tex, rect, false, draw_color)
	)
	_make_btn_bouncy(btn)

# ─── Connecting Lines ─────────────────────────────────────────────────────────

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
<<<<<<< HEAD

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
=======
		
		var btn := row.get_node_or_null("LessonBtn") as Button
		if not btn: continue
		
		# Compute center in HBox local coordinates
		var center := col.position + row.position + btn.position + btn.size / 2.0
		centers.append(center)
		
		var lesson_id := lessons_data[i]["id"] as String
		var is_unlocked := false
>>>>>>> 92a30cf66a46caceb8970d060858dafbfbaa7dd8
		if i == 0:
			is_unlocked = true
		else:
<<<<<<< HEAD
			var prev_id := LESSONS[i - 1]["id"] as String
			is_v_unlocked = unlocked_lessons.has(lesson_id + "_video") or completed_lessons.has(prev_id + "_practice")

		var is_p_unlocked := is_v_unlocked and (completed_lessons.has(lesson_id + "_video") or unlocked_lessons.has(p_id))

		node_unlocked.append(is_v_unlocked)
		node_unlocked.append(is_p_unlocked)
=======
			var prev_id := lessons_data[i - 1]["id"] as String
			is_unlocked = unlocked_lessons.has(lesson_id) or completed_lessons.has(prev_id)
			
		node_unlocked.append(is_unlocked)
>>>>>>> 92a30cf66a46caceb8970d060858dafbfbaa7dd8

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

# ─── Responsive Layout ────────────────────────────────────────────────────────

func _apply_responsive_layout() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var mobile: bool = viewport_size.x < 850.0 or viewport_size.x < viewport_size.y
	sidebar.visible = not mobile

	var top_margin := $Root/RightContent/TopBar/TopM as MarginContainer
	top_margin.add_theme_constant_override("margin_left",   16 if mobile else 36)
	top_margin.add_theme_constant_override("margin_right",  16 if mobile else 36)
	top_margin.add_theme_constant_override("margin_top",    16 if mobile else 24)
	top_margin.add_theme_constant_override("margin_bottom", 12 if mobile else 16)

	page_title.add_theme_font_size_override("font_size", 17 if mobile else 26)
	change_course_btn.custom_minimum_size.x = 100 if mobile else 170

	# Lesson card sizing — larger on mobile for touch targets
	var circle_sz := Vector2(155, 155) if mobile else Vector2(170, 170)
	var circle_sep := 60 if mobile else 100
	var hbox_sep := 60 if mobile else 120

	lessons_hbox.add_theme_constant_override("separation", hbox_sep)

	for col in lessons_hbox.get_children():
		if col is VBoxContainer:
			col.custom_minimum_size = Vector2.ZERO
			col.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			var row := col.get_node_or_null("Row") as HBoxContainer
			if row:
				row.add_theme_constant_override("separation", circle_sep)
				for btn in row.get_children():
					if btn is Button:
						btn.custom_minimum_size = circle_sz
						btn.add_theme_font_size_override("font_size", 14 if mobile else 15)

	# Resize audio panel for mobile
	if _audio_panel:
		if mobile:
			_audio_panel.custom_minimum_size = Vector2(viewport_size.x - 32, 200)
			_audio_panel.offset_left = -(viewport_size.x - 16)
			_audio_panel.offset_right = -16
			_audio_panel.offset_top = -216
			_audio_panel.offset_bottom = -16
		else:
			_audio_panel.custom_minimum_size = Vector2(300, 220)
			_audio_panel.offset_left = -324
			_audio_panel.offset_right = -16
			_audio_panel.offset_top = -240
			_audio_panel.offset_bottom = -16

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
