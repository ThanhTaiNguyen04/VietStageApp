extends Control

const ApiClientScript = preload("res://scripts/ApiClient.gd")

# ─── Color Palette ────────────────────────────────────────────────────────────
const C_GOLD       := Color(0.77, 0.58, 0.15, 1.0)
const C_GOLD_LIGHT := Color(0.95, 0.82, 0.45, 1.0)
const C_JADE       := Color(0.09, 0.27, 0.18, 1.0)
const C_RED_SON    := Color(0.8, 0.2, 0.2, 1.0)
const C_BG_BAR     := Color(0.97, 0.95, 0.91, 0.55)
const C_CARD       := Color(1.0, 0.99, 0.97, 0.8)
const C_TEXT       := Color(0.13, 0.08, 0.05, 1.0)
const C_TEXT_MUTED := Color(0.43, 0.38, 0.33, 1.0)

# [node_id, label_text, bg, border, accent, icon_name]
const STAT_CARDS := [
	["G1", "Chuỗi liên tiếp",   Color(1.0, 1.0, 1.0, 0.85), Color(0.85, 0.4, 0.2, 0.5), Color(0.85, 0.4, 0.2, 1.0), "flame"],
	["G2", "Điểm tích lũy",      Color(1.0, 1.0, 1.0, 0.85), Color(0.77, 0.58, 0.15, 0.6), Color(0.8, 0.6, 0.1, 1.0), "star"],
	["G3", "Tiến trình học",     Color(1.0, 1.0, 1.0, 0.85), Color(0.2, 0.6, 0.4, 0.5), Color(0.2, 0.6, 0.4, 1.0), "trending-up"],
	["G4", "Ngày tham gia",      Color(1.0, 1.0, 1.0, 0.85), Color(0.4, 0.5, 0.8, 0.5), Color(0.3, 0.4, 0.7, 1.0), "calendar-days"],
]

# ─── Node Refs ───────────────────────────────────────────────────────────────
@onready var back_btn   : Button         = $Root/TopBar/TopM/TopH/BackBtn
@onready var page_title : Label          = $Root/TopBar/TopM/TopH/PageTitle
@onready var name_lbl   : Label          = $Root/Content/ContentV/Card/CardM/CardV/ProfileSection/NameLabel
@onready var email_lbl  : Label          = $Root/Content/ContentV/Card/CardM/CardV/ProfileSection/EmailLabel
@onready var logout_btn : Button         = $Root/Content/ContentV/Card/CardM/CardV/LogoutBtn
@onready var ver_label  : Label          = $Root/Content/ContentV/VerLabel
@onready var grid       : GridContainer  = $Root/Content/ContentV/Card/CardM/CardV/Grid
@onready var card_node  : PanelContainer = $Root/Content/ContentV/Card
@onready var av_circle  : PanelContainer = $Root/Content/ContentV/Card/CardM/CardV/ProfileSection/AvatarCircle
@onready var divider    : HSeparator     = $Root/Content/ContentV/Card/CardM/CardV/Divider
@onready var content_m  : MarginContainer = $Root/Content
@onready var bg         : TextureRect     = $BG
@onready var bg_overlay : ColorRect       = $BGOverlay
@onready var card_v     : VBoxContainer  = $Root/Content/ContentV/Card/CardM/CardV
@onready var profile_section: VBoxContainer = $Root/Content/ContentV/Card/CardM/CardV/ProfileSection

var _name_edit: LineEdit
var _main_split: HBoxContainer
var _left_col: VBoxContainer
var _right_col: VBoxContainer
var _api_client = null

func _ready() -> void:
	_api_client = ApiClientScript.new()
	add_child(_api_client)
	SecureDataManager.load_data()
	_restructure_layout()
	_populate_data()
	_enhance_ux()
	_build_theme()
	_animate_in()

	back_btn.pressed.connect(_go_back)
	logout_btn.pressed.connect(_on_logout)
	_make_btn_bouncy(back_btn)
	_make_btn_bouncy(logout_btn)

	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()

