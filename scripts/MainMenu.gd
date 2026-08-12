extends Control

# ─── Color Palette (Traditional Vietnamese Lacquer Red & Gold - Light Cream Theme)
const C_BG_DARK     := Color(0.95, 0.93, 0.89, 1.0) # #F3EFE3 - warm cream-beige for sidebar
const C_BG_DARKER   := Color(0.98, 0.97, 0.94, 1.0) # #FAF8F5 - warm cream background
const C_WAVE_COLOR  := Color(0.92, 0.88, 0.80, 0.45) # soft warm gray wave
const C_WAVE_COLOR2 := Color(0.95, 0.85, 0.60, 0.22) # soft warm gold wave
const C_CARD_BG     := Color(0.09, 0.27, 0.18, 1.0) # C_RED_SON - premium deep jade green
const C_CARD_BG_DK  := Color(0.28, 0.16, 0.10, 1.0) # deep warm brown wood
const C_CARD_LOCKED := Color(0.92, 0.90, 0.86, 0.70) # light warm gray-cream
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
const C_TERRACOTTA  := Color(0.753, 0.329, 0.102, 1.0) # #C0541A brand lacquer red
const SIDEBAR_COLLAPSED_WIDTH := 64.0

const DAN_TRANH_LESSON_SCRIPT = preload("res://scripts/LessonDanTranhList.gd")

var _active_side_btn : Button = null
var _time : float = 0.0
var _sidebar_icons_cache := {}
var btn_minigame : Button
var btn_minigame_mob : Button
var btn_leaderboard : Button
var btn_leaderboard_mob : Button
var _api_client = null
var _profile_level := 1
var _account_menu_open := false
var _avatar_request: HTTPRequest
var _remote_avatar_texture: Texture2D
var _requested_avatar_url := ""
var _summary_data := {}
var _daily_challenges: Array = []
var _daily_pill: PanelContainer = null
var _daily_pill_label: Button = null
var _daily_overlay: ColorRect = null
var _sidebar_expanded := true
var _sidebar_tween: Tween = null
var _sidebar_reveal_tween: Tween = null
var _sidebar_rail_width := 220.0
var _sidebar_safe_left := 0.0
var _sidebar_dropdown: PanelContainer = null
var _sidebar_blur: ColorRect = null
var _menu_glass: ColorRect = null

# ─── @onready refs ─────────────────────────────────────────────────────────────
@onready var bg_canvas     : Control        = $BackgroundCanvas
@onready var sidebar       : PanelContainer = $Root/Sidebar
@onready var side_margin   : MarginContainer = $Root/Sidebar/SideM
@onready var btn_menu      : Button         = $Root/Sidebar/SideM/SideV/BtnMenu
@onready var btn_courses   : Button         = $Root/Sidebar/SideM/SideV/BtnCourses
@onready var btn_room      : Button         = $Root/Sidebar/SideM/SideV/BtnRoom
@onready var btn_songs     : Button         = $Root/Sidebar/SideM/SideV/BtnSongs
@onready var btn_account   : Button         = $Root/Sidebar/SideM/SideV/BtnAccount

@onready var bottom_bar      : PanelContainer = $Root/RightContent/BottomBar
@onready var bottom_margin   : MarginContainer = $Root/RightContent/BottomBar/BottomM
@onready var btn_courses_mob : Button         = $Root/RightContent/BottomBar/BottomM/BottomH/BtnCoursesMobile
@onready var btn_room_mob    : Button         = $Root/RightContent/BottomBar/BottomM/BottomH/BtnRoomMobile
@onready var btn_songs_mob   : Button         = $Root/RightContent/BottomBar/BottomM/BottomH/BtnSongsMobile
@onready var btn_account_mob : Button         = $Root/RightContent/BottomBar/BottomM/BottomH/BtnAccountMobile

@onready var top_bar       : MarginContainer = $Root/RightContent/TopBar
@onready var avatar_circle : PanelContainer  = $Root/RightContent/TopBar/TopRow/AvatarCircle
@onready var profile_menu  : PanelContainer  = $Root/RightContent/TopBar/TopRow/ProfileMenu
@onready var profile_trigger: Button = $Root/RightContent/TopBar/TopRow/ProfileMenu/TriggerButton
@onready var mini_avatar_frame: PanelContainer = $Root/RightContent/TopBar/TopRow/ProfileMenu/TriggerM/TriggerH/MiniAvatarFrame
@onready var trigger_copy: VBoxContainer = $Root/RightContent/TopBar/TopRow/ProfileMenu/TriggerM/TriggerH/TriggerCopy
@onready var trigger_name: Label = $Root/RightContent/TopBar/TopRow/ProfileMenu/TriggerM/TriggerH/TriggerCopy/TriggerName
@onready var trigger_level: Label = $Root/RightContent/TopBar/TopRow/ProfileMenu/TriggerM/TriggerH/TriggerCopy/TriggerLevel
@onready var trigger_chevron: Label = $Root/RightContent/TopBar/TopRow/ProfileMenu/TriggerM/TriggerH/Chevron

@onready var account_menu_layer: Control = $AccountMenuLayer
@onready var dismiss_button: Button = $AccountMenuLayer/DismissButton
@onready var account_panel: PanelContainer = $AccountMenuLayer/AccountPanel
@onready var large_avatar_frame: PanelContainer = $AccountMenuLayer/AccountPanel/MenuM/MenuV/MenuHeader/LargeAvatarFrame
@onready var header_name: Label = $AccountMenuLayer/AccountPanel/MenuM/MenuV/MenuHeader/HeaderCopy/HeaderName
@onready var header_meta: Label = $AccountMenuLayer/AccountPanel/MenuM/MenuV/MenuHeader/HeaderCopy/HeaderMeta
@onready var online_dot: PanelContainer = $AccountMenuLayer/AccountPanel/MenuM/MenuV/MenuHeader/HeaderCopy/OnlineRow/OnlineDot
@onready var online_label: Label = $AccountMenuLayer/AccountPanel/MenuM/MenuV/MenuHeader/HeaderCopy/OnlineRow/OnlineLabel
@onready var profile_action: Button = $AccountMenuLayer/AccountPanel/MenuM/MenuV/ProfileAction
@onready var achievement_action: Button = $AccountMenuLayer/AccountPanel/MenuM/MenuV/AchievementAction
@onready var settings_action: Button = $AccountMenuLayer/AccountPanel/MenuM/MenuV/SettingsAction
@onready var logout_action: Button = $AccountMenuLayer/AccountPanel/MenuM/MenuV/LogoutAction

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
var card_level_7: PanelContainer
var card_level_8: PanelContainer

# ─── Ready ─────────────────────────────────────────────────────────────────────

func _ready() -> void:
	SecureDataManager.load_data()
	InstrumentSelect.selected_instrument = SecureDataManager.data.get("selected_instrument", "dan_tranh")

	_api_client = preload("res://scripts/ApiClient.gd").new()
	add_child(_api_client)
	_avatar_request = HTTPRequest.new()
	_avatar_request.request_completed.connect(_on_profile_avatar_loaded)
	add_child(_avatar_request)
	_fetch_and_sync_progress()
	_fetch_profile_identity()
	
	# Programmatic instantiation of MiniGame button
	var side_v := $Root/Sidebar/SideM/SideV as VBoxContainer
	btn_minigame = Button.new()
	btn_minigame.name = "BtnMiniGame"
	btn_minigame.text = "Mini-game"
	btn_minigame.flat = true
	btn_minigame.custom_minimum_size = Vector2(220, 100)
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
	
	btn_leaderboard = Button.new()
	btn_leaderboard.name = "BtnLeaderboard"
	btn_leaderboard.text = "Xếp hạng"
	btn_leaderboard.flat = true
	btn_leaderboard.custom_minimum_size = Vector2(220, 100)
	side_v.add_child(btn_leaderboard)
	side_v.move_child(btn_leaderboard, 6)

	btn_leaderboard_mob = Button.new()
	btn_leaderboard_mob.name = "BtnLeaderboardMobile"
	btn_leaderboard_mob.text = "Xếp hạng"
	btn_leaderboard_mob.flat = true
	btn_leaderboard_mob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_h.add_child(btn_leaderboard_mob)
	bottom_h.move_child(btn_leaderboard_mob, 4)
	
	_build_sidebar()
	_build_sidebar_dropdown()
	_build_menu_glass()
	_build_bottom_bar()
	_build_top_bar()
	_build_profile_menu()
	_create_level_7_card()
	_create_level_8_card()
	_build_roadmap_cards()
	_connect_buttons()
	_setup_drawing_callbacks()
	_animate_in()
	
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.38)

	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()

	avatar_circle.hide()
	btn_account.hide()
	btn_account_mob.hide()

func _fetch_and_sync_progress() -> void:
	if _api_client == null:
		return
	var response = await _api_client.get_my_progress()
	if _api_client._is_success(response):
		var list = response.get("body", {}).get("data", [])
		SecureDataManager.sync_backend_progress(list)
		_build_roadmap_cards()
	var summary_response = await _api_client.get_my_progress_summary()
	if _api_client._is_success(summary_response):
		var summary_data: Variant = summary_response.get("body", {}).get("data", {})
		if summary_data is Dictionary:
			_summary_data = summary_data
			var total_points := int(summary_data.get("total_points", summary_data.get("totalPoints", 0)))
			_profile_level = int(total_points / 1000) + 1
			_update_profile_menu_data()
			_apply_stat_pills(summary_data)
			if streak_pill and xp_pill:
				streak_pill.visible = false
				xp_pill.visible = false
	_fetch_daily_challenges()
	BackendReport.fetch_and_install_catalog()

func _fetch_profile_identity() -> void:
	if _api_client == null:
		return
	var response: Dictionary = await _api_client.get_me()
	if not _api_client._is_success(response):
		_load_profile_avatar(str(SecureDataManager.data.get("user_avatar_url", "")))
		return
	var body: Variant = response.get("body", {})
	var profile: Variant = body.get("data", {}) if body is Dictionary else {}
	if not profile is Dictionary:
		return
	var full_name := str(profile.get("fullName", "")).strip_edges()
	var avatar_url := str(profile.get("avatarUrl", "")).strip_edges()
	if not full_name.is_empty():
		SecureDataManager.data["user_name"] = full_name
	SecureDataManager.data["user_avatar_url"] = avatar_url
	SecureDataManager.save_data()
	_update_profile_menu_data()

