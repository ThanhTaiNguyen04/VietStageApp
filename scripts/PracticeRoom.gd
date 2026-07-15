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

const LEVEL1_LESSON1_ID := "dan_tranh_level_1_bai_1_practice"
const LEVEL1_LESSON2_ID := "dan_tranh_level_1_bai_2_practice"
const LEVEL1_LESSON3_ID := "dan_tranh_level_1_bai_3_practice"
const LEVEL1_LESSON1_NOTES: Array[String] = ["Sol1", "La1", "Đô2", "Rê2", "Mi2"]
const LEVEL1_LESSON1_LABELS: Array[String] = ["Sol", "La", "Đô", "Rê", "Mi"]
const LEVEL1_CONFIGS := {
	LEVEL1_LESSON1_ID: {
		"lesson": 1, "title": "Làm quen 5 nốt cơ bản", "mode": "guided_song", "input": "micro",
		"sheet": ["Sol1", "La1", "Đô2", "Rê2", "Mi2"], "active_strings": [0, 1, 2, 3, 4],
		"instruction": "Nghe câu nhạc chậm. Khi nhạc dừng, hãy gảy lần lượt Sol – La – Đô – Rê – Mi trên đàn thật.",
		"bpm": 56.0, "pass_score": 80.0
	},
	LEVEL1_LESSON2_ID: {
		"lesson": 2, "title": "Điền nốt vào giai điệu", "mode": "guided_song", "input": "micro",
		"sheet": ["Sol1", "La1", "Đô2", "La1", "Sol1", "Rê2", "Mi2", "Rê2", "Đô2", "La1", "Sol1", "Đô2"],
		"instruction": "Nghe giai điệu. Khi nhạc dừng ở vạch vàng, hãy gảy đúng nốt còn thiếu để nhạc phát tiếp.",
		"active_strings": [0, 1, 2, 3, 4], "bpm": 72.0, "pass_score": 80.0
	},
	LEVEL1_LESSON3_ID: {
		"lesson": 3, "title": "Hoàn thiện giai điệu", "mode": "guided_song", "input": "micro",
		"sheet": ["Sol1", "La1", "Đô2", "Rê2", "Mi2", "Rê2", "Đô2", "La1",
			"Sol1", "Đô2", "Mi2", "Rê2", "Đô2", "La1", "Sol1", "La1",
			"Đô2", "Rê2", "Mi2", "Đô2"],
		"instruction": "Hoàn thiện đoạn nhạc dài hơn. Quan sát nốt kế tiếp, nghe nhịp và gảy đúng mỗi khi nhạc dừng.",
		"active_strings": [0, 1, 2, 3, 4], "bpm": 84.0, "pass_score": 80.0
	}
}

var _level1_lesson1_mode := false
var _level1_mode := false
var _level1_config: Dictionary = {}
var _level1_state := "preview"
var _level1_countdown := 0.0
var _level1_round := 0
var _level1_speed := 0.8
var _level1_total_attempts := 0
var _level1_correct_count := 0
var _level1_consecutive_misses := 0
var _level1_timing_scores: Array[float] = []
var _level1_high_errors := 0
var _level1_low_errors := 0
var _level1_early_errors := 0
var _level1_late_errors := 0
var _level1_result_shown := false
var _level1_instruction: Label = null
var _level1_progress_label: Label = null
var _level1_compact_panel: PanelContainer = null
var _level1_speed_buttons: Array[Button] = []
var _level1_completed: Array[bool] = [false, false, false, false, false]
var _level1_note_buttons: Array[Button] = []
var _level1_status_label: Label = null
var _level1_start_button: Button = null
var _level1_pitch_hold := 0.0
var _level1_wait_for_silence := false
var _level1_silence_time := 0.0
const LEVEL1_GUIDED_LEAD_BEATS: float = 1.5
var _level1_waiting_for_note: bool = false
var _level1_backing_timer: float = 0.0
var _level1_backing_step: int = 0
var _level1_backing_players: Array[AudioStreamPlayer] = []

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
	_level1_mode = LEVEL1_CONFIGS.has(SecureDataManager.active_lesson_id)
	_level1_lesson1_mode = false
	if _level1_mode:
		_level1_config = LEVEL1_CONFIGS[SecureDataManager.active_lesson_id].duplicate(true)
		_level1_lesson1_mode = str(_level1_config.get("mode", "")) == "explore"
		current_song_title = str(_level1_config["title"])
		current_song_sheet.clear()
		current_song_sheet.assign(_level1_config["sheet"])
		_song_bpm = float(_level1_config["bpm"])

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
	if not song_found and not _level1_mode:
		_song_bpm = 80.0
	elif _level1_mode:
		_song_bpm = float(_level1_config["bpm"])
		
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
	if not ProjectSettings.get_setting("audio/driver/enable_input") and (not _level1_mode or str(_level1_config.get("input", "micro")) == "micro"):
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

	if _level1_lesson1_mode:
		_setup_level1_lesson1_exercise()
	elif _level1_mode:
		_setup_level1_sequence_exercise()
	if _level1_mode:
		_setup_level1_focus_ui()


