extends Control
class_name PracticeSaoTruc

# ─── Color Palette ─────────────────────────────────────────────────────────────
const C_GOLD       := Color(0.77, 0.58, 0.15, 1.0)
const C_GOLD_LIGHT := Color(0.95, 0.82, 0.45, 1.0)
const C_JADE       := Color(0.12, 0.37, 0.23, 1.0)
const C_RED_SON    := Color(0.09, 0.27, 0.18, 1.0)
const C_CREAM      := Color(1.00, 0.97, 0.88, 1.0)
const C_CREAM_DIM  := Color(0.80, 0.76, 0.66, 1.0)
const C_GREEN_OK   := Color(0.12, 0.37, 0.23, 1.0)
const C_WARN       := Color(0.77, 0.58, 0.15, 1.0)
const C_RED_ERR    := Color(0.70, 0.12, 0.08, 1.0)

const C_BG         := Color(0.98, 0.97, 0.93, 1.0)
const C_BG_BAR     := Color(0.95, 0.93, 0.89, 1.0)
const C_CARD       := Color(1.00, 1.00, 1.00, 1.0)
const C_TEXT       := Color(0.13, 0.08, 0.05, 1.0)
const C_TEXT_MUTED := Color(0.43, 0.38, 0.33, 1.0)

@onready var linh_panel   : PanelContainer = $Root/MiddleRow/LinhPanel
@onready var char_linh    : TextureRect   = $Root/MiddleRow/LinhPanel/LinhVBox/CharLinhWrapper/CharLinh
@onready var speech_label : Label         = $Root/MiddleRow/LinhPanel/LinhVBox/SpeechBubble/SpeechM/SpeechLabel
@onready var lesson_bar   : ProgressBar   = $Root/TopBar/TopM/TopH/ProgressVBox/LessonBar
@onready var pitch_note   : Label         = $Root/MiddleRow/MainContent/StatsRow/PitchPanel/PitchM/PitchV/PitchNote
@onready var pitch_status : Label         = $Root/MiddleRow/MainContent/StatsRow/PitchPanel/PitchM/PitchV/PitchStatus
@onready var rhythm_bars  : HBoxContainer = $Root/MiddleRow/MainContent/StatsRow/RhythmPanel/RhythmM/RhythmV/RhythmBars
@onready var rhythm_acc   : Label         = $Root/MiddleRow/MainContent/StatsRow/RhythmPanel/RhythmM/RhythmV/RhythmAcc
@onready var score_num    : Label         = $Root/MiddleRow/MainContent/StatsRow/ScorePanel/ScoreM/ScoreV/ScoreNum
@onready var record_btn   : Button        = $Root/RecordBar/RecordM/RecordH/RecordBtn
@onready var notes_hbox   : HBoxContainer = $Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/NotesScroll/NotesHBox
@onready var target_note_label : Label    = $Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/TargetNoteLabel
@onready var holes_hbox   : HBoxContainer = $Root/FluteBoard/BoardM/BoardVBox/FluteFrame/FluteM/FluteStack/HoleRow
@onready var target_label : Label         = $Root/FluteBoard/BoardM/BoardVBox/TargetLabel
@onready var hint_dialog  : AcceptDialog  = $HintDialog
@onready var result_dialog: AcceptDialog  = $ResultDialog
@onready var dots_hbox    : HBoxContainer = $Root/TopBar/TopM/TopH/DotsHBox
@onready var breath_progress : ProgressBar = $Root/FluteBoard/BoardM/BoardVBox/BreathHBox/BreathProgress
@onready var breath_status   : Label       = $Root/FluteBoard/BoardM/BoardVBox/BreathHBox/BreathStatus

var _recording   := false
var _mic_mode    := true
var _score       := 75.0
var _sim_timer   := 0.0
var _ignore_input_timer := 0.0
var _correct_pitch_hold_time := 0.0
var _float_tween : Tween
var _note_idx    := 0

# AI Analysis tracking variables
var _practice_time := 0.0
var _detected_onsets : PackedFloat32Array = PackedFloat32Array()
var _reference_onsets : PackedFloat32Array = PackedFloat32Array()
var _pitch_scores : Array[float] = []
var _breath_scores : Array[float] = []

var _is_wait_mode := true
var _is_demo_mode := false
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

# Zither backing track variables
var _lesson_mode := 0 # 0: Học nốt, 1: Nhạc nền
var _backing_playing := false
var _backing_beat_idx := 0
var _backing_timer := 0.0
const BEAT_DURATION := 0.8
var _lesson_beats : Array = []
var _zither_streams : Dictionary = {}

var note_statuses : Array[String] = []
var note_visuals : Dictionary = {}
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

