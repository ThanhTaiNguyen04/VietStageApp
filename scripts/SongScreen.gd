extends Control

# ─── Vietnamese Traditional Color Palette ──────────────────────────────────────
const C_GOLD       := Color(0.77, 0.58, 0.15, 1.0)
const C_GOLD_LIGHT := Color(0.95, 0.82, 0.45, 1.0)
const C_GOLD_DARK  := Color(0.06, 0.02, 0.00, 1.0)
const C_RED_SON    := Color(0.09, 0.27, 0.18, 1.0)
const C_RED_DK     := Color(0.05, 0.16, 0.11, 0.96)
const C_BG_DARK    := Color(0.98, 0.97, 0.94, 1.0)
const C_BG_BAR     := Color(0.95, 0.93, 0.89, 1.0)
const C_TEXT       := Color(0.13, 0.08, 0.05, 1.0)
const C_TEXT_MUTED := Color(0.43, 0.38, 0.33, 1.0)
const C_CARD       := Color(1.00, 1.00, 1.00, 0.95)
const C_JADE       := Color(0.12, 0.37, 0.23, 1.0)
const C_JADE_LIGHT := Color(0.25, 0.65, 0.45, 1.0)

# ─── Static Song Database ─────────────────────────────────────────────────────
const SONGS_DATA := [
	{
		"id": "song_001",
		"title": "Bèo Dạt Mây Trôi",
		"desc": "Dân ca quan họ Bắc Ninh - Giai điệu mượt mà, đậm đà quê hương đất nước.",
		"instrument": "dan_tranh",
		"instrument_label": "Đàn Tranh",
		"difficulty": "Dễ",
		"difficulty_color": Color(0.12, 0.37, 0.23, 1.0), # Jade green
		"genre": "dan_ca",
		"genre_label": "Dân ca",
		"xp": 100,
		"sheet": ["Đô","Đô","Rê","Fa","Fa","Sol","La","Sol","Fa","Rê","Đô"]
	},
	{
		"id": "song_002",
		"title": "Dạ Cổ Hoài Lang",
		"desc": "Bản nhạc cổ hoài niệm Nam Bộ của nhạc sĩ Cao Văn Lầu, giai điệu da diết.",
		"instrument": "dan_tranh",
		"instrument_label": "Đàn Tranh",
		"difficulty": "Khó",
		"difficulty_color": Color(0.09, 0.27, 0.18, 1.0), # Jade green
		"genre": "co_truyen",
		"genre_label": "Cổ truyền",
		"xp": 250,
		"sheet": ["Đô2","Đô2","Rê2","Đô2","Fa","Sol","La","Rê","Fa","Đô2","Đô"]
	},
	{
		"id": "song_003",
		"title": "Lý Mỹ Hưng",
		"desc": "Điệu lý vui tươi, rộn ràng, phổ biến trong Nhạc tài tử Nam Bộ.",
		"instrument": "dan_tranh",
		"instrument_label": "Đàn Tranh",
		"difficulty": "Trung bình",
		"difficulty_color": Color(0.77, 0.58, 0.15, 1.0), # Gold
		"genre": "co_truyen",
		"genre_label": "Cổ truyền",
		"xp": 180,
		"sheet": ["Fa","Rê","Đô","Rê","Fa","Sol","Đô2","La","Sol","Fa","Đô"]
	},
	{
		"id": "song_004",
		"title": "Đất Phương Nam",
		"desc": "Bài hát hào hùng mang âm hưởng dân gian miền Nam Bộ sông nước.",
		"instrument": "dan_tranh",
		"instrument_label": "Đàn Tranh",
		"difficulty": "Trung bình",
		"difficulty_color": Color(0.77, 0.58, 0.15, 1.0), # Gold
		"genre": "tru_tinh",
		"genre_label": "Trữ tình",
		"xp": 200,
		"sheet": ["Đô","Fa","Sol","Đô2","La","Đô2","Sol","Fa","Rê","Đô","Đô"]
	},
	{
		"id": "song_004b",
		"title": "Giấc Mơ Trưa",
		"desc": "Tác phẩm trứ danh của nhạc sĩ Giáng Son - Giai điệu mộng mơ, thanh tao đặc trưng của Đàn Tranh.",
		"instrument": "dan_tranh",
		"instrument_label": "Đàn Tranh",
		"difficulty": "Khó",
		"difficulty_color": Color(0.09, 0.27, 0.18, 1.0), # Jade green
		"genre": "tru_tinh",
		"genre_label": "Trữ tình",
		"xp": 300,
		"sheet": ["Rest", "Sol", "La", "Đô2", "Rê2", "Mi2", "Sol2", "La2", "Rê3", "Rê3", "Rest", "La2", "Sol2", "Mi2", "Rê2", "Đô2", "La", "Sol", "Đô2", "Đô2", "Rest", "Đô2", "Rê2", "Mi2", "Sol2", "La2", "Sol2", "Mi2", "Rê2", "Rê2", "Rest", "Đô2", "Rê2", "Mi2", "Sol2", "La2", "Đô3", "La2", "Sol2", "Sol2", "Rest", "La2", "Sol2", "Mi2", "Rê2", "Mi2", "Rê2", "Đô2", "Đô2", "Rest", "Mi2", "Rê2", "Đô2", "Rê2", "Sol2", "Rê2", "Sol2", "Đô3", "Đô3", "Đô3", "Rest", "Mi2", "Rê2", "Sol2", "Rê2", "Rê2", "Rê2", "Rest", "Mi2", "Rê2", "Đô2", "Rê2", "Sol2", "La2", "La2", "La2", "Rest", "Sol2", "La2", "Mi2", "Rê2", "Đô2", "Rê2", "Sol2", "Sol2", "Rest", "Rê3", "Đô3", "La2", "Đô3", "Sol2", "Sol2", "Rest", "La2", "Sol2", "Mi2", "Sol2", "Rê2", "Rê2", "Rest", "Mi2", "Rê2", "Đô2", "Rê2", "Sol", "Sol", "Rest", "Đô2", "Rê2", "Mi2", "Sol2", "La2", "Sol2", "La2", "La2", "Rest", "Sol2", "La2", "Mi2", "Rê2", "Đô2", "Rê2", "Đô2", "Đô2", "Rest", "Đô2", "Rê2", "Mi2", "Sol2", "La2", "Sol2", "La2", "Đô3", "La2", "Sol2", "Mi2", "Sol2", "La2", "La2", "Rest", "Đô2", "Rê2", "Mi2", "Sol2", "La2", "Sol2", "La2", "Đô3", "Rê3", "Đô3", "La2", "Đô3", "Sol2", "Sol2", "Rest", "La2", "Sol2", "Mi2", "Sol2", "Rê2", "Mi2", "Đô2", "Đô2", "Rest", "La", "Sol", "Đô2", "Rê2", "Mi2", "Sol2", "La2", "Sol2", "Mi2", "Rê2", "Đô2", "Đô2", "Rest", "Đô2", "Rê2", "Mi2", "Sol2", "La2", "Sol2", "La2", "Đô3", "La2", "Sol2", "Mi2", "Sol2", "La2", "La2", "Rest", "Đô2", "Rê2", "Mi2", "Sol2", "La2", "Sol2", "La2", "Đô3", "Rê3", "Đô3", "La2", "Đô3", "Sol2", "Sol2", "Rest", "La2", "Sol2", "Mi2", "Sol2", "Rê2", "Mi2", "Đô2", "Đô2", "Rest", "La", "Sol", "Đô2", "Rê2", "Mi2", "Sol2", "La2", "Sol2", "Mi2", "Rê2", "Đô2", "Đô2", "Rest"]
	},
	{
		"id": "song_012",
		"title": "Inh Lả Ơi",
		"desc": "Dân ca Thái, chuyển soạn cho sáo trúc theo nhịp Jiangnan, tempo 110 BPM.",
		"instrument": "sao_truc",
		"instrument_label": "Sáo Trúc",
		"difficulty": "Dễ",
		"difficulty_color": Color(0.12, 0.37, 0.23, 1.0), # Jade green
		"genre": "dan_ca",
		"genre_label": "Dân ca",
		"xp": 130,
		"bpm": 110.0,
		"sheet": [
			"Đô2", "La", "Si", "Đô2", "Rest", "Đô2", "Sol", "La", "Rest", "Đô2", "Sol",
			"Fa", "Đô2", "Si", "La", "Sol", "Rest", "Fa", "La", "Đô2", "Sol",
			"Sol", "Sol", "Fa", "Fa", "Rest", "Đô2", "Sol", "La", "Rest", "Đô2", "Sol", "Đô2", "Rest"
		],
		"durations": [
			1.0, 0.5, 0.5, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
			1.0, 1.0, 0.5, 0.5, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
			1.0, 0.5, 0.5, 1.0, 1.0, 1.0, 0.5, 0.5, 1.0, 1.0, 1.0, 1.0, 1.0
		]
	},
	{
		"id": "song_005",
		"title": "Lý Hoài Nam",
		"desc": "Làn điệu dân ca miền Trung, đặc biệt du dương khi thổi sáo trúc.",
		"instrument": "sao_truc",
		"instrument_label": "Sáo Trúc",
		"difficulty": "Dễ",
		"difficulty_color": Color(0.12, 0.37, 0.23, 1.0), # Jade green
		"genre": "dan_ca",
		"genre_label": "Dân ca",
		"xp": 100,
		"sheet": ["Đô","Đô","Rê","Mi","Mi","Fa","Sol","Fa","Mi","Rê","Đô"]
	},
	{
		"id": "song_006",
		"title": "Lòng Mẹ",
		"desc": "Tác phẩm bất hủ của nhạc sĩ Y Vân tràn đầy tình yêu thương gia đình.",
		"instrument": "sao_truc",
		"instrument_label": "Sáo Trúc",
		"difficulty": "Trung bình",
		"difficulty_color": Color(0.77, 0.58, 0.15, 1.0), # Gold
		"genre": "tru_tinh",
		"genre_label": "Trữ tình",
		"xp": 150,
		"sheet": ["Đô","Mi","Sol","La","Sol","Mi","Rê","Mi","Rê","Đô","Đô"]
	},
	{
		"id": "song_007",
		"title": "Trống Cơm",
		"desc": "Điệu dân ca Bắc Bộ rộn rã, nhộn nhịp vui nhộn đầy sinh động.",
		"instrument": "sao_truc",
		"instrument_label": "Sáo Trúc",
		"difficulty": "Khó",
		"difficulty_color": Color(0.09, 0.27, 0.18, 1.0), # Jade green
		"genre": "dan_ca",
		"genre_label": "Dân ca",
		"xp": 220,
		"sheet": ["Sol","La","Si","Sol","La","Sol","Fa","Mi","Rê","Mi","Đô"]
	},
	{
		"id": "song_008",
		"title": "Gặp Mẹ Trong Mơ",
		"desc": "Khúc hát tình mẹ dịu êm cảm động, chuyển soạn mộc mạc cho sáo.",
		"instrument": "sao_truc",
		"instrument_label": "Sáo Trúc",
		"difficulty": "Dễ",
		"difficulty_color": Color(0.12, 0.37, 0.23, 1.0), # Jade green
		"genre": "tru_tinh",
		"genre_label": "Trữ tình",
		"xp": 120,
		"sheet": ["Đô","Rê","Mi","Sol","Mi","Rê","Đô","Rê","Mi","Rê","Đô"]
	},
	{
		"id": "song_011",
		"title": "Futari no Kimochi",
		"desc": "Bản nhạc chủ đề đầy cảm xúc trong phim hoạt hình InuYasha dành cho Sáo Trúc.",
		"instrument": "sao_truc",
		"instrument_label": "Sáo Trúc",
		"difficulty": "Trung bình",
		"difficulty_color": Color(0.77, 0.58, 0.15, 1.0), # Gold
		"genre": "tru_tinh",
		"genre_label": "Trữ tình",
		"xp": 200,
		"sheet": [
			"Mi", "Sol", "La", "La", "Đô2", "Rê2", "Mi2", "Sol2", "Mi2", "Rê2", "Đô2", "La", "Mi2", "Rê2", "La", "Mi2", "Rê2", "La", "Sol", "Mi",
			"Mi", "Sol", "La", "La", "Đô2", "Rê2", "Mi2", "Sol2", "Mi2", "Rê2", "Đô2", "La", "Mi2", "Rê2", "La", "Mi2", "Rê2", "La", "Sol", "La",
			"Mi2", "Sol2", "La2", "Sol2", "La2", "Si2", "Sol2", "La2", "Sol2", "Rê2", "Mi2", "Mi2", "Sol2", "La2", "Sol2", "La2", "Đô3", "Si2", "Sol2", "Mi2",
			"Mi2", "Sol2", "La2", "Sol2", "La2", "Si2", "Sol2", "La2", "Sol2", "Rê2", "Mi2", "Mi2", "Rê2", "La", "Mi2", "Rê2", "La", "Sol", "La"
		]
	},
	{
		"id": "song_009",
		"title": "Lý Kéo Chài",
		"desc": "Làn điệu dân ca Nam Bộ mộc mạc rộn rã, phù hợp với tiếng đàn bầu ngân vang.",
		"instrument": "dan_bau",
		"instrument_label": "Đàn Bầu",
		"difficulty": "Dễ",
		"difficulty_color": Color(0.12, 0.37, 0.23, 1.0), # Jade green
		"genre": "dan_ca",
		"genre_label": "Dân ca",
		"xp": 120,
		"sheet": ["Đô","Mi","Fa","La","Si","La","Fa","Mi","Rê","Đô"]
	},
	{
		"id": "song_010",
		"title": "Trống Cơm",
		"desc": "Điệu dân ca dí dỏm, ngắt nhịp vui nhộn, rất độc đáo khi biểu diễn trên đàn bầu.",
		"instrument": "dan_bau",
		"instrument_label": "Đàn Bầu",
		"difficulty": "Trung bình",
		"difficulty_color": Color(0.77, 0.58, 0.15, 1.0), # Gold
		"genre": "dan_ca",
		"genre_label": "Dân ca",
		"xp": 160,
		"sheet": ["Đô","Mi","Fa","La","Si","La","Fa","Mi","Rê","Đô","La"]
	},
	{
		"id": "song_012",
		"title": "Gió Đánh Đò Đưa",
		"desc": "Làn điệu dân ca Quan họ Bắc Ninh vui tươi rộn rã, cực kỳ tình cảm khi ngân vang trên Đàn Bầu.",
		"instrument": "dan_bau",
		"instrument_label": "Đàn Bầu",
		"difficulty": "Trung bình",
		"difficulty_color": Color(0.77, 0.58, 0.15, 1.0), # Gold
		"genre": "dan_ca",
		"genre_label": "Dân ca",
		"xp": 180,
		"sheet": ["Rê", "Rê", "Fa", "Sol", "Mi", "Sol", "Đô", "Đô", "Rê", "Mi", "Rê", "Đô", "Đô", "Rê", "Mi", "Rê", "Rê", "Đô", "La", "Sol", "La", "Đô", "Rê", "Đô", "La", "Sol", "Mi", "Sol", "La", "Sol", "Mi", "Mi", "Mi", "Sol", "La", "Đô", "Rê", "Mi", "Rê", "Đô", "Rê", "Mi", "Rê", "Đô", "La", "Đô", "Rê", "Đô"]
	}
]