func _setup_level1_lesson1_exercise() -> void:
	_note_idx = 0
	_score = 0.0
	_is_wait_mode = true
	_mic_mode = true
	if _board:
		_board.simplify_note_labels = true
		_board.clear_feedback_details()
		_board.set_target(0)

	var song_selector := $SettingsPanel/SettingsM/SettingsVBox.get_node_or_null("SongSelector")
	if song_selector:
		song_selector.visible = false
	for button_name in ["DemoBtn", "SlowBtn"]:
		var sidebar_button := $SettingsPanel/SettingsM/SettingsVBox/CtrlBtns.get_node_or_null(button_name)
		if sidebar_button:
			sidebar_button.visible = false
	if record_btn:
		record_btn.text = "\nBắt đầu nhận diện"

	var panel := PanelContainer.new()
	panel.name = "Level1Lesson1Exercise"
	panel.custom_minimum_size = Vector2(0.0, 150.0)
	panel.add_theme_stylebox_override("panel", _flat(Color("#fffaf0"), Color("#c99a3c"), 16))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)

	var heading := Label.new()
	heading.text = "BÀI 1 · LÀM QUEN 5 NỐT CƠ BẢN"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color", C_JADE)
	heading.add_theme_font_size_override("font_size", 20)
	content.add_child(heading)

	var instruction := Label.new()
	instruction.text = "Bấm từng nốt để nghe mẫu, sau đó gảy nốt tương ứng trên đàn thật. Micro sẽ phân tích cao độ và chỉ cho qua khi nốt đúng."
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction.add_theme_color_override("font_color", C_TEXT_MUTED)
	instruction.add_theme_font_size_override("font_size", 14)
	content.add_child(instruction)

	var notes_row := HBoxContainer.new()
	notes_row.alignment = BoxContainer.ALIGNMENT_CENTER
	notes_row.add_theme_constant_override("separation", 12)
	content.add_child(notes_row)
	_level1_note_buttons.clear()
	for i in LEVEL1_LESSON1_LABELS.size():
		var note_button := Button.new()
		note_button.custom_minimum_size = Vector2(92.0, 42.0)
		note_button.text = LEVEL1_LESSON1_LABELS[i]
		note_button.tooltip_text = "Nghe mẫu nốt %s" % LEVEL1_LESSON1_LABELS[i]
		note_button.pressed.connect(_preview_level1_lesson1_note.bind(i))
		notes_row.add_child(note_button)
		_level1_note_buttons.append(note_button)

	var action_row := HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 16)
	content.add_child(action_row)

	_level1_status_label = Label.new()
	_level1_status_label.custom_minimum_size.x = 520.0
	_level1_status_label.text = "Hãy nghe mẫu 5 nốt, sau đó bấm Bắt đầu nhận diện."
	_level1_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level1_status_label.add_theme_color_override("font_color", C_TEXT)
	_level1_status_label.add_theme_font_size_override("font_size", 15)
	action_row.add_child(_level1_status_label)

	_level1_start_button = Button.new()
	_level1_start_button.custom_minimum_size = Vector2(190.0, 40.0)
	_level1_start_button.text = "Bắt đầu nhận diện"
	_level1_start_button.add_theme_stylebox_override("normal", _flat(C_JADE, C_GOLD, 12))
	_level1_start_button.add_theme_stylebox_override("hover", _flat(C_JADE.lightened(0.08), C_GOLD_LIGHT, 12))
	_level1_start_button.add_theme_color_override("font_color", Color.WHITE)
	_level1_start_button.pressed.connect(_toggle_record)
	action_row.add_child(_level1_start_button)

	$Root.add_child(panel)
	$Root.move_child(panel, 1)
	_update_level1_lesson1_ui()
	_va_say("Hãy nghe và gảy lại lần lượt năm nốt Sol, La, Đô, Rê, Mi trên đàn thật nhé!")

func _preview_level1_lesson1_note(index: int) -> void:
	if index < 0 or index >= LEVEL1_LESSON1_NOTES.size():
		return
	if _board:
		_board.pluck(index)
	_set_level1_status("Đang phát mẫu nốt %s · Hãy ghi nhớ rồi gảy lại trên đàn thật." % LEVEL1_LESSON1_LABELS[index], C_GOLD_TEXT)

func _update_level1_lesson1_ui() -> void:
	for i in _level1_note_buttons.size():
		var button := _level1_note_buttons[i]
		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(12)
		style.set_border_width_all(2)
		if _level1_completed[i]:
			style.bg_color = Color("#27965a")
			style.border_color = Color("#70d99a")
			button.text = "✓ %s" % LEVEL1_LESSON1_LABELS[i]
			button.add_theme_color_override("font_color", Color.WHITE)
		elif i == _note_idx and _note_idx < LEVEL1_LESSON1_NOTES.size():
			style.bg_color = Color("#f5dfaa")
			style.border_color = C_GOLD
			button.text = "▶ %s" % LEVEL1_LESSON1_LABELS[i]
			button.add_theme_color_override("font_color", C_JADE)
		else:
			style.bg_color = Color("#f3eee1")
			style.border_color = Color("#d5c8aa")
			button.text = LEVEL1_LESSON1_LABELS[i]
			button.add_theme_color_override("font_color", C_TEXT_MUTED)
		button.add_theme_stylebox_override("normal", style)
		var hover := style.duplicate() as StyleBoxFlat
		hover.bg_color = hover.bg_color.lightened(0.06)
		button.add_theme_stylebox_override("hover", hover)
	lesson_bar.value = _score
	var progress_label := $SettingsPanel/SettingsM/SettingsVBox/ProgressVBox/PctLabel as Label
	if progress_label:
		progress_label.text = "%d%%" % int(_score)
	if target_label:
		target_label.text = "Nốt cần gảy: %s" % LEVEL1_LESSON1_LABELS[_note_idx] if _note_idx < LEVEL1_LESSON1_LABELS.size() else "Hoàn thành 5 nốt"
	_update_level1_progress()

func _set_level1_status(text: String, color: Color) -> void:
	if _level1_status_label:
		_level1_status_label.text = text
		_level1_status_label.add_theme_color_override("font_color", color)

func _toggle_level1_lesson1_listening() -> void:
	var visualizer = $Root/RecordBar/RecordM/RecordH.get_node_or_null("WaveformVisualizer")
	if _recording:
		_recording = false
		if visualizer:
			visualizer.visible = false
		if _level1_start_button:
			_level1_start_button.text = "Tiếp tục nhận diện"
		if record_btn:
			record_btn.text = "\nTiếp tục nhận diện"
		_set_level1_status("Đã tạm dừng. Bấm Tiếp tục khi bạn sẵn sàng.", C_WARN)
		_set_level1_controls(false)
		return
	if not ProjectSettings.get_setting("audio/driver/enable_input"):
		_set_level1_status("Không thể bắt đầu: ứng dụng chưa được cấp quyền Microphone.", C_RED_ERR)
		return

	_recording = true
	_level1_pitch_hold = 0.0
	_level1_wait_for_silence = false
	if visualizer:
		visualizer.visible = true
	if _level1_start_button:
		_level1_start_button.text = "Tạm dừng"
	if record_btn:
		record_btn.text = "\nTạm dừng"
	create_tween().tween_property($SettingsPanel, "position:x", -260.0, 0.3).set_ease(Tween.EASE_OUT)
	_set_level1_status("Đang nghe · Hãy gảy nốt %s trên đàn thật." % LEVEL1_LESSON1_LABELS[_note_idx], C_JADE)
	if _board:
		_board.set_target(_note_idx)
	_set_level1_controls(true)

