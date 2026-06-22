extends CanvasLayer

const C_GOLD      := Color(0.77, 0.58, 0.15, 1.0)
const C_GOLD_LT   := Color(0.95, 0.82, 0.45, 1.0)
const C_WHITE_DIM := Color(0.13, 0.08, 0.05, 1.0)
const C_BUBBLE_BG := Color(1.00, 1.00, 1.00, 0.98)
const C_RED_SON    := Color(0.70, 0.12, 0.08, 1.0)

const HIDDEN_SCENES := ["SplashScreen", "LoadingScreen", "LoginScreen", "InstrumentSelect", "MainMenu", "CourseMap", "VirtualMusicRoom", "PracticeRoom", "PracticeSaoTruc", "PracticeDanBau"]

const TIPS : Array[String] = [
	"Thư giãn cổ tay khi gảy đàn nhé!",
	"Luyện chậm trước, tốc độ tự tăng.",
	"Tai nghe tốt là bí quyết số một!",
	"Mỗi ngày 15 phút đều hơn 2 giờ/tuần.",
	"Hít thở đều khi thổi sáo nhé!",
	"Bạn đang làm rất tốt! Cứ tiếp tục!",
]

var _tip_idx    : int  = 0
var _is_open    : bool = false
var _last_scene : String = ""

var _root          : Control
var _speech_bubble : PanelContainer
var _bubble_label  : Label

func _ready() -> void:
	layer = 100
	_build_ui()

func _process(_delta: float) -> void:
	var scene_name := _get_scene_name()
	if scene_name == _last_scene:
		return
	_last_scene = scene_name
	_on_scene_changed(scene_name)

func _get_scene_name() -> String:
	var cs := get_tree().current_scene
	return cs.name if cs else ""

func _on_scene_changed(scene_name: String) -> void:
	if scene_name in HIDDEN_SCENES:
		_root.visible = false
		_is_open = false
		_speech_bubble.visible = false
	else:
		_root.visible = true
		get_tree().create_timer(1.2).timeout.connect(func() -> void:
			greet(scene_name)
		)

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.visible = false
	add_child(_root)

	# ── Speech bubble — dark glass, anchored bottom-right above toggle btn ────
	_speech_bubble = PanelContainer.new()
	_speech_bubble.anchor_left   = 1.0; _speech_bubble.anchor_right  = 1.0
	_speech_bubble.anchor_top    = 1.0; _speech_bubble.anchor_bottom = 1.0
	_speech_bubble.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_speech_bubble.grow_vertical   = Control.GROW_DIRECTION_BEGIN
	_speech_bubble.offset_left   = -340.0
	_speech_bubble.offset_top    = -200.0
	_speech_bubble.offset_right  = -16.0
	_speech_bubble.offset_bottom = -112.0
	_speech_bubble.visible = false

	var bub_s := _flat(C_BUBBLE_BG, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45), 16)
	bub_s.shadow_size = 12; bub_s.shadow_color = Color(0, 0, 0, 0.08)
	bub_s.border_width_left = 1; bub_s.border_width_right  = 1
	bub_s.border_width_top  = 1; bub_s.border_width_bottom = 3
	_speech_bubble.add_theme_stylebox_override("panel", bub_s)
	_root.add_child(_speech_bubble)

	var bm := MarginContainer.new()
	bm.layout_mode = 2
	bm.add_theme_constant_override("margin_left",   18)
	bm.add_theme_constant_override("margin_right",  18)
	bm.add_theme_constant_override("margin_top",    14)
	bm.add_theme_constant_override("margin_bottom", 14)
	_speech_bubble.add_child(bm)

	_bubble_label = Label.new()
	_bubble_label.layout_mode = 2
	_bubble_label.add_theme_font_size_override("font_size", 20)
	_bubble_label.add_theme_color_override("font_color", C_WHITE_DIM)
	_bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bm.add_child(_bubble_label)

	# Bubble tail pointing toward toggle button (bottom-right)
	var tail := Control.new()
	tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tail.anchor_left = 0.80; tail.anchor_right = 0.80
	tail.anchor_top  = 1.0;  tail.anchor_bottom = 1.0
	tail.offset_left = -10; tail.offset_right = 10
	tail.offset_top  = 0;   tail.offset_bottom = 14
	tail.draw.connect(func() -> void:
		tail.draw_colored_polygon(
			PackedVector2Array([Vector2(0, 0), Vector2(20, 0), Vector2(10, 14)]),
			C_BUBBLE_BG
		)
	)
	_speech_bubble.add_child(tail)

func play_happy(text: String) -> void:
	show_tip(text)

func _close_bubble() -> void:
	_is_open = false
	var t := create_tween()
	t.tween_property(_speech_bubble, "modulate:a", 0.0, 0.20)
	t.tween_callback(func() -> void: _speech_bubble.visible = false)

# ── Public API ────────────────────────────────────────────────────────────────
func show_tip(text: String, auto_hide_sec: float = 5.0) -> void:
	_bubble_label.text = text
	_is_open = true
	_speech_bubble.modulate.a = 0.0
	_speech_bubble.visible    = true
	create_tween().tween_property(_speech_bubble, "modulate:a", 1.0, 0.22)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if auto_hide_sec > 0.0:
		get_tree().create_timer(auto_hide_sec).timeout.connect(func() -> void:
			if _is_open:
				_close_bubble()
		)

func show_random_tip() -> void:
	_tip_idx = (_tip_idx + 1) % TIPS.size()
	show_tip(TIPS[_tip_idx])

func greet(scene_name: String) -> void:
	var msgs := {
		"MainMenu":        "Chào mừng trở lại! Hôm nay bạn muốn học gì?",
		"CourseMap":       "Chọn bài học phù hợp với trình độ nhé!",
		"PracticeRoom":    "Thư giãn và cảm nhận từng nốt đàn tranh!",
		"PracticeSaoTruc": "Hít thở đều và thổi nhẹ vào miệng sáo nhé!",
		"MiniGame":        "Lắng nghe kỹ âm thanh rồi hãy chọn nhé!",
		"VideoPlayer":     _get_video_player_greet(),
	}
	show_tip(msgs.get(scene_name, TIPS[randi() % TIPS.size()]), 6.0)

func _get_video_player_greet() -> String:
	var inst = SecureDataManager.data.get("selected_instrument", "dan_tranh")
	if inst == "sao_truc":
		return "Chú ý kỹ thuật đặt môi thổi sáo của tôi nhé!"
	elif inst == "dan_bau":
		return "Chú ý kỹ thuật uốn cần đàn bầu của tôi nhé!"
	return "Chú ý kỹ thuật gảy dây đàn tranh của tôi nhé!"

func _flat(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.border_color = border
	s.border_width_left = 1; s.border_width_right  = 1
	s.border_width_top  = 1; s.border_width_bottom = 1
	s.corner_radius_top_left     = radius; s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius; s.corner_radius_bottom_right = radius
	return s