# ─── @onready references ─────────────────────────────────────────────────────
@onready var bg_overlay      : ColorRect      = $BGOverlay
@onready var back_btn        : Button         = $Root/TopBar/TopM/TopH/BackBtn
@onready var page_title      : Label          = $Root/TopBar/TopM/TopH/PageTitle
@onready var search_edit     : LineEdit       = $Root/Content/ContentMargin/SplitHBox/ListVBox/SearchFilterHBox/SearchEdit
@onready var btn_all         : Button         = $Root/Content/ContentMargin/SplitHBox/ListVBox/FilterTabs/BtnAll
@onready var btn_danca       : Button         = $Root/Content/ContentMargin/SplitHBox/ListVBox/FilterTabs/BtnDanCa
@onready var btn_trutinh     : Button         = $Root/Content/ContentMargin/SplitHBox/ListVBox/FilterTabs/BtnTruTinh
@onready var btn_cotruyen    : Button         = $Root/Content/ContentMargin/SplitHBox/ListVBox/FilterTabs/BtnCoTruyen
@onready var songs_grid      : GridContainer  = $Root/Content/ContentMargin/SplitHBox/ListVBox/SongsScroll/SongsGrid

@onready var split_hbox      : HBoxContainer  = $Root/Content/ContentMargin/SplitHBox
@onready var detail_panel    : PanelContainer = $Root/Content/ContentMargin/SplitHBox/DetailPanel
@onready var detail_title    : Label          = $Root/Content/ContentMargin/SplitHBox/DetailPanel/DetailM/DetailVBox/DetailHeader/DetailTitle
@onready var detail_tags     : HBoxContainer  = $Root/Content/ContentMargin/SplitHBox/DetailPanel/DetailM/DetailVBox/DetailHeader/DetailTags
@onready var detail_desc     : Label          = $Root/Content/ContentMargin/SplitHBox/DetailPanel/DetailM/DetailVBox/DetailDesc
@onready var notes_hbox      : HBoxContainer  = $Root/Content/ContentMargin/SplitHBox/DetailPanel/DetailM/DetailVBox/NotesScroll/NotesHBox
@onready var btn_start_practice : Button      = $Root/Content/ContentMargin/SplitHBox/DetailPanel/DetailM/DetailVBox/BtnStartPractice

