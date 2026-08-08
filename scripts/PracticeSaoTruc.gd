extends Control
class_name PracticeSaoTruc

# ─── Color Palette — VietStage Skill §4: Warm Vietnamese Dark Premium
const C_GOLD       := Color(0.961, 0.784, 0.259, 1.0) # #F5C842 Golden Amber
const C_GOLD_LIGHT := Color(1.00, 0.87, 0.45, 1.0)    # #FFDF73 Bright Gold
const C_GOLD_TEXT  := Color(0.961, 0.784, 0.259, 1.0) # Golden Amber
const C_JADE       := Color(0.059, 0.180, 0.118, 1.0) # #0F2E1E Deep Jade
const C_RED_SON    := Color(0.753, 0.329, 0.102, 1.0) # #C0541A Terracotta (Primary)
const C_CREAM      := Color(0.941, 0.871, 0.706, 1.0) # #F0DEB4 Warm Ivory
const C_CREAM_DIM  := Color(0.659, 0.565, 0.439, 1.0) # #A89070 Muted Sand
const C_GREEN_OK   := Color(0.298, 0.686, 0.490, 1.0) # #4CAF7D Jade Green (correct)
const C_WARN       := Color(0.961, 0.651, 0.137, 1.0) # #F5A623 Orange Warning
const C_RED_ERR    := Color(0.910, 0.271, 0.271, 1.0) # #E84545 Error Red

const C_BG         := Color(0.102, 0.071, 0.031, 1.0) # #1A1208 Deep Mahogany
const C_BG_BAR     := Color(0.071, 0.047, 0.020, 1.0) # #120C05 Darker Mahogany
const C_CARD       := Color(0.059, 0.180, 0.118, 1.0) # #0F2E1E Deep Jade (notation bg)
const C_TEXT       := Color(0.941, 0.871, 0.706, 1.0) # #F0DEB4 Warm Ivory
const C_TEXT_MUTED := Color(0.659, 0.565, 0.439, 1.0) # #A89070 Muted Sand
@onready var linh_panel   : PanelContainer = $Root/MiddleRow/LinhPanel
@onready var char_linh    : TextureRect   = $Root/MiddleRow/LinhPanel/LinhVBox/CharLinhWrapper/CharLinh
@onready var speech_label : Label         = $Root/MiddleRow/LinhPanel/LinhVBox/SpeechBubble/SpeechM/SpeechLabel
@onready var lesson_bar   : ProgressBar   = $SettingsPanel/SettingsM/SettingsVBox/ProgressVBox/LessonBar
@onready var pitch_note   : Label         = $Root/MiddleRow/MainContent/StatsRow/StatsM/StatsHBox/PitchV/PitchNote
@onready var pitch_status : Label         = $Root/MiddleRow/MainContent/StatsRow/StatsM/StatsHBox/PitchV/PitchStatus
@onready var rhythm_bars  : HBoxContainer = $Root/MiddleRow/MainContent/StatsRow/StatsM/StatsHBox/RhythmV/RhythmBars
@onready var rhythm_acc   : Label         = $Root/MiddleRow/MainContent/StatsRow/StatsM/StatsHBox/RhythmV/RhythmAcc
@onready var score_num    : Label         = $Root/MiddleRow/MainContent/StatsRow/StatsM/StatsHBox/ScoreV/ScoreNum
@onready var record_btn   : Button        = $Root/RecordBar/RecordM/RecordH/RecordBtn
@onready var notes_hbox   : HBoxContainer = $Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/NotesScroll/NotesHBox
@onready var target_note_label : Label    = $Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/TopInfoHBox/NotationVBoxLeft/TargetNoteLabel
@onready var holes_hbox   : HBoxContainer = $Root/FluteBoard/BoardM/BoardVBox/FluteFrame/FluteM/FluteStack/HoleRow
@onready var target_label : Label         = $Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/TopInfoHBox/FluteVBoxRight/TargetLabel
@onready var hint_dialog  : AcceptDialog  = $HintDialog
@onready var result_dialog: AcceptDialog  = $ResultDialog
@onready var dots_hbox    : HBoxContainer = $SettingsPanel/SettingsM/SettingsVBox/DotsHBox
@onready var breath_progress : ProgressBar = $Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/TopInfoHBox/FluteVBoxRight/BreathHBox/BreathProgress
@onready var breath_status   : Label       = $Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/TopInfoHBox/FluteVBoxRight/BreathHBox/BreathStatus
var _recording   := false
var _mic_mode    := true
var _score       := 75.0
var _sim_timer   := 0.0
var _ignore_input_timer := 0.0
var _correct_pitch_hold_time := 0.0
var _waiting_for_breath_release := false
var _float_tween : Tween
var _note_idx    := 0

# AI Analysis tracking variables
var _practice_time := 0.0
var _detected_onsets : PackedFloat32Array = PackedFloat32Array()
var _reference_onsets : PackedFloat32Array = PackedFloat32Array()
var _pitch_scores : Array[float] = []
var _breath_scores : Array[float] = []
var _last_rhythm_score := 80.0


var _count_in_timer := 3.0
var _count_in_step := 3
var _is_wait_mode := false
var _is_demo_mode := false
var _speed_scale := 1.0
var _total_mistakes := 0
var _song_bpm := 100.0
var _current_note_elapsed := 0.0
var _current_note_correct_frames := 0
var _current_note_total_frames := 0

var _covered_states : Array[bool] = [true, true, true, true, true, true]
var _flute_streams : Dictionary = {}
var _active_player : AudioStreamPlayer = null
var _breath_pressure := 0.0
var _rec_tween   : Tween
var _detected_notes_history: Array[String] = []
const HISTORY_SIZE := 8
var _teacher_tip_timer := 0.0
var _auto_blow := false
var _viewport_scroll_y := 0.0

# Zither backing track variables
var _lesson_mode := 0 # 0: Học nốt, 1: Nhạc nền
var _backing_playing := false
var _backing_beat_idx := 0
var _backing_timer := 0.0
const BEAT_DURATION := 0.8
var _lesson_beats : Array = []
var _zither_streams : Dictionary = {}
var _waveform_visualizer: Control = null

var note_statuses : Array[String] = []
var note_visuals : Dictionary = {}
var _intro_audio_manager : AIAudioManager = null
var _current_intro_step := 0
var _intro_slides : Array = []
var _intro_hole_cols : Array[VBoxContainer] = []
var _intro_overlay : ColorRect = null
var _intro_text_lbl : Label = null
var _intro_flute_body : Control = null
var _intro_next_btn : Button = null
var _intro_listen_btn : Button = null
var _intro_active_note_display_lbl : Label = null
var _active_note_is_correct := false
var _active_note_is_heard := false
const LANES := ["Đô", "Rê", "Mi", "Fa", "Sol", "La", "Si", "Đô2", "Rê2", "Mi2", "Fa2", "Sol2", "La2", "Si2", "Đô3"]

var _eval_cooldown := 0.0
var _linh_collapsed := true
var linh_mini_btn : Button
var _collapse_timer : SceneTreeTimer = null

const FREQS := {
	"Đô": 523.25, # C5 (Vietnamese Sáo C5 Đô lowest note)
	"Rê": 587.33, # D5
	"Mi": 659.25, # E5
	"Fa": 698.46, # F5
	"Sol": 783.99, # G5
	"La": 880.00, # A5
	"Si": 987.77,  # B5
	"Đô2": 1046.50, # C6
	"Rê2": 1174.66, # D6
	"Mi2": 1318.51, # E6
	"Fa2": 1396.91, # F6
	"Sol2": 1567.98, # G6
	"La2": 1760.00, # A6
	"Si2": 1975.53,  # B6
	"Đô3": 2093.00 # C7
}

const FINGERINGS := {
	"Đô": [true, true, true, true, true, true],
	"Rê": [true, true, true, true, true, false],
	"Mi": [true, true, true, true, false, false],
	"Fa": [true, true, true, false, false, false],
	"Sol": [true, true, false, false, false, false],
	"La": [true, false, false, false, false, false],
	"Si": [false, false, false, false, false, false],
	"Đô2": [true, true, true, true, true, true],
	"Rê2": [true, true, true, true, true, false],
	"Mi2": [true, true, true, true, false, false],
	"Fa2": [true, true, true, false, false, false],
	"Sol2": [true, true, false, false, false, false],
	"La2": [true, false, false, false, false, false],
	"Si2": [false, false, false, false, false, false],
	"Đô3": [true, true, true, true, true, true]
}

const NOTES_VN : Array[String] = [
	"Đô", "Rê", "Mi", "Fa", "Sol", "La", "Si",
	"Đô2", "Rê2", "Mi2", "Fa2", "Sol2", "La2", "Si2", "Đô3"
]
static var current_song_title := ""
static var current_song_sheet : Array[String] = []
static var current_song_durations : Array[float] = []
static var current_song_bpm := 0.0

var sheet_notes : Array[String] = [
	"Đô", "Rê", "Mi", "Fa", "Sol", "La", "Si"
]

var sheet_durations : Array[float] = [
	2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0
]

var songs_list : Array[Dictionary] = [
	{
		"title": "Inh Lả Ơi",
		"bpm": 110.0,
		"sheet": [
			"Đô2", "La", "Si", "Đô2", "Rest", "Đô2", "Sol", "La", "Rest", "Đô2", "Sol",
			"Fa", "Đô2", "Si", "La", "Sol", "Rest", "Fa", "La", "Đô2", "Sol",
			"Sol", "Sol", "Fa", "Fa", "Rest", "Đô2", "Sol", "La", "Rest", "Đô2", "Sol", "Đô2", "Rest"
		],
		"durations": [
			1.0, 0.5, 0.5, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
			1.0, 1.0, 0.5, 0.5, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
			1.0, 0.5, 0.5, 1.0, 1.0, 1.0, 0.5, 0.5, 1.0, 1.0, 1.0, 1.0, 1.0
		]
	},
	{
		"title": "Futari no Kimochi",
		"bpm": 88.0,
		"sheet": [
			"La", "La", "Đô2", "Rê2", "Rê2", "Mi2", "Rê2", "Đô2", "Rê2", "Mi2",
			"Mi2", "Rê2", "Đô2", "La", "Sol", "La", "Đô2",
			"La", "Sol", "La", "Đô2", "Rê2", "Mi2", "Sol2", "Mi2", "Rê2", "Mi2",
			"Mi2", "Rê2", "Đô2", "La", "Sol", "La", "Rê2", "Đô2", "La"
		],
		"durations": [
			0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 1.5,
			0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 2.0,
			0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 1.5,
			0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 2.0
		]
	},
	{
		"title": "Lý Hoài Nam",
		"bpm": 80.0,
		"sheet": ["Đô", "Đô", "Rê", "Mi", "Mi", "Fa", "Sol", "Fa", "Mi", "Rê", "Đô"],
		"durations": [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0]
	},
	{
		"title": "Lòng Mẹ",
		"bpm": 76.0,
		"sheet": ["Đô", "Mi", "Sol", "La", "Sol", "Mi", "Rê", "Mi", "Rê", "Đô", "Đô"],
		"durations": [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0]
	},
	{
		"title": "Trống Cơm",
		"bpm": 100.0,
		"sheet": ["Sol", "La", "Si", "Sol", "La", "Sol", "Fa", "Mi", "Rê", "Mi", "Đô"],
		"durations": [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0]
	}
]

const HOLES    := 6
const SPEECHES : Array[String] = [
	"Thở đều, môi khép nhẹ.",
	"Giữ hơi ổn định nhé.",
	"Tốt lắm, âm rõ rồi.",
	"Cổ tay thả lỏng, đừng gồng.",
]

func _is_rest_note(note: String) -> bool:
	return note == "Rest" or note == "Nghỉ"

func _process_rest_note(delta: float) -> bool:
	if sheet_notes.is_empty():
		return false
	var target_note = sheet_notes[_note_idx]
	if not _is_rest_note(target_note):
		return false

	_current_note_elapsed += delta
	var target_duration = sheet_durations[_note_idx] * (60.0 / _song_bpm)
	pitch_note.text = "Nghỉ"
	pitch_status.text = "Giữ khoảng ngắt"
	pitch_status.add_theme_color_override("font_color", C_GOLD)
	pitch_note.add_theme_color_override("font_color", C_GOLD)
	target_note_label.text = "Khoảng nghỉ"
	target_label.text = "Tạm nghỉ hơi theo đúng trường độ"

	if _current_note_elapsed >= target_duration:
		if _note_idx < note_statuses.size():
			note_statuses[_note_idx] = "correct"
		_current_note_elapsed = 0.0
		_note_idx = (_note_idx + 1) % sheet_notes.size()
		_build_notation()
		_update_target_indicator()
	return true