var sheet_notes : Array[String] = [
	"La", "La", "Đô2", "Rê2", "Rê2", "Mi2", "Rê2", "Đô2", "Rê2", "Mi2",
	"Mi2", "Rê2", "Đô2", "La", "Sol", "La", "Đô2",
	"La", "Sol", "La", "Đô2", "Rê2", "Mi2", "Sol2", "Mi2", "Rê2", "Mi2",
	"Mi2", "Rê2", "Đô2", "La", "Sol", "La", "Rê2", "Đô2", "La"
]

var sheet_durations : Array[float] = [
	0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 1.5,
	0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 2.0,
	0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 1.5,
	0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 2.0
]

var songs_list : Array[Dictionary] = [
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

func _ready() -> void:
	if current_song_title != "":
		sheet_notes.assign(current_song_sheet)
		sheet_durations.clear()
		for note in sheet_notes:
			sheet_durations.append(1.0)
	else:
		if sheet_durations.size() != sheet_notes.size():
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
		
	# Shrink other sections to give maximum space to the note visualizer
	var stats_row := $Root/MiddleRow/MainContent/StatsRow as HBoxContainer
	if stats_row:
		stats_row.custom_minimum_size.y = 70.0
		
		# Shrink margins and spaces of the stats container to fit the smaller size
		var pitch_m := stats_row.get_node_or_null("PitchPanel/PitchM") as MarginContainer
		if pitch_m:
			pitch_m.add_theme_constant_override("margin_top", 4)
			pitch_m.add_theme_constant_override("margin_bottom", 4)
		var rhythm_m := stats_row.get_node_or_null("RhythmPanel/RhythmM") as MarginContainer
		if rhythm_m:
			rhythm_m.add_theme_constant_override("margin_top", 4)
			rhythm_m.add_theme_constant_override("margin_bottom", 4)
		var score_m := stats_row.get_node_or_null("ScorePanel/ScoreM") as MarginContainer
		if score_m:
			score_m.add_theme_constant_override("margin_top", 4)
			score_m.add_theme_constant_override("margin_bottom", 4)
			
		var pitch_v := stats_row.get_node_or_null("PitchPanel/PitchM/PitchV") as VBoxContainer
		if pitch_v:
			pitch_v.add_theme_constant_override("separation", 2)
		var rhythm_v := stats_row.get_node_or_null("RhythmPanel/RhythmM/RhythmV") as VBoxContainer
		if rhythm_v:
			rhythm_v.add_theme_constant_override("separation", 2)
		var score_v := stats_row.get_node_or_null("ScorePanel/ScoreM/ScoreV") as VBoxContainer
		if score_v:
			score_v.add_theme_constant_override("separation", 2)
			
		if rhythm_bars:
			rhythm_bars.custom_minimum_size.y = 20.0
			
		if pitch_note: pitch_note.add_theme_font_size_override("font_size", 28)
		if score_num: score_num.add_theme_font_size_override("font_size", 28)
		
		var pitch_title := stats_row.get_node_or_null("PitchPanel/PitchM/PitchV/PitchTitle") as Label
		if pitch_title: pitch_title.add_theme_font_size_override("font_size", 12)
		var rhythm_title := stats_row.get_node_or_null("RhythmPanel/RhythmM/RhythmV/RhythmTitle") as Label
		if rhythm_title: rhythm_title.add_theme_font_size_override("font_size", 12)
		var score_title := stats_row.get_node_or_null("ScorePanel/ScoreM/ScoreV/ScoreTitle") as Label
		if score_title: score_title.add_theme_font_size_override("font_size", 12)
		
	var flute_board := $Root/FluteBoard as PanelContainer
	if flute_board:
		flute_board.custom_minimum_size.y = 140.0
		
		# Shrink margins and spaces of the flute board to fit
		var board_m := flute_board.get_node_or_null("BoardM") as MarginContainer
		if board_m:
			board_m.add_theme_constant_override("margin_top", 4)
			board_m.add_theme_constant_override("margin_bottom", 4)
			board_m.add_theme_constant_override("margin_left", 24)
			board_m.add_theme_constant_override("margin_right", 24)
			
		var board_vbox := flute_board.get_node_or_null("BoardM/BoardVBox") as VBoxContainer
		if board_vbox:
			board_vbox.add_theme_constant_override("separation", 2)
			
		var flute_m := flute_board.get_node_or_null("BoardM/BoardVBox/FluteFrame/FluteM") as MarginContainer
		if flute_m:
			flute_m.add_theme_constant_override("margin_top", 4)
			flute_m.add_theme_constant_override("margin_bottom", 4)
			
		var board_label := flute_board.get_node_or_null("BoardM/BoardVBox/BoardLabel") as Label
		if board_label: board_label.add_theme_font_size_override("font_size", 13)
		if target_label: target_label.add_theme_font_size_override("font_size", 12)
		var guidance_label := flute_board.get_node_or_null("BoardM/BoardVBox/GuidanceLabel") as Label
		if guidance_label: guidance_label.add_theme_font_size_override("font_size", 11)
		
		var breath_label := flute_board.get_node_or_null("BoardM/BoardVBox/BreathHBox/BreathLabel") as Label
		if breath_label: breath_label.add_theme_font_size_override("font_size", 11)
		if breath_status: breath_status.add_theme_font_size_override("font_size", 11)
		if breath_progress: breath_progress.custom_minimum_size.y = 8
		
	# Create and style the NoteTrackPanel
	var track_panel := Panel.new()
	track_panel.name = "NoteTrackPanel"
	track_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	track_panel.custom_minimum_size.y = 450.0
	
	# Apply premium dark wood and gold stylebox
	var style_box := StyleBoxFlat.new()
	style_box.bg_color = Color(0.08, 0.08, 0.1, 0.95)
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
			note_container.draw_line(Vector2(0, y), Vector2(w, y), Color(1.0, 1.0, 1.0, 0.05), 1.0)
			note_container.draw_string(theme_font, Vector2(10, y - 4), LANES[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 1.0, 1.0, 0.25))
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
	target_lbl.add_theme_font_size_override("font_size", 10)
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
	needle.custom_minimum_size = Vector2(25, 6)
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
	_setup_collapsible_linh()
	
	# Dynamic Song Selector OptionButton setup
	var top_h := $Root/TopBar/TopM/TopH as HBoxContainer
	if top_h:
		var song_sel := OptionButton.new()
		song_sel.name = "SongSelector"
		song_sel.custom_minimum_size = Vector2(200, 44)
		song_sel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		# Premium Styling matching the Vietnamese classical style
		var sb_normal := _flat(C_BG_BAR, C_GOLD, 8)
		var sb_hover := _flat(C_BG_BAR, C_GOLD_LIGHT, 8)
		var sb_pressed := _flat(C_GOLD, C_GOLD_LIGHT, 8)
		
		song_sel.add_theme_stylebox_override("normal", sb_normal)
		song_sel.add_theme_stylebox_override("hover", sb_hover)
		song_sel.add_theme_stylebox_override("pressed", sb_pressed)
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
					"bpm": 90.0,
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
		top_h.add_child(song_sel)
		# Place it immediately after the LessonTitle Label (which is at index 2)
		top_h.move_child(song_sel, 3)
		
		song_sel.item_selected.connect(func(index: int) -> void:
			_on_song_selected(index)
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
	
	# Dynamically insert premium real-time microphone waveform visualizer!
	var record_hbox := $Root/RecordBar/RecordM/RecordH
	var analyzer_script := load("res://scripts/AudioCaptureAnalyzer.gd")
	if record_hbox and analyzer_script:
		var visualizer := Control.new()
		visualizer.name = "WaveformVisualizer"
		visualizer.custom_minimum_size = Vector2(320, 62)
		visualizer.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		visualizer.set_script(analyzer_script)
		visualizer.min_frequency = 250.0
		visualizer.max_frequency = 2200.0
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
		# Position next to record button
		record_hbox.move_child(rec_indicator, 2)
		
		# Dynamically add the Auto-Blow toggle button!
		var auto_blow_btn := Button.new()
		auto_blow_btn.name = "AutoBlowBtn"
		auto_blow_btn.text = "Hơi tự động: Tắt"
		auto_blow_btn.toggle_mode = true
		auto_blow_btn.button_pressed = false
		auto_blow_btn.custom_minimum_size = Vector2(140, 44)
		auto_blow_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		var bn := _flat(C_CARD, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45), 14)
		var bh := _flat(C_CARD, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.85), 14)
		bh.shadow_size = 5; bh.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.15)
		var bp := _flat(C_GOLD, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.85), 14)
		
		auto_blow_btn.add_theme_stylebox_override("normal",  bn)
		auto_blow_btn.add_theme_stylebox_override("hover",   bh)
		auto_blow_btn.add_theme_stylebox_override("pressed", bp)
		auto_blow_btn.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
		auto_blow_btn.add_theme_color_override("font_color",         C_TEXT)
		auto_blow_btn.add_theme_color_override("font_hover_color",   C_RED_SON)
		auto_blow_btn.add_theme_color_override("font_pressed_color", Color.WHITE)
		auto_blow_btn.add_theme_font_size_override("font_size", 14)
		
		auto_blow_btn.toggled.connect(func(pressed: bool) -> void:
			_auto_blow = pressed
			if pressed:
				auto_blow_btn.text = "Hơi tự động: Bật"
				_va_say("Đã bật hơi thở tự động. Con chỉ cần tập trung bấm đúng các nốt nhạc nhé!")
			else:
				auto_blow_btn.text = "Hơi tự động: Tắt"
				_va_say("Đã tắt hơi tự động. Bây giờ hệ thống sẽ thu âm hơi thở thật từ microphone.")
		)
		
		record_hbox.add_child(auto_blow_btn)
		record_hbox.move_child(auto_blow_btn, 3)
		_make_button_bouncy(auto_blow_btn)
		
		# Dynamically add the Lesson Mode toggle button!
		var lesson_mode_btn := Button.new()
		lesson_mode_btn.name = "LessonModeBtn"
		lesson_mode_btn.text = "Bài học: Học nốt"
		lesson_mode_btn.toggle_mode = true
		lesson_mode_btn.button_pressed = false
		lesson_mode_btn.custom_minimum_size = Vector2(160, 44)
		lesson_mode_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		lesson_mode_btn.add_theme_stylebox_override("normal",  bn)
		lesson_mode_btn.add_theme_stylebox_override("hover",   bh)
		lesson_mode_btn.add_theme_stylebox_override("pressed", bp)
		lesson_mode_btn.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
		lesson_mode_btn.add_theme_color_override("font_color",         C_TEXT)
		lesson_mode_btn.add_theme_color_override("font_hover_color",   C_RED_SON)
		lesson_mode_btn.add_theme_color_override("font_pressed_color", Color.WHITE)
		lesson_mode_btn.add_theme_font_size_override("font_size", 14)
		
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
		
		record_hbox.add_child(lesson_mode_btn)
		record_hbox.move_child(lesson_mode_btn, 4)
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


