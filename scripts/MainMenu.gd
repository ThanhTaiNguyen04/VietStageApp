extends Control

# ─── Color Palette (Traditional Vietnamese Lacquer Red & Gold) ──────────────────
const C_BG_DARK     := Color(0.063, 0.024, 0.016, 1.0) # #100604 - deep black/mahogany wood
const C_BG_DARKER   := Color(0.035, 0.008, 0.004, 1.0) # #090201 - darker lacquer black
const C_WAVE_COLOR  := Color(0.380, 0.059, 0.039, 0.28) # #610f0a - lacquer red waves
const C_WAVE_COLOR2 := Color(0.550, 0.260, 0.050, 0.16) # glowing bronze/orange wave
const C_CARD_BG     := Color(0.720, 0.120, 0.080, 1.0) # C_RED_SON - vermilion lacquer red
const C_CARD_BG_DK  := Color(0.380, 0.060, 0.040, 1.0) # C_RED_DK - deep lacquer red
const C_CARD_LOCKED := Color(0.120, 0.040, 0.020, 0.96) # mahogany black
const C_GOLD_GLOW   := Color(0.950, 0.720, 0.180, 1.0) # C_GOLD - glowing gold progress ring
const C_PATH_LINE   := Color(0.988, 0.976, 0.910, 1.0) # cream white path
const C_PATH_SHADOW := Color(0.150, 0.020, 0.010, 0.55) # deep red path shadow

const C_RED_SON     := Color(0.72, 0.12, 0.08, 1.0)
const C_RED_DK      := Color(0.38, 0.06, 0.04, 0.96)
const C_GOLD        := Color(0.95, 0.72, 0.18, 1.0)
const C_GOLD_LIGHT  := Color(1.00, 0.87, 0.45, 1.0)
const C_CREAM       := Color(1.00, 0.97, 0.88, 1.0)
const C_CREAM_DIM   := Color(0.80, 0.76, 0.66, 1.0)

var _active_side_btn : Button = null
var _time : float = 0.0

# ─── @onready refs ─────────────────────────────────────────────────────────────
@onready var bg_canvas     : Control        = $BackgroundCanvas
@onready var sidebar       : PanelContainer = $Root/Sidebar
@onready var btn_menu      : Button         = $Root/Sidebar/SideM/SideV/BtnMenu
@onready var btn_courses   : Button         = $Root/Sidebar/SideM/SideV/BtnCourses
@onready var btn_songs     : Button         = $Root/Sidebar/SideM/SideV/BtnSongs
@onready var btn_account   : Button         = $Root/Sidebar/SideM/SideV/BtnAccount

@onready var top_bar       : MarginContainer = $Root/RightContent/TopBar
@onready var avatar_circle : PanelContainer  = $Root/RightContent/TopBar/TopRow/AvatarCircle
@onready var avatar_thumb  : TextureRect     = $Root/RightContent/TopBar/TopRow/AvatarCircle/AvatarThumb
@onready var greet_lbl     : Label           = $Root/RightContent/TopBar/TopRow/GreetLabel
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
func _ready() -> void:
	SecureDataManager.load_data()
	_build_sidebar()
	_build_top_bar()
	_build_roadmap_cards()
	_connect_buttons()
	_setup_drawing_callbacks()
	_animate_in()
	
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.38)

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
		# Gray outer ring
		vis_basic.draw_arc(Vector2(cx, cy), r, 0, TAU, 32, Color(1.0, 1.0, 1.0, 0.12), 7.0, true)
		# Gold progress ring (60% master)
		vis_basic.draw_arc(Vector2(cx, cy), r, -PI/2, -PI/2 + 0.6 * TAU, 32, C_GOLD_GLOW, 7.0, true)
		# Draw percentage text in the center
		var font := vis_basic.get_theme_font("font")
		vis_basic.draw_string(font, Vector2(cx - 18, cy + 6), "60%", HORIZONTAL_ALIGNMENT_CENTER, -1, 18, C_CREAM)
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
	var cx := c.size.x / 2.0
	var cy := c.size.y / 2.0
	# Padlock body
	c.draw_rect(Rect2(cx - 12, cy - 4, 24, 20), C_CREAM_DIM, true)
	c.draw_rect(Rect2(cx - 12, cy - 4, 24, 20), Color(0.12, 0.04, 0.02, 1), false, 2.0)
	# Lock shackle
	c.draw_arc(Vector2(cx, cy - 4), 8.0, PI, TAU, 16, C_CREAM_DIM, 3.0, true)

