extends Node
## Design System autoload — palette, spacing, typography, UI helpers.
## Access via DS.C_GOLD, DS.flat(), DS.make_bouncy(), etc.

# ── Color Palette (Traditional Vietnamese Lacquer Red & Gold) ─────────────────
const C_GOLD       := Color(0.95, 0.72, 0.18)    # #F2B82D  primary CTA
const C_GOLD_LIGHT := Color(1.00, 0.87, 0.45)    # lighter gold
const C_GOLD_DARK  := Color(0.06, 0.02, 0.00)    # dark text on gold bg
const C_RED_SON    := Color(0.72, 0.12, 0.08)    # #B81F14  vermilion active
const C_RED_DK     := Color(0.38, 0.06, 0.04)    # deep lacquer red
const C_BG_DARK    := Color(0.063, 0.024, 0.016) # #100604  main background
const C_BG_DARKER  := Color(0.035, 0.008, 0.004) # #090201  deeper bg
const C_CARD       := Color(0.102, 0.039, 0.024) # #1A0A06  card surface
const C_CREAM      := Color(1.00, 0.97, 0.88)    # #FFF7E0  primary text
const C_CREAM_DIM  := Color(0.80, 0.76, 0.66)    # dimmed cream
const C_JADE       := Color(0.18, 0.62, 0.42)    # #2E9E6B  success / completed
const C_ERR        := Color(0.98, 0.32, 0.22)    # error red
const C_OK         := Color(0.25, 0.88, 0.55)    # success green
const C_G_BLUE     := Color(0.26, 0.52, 0.96)    # Google blue

# ── Spacing tokens ─────────────────────────────────────────────────────────────
const SP_XS  : int = 4
const SP_SM  : int = 8
const SP_MD  : int = 16
const SP_LG  : int = 24
const SP_XL  : int = 32
const SP_2XL : int = 48

# ── Typography scale (390 × 844 portrait) ────────────────────────────────────
const FS_DISPLAY : int = 32  # hero / splash title
const FS_H1      : int = 26  # screen title
const FS_H2      : int = 20  # section header
const FS_BODY    : int = 16  # body text
const FS_CAPTION : int = 13  # meta / caption
const FS_MICRO   : int = 11  # badge / tiny label

# ── Safe area insets (landscape) ─────────────────────────────────────────────
const SAFE_TOP    : int = 0   # no top status bar in landscape game
const SAFE_BOTTOM : int = 0   # no bottom indicator
const SAFE_LEFT   : int = 34  # notch / camera cutout (landscape left)
const SAFE_RIGHT  : int = 34  # speaker grill safe zone (landscape right)

# ── Landscape layout ──────────────────────────────────────────────────────────
const NAV_W     : int = 72   # left sidebar nav width
const TOPBAR_H  : int = 56   # compact top bar height for landscape

# ── Corner radii ──────────────────────────────────────────────────────────────
const R_SM   : int = 8
const R_MD   : int = 14
const R_LG   : int = 20
const R_XL   : int = 28
const R_PILL : int = 999

# ── StyleBoxFlat factory ──────────────────────────────────────────────────────

static func flat(bg: Color, border: Color, radius: int, border_w: int = 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color    = bg
	s.border_color = border
	s.corner_radius_top_left     = radius
	s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius
	s.corner_radius_bottom_right = radius
	s.border_width_left   = border_w
	s.border_width_right  = border_w
	s.border_width_top    = border_w
	s.border_width_bottom = border_w
	s.content_margin_left   = SP_LG
	s.content_margin_right  = SP_LG
	s.content_margin_top    = SP_MD
	s.content_margin_bottom = SP_MD
	return s

static func pill(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color    = bg
	s.border_color = border
	s.corner_radius_top_left     = R_PILL
	s.corner_radius_top_right    = R_PILL
	s.corner_radius_bottom_left  = R_PILL
	s.corner_radius_bottom_right = R_PILL
	s.border_width_left   = 1
	s.border_width_right  = 1
	s.border_width_top    = 1
	s.border_width_bottom = 1
	s.content_margin_left   = SP_MD
	s.content_margin_right  = SP_MD
	s.content_margin_top    = SP_SM - 2
	s.content_margin_bottom = SP_SM - 2
	return s

static func no_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color    = Color.TRANSPARENT
	s.border_color = Color.TRANSPARENT
	s.border_width_left   = 0
	s.border_width_right  = 0
	s.border_width_top    = 0
	s.border_width_bottom = 0
	return s

static func shadow(sb: StyleBoxFlat, size: int, color: Color, offset: Vector2 = Vector2.ZERO) -> StyleBoxFlat:
	sb.shadow_size   = size
	sb.shadow_color  = color
	sb.shadow_offset = offset
	return sb

# ── Button variant factories ──────────────────────────────────────────────────

static func primary_styles() -> Array[StyleBoxFlat]:
	var n := shadow(
		flat(C_GOLD, Color.TRANSPARENT, R_MD, 0),
		20, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.40)
	)
	var h := shadow(
		flat(C_GOLD_LIGHT, Color.TRANSPARENT, R_MD, 0),
		28, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.55)
	)
	var p := flat(C_GOLD.darkened(0.14), Color.TRANSPARENT, R_MD, 0)
	return [n, h, p, no_style()]