func _ready() -> void:
	_setup_audio_bus()
	# Setup collapsible LinhPanel system
	_setup_collapsible_linh()
	
	current_song_title = SecureDataManager.data.get("current_song_title", "")
	if current_song_title != "":
		sheet_notes.assign(current_song_sheet)
		sheet_durations.assign(current_song_durations)
		if current_song_bpm > 0.0:
			_song_bpm = current_song_bpm
		if sheet_durations.size() != sheet_notes.size():
			sheet_durations.clear()
			for note in sheet_notes:
				sheet_durations.append(1.0)
	else:
		if sheet_durations.size() != sheet_notes.size():
			sheet_durations.clear()
			for note in sheet_notes:
				sheet_durations.append(1.0)
	
	# Bulletproof safety: if sheet_notes is empty under any scenario, populate with default notes
	if sheet_notes.is_empty():
		sheet_notes.assign(["Đô", "Rê", "Mi", "Fa", "Sol", "La", "Si"])
		sheet_durations.clear()
		for note in sheet_notes:
			sheet_durations.append(1.0)
	_generate_streams()
	_set_labels()
	_build_theme()
	
	# Hide default NotesScroll ScrollContainer
	var scroll_container := notes_hbox.get_parent() as ScrollContainer
	if scroll_container:
		scroll_container.visible = false
		
	# Hide stats row completely on mobile as requested
	var stats_row := $Root/MiddleRow/MainContent/StatsRow as Control
	if stats_row:
		stats_row.visible = false
		
	var flute_board := $Root/FluteBoard as PanelContainer
	if flute_board:
		flute_board.custom_minimum_size.y = 180
		
	# Hide TopInfoHBox as per user request to free up space
	var top_info := $Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/TopInfoHBox as Control
	if top_info:
		top_info.visible = false
		
		# Shrink margins and spaces of the flute board to fit
		var board_m := flute_board.get_node_or_null("BoardM") as MarginContainer
		if board_m:
			board_m.add_theme_constant_override("margin_top", 4)
			board_m.add_theme_constant_override("margin_bottom", 4)
			board_m.add_theme_constant_override("margin_left", 24)
			board_m.add_theme_constant_override("margin_right", 24)
			
		var board_vbox := flute_board.get_node_or_null("BoardM/BoardVBox") as VBoxContainer
		if board_vbox:
			board_vbox.add_theme_constant_override("separation", 0)
			
		var flute_m := flute_board.get_node_or_null("BoardM/BoardVBox/FluteFrame/FluteM") as MarginContainer
		if flute_m:
			flute_m.add_theme_constant_override("margin_top", 4)
			flute_m.add_theme_constant_override("margin_bottom", 4)
			
		var right_vbox := $Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/TopInfoHBox/FluteVBoxRight as VBoxContainer
		if right_vbox:
			var board_label := right_vbox.get_node_or_null("BoardLabel") as Label
			if board_label: board_label.add_theme_font_size_override("font_size", 20)
			if target_label: target_label.add_theme_font_size_override("font_size", 18)
			var guidance_label := right_vbox.get_node_or_null("GuidanceLabel") as Label
			if guidance_label: guidance_label.add_theme_font_size_override("font_size", 17)
			
			var breath_label := right_vbox.get_node_or_null("BreathHBox/BreathLabel") as Label
			if breath_label: breath_label.add_theme_font_size_override("font_size", 17)
			if breath_status: breath_status.add_theme_font_size_override("font_size", 17)
			if breath_progress: breath_progress.custom_minimum_size.y = 12
		
	# Create and style the NoteTrackPanel
	var track_panel := Panel.new()
	track_panel.name = "NoteTrackPanel"
	track_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	track_panel.custom_minimum_size.y = 450
	
	# Apply premium dark wood and gold stylebox
	var style_box := StyleBoxFlat.new()
	style_box.bg_color = Color(0.08, 0.08, 0.1, 0.95)
	style_box.border_color = C_GOLD
	style_box.border_width_top = 2; style_box.border_width_bottom = 2
	style_box.corner_radius_top_left = 18; style_box.corner_radius_top_right = 18
	style_box.corner_radius_bottom_left = 18; style_box.corner_radius_bottom_right = 18
	track_panel.add_theme_stylebox_override("panel", style_box)
	
	# Note container with clip contents
	var note_container := Control.new()
	note_container.name = "NoteContainer"
	note_container.clip_contents = true
	note_container.anchors_preset = Control.PRESET_FULL_RECT
	note_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Draw lanes lines and note names dynamically with vertical scroll support!
	var theme_font := get_theme_font("font")
	note_container.draw.connect(func() -> void:
		var w = note_container.size.x
		var h = note_container.size.y
		var count = LANES.size()
		var lane_h := 90.0
		for i in range(count):
			var y = h - (i * lane_h - _viewport_scroll_y + lane_h)
			var bottom_y = y + lane_h
			if bottom_y >= -20 and y <= h + 20:
				note_container.draw_line(Vector2(0, bottom_y), Vector2(w, bottom_y), Color(1.0, 1.0, 1.0, 0.08), 1.0)
				if i % 2 == 0:
					note_container.draw_rect(Rect2(0, y, w, lane_h), Color(1.0, 1.0, 1.0, 0.018))
				note_container.draw_string(theme_font, Vector2(10, y + (lane_h / 2.0) + 4.0), LANES[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 1.0, 1.0, 0.45))
		
		# Draw Clef and Time signature on the left
		note_container.draw_string(theme_font, Vector2(5, 120), "𝄞", HORIZONTAL_ALIGNMENT_LEFT, -1, 70, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.7))
		note_container.draw_string(theme_font, Vector2(35, 100), "4", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.7))
		note_container.draw_string(theme_font, Vector2(35, 140), "4", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.7))

	)
	track_panel.add_child(note_container)
	
	# Target Line (Glowing vertical bar to indicate evaluation hit point)
	var target_line := ColorRect.new()
	target_line.name = "TargetLine"
	target_line.color = Color(1.0, 0.6, 0.1, 0.25) # Soft orange glow
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
	core_line.color = Color(1.0, 0.82, 0.2, 0.95) # Gold core
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
	target_lbl.text = "VẠCH THỔI"
	target_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
	target_lbl.add_theme_font_size_override("font_size", 15)
	target_lbl.anchor_left = 0.5
	target_lbl.anchor_right = 0.5
	target_lbl.anchor_top = 0.0
	target_lbl.anchor_bottom = 0.0
	target_lbl.offset_top = 8.0
	target_lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	target_line.add_child(target_lbl)
	
	# Feedback Needle
	var needle := ColorRect.new()
	needle.name = "FeedbackNeedle"
	needle.custom_minimum_size = Vector2(38, 9)
	needle.color = Color("#76ba99")
	needle.visible = false
	track_panel.add_child(needle)
	
	var notation_vbox := $Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox
	if notation_vbox:
		notation_vbox.add_child(track_panel)
		notation_vbox.move_child(track_panel, notation_vbox.get_child_count() - 1)

	_build_notation()
	_build_flute()
	_build_dots()
	_build_rhythm_bars()
	_start_float()
	_connect_buttons()
	# Removed duplicate _setup_collapsible_linh() call
	# Removed char_linh.get_parent().visible = false because collapsible system handles it
	# Dynamic Song & Speed Selector setup inside SettingsPanel/SettingsM/SettingsVBox
	var settings_vbox := $SettingsPanel/SettingsM/SettingsVBox as VBoxContainer
	if settings_vbox:
		var song_sel := OptionButton.new()
		song_sel.name = "SongSelector"
		song_sel.custom_minimum_size = Vector2(300, 66)
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
		song_sel.add_theme_font_size_override("font_size", 24)
		
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
					"bpm": current_song_bpm if current_song_bpm > 0.0 else 90.0,
					"sheet": current_song_sheet,
					"durations": current_song_durations.duplicate()
				}
				if new_song["durations"].size() != current_song_sheet.size():
					new_song["durations"].clear()
					for note in current_song_sheet:
						new_song["durations"].append(1.0)
				songs_list.append(new_song)
				default_idx = songs_list.size() - 1
		
		for i in range(songs_list.size()):
			song_sel.add_item(songs_list[i]["title"], i)
			
		song_sel.selected = default_idx
		settings_vbox.add_child(song_sel)
		# Place it immediately after the HSeparator (index 1)
		settings_vbox.move_child(song_sel, 2)
		
		song_sel.item_selected.connect(func(index: int) -> void:
			_on_song_selected(index)
		)
		
		# Dynamic Speed Selector OptionButton setup
		var speed_sel := OptionButton.new()
		speed_sel.name = "SpeedSelector"
		speed_sel.custom_minimum_size = Vector2(248, 66)
		speed_sel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		speed_sel.add_theme_stylebox_override("normal", sb_normal)
		speed_sel.add_theme_stylebox_override("hover", sb_hover)
		speed_sel.add_theme_stylebox_override("pressed", sb_pressed)
		if f_body: speed_sel.add_theme_font_override("font", f_body)
		speed_sel.add_theme_color_override("font_color", C_TEXT)
		speed_sel.add_theme_color_override("font_hover_color", C_TEXT)
		speed_sel.add_theme_font_size_override("font_size", 24)
		
		speed_sel.add_item("Tốc độ: 100%", 0)
		speed_sel.add_item("Tốc độ: 80%", 1)
		speed_sel.add_item("Tốc độ: 60%", 2)
		speed_sel.add_item("Tốc độ: 50%", 3)
		speed_sel.selected = 0
		
		settings_vbox.add_child(speed_sel)
		# Place it immediately after the SongSelector (now at index 2)
		settings_vbox.move_child(speed_sel, 3)
		
		speed_sel.item_selected.connect(func(index: int) -> void:
			match index:
				0: _speed_scale = 1.0
				1: _speed_scale = 0.8
				2: _speed_scale = 0.6
				3: _speed_scale = 0.5
			_va_say("Đã chỉnh tốc độ nốt chạy thành %d%%." % int(_speed_scale * 100))
		)
	
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
	
	# Dynamically insert premium real-time microphone waveform visualizer inside SettingsPanel!
	var settings_ctrl_btns := $SettingsPanel/SettingsM/SettingsVBox/CtrlBtns as VBoxContainer
	var record_hbox := $Root/RecordBar/RecordM/RecordH
	var analyzer_script := load("res://scripts/AudioCaptureAnalyzer.gd")
	if settings_ctrl_btns and record_hbox and analyzer_script:
		var visualizer := Control.new()
		visualizer.name = "WaveformVisualizer"
		visualizer.custom_minimum_size = Vector2(0, 93)
		visualizer.set_script(analyzer_script)
		var profile_script = load("res://scripts/InstrumentPitchProfile.gd")
		var profile = profile_script.new()
		profile.notes.assign(FREQS.keys())
		var freqs_array: Array[float] = []
		var mappings_array: Array[int] = []
		var keys = FREQS.keys()
		for i in range(keys.size()):
			freqs_array.append(FREQS[keys[i]])
			mappings_array.append(i)
		profile.frequencies = PackedFloat32Array(freqs_array)
		profile.physical_mappings = mappings_array
		
		profile.min_frequency = 250.0
		profile.max_frequency = 2200.0
		profile.volume_threshold_db = -45.0
		profile.cents_tolerance = 40.0
		profile.hold_time_sec = 0.40
		profile.is_plucked_instrument = false
		
		visualizer.pitch_profile = profile
		visualizer.min_frequency = 250.0
		visualizer.max_frequency = 2200.0
		visualizer.volume_threshold_db = -32.0
		visualizer.visible = false
		settings_ctrl_btns.add_child(visualizer)
		_waveform_visualizer = visualizer
		
		# Programmatic Mode Toggle Button in SettingsPanel
		var mode_btn := Button.new()
		mode_btn.name = "ModeToggleBtn"
		mode_btn.text = "Chế độ: Micro 🎙️"
		mode_btn.custom_minimum_size = Vector2(0, 72)
		settings_ctrl_btns.add_child(mode_btn)
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

		# Programmatically add pulsing "REC" recording indicator next to record button in record_hbox
		var rec_indicator := HBoxContainer.new()
		rec_indicator.name = "RecIndicator"
		rec_indicator.alignment = BoxContainer.ALIGNMENT_CENTER
		rec_indicator.visible = false
		
		# Small red dot
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(18, 18)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var dot_style := StyleBoxFlat.new()
		dot_style.bg_color = C_RED_SON
		dot_style.corner_radius_top_left = 9
		dot_style.corner_radius_top_right = 9
		dot_style.corner_radius_bottom_left = 9
		dot_style.corner_radius_bottom_right = 9
		dot.add_theme_stylebox_override("panel", dot_style)
		
		# REC Label
		var lbl := Label.new()
		lbl.text = "REC"
		lbl.add_theme_font_size_override("font_size", 21)
		lbl.add_theme_color_override("font_color", C_RED_SON)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		rec_indicator.add_child(dot)
		rec_indicator.add_child(lbl)
		rec_indicator.add_theme_constant_override("separation", 6)
		rec_indicator.custom_minimum_size = Vector2(90, 45)
		
		record_hbox.add_child(rec_indicator)
		# Position next to record button (ResetBtn is 0, RecordBtn is 1)
		record_hbox.move_child(rec_indicator, 2)
		
		# Dynamically add the Auto-Blow toggle button inside SettingsPanel!
		var auto_blow_btn := Button.new()
		auto_blow_btn.name = "AutoBlowBtn"
		auto_blow_btn.text = "Hơi tự động: Tắt"
		auto_blow_btn.toggle_mode = true
		auto_blow_btn.button_pressed = false
		auto_blow_btn.custom_minimum_size = Vector2(0, 72)
		
		var f_btn_bold := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
		
		var bn := _flat(C_CARD, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45), 14)
		var bh := _flat(C_CARD, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.85), 14)
		bh.shadow_size = 5; bh.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.15)
		var bp := _flat(C_GOLD, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.85), 14)
		
		auto_blow_btn.add_theme_stylebox_override("normal",  bn)
		auto_blow_btn.add_theme_stylebox_override("hover",   bh)
		auto_blow_btn.add_theme_stylebox_override("pressed", bp)
		auto_blow_btn.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
		if f_btn_bold: auto_blow_btn.add_theme_font_override("font", f_btn_bold)
		auto_blow_btn.add_theme_color_override("font_color",         C_TEXT)
		auto_blow_btn.add_theme_color_override("font_hover_color",   C_GOLD_LIGHT)
		auto_blow_btn.add_theme_color_override("font_pressed_color", Color.WHITE)
		auto_blow_btn.add_theme_font_size_override("font_size", 21)
		
		auto_blow_btn.toggled.connect(func(pressed: bool) -> void:
			_auto_blow = pressed
			if pressed:
				auto_blow_btn.text = "Hơi tự động: Bật"
				_va_say("Đã bật hơi thở tự động. Con chỉ cần tập trung bấm đúng các nốt nhạc nhé!")
			else:
				auto_blow_btn.text = "Hơi tự động: Tắt"
				_va_say("Đã tắt hơi tự động. Bây giờ hệ thống sẽ thu âm hơi thở thật từ microphone.")
		)
		
		settings_ctrl_btns.add_child(auto_blow_btn)
		_make_button_bouncy(auto_blow_btn)
		
		# Dynamically add the Lesson Mode toggle button inside SettingsPanel!
		var lesson_mode_btn := Button.new()
		lesson_mode_btn.name = "LessonModeBtn"
		lesson_mode_btn.text = "Bài học: Học nốt"
		lesson_mode_btn.toggle_mode = true
		lesson_mode_btn.button_pressed = false
		lesson_mode_btn.custom_minimum_size = Vector2(0, 72)
		
		lesson_mode_btn.add_theme_stylebox_override("normal",  bn)
		lesson_mode_btn.add_theme_stylebox_override("hover",   bh)
		lesson_mode_btn.add_theme_stylebox_override("pressed", bp)
		lesson_mode_btn.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
		if f_btn_bold: lesson_mode_btn.add_theme_font_override("font", f_btn_bold)
		lesson_mode_btn.add_theme_color_override("font_color",         C_TEXT)
		lesson_mode_btn.add_theme_color_override("font_hover_color",   C_GOLD_LIGHT)
		lesson_mode_btn.add_theme_color_override("font_pressed_color", Color.WHITE)
		lesson_mode_btn.add_theme_font_size_override("font_size", 21)
		
		lesson_mode_btn.toggled.connect(func(pressed: bool) -> void:
			if _recording:
				lesson_mode_btn.set_pressed_no_signal(not pressed)
				_va_say("Con hãy dừng ghi âm trước khi chuyển bài học nhé!")
				return
			
			_lesson_mode = 1 if pressed else 0
			if pressed:
				lesson_mode_btn.text = "Bài học: Nhạc nền"
				_va_say("Đã chuyển sang Bài 2: Luyện tập với nhạc nền zither. Hãy chuẩn bị ghi âm nhé!")
			else:
				lesson_mode_btn.text = "Bài học: Học nốt"
				_va_say("Đã chuyển sang Bài 1: Học từng nốt. Cô giáo sẽ thổi mẫu từng nốt để con làm theo.")
		)
		
		settings_ctrl_btns.add_child(lesson_mode_btn)
		_make_button_bouncy(lesson_mode_btn)
		
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.35)

	# Setup interactive teacher to open AI chat
	char_linh.mouse_filter = Control.MOUSE_FILTER_STOP
	char_linh.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			var chat = AIChatPopup.new()
			add_child(chat)
			chat.open_chat("sao_truc")
	)
	
	# Introduction overlay bypassed per user request to start clean practice instantly
	pass

	_setup_fullscreen_video_practice("res://image/saotruc.png")