func _process(delta: float) -> void:
	_time += delta
	bg_canvas.queue_redraw()
	roadmap_content.queue_redraw()
	
	var straight_instrument := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
	# Removed hack because _on_viewport_size_changed now handles it properly


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
		
		var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
		var pct := 0.0
		if inst == "dan_tranh":
			var stats: Dictionary = _get_dan_tranh_level_status(1)
			pct = stats["pct"]
		elif inst == "dan_bau" or inst == "sao_truc":
			var stats := _get_dan_bau_card_status("basic") if inst == "dan_bau" else _get_sao_truc_card_status("basic")
			pct = stats["pct"]
		else:
			if SecureDataManager.is_lesson_completed(inst, "Node1"):
				pct = 100.0
		
		var angle_fill := (pct / 100.0) * TAU
		if angle_fill > 0.001:
			vis_basic.draw_arc(Vector2(cx, cy), r, -PI/2, -PI/2 + angle_fill, 32, C_GOLD_GLOW, 7.0, true)
		# Draw percentage text in the center
		var font := vis_basic.get_theme_font("font")
		var pct_text := str(int(pct)) + "%"
		var text_sz := font.get_string_size(pct_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 18)
		vis_basic.draw_string(font, Vector2(cx - text_sz.x * 0.5, cy + 6), pct_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, C_CREAM)
	)
	
	# Card Essentials Progress Ring in Gold
	var vis_essentials := card_essentials.get_node("Margin/Row/Visual") as Control
	vis_essentials.draw.connect(func() -> void:
		var cx := vis_essentials.size.x / 2.0
		var cy := vis_essentials.size.y / 2.0
		var r := 34.0
		vis_essentials.draw_arc(Vector2(cx, cy), r, 0, TAU, 32, Color(1.0, 1.0, 1.0, 0.12), 7.0, true)
		
		var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
		var pct := 0.0
		if inst == "dan_tranh":
			var stats: Dictionary = _get_dan_tranh_level_status(2)
			pct = stats["pct"]
		elif inst == "dan_bau" or inst == "sao_truc":
			var stats := _get_dan_bau_card_status("essentials") if inst == "dan_bau" else _get_sao_truc_card_status("essentials")
			pct = stats["pct"]
		else:
			if SecureDataManager.is_lesson_completed(inst, "Node1"): pct += 50.0
			if SecureDataManager.is_lesson_completed(inst, "Node3"): pct += 50.0
			
		var angle_fill := (pct / 100.0) * TAU
		if angle_fill > 0.001:
			vis_essentials.draw_arc(Vector2(cx, cy), r, -PI/2, -PI/2 + angle_fill, 32, C_GOLD_GLOW, 7.0, true)
		# Draw percentage text in the center
		var font := vis_essentials.get_theme_font("font")
		var pct_text := str(int(pct)) + "%"
		var text_sz := font.get_string_size(pct_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 18)
		vis_essentials.draw_string(font, Vector2(cx - text_sz.x * 0.5, cy + 6), pct_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, C_CREAM)
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
		lock_tex = load("res://assets/textures/lucide/lock.svg") as Texture2D
		_sidebar_icons_cache["lock"] = lock_tex

	if lock_tex:
		var sz := c.size
		var cx := sz.x * 0.5
		var cy := sz.y * 0.5
		c.draw_texture_rect(lock_tex, Rect2(cx - 16, cy - 16, 32, 32), false, C_CREAM_DIM)

func _draw_background_waves() -> void:
	var sz := bg_canvas.size
	# Lacquer deep dark brown base
	bg_canvas.draw_rect(Rect2(Vector2.ZERO, sz), C_BG_DARKER)
	
	var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
	if inst == "dan_tranh" or inst == "dan_bau" or inst == "trong_chau" or inst == "sao_truc":
		var cache_key := "bg_" + inst
		if not _sidebar_icons_cache.has(cache_key):
			var tex_path := "res://assets/textures/" + inst + "_background.png"
			if ResourceLoader.exists(tex_path):
				_sidebar_icons_cache[cache_key] = load(tex_path) as Texture2D
			else:
				_sidebar_icons_cache[cache_key] = null
				
		var tex = _sidebar_icons_cache[cache_key]
		if tex:
			var scale_factor = max(sz.x / tex.get_width(), sz.y / tex.get_height())
			var new_sz = Vector2(tex.get_width() * scale_factor, tex.get_height() * scale_factor)
			var pos = Vector2((sz.x - new_sz.x) / 2.0, (sz.y - new_sz.y) / 2.0)
			bg_canvas.draw_texture_rect(tex, Rect2(pos, new_sz), false)
			return # Bỏ qua vẽ sóng bên dưới
	
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
	var p_level_7 := card_level_7.position + card_level_7.size / 2.0
	var p_level_8 := card_level_8.position + card_level_8.size / 2.0
		
	var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
	if inst == "dan_bau" or inst == "dan_tranh" or inst == "sao_truc":
		# Ép tọa độ Y của các điểm neo bằng nhau để đường vàng vẽ thẳng tắp 100%
		var straight_y = p_basic.y
		p_ess.y = straight_y
		p_sol_sk.y = straight_y
		p_cho_sk.y = straight_y
		p_pop.y = straight_y
		p_class.y = straight_y
		
		# Đường thẳng duy nhất nằm ngang
		_draw_thick_path(p_basic, p_ess)
		_draw_thick_path(p_ess, p_sol_sk)
		if inst == "dan_tranh":
			_draw_thick_path(p_ess, p_level_7)
			_draw_thick_path(p_level_7, p_level_8)
		else:
			_draw_thick_path(p_sol_sk, p_cho_sk)
			_draw_thick_path(p_cho_sk, p_pop)
	else:
		# Draw roadmap line segments connecting cards
		# Basic Card -> Essentials Card -> Split point
		_draw_thick_path(p_basic, p_ess)
		
		# Essentials split into Soloist and Chords paths
		_draw_curved_path(p_ess, p_sol_un)
		_draw_curved_path(p_ess, p_cho_un)
		
		# Top Path (Soloist): SoloistUnlock -> SoloistSkills -> Classical
		_draw_thick_path(p_sol_un, p_sol_sk)
		_draw_thick_path(p_sol_sk, p_class)
		
		# Bottom Path (Chords): ChordsUnlock -> ChordsSkills -> PopChords
		_draw_thick_path(p_cho_un, p_cho_sk)
		_draw_thick_path(p_cho_sk, p_pop)

func _draw_thick_path(from: Vector2, to: Vector2) -> void:
	roadmap_content.draw_line(from, to, Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.15), 24.0, true)
	roadmap_content.draw_line(from, to, Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.4), 14.0, true)
	roadmap_content.draw_line(from, to, Color(1.0, 1.0, 1.0, 0.6), 4.0, true)

func _draw_curved_path(from: Vector2, to: Vector2) -> void:
	var ctrl1 := Vector2(from.x + (to.x - from.x) * 0.4, from.y)
	var ctrl2 := Vector2(from.x + (to.x - from.x) * 0.6, to.y)
	
	var line_pts := PackedVector2Array()
	
	for i in range(20):
		var t := i / 19.0
		var p := from.bezier_interpolate(ctrl1, ctrl2, to, t)
		line_pts.append(p)
		
	roadmap_content.draw_polyline(line_pts, Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.15), 24.0, true)
	roadmap_content.draw_polyline(line_pts, Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.4), 14.0, true)
	roadmap_content.draw_polyline(line_pts, Color(1.0, 1.0, 1.0, 0.6), 4.0, true)

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
	var side_s := StyleBoxFlat.new()
	side_s.bg_color = Color(0.93, 0.91, 0.87, 0.6) # Glassmorphism opacity
	side_s.border_color = Color(0.8, 0.78, 0.73, 0.8)
	side_s.border_width_right = 2
	side_s.content_margin_right = 0
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
	_sidebar_blur = blur_rect

	_style_side_icon_btn(btn_menu,     false)
	_style_side_icon_btn(btn_courses,  true)
	_style_side_icon_btn(btn_room,     false)
	_style_side_icon_btn(btn_songs,    false)
	_style_side_icon_btn(btn_minigame, false)
	_style_side_icon_btn(btn_leaderboard, false)
	_style_side_icon_btn(btn_account,  false)

	_attach_icon_draw(btn_menu,     0)
	_attach_icon_draw(btn_courses,  1)
	_attach_icon_draw(btn_room,     6)
	_attach_icon_draw(btn_songs,    2)
	_attach_icon_draw(btn_minigame, 3)
	_attach_icon_draw(btn_leaderboard, 4)
	_attach_icon_draw(btn_account,  5)

	_active_side_btn = btn_courses

func _build_sidebar_dropdown() -> void:
	_sidebar_dropdown = PanelContainer.new()
	_sidebar_dropdown.name = "SidebarDropdown"
	_sidebar_dropdown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sidebar_dropdown.z_index = 20
	_sidebar_dropdown.hide()

	var dropdown_style := _flat(Color(0.98, 0.97, 0.94, 0.96), Color(C_GOLD_LIGHT.r, C_GOLD_LIGHT.g, C_GOLD_LIGHT.b, 0.9), 16)
	dropdown_style.shadow_color = Color(0.04, 0.10, 0.06, 0.24)
	dropdown_style.shadow_size = 10
	dropdown_style.shadow_offset = Vector2(0, 4)
	_sidebar_dropdown.add_theme_stylebox_override("panel", dropdown_style)

	var label := Label.new()
	label.text = "Điều hướng"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", C_RED_SON)
	label.add_theme_font_size_override("font_size", 14)
	_sidebar_dropdown.add_child(label)
	add_child(_sidebar_dropdown)

func _build_menu_glass() -> void:
	_menu_glass = ColorRect.new()
	_menu_glass.name = "MenuGlass"
	_menu_glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_glass.hide()

	var glass_shader := Shader.new()
	glass_shader.code = """
	shader_type canvas_item;
	uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
	void fragment() {
		float edge = smoothstep(0.50, 0.46, length(UV - vec2(0.5)));
		vec3 blurred_scene = textureLod(screen_texture, SCREEN_UV, 2.6).rgb;
		vec3 glass_tint = mix(blurred_scene, vec3(0.95, 0.97, 0.91), 0.28);
		COLOR = vec4(glass_tint, edge * 0.94);
	}
	"""
	var glass_material := ShaderMaterial.new()
	glass_material.shader = glass_shader
	_menu_glass.material = glass_material
	btn_menu.add_child(_menu_glass)
	btn_menu.move_child(_menu_glass, 0)
	_position_menu_glass()

func _build_bottom_bar() -> void:
	var bottom_s := _flat(C_BG_DARK, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.15), 0)
	bottom_s.border_width_left = 0; bottom_s.border_width_right = 0; bottom_s.border_width_bottom = 0
	bottom_s.border_width_top = 2
	bottom_s.shadow_size = 12
	bottom_s.shadow_color = Color(0.13, 0.08, 0.05, 0.15)
	bottom_s.shadow_offset = Vector2(0, -4)
	bottom_bar.add_theme_stylebox_override("panel", bottom_s)

	_style_bottom_icon_btn(btn_courses_mob, true)
	_style_bottom_icon_btn(btn_room_mob,    false)
	_style_bottom_icon_btn(btn_songs_mob,   false)
	_style_bottom_icon_btn(btn_account_mob, false)
	_style_bottom_icon_btn(btn_minigame_mob, false)
	_style_bottom_icon_btn(btn_leaderboard_mob, false)

	_attach_bottom_icon_draw(btn_courses_mob, 1)
	_attach_bottom_icon_draw(btn_room_mob,    6)
	_attach_bottom_icon_draw(btn_songs_mob,   2)
	_attach_bottom_icon_draw(btn_account_mob, 5)
	_attach_bottom_icon_draw(btn_minigame_mob, 3)
	_attach_bottom_icon_draw(btn_leaderboard_mob, 4)

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

func _style_side_icon_btn(btn: Button, is_active: bool, is_locked: bool = false) -> void:
	var bg_n := _flat(Color(0, 0, 0, 0) if not is_active else Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.12), Color(0, 0, 0, 0), 18)
	var bg_h := _flat(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.08) if not is_locked else Color(0, 0, 0, 0), Color(0, 0, 0, 0), 18)
	var bg_p := _flat(Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.20) if not is_locked else Color(0, 0, 0, 0), Color(0, 0, 0, 0), 18)

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
	btn.add_theme_stylebox_override("focus",   _flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))
	btn.add_theme_color_override("font_color",         C_RED_SON if is_active else (Color(0.43, 0.38, 0.33, 0.40) if is_locked else Color(0.43, 0.38, 0.33, 1.0)))
	btn.add_theme_color_override("font_hover_color",   Color(0.43, 0.38, 0.33, 0.8) if is_locked else Color(0.13, 0.08, 0.05, 1.0))
	btn.add_theme_color_override("font_pressed_color", C_RED_SON if not is_locked else Color(0.43, 0.38, 0.33, 0.40))
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
	
	if is_locked:
		var lock_tex : Texture2D = null
		if _sidebar_icons_cache.has("lock"):
			lock_tex = _sidebar_icons_cache["lock"]
		else:
			lock_tex = load("res://assets/textures/lucide/lock.svg") as Texture2D
			_sidebar_icons_cache["lock"] = lock_tex
			
		if lock_tex:
			var lx := cx + 10.0
			var ly := cy + 8.0
			c.draw_texture_rect(lock_tex, Rect2(lx - 6, ly - 6, 12, 12), false, C_GOLD)

# ─── Top Bar ────────────────────────────────────────────────────────────────
func _build_top_bar() -> void:
	# Khung avatar: bo tròn hoàn toàn, viền vàng phát sáng
	var av_s := StyleBoxFlat.new()
	av_s.bg_color              = C_BG_DARK
	av_s.border_color          = C_GOLD
	av_s.border_width_left     = 3; av_s.border_width_right  = 3
	av_s.border_width_top      = 3; av_s.border_width_bottom = 3
	av_s.corner_radius_top_left     = 34; av_s.corner_radius_top_right    = 34
	av_s.corner_radius_bottom_left  = 34; av_s.corner_radius_bottom_right = 34
	av_s.shadow_size   = 10
	av_s.shadow_color  = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.22)
	av_s.shadow_offset = Vector2(0, 2)
	avatar_circle.add_theme_stylebox_override("panel", av_s)

	# Lớp vẽ vòng tròn bo góc phía trên avatar (đảm bảo cắt đúng)
	var ring_draw := Control.new()
	ring_draw.name = "RingDraw"
	ring_draw.set_anchors_preset(Control.PRESET_FULL_RECT)
	ring_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring_draw.draw.connect(func() -> void:
		var sz := ring_draw.size
		var c  := sz / 2.0
		var r  := minf(c.x, c.y) - 3.0
		# Vòng nhẫn vàng ngoài cùng
		ring_draw.draw_arc(c, r, 0, TAU, 64, C_GOLD, 3.0, true)
		# Vòng nhẫn vàng nhạt phát sáng
		ring_draw.draw_arc(c, r - 1.5, 0, TAU, 64, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25), 6.0, true)
	)
	avatar_circle.add_child(ring_draw)

	var sp_s := _flat(Color(0.13, 0.08, 0.05, 0.9), Color(0.9, 0.42, 0.08, 0.4), 22)
	streak_pill.add_theme_stylebox_override("panel", sp_s)
	sp_label.add_theme_color_override("font_color", Color(1.0, 0.70, 0.22, 1.0))
	sp_label.text = str(SecureDataManager.data.daily_streak) + " ngày"

	var xp_s := _flat(Color(0.13, 0.08, 0.05, 0.9), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.4), 22)
	xp_pill.add_theme_stylebox_override("panel", xp_s)
	xp_label.add_theme_color_override("font_color", C_GOLD_LIGHT)

	var local_xp : int = int(SecureDataManager.data.get("total_points", 0)) + int(int(SecureDataManager.data.practice_time_seconds) / 6.0)
	xp_label.text = str(local_xp) + " XP"

	# Giá trị từ BE sẽ đè lên khi _fetch_and_sync_progress() thành công.
	# Ẩn khi chưa có dữ liệu BE để tránh hiện số liệu mặc định gây hiểu nhầm.
	streak_pill.visible = false
	xp_pill.visible = false

	_build_daily_challenge_pill()

func _apply_stat_pills(summary: Dictionary) -> void:
	var streak := int(summary.get("current_streak", summary.get("currentStreak", 0)))
	var points := int(summary.get("total_points", summary.get("totalPoints", 0)))
	if sp_label:
		sp_label.text = "%d ngày" % streak
	if xp_label:
		xp_label.text = "%d XP" % points

# ── Daily challenges ──────────────────────────────────────────────────────────

