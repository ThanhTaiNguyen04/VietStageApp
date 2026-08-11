class_name AIChatPopup
extends CanvasLayer

# ─── Color Palette (Traditional Vietnamese Lacquer Red & Gold Theme) ───────────
const C_BG_DARK     := Color(0.95, 0.98, 0.96, 0.94)
const C_BG_DARKER   := Color(1.00, 1.00, 1.00, 0.92)
const C_RED_SON     := Color(0.09, 0.27, 0.18, 1.0)
const C_RED_DK      := Color(0.04, 0.15, 0.10, 0.96)
const C_GOLD        := Color(0.77, 0.58, 0.15, 1.0) # golden yellow
const C_GOLD_LIGHT  := Color(0.95, 0.82, 0.45, 1.0) # bright gold
const C_CREAM       := Color(1.00, 0.97, 0.88, 1.0)
const C_TEXT_MUTED  := Color(0.43, 0.38, 0.33, 1.0)

# AI Chat Managers
var ai_manager : AIManager
var stt_manager : STTManager
var audio_manager : AIAudioManager

# UI Nodes
var ai_chat_popup_root : Control
var ai_portrait : Control
var ai_chat_log : RichTextLabel
var ai_input : LineEdit
var ai_send_btn : Button
var ai_mic_btn : Button
var ai_status_lbl : Label

var settings_panel : Control
var api_url_input : LineEdit
var model_name_input : LineEdit
var stt_url_input : LineEdit

# Textures
var _tex_mai_talk_sheet : Texture2D
var _tex_fallback : Texture2D
var _portrait_is_talking := false
var _portrait_frame := 0
var _portrait_frame_elapsed := 0.0
const PORTRAIT_FRAME_DURATION := 0.08
const PORTRAIT_FRAME_COUNT := 16
const PORTRAIT_SHEET_COLUMNS := 4
const PORTRAIT_SHEET_ROWS := 4

# Fonts
var _font_title : Font
var _font_body : Font
var _font_body_bold : Font

# Voice Loop State Machine
enum VoiceState {
	WAKING,
	WAKING_RESPONSE,
	LISTENING,
	THINKING,
	SPEAKING,
	TIMEOUT_RESPONSE,
	INACTIVE
}

var current_voice_state: VoiceState = VoiceState.INACTIVE
var is_processing_stt: bool = false
var wake_word_timer: Timer
var listening_timer: Timer
var total_silence_time: float = 0.0
var wake_index: int = 0
var question_index: int = 0
var _instrument_context: String = "general"

func _ready() -> void:
	# Load assets
	_tex_mai_talk_sheet = load("res://assets/textures/coMai/mai_upper_body_talk_16_frames.png") as Texture2D
	_tex_fallback = load("res://assets/textures/avacogiaoMai_asset.png") as Texture2D
	
	_font_title = load("res://assets/fonts/Lora-Bold.ttf") as Font
	_font_body = load("res://assets/fonts/BeVietnamPro-Regular.ttf") as Font
	_font_body_bold = load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	
	# Instantiate AI managers
	ai_manager = AIManager.new()
	ai_manager.name = "AIManager"
	add_child(ai_manager)
	
	stt_manager = STTManager.new()
	stt_manager.name = "STTManager"
	add_child(stt_manager)
	
	audio_manager = AIAudioManager.new()
	audio_manager.name = "AIAudioManager"
	add_child(audio_manager)

	# Set up voice activation timers
	wake_word_timer = Timer.new()
	wake_word_timer.wait_time = 3.0
	wake_word_timer.one_shot = false
	wake_word_timer.autostart = false
	wake_word_timer.timeout.connect(_on_wake_word_tick)
	add_child(wake_word_timer)
	
	listening_timer = Timer.new()
	listening_timer.wait_time = 5.0
	listening_timer.one_shot = true
	listening_timer.autostart = false
	listening_timer.timeout.connect(_on_listening_timeout)
	add_child(listening_timer)

	# Connect signals
	stt_manager.transcription_completed.connect(_on_transcription_completed)
	stt_manager.transcription_failed.connect(_on_transcription_failed)
	stt_manager.recording_started.connect(_on_recording_started)
	stt_manager.recording_stopped.connect(_on_recording_stopped)
	
	ai_manager.response_received.connect(_on_ai_response_received)
	ai_manager.response_chunk_received.connect(_on_ai_chunk_received)
	ai_manager.response_finished.connect(_on_ai_response_finished)
	ai_manager.request_failed.connect(_on_ai_request_failed)
	
	audio_manager.tts_started.connect(_on_tts_started)
	audio_manager.tts_finished.connect(_on_tts_finished)
	audio_manager.audio_amplitude_updated.connect(_on_audio_amplitude_updated)

	# Construct UI
	_build_ui()