func _draw_background_waves() -> void:
	var sz := bg_canvas.size
	# Lacquer deep dark brown base
	bg_canvas.draw_rect(Rect2(Vector2.ZERO, sz), C_BG_DARKER)
	
	# Lacquer Red Wave 1 (Animated)
	var w1_pts := PackedVector2Array()
	var w1_start := Vector2(0, sz.y * 0.15 + sin(_time * 0.8) * 8.0)
	var w1_ctrl1 := Vector2(sz.x * 0.3, sz.y * 0.45 + cos(_time * 0.6) * 12.0)
	var w1_ctrl2 := Vector2(sz.x * 0.6, sz.y * 0.10 + sin(_time * 0.7) * 10.0)
	var w1_end   := Vector2(sz.x, sz.y * 0.35 + cos(_time * 0.9) * 8.0)
	for i in range(30):
		var t := i / 29.0
		w1_pts.append(w1_start.bezier_interpolate(w1_ctrl1, w1_ctrl2, w1_end, t))
	w1_pts.append(Vector2(sz.x, sz.y))
	w1_pts.append(Vector2(0, sz.y))
	bg_canvas.draw_colored_polygon(w1_pts, C_WAVE_COLOR)
	
	# Bronze Golden Wave 2 (Animated)
	var w2_pts := PackedVector2Array()
	var w2_start := Vector2(0, sz.y * 0.45 + cos(_time * 0.7) * 10.0)
	var w2_ctrl1 := Vector2(sz.x * 0.35, sz.y * 0.20 + sin(_time * 0.8) * 12.0)
	var w2_ctrl2 := Vector2(sz.x * 0.7, sz.y * 0.55 + cos(_time * 0.5) * 10.0)
	var w2_end   := Vector2(sz.x, sz.y * 0.25 + sin(_time * 0.6) * 8.0)
	for i in range(30):
		var t := i / 29.0
		w2_pts.append(w2_start.bezier_interpolate(w2_ctrl1, w2_ctrl2, w2_end, t))
	w2_pts.append(Vector2(sz.x, sz.y))
	w2_pts.append(Vector2(0, sz.y))
	bg_canvas.draw_colored_polygon(w2_pts, C_WAVE_COLOR2)