# ─── Layout Restructure ──────────────────────────────────────────────────────
func _restructure_layout() -> void:
	# Convert VBox layout to HBox layout (Left: Profile, Right: Stats)
	_main_split = HBoxContainer.new()
	_main_split.add_theme_constant_override("separation", 64)
	
	_left_col = VBoxContainer.new()
	_left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_left_col.size_flags_stretch_ratio = 1.0
	_left_col.alignment = BoxContainer.ALIGNMENT_CENTER
	_left_col.add_theme_constant_override("separation", 16)
	
	_right_col = VBoxContainer.new()
	_right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_right_col.size_flags_stretch_ratio = 1.5
	_right_col.alignment = BoxContainer.ALIGNMENT_CENTER
	_right_col.add_theme_constant_override("separation", 24)
	
	card_v.add_child(_main_split)
	card_v.move_child(_main_split, 0)
	_main_split.add_child(_left_col)
	_main_split.add_child(_right_col)
	
	# Move existing nodes
	if profile_section.get_parent():
		profile_section.get_parent().remove_child(profile_section)
	_left_col.add_child(profile_section)
	
	if divider.get_parent():
		divider.get_parent().remove_child(divider)
		divider.queue_free() # Remove divider since we use columns
		
	if grid.get_parent():
		grid.get_parent().remove_child(grid)
	_right_col.add_child(grid)
	grid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	grid.custom_minimum_size = Vector2(0, 240)
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 24)

# ─── Data ────────────────────────────────────────────────────────────────────
func _populate_data() -> void:
	page_title.text = "Hồ Sơ Học Viên"
	back_btn.text   = " Quay lại"
	var back_icon = load("res://assets/textures/lucide/arrow-left.svg") as Texture2D
	if back_icon: back_btn.icon = back_icon; back_btn.expand_icon = true
	
	var avatar_rect = av_circle.get_node_or_null("Avatar") as TextureRect
	if avatar_rect:
		avatar_rect.texture = load("res://assets/textures/avacogiaoMai_asset.png")
	
	ver_label.hide()

	name_lbl.text  = SecureDataManager.data.get("user_name",  "Google User")
	email_lbl.text = SecureDataManager.data.get("user_email", "google.user@gmail.com")

	# Stats
	var streak : int   = int(SecureDataManager.data.get("daily_streak", 1))
	var psecs  : int   = int(SecureDataManager.data.get("practice_time_seconds", 0))
	var xp     : int   = 1240 + int(psecs / 6.0)
	var inst   : String = SecureDataManager.data.get("selected_instrument", "dan_tranh")
	var prog   : float  = SecureDataManager.get_course_progress(inst)
	var join   : String = SecureDataManager.data.get("join_date", "")
	if join == "":
		var d := Time.get_date_dict_from_system()
		join = "%02d/%02d/%d" % [d.day, d.month, d.year]
		SecureDataManager.data["join_date"] = join
		SecureDataManager.save_data()

	var stat_values := [
		"%d Ngày" % streak,
		"%d XP"   % xp,
		"%.0f%%" % prog,
		join,
	]

	for i in STAT_CARDS.size():
		var id  : String = STAT_CARDS[i][0] as String
		var lbl : String = STAT_CARDS[i][1] as String
		var icon_lbl = _get_stat_node(id, "Icon")
		if icon_lbl: icon_lbl.hide()
		var val_node = _get_stat_node(id, "Val")
		var parent = val_node.get_parent()
		if not parent.has_node("IconTex"):
			var tex_rect = TextureRect.new()
			tex_rect.name = "IconTex"
			tex_rect.texture = load("res://assets/textures/lucide/" + STAT_CARDS[i][5] + ".svg") as Texture2D
			tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.custom_minimum_size = Vector2(28, 28)
			tex_rect.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			tex_rect.modulate = STAT_CARDS[i][4] as Color
			parent.add_child(tex_rect)
			parent.move_child(tex_rect, 0)
		val_node.text  = stat_values[i]
		_get_stat_node(id, "Lbl").text  = lbl

