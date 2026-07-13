extends Control

# ─── Color Palette (Traditional Vietnamese Lacquer Red & Gold - Light Cream Theme)
const C_BG_DARK     := Color(0.95, 0.93, 0.89, 1.0) # #F3EFE3 - warm cream-beige for sidebar
const C_BG_DARKER   := Color(0.98, 0.97, 0.94, 1.0) # #FAF8F5 - warm cream background
const C_BG_PANEL    := Color(0.95, 0.93, 0.89, 0.96) # sidebar/bottombar glass
const C_WAVE_COLOR  := Color(0.92, 0.88, 0.80, 0.45) # soft warm gray wave
const C_WAVE_COLOR2 := Color(0.95, 0.85, 0.60, 0.22) # soft warm gold wave
const C_CARD_BG     := Color(0.09, 0.27, 0.18, 1.0) # C_RED_SON - premium deep jade green
const C_CARD_BG_DK  := Color(0.28, 0.16, 0.10, 1.0) # deep warm brown wood
const C_CARD_LOCKED := Color(0.92, 0.90, 0.86, 0.70) # light warm gray-cream
const C_PRIMARY     := Color(0.753, 0.329, 0.102, 1.0)
const C_PRIMARY_LT  := Color(0.831, 0.388, 0.122, 1.0)
const C_PRIMARY_DK  := Color(0.620, 0.247, 0.063, 1.0)
const C_GOLD_GLOW   := Color(0.77, 0.58, 0.15, 1.0) # C_GOLD - glowing gold progress ring
const C_PATH_LINE   := Color(0.77, 0.58, 0.15, 0.80) # gold path line
const C_PATH_SHADOW := Color(0.90, 0.86, 0.78, 0.40) # soft gold/beige shadow
const C_RED_SON     := Color(0.09, 0.27, 0.18, 1.0)
const C_RED_DK      := Color(0.05, 0.16, 0.11, 0.96)
const C_GOLD        := Color(0.77, 0.58, 0.15, 1.0)
const C_GOLD_LIGHT  := Color(0.92, 0.76, 0.30, 1.0)
const C_GOLD_DARK   := Color(0.55, 0.40, 0.08, 1.0)
const C_CREAM       := Color(1.00, 0.97, 0.88, 1.0)
const C_CREAM_DIM   := Color(0.80, 0.76, 0.66, 1.0)
const C_TEXT_DIS    := Color(0.353, 0.290, 0.220, 1.0)

var _active_side_btn : Button = null
var _time : float = 0.0
var _sidebar_icons_cache := {}
var btn_minigame : Button
var btn_minigame_mob : Button
const LESSON_DAN_BAU_SCRIPT = preload("res://scripts/LessonDanBau.gd")

# ─── @onready refs ─────────────────────────────────────────────────────────────
@onready var bg_canvas     : Control        = $BackgroundCanvas
@onready var sidebar       : PanelContainer = $Root/Sidebar
@onready var btn_menu      : Button         = $Root/Sidebar/SideM/SideV/BtnMenu
@onready var btn_courses   : Button         = $Root/Sidebar/SideM/SideV/BtnCourses
@onready var btn_room      : Button         = $Root/Sidebar/SideM/SideV/BtnRoom
@onready var btn_songs     : Button         = $Root/Sidebar/SideM/SideV/BtnSongs
@onready var btn_account   : Button         = $Root/Sidebar/SideM/SideV/BtnAccount

@onready var bottom_bar      : PanelContainer = $Root/RightContent/BottomBar
@onready var btn_courses_mob : Button         = $Root/RightContent/BottomBar/BottomM/BottomH/BtnCoursesMobile
@onready var btn_room_mob    : Button         = $Root/RightContent/BottomBar/BottomM/BottomH/BtnRoomMobile
@onready var btn_songs_mob   : Button         = $Root/RightContent/BottomBar/BottomM/BottomH/BtnSongsMobile
@onready var btn_account_mob : Button         = $Root/RightContent/BottomBar/BottomM/BottomH/BtnAccountMobile

@onready var top_bar       : MarginContainer = $Root/RightContent/TopBar
@onready var avatar_circle : PanelContainer  = $Root/RightContent/TopBar/TopRow/AvatarCircle

@onready var streak_pill   : PanelContainer  = $Root/RightContent/TopBar/TopRow/StatsRow/StreakPill
@onready var sp_label      : Label           = $Root/RightContent/TopBar/TopRow/StatsRow/StreakPill/SPMargin/SPLabel
@onready var xp_pill       : PanelContainer  = $Root/RightContent/TopBar/TopRow/StatsRow/XPPill
@onready var xp_label      : Label           = $Root/RightContent/TopBar/TopRow/StatsRow/XPPill/XPMargin/XPLabel

@onready var roadmap_scroll : ScrollContainer = $Root/RightContent/RoadmapScroll
@onready var roadmap_content: Control         = $Root/RightContent/RoadmapScroll/RoadmapContent

# Roadmap Text Labels
@onready var roadmap_guide     : Label = $Root/RightContent/RoadmapScroll/RoadmapContent/RoadmapGuide
@onready var path_soloist_title: Label = $Root/RightContent/RoadmapScroll/RoadmapContent/PathSoloistTitle
@onready var path_chords_title : Label = $Root/RightContent/RoadmapScroll/RoadmapContent/PathChordsTitle

# Roadmap Cards
@onready var card_basic    : PanelContainer = $Root/RightContent/RoadmapScroll/RoadmapContent/CardBasic
@onready var card_essentials: PanelContainer = $Root/RightContent/RoadmapScroll/RoadmapContent/CardEssentials
@onready var card_soloist_unlock: PanelContainer = $Root/RightContent/RoadmapScroll/RoadmapContent/CardSoloistUnlock
@onready var card_chords_unlock: PanelContainer = $Root/RightContent/RoadmapScroll/RoadmapContent/CardChordsUnlock
@onready var card_soloist_skills: PanelContainer = $Root/RightContent/RoadmapScroll/RoadmapContent/CardSoloistSkills
@onready var card_chords_skills: PanelContainer = $Root/RightContent/RoadmapScroll/RoadmapContent/CardChordsSkills
@onready var card_classical : PanelContainer = $Root/RightContent/RoadmapScroll/RoadmapContent/CardClassical
@onready var card_pop_chords: PanelContainer = $Root/RightContent/RoadmapScroll/RoadmapContent/CardPopChords

# ─── Ready ─────────────────────────────────────────────────────────────────────
var card_adv_tech: PanelContainer
var card_pro_perf: PanelContainer
var card_mastery1: PanelContainer
var card_mastery2: PanelContainer
var _is_dragging_roadmap := false
var _drag_start_pos := Vector2()
var _scroll_start_x := 0

func _ready() -> void:
	SecureDataManager.load_data()
	InstrumentSelect.selected_instrument = SecureDataManager.data.get("selected_instrument", "dan_tranh")
	
	# Programmatic instantiation of MiniGame button
	var side_v := $Root/Sidebar/SideM/SideV as VBoxContainer
	btn_minigame = Button.new()
	btn_minigame.name = "BtnMiniGame"
	btn_minigame.text = "Mini-game"
	btn_minigame.flat = true
	btn_minigame.custom_minimum_size = Vector2(220, 140)
	side_v.add_child(btn_minigame)
	side_v.move_child(btn_minigame, 5) # after BtnSongs (index 4)

	var bottom_h := $Root/RightContent/BottomBar/BottomM/BottomH as HBoxContainer
	btn_minigame_mob = Button.new()
	btn_minigame_mob.name = "BtnMiniGameMobile"
	btn_minigame_mob.text = "Mini-game"
	btn_minigame_mob.flat = true
	btn_minigame_mob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_h.add_child(btn_minigame_mob)
	bottom_h.move_child(btn_minigame_mob, 3) # after BtnSongsMobile (index 2)
	
	_build_sidebar()
	_build_bottom_bar()
	_build_top_bar()
	_build_roadmap_cards()
	_connect_buttons()
	_setup_drawing_callbacks()
	_animate_in()
	
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.38)

	get_viewport().size_changed.connect(_on_viewport_size_changed)
	# roadmap_scroll.gui_input.connect(_on_roadmap_scroll_gui_input)
	_on_viewport_size_changed()

	avatar_circle.hide()

func _process(delta: float) -> void:
	_time += delta
	bg_canvas.queue_redraw()
	roadmap_content.queue_redraw()

