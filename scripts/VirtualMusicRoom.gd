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
var _time : float = 0.0
var _hovered_station : String = ""
var _linh_base_y : float = 220.0
var _speech_timer : float = 0.0
var _welcome_bow_timer : float = 1.6


var _current_popup_instrument : String = ""
var _audio_manager : AIAudioManager = null

var _linh_is_moving : bool = false
var _linh_tween : Tween = null
var _particles : Array[Dictionary] = []
var _tex_tranh : Texture2D
var _tex_sao : Texture2D
var _tex_bau : Texture2D
var _tex_trong : Texture2D
var _tex_linh : Texture2D
var _tex_player : Texture2D
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

var _font_title : Font
var _font_body : Font
var _font_body_bold : Font


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
	_spawn_decorations()
	_setup_hud_shop_button()
	_tex_tranh = _make_texture_transparent(load("res://assets/textures/dan_tranh_asset.png") as Texture2D)
	_tex_sao = _make_texture_transparent(load("res://assets/textures/sao_truc_asset.png") as Texture2D)
	_tex_bau = _make_texture_transparent(load("res://assets/textures/dan_bau_asset.png") as Texture2D)
	_tex_trong = _make_texture_transparent(load("res://assets/textures/trong_chau_asset.png") as Texture2D)
	_tex_linh = load("res://assets/textures/virtual_artist_mai.png") as Texture2D
	_tex_player = load("res://assets/textures/virtual_student.png") as Texture2D
	
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
	s_tranh.size = Vector2(240, 140)
	s_sao.size = Vector2(240, 140)
	s_bau.size = Vector2(240, 140)
	s_trong.size = Vector2(240, 140)
	
	_setup_station_button(s_tranh, "tranh", "Đàn Tranh", _draw_tranh)
	_setup_station_button(s_sao, "sao", "Sáo Trúc", _draw_sao)
	_setup_station_button(s_bau, "bau", "Đàn Bầu", _draw_bau)
	_setup_station_button(s_trong, "trong", "Trống Chầu", _draw_trong)
	
	# Setup Linh Assist
	char_linh.draw.connect(_draw_linh.bind(char_linh))
	_linh_base_y = char_linh.position.y
	char_linh.gui_input.connect(_on_char_linh_gui_input)
	
	# Speech bubble hidden (removed by design)
	
	# Setup Focus Mode Popup controls
	_setup_focus_popup_controls()
	
	# Setup Back button to return to Main Menu
	btn_back.show()
	_style_popup_button(btn_back, true)
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
	
	# Play welcome speech after transition
	get_tree().create_timer(0.8).timeout.connect(func() -> void:
		if is_instance_valid(_audio_manager):
			_audio_manager.speak_vietnamese("Chào mừng bạn đến với lớp học nhạc cụ dân tộc của Mai, hôm nay bạn muốn học gì")
	)



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

	# Floating animation for pedestals/stations
	s_tranh.position.y = 520.0 + sin(_time * 2.0) * 8.0
	s_sao.position.y = 520.0 + sin(_time * 2.0 + PI/2.0) * 8.0
	s_bau.position.y = 360.0 + sin(_time * 2.0 + PI) * 8.0
	s_trong.position.y = 360.0 + sin(_time * 2.0 + 1.5*PI) * 8.0

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
	
	# Occasional random talk from Linh if idle
	_speech_timer += delta
	if _speech_timer > 15.0:
		_speech_timer = 0.0
		if _hovered_station == "" and not is_ui_focused:
			_show_dialogue(LINH_TIPS.pick_random())

# ─── Tooltip & Affordance Interactive Stations ─────────────────────────────────
func _setup_station_button(btn: Button, code_name: String, displayName: String, draw_func: Callable) -> void:
	btn.pivot_offset = btn.size / 2.0
	btn.draw.connect(_on_station_draw.bind(btn, displayName, draw_func))
	
	# Override button styles to flat/empty to remove ugly Godot grey boxes
	var empty_sb := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty_sb)
	btn.add_theme_stylebox_override("hover", empty_sb)
	btn.add_theme_stylebox_override("pressed", empty_sb)
	btn.add_theme_stylebox_override("focus", empty_sb)
	btn.flat = true
	
	btn.mouse_entered.connect(_on_station_mouse_entered.bind(btn, code_name, displayName))
	btn.mouse_exited.connect(_on_station_mouse_exited.bind(btn, code_name))
	btn.pressed.connect(_on_station_pressed.bind(btn, code_name))

func _on_station_draw(btn: Button, displayName: String, draw_func: Callable) -> void:
	var sz := btn.size
	var is_hov := btn.is_hovered()
	
	# Draw the custom instrument vectors
	draw_func.call(btn)
	
	# Draw instrument name label at the bottom of the card using _font_body_bold
	var font := _font_body_bold if _font_body_bold else btn.get_theme_default_font()
	if font:
		var name_str := displayName
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
			lbl_y = cy + 25.0
		
		# Shadow
		btn.draw_string(font, Vector2(lbl_x + 1, lbl_y + 1), name_str,
			HORIZONTAL_ALIGNMENT_CENTER, sz.x, 16, Color(0, 0, 0, 0.6))
		# Main text: gold when hovered, cream when normal
		var text_col := C_GOLD_LIGHT if is_hov else C_CREAM
		btn.draw_string(font, Vector2(lbl_x, lbl_y), name_str,
			HORIZONTAL_ALIGNMENT_CENTER, sz.x, 16, text_col)

func _on_station_mouse_entered(btn: Button, code_name: String, displayName: String) -> void:
	_hovered_station = code_name
	
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
	# Visual press feedback
	var pt := create_tween()
	pt.tween_property(btn, "scale", Vector2(0.92, 0.92), 0.08)
	pt.tween_property(btn, "scale", Vector2(1.08, 1.08) if btn.is_hovered() else Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK)
	
	# Skip introduction popup and select instrument directly to enter MainMenu
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

func _get_station_interact_spot(code_name: String) -> Vector2:
	match code_name:
		"tranh": return Vector2(s_tranh.position.x + 120.0, 700.0)
		"sao": return Vector2(s_sao.position.x + 120.0, 700.0)
		"bau": return Vector2(s_bau.position.x + 120.0, 540.0)
		"trong": return Vector2(s_trong.position.x + 120.0, 540.0)
	return Vector2(600, 480)

