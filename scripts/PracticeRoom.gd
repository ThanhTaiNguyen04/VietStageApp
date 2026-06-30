extends Control
class_name PracticeRoom

# ─── Color Palette ─────────────────────────────────────────────────────────────
const C_GOLD       := Color("#c99a3c") # Antique Gold (matching button in screenshot)
const C_GOLD_LIGHT := Color("#fce8b3") # Light Golden highlight for dark overlays
const C_GOLD_TEXT  := Color("#8c6613") # Dark Bronze Gold for light text/labels
const C_JADE       := Color("#0e3d26") # Deep Forest Green (#0e3d26)
const C_RED_SON    := Color("#0e3d26") # Deep Forest Green primary accent
const C_CREAM      := Color("#faf6eb") # Warm Light Cream
const C_CREAM_DIM  := Color("#ede7da") # Sidebar/Header Cream
const C_GREEN_OK   := Color("#27ae60") # Rich Green for success states
const C_WARN       := Color("#b5882b") # Warm Amber for warning states
const C_RED_ERR    := Color("#a82b2b") # Ruby Red for error states

const C_BG         := Color("#faf6eb") # Main Background (Soft Cream)
const C_BG_BAR     := Color("#ede7da") # Sidebar/Header/Footer (Darker Cream)
const C_CARD       := Color("#f6f2e5") # Stats Panel Background (Warm Card Cream)
const C_TEXT       := Color("#0e3d26") # Deep Forest Green text
const C_TEXT_MUTED := Color("#5c503e") # Warm Muted Charcoal-brown text

# ─── @onready ─────────────────────────────────────────────────────────────────
@onready var linh_panel   : PanelContainer = $Root/MiddleRow/LinhPanel
@onready var char_linh    : TextureRect   = $Root/MiddleRow/LinhPanel/LinhVBox/CharLinhWrapper/CharLinh
@onready var speech_label : Label         = $Root/MiddleRow/LinhPanel/LinhVBox/SpeechBubble/SpeechM/SpeechLabel
@onready var lesson_bar   : ProgressBar   = $SettingsPanel/SettingsM/SettingsVBox/ProgressVBox/LessonBar
@onready var pitch_note   : Label         = $Root/MiddleRow/MainContent/StatsRow/PitchPanel/PitchM/PitchV/PitchNote
@onready var pitch_status : Label         = $Root/MiddleRow/MainContent/StatsRow/PitchPanel/PitchM/PitchV/PitchStatus
@onready var rhythm_bars  : HBoxContainer = $Root/MiddleRow/MainContent/StatsRow/RhythmPanel/RhythmM/RhythmV/RhythmBars
@onready var rhythm_acc   : Label         = $Root/MiddleRow/MainContent/StatsRow/RhythmPanel/RhythmM/RhythmV/RhythmAcc
@onready var score_num    : Label         = $Root/MiddleRow/MainContent/StatsRow/ScorePanel/ScoreM/ScoreV/ScoreNum
@onready var record_btn   : Button        = $Root/RecordBar/RecordM/RecordH/RecordBtn
@onready var notes_hbox   : HBoxContainer = $Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/NotesScroll/NotesHBox
@onready var target_note_label : Label    = $Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/TargetNoteLabel
@onready var target_label : Label         = $Root/StringsBoard/BoardM/BoardVBox/TargetLabel
@onready var hint_dialog  : AcceptDialog  = $HintDialog
@onready var result_dialog: AcceptDialog  = $ResultDialog
@onready var dots_hbox    : HBoxContainer = $SettingsPanel/SettingsM/SettingsVBox/DotsHBox
@onready var _board       : Control       = $Root/StringsBoard/BoardM/BoardVBox/DanTranhBoard

# --- Audio settings (simpler, no runtime bus creation) ---
var zither_volume_db: float = -6.0   # Base volume for Zither notes
var backing_volume_db: float = -28.0  # Volume for backing chords (much quieter)


# ─── State ────────────────────────────────────────────────────────────────────
var _recording   := false
var _mic_mode    := true
var _score       := 75.0
var _sim_timer   := 0.0
var _correct_pitch_hold_time := 0.0
var _float_tween : Tween
var _note_idx    := 0
var _is_wait_mode := true
var _is_demo_mode := false
var _current_note_elapsed := 0.0
var _song_bpm := 80.0
var _speed_scale := 1.0
var _current_note_hit := false
var _demo_note_plucked := false

# AI Analysis tracking variables
var _practice_time := 0.0
var _detected_onsets : PackedFloat32Array = PackedFloat32Array()
var _reference_onsets : PackedFloat32Array = PackedFloat32Array()
var _pitch_scores : Array[float] = []
var _tone_scores : Array[float] = []

var _string_streams: Array[AudioStreamWAV] = []
var _rec_tween   : Tween
var _detected_notes_history: Array[String] = []
const HISTORY_SIZE := 8
var _teacher_tip_timer := 0.0

var _eval_cooldown := 0.0
var _linh_collapsed := true
var linh_mini_btn : Button
var _collapse_timer : SceneTreeTimer = null

const NOTES_VN : Array[String] = [
	"Đô", "Rê", "Mi", "Fa", "Sol", "La", "Si",
	"Đô2", "Rê2", "Mi2", "Fa2", "Sol2", "La2", "Si2",
	"Đô3", "Rê3"
]

const LANES : Array[String] = [
	"Đô", "Rê", "Mi", "Fa", "Sol", "La", "Si",
	"Đô2", "Rê2", "Mi2", "Fa2", "Sol2", "La2", "Si2",
	"Đô3", "Rê3"
]

static var current_song_title := ""
static var current_song_sheet : Array[String] = []

var songs_list : Array = [
	{
		"title": "Bèo Dạt Mây Trôi",
		"bpm": 80.0,
		"sheet": ["Đô","Đô","Rê","Fa","Fa","Sol","La","Sol","Fa","Rê","Đô"],
		"durations": []
	},
	{
		"title": "Dạ Cổ Hoài Lang",
		"bpm": 70.0,
		"sheet": ["Đô2","Đô2","Rê2","Đô2","Fa","Sol","La","Rê","Fa","Đô2","Đô"],
		"durations": []
	},
	{
		"title": "Lý Mỹ Hưng",
		"bpm": 85.0,
		"sheet": ["Fa","Rê","Đô","Rê","Fa","Sol","Đô2","La","Sol","Fa","Đô"],
		"durations": []
	},
	{
		"title": "Đất Phương Nam",
		"bpm": 90.0,
		"sheet": ["Đô","Fa","Sol","Đô2","La","Đô2","Sol","Fa","Rê","Đô","Đô"],
		"durations": []
	},
	{
		"title": "Giấc Mơ Trưa",
		"bpm": 90.0,
		"sheet": ["Rest", "Sol", "La", "Đô2", "Rê2", "Mi2", "Sol2", "La2", "Rê3", "Rê3", "Rest", "La2", "Sol2", "Mi2", "Rê2", "Đô2", "La", "Sol", "Đô2", "Đô2", "Rest", "Đô2", "Rê2", "Mi2", "Sol2", "La2", "Sol2", "Mi2", "Rê2", "Rê2", "Rest", "Đô2", "Rê2", "Mi2", "Sol2", "La2", "Đô3", "La2", "Sol2", "Sol2", "Rest", "La2", "Sol2", "Mi2", "Rê2", "Mi2", "Rê2", "Đô2", "Đô2", "Rest", "Mi2", "Rê2", "Đô2", "Rê2", "Sol2", "Rê2", "Sol2", "Đô3", "Đô3", "Đô3", "Rest", "Mi2", "Rê2", "Sol2", "Rê2", "Rê2", "Rê2", "Rest", "Mi2", "Rê2", "Đô2", "Rê2", "Sol2", "La2", "La2", "La2", "Rest", "Sol2", "La2", "Mi2", "Rê2", "Đô2", "Rê2", "Sol2", "Sol2", "Rest", "Rê3", "Đô3", "La2", "Đô3", "Sol2", "Sol2", "Rest", "La2", "Sol2", "Mi2", "Sol2", "Rê2", "Rê2", "Rest", "Mi2", "Rê2", "Đô2", "Rê2", "Sol", "Sol", "Rest", "Đô2", "Rê2", "Mi2", "Sol2", "La2", "Sol2", "La2", "La2", "Rest", "Sol2", "La2", "Mi2", "Rê2", "Đô2", "Rê2", "Đô2", "Đô2", "Rest", "Đô2", "Rê2", "Mi2", "Sol2", "La2", "Sol2", "La2", "Đô3", "La2", "Sol2", "Mi2", "Sol2", "La2", "La2", "Rest", "Đô2", "Rê2", "Mi2", "Sol2", "La2", "Sol2", "La2", "Đô3", "Rê3", "Đô3", "La2", "Đô3", "Sol2", "Sol2", "Rest", "La2", "Sol2", "Mi2", "Sol2", "Rê2", "Mi2", "Đô2", "Đô2", "Rest", "La", "Sol", "Đô2", "Rê2", "Mi2", "Sol2", "La2", "Sol2", "Mi2", "Rê2", "Đô2", "Đô2", "Rest", "Đô2", "Rê2", "Mi2", "Sol2", "La2", "Sol2", "La2", "Đô3", "La2", "Sol2", "Mi2", "Sol2", "La2", "La2", "Rest", "Đô2", "Rê2", "Mi2", "Sol2", "La2", "Sol2", "La2", "Đô3", "Rê3", "Đô3", "La2", "Đô3", "Sol2", "Sol2", "Rest", "La2", "Sol2", "Mi2", "Sol2", "Rê2", "Mi2", "Đô2", "Đô2", "Rest", "La", "Sol", "Đô2", "Rê2", "Mi2", "Sol2", "La2", "Sol2", "Mi2", "Rê2", "Đô2", "Đô2", "Rest"],
		"durations": [
			0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 2.0, 2.0,
			0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 2.0, 2.0,
			0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 2.0, 2.0,
			0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 2.0, 2.0,
			0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 2.0, 1.0, 1.0,
			0.5, 0.5, 0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 1.0, 2.0, 1.0, 1.0,
			0.5, 0.5, 0.5, 0.5, 2.0, 1.0, 1.0,
			0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 1.0, 1.0,
			0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 2.0, 1.0, 1.0,
			0.5, 0.5, 0.5, 0.5, 1.0, 1.0, 1.0,
			0.5, 0.5, 0.5, 0.5, 2.0, 1.0, 1.0,
			0.5, 0.5, 0.5, 0.5, 2.0, 1.0, 1.0,
			0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 1.0, 1.0,
			0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 2.0, 1.0, 1.0,
			0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 2.0, 1.0, 1.0,
			0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 2.0, 1.0, 1.0,
			0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 2.0, 1.0, 1.0,
			0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 2.0, 1.0, 1.0,
			0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 2.0, 1.0, 1.0,
			0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 2.0, 1.0, 1.0,
			0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 2.0, 1.0, 1.0,
			0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 2.0, 1.0, 1.0
		]
	}
]

var sheet_notes : Array[String] = ["Đô","Đô","Rê","Fa","Fa","Sol","La","Sol","Fa","Rê","Đô"]
var sheet_durations : Array[float] = []
var note_visuals : Dictionary = {}
var note_statuses : Array[String] = []
var _last_backing_measure : int = -1

var _current_time_beats := 0.0
var _target_time_beats := 0.0