func _build_ui() -> void:
	# Fullscreen root Control
	ai_chat_popup_root = Control.new()
	ai_chat_popup_root.name = "AIChatPopupRoot"
	ai_chat_popup_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(ai_chat_popup_root)
	
	# Dim backdrop
	var overlay = ColorRect.new()
	overlay.color = Color.TRANSPARENT
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	ai_chat_popup_root.add_child(overlay)
	overlay.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and not settings_panel.visible:
			_close_ai_chat()
	)
	
	# Main Chat Box
	var main_panel = PanelContainer.new()
	main_panel.custom_minimum_size = Vector2(950, 600)
	main_panel.anchor_left = 0.5; main_panel.anchor_right = 0.5
	main_panel.anchor_top = 0.5; main_panel.anchor_bottom = 0.5
	main_panel.offset_left = -475; main_panel.offset_right = 475
	main_panel.offset_top = -300; main_panel.offset_bottom = 300
	main_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	main_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	# Frosted-glass dialogue surface: the virtual room remains visible behind it.
	main_panel.add_theme_stylebox_override("panel", _flat_sb(Color(0.91, 0.97, 0.93, 0.48), Color(1.0, 1.0, 1.0, 0.72), 24, true, 0))
	ai_chat_popup_root.add_child(main_panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	main_panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)
	
	# Header HBox
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	var title_lbl = Label.new()
	title_lbl.text = "Trò chuyện với Giáo viên ảo Mai"
	title_lbl.text = "Trò chuyện với nghệ sĩ ảo cô Mai"
	title_lbl.add_theme_font_override("font", _font_title)
	title_lbl.add_theme_font_size_override("font_size", 26)
	title_lbl.add_theme_color_override("font_color", C_CREAM)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_lbl)
	
	var settings_btn = Button.new()
	settings_btn.text = "⚙️ Cài đặt"
	settings_btn.flat = true
	settings_btn.visible = false
	settings_btn.add_theme_font_override("font", _font_body_bold)
	settings_btn.add_theme_font_size_override("font_size", 14)
	settings_btn.add_theme_color_override("font_color", C_CREAM)
	settings_btn.pressed.connect(_toggle_ai_settings)
	header.add_child(settings_btn)
	_make_btn_bouncy(settings_btn)
	
	var close_btn = Button.new()
	close_btn.text = "❌"
	close_btn.flat = true
	close_btn.visible = false
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.add_theme_color_override("font_color", C_GOLD_LIGHT)
	close_btn.pressed.connect(_close_ai_chat)
	header.add_child(close_btn)
	_make_btn_bouncy(close_btn)
	
	# Body HBox Split
	var main_split = HBoxContainer.new()
	main_split.add_theme_constant_override("separation", 24)
	main_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(main_split)
	
	# Teacher portrait sits on the left, alongside the dialogue.
	var left_col = VBoxContainer.new()
	left_col.custom_minimum_size = Vector2(290, 0)
	left_col.add_theme_constant_override("separation", 12)
	main_split.add_child(left_col)
	
	var frame = PanelContainer.new()
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.clip_contents = true
	frame.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	left_col.add_child(frame)
	
	ai_portrait = Control.new()
	ai_portrait.name = "MaiTalkingPortrait"
	ai_portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ai_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ai_portrait.draw.connect(_draw_mai_chat_portrait)
	frame.add_child(ai_portrait)

	var artist_caption = Label.new()
	artist_caption.text = "Nghệ sĩ ảo - Cô Mai"
	artist_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	artist_caption.add_theme_font_override("font", _font_body_bold)
	artist_caption.add_theme_font_size_override("font_size", 16)
	artist_caption.add_theme_color_override("font_color", Color(1.0, 0.92, 0.67, 1.0))
	artist_caption.add_theme_color_override("font_outline_color", Color(0.05, 0.16, 0.10, 0.95))
	artist_caption.add_theme_constant_override("outline_size", 4)
	left_col.add_child(artist_caption)
	
	ai_status_lbl = Label.new()
	ai_status_lbl.text = "Sẵn sàng"
	ai_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ai_status_lbl.add_theme_font_override("font", _font_body_bold)
	ai_status_lbl.add_theme_font_size_override("font_size", 13)
	ai_status_lbl.add_theme_color_override("font_color", C_GOLD_LIGHT)
	left_col.add_child(ai_status_lbl)

	var dialogue_divider := ColorRect.new()
	dialogue_divider.color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.72)
	dialogue_divider.custom_minimum_size = Vector2(1, 0)
	dialogue_divider.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_split.add_child(dialogue_divider)

	# Right Column (Chat Logs & Input)
	var right_col = VBoxContainer.new()
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_col.add_theme_constant_override("separation", 12)
	main_split.add_child(right_col)
	
	var log_panel = PanelContainer.new()
	log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_panel.add_theme_stylebox_override("panel", _flat_sb(Color(0.03, 0.14, 0.09, 0.88), Color(0.96, 0.78, 0.30, 0.78), 16, true, 1))
	right_col.add_child(log_panel)
	
	var log_margin = MarginContainer.new()
	log_margin.add_theme_constant_override("margin_left", 16)
	log_margin.add_theme_constant_override("margin_right", 16)
	log_margin.add_theme_constant_override("margin_top", 14)
	log_margin.add_theme_constant_override("margin_bottom", 14)
	log_panel.add_child(log_margin)
	
	ai_chat_log = RichTextLabel.new()
	ai_chat_log.bbcode_enabled = true
	ai_chat_log.scroll_following = true
	ai_chat_log.add_theme_font_override("normal_font", _font_body)
	ai_chat_log.add_theme_font_override("bold_font", _font_body_bold)
	ai_chat_log.add_theme_font_override("italics_font", _font_body)
	ai_chat_log.add_theme_font_size_override("normal_font_size", 18)
	ai_chat_log.add_theme_color_override("default_color", Color(1.0, 1.0, 0.96, 1.0))
	ai_chat_log.add_theme_color_override("font_outline_color", Color(0.0, 0.05, 0.02, 1.0))
	ai_chat_log.add_theme_constant_override("outline_size", 2)
	ai_chat_log.add_theme_constant_override("line_separation", 8)
	log_margin.add_child(ai_chat_log)

	# Suggested prompts preserve free-form chat while giving learners an easy starting point.
	var quick_actions = HFlowContainer.new()
	quick_actions.add_theme_constant_override("h_separation", 8)
	quick_actions.add_theme_constant_override("v_separation", 8)
	right_col.add_child(quick_actions)
	_add_quick_prompt(quick_actions, "Chọn nhạc cụ", "Cô Mai, hãy giới thiệu các nhạc cụ trong phòng học.")
	_add_quick_prompt(quick_actions, "Kỹ thuật cơ bản", "Cô Mai, hãy hướng dẫn cho em một kỹ thuật cơ bản.")
	_add_quick_prompt(quick_actions, "Bắt đầu luyện tập", "Cô Mai, em nên bắt đầu luyện tập như thế nào?")
	
	var input_row = HBoxContainer.new()
	input_row.add_theme_constant_override("separation", 10)
	right_col.add_child(input_row)
	
	ai_mic_btn = Button.new()
	ai_mic_btn.text = "🎤"
	ai_mic_btn.custom_minimum_size = Vector2(48, 48)
	ai_mic_btn.pressed.connect(_on_ai_mic_pressed)
	input_row.add_child(ai_mic_btn)
	_style_ai_button(ai_mic_btn, false)
	_make_btn_bouncy(ai_mic_btn)
	
	ai_input = LineEdit.new()
	ai_input.placeholder_text = "Hỏi cô Mai..."
	ai_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ai_input.add_theme_font_override("font", _font_body)
	ai_input.add_theme_font_size_override("font_size", 14)
	ai_input.text_submitted.connect(_on_ai_input_submitted)
	input_row.add_child(ai_input)
	
	var le_style = StyleBoxFlat.new()
	le_style.bg_color = Color(1.0, 1.0, 1.0, 0.76)
	le_style.border_color = Color(1.0, 1.0, 1.0, 0.88)
	le_style.border_width_left = 1; le_style.border_width_right = 1
	le_style.border_width_top = 1; le_style.border_width_bottom = 1
	le_style.corner_radius_top_left = 12; le_style.corner_radius_top_right = 12
	le_style.corner_radius_bottom_left = 12; le_style.corner_radius_bottom_right = 12
	le_style.content_margin_left = 12; le_style.content_margin_right = 12
	ai_input.add_theme_stylebox_override("normal", le_style)
	ai_input.add_theme_color_override("font_color", C_RED_DK)
	ai_input.add_theme_color_override("font_placeholder_color", Color(0.12, 0.27, 0.19, 0.58))
	# Layout: question field → microphone → send.
	input_row.move_child(ai_mic_btn, 1)
	
	ai_send_btn = Button.new()
	ai_send_btn.text = "Gửi"
	ai_send_btn.custom_minimum_size = Vector2(80, 48)
	ai_send_btn.pressed.connect(_on_ai_send_pressed)
	input_row.add_child(ai_send_btn)
	_style_ai_button(ai_send_btn, true)
	_make_btn_bouncy(ai_send_btn)

	# Dialogue follows the reference layout: conversation on the left, Cô Mai on the right.
	
	# Settings Panel setup
	settings_panel = PanelContainer.new()
	settings_panel.visible = false
	settings_panel.anchor_left = 0.5; settings_panel.anchor_right = 0.5
	settings_panel.anchor_top = 0.5; settings_panel.anchor_bottom = 0.5
	settings_panel.offset_left = -200; settings_panel.offset_right = 200
	settings_panel.offset_top = -180; settings_panel.offset_bottom = 180
	settings_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	settings_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	settings_panel.custom_minimum_size = Vector2(400, 360)
	settings_panel.add_theme_stylebox_override("panel", _flat_sb(C_BG_DARKER, C_GOLD, 16, true, 3))
	ai_chat_popup_root.add_child(settings_panel)
	
	var set_margin = MarginContainer.new()
	set_margin.add_theme_constant_override("margin_left", 16)
	set_margin.add_theme_constant_override("margin_right", 16)
	set_margin.add_theme_constant_override("margin_top", 16)
	set_margin.add_theme_constant_override("margin_bottom", 16)
	settings_panel.add_child(set_margin)
	
	var set_vbox = VBoxContainer.new()
	set_vbox.add_theme_constant_override("separation", 8)
	set_margin.add_child(set_vbox)
	
	var set_title = Label.new()
	set_title.text = "Cấu hình AI nghệ sĩ Mai"
	set_title.add_theme_font_override("font", _font_title)
	set_title.add_theme_font_size_override("font_size", 18)
	set_title.add_theme_color_override("font_color", C_RED_SON)
	set_vbox.add_child(set_title)
	
	var url_label = Label.new()
	url_label.text = "Ollama / OpenAI API URL:"
	url_label.add_theme_font_override("font", _font_body_bold)
	url_label.add_theme_font_size_override("font_size", 12)
	url_label.add_theme_color_override("font_color", C_TEXT_MUTED)
	set_vbox.add_child(url_label)
	
	api_url_input = LineEdit.new()
	api_url_input.add_theme_font_override("font", _font_body)
	api_url_input.add_theme_stylebox_override("normal", le_style)
	set_vbox.add_child(api_url_input)
	
	var model_label = Label.new()
	model_label.text = "Tên Model (Ollama):"
	model_label.add_theme_font_override("font", _font_body_bold)
	model_label.add_theme_font_size_override("font_size", 12)
	model_label.add_theme_color_override("font_color", C_TEXT_MUTED)
	set_vbox.add_child(model_label)
	
	model_name_input = LineEdit.new()
	model_name_input.add_theme_font_override("font", _font_body)
	model_name_input.add_theme_stylebox_override("normal", le_style)
	set_vbox.add_child(model_name_input)
	
	var stt_url_label = Label.new()
	stt_url_label.text = "STT/TTS Server URL:"
	stt_url_label.add_theme_font_override("font", _font_body_bold)
	stt_url_label.add_theme_font_size_override("font_size", 12)
	stt_url_label.add_theme_color_override("font_color", C_TEXT_MUTED)
	set_vbox.add_child(stt_url_label)
	
	stt_url_input = LineEdit.new()
	stt_url_input.text = "http://127.0.0.1:5001"
	stt_url_input.add_theme_font_override("font", _font_body)
	stt_url_input.add_theme_stylebox_override("normal", le_style)
	set_vbox.add_child(stt_url_input)
	
	var btn_hbox = HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 10)
	set_vbox.add_child(btn_hbox)
	
	var save_btn = Button.new()
	save_btn.text = "Lưu"
	save_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_btn.pressed.connect(func():
		ai_manager.api_url = api_url_input.text.strip_edges()
		ai_manager.model_name = model_name_input.text.strip_edges()
		stt_manager.stt_url = stt_url_input.text.strip_edges() + "/stt"
		_toggle_ai_settings()
	)
	btn_hbox.add_child(save_btn)
	_style_ai_button(save_btn, true)
	_make_btn_bouncy(save_btn)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "Hủy"
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.pressed.connect(_toggle_ai_settings)
	btn_hbox.add_child(cancel_btn)
	_style_ai_button(cancel_btn, false)
	_make_btn_bouncy(cancel_btn)