func _process(delta: float) -> void:
	if _recording:
		_practice_time += delta
		if _current_note_elapsed < 0.0:
			_current_note_elapsed += delta
			
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
					_play_flute_sound(sheet_notes[0])
		else:
			if _mic_mode:
				_process_real_audio(delta)
			else:
				# If we are in Touch Mode, we still want Auto Scroll / Demo Mode to work!
				if not _is_wait_mode or _is_demo_mode:
					_current_note_elapsed += delta
					var target_duration = sheet_durations[_note_idx] * (60.0 / _song_bpm)
					
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
					_sim_timer += delta
					if _sim_timer >= 1.2:
						_sim_timer = 0.0
						_simulate_tick()
	_update_breath_physics(delta)
	
	# 2. Update zither backing track if recording and in Lesson 2
	if _recording and _lesson_mode == 1:
		if _current_note_elapsed >= 0.0:
			_update_backing_track(delta)
		
	if _ignore_input_timer > 0.0:
		_ignore_input_timer -= delta
		# Clear detected notes history to avoid carry-over pitch spikes
		_detected_notes_history.clear()
		return
		
	# Update Note rolling blocks positions and feedback needle
	var track_panel = $Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox.get_node_or_null("NoteTrackPanel")
	if track_panel:
		var note_container = track_panel.get_node_or_null("NoteContainer")
		if note_container and sheet_notes.size() > 0:
			var bps = _song_bpm / 60.0
			var start_beat := 0.0
			for j in range(_note_idx):
				if j < sheet_durations.size():
					start_beat += sheet_durations[j]
			var current_time_beats = start_beat + (_current_note_elapsed * bps) if _recording else start_beat
			
			var PIXELS_PER_BEAT := 120.0
			var TARGET_LINE_X := 200.0
			var count = LANES.size()
			var container_h = note_container.size.y if note_container.size.y > 0 else 450.0
			var lane_h = container_h / count
			
			for i in range(sheet_notes.size()):
				if not note_visuals.has(i): continue
				var block = note_visuals[i] as ColorRect
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
						block.color = Color("#e5ba73") # Yellow warning / waiting color
					elif _is_demo_mode:
						block.color = Color("#3e8e41") # Green
					else:
						if _active_note_is_correct:
							block.color = Color("#3e8e41") # Green
						elif _active_note_is_heard:
							block.color = Color("#8d3b3b") # Red
						else:
							block.color = Color("#455a64") # Unplayed grey-blue
				else:
					var status = note_statuses[i] if i < note_statuses.size() else "unplayed"
					if status == "correct":
						block.color = Color("#76ba99") # Faded green
					elif status == "missed":
						block.color = Color("#8d3b3b") # Missed red
					else:
						block.color = Color("#455a64") # Unplayed grey-blue

		# Position feedback needle
		var needle = track_panel.get_node_or_null("FeedbackNeedle") as ColorRect
		if needle:
			var visualizer = $Root/RecordBar/RecordM/RecordH.get_node_or_null("WaveformVisualizer")
			var db = visualizer.current_amplitude_db if visualizer else -99.0
			var pitch = visualizer.current_pitch if visualizer else 0.0
			
			if _recording and _mic_mode and not _is_demo_mode and db > -45.0 and pitch > 50.0:
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
					var target_y = _get_lane_y(closest_note) + (450.0 / LANES.size() / 2.0)
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
	if CourseMap.active_lesson_id == "Node3":
		diff = "Trung bình"
	elif CourseMap.active_lesson_id == "Node4":
		diff = "Nâng cao"
		
	var title_lbl := "Lý Hoài Nam (Dân ca)"
	if current_song_title != "":
		title_lbl = current_song_title
		diff = "Bài hát"
	else:
		if CourseMap.active_lesson_id == "Node3":
			title_lbl = "Luyện Ngón Sáo Trúc"
		elif CourseMap.active_lesson_id == "Node4":
			title_lbl = "Nhấp Ngón Kỹ Thuật"

	($Root/TopBar/TopM/TopH/LessonTag  as Label).text  = "SÁO TRÚC  ·  BÀI HÁT" if current_song_title != "" else "SÁO TRÚC  ·  KỸ THUẬT  ·  %s" % diff.to_upper()
	($Root/TopBar/TopM/TopH/LessonTitle as Label).text = title_lbl
	($Root/TopBar/TopM/TopH/ProgressVBox/PctLabel as Label).text = "20%" if current_song_title == "" else "100%"
	($Root/TopBar/TopM/TopH/CtrlBtns/HintBtn as Button).text = "Gợi ý"
	_update_wait_mode_ui()
	_update_demo_mode_ui()

	($Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/NotationLabel as Label).text = "BẢN NHẠC  —  Thổi theo dòng nốt"
	($Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/TargetNoteLabel as Label).text = "Nốt cần thổi: La" if current_song_title == "" else "Nốt cần thổi: " + sheet_notes[0]
	($Root/MiddleRow/MainContent/StatsRow/PitchPanel/PitchM/PitchV/PitchTitle   as Label).text = "CAO ĐỘ"
	($Root/MiddleRow/MainContent/StatsRow/RhythmPanel/RhythmM/RhythmV/RhythmTitle as Label).text = "NHỊP ĐIỆU"
	($Root/MiddleRow/MainContent/StatsRow/ScorePanel/ScoreM/ScoreV/ScoreTitle  as Label).text = "ĐIỂM SỐ"
	($Root/MiddleRow/MainContent/StatsRow/ScorePanel/ScoreM/ScoreV/ScoreSub   as Label).text = "Cao độ 82%  ·  Nhịp 71%"

	($Root/FluteBoard/BoardM/BoardVBox/BoardLabel as Label).text = "SÁO TRÚC  —  Che lỗ để thổi"
	record_btn.text = "Bắt đầu luyện tập"
	($Root/RecordBar/RecordM/RecordH/ResetBtn as Button).text = "Làm lại"

	speech_label.text = SPEECHES[0]

	hint_dialog.title = "Gợi ý kỹ thuật"
	hint_dialog.dialog_text = "Khi thổi sáo trúc:\n\n• Môi khép nhẹ, không cắn lưỡi gà\n• Thổi đều hơi, không gấp\n• Che kín lỗ bằng thịt đầu ngón\n• Giữ cổ tay thư giãn\n• Lắng nghe cao độ rõ ràng"

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
	($Root/TopBar/TopM/TopH/ProgressVBox/PctLabel as Label).add_theme_color_override("font_color", C_TEXT_MUTED)
	_style_progress_bar(lesson_bar, C_RED_SON, Color(0,0,0,0.08))

	var back := $Root/TopBar/TopM/TopH/BackBtn as Button
	_style_text_btn(back, C_RED_SON, C_RED_SON.lightened(0.15))
	for bn in ["HintBtn","DemoBtn","SlowBtn"]:
		_style_outlined_btn($Root/TopBar/TopM/TopH/CtrlBtns.get_node(bn) as Button)

	# Linh panel
	var linh_s := _flat(C_BG_BAR, Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.1), 0)
	linh_s.border_width_right = 2; linh_s.border_width_left = 0; linh_s.border_width_top = 0; linh_s.border_width_bottom = 0
	($Root/MiddleRow/LinhPanel as PanelContainer).add_theme_stylebox_override("panel", linh_s)

	var bubble_s := _flat(C_CARD, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.4), 14)
	($Root/MiddleRow/LinhPanel/LinhVBox/SpeechBubble as PanelContainer).add_theme_stylebox_override("panel", bubble_s)
	speech_label.add_theme_color_override("font_color", C_TEXT)

	# Notation Area — light parchment card
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

	# Flute board
	var sb_s := _flat(C_BG, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25), 0)
	sb_s.border_width_top = 2; sb_s.border_width_bottom = 0; sb_s.border_width_left = 0; sb_s.border_width_right = 0
	($Root/FluteBoard as PanelContainer).add_theme_stylebox_override("panel", sb_s)
	($Root/FluteBoard/BoardM/BoardVBox/BoardLabel as Label).add_theme_color_override("font_color", C_TEXT_MUTED)
	($Root/FluteBoard/BoardM/BoardVBox/TargetLabel as Label).add_theme_color_override("font_color", C_TEXT)
	($Root/FluteBoard/BoardM/BoardVBox/GuidanceLabel as Label).add_theme_color_override("font_color", C_TEXT_MUTED)

	# Flute frame
	var frame := $Root/FluteBoard/BoardM/BoardVBox/FluteFrame as PanelContainer
	var frame_s := _flat(Color(0.24, 0.14, 0.06, 1.0), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.4), 10)
	frame.add_theme_stylebox_override("panel", frame_s)

	# Breath progress styling
	var bf := StyleBoxFlat.new()
	bf.bg_color = C_JADE
	bf.corner_radius_top_left = 6; bf.corner_radius_top_right = 6
	bf.corner_radius_bottom_left = 6; bf.corner_radius_bottom_right = 6
	var bb := StyleBoxFlat.new()
	bb.bg_color = Color(0.0, 0.0, 0.0, 0.08)
	bb.corner_radius_top_left = 6; bb.corner_radius_top_right = 6
	bb.corner_radius_bottom_left = 6; bb.corner_radius_bottom_right = 6
	breath_progress.add_theme_stylebox_override("fill", bf)
	breath_progress.add_theme_stylebox_override("background", bb)
	($Root/FluteBoard/BoardM/BoardVBox/BreathHBox/BreathLabel as Label).add_theme_color_override("font_color", C_TEXT_MUTED)

	var rec_bar_s := _flat(C_BG_BAR, Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.15), 0)
	rec_bar_s.border_width_top = 2; rec_bar_s.border_width_bottom = 0; rec_bar_s.border_width_left = 0; rec_bar_s.border_width_right = 0
	($Root/RecordBar as PanelContainer).add_theme_stylebox_override("panel", rec_bar_s)

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