func _build_daily_challenge_pill() -> void:
	var stats_row := $Root/RightContent/TopBar/TopRow/StatsRow as HBoxContainer
	if stats_row == null:
		return
	_daily_pill = PanelContainer.new()
	_daily_pill.name = "DailyChallengePill"
	_daily_pill.visible = false
	_daily_pill.add_theme_stylebox_override("panel", _flat(Color(0.13, 0.08, 0.05, 0.92), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45), 22))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	var btn := Button.new()
	btn.flat = true
	btn.add_theme_font_size_override("font_size", 17)
	btn.add_theme_color_override("font_color", C_GOLD_LIGHT)
	btn.add_theme_color_override("font_hover_color", C_GOLD)
	btn.pressed.connect(_show_daily_challenges_popup)
	_daily_pill_label = btn
	margin.add_child(btn)
	_daily_pill.add_child(margin)
	stats_row.add_child(_daily_pill)

func _fetch_daily_challenges() -> void:
	if not BackendReport.is_signed_in():
		return
	_daily_challenges = await BackendReport.fetch_daily_challenges()
	_refresh_daily_pill_text()
	if _daily_pill:
		_daily_pill.visible = not _daily_challenges.is_empty()

func _refresh_daily_pill_text() -> void:
	if _daily_pill_label == null:
		return
	var pending := 0
	for challenge: Variant in _daily_challenges:
		if challenge is Dictionary:
			if not bool(challenge.get("is_completed", challenge.get("completed", false))):
				pending += 1
	if pending > 0:
		_daily_pill_label.text = "🔥 Thử thách hôm nay · %d" % pending
	else:
		_daily_pill_label.text = "🔥 Thử thách hôm nay"

func _show_daily_challenges_popup() -> void:
	if _daily_challenges.is_empty():
		return
	if _daily_overlay != null and is_instance_valid(_daily_overlay):
		_daily_overlay.queue_free()
		_daily_overlay = null

	_daily_overlay = ColorRect.new()
	_daily_overlay.name = "DailyChallengeOverlay"
	_daily_overlay.color = Color(0.05, 0.02, 0.01, 0.72)
	_daily_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_daily_overlay.z_index = 300
	add_child(_daily_overlay)
	_daily_overlay.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_close_daily_challenges_popup()
	)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_daily_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _flat(Color(0.10, 0.05, 0.02, 0.98), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.5), 24))
	panel.custom_minimum_size = Vector2(560, 0)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "🎯 THỬ THÁCH HÔM NAY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", C_GOLD_LIGHT)
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Hoàn thành thử thách để nhận điểm thưởng, tích lũy chuỗi luyện tập."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color(1, 1, 1, 0.72))
	vbox.add_child(subtitle)

	for challenge: Variant in _daily_challenges:
		if challenge is Dictionary:
			_build_daily_challenge_row(vbox, challenge)

	var close_btn := Button.new()
	close_btn.text = "ĐÓNG"
	close_btn.custom_minimum_size = Vector2(200, 54)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.add_theme_stylebox_override("normal", _flat(C_RED_SON, C_GOLD, 16))
	close_btn.add_theme_color_override("font_color", Color.WHITE)
	close_btn.add_theme_stylebox_override("hover", _flat(C_RED_SON.lightened(0.12), C_GOLD_LIGHT, 16))
	close_btn.pressed.connect(_close_daily_challenges_popup)
	vbox.add_child(close_btn)

func _build_daily_challenge_row(vbox: VBoxContainer, challenge: Dictionary) -> void:
	var is_done := bool(challenge.get("is_completed", challenge.get("completed", false)))
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", _flat(Color(1, 1, 1, 0.05), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.3), 14))
	var row_m := MarginContainer.new()
	row_m.add_theme_constant_override("margin_left", 18)
	row_m.add_theme_constant_override("margin_right", 18)
	row_m.add_theme_constant_override("margin_top", 12)
	row_m.add_theme_constant_override("margin_bottom", 12)
	row.add_child(row_m)
	var row_h := HBoxContainer.new()
	row_h.add_theme_constant_override("separation", 16)
	row_m.add_child(row_h)

	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row_title := Label.new()
	row_title.text = str(challenge.get("title", "Thử thách"))
	row_title.add_theme_font_size_override("font_size", 19)
	row_title.add_theme_color_override("font_color", C_CREAM)
	copy.add_child(row_title)
	var row_desc := Label.new()
	row_desc.text = "%s · Thưởng +%d điểm" % [str(challenge.get("description", "")), int(challenge.get("reward_points", 0))]
	row_desc.add_theme_font_size_override("font_size", 14)
	row_desc.add_theme_color_override("font_color", Color(1, 1, 1, 0.62))
	copy.add_child(row_desc)
	row_h.add_child(copy)

	if is_done:
		var done_lbl := Label.new()
		done_lbl.text = "✓ HOÀN THÀNH"
		done_lbl.add_theme_font_size_override("font_size", 15)
		done_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.6, 1.0))
		done_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row_h.add_child(done_lbl)
	else:
		var claim_btn := Button.new()
		claim_btn.text = "NHẬN THƯỞNG"
		claim_btn.custom_minimum_size = Vector2(170, 44)
		claim_btn.add_theme_font_size_override("font_size", 15)
		claim_btn.add_theme_stylebox_override("normal", _flat(C_GOLD, Color.TRANSPARENT, 12))
		claim_btn.add_theme_color_override("font_color", C_GOLD_DARK)
		var challenge_id := int(challenge.get("id", 0))
		claim_btn.pressed.connect(func() -> void: _complete_daily_challenge(challenge_id))
		row_h.add_child(claim_btn)
	vbox.add_child(row)

func _complete_daily_challenge(challenge_id: int) -> void:
	var result: Dictionary = await BackendReport.complete_daily_challenge(challenge_id)
	if not result.get("submitted", false):
		push_warning("[MainMenu] Không nhận được thưởng thử thách: %s" % str(result.get("message", "")))
		return
	for challenge: Variant in _daily_challenges:
		if challenge is Dictionary and int(challenge.get("id", 0)) == challenge_id:
			challenge["is_completed"] = true
			break
	_refresh_daily_pill_text()
	# Làm mới điểm từ BE để cập nhật ngay XP trên thanh thống kê
	var summary_response = await _api_client.get_my_progress_summary()
	if _api_client != null and _api_client._is_success(summary_response):
		var summary_data: Variant = summary_response.get("body", {}).get("data", {})
		if summary_data is Dictionary:
			_apply_stat_pills(summary_data)
	_show_daily_challenges_popup()

func _close_daily_challenges_popup() -> void:
	if _daily_overlay != null and is_instance_valid(_daily_overlay):
		_daily_overlay.queue_free()
		_daily_overlay = null

func _build_profile_menu() -> void:
	var top_row := profile_menu.get_parent() as HBoxContainer
	if top_row:
		top_row.move_child(profile_menu, top_row.get_child_count() - 1)
	_update_profile_menu_data()
	_style_account_menu()
	profile_trigger.pressed.connect(_toggle_account_menu)
	dismiss_button.pressed.connect(_close_account_menu)
	profile_action.pressed.connect(func() -> void: _open_account_destination("profile"))
	achievement_action.pressed.connect(func() -> void: _open_account_destination("achievements"))
	settings_action.pressed.connect(func() -> void: _open_account_destination("settings"))
	logout_action.pressed.connect(func() -> void: _open_account_destination("logout"))

func _update_profile_menu_data() -> void:
	var player_name := str(SecureDataManager.data.get("user_name", "Học viên VietStage"))
	var instrument := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
	trigger_name.text = player_name
	trigger_level.text = "Cấp độ %d" % _profile_level
	header_name.text = player_name
	header_meta.text = "Cấp độ %d · Đang học %s" % [_profile_level, _instrument_display_name(instrument)]
	online_label.text = "Đang hoạt động"

	var avatar_source := str(SecureDataManager.data.get("user_avatar_url", "")).strip_edges()
	if avatar_source.is_empty():
		avatar_source = str(SecureDataManager.data.get("user_avatar", "res://assets/textures/default_avatar.png"))
	var avatar_tex := _remote_avatar_texture
	if avatar_tex == null and avatar_source.begins_with("res://"):
		avatar_tex = load(avatar_source) as Texture2D
	if avatar_tex == null:
		avatar_tex = load("res://assets/textures/default_avatar.png") as Texture2D
	_set_profile_avatar_texture(avatar_tex)
	_load_profile_avatar(avatar_source)

func _set_profile_avatar_texture(texture: Texture2D) -> void:
	if texture == null:
		return
	var mini_avatar := mini_avatar_frame.get_node_or_null("MiniAvatar") as TextureRect
	if mini_avatar:
		mini_avatar.texture = texture
	var large_avatar := large_avatar_frame.get_node_or_null("LargeAvatar") as TextureRect
	if large_avatar:
		large_avatar.texture = texture

func _load_profile_avatar(avatar_url: String) -> void:
	if not avatar_url.begins_with("https://") and not avatar_url.begins_with("http://"):
		return
	if avatar_url == _requested_avatar_url:
		return
	_requested_avatar_url = avatar_url
	_avatar_request.cancel_request()
	var request_error := _avatar_request.request(avatar_url)
	if request_error != OK:
		_requested_avatar_url = ""

func _on_profile_avatar_loaded(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300 or body.is_empty():
		_requested_avatar_url = ""
		return
	var image := Image.new()
	var decode_error := image.load_png_from_buffer(body)
	if decode_error != OK:
		decode_error = image.load_jpg_from_buffer(body)
	if decode_error != OK:
		decode_error = image.load_webp_from_buffer(body)
	if decode_error != OK:
		_requested_avatar_url = ""
		return
	_remote_avatar_texture = ImageTexture.create_from_image(image)
	_set_profile_avatar_texture(_remote_avatar_texture)

func _instrument_display_name(instrument: String) -> String:
	match instrument:
		"dan_bau": return "Đàn Bầu"
		"sao_truc": return "Sáo Trúc"
		"trong_chau": return "Trống Chầu"
		_: return "Đàn Tranh"

func _style_account_menu() -> void:
	var bold_font := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if bold_font:
		trigger_name.add_theme_font_override("font", bold_font)
		header_name.add_theme_font_override("font", bold_font)
		for button: Button in [profile_action, achievement_action, settings_action, logout_action]:
			button.add_theme_font_override("font", bold_font)
	var trigger_style := _flat(Color(1.0, 1.0, 1.0, 0.65), Color(C_GOLD_LIGHT.r, C_GOLD_LIGHT.g, C_GOLD_LIGHT.b, 0.6), 35)
	trigger_style.shadow_color = Color(0.04, 0.10, 0.06, 0.18)
	trigger_style.shadow_size = 10
	trigger_style.shadow_offset = Vector2(0, 4)
	profile_menu.add_theme_stylebox_override("panel", trigger_style)
	mini_avatar_frame.add_theme_stylebox_override("panel", _avatar_menu_style(35, 0, Color.TRANSPARENT))
	large_avatar_frame.add_theme_stylebox_override("panel", _avatar_menu_style(36, 3, Color.WHITE))
	trigger_name.add_theme_color_override("font_color", Color(0.98, 0.96, 0.92, 1.0))
	trigger_level.add_theme_color_override("font_color", C_GOLD_LIGHT)
	trigger_chevron.add_theme_color_override("font_color", C_GOLD_LIGHT)

	profile_trigger.add_theme_stylebox_override("normal", _flat(Color.TRANSPARENT, Color.TRANSPARENT, 35))
	profile_trigger.add_theme_stylebox_override("hover", _flat(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.08), Color.TRANSPARENT, 35))
	profile_trigger.add_theme_stylebox_override("pressed", _flat(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.16), Color.TRANSPARENT, 35))
	profile_trigger.add_theme_stylebox_override("focus", _flat(Color.TRANSPARENT, C_GOLD, 35))

	var panel_style := _flat(Color(0.93, 0.91, 0.87, 0.6), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.58), 24)
	panel_style.shadow_color = Color(0.02, 0.06, 0.035, 0.34)
	panel_style.shadow_size = 22
	panel_style.shadow_offset = Vector2(0, 10)
	account_panel.add_theme_stylebox_override("panel", panel_style)
	header_name.add_theme_color_override("font_color", Color(0.13, 0.08, 0.05, 1.0))
	header_meta.add_theme_color_override("font_color", Color(0.36, 0.31, 0.27, 1.0))
	online_dot.add_theme_stylebox_override("panel", _flat(Color(0.22, 0.72, 0.36, 1.0), Color.WHITE, 4))
	online_label.add_theme_color_override("font_color", C_RED_SON)
	_style_account_action(profile_action, "user")
	_style_account_action(achievement_action, "trophy")
	_style_account_action(settings_action, "settings")
	_style_account_action(logout_action, "log-out")
	logout_action.add_theme_color_override("font_color", C_TERRACOTTA)
	logout_action.add_theme_color_override("icon_normal_color", C_TERRACOTTA)
	
	dismiss_button.add_theme_stylebox_override("normal", _flat(Color(0.01, 0.04, 0.025, 0.10), Color.TRANSPARENT, 0))
	dismiss_button.add_theme_stylebox_override("hover", _flat(Color(0.01, 0.04, 0.025, 0.13), Color.TRANSPARENT, 0))
	dismiss_button.add_theme_stylebox_override("pressed", _flat(Color(0.02, 0.05, 0.03, 0.12), Color.TRANSPARENT, 0))