@onready var bottom_bar      : PanelContainer = $Root/BottomBar
@onready var btn_courses_mob : Button         = $Root/BottomBar/BottomM/BottomH/BtnCoursesMobile
@onready var btn_room_mob    : Button         = $Root/BottomBar/BottomM/BottomH/BtnRoomMobile
@onready var btn_songs_mob   : Button         = $Root/BottomBar/BottomM/BottomH/BtnSongsMobile
@onready var btn_account_mob : Button         = $Root/BottomBar/BottomM/BottomH/BtnAccountMobile

# ─── Filtering State ──────────────────────────────────────────────────────────
var current_filter := "all"
var search_text := ""
var _sidebar_icons_cache := {}
var selected_song_data := {}
var selected_card_node : PanelContainer = null

func _ready() -> void:
	SecureDataManager.load_data()
	_build_theme()
	_connect_events()
	_populate_songs()
	_animate_in()

	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()

# ─── Theme & Layout Customization ─────────────────────────────────────────────
func _build_theme() -> void:
	var selected_inst = SecureDataManager.data.get("selected_instrument", "dan_tranh")
	
	var theme_color := C_RED_SON
	var accent_color := C_GOLD
	var bg_overlay_color := Color(0.06, 0.03, 0.012, 0.94) # deep warm mahogany
	var inst_label := "Đàn Tranh"
	var bg_texture_path := "res://assets/textures/bg_main_menu.png"
	
	if selected_inst == "sao_truc":
		bg_overlay_color = Color(0, 0, 0, 0)
		bg_texture_path = "res://assets/textures/sao_truc_background.png"
		inst_label = "Sáo Trúc"
	elif selected_inst == "dan_bau":
		bg_overlay_color = Color(0, 0, 0, 0)
		bg_texture_path = "res://assets/textures/dan_bau_background.png"
		inst_label = "Đàn Bầu"
	elif selected_inst == "trong_chau":
		bg_overlay_color = Color(0, 0, 0, 0)
		bg_texture_path = "res://assets/textures/trong_chau_background.png"
		inst_label = "Trống Chầu"
	elif selected_inst == "dan_tranh":
		bg_texture_path = "res://assets/textures/dan_tranh_background.png"
		bg_overlay_color = Color(0, 0, 0, 0)
		
	# Apply dynamic title
	page_title.text = "Kho Bài Hát - " + inst_label
	
	# Load and set the specific background texture
	var bg = get_node_or_null("BG") as TextureRect
	if bg:
		bg.texture = load(bg_texture_path)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	
	# Apply background overlay color
	if bg_overlay:
		bg_overlay.color = bg_overlay_color
	
	# Top bar style matching global design
	var top_bar = $Root/TopBar
	if not top_bar.has_node("BlurRect"):
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
		var blur := ColorRect.new()
		blur.name = "BlurRect"
		blur.material = top_blur_mat
		blur.mouse_filter = Control.MOUSE_FILTER_IGNORE
		blur.show_behind_parent = true
		blur.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		blur.offset_bottom = -1
		top_bar.add_child(blur)
		
	var top_s := _flat(Color(1.0, 0.99, 0.97, 0.7), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.28), 0)
	top_s.border_width_bottom = 1
	top_s.content_margin_bottom = 0
	top_bar.add_theme_stylebox_override("panel", top_s)
	
	page_title.add_theme_color_override("font_color", theme_color)
	var font_title := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if font_title:
		page_title.add_theme_font_override("font", font_title)

	# Back button style
	back_btn.text = ""
	back_btn.icon = load("res://assets/textures/lucide/arrow-left.svg") as Texture2D
	back_btn.expand_icon = true
	back_btn.custom_minimum_size = Vector2(48, 48)
	back_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	back_btn.add_theme_color_override("icon_normal_color", theme_color)
	back_btn.add_theme_color_override("icon_hover_color", accent_color)
	back_btn.add_theme_color_override("icon_pressed_color", theme_color)
	back_btn.add_theme_stylebox_override("normal",  _flat(Color(0,0,0,0), Color(0,0,0,0), 8))
	back_btn.add_theme_stylebox_override("hover",   _flat(Color(theme_color.r,theme_color.g,theme_color.b,0.12), Color(0,0,0,0), 8))
	back_btn.add_theme_stylebox_override("pressed", _flat(Color(theme_color.r,theme_color.g,theme_color.b,0.20), Color(0,0,0,0), 8))
	back_btn.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0), 0))

	# Search LineEdit style (Match Login email input)
	var se_n := _flat(Color(0.95, 0.93, 0.89, 0.60), Color(0.13, 0.08, 0.05, 0.15), 28)
	se_n.border_width_left=1; se_n.border_width_right=1; se_n.border_width_top=1; se_n.border_width_bottom=1
	se_n.content_margin_left = 20
	var se_f := _flat(Color(1.00, 1.00, 1.00, 1.00), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.88), 28)
	se_f.border_width_left=1; se_f.border_width_right=1; se_f.border_width_top=1; se_f.border_width_bottom=1
	se_f.content_margin_left = 20
	se_f.shadow_size = 12; se_f.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.18)
	
	search_edit.add_theme_stylebox_override("normal", se_n)
	search_edit.add_theme_stylebox_override("focus",  se_f)
	search_edit.add_theme_color_override("font_color",        C_TEXT)
	search_edit.add_theme_color_override("placeholder_color", Color(0.13, 0.08, 0.05, 0.7))
	search_edit.add_theme_color_override("caret_color",       C_GOLD)

	# Filter buttons style
	_style_filter_btn(btn_all, current_filter == "all")
	_style_filter_btn(btn_danca, current_filter == "dan_ca")
	_style_filter_btn(btn_trutinh, current_filter == "tru_tinh")
	_style_filter_btn(btn_cotruyen, current_filter == "co_truyen")

	# Mobile Bottom bar style
	var bottom_s := _flat(C_BG_BAR, Color(accent_color.r, accent_color.g, accent_color.b, 0.15), 0)
	bottom_s.border_width_left = 0; bottom_s.border_width_right = 0; bottom_s.border_width_bottom = 0
	bottom_s.border_width_top = 2
	bottom_bar.add_theme_stylebox_override("panel", bottom_s)

	_style_bottom_icon_btn(btn_courses_mob, false)
	_style_bottom_icon_btn(btn_room_mob,    false)
	_style_bottom_icon_btn(btn_songs_mob,   true)
	_style_bottom_icon_btn(btn_account_mob, false)

	_attach_bottom_icon_draw(btn_courses_mob, 1, false)
	_attach_bottom_icon_draw(btn_room_mob,    6, false)
	_attach_bottom_icon_draw(btn_songs_mob,   2, false)
	_attach_bottom_icon_draw(btn_account_mob, 5, false)

	# DetailPanel style matching global design
	var detail_s := _flat(C_CARD, Color(accent_color.r, accent_color.g, accent_color.b, 0.3), 24)
	detail_s.shadow_size = 16
	detail_s.shadow_color = Color(0, 0, 0, 0.08)
	detail_s.shadow_offset = Vector2(0, 6)
	detail_s.border_width_left = 1; detail_s.border_width_right = 1
	detail_s.border_width_top = 4; detail_s.border_width_bottom = 1
	detail_panel.add_theme_stylebox_override("panel", detail_s)

	# Start practice button styling
	var sp_n := _flat(theme_color, accent_color, 16)
	sp_n.border_width_left = 1; sp_n.border_width_right = 1
	sp_n.border_width_top = 1; sp_n.border_width_bottom = 1
	sp_n.shadow_size = 8
	sp_n.shadow_color = Color(theme_color.r, theme_color.g, theme_color.b, 0.25)
	sp_n.shadow_offset = Vector2(0, 3)

	var sp_h := _flat(theme_color.lightened(0.12), Color.WHITE, 16)
	sp_h.border_width_left = 1; sp_h.border_width_right = 1
	sp_h.border_width_top = 1; sp_h.border_width_bottom = 1
	sp_h.shadow_size = 8
	sp_h.shadow_color = Color(theme_color.r, theme_color.g, theme_color.b, 0.35)

	var sp_p := _flat(theme_color.darkened(0.12), accent_color, 16)
	
	btn_start_practice.add_theme_stylebox_override("normal", sp_n)
	btn_start_practice.add_theme_stylebox_override("hover", sp_h)
	btn_start_practice.add_theme_stylebox_override("pressed", sp_p)
	btn_start_practice.add_theme_stylebox_override("focus", _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	btn_start_practice.add_theme_color_override("font_color", Color.WHITE)
	btn_start_practice.add_theme_color_override("font_hover_color", Color.WHITE)
	btn_start_practice.add_theme_color_override("font_pressed_color", Color.WHITE)

func _style_filter_btn(btn: Button, active: bool) -> void:
	var selected_inst = SecureDataManager.data.get("selected_instrument", "dan_tranh")
	
	var theme_color := C_RED_SON
	var accent_color := C_GOLD
	# Use unified theme color (Dan Tranh style)

	var bg := theme_color if active else Color(1.0, 1.0, 1.0, 0.85)
	var border := theme_color.darkened(0.1) if active else Color.TRANSPARENT
	
	var style := _flat(bg, border, 20)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", _flat(bg.lightened(0.12) if active else Color.WHITE, border, 20))
	btn.add_theme_stylebox_override("pressed", _flat(bg.darkened(0.12), border, 20))
	btn.add_theme_stylebox_override("focus", _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	btn.add_theme_color_override("font_color", Color.WHITE if active else C_TEXT)
	btn.add_theme_color_override("font_hover_color", Color.WHITE if active else theme_color)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)

func _style_bottom_icon_btn(btn: Button, is_active: bool, is_locked: bool = false) -> void:
	var selected_inst = SecureDataManager.data.get("selected_instrument", "dan_tranh")
	
	var theme_color := C_RED_SON
	var accent_color := C_GOLD
	# Use unified theme color (Dan Tranh style)

	var bg_n := _flat(Color(0, 0, 0, 0) if not is_active else Color(theme_color.r, theme_color.g, theme_color.b, 0.08), Color(0, 0, 0, 0), 12)
	var bg_h := _flat(Color(accent_color.r, accent_color.g, accent_color.b, 0.06) if not is_locked else Color(0, 0, 0, 0), Color(0, 0, 0, 0), 12)
	var bg_p := _flat(Color(theme_color.r, theme_color.g, theme_color.b, 0.15) if not is_locked else Color(0, 0, 0, 0), Color(0, 0, 0, 0), 12)

	bg_n.content_margin_top = 42
	bg_n.content_margin_bottom = 6
	bg_h.content_margin_top = 42
	bg_h.content_margin_bottom = 6
	bg_p.content_margin_top = 42
	bg_p.content_margin_bottom = 6

	if is_active:
		bg_n.border_width_top = 4
		bg_n.border_width_left = 0; bg_n.border_width_right = 0; bg_n.border_width_bottom = 0
		bg_n.border_color = accent_color

	btn.add_theme_stylebox_override("normal",  bg_n)
	btn.add_theme_stylebox_override("hover",   bg_h)
	btn.add_theme_stylebox_override("pressed", bg_p)
	btn.add_theme_stylebox_override("focus",   _flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))
	btn.add_theme_color_override("font_color",         theme_color if is_active else (Color(0.43, 0.38, 0.33, 0.40) if is_locked else Color(0.43, 0.38, 0.33, 1.0)))
	btn.add_theme_color_override("font_hover_color",   Color(0.43, 0.38, 0.33, 0.8) if is_locked else Color(0.13, 0.08, 0.05, 1.0))
	btn.add_theme_color_override("font_pressed_color", theme_color if not is_locked else Color(0.43, 0.38, 0.33, 0.40))