# ─── UX Enhancements ────────────────────────────────────────────────────────
func _enhance_ux() -> void:
	# Move Logout
	var toph = $Root/TopBar/TopM/TopH
	if logout_btn.get_parent():
		logout_btn.get_parent().remove_child(logout_btn)
	toph.add_child(logout_btn)
	logout_btn.text = " Đăng Xuất"
	logout_btn.icon = load("res://assets/textures/lucide/log-out.svg") as Texture2D
	logout_btn.expand_icon = true
	logout_btn.custom_minimum_size = Vector2(130, 42)
	logout_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Current Instrument Tag
	var inst = SecureDataManager.data.get("selected_instrument", "dan_tranh")
	var inst_name = "Đàn Tranh"
	if inst == "dan_bau": inst_name = "Đàn Bầu"
	elif inst == "trong_chau": inst_name = "Trống Chầu"
	elif inst == "sao_truc": inst_name = "Sáo Trúc"
	
	var inst_hbox = HBoxContainer.new()
	inst_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	var inst_icon = TextureRect.new()
	inst_icon.texture = load("res://assets/textures/lucide/music.svg")
	inst_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	inst_icon.custom_minimum_size = Vector2(18, 18)
	inst_icon.modulate = C_JADE
	var inst_lbl = Label.new()
	inst_lbl.text = "Đang học: " + inst_name
	inst_lbl.add_theme_color_override("font_color", C_JADE)
	inst_lbl.add_theme_font_size_override("font_size", 16)
	var bevietnam_bold = load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if bevietnam_bold: inst_lbl.add_theme_font_override("font", bevietnam_bold)
	inst_hbox.add_child(inst_icon)
	inst_hbox.add_child(inst_lbl)
	
	var inst_panel = PanelContainer.new()
	inst_panel.add_child(inst_hbox)
	var ip_style = StyleBoxFlat.new()
	ip_style.bg_color = Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.15)
	ip_style.corner_radius_top_left = 16; ip_style.corner_radius_bottom_right = 16
	ip_style.corner_radius_top_right = 16; ip_style.corner_radius_bottom_left = 16
	ip_style.content_margin_left = 16; ip_style.content_margin_right = 16
	ip_style.content_margin_top = 8; ip_style.content_margin_bottom = 8
	inst_panel.add_theme_stylebox_override("panel", ip_style)
	inst_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	profile_section.add_child(inst_panel)
	profile_section.move_child(inst_panel, 1) # Below avatar
	
	# Edit Profile Button
	var edit_btn = Button.new()
	edit_btn.text = " Chỉnh Sửa Hồ Sơ"
	edit_btn.icon = load("res://assets/textures/lucide/settings.svg")
	edit_btn.expand_icon = true
	edit_btn.custom_minimum_size = Vector2(200, 48)
	edit_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var eb_style = StyleBoxFlat.new()
	eb_style.bg_color = C_GOLD
	eb_style.corner_radius_top_left = 24; eb_style.corner_radius_bottom_right = 24
	eb_style.corner_radius_top_right = 24; eb_style.corner_radius_bottom_left = 24
	edit_btn.add_theme_stylebox_override("normal", eb_style)
	var eb_hover = eb_style.duplicate()
	eb_hover.bg_color = C_JADE
	edit_btn.add_theme_stylebox_override("hover", eb_hover)
	if bevietnam_bold: edit_btn.add_theme_font_override("font", bevietnam_bold)
	edit_btn.add_theme_color_override("font_color", Color.WHITE)
	_make_btn_bouncy(edit_btn)
	_left_col.add_child(edit_btn)
	
	_name_edit = LineEdit.new()
	_name_edit.visible = false
	_name_edit.custom_minimum_size = Vector2(260, 42)
	_name_edit.text = name_lbl.text
	_name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ne_style = StyleBoxFlat.new()
	ne_style.bg_color = Color(1, 1, 1, 0.9)
	ne_style.border_width_bottom = 2; ne_style.border_color = C_JADE
	ne_style.corner_radius_top_left = 6; ne_style.corner_radius_top_right = 6
	_name_edit.add_theme_stylebox_override("normal", ne_style)
	_name_edit.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	if bevietnam_bold: _name_edit.add_theme_font_override("font", bevietnam_bold)
	
	name_lbl.get_parent().add_child(_name_edit)
	name_lbl.get_parent().move_child(_name_edit, name_lbl.get_index())
	
	var is_editing = [false]
	var save_func = func() -> void:
		if is_editing[0]:
			var new_name = _name_edit.text.strip_edges()
			if new_name != "":
				name_lbl.text = new_name
				SecureDataManager.data["user_name"] = new_name
				SecureDataManager.save_data()
			is_editing[0] = false
			_name_edit.visible = false
			name_lbl.visible = true
			edit_btn.text = " Chỉnh Sửa Hồ Sơ"
			edit_btn.icon = load("res://assets/textures/lucide/settings.svg")
			eb_style.bg_color = C_GOLD
		else:
			is_editing[0] = true
			_name_edit.text = name_lbl.text
			name_lbl.visible = false
			_name_edit.visible = true
			_name_edit.grab_focus()
			edit_btn.text = " Lưu Thay Đổi"
			edit_btn.icon = load("res://assets/textures/lucide/check-circle.svg")
			eb_style.bg_color = C_JADE
			
	edit_btn.pressed.connect(save_func)
	_name_edit.text_submitted.connect(func(_t): save_func.call())
	
	# Avatar Camera Icon Overlay
	var btn_overlay = Control.new()
	av_circle.add_child(btn_overlay)
	var pen_btn = Button.new()
	pen_btn.custom_minimum_size = Vector2(36, 36)
	pen_btn.icon = load("res://assets/textures/lucide/camera.svg")
	pen_btn.expand_icon = true
	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color(1,1,1); p_style.border_width_left = 1; p_style.border_width_top = 1
	p_style.border_width_right = 1; p_style.border_width_bottom = 1; p_style.border_color = Color(0.8,0.8,0.8)
	p_style.corner_radius_top_left = 36; p_style.corner_radius_bottom_right = 36; p_style.corner_radius_top_right = 36; p_style.corner_radius_bottom_left = 36
	p_style.shadow_size = 4; p_style.shadow_color = Color(0,0,0,0.2)
	pen_btn.add_theme_stylebox_override("normal", p_style)
	var p_hover = p_style.duplicate(); p_hover.bg_color = C_GOLD; p_hover.border_color = C_GOLD
	pen_btn.add_theme_stylebox_override("hover", p_hover)
	pen_btn.position = Vector2(96, 96) # Bottom right of avatar
	btn_overlay.add_child(pen_btn)
	_make_btn_bouncy(pen_btn)
	pen_btn.pressed.connect(func(): OS.alert("Mở hộp thoại tải ảnh từ thiết bị (FileDialog).", "Đổi Avatar"))
	
	# Add Progress Bar to G3
	var g3v = _get_stat_node("G3", "Val").get_parent()
	var prog = ProgressBar.new()
	prog.custom_minimum_size = Vector2(0, 10)
	prog.show_percentage = false
	prog.value = SecureDataManager.get_course_progress(inst)
	g3v.add_child(prog)
	
	var p_bg = StyleBoxFlat.new(); p_bg.bg_color = Color(0,0,0, 0.1); p_bg.corner_radius_top_left = 5; p_bg.corner_radius_bottom_right = 5; p_bg.corner_radius_top_right = 5; p_bg.corner_radius_bottom_left = 5
	var p_fg = StyleBoxFlat.new(); p_fg.bg_color = STAT_CARDS[2][4]; p_fg.corner_radius_top_left = 5; p_fg.corner_radius_bottom_right = 5; p_fg.corner_radius_top_right = 5; p_fg.corner_radius_bottom_left = 5
	prog.add_theme_stylebox_override("background", p_bg)
	prog.add_theme_stylebox_override("fill", p_fg)
	
	# Complete lessons label
	var num_completed = SecureDataManager.data.completed_lessons[inst].size() if SecureDataManager.data.completed_lessons.has(inst) else 0
	var msg_lbl = Label.new()
	msg_lbl.text = "Bạn đã hoàn thành %d bài học %s!" % [num_completed, inst_name]
	msg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_lbl.add_theme_color_override("font_color", C_TEXT_MUTED)
	if bevietnam_bold: msg_lbl.add_theme_font_override("font", bevietnam_bold)
	_right_col.add_child(msg_lbl)

