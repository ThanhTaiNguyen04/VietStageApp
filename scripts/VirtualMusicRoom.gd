extends Control

# ─── Color Palette (Traditional Vietnamese Jade Green & Gold Theme) ───────────
const C_BG_DARK     := Color(0.95, 0.93, 0.89, 1.0) # #F3EFE3 - warm cream-beige for sidebar
const C_BG_DARKER   := Color(0.98, 0.97, 0.94, 1.0) # #FAF8F5 - warm cream background
const C_RED_SON     := Color(0.09, 0.27, 0.18, 1.0) # Premium deep jade green (instead of vermilion lacquer red)
const C_RED_DK      := Color(0.05, 0.16, 0.11, 0.96) # Deep dark jade green (instead of deep red)
const C_GOLD        := Color(0.77, 0.58, 0.15, 1.0) # golden yellow
const C_GOLD_LIGHT  := Color(0.95, 0.82, 0.45, 1.0) # bright gold
const C_CREAM       := Color(1.00, 0.97, 0.88, 1.0)
const C_CREAM_DIM   := Color(0.80, 0.76, 0.66, 1.0)
const C_TEXT_MUTED  := Color(0.43, 0.38, 0.33, 1.0)
const C_JADE        := Color(0.12, 0.37, 0.23, 1.0) # bamboo jade green

const FORCE_PROCEDURAL_PLAYER : bool = true

# ─── @onready references ───────────────────────────────────────────────────────
@onready var bg_canvas     : Control        = $BGCanvas
@onready var room_content  : Control        = $RoomContent
@onready var floor_canvas  : Control        = $RoomContent/FloorCanvas
@onready var interact_prompt : PanelContainer = $RoomContent/InteractPrompt
@onready var prompt_lbl    : Label          = $RoomContent/InteractPrompt/Margin/Label
# SpeechBubble removed
@onready var char_linh     : Control        = $RoomContent/CharLinh
@onready var station_tooltip : PanelContainer = $RoomContent/StationTooltip
@onready var tooltip_lbl   : Label          = $RoomContent/StationTooltip/Margin/Label

# Stations
@onready var s_tranh       : Button         = $RoomContent/StationTranh
@onready var s_sao         : Button         = $RoomContent/StationSao
@onready var s_bau         : Button         = $RoomContent/StationBau
@onready var s_trong       : Button         = $RoomContent/StationTrong

# Navigation
@onready var btn_back        : Button         = $HUD/BtnBack

# Focus Mode Popup
@onready var popup             : Control        = $HUD/FocusModePopup
@onready var popup_draw        : Control        = $HUD/FocusModePopup/ScrollPanel/ScrollDraw
@onready var popup_title       : Label          = $HUD/FocusModePopup/ScrollPanel/ScrollContent/PopupTitle
@onready var btn_tab_theory    : Button         = $HUD/FocusModePopup/ScrollPanel/ScrollContent/TabHBox/BtnTabTheory
@onready var btn_tab_fingering : Button         = $HUD/FocusModePopup/ScrollPanel/ScrollContent/TabHBox/BtnTabFingering
@onready var theory_panel      : VBoxContainer  = $HUD/FocusModePopup/ScrollPanel/ScrollContent/ContentArea/TheoryPanel
@onready var fingering_panel   : VBoxContainer  = $HUD/FocusModePopup/ScrollPanel/ScrollContent/ContentArea/FingeringPanel
@onready var diagram_theory    : Control        = $HUD/FocusModePopup/ScrollPanel/ScrollContent/ContentArea/TheoryPanel/DiagramTheory
@onready var diagram_fingering : Control        = $HUD/FocusModePopup/ScrollPanel/ScrollContent/ContentArea/FingeringPanel/DiagramFingering
@onready var text_theory       : Label          = $HUD/FocusModePopup/ScrollPanel/ScrollContent/ContentArea/TheoryPanel/TextTheory
@onready var text_fingering    : Label          = $HUD/FocusModePopup/ScrollPanel/ScrollContent/ContentArea/FingeringPanel/TextFingering
@onready var btn_popup_play    : Button         = $HUD/FocusModePopup/ScrollPanel/ScrollContent/ButtonHBox/BtnPopupPlay
@onready var btn_popup_close   : Button         = $HUD/FocusModePopup/ScrollPanel/ScrollContent/ButtonHBox/BtnPopupClose

# State variables
static var _has_played_intro : bool = false
var _time : float = 0.0
var _hovered_station : String = ""
var _linh_base_y : float = 220.0
var _speech_timer : float = 0.0
var _welcome_bow_timer : float = 1.6
var _dragged_decor : Control = null
var _drag_offset : Vector2 = Vector2.ZERO
var _pressed_decor : Control = null
var _press_timer_tween : Tween = null
var _press_start_pos : Vector2 = Vector2.ZERO

var _current_popup_instrument : String = ""
var _audio_manager : AIAudioManager = null

var _linh_is_moving : bool = false
var _linh_tween : Tween = null
var _is_in_intro : bool = false
var _particles : Array[Dictionary] = []
var _tex_tranh : Texture2D
var _tex_sao : Texture2D
var _tex_bau : Texture2D
var _tex_trong : Texture2D
var _tex_linh : Texture2D
var _tex_linh_talk : Texture2D
var _tex_linh_walk_down : Texture2D
var _tex_linh_walk_up : Texture2D
var _tex_linh_walk_left : Texture2D
var _tex_linh_walk_right : Texture2D
var _tex_linh_walk_down_left : Texture2D
var _tex_linh_walk_down_right : Texture2D
var _tex_linh_walk_up_left : Texture2D
var _tex_linh_walk_up_right : Texture2D
var _tex_player : Texture2D
var _tex_wall : Texture2D
var _tex_decor_chausen : Texture2D
var _tex_decor_bantra : Texture2D
var _tex_decor_tranh : Texture2D
var _tex_decor_quat : Texture2D
var _tex_decor_denlong : Texture2D
var _tex_decor_denda : Texture2D
var _tex_decor_chuonggio : Texture2D
var _tex_decor_binhsen : Texture2D
var _linh_walk_direction : String = "down"
var _idle_breath_time : float = 0.0
var _blink_timer : float = 2.0
var _is_blinking : bool = false
var _blink_duration : float = 0.15
var _typewriter_text : String = ""
var _typewriter_progress : float = 0.0
var _typewriter_timer : float = 0.0
var _card_particles : Array[Dictionary] = []
var _card_particle_timer : float = 0.0
var _prompt_is_showing : bool = false
var _prompt_tween : Tween = null
var _player_expression : String = "normal"
var _left_bound : float = 0.0
var _right_bound : float = 1200.0
var _player_dir : Vector2 = Vector2.DOWN
var _idle_time : float = 0.0

# Player state variables
var _player_pos : Vector2 = Vector2(600, 560)
var _target_position : Vector2 = Vector2(600, 560)
var _is_moving_to_target : bool = false
var _player_is_moving : bool = false
var _player_walk_time : float = 0.0
var _player_facing_right : bool = true
var _interact_target_station : String = ""
var _interact_target_linh : bool = false
var _interact_range : float = 120.0
var _player_speed : float = 280.0
var _walk_particles : Array[Dictionary] = []
var _walk_particle_timer : float = 0.0

var char_player : Control
var dialogue_box : PanelContainer
var dialogue_lbl : Label
var btn_dialogue_close : Button

var shop_popup : Control = null
var _api_client = null
var _cosmetics_all: Array = []
var _cosmetics_owned: Array = []
var _cosmetics_locked: Array = []
var _instruments_data: Dictionary = {
	"tranh": {
		"name": "Đàn Tranh",
		"desc": "Đàn Tranh sử dụng thang âm chuẩn với các nốt nhạc: Đô - Rê - Mi - Fa - Sol - La - Si (tương đương với các tần số C3 - D3 - E3 - F3 - G3 - A3 - B3). Nhấn vào dây đàn bên phải nhạn để gảy âm.",
		"fingering": "Kỹ thuật tay phải: Sử dụng ngón cái (1), ngón trỏ (2) và ngón giữa (3) đeo móng gảy để gảy dây đàn hướng vào lòng.\nKỹ thuật tay trái: Nhấn và rung dây ở phía bên trái nhạn đàn để tạo âm rung cảm xúc."
	},
	"sao": {
		"name": "Sáo Trúc",
		"desc": "Sáo Trúc sử dụng thang âm tự nhiên. Bằng cách lấy hơi bụng tròn trịa và hé/bịt các lỗ bấm, người thổi có thể tạo ra các nốt Đô - Rê - Mi - Fa - Sol - La chuẩn âm điệu dân tộc.",
		"fingering": "Kỹ thuật ngón: Đặt môi đều vào lỗ thổi. Bịt kín lỗ ngón bằng đầu ngón tay mềm mại (không dùng đốt ngón tay). Thổi hơi đều để âm thanh không bị rè."
	},
	"bau": {
		"name": "Đàn Bầu",
		"desc": "Đàn Bầu (Độc huyền cầm) chỉ sử dụng một dây tơ duy nhất căng trên thân tre gỗ. Các nốt nhạc được tạo ra bằng cách gảy vào các điểm hài âm và uốn vòi đàn để đổi cao độ.",
		"fingering": "Tay phải: Dùng que gảy nhỏ gảy vào dây đồng thời chạm cạnh bàn tay vào điểm hài âm để tạo tiếng bầu trầm bổng.\nTay trái: Cầm vòi đàn uốn về phía trước (giảm cao độ) hoặc kéo về sau (tăng cao độ)."
	},
	"trong": {
		"name": "Trống Chầu",
		"desc": "Trống Chầu đóng vai trò giữ nhịp điệu rộn ràng cho các điệu hát chèo, hát đào cổ truyền. Mặt trống bằng da bò căng chặt tạo tiếng vang đanh thép rực lửa.",
		"fingering": "Gõ vào tâm mặt trống tạo tiếng 'Tịch' trầm sâu. Gõ vào vành gỗ trống bằng dùi chầu gỗ tạo tiếng 'Cắc' vang dội réo rắt báo hiệu đổi làn điệu."
	}
}

var _font_title : Font
var _font_body : Font
var _font_body_bold : Font

var _is_mobile_layout : bool = false
var _station_transitioning : bool = false
var _station_base_positions := {
	"tranh": Vector2(-20.0, 620.0),
	"bau": Vector2(260.0, 620.0),
	"trong": Vector2(540.0, 620.0),
	"sao": Vector2(820.0, 620.0),
}


const LINH_TIPS := [
	"Bạn có biết: Đàn Tranh có nguồn gốc từ đàn Tranh cổ tự, nhưng được các nghệ nhân cải tiến với âm sắc thanh tao đặc trưng Việt Nam.",
	"Luyện tập hàng ngày giúp tai nghe nhạy bén và ngón tay linh hoạt hơn đó!",
	"Hãy thử học một bài hát mới trong Kho Bài Hát để tích lũy thêm điểm XP nhé.",
	"Sáo Trúc làm từ các ống tre, trúc già tự nhiên, mang hơi thở của sông núi làng quê Việt Nam.",
	"Hãy thử luyện tập Đàn Bầu hoặc Trống Chầu để khám phá các âm điệu mới nhé!"
]


func _ready() -> void:
	# Reset anchors to Top-Left to allow manual absolute positioning in _on_viewport_size_changed()
	room_content.anchor_left = 0.0
	room_content.anchor_top = 0.0
	room_content.anchor_right = 0.0
	room_content.anchor_bottom = 0.0
	room_content.size = Vector2(1200, 800)
	var focus_scroll = popup.get_node_or_null("ScrollPanel")
	if focus_scroll:
		focus_scroll.custom_minimum_size = Vector2(920, 580)

	SecureDataManager.load_data()
	
	_api_client = preload("res://scripts/ApiClient.gd").new()
	add_child(_api_client)
	_fetch_cosmetics_data()
	_fetch_instruments_data()
	
	_spawn_decorations()
	_setup_hud_shop_button()
	_tex_decor_chausen = _load_decor_texture("res://assets/textures/comestic_rewards/277822b0-ef0c-48e5-b7cf-59fb941dd3e3.png")
	_tex_decor_bantra = _load_decor_texture("res://assets/textures/comestic_rewards/53b2828a-00b9-4913-8ef1-ea95f7efe6aa.png")
	_tex_decor_tranh = _load_decor_texture("res://assets/textures/comestic_rewards/6a00c552-cc19-47ac-bb4e-4da0900a6473.png")
	_tex_decor_quat = _load_decor_texture("res://assets/textures/comestic_rewards/70833c90-f0c2-4f58-9df3-9d348f1c28fe.png")
	_tex_decor_denlong = _load_decor_texture("res://assets/textures/comestic_rewards/7f2fca74-fec1-42a5-ba94-bfde4c80fe21.png")
	_tex_decor_denda = _load_decor_texture("res://assets/textures/comestic_rewards/98fada3c-096e-4105-af8d-c74e249aad04.png")
	_tex_decor_chuonggio = _load_decor_texture("res://assets/textures/comestic_rewards/a39c0e84-7cad-4af1-823e-af840b82328a.png")
	_tex_decor_binhsen = _load_decor_texture("res://assets/textures/comestic_rewards/a5f93c96-38b6-4692-b001-8e2e7704040f.png")
	_tex_tranh = load("res://assets/textures/dan_tranh_17_assetremove.png") as Texture2D
	_tex_sao = load("res://assets/textures/sao_truc_SN01_assetremove.png") as Texture2D
	_tex_bau = load("res://assets/textures/dan_bau_assetremove.png") as Texture2D
	_tex_trong = load("res://assets/textures/trong_chau_assetremove.png") as Texture2D
	_tex_linh = load("res://assets/textures/cogiaoMai_asset.png") as Texture2D
	_tex_linh_talk = load("res://assets/textures/coMai/mai_talk_sheet.png") as Texture2D
	_tex_linh_walk_down = load("res://assets/textures/coMai/mai_walk_down_sheet.png") as Texture2D
	_tex_linh_walk_up = load("res://assets/textures/coMai/mai_walk_up_sheet.png") as Texture2D
	_tex_linh_walk_left = load("res://assets/textures/coMai/mai_walk_left_sheet.png") as Texture2D
	_tex_linh_walk_right = load("res://assets/textures/coMai/mai_walk_right_sheet.png") as Texture2D
	_tex_linh_walk_down_left = load("res://assets/textures/coMai/mai_walk_down_left_sheet.png") as Texture2D
	_tex_linh_walk_down_right = load("res://assets/textures/coMai/mai_walk_down_right_sheet.png") as Texture2D
	_tex_linh_walk_up_left = load("res://assets/textures/coMai/mai_walk_up_left_sheet.png") as Texture2D
	_tex_linh_walk_up_right = load("res://assets/textures/coMai/mai_walk_up_right_sheet.png") as Texture2D
	_tex_player = load("res://assets/textures/default_avatar.png") as Texture2D
	_tex_wall = load("res://assets/textures/backgroundphonghocao.png") as Texture2D
	
	# Initialize Player Character (Disabled/Removed by design)
	char_player = null

	
	# FloorCanvas click handling
	floor_canvas.mouse_filter = Control.MOUSE_FILTER_PASS
	floor_canvas.gui_input.connect(_on_floor_gui_input)
	
	# Load premium fonts
	_font_title = load("res://assets/fonts/Lora-Bold.ttf") as Font
	_font_body = load("res://assets/fonts/BeVietnamPro-Regular.ttf") as Font
	_font_body_bold = load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	
	if _font_title:
		popup_title.add_theme_font_override("font", _font_title)
	if _font_body:
		text_theory.add_theme_font_override("font", _font_body)
		text_fingering.add_theme_font_override("font", _font_body)
	if _font_body_bold:
		prompt_lbl.add_theme_font_override("font", _font_body_bold)
		tooltip_lbl.add_theme_font_override("font", _font_body_bold)
		btn_tab_theory.add_theme_font_override("font", _font_body_bold)
		btn_tab_fingering.add_theme_font_override("font", _font_body_bold)
		btn_popup_play.add_theme_font_override("font", _font_body_bold)
		btn_popup_close.add_theme_font_override("font", _font_body_bold)
		btn_back.add_theme_font_override("font", _font_body_bold)
		
	# Initialize ambient particles
	for i in range(30):
		_particles.append({
			"pos": Vector2(randf_range(0, 1200), randf_range(-100, 800)),
			"speed": Vector2(randf_range(-30, 30), randf_range(50, 110)),
			"rot": randf_range(0, TAU),
			"rot_speed": randf_range(-2.0, 2.0),
			"scale": randf_range(0.6, 1.4),
			"color": Color(0.77, 0.58, 0.15, randf_range(0.25, 0.65)) if randf() > 0.4 else Color(0.09, 0.27, 0.18, randf_range(0.25, 0.65))
		})

	# Drawing connections
	bg_canvas.draw.connect(_draw_room_background)
	floor_canvas.draw.connect(_draw_floor_canvas)
	popup_draw.draw.connect(_draw_popup_scroll.bind(popup_draw))
	
	# Interact prompt styling
	interact_prompt.add_theme_stylebox_override("panel", _flat_sb(C_RED_SON, C_GOLD, 12, true, 2))
	prompt_lbl.add_theme_color_override("font_color", C_CREAM)
	diagram_theory.draw.connect(_draw_diagram_theory.bind(diagram_theory))
	diagram_fingering.draw.connect(_draw_diagram_fingering.bind(diagram_fingering))
	

	
	# Setup Tooltip Box Style
	station_tooltip.add_theme_stylebox_override("panel", _flat_sb(C_BG_DARKER, C_RED_SON, 12, true, 2))
	tooltip_lbl.add_theme_color_override("font_color", C_RED_DK)
	
	# Setup Interactive Stations
	s_tranh.size = Vector2(400, 240)
	s_sao.size = Vector2(400, 240)
	s_bau.size = Vector2(400, 240)
	s_trong.size = Vector2(400, 240)
	
	_setup_station_button(s_tranh, "tranh", _draw_tranh)
	_setup_station_button(s_sao, "sao", _draw_sao)
	_setup_station_button(s_bau, "bau", _draw_bau)
	_setup_station_button(s_trong, "trong", _draw_trong)
	
	# Setup Linh Assist
	char_linh.draw.connect(_draw_linh.bind(char_linh))
	char_linh.position.y += 170.0
	_linh_base_y = char_linh.position.y
	char_linh.gui_input.connect(_on_char_linh_gui_input)
	
	# Speech bubble hidden (removed by design)
	
	# Setup Focus Mode Popup controls
	_setup_focus_popup_controls()
	_setup_hanging_scroll()
	
	# Setup Back button to return to Main Menu (Icon button for mobile style)
	btn_back.show()
	btn_back.text = ""
	btn_back.icon = load("res://icons8/icons8-back-16.png") as Texture2D
	btn_back.expand_icon = true
	btn_back.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_hud_icon_button(btn_back)
	_make_btn_bouncy(btn_back)
	btn_back.pressed.connect(func() -> void:
		if _audio_manager:
			_audio_manager.audio_player.stop()
		_fade_to("res://scenes/MainMenu.tscn")
	)
	
	# Transition fade in
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.35)

	# Responsive connection
	get_viewport().size_changed.connect(func() -> void: _on_viewport_size_changed.call_deferred())
	_on_viewport_size_changed()
	
	_audio_manager = AIAudioManager.new()
	_audio_manager.name = "AIAudioManager"
	add_child(_audio_manager)
	
	# Play welcome speech only once per session
	if not _has_played_intro:
		get_tree().create_timer(0.8).timeout.connect(_start_intro_cinematic)



