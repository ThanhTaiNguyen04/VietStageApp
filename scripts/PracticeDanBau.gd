extends Control
class_name PracticeDanBau

# ─── Color Palette ─────────────────────────────────────────────────────────────
const C_GOLD       := Color("#d4af37") # Metallic gold accent
const C_GOLD_LIGHT := Color("#f3d55b") # Light Golden highlight
const C_GOLD_TEXT  := Color("#8c6613") # Dark Bronze Gold for labels
const C_JADE       := Color("#0e3d26") # Deep Forest Green
const C_RED_SON    := Color("#b22222") # Deep lacquer red
const C_CREAM      := Color("#faf6eb") # Warm Light Cream
const C_CREAM_DIM  := Color("#ede7da") # Sidebar/Header Cream
const C_GREEN_OK   := Color("#27ae60") # Rich Green for success states
const C_WARN       := Color("#b5882b") # Warm Amber for warning states
const C_RED_ERR    := Color("#a82b2b") # Ruby Red for error states

const C_BG         := Color("#faf6eb") # Main Background (Soft Cream)
const C_BG_BAR     := Color("#ede7da") # Sidebar/Header/Footer (Darker Cream)
const C_CARD       := Color("#f6f2e5") # Stats Panel Background (Warm Card Cream)
const C_TEXT       := Color("#2b2b2b") # Dark charcoal for text
const C_TEXT_MUTED := Color("#595959") # Gray text
const C_GREEN_JADE := Color("#2e8b57") # Jade green

# ─── @onready ─────────────────────────────────────────────────────────────────
@onready var linh_panel        : PanelContainer = $Root/MiddleRow/LinhPanel
@onready var char_linh         : TextureRect    = $Root/MiddleRow/LinhPanel/LinhVBox/CharLinhWrapper/CharLinh
@onready var speech_label      : Label          = $Root/MiddleRow/LinhPanel/LinhVBox/SpeechBubble/SpeechM/SpeechLabel
@onready var lesson_bar        : ProgressBar    = $SettingsPanel/SettingsM/SettingsVBox/ProgressVBox/LessonBar
# TopBar chips (Simply Piano layout)
@onready var pitch_note        : Label          = $Root/TopBar/TopM/TopH/PitchChip/PitchNote
@onready var pitch_status      : Label          = $Root/TopBar/TopM/TopH/PitchChip/PitchStatus
@onready var score_num         : Label          = $Root/TopBar/TopM/TopH/ScoreChip/ScoreNum
@onready var falling_notes : Control = $Root/MiddleRow/MainContent/FallingNotesLayer
@onready var song_player : Node = $Root/MiddleRow/MainContent/SongPlayer
@onready var target_label      : Label          = $Root/StringsBoard/BoardM/BoardHBox/BoardVBox/TargetLabel
@onready var dots_hbox         : HBoxContainer  = $SettingsPanel/SettingsM/SettingsVBox/DotsHBox
@onready var _board            : Control        = $Root/StringsBoard/BoardM/BoardHBox/BoardVBox/DanBauBoard
@onready var record_btn        : Button         = $Root/RecordBar/RecordM/RecordH/RecordBtn



# ─── State ────────────────────────────────────────────────────────────────────
var _recording   := false
var _mic_mode    := true
var _score       := 75.0
var _sim_timer   := 0.0
var _correct_pitch_hold_time := 0.0
var _float_tween : Tween
var _note_idx    := 0
var _string_streams: Array[AudioStreamWAV] = []
# ── Sample-based playback: base WAV + pitch ratio per note ──
# Measured fundamental of dan_bau.wav recording (FFT analysis: ~379 Hz ≈ G4-)
const BASE_SAMPLE_FREQ: float = 379.0
var _base_wav: AudioStreamWAV = null
var _current_playing_idx: int = 0   # tracks which note index is currently active
var _active_player : AudioStreamPlayer = null
var _rec_tween   : Tween
var _detected_notes_history: Array[String] = []
const HISTORY_SIZE := 8
var _teacher_tip_timer := 0.0
var _current_bend_cents := 0.0
var _eval_cooldown := 0.0
var _linh_collapsed := true
var linh_mini_btn : Button
var _collapse_timer : SceneTreeTimer = null
var _demo_active := false
var _demo_tween : Tween = null

# AI Analysis tracking variables
var _practice_time := 0.0
var _detected_onsets : PackedFloat32Array = PackedFloat32Array()
var _reference_onsets : PackedFloat32Array = PackedFloat32Array()
var _pitch_scores : Array[float] = []
var _tone_scores : Array[float] = []

const NOTES_VN : Array[String] = ["Đố", "Sol", "Mi", "Đô", "Sol", "Đồ"]
static var current_song_title := ""
static var current_song_sheet : Array[String] = []

var sheet_notes : Array[String] = ["Đồ","Sol","Đồ","Đô","Sol","Đô","Mi","Đô","Sol","Sol","Đô","Mi","Đô","Sol","Đồ","Đô","Đồ"]
const SPEECHES : Array[String] = [
	"Gảy vào nốt hài âm trên dây,\nnhấn cần đàn trái để uốn cao độ.",
	"Rất tốt!\nUốn cần đàn đều tay hơn nữa.",
	"Cao độ chuẩn âm sắc truyền thống,\ntiếp tục nào.",
	"Tiếng bầu ngân nga mềm mại,\nnhịp điệu rất đẹp.",
]
func _ready() -> void:
	# Setup collapsible LinhPanel system
	_setup_collapsible_linh()
	
	if current_song_title != "":
		sheet_notes = current_song_sheet
	elif SecureDataManager.active_lesson_id.begins_with("dan_bau_coban_"):
		var clean_id := SecureDataManager.active_lesson_id.replace("_practice", "").replace("_video", "")
		var idx := int(clean_id.replace("dan_bau_coban_", ""))
		if idx == 1 or idx == 2:
			sheet_notes = ["Đồ", "Đồ", "Đồ", "Đồ"]
		elif idx == 3:
			sheet_notes = ["Đồ", "Đô", "Mi", "Đô", "Mi", "Đồ"]
		elif idx == 4:
			sheet_notes = ["Đồ", "Đô", "Đồ", "Đô"]
		elif idx == 5:
			sheet_notes = ["Đồ", "Đô", "Mi", "Sol", "Sol", "Mi", "Đô", "Sol", "Mi", "Đô", "Đồ"]
	_generate_streams()
	_set_labels()
	_build_theme()
	_build_board()
	_build_dots()
	if falling_notes: falling_notes.note_hit.connect(_on_falling_note_hit)
	_start_float()
	_connect_buttons()
	
	resized.connect(_on_resized)
	_on_resized()
	# Removed duplicate _setup_collapsible_linh() call
	# Removed char_linh.get_parent().visible = false because collapsible system handles it
	
	# Check mic permission
	if not ProjectSettings.get_setting("audio/driver/enable_input"):
		var mic_dialog := AcceptDialog.new()
		mic_dialog.title = "Cảnh Báo Thiết Bị"
		mic_dialog.dialog_text = "Ứng dụng chưa được cấp quyền truy cập Microphone hoặc tính năng Audio Input bị vô hiệu hóa trong cài đặt.\n\nVui lòng kiểm tra lại thiết bị thu âm để thực hiện bài học."
		var dialog_style := _flat(C_BG_BAR, C_GOLD, 16)
		mic_dialog.add_theme_stylebox_override("panel", dialog_style)
		mic_dialog.add_theme_color_override("title_color", C_RED_SON)
		add_child(mic_dialog)
		mic_dialog.popup_centered()
	
	# Dynamically insert premium microphone waveform visualizer
	var record_hbox := $Root/RecordBar/RecordM/RecordH
	var analyzer_script := load("res://scripts/AudioCaptureAnalyzer.gd")
	if record_hbox and analyzer_script:
		var visualizer := Control.new()
		visualizer.name = "WaveformVisualizer"
		visualizer.custom_minimum_size = Vector2(320, 62)
		visualizer.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		visualizer.set_script(analyzer_script)
		visualizer.min_frequency = 150.0
		visualizer.max_frequency = 800.0
		visualizer.volume_threshold_db = -32.0
		visualizer.visible = false
		record_hbox.add_child(visualizer)
		record_hbox.move_child(visualizer, 1)
		
		# Programmatic Mode Toggle Button
		var ctrl_btns = get_node_or_null("../SettingsPanel/SettingsM/SettingsVBox/CtrlBtns")
		var mode_btn := Button.new()
		mode_btn.name = "ModeToggleBtn"
		mode_btn.text = "Chế độ: Micro 🎙️"
		mode_btn.custom_minimum_size = Vector2(0, 48)
		if ctrl_btns:
			ctrl_btns.add_child(mode_btn)
			_style_sidebar_btn(mode_btn)
			_make_button_bouncy(mode_btn)
			
		mode_btn.pressed.connect(func() -> void:
			_mic_mode = not _mic_mode
			if _mic_mode:
				mode_btn.text = "Chế độ: Micro 🎙️"
				_va_say("Đã chuyển sang Chế độ luyện tập qua Micro.")
			else:
				mode_btn.text = "Chế độ: Chạm 📱"
				_va_say("Đã chuyển sang Chế độ tự học qua màn hình chạm.")
		)

		# REC indicator
		var rec_indicator := HBoxContainer.new()
		rec_indicator.name = "RecIndicator"
		rec_indicator.alignment = BoxContainer.ALIGNMENT_CENTER
		rec_indicator.visible = false
		
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(12, 12)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var dot_style := StyleBoxFlat.new()
		dot_style.bg_color = C_RED_SON
		dot_style.corner_radius_top_left = 6; dot_style.corner_radius_top_right = 6
		dot_style.corner_radius_bottom_left = 6; dot_style.corner_radius_bottom_right = 6
		dot.add_theme_stylebox_override("panel", dot_style)
		
		var lbl := Label.new()
		lbl.text = "REC"
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", C_RED_SON)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		rec_indicator.add_child(dot)
		rec_indicator.add_child(lbl)
		rec_indicator.add_theme_constant_override("separation", 6)
		rec_indicator.custom_minimum_size = Vector2(60, 30)
		
		record_hbox.add_child(rec_indicator)
		record_hbox.move_child(rec_indicator, 2)
		
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.35)

	# Setup interactive teacher to open AI chat
	char_linh.mouse_filter = Control.MOUSE_FILTER_STOP
	char_linh.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			var chat = AIChatPopup.new()
			add_child(chat)
			chat.open_chat("dan_bau")
	)