func _attach_bottom_icon_draw(btn: Button, icon_type: int, is_locked: bool = false) -> void:
	for c in btn.get_children():
		if c.name == "IconDraw": c.queue_free()
		
	var ic := Control.new()
	ic.name = "IconDraw"
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic.layout_mode = 1
	ic.anchors_preset = Control.PRESET_CENTER_TOP
	ic.anchor_left = 0.5; ic.anchor_right = 0.5
	ic.anchor_top = 0.0;  ic.anchor_bottom = 0.0
	ic.offset_left = -20; ic.offset_right = 20
	ic.offset_top = 6;    ic.offset_bottom = 38
	ic.draw.connect(func() -> void: _draw_sidebar_icon(ic, icon_type, is_locked))
	btn.add_child(ic)

func _draw_sidebar_icon(c: Control, t: int, is_locked: bool = false) -> void:
	var sz := c.size
	var cx := sz.x * 0.5
	var cy := sz.y * 0.5
	var col : Color = c.get_parent().get_theme_color("font_color", "Button")

	var selected_inst = SecureDataManager.data.get("selected_instrument", "dan_tranh")
	var accent_color := C_GOLD
	# Use unified theme color (Dan Tranh style)

	var tex_name := ""
	match t:
		0: tex_name = "menu"
		1: tex_name = "course"
		2: tex_name = "songs"
		3: tex_name = "game"
		4: tex_name = "progress"
		5: tex_name = "account"
		6: tex_name = "room"
	
	var texture : Texture2D = null
	if _sidebar_icons_cache.has(t):
		texture = _sidebar_icons_cache[t]
	elif tex_name != "":
		texture = load("res://assets/textures/icons8/" + tex_name + ".png") as Texture2D
		_sidebar_icons_cache[t] = texture
	
	if texture:
		var icon_sz := Vector2(36, 36)
		if t == 0:
			icon_sz = Vector2(28, 28)
		var rect := Rect2(Vector2(cx - icon_sz.x/2, cy - icon_sz.y/2), icon_sz)
		c.draw_texture_rect(texture, rect, false, col)
	
	if is_locked:
		var lock_tex : Texture2D = null
		if _sidebar_icons_cache.has("lock"):
			lock_tex = _sidebar_icons_cache["lock"]
		else:
			lock_tex = load("res://assets/textures/icons8/lock.png") as Texture2D
			_sidebar_icons_cache["lock"] = lock_tex
			
		if lock_tex:
			var lx := cx + 10.0
			var ly := cy + 8.0
			c.draw_texture_rect(lock_tex, Rect2(lx - 6, ly - 6, 12, 12), false, accent_color)