func _process_level1_lesson1_audio(delta: float) -> void:
	if _note_idx >= LEVEL1_LESSON1_NOTES.size():
		return
	if not _mic_mode:
		_set_level1_status("Micro đang tắt · Hãy bật Micro trong thanh công cụ.", C_WARN)
		return
	var visualizer = $Root/RecordBar/RecordM/RecordH.get_node_or_null("WaveformVisualizer")
	if not visualizer:
		_set_level1_status("Không tìm thấy bộ phân tích âm thanh.", C_RED_ERR)
		return

	var amplitude_db: float = visualizer.current_amplitude_db
	var pitch: float = visualizer.current_pitch
	if amplitude_db <= -45.0 or pitch <= 50.0:
		_level1_pitch_hold = 0.0
		if _level1_wait_for_silence:
			_level1_silence_time += delta
			if _level1_silence_time >= 0.12:
				_level1_wait_for_silence = false
				_level1_silence_time = 0.0
				if _board:
					_board.set_target(_note_idx)
		_set_level1_status("Đang nghe · Hãy gảy nốt %s trên đàn thật." % LEVEL1_LESSON1_LABELS[_note_idx], C_JADE)
		return
	_level1_silence_time = 0.0
	if _level1_wait_for_silence:
		_set_level1_status("Thả âm vừa gảy, rồi chuẩn bị cho nốt %s." % LEVEL1_LESSON1_LABELS[_note_idx], C_WARN)
		return

	var closest_index := 0
	var closest_cents := INF
	for i in LEVEL1_LESSON1_NOTES.size():
		var frequency := _get_string_frequency(i)
		var cents_distance: float = absf(1200.0 * log(pitch / frequency) / log(2.0))
		if cents_distance < closest_cents:
			closest_cents = cents_distance
			closest_index = i

	var expected_frequency := _get_string_frequency(_note_idx)
	var expected_cents: float = 1200.0 * log(pitch / expected_frequency) / log(2.0)
	pitch_note.text = LEVEL1_LESSON1_LABELS[closest_index]
	if closest_index == _note_idx and absf(expected_cents) <= 35.0:
		if _board:
			_board.set_feedback_detail(_note_idx, "✓ %s" % LEVEL1_LESSON1_LABELS[_note_idx], 0)
		_level1_pitch_hold += delta
		var hold_percent := mini(100, int((_level1_pitch_hold / 0.35) * 100.0))
		_set_level1_status("Đúng nốt %s · Giữ âm ổn định %d%%" % [LEVEL1_LESSON1_LABELS[_note_idx], hold_percent], C_GREEN_OK)
		if _level1_pitch_hold >= 0.35:
			_complete_level1_lesson1_note()
		return

	_level1_pitch_hold = 0.0
	if closest_index == _note_idx:
		var direction := "cao" if expected_cents > 0.0 else "thấp"
		if _board:
			_board.set_feedback_detail(_note_idx, "%s %d¢" % ["↓" if expected_cents > 0.0 else "↑", int(absf(expected_cents))], 2)
		_set_level1_status("Đúng dây nhưng hơi %s (%d cent) · Hãy chỉnh cao độ nốt %s." % [direction, int(absf(expected_cents)), LEVEL1_LESSON1_LABELS[_note_idx]], C_RED_ERR)
	else:
		if _board:
			_board.set_feedback_detail(_note_idx, "✕ %s" % LEVEL1_LESSON1_LABELS[closest_index], 2)
		_set_level1_status("Chưa đúng: nhận diện %s · Nốt cần gảy là %s." % [LEVEL1_LESSON1_LABELS[closest_index], LEVEL1_LESSON1_LABELS[_note_idx]], C_RED_ERR)

func _complete_level1_lesson1_note() -> void:
	var completed_index := _note_idx
	_level1_completed[completed_index] = true
	if _board:
		_board.set_feedback_detail(completed_index, "✓ %s" % LEVEL1_LESSON1_LABELS[completed_index], 1)
	_note_idx += 1
	_score = float(_note_idx) / float(LEVEL1_LESSON1_NOTES.size()) * 100.0
	_refresh_score()
	_update_level1_lesson1_ui()
	_level1_pitch_hold = 0.0
	_level1_wait_for_silence = true

	if _note_idx >= LEVEL1_LESSON1_NOTES.size():
		_finish_level1_lesson1_exercise()
		return
	if _board:
		_board.set_target(_note_idx)
	_set_level1_status("Chính xác nốt %s! Tiếp theo: gảy nốt %s." % [LEVEL1_LESSON1_LABELS[completed_index], LEVEL1_LESSON1_LABELS[_note_idx]], C_GREEN_OK)
	_va_say("Đúng rồi! Tiếp theo con hãy gảy nốt %s." % LEVEL1_LESSON1_LABELS[_note_idx])

func _finish_level1_lesson1_exercise() -> void:
	_recording = false
	var visualizer = $Root/RecordBar/RecordM/RecordH.get_node_or_null("WaveformVisualizer")
	if visualizer:
		visualizer.visible = false
	if _board:
		_board.set_target(-1)
	_set_level1_controls(false)
	if _level1_start_button:
		_level1_start_button.text = "Đã hoàn thành"
		_level1_start_button.disabled = true
	if record_btn:
		record_btn.text = "\nĐã hoàn thành"
		record_btn.disabled = true
	_set_level1_status("Hoàn thành! Bạn đã nhận diện đúng Sol · La · Đô · Rê · Mi.", C_GREEN_OK)
	SecureDataManager.complete_lesson("dan_tranh", LEVEL1_LESSON1_ID, 3)
	_va_say("Xuất sắc! Con đã nhận diện đúng cả năm nốt Sol, La, Đô, Rê và Mi.")

func _reset_level1_lesson1_exercise() -> void:
	_recording = false
	_note_idx = 0
	_score = 0.0
	_level1_pitch_hold = 0.0
	_level1_wait_for_silence = false
	_level1_silence_time = 0.0
	for i in _level1_completed.size():
		_level1_completed[i] = false
	var visualizer = $Root/RecordBar/RecordM/RecordH.get_node_or_null("WaveformVisualizer")
	if visualizer:
		visualizer.visible = false
	if _board:
		_board.clear_feedback_details()
		_board.set_target(0)
	if _level1_start_button:
		_level1_start_button.disabled = false
		_level1_start_button.text = "Bắt đầu nhận diện"
	if record_btn:
		record_btn.disabled = false
		record_btn.text = "\nBắt đầu nhận diện"
	_update_level1_lesson1_ui()
	_set_level1_status("Hãy nghe mẫu 5 nốt, sau đó bấm Bắt đầu nhận diện.", C_TEXT)
	_refresh_score()