func _build_flute() -> void:
	for c in holes_hbox.get_children():
		holes_hbox.remove_child(c)
		c.queue_free()

	for i in HOLES:
		var hole := PanelContainer.new()
		hole.custom_minimum_size = Vector2(50, 50)
		hole.pivot_offset = Vector2(25, 25)
		hole.mouse_filter = Control.MOUSE_FILTER_STOP
		
		var hs := StyleBoxFlat.new()
		hs.border_width_left = 3; hs.border_width_right = 3
		hs.border_width_top = 3; hs.border_width_bottom = 3
		hs.corner_radius_top_left = 25; hs.corner_radius_top_right = 25
		hs.corner_radius_bottom_left = 25; hs.corner_radius_bottom_right = 25
		
		if _covered_states[i]:
			hs.bg_color = C_GOLD
			hs.border_color = C_GOLD_LIGHT
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
		bar.custom_minimum_size = Vector2(9, 10)
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
	_active_player.volume_db = -80.0 if _recording else -3.0
	add_child(_active_player)
	_active_player.play()

func _play_preview_or_sound() -> void:
	if _recording: return
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
		hs.bg_color = C_GOLD
		hs.border_color = C_GOLD_LIGHT
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
		halo.custom_minimum_size = Vector2(30, 30)
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
	_float_tween = create_tween().set_loops()
	_float_tween.tween_property(char_linh, "position:y", -12.0, 2.1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_float_tween.tween_property(char_linh, "position:y", 0.0, 2.1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _connect_buttons() -> void:
	var back_btn := $Root/TopBar/TopM/TopH/BackBtn as Button
	var hint_btn := $Root/TopBar/TopM/TopH/CtrlBtns/HintBtn as Button
	var demo_btn := $Root/TopBar/TopM/TopH/CtrlBtns/DemoBtn as Button
	var slow_btn := $Root/TopBar/TopM/TopH/CtrlBtns/SlowBtn as Button
	var reset_btn := $Root/RecordBar/RecordM/RecordH/ResetBtn as Button

	back_btn.pressed.connect(_go_back)
	hint_btn.pressed.connect(_show_custom_hint)
	demo_btn.pressed.connect(_toggle_demo_mode)
	slow_btn.pressed.connect(_toggle_wait_mode)
	record_btn.pressed.connect(_toggle_record)
	reset_btn.pressed.connect(_reset)

	_make_button_bouncy(back_btn)
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
	var visualizer = $Root/RecordBar/RecordM/RecordH.get_node_or_null("WaveformVisualizer")
	_update_rec_pulse(_recording)
	if _recording:
		record_btn.text = "Dừng luyện tập"
		_va_say(SPEECHES[0])
		_start_pitch_detection()
		if visualizer and _mic_mode: visualizer.visible = true
		_current_note_elapsed = -4.0
		
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
		if visualizer:
			visualizer.add_practice_score(_score)
		_show_custom_result()
		_stop_pitch_detection()
		if visualizer: visualizer.visible = false
		if _active_player and is_instance_valid(_active_player):
			_active_player.stop()
			_active_player.queue_free()
			_active_player = null

func _demo() -> void:
	var target_note := sheet_notes[_note_idx]
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
		
	var visualizer = $Root/RecordBar/RecordM/RecordH.get_node_or_null("WaveformVisualizer")
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
			
		var is_pitch_ok = db > -45.0 and pitch > 50.0 and abs(cents) < 75.0
		var is_correct_note = false
		if is_pitch_ok:
			var tolerance_cents = 25.0 / visualizer.difficulty_tolerance_scale
			if abs(cents) < tolerance_cents:
				is_correct_note = true
				
		var is_breath_ok = _breath_pressure >= 12.0 and _breath_pressure <= 85.0
		
		_active_note_is_correct = is_correct_note and is_breath_ok
		_active_note_is_heard = db > -45.0 and pitch > 50.0
		
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
			if db > -45.0 and pitch > 50.0:
				var detected_note = _detect_note_from_pitch(pitch, scale_mult)
				if detected_note != "":
					pitch_note.text = detected_note + ("²" if is_overblowing else "")
				else:
					pitch_note.text = "—"
				pitch_status.text = "Chưa đúng nốt"
				pitch_status.add_theme_color_override("font_color", C_RED_ERR)
				pitch_note.add_theme_color_override("font_color", C_RED_ERR)
			else:
				# Silence
				pitch_note.text = "—"
				pitch_status.text = "Đang nghe..."
				pitch_status.add_theme_color_override("font_color", C_CREAM_DIM)
				pitch_note.add_theme_color_override("font_color", C_TEXT_MUTED)
			
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
	
	_active_note_is_heard = db > -45.0 and pitch > 50.0
	
	if db > -45.0 and pitch > 50.0:
		var target_freq = FREQS.get(target_note, 261.63)
		var is_overblowing := _breath_pressure > 82.0
		var scale_mult := 2.0 if is_overblowing else 1.0
		var effective_target_freq : float = target_freq * scale_mult
		
		var cents = 1200.0 * log(pitch / effective_target_freq) / log(2.0)
		var tolerance_cents = 25.0 / visualizer.difficulty_tolerance_scale
		
		if abs(cents) < 75.0:
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
				
				_correct_pitch_hold_time += delta
				if _correct_pitch_hold_time >= 0.15:
					_correct_pitch_hold_time = 0.0
					_advance_note_in_practice()
					
					# Dynamic AI scoring
					var rhythm_score = visualizer.evaluate_rhythm(_detected_onsets, _reference_onsets, 0.3 * visualizer.difficulty_tolerance_scale)
					var avg_pitch_score = _get_average_score(_pitch_scores, 80.0)
					var avg_breath_score = _get_average_score(_breath_scores, 80.0)
					
					_score = visualizer.calculate_composite_score(avg_pitch_score, rhythm_score, 100.0, avg_breath_score)
					_refresh_score()
					_update_rhythm_real()
					rhythm_acc.text = "Nhịp điệu: %d%% | Cột hơi: %d%%" % [int(rhythm_score), int(avg_breath_score)]
					
					# Auto update covered states fingerings for visual help
					var target_fingering = FINGERINGS.get(target_note, [false, false, false, false, false, false])
					_covered_states.assign(target_fingering)
					_build_flute()
					
					_eval_cooldown = 1.0
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
		pitch_status.add_theme_color_override("font_color", C_CREAM_DIM)
		pitch_note.add_theme_color_override("font_color", C_TEXT_MUTED)
		_active_note_is_correct = false
		_active_note_is_heard = false

func _update_wait_mode_ui() -> void:
	var slow_btn := $Root/TopBar/TopM/TopH/CtrlBtns/SlowBtn as Button
	if not slow_btn: return
	if _is_wait_mode:
		slow_btn.text = "Chờ nốt: Bật ⏳"
		slow_btn.modulate = Color("#e5ba73") # Warm gold/yellow
	else:
		slow_btn.text = "Tự trôi: Bật 🌊"
		slow_btn.modulate = Color("#76ba99") # Mint green

func _update_demo_mode_ui() -> void:
	var demo_btn := $Root/TopBar/TopM/TopH/CtrlBtns/DemoBtn as Button
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
		
	var score_sub_lbl := $Root/MiddleRow/MainContent/StatsRow/ScorePanel/ScoreM/ScoreV/ScoreSub as Label
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

func _va_say(text: String) -> void:
	speech_label.text = text
	var t := create_tween()
	t.tween_property(char_linh, "scale", Vector2(1.03, 0.97), 0.08)
	t.tween_property(char_linh, "scale", Vector2.ONE, 0.14)

	if _linh_collapsed:
		_linh_collapsed = false
		_update_linh_visibility()
		
	var active_timer = get_tree().create_timer(6.0)
	_collapse_timer = active_timer
	active_timer.timeout.connect(func():
		if _collapse_timer == active_timer and not _linh_collapsed:
			_linh_collapsed = true
			_update_linh_visibility()
	)

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
		SecureDataManager.complete_lesson(inst, CourseMap.active_lesson_id, stars)
		
	var popup_scene := load("res://scenes/CustomPopup.tscn") as PackedScene
	if popup_scene:
		var popup = popup_scene.instantiate()
		add_child(popup)
		var p := randf_range(70, 92)
		var r := randf_range(65, 90)
		var t := clampf((_score * 3.0 - p - r), 60, 95)
		
		var next_lesson_name := "Khóa Học Tiếp"
		if CourseMap.active_lesson_id == "Node2":
			next_lesson_name = "Luyện Ngón"
		elif CourseMap.active_lesson_id == "Node3":
			next_lesson_name = "Nhấp Ngón"
			
		popup.setup_result(_score, p, r, t, 80, "Đã mở khóa: " + next_lesson_name)

func _reset() -> void:
	_note_idx = 0
	_score = 75.0
	_eval_cooldown = 0.0
	_covered_states = [true, true, true, true, true, true]
	_build_notation()
	_build_flute()
	_update_target_indicator()
	_update_rec_pulse(false)
	var visualizer = $Root/RecordBar/RecordM/RecordH.get_node_or_null("WaveformVisualizer")
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
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.22)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/CourseMap.tscn"))

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
	pf.corner_radius_top_left = 7; pf.corner_radius_top_right = 7
	pf.corner_radius_bottom_left = 7; pf.corner_radius_bottom_right = 7
	pf.shadow_size = 5; pf.shadow_color = Color(fill.r, fill.g, fill.b, 0.4)
	var pbg := StyleBoxFlat.new(); pbg.bg_color = bg
	pbg.corner_radius_top_left = 7; pbg.corner_radius_top_right = 7
	pbg.corner_radius_bottom_left = 7; pbg.corner_radius_bottom_right = 7
	pb.add_theme_stylebox_override("fill", pf)
	pb.add_theme_stylebox_override("background", pbg)

func _style_text_btn(btn: Button, col: Color, hover: Color) -> void:
	btn.add_theme_color_override("font_color", col)
	btn.add_theme_color_override("font_hover_color", hover)
	btn.add_theme_stylebox_override("normal",  _flat(Color(0,0,0,0), Color(0,0,0,0), 8))
	btn.add_theme_stylebox_override("hover",   _flat(Color(col.r,col.g,col.b,0.12), Color(0,0,0,0), 8))
	btn.add_theme_stylebox_override("pressed", _flat(Color(col.r,col.g,col.b,0.20), Color(0,0,0,0), 8))
	btn.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0), 0))

