extends Control

# ── Colors ────────────────────────────────────────────────────────────
const C_BG        := Color("#faf8f5")
const C_GREEN     := Color("#173f2d")  # C_JADE
const C_GREEN_MID := Color("#245f43")  # C_JADE_LIGHT
const C_GOLD      := Color("#c59626")  # C_GOLD
const C_GOLD_LT   := Color("#f0cb62")  # C_GOLD_LIGHT
const C_SILVER    := Color(0.60, 0.65, 0.70, 1.0)
const C_BRONZE    := Color(0.72, 0.45, 0.20, 1.0)
const C_CREAM     := Color("#fffdf8")  # C_CARD
const C_TEXT      := Color("#21140d")  # C_TEXT
const C_TEXT_MUT  := Color("#6f6257")  # C_MUTED
const C_CARD      := Color("#fffdf8")  # C_CARD
const C_ROW_ALT   := Color(0.96, 0.94, 0.90, 0.60)
const C_ROW_ME    := Color(0.97, 0.91, 0.72, 0.80)   # highlighted "you" row

# ── State ─────────────────────────────────────────────────────────────
var instrument_id : String = "dan_tranh"
var bg_texture    : Texture2D = null
var font_bold     : Font = null
var font_regular  : Font = null

# ── Instruments for tab filter ────────────────────────────────────────
const INSTRUMENTS := [
	{"id": "dan_tranh",  "label": "Đàn Tranh"},
	{"id": "dan_bau",    "label": "Đàn Bầu"},
	{"id": "sao_truc",   "label": "Sáo Trúc"},
	{"id": "trong_chau", "label": "Trống Chầu"},
]


# ── Node refs ──────────────────────────────────────────────────────────
@onready var back_btn  : Button = $FloatingMargin/BackBtn
@onready var top_title : Label  = $Root/TitleMargin/Title

# will be populated dynamically
var _tab_btns   : Array[Button] = []
var _list_vbox  : VBoxContainer = null
var _api_client = null
var _leaderboard_list: Array = []
var _my_rank_info: Dictionary = {}

func _ready() -> void:
	if has_node("BG"):
		get_node("BG").queue_free()

	SecureDataManager.load_data()
	instrument_id = str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))

	font_bold    = load("res://assets/fonts/BeVietnamPro-Bold.ttf")
	font_regular = load("res://assets/fonts/BeVietnamPro-Regular.ttf")

	bg_texture = load("res://assets/textures/bon_nhac_cu_background.png") as Texture2D

	_api_client = preload("res://scripts/ApiClient.gd").new()
	add_child(_api_client)

	_build_topbar()
	_build_content()

	_fetch_leaderboard_data()

	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.35)

func _fetch_leaderboard_data() -> void:
	var response = await _api_client.get_top_leaderboard(100)
	if _api_client._is_success(response):
		_leaderboard_list = response.get("body", {}).get("data", [])
	else:
		print("Failed to fetch leaderboard: ", _api_client.error_message(response, "Unknown error"))
		_leaderboard_list = []

	var me_response = await _api_client.get_my_leaderboard()
	if _api_client._is_success(me_response):
		_my_rank_info = me_response.get("body", {}).get("data", {})
	else:
		_my_rank_info = {}

	_populate_list()
	
	# Rebuild content to update sticky bar
	_rebuild_all()

func _draw() -> void:
	var sz := get_rect().size
	if bg_texture:
		var tex_sz := bg_texture.get_size()
		var scale_f := maxf(sz.x / tex_sz.x, sz.y / tex_sz.y)
		var draw_sz := tex_sz * scale_f
		var draw_pos := (sz - draw_sz) / 2.0
		draw_texture_rect(bg_texture, Rect2(draw_pos, draw_sz), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, sz), C_BG)