func _get_closest_station() -> String:
	var player_feet := _get_player_feet()
	var stations := {
		"tranh": Vector2(s_tranh.position.x + 120.0, 655.0),
		"sao": Vector2(s_sao.position.x + 120.0, 655.0),
		"bau": Vector2(s_bau.position.x + 120.0, 495.0),
		"trong": Vector2(s_trong.position.x + 120.0, 495.0)
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

func _move_linh_to_station(station_code: String) -> void:
	_linh_is_moving = true
	if _linh_tween:
		_linh_tween.kill()
	
	var target_feet := Vector2(600, 370) # default starting feet position
	
	match station_code:
		"tranh":       target_feet = Vector2(s_tranh.position.x + 120.0, 655.0)
		"sao":         target_feet = Vector2(s_sao.position.x + 120.0, 655.0)
		"bau":         target_feet = Vector2(s_bau.position.x + 120.0, 495.0)
		"trong":       target_feet = Vector2(s_trong.position.x + 120.0, 495.0)
	
	var target_x := target_feet.x - 80.0
	var target_y := target_feet.y - 150.0
	
	_linh_tween = create_tween()
	_linh_tween.set_parallel(true)
	_linh_tween.tween_property(char_linh, "position:x", target_x, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_linh_tween.tween_property(self, "_linh_base_y", target_y, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	_linh_tween.set_parallel(false)
	_linh_tween.tween_callback(func() -> void:
		_linh_is_moving = false
		_open_focus_mode_popup(station_code)
	)

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
	
	# Configure labels and details based on instrument
	if inst == "tranh":
		popup_title.text = "Giới Thiệu Đàn Tranh"
		text_theory.text = "Đàn Tranh sử dụng thang âm chuẩn với các nốt nhạc: Đô - Rê - Mi - Fa - Sol - La - Si (tương đương với các tần số C3 - D3 - E3 - F3 - G3 - A3 - B3). Nhấn vào dây đàn bên phải nhạn để gảy âm."
		text_fingering.text = "Kỹ thuật tay phải: Sử dụng ngón cái (1), ngón trỏ (2) và ngón giữa (3) đeo móng gảy để gảy dây đàn hướng vào lòng.\nKỹ thuật tay trái: Nhấn và rung dây ở phía bên trái nhạn đàn để tạo âm rung cảm xúc."
		btn_popup_play.visible = true
		btn_popup_play.text = "VÀO HỌC"
	elif inst == "sao":
		popup_title.text = "Giới Thiệu Sáo Trúc"
		text_theory.text = "Sáo Trúc sử dụng thang âm tự nhiên. Bằng cách lấy hơi bụng tròn trịa và hé/bịt các lỗ bấm, người thổi có thể tạo ra các nốt Đô - Rê - Mi - Fa - Sol - La chuẩn âm điệu dân tộc."
		text_fingering.text = "Kỹ thuật ngón: Đặt môi đều vào lỗ thổi. Bịt kín lỗ ngón bằng đầu ngón tay mềm mại (không dùng đốt ngón tay). Thổi hơi đều để âm thanh không bị rè."
		btn_popup_play.visible = true
		btn_popup_play.text = "VÀO HỌC"
	elif inst == "bau":
		popup_title.text = "Giới Thiệu Đàn Bầu"
		text_theory.text = "Đàn Bầu (Độc huyền cầm) chỉ sử dụng một dây tơ duy nhất căng trên thân tre gỗ. Các nốt nhạc được tạo ra bằng cách gảy vào các điểm hài âm và uốn vòi đàn để đổi cao độ."
		text_fingering.text = "Tay phải: Dùng que gảy nhỏ gảy vào dây đồng thời chạm cạnh bàn tay vào điểm hài âm để tạo tiếng bầu trầm bổng.\nTay trái: Cầm vòi đàn uốn về phía trước (giảm cao độ) hoặc kéo về sau (tăng cao độ)."
		btn_popup_play.visible = true
		btn_popup_play.text = "VÀO HỌC"
	elif inst == "trong":
		popup_title.text = "Giới Thiệu Trống Chầu"
		text_theory.text = "Trống Chầu đóng vai trò giữ nhịp điệu rộn ràng cho các điệu hát chèo, hát đào cổ truyền. Mặt trống bằng da bò căng chặt tạo tiếng vang đanh thép rực lửa."
		text_fingering.text = "Gõ vào tâm mặt trống tạo tiếng 'Tịch' trầm sâu. Gõ vào vành gỗ trống bằng dùi chầu gỗ tạo tiếng 'Cắc' vang dội réo rắt báo hiệu đổi làn điệu."
		btn_popup_play.visible = true
		btn_popup_play.text = "VÀO HỌC" # locked
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

# ─── Procedural 2.5D Room Drawing – Classical Vietnamese Style ─────────────────
func _draw_room_background() -> void:
	var viewport_size : Vector2 = get_viewport().get_visible_rect().size
	# 1. Deep background — aged indigo/midnight tone
	bg_canvas.draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.07, 0.05, 0.04))
	
	# Set transform relative to room_content (1200x800 space)
	bg_canvas.draw_set_transform(room_content.position, 0.0, room_content.scale)
	var sz := Vector2(1200, 800)
	var wall_h := 310.0
	
	# Calculate visible screen boundaries in transformed coordinates to stretch room background
	var rx := room_content.position.x
	var ry := room_content.position.y
	var scale := room_content.scale.x
	var left_bound : float = -rx / scale if scale > 0.0 else 0.0
	var right_bound : float = (viewport_size.x - rx) / scale if scale > 0.0 else 1200.0
	var top_bound : float = -ry / scale if scale > 0.0 else 0.0
	var bottom_bound : float = (viewport_size.y - ry) / scale if scale > 0.0 else 800.0
	
	# ── 2. Wall: aged cream plaster (Stretched!) ──────────────────────
	var wall_base := Color(0.95, 0.93, 0.89)  # warm cream-beige (#F3EFE3)
	bg_canvas.draw_rect(Rect2(left_bound, top_bound, right_bound - left_bound, wall_h - top_bound), wall_base)
	
	# Subtle aged plaster texture — horizontal streaks stretching across bounds
	for i in range(int(top_bound), int(wall_h), 8):
		var streak_a := 0.04 * sin(float(i) * 0.3 + _time * 0.1)
		var streak_col := Color(0.92 + streak_a, 0.88, 0.80, 0.25)
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
	
	# ── 4. Central hanging scroll calligraphy panel (Remains Centered!) ───────────
	var scroll_w := 220.0
	var scroll_h := 230.0
	var scroll_x := (sz.x - scroll_w) / 2.0
	var scroll_y := 28.0
	# Scroll background (aged silk)
	bg_canvas.draw_rect(Rect2(scroll_x, scroll_y, scroll_w, scroll_h), Color(0.94, 0.89, 0.74))
	# Decorative inner border
	bg_canvas.draw_rect(Rect2(scroll_x + 8, scroll_y + 8, scroll_w - 16, scroll_h - 16), Color(0.94, 0.89, 0.74), false)
	bg_canvas.draw_rect(Rect2(scroll_x + 8, scroll_y + 8, scroll_w - 16, scroll_h - 16), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.6), false, 1.5)
	# Gold outer frame
	bg_canvas.draw_rect(Rect2(scroll_x, scroll_y, scroll_w, scroll_h), C_GOLD, false, 3.0)
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
	# Kanji/Chu Nom style vertical strokes (abstract decorative)
	var font := _font_title if _font_title else bg_canvas.get_theme_default_font()
	if font:
		bg_canvas.draw_string(font, Vector2(scroll_x, scroll_y + 44), "ÂM NHẠC", HORIZONTAL_ALIGNMENT_CENTER, scroll_w, 24, C_RED_SON)
		bg_canvas.draw_string(font, Vector2(scroll_x, scroll_y + 90), "TRUYỀN THỐNG", HORIZONTAL_ALIGNMENT_CENTER, scroll_w, 15, C_RED_DK)
		bg_canvas.draw_string(font, Vector2(scroll_x, scroll_y + 118), "VIỆT NAM", HORIZONTAL_ALIGNMENT_CENTER, scroll_w, 18, C_RED_SON)
	# Thin horizontal separator lines
	bg_canvas.draw_line(Vector2(scroll_x + 20, scroll_y + 60), Vector2(scroll_x + scroll_w - 20, scroll_y + 60), C_GOLD, 1.0)
	bg_canvas.draw_line(Vector2(scroll_x + 20, scroll_y + 132), Vector2(scroll_x + scroll_w - 20, scroll_y + 132), C_GOLD, 1.0)
	# Ink-wash lotus / seal decorative motif
	var seal_pos := Vector2(scroll_x + scroll_w * 0.5, scroll_y + 175)
	bg_canvas.draw_circle(seal_pos, 24.0, Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.15))
	bg_canvas.draw_arc(seal_pos, 22.0, 0, TAU, 32, C_RED_SON, 1.5)
	bg_canvas.draw_circle(seal_pos, 8.0, Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.5))
	
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
	bg_canvas.draw_colored_polygon(floor_pts, Color(0.16, 0.12, 0.09))  # muted dark teak wood
	
	# Horizontal plank grain lines stretching across bounds
	var plank_h := 26.0
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
	var shadow_col := Color(0.06, 0.03, 0.01, 0.55)
	
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
		[Vector2(s_tranh.position.x + 120.0, 655.0), "Đàn Tranh"],
		[Vector2(s_sao.position.x + 120.0, 655.0), "Sáo Trúc"],
		[Vector2(s_bau.position.x + 120.0, 495.0), "Đàn Bầu"],
		[Vector2(s_trong.position.x + 120.0, 495.0), "Trống Chầu"],
	]
	
	for st in stations:
		var pos : Vector2 = st[0]
		
		# 1. Floor drop shadow (ellipse)
		floor_canvas.draw_arc(pos, 80.0, 0, TAU, 32, shadow_col, 14.0)
		
		# 2. Permanent warm spotlight glow halos on floor (Soften by 60%)
		var halo_a := 0.04 + 0.02 * sin(_time * 1.2)
		floor_canvas.draw_arc(pos, 96.0, 0, TAU, 32, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, halo_a * 0.5), 18.0)
		floor_canvas.draw_arc(pos, 82.0, 0, TAU, 32, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, halo_a), 6.0)
		floor_canvas.draw_arc(pos, 70.0, 0, TAU, 32, Color(1.0, 0.95, 0.80, halo_a * 0.6), 2.0)
	
	# 3. Pulsing yellow glow circle when hovering (Soften by 50%)
	if _hovered_station != "":
		var base_pos := Vector2.ZERO
		
		match _hovered_station:
			"tranh":  base_pos = Vector2(s_tranh.position.x + 120.0, 655.0)
			"sao":    base_pos = Vector2(s_sao.position.x + 120.0, 655.0)
			"bau":    base_pos = Vector2(s_bau.position.x + 120.0, 495.0)
			"trong":  base_pos = Vector2(s_trong.position.x + 120.0, 495.0)
		
		if base_pos != Vector2.ZERO:
			var pulse := sin(_time * 7.0)
			# Outer soft ring
			floor_canvas.draw_arc(base_pos, 108.0 + pulse * 5.0, 0, TAU, 32,
				Color(C_GOLD_LIGHT.r, C_GOLD_LIGHT.g, C_GOLD_LIGHT.b, 0.08 + 0.04 * pulse), 14.0, true)
			# Middle ring
			floor_canvas.draw_arc(base_pos, 86.0, 0, TAU, 32,
				Color(C_GOLD_LIGHT.r, C_GOLD_LIGHT.g, C_GOLD_LIGHT.b, 0.28 + 0.08 * pulse), 8.0, true)
			# Inner bright ring
			floor_canvas.draw_arc(base_pos, 74.0, 0, TAU, 32,
				Color(1.0, 0.97, 0.90, 0.45), 2.5, true)

				
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
	if not char_player:
		return
	var items : Array[Control] = [s_tranh, s_sao, s_bau, s_trong, char_linh, char_player]
	for c in room_content.get_children():
		if c.name.begins_with("Decor_"):
			items.append(c)
			
	items.sort_custom(func(a, b):
		return _get_sort_y(a) < _get_sort_y(b)
	)
	# FloorCanvas is at index 0, so move other children starting from index 1
	for i in range(items.size()):
		room_content.move_child(items[i], i + 1)
	