# Introductory Tutorial Overlay
var _intro_overlay : ColorRect = null
var _intro_text_lbl : Label = null
var _intro_active_note_display_lbl : Label = null
var _intro_zither_body : Control = null
var _intro_listen_btn : Button = null
var _intro_next_btn : Button = null
var _intro_audio_manager : AIAudioManager = null
var _active_player : AudioStreamPlayer = null
var _current_intro_step := 0
var _intro_slides : Array = []

const SPEECHES : Array[String] = [
	"Gảy nhẹ dây số 3,\nnhấn rung bên trái nhạn đàn.",
	"Rất tốt!\nGiữ ngón cố định hơn nhé.",
	"Cao độ đang chuẩn,\ntiếp tục nào.",
	"Âm rung mềm mại,\nnhịp đều hơn nhé.",
	"Cổ tay thả lỏng,\ngảy dứt khoát hơn.",
]

func _ready() -> void:
	for song in songs_list:
		if song["durations"].is_empty():
			for note in song["sheet"]:
				song["durations"].append(1.0)

	var pentatonic_to_western = {
		"Hò": "Đô",
		"Xự": "Rê",
		"Xang": "Fa",
		"Xê": "Sol",
		"Công": "La",
		"Liu": "Đô2",
		"Ú": "Rê2"
	}
	# Try loading from local songs_list first to preserve custom durations!
	var found_local := false
	for song in songs_list:
		if song["title"] == current_song_title:
			sheet_notes.clear()
			for note in song["sheet"]:
				sheet_notes.append(pentatonic_to_western.get(note, note))
			sheet_durations = song["durations"].duplicate()
			found_local = true
			break
			
	if not found_local:
		if current_song_title != "" and current_song_sheet.size() > 0:
			sheet_notes.clear()
			for note in current_song_sheet:
				sheet_notes.append(pentatonic_to_western.get(note, note))
		else:
			var mapped: Array[String] = []
			for note in sheet_notes:
				mapped.append(pentatonic_to_western.get(note, note))
			sheet_notes = mapped
			
		sheet_durations.clear()
		for note in sheet_notes:
			sheet_durations.append(1.0)
		
	# Initialize _song_bpm
	var song_found = false
	if current_song_title != "":
		for song in songs_list:
			if song["title"] == current_song_title:
				_song_bpm = song.get("bpm", 80.0)
				song_found = true
				break
	if not song_found:
		_song_bpm = 80.0
		
	_generate_streams()
	_set_labels()
	_build_theme()
	# Initialize audio buses and effects
	_setup_audio_buses()
	
	# Hide default NotesScroll ScrollContainer
	var scroll_container := notes_hbox.get_parent() as ScrollContainer
	if scroll_container:
		scroll_container.visible = false

	# Hide NotationArea entirely
	var notation_area := $Root/MiddleRow/MainContent/NotationArea as PanelContainer
	if notation_area:
		notation_area.visible = false

	# Hide SpeechBubble overlay as requested
	var speech_bubble := $Root/MiddleRow/LinhPanel/LinhVBox/SpeechBubble as PanelContainer
	if speech_bubble:
		speech_bubble.visible = false

	var middle_row := $Root/MiddleRow as HBoxContainer
	if middle_row:
		middle_row.visible = false


	# Create and style the NoteTrackPanel
	var track_panel := Panel.new()
	track_panel.name = "NoteTrackPanel"
	track_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	track_panel.custom_minimum_size.y = 300.0
	
	var style_box := StyleBoxFlat.new()
	style_box.bg_color = C_CARD
	style_box.border_color = C_GOLD
	style_box.border_width_top = 2; style_box.border_width_bottom = 2
	style_box.corner_radius_top_left = 12; style_box.corner_radius_top_right = 12
	style_box.corner_radius_bottom_left = 12; style_box.corner_radius_bottom_right = 12
	track_panel.add_theme_stylebox_override("panel", style_box)
	
	# Note container with clip contents
	var note_container := Control.new()
	note_container.name = "NoteContainer"
	note_container.clip_contents = true
	note_container.anchors_preset = Control.PRESET_FULL_RECT
	note_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Draw lanes lines and note names dynamically!
	var theme_font := get_theme_font("font")
	note_container.draw.connect(func() -> void:
		var w = note_container.size.x
		var h = note_container.size.y
		var count = LANES.size()
		var step = h / count
		for i in range(count):
			var y = h - i * step
			note_container.draw_line(Vector2(0, y), Vector2(w, y), Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.08), 1.0)
			note_container.draw_string(theme_font, Vector2(10, y - 5), LANES[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(C_TEXT_MUTED.r, C_TEXT_MUTED.g, C_TEXT_MUTED.b, 0.45))
	)
	track_panel.add_child(note_container)
	
	# Target Line (Glowing vertical bar to indicate evaluation hit point)
	var target_line := ColorRect.new()
	target_line.name = "TargetLine"
	target_line.color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25)
	target_line.anchor_left = 0.0
	target_line.anchor_right = 0.0
	target_line.anchor_top = 0.0
	target_line.anchor_bottom = 1.0
	target_line.offset_left = 196.0
	target_line.offset_right = 204.0 # 8px total width
	target_line.offset_top = 0.0
	target_line.offset_bottom = 0.0
	track_panel.add_child(target_line)
	
	# Solid golden core line in the center of the target bar
	var core_line := ColorRect.new()
	core_line.name = "CoreLine"
	core_line.color = C_GOLD_TEXT
	core_line.anchor_left = 0.5
	core_line.anchor_right = 0.5
	core_line.anchor_top = 0.0
	core_line.anchor_bottom = 1.0
	core_line.offset_left = -1.0
	core_line.offset_right = 1.0
	core_line.offset_top = 0.0
	core_line.offset_bottom = 0.0
	target_line.add_child(core_line)
	
	# Label indicator text for the target line
	var target_lbl := Label.new()
	target_lbl.name = "TargetLabelIndicator"
	target_lbl.text = "VẠCH GẢY"
	target_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_lbl.add_theme_color_override("font_color", C_GOLD_TEXT)
	target_lbl.add_theme_font_size_override("font_size", 10)
	target_lbl.anchor_left = 0.5
	target_lbl.anchor_right = 0.5
	target_lbl.anchor_top = 0.0
	target_lbl.anchor_bottom = 0.0
	target_lbl.offset_top = 8.0
	target_lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	target_line.add_child(target_lbl)
	
	var notation_vbox := $Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox
	if notation_vbox:
		notation_vbox.add_child(track_panel)
		notation_vbox.move_child(track_panel, notation_vbox.get_child_count() - 1)
		
	_current_time_beats = float(_note_idx)
	_target_time_beats = float(_note_idx)
	_build_notation()
	_build_strings()
	_build_dots()
	_build_rhythm_bars()
	_start_float()
	_connect_buttons()
	# Setup collapsible LinhPanel system
	_setup_collapsible_linh()
	
	# Removed char_linh.get_parent().visible = false because collapsible system handles it
	
	# Check mic permission/driver state
	if not ProjectSettings.get_setting("audio/driver/enable_input"):
		var mic_dialog := AcceptDialog.new()
		mic_dialog.title = "Cảnh Báo Thiết Bị"
		mic_dialog.dialog_text = "Ứng dụng chưa được cấp quyền truy cập Microphone hoặc tính năng Audio Input bị vô hiệu hóa trong cài đặt.\n\nVui lòng kiểm tra lại thiết bị thu âm để thực hiện bài học."
		var dialog_style := _flat(C_BG_BAR, C_GOLD, 16)
		mic_dialog.add_theme_stylebox_override("panel", dialog_style)
		mic_dialog.add_theme_color_override("title_color", C_RED_SON)
		add_child(mic_dialog)
		mic_dialog.popup_centered()
	
	# Dynamically insert premium real-time microphone waveform visualizer!
	var record_hbox := $Root/RecordBar/RecordM/RecordH
	var analyzer_script := load("res://scripts/AudioCaptureAnalyzer.gd")
	if record_hbox and analyzer_script:
		var visualizer := Control.new()
		visualizer.name = "WaveformVisualizer"
		visualizer.custom_minimum_size = Vector2(320, 62)
		visualizer.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		visualizer.set_script(analyzer_script)
		visualizer.min_frequency = 120.0
		visualizer.max_frequency = 900.0
		visualizer.volume_threshold_db = -45.0
		visualizer.visible = false
		record_hbox.add_child(visualizer)
		record_hbox.move_child(visualizer, 1) # Positioned beautifully between RecordBtn and ResetBtn
		
		# Programmatic Mode Toggle Button
		var mode_btn := Button.new()
		mode_btn.name = "ModeToggleBtn"
		mode_btn.text = "Chế độ: Micro 🎙️"
		mode_btn.custom_minimum_size = Vector2(170, 44)
		mode_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		record_hbox.add_child(mode_btn)
		record_hbox.move_child(mode_btn, 0)
		_style_outlined_btn(mode_btn)
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

		# Programmatically add pulsing "REC" recording indicator next to record button
		var rec_indicator := HBoxContainer.new()
		rec_indicator.name = "RecIndicator"
		rec_indicator.alignment = BoxContainer.ALIGNMENT_CENTER
		rec_indicator.visible = false
		
		# Small red dot
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(12, 12)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var dot_style := StyleBoxFlat.new()
		dot_style.bg_color = C_RED_SON
		dot_style.corner_radius_top_left = 6
		dot_style.corner_radius_top_right = 6
		dot_style.corner_radius_bottom_left = 6
		dot_style.corner_radius_bottom_right = 6
		dot.add_theme_stylebox_override("panel", dot_style)
		
		# REC Label
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

	char_linh.mouse_filter = Control.MOUSE_FILTER_STOP
	char_linh.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			var chat = AIChatPopup.new()
			add_child(chat)
			chat.open_chat("dan_tranh")
	)
	
	if current_song_title == "" and not SecureDataManager.has_viewed_intro("dan_tranh"):
		_show_introduction_overlay()
		
	_update_demo_mode_ui()
	_update_wait_mode_ui()
		
	# Dynamic Song & Speed Selector setup inside SettingsPanel/SettingsM/SettingsVBox
	var settings_vbox := $SettingsPanel/SettingsM/SettingsVBox as VBoxContainer
	if settings_vbox:
		var song_sel := OptionButton.new()
		song_sel.name = "SongSelector"
		song_sel.custom_minimum_size = Vector2(200, 44)
		song_sel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		# Premium Styling matching the Vietnamese classical style
		var f_body := load("res://assets/fonts/BeVietnamPro-Regular.ttf") as Font
		var sb_normal := _flat(C_BG_BAR, C_GOLD, 8)
		var sb_hover := _flat(C_BG_BAR, C_GOLD_LIGHT, 8)
		var sb_pressed := _flat(C_GOLD, C_GOLD_LIGHT, 8)
		
		song_sel.add_theme_stylebox_override("normal", sb_normal)
		song_sel.add_theme_stylebox_override("hover", sb_hover)
		song_sel.add_theme_stylebox_override("pressed", sb_pressed)
		if f_body: song_sel.add_theme_font_override("font", f_body)
		song_sel.add_theme_color_override("font_color", C_TEXT)
		song_sel.add_theme_color_override("font_hover_color", C_TEXT)
		song_sel.add_theme_font_size_override("font_size", 16)
		
		var default_idx := 0
		if current_song_title != "":
			var found := false
			for i in range(songs_list.size()):
				if songs_list[i]["title"] == current_song_title:
					default_idx = i
					found = true
					break
			if not found:
				var new_song = {
					"title": current_song_title,
					"sheet": current_song_sheet,
					"durations": []
				}
				for note in current_song_sheet:
					new_song["durations"].append(1.0)
				songs_list.append(new_song)
				default_idx = songs_list.size() - 1
		
		for i in range(songs_list.size()):
			song_sel.add_item(songs_list[i]["title"], i)
			
		song_sel.selected = default_idx
		settings_vbox.add_child(song_sel)
		settings_vbox.move_child(song_sel, 2)
		
		song_sel.item_selected.connect(func(index: int) -> void:
			_on_song_selected(index)
		)
		
		# Dynamic Speed Selector OptionButton setup
		var speed_sel := OptionButton.new()
		speed_sel.name = "SpeedSelector"
		speed_sel.custom_minimum_size = Vector2(165, 44)
		speed_sel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		speed_sel.add_theme_stylebox_override("normal", sb_normal)
		speed_sel.add_theme_stylebox_override("hover", sb_hover)
		speed_sel.add_theme_stylebox_override("pressed", sb_pressed)
		if f_body: speed_sel.add_theme_font_override("font", f_body)
		speed_sel.add_theme_color_override("font_color", C_TEXT)
		speed_sel.add_theme_color_override("font_hover_color", C_TEXT)
		speed_sel.add_theme_font_size_override("font_size", 16)
		
		speed_sel.add_item("Tốc độ: 100%", 0)
		speed_sel.add_item("Tốc độ: 80%", 1)
		speed_sel.add_item("Tốc độ: 60%", 2)
		speed_sel.add_item("Tốc độ: 50%", 3)
		speed_sel.selected = 0
		
		settings_vbox.add_child(speed_sel)
		settings_vbox.move_child(speed_sel, 3)
		
		speed_sel.item_selected.connect(func(index: int) -> void:
			match index:
				0: _speed_scale = 1.0
				1: _speed_scale = 0.8
				2: _speed_scale = 0.6
				3: _speed_scale = 0.5
			_va_say("Đã chỉnh tốc độ nốt chạy thành %d%%." % int(_speed_scale * 100))
		)