# ─── Setup Events ─────────────────────────────────────────────────────────────
func _connect_events() -> void:
	back_btn.pressed.connect(_go_back)
	_make_btn_bouncy(back_btn)
	
	search_edit.text_changed.connect(func(new_text: String) -> void:
		search_text = new_text
		_populate_songs()
	)

	btn_all.pressed.connect(func() -> void: _set_filter("all"))
	btn_danca.pressed.connect(func() -> void: _set_filter("dan_ca"))
	btn_trutinh.pressed.connect(func() -> void: _set_filter("tru_tinh"))
	btn_cotruyen.pressed.connect(func() -> void: _set_filter("co_truyen"))

	for btn in [btn_all, btn_danca, btn_trutinh, btn_cotruyen]:
		_make_btn_bouncy(btn)

	btn_courses_mob.pressed.connect(func() -> void: _fade_to("res://scenes/MainMenu.tscn"))
	btn_room_mob.pressed.connect(func() -> void: _fade_to("res://scenes/VirtualMusicRoom.tscn"))
	btn_account_mob.pressed.connect(func() -> void: _fade_to("res://scenes/AccountScreen.tscn"))

	for btn in [btn_courses_mob, btn_room_mob, btn_songs_mob, btn_account_mob]:
		_make_btn_bouncy(btn)

	btn_start_practice.pressed.connect(func() -> void:
		if not selected_song_data.is_empty():
			_on_play_song(selected_song_data)
	)
	_make_btn_bouncy(btn_start_practice)