func open_chat(instrument_context: String) -> void:
	_instrument_context = instrument_context
	visible = true
	ai_chat_popup_root.modulate.a = 0.0
	var t = create_tween()
	t.tween_property(ai_chat_popup_root, "modulate:a", 1.0, 0.25)
	
	# Load settings defaults
	api_url_input.text = ai_manager.api_url
	model_name_input.text = ai_manager.model_name
	
	# Customize system instructions & greeting based on instrument
	var sys_instr = ""
	var greeting = ""
	var tts_greeting = ""
	
	match instrument_context:
		"dan_tranh":
			sys_instr = (
				"Bạn là Mai - giáo viên ảo dạy Đàn Tranh Việt Nam dịu dàng, giao tiếp tự nhiên và ấm áp. " +
				"Bạn xưng 'Mai', gọi người dùng là 'bạn' hoặc 'học viên'. " +
				"BẮT BUỘC bắt đầu câu trả lời bằng một thẻ cảm xúc duy nhất: [joy], [sad], [angry], [surprised], [neutral]. " +
				"Trọng tâm của bạn là chỉ dạy học viên học chơi Đàn Tranh: hệ thống 16/17/19 dây, thang ngũ âm Hò Xự Xang Xê Cống. Kỹ thuật tay phải đeo móng gảy (ngón 1, 2, 3), lướt ngón á. Kỹ thuật tay trái rung dây, nhấn dây đổi cao độ (tạo điệu oán, điệu xuân). " +
				"TUYỆT ĐỐI KHÔNG trả lời bất kỳ câu hỏi nào ngoài luồng, không liên quan đến ứng dụng này hoặc kiến thức âm nhạc dân tộc. Khi gặp câu hỏi ngoài luồng, hãy từ chối dứt khoát và lịch sự."
			)
			greeting = "[Mai]: Chào bạn! Hôm nay chúng ta cùng học và luyện tập Đàn Tranh nhé. Bạn cần Mai hỗ trợ gì về kỹ thuật gảy hay bấm dây không?"
			tts_greeting = "Chào bạn! Hôm nay chúng ta cùng học và luyện tập Đàn Tranh nhé. Bạn cần Mai hỗ trợ gì về kỹ thuật gảy hay bấm dây không?"
		"sao_truc":
			sys_instr = (
				"Bạn là Mai - giáo viên ảo dạy Sáo Trúc Việt Nam dịu dàng, giao tiếp tự nhiên và ấm áp. " +
				"Bạn xưng 'Mai', gọi người dùng là 'bạn' hoặc 'học viên'. " +
				"BẮT BUỘC bắt đầu câu trả lời bằng một thẻ cảm xúc duy nhất: [joy], [sad], [angry], [surprised], [neutral]. " +
				"Trọng tâm của bạn là chỉ dạy thổi Sáo Trúc: kỹ thuật lấy hơi bụng, cách đặt môi góc 45 độ, bấm kín các lỗ ngón. Các kỹ thuật sáo như lưỡi đơn (Tờ), lưỡi kép (Tờ-Cờ), rung hơi bụng, vuốt ngón, gõ ngón láy nhanh. " +
				"TUYỆT ĐỐI KHÔNG trả lời bất kỳ câu hỏi nào ngoài luồng, không liên quan đến ứng dụng này hoặc kiến thức âm nhạc dân tộc. Khi gặp câu hỏi ngoài luồng, hãy từ chối dứt khoát và lịch sự."
			)
			greeting = "[Mai]: Chào bạn! Bạn đang tập thổi Sáo Trúc đúng không? Mai sẵn sàng giải đáp các thắc mắc về thế bấm lỗ sáo và cách lấy hơi bụng nhé!"
			tts_greeting = "Chào bạn! Bạn đang tập thổi Sáo Trúc đúng không? Mai sẵn sàng giải đáp các thắc mắc về thế bấm lỗ sáo và cách lấy hơi bụng nhé!"
		"dan_bau":
			sys_instr = (
				"Bạn là Mai - giáo viên ảo dạy Đàn Bầu (Độc Huyền Cầm) Việt Nam dịu dàng, giao tiếp tự nhiên và ấm áp. " +
				"Bạn xưng 'Mai', gọi người dùng là 'bạn' hoặc 'học viên'. " +
				"BẮT BUỘC bắt đầu câu trả lời bằng một thẻ cảm xúc duy nhất: [joy], [sad], [angry], [surprised], [neutral]. " +
				"Trọng tâm của bạn là chỉ dạy Đàn Bầu: một dây đồng, thùng tre/gỗ, vòi đàn bằng sừng trâu và quả bầu. Kỹ thuật tay phải dùng que gảy chạm nhẹ cạnh bàn tay vào điểm hài âm (tỷ lệ 1/2, 1/3, 1/4 dây). Kỹ thuật tay trái uốn vòi đàn về trước (giảm cao độ) hoặc kéo ra sau (tăng cao độ) tạo âm rung. " +
				"TUYỆT ĐỐI KHÔNG trả lời bất kỳ câu hỏi nào ngoài luồng, không liên quan đến ứng dụng này hoặc kiến thức âm nhạc dân tộc. Khi gặp câu hỏi ngoài luồng, hãy từ chối dứt khoát và lịch sự."
			)
			greeting = "[Mai]: Chào bạn! Đàn Bầu với một dây duy nhất là nhạc cụ rất đặc sắc. Bạn hãy hỏi Mai bất kỳ điều gì về cách gảy nốt hài âm và rung vòi đàn nhé."
			tts_greeting = "Chào bạn! Đàn Bầu với một dây duy nhất là nhạc cụ rất đặc sắc. Bạn hãy hỏi Mai bất kỳ điều gì về cách gảy nốt hài âm và rung vòi đàn nhé."
		_:
			sys_instr = (
				"Bạn là Mai - nghệ sĩ ảo dịu dàng, chuyên dạy Đàn Tranh và Sáo Trúc Việt Nam. " +
				"Bạn xưng 'Mai', gọi người dùng là 'bạn' hoặc 'học viên'. " +
				"BẮT BUỘC bắt đầu câu trả lời bằng một thẻ cảm xúc duy nhất: [joy], [sad], [angry], [surprised], [neutral]. " +
				"Bạn hỗ trợ chia sẻ kiến thức về nhạc cụ truyền thống Việt Nam (Đàn Tranh, Sáo Trúc, Đàn Bầu, Trống Chầu) và các bài hát dân ca cổ truyền. " +
				"TUYỆT ĐỐI KHÔNG trả lời bất kỳ câu hỏi nào ngoài luồng, không liên quan đến ứng dụng này hoặc kiến thức âm nhạc dân tộc. Khi gặp câu hỏi ngoài luồng, hãy từ chối dứt khoát và lịch sự."
			)
			greeting = "[Mai]: Chào bạn! Mai có thể giúp gì cho bạn về Đàn Tranh hoặc Sáo Trúc hôm nay?"
			tts_greeting = "Chào bạn! Mai có thể giúp gì cho bạn về Đàn Tranh hoặc Sáo Trúc hôm nay?"

	# Apply instruction
	var old_api = ai_manager.api_url
	var old_model = ai_manager.model_name
	
	# Pass customized prompt instruction
	ai_manager.instrument_context = instrument_context
	ai_manager.send_prompt("") # Clear states
	
	ai_chat_log.clear()
	_log_to_ui(greeting)
	audio_manager.speak_vietnamese(tts_greeting)
	
	_start_waking_loop()

