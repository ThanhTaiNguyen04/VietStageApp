extends Node
## Design System autoload — palette, spacing, typography, UI helpers.
## Single source of truth for the whole app (cream / jade / gold lacquer).
## Access via DS.C_GOLD, DS.flat(), DS.make_bouncy(), etc.

# ── Core Palette (Warm Cream + Jade + Gold Lacquer) ─────────────────────────
const C_BG         := Color(0.98, 0.97, 0.94, 1.0)  # #FAF8F5 page background
const C_BG_SIDEBAR := Color(0.95, 0.93, 0.89, 1.0)  # #F3EFE3 sidebar surface
const C_CARD       := Color(1.00, 0.99, 0.97, 1.0)  # #FFFDF8 elevated surface
const C_CARD_HOVER := Color(0.98, 0.95, 0.88, 1.0)

const C_JADE       := Color(0.09, 0.27, 0.18, 1.0)  # #173F2D primary brand
const C_JADE_LIGHT := Color(0.14, 0.37, 0.23, 1.0)  # #245F43 hover / active path
const C_JADE_TINT  := Color(0.09, 0.27, 0.18, 0.12) # translucent jade wash

const C_GOLD       := Color(0.77, 0.58, 0.15, 1.0)  # #C59626 accent
const C_GOLD_LIGHT := Color(0.94, 0.80, 0.38, 1.0)  # #F0CB62 hover gold
const C_GOLD_TINT  := Color(0.77, 0.58, 0.15, 0.14) # translucent gold wash
const C_GOLD_DARK  := Color(0.45, 0.32, 0.06, 1.0)  # text on gold

const C_TEXT       := Color(0.13, 0.08, 0.05, 1.0)  # #21140D primary text
const C_TEXT_MUTED := Color(0.44, 0.38, 0.34, 1.0)  # #6F6257 secondary text
const C_TEXT_FAINT := Color(0.44, 0.38, 0.34, 0.45)

const C_CREAM      := Color(1.00, 0.97, 0.88, 1.0)  # light text on jade/gold
const C_CREAM_DIM  := Color(0.80, 0.76, 0.66, 1.0)  # dimmed light text

const C_ERR        := Color(0.72, 0.12, 0.08, 1.0)  # #B81F14 error / danger
const C_OK         := Color(0.18, 0.62, 0.42, 1.0)  # success green
const C_WARN       := Color(0.72, 0.42, 0.10, 1.0)  # warning amber

const C_LINE       := Color(0.13, 0.08, 0.05, 0.12) # hairline divider
const C_BG_DARK    := Color(0.06, 0.05, 0.04, 1.0)  # legacy dark (overlays/shadow)

# ── Spacing tokens ─────────────────────────────────────────────────────────────
const SP_XS  : int = 4
const SP_SM  : int = 8
const SP_MD  : int = 16
const SP_LG  : int = 24
const SP_XL  : int = 32
const SP_2XL : int = 48

# ── Typography scale ──────────────────────────────────────────────────────────
const FS_DISPLAY : int = 32  # hero / splash title
const FS_H1      : int = 26  # screen title
const FS_H2      : int = 20  # section header
const FS_BODY    : int = 16  # body text
const FS_CAPTION : int = 13  # meta / caption
const FS_MICRO   : int = 11  # badge / tiny label

# ── Corner radii ──────────────────────────────────────────────────────────────
const R_SM   : int = 8
const R_MD   : int = 14
const R_LG   : int = 20
const R_XL   : int = 28
const R_PILL : int = 999

# ── StyleBoxFlat factory ──────────────────────────────────────────────────────

static func flat(bg: Color, border: Color, radius: int, border_w: int = 1, margins: Vector4i = Vector4i(SP_LG, SP_MD, SP_LG, SP_MD)) -> StyleBoxFlat:
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
	s.content_margin_left   = margins.x
	s.content_margin_top    = margins.y
	s.content_margin_right  = margins.z
	s.content_margin_bottom = margins.w
	return s

static func pill(bg: Color, border: Color, margins: Vector4i = Vector4i(SP_MD, SP_SM - 2, SP_MD, SP_SM - 2)) -> StyleBoxFlat:
	var s := flat(bg, border, R_PILL, 1, margins)
	return s

static func no_style() -> StyleBoxFlat:
	return flat(Color.TRANSPARENT, Color.TRANSPARENT, 0, 0, Vector4i(0, 0, 0, 0))

static func shadow(sb: StyleBoxFlat, size: int, color: Color, offset: Vector2 = Vector2.ZERO) -> StyleBoxFlat:
	sb.shadow_size   = size
	sb.shadow_color  = color
	sb.shadow_offset = offset
	return sb

# ── Card helpers (light theme) ────────────────────────────────────────────────

static func card_style() -> StyleBoxFlat:
	var s := flat(C_CARD, Color(C_LINE.r, C_LINE.g, C_LINE.b, 0.8), R_LG, 1)
	shadow(s, 14, Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.10), Vector2(0, 3))
	return s

