extends Control
class_name VideoPlayer

# ─── Color Palette ─────────────────────────────────────────────────────────────
const C_GOLD       := Color(0.77, 0.58, 0.15, 1.0)
const C_GOLD_LIGHT := Color(0.92, 0.76, 0.30, 1.0)
const C_JADE       := Color(0.12, 0.37, 0.23, 1.0)
const C_RED_SON    := Color(0.09, 0.27, 0.18, 1.0)
const C_CREAM      := Color(1.00, 0.97, 0.88, 1.0)
const C_CREAM_DIM  := Color(0.80, 0.76, 0.66, 1.0)
const C_DARK_WOOD  := Color(0.98, 0.97, 0.94, 1.0) # main background cream
const C_SCREEN_BG  := Color(0.95, 0.93, 0.89, 1.0) # screen placeholder gray-cream

# ─── Refs ───
@onready var player_card  : PanelContainer = $Center/PlayerCard
@onready var card_m       : MarginContainer = $Center/PlayerCard/CardM
@onready var player_vbox  : VBoxContainer   = $Center/PlayerCard/CardM/PlayerVBox
@onready var top_row      : HBoxContainer   = $Center/PlayerCard/CardM/PlayerVBox/TopRow
@onready var sub_panel    : PanelContainer  = $Center/PlayerCard/CardM/PlayerVBox/SubPanel
@onready var footer_row   : HBoxContainer   = $Center/PlayerCard/CardM/PlayerVBox/FooterRow
@onready var video_frame  : PanelContainer  = $Center/PlayerCard/CardM/PlayerVBox/VideoFrame
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
var _duration    := 10.0
var _video_zoomed := false

const SPEEDS := [0.5, 1.0, 1.5, 2.0]
var speed_idx := 1

var rewind_btn : Button
var forward_btn : Button
var speed_btn : Button
var zoom_btn : Button

const SUBTITLES_DAN_TRANH := [
	{"start": 0.0,  "end": 2.5,  "text": "Xin chào bạn! Tôi là giảng viên, người đồng hành hướng dẫn nhạc cụ truyền thống của bạn tại VietStage."},
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
	{"start": 0.0,  "end": 2.0,  "text": "Xin chào bạn! Tôi là cô Mai, người đồng hành hướng dẫn nhạc cụ truyền thống của bạn tại VietStage."},
	{"start": 2.0,  "end": 4.5,  "text": "Hôm nay, chúng ta sẽ cùng nhau làm quen với tư thế cơ bản, cách gẩy và tạo tiếng bồi âm đầu tiên."},
	{"start": 4.5,  "end": 6.5,  "text": "Hãy chú ý giữ lưng thẳng, tay cầm que gảy nhẹ nhàng và lắng nghe âm vang độc đáo từ một dây đàn nhé."},
	{"start": 6.5,  "end": 8.0,  "text": "Tuyệt vời! Bây giờ hãy nhấn 'Hoàn Thành Video' để nhận 80 điểm và vào phòng tập luyện thực hành ngay thôi!"}
]

static var custom_video_path := ""
static var custom_subtitles : Array = []

var active_subtitles := []