func _process(delta: float) -> void:
	_time += delta
	bg_canvas.queue_redraw()
	char_linh.queue_redraw()
	floor_canvas.queue_redraw()
	
	# Update idle breathing cycle when not moving
	if not _player_is_moving:
		_idle_breath_time += delta * 2.2
		_idle_time += delta
		if _idle_time > 6.0 and _player_expression == "normal":
			_player_expression = "sleepy"
	else:
		_idle_breath_time = 0.0
		_idle_time = 0.0
		if _player_expression == "sleepy":
			_player_expression = "normal"
		
	# Update random eye blinking cycle
	_blink_timer -= delta
	if _blink_timer <= 0.0:
		_is_blinking = true
		_blink_timer = randf_range(2.5, 5.5)
	if _is_blinking:
		_blink_duration -= delta
		if _blink_duration <= 0.0:
			_is_blinking = false
			_blink_duration = 0.15
			
	# Update typewriter text progress for NPC dialogue box
	if dialogue_box != null and dialogue_box.visible and _typewriter_progress < _typewriter_text.length():
		_typewriter_progress += delta * 35.0
		dialogue_lbl.text = _typewriter_text.left(int(_typewriter_progress))
	
	# Update particles drift across visible widescreen boundaries
	var rx := room_content.position.x
	var ry := room_content.position.y
	var scale := room_content.scale.x
	var viewport_size : Vector2 = get_viewport().get_visible_rect().size
	var left_bound : float = -rx / scale if scale > 0.0 else 0.0
	var right_bound : float = (viewport_size.x - rx) / scale if scale > 0.0 else 1200.0
	var top_bound : float = -ry / scale if scale > 0.0 else 0.0
	var bottom_bound : float = (viewport_size.y - ry) / scale if scale > 0.0 else 800.0

	for p in _particles:
		p.pos += p.speed * delta
		p.rot += p.rot_speed * delta
		if p.pos.y > 800 or p.pos.x < left_bound or p.pos.x > right_bound:
			p.pos.y = -50
			p.pos.x = randf_range(left_bound, right_bound)
			p.speed.y = randf_range(50, 110)
			p.speed.x = randf_range(-30, 30)

	# Update card hover particles
	var temp_card_particles : Array[Dictionary] = []
	for p in _card_particles:
		p.life -= delta
		p.pos += p.vel * delta
		if p.life > 0.0:
			temp_card_particles.append(p)
	_card_particles = temp_card_particles

	# Spawn card hover particles if hovering an instrument
	if _hovered_station != "":
		_card_particle_timer += delta
		if _card_particle_timer > 0.04:
			_card_particle_timer = 0.0
			var rect := Rect2()
			match _hovered_station:
				"tranh": rect = Rect2(s_tranh.position.x, s_tranh.position.y, s_tranh.size.x, s_tranh.size.y)
				"sao": rect = Rect2(s_sao.position.x, s_sao.position.y, s_sao.size.x, s_sao.size.y)
				"bau": rect = Rect2(s_bau.position.x, s_bau.position.y, s_bau.size.x, s_bau.size.y)
				"trong": rect = Rect2(s_trong.position.x, s_trong.position.y, s_trong.size.x, s_trong.size.y)
			
			if rect != Rect2():
				var spawn_pos := Vector2(
					randf_range(rect.position.x - 10, rect.position.x + rect.size.x + 10),
					randf_range(rect.position.y + rect.size.y - 20, rect.position.y + rect.size.y + 10)
				)
				_card_particles.append({
					"pos": spawn_pos,
					"vel": Vector2(randf_range(-30, 30), randf_range(-65, -120)),
					"life": randf_range(0.6, 1.0),
					"max_life": 1.0,
					"initial_size": randf_range(2.0, 4.2),
					"color": Color(1.0, 0.85, 0.35, 0.8) # gold sparkle
				})

	# Update welcome bow timer
	_welcome_bow_timer = maxf(0.0, _welcome_bow_timer - delta)

	# Floating animation for pedestals/stations, preserving responsive base positions.
	var float_amp := 4.0 if _is_mobile_layout else 8.0
	s_tranh.position = _station_base_positions["tranh"] + Vector2(0.0, sin(_time * 2.0) * float_amp)
	s_sao.position = _station_base_positions["sao"] + Vector2(0.0, sin(_time * 2.0 + PI/2.0) * float_amp)
	s_bau.position = _station_base_positions["bau"] + Vector2(0.0, sin(_time * 2.0 + PI) * float_amp)
	s_trong.position = _station_base_positions["trong"] + Vector2(0.0, sin(_time * 2.0 + 1.5*PI) * float_amp)

	# Keep Linh at base Y (procedural animations handled in _draw_linh canvas transform)
	char_linh.position.y = _linh_base_y
	
	# Proximity check and prompt update (Bypassed if no player)
	var closest_station := ""
	var is_near_linh := false
	var is_ui_focused := popup.visible or (dialogue_box != null and dialogue_box.visible) or (shop_popup != null and shop_popup.visible)
	
	if char_player != null:
		closest_station = _get_closest_station()
		is_near_linh = _get_player_feet().distance_to(Vector2(600, 370)) < _interact_range

	# Movement logic (Only if student character is present)
	if char_player != null and not is_ui_focused:
		var move_dir := Vector2.ZERO
		if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
			move_dir.x -= 1
		if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
			move_dir.x += 1
		if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
			move_dir.y -= 1
		if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
			move_dir.y += 1
		
		if move_dir != Vector2.ZERO:
			# Cancel mouse travel on key press
			_is_moving_to_target = false
			_interact_target_station = ""
			_interact_target_linh = false
			_close_dialogue()
			
			move_dir = move_dir.normalized()
			_player_dir = move_dir
			char_player.position += move_dir * _player_speed * delta
			# Clamp to walkable area
			var feet_x := char_player.position.x + 80.0
			var feet_y := char_player.position.y + 150.0
			feet_x = clampf(feet_x, _left_bound + 60.0, _right_bound - 60.0)
			feet_y = clampf(feet_y, 330.0, 760.0)
			char_player.position = Vector2(feet_x - 80.0, feet_y - 150.0)
			
			_player_is_moving = true
			if move_dir.x < 0:
				_player_facing_right = false
			elif move_dir.x > 0:
				_player_facing_right = true
		elif _is_moving_to_target:
			var current_feet := _get_player_feet()
			var dist := current_feet.distance_to(_target_position)
			if dist < 5.0:
				char_player.position = Vector2(_target_position.x - 80.0, _target_position.y - 150.0)
				_is_moving_to_target = false
				_player_is_moving = false
				
				# Trigger interaction if arriving at a station or Linh
				if _interact_target_station != "":
					_open_focus_mode_popup(_interact_target_station)
					_interact_target_station = ""
				elif _interact_target_linh:
					_show_dialogue(LINH_TIPS.pick_random())
					_interact_target_linh = false
			else:
				var dir := (_target_position - current_feet).normalized()
				_player_dir = dir
				char_player.position += dir * _player_speed * delta
				_player_is_moving = true
				if dir.x < 0:
					_player_facing_right = false
				elif dir.x > 0:
					_player_facing_right = true
		else:
			_player_is_moving = false
	else:
		_player_is_moving = false
		_is_moving_to_target = false
		_interact_target_station = ""
		_interact_target_linh = false

	# Update walk cycle timer and trigger redraw (Only if student is present)
	if char_player != null:
		if _player_is_moving:
			_player_walk_time += delta * 12.0
			char_player.queue_redraw()
			
			# Spawn walk particles
			_walk_particle_timer += delta
			if _walk_particle_timer > 0.08:
				_walk_particle_timer = 0.0
				_walk_particles.append({
					"pos": _get_player_feet(),
					"vel": Vector2(randf_range(-20, 20), randf_range(-10, -30)),
					"life": 0.6,
					"max_life": 0.6,
					"initial_size": randf_range(3.0, 6.5),
					"color": Color(C_GOLD_LIGHT.r, C_GOLD_LIGHT.g, C_GOLD_LIGHT.b, 0.7)
				})
		else:
			char_player.queue_redraw()

		
	# Update walk particles
	var temp_walk_particles : Array[Dictionary] = []
	for p in _walk_particles:
		p.life -= delta
		p.pos += p.vel * delta
		p.size = p.initial_size * (p.life / p.max_life)
		p.color.a = 0.7 * (p.life / p.max_life)
		if p.life > 0.0:
			temp_walk_particles.append(p)
	_walk_particles = temp_walk_particles

	# Proximity prompt update (Only if student is present)
	if char_player != null:
		var want_prompt := false
		var prompt_text := ""
		var prompt_action_station := ""
		var prompt_action_linh := false
		
		if closest_station != "" and not is_ui_focused:
			want_prompt = true
			var station_name := ""
			match closest_station:
				"tranh": station_name = "Đàn Tranh"
				"sao": station_name = "Sáo Trúc"
				"bau": station_name = "Đàn Bầu"
				"trong": station_name = "Trống Chầu"
			prompt_text = "Ấn [E] để tương tác với " + station_name
			prompt_action_station = closest_station
		elif is_near_linh and not is_ui_focused:
			want_prompt = true
			prompt_text = "Ấn [E] để trò chuyện với cô Mai"
			prompt_action_linh = true

		if want_prompt:
			prompt_lbl.text = prompt_text
			
			# Center above player head
			var target_x := char_player.position.x + (char_player.size.x - interact_prompt.size.x) / 2.0
			var target_y := char_player.position.y - 10.0
			
			if not _prompt_is_showing:
				_prompt_is_showing = true
				interact_prompt.visible = true
				interact_prompt.position = Vector2(target_x, target_y + 15.0) # start slightly lower
				interact_prompt.modulate.a = 0.0
				
				if _prompt_tween:
					_prompt_tween.kill()
				_prompt_tween = create_tween().set_parallel(true)
				_prompt_tween.tween_property(interact_prompt, "position", Vector2(target_x, target_y), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				_prompt_tween.tween_property(interact_prompt, "modulate:a", 1.0, 0.25)
			else:
				# Update position continuously
				interact_prompt.position = Vector2(target_x, target_y)
				
			if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_E):
				if prompt_action_station != "":
					_open_focus_mode_popup(prompt_action_station)
				elif prompt_action_linh:
					_show_dialogue(LINH_TIPS.pick_random())
		else:
			if _prompt_is_showing:
				_prompt_is_showing = false
				if _prompt_tween:
					_prompt_tween.kill()
				_prompt_tween = create_tween().set_parallel(true)
				var target_y := char_player.position.y - 10.0
				var target_x := char_player.position.x + (char_player.size.x - interact_prompt.size.x) / 2.0
				_prompt_tween.tween_property(interact_prompt, "position", Vector2(target_x, target_y + 15.0), 0.2).set_ease(Tween.EASE_IN)
				_prompt_tween.tween_property(interact_prompt, "modulate:a", 0.0, 0.2)
				_prompt_tween.chain().tween_callback(func() -> void: interact_prompt.visible = false)
	else:
		interact_prompt.visible = false


	if _linh_is_moving or _player_is_moving:
		_sort_room_elements()
	
	# Occasional random talk from Linh if idle (Disabled per user request)
	# _speech_timer += delta
	# if _speech_timer > 15.0:
	# 	_speech_timer = 0.0
	# 	if _hovered_station == "" and not is_ui_focused:
	# 		_show_dialogue(LINH_TIPS.pick_random())

# ─── Tooltip & Affordance Interactive Stations ─────────────────────────────────
func _setup_station_button(btn: Button, code_name: String, draw_func: Callable) -> void:
	btn.pivot_offset = btn.size / 2.0
	btn.draw.connect(_on_station_draw.bind(btn, code_name, draw_func))
	
	# Override button styles to flat/empty to remove ugly Godot grey boxes
	var empty_sb := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty_sb)
	btn.add_theme_stylebox_override("hover", empty_sb)
	btn.add_theme_stylebox_override("pressed", empty_sb)
	btn.add_theme_stylebox_override("focus", empty_sb)
	btn.flat = true
	
	btn.mouse_entered.connect(_on_station_mouse_entered.bind(btn, code_name))
	btn.mouse_exited.connect(_on_station_mouse_exited.bind(btn, code_name))
	btn.pressed.connect(_on_station_pressed.bind(btn, code_name))

func _on_station_draw(btn: Button, code_name: String, draw_func: Callable) -> void:
	var displayName : String = _instruments_data.get(code_name, {}).get("name", "")
	var sz := btn.size
	var is_hov := btn.is_hovered()
	
	# Draw the custom instrument vectors
	draw_func.call(btn)
	
	# Draw instrument name label at the bottom of the card using _font_body_bold
	var font := _font_body_bold if _font_body_bold else btn.get_theme_default_font()
	if font:
		var name_str : String = displayName
		if displayName.contains(" (Sắp ra mắt)"):
			name_str = displayName.replace(" (Sắp ra mắt)", "")
			
		var cy := sz.y * 0.5
		var lbl_x := 0.0
		var has_tex := false
		if btn.name == "StationTranh" and _tex_tranh: has_tex = true
		elif btn.name == "StationSao" and _tex_sao: has_tex = true
		elif btn.name == "StationBau" and _tex_bau: has_tex = true
		elif btn.name == "StationTrong" and _tex_trong: has_tex = true
		
		var lbl_y := sz.y - 12.0
		if has_tex:
			lbl_y = sz.y - 16.0
		var label_font_size := 15 if _is_mobile_layout else 17
		
		# Shadow
		btn.draw_string(font, Vector2(lbl_x + 1, lbl_y + 1), name_str,
			HORIZONTAL_ALIGNMENT_CENTER, sz.x, label_font_size, Color(0, 0, 0, 0.70))
		# Main text: gold when hovered, cream when normal
		var text_col := C_GOLD_LIGHT if is_hov else C_CREAM
		btn.draw_string(font, Vector2(lbl_x, lbl_y), name_str,
			HORIZONTAL_ALIGNMENT_CENTER, sz.x, label_font_size, text_col)

