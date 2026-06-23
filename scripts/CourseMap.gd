extends Control

class_name CourseMap

# ─── Colors ───────────────────────────────────────────────────────────────────
const C_BG_DARK     := Color(0.98, 0.97, 0.94, 1.0) # #FAF8F5 - warm cream background
const C_RED_SON     := Color(0.09, 0.27, 0.18, 1.0) # premium deep jade green
const C_RED_SON_DK  := Color(0.95, 0.93, 0.89, 1.0) # #F3EFE3 - warm cream for panels/sidebar
const C_GOLD        := Color(0.77, 0.58, 0.15, 1.0) # gold
const C_GOLD_LIGHT  := Color(0.92, 0.76, 0.30, 1.0)
const C_JADE        := Color(0.12, 0.37, 0.23, 1.0) # bamboo jade
const C_JADE_LIGHT  := Color(0.25, 0.65, 0.45, 1.0)
const C_CREAM       := Color(1.00, 0.97, 0.88, 1.0)
const C_CREAM_DIM   := Color(0.80, 0.76, 0.66, 1.0)
const C_LOCKED      := Color(0.92, 0.90, 0.86, 1.0) # light warm cream-gray for locked nodes

# ─── Static Progress State ────────────────────────────────────────────────────
static var video_completed := false
static var active_lesson_id := "Node2"

# ─── Refs ───
@onready var course_title : Label         = $RootHBox/RightContent/TopBar/TopM/TopH/CourseTitle
@onready var btn_menu     : Button        = $RootHBox/LeftSidebar/SideM/SideV/BtnMenu
@onready var btn_courses  : Button        = $RootHBox/LeftSidebar/SideM/SideV/BtnCourses
@onready var btn_room     : Button        = $RootHBox/LeftSidebar/SideM/SideV/BtnRoom
@onready var btn_songs    : Button        = $RootHBox/LeftSidebar/SideM/SideV/BtnSongs
@onready var btn_account  : Button        = $RootHBox/LeftSidebar/SideM/SideV/BtnAccount
@onready var map_hbox     : HBoxContainer = $RootHBox/RightContent/MapScroll/ScrollM/MapHBox

@onready var bottom_bar      : PanelContainer = $RootHBox/RightContent/BottomBar
@onready var btn_courses_mob : Button         = $RootHBox/RightContent/BottomBar/BottomM/BottomH/BtnCoursesMobile
@onready var btn_room_mob    : Button         = $RootHBox/RightContent/BottomBar/BottomM/BottomH/BtnRoomMobile
@onready var btn_songs_mob   : Button         = $RootHBox/RightContent/BottomBar/BottomM/BottomH/BtnSongsMobile
@onready var btn_account_mob : Button         = $RootHBox/RightContent/BottomBar/BottomM/BottomH/BtnAccountMobile

var _active_side_btn : Button = null
var _pulse_time := 0.0
var _sidebar_icons_cache := {}
var btn_minigame : Button
var btn_minigame_mob : Button


