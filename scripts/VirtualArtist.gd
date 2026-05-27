extends CanvasLayer

# ── Colors ────────────────────────────────────────────────────────────────────
const C_RED_SON    := Color(0.72, 0.12, 0.08, 1.0)
const C_RED_DK     := Color(0.38, 0.06, 0.04, 0.97)
const C_GOLD       := Color(0.95, 0.72, 0.18, 1.0)
const C_GOLD_LIGHT := Color(1.00, 0.87, 0.45, 1.0)
const C_CREAM      := Color(1.00, 0.97, 0.88, 1.0)

# ── Animation frames ──────────────────────────────────────────────────────────
# Loaded at runtime after editor imports them. Fallback: character_linh.jpg
const FRAME_PATHS := [
	"res://assets/textures/mai_idle.jpg",
	"res://assets/textures/mai_talking.jpg",
	"res://assets/textures/mai_happy.jpg",
]
const FALLBACK_PATH := "res://assets/textures/character_linh.jpg"

enum Anim { IDLE, TALKING, HAPPY }

var _frames      : Array[Texture2D] = []
var _cur_anim    : Anim = Anim.IDLE
var _anim_timer  : float = 0.0
var _talk_tick   : float = 0.0
var _is_talking  : bool  = false
var _is_visible  : bool  = false

# ── Tip pool ──────────────────────────────────────────────────────────────────
const TIPS : Array[String] = [
	"Thư giãn cổ tay khi gảy đàn nhé!",
	"Luyện chậm trước, tốc độ tự tăng.",
	"Tai nghe tốt là bí quyết số một!",
	"Mỗi ngày 15 phút đều hơn 2 giờ/tuần.",
	"Hít thở đều khi thổi sáo nhé!",
	"Nhắm mắt và cảm nhận âm nhạc...",
	"Tiếng đàn tranh như tiếng suối chảy.",
	"Bạn đang làm rất tốt! Cứ tiếp tục!",
]
var _tip_idx : int = 0

# ── Node refs ─────────────────────────────────────────────────────────────────
var _char_panel    : Control
var _char_texture  : TextureRect
var _speech_bubble : PanelContainer
var _bubble_label  : Label
var _toggle_btn    : Button
var _bob_tween     : Tween

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	layer = 100
	_load_frames()
	_build_ui()
	_start_bob()
	# Welcome greeting 2s after any scene loads
	get_tree().create_timer(2.0).timeout.connect(func() -> void:
		show_tip("Chào mừng! Tôi là Mai — nghệ sĩ ảo của bạn.")
	)

func _process(delta: float) -> void:
	if not _is_visible or not _is_talking:
		return
	# Flicker between IDLE ↔ TALKING while speech bubble is visible
	_talk_tick += delta
	if _talk_tick >= 0.35:
		_talk_tick = 0.0
		var nxt := Anim.IDLE if _cur_anim == Anim.TALKING else Anim.TALKING
		_set_frame(nxt)

# ─── Load frames ─────────────────────────────────────────────────────────────
func _load_frames() -> void:
	_frames.clear()
	var fallback : Texture2D = load(FALLBACK_PATH)
	for path in FRAME_PATHS:
		# Safely attempt load without crashing if not yet imported
		var f : Texture2D
		if FileAccess.file_exists(path + ".import"):
			f = load(path)
		if f:
			_frames.append(f)
		else:
			_frames.append(fallback)   # use fallback so array always has 3 slots

func _set_frame(anim: Anim) -> void:
	_cur_anim = anim
	if _frames.size() > int(anim):
		_char_texture.texture = _frames[int(anim)]