func _process(delta: float) -> void:
	if _recording:
		_practice_time += delta
		
		# Play dynamic backing chords at each measure start for "Giấc Mơ Trưa"
		if current_song_title == "Giấc Mơ Trưa":
			var current_measure := floori(_current_time_beats / 2.0)
			if current_measure != _last_backing_measure:
				_last_backing_measure = current_measure
				_play_backing_chord(current_measure)
				# Adjust backing chord volume based on user preference
				if _active_player and is_instance_valid(_active_player):
					if AudioServer.get_bus_index("Backing") != -1:
						_active_player.bus = "Backing"
						_active_player.volume_db = backing_volume_db
		
		if _is_demo_mode:
			_current_note_elapsed += delta * _speed_scale
			var target_duration = sheet_durations[_note_idx] * (60.0 / _song_bpm)
			
			if not _demo_note_plucked:
				_demo_note_plucked = true
				var target_note = sheet_notes[_note_idx]
				var target_idx = NOTES_VN.find(target_note)
				if target_idx != -1:
					# Play audio only once via _play_zither_sound (board audio disabled in demo)
					_play_zither_sound(target_idx)
					if _board:
						# Visual only — disable audio on board to avoid double playback & distortion
						_board.audio_enabled = false
						_board.pluck(target_idx)
						_board.audio_enabled = false
						
			if _current_note_elapsed >= target_duration:
				_current_note_elapsed = 0.0
				_demo_note_plucked = false
				_note_idx = (_note_idx + 1) % sheet_notes.size()
				_build_notation()
				_update_target_indicator()
		elif not _is_wait_mode:
			_current_note_elapsed += delta * _speed_scale
			var target_duration = sheet_durations[_note_idx] * (60.0 / _song_bpm)
			
			if _mic_mode:
				_process_real_audio(delta)
			else:
				_sim_timer += delta
				if _sim_timer >= 1.2:
					_sim_timer = 0.0
					if randf() > 0.3:
						_current_note_hit = true
						var target_note = sheet_notes[_note_idx]
						var target_idx = NOTES_VN.find(target_note)
						if target_idx != -1 and _board:
							_board.pluck(target_idx)
							
			if _current_note_elapsed >= target_duration:
				# Evaluate this note
				var target_note = sheet_notes[_note_idx]
				var is_rest = target_note == "Rest" or target_note == "-" or target_note == "nghỉ"
				if is_rest or _current_note_hit:
					_score = clamp(_score + 5.0, 0, 100)
					note_statuses[_note_idx] = "correct"
					if not is_rest:
						_va_say("Tuyệt vời!")
				else:
					_score = clamp(_score - 2.0, 0, 100)
					note_statuses[_note_idx] = "missed"
					_va_say("Nhỡ nhịp rồi, cố lên con!")
				_refresh_score()
				_update_rhythm()
				_current_note_elapsed = 0.0
				_current_note_hit = false
				_note_idx = (_note_idx + 1) % sheet_notes.size()
				_build_notation()
				_update_target_indicator()
		else:
			var target_note = sheet_notes[_note_idx]
			if target_note == "Rest" or target_note == "-" or target_note == "nghỉ":
				_current_note_elapsed += delta * _speed_scale
				var target_duration = sheet_durations[_note_idx] * (60.0 / _song_bpm)
				if _current_note_elapsed >= target_duration:
					_current_note_elapsed = 0.0
					_note_idx = (_note_idx + 1) % sheet_notes.size()
					_build_notation()
					_update_target_indicator()
			else:
				_current_note_elapsed = 0.0
				if _mic_mode:
					_process_real_audio(delta)
				else:
					_sim_timer += delta
					if _sim_timer >= 1.2:
						_sim_timer = 0.0
						_simulate_tick()

	# Update note rolling blocks positions
	var track_panel = $Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox.get_node_or_null("NoteTrackPanel")
	if track_panel:
		var note_container = track_panel.get_node_or_null("NoteContainer")
		if note_container and sheet_notes.size() > 0:
			var start_beat := 0.0
			for j in range(_note_idx):
				if j < sheet_durations.size():
					start_beat += sheet_durations[j]
			var bps := _song_bpm / 60.0
			_target_time_beats = start_beat + (_current_note_elapsed * bps) if _recording else start_beat
			_current_time_beats = lerp(_current_time_beats, _target_time_beats, 10.0 * delta)
			
			var PIXELS_PER_BEAT := 120.0
			var TARGET_LINE_X := 200.0
			var count = LANES.size()
			var container_h = note_container.size.y if note_container.size.y > 0 else 300.0
			var lane_h = container_h / count
			
			for i in range(sheet_notes.size()):
				if not note_visuals.has(i): continue
				var block = note_visuals[i] as Panel
				if not is_instance_valid(block): continue
				
				var note_time = block.get_meta("note_time", 0.0) as float
				var note_duration = block.get_meta("note_duration", 1.0) as float
				var note_name = block.get_meta("note_name", "") as String
				
				var note_start_x = TARGET_LINE_X + (note_time - _current_time_beats) * PIXELS_PER_BEAT
				var note_width = note_duration * PIXELS_PER_BEAT
				var note_y = _get_lane_y(note_name)
				
				block.position = Vector2(note_start_x, note_y)
				block.size = Vector2(max(5.0, note_width - 15.0), lane_h - 6.0)
				
				if note_start_x + note_width < 0:
					block.visible = false
				else:
					block.visible = true
					
				# Dynamic color updates
				if note_name == "Rest" or note_name == "-" or note_name == "nghỉ":
					pass # Keep transparent
				elif i == _note_idx:
					_set_block_color(block, C_GOLD)
				else:
					var status = note_statuses[i] if i < note_statuses.size() else "unplayed"
					if status == "correct":
						_set_block_color(block, C_GREEN_OK)
					else:
						_set_block_color(block, Color("#5c8c72"))
			
			# Pass scrolling notes state to DanTranhBoard for direct string rendering
			if _board:
				_board.sheet_notes = sheet_notes
				_board.sheet_durations = sheet_durations
				_board.note_statuses = note_statuses
				_board.current_note_idx = _note_idx
				_board.current_time_beats = _current_time_beats
				_board.is_active = _recording
				_board.queue_redraw()


# ─── Labels ───────────────────────────────────────────────────────────────────
func _set_labels() -> void:
	($Root/TopBar/TopM/TopH/BackBtn    as Button).text = "Quay lại"
	
	var diff := "Cơ bản"
	if SecureDataManager.active_lesson_id == "Node3":
		diff = "Trung bình"
	elif SecureDataManager.active_lesson_id == "Node4":
		diff = "Nâng cao"
		
	var title_lbl := "Kỹ Thuật Nhấn Dây & Rung Âm"
	if current_song_title != "":
		title_lbl = current_song_title
		diff = "Bài hát"
	else:
		if SecureDataManager.active_lesson_id == "Node2":
			title_lbl = "3 Nốt Đầu (Đô - Rê - Mi)"
		elif SecureDataManager.active_lesson_id == "Node4":
			title_lbl = "Kỹ Thuật Song Thanh"

	($Root/TopBar/TopM/TopH/LessonTag  as Label).text  = "ĐÀN TRANH  ·  KỸ THUẬT  ·  %s" % diff.to_upper()
	($Root/TopBar/TopM/TopH/LessonTitle as Label).text = title_lbl
	($SettingsPanel/SettingsM/SettingsVBox/ProgressVBox/PctLabel as Label).text = "60%" if current_song_title == "" else "100%"
	($SettingsPanel/SettingsM/SettingsVBox/CtrlBtns/HintBtn as Button).text = "Gợi ý"

	($Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/NotationLabel as Label).text = "BẢN NHẠC  —  Gảy theo dòng nốt"
	($Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/TargetNoteLabel as Label).text = "Nốt cần gảy: Đô"
	($Root/MiddleRow/MainContent/StatsRow/PitchPanel/PitchM/PitchV/PitchTitle   as Label).text = "CAO ĐỘ"
	($Root/MiddleRow/MainContent/StatsRow/RhythmPanel/RhythmM/RhythmV/RhythmTitle as Label).text = "NHỊP ĐIỆU"
	($Root/MiddleRow/MainContent/StatsRow/ScorePanel/ScoreM/ScoreV/ScoreTitle  as Label).text = "ĐIỂM SỐ"
	($Root/MiddleRow/MainContent/StatsRow/ScorePanel/ScoreM/ScoreV/ScoreSub   as Label).text = "Cao độ 82%  ·  Nhịp 71%"

	($Root/StringsBoard/BoardM/BoardVBox/BoardLabel as Label).text = "ĐÀN TRANH 16 DÂY  —  Chạm phải nhạn đàn để gảy  ·  Kéo trái để nhấn rung"
	record_btn.text = "Bắt đầu luyện tập"
	($Root/RecordBar/RecordM/RecordH/ResetBtn as Button).text = "Làm lại"

	speech_label.text = SPEECHES[0]

	hint_dialog.title = "Gợi ý kỹ thuật"
	hint_dialog.dialog_text = "Kỹ thuật gảy đàn tranh:\n\n🎵 GẢY DÂY: Chạm vào phần bên phải nhạn đàn (▲) để phát âm\n🎵 NHẤN RUNG: Giữ và kéo phần bên trái nhạn đàn để tạo rung âm\n\n• Dùng đầu ngón tay phải gảy nhẹ và dứt khoát\n• Ngón tay trái nhấn nhẹ phía trái nhạn đàn 2-3mm\n• Kéo và thả để tạo tiếng rung (vibrato)\n• Giữ cổ tay thả lỏng, ngón tay vuông góc với dây"