# ──────────────────────────────────────────────────────────────────────
# TOP BAR
# ──────────────────────────────────────────────────────────────────────
func _build_topbar() -> void:
	top_title.text = " BẢNG XẾP HẠNG"
	top_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	top_title.add_theme_color_override("font_color", C_GREEN)
	if font_bold: top_title.add_theme_font_override("font", font_bold)

	var back_tex := load("res://assets/textures/lucide/arrow-left.svg") as Texture2D
	back_btn.icon = back_tex
	back_btn.text = ""
	back_btn.expand_icon = true
	back_btn.add_theme_constant_override("icon_max_width", 78)
	
	back_btn.add_theme_color_override("icon_normal_color", C_GREEN)
	back_btn.add_theme_color_override("icon_hover_color", C_GREEN.lightened(0.2))
	back_btn.add_theme_color_override("icon_pressed_color", C_GREEN.darkened(0.2))
	back_btn.add_theme_color_override("icon_focus_color", C_GREEN)
	
	var empty := _flat(Color.TRANSPARENT, Color.TRANSPARENT, 0, 0)
	back_btn.add_theme_stylebox_override("normal", empty)
	back_btn.add_theme_stylebox_override("hover", empty)
	back_btn.add_theme_stylebox_override("pressed", empty)
	back_btn.add_theme_stylebox_override("focus", empty)

	back_btn.pressed.connect(_go_back)
	_make_btn_bouncy(back_btn)

# ──────────────────────────────────────────────────────────────────────
# MAIN CONTENT  (card with tabs + podium + list)
# ──────────────────────────────────────────────────────────────────────
func _build_content() -> void:
	# Replace whatever is in GameVBox with our custom content
	var gv : VBoxContainer = $Root/Card/CardM/GameVBox
	for c in gv.get_children():
		c.queue_free()

	# Card style
	var card := $Root/Card as PanelContainer
	var cs   := _flat(Color(1.0, 0.99, 0.97, 0.7), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.28), 32)
	cs.border_width_left = 2; cs.border_width_right = 2; cs.border_width_top = 2; cs.border_width_bottom = 2
	cs.shadow_size   = 40
	cs.shadow_color  = Color(0.09, 0.25, 0.18, 0.15)
	cs.shadow_offset = Vector2(0, 10)
	card.add_theme_stylebox_override("panel", cs)

	# Add blur effect to card
	if not card.has_node("BlurRect"):
		var blur_mat := ShaderMaterial.new()
		var blur_sh  := Shader.new()
		blur_sh.code = """
		shader_type canvas_item;
		uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
		uniform float lod : hint_range(0.0,5.0) = 2.0;
		void fragment() { COLOR = textureLod(screen_texture, SCREEN_UV, lod); }
		"""
		blur_mat.shader = blur_sh
		var blur := ColorRect.new()
		blur.name = "BlurRect"
		blur.material = blur_mat
		blur.mouse_filter = Control.MOUSE_FILTER_IGNORE
		blur.show_behind_parent = true
		blur.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		card.add_child(blur)

	# ── Instrument tabs ──
	var tab_margin := MarginContainer.new()
	tab_margin.add_theme_constant_override("margin_left",  8)
	tab_margin.add_theme_constant_override("margin_right", 8)
	tab_margin.add_theme_constant_override("margin_top",   12)
	gv.add_child(tab_margin)

	var tab_hbox := HBoxContainer.new()
	tab_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_hbox.add_theme_constant_override("separation", 16)
	tab_margin.add_child(tab_hbox)

	for inst in INSTRUMENTS:
		var tb := Button.new()
		tb.text = inst["label"]
		tb.flat = false
		tb.custom_minimum_size = Vector2(100, 42)
		_style_tab(tb, inst["id"] == instrument_id)
		if font_bold: tb.add_theme_font_override("font", font_bold)
		tb.add_theme_font_size_override("font_size", 20)
		var iid : String = inst["id"]
		tb.pressed.connect(func(): _switch_instrument(iid))
		_make_btn_bouncy(tb)
		tab_hbox.add_child(tb)
		_tab_btns.append(tb)

	# ── Scroll container for podium + list ──
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	gv.add_child(scroll)

	var inner := VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 0)
	scroll.add_child(inner)

	# ── Podium (top 3) - Removed ──

	# ── List header ──
	var header_margin := MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left",  32)
	header_margin.add_theme_constant_override("margin_right", 32)
	header_margin.add_theme_constant_override("margin_top",   8)
	header_margin.add_theme_constant_override("margin_bottom", 4)
	inner.add_child(header_margin)

	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 10)
	header_margin.add_child(hdr)
	for col in [["Hạng",56, HORIZONTAL_ALIGNMENT_CENTER], ["Người chơi",0, HORIZONTAL_ALIGNMENT_LEFT], ["Chuỗi ngày",100, HORIZONTAL_ALIGNMENT_RIGHT], ["Điểm",60, HORIZONTAL_ALIGNMENT_RIGHT]]:
		if col[0] == "Điểm":
			var col_hb := HBoxContainer.new()
			col_hb.custom_minimum_size = Vector2(col[1], 0)
			col_hb.alignment = BoxContainer.ALIGNMENT_END
			var ic := TextureRect.new()
			ic.texture = load("res://assets/textures/lucide/star.svg")
			ic.custom_minimum_size = Vector2(14, 14)
			ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ic.modulate = C_TEXT_MUT
			col_hb.add_child(ic)
			var lbl := Label.new()
			lbl.text = col[0]
			lbl.add_theme_color_override("font_color", C_TEXT_MUT)
			lbl.add_theme_font_size_override("font_size", 20)
			if font_regular: lbl.add_theme_font_override("font", font_regular)
			col_hb.add_child(lbl)
			hdr.add_child(col_hb)
		else:
			var lbl := Label.new()
			lbl.text = col[0]
			if col[1] > 0: lbl.custom_minimum_size = Vector2(col[1], 0)
			elif col[1] == 0: lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lbl.horizontal_alignment = col[2]
			lbl.add_theme_color_override("font_color", C_TEXT_MUT)
			lbl.add_theme_font_size_override("font_size", 20)
			if font_regular: lbl.add_theme_font_override("font", font_regular)
			hdr.add_child(lbl)

	# thin separator
	var sep2 := ColorRect.new()
	sep2.custom_minimum_size = Vector2(0, 1)
	sep2.color = Color(C_TEXT_MUT.r, C_TEXT_MUT.g, C_TEXT_MUT.b, 0.18)
	inner.add_child(sep2)