func _process(delta: float) -> void:
	if _recording:
		_practice_time += delta
		if _mic_mode:
			_process_real_audio(delta)
		else:
			_sim_timer += delta
			if _sim_timer >= 1.2:
				_sim_timer = 0.0
				_simulate_tick()

# ─── Labels & Details ─────────────────────────────────────────────────────────
func _set_labels() -> void:
	($Root/TopBar/TopM/TopH/BackBtn    as Button).text = "Quay lại"
	
	var diff := "Cơ bản"
	if SecureDataManager.active_lesson_id == "Node3":
		diff = "Trung bình"
	elif SecureDataManager.active_lesson_id == "Node4":
		diff = "Nâng cao"
	elif SecureDataManager.active_lesson_id.begins_with("dan_bau_coban_"):
		var clean_id := SecureDataManager.active_lesson_id.replace("_practice", "").replace("_video", "")
		var idx := int(clean_id.replace("dan_bau_coban_", ""))
		diff = "Bài %d" % idx
		
	var title_lbl := "Lòng Mẹ - Y Vân"
	if current_song_title != "":
		title_lbl = current_song_title
		diff = "Bài hát"
	else:
		if SecureDataManager.active_lesson_id.begins_with("dan_bau_coban_"):
			var clean_id := SecureDataManager.active_lesson_id.replace("_practice", "").replace("_video", "")
			var idx := int(clean_id.replace("dan_bau_coban_", ""))
			title_lbl = "Đàn Bầu Cơ Bản %d" % idx
		elif SecureDataManager.active_lesson_id == "Node2":
			title_lbl = "Hài Âm Cơ Bản"
		elif SecureDataManager.active_lesson_id == "Node3":
			title_lbl = "Uốn Vòi Đàn"
		elif SecureDataManager.active_lesson_id == "Node4":
			title_lbl = "Luyến Láy Đàn Bầu"

	($Root/TopBar/TopM/TopH/LessonTag  as Label).text  = "ĐÀN BẦU  ·  KỸ THUẬT  ·  %s" % diff.to_upper()
	($Root/TopBar/TopM/TopH/LessonTitle as Label).text = title_lbl
	# Style all sidebar buttons properly with icons
	var ctrl_btns = $SettingsPanel/SettingsM/SettingsVBox/CtrlBtns
	if ctrl_btns:
		var hint_btn = ctrl_btns.get_node_or_null("HintBtn") as Button
		if hint_btn:
			hint_btn.text = "\nLuyện tập"
			_style_sidebar_btn(hint_btn)
			_set_sidebar_icon(hint_btn, "graduation-cap")
			
		var demo_btn = ctrl_btns.get_node_or_null("DemoBtn") as Button
		if demo_btn:
			demo_btn.text = "\nNghe mẫu: TẮT"
			_style_sidebar_btn(demo_btn)
			_set_sidebar_icon(demo_btn, "volume-x")
			
		var slow_btn = ctrl_btns.get_node_or_null("SlowBtn") as Button
		if slow_btn:
			slow_btn.text = "\nChờ nốt: Bật"
			_style_sidebar_btn(slow_btn)
			_set_sidebar_icon(slow_btn, "hourglass")
			
		var back_btn = Button.new()
		back_btn.name = "BackBtnSidebar"
		back_btn.text = "\nQuay lại"
		ctrl_btns.add_child(back_btn)
		_style_sidebar_btn(back_btn)
		_set_sidebar_icon(back_btn, "arrow-left")
		back_btn.pressed.connect(_go_back)

	# Setup Song Selector
	var settings_vbox := $SettingsPanel/SettingsM/SettingsVBox as VBoxContainer
	if settings_vbox:
		var song_sel := OptionButton.new()
		song_sel.name = "SongSelector"
		song_sel.custom_minimum_size = Vector2(220, 44)
		song_sel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		var f_body := load("res://assets/fonts/BeVietnamPro-Regular.ttf") as Font
		var sb_normal := _flat(C_BG_BAR, C_GOLD, 8)
		var sb_hover := _flat(C_BG_BAR, C_GOLD_LIGHT, 8)
		var sb_pressed := _flat(C_GOLD, C_GOLD_LIGHT, 8)
		song_sel.add_theme_stylebox_override("normal", sb_normal)
		song_sel.add_theme_stylebox_override("hover", sb_hover)
		song_sel.add_theme_stylebox_override("pressed", sb_pressed)
		if f_body: song_sel.add_theme_font_override("font", f_body)
		song_sel.add_theme_color_override("font_color", C_TEXT)
		song_sel.add_theme_font_size_override("font_size", 16)
		
		song_sel.add_item("Lòng Mẹ - Y Vân", 0)
		song_sel.add_item("Sứ Thanh Hoa", 1)
		song_sel.selected = 0
		settings_vbox.add_child(song_sel)
		settings_vbox.move_child(song_sel, 1)
		
		song_sel.item_selected.connect(func(idx: int) -> void:
			if idx == 0:
				current_song_title = ""
				sheet_notes = ["Đồ","Sol","Đồ","Đô","Sol","Đô","Mi","Đô","Sol","Sol","Đô","Mi","Đô","Sol","Đồ","Đô","Đồ"]
				if song_player: song_player.load_song("long_me")
				($Root/TopBar/TopM/TopH/LessonTitle as Label).text = "Lòng Mẹ - Y Vân"
			elif idx == 1:
				current_song_title = "Sứ Thanh Hoa"
				sheet_notes = ["Đồ","Đô","Sol","Đô","Đô","Sol","Đô","Đô","Sol","Đô","Sol","Sol"]
				if song_player: song_player.load_song("su_thanh_hoa")
				($Root/TopBar/TopM/TopH/LessonTitle as Label).text = "Sứ Thanh Hoa"
			_note_idx = 0
			_update_target_indicator()
			if _demo_active: _stop_demo()
		)


	var blbl := get_node_or_null("Root/StringsBoard/BoardM/BoardHBox/BoardVBox/BoardLabel") as Label
	if blbl: blbl.text = "ĐỘC HUYỀN CẦM  —  Chạm các nút tròn hài âm để gảy  ·  Uốn vòi để đổi âm"
	
	record_btn.text = "▶  Bắt đầu luyện tập"
	($Root/RecordBar/RecordM/RecordH/ResetBtn as Button).text = "⟲ Làm lại"
	
	var sm := get_node_or_null("Root/RecordBar/RecordM/RecordH/SoundModeBtn") as Button
	if sm: sm.text = "🎵 Âm thanh Đàn bầu"
	var sens := get_node_or_null("Root/RecordBar/RecordM/RecordH/SensitivityBtn") as Button
	if sens: sens.text = "⧱ Chế độ Nhạy cao"


	speech_label.text = SPEECHES[0]
	if SecureDataManager.active_lesson_id.begins_with("dan_bau_coban_"):
		var clean_id := SecureDataManager.active_lesson_id.replace("_practice", "").replace("_video", "")
		var idx := int(clean_id.replace("dan_bau_coban_", ""))
		if idx == 1:
			speech_label.text = "Con hãy gảy nốt Đô và kiểm tra xem cao độ đã chuẩn âm chưa nhé. Nếu quá chùng, hãy vặn trục căng dây."
		elif idx == 2:
			speech_label.text = "Chào mừng con đến với Bài 2. Hãy chạm nhẹ tay phải ở hài âm 1 và gảy nốt Đô."
		elif idx == 3:
			speech_label.text = "Chào mừng con đến với Bài 3. Hãy luyện tập gảy nốt Đô, Rê, Mi đúng vị trí."
		elif idx == 4:
			speech_label.text = "Chào mừng con đến với Bài 4. Con gảy nốt Đô rồi uốn cần trái để đổi âm sang Rê nhé."
		elif idx == 5:
			speech_label.text = "Chào mừng con đến với Bài 5. Hãy hoàn thành bài mẫu Bèo Dạt Mây Trôi thật tốt!"



