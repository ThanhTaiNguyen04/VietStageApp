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

# ── Mock data (keyed by instrument id) ───────────────────────────────
const MOCK := {
	"dan_tranh": [
		{"name": "Nguyễn Văn A", "level": 4, "lesson": 2, "stars": 18},
		{"name": "Trần Thị B",   "level": 3, "lesson": 5, "stars": 15},
		{"name": "Lê Văn C",     "level": 3, "lesson": 1, "stars": 12},
		{"name": "Phạm D",       "level": 2, "lesson": 4, "stars":  9},
		{"name": "Hoàng E",      "level": 2, "lesson": 2, "stars":  7},
		{"name": "Vũ F",         "level": 1, "lesson": 5, "stars":  5},
		{"name": "Ngô G",        "level": 1, "lesson": 3, "stars":  3},
		{"name": "Đỗ H",         "level": 1, "lesson": 1, "stars":  1},
	],
	"dan_bau": [
		{"name": "Hoàng Thị M",  "level": 3, "lesson": 3, "stars": 13},
		{"name": "Bùi Văn N",    "level": 2, "lesson": 4, "stars": 10},
		{"name": "Đặng O",       "level": 2, "lesson": 2, "stars":  8},
		{"name": "Vũ Thị P",     "level": 1, "lesson": 5, "stars":  6},
		{"name": "Trương Q",     "level": 1, "lesson": 3, "stars":  4},
	],
	"sao_truc": [
		{"name": "Ngô Thị R",    "level": 4, "lesson": 1, "stars": 16},
		{"name": "Lý Văn S",     "level": 3, "lesson": 2, "stars": 11},
		{"name": "Mai T",        "level": 2, "lesson": 3, "stars":  8},
		{"name": "Cao U",        "level": 1, "lesson": 4, "stars":  5},
	],
	"trong_chau": [
		{"name": "Đinh Thị V",   "level": 3, "lesson": 4, "stars": 14},
		{"name": "Lưu W",        "level": 2, "lesson": 5, "stars":  9},
		{"name": "Phan X",       "level": 2, "lesson": 1, "stars":  7},
		{"name": "Tô Y",         "level": 1, "lesson": 2, "stars":  3},
	],
}

# My fake rank position for demo ("BẠN" highlight)
const MY_RANK := 5

# ── Node refs ──────────────────────────────────────────────────────────
@onready var back_btn  : Button = $Root/TopBar/TopM/TopH/BackBtn
@onready var top_title : Label  = $Root/TopBar/TopM/TopH/Title

# will be populated dynamically
var _tab_btns   : Array[Button] = []
var _list_vbox  : VBoxContainer = null

func _ready() -> void:
	if has_node("BG"):
		get_node("BG").queue_free()

	SecureDataManager.load_data()
	instrument_id = str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))

	font_bold    = load("res://assets/fonts/BeVietnamPro-Bold.ttf")
	font_regular = load("res://assets/fonts/BeVietnamPro-Regular.ttf")

	bg_texture = load("res://assets/textures/bon_nhac_cu_background.png") as Texture2D

	_build_topbar()
	_build_content()

	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.35)

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
	var top_bar = $Root/TopBar

	# Frosted glass shader
	if not top_bar.has_node("BlurRect"):
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
		blur.offset_bottom = -1
		top_bar.add_child(blur)

	var top_s := _flat(Color(1.0, 0.99, 0.97, 0.7), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.28), 0)
	top_s.border_width_bottom = 1
	top_s.content_margin_bottom = 0
	top_bar.add_theme_stylebox_override("panel", top_s)

	var spacer = $Root/TopBar/TopM/TopH/Spacer
	if spacer: spacer.hide()
	var spacer_right = $Root/TopBar/TopM/TopH/SpacerRight
	if spacer_right: spacer_right.hide()

	top_title.text = " BẢNG XẾP HẠNG"
	top_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	top_title.add_theme_color_override("font_color", C_GREEN)
	if font_bold: top_title.add_theme_font_override("font", font_bold)

	var toph := $Root/TopBar/TopM/TopH
	if toph.has_node("TitleIcon"):
		toph.get_node("TitleIcon").queue_free()

	var back_tex := load("res://assets/textures/lucide/arrow-left.svg") as Texture2D
	back_btn.icon = back_tex
	back_btn.text = ""
	back_btn.flat = true
	back_btn.custom_minimum_size = Vector2(50, 50)
	back_btn.add_theme_color_override("icon_normal_color", C_GREEN)
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
	var cs   := _flat(Color(0.95, 0.93, 0.89, 0.75), Color(0.77, 0.59, 0.15, 0.4), 32)
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
		tb.add_theme_font_size_override("font_size", 14)
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

	# ── Podium (top 3) ──
	_build_podium(inner)

	# ── List header ──
	var header_margin := MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left",  20)
	header_margin.add_theme_constant_override("margin_right", 20)
	header_margin.add_theme_constant_override("margin_top",   8)
	header_margin.add_theme_constant_override("margin_bottom", 4)
	inner.add_child(header_margin)

	var hdr := HBoxContainer.new()
	header_margin.add_child(hdr)
	for col in [["#",48], ["Người chơi",0], ["Level",-1], ["⭐ Sao",-1]]:
		var lbl := Label.new()
		lbl.text = col[0]
		if col[1] > 0:
			lbl.custom_minimum_size = Vector2(col[1], 0)
		elif col[1] == 0:
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		else:
			lbl.custom_minimum_size = Vector2(80, 0)
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl.add_theme_color_override("font_color", C_TEXT_MUT)
		lbl.add_theme_font_size_override("font_size", 12)
		if font_regular: lbl.add_theme_font_override("font", font_regular)
		hdr.add_child(lbl)

	# thin separator
	var sep2 := ColorRect.new()
	sep2.custom_minimum_size = Vector2(0, 1)
	sep2.color = Color(C_TEXT_MUT.r, C_TEXT_MUT.g, C_TEXT_MUT.b, 0.18)
	inner.add_child(sep2)

	# ── Rank list (4+) ──
	_list_vbox = VBoxContainer.new()
	_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_vbox.add_theme_constant_override("separation", 0)
	inner.add_child(_list_vbox)

	_populate_list()