func _populate_list() -> void:
	if _list_vbox == null:
		return
	for c in _list_vbox.get_children():
		c.queue_free()

	if _leaderboard_list.size() > 0:
		for i in range(_leaderboard_list.size()):
			var p : Dictionary = _leaderboard_list[i]
			var rk : int = int(p.get("rank", i + 1))
			var is_me := false
			if _my_rank_info.size() > 0:
				is_me = (rk == int(_my_rank_info.get("rank", -1)))
			_list_vbox.add_child(_create_list_row(p, rk, is_me))

	var bottom := Control.new()
	bottom.custom_minimum_size = Vector2(0, 16)
	_list_vbox.add_child(bottom)


func _create_list_row(p: Dictionary, rk: int, is_me: bool) -> Control:
	var row_margin := MarginContainer.new()
	row_margin.add_theme_constant_override("margin_left",  20)
	row_margin.add_theme_constant_override("margin_right", 20)
	row_margin.add_theme_constant_override("margin_top",    6)
	row_margin.add_theme_constant_override("margin_bottom", 6)

	var row_bg := PanelContainer.new()
	var rs : StyleBoxFlat
	if is_me:
		rs = _flat(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.12), C_GOLD, 16, 2)
	else:
		rs = _flat(Color(1.0, 1.0, 1.0, 0.45), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.15), 16, 1)
	row_bg.add_theme_stylebox_override("panel", rs)
	row_margin.add_child(row_bg)

	var inner := MarginContainer.new()
	inner.add_theme_constant_override("margin_left",  20)
	inner.add_theme_constant_override("margin_right", 20)
	inner.add_theme_constant_override("margin_top",    12)
	inner.add_theme_constant_override("margin_bottom", 12)
	row_bg.add_child(inner)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	inner.add_child(hbox)

	var rk_lbl := Label.new()
	rk_lbl.text = str(rk)
	rk_lbl.custom_minimum_size = Vector2(56, 0)
	rk_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rk_lbl.add_theme_color_override("font_color", C_GREEN if is_me else C_TEXT_MUT)
	rk_lbl.add_theme_font_size_override("font_size", 22)
	if font_bold: rk_lbl.add_theme_font_override("font", font_bold)
	hbox.add_child(rk_lbl)

	var mini_av := _make_mini_avatar(48, C_GREEN_MID)
	hbox.add_child(mini_av)

	var name_hbox := HBoxContainer.new()
	name_hbox.add_theme_constant_override("separation", 8)
	name_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_hbox)

	var name_lbl := Label.new()
	name_lbl.text = p.get("learner_name", p.get("name", "Ẩn danh"))
	name_lbl.add_theme_color_override("font_color", C_GREEN if is_me else C_TEXT_MUT)
	name_lbl.add_theme_font_size_override("font_size", 16)
	if font_bold and is_me:
		name_lbl.add_theme_font_override("font", font_bold)
	elif font_regular:
		name_lbl.add_theme_font_override("font", font_bold if is_me else font_regular)
	name_hbox.add_child(name_lbl)

	if is_me:
		var me_badge := Label.new()
		me_badge.text = " BẠN "
		me_badge.add_theme_color_override("font_color", C_CREAM)
		me_badge.add_theme_font_size_override("font_size", 10)
		if font_bold: me_badge.add_theme_font_override("font", font_bold)
		var me_s := _flat(C_GREEN, Color(0,0,0,0), 6)
		me_badge.add_theme_stylebox_override("normal", me_s)
		name_hbox.add_child(me_badge)

	var lv_lbl := Label.new()
	var streak : int = 0
	if p.has("current_streak"):
		streak = int(p.get("current_streak", 0))
	elif p.has("level"):
		streak = int(p.get("level", 1)) * 2
	lv_lbl.text = "%d ngày" % streak
	lv_lbl.custom_minimum_size = Vector2(100, 0)
	lv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lv_lbl.add_theme_color_override("font_color", C_TEXT_MUT)
	lv_lbl.add_theme_font_size_override("font_size", 15)
	if font_regular: lv_lbl.add_theme_font_override("font", font_regular)
	hbox.add_child(lv_lbl)

	var star_hbox := HBoxContainer.new()
	star_hbox.custom_minimum_size = Vector2(60, 0)
	star_hbox.alignment = BoxContainer.ALIGNMENT_END
	hbox.add_child(star_hbox)

	var star_ic := TextureRect.new()
	star_ic.texture = load("res://assets/textures/lucide/star.svg")
	star_ic.custom_minimum_size = Vector2(18, 18)
	star_ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star_ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	star_ic.modulate = C_GOLD
	star_hbox.add_child(star_ic)

	var star_lbl := Label.new()
	star_lbl.text = str(int(p.get("total_points", p.get("stars", 0))))
	star_lbl.add_theme_color_override("font_color", C_GOLD)
	star_lbl.add_theme_font_size_override("font_size", 16)
	if font_bold: star_lbl.add_theme_font_override("font", font_bold)
	star_hbox.add_child(star_lbl)

	return row_margin