func _setup_level1_focus_ui() -> void:
	var active: Array[int] = []
	for value in _level1_config.get("active_strings", []):
		active.append(int(value))
	if _board:
		_board.simplify_note_labels = true
		_board.set_active_strings(active)
		var focus_mode: String = str(_level1_config.get("mode", ""))
		var uses_right_playhead: bool = focus_mode == "catch" or focus_mode == "guided_song"
		_board.set_playhead_ratio(0.82 if uses_right_playhead else 0.25)
		_board.set_note_travel_direction(uses_right_playhead)
		_board.audio_enabled = focus_mode != "guided_song"
		_board.note_cues = _level1_config.get("cues", [])
	var board_label := $Root/StringsBoard/BoardM/BoardVBox/BoardLabel as Label
	if str(_level1_config.get("mode", "")) == "guided_song":
		board_label.text = "ĐIỀN NỐT VÀO GIAI ĐIỆU · %d nốt · BPM %d · Nhạc dừng ở vạch vàng" % [sheet_notes.size(), int(_level1_config["bpm"])]
	else:
		board_label.text = "ĐÀN TRANH 17 DÂY · Vàng: nốt cần gảy · Xanh: đúng · Cam/đỏ: cần chỉnh"
	var controls := $SettingsPanel/SettingsM/SettingsVBox/CtrlBtns as VBoxContainer
	for button_name in ["StopRecordBtn", "SlowBtn", "DemoBtn"]:
		var extra_button := controls.get_node_or_null(button_name)
		if extra_button:
			extra_button.visible = false
	var mic_button := controls.get_node_or_null("MicBtn")
	if mic_button:
		mic_button.visible = str(_level1_config.get("input", "")) == "micro"
	var dots := $SettingsPanel/SettingsM/SettingsVBox/DotsHBox as HBoxContainer
	if dots:
		dots.visible = false
	var sidebar_progress := $SettingsPanel/SettingsM/SettingsVBox/ProgressVBox as VBoxContainer
	if sidebar_progress:
		sidebar_progress.visible = false
	for child in controls.get_children():
		if child is Button:
			child.custom_minimum_size = Vector2(200.0, 54.0)
	var top_h := $Root/TopBar/TopM/TopH as HBoxContainer
	_level1_progress_label = Label.new()
	_level1_progress_label.name = "Level1Progress"
	_level1_progress_label.custom_minimum_size.x = 120.0
	_level1_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level1_progress_label.add_theme_color_override("font_color", C_GOLD_TEXT)
	_level1_progress_label.add_theme_font_size_override("font_size", 15)
	top_h.add_child(_level1_progress_label)
	top_h.move_child(_level1_progress_label, top_h.get_child_count() - 2)
	var pause_button := Button.new()
	pause_button.name = "Level1PauseBtn"
	pause_button.text = "Tạm dừng"
	pause_button.custom_minimum_size = Vector2(104.0, 40.0)
	pause_button.visible = false
	pause_button.pressed.connect(func() -> void:
		if _level1_lesson1_mode:
			_toggle_level1_lesson1_listening()
		else:
			_toggle_level1_sequence()
	)
	top_h.add_child(pause_button)
	top_h.move_child(pause_button, top_h.get_child_count() - 2)
	_update_level1_progress()

func _setup_level1_sequence_exercise() -> void:
	_note_idx = 0
	_score = 0.0
	_level1_state = "preview"
	_mic_mode = str(_level1_config["input"]) == "micro"
	_reset_level1_metrics()
	var song_selector := $SettingsPanel/SettingsM/SettingsVBox.get_node_or_null("SongSelector")
	if song_selector:
		song_selector.visible = false
	var panel := PanelContainer.new()
	panel.name = "Level1SequenceExercise"
	panel.custom_minimum_size = Vector2(0.0, 118.0)
	panel.add_theme_stylebox_override("panel", _flat(Color("#fffaf0"), C_GOLD, 14))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	margin.add_child(content)
	var heading := Label.new()
	heading.text = "BÀI %d · %s" % [int(_level1_config["lesson"]), str(_level1_config["title"]).to_upper()]
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color", C_JADE)
	heading.add_theme_font_size_override("font_size", 19)
	content.add_child(heading)
	_level1_instruction = Label.new()
	var exercise_mode: String = str(_level1_config["mode"])
	if exercise_mode == "guided_song":
		_level1_instruction.text = str(_level1_config.get("instruction", "Gảy đúng nốt còn thiếu trên đàn thật để nhạc phát tiếp."))
	elif exercise_mode == "catch":
		_level1_instruction.text = "Chạm đúng ba dây Đô – Rê – Mi theo ký hiệu N1/N2."
	else:
		_level1_instruction.text = "Gảy đàn thật theo chuỗi nốt ở BPM 60; micro đánh giá cao độ và thời điểm."
	_level1_instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level1_instruction.add_theme_color_override("font_color", C_TEXT_MUTED)
	_level1_instruction.add_theme_font_size_override("font_size", 14)
	content.add_child(_level1_instruction)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	content.add_child(actions)
	_level1_status_label = Label.new()
	_level1_status_label.custom_minimum_size.x = 500.0
	_level1_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level1_status_label.text = "Sẵn sàng · Bấm Bắt đầu khi bạn đã đặt đàn đúng vị trí."
	_level1_status_label.add_theme_color_override("font_color", C_TEXT)
	actions.add_child(_level1_status_label)
	if str(_level1_config["mode"]) == "rhythm":
		for speed_value in [0.6, 0.8, 1.0]:
			var speed_button := Button.new()
			speed_button.text = "%d%%" % int(speed_value * 100.0)
			speed_button.custom_minimum_size = Vector2(62.0, 38.0)
			speed_button.pressed.connect(_set_level1_speed.bind(speed_value))
			actions.add_child(speed_button)
			_level1_speed_buttons.append(speed_button)
	_level1_start_button = Button.new()
	_level1_start_button.text = "Bắt đầu"
	_level1_start_button.custom_minimum_size = Vector2(150.0, 40.0)
	_level1_start_button.add_theme_stylebox_override("normal", _flat(C_JADE, C_GOLD, 12))
	_level1_start_button.add_theme_color_override("font_color", Color.WHITE)
	_level1_start_button.pressed.connect(_toggle_level1_sequence)
	actions.add_child(_level1_start_button)
	$Root.add_child(panel)
	$Root.move_child(panel, 1)
	_level1_compact_panel = panel
	_set_level1_speed(_level1_speed)
	_reset_level1_sequence()

