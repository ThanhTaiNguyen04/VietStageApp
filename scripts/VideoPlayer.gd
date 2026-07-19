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
@onready var play_overlay : PanelContainer = $Center/PlayerCard/CardM/PlayerVBox/VideoFrame/FrameM/ScreenAnchor/MediaAspect/MediaSurface/PlayOverlay
@onready var linh_rect     : TextureRect    = $Center/PlayerCard/CardM/PlayerVBox/VideoFrame/FrameM/ScreenAnchor/MediaAspect/MediaSurface/LinhTexture
@onready var video_stream_player : VideoStreamPlayer = $Center/PlayerCard/CardM/PlayerVBox/VideoFrame/FrameM/ScreenAnchor/MediaAspect/MediaSurface/VideoStreamPlayer

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
var intro_exit_btn : Button
var intro_overlay : Control
var intro_pbar : ProgressBar
var intro_count_lbl : Label

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

const SUBTITLES_TRONG_CHAU := [
	{"start": 0.0,  "end": 2.5,  "text": "Xin chào bạn! Tôi là cô Mai, người hướng dẫn nhịp điệu Trống Chầu truyền thống tại VietStage."},
	{"start": 2.5,  "end": 5.5,  "text": "Hôm nay, chúng ta sẽ học cách cầm dùi chầu, tư thế ngồi thẳng và cách gõ âm Tịch cơ bản trên mặt trống."},
	{"start": 5.5,  "end": 8.0,  "text": "Hãy thả lỏng khớp cổ tay, gõ dùi dứt khoát vào tâm trống để tạo tiếng trầm ấm vang vọng tự nhiên."},
	{"start": 8.0,  "end": 10.0, "text": "Tuyệt vời! Hãy nhấn 'Hoàn Thành Video' để nhận 80 điểm và bắt đầu luyện tập thực tế ngay!"}
]

static var custom_video_sequence: Array = []
static var current_sequence_index: int = 0
static var custom_video_path := ""
static var custom_subtitles := []

var sequence_modal: Control

var active_subtitles := []