func _on_station_mouse_entered(btn: Button, code_name: String) -> void:
	_hovered_station = code_name
	var displayName : String = _instruments_data.get(code_name, {}).get("name", "")
	
	# Bouncy scale up and request redraw for glows
	var t := create_tween().set_parallel(true)
	t.tween_property(btn, "scale", Vector2(1.12, 1.12), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Show custom floating tooltip directly above the instrument
	tooltip_lbl.text = displayName
	station_tooltip.visible = true
	station_tooltip.modulate.a = 0.0
	
	# Position tooltip centered above the button
	var btn_center_x = btn.position.x + btn.size.x / 2.0
	var btn_top_y = btn.position.y
	station_tooltip.position = Vector2(btn_center_x - station_tooltip.size.x / 2.0, btn_top_y - 45)
	
	var tt_t := create_tween()
	tt_t.tween_property(station_tooltip, "modulate:a", 1.0, 0.15)

func _on_station_mouse_exited(btn: Button, code_name: String) -> void:
	if _hovered_station == code_name:
		_hovered_station = ""
		
	var t := create_tween()
	t.tween_property(btn, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Fade out tooltip
	var tt_t := create_tween()
	tt_t.tween_property(station_tooltip, "modulate:a", 0.0, 0.1)
	tt_t.tween_callback(func() -> void: station_tooltip.visible = false)

func _on_station_pressed(btn: Button, code_name: String) -> void:
	if _station_transitioning:
		return
	_station_transitioning = true
	_player_expression = "focused"

	# Visual press feedback
	var pt := create_tween()
	pt.tween_property(btn, "scale", Vector2(0.92, 0.92), 0.08)
	pt.tween_property(btn, "scale", Vector2(1.08, 1.08) if btn.is_hovered() else Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK)
	
	_move_linh_to_station(code_name, false)

func _select_instrument_and_enter(code_name: String) -> void:
	if code_name == "tranh":
		InstrumentSelect.selected_instrument = "dan_tranh"
		SecureDataManager.data["selected_instrument"] = "dan_tranh"
		SecureDataManager.save_data()
		_fade_to("res://scenes/MainMenu.tscn")
	elif code_name == "sao":
		InstrumentSelect.selected_instrument = "sao_truc"
		SecureDataManager.data["selected_instrument"] = "sao_truc"
		SecureDataManager.save_data()
		_fade_to("res://scenes/MainMenu.tscn")
	elif code_name == "bau":
		InstrumentSelect.selected_instrument = "dan_bau"
		SecureDataManager.data["selected_instrument"] = "dan_bau"
		SecureDataManager.save_data()
		_fade_to("res://scenes/MainMenu.tscn")
	elif code_name == "trong":
		InstrumentSelect.selected_instrument = "trong_chau"
		SecureDataManager.data["selected_instrument"] = "trong_chau"
		SecureDataManager.save_data()
		_fade_to("res://scenes/MainMenu.tscn")



func _move_player_to_station(code_name: String) -> void:
	var target_feet := _get_station_interact_spot(code_name)
	var player_feet := _get_player_feet()
	if player_feet.distance_to(target_feet) < _interact_range:
		_open_focus_mode_popup(code_name)
	else:
		_target_position = target_feet
		_is_moving_to_target = true
		_interact_target_station = code_name
		_interact_target_linh = false
		_close_dialogue()

func _get_player_feet() -> Vector2:
	if not char_player:
		return _player_pos
	return char_player.position + Vector2(80.0, 150.0)

func _get_station_center(btn: Button) -> Vector2:
	return btn.position + btn.size * 0.5

func _get_station_floor_center(btn: Button) -> Vector2:
	var floor_offset := 22.0 if _is_mobile_layout else 35.0
	return _get_station_center(btn) + Vector2(0.0, floor_offset)

func _get_linh_feet_offset() -> Vector2:
	return Vector2(char_linh.size.x * 0.5, char_linh.size.y * 0.5 + 74.0)

func _get_station_interact_spot(code_name: String) -> Vector2:
	match code_name:
		"tranh": return _get_station_floor_center(s_tranh) + Vector2(0.0, 45.0)
		"sao": return _get_station_floor_center(s_sao) + Vector2(0.0, 45.0)
		"bau": return _get_station_floor_center(s_bau) + Vector2(0.0, 45.0)
		"trong": return _get_station_floor_center(s_trong) + Vector2(0.0, 45.0)
	return Vector2(600, 480)

func _get_closest_station() -> String:
	var player_feet := _get_player_feet()
	var stations := {
		"tranh": _get_station_floor_center(s_tranh),
		"sao": _get_station_floor_center(s_sao),
		"bau": _get_station_floor_center(s_bau),
		"trong": _get_station_floor_center(s_trong)
	}
	var closest := ""
	var min_dist := _interact_range
	for code in stations:
		var dist := player_feet.distance_to(stations[code])
		if dist < min_dist:
			closest = code
			min_dist = dist
	return closest

func _on_floor_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_event := event as InputEventMouseButton
		var click_pos := mouse_event.position
		click_pos.x = clampf(click_pos.x, _left_bound + 60.0, _right_bound - 60.0)
		click_pos.y = clampf(click_pos.y, 330.0, 760.0)
		_target_position = click_pos
		_is_moving_to_target = true
		_interact_target_station = ""
		_interact_target_linh = false
		_close_dialogue()

func _move_linh_to_station(station_code: String, show_popup_after_move: bool = true) -> void:
	if _linh_tween:
		_linh_tween.kill()
	
	var target_feet := Vector2(600, 370) # default starting feet position
	
	match station_code:
		"tranh":       target_feet = _get_station_floor_center(s_tranh)
		"sao":         target_feet = _get_station_floor_center(s_sao)
		"bau":         target_feet = _get_station_floor_center(s_bau)
		"trong":       target_feet = _get_station_floor_center(s_trong)
	
	var linh_feet_offset := _get_linh_feet_offset()
	var current_feet := char_linh.position + linh_feet_offset
	var move_delta := target_feet - current_feet
	_linh_walk_direction = _get_linh_walk_direction(move_delta)
	_linh_is_moving = true
	var target_x := target_feet.x - linh_feet_offset.x
	var target_y := target_feet.y - linh_feet_offset.y
	
	_linh_tween = create_tween()
	_linh_tween.set_parallel(true)
	_linh_tween.tween_property(char_linh, "position:x", target_x, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_linh_tween.tween_property(self, "_linh_base_y", target_y, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	_linh_tween.set_parallel(false)
	_linh_tween.tween_callback(func() -> void:
		_linh_is_moving = false
		if show_popup_after_move:
			_open_focus_mode_popup(station_code)
		else:
			_select_instrument_and_enter(station_code)
	)

func _get_linh_walk_direction(move_delta: Vector2) -> String:
	# Use a diagonal animation when both axes make up a meaningful part of the path.
	# This avoids a barely diagonal route looking like it is moving sideways or vertically.
	var horizontal := absf(move_delta.x)
	var vertical := absf(move_delta.y)
	if minf(horizontal, vertical) >= maxf(horizontal, vertical) * 0.35:
		if move_delta.y >= 0.0:
			return "down_right" if move_delta.x >= 0.0 else "down_left"
		return "up_right" if move_delta.x >= 0.0 else "up_left"
	if horizontal > vertical:
		return "right" if move_delta.x >= 0.0 else "left"
	return "down" if move_delta.y >= 0.0 else "up"

func _linh_talk(_txt: String) -> void:
	# Speech bubble removed — teacher speaks through the popup now
	pass

func _on_char_linh_gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		if _audio_manager:
			_audio_manager.audio_player.stop()
		var chat = AIChatPopup.new()
		$HUD.add_child(chat)
		chat.open_chat("general")



# ─── Focus Mode Popup ──────────────────────────────────────────────────────────
func _setup_focus_popup_controls() -> void:
	_style_popup_button(btn_popup_play, true)
	_style_popup_button(btn_popup_close, false)
	_style_popup_tab_button(btn_tab_theory, true)
	_style_popup_tab_button(btn_tab_fingering, false)
	
	btn_tab_theory.pressed.connect(func() -> void:
		_toggle_popup_tab(true)
	)
	btn_tab_fingering.pressed.connect(func() -> void:
		_toggle_popup_tab(false)
	)
	
	btn_popup_close.pressed.connect(func() -> void:
		_player_expression = "normal"
		var t := create_tween()
		t.tween_property(popup, "modulate:a", 0.0, 0.2)
		t.tween_callback(func() -> void: popup.visible = false)
	)
	
	btn_popup_play.pressed.connect(func() -> void:
		if _current_popup_instrument == "tranh":
			InstrumentSelect.selected_instrument = "dan_tranh"
			SecureDataManager.data["selected_instrument"] = "dan_tranh"
			SecureDataManager.save_data()
			_fade_to("res://scenes/MainMenu.tscn")
		elif _current_popup_instrument == "sao":
			InstrumentSelect.selected_instrument = "sao_truc"
			SecureDataManager.data["selected_instrument"] = "sao_truc"
			SecureDataManager.save_data()
			_fade_to("res://scenes/MainMenu.tscn")
		elif _current_popup_instrument == "bau":
			InstrumentSelect.selected_instrument = "dan_bau"
			SecureDataManager.data["selected_instrument"] = "dan_bau"
			SecureDataManager.save_data()
			_fade_to("res://scenes/MainMenu.tscn")
		elif _current_popup_instrument == "trong":
			InstrumentSelect.selected_instrument = "trong_chau"
			SecureDataManager.data["selected_instrument"] = "trong_chau"
			SecureDataManager.save_data()
			_fade_to("res://scenes/MainMenu.tscn")
	)
	
	_make_btn_bouncy(btn_tab_theory)
	_make_btn_bouncy(btn_tab_fingering)
	_make_btn_bouncy(btn_popup_play)
	_make_btn_bouncy(btn_popup_close)

func _open_focus_mode_popup(inst: String) -> void:
	if _audio_manager:
		_audio_manager.audio_player.stop()
	_current_popup_instrument = inst
	_player_expression = "focused"
	_toggle_popup_tab(true)
	
	# Configure labels and details based on instrument from dynamic data
	if _instruments_data.has(inst):
		var data = _instruments_data[inst]
		popup_title.text = "Giới Thiệu " + data.get("name", "")
		text_theory.text = data.get("desc", "")
		text_fingering.text = data.get("fingering", "")
		btn_popup_play.visible = true
		btn_popup_play.text = "VÀO HỌC"
	else:
		popup_title.text = "Giới Thiệu Nhạc Cụ"
		text_theory.text = ""
		text_fingering.text = ""
		btn_popup_play.visible = false
	
	# Request redraws on diagrams
	diagram_theory.queue_redraw()
	diagram_fingering.queue_redraw()
	popup_draw.queue_redraw()
	
	# Anim modal fade-in
	popup.visible = true
	popup.modulate.a = 0.0
	create_tween().tween_property(popup, "modulate:a", 1.0, 0.2)

func _toggle_popup_tab(show_theory: bool) -> void:
	theory_panel.visible = show_theory
	fingering_panel.visible = not show_theory
	_style_popup_tab_button(btn_tab_theory, show_theory)
	_style_popup_tab_button(btn_tab_fingering, not show_theory)

func _style_popup_tab_button(btn: Button, active: bool) -> void:
	var bg := C_RED_SON if active else Color(0.95, 0.93, 0.89, 0.6)
	var fg := C_CREAM if active else C_TEXT_MUTED
	var border := C_RED_SON if active else Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.2)
	btn.add_theme_stylebox_override("normal", _flat_sb(bg, border, 12, false, 1))
	btn.add_theme_stylebox_override("hover", _flat_sb(bg.lightened(0.1), border, 12, false, 1))
	btn.add_theme_stylebox_override("pressed", _flat_sb(bg.darkened(0.1), border, 12, false, 1))
	btn.add_theme_stylebox_override("focus", _flat_sb(Color(0,0,0,0), Color(0,0,0,0), 0))
	btn.add_theme_color_override("font_color", fg)
	btn.add_theme_color_override("font_hover_color", fg)
	btn.add_theme_color_override("font_pressed_color", fg)

func _style_popup_button(btn: Button, primary: bool) -> void:
	var bg := C_RED_SON if primary else Color(0, 0, 0, 0)
	var border := C_GOLD if primary else C_RED_SON
	var fg := C_CREAM if primary else C_RED_SON
	btn.add_theme_stylebox_override("normal", _flat_sb(bg, border, 20, primary, 3))
	btn.add_theme_stylebox_override("hover", _flat_sb(bg.lightened(0.12), border.lightened(0.1), 20, primary, 3))
	btn.add_theme_stylebox_override("pressed", _flat_sb(bg.darkened(0.12), border, 20, false, 1))
	btn.add_theme_stylebox_override("focus", _flat_sb(Color(0,0,0,0), Color(0,0,0,0), 0))
	btn.add_theme_color_override("font_color", fg)
	btn.add_theme_color_override("font_hover_color", fg)
	btn.remove_theme_stylebox_override("disabled")
	btn.remove_theme_color_override("font_disabled_color")

func _style_hud_icon_button(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", _flat_sb(Color(0,0,0,0), Color(0,0,0,0), 0))
	btn.add_theme_stylebox_override("hover", _flat_sb(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.12), Color(0,0,0,0), 28))
	btn.add_theme_stylebox_override("pressed", _flat_sb(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.22), Color(0,0,0,0), 28))
	btn.add_theme_stylebox_override("focus", _flat_sb(Color(0,0,0,0), Color(0,0,0,0), 0))
	btn.add_theme_color_override("icon_normal_color", Color(0.25, 0.18, 0.12)) # Warm bronze-brown
	btn.add_theme_color_override("icon_hover_color", C_GOLD)
	btn.add_theme_color_override("icon_pressed_color", Color(0.5, 0.4, 0.3))

# ─── Procedural 2.5D Room Drawing – Classical Vietnamese Style ─────────────────
func _draw_room_background() -> void:
	var viewport_size : Vector2 = get_viewport().get_visible_rect().size
	# 1. Deep background — aged indigo/midnight tone
	bg_canvas.draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.07, 0.05, 0.04))
	
	# Set transform relative to room_content (1200x800 space)
	bg_canvas.draw_set_transform(room_content.position, 0.0, room_content.scale)
	var sz := Vector2(1200, 800)
	var wall_h := 380.0 if _is_mobile_layout else 480.0
	
	# Calculate visible screen boundaries in transformed coordinates to stretch room background
	var rx := room_content.position.x
	var ry := room_content.position.y
	var scale := room_content.scale.x
	var left_bound : float = -rx / scale if scale > 0.0 else 0.0
	var right_bound : float = (viewport_size.x - rx) / scale if scale > 0.0 else 1200.0
	var top_bound : float = -ry / scale if scale > 0.0 else 0.0
	var bottom_bound : float = (viewport_size.y - ry) / scale if scale > 0.0 else 800.0
	
	# ── 2. Wall: Custom image background ──────
	if _tex_wall:
		var wall_rect := Rect2(left_bound, top_bound, right_bound - left_bound, wall_h - top_bound)
		bg_canvas.draw_texture_rect(_tex_wall, wall_rect, false)
	else:
		var steps := 32
		var step_h := (wall_h - top_bound) / steps
		var col_top := Color(0.97, 0.96, 0.92) # Luminous light cream-white
		var col_bottom := Color(0.99, 0.99, 0.96) # Luminous bright warm-white
		for s in range(steps):
			var y1 = top_bound + s * step_h
			var y2 = y1 + step_h
			var t = float(s) / float(steps)
			var col = col_top.lerp(col_bottom, t)
			bg_canvas.draw_rect(Rect2(left_bound, y1, right_bound - left_bound, y2 - y1), col)
		
		for i in range(int(top_bound), int(wall_h), 8):
			var streak_a := 0.02 * sin(float(i) * 0.3 + _time * 0.1)
			var streak_col := Color(0.95 + streak_a, 0.93, 0.88, 0.08) # Very subtle bright streaks
			bg_canvas.draw_line(Vector2(left_bound, i), Vector2(right_bound, i), streak_col, 1.0)
	
	# ── 3. Ornate upper cornice (horizontal gilded beam - Stretched!) ─────────────
	var cornice_y := wall_h - 36.0
	bg_canvas.draw_rect(Rect2(left_bound, cornice_y, right_bound - left_bound, 36), C_RED_SON) # Deep jade green cornice
	# Gold leaf trim lines
	bg_canvas.draw_line(Vector2(left_bound, cornice_y), Vector2(right_bound, cornice_y), C_GOLD, 3.0)
	bg_canvas.draw_line(Vector2(left_bound, cornice_y + 6), Vector2(right_bound, cornice_y + 6), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35), 1.0)
	bg_canvas.draw_line(Vector2(left_bound, wall_h - 3), Vector2(right_bound, wall_h - 3), C_GOLD, 3.0)
	
	# Cornice notches (repeating motif across bounds)
	var start_notch : float = floor(left_bound / 80.0) * 80.0
	for cx_n in range(start_notch, right_bound, 80.0):
		bg_canvas.draw_rect(Rect2(cx_n - 2, cornice_y + 10, 4, 16), C_GOLD_LIGHT)
	
	# ── 4. Central hanging scroll calligraphy panel rollers and ribbons ───────────
	var scroll_w := 160.0 if _is_mobile_layout else 220.0
	var scroll_h := 160.0 if _is_mobile_layout else 210.0
	var scroll_x := (sz.x - scroll_w) / 2.0
	var scroll_y := 12.0
	
	# Top & bottom rollers (dark lacquered wood)
	var roller_col := Color(0.18, 0.10, 0.05)
	bg_canvas.draw_rect(Rect2(scroll_x - 12, scroll_y - 10, scroll_w + 24, 14), roller_col)
	bg_canvas.draw_rect(Rect2(scroll_x - 12, scroll_y - 10, scroll_w + 24, 14), C_GOLD, false, 1.5)
	bg_canvas.draw_circle(Vector2(scroll_x - 12, scroll_y - 3), 8, C_GOLD)
	bg_canvas.draw_circle(Vector2(scroll_x + scroll_w + 12, scroll_y - 3), 8, C_GOLD)
	bg_canvas.draw_rect(Rect2(scroll_x - 12, scroll_y + scroll_h - 4, scroll_w + 24, 14), roller_col)
	bg_canvas.draw_rect(Rect2(scroll_x - 12, scroll_y + scroll_h - 4, scroll_w + 24, 14), C_GOLD, false, 1.5)
	bg_canvas.draw_circle(Vector2(scroll_x - 12, scroll_y + scroll_h + 3), 8, C_GOLD)
	bg_canvas.draw_circle(Vector2(scroll_x + scroll_w + 12, scroll_y + scroll_h + 3), 8, C_GOLD)
	# Hanging ribbons from scroll
	var rib_x1 := scroll_x + scroll_w * 0.25
	var rib_x2 := scroll_x + scroll_w * 0.75
	bg_canvas.draw_line(Vector2(rib_x1, scroll_y - 10), Vector2(rib_x1, 0), C_RED_SON, 3.0)
	bg_canvas.draw_line(Vector2(rib_x2, scroll_y - 10), Vector2(rib_x2, 0), C_RED_SON, 3.0)
	
	# ── 5. Side column pillars (deep jade green wood - Framed to Screen!) ──
	for col_x in [_left_bound + 60.0, _right_bound - 80.0]:
		# Column base shadow
		bg_canvas.draw_rect(Rect2(col_x + 3, 0, 20, wall_h), Color(0, 0, 0, 0.25))
		# Column body
		bg_canvas.draw_rect(Rect2(col_x, 0, 20, wall_h), C_RED_SON) # Premium deep jade green body
		# Gold gilded edge
		bg_canvas.draw_line(Vector2(col_x, 0), Vector2(col_x, wall_h), C_GOLD, 2.0)
		bg_canvas.draw_line(Vector2(col_x + 20, 0), Vector2(col_x + 20, wall_h), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.4), 1.0)
		# Capital ornament at top
		bg_canvas.draw_rect(Rect2(col_x - 8, 0, 36, 16), C_RED_SON)
		bg_canvas.draw_rect(Rect2(col_x - 8, 0, 36, 16), C_GOLD, false, 1.5)
		
	# ── 6. Hanging lanterns (two golden silk lanterns either side) ──────────────────
	var pulse := 0.08 * sin(_time * 1.8)
	for lan_x in [_left_bound + 180.0, _right_bound - 200.0]:
		var lan_y := 20.0
		# Lantern string from ceiling
		bg_canvas.draw_line(Vector2(lan_x, 0), Vector2(lan_x, lan_y + 12), Color(0.50, 0.35, 0.15), 2.0)
		# Lantern body (oval) - soft warm gold/orange instead of red
		var lan_col := Color(0.92 + pulse, 0.76, 0.30)
		var lh := 60.0
		var lw := 28.0
		for layer in range(20):
			var t_fac := float(layer) / 20.0
			var layer_w := sin(t_fac * PI) * lw
			var layer_y := lan_y + t_fac * lh
			var stripe_col := Color(0.77 + pulse, 0.58, 0.15) if layer % 4 < 2 else lan_col # C_GOLD stripes
			bg_canvas.draw_line(Vector2(lan_x - layer_w, layer_y), Vector2(lan_x + layer_w, layer_y), stripe_col, lh / 20.0 + 0.5)
		# Top & bottom caps (gold)
		bg_canvas.draw_rect(Rect2(lan_x - lw * 0.4, lan_y, lw * 0.8, 8), C_GOLD)
		bg_canvas.draw_rect(Rect2(lan_x - lw * 0.4, lan_y + lh - 4, lw * 0.8, 8), C_GOLD)
		# Tassel fringes at bottom
		for fi in range(-3, 4):
			var flen := 18.0 + sin(fi * 1.2 + _time * 2.0) * 4.0
			bg_canvas.draw_line(Vector2(lan_x + fi * 4, lan_y + lh + 4), Vector2(lan_x + fi * 4 + sin(_time + fi) * 2, lan_y + lh + 4 + flen), Color(0.90, 0.65, 0.15, 0.85), 1.5)
	
	# ── 7. Muted dark teak hardwood floor (Stretched!) ─────────────────────────────
	var floor_pts := PackedVector2Array([
		Vector2(left_bound, wall_h), Vector2(right_bound, wall_h),
		Vector2(right_bound, bottom_bound), Vector2(left_bound, bottom_bound)
	])
	bg_canvas.draw_colored_polygon(floor_pts, Color(0.42, 0.32, 0.22))  # warm golden-brown teak wood floor
	
	# Horizontal plank grain lines stretching across bounds
	var plank_h := 16.0
	for y_floor in range(int(wall_h), int(bottom_bound), int(plank_h)):
		bg_canvas.draw_line(Vector2(left_bound, y_floor), Vector2(right_bound, y_floor), Color(0.11, 0.08, 0.05, 0.6), 1.2)
		# Staggered joint
		var joint_off := int(y_floor / plank_h) % 2 * 300
		var start_joint : float = floor((left_bound - joint_off) / 500.0) * 500.0 + joint_off
		for x_j in range(start_joint, right_bound, 500.0):
			bg_canvas.draw_line(Vector2(x_j, y_floor), Vector2(x_j, y_floor + plank_h), Color(0.11, 0.08, 0.05, 0.55), 1.0)
		# Subtle lacquer sheen highlights
		bg_canvas.draw_line(Vector2(left_bound, y_floor + 3), Vector2(right_bound, y_floor + 3), Color(0.25, 0.20, 0.15, 0.1), 1.5)
	
	# Deep shadow at the base of the wall (Stretched!)
	for j in range(30):
		var y_pos := wall_h + j * 4.0
		var alpha := (1.0 - float(j) / 30.0) * 0.75
		bg_canvas.draw_line(Vector2(left_bound, y_pos), Vector2(right_bound, y_pos), Color(0.04, 0.02, 0.01, alpha), 5.0)
	
	# ── 8. Drifting golden dust motes (incense smoke atmosphere - Softened!) ─────────────────
	for p in _particles:
		bg_canvas.draw_circle(p.pos, 2.5 * p.scale, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, p.color.a * 0.15))

func _draw_floor_canvas() -> void:
	var shadow_col := Color(0.04, 0.02, 0.01, 0.18)
	
	# Draw teacher's floor reflection (Flipped vertical texture, soft jade blend)
	if _tex_linh:
		var ref_h := 160.0 * 0.62
		var ref_rect := Rect2(600.0 - 80.0, 370.0 + ref_h, 160.0, -ref_h)
		floor_canvas.draw_texture_rect(_tex_linh, ref_rect, false, Color(0.09, 0.27, 0.18, 0.14))

	# Draw active speaking soundwave ripples under teacher
	var is_linh_speaking := false
	if _audio_manager and is_instance_valid(_audio_manager) and _audio_manager.audio_player:
		is_linh_speaking = _audio_manager.audio_player.playing
		
	if is_linh_speaking:
		var wave_center := Vector2(600.0, 370.0) # base of Linh
		var w1 := fmod(_time * 3.8, 1.0)
		var r1 := 35.0 + w1 * 65.0
		var a1 := (1.0 - w1) * 0.4
		floor_canvas.draw_arc(wave_center, r1, 0.0, TAU, 32, Color(0.95, 0.72, 0.18, a1), 2.0, true)
		
		var w2 := fmod(_time * 3.8 + 0.5, 1.0)
		var r2 := 35.0 + w2 * 65.0
		var a2 := (1.0 - w2) * 0.4
		floor_canvas.draw_arc(wave_center, r2, 0.0, TAU, 32, Color(0.95, 0.72, 0.18, a2), 2.0, true)
	
	# Station data: [center_pos, name]
	var stations := [
		[_get_station_floor_center(s_tranh), "Đàn Tranh"],
		[_get_station_floor_center(s_sao), "Sáo Trúc"],
		[_get_station_floor_center(s_bau), "Đàn Bầu"],
		[_get_station_floor_center(s_trong), "Trống Chầu"],
	]
	
	for st in stations:
		var pos : Vector2 = st[0]
		
		# 1. Soft floor shadow, kept low so instruments are not framed by dark rings.
		_draw_ellipse_poly(floor_canvas, pos + Vector2(0.0, 16.0), 156.0, 36.0, shadow_col)
		
		# 2. Permanent warm spotlight glow, subtle enough for mobile.
		var halo_a := 0.04 + 0.02 * sin(_time * 1.2)
		_draw_ellipse_line(floor_canvas, pos + Vector2(0.0, 14.0), 180.0, 43.0, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, halo_a), 2.0)
		_draw_ellipse_line(floor_canvas, pos + Vector2(0.0, 14.0), 132.0, 30.0, Color(1.0, 0.95, 0.80, halo_a * 0.8), 1.2)
	
	# 3. Pulsing yellow glow circle when hovering (Soften by 50%)
	if _hovered_station != "":
		var base_pos := Vector2.ZERO
		
		match _hovered_station:
			"tranh":  base_pos = _get_station_floor_center(s_tranh)
			"sao":    base_pos = _get_station_floor_center(s_sao)
			"bau":    base_pos = _get_station_floor_center(s_bau)
			"trong":  base_pos = _get_station_floor_center(s_trong)
		
		if base_pos != Vector2.ZERO:
			var pulse := sin(_time * 7.0)
			_draw_ellipse_line(floor_canvas, base_pos + Vector2(0.0, 14.0), 198.0 + pulse * 5.0, 47.0 + pulse * 2.0,
				Color(C_GOLD_LIGHT.r, C_GOLD_LIGHT.g, C_GOLD_LIGHT.b, 0.22 + 0.06 * pulse), 3.0)
			_draw_ellipse_line(floor_canvas, base_pos + Vector2(0.0, 14.0), 138.0, 31.0,
				Color(1.0, 0.97, 0.90, 0.42), 1.5)

				
	# 5. Draw walking particles
	for p in _walk_particles:
		floor_canvas.draw_circle(p.pos, p.size, p.color)

	# 6. Draw card hover particles
	for p in _card_particles:
		floor_canvas.draw_circle(p.pos, p.initial_size * (p.life / p.max_life), Color(p.color.r, p.color.g, p.color.b, p.color.a * (p.life / p.max_life)))
		var c_alpha : float = p.color.a * (p.life / p.max_life)
		var cross_color := Color(1.0, 0.95, 0.70, c_alpha * 0.45)
		var cross_size : float = p.initial_size * 1.5 * (p.life / p.max_life)
		floor_canvas.draw_line(p.pos - Vector2(cross_size, 0), p.pos + Vector2(cross_size, 0), cross_color, 1.0)
		floor_canvas.draw_line(p.pos - Vector2(0, cross_size), p.pos + Vector2(0, cross_size), cross_color, 1.0)

func _get_sort_y(node: Control) -> float:
	return node.position.y + node.size.y

func _sort_room_elements() -> void:
	var items : Array[Control] = [s_tranh, s_sao, s_bau, s_trong, char_linh]
	if char_player:
		items.append(char_player)
	for c in room_content.get_children():
		if c.name.begins_with("Decor_"):
			items.append(c)
			
	items.sort_custom(func(a, b):
		return _get_sort_y(a) < _get_sort_y(b)
	)
	# FloorCanvas is at index 0, so move other children starting from index 1
	for i in range(items.size()):
		room_content.move_child(items[i], i + 1)

func _draw_instrument_image(c: Button, tex: Texture2D, height_ratio: float = 0.74) -> void:
	var sz := c.size
	var cx := sz.x * 0.5
	var cy := sz.y * 0.5
	var is_hov := c.is_hovered()
	var max_w := sz.x * (1.04 if _is_mobile_layout else 1.02)
	var max_h := sz.y * height_ratio
	var tex_ratio := tex.get_width() / float(tex.get_height())
	var img_w := max_w
	var img_h := img_w / tex_ratio
	if img_h > max_h:
		img_h = max_h
		img_w = img_h * tex_ratio

	var lift := 18.0 if is_hov else 10.0
	var img_rect := Rect2(cx - img_w * 0.5, cy - img_h * 0.5 - lift, img_w, img_h)
	var shadow_w := img_w * 0.78
	var shadow_y := img_rect.position.y + img_h + 14.0
	_draw_ellipse_poly(c, Vector2(cx, shadow_y), shadow_w * 0.5, 11.0, Color(0.0, 0.0, 0.0, 0.18))
	if is_hov:
		_draw_ellipse_line(c, Vector2(cx, shadow_y), shadow_w * 0.58, 14.0, Color(C_GOLD_LIGHT.r, C_GOLD_LIGHT.g, C_GOLD_LIGHT.b, 0.32), 2.0)
		c.draw_texture_rect(tex, img_rect.grow(7.0), false, Color(1.0, 0.86, 0.38, 0.22))
	c.draw_texture_rect(tex, img_rect, false)
	
func _draw_tranh(c: Button) -> void:
	var sz := c.size
	var cx := sz.x * 0.5
	var cy := sz.y * 0.5
	var is_hov := c.is_hovered()
	
	if not _tex_tranh:
		c.draw_line(Vector2(cx - 70, cy + 15), Vector2(cx - 75, cy + 65), Color(0.12, 0.06, 0.03), 6.0)
		c.draw_line(Vector2(cx + 70, cy + 15), Vector2(cx + 75, cy + 65), Color(0.12, 0.06, 0.03), 6.0)
		c.draw_line(Vector2(cx - 75, cy + 60), Vector2(cx + 75, cy + 60), Color(0.10, 0.05, 0.02), 3.5)
	
	if _tex_tranh:
		_draw_instrument_image(c, _tex_tranh, 0.86)
	else:
		# Fallback if texture fails to load (original procedural rendering)
		var zb_pts := PackedVector2Array([
			Vector2(cx - 96, cy - 15),
			Vector2(cx + 96, cy - 19),
			Vector2(cx + 86, cy + 23),
			Vector2(cx - 86, cy + 23)
		])
		
		# Base mahogany color
		c.draw_colored_polygon(zb_pts, Color(0.36, 0.16, 0.07))
		
		# Wood grain lines running along the length of the zither
		for i in range(12):
			var y_off := -14.0 + i * 3.2
			c.draw_line(Vector2(cx - 93, cy + y_off), Vector2(cx + 85, cy + y_off - 2.0), Color(0.22, 0.08, 0.03, 0.45), 1.2)
			
		# Gloss highlight (shiny lacquer) running across the top edge
		c.draw_line(Vector2(cx - 90, cy - 10), Vector2(cx + 80, cy - 14), Color(1, 1, 1, 0.12), 3.0)

		# Gold lacquer plum blossom floral motif in the middle
		c.draw_circle(Vector2(cx, cy + 4), 2.8, C_GOLD)
		for i in range(5):
			var angle := i * (TAU / 5.0)
			c.draw_circle(Vector2(cx, cy + 4) + Vector2(4.5, 0).rotated(angle), 2.0, C_GOLD_LIGHT)
		
		c.draw_polyline(zb_pts, C_GOLD if not is_hov else C_GOLD_LIGHT, 2.0 if not is_hov else 3.8, true)
		
		# White/Cream headpiece & tailpiece representing ivory inserts
		c.draw_rect(Rect2(cx - 96, cy - 15, 14, 36), C_CREAM)
		c.draw_rect(Rect2(cx + 82, cy - 19, 14, 40), C_CREAM)
		
		# Gold filigree bands on ivory tips
		c.draw_rect(Rect2(cx - 84, cy - 15, 2, 36), C_GOLD)
		c.draw_rect(Rect2(cx + 82, cy - 19, 2, 40), C_GOLD)
		
		# Bridges (nhạn đàn) with 3D drop shadows underneath
		for i in range(12):
			var bx := cx - 65 + i * 11
			var by := cy + 1 - (i % 2) * 5
			var br_pts := PackedVector2Array([
				Vector2(bx - 3, by + 4),
				Vector2(bx, by - 2),
				Vector2(bx + 3, by + 4)
			])
			c.draw_colored_polygon(br_pts, C_RED_SON)
			c.draw_circle(Vector2(bx, by - 2), 1.0, C_CREAM)
			
		# Draw Strings (12 fine strings)
		for i in range(12):
			var sy_offset := -10.0 + i * 2.8
			c.draw_line(Vector2(cx - 83, cy + sy_offset), Vector2(cx + 83, cy + sy_offset - 2.0), Color(0.95, 0.95, 0.9, 0.85), 0.8)