func _ready() -> void:
	var inst := InstrumentSelect.selected_instrument
	if custom_video_path != "":
		video_stream_player.stream = load(custom_video_path)
		active_subtitles = custom_subtitles
	else:
		if inst == "sao_truc":
			video_stream_player.stream = load("res://Video/Giảng_viên_dạy_sáo_trúc_202606300842.ogv")
			active_subtitles = SUBTITLES_SAO_TRUC
		elif inst == "dan_bau":
			video_stream_player.stream = load("res://Video/coMai_danBau.ogv")
			active_subtitles = SUBTITLES_DAN_BAU
		else:
			video_stream_player.stream = load("res://Video/giang_vien_dan_tranh_1942.ogv")
			active_subtitles = SUBTITLES_DAN_TRANH

	# Make PlayerCard take up the entire screen programmatically
	var center_container = $Center
	if center_container:
		center_container.remove_child(player_card)
		add_child(player_card)
		player_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		player_card.custom_minimum_size = Vector2.ZERO
		center_container.queue_free()

	# Instantiate buttons programmatically
	var control_row := player_vbox.get_node("ControlRow") as HBoxContainer
	
	rewind_btn = Button.new()
	rewind_btn.text = "⏪"
	rewind_btn.custom_minimum_size = Vector2(50, 42)
	control_row.add_child(rewind_btn)
	control_row.move_child(rewind_btn, 0)
	
	forward_btn = Button.new()
	forward_btn.text = "⏩"
	forward_btn.custom_minimum_size = Vector2(50, 42)
	control_row.add_child(forward_btn)
	control_row.move_child(forward_btn, 2)
	
	speed_btn = Button.new()
	speed_btn.text = "1.0x"
	speed_btn.custom_minimum_size = Vector2(65, 42)
	control_row.add_child(speed_btn)
	control_row.move_child(speed_btn, 3)
	
	zoom_btn = Button.new()
	zoom_btn.text = "⛶"
	zoom_btn.custom_minimum_size = Vector2(50, 42)
	control_row.add_child(zoom_btn)

	_build_theme()
	_connect_buttons()
	_update_play_state()
	
	# Determine duration dynamically
	if video_stream_player.stream:
		var stream_len := video_stream_player.get_stream_length()
		if stream_len > 0.0:
			_duration = stream_len
		else:
			if inst == "sao_truc":
				_duration = 10.0
			elif inst == "dan_bau":
				_duration = 10.0
			else:
				_duration = 10.0 # new danTranh video is 10.0s
	
	# Update initially
	_update_media_progress()
	
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.35)

func _process(delta: float) -> void:
	if _playing:
		if video_stream_player.is_playing():
			_time = video_stream_player.stream_position
		
		if _time >= _duration:
			_time = _duration
			_playing = false
			_update_play_state()
			_va_success_prompt()
			video_stream_player.stop()
			linh_rect.visible = true
			video_stream_player.visible = false
			
		_update_media_progress()