# ─── Drawing Callbacks ────────────────────────────────────────────────────────
func _setup_drawing_callbacks() -> void:
	# Background curves
	bg_canvas.draw.connect(_draw_background_waves)
	bg_canvas.queue_redraw()
	
	# Roadmap curves + clouds + stars
	roadmap_content.draw.connect(_draw_roadmap_paths)
	roadmap_content.queue_redraw()
	
	# Card Basic Progress Ring in Gold
	var vis_basic := card_basic.get_node("Margin/Row/Visual") as Control
	vis_basic.draw.connect(func() -> void:
		var cx := vis_basic.size.x / 2.0
		var cy := vis_basic.size.y / 2.0
		var r := 34.0
		var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
		var is_completed = SecureDataManager.is_lesson_completed(inst, "Node1")
		var pct = 1.0 if is_completed else 0.0
		var pct_str = "100%" if is_completed else "0%"
		
		# Gray outer ring
		vis_basic.draw_arc(Vector2(cx, cy), r, 0, TAU, 32, Color(1.0, 1.0, 1.0, 0.12), 7.0, true)
		# Gold progress ring
		if pct > 0:
			vis_basic.draw_arc(Vector2(cx, cy), r, -PI/2, -PI/2 + pct * TAU, 32, C_GOLD_GLOW, 7.0, true)
		# Draw percentage text in the center
		var font := vis_basic.get_theme_font("font")
		vis_basic.draw_string(font, Vector2(cx - 22 if is_completed else cx - 12, cy + 6), pct_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 18, C_CREAM)
	)
	
	# Card Essentials Graphic
	var vis_essentials := card_essentials.get_node("Margin/Row/Visual") as Control
	vis_essentials.draw.connect(func() -> void:
		var cx := vis_essentials.size.x / 2.0
		var cy := vis_essentials.size.y / 2.0
		var r := 34.0
		vis_essentials.draw_arc(Vector2(cx, cy), r, 0, TAU, 32, Color(1.0, 1.0, 1.0, 0.12), 7.0, true)
		# Draw traditional flute/Sao Truc
		vis_essentials.draw_line(Vector2(cx - 24, cy + 12), Vector2(cx + 24, cy - 12), C_GOLD, 4.0, true)
		vis_essentials.draw_circle(Vector2(cx - 12, cy + 6), 3.0, C_CARD_BG_DK)
		vis_essentials.draw_circle(Vector2(cx, cy), 3.0, C_CARD_BG_DK)
		vis_essentials.draw_circle(Vector2(cx + 12, cy - 6), 3.0, C_CARD_BG_DK)
	)
	
	# Lock Icons on Locked Cards
	var lock_soloist := card_soloist_unlock.get_node("Margin/VBox/LockedIcon") as Control
	lock_soloist.draw.connect(func() -> void: _draw_lock_icon(lock_soloist))
	
	var lock_chords := card_chords_unlock.get_node("Margin/VBox/LockedIcon") as Control
	lock_chords.draw.connect(func() -> void: _draw_lock_icon(lock_chords))

func _draw_lock_icon(c: Control) -> void:
	var lock_tex : Texture2D = null
	if _sidebar_icons_cache.has("lock"):
		lock_tex = _sidebar_icons_cache["lock"]
	else:
		lock_tex = load("res://assets/textures/icons8/lock.png") as Texture2D
		_sidebar_icons_cache["lock"] = lock_tex

	if lock_tex:
		var sz := c.size
		var cx := sz.x * 0.5
		var cy := sz.y * 0.5
		c.draw_texture_rect(lock_tex, Rect2(cx - 16, cy - 16, 32, 32), false, C_CREAM_DIM)

func _draw_background_waves() -> void:
	var sz := bg_canvas.size
	
	# ── Base: dark mahogany fill ──────────────────────────────────────────────
	bg_canvas.draw_rect(Rect2(Vector2.ZERO, sz), C_BG_DARK)
	
	# ── Radial warm glow from top-right (ambient lantern light) ───────────────
	var glow_cx := sz.x * 0.75; var glow_cy := sz.y * 0.12
	for i in range(6):
		var r := sz.x * (0.65 - i * 0.08)
		var a := 0.028 - i * 0.003
		bg_canvas.draw_circle(Vector2(glow_cx, glow_cy), r,
			Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, a))
	
	# ── Terracotta Wave 1 — lower sweep (animated) ───────────────────────────
	var w1_pts := PackedVector2Array()
	var w1_start := Vector2(0, sz.y * 0.55 + sin(_time * 0.55) * 14.0)
	var w1_ctrl1 := Vector2(sz.x * 0.30, sz.y * 0.80 + cos(_time * 0.45) * 18.0)
	var w1_ctrl2 := Vector2(sz.x * 0.65, sz.y * 0.48 + sin(_time * 0.50) * 14.0)
	var w1_end   := Vector2(sz.x, sz.y * 0.70 + cos(_time * 0.60) * 12.0)
	for i in range(32):
		var t := i / 31.0
		w1_pts.append(w1_start.bezier_interpolate(w1_ctrl1, w1_ctrl2, w1_end, t))
	w1_pts.append(Vector2(sz.x, sz.y))
	w1_pts.append(Vector2(0, sz.y))
	bg_canvas.draw_colored_polygon(w1_pts, C_WAVE_COLOR)
	
	# ── Amber Wave 2 — upper sweep (animated) ────────────────────────────────
	var w2_pts := PackedVector2Array()
	var w2_start := Vector2(0, sz.y * 0.18 + cos(_time * 0.42) * 10.0)
	var w2_ctrl1 := Vector2(sz.x * 0.28, sz.y * 0.38 + sin(_time * 0.52) * 14.0)
	var w2_ctrl2 := Vector2(sz.x * 0.62, sz.y * 0.08 + cos(_time * 0.38) * 10.0)
	var w2_end   := Vector2(sz.x, sz.y * 0.28 + sin(_time * 0.48) * 10.0)
	for i in range(32):
		var t := i / 31.0
		w2_pts.append(w2_start.bezier_interpolate(w2_ctrl1, w2_ctrl2, w2_end, t))
	w2_pts.append(Vector2(sz.x, sz.y))
	w2_pts.append(Vector2(0, sz.y))
	bg_canvas.draw_colored_polygon(w2_pts, C_WAVE_COLOR2)
	
	# ── Walnut mid tone bottom gradient ──────────────────────────────────────
	for i in range(8):
		var t := float(i) / 7.0
		var y := sz.y * (0.75 + t * 0.25)
		bg_canvas.draw_rect(Rect2(0, y, sz.x, sz.y / 7.0),
			Color(C_BG_DARKER.r, C_BG_DARKER.g, C_BG_DARKER.b, t * 0.55))

func _draw_roadmap_paths() -> void:
	# Draw gorgeous traditional cloud designs and star particles under paths
	_draw_traditional_cloud(roadmap_content, Vector2(320 + sin(_time * 0.2) * 15.0, 130), 55.0)
	_draw_traditional_cloud(roadmap_content, Vector2(850 + cos(_time * 0.15) * 12.0, 630), 45.0)
	_draw_traditional_cloud(roadmap_content, Vector2(1620 + sin(_time * 0.25) * 15.0, 120), 50.0)
	_draw_traditional_cloud(roadmap_content, Vector2(2150 + cos(_time * 0.18) * 18.0, 620), 55.0)
	
	# Glowing Gold Stars
	var star_positions := [
		Vector2(160, 130), Vector2(280, 620), Vector2(620, 120), Vector2(980, 640),
		Vector2(1210, 380), Vector2(1480, 120), Vector2(1780, 640), Vector2(2080, 120)
	]
	for i in range(star_positions.size()):
		_draw_gold_star(roadmap_content, star_positions[i], i)

	# Compute centers dynamically
	var p_basic := card_basic.position + card_basic.size / 2.0
	var p_ess := card_essentials.position + card_essentials.size / 2.0
	var p_sol_un := card_soloist_unlock.position + card_soloist_unlock.size / 2.0
	var p_cho_un := card_chords_unlock.position + card_chords_unlock.size / 2.0
	var p_sol_sk := card_soloist_skills.position + card_soloist_skills.size / 2.0
	var p_cho_sk := card_chords_skills.position + card_chords_skills.size / 2.0
	var p_class := card_classical.position + card_classical.size / 2.0
	var p_pop := card_pop_chords.position + card_pop_chords.size / 2.0
		
	# Draw roadmap line segments connecting cards
	# Basic Card -> Essentials Card -> Split point
	_draw_thick_path(p_basic, p_ess)
	
	# Essentials split into Soloist and Chords paths
	_draw_curved_path(p_ess, p_sol_un)
	_draw_curved_path(p_ess, p_cho_un)
	
	# Top Path (Soloist): SoloistUnlock -> SoloistSkills -> Classical
	_draw_thick_path(p_sol_un, p_sol_sk)
	_draw_thick_path(p_sol_sk, p_class)
	if card_adv_tech and card_adv_tech.visible:
		_draw_thick_path(p_class, card_adv_tech.position + card_adv_tech.size/2.0)
		_draw_thick_path(card_adv_tech.position + card_adv_tech.size/2.0, card_pro_perf.position + card_pro_perf.size/2.0)
	if card_mastery1 and card_mastery1.visible:
		_draw_thick_path(card_pro_perf.position + card_pro_perf.size/2.0, card_mastery1.position + card_mastery1.size/2.0)
		_draw_thick_path(card_mastery1.position + card_mastery1.size/2.0, card_mastery2.position + card_mastery2.size/2.0)
	
	# Bottom Path (Chords): ChordsUnlock -> ChordsSkills -> PopChords
	_draw_thick_path(p_cho_un, p_cho_sk)
	_draw_thick_path(p_cho_sk, p_pop)