static func card_hover_style() -> StyleBoxFlat:
	var s := flat(C_CARD_HOVER, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45), R_LG, 1)
	shadow(s, 18, Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.16), Vector2(0, 4))
	return s

static func panel_style() -> StyleBoxFlat:
	var s := flat(Color(C_CARD.r, C_CARD.g, C_CARD.b, 0.92), Color(C_LINE.r, C_LINE.g, C_LINE.b, 0.7), R_MD, 1)
	return s

static func apply_card(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", card_style())

# ── Button variant factories (light theme) ────────────────────────────────────

static func primary_styles() -> Array[StyleBoxFlat]:
	var n := shadow(
		flat(C_JADE, Color.TRANSPARENT, R_MD, 0, Vector4i(SP_LG, SP_MD, SP_LG, SP_MD)),
		16, Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.30), Vector2(0, 3)
	)
	var h := shadow(
		flat(C_JADE_LIGHT, Color.TRANSPARENT, R_MD, 0, Vector4i(SP_LG, SP_MD, SP_LG, SP_MD)),
		22, Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.42), Vector2(0, 4)
	)
	var p := flat(C_JADE.darkened(0.12), Color.TRANSPARENT, R_MD, 0, Vector4i(SP_LG, SP_MD, SP_LG, SP_MD))
	return [n, h, p, no_style()]

static func secondary_styles() -> Array[StyleBoxFlat]:
	var n := flat(Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.08), Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.40), R_MD, 1)
	var h := flat(Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.14), Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.65), R_MD, 1)
	var p := flat(Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.20), Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.80), R_MD, 1)
	return [n, h, p, no_style()]

static func gold_styles() -> Array[StyleBoxFlat]:
	var n := shadow(
		flat(C_GOLD, Color.TRANSPARENT, R_MD, 0, Vector4i(SP_LG, SP_MD, SP_LG, SP_MD)),
		14, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.30), Vector2(0, 3)
	)
	var h := shadow(
		flat(C_GOLD_LIGHT, Color.TRANSPARENT, R_MD, 0, Vector4i(SP_LG, SP_MD, SP_LG, SP_MD)),
		20, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.42), Vector2(0, 4)
	)
	var p := flat(C_GOLD.darkened(0.12), Color.TRANSPARENT, R_MD, 0, Vector4i(SP_LG, SP_MD, SP_LG, SP_MD))
	return [n, h, p, no_style()]

static func ghost_styles() -> Array[StyleBoxFlat]:
	var n := flat(Color.TRANSPARENT, Color(C_TEXT.r, C_TEXT.g, C_TEXT.b, 0.25), R_MD, 1)
	var h := flat(Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.08), Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.45), R_MD, 1)
	var p := flat(Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.14), Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.55), R_MD, 1)
	return [n, h, p, no_style()]

static func danger_styles() -> Array[StyleBoxFlat]:
	var n := shadow(
		flat(C_ERR, Color.TRANSPARENT, R_MD, 0, Vector4i(SP_LG, SP_MD, SP_LG, SP_MD)),
		12, Color(C_ERR.r, C_ERR.g, C_ERR.b, 0.35), Vector2(0, 3)
	)
	var h := flat(C_ERR.lightened(0.10), Color.TRANSPARENT, R_MD, 0, Vector4i(SP_LG, SP_MD, SP_LG, SP_MD))
	var p := flat(C_ERR.darkened(0.15), Color.TRANSPARENT, R_MD, 0, Vector4i(SP_LG, SP_MD, SP_LG, SP_MD))
	return [n, h, p, no_style()]

# ── Apply helpers ─────────────────────────────────────────────────────────────

static func apply_primary(btn: Button, font_size: int = FS_BODY) -> void:
	_apply_btn(btn, primary_styles(), C_CREAM, font_size)

static func apply_secondary(btn: Button, font_size: int = FS_BODY) -> void:
	_apply_btn(btn, secondary_styles(), C_JADE, font_size)

static func apply_gold(btn: Button, font_size: int = FS_BODY) -> void:
	_apply_btn(btn, gold_styles(), C_BG, font_size)

static func apply_ghost(btn: Button, font_size: int = FS_BODY) -> void:
	_apply_btn(btn, ghost_styles(), C_JADE, font_size)

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

static func card_glass_style() -> StyleBoxFlat:
	var s := flat(Color(1, 1, 1, 0.45), Color(1, 1, 1, 0.55), R_LG, 1)
	shadow(s, 12, Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.12))
	return s

# ── Typography helpers ────────────────────────────────────────────────────────

static func apply_title(lbl: Label) -> void:
	lbl.add_theme_color_override("font_color", C_JADE)
	var f := load("res://assets/fonts/Lora-Bold.ttf") as Font
	if f:
		lbl.add_theme_font_override("font", f)