func _build_sticky_bar() -> Control:
	if _my_rank_info.size() > 0 and _my_rank_info.get("rank", 0) > 0:
		var rk = int(_my_rank_info.get("rank", 0))
		var total_pts = int(_my_rank_info.get("total_points", 0))
		
		# Tìm thông tin người chơi hiện tại trong list (để lấy streak, tên)
		var me_name = SecureDataManager.data.get("user_name", "BẠN")
		var me_streak = 0
		for item in _leaderboard_list:
			if int(item.get("rank", 0)) == rk:
				me_name = item.get("learner_name", me_name)
				me_streak = int(item.get("current_streak", 0))
				break
				
		var p = {
			"learner_name": me_name,
			"total_points": total_pts,
			"current_streak": me_streak
		}
		
		var wrapper = PanelContainer.new()
		var s = _flat(Color(0.98, 0.97, 0.94, 0.95), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.3), 0)
		s.border_width_top = 2
		wrapper.add_theme_stylebox_override("panel", s)
		wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var row = _create_list_row(p, rk, true)
		row.add_theme_constant_override("margin_top", 12)
		row.add_theme_constant_override("margin_bottom", 12)
		wrapper.add_child(row)
		return wrapper

	return null

# ──────────────────────────────────────────────────────────────────────
# TAB SWITCH
# ──────────────────────────────────────────────────────────────────────
func _switch_instrument(iid: String) -> void:
	if iid == instrument_id:
		return
	instrument_id = iid

	# Re-style tabs
	for i in range(_tab_btns.size()):
		_style_tab(_tab_btns[i], INSTRUMENTS[i]["id"] == iid)

	# Switch background
	bg_texture = load("res://assets/textures/bon_nhac_cu_background.png") as Texture2D
	queue_redraw()

	# Rebuild list only (podium is rebuilt from scratch below)
	_rebuild_all()