func _ready() -> void:
	var inst := InstrumentSelect.selected_instrument
	
	custom_video_sequence = SecureDataManager.data.get("custom_video_sequence", [])
	current_sequence_index = SecureDataManager.data.get("current_sequence_index", 0)
	
	if custom_video_sequence.size() > 0:
		var path: String = custom_video_sequence[current_sequence_index]
		video_stream_player.stream = load(path)
		_duration = _get_video_duration(path)
	elif custom_video_path != "":
		video_stream_player.stream = load(custom_video_path)
		_duration = _get_video_duration(custom_video_path)
		active_subtitles = custom_subtitles
	else:
		if inst == "sao_truc":
			video_stream_player.stream = load("res://Video/Giảng_viên_dạy_sáo_trúc_202606300842.ogv")
			active_subtitles = SUBTITLES_SAO_TRUC
		elif inst == "dan_bau":
			video_stream_player.stream = load("res://Video/coMai_danBau.ogv")
			active_subtitles = SUBTITLES_DAN_BAU
		elif inst == "trong_chau":
			video_stream_player.stream = load("res://Video/coMai_danBau.ogv")
			active_subtitles = SUBTITLES_TRONG_CHAU
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
	
	if inst == "dan_bau" or inst == "dan_tranh":
		_setup_simply_piano_layout()
		
	if custom_video_sequence.size() > 0:
		top_row.visible = false
		control_row.visible = false
		footer_row.visible = false
		sub_panel.visible = false
		video_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		# Loại bỏ viền trắng để video full màn hình
		if card_m:
			card_m.add_theme_constant_override("margin_left", 0)
			card_m.add_theme_constant_override("margin_right", 0)
			card_m.add_theme_constant_override("margin_top", 0)
			card_m.add_theme_constant_override("margin_bottom", 0)
		player_card.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		video_frame.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		var frame_m = video_frame.get_node_or_null("FrameM")
		if frame_m:
			frame_m.add_theme_constant_override("margin_left", 0)
			frame_m.add_theme_constant_override("margin_right", 0)
			frame_m.add_theme_constant_override("margin_top", 0)
			frame_m.add_theme_constant_override("margin_bottom", 0)
		
		# Chuyển nền tổng thể thành đen
		var bg_node := get_node_or_null("BG") as ColorRect
		if bg_node: bg_node.color = Color.BLACK
		var screen_bg = screen_anch.get_node_or_null("ScreenBG") as ColorRect
		if screen_bg: screen_bg.color = Color.BLACK
			
		var media_aspect = screen_anch.get_node_or_null("MediaAspect")
		if media_aspect:
			media_aspect.ratio = 16.0 / 9.0
			# Thay đổi thành COVER để lấp đầy toàn bộ màn hình, cắt bỏ viền đen
			media_aspect.stretch_mode = AspectRatioContainer.STRETCH_COVER
			
		video_stream_player.expand = true
		
		# Tự động phát
		_time = 0.0
		video_stream_player.stream_position = 0.0
		_playing = true
		_update_play_state()
		video_stream_player.play()
		
		_setup_intro_layout()

	_create_sequence_modal()
	
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
		elif not video_stream_player.paused:
			# Video finished naturally before reaching _duration
			_time = _duration
		
		if _time >= _duration:
			_time = _duration
			_playing = false
			_update_play_state()
			video_stream_player.stop()
			
			if custom_video_sequence.size() > 0:
				_show_sequence_modal()
			else:
				_va_success_prompt()
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
	var cur_min := int(int(_time) / 60.0)
	var cur_sec := int(_time) % 60
	var dur_min := int(int(_duration) / 60.0)
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
		video_stream_player.stop()
		
		if custom_video_sequence.size() > 0:
			_show_sequence_modal()
		else:
			_va_success_prompt()
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
		if play_btn.has_node("VBoxContainer/LabelTxt"):
			var lbl = play_btn.get_node("VBoxContainer/LabelTxt") as Label
			var irect = play_btn.get_node("VBoxContainer/IconRect") as TextureRect
			lbl.text = "Pause"
			var tex = _get_white_lucide_icon("pause")
			if tex: irect.texture = tex
		elif play_btn.has_meta("is_intro_btn"):
			var irect = play_btn.get_child(0) as TextureRect
			var tex = _get_white_lucide_icon("pause")
			if tex: irect.texture = tex
			if intro_exit_btn: intro_exit_btn.visible = false
		else:
			play_btn.text = "⏸"
		play_overlay.visible = false
		linh_rect.visible = false
		video_stream_player.visible = true
		if video_stream_player.paused:
			video_stream_player.paused = false
		else:
			video_stream_player.play()
	else:
		if play_btn.has_node("VBoxContainer/LabelTxt"):
			var lbl = play_btn.get_node("VBoxContainer/LabelTxt") as Label
			var irect = play_btn.get_node("VBoxContainer/IconRect") as TextureRect
			lbl.text = "Play"
			var tex = _get_white_lucide_icon("play")
			if tex: irect.texture = tex
		elif play_btn.has_meta("is_intro_btn"):
			var irect = play_btn.get_child(0) as TextureRect
			var tex = _get_white_lucide_icon("play")
			if tex: irect.texture = tex
			if intro_exit_btn: intro_exit_btn.visible = true
		else:
			play_btn.text = "▶"
		play_overlay.visible = true
		if video_stream_player.is_playing() and not video_stream_player.paused:
			video_stream_player.paused = true
	
	_create_sequence_modal()

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
	custom_video_sequence = []
	current_sequence_index = 0
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.22)
	t.tween_callback(func() -> void:
		if lesson_id.begins_with("dan_tranh_level_") and lesson_id.ends_with("_video"):
			SecureDataManager.active_lesson_id = lesson_id.replace("_video", "_practice")
			get_tree().change_scene_to_file("res://scenes/PracticeRoom.tscn")
		elif lesson_id.begins_with("dan_bau_coban_") and lesson_id.ends_with("_video"):
			SecureDataManager.active_lesson_id = lesson_id.replace("_video", "_practice")
			get_tree().change_scene_to_file("res://scenes/PracticeDanBau.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)

func _go_back() -> void:
	video_stream_player.stop()
	custom_video_path = ""
	custom_subtitles = []
	custom_video_sequence = []
	current_sequence_index = 0
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.22)
	t.tween_callback(func() -> void:
		var target := "res://scenes/LessonDanTranh.tscn" if SecureDataManager.active_lesson_id.begins_with("dan_tranh_level_") else "res://scenes/MainMenu.tscn"
		get_tree().change_scene_to_file(target)
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
	)

func _setup_simply_piano_layout() -> void:
	# Hide default rows
	if top_row: top_row.visible = false
	var control_row := player_vbox.get_node_or_null("ControlRow")
	if control_row: control_row.visible = false
	if footer_row: footer_row.visible = false
	if sub_panel: sub_panel.visible = false
	
	# Loại bỏ viền trắng để video tràn màn hình
	if card_m:
		card_m.add_theme_constant_override("margin_left", 0)
		card_m.add_theme_constant_override("margin_right", 0)
		card_m.add_theme_constant_override("margin_top", 0)
		card_m.add_theme_constant_override("margin_bottom", 0)
	player_card.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	if video_frame:
		video_frame.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		
	# Chuyển nền tổng thành đen để không lộ viền trắng khi video có letterbox
	var bg_node := get_node_or_null("BG") as ColorRect
	if bg_node:
		bg_node.color = Color.BLACK
	
	# Create overlay container on video_frame
	var overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	video_frame.add_child(overlay)
	
	# 1. Top Left Buttons (Play, Restart, Exit)
	var tl_hbox = HBoxContainer.new()
	tl_hbox.add_theme_constant_override("separation", 15)
	tl_hbox.set_anchors_preset(Control.PRESET_TOP_LEFT)
	tl_hbox.position = Vector2(30, 30)
	overlay.add_child(tl_hbox)
	
	var create_sp_btn = func(icon_name: String, lbl_txt: String, cb: Callable) -> Button:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(72, 72)
		var sb = _flat(Color(1, 1, 1, 0.25), Color(1, 1, 1, 0.4), 16)
		var sb_h = _flat(Color(1, 1, 1, 0.4), Color(1, 1, 1, 0.6), 16)
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb_h)
		btn.add_theme_stylebox_override("pressed", sb_h)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		btn.pressed.connect(cb)
		
		# Dùng VBoxContainer để căn giữa cả icon và text hoàn hảo
		var vbox = VBoxContainer.new()
		vbox.name = "VBoxContainer"
		vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 2)
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(vbox)
		
		var icon_rect = TextureRect.new()
		icon_rect.name = "IconRect"
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tex = _get_white_lucide_icon(icon_name)
		if tex: icon_rect.texture = tex
		vbox.add_child(icon_rect)
		
		var lbl = Label.new()
		lbl.name = "LabelTxt"
		lbl.text = lbl_txt
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(lbl)
		
		_make_button_bouncy(btn)
		tl_hbox.add_child(btn)
		return btn
		
	var sp_play = create_sp_btn.call("play", "Play", _toggle_play)
	# Cập nhật Play text reference cho update_play_state
	play_btn = sp_play 
	var sp_restart = create_sp_btn.call("rotate-ccw", "Restart", func():
		_time = 0.0
		video_stream_player.stream_position = 0.0
	)
	var sp_exit = create_sp_btn.call("log-out", "Exit", _go_back)
	
	# 2. Skip Button at Bottom Right
	var sp_skip = Button.new()
	sp_skip.text = "SKIP"
	sp_skip.add_theme_font_size_override("font_size", 20)
	var skip_sb = StyleBoxEmpty.new()
	sp_skip.add_theme_stylebox_override("normal", skip_sb)
	sp_skip.add_theme_stylebox_override("hover", skip_sb)
	sp_skip.add_theme_stylebox_override("pressed", skip_sb)
	sp_skip.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	sp_skip.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	sp_skip.position = Vector2(-120, -60)
	sp_skip.pressed.connect(_on_complete)
	_make_button_bouncy(sp_skip)
	overlay.add_child(sp_skip)
	
	# 3. Subtitles at Bottom Center
	var sub_cont = PanelContainer.new()
	var sub_sb = _flat(Color(0,0,0,0.5), Color(0,0,0,0), 8)
	sub_cont.add_theme_stylebox_override("panel", sub_sb)
	sub_cont.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	sub_cont.position = Vector2(-300, -80)
	sub_cont.custom_minimum_size = Vector2(600, 40)
	
	var new_sub_lbl = Label.new()
	new_sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	new_sub_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	new_sub_lbl.add_theme_font_size_override("font_size", 18)
	new_sub_lbl.add_theme_color_override("font_color", Color.WHITE)
	new_sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub_cont.add_child(new_sub_lbl)
	overlay.add_child(sub_cont)
	
	# Override sub_label reference so subtitle updates work
	sub_label = new_sub_lbl