# ─── Theme ───────────────────────────────────────────────────────────────────
func _build_theme() -> void:
	var lora_bold = load("res://assets/fonts/Lora-Bold.ttf") as Font
	var bevietnam_bold = load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	var bevietnam_reg = load("res://assets/fonts/BeVietnamPro-Regular.ttf") as Font
	if lora_bold:
		page_title.add_theme_font_override("font", lora_bold)
		name_lbl.add_theme_font_override("font", lora_bold)
	if bevietnam_bold:
		logout_btn.add_theme_font_override("font", bevietnam_bold)
		back_btn.add_theme_font_override("font", bevietnam_bold)
		for sc in STAT_CARDS:
			_get_stat_node(sc[0], "Val").add_theme_font_override("font", bevietnam_bold)
			
	var btn_sb = _flat(Color(1,1,1,0.5), Color(0,0,0,0), 24)
	btn_sb.content_margin_left = 16; btn_sb.content_margin_right = 16
	btn_sb.content_margin_top = 8; btn_sb.content_margin_bottom = 8
	var btn_hover = btn_sb.duplicate()
	btn_hover.bg_color = Color(1,1,1,0.8)
	
	back_btn.add_theme_stylebox_override("normal", btn_sb)
	back_btn.add_theme_stylebox_override("hover", btn_hover)
	back_btn.add_theme_color_override("font_color", C_JADE)
	back_btn.add_theme_color_override("font_hover_color", C_JADE)
	
	logout_btn.add_theme_stylebox_override("normal", btn_sb)
	logout_btn.add_theme_stylebox_override("hover", btn_hover)
	logout_btn.add_theme_color_override("font_color", C_RED_SON)
	logout_btn.add_theme_color_override("font_hover_color", C_RED_SON)

	if bevietnam_reg:
		email_lbl.add_theme_font_override("font", bevietnam_reg)
		ver_label.add_theme_font_override("font", bevietnam_reg)
		for sc in STAT_CARDS:
			_get_stat_node(sc[0], "Lbl").add_theme_font_override("font", bevietnam_reg)

	if bg:
		bg.texture = load("res://assets/textures/bon_nhac_cu_background.png") as Texture2D
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if bg_overlay:
		bg_overlay.color = Color(0, 0, 0, 0.2) # Hơi tối một chút để dễ đọc

	# TopBar
	var top_s : StyleBoxFlat = _flat(C_BG_BAR, Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.25), 0)
	top_s.border_width_bottom = 2
	top_s.border_width_top = 0; top_s.border_width_left = 0; top_s.border_width_right = 0
	($Root/TopBar as PanelContainer).add_theme_stylebox_override("panel", top_s)
	page_title.add_theme_color_override("font_color", C_JADE)
	
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
	$Root/TopBar.add_child(blur_rect)
	$Root/TopBar.move_child(blur_rect, 0)

	# Back button
	back_btn.add_theme_color_override("font_color", C_JADE)
	back_btn.add_theme_color_override("font_hover_color", C_GOLD)
	back_btn.add_theme_stylebox_override("normal",  _flat(Color(0,0,0,0), Color(0,0,0,0), 8))
	back_btn.add_theme_stylebox_override("hover",   _flat(Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.1), Color(0,0,0,0), 8))
	back_btn.add_theme_stylebox_override("pressed", _flat(Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.18), Color(0,0,0,0), 8))
	back_btn.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0), 0))

	# Main card (Wider for 2 columns)
	var cs : StyleBoxFlat = _flat(C_CARD, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.6), 24)
	cs.border_width_top = 2; cs.border_width_left = 2; cs.border_width_right = 2; cs.border_width_bottom = 2
	cs.shadow_size = 32; cs.shadow_color = Color(0.0, 0.0, 0.0, 0.15)
	cs.shadow_offset = Vector2(0, 12)
	card_node.add_theme_stylebox_override("panel", cs)
	
	var card_blur = blur_rect.duplicate()
	card_node.add_child(card_blur)
	card_node.move_child(card_blur, 0)

	# Avatar circle
	var av_s : StyleBoxFlat = _flat(Color(1, 1, 1, 1), C_GOLD, 64)
	av_s.border_width_left = 4; av_s.border_width_right = 4
	av_s.border_width_top  = 4; av_s.border_width_bottom = 4
	av_s.shadow_size = 16; av_s.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25)
	av_circle.add_theme_stylebox_override("panel", av_s)
	av_circle.custom_minimum_size = Vector2(136, 136)

	name_lbl.add_theme_color_override("font_color", C_TEXT)
	name_lbl.add_theme_font_size_override("font_size", 32)
	email_lbl.add_theme_color_override("font_color", C_TEXT_MUTED)

	# Stat cards
	for sc in STAT_CARDS:
		var id  : String = sc[0] as String
		var bg_c  : Color  = sc[2] as Color
		var brd : Color  = sc[3] as Color
		var nc  : PanelContainer = grid.get_node(id) as PanelContainer
		var card_s : StyleBoxFlat = _flat(bg_c, brd, 16)
		card_s.border_width_top = 2; card_s.border_width_left = 2
		card_s.border_width_right = 2; card_s.border_width_bottom = 2
		card_s.shadow_size = 8; card_s.shadow_color = Color(0, 0, 0, 0.05)
		nc.add_theme_stylebox_override("panel", card_s)
		
		var val_lbl = _get_stat_node(id, "Val")
		val_lbl.add_theme_color_override("font_color", C_TEXT)
		val_lbl.add_theme_font_size_override("font_size", 24)
		_get_stat_node(id, "Lbl").add_theme_color_override("font_color", C_TEXT_MUTED)

	# Logout button
	var lg_n : StyleBoxFlat = _flat(Color(1.0, 1.0, 1.0, 0.8), Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.5), 24)
	lg_n.border_width_left = 2; lg_n.border_width_right = 2
	lg_n.border_width_top = 2; lg_n.border_width_bottom = 2
	var lg_h : StyleBoxFlat = lg_n.duplicate() as StyleBoxFlat
	lg_h.bg_color = Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.15)
	lg_h.border_color = C_RED_SON
	logout_btn.add_theme_stylebox_override("normal",  lg_n)
	logout_btn.add_theme_stylebox_override("hover",   lg_h)
	logout_btn.add_theme_stylebox_override("pressed", _flat(Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.25), C_RED_SON, 24))
	logout_btn.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	logout_btn.add_theme_color_override("font_color",         C_TEXT)
	logout_btn.add_theme_color_override("font_hover_color",   C_RED_SON)
	logout_btn.add_theme_color_override("font_pressed_color", C_RED_SON)

	ver_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.8))