func _rebuild_all() -> void:
	var gv : VBoxContainer = $Root/Card/CardM/GameVBox
	# Remove everything except the first child (tab_margin)
	var keep := 1
	var children := gv.get_children()
	for i in range(children.size()):
		if i >= keep:
			children[i].queue_free()

	# Rebuild scroll + content
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	gv.add_child(scroll)

	var inner := VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 0)
	scroll.add_child(inner)

	# _build_podium(inner) removed

	var header_margin := MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left",  32)
	header_margin.add_theme_constant_override("margin_right", 32)
	header_margin.add_theme_constant_override("margin_top",    8)
	header_margin.add_theme_constant_override("margin_bottom", 4)
	inner.add_child(header_margin)

	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 10)
	header_margin.add_child(hdr)
	for col in [["Hạng",56, HORIZONTAL_ALIGNMENT_CENTER], ["Người chơi",0, HORIZONTAL_ALIGNMENT_LEFT], ["Chuỗi ngày",100, HORIZONTAL_ALIGNMENT_RIGHT], ["Điểm",60, HORIZONTAL_ALIGNMENT_RIGHT]]:
		if col[0] == "Điểm":
			var col_hb := HBoxContainer.new()
			col_hb.custom_minimum_size = Vector2(col[1], 0)
			col_hb.alignment = BoxContainer.ALIGNMENT_END
			var ic := TextureRect.new()
			ic.texture = load("res://assets/textures/lucide/star.svg")
			ic.custom_minimum_size = Vector2(14, 14)
			ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ic.modulate = C_TEXT_MUT
			col_hb.add_child(ic)
			var lbl := Label.new()
			lbl.text = col[0]
			lbl.add_theme_color_override("font_color", C_TEXT_MUT)
			lbl.add_theme_font_size_override("font_size", 12)
			if font_regular: lbl.add_theme_font_override("font", font_regular)
			col_hb.add_child(lbl)
			hdr.add_child(col_hb)
		else:
			var lbl := Label.new()
			lbl.text = col[0]
			if col[1] > 0: lbl.custom_minimum_size = Vector2(col[1], 0)
			elif col[1] == 0: lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lbl.horizontal_alignment = col[2]
			lbl.add_theme_color_override("font_color", C_TEXT_MUT)
			lbl.add_theme_font_size_override("font_size", 12)
			if font_regular: lbl.add_theme_font_override("font", font_regular)
			hdr.add_child(lbl)

	var sep2 := ColorRect.new()
	sep2.custom_minimum_size = Vector2(0, 1)
	sep2.color = Color(C_TEXT_MUT.r, C_TEXT_MUT.g, C_TEXT_MUT.b, 0.18)
	inner.add_child(sep2)

	_list_vbox = VBoxContainer.new()
	_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_vbox.add_theme_constant_override("separation", 0)
	inner.add_child(_list_vbox)

	_populate_list()
	
	var sticky_bar := _build_sticky_bar()
	if sticky_bar: gv.add_child(sticky_bar)