func _ready() -> void:
	SecureDataManager.load_data()
	
	# Programmatic instantiation of MiniGame button
	var side_v := $RootHBox/LeftSidebar/SideM/SideV as VBoxContainer
	btn_minigame = Button.new()
	btn_minigame.name = "BtnMiniGame"
	btn_minigame.text = "Mini-game"
	btn_minigame.flat = true
	btn_minigame.custom_minimum_size = Vector2(220, 140)
	side_v.add_child(btn_minigame)
	side_v.move_child(btn_minigame, 5) # after BtnSongs (index 4)

	var bottom_h := $RootHBox/RightContent/BottomBar/BottomM/BottomH as HBoxContainer
	btn_minigame_mob = Button.new()
	btn_minigame_mob.name = "BtnMiniGameMobile"
	btn_minigame_mob.text = "Mini-game"
	btn_minigame_mob.flat = true
	btn_minigame_mob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_h.add_child(btn_minigame_mob)
	bottom_h.move_child(btn_minigame_mob, 3) # after BtnSongsMobile (index 2)

	# Sync video_completed progress with SecureDataManager
	if CourseMap.video_completed:
		var inst := InstrumentSelect.selected_instrument
		if not SecureDataManager.is_lesson_completed(inst, "Node1"):
			SecureDataManager.complete_lesson(inst, "Node1", 3)
			
	# Hide or remove the default ColorRect to draw canvas backdrop directly
	if has_node("BG"):
		get_node("BG").queue_free()
	
	# Bind the custom 3D Bezier and decorative elements path script dynamically!
	var path_line_container := $RootHBox/RightContent/MapScroll/ScrollM/PathLineContainer
	var path_script := load("res://scripts/CoursePathLine.gd")
	if path_line_container and path_script:
		path_line_container.set_script(path_script)
		path_line_container._ready()

	# Hide scrollbars for a clean, custom mobile swipe layout
	var map_scroll : ScrollContainer = $RootHBox/RightContent/MapScroll
	if map_scroll:
		map_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	
	# Tune vertical margins dynamically to get the perfect 45-degree slope for the wavy map
	var scroll_m : MarginContainer = $RootHBox/RightContent/MapScroll/ScrollM
	if scroll_m:
		scroll_m.add_theme_constant_override("margin_top", 170)
		scroll_m.add_theme_constant_override("margin_bottom", 170)
	
	# Set ideal separation spacing for the zig-zag look
	if map_hbox:
		map_hbox.add_theme_constant_override("separation", 96)
		
		# Programmatically stagger the 5 circular nodes (1, 3, 5 at top, 2, 4 at bottom)
		var n1 := map_hbox.get_node_or_null("Node1")
		if n1: n1.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		var n2 := map_hbox.get_node_or_null("Node2")
		if n2: n2.size_flags_vertical = Control.SIZE_SHRINK_END
		var n3 := map_hbox.get_node_or_null("Node3")
		if n3: n3.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		var n4 := map_hbox.get_node_or_null("Node4")
		if n4: n4.size_flags_vertical = Control.SIZE_SHRINK_END
		var n5 := map_hbox.get_node_or_null("Node5")
		if n5: n5.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	_build_theme()
	_build_bottom_bar()
	_set_labels()
	_animate_in()
	_setup_nodes()
	_connect_buttons()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.35)

	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()

func _process(delta: float) -> void:
	# Gentle breathing scale animation on active lesson node
	_pulse_time += delta
	var inst := InstrumentSelect.selected_instrument
	var active_node_idx := 1
	for i in range(1, 6):
		var node_id = "Node" + str(i)
		if SecureDataManager.is_lesson_unlocked(inst, node_id):
			active_node_idx = i
			
	var active_node_name = "Node" + str(active_node_idx)
	var active_node = map_hbox.get_node_or_null(active_node_name) as PanelContainer
	
	if active_node and is_instance_valid(active_node):
		if not active_node.is_queued_for_deletion():
			var pulse := 1.0 + sin(_pulse_time * 3.6) * 0.016
			active_node.scale = Vector2(pulse, pulse)

func _draw() -> void:
	# Draw premium solid Mahogany wood background
	draw_rect(Rect2(Vector2.ZERO, size), C_BG_DARK)
	
	# Draw gorgeous, high-fidelity traditional Vietnamese bronze drum ornament center (Top-Left)
	var tl_center := Vector2(240, 240)
	_draw_bronze_motif(tl_center, 320.0)
	
	# Draw traditional bronze drum ornament center (Bottom-Right)
	var br_center := size - Vector2(160, 160)
	_draw_bronze_motif(br_center, 260.0)

func _draw_bronze_motif(cntr: Vector2, max_radius: float) -> void:
	var gold_trans := Color(C_GOLD_LIGHT.r, C_GOLD_LIGHT.g, C_GOLD_LIGHT.b, 0.28)
	var gold_dim := Color(C_GOLD_LIGHT.r, C_GOLD_LIGHT.g, C_GOLD_LIGHT.b, 0.16)
	
	# Draw concentric thin golden rings
	draw_arc(cntr, max_radius * 0.22, 0.0, TAU, 64, gold_trans, 3.0, true)
	draw_arc(cntr, max_radius * 0.44, 0.0, TAU, 80, gold_dim, 2.0, true)
	draw_arc(cntr, max_radius * 0.66, 0.0, TAU, 96, gold_trans, 3.0, true)
	draw_arc(cntr, max_radius * 0.88, 0.0, TAU, 120, gold_dim, 2.0, true)
	
	# Draw traditional center 12-ray sun symbol
	var rays := 12
	var inner_r := max_radius * 0.05
	var outer_r := max_radius * 0.18
	for i in range(rays):
		var angle := float(i) * (TAU / float(rays))
		var dir := Vector2(cos(angle), sin(angle))
		draw_line(cntr + dir * inner_r, cntr + dir * outer_r, gold_trans, 3.5, true)
		
		# Draw decorative small dots in between the sun rays
		var mid_angle := angle + (PI / float(rays))
		var mid_dir := Vector2(cos(mid_angle), sin(mid_angle))
		draw_circle(cntr + mid_dir * (inner_r + outer_r) * 0.52, 3.5, gold_dim)