func _draw_sao(c: Button) -> void:
	var sz := c.size
	var cx := sz.x * 0.5
	var cy := sz.y * 0.5
	var is_hov := c.is_hovered()
	
	if not _tex_sao:
		c.draw_line(Vector2(cx - 30, cy + 25), Vector2(cx + 30, cy + 25), Color(0.18, 0.10, 0.05), 5.5)
		c.draw_line(Vector2(cx - 20, cy + 25), Vector2(cx - 20, cy + 65), Color(0.18, 0.10, 0.05), 3.5)
		c.draw_line(Vector2(cx + 20, cy + 25), Vector2(cx + 20, cy + 65), Color(0.18, 0.10, 0.05), 3.5)
		c.draw_circle(Vector2(cx - 20, cy + 25), 3.5, C_GOLD)
		c.draw_circle(Vector2(cx + 20, cy + 25), 3.5, C_GOLD)
	
	if _tex_sao:
		_draw_instrument_image(c, _tex_sao, 0.86)
	else:
		# Slanted Bamboo Flute body - Warm Golden Bamboo color (realistic)
		var f_start := Vector2(cx - 90, cy + 10)
		var f_end   := Vector2(cx + 85, cy - 20)
		var bamboo_col := Color(0.85, 0.65, 0.28) # Realistic yellow bamboo
		c.draw_line(f_start, f_end, bamboo_col, 11.0, true)
		
		# Glossy cylindrical reflection sheen
		c.draw_line(f_start - Vector2(0, 2), f_end - Vector2(0, 2), Color(1, 1, 1, 0.35), 3.0, true)
		# Bottom shadow sheen
		c.draw_line(f_start + Vector2(0, 2), f_end + Vector2(0, 2), Color(0.38, 0.22, 0.08, 0.45), 3.5, true)
		
		c.draw_line(f_start, f_end, C_GOLD if not is_hov else C_GOLD_LIGHT, 1.2 if not is_hov else 3.2)
		
		# Bamboo rings/node lines (dark brown thread wrap + node ridge)
		for i in range(6):
			var p := f_start.lerp(f_end, float(i) / 5.0)
			var angle := f_start.angle_to_point(f_end)
			var dir := Vector2(cos(angle + PI/2), sin(angle + PI/2))
			# Brown node line
			c.draw_line(p - dir * 5.2, p + dir * 5.2, Color(0.25, 0.13, 0.05), 3.0)
			c.draw_line(p - dir * 4.0, p + dir * 4.0, C_GOLD_LIGHT, 1.0)
			
		# Red protective thread wraps at the ends (prevent bamboo cracking)
		for side_p in [f_start, f_end]:
			var angle := f_start.angle_to_point(f_end)
			var dir := Vector2(cos(angle + PI/2), sin(angle + PI/2))
			c.draw_line(side_p - dir * 5.0, side_p + dir * 5.0, C_RED_SON, 4.0)
			
		# Finger holes with inner 3D depth shadows
		for i in range(6):
			var p := f_start.lerp(f_end, 0.25 + float(i) * 0.1)
			c.draw_circle(p, 2.5, Color(0.20, 0.12, 0.06))
			c.draw_circle(p, 1.5, Color.BLACK)
			
		# Flowing red silk tassels with realistic knots
		var t_pos := f_start + Vector2(-6, 2)
		c.draw_circle(t_pos, 4.5, C_RED_SON)
		c.draw_line(t_pos, t_pos + Vector2(-12, 22), C_RED_SON, 2.2, true)
		c.draw_line(t_pos + Vector2(-2, 1), t_pos + Vector2(-15, 20), Color(0.95, 0.45, 0.25), 1.2, true)
		c.draw_line(t_pos + Vector2(2, -1), t_pos + Vector2(-8, 24), Color(0.50, 0.05, 0.02), 1.5, true)

func _draw_bau(c: Button) -> void:
	var sz := c.size
	var cx := sz.x * 0.5
	var cy := sz.y * 0.5
	var is_hov := c.is_hovered()
	
	if not _tex_bau:
		c.draw_line(Vector2(cx - 65, cy + 20), Vector2(cx - 70, cy + 65), Color(0.14, 0.08, 0.04), 5.5)
		c.draw_line(Vector2(cx + 65, cy + 20), Vector2(cx + 70, cy + 65), Color(0.14, 0.08, 0.04), 5.5)
	
	if _tex_bau:
		_draw_instrument_image(c, _tex_bau, 0.88)
	else:
		# Monochord Zither Body with tapered profile (tapered mahogany wood)
		# Left end is narrower (where the gourd is), right end is wider
		var zb_pts := PackedVector2Array([
			Vector2(cx - 85, cy - 5), # Left top
			Vector2(cx + 85, cy - 10), # Right top (slightly wider)
			Vector2(cx + 80, cy + 18), # Right bottom
			Vector2(cx - 80, cy + 12)  # Left bottom (narrower)
		])
		
		# Base dark mahogany color
		c.draw_colored_polygon(zb_pts, Color(0.28, 0.13, 0.05))
		
		# Wood grain lines
		for k in range(5):
			var y_off := -2.0 + k * 4.0
			c.draw_line(Vector2(cx - 82, cy + y_off), Vector2(cx + 81, cy + y_off - 2.0), Color(0.16, 0.07, 0.02, 0.50), 1.2)
			
		c.draw_polyline(zb_pts, C_GOLD if not is_hov else C_GOLD_LIGHT, 1.5 if not is_hov else 3.2, true)
		
		# Yellow gourd (Bầu tơ) at the left end (dried gourd shell texture)
		var g_pos := Vector2(cx - 62, cy - 20)
		c.draw_circle(g_pos, 8.5, Color(0.85, 0.60, 0.22)) # Gourd yellow-brown
		c.draw_circle(g_pos + Vector2(-1, -1), 6.5, Color(0.95, 0.75, 0.35)) # Highlight
		c.draw_circle(g_pos + Vector2(0, 8), 12.0, Color(0.85, 0.60, 0.22))
		c.draw_circle(g_pos + Vector2(-2, 6), 9.0, Color(0.95, 0.75, 0.35)) # Highlight
		
		# Flexible rod/handle (Cần đàn) made of glossy black water buffalo horn
		var r_pts := PackedVector2Array([
			g_pos,
			g_pos + Vector2(-8, -26),
			g_pos + Vector2(-24, -34)
		])
		c.draw_polyline(r_pts, Color(0.10, 0.08, 0.08), 4.5, true) # Black horn rod
		c.draw_polyline(r_pts, Color(0.40, 0.40, 0.40, 0.40), 1.5, true) # Specular highlight
		c.draw_circle(g_pos + Vector2(-24, -34), 3.5, C_GOLD)
		
		# Single steel string (nhạc huyền)
		c.draw_line(g_pos + Vector2(-24, -34), Vector2(cx + 74, cy + 2), Color(0.95, 0.95, 0.90, 0.95), 1.5)

func _draw_trong(c: Button) -> void:
	var sz := c.size
	var cx := sz.x * 0.5
	var cy := sz.y * 0.5
	var is_hov := c.is_hovered()
	
	if not _tex_trong:
		c.draw_line(Vector2(cx - 36, cy + 15), Vector2(cx - 56, cy + 65), Color(0.20, 0.12, 0.06), 6.0)
		c.draw_line(Vector2(cx + 36, cy + 15), Vector2(cx + 56, cy + 65), Color(0.20, 0.12, 0.06), 6.0)
		c.draw_line(Vector2(cx - 46, cy + 45), Vector2(cx + 46, cy + 45), Color(0.20, 0.12, 0.06), 4.5)
	
	if _tex_trong:
		_draw_instrument_image(c, _tex_trong, 0.92)
	else:
		# Drum body (Realistic curved barrel staves)
		var dc := Vector2(cx, cy - 4)
		var db_pts := PackedVector2Array()
		var rx := 44.0
		var ry := 30.0
		
		# Draw barrel body with wooden vertical planks / staves
		for step in range(32):
			var a := float(step) * (TAU / float(32))
			db_pts.append(dc + Vector2(cos(a) * rx, sin(a) * ry))
		c.draw_colored_polygon(db_pts, C_RED_SON)
		
		# Draw barrel staves (vertical segments)
		for i in range(1, 8):
			var ratio := float(i) / 8.0
			var sx := -rx + ratio * rx * 2.0
			var sy := sqrt(1.0 - (sx * sx) / (rx * rx)) * ry
			c.draw_line(dc + Vector2(sx, -sy), dc + Vector2(sx, sy), Color(0.32, 0.04, 0.02, 0.50), 1.5)
			
		c.draw_polyline(db_pts, C_GOLD if not is_hov else C_GOLD_LIGHT, 2.5 if not is_hov else 3.8, true)
		
		# Drum skins with concentric rings (aged cowhide leather head)
		var top_pts := PackedVector2Array()
		var trx := 44.0
		var try := 13.0
		var tc := dc - Vector2(0, 13)
		for step in range(32):
			var a := float(step) * (TAU / float(32))
			top_pts.append(tc + Vector2(cos(a) * trx, sin(a) * try))
		c.draw_colored_polygon(top_pts, Color(0.93, 0.85, 0.72)) # Aged leather color
		c.draw_polyline(top_pts, Color(0.75, 0.60, 0.40), 2.0, true)
		
		# Leather head concentric rings
		c.draw_arc(tc, trx * 0.70, 0.0, TAU, 24, Color(0.78, 0.65, 0.48), 1.2)
		c.draw_arc(tc, trx * 0.35, 0.0, TAU, 16, Color(0.70, 0.58, 0.42), 1.5)
		
		# Rivets (đinh tre / đồng đóng xung quanh mặt trống)
		for i in range(9):
			var rx_offset := -36 + i * 9
			c.draw_circle(dc + Vector2(rx_offset, 6), 2.8, C_GOLD)
			c.draw_circle(dc + Vector2(rx_offset - 0.5, 5.0), 1.2, Color.WHITE) # shadow dot
			
		# Drumsticks with wooden texture
		c.draw_line(Vector2(cx - 32, cy + 18), Vector2(cx + 28, cy - 14), Color(0.92, 0.84, 0.72), 3.5, true)
		c.draw_line(Vector2(cx - 32, cy + 18), Vector2(cx - 16, cy + 8), C_GOLD, 3.8, true) # Grip wrapper
		c.draw_line(Vector2(cx + 32, cy + 18), Vector2(cx - 28, cy - 14), Color(0.92, 0.84, 0.72), 3.5, true)
		c.draw_line(Vector2(cx + 32, cy + 18), Vector2(cx + 16, cy + 8), C_GOLD, 3.8, true) # Grip wrapper

func _draw_linh(c: Control) -> void:
	var sz := c.size
	var cx := sz.x * 0.5
	var cy := sz.y * 0.5
	
	# Check if she is speaking
	var is_speaking := false
	if _audio_manager and is_instance_valid(_audio_manager) and _audio_manager.audio_player:
		is_speaking = _audio_manager.audio_player.playing

	# Welcome bow calculation
	var bow_t := clampf((1.6 - _welcome_bow_timer) / 1.6, 0.0, 1.0)
	var bow_tilt := 0.0
	var bow_y := 0.0
	if _welcome_bow_timer > 0.0:
		var bow_phase := sin(bow_t * PI)
		bow_tilt = bow_phase * 0.12 # tilt forward
		bow_y = bow_phase * 15.0 # drop down slightly
		
	# Compute procedural bob, sway (rotation) and squash/stretch scale
	var bob := 0.0
	var rot := bow_tilt
	var scale_vec := Vector2.ONE
	
	if is_speaking:
		bob = bow_y
		rot = bow_tilt
		scale_vec = Vector2.ONE
	else:
		bob = bow_y
		rot = bow_tilt
		scale_vec = Vector2.ONE
		
	# Draw flat feet shadow (before transform so it doesn't move with her)
	var shadow_radius := 28.0 * clampf(1.0 - (bob / 45.0), 0.7, 1.15)
	c.draw_arc(Vector2(cx, cy + 74), shadow_radius, 0, TAU, 16, Color(0, 0, 0, 0.22), 6.0)
	
	# Apply 2D drawing transform centered at the character base (feet)
	var base_pos := Vector2(cx, cy + 74.0)
	c.draw_set_transform(base_pos + Vector2(0.0, bob - 74.0), rot, scale_vec)
	
	var animation_sheet : Texture2D = null
	if _linh_is_moving:
		match _linh_walk_direction:
			"up": animation_sheet = _tex_linh_walk_up
			"left": animation_sheet = _tex_linh_walk_left
			"right": animation_sheet = _tex_linh_walk_right
			"down_left": animation_sheet = _tex_linh_walk_down_left
			"down_right": animation_sheet = _tex_linh_walk_down_right
			"up_left": animation_sheet = _tex_linh_walk_up_left
			"up_right": animation_sheet = _tex_linh_walk_up_right
			_: animation_sheet = _tex_linh_walk_down
	elif is_speaking:
		animation_sheet = _tex_linh_talk

	if animation_sheet:
		_draw_linh_sheet_frame(c, animation_sheet, sz, int(_time * 8.0) % 6)
	elif _tex_linh:
		var img_w := sz.x
		var img_h := sz.y
		var tex_ratio := _tex_linh.get_width() / float(_tex_linh.get_height())
		if tex_ratio > 1.0:
			img_h = sz.x / tex_ratio
		else:
			img_w = sz.y * tex_ratio
		
		# Draw centered relative to the new origin (0.0, 74.0 is feet in local space, so offset is (74.0 - img_h))
		var img_rect := Rect2(-img_w * 0.5, 74.0 - img_h, img_w, img_h)
		c.draw_texture_rect(_tex_linh, img_rect, false)
	else:
		# Draw procedural fallback (relative coordinates shifted by new origin at base_pos)
		# Origin is at (cx, cy + 74), so we subtract cx from X and (cy + 74) from Y
		# 1. Ao Dai Robe (Jade/Teal)
		var body_pts := PackedVector2Array([
			Vector2(-36, -12),
			Vector2(36, -12),
			Vector2(12, -56),
			Vector2(-12, -56)
		])
		c.draw_colored_polygon(body_pts, Color(0.15, 0.56, 0.62))
		c.draw_polyline(body_pts, C_GOLD, 2.0, true)
		c.draw_line(Vector2(-8, -56), Vector2(8, -56), C_GOLD, 3.0)
		
		var head_c := Vector2(0, -86)
		c.draw_circle(head_c, 24.0, C_CREAM)
		c.draw_arc(head_c, 24.0, 0, TAU, 32, C_GOLD, 2.0, true)
		
		var hair_pts := PackedVector2Array([
			head_c + Vector2(-24, -2),
			head_c + Vector2(-22, -18),
			head_c + Vector2(0, -26),
			head_c + Vector2(22, -18),
			head_c + Vector2(24, -2),
			head_c + Vector2(18, -10),
			head_c + Vector2(8, -8),
			head_c + Vector2(0, -14),
			head_c + Vector2(-8, -8),
			head_c + Vector2(-18, -10)
		])
		c.draw_colored_polygon(hair_pts, Color(0.10, 0.08, 0.08))
		
		c.draw_line(head_c + Vector2(-20, -18), head_c + Vector2(20, -18), C_GOLD, 6.0, true)

		c.draw_line(head_c + Vector2(-16, -20), head_c + Vector2(16, -20), C_RED_SON, 2.5, true)
		
		c.draw_circle(head_c + Vector2(-12, 4), 3.0, Color(1.0, 0.5, 0.5, 0.5))
		c.draw_circle(head_c + Vector2(12, 4), 3.0, Color(1.0, 0.5, 0.5, 0.5))
		c.draw_arc(head_c + Vector2(-10, -2), 3.5, PI, TAU, 8, Color.BLACK, 2.0)
		c.draw_arc(head_c + Vector2(10, -2), 3.5, PI, TAU, 8, Color.BLACK, 2.0)
		c.draw_arc(head_c + Vector2(0, 5), 4.5, 0, PI, 8, C_RED_SON, 2.0)


func _draw_linh_sheet_frame(c: Control, sheet: Texture2D, size: Vector2, frame_index: int) -> void:
	# Each Cô Mai sheet is a 3-column × 2-row grid, containing six animation frames.
	var frame_width := sheet.get_width() / 3.0
	var frame_height := sheet.get_height() / 2.0
	var frame := posmod(frame_index, 6)
	var source_rect := Rect2(
		float(frame % 3) * frame_width,
		float(frame / 3) * frame_height,
		frame_width,
		frame_height
	)
	# Keep the same tall visual proportion as the former static illustration.
	var image_height := size.y
	var image_width := image_height * (2.0 / 3.0)
	var destination_rect := Rect2(-image_width * 0.5, 74.0 - image_height, image_width, image_height)
	c.draw_texture_rect_region(sheet, destination_rect, source_rect)

func _draw_capsule(c: Control, p1: Vector2, p2: Vector2, color: Color, width: float) -> void:
	c.draw_line(p1, p2, color, width)
	c.draw_circle(p1, width * 0.5, color)
	c.draw_circle(p2, width * 0.5, color)

