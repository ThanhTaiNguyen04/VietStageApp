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
var _current_note_hit := false
var _demo_note_plucked := false
var _layout_btn: Button = null

enum BoardOrientation { LANDSCAPE, PORTRAIT }
var _current_orientation: BoardOrientation = BoardOrientation.LANDSCAPE
# AI Analysis tracking variables
var _practice_time := 0.0
var _detected_onsets : PackedFloat32Array = PackedFloat32Array()
var _reference_onsets : PackedFloat32Array = PackedFloat32Array()
var _pitch_scores : Array[float] = []
var _tone_scores : Array[float] = []

var _string_streams: Array[AudioStreamWAV] = []
var _rec_tween   : Tween
var _header_tween : Tween
var _detected_notes_history: Array[String] = []
const HISTORY_SIZE := 8
var _teacher_tip_timer := 0.0

var _eval_cooldown := 0.0
var _linh_collapsed := true
var linh_mini_btn : Button
var _collapse_timer : SceneTreeTimer = null

const NOTES_VN : Array[String] = [
	"Sol1", "La1", "Đô2", "Rê2", "Mi2",
	"Sol2", "La2", "Đô3", "Rê3", "Mi3",
	"Sol3", "La3", "Đô4", "Rê4", "Mi4",
	"Sol4", "La4" 
]