func _draw_roadmap_paths() -> void:
	# Draw gorgeous traditional cloud designs and star particles under paths
	# Clouds in Gold watermarks (slow floating drift)
	_draw_traditional_cloud(roadmap_content, Vector2(320 + sin(_time * 0.2) * 15.0, 130), 55.0)
	_draw_traditional_cloud(roadmap_content, Vector2(850 + cos(_time * 0.15) * 12.0, 630), 45.0)
	_draw_traditional_cloud(roadmap_content, Vector2(1620 + sin(_time * 0.25) * 15.0, 120), 50.0)
	_draw_traditional_cloud(roadmap_content, Vector2(2150 + cos(_time * 0.18) * 18.0, 620), 55.0)
	
	# Glowing Gold Stars (individual shimmers)
	var star_positions := [
		Vector2(160, 130), Vector2(280, 620), Vector2(620, 120), Vector2(980, 640),
		Vector2(1210, 380), Vector2(1480, 120), Vector2(1780, 640), Vector2(2080, 120)
	]
	for i in range(star_positions.size()):
		_draw_gold_star(roadmap_content, star_positions[i], i)
		
	# Draw roadmap line segments connecting cards
	# Basic Card -> Essentials Card -> Split point
	_draw_thick_path(Vector2(270, 380), Vector2(780, 380))
	
	# Essentials split into Soloist and Chords paths
	_draw_curved_path(Vector2(780, 380), Vector2(1210, 200))
	_draw_curved_path(Vector2(780, 380), Vector2(1210, 560))
	
	# Top Path (Soloist): SoloistUnlock -> SoloistSkills -> Classical
	_draw_thick_path(Vector2(1210, 200), Vector2(2160, 200))
	
	# Bottom Path (Chords): ChordsUnlock -> ChordsSkills -> PopChords
	_draw_thick_path(Vector2(1210, 560), Vector2(2160, 560))

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
	var side_s := _flat(C_BG_DARK, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.15), 0)
	side_s.border_width_left = 0; side_s.border_width_top = 0; side_s.border_width_bottom = 0
	side_s.border_width_right = 2
	side_s.shadow_size = 16
	side_s.shadow_color = Color(0, 0, 0, 0.5)
	side_s.shadow_offset = Vector2(4, 0)
	sidebar.add_theme_stylebox_override("panel", side_s)

	var is_prem : bool = SecureDataManager.data.get("is_premium", false)

	_style_side_icon_btn(btn_menu, false)
	_style_side_icon_btn(btn_courses,  true)
	_style_side_icon_btn(btn_songs,    false, not is_prem)
	_style_side_icon_btn(btn_account, false)

	_attach_icon_draw(btn_menu,     0)
	_attach_icon_draw(btn_courses,  1)
	_attach_icon_draw(btn_songs,    2, not is_prem)
	_attach_icon_draw(btn_account,  5)

	_active_side_btn = btn_courses

func _style_side_icon_btn(btn: Button, is_active: bool, is_locked: bool = false) -> void:
	var bg_n := _flat(Color(0, 0, 0, 0) if not is_active else Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.22), Color(0, 0, 0, 0), 18)
	var bg_h := _flat(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.10) if not is_locked else Color(0, 0, 0, 0), Color(0, 0, 0, 0), 18)
	var bg_p := _flat(Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.30) if not is_locked else Color(0, 0, 0, 0), Color(0, 0, 0, 0), 18)

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
	btn.add_theme_stylebox_override("focus",   _flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))
	btn.add_theme_color_override("font_color",         C_GOLD if is_active else (C_CREAM_DIM.darkened(0.35) if is_locked else C_CREAM_DIM))
	btn.add_theme_color_override("font_hover_color",   C_CREAM_DIM.darkened(0.2) if is_locked else C_CREAM)
	btn.add_theme_color_override("font_pressed_color", C_GOLD if not is_locked else C_CREAM_DIM.darkened(0.35))
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

	match t:
		0: # Hamburger
			for i in 3:
				var y := cy - 12.0 + i * 12.0
				c.draw_line(Vector2(cx - 15, y), Vector2(cx + 15, y), col, 4.0, true)
		1: # Graduation
			var pts := PackedVector2Array([
				Vector2(cx, cy - 14),
				Vector2(cx + 22, cy - 4),
				Vector2(cx, cy + 6),
				Vector2(cx - 22, cy - 4)
			])
			c.draw_colored_polygon(pts, col)
			var base_pts := PackedVector2Array([
				Vector2(cx - 11, cy + 1),
				Vector2(cx + 11, cy + 1),
				Vector2(cx + 8, cy + 8),
				Vector2(cx - 8, cy + 8)
			])
			c.draw_colored_polygon(base_pts, col)
			c.draw_line(Vector2(cx, cy - 4), Vector2(cx + 15, cy + 3), col, 3.0, true)
			c.draw_circle(Vector2(cx + 15, cy + 6), 3.5, col)
		2: # Notes
			c.draw_rect(Rect2(cx - 13, cy - 14, 5, 20), col)
			c.draw_rect(Rect2(cx + 3,  cy - 18, 5, 20), col)
			c.draw_circle(Vector2(cx - 10,  cy + 6), 6.5, col)
			c.draw_circle(Vector2(cx + 6,  cy + 2), 6.5, col)
			c.draw_line(Vector2(cx - 8, cy - 14), Vector2(cx + 8, cy - 18), col, 4.0, true)
		3: # Gamepad
			c.draw_arc(Vector2(cx, cy), 16, 0, TAU, 32, col, 4.0, true)
			c.draw_line(Vector2(cx - 10, cy), Vector2(cx - 4, cy), col, 3.5, true)
			c.draw_line(Vector2(cx + 4, cy), Vector2(cx + 10, cy), col, 3.5, true)
			c.draw_line(Vector2(cx, cy - 10), Vector2(cx, cy - 4), col, 3.5, true)
			c.draw_line(Vector2(cx, cy + 4), Vector2(cx, cy + 10), col, 3.5, true)
			c.draw_circle(Vector2(cx + 7, cy - 3), 3.5, col)
			c.draw_circle(Vector2(cx + 7, cy + 3), 3.5, col)
		4: # Bars
			var bar_w := 8.0
			var bars := [14.0, 22.0, 11.0, 19.0]
			var base_y := cy + 14.0
			for i in bars.size():
				var x := cx - 18.0 + i * 12.0
				c.draw_rect(Rect2(x, base_y - bars[i], bar_w, bars[i]), col)
		5: # Person
			c.draw_circle(Vector2(cx, cy - 8), 8.5, col)
			c.draw_arc(Vector2(cx, cy + 14), 14, PI, TAU, 24, col, 4.0, true)

	if is_locked:
		var lx := cx + 12.0
		var ly := cy + 10.0
		# draw small lock
		c.draw_rect(Rect2(lx - 5, ly - 2, 10, 8), C_GOLD, true) # golden lock body
		c.draw_rect(Rect2(lx - 5, ly - 2, 10, 8), C_BG_DARK, false, 1.0)
		c.draw_arc(Vector2(lx, ly - 2), 3.5, PI, TAU, 8, C_GOLD, 1.5, true)