func _draw_tranh(c: Button) -> void:
	var sz := c.size
	var cx := sz.x * 0.5
	var cy := sz.y * 0.5
	var is_hov := c.is_hovered()
	
	# Draw table stand with wooden joint detail & shadow
	c.draw_line(Vector2(cx - 70, cy + 15), Vector2(cx - 75, cy + 65), Color(0.12, 0.06, 0.03), 6.0)
	c.draw_line(Vector2(cx + 70, cy + 15), Vector2(cx + 75, cy + 65), Color(0.12, 0.06, 0.03), 6.0)
	c.draw_line(Vector2(cx - 75, cy + 60), Vector2(cx + 75, cy + 60), Color(0.10, 0.05, 0.02), 3.5)
	
	if _tex_tranh:
		# Dimensions of the instrument image card
		var img_w := 200.0
		var img_h := 70.0
		var card_rect := Rect2(cx - img_w / 2.0, cy - img_h / 2.0 - 15.0, img_w, 100.0)
		var img_rect := Rect2(cx - img_w / 2.0, cy - img_h / 2.0 - 15.0, img_w, img_h)
		
		# Draw a premium dark glassmorphism card background with gold border
		var r_sb := StyleBoxFlat.new()
		r_sb.bg_color = Color(0.05, 0.03, 0.02, 0.70) # Dark warm brown glass
		r_sb.border_color = C_GOLD if not is_hov else C_GOLD_LIGHT
		r_sb.border_width_left = 2; r_sb.border_width_right = 2
		r_sb.border_width_top = 2; r_sb.border_width_bottom = 2
		r_sb.corner_radius_top_left = 12; r_sb.corner_radius_top_right = 12
		r_sb.corner_radius_bottom_left = 12; r_sb.corner_radius_bottom_right = 12
		r_sb.shadow_size = 8
		r_sb.shadow_color = Color(0, 0, 0, 0.3)
		r_sb.shadow_offset = Vector2(0, 4)
		c.draw_style_box(r_sb, card_rect)
		
		# Draw the loaded Dan Tranh image texture on top of the glass card
		c.draw_texture_rect(_tex_tranh, img_rect, false)
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
	
	# Stand base shadow & wood stand
	c.draw_line(Vector2(cx - 30, cy + 25), Vector2(cx + 30, cy + 25), Color(0.18, 0.10, 0.05), 5.5)
	c.draw_line(Vector2(cx - 20, cy + 25), Vector2(cx - 20, cy + 65), Color(0.18, 0.10, 0.05), 3.5)
	c.draw_line(Vector2(cx + 20, cy + 25), Vector2(cx + 20, cy + 65), Color(0.18, 0.10, 0.05), 3.5)
	c.draw_circle(Vector2(cx - 20, cy + 25), 3.5, C_GOLD)
	c.draw_circle(Vector2(cx + 20, cy + 25), 3.5, C_GOLD)
	
	if _tex_sao:
		# Dimensions of the instrument image card
		var img_w := 200.0
		var img_h := 70.0
		var card_rect := Rect2(cx - img_w / 2.0, cy - img_h / 2.0 - 15.0, img_w, 100.0)
		var img_rect := Rect2(cx - img_w / 2.0, cy - img_h / 2.0 - 15.0, img_w, img_h)
		
		# Draw a premium dark glassmorphism card background with gold border
		var r_sb := StyleBoxFlat.new()
		r_sb.bg_color = Color(0.05, 0.03, 0.02, 0.70) # Dark warm brown glass
		r_sb.border_color = C_GOLD if not is_hov else C_GOLD_LIGHT
		r_sb.border_width_left = 2; r_sb.border_width_right = 2
		r_sb.border_width_top = 2; r_sb.border_width_bottom = 2
		r_sb.corner_radius_top_left = 12; r_sb.corner_radius_top_right = 12
		r_sb.corner_radius_bottom_left = 12; r_sb.corner_radius_bottom_right = 12
		r_sb.shadow_size = 8
		r_sb.shadow_color = Color(0, 0, 0, 0.3)
		r_sb.shadow_offset = Vector2(0, 4)
		c.draw_style_box(r_sb, card_rect)
		
		# Draw the loaded Sao Truc image texture on top of the glass card
		c.draw_texture_rect(_tex_sao, img_rect, false)
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
	
	# Zither Base Stand
	c.draw_line(Vector2(cx - 65, cy + 20), Vector2(cx - 70, cy + 65), Color(0.14, 0.08, 0.04), 5.5)
	c.draw_line(Vector2(cx + 65, cy + 20), Vector2(cx + 70, cy + 65), Color(0.14, 0.08, 0.04), 5.5)
	
	if _tex_bau:
		# Dimensions of the instrument image card
		var img_w := 200.0
		var img_h := 70.0
		var card_rect := Rect2(cx - img_w / 2.0, cy - img_h / 2.0 - 15.0, img_w, 100.0)
		var img_rect := Rect2(cx - img_w / 2.0, cy - img_h / 2.0 - 15.0, img_w, img_h)
		
		# Draw a premium dark glassmorphism card background with gold border
		var r_sb := StyleBoxFlat.new()
		r_sb.bg_color = Color(0.05, 0.03, 0.02, 0.70) # Dark warm brown glass
		r_sb.border_color = C_GOLD if not is_hov else C_GOLD_LIGHT
		r_sb.border_width_left = 2; r_sb.border_width_right = 2
		r_sb.border_width_top = 2; r_sb.border_width_bottom = 2
		r_sb.corner_radius_top_left = 12; r_sb.corner_radius_top_right = 12
		r_sb.corner_radius_bottom_left = 12; r_sb.corner_radius_bottom_right = 12
		r_sb.shadow_size = 8
		r_sb.shadow_color = Color(0, 0, 0, 0.3)
		r_sb.shadow_offset = Vector2(0, 4)
		c.draw_style_box(r_sb, card_rect)
		
		# Draw the loaded Dan Bau image texture on top of the glass card
		c.draw_texture_rect(_tex_bau, img_rect, false)
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
	
	# Wooden Stand
	c.draw_line(Vector2(cx - 36, cy + 15), Vector2(cx - 56, cy + 65), Color(0.20, 0.12, 0.06), 6.0)
	c.draw_line(Vector2(cx + 36, cy + 15), Vector2(cx + 56, cy + 65), Color(0.20, 0.12, 0.06), 6.0)
	c.draw_line(Vector2(cx - 46, cy + 45), Vector2(cx + 46, cy + 45), Color(0.20, 0.12, 0.06), 4.5)
	
	if _tex_trong:
		# Dimensions of the drum image card
		var img_w := 200.0
		var img_h := 70.0
		var card_rect := Rect2(cx - img_w / 2.0, cy - img_h / 2.0 - 15.0, img_w, 100.0)
		var img_rect := Rect2(cx - img_w / 2.0, cy - img_h / 2.0 - 15.0, img_w, img_h)
		
		# Draw a premium dark glassmorphism card background with gold border
		var r_sb := StyleBoxFlat.new()
		r_sb.bg_color = Color(0.05, 0.03, 0.02, 0.70) # Dark warm brown glass
		r_sb.border_color = C_GOLD if not is_hov else C_GOLD_LIGHT
		r_sb.border_width_left = 2; r_sb.border_width_right = 2
		r_sb.border_width_top = 2; r_sb.border_width_bottom = 2
		r_sb.corner_radius_top_left = 12; r_sb.corner_radius_top_right = 12
		r_sb.corner_radius_bottom_left = 12; r_sb.corner_radius_bottom_right = 12
		r_sb.shadow_size = 8
		r_sb.shadow_color = Color(0, 0, 0, 0.3)
		r_sb.shadow_offset = Vector2(0, 4)
		c.draw_style_box(r_sb, card_rect)
		
		# Draw the loaded Trong image texture on top of the glass card
		c.draw_texture_rect(_tex_trong, img_rect, false)
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
		bob = bow_y + sin(_time * 6.5) * 5.0
		rot += sin(_time * 3.5) * 0.038
		scale_vec = Vector2(1.0 + sin(_time * 9.0) * 0.022, 1.0 - sin(_time * 9.0) * 0.022)
	else:
		bob = bow_y + sin(_time * 1.8) * 3.0
		rot += sin(_time * 0.8) * 0.015
		scale_vec = Vector2(1.0, 1.0 + sin(_time * 1.8) * 0.008)
		
	# Draw flat feet shadow (before transform so it doesn't move with her)
	var shadow_radius := 28.0 * clampf(1.0 - (bob / 45.0), 0.7, 1.15)
	c.draw_arc(Vector2(cx, cy + 74), shadow_radius, 0, TAU, 16, Color(0, 0, 0, 0.22), 6.0)
	
	# Apply 2D drawing transform centered at the character base (feet)
	var base_pos := Vector2(cx, cy + 74.0)
	c.draw_set_transform(base_pos + Vector2(0.0, bob - 74.0), rot, scale_vec)
	
	if _tex_linh:
		var img_w := sz.x
		var img_h := sz.y
		var tex_ratio := _tex_linh.get_width() / float(_tex_linh.get_height())
		if tex_ratio > 1.0:
			img_h = sz.x / tex_ratio
		else:
			img_w = sz.y * tex_ratio
		
		# Draw centered relative to the new origin (0.0, 74.0 is feet in local space, so offset is (6.0 - img_h))
		var img_rect := Rect2(-img_w * 0.5, 6.0 - img_h, img_w, img_h)
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
	avatar_control.custom_minimum_size = Vector2(100, 100)
	avatar_control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(avatar_control)
	
	avatar_control.draw.connect(func() -> void:
		var center := Vector2(50, 50)
		avatar_control.draw_circle(center, 46.0, C_GOLD)
		avatar_control.draw_circle(center, 44.0, C_CREAM)
		if _tex_linh:
			var rect := Rect2(center - Vector2(36, 36), Vector2(72, 72))
			avatar_control.draw_texture_rect_region(_tex_linh, rect, Rect2(380, 50, 260, 260))
	)
	
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	hbox.add_child(vbox)
	
	var name_lbl := Label.new()
	name_lbl.text = "Cô Mai"
	if _font_body_bold:
		name_lbl.add_theme_font_override("font", _font_body_bold)
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", C_GOLD_LIGHT)
	vbox.add_child(name_lbl)
	
	dialogue_lbl = Label.new()
	dialogue_lbl.text = "Xin chào học viên!"
	if _font_body:
		dialogue_lbl.add_theme_font_override("font", _font_body)
	dialogue_lbl.add_theme_font_size_override("font_size", 15)
	dialogue_lbl.add_theme_color_override("font_color", C_CREAM)
	dialogue_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	dialogue_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(dialogue_lbl)
	
	btn_dialogue_close = Button.new()
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
	_player_expression = "focused"
	_typewriter_text = text
	_typewriter_progress = 0.0
	dialogue_lbl.text = ""
	dialogue_box.visible = true
	dialogue_box.modulate.a = 0.0
	dialogue_box.offset_bottom = 0
	dialogue_box.offset_top = -160
	
	var t := create_tween().set_parallel(true)
	t.tween_property(dialogue_box, "modulate:a", 1.0, 0.25)
	t.tween_property(dialogue_box, "offset_bottom", -32, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(dialogue_box, "offset_top", -192, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

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
	var t := create_tween().set_parallel(true)
	t.tween_property(dialogue_box, "modulate:a", 0.0, 0.2)
	t.tween_property(dialogue_box, "offset_bottom", 0, 0.2)
	t.tween_property(dialogue_box, "offset_top", -160, 0.2)
	t.chain().tween_callback(func() -> void: dialogue_box.visible = false)

# ─── Focus Mode Vector Custom Diagrams ─────────────────────────────────────────
func _draw_popup_scroll(c: Control) -> void:
	var sz := c.size
	# 1. Cream paper scroll body
	var paper_rect := Rect2(40, 30, sz.x - 80, sz.y - 60)
	c.draw_rect(paper_rect, C_CREAM, true)
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
func _on_viewport_size_changed() -> void:
	var size : Vector2 = get_viewport().get_visible_rect().size
	var is_mobile := size.x < size.y or size.x < 768
	
	# Scale the 2.5D Room content container to fit inside screen boundaries
	var margin_l : float = 0.0
	var margin_r : float = 0.0
	var margin_b : float = 0.0
	
	var room_w : float = float(size.x) - margin_l - margin_r
	var room_h : float = float(size.y) - margin_b
	
	# Base room scale
	var scale_factor := minf(room_w / 1200.0, room_h / 800.0)
	if is_mobile:
		scale_factor *= 1.15
		
	room_content.scale = Vector2(scale_factor, scale_factor)
	room_content.position = Vector2(
		margin_l + (room_w - 1200.0 * scale_factor) / 2.0,
		(room_h - 800.0 * scale_factor) / 2.0
	)
	
	var rx := room_content.position.x
	_left_bound = -rx / scale_factor if scale_factor > 0.0 else 0.0
	_right_bound = (size.x - rx) / scale_factor if scale_factor > 0.0 else 1200.0
	var center_x := 600.0

	s_tranh.position = Vector2(lerpf(center_x - 480.0, _left_bound + 120.0, 0.4), 520.0)
	s_sao.position = Vector2(lerpf(center_x + 240.0, _right_bound - 360.0, 0.4), 520.0)
	s_bau.position = Vector2(lerpf(center_x - 320.0, _left_bound + 280.0, 0.3), 360.0)
	s_trong.position = Vector2(lerpf(center_x + 80.0, _right_bound - 520.0, 0.3), 360.0)
	
	# Update popups to match the actual window size
	if popup and is_instance_valid(popup):
		popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var scroll_panel = popup.get_node_or_null("ScrollPanel")
		if scroll_panel:
			scroll_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
			
	if shop_popup and is_instance_valid(shop_popup):
		shop_popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var scroll_panel = shop_popup.get_node_or_null("ScrollPanel")
		if scroll_panel:
			scroll_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

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
	
	# Create Star Badge
	var star_badge := PanelContainer.new()
	star_badge.name = "StarBadge"
	star_badge.custom_minimum_size = Vector2(140, 48)
	hud_hbox.add_child(star_badge)
	
	var badge_s := StyleBoxFlat.new()
	badge_s.bg_color = Color(0.08, 0.05, 0.03, 0.8) # Dark premium brown
	badge_s.border_color = C_GOLD
	badge_s.border_width_left = 2; badge_s.border_width_right = 2
	badge_s.border_width_top = 2; badge_s.border_width_bottom = 2
	badge_s.corner_radius_top_left = 24; badge_s.corner_radius_top_right = 24
	badge_s.corner_radius_bottom_left = 24; badge_s.corner_radius_bottom_right = 24
	star_badge.add_theme_stylebox_override("panel", badge_s)
	
	var badge_margin := MarginContainer.new()
	badge_margin.name = "Margin"
	badge_margin.add_theme_constant_override("margin_left", 12)
	badge_margin.add_theme_constant_override("margin_right", 12)
	star_badge.add_child(badge_margin)
	
	var badge_label := Label.new()
	badge_label.name = "Label"
	badge_label.text = "⭐ %d SAO" % SecureDataManager.get_total_stars()
	badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge_label.add_theme_font_size_override("font_size", 15)
	badge_label.add_theme_color_override("font_color", C_GOLD_LIGHT)
	if _font_body_bold:
		badge_label.add_theme_font_override("font", _font_body_bold)
	badge_margin.add_child(badge_label)

	# Create Shop Button
	var btn_shop := Button.new()
	btn_shop.name = "BtnShop"
	btn_shop.text = "🎨 TRANG TRÍ"
	btn_shop.custom_minimum_size = Vector2(160, 48)
	hud_hbox.add_child(btn_shop)
	_style_popup_button(btn_shop, true)
	_make_btn_bouncy(btn_shop)
	btn_shop.pressed.connect(_open_shop_popup)

func _update_star_badge() -> void:
	var label = $HUD.get_node_or_null("HUDHBox/StarBadge/Margin/Label") as Label
	if label:
		label.text = "⭐ %d SAO" % SecureDataManager.get_total_stars()

func _spawn_decorations() -> void:
	# Clear old decorations first
	for c in room_content.get_children():
		if c.name.begins_with("Decor_"):
			c.queue_free()
			
	var active_decor = SecureDataManager.data.get("active_decorations", [])
	for item_id in active_decor:
		var ctrl := Control.new()
		ctrl.name = "Decor_" + item_id
		
		# Define sizes and positions for room layout
		match item_id:
			"painting":
				ctrl.position = Vector2(180, 55)
				ctrl.size = Vector2(80, 120)
			"vase":
				ctrl.position = Vector2(390, 420)
				ctrl.size = Vector2(70, 90)
			"bamboo":
				ctrl.position = Vector2(50, 240)
				ctrl.size = Vector2(80, 110)
			"bronze_drum":
				ctrl.position = Vector2(615, 665)
				ctrl.size = Vector2(80, 65)
				
		room_content.add_child(ctrl)
		ctrl.draw.connect(_draw_decor_node.bind(ctrl, item_id))
	
	_sort_room_elements()

func _draw_decor_node(c: Control, item_id: String) -> void:
	_draw_decor_item(c, item_id, 1.0)

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

func _draw_decor_item(c: Control, item_id: String, size_scale: float = 1.0) -> void:
	var sz := c.size
	var cx := sz.x * 0.5
	var cy := sz.y * 0.5
	
	match item_id:
		"painting":
			var rect_w := 68.0 * size_scale
			var rect_h := 110.0 * size_scale
			var px := cx - rect_w/2
			var py := cy - rect_h/2
			
			# Rollers at top and bottom (dark wood with gold caps)
			var roller_color := Color(0.18, 0.10, 0.05)
			c.draw_rect(Rect2(px - 6 * size_scale, py - 3 * size_scale, rect_w + 12 * size_scale, 6 * size_scale), roller_color, true)
			c.draw_circle(Vector2(px - 6 * size_scale, py), 3 * size_scale, C_GOLD)
			c.draw_circle(Vector2(px + rect_w + 6 * size_scale, py), 3 * size_scale, C_GOLD)
			
			c.draw_rect(Rect2(px - 6 * size_scale, py + rect_h - 3 * size_scale, rect_w + 12 * size_scale, 6 * size_scale), roller_color, true)
			c.draw_circle(Vector2(px - 6 * size_scale, py + rect_h), 3 * size_scale, C_GOLD)
			c.draw_circle(Vector2(px + rect_w + 6 * size_scale, py + rect_h), 3 * size_scale, C_GOLD)
			
			# Hanging string at top
			c.draw_line(Vector2(px + rect_w*0.2, py - 3*size_scale), Vector2(cx, py - 15*size_scale), C_RED_SON, 1.5 * size_scale)
			c.draw_line(Vector2(px + rect_w*0.8, py - 3*size_scale), Vector2(cx, py - 15*size_scale), C_RED_SON, 1.5 * size_scale)
			
			# Scroll background (aged silk paper)
			var paper_rect := Rect2(px, py, rect_w, rect_h)
			c.draw_rect(paper_rect, Color(0.94, 0.89, 0.74), true) # Aged silk
			c.draw_rect(paper_rect, C_GOLD, false, 1.2 * size_scale) # Thin gold border
			
			# Inner thin border
			c.draw_rect(Rect2(px + 4 * size_scale, py + 4 * size_scale, rect_w - 8 * size_scale, rect_h - 8 * size_scale), Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.2), false, 0.8 * size_scale)
			
			# Painting Content: Traditional female musician playing a flute/zither
			# 1. Stylized background: mountains (light gold-brown wash) & sun (red)
			var bg_sun_c := Vector2(cx + 12 * size_scale, cy - 20 * size_scale)
			c.draw_circle(bg_sun_c, 10.0 * size_scale, Color(0.68, 0.15, 0.15, 0.75)) # Red sun
			
			# Mountain silhouette
			var mount_pts := PackedVector2Array([
				Vector2(px + 6*size_scale, py + rect_h - 10*size_scale),
				Vector2(px + rect_w*0.35, cy + 15*size_scale),
				Vector2(px + rect_w*0.65, cy + 28*size_scale),
				Vector2(px + rect_w - 6*size_scale, py + rect_h - 10*size_scale)
			])
			c.draw_colored_polygon(mount_pts, Color(0.77, 0.58, 0.15, 0.25))
			
			# 2. Female figure silhouette/drawing (stylized Ao Dai player)
			var fig_x := cx - 8 * size_scale
			var fig_y := cy + 15 * size_scale
			# Ao Dai robe body (deep jade green / blue blend)
			var body_pts := PackedVector2Array([
				Vector2(fig_x - 10*size_scale, fig_y + 25*size_scale),
				Vector2(fig_x + 12*size_scale, fig_y + 25*size_scale),
				Vector2(fig_x + 4*size_scale, fig_y - 12*size_scale),
				Vector2(fig_x - 4*size_scale, fig_y - 12*size_scale)
			])
			c.draw_colored_polygon(body_pts, Color(0.09, 0.27, 0.18, 0.85)) # Jade Ao Dai
			c.draw_polyline(body_pts, C_GOLD, 0.8 * size_scale, true)
			
			# Head & Turban
			var head_c := Vector2(fig_x, fig_y - 20 * size_scale)
			c.draw_circle(head_c, 7.0 * size_scale, C_CREAM) # face
			c.draw_circle(head_c - Vector2(0, 2*size_scale), 7.5 * size_scale, Color(0.12, 0.12, 0.12)) # hair/turban
			c.draw_circle(head_c - Vector2(0, 4*size_scale), 8.5 * size_scale, Color(0.77, 0.58, 0.15)) # golden turban outer
			
			# Hands & Flute
			var flute_p1 := Vector2(fig_x - 14*size_scale, fig_y - 8*size_scale)
			var flute_p2 := Vector2(fig_x + 16*size_scale, fig_y - 14*size_scale)
			c.draw_line(flute_p1, flute_p2, Color(0.85, 0.65, 0.28), 2.2 * size_scale, true) # bamboo flute
			c.draw_circle(Vector2(fig_x - 2*size_scale, fig_y - 10*size_scale), 2.5 * size_scale, C_CREAM) # hands
			
			# Red Calligraphy Seal
			c.draw_rect(Rect2(px + 8*size_scale, py + rect_h - 22*size_scale, 8*size_scale, 8*size_scale), C_RED_SON, true)
			c.draw_rect(Rect2(px + 8*size_scale, py + rect_h - 22*size_scale, 8*size_scale, 8*size_scale), C_GOLD, false, 0.5 * size_scale)
			
			# Calligraphy Text (vertical abstract Nom script strokes)
			c.draw_line(Vector2(px + 10*size_scale, py + 12*size_scale), Vector2(px + 10*size_scale, py + 38*size_scale), Color(0.15, 0.12, 0.10, 0.85), 1.0 * size_scale)
			c.draw_line(Vector2(px + 14*size_scale, py + 15*size_scale), Vector2(px + 14*size_scale, py + 30*size_scale), Color(0.15, 0.12, 0.10, 0.75), 1.0 * size_scale)
			
		"vase":
			var stand_w := 60.0 * size_scale
			var stand_h := 82.0 * size_scale
			var px := cx - stand_w / 2
			var py := cy - stand_h / 2
			
			# Bounding stand base
			c.draw_rect(Rect2(px - 4*size_scale, py + stand_h - 8*size_scale, stand_w + 8*size_scale, 8*size_scale), Color(0.18, 0.10, 0.05), true)
			c.draw_rect(Rect2(px - 4*size_scale, py + stand_h - 8*size_scale, stand_w + 8*size_scale, 8*size_scale), C_GOLD, false, 1.0 * size_scale)
			
			# Left and Right Pillars (dark mahogany wood)
			var pillar_col := Color(0.24, 0.12, 0.06)
			c.draw_rect(Rect2(px, py + 12*size_scale, 6*size_scale, stand_h - 20*size_scale), pillar_col, true)
			c.draw_rect(Rect2(px, py + 12*size_scale, 6*size_scale, stand_h - 20*size_scale), C_GOLD, false, 0.8 * size_scale)
			
			c.draw_rect(Rect2(px + stand_w - 6*size_scale, py + 12*size_scale, 6*size_scale, stand_h - 20*size_scale), pillar_col, true)
			c.draw_rect(Rect2(px + stand_w - 6*size_scale, py + 12*size_scale, 6*size_scale, stand_h - 20*size_scale), C_GOLD, false, 0.8 * size_scale)
			
			# Curved Top Beam (Pagoda roof style silhouette)
			var roof_pts := PackedVector2Array([
				Vector2(px - 8*size_scale, py + 16*size_scale),
				Vector2(px, py + 6*size_scale),
				Vector2(cx, py + 4*size_scale),
				Vector2(px + stand_w, py + 6*size_scale),
				Vector2(px + stand_w + 8*size_scale, py + 16*size_scale),
				Vector2(px + stand_w + 2*size_scale, py + 16*size_scale),
				Vector2(cx, py + 10*size_scale),
				Vector2(px - 2*size_scale, py + 16*size_scale)
			])
			c.draw_colored_polygon(roof_pts, pillar_col)
			c.draw_polyline(roof_pts, C_GOLD, 1.2 * size_scale, true)
			
			# Hanging cords (red)
			var gong_center := Vector2(cx, py + stand_h * 0.52)
			c.draw_line(Vector2(cx - 10*size_scale, py + 10*size_scale), gong_center - Vector2(6*size_scale, 16*size_scale), C_RED_SON, 1.5 * size_scale)
			c.draw_line(Vector2(cx + 10*size_scale, py + 10*size_scale), gong_center + Vector2(6*size_scale, -16*size_scale), C_RED_SON, 1.5 * size_scale)
			
			# Bronze Gong (Chiêng Đồng)
			var gong_r := 19.0 * size_scale
			c.draw_circle(gong_center, gong_r, Color(0.68, 0.52, 0.22)) # Bronze body
			
			# Concentric rings & details on gong face
			c.draw_circle(gong_center, gong_r * 0.95, Color(0.58, 0.44, 0.16)) # Darker outer band
			c.draw_circle(gong_center, gong_r * 0.8, Color(0.68, 0.52, 0.22))
			c.draw_circle(gong_center, gong_r * 0.45, Color(0.58, 0.44, 0.16)) # Darker inner ring
			
			# Center Boss (Núm chiêng - raised hub)
			c.draw_circle(gong_center, gong_r * 0.24, Color(0.85, 0.68, 0.28)) # Bright gold center
			c.draw_circle(gong_center - Vector2(1, 1)*size_scale, gong_r * 0.12, Color.WHITE) # Specular shine
			
			# Fine gold rim line
			c.draw_arc(gong_center, gong_r - 0.5*size_scale, 0.0, TAU, 32, C_GOLD_LIGHT, 1.0 * size_scale)
			c.draw_arc(gong_center, gong_r * 0.6, 0.0, TAU, 24, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45), 0.8 * size_scale)
			
			# Mallet resting against stand
			var mallet_p1 := Vector2(cx + 14*size_scale, py + stand_h - 10*size_scale)
			var mallet_p2 := Vector2(cx + 26*size_scale, py + stand_h * 0.45)
			c.draw_line(mallet_p1, mallet_p2, Color(0.48, 0.32, 0.20), 2.2 * size_scale, true) # Stick
			c.draw_circle(mallet_p2, 4.5 * size_scale, C_RED_SON) # Red head mallet

		"bamboo":
			var rack_w := 70.0 * size_scale
			var rack_h := 100.0 * size_scale
			var px := cx - rack_w / 2
			var py := cy - rack_h / 2
			
			# Stand base pot/wood mount
			c.draw_rect(Rect2(px + 10*size_scale, py + rack_h - 10*size_scale, rack_w - 20*size_scale, 10*size_scale), Color(0.18, 0.14, 0.12), true)
			c.draw_rect(Rect2(px + 10*size_scale, py + rack_h - 10*size_scale, rack_w - 20*size_scale, 10*size_scale), C_GOLD, false, 1.0 * size_scale)
			
			# Two vertical support posts (bamboo structure)
			var post_col := Color(0.35, 0.22, 0.10)
			c.draw_rect(Rect2(px + 20*size_scale, py + 10*size_scale, 6*size_scale, rack_h - 20*size_scale), post_col, true)
			c.draw_rect(Rect2(px + 20*size_scale, py + 10*size_scale, 6*size_scale, rack_h - 20*size_scale), Color(0.50, 0.32, 0.16), false, 0.8 * size_scale)
			
			c.draw_rect(Rect2(px + rack_w - 26*size_scale, py + 10*size_scale, 6*size_scale, rack_h - 20*size_scale), post_col, true)
			c.draw_rect(Rect2(px + rack_w - 26*size_scale, py + 10*size_scale, 6*size_scale, rack_h - 20*size_scale), Color(0.50, 0.32, 0.16), false, 0.8 * size_scale)
			
			# Ornate shelf headers
			c.draw_line(Vector2(px + 14*size_scale, py + 15*size_scale), Vector2(px + rack_w - 14*size_scale, py + 15*size_scale), post_col, 4.0 * size_scale)
			c.draw_line(Vector2(px + 14*size_scale, py + 15*size_scale), Vector2(px + rack_w - 14*size_scale, py + 15*size_scale), C_GOLD, 0.8 * size_scale)
			
			# Draw 3 horizontal flutes with different colors and sizes
			var fl_colors := [
				Color(0.85, 0.65, 0.28), # Yellow bamboo
				Color(0.18, 0.44, 0.24), # Green fresh bamboo
				Color(0.36, 0.18, 0.08)  # Aged dark wood/bamboo
			]
			
			var fl_y_coords := [
				py + 30.0 * size_scale,
				py + 52.0 * size_scale,
				py + 74.0 * size_scale
			]
			
			var fl_widths := [
				68.0 * size_scale,
				58.0 * size_scale,
				62.0 * size_scale
			]
			
			var fl_thicknesses := [
				5.5 * size_scale,
				4.5 * size_scale,
				5.0 * size_scale
			]
			
			for i in range(3):
				var f_w : float = fl_widths[i]
				var f_y : float = fl_y_coords[i]
				var f_th : float = fl_thicknesses[i]
				var f_x1 := cx - f_w * 0.5
				var f_x2 := cx + f_w * 0.5
				
				# 1. Flute Body
				c.draw_line(Vector2(f_x1, f_y), Vector2(f_x2, f_y), fl_colors[i], f_th, true)
				c.draw_line(Vector2(f_x1, f_y), Vector2(f_x2, f_y), Color(1, 1, 1, 0.22), 1.0 * size_scale) # specular line
				
				# 2. Red thread wraps at ends
				c.draw_line(Vector2(f_x1, f_y), Vector2(f_x1 + 4*size_scale, f_y), C_RED_SON, f_th + 0.5*size_scale)
				c.draw_line(Vector2(f_x2 - 4*size_scale, f_y), Vector2(f_x2, f_y), C_RED_SON, f_th + 0.5*size_scale)
				
				# 3. Finger holes (tiny black dots)
				for h_idx in range(6):
					var hole_x = lerpf(f_x1 + f_w*0.3, f_x2 - f_w*0.2, float(h_idx)/5.0)
					c.draw_circle(Vector2(hole_x, f_y), 1.2 * size_scale, Color.BLACK)
				
				# 4. Lively swaying red tassels hanging from left end
				var sway := sin(_time * 2.5 + i * 1.2) * 6.0 * size_scale
				var tassel_start := Vector2(f_x1 + 2*size_scale, f_y)
				var tassel_end := tassel_start + Vector2(sway * 0.5, 18.0 * size_scale)
				
				c.draw_line(tassel_start, tassel_end, C_RED_SON, 1.2 * size_scale) # hanging string
				c.draw_circle(tassel_end, 2.5 * size_scale, C_GOLD) # bead
				
				# Fringes body
				var fringe_pts := PackedVector2Array([
					tassel_end,
					tassel_end + Vector2(sway - 2*size_scale, 14*size_scale),
					tassel_end + Vector2(sway + 2*size_scale, 14*size_scale)
				])
				c.draw_colored_polygon(fringe_pts, C_RED_SON)

		"bronze_drum":
			var dr_r := 36.0 * size_scale
			var dr_h := 50.0 * size_scale
			var drum_base_y := cy + 18 * size_scale
			
			# Wooden base platform
			c.draw_rect(Rect2(cx - dr_r * 1.15, drum_base_y, dr_r * 2.3, 10.0 * size_scale), Color(0.18, 0.10, 0.05), true)
			c.draw_rect(Rect2(cx - dr_r * 1.15, drum_base_y, dr_r * 2.3, 10.0 * size_scale), C_GOLD, false, 1.2 * size_scale)
			
			# Drum Body polygon (typical flared top, curved middle waist, and wider base)
			var body_pts := PackedVector2Array()
			var steps := 24
			for i in range(steps + 1):
				var t := float(i) / steps
				var py = drum_base_y - t * dr_h
				var w_fac = 1.0
				if t < 0.28:
					# Lower flare
					w_fac = lerpf(0.95, 0.76, t / 0.28)
				elif t < 0.72:
					# Curved waist
					var wt = (t - 0.28) / 0.44
					w_fac = 0.76 + (1.0 - 0.76) * sin(wt * PI) * 0.15 # waist dip
					if wt > 0.5:
						w_fac = lerpf(0.76, 0.96, (wt - 0.5) * 2.0)
				else:
					# Top flare
					w_fac = lerpf(0.96, 1.05, (t - 0.72) / 0.28)
				body_pts.append(Vector2(cx - dr_r * w_fac, py))
			for i in range(steps, -1, -1):
				var t := float(i) / steps
				var py = drum_base_y - t * dr_h
				var w_fac = 1.0
				if t < 0.28:
					w_fac = lerpf(0.95, 0.76, t / 0.28)
				elif t < 0.72:
					var wt = (t - 0.28) / 0.44
					w_fac = 0.76 + (1.0 - 0.76) * sin(wt * PI) * 0.15
					if wt > 0.5:
						w_fac = lerpf(0.76, 0.96, (wt - 0.5) * 2.0)
				else:
					w_fac = lerpf(0.96, 1.05, (t - 0.72) / 0.28)
				body_pts.append(Vector2(cx + dr_r * w_fac, py))
				
			c.draw_colored_polygon(body_pts, Color(0.48, 0.35, 0.20)) # Darker bronze base
			c.draw_polyline(body_pts, C_GOLD, 1.0 * size_scale, true)
			
			# Outer highlight / 3D shading
			c.draw_polyline(body_pts, Color(0.68, 0.52, 0.32, 0.65), 2.2 * size_scale, true)
			
			# Horizontal decorative bands on drum barrel
			for by_f in [0.22, 0.5, 0.78]:
				var dy = drum_base_y - dr_h * by_f
				c.draw_line(Vector2(cx - dr_r * 0.72, dy), Vector2(cx + dr_r * 0.72, dy), Color(0.68, 0.55, 0.35, 0.5), 1.5 * size_scale)
				
			# Side handles (2 pairs of double loops)
			var h_color := C_GOLD
			var h_y1 := drum_base_y - dr_h * 0.68
			var h_y2 := drum_base_y - dr_h * 0.42
			# Left double loops
			c.draw_line(Vector2(cx - dr_r * 0.8, h_y1), Vector2(cx - dr_r * 0.98, h_y1 + 4*size_scale), h_color, 2.0 * size_scale)
			c.draw_line(Vector2(cx - dr_r * 0.8, h_y2), Vector2(cx - dr_r * 0.98, h_y2 - 4*size_scale), h_color, 2.0 * size_scale)
			c.draw_line(Vector2(cx - dr_r * 0.98, h_y1 + 4*size_scale), Vector2(cx - dr_r * 0.98, h_y2 - 4*size_scale), h_color, 2.0 * size_scale)
			
			# Right double loops
			c.draw_line(Vector2(cx + dr_r * 0.8, h_y1), Vector2(cx + dr_r * 0.98, h_y1 + 4*size_scale), h_color, 2.0 * size_scale)
			c.draw_line(Vector2(cx + dr_r * 0.8, h_y2), Vector2(cx + dr_r * 0.98, h_y2 - 4*size_scale), h_color, 2.0 * size_scale)
			c.draw_line(Vector2(cx + dr_r * 0.98, h_y1 + 4*size_scale), Vector2(cx + dr_r * 0.98, h_y2 - 4*size_scale), h_color, 2.0 * size_scale)
			
			# Drumhead ellipse top
			var dh_center := Vector2(cx, drum_base_y - dr_h)
			var dh_rx := dr_r * 1.05
			var dh_ry := 11.5 * size_scale
			_draw_ellipse_poly(c, dh_center, dh_rx, dh_ry, Color(0.55, 0.42, 0.25))
			_draw_ellipse_line(c, dh_center, dh_rx, dh_ry, C_GOLD, 1.5 * size_scale)
			
			# Concentric rings on drumhead
			_draw_ellipse_line(c, dh_center, dh_rx * 0.82, dh_ry * 0.82, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.5), 0.8 * size_scale)
			_draw_ellipse_line(c, dh_center, dh_rx * 0.52, dh_ry * 0.52, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.5), 0.8 * size_scale)
			
			# Abstract Chim Lạc flying bird icons (little golden arcs) in the middle ring
			for deg in range(0, 360, 45):
				var rad := float(deg) * PI / 180.0
				var bird_pos := dh_center + Vector2(cos(rad) * dh_rx * 0.68, sin(rad) * dh_ry * 0.68)
				c.draw_arc(bird_pos, 2.8 * size_scale, PI * 0.85, PI * 1.85, 8, C_GOLD_LIGHT, 0.8 * size_scale)
			
			# Star/Sun motif in center (12-pointed star)
			var sun_glow_p := 0.25 + 0.15 * sin(_time * 4.0) # Pulsing glow value
			c.draw_circle(dh_center, 6.5 * size_scale, Color(C_GOLD_LIGHT.r, C_GOLD_LIGHT.g, C_GOLD_LIGHT.b, sun_glow_p))
			
			# 12 Points of the Star/Sun
			var star_pts := PackedVector2Array()
			var star_inner_r := 3.2 * size_scale
			var star_outer_r := 8.2 * size_scale
			for step in range(24):
				var angle := step * (TAU / 24.0)
				var r := star_outer_r if step % 2 == 0 else star_inner_r
				star_pts.append(dh_center + Vector2(cos(angle) * r, sin(angle) * r * (dh_ry / dh_rx)))
			c.draw_colored_polygon(star_pts, C_GOLD_LIGHT)
			c.draw_polyline(star_pts, Color.WHITE, 0.6 * size_scale, true)

