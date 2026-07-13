class_name BottomNavBar
extends PanelContainer

signal tab_changed(tab_index: int)

const _TAB_LABELS := ["Trang chủ", "Khóa học", "Luyện tập", "Hồ sơ"]
const _BTN_SIZE   : int = 72  # square touch target

var _tabs       : Array[Button]  = []
var _icon_draws : Array[Control] = []
var _tab_labels : Array[Label]   = []
var _active_idx : int = -1

@onready var _tab_row := $InnerV/SafeMargin/TabRow

func _ready() -> void:
	_build_bg()
	_build_tabs()
	set_active_tab(0, false)

# ── Public API ────────────────────────────────────────────────────────────────

func set_active_tab(index: int, emit: bool = true) -> void:
	if index == _active_idx:
		return
	_active_idx = index
	for i in _tabs.size():
		_refresh_tab(i)
	if emit:
		tab_changed.emit(index)

# ── Build ─────────────────────────────────────────────────────────────────────

func _build_bg() -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(DS.C_BG_DARK.r, DS.C_BG_DARK.g, DS.C_BG_DARK.b, 0.97)
	s.border_width_left   = 0
	s.border_width_top    = 0
	s.border_width_right  = 1  # right divider line
	s.border_width_bottom = 0
	s.border_color = Color(DS.C_GOLD.r, DS.C_GOLD.g, DS.C_GOLD.b, 0.14)
	add_theme_stylebox_override("panel", s)

func _build_tabs() -> void:
	for i in _TAB_LABELS.size():
		var btn := Button.new()
		btn.flat = true
		btn.custom_minimum_size = Vector2(_BTN_SIZE, _BTN_SIZE)
		btn.size_flags_vertical  = Control.SIZE_EXPAND_FILL
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.focus_mode = Control.FOCUS_NONE

		btn.add_theme_stylebox_override("normal",  DS.no_style())
		btn.add_theme_stylebox_override("hover",   DS.no_style())
		btn.add_theme_stylebox_override("pressed", DS.no_style())
		btn.add_theme_stylebox_override("focus",   DS.no_style())

		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_theme_constant_override("separation", 3)

		var icon := Control.new()
		icon.custom_minimum_size = Vector2(26, 26)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon_idx := i
		icon.draw.connect(func() -> void: _draw_icon(icon, icon_idx))

		var lbl := Label.new()
		lbl.text = _TAB_LABELS[i]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.add_theme_font_size_override("font_size", DS.FS_MICRO)

		vbox.add_child(icon)
		vbox.add_child(lbl)
		btn.add_child(vbox)
		_tab_row.add_child(btn)

		_tabs.append(btn)
		_icon_draws.append(icon)
		_tab_labels.append(lbl)

		var tab_index := i
		btn.pressed.connect(func() -> void: set_active_tab(tab_index))

# ── State refresh ─────────────────────────────────────────────────────────────

func _refresh_tab(i: int) -> void:
	var is_active := (i == _active_idx)
	var col := DS.C_GOLD if is_active else DS.C_CREAM_DIM
	_tab_labels[i].add_theme_color_override("font_color", col)
	_icon_draws[i].queue_redraw()

# ── Icon drawing ──────────────────────────────────────────────────────────────

func _draw_icon(c: Control, icon_type: int) -> void:
	var is_active := (icon_type == _active_idx)
	var col := DS.C_GOLD if is_active else DS.C_CREAM_DIM
	var sz  := c.size
	var cx  := sz.x * 0.5
	var cy  := sz.y * 0.5

	match icon_type:
		0: # Home
			var pts := PackedVector2Array([
				Vector2(cx, cy - 11),
				Vector2(cx + 12, cy - 1),
				Vector2(cx + 9, cy - 1),
				Vector2(cx + 9, cy + 11),
				Vector2(cx - 9, cy + 11),
				Vector2(cx - 9, cy - 1),
				Vector2(cx - 12, cy - 1)
			])
			c.draw_colored_polygon(pts, col)
			c.draw_rect(Rect2(cx - 4, cy + 3, 8, 8), Color(DS.C_BG_DARK.r, DS.C_BG_DARK.g, DS.C_BG_DARK.b, 0.8))

		1: # Courses (grad cap)
			var d := PackedVector2Array([
				Vector2(cx, cy - 11), Vector2(cx + 13, cy - 4),
				Vector2(cx, cy + 3),  Vector2(cx - 13, cy - 4)
			])
			c.draw_colored_polygon(d, col)
			var b := PackedVector2Array([
				Vector2(cx - 8, cy), Vector2(cx + 8, cy),
				Vector2(cx + 6, cy + 8), Vector2(cx - 6, cy + 8)
			])
			c.draw_colored_polygon(b, col)
			c.draw_line(Vector2(cx, cy - 4), Vector2(cx + 11, cy + 1), col, 2.5, true)
			c.draw_circle(Vector2(cx + 11, cy + 4), 2.5, col)

		2: # Practice (music note)
			c.draw_rect(Rect2(cx - 8, cy - 10, 4, 14), col)
			c.draw_rect(Rect2(cx + 1,  cy - 14, 4, 14), col)
			c.draw_circle(Vector2(cx - 6,  cy + 4), 5.0, col)
			c.draw_circle(Vector2(cx + 3,  cy + 0), 5.0, col)
			c.draw_line(Vector2(cx - 4, cy - 10), Vector2(cx + 5, cy - 14), col, 3.0, true)

		3: # Profile (person)
			c.draw_circle(Vector2(cx, cy - 6), 7.0, col)
			c.draw_arc(Vector2(cx, cy + 11), 11, PI, TAU, 18, col, 4.0, true)

	# Active indicator: vertical gold pill on left edge
	if is_active:
		c.draw_rect(Rect2(-4.0, cy - 11, 3, 22), DS.C_GOLD)
