extends Control
class_name PracticeControlHud

## Shared practice controls for instrument lessons. The parent owns playback;
## this component only presents the common HUD and emits intent signals.
signal back_requested
signal speed_selected(multiplier: float)
signal pause_requested
signal resume_requested
signal restart_requested
signal sample_requested

const SPEEDS := [0.6, 0.8, 1.0, 1.2]
const LABELS := ["60%", "80%", "100%", "120%"]
const WOOD := Color("#2e2116")
const GOLD := Color("#f0c64b")

var _back_button: Button
var _pause_button: Button
var _speed_panel: PanelContainer
var _speed_buttons: Array[Button] = []
var _overlay: ColorRect
var _pause_card: PanelContainer
var _pause_actions: GridContainer
var _resume_button: Button
var _restart_button: Button
var _sample_button: Button
var _resume_label: Label
var _sample_label: Label
var _selected_speed := 1.0

func _ready() -> void:
	name = "PracticeControlHud"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_controls()
	set_speed(1.0)
	set_pause_visible(false)
	resized.connect(_layout_controls)
	_layout_controls()

func set_hud_visible(value: bool) -> void:
	visible = value
	if not value:
		set_pause_visible(false)

func set_playback_controls_visible(value: bool) -> void:
	if _speed_panel:
		_speed_panel.visible = value
	if _pause_button:
		_pause_button.visible = value
	if not value:
		set_pause_visible(false)

func set_speed(multiplier: float) -> void:
	_selected_speed = multiplier
	for index in _speed_buttons.size():
		var selected := is_equal_approx(SPEEDS[index], multiplier)
		_speed_buttons[index].add_theme_stylebox_override("normal", _speed_style(selected))
		_speed_buttons[index].add_theme_stylebox_override("hover", _speed_style(selected))
		_speed_buttons[index].add_theme_color_override("font_color", WOOD if selected else Color.WHITE)

func set_pause_visible(value: bool) -> void:
	_overlay.visible = value

func set_action_labels(resume_label := "Tiếp tục", sample_label := "Nghe mẫu") -> void:
	if _resume_label:
		_resume_label.text = resume_label
	if _sample_label:
		_sample_label.text = sample_label

func _build_controls() -> void:
	_back_button = _icon_button("res://icons8/icons8-back-100.png")
	_back_button.name = "PracticeHudBack"
	_back_button.pressed.connect(func() -> void: back_requested.emit())
	add_child(_back_button)

	_pause_button = _icon_button("res://icons8/icons8-pause-100.png")
	_pause_button.name = "PracticeHudPause"
	_pause_button.pressed.connect(func() -> void: pause_requested.emit())
	add_child(_pause_button)

	_speed_panel = PanelContainer.new()
	_speed_panel.name = "PracticeHudSpeed"
	_speed_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(WOOD, 0.92)
	panel_style.border_color = Color(GOLD, 0.72)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(20)
	panel_style.content_margin_left = 14
	panel_style.content_margin_right = 14
	panel_style.content_margin_top = 7
	panel_style.content_margin_bottom = 7
	_speed_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_speed_panel)
	var speed_row := HBoxContainer.new()
	speed_row.add_theme_constant_override("separation", 8)
	_speed_panel.add_child(speed_row)
	for index in SPEEDS.size():
		if index > 0:
			var separator := Label.new()
			separator.text = "|"
			separator.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
			separator.add_theme_font_size_override("font_size", 20)
			speed_row.add_child(separator)
		var multiplier: float = SPEEDS[index]
		var speed_button := Button.new()
		speed_button.name = "Speed%d" % int(multiplier * 100.0)
		speed_button.text = LABELS[index]
		speed_button.custom_minimum_size = Vector2(68, 34)
		speed_button.focus_mode = Control.FOCUS_NONE
		speed_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		speed_button.add_theme_font_size_override("font_size", 18)
		speed_button.pressed.connect(func() -> void: speed_selected.emit(multiplier))
		speed_row.add_child(speed_button)
		_speed_buttons.append(speed_button)

	_overlay = ColorRect.new()
	_overlay.name = "PracticeHudPauseOverlay"
	_overlay.color = Color(0, 0, 0, 0.45)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.z_index = 20
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	_pause_card = PanelContainer.new()
	_pause_card.name = "PracticeHudPauseCard"
	_pause_card.anchor_left = 0.5
	_pause_card.anchor_top = 0.5
	_pause_card.anchor_right = 0.5
	_pause_card.anchor_bottom = 0.5
	var pause_style := StyleBoxFlat.new()
	pause_style.bg_color = Color(WOOD, 0.97)
	pause_style.border_color = Color(GOLD, 0.7)
	pause_style.set_border_width_all(2)
	pause_style.set_corner_radius_all(20)
	pause_style.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
	pause_style.shadow_size = 18
	pause_style.shadow_offset = Vector2(0, 8)
	_pause_card.add_theme_stylebox_override("panel", pause_style)
	_overlay.add_child(_pause_card)
	var pause_margin := MarginContainer.new()
	pause_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_margin.add_theme_constant_override("margin_left", 22)
	pause_margin.add_theme_constant_override("margin_right", 22)
	pause_margin.add_theme_constant_override("margin_top", 18)
	pause_margin.add_theme_constant_override("margin_bottom", 18)
	_pause_card.add_child(pause_margin)
	var pause_content := VBoxContainer.new()
	pause_content.add_theme_constant_override("separation", 12)
	pause_margin.add_child(pause_content)
	var pause_title := Label.new()
	pause_title.text = "Đã tạm dừng"
	pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_title.add_theme_color_override("font_color", GOLD)
	pause_title.add_theme_font_size_override("font_size", 18)
	var title_font := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if title_font:
		pause_title.add_theme_font_override("font", title_font)
	pause_content.add_child(pause_title)
	_pause_actions = GridContainer.new()
	_pause_actions.columns = 3
	_pause_actions.add_theme_constant_override("h_separation", 14)
	_pause_actions.add_theme_constant_override("v_separation", 10)
	pause_content.add_child(_pause_actions)
	_resume_button = _action_button("Tiếp tục", "res://icons8/icons8-play-100.png")
	_resume_label = _resume_button.get_node("ActionContent/ActionLabel") as Label
	_resume_button.pressed.connect(func() -> void: resume_requested.emit())
	_pause_actions.add_child(_resume_button)
	_restart_button = _action_button("Chơi lại", "res://icons8/icons8-restart-100.png")
	_restart_button.pressed.connect(func() -> void: restart_requested.emit())
	_pause_actions.add_child(_restart_button)
	_sample_button = _action_button("Nghe mẫu", "res://icons8/icons8-speaker-100.png")
	_sample_label = _sample_button.get_node("ActionContent/ActionLabel") as Label
	_sample_button.pressed.connect(func() -> void: sample_requested.emit())
	_pause_actions.add_child(_sample_button)