# ─── Build UI ────────────────────────────────────────────────────────────────
func _build_ui() -> void:
	# Full-screen transparent root
	var root := Control.new()
	root.name = "VARoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# ── Character panel anchored bottom-right ──────────────────────────────
	_char_panel = Control.new()
	_char_panel.name = "CharPanel"
	_char_panel.anchor_left   = 1.0; _char_panel.anchor_right  = 1.0
	_char_panel.anchor_top    = 1.0; _char_panel.anchor_bottom = 1.0
	_char_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_char_panel.grow_vertical   = Control.GROW_DIRECTION_BEGIN
	_char_panel.offset_left   = -280.0
	_char_panel.offset_top    = -420.0
	_char_panel.offset_right  = -12.0
	_char_panel.offset_bottom = -96.0    # gap above toggle button
	_char_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_char_panel)

	# ── Speech bubble above character ──────────────────────────────────────
	_speech_bubble = PanelContainer.new()
	_speech_bubble.name = "SpeechBubble"
	_speech_bubble.anchor_left   = 0.0;  _speech_bubble.anchor_right  = 1.0
	_speech_bubble.anchor_top    = 0.0;  _speech_bubble.anchor_bottom = 0.0
	_speech_bubble.offset_left   = -240.0
	_speech_bubble.offset_top    = 0.0
	_speech_bubble.offset_right  = 0.0
	_speech_bubble.offset_bottom = 130.0
	_speech_bubble.visible = false
	var bub_s := _flat(Color(0.97, 0.96, 0.90, 0.97), C_RED_SON, 18)
	bub_s.border_width_bottom = 5
	bub_s.shadow_size = 16; bub_s.shadow_color = Color(0, 0, 0, 0.30)
	_speech_bubble.add_theme_stylebox_override("panel", bub_s)
	_char_panel.add_child(_speech_bubble)

	var bm := MarginContainer.new()
	bm.layout_mode = 2
	bm.add_theme_constant_override("margin_left",   20)
	bm.add_theme_constant_override("margin_right",  20)
	bm.add_theme_constant_override("margin_top",    16)
	bm.add_theme_constant_override("margin_bottom", 16)
	_speech_bubble.add_child(bm)

	_bubble_label = Label.new()
	_bubble_label.layout_mode = 2
	_bubble_label.add_theme_font_size_override("font_size", 22)
	_bubble_label.add_theme_color_override("font_color", C_RED_DK)
	_bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bm.add_child(_bubble_label)

	# Bubble tail triangle (drawn via sub-control)
	var tail := Control.new()
	tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tail.anchor_left = 0.85; tail.anchor_right = 0.85
	tail.anchor_top  = 1.0;  tail.anchor_bottom = 1.0
	tail.offset_left = -12; tail.offset_right = 12
	tail.offset_top  = 0;   tail.offset_bottom = 16
	tail.draw.connect(func() -> void:
		var pts := PackedVector2Array([
			Vector2(0, 0), Vector2(24, 0), Vector2(12, 16)
		])
		tail.draw_colored_polygon(pts, Color(0.97, 0.96, 0.90, 0.97))
	)
	_speech_bubble.add_child(tail)

	# ── Character TextureRect ──────────────────────────────────────────────
	_char_texture = TextureRect.new()
	_char_texture.name = "CharTexture"
	_char_texture.anchor_left   = 0.0;  _char_texture.anchor_right  = 1.0
	_char_texture.anchor_top    = 0.0;  _char_texture.anchor_bottom = 1.0
	_char_texture.offset_top    = 110.0   # leave room for speech bubble
	_char_texture.expand_mode   = TextureRect.EXPAND_IGNORE_SIZE
	_char_texture.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_char_texture.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	if _frames.size() > 0 and _frames[0]:
		_char_texture.texture = _frames[0]
	_char_panel.add_child(_char_texture)

	# ── Toggle button ── round red pill, bottom-right ──────────────────────
	_toggle_btn = Button.new()
	_toggle_btn.name = "ToggleBtn"
	_toggle_btn.anchor_left   = 1.0; _toggle_btn.anchor_right  = 1.0
	_toggle_btn.anchor_top    = 1.0; _toggle_btn.anchor_bottom = 1.0
	_toggle_btn.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_toggle_btn.grow_vertical   = Control.GROW_DIRECTION_BEGIN
	_toggle_btn.offset_left   = -160.0
	_toggle_btn.offset_top    = -88.0
	_toggle_btn.offset_right  = -16.0
	_toggle_btn.offset_bottom = -16.0
	_toggle_btn.text = "Mai"
	_toggle_btn.add_theme_font_size_override("font_size", 22)

	var tb_n := _flat(C_RED_SON, C_GOLD, 36)
	tb_n.shadow_size = 12; tb_n.shadow_color = Color(0, 0, 0, 0.44)
	tb_n.border_width_bottom = 5
	tb_n.content_margin_left = 68

	var tb_h := _flat(C_RED_DK, C_GOLD_LIGHT, 36)
	tb_h.shadow_size = 16; tb_h.shadow_color = Color(0, 0, 0, 0.44)
	tb_h.content_margin_left = 68

	var tb_p := _flat(C_RED_DK, C_GOLD, 36)
	tb_p.content_margin_left = 68

	_toggle_btn.add_theme_stylebox_override("normal",  tb_n)
	_toggle_btn.add_theme_stylebox_override("hover",   tb_h)
	_toggle_btn.add_theme_stylebox_override("pressed", tb_p)
	_toggle_btn.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	_toggle_btn.add_theme_color_override("font_color",         C_GOLD)
	_toggle_btn.add_theme_color_override("font_hover_color",   C_GOLD_LIGHT)
	_toggle_btn.add_theme_color_override("font_pressed_color", C_CREAM)
	_toggle_btn.pressed.connect(_on_toggle_pressed)
	root.add_child(_toggle_btn)

	# ── Circular Avatar Container ──
	var avatar_container := PanelContainer.new()
	avatar_container.name = "AvatarContainer"
	avatar_container.custom_minimum_size = Vector2(48, 48)
	avatar_container.clip_contents = true

	var cir_sb := StyleBoxFlat.new()
	cir_sb.corner_radius_top_left = 24
	cir_sb.corner_radius_top_right = 24
	cir_sb.corner_radius_bottom_left = 24
	cir_sb.corner_radius_bottom_right = 24
	cir_sb.bg_color = Color.WHITE
	cir_sb.border_width_left = 2; cir_sb.border_width_right = 2
	cir_sb.border_width_top = 2; cir_sb.border_width_bottom = 2
	cir_sb.border_color = C_GOLD
	avatar_container.add_theme_stylebox_override("panel", cir_sb)

	var avatar := TextureRect.new()
	avatar.texture = load("res://assets/textures/virtual_artist_mai.jpg")
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	avatar_container.add_child(avatar)

	avatar_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toggle_btn.add_child(avatar_container)

	# Center vertically on the left side of the toggle button
	avatar_container.anchor_left = 0.0; avatar_container.anchor_right = 0.0
	avatar_container.anchor_top = 0.5; avatar_container.anchor_bottom = 0.5
	avatar_container.offset_left = 12
	avatar_container.offset_top = -24
	avatar_container.offset_right = 60
	avatar_container.offset_bottom = 24

	# Initially hidden
	_char_panel.modulate.a = 0.0
	_char_panel.scale = Vector2(0.55, 0.55)