# ─── Theme ────────────────────────────────────────────────────────────────────
func _build_theme() -> void:
	# Background overlay
	var bg_over := get_node_or_null("BGOverlay") as ColorRect
	if bg_over:
		bg_over.color = C_BG

	# Top bar
	var top_s := _flat(C_BG_BAR, Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.15), 0)
	top_s.border_width_bottom = 2; top_s.border_width_top = 0; top_s.border_width_left = 0; top_s.border_width_right = 0
	($Root/TopBar as PanelContainer).add_theme_stylebox_override("panel", top_s)

	($Root/TopBar/TopM/TopH/LessonTag   as Label).add_theme_color_override("font_color", C_RED_SON)
	($Root/TopBar/TopM/TopH/LessonTitle as Label).add_theme_color_override("font_color", C_TEXT)
	($SettingsPanel/SettingsM/SettingsVBox/ProgressVBox/PctLabel as Label).add_theme_color_override("font_color", C_TEXT_MUTED)
	_style_progress_bar(lesson_bar, C_RED_SON, Color(0,0,0,0.08))

	var back := $Root/TopBar/TopM/TopH/BackBtn as Button
	_style_text_btn(back, C_RED_SON, C_RED_SON.lightened(0.15))
	
	var menu_btn := $Root/TopBar/TopM/TopH/MenuBtn as Button
	if menu_btn:
		_style_text_btn(menu_btn, C_RED_SON, C_RED_SON.lightened(0.15))

	var settings_panel := $SettingsPanel as PanelContainer
	if settings_panel:
		var sp_style := StyleBoxFlat.new()
		sp_style.bg_color = C_CARD
		sp_style.border_color = C_GOLD
		sp_style.border_width_left = 2; sp_style.border_width_right = 2
		sp_style.border_width_top = 2; sp_style.border_width_bottom = 2
		sp_style.corner_radius_top_left = 14; sp_style.corner_radius_top_right = 14
		sp_style.corner_radius_bottom_left = 14; sp_style.corner_radius_bottom_right = 14
		sp_style.shadow_size = 10; sp_style.shadow_color = Color(0.2, 0.15, 0.1, 0.25)
		settings_panel.add_theme_stylebox_override("panel", sp_style)
		
		var menu_title := $SettingsPanel/SettingsM/SettingsVBox/MenuTitle as Label
		if menu_title:
			menu_title.add_theme_color_override("font_color", C_TEXT)
			var f_title := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
			if f_title: menu_title.add_theme_font_override("font", f_title)

	for bn in ["HintBtn","DemoBtn","SlowBtn"]:
		var btn = $SettingsPanel/SettingsM/SettingsVBox/CtrlBtns.get_node(bn) as Button
		if btn:
			_style_outlined_btn(btn)

	# Linh panel
	var linh_s := StyleBoxEmpty.new()
	var lp = get_node_or_null("Root/MiddleRow/LinhPanel")
	if lp:
		lp.add_theme_stylebox_override("panel", linh_s)

	# Speech bubble stylebox - empty to remove the frame/border
	var bubble_s := StyleBoxEmpty.new()
	var sb = get_node_or_null("Root/MiddleRow/LinhPanel/LinhVBox/SpeechBubble")
	if not sb:
		sb = get_node_or_null("SpeechBubble")
	if sb:
		sb.add_theme_stylebox_override("panel", bubble_s)

	# High contrast text color with drop shadow for readability on dark zither board background
	speech_label.add_theme_color_override("font_color", C_GOLD_LIGHT)
	speech_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	speech_label.add_theme_constant_override("shadow_offset_x", 1)
	speech_label.add_theme_constant_override("shadow_offset_y", 1)
	speech_label.add_theme_constant_override("shadow_outline_size", 2)

	# Notation area — light parchment card
	var na_s := _flat(Color(0.99, 0.98, 0.95, 1.0), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35), 12)
	($Root/MiddleRow/MainContent/NotationArea as PanelContainer).add_theme_stylebox_override("panel", na_s)
	($Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/NotationLabel as Label).add_theme_color_override("font_color", C_TEXT_MUTED)
	($Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/TargetNoteLabel as Label).add_theme_color_override("font_color", C_TEXT)

	# Stats panels
	var stat_bg := _flat(C_CARD, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25), 12)
	($Root/MiddleRow/MainContent/StatsRow/PitchPanel  as PanelContainer).add_theme_stylebox_override("panel", stat_bg.duplicate())
	($Root/MiddleRow/MainContent/StatsRow/RhythmPanel as PanelContainer).add_theme_stylebox_override("panel", stat_bg.duplicate())
	($Root/MiddleRow/MainContent/StatsRow/ScorePanel  as PanelContainer).add_theme_stylebox_override("panel", stat_bg.duplicate())

	pitch_note.add_theme_color_override("font_color",   C_RED_SON)
	pitch_status.add_theme_color_override("font_color", C_TEXT_MUTED)
	($Root/MiddleRow/MainContent/StatsRow/PitchPanel/PitchM/PitchV/PitchTitle   as Label).add_theme_color_override("font_color", C_TEXT_MUTED)
	($Root/MiddleRow/MainContent/StatsRow/RhythmPanel/RhythmM/RhythmV/RhythmTitle as Label).add_theme_color_override("font_color", C_TEXT_MUTED)
	rhythm_acc.add_theme_color_override("font_color", C_TEXT_MUTED)
	($Root/MiddleRow/MainContent/StatsRow/ScorePanel/ScoreM/ScoreV/ScoreTitle as Label).add_theme_color_override("font_color", C_TEXT_MUTED)
	score_num.add_theme_color_override("font_color", C_RED_SON)
	($Root/MiddleRow/MainContent/StatsRow/ScorePanel/ScoreM/ScoreV/ScoreSub   as Label).add_theme_color_override("font_color", C_TEXT_MUTED)

	# Strings board — deep rosewood background
	var sb_s := StyleBoxFlat.new()
	sb_s.bg_color = Color(0.11, 0.06, 0.02, 1.0)
	sb_s.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45)
	sb_s.border_width_top = 2; sb_s.border_width_bottom = 0
	sb_s.border_width_left = 0; sb_s.border_width_right = 0
	($Root/StringsBoard as PanelContainer).add_theme_stylebox_override("panel", sb_s)
	($Root/StringsBoard/BoardM/BoardVBox/BoardLabel as Label).add_theme_color_override("font_color", Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.75))
	($Root/StringsBoard/BoardM/BoardVBox/TargetLabel as Label).add_theme_color_override("font_color", Color(1.0, 0.92, 0.70, 1.0))

	# Record bar
	var rec_bar_s := _flat(C_BG_BAR, Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.15), 0)
	rec_bar_s.border_width_top = 2; rec_bar_s.border_width_bottom = 0; rec_bar_s.border_width_left = 0; rec_bar_s.border_width_right = 0
	($Root/RecordBar as PanelContainer).add_theme_stylebox_override("panel", rec_bar_s)

	# Record button
	var rn := _flat(C_RED_SON, Color(1.0, 0.4, 0.2, 0.4), 22)
	rn.shadow_size = 10; rn.shadow_color = Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.25)
	var rh := _flat(C_RED_SON.lightened(0.12), Color(1.0, 0.4, 0.2, 0.6), 22)
	rh.shadow_size = 14; rh.shadow_color = Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.35)
	record_btn.add_theme_stylebox_override("normal",  rn)
	record_btn.add_theme_stylebox_override("hover",   rh)
	record_btn.add_theme_stylebox_override("pressed", _flat(C_RED_SON.darkened(0.15), Color(0,0,0,0.15), 22))
	record_btn.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	record_btn.add_theme_color_override("font_color", Color(1,1,1,1))

	_style_outlined_btn($Root/RecordBar/RecordM/RecordH/ResetBtn as Button)

# ─── Notation Track ───────────────────────────────────────────────────────────
func _build_notation() -> void:
	_build_notation_track()

func _build_notation_track() -> void:
	var track_panel = $Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox.get_node_or_null("NoteTrackPanel")
	if not track_panel: return
	var note_container = track_panel.get_node_or_null("NoteContainer")
	if not note_container: return
	
	# Clear old children
	for child in note_container.get_children():
		child.queue_free()
	note_visuals.clear()
	
	# Reset status array
	note_statuses.clear()
	for i in range(sheet_notes.size()):
		if i < _note_idx:
			note_statuses.append("correct")
		else:
			note_statuses.append("unplayed")
		
	# Build note blocks
	var time_beats = 0.0
	for i in range(sheet_notes.size()):
		var note_name = sheet_notes[i]
		var duration = sheet_durations[i] if i < sheet_durations.size() else 1.0
		
		var block := Panel.new()
		block.name = "NoteBlock_%d" % i
		
		var bs := StyleBoxFlat.new()
		if note_name == "Rest" or note_name == "-" or note_name == "nghỉ":
			bs.bg_color = Color(0, 0, 0, 0)
			bs.border_color = Color(0, 0, 0, 0)
		else:
			bs.bg_color = Color("#5c8c72") # Slate jade unplayed (soft sage/jade green)
			bs.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45)
			bs.border_width_left = 1; bs.border_width_right = 1
			bs.border_width_top = 1; bs.border_width_bottom = 1
			bs.corner_radius_top_left = 6; bs.corner_radius_top_right = 6
			bs.corner_radius_bottom_left = 6; bs.corner_radius_bottom_right = 6
		block.add_theme_stylebox_override("panel", bs)
		
		# Add label for note name
		var lbl := Label.new()
		if note_name == "Rest" or note_name == "-" or note_name == "nghỉ":
			lbl.text = ""
		else:
			lbl.text = note_name
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.anchors_preset = Control.PRESET_FULL_RECT
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.add_theme_font_size_override("font_size", 15)
		block.add_child(lbl)
		
		# Save metadata on the block
		block.set_meta("note_time", time_beats)
		block.set_meta("note_duration", duration)
		block.set_meta("note_name", note_name)
		
		note_container.add_child(block)
		note_visuals[i] = block
		
		time_beats += duration

func _get_lane_y(note_name: String) -> float:
	var track_panel = $Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox.get_node_or_null("NoteTrackPanel")
	if not track_panel: return 0.0
	var note_container = track_panel.get_node_or_null("NoteContainer")
	if not note_container: return 0.0
	
	var clean_note := note_name.strip_edges()
	var lane_idx = LANES.find(clean_note)
	if lane_idx == -1:
		lane_idx = 0
	var container_h = note_container.size.y if note_container.size.y > 0 else 300.0
	var step = container_h / LANES.size()
	var y = container_h - (lane_idx + 1) * step + 2.0
	return y

func _set_block_color(block: Panel, color: Color) -> void:
	if not is_instance_valid(block): return
	var sb = block.get_theme_stylebox("panel") as StyleBoxFlat
	if sb:
		var sb_dup = sb.duplicate() as StyleBoxFlat
		sb_dup.bg_color = color
		block.add_theme_stylebox_override("panel", sb_dup)

# ─── Dot progress indicators ──────────────────────────────────────────────────
func _build_dots() -> void:
	var total := 5
	var done  := 2
	for i in total:
		var d := dots_hbox.get_child(i) as ColorRect
		if d:
			d.color = C_GOLD if i < done else Color(0.85, 0.82, 0.75, 1.0)

