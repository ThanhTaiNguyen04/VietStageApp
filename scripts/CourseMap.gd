extends Control

class_name CourseMap

# ─── Colors ───────────────────────────────────────────────────────────────────
const C_BG_DARK     := Color(0.98, 0.97, 0.94, 1.0) # #FAF8F5 - warm cream background
const C_RED_SON     := Color(0.70, 0.12, 0.08, 1.0) # lacquer red
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

func _ready() -> void:
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
	
	btn_room.hide()
	btn_room_mob.hide()

func _process(delta: float) -> void:
	# Gentle breathing scale animation on active lesson node
	_pulse_time += delta
	var active_node : PanelContainer
	if not video_completed:
		active_node = map_hbox.get_node_or_null("Node1") as PanelContainer
	else:
		active_node = map_hbox.get_node_or_null("Node2") as PanelContainer
	
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
		(map_hbox.get_node("Node2/N2V/Title") as Label).text = "3 Nốt Đầu"
		(map_hbox.get_node("Node3/N3V/Title") as Label).text = "Nhấn & Rung"
		(map_hbox.get_node("Node4/N4V/Title") as Label).text = "Song Thanh"
		(map_hbox.get_node("Node5/N5V/Title") as Label).text = "Khóa Học Tiếp"
	else:
		course_title.text = "Khóa Học Sáo Trúc Cơ Bản"
		(map_hbox.get_node("Node2/N2V/Title") as Label).text = "Hơi & Che Lỗ"
		(map_hbox.get_node("Node3/N3V/Title") as Label).text = "Luyện Ngón"
		(map_hbox.get_node("Node4/N4V/Title") as Label).text = "Nhấp Ngón"
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
	for child in btn_account.get_children():
		if child.name == "IconDraw": child.queue_free()

	_attach_icon_draw(btn_menu,     0)
	_attach_icon_draw(btn_courses,  1)
	_attach_icon_draw(btn_room,     6)
	_attach_icon_draw(btn_songs,    2, not is_prem)
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
	_style_bottom_icon_btn(btn_account_mob, false)

	_attach_bottom_icon_draw(btn_courses_mob, 1)
	_attach_bottom_icon_draw(btn_room_mob,    6)
	_attach_bottom_icon_draw(btn_songs_mob,   2, not is_prem)
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

	# Configure Node 1 (Intro)
	var n1 := map_hbox.get_node("Node1") as PanelContainer
	var n1_icon := n1.get_node("IconAnchor/IconPill") as PanelContainer
	var n1_lbl := n1.get_node("N1V/Title") as Label

	# Configure Node 2 (Practice)
	var n2 := map_hbox.get_node("Node2") as PanelContainer
	var n2_icon := n2.get_node("IconAnchor/IconPill") as PanelContainer
	var n2_lbl := n2.get_node("N2V/Title") as Label
	var n2_tooltip := n2.get_node("TooltipAnchor/Tooltip") as PanelContainer

	# Configure Node 3, 4, 5
	for name_node in ["Node3", "Node4", "Node5"]:
		var node := map_hbox.get_node(name_node) as PanelContainer
		var n_icon := node.get_node("IconAnchor/IconPill") as PanelContainer
		var n_lbl := node.get_node(name_node.replace("Node","N") + "V/Title") as Label
		
		# Upgrade to gorgeous 3D cartoon stylebox
		node.add_theme_stylebox_override("panel", _flat(C_LOCKED, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35), 90, true, 5))
		n_icon.add_theme_stylebox_override("panel", _flat(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25), Color(0,0,0,0), 22, false, 2))
		_setup_icon_pill(n_icon, 2) # LOCK vector icon
		n_lbl.add_theme_color_override("font_color", Color(0.35, 0.25, 0.20, 0.75))

	if not video_completed:
		# Node 1 is active (3D bubble cream circle, gold border)
		n1.add_theme_stylebox_override("panel", _flat(C_CREAM, C_GOLD_LIGHT, 90, true, 6))
		n1_icon.add_theme_stylebox_override("panel", _flat(C_GOLD, C_GOLD_LIGHT, 22, false, 2))
		_setup_icon_pill(n1_icon, 0) # PLAY vector icon
		n1_lbl.add_theme_color_override("font_color", C_RED_SON)

		# Node 2 is locked (3D bubble dark circle)
		n2.add_theme_stylebox_override("panel", _flat(C_LOCKED, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35), 90, true, 5))
		n2_icon.add_theme_stylebox_override("panel", _flat(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25), Color(0,0,0,0), 22, false, 2))
		_setup_icon_pill(n2_icon, 2) # LOCK vector icon
		n2_lbl.add_theme_color_override("font_color", Color(0.35, 0.25, 0.20, 0.75))

		# Hide Node 2's "NEXT" tooltip
		n2_tooltip.visible = false

		# Setup custom NEXT tooltip above Node 1!
		_setup_active_tooltip(n1, "BẮT ĐẦU")
	else:
		# Node 1 is completed (solid Jade Green circle, checkmark play icon)
		n1.add_theme_stylebox_override("panel", _flat(C_JADE, C_JADE_LIGHT, 90, true, 4))
		n1_icon.add_theme_stylebox_override("panel", _flat(C_JADE_LIGHT, C_CREAM, 22, false, 2))
		_setup_icon_pill(n1_icon, 1) # CHECK vector icon
		n1_lbl.add_theme_color_override("font_color", C_JADE)

		# Node 2 is unlocked (white circle, red border)
		n2.add_theme_stylebox_override("panel", _flat(C_CREAM, C_RED_SON, 90, true, 6))
		n2_icon.add_theme_stylebox_override("panel", _flat(C_RED_SON, C_CREAM, 22, false, 2))
		_setup_icon_pill(n2_icon, 3) # MUSIC vector icon
		n2_lbl.add_theme_color_override("font_color", C_RED_SON)

		# Show Node 2's yellow NEXT tooltip (gorgeous 3D bubble speech indicator)
		n2_tooltip.visible = true
		n2_tooltip.add_theme_stylebox_override("panel", _flat(C_GOLD, C_GOLD_LIGHT, 12, true, 3))
		n2_tooltip.get_node("TooltipText").add_theme_color_override("font_color", C_RED_SON)
		_animate_bob(n2_tooltip)

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

	for btn in [btn_courses_mob, btn_room_mob, btn_songs_mob, btn_account_mob]:
		_make_button_bouncy(btn)

	var n1 := map_hbox.get_node("Node1") as PanelContainer
	n1.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			_pluck_node(n1)
			_go_video_lesson()
	)
	_make_node_hover_bouncy(n1)

	var n2 := map_hbox.get_node("Node2") as PanelContainer
	n2.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			if video_completed:
				_pluck_node(n2)
				_go_practice_room()
			else:
				# Show a prompt to watch video first
				var t := create_tween()
				t.tween_property(n1, "scale", Vector2(1.12, 1.12), 0.12).set_trans(Tween.TRANS_BACK)
				t.tween_property(n1, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)
	)
	if video_completed:
		_make_node_hover_bouncy(n2)

	# Locked nodes click visual feedback
	for node_name in ["Node3", "Node4", "Node5"]:
		var node := map_hbox.get_node(node_name) as PanelContainer
		node.gui_input.connect(func(e: InputEvent) -> void:
			if e is InputEventMouseButton and e.pressed:
				var t := create_tween()
				t.tween_property(node, "position:x", node.position.x - 8.0, 0.05)
				t.tween_property(node, "position:x", node.position.x + 8.0, 0.05)
				t.tween_property(node, "position:x", node.position.x,       0.05)
		)

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

func _go_video_lesson() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.22)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/VideoPlayer.tscn"))

func _go_practice_room() -> void:
	var inst := InstrumentSelect.selected_instrument
	var path := "res://scenes/PracticeRoom.tscn" if inst == "dan_tranh" else "res://scenes/PracticeSaoTruc.tscn"
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.22)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file(path))

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