func _draw_player(c: Control) -> void:
	var sz := c.size
	var cx := sz.x * 0.5
	var cy := sz.y * 0.5
	
	# Feet shadow (ellipse on the floor)
	c.draw_arc(Vector2(cx, cy + 74), 28.0, 0, TAU, 16, Color(0, 0, 0, 0.22), 6.0)
	
	# Compute walking bob, tilt, scale flip
	var scale_h := 1.0 if _player_facing_right else -1.0
	var tilt := cos(_player_walk_time) * 0.08 if _player_is_moving else 0.0
	var bob := sin(_player_walk_time) * 6.0 if _player_is_moving else 0.0
	
	c.draw_set_transform(Vector2(cx, cy + bob), tilt, Vector2(scale_h, 1.0))
	
	if not FORCE_PROCEDURAL_PLAYER and _tex_player:
		# Draw the 2D pixel art student sprite!
		var img_w := sz.x
		var img_h := sz.y
		var tex_ratio := _tex_player.get_width() / float(_tex_player.get_height())
		if tex_ratio > 1.0:
			img_h = sz.x / tex_ratio
		else:
			img_w = sz.y * tex_ratio
			
		# Position sprite sitting on the shadow (bottom of sprite at y=74)
		var img_rect := Rect2(-img_w * 0.5, 74.0 - img_h, img_w, img_h)
		c.draw_texture_rect(_tex_player, img_rect, false)
	else:
		# Procedural High-Fidelity Fallback with 4-directional poses, expressions & playing poses
		var breath_bob := sin(_idle_breath_time) * 1.5 if not _player_is_moving else 0.0
		
		var is_playing : bool = popup.visible
		var inst : String = _current_popup_instrument
		
		var is_sitting : bool = is_playing and (inst == "tranh" or inst == "bau")
		var is_blowing_flute : bool = is_playing and (inst == "sao")
		var is_drumming : bool = is_playing and (inst == "trong")
		
		var is_walking_up : bool = not is_playing and _player_is_moving and _player_dir.y < -0.5
		
		# If sitting, lower the height center
		var body_cy : float = cy
		if is_sitting:
			body_cy += 12.0
		
		# 1. Legs and Feet (Detailed Trousers and Shoes)
		if is_sitting:
			# Draw folded knees (white traditional trousers style)
			_draw_capsule(c, Vector2(-10, 50 + breath_bob * 0.5), Vector2(-42, 60), Color(0.92, 0.92, 0.90), 22.0)
			_draw_capsule(c, Vector2(10, 50 + breath_bob * 0.5), Vector2(42, 60), Color(0.92, 0.92, 0.90), 22.0)
			
			# Draw shoes peeking out from the sides of the knees
			c.draw_circle(Vector2(-42, 64), 7.5, Color(0.12, 0.12, 0.12))
			c.draw_circle(Vector2(42, 64), 7.5, Color(0.12, 0.12, 0.12))
		else:
			var phase := _player_walk_time
			var leg_swing := sin(phase) if _player_is_moving else 0.0
			var foot_lift_l := maxf(0.0, cos(phase)) * 9.0 if _player_is_moving else 0.0
			var foot_lift_r := maxf(0.0, -cos(phase)) * 9.0 if _player_is_moving else 0.0
			
			var hip_l := Vector2(-15, 50 + breath_bob * 0.5)
			var hip_r := Vector2(15, 50 + breath_bob * 0.5)
			
			var foot_l := Vector2(-15 + leg_swing * 22.0, 78.0 - foot_lift_l)
			var foot_r := Vector2(15 - leg_swing * 22.0, 78.0 - foot_lift_r)
			
			# Draw Trousers (White traditional silk pants)
			c.draw_line(hip_l, foot_l, Color(0.92, 0.92, 0.90), 14.0)
			c.draw_line(hip_r, foot_r, Color(0.92, 0.92, 0.90), 14.0)
			
			# Draw Shoes (Detailed black shoes with white soles)
			for foot_pos in [foot_l, foot_r]:
				c.draw_circle(foot_pos, 8.5, Color(0.12, 0.12, 0.12)) # shoe body
				c.draw_line(foot_pos + Vector2(-8, 5), foot_pos + Vector2(8, 5), Color(0.95, 0.95, 0.92), 2.5) # sole
				
		# 2. Back flap of Ao Dai
		var wind_offset := -15.0 if (_player_is_moving and not is_sitting) else 0.0
		var back_flap_color := Color(0.06, 0.22, 0.52)
		if is_sitting:
			# Flap draped behind the seat
			var back_flap := PackedVector2Array([
				Vector2(-22, 50 + breath_bob * 0.5),
				Vector2(22, 50 + breath_bob * 0.5),
				Vector2(32, 68),
				Vector2(-32, 68)
			])
			c.draw_colored_polygon(back_flap, back_flap_color)
			c.draw_polyline(back_flap, C_GOLD, 1.5, true)
		else:
			var back_flap := PackedVector2Array([
				Vector2(-18, 50 + breath_bob * 0.5),
				Vector2(18, 50 + breath_bob * 0.5),
				Vector2(16 + wind_offset, 76),
				Vector2(-16 + wind_offset, 76)
			])
			c.draw_colored_polygon(back_flap, back_flap_color)
			c.draw_polyline(back_flap, C_GOLD, 1.5, true)
			
		# 3. Torso (Main Ao Dai robe body)
		var body_pts := PackedVector2Array([
			Vector2(-24, 18 + breath_bob),
			Vector2(24, 18 + breath_bob),
			Vector2(18, 52 + breath_bob * 0.5),
			Vector2(-18, 52 + breath_bob * 0.5)
		])
		c.draw_colored_polygon(body_pts, Color(0.08, 0.26, 0.62))
		c.draw_polyline(body_pts, C_GOLD, 2.0, true)
		c.draw_line(Vector2(-8, 18 + breath_bob), Vector2(8, 18 + breath_bob), C_GOLD, 3.0) # collar ring
		
		# 4. Gold lotus embroidery emblem on the chest (Only front view)
		if not is_walking_up:
			var chest_c := Vector2(0, 32 + breath_bob * 0.8)
			c.draw_circle(chest_c, 5.0, C_GOLD)
			c.draw_circle(chest_c, 3.5, C_GOLD_LIGHT)
			c.draw_arc(chest_c + Vector2(-6, 0), 4.0, -PI/2, PI/2, 8, C_GOLD, 1.2)
			c.draw_arc(chest_c + Vector2(6, 0), 4.0, PI/2, 3*PI/2, 8, C_GOLD, 1.2)
			c.draw_line(chest_c, chest_c + Vector2(0, -8), C_GOLD, 1.5)
		
		# 5. Front flap of Ao Dai (flows over the trousers) (Only front view)
		if not is_walking_up:
			if is_sitting:
				var front_flap := PackedVector2Array([
					Vector2(-18, 52 + breath_bob * 0.5),
					Vector2(18, 52 + breath_bob * 0.5),
					Vector2(24, 62),
					Vector2(-24, 62)
				])
				c.draw_colored_polygon(front_flap, Color(0.08, 0.26, 0.62))
				c.draw_polyline(front_flap, C_GOLD, 2.0, true)
			else:
				var front_flap := PackedVector2Array([
					Vector2(-16, 52 + breath_bob * 0.5),
					Vector2(16, 52 + breath_bob * 0.5),
					Vector2(14 + wind_offset, 74),
					Vector2(-14 + wind_offset, 74)
				])
				c.draw_colored_polygon(front_flap, Color(0.08, 0.26, 0.62))
				c.draw_polyline(front_flap, C_GOLD, 2.0, true)
		
		# 6. Khánh ngọc/Tua rua vàng đeo bên hông (Only front view)
		if not is_walking_up:
			var tassel_y := 48.0 + breath_bob * 0.6
			var tassel_base := Vector2(14, tassel_y)
			var tassel_sway := sin(_player_walk_time * 1.5) * 8.0 if (_player_is_moving and not is_sitting) else sin(_time * 2.0) * 2.0
			c.draw_circle(tassel_base, 3.8, C_GOLD)
			c.draw_circle(tassel_base, 2.0, C_JADE)
			c.draw_line(tassel_base, tassel_base + Vector2(tassel_sway, 18.0), C_RED_SON, 2.0)
			c.draw_circle(tassel_base + Vector2(tassel_sway, 18.0), 1.5, C_GOLD)
			
		# 7. Arms and Hands (Alternating swinging, playing, or holding scroll)
		var shoulder_l := Vector2(-22, 20 + breath_bob)
		var shoulder_r := Vector2(22, 20 + breath_bob)
		
		if is_sitting:
			# Sitting pose playing zither/monochord - hands hover and strum
			var hand_l := Vector2(-26, 46 + sin(_time * 5.0) * 3.0)
			var hand_r := Vector2(26, 46 + cos(_time * 5.0) * 3.0)
			
			var elbow_l := shoulder_l.lerp(hand_l, 0.5) + Vector2(-6.0, 3.0)
			var elbow_r := shoulder_r.lerp(hand_r, 0.5) + Vector2(6.0, 3.0)
			
			_draw_capsule(c, shoulder_l, elbow_l, Color(0.08, 0.26, 0.62), 14.0)
			_draw_capsule(c, elbow_l, hand_l, Color(0.08, 0.26, 0.62), 14.0)
			c.draw_line(hand_l - (hand_l - elbow_l).normalized() * 3.0, hand_l, C_GOLD, 15.0)
			c.draw_circle(hand_l, 5.5, C_CREAM)
			
			_draw_capsule(c, shoulder_r, elbow_r, Color(0.08, 0.26, 0.62), 14.0)
			_draw_capsule(c, elbow_r, hand_r, Color(0.08, 0.26, 0.62), 14.0)
			c.draw_line(hand_r - (hand_r - elbow_r).normalized() * 3.0, hand_r, C_GOLD, 15.0)
			c.draw_circle(hand_r, 5.5, C_CREAM)
		elif is_blowing_flute:
			# Standing/sitting blowing bamboo flute - flute drawn slanted near mouth
			var flute_p1 := Vector2(-28, 5)
			var flute_p2 := Vector2(30, -5)
			# Draw the flute
			c.draw_line(flute_p1, flute_p2, Color(0.85, 0.65, 0.28), 7.0, true)
			c.draw_line(flute_p1, flute_p2, C_GOLD, 1.0)
			# Red thread bands
			c.draw_line(flute_p1, flute_p1 + (flute_p2 - flute_p1).normalized() * 4.0, C_RED_SON, 7.2)
			c.draw_line(flute_p2 - (flute_p2 - flute_p1).normalized() * 4.0, flute_p2, C_RED_SON, 7.2)
			
			# Hands raised to touch the flute
			var hand_l := Vector2(-12, 3)
			var hand_r := Vector2(10, 0)
			
			var elbow_l := shoulder_l.lerp(hand_l, 0.5) + Vector2(-8.0, 5.0)
			var elbow_r := shoulder_r.lerp(hand_r, 0.5) + Vector2(8.0, 5.0)
			
			_draw_capsule(c, shoulder_l, elbow_l, Color(0.08, 0.26, 0.62), 14.0)
			_draw_capsule(c, elbow_l, hand_l, Color(0.08, 0.26, 0.62), 14.0)
			c.draw_circle(hand_l, 5.5, C_CREAM)
			
			_draw_capsule(c, shoulder_r, elbow_r, Color(0.08, 0.26, 0.62), 14.0)
			_draw_capsule(c, elbow_r, hand_r, Color(0.08, 0.26, 0.62), 14.0)
			c.draw_circle(hand_r, 5.5, C_CREAM)
		elif is_drumming:
			# Drumming pose holding drumsticks pointing downwards
			var hand_l := Vector2(-18, 46 + sin(_time * 6.0) * 4.0)
			var hand_r := Vector2(18, 46 + cos(_time * 6.0) * 4.0)
			
			var elbow_l := shoulder_l.lerp(hand_l, 0.5) + Vector2(-6.0, 3.0)
			var elbow_r := shoulder_r.lerp(hand_r, 0.5) + Vector2(6.0, 3.0)
			
			_draw_capsule(c, shoulder_l, elbow_l, Color(0.08, 0.26, 0.62), 14.0)
			_draw_capsule(c, elbow_l, hand_l, Color(0.08, 0.26, 0.62), 14.0)
			c.draw_circle(hand_l, 5.5, C_CREAM)
			
			_draw_capsule(c, shoulder_r, elbow_r, Color(0.08, 0.26, 0.62), 14.0)
			_draw_capsule(c, elbow_r, hand_r, Color(0.08, 0.26, 0.62), 14.0)
			c.draw_circle(hand_r, 5.5, C_CREAM)
			
			# Drumsticks (wood color)
			c.draw_line(hand_l, hand_l + Vector2(8, 12), Color(0.92, 0.84, 0.72), 3.0, true)
			c.draw_line(hand_r, hand_r + Vector2(-8, 12), Color(0.92, 0.84, 0.72), 3.0, true)
		elif is_walking_up:
			# Back walk swing
			var phase := _player_walk_time
			var arm_swing := sin(phase)
			var hand_l := Vector2(-26 + arm_swing * 10.0, 42.0 + cos(phase) * 3.0)
			var hand_r := Vector2(26 - arm_swing * 10.0, 42.0 - cos(phase) * 3.0)
			
			var elbow_l := shoulder_l.lerp(hand_l, 0.5) + Vector2(-4.0, 2.0)
			var elbow_r := shoulder_r.lerp(hand_r, 0.5) + Vector2(4.0, 2.0)
			
			_draw_capsule(c, shoulder_l, elbow_l, Color(0.08, 0.26, 0.62), 13.0)
			_draw_capsule(c, elbow_l, hand_l, Color(0.08, 0.26, 0.62), 13.0)
			c.draw_circle(hand_l, 5.0, C_CREAM)
			
			_draw_capsule(c, shoulder_r, elbow_r, Color(0.08, 0.26, 0.62), 13.0)
			_draw_capsule(c, elbow_r, hand_r, Color(0.08, 0.26, 0.62), 13.0)
			c.draw_circle(hand_r, 5.0, C_CREAM)
		else:
			# Front view standard: swing arms when walking, otherwise hold rolled scroll
			if _player_is_moving:
				var phase := _player_walk_time
				var arm_swing := sin(phase)
				var hand_l := Vector2(-36 + arm_swing * 12.0, 42.0 + cos(phase) * 3.0)
				var hand_r := Vector2(36 - arm_swing * 12.0, 42.0 - cos(phase) * 3.0)
				
				var elbow_l := shoulder_l.lerp(hand_l, 0.5) + Vector2(-6.0, 3.0)
				var elbow_r := shoulder_r.lerp(hand_r, 0.5) + Vector2(6.0, 3.0)
				
				_draw_capsule(c, shoulder_l, elbow_l, Color(0.08, 0.26, 0.62), 14.0)
				_draw_capsule(c, elbow_l, hand_l, Color(0.08, 0.26, 0.62), 14.0)
				c.draw_line(hand_l - (hand_l - elbow_l).normalized() * 3.0, hand_l, C_GOLD, 15.0)
				c.draw_circle(hand_l, 5.5, C_CREAM)
				
				_draw_capsule(c, shoulder_r, elbow_r, Color(0.08, 0.26, 0.62), 14.0)
				_draw_capsule(c, elbow_r, hand_r, Color(0.08, 0.26, 0.62), 14.0)
				c.draw_line(hand_r - (hand_r - elbow_r).normalized() * 3.0, hand_r, C_GOLD, 15.0)
				c.draw_circle(hand_r, 5.5, C_CREAM)
			else:
				var hand_l := Vector2(-15, 38 + breath_bob)
				var hand_r := Vector2(15, 38 + breath_bob)
				
				var elbow_l := shoulder_l.lerp(hand_l, 0.5) + Vector2(-5.0, 2.0)
				var elbow_r := shoulder_r.lerp(hand_r, 0.5) + Vector2(5.0, 2.0)
				
				_draw_capsule(c, shoulder_l, elbow_l, Color(0.08, 0.26, 0.62), 14.0)
				_draw_capsule(c, elbow_l, hand_l, Color(0.08, 0.26, 0.62), 14.0)
				
				_draw_capsule(c, shoulder_r, elbow_r, Color(0.08, 0.26, 0.62), 14.0)
				_draw_capsule(c, elbow_r, hand_r, Color(0.08, 0.26, 0.62), 14.0)
				
				c.draw_circle(hand_l, 5.5, C_CREAM)
				c.draw_circle(hand_r, 5.5, C_CREAM)
				
				# Draw Rolled Scroll (Sách nhạc / Cuộn thư cổ)
				var scroll_p1 := Vector2(-24, 40 + breath_bob)
				var scroll_p2 := Vector2(24, 34 + breath_bob)
				c.draw_line(scroll_p1, scroll_p2, C_CREAM, 11.0, true) # roll body
				c.draw_line(scroll_p1, scroll_p2, C_GOLD, 1.2) # borders
				c.draw_circle(Vector2(0, 37 + breath_bob), 5.5, C_RED_SON)
				c.draw_line(Vector2(0, 37 + breath_bob), Vector2(-4, 50 + breath_bob), C_RED_SON, 2.0)
				
		# 8. Head & Turban
		var head_c := Vector2(0, -12 + breath_bob * 1.2)
		var turban_y := head_c.y - 14.0
		var turban_color := Color(0.06, 0.18, 0.45)
		
		if is_walking_up:
			# Draw back of Turban and Neck hair
			c.draw_circle(head_c + Vector2(0, -6), 25.0, turban_color)
			c.draw_circle(head_c + Vector2(0, -12), 20.0, turban_color.darkened(0.15))
			c.draw_arc(head_c + Vector2(0, -6), 25.0, 0, TAU, 32, C_GOLD, 1.5)
			
			var hair_pts := PackedVector2Array([
				head_c + Vector2(-23, 2),
				head_c + Vector2(-18, 16),
				head_c + Vector2(0, 20),
				head_c + Vector2(18, 16),
				head_c + Vector2(23, 2),
				head_c + Vector2(12, 10),
				head_c + Vector2(-12, 10)
			])
			c.draw_colored_polygon(hair_pts, Color.BLACK)
			c.draw_polyline(hair_pts, Color(0.12, 0.12, 0.12), 1.0)
		else:
			# Front Head
			c.draw_circle(head_c, 24.0, C_CREAM)
			c.draw_arc(head_c, 24.0, 0, TAU, 32, C_GOLD, 2.0, true)
			
			# Khăn Đóng (Cross-wrapped turban)
			var wrap1 := PackedVector2Array([
				Vector2(-22, turban_y - 8),
				Vector2(4, turban_y - 2),
				Vector2(4, turban_y - 8),
				Vector2(-22, turban_y - 14)
			])
			c.draw_colored_polygon(wrap1, turban_color)
			c.draw_polyline(wrap1, C_GOLD, 1.0, true)
			
			var wrap2 := PackedVector2Array([
				Vector2(-4, turban_y - 2),
				Vector2(22, turban_y - 8),
				Vector2(22, turban_y - 14),
				Vector2(-4, turban_y - 8)
			])
			c.draw_colored_polygon(wrap2, turban_color.lightened(0.08))
			c.draw_polyline(wrap2, C_GOLD, 1.0, true)
			
			var crown := PackedVector2Array([
				Vector2(-18, turban_y - 14),
				Vector2(18, turban_y - 14),
				Vector2(14, turban_y - 22),
				Vector2(-14, turban_y - 22)
			])
			c.draw_colored_polygon(crown, turban_color.darkened(0.12))
			c.draw_polyline(crown, C_GOLD, 1.2, true)
			
			# Styled Hair (Bangs & sideburns)
			var bang_l := PackedVector2Array([
				head_c + Vector2(-20, -14),
				head_c + Vector2(-10, -14),
				head_c + Vector2(-15, -6)
			])
			c.draw_colored_polygon(bang_l, Color.BLACK)
			
			var bang_r := PackedVector2Array([
				head_c + Vector2(10, -14),
				head_c + Vector2(20, -14),
				head_c + Vector2(15, -6)
			])
			c.draw_colored_polygon(bang_r, Color.BLACK)
			
			c.draw_line(head_c + Vector2(-22, -6), head_c + Vector2(-23, 8), Color.BLACK, 3.0)
			c.draw_line(head_c + Vector2(22, -6), head_c + Vector2(23, 8), Color.BLACK, 3.0)
			
			# Blush cheeks
			c.draw_circle(head_c + Vector2(-12, 4), 3.0, Color(1.0, 0.5, 0.5, 0.45))
			c.draw_circle(head_c + Vector2(12, 4), 3.0, Color(1.0, 0.5, 0.5, 0.45))
			
			# Expressive Eyes based on _player_expression & random blinking
			var eye_l := head_c + Vector2(-9, -2)
			var eye_r := head_c + Vector2(9, -2)
			
			var is_blinking_now := _is_blinking and _player_expression != "sleepy" and _player_expression != "happy"
			
			if is_blinking_now:
				c.draw_arc(eye_l, 4.0, 0, PI, 8, Color(0.1, 0.1, 0.1), 2.0)
				c.draw_arc(eye_r, 4.0, 0, PI, 8, Color(0.1, 0.1, 0.1), 2.0)
			elif _player_expression == "sleepy":
				c.draw_arc(eye_l + Vector2(0, -1), 3.5, 0, PI, 8, Color(0.1, 0.1, 0.1), 2.2)
				c.draw_arc(eye_r + Vector2(0, -1), 3.5, 0, PI, 8, Color(0.1, 0.1, 0.1), 2.2)
				c.draw_line(eye_l + Vector2(-5, -6), eye_l + Vector2(4, -6), Color.BLACK, 1.2)
				c.draw_line(eye_r + Vector2(-4, -6), eye_r + Vector2(5, -6), Color.BLACK, 1.2)
				# yawning mouth
				c.draw_line(head_c + Vector2(0, 4), head_c + Vector2(0, 9), C_RED_SON, 5.0, true)
				c.draw_line(head_c + Vector2(0, 5), head_c + Vector2(0, 8), Color(0.2, 0.05, 0.05), 3.0, true)
			elif _player_expression == "focused":
				c.draw_circle(eye_l, 3.5, Color.BLACK)
				c.draw_circle(eye_l + Vector2(-0.8, -0.8), 0.8, Color.WHITE)
				c.draw_circle(eye_r, 3.5, Color.BLACK)
				c.draw_circle(eye_r + Vector2(-0.8, -0.8), 0.8, Color.WHITE)
				c.draw_line(eye_l + Vector2(-5, -6), eye_l + Vector2(5, -4), Color.BLACK, 1.8)
				c.draw_line(eye_r + Vector2(-5, -4), eye_r + Vector2(5, -6), Color.BLACK, 1.8)
				c.draw_line(head_c + Vector2(-4, 5), head_c + Vector2(4, 5), Color.BLACK, 1.5)
			elif _player_expression == "happy":
				c.draw_arc(eye_l + Vector2(0, 1), 3.5, PI, 2*PI, 8, Color(0.1, 0.1, 0.1), 2.5)
				c.draw_arc(eye_r + Vector2(0, 1), 3.5, PI, 2*PI, 8, Color(0.1, 0.1, 0.1), 2.5)
				c.draw_arc(eye_l + Vector2(0, -4), 4.5, PI, 2*PI, 8, Color.BLACK, 1.2)
				c.draw_arc(eye_r + Vector2(0, -4), 4.5, PI, 2*PI, 8, Color.BLACK, 1.2)
				c.draw_arc(head_c + Vector2(0, 4), 5.5, 0, PI, 8, C_RED_SON, 2.2)
			elif _player_expression == "confused":
				c.draw_circle(eye_l, 4.0, Color.WHITE)
				c.draw_circle(eye_l, 2.2, Color.BLACK)
				c.draw_circle(eye_r, 2.5, Color.BLACK)
				c.draw_line(eye_l + Vector2(-5, -8), eye_l + Vector2(5, -10), Color.BLACK, 1.5)
				c.draw_line(eye_r + Vector2(-5, -4), eye_r + Vector2(5, -6), Color.BLACK, 1.5)
				c.draw_line(head_c + Vector2(-5, 6), head_c + Vector2(-2, 4), Color.BLACK, 1.5)
				c.draw_line(head_c + Vector2(-2, 4), head_c + Vector2(2, 7), Color.BLACK, 1.5)
				c.draw_line(head_c + Vector2(2, 7), head_c + Vector2(5, 5), Color.BLACK, 1.5)
			else:
				c.draw_circle(eye_l, 4.0, Color.WHITE)
				c.draw_circle(eye_l, 2.5, Color(0.1, 0.1, 0.1))
				c.draw_circle(eye_l + Vector2(-1, -1), 1.0, Color.WHITE)
				c.draw_arc(eye_l, 4.5, PI, 2*PI, 8, Color.BLACK, 1.5)
				
				c.draw_circle(eye_r, 4.0, Color.WHITE)
				c.draw_circle(eye_r, 2.5, Color(0.1, 0.1, 0.1))
				c.draw_circle(eye_r + Vector2(-1, -1), 1.0, Color.WHITE)
				c.draw_arc(eye_r, 4.5, PI, 2*PI, 8, Color.BLACK, 1.5)
				
				c.draw_line(eye_l + Vector2(-5, -6), eye_l + Vector2(4, -7), Color.BLACK, 1.2)
				c.draw_line(eye_r + Vector2(-4, -7), eye_r + Vector2(5, -6), Color.BLACK, 1.2)
				
				c.draw_line(head_c + Vector2(0, -2), head_c + Vector2(-1, 3), Color(0.85, 0.76, 0.66), 1.5)
				c.draw_arc(head_c + Vector2(0, 5), 4.5, 0, PI, 8, C_RED_SON, 2.0)


func _setup_dialogue_box() -> void:
	dialogue_box = PanelContainer.new()
	dialogue_box.name = "DialogueBox"
	dialogue_box.visible = false
	$HUD.add_child(dialogue_box)
	
	dialogue_box.custom_minimum_size = Vector2(800, 160)
	dialogue_box.size = Vector2(800, 160)
	dialogue_box.anchors_preset = Control.PRESET_CENTER_BOTTOM
	dialogue_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	dialogue_box.offset_bottom = -32
	dialogue_box.offset_top = -192
	dialogue_box.offset_left = -400
	dialogue_box.offset_right = 400
	
	# Translucent glassmorphic lacquer red stylebox
	var glass_panel := _flat_sb(Color(0.35, 0.05, 0.04, 0.88), C_GOLD, 16, true, 3)
	dialogue_box.add_theme_stylebox_override("panel", glass_panel)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	dialogue_box.add_child(margin)
	
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 24)
	margin.add_child(hbox)
	
	var avatar_control := Control.new()
	avatar_control.name = "Avatar"
	avatar_control.custom_minimum_size = Vector2(100, 100)
	avatar_control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(avatar_control)
	
	avatar_control.draw.connect(func() -> void:
		var sz_act := avatar_control.size
		var center := sz_act * 0.5
		var r_outer := center.x - 2.0
		var r_inner := center.x - 4.0
		avatar_control.draw_circle(center, r_outer, C_GOLD)
		avatar_control.draw_circle(center, r_inner, C_CREAM)
		if _tex_linh:
			var r_w := r_inner * 2.0 * 0.8
			var rect := Rect2(center - Vector2(r_w * 0.5, r_w * 0.5), Vector2(r_w, r_w))
			avatar_control.draw_texture_rect_region(_tex_linh, rect, Rect2(380, 50, 260, 260))
	)
	
	var vbox := VBoxContainer.new()
	vbox.name = "DialogueVBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	hbox.add_child(vbox)
	
	var name_lbl := Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.text = "Cô Mai"
	if _font_body_bold:
		name_lbl.add_theme_font_override("font", _font_body_bold)
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", C_GOLD_LIGHT)
	vbox.add_child(name_lbl)
	
	dialogue_lbl = Label.new()
	dialogue_lbl.name = "DialogueLabel"
	dialogue_lbl.text = "Xin chào học viên!"
	if _font_body:
		dialogue_lbl.add_theme_font_override("font", _font_body)
	dialogue_lbl.add_theme_font_size_override("font_size", 15)
	dialogue_lbl.add_theme_color_override("font_color", C_CREAM)
	dialogue_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	dialogue_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(dialogue_lbl)
	
	btn_dialogue_close = Button.new()
	btn_dialogue_close.name = "CloseButton"
	btn_dialogue_close.text = "TIẾP TỤC"
	btn_dialogue_close.custom_minimum_size = Vector2(120, 36)
	btn_dialogue_close.size_flags_horizontal = Control.SIZE_SHRINK_END
	_style_popup_button(btn_dialogue_close, true)
	_make_btn_bouncy(btn_dialogue_close)
	vbox.add_child(btn_dialogue_close)
	
	btn_dialogue_close.pressed.connect(func() -> void:
		if _typewriter_progress < _typewriter_text.length():
			_typewriter_progress = _typewriter_text.length()
			dialogue_lbl.text = _typewriter_text
		else:
			_close_dialogue()
	)