func _style_account_action(button: Button, icon_name: String) -> void:
	button.icon = load("res://assets/textures/lucide/" + icon_name + ".svg") as Texture2D
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 23)
	button.add_theme_constant_override("h_separation", 14)
	button.add_theme_color_override("font_color", Color(0.13, 0.08, 0.05, 1.0))
	button.add_theme_color_override("font_hover_color", C_TERRACOTTA)
	button.add_theme_color_override("icon_normal_color", C_RED_SON)
	button.add_theme_color_override("icon_hover_color", C_TERRACOTTA)
	button.add_theme_stylebox_override("normal", _flat(Color.TRANSPARENT, Color.TRANSPARENT, 14))
	button.add_theme_stylebox_override("hover", _flat(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.11), Color.TRANSPARENT, 14))
	button.add_theme_stylebox_override("pressed", _flat(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.18), Color.TRANSPARENT, 14))
	button.add_theme_stylebox_override("focus", _flat(Color.TRANSPARENT, C_GOLD, 14))

func _avatar_menu_style(radius: int, border_width: int, bg_color := Color.WHITE) -> StyleBoxFlat:
	var style := _flat(bg_color, C_GOLD, radius)
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.border_width_top = border_width
	style.border_width_bottom = border_width
	return style

func _toggle_account_menu() -> void:
	if _account_menu_open:
		_close_account_menu()
	else:
		_open_account_menu()

func _open_account_menu() -> void:
	_account_menu_open = true
	_update_profile_menu_data()
	_layout_account_menu(get_viewport_rect().size)
	account_menu_layer.show()
	account_menu_layer.modulate.a = 0.0
	account_panel.scale = Vector2(0.96, 0.96)
	account_panel.position.y -= 6.0
	trigger_chevron.text = "⌃"
	var tween := create_tween().set_parallel(true)
	tween.tween_property(account_menu_layer, "modulate:a", 1.0, 0.16)
	tween.tween_property(account_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(account_panel, "position:y", account_panel.position.y + 6.0, 0.2).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

func _close_account_menu(animated: bool = true) -> void:
	if not _account_menu_open and not account_menu_layer.visible:
		return
	_account_menu_open = false
	trigger_chevron.text = "⌄"
	if not animated:
		account_menu_layer.hide()
		account_panel.scale = Vector2.ONE
		return
	var tween := create_tween().set_parallel(true)
	tween.tween_property(account_menu_layer, "modulate:a", 0.0, 0.12)
	tween.tween_property(account_panel, "scale", Vector2(0.98, 0.98), 0.12)
	await tween.finished
	if not _account_menu_open:
		account_menu_layer.hide()
		account_panel.scale = Vector2.ONE

func _open_account_destination(destination: String) -> void:
	_close_account_menu(false)
	if destination == "achievements":
		_go_progress()
	elif destination == "settings":
		_go_settings()
	elif destination == "logout":
		_confirm_logout()
	else:
		_go_account()

func _confirm_logout() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.4)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(overlay)
	
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)
	
	var panel := PanelContainer.new()
	# Minimalist white card style with thin border
	var p_style := _flat(Color.WHITE, Color("#EAEAEA"), 16)
	p_style.shadow_color = Color(0, 0, 0, 0.05)
	p_style.shadow_size = 16
	p_style.shadow_offset = Vector2(0, 4)
	panel.add_theme_stylebox_override("panel", p_style)
	panel.custom_minimum_size = Vector2(340, 0)
	center.add_child(panel)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_bottom", 32)
	panel.add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	margin.add_child(vbox)
	
	var bold_font := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	
	var title := Label.new()
	title.text = "Đăng xuất"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if bold_font: title.add_theme_font_override("font", bold_font)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("#111111")) # Charcoal black
	vbox.add_child(title)
	
	var msg := Label.new()
	msg.text = "Kết thúc phiên đăng nhập hiện tại?"
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", 16)
	msg.add_theme_color_override("font_color", Color("#787774")) # Muted gray
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(msg)
	
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	vbox.add_child(hbox)
	
	var btn_cancel := Button.new()
	btn_cancel.text = "Ở lại"
	btn_cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_cancel.custom_minimum_size.y = 48
	# White button with thin border
	var cancel_normal := _flat(Color.WHITE, Color("#EAEAEA"), 12)
	var cancel_hover := _flat(Color("#F7F6F3"), Color("#EAEAEA"), 12)
	btn_cancel.add_theme_stylebox_override("normal", cancel_normal)
	btn_cancel.add_theme_stylebox_override("hover", cancel_hover)
	btn_cancel.add_theme_stylebox_override("pressed", cancel_hover)
	btn_cancel.add_theme_stylebox_override("focus", _flat(Color.TRANSPARENT, C_GOLD, 12))
	btn_cancel.add_theme_color_override("font_color", Color("#111111"))
	btn_cancel.add_theme_color_override("font_hover_color", Color("#111111"))
	if bold_font: btn_cancel.add_theme_font_override("font", bold_font)
	hbox.add_child(btn_cancel)
	
	var btn_logout := Button.new()
	btn_logout.text = "Đăng xuất"
	btn_logout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_logout.custom_minimum_size.y = 48
	# Solid charcoal button
	var logout_normal := _flat(Color("#f90606"), Color("#f80707"), 12)
	var logout_hover := _flat(Color("#f90606").lightened(0.15), Color("#f80707"), 12)
	btn_logout.add_theme_stylebox_override("normal", logout_normal)
	btn_logout.add_theme_stylebox_override("hover", logout_hover)
	btn_logout.add_theme_stylebox_override("pressed", logout_hover)
	btn_logout.add_theme_stylebox_override("focus", _flat(Color.TRANSPARENT, C_GOLD, 12))
	btn_logout.add_theme_color_override("font_color", Color.WHITE)
	btn_logout.add_theme_color_override("font_hover_color", Color.WHITE)
	if bold_font: btn_logout.add_theme_font_override("font", bold_font)
	hbox.add_child(btn_logout)
	
	add_child(layer)
	
	btn_cancel.pressed.connect(func() -> void:
		_close_custom_dialog(layer, overlay, panel)
	)
	btn_logout.pressed.connect(func() -> void:
		_close_custom_dialog(layer, overlay, panel)
		_logout()
	)
	
	overlay.modulate.a = 0.0
	panel.scale = Vector2(0.9, 0.9)
	panel.pivot_offset = panel.custom_minimum_size / 2.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(overlay, "modulate:a", 1.0, 0.2)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _close_custom_dialog(layer: CanvasLayer, overlay: ColorRect, panel: PanelContainer) -> void:
	if not is_instance_valid(layer):
		return
	var tw := create_tween().set_parallel(true)
	tw.tween_property(overlay, "modulate:a", 0.0, 0.15)
	tw.tween_property(panel, "scale", Vector2(0.95, 0.95), 0.15)
	tw.chain().tween_callback(layer.queue_free)

func _logout() -> void:
	logout_action.disabled = true
	await _api_client.logout()
	get_tree().change_scene_to_file("res://scenes/LoginScreen.tscn")


func _layout_account_menu(viewport_size: Vector2) -> void:
	var safe := _safe_insets(viewport_size)
	var mobile := _is_mobile_layout(viewport_size)
	var panel_height := account_panel.get_combined_minimum_size().y
	
	if mobile:
		var safe_width := viewport_size.x - safe.x - safe.z
		var panel_width := minf(380.0, safe_width - 32.0)
		var panel_left := safe.x + (safe_width - panel_width) / 2.0
		var panel_top := safe.y + (viewport_size.y - safe.y - safe.w - panel_height) / 2.0
		account_panel.position = Vector2(panel_left, panel_top)
		account_panel.size = Vector2(panel_width, panel_height)
		account_panel.pivot_offset = Vector2(panel_width / 2.0, panel_height / 2.0)
	else:
		var safe_width := maxf(280.0, viewport_size.x - safe.x - safe.z)
		var panel_width := minf(370.0, safe_width - 24.0)
		var panel_left := viewport_size.x - safe.z - panel_width - 12.0
		var desired_top := profile_menu.global_position.y + profile_menu.size.y + 10.0
		var max_top := viewport_size.y - safe.w - panel_height - 12.0
		var panel_top := clampf(desired_top, safe.y + 8.0, maxf(safe.y + 8.0, max_top))
		account_panel.position = Vector2(panel_left, panel_top)
		account_panel.size = Vector2(panel_width, panel_height)
		account_panel.pivot_offset = Vector2(panel_width, 0)

func _is_mobile_layout(viewport_size: Vector2) -> bool:
	return (
		OS.has_feature("mobile")
		or OS.has_feature("android")
		or OS.has_feature("ios")
		or viewport_size.x < viewport_size.y
		or viewport_size.x < 768.0
	)