func _draw_thick_path(from: Vector2, to: Vector2) -> void:
	roadmap_content.draw_line(from + Vector2(0, 3), to + Vector2(0, 3), C_PATH_SHADOW, 10.0, true)
	roadmap_content.draw_line(from, to, C_PATH_LINE, 6.0, true)

func _draw_curved_path(from: Vector2, to: Vector2) -> void:
	var ctrl1 := Vector2(from.x + (to.x - from.x) * 0.4, from.y)
	var ctrl2 := Vector2(from.x + (to.x - from.x) * 0.6, to.y)
	
	var shadow_pts := PackedVector2Array()
	var line_pts := PackedVector2Array()
	
	for i in range(20):
		var t := i / 19.0
		var p := from.bezier_interpolate(ctrl1, ctrl2, to, t)
		shadow_pts.append(p + Vector2(0, 3))
		line_pts.append(p)
		
	roadmap_content.draw_polyline(shadow_pts, C_PATH_SHADOW, 10.0, true)
	roadmap_content.draw_polyline(line_pts, C_PATH_LINE, 6.0, true)

func _draw_gold_star(c: Control, pos: Vector2, idx: int) -> void:
	var shimmer := 0.20 + 0.22 * sin(_time * 2.2 + idx * 0.9)
	var col := Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, shimmer)
	# 4-pointed traditional star
	var pts := PackedVector2Array([
		pos + Vector2(0, -9),
		pos + Vector2(3, -3),
		pos + Vector2(9, 0),
		pos + Vector2(3, 3),
		pos + Vector2(0, 9),
		pos + Vector2(-3, 3),
		pos + Vector2(-9, 0),
		pos + Vector2(-3, -3)
	])
	c.draw_colored_polygon(pts, col)

func _draw_traditional_cloud(c: Control, pos: Vector2, size: float) -> void:
	var col := Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.11)
	c.draw_circle(pos, size * 0.6, col)
	c.draw_circle(pos + Vector2(size * 0.5, -size * 0.1), size * 0.45, col)
	c.draw_circle(pos - Vector2(size * 0.5, -size * 0.1), size * 0.45, col)
	c.draw_circle(pos + Vector2(size * 0.9, size * 0.15), size * 0.3, col)
	c.draw_circle(pos - Vector2(size * 0.9, size * 0.15), size * 0.3, col)

# ─── Sidebar ───────────────────────────────────────────────────────────────────
func _build_sidebar() -> void:
	# Dark glass panel — deep mahogany with subtle gold right border
	var side_s := _flat(C_BG_PANEL, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.30), 0)
	side_s.border_width_left = 0; side_s.border_width_top = 0; side_s.border_width_bottom = 0
	side_s.border_width_right = 2
	side_s.shadow_size = 24
	side_s.shadow_color = Color(0, 0, 0, 0.45)
	side_s.shadow_offset = Vector2(8, 0)
	sidebar.add_theme_stylebox_override("panel", side_s)

func _build_bottom_bar() -> void:
	# Dark glass panel — deep mahogany with gold top border
	var bottom_s := _flat(C_BG_PANEL, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.30), 0)
	bottom_s.border_width_left = 0; bottom_s.border_width_right = 0; bottom_s.border_width_bottom = 0
	bottom_s.border_width_top = 2
	bottom_s.shadow_size = 24
	bottom_s.shadow_color = Color(0, 0, 0, 0.45)
	bottom_s.shadow_offset = Vector2(0, -8)
	bottom_bar.add_theme_stylebox_override("panel", bottom_s)

	_style_bottom_icon_btn(btn_courses_mob, true)
	_style_bottom_icon_btn(btn_room_mob,    false)
	_style_bottom_icon_btn(btn_songs_mob,   false)
	_style_bottom_icon_btn(btn_account_mob, false)
	_style_bottom_icon_btn(btn_minigame_mob, false)

	_attach_bottom_icon_draw(btn_courses_mob, 1)
	_attach_bottom_icon_draw(btn_room_mob,    6)
	_attach_bottom_icon_draw(btn_songs_mob,   2)
	_attach_bottom_icon_draw(btn_account_mob, 5)
	_attach_bottom_icon_draw(btn_minigame_mob, 3)

func _style_bottom_icon_btn(btn: Button, is_active: bool, is_locked: bool = false) -> void:
	# Active tab: gold top border + warm ivory text; inactive: muted sand
	var active_bg := _flat(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.10), Color(0, 0, 0, 0), 12)
	var normal_bg := _flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 12)
	var bg_n := active_bg if is_active else normal_bg
	var bg_h := _flat(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.08) if not is_locked else Color(0, 0, 0, 0), Color(0, 0, 0, 0), 12)
	var bg_p := _flat(Color(C_PRIMARY.r, C_PRIMARY.g, C_PRIMARY.b, 0.15) if not is_locked else Color(0, 0, 0, 0), Color(0, 0, 0, 0), 12)

	bg_n.content_margin_top = 42
	bg_n.content_margin_bottom = 6
	bg_h.content_margin_top = 42
	bg_h.content_margin_bottom = 6
	bg_p.content_margin_top = 42
	bg_p.content_margin_bottom = 6

	if is_active:
		# Gold indicator at top of active tab
		bg_n.border_width_top = 3
		bg_n.border_width_left = 0; bg_n.border_width_right = 0; bg_n.border_width_bottom = 0
		bg_n.border_color = C_GOLD

	btn.add_theme_stylebox_override("normal",  bg_n)
	btn.add_theme_stylebox_override("hover",   bg_h)
	btn.add_theme_stylebox_override("pressed", bg_p)
	btn.add_theme_stylebox_override("focus",   _flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))
	# Active = warm ivory; locked = very dim; normal = muted sand
	var fc_normal := C_CREAM if is_active else (Color(C_CREAM_DIM.r, C_CREAM_DIM.g, C_CREAM_DIM.b, 0.35) if is_locked else C_CREAM_DIM)
	btn.add_theme_color_override("font_color",         fc_normal)
	btn.add_theme_color_override("font_hover_color",   C_CREAM if not is_locked else Color(C_CREAM_DIM.r, C_CREAM_DIM.g, C_CREAM_DIM.b, 0.35))
	btn.add_theme_color_override("font_pressed_color", C_GOLD if not is_locked else Color(C_CREAM_DIM.r, C_CREAM_DIM.g, C_CREAM_DIM.b, 0.35))
	btn.add_theme_font_size_override("font_size", 14)

func _attach_bottom_icon_draw(btn: Button, icon_type: int, is_locked: bool = false) -> void:
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

	_active_side_btn = btn_courses

func _style_side_icon_btn(btn: Button, is_active: bool, is_locked: bool = false) -> void:
	# Active sidebar btn: gold left border + warm ivory text + subtle gold bg tint
	var active_bg := _flat(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.10), Color(0, 0, 0, 0), 18)
	var normal_bg := _flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 18)
	var bg_n := active_bg if is_active else normal_bg
	var bg_h := _flat(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.07) if not is_locked else Color(0, 0, 0, 0), Color(0, 0, 0, 0), 18)
	var bg_p := _flat(Color(C_PRIMARY.r, C_PRIMARY.g, C_PRIMARY.b, 0.18) if not is_locked else Color(0, 0, 0, 0), Color(0, 0, 0, 0), 18)

	bg_n.content_margin_top = 96
	bg_n.content_margin_bottom = 8
	bg_h.content_margin_top = 96
	bg_h.content_margin_bottom = 8
	bg_p.content_margin_top = 96
	bg_p.content_margin_bottom = 8

	if is_active:
		# Gold left accent bar
		bg_n.border_width_left = 5
		bg_n.border_width_right = 0; bg_n.border_width_top = 0; bg_n.border_width_bottom = 0
		bg_n.border_color = C_GOLD

	btn.add_theme_stylebox_override("normal",  bg_n)
	btn.add_theme_stylebox_override("hover",   bg_h)
	btn.add_theme_stylebox_override("pressed", bg_p)
	btn.add_theme_stylebox_override("focus",   _flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))
	var fc_s := C_GOLD if is_active else (Color(C_CREAM_DIM.r, C_CREAM_DIM.g, C_CREAM_DIM.b, 0.30) if is_locked else C_CREAM_DIM)
	btn.add_theme_color_override("font_color",         fc_s)
	btn.add_theme_color_override("font_hover_color",   C_CREAM if not is_locked else Color(C_CREAM_DIM.r, C_CREAM_DIM.g, C_CREAM_DIM.b, 0.30))
	btn.add_theme_color_override("font_pressed_color", C_GOLD if not is_locked else Color(C_CREAM_DIM.r, C_CREAM_DIM.g, C_CREAM_DIM.b, 0.30))
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
			c.draw_texture_rect(lock_tex, Rect2(lx - 6, ly - 6, 12, 12), false, C_GOLD)