# ─── Dan Tranh Board ─────────────────────────────────────────────────────────
func _build_strings() -> void:
	var freqs: Array[float] = []
	for i in 16:
		freqs.append(_get_string_frequency(i))
	_board.init(NOTES_VN, _string_streams, freqs)
	_board.string_plucked.connect(_on_string_plucked)
	_board.string_pressed.connect(_on_string_pressed)
	_update_target_indicator()

func _build_rhythm_bars() -> void:
	for c in rhythm_bars.get_children(): c.queue_free()
	for _i in range(14):
		var bar := ColorRect.new()
		bar.custom_minimum_size = Vector2(9, 10)
		bar.color = Color(0.85, 0.82, 0.75, 1.0)
		bar.size_flags_vertical = Control.SIZE_SHRINK_END
		rhythm_bars.add_child(bar)

# ─── Sound Generator (Karplus-Strong Plucked String Synthesis) ────────────────
func _generate_streams() -> void:
	_string_streams.resize(16)
	for i in 16:
		var freq := _get_string_frequency(i)
		_string_streams[i] = _generate_pluck_stream(freq)

func _get_string_frequency(idx: int) -> float:
	# Đàn tranh 16 dây - tần số chuẩn từ dây 1 (thấp) đến dây 16 (cao)
	# Tuning theo hệ thất cung (diatonic) Đô, Rê, Mi, Fa, Sol, La, Si
	var base_freqs = [
		130.81, # Đô (C3)
		146.83, # Rê (D3)
		164.81, # Mi (E3)
		174.61, # Fa (F3)
		196.00, # Sol (G3)
		220.00, # La (A3)
		246.94  # Si (B3)
	]
	var octave = idx / 7
	var note_in_octave = idx % 7
	return base_freqs[note_in_octave] * pow(2, octave)

func _generate_pluck_stream(freq: float) -> AudioStreamWAV:
	# ── Clean Karplus-Strong — Đàn Tranh tuned ───────────────────────────────
	const SAMPLE_RATE: int = 44100
	const DURATION: float  = 4.0   # 4 giây sustain tự nhiên
	var sample_count: int  = int(SAMPLE_RATE * DURATION)

	var delay_len: int = int(float(SAMPLE_RATE) / freq)
	if delay_len < 2:
		delay_len = 2

	# ── Khởi tạo delay line: white noise thuần ───────────────────────────────
	var delay_buf := PackedFloat32Array()
	delay_buf.resize(delay_len)
	for k in delay_len:
		delay_buf[k] = randf_range(-1.0, 1.0)

	# ── Decay tự nhiên theo tần số ────────────────────────────────────────────
	# Dây trầm rung lâu hơn dây cao (thực tế vật lý)
	var freq_ratio := clampf(freq / 1000.0, 0.0, 1.0)
	var decay: float = clampf(0.9993 - freq_ratio * 0.002, 0.9972, 0.9993)

	# ── Sinh samples bằng Karplus-Strong chuẩn ───────────────────────────────
	var samples := PackedFloat32Array()
	samples.resize(sample_count)
	var buf_pos: int = 0

	for i in sample_count:
		var next_pos: int = (buf_pos + 1) % delay_len
		# Lowpass averaging filter (standard KS)
		var new_sample: float = decay * 0.5 * (delay_buf[buf_pos] + delay_buf[next_pos])
		samples[i] = new_sample
		delay_buf[buf_pos] = new_sample
		buf_pos = (buf_pos + 1) % delay_len

	# ── Smooth attack: 10ms ramp lên từ 0 (tránh click) ─────────────────────
	var attack_samps := int(SAMPLE_RATE * 0.01)
	for i in attack_samps:
		samples[i] *= (float(i) / float(attack_samps))

	# ── Normalise và encode PCM 16-bit ────────────────────────────────────────
	var max_amp: float = 0.0
	for s in samples:
		var a := absf(s)
		if a > max_amp:
			max_amp = a
	if max_amp < 0.0001:
		max_amp = 1.0
	# Normalise tới 85% để tránh clipping khi reverb cộng thêm
	var norm_factor: float = 0.85 / max_amp

	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in sample_count:
		var val: float = clamp(samples[i] * norm_factor, -1.0, 1.0)
		var val_i16: int = int(val * 32767.0)
		var u16: int = val_i16 & 0xFFFF
		data[i * 2]     = u16 & 0xFF
		data[i * 2 + 1] = (u16 >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format   = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo   = false
	stream.data     = data
	return stream


# ─── String Signal Handlers ───────────────────────────────────────────────────
func _on_string_plucked(idx: int, plucked_note: String) -> void:
	if _is_demo_mode:
		return

	pitch_note.text   = plucked_note
	pitch_status.text = "Dây %d  —  Vừa gảy" % (idx + 1)
	pitch_status.add_theme_color_override("font_color", C_GREEN_OK)
	pitch_note.add_theme_color_override("font_color",   C_GOLD_LIGHT)

	if plucked_note == sheet_notes[_note_idx]:
		if not _is_wait_mode:
			_current_note_hit = true
			_score = clamp(_score + 4.0, 0, 100)
			_refresh_score()
			_va_say("Xuất sắc! Gảy đúng nốt rồi.")
		else:
			_note_idx = (_note_idx + 1) % sheet_notes.size()
			_build_notation()
			_update_target_indicator()
			_score = clamp(_score + 4.0, 0, 100)
			_refresh_score()
			_va_say("Xuất sắc! Gảy đúng nốt rồi.")

func _on_string_pressed(idx: int, cents_offset: float) -> void:
	if cents_offset > 5.0:
		pitch_status.text = "Dây %d  —  Đang nhấn (+%d¢)" % [idx + 1, int(cents_offset)]
		pitch_status.add_theme_color_override("font_color", C_GOLD)
		
		var note_name = NOTES_VN[idx % NOTES_VN.size()]
		if note_name == sheet_notes[_note_idx]:
			_score = clamp(_score + 0.1, 0, 100)
			_refresh_score()
			if randf() > 0.985:
				_va_say(SPEECHES[3]) # "Âm rung mềm mại, nhịp đều hơn nhé."
	else:
		pitch_status.text = "Sẵn sàng"
		pitch_status.add_theme_color_override("font_color", C_CREAM_DIM)

# ─── Float Linh ───────────────────────────────────────────────────────────────
func _start_float() -> void:
	pass

# ─── Connections ──────────────────────────────────────────────────────────────
func _connect_buttons() -> void:
	var back_btn := $Root/TopBar/TopM/TopH/BackBtn as Button
	var menu_btn := $Root/TopBar/TopM/TopH/MenuBtn as Button
	var hint_btn := $SettingsPanel/SettingsM/SettingsVBox/CtrlBtns/HintBtn as Button
	var demo_btn := $SettingsPanel/SettingsM/SettingsVBox/CtrlBtns/DemoBtn as Button
	var slow_btn := $SettingsPanel/SettingsM/SettingsVBox/CtrlBtns/SlowBtn as Button
	var reset_btn := $Root/RecordBar/RecordM/RecordH/ResetBtn as Button

	back_btn.pressed.connect(_go_back)
	menu_btn.pressed.connect(func() -> void:
		$SettingsPanel.visible = not $SettingsPanel.visible
	)
	hint_btn.pressed.connect(_show_custom_hint)
	demo_btn.pressed.connect(_toggle_demo_mode)
	slow_btn.pressed.connect(_toggle_wait_mode)
	record_btn.pressed.connect(_toggle_record)
	reset_btn.pressed.connect(_reset)

	_make_button_bouncy(back_btn)
	_make_button_bouncy(menu_btn)
	_make_button_bouncy(hint_btn)
	_make_button_bouncy(demo_btn)
	_make_button_bouncy(slow_btn)
	_make_button_bouncy(record_btn)
	_make_button_bouncy(reset_btn)

func _toggle_record() -> void:
	_recording = not _recording
	var visualizer = $Root/RecordBar/RecordM/RecordH.get_node_or_null("WaveformVisualizer")
	_update_rec_pulse(_recording)
	if _recording:
		record_btn.text = "Dừng luyện tập"
		_va_say(SPEECHES[0])
		_start_pitch_detection()
		if visualizer and _mic_mode: visualizer.visible = true
		if _board:
			_board.audio_enabled = true
		
		# Reset AI tracking
		_practice_time = 0.0
		_detected_onsets.clear()
		_pitch_scores.clear()
		_tone_scores.clear()
		_reference_onsets = PackedFloat32Array()
		for i in range(sheet_notes.size()):
			_reference_onsets.append(1.0 + i * 1.5)
	else:
		record_btn.text = "Bắt đầu luyện tập"
		if visualizer:
			visualizer.add_practice_score(_score)
		_show_custom_result()
		_stop_pitch_detection()
		if visualizer: visualizer.visible = false
		if _board:
			_board.audio_enabled = true

func _play_zither_sound(string_idx: int, volume: float = -6.0) -> void:
	if string_idx < 0 or string_idx >= 16:
		return
	# Stop any previous player
	if _active_player and is_instance_valid(_active_player):
		_active_player.stop()
		_active_player.queue_free()
		_active_player = null

	var pl := AudioStreamPlayer.new()
	pl.stream = _string_streams[string_idx]
	pl.volume_db = volume
	# Play through Master bus only — no custom bus to avoid saturation
	pl.bus = "Master"
	add_child(pl)
	pl.play()
	_active_player = pl

	# Natural fade-out — local capture prevents old tweens killing new player
	var ft = create_tween()
	ft.tween_interval(2.5)
	ft.tween_property(pl, "volume_db", -80.0, 0.8)
	ft.tween_callback(func() -> void:
		if is_instance_valid(pl):
			pl.stop()
			pl.queue_free()
		if _active_player == pl:
			_active_player = null
	)

func _toggle_demo_mode() -> void:
	_is_demo_mode = not _is_demo_mode
	if _is_demo_mode:
		_is_wait_mode = false # Disable wait mode if demo is active
		_update_wait_mode_ui()
		_va_say("Đã bật Nghe mẫu. Hệ thống sẽ tự chơi giai điệu bài hát.")
		# Board visual only — audio handled by _play_zither_sound to avoid double-play
		if _board:
			_board.audio_enabled = false
		# Automatically start playing if not already playing
		if not _recording:
			_toggle_record()
	else:
		_is_wait_mode = true
		_update_wait_mode_ui()
		_va_say("Đã tắt Nghe mẫu. Con hãy tự mình luyện tập nhé!")
		# Restore board audio for manual play
		if _board:
			_board.audio_enabled = true
		if _recording:
			_toggle_record()
	_update_demo_mode_ui()

func _update_demo_mode_ui() -> void:
	var demo_btn := $SettingsPanel/SettingsM/SettingsVBox/CtrlBtns/DemoBtn as Button
	if not demo_btn: return
	if _is_demo_mode:
		demo_btn.text = "Nghe mẫu: BẬT 🔊"
		demo_btn.modulate = Color("#76ba99") # Mint green
	else:
		demo_btn.text = "Nghe mẫu: TẮT 🔇"
		demo_btn.modulate = Color.WHITE

func _toggle_wait_mode() -> void:
	if _is_demo_mode:
		_va_say("Đang chạy Nghe mẫu. Con không thể đổi chế độ lúc này.")
		return
	_is_wait_mode = not _is_wait_mode
	if _is_wait_mode:
		_va_say("Chế độ Luyện tập: Hệ thống sẽ chờ con gảy đúng nốt nhạc.")
	else:
		_va_say("Chế độ Tự trôi: Bản nhạc sẽ trôi tự động theo nhịp độ.")
	_update_wait_mode_ui()

func _update_wait_mode_ui() -> void:
	var slow_btn := $SettingsPanel/SettingsM/SettingsVBox/CtrlBtns/SlowBtn as Button
	if not slow_btn: return
	if _is_wait_mode:
		slow_btn.text = "Chờ nốt: Bật ⏳"
		slow_btn.modulate = Color("#e5ba73") # Warm gold
	else:
		slow_btn.text = "Tự trôi: Bật 🌊"
		slow_btn.modulate = Color("#76ba99") # Mint green

func _simulate_tick() -> void:
	var ni := randi() % NOTES_VN.size()
	pitch_note.text = NOTES_VN[ni]
	var cents := randf_range(-24.0, 24.0)
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
		_build_notation()
		_update_target_indicator()

	_score = clamp(_score + randf_range(-2.0, 4.0), 0, 100)
	_refresh_score()
	_update_rhythm()
	if randi() % 4 == 0: _va_say(SPEECHES[randi() % SPEECHES.size()])

func _process_real_audio(delta: float) -> void:
	if _is_demo_mode:
		return

	if _eval_cooldown > 0.0:
		_eval_cooldown -= delta
		return
		
	var visualizer = $Root/RecordBar/RecordM/RecordH.get_node_or_null("WaveformVisualizer")
	if not visualizer: return
	
	var db = visualizer.current_amplitude_db
	var pitch = visualizer.current_pitch
	
	if db > -45.0 and pitch > 50.0:
		var target_note = sheet_notes[_note_idx]
		
		# Find the closest frequency matching the target note in all 16 strings
		var closest_target_freq := 0.0
		var min_diff := 999999.0
		for i in range(16):
			var note_name = NOTES_VN[i]
			if note_name == target_note:
				var string_freq = _get_string_frequency(i)
				var diff = abs(pitch - string_freq)
				if diff < min_diff:
					min_diff = diff
					closest_target_freq = string_freq
					
		if closest_target_freq > 0.0:
			var cents = 1200.0 * log(pitch / closest_target_freq) / log(2.0)
			if abs(cents) < 50.0:
				pitch_note.text = target_note
				
				# Scaled tolerance window based on difficulty scale
				var tolerance_cents = 12.0 / visualizer.difficulty_tolerance_scale
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
				
				# Dynamic AI scoring
				var rhythm_score = visualizer.evaluate_rhythm(_detected_onsets, _reference_onsets, 0.3 * visualizer.difficulty_tolerance_scale)
				var avg_pitch_score = _get_average_score(_pitch_scores, 80.0)
				var avg_tone_score = _get_average_score(_tone_scores, 80.0)
				
				_score = visualizer.calculate_composite_score(avg_pitch_score, rhythm_score, avg_tone_score, 100.0)
				_refresh_score()
				_update_rhythm_real()
				rhythm_acc.text = "Nhịp điệu: %d%% | Âm sắc: %d%%" % [int(rhythm_score), int(avg_tone_score)]
				
				# Pluck visual effect on board
				var target_string_idx := NOTES_VN.find(target_note)
				if target_string_idx != -1 and _board:
					_board.pluck(target_string_idx)
					
				_va_say("Tuyệt vời! Gảy đúng nốt rồi.")
				
				if not _is_wait_mode:
					_current_note_hit = true
				else:
					_note_idx = (_note_idx + 1) % sheet_notes.size()
					_build_notation()
					_update_target_indicator()
					
				_eval_cooldown = 1.0
				return
				
		var detected_note := ""
		var closest_detected_freq := 0.0
		var min_detected_diff := 999999.0
		for i in range(16):
			var string_freq = _get_string_frequency(i)
			var diff = abs(pitch - string_freq)
			if diff < min_detected_diff:
				min_detected_diff = diff
				closest_detected_freq = string_freq
				detected_note = NOTES_VN[i]
				
		if detected_note != "" and min_detected_diff < 30.0:
			pitch_note.text = detected_note
			pitch_status.text = "Lệch cao độ (Cần: %s)" % target_note
			pitch_status.add_theme_color_override("font_color", C_RED_ERR)
			pitch_note.add_theme_color_override("font_color", C_RED_ERR)
			_score = clamp(_score - 0.5 * delta, 0, 100)
			_refresh_score()
	else:
		pitch_note.text = "—"
		pitch_status.text = "Đang nghe..."
		pitch_status.add_theme_color_override("font_color", C_CREAM_DIM)
		pitch_note.add_theme_color_override("font_color", C_RED_SON)

func _update_rhythm_real() -> void:
	var bars := rhythm_bars.get_children()
	var ok := 0
	for bar in bars:
		var cr := bar as ColorRect
		if randf() > 0.1:
			ok += 1
			var h := randf_range(16.0, 56.0)
			var t := create_tween().set_parallel(true)
			t.tween_property(cr, "custom_minimum_size:y", h, 0.08)
			t.tween_property(cr, "color", C_JADE if randf() > 0.2 else C_GOLD, 0.07)
			t.chain().parallel().tween_property(cr, "custom_minimum_size:y", 10.0, 0.36)
			t.parallel().tween_property(cr, "color", Color(0.85, 0.82, 0.75, 1.0), 0.36)
	var pct := int(float(ok) / float(bars.size()) * 100.0)
	rhythm_acc.text = "Độ chính xác: %d%%" % pct
	rhythm_acc.add_theme_color_override("font_color", C_GREEN_OK)

func _refresh_score() -> void:
	score_num.text = str(int(_score))
	if _score >= 85.0:   score_num.add_theme_color_override("font_color", C_GREEN_OK)
	elif _score >= 70.0: score_num.add_theme_color_override("font_color", C_GOLD)
	else:                score_num.add_theme_color_override("font_color", C_RED_ERR)

func _update_rhythm() -> void:
	var bars := rhythm_bars.get_children()
	var ok   := 0
	for bar in bars:
		var cr := bar as ColorRect
		if randf() > 0.3:
			ok += 1
			var h := randf_range(14.0, 52.0)
			var t := create_tween().set_parallel(true)
			t.tween_property(cr, "custom_minimum_size:y", h, 0.08)
			t.tween_property(cr, "color", C_JADE if randf() > 0.2 else C_GOLD, 0.07)
			t.chain().parallel().tween_property(cr, "custom_minimum_size:y", 10.0, 0.36)
			t.parallel().tween_property(cr, "color", Color(0.85, 0.82, 0.75, 1.0), 0.36)
	var pct := int(float(ok) / float(bars.size()) * 100.0)
	rhythm_acc.text = "Độ chính xác: %d%%" % pct
	rhythm_acc.add_theme_color_override("font_color",
		C_GREEN_OK if pct >= 80 else (C_WARN if pct >= 60 else C_RED_ERR))

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
		_linh_collapsed = false
		_update_linh_visibility()
	)
	_make_button_bouncy(linh_mini_btn)
	_update_linh_visibility()

