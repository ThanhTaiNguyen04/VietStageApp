extends Control

# ─── Color Palette ─────────────────────────────────────────────────────────────
const C_GOLD       := Color(0.77, 0.58, 0.15, 1.0)
const C_GOLD_LIGHT := Color(0.92, 0.76, 0.30, 1.0)
const C_JADE       := Color(0.12, 0.37, 0.23, 1.0)
const C_RED_SON    := Color(0.70, 0.12, 0.08, 1.0)
const C_CREAM      := Color(1.00, 0.97, 0.88, 1.0)
const C_CREAM_DIM  := Color(0.80, 0.76, 0.66, 1.0)
const C_DARK_WOOD  := Color(0.98, 0.97, 0.94, 1.0) # main background cream
const C_SCREEN_BG  := Color(0.95, 0.93, 0.89, 1.0) # screen placeholder gray-cream

# ─── Refs ───
@onready var player_card  : PanelContainer = $Center/PlayerCard
@onready var back_btn     : Button         = $Center/PlayerCard/CardM/PlayerVBox/TopRow/BackBtn
@onready var play_btn     : Button         = $Center/PlayerCard/CardM/PlayerVBox/ControlRow/PlayBtn
@onready var progress_bar : ProgressBar    = $Center/PlayerCard/CardM/PlayerVBox/ControlRow/TimeProgress
@onready var time_label   : Label          = $Center/PlayerCard/CardM/PlayerVBox/ControlRow/TimeLabel
@onready var sub_label    : Label          = $Center/PlayerCard/CardM/PlayerVBox/SubPanel/SubM/SubLabel
@onready var skip_btn     : Button         = $Center/PlayerCard/CardM/PlayerVBox/FooterRow/SkipBtn
@onready var complete_btn : Button         = $Center/PlayerCard/CardM/PlayerVBox/FooterRow/CompleteBtn
@onready var screen_anch  : Control        = $Center/PlayerCard/CardM/PlayerVBox/VideoFrame/FrameM/ScreenAnchor
@onready var play_overlay : PanelContainer = $Center/PlayerCard/CardM/PlayerVBox/VideoFrame/FrameM/ScreenAnchor/PlayOverlay
@onready var linh_rect     : TextureRect    = $Center/PlayerCard/CardM/PlayerVBox/VideoFrame/FrameM/ScreenAnchor/LinhTexture
@onready var video_stream_player : VideoStreamPlayer = $Center/PlayerCard/CardM/PlayerVBox/VideoFrame/FrameM/ScreenAnchor/VideoStreamPlayer

# ─── State ───
var _playing     := false
var _time        := 0.0
const DURATION   := 10.0

const SUBTITLES_DAN_TRANH := [
	{"start": 0.0,  "end": 2.5,  "text": "Xin chào bạn! Tôi là cô Mai, người đồng hành hướng dẫn nhạc cụ truyền thống của bạn tại VietStage."},
	{"start": 2.5,  "end": 5.5,  "text": "Hôm nay, chúng ta sẽ cùng nhau làm quen với tư thế cơ bản, cách đặt ngón gảy và làm quen nốt đầu tiên."},
	{"start": 5.5,  "end": 8.0,  "text": "Hãy chú ý giữ lưng thẳng, cổ tay thả lỏng nhẹ nhàng và lắng nghe âm vang tự nhiên từ nhạc cụ nhé."},
	{"start": 8.0,  "end": 10.0, "text": "Tuyệt vời! Bây giờ hãy nhấn 'Hoàn Thành Video' để nhận 80 điểm và vào phòng tập luyện thực hành ngay thôi!"}
]

const SUBTITLES_SAO_TRUC := [
	{"start": 0.0,  "end": 2.5,  "text": "Xin chào bạn! Tôi là cô Mai, người đồng hành hướng dẫn nhạc cụ truyền thống của bạn tại VietStage."},
	{"start": 2.5,  "end": 5.5,  "text": "Hôm nay, chúng ta sẽ cùng nhau làm quen với tư thế cầm sáo, cách đặt môi và thổi nốt nhạc đầu tiên."},
	{"start": 5.5,  "end": 8.0,  "text": "Hãy chú ý giữ thẳng lưng, lấy hơi sâu bằng bụng và lắng nghe âm vang trong trẻo của tiếng sáo nhé."},
	{"start": 8.0,  "end": 10.0, "text": "Tuyệt vời! Bây giờ hãy nhấn 'Hoàn Thành Video' để nhận 80 điểm và vào phòng tập luyện thực hành ngay thôi!"}
]