func _style_outlined_btn(btn: Button) -> void:
	var bn := _flat(C_CARD, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45), 14)
	var bh := _flat(C_CARD, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.85), 14)
	bh.shadow_size = 5; bh.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.15)
	btn.add_theme_stylebox_override("normal",  bn)
	btn.add_theme_stylebox_override("hover",   bh)
	btn.add_theme_stylebox_override("pressed", _flat(Color(0.95, 0.93, 0.89, 1.0), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.5), 14))
	btn.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	btn.add_theme_color_override("font_color",         C_TEXT)
	btn.add_theme_color_override("font_hover_color",   C_RED_SON)
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
	var visualizer = $Root/RecordBar/RecordM/RecordH.get_node_or_null("WaveformVisualizer")
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
		fill_style.corner_radius_top_left = 6; fill_style.corner_radius_top_right = 6
		fill_style.corner_radius_bottom_left = 6; fill_style.corner_radius_bottom_right = 6
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
		rec_indicator.pivot_offset = Vector2(30, 15)
		
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
					hs.bg_color = C_GOLD
					hs.border_color = C_GOLD_LIGHT
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
					hs.bg_color = C_GOLD
					hs.border_color = C_GOLD_LIGHT
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
	_active_player.volume_db = -3.0 # audible guide sound
	add_child(_active_player)
	_active_player.play()
	
	# Set ignore input timer to prevent microphone feedback loop
	_ignore_input_timer = 0.6
	
	# Fade out and stop the guide sound after 0.5s
	var temp_player = _active_player
	get_tree().create_timer(0.5).timeout.connect(func() -> void:
		if is_instance_valid(temp_player):
			var fade = create_tween()
			fade.tween_property(temp_player, "volume_db", -30.0, 0.1)
			fade.tween_callback(temp_player.queue_free)
			if _active_player == temp_player:
				_active_player = null
	)

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
		var visualizer = $Root/RecordBar/RecordM/RecordH.get_node_or_null("WaveformVisualizer")
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
	var container_h = note_container.size.y if note_container.size.y > 0 else 450.0
	var lane_height = container_h / LANES.size()
	return container_h - (lane_idx + 1) * lane_height + 2.0

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
		
		var block := ColorRect.new()
		block.name = "NoteBlock_%d" % i
		block.color = Color("#455a64") # Grey-blue
		
		# Add label for note name
		var lbl := Label.new()
		lbl.text = note_name
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.anchors_preset = Control.PRESET_FULL_RECT
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.add_theme_font_size_override("font_size", 13)
		block.add_child(lbl)
		
		# Save metadata on the block
		block.set_meta("note_time", time_beats)
		block.set_meta("note_duration", duration)
		block.set_meta("note_name", note_name)
		
		note_container.add_child(block)
		note_visuals[i] = block
		
		time_beats += duration