# ─── Top Bar ──────────────────────────────────────────────────────────────────
func _build_top_bar() -> void:
	# Avatar: dark glass circle with gold border + glow
	var av_s := StyleBoxFlat.new()
	av_s.bg_color              = C_BG_PANEL
	av_s.border_color          = C_GOLD
	av_s.border_width_left     = 3; av_s.border_width_right  = 3
	av_s.border_width_top      = 3; av_s.border_width_bottom = 3
	av_s.corner_radius_top_left     = 34; av_s.corner_radius_top_right    = 34
	av_s.corner_radius_bottom_left  = 34; av_s.corner_radius_bottom_right = 34
	av_s.shadow_size   = 14
	av_s.shadow_color  = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35)
	av_s.shadow_offset = Vector2(0, 2)
	avatar_circle.add_theme_stylebox_override("panel", av_s)

	# Gold glow ring around avatar
	var ring_draw := Control.new()
	ring_draw.name = "RingDraw"
	ring_draw.set_anchors_preset(Control.PRESET_FULL_RECT)
	ring_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring_draw.draw.connect(func() -> void:
		var sz := ring_draw.size
		var c  := sz / 2.0
		var r  := minf(c.x, c.y) - 3.0
		# Outer gold ring
		ring_draw.draw_arc(c, r, 0, TAU, 64, C_GOLD, 2.5, true)
		# Soft inner glow
		ring_draw.draw_arc(c, r - 2.0, 0, TAU, 64, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.30), 5.0, true)
	)
	avatar_circle.add_child(ring_draw)

	# Streak pill — dark glass, warm orange border, amber text
	var sp_s := _flat(C_BG_PANEL, Color(0.961, 0.651, 0.137, 0.55), 22)
	sp_s.shadow_size = 8; sp_s.shadow_color = Color(0.961, 0.651, 0.137, 0.18)
	streak_pill.add_theme_stylebox_override("panel", sp_s)
	sp_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.24, 1.0))
	sp_label.text = "🔥 " + str(SecureDataManager.data.daily_streak) + " ngày"

	# XP pill — dark glass, gold border, gold text
	var xp_s := _flat(C_BG_PANEL, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.55), 22)
	xp_s.shadow_size = 8; xp_s.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.22)
	xp_pill.add_theme_stylebox_override("panel", xp_s)
	xp_label.add_theme_color_override("font_color", C_GOLD)
	var total_xp : int = 1240 + int(SecureDataManager.data.practice_time_seconds) / 6
	xp_label.text = "⭐ " + str(total_xp) + " XP"