func _set_labels() -> void:
	var inst := InstrumentSelect.selected_instrument
	if inst == "dan_tranh":
		course_title.text = "Khóa Học Đàn Tranh Cơ Bản"
		(map_hbox.get_node("Node2/N2V/Title") as Label).text = "3 Nốt Đầu\n(Cơ bản)"
		(map_hbox.get_node("Node3/N3V/Title") as Label).text = "Nhấn & Rung\n(Trung bình)"
		(map_hbox.get_node("Node4/N4V/Title") as Label).text = "Song Thanh\n(Nâng cao)"
		(map_hbox.get_node("Node5/N5V/Title") as Label).text = "Khóa Học Tiếp"
	elif inst == "dan_bau":
		course_title.text = "Khóa Học Đàn Bầu Cơ Bản"
		(map_hbox.get_node("Node2/N2V/Title") as Label).text = "Hài Âm Cơ Bản\n(Cơ bản)"
		(map_hbox.get_node("Node3/N3V/Title") as Label).text = "Uốn Vòi Đàn\n(Trung bình)"
		(map_hbox.get_node("Node4/N4V/Title") as Label).text = "Luyến Láy\n(Nâng cao)"
		(map_hbox.get_node("Node5/N5V/Title") as Label).text = "Khóa Học Tiếp"
	else:
		course_title.text = "Khóa Học Sáo Trúc Cơ Bản"
		(map_hbox.get_node("Node2/N2V/Title") as Label).text = "Hơi & Che Lỗ\n(Cơ bản)"
		(map_hbox.get_node("Node3/N3V/Title") as Label).text = "Luyện Ngón\n(Trung bình)"
		(map_hbox.get_node("Node4/N4V/Title") as Label).text = "Nhấp Ngón\n(Nâng cao)"
		(map_hbox.get_node("Node5/N5V/Title") as Label).text = "Khóa Học Tiếp"
 
	btn_courses.text = "Khóa học"
	btn_room.text = "Phòng nhạc"
	btn_songs.text = "Bài hát"
	btn_account.text = "Hồ sơ"

func _build_theme() -> void:
	# Left sidebar - match MainMenu exactly!
	var side_s := _flat_sidebar(C_RED_SON_DK, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.15), 0)
	side_s.border_width_left = 0; side_s.border_width_top = 0; side_s.border_width_bottom = 0
	side_s.border_width_right = 2
	side_s.shadow_size = 12
	side_s.shadow_color = Color(0.13, 0.08, 0.05, 0.15)
	side_s.shadow_offset = Vector2(4, 0)
	($RootHBox/LeftSidebar as PanelContainer).add_theme_stylebox_override("panel", side_s)

	var is_prem : bool = SecureDataManager.data.get("is_premium", false)

	_style_side_icon_btn(btn_menu, false)
	_style_side_icon_btn(btn_courses,  true)
	_style_side_icon_btn(btn_room,     false)
	_style_side_icon_btn(btn_songs,    false, not is_prem)
	_style_side_icon_btn(btn_minigame, false)
	_style_side_icon_btn(btn_account, false)

	# Clean up any existing IconDraw instances
	for child in btn_menu.get_children():
		if child.name == "IconDraw": child.queue_free()
	for child in btn_courses.get_children():
		if child.name == "IconDraw": child.queue_free()
	for child in btn_room.get_children():
		if child.name == "IconDraw": child.queue_free()
	for child in btn_songs.get_children():
		if child.name == "IconDraw": child.queue_free()
	for child in btn_minigame.get_children():
		if child.name == "IconDraw": child.queue_free()
	for child in btn_account.get_children():
		if child.name == "IconDraw": child.queue_free()

	_attach_icon_draw(btn_menu,     0)
	_attach_icon_draw(btn_courses,  1)
	_attach_icon_draw(btn_room,     6)
	_attach_icon_draw(btn_songs,    2, not is_prem)
	_attach_icon_draw(btn_minigame, 3)
	_attach_icon_draw(btn_account,  5)

	_active_side_btn = btn_courses

	# Top bar
	var top_s := _flat(C_RED_SON_DK, Color(0,0,0,0), 0)
	top_s.border_width_bottom = 3
	top_s.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.12)
	($RootHBox/RightContent/TopBar as PanelContainer).add_theme_stylebox_override("panel", top_s)
	
	var font_title := load("res://assets/fonts/Lora-Bold.ttf")
	if font_title:
		course_title.add_theme_font_override("font", font_title)
		
	course_title.add_theme_color_override("font_color", C_RED_SON)
	course_title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0))
	course_title.add_theme_constant_override("outline_size", 0)