func _set_level1_speed(value: float) -> void:
	if _level1_state == "playing" or _level1_state == "countdown":
		return
	_level1_speed = value
	for button in _level1_speed_buttons:
		var selected := button.text == "%d%%" % int(value * 100.0)
		button.modulate = C_GOLD_LIGHT if selected else Color.WHITE

func _toggle_level1_sequence() -> void:
	if _level1_state == "playing" or _level1_state == "countdown":
		_level1_state = "paused"
		_recording = false
		if str(_level1_config.get("mode", "")) == "guided_song":
			_level1_waiting_for_note = false
			_current_note_elapsed = 0.0
			_current_time_beats = float(_note_idx) - LEVEL1_GUIDED_LEAD_BEATS
			_stop_level1_backing()
		_set_level1_status("Đã tạm dừng · Bấm Tiếp tục khi sẵn sàng.", C_WARN)
		_set_level1_controls(false)
		return
	if _level1_state == "result":
		_reset_level1_sequence()
	if str(_level1_config.get("input", "")) == "micro" and not ProjectSettings.get_setting("audio/driver/enable_input"):
		_set_level1_status("Không thể bắt đầu: ứng dụng chưa được cấp quyền Microphone.", C_RED_ERR)
		return
	_level1_state = "countdown"
	_level1_countdown = 3.0
	_recording = false
	if str(_level1_config.get("mode", "")) == "guided_song":
		_level1_waiting_for_note = false
		_current_note_elapsed = 0.0
		_current_time_beats = float(_note_idx) - LEVEL1_GUIDED_LEAD_BEATS
		_level1_backing_timer = 0.0
	_level1_silence_time = 0.0
	_level1_result_shown = false
	if _level1_instruction:
		_level1_instruction.visible = false
	if _level1_compact_panel:
		_level1_compact_panel.custom_minimum_size.y = 64.0
	_set_level1_controls(true)
	_set_level1_status("Chuẩn bị · 3", C_GOLD_TEXT)
	_sync_level1_board()

func _set_level1_controls(running: bool) -> void:
	if _level1_start_button:
		_level1_start_button.text = "Tạm dừng" if running else "Tiếp tục"
	var pause_button := get_node_or_null("Root/TopBar/TopM/TopH/Level1PauseBtn") as Button
	if pause_button:
		pause_button.visible = running
	if record_btn:
		record_btn.text = "\nTạm dừng" if running else "\nTiếp tục"
	var visualizer = $Root/RecordBar/RecordM/RecordH.get_node_or_null("WaveformVisualizer")
	if visualizer:
		visualizer.visible = running and _mic_mode and str(_level1_config.get("input", "")) == "micro"
	if running:
		linh_panel.visible = false
		if linh_mini_btn:
			linh_mini_btn.visible = false
	else:
		_update_linh_visibility()

func _reset_level1_metrics() -> void:
	_level1_total_attempts = 0
	_level1_correct_count = 0
	_level1_consecutive_misses = 0
	_level1_timing_scores.clear()
	_level1_high_errors = 0
	_level1_low_errors = 0
	_level1_early_errors = 0
	_level1_late_errors = 0

func _reset_level1_sequence() -> void:
	_recording = false
	_stop_level1_backing()
	_level1_state = "preview"
	_level1_round = 0
	_note_idx = 0
	_current_note_elapsed = 0.0
	_current_time_beats = -LEVEL1_GUIDED_LEAD_BEATS if str(_level1_config.get("mode", "")) == "guided_song" else 0.0
	_score = 0.0
	_level1_wait_for_silence = false
	_level1_silence_time = 0.0
	_level1_waiting_for_note = false
	_level1_backing_timer = 0.0
	_level1_backing_step = 0
	_level1_result_shown = false
	_reset_level1_metrics()
	note_statuses.clear()
	for _i in sheet_notes.size():
		note_statuses.append("unplayed")
	if _board:
		_board.clear_feedback_details()
	if _level1_instruction:
		_level1_instruction.visible = true
	if _level1_compact_panel:
		_level1_compact_panel.custom_minimum_size.y = 118.0
	if _level1_start_button:
		_level1_start_button.disabled = false
		_level1_start_button.text = "Bắt đầu"
	if str(_level1_config.get("mode", "")) == "guided_song":
		_set_level1_status("Sẵn sàng · Bật micro và chuẩn bị gảy Sol – La – Đô – Rê – Mi.", C_TEXT)
	else:
		_set_level1_status("Sẵn sàng · Bấm Bắt đầu khi bạn đã đặt đàn đúng vị trí.", C_TEXT)
	_set_level1_target()
	_sync_level1_board()
	_update_level1_progress()

func _set_level1_target() -> void:
	if not _board or _note_idx < 0 or _note_idx >= sheet_notes.size():
		return
	var target_idx := NOTES_VN.find(sheet_notes[_note_idx])
	_board.set_target(target_idx)
	if target_label:
		target_label.text = "Nốt cần gảy: %s" % sheet_notes[_note_idx].rstrip("0123456789")

func _sync_level1_board() -> void:
	if not _board:
		return
	_board.sheet_notes = sheet_notes
	_board.sheet_durations = sheet_durations
	_board.note_statuses = note_statuses
	_board.note_cues = _level1_config.get("cues", [])
	_board.current_note_idx = _note_idx
	_board.current_time_beats = _current_time_beats
	_board.is_active = _level1_state == "countdown" or _level1_state == "playing"
	_board.queue_redraw()

func _update_level1_progress() -> void:
	if not _level1_progress_label:
		return
	var total := sheet_notes.size()
	var current := mini(_note_idx + 1, total)
	var prefix := "Lượt %d/3 · " % (_level1_round + 1) if str(_level1_config.get("mode", "")) == "catch" else ""
	_level1_progress_label.text = "%s%d/%d · %d%%" % [prefix, current, total, int(_score)]
	lesson_bar.value = _score