func _process(delta: float) -> void:
	var effective_delta = delta * _speed_scale
	if not _is_wait_mode and not _is_demo_mode and _count_in_timer > 0.0:
		_count_in_timer -= effective_delta
		var current_step = int(ceil(_count_in_timer))
		if current_step != _count_in_step:
			_count_in_step = current_step
			pitch_note.text = str(_count_in_step) if _count_in_step > 0 else "Bắt đầu!"
			pitch_status.text = "Chuẩn bị vào nhịp..."
			pitch_status.add_theme_color_override("font_color", C_GOLD)
			pitch_note.add_theme_color_override("font_color", C_GOLD)
		if _count_in_timer > 0.0:
			return # Pause the game while counting in

	if _recording:
		_practice_time += effective_delta
		if _current_note_elapsed < 0.0:
			_current_note_elapsed += effective_delta
			
			pitch_note.text = "—"
			var prep_sec := int(ceil(abs(_current_note_elapsed)))
			pitch_status.text = "Chuẩn bị: %d..." % prep_sec
			pitch_status.add_theme_color_override("font_color", C_GOLD)
			pitch_note.add_theme_color_override("font_color", C_GOLD)
			
			# Visual aid: show first note's fingering so the user can prepare
			if sheet_notes.size() > 0:
				var first_note = sheet_notes[0]
				var target_fingering = FINGERINGS.get(first_note, [false, false, false, false, false, false])
				_covered_states.assign(target_fingering)
				_build_flute()
				
			# Transition check: countdown finished!
			if _current_note_elapsed >= 0.0:
				_current_note_elapsed = 0.0
				pitch_status.text = "Thổi ngay!"
				pitch_status.add_theme_color_override("font_color", C_GREEN_OK)
				
				# Play the first note guide sound if not in demo mode
				if not _is_demo_mode and sheet_notes.size() > 0:
					if not _is_rest_note(sheet_notes[0]):
						_play_flute_sound(sheet_notes[0])
		else:
			if _process_rest_note(effective_delta):
				pass
			elif _mic_mode:
				_process_real_audio(effective_delta)
			else:
				# If we are in Touch Mode, we still want Auto Scroll / Demo Mode to work!
				if not _is_wait_mode or _is_demo_mode:
					var effective_bpm = _song_bpm * _speed_scale
					_current_note_elapsed += effective_delta
					var target_duration = sheet_durations[_note_idx] * (60.0 / effective_bpm)
					
					# Demo Mode: automatically play note sounds
					if _is_demo_mode:
						var target_note = sheet_notes[_note_idx]
						if not _active_player or not is_instance_valid(_active_player) or _active_player.get_meta("note_played", "") != target_note:
							_play_flute_sound(target_note)
							if _active_player:
								_active_player.set_meta("note_played", target_note)
								_active_player.volume_db = -3.0
								
						var target_fingering = FINGERINGS.get(target_note, [false, false, false, false, false, false])
						_covered_states.assign(target_fingering)
						_build_flute()
						
						pitch_note.text = target_note
						pitch_status.text = "Đang nghe mẫu..."
						pitch_status.add_theme_color_override("font_color", C_GREEN_OK)
						pitch_note.add_theme_color_override("font_color", C_GREEN_OK)
						
					if _current_note_elapsed >= target_duration:
						_current_note_elapsed = 0.0
						_note_idx = (_note_idx + 1) % sheet_notes.size()
						_build_notation()
						_update_target_indicator()
						if not _is_demo_mode:
							_play_flute_sound(sheet_notes[_note_idx])
				else:
					# Normal Touch Mode simulation
					_sim_timer += effective_delta
					if _sim_timer >= 1.2:
						_sim_timer = 0.0
						_simulate_tick()
	_update_breath_physics(delta)
	
	# 2. Update zither backing track if recording and in Lesson 2
	if _recording and _lesson_mode == 1:
		if _current_note_elapsed >= 0.0:
			_update_backing_track(effective_delta)
		
	if _ignore_input_timer > 0.0:
		_ignore_input_timer -= effective_delta
		# Clear detected notes history to avoid carry-over pitch spikes
		_detected_notes_history.clear()
		return
		
	# Update Note rolling blocks positions and feedback needle
	var track_panel = $Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox.get_node_or_null("NoteTrackPanel")
	if track_panel:
		var note_container = track_panel.get_node_or_null("NoteContainer")
		if note_container and sheet_notes.size() > 0:
			var target_active_note = sheet_notes[_note_idx]
			var clean_note = target_active_note.replace("²", "")
			var active_lane_idx = LANES.find(clean_note)
			if active_lane_idx == -1: active_lane_idx = 7
			
			var lane_h := 90.0
			var container_h = note_container.size.y if note_container.size.y > 0 else 300.0
			var target_scroll_y = active_lane_idx * lane_h - (container_h / 2.0) + (lane_h / 2.0)
			
			var max_scroll_y = LANES.size() * lane_h - container_h
			if max_scroll_y < 0: max_scroll_y = 0
			target_scroll_y = clamp(target_scroll_y, 0.0, max_scroll_y)
			
			_viewport_scroll_y = lerp(_viewport_scroll_y, target_scroll_y, 0.1)
			note_container.queue_redraw()
			
			var bps = _song_bpm / 60.0
			var start_beat := 0.0
			for j in range(_note_idx):
				if j < sheet_durations.size():
					start_beat += sheet_durations[j]
			var current_time_beats = start_beat + (_current_note_elapsed * bps) if _recording else start_beat
			
			var PIXELS_PER_BEAT := 120.0
			var TARGET_LINE_X := 200.0
			
			for i in range(sheet_notes.size()):
				if not note_visuals.has(i): continue
				var block = note_visuals[i] as Panel
				if not is_instance_valid(block): continue
				
				var note_time = block.get_meta("note_time", 0.0) as float
				var note_duration = block.get_meta("note_duration", 1.0) as float
				var note_name = block.get_meta("note_name", "") as String
				
				var note_start_x = TARGET_LINE_X + (note_time - current_time_beats) * PIXELS_PER_BEAT
				var note_width = note_duration * PIXELS_PER_BEAT
				var note_y = _get_lane_y(note_name)
				
				block.position = Vector2(note_start_x, note_y)
				block.size = Vector2(max(5.0, note_width - 15.0), lane_h - 6.0)
				
				if note_start_x + note_width < 0:
					block.visible = false
				else:
					block.visible = true
					
				# Dynamic color updates
				if i == _note_idx:
					if not _recording:
						_set_block_color(block, C_GOLD) # Golden waiting color
					elif _is_demo_mode:
						_set_block_color(block, C_GREEN_OK) # Emerald Green
					else:
						if _active_note_is_correct:
							_set_block_color(block, C_GREEN_OK) # Emerald Green
						elif _active_note_is_heard:
							_set_block_color(block, C_RED_ERR) # Crimson Red
						else:
							_set_block_color(block, Color("#5c8c72")) # Slate Jade Unplayed
				else:
					var status = note_statuses[i] if i < note_statuses.size() else "unplayed"
					if status == "correct":
						_set_block_color(block, C_GREEN_OK) # Faded Green (Passed)
					elif status == "missed":
						_set_block_color(block, C_RED_ERR) # Missed Dark Red
					else:
						_set_block_color(block, Color("#5c8c72")) # Slate Jade Unplayed

		# Position feedback needle
		var needle = track_panel.get_node_or_null("FeedbackNeedle") as ColorRect
		if needle:
			var visualizer = _waveform_visualizer
			var db = visualizer.current_amplitude_db if visualizer else -99.0
			var pitch = visualizer.current_pitch if visualizer else 0.0
			
			if _recording and _mic_mode and not _is_demo_mode and db > -32.0 and pitch > 50.0:
				needle.visible = true
				
				# Find closest note in FREQS
				var closest_note := ""
				var min_diff := 999999.0
				var is_overblowing := _breath_pressure > 82.0
				var scale_mult := 2.0 if is_overblowing else 1.0
				
				for note in FREQS.keys():
					var note_freq = FREQS[note] * scale_mult
					var diff = abs(pitch - note_freq)
					if diff < min_diff:
						min_diff = diff
						closest_note = note
				
				if closest_note != "":
					var target_y = _get_lane_y(closest_note) + (40.0 / 2.0)
					needle.position.y = lerp(needle.position.y, target_y - (needle.size.y / 2.0), 0.3)
					needle.position.x = 200.0 - 10.0
					
					var target_note = sheet_notes[_note_idx]
					if closest_note == target_note:
						needle.color = Color("#76ba99")
					else:
						needle.color = Color("#e5ba73")
			else:
				needle.visible = false
		


func _set_labels() -> void:
	($Root/TopBar/TopM/TopH/BackBtn    as Button).text = "Quay lại"
	var diff := "Cơ bản"
	if SecureDataManager.active_lesson_id == "Node3":
		diff = "Trung bình"
	elif SecureDataManager.active_lesson_id == "Node4":
		diff = "Nâng cao"
		
	var title_lbl := "Lý Hoài Nam (Dân ca)"
	if current_song_title != "":
		title_lbl = current_song_title
		diff = "Bài hát"
	else:
		if SecureDataManager.active_lesson_id == "Node3":
			title_lbl = "Luyện Ngón Sáo Trúc"
		elif SecureDataManager.active_lesson_id == "Node4":
			title_lbl = "Nhấp Ngón Kỹ Thuật"

	($Root/TopBar/TopM/TopH/LessonTitle as Label).text = title_lbl
	($SettingsPanel/SettingsM/SettingsVBox/ProgressVBox/PctLabel as Label).text = "20%" if current_song_title == "" else "100%"
	($SettingsPanel/SettingsM/SettingsVBox/CtrlBtns/HintBtn as Button).text = "Gợi ý"
	_update_wait_mode_ui()
	_update_demo_mode_ui()

	var current_chord := ""
	
	if "Trống Cơm" in title_lbl:
		current_chord = "Hợp âm: C - F - G"
	elif "Bèo Dạt Mây Trôi" in title_lbl:
		current_chord = "Hợp âm: Em - Bm - D"
	elif "Cây Trúc Xinh" in title_lbl:
		current_chord = "Hợp âm: Am - G - Em"
	elif "Gặp Mẹ Trong Mơ" in title_lbl:
		current_chord = "Hợp âm: Am - F - C - G"
	elif "Lý Hoài Nam" in title_lbl:
		current_chord = "Hợp âm: Dm - F - Am"
	elif "Xuân Về Bản Mèo" in title_lbl:
		current_chord = "Hợp âm: Am - C - D"
		
	if current_chord != "":
		($Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/TopInfoHBox/NotationVBoxLeft/NotationLabel as Label).text = "BẢN NHẠC  —  " + current_chord
	else:
		($Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/TopInfoHBox/NotationVBoxLeft/NotationLabel as Label).text = "BẢN NHẠC  —  Thổi theo dòng nốt"

	var display_note = "La"
	if current_song_title != "" and sheet_notes.size() > 0:
		display_note = sheet_notes[0]
	($Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/TopInfoHBox/NotationVBoxLeft/TargetNoteLabel as Label).text = "Nốt cần thổi: " + display_note
	($Root/MiddleRow/MainContent/StatsRow/StatsM/StatsHBox/PitchV/PitchTitle   as Label).text = "CAO ĐỘ"
	($Root/MiddleRow/MainContent/StatsRow/StatsM/StatsHBox/RhythmV/RhythmTitle as Label).text = "NHỊP ĐIỆU"
	($Root/MiddleRow/MainContent/StatsRow/StatsM/StatsHBox/ScoreV/ScoreTitle  as Label).text = "ĐIỂM SỐ"
	($Root/MiddleRow/MainContent/StatsRow/StatsM/StatsHBox/ScoreV/ScoreSub   as Label).text = "Cao độ 82%  ·  Nhịp 71%"

	($Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/TopInfoHBox/FluteVBoxRight/BoardLabel as Label).text = "SÁO TRÚC  —  Che lỗ để thổi"
	record_btn.text = "Bắt đầu luyện tập"
	($Root/RecordBar/RecordM/RecordH/ResetBtn as Button).text = "Làm lại"

	speech_label.text = SPEECHES[0]

	hint_dialog.title = "Gợi ý kỹ thuật"
	hint_dialog.dialog_text = "Khi thổi sáo trúc:\n\n• Môi khép nhẹ, không cắn lưỡi gà\n• Thổi đều hơi, không gấp\n• Che kín lỗ bằng thịt đầu ngón\n• Giữ cổ tay thư giãn\n• Lắng nghe cao độ rõ ràng"

func _build_theme() -> void:
	# ── Background overlay: warm dark mahogany ────────────────────────────────────
	var bg_over := get_node_or_null("BGOverlay") as ColorRect
	if bg_over:
		bg_over.color = Color(0.059, 0.035, 0.012, 0.88) # dark mahogany warm overlay

	# Load premium fonts
	var f_title := load("res://assets/fonts/Lora-Bold.ttf") as Font
	var f_body := load("res://assets/fonts/BeVietnamPro-Regular.ttf") as Font
	var f_body_bold := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font

	# ── TOP BAR: dark mahogany glass with gold bottom border ─────────────────────
	var top_s := StyleBoxFlat.new()
	top_s.bg_color = Color(0.071, 0.047, 0.020, 0.97) # dark mahogany
	top_s.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45)
	top_s.border_width_bottom = 2
	top_s.border_width_top = 0; top_s.border_width_left = 0; top_s.border_width_right = 0
	top_s.shadow_size = 12; top_s.shadow_color = Color(0, 0, 0, 0.40)
	top_s.shadow_offset = Vector2(0, 4)
	($Root/TopBar as PanelContainer).add_theme_stylebox_override("panel", top_s)

	var lesson_title = $Root/TopBar/TopM/TopH/LessonTitle as Label
	lesson_title.add_theme_color_override("font_color", C_GOLD)
	if f_title: lesson_title.add_theme_font_override("font", f_title)
	lesson_title.add_theme_font_size_override("font_size", 30)

	var back := $Root/TopBar/TopM/TopH/BackBtn as Button
	_style_text_btn(back, C_CREAM_DIM, C_CREAM)
	
	var menu_btn := $Root/TopBar/TopM/TopH/MenuBtn as Button
	if menu_btn: _style_text_btn(menu_btn, C_GOLD, C_GOLD_LIGHT)

	# ── SETTINGS PANEL: dark jade card ────────────────────────────────────────
	var pct_label = $SettingsPanel/SettingsM/SettingsVBox/ProgressVBox/PctLabel as Label
	pct_label.add_theme_color_override("font_color", C_TEXT_MUTED)
	if f_body: pct_label.add_theme_font_override("font", f_body)
	pct_label.add_theme_font_size_override("font_size", 18)
	_style_progress_bar(lesson_bar, C_GREEN_OK, Color(1.0, 1.0, 1.0, 0.06))

	var settings_panel := $SettingsPanel as PanelContainer
	if settings_panel:
		var sp_style := StyleBoxFlat.new()
		sp_style.bg_color = Color(0.071, 0.047, 0.020, 0.97)
		sp_style.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.50)
		sp_style.border_width_left = 1; sp_style.border_width_right = 1
		sp_style.border_width_top = 1; sp_style.border_width_bottom = 1
		sp_style.corner_radius_top_left = 21; sp_style.corner_radius_top_right = 21
		sp_style.corner_radius_bottom_left = 21; sp_style.corner_radius_bottom_right = 21
		sp_style.shadow_size = 22; sp_style.shadow_color = Color(0, 0, 0, 0.55)
		settings_panel.add_theme_stylebox_override("panel", sp_style)
		var menu_title := $SettingsPanel/SettingsM/SettingsVBox/MenuTitle as Label
		if menu_title:
			menu_title.add_theme_color_override("font_color", C_GOLD)
			if f_title: menu_title.add_theme_font_override("font", f_title)

	for bn in ["HintBtn","DemoBtn","SlowBtn"]:
		var btn = $SettingsPanel/SettingsM/SettingsVBox/CtrlBtns.get_node(bn) as Button
		if btn: _style_outlined_btn(btn)

	# ── LINH PANEL: transparent + warm speech bubble ───────────────────────────
	($Root/MiddleRow/LinhPanel as PanelContainer).add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var bubble_s := StyleBoxFlat.new()
	bubble_s.bg_color = Color(0.071, 0.047, 0.020, 0.90)
	bubble_s.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.55)
	bubble_s.border_width_left = 1; bubble_s.border_width_right = 1
	bubble_s.border_width_top = 1; bubble_s.border_width_bottom = 1
	bubble_s.corner_radius_top_left = 24; bubble_s.corner_radius_top_right = 24
	bubble_s.corner_radius_bottom_left = 24; bubble_s.corner_radius_bottom_right = 24
	($Root/MiddleRow/LinhPanel/LinhVBox/SpeechBubble as PanelContainer).add_theme_stylebox_override("panel", bubble_s)
	speech_label.add_theme_color_override("font_color", C_CREAM)
	if f_body: speech_label.add_theme_font_override("font", f_body)
	speech_label.add_theme_font_size_override("font_size", 20)

	# ── NOTATION AREA: deep jade card with gold border ───────────────────────────
	var na_s := StyleBoxFlat.new()
	na_s.bg_color = Color(0.039, 0.110, 0.071, 0.97) # deep jade dark
	na_s.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.22)
	na_s.border_width_left = 1; na_s.border_width_right = 1
	na_s.border_width_top = 1; na_s.border_width_bottom = 1
	($Root/MiddleRow/MainContent/NotationArea as PanelContainer).add_theme_stylebox_override("panel", na_s)

	var notation_label = $Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/TopInfoHBox/NotationVBoxLeft/NotationLabel as Label
	notation_label.add_theme_color_override("font_color", C_TEXT_MUTED)
	if f_body_bold: notation_label.add_theme_font_override("font", f_body_bold)
	notation_label.add_theme_font_size_override("font_size", 18)

	var target_note_lbl = $Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/TopInfoHBox/NotationVBoxLeft/TargetNoteLabel as Label
	target_note_lbl.add_theme_color_override("font_color", C_GOLD)
	if f_body_bold: target_note_lbl.add_theme_font_override("font", f_body_bold)
	target_note_lbl.add_theme_font_size_override("font_size", 27)

	# Stats panels
	var stat_bg := StyleBoxFlat.new()
	stat_bg.bg_color = Color(0.071, 0.047, 0.020, 0.95)
	stat_bg.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.30)
	stat_bg.border_width_left = 1; stat_bg.border_width_right = 1
	stat_bg.border_width_top = 1; stat_bg.border_width_bottom = 1
	stat_bg.corner_radius_top_left = 21; stat_bg.corner_radius_top_right = 21
	stat_bg.corner_radius_bottom_left = 21; stat_bg.corner_radius_bottom_right = 21
	stat_bg.shadow_size = 8; stat_bg.shadow_color = Color(0, 0, 0, 0.35)
	($Root/MiddleRow/MainContent/StatsRow as PanelContainer).add_theme_stylebox_override("panel", stat_bg)

	for lbl_path in ["PitchV/PitchTitle", "RhythmV/RhythmTitle", "ScoreV/ScoreTitle"]:
		var lbl = $Root/MiddleRow/MainContent/StatsRow/StatsM/StatsHBox.get_node(lbl_path) as Label
		if lbl:
			lbl.add_theme_color_override("font_color", C_TEXT_MUTED)
			if f_body_bold: lbl.add_theme_font_override("font", f_body_bold)
			lbl.add_theme_font_size_override("font_size", 17)

	pitch_note.add_theme_color_override("font_color", C_GOLD)
	if f_title: pitch_note.add_theme_font_override("font", f_title)
	pitch_note.add_theme_font_size_override("font_size", 45)

	pitch_status.add_theme_color_override("font_color", C_TEXT_MUTED)
	if f_body: pitch_status.add_theme_font_override("font", f_body)
	pitch_status.add_theme_font_size_override("font_size", 17)

	rhythm_acc.add_theme_color_override("font_color", C_TEXT_MUTED)
	if f_body: rhythm_acc.add_theme_font_override("font", f_body)
	rhythm_acc.add_theme_font_size_override("font_size", 17)

	score_num.add_theme_color_override("font_color", C_GREEN_OK)
	if f_title: score_num.add_theme_font_override("font", f_title)
	score_num.add_theme_font_size_override("font_size", 45)

	var score_sub = $Root/MiddleRow/MainContent/StatsRow/StatsM/StatsHBox/ScoreV/ScoreSub as Label
	score_sub.add_theme_color_override("font_color", C_TEXT_MUTED)
	if f_body: score_sub.add_theme_font_override("font", f_body)
	score_sub.add_theme_font_size_override("font_size", 17)

	# ── FLUTE BOARD: dark warm mahogany strip ───────────────────────────────────
	var sb_s := StyleBoxFlat.new()
	sb_s.bg_color = Color(0.059, 0.039, 0.016, 0.97)
	sb_s.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35)
	sb_s.border_width_top = 2; sb_s.border_width_bottom = 0
	sb_s.border_width_left = 0; sb_s.border_width_right = 0
	($Root/FluteBoard as PanelContainer).add_theme_stylebox_override("panel", sb_s)

	var board_lbl = $Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/TopInfoHBox/FluteVBoxRight/BoardLabel as Label
	board_lbl.add_theme_color_override("font_color", C_TEXT_MUTED)
	if f_body_bold: board_lbl.add_theme_font_override("font", f_body_bold)
	board_lbl.add_theme_font_size_override("font_size", 18)

	target_label.add_theme_color_override("font_color", C_GOLD)
	if f_body_bold: target_label.add_theme_font_override("font", f_body_bold)
	target_label.add_theme_font_size_override("font_size", 20)

	var guidance_lbl = $Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/TopInfoHBox/FluteVBoxRight/GuidanceLabel as Label
	guidance_lbl.add_theme_color_override("font_color", C_TEXT_MUTED)
	if f_body: guidance_lbl.add_theme_font_override("font", f_body)
	guidance_lbl.add_theme_font_size_override("font_size", 17)

	# Flute frame: warm dark wood
	var frame := $Root/FluteBoard/BoardM/BoardVBox/FluteFrame as PanelContainer
	var frame_s := StyleBoxFlat.new()
	frame_s.bg_color = Color(0.06, 0.035, 0.010, 1.0) # very dark warm mahogany
	frame_s.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.40)
	frame_s.border_width_left = 1; frame_s.border_width_right = 1
	frame_s.border_width_top = 1; frame_s.border_width_bottom = 1
	frame_s.corner_radius_top_left = 15; frame_s.corner_radius_top_right = 15
	frame_s.corner_radius_bottom_left = 15; frame_s.corner_radius_bottom_right = 15
	frame.add_theme_stylebox_override("panel", frame_s)

	# Breath progress: jade green fill
	var bf := StyleBoxFlat.new()
	bf.bg_color = C_GREEN_OK
	bf.corner_radius_top_left = 9; bf.corner_radius_top_right = 9
	bf.corner_radius_bottom_left = 9; bf.corner_radius_bottom_right = 9
	bf.shadow_size = 6; bf.shadow_color = Color(C_GREEN_OK.r, C_GREEN_OK.g, C_GREEN_OK.b, 0.40)
	var bb := StyleBoxFlat.new()
	bb.bg_color = Color(1.0, 1.0, 1.0, 0.06)
	bb.corner_radius_top_left = 9; bb.corner_radius_top_right = 9
	bb.corner_radius_bottom_left = 9; bb.corner_radius_bottom_right = 9
	breath_progress.add_theme_stylebox_override("fill", bf)
	breath_progress.add_theme_stylebox_override("background", bb)

	var breath_lbl = $Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/TopInfoHBox/FluteVBoxRight/BreathHBox/BreathLabel as Label
	breath_lbl.add_theme_color_override("font_color", C_TEXT_MUTED)
	if f_body_bold: breath_lbl.add_theme_font_override("font", f_body_bold)
	breath_lbl.add_theme_font_size_override("font_size", 17)
	if breath_status:
		breath_status.add_theme_color_override("font_color", C_CREAM)
		if f_body: breath_status.add_theme_font_override("font", f_body)
		breath_status.add_theme_font_size_override("font_size", 17)

	# ── RECORD BAR: dark mahogany bottom strip ─────────────────────────────────
	var rec_bar_s := StyleBoxFlat.new()
	rec_bar_s.bg_color = Color(0.059, 0.039, 0.016, 0.97)
	rec_bar_s.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35)
	rec_bar_s.border_width_top = 2; rec_bar_s.border_width_bottom = 0
	rec_bar_s.border_width_left = 0; rec_bar_s.border_width_right = 0
	($Root/RecordBar as PanelContainer).add_theme_stylebox_override("panel", rec_bar_s)

	# ── RECORD BUTTON (Bắt đầu luyện tập): Terracotta gradient + gold glow ───────
	var rn := StyleBoxFlat.new()
	rn.bg_color = Color(0.753, 0.329, 0.102, 1.0)  # Terracotta #C0541A
	rn.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.55)
	rn.border_width_left = 2; rn.border_width_right = 2; rn.border_width_top = 2; rn.border_width_bottom = 2
	rn.corner_radius_top_left = 39; rn.corner_radius_top_right = 39
	rn.corner_radius_bottom_left = 39; rn.corner_radius_bottom_right = 39
	rn.shadow_size = 16; rn.shadow_color = Color(0.753, 0.329, 0.102, 0.50)
	var rh := StyleBoxFlat.new()
	rh.bg_color = Color(0.831, 0.388, 0.122, 1.0)  # Lighter terracotta #D4631F
	rh.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.85)
	rh.border_width_left = 2; rh.border_width_right = 2; rh.border_width_top = 2; rh.border_width_bottom = 2
	rh.corner_radius_top_left = 39; rh.corner_radius_top_right = 39
	rh.corner_radius_bottom_left = 39; rh.corner_radius_bottom_right = 39
	rh.shadow_size = 22; rh.shadow_color = Color(0.831, 0.388, 0.122, 0.65)
	var rp := StyleBoxFlat.new()
	rp.bg_color = Color(0.620, 0.247, 0.063, 1.0)  # Dark terracotta #9E3F10
	rp.corner_radius_top_left = 39; rp.corner_radius_top_right = 39
	rp.corner_radius_bottom_left = 39; rp.corner_radius_bottom_right = 39
	record_btn.add_theme_stylebox_override("normal",  rn)
	record_btn.add_theme_stylebox_override("hover",   rh)
	record_btn.add_theme_stylebox_override("pressed", rp)
	record_btn.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	record_btn.add_theme_color_override("font_color", C_CREAM)
	if f_body_bold: record_btn.add_theme_font_override("font", f_body_bold)
	record_btn.add_theme_font_size_override("font_size", 26)

	# ── RESET BUTTON (Làm lại): dark outline with warm ivory text ──────────────
	_style_outlined_btn($Root/RecordBar/RecordM/RecordH/ResetBtn as Button)