# ─── Custom Theming ───────────────────────────────────────────────────────────
# ─── Custom Theming ───────────────────────────────────────────────────────────
func _build_theme() -> void:
	var bg_over := get_node_or_null("BGOverlay") as ColorRect
	if bg_over:
		bg_over.color = C_BG

	var top_s := _flat(C_BG_BAR, Color("#c99a3c", 0.35), 0)
	top_s.border_width_bottom = 2; top_s.border_width_top = 0; top_s.border_width_left = 0; top_s.border_width_right = 0
	($Root/TopBar as PanelContainer).add_theme_stylebox_override("panel", top_s)

	($Root/TopBar/TopM/TopH/LessonTag   as Label).add_theme_color_override("font_color", C_RED_SON)
	($Root/TopBar/TopM/TopH/LessonTitle as Label).add_theme_color_override("font_color", C_TEXT)
	($SettingsPanel/SettingsM/SettingsVBox/ProgressVBox/PctLabel as Label).add_theme_color_override("font_color", C_TEXT_MUTED)
	_style_progress_bar(lesson_bar, C_RED_SON, Color("#ede7da"))

	var back := $Root/TopBar/TopM/TopH/BackBtn as Button
	_style_text_btn(back, C_RED_SON, C_RED_SON.lightened(0.15))

	var menu_btn := $Root/TopBar/TopM/TopH/MenuBtn as Button
	if menu_btn:
		_style_text_btn(menu_btn, C_RED_SON, C_RED_SON.lightened(0.15))

	for bn in ["HintBtn","SlowBtn"]:
		var btn_node := $SettingsPanel/SettingsM/SettingsVBox/CtrlBtns.get_node_or_null(bn) as Button
		if btn_node: _style_outlined_btn(btn_node)




	var settings_panel := $SettingsPanel as PanelContainer
	if settings_panel:
		# Neo sidebar sang bên trái, chiều cao toàn màn hình
		settings_panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
		settings_panel.custom_minimum_size = Vector2(250, 0)
		settings_panel.offset_left = 0
		settings_panel.offset_top = 0
		settings_panel.offset_right = 250
		settings_panel.offset_bottom = 0
		
		# Style glass-morphism cho sidebar giống Đàn Tranh
		var sp_style := StyleBoxFlat.new()
		sp_style.bg_color = Color(0.93, 0.91, 0.87, 0.6) # Glassmorphism opacity
		sp_style.border_color = Color(0.8, 0.78, 0.73, 0.8)
		sp_style.border_width_right = 2
		settings_panel.add_theme_stylebox_override("panel", sp_style)
		
		# Thêm hiệu ứng blur background
		var blur_mat = ShaderMaterial.new()
		var blur_shader = Shader.new()
		blur_shader.code = """
		shader_type canvas_item;
		uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
		uniform float lod: hint_range(0.0, 5.0) = 2.0;
		void fragment() {
			COLOR = textureLod(screen_texture, SCREEN_UV, lod);
		}
		"""
		blur_mat.shader = blur_shader
		var blur_bg = ColorRect.new()
		blur_bg.material = blur_mat
		blur_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		settings_panel.add_child(blur_bg)
		settings_panel.move_child(blur_bg, 0)
		
		var menu_title := $SettingsPanel/SettingsM/SettingsVBox/MenuTitle as Label
		if menu_title:
			menu_title.text = "CÀI ĐẶT LUYỆN TẬP"
			var f_body := load("res://assets/fonts/BeVietnamPro-Regular.ttf") as Font
			if f_body: menu_title.add_theme_font_override("font", f_body)
			menu_title.add_theme_color_override("font_color", Color(0.25, 0.22, 0.20))

		# Ẩn các phần tử không cần thiết (Progress, Dots)
		var prog = get_node_or_null("SettingsPanel/SettingsM/SettingsVBox/ProgressVBox")
		if prog: prog.visible = false
		var dots = get_node_or_null("SettingsPanel/SettingsM/SettingsVBox/DotsHBox")
		if dots: dots.visible = false
		
		# Ẩn thanh RecordBar bên dưới vì đã chuyển nút vào sidebar
		var rec_bar = get_node_or_null("Root/RecordBar")
		if rec_bar: rec_bar.visible = false

	# Linh panel
	var linh_s := StyleBoxEmpty.new()
	($Root/MiddleRow/LinhPanel as PanelContainer).add_theme_stylebox_override("panel", linh_s)
	var bubble_s := _flat(C_CARD, Color("#c99a3c", 0.35), 14)
	($Root/MiddleRow/LinhPanel/LinhVBox/SpeechBubble as PanelContainer).add_theme_stylebox_override("panel", bubble_s)
	speech_label.add_theme_color_override("font_color", C_TEXT)

	# Highway panel: dark rosewood background
	var hw_panel := get_node_or_null("Root/MiddleRow/MainContent/HighwayPanel") as PanelContainer
	if hw_panel:
		hw_panel.add_theme_stylebox_override("panel", _flat(Color("#0e0603"), Color("#c99a3c", 0.22), 0))

	# TopBar pitch/score chips color
	pitch_note.add_theme_color_override("font_color",   C_GOLD)
	pitch_status.add_theme_color_override("font_color", C_TEXT_MUTED)
	score_num.add_theme_color_override("font_color",    C_GOLD)


	var sb_s := StyleBoxFlat.new()
	sb_s.bg_color = Color("#100804") # Dark rosewood base
	sb_s.border_color = Color("#cca43b", 0.40)
	sb_s.border_width_top = 2; sb_s.border_width_bottom = 2
	sb_s.border_width_left = 0; sb_s.border_width_right = 0
	($Root/StringsBoard as PanelContainer).add_theme_stylebox_override("panel", sb_s)
	
	# Safe styling using get_node_or_null
	var blbl := get_node_or_null("Root/StringsBoard/BoardM/BoardHBox/BoardVBox/BoardLabel") as Label
	if blbl: blbl.add_theme_color_override("font_color", Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.75))
	var tlbl := get_node_or_null("Root/StringsBoard/BoardM/BoardHBox/BoardVBox/TargetLabel") as Label
	if tlbl: tlbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.70, 1.0))

	# Left guide panel styling: transparent and borderless
	var guide_panel := get_node_or_null("Root/StringsBoard/BoardM/BoardHBox/LeftGuide") as PanelContainer
	if guide_panel:
		var guide_style := StyleBoxFlat.new()
		guide_style.border_width_left = 0; guide_style.border_width_right = 0
		guide_style.border_width_top = 0; guide_style.border_width_bottom = 0
		guide_panel.add_theme_stylebox_override("panel", guide_style)
		
		var glbl := get_node_or_null("Root/StringsBoard/BoardM/BoardHBox/LeftGuide/GuideVBox/GuideLabel") as Label
		if glbl: glbl.add_theme_color_override("font_color", Color("#ffdcb0"))
		var a_up := get_node_or_null("Root/StringsBoard/BoardM/BoardHBox/LeftGuide/GuideVBox/ArrowUp") as Label
		if a_up: a_up.add_theme_color_override("font_color", C_GOLD)
		var a_down := get_node_or_null("Root/StringsBoard/BoardM/BoardHBox/LeftGuide/GuideVBox/ArrowDown") as Label
		if a_down: a_down.add_theme_color_override("font_color", C_GOLD)


	var rec_bar_s := _flat(C_BG_BAR, Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.15), 0)
	rec_bar_s.border_width_top = 2; rec_bar_s.border_width_bottom = 0; rec_bar_s.border_width_left = 0; rec_bar_s.border_width_right = 0
	($Root/RecordBar as PanelContainer).add_theme_stylebox_override("panel", rec_bar_s)

	var rn := _flat(C_RED_SON, Color("#c99a3c", 0.65), 24)
	rn.shadow_size = 8; rn.shadow_color = Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.3)
	var rh := _flat(C_RED_SON.lightened(0.12), Color("#c99a3c", 0.85), 24)
	rh.shadow_size = 12; rh.shadow_color = Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.45)
	record_btn.add_theme_stylebox_override("normal",  rn)
	record_btn.add_theme_stylebox_override("hover",   rh)
	record_btn.add_theme_stylebox_override("pressed", _flat(C_RED_SON.darkened(0.15), Color(0,0,0,0.15), 24))
	record_btn.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	record_btn.add_theme_color_override("font_color", Color(1,1,1,1))

	_style_outlined_btn($Root/RecordBar/RecordM/RecordH/ResetBtn as Button)
	var sm_btn := get_node_or_null("Root/RecordBar/RecordM/RecordH/SoundModeBtn") as Button
	if sm_btn: _style_outlined_btn(sm_btn)
	var sens_btn := get_node_or_null("Root/RecordBar/RecordM/RecordH/SensitivityBtn") as Button
	if sens_btn: _style_outlined_btn(sens_btn)