func _process_level1_sequence(delta: float) -> void:
	if _level1_state == "countdown":
		_level1_countdown -= delta
		_set_level1_status("Chuẩn bị · %d" % maxi(1, ceili(_level1_countdown)), C_GOLD_TEXT)
		if _level1_countdown <= 0.0:
			_level1_state = "playing"
			_recording = true
			_current_note_elapsed = 0.0
			if str(_level1_config.get("mode", "")) == "guided_song":
				_current_time_beats = float(_note_idx) - LEVEL1_GUIDED_LEAD_BEATS
				_level1_waiting_for_note = false
				_level1_backing_timer = 0.0
				_set_level1_status("♪ Nhạc đang phát · Chuẩn bị nốt còn thiếu", C_JADE)
			else:
				_set_level1_status("Bắt đầu!", C_JADE)
			_set_level1_target()
		_sync_level1_board()
		return
	if _level1_state != "playing":
		return
	_practice_time += delta
	_current_note_elapsed += delta
	if str(_level1_config.get("mode", "")) == "guided_song":
		_process_level1_guided_song(delta)
		_sync_level1_board()
		return
	var speed: float = float([0.75, 0.9, 1.0][_level1_round]) if str(_level1_config["mode"]) == "catch" else _level1_speed
	var seconds_per_note: float = 60.0 / (float(_level1_config["bpm"]) * speed)
	_current_time_beats = float(_note_idx) + clampf(_current_note_elapsed / seconds_per_note, 0.0, 1.0)
	if str(_level1_config["mode"]) == "rhythm":
		_process_level1_rhythm_audio(delta, seconds_per_note)
	if _level1_state == "playing" and _current_note_elapsed >= seconds_per_note:
		_register_level1_miss("missed")
	_sync_level1_board()

func _process_level1_guided_song(delta: float) -> void:
	if _note_idx >= sheet_notes.size():
		return
	var seconds_per_beat: float = 60.0 / float(_level1_config["bpm"])
	if not _level1_waiting_for_note:
		_current_time_beats = float(_note_idx) - LEVEL1_GUIDED_LEAD_BEATS + (_current_note_elapsed / seconds_per_beat)
		_level1_backing_timer -= delta
		if _level1_backing_timer <= 0.0:
			_play_level1_backing_pulse()
			_level1_backing_timer = seconds_per_beat * 0.5
		if _current_time_beats >= float(_note_idx):
			_current_time_beats = float(_note_idx)
			_current_note_elapsed = 0.0
			_level1_waiting_for_note = true
			_level1_pitch_hold = 0.0
			_stop_level1_backing()
			var target_name: String = sheet_notes[_note_idx].rstrip("0123456789")
			_set_level1_status("NHẠC ĐANG DỪNG · Gảy nốt %s để tiếp tục" % target_name, C_GOLD_TEXT)
		return
	_process_level1_guided_song_audio(delta)

func _play_level1_backing_pulse() -> void:
	if _string_streams.is_empty():
		return
	var accompaniment: Array[int] = [5, 7, 9, 7, 10, 7, 9, 6]
	var string_idx: int = accompaniment[_level1_backing_step % accompaniment.size()]
	_level1_backing_step += 1
	if string_idx < 0 or string_idx >= _string_streams.size():
		return
	var player := AudioStreamPlayer.new()
	player.stream = _string_streams[string_idx]
	player.volume_db = -19.0
	player.bus = "Master"
	add_child(player)
	_level1_backing_players.append(player)
	player.play()
	var release_timer := get_tree().create_timer(0.42)
	release_timer.timeout.connect(func() -> void:
		if is_instance_valid(player):
			_level1_backing_players.erase(player)
			player.stop()
			player.queue_free()
	)

func _stop_level1_backing() -> void:
	for player in _level1_backing_players:
		if is_instance_valid(player):
			player.stop()
			player.queue_free()
	_level1_backing_players.clear()

func _process_level1_guided_song_audio(delta: float) -> void:
	if not _mic_mode:
		_set_level1_status("NHẠC ĐANG DỪNG · Micro đang tắt", C_WARN)
		return
	var visualizer = $Root/RecordBar/RecordM/RecordH.get_node_or_null("WaveformVisualizer")
	if not visualizer or _note_idx >= sheet_notes.size():
		return
	var amplitude_db: float = visualizer.current_amplitude_db
	var pitch: float = visualizer.current_pitch
	var target_name: String = sheet_notes[_note_idx].rstrip("0123456789")
	if amplitude_db <= -45.0 or pitch <= 50.0:
		_level1_pitch_hold = 0.0
		if _level1_wait_for_silence:
			_level1_silence_time += delta
			if _level1_silence_time >= 0.12:
				_level1_wait_for_silence = false
				_level1_silence_time = 0.0
				_set_level1_status("NHẠC ĐANG DỪNG · Gảy đúng nốt %s để tiếp tục" % target_name, C_GOLD_TEXT)
		return
	_level1_silence_time = 0.0
	if _level1_wait_for_silence:
		return

	var closest_idx: int = 0
	var closest_cents: float = INF
	for i in 5:
		var candidate_frequency: float = _get_string_frequency(i)
		var cents_distance: float = absf(1200.0 * log(pitch / candidate_frequency) / log(2.0))
		if cents_distance < closest_cents:
			closest_cents = cents_distance
			closest_idx = i
	var target_idx: int = NOTES_VN.find(sheet_notes[_note_idx])
	if target_idx < 0:
		return
	var target_frequency: float = _get_string_frequency(target_idx)
	var target_cents: float = 1200.0 * log(pitch / target_frequency) / log(2.0)
	var detected_name: String = NOTES_VN[closest_idx].rstrip("0123456789")
	pitch_note.text = detected_name

	if closest_idx == target_idx and absf(target_cents) <= 35.0:
		_level1_pitch_hold += delta
		pitch_note.add_theme_color_override("font_color", C_GREEN_OK)
		pitch_status.text = "Đúng nốt · Nhạc sắp phát tiếp"
		pitch_status.add_theme_color_override("font_color", C_GREEN_OK)
		if _board:
			_board.set_feedback_detail(target_idx, "✓ %s" % target_name, 1)
		var hold_percent: int = mini(100, int((_level1_pitch_hold / 0.18) * 100.0))
		_set_level1_status("ĐÚNG NỐT %s · %d%%" % [target_name, hold_percent], C_GREEN_OK)
		if _level1_pitch_hold >= 0.18:
			_level1_total_attempts += 1
			_level1_wait_for_silence = true
			_level1_waiting_for_note = false
			_register_level1_correct("✓ %s · Nhạc tiếp tục" % target_name)
		return

	_level1_pitch_hold = 0.0
	_level1_total_attempts += 1
	_level1_consecutive_misses += 1
	_level1_wait_for_silence = true
	note_statuses[_note_idx] = "missed"
	pitch_note.add_theme_color_override("font_color", C_RED_ERR)
	pitch_status.text = "Sai nốt · Cần gảy %s" % target_name
	pitch_status.add_theme_color_override("font_color", C_RED_ERR)
	if target_cents > 0.0:
		_level1_high_errors += 1
	else:
		_level1_low_errors += 1
	var correction: String = "↓" if target_cents > 0.0 else "↑"
	if _board:
		_board.set_feedback_detail(target_idx, "✕ %s · cần %s" % [detected_name, target_name], 2)
	_set_level1_status("SAI NỐT · Nghe thấy %s %s%d¢ · Hãy gảy lại %s" % [detected_name, correction, int(absf(target_cents)), target_name], C_RED_ERR)
	_update_level1_score()