func _build_flute() -> void:
	for c in holes_hbox.get_children():
		holes_hbox.remove_child(c)
		c.queue_free()

	for i in HOLES:
		var hole := PanelContainer.new()
		hole.custom_minimum_size = Vector2(75, 75)
		hole.pivot_offset = Vector2(38, 38)
		hole.mouse_filter = Control.MOUSE_FILTER_STOP
		
		var hs := StyleBoxFlat.new()
		hs.border_width_left = 3; hs.border_width_right = 3
		hs.border_width_top = 3; hs.border_width_bottom = 3
		hs.corner_radius_top_left = 38; hs.corner_radius_top_right = 38
		hs.corner_radius_bottom_left = 38; hs.corner_radius_bottom_right = 38
		
		if _covered_states[i]:
			hs.bg_color = Color.RED
			hs.border_color = Color.INDIAN_RED
		else:
			hs.bg_color = Color(0.04, 0.02, 0.01)
			hs.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25)
			
		hole.add_theme_stylebox_override("panel", hs)

		var idx := i
		hole.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_toggle_hole_state(idx, hole, hs)
		)

		holes_hbox.add_child(hole)

	_update_target_indicator()

func _build_notation() -> void:
	_build_notation_track()

func _build_dots() -> void:
	var total := 5
	var done  := 1
	for i in total:
		var d := dots_hbox.get_child(i) as ColorRect
		if d:
			d.color = C_GOLD if i < done else Color(0.85, 0.82, 0.75, 1.0)

func _build_rhythm_bars() -> void:
	for c in rhythm_bars.get_children(): c.queue_free()
	for _i in range(14):
		var bar := ColorRect.new()
		bar.custom_minimum_size = Vector2(14, 15)
		bar.color = Color(0.85, 0.82, 0.75, 1.0)
		bar.size_flags_vertical = Control.SIZE_SHRINK_END
		rhythm_bars.add_child(bar)

# ─── Sound Generator ──────────────────────────────────────────────────────────
func _generate_streams() -> void:
	for note in NOTES_VN:
		var freq = FREQS[note]
		_flute_streams[note] = _generate_flute_stream(freq)
	_generate_zither_streams()

func _generate_flute_stream(freq: float) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	stream.stereo = false
	
	# Loop settings for a sustained blowing sound
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = int(44100 * 0.3)
	stream.loop_end = int(44100 * 1.7)
	
	var duration := 2.0 # 2 seconds total buffer
	var sample_count := int(44100 * duration)
	var byte_count := sample_count * 2
	var data := PackedByteArray()
	data.resize(byte_count)
	
	var phase := 0.0
	var increment := freq * TAU / 44100.0
	
	for i in range(sample_count):
		var t_sec = float(i) / 44100.0
		# Gentle organic pitch vibrato (6Hz modulation)
		var vibrato = 1.0 + 0.012 * sin(t_sec * 6.0 * TAU)
		# Air blow friction white noise (hiss)
		var air_noise = randf_range(-1.0, 1.0) * (0.05 * exp(-t_sec * 5.0) + 0.02)
		
		var sample = 0.0
		sample += sin(phase) * 0.50                      # Fundamental
		sample += sin(phase * 2.0) * 0.06                 # 2nd harmonic
		sample += sin(phase * 3.0) * 0.03                 # 3rd harmonic
		
		# Breath attack fade-in over 80ms
		var attack = clamp(t_sec / 0.08, 0.0, 1.0)
		var decay = clamp((duration - t_sec) / 0.3, 0.0, 1.0)
		
		var final_val = (sample * attack + air_noise) * decay * 0.85
		final_val = clamp(final_val, -1.0, 1.0)
		
		var val_i16 = int(final_val * 32767.0)
		data[i * 2] = val_i16 & 0xFF
		data[i * 2 + 1] = (val_i16 >> 8) & 0xFF
		
		phase += increment * vibrato
		
	stream.data = data
	return stream

func _play_flute_sound(note: String) -> void:
	if _is_rest_note(note):
		return
	if _recording:
		# Muted per user request: only recognize pitch, do not play sound feedback when recording
		return
	if not _flute_streams.has(note): return
	
	if _active_player and is_instance_valid(_active_player):
		var old_player = _active_player
		var fade_t = create_tween()
		fade_t.tween_property(old_player, "volume_db", -30.0, 0.08)
		fade_t.tween_callback(func() -> void:
			old_player.stop()
			old_player.queue_free()
		)
		
	_active_player = AudioStreamPlayer.new()
	_active_player.stream = _flute_streams[note]
	_active_player.volume_db = -80.0 if (_recording and _mic_mode) else -3.0
	add_child(_active_player)
	_active_player.play()

func _play_preview_or_sound() -> void:
	if _recording and _mic_mode: return
	var current_note = _get_current_note()
	_play_flute_sound(current_note)
	if not _recording:
		# Preview note for 0.6s if not recording
		var temp_player = _active_player
		get_tree().create_timer(0.6).timeout.connect(func() -> void:
			if is_instance_valid(temp_player) and temp_player == _active_player and not _recording:
				var fade = create_tween()
				fade.tween_property(temp_player, "volume_db", -30.0, 0.12)
				fade.tween_callback(temp_player.queue_free)
				if _active_player == temp_player:
					_active_player = null
		)

# ─── Fingering Logic ─────────────────────────────────────────────────────────
func _get_current_note() -> String:
	var covered_count := 0
	for i in range(HOLES):
		if _covered_states[i]:
			covered_count += 1
		else:
			break
	var notes = ["Si", "La", "Sol", "Fa", "Mi", "Rê", "Đô"]
	return notes[covered_count]

func _toggle_hole_state(idx: int, hole: PanelContainer, hs: StyleBoxFlat) -> void:
	_covered_states[idx] = not _covered_states[idx]
	var is_covered = _covered_states[idx]
	
	if is_covered:
		hs.bg_color = Color.RED
		hs.border_color = Color.INDIAN_RED
	else:
		hs.bg_color = Color(0.04, 0.02, 0.01)
		hs.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25)
		
	var t := create_tween().set_parallel(true)
	t.tween_property(hole, "scale", Vector2(1.15, 1.15), 0.06)
	t.tween_property(hole, "scale", Vector2.ONE, 0.12)
	
	var current_note = _get_current_note()
	pitch_note.text = current_note
	pitch_status.text = "Thế bấm: %s" % current_note
	pitch_status.add_theme_color_override("font_color", C_GOLD)
	
	_play_preview_or_sound()
		
	var target_note = sheet_notes[_note_idx]
	if current_note == target_note:
		_note_idx = (_note_idx + 1) % sheet_notes.size()
		_build_notation()
		_update_target_indicator()
		_score = clamp(_score + 4.0, 0, 100)
		_refresh_score()
		_va_say("Đúng rồi, giữ hơi đều.")
		
		# Glowing correct halo
		var halo := ColorRect.new()
		halo.color = Color(0.98, 0.85, 0.35, 0.45)
		halo.custom_minimum_size = Vector2(45, 45)
		halo.set_anchors_preset(Control.PRESET_FULL_RECT)
		halo.offset_left = -30; halo.offset_right = 30
		halo.offset_top = -30; halo.offset_bottom = 30
		hole.add_child(halo)
		var ht := create_tween()
		ht.tween_property(halo, "custom_minimum_size", Vector2(160, 160), 0.28)
		ht.tween_property(halo, "color", Color(0.98, 0.85, 0.35, 0.0), 0.36)
		ht.tween_callback(func() -> void: halo.queue_free())

func _update_target_indicator() -> void:
	var target_note := sheet_notes[_note_idx]
	if _is_rest_note(target_note):
		target_note_label.text = "Khoảng nghỉ"
		target_label.text = "Tạm nghỉ hơi theo đúng trường độ"
		return
	target_note_label.text = "Nốt cần thổi: %s" % target_note
	
	var target_fingering = FINGERINGS.get(target_note, [false, false, false, false, false, false])
	
	var target_holes_txt := ""
	for i in range(HOLES):
		if target_fingering[i]:
			if target_holes_txt != "": target_holes_txt += ", "
			target_holes_txt += str(i + 1)
			
	if target_holes_txt == "":
		target_label.text = "Thế bấm nốt %s: Mở tất cả các lỗ" % target_note
	else:
		target_label.text = "Thế bấm nốt %s: Che lỗ %s" % [target_note, target_holes_txt]
		
	for i in holes_hbox.get_child_count():
		var hole := holes_hbox.get_child(i) as PanelContainer
		if hole:
			var style := hole.get_theme_stylebox("panel") as StyleBoxFlat
			if style:
				var is_target_covered = target_fingering[i]
				if is_target_covered:
					style.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.95)
					style.border_width_left = 3; style.border_width_right = 3
					style.border_width_top = 3; style.border_width_bottom = 3
				else:
					style.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25)
					style.border_width_left = 2; style.border_width_right = 2
					style.border_width_top = 2; style.border_width_bottom = 2
func _start_float() -> void:
	pass

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

	# Click flute body to blow/play preview
	var flute_body := $Root/FluteBoard/BoardM/BoardVBox/FluteFrame/FluteM/FluteStack/FluteBody as Control
	if flute_body:
		flute_body.mouse_filter = Control.MOUSE_FILTER_STOP
		flute_body.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_play_preview_or_sound()
				var t := create_tween()
				t.tween_property(flute_body, "scale", Vector2(1.02, 1.02), 0.06).set_trans(Tween.TRANS_QUAD)
				t.tween_property(flute_body, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD)
		)

func _toggle_record() -> void:
	_recording = not _recording
	var visualizer = _waveform_visualizer
	_update_rec_pulse(_recording)
	if _recording:
		record_btn.text = "Dừng luyện tập"
		_va_say(SPEECHES[0])
		_start_pitch_detection()
		if visualizer and _mic_mode: visualizer.visible = true
		_current_note_elapsed = -4.0
		_waiting_for_breath_release = false
		
		if visualizer and visualizer.has_method("start_recording") and _mic_mode:
			visualizer.start_recording()
		
		# Reset AI tracking
		_practice_time = 0.0
		_detected_onsets.clear()
		_pitch_scores.clear()
		_breath_scores.clear()
		_reference_onsets = PackedFloat32Array()
		for i in range(sheet_notes.size()):
			_reference_onsets.append(1.0 + i * 1.5)
	else:
		record_btn.text = "Bắt đầu luyện tập"
		_current_note_elapsed = 0.0
		if visualizer:
			visualizer.add_practice_score(_score)
			visualizer.visible = false
		_show_custom_result()
		_stop_pitch_detection()
		
		if visualizer and visualizer.has_method("stop_recording") and _mic_mode:
			var stream = visualizer.stop_recording()
			if stream:
				var file_name = "user://practice_record_saotruc_" + str(Time.get_unix_time_from_system()) + ".wav"
				stream.save_to_wav(file_name)
				print("Saved practice recording to: ", file_name)
				_va_say("Đã lưu bản thu âm để giáo viên chấm điểm!")
		if visualizer: visualizer.visible = false
		if _active_player and is_instance_valid(_active_player):
			_active_player.stop()
			_active_player.queue_free()
			_active_player = null