# ──────────────────────────────────────────────────────────────────────
# PODIUM  (top 3 visually)
# ──────────────────────────────────────────────────────────────────────
func _build_podium(container: VBoxContainer) -> void:
	var players = MOCK.get(instrument_id, [])
	if players.size() < 3:
		return

	var pod_margin := MarginContainer.new()
	pod_margin.add_theme_constant_override("margin_left",  24)
	pod_margin.add_theme_constant_override("margin_right", 24)
	pod_margin.add_theme_constant_override("margin_top",   20)
	pod_margin.add_theme_constant_override("margin_bottom", 8)
	container.add_child(pod_margin)

	# HBox: [2nd | 1st | 3rd]
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 12)
	pod_margin.add_child(hbox)

	# Order: rank 2, rank 1, rank 3
	var order := [1, 0, 2]
	for oi in order:
		var p   : Dictionary = players[oi]
		var rk  : int = oi + 1  # 1-based
		var col := _get_rank_color(rk)

		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_END
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_theme_constant_override("separation", 6)
		hbox.add_child(vbox)

		# Crown icon for #1
		if rk == 1:
			var crown_lbl := Label.new()
			crown_lbl.text = "👑"
			crown_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			crown_lbl.add_theme_font_size_override("font_size", 28)
			vbox.add_child(crown_lbl)

		# Avatar circle
		var avatar_size := 72 if rk == 1 else 58
		var av_btn := _make_avatar_circle(avatar_size, col)
		vbox.add_child(av_btn)

		# Medal badge
		var medal_lbl := Label.new()
		medal_lbl.text = ["🥇","🥈","🥉"][rk - 1]
		medal_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		medal_lbl.add_theme_font_size_override("font_size", 22)
		vbox.add_child(medal_lbl)

		# Name
		var name_lbl := Label.new()
		name_lbl.text = p["name"]
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_color_override("font_color", C_TEXT)
		name_lbl.add_theme_font_size_override("font_size", 13 if rk == 1 else 12)
		if font_bold: name_lbl.add_theme_font_override("font", font_bold)
		name_lbl.clip_text = true
		vbox.add_child(name_lbl)

		# Level badge
		var lv_badge := _make_level_badge(p["level"], p["stars"])
		vbox.add_child(lv_badge)

		# Spacer at bottom for non-first to visually "lower" them
		if rk != 1:
			var spacer := Control.new()
			spacer.custom_minimum_size = Vector2(0, 0 if rk == 2 else 12)
			vbox.add_child(spacer)

