extends Control

# ─── Vietnamese Traditional Color Palette ──────────────────────────────────────
const C_GOLD       := Color(0.77, 0.58, 0.15, 1.0)
const C_GOLD_LIGHT := Color(0.95, 0.82, 0.45, 1.0)
const C_GOLD_DARK  := Color(0.06, 0.02, 0.00, 1.0)
const C_RED_SON    := Color(0.70, 0.12, 0.08, 1.0)
const C_RED_DK     := Color(0.50, 0.08, 0.05, 1.0)
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
		"sheet": ["Hò","Hò","Xự","Xang","Xang","Xê","Công","Xê","Xang","Xự","Hò"]
	},
	{
		"id": "song_002",
		"title": "Dạ Cổ Hoài Lang",
		"desc": "Bản nhạc cổ hoài niệm Nam Bộ của nhạc sĩ Cao Văn Lầu, giai điệu da diết.",
		"instrument": "dan_tranh",
		"instrument_label": "Đàn Tranh",
		"difficulty": "Khó",
		"difficulty_color": Color(0.70, 0.12, 0.08, 1.0), # Red
		"genre": "co_truyen",
		"genre_label": "Cổ truyền",
		"xp": 250,
		"sheet": ["Liu","Liu","Ú","Liu","Xang","Xê","Công","Xự","Xang","Liu","Hò"]
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
		"sheet": ["Xang","Xự","Hò","Xự","Xang","Xê","Liu","Công","Xê","Xang","Hò"]
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
		"sheet": ["Hò","Xang","Xê","Liu","Công","Liu","Xê","Xang","Xự","Hò","Hò"]
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
		"difficulty_color": Color(0.70, 0.12, 0.08, 1.0), # Red
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
	}
]

# ─── @onready references ─────────────────────────────────────────────────────
@onready var back_btn        : Button         = $Root/TopBar/TopM/TopH/BackBtn
@onready var page_title      : Label          = $Root/TopBar/TopM/TopH/PageTitle
@onready var search_edit     : LineEdit       = $Root/Content/ContentMargin/MainVBox/SearchFilterHBox/SearchEdit
@onready var btn_all         : Button         = $Root/Content/ContentMargin/MainVBox/FilterTabs/BtnAll
@onready var btn_danca       : Button         = $Root/Content/ContentMargin/MainVBox/FilterTabs/BtnDanCa
@onready var btn_trutinh     : Button         = $Root/Content/ContentMargin/MainVBox/FilterTabs/BtnTruTinh
@onready var btn_cotruyen    : Button         = $Root/Content/ContentMargin/MainVBox/FilterTabs/BtnCoTruyen
@onready var songs_grid      : GridContainer  = $Root/Content/ContentMargin/MainVBox/SongsScroll/SongsGrid

@onready var bottom_bar      : PanelContainer = $Root/BottomBar
@onready var btn_courses_mob : Button         = $Root/BottomBar/BottomM/BottomH/BtnCoursesMobile
@onready var btn_room_mob    : Button         = $Root/BottomBar/BottomM/BottomH/BtnRoomMobile
@onready var btn_songs_mob   : Button         = $Root/BottomBar/BottomM/BottomH/BtnSongsMobile
@onready var btn_account_mob : Button         = $Root/BottomBar/BottomM/BottomH/BtnAccountMobile

# ─── Filtering State ──────────────────────────────────────────────────────────
var current_filter := "all"
var search_text := ""

func _ready() -> void:
	_build_theme()
	_connect_events()
	_populate_songs()
	_animate_in()

	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()

# ─── Theme & Layout Customization ─────────────────────────────────────────────
func _build_theme() -> void:
	# Top bar style matching global alabaster design
	var top_s := _flat(C_BG_BAR, Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.15), 0)
	top_s.border_width_bottom = 2; top_s.border_width_top = 0; top_s.border_width_left = 0; top_s.border_width_right = 0
	$Root/TopBar.add_theme_stylebox_override("panel", top_s)
	page_title.add_theme_color_override("font_color", C_RED_SON)

	# Back button style
	back_btn.add_theme_color_override("font_color", C_RED_SON)
	back_btn.add_theme_color_override("font_hover_color", C_RED_SON.lightened(0.15))
	back_btn.add_theme_stylebox_override("normal",  _flat(Color(0,0,0,0), Color(0,0,0,0), 8))
	back_btn.add_theme_stylebox_override("hover",   _flat(Color(C_RED_SON.r,C_RED_SON.g,C_RED_SON.b,0.12), Color(0,0,0,0), 8))
	back_btn.add_theme_stylebox_override("pressed", _flat(Color(C_RED_SON.r,C_RED_SON.g,C_RED_SON.b,0.20), Color(0,0,0,0), 8))
	back_btn.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0), 0))

	# Search LineEdit style
	var se_n := _flat(Color(1.0, 1.0, 1.0, 0.8), Color(0.13, 0.08, 0.05, 0.15), 24)
	var se_f := _flat(Color(1.0, 1.0, 1.0, 1.0), C_GOLD, 24)
	se_f.shadow_size = 10; se_f.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.15)
	search_edit.add_theme_stylebox_override("normal", se_n)
	search_edit.add_theme_stylebox_override("focus",  se_f)
	search_edit.add_theme_color_override("font_color",        C_TEXT)
	search_edit.add_theme_color_override("placeholder_color", Color(0.43, 0.38, 0.33, 0.55))
	search_edit.add_theme_color_override("caret_color",       C_GOLD)

	# Filter buttons style
	_style_filter_btn(btn_all, true)
	_style_filter_btn(btn_danca, false)
	_style_filter_btn(btn_trutinh, false)
	_style_filter_btn(btn_cotruyen, false)

	# Mobile Bottom bar style
	var bottom_s := _flat(C_BG_BAR, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.15), 0)
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