func _demo() -> void:
	var target_note := sheet_notes[_note_idx]
	if _is_rest_note(target_note):
		_va_say("Đây là khoảng nghỉ. Hãy ngắt hơi và giữ im lặng đúng trường độ.")
		return
	_va_say("Lắng nghe nốt %s mẫu và thế bấm chuẩn." % target_note)
	
	var t := create_tween()
	t.tween_property(char_linh, "modulate", Color(1.5, 1.1, 0.6, 1.0), 0.3)
	t.tween_property(char_linh, "modulate", Color.WHITE, 0.5)

	_play_flute_sound(target_note)

	var target_fingering = FINGERINGS.get(target_note, [false, false, false, false, false, false])
	var delay := 0.1
	for i in range(HOLES):
		if target_fingering[i]:
			var hole := holes_hbox.get_child(i) as PanelContainer
			if hole:
				var dt := create_tween()
				dt.tween_property(hole, "scale", Vector2(1.15, 1.15), 0.08).set_delay(delay)
				dt.tween_property(hole, "scale", Vector2.ONE, 0.12)
				delay += 0.15


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

func _detect_note_from_pitch(pitch: float, scale_mult: float) -> String:
	if pitch <= 50.0:
		return ""
	var closest_note := ""
	var min_cents_diff := 999999.0
	for note in FREQS.keys():
		var note_freq = FREQS[note] * scale_mult
		var cents_diff = abs(1200.0 * log(pitch / note_freq) / log(2.0))
		if cents_diff < min_cents_diff:
			min_cents_diff = cents_diff
			closest_note = note
	if closest_note != "" and min_cents_diff < 75.0:
		return closest_note
	return ""

func _process_real_audio(delta: float) -> void:
	if _eval_cooldown > 0.0:
		_eval_cooldown -= delta
		return
		
	var visualizer = _waveform_visualizer
	if not visualizer: return
	
	var target_note = sheet_notes[_note_idx]
	var target_duration = sheet_durations[_note_idx] * (60.0 / _song_bpm)
	
	_active_note_is_correct = false
	_active_note_is_heard = false
	
	# A. Demo Mode
	if _is_demo_mode:
		_active_note_is_correct = true
		_active_note_is_heard = true
		_current_note_elapsed += delta
		
		# Play audio if not playing or switched note
		if not _active_player or not is_instance_valid(_active_player) or _active_player.get_meta("note_played", "") != target_note:
			_play_flute_sound(target_note)
			if _active_player:
				_active_player.set_meta("note_played", target_note)
				_active_player.volume_db = -3.0 # Make audible
			
		# Update visual covered state/fingering
		var target_fingering = FINGERINGS.get(target_note, [false, false, false, false, false, false])
		_covered_states.assign(target_fingering)
		_build_flute()
		
		pitch_note.text = target_note
		pitch_status.text = "Đang nghe mẫu..."
		pitch_status.add_theme_color_override("font_color", C_GREEN_OK)
		pitch_note.add_theme_color_override("font_color", C_GREEN_OK)
		
		if _current_note_elapsed >= target_duration:
			if _note_idx < note_statuses.size():
				note_statuses[_note_idx] = "correct"
			_current_note_elapsed = 0.0
			_note_idx = (_note_idx + 1) % sheet_notes.size()
			_build_notation()
			_update_target_indicator()
		return
		
	# B. Auto Scroll Mode
	if not _is_wait_mode:
		_current_note_elapsed += delta
		_current_note_total_frames += 1
		
		var db = visualizer.current_amplitude_db
		var pitch = visualizer.current_pitch
		var target_freq = FREQS.get(target_note, 261.63)
		var is_overblowing := _breath_pressure > 82.0
		var scale_mult := 2.0 if is_overblowing else 1.0
		var effective_target_freq : float = target_freq * scale_mult
		
		var cents := 999.0
		if pitch > 0.0:
			cents = 1200.0 * log(pitch / effective_target_freq) / log(2.0)
			
		var is_pitch_ok = db > -32.0 and pitch > 50.0 and abs(cents) < 150.0
		var is_correct_note = false
		if is_pitch_ok:
			var tolerance_cents = 45.0 / visualizer.difficulty_tolerance_scale
			if abs(cents) < tolerance_cents:
				is_correct_note = true
				
		var is_breath_ok = _breath_pressure >= 12.0 and _breath_pressure <= 85.0
		
		_active_note_is_correct = is_correct_note and is_breath_ok
		_active_note_is_heard = db > -32.0 and pitch > 50.0
		
		if is_correct_note and is_breath_ok:
			_current_note_correct_frames += 1
			pitch_note.text = target_note + ("²" if is_overblowing else "")
			pitch_status.text = "Rất chuẩn!"
			pitch_status.add_theme_color_override("font_color", C_GREEN_OK)
			pitch_note.add_theme_color_override("font_color", C_GREEN_OK)
			
			# Auto update covered states fingerings for visual help
			var target_fingering = FINGERINGS.get(target_note, [false, false, false, false, false, false])
			_covered_states.assign(target_fingering)
			_build_flute()
		elif is_pitch_ok:
			pitch_note.text = target_note + ("²" if is_overblowing else "")
			pitch_status.text = "Hơi yếu/mạnh"
			pitch_status.add_theme_color_override("font_color", C_WARN)
			pitch_note.add_theme_color_override("font_color", C_WARN)
		else:
			if db > -32.0 and pitch > 50.0:
				var detected_note = _detect_note_from_pitch(pitch, scale_mult)
				if detected_note != "":
					pitch_note.text = detected_note + ("²" if is_overblowing else "")
				else:
					pitch_note.text = "—"
				pitch_status.text = "Lệch âm: %s (Cần: %s)" % [detected_note if detected_note != "" else "?", target_note + ("²" if is_overblowing else "")]
				pitch_status.add_theme_color_override("font_color", C_RED_ERR)
				pitch_note.add_theme_color_override("font_color", C_RED_ERR)
			else:
				# Silence
				pitch_note.text = "—"
				pitch_status.text = "Đang nghe..."
				pitch_status.add_theme_color_override("font_color", C_GOLD)
				pitch_note.add_theme_color_override("font_color", C_GOLD)
			
		if _current_note_elapsed >= target_duration:
			var accuracy := 0.0
			if _current_note_total_frames > 0:
				accuracy = float(_current_note_correct_frames) / _current_note_total_frames
				
			if accuracy >= 0.4:
				_score = clamp(_score + 5.0, 0, 100)
				_refresh_score()
				_update_rhythm_real()
				_va_say("Tuyệt vời!")
				
				# Record AI performance metrics
				_detected_onsets.append(_practice_time)
				_pitch_scores.append(100.0)
				_breath_scores.append(100.0)
				
				if _note_idx < note_statuses.size():
					note_statuses[_note_idx] = "correct"
			else:
				_score = clamp(_score - 4.0, 0, 100)
				_refresh_score()
				_total_mistakes += 1
				rhythm_acc.text = "Lỗi: %d/2" % _total_mistakes
				rhythm_acc.add_theme_color_override("font_color", C_RED_ERR)
				
				if _note_idx < note_statuses.size():
					note_statuses[_note_idx] = "missed"
				
				if _total_mistakes > 2:
					_trigger_rewind()
					return
					
			_current_note_elapsed = 0.0
			_current_note_correct_frames = 0
			_current_note_total_frames = 0
			
			_note_idx = (_note_idx + 1) % sheet_notes.size()
			_build_notation()
			_update_target_indicator()
			_play_flute_sound(target_note) # Play sound feedback
		return
		
	# C. Wait Mode
	var db = visualizer.current_amplitude_db
	var pitch = visualizer.current_pitch
	
	_active_note_is_heard = db > -32.0 and pitch > 50.0
	
	# Rule: Articulation check / Cách hơi (Ngắt hơi giữa các nốt)
	if _waiting_for_breath_release:
		# Detect silence or drop in breath pressure to confirm articulation
		var is_silent = db < -42.0 or pitch <= 50.0 or _breath_pressure < 10.0
		if is_silent:
			_waiting_for_breath_release = false
			_advance_note_in_practice()
			
			# Dynamic AI scoring
			var rhythm_score = visualizer.evaluate_rhythm(_detected_onsets, _reference_onsets, 0.3 * visualizer.difficulty_tolerance_scale)
			_last_rhythm_score = rhythm_score
			var avg_pitch_score = _get_average_score(_pitch_scores, 80.0)
			var avg_breath_score = _get_average_score(_breath_scores, 80.0)
			
			_score = visualizer.calculate_composite_score(avg_pitch_score, rhythm_score, 100.0, avg_breath_score)
			_refresh_score()
			_update_rhythm_real()
			rhythm_acc.text = "Nhịp điệu: %d%% | Cột hơi: %d%%" % [int(rhythm_score), int(avg_breath_score)]
			
			# Auto update covered states fingerings for visual help
			var next_note = sheet_notes[_note_idx]
			var target_fingering = FINGERINGS.get(next_note, [false, false, false, false, false, false])
			_covered_states.assign(target_fingering)
			_build_flute()
			
			_eval_cooldown = 0.6
			return
		else:
			pitch_status.text = "Ngắt hơi chuyển nốt!"
			pitch_status.add_theme_color_override("font_color", C_GOLD)
			pitch_note.text = "—"
			pitch_note.add_theme_color_override("font_color", C_GOLD)
			return
			
	if db > -32.0 and pitch > 50.0:
		var target_freq = FREQS.get(target_note, 261.63)
		var is_overblowing := _breath_pressure > 82.0
		var scale_mult := 2.0 if is_overblowing else 1.0
		var effective_target_freq : float = target_freq * scale_mult
		
		var cents = 1200.0 * log(pitch / effective_target_freq) / log(2.0)
		var tolerance_cents = 45.0 / visualizer.difficulty_tolerance_scale
		
		if abs(cents) < 150.0:
			pitch_note.text = target_note + ("²" if is_overblowing else "")
			if abs(cents) < tolerance_cents:
				pitch_status.text = "Đúng cao độ" + (" (Quãng 2)" if is_overblowing else "")
				pitch_status.add_theme_color_override("font_color", C_GREEN_OK)
				pitch_note.add_theme_color_override("font_color", C_GREEN_OK)
				
				var is_breath_ok = _breath_pressure >= 12.0 and _breath_pressure <= 85.0
				_active_note_is_correct = is_breath_ok
				
				# Record AI performance metrics
				_detected_onsets.append(_practice_time)
				var pitch_err = clamp(100.0 - abs(cents) * 2.0, 0.0, 100.0)
				_pitch_scores.append(pitch_err)
				_breath_scores.append(visualizer.current_breath_purity)
				
				# Rule: Duration check / Trường độ (Thổi đúng tần số đủ thời gian của nốt)
				_correct_pitch_hold_time += delta
				var required_hold_time = max(0.3, target_duration * 0.5)
				if _correct_pitch_hold_time >= required_hold_time:
					_correct_pitch_hold_time = 0.0
					
					# Flag that we are now waiting for the user to cut their breath
					_waiting_for_breath_release = true
					
					pitch_status.text = "Ngắt hơi..."
					pitch_status.add_theme_color_override("font_color", C_GOLD)
					return
			else:
				pitch_status.text = "Hơi cao" if cents > 0 else "Hơi thấp"
				pitch_status.add_theme_color_override("font_color", C_WARN)
				pitch_note.add_theme_color_override("font_color", C_WARN)
		else:
			# Check if it matches another note in the scale using cents
			var detected_note := ""
			var closest_note := ""
			var min_cents_diff := 999999.0
			for note in FREQS.keys():
				var note_freq = FREQS[note] * scale_mult
				var cents_diff = abs(1200.0 * log(pitch / note_freq) / log(2.0))
				if cents_diff < min_cents_diff:
					min_cents_diff = cents_diff
					closest_note = note
					
			if closest_note != "" and min_cents_diff < 75.0:
				detected_note = closest_note + ("²" if is_overblowing else "")
				pitch_note.text = detected_note
				pitch_status.text = "Lệch cao độ (Cần: %s%s)" % [target_note, "²" if is_overblowing else ""]
				pitch_status.add_theme_color_override("font_color", C_RED_ERR)
				pitch_note.add_theme_color_override("font_color", C_RED_ERR)
				_score = clamp(_score - 0.5 * delta, 0, 100)
				_refresh_score()
			else:
				pitch_note.text = "—"
				pitch_status.text = "Lệch cao độ (Cần: %s%s)" % [target_note, "²" if is_overblowing else ""]
				pitch_status.add_theme_color_override("font_color", C_RED_ERR)
				pitch_note.add_theme_color_override("font_color", C_RED_ERR)
				_score = clamp(_score - 0.5 * delta, 0, 100)
				_refresh_score()
	else:
		pitch_note.text = "—"
		pitch_status.text = "Đang nghe..."
		pitch_status.add_theme_color_override("font_color", C_GOLD)
		pitch_note.add_theme_color_override("font_color", C_GOLD)
		_active_note_is_correct = false
		_active_note_is_heard = false

func _update_wait_mode_ui() -> void:
	var slow_btn := $SettingsPanel/SettingsM/SettingsVBox/CtrlBtns/SlowBtn as Button
	if not slow_btn: return
	if _is_wait_mode:
		slow_btn.text = "Chờ nốt: Bật ⏳"
		slow_btn.modulate = Color("#e5ba73") # Warm gold/yellow
	else:
		slow_btn.text = "Tự trôi: Bật 🌊"
		slow_btn.modulate = Color("#76ba99") # Mint green

func _update_demo_mode_ui() -> void:
	var demo_btn := $SettingsPanel/SettingsM/SettingsVBox/CtrlBtns/DemoBtn as Button
	if not demo_btn: return
	if _is_demo_mode:
		demo_btn.text = "Nghe mẫu: BẬT 🔊"
		demo_btn.modulate = Color("#76ba99") # Mint green
	else:
		demo_btn.text = "Nghe mẫu: TẮT 🔇"
		demo_btn.modulate = Color(1.0, 1.0, 1.0) # Reset to default

func _toggle_demo_mode() -> void:
	_is_demo_mode = not _is_demo_mode
	if _is_demo_mode:
		_is_wait_mode = false # Disable wait mode if demo is active
		_update_wait_mode_ui()
		_va_say("Đã bật Nghe mẫu. Hệ thống sẽ tự chơi giai điệu bài hát.")
	else:
		_is_wait_mode = true
		_update_wait_mode_ui()
		_va_say("Đã tắt Nghe mẫu. Con hãy tự mình luyện tập nhé!")
	_update_demo_mode_ui()
	
	# Stop active sound first
	if _active_player and is_instance_valid(_active_player):
		_active_player.stop()
		_active_player.queue_free()
		_active_player = null

func _toggle_wait_mode() -> void:
	if _is_demo_mode:
		_va_say("Đang chạy Nghe mẫu. Con không thể đổi chế độ lúc này.")
		return
	_is_wait_mode = not _is_wait_mode
	if _is_wait_mode:
		_va_say("Chế độ Luyện tập: Hệ thống sẽ chờ con thổi đúng nốt nhạc.")
	else:
		_va_say("Chế độ Tự trôi: Bản nhạc sẽ trôi tự động theo nhịp độ.")
	_update_wait_mode_ui()

func _advance_note_in_practice() -> void:
	if _note_idx < note_statuses.size():
		note_statuses[_note_idx] = "correct"
		
	var target_note = sheet_notes[_note_idx]
	if _lesson_mode == 0:
		_note_idx = (_note_idx + 1) % sheet_notes.size()
		_build_notation()
		_update_target_indicator()
		
		# Guide sound & prompt
		var next_note = sheet_notes[_note_idx]
		_play_flute_sound_guide(next_note)
		_va_say("Đúng rồi! Hãy tiếp tục thổi nốt mẫu %s nhé." % next_note)
	else:
		# Play zither backing pluck
		_play_zither_backing(target_note)
		_va_say("Chuẩn nốt! Nhạc nền tiếp tục...")
		
		# Resume backing track!
		_backing_playing = true
		_backing_timer = BEAT_DURATION