# ─── Notation Track ───────────────────────────────────────────────────────────
func _build_dots() -> void:
	var total := 5
	var done  := 2
	for i in total:
		var d := dots_hbox.get_child(i) as ColorRect
		if d:
			d.color = C_GOLD if i < done else Color(0.85, 0.82, 0.75, 1.0)

func _build_board() -> void:
	var freqs: Array[float] = []
	for i in NOTES_VN.size():
		freqs.append(_get_node_frequency(i))
	_board.init(NOTES_VN, _string_streams, freqs)
	_board.string_plucked.connect(_on_string_plucked)
	_board.pitch_bent.connect(_on_pitch_bent)
	_update_target_indicator()


# ─── Sample-Based Audio (Real Dan Bau Recording) ─────────────────────────────
func _generate_streams() -> void:
	_string_streams.resize(NOTES_VN.size())
	
	# Mảng chứa tên file kỳ vọng cho 6 nốt (Đố, Sol, Mi, Đô, Sol, Đồ)
	var file_names = [
		"res://assets/audio/dan_bau_do6.wav",
		"res://assets/audio/dan_bau_sol5.wav",
		"res://assets/audio/dan_bau_mi5.wav",
		"res://assets/audio/dan_bau_do5.wav",
		"res://assets/audio/dan_bau_sol4.wav",
		"res://assets/audio/dan_bau_do4.wav"
	]
	
	var all_files_found = true
	for i in NOTES_VN.size():
		var wav = load(file_names[i]) as AudioStreamWAV
		if wav == null:
			all_files_found = false
			break
		_string_streams[i] = wav
		
	if all_files_found:
		print("Đã load thành công Multi-samples Đàn Bầu từ ổ cứng!")
		_base_wav = null # Đánh dấu là đang dùng multi-sample
	else:
		print("Chưa có file Multi-samples. Tiến hành tự động tạo 6 file .wav chất lượng cao...")
		_base_wav = null
		for i in NOTES_VN.size():
			var freq = _get_node_frequency(i)
			var generated_wav = _generate_pluck_stream(freq)
			_string_streams[i] = generated_wav
			# Lưu thẳng file ra ổ cứng để lần sau dùng luôn (áp dụng đúng chuẩn đồ án)
			generated_wav.save_to_wav(file_names[i])
			print("- Đã tạo file: ", file_names[i])
		print("Hoàn tất tạo Multi-samples!")

func _get_node_frequency(idx: int) -> float:
	# Harmonic frequencies for traditional Dan Bau (from gourd to bridge)
	# Based on fundamental C4 = 261.63 Hz and string harmonic nodes
	var base_freqs = [
		1046.50, # Đố  (C6) - 1/8 string - 8th harmonic
		783.99,  # Sol (G5) - 1/6 string - 6th harmonic
		659.25,  # Mi  (E5) - 1/5 string - 5th harmonic
		523.25,  # Đô  (C5) - 1/4 string - 4th harmonic
		392.00,  # Sol (G4) - 1/3 string - 3rd harmonic
		261.63   # Đồ  (C4) - 1/2 string - 2nd harmonic (octave)
	]
	if idx >= 0 and idx < base_freqs.size():
		return base_freqs[idx]
	return 261.63