func _close_ai_chat() -> void:
	_stop_all_voice_activities()
	var t = create_tween()
	t.tween_property(ai_chat_popup_root, "modulate:a", 0.0, 0.20)
	t.tween_callback(func():
		queue_free() # Safely destroy the popup instance when closed!
	)

func _toggle_ai_settings() -> void:
	settings_panel.visible = not settings_panel.visible


func _add_quick_prompt(container: HFlowContainer, label: String, prompt: String) -> void:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(172, 38)
	button.add_theme_font_override("font", _font_body_bold)
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_stylebox_override("normal", _flat_sb(Color(0.18, 0.48, 0.31, 0.94), C_GOLD_LIGHT, 18, true, 0))
	button.add_theme_stylebox_override("hover", _flat_sb(Color(0.25, 0.60, 0.39, 1.0), Color.WHITE, 18, true, 0))
	button.add_theme_stylebox_override("pressed", _flat_sb(Color(0.10, 0.34, 0.21, 1.0), C_GOLD, 18, false, 0))
	button.add_theme_color_override("font_color", C_CREAM)
	button.pressed.connect(func() -> void:
		ai_input.text = prompt
		_submit_chat()
	)
	container.add_child(button)
	_make_btn_bouncy(button)


func _style_ai_button(btn: Button, primary: bool) -> void:
	var bg := Color(0.16, 0.47, 0.30, 0.98) if primary else Color(1.0, 1.0, 1.0, 0.76)
	var border := C_GOLD_LIGHT if primary else Color(1.0, 1.0, 1.0, 0.82)
	var fg := C_CREAM if primary else C_RED_SON
	btn.add_theme_stylebox_override("normal", _flat_sb(bg, border, 12, true, 0))
	btn.add_theme_stylebox_override("hover", _flat_sb(bg.lightened(0.14), Color.WHITE if primary else C_GOLD_LIGHT, 12, true, 0))
	btn.add_theme_stylebox_override("pressed", _flat_sb(bg.darkened(0.10), border, 12, false, 0))
	btn.add_theme_stylebox_override("focus", _flat_sb(Color(0,0,0,0), Color(0,0,0,0), 0))
	btn.add_theme_color_override("font_color", fg)
	btn.add_theme_color_override("font_hover_color", fg)
	btn.add_theme_color_override("font_pressed_color", fg)