# ─── Bob animation ────────────────────────────────────────────────────────────
func _start_bob() -> void:
	_bob_tween = create_tween().set_loops()
	_bob_tween.tween_property(_char_panel, "position:y", -14.0, 1.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_bob_tween.tween_property(_char_panel, "position:y", 0.0,   1.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _on_toggle_pressed() -> void:
	if _is_visible: hide_artist()
	else: show_artist()

# ─── Public API ───────────────────────────────────────────────────────────────

## Hiện nhân vật lên với animation spring-in
func show_artist() -> void:
	_is_visible = true
	_char_panel.visible = true
	_set_frame(Anim.HAPPY)
	var t := create_tween().set_parallel(true)
	t.tween_property(_char_panel, "modulate:a", 1.0, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_char_panel, "scale", Vector2.ONE,    0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# After spring-in → settle to IDLE
	get_tree().create_timer(0.55).timeout.connect(func() -> void:
		_set_frame(Anim.IDLE)
	)

## Ẩn nhân vật
func hide_artist() -> void:
	_is_visible = false
	_is_talking = false
	_speech_bubble.visible = false
	var t := create_tween().set_parallel(true)
	t.tween_property(_char_panel, "modulate:a", 0.0,           0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(_char_panel, "scale", Vector2(0.55, 0.55), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

## Hiện nhân vật với tin nhắn trong speech bubble
func show_tip(text: String, auto_hide_sec: float = 5.0) -> void:
	_bubble_label.text = text
	if not _is_visible:
		show_artist()

	await get_tree().process_frame
	_speech_bubble.modulate.a = 0.0
	_speech_bubble.visible = true
	_is_talking = true
	_set_frame(Anim.TALKING)

	var t := create_tween()
	t.tween_property(_speech_bubble, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if auto_hide_sec > 0.0:
		get_tree().create_timer(auto_hide_sec).timeout.connect(func() -> void:
			_is_talking = false
			_set_frame(Anim.IDLE)
			var t2 := create_tween()
			t2.tween_property(_speech_bubble, "modulate:a", 0.0, 0.3)
			t2.tween_callback(func() -> void: _speech_bubble.visible = false)
		)

## Phát vui mừng (đúng câu trả lời, hoàn thành bài...)
func play_happy(text: String = "") -> void:
	if not _is_visible: show_artist()
	_is_talking = false
	_set_frame(Anim.HAPPY)
	# Quick scale pop
	var t := create_tween().set_parallel(true)
	t.tween_property(_char_panel, "scale", Vector2(1.12, 1.12), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_char_panel, "rotation_degrees", 6.0,  0.10)
	get_tree().create_timer(0.15).timeout.connect(func() -> void:
		var t2 := create_tween().set_parallel(true)
		t2.tween_property(_char_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK)
		t2.tween_property(_char_panel, "rotation_degrees", 0.0,  0.20)
	)
	if text.length() > 0:
		get_tree().create_timer(0.3).timeout.connect(func() -> void:
			show_tip(text, 4.0)
		)
	else:
		get_tree().create_timer(1.5).timeout.connect(func() -> void:
			_set_frame(Anim.IDLE)
		)

## Hiện random tip từ pool
func show_random_tip() -> void:
	_tip_idx = (_tip_idx + 1) % TIPS.size()
	show_tip(TIPS[_tip_idx])

## Tự chào theo tên màn hình
func greet(scene_name: String) -> void:
	var msgs : Dictionary = {
		"MainMenu":        "Chào mừng trở lại! Hôm nay bạn muốn học gì?",
		"CourseMap":       "Chọn bài học phù hợp với trình độ nhé!",
		"PracticeRoom":    "Thư giãn và cảm nhận từng nốt đàn tranh!",
		"PracticeSaoTruc": "Hít thở đều và thổi nhẹ vào miệng sáo nhé!",
		"MiniGame":        "Lắng nghe kỹ âm thanh rồi hãy chọn nhé!",
		"VideoPlayer":     "Chú ý kỹ thuật bấm dây của tôi nhé!",
	}
	var msg : String = msgs.get(scene_name, TIPS[randi() % TIPS.size()])
	show_tip(msg, 6.0)

# ─── Helper ───────────────────────────────────────────────────────────────────
func _flat(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.border_color = border
	s.border_width_left = 2; s.border_width_right  = 2
	s.border_width_top  = 2; s.border_width_bottom = 2
	s.corner_radius_top_left     = radius; s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius; s.corner_radius_bottom_right = radius
	return s