func _process_level1_rhythm_audio(delta: float, seconds_per_note: float) -> void:
	if not _mic_mode:
		_set_level1_status("Micro đang tắt · Hãy bật Micro trong thanh công cụ.", C_WARN)
		return
	var visualizer = $Root/RecordBar/RecordM/RecordH.get_node_or_null("WaveformVisualizer")
	if not visualizer or _note_idx >= sheet_notes.size():
		return
	var db: float = visualizer.current_amplitude_db
	var pitch: float = visualizer.current_pitch
	if db <= -45.0 or pitch <= 50.0:
		if _level1_wait_for_silence:
			_level1_silence_time += delta
			if _level1_silence_time >= 0.12:
				_level1_wait_for_silence = false
				_level1_silence_time = 0.0
		return
	_level1_silence_time = 0.0
	if _level1_wait_for_silence:
		return
	_level1_wait_for_silence = true
	var closest_idx := 0
	var closest_cents := INF
	for i in NOTES_VN.size():
		var frequency := _get_string_frequency(i)
		var distance := absf(1200.0 * log(pitch / frequency) / log(2.0))
		if distance < closest_cents:
			closest_cents = distance
			closest_idx = i
	var target_idx := NOTES_VN.find(sheet_notes[_note_idx])
	var target_frequency := _get_string_frequency(target_idx)
	var cents := 1200.0 * log(pitch / target_frequency) / log(2.0)
	_level1_total_attempts += 1
	if closest_idx == target_idx and absf(cents) <= 35.0:
		var timing := clampf(100.0 - absf(_current_note_elapsed - seconds_per_note * 0.35) / seconds_per_note * 130.0, 0.0, 100.0)
		_level1_timing_scores.append(timing)
		if _current_note_elapsed < seconds_per_note * 0.18:
			_level1_early_errors += 1
		elif _current_note_elapsed > seconds_per_note * 0.72:
			_level1_late_errors += 1
		_register_level1_correct("✓ %s" % sheet_notes[_note_idx].rstrip("0123456789"))
	else:
		if cents > 0.0:
			_level1_high_errors += 1
		else:
			_level1_low_errors += 1
		var arrow := "↓" if cents > 0.0 else "↑"
		_register_level1_miss("✕ %s %s%d¢" % [NOTES_VN[closest_idx].rstrip("0123456789"), arrow, int(absf(cents))])

func _register_level1_correct(detail: String) -> void:
	if _note_idx >= sheet_notes.size():
		return
	var idx := NOTES_VN.find(sheet_notes[_note_idx])
	note_statuses[_note_idx] = "correct"
	_level1_correct_count += 1
	_level1_consecutive_misses = 0
	if _board:
		_board.set_feedback_detail(idx, detail, 1)
	_set_level1_status("Chính xác · %s" % detail, C_GREEN_OK)
	_advance_level1_note()

func _register_level1_miss(detail: String) -> void:
	if _note_idx >= sheet_notes.size():
		return
	var idx := NOTES_VN.find(sheet_notes[_note_idx])
	if detail == "missed":
		_level1_total_attempts += 1
		detail = "✕ Nhỡ nhịp"
	note_statuses[_note_idx] = "missed"
	_level1_consecutive_misses += 1
	if _board:
		_board.set_feedback_detail(idx, detail, 2)
	_set_level1_status("Chưa đúng · %s" % detail, C_RED_ERR)
	if str(_level1_config["mode"]) == "rhythm" and _level1_consecutive_misses >= 3:
		var phrase_start := int(_note_idx / 4) * 4
		for i in range(phrase_start, mini(phrase_start + 4, note_statuses.size())):
			note_statuses[i] = "unplayed"
		_note_idx = phrase_start
		_current_note_elapsed = 0.0
		_current_time_beats = float(_note_idx)
		_level1_consecutive_misses = 0
		_set_level1_status("Hãy thử lại cụm %d–%d." % [phrase_start + 1, mini(phrase_start + 4, sheet_notes.size())], C_WARN)
		_set_level1_target()
		return
	_advance_level1_note()

func _advance_level1_note() -> void:
	_note_idx += 1
	_current_note_elapsed = 0.0
	_current_time_beats = float(_note_idx) - LEVEL1_GUIDED_LEAD_BEATS if str(_level1_config.get("mode", "")) == "guided_song" else float(_note_idx)
	if _note_idx >= sheet_notes.size():
		if str(_level1_config["mode"]) == "catch" and _level1_round < 2:
			_level1_round += 1
			_note_idx = 0
			for i in note_statuses.size():
				note_statuses[i] = "unplayed"
			_set_level1_status("Lượt %d/3 · Tốc độ tăng lên." % (_level1_round + 1), C_GOLD_TEXT)
			_set_level1_target()
			_update_level1_score()
		else:
			_finish_level1_sequence()
		return
	_set_level1_target()
	if str(_level1_config.get("mode", "")) == "guided_song":
		_level1_backing_timer = 0.0
		_set_level1_status("♪ Chính xác · Nhạc tiếp tục · Chuẩn bị nốt %s" % sheet_notes[_note_idx].rstrip("0123456789"), C_GREEN_OK)
	_update_level1_score()