# ─── Top Bar ──────────────────────────────────────────────────────────────────
func _build_top_bar() -> void:
	var av_s := _flat(C_BG_DARK, C_GOLD, 34)
	av_s.border_width_left = 2; av_s.border_width_right = 2
	av_s.border_width_top = 2; av_s.border_width_bottom = 2
	av_s.shadow_size = 8; av_s.shadow_color = Color(0, 0, 0, 0.35)
	avatar_circle.add_theme_stylebox_override("panel", av_s)
	
	greet_lbl.add_theme_color_override("font_color", C_CREAM)
	greet_lbl.text = "Hi, Tai!"

	var sp_s := _flat(C_BG_DARK, Color(0.9, 0.42, 0.08, 0.4), 22)
	streak_pill.add_theme_stylebox_override("panel", sp_s)
	sp_label.add_theme_color_override("font_color", Color(1.0, 0.70, 0.22, 1.0))
	sp_label.text = str(SecureDataManager.data.daily_streak) + " ngày"

	var xp_s := _flat(C_BG_DARK, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.4), 22)
	xp_pill.add_theme_stylebox_override("panel", xp_s)
	xp_label.add_theme_color_override("font_color", C_GOLD_LIGHT)
	
	var total_xp : int = 1240 + int(SecureDataManager.data.practice_time_seconds) / 6
	xp_label.text = str(total_xp) + " XP"