# ─── Roadmap Cards styling ───────────────────────────────────────────────────
func _build_roadmap_cards() -> void:
	var instrument := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
	var is_tranh := (instrument == "dan_tranh")
	
	# Main labels styling
	var font_title := load("res://assets/fonts/Lora-Bold.ttf")
	if font_title:
		roadmap_guide.add_theme_font_override("font", font_title)
		path_soloist_title.add_theme_font_override("font", font_title)
		path_chords_title.add_theme_font_override("font", font_title)
		
	roadmap_guide.add_theme_color_override("font_color", Color(0.13, 0.08, 0.05, 1.0))
	path_soloist_title.add_theme_color_override("font_color", C_RED_SON)
	path_chords_title.add_theme_color_override("font_color", C_RED_SON)
	
	# Cards references
	var basic_title := card_basic.get_node("Margin/Row/TextV/Title") as Label
	var basic_desc := card_basic.get_node("Margin/Row/TextV/Desc") as Label
	var basic_details := card_basic.get_node("Margin/Row/TextV/Details") as Label
	
	var ess_title := card_essentials.get_node("Margin/Row/TextV/Title") as Label
	var ess_desc := card_essentials.get_node("Margin/Row/TextV/Desc") as Label
	var ess_details := card_essentials.get_node("Margin/Row/TextV/Details") as Label
	
	var soloist_unlock_title := card_soloist_unlock.get_node("Margin/VBox/Title") as Label
	var chords_unlock_title := card_chords_unlock.get_node("Margin/VBox/Title") as Label
	
	var soloist_skills_title := card_soloist_skills.get_node("Margin/HBox/TextV/Title") as Label
	var soloist_skills_bullets := card_soloist_skills.get_node("Margin/HBox/TextV/BulletList") as Label
	
	var chords_skills_title := card_chords_skills.get_node("Margin/HBox/TextV/Title") as Label
	var chords_skills_bullets := card_chords_skills.get_node("Margin/HBox/TextV/BulletList") as Label
	
	var classical_title := card_classical.get_node("Margin/HBox/TextV/Title") as Label
	var classical_desc := card_classical.get_node("Margin/HBox/TextV/BulletList") as Label
	
	var pop_chords_title := card_pop_chords.get_node("Margin/HBox/TextV/Title") as Label
	var pop_chords_desc := card_pop_chords.get_node("Margin/HBox/TextV/BulletList") as Label

	if not card_adv_tech:
		card_adv_tech = card_classical.duplicate()
		roadmap_content.add_child(card_adv_tech)
		card_adv_tech.position = Vector2(2460, 95)
		roadmap_content.custom_minimum_size.x = 6000
		roadmap_content.size.x = 6000
		roadmap_content.set_anchors_preset(Control.PRESET_TOP_LEFT)
	
	if not card_pro_perf:
		card_pro_perf = card_classical.duplicate()
		roadmap_content.add_child(card_pro_perf)
		card_pro_perf.position = Vector2(2990, 95)
		
	if not card_mastery1:
		card_mastery1 = card_classical.duplicate()
		roadmap_content.add_child(card_mastery1)
		card_mastery1.position = Vector2(3520, 95)
		
	if not card_mastery2:
		card_mastery2 = card_classical.duplicate()
		roadmap_content.add_child(card_mastery2)
		card_mastery2.position = Vector2(4050, 95)
		
	var adv_title := card_adv_tech.get_node("Margin/HBox/TextV/Title") as Label
	var adv_desc := card_adv_tech.get_node("Margin/HBox/TextV/BulletList") as Label
	var adv_btn := card_adv_tech.get_node("Margin/HBox/BtnPlay") as Button
	
	var pro_title := card_pro_perf.get_node("Margin/HBox/TextV/Title") as Label
	var pro_desc := card_pro_perf.get_node("Margin/HBox/TextV/BulletList") as Label
	var pro_btn := card_pro_perf.get_node("Margin/HBox/BtnPlay") as Button
	
	var m1_title := card_mastery1.get_node("Margin/HBox/TextV/Title") as Label
	var m1_desc := card_mastery1.get_node("Margin/HBox/TextV/BulletList") as Label
	var m1_btn := card_mastery1.get_node("Margin/HBox/BtnPlay") as Button
	
	var m2_title := card_mastery2.get_node("Margin/HBox/TextV/Title") as Label
	var m2_desc := card_mastery2.get_node("Margin/HBox/TextV/BulletList") as Label
	var m2_btn := card_mastery2.get_node("Margin/HBox/BtnPlay") as Button


	if instrument == "dan_tranh":
		card_adv_tech.hide()
		card_pro_perf.hide()
		card_mastery1.hide()
		card_mastery2.hide()
		# Lộ trình Đàn Tranh
		path_soloist_title.text = "🎵 ĐƯỜNG ĐỘC TẤU (SOLOIST PATH)"
		path_chords_title.text = "🎸 ĐƯỜNG ĐỆM HÁT (CHORDS PATH)"
		
		basic_title.text = "Nhập Môn Đàn Tranh"
		basic_desc.text = "Học tư thế ngồi, cách đeo móng gảy và gảy các âm cơ bản trên dây tranh."
		basic_details.text = "📖 Lý Thuyết | ⭐ 5 Sao | 100% Hoàn Thành" if SecureDataManager.is_lesson_completed(instrument, "Node1") else "📖 Lý Thuyết | ⭐ 0 Sao | 0% Hoàn Thành"
		
		ess_title.text = "Kỹ Thuật Nhấn Rung"
		ess_desc.text = "Luyện nhấn dây (nhấn 1/2 âm, 1 âm) và rung dây bằng tay trái tạo hồn cho nhạc."
		ess_details.text = "📖 3 Bài Học | 🔒 Mở khóa sau khi hoàn thành Nhập Môn" if not SecureDataManager.is_lesson_completed(instrument, "Node1") else "📖 3 Bài Học | Mở Khóa"
		
		soloist_unlock_title.text = "Độc Tấu"
		chords_unlock_title.text = "Hợp Âm"
		
		soloist_skills_title.text = "Bài 1: Khúc Nhạc Vui"
		soloist_skills_bullets.text = "✓ Kỹ thuật Song Thanh, Vê dây\n✓ Kỹ thuật Á vuốt, Vuốt dây\n✓ Đọc nhạc phổ Ngũ cung cổ"
		
		chords_skills_title.text = "Hợp Âm Đàn Tranh"
		chords_skills_bullets.text = "✓ Cách rải hợp âm ngũ cung cổ\n✓ Đệm các tiết tấu dân ca 2/4\n✓ Kỹ thuật hợp âm rải (Arpeggio)"
		
		classical_title.text = "Nhạc Cổ Truyền"
		classical_desc.text = "✓ Dạ Cổ Hoài Lang (Độc tấu)\n✓ Bản cổ Nam Bộ Lý Mỹ Hưng\n✓ Độc tấu điệu nhạc cổ truyền"
		
		pop_chords_title.text = "Đệm Hát Hiện Đại"
		pop_chords_desc.text = "✓ Bèo Dạt Mây Trôi (Dân ca)\n✓ Đất Phương Nam (Đệm hát)\n✓ Nhạc Pop & Quê hương trữ tình"
	elif instrument == "dan_bau":
		card_adv_tech.hide()
		card_pro_perf.hide()
		card_mastery1.hide()
		card_mastery2.hide()
		# Lộ trình Đàn Bầu
		path_soloist_title.text = "🎵 ĐƯỜNG ĐỘC TẤU (SOLOIST PATH)"
		path_chords_title.text = "🎸 ĐƯỜNG ĐỆM HÁT (CHORDS PATH)"
		
		basic_title.text = "Nhập Môn Đàn Bầu"
		basic_desc.text = "Học tư thế ngồi, cách cầm que gảy và gảy các âm bồi/hài âm cơ bản trên một dây."
		basic_details.text = "📖 Lý Thuyết | ⭐ 5 Sao | 100% Hoàn Thành" if SecureDataManager.is_lesson_completed(instrument, "Node1") else "📖 Lý Thuyết | ⭐ 0 Sao | 0% Hoàn Thành"
		
		ess_title.text = "Kỹ Thuật Uốn Cần"
		ess_desc.text = "Luyện kỹ thuật uốn cần đàn luyến láy để thay đổi cao độ tiếng đàn ngân nga."
		ess_details.text = "📖 3 Bài Học | 🔒 Mở khóa sau khi hoàn thành Nhập Môn" if not SecureDataManager.is_lesson_completed(instrument, "Node1") else "📖 3 Bài Học | Mở Khóa"
		
		soloist_unlock_title.text = "Độc Tấu"
		chords_unlock_title.text = "Đệm Hát"
		
		soloist_skills_title.text = "Bài 1: Khúc Nhạc Vui"
		soloist_skills_bullets.text = "✓ Kỹ thuật Hài âm nâng cao\n✓ Rung cần tạo ngân rung sâu\n✓ Đọc nhạc phổ Độc huyền cầm"
		
		chords_skills_title.text = "Đệm Hát Đàn Bầu"
		chords_skills_bullets.text = "✓ Cách uốn nốt theo lời ca\n✓ Đệm các làn điệu dân ca cổ\n✓ Kỹ thuật luyến láy lướt âm"
		
		classical_title.text = "Nhạc Cổ Truyền"
		classical_desc.text = "✓ Dạ Cổ Hoài Lang (Đàn Bầu)\n✓ Làn điệu cổ truyền Bắc Bộ\n✓ Độc tấu nhạc cổ điệu da diết"
		
		pop_chords_title.text = "Đệm Hát Quê Hương"
		pop_chords_desc.text = "✓ Bèo Dạt Mây Trôi (Dân ca)\n✓ Trống Cơm / Lý Kéo Chài\n✓ Nhạc quê hương & trữ tình sâu lắng"
	else:
		# Lộ trình Sáo Trúc
		path_soloist_title.text = "🎵 ĐƯỜNG ĐỘC TẤU (SOLOIST PATH)"
		path_chords_title.text = "🎷 ĐƯỜNG HÒA TẤU (ENSEMBLE PATH)"
		
		basic_title.text = "Nhập Môn Sáo Trúc"
		basic_desc.text = "Học đặt môi, lấy hơi bụng, cách bấm các lỗ sáo và thổi ra âm thanh tròn trịa."
		basic_details.text = "📖 Lý Thuyết | ⭐ 5 Sao | 100% Hoàn Thành" if SecureDataManager.is_lesson_completed(instrument, "Node1") else "📖 Lý Thuyết | ⭐ 0 Sao | 0% Hoàn Thành"
		
		ess_title.text = "Bấm Ngón & Lấy Hơi"
		ess_desc.text = "Tập bấm các nốt chuẩn thang âm sáo trúc và kiểm soát cột hơi ổn định."
		ess_details.text = "📖 3 Bài Học | 🔒 Mở khóa sau khi hoàn thành Nhập Môn" if not SecureDataManager.is_lesson_completed(instrument, "Node1") else "📖 3 Bài Học | Mở Khóa"
		
		soloist_unlock_title.text = "Độc Tấu"
		chords_unlock_title.text = "Hòa Tấu"
		
		soloist_skills_title.text = "Bài 1: Khúc Nhạc Vui"
		soloist_skills_bullets.text = "✓ Làm quen nốt nhạc cơ bản\n✓ Thử thách nhịp điệu (Rhythm)\n✓ Tự tin thổi bài đầu tiên"
		
		chords_skills_title.text = "Hòa Tấu 1: Cây Trúc Xinh"
		chords_skills_bullets.text = "✓ Hòa tấu cùng trống và đàn\n✓ Kỹ thuật thổi đệm theo giai điệu\n✓ Phối hợp nhịp nhàng"
		
		classical_title.text = "Bài 2: Trống Cơm"
		classical_desc.text = "✓ Làn điệu dân ca Bắc Bộ\n✓ Kỹ thuật lấy hơi nhịp nhàng\n✓ Tăng tốc độ thổi sáo"
		
		pop_chords_title.text = "Hòa Tấu 2: Nhật Ký Của Mẹ"
		pop_chords_desc.text = "✓ Thổi trên nền nhạc Beat hiện đại\n✓ Cảm xúc sâu lắng (Gặp Mẹ Trong Mơ)\n✓ Nhạc trẻ kết hợp truyền thống"

		card_adv_tech.show()
		card_pro_perf.show()
		
		adv_title.text = "Bài 3: Bèo Dạt Mây Trôi"
		adv_desc.text = "✓ Dân ca trữ tình đồng bằng
✓ Kỹ thuật vuốt ngón cơ bản
✓ Truyền cảm xúc vào tiếng sáo"
		
		pro_title.text = "Biểu Diễn Chuyên Nghiệp"
		pro_desc.text = "✓ Bèo Dạt Mây Trôi\n✓ Lý Cây Bông\n✓ Nhạc Trẻ Cover"
		
		card_mastery1.show()
		card_mastery2.show()
		
		m1_title.text = "Bài 4: Lý Hoài Nam"
		m1_desc.text = "✓ Thổi luyến ngũ cung mượt mà\n✓ Kỹ thuật phi yến\n✓ Hơi dài và nhịp điệu tự do"
		
		m2_title.text = "Bài 5: Xuân Về Bản Mèo"
		m2_desc.text = "✓ Tác phẩm sáo trúc kinh điển