func _open_shop_popup() -> void:
	if not shop_popup:
		_setup_shop_popup()
	_update_shop_items()
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
	overlay.color = Color(0.06, 0.04, 0.02, 0.75)
	shop_popup.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
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
	
	var title := Label.new()
	title.text = "🎨 CỬA HÀNG TRANG TRÍ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", C_RED_SON)
	if _font_title:
		title.add_theme_font_override("font", _font_title)
	scroll_content.add_child(title)
	
	var stars_label := Label.new()
	stars_label.name = "StarsLabel"
	stars_label.text = "Bạn có: ⭐ %d Sao" % SecureDataManager.get_total_stars()
	stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars_label.add_theme_font_size_override("font_size", 14)
	stars_label.add_theme_color_override("font_color", C_GOLD)
	if _font_body_bold:
		stars_label.add_theme_font_override("font", _font_body_bold)
	scroll_content.add_child(stars_label)
	
	var grid := GridContainer.new()
	grid.name = "Grid"
	grid.columns = 2
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 16)
	scroll_content.add_child(grid)
	
	var items = [
		{"id": "painting", "name": "Tranh Tố Nữ Cổ Phong", "cost": 3, "desc": "Tranh dân gian Hàng Trống phác họa thiếu nữ chơi nhạc cụ truyền thống."},
		{"id": "vase", "name": "Giá Treo Chiêng Đồng", "cost": 5, "desc": "Chiêng đồng cổ Tây Nguyên treo trên giá gỗ chạm khắc tinh xảo."},
		{"id": "bamboo", "name": "Kệ Sáo Trúc Nhã Nhạc", "cost": 8, "desc": "Giá treo các loại sáo trúc, tiêu với tua rua đỏ đung đưa sinh động."},
		{"id": "bronze_drum", "name": "Trống Đồng Đông Sơn", "cost": 12, "desc": "Báu vật âm nhạc cổ xưa với họa tiết mặt trời tỏa sáng linh thiêng."}
	]
	
	for item in items:
		var card := PanelContainer.new()
		card.name = "Card_" + item.id
		card.custom_minimum_size = Vector2(360, 150)
		var sb := _flat_sb(Color(0.98, 0.97, 0.94, 0.95), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.3), 10, true, 1.5)
		card.add_theme_stylebox_override("panel", sb)
		grid.add_child(card)
		
		var margin := MarginContainer.new()
		margin.name = "Margin"
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_bottom", 10)
		card.add_child(margin)
		
		var hbox := HBoxContainer.new()
		hbox.name = "HBox"
		hbox.add_theme_constant_override("separation", 16)
		margin.add_child(hbox)
		
		var preview := Control.new()
		preview.name = "Preview"
		preview.custom_minimum_size = Vector2(90, 110)
		preview.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox.add_child(preview)
		preview.draw.connect(_draw_decor_node.bind(preview, item.id))
		
		var vbox := VBoxContainer.new()
		vbox.name = "VBox"
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_theme_constant_override("separation", 6)
		hbox.add_child(vbox)
		
		var name_lbl := Label.new()
		name_lbl.text = item.name
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_color", C_RED_DK)
		if _font_body_bold:
			name_lbl.add_theme_font_override("font", _font_body_bold)
		vbox.add_child(name_lbl)
		
		var cost_lbl := Label.new()
		cost_lbl.name = "CostLabel"
		cost_lbl.text = "Yêu cầu: ⭐ %d Sao" % item.cost
		cost_lbl.add_theme_font_size_override("font_size", 13)
		cost_lbl.add_theme_color_override("font_color", C_GOLD)
		if _font_body_bold:
			cost_lbl.add_theme_font_override("font", _font_body_bold)
		vbox.add_child(cost_lbl)
		
		var desc_lbl := Label.new()
		desc_lbl.text = item.desc
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.add_theme_color_override("font_color", C_TEXT_MUTED)
		if _font_body:
			desc_lbl.add_theme_font_override("font", _font_body)
		vbox.add_child(desc_lbl)
		
		var btn := Button.new()
		btn.name = "BtnAction"
		btn.custom_minimum_size = Vector2(0, 36)
		vbox.add_child(btn)
		_style_popup_button(btn, true)
		_make_btn_bouncy(btn)
		
		btn.pressed.connect(_on_shop_action_pressed.bind(item.id, item.cost))
		
	var btn_close := Button.new()
	btn_close.text = "ĐÓNG"
	btn_close.custom_minimum_size = Vector2(180, 46)
	btn_close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_style_popup_button(btn_close, false)
	_make_btn_bouncy(btn_close)
	scroll_content.add_child(btn_close)
	
	btn_close.pressed.connect(func() -> void:
		_player_expression = "normal"
		var t := create_tween()
		t.tween_property(shop_popup, "modulate:a", 0.0, 0.2)
		t.tween_callback(func() -> void: shop_popup.visible = false)
	)

