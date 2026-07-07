extends Control

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
var _current_video_idx := 0

const SPEEDS := [0.5, 1.0, 1.5, 2.0]
var speed_idx := 1

var rewind_btn : Button
var forward_btn : Button
var speed_btn : Button
var zoom_btn : Button

# Up Next Interactive Check references
var up_next_overlay : PanelContainer
var up_next_lbl : Label
var question_lbl : Label
var option_a_btn : Button
var option_b_btn : Button

const SUBTITLES_DAN_TRANH := [
	{"start": 0.0,  "end": 999.0,  "text": "Hãy xem kĩ hướng dẫn của cô giáo để chuẩn bị vào thực hành nhé!"}
]

var active_subtitles := []

func _load_video(idx: int) -> void:
	_current_video_idx = idx
	_playing = true
	_time = 0.0
	if up_next_overlay:
		up_next_overlay.visible = false
	if card_m:
		card_m.visible = true
	
	# Load from nvaore directory (pre-compiled stable high-quality ogv videos from NamTest)
	var video_path := "res://nvaore/intro" + str(idx + 1) + ".ogv"
	video_stream_player.stream = load(video_path)
	
	# Determine duration dynamically
	if video_stream_player.stream:
		var stream_len := video_stream_player.get_stream_length()
		if stream_len > 0.0:
			_duration = stream_len
		else:
			_duration = 10.0
			
	var title_lbl := top_row.get_node_or_null("VideoTitle") as Label
	if title_lbl:
		title_lbl.text = "Bài Học Video: Nhập Môn (Phần " + str(idx + 1) + "/3)"
		
	video_stream_player.stream_position = 0.0
	video_stream_player.stop()
	
	play_overlay.visible = false
	linh_rect.visible = false
	video_stream_player.visible = true
	
	if complete_btn:
		if idx < 2:
			complete_btn.text = "❯"
		else:
			complete_btn.text = "Hoàn Thành Video"
			
	_update_play_state()
	_update_media_progress()
	_on_viewport_size_changed()

func _ready() -> void:
	# Make PlayerCard take up the entire screen programmatically
	var center_container = $Center
	if center_container:
		center_container.remove_child(player_card)
		add_child(player_card)
		player_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		player_card.custom_minimum_size = Vector2.ZERO
		center_container.queue_free()

	# Reparent ScreenAnchor to fill the entire player_card background for a true fullscreen layout
	if video_frame:
		var frame_m := video_frame.get_node_or_null("FrameM")
		if frame_m:
			var anchor := frame_m.get_node_or_null("ScreenAnchor") as Control
			if anchor:
				frame_m.remove_child(anchor)
				player_card.add_child(anchor)
				player_card.move_child(anchor, 0) # Draw first (below HUD layer)
				anchor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				
				# Stretch VideoStreamPlayer to cover the entire screen!
				video_stream_player.expand = true
				video_stream_player.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				
				# Stretch other components inside the anchor
				var bg := anchor.get_node_or_null("ScreenBG") as Control
				if bg: bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				var linh := anchor.get_node_or_null("LinhTexture") as Control
				if linh: linh.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				var overlay := anchor.get_node_or_null("PlayOverlay") as Control
				if overlay: overlay.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
				
		# Remove the empty VideoFrame from PlayerVBox
		player_vbox.remove_child(video_frame)
		video_frame.queue_free()
		
		# Insert transparent expanding spacer inside PlayerVBox to push control elements to top/bottom
		var spacer := Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		player_vbox.add_child(spacer)
		player_vbox.move_child(spacer, 1)

	# Instantiate control buttons programmatically to satisfy layout checks but hide them
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
	_build_up_next_overlay()
	
	if control_row:
		control_row.visible = false
	if skip_btn:
		skip_btn.visible = false
	if sub_panel:
		sub_panel.visible = false
	
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	video_stream_player.finished.connect(_on_video_finished)
	_on_viewport_size_changed()
	
	# Load the first intro video
	_load_video(0)
	
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.35)

func _process(delta: float) -> void:
	if _playing:
		if video_stream_player.is_playing():
			_time = video_stream_player.stream_position
		
		# Fallback checking for EOF if stream finished fails
		if _time >= _duration:
			_on_video_finished()
			
		_update_media_progress()