func _set_filter(filter_name: String) -> void:
	current_filter = filter_name
	_style_filter_btn(btn_all, current_filter == "all")
	_style_filter_btn(btn_danca, current_filter == "dan_ca")
	_style_filter_btn(btn_trutinh, current_filter == "tru_tinh")
	_style_filter_btn(btn_cotruyen, current_filter == "co_truyen")
	_populate_songs()

# ─── Populate Song Cards ──────────────────────────────────────────────────────
func _populate_songs() -> void:
	# Reset selected card reference
	selected_card_node = null
	
	# Clear grid
	for child in songs_grid.get_children():
		child.queue_free()

	var selected_inst = SecureDataManager.data.get("selected_instrument", "dan_tranh")
	
	var first_card : PanelContainer = null
	var first_song : Dictionary = {}

	for song in SONGS_DATA:
		# Filter by instrument selection
		if song.instrument != selected_inst:
			continue
		# Search Filter
		if search_text != "" and not search_text.to_lower() in song.title.to_lower():
			continue
		# Category Filter
		if current_filter != "all" and song.genre != current_filter:
			continue
			
		var card := _create_song_card(song)
		songs_grid.add_child(card)
		
		if first_card == null:
			first_card = card
			first_song = song

	# Auto-select first song on desktop if available
	var viewport_size = get_viewport().size
	var is_mobile = viewport_size.x < viewport_size.y or viewport_size.x < 768
	if not is_mobile and first_card != null:
		# Wait for card to be ready in tree before modifying styles
		_select_song(first_song, first_card)
	elif not is_mobile:
		_clear_details()

func _create_song_card(song: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	
	var selected_inst = SecureDataManager.data.get("selected_instrument", "dan_tranh")
	var theme_color := C_RED_SON
	var accent_color := C_GOLD
	# Use unified theme color (Dan Tranh style)

	var card_style := _flat(C_CARD, Color(accent_color.r, accent_color.g, accent_color.b, 0.22), 20)
	card_style.shadow_size = 12
	card_style.shadow_color = Color(0, 0, 0, 0.05)
	card_style.shadow_offset = Vector2(0, 4)
	card_style.border_width_left = 1
	card_style.border_width_right = 1
	card_style.border_width_top = 3
	card_style.border_width_bottom = 1
	card.add_theme_stylebox_override("panel", card_style)
	card.pivot_offset = Vector2(200, 75)
	card.custom_minimum_size = Vector2(0, 130)

	card.set_meta("song_data", song)
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var viewport_size = get_viewport().size
			var is_mobile = viewport_size.x < viewport_size.y or viewport_size.x < 768
			if is_mobile:
				_on_play_song(song)
			else:
				_select_song(song, card)
	)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	margin.add_child(hbox)

	# Left Column: Round Icon representing the instrument
	var icon_circle := PanelContainer.new()
	icon_circle.custom_minimum_size = Vector2(58, 58)
	icon_circle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var icon_bg_color := Color(0.97, 0.91, 0.85, 1.0)
	var icon_border_color := C_GOLD
	if song.instrument == "dan_tranh":
		icon_bg_color = Color(0.97, 0.91, 0.85, 1.0)
		icon_border_color = C_GOLD
	elif song.instrument == "sao_truc":
		icon_bg_color = Color(0.88, 0.94, 0.90, 1.0)
		icon_border_color = C_JADE_LIGHT
	elif song.instrument == "dan_bau":
		icon_bg_color = Color(0.92, 0.90, 0.95, 1.0)
		icon_border_color = Color(0.55, 0.45, 0.80, 1.0)
		
	var icon_circle_style := _flat(icon_bg_color, icon_border_color, 29)
	icon_circle.add_theme_stylebox_override("panel", icon_circle_style)

	var icon_lbl := TextureRect.new()
	if song.instrument == "dan_tranh":
		icon_lbl.texture = load("res://assets/textures/lucide/music.svg") as Texture2D
		icon_lbl.modulate = icon_border_color
	elif song.instrument == "sao_truc":
		icon_lbl.texture = load("res://assets/textures/lucide/music.svg") as Texture2D
		icon_lbl.modulate = icon_border_color
	else:
		icon_lbl.texture = load("res://assets/textures/lucide/music.svg") as Texture2D
		icon_lbl.modulate = icon_border_color
	icon_lbl.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_lbl.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_lbl.custom_minimum_size = Vector2(24, 24)
	icon_circle.add_child(icon_lbl)
	hbox.add_child(icon_circle)

	# Middle Column: Song description & metadata pills
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = song.title
	var font_card_title := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if font_card_title:
		title_lbl.add_theme_font_override("font", font_card_title)
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", C_TEXT)
	vbox.add_child(title_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = song.desc
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", C_TEXT_MUTED)
	vbox.add_child(desc_lbl)

	# Tag Pills Container
	var tags_hbox := HBoxContainer.new()
	tags_hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(tags_hbox)

	# Instrument Tag
	var inst_pill := PanelContainer.new()
	var inst_bg := C_GOLD
	if song.instrument == "dan_tranh":
		inst_bg = C_GOLD
	elif song.instrument == "sao_truc":
		inst_bg = C_JADE
	elif song.instrument == "dan_bau":
		inst_bg = Color(0.55, 0.45, 0.80, 1.0)
	inst_pill.add_theme_stylebox_override("panel", _flat(inst_bg, Color(0,0,0,0), 6))
	
	var inst_lbl := Label.new()
	inst_lbl.text = song.instrument_label
	inst_lbl.add_theme_font_size_override("font_size", 10)
	inst_lbl.add_theme_color_override("font_color", Color.WHITE)
	inst_pill.add_child(inst_lbl)
	tags_hbox.add_child(inst_pill)

	# Difficulty Tag
	var diff_pill := PanelContainer.new()
	diff_pill.add_theme_stylebox_override("panel", _flat(song.difficulty_color, Color(0,0,0,0), 6))
	var diff_lbl := Label.new()
	diff_lbl.text = song.difficulty
	diff_lbl.add_theme_font_size_override("font_size", 10)
	diff_lbl.add_theme_color_override("font_color", Color.WHITE)
	diff_pill.add_child(diff_lbl)
	tags_hbox.add_child(diff_pill)

	# XP Tag
	var xp_pill := PanelContainer.new()
	xp_pill.add_theme_stylebox_override("panel", _flat(Color(0.13, 0.08, 0.05, 0.06), Color(0,0,0,0), 6))
	var xp_lbl := Label.new()
	xp_lbl.text = "+%d XP" % song.xp
	xp_lbl.add_theme_font_size_override("font_size", 10)
	xp_lbl.add_theme_color_override("font_color", C_TEXT_MUTED)
	xp_pill.add_child(xp_lbl)
	tags_hbox.add_child(xp_pill)

	# Right Column: Bouncy Dynamic Play Button
	var play_btn := Button.new()
	play_btn.custom_minimum_size = Vector2(48, 48)
	play_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style_circular_play_btn(play_btn, theme_color, accent_color)
	_make_btn_bouncy(play_btn)
	play_btn.pressed.connect(func() -> void: _on_play_song(song))
	hbox.add_child(play_btn)

	return card

func _style_circular_play_btn(btn: Button, theme_color: Color, accent_color: Color) -> void:
	var pb_n := _flat(theme_color, accent_color, 24)
	pb_n.border_width_left = 2; pb_n.border_width_right = 2
	pb_n.border_width_top = 2; pb_n.border_width_bottom = 2
	pb_n.shadow_size = 6; pb_n.shadow_color = Color(theme_color.r, theme_color.g, theme_color.b, 0.3)
	
	var pb_h := _flat(theme_color.lightened(0.15), Color.WHITE, 24)
	pb_h.border_width_left = 2; pb_h.border_width_right = 2
	pb_h.border_width_top = 2; pb_h.border_width_bottom = 2
	
	btn.add_theme_stylebox_override("normal", pb_n)
	btn.add_theme_stylebox_override("hover", pb_h)
	btn.add_theme_stylebox_override("pressed", _flat(theme_color.darkened(0.15), accent_color, 24))
	btn.add_theme_stylebox_override("focus", _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	
	btn.icon = load("res://assets/textures/lucide/play.svg") as Texture2D
	btn.expand_icon = true
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.add_theme_color_override("icon_normal_color", Color.WHITE)
	btn.add_theme_color_override("icon_hover_color", Color.WHITE)
	btn.add_theme_color_override("icon_pressed_color", Color.WHITE)

# ─── Navigation ────────────────────────────────────────────────────────────────
func _on_play_song(song: Dictionary) -> void:
	# Store instrument and parameters
	SecureDataManager.data["selected_instrument"] = song.instrument
	SecureDataManager.save_data()
	
	# Transition dynamic values to practice room
	var sheet_typed: Array[String] = []
	sheet_typed.assign(song.sheet)
	var durations_typed: Array[float] = []
	if song.has("durations"):
		durations_typed.assign(song.durations)

	if song.instrument == "dan_tranh":
		var pr_script = load("res://scripts/PracticeRoom.gd")
		if pr_script:
			pr_script.current_song_title = song.title
			pr_script.current_song_sheet = sheet_typed
		_fade_to("res://scenes/PracticeRoom.tscn")
	elif song.instrument == "dan_bau":
		var pr_script = load("res://scripts/PracticeDanBau.gd")
		if pr_script:
			pr_script.current_song_title = song.title
			pr_script.current_song_sheet = sheet_typed
		_fade_to("res://scenes/PracticeDanBau.tscn")
	else:
		var pr_script = load("res://scripts/PracticeSaoTruc.gd")
		if pr_script:
			pr_script.current_song_title = song.title
			pr_script.current_song_sheet = sheet_typed
			pr_script.current_song_durations = durations_typed
			if song.has("bpm"):
				pr_script.current_song_bpm = float(song.bpm)
		_fade_to("res://scenes/PracticeSaoTruc.tscn")

func _go_back() -> void:
	_fade_to("res://scenes/MainMenu.tscn")

func _fade_to(path: String) -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.22)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file(path))