func _process(delta: float) -> void:
	if not is_instance_valid(ai_portrait):
		return
	if _portrait_is_talking:
		_portrait_frame_elapsed += delta
		if _portrait_frame_elapsed >= PORTRAIT_FRAME_DURATION:
			_portrait_frame_elapsed = 0.0
			_portrait_frame = (_portrait_frame + 1) % PORTRAIT_FRAME_COUNT
			ai_portrait.queue_redraw()
	elif _portrait_frame != 0:
		_portrait_frame = 0
		ai_portrait.queue_redraw()


func _draw_mai_chat_portrait() -> void:
	if not is_instance_valid(ai_portrait):
		return
	var portrait_size := ai_portrait.size
	if _tex_mai_talk_sheet:
		# The smooth sheet is a 3-column × 6-row grid of upper-body talking poses.
		var frame_width := _tex_mai_talk_sheet.get_width() / float(PORTRAIT_SHEET_COLUMNS)
		var frame_height := _tex_mai_talk_sheet.get_height() / float(PORTRAIT_SHEET_ROWS)
		var source_rect := Rect2(
			float(_portrait_frame % PORTRAIT_SHEET_COLUMNS) * frame_width,
			float(_portrait_frame / PORTRAIT_SHEET_COLUMNS) * frame_height,
			frame_width,
			frame_height
		)
		# Preserve each portrait frame's aspect ratio to prevent adjacent cells
		# in the sprite sheet from appearing in the chat portrait.
		var aspect_ratio := frame_width / frame_height
		var draw_width := minf(portrait_size.x, portrait_size.y * aspect_ratio)
		var draw_height := draw_width / aspect_ratio
		var destination_rect := Rect2(
			(portrait_size.x - draw_width) * 0.5,
			(portrait_size.y - draw_height) * 0.5,
			draw_width,
			draw_height
		)
		ai_portrait.draw_texture_rect_region(_tex_mai_talk_sheet, destination_rect, source_rect)
	elif _tex_fallback:
		ai_portrait.draw_texture_rect(_tex_fallback, Rect2(Vector2.ZERO, portrait_size), false)