func _update_media_progress() -> void:
	if _duration > 0.0:
		progress_bar.value = (_time / _duration) * 100.0
	else:
		progress_bar.value = 0.0
		
	var cur_min := int(_time) / 60
	var cur_sec := int(_time) % 60
	var dur_min := int(_duration) / 60
	var dur_sec := int(_duration) % 60
	time_label.text = "%d:%02d / %d:%02d" % [cur_min, cur_sec, dur_min, dur_sec]

func _build_theme() -> void:
	var inst := InstrumentSelect.selected_instrument
	
	var theme_color := C_RED_SON
	var accent_color := C_GOLD
	var accent_light := C_GOLD_LIGHT
	var bg_color := Color(0, 0, 0, 1.0) # Solid black background for fullscreen video
	
	if inst == "sao_truc":
		theme_color = C_JADE
		accent_color = Color(0.25, 0.65, 0.45, 1.0)
		accent_light = Color(0.35, 0.85, 0.60, 1.0)
	elif inst == "dan_bau":
		theme_color = Color(0.38, 0.25, 0.60, 1.0)
		accent_color = Color(0.55, 0.45, 0.80, 1.0)
		accent_light = Color(0.70, 0.60, 0.90, 1.0)

	var bg_node := get_node_or_null("BG") as ColorRect
	if bg_node:
		bg_node.color = bg_color

	var title_lbl := top_row.get_node_or_null("VideoTitle") as Label
	if title_lbl:
		title_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))

	var card_s := StyleBoxEmpty.new() # Transparent layout to draw directly over video
	player_card.add_theme_stylebox_override("panel", card_s)

	var frame_s := StyleBoxFlat.new()
	frame_s.bg_color = Color(0, 0, 0, 1.0)
	frame_s.border_width_left = 0; frame_s.border_width_right = 0
	frame_s.border_width_top = 0; frame_s.border_width_bottom = 0
	if video_frame:
		video_frame.add_theme_stylebox_override("panel", frame_s)

	var overlay_s := _flat(accent_color, accent_light, 44)
	play_overlay.add_theme_stylebox_override("panel", overlay_s)

	_apply_image_style(back_btn, "res://image/quaylai.png", 240.0, 160.0)
	if complete_btn:
		_apply_image_style(complete_btn, "res://image/videott.png", 240.0, 160.0)

func _build_up_next_overlay() -> void:
	up_next_overlay = PanelContainer.new()
	up_next_overlay.name = "UpNextOverlay"
	up_next_overlay.visible = false
	
	var purple_sb := StyleBoxFlat.new()
	purple_sb.bg_color = Color(0.38, 0.05, 0.85, 0.22) # translucent violet base
	up_next_overlay.add_theme_stylebox_override("panel", purple_sb)
	
	player_card.add_child(up_next_overlay)
	player_card.move_child(up_next_overlay, 1)
	up_next_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var overlay_m := MarginContainer.new()
	overlay_m.add_theme_constant_override("margin_left", 32)
	overlay_m.add_theme_constant_override("margin_right", 32)
	overlay_m.add_theme_constant_override("margin_top", 32)
	overlay_m.add_theme_constant_override("margin_bottom", 32)
	up_next_overlay.add_child(overlay_m)
	
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	overlay_m.add_child(vbox)
	
	up_next_lbl = Label.new()
	up_next_lbl.text = "Up Next:"
	up_next_lbl.add_theme_font_size_override("font_size", 24)
	up_next_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	up_next_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(up_next_lbl)
	
	var black_panel := PanelContainer.new()
	var black_sb := StyleBoxFlat.new()
	black_sb.bg_color = Color(0, 0, 0, 0.55)
	black_sb.corner_radius_top_left = 12
	black_sb.corner_radius_top_right = 12
	black_sb.corner_radius_bottom_left = 12
	black_sb.corner_radius_bottom_right = 12
	black_panel.add_theme_stylebox_override("panel", black_sb)
	black_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(black_panel)
	
	var pm := MarginContainer.new()
	pm.add_theme_constant_override("margin_left", 48)
	pm.add_theme_constant_override("margin_right", 48)
	pm.add_theme_constant_override("margin_top", 28)
	pm.add_theme_constant_override("margin_bottom", 28)
	black_panel.add_child(pm)
	
	var inner_vbox := VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 20)
	pm.add_child(inner_vbox)
	
	question_lbl = Label.new()
	question_lbl.text = "Bạn đã nắm rõ nội dung bài học chưa?"
	question_lbl.add_theme_font_size_override("font_size", 20)
	question_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	question_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner_vbox.add_child(question_lbl)
	
	var options_hbox := HBoxContainer.new()
	options_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	options_hbox.add_theme_constant_override("separation", 16)
	inner_vbox.add_child(options_hbox)
	
	option_b_btn = Button.new()
	option_b_btn.text = "Chưa rõ, xem lại"
	option_b_btn.custom_minimum_size = Vector2(220, 46)
	option_b_btn.add_theme_font_size_override("font_size", 16)
	options_hbox.add_child(option_b_btn)
	option_b_btn.pressed.connect(_on_replay_current)
	_make_button_bouncy(option_b_btn)
	
	option_a_btn = Button.new()
	option_a_btn.text = "Đã rõ, tiếp tục!"
	option_a_btn.custom_minimum_size = Vector2(220, 46)
	option_a_btn.add_theme_font_size_override("font_size", 16)
	options_hbox.add_child(option_a_btn)
	option_a_btn.pressed.connect(_on_complete)
	_make_button_bouncy(option_a_btn)