func _trigger_rewind() -> void:
	_total_mistakes = 0
	_note_idx = max(0, _note_idx - 3)
	_current_note_elapsed = 0.0
	_current_note_correct_frames = 0
	_current_note_total_frames = 0
	_waiting_for_breath_release = false
	
	# Reset status array for rewound notes
	for i in range(_note_idx, note_statuses.size()):
		if i < note_statuses.size():
			note_statuses[i] = "unplayed"
			
	_build_notation()
	_update_target_indicator()
	
	# Reset rhythm display error counters
	rhythm_acc.text = "Lỗi: 0/2"
	rhythm_acc.add_theme_color_override("font_color", C_TEXT_MUTED)
	
	_va_say("THỔI SAI QUÁ 2 NỐT! Lùi lại 3 nốt...")

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
	
	# Dynamically update ScoreSub to show real-time average accuracy!
	var avg_pitch := 80.0
	if _pitch_scores.size() > 0:
		var sum := 0.0
		for s in _pitch_scores: sum += s
		avg_pitch = sum / _pitch_scores.size()
		
	var avg_breath := 80.0
	if _breath_scores.size() > 0:
		var sum := 0.0
		for s in _breath_scores: sum += s
		avg_breath = sum / _breath_scores.size()
		
	var score_sub_lbl := $Root/MiddleRow/MainContent/StatsRow/StatsM/StatsHBox/ScoreV/ScoreSub as Label
	if score_sub_lbl:
		score_sub_lbl.text = "Cao độ %d%%  ·  Cột hơi %d%%" % [int(avg_pitch), int(avg_breath)]

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
		collapse_btn.custom_minimum_size = Vector2(0, 54)
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
		spacer.custom_minimum_size = Vector2(0, 36)
		linh_vbox.add_child(spacer)
		linh_vbox.move_child(spacer, 1)

	linh_mini_btn = Button.new()
	linh_mini_btn.name = "LinhMiniBtn"
	linh_mini_btn.custom_minimum_size = Vector2(96, 96)
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
	btn_s.corner_radius_top_left = 48; btn_s.corner_radius_top_right = 48
	btn_s.corner_radius_bottom_left = 48; btn_s.corner_radius_bottom_right = 48
	btn_s.shadow_size = 8; btn_s.shadow_color = Color(0.13, 0.08, 0.05, 0.15)
	
	linh_mini_btn.add_theme_stylebox_override("normal", btn_s)
	linh_mini_btn.add_theme_stylebox_override("hover", btn_s.duplicate())
	linh_mini_btn.add_theme_stylebox_override("pressed", btn_s.duplicate())
	
	var mini_tex := TextureRect.new()
	mini_tex.texture = load("res://assets/textures/avacogiaoMai_asset.png")
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
		linh_panel.visible = false
	if linh_mini_btn:
		linh_mini_btn.visible = false

func _show_custom_hint() -> void:
	var popup_scene := load("res://scenes/CustomPopup.tscn") as PackedScene
	if popup_scene:
		var popup = popup_scene.instantiate()
		add_child(popup)
		var text := "[b]🎵 HƠI THỞ:[/b]\nThổi hơi đều, ổn định, không quá mạnh để tránh bị quá quãng (overblow).\n\n[b]🎵 THẾ BẤM CHE LỖ:[/b]\nĐặt các đầu ngón tay phủ kín hoàn toàn các lỗ sáo sẫm màu theo thế bấm nốt nhạc mục tiêu.\n\n[b]💡 HƯỚNG DẪN KỸ THUẬT:[/b]\n• Giữ môi khép nhẹ, thổi luồng hơi tập trung.\n• Thả lỏng cổ tay và ngón tay khi che lỗ sáo.\n• Lắng nghe cao độ phản hồi để điều chỉnh thế bấm.\n• Luyện tập hơi dài và đều đặn mỗi ngày."
		popup.setup_hint("Gợi ý kỹ thuật", text)

func _show_custom_result() -> void:
	var inst := InstrumentSelect.selected_instrument
	var stars := 1
	if _score >= 85.0: stars = 3
	elif _score >= 75.0: stars = 2
	
	if _score >= 70.0:
		SecureDataManager.complete_lesson(inst, SecureDataManager.active_lesson_id, stars)
		_sync_practice_to_backend(inst, SecureDataManager.active_lesson_id, stars)
		
	var popup_scene := load("res://scenes/CustomPopup.tscn") as PackedScene
	if popup_scene:
		var popup = popup_scene.instantiate()
		add_child(popup)
		var p := randf_range(70, 92)
		var r := randf_range(65, 90)
		var t := clampf((_score * 3.0 - p - r), 60, 95)
		
		var next_lesson_name := "Khóa Học Tiếp"
		if SecureDataManager.active_lesson_id == "Node2":
			next_lesson_name = "Luyện Ngón"
		elif SecureDataManager.active_lesson_id == "Node3":
			next_lesson_name = "Nhấp Ngón"
			
		popup.setup_result(_score, p, r, t, 80, "Đã mở khóa: " + next_lesson_name)

func _sync_practice_to_backend(inst: String, local_lesson_id: String, _stars: int) -> void:
	if not BackendReport.is_signed_in():
		return
	var result: Dictionary = await BackendReport.report_practice(inst, local_lesson_id, {
		"pitch": _get_average_score(_pitch_scores, 80.0),
		"rhythm": _last_rhythm_score,
		"dynamics": 0.0,
		"tonal_quality": 0.0,
		"breath": _get_average_score(_breath_scores, 80.0),
	})
	if not result.get("submitted", false):
		push_warning("[PracticeSaoTruc] Không đồng bộ lượt tập: %s" % str(result.get("reason", "")))

func _reset() -> void:
	_note_idx = 0
	_score = 75.0
	_eval_cooldown = 0.0
	_covered_states = [true, true, true, true, true, true]
	_build_notation()
	_build_flute()
	_update_target_indicator()
	_update_rec_pulse(false)
	var visualizer = _waveform_visualizer
	if visualizer: visualizer.visible = false
	pitch_note.text = "-"
	pitch_status.text = "Đang nghe..."
	pitch_status.add_theme_color_override("font_color", C_TEXT_MUTED)
	pitch_note.add_theme_color_override("font_color", C_RED_SON)
	rhythm_acc.text = "Đang nghe..."
	if _active_player and is_instance_valid(_active_player):
		_active_player.stop()
		_active_player.queue_free()
		_active_player = null

func _go_back() -> void:
	if _intro_audio_manager:
		_intro_audio_manager.audio_player.stop()
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.22)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))

## Pitch-detection stubs — to be replaced with real audio analysis
func _start_pitch_detection() -> void:
	_sim_timer = 0.0
	_note_idx = 0
	_correct_pitch_hold_time = 0.0
	_build_lesson_beats()
	
	if _lesson_mode == 0:
		_backing_playing = false
		var first_note = sheet_notes[0] if sheet_notes.size() > 0 else "Đô"
		_play_flute_sound_guide(first_note)
		_va_say("Bài 1: Hãy thổi nốt mẫu %s theo hướng dẫn bấm ngón nhé!" % first_note)
	else:
		_backing_playing = true
		_backing_beat_idx = -1
		_backing_timer = BEAT_DURATION
		_va_say("Bài 2: Nhạc nền đang chạy... Hãy chú ý lắng nghe và thổi đúng lúc nhé!")

func _stop_pitch_detection() -> void:
	_sim_timer = 0.0
	_backing_playing = false

func _flat(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.border_color = border
	s.border_width_left = 2; s.border_width_right  = 2
	s.border_width_top  = 2; s.border_width_bottom = 2
	s.corner_radius_top_left     = radius; s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius; s.corner_radius_bottom_right = radius
	return s

func _style_progress_bar(pb: ProgressBar, fill: Color, bg: Color) -> void:
	var pf := StyleBoxFlat.new(); pf.bg_color = fill
	pf.corner_radius_top_left = 11; pf.corner_radius_top_right = 11
	pf.corner_radius_bottom_left = 11; pf.corner_radius_bottom_right = 11
	pf.shadow_size = 5; pf.shadow_color = Color(fill.r, fill.g, fill.b, 0.4)
	var pbg := StyleBoxFlat.new(); pbg.bg_color = bg
	pbg.corner_radius_top_left = 11; pbg.corner_radius_top_right = 11
	pbg.corner_radius_bottom_left = 11; pbg.corner_radius_bottom_right = 11
	pb.add_theme_stylebox_override("fill", pf)
	pb.add_theme_stylebox_override("background", pbg)

func _style_text_btn(btn: Button, col: Color, hover: Color) -> void:
	if not is_instance_valid(btn): return
	var f_body_bold := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if f_body_bold: btn.add_theme_font_override("font", f_body_bold)
	btn.add_theme_font_size_override("font_size", 21)
	
	btn.add_theme_color_override("font_color", col)
	btn.add_theme_color_override("font_hover_color", hover)
	btn.add_theme_stylebox_override("normal",  _flat(Color(0,0,0,0), Color(0,0,0,0), 8))
	btn.add_theme_stylebox_override("hover",   _flat(Color(col.r,col.g,col.b,0.12), Color(0,0,0,0), 8))
	btn.add_theme_stylebox_override("pressed", _flat(Color(col.r,col.g,col.b,0.20), Color(0,0,0,0), 8))
	btn.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0), 0))

func _style_outlined_btn(btn: Button) -> void:
	if not is_instance_valid(btn): return
	var f_body_bold := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if f_body_bold: btn.add_theme_font_override("font", f_body_bold)
	btn.add_theme_font_size_override("font_size", 20)
	
	var bn := _flat(C_CARD, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45), 14)
	var bh := _flat(C_CARD, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.85), 14)
	bh.shadow_size = 5; bh.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.15)
	
	btn.add_theme_stylebox_override("normal",  bn)
	btn.add_theme_stylebox_override("hover",   bh)
	btn.add_theme_stylebox_override("pressed", _flat(C_BG_BAR, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.5), 14))
	btn.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	btn.add_theme_color_override("font_color",         C_TEXT)
	btn.add_theme_color_override("font_hover_color",   C_GOLD_TEXT)
	btn.add_theme_color_override("font_pressed_color", C_TEXT)

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

func _update_breath_physics(delta: float) -> void:
	var visualizer = _waveform_visualizer
	var target_breath := 0.0
	
	if _recording:
		if _auto_blow or not _mic_mode:
			target_breath = 65.0 + sin(Time.get_ticks_msec() * 0.005) * 2.5
		elif visualizer and ProjectSettings.get_setting("audio/driver/enable_input"):
			if visualizer.current_amplitude_db > visualizer.volume_threshold_db:
				var db = visualizer.current_amplitude_db
				var range_db = abs(visualizer.volume_threshold_db)
				target_breath = clamp((db - visualizer.volume_threshold_db) / max(10.0, range_db - 5.0), 0.0, 1.0) * 100.0
			else:
				target_breath = 0.0
		else:
			target_breath = 65.0 + sin(Time.get_ticks_msec() * 0.005) * 2.5
	else:
		target_breath = 0.0
		
	_breath_pressure = lerp(_breath_pressure, target_breath, 0.15)
	breath_progress.value = _breath_pressure
	
	var flute_body := $Root/FluteBoard/BoardM/BoardVBox/FluteFrame/FluteM/FluteStack/FluteBody as Control
	if flute_body:
		var overblown := _breath_pressure > 82.0
		if flute_body.get("is_overblowing") != overblown:
			flute_body.set("is_overblowing", overblown)
			flute_body.queue_redraw()
	
	var fill_style = breath_progress.get_theme_stylebox("fill") as StyleBoxFlat
	if not fill_style:
		fill_style = StyleBoxFlat.new()
		fill_style.corner_radius_top_left = 9; fill_style.corner_radius_top_right = 9
		fill_style.corner_radius_bottom_left = 9; fill_style.corner_radius_bottom_right = 9
		breath_progress.add_theme_stylebox_override("fill", fill_style)
		
	if _breath_pressure < 12.0:
		breath_status.text = "Chờ hơi thổi..."
		breath_status.add_theme_color_override("font_color", C_CREAM_DIM)
		fill_style.bg_color = C_CREAM_DIM
		if _recording and _active_player and is_instance_valid(_active_player):
			_active_player.volume_db = -80.0
	elif _breath_pressure >= 12.0 and _breath_pressure <= 85.0:
		breath_status.text = "Ổn định (Đạt chuẩn)"
		breath_status.add_theme_color_override("font_color", C_GREEN_OK)
		fill_style.bg_color = C_JADE
		if _recording and _active_player and is_instance_valid(_active_player):
			_active_player.volume_db = -3.0
			_active_player.pitch_scale = 1.0
	else:
		breath_status.text = "Hơi quá mạnh (Overblow +1 Octave)"
		breath_status.add_theme_color_override("font_color", C_RED_ERR)
		fill_style.bg_color = C_RED_ERR
		if _recording and _active_player and is_instance_valid(_active_player):
			_active_player.volume_db = -1.0
			_active_player.pitch_scale = 2.0