✓ Reo lưỡi kép, phi yến
✓ Biểu diễn như nghệ sĩ"

	# ── Style Card Basic — deep jade, gold border, warm glow ─────────────────
	var basic_sb := _flat(C_CARD_BG, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.40), 20)
	basic_sb.border_width_left = 2; basic_sb.border_width_right = 2
	basic_sb.border_width_top = 2; basic_sb.border_width_bottom = 2
	basic_sb.shadow_size = 28
	basic_sb.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.28)
	card_basic.add_theme_stylebox_override("panel", basic_sb)
	basic_title.add_theme_color_override("font_color", C_CREAM)
	basic_desc.add_theme_color_override("font_color", C_CREAM_DIM)
	basic_details.add_theme_color_override("font_color", C_GOLD)
	
	# ── Style Card Essentials — walnut, gold border glow ─────────────────────
	var ess_sb := _flat(C_CARD_BG_DK, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.30), 20)
	ess_sb.border_width_left = 2; ess_sb.border_width_right = 2
	ess_sb.border_width_top = 2; ess_sb.border_width_bottom = 2
	ess_sb.shadow_size = 22; ess_sb.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.18)
	card_essentials.add_theme_stylebox_override("panel", ess_sb)
	ess_title.add_theme_color_override("font_color", C_CREAM)
	ess_desc.add_theme_color_override("font_color", C_CREAM_DIM)
	ess_details.add_theme_color_override("font_color", C_GOLD)
	
	# ── Locked Cards — dark muted, subtle primary border ──────────────────────
	var lock_sb := _flat(C_CARD_LOCKED, Color(C_PRIMARY.r, C_PRIMARY.g, C_PRIMARY.b, 0.20), 20)
	lock_sb.border_width_left = 1; lock_sb.border_width_right = 1
	lock_sb.border_width_top = 1; lock_sb.border_width_bottom = 1
	lock_sb.shadow_size = 10; lock_sb.shadow_color = Color(0, 0, 0, 0.30)
	
	for card in [card_soloist_unlock, card_chords_unlock]:
		card.add_theme_stylebox_override("panel", lock_sb)
		var title := card.get_node("Margin/VBox/Title") as Label
		title.add_theme_color_override("font_color", C_CREAM_DIM)
		
		# Unlock button — terracotta gradient on dark card
		var btn := card.get_node("Margin/VBox/BtnUnlock") as Button
		var btn_n := _flat(C_PRIMARY, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35), 14)
		btn_n.shadow_size = 12; btn_n.shadow_color = Color(C_PRIMARY.r, C_PRIMARY.g, C_PRIMARY.b, 0.40)
		btn.add_theme_stylebox_override("normal",  btn_n)
		btn.add_theme_stylebox_override("hover",   _flat(C_PRIMARY_LT, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.55), 14))
		btn.add_theme_stylebox_override("pressed", _flat(C_PRIMARY_DK, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.20), 14))
		btn.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), C_GOLD, 14))
		btn.add_theme_color_override("font_color",         C_CREAM)
		btn.add_theme_color_override("font_hover_color",   C_CREAM)
		btn.add_theme_color_override("font_pressed_color", C_GOLD)
		btn.add_theme_font_size_override("font_size", 15)

	# ── Skills & end cards — dark walnut, gold border ─────────────────────────
	var skills_sb := _flat(C_CARD_BG_DK, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25), 20)
	skills_sb.border_width_left = 2; skills_sb.border_width_right = 2
	skills_sb.border_width_top = 2; skills_sb.border_width_bottom = 2
	skills_sb.shadow_size = 18; skills_sb.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.14)
	
		
	if not adv_btn.pressed.is_connected(_on_adv_tech_pressed):
		adv_btn.pressed.connect(_on_adv_tech_pressed)
		pro_btn.pressed.connect(_on_pro_perf_pressed)
		m1_btn.pressed.connect(_on_m1_pressed)
		m2_btn.pressed.connect(_on_m2_pressed)
	for card in [card_soloist_skills, card_chords_skills, card_classical, card_pop_chords, card_adv_tech, card_pro_perf, card_mastery1, card_mastery2]:
		card.add_theme_stylebox_override("panel", skills_sb)
		var title := card.get_node("Margin/HBox/TextV/Title") as Label
		var bullets := card.get_node("Margin/HBox/TextV/BulletList") as Label
		# Warm ivory title, muted sand bullet text
		title.add_theme_color_override("font_color", C_GOLD)
		bullets.add_theme_color_override("font_color", C_CREAM_DIM)
		
		# Style circular play button — terracotta filled, gold border
		var btn := card.get_node("Margin/HBox/BtnPlay") as Button
		_style_circular_play_btn(btn)

func _style_circular_play_btn(btn: Button) -> void:
	# Terracotta gradient fill, gold glow border
	var pb_n := _flat(C_PRIMARY, C_GOLD, 32)
	pb_n.border_width_left = 2; pb_n.border_width_right = 2
	pb_n.border_width_top = 2; pb_n.border_width_bottom = 2
	pb_n.shadow_size = 14; pb_n.shadow_color = Color(C_PRIMARY.r, C_PRIMARY.g, C_PRIMARY.b, 0.50)
	
	var pb_h := _flat(C_PRIMARY_LT, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.90), 32)
	pb_h.border_width_left = 2; pb_h.border_width_right = 2
	pb_h.border_width_top = 2; pb_h.border_width_bottom = 2
	pb_h.shadow_size = 20; pb_h.shadow_color = Color(C_PRIMARY.r, C_PRIMARY.g, C_PRIMARY.b, 0.65)
	
	btn.add_theme_stylebox_override("normal", pb_n)
	btn.add_theme_stylebox_override("hover", pb_h)
	btn.add_theme_stylebox_override("pressed", _flat(C_PRIMARY_DK, C_GOLD, 32))
	btn.add_theme_stylebox_override("focus", _flat(Color(0,0,0,0), C_GOLD, 32))
	
	# Procedural play triangle icon inside
	var draw_node := Control.new()
	draw_node.name = "PlayTriangle"
	draw_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	draw_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	draw_node.draw.connect(func() -> void:
		var sz := draw_node.size
		var cx := sz.x * 0.54
		var cy := sz.y * 0.5
		var pts := PackedVector2Array([
			Vector2(cx - 9, cy - 12),
			Vector2(cx + 11, cy),
			Vector2(cx - 9, cy + 12)
		])
		draw_node.draw_colored_polygon(pts, Color.WHITE)
	)
	btn.add_child(draw_node)

# ─── Animate In ────────────────────────────────────────────────────────────────
func _animate_in() -> void:
	var items := [card_basic, card_essentials, card_soloist_unlock, card_chords_unlock, card_soloist_skills, card_chords_skills, card_classical, card_pop_chords]
	var delay := 0.0
	for item in items:
		if not is_instance_valid(item): continue
		item.modulate.a = 0.0
		item.position.x += 40.0
		var t := create_tween().set_parallel(true)
		t.tween_property(item, "modulate:a", 1.0, 0.45).set_delay(delay)
		t.tween_property(item, "position:x", item.position.x - 40.0, 0.45).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		delay += 0.08