static func secondary_styles() -> Array[StyleBoxFlat]:
	var n := flat(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.10), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45), R_MD)
	var h := flat(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.18), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.70), R_MD)
	var p := flat(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.80), R_MD)
	return [n, h, p, no_style()]

static func ghost_styles() -> Array[StyleBoxFlat]:
	var n := flat(Color.TRANSPARENT,   Color(1, 1, 1, 0.22), R_MD)
	var h := flat(Color(1, 1, 1, 0.06), Color(1, 1, 1, 0.45), R_MD)
	var p := flat(Color(1, 1, 1, 0.12), Color(1, 1, 1, 0.55), R_MD)
	return [n, h, p, no_style()]

static func danger_styles() -> Array[StyleBoxFlat]:
	var n := shadow(
		flat(C_RED_SON, Color.TRANSPARENT, R_MD, 0),
		12, Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.40)
	)
	var h := flat(C_RED_SON.lightened(0.10), Color.TRANSPARENT, R_MD, 0)
	var p := flat(C_RED_DK, Color.TRANSPARENT, R_MD, 0)
	return [n, h, p, no_style()]

# ── Apply helpers ─────────────────────────────────────────────────────────────

static func apply_primary(btn: Button, font_size: int = FS_BODY) -> void:
	_apply_btn(btn, primary_styles(), C_GOLD_DARK, font_size)

static func apply_secondary(btn: Button, font_size: int = FS_BODY) -> void:
	_apply_btn(btn, secondary_styles(), C_CREAM, font_size)

static func apply_ghost(btn: Button, font_size: int = FS_BODY) -> void:
	_apply_btn(btn, ghost_styles(), C_CREAM, font_size)

static func apply_danger(btn: Button, font_size: int = FS_BODY) -> void:
	_apply_btn(btn, danger_styles(), C_CREAM, font_size)

static func _apply_btn(btn: Button, styles: Array[StyleBoxFlat], text_col: Color, fs: int) -> void:
	btn.add_theme_stylebox_override("normal",  styles[0])
	btn.add_theme_stylebox_override("hover",   styles[1])
	btn.add_theme_stylebox_override("pressed", styles[2])
	btn.add_theme_stylebox_override("focus",   styles[3])
	btn.add_theme_color_override("font_color",         text_col)
	btn.add_theme_color_override("font_hover_color",   text_col)
	btn.add_theme_color_override("font_pressed_color", text_col)
	btn.add_theme_font_size_override("font_size", fs)

# ── Panel helpers ─────────────────────────────────────────────────────────────

static func card_dark_style() -> StyleBoxFlat:
	var s := flat(C_CARD, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.18), R_LG)
	shadow(s, 16, Color(0, 0, 0, 0.45), Vector2(0, 4))
	return s

static func card_glass_style() -> StyleBoxFlat:
	var s := flat(Color(1, 1, 1, 0.06), Color(1, 1, 1, 0.12), R_LG)
	shadow(s, 12, Color(0, 0, 0, 0.30))
	return s

static func apply_card(panel: PanelContainer, glass: bool = false) -> void:
	panel.add_theme_stylebox_override("panel", card_glass_style() if glass else card_dark_style())

# ── Button bounce micro-interaction ──────────────────────────────────────────

static func make_bouncy(btn: Button) -> void:
	btn.pivot_offset = btn.size / 2.0
	btn.resized.connect(func() -> void: btn.pivot_offset = btn.size / 2.0)
	btn.mouse_entered.connect(func() -> void:
		btn.create_tween().tween_property(btn, "scale", Vector2(1.06, 1.06), 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func() -> void:
		btn.create_tween().tween_property(btn, "scale", Vector2.ONE, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	btn.button_down.connect(func() -> void:
		btn.create_tween().tween_property(btn, "scale", Vector2(0.94, 0.94), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	btn.button_up.connect(func() -> void:
		var tgt := Vector2(1.06, 1.06) if btn.is_hovered() else Vector2.ONE
		btn.create_tween().tween_property(btn, "scale", tgt, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)

# ── Scene transition ──────────────────────────────────────────────────────────

static func fade_to(node: Control, path: String, dur: float = 0.28) -> void:
	var t := node.create_tween()
	t.tween_property(node, "modulate:a", 0.0, dur).set_trans(Tween.TRANS_CUBIC)
	t.tween_callback(func() -> void: node.get_tree().change_scene_to_file(path))
