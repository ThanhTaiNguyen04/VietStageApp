extends Node

const DEFAULT_W      : float = 220.0
const ANIM_TIME      : float = 0.30
const BACKDROP_ALPHA : float = 0.38

var desktop_width : float = DEFAULT_W

var sidebar : PanelContainer
var host    : Control
var hbox    : HBoxContainer
var top_h   : Control

var _toggle   : Button
var _backdrop : Button
var _menu_tex : Texture2D
var _x_tex    : Texture2D

var _is_desktop   : bool = true
var _overlay_open : bool = false
var _overlay_w    : float = DEFAULT_W
var _tween        : Tween
var _flow_children : Array[Control] = []

func setup(sb: PanelContainer, host_ctrl: Control, flow_hbox: HBoxContainer, top_row: Control) -> void:
	sidebar = sb
	host = host_ctrl
	hbox = flow_hbox
	top_h = top_row
	name = "SidebarDrawer"
	sidebar.clip_contents = true
	_collect_flow_children()
	_build_toggle()

func _collect_flow_children() -> void:
	_flow_children.clear()
	var stack: Array[Node] = []
	for child in sidebar.get_children():
		stack.append(child)
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is Control:
			_flow_children.append(node)
			for c in node.get_children():
				stack.append(c)

func set_viewport_mode(is_desktop: bool) -> void:
	_is_desktop = is_desktop
	_enter_overlay()
	_force_top_corner.call_deferred()

func _force_top_corner() -> void:
	if top_h and top_h.get_parent() is MarginContainer:
		var m := top_h.get_parent() as MarginContainer
		var vp := get_viewport().get_visible_rect().size if get_viewport() else Vector2(1280, 720)
		var margin := DS.nav_margin(vp.x, desktop_width)
		m.add_theme_constant_override("margin_left", margin)

func is_drawer_open() -> bool:
	return _overlay_open

func _build_toggle() -> void:
	if _toggle:
		return
	_menu_tex = load("res://assets/textures/lucide/menu.svg") as Texture2D
	_x_tex = load("res://assets/textures/lucide/x.svg") as Texture2D
	_toggle = Button.new()
	_toggle.name = "SidebarToggle"
	_toggle.icon = _menu_tex
	_toggle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	DS.apply_round_icon_btn(_toggle)
	_toggle.pressed.connect(_on_toggle_pressed)
	_make_bouncy(_toggle)
	if top_h:
		top_h.add_child(_toggle)
		top_h.move_child(_toggle, 0)
	_refresh_toggle_icon()

func _bring_toggle_to_front() -> void:
	if _toggle and _toggle.get_parent() == host:
		host.move_child(_toggle, host.get_child_count() - 1)

func _build_backdrop() -> void:
	if _backdrop:
		return
	_backdrop = Button.new()
	_backdrop.name = "SidebarBackdrop"
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_default_cursor_shape = Control.CURSOR_ARROW
	var dim := _dim(Color(0.03, 0.05, 0.04, BACKDROP_ALPHA))
	_backdrop.add_theme_stylebox_override("normal", dim)
	_backdrop.add_theme_stylebox_override("hover", dim)
	_backdrop.add_theme_stylebox_override("pressed", _dim(Color(0.03, 0.05, 0.04, BACKDROP_ALPHA + 0.05)))
	_backdrop.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_backdrop.modulate.a = 0.0
	_backdrop.visible = false
	_backdrop.pressed.connect(close_drawer)
	host.add_child(_backdrop)

func _on_toggle_pressed() -> void:
	if _overlay_open:
		_close_drawer()
	else:
		_open_drawer()
	_refresh_toggle_icon()

func open_drawer() -> void:
	_open_drawer()
	_refresh_toggle_icon()

func close_drawer() -> void:
	_close_drawer()
	_refresh_toggle_icon()

func _enter_overlay() -> void:
	_build_backdrop()
	if sidebar.get_parent() != host:
		hbox.remove_child(sidebar)
		host.add_child(sidebar)
		host.move_child(sidebar, host.get_child_count() - 1)
		_overlay_open = false
	_apply_overlay_geometry()
	_set_children_min_x(_overlay_w)
	_bring_toggle_to_front()
	if not _overlay_open:
		sidebar.visible = false
		_backdrop.visible = false
	else:
		sidebar.visible = true
		_backdrop.visible = true
	_refresh_toggle_icon()

func _apply_overlay_geometry() -> void:
	var vp := get_viewport().get_visible_rect().size if get_viewport() else Vector2(1280, 720)
	_overlay_w = minf(desktop_width, vp.x * 0.85)
	var top_offset := 0.0
	if _toggle and _toggle.is_inside_tree() and host and host.is_inside_tree():
		var host_origin := host.get_global_rect().position
		top_offset = _toggle.get_global_rect().end.y - host_origin.y + 8.0
	sidebar.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	sidebar.anchor_top = 0.0
	sidebar.anchor_bottom = 1.0
	sidebar.offset_top = top_offset
	sidebar.offset_bottom = 0.0
	sidebar.offset_left = 0.0
	sidebar.offset_right = _overlay_w
	sidebar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

func _open_drawer() -> void:
	_apply_overlay_geometry()
	sidebar.position.x = -_overlay_w
	sidebar.visible = true
	_backdrop.visible = true
	_bring_toggle_to_front()
	_kill_tween()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(sidebar, "position:x", 0.0, ANIM_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_backdrop, "modulate:a", 1.0, ANIM_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_overlay_open = true

func _close_drawer() -> void:
	if not _overlay_open:
		return
	_kill_tween()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(sidebar, "position:x", -_overlay_w, ANIM_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_property(_backdrop, "modulate:a", 0.0, ANIM_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_callback(func() -> void:
		sidebar.visible = false
		_backdrop.visible = false
	)
	_overlay_open = false

func _set_children_min_x(v: float) -> void:
	for c in _flow_children:
		c.custom_minimum_size.x = v

func _refresh_toggle_icon() -> void:
	if _toggle == null:
		return
	_toggle.icon = _x_tex if _overlay_open else _menu_tex

func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = null

func _dim(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = 0
	s.corner_radius_top_right = 0
	s.corner_radius_bottom_left = 0
	s.corner_radius_bottom_right = 0
	return s

func _flat(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	return s

func _make_bouncy(btn: Button) -> void:
	btn.pivot_offset = btn.size / 2.0
	btn.resized.connect(func() -> void: btn.pivot_offset = btn.size / 2.0)
	btn.mouse_entered.connect(func() -> void:
		create_tween().tween_property(btn, "scale", Vector2(1.05, 1.05), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func() -> void:
		create_tween().tween_property(btn, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	btn.button_down.connect(func() -> void:
		create_tween().tween_property(btn, "scale", Vector2(0.95, 0.95), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	btn.button_up.connect(func() -> void:
		var target := Vector2(1.05, 1.05) if btn.is_hovered() else Vector2.ONE
		create_tween().tween_property(btn, "scale", target, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
