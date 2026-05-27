extends Control

class_name CourseMap

# ─── Colors ───────────────────────────────────────────────────────────────────
const C_BG_DARK     := Color(0.07, 0.04, 0.015, 1.0)
const C_RED_SON     := Color(0.72, 0.12, 0.08, 1.0)
const C_RED_SON_DK  := Color(0.38, 0.06, 0.04, 0.95)
const C_GOLD        := Color(0.95, 0.72, 0.18, 1.0)
const C_GOLD_LIGHT  := Color(1.00, 0.87, 0.45, 1.0)
const C_JADE        := Color(0.18, 0.62, 0.42, 1.0)
const C_JADE_LIGHT  := Color(0.35, 0.85, 0.60, 1.0)
const C_CREAM       := Color(1.00, 0.97, 0.88, 1.0)
const C_CREAM_DIM   := Color(0.80, 0.76, 0.66, 1.0)
const C_LOCKED      := Color(0.12, 0.08, 0.04, 0.65)

# ─── Static Progress State ────────────────────────────────────────────────────
static var video_completed := false

# ─── Refs ───
@onready var course_title : Label         = $RootHBox/RightContent/TopBar/TopM/TopH/CourseTitle
@onready var change_btn   : Button        = $RootHBox/RightContent/TopBar/TopM/TopH/ChangeCourseBtn
@onready var tab_courses  : Button        = $RootHBox/LeftSidebar/SidebarM/SidebarV/TabCourses
@onready var tab_songs    : Button        = $RootHBox/LeftSidebar/SidebarM/SidebarV/TabSongs
@onready var tab_games    : Button        = $RootHBox/LeftSidebar/SidebarM/SidebarV/TabGames
@onready var map_hbox     : HBoxContainer = $RootHBox/RightContent/MapScroll/ScrollM/MapHBox

var _pulse_time := 0.0

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
	_set_labels()
	_animate_in()
	_setup_nodes()
	_connect_buttons()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.35)

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
	var gold_trans := Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.08)
	var gold_dim := Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.035)
	
	# Draw concentric thin golden rings
	draw_arc(cntr, max_radius * 0.22, 0.0, TAU, 64, gold_trans, 2.0, true)
	draw_arc(cntr, max_radius * 0.44, 0.0, TAU, 80, gold_dim, 1.5, true)
	draw_arc(cntr, max_radius * 0.66, 0.0, TAU, 96, gold_trans, 2.0, true)
	draw_arc(cntr, max_radius * 0.88, 0.0, TAU, 120, gold_dim, 1.0, true)
	
	# Draw traditional center 12-ray sun symbol
	var rays := 12
	var inner_r := max_radius * 0.05
	var outer_r := max_radius * 0.18
	for i in range(rays):
		var angle := float(i) * (TAU / float(rays))
		var dir := Vector2(cos(angle), sin(angle))
		draw_line(cntr + dir * inner_r, cntr + dir * outer_r, gold_trans, 2.5, true)
		
		# Draw decorative small dots in between the sun rays
		var mid_angle := angle + (PI / float(rays))
		var mid_dir := Vector2(cos(mid_angle), sin(mid_angle))
		draw_circle(cntr + mid_dir * (inner_r + outer_r) * 0.52, 2.8, gold_dim)

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

	tab_courses.text = "Bài học"
	tab_songs.text = "Bài hát"
	change_btn.text = "Đổi nhạc cụ"