func _update_linh_visibility() -> void:
	if linh_panel:
		linh_panel.visible = not _linh_collapsed
	if linh_mini_btn:
		linh_mini_btn.visible = _linh_collapsed

func _update_target_indicator() -> void:
	var target_note := sheet_notes[_note_idx]
	var target_idx  := NOTES_VN.find(target_note)
	if target_note == "Rest" or target_note == "-" or target_note == "nghỉ":
		target_label.text      = "Dây cần gảy: Nghỉ"
		target_note_label.text = "Nốt cần gảy: Nghỉ ⏳"
		if _board: _board.set_target(-1)
	else:
		if target_idx == -1: target_idx = 0
		target_label.text      = "Dây cần gảy: %d" % (target_idx + 1)
		target_note_label.text = "Nốt cần gảy: %s" % target_note
		if _board: _board.set_target(target_idx)

func _reset() -> void:
	_score = 75.0; _recording = false; _note_idx = 0
	_current_time_beats = float(_note_idx)
	_target_time_beats = float(_note_idx)
	_eval_cooldown = 0.0
	_current_note_elapsed = 0.0
	_current_note_hit = false
	_demo_note_plucked = false
	_is_wait_mode = true
	_is_demo_mode = false
	_last_backing_measure = -1
	_update_demo_mode_ui()
	_update_wait_mode_ui()
	_build_notation()
	record_btn.text   = "Bắt Đầu Luyện Tập"
	_update_rec_pulse(false)
	var visualizer = $Root/RecordBar/RecordM/RecordH.get_node_or_null("WaveformVisualizer")
	if visualizer: visualizer.visible = false
	pitch_note.text   = "—"
	pitch_status.text = "Đang nghe..."
	pitch_status.add_theme_color_override("font_color", C_TEXT_MUTED)
	pitch_note.add_theme_color_override("font_color", C_RED_SON)
	rhythm_acc.text   = "Đang nghe..."
	_refresh_score()
	_va_say("Làm lại nào!\nLuyện tập giúp bạn cải thiện mỗi ngày.")

func _show_custom_hint() -> void:
	var popup_scene := load("res://scenes/CustomPopup.tscn") as PackedScene
	if popup_scene:
		var popup = popup_scene.instantiate()
		add_child(popup)
		var text := "[b]🎵 GẢY DÂY:[/b]\nChạm vào phần bên phải nhạn đàn (▲) để phát âm.\n\n[b]🎵 NHẤN RUNG:[/b]\nGiữ và kéo phần bên trái nhạn đàn để tạo tiếng nhấn rung.\n\n[b]💡 HƯỚNG DẪN KỸ THUẬT:[/b]\n• Dùng đầu ngón tay phải gảy nhẹ và dứt khoát.\n• Ngón tay trái nhấn nhẹ phía trái nhạn đàn 2-3mm.\n• Kéo và thả để tạo tiếng rung (vibrato).\n• Giữ cổ tay thả lỏng, ngón tay vuông góc với dây."
		popup.setup_hint("Gợi ý kỹ thuật", text)

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
		if SecureDataManager.active_lesson_id == "Node2":
			next_lesson_name = "Nhấn & Rung"
		elif SecureDataManager.active_lesson_id == "Node3":
			next_lesson_name = "Song Thanh"
			
		popup.setup_result(_score, 82.0, 71.0, 79.0, 80, "Đã mở khóa: " + next_lesson_name)

func _go_back() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.22)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))

## Pitch-detection stubs — replace with real implementation or plugin integration
func _start_pitch_detection() -> void:
	_sim_timer = 0.0
	_note_idx = 0
	_current_time_beats = float(_note_idx)
	_target_time_beats = float(_note_idx)
	_build_notation()
	_update_target_indicator()

func _stop_pitch_detection() -> void:
	_sim_timer = 0.0

func _on_song_selected(index: int) -> void:
	if index < 0 or index >= songs_list.size(): return
	var song = songs_list[index]
	
	current_song_title = song["title"]
	
	var pentatonic_to_western = {
		"Hò": "Đô",
		"Xự": "Rê",
		"Xang": "Fa",
		"Xê": "Sol",
		"Công": "La",
		"Liu": "Đô2",
		"Ú": "Rê2"
	}
	
	sheet_notes.clear()
	for note in song["sheet"]:
		sheet_notes.append(pentatonic_to_western.get(note, note))
		
	if song["durations"].is_empty():
		var durs: Array[float] = []
		for note in song["sheet"]:
			durs.append(1.0)
		song["durations"] = durs
		
	sheet_durations.assign(song["durations"])
	
	# Reset states
	_note_idx = 0
	_current_time_beats = float(_note_idx)
	_target_time_beats = float(_note_idx)
	_score = 75.0
	_sim_timer = 0.0
	_current_note_elapsed = 0.0
	_current_note_hit = false
	_demo_note_plucked = false
	_is_wait_mode = true
	_is_demo_mode = false
	_song_bpm = song.get("bpm", 80.0)
	_last_backing_measure = -1
	
	# Stop recording quietly if active
	if _recording:
		_recording = false
		_update_rec_pulse(false)
		record_btn.text = "Bắt đầu luyện tập"
		_stop_pitch_detection()
		var visualizer = $Root/RecordBar/RecordM/RecordH.get_node_or_null("WaveformVisualizer")
		if visualizer: visualizer.visible = false
		
	_set_labels()
	_update_demo_mode_ui()
	_update_wait_mode_ui()
	_build_notation()
	_build_dots()
	_build_rhythm_bars()
	_update_target_indicator()
	_refresh_score()
	
	_va_say("Đã chọn bài: " + current_song_title)