func _update_media_progress() -> void:
	# Progress bar
	if _duration > 0.0:
		progress_bar.value = (_time / _duration) * 100.0
	else:
		progress_bar.value = 0.0
		
	# Time label
	var cur_min := int(_time) / 60
	var cur_sec := int(_time) % 60
	var dur_min := int(_duration) / 60
	var dur_sec := int(_duration) % 60
	time_label.text = "%d:%02d / %d:%02d" % [cur_min, cur_sec, dur_min, dur_sec]
	
	# Subtitles - only update if the video is not at the end
	if _time < _duration:
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
	var inst := InstrumentSelect.selected_instrument
	
	var theme_color := C_RED_SON      # default for dan_tranh (jade green)
	var accent_color := C_GOLD        # default for dan_tranh (gold)
	var accent_light := C_GOLD_LIGHT
	var bg_color := Color(0.98, 0.97, 0.94, 1.0) # cream background
	
	if inst == "sao_truc":
		theme_color = C_JADE
		accent_color = Color(0.25, 0.65, 0.45, 1.0)
		accent_light = Color(0.35, 0.85, 0.60, 1.0)
		bg_color = Color(0.95, 0.97, 0.95, 1.0)
	elif inst == "dan_bau":
		theme_color = Color(0.38, 0.25, 0.60, 1.0)
		accent_color = Color(0.55, 0.45, 0.80, 1.0)
		accent_light = Color(0.70, 0.60, 0.90, 1.0)
		bg_color = Color(0.96, 0.95, 0.98, 1.0)

	# Apply BG color
	var bg_node := get_node_or_null("BG") as ColorRect
	if bg_node:
		bg_node.color = bg_color

	# Title text color
	var title_lbl := top_row.get_node_or_null("VideoTitle") as Label
	if title_lbl:
		title_lbl.add_theme_color_override("font_color", theme_color)

	# Main card container (styled flat for fullscreen layout)
	var card_s := _flat(Color(1.0, 1.0, 1.0, 0.95), Color(accent_color.r, accent_color.g, accent_color.b, 0.15), 0)
	card_s.shadow_size = 0
	player_card.add_theme_stylebox_override("panel", card_s)

	# Video screen box
	var frame_s := _flat(C_SCREEN_BG, Color(accent_color.r, accent_color.g, accent_color.b, 0.15), 16)
	if video_frame:
		video_frame.add_theme_stylebox_override("panel", frame_s)

	# Play Overlay circle button
	var overlay_s := _flat(accent_color, accent_light, 44)
	overlay_s.shadow_size = 8; overlay_s.shadow_color = Color(0.13, 0.08, 0.05, 0.18)
	play_overlay.add_theme_stylebox_override("panel", overlay_s)
	play_overlay.get_node("PlayText").add_theme_color_override("font_color", Color(1, 1, 1, 1) if inst != "dan_tranh" else Color(0.13, 0.08, 0.05, 1.0))

	# Subtitles box - light warm background
	var sub_s := _flat(Color(0.95, 0.93, 0.89, 0.85), Color(accent_color.r, accent_color.g, accent_color.b, 0.20), 16)
	if sub_panel:
		sub_panel.add_theme_stylebox_override("panel", sub_s)
	sub_label.add_theme_color_override("font_color", Color(0.13, 0.08, 0.05, 1.0))

	# Buttons
	_style_outlined_btn(back_btn, 18, theme_color, accent_color)
	_style_outlined_btn(skip_btn, 22, theme_color, accent_color)
	_style_outlined_btn(play_btn, 16, theme_color, accent_color)
	
	if rewind_btn:
		_style_outlined_btn(rewind_btn, 16, theme_color, accent_color)
	if forward_btn:
		_style_outlined_btn(forward_btn, 16, theme_color, accent_color)
	if speed_btn:
		_style_outlined_btn(speed_btn, 16, theme_color, accent_color)
	if zoom_btn:
		_style_outlined_btn(zoom_btn, 16, theme_color, accent_color)

	# Complete Btn (Gold filled primary CTA)
	var c_n := _flat(theme_color, Color(1,1,1,0.2), 22)
	c_n.shadow_size = 12; c_n.shadow_color = Color(theme_color.r, theme_color.g, theme_color.b, 0.25)
	var c_h := _flat(theme_color.lightened(0.12), Color(1,1,1,0.3), 22)
	c_h.shadow_size = 18; c_h.shadow_color = Color(theme_color.r, theme_color.g, theme_color.b, 0.35)
	complete_btn.add_theme_stylebox_override("normal", c_n)
	complete_btn.add_theme_stylebox_override("hover", c_h)
	complete_btn.add_theme_stylebox_override("pressed", _flat(theme_color.darkened(0.18), Color(0,0,0,0.2), 22))
	complete_btn.add_theme_stylebox_override("focus", _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	complete_btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	complete_btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	complete_btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 1))
	complete_btn.add_theme_font_size_override("font_size", 20)

	# Progress bar
	var pf := StyleBoxFlat.new(); pf.bg_color = accent_color
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

	if rewind_btn:
		rewind_btn.pressed.connect(_on_rewind_pressed)
		_make_button_bouncy(rewind_btn)
	if forward_btn:
		forward_btn.pressed.connect(_on_forward_pressed)
		_make_button_bouncy(forward_btn)
	if speed_btn:
		speed_btn.pressed.connect(_on_speed_pressed)
		_make_button_bouncy(speed_btn)
	if zoom_btn:
		zoom_btn.pressed.connect(_on_zoom_pressed)
		_make_button_bouncy(zoom_btn)

	play_overlay.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			_toggle_play()
	)

	_make_button_bouncy(back_btn)
	_make_button_bouncy(skip_btn)
	_make_button_bouncy(play_btn)
	_make_button_bouncy(complete_btn)

func _toggle_play() -> void:
	if _time >= _duration:
		# replay from start
		_time = 0.0
		video_stream_player.stream_position = 0.0
		linh_rect.texture = load("res://assets/textures/virtual_artist_mai.png") # reset to default vector avatar
	_playing = not _playing
	_update_play_state()

func _on_rewind_pressed() -> void:
	var new_pos = _time - 2.0
	if new_pos < 0.0:
		new_pos = 0.0
	_time = new_pos
	video_stream_player.stream_position = new_pos
	_update_media_progress()