func _get_video_duration(path: String) -> float:
	if "intro" in path or "intro" in path.to_lower():
		return 16.0
	return 10.0

# ─── SEQUENCE MODAL ─────────────────────────────────────────────────────────

func _create_sequence_modal() -> void:
	sequence_modal = Control.new()
	sequence_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	sequence_modal.visible = false
	
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	# Phóng to x3: Rộng 720, Cao 260
	panel.position = Vector2(-360, -260)
	panel.custom_minimum_size = Vector2(720, 260)
	
	var panel_sb = StyleBoxFlat.new()
	var bg_col = Color("1a1208")
	bg_col.a = 0.95
	panel_sb.bg_color = bg_col # Màu Deep Mahogany của app
	panel_sb.corner_radius_top_left = 130
	panel_sb.corner_radius_top_right = 130
	panel_sb.corner_radius_bottom_left = 0
	panel_sb.corner_radius_bottom_right = 0
	panel.add_theme_stylebox_override("panel", panel_sb)
	sequence_modal.add_child(panel)
	
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 80)
	panel.add_child(hbox)
	
	# Nút Replay (Trái) - Phóng to 160x160
	var replay_btn := Button.new()
	replay_btn.custom_minimum_size = Vector2(160, 160)
	replay_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var replay_sb := StyleBoxFlat.new()
	replay_sb.bg_color = Color.TRANSPARENT
	replay_sb.border_width_left = 6; replay_sb.border_width_top = 6
	replay_sb.border_width_right = 6; replay_sb.border_width_bottom = 6
	replay_sb.border_color = Color("f0deb4") # Warm Ivory
	replay_sb.corner_radius_top_left = 80; replay_sb.corner_radius_top_right = 80
	replay_sb.corner_radius_bottom_left = 80; replay_sb.corner_radius_bottom_right = 80
	replay_btn.add_theme_stylebox_override("normal", replay_sb)
	replay_btn.add_theme_stylebox_override("hover", replay_sb)
	replay_btn.add_theme_stylebox_override("pressed", replay_sb)
	replay_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	var replay_icon := TextureRect.new()
	# Tăng scale nội tại của SVG lên cực đại (x5) để siêu nét
	replay_icon.texture = _get_white_lucide_icon("rotate-ccw", 5.0)
	replay_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	replay_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	replay_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Thu hẹp vùng hiển thị icon lại một chút so với viền nút để không bị lẹm
	replay_icon.offset_left = 35
	replay_icon.offset_top = 35
	replay_icon.offset_right = -35
	replay_icon.offset_bottom = -35
	replay_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	replay_btn.add_child(replay_icon)
	hbox.add_child(replay_btn)
	
	# Nút Next (Phải) - Phóng to 160x160
	var next_btn := Button.new()
	next_btn.custom_minimum_size = Vector2(160, 160)
	next_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var next_sb := StyleBoxFlat.new()
	next_sb.bg_color = Color("c0541a") # Màu Terracotta đỏ cam (Primary)
	next_sb.corner_radius_top_left = 80; next_sb.corner_radius_top_right = 80
	next_sb.corner_radius_bottom_left = 80; next_sb.corner_radius_bottom_right = 80
	next_btn.add_theme_stylebox_override("normal", next_sb)
	
	var next_sb_hover := next_sb.duplicate() as StyleBoxFlat
	next_sb_hover.bg_color = Color("d16021") # Sáng hơn xíu
	next_btn.add_theme_stylebox_override("hover", next_sb_hover)
	next_btn.add_theme_stylebox_override("pressed", next_sb)
	next_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	var next_icon := TextureRect.new()
	next_icon.texture = _get_white_lucide_icon("play", 5.0)
	next_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	next_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	next_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Padding 35px -> kích thước icon thực tế là 90x90 trên nền nút 160x160
	next_icon.offset_left = 35
	next_icon.offset_top = 35
	next_icon.offset_right = -35
	next_icon.offset_bottom = -35
	next_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	next_btn.add_child(next_icon)
	hbox.add_child(next_btn)
	
	_make_button_bouncy(replay_btn)
	_make_button_bouncy(next_btn)
	
	replay_btn.pressed.connect(_on_sequence_replay)
	next_btn.pressed.connect(_on_sequence_next)
	
	# Đưa panel vào VideoFrame
	video_frame.add_child(sequence_modal)