func _update_rec_pulse(active: bool) -> void:
	var rec_indicator := $Root/RecordBar/RecordM/RecordH.get_node_or_null("RecIndicator") as Control
	if not rec_indicator: return
	
	if _rec_tween and _rec_tween.is_valid():
		_rec_tween.kill()
		
	rec_indicator.visible = active
	if active:
		rec_indicator.modulate.a = 1.0
		rec_indicator.scale = Vector2.ONE
		rec_indicator.pivot_offset = Vector2(45, 23)
		
		_rec_tween = create_tween().set_loops()
		_rec_tween.set_parallel(true)
		_rec_tween.tween_property(rec_indicator, "modulate:a", 0.3, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_rec_tween.tween_property(rec_indicator, "scale", Vector2(1.08, 1.08), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_rec_tween.chain().parallel()
		_rec_tween.tween_property(rec_indicator, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_rec_tween.tween_property(rec_indicator, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

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

func _check_teacher_advice(closest_note: String, is_breath_ok: bool) -> void:
	if not _recording: return
	
	var target_note = sheet_notes[_note_idx]
	if closest_note == "":
		return
		
	if closest_note == target_note:
		if _breath_pressure < 40.0:
			_va_say("Đúng nốt %s rồi! Nhưng hãy thổi mạnh hơi lên một chút để âm vang chuẩn nhé." % target_note)
		elif _breath_pressure > 82.0:
			_va_say("Hơi mạnh quá rồi! Hãy thổi nhẹ hơi lại để tránh bị overblow nốt %s." % target_note)
		else:
			if randf() > 0.6:
				_va_say("Rất tốt! Luồng hơi của con cực kỳ ổn định đấy.")
	else:
		if _breath_pressure < 40.0:
			_va_say("Hơi đang yếu và bấm sai nốt nữa. Hãy che lỗ nốt %s và thổi mạnh lên tí nhé." % target_note)
		elif _breath_pressure > 82.0:
			_va_say("Thổi quá mạnh làm âm bị chói và sai nốt. Thổi nhẹ lại và bấm nốt %s." % target_note)
		else:
			_va_say("Bị sai nốt rồi. Con hãy quan sát kỹ gợi ý thế bấm nốt %s ở bên dưới nhé!" % target_note)

func _update_virtual_holes(note_name: String) -> void:
	var fingering = FINGERINGS.get(note_name, [])
	if fingering.size() != HOLES: return
	
	for i in range(HOLES):
		var hole = holes_hbox.get_child(i) as PanelContainer
		if hole:
			var hs = hole.get_theme_stylebox("panel") as StyleBoxFlat
			if hs:
				var is_covered = fingering[i]
				if is_covered:
					hs.bg_color = Color.RED
					hs.border_color = Color.INDIAN_RED
				else:
					hs.bg_color = Color(0.04, 0.02, 0.01)
					hs.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25)

func _update_virtual_holes_to_clicked_states() -> void:
	for i in range(HOLES):
		var hole = holes_hbox.get_child(i) as PanelContainer
		if hole:
			var hs = hole.get_theme_stylebox("panel") as StyleBoxFlat
			if hs:
				var is_covered = _covered_states[i]
				if is_covered:
					hs.bg_color = Color.RED
					hs.border_color = Color.INDIAN_RED
				else:
					hs.bg_color = Color(0.04, 0.02, 0.01)
					hs.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25)

# ─── Zither Accompaniment Backing Track ───────────────────────────────────────
func _get_zither_frequency(note_name: String) -> float:
	var base_freqs = {
		"Đô": 130.81, "Rê": 146.83, "Mi": 164.81, "Fa": 174.61, "Sol": 196.00, "La": 220.00, "Si": 246.94,
		"Đô2": 261.63, "Rê2": 293.66, "Mi2": 329.63, "Fa2": 349.23, "Sol2": 392.00, "La2": 440.00, "Si2": 493.88,
		"Đô3": 523.25, "Rê3": 587.33
	}
	if base_freqs.has(note_name):
		return base_freqs[note_name]
	var clean = note_name.replace("#", "")
	if base_freqs.has(clean):
		return base_freqs[clean]
	return 261.63

func _generate_zither_streams() -> void:
	var notes_to_gen = [
		"Đô", "Rê", "Mi", "Fa", "Sol", "La", "Si",
		"Đô2", "Rê2", "Mi2", "Fa2", "Sol2", "La2", "Si2",
		"Đô3", "Rê3"
	]
	for note in notes_to_gen:
		var freq = _get_zither_frequency(note)
		_zither_streams[note] = _generate_zither_pluck_stream(freq)

func _generate_zither_pluck_stream(freq: float) -> AudioStreamWAV:
	const SAMPLE_RATE: int = 44100
	const DURATION: float  = 2.0
	var sample_count: int  = int(SAMPLE_RATE * DURATION)

	var delay_len: int = int(float(SAMPLE_RATE) / freq)
	if delay_len < 2:
		delay_len = 2

	var delay_buf := PackedFloat32Array()
	delay_buf.resize(delay_len)
	for k in delay_len:
		delay_buf[k] = randf_range(-1.0, 1.0)

	var decay: float = clamp(0.996 - freq / 20000.0, 0.980, 0.9995)

	var samples := PackedFloat32Array()
	samples.resize(sample_count)
	var buf_pos: int = 0

	for i in sample_count:
		var next_pos: int = (buf_pos + 1) % delay_len
		var new_sample: float = decay * 0.5 * (delay_buf[buf_pos] + delay_buf[next_pos])
		samples[i] = new_sample
		delay_buf[buf_pos] = new_sample
		buf_pos = (buf_pos + 1) % delay_len

	var max_amp: float = 0.0
	for s in samples:
		var abs_s: float = absf(s)
		if abs_s > max_amp:
			max_amp = abs_s
	if max_amp < 0.0001:
		max_amp = 1.0
	var norm_factor: float = 0.92 / max_amp

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

func _play_zither_backing(note: String) -> void:
	var clean_note = note
	if not _zither_streams.has(clean_note):
		clean_note = clean_note.replace("#", "")
	if not _zither_streams.has(clean_note): return
	
	var pl := AudioStreamPlayer.new()
	pl.stream = _zither_streams[clean_note]
	pl.volume_db = -8.0 # softer zither backing track
	pl.bus = "Master"
	add_child(pl)
	pl.play()
	get_tree().create_timer(2.5).timeout.connect(pl.queue_free)

func _play_flute_sound_guide(note: String) -> void:
	# Muted per user request: only recognize pitch, do not play guide sounds
	return

func _build_lesson_beats() -> void:
	_lesson_beats.clear()
	var first_note = sheet_notes[0] if sheet_notes.size() > 0 else "Đô"
	var helper_note = "Sol"
	if first_note == "Sol" or first_note == "La":
		helper_note = "Đô"
	
	# Intro (4 beats)
	_lesson_beats.append({"action": "play_zither", "note": first_note})
	_lesson_beats.append({"action": "play_zither", "note": helper_note})
	_lesson_beats.append({"action": "play_zither", "note": first_note})
	_lesson_beats.append({"action": "play_zither", "note": helper_note})
	
	# Play melody & pause for user
	for note in sheet_notes:
		if _is_rest_note(note):
			_lesson_beats.append({"action": "rest"})
			continue
		_lesson_beats.append({"action": "target_flute", "note": note})
		var acc_note = "Sol" if note != "Sol" else "Đô"
		_lesson_beats.append({"action": "play_zither", "note": acc_note})
	
	# Outro
	_lesson_beats.append({"action": "play_zither", "note": "Đô2"})
	_lesson_beats.append({"action": "play_zither", "note": "Mi2"})
	_lesson_beats.append({"action": "play_zither", "note": "Sol2"})
	_lesson_beats.append({"action": "play_zither", "note": "Đô3"})
	_lesson_beats.append({"action": "finish"})

func _update_backing_track(delta: float) -> void:
	if not _backing_playing: return
	
	_backing_timer += delta
	if _backing_timer >= BEAT_DURATION:
		_backing_timer = 0.0
		_backing_beat_idx += 1
		
		if _backing_beat_idx >= _lesson_beats.size():
			_backing_playing = false
			_toggle_record()
			_show_custom_result()
			_va_say("Tuyệt vời! Con đã hoàn thành luyện tập với nhạc nền xuất sắc!")
			return
			
		var beat = _lesson_beats[_backing_beat_idx]
		match beat.action:
			"play_zither":
				_play_zither_backing(beat.note)
			"rest":
				_va_say("Nghỉ hơi đúng trường độ.")
			"target_flute":
				_backing_playing = false
				var match_idx = -1
				for k in range(_note_idx, sheet_notes.size()):
					if sheet_notes[k] == beat.note:
						match_idx = k
						break
				if match_idx != -1:
					_note_idx = match_idx
				else:
					match_idx = sheet_notes.find(beat.note)
					if match_idx != -1:
						_note_idx = match_idx
						
				_build_notation()
				_update_target_indicator()
				
				# Guide sound & prompt
				_play_flute_sound_guide(beat.note)
				_va_say("Nghe nhạc mẫu. Hãy thổi nốt %s!" % beat.note)
func _get_average_score(scores: Array, default_val: float) -> float:
	if scores.size() == 0:
		return default_val
	var sum := 0.0
	for s in scores:
		sum += s
	return sum / scores.size()

func _get_scroll_target_for_note(idx: int) -> float:
	var scroll_container := notes_hbox.get_parent() as ScrollContainer
	if not scroll_container: return 0.0
	
	var separation := 16.0
	var active_x := 0.0
	var active_w := 70.0
	for j in range(idx):
		var dur := sheet_durations[j] if j < sheet_durations.size() else 1.0
		active_x += (70.0 + dur * 60.0) + separation
	
	if idx < sheet_durations.size():
		var dur := sheet_durations[idx]
		active_w = 70.0 + dur * 60.0
		
	var viewport_w : float = scroll_container.size.x if scroll_container.size.x > 0 else 800.0
	return active_x + (active_w / 2.0) - (viewport_w / 2.0)

func _on_song_selected(index: int) -> void:
	if index < 0 or index >= songs_list.size(): return
	var song = songs_list[index]
	
	current_song_title = song["title"]
	sheet_notes.assign(song["sheet"])
	sheet_durations.assign(song["durations"])
	_song_bpm = song["bpm"]
	
	if sheet_durations.size() != sheet_notes.size():
		sheet_durations.clear()
		for note in sheet_notes:
			sheet_durations.append(1.0)
			
	# Stop active player if playing
	if _active_player and is_instance_valid(_active_player):
		_active_player.stop()
		_active_player.queue_free()
		_active_player = null
		
	# Reset states
	_note_idx = 0
	_current_note_elapsed = 0.0
	_current_note_correct_frames = 0
	_current_note_total_frames = 0
	_total_mistakes = 0
	_correct_pitch_hold_time = 0.0
	_score = 75.0
	_sim_timer = 0.0
	_ignore_input_timer = 0.0
	_backing_playing = false
	
	# Stop recording quietly if active
	if _recording:
		_recording = false
		_update_rec_pulse(false)
		record_btn.text = "Bắt đầu luyện tập"
		_stop_pitch_detection()
		var visualizer = _waveform_visualizer
		if visualizer: visualizer.visible = false
		
	_set_labels()
	_build_notation()
	_build_dots()
	_build_rhythm_bars()
	_build_lesson_beats()
	_update_target_indicator()
	_refresh_score()
	
	# Set fingering visualization helper to the first note
	if sheet_notes.size() > 0:
		var target_fingering = FINGERINGS.get(sheet_notes[0], [false, false, false, false, false, false])
		_covered_states.assign(target_fingering)
		_build_flute()
	
	_va_say("Đã chọn bài: " + current_song_title)

func _get_lane_y(note_name: String) -> float:
	var track_panel = $Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox.get_node_or_null("NoteTrackPanel")
	if not track_panel: return 0.0
	var note_container = track_panel.get_node_or_null("NoteContainer")
	if not note_container: return 0.0
	
	var clean_note := note_name.replace("²", "") # strip overblow indicator
	var lane_idx = LANES.find(clean_note)
	if lane_idx == -1:
		lane_idx = 0
	var lane_h := 90.0
	var container_h = note_container.size.y if note_container.size.y > 0 else 300.0
	var y = container_h - (lane_idx * lane_h - _viewport_scroll_y + lane_h)
	return y

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
	for note in sheet_notes:
		note_statuses.append("unplayed")
		
	# Build note blocks
	var time_beats = 0.0
	for i in range(sheet_notes.size()):
		var note_name = sheet_notes[i]
		var duration = sheet_durations[i]
		
		var block := Panel.new()
		block.name = "NoteBlock_%d" % i
		
		var bs := StyleBoxFlat.new()
		bs.bg_color = Color("#5c8c72") # Slate jade unplayed (soft sage/jade green)
		bs.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45)
		bs.border_width_left = 1; bs.border_width_right = 1
		bs.border_width_top = 1; bs.border_width_bottom = 1
		bs.corner_radius_top_left = 9; bs.corner_radius_top_right = 9
		bs.corner_radius_bottom_left = 9; bs.corner_radius_bottom_right = 9
		block.add_theme_stylebox_override("panel", bs)
		
		# Add label for note name
		var lbl := Label.new()
		lbl.text = note_name
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.anchors_preset = Control.PRESET_FULL_RECT
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.add_theme_font_size_override("font_size", 20)
		block.add_child(lbl)
		
		# Save metadata on the block
		block.set_meta("note_time", time_beats)
		block.set_meta("note_duration", duration)
		block.set_meta("note_name", note_name)
		
		note_container.add_child(block)
		note_visuals[i] = block
		time_beats += duration
		
		if fmod(time_beats, 4.0) == 0.0:
			var bar_line = ColorRect.new()
			bar_line.color = Color(1, 1, 1, 0.4)
			bar_line.custom_minimum_size = Vector2(2, 400)
			bar_line.set_meta("is_bar_line", true)
			bar_line.set_meta("note_time", time_beats)
			note_container.add_child(bar_line)


func _set_block_color(block: Panel, color: Color) -> void:
	if not is_instance_valid(block): return
	var sb = block.get_theme_stylebox("panel") as StyleBoxFlat
	if sb:
		var sb_dup = sb.duplicate() as StyleBoxFlat
		sb_dup.bg_color = color
		block.add_theme_stylebox_override("panel", sb_dup)

func _show_introduction_overlay() -> void:
	_current_intro_step = 0
	_intro_hole_cols.clear()
	
	# Initialize slide data
	_intro_slides = [
		{
			"text": "Chào mừng con đến với bài học hơi thở và che lỗ cơ bản của sáo trúc. Sáo trúc là một nhạc cụ thổi hơi vô cùng độc đáo của dân tộc ta.",
			"voice": "Chào mừng con đến với bài học hơi thở và che lỗ cơ bản của sáo trúc. Sáo trúc là một nhạc cụ thổi hơi vô cùng độc đáo của dân tộc ta.",
			"fingering": [true, true, true, true, true, true],
			"active_hole": -1,
			"note_to_play": ""
		},
		{
			"text": "Sáo trúc của chúng ta có sáu lỗ bấm chính. Cây sáo C5 Đô này có thể thổi được 15 âm từ Đô 1 đến Đô 3. Khi bịt kín toàn bộ cả sáu lỗ, ta sẽ thổi được nốt Đô (C5) trầm nhất.",
			"voice": "Sáo trúc của chúng ta có sáu lỗ bấm chính. Cây sáo Đô năm này có thể thổi được mười lăm âm từ Đô một đến Đô ba. Khi bịt kín toàn bộ cả sáu lỗ, ta sẽ thổi được nốt Đô trầm nhất.",
			"fingering": [true, true, true, true, true, true],
			"active_hole": -1,
			"note_to_play": "Đô (C5)"
		},
		{
			"text": "Mở lỗ số 6 (ngoài cùng bên phải), năm lỗ còn lại bịt kín, ta thổi được nốt Rê (D5).",
			"voice": "Mở lỗ số sáu ngoài cùng bên phải, năm lỗ còn lại bịt kín, ta thổi được nốt Rê.",
			"fingering": [true, true, true, true, true, false],
			"active_hole": 5,
			"note_to_play": "Rê (D5)"
		},
		{
			"text": "Tiếp tục mở lỗ số 5, bốn lỗ bên trái bịt kín, ta thổi được nốt Mi (E5).",
			"voice": "Tiếp tục mở lỗ số năm, bốn lỗ bên trái bịt kín, ta thổi được nốt Mi.",
			"fingering": [true, true, true, true, false, false],
			"active_hole": 4,
			"note_to_play": "Mi (E5)"
		},
		{
			"text": "Mở lỗ số 4, ba lỗ bên trái bịt kín, ta thổi được nốt Fa (F5).",
			"voice": "Mở lỗ số bốn, ba lỗ bên trái bịt kín, ta thổi được nốt Fa.",
			"fingering": [true, true, true, false, false, false],
			"active_hole": 3,
			"note_to_play": "Fa (F5)"
		},
		{
			"text": "Mở lỗ số 3, hai lỗ bên trái bịt kín, ta thổi được nốt Sol (G5).",
			"voice": "Mở lỗ số ba, hai lỗ bên trái bịt kín, ta thổi được nốt Sol.",
			"fingering": [true, true, false, false, false, false],
			"active_hole": 2,
			"note_to_play": "Sol (G5)"
		},
		{
			"text": "Mở lỗ số 2, chỉ bịt kín lỗ số 1 bên trái, ta thổi được nốt La (A5).",
			"voice": "Mở lỗ số hai, chỉ bịt kín lỗ số một bên trái, ta thổi được nốt La.",
			"fingering": [true, false, false, false, false, false],
			"active_hole": 1,
			"note_to_play": "La (A5)"
		},
		{
			"text": "Cuối cùng, mở lỗ số 1 - tức là mở toàn bộ cả sáu lỗ sáo, ta sẽ thổi được nốt Si (B5).",
			"voice": "Cuối cùng, mở lỗ số một, tức là mở toàn bộ cả sáu lỗ sáo, ta sẽ thổi được nốt Si.",
			"fingering": [false, false, false, false, false, false],
			"active_hole": 0,
			"note_to_play": "Si (B5)"
		},
		{
			"text": "Rất giỏi! Con đã nắm vững vị trí bấm của sáu nốt sáo cơ bản rồi đấy. Hãy bấm Bắt đầu luyện tập để thử sức nhé!",
			"voice": "Rất giỏi! Con đã nắm vững vị trí bấm của sáu nốt sáo cơ bản rồi đấy. Hãy bấm Bắt đầu luyện tập để thử sức nhé!",
			"fingering": [false, false, false, false, false, false],
			"active_hole": -1,
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
	artist_img.texture = load("res://assets/textures/avacogiaoMai_asset.png")
	artist_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artist_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	artist_img.size = Vector2(850, 720)
	artist_img.custom_minimum_size = Vector2(1275, 1080)
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
	title.text = "BÀI HỌC CƠ BẢN: SÁO TRÚC 6 LỖ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if f_title: title.add_theme_font_override("font", f_title)
	title.add_theme_font_size_override("font_size", 39)
	title.add_theme_color_override("font_color", C_GOLD)
	right_vbox.add_child(title)

	# Active note highlight display
	_intro_active_note_display_lbl = Label.new()
	_intro_active_note_display_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if f_body_bold: _intro_active_note_display_lbl.add_theme_font_override("font", f_body_bold)
	_intro_active_note_display_lbl.add_theme_font_size_override("font_size", 33)
	_intro_active_note_display_lbl.add_theme_color_override("font_color", C_GOLD_LIGHT)
	right_vbox.add_child(_intro_active_note_display_lbl)
	
	# Speech Bubble Panel Container for instructions
	var bubble := PanelContainer.new()
	var bs := StyleBoxFlat.new()
	bs.bg_color = C_BG_BAR
	bs.border_color = C_GOLD
	bs.border_width_left = 2; bs.border_width_right = 2
	bs.border_width_top = 2; bs.border_width_bottom = 2
	bs.corner_radius_top_left = 24; bs.corner_radius_top_right = 24
	bs.corner_radius_bottom_left = 24; bs.corner_radius_bottom_right = 24
	bs.shadow_size = 6
	bs.shadow_color = Color(0, 0, 0, 0.25)
	bubble.add_theme_stylebox_override("panel", bs)
	bubble.custom_minimum_size = Vector2(540, 240)
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
	_intro_text_lbl.custom_minimum_size = Vector2(480, 180)
	if f_body: _intro_text_lbl.add_theme_font_override("font", f_body)
	_intro_text_lbl.add_theme_font_size_override("font_size", 23)
	_intro_text_lbl.add_theme_color_override("font_color", C_TEXT)
	bubble_margin.add_child(_intro_text_lbl)
	
	# Flute Display Container (Larger!)
	var flute_area := Control.new()
	flute_area.custom_minimum_size = Vector2(540, 300)
	flute_area.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	right_vbox.add_child(flute_area)
	
	# Flute Body cylinder (Larger!)
	_intro_flute_body = Control.new()
	_intro_flute_body.set_script(load("res://scripts/FluteBody.gd"))
	_intro_flute_body.custom_minimum_size = Vector2(510, 72)
	_intro_flute_body.size = Vector2(340, 48)
	_intro_flute_body.position = Vector2(10, 110)
	flute_area.add_child(_intro_flute_body)
	
	# Hole columns row
	var hole_row = HBoxContainer.new()
	hole_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hole_row.add_theme_constant_override("separation", 16)
	hole_row.size = Vector2(300, 120)
	hole_row.position = Vector2(20, 30)
	flute_area.add_child(hole_row)
	
	var hole_notes = ["Si", "La", "Sol", "Fa", "Mi", "Rê"]
	for i in range(6):
		var col := VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 6)
		
		# Note label
		var note_lbl := Label.new()
		note_lbl.text = hole_notes[i]
		note_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if f_body_bold: note_lbl.add_theme_font_override("font", f_body_bold)
		note_lbl.add_theme_font_size_override("font_size", 23)
		note_lbl.add_theme_color_override("font_color", C_GOLD)
		col.add_child(note_lbl)
		
		# Connector line
		var line := ColorRect.new()
		line.color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.4)
		line.custom_minimum_size = Vector2(3, 72)
		line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(line)
		
		# Circular Hole PanelContainer
		var hole := PanelContainer.new()
		hole.custom_minimum_size = Vector2(48, 48)
		
		var hs := StyleBoxFlat.new()
		hs.bg_color = Color("#1e110b")
		hs.border_color = C_GOLD
		hs.border_width_left = 2; hs.border_width_right = 2
		hs.border_width_top = 2; hs.border_width_bottom = 2
		hs.corner_radius_top_left = 24; hs.corner_radius_top_right = 24
		hs.corner_radius_bottom_left = 24; hs.corner_radius_bottom_right = 24
		hole.add_theme_stylebox_override("panel", hs)
		
		var num_lbl := Label.new()
		num_lbl.text = str(i + 1)
		num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		if f_body: num_lbl.add_theme_font_override("font", f_body)
		num_lbl.add_theme_font_size_override("font_size", 17)
		num_lbl.add_theme_color_override("font_color", C_CREAM)
		hole.add_child(num_lbl)
		col.add_child(hole)
		
		hole_row.add_child(col)
		_intro_hole_cols.append(col)
		
	# Navigation VBox Container
	var btn_vbox := VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 12)
	btn_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	right_vbox.add_child(btn_vbox)

	# Listen Button (Nghe Thử)
	_intro_listen_btn = Button.new()
	_intro_listen_btn.text = "🔊 NGHE THỬ"
	_intro_listen_btn.custom_minimum_size = Vector2(510, 72)
	if f_body_bold: _intro_listen_btn.add_theme_font_override("font", f_body_bold)
	_intro_listen_btn.add_theme_font_size_override("font_size", 23)
	_intro_listen_btn.add_theme_color_override("font_color", C_CREAM)
	
	var sb_listen_normal := StyleBoxFlat.new()
	sb_listen_normal.bg_color = Color("#091b10") # Dark jade green
	sb_listen_normal.border_color = C_GOLD
	sb_listen_normal.border_width_left = 2; sb_listen_normal.border_width_right = 2
	sb_listen_normal.border_width_top = 2; sb_listen_normal.border_width_bottom = 2
	sb_listen_normal.corner_radius_top_left = 15; sb_listen_normal.corner_radius_top_right = 15
	sb_listen_normal.corner_radius_bottom_left = 15; sb_listen_normal.corner_radius_bottom_right = 15
	
	var sb_listen_hover := StyleBoxFlat.new()
	sb_listen_hover.bg_color = Color("#11301c") # Lighter jade
	sb_listen_hover.border_color = C_GOLD_LIGHT
	sb_listen_hover.border_width_left = 2; sb_listen_hover.border_width_right = 2
	sb_listen_hover.border_width_top = 2; sb_listen_hover.border_width_bottom = 2
	sb_listen_hover.corner_radius_top_left = 15; sb_listen_hover.corner_radius_top_right = 15
	sb_listen_hover.corner_radius_bottom_left = 15; sb_listen_hover.corner_radius_bottom_right = 15
	
	_intro_listen_btn.add_theme_stylebox_override("normal", sb_listen_normal)
	_intro_listen_btn.add_theme_stylebox_override("hover", sb_listen_hover)
	_intro_listen_btn.add_theme_stylebox_override("pressed", sb_listen_normal)
	_intro_listen_btn.pressed.connect(func() -> void:
		if _current_intro_step < _intro_slides.size():
			var slide = _intro_slides[_current_intro_step]
			var note_to_play : String = slide.get("note_to_play", "")
			if note_to_play != "":
				var note_key = note_to_play.split(" ")[0]
				_play_intro_flute_sound_briefly(note_key, -3.0)
	)
	btn_vbox.add_child(_intro_listen_btn)
	_make_button_bouncy(_intro_listen_btn)

	# Next / Understood Button
	_intro_next_btn = Button.new()
	_intro_next_btn.text = "ĐÃ HIỂU ➔"
	_intro_next_btn.custom_minimum_size = Vector2(510, 72)
	if f_body_bold: _intro_next_btn.add_theme_font_override("font", f_body_bold)
	_intro_next_btn.add_theme_font_size_override("font_size", 23)
	_intro_next_btn.add_theme_color_override("font_color", C_CREAM)
	
	var sb_normal := StyleBoxFlat.new()
	sb_normal.bg_color = C_RED_SON
	sb_normal.border_color = C_GOLD
	sb_normal.border_width_left = 2; sb_normal.border_width_right = 2
	sb_normal.border_width_top = 2; sb_normal.border_width_bottom = 2
	sb_normal.corner_radius_top_left = 15; sb_normal.corner_radius_top_right = 15
	sb_normal.corner_radius_bottom_left = 15; sb_normal.corner_radius_bottom_right = 15
	
	var sb_hover := StyleBoxFlat.new()
	sb_hover.bg_color = C_RED_SON.lightened(0.12)
	sb_hover.border_color = C_GOLD_LIGHT
	sb_hover.border_width_left = 2; sb_hover.border_width_right = 2
	sb_hover.border_width_top = 2; sb_hover.border_width_bottom = 2
	sb_hover.corner_radius_top_left = 15; sb_hover.corner_radius_top_right = 15
	sb_hover.corner_radius_bottom_left = 15; sb_hover.corner_radius_bottom_right = 15
	
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
	if not _intro_overlay or not is_instance_valid(_intro_overlay): return
	if _current_intro_step < _intro_slides.size() - 1:
		_update_cinematic_step(_current_intro_step + 1)
	else:
		SecureDataManager.mark_intro_viewed("sao_truc")
		if _intro_audio_manager:
			_intro_audio_manager.audio_player.stop()
			_intro_audio_manager.queue_free()
			_intro_audio_manager = null
		if _active_player and is_instance_valid(_active_player):
			_active_player.stop()
			_active_player.queue_free()
			_active_player = null
		
		# Temporarily store the reference to prevent race conditions during tween
		var temp_overlay := _intro_overlay
		_intro_overlay = null
		var t := create_tween()
		t.tween_property(temp_overlay, "modulate:a", 0.0, 0.25)
		t.tween_callback(func() -> void:
			if is_instance_valid(temp_overlay):
				temp_overlay.queue_free()
		)