func _show_introduction_overlay() -> void:
	_current_intro_step = 0
	
	# Initialize slide data
	_intro_slides = [
		{
			"text": "Chào mừng con đến với bài học gảy đàn và rung âm cơ bản của Đàn Tranh. Đàn Tranh là một nhạc cụ gảy vô cùng thanh tao và phong phú của dân tộc ta.",
			"voice": "Chào mừng con đến với bài học gảy đàn và rung âm cơ bản của Đàn Tranh. Đàn Tranh là một nhạc cụ gảy vô cùng thanh tao và phong phú của dân tộc ta.",
			"highlighted_string": -1,
			"note_to_play": ""
		},
		{
			"text": "Cây đàn tranh của chúng ta có 16 dây chính, được lên dây theo thang năm âm (pentatonic) truyền thống gồm: Hò (Đô), Xự (Rê), Xang (Fa), Xê (Sol), Công (La).",
			"voice": "Cây đàn tranh của chúng ta có mười sáu dây chính, được lên dây theo thang năm âm truyền thống gồm: Hò tức là Đô, Xự tức là Rê, Xang tức là Fáp, Xê tức là Sol, và Công tức là La.",
			"highlighted_string": -1,
			"note_to_play": ""
		},
		{
			"text": "Dây số 1 (dây trầm nhất, ở xa con nhất) là nốt Đô (Hò). Hãy nghe thử âm thanh ngân vang của dây Đô trầm nhé.",
			"voice": "Dây số một dây trầm nhất, ở xa con nhất là nốt Đô. Hãy nghe thử âm thanh ngân vang của dây Đô trầm nhé.",
			"highlighted_string": 0,
			"note_to_play": "Đô"
		},
		{
			"text": "Dây số 2 tiếp theo là nốt Rê (Xự). Âm thanh hơi cao hơn một chút.",
			"voice": "Dây số hai tiếp theo là nốt Rê. Âm thanh hơi cao hơn một chút.",
			"highlighted_string": 1,
			"note_to_play": "Rê"
		},
		{
			"text": "Dây số 3 là nốt Mi (với thang diatonic) hoặc nốt Fa (Xang). Dưới đây là âm nốt Fa.",
			"voice": "Dây số ba là nốt Mi hoặc nốt Fa. Dưới đây là âm nốt Fa.",
			"highlighted_string": 3,
			"note_to_play": "Fa"
		},
		{
			"text": "Khi gảy, con chạm và vuốt nhẹ bên phải nhạn đàn. Khi nhấn nhấn bên trái nhạn đàn, âm thanh sẽ có tiếng nhấn rung vô cùng điệu nghệ.",
			"voice": "Khi gảy, con chạm và vuốt nhẹ bên phải nhạn đàn. Khi nhấn nhấn bên trái nhạn đàn, âm thanh sẽ có tiếng nhấn rung vô cùng điệu nghệ.",
			"highlighted_string": -1,
			"note_to_play": ""
		},
		{
			"text": "Rất giỏi! Con đã hiểu cơ bản cách gảy và nghe âm đàn tranh rồi. Hãy bấm Bắt đầu luyện tập để hòa mình vào tiếng nhạc nhé!",
			"voice": "Rất giỏi! Con đã hiểu cơ bản cách gảy và nghe âm đàn tranh rồi. Hãy bấm Bắt đầu luyện tập để hòa mình vào tiếng nhạc nhé!",
			"highlighted_string": -1,
			"note_to_play": ""
		}
	]

	# 1. Fullscreen dark jade background
	_intro_overlay = ColorRect.new()
	_intro_overlay.name = "IntroOverlay"
	_intro_overlay.color = Color("#07120aef") # Very dark jade green
	_intro_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_intro_overlay)
	
	# ─── Virtual Instructor (Mai) - 2/3 Screen Width ───
	var artist_img := TextureRect.new()
	artist_img.texture = load("res://assets/textures/virtual_artist_mai.png")
	artist_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artist_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	artist_img.size = Vector2(850, 720)
	artist_img.custom_minimum_size = Vector2(850, 720)
	artist_img.position = Vector2(-80, 0)
	_intro_overlay.add_child(artist_img)
	
	# Load premium fonts
	var f_title := load("res://assets/fonts/Lora-Bold.ttf") as Font
	var f_body := load("res://assets/fonts/BeVietnamPro-Regular.ttf") as Font
	var f_body_bold := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	
	# 2. Main Margin Container (Pushed to the right 1/3 of the screen)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 850)
	margin.add_theme_constant_override("margin_right", 50)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	_intro_overlay.add_child(margin)
	
	# 3. Content VBox (Direct child of margin)
	var right_vbox := VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	right_vbox.add_theme_constant_override("separation", 36)
	margin.add_child(right_vbox)
	
	# Cinematic Title
	var title := Label.new()
	title.text = "BÀI HỌC CƠ BẢN: ĐÀN TRANH 16 DÂY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if f_title: title.add_theme_font_override("font", f_title)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", C_GOLD)
	right_vbox.add_child(title)

	# Active note highlight display
	_intro_active_note_display_lbl = Label.new()
	_intro_active_note_display_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if f_body_bold: _intro_active_note_display_lbl.add_theme_font_override("font", f_body_bold)
	_intro_active_note_display_lbl.add_theme_font_size_override("font_size", 22)
	_intro_active_note_display_lbl.add_theme_color_override("font_color", C_GOLD_LIGHT)
	right_vbox.add_child(_intro_active_note_display_lbl)
	
	# Speech Bubble Panel Container for instructions
	var bubble := PanelContainer.new()
	var bs := StyleBoxFlat.new()
	bs.bg_color = C_BG_BAR
	bs.border_color = C_GOLD
	bs.border_width_left = 2; bs.border_width_right = 2
	bs.border_width_top = 2; bs.border_width_bottom = 2
	bs.corner_radius_top_left = 16; bs.corner_radius_top_right = 16
	bs.corner_radius_bottom_left = 16; bs.corner_radius_bottom_right = 16
	bs.shadow_size = 6
	bs.shadow_color = Color(0, 0, 0, 0.25)
	bubble.add_theme_stylebox_override("panel", bs)
	bubble.custom_minimum_size = Vector2(360, 160)
	bubble.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	right_vbox.add_child(bubble)
	
	var bubble_margin := MarginContainer.new()
	bubble_margin.add_theme_constant_override("margin_left", 16)
	bubble_margin.add_theme_constant_override("margin_right", 16)
	bubble_margin.add_theme_constant_override("margin_top", 16)
	bubble_margin.add_theme_constant_override("margin_bottom", 16)
	bubble.add_child(bubble_margin)
	
	_intro_text_lbl = Label.new()
	_intro_text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_intro_text_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_intro_text_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_intro_text_lbl.custom_minimum_size = Vector2(320, 120)
	if f_body: _intro_text_lbl.add_theme_font_override("font", f_body)
	_intro_text_lbl.add_theme_font_size_override("font_size", 15)
	_intro_text_lbl.add_theme_color_override("font_color", C_TEXT)
	bubble_margin.add_child(_intro_text_lbl)
	
	# Zither Display Container (Larger!)
	var zither_area := Control.new()
	zither_area.custom_minimum_size = Vector2(360, 360)
	zither_area.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	right_vbox.add_child(zither_area)
	
	# Zither Body (Larger!)
	var theme_font := get_theme_font("font")
	_intro_zither_body = Control.new()
	_intro_zither_body.custom_minimum_size = Vector2(340, 320)
	_intro_zither_body.size = Vector2(340, 320)
	_intro_zither_body.position = Vector2(10, 20)
	zither_area.add_child(_intro_zither_body)
	
	_intro_zither_body.draw.connect(func() -> void:
		var w = _intro_zither_body.size.x
		var h = _intro_zither_body.size.y
		# Draw wood background
		_intro_zither_body.draw_rect(Rect2(0, 0, w, h), Color("#2e180d"), true)
		# Draw gold border
		_intro_zither_body.draw_rect(Rect2(0, 0, w, h), C_GOLD, false, 2.0)
		
		# Draw 16 horizontal string lines
		var step = h / 17.0
		for i in range(16):
			var y = step * (i + 1)
			var color = Color(0.9, 0.75, 0.4, 0.4)
			var width = 1.0
			
			if _current_intro_step < _intro_slides.size():
				var slide = _intro_slides[_current_intro_step]
				var highlighted_idx = slide.get("highlighted_string", -1) as int
				if highlighted_idx == i:
					color = C_GOLD_LIGHT
					width = 3.0
				
			_intro_zither_body.draw_line(Vector2(40, y), Vector2(w - 60, y), color, width)
			
			# Draw peg/bridges
			_intro_zither_body.draw_circle(Vector2(40, y), 3.0, C_GOLD)
			_intro_zither_body.draw_circle(Vector2(w - 60, y), 3.0, C_GOLD)
			
			# Draw string label name on peg
			_intro_zither_body.draw_string(theme_font, Vector2(w - 50, y + 4), NOTES_VN[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, C_CREAM)
	)
	
	# Navigation VBox Container
	var btn_vbox := VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 12)
	btn_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	right_vbox.add_child(btn_vbox)

	# Listen Button (Nghe Thử)
	_intro_listen_btn = Button.new()
	_intro_listen_btn.text = "🔊 NGHE THỬ"
	_intro_listen_btn.custom_minimum_size = Vector2(340, 48)
	if f_body_bold: _intro_listen_btn.add_theme_font_override("font", f_body_bold)
	_intro_listen_btn.add_theme_font_size_override("font_size", 15)
	_intro_listen_btn.add_theme_color_override("font_color", C_CREAM)
	
	var sb_listen_normal := StyleBoxFlat.new()
	sb_listen_normal.bg_color = Color("#091b10") # Dark jade green
	sb_listen_normal.border_color = C_GOLD
	sb_listen_normal.border_width_left = 2; sb_listen_normal.border_width_right = 2
	sb_listen_normal.border_width_top = 2; sb_listen_normal.border_width_bottom = 2
	sb_listen_normal.corner_radius_top_left = 10; sb_listen_normal.corner_radius_top_right = 10
	sb_listen_normal.corner_radius_bottom_left = 10; sb_listen_normal.corner_radius_bottom_right = 10
	
	var sb_listen_hover := StyleBoxFlat.new()
	sb_listen_hover.bg_color = Color("#11301c") # Lighter jade
	sb_listen_hover.border_color = C_GOLD_LIGHT
	sb_listen_hover.border_width_left = 2; sb_listen_hover.border_width_right = 2
	sb_listen_hover.border_width_top = 2; sb_listen_hover.border_width_bottom = 2
	sb_listen_hover.corner_radius_top_left = 10; sb_listen_hover.corner_radius_top_right = 10
	sb_listen_hover.corner_radius_bottom_left = 10; sb_listen_hover.corner_radius_bottom_right = 10
	
	_intro_listen_btn.add_theme_stylebox_override("normal", sb_listen_normal)
	_intro_listen_btn.add_theme_stylebox_override("hover", sb_listen_hover)
	_intro_listen_btn.add_theme_stylebox_override("pressed", sb_listen_normal)
	_intro_listen_btn.pressed.connect(func() -> void:
		if _current_intro_step < _intro_slides.size():
			var slide = _intro_slides[_current_intro_step]
			var highlighted_idx = slide.get("highlighted_string", -1) as int
			if highlighted_idx != -1:
				_play_intro_zither_sound_briefly(highlighted_idx, -3.0)
	)
	btn_vbox.add_child(_intro_listen_btn)
	_make_button_bouncy(_intro_listen_btn)

	# Next / Understood Button
	_intro_next_btn = Button.new()
	_intro_next_btn.text = "ĐÃ HIỂU ➔"
	_intro_next_btn.custom_minimum_size = Vector2(340, 48)
	if f_body_bold: _intro_next_btn.add_theme_font_override("font", f_body_bold)
	_intro_next_btn.add_theme_font_size_override("font_size", 15)
	_intro_next_btn.add_theme_color_override("font_color", C_CREAM)
	
	var sb_normal := StyleBoxFlat.new()
	sb_normal.bg_color = C_RED_SON
	sb_normal.border_color = C_GOLD
	sb_normal.border_width_left = 2; sb_normal.border_width_right = 2
	sb_normal.border_width_top = 2; sb_normal.border_width_bottom = 2
	sb_normal.corner_radius_top_left = 10; sb_normal.corner_radius_top_right = 10
	sb_normal.corner_radius_bottom_left = 10; sb_normal.corner_radius_bottom_right = 10
	
	var sb_hover := StyleBoxFlat.new()
	sb_hover.bg_color = C_RED_SON.lightened(0.12)
	sb_hover.border_color = C_GOLD_LIGHT
	sb_hover.border_width_left = 2; sb_hover.border_width_right = 2
	sb_hover.border_width_top = 2; sb_hover.border_width_bottom = 2
	sb_hover.corner_radius_top_left = 10; sb_hover.corner_radius_top_right = 10
	sb_hover.corner_radius_bottom_left = 10; sb_hover.corner_radius_bottom_right = 10
	
	_intro_next_btn.add_theme_stylebox_override("normal", sb_normal)
	_intro_next_btn.add_theme_stylebox_override("hover", sb_hover)
	_intro_next_btn.add_theme_stylebox_override("pressed", sb_normal)
	_intro_next_btn.pressed.connect(_on_intro_next_pressed)
	btn_vbox.add_child(_intro_next_btn)
	_make_button_bouncy(_intro_next_btn)
	
	# Instantiate Voice Manager
	_intro_audio_manager = AIAudioManager.new()
	_intro_audio_manager.name = "IntroAudioManager"
	add_child(_intro_audio_manager)
	
	# Update the first step
	_update_cinematic_step(0)