func _show_sequence_modal() -> void:
	sequence_modal.visible = true
	if intro_overlay: intro_overlay.visible = false
	if play_overlay: play_overlay.visible = false
	sequence_modal.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(sequence_modal, "modulate:a", 1.0, 0.3)

func _on_sequence_replay() -> void:
	sequence_modal.visible = false
	if intro_overlay: intro_overlay.visible = true
	_time = 0.0
	video_stream_player.stream_position = 0.0
	_playing = true
	_update_play_state()
	video_stream_player.play()

func _on_sequence_next() -> void:
	current_sequence_index += 1
	sequence_modal.visible = false
	if intro_overlay: intro_overlay.visible = true
	
	if current_sequence_index < custom_video_sequence.size():
		var path: String = custom_video_sequence[current_sequence_index]
		video_stream_player.stream = load(path)
		_duration = _get_video_duration(path)
		_time = 0.0
		video_stream_player.stream_position = 0.0
		_playing = true
		_update_play_state()
		video_stream_player.play()
		
		if intro_pbar:
			intro_pbar.value = current_sequence_index + 1
		if intro_count_lbl:
			intro_count_lbl.text = str(current_sequence_index + 1) + "/" + str(custom_video_sequence.size())
	else:
		_on_complete()

func _get_white_lucide_icon(icon_name: String, svg_scale: float = 1.25) -> Texture2D:
	var path = "res://assets/textures/lucide/" + icon_name + ".svg"
	if not FileAccess.file_exists(path):
		return null
	var svg_str = FileAccess.get_file_as_string(path)
	if svg_str.is_empty():
		return null
	svg_str = svg_str.replace("currentColor", "#FFFFFF")
	svg_str = svg_str.replace("stroke-width=\"2\"", "stroke-width=\"1.5\"")
	var img = Image.new()
	var err = img.load_svg_from_string(svg_str, 1.25)
	if err == OK:
		return ImageTexture.create_from_image(img)
	return null