func _style_filter_btn(btn: Button, active: bool) -> void:
	var bg := C_RED_SON if active else Color(0.95, 0.93, 0.89, 0.6)
	var fg := C_BG_DARK if active else C_TEXT_MUTED
	var border := C_RED_SON if active else Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.20)
	
	var style := _flat(bg, border, 16)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", _flat(bg.lightened(0.12), border, 16))
	btn.add_theme_stylebox_override("pressed", _flat(bg.darkened(0.12), border, 16))
	btn.add_theme_stylebox_override("focus", _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	btn.add_theme_color_override("font_color", fg)
	btn.add_theme_color_override("font_hover_color", fg)
	btn.add_theme_color_override("font_pressed_color", fg)

func _style_bottom_icon_btn(btn: Button, is_active: bool, is_locked: bool = false) -> void:
	var bg_n := _flat(Color(0, 0, 0, 0) if not is_active else Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.08), Color(0, 0, 0, 0), 12)
	var bg_h := _flat(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.06) if not is_locked else Color(0, 0, 0, 0), Color(0, 0, 0, 0), 12)
	var bg_p := _flat(Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.15) if not is_locked else Color(0, 0, 0, 0), Color(0, 0, 0, 0), 12)

	bg_n.content_margin_top = 42
	bg_n.content_margin_bottom = 6
	bg_h.content_margin_top = 42
	bg_h.content_margin_bottom = 6
	bg_p.content_margin_top = 42
	bg_p.content_margin_bottom = 6

	if is_active:
		bg_n.border_width_top = 4
		bg_n.border_width_left = 0; bg_n.border_width_right = 0; bg_n.border_width_bottom = 0
		bg_n.border_color = C_GOLD

	btn.add_theme_stylebox_override("normal",  bg_n)
	btn.add_theme_stylebox_override("hover",   bg_h)
	btn.add_theme_stylebox_override("pressed", bg_p)
	btn.add_theme_stylebox_override("focus",   _flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))
	btn.add_theme_color_override("font_color",         C_RED_SON if is_active else (Color(0.43, 0.38, 0.33, 0.40) if is_locked else Color(0.43, 0.38, 0.33, 1.0)))
	btn.add_theme_color_override("font_hover_color",   Color(0.43, 0.38, 0.33, 0.8) if is_locked else Color(0.13, 0.08, 0.05, 1.0))
	btn.add_theme_color_override("font_pressed_color", C_RED_SON if not is_locked else Color(0.43, 0.38, 0.33, 0.40))

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
	if tex_name != "":
		texture = load("res://assets/textures/icons8/" + tex_name + ".png") as Texture2D
	
	if texture:
		var icon_sz := Vector2(36, 36)
		if t == 0:
			icon_sz = Vector2(28, 28)
		var rect := Rect2(Vector2(cx - icon_sz.x/2, cy - icon_sz.y/2), icon_sz)
		c.draw_texture_rect(texture, rect, false, col)
	
	if is_locked:
		var lock_tex := load("res://assets/textures/icons8/lock.png") as Texture2D
		if lock_tex:
			var lx := cx + 10.0
			var ly := cy + 8.0
			c.draw_texture_rect(lock_tex, Rect2(lx - 6, ly - 6, 12, 12), false, C_GOLD)

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

	btn_courses_mob.pressed.connect(func() -> void: _fade_to("res://scenes/CourseMap.tscn"))
	btn_room_mob.pressed.connect(func() -> void: _fade_to("res://scenes/VirtualMusicRoom.tscn"))
	btn_account_mob.pressed.connect(func() -> void: _fade_to("res://scenes/AccountScreen.tscn"))

	for btn in [btn_courses_mob, btn_room_mob, btn_songs_mob, btn_account_mob]:
		_make_btn_bouncy(btn)