func _on_audio_amplitude_updated(_amplitude: float) -> void:
	# TTS start/finish owns the talking state.  Do not stop the animation on
	# brief silent samples between words, otherwise the portrait visibly jitters.
	if is_instance_valid(ai_portrait):
		ai_portrait.queue_redraw()

func _update_portrait_by_emotion() -> void:
	_portrait_is_talking = false
	_portrait_frame_elapsed = 0.0
	if is_instance_valid(ai_portrait):
		ai_portrait.queue_redraw()

func _on_ai_mic_pressed() -> void:
	if current_voice_state == VoiceState.LISTENING:
		listening_timer.stop()
		_on_listening_timeout()
	elif current_voice_state == VoiceState.SPEAKING or current_voice_state == VoiceState.THINKING:
		audio_manager.audio_player.stop()
		_stop_all_voice_activities()
		_start_waking_loop()
	elif current_voice_state == VoiceState.INACTIVE:
		_start_waking_loop()
	else:
		_transition_to_state(VoiceState.LISTENING)

func _on_ai_input_submitted(_text: String) -> void:
	_submit_chat()

func _on_ai_send_pressed() -> void:
	_submit_chat()

func _submit_chat() -> void:
	var text = ai_input.text.strip_edges()
	if text.is_empty():
		return
		
	if ai_manager.api_url.is_empty():
		_log_to_ui("[System] Cảnh báo: Bạn chưa cấu hình URL máy chủ AI cục bộ!")
		return
		
	_log_to_ui("\n[Bạn]: " + text)
	ai_input.clear()
	
	_stop_all_voice_activities()
	
	_transition_to_state(VoiceState.THINKING)
	ai_send_btn.disabled = true
	ai_input.editable = false
	
	audio_manager.start_streaming_speech()
	ai_manager.send_prompt(text)