func _setup_intro_layout() -> void:
	intro_overlay = Control.new()
	intro_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	intro_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	video_frame.add_child(intro_overlay)

	var tl_hbox = HBoxContainer.new()
	tl_hbox.add_theme_constant_override("separation", 20)
	tl_hbox.set_anchors_preset(Control.PRESET_TOP_LEFT)
	tl_hbox.position = Vector2(40, 40)
	intro_overlay.add_child(tl_hbox)

	var create_circ_btn = func(icon_name: String, cb: Callable) -> Button:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(120, 120)
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0.5)
		sb.corner_radius_top_left = 60
		sb.corner_radius_top_right = 60
		sb.corner_radius_bottom_left = 60
		sb.corner_radius_bottom_right = 60
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		
		var icon_rect = TextureRect.new()
		var tex = _get_white_lucide_icon(icon_name, 5.0)
		if tex: icon_rect.texture = tex
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		# Margin 25px để icon to (70x70) bên trong viền nút (120x120)
		icon_rect.offset_left = 25
		icon_rect.offset_top = 25
		icon_rect.offset_right = -25
		icon_rect.offset_bottom = -25
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(icon_rect)
		btn.pressed.connect(cb)
		_make_button_bouncy(btn)
		return btn

	var intro_play = create_circ_btn.call("pause", _toggle_play)
	play_btn = intro_play
	play_btn.set_meta("is_intro_btn", true)
	tl_hbox.add_child(intro_play)
	
	intro_exit_btn = create_circ_btn.call("log-out", _go_back)
	intro_exit_btn.visible = false
	tl_hbox.add_child(intro_exit_btn)

	var sp_skip = Button.new()
	sp_skip.text = "SKIP"
	sp_skip.add_theme_font_size_override("font_size", 48)
	var skip_sb = StyleBoxEmpty.new()
	sp_skip.add_theme_stylebox_override("normal", skip_sb)
	sp_skip.add_theme_stylebox_override("hover", skip_sb)
	sp_skip.add_theme_stylebox_override("pressed", skip_sb)
	sp_skip.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	sp_skip.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	sp_skip.position = Vector2(-220, -100)
	sp_skip.pressed.connect(_on_sequence_next)
	_make_button_bouncy(sp_skip)
	intro_overlay.add_child(sp_skip)

	var tr_hbox = HBoxContainer.new()
	tr_hbox.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	tr_hbox.position = Vector2(-450, 50)
	tr_hbox.add_theme_constant_override("separation", 20)
	intro_overlay.add_child(tr_hbox)

	intro_pbar = ProgressBar.new()
	intro_pbar.custom_minimum_size = Vector2(300, 24)
	intro_pbar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	intro_pbar.show_percentage = false
	var bg_sb = StyleBoxFlat.new()
	bg_sb.bg_color = Color(0, 0, 0, 0.4)
	bg_sb.corner_radius_top_left = 12
	bg_sb.corner_radius_top_right = 12
	bg_sb.corner_radius_bottom_left = 12
	bg_sb.corner_radius_bottom_right = 12
	var fg_sb = StyleBoxFlat.new()
	fg_sb.bg_color = Color(0.6, 0.9, 0.2)
	fg_sb.corner_radius_top_left = 12
	fg_sb.corner_radius_top_right = 12
	fg_sb.corner_radius_bottom_left = 12
	fg_sb.corner_radius_bottom_right = 12
	intro_pbar.add_theme_stylebox_override("background", bg_sb)
	intro_pbar.add_theme_stylebox_override("fill", fg_sb)
	intro_pbar.max_value = custom_video_sequence.size()
	intro_pbar.value = current_sequence_index + 1
	tr_hbox.add_child(intro_pbar)

	intro_count_lbl = Label.new()
	intro_count_lbl.text = str(current_sequence_index + 1) + "/" + str(custom_video_sequence.size())
	intro_count_lbl.add_theme_font_size_override("font_size", 40)
	tr_hbox.add_child(intro_count_lbl)