func _build_theme() -> void:
	# Left sidebar - glassmorphism semi-transparent lacquer red with gorgeous right shadow!
	var side_s := _flat(C_RED_SON_DK, Color(0,0,0,0), 0)
	side_s.border_width_right = 3
	side_s.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.22)
	side_s.shadow_size = 12
	side_s.shadow_color = Color(0, 0, 0, 0.35)
	side_s.shadow_offset = Vector2(4, 0)
	($RootHBox/LeftSidebar as PanelContainer).add_theme_stylebox_override("panel", side_s)

	# Sidebar tab style (Upgraded to premium 3D bubble style with content margins)
	var courses_s := _flat(C_RED_SON, C_GOLD, 20, true, 4)
	courses_s.border_width_left = 6; courses_s.border_width_right = 0; courses_s.border_width_top = 0; courses_s.border_width_bottom = 4
	courses_s.content_margin_left = 64
	tab_courses.add_theme_stylebox_override("normal", courses_s)
	tab_courses.add_theme_color_override("font_color", C_GOLD)

	var songs_s := _flat(Color(0,0,0,0), Color(0,0,0,0), 20)
	songs_s.content_margin_left = 64
	tab_songs.add_theme_stylebox_override("normal", songs_s)
	tab_songs.add_theme_color_override("font_color", C_CREAM_DIM)
	
	var tab_h := _flat(Color(1,1,1,0.06), C_GOLD, 20, false, 2)
	tab_h.content_margin_left = 64
	tab_songs.add_theme_stylebox_override("hover", tab_h)
	tab_songs.add_theme_color_override("font_hover_color", C_CREAM)

	# Style TabGames just like TabSongs!
	var games_s := _flat(Color(0,0,0,0), Color(0,0,0,0), 20)
	games_s.content_margin_left = 64
	tab_games.add_theme_stylebox_override("normal", games_s)
	tab_games.add_theme_stylebox_override("hover", tab_h)
	tab_games.add_theme_color_override("font_color", C_CREAM_DIM)
	tab_games.add_theme_color_override("font_hover_color", C_CREAM)

	# Top bar
	var top_s := _flat(C_RED_SON_DK, Color(0,0,0,0), 0)
	top_s.border_width_bottom = 3
	top_s.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.12)
	($RootHBox/RightContent/TopBar as PanelContainer).add_theme_stylebox_override("panel", top_s)
	course_title.add_theme_color_override("font_color", C_GOLD)
	course_title.add_theme_color_override("font_outline_color", Color(0.38, 0.06, 0.04, 1.0))
	course_title.add_theme_constant_override("outline_size", 6)

	# Change Course Button (Upgraded to beautiful solid lacquer red & gold 3D button)
	var c_n := _flat(C_RED_SON, C_GOLD, 20, true, 4)
	var c_h := _flat(C_RED_SON_DK, C_GOLD_LIGHT, 20, true, 4)
	change_btn.add_theme_stylebox_override("normal", c_n)
	change_btn.add_theme_stylebox_override("hover", c_h)
	change_btn.add_theme_stylebox_override("pressed", _flat(Color(0.2, 0.05, 0.03, 1.0), C_GOLD, 20, false, 1))
	change_btn.add_theme_stylebox_override("focus", _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	change_btn.add_theme_color_override("font_color", C_CREAM)
	change_btn.add_theme_color_override("font_hover_color", C_CREAM)

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
		node.add_theme_stylebox_override("panel", _flat(C_LOCKED, Color(C_RED_SON.r,C_RED_SON.g,C_RED_SON.b,0.3), 90, true, 5))
		n_icon.add_theme_stylebox_override("panel", _flat(C_RED_SON_DK, Color(0,0,0,0), 22, false, 2))
		_setup_icon_pill(n_icon, 2) # LOCK vector icon
		n_lbl.add_theme_color_override("font_color", Color(C_CREAM_DIM.r, C_CREAM_DIM.g, C_CREAM_DIM.b, 0.45))

	if not video_completed:
		# Node 1 is active (3D bubble cream circle, gold border)
		n1.add_theme_stylebox_override("panel", _flat(C_CREAM, C_GOLD, 90, true, 6))
		n1_icon.add_theme_stylebox_override("panel", _flat(C_GOLD, C_GOLD_LIGHT, 22, false, 2))
		_setup_icon_pill(n1_icon, 0) # PLAY vector icon
		n1_lbl.add_theme_color_override("font_color", C_RED_SON_DK)

		# Node 2 is locked (3D bubble dark circle)
		n2.add_theme_stylebox_override("panel", _flat(C_LOCKED, Color(C_RED_SON.r,C_RED_SON.g,C_RED_SON.b,0.3), 90, true, 5))
		n2_icon.add_theme_stylebox_override("panel", _flat(C_RED_SON_DK, Color(0,0,0,0), 22, false, 2))
		_setup_icon_pill(n2_icon, 2) # LOCK vector icon
		n2_lbl.add_theme_color_override("font_color", Color(C_CREAM_DIM.r, C_CREAM_DIM.g, C_CREAM_DIM.b, 0.45))

		# Hide Node 2's "NEXT" tooltip
		n2_tooltip.visible = false

		# Setup custom NEXT tooltip above Node 1!
		_setup_active_tooltip(n1, "BẮT ĐẦU")
	else:
		# Node 1 is completed (solid Jade Green circle, checkmark play icon)
		n1.add_theme_stylebox_override("panel", _flat(C_JADE, C_JADE_LIGHT, 90, true, 4))
		n1_icon.add_theme_stylebox_override("panel", _flat(C_JADE_LIGHT, C_CREAM, 22, false, 2))
		_setup_icon_pill(n1_icon, 1) # CHECK vector icon
		n1_lbl.add_theme_color_override("font_color", C_CREAM)

		# Node 2 is unlocked (white circle, red border)
		n2.add_theme_stylebox_override("panel", _flat(C_CREAM, C_RED_SON, 90, true, 6))
		n2_icon.add_theme_stylebox_override("panel", _flat(C_RED_SON, C_CREAM, 22, false, 2))
		_setup_icon_pill(n2_icon, 3) # MUSIC vector icon
		n2_lbl.add_theme_color_override("font_color", C_RED_SON_DK)

		# Show Node 2's yellow NEXT tooltip (gorgeous 3D bubble speech indicator)
		n2_tooltip.visible = true
		n2_tooltip.add_theme_stylebox_override("panel", _flat(C_GOLD, C_GOLD_LIGHT, 12, true, 3))
		n2_tooltip.get_node("TooltipText").add_theme_color_override("font_color", C_RED_SON_DK)
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
	change_btn.pressed.connect(_go_change_course)
	_make_button_bouncy(change_btn)
	
	# Connect hamburger menu button back to main menu!
	var menu_btn := $RootHBox/LeftSidebar/SidebarM/SidebarV/MenuBtn as Button
	if menu_btn:
		menu_btn.pressed.connect(func() -> void:
			var t := create_tween()
			t.tween_property(self, "modulate:a", 0.0, 0.22)
			t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
		)
		_make_button_bouncy(menu_btn)

	# Connect TabGames to the MiniGame scene!
	if tab_games:
		tab_games.pressed.connect(func() -> void:
			var t := create_tween()
			t.tween_property(self, "modulate:a", 0.0, 0.22)
			t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/MiniGame.tscn"))
		)
		_make_button_bouncy(tab_games)

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

func _go_change_course() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.22)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/InstrumentSelect.tscn"))

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