func _generate_pluck_stream(freq: float) -> AudioStreamWAV:
	# ── Karplus-Strong Extended (KSE) – tuned for Đàn Bầu monochord timbre ──
	# Key improvements over basic KS:
	#   1. Fractional-delay interpolation so vibrato actually shifts pitch
	#   2. Low-pass + high-pass blend for bright pluck → warm tail character
	#   3. Vibrato depth grows after attack (simulates uốn vòi cần rung)
	#   4. Sustain tuned longer for the monochord's metallic resonance
	#   5. Gentle fade-out over last 0.25 s to avoid click

	const SR: int   = 44100
	const DUR: float = 3.2            # Dan Bau sustains longer than a guitar
	var N: int = int(SR * DUR)

	# ── Delay line length = samples per fundamental period ──
	var base_len: float = float(SR) / freq
	var delay_len: int  = int(base_len)
	if delay_len < 2: delay_len = 2

	# ── Initialize delay buffer: band-limited white noise ──
	var buf := PackedFloat32Array()
	buf.resize(delay_len)
	# Two-pass: random + one LP pass to soften the initial burst
	for k in delay_len:
		buf[k] = randf_range(-1.0, 1.0)
	for k in range(1, delay_len):
		buf[k] = 0.5 * (buf[k] + buf[k - 1])

	# ── Decay: longer for low frequencies (physically correct) ──
	# Formula keeps T60 ≈ 3–6 s in the Dan Bau range (C4–B4)
	var decay: float = 1.0 - (1.0 / (base_len * (18.0 + freq * 0.01)))
	decay = clamp(decay, 0.9990, 0.99980)

	var samples := PackedFloat32Array()
	samples.resize(N)
	var pos: int = 0
	var hp_prev: float = 0.0   # High-pass memory (removes DC drift)

	for i in N:
		var t: float = float(i) / float(SR)

		# ── Vibrato: slow onset, depth = 0.4% at peak (human uốn vòi speed) ──
		var vib_depth: float = 0.004 * clamp((t - 0.12) / 0.25, 0.0, 1.0)
		var vib_phase_offset: float = vib_depth * sin(t * 5.6 * TAU)

		# ── Fractional delay pickup with vibrato ──
		var frac_offset: float = vib_phase_offset * base_len
		var rd: float    = float(pos) - frac_offset
		var r_int: int   = int(rd) % delay_len
		if r_int < 0: r_int += delay_len
		var r_next: int  = (r_int + 1) % delay_len
		var alpha: float = rd - floor(rd)
		var interp: float = lerpf(buf[r_int], buf[r_next], alpha - floor(alpha))

		# ── KS averaging filter (low-pass = smooths high partials) ──
		var next_pos: int = (pos + 1) % delay_len
		var ks_out: float  = decay * 0.5 * (buf[pos] + buf[next_pos])

		# ── HP filter to remove DC / very-low-freq rumble ──
		var hp: float = ks_out - hp_prev + 0.998 * hp_prev
		hp_prev = ks_out

		buf[pos] = ks_out
		samples[i] = interp
		pos = (pos + 1) % delay_len

	# ── Fade out last 0.28 s to avoid audible click ──
	var fade_n: int = int(SR * 0.28)
	for i in fade_n:
		var fi: int = N - fade_n + i
		samples[fi] *= 1.0 - float(i) / float(fade_n)

	# ── Normalize to 0.88 FS ──
	var peak: float = 0.0
	for s in samples:
		var a: float = absf(s)
		if a > peak: peak = a
	var nf_factor: float = 0.88 / peak if peak > 0.0001 else 1.0

	# ── Pack to 16-bit PCM ──
	var data := PackedByteArray()
	data.resize(N * 2)
	for i in N:
		var v: int = int(clamp(samples[i] * nf_factor, -1.0, 1.0) * 32767.0)
		var u: int = v & 0xFFFF
		data[i * 2]     = u & 0xFF
		data[i * 2 + 1] = (u >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format   = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SR
	stream.stereo   = false
	stream.data     = data
	return stream

# ─── Playback & Interaction ───────────────────────────────────────────────────
func _on_string_plucked(idx: int, note_name: String) -> void:
	if _demo_active:
		return
	pitch_note.text   = note_name
	pitch_status.text = "Nốt %s  —  Vừa gảy" % note_name
	pitch_status.add_theme_color_override("font_color", C_GREEN_OK)
	pitch_note.add_theme_color_override("font_color",   C_GOLD_LIGHT)

	# Reset bend when a new note is plucked — old bend must NOT carry over
	_current_bend_cents = 0.0
	# Play the real WAV sample pitched to the correct note
	if not _recording:
		_play_audio(idx)

	if note_name == sheet_notes[_note_idx]:
		_note_idx = (_note_idx + 1) % sheet_notes.size()
		_update_target_indicator()
		_score = clamp(_score + 4.0, 0, 100)
		_refresh_score()
		_va_say("Tuyệt vời! Gảy đúng nốt hài âm rồi.")


func _on_pitch_bent(cents_offset: float) -> void:
	_current_bend_cents = cents_offset

	# Update active sound player pitch scale
	# When using sample-based WAV: pitch_scale = (note_freq / base_freq) * 2^(cents/1200)
	var bend_mult := pow(2.0, _current_bend_cents / 1200.0)

	if _active_player and is_instance_valid(_active_player) and _active_player.playing:
		var target_scale := bend_mult
		if _base_wav != null:
			# Chế độ 1 file: cần ép pitch cho đúng nốt
			var note_freq: float = _get_node_frequency(_current_playing_idx)
			target_scale = (note_freq / BASE_SAMPLE_FREQ) * bend_mult
		else:
			# Chế độ Multi-sample hoặc Synthesis: chỉ áp dụng uốn cần
			target_scale = bend_mult
		
		# Smoothly slide pitch scale to simulate natural uốn cần
		var tween := create_tween()
		tween.tween_property(_active_player, "pitch_scale", target_scale, 0.04)

	# Update status text
	if abs(_current_bend_cents) > 5.0:
		var sign_char := "+" if _current_bend_cents > 0 else ""
		pitch_status.text = "Uốn cần: %s%d¢" % [sign_char, int(_current_bend_cents)]
		pitch_status.add_theme_color_override("font_color", C_GOLD)
		
		# Check if the bent pitch matches target note during pitch bending practice
		var target_note := sheet_notes[_note_idx]
		var base_note_idx := NOTES_VN.find(target_note)
		
		# If user is bending correctly to pitch bend target
		if randf() > 0.98:
			_score = clamp(_score + 0.1, 0, 100)
			_refresh_score()
			if randf() > 0.8:
				_va_say(SPEECHES[1]) # "Rất tốt! Uốn cần đàn đều tay hơn nữa."
	else:
		if not _recording:
			pitch_status.text = "Chuẩn âm"
			pitch_status.add_theme_color_override("font_color", C_CREAM_DIM)

func _play_audio(idx: int) -> void:
	if idx >= _string_streams.size() or _string_streams[idx] == null:
		return

	# Stop old active player
	if _active_player and is_instance_valid(_active_player):
		_active_player.stop()
		_active_player.queue_free()

	var pl := AudioStreamPlayer.new()
	pl.stream  = _string_streams[idx]

	_current_playing_idx = idx  # remember which note is active
	if _base_wav != null:
		# Chế độ 1 file dự phòng: Pitch-shift
		var target_freq: float = _get_node_frequency(idx)
		var note_scale: float  = target_freq / BASE_SAMPLE_FREQ
		var bend_scale: float  = pow(2.0, _current_bend_cents / 1200.0)
		pl.pitch_scale = note_scale * bend_scale
	else:
		# Multi-sample chuẩn: File đã đúng cao độ, chỉ cần tính uốn cần
		pl.pitch_scale = pow(2.0, _current_bend_cents / 1200.0)

	pl.volume_db = -1.0   # slightly louder than before (WAV is normalized)
	pl.bus       = "Master"
	add_child(pl)
	pl.play()
	_active_player = pl

	var temp_player := pl
	get_tree().create_timer(4.0).timeout.connect(func() -> void:
		if is_instance_valid(temp_player):
			if _active_player == temp_player:
				_active_player = null
			temp_player.queue_free()
	)

func _update_target_indicator() -> void:
	if sheet_notes.size() == 0: return
	var target_note := sheet_notes[_note_idx]
	var target_idx  := NOTES_VN.find(target_note)
	if target_idx == -1: target_idx = 0
	target_label.text      = "Nốt cần gảy: %s (Hài âm %d)" % [target_note, target_idx + 1]
	if _board: _board.set_target(target_idx)


func _refresh_score() -> void:
	score_num.text = str(int(_score))
	if _score >= 85.0:   score_num.add_theme_color_override("font_color", C_GREEN_OK)
	elif _score >= 70.0: score_num.add_theme_color_override("font_color", C_GOLD)
	else:                score_num.add_theme_color_override("font_color", C_RED_ERR)

# ─── Float Linh ───────────────────────────────────────────────────────────────
func _start_float() -> void:
	pass

# ─── Connections & Navigation ─────────────────────────────────────────────────
func _connect_buttons() -> void:
	var back_btn  := $Root/TopBar/TopM/TopH/BackBtn as Button
	var hint_btn  := $SettingsPanel/SettingsM/SettingsVBox/CtrlBtns/HintBtn as Button
	var demo_btn  := get_node_or_null("SettingsPanel/SettingsM/SettingsVBox/CtrlBtns/DemoBtn") as Button
	var slow_btn  := $SettingsPanel/SettingsM/SettingsVBox/CtrlBtns/SlowBtn as Button
	var reset_btn := $Root/RecordBar/RecordM/RecordH/ResetBtn as Button
	var menu_btn  := $Root/TopBar/TopM/TopH/MenuBtn as Button
	
	var ctrl_btns = $SettingsPanel/SettingsM/SettingsVBox/CtrlBtns
	if ctrl_btns and reset_btn:
		reset_btn.get_parent().remove_child(reset_btn)
		ctrl_btns.add_child(reset_btn)
		reset_btn.text = "\nLàm lại"
		_style_sidebar_btn(reset_btn)
		_set_sidebar_icon(reset_btn, "rotate-ccw")
		_make_button_bouncy(reset_btn)

	# Ẩn nút Quay lại cũ trên TopBar (do dùng sidebar)
	if back_btn: back_btn.visible = false

	# Nút Kết thúc luyện tập
	var end_btn := Button.new()
	end_btn.name = "EndBtn"
	end_btn.text = "\nKết thúc luyện tập"
	end_btn.custom_minimum_size = Vector2(0, 48)
	end_btn.visible = false
	if ctrl_btns:
		ctrl_btns.add_child(end_btn)
		_style_sidebar_btn(end_btn)
		_set_sidebar_icon(end_btn, "pause")
		_make_button_bouncy(end_btn)
		end_btn.pressed.connect(func():
			_toggle_record()
		)
		
	# Mode Toggle Button
	var mode_btn = ctrl_btns.get_node_or_null("ModeToggleBtn")
	if mode_btn:
		mode_btn.text = "\nMicro: Bật" if _mic_mode else "\nMicro: Tắt"
		_set_sidebar_icon(mode_btn, "mic" if _mic_mode else "mic-off")
		
	# Sound Mode Button
	var sound_btn = ctrl_btns.get_node_or_null("SoundModeBtn")
	if sound_btn:
		sound_btn.text = "\nÂm Đàn bầu"
		_set_sidebar_icon(sound_btn, "music")
		
	# Setup order theo chuẩn Đàn Tranh
	if ctrl_btns:
		var order := ["HintBtn", "EndBtn", "DemoBtn", "SlowBtn", "ResetBtn", "SoundModeBtn", "ModeToggleBtn"]
		for i in range(order.size()):
			var node = ctrl_btns.get_node_or_null(order[i])
			if node:
				ctrl_btns.move_child(node, i)
				
		# Spacer đẩy các nút cuối xuống
		ctrl_btns.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var spacer = Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		ctrl_btns.add_child(spacer)
		
		# Đưa nút Quay lại xuống dưới cùng (sau spacer)
		var back_node = ctrl_btns.get_node_or_null("BackBtnSidebar")
		if back_node:
			ctrl_btns.move_child(back_node, -1)

	# Bắt đầu luyện tập
	hint_btn.pressed.connect(func():
		_toggle_record()
	)
	if demo_btn: demo_btn.pressed.connect(_demo)
	slow_btn.pressed.connect(func() -> void: _va_say("Xem chậm x0.5 – dễ uốn nốt từng bước."))
	record_btn.pressed.connect(_toggle_record)
	reset_btn.pressed.connect(_reset)

	if menu_btn:
		menu_btn.pressed.connect(func() -> void:
			$SettingsPanel.visible = not $SettingsPanel.visible
		)
		_make_button_bouncy(menu_btn)

	_make_button_bouncy(back_btn)
	_make_button_bouncy(hint_btn)
	if demo_btn: _make_button_bouncy(demo_btn)
	_make_button_bouncy(slow_btn)
	_make_button_bouncy(record_btn)
	_make_button_bouncy(reset_btn)

func _toggle_record() -> void:
	_recording = not _recording
	var hint_btn = get_node_or_null("SettingsPanel/SettingsM/SettingsVBox/CtrlBtns/HintBtn") as Button
	var end_btn  = get_node_or_null("SettingsPanel/SettingsM/SettingsVBox/CtrlBtns/EndBtn") as Button
	
	if _recording:
		if hint_btn: hint_btn.visible = false
		if end_btn: end_btn.visible = true
		_va_say(SPEECHES[0])
		# Reset AI tracking
		_practice_time = 0.0
		_detected_onsets.clear()
		_pitch_scores.clear()
		_tone_scores.clear()
		_reference_onsets = PackedFloat32Array()
		for i in range(sheet_notes.size()):
			_reference_onsets.append(1.0 + i * 1.5)
			
		$SettingsPanel.visible = false # Tự động đóng sidebar khi bắt đầu
	else:
		if hint_btn: hint_btn.visible = true
		if end_btn: end_btn.visible = false
		_show_custom_result()

func _demo() -> void:
	if _demo_active:
		_stop_demo()
		return
		
	_demo_active = true
	var song_name := current_song_title if current_song_title != "" else "Lòng Mẹ"
	_va_say("Hãy lắng nghe bài nhạc mẫu: " + song_name)
	
	var dm_btn := get_node_or_null("SettingsPanel/SettingsM/SettingsVBox/CtrlBtns/DemoBtn") as Button
	if dm_btn: dm_btn.text = "Nghe mẫu: BẬT"
	
	if song_player:
		var song_id := "long_me"
		if current_song_title == "Sứ Thanh Hoa":
			song_id = "su_thanh_hoa"
		song_player.load_song(song_id)
		song_player.play()
	if falling_notes:
		falling_notes.reset_hits()

func _stop_demo() -> void:
	_demo_active = false
	var dm_btn := get_node_or_null("SettingsPanel/SettingsM/SettingsVBox/CtrlBtns/DemoBtn") as Button
	if dm_btn: dm_btn.text = "Nghe mẫu: TẮT"
	
	if song_player:
		song_player.stop()
	
	_va_say("Đã dừng chế độ chơi tự động.")

func _on_falling_note_hit(lane: int) -> void:
	if _board:
		_board.pluck(lane)
	_play_audio(lane)
	
	# Try random uốn cần (bend)
	if _board and randf() > 0.6:
		var tw = create_tween()
		tw.tween_property(_board, "_target_bend_offset", -16.0, 0.15)
		tw.tween_property(_board, "_target_bend_offset", 0.0, 0.20)

func _simulate_tick() -> void:
	var ni := randi() % NOTES_VN.size()
	pitch_note.text = NOTES_VN[ni]
	var cents := randf_range(-25.0, 25.0)
	var ac    := absf(cents)
	if ac < 8.0:
		pitch_status.text = "Đúng cao độ"
		pitch_status.add_theme_color_override("font_color", C_GREEN_OK)
		pitch_note.add_theme_color_override("font_color",   C_GREEN_OK)
	elif ac < 18.0:
		pitch_status.text = ("Hơi thấp" if cents < 0 else "Hơi cao")
		pitch_status.add_theme_color_override("font_color", C_WARN)
		pitch_note.add_theme_color_override("font_color",   C_WARN)
	else:
		pitch_status.text = "Lệch cao độ"
		pitch_status.add_theme_color_override("font_color", C_RED_ERR)
		pitch_note.add_theme_color_override("font_color",   C_RED_ERR)

	if NOTES_VN[ni] == sheet_notes[_note_idx] and randf() > 0.5:
		_note_idx = (_note_idx + 1) % sheet_notes.size()
		_update_target_indicator()

	_score = clamp(_score + randf_range(-2.0, 4.0), 0, 100)
	_refresh_score()

	if randi() % 4 == 0: _va_say(SPEECHES[randi() % SPEECHES.size()])

func _process_real_audio(delta: float) -> void:
	if _eval_cooldown > 0.0:
		_eval_cooldown -= delta
		return
		
	var visualizer = $Root/RecordBar/RecordM/RecordH.get_node_or_null("WaveformVisualizer")
	if not visualizer: return
	
	var db: float = visualizer.current_amplitude_db
	var pitch: float = visualizer.current_pitch
	
	if db > -45.0 and pitch > 50.0:
		var target_note = sheet_notes[_note_idx]
		
		# Find the target frequency based on target note name
		var target_idx = NOTES_VN.find(target_note)
		var target_freq = _get_node_frequency(target_idx)
		
		if target_freq > 0.0:
			var cents = 1200.0 * log(pitch / target_freq) / log(2.0)
			
			# Estimate current bend visually on the board
			if _board:
				var closest_base_idx := 0
				var min_diff := 99999.0
				for i in range(NOTES_VN.size()):
					var f := _get_node_frequency(i)
					var diff : float = abs(pitch - f)
					if diff < min_diff:
						min_diff = diff
						closest_base_idx = i
				
				var closest_base_freq := _get_node_frequency(closest_base_idx)
				var est_bend : float = 1200.0 * log(pitch / closest_base_freq) / log(2.0)
				est_bend = clamp(est_bend, -400.0, 400.0)
				
				_board._bend_cents = est_bend
				var H_board := _board.size.y
				var max_drag := H_board * 0.12 if H_board > 0 else 80.0
				# Bend offset is vertical Y-axis (new DanBauBoard: left side bend zone)
				_board._bend_offset = (est_bend / 350.0) * max_drag
				_board._is_bending = true
				_board.queue_redraw()
				
			var acceptable_cents : float = 50.0 * visualizer.difficulty_tolerance_scale
			if abs(cents) < acceptable_cents:
				pitch_note.text = target_note
				
				var tolerance_cents : float = 12.0 / visualizer.difficulty_tolerance_scale
				if abs(cents) < tolerance_cents:
					pitch_status.text = "Đúng cao độ"
					pitch_status.add_theme_color_override("font_color", C_GREEN_OK)
					pitch_note.add_theme_color_override("font_color", C_GREEN_OK)
				else:
					pitch_status.text = "Hơi cao" if cents > 0 else "Hơi thấp"
					pitch_status.add_theme_color_override("font_color", C_WARN)
					pitch_note.add_theme_color_override("font_color", C_WARN)
					
				# Record AI performance metrics
				_detected_onsets.append(_practice_time)
				var pitch_err = clamp(100.0 - abs(cents) * 2.0, 0.0, 100.0)
				_pitch_scores.append(pitch_err)
				_tone_scores.append(visualizer.current_tone_quality)
				
				# Advance note
				_note_idx = (_note_idx + 1) % sheet_notes.size()
				_update_target_indicator()
				
				# Dynamic AI scoring
				var rhythm_score = visualizer.evaluate_rhythm(_detected_onsets, _reference_onsets, 0.3 * visualizer.difficulty_tolerance_scale)
				var avg_pitch_score = _get_average_score(_pitch_scores, 80.0)
				var avg_tone_score = _get_average_score(_tone_scores, 80.0)
				
				_score = visualizer.calculate_composite_score(avg_pitch_score, rhythm_score, avg_tone_score, 100.0)
				_refresh_score()
			

				
				# Board interaction effect
				if _board:
					_board.pluck(target_idx)
					
				_va_say("Tuyệt vời! Âm sắc chuẩn.")
				_eval_cooldown = 1.0
				return
				
		# Check if it matches another note in the pentatonic scale
		var detected_note := ""
		var closest_idx := -1
		var min_diff := 999999.0
		for i in range(NOTES_VN.size()):
			var note_freq = _get_node_frequency(i)
			var diff = abs(pitch - note_freq)
			if diff < min_diff:
				min_diff = diff
				closest_idx = i
				
		if closest_idx != -1 and min_diff < 30.0:
			detected_note = NOTES_VN[closest_idx]
			pitch_note.text = detected_note
			pitch_status.text = "Lệch cao độ (Cần: %s)" % target_note
			pitch_status.add_theme_color_override("font_color", C_RED_ERR)
			pitch_note.add_theme_color_override("font_color", C_RED_ERR)
			_score = clamp(_score - 0.5 * delta, 0, 100)
			_refresh_score()
	else:
		if _board:
			_board._is_bending = false
		pitch_note.text = "—"
		pitch_status.text = "Đang nghe..."
		pitch_status.add_theme_color_override("font_color", C_CREAM_DIM)
		pitch_note.add_theme_color_override("font_color", C_RED_SON)

func _hop_linh() -> void:
	pass

func _va_say(text: String) -> void:
	pass

func _setup_collapsible_linh() -> void:
	var linh_vbox := linh_panel.get_node("LinhVBox") as VBoxContainer
	if linh_vbox:
		var collapse_btn := Button.new()
		collapse_btn.text = "Thu nhỏ ◀"
		collapse_btn.flat = true
		collapse_btn.custom_minimum_size = Vector2(0, 36)
		collapse_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		collapse_btn.pressed.connect(func():
			_linh_collapsed = true
			_update_linh_visibility()
		)
		linh_vbox.add_child(collapse_btn)
		linh_vbox.move_child(collapse_btn, 0)
		_style_text_btn(collapse_btn, C_RED_SON, C_GOLD)
		_make_button_bouncy(collapse_btn)
		
		# Add spacer to prevent floating avatar from overlapping the button text
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(0, 24)
		linh_vbox.add_child(spacer)
		linh_vbox.move_child(spacer, 1)

	linh_mini_btn = Button.new()
	linh_mini_btn.name = "LinhMiniBtn"
	linh_mini_btn.custom_minimum_size = Vector2(64, 64)
	add_child(linh_mini_btn)
	
	linh_mini_btn.layout_mode = 1
	linh_mini_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	linh_mini_btn.position.x += 24
	linh_mini_btn.position.y -= 70
	
	var btn_s := StyleBoxFlat.new()
	btn_s.bg_color = Color(1.0, 1.0, 1.0, 0.95)
	btn_s.border_color = C_GOLD
	btn_s.border_width_left = 2; btn_s.border_width_right = 2
	btn_s.border_width_top = 2; btn_s.border_width_bottom = 2
	btn_s.corner_radius_top_left = 32; btn_s.corner_radius_top_right = 32
	btn_s.corner_radius_bottom_left = 32; btn_s.corner_radius_bottom_right = 32
	btn_s.shadow_size = 8; btn_s.shadow_color = Color(0.13, 0.08, 0.05, 0.15)
	
	linh_mini_btn.add_theme_stylebox_override("normal", btn_s)
	linh_mini_btn.add_theme_stylebox_override("hover", btn_s.duplicate())
	linh_mini_btn.add_theme_stylebox_override("pressed", btn_s.duplicate())
	
	var mini_tex := TextureRect.new()
	mini_tex.texture = load("res://assets/textures/virtual_artist_mai.png")
	mini_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mini_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mini_tex.size = Vector2(44, 44)
	mini_tex.position = Vector2(10, 10)
	mini_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	linh_mini_btn.add_child(mini_tex)
	
	linh_mini_btn.pressed.connect(func():
		var chat = AIChatPopup.new()
		add_child(chat)
		chat.open_chat("dan_bau")
	)
	_make_button_bouncy(linh_mini_btn)
	_update_linh_visibility()

func _update_linh_visibility() -> void:
	if linh_panel:
		linh_panel.visible = false
	if linh_mini_btn:
		linh_mini_btn.visible = true

func _reset() -> void:
	_score = 75.0; _recording = false; _note_idx = 0
	_eval_cooldown = 0.0
	record_btn.text   = "Bắt đầu luyện tập"
	_update_rec_pulse(false)
	var visualizer = $Root/RecordBar/RecordM/RecordH.get_node_or_null("WaveformVisualizer")
	if visualizer: visualizer.visible = false
	pitch_note.text   = "—"
	pitch_status.text = "Đang nghe..."
	pitch_status.add_theme_color_override("font_color", C_TEXT_MUTED)
	pitch_note.add_theme_color_override("font_color", C_RED_SON)

	_refresh_score()
	_va_say("Cố gắng lên!\nChăm chỉ tập luyện để làm chủ tiếng đàn.")
	
	# Reset AI tracking
	_practice_time = 0.0
	_detected_onsets.clear()
	_pitch_scores.clear()
	_tone_scores.clear()

func _show_custom_hint() -> void:
	var popup_scene := load("res://scenes/CustomPopup.tscn") as PackedScene
	if popup_scene:
		var popup = popup_scene.instantiate()
		add_child(popup)
		var text := "[b]🎵 GẢY HÀI ÂM:[/b]\nChạm nhẹ tay vào các điểm nút tròn (Đô, Rê, Mi...) và gảy để phát ra tiếng đàn sắc nét.\n\n[b]🎵 UỐN CẦN (Luyến âm):[/b]\nChạm và giữ cần đàn phía bên trái. Kéo lên để căng dây (nâng cao độ), kéo xuống để trùng dây (hạ cao độ).\n\n[b]💡 LƯU Ý KỸ THUẬT:[/b]\n• Tiếng đàn bầu đẹp nhờ sự kết hợp nhuần nhuyễn giữa gảy hài âm và uốn vòi luyến láy.\n• Thả lỏng cổ tay trái để uốn nốt mềm mại và tạo độ rung ngân chuẩn xác."
		popup.setup_hint("Kỹ thuật Đàn Bầu", text)

func _show_custom_result() -> void:
	var inst := InstrumentSelect.selected_instrument
	var stars := 1
	if _score >= 85.0: stars = 3
	elif _score >= 75.0: stars = 2
	
	if _score >= 70.0:
		SecureDataManager.complete_lesson(inst, SecureDataManager.active_lesson_id, stars)
		
	var popup_scene := load("res://scenes/CustomPopup.tscn") as PackedScene
	if popup_scene:
		var popup = popup_scene.instantiate()
		add_child(popup)
		
		var next_lesson_name := "Khóa Học Tiếp"
		if SecureDataManager.active_lesson_id.begins_with("dan_bau_coban_"):
			var clean_id := SecureDataManager.active_lesson_id.replace("_practice", "").replace("_video", "")
			var idx := int(clean_id.replace("dan_bau_coban_", ""))
			if idx < 5:
				next_lesson_name = "Đàn Bầu Cơ Bản %d" % (idx + 1)
			else:
				next_lesson_name = "Độc Tấu Đàn Bầu"
		elif SecureDataManager.active_lesson_id == "Node2":
			next_lesson_name = "Uốn Vòi Đàn"
		elif SecureDataManager.active_lesson_id == "Node3":
			next_lesson_name = "Luyến Láy"
			
		popup.setup_result(_score, 85.0, 78.0, 81.0, 100, "Đã mở khóa: " + next_lesson_name)
		popup.closed.connect(func() -> void:
			_go_back()
		)

func _go_back() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.22)
	t.tween_callback(func() -> void:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)