static func apply_body(lbl: Label) -> void:
	lbl.add_theme_color_override("font_color", C_TEXT)
	var f := load("res://assets/fonts/BeVietnamPro-Regular.ttf") as Font
	if f:
		lbl.add_theme_font_override("font", f)

# ── Profile pill (matches MainMenu profile trigger) ───────────────────────────
# Returns a PanelContainer styled like the khóa-học profile trigger:
# frosted white panel + gold border, round avatar, name, "Xem hồ sơ", chevron.
# Caller connects "TriggerButton" pressed -> AccountScreen.

static func build_profile_pill() -> PanelContainer:
	var pill := PanelContainer.new()
	pill.name = "ProfilePill"
	pill.custom_minimum_size = Vector2(70, 70)
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pill.add_theme_stylebox_override("panel", _profile_pill_style())

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 3)
	margin.add_theme_constant_override("margin_right", 3)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_bottom", 3)
	pill.add_child(margin)

	var avatar_frame := PanelContainer.new()
	avatar_frame.name = "AvatarFrame"
	avatar_frame.custom_minimum_size = Vector2(64, 64)
	avatar_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	avatar_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	avatar_frame.clip_contents = true
	avatar_frame.add_theme_stylebox_override("panel", flat(Color.TRANSPARENT, Color.TRANSPARENT, 32, 0, Vector4i.ZERO))
	margin.add_child(avatar_frame)

	var avatar_icon := TextureRect.new()
	avatar_icon.name = "AvatarIcon"
	
	# Load Circular Shader Material
	var shader = load("res://assets/shaders/circular_avatar.gdshader") as Shader
	if shader:
		var mat = ShaderMaterial.new()
		mat.shader = shader
		avatar_icon.material = mat
		
	# Load User Avatar Texture
	var avatar_source := str(SecureDataManager.data.get("user_avatar_url", "")).strip_edges()
	if avatar_source.is_empty():
		avatar_source = str(SecureDataManager.data.get("user_avatar", "res://assets/textures/default_avatar.png"))
	var avatar_tex : Texture2D = null
	if avatar_source.begins_with("res://"):
		avatar_tex = load(avatar_source) as Texture2D
	if avatar_tex == null:
		avatar_tex = load("res://assets/textures/default_avatar.png") as Texture2D
		
	avatar_icon.texture = avatar_tex
	avatar_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar_icon.stretch_mode = TextureRect.STRETCH_SCALE
	avatar_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	avatar_frame.add_child(avatar_icon)

	var trigger := Button.new()
	trigger.name = "TriggerButton"
	trigger.flat = true
	
	var hover_style := StyleBoxFlat.new()
	hover_style.draw_center = false
	hover_style.border_width_left = 2; hover_style.border_width_right = 2
	hover_style.border_width_top = 2; hover_style.border_width_bottom = 2
	hover_style.border_color = C_GOLD_LIGHT
	hover_style.set_corner_radius_all(35)
	
	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.15)
	pressed_style.border_width_left = 2; pressed_style.border_width_right = 2
	pressed_style.border_width_top = 2; pressed_style.border_width_bottom = 2
	pressed_style.border_color = C_GOLD_LIGHT
	pressed_style.set_corner_radius_all(35)
	
	trigger.add_theme_stylebox_override("normal",  flat(Color.TRANSPARENT, Color.TRANSPARENT, 35, 0, Vector4i.ZERO))
	trigger.add_theme_stylebox_override("hover",   hover_style)
	trigger.add_theme_stylebox_override("pressed", pressed_style)
	trigger.add_theme_stylebox_override("focus",   flat(Color.TRANSPARENT, Color.TRANSPARENT, 35, 0, Vector4i.ZERO))
	
	trigger.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pill.add_child(trigger)
	
	# Make the pill bouncy
	trigger.mouse_entered.connect(func() -> void:
		pill.create_tween().tween_property(pill, "scale", Vector2(1.06, 1.06), 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	trigger.mouse_exited.connect(func() -> void:
		pill.create_tween().tween_property(pill, "scale", Vector2.ONE, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	trigger.button_down.connect(func() -> void:
		pill.create_tween().tween_property(pill, "scale", Vector2(0.94, 0.94), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	trigger.button_up.connect(func() -> void:
		var tgt := Vector2(1.06, 1.06) if trigger.is_hovered() else Vector2.ONE
		pill.create_tween().tween_property(pill, "scale", tgt, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)

	return pill

static func _profile_pill_style() -> StyleBoxFlat:
	var s := flat(Color(1.0, 1.0, 1.0, 0.65), Color(C_GOLD_LIGHT.r, C_GOLD_LIGHT.g, C_GOLD_LIGHT.b, 0.6), 35, 1, Vector4i.ZERO)
	shadow(s, 10, Color(0.04, 0.10, 0.06, 0.18), Vector2(0, 4))
	return s

static func _avatar_frame_style() -> StyleBoxFlat:
	var s := flat(Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.10), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.5), 22, 1, Vector4i.ZERO)
	return s

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