# ──────────────────────────────────────────────────────────────────────
# HELPERS
# ──────────────────────────────────────────────────────────────────────
func _make_avatar_circle(size: int, col: Color) -> Control:
	var holder := PanelContainer.new()
	holder.custom_minimum_size = Vector2(size, size)
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	# 1 = CLIP_CHILDREN_ONLY
	holder.clip_children = 1

	var s := StyleBoxFlat.new()
	s.bg_color = col
	s.border_width_all = 3
	s.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.6)
	var r = int(size / 2.0)
	s.corner_radius_top_left = r
	s.corner_radius_top_right = r
	s.corner_radius_bottom_left = r
	s.corner_radius_bottom_right = r
	holder.add_theme_stylebox_override("panel", s)

	var tex_rect := TextureRect.new()
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tex_rect.texture = load("res://assets/textures/avacogiaoMai_asset.png") as Texture2D
	holder.add_child(tex_rect)
	
	return holder

func _make_mini_avatar(size: int, col: Color) -> Control:
	var holder := PanelContainer.new()
	holder.custom_minimum_size = Vector2(size, size)
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	holder.clip_children = 1

	var s := StyleBoxFlat.new()
	s.bg_color = col
	var r = int(size / 2.0)
	s.corner_radius_top_left = r
	s.corner_radius_top_right = r
	s.corner_radius_bottom_left = r
	s.corner_radius_bottom_right = r
	holder.add_theme_stylebox_override("panel", s)

	var tex_rect := TextureRect.new()
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tex_rect.texture = load("res://assets/textures/avacogiaoMai_asset.png") as Texture2D
	holder.add_child(tex_rect)
	
	return holder

func _make_level_badge(level: int, stars: int) -> CenterContainer:
	var cc := CenterContainer.new()
	var s := _flat(_get_level_bg_color(level), Color(0,0,0,0), 8)
	s.content_margin_left  = 8
	s.content_margin_right = 8
	s.content_margin_top   = 3
	s.content_margin_bottom= 3
	
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", s)
	
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	
	var lbl_lv := Label.new()
	lbl_lv.text = "Lv.%d" % level
	lbl_lv.add_theme_color_override("font_color", _get_level_text_color(level))
	lbl_lv.add_theme_font_size_override("font_size", 11)
	if font_bold: lbl_lv.add_theme_font_override("font", font_bold)
	hbox.add_child(lbl_lv)
	
	var star_ic := TextureRect.new()
	star_ic.texture = load("res://assets/textures/lucide/star.svg")
	star_ic.custom_minimum_size = Vector2(10, 10)
	star_ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star_ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	star_ic.modulate = _get_level_text_color(level)
	hbox.add_child(star_ic)
	
	var lbl_stars := Label.new()
	lbl_stars.text = str(stars)
	lbl_stars.add_theme_color_override("font_color", _get_level_text_color(level))
	lbl_stars.add_theme_font_size_override("font_size", 11)
	if font_bold: lbl_stars.add_theme_font_override("font", font_bold)
	hbox.add_child(lbl_stars)
	
	p.add_child(hbox)
	cc.add_child(p)
	return cc