# ─── Animation In ──────────────────────────────────────────────────────────────
func _animate_in() -> void:
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.32)

# ─── Responsive Layout ────────────────────────────────────────────────────────
func _on_viewport_size_changed() -> void:
	var viewport_size = get_viewport().size
	var is_mobile = viewport_size.x < viewport_size.y or viewport_size.x < 768
	
	bottom_bar.visible = is_mobile
	songs_grid.columns = 1 if is_mobile else 2
	
	if detail_panel:
		detail_panel.visible = not is_mobile
	
	# Adjust margin containers dynamically
	var top_m := $Root/TopBar/TopM as MarginContainer
	var content_m := $Root/Content/ContentMargin as MarginContainer
	
	if is_mobile:
		top_m.add_theme_constant_override("margin_left", 16)
		top_m.add_theme_constant_override("margin_right", 16)
		content_m.add_theme_constant_override("margin_left", 16)
		content_m.add_theme_constant_override("margin_right", 16)
		content_m.add_theme_constant_override("margin_top", 16)
		content_m.add_theme_constant_override("margin_bottom", 16)
		
		back_btn.custom_minimum_size = Vector2(100, back_btn.custom_minimum_size.y)
		page_title.add_theme_font_size_override("font_size", 20)
		search_edit.add_theme_font_size_override("font_size", 16)
		
		# Shrink filter tabs for scrolling/wrapping
		for btn in [btn_all, btn_danca, btn_trutinh, btn_cotruyen]:
			btn.custom_minimum_size = Vector2(90, 38)
			btn.add_theme_font_size_override("font_size", 13)
	else:
		top_m.add_theme_constant_override("margin_left", 48)
		top_m.add_theme_constant_override("margin_right", 48)
		content_m.add_theme_constant_override("margin_left", 48)
		content_m.add_theme_constant_override("margin_right", 48)
		content_m.add_theme_constant_override("margin_top", 28)
		content_m.add_theme_constant_override("margin_bottom", 28)
		
		back_btn.custom_minimum_size = Vector2(180, back_btn.custom_minimum_size.y)
		page_title.add_theme_font_size_override("font_size", 36)
		search_edit.add_theme_font_size_override("font_size", 18)
		
		for btn in [btn_all, btn_danca, btn_trutinh, btn_cotruyen]:
			btn.custom_minimum_size = Vector2(120, 44)
			btn.add_theme_font_size_override("font_size", 16)