func _show_dialogue(text: String) -> void:
	if not dialogue_box:
		_setup_dialogue_box()
	var size : Vector2 = get_viewport().get_visible_rect().size
	_player_expression = "focused"
	_typewriter_text = text
	_typewriter_progress = 0.0
	dialogue_lbl.text = ""
	dialogue_box.visible = true
	
	# Compute new dialogue layout and targets
	_update_dialogue_layout(size)
	
	var target_bottom := dialogue_box.offset_bottom
	var target_top := dialogue_box.offset_top
	
	dialogue_box.modulate.a = 0.0
	dialogue_box.offset_bottom = 0
	dialogue_box.offset_top = target_bottom - dialogue_box.size.y
	
	var t := create_tween().set_parallel(true)
	t.tween_property(dialogue_box, "modulate:a", 1.0, 0.25)
	t.tween_property(dialogue_box, "offset_bottom", target_bottom, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(dialogue_box, "offset_top", target_top, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Tween RoomContent scaling down to fit above the dialogue
	var target_layout := _calculate_room_layout(size, true)
	t.tween_property(room_content, "scale", target_layout.scale, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(room_content, "position", target_layout.position, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _close_dialogue() -> void:
	if not dialogue_box or not dialogue_box.visible:
		return
	_player_expression = "happy"
	var t_expr := create_tween()
	t_expr.tween_interval(1.0)
	t_expr.tween_callback(func() -> void:
		if _player_expression == "happy":
			_player_expression = "normal"
	)
	
	var target_top := -dialogue_box.size.y
	var t := create_tween().set_parallel(true)
	t.tween_property(dialogue_box, "modulate:a", 0.0, 0.2)
	t.tween_property(dialogue_box, "offset_bottom", 0, 0.2)
	t.tween_property(dialogue_box, "offset_top", target_top, 0.2)
	
	# Tween RoomContent scaling back to normal
	var size : Vector2 = get_viewport().get_visible_rect().size
	var target_layout := _calculate_room_layout(size, false)
	t.tween_property(room_content, "scale", target_layout.scale, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(room_content, "position", target_layout.position, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	t.chain().tween_callback(func() -> void:
		dialogue_box.visible = false
		_on_viewport_size_changed() # Force alignment check
	)

# ─── Focus Mode Vector Custom Diagrams ─────────────────────────────────────────
func _draw_popup_scroll(c: Control) -> void:
	var sz := c.size
	# 1. Cream paper scroll body with glassmorphic transparency
	var paper_rect := Rect2(40, 30, sz.x - 80, sz.y - 60)
	c.draw_rect(paper_rect, Color(0.99, 0.98, 0.95, 0.72), true)
	c.draw_rect(paper_rect, C_GOLD, false, 3.5)
	
	# Decorative inner border
	c.draw_rect(Rect2(48, 38, sz.x - 96, sz.y - 76), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.28), false, 1.5)
	
	# 2. Wooden rollers at top and bottom
	var roller_col := Color(0.28, 0.16, 0.10)
	c.draw_rect(Rect2(20, 14, sz.x - 40, 20), roller_col, true)
	c.draw_rect(Rect2(20, 14, sz.x - 40, 20), C_GOLD, false, 2.0)
	c.draw_circle(Vector2(20, 24), 10.0, C_GOLD)
	c.draw_circle(Vector2(sz.x - 20, 24), 10.0, C_GOLD)
	
	c.draw_rect(Rect2(20, sz.y - 34, sz.x - 40, 20), roller_col, true)
	c.draw_rect(Rect2(20, sz.y - 34, sz.x - 40, 20), C_GOLD, false, 2.0)
	c.draw_circle(Vector2(20, sz.y - 24), 10.0, C_GOLD)
	c.draw_circle(Vector2(sz.x - 20, sz.y - 24), 10.0, C_GOLD)
	
	# Golden red hanging ribbons
	c.draw_line(Vector2(sz.x * 0.18, 14), Vector2(sz.x * 0.18, 0), C_RED_SON, 3.0)
	c.draw_line(Vector2(sz.x * 0.82, 14), Vector2(sz.x * 0.82, 0), C_RED_SON, 3.0)

func _draw_diagram_theory(c: Control) -> void:
	var sz := c.size
	var cy := sz.y * 0.5
	var font := c.get_theme_font("font")
	
	# Background wash
	c.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.95, 0.93, 0.89, 0.4), true)
	
	if _current_popup_instrument == "tranh":
		# Draw zither board layout
		c.draw_rect(Rect2(40, cy - 20, sz.x - 80, 40), Color(0.38, 0.20, 0.10), true)
		c.draw_rect(Rect2(40, cy - 20, sz.x - 80, 40), C_GOLD, false, 1.5)
		
		# Draw strings + notes labels
		var notes := ["Đô", "Rê", "Mi", "Fa", "Sol", "La", "Si"]
		var notes_lat := ["C3", "D3", "E3", "F3", "G3", "A3", "B3"]
		var start_x := 80.0
		var spacing := (sz.x - 160.0) / 6.0
		
		for i in range(7):
			var sx := start_x + i * spacing
			c.draw_line(Vector2(sx, cy - 18), Vector2(sx, cy + 18), Color(0.95, 0.85, 0.65), 1.8)
			c.draw_circle(Vector2(sx, cy), 3.5, C_RED_SON)
			c.draw_string(font, Vector2(sx - 16, cy - 26), notes[i], HORIZONTAL_ALIGNMENT_CENTER, -1, 14, C_RED_DK)
			c.draw_string(font, Vector2(sx - 16, cy + 34), notes_lat[i], HORIZONTAL_ALIGNMENT_CENTER, -1, 11, C_JADE)
	elif _current_popup_instrument == "sao":
		# Draw bamboo flute
		var start_x := 60.0
		var end_x := sz.x - 60.0
		c.draw_line(Vector2(start_x, cy), Vector2(end_x, cy), C_JADE, 14.0, true)
		
		var holes := ["Đô", "Rê", "Mi", "Fa", "Sol", "La"]
		var holes_lat := ["C4", "D4", "E4", "F4", "G4", "A4"]
		var start_hole := start_x + (end_x - start_x) * 0.25
		var spacing := (end_x - start_x) * 0.11
		
		for i in range(6):
			var hx := start_hole + i * spacing
			c.draw_circle(Vector2(hx, cy), 4.0, Color.BLACK)
			c.draw_string(font, Vector2(hx - 16, cy - 16), holes[i], HORIZONTAL_ALIGNMENT_CENTER, -1, 14, C_RED_DK)
			c.draw_string(font, Vector2(hx - 16, cy + 28), holes_lat[i], HORIZONTAL_ALIGNMENT_CENTER, -1, 11, C_GOLD)
	else:
		# Bookshelf/Leaderboard drawing scrolls
		c.draw_string(font, Vector2(sz.x * 0.5 - 100, cy - 10), "TÀI LIỆU KHÓA HỌC", HORIZONTAL_ALIGNMENT_CENTER, -1, 16, C_RED_DK)
		c.draw_line(Vector2(sz.x * 0.5 - 80, cy + 10), Vector2(sz.x * 0.5 + 80, cy + 10), C_GOLD, 2.0)

func _draw_diagram_fingering(c: Control) -> void:
	var sz := c.size
	var cx := sz.x * 0.5
	var cy := sz.y * 0.5
	var font := c.get_theme_font("font")
	
	c.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.95, 0.93, 0.89, 0.4), true)
	
	if _current_popup_instrument == "tranh":
		c.draw_line(Vector2(cx - 150, cy), Vector2(cx + 150, cy), Color(0.9, 0.9, 0.8), 2.5)
		c.draw_circle(Vector2(cx, cy), 6.0, C_GOLD)
		c.draw_line(Vector2(cx - 30, cy + 40), Vector2(cx, cy + 4), C_RED_SON, 3.0, true)
		c.draw_line(Vector2(cx, cy + 4), Vector2(cx - 10, cy + 12), C_RED_SON, 3.0, true)
		c.draw_line(Vector2(cx, cy + 4), Vector2(cx - 12, cy + 4), C_RED_SON, 3.0, true)
		c.draw_string(font, Vector2(50, cy - 30), "• Hướng gảy: Tay phải gảy hướng vào phía lòng người chơi", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, C_RED_DK)
		c.draw_string(font, Vector2(50, cy - 10), "• Kỹ thuật nhấn: Tay trái ấn nhẹ dây để tạo điệu luyến rung cổ kính", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, C_RED_DK)
	elif _current_popup_instrument == "sao":
		c.draw_line(Vector2(cx - 120, cy), Vector2(cx + 120, cy), C_JADE, 12.0, true)
		for i in range(6):
			var hx := cx - 90 + i * 36
			var cover_col = Color.BLACK if i < 3 else C_CREAM
			c.draw_circle(Vector2(hx, cy), 4.5, cover_col)
			if i >= 3:
				c.draw_circle(Vector2(hx, cy), 4.5, Color.BLACK, false, 1.2)
		c.draw_string(font, Vector2(50, cy - 30), "• Bịt kín lỗ ngón (●) | Để hở lỗ ngón (○)", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, C_RED_DK)
		c.draw_string(font, Vector2(50, cy - 10), "• Đặt môi đều đặn thổi luồng hơi nhẹ nhàng từ bụng lên", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, C_RED_DK)
	else:
		c.draw_string(font, Vector2(sz.x * 0.5 - 100, cy - 10), "HỆ THỐNG PHẦN THƯỞNG", HORIZONTAL_ALIGNMENT_CENTER, -1, 16, C_RED_DK)

func _fade_to(path: String) -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.25)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file(path))

# ─── Responsive Layout ────────────────────────────────────────────────────────
func _calculate_room_layout(size: Vector2, dialogue_visible: bool) -> Dictionary:
	var is_mobile := size.x < size.y or size.x < 768
	var margin_l : float = 8.0 if is_mobile else 0.0
	var margin_r : float = 8.0 if is_mobile else 0.0
	var margin_b : float = 8.0 if is_mobile else 0.0
	
	var room_w : float = float(size.x) - margin_l - margin_r
	var room_h : float = float(size.y) - margin_b
	
	if dialogue_visible:
		var dialog_h := minf(160.0, size.y * (0.35 if is_mobile else 0.28))
		if size.y < 450:
			dialog_h = minf(120.0, size.y * 0.3)
		var margin_b_dialogue := 24.0 if size.y > 500 else 12.0
		room_h -= (dialog_h + margin_b_dialogue + 8.0)
		
	var scale_factor := minf(room_w / 1200.0, room_h / 800.0)
	if is_mobile:
		scale_factor = minf(room_w / 760.0, room_h / 820.0)
		
	return {
		"scale": Vector2(scale_factor, scale_factor),
		"position": Vector2(
			margin_l + (room_w - 1200.0 * scale_factor) / 2.0,
			(room_h - 800.0 * scale_factor) / 2.0
		)
	}

func _update_dialogue_layout(size: Vector2) -> void:
	if not dialogue_box:
		return
	var is_mobile := size.x < size.y or size.x < 768
	var is_compact := is_mobile or size.y < 500
	
	var dialog_w := minf(800.0, size.x - (32.0 if is_mobile else 64.0))
	var dialog_h := minf(160.0, size.y * (0.35 if is_mobile else 0.28))
	if size.y < 450:
		dialog_h = minf(120.0, size.y * 0.3)
	
	dialogue_box.custom_minimum_size = Vector2(dialog_w, dialog_h)
	dialogue_box.size = Vector2(dialog_w, dialog_h)
	
	var margin_b := 24.0 if size.y > 500 else 12.0
	
	if dialogue_box.visible:
		dialogue_box.offset_bottom = -margin_b
		dialogue_box.offset_top = -margin_b - dialog_h
	else:
		dialogue_box.offset_bottom = 0
		dialogue_box.offset_top = -dialog_h
		
	dialogue_box.offset_left = -dialog_w * 0.5
	dialogue_box.offset_right = dialog_w * 0.5
	
	# Responsive child nodes adjustments
	var margin := dialogue_box.get_child(0) as MarginContainer
	if margin:
		var m_val := 12 if is_compact else 24
		var m_top_bottom := 10 if is_compact else 16
		margin.add_theme_constant_override("margin_left", m_val)
		margin.add_theme_constant_override("margin_right", m_val)
		margin.add_theme_constant_override("margin_top", m_top_bottom)
		margin.add_theme_constant_override("margin_bottom", m_top_bottom)
		
		var hbox := margin.get_child(0) as HBoxContainer
		if hbox:
			hbox.add_theme_constant_override("separation", 12 if is_compact else 24)
			
			var avatar := hbox.find_child("Avatar") as Control
			if avatar:
				var av_sz := 64.0 if is_compact else 100.0
				avatar.custom_minimum_size = Vector2(av_sz, av_sz)
				avatar.size = Vector2(av_sz, av_sz)
				avatar.queue_redraw()
				
			var vbox := hbox.find_child("DialogueVBox") as VBoxContainer
			if vbox:
				vbox.add_theme_constant_override("separation", 4 if is_compact else 8)
				var name_lbl := vbox.find_child("NameLabel") as Label
				if name_lbl:
					name_lbl.add_theme_font_size_override("font_size", 14 if is_compact else 18)
				if dialogue_lbl:
					dialogue_lbl.add_theme_font_size_override("font_size", 13 if is_compact else 15)
				var btn_close := vbox.find_child("CloseButton") as Button
				if btn_close:
					btn_close.custom_minimum_size = Vector2(100, 30) if is_compact else Vector2(120, 36)

func _on_viewport_size_changed() -> void:
	var size : Vector2 = get_viewport().get_visible_rect().size
	var is_mobile := size.x < size.y or size.x < 768
	_is_mobile_layout = is_mobile
	
	var layout := _calculate_room_layout(size, dialogue_box != null and dialogue_box.visible)
	room_content.scale = layout.scale
	room_content.position = layout.position
	
	var rx := room_content.position.x
	var scale_factor := room_content.scale.x
	_left_bound = -rx / scale_factor if scale_factor > 0.0 else 0.0
	_right_bound = (size.x - rx) / scale_factor if scale_factor > 0.0 else 1200.0
	var center_x := 600.0

	var station_size := Vector2(360.0, 250.0) if is_mobile else Vector2(360.0, 280.0)
	for station in [s_tranh, s_sao, s_bau, s_trong]:
		station.size = station_size
		station.custom_minimum_size = station_size

	if is_mobile:
		var col_gap := 28.0
		var left_x := center_x - station_size.x - col_gap * 0.5
		var right_x := center_x + col_gap * 0.5
		_station_base_positions["bau"] = Vector2(left_x, 275.0)
		_station_base_positions["trong"] = Vector2(right_x, 275.0)
		_station_base_positions["tranh"] = Vector2(left_x, 515.0)
		_station_base_positions["sao"] = Vector2(right_x, 515.0)
		if not _is_in_intro:
			_linh_base_y = 210.0 # Shift down to avoid scroll text overlap on mobile
			char_linh.position.x = 500.0 - 50.0
			char_linh.size = Vector2(210.0, 210.0) * 3.5
	else:
		# Symmetrical Flat Layout
		_station_base_positions["tranh"] = Vector2(-20.0, 500.0)
		_station_base_positions["bau"] = Vector2(280.0, 500.0)
		_station_base_positions["trong"] = Vector2(580.0, 500.0)
		_station_base_positions["sao"] = Vector2(880.0, 500.0)
		if not _is_in_intro:
			_linh_base_y = 290.0 if not _linh_is_moving else _linh_base_y
			char_linh.position.x = 485.0 - 50.0
			char_linh.size = Vector2(230.0, 230.0) * 1.6

	s_tranh.position = _station_base_positions["tranh"]
	s_sao.position = _station_base_positions["sao"]
	s_bau.position = _station_base_positions["bau"]
	s_trong.position = _station_base_positions["trong"]
	
	# Update popups to match the actual window size
	if popup and is_instance_valid(popup):
		_apply_popup_layout(popup, is_mobile)
			
	if shop_popup and is_instance_valid(shop_popup):
		_apply_popup_layout(shop_popup, is_mobile)
		
	if dialogue_box and is_instance_valid(dialogue_box):
		_update_dialogue_layout(size)

	btn_back.custom_minimum_size = Vector2(48, 48) if is_mobile else Vector2(56, 56)
	btn_back.offset_left = 12.0 if is_mobile else 32.0
	btn_back.offset_top = 12.0 if is_mobile else 32.0
	btn_back.offset_right = btn_back.offset_left + btn_back.custom_minimum_size.x
	btn_back.offset_bottom = btn_back.offset_top + btn_back.custom_minimum_size.y
	_update_hud_hbox_layout(is_mobile)
	_update_hanging_scroll_layout()

func _apply_popup_layout(target_popup: Control, is_mobile: bool) -> void:
	target_popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var viewport_size := get_viewport().get_visible_rect().size
	var panel = target_popup.get_node_or_null("ScrollPanel") as Control
	if not panel:
		return
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	var max_w := 980.0 if target_popup.name == "ShopPopup" else 920.0
	var max_h := 620.0 if target_popup.name == "ShopPopup" else 580.0
	var panel_w := minf(max_w, viewport_size.x - (24.0 if is_mobile else 80.0))
	var panel_h := minf(max_h, viewport_size.y - (24.0 if is_mobile else 80.0))
	panel.size = Vector2(maxf(300.0, panel_w), maxf(300.0 if is_mobile else 480.0, panel_h))
	panel.custom_minimum_size = panel.size
	panel.position = (viewport_size - panel.size) * 0.5
	var content = panel.get_node_or_null("ScrollContent") as Control
	if content:
		var side_margin := 20.0 if is_mobile else 80.0
		var vertical_margin := 28.0 if is_mobile else 54.0
		content.offset_left = side_margin
		content.offset_top = vertical_margin
		content.offset_right = -side_margin
		content.offset_bottom = -vertical_margin
	var tab_hbox = panel.get_node_or_null("ScrollContent/TabHBox") as HBoxContainer
	if tab_hbox:
		tab_hbox.add_theme_constant_override("separation", 8 if is_mobile else 16)
	for button_path in ["ScrollContent/TabHBox/BtnTabTheory", "ScrollContent/TabHBox/BtnTabFingering", "ScrollContent/ButtonHBox/BtnPopupPlay", "ScrollContent/ButtonHBox/BtnPopupClose"]:
		var btn = panel.get_node_or_null(button_path) as Button
		if btn:
			btn.custom_minimum_size = Vector2(132, 40) if is_mobile else Vector2(180, 48)
			btn.add_theme_font_size_override("font_size", 12 if is_mobile else 14)
	var title = panel.get_node_or_null("ScrollContent/PopupTitle") as Label
	if title:
		title.add_theme_font_size_override("font_size", 22 if is_mobile else 28)
	var grid = panel.get_node_or_null("ScrollContent/Grid") as GridContainer
	if grid:
		grid.columns = 1 if is_mobile else 2
		grid.add_theme_constant_override("h_separation", 12 if is_mobile else 24)
		grid.add_theme_constant_override("v_separation", 10 if is_mobile else 16)

func _update_hud_hbox_layout(is_mobile: bool) -> void:
	var hud_hbox = $HUD.get_node_or_null("HUDHBox") as HBoxContainer
	if not hud_hbox:
		return
	hud_hbox.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	hud_hbox.offset_top = 12 if is_mobile else 32
	hud_hbox.offset_right = -12 if is_mobile else -32
	hud_hbox.offset_left = -280 if is_mobile else -340
	hud_hbox.offset_bottom = hud_hbox.offset_top + (42 if is_mobile else 56)
	hud_hbox.add_theme_constant_override("separation", 8 if is_mobile else 16)
	var star_badge = hud_hbox.get_node_or_null("StarBadge") as PanelContainer
	if star_badge:
		star_badge.custom_minimum_size = Vector2(64, 42) if is_mobile else Vector2(100, 48)
		var label = star_badge.get_node_or_null("Margin/Label") as Label
		if label:
			label.add_theme_font_size_override("font_size", 12 if is_mobile else 15)
	var btn_shop = hud_hbox.get_node_or_null("BtnShop") as Button
	if btn_shop:
		btn_shop.custom_minimum_size = Vector2(100, 42) if is_mobile else Vector2(140, 48)

# ─── Styling and Bouncy Helpers ───────────────────────────────────────────────
func _flat_sb(bg: Color, border: Color, radius: int, shadow: bool = false, offset_bottom: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.border_color = border
	s.border_width_left = 3
	s.border_width_right = 3
	s.border_width_top  = 3
	s.border_width_bottom = 3 + offset_bottom
	s.corner_radius_top_left     = radius; s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius; s.corner_radius_bottom_right = radius
	if shadow:
		s.shadow_size = 8
		s.shadow_color = Color(0, 0, 0, 0.2)
		s.shadow_offset = Vector2(0, 4)
	return s

func _make_btn_bouncy(btn: Button) -> void:
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
		btn.scale = Vector2(1.05, 1.05) if btn.is_hovered() else Vector2.ONE
	)