func _safe_insets(viewport_size: Vector2) -> Vector4:
	if not (OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")):
		return Vector4.ZERO
	var screen_size := DisplayServer.screen_get_size()
	var safe_area := DisplayServer.get_display_safe_area()
	if screen_size.x <= 0 or screen_size.y <= 0 or safe_area.size.x <= 0 or safe_area.size.y <= 0:
		return Vector4.ZERO
	var scale_x := viewport_size.x / float(screen_size.x)
	var scale_y := viewport_size.y / float(screen_size.y)
	var left := maxf(0.0, float(safe_area.position.x) * scale_x)
	var top := maxf(0.0, float(safe_area.position.y) * scale_y)
	var right := maxf(0.0, float(screen_size.x - safe_area.end.x) * scale_x)
	var bottom := maxf(0.0, float(screen_size.y - safe_area.end.y) * scale_y)
	return Vector4(left, top, right, bottom)

func _unhandled_input(event: InputEvent) -> void:
	if _account_menu_open and event.is_action_pressed("ui_cancel"):
		_close_account_menu()
		get_viewport().set_input_as_handled()

# ─── Roadmap Cards styling ───────────────────────────────────────────────────
func _create_level_7_card() -> void:
	card_level_7 = card_classical.duplicate() as PanelContainer
	card_level_7.name = "CardLevel7"
	roadmap_content.add_child(card_level_7)


func _create_level_8_card() -> void:
	card_level_8 = card_classical.duplicate() as PanelContainer
	card_level_8.name = "CardLevel8"
	roadmap_content.add_child(card_level_8)

func _build_roadmap_cards() -> void:
	var instrument := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
	var is_tranh := (instrument == "dan_tranh")
	
	# Main labels styling
	var font_title := load("res://assets/fonts/BeVietnamPro-Bold.ttf")
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
	var level_7_title := card_level_7.get_node("Margin/HBox/TextV/Title") as Label
	var level_7_desc := card_level_7.get_node("Margin/HBox/TextV/BulletList") as Label
	var level_8_title := card_level_8.get_node("Margin/HBox/TextV/Title") as Label
	var level_8_desc := card_level_8.get_node("Margin/HBox/TextV/BulletList") as Label
	
	var pop_chords_title := card_pop_chords.get_node("Margin/HBox/TextV/Title") as Label
	var pop_chords_desc := card_pop_chords.get_node("Margin/HBox/TextV/BulletList") as Label
	
	if font_title:
		basic_title.add_theme_font_override("font", font_title)
		ess_title.add_theme_font_override("font", font_title)
		soloist_unlock_title.add_theme_font_override("font", font_title)
		chords_unlock_title.add_theme_font_override("font", font_title)
		soloist_skills_title.add_theme_font_override("font", font_title)
		chords_skills_title.add_theme_font_override("font", font_title)
		classical_title.add_theme_font_override("font", font_title)
		level_7_title.add_theme_font_override("font", font_title)
		level_8_title.add_theme_font_override("font", font_title)
		pop_chords_title.add_theme_font_override("font", font_title)

	# Hiển thị lại các thẻ bị ẩn nếu chuyển về đàn tranh / sáo trúc
	card_soloist_unlock.show()
	card_chords_unlock.show()
	card_classical.show()
	card_level_7.hide()
	card_level_8.hide()
	path_soloist_title.show()
	path_chords_title.show()
	
	# Khôi phục vị trí gốc cho các nhánh
	card_soloist_skills.position = Vector2(1410, 95)
	card_chords_skills.position = Vector2(1410, 455)
	card_pop_chords.position = Vector2(1930, 455)

	if instrument == "dan_tranh":
		# Chỉ giữ lại các Level đang dùng trên lộ trình Đàn Tranh.
		card_soloist_unlock.hide()
		card_chords_unlock.hide()
		card_soloist_skills.hide()
		card_chords_skills.hide()
		card_classical.hide()
		card_pop_chords.hide()
		card_level_7.show()
		card_level_8.show()
		path_soloist_title.hide()
		path_chords_title.hide()
		
		card_level_7.position = Vector2(1060, 275)
		card_level_8.position = Vector2(1570, 275)
		_set_title_with_icon(roadmap_guide, "map", "Lộ trình học tập Đàn Tranh")
		
		basic_title.text = "LEVEL 1: NHẬP MÔN & LÀM QUEN"
		basic_desc.text = "Hiểu nhạc cụ, đọc giao diện nốt rơi và gảy những nốt cơ bản."
		# basic_details.text = "📖 3 Bài Học | ⭐ 0 Sao | 0% Hoàn Thành"
		
		ess_title.text = "LEVEL 2: KHÚC DẠO ĐẦU"
		ess_desc.text = "Chơi hoàn chỉnh bài nhạc đầu tiên với nhịp độ chậm."
		# ess_details.text = "📖 3 Bài Học | 🔒 Cần hoàn thành level trước"
		
		soloist_skills_title.text = "LEVEL 3: NHỊP ĐIỆU & TỐC ĐỘ"
		soloist_skills_bullets.text = "✓ Luyện ngón tốc độ cao – Mã Vũ\n✓ Dân ca Quan họ – Lý Cây Đa\n✓ Làm quen mật độ nốt dày hơn"
		
		chords_skills_title.text = "LEVEL 4: KỸ THUẬT NÂNG CAO"
		chords_skills_bullets.text = "✓ Mô phỏng kỹ thuật rung tay trái\n✓ Hòa tấu cùng nhạc cụ khác\n✓ Đánh đàn theo beat"
		
		pop_chords_title.text = "LEVEL 5: MASTER – NHẠC HIỆN ĐẠI"
		pop_chords_desc.text = "✓ Nhạc hiện đại: Sứ Thanh Hoa\n✓ Boss Stage sinh tồn\n✓ Biểu diễn không gợi ý"
		
		classical_title.text = "LEVEL 6: HỢP ÂM & HÒA ÂM"
		classical_desc.text = "✓ Lý thuyết & thế bấm hợp âm\n✓ Kỹ thuật gảy song âm & Arpeggio\n✓ Thực hành đệm hòa âm"
		level_7_title.text = "LEVEL 3: KỸ THUẬT NÂNG CAO"
		level_7_desc.text = "✓ Kỹ năng á – vuốt 17 dây\n✓ Nhấn, rung dây & song thanh\n✓ Demo hiệu ứng phản hồi sai"
		level_8_title.text = "LEVEL 4: KỸ THUẬT NÂNG CAO MỞ RỘNG"
		level_8_desc.text = "✓ Kỹ thuật Vê\n✓ Kỹ thuật đánh hợp âm ba ngón"
	elif instrument == "dan_bau":
		# Ẩn các node dư thừa để tạo 1 đường duy nhất cho Đàn Bầu
		card_soloist_unlock.hide()
		card_chords_unlock.hide()
		card_classical.hide()
		path_soloist_title.hide()
		path_chords_title.hide()
		
		# BẮT BUỘC ĐƯA CÁC THẺ VỀ CÙNG 1 ĐƯỜNG THẲNG NGANG (Y = 275)
		card_soloist_skills.position = Vector2(1060, 275)
		card_chords_skills.position = Vector2(1570, 275)
		card_pop_chords.position = Vector2(2080, 275)
		
		# Lộ trình Đàn Bầu
		_set_title_with_icon(roadmap_guide, "map", "Lộ trình học tập Đàn Bầu")
		basic_title.text = "LEVEL 1: NHẬP MÔN TẠO ÂM"
		basic_desc.text = "Nắm vững tư thế và cách tạo bồi âm chuẩn trên cơ chế 1 dây."
		# basic_details.text = "📖 2 Bài Học | ⭐ 4 Sao | 0% Hoàn Thành"
		
		ess_title.text = "LEVEL 2: LINH HỒN CỦA ĐÀN"
		ess_desc.text = "Dùng cần đàn (tay trái) để thay đổi cao độ và kỹ thuật căng dây."
		# ess_details.text = "📖 2 Bài Học | 🔒 Cần hoàn thành bài trước"
		
		soloist_unlock_title.text = "LEVEL 3"
		chords_unlock_title.text = "LEVEL 4"
		
		soloist_skills_title.text = "LEVEL 3: UYỂN CHUYỂN"
		soloist_skills_bullets.text = "✓ Làm chủ kỹ thuật chùng dây\n✓ Đẩy cần đàn về phía thân người\n✓ Bài hát: Lý Cây Đa"
		
		chords_skills_title.text = "LEVEL 4: KỸ THUẬT LUYẾN ÂM"
		chords_skills_bullets.text = "✓ Đánh các nốt luyến dài\n✓ Kỹ thuật Luyến 2 chiều\n✓ Bài hát: Cò Lả & Auld Lang Syne"
		
		classical_title.text = "LEVEL 5: HÒA TẤU & THỬ THÁCH MASTER"
		classical_desc.text = "✓ Biểu diễn như nghệ sĩ thực thụ\n✓ Nghệ thuật Hòa tấu (Ensemble)\n✓ Boss Stage: Biểu diễn bằng tai"
		
		pop_chords_title.text = "LEVEL 5: HÒA TẤU & THỬ THÁCH MASTER"
		pop_chords_desc.text = "✓ Biểu diễn như nghệ sĩ thực thụ\n✓ Chơi Lead cùng Backing Track\n✓ Boss Stage: Chứng nhận ảo"
	elif instrument == "trong_chau":
		_set_title_with_icon(roadmap_guide, "map", "Lộ trình học tập Trống Chầu")
	elif instrument == "sao_truc":
		_set_title_with_icon(roadmap_guide, "map", "Lộ trình học tập Sáo Trúc")
		# Lộ trình Sáo Trúc
		path_soloist_title.text = "🎵 ĐƯỜNG ĐỘC TẤU (SOLOIST PATH)"
		path_chords_title.text = "🎷 ĐƯỜNG HÒA TẤU (ENSEMBLE PATH)"
		# Lộ trình Sáo Trúc (Tuyến tính giống Đàn Bầu)
		card_soloist_unlock.hide()
		card_chords_unlock.hide()
		card_classical.hide()
		path_soloist_title.hide()
		path_chords_title.hide()
		
		# Ép thẻ về cùng Y = 275
		card_soloist_skills.position = Vector2(1060, 275)
		card_chords_skills.position = Vector2(1570, 275)
		card_pop_chords.position = Vector2(2080, 275)
		
		basic_title.text = "LEVEL 1: KHẨU HÌNH MÔI & TẠO ÂM"
		basic_desc.text = "Học đặt môi, lấy hơi bụng, cách bấm các lỗ sáo và thổi ra âm thanh tròn trịa."
		# basic_details.text = "📖 1 Bài Học | ⭐ 0 Sao | 0% Hoàn Thành"
		
		ess_title.text = "LEVEL 2: BẤM NGÓN & LẤY HƠI"
		ess_desc.text = "Tập bấm các nốt chuẩn thang âm sáo trúc và kiểm soát cột hơi ổn định."
		# ess_details.text = "📖 7 Bài Học | 🔒 Cần hoàn thành bài trước"
		
		soloist_skills_title.text = "LEVEL 3: KHÚC NHẠC VUI"
		soloist_skills_bullets.text = "✓ Thực hành từng khung nhạc\n✓ Luyện tập cách ghép câu\n✓ Hoàn thiện bài Khúc Nhạc Vui"
		
		chords_skills_title.text = "LEVEL 4: INH LẢ ƠI"
		chords_skills_bullets.text = "✓ Thực hành từng câu\n✓ Luyện tập chuyển ngón\n✓ Hoàn thiện bài Inh Lả Ơi"
		
		pop_chords_title.text = "LEVEL 5: FUTARI NO KIMOCHI"
		pop_chords_desc.text = "✓ Thực hành đoạn 1\n✓ Thực hành đoạn 2\n✓ Hoàn thiện bài Futari no Kimochi"

	# Dynamic progression styling for Card Basic (Node1 Video / Dan Bau Lesson 1-2)
	var is_basic_completed := false
	var basic_stars := 0
	var basic_pct := 0
	if instrument == "dan_tranh":
		var stats := _get_dan_tranh_level_status(1)
		is_basic_completed = stats["completed"]
		basic_stars = stats["stars"]
		basic_pct = stats["pct"]
	elif instrument == "dan_bau" or instrument == "sao_truc":
		var card_t = "basic"
		var stats := _get_dan_bau_card_status(card_t) if instrument == "dan_bau" else _get_sao_truc_card_status(card_t)
		is_basic_completed = stats["completed"]
		basic_stars = stats["stars"]
		basic_pct = stats["pct"]
	else:
		is_basic_completed = SecureDataManager.is_lesson_completed(instrument, "Node1")
		var stars_dict = SecureDataManager.data.get("stars", {})
		var inst_stars = stars_dict.get(instrument, {})
		basic_stars = inst_stars.get("Node1", 0)
		basic_pct = 100 if is_basic_completed else 0

	var basic_sb := _flat(C_CARD_BG, Color.WHITE, 24)
	basic_sb.border_width_left = 6; basic_sb.border_width_right = 6
	basic_sb.border_width_top = 6; basic_sb.border_width_bottom = 6
	basic_sb.shadow_size = 24; basic_sb.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35)
	card_basic.add_theme_stylebox_override("panel", basic_sb)
	basic_title.add_theme_color_override("font_color", C_CREAM)
	basic_desc.add_theme_color_override("font_color", C_CREAM_DIM)
	basic_details.add_theme_color_override("font_color", C_GOLD_LIGHT)
	if instrument == "dan_tranh":
		_set_details_text(basic_details, 9, basic_stars, basic_pct, false)
	elif instrument == "sao_truc":
		_set_details_text(basic_details, 1, basic_stars, basic_pct, false)
	elif instrument == "dan_bau":
		_set_details_text(basic_details, 2, basic_stars, basic_pct, false)
	else:
		if is_basic_completed:
			_set_details_text(basic_details, 2, basic_stars, 100, false)
		else:
			_set_details_text(basic_details, 2, 0, 0, false)

	# Dynamic progression styling for Card Essentials
	var is_ess_unlocked := is_basic_completed
	if not is_ess_unlocked:
		var ess_lock_sb := _flat(Color(1.0, 1.0, 1.0, 0.45), Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.55), 24)
		ess_lock_sb.border_width_left = 6; ess_lock_sb.border_width_right = 6
		ess_lock_sb.border_width_top = 6; ess_lock_sb.border_width_bottom = 6
		card_essentials.add_theme_stylebox_override("panel", ess_lock_sb)
		ess_title.add_theme_color_override("font_color", Color(0.43, 0.38, 0.33, 0.6))
		ess_desc.add_theme_color_override("font_color", Color(0.43, 0.38, 0.33, 0.4))
		ess_details.add_theme_color_override("font_color", Color(0.43, 0.38, 0.33, 0.6))
		if instrument == "dan_bau":
			_set_details_text(ess_details, 2, 0, 0, false)
		elif instrument == "sao_truc":
			_set_details_text(ess_details, 7, 0, 0, false)
		else:
			_set_details_text(ess_details, 6 if instrument == "dan_tranh" else 3, 0, 0, false)
	else:
		var ess_sb := _flat(C_CARD_BG_DK, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35), 24)
		ess_sb.border_width_left = 6; ess_sb.border_width_right = 6
		ess_sb.border_width_top = 6; ess_sb.border_width_bottom = 6
		card_essentials.add_theme_stylebox_override("panel", ess_sb)
		ess_title.add_theme_color_override("font_color", C_CREAM)
		ess_desc.add_theme_color_override("font_color", C_CREAM_DIM)
		ess_details.add_theme_color_override("font_color", C_GOLD_LIGHT)
		if instrument == "dan_tranh":
			var stats := _get_dan_tranh_level_status(2)
			_set_details_text(ess_details, 6, stats["stars"], stats["pct"], false)
		elif instrument == "sao_truc":
			var stats := _get_sao_truc_card_status("essentials")
			_set_details_text(ess_details, 7, stats["stars"], stats["pct"], false)
		elif instrument == "dan_bau":
			var stats := _get_dan_bau_card_status("essentials")
			_set_details_text(ess_details, 2, stats["stars"], stats["pct"], false)
		else:
			var stars_dict = SecureDataManager.data.get("stars", {})
			var inst_stars = stars_dict.get(instrument, {})
			var stars_n2: int = inst_stars.get("Node2", 0)
			var stars_n3: int = inst_stars.get("Node3", 0)
			var total_stars = stars_n2 + stars_n3
			var pct = 0.0
			if SecureDataManager.is_lesson_completed(instrument, "Node1"): pct += 50.0
			if SecureDataManager.is_lesson_completed(instrument, "Node3"): pct += 50.0
			_set_details_text(ess_details, 3, total_stars, int(pct), false)
	
	# Locked Cards (Soloist & Chords Unlock)
	var lock_sb := _flat(Color(1.0, 1.0, 1.0, 0.45), Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.55), 20)
	lock_sb.border_width_left = 6; lock_sb.border_width_right = 6
	lock_sb.border_width_top = 6; lock_sb.border_width_bottom = 6
	
	for card in [card_soloist_unlock, card_chords_unlock]:
		card.add_theme_stylebox_override("panel", lock_sb)
		var title := card.get_node("Margin/VBox/Title") as Label
		title.add_theme_color_override("font_color", Color(0.43, 0.38, 0.33, 1.0))
		
		# Buttons "MỞ KHÓA" - Dark outline on light card
		var btn := card.get_node("Margin/VBox/BtnUnlock") as Button
		var btn_sb := _flat(Color(0,0,0,0), Color(0.13, 0.08, 0.05, 0.30), 12)
		btn.add_theme_stylebox_override("normal", btn_sb)
		btn.add_theme_stylebox_override("hover", _flat(Color(0,0,0,0.06), Color(0.13, 0.08, 0.05, 0.60), 12))
		btn.add_theme_stylebox_override("pressed", _flat(Color(0,0,0,0.12), C_GOLD, 12))
		btn.add_theme_color_override("font_color", Color(0.13, 0.08, 0.05, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(0.13, 0.08, 0.05, 1.0))
		btn.add_theme_color_override("font_pressed_color", C_GOLD_DARK)
		btn.add_theme_font_size_override("font_size", 14)

	# Skills & End cards (partially master)
	var skills_sb := _flat(Color(1.0, 1.0, 1.0, 0.65), Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.55), 20)
	skills_sb.border_width_left = 6; skills_sb.border_width_right = 6
	skills_sb.border_width_top = 6; skills_sb.border_width_bottom = 6
	
	for card in [card_soloist_skills, card_chords_skills, card_classical, card_level_7, card_level_8, card_pop_chords]:
		card.add_theme_stylebox_override("panel", skills_sb)
		var title := card.get_node("Margin/HBox/TextV/Title") as Label
		var bullets := card.get_node("Margin/HBox/TextV/BulletList") as Label
		title.add_theme_color_override("font_color", C_RED_SON)
		bullets.add_theme_color_override("font_color", Color(0.13, 0.08, 0.05, 1.0))
		
		# Style circular play button (Vermilion red filled, gold border)
		var btn := card.get_node("Margin/HBox/BtnPlay") as Button
		_style_circular_play_btn(btn)
		
		var det := _ensure_details_label(card)
		if det:
			_set_details_text(det, 3, 0, 0, false)

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
	roadmap_content.mouse_filter = Control.MOUSE_FILTER_PASS
	var items := [card_basic, card_essentials, card_soloist_unlock, card_chords_unlock, card_soloist_skills, card_chords_skills, card_classical, card_level_7, card_level_8, card_pop_chords]
	var delay := 0.0
	for item in items:
		if not is_instance_valid(item): continue
		item.mouse_filter = Control.MOUSE_FILTER_PASS
		item.modulate.a = 0.0
		item.position.x += 40.0
		var t := create_tween().set_parallel(true)
		t.tween_property(item, "modulate:a", 1.0, 0.45).set_delay(delay)
		t.tween_property(item, "position:x", item.position.x - 40.0, 0.45).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		delay += 0.08