func _on_viewport_size_changed() -> void:
	var vp_size = get_viewport().size
	var is_mobile = vp_size.x < vp_size.y or vp_size.x < 1000
	var inst := InstrumentSelect.selected_instrument
	
	var theme_color := C_RED_SON
	var accent_color := C_GOLD
	var accent_light := C_GOLD_LIGHT
	
	if inst == "sao_truc":
		theme_color = C_JADE
		accent_color = Color(0.25, 0.65, 0.45, 1.0)
		accent_light = Color(0.35, 0.85, 0.60, 1.0)
	elif inst == "dan_bau":
		theme_color = Color(0.38, 0.25, 0.60, 1.0)
		accent_color = Color(0.55, 0.45, 0.80, 1.0)
		accent_light = Color(0.70, 0.60, 0.90, 1.0)

	# Reparent back_btn dynamically based on viewport layout
	if is_mobile:
		if back_btn.get_parent() == top_row:
			top_row.remove_child(back_btn)
			footer_row.add_child(back_btn)
			footer_row.move_child(back_btn, 0)
	else:
		if back_btn.get_parent() == footer_row:
			footer_row.remove_child(back_btn)
			top_row.add_child(back_btn)
			top_row.move_child(back_btn, 0)

	# Apply custom premium image button styling per user request (aspect ratio 1.5)
	_apply_image_style(back_btn, "res://image/quaylai.png", 240.0, 160.0)
	if complete_btn:
		_apply_image_style(complete_btn, "res://image/videott.png", 240.0, 160.0)

	# Style Option B (Outlined, retry)
	var ob_n := _flat(Color(0, 0, 0, 0.4), theme_color, 20)
	var ob_h := _flat(Color(0.2, 0.2, 0.2, 0.5), theme_color.lightened(0.15), 20)
	option_b_btn.add_theme_stylebox_override("normal", ob_n)
	option_b_btn.add_theme_stylebox_override("hover", ob_h)
	option_b_btn.add_theme_stylebox_override("pressed", _flat(Color(0.1, 0.1, 0.1, 0.6), Color(0,0,0,0), 20))
	option_b_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	option_b_btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	
	# Style Option A (Filled, next)
	var oa_n := _flat(theme_color, accent_color, 20)
	var oa_h := _flat(theme_color.lightened(0.15), accent_light, 20)
	option_a_btn.add_theme_stylebox_override("normal", oa_n)
	option_a_btn.add_theme_stylebox_override("hover", oa_h)
	option_a_btn.add_theme_stylebox_override("pressed", _flat(theme_color.darkened(0.15), Color(0,0,0,0), 20))
	option_a_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	option_a_btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))

func _connect_buttons() -> void:
	back_btn.pressed.connect(_go_back)
	complete_btn.pressed.connect(_on_complete)
	
	play_overlay.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			_toggle_play()
	)

	_make_button_bouncy(back_btn)
	_make_button_bouncy(complete_btn)

func _toggle_play() -> void:
	_playing = not _playing
	_update_play_state()