func _fetch_cosmetics_data() -> void:
	if _api_client == null:
		return
	
	if BackendReport.is_signed_in():
		var response = await _api_client.get_all_cosmetics()
		if _api_client._is_success(response):
			_cosmetics_all = response.get("body", {}).get("data", [])
		else:
			_cosmetics_all = []
			
		var my_response = await _api_client.get_my_cosmetics()
		if _api_client._is_success(my_response):
			var body = my_response.get("body", {}).get("data", {})
			_cosmetics_owned = body.get("owned", [])
			_cosmetics_locked = body.get("locked", [])
		else:
			_cosmetics_owned = []
			_cosmetics_locked = []
	else:
		# BYPASS API FOR LOCAL TEST
		_cosmetics_all = []
		_cosmetics_owned = []
		_cosmetics_locked = []
		if _cosmetics_owned.is_empty() and _cosmetics_locked.is_empty():
			var all_mock = [
				{"id": 1, "name": "Chậu sen nhỏ", "assetUrl": "chausen", "unlockValue": 50, "description": "Trang trí phòng nhạc."},
				{"id": 2, "name": "Bàn trà", "assetUrl": "bantra", "unlockValue": 100, "description": "Trang trí phòng nhạc."},
				{"id": 3, "name": "Tranh phong cảnh", "assetUrl": "tranh", "unlockValue": 200, "description": "Trang trí phòng nhạc."},
				{"id": 4, "name": "Quạt treo tường", "assetUrl": "quat", "unlockValue": 150, "description": "Trang trí phòng nhạc."},
				{"id": 5, "name": "Đèn lồng đỏ", "assetUrl": "denlong", "unlockValue": 75, "description": "Trang trí phòng nhạc."},
				{"id": 6, "name": "Đèn đá Nhật", "assetUrl": "denda", "unlockValue": 120, "description": "Trang trí phòng nhạc."},
				{"id": 7, "name": "Chuông gió", "assetUrl": "chuonggio", "unlockValue": 80, "description": "Trang trí phòng nhạc."},
				{"id": 8, "name": "Bình sen lớn", "assetUrl": "binhsen", "unlockValue": 90, "description": "Trang trí phòng nhạc."}
			]
			var unlocked = SecureDataManager.data.get("unlocked_decorations", [])
			var active = SecureDataManager.data.get("active_decorations", [])
			for m_item in all_mock:
				var m_key = _get_draw_key(m_item)
				if unlocked.has(m_key):
					m_item["isEquipped"] = active.has(m_key)
					_cosmetics_owned.append(m_item)
				else:
					_cosmetics_locked.append(m_item)
		
	# Spawn lại các vật phẩm trang bị thực tế từ API và cập nhật shop
	_spawn_decorations()
	if shop_popup and shop_popup.visible:
		_update_shop_items()

func _get_draw_key(item: Dictionary) -> String:
	var asset_url := str(item.get("assetUrl", "")).to_lower()
	var item_name := str(item.get("name", "")).to_lower()
	
	if "chausen" in asset_url: return "chausen"
	elif "bantra" in asset_url: return "bantra"
	elif "tranh" in asset_url: return "tranh"
	elif "quat" in asset_url: return "quat"
	elif "denlong" in asset_url: return "denlong"
	elif "denda" in asset_url: return "denda"
	elif "chuonggio" in asset_url: return "chuonggio"
	elif "binhsen" in asset_url: return "binhsen"
	
	if "chau sen" in item_name or "chậu sen" in item_name: return "chausen"
	elif "ban tra" in item_name or "bàn trà" in item_name: return "bantra"
	elif "quat" in item_name or "quạt" in item_name: return "quat"
	elif "den long" in item_name or "đèn lồng" in item_name: return "denlong"
	elif "den da" in item_name or "đèn đá" in item_name: return "denda"
	elif "chuong gio" in item_name or "chuông gió" in item_name: return "chuonggio"
	elif "binh sen" in item_name or "bình sen" in item_name: return "binhsen"
	elif "painting" in asset_url or "painting" in item_name or "tranh" in item_name:
		return "tranh"
	elif "vase" in asset_url or "vase" in item_name or "bình" in item_name or "hoa" in item_name:
		return "binhsen"
	elif "bamboo" in asset_url or "bamboo" in item_name or "trúc" in item_name:
		return "chausen"
	elif "drum" in asset_url or "drum" in item_name or "trống" in item_name:
		return "bantra"
	return "tranh"

func _fetch_instruments_data() -> void:
	if _api_client == null:
		return
	var response = await _api_client.get_instruments()
	if _api_client._is_success(response):
		var list = response.get("body", {}).get("data", [])
		for item in list:
			var code = _get_instrument_code_mapping(item.get("instrumentCode", ""))
			if code != "":
				_instruments_data[code] = {
					"name": item.get("name", _instruments_data[code]["name"]),
					"desc": item.get("description", _instruments_data[code]["desc"])
				}

func _get_instrument_code_mapping(api_code: String) -> String:
	var c = api_code.to_lower()
	if "tranh" in c:
		return "tranh"
	elif "sao" in c:
		return "sao"
	elif "bau" in c:
		return "bau"
	elif "trong" in c:
		return "trong"
	return ""

# ─── Decoration Shop & Reward Helpers ──────────────────────────────────────────

func _setup_hud_shop_button() -> void:
	# Create a clean, non-overlapping HBoxContainer for top-right HUD controls
	var hud_hbox := HBoxContainer.new()
	hud_hbox.name = "HUDHBox"
	$HUD.add_child(hud_hbox)
	hud_hbox.layout_mode = 1
	hud_hbox.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	hud_hbox.offset_left = -380
	hud_hbox.offset_top = 32
	hud_hbox.offset_right = -32
	hud_hbox.offset_bottom = 32 + 48
	hud_hbox.alignment = BoxContainer.ALIGNMENT_END
	hud_hbox.add_theme_constant_override("separation", 16)

	var blur_shader := Shader.new()
	blur_shader.code = """
	shader_type canvas_item;
	uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
	uniform float lod: hint_range(0.0, 5.0) = 2.0;
	void fragment() {
		COLOR = textureLod(screen_texture, SCREEN_UV, lod);
	}
	"""
	
	# Create Star Badge
	var star_badge := PanelContainer.new()
	star_badge.name = "StarBadge"
	star_badge.custom_minimum_size = Vector2(100, 48)
	hud_hbox.add_child(star_badge)
	
	var badge_blur_rect := ColorRect.new()
	badge_blur_rect.material = ShaderMaterial.new()
	badge_blur_rect.material.shader = blur_shader
	badge_blur_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	badge_blur_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_blur_rect.show_behind_parent = true
	star_badge.add_child(badge_blur_rect)
	
	var badge_s := StyleBoxFlat.new()
	badge_s.bg_color = Color(0.95, 0.93, 0.89, 0.65) # Glassmorphic lacquer warm ivory
	badge_s.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45) # Soft gold border
	badge_s.border_width_left = 2; badge_s.border_width_right = 2
	badge_s.border_width_top = 2; badge_s.border_width_bottom = 2
	badge_s.corner_radius_top_left = 24; badge_s.corner_radius_top_right = 24
	badge_s.corner_radius_bottom_left = 24; badge_s.corner_radius_bottom_right = 24
	badge_s.shadow_size = 6
	badge_s.shadow_color = Color(0.13, 0.08, 0.05, 0.12)
	star_badge.add_theme_stylebox_override("panel", badge_s)
	
	var badge_margin := MarginContainer.new()
	badge_margin.name = "Margin"
	badge_margin.add_theme_constant_override("margin_left", 12)
	badge_margin.add_theme_constant_override("margin_right", 16)
	star_badge.add_child(badge_margin)
	
	var badge_hbox := HBoxContainer.new()
	badge_hbox.add_theme_constant_override("separation", 6)
	badge_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	badge_margin.add_child(badge_hbox)
	
	var badge_icon := TextureRect.new()
	badge_icon.texture = load("res://assets/textures/lucide/star.svg") as Texture2D
	badge_icon.custom_minimum_size = Vector2(20, 20)
	badge_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	badge_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	badge_icon.modulate = C_GOLD
	badge_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge_hbox.add_child(badge_icon)
	
	var badge_label := Label.new()
	badge_label.name = "Label"
	badge_label.text = "%d" % SecureDataManager.get_total_stars()
	badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge_label.add_theme_font_size_override("font_size", 16)
	badge_label.add_theme_color_override("font_color", Color(0.13, 0.08, 0.05, 1.0))
	if _font_body_bold:
		badge_label.add_theme_font_override("font", _font_body_bold)
	badge_hbox.add_child(badge_label)

	# Create Shop Button (Text-only, Frosted Glass)
	var btn_shop := Button.new()
	btn_shop.name = "BtnShop"
	btn_shop.text = "Cửa hàng"
	btn_shop.custom_minimum_size = Vector2(130, 48)
	btn_shop.add_theme_font_size_override("font_size", 16)
	if _font_body_bold:
		btn_shop.add_theme_font_override("font", _font_body_bold)
	btn_shop.add_theme_color_override("font_color", C_JADE)
	btn_shop.add_theme_color_override("font_hover_color", Color(0.13, 0.08, 0.05, 1.0))
	btn_shop.add_theme_color_override("font_pressed_color", C_JADE)
	
	var btn_blur_rect := ColorRect.new()
	btn_blur_rect.material = ShaderMaterial.new()
	btn_blur_rect.material.shader = blur_shader
	btn_blur_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn_blur_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn_blur_rect.show_behind_parent = true
	btn_shop.add_child(btn_blur_rect)
	
	var btn_s := StyleBoxFlat.new()
	btn_s.bg_color = Color(0.95, 0.93, 0.89, 0.65) # Glassmorphic warm ivory
	btn_s.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45)
	btn_s.border_width_left = 2; btn_s.border_width_right = 2
	btn_s.border_width_top = 2; btn_s.border_width_bottom = 2
	btn_s.corner_radius_top_left = 24; btn_s.corner_radius_top_right = 24
	btn_s.corner_radius_bottom_left = 24; btn_s.corner_radius_bottom_right = 24
	btn_s.shadow_size = 8
	btn_s.shadow_color = Color(0.13, 0.08, 0.05, 0.12)
	btn_shop.add_theme_stylebox_override("normal", btn_s)
	
	var btn_h := btn_s.duplicate() as StyleBoxFlat
	btn_h.bg_color = Color(1.0, 0.98, 0.94, 0.85)
	btn_h.border_color = C_GOLD
	btn_shop.add_theme_stylebox_override("hover", btn_h)

	var btn_p := btn_s.duplicate() as StyleBoxFlat
	btn_p.bg_color = Color(0.90, 0.88, 0.84, 0.85)
	btn_p.border_color = C_JADE
	btn_shop.add_theme_stylebox_override("pressed", btn_p)
	btn_shop.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	hud_hbox.add_child(btn_shop)
	hud_hbox.move_child(btn_shop, 0)
	
	_make_btn_bouncy(btn_shop)
	btn_shop.pressed.connect(_open_shop_popup)

func _update_star_badge() -> void:
	var label = $HUD.get_node_or_null("HUDHBox/StarBadge/Margin/HBoxContainer/Label") as Label
	if not label:
		label = $HUD.get_node_or_null("HUDHBox/StarBadge/Margin/Label") as Label
	if label:
		label.text = "%d" % SecureDataManager.get_total_stars()

func _spawn_decorations() -> void:
	# Clear old decorations first
	for c in room_content.get_children():
		if "Decor_" in c.name:
			room_content.remove_child(c)
			c.queue_free()
			
	for item in _cosmetics_owned:
		if item.get("isEquipped", false):
			var item_id = _get_draw_key(item)
			var ctrl := Control.new()
			ctrl.name = "Decor_" + str(item.get("id"))
			ctrl.mouse_filter = Control.MOUSE_FILTER_STOP
			ctrl.gui_input.connect(_on_decor_gui_input.bind(ctrl, item_id))
			
			var saved_positions = SecureDataManager.data.get("decor_positions", {})
			var has_saved = saved_positions.has(item_id)
			
			# Define sizes and positions for room layout
			match item_id:
				"chausen":
					ctrl.position = Vector2(65, 469)
					ctrl.size = Vector2(200, 200)
				"bantra":
					ctrl.position = Vector2(899, 512)
					ctrl.size = Vector2(250, 200)
				"tranh":
					ctrl.position = Vector2(60, 180)
					ctrl.size = Vector2(300, 200)
				"quat":
					ctrl.position = Vector2(850, 180)
					ctrl.size = Vector2(300, 200)
				"denlong":
					ctrl.position = Vector2(130, -20)
					ctrl.size = Vector2(150, 250)
				"denda":
					ctrl.position = Vector2(40, 610)
					ctrl.size = Vector2(120, 200)
				"chuonggio":
					ctrl.position = Vector2(920, -20)
					ctrl.size = Vector2(150, 250)
				"binhsen":
					ctrl.position = Vector2(1080, 400)
					ctrl.size = Vector2(120, 250)
				_:
					ctrl.position = Vector2(0, 0)
					ctrl.size = Vector2(100, 100)
					
			if has_saved:
				var pos = saved_positions[item_id]
				ctrl.position = Vector2(pos.x, pos.y)
				
			ctrl.pivot_offset = ctrl.size / 2.0
			room_content.add_child(ctrl)
			ctrl.draw.connect(_draw_decor_node.bind(ctrl, item_id, false))
	
	_sort_room_elements()

func _on_decor_gui_input(event: InputEvent, ctrl: Control, item_id: String) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_pressed_decor = ctrl
				_press_start_pos = event.global_position
				
				if _press_timer_tween and _press_timer_tween.is_valid():
					_press_timer_tween.kill()
				
				_press_timer_tween = create_tween()
				_press_timer_tween.tween_property(ctrl, "scale", Vector2(1.1, 1.1), 0.4).set_trans(Tween.TRANS_SINE)
				_press_timer_tween.tween_callback(func():
					_dragged_decor = ctrl
					# Calculate offset based on scaled size to prevent jumping
					var scaled_global = ctrl.global_position + ctrl.pivot_offset - (ctrl.pivot_offset * 1.1)
					_drag_offset = event.global_position - scaled_global
					var t = create_tween()
					t.tween_property(ctrl, "scale", Vector2(1.15, 1.15), 0.1)
					t.tween_property(ctrl, "scale", Vector2(1.1, 1.1), 0.1)
				)
			else:
				if _press_timer_tween and _press_timer_tween.is_valid():
					_press_timer_tween.kill()
					_press_timer_tween = null
					
				if _dragged_decor == ctrl:
					_dragged_decor = null
					var t = create_tween()
					t.tween_property(ctrl, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BOUNCE)
					if not SecureDataManager.data.has("decor_positions"):
						SecureDataManager.data["decor_positions"] = {}
					SecureDataManager.data["decor_positions"][item_id] = {"x": ctrl.position.x, "y": ctrl.position.y}
					SecureDataManager.save_data()
				elif _pressed_decor == ctrl:
					var t = create_tween()
					t.tween_property(ctrl, "scale", Vector2(1.0, 1.0), 0.1)
				
				_pressed_decor = null
					
	elif event is InputEventMouseMotion:
		if _dragged_decor == ctrl:
			var new_pos = event.global_position - _drag_offset
			var vp_size = get_viewport().get_visible_rect().size
			# Account for scaling in clamps
			var scaled_size = ctrl.size * ctrl.scale
			new_pos.x = clamp(new_pos.x, ctrl.pivot_offset.x * (1.0 - ctrl.scale.x), vp_size.x - scaled_size.x + ctrl.pivot_offset.x * (1.0 - ctrl.scale.x))
			new_pos.y = clamp(new_pos.y, ctrl.pivot_offset.y * (1.0 - ctrl.scale.y), vp_size.y - scaled_size.y + ctrl.pivot_offset.y * (1.0 - ctrl.scale.y))
			
			ctrl.global_position = new_pos
			_sort_room_elements()
		elif _pressed_decor == ctrl:
			if event.global_position.distance_to(_press_start_pos) > 10.0:
				if _press_timer_tween and _press_timer_tween.is_valid():
					_press_timer_tween.kill()
					_press_timer_tween = null
				_pressed_decor = null
				var t = create_tween()
				t.tween_property(ctrl, "scale", Vector2(1.0, 1.0), 0.1)

func _draw_decor_node(c: Control, item_id: String, in_shop: bool = false) -> void:
	var scale := 1.0
	if item_id == "bronze_drum" and not in_shop:
		scale = 3.5
	_draw_decor_item(c, item_id, scale)

func _draw_ellipse_poly(c: Control, center: Vector2, radius_x: float, radius_y: float, color: Color) -> void:
	var pts := PackedVector2Array()
	var steps := 24
	for i in range(steps):
		var angle = float(i) * TAU / steps
		pts.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	c.draw_colored_polygon(pts, color)

func _draw_ellipse_line(c: Control, center: Vector2, radius_x: float, radius_y: float, color: Color, width: float = 1.0) -> void:
	var pts := PackedVector2Array()
	var steps := 24
	for i in range(steps + 1):
		var angle = float(i) * TAU / steps
		pts.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	c.draw_polyline(pts, color, width, true)

func _load_decor_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _draw_decor_item(c: Control, item_id: String, size_scale: float = 1.0) -> void:
	var sz := c.size
	var tex: Texture2D = null
	match item_id:
		"chausen": tex = _tex_decor_chausen
		"bantra": tex = _tex_decor_bantra
		"tranh": tex = _tex_decor_tranh
		"quat": tex = _tex_decor_quat
		"denlong": tex = _tex_decor_denlong
		"denda": tex = _tex_decor_denda
		"chuonggio": tex = _tex_decor_chuonggio
		"binhsen": tex = _tex_decor_binhsen
	if tex:
		var tex_size = tex.get_size()
		var scale_x = sz.x / tex_size.x
		var scale_y = sz.y / tex_size.y
		var final_scale = min(scale_x, scale_y) * size_scale
		var w = tex_size.x * final_scale
		var h = tex_size.y * final_scale
		var rect = Rect2((sz.x - w) / 2.0, (sz.y - h) / 2.0, w, h)
		c.draw_texture_rect(tex, rect, false)

func _open_shop_popup() -> void:
	if not shop_popup:
		_setup_shop_popup()
	_update_shop_items()
	_apply_popup_layout(shop_popup, _is_mobile_layout)
	_player_expression = "focused"
	shop_popup.visible = true
	shop_popup.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(shop_popup, "modulate:a", 1.0, 0.22)

func _setup_shop_popup() -> void:
	shop_popup = Control.new()
	shop_popup.name = "ShopPopup"
	$HUD.add_child(shop_popup)
	shop_popup.layout_mode = 1
	shop_popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var overlay := ColorRect.new()
	overlay.name = "OverlayBG"
	overlay.color = Color(0.06, 0.04, 0.02, 0.55) # Lighter overlay for better glass blur visual contrast
	shop_popup.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var blur_shader := Shader.new()
	blur_shader.code = """
	shader_type canvas_item;
	uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
	uniform float lod: hint_range(0.0, 5.0) = 2.0;
	void fragment() {
		COLOR = textureLod(screen_texture, SCREEN_UV, lod);
	}
	"""
	
	# Full screen frosted glass behind the scroll panel
	var popup_blur := ColorRect.new()
	popup_blur.material = ShaderMaterial.new()
	popup_blur.material.shader = blur_shader
	popup_blur.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup_blur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shop_popup.add_child(popup_blur)
	
	var scroll_panel := Control.new()
	scroll_panel.name = "ScrollPanel"
	scroll_panel.custom_minimum_size = Vector2(920, 580)
	scroll_panel.size = Vector2(920, 580)
	shop_popup.add_child(scroll_panel)
	scroll_panel.layout_mode = 1
	scroll_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	scroll_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	scroll_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	
	var scroll_draw := Control.new()
	scroll_draw.name = "ScrollDraw"
	scroll_panel.add_child(scroll_draw)
	scroll_draw.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll_draw.draw.connect(_draw_popup_scroll.bind(scroll_draw))
	
	var scroll_content := VBoxContainer.new()
	scroll_content.name = "ScrollContent"
	scroll_panel.add_child(scroll_content)
	scroll_content.layout_mode = 1
	scroll_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll_content.offset_left = 80
	scroll_content.offset_top = 54
	scroll_content.offset_right = -80
	scroll_content.offset_bottom = -54
	scroll_content.add_theme_constant_override("separation", 14)
	
	var title_hbox := HBoxContainer.new()
	title_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	title_hbox.add_theme_constant_override("separation", 10)
	scroll_content.add_child(title_hbox)

	var title := Label.new()
	title.text = "CỬA HÀNG TRANG TRÍ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", C_JADE)
	if _font_title:
		title.add_theme_font_override("font", _font_title)
	title_hbox.add_child(title)
	
	var stars_container := HBoxContainer.new()
	stars_container.name = "StarsContainer"
	stars_container.alignment = BoxContainer.ALIGNMENT_CENTER
	stars_container.add_theme_constant_override("separation", 8)
	scroll_content.add_child(stars_container)
	
	var prefix_label := Label.new()
	prefix_label.text = "Bạn có: "
	prefix_label.add_theme_font_size_override("font_size", 14)
	prefix_label.add_theme_color_override("font_color", C_GOLD)
	if _font_body_bold:
		prefix_label.add_theme_font_override("font", _font_body_bold)
	stars_container.add_child(prefix_label)
	
	var star_icon := TextureRect.new()
	star_icon.texture = load("res://assets/textures/lucide/star.svg") as Texture2D
	star_icon.custom_minimum_size = Vector2(18, 18)
	star_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	star_icon.modulate = C_GOLD
	star_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stars_container.add_child(star_icon)
	
	var stars_val_label := Label.new()
	stars_val_label.name = "StarsValLabel"
	stars_val_label.text = "%d Sao" % SecureDataManager.get_total_stars()
	stars_val_label.add_theme_font_size_override("font_size", 14)
	stars_val_label.add_theme_color_override("font_color", C_GOLD)
	if _font_body_bold:
		stars_val_label.add_theme_font_override("font", _font_body_bold)
	stars_container.add_child(stars_val_label)
	
	var shop_scroll := ScrollContainer.new()
	shop_scroll.name = "ShopScroll"
	shop_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shop_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_content.add_child(shop_scroll)
	
	var grid := GridContainer.new()
	grid.name = "Grid"
	grid.columns = 2
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	shop_scroll.add_child(grid)
	
	var btn_close := Button.new()
	btn_close.text = "ĐÓNG"
	btn_close.custom_minimum_size = Vector2(180, 44)
	btn_close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if _font_body_bold:
		btn_close.add_theme_font_override("font", _font_body_bold)
	_style_outline_btn(btn_close)
	_make_btn_bouncy(btn_close)
	scroll_content.add_child(btn_close)
	
	btn_close.pressed.connect(func() -> void:
		_player_expression = "normal"
		var t := create_tween()
		t.tween_property(shop_popup, "modulate:a", 0.0, 0.2)
		t.tween_callback(func() -> void: shop_popup.visible = false)
	)