func _style_tab(btn: Button, active: bool) -> void:
	var bg_n : StyleBoxFlat
	var bg_h : StyleBoxFlat
	var bg_p : StyleBoxFlat
	
	if active:
		bg_n = _flat(C_GREEN, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35), 24)
		bg_n.border_width_left = 4; bg_n.border_width_right = 4; bg_n.border_width_top = 4; bg_n.border_width_bottom = 4
		bg_h = _flat(C_GREEN.lightened(0.08), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.5), 24)
		bg_h.border_width_left = 4; bg_h.border_width_right = 4; bg_h.border_width_top = 4; bg_h.border_width_bottom = 4
		bg_p = _flat(C_GREEN.darkened(0.08), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35), 24)
		bg_p.border_width_left = 4; bg_p.border_width_right = 4; bg_p.border_width_top = 4; bg_p.border_width_bottom = 4
	else:
		bg_n = _flat(Color(1.0, 1.0, 1.0, 0.45), Color(C_GREEN.r, C_GREEN.g, C_GREEN.b, 0.55), 24)
		bg_n.border_width_left = 4; bg_n.border_width_right = 4; bg_n.border_width_top = 4; bg_n.border_width_bottom = 4
		bg_h = _flat(Color(1.0, 1.0, 1.0, 0.65), Color(C_GREEN.r, C_GREEN.g, C_GREEN.b, 0.7), 24)
		bg_h.border_width_left = 4; bg_h.border_width_right = 4; bg_h.border_width_top = 4; bg_h.border_width_bottom = 4
		bg_p = _flat(Color(1.0, 1.0, 1.0, 0.3), Color(C_GREEN.r, C_GREEN.g, C_GREEN.b, 0.55), 24)
		bg_p.border_width_left = 4; bg_p.border_width_right = 4; bg_p.border_width_top = 4; bg_p.border_width_bottom = 4
	
	bg_n.content_margin_left = 24
	bg_n.content_margin_right = 24
	bg_n.content_margin_top = 8
	bg_n.content_margin_bottom = 8
	bg_h.content_margin_left = 24; bg_h.content_margin_right = 24; bg_h.content_margin_top = 8; bg_h.content_margin_bottom = 8
	bg_p.content_margin_left = 24; bg_p.content_margin_right = 24; bg_p.content_margin_top = 8; bg_p.content_margin_bottom = 8
	
	btn.add_theme_stylebox_override("normal", bg_n)
	btn.add_theme_stylebox_override("hover", bg_h)
	btn.add_theme_stylebox_override("pressed", bg_p)
	btn.add_theme_stylebox_override("focus", _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	
	var text_c := C_CREAM if active else Color(0.43, 0.38, 0.33, 0.7)
	btn.add_theme_color_override("font_color", text_c)
	btn.add_theme_color_override("font_hover_color", C_CREAM if active else Color(0.43, 0.38, 0.33, 1.0))
	btn.add_theme_color_override("font_pressed_color", text_c)
	btn.add_theme_color_override("font_focus_color", text_c)

func _flat(bg: Color, border: Color, radius: int, bw: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left   = bw
	s.border_width_right  = bw
	s.border_width_top    = bw
	s.border_width_bottom = bw
	s.corner_radius_top_left     = radius
	s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius
	s.corner_radius_bottom_right = radius
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

func _get_rank_color(rank: int) -> Color:
	match rank:
		1: return Color(0.65, 0.42, 0.05, 1.0)  # deep gold
		2: return Color(0.42, 0.46, 0.52, 1.0)  # silver
		3: return Color(0.52, 0.28, 0.10, 1.0)  # bronze
	return C_GREEN_MID

func _get_level_bg_color(level: int) -> Color:
	match level:
		1: return Color(0.88, 0.94, 0.91, 0.90)
		2: return Color(0.80, 0.92, 0.80, 0.90)
		3: return Color(0.78, 0.90, 0.68, 0.90)
		4: return Color(0.70, 0.86, 0.55, 0.90)
		_: return Color(0.60, 0.80, 0.40, 0.90)

func _get_level_text_color(level: int) -> Color:
	match level:
		1: return Color(0.20, 0.45, 0.28, 1.0)
		2: return Color(0.12, 0.40, 0.20, 1.0)
		3: return Color(0.10, 0.35, 0.15, 1.0)
		4: return Color(0.08, 0.30, 0.10, 1.0)
		_: return C_GREEN

func _inst_label(iid: String) -> String:
	for inst in INSTRUMENTS:
		if inst["id"] == iid:
			return inst["label"]
	return iid

func _go_back() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.22)
	var back_path := "res://scenes/MainMenu.tscn"
	t.tween_callback(func(): get_tree().change_scene_to_file(back_path))