func _style_side_icon_btn(btn: Button, is_active: bool, is_locked: bool = false) -> void:
	var bg_n := _flat_sidebar(Color(0, 0, 0, 0) if not is_active else Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.12), Color(0, 0, 0, 0), 18)
	var bg_h := _flat_sidebar(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.08) if not is_locked else Color(0, 0, 0, 0), Color(0, 0, 0, 0), 18)
	var bg_p := _flat_sidebar(Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.20) if not is_locked else Color(0, 0, 0, 0), Color(0, 0, 0, 0), 18)

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
	btn.add_theme_stylebox_override("focus",   _flat_sidebar(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))
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

func _flat_sidebar(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.border_color = border
	s.border_width_left = 2; s.border_width_right  = 2
	s.border_width_top  = 2; s.border_width_bottom = 2
	s.corner_radius_top_left     = radius; s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius; s.corner_radius_bottom_right = radius
	return s

func _build_bottom_bar() -> void:
	var bottom_s := _flat_sidebar(C_RED_SON_DK, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.15), 0)
	bottom_s.border_width_left = 0; bottom_s.border_width_right = 0; bottom_s.border_width_bottom = 0
	bottom_s.border_width_top = 2
	bottom_s.shadow_size = 12
	bottom_s.shadow_color = Color(0.13, 0.08, 0.05, 0.15)
	bottom_s.shadow_offset = Vector2(0, -4)
	bottom_bar.add_theme_stylebox_override("panel", bottom_s)

	var is_prem : bool = SecureDataManager.data.get("is_premium", false)

	_style_bottom_icon_btn(btn_courses_mob, true)
	_style_bottom_icon_btn(btn_room_mob,    false)
	_style_bottom_icon_btn(btn_songs_mob,   false, not is_prem)
	_style_bottom_icon_btn(btn_minigame_mob, false)
	_style_bottom_icon_btn(btn_account_mob, false)

	_attach_bottom_icon_draw(btn_courses_mob, 1)
	_attach_bottom_icon_draw(btn_room_mob,    6)
	_attach_bottom_icon_draw(btn_songs_mob,   2, not is_prem)
	_attach_bottom_icon_draw(btn_minigame_mob, 3)
	_attach_bottom_icon_draw(btn_account_mob, 5)

func _style_bottom_icon_btn(btn: Button, is_active: bool, is_locked: bool = false) -> void:
	var bg_n := _flat_sidebar(Color(0, 0, 0, 0) if not is_active else Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.08), Color(0, 0, 0, 0), 12)
	var bg_h := _flat_sidebar(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.06) if not is_locked else Color(0, 0, 0, 0), Color(0, 0, 0, 0), 12)
	var bg_p := _flat_sidebar(Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.15) if not is_locked else Color(0, 0, 0, 0), Color(0, 0, 0, 0), 12)

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
	btn.add_theme_stylebox_override("focus",   _flat_sidebar(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))
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