# ─── Connect Buttons ───────────────────────────────────────────────────────────
func _connect_buttons() -> void:
	btn_room.pressed.connect(func() -> void: _fade_to("res://scenes/VirtualMusicRoom.tscn"))
	btn_songs.pressed.connect(func() -> void:
		_fade_to("res://scenes/SongScreen.tscn")
	)
	btn_account.pressed.connect(_go_account)
	btn_minigame.pressed.connect(func() -> void: _fade_to("res://scenes/MiniGame.tscn"))
 
	for btn in [btn_courses, btn_room, btn_songs, btn_minigame, btn_account]:
		_make_btn_bouncy(btn)
		btn.pressed.connect(func() -> void: _set_active_tab(btn))

	# Card Clicks
	card_basic.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			SecureDataManager.active_lesson_id = "Node1"
			_fade_to("res://scenes/VideoPlayer.tscn")
	)
	card_essentials.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
			if inst == "dan_tranh":
				_show_course_detail("Kỹ Thuật Nhấn Rung", 2, 7)
			elif inst == "dan_bau":
				_fade_to("res://scenes/LessonDanBau.tscn")
			else:
				_show_course_detail("Bấm Ngón & Lấy Hơi", 2, 7)
	)
	
	# Play Buttons -> Practice Room
	var play_soloist := card_soloist_skills.get_node("Margin/HBox/BtnPlay") as Button
	play_soloist.pressed.connect(func() -> void:
		var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
		if inst == "sao_truc":
			_show_course_detail("Bài 1: Khúc Nhạc Vui", 9, 10)
		elif inst == "dan_bau":
			_fade_to("res://scenes/LessonDanBau.tscn")
		else:
			_show_course_detail("Kỹ Năng Độc Tấu", 4, 3)
	)
	_make_btn_bouncy(play_soloist)
	
	var play_chords := card_chords_skills.get_node("Margin/HBox/BtnPlay") as Button
	play_chords.pressed.connect(_on_chords_pressed)
	_make_btn_bouncy(play_chords)

	var play_classical := card_classical.get_node("Margin/HBox/BtnPlay") as Button
	play_classical.pressed.connect(_on_classical_pressed)
	_make_btn_bouncy(play_classical)
	
	var play_pop := card_pop_chords.get_node("Margin/HBox/BtnPlay") as Button
	play_pop.pressed.connect(_on_pop_pressed)
	_make_btn_bouncy(play_pop)

	# Unlock Buttons -> Virtual Artist Mai popup
	var unlock_sol := card_soloist_unlock.get_node("Margin/VBox/BtnUnlock") as Button
	unlock_sol.pressed.connect(func() -> void:
		pass
	)
	_make_btn_bouncy(unlock_sol)

	var unlock_cho := card_chords_unlock.get_node("Margin/VBox/BtnUnlock") as Button
	unlock_cho.pressed.connect(func() -> void:
		pass
	)
	_make_btn_bouncy(unlock_cho)

	avatar_circle.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed: _go_account()
	)

	# Mobile Navigation Connections
	btn_room_mob.pressed.connect(func() -> void: _fade_to("res://scenes/VirtualMusicRoom.tscn"))
	btn_songs_mob.pressed.connect(func() -> void:
		_fade_to("res://scenes/SongScreen.tscn")
	)
	btn_account_mob.pressed.connect(_go_account)
	btn_minigame_mob.pressed.connect(func() -> void: _fade_to("res://scenes/MiniGame.tscn"))
 
	for btn in [btn_courses_mob, btn_room_mob, btn_songs_mob, btn_minigame_mob, btn_account_mob]:
		_make_btn_bouncy(btn)
		btn.pressed.connect(func() -> void: _set_active_tab(btn))

func _set_active_tab(active: Button) -> void:
	var all : Array[Button] = [btn_courses, btn_room, btn_songs, btn_minigame, btn_account]
	var active_desktop : Button = null
	if active == btn_courses or active == btn_courses_mob: active_desktop = btn_courses
	elif active == btn_room or active == btn_room_mob: active_desktop = btn_room
	elif active == btn_songs or active == btn_songs_mob: active_desktop = btn_songs
	elif active == btn_minigame or active == btn_minigame_mob: active_desktop = btn_minigame
	elif active == btn_account or active == btn_account_mob: active_desktop = btn_account
	
	for b : Button in all:
		var is_a : bool = (b == active_desktop)
		_style_side_icon_btn(b, is_a)
		var ic := b.get_node_or_null("IconDraw") as Control
		if ic: ic.queue_redraw()
	_active_side_btn = active_desktop
	
	var all_mob : Array[Button] = [btn_courses_mob, btn_room_mob, btn_songs_mob, btn_minigame_mob, btn_account_mob]
	var active_mobile : Button = null
	if active == btn_courses or active == btn_courses_mob: active_mobile = btn_courses_mob
	elif active == btn_room or active == btn_room_mob: active_mobile = btn_room_mob
	elif active == btn_songs or active == btn_songs_mob: active_mobile = btn_songs_mob
	elif active == btn_minigame or active == btn_minigame_mob: active_mobile = btn_minigame_mob
	elif active == btn_account or active == btn_account_mob: active_mobile = btn_account_mob
	
	for b : Button in all_mob:
		var is_a : bool = (b == active_mobile)
		_style_bottom_icon_btn(b, is_a)
		var ic := b.get_node_or_null("IconDraw") as Control
		if ic: ic.queue_redraw()

# ─── Navigation ────────────────────────────────────────────────────────────────
func _go_practice() -> void:
	var instrument : String = SecureDataManager.data.get("selected_instrument", "dan_tranh")
	if instrument == "dan_tranh":
		card_adv_tech.hide()
		card_pro_perf.hide()
		_fade_to("res://scenes/PracticeRoom.tscn")
	elif instrument == "dan_bau":
		card_adv_tech.hide()
		card_pro_perf.hide()
		_fade_to("res://scenes/PracticeDanBau.tscn")
	else:
		_fade_to("res://scenes/PracticeSaoTruc.tscn")

func _go_practice_room_for_node(node_index: int) -> void:
	var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
	
	if inst == "dan_tranh":
		if node_index == 2:
			PracticeRoom.current_song_title = "3 Nốt Đầu (Đô - Rê - Mi)"
			PracticeRoom.current_song_sheet = ["Đô", "Rê", "Mi", "Rê", "Đô", "Rê", "Mi", "Đô"]
		elif node_index == 3:
			PracticeRoom.current_song_title = "Kỹ Thuật Nhấn Dây & Rung Âm"
			PracticeRoom.current_song_sheet = ["Đô", "Đô", "Rê", "Mi", "Mi", "Sol", "Sol", "Sol", "Mi", "Rê", "Đô"]
		elif node_index == 4:
			PracticeRoom.current_song_title = "Kỹ Thuật Song Thanh"
			PracticeRoom.current_song_sheet = ["Đô", "La", "Sol", "Đô", "La", "Mi", "Sol", "La"]
	elif inst == "dan_bau":
		if node_index == 2:
			PracticeDanBau.current_song_title = "Hài Âm Cơ Bản"
			PracticeDanBau.current_song_sheet = ["Đô", "Rê", "Mi", "Fa", "Sol", "La", "Si"]
		elif node_index == 3:
			PracticeDanBau.current_song_title = "Uốn Vòi Đàn"
			PracticeDanBau.current_song_sheet = ["Đô", "Mi", "Fa", "La", "Si", "La", "Fa", "Mi", "Rê", "Đô"]
		elif node_index == 4:
			PracticeDanBau.current_song_title = "Luyến Láy Đàn Bầu"
			PracticeDanBau.current_song_sheet = ["Đô", "Fa", "La", "Si", "La", "Fa", "Đô"]
	else: # sao_truc
		if node_index == 2:
			PracticeSaoTruc.current_song_title = "Hơi thở & Che lỗ cơ bản"
			PracticeSaoTruc.current_song_sheet = ["Đô", "Rê", "Mi", "Fa", "Sol", "La", "Si"]
		elif node_index == 3:
			PracticeSaoTruc.current_song_title = "Luyện Ngón Sáo Trúc"
			PracticeSaoTruc.current_song_sheet = ["Đô", "Đô", "Rê", "Mi", "Mi", "Fa", "Sol", "Fa", "Mi", "Rê", "Đô"]
		elif node_index == 4:
			PracticeSaoTruc.current_song_title = "Nhấp Ngón Kỹ Thuật"
			PracticeSaoTruc.current_song_sheet = ["Sol", "La", "Si", "Đô", "Si", "La", "Sol"]

	var path := "res://scenes/PracticeRoom.tscn"
	if inst == "dan_tranh":
		path = "res://scenes/PracticeRoom.tscn"
	elif inst == "dan_bau":
		path = "res://scenes/PracticeDanBau.tscn"
	else:
		path = "res://scenes/PracticeSaoTruc.tscn"
		
	_fade_to(path)

func _go_instruments() -> void: _fade_to("res://scenes/InstrumentSelect.tscn")
func _go_progress()    -> void: _fade_to("res://scenes/ProgressScreen.tscn")
func _go_account()     -> void: _fade_to("res://scenes/AccountScreen.tscn")

func _fade_to(path: String) -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.25)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file(path))