const SUBTITLES_DAN_BAU := [
	{"start": 0.0,  "end": 2.5,  "text": "Xin chào bạn! Tôi là cô Mai, người đồng hành hướng dẫn nhạc cụ truyền thống của bạn tại VietStage."},
	{"start": 2.5,  "end": 5.5,  "text": "Hôm nay, chúng ta sẽ cùng nhau làm quen với tư thế cơ bản, cách gẩy và tạo tiếng bồi âm đầu tiên."},
	{"start": 5.5,  "end": 8.0,  "text": "Hãy chú ý giữ lưng thẳng, tay cầm que gảy nhẹ nhàng và lắng nghe âm vang độc đáo từ một dây đàn nhé."},
	{"start": 8.0,  "end": 10.0, "text": "Tuyệt vời! Bây giờ hãy nhấn 'Hoàn Thành Video' để nhận 80 điểm và vào phòng tập luyện thực hành ngay thôi!"}
]

var active_subtitles := []

func _ready() -> void:
	var inst := InstrumentSelect.selected_instrument
	if inst == "sao_truc":
		video_stream_player.stream = load("res://Video/st_bai1.ogv")
		active_subtitles = SUBTITLES_SAO_TRUC
	elif inst == "dan_bau":
		video_stream_player.stream = load("res://Video/intro_video.ogv")
		active_subtitles = SUBTITLES_DAN_BAU
	else:
		video_stream_player.stream = load("res://Video/intro_video.ogv")
		active_subtitles = SUBTITLES_DAN_TRANH

	_build_theme()
	_connect_buttons()
	_update_play_state()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.35)

func _process(delta: float) -> void:
	if _playing:
		_time += delta
		if _time >= DURATION:
			_time = DURATION
			_playing = false
			_update_play_state()
			_va_success_prompt()
			video_stream_player.stop()
			linh_rect.visible = true
			video_stream_player.visible = false
		
		# Update media progress
		progress_bar.value = (_time / DURATION) * 100.0
		time_label.text = "0:%02d / 0:10" % [int(_time)]
		
		# Update subtitles
		var sub_found := false
		for sub in active_subtitles:
			var s_start: float = sub["start"]
			var s_end: float = sub["end"]
			if _time >= s_start and _time < s_end:
				sub_label.text = sub["text"] as String
				sub_found = true
				break
		if not sub_found:
			sub_label.text = ""

func _build_theme() -> void:
	# Main card container
	var card_s := _flat(Color(1.0, 1.0, 1.0, 0.95), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25), 28)
	card_s.shadow_size = 30; card_s.shadow_color = Color(0.13, 0.08, 0.05, 0.10)
	player_card.add_theme_stylebox_override("panel", card_s)

	# Video screen box
	var frame_s := _flat(C_SCREEN_BG, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.15), 16)
	($Center/PlayerCard/CardM/PlayerVBox/VideoFrame as PanelContainer).add_theme_stylebox_override("panel", frame_s)

	# Play Overlay circle button
	var overlay_s := _flat(C_GOLD, C_GOLD_LIGHT, 44)
	overlay_s.shadow_size = 8; overlay_s.shadow_color = Color(0.13, 0.08, 0.05, 0.18)
	play_overlay.add_theme_stylebox_override("panel", overlay_s)
	play_overlay.get_node("PlayText").add_theme_color_override("font_color", Color(0.13, 0.08, 0.05, 1.0))

	# Subtitles box - light warm background
	var sub_s := _flat(Color(0.95, 0.93, 0.89, 0.85), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.20), 16)
	($Center/PlayerCard/CardM/PlayerVBox/SubPanel as PanelContainer).add_theme_stylebox_override("panel", sub_s)
	sub_label.add_theme_color_override("font_color", Color(0.13, 0.08, 0.05, 1.0))

	# Buttons
	_style_outlined_btn(back_btn, 18)
	_style_outlined_btn(skip_btn, 22)
	_style_outlined_btn(play_btn, 16)

	# Complete Btn (Gold filled primary CTA)
	var c_n := _flat(C_GOLD, Color(1,1,1,0.2), 22)
	c_n.shadow_size = 12; c_n.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25)
	var c_h := _flat(C_GOLD_LIGHT, Color(1,1,1,0.3), 22)
	c_h.shadow_size = 18; c_h.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35)
	complete_btn.add_theme_stylebox_override("normal", c_n)
	complete_btn.add_theme_stylebox_override("hover", c_h)
	complete_btn.add_theme_stylebox_override("pressed", _flat(C_GOLD.darkened(0.18), Color(0,0,0,0.2), 22))
	complete_btn.add_theme_stylebox_override("focus", _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	complete_btn.add_theme_color_override("font_color", Color(0.13, 0.08, 0.05, 1.0))
	complete_btn.add_theme_color_override("font_hover_color", Color(0.13, 0.08, 0.05, 1.0))
	complete_btn.add_theme_color_override("font_pressed_color", Color(0.13, 0.08, 0.05, 1.0))
	complete_btn.add_theme_font_size_override("font_size", 20)

	# Progress bar
	var pf := StyleBoxFlat.new(); pf.bg_color = C_GOLD
	pf.corner_radius_top_left = 6; pf.corner_radius_top_right = 6
	pf.corner_radius_bottom_left = 6; pf.corner_radius_bottom_right = 6
	var pb := StyleBoxFlat.new(); pb.bg_color = Color(0.13, 0.08, 0.05, 0.08)
	pb.corner_radius_top_left = 6; pb.corner_radius_top_right = 6
	pb.corner_radius_bottom_left = 6; pb.corner_radius_bottom_right = 6
	progress_bar.add_theme_stylebox_override("fill", pf)
	progress_bar.add_theme_stylebox_override("background", pb)
	time_label.add_theme_color_override("font_color", Color(0.13, 0.08, 0.05, 0.70))

func _connect_buttons() -> void:
	back_btn.pressed.connect(_go_back)
	skip_btn.pressed.connect(_go_back)
	complete_btn.pressed.connect(_on_complete)
	play_btn.pressed.connect(_toggle_play)

	play_overlay.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			_toggle_play()
	)

	_make_button_bouncy(back_btn)
	_make_button_bouncy(skip_btn)
	_make_button_bouncy(play_btn)
	_make_button_bouncy(complete_btn)