# ─── Roadmap Cards styling ───────────────────────────────────────────────────
func _build_roadmap_cards() -> void:
	var instrument := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
	var is_tranh := (instrument == "dan_tranh")
	
	# Main labels styling
	roadmap_guide.add_theme_color_override("font_color", C_GOLD_LIGHT)
	path_soloist_title.add_theme_color_override("font_color", C_GOLD)
	path_chords_title.add_theme_color_override("font_color", C_GOLD)
	
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

	if is_tranh:
		# Lộ trình Đàn Tranh
		path_soloist_title.text = "🎵 ĐƯỜNG ĐỘC TẤU (SOLOIST PATH)"
		path_chords_title.text = "🎸 ĐƯỜNG ĐỆM HÁT (CHORDS PATH)"
		
		basic_title.text = "Nhập Môn Đàn Tranh"
		basic_desc.text = "Học tư thế ngồi, cách đeo móng gảy và gảy các âm cơ bản trên dây tranh."
		basic_details.text = "📖 2 Bài Học | ⭐ 6 Sao | 60% Hoàn Thành"
		
		ess_title.text = "Kỹ Thuật Nhấn Rung"
		ess_desc.text = "Luyện nhấn dây (nhấn 1/2 âm, 1 âm) và rung dây bằng tay trái tạo hồn cho nhạc."
		ess_details.text = "📖 3 Bài Học | 🔒 Cần hoàn thành bài trước"
		
		soloist_unlock_title.text = "Độc Tấu"
		chords_unlock_title.text = "Hợp Âm"
		
		soloist_skills_title.text = "Kỹ Năng Độc Tấu"
		soloist_skills_bullets.text = "✓ Kỹ thuật Song Thanh, Vê dây\n✓ Kỹ thuật Á vuốt, Vuốt dây\n✓ Đọc nhạc phổ Ngũ cung cổ"
		
		chords_skills_title.text = "Hợp Âm Đàn Tranh"
		chords_skills_bullets.text = "✓ Cách rải hợp âm ngũ cung cổ\n✓ Đệm các tiết tấu dân ca 2/4\n✓ Kỹ thuật hợp âm rải (Arpeggio)"
		
		classical_title.text = "Nhạc Cổ Truyền"
		classical_desc.text = "✓ Dạ Cổ Hoài Lang (Độc tấu)\n✓ Bản cổ Nam Bộ Lý Mỹ Hưng\n✓ Độc tấu điệu nhạc cổ truyền"
		
		pop_chords_title.text = "Đệm Hát Hiện Đại"
		pop_chords_desc.text = "✓ Bèo Dạt Mây Trôi (Dân ca)\n✓ Đất Phương Nam (Đệm hát)\n✓ Nhạc Pop & Quê hương trữ tình"
	else:
		# Lộ trình Sáo Trúc
		path_soloist_title.text = "🎵 ĐƯỜNG ĐỘC TẤU (SOLOIST PATH)"
		path_chords_title.text = "🎷 ĐƯỜNG HÒA TẤU (ENSEMBLE PATH)"
		
		basic_title.text = "Nhập Môn Sáo Trúc"
		basic_desc.text = "Học đặt môi, lấy hơi bụng, cách bấm các lỗ sáo và thổi ra âm thanh tròn trịa."
		basic_details.text = "📖 2 Bài Học | ⭐ 6 Sao | 60% Hoàn Thành"
		
		ess_title.text = "Bấm Ngón & Lấy Hơi"
		ess_desc.text = "Tập bấm các nốt chuẩn thang âm sáo trúc và kiểm soát cột hơi ổn định."
		ess_details.text = "📖 3 Bài Học | 🔒 Cần hoàn thành bài trước"
		
		soloist_unlock_title.text = "Độc Tấu"
		chords_unlock_title.text = "Hòa Tấu"
		
		soloist_skills_title.text = "Kỹ Năng Độc Tấu"
		soloist_skills_bullets.text = "✓ Kỹ thuật Láy ngón, Rung ngón\n✓ Kỹ thuật Réo rắt, Vuốt sáo\n✓ Đọc sáo phổ Ngũ cung"
		
		chords_skills_title.text = "Kỹ Năng Hòa Tấu"
		chords_skills_bullets.text = "✓ Thổi bè hòa âm phụ họa\n✓ Hòa tấu cùng các nhạc cụ dân tộc\n✓ Kỹ thuật thổi đệm bè nâng cao"
		
		classical_title.text = "Làn Điệu Quê Hương"
		classical_desc.text = "✓ Lý Hoài Nam (Dân ca)\n✓ Lòng Mẹ (Sáo độc tấu)\n✓ Thổi sáo truyền cảm cổ truyền"
		
		pop_chords_title.text = "Sáo Trúc Pop"
		pop_chords_desc.text = "✓ Bèo Dạt Mây Trôi (Dân ca)\n✓ Gặp Mẹ Trong Mơ (Nhạc ngoại)\n✓ Hòa âm nhạc nhẹ trữ tình"

	# Style Card Basic
	var basic_sb := _flat(C_CARD_BG, Color.WHITE, 24)
	basic_sb.border_width_left = 4; basic_sb.border_width_right = 4
	basic_sb.border_width_top = 4; basic_sb.border_width_bottom = 4
	basic_sb.shadow_size = 20; basic_sb.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35)
	card_basic.add_theme_stylebox_override("panel", basic_sb)
	basic_title.add_theme_color_override("font_color", C_CREAM)
	basic_desc.add_theme_color_override("font_color", C_CREAM_DIM)
	basic_details.add_theme_color_override("font_color", C_GOLD_LIGHT)
	
	# Style Card Essentials
	var ess_sb := _flat(C_CARD_BG_DK, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35), 24)
	card_essentials.add_theme_stylebox_override("panel", ess_sb)
	ess_title.add_theme_color_override("font_color", C_CREAM)
	ess_desc.add_theme_color_override("font_color", C_CREAM_DIM)
	ess_details.add_theme_color_override("font_color", C_GOLD_LIGHT)
	
	# Locked Cards (Soloist & Chords Unlock)
	var lock_sb := _flat(C_CARD_LOCKED, Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.20), 20)
	lock_sb.shadow_size = 12; lock_sb.shadow_color = Color(0, 0, 0, 0.35)
	
	for card in [card_soloist_unlock, card_chords_unlock]:
		card.add_theme_stylebox_override("panel", lock_sb)
		var title := card.get_node("Margin/VBox/Title") as Label
		title.add_theme_color_override("font_color", C_CREAM_DIM)
		
		# Buttons "MỞ KHÓA" - Gold/cream border outline
		var btn := card.get_node("Margin/VBox/BtnUnlock") as Button
		var btn_sb := _flat(Color(0,0,0,0), C_CREAM_DIM, 12)
		btn.add_theme_stylebox_override("normal", btn_sb)
		btn.add_theme_stylebox_override("hover", _flat(Color(1,1,1,0.08), C_CREAM, 12))
		btn.add_theme_stylebox_override("pressed", _flat(Color(1,1,1,0.15), C_GOLD, 12))
		btn.add_theme_color_override("font_color", C_CREAM)
		btn.add_theme_font_size_override("font_size", 14)

	# Skills & End cards (partially master)
	var skills_sb := _flat(C_BG_DARK, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35), 20)
	skills_sb.border_width_left = 3; skills_sb.border_width_right = 3
	skills_sb.border_width_top = 3; skills_sb.border_width_bottom = 3
	skills_sb.shadow_size = 12; skills_sb.shadow_color = Color(0, 0, 0, 0.4)
	
	for card in [card_soloist_skills, card_chords_skills, card_classical, card_pop_chords]:
		card.add_theme_stylebox_override("panel", skills_sb)
		var title := card.get_node("Margin/HBox/TextV/Title") as Label
		var bullets := card.get_node("Margin/HBox/TextV/BulletList") as Label
		title.add_theme_color_override("font_color", C_GOLD)
		bullets.add_theme_color_override("font_color", C_CREAM)
		
		# Style circular play button (Vermilion red filled, gold border)
		var btn := card.get_node("Margin/HBox/BtnPlay") as Button
		_style_circular_play_btn(btn)