# ─── Sidebar drawer ───────────────────────────────────────────────────────────
func _toggle_sidebar() -> void:
	if _sidebar_expanded:
		_set_sidebar_expanded(false, true)
	else:
		_reveal_sidebar_from_menu()

func _reveal_sidebar_from_menu() -> void:
	if _sidebar_reveal_tween:
		_sidebar_reveal_tween.kill()
	if not _sidebar_dropdown:
		_set_sidebar_expanded(true, true)
		return

	var dropdown_width := minf(190.0, _sidebar_rail_width)
	_sidebar_dropdown.position = Vector2(_sidebar_safe_left + 8.0, btn_menu.global_position.y + btn_menu.size.y + 8.0)
	_sidebar_dropdown.size = Vector2(SIDEBAR_COLLAPSED_WIDTH, 0.0)
	_sidebar_dropdown.modulate.a = 0.0
	_sidebar_dropdown.show()

	_sidebar_reveal_tween = create_tween()
	_sidebar_reveal_tween.set_parallel(true)
	_sidebar_reveal_tween.tween_property(_sidebar_dropdown, "size", Vector2(dropdown_width, 42.0), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_sidebar_reveal_tween.tween_property(_sidebar_dropdown, "modulate:a", 1.0, 0.12)
	_sidebar_reveal_tween.set_parallel(false)
	_sidebar_reveal_tween.tween_interval(0.16)
	_sidebar_reveal_tween.tween_callback(func() -> void: _set_sidebar_expanded(true, true))
	_sidebar_reveal_tween.set_parallel(true)
	_sidebar_reveal_tween.tween_property(_sidebar_dropdown, "size:y", 0.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_sidebar_reveal_tween.tween_property(_sidebar_dropdown, "modulate:a", 0.0, 0.12)
	_sidebar_reveal_tween.set_parallel(false)
	_sidebar_reveal_tween.tween_callback(func() -> void: _sidebar_dropdown.hide())

func _set_sidebar_expanded(expanded: bool, animate: bool) -> void:
	if _sidebar_tween:
		_sidebar_tween.kill()
	_sidebar_expanded = expanded

	var rail_width := _sidebar_rail_width if expanded else SIDEBAR_COLLAPSED_WIDTH
	var sidebar_width := rail_width + _sidebar_safe_left
	var navigation := [btn_courses, btn_room, btn_songs, btn_minigame, btn_leaderboard]
	var top_spacer := $Root/Sidebar/SideM/SideV/TopSpacer as Control
	var bottom_spacer := $Root/Sidebar/SideM/SideV/BotSpacer as Control

	if expanded:
		if top_spacer: top_spacer.show()
		if bottom_spacer: bottom_spacer.show()
		for button: Button in navigation:
			button.show()

	if not animate:
		sidebar.custom_minimum_size.x = sidebar_width
		btn_menu.custom_minimum_size.x = rail_width
		btn_menu.custom_minimum_size.y = SIDEBAR_COLLAPSED_WIDTH if not expanded else (92.0 if _sidebar_rail_width <= 168.0 else 100.0)
		for button: Button in navigation:
			button.custom_minimum_size.x = rail_width
		_apply_menu_button_presentation(expanded)
		_apply_sidebar_panel_presentation(expanded)
		if not expanded:
			if top_spacer: top_spacer.hide()
			if bottom_spacer: bottom_spacer.hide()
			for button: Button in navigation:
				button.hide()
		return

	_sidebar_tween = create_tween().set_parallel(true)
	_sidebar_tween.tween_property(sidebar, "custom_minimum_size:x", sidebar_width, 0.28).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	_sidebar_tween.tween_property(btn_menu, "custom_minimum_size:x", rail_width, 0.28).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	for button: Button in navigation:
		_sidebar_tween.tween_property(button, "custom_minimum_size:x", rail_width, 0.28).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	_sidebar_tween.tween_property(btn_menu, "custom_minimum_size:y", SIDEBAR_COLLAPSED_WIDTH if not expanded else (92.0 if _sidebar_rail_width <= 168.0 else 100.0), 0.28).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	if expanded:
		_apply_menu_button_presentation(true)
		_apply_sidebar_panel_presentation(true)

	if not expanded:
		_sidebar_tween.set_parallel(false)
		_sidebar_tween.tween_callback(func() -> void:
			if top_spacer: top_spacer.hide()
			if bottom_spacer: bottom_spacer.hide()
			for button: Button in navigation:
				button.hide()
			_apply_menu_button_presentation(false)
			_apply_sidebar_panel_presentation(false)
		)

func _apply_menu_button_presentation(expanded: bool) -> void:
	var icon := btn_menu.get_node_or_null("IconDraw") as Control
	if expanded:
		if _menu_glass:
			_menu_glass.hide()
		_style_side_icon_btn(btn_menu, false)
		if icon:
			icon.anchors_preset = Control.PRESET_CENTER_TOP
			icon.anchor_left = 0.5; icon.anchor_right = 0.5
			icon.anchor_top = 0.0; icon.anchor_bottom = 0.0
			icon.offset_left = -40; icon.offset_right = 40
			icon.offset_top = 8; icon.offset_bottom = 64
		return

	var circle := _flat(Color(0, 0, 0, 0), Color(C_GOLD_LIGHT.r, C_GOLD_LIGHT.g, C_GOLD_LIGHT.b, 0.9), 32)
	circle.shadow_color = Color(0.04, 0.10, 0.06, 0.22)
	circle.shadow_size = 8
	circle.shadow_offset = Vector2(0, 3)
	btn_menu.add_theme_stylebox_override("normal", circle)
	btn_menu.add_theme_stylebox_override("hover", _flat(Color(1.0, 1.0, 1.0, 0.18), C_GOLD, 32))
	btn_menu.add_theme_stylebox_override("pressed", _flat(Color(0.91, 0.95, 0.91, 0.28), C_GOLD_DARK, 32))
	btn_menu.add_theme_stylebox_override("focus", _flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 32))
	btn_menu.add_theme_color_override("font_color", C_RED_SON)
	if icon:
		icon.anchors_preset = Control.PRESET_CENTER
		icon.anchor_left = 0.5; icon.anchor_right = 0.5
		icon.anchor_top = 0.5; icon.anchor_bottom = 0.5
		icon.offset_left = -14; icon.offset_right = 14
		icon.offset_top = -14; icon.offset_bottom = 14
	if _menu_glass:
		_menu_glass.show()
		call_deferred("_position_menu_glass")

func _position_menu_glass() -> void:
	if not _menu_glass or not _menu_glass.visible:
		return
	_menu_glass.anchors_preset = Control.PRESET_CENTER
	_menu_glass.anchor_left = 0.5; _menu_glass.anchor_right = 0.5
	_menu_glass.anchor_top = 0.5; _menu_glass.anchor_bottom = 0.5
	_menu_glass.offset_left = -SIDEBAR_COLLAPSED_WIDTH * 0.5
	_menu_glass.offset_right = SIDEBAR_COLLAPSED_WIDTH * 0.5
	_menu_glass.offset_top = -SIDEBAR_COLLAPSED_WIDTH * 0.5
	_menu_glass.offset_bottom = SIDEBAR_COLLAPSED_WIDTH * 0.5

func _apply_sidebar_panel_presentation(expanded: bool) -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.93, 0.91, 0.87, 0.6) if expanded else Color(0, 0, 0, 0)
	panel_style.border_color = Color(0.8, 0.78, 0.73, 0.8) if expanded else Color(0, 0, 0, 0)
	panel_style.border_width_right = 2 if expanded else 0
	panel_style.content_margin_right = 0
	sidebar.add_theme_stylebox_override("panel", panel_style)
	if _sidebar_blur:
		_sidebar_blur.visible = expanded