func _on_intro_next_pressed() -> void:
	if _current_intro_step < _intro_slides.size() - 1:
		_update_cinematic_step(_current_intro_step + 1)
	else:
		SecureDataManager.mark_intro_viewed("dan_tranh")
		if _intro_audio_manager:
			_intro_audio_manager.audio_player.stop()
			_intro_audio_manager.queue_free()
			_intro_audio_manager = null
		if _active_player and is_instance_valid(_active_player):
			_active_player.stop()
			_active_player.queue_free()
			_active_player = null
		var t := create_tween()
		t.tween_property(_intro_overlay, "modulate:a", 0.0, 0.25)
		t.tween_callback(func() -> void:
			_intro_overlay.queue_free()
			_intro_overlay = null
		)

func _play_intro_zither_sound_briefly(string_idx: int, volume: float = -3.0) -> void:
	if string_idx < 0 or string_idx >= 16: return
	if _active_player and is_instance_valid(_active_player):
		_active_player.stop()
		_active_player.queue_free()
		_active_player = null

	var pl := AudioStreamPlayer.new()
	pl.stream = _string_streams[string_idx]
	pl.volume_db = volume
	add_child(pl)
	pl.play()
	_active_player = pl

	var ft = create_tween()
	ft.tween_interval(2.2)
	ft.tween_property(pl, "volume_db", -80.0, 0.5)
	ft.tween_callback(func() -> void:
		if is_instance_valid(pl):
			pl.stop()
			pl.queue_free()
		if _active_player == pl:
			_active_player = null
	)

func _update_cinematic_step(step_idx: int) -> void:
	_current_intro_step = step_idx
	var slide = _intro_slides[step_idx]
	_intro_text_lbl.text = slide.text
	
	if _intro_audio_manager:
		_intro_audio_manager.audio_player.stop()
		_intro_audio_manager.speak_vietnamese(slide.voice)
		
	var note_to_play : String = slide.get("note_to_play", "")
	var highlighted_idx = slide.get("highlighted_string", -1) as int
	if note_to_play != "" and highlighted_idx != -1:
		_intro_listen_btn.visible = true
		_intro_listen_btn.text = "🔊 NGHE THỬ NỐT " + note_to_play.to_upper()
		_intro_active_note_display_lbl.visible = true
		_intro_active_note_display_lbl.text = "Âm sắc: " + note_to_play
		
		# Auto-play a brief soft sound
		_play_intro_zither_sound_briefly(highlighted_idx, -12.0)
	else:
		_intro_listen_btn.visible = false
		_intro_active_note_display_lbl.visible = false
		if _active_player and is_instance_valid(_active_player):
			_active_player.stop()
			_active_player.queue_free()
			_active_player = null
		
	if step_idx < _intro_slides.size() - 1:
		_intro_next_btn.text = "ĐÃ HIỂU ➔"
	else:
		_intro_next_btn.text = "BẮT ĐẦU LUYỆN TẬP"
		
	if step_idx == 0:
		_intro_zither_body.modulate.a = 0.0
	else:
		_intro_zither_body.modulate.a = 1.0
		
	_intro_zither_body.queue_redraw()

# ─── Helpers ──────────────────────────────────────────────────────────────────
func _setup_audio_buses() -> void:
	# Audio buses are configured in the Godot editor (res://audio_bus_layout.tres)
	# Runtime bus/reverb creation is disabled to prevent distortion from
	# accumulated reverb tails across multiple simultaneous players.
	pass
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
	f.shadow_size = 5; f.shadow_color = Color(fill.r, fill.g, fill.b, 0.35)
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
	var bn := _flat(Color(0.16, 0.09, 0.03, 0.65), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.55), 14)
	var bh := _flat(Color(0.26, 0.15, 0.04, 0.85), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.85), 14)
	bh.shadow_size = 7; bh.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.22)
	btn.add_theme_stylebox_override("normal",  bn)
	btn.add_theme_stylebox_override("hover",   bh)
	btn.add_theme_stylebox_override("pressed", _flat(Color(0.10, 0.06, 0.02, 0.9), Color(C_GOLD.r,C_GOLD.g,C_GOLD.b,0.40), 14))
	btn.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	btn.add_theme_color_override("font_color",         C_GOLD)
	btn.add_theme_color_override("font_hover_color",   C_GOLD_LIGHT)
	btn.add_theme_color_override("font_pressed_color", C_GOLD)

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

func _find_closest_string_index(freq: float) -> int:
	var closest_idx = -1
	var min_diff = 1e9
	for i in range(16):
		var string_freq = _get_string_frequency(i)
		var diff = abs(freq - string_freq)
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
			_va_say("Đúng nốt %s rồi, nhưng cao độ chưa chuẩn lắm. Hãy nhấn nhẹ dây bên trái nhạn để chỉnh lại nhé." % target_note)
		else:
			if randf() > 0.6:
				_va_say("Tuyệt vời! Gảy rất dứt khoát và đúng cao độ nốt %s." % target_note)
	else:
		_va_say("Hình như con gảy nhầm sang nốt %s. Nốt cần gảy là %s, hãy quan sát vị trí dây nhé!" % [closest_note, target_note])

func _get_average_score(scores: Array, default_val: float) -> float:
	if scores.size() == 0:
		return default_val
	var sum := 0.0
	for s in scores:
		sum += s
	return sum / scores.size()

func _play_backing_chord(measure: int) -> void:
	var chord_indices = []
	if measure < 20: # Intro
		var step = measure / 2
		if step == 0 or step == 1 or step == 3 or step == 4 or step == 9:
			chord_indices = [0, 2, 4] # C
		elif step == 2 or step == 7:
			chord_indices = [3, 5, 7] # F
		elif step == 5 or step == 6 or step == 8:
			chord_indices = [4, 6, 8] # G
	elif measure < 35: # Verse 1
		var idx = measure - 20
		if idx in [0, 1, 12, 13, 14]:
			chord_indices = [0, 2, 4] # C
		elif idx in [2, 3, 8, 9]:
			chord_indices = [3, 5, 7] # F
		elif idx in [4, 5, 10, 11]:
			chord_indices = [4, 6, 8] # G
		elif idx in [6, 7]:
			chord_indices = [5, 7, 9] # Am
	elif measure < 51: # Verse 2
		var idx = measure - 35
		if idx in [0, 1, 8, 9]:
			chord_indices = [3, 5, 7] # F
		elif idx in [2, 3, 12, 13, 14, 15]:
			chord_indices = [0, 2, 4] # C
		elif idx in [4, 5, 10, 11]:
			chord_indices = [4, 6, 8] # G
		elif idx in [6, 7]:
			chord_indices = [5, 7, 9] # Am
	elif measure < 70: # Chorus
		var idx = measure - 51
		if idx in [0, 1, 12, 13, 14]:
			chord_indices = [0, 2, 4] # C
		elif idx in [2, 3, 8, 15, 16]:
			chord_indices = [3, 5, 7] # F
		elif idx in [4, 5, 10, 11, 17, 18]:
			chord_indices = [4, 6, 8] # G
		elif idx in [6, 7]:
			chord_indices = [5, 7, 9] # Am
	else: # Chorus repeat
		var idx = measure - 70
		if idx in [0, 1, 12, 13, 14, 19]:
			chord_indices = [0, 2, 4] # C
		elif idx in [2, 3, 8, 15, 16]:
			chord_indices = [3, 5, 7] # F
		elif idx in [4, 5, 10, 11, 17, 18]:
			chord_indices = [4, 6, 8] # G
		elif idx in [6, 7]:
			chord_indices = [5, 7, 9] # Am
			
	if chord_indices.is_empty():
		chord_indices = [0, 2, 4] # fallback C
		
	# Arpeggiate chord!
	for i in range(chord_indices.size()):
		var s_idx = chord_indices[i]
		var t = create_tween()
		t.tween_interval(i * 0.08)
		t.tween_callback(func() -> void:
			_play_backing_note(s_idx, -22.0)
		)

func _play_backing_note(string_idx: int, volume: float) -> void:
	if string_idx < 0 or string_idx >= 16: return
	var bp := AudioStreamPlayer.new()
	bp.stream = _string_streams[string_idx]
	bp.volume_db = backing_volume_db  # use the configured backing volume
	bp.bus = "Master"
	add_child(bp)
	bp.play()

	var ft = create_tween()
	ft.tween_interval(1.5)
	ft.tween_property(bp, "volume_db", -80.0, 0.4)
	ft.tween_callback(bp.queue_free)