const LANES : Array[int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]

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
		"title": "Lý Cây Đa",
		"bpm": 85.0,
		"sheet": [
			"Đô3", "Rê3", "Rê3", "Đô3", "Rê3", "Mi3", "Rê3", "Đô3", "Rê3", "Mi3", "Rê3", "Đô3", "Rê3", "Đô3", "Rê3",
			"Rê3", "Đô3", "Rê3", "Mi3", "Rê3", "Đô3", "Rê3", "Đô3", "Rê3", "Đô3", "Rê3", "Mi3", "Rê3", "Đô3", "Rê3", "Đô3",
			"Mi3", "Mi3", "Rê3", "Rê3", "Đô3", "Mi3", "Rê3", "Đô3", "Sol2", "Sol2", "Đô3",
			"Đô3", "Sol2", "Sol2", "Đô3", "Sol2", "Đô3", "La2", "Sol2", "Fa2", "La2", "Sol2", "La2", "Đô3", "La2",
			"Sol2", "La2", "Sol2", "Sol2", "La2", "Sol2", "La2", "Đô3", "La2", "Sol2", "La2", "Sol2"
		],
		"durations": [
			0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0,
			0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0,
			0.5, 0.5, 0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 1.0,
			0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0,
			0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.5
		]
	},
	{
		"title": "Lý Cây Bông",
		"bpm": 80.0,
		"sheet": [
			"La2", "Sol2", "La2", "La2", "Sol2", "La2", "Đô3", "Mi3", "Sol3", "Mi3", "Sol3", "Sol3", "Mi3",
			"La2", "Sol2", "Mi3", "Sol2", "La2", "La2", "La2", "Sol2", "Mi3", "Sol3", "Mi3", "Sol3",
			"La2", "Sol2", "Mi3", "Sol2", "La2", "La2", "Rê3", "Mi3", "Sol3", "Mi3", "Rê3", "Đô3", "La2",
			"Rê3", "Mi3", "Rê3", "Rê3", "Rê3", "Rê3", "Rê3", "Mi3", "Sol3",
			"Mi3", "Rê3", "Đô3", "La2", "La2", "La2", "Đô3", "Rê3", "Mi3", "Rê3"
		],
		"durations": [
			0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0,
			0.5, 0.5, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0,
			0.5, 0.5, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0,
			0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0,
			0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.5
		]
	},
	{
		"title": "Giấc Mơ Trưa",
		"bpm": 90.0,
		"sheet": ["Rest", "Sol1", "La1", "Đô3", "Rê3", "Mi3", "Sol2", "La2", "Rê4", "Rê4", "Rest", "La2", "Sol2", "Mi3", "Rê3", "Đô3", "La1", "Sol1", "Đô3", "Đô3", "Rest", "Đô3", "Rê3", "Mi3", "Sol2", "La2", "Sol2", "Mi3", "Rê3", "Rê3", "Rest", "Đô3", "Rê3", "Mi3", "Sol2", "La2", "Đô4", "La2", "Sol2", "Sol2", "Rest", "La2", "Sol2", "Mi3", "Rê3", "Mi3", "Rê3", "Đô3", "Đô3", "Rest", "Mi3", "Rê3", "Đô3", "Rê3", "Sol2", "Rê3", "Sol2", "Đô4", "Đô4", "Đô4", "Rest", "Mi3", "Rê3", "Sol2", "Rê3", "Rê3", "Rê3", "Rest", "Mi3", "Rê3", "Đô3", "Rê3", "Sol2", "La2", "La2", "La2", "Rest", "Sol2", "La2", "Mi3", "Rê3", "Đô3", "Rê3", "Sol2", "Sol2", "Rest", "Rê4", "Đô4", "La2", "Đô4", "Sol2", "Sol2", "Rest", "La2", "Sol2", "Mi3", "Sol2", "Rê3", "Rê3", "Rest", "Mi3", "Rê3", "Đô3", "Rê3", "Sol1", "Sol1", "Rest", "Đô3", "Rê3", "Mi3", "Sol2", "La2", "Sol2", "La2", "La2", "Rest", "Sol2", "La2", "Mi3", "Rê3", "Đô3", "Rê3", "Đô3", "Đô3", "Rest", "Đô3", "Rê3", "Mi3", "Sol2", "La2", "Sol2", "La2", "Đô4", "La2", "Sol2", "Mi3", "Sol2", "La2", "La2", "Rest", "Đô3", "Rê3", "Mi3", "Sol2", "La2", "Sol2", "La2", "Đô4", "Rê4", "Đô4", "La2", "Đô4", "Sol2", "Sol2", "Rest", "La2", "Sol2", "Mi3", "Sol2", "Rê3", "Mi3", "Đô3", "Đô3", "Rest", "La1", "Sol1", "Đô3", "Rê3", "Mi3", "Sol2", "La2", "Sol2", "Mi3", "Rê3", "Đô3", "Đô3", "Rest", "Đô3", "Rê3", "Mi3", "Sol2", "La2", "Sol2", "La2", "Đô4", "La2", "Sol2", "Mi3", "Sol2", "La2", "La2", "Rest", "Đô3", "Rê3", "Mi3", "Sol2", "La2", "Sol2", "La2", "Đô4", "Rê4", "Đô4", "La2", "Đô4", "Sol2", "Sol2", "Rest", "La2", "Sol2", "Mi3", "Sol2", "Rê3", "Mi3", "Đô3", "Đô3", "Rest", "La1", "Sol1", "Đô3", "Rê3", "Mi3", "Sol2", "La2", "Sol2", "Mi3", "Rê3", "Đô3", "Đô3", "Rest"],
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
	},
	{
		"title": "Sứ Thanh Hoa",
		"bpm": 80.0,
		"sheet": [
			"Rê3", "Đô3", "La2", "Đô3", "Đô3", "La2", "Đô3", "Đô3", "La2", "Đô3", "La2", "Sol2",
			"Rê3", "Đô3", "La2", "Đô3", "Đô3", "La2", "Đô3", "Đô3", "Mi3", "Rê3", "Đô3", "Sol2", "La2", "Mi3",
			"Mi3", "Rê3", "Mi3", "Rê3", "Mi3", "Sol3", "Mi3", "Rest", "Mi3", "Mi3", "Rê3",
			"Đô3", "Mi3", "Rê3", "Rê3", "Đô3", "La2", "Đô3", "Đô3", "La2", "Đô3",
			"La2", "Sol2", "Sol2", "La2", "Mi3", "Sol3", "Sol3", "Mi3", "Sol3", "Sol3", "Mi3", "Rê3", "Đô3", "Đô3",
			"Rê3", "Đô3", "Rê3", "Mi3", "Rê3", "Rê3", "Đô3", "Rê3", "Đô3", "Rê3", "Đô3", "Đô3", "La2", "Đô3", "Rê3", "Rê3"
		],
		"durations": [
			0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5, 2.0,
			0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5,
			0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 1.0, 0.5, 0.5, 2.0,
			0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 3.0,
			1.0, 1.0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5,
			0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5
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

	# Hide NotationArea entirely and collapse MiddleRow to make Dan Tranh zither full screen
	var notation_area := $Root/MiddleRow/MainContent/NotationArea as PanelContainer
	if notation_area:
		notation_area.visible = false
	var middle_row := $Root/MiddleRow as HBoxContainer
	if middle_row:
		middle_row.custom_minimum_size.y = 0
		
	# Ẩn StatsRow để tối ưu không gian hiển thị trên mobile (Giống giao diện Sáo Trúc)
	var stats_row = $Root/MiddleRow/MainContent/StatsRow
	if stats_row:
		stats_row.visible = false


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
			note_container.draw_string(theme_font, Vector2(10, y - 5), NOTES_VN[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(C_TEXT_MUTED.r, C_TEXT_MUTED.g, C_TEXT_MUTED.b, 0.45))
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
	_setup_collapsible_linh()
	
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
		
		# Căn giữa các nút theo giao diện Sáo Trúc
		record_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		# Convert Bắt đầu luyện tập (RecordBtn) to FAB
		if record_btn:
			record_btn.get_parent().remove_child(record_btn)
			add_child(record_btn)
			record_btn.name = "RecordFAB"
			record_btn.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
			record_btn.anchor_left = 0.5; record_btn.anchor_right = 0.5
			record_btn.anchor_top = 1.0; record_btn.anchor_bottom = 1.0
			record_btn.offset_left = -35; record_btn.offset_right = 35
			record_btn.offset_top = -90; record_btn.offset_bottom = -20
			record_btn.text = ""
			
			var tex = load("res://assets/textures/lucide/play.svg")
			if tex:
				record_btn.icon = tex
				record_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
				if "vertical_icon_alignment" in record_btn:
					record_btn.set("vertical_icon_alignment", 1) # CENTER
				record_btn.expand_icon = true

			var btn_s := StyleBoxFlat.new()
			btn_s.bg_color = Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.6)
			btn_s.corner_radius_top_left = 35; btn_s.corner_radius_top_right = 35
			btn_s.corner_radius_bottom_left = 35; btn_s.corner_radius_bottom_right = 35
			var btn_h := btn_s.duplicate()
			btn_h.bg_color = C_JADE
			record_btn.add_theme_stylebox_override("normal", btn_s)
			record_btn.add_theme_stylebox_override("hover", btn_h)
			record_btn.add_theme_stylebox_override("pressed", btn_s)
			record_btn.add_theme_stylebox_override("focus", _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
			_make_button_bouncy(record_btn)

		var record_bar = $Root.get_node_or_null("RecordBar")
		if record_bar: record_bar.visible = false
		
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.35)

	char_linh.mouse_filter = Control.MOUSE_FILTER_STOP
	char_linh.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			var chat = AIChatPopup.new()
			add_child(chat)
			chat.open_chat("dan_tranh")
	)
	
	# Add Layout toggle button
	var ctrl_btns = $SettingsPanel/SettingsM/SettingsVBox/CtrlBtns as Control
	if ctrl_btns:
		# Remove HintBtn (Gợi ý kĩ thuật)
		var hint_btn = ctrl_btns.get_node_or_null("HintBtn")
		if hint_btn:
			hint_btn.queue_free()
			
		# 1. Luyện tập (RecordBtn)
		if record_btn:
			record_btn.get_parent().remove_child(record_btn)
			ctrl_btns.add_child(record_btn)
			ctrl_btns.move_child(record_btn, 0)
			record_btn.name = "RecordSidebarBtn"
			record_btn.text = "\nLuyện tập"
			record_btn.custom_minimum_size = Vector2(200, 70)
			_style_sidebar_btn(record_btn)
			_set_sidebar_icon(record_btn, "graduation-cap")
			_make_button_bouncy(record_btn)
			
		# 1.5. Kết thúc luyện tập
		var stop_record_btn = Button.new()
		stop_record_btn.name = "StopRecordBtn"
		stop_record_btn.text = "\nKết thúc luyện tập"
		stop_record_btn.custom_minimum_size = Vector2(200, 70)
		ctrl_btns.add_child(stop_record_btn)
		ctrl_btns.move_child(stop_record_btn, 1)
		_style_sidebar_btn(stop_record_btn)
		_set_sidebar_icon(stop_record_btn, "pause")
		_make_button_bouncy(stop_record_btn)
		stop_record_btn.pressed.connect(func():
			if _recording: _toggle_record()
		)
			
		# 2. Làm lại (ResetBtn)
		var reset_sidebar_btn = Button.new()
		reset_sidebar_btn.name = "ResetSidebarBtn"
		reset_sidebar_btn.text = "\nLàm lại"
		reset_sidebar_btn.custom_minimum_size = Vector2(200, 70)
		ctrl_btns.add_child(reset_sidebar_btn)
		ctrl_btns.move_child(reset_sidebar_btn, 2)
		_style_sidebar_btn(reset_sidebar_btn)
		_set_sidebar_icon(reset_sidebar_btn, "rotate-cw")
		_make_button_bouncy(reset_sidebar_btn)
		reset_sidebar_btn.pressed.connect(_reset)
		
		# 3. Chờ nốt (SlowBtn in .tscn)
		var slow_btn = ctrl_btns.get_node_or_null("SlowBtn")
		if slow_btn:
			ctrl_btns.move_child(slow_btn, 3)
			
		# 4. Micro (MicBtn)
		var mic_btn = Button.new()
		mic_btn.name = "MicBtn"
		mic_btn.text = "\nMicro: Bật" if _mic_mode else "\nMicro: Tắt"
		mic_btn.custom_minimum_size = Vector2(200, 70)
		ctrl_btns.add_child(mic_btn)
		ctrl_btns.move_child(mic_btn, 4)
		_style_sidebar_btn(mic_btn)
		_set_sidebar_icon(mic_btn, "mic" if _mic_mode else "mic-off")
		_make_button_bouncy(mic_btn)
		mic_btn.pressed.connect(func():
			_mic_mode = not _mic_mode
			mic_btn.text = "\nMicro: Bật" if _mic_mode else "\nMicro: Tắt"
			_set_sidebar_icon(mic_btn, "mic" if _mic_mode else "mic-off")
		)
		
		# 5. Nghe mẫu (DemoBtn in .tscn)
		var demo_btn = ctrl_btns.get_node_or_null("DemoBtn")
		if demo_btn:
			ctrl_btns.move_child(demo_btn, 5)
			
		# 6. Đàn ngang / Đàn dọc (LayoutBtn)
		var layout_btn = Button.new()
		layout_btn.name = "LayoutBtn"
		layout_btn.text = "\nĐàn dọc" if _current_orientation == BoardOrientation.PORTRAIT else "\nĐàn ngang"
		layout_btn.custom_minimum_size = Vector2(200, 70)
		ctrl_btns.add_child(layout_btn)
		ctrl_btns.move_child(layout_btn, 6)
		_style_sidebar_btn(layout_btn)
		_set_sidebar_icon(layout_btn, "rotate-cw")
		_make_button_bouncy(layout_btn)
		_layout_btn = layout_btn
		layout_btn.pressed.connect(toggle_orientation)
			
		# Thêm spacer để đẩy nút Quay lại xuống dưới cùng
		ctrl_btns.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var spacer = Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		ctrl_btns.add_child(spacer)
			
		# 7. Quay lại (BackBtnSidebar)
		var back_btn_sidebar = Button.new()
		back_btn_sidebar.name = "BackBtnSidebar"
		back_btn_sidebar.text = "\nQuay lại"
		back_btn_sidebar.custom_minimum_size = Vector2(200, 70)
		ctrl_btns.add_child(back_btn_sidebar)
		# NOTE: No move_child called, so it stays at the very bottom!
		_style_sidebar_btn(back_btn_sidebar)
		_set_sidebar_icon(back_btn_sidebar, "arrow-left")
		_make_button_bouncy(back_btn_sidebar)
		back_btn_sidebar.pressed.connect(_go_back)
		
		# Finally, resize any other pre-existing buttons in ctrl_btns to the new mobile-friendly size
		for child in ctrl_btns.get_children():
			if child is Button:
				child.custom_minimum_size = Vector2(200, 70)
				# Ensure text format is stacked (add \n if not present)
				var clean_text = child.text.replace("\n", "").strip_edges()
				child.text = "\n" + clean_text

	
	if current_song_title == "":
		_show_introduction_overlay()
		
	_update_demo_mode_ui()
	_update_wait_mode_ui()
		
	# Dynamic Song Selector OptionButton setup
	var settings_vbox := $SettingsPanel/SettingsM/SettingsVBox as VBoxContainer
	if settings_vbox:
		var song_sel := OptionButton.new()
		song_sel.name = "SongSelector"
		song_sel.custom_minimum_size = Vector2(220, 44)
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
		settings_vbox.move_child(song_sel, 1) # Put SongSelector right at the top (after title if any, or at index 1)
		
		song_sel.item_selected.connect(func(index: int) -> void:
			_on_song_selected(index)
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
			_current_note_elapsed += delta
			var target_duration = sheet_durations[_note_idx] * (60.0 / _song_bpm)
			
			if not _demo_note_plucked:
				_demo_note_plucked = true
				var target_note = sheet_notes[_note_idx]
				var target_idx = NOTES_VN.find(target_note)
				if target_idx != -1:
					if _board:
						_board.pluck(target_idx)
						
			if _current_note_elapsed >= target_duration:
				_current_note_elapsed = 0.0
				_demo_note_plucked = false
				_note_idx = (_note_idx + 1) % sheet_notes.size()
				_build_notation()
				_update_target_indicator()
		elif not _is_wait_mode:
			_current_note_elapsed += delta
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
				_current_note_elapsed += delta
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

	($Root/TopBar/TopM/TopH/LessonTitle as Label).text = title_lbl
	($SettingsPanel/SettingsM/SettingsVBox/ProgressVBox/PctLabel as Label).text = "60%" if current_song_title == "" else "100%"
	var hint_btn_node = $SettingsPanel/SettingsM/SettingsVBox/CtrlBtns.get_node_or_null("HintBtn") as Button
	if hint_btn_node:
		hint_btn_node.text = "Gợi ý"

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
		
	# Set Root panel background color to C_BG to match curriculum
	var root_s := StyleBoxFlat.new()
	root_s.bg_color = C_BG
	var root_node = get_node_or_null("Root") as PanelContainer
	if root_node:
		root_node.add_theme_stylebox_override("panel", root_s)

	var prog_vbox = $SettingsPanel/SettingsM/SettingsVBox/ProgressVBox
	if prog_vbox:
		prog_vbox.visible = false

	var dots_box = $SettingsPanel/SettingsM/SettingsVBox/DotsHBox
	if dots_box: dots_box.visible = false

	var back := $Root/TopBar/TopM/TopH/BackBtn as Button
	if back: back.visible = false # We moved it to sidebar
	
	var top_bar = $Root.get_node_or_null("TopBar")
	if top_bar: top_bar.visible = false

	# Transparent background + Top shadow gradient for StringsBoard
	var strings_board = $Root.get_node_or_null("StringsBoard")
	if strings_board:
		var sb_style = StyleBoxEmpty.new()
		if strings_board is PanelContainer:
			strings_board.add_theme_stylebox_override("panel", sb_style)
			
		var shadow_rect = TextureRect.new()
		shadow_rect.name = "TopShadow"
		
		var shadow_grad = Gradient.new()
		shadow_grad.add_point(0.0, Color(0, 0, 0, 0.7)) # Black 70%
		shadow_grad.add_point(1.0, Color(0, 0, 0, 0.0)) # Transparent
		var shadow_grad_tex = GradientTexture2D.new()
		shadow_grad_tex.gradient = shadow_grad
		shadow_grad_tex.fill_from = Vector2(0, 0)
		shadow_grad_tex.fill_to = Vector2(0, 1)
		
		shadow_rect.texture = shadow_grad_tex
		shadow_rect.set_anchors_preset(Control.PRESET_TOP_WIDE)
		shadow_rect.anchor_bottom = 0.0
		shadow_rect.offset_bottom = 120 # Height of the gradient shadow
		shadow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		strings_board.add_child(shadow_rect)
		strings_board.move_child(shadow_rect, 0)
		
	# Bỏ phần khung xám hai bên đàn và phía dưới đàn (remove margins from BoardM)
	var board_m = $Root/StringsBoard.get_node_or_null("BoardM") as MarginContainer
	if board_m:
		board_m.add_theme_constant_override("margin_left", 0)
		board_m.add_theme_constant_override("margin_right", 0)
		board_m.add_theme_constant_override("margin_top", 0)
		board_m.add_theme_constant_override("margin_bottom", 0)

	var board_vbox = $Root/StringsBoard/BoardM/BoardVBox
	var board_label = board_vbox.get_node_or_null("BoardLabel")
	var menu_btn := $Root/TopBar/TopM/TopH/MenuBtn as Button
	
	if menu_btn and board_label:
		menu_btn.get_parent().remove_child(menu_btn)
		
		# Remove the top gray area labels
		if board_label: board_label.visible = false
		var target_label = board_vbox.get_node_or_null("TargetLabel") as Label
		if target_label: target_label.visible = false
		
		# Keep the sidebar toggle in the screen overlay instead of inside the
		# instrument. The board changes its logical size and drawing transform in
		# portrait mode, which could move/clip child controls outside the viewport.
		add_child(menu_btn)
		menu_btn.name = "MenuFAB"
		menu_btn.text = ""
		menu_btn.custom_minimum_size = Vector2(40, 40)
		menu_btn.size = Vector2(40, 40)
		menu_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
		menu_btn.position = Vector2(32.0, 12.0)
		menu_btn.z_index = 90
		
		var tex = load("res://assets/textures/lucide/menu.svg")
		if tex:
			menu_btn.icon = tex
			menu_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			if "vertical_icon_alignment" in menu_btn:
				menu_btn.set("vertical_icon_alignment", 1) # CENTER
			menu_btn.expand_icon = true
			menu_btn.add_theme_color_override("icon_normal_color", C_TEXT)
			menu_btn.add_theme_color_override("icon_hover_color", C_JADE)
			menu_btn.add_theme_color_override("icon_pressed_color", C_JADE)
		
		var fab_s := StyleBoxFlat.new()
		fab_s.bg_color = Color(0.95, 0.93, 0.87, 0.55)
		fab_s.corner_radius_top_left = 12; fab_s.corner_radius_top_right = 12
		fab_s.corner_radius_bottom_left = 12; fab_s.corner_radius_bottom_right = 12
		var fab_h := fab_s.duplicate() as StyleBoxFlat
		fab_h.bg_color = Color(0.95, 0.93, 0.87, 0.85)
		menu_btn.add_theme_stylebox_override("normal", fab_s)
		menu_btn.add_theme_stylebox_override("hover", fab_h)
		menu_btn.add_theme_stylebox_override("pressed", fab_s)
		menu_btn.add_theme_stylebox_override("focus", _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
		menu_btn.modulate = Color(1, 1, 1, 0.8)
		menu_btn.mouse_entered.connect(func(): menu_btn.modulate = Color.WHITE)
		menu_btn.mouse_exited.connect(func(): menu_btn.modulate = Color(1, 1, 1, 0.8))
		
	var settings_panel := $SettingsPanel as PanelContainer
	if settings_panel:
		settings_panel.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
		settings_panel.custom_minimum_size.x = 240
		settings_panel.size.x = 240
		settings_panel.position.x = -260
		settings_panel.visible = true
		settings_panel.z_index = 100
		
		var sp_style := StyleBoxFlat.new()
		sp_style.bg_color = Color(0.93, 0.91, 0.87, 0.6) # Glassmorphism opacity
		sp_style.border_color = Color(0.8, 0.78, 0.73, 0.8)
		sp_style.border_width_right = 2
		settings_panel.add_theme_stylebox_override("panel", sp_style)
		
		# Add Blur Behind
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
		var blur_rect = ColorRect.new()
		blur_rect.material = blur_mat
		blur_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		blur_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		blur_rect.show_behind_parent = true
		settings_panel.add_child(blur_rect)
		settings_panel.move_child(blur_rect, 0)
		
		var menu_title := $SettingsPanel/SettingsM/SettingsVBox/MenuTitle as Label
		if menu_title:
			menu_title.add_theme_color_override("font_color", Color(0.15, 0.25, 0.15))

	var ctrl_btns = $SettingsPanel/SettingsM/SettingsVBox/CtrlBtns
	if ctrl_btns:
		if "columns" in ctrl_btns:
			ctrl_btns.columns = 1
			
	for bn in ["HintBtn","DemoBtn","SlowBtn"]:
		var btn = $SettingsPanel/SettingsM/SettingsVBox/CtrlBtns.get_node_or_null(bn) as Button
		if btn:
			_style_sidebar_btn(btn)
			
	var hint_btn = $SettingsPanel/SettingsM/SettingsVBox/CtrlBtns.get_node_or_null("HintBtn") as Button
	if hint_btn:
		hint_btn.text = "\nLuyện tập"
		_set_sidebar_icon(hint_btn, "graduation-cap")

	# Linh panel
	var linh_s := _flat(C_BG_BAR, Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.1), 0)
	linh_s.border_width_right = 2; linh_s.border_width_left = 0; linh_s.border_width_top = 0; linh_s.border_width_bottom = 0
	($Root/MiddleRow/LinhPanel as PanelContainer).add_theme_stylebox_override("panel", linh_s)

	var bubble_s := _flat(C_CARD, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.4), 14)
	($Root/MiddleRow/LinhPanel/LinhVBox/SpeechBubble as PanelContainer).add_theme_stylebox_override("panel", bubble_s)
	speech_label.add_theme_color_override("font_color", C_TEXT)

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

	# Removed the solid brown background here to allow the transparent/TopShadow effect.

	# Setup RecordBtn as a small FAB floating on the left side (next to La 1 string)
	if record_btn:
		var parent = record_btn.get_parent()
		if parent: parent.remove_child(record_btn)
		if _board: _board.add_child(record_btn)
		
		record_btn.name = "RecordFAB"
		record_btn.text = ""
		record_btn.custom_minimum_size = Vector2(40, 40)
		record_btn.size = Vector2(40, 40)
		record_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
		# Dynamic position will be set in update_fabs 
		
		var play_tex = load("res://assets/textures/lucide/play.svg")
		if play_tex:
			record_btn.icon = play_tex
			record_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			if "vertical_icon_alignment" in record_btn:
				record_btn.set("vertical_icon_alignment", 1) # CENTER
			record_btn.expand_icon = true
			record_btn.add_theme_color_override("icon_normal_color", Color(0.98, 0.97, 0.95))
			record_btn.add_theme_color_override("icon_hover_color", Color.WHITE)
			record_btn.add_theme_color_override("icon_pressed_color", Color.WHITE)
		
		# Same glassmorphic style as MenuFAB
		var fab_s := StyleBoxFlat.new()
		fab_s.bg_color = Color(1, 1, 1, 0.1)
		fab_s.corner_radius_top_left = 12; fab_s.corner_radius_top_right = 12
		fab_s.corner_radius_bottom_left = 12; fab_s.corner_radius_bottom_right = 12
		var fab_h := fab_s.duplicate() as StyleBoxFlat
		fab_h.bg_color = Color(1, 1, 1, 0.3)
		record_btn.add_theme_stylebox_override("normal", fab_s)
		record_btn.add_theme_stylebox_override("hover", fab_h)
		record_btn.add_theme_stylebox_override("pressed", fab_s)
		record_btn.add_theme_stylebox_override("focus", _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
		record_btn.modulate = Color(1, 1, 1, 0.8)
		record_btn.mouse_entered.connect(func(): record_btn.modulate = Color.WHITE)
		record_btn.mouse_exited.connect(func(): record_btn.modulate = Color(1, 1, 1, 0.8))

	# Hide RecordBar completely
	var record_bar = $Root.get_node_or_null("RecordBar")
	if record_bar: record_bar.visible = false
	
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
	var lane_idx = NOTES_VN.find(clean_note)
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
	# Đàn tranh 16 dây - tuning theo hệ ngũ cung Sol - La - Đô - Rê - Mi
	var base_freqs = [
		196.00, # Sol (G3)
		220.00, # La (A3)
		261.63, # Đô (C4)
		293.66, # Rê (D4)
		329.63  # Mi (E4)
	]
	var octave = idx / 5
	var note_in_octave = idx % 5
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
	_show_header()
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
	_show_header()
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
	_float_tween = create_tween().set_loops()
	_float_tween.tween_property(char_linh, "position:y", -12.0, 2.1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_float_tween.tween_property(char_linh, "position:y", 0.0, 2.1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

# ─── Connections ──────────────────────────────────────────────────────────────
func _connect_buttons() -> void:
	var back_btn := $Root/TopBar/TopM/TopH/BackBtn as Button
	var menu_btn := find_child("MenuFAB", true, false) as Button
	if not menu_btn: menu_btn = $Root/TopBar/TopM/TopH/MenuBtn as Button
	var hint_btn := $SettingsPanel/SettingsM/SettingsVBox/CtrlBtns/HintBtn as Button
	var demo_btn := $SettingsPanel/SettingsM/SettingsVBox/CtrlBtns/DemoBtn as Button
	var slow_btn := $SettingsPanel/SettingsM/SettingsVBox/CtrlBtns/SlowBtn as Button
	var reset_btn := $Root/RecordBar/RecordM/RecordH/ResetBtn as Button

	back_btn.pressed.connect(_go_back)
	if menu_btn:
		menu_btn.pressed.connect(func() -> void:
			var target_x = 0.0 if $SettingsPanel.position.x < -10.0 else -260.0
			var t = create_tween()
			t.tween_property($SettingsPanel, "position:x", target_x, 0.4).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		)
	if demo_btn: demo_btn.pressed.connect(_toggle_demo_mode)
	if slow_btn: slow_btn.pressed.connect(_toggle_wait_mode)
	if record_btn: 
		for conn in record_btn.get_signal_connection_list("pressed"):
			record_btn.pressed.disconnect(conn["callable"])
		record_btn.pressed.connect(func():
			if not _recording: 
				_toggle_record()
			else:
				# Đang luyện tập, đóng sidebar để tiếp tục chơi đàn
				create_tween().tween_property($SettingsPanel, "position:x", -260.0, 0.35).set_ease(Tween.EASE_OUT)
		)
	if reset_btn: reset_btn.pressed.connect(_reset)

	if back_btn: _make_button_bouncy(back_btn)
	if menu_btn: _make_button_bouncy(menu_btn)
	if demo_btn: _make_button_bouncy(demo_btn)
	if slow_btn: _make_button_bouncy(slow_btn)
	_make_button_bouncy(record_btn)
	_make_button_bouncy(reset_btn)

func _toggle_record() -> void:
	_recording = not _recording
	var visualizer = $Root/RecordBar/RecordM/RecordH.get_node_or_null("WaveformVisualizer")
	_update_rec_pulse(_recording)
	if _recording:
		# Auto-hide sidebar when starting practice
		create_tween().tween_property($SettingsPanel, "position:x", -260.0, 0.35).set_ease(Tween.EASE_OUT)
		
		_hide_header_delayed()
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
		_show_header()
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
		# Automatically start playing if not already playing
		if not _recording:
			_toggle_record()
	else:
		_is_wait_mode = true
		_update_wait_mode_ui()
		_va_say("Đã tắt Nghe mẫu. Con hãy tự mình luyện tập nhé!")
		if _recording:
			_toggle_record()
	_update_demo_mode_ui()

func _update_demo_mode_ui() -> void:
	var demo_btn := $SettingsPanel/SettingsM/SettingsVBox/CtrlBtns/DemoBtn as Button
	if not demo_btn: return
	if _is_demo_mode:
		demo_btn.text = "\nNghe mẫu: BẬT"
		demo_btn.modulate = Color("#76ba99") # Mint green
		_set_sidebar_icon(demo_btn, "volume-2")
	else:
		demo_btn.text = "\nNghe mẫu: TẮT"
		demo_btn.modulate = Color.WHITE
		_set_sidebar_icon(demo_btn, "volume-x")

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
		slow_btn.text = "\nChờ nốt: Bật"
		slow_btn.modulate = Color("#e5ba73") # Warm gold
		_set_sidebar_icon(slow_btn, "hourglass")
	else:
		slow_btn.text = "\nTự trôi: Bật"
		slow_btn.modulate = Color("#76ba99") # Mint green
		_set_sidebar_icon(slow_btn, "hourglass")

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

func _va_say(text: String) -> void:
	speech_label.text = text
	var t := create_tween()
	t.tween_property(char_linh, "scale", Vector2(1.03, 0.97), 0.08)
	t.tween_property(char_linh, "scale", Vector2.ONE, 0.14)

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
	t.tween_callback(func() -> void:
		var target := "res://scenes/LessonDanTranh.tscn" if SecureDataManager.active_lesson_id.begins_with("dan_tranh_level_") else "res://scenes/MainMenu.tscn"
		get_tree().change_scene_to_file(target))

func reset_layout_transforms() -> void:
	if not _board: return
	
	# Clear all applied transforms/offsets to ensure a clean slate
	_board.rotation = 0.0
	_board.scale = Vector2.ONE
	_board.position = Vector2.ZERO
	_board.pivot_offset = Vector2.ZERO
	_board.custom_minimum_size = Vector2.ZERO
	_board.is_portrait_mode = false
	_board.queue_redraw()
	
	# Sync Container logic to recalibrate its child controls
	var parent_vbox = _board.get_parent()
	if parent_vbox and parent_vbox is Container:
		parent_vbox.queue_sort()
		
func toggle_orientation() -> void:
	if not _board: return
	
	# Always reset to original baseline before applying new transforms
	reset_layout_transforms()
	
	if _current_orientation == BoardOrientation.LANDSCAPE:
		# Switch to PORTRAIT
		_current_orientation = BoardOrientation.PORTRAIT
		var vp_size = get_viewport_rect().size
		
		# Set dimensions so it perfectly fills the portrait screen
		# By swapping custom_minimum_size, the VBoxContainer gives it portrait proportions
		_board.custom_minimum_size = Vector2(vp_size.x, vp_size.y * 1.2)
		_board.size = _board.custom_minimum_size
		_board.is_portrait_mode = true
		_board.queue_redraw()
		
		if _layout_btn:
			_layout_btn.text = "\nĐàn dọc"
	else:
		# Switch to LANDSCAPE
		_current_orientation = BoardOrientation.LANDSCAPE
		if _layout_btn:
			_layout_btn.text = "\nĐàn ngang"

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
			"text": "Cây đàn tranh của chúng ta có 16 dây chính, được lên dây theo thang năm âm (pentatonic) truyền thống gồm: Sol, La, Đô, Rê, Mi.",
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
			"text": "Dây số 3 là nốt Đô. Dưới đây là âm nốt Đô.",
			"voice": "Dây số ba là nốt Đô. Dưới đây là âm nốt Đô.",
			"highlighted_string": 2,
			"note_to_play": "Đô"
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
	
	# Load premium fonts
	var f_title := load("res://assets/fonts/Lora-Bold.ttf") as Font
	var f_body := load("res://assets/fonts/BeVietnamPro-Regular.ttf") as Font
	var f_body_bold := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	
	# 2. Main Margin Container
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	_intro_overlay.add_child(margin)
	
	# 3. Main HBox to split Left (Mai) and Right (Zither + Navigation)
	var main_hbox := HBoxContainer.new()
	main_hbox.add_theme_constant_override("separation", 50)
	main_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(main_hbox)
	
	# ─── LEFT PANEL: Teacher Mai & Speech Bubble ───
	var left_vbox := VBoxContainer.new()
	left_vbox.custom_minimum_size = Vector2(350, 0)
	left_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	left_vbox.add_theme_constant_override("separation", 20)
	main_hbox.add_child(left_vbox)
	
	# Teacher Portrait
	var portrait := TextureRect.new()
	portrait.texture = load("res://assets/textures/virtual_artist_mai.png")
	portrait.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size = Vector2(240, 360)
	left_vbox.add_child(portrait)
	
	# Speech Bubble Panel Container
	var bubble := PanelContainer.new()
	var bs := StyleBoxFlat.new()
	bs.bg_color = C_BG_BAR
	bs.border_color = C_GOLD
	bs.border_width_left = 2; bs.border_width_right = 2
	bs.border_width_top = 2; bs.border_width_bottom = 2
	bs.corner_radius_top_left = 16; bs.corner_radius_top_right = 16
	bs.corner_radius_bottom_left = 16; bs.corner_radius_bottom_right = 16
	bubble.add_theme_stylebox_override("panel", bs)
	left_vbox.add_child(bubble)
	
	var bubble_margin := MarginContainer.new()
	bubble_margin.add_theme_constant_override("margin_left", 16)
	bubble_margin.add_theme_constant_override("margin_right", 16)
	bubble_margin.add_theme_constant_override("margin_top", 16)
	bubble_margin.add_theme_constant_override("margin_bottom", 16)
	bubble.add_child(bubble_margin)
	
	_intro_text_lbl = Label.new()
	_intro_text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_intro_text_lbl.custom_minimum_size = Vector2(300, 100)
	if f_body: _intro_text_lbl.add_theme_font_override("font", f_body)
	_intro_text_lbl.add_theme_font_size_override("font_size", 14)
	_intro_text_lbl.add_theme_color_override("font_color", C_TEXT)
	bubble_margin.add_child(_intro_text_lbl)
	
	# ─── RIGHT PANEL: Zither & Navigation ───
	var right_vbox := VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	right_vbox.add_theme_constant_override("separation", 36)
	main_hbox.add_child(right_vbox)
	
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
	
	# Zither Display Container
	var zither_area := Control.new()
	zither_area.custom_minimum_size = Vector2(760, 200)
	zither_area.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	right_vbox.add_child(zither_area)
	
	# Zither Body
	var theme_font := get_theme_font("font")
	_intro_zither_body = Control.new()
	_intro_zither_body.custom_minimum_size = Vector2(680, 180)
	_intro_zither_body.size = Vector2(680, 180)
	_intro_zither_body.position = Vector2(40, 10)
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
	
	# Navigation HBox Container
	var btn_hbox := HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 20)
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	right_vbox.add_child(btn_hbox)

	# Listen Button (Nghe Thử)
	_intro_listen_btn = Button.new()
	_intro_listen_btn.text = "🔊 NGHE THỬ"
	_intro_listen_btn.custom_minimum_size = Vector2(180, 48)
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
	btn_hbox.add_child(_intro_listen_btn)
	_make_button_bouncy(_intro_listen_btn)

	# Next / Understood Button
	_intro_next_btn = Button.new()
	_intro_next_btn.text = "ĐÃ HIỂU ➔"
	_intro_next_btn.custom_minimum_size = Vector2(220, 48)
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
	btn_hbox.add_child(_intro_next_btn)
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

func _style_sidebar_btn(btn: Button) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	var sb_hover := StyleBoxFlat.new()
	sb_hover.bg_color = Color(0.1, 0.35, 0.2, 0.08) # Màu xanh rêu nhạt khi hover
	
	btn.custom_minimum_size.y = 60
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("focus", _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	btn.add_theme_color_override("font_color", Color(0.25, 0.22, 0.20)) # Màu xám nâu tối
	btn.add_theme_color_override("font_hover_color", Color(0.1, 0.35, 0.2)) # Xanh rêu
	
	# Định dạng icon màu đen/tối tương tự giáo trình
	btn.add_theme_color_override("icon_normal_color", Color(0.1, 0.1, 0.1))
	btn.add_theme_color_override("icon_hover_color", Color(0.1, 0.35, 0.2))
	btn.add_theme_color_override("icon_pressed_color", Color.BLACK)
	
	var f_body := load("res://assets/fonts/BeVietnamPro-Regular.ttf") as Font
	if f_body: btn.add_theme_font_override("font", f_body)
	btn.add_theme_font_size_override("font_size", 16)
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Expand icon to make it slightly larger
	btn.expand_icon = true

func _set_sidebar_icon(btn: Button, icon_name: String) -> void:
	var tex = load("res://assets/textures/lucide/" + icon_name + ".svg")
	if tex:
		btn.icon = tex
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if "vertical_icon_alignment" in btn:
			btn.set("vertical_icon_alignment", 0) # VERTICAL_ALIGNMENT_TOP

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

func _hide_header_delayed() -> void:
	if _header_tween and _header_tween.is_running():
		_header_tween.kill()
	var record_fab = find_child("RecordFAB", true, false)
	if record_fab:
		_header_tween = create_tween().set_parallel(true)
		_header_tween.tween_interval(3.0)
		_header_tween.parallel().tween_property(record_fab, "modulate:a", 0.0, 0.5)
		_header_tween.chain().tween_callback(func(): record_fab.visible = false)

func _show_header() -> void:
	if _header_tween and _header_tween.is_running():
		_header_tween.kill()
	var record_fab = find_child("RecordFAB", true, false)
	if record_fab:
		record_fab.visible = true
		_header_tween = create_tween().set_parallel(true)
		_header_tween.parallel().tween_property(record_fab, "modulate:a", 1.0, 0.2)