func _setup_nodes() -> void:
	# Clear out any previous setups and set pivots for bouncy cartoon animations
	for c in map_hbox.get_children():
		var node := c as PanelContainer
		node.pivot_offset = Vector2(90, 90)

	var inst := InstrumentSelect.selected_instrument
	SecureDataManager.load_data()

	# Clean up any programmatic active tooltip anchors
	for c in map_hbox.get_children():
		var child_anchor = c.get_node_or_null("TooltipAnchor")
		if child_anchor:
			var tooltip = child_anchor.get_node_or_null("Tooltip")
			if tooltip:
				tooltip.visible = false

	# We'll determine the active (latest unlocked but not completed) node to show the TIẾP THEO tooltip
	var active_node_idx := 1
	for i in range(1, 6):
		var node_id = "Node" + str(i)
		if SecureDataManager.is_lesson_unlocked(inst, node_id):
			active_node_idx = i

	for i in range(1, 6):
		var node_id = "Node" + str(i)
		var node_name = "Node" + str(i)
		var node := map_hbox.get_node(node_name) as PanelContainer
		var n_icon := node.get_node("IconAnchor/IconPill") as PanelContainer
		var n_lbl := node.get_node("N" + str(i) + "V/Title") as Label
		
		# If this node is completed
		if SecureDataManager.is_lesson_completed(inst, node_id):
			# Solid Jade Green circle, checkmark play icon
			node.add_theme_stylebox_override("panel", _flat(C_JADE, C_JADE_LIGHT, 90, true, 4))
			n_icon.add_theme_stylebox_override("panel", _flat(C_JADE_LIGHT, C_CREAM, 22, false, 2))
			_setup_icon_pill(n_icon, 1) # CHECK vector icon
			n_lbl.add_theme_color_override("font_color", C_JADE)
			
		# If this node is unlocked
		elif SecureDataManager.is_lesson_unlocked(inst, node_id):
			# Cream circle, red border
			node.add_theme_stylebox_override("panel", _flat(C_CREAM, C_RED_SON, 90, true, 6))
			n_icon.add_theme_stylebox_override("panel", _flat(C_RED_SON, C_CREAM, 22, false, 2))
			
			var icon_type = 3 # Default to MUSIC note icon for practice
			if i == 1:
				icon_type = 0 # PLAY icon for intro video
			elif i == 5:
				icon_type = 1 # CHECK icon
			_setup_icon_pill(n_icon, icon_type)
			n_lbl.add_theme_color_override("font_color", C_RED_SON)
			
			# Setup active yellow speech tooltip only if it is the latest unlocked node
			if i == active_node_idx:
				if i == 1:
					_setup_active_tooltip(node, "BẮT ĐẦU")
				elif i == 5:
					_setup_active_tooltip(node, "HOÀN THÀNH")
				else:
					_setup_active_tooltip(node, "TIẾP THEO")
					
				var anchor = node.get_node_or_null("TooltipAnchor")
				if anchor:
					var tooltip = anchor.get_node_or_null("Tooltip") as PanelContainer
					if tooltip:
						tooltip.visible = true
						tooltip.add_theme_stylebox_override("panel", _flat(C_GOLD, C_GOLD_LIGHT, 12, true, 3))
						tooltip.get_node("TooltipText").add_theme_color_override("font_color", C_RED_SON)
						_animate_bob(tooltip)
						
		# If locked
		else:
			node.add_theme_stylebox_override("panel", _flat(C_LOCKED, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35), 90, true, 5))
			n_icon.add_theme_stylebox_override("panel", _flat(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25), Color(0,0,0,0), 22, false, 2))
			_setup_icon_pill(n_icon, 2) # LOCK vector icon
			n_lbl.add_theme_color_override("font_color", Color(0.35, 0.25, 0.20, 0.75))

func _setup_icon_pill(pill: PanelContainer, type: int) -> void:
	# Attach the pixel-perfect anti-aliased dynamic vector icon script!
	var pill_script := load("res://scripts/CourseIconPill.gd")
	if pill and pill_script:
		if not pill.get_script():
			pill.set_script(pill_script)
			pill._ready()
		pill.set_type(type)

func _setup_active_tooltip(node: Control, label_text: String) -> void:
	if node.has_node("TooltipAnchor"): return
	var anchor := Control.new()
	anchor.name = "TooltipAnchor"
	anchor.layout_mode = 2
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var tooltip := PanelContainer.new()
	tooltip.name = "Tooltip"
	tooltip.custom_minimum_size = Vector2(96, 38)
	tooltip.layout_mode = 1
	tooltip.anchors_preset = PRESET_CENTER_TOP
	tooltip.anchor_left = 0.5
	tooltip.anchor_right = 0.5
	tooltip.offset_left = -48
	tooltip.offset_top = -68
	tooltip.offset_right = 48
	tooltip.offset_bottom = -30
	tooltip.grow_horizontal = GROW_DIRECTION_BOTH
	tooltip.add_theme_stylebox_override("panel", _flat(C_GOLD, C_GOLD_LIGHT, 12, true, 3))
	
	var lbl := Label.new()
	lbl.name = "TooltipText"
	lbl.text = label_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", C_RED_SON_DK)
	
	tooltip.add_child(lbl)
	anchor.add_child(tooltip)
	node.add_child(anchor)
	
	_animate_bob(tooltip)