func _play_intro_flute_sound_briefly(note: String, volume: float = -12.0) -> void:
	if not _flute_streams.has(note): return
	if _active_player and is_instance_valid(_active_player):
		_active_player.stop()
		_active_player.queue_free()
		_active_player = null
		
	var new_player = AudioStreamPlayer.new()
	new_player.stream = _flute_streams[note]
	new_player.volume_db = -10.0
		
	# Slow-motion Pitch-preserving time stretch
	new_player.bus = "SlowMotion"
	new_player.pitch_scale = _speed_scale
	var bus_idx = AudioServer.get_bus_index("SlowMotion")
	if bus_idx != -1:
		var effect = AudioServer.get_bus_effect(bus_idx, 0) as AudioEffectPitchShift
		if effect:
			effect.pitch_scale = 1.0 / _speed_scale
				
	add_child(new_player)
	new_player.play()
	_active_player = new_player
	
	var ft = create_tween()
	ft.tween_interval(2.2 / _speed_scale)
	ft.tween_property(_active_player, "volume_db", -80.0, 0.5)
	ft.tween_callback(func() -> void:
		if _active_player and is_instance_valid(_active_player):
			_active_player.stop()
			_active_player.queue_free()
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
	if note_to_play != "":
		_intro_listen_btn.visible = true
		_intro_listen_btn.text = "🔊 NGHE THỬ NỐT " + note_to_play.split(" ")[0].to_upper()
		_intro_active_note_display_lbl.visible = true
		_intro_active_note_display_lbl.text = "Âm sắc: " + note_to_play
		
		# Auto-play a brief soft sound
		var note_key = note_to_play.split(" ")[0]
		_play_intro_flute_sound_briefly(note_key, -14.0)
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
		_intro_flute_body.modulate.a = 0.0
	else:
		_intro_flute_body.modulate.a = 1.0
		
	if step_idx == 0:
		_intro_flute_body.modulate.a = 0.0
		for col in _intro_hole_cols:
			col.modulate.a = 0.0
	else:
		_intro_flute_body.modulate.a = 1.0
		var fingering = slide.fingering
		var active_hole = slide.active_hole
		
		for i in range(6):
			var col = _intro_hole_cols[i]
			col.modulate.a = 1.0
			
			var is_covered = fingering[i]
			var hole = col.get_child(2) as PanelContainer
			var note_lbl = col.get_child(0) as Label
			var line = col.get_child(1) as ColorRect
			
			var hs = hole.get_theme_stylebox("panel") as StyleBoxFlat
			if hs:
				if is_covered:
					hs.bg_color = Color.RED
					hs.border_color = Color.INDIAN_RED
				else:
					hs.bg_color = Color(0.04, 0.02, 0.01)
					hs.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25)
					
			if i == active_hole or (step_idx == 1 and active_hole == -1):
				if step_idx == 1:
					note_lbl.visible = false
					line.visible = false
				else:
					note_lbl.visible = true
					line.visible = true
					line.color = C_GOLD_LIGHT
					
				if hs:
					hs.border_color = Color.INDIAN_RED
					if i == active_hole:
						hs.bg_color = Color.RED_LIGHT
				
				var ht := create_tween()
				ht.tween_property(hole, "scale", Vector2(1.15, 1.15), 0.15)
				ht.tween_property(hole, "scale", Vector2.ONE, 0.15)
			else:
				if step_idx == 8:
					note_lbl.visible = true
					line.visible = true
					line.color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.4)
				else:
					note_lbl.visible = false
					line.visible = false


func _setup_fullscreen_video_practice(guide_path: String) -> void:
	# 1. Make sure middle_row, MainContent, and NotationArea are visible
	var middle_row := $Root/MiddleRow as Control
	if middle_row: middle_row.visible = true
	var main_content := $Root/MiddleRow/MainContent as Control
	if main_content: main_content.visible = true
	var notation_area := $Root/MiddleRow/MainContent/NotationArea as PanelContainer
	if notation_area: 
		notation_area.visible = true
		notation_area.clip_contents = true

	# Style NotationM with 0 margins to maximize vertical and horizontal draw area
	var notation_m := $Root/MiddleRow/MainContent/NotationArea/NotationM as MarginContainer
	if notation_m:
		notation_m.add_theme_constant_override("margin_left", 0)
		notation_m.add_theme_constant_override("margin_right", 0)
		notation_m.add_theme_constant_override("margin_top", 0)
		notation_m.add_theme_constant_override("margin_bottom", 0)
	
	# Enlarge UI items for mobile readability
	var back_btn = $Root/TopBar/TopM/TopH/BackBtn as Button
	if back_btn:
		back_btn.custom_minimum_size = Vector2(240, 72)
		back_btn.add_theme_font_size_override("font_size", 33)
		
	var lesson_title = $Root/TopBar/TopM/TopH/LessonTitle as Label
	if lesson_title:
		lesson_title.add_theme_font_size_override("font_size", 39)
		
	var notation_label = $Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/TopInfoHBox/NotationVBoxLeft/NotationLabel as Label
	if notation_label:
		notation_label.add_theme_font_size_override("font_size", 36)
		
	var target_note_label = $Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/TopInfoHBox/NotationVBoxLeft/TargetNoteLabel as Label
	if target_note_label:
		target_note_label.add_theme_font_size_override("font_size", 48)
	
	# 2. Hide the dark Simply Piano lanes (NoteTrackPanel)
	var track_panel = $Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox.get_node_or_null("NoteTrackPanel")
	if track_panel:
		track_panel.visible = false
	var scroll_container := notes_hbox.get_parent() as ScrollContainer
	if scroll_container:
		scroll_container.visible = false
		
	# 3. Style NotationArea with solid white background and thin gold border
	var na_s := StyleBoxFlat.new()
	na_s.bg_color = Color.WHITE
	na_s.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35)
	na_s.border_width_left = 2; na_s.border_width_right = 2
	na_s.border_width_top = 2; na_s.border_width_bottom = 2
	na_s.corner_radius_top_left = 18; na_s.corner_radius_top_right = 18
	na_s.corner_radius_bottom_left = 18; na_s.corner_radius_bottom_right = 18
	notation_area.add_theme_stylebox_override("panel", na_s)
	
	# 4. Hide Linh character and recording controls
	if linh_panel:
		linh_panel.visible = false
	var r_bar := $Root/RecordBar as Control
	if r_bar:
		r_bar.visible = true
		
	# 5. Hide FluteBoard/StringsBoard guide at the bottom
	var flute_board := $Root/FluteBoard as Control
	if flute_board: flute_board.visible = false
	var strings_board := $Root/StringsBoard as Control
	if strings_board: strings_board.visible = false
	
	# 6. Hide right-side detail vbox in Sao Truc
	var right_vbox := $Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/TopInfoHBox/FluteVBoxRight as Control
	if right_vbox: right_vbox.visible = false
	
	# 7. Add Falling Notes Visualizer Track (replaces the simple vertical spacer layout flow)
	var notation_vbox := $Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox as VBoxContainer
	if notation_vbox:
		# Add a spacer to push the flute wrapper to the bottom of the vbox
		var spacer := Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		notation_vbox.add_child(spacer)
		
		# Add the interactive visualizer track as overlay inside notation_m
		# Stacking it in MarginContainer ensures it draws ON TOP of the flute image at the bottom!
		var visualizer_track := Control.new()
		visualizer_track.name = "VisualizerTrack"
		visualizer_track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		visualizer_track.size_flags_vertical = Control.SIZE_EXPAND_FILL
		# Disable mouse input so touch clicks fall through to the flute buttons below!
		visualizer_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Load the static script directly to avoid runtime reload compiler bugs
		var track_script := load("res://scripts/VisualizerTrack.gd") as GDScript
		visualizer_track.set_script(track_script)
		visualizer_track.set("practice_scene", self)
		
		if notation_m:
			notation_m.add_child(visualizer_track)

		# Add a clean white margin container as wrapper to center the guide nicely
		var wrapper := MarginContainer.new()
		wrapper.name = "GuideWrapper"
		wrapper.add_theme_constant_override("margin_left", 8)
		wrapper.add_theme_constant_override("margin_right", 8)
		wrapper.add_theme_constant_override("margin_top", 0)
		wrapper.add_theme_constant_override("margin_bottom", 12) # Small gap from bottom edge
		wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		wrapper.size_flags_vertical = Control.SIZE_SHRINK_END # Bottom align
		wrapper.custom_minimum_size = Vector2(0, 240) # Safe height
		notation_vbox.add_child(wrapper)
		
		if guide_path.ends_with(".png") or guide_path.ends_with(".jpg"):
			# Load as static image guide
			var img_rect := TextureRect.new()
			img_rect.name = "GuideImage"
			img_rect.texture = load(guide_path)
			img_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			img_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			img_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
			wrapper.add_child(img_rect)
			
			# Visually scale up the image to zoom in on the flute!
			# This bypasses all container minimum size constraints and avoids UI stretching!
			img_rect.scale = Vector2(1.8, 1.8)
			img_rect.item_rect_changed.connect(func() -> void:
				img_rect.pivot_offset = img_rect.size / 2
			)
		else:
			# Load as video stream guide
			var guide_player := VideoStreamPlayer.new()
			guide_player.name = "GuideVideoPlayer"
			guide_player.stream = load(guide_path)
			guide_player.expand = true
			guide_player.loop = true
			guide_player.volume_db = -80.0 # Silent loop
			guide_player.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			guide_player.size_flags_vertical = Control.SIZE_EXPAND_FILL
			wrapper.add_child(guide_player)
			
			# Visually scale up the video to zoom in!
			guide_player.scale = Vector2(1.8, 1.8)
			guide_player.item_rect_changed.connect(func() -> void:
				guide_player.pivot_offset = guide_player.size / 2
			)
			
			guide_player.play()
			guide_player.finished.connect(func() -> void:
				guide_player.play()
			)
		
	# 8. Hide StatsRow (cao độ/âm lượng) completely as requested
	var stats_row = $Root/MiddleRow/MainContent/StatsRow
	if stats_row:
		stats_row.visible = false
		
	# 9. Wait for user to tap Start
	pass

func _setup_audio_bus() -> void:
	var bus_idx = AudioServer.get_bus_index("SlowMotion")
	if bus_idx == -1:
		bus_idx = AudioServer.bus_count
		AudioServer.add_bus(bus_idx)
		AudioServer.set_bus_name(bus_idx, "SlowMotion")
		var pitch_shift = AudioEffectPitchShift.new()
		AudioServer.add_bus_effect(bus_idx, pitch_shift)