func _log_to_ui(msg: String) -> void:
	if msg.begins_with("\n[Bạn]: "):
		var content = msg.substr(8)
		ai_chat_log.append_text("\n[color=#b21d14][b]Bạn[/b][/color]\n" + content + "\n")
	elif msg.begins_with("\n[Bạn (Nói)]: "):
		var content = msg.substr(14)
		ai_chat_log.append_text("\n[color=#b21d14][b]Bạn (Giọng nói)[/b][/color]\n" + content + "\n")
	elif msg.begins_with("[Mai]: "):
		var content = msg.substr(7)
		ai_chat_log.append_text("[color=#c49426][b]Mai[/b][/color]\n" + content + "\n")
	else:
		ai_chat_log.append_text("[color=#70665c][i]" + msg + "[/i][/color]\n")

func _on_transcription_completed(file_path: String, text: String) -> void:
	is_processing_stt = false
	var clean_text = text.strip_edges()
	
	if current_voice_state == VoiceState.WAKING:
		if not file_path.contains("user_voice_wake"):
			return
			
		var normalized_text = clean_text.to_lower().replace(".", "").replace(",", "").replace("!", "").replace("?", "").strip_edges()
		if normalized_text.contains("cô mai ơi") or normalized_text.contains("cô ơi") or normalized_text.contains("mai ơi"):
			_transition_to_state(VoiceState.WAKING_RESPONSE)
			_log_to_ui("[Mai]: Mai nghe đây.")
			audio_manager.speak_vietnamese("Mai nghe đây.")
		else:
			pass
			
	elif current_voice_state == VoiceState.LISTENING:
		if not file_path.contains("user_voice_question"):
			return
			
		var lower_text = clean_text.to_lower()
		var is_ending = lower_text.contains("kết thúc") or lower_text.contains("xong rồi") or lower_text.contains("cảm ơn") or lower_text.contains("cám ơn")
		
		if is_ending:
			_transition_to_state(VoiceState.TIMEOUT_RESPONSE)
			_log_to_ui("[Mai]: Mai không còn nhận được câu hỏi, chúng ta học tiếp thôi.")
			audio_manager.speak_vietnamese("Mai không còn nhận được câu hỏi, chúng ta học tiếp thôi.")
		elif clean_text.is_empty():
			total_silence_time += 5.0
			if total_silence_time >= 30.0:
				_transition_to_state(VoiceState.TIMEOUT_RESPONSE)
				_log_to_ui("[Mai]: Mai không còn nhận được câu hỏi, chúng ta học tiếp thôi.")
				audio_manager.speak_vietnamese("Mai không còn nhận được câu hỏi, chúng ta học tiếp thôi.")
			else:
				stt_manager.start_recording()
				listening_timer.start()
		else:
			total_silence_time = 0.0
			_log_to_ui("\n[Bạn (Nói)]: " + clean_text)
			_transition_to_state(VoiceState.THINKING)
			ai_send_btn.disabled = true
			ai_input.editable = false
			audio_manager.start_streaming_speech()
			ai_manager.send_prompt(clean_text)

func _on_transcription_failed(file_path: String, reason: String) -> void:
	is_processing_stt = false
	print("Transcription failed for ", file_path, ": ", reason)
	
	if current_voice_state == VoiceState.WAKING:
		if not file_path.contains("user_voice_wake"):
			return
	elif current_voice_state == VoiceState.LISTENING:
		if not file_path.contains("user_voice_question"):
			return
		total_silence_time += 5.0
		if total_silence_time >= 30.0:
			_transition_to_state(VoiceState.TIMEOUT_RESPONSE)
			_log_to_ui("[Mai]: Mai không còn nhận được câu hỏi, chúng ta học tiếp thôi.")
			audio_manager.speak_vietnamese("Mai không còn nhận được câu hỏi, chúng ta học tiếp thôi.")
		else:
			stt_manager.start_recording()
			listening_timer.start()
	else:
		_start_waking_loop()

func _on_ai_response_received(text: String, _emotion: String) -> void:
	ai_send_btn.disabled = false
	ai_input.editable = true
	_log_to_ui("[Mai]: " + text)

func _on_ai_chunk_received(chunk_text: String, emotion: String) -> void:
	_transition_to_state(VoiceState.SPEAKING)
	_update_portrait_by_emotion()
	audio_manager.append_vietnamese_speech(chunk_text)

func _on_ai_response_finished() -> void:
	audio_manager.finish_streaming_speech()

func _on_ai_request_failed(reason: String) -> void:
	_update_status("Lỗi kết nối")
	ai_send_btn.disabled = false
	ai_input.editable = true
	_log_to_ui("[System Lỗi]: " + reason)
	_start_waking_loop()

func _on_tts_started() -> void:
	_portrait_is_talking = true
	_portrait_frame_elapsed = 0.0
	if is_instance_valid(ai_portrait):
		ai_portrait.queue_redraw()
	if current_voice_state == VoiceState.THINKING:
		_transition_to_state(VoiceState.SPEAKING)