func _animate_bob(node: Control) -> void:
	var oy := node.position.y
	var t := create_tween().set_loops()
	t.tween_property(node, "position:y", oy - 10.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(node, "position:y", oy,        0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _connect_buttons() -> void:
	# Connect hamburger menu button back to main menu!
	if btn_menu:
		btn_menu.pressed.connect(func() -> void:
			var t := create_tween()
			t.tween_property(self, "modulate:a", 0.0, 0.22)
			t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
		)
		_make_button_bouncy(btn_menu)

	# Connect btn_room to virtual room
	if btn_room:
		btn_room.pressed.connect(func() -> void:
			var t := create_tween()
			t.tween_property(self, "modulate:a", 0.0, 0.22)
			t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/VirtualMusicRoom.tscn"))
		)
		_make_button_bouncy(btn_room)

	# Connect btn_songs with Premium Check
	if btn_songs:
		btn_songs.pressed.connect(func() -> void:
			var is_prem : bool = SecureDataManager.data.get("is_premium", false)
			if is_prem:
				var t := create_tween()
				t.tween_property(self, "modulate:a", 0.0, 0.22)
				t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/SongScreen.tscn"))
			else:
				VirtualArtist.show_tip("Phần Bài hát chỉ dành cho tài khoản Premium! Hãy nâng cấp trong phần Hồ sơ nhé.", 4.5)
		)
		_make_button_bouncy(btn_songs)

	# Connect btn_account to the Profile screen
	if btn_account:
		btn_account.pressed.connect(func() -> void:
			var t := create_tween()
			t.tween_property(self, "modulate:a", 0.0, 0.22)
			t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/AccountScreen.tscn"))
		)
		_make_button_bouncy(btn_account)

	if btn_minigame:
		btn_minigame.pressed.connect(func() -> void:
			var t := create_tween()
			t.tween_property(self, "modulate:a", 0.0, 0.22)
			t.tween_callback(func() -> void: get_tree().change_scene_to_file(_get_minigame_scene()))
		)
		_make_button_bouncy(btn_minigame)

	if btn_courses:
		_make_button_bouncy(btn_courses)

	# Mobile tabs events
	btn_courses_mob.pressed.connect(func() -> void:
		pass
	)
	btn_room_mob.pressed.connect(func() -> void:
		var t := create_tween()
		t.tween_property(self, "modulate:a", 0.0, 0.22)
		t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/VirtualMusicRoom.tscn"))
	)
	btn_songs_mob.pressed.connect(func() -> void:
		var is_prem : bool = SecureDataManager.data.get("is_premium", false)
		if is_prem:
			var t := create_tween()
			t.tween_property(self, "modulate:a", 0.0, 0.22)
			t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/SongScreen.tscn"))
		else:
			VirtualArtist.show_tip("Phần Bài hát chỉ dành cho tài khoản Premium! Hãy nâng cấp trong phần Hồ sơ nhé.", 4.5)
	)
	btn_account_mob.pressed.connect(func() -> void:
		var t := create_tween()
		t.tween_property(self, "modulate:a", 0.0, 0.22)
		t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/AccountScreen.tscn"))
	)

	if btn_minigame_mob:
		btn_minigame_mob.pressed.connect(func() -> void:
			var t := create_tween()
			t.tween_property(self, "modulate:a", 0.0, 0.22)
			t.tween_callback(func() -> void: get_tree().change_scene_to_file(_get_minigame_scene()))
		)
		_make_button_bouncy(btn_minigame_mob)

	for btn in [btn_courses_mob, btn_room_mob, btn_songs_mob, btn_minigame_mob, btn_account_mob]:
		_make_button_bouncy(btn)

	var inst_type := InstrumentSelect.selected_instrument
	SecureDataManager.load_data()

	# Node 1
	var n1 := map_hbox.get_node("Node1") as PanelContainer
	n1.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			_pluck_node(n1)
			CourseMap.active_lesson_id = "Node1"
			_go_video_lesson()
	)
	_make_node_hover_bouncy(n1)

	# Nodes 2 to 5
	for i in range(2, 6):
		var node_name := "Node" + str(i)
		var node_id := "Node" + str(i)
		var node := map_hbox.get_node(node_name) as PanelContainer
		
		node.gui_input.connect(func(e: InputEvent) -> void:
			if e is InputEventMouseButton and e.pressed:
				if SecureDataManager.is_lesson_unlocked(inst_type, node_id):
					_pluck_node(node)
					if i == 5:
						SecureDataManager.complete_lesson(inst_type, "Node5", 3)
						_show_course_completed_dialog()
					else:
						CourseMap.active_lesson_id = node_id
						_go_practice_room_for_node(i)
				else:
					# Shake animation for locked nodes
					var t := create_tween()
					var original_x = node.position.x
					t.tween_property(node, "position:x", original_x - 8.0, 0.05)
					t.tween_property(node, "position:x", original_x + 8.0, 0.05)
					t.tween_property(node, "position:x", original_x,       0.05)
		)
		
		if SecureDataManager.is_lesson_unlocked(inst_type, node_id):
			_make_node_hover_bouncy(node)

func _pluck_node(node: Control) -> void:
	var t := create_tween()
	t.tween_property(node, "scale", Vector2(0.92, 0.92), 0.08).set_trans(Tween.TRANS_QUAD)
	t.tween_property(node, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK)

func _make_node_hover_bouncy(node: Control) -> void:
	node.mouse_entered.connect(func() -> void:
		var t := create_tween().set_parallel(true)
		t.tween_property(node, "scale", Vector2(1.08, 1.08), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(node, "rotation_degrees", 3.0, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	)
	node.mouse_exited.connect(func() -> void:
		var t := create_tween().set_parallel(true)
		t.tween_property(node, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(node, "rotation_degrees", 0.0, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	)

func _get_minigame_scene() -> String:
	match InstrumentSelect.selected_instrument:
		"dan_tranh":
			return "res://scenes/MiniGameDanTranh.tscn"
		"sao_truc":
			return "res://scenes/MiniGameSaoTruc.tscn"
		"dan_bau":
			return "res://scenes/MiniGameDanBau.tscn"
		_:
			return "res://scenes/MiniGameDanTranh.tscn"

func _go_video_lesson() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.22)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/VideoPlayer.tscn"))

func _go_practice_room_for_node(node_index: int) -> void:
	var inst := InstrumentSelect.selected_instrument
	
	# Configure target song title and sheet notes for the selected lesson!
	if inst == "dan_tranh":
		if node_index == 2:
			PracticeRoom.current_song_title = "3 Nốt Đầu (Đô - Rê - Mi)"
			PracticeRoom.current_song_sheet = ["Đô", "Rê", "Mi", "Rê", "Đô", "Rê", "Mi", "Đô"]
		elif node_index == 3:
			PracticeRoom.current_song_title = "Kỹ Thuật Nhấn Dây & Rung Âm"
			PracticeRoom.current_song_sheet = ["Đô", "Đô", "Rê", "Mi", "Mi", "Fa", "Sol", "Fa", "Mi", "Rê", "Đô"]
		elif node_index == 4:
			PracticeRoom.current_song_title = "Kỹ Thuật Song Thanh"
			PracticeRoom.current_song_sheet = ["Đô", "La", "Fa", "Si", "La", "Mi", "Sol", "La"]
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
		
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.22)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file(path))

func _show_course_completed_dialog() -> void:
	var popup_scene := load("res://scenes/CustomPopup.tscn") as PackedScene
	if popup_scene:
		var popup = popup_scene.instantiate()
		add_child(popup)
		
		var inst := InstrumentSelect.selected_instrument
		var inst_name := ""
		var lessons_list := ""
		var next_inst_msg := ""
		
		if inst == "dan_tranh":
			inst_name = "Đàn Tranh"
			lessons_list = "• Giới thiệu nhạc cụ\n• Kỹ thuật 3 Nốt Đầu\n• Kỹ thuật Nhấn Dây & Rung Âm\n• Kỹ thuật Song Thanh"
			next_inst_msg = "• Đã mở khóa khóa học tiếp theo: [b]Sáo Trúc[/b]!"
		elif inst == "sao_truc":
			inst_name = "Sáo Trúc"
			lessons_list = "• Giới thiệu nhạc cụ\n• Kỹ thuật Hơi & Che Lỗ\n• Kỹ thuật Luyện Ngón\n• Kỹ thuật Nhấp Ngón"
			next_inst_msg = "• Đã mở khóa khóa học tiếp theo: [b]Đàn Bầu[/b]!"
		else:
			inst_name = "Đàn Bầu"
			lessons_list = "• Giới thiệu nhạc cụ\n• Kỹ thuật Hài Âm Cơ Bản\n• Kỹ thuật Uốn Vòi Đàn\n• Kỹ thuật Luyến Láy"
			next_inst_msg = "• Bạn đã hoàn thành toàn bộ các khóa học cơ bản!"

		var text := "[b]🎉 CHÚC MỪNG HOÀN THÀNH KHÓA HỌC![/b]\n\nBạn đã xuất sắc vượt qua toàn bộ lộ trình học %s cơ bản:\n%s\n\n[b]💡 LỜI KHUYÊN TIẾP THEO:[/b]\n%s\n• Tiếp tục luyện tập hàng ngày trong phòng nhạc ảo.\n• Thử sức với phần bài hát truyền thống để rèn luyện sự uyển chuyển." % [inst_name, lessons_list, next_inst_msg]
		
		popup.setup_hint("Chúc mừng hoàn thành", text)
		popup.closed.connect(func() -> void:
			var t := create_tween()
			t.tween_property(self, "modulate:a", 0.0, 0.22)
			t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/InstrumentSelect.tscn"))
		)

func _animate_in() -> void:
	var delay := 0.15
	for card in map_hbox.get_children():
		var c := card as Control
		c.modulate.a = 0.0
		c.scale = Vector2(0.68, 0.68)
		var t := create_tween().set_parallel(true)
		t.tween_property(c, "modulate:a", 1.0, 0.38).set_delay(delay)
		t.tween_property(c, "scale", Vector2.ONE, 0.45).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		delay += 0.08

func _flat(bg: Color, border: Color, radius: int, shadow: bool = false, offset_bottom: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.border_color = border
	s.border_width_left = 3
	s.border_width_right = 3
	s.border_width_top  = 3
	s.border_width_bottom = 3 + offset_bottom
	s.corner_radius_top_left     = radius; s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius; s.corner_radius_bottom_right = radius
	if shadow:
		s.shadow_size = 6
		s.shadow_color = Color(0, 0, 0, 0.22)
		s.shadow_offset = Vector2(0, 4)
	return s

func _make_button_bouncy(btn: Button) -> void:
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

func _on_viewport_size_changed() -> void:
	var size = get_viewport().size
	var is_mobile = size.x < size.y or size.x < 768
	
	# Root container vertical orientation
	var root_hbox := $RootHBox as BoxContainer
	root_hbox.vertical = is_mobile
	
	# Left sidebar visibility
	$RootHBox/LeftSidebar.visible = not is_mobile
	bottom_bar.visible = is_mobile
	
	# Map margins and separation overrides
	var scroll_m := $RootHBox/RightContent/MapScroll/ScrollM as MarginContainer
	if is_mobile:
		scroll_m.add_theme_constant_override("margin_top", 100)
		scroll_m.add_theme_constant_override("margin_bottom", 100)
		scroll_m.add_theme_constant_override("margin_left", 36)
		scroll_m.add_theme_constant_override("margin_right", 36)
		map_hbox.add_theme_constant_override("separation", 64)
		$RootHBox/RightContent/TopBar/TopM.add_theme_constant_override("margin_left", 16)
		$RootHBox/RightContent/TopBar/TopM.add_theme_constant_override("margin_right", 16)
		course_title.add_theme_font_size_override("font_size", 18)
	else:
		scroll_m.add_theme_constant_override("margin_top", 170)
		scroll_m.add_theme_constant_override("margin_bottom", 170)
		scroll_m.add_theme_constant_override("margin_left", 80)
		scroll_m.add_theme_constant_override("margin_right", 80)
		map_hbox.add_theme_constant_override("separation", 96)
		$RootHBox/RightContent/TopBar/TopM.add_theme_constant_override("margin_left", 32)
		$RootHBox/RightContent/TopBar/TopM.add_theme_constant_override("margin_right", 32)
		course_title.add_theme_font_size_override("font_size", 28)
		
	# Scale circular map nodes dynamically
	var node_size := Vector2(130, 130) if is_mobile else Vector2(180, 180)
	var title_font_size := 14 if is_mobile else 20
	var icon_pill_offset := -22.0 if is_mobile else -32.0
	var icon_pill_size := Vector2(36, 36) if is_mobile else Vector2(44, 44)
	var icon_pill_offset_xy := 8.0 if is_mobile else 12.0
	
	for c in map_hbox.get_children():
		var node := c as PanelContainer
		node.custom_minimum_size = node_size
		node.pivot_offset = node_size / 2.0
		
		# Update title font size
		var v_box = node.get_child(0) as VBoxContainer
		if v_box:
			var label = v_box.get_node_or_null("Title") as Label
			if label:
				label.add_theme_font_size_override("font_size", title_font_size)
				label.autowrap_mode = TextServer.AUTOWRAP_WORD
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				
		# Update icon pill anchor and offsets
		var anchor = node.get_node_or_null("IconAnchor") as Control
		if anchor:
			var pill = anchor.get_node_or_null("IconPill") as PanelContainer
			if pill:
				pill.custom_minimum_size = icon_pill_size
				pill.offset_left = icon_pill_offset
				pill.offset_top = icon_pill_offset
				pill.offset_right = icon_pill_offset_xy
				pill.offset_bottom = icon_pill_offset_xy
				
		# Update tooltip anchors
		var tooltip_anchor = node.get_node_or_null("TooltipAnchor") as Control
		if tooltip_anchor:
			var tooltip = tooltip_anchor.get_node_or_null("Tooltip") as PanelContainer
			if tooltip:
				if is_mobile:
					tooltip.offset_top = -54
				else:
					tooltip.offset_top = -68