func _update_level1_score() -> void:
	var accuracy := float(_level1_correct_count) / float(maxi(1, _level1_total_attempts)) * 100.0
	if str(_level1_config["mode"]) == "rhythm":
		var timing := _get_average_score(_level1_timing_scores, 0.0)
		_score = accuracy * 0.7 + timing * 0.3
	else:
		_score = accuracy
	_refresh_score()
	_update_level1_progress()

func _finish_level1_sequence() -> void:
	_recording = false
	_stop_level1_backing()
	_level1_state = "result"
	_update_level1_score()
	var passed := _score >= float(_level1_config["pass_score"])
	if passed:
		SecureDataManager.complete_lesson("dan_tranh", SecureDataManager.active_lesson_id, 3 if _score >= 90.0 else 2)
	if _board:
		_board.set_target(-1)
		_board.is_active = false
	_set_level1_controls(false)
	if _level1_start_button:
		_level1_start_button.text = "Luyện lại"
	_set_level1_status("Hoàn thành · %d%% · %s" % [int(_score), "Đạt" if passed else "Cần đạt 80%"], C_GREEN_OK if passed else C_WARN)
	_show_level1_result(passed)

func _show_level1_result(passed: bool) -> void:
	if _level1_result_shown:
		return
	_level1_result_shown = true
	var popup_scene := load("res://scenes/CustomPopup.tscn") as PackedScene
	if not popup_scene:
		return
	var popup = popup_scene.instantiate()
	add_child(popup)
	var pitch_accuracy := float(_level1_correct_count) / float(maxi(1, _level1_total_attempts)) * 100.0
	var timing := _get_average_score(_level1_timing_scores, pitch_accuracy)
	popup.setup_result(_score, pitch_accuracy, timing, 100.0 if passed else 70.0, 30 if passed else 0, "Bài tiếp theo" if passed else "Luyện lại")
	var action := popup.get_node_or_null("CardContainer/MarginContainer/Content/ActionBtn") as Button
	if action:
		action.text = "Bài tiếp theo" if passed else "Luyện lại"
	if passed:
		popup.closed.connect(_go_back)
	else:
		popup.closed.connect(_reset_level1_sequence)
	var summary := popup.get_node_or_null("CardContainer/MarginContainer/Content/ResultVBox/MainRow/DetailsVBox/RewardsCard/RewardM/RewardsLabel") as Label
	if summary:
		summary.text = "Đúng %d/%d · Cao %d · Thấp %d · Sớm %d · Muộn %d" % [_level1_correct_count, _level1_total_attempts, _level1_high_errors, _level1_low_errors, _level1_early_errors, _level1_late_errors]


func _process(delta: float) -> void:
	if _level1_mode and not _level1_lesson1_mode:
		_process_level1_sequence(delta)
		return
	if _level1_lesson1_mode:
		if _recording:
			_practice_time += delta
			_process_level1_lesson1_audio(delta)
		return

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

	($Root/StringsBoard/BoardM/BoardVBox/BoardLabel as Label).text = "ĐÀN TRANH 17 DÂY  —  Chạm phải nhạn đàn để gảy  ·  Kéo trái để nhấn rung"
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
		settings_panel.offset_right = settings_panel.offset_left + 240.0
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
	for i in 17:
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
	_string_streams.resize(17)
	for i in 17:
		var freq := _get_string_frequency(i)
		_string_streams[i] = _generate_pluck_stream(freq)

func _get_string_frequency(idx: int) -> float:
	# Đàn tranh 17 dây - tuning theo hệ ngũ cung Sol - La - Đô - Rê - Mi
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
	if _level1_mode and str(_level1_config.get("mode", "")) == "catch":
		var simple_note := plucked_note.rstrip("0123456789")
		if _level1_state != "playing":
			_set_level1_status("Nốt %s · Bấm Bắt đầu để vào bài Hứng nốt." % simple_note, C_GOLD_TEXT)
			return
		if _note_idx >= sheet_notes.size():
			return
		_level1_total_attempts += 1
		var expected_idx := NOTES_VN.find(sheet_notes[_note_idx])
		if idx == expected_idx:
			_register_level1_correct("✓ %s · %s" % [simple_note, str(_level1_config["cues"][_note_idx])])
		else:
			_register_level1_miss("✕ Đã gảy %s" % simple_note)
		return
	if _level1_mode and not _level1_lesson1_mode:
		_set_level1_status("Nghe mẫu nốt %s · Khi luyện tập, hãy gảy trên đàn thật." % plucked_note.rstrip("0123456789"), C_GOLD_TEXT)
		return
	if _level1_lesson1_mode:
		var simple_note := plucked_note.rstrip("0123456789")
		pitch_note.text = simple_note
		pitch_status.text = "Nốt mẫu · Hãy gảy lại trên đàn thật"
		pitch_status.add_theme_color_override("font_color", C_GOLD_TEXT)
		pitch_note.add_theme_color_override("font_color", C_GOLD)
		_set_level1_status("Đang phát mẫu nốt %s · Hãy gảy lại trên đàn thật." % simple_note, C_GOLD_TEXT)
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
			if _level1_mode:
				_toggle_record()
			elif not _recording:
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
	if _level1_lesson1_mode:
		_toggle_level1_lesson1_listening()
		return
	if _level1_mode:
		_toggle_level1_sequence()
		return
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
	if string_idx < 0 or string_idx >= 17:
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
		
		# Find the closest frequency matching the target note across all 17 strings
		var closest_target_freq := 0.0
		var min_diff := 999999.0
		for i in range(17):
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
		for i in range(17):
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
	if _level1_lesson1_mode:
		_reset_level1_lesson1_exercise()
		return
	if _level1_mode:
		_reset_level1_sequence()
		return
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
			"text": "Cây đàn tranh của chúng ta có 17 dây, được lên dây theo thang năm âm (pentatonic) truyền thống gồm: Sol, La, Đô, Rê, Mi.",
			"voice": "Cây đàn tranh của chúng ta có mười bảy dây, được lên dây theo thang năm âm truyền thống gồm: Sol, La, Đô, Rê và Mi.",
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
	title.text = "BÀI HỌC CƠ BẢN: ĐÀN TRANH 17 DÂY"
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
		for i in range(17):
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
	if string_idx < 0 or string_idx >= 17: return
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
	for i in range(17):
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
	if string_idx < 0 or string_idx >= 17: return
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