func _on_shop_action_pressed(item: Dictionary, owned: bool) -> void:
	var cosmetic_id = int(item.get("id", 0))
	if cosmetic_id == 0:
		return
	
	if not owned:
		var success = false
		var cost = int(item.get("unlockValue", 0))
		var item_key = _get_draw_key(item)
		if SecureDataManager.unlock_decoration(item_key, cost):
			if SecureDataManager.data.has("stars") and SecureDataManager.data["stars"].has("test"):
				SecureDataManager.data["stars"]["test"]["free"] = max(0, SecureDataManager.data["stars"]["test"]["free"] - cost)
				SecureDataManager.save_data()
			success = true
		if success:
			_card_particle_timer = 999.0
			_player_expression = "happy"
			get_tree().create_timer(1.2).timeout.connect(func(): _player_expression = "normal")
			_update_star_badge()
			_fetch_cosmetics_data()
			_update_shop_items()
	else:
		var is_equipped = item.get("isEquipped", false)
		var item_key = _get_draw_key(item)
		if not is_equipped:
			if not SecureDataManager.data.has("active_decorations"):
				SecureDataManager.data["active_decorations"] = []
			if not SecureDataManager.data["active_decorations"].has(item_key):
				SecureDataManager.data["active_decorations"].append(item_key)
		else:
			if SecureDataManager.data.has("active_decorations"):
				SecureDataManager.data["active_decorations"].erase(item_key)
		SecureDataManager.save_data()
		_fetch_cosmetics_data()
		_update_shop_items()

func _update_shop_items() -> void:
	if SecureDataManager.get_total_stars() < 9999:
		if not SecureDataManager.data.has("stars"):
			SecureDataManager.data["stars"] = {}
		if not SecureDataManager.data["stars"].has("test"):
			SecureDataManager.data["stars"]["test"] = {}
		SecureDataManager.data["stars"]["test"]["free"] = 9999
		SecureDataManager.save_data()
	
	var stars = SecureDataManager.get_total_stars()
	var stars_val_label = shop_popup.get_node_or_null("ScrollPanel/ScrollContent/StarsContainer/StarsValLabel") as Label
	if stars_val_label:
		stars_val_label.text = "%d Sao" % stars
		
	var grid = shop_popup.get_node("ScrollPanel/ScrollContent/ShopScroll/Grid") as GridContainer
	if not grid:
		return
	
	# Xóa các thẻ bài cũ
	for c in grid.get_children():
		c.queue_free()
		
	# 1. Vẽ các vật phẩm đã sở hữu
	for item in _cosmetics_owned:
		var card = _create_shop_card(item, true, stars)
		grid.add_child(card)
		
	# 2. Vẽ các vật phẩm chưa sở hữu
	for item in _cosmetics_locked:
		var card = _create_shop_card(item, false, stars)
		grid.add_child(card)

func _create_shop_card(item: Dictionary, owned: bool, stars: int) -> PanelContainer:
	var item_id = _get_draw_key(item)
	var name = item.get("name", "Vật phẩm")
	var cost = int(item.get("unlockValue", 3))
	var desc = item.get("description", "Vật phẩm trang trí cho phòng nhạc.")
	
	var card := PanelContainer.new()
	card.name = "Card_" + str(item.get("id"))
	card.custom_minimum_size = Vector2(380, 160)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.99, 0.98, 0.96, 0.96) # Clean warm ivory card
	sb.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.40) # Soft refined gold border
	sb.border_width_left = 2; sb.border_width_right = 2
	sb.border_width_top = 2; sb.border_width_bottom = 2
	sb.corner_radius_top_left = 18; sb.corner_radius_top_right = 18
	sb.corner_radius_bottom_left = 18; sb.corner_radius_bottom_right = 18
	sb.shadow_size = 8
	sb.shadow_color = Color(0.13, 0.08, 0.05, 0.08)
	sb.shadow_offset = Vector2(0, 3)
	card.add_theme_stylebox_override("panel", sb)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)
	
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	margin.add_child(hbox)
	
	var preview := TextureRect.new()
	preview.custom_minimum_size = Vector2(90, 110)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(preview)
	
	var tex: Texture2D = null
	match item_id:
		"chausen": tex = _tex_decor_chausen
		"bantra": tex = _tex_decor_bantra
		"tranh": tex = _tex_decor_tranh
		"quat": tex = _tex_decor_quat
		"denlong": tex = _tex_decor_denlong
		"denda": tex = _tex_decor_denda
		"chuonggio": tex = _tex_decor_chuonggio
		"binhsen": tex = _tex_decor_binhsen
		
	if tex != null:
		preview.texture = tex
	else:
		preview.draw.connect(_draw_decor_node.bind(preview, item_id, true))
	
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	hbox.add_child(vbox)
	
	var name_lbl := Label.new()
	name_lbl.text = name
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.add_theme_color_override("font_color", C_JADE)
	if _font_body_bold:
		name_lbl.add_theme_font_override("font", _font_body_bold)
	vbox.add_child(name_lbl)
	
	var cost_hbox := HBoxContainer.new()
	cost_hbox.add_theme_constant_override("separation", 6)
	vbox.add_child(cost_hbox)
	
	var req_lbl := Label.new()
	req_lbl.text = "Yêu cầu: "
	req_lbl.add_theme_font_size_override("font_size", 13)
	req_lbl.add_theme_color_override("font_color", C_GOLD)
	if _font_body_bold:
		req_lbl.add_theme_font_override("font", _font_body_bold)
	cost_hbox.add_child(req_lbl)
	
	var req_star_icon := TextureRect.new()
	req_star_icon.texture = load("res://assets/textures/lucide/star.svg") as Texture2D
	req_star_icon.custom_minimum_size = Vector2(16, 16)
	req_star_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	req_star_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	req_star_icon.modulate = C_GOLD
	req_star_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cost_hbox.add_child(req_star_icon)
	
	var cost_lbl := Label.new()
	cost_lbl.text = "%d Sao" % cost
	cost_lbl.add_theme_font_size_override("font_size", 13)
	cost_lbl.add_theme_color_override("font_color", C_GOLD)
	if _font_body_bold:
		cost_lbl.add_theme_font_override("font", _font_body_bold)
	cost_hbox.add_child(cost_lbl)
	
	var desc_lbl := Label.new()
	desc_lbl.text = desc
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", Color(0.43, 0.38, 0.33, 0.9))
	if _font_body:
		desc_lbl.add_theme_font_override("font", _font_body)
	vbox.add_child(desc_lbl)
	
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 38)
	if _font_body_bold:
		btn.add_theme_font_override("font", _font_body_bold)
	vbox.add_child(btn)
	_make_btn_bouncy(btn)
	
	if not owned:
		btn.text = "MỞ KHÓA"
		if stars >= cost:
			_style_primary_btn(btn)
			btn.disabled = false
		else:
			_style_disabled_button(btn)
			btn.disabled = true
	else:
		btn.disabled = false
		var active = item.get("isEquipped", false)
		if active:
			btn.text = "CẤT ĐI"
			_style_outline_btn(btn)
		else:
			btn.text = "TRƯNG BÀY"
			_style_primary_btn(btn)
			
		# Clean extra emojis from equipped button texts and add style box customization if needed
	btn.pressed.connect(_on_shop_action_pressed.bind(item, owned))
	return card

func _style_primary_btn(btn: Button) -> void:
	var s_norm := StyleBoxFlat.new()
	s_norm.bg_color = C_JADE
	s_norm.border_color = C_GOLD
	s_norm.border_width_left = 2; s_norm.border_width_right = 2
	s_norm.border_width_top = 2; s_norm.border_width_bottom = 2
	s_norm.corner_radius_top_left = 20; s_norm.corner_radius_top_right = 20
	s_norm.corner_radius_bottom_left = 20; s_norm.corner_radius_bottom_right = 20
	s_norm.shadow_size = 6
	s_norm.shadow_color = Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.35)
	
	var s_hov := s_norm.duplicate() as StyleBoxFlat
	s_hov.bg_color = Color(0.18, 0.48, 0.32, 1.0)
	s_hov.border_color = C_GOLD_LIGHT
	
	var s_prs := s_norm.duplicate() as StyleBoxFlat
	s_prs.bg_color = Color(0.08, 0.25, 0.16, 1.0)
	s_prs.border_color = C_GOLD
	
	btn.add_theme_stylebox_override("normal", s_norm)
	btn.add_theme_stylebox_override("hover", s_hov)
	btn.add_theme_stylebox_override("pressed", s_prs)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_color_override("font_color", Color(0.99, 0.98, 0.95, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.90, 0.88, 0.84, 1.0))
	btn.add_theme_font_size_override("font_size", 14)
	if _font_body_bold:
		btn.add_theme_font_override("font", _font_body_bold)
	btn.remove_theme_stylebox_override("disabled")
	btn.remove_theme_color_override("font_disabled_color")

func _style_outline_btn(btn: Button) -> void:
	var s_norm := StyleBoxFlat.new()
	s_norm.bg_color = Color(0, 0, 0, 0)
	s_norm.border_color = C_JADE
	s_norm.border_width_left = 2; s_norm.border_width_right = 2
	s_norm.border_width_top = 2; s_norm.border_width_bottom = 2
	s_norm.corner_radius_top_left = 20; s_norm.corner_radius_top_right = 20
	s_norm.corner_radius_bottom_left = 20; s_norm.corner_radius_bottom_right = 20
	
	var s_hov := s_norm.duplicate() as StyleBoxFlat
	s_hov.bg_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.12)
	s_hov.border_color = C_GOLD
	
	var s_prs := s_norm.duplicate() as StyleBoxFlat
	s_prs.bg_color = Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.15)
	s_prs.border_color = C_JADE
	
	btn.add_theme_stylebox_override("normal", s_norm)
	btn.add_theme_stylebox_override("hover", s_hov)
	btn.add_theme_stylebox_override("pressed", s_prs)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_color_override("font_color", C_JADE)
	btn.add_theme_color_override("font_hover_color", Color(0.13, 0.08, 0.05, 1.0))
	btn.add_theme_color_override("font_pressed_color", C_JADE)
	btn.add_theme_font_size_override("font_size", 14)
	if _font_body_bold:
		btn.add_theme_font_override("font", _font_body_bold)
	btn.remove_theme_stylebox_override("disabled")
	btn.remove_theme_color_override("font_disabled_color")

func _style_disabled_button(btn: Button) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.92, 0.90, 0.86, 0.70) # Warm muted soft beige
	s.border_color = Color(0.78, 0.75, 0.70, 0.50)
	s.border_width_left = 2; s.border_width_right = 2
	s.border_width_top = 2; s.border_width_bottom = 2
	s.corner_radius_top_left = 20; s.corner_radius_top_right = 20
	s.corner_radius_bottom_left = 20; s.corner_radius_bottom_right = 20
	btn.add_theme_stylebox_override("disabled", s)
	btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.50, 0.45, 0.7))
	btn.add_theme_font_size_override("font_size", 14)
	if _font_body_bold:
		btn.add_theme_font_override("font", _font_body_bold)

func _make_texture_transparent(tex: Texture2D) -> Texture2D:
	if not tex: return null
	var img := tex.get_image()
	if not img: return tex
	
	if img.is_compressed():
		var err = img.decompress()
		if err != OK:
			return tex
			
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
		
	# Loop over all pixels
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c := img.get_pixel(x, y)
			# Key out near-white background
			if c.r > 0.90 and c.g > 0.90 and c.b > 0.90:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				
	return ImageTexture.create_from_image(img)

func _start_intro_cinematic() -> void:
	if not is_instance_valid(_audio_manager): return
	_has_played_intro = true
	_is_in_intro = true
	var dim_overlay = ColorRect.new()
	dim_overlay.name = "IntroDimOverlay"
	dim_overlay.color = Color(0, 0, 0, 0)
	dim_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim_overlay.z_index = 40
	dim_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim_overlay)
	
	var sub_panel = PanelContainer.new()
	sub_panel.name = "IntroSubtitle"
	sub_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	sub_panel.offset_left = -440.0
	sub_panel.offset_right = 60.0
	sub_panel.offset_top = -130.0
	sub_panel.offset_bottom = 90.0
	sub_panel.z_index = 51
	sub_panel.modulate = Color(1, 1, 1, 0)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.05, 0.05, 0.75)
	sb.border_width_left = 3; sb.border_width_right = 3
	sb.border_width_top = 3; sb.border_width_bottom = 3
	sb.border_color = Color(0.9, 0.75, 0.3, 0.9) # Gold border
	sb.corner_radius_top_left = 25; sb.corner_radius_top_right = 25
	sb.corner_radius_bottom_left = 25; sb.corner_radius_bottom_right = 25
	sub_panel.add_theme_stylebox_override("panel", sb)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	sub_panel.add_child(margin)
	
	var subtitle = Label.new()
	subtitle.name = "TextLabel"
	subtitle.text = "Chào mừng bạn đến với lớp học nhạc cụ dân tộc. Hôm nay bạn muốn học gì?"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD
	subtitle.add_theme_font_size_override("font_size", 38)
	subtitle.add_theme_color_override("font_color", Color.WHITE)
	subtitle.add_theme_constant_override("line_spacing", 8)
	subtitle.visible_ratio = 0.0 # Start hidden for typewriter effect
	margin.add_child(subtitle)
	
	add_child(sub_panel)
	
	char_linh.z_index = 50
	
	var t = create_tween()
	t.set_parallel(true)
	t.tween_property(dim_overlay, "color:a", 0.75, 1.0)
	t.tween_property(sub_panel, "modulate:a", 1.0, 1.0)
	t.tween_property(char_linh, "position:x", 600.0 - 50.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(char_linh, "size", Vector2(250.0, 250.0) * 2.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "_linh_base_y", 370.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	for c in $HUD.get_children():
		if c is Control and c.name != "IntroSkipBtn":
			t.tween_property(c, "modulate", Color(0.25, 0.25, 0.25, 1.0), 1.0)
			
	var skip_btn = Button.new()
	skip_btn.name = "IntroSkipBtn"
	skip_btn.text = "Bỏ qua >>"
	skip_btn.add_theme_font_size_override("font_size", 16)
	if _font_body_bold: skip_btn.add_theme_font_override("font", _font_body_bold)
	
	var sb_skip = StyleBoxFlat.new()
	sb_skip.bg_color = Color(0, 0, 0, 0.5)
	sb_skip.border_color = C_GOLD
	sb_skip.border_width_left = 2; sb_skip.border_width_right = 2
	sb_skip.border_width_top = 2; sb_skip.border_width_bottom = 2
	sb_skip.corner_radius_top_left = 20; sb_skip.corner_radius_top_right = 20
	sb_skip.corner_radius_bottom_left = 20; sb_skip.corner_radius_bottom_right = 20
	skip_btn.add_theme_stylebox_override("normal", sb_skip)
	skip_btn.add_theme_stylebox_override("hover", sb_skip)
	skip_btn.add_theme_stylebox_override("pressed", sb_skip)
	
	skip_btn.modulate = Color(1, 1, 1, 0)
	$HUD.add_child(skip_btn)
	
	skip_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	skip_btn.offset_left = -160
	skip_btn.offset_right = -32
	skip_btn.offset_top = -80
	skip_btn.offset_bottom = -32
	skip_btn.pressed.connect(_skip_intro_cinematic)
	
	t.tween_property(skip_btn, "modulate:a", 1.0, 1.0)
	t.set_parallel(false)
	
	t.tween_callback(func():
		var tw_text = create_tween()
		tw_text.tween_property(subtitle, "visible_ratio", 1.0, 3.5).set_ease(Tween.EASE_OUT)
		
		var stream = load("res://audio/phongnhac1.mp3")
		if stream and is_instance_valid(_audio_manager.audio_player):
			if "loop" in stream:
				stream.loop = false
			_audio_manager.audio_player.stream = stream
			_audio_manager.audio_player.play()
			
			if not _audio_manager.audio_player.finished.is_connected(_end_intro_cinematic):
				_audio_manager.audio_player.finished.connect(_end_intro_cinematic, CONNECT_ONE_SHOT)
			
			var dur = stream.get_length() if stream.has_method("get_length") else 5.0
			var timer = get_tree().create_timer(dur + 0.5)
			if not timer.timeout.is_connected(_end_intro_cinematic):
				timer.timeout.connect(_end_intro_cinematic)
		else:
			_audio_manager.speak_vietnamese(subtitle.text)
			var timer = get_tree().create_timer(5.0)
			if not timer.timeout.is_connected(_end_intro_cinematic):
				timer.timeout.connect(_end_intro_cinematic)
	)

func _end_intro_cinematic() -> void:
	if not _is_in_intro: return
	_is_in_intro = false
	var dim_overlay = get_node_or_null("IntroDimOverlay")
	var subtitle = get_node_or_null("IntroSubtitle")
	var skip_btn = get_node_or_null("HUD/IntroSkipBtn")
	var t = create_tween()
	t.set_parallel(true)
	if dim_overlay: t.tween_property(dim_overlay, "color:a", 0.0, 1.0)
	if subtitle: t.tween_property(subtitle, "modulate:a", 0.0, 1.0)
	if skip_btn: t.tween_property(skip_btn, "modulate:a", 0.0, 1.0)
	for c in $HUD.get_children():
		if c is Control and c.name != "IntroSkipBtn":
			t.tween_property(c, "modulate", Color(1, 1, 1, 1), 1.0)
	t.set_parallel(false)
	t.tween_callback(func():
		if dim_overlay: dim_overlay.queue_free()
		if subtitle: subtitle.queue_free()
		if skip_btn: skip_btn.queue_free()
		char_linh.z_index = 0
		_on_viewport_size_changed()
	)

func _skip_intro_cinematic() -> void:
	if not _is_in_intro: return
	if is_instance_valid(_audio_manager) and is_instance_valid(_audio_manager.audio_player):
		_audio_manager.audio_player.stop()
	_end_intro_cinematic()

func _setup_hanging_scroll() -> void:
	var scroll = room_content.get_node_or_null("HangingScroll")
	if scroll:
		return
		
	scroll = PanelContainer.new()
	scroll.name = "HangingScroll"
	room_content.add_child(scroll)
	room_content.move_child(scroll, 0) # Keep it in background
	
	# Frosted Glass Shader for Hanging Scroll
	var blur_shader := Shader.new()
	blur_shader.code = """
	shader_type canvas_item;
	uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
	uniform float lod: hint_range(0.0, 5.0) = 2.0;
	void fragment() {
		COLOR = textureLod(screen_texture, SCREEN_UV, lod);
	}
	"""
	
	var blur_rect := ColorRect.new()
	blur_rect.name = "BlurBG"
	blur_rect.material = ShaderMaterial.new()
	blur_rect.material.shader = blur_shader
	blur_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blur_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blur_rect.show_behind_parent = true
	scroll.add_child(blur_rect)
	
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.99, 0.98, 0.96, 0.65) # Warm cream glass
	sb.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.65)
	sb.border_width_left = 3
	sb.border_width_right = 3
	sb.border_width_top = 3
	sb.border_width_bottom = 3
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	scroll.add_theme_stylebox_override("panel", sb)
	
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	scroll.add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	margin.add_child(vbox)
	
	var lbl_music := Label.new()
	lbl_music.name = "LblMusic"
	lbl_music.text = "ÂM NHẠC"
	lbl_music.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_music.add_theme_color_override("font_color", C_JADE)
	if _font_title:
		lbl_music.add_theme_font_override("font", _font_title)
	vbox.add_child(lbl_music)
	
	var sep1 := HSeparator.new()
	sep1.name = "Sep1"
	sep1.modulate = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45)
	vbox.add_child(sep1)
	
	var lbl_trad := Label.new()
	lbl_trad.name = "LblTrad"
	lbl_trad.text = "TRUYỀN THỐNG"
	lbl_trad.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_trad.add_theme_color_override("font_color", C_GOLD)
	if _font_body_bold:
		lbl_trad.add_theme_font_override("font", _font_body_bold)
	vbox.add_child(lbl_trad)
	
	var lbl_viet := Label.new()
	lbl_viet.name = "LblViet"
	lbl_viet.text = "VIỆT NAM"
	lbl_viet.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_viet.add_theme_color_override("font_color", C_JADE)
	if _font_title:
		lbl_viet.add_theme_font_override("font", _font_title)
	vbox.add_child(lbl_viet)
	
	var sep2 := HSeparator.new()
	sep2.name = "Sep2"
	sep2.modulate = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45)
	vbox.add_child(sep2)
	
	var seal_ctrl := Control.new()
	seal_ctrl.name = "Seal"
	seal_ctrl.custom_minimum_size = Vector2(32, 32)
	seal_ctrl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	seal_ctrl.draw.connect(func() -> void:
		var seal_r := seal_ctrl.size.x / 2.0
		var seal_pos := Vector2(seal_r, seal_r)
		seal_ctrl.draw_circle(seal_pos, seal_r, Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.15))
		seal_ctrl.draw_arc(seal_pos, seal_r - 2.0, 0, TAU, 32, C_RED_SON, 1.5)
		seal_ctrl.draw_circle(seal_pos, 4.0, Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.5))
	)
	vbox.add_child(seal_ctrl)

func _update_hanging_scroll_layout() -> void:
	var scroll = room_content.get_node_or_null("HangingScroll")
	if not scroll:
		return
	
	var scroll_w := 160.0 if _is_mobile_layout else 220.0
	var scroll_h := 160.0 if _is_mobile_layout else 210.0
	var scroll_x := (1200.0 - scroll_w) / 2.0
	var scroll_y := 12.0
	
	scroll.position = Vector2(scroll_x, scroll_y)
	scroll.size = Vector2(scroll_w, scroll_h)
	scroll.custom_minimum_size = Vector2(scroll_w, scroll_h)
	
	var vbox = scroll.get_node("Margin/VBox")
	var lbl_music = vbox.get_node("LblMusic") as Label
	var lbl_trad = vbox.get_node("LblTrad") as Label
	var lbl_viet = vbox.get_node("LblViet") as Label
	var seal = vbox.get_node("Seal") as Control
	
	if _is_mobile_layout:
		lbl_music.add_theme_font_size_override("font_size", 16)
		lbl_trad.add_theme_font_size_override("font_size", 11)
		lbl_viet.add_theme_font_size_override("font_size", 14)
		seal.custom_minimum_size = Vector2(28, 28)
	else:
		lbl_music.add_theme_font_size_override("font_size", 22)
		lbl_trad.add_theme_font_size_override("font_size", 13)
		lbl_viet.add_theme_font_size_override("font_size", 17)
		seal.custom_minimum_size = Vector2(34, 34)
