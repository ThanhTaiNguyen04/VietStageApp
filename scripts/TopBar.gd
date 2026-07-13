class_name TopBar
extends MarginContainer

signal avatar_pressed

@onready var _avatar_circle : PanelContainer = $Inner/AvatarCircle
@onready var _avatar_thumb  : TextureRect    = $Inner/AvatarCircle/AvatarThumb
@onready var _greet_label   : Label          = $Inner/GreetVBox/GreetLabel
@onready var _sub_label     : Label          = $Inner/GreetVBox/SubLabel
@onready var _streak_pill   : PanelContainer = $Inner/StatRow/StreakPill
@onready var _streak_label  : Label          = $Inner/StatRow/StreakPill/StreakMargin/StreakLabel
@onready var _xp_pill       : PanelContainer = $Inner/StatRow/XPPill
@onready var _xp_label      : Label          = $Inner/StatRow/XPPill/XPMargin/XPLabel

func _ready() -> void:
	_style_avatar()
	_style_pills()
	_greet_label.add_theme_color_override("font_color", DS.C_CREAM)
	_sub_label.add_theme_color_override("font_color",   DS.C_CREAM_DIM)

	_avatar_circle.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			avatar_pressed.emit()
	)

# ── Public API ────────────────────────────────────────────────────────────────

func setup(username: String, streak: int, xp: int, avatar: Texture2D = null) -> void:
	_greet_label.text = "Chào, %s!" % username
	_sub_label.text   = "Tiếp tục luyện tập hôm nay"
	_streak_label.text = "🔥 %d ngày" % streak
	_xp_label.text     = "⭐ %d XP" % xp
	if avatar:
		_avatar_thumb.texture = avatar

func set_sub_text(text: String) -> void:
	_sub_label.text = text

# ── Styling ───────────────────────────────────────────────────────────────────

func _style_avatar() -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = DS.C_BG_DARK
	s.border_color = DS.C_GOLD
	s.border_width_left   = 2
	s.border_width_right  = 2
	s.border_width_top    = 2
	s.border_width_bottom = 2
	s.corner_radius_top_left     = 24
	s.corner_radius_top_right    = 24
	s.corner_radius_bottom_left  = 24
	s.corner_radius_bottom_right = 24
	s.shadow_size  = 10
	s.shadow_color = Color(DS.C_GOLD.r, DS.C_GOLD.g, DS.C_GOLD.b, 0.35)
	_avatar_circle.add_theme_stylebox_override("panel", s)

func _style_pills() -> void:
	var streak_s := DS.pill(
		Color(DS.C_BG_DARK.r, DS.C_BG_DARK.g, DS.C_BG_DARK.b, 0.80),
		Color(0.90, 0.42, 0.08, 0.45)
	)
	_streak_pill.add_theme_stylebox_override("panel", streak_s)
	_streak_label.add_theme_color_override("font_color", Color(1.0, 0.70, 0.22, 1.0))

	var xp_s := DS.pill(
		Color(DS.C_BG_DARK.r, DS.C_BG_DARK.g, DS.C_BG_DARK.b, 0.80),
		Color(DS.C_GOLD.r, DS.C_GOLD.g, DS.C_GOLD.b, 0.45)
	)
	_xp_pill.add_theme_stylebox_override("panel", xp_s)
	_xp_label.add_theme_color_override("font_color", DS.C_GOLD_LIGHT)