# ─── Responsive ───────────────────────────────────────────────────────────────
func _on_viewport_size_changed() -> void:
	var sz     : Vector2 = get_viewport().size
	var mobile : bool    = sz.x < sz.y or sz.x < 768.0

	_main_split.vertical = mobile
	grid.columns = 1 if mobile else 2

	var pad : int = 20 if mobile else 48
	content_m.add_theme_constant_override("margin_left",   pad)
	content_m.add_theme_constant_override("margin_right",  pad)
	content_m.add_theme_constant_override("margin_top",    24 if mobile else 36)
	content_m.add_theme_constant_override("margin_bottom", 24 if mobile else 36)

	var card_m : MarginContainer = $Root/Content/ContentV/Card/CardM as MarginContainer
	var inner_x : int = 36 if mobile else 96
	var inner_y : int = 36 if mobile else 72
	card_m.add_theme_constant_override("margin_left",   inner_x)
	card_m.add_theme_constant_override("margin_right",  inner_x)
	card_m.add_theme_constant_override("margin_top",    inner_y)
	card_m.add_theme_constant_override("margin_bottom", inner_y)

# ─── Animation ───────────────────────────────────────────────────────────────
func _animate_in() -> void:
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.30)
	var delay : float = 0.10
	for sc in STAT_CARDS:
		var node : Control = grid.get_node(sc[0] as String) as Control
		node.modulate.a = 0.0
		node.position.y += 20
		var t : Tween = create_tween().set_parallel(true)
		t.tween_property(node, "modulate:a", 1.0, 0.3).set_delay(delay)
		t.tween_property(node, "position:y", node.position.y - 20, 0.4).set_delay(delay) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		delay += 0.08