func _toggle_play() -> void:
	if _time >= DURATION:
		# replay from start
		_time = 0.0
		video_stream_player.stream_position = 0.0
	_playing = not _playing
	_update_play_state()

func _update_play_state() -> void:
	if _playing:
		play_btn.text = "⏸"
		play_overlay.visible = false
		linh_rect.visible = false
		video_stream_player.visible = true
		if video_stream_player.paused:
			video_stream_player.paused = false
		else:
			video_stream_player.play()
	else:
		play_btn.text = "▶"
		play_overlay.visible = true
		if video_stream_player.is_playing() and not video_stream_player.paused:
			video_stream_player.paused = true

func _va_success_prompt() -> void:
	sub_label.text = "Tuyệt vời! Bài học hoàn thành. Hãy bấm nút 'Hoàn Thành Video' màu vàng để mở khóa thực hành!"
	sub_label.add_theme_color_override("font_color", C_RED_SON)
	# Flash the complete button
	var ct := create_tween()
	ct.tween_property(complete_btn, "scale", Vector2(1.08, 1.08), 0.15).set_trans(Tween.TRANS_BACK)
	ct.tween_property(complete_btn, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)

func _on_complete() -> void:
	video_stream_player.stop()
	var inst := InstrumentSelect.selected_instrument
	SecureDataManager.complete_lesson(inst, "Node1", 3) # Mark Intro completed with 3 stars securely!
	CourseMap.video_completed = true
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.22)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/CourseMap.tscn"))

func _go_back() -> void:
	video_stream_player.stop()
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.22)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/CourseMap.tscn"))

func _style_outlined_btn(btn: Button, radius: int) -> void:
	var bn := _flat(Color(0,0,0,0), Color(0.13, 0.08, 0.05, 0.20), radius)
	var bh := _flat(Color(0,0,0,0.04), Color(0.70, 0.12, 0.08, 0.60), radius)
	btn.add_theme_stylebox_override("normal", bn)
	btn.add_theme_stylebox_override("hover", bh)
	btn.add_theme_stylebox_override("pressed", _flat(Color(0,0,0,0.08), C_GOLD, radius))
	btn.add_theme_stylebox_override("focus", _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	btn.add_theme_color_override("font_color", Color(0.13, 0.08, 0.05, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(0.70, 0.12, 0.08, 1.0))

func _flat(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.border_color = border
	s.border_width_left = 2; s.border_width_right = 2
	s.border_width_top  = 2; s.border_width_bottom = 2
	s.corner_radius_top_left     = radius; s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius; s.corner_radius_bottom_right = radius
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