func _set_filter(filter_name: String) -> void:
	current_filter = filter_name
	_style_filter_btn(btn_all, current_filter == "all")
	_style_filter_btn(btn_danca, current_filter == "dan_ca")
	_style_filter_btn(btn_trutinh, current_filter == "tru_tinh")
	_style_filter_btn(btn_cotruyen, current_filter == "co_truyen")
	_populate_songs()

# ─── Populate Song Cards ──────────────────────────────────────────────────────
func _populate_songs() -> void:
	# Clear grid
	for child in songs_grid.get_children():
		child.queue_free()

	for song in SONGS_DATA:
		# Search Filter
		if search_text != "" and not search_text.to_lower() in song.title.to_lower():
			continue
		# Category Filter
		if current_filter != "all" and song.genre != current_filter:
			continue
			
		var card := _create_song_card(song)
		songs_grid.add_child(card)

func _create_song_card(song: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	var card_style := _flat(C_CARD, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.22), 20)
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
	var icon_bg_color = Color(0.97, 0.91, 0.85, 1.0) if song.instrument == "dan_tranh" else Color(0.88, 0.94, 0.90, 1.0)
	var icon_border_color = C_GOLD if song.instrument == "dan_tranh" else C_JADE_LIGHT
	var icon_circle_style := _flat(icon_bg_color, icon_border_color, 29)
	icon_circle.add_theme_stylebox_override("panel", icon_circle_style)

	var icon_lbl := Label.new()
	icon_lbl.text = "箏" if song.instrument == "dan_tranh" else "🪈"
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 24)
	icon_lbl.add_theme_color_override("font_color", icon_border_color)
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
	var font_title := load("res://assets/fonts/Lora-Bold.ttf") as Font
	if font_title:
		title_lbl.add_theme_font_override("font", font_title)
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
	var inst_bg = C_GOLD if song.instrument == "dan_tranh" else C_JADE
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

	# Right Column: Bouncy Red Play Button
	var play_btn := Button.new()
	play_btn.custom_minimum_size = Vector2(48, 48)
	play_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style_circular_play_btn(play_btn)
	_make_btn_bouncy(play_btn)
	play_btn.pressed.connect(func() -> void: _on_play_song(song))
	hbox.add_child(play_btn)

	return card

func _style_circular_play_btn(btn: Button) -> void:
	var pb_n := _flat(C_RED_SON, C_GOLD, 24)
	pb_n.border_width_left = 2; pb_n.border_width_right = 2
	pb_n.border_width_top = 2; pb_n.border_width_bottom = 2
	pb_n.shadow_size = 6; pb_n.shadow_color = Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.3)
	
	var pb_h := _flat(Color(0.85, 0.18, 0.12, 1.0), Color.WHITE, 24)
	pb_h.border_width_left = 2; pb_h.border_width_right = 2
	pb_h.border_width_top = 2; pb_h.border_width_bottom = 2
	
	btn.add_theme_stylebox_override("normal", pb_n)
	btn.add_theme_stylebox_override("hover", pb_h)
	btn.add_theme_stylebox_override("pressed", _flat(C_RED_DK, C_GOLD, 24))
	btn.add_theme_stylebox_override("focus", _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	
	var draw_node := Control.new()
	draw_node.name = "PlayTriangle"
	draw_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	draw_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	draw_node.draw.connect(func() -> void:
		var sz := draw_node.size
		var cx := sz.x * 0.54
		var cy := sz.y * 0.5
		var pts := PackedVector2Array([
			Vector2(cx - 6, cy - 8),
			Vector2(cx + 8, cy),
			Vector2(cx - 6, cy + 8)
		])
		draw_node.draw_colored_polygon(pts, Color.WHITE)
	)
	btn.add_child(draw_node)

# ─── Navigation ────────────────────────────────────────────────────────────────
func _on_play_song(song: Dictionary) -> void:
	# Store instrument and parameters
	SecureDataManager.data["selected_instrument"] = song.instrument
	SecureDataManager.save_data()
	
	# Transition dynamic values to practice room
	if song.instrument == "dan_tranh":
		var pr_script = load("res://scripts/PracticeRoom.gd")
		if pr_script:
			pr_script.current_song_title = song.title
			pr_script.current_song_sheet = song.sheet
		_fade_to("res://scenes/PracticeRoom.tscn")
	else:
		var pr_script = load("res://scripts/PracticeSaoTruc.gd")
		if pr_script:
			pr_script.current_song_title = song.title
			pr_script.current_song_sheet = song.sheet
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
	var size = get_viewport().size
	var is_mobile = size.x < size.y or size.x < 768
	
	bottom_bar.visible = is_mobile
	songs_grid.columns = 1 if is_mobile else 2
	
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