# ─── Connect Buttons ───────────────────────────────────────────────────────────
func _connect_buttons() -> void:
	btn_menu.pressed.connect(_toggle_sidebar)
	_make_btn_bouncy(btn_menu)
	btn_room.pressed.connect(func() -> void: _fade_to("res://scenes/VirtualMusicRoom.tscn"))
	btn_songs.pressed.connect(func() -> void:
		_fade_to("res://scenes/SongScreen.tscn")
	)
	btn_account.pressed.connect(_go_account)
	btn_minigame.pressed.connect(func() -> void: _fade_to("res://scenes/MiniGame.tscn"))
	btn_leaderboard.pressed.connect(_on_btn_leaderboard_pressed)
 
	for btn in [btn_courses, btn_room, btn_songs, btn_minigame, btn_account, btn_leaderboard]:
		_make_btn_bouncy(btn)
		btn.pressed.connect(func() -> void: _set_active_tab(btn))

	# Card Clicks
	card_basic.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
			var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
			if inst == "dan_tranh":
				DAN_TRANH_LESSON_SCRIPT.selected_level = 1
				_fade_to("res://scenes/LessonDanTranhList.tscn")
			elif inst == "dan_bau":
				LESSON_SCRIPT.selected_level = 1
				_fade_to("res://scenes/LessonDanBau.tscn")
			elif inst == "trong_chau":
				_fade_to("res://scenes/LessonTrongChau.tscn")
			elif inst == "sao_truc":
				SecureDataManager.active_lesson_id = "sao_truc_level1_1_video"
				SecureDataManager.data["custom_video_sequence"] = ["res://nvaore/intro1.ogv", "res://nvaore/intro2.ogv", "res://nvaore/intro3.ogv"]
				SecureDataManager.data["current_sequence_index"] = 0
				_fade_to("res://scenes/VideoPlayer.tscn")
			else:
				SecureDataManager.active_lesson_id = "Node1"
				_fade_to("res://scenes/VideoPlayer.tscn")
	)
	card_essentials.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
			var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
			if inst == "dan_tranh":
				DAN_TRANH_LESSON_SCRIPT.selected_level = 2
				_fade_to("res://scenes/LessonDanTranhList.tscn")
			elif inst == "dan_bau":
				LESSON_SCRIPT.selected_level = 2
				_fade_to("res://scenes/LessonDanBau.tscn")
			elif inst == "trong_chau":
				_fade_to("res://scenes/LessonTrongChau.tscn")
			elif inst == "sao_truc":
				var script = load("res://scripts/LessonSaoTrucList.gd")
				if script: script.selected_level = 2
				_fade_to("res://scenes/LessonSaoTrucList.tscn")
			else:
				var is_ess_unlocked := SecureDataManager.is_lesson_completed(inst, "Node1")
				if not is_ess_unlocked:
					_virtual_artist_play_happy("Bạn ơi, hãy xem xong video Hướng Dẫn ở bài Nhập Môn để mở khóa bài Luyện Tập nhé!")
					return
				if SecureDataManager.is_lesson_completed(inst, "Node1"):
					SecureDataManager.active_lesson_id = "Node3"
					_go_practice_room_for_node(3)
				else:
					SecureDataManager.active_lesson_id = "Node1"
					_go_practice_room_for_node(2)
	)
	
	card_soloist_skills.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
			var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
			if inst == "dan_tranh":
				DAN_TRANH_LESSON_SCRIPT.selected_level = 3
				_fade_to("res://scenes/LessonDanTranhList.tscn")
			elif inst == "sao_truc":
				var script = load("res://scripts/LessonSaoTrucList.gd")
				if script: script.selected_level = 3
				_fade_to("res://scenes/LessonSaoTrucList.tscn")
	)

	card_chords_skills.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
			var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
			if inst == "dan_tranh":
				DAN_TRANH_LESSON_SCRIPT.selected_level = 4
				_fade_to("res://scenes/LessonDanTranhList.tscn")
			elif inst == "sao_truc":
				var script = load("res://scripts/LessonSaoTrucList.gd")
				if script: script.selected_level = 4
				_fade_to("res://scenes/LessonSaoTrucList.tscn")
	)

	card_classical.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
			var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
			if inst == "dan_tranh":
				DAN_TRANH_LESSON_SCRIPT.selected_level = 6
				_fade_to("res://scenes/LessonDanTranhList.tscn")
			elif inst == "sao_truc":
				var script = load("res://scripts/LessonSaoTrucList.gd")
				if script: script.selected_level = 5
				_fade_to("res://scenes/LessonSaoTrucList.tscn")
	)
	card_level_7.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
			if str(SecureDataManager.data.get("selected_instrument", "dan_tranh")) == "dan_tranh":
				DAN_TRANH_LESSON_SCRIPT.selected_level = 7
				_fade_to("res://scenes/LessonDanTranhList.tscn")
	)
	card_level_8.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
			if str(SecureDataManager.data.get("selected_instrument", "dan_tranh")) == "dan_tranh":
				DAN_TRANH_LESSON_SCRIPT.selected_level = 8
				_fade_to("res://scenes/LessonDanTranhList.tscn")
	)

	card_pop_chords.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
			var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
			if inst == "dan_tranh":
				DAN_TRANH_LESSON_SCRIPT.selected_level = 5
				_fade_to("res://scenes/LessonDanTranhList.tscn")
			elif inst == "sao_truc":
				var script = load("res://scripts/LessonSaoTrucList.gd")
				if script: script.selected_level = 5
				_fade_to("res://scenes/LessonSaoTrucList.tscn")
	)
	
	# Play Buttons -> Practice Room
	var play_soloist := card_soloist_skills.get_node("Margin/HBox/BtnPlay") as Button
	play_soloist.pressed.connect(func() -> void:
		var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
		if inst == "dan_tranh":
			DAN_TRANH_LESSON_SCRIPT.selected_level = 3
			_fade_to("res://scenes/LessonDanTranhList.tscn")
		elif inst == "dan_bau":
			LESSON_SCRIPT.selected_level = 3
			_fade_to("res://scenes/LessonDanBau.tscn")
		elif inst == "trong_chau":
			_fade_to("res://scenes/LessonTrongChau.tscn")
		elif inst == "sao_truc":
			var script = load("res://scripts/LessonSaoTrucList.gd")
			if script: script.selected_level = 3
			_fade_to("res://scenes/LessonSaoTrucList.tscn")
		else:
			SecureDataManager.active_lesson_id = "Node4"
			_go_practice_room_for_node(4)
	)
	_make_btn_bouncy(play_soloist)
	
	var play_chords := card_chords_skills.get_node("Margin/HBox/BtnPlay") as Button
	play_chords.pressed.connect(func() -> void:
		var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
		if inst == "dan_tranh":
			DAN_TRANH_LESSON_SCRIPT.selected_level = 4
			_fade_to("res://scenes/LessonDanTranhList.tscn")
		elif inst == "dan_bau":
			LESSON_SCRIPT.selected_level = 4
			_fade_to("res://scenes/LessonDanBau.tscn")
		elif inst == "trong_chau":
			_fade_to("res://scenes/LessonTrongChau.tscn")
		elif inst == "sao_truc":
			var script = load("res://scripts/LessonSaoTrucList.gd")
			if script: script.selected_level = 4
			_fade_to("res://scenes/LessonSaoTrucList.tscn")
		else:
			_go_practice()
	)
	_make_btn_bouncy(play_chords)

	var play_classical := card_classical.get_node("Margin/HBox/BtnPlay") as Button
	play_classical.pressed.connect(func() -> void:
		var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
		if inst == "dan_tranh":
			DAN_TRANH_LESSON_SCRIPT.selected_level = 6
			_fade_to("res://scenes/LessonDanTranhList.tscn")
		elif inst == "dan_bau":
			LESSON_SCRIPT.selected_level = 5
			_fade_to("res://scenes/LessonDanBau.tscn")
		elif inst == "trong_chau":
			_fade_to("res://scenes/LessonTrongChau.tscn")
		elif inst == "sao_truc":
			var script = load("res://scripts/LessonSaoTrucList.gd")
			if script: script.selected_level = 5
			_fade_to("res://scenes/LessonSaoTrucList.tscn")
		else:
			_go_practice()
	)
	_make_btn_bouncy(play_classical)

	var play_level_7 := card_level_7.get_node("Margin/HBox/BtnPlay") as Button
	play_level_7.pressed.connect(func() -> void:
		if str(SecureDataManager.data.get("selected_instrument", "dan_tranh")) == "dan_tranh":
			DAN_TRANH_LESSON_SCRIPT.selected_level = 7
			_fade_to("res://scenes/LessonDanTranhList.tscn")
	)
	_make_btn_bouncy(play_level_7)

	var play_level_8 := card_level_8.get_node("Margin/HBox/BtnPlay") as Button
	play_level_8.pressed.connect(func() -> void:
		if str(SecureDataManager.data.get("selected_instrument", "dan_tranh")) == "dan_tranh":
			DAN_TRANH_LESSON_SCRIPT.selected_level = 8
			_fade_to("res://scenes/LessonDanTranhList.tscn")
	)
	_make_btn_bouncy(play_level_8)
	
	var play_pop := card_pop_chords.get_node("Margin/HBox/BtnPlay") as Button
	play_pop.pressed.connect(func() -> void:
		var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
		if inst == "dan_tranh":
			DAN_TRANH_LESSON_SCRIPT.selected_level = 5
			_fade_to("res://scenes/LessonDanTranhList.tscn")
		elif inst == "dan_bau":
			LESSON_SCRIPT.selected_level = 5
			_fade_to("res://scenes/LessonDanBau.tscn")
		elif inst == "trong_chau":
			_fade_to("res://scenes/LessonTrongChau.tscn")
		elif inst == "sao_truc":
			var script = load("res://scripts/LessonSaoTrucList.gd")
			if script: script.selected_level = 5
			_fade_to("res://scenes/LessonSaoTrucList.tscn")
		else:
			_go_practice()
	)
	_make_btn_bouncy(play_pop)

	# Unlock Buttons -> Virtual Artist Mai popup
	var unlock_sol := card_soloist_unlock.get_node("Margin/VBox/BtnUnlock") as Button
	unlock_sol.pressed.connect(func() -> void:
		_virtual_artist_play_happy("Chúc mừng! Bạn đã tích lũy đủ XP để mở khóa con đường Độc Tấu.")
	)
	_make_btn_bouncy(unlock_sol)

	var unlock_cho := card_chords_unlock.get_node("Margin/VBox/BtnUnlock") as Button
	unlock_cho.pressed.connect(func() -> void:
		_virtual_artist_play_happy("Chúc mừng! Bạn đã sẵn sàng mở khóa con đường Hợp Âm.")
	)
	_make_btn_bouncy(unlock_cho)

	avatar_circle.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and not e.pressed and e.button_index == MOUSE_BUTTON_LEFT: _go_account()
	)

	# Mobile Navigation Connections
	btn_room_mob.pressed.connect(func() -> void: _fade_to("res://scenes/VirtualMusicRoom.tscn"))
	btn_songs_mob.pressed.connect(func() -> void:
		_fade_to("res://scenes/SongScreen.tscn")
	)
	btn_account_mob.pressed.connect(_go_account)
	btn_minigame_mob.pressed.connect(func() -> void: _fade_to("res://scenes/MiniGame.tscn"))
	btn_leaderboard_mob.pressed.connect(_on_btn_leaderboard_pressed)
 
	for btn in [btn_courses_mob, btn_room_mob, btn_songs_mob, btn_minigame_mob, btn_account_mob, btn_leaderboard_mob]:
		_make_btn_bouncy(btn)
		btn.pressed.connect(func() -> void: _set_active_tab(btn))

func _set_active_tab(active: Button) -> void:
	var all : Array[Button] = [btn_courses, btn_room, btn_songs, btn_minigame, btn_account, btn_leaderboard]
	var active_desktop : Button = null
	if active == btn_courses or active == btn_courses_mob: active_desktop = btn_courses
	elif active == btn_room or active == btn_room_mob: active_desktop = btn_room
	elif active == btn_songs or active == btn_songs_mob: active_desktop = btn_songs
	elif active == btn_minigame or active == btn_minigame_mob: active_desktop = btn_minigame
	elif active == btn_leaderboard or active == btn_leaderboard_mob: active_desktop = btn_leaderboard
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
func _virtual_artist_play_happy(text: String) -> void:
	var artist := get_node_or_null("/root/VirtualArtist")
	if artist and artist.has_method("play_happy"):
		artist.call("play_happy", text)

func _go_practice() -> void:
	var instrument : String = SecureDataManager.data.get("selected_instrument", "dan_tranh")
	if instrument == "dan_tranh":
		_fade_to("res://scenes/PracticeRoom.tscn")
	elif instrument == "dan_bau":
		_fade_to("res://scenes/PracticeDanBau.tscn")
	elif instrument == "trong_chau":
		_fade_to("res://scenes/PracticeTrongChau.tscn")
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
	elif inst == "trong_chau":
		var script = load("res://scripts/PracticeTrongChau.gd")
		var sheet: Array[String] = []
		if node_index == 2:
			script.current_song_title = "Nhịp Trống Cơ Bản"
			sheet.assign(["Tịch", "Tịch", "Cắc", "Tịch", "Tịch", "Cắc"])
		elif node_index == 3:
			script.current_song_title = "Tiếng Cắc Vành Gỗ"
			sheet.assign(["Tịch", "Cắc", "Cắc", "Tịch", "Cắc", "Cắc", "Tịch"])
		elif node_index == 4:
			script.current_song_title = "Liên Khúc Trống Chầu"
			sheet.assign(["Tịch", "Cắc", "Tịch", "Cắc", "Tịch", "Cắc", "Tịch", "Cắc"])
		script.current_song_sheet = sheet
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
	elif inst == "trong_chau":
		path = "res://scenes/PracticeTrongChau.tscn"
	else:
		path = "res://scenes/PracticeSaoTruc.tscn"
		
	_fade_to(path)

func _go_instruments() -> void: _fade_to("res://scenes/InstrumentSelect.tscn")
func _go_progress()    -> void: _fade_to("res://scenes/ProgressScreen.tscn")
func _go_account()     -> void: _fade_to("res://scenes/AccountScreen.tscn")
func _go_settings()    -> void: _fade_to("res://scenes/AccountSettings.tscn")

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
	var viewport_size: Vector2 = get_viewport_rect().size
	var is_mobile := _is_mobile_layout(viewport_size)
	var safe := _safe_insets(viewport_size)
	var compact_profile := false
	var safe_left := minf(safe.x, 104.0) if is_mobile else 0.0
	var rail_width := 168.0 if is_mobile else 220.0
	_sidebar_rail_width = rail_width
	_sidebar_safe_left = safe_left

	# Landscape navigation remains on the left; safe padding keeps controls clear
	# of Dynamic Island and rounded display corners.
	sidebar.visible = true
	bottom_bar.visible = false
	side_margin.add_theme_constant_override("margin_left", int(safe_left))
	side_margin.add_theme_constant_override("margin_right", 0)
	side_margin.add_theme_constant_override("margin_top", int(safe.y + 20.0) if is_mobile else 32)
	side_margin.add_theme_constant_override("margin_bottom", int(safe.w + 20.0) if is_mobile else 32)
	var side_button_height := 92.0 if is_mobile else 100.0
	for button: Button in [btn_menu, btn_courses, btn_room, btn_songs, btn_minigame, btn_leaderboard, btn_account]:
		button.custom_minimum_size.y = side_button_height
		button.add_theme_font_size_override("font_size", 18 if is_mobile else 22)
	$Root/Sidebar/SideM/SideV/TopSpacer.custom_minimum_size.y = 14.0 if is_mobile else 32.0
	_set_sidebar_expanded(_sidebar_expanded, false)
	
	# Responsive profile button styling
	var radius := 35
	var trigger_style := _flat(Color(1.0, 1.0, 1.0, 0.65), Color(C_GOLD_LIGHT.r, C_GOLD_LIGHT.g, C_GOLD_LIGHT.b, 0.6), radius)
	trigger_style.shadow_color = Color(0.04, 0.10, 0.06, 0.18)
	trigger_style.shadow_size = 10
	trigger_style.shadow_offset = Vector2(0, 4)
	profile_menu.add_theme_stylebox_override("panel", trigger_style)

	var trigger_m := profile_menu.get_node_or_null("TriggerM") as MarginContainer

	trigger_copy.visible = false
	trigger_chevron.visible = false
	profile_menu.custom_minimum_size = Vector2(70, 70)
	profile_menu.size = Vector2(70, 70)
	if trigger_m:
		trigger_m.add_theme_constant_override("margin_left", 0)
		trigger_m.add_theme_constant_override("margin_right", 0)
		trigger_m.add_theme_constant_override("margin_top", 0)
		trigger_m.add_theme_constant_override("margin_bottom", 0)

	top_bar.custom_minimum_size.y = (76.0 + safe.y) if is_mobile else 96.0
	top_bar.add_theme_constant_override("margin_top", int(safe.y + 10.0) if is_mobile else 16)
	top_bar.add_theme_constant_override("margin_bottom", 8)

	# TopBar scaling
	if is_mobile:
		top_bar.add_theme_constant_override("margin_left", 14)
		top_bar.add_theme_constant_override("margin_right", int(safe.z + 12.0))
		bottom_margin.add_theme_constant_override("margin_left", 16)
		bottom_margin.add_theme_constant_override("margin_right", 16)
		bottom_margin.add_theme_constant_override("margin_bottom", 0)
		bottom_bar.custom_minimum_size.y = 80.0
		sp_label.add_theme_font_size_override("font_size", 14)
		xp_label.add_theme_font_size_override("font_size", 14)
		streak_pill.get_node("SPMargin").add_theme_constant_override("margin_left", 12)
		streak_pill.get_node("SPMargin").add_theme_constant_override("margin_right", 12)
		xp_pill.get_node("XPMargin").add_theme_constant_override("margin_left", 12)
		xp_pill.get_node("XPMargin").add_theme_constant_override("margin_right", 12)
	else:
		top_bar.add_theme_constant_override("margin_left", 40)
		top_bar.add_theme_constant_override("margin_right", 40)
		bottom_margin.add_theme_constant_override("margin_left", 16)
		bottom_margin.add_theme_constant_override("margin_right", 16)
		bottom_margin.add_theme_constant_override("margin_bottom", 0)
		bottom_bar.custom_minimum_size.y = 80.0
		sp_label.add_theme_font_size_override("font_size", 18)
		xp_label.add_theme_font_size_override("font_size", 18)
		streak_pill.get_node("SPMargin").add_theme_constant_override("margin_left", 22)
		streak_pill.get_node("SPMargin").add_theme_constant_override("margin_right", 22)
		xp_pill.get_node("XPMargin").add_theme_constant_override("margin_left", 22)
		xp_pill.get_node("XPMargin").add_theme_constant_override("margin_right", 22)

	var overlay_alpha := 0.22 if is_mobile else 0.10
	dismiss_button.add_theme_stylebox_override("normal", _flat(Color(0.01, 0.04, 0.025, overlay_alpha), Color.TRANSPARENT, 0))
	dismiss_button.add_theme_stylebox_override("hover", _flat(Color(0.01, 0.04, 0.025, overlay_alpha), Color.TRANSPARENT, 0))
	dismiss_button.add_theme_stylebox_override("pressed", _flat(Color(0.01, 0.04, 0.025, overlay_alpha + 0.04), Color.TRANSPARENT, 0))
		
	# Cards scaling
	# Card content has a real minimum width of 460px. Using a smaller layout
	# step made neighboring cards overlap even though custom_minimum_size changed.
	var card_w: float = 460.0
	var un_card_w: float = 280.0
	var gap: float = 34.0 if is_mobile else 90.0
	
	var x_basic: float = 28.0 if is_mobile else 40.0
	var instrument: String = str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
	
	var y_top: float = 40.0 if is_mobile else 95.0
	var y_mid: float = 180.0 if is_mobile else 275.0
	var y_bot: float = 320.0 if is_mobile else 455.0
	var roadmap_h: float = 520.0 if is_mobile else 760.0
	var x_un: float = 0.0
	
	if instrument == "dan_bau" or instrument == "sao_truc" or instrument == "trong_chau" or instrument == "dan_tranh":
		var x_ess: float = x_basic + card_w + gap
		var x_sk: float = x_ess + card_w + gap
		var x_ch: float = x_sk + card_w + gap
		var x_pop: float = x_ch + card_w + gap
		var x_class: float = x_pop + card_w + gap
		var x_level_7: float = x_class + card_w + gap
		x_un = x_ess + card_w + gap # Not really used in straight layout, but set for safety
		
		var total_w: float = x_ch + card_w + 40.0 if instrument == "dan_tranh" else x_pop + card_w + 40.0
		roadmap_content.custom_minimum_size = Vector2(total_w, roadmap_h)
		
		card_basic.position = Vector2(x_basic, y_mid)
		card_basic.custom_minimum_size = Vector2(card_w, card_basic.custom_minimum_size.y)
		
		card_essentials.position = Vector2(x_ess, y_mid)
		card_essentials.custom_minimum_size = Vector2(card_w, card_essentials.custom_minimum_size.y)
		
		card_soloist_skills.position = Vector2(x_sk, y_mid)
		card_soloist_skills.custom_minimum_size = Vector2(card_w, card_soloist_skills.custom_minimum_size.y)
		
		card_chords_skills.position = Vector2(x_ch, y_mid)
		card_chords_skills.custom_minimum_size = Vector2(card_w, card_chords_skills.custom_minimum_size.y)
		
		card_pop_chords.position = Vector2(x_ch, y_mid) if instrument == "dan_tranh" else Vector2(x_pop, y_mid)
		card_pop_chords.custom_minimum_size = Vector2(card_w, card_pop_chords.custom_minimum_size.y)
		
		card_classical.position = Vector2(x_class, y_mid)
		card_classical.custom_minimum_size = Vector2(card_w, card_classical.custom_minimum_size.y)
		card_level_7.position = Vector2(x_sk, y_mid) if instrument == "dan_tranh" else Vector2(x_class, y_mid)
		card_level_7.custom_minimum_size = Vector2(card_w, card_level_7.custom_minimum_size.y)
		card_level_8.position = Vector2(x_ch, y_mid) if instrument == "dan_tranh" else Vector2(x_level_7, y_mid)
		card_level_8.custom_minimum_size = Vector2(card_w, card_level_8.custom_minimum_size.y)
	else:
		var x_ess: float = x_basic + card_w + gap
		x_un = x_ess + card_w + gap
		var x_sk: float = x_un + un_card_w + gap
		var x_end: float = x_sk + card_w + gap
		var total_w: float = 2590.0 + card_w + 120.0
		
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
	if _account_menu_open:
		call_deferred("_relayout_open_account_menu")