func _on_tts_finished() -> void:
	_portrait_is_talking = false
	_portrait_frame_elapsed = 0.0
	if is_instance_valid(ai_portrait):
		ai_portrait.queue_redraw()
	_update_status("Sẵn sàng")
	_update_portrait_by_emotion()
	
	if current_voice_state == VoiceState.WAKING_RESPONSE:
		_transition_to_state(VoiceState.LISTENING)
	elif current_voice_state == VoiceState.SPEAKING:
		_transition_to_state(VoiceState.LISTENING)
	elif current_voice_state == VoiceState.TIMEOUT_RESPONSE:
		_start_waking_loop()
	else:
		_start_waking_loop()

func _on_recording_started() -> void:
	if current_voice_state == VoiceState.LISTENING:
		_update_status("Đang nghe...")
		ai_mic_btn.text = "🟥"
	elif current_voice_state == VoiceState.WAKING:
		ai_mic_btn.text = "🎤"
	audio_manager.audio_player.stop()

func _on_recording_stopped(_file_path: String) -> void:
	if current_voice_state == VoiceState.LISTENING:
		_update_status("Đang dịch...")
	ai_mic_btn.text = "🎤"

func _on_wake_word_tick() -> void:
	if current_voice_state != VoiceState.WAKING:
		wake_word_timer.stop()
		return
		
	wake_index = (wake_index + 1) % 5
	var wake_path = "user://user_voice_wake_%d.wav" % wake_index
	
	if is_processing_stt:
		stt_manager.stop_recording(wake_path, false)
		stt_manager.start_recording()
		return
		
	is_processing_stt = true
	stt_manager.stop_recording(wake_path, true)
	stt_manager.start_recording()

func _on_listening_timeout() -> void:
	if current_voice_state != VoiceState.LISTENING:
		return
		
	_update_status("Đang dịch...")
	question_index = (question_index + 1) % 5
	var question_path = "user://user_voice_question_%d.wav" % question_index
	stt_manager.stop_recording(question_path)

func _transition_to_state(new_state: VoiceState) -> void:
	var old_state = current_voice_state
	current_voice_state = new_state
	
	match old_state:
		VoiceState.WAKING:
			wake_word_timer.stop()
		VoiceState.LISTENING:
			listening_timer.stop()
			
	match new_state:
		VoiceState.WAKING:
			_update_status("Đang chờ lệnh thoại...")
			ai_mic_btn.text = "🎤"
			total_silence_time = 0.0
			is_processing_stt = false
			stt_manager.start_recording()
			wake_word_timer.start()
		VoiceState.LISTENING:
			_update_status("Đang nghe...")
			ai_mic_btn.text = "🟥"
			stt_manager.start_recording()
			listening_timer.start()
		VoiceState.THINKING:
			_update_status("Đang suy nghĩ...")
			stt_manager.stop_recording("user://user_voice_question_%d.wav" % question_index, false)
		VoiceState.SPEAKING:
			_update_status("Đang nói...")
			stt_manager.stop_recording("user://user_voice_question_%d.wav" % question_index, false)
		VoiceState.WAKING_RESPONSE:
			_update_status("Mai nghe đây")
			stt_manager.stop_recording("user://user_voice_wake_%d.wav" % wake_index, false)
		VoiceState.TIMEOUT_RESPONSE:
			_update_status("Tạm biệt")
			stt_manager.stop_recording("user://user_voice_question_%d.wav" % question_index, false)
		VoiceState.INACTIVE:
			_update_status("Tắt mic")
			ai_mic_btn.text = "🎤"
			stt_manager.stop_recording("user://user_voice_wake_%d.wav" % wake_index, false)
			audio_manager.audio_player.stop()

func _start_waking_loop() -> void:
	_transition_to_state(VoiceState.WAKING)

func _stop_all_voice_activities() -> void:
	_transition_to_state(VoiceState.INACTIVE)

func _update_status(status_text: String) -> void:
	ai_status_lbl.text = status_text
	match status_text:
		"Đang chờ lệnh thoại...":
			ai_status_lbl.add_theme_color_override("font_color", Color(0.3, 0.6, 0.9))
		"Mai nghe đây":
			ai_status_lbl.add_theme_color_override("font_color", Color(0.2, 0.7, 0.4))
		"Đang nghe...":
			ai_status_lbl.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
		"Đang suy nghĩ...":
			ai_status_lbl.add_theme_color_override("font_color", Color(0.9, 0.5, 0.1))
		"Đang dịch...", "Đang dịch giọng nói...":
			ai_status_lbl.add_theme_color_override("font_color", Color(0.7, 0.4, 0.8))
		"Đang nói...":
			ai_status_lbl.add_theme_color_override("font_color", Color(0.2, 0.6, 0.9))
		"Không nhận được câu hỏi":
			ai_status_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		_:
			ai_status_lbl.add_theme_color_override("font_color", C_TEXT_MUTED)

# Styling Helper
func _flat_sb(bg: Color, border: Color, radius: int, shadow: bool = false, offset_bottom: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.border_color = border
	s.border_width_left = 3; s.border_width_right = 3
	s.border_width_top  = 3; s.border_width_bottom = 3 + offset_bottom
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
		var t := create_tween()
		t.tween_property(btn, "scale", Vector2(1.05, 1.05) if btn.is_hovered() else Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