# ──────────────────────────────────────────────────────────────────────
# RANK LIST (rows 4 and beyond)
# ──────────────────────────────────────────────────────────────────────
func _populate_list() -> void:
	if _list_vbox == null:
		return
	for c in _list_vbox.get_children():
		c.queue_free()

	var players = MOCK.get(instrument_id, [])
	var start   = 3 if players.size() > 3 else 0

	for i in range(start, players.size()):
		var p   : Dictionary = players[i]
		var rk  : int = i + 1
		var is_me := (rk == MY_RANK)

		var row_margin := MarginContainer.new()
		row_margin.add_theme_constant_override("margin_left",  20)
		row_margin.add_theme_constant_override("margin_right", 20)
		row_margin.add_theme_constant_override("margin_top",    4)
		row_margin.add_theme_constant_override("margin_bottom", 4)
		_list_vbox.add_child(row_margin)

		var row_bg := PanelContainer.new()
		var rs : StyleBoxFlat
		if is_me:
			rs = _flat(Color(C_GREEN.r, C_GREEN.g, C_GREEN.b, 0.12), Color(0, 0, 0, 0), 12)
			rs.border_width_left = 6
			rs.border_color = C_GOLD
		else:
			rs = _flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 12)
		row_bg.add_theme_stylebox_override("panel", rs)
		row_margin.add_child(row_bg)

		var inner := MarginContainer.new()
		inner.add_theme_constant_override("margin_left",  12)
		inner.add_theme_constant_override("margin_right", 12)
		inner.add_theme_constant_override("margin_top",    8)
		inner.add_theme_constant_override("margin_bottom", 8)
		row_bg.add_child(inner)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		inner.add_child(hbox)

		# Rank number
		var rk_lbl := Label.new()
		rk_lbl.text = "#" + str(rk)
		rk_lbl.custom_minimum_size = Vector2(36, 0)
		rk_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rk_lbl.add_theme_color_override("font_color", C_GREEN if is_me else C_TEXT_MUT)
		rk_lbl.add_theme_font_size_override("font_size", 14)
		if font_bold: rk_lbl.add_theme_font_override("font", font_bold)
		hbox.add_child(rk_lbl)

		# Mini avatar
		var mini_av := _make_mini_avatar(32, C_GREEN_MID)
		hbox.add_child(mini_av)

		# Name + "BẠN" badge
		var name_hbox := HBoxContainer.new()
		name_hbox.add_theme_constant_override("separation", 6)
		name_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(name_hbox)

		var name_lbl := Label.new()
		name_lbl.text = p["name"]
		name_lbl.add_theme_color_override("font_color", C_GREEN if is_me else C_TEXT_MUT)
		name_lbl.add_theme_font_size_override("font_size", 14)
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

		# Level text
		var lv_lbl := Label.new()
		lv_lbl.text = "Lv.%d · Bài %d" % [p["level"], p["lesson"]]
		lv_lbl.custom_minimum_size = Vector2(100, 0)
		lv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lv_lbl.add_theme_color_override("font_color", C_TEXT_MUT)
		lv_lbl.add_theme_font_size_override("font_size", 12)
		if font_regular: lv_lbl.add_theme_font_override("font", font_regular)
		hbox.add_child(lv_lbl)

		# Stars
		var star_lbl := Label.new()
		star_lbl.text = "⭐ " + str(p["stars"])
		star_lbl.custom_minimum_size = Vector2(60, 0)
		star_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		star_lbl.add_theme_color_override("font_color", C_GOLD)
		star_lbl.add_theme_font_size_override("font_size", 13)
		if font_bold: star_lbl.add_theme_font_override("font", font_bold)
		hbox.add_child(star_lbl)

	# Bottom padding
	var bottom := Control.new()
	bottom.custom_minimum_size = Vector2(0, 16)
	_list_vbox.add_child(bottom)

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

	_build_podium(inner)

	var header_margin := MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left",  20)
	header_margin.add_theme_constant_override("margin_right", 20)
	header_margin.add_theme_constant_override("margin_top",    8)
	header_margin.add_theme_constant_override("margin_bottom", 4)
	inner.add_child(header_margin)

	var hdr := HBoxContainer.new()
	header_margin.add_child(hdr)
	for col in [["#",48], ["Người chơi",0], ["Level",-1], ["⭐ Sao",-1]]:
		var lbl := Label.new()
		lbl.text = col[0]
		if col[1] > 0: lbl.custom_minimum_size = Vector2(col[1], 0)
		elif col[1] == 0: lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		else: lbl.custom_minimum_size = Vector2(80, 0); lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
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
	var lbl := Label.new()
	lbl.text = "Lv.%d  ⭐%d" % [level, stars]
	lbl.add_theme_color_override("font_color", _get_level_text_color(level))
	lbl.add_theme_font_size_override("font_size", 11)
	if font_bold: lbl.add_theme_font_override("font", font_bold)
	var s := _flat(_get_level_bg_color(level), Color(0,0,0,0), 8)
	s.content_margin_left  = 8
	s.content_margin_right = 8
	s.content_margin_top   = 3
	s.content_margin_bottom= 3
	lbl.add_theme_stylebox_override("normal", s)
	cc.add_child(lbl)
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