func _relayout_open_account_menu() -> void:
	if _account_menu_open:
		_layout_account_menu(get_viewport_rect().size)

# ─── Dan Tranh Level Progress ─────────────────────────────────────────────────
func _get_dan_tranh_level_status(level_number: int) -> Dictionary:
	var completed: Array = SecureDataManager.data.get("completed_lessons", {}).get("dan_tranh", [])
	var stars: Dictionary = SecureDataManager.data.get("stars", {}).get("dan_tranh", {})
	var level_data: Dictionary = DAN_TRANH_LESSON_SCRIPT.get_level_data(level_number)
	var step_ids: Array[String] = []
	for lesson_value in level_data["lessons"]:
		var lesson: Dictionary = lesson_value
		var lesson_number := int(lesson["number"])
		var prefix := "dan_tranh_level_%d_bai_%d_" % [level_number, lesson_number]
		if str(lesson["video"]) != "":
			step_ids.append(prefix + "video")
		step_ids.append(prefix + "practice")
	var completed_count := 0
	var total_stars := 0
	for step_id in step_ids:
		if completed.has(step_id):
			completed_count += 1
			total_stars += int(stars.get(step_id, 0))
	var pct := 0
	if not step_ids.is_empty():
		pct = int(float(completed_count) / float(step_ids.size()) * 100.0)
	return {
		"completed": completed_count == step_ids.size(),
		"stars": total_stars,
		"pct": pct
	}

# ─── Dan Bau Custom Progression & Content Handling ─────────────────────────────
const LESSON_SCRIPT = preload("res://scripts/LessonDanBau.gd")

func _get_dan_bau_card_status(card_type: String) -> Dictionary:
	var completed : Array = SecureDataManager.data.get("completed_lessons", {}).get("dan_bau", [])
	var stars_dict : Dictionary = SecureDataManager.data.get("stars", {}).get("dan_bau", {})
	
	var total_stars := 0
	var completed_count := 0
	var total_count := 2
	
	var steps_to_check := []
	if card_type == "basic":
		steps_to_check = ["dan_bau_level1_bai1_video"]
	elif card_type == "essentials":
		steps_to_check = ["dan_bau_level2_bai1_practice", "dan_bau_level2_bai2_practice", "dan_bau_level2_bai3_practice", "dan_bau_level2_bai4_practice", "dan_bau_level2_bai5_practice"]
	elif card_type == "soloist":
		steps_to_check = ["dan_bau_level3_bai1_practice", "dan_bau_level3_bai2_practice", "dan_bau_level3_bai3_practice", "dan_bau_level3_bai4_practice", "dan_bau_level3_bai5_practice"]
	elif card_type == "chords":
		steps_to_check = ["dan_bau_level4_bai1_practice", "dan_bau_level4_bai2_practice", "dan_bau_level4_bai3_practice", "dan_bau_level4_bai4_practice", "dan_bau_level4_bai5_practice"]
	elif card_type == "classical" or card_type == "pop_chords":
		steps_to_check = ["dan_bau_level5_bai1_practice", "dan_bau_level5_bai2_practice", "dan_bau_level5_bai3_practice", "dan_bau_level5_bai4_practice", "dan_bau_level5_bai5_practice"]
		
	for step in steps_to_check:
		if completed.has(step):
			completed_count += 1
		total_stars += stars_dict.get(step, 0)
		
	total_count = steps_to_check.size()
	var pct = 0
	if total_count > 0:
		pct = int((float(completed_count) / float(total_count)) * 100.0)
	return {"stars": total_stars, "pct": pct, "completed": completed_count == total_count}

func _play_dan_bau_video(lesson_idx: int) -> void:
	var lessons_data = LESSON_SCRIPT.LEVELS[0]["lessons"]
	if lesson_idx >= 0 and lesson_idx < lessons_data.size():
		var ldata = lessons_data[lesson_idx]
		SecureDataManager.active_lesson_id = ldata["id"]
		VideoPlayer.custom_video_path = "res://Video/coMai_danBau.ogv"
		VideoPlayer.custom_subtitles = ldata.get("subtitles", [])
		_fade_to("res://scenes/VideoPlayer.tscn")

func _play_dan_bau_practice(lesson_num: int) -> void:
	SecureDataManager.active_lesson_id = "dan_bau_coban_" + str(lesson_num) + "_practice"
	_fade_to("res://scenes/PracticeDanBau.tscn")

func _ensure_details_label(card: Control) -> Label:
	var text_v = card.get_node_or_null("Margin/Row/TextV")
	if not text_v:
		text_v = card.get_node_or_null("Margin/HBox/TextV")
	if not text_v:
		return null
		
	var details = text_v.get_node_or_null("Details") as Label
	if not details:
		details = Label.new()
		details.name = "Details"
		details.custom_minimum_size = Vector2(310, 0)
		details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		details.add_theme_font_size_override("font_size", 16)
		text_v.add_child(details)
	
	details.add_theme_color_override("font_color", Color(0.43, 0.38, 0.33, 1.0))
	return details

func _set_details_text(lbl: Label, n_lessons: int, stars: int, pct: int, is_locked: bool) -> void:
	for child in lbl.get_children():
		child.queue_free()
	lbl.text = ""
	
	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 6)
	hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	
	var add_item = func(icon_name: String, text: String, add_divider: bool = true):
		var tex = TextureRect.new()
		var texture = load("res://assets/textures/lucide/" + icon_name + ".svg") as Texture2D
		tex.texture = texture
		tex.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.custom_minimum_size = Vector2(18, 18)
		tex.modulate = lbl.get_theme_color("font_color")
		hbox.add_child(tex)
		
		var t = Label.new()
		t.text = text
		t.add_theme_font_size_override("font_size", lbl.get_theme_font_size("font_size"))
		t.add_theme_color_override("font_color", lbl.get_theme_color("font_color"))
		if lbl.has_theme_font_override("font"):
			t.add_theme_font_override("font", lbl.get_theme_font("font"))
		hbox.add_child(t)
		
		if add_divider:
			var div = Label.new()
			div.text = " | "
			div.add_theme_font_size_override("font_size", lbl.get_theme_font_size("font_size"))
			div.add_theme_color_override("font_color", lbl.get_theme_color("font_color"))
			if lbl.has_theme_font_override("font"):
				div.add_theme_font_override("font", lbl.get_theme_font("font"))
			hbox.add_child(div)
			
	add_item.call("book-open", str(n_lessons) + " Bài Học", true)
	if is_locked:
		add_item.call("lock", "Cần hoàn thành bài trước", false)
	else:
		add_item.call("star", str(stars) + " Sao", true)
		if pct >= 100:
			add_item.call("check-circle", "100% Hoàn Thành", false)
		else:
			add_item.call("circle", str(pct) + "% Hoàn Thành", false)
			
	lbl.add_child(hbox)

func _set_title_with_icon(lbl: Label, icon_name: String, text: String) -> void:
	for child in lbl.get_children():
		child.queue_free()
	lbl.text = ""
	
	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 10)
	hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	
	var tex = TextureRect.new()
	var texture = load("res://assets/textures/lucide/" + icon_name + ".svg") as Texture2D
	tex.texture = texture
	tex.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.custom_minimum_size = Vector2(28, 28)
	tex.modulate = lbl.get_theme_color("font_color")
	hbox.add_child(tex)
	
	var t = Label.new()
	t.text = text
	if lbl.has_theme_font_size_override("font_size"):
		t.add_theme_font_size_override("font_size", lbl.get_theme_font_size("font_size"))
	if lbl.has_theme_color_override("font_color"):
		t.add_theme_color_override("font_color", lbl.get_theme_color("font_color"))
	if lbl.has_theme_font_override("font"):
		t.add_theme_font_override("font", lbl.get_theme_font("font"))
	hbox.add_child(t)
	
	lbl.add_child(hbox)
# ─── Sáo Trúc Custom Progression ──────────────────────────────────────────────────
func _get_sao_truc_card_status(card_type: String) -> Dictionary:
	var completed : Array = SecureDataManager.data.get("completed_lessons", {}).get("sao_truc", [])
	var stars_dict : Dictionary = SecureDataManager.data.get("stars", {}).get("sao_truc", {})
	
	var total_stars := 0
	var completed_count := 0
	var total_count := 2
	
	var steps_to_check := []
	if card_type == "basic":
		steps_to_check = ["sao_truc_level1_1_video"]
	elif card_type == "essentials":
		steps_to_check = ["Node1", "Node2", "Node3", "Node4", "Node5", "Node6", "Node7", "Node8"]
	elif card_type == "soloist":
		steps_to_check = ["sao_truc_level3_1", "sao_truc_level3_2"]
	elif card_type == "chords":
		steps_to_check = ["sao_truc_level4_1", "sao_truc_level4_2"]
	elif card_type == "classical" or card_type == "pop_chords":
		steps_to_check = ["sao_truc_level5_1", "sao_truc_level5_2"]
		
	total_count = steps_to_check.size()
	if total_count == 0: total_count = 1
		
	for step in steps_to_check:
		if completed.has(step):
			completed_count += 1
		total_stars += stars_dict.get(step, 0)
		
	var pct := 0
	if total_count > 0:
		pct = int((float(completed_count) / float(total_count)) * 100.0)
	return {"stars": total_stars, "pct": pct, "completed": completed_count == total_count}

func _on_btn_leaderboard_pressed() -> void:
	_fade_to("res://scenes/LeaderboardScreen.tscn")