# ─── Helpers ───────────────────────────────────────────────────────────────────
func _flat(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.border_color = border
	s.border_width_left = 2; s.border_width_right  = 2
	s.border_width_top  = 2; s.border_width_bottom = 2
	s.corner_radius_top_left     = radius; s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius; s.corner_radius_bottom_right = radius
	return s

func _make_btn_bouncy(btn: Button) -> void:
	btn.pivot_offset = btn.size / 2.0
	btn.resized.connect(func() -> void: btn.pivot_offset = btn.size / 2.0)
	btn.mouse_entered.connect(func() -> void:
		var t := create_tween()
		t.tween_property(btn, "scale", Vector2(1.06, 1.06), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
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
		t.tween_property(btn, "scale", Vector2(1.06, 1.06) if btn.is_hovered() else Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)

func _on_viewport_size_changed() -> void:
	var size = get_viewport().size
	var is_mobile = size.x < size.y or size.x < 768
	
	sidebar.visible = not is_mobile
	bottom_bar.visible = is_mobile
	
	# TopBar scaling
	if is_mobile:
		top_bar.add_theme_constant_override("margin_left", 16)
		top_bar.add_theme_constant_override("margin_right", 16)
		sp_label.add_theme_font_size_override("font_size", 14)
		xp_label.add_theme_font_size_override("font_size", 14)
		streak_pill.get_node("SPMargin").add_theme_constant_override("margin_left", 12)
		streak_pill.get_node("SPMargin").add_theme_constant_override("margin_right", 12)
		xp_pill.get_node("XPMargin").add_theme_constant_override("margin_left", 12)
		xp_pill.get_node("XPMargin").add_theme_constant_override("margin_right", 12)
	else:
		top_bar.add_theme_constant_override("margin_left", 40)
		top_bar.add_theme_constant_override("margin_right", 40)
		sp_label.add_theme_font_size_override("font_size", 18)
		xp_label.add_theme_font_size_override("font_size", 18)
		streak_pill.get_node("SPMargin").add_theme_constant_override("margin_left", 22)
		streak_pill.get_node("SPMargin").add_theme_constant_override("margin_right", 22)
		xp_pill.get_node("XPMargin").add_theme_constant_override("margin_left", 22)
		xp_pill.get_node("XPMargin").add_theme_constant_override("margin_right", 22)
		
	# Cards scaling
	var card_w := 300.0 if is_mobile else 460.0
	var un_card_w := 200.0 if is_mobile else 280.0
	var gap := 40.0 if is_mobile else 90.0
	
	var x_basic := 40.0
	var x_ess   := x_basic + card_w + gap
	var x_un    := x_ess + card_w + gap
	var x_sk    := x_un + un_card_w + gap
	var x_end   := x_sk + card_w + gap
	var total_w := x_end + card_w + 40.0
	
	var y_top := 40.0 if is_mobile else 95.0
	var y_mid := 180.0 if is_mobile else 275.0
	var y_bot := 320.0 if is_mobile else 455.0
	var roadmap_h := 520.0 if is_mobile else 760.0
	
	if card_mastery2 != null and card_mastery2.visible:
		total_w = max(total_w, card_mastery2.position.x + card_w + 80.0)
	elif card_pro_perf != null and card_pro_perf.visible:
		total_w = max(total_w, card_pro_perf.position.x + card_w + 80.0)
		
	roadmap_content.custom_minimum_size = Vector2(total_w, roadmap_h)
	
	card_basic.position = Vector2(x_basic, y_mid)
	card_basic.custom_minimum_size = Vector2(card_w, card_basic.custom_minimum_size.y)
	
	card_essentials.position = Vector2(x_ess, y_mid)
	card_essentials.custom_minimum_size = Vector2(card_w, card_essentials.custom_minimum_size.y)
	
	card_soloist_unlock.position = Vector2(x_un, y_top)
	card_soloist_unlock.custom_minimum_size = Vector2(un_card_w, card_soloist_unlock.custom_minimum_size.y)
	
	card_chords_unlock.position = Vector2(x_un, y_bot)
	card_chords_unlock.custom_minimum_size = Vector2(un_card_w, card_chords_unlock.custom_minimum_size.y)
	
	card_soloist_skills.position = Vector2(x_sk, y_top)
	card_soloist_skills.custom_minimum_size = Vector2(card_w, card_soloist_skills.custom_minimum_size.y)
	
	card_chords_skills.position = Vector2(x_sk, y_bot)
	card_chords_skills.custom_minimum_size = Vector2(card_w, card_chords_skills.custom_minimum_size.y)
	
	card_classical.position = Vector2(x_end, y_top)
	card_classical.custom_minimum_size = Vector2(card_w, card_classical.custom_minimum_size.y)
	
	card_pop_chords.position = Vector2(x_end, y_bot)
	card_pop_chords.custom_minimum_size = Vector2(card_w, card_pop_chords.custom_minimum_size.y)
	
	roadmap_guide.position = Vector2(x_basic, 80.0 if is_mobile else 180.0)
	path_soloist_title.position = Vector2(x_un, 10.0 if is_mobile else 40.0)
	path_chords_title.position = Vector2(x_un, 290.0 if is_mobile else 400.0)
	
	# Redraw to update paths
	roadmap_content.queue_redraw()

# ─── Course Detail Popup ───────────────────────────────────────────────────────
func _get_max_unlocked_node(inst: String) -> int:
	if SecureDataManager.is_lesson_completed(inst, "Node4"): return 5
	if SecureDataManager.is_lesson_completed(inst, "Node3"): return 4
	if SecureDataManager.is_lesson_completed(inst, "Node2"): return 3
	if SecureDataManager.is_lesson_completed(inst, "Node1"): return 2
	return 1

func _show_course_detail(title: String, start_node: int, count: int) -> void:
	SecureDataManager.active_course_title = title
	SecureDataManager.active_course_start_node = start_node
	SecureDataManager.active_course_node_count = count
	_fade_to("res://scenes/CourseDetailScreen.tscn")

func _get_dan_bau_card_status(card_type: String) -> Dictionary:
	var completed : Array = SecureDataManager.data.completed_lessons.get("dan_bau", [])
	var stars_dict : Dictionary = SecureDataManager.data.stars.get("dan_bau", {})
	var steps_to_check: Array[String] = []
	if card_type == "basic":
		steps_to_check = ["dan_bau_coban_1_video", "dan_bau_coban_1_practice"]
	elif card_type == "essentials":
		steps_to_check = ["dan_bau_coban_2_video", "dan_bau_coban_2_practice"]
	elif card_type == "soloist":
		steps_to_check = ["dan_bau_coban_3_video", "dan_bau_coban_3_practice"]
	elif card_type == "chords":
		steps_to_check = ["dan_bau_coban_4_video", "dan_bau_coban_4_practice"]
	elif card_type == "classical" or card_type == "pop_chords":
		steps_to_check = ["dan_bau_coban_5_video", "dan_bau_coban_5_practice"]

	var total_stars := 0
	var completed_count := 0
	for step in steps_to_check:
		if completed.has(step):
			completed_count += 1
		total_stars += int(stars_dict.get(step, 0))

	var total_count: int = max(1, steps_to_check.size())
	var pct: int = int((float(completed_count) / float(total_count)) * 100.0)
	return {"stars": total_stars, "pct": pct, "completed": completed_count == total_count}

func _play_dan_bau_video(lesson_idx: int) -> void:
	var lessons_data: Array = LESSON_DAN_BAU_SCRIPT.LESSONS
	if lesson_idx < 0 or lesson_idx >= lessons_data.size():
		return
	var ldata: Dictionary = lessons_data[lesson_idx]
	SecureDataManager.active_lesson_id = str(ldata["id"]) + "_video"
	VideoPlayer.custom_video_path = "res://Video/coMai_danBau.ogv"
	VideoPlayer.custom_subtitles = ldata["subtitles"]
	_fade_to("res://scenes/VideoPlayer.tscn")

func _play_dan_bau_practice(lesson_num: int) -> void:
	SecureDataManager.active_lesson_id = "dan_bau_coban_" + str(lesson_num) + "_practice"
	_fade_to("res://scenes/PracticeDanBau.tscn")

func _on_adv_tech_pressed() -> void:
	var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
	if inst == "sao_truc":
		_show_course_detail("Bài 3: Bèo Dạt Mây Trôi", 29, 3)

func _on_pro_perf_pressed() -> void:
	var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
	if inst == "sao_truc":
		_show_course_detail("Biểu Diễn Chuyên Nghiệp", 15, 3)

func _on_classical_pressed() -> void:
	var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
	if inst == "sao_truc":
		_show_course_detail("Bài 2: Trống Cơm", 19, 10)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_is_dragging_roadmap = true
				_drag_start_pos = event.global_position
				_scroll_start_x = roadmap_scroll.scroll_horizontal
			else:
				_is_dragging_roadmap = false
	elif event is InputEventMouseMotion and _is_dragging_roadmap:
		var dx = event.global_position.x - _drag_start_pos.x
		roadmap_scroll.scroll_horizontal = _scroll_start_x - int(dx)


func _on_m1_pressed() -> void:
	var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
	if inst == "sao_truc":
		_show_course_detail("Bài 4: Lý Hoài Nam", 38, 3)

func _on_m2_pressed() -> void:
	var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
	if inst == "sao_truc":
		_show_course_detail("Bài 5: Xuân Về Bản Mèo", 41, 5)

func _on_chords_pressed() -> void:
	var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
	if inst == "sao_truc":
		_show_course_detail("Hòa Tấu 1: Cây Trúc Xinh", 32, 3)

func _on_pop_pressed() -> void:
	var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
	if inst == "sao_truc":
		_show_course_detail("Hòa Tấu 2: Nhật Ký Của Mẹ", 35, 3)