func _style_circular_play_btn(btn: Button) -> void:
	var pb_n := _flat(C_RED_SON, C_GOLD, 32)
	pb_n.border_width_left = 3; pb_n.border_width_right = 3
	pb_n.border_width_top = 3; pb_n.border_width_bottom = 3
	pb_n.shadow_size = 10; pb_n.shadow_color = Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.4)
	
	var pb_h := _flat(Color(0.85, 0.18, 0.12, 1.0), Color.WHITE, 32)
	pb_h.border_width_left = 3; pb_h.border_width_right = 3
	pb_h.border_width_top = 3; pb_h.border_width_bottom = 3
	
	btn.add_theme_stylebox_override("normal", pb_n)
	btn.add_theme_stylebox_override("hover", pb_h)
	btn.add_theme_stylebox_override("pressed", _flat(C_RED_DK, C_GOLD, 32))
	btn.add_theme_stylebox_override("focus", _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	
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
	btn_courses.pressed.connect(func() -> void: _fade_to("res://scenes/CourseMap.tscn"))
	btn_songs.pressed.connect(func() -> void:
		var is_prem : bool = SecureDataManager.data.get("is_premium", false)
		if is_prem:
			_go_instruments()
		else:
			VirtualArtist.show_tip("Phần Bài hát chỉ dành cho tài khoản Premium! Hãy nâng cấp trong phần Hồ sơ nhé.", 4.5)
	)
	btn_account.pressed.connect(_go_account)

	for btn in [btn_courses, btn_songs, btn_account]:
		_make_btn_bouncy(btn)
		btn.pressed.connect(func() -> void: _set_active_tab(btn))

	# Card Clicks
	card_basic.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed: _fade_to("res://scenes/CourseMap.tscn")
	)
	card_essentials.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed: _fade_to("res://scenes/CourseMap.tscn")
	)
	
	# Play Buttons -> Practice Room
	var play_soloist := card_soloist_skills.get_node("Margin/HBox/BtnPlay") as Button
	play_soloist.pressed.connect(_go_practice)
	_make_btn_bouncy(play_soloist)
	
	var play_chords := card_chords_skills.get_node("Margin/HBox/BtnPlay") as Button
	play_chords.pressed.connect(_go_practice)
	_make_btn_bouncy(play_chords)

	var play_classical := card_classical.get_node("Margin/HBox/BtnPlay") as Button
	play_classical.pressed.connect(_go_practice)
	_make_btn_bouncy(play_classical)
	
	var play_pop := card_pop_chords.get_node("Margin/HBox/BtnPlay") as Button
	play_pop.pressed.connect(_go_practice)
	_make_btn_bouncy(play_pop)

	# Unlock Buttons -> Virtual Artist Mai popup
	var unlock_sol := card_soloist_unlock.get_node("Margin/VBox/BtnUnlock") as Button
	unlock_sol.pressed.connect(func() -> void:
		VirtualArtist.play_happy("Chúc mừng! Bạn đã tích lũy đủ XP để mở khóa con đường Độc Tấu.")
	)
	_make_btn_bouncy(unlock_sol)

	var unlock_cho := card_chords_unlock.get_node("Margin/VBox/BtnUnlock") as Button
	unlock_cho.pressed.connect(func() -> void:
		VirtualArtist.play_happy("Chúc mừng! Bạn đã sẵn sàng mở khóa con đường Hợp Âm.")
	)
	_make_btn_bouncy(unlock_cho)

	avatar_circle.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed: _go_account()
	)

func _set_active_tab(active: Button) -> void:
	var is_prem : bool = SecureDataManager.data.get("is_premium", false)
	if active == btn_songs and not is_prem:
		return
	var all : Array[Button] = [btn_courses, btn_songs, btn_account]
	for b : Button in all:
		var is_a : bool = (b == active)
		_style_side_icon_btn(b, is_a, b == btn_songs and not is_prem)
		var ic := b.get_node_or_null("IconDraw") as Control
		if ic: ic.queue_redraw()
	_active_side_btn = active

# ─── Navigation ────────────────────────────────────────────────────────────────
func _go_practice() -> void:
	var instrument : String = SecureDataManager.data.get("selected_instrument", "dan_tranh")
	if instrument == "dan_tranh":
		_fade_to("res://scenes/PracticeRoom.tscn")
	else:
		_fade_to("res://scenes/PracticeSaoTruc.tscn")

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