func _on_forward_pressed() -> void:
	var new_pos = _time + 2.0
	if new_pos >= _duration:
		new_pos = _duration
		_time = _duration
		_playing = false
		_update_play_state()
		_va_success_prompt()
		video_stream_player.stop()
		linh_rect.visible = true
		video_stream_player.visible = false
	else:
		_time = new_pos
		video_stream_player.stream_position = new_pos
	_update_media_progress()

func _on_speed_pressed() -> void:
	speed_idx = (speed_idx + 1) % SPEEDS.size()
	var speed = SPEEDS[speed_idx]
	video_stream_player.speed_scale = speed
	speed_btn.text = "%.1fx" % speed

func _on_zoom_pressed() -> void:
	_video_zoomed = not _video_zoomed
	
	if top_row:
		top_row.visible = not _video_zoomed
	if sub_panel:
		sub_panel.visible = not _video_zoomed
	if footer_row:
		footer_row.visible = not _video_zoomed
		
	if _video_zoomed:
		zoom_btn.text = "⇲"
		if card_m:
			card_m.add_theme_constant_override("margin_left", 0)
			card_m.add_theme_constant_override("margin_right", 0)
			card_m.add_theme_constant_override("margin_top", 0)
			card_m.add_theme_constant_override("margin_bottom", 0)
	else:
		zoom_btn.text = "⛶"
		if card_m:
			card_m.add_theme_constant_override("margin_left", 32)
			card_m.add_theme_constant_override("margin_right", 32)
			card_m.add_theme_constant_override("margin_top", 24)
			card_m.add_theme_constant_override("margin_bottom", 24)

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
	var inst := InstrumentSelect.selected_instrument
	var btn_color_name := "màu vàng"
	var text_col := C_RED_SON
	if inst == "sao_truc":
		btn_color_name = "màu xanh"
		text_col = C_JADE
	elif inst == "dan_bau":
		btn_color_name = "màu tím"
		text_col = Color(0.38, 0.25, 0.60, 1.0)
		
	sub_label.text = "Tuyệt vời! Bài học hoàn thành. Hãy bấm nút 'Hoàn Thành Video' %s để mở khóa thực hành!" % btn_color_name
	sub_label.add_theme_color_override("font_color", text_col)
	
	# Load the happy virtual artist texture when completed
	linh_rect.texture = load("res://assets/textures/mai_happy.jpg")
	
	# Flash the complete button
	var ct := create_tween()
	ct.tween_property(complete_btn, "scale", Vector2(1.08, 1.08), 0.15).set_trans(Tween.TRANS_BACK)
	ct.tween_property(complete_btn, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)

func _on_complete() -> void:
	video_stream_player.stop()
	var inst := str(SecureDataManager.data.get("selected_instrument", InstrumentSelect.selected_instrument))
	var lesson_id := SecureDataManager.active_lesson_id
	SecureDataManager.complete_lesson(inst, lesson_id, 3) # Mark Intro completed with 3 stars securely!
	SecureDataManager.video_completed = true
	custom_video_path = ""
	custom_subtitles = []
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.22)
	t.tween_callback(func() -> void:
		if lesson_id.begins_with("dan_bau_coban_") and lesson_id.ends_with("_video"):
			SecureDataManager.active_lesson_id = lesson_id.replace("_video", "_practice")
			get_tree().change_scene_to_file("res://scenes/PracticeDanBau.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)

func _go_back() -> void:
	video_stream_player.stop()
	custom_video_path = ""
	custom_subtitles = []
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.22)
	t.tween_callback(func() -> void:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)

func _style_outlined_btn(btn: Button, radius: int, theme_color: Color = C_RED_SON, accent_color: Color = C_GOLD) -> void:
	var bn := _flat(Color(0,0,0,0), Color(0.13, 0.08, 0.05, 0.20), radius)
	var bh := _flat(Color(0,0,0,0.04), Color(theme_color.r, theme_color.g, theme_color.b, 0.60), radius)
	btn.add_theme_stylebox_override("normal", bn)
	btn.add_theme_stylebox_override("hover", bh)
	btn.add_theme_stylebox_override("pressed", _flat(Color(0,0,0,0.08), accent_color, radius))
	btn.add_theme_stylebox_override("focus", _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	btn.add_theme_color_override("font_color", Color(0.13, 0.08, 0.05, 1.0))
	btn.add_theme_color_override("font_hover_color", theme_color)

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