# ─── Helpers ───────────────────────────────────────────────────────────────────
func _flat(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.border_color = border
	s.border_width_left = 1; s.border_width_right = 1
	s.border_width_top  = 1; s.border_width_bottom = 1
	s.corner_radius_top_left     = radius; s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius; s.corner_radius_bottom_right = radius
	return s

func _make_btn_bouncy(btn: Button) -> void:
	btn.pivot_offset = btn.size / 2.0
	btn.resized.connect(func() -> void: btn.pivot_offset = btn.size / 2.0)
	btn.mouse_entered.connect(func() -> void:
		var t := create_tween()
		t.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func() -> void:
		var t := create_tween()
		t.tween_property(btn, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	btn.button_down.connect(func() -> void:
		var t := create_tween()
		t.tween_property(btn, "scale", Vector2(0.95, 0.95), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	btn.button_up.connect(func() -> void:
		var t := create_tween()
		t.tween_property(btn, "scale", Vector2(1.05, 1.05) if btn.is_hovered() else Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)

# ─── Song Preview & Detail Helpers ─────────────────────────────────────────────
func _clear_details() -> void:
	selected_song_data = {}
	selected_card_node = null
	detail_title.text = "Không có bài hát"
	detail_desc.text = "Vui lòng điều chỉnh bộ lọc hoặc từ khóa tìm kiếm."
	for child in detail_tags.get_children():
		child.queue_free()
	for child in notes_hbox.get_children():
		child.queue_free()
	btn_start_practice.disabled = true
	btn_start_practice.text = "KHÔNG THỂ LUYỆN TẬP"

func _select_song(song: Dictionary, card: PanelContainer) -> void:
	selected_song_data = song
	
	# Update card highlight
	if selected_card_node != null and is_instance_valid(selected_card_node):
		# Reset previous card to normal style
		var prev_song = selected_card_node.get_meta("song_data") as Dictionary
		_style_card_border(selected_card_node, prev_song, false)
		
	selected_card_node = card
	if selected_card_node != null and is_instance_valid(selected_card_node):
		_style_card_border(selected_card_node, song, true)
		
	# Update Detail Panel info
	detail_title.text = song.title
	var font_title := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if font_title:
		detail_title.add_theme_font_override("font", font_title)
	detail_desc.text = song.desc
	btn_start_practice.disabled = false
	btn_start_practice.text = "VÀO LUYỆN TẬP"
	
	# Update dynamic tags in details panel
	for child in detail_tags.get_children():
		child.queue_free()
		
	var selected_inst = SecureDataManager.data.get("selected_instrument", "dan_tranh")
	var theme_color := C_RED_SON
	var accent_color := C_GOLD
	# Use unified theme color (Dan Tranh style)
		
	# Instrument Tag
	var inst_pill := PanelContainer.new()
	var inst_bg := C_GOLD
	if song.instrument == "dan_tranh": inst_bg = C_GOLD
	elif song.instrument == "sao_truc": inst_bg = C_JADE
	elif song.instrument == "dan_bau": inst_bg = Color(0.55, 0.45, 0.80, 1.0)
	inst_pill.add_theme_stylebox_override("panel", _flat(inst_bg, Color(0,0,0,0), 6))
	var inst_lbl := Label.new()
	inst_lbl.text = song.instrument_label
	inst_lbl.add_theme_font_size_override("font_size", 11)
	inst_lbl.add_theme_color_override("font_color", Color.WHITE)
	inst_pill.add_child(inst_lbl)
	detail_tags.add_child(inst_pill)
	
	# Difficulty Tag
	var diff_pill := PanelContainer.new()
	diff_pill.add_theme_stylebox_override("panel", _flat(song.difficulty_color, Color(0,0,0,0), 6))
	var diff_lbl := Label.new()
	diff_lbl.text = song.difficulty
	diff_lbl.add_theme_font_size_override("font_size", 11)
	diff_lbl.add_theme_color_override("font_color", Color.WHITE)
	diff_pill.add_child(diff_lbl)
	detail_tags.add_child(diff_pill)
	
	# XP Tag
	var xp_pill := PanelContainer.new()
	xp_pill.add_theme_stylebox_override("panel", _flat(Color(theme_color.r, theme_color.g, theme_color.b, 0.08), Color(0,0,0,0), 6))
	var xp_lbl := Label.new()
	xp_lbl.text = "+%d XP" % song.xp
	xp_lbl.add_theme_font_size_override("font_size", 11)
	xp_lbl.add_theme_color_override("font_color", theme_color)
	xp_pill.add_child(xp_lbl)
	detail_tags.add_child(xp_pill)
	
	# Update Sheet notes preview circles
	for child in notes_hbox.get_children():
		child.queue_free()
		
	for note in song.sheet:
		var note_circle := PanelContainer.new()
		note_circle.custom_minimum_size = Vector2(46, 46)
		note_circle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		var circle_style := _flat(Color(1.0, 1.0, 1.0, 0.95), Color(accent_color.r, accent_color.g, accent_color.b, 0.4), 23)
		circle_style.border_width_left = 2; circle_style.border_width_right = 2
		circle_style.border_width_top = 2; circle_style.border_width_bottom = 2
		note_circle.add_theme_stylebox_override("panel", circle_style)
		
		var note_lbl := Label.new()
		note_lbl.text = str(note)
		note_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		note_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var font_bold = load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
		if font_bold:
			note_lbl.add_theme_font_override("font", font_bold)
		note_lbl.add_theme_font_size_override("font_size", 14)
		note_lbl.add_theme_color_override("font_color", C_TEXT)
		note_circle.add_child(note_lbl)
		
		notes_hbox.add_child(note_circle)

func _style_card_border(card: PanelContainer, song: Dictionary, is_selected: bool) -> void:
	var selected_inst = SecureDataManager.data.get("selected_instrument", "dan_tranh")
	var theme_color := C_RED_SON
	var accent_color := C_GOLD
	# Use unified theme color (Dan Tranh style)
	var border_color = theme_color if is_selected else Color(accent_color.r, accent_color.g, accent_color.b, 0.22)
	var border_width = 3 if is_selected else 1
	var shadow_size = 18 if is_selected else 12
	var shadow_alpha = 0.12 if is_selected else 0.05
	
	var card_style := _flat(C_CARD, border_color, 20)
	card_style.shadow_size = shadow_size
	card_style.shadow_color = Color(0, 0, 0, shadow_alpha)
	card_style.shadow_offset = Vector2(0, 5 if is_selected else 4)
	card_style.border_width_left = border_width
	card_style.border_width_right = border_width
	card_style.border_width_top = 4 if is_selected else 3
	card_style.border_width_bottom = border_width
	
	card.add_theme_stylebox_override("panel", card_style)