func _on_shop_action_pressed(item_id: String, cost: int) -> void:
	var unlocked = SecureDataManager.data.unlocked_decorations.has(item_id)
	if not unlocked:
		var success = SecureDataManager.unlock_decoration(item_id, cost)
		if success:
			_card_particle_timer = 999.0
			_update_shop_items()
			_update_star_badge()
			_spawn_decorations()
			_player_expression = "happy"
			get_tree().create_timer(1.2).timeout.connect(func(): _player_expression = "normal")
	else:
		SecureDataManager.toggle_decoration(item_id)
		_update_shop_items()
		_spawn_decorations()

func _update_shop_items() -> void:
	var stars = SecureDataManager.get_total_stars()
	var stars_label = shop_popup.get_node("ScrollPanel/ScrollContent/StarsLabel") as Label
	if stars_label:
		stars_label.text = "Bạn có: ⭐ %d Sao" % stars
		
	var items = ["painting", "vase", "bamboo", "bronze_drum"]
	for item_id in items:
		var card = shop_popup.get_node("ScrollPanel/ScrollContent/Grid/Card_" + item_id)
		if not card: continue
		
		var btn = card.get_node("Margin/HBox/VBox/BtnAction") as Button
		var unlocked = SecureDataManager.data.unlocked_decorations.has(item_id)
		var active = SecureDataManager.data.active_decorations.has(item_id)
		
		if not unlocked:
			btn.text = "MỞ KHÓA"
			var cost = 3
			match item_id:
				"painting": cost = 3
				"vase": cost = 5
				"bamboo": cost = 8
				"bronze_drum": cost = 12
				
			if stars >= cost:
				_style_popup_button(btn, true)
				btn.disabled = false
			else:
				_style_disabled_button(btn)
				btn.disabled = true
		else:
			btn.disabled = false
			if active:
				btn.text = "CẤT ĐI 📦"
				_style_popup_button(btn, false)
			else:
				btn.text = "TRƯNG BÀY ✨"
				_style_popup_button(btn, true)

func _style_disabled_button(btn: Button) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.16, 0.14, 0.12, 0.7) # Dark warm grey/brown
	s.border_color = Color(0.30, 0.26, 0.22, 0.4) # Subtle dark brown border
	s.border_width_left = 2; s.border_width_right = 2
	s.border_width_top = 2; s.border_width_bottom = 2
	s.corner_radius_top_left = 20; s.corner_radius_top_right = 20
	s.corner_radius_bottom_left = 20; s.corner_radius_bottom_right = 20
	btn.add_theme_stylebox_override("disabled", s)
	btn.add_theme_color_override("font_disabled_color", Color(0.43, 0.38, 0.33, 0.8)) # Grey text

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