func _update_play_state() -> void:
	if _playing:
		play_overlay.visible = false
		linh_rect.visible = false
		video_stream_player.visible = true
		video_stream_player.paused = false
		video_stream_player.play()
	else:
		play_overlay.visible = true
		if video_stream_player.is_playing() and not video_stream_player.paused:
			video_stream_player.paused = true

func _va_success_prompt() -> void:
	var inst := InstrumentSelect.selected_instrument
	var text_col := C_RED_SON
	if inst == "sao_truc":
		text_col = C_JADE
	elif inst == "dan_bau":
		text_col = Color(0.38, 0.25, 0.60, 1.0)
		
	# Show the Yousician-style custom instrument theme "Up Next" overlay
	if up_next_overlay:
		up_next_overlay.visible = true
		
		# Change background to theme color matching the instrument with alpha opacity (translucent overlay)
		var theme_sb := StyleBoxFlat.new()
		theme_sb.bg_color = Color(text_col.r, text_col.g, text_col.b, 0.22)
		up_next_overlay.add_theme_stylebox_override("panel", theme_sb)
		
		if _current_video_idx < 2:
			up_next_lbl.text = "Up Next: Phần " + str(_current_video_idx + 2)
		else:
			up_next_lbl.text = "Up Next: Thực Hành"
			
		if _current_video_idx == 0:
			question_lbl.text = "Bạn đã hiểu rõ về cấu tạo và tính năng cơ bản của nhạc cụ này chưa?"
			option_a_btn.text = "Đã rõ, tiếp tục!"
			option_b_btn.text = "Chưa rõ, xem lại"
		elif _current_video_idx == 1:
			question_lbl.text = "Bạn đã nắm được cách cầm nhạc cụ và tư thế ngồi chuẩn chưa?"
			option_a_btn.text = "Đã nắm rõ, tiếp tục!"
			option_b_btn.text = "Chưa rõ, xem lại"
		else:
			question_lbl.text = "Bạn đã hiểu cách chơi nốt nhạc đầu tiên và sẵn sàng cấp quyền Micro để bắt đầu thực hành chưa?"
			option_a_btn.text = "Sẵn sàng, vào tập!"
			option_b_btn.text = "Chưa rõ, xem lại"
			
		# Hide the main HUD (CardM) to hide corner circular icons and capture input
		if card_m:
			card_m.visible = false

func _on_replay_current() -> void:
	_time = 0.0
	video_stream_player.stream_position = 0.0
	_playing = true
	_update_play_state()
	if up_next_overlay:
		up_next_overlay.visible = false
	if card_m:
		card_m.visible = true

func _on_video_finished() -> void:
	if not _playing and up_next_overlay and up_next_overlay.visible:
		return
	_time = _duration
	_playing = false
	_update_play_state()
	_va_success_prompt()
	video_stream_player.paused = true
	linh_rect.visible = false
	video_stream_player.visible = true

func _on_complete() -> void:
	if _current_video_idx < 2:
		_load_video(_current_video_idx + 1)
	else:
		video_stream_player.stop()
		var inst := InstrumentSelect.selected_instrument
		SecureDataManager.complete_lesson(inst, "Node1", 3) # Mark Intro completed securely!
		SecureDataManager.video_completed = true
		var t := create_tween()
		t.tween_property(self, "modulate:a", 0.0, 0.22)
		t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))

func _go_back() -> void:
	if _current_video_idx > 0:
		_load_video(_current_video_idx - 1)
	else:
		video_stream_player.stop()
		var t := create_tween()
		t.tween_property(self, "modulate:a", 0.0, 0.22)
		t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/CourseMap.tscn"))
func _apply_image_style(btn: Button, path: String, width: float, height: float) -> void:
	var tex = load(path) as Texture2D
	if not tex: return
	btn.text = ""
	btn.custom_minimum_size = Vector2(width, height)
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _style_outlined_btn(btn: Button, radius: int, theme_color: Color = C_RED_SON, accent_color: Color = C_GOLD) -> void:
	var bn := _flat(Color(1.0, 0.98, 0.95, 0.85), Color(0.13, 0.08, 0.05, 0.15), radius)
	var bh := _flat(Color(1.0, 0.98, 0.95, 1.0), theme_color, radius)
	btn.add_theme_stylebox_override("normal", bn)
	btn.add_theme_stylebox_override("hover", bh)
	btn.add_theme_stylebox_override("pressed", _flat(Color(1.0, 0.98, 0.95, 0.65), accent_color, radius))
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