func _layout_controls() -> void:
	_back_button.position = Vector2(40, 24)
	_pause_button.position = Vector2(maxf(40.0, size.x - 108.0), 24)
	if size.x < 980.0:
		_speed_panel.position = Vector2(maxf(16.0, (size.x - _speed_panel.get_combined_minimum_size().x) * 0.5), 102)
	else:
		_speed_panel.position = Vector2(maxf(120.0, size.x - 124.0 - _speed_panel.get_combined_minimum_size().x), 34)
	if _pause_card:
		if size.x < 620.0:
			_pause_actions.columns = 1
			_pause_card.offset_left = -size.x * 0.5 + 16.0
			_pause_card.offset_right = size.x * 0.5 - 16.0
			_pause_card.offset_top = -154.0
			_pause_card.offset_bottom = 154.0
		else:
			_pause_actions.columns = 3
			_pause_card.offset_left = -310.0
			_pause_card.offset_right = 310.0
			_pause_card.offset_top = -68.0
			_pause_card.offset_bottom = 68.0

func _icon_button(icon_path: String) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(68, 68)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", _round_style(Color(WOOD, 0.92), Color(GOLD, 0.72)))
	button.add_theme_stylebox_override("hover", _round_style(Color(GOLD, 0.25), GOLD))
	button.add_theme_stylebox_override("pressed", _round_style(Color(GOLD, 0.40), GOLD))
	var icon := TextureRect.new()
	icon.texture = load(icon_path) as Texture2D
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	icon.position = Vector2(-18, -18)
	icon.size = Vector2(36, 36)

	var mat := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
	uniform vec4 modulate_color : source_color = vec4(1.0);
	void fragment() {
		vec4 tex = texture(TEXTURE, UV);
		COLOR = vec4(modulate_color.rgb, tex.a * modulate_color.a);
	}"""
	mat.shader = shader
	mat.set_shader_parameter("modulate_color", Color.WHITE)
	icon.material = mat
	button.mouse_entered.connect(func() -> void:
		mat.set_shader_parameter("modulate_color", GOLD)
	)
	button.mouse_exited.connect(func() -> void:
		mat.set_shader_parameter("modulate_color", Color.WHITE)
	)

	button.add_child(icon)
	return button

func _action_button(label: String, icon_path: String) -> Button:
	var button := Button.new()
	button.name = label
	button.tooltip_text = label
	button.custom_minimum_size = Vector2(180, 54)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var empty_style := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty_style)
	button.add_theme_stylebox_override("hover", empty_style)
	button.add_theme_stylebox_override("pressed", empty_style)
	button.add_theme_stylebox_override("focus", empty_style)

	var content := HBoxContainer.new()
	content.name = "ActionContent"
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 10)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(content)

	var icon := TextureRect.new()
	icon.texture = load(icon_path) as Texture2D
	icon.custom_minimum_size = Vector2(24, 24)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	content.add_child(icon)
	var material := _tint_icon(icon, Color.WHITE)

	var text := Label.new()
	text.name = "ActionLabel"
	text.text = label
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	text.add_theme_color_override("font_color", Color.WHITE)
	text.add_theme_font_size_override("font_size", 16)
	var bold_font := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if bold_font:
		text.add_theme_font_override("font", bold_font)
	text.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(text)

	button.mouse_entered.connect(func() -> void:
		material.set_shader_parameter("modulate_color", GOLD)
		text.add_theme_color_override("font_color", GOLD)
	)
	button.mouse_exited.connect(func() -> void:
		material.set_shader_parameter("modulate_color", Color.WHITE)
		text.add_theme_color_override("font_color", Color.WHITE)
	)
	button.button_down.connect(func() -> void:
		icon.self_modulate = Color(0.8, 0.8, 0.8)
		text.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	)
	button.button_up.connect(func() -> void:
		icon.self_modulate = Color.WHITE
		text.add_theme_color_override("font_color", Color.WHITE)
	)
	return button

func _tint_icon(icon: TextureRect, color: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
uniform vec4 modulate_color : source_color = vec4(1.0);
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	COLOR = vec4(modulate_color.rgb, tex.a * modulate_color.a);
}"""
	material.shader = shader
	material.set_shader_parameter("modulate_color", color)
	icon.material = material
	return material

func _speed_style(selected: bool) -> StyleBox:
	if not selected:
		return StyleBoxEmpty.new()
	var style := StyleBoxFlat.new()
	style.bg_color = GOLD
	style.set_corner_radius_all(11)
	return style

func _round_style(background: Color, border: Color, radius := 34) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	return style