# ─── Navigation ───────────────────────────────────────────────────────────────
func _go_back() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.22)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))

func _on_logout() -> void:
	logout_btn.disabled = true
	await _api_client.logout()
	SecureDataManager.data.erase("user_id")
	SecureDataManager.data.erase("user_name")
	SecureDataManager.data.erase("user_email")
	SecureDataManager.data.erase("user_code")
	SecureDataManager.data.erase("user_role")
	SecureDataManager.save_data()
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.25)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/LoginScreen.tscn"))

# ─── Helpers ──────────────────────────────────────────────────────────────────
func _get_stat_node(id: String, child: String) -> Label:
	var path := id + "/" + id + "M/" + id + "V/" + child
	var node := grid.get_node_or_null(path)
	if node == null:
		return null
	return node as Label

func _flat(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.border_color = border
	s.border_width_left = 1; s.border_width_right = 1
	s.border_width_top  = 1; s.border_width_bottom = 1
	s.corner_radius_top_left    = radius; s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left = radius; s.corner_radius_bottom_right = radius
	return s

func _make_btn_bouncy(btn: Button) -> void:
	btn.pivot_offset = btn.size / 2.0
	btn.resized.connect(func() -> void: btn.pivot_offset = btn.size / 2.0)
	btn.mouse_entered.connect(func() -> void:
		create_tween().tween_property(btn, "scale", Vector2(1.05, 1.05), 0.12)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func() -> void:
		create_tween().tween_property(btn, "scale", Vector2.ONE, 0.12)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	btn.button_down.connect(func() -> void:
		create_tween().tween_property(btn, "scale", Vector2(0.95, 0.95), 0.08)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	btn.button_up.connect(func() -> void:
		var target := Vector2(1.05, 1.05) if btn.is_hovered() else Vector2.ONE
		create_tween().tween_property(btn, "scale", target, 0.12)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