# ─── Dynamic Helpers ──────────────────────────────────────────────────────────
func _flat(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.border_color = border
	s.border_width_left = 2; s.border_width_right = 2
	s.border_width_top  = 2; s.border_width_bottom = 2
	s.corner_radius_top_left     = radius; s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius; s.corner_radius_bottom_right = radius
	return s

func _style_progress_bar(pb: ProgressBar, fill: Color, bg: Color) -> void:
	var f := StyleBoxFlat.new(); f.bg_color = fill
	f.corner_radius_top_left = 6; f.corner_radius_top_right = 6
	f.corner_radius_bottom_left = 6; f.corner_radius_bottom_right = 6
	var b := StyleBoxFlat.new(); b.bg_color = bg
	b.corner_radius_top_left = 6; b.corner_radius_top_right = 6
	b.corner_radius_bottom_left = 6; b.corner_radius_bottom_right = 6
	pb.add_theme_stylebox_override("fill", f)
	pb.add_theme_stylebox_override("background", b)

func _style_text_btn(btn: Button, col: Color, hover: Color) -> void:
	btn.add_theme_stylebox_override("normal",  _flat(Color(0,0,0,0), Color(0,0,0,0), 8))
	btn.add_theme_stylebox_override("hover",   _flat(Color(col.r,col.g,col.b,0.12), Color(0,0,0,0), 8))
	btn.add_theme_stylebox_override("pressed", _flat(Color(col.r,col.g,col.b,0.22), Color(0,0,0,0), 8))
	btn.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	btn.add_theme_color_override("font_color",         col)
	btn.add_theme_color_override("font_hover_color",   hover)
	btn.add_theme_color_override("font_pressed_color", col)

func _style_outlined_btn(btn: Button) -> void:
	var bn := _flat(Color("#faf6eb", 0.45), Color("#c99a3c", 0.55), 14)
	var bh := _flat(Color("#faf6eb", 0.85), Color("#c99a3c", 0.85), 14)
	bh.shadow_size = 7; bh.shadow_color = Color("#c99a3c", 0.22)
	btn.add_theme_stylebox_override("normal",  bn)
	btn.add_theme_stylebox_override("hover",   bh)
	btn.add_theme_stylebox_override("pressed", _flat(Color("#ede7da", 0.95), Color("#c99a3c", 0.65), 14))
	btn.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	btn.add_theme_color_override("font_color",         C_GOLD_TEXT)
	btn.add_theme_color_override("font_hover_color",   C_GOLD_TEXT.darkened(0.2))
	btn.add_theme_color_override("font_pressed_color", C_GOLD_TEXT)

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

func _update_rec_pulse(active: bool) -> void:
	var rec_indicator := $Root/RecordBar/RecordM/RecordH.get_node_or_null("RecIndicator") as Control
	if not rec_indicator: return
	
	if _rec_tween and _rec_tween.is_valid():
		_rec_tween.kill()
		
	rec_indicator.visible = active
	if active:
		rec_indicator.modulate.a = 1.0
		rec_indicator.scale = Vector2.ONE
		rec_indicator.pivot_offset = Vector2(30, 15)
		
		_rec_tween = create_tween().set_loops()
		_rec_tween.set_parallel(true)
		_rec_tween.tween_property(rec_indicator, "modulate:a", 0.3, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_rec_tween.tween_property(rec_indicator, "scale", Vector2(1.08, 1.08), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_rec_tween.chain().parallel()
		_rec_tween.tween_property(rec_indicator, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_rec_tween.tween_property(rec_indicator, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _find_closest_node_index(freq: float) -> int:
	var closest_idx = -1
	var min_diff = 1e9
	for i in range(NOTES_VN.size()):
		var note_freq = _get_node_frequency(i)
		var diff = abs(freq - note_freq)
		if diff < min_diff:
			min_diff = diff
			closest_idx = i
	return closest_idx

func _get_stabilized_note(new_note: String) -> String:
	_detected_notes_history.append(new_note)
	if _detected_notes_history.size() > HISTORY_SIZE:
		_detected_notes_history.remove_at(0)
		
	var counts := {}
	for note in _detected_notes_history:
		if note == "": continue
		if not counts.has(note):
			counts[note] = 0
		counts[note] += 1
		
	var max_count := 0
	var stable_note := ""
	for note in counts:
		if counts[note] > max_count:
			max_count = counts[note]
			stable_note = note
			
	if max_count >= 5:
		return stable_note
	return ""

func _check_teacher_advice(closest_note: String, cents_dev: float) -> void:
	if not _recording: return
	
	var target_note = sheet_notes[_note_idx]
	if closest_note == "":
		return
		
	if closest_note == target_note:
		if cents_dev > 15.0:
			_va_say("Đúng nốt %s rồi! Nhưng cao độ lệch nhẹ. Con hãy uốn nhẹ cần đàn (bend) để khớp chuẩn nhé." % target_note)
		else:
			if randf() > 0.6:
				_va_say("Âm hài âm chuẩn xác! Kỹ thuật uốn cần nốt %s của con rất điệu nghệ." % target_note)
	else:
		_va_say("Nghe như nốt %s. Nốt mục tiêu là %s đấy. Con hãy chỉnh lại vị trí gảy hài âm hoặc góc uốn cần nhé!" % [closest_note, target_note])

func _get_average_score(scores: Array, default_val: float) -> float:
	if scores.size() == 0:
		return default_val
	var sum := 0.0
	for s in scores:
		sum += s
	return sum / scores.size()

func _on_resized() -> void:
	var w := size.x
	var h := size.y

	# 1. Top Bar responsiveness
	var top_m := $Root/TopBar/TopM as MarginContainer
	var back_btn := $Root/TopBar/TopM/TopH/BackBtn as Button
	var menu_btn := $Root/TopBar/TopM/TopH/MenuBtn as Button
	var lesson_title := $Root/TopBar/TopM/TopH/LessonTitle as Label

	if w < 600:
		top_m.add_theme_constant_override("margin_left", 12)
		top_m.add_theme_constant_override("margin_right", 12)
		back_btn.custom_minimum_size = Vector2(90, 40)
		back_btn.add_theme_font_size_override("font_size", 14)
		menu_btn.custom_minimum_size = Vector2(44, 44)
		menu_btn.add_theme_font_size_override("font_size", 24)
		lesson_title.add_theme_font_size_override("font_size", 16)
	else:
		top_m.add_theme_constant_override("margin_left", 40)
		top_m.add_theme_constant_override("margin_right", 40)
		back_btn.custom_minimum_size = Vector2(150, 48)
		back_btn.add_theme_font_size_override("font_size", 20)
		menu_btn.custom_minimum_size = Vector2(72, 72)
		menu_btn.add_theme_font_size_override("font_size", 40)
		lesson_title.add_theme_font_size_override("font_size", 24)

	# 2. Middle Content & Stats responsiveness
	var notation_m := get_node_or_null("Root/MiddleRow/MainContent/NotationArea/NotationM") as MarginContainer

	if w < 600:
		if notation_m:
			notation_m.add_theme_constant_override("margin_left", 12)
			notation_m.add_theme_constant_override("margin_right", 12)
			notation_m.add_theme_constant_override("margin_top", 8)
			notation_m.add_theme_constant_override("margin_bottom", 8)
		pitch_note.add_theme_font_size_override("font_size", 18)
		score_num.add_theme_font_size_override("font_size", 18)
	else:
		if notation_m:
			notation_m.add_theme_constant_override("margin_left", 32)
			notation_m.add_theme_constant_override("margin_right", 32)
			notation_m.add_theme_constant_override("margin_top", 18)
			notation_m.add_theme_constant_override("margin_bottom", 18)
		pitch_note.add_theme_font_size_override("font_size", 18)
		score_num.add_theme_font_size_override("font_size", 18)


	# 3. Bottom Control Bar responsiveness
	var record_m := $Root/RecordBar/RecordM as MarginContainer
	var record_h := $Root/RecordBar/RecordM/RecordH as HBoxContainer

	if w < 600:
		record_m.add_theme_constant_override("margin_left", 12)
		record_m.add_theme_constant_override("margin_right", 12)
		record_h.add_theme_constant_override("separation", 10)
		
		# Shrink button widths on mobile portrait
		record_btn.custom_minimum_size = Vector2(0, 48)
		record_btn.size_flags_horizontal = SIZE_EXPAND_FILL
		record_btn.add_theme_font_size_override("font_size", 16)
		
		var reset_btn := $Root/RecordBar/RecordM/RecordH/ResetBtn as Button
		if reset_btn:
			reset_btn.custom_minimum_size = Vector2(90, 48)
			reset_btn.add_theme_font_size_override("font_size", 15)
			
		var mode_btn := record_h.get_node_or_null("ModeToggleBtn") as Button
		if mode_btn:
			mode_btn.custom_minimum_size = Vector2(110, 40)
			mode_btn.add_theme_font_size_override("font_size", 12)
			
		var visualizer := record_h.get_node_or_null("WaveformVisualizer") as Control
		if visualizer:
			visualizer.custom_minimum_size = Vector2(100, 44)
	else:
		record_m.add_theme_constant_override("margin_left", 48)
		record_m.add_theme_constant_override("margin_right", 48)
		record_h.add_theme_constant_override("separation", 20)
		
		record_btn.custom_minimum_size = Vector2(500, 56)
		record_btn.size_flags_horizontal = SIZE_SHRINK_CENTER
		record_btn.add_theme_font_size_override("font_size", 22)
		
		var reset_btn := $Root/RecordBar/RecordM/RecordH/ResetBtn as Button
		if reset_btn:
			reset_btn.custom_minimum_size = Vector2(150, 52)
			reset_btn.add_theme_font_size_override("font_size", 18)
			
		var mode_btn := record_h.get_node_or_null("ModeToggleBtn") as Button
		if mode_btn:
			mode_btn.custom_minimum_size = Vector2(170, 44)
			mode_btn.add_theme_font_size_override("font_size", 16)
			
		var visualizer := record_h.get_node_or_null("WaveformVisualizer") as Control
		if visualizer:
			visualizer.custom_minimum_size = Vector2(320, 62)


func _style_sidebar_btn(btn: Button) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	var sb_hover := StyleBoxFlat.new()
	sb_hover.bg_color = Color(0.1, 0.35, 0.2, 0.08)
	
	btn.custom_minimum_size.y = 60
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("focus", _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	btn.add_theme_color_override("font_color", Color(0.25, 0.22, 0.20))
	btn.add_theme_color_override("font_hover_color", Color(0.1, 0.35, 0.2))
	
	btn.add_theme_color_override("icon_normal_color", Color(0.1, 0.1, 0.1))
	btn.add_theme_color_override("icon_hover_color", Color(0.1, 0.35, 0.2))
	btn.add_theme_color_override("icon_pressed_color", Color.BLACK)
	
	var f_body := load("res://assets/fonts/BeVietnamPro-Regular.ttf") as Font
	if f_body: btn.add_theme_font_override("font", f_body)
	btn.add_theme_font_size_override("font_size", 16)
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.expand_icon = true

func _set_sidebar_icon(btn: Button, icon_name: String) -> void:
	var tex = load("res://assets/textures/lucide/" + icon_name + ".svg")
	if tex:
		btn.icon = tex
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if "vertical_icon_alignment" in btn:
			btn.set("vertical_icon_alignment", 0)
