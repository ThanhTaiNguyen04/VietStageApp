extends Control
class_name LessonDanTranh

const C_GOLD = Color(0.961, 0.784, 0.259, 1.0)
const C_WOOD = Color(0.18, 0.13, 0.08, 1.0)
const C_JADE = Color("#173f2d")
const LEVEL_7_GLISSANDO_ID := "dan_tranh_level_7_bai_18_practice"
const LEVEL_7_GLISSANDO_TITLE := "Kỹ thuật Á"
const LEVEL_7_PRESS_ID := "dan_tranh_level_7_bai_19_practice"
const LEVEL_7_SONG_THANH_ID := "dan_tranh_level_7_bai_20_practice"
const LEVEL_7_VIBRATO_ID := "dan_tranh_level_7_bai_21_practice"
const LEVEL_8_TREMOLO_ID := "dan_tranh_level_8_bai_30_practice"
const ERROR_FLASH_DEMO_ID := "dan_tranh_level_7_bai_22_practice"
const CHORD_MIN_FUNDAMENTAL_DB := -55.0
const CHORD_SIMULTANEOUS_HOLD_TIME := 0.05
const CHORD_MAX_COMPONENT_SPREAD_DB := 28.0
const CHORD_UNEXPECTED_NOTE_MARGIN_DB := 2.0
const TTS_MIC_RESUME_DELAY_SEC := 0.40

enum State { CALIBRATION, INTRO, PRACTICE_SINGLE, PRACTICE, COMPLETED, RHYTHM_GAME }
enum TechniqueSampleKind { NONE, GLISSANDO, PRESS, VIBRATO, TREMOLO }
var current_state = State.INTRO

@onready var root = $Root
@onready var zither_board = $Root/CenterContainer/ZitherBoard/BoardM/ZitherFrame/ZitherM/ZitherStack/DanTranhBoard
@onready var string_overlay = $Root/CenterContainer/ZitherBoard/BoardM/ZitherFrame/ZitherM/ZitherStack/StringOverlay

@onready var back_btn = $BackBtn
@onready var complete_btn = $CompleteBtn
@onready var teacher_area = $TeacherArea
@onready var teacher_char = $TeacherArea/TeacherChar
@onready var speech_text = $TeacherArea/DialogBox/M/V/SpeechText
@onready var real_mode_btn = $TeacherArea/DialogBox/M/V/ModeButtons/RealModeBtn
@onready var analyzer = $Analyzer
@onready var feedback_area = $FeedbackArea
@onready var volume_bar = $FeedbackArea/VolumeBar
var ai_audio = null
var _dan_tranh_attempts: Array[Dictionary] = []
var _micro_scoring_locked := false
var _tts_resume_token := 0

# Virtual Teacher Portrait Animation States
var _tex_mai_talk_sheet = load("res://assets/textures/coMai/mai_upper_body_talk_16_frames.png") as Texture2D
var _teacher_atlas : AtlasTexture
var _portrait_is_talking := false
var _portrait_frame := 0
var _portrait_frame_elapsed := 0.0
var _teacher_avatar_wrapper: Panel
const PORTRAIT_FRAME_DURATION := 0.08
const PORTRAIT_FRAME_COUNT := 16
const PORTRAIT_SHEET_COLUMNS := 4
const PORTRAIT_SHEET_ROWS := 4

var staff_display: Control
var pitch_box: PanelContainer
var pitch_note_lbl: Label
var pitch_status_lbl: Label
var mic_status_lbl: Label
var pitch_meter: Control
var force_mobile_audio_fallback_for_tests := false
var staff_card: PanelContainer
var title_plaque: PanelContainer
var pill_badge: PanelContainer
var sub_instr_row: HBoxContainer

class PitchMeterDraw extends Control:
	var current_cents: float = 0.0
	var is_active: bool = false
	
	func _draw():
		var W = size.x
		var H = size.y
		var cy = H / 2.0
		var cx = W / 2.0
		
		# Base track bar
		draw_rect(Rect2(0, cy - 3, W, 6), Color(0.15, 0.15, 0.15, 0.7), true)
		
		# Target in-tune zone (-25 to +25 cents) -> Green translucent fill
		var safe_w = (50.0 / 100.0) * W
		draw_rect(Rect2(cx - safe_w/2.0, cy - 5, safe_w, 10), Color(0.2, 0.8, 0.3, 0.35), true)
		
		# Center gold target line (0 cents)
		draw_line(Vector2(cx, cy - 8), Vector2(cx, cy + 8), Color(0.961, 0.784, 0.259, 1.0), 2.5)
		
		# End ticks (-50, +50)
		draw_line(Vector2(4, cy - 5), Vector2(4, cy + 5), Color(0.7, 0.7, 0.7, 0.5), 1.5)
		draw_line(Vector2(W - 4, cy - 5), Vector2(W - 4, cy + 5), Color(0.7, 0.7, 0.7, 0.5), 1.5)
		
		# Real-time Needle / Pointer
		if is_active:
			var norm_c = clampf(current_cents, -50.0, 50.0)
			var ptr_x = cx + (norm_c / 50.0) * (W / 2.0 - 6.0)
			var ptr_color = Color(0.25, 0.95, 0.45) if abs(norm_c) <= 25.0 else Color(1.0, 0.35, 0.35)
			
			# Needle pointer (bright glowing vertical bar + circle cap)
			draw_line(Vector2(ptr_x, cy - 10), Vector2(ptr_x, cy + 10), ptr_color, 3.5)
			draw_circle(Vector2(ptr_x, cy), 5.0, ptr_color)


var glissando_sheet: Control
var glissando_progress_label: Label
var glissando_progress_bar: ProgressBar
var glissando_instruction_label: Label
var glissando_status_label: Label
var glissando_round_idx := 0
var glissando_detected_strings: Array[int] = []
var glissando_detected_times: Array[float] = []
var glissando_detected_generations: Array[int] = []
var glissando_display_notes: Array = []
var glissando_last_detection_time := 0.0
var glissando_round_locked := false
const GLISSANDO_GAP_TIMEOUT := 0.75
const GLISSANDO_MAX_ATTACK_GAP := 0.45
const GLISSANDO_MAX_STRING_STEP := 6
const GLISSANDO_MIN_DISTINCT_STRINGS := 5
const GLISSANDO_ROUNDS := [
	{"mode": "down", "title": "Á xuống", "instruction": "Vuốt liền mạch từ dây cao xuống dây thấp"},
	{"mode": "up", "title": "Á lên", "instruction": "Vuốt liền mạch từ dây thấp lên dây cao"},
	{"mode": "round", "title": "Á vòng", "instruction": "Vuốt từ dây cao xuống dây thấp rồi trở lên dây cao"}
]
var vibrato_sheet_hud: Control
var vibrato_instruction_label: Label
var vibrato_status_label: Label
var vibrato_progress_bar: ProgressBar
var vibrato_note_idx := 0
var vibrato_display_notes: Array = []
var vibrato_pitch_history: Array[float] = []
var vibrato_sample_accumulator := 0.0
var vibrato_attempt_elapsed := 0.0
var vibrato_silence_elapsed := 0.0
var vibrato_base_note_heard := false
var vibrato_note_locked := false
var vibrato_attack_generation := -1
var vibrato_consumed_attack_generation := -1
var vibrato_contour_elapsed := 0.0
var vibrato_min_amplitude_db := 0.0
var vibrato_added_sound_elapsed := 0.0
const VIBRATO_NOTES: Array[String] = ["Sol2", "La2", "Đô3", "Rê3", "Mi3", "Sol3", "La3"]
const VIBRATO_SAMPLE_INTERVAL := 0.025
const VIBRATO_ATTEMPT_TIMEOUT := 5.0
const VIBRATO_MAX_SIGNAL_GAP := 0.45
const VIBRATO_ADDED_SOUND_RISE_DB := 8.0
const VIBRATO_ADDED_SOUND_HOLD_SEC := 0.10
const VIBRATO_MIN_DURATION_SEC := 0.50
const VIBRATO_MAX_RAW_UPWARD_CENTS := 150.0
const VIBRATO_MIN_RAW_CENTS := -40.0
var press_sheet_hud: Control
var press_instruction_label: Label
var press_status_label: Label
var press_progress_bar: ProgressBar
var press_exercise_idx := 0
var press_display_notes: Array = []
var press_cents_history: Array[float] = []
var press_sample_accumulator := 0.0
var press_attempt_elapsed := 0.0
var press_silence_elapsed := 0.0
var press_target_hold_elapsed := 0.0
var press_base_note_heard := false
var press_exercise_locked := false
var press_max_cents := 0.0
var press_attack_generation := -1
var press_consumed_attack_generation := -1
var press_contour_elapsed := 0.0
var press_min_amplitude_db := 0.0
var press_added_sound_elapsed := 0.0
const PRESS_SAMPLE_INTERVAL := 0.025
const PRESS_ATTEMPT_TIMEOUT := 5.5
const PRESS_MAX_SIGNAL_GAP := 0.45
const PRESS_MAX_SAMPLE_JUMP_CENTS := 120.0
const PRESS_MAX_RISE_DELAY := 0.80
const PRESS_ADDED_SOUND_RISE_DB := 8.0
const PRESS_ADDED_SOUND_HOLD_SEC := 0.10
const PRESS_EXERCISES := [
	{"source": "Mi2", "target": "Fa2", "interval": 100.0},
	{"source": "La2", "target": "Si2", "interval": 200.0},
	{"source": "Mi3", "target": "Fa3", "interval": 100.0},
	{"source": "La3", "target": "Si3", "interval": 200.0}
]
var tremolo_sheet_hud: Control
var tremolo_instruction_label: Label
var tremolo_status_label: Label
var tremolo_progress_bar: ProgressBar
var tremolo_exercise_idx := 0
var tremolo_display_notes: Array = []
var tremolo_attack_strings: Array[int] = []
var tremolo_attack_times: Array[float] = []
var tremolo_attack_generations: Array[int] = []
var tremolo_attempt_started_at := 0.0
var tremolo_last_attack_at := 0.0
var tremolo_last_seen_generation := -1
var tremolo_exercise_locked := false
var tremolo_wrong_attacks := 0
const TREMOLO_REQUIRED_DURATION := 1.2
const TREMOLO_GAP_TIMEOUT := 0.60
const TREMOLO_EXERCISE_TIMEOUT := 6.5
const TREMOLO_MIN_SCORED_DURATION := 0.90
const TREMOLO_MIN_ATTACK_COUNT := 5
const TREMOLO_MIN_RATE := 2.5
const TREMOLO_MAX_RATE := 14.0
const TREMOLO_MAX_ATTACK_GAP := 0.50
const TREMOLO_MIN_REGULARITY := 0.35
const TREMOLO_EXERCISES := [
	{"mode": "single", "title": "Vê một dây · Đô2", "notes": ["Đô2"]},
	{"mode": "single", "title": "Vê một dây · Sol2", "notes": ["Sol2"]},
	{"mode": "single", "title": "Vê một dây · Đô3", "notes": ["Đô3"]},
	{"mode": "octave", "title": "Vê quãng tám · Đô2 – Đô3", "notes": ["Đô2", "Đô3"]},
	{"mode": "octave", "title": "Vê quãng tám · Sol2 – Sol3", "notes": ["Sol2", "Sol3"]},
	{"mode": "octave", "title": "Vê quãng tám · La2 – La3", "notes": ["La2", "La3"]}
]
var dan_tranh_string_streams: Array = []
var technique_sample_player: AudioStreamPlayer
var technique_sample_kind := TechniqueSampleKind.NONE
var technique_sample_demo_idx := 0
var technique_sample_elapsed := 0.0
var technique_sample_event_elapsed := 0.0
var technique_sample_sequence: Array[int] = []
var technique_sample_sequence_idx := 0
var technique_sample_in_gap := false
var technique_sample_input_cooldown := 0.0
const TECHNIQUE_SAMPLE_GAP := 0.65
const GLISSANDO_SAMPLE_INTERVAL := 0.075
const PRESS_SAMPLE_DURATION := 2.25
const VIBRATO_DEMO_DURATION := 2.20
const TREMOLO_SAMPLE_INTERVAL := 0.14
const TREMOLO_SAMPLE_DURATION := 2.60
var error_flash_overlay: Control
var error_flash_badge: Control
var error_flash_halo: Control
var error_flash_title_label: Label
var error_flash_detail_label: Label
var error_flash_timer := 0.75
var error_flash_tween: Tween
var error_pulse_tween: Tween
var error_shake_tween: Tween
var error_flash_note: Dictionary = {}
var error_feedback_player: AudioStreamPlayer
var error_tooltip_final_position := Vector2.ZERO
var error_feedback_showing := false
var error_feedback_target_note := ""
var error_feedback_title := "Chưa đúng"
var error_feedback_detail := ""
var unrecognized_audio_elapsed := 0.0
const UNRECOGNIZED_AUDIO_HINT_DELAY := 0.30
var current_lesson_id: String
var lesson_data: Dictionary
static var current_song_durations: Array[float] = []
static var current_song_cues: Array[String] = []
static var current_song_fingerings: Array[String] = []
# Set by the Level 7 lesson selector immediately before the scene is opened.
# This does not rely on any persisted lesson/session value.
static var force_glissando_start := false

var lesson_sheet: Array[String] = []
var lesson_durations: Array[float] = []

var practice_idx: int = 0

var is_challenge_mode := false
var rhythm_time := 0.0
var challenge_hit_notes := 0
var challenge_total_notes := 0
var bpm_multiplier := 1.0
var bpm_controls_row: HBoxContainer
var score_label: Label
var has_rhythm_completed := false
var active_rhythm_notes := []
var notes_judged := {}
var intro_step: int = 0
var intro_playback_token: int = 0
var time_correct: float = 0.0
var REQUIRED_HOLD_TIME: float = 0.20

var wrong_note_time: float = 0.0
var REQUIRED_WRONG_HOLD_TIME: float = 0.18

var active_falling_notes = []
var practice_time: float = 0.0

var single_practice_idx: int = 0
var unique_practice_notes: Array[String] = []

var wrong_note_cooldown: float = 0.0
var mic_cooldown: float = 0.0

var consecutive_hits: int = 0

var consecutive_misses: int = 0
var total_misses: int = 0
var current_speed_multiplier: float = 1.0

const STRINGS = 17

const ALL_17_NOTES: Array[String] = [
	"Sol1", "La1", "Đô2", "Rê2", "Mi2",
	"Sol2", "La2", "Đô3", "Rê3", "Mi3",
	"Sol3", "La3", "Đô4", "Rê4", "Mi4",
	"Sol4", "La4"
]


const LESSON_DIALOGUES = {
	"dan_tranh_level_7_bai_18_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ cùng tìm hiểu kỹ thuật Á trên đàn Tranh.", "highlight": -1},
		{"action": "speak", "text": "Kỹ thuật Á là dùng ngón tay phải vuốt nhanh và liên tục qua nhiều dây để tạo thành một chuỗi âm thanh liền mạch.", "highlight": -1},
		{"action": "speak", "text": "Á xuống là vuốt từ vùng dây có âm cao xuống vùng dây có âm thấp. Á lên là vuốt theo chiều ngược lại, từ âm thấp lên âm cao.", "highlight": -1},
		{"action": "speak", "text": "Á vòng là kết hợp hai chiều trong cùng một động tác: vuốt xuống rồi đổi hướng vuốt trở lên. Khi thực hiện, các tiếng cần nối đều, rõ và không bị ngắt quãng.", "highlight": -1},
		{"action": "speak", "text": "Phần thực hành gồm ba lượt: Á xuống, Á lên và Á vòng. Ứng dụng sẽ nghe đàn thật, kiểm tra hướng vuốt, độ rộng và tính liên tục của chuỗi âm. Bây giờ chúng ta bắt đầu nhé!", "highlight": -1}
	],
	"dan_tranh_level_1_bai_1_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học đầu tiên, chúng ta sẽ cùng tìm hiểu nhạc cụ đàn Tranh.", "highlight": -1},
		{"action": "speak", "text": "Đàn Tranh là nhạc cụ dây truyền thống của Việt Nam. Đàn thường có mười sáu hoặc mười chín dây, thân đàn dạng hộp dài hình thang, dài khoảng một trăm mười đến một trăm hai mươi xen-ti-mét. Đầu lớn rộng hơn là nơi mắc dây và đặt cầu đàn; đầu nhỏ có các trục để lên dây.", "highlight": -1},
		{"action": "speak", "text": "Các bộ phận chính của đàn gồm có mặt đàn, thành và đáy đàn, cầu đàn, nhạn, trục đàn, dây đàn và móng gảy.", "highlight": -1},
		{"action": "speak", "text": "Mặt đàn làm từ gỗ nhẹ, thường là gỗ ngô đồng, có dạng vồng lên. Thành và đáy đàn làm từ các loại gỗ cứng; đáy đàn có lỗ thoát âm và vị trí cầm hoặc treo đàn.", "highlight": -1},
		{"action": "speak", "text": "Cầu đàn nằm ở đầu rộng, giúp cố định dây đàn. Nhạn, còn gọi là ngựa đàn, là các thanh gỗ nhỏ đỡ dây trên mặt đàn và có thể di chuyển để điều chỉnh cao độ của từng dây.", "highlight": -1},
		{"action": "speak", "text": "Trục đàn nằm ở đầu nhỏ, dùng để căng và lên dây. Dây đàn thường làm bằng thép hoặc inox, có độ dày khác nhau để tạo ra âm thanh cao thấp.", "highlight": -1},
		{"action": "speak", "text": "Móng gảy được đeo ở ngón cái, ngón trỏ và ngón giữa của tay phải để gảy đàn; có thể làm từ đồi mồi, sừng hoặc kim loại.", "highlight": -1},
		{"action": "speak", "text": "Đàn Tranh có thể diễn tấu giai điệu, gảy quãng tám, chập âm và vuốt dây để tạo âm thanh mềm mại, đặc trưng. Đàn được dùng để độc tấu, hòa tấu hoặc đệm cho hát; phù hợp với dân ca, nhạc truyền thống và cả các tác phẩm hiện đại.", "highlight": -1},
		{"action": "speak", "text": "Bây giờ, hãy ngồi thẳng lưng và đặt đàn trước mặt. Đầu lớn của đàn nằm phía tay phải. Chúng ta dùng tay phải để gảy và tay trái để nhấn, giữ dây tạo âm vang. Hãy cùng bắt đầu phần thực hành nhé!", "highlight": -1},
		{"action": "speak", "text": "Đầu tiên, hãy làm quen với âm sắc của 5 nốt cơ bản nhất ở quãng trầm của đàn.", "highlight": -1},
		{"action": "speak", "text": "Dây 1: Nốt Sol1. Hãy gảy đúng nốt Sol1 ở dây thứ nhất đàn.", "highlight": 0},
		{"action": "speak", "text": "Dây 2: Nốt La1. Hãy gảy nốt La1 ở dây thứ 2 trên đàn.", "highlight": 1},
		{"action": "speak", "text": "Dây 3: Nốt Đô2. Hãy gảy nốt Đô2 ở dây thứ 3 trên đàn.", "highlight": 2},
		{"action": "speak", "text": "Dây 4: Nốt Rê2. Hãy gảy nốt Rê2 ở dây thứ 4 trên đàn.", "highlight": 3},
		{"action": "speak", "text": "Dây 5: Nốt Mi2. Hãy gảy nốt Mi2 ở dây thứ 5 trên đàn.", "highlight": 4},
		{"action": "speak", "text": "Tuyệt vời! Bạn đã hoàn thành gảy 5 nốt cơ bản đầu tiên của Đàn Tranh!", "highlight": -1}
	],

	"dan_tranh_level_1_bai_2_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ luyện gảy các nốt cơ bản, phần một.", "highlight": -1},
		{"action": "speak", "text": "Chúng ta sẽ luyện tập lần lượt từng nốt: Sol một, La một, Đô hai, Rê hai, Mi hai, Sol hai, La hai, Đô ba, Rê ba và Mi ba.", "highlight": -1},
		{"action": "speak", "text": "Phần này giúp bạn luyện nhận biết và gảy lần lượt các nốt từ Sol một đến Mi ba. Hãy luân phiên ngón số hai rồi ngón số một, bắt đầu bằng ngón hai ở nốt đầu tiên. Ứng dụng sẽ nghe đàn thật qua micro và chỉ chuyển sang dây kế tiếp sau khi nhận diện đúng cao độ. Hãy gảy chậm, rõ tiếng và đúng vị trí từng dây. Bây giờ, chúng ta cùng bắt đầu nhé!", "highlight": -1},
		{"action": "speak", "text": "Đầu tiên là dây 1: Nốt Sol1 ở quãng thấp nhất. Hãy gảy dây 1.", "highlight": 0, "note": "Sol1"},
		{"action": "speak", "text": "Dây 2: Nốt La1. Hãy gảy dây 2.", "highlight": 1, "note": "La1"},
		{"action": "speak", "text": "Dây 3: Nốt Đô2. Hãy gảy dây 3.", "highlight": 2, "note": "Đô2"},
		{"action": "speak", "text": "Dây 4: Nốt Rê2. Hãy gảy dây 4.", "highlight": 3, "note": "Rê2"},
		{"action": "speak", "text": "Dây 5: Nốt Mi2. Hãy gảy dây 5.", "highlight": 4, "note": "Mi2"},
		{"action": "speak", "text": "Dây 6: Nốt Sol2. Hãy gảy dây 6.", "highlight": 5, "note": "Sol2"},
		{"action": "speak", "text": "Dây 7: Nốt La2. Hãy gảy dây 7.", "highlight": 6, "note": "La2"},
		{"action": "speak", "text": "Dây 8: Nốt Đô3. Hãy gảy dây 8.", "highlight": 7, "note": "Đô3"},
		{"action": "speak", "text": "Dây 9: Nốt Rê3. Hãy gảy dây 9.", "highlight": 8, "note": "Rê3"},
		{"action": "speak", "text": "Dây 10: Nốt Mi3. Hãy gảy dây 10.", "highlight": 9, "note": "Mi3"},
		{"action": "speak", "text": "Tuyệt vời! Bạn đã hoàn thành nhận diện và gảy đúng 10 nốt cơ bản quãng thấp và trung!", "highlight": -1}
	],

	"dan_tranh_level_1_bai_3_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ luyện gảy các nốt cơ bản, phần hai.", "highlight": -1},
		{"action": "speak", "text": "Chúng ta sẽ luyện tập lần lượt từng nốt: Sol ba, La ba, Đô bốn, Rê bốn, Mi bốn, Sol bốn và La bốn.", "highlight": -1},
		{"action": "speak", "text": "Ở phần này, hãy luân phiên ngón số ba, ngón số hai rồi ngón số một, bắt đầu bằng ngón ba ở nốt đầu tiên. Dãy số dưới sheet sẽ là ba, hai, một, ba, hai, một, ba.", "highlight": -1},
		{"action": "speak", "text": "Ứng dụng sẽ nghe đàn thật qua micro và chỉ chuyển sang dây kế tiếp sau khi nhận diện đúng cao độ. Hãy đổi ngón theo số dưới sheet, gảy rõ tiếng và chú ý không nhầm vị trí các dây cao. Bây giờ, chúng ta cùng bắt đầu nhé!", "highlight": -1},
		{"action": "speak", "text": "Dây 11: Nốt Sol3. Hãy gảy dây 11.", "highlight": 10, "note": "Sol3"},
		{"action": "speak", "text": "Dây 12: Nốt La3. Hãy gảy dây 12.", "highlight": 11, "note": "La3"},
		{"action": "speak", "text": "Dây 13: Nốt Đô4. Hãy gảy dây 13.", "highlight": 12, "note": "Đô4"},
		{"action": "speak", "text": "Dây 14: Nốt Rê4. Hãy gảy dây 14.", "highlight": 13, "note": "Rê4"},
		{"action": "speak", "text": "Dây 15: Nốt Mi4. Hãy gảy dây 15.", "highlight": 14, "note": "Mi4"},
		{"action": "speak", "text": "Dây 16: Nốt Sol4. Hãy gảy dây 16.", "highlight": 15, "note": "Sol4"},
		{"action": "speak", "text": "Dây 17: Nốt La4. Hãy gảy dây 17.", "highlight": 16, "note": "La4"},
		{"action": "speak", "text": "Tuyệt vời! Bạn đã hoàn thành nhận diện và gảy đúng 7 nốt ở âm vực cao!", "highlight": -1}
	],

	"dan_tranh_level_2_bai_10_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ luyện nửa đoạn đầu bài Lý cây đa.", "highlight": -1},
		{"action": "speak", "text": "Hãy áp dụng các nốt và ngón gảy đã học để luyện nửa đầu bài Lý cây đa. Bạn nên tập chậm từng câu và đếm nhịp đều. Bây giờ, chúng ta cùng bắt đầu phần thực hành nhé!", "highlight": -1}
	],

	"dan_tranh_level_2_bai_11_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ tiếp tục luyện nửa đoạn cuối bài Lý cây đa.", "highlight": -1},
		{"action": "speak", "text": "Hãy chú ý tên nốt, nhịp và ngón gảy của từng câu nhạc. Bây giờ, chúng ta cùng bắt đầu phần thực hành nhé!", "highlight": -1}
	],

	"dan_tranh_level_2_bai_12_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ hoàn thiện bài Lý cây đa.", "highlight": -1},
		{"action": "speak", "text": "Hãy ghép hai phần đã học để chơi hoàn chỉnh bài Lý cây đa. Bắt đầu chậm, gảy rõ tiếng và giữ nhịp đều. Bây giờ, chúng ta cùng bắt đầu phần thực hành nhé!", "highlight": -1}
	],

	"dan_tranh_level_2_bai_13_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ luyện nửa đoạn đầu bài Sứ thanh hoa.", "highlight": -1},
		{"action": "speak", "text": "Ở bài này, chúng ta áp dụng luyện tập các kỹ thuật gảy ngón vào nửa đầu bài Sứ thanh hoa. Hãy tập từng câu nhạc chậm, đúng nốt và đều nhịp. Bây giờ, chúng ta cùng bắt đầu phần thực hành nhé!", "highlight": -1}
	],

	"dan_tranh_level_2_bai_14_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ tiếp tục luyện nửa đoạn cuối bài Sứ thanh hoa.", "highlight": -1},
		{"action": "speak", "text": "Chú ý các chỗ đổi ngón, nhấn hoặc nếu có rung dây để giai điệu liền mạch và có cảm xúc. Bây giờ, chúng ta cùng bắt đầu phần thực hành nhé!", "highlight": -1}
	],

	"dan_tranh_level_2_bai_15_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ hoàn thiện bài Sứ thanh hoa.", "highlight": -1},
		{"action": "speak", "text": "Giờ ghép hai phần đã học để chơi hoàn chỉnh bài Sứ thanh hoa. Hãy giữ nhịp ổn định, gảy rõ nốt và thể hiện kỹ thuật đúng vị trí. Bây giờ, chúng ta cùng bắt đầu phần thực hành nhé!", "highlight": -1}
	],

	"dan_tranh_level_1_bai_7_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ luyện kỹ thuật gảy ngón số một trên năm dây giữa của đàn Tranh.", "highlight": -1},
		{"action": "speak", "text": "Ngón số một là ngón cái của tay phải. Ngón bốn tỳ nhẹ lên cầu đàn, các ngón còn lại khum tự nhiên; hãy giữ bàn tay và cổ tay thả lỏng khi gảy.", "highlight": -1},
		{"action": "speak", "text": "Phần thực hành gồm năm nốt: Sol hai ở dây sáu, La hai ở dây bảy, Đô ba ở dây tám, Rê ba ở dây chín và Mi ba ở dây mười. Ứng dụng sẽ nghe đàn thật và chỉ ghi nhận khi bạn gảy đúng cao độ. Bây giờ chúng ta bắt đầu nhé!", "highlight": -1}
	],

	"dan_tranh_level_1_bai_8_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ luyện kỹ thuật gảy ngón số hai trên năm dây đầu của đàn Tranh.", "highlight": -1},
		{"action": "speak", "text": "Ngón số hai là ngón trỏ của tay phải. Hãy giữ cổ tay thả lỏng, bàn tay khum tự nhiên và dùng ngón trỏ để gảy từng dây rõ tiếng.", "highlight": -1},
		{"action": "speak", "text": "Phần thực hành gồm năm nốt: Sol một ở dây một, La một ở dây hai, Đô hai ở dây ba, Rê hai ở dây bốn và Mi hai ở dây năm. Ứng dụng sẽ nghe đàn thật và chỉ ghi nhận khi bạn gảy đúng cao độ. Bây giờ chúng ta bắt đầu nhé!", "highlight": -1}
	],

	"dan_tranh_level_1_bai_9_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ luyện kỹ thuật gảy ngón số ba trên bảy dây cao của đàn Tranh.", "highlight": -1},
		{"action": "speak", "text": "Ngón số ba là ngón giữa của tay phải. Hãy giữ bàn tay khum tự nhiên, cổ tay thả lỏng và dùng ngón giữa để gảy từng dây rõ tiếng.", "highlight": -1},
		{"action": "speak", "text": "Phần thực hành gồm bảy nốt: Sol ba ở dây mười một, La ba ở dây mười hai, Đô bốn ở dây mười ba, Rê bốn ở dây mười bốn, Mi bốn ở dây mười lăm, Sol bốn ở dây mười sáu và La bốn ở dây mười bảy. Ứng dụng sẽ nghe đàn thật và chỉ ghi nhận khi bạn gảy đúng cao độ. Bây giờ chúng ta bắt đầu nhé!", "highlight": -1}
	],

	"dan_tranh_level_1_bai_4_practice": [
		{"action": "speak", "text": "Chào bạn! Trước khi đọc bản nhạc, chúng ta hãy nhận biết ba âm vực của 17 dây đàn Tranh. Âm vực là vùng âm thanh trầm, trung hoặc cao; khác với quãng là khoảng cách giữa hai nốt.", "highlight": -1},
		{"action": "speak", "text": "Âm vực trầm gồm các dây 1 đến 5: Sol1, La1, Đô2, Rê2 và Mi2. Đây là nhóm dây có âm thanh thấp nhất trên đàn.", "highlight": -1},
		{"action": "speak", "text": "Âm vực trung gồm các dây 6 đến 10: Sol2, La2, Đô3, Rê3 và Mi3. Âm vực cao gồm các dây 11 đến 17: Sol3, La3, Đô4, Rê4, Mi4, Sol4 và La4.", "highlight": -1},
		{"action": "speak", "text": "Các tên nốt có thể lặp lại ở những độ cao khác nhau, chẳng hạn Sol1, Sol2, Sol3 và Sol4. Con số sau tên nốt giúp chúng ta phân biệt đúng dây và đúng âm vực.", "highlight": -1},
		{"action": "speak", "text": "Khi đọc một bản nhạc, chúng ta còn cần chú ý đến tempo, khóa nhạc và nhịp.", "highlight": -1},
		{"action": "speak", "text": "Tempo là tốc độ nhanh hoặc chậm của bản nhạc. Tempo có thể được ghi bằng số B P M; ví dụ, sáu mươi B P M chậm hơn một trăm hai mươi B P M. Khi tập đàn, bạn nên bắt đầu chậm, giữ đều nhịp rồi mới tăng tốc.", "highlight": -1, "show_speed": true},
		{"action": "speak", "text": "Khóa Sol là ký hiệu thường đặt ở đầu khuông nhạc, giúp chúng ta xác định tên và độ cao của các nốt. Dấu khóa này bắt đầu từ dòng thứ hai của khuông nhạc, cho biết đó là vị trí của nốt Sol.", "highlight": -1, "show_staff": true, "clef": true},
		{"action": "speak", "text": "Nhịp bốn phần tư nghĩa là mỗi ô nhịp có bốn phách và nốt đen được tính là một phách. Ta đếm đều: một, hai, ba, bốn. Phách một thường mạnh hơn các phách còn lại.", "highlight": -1, "show_staff": true, "time_sig": 4},
		{"action": "speak", "text": "Nhịp hai phần tư nghĩa là mỗi ô nhịp có hai phách và nốt đen cũng được tính là một phách. Ta đếm: một, hai; trong đó phách một mạnh và phách hai nhẹ hơn.", "highlight": -1, "show_staff": true, "time_sig": 2},
		{"action": "speak", "text": "Hiểu tempo và nhịp sẽ giúp chúng ta gảy đàn đúng tốc độ, đúng điểm rơi của phách. Khóa Sol giúp chúng ta đọc đúng nốt trên bản nhạc. Bây giờ, chúng ta cùng bắt đầu phần thực hành nhé!", "highlight": -1, "show_staff": true, "time_sig": 4},
		{"action": "speak", "text": "Bây giờ chúng ta cùng luyện tập theo nhịp 4/4. Ta sẽ gảy nốt Sol2, đếm 1-2-3-4 cho mỗi ô nhịp. Hãy gảy nốt Sol2.", "highlight": 0, "note": "Sol2", "time_sig": 4},
		{"action": "speak", "text": "Gảy nốt La2 giữ đều nhịp 4/4.", "highlight": 1, "note": "La2", "time_sig": 4},
		{"action": "speak", "text": "Gảy nốt Đô3 giữ đều nhịp 4/4.", "highlight": 2, "note": "Đô3", "time_sig": 4},
		{"action": "speak", "text": "Gảy nốt Rê3 giữ đều nhịp 4/4.", "highlight": 3, "note": "Rê3", "time_sig": 4},
		{"action": "speak", "text": "Tiếp tục với nhịp 4/4: nốt Mi3.", "highlight": 4, "note": "Mi3", "time_sig": 4},
		{"action": "speak", "text": "Rồi nốt Rê3, giữ nhịp đều.", "highlight": 5, "note": "Rê3", "time_sig": 4},
		{"action": "speak", "text": "Nốt Đô3, giữ nhịp đều.", "highlight": 6, "note": "Đô3", "time_sig": 4},
		{"action": "speak", "text": "Nốt La2, giữ nhịp đều.", "highlight": 7, "note": "La2", "time_sig": 4},
		{"action": "speak", "text": "Giờ chuyển sang nhịp 2/4, nhanh gọn hơn: gảy nốt Sol2.", "highlight": 8, "note": "Sol2", "time_sig": 2},
		{"action": "speak", "text": "Nốt La2 theo nhịp 2/4.", "highlight": 9, "note": "La2", "time_sig": 2},
		{"action": "speak", "text": "Nốt Đô3 theo nhịp 2/4.", "highlight": 10, "note": "Đô3", "time_sig": 2},
		{"action": "speak", "text": "Nốt Rê3 theo nhịp 2/4.", "highlight": 11, "note": "Rê3", "time_sig": 2},
		{"action": "speak", "text": "Nốt Mi3 theo nhịp 2/4.", "highlight": 12, "note": "Mi3", "time_sig": 2},
		{"action": "speak", "text": "Nốt Sol3 theo nhịp 2/4.", "highlight": 13, "note": "Sol3", "time_sig": 2},
		{"action": "speak", "text": "Nốt Rê3 theo nhịp 2/4.", "highlight": 14, "note": "Rê3", "time_sig": 2},
		{"action": "speak", "text": "Và cuối cùng nốt Đô3, giữ nhịp 2/4 thật đều.", "highlight": 15, "note": "Đô3", "time_sig": 2},
		{"action": "speak", "text": "Tuyệt vời! Tóm lại: 17 dây đàn được chia thành âm vực trầm, trung và cao; tempo là tốc độ bài nhạc; khóa Sol xác định vị trí nốt trên khuông; nhịp 4/4 có 4 phách mỗi ô và nhịp 2/4 có 2 phách mỗi ô. Bạn đã hoàn thành bài học!", "highlight": -1}
	],

	"dan_tranh_level_1_bai_5_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ cùng tìm hiểu nhịp điệu cơ bản và trường độ của nốt nhạc.", "highlight": -1},
		{"action": "speak", "text": "Trường độ là độ dài ngắn của âm thanh. Khi gảy một nốt trên đàn Tranh, chúng ta cần biết âm đó kéo dài bao lâu trước khi chuyển sang nốt tiếp theo.", "highlight": -1},
		{"action": "speak", "text": "Trong nhịp bốn phần tư, nốt trắng dài hai phách; nốt đen dài một phách; nốt móc đơn dài nửa phách và hai nốt móc đơn bằng một nốt đen.", "highlight": -1},
		{"action": "speak", "text": "Nốt móc kép dài một phần tư phách và bốn nốt móc kép bằng một nốt đen. Bạn có thể hiểu đơn giản: nốt càng nhiều móc thì âm càng ngắn và cần gảy nhanh hơn.", "highlight": -1},
		{"action": "speak", "text": "Khi chơi đàn Tranh, hãy đếm đều nhịp trong đầu. Với nốt dài, chúng ta chỉ gảy một lần rồi để tiếng đàn ngân đủ số phách, không gảy lặp lại nhiều lần. Hiểu đúng trường độ sẽ giúp bản nhạc đều nhịp, rõ ràng và dễ nghe hơn. Bây giờ, chúng ta cùng bắt đầu phần thực hành nhé!", "highlight": -1},
		{"action": "speak", "text": "Đầu tiên là Nốt Trắng. Nốt trắng có đầu hình bầu dục rỗng, có thân nốt, kéo dài 2 phách. Hãy gảy nốt Đô2 và giữ âm vang 2 phách.", "highlight": 0, "note": "Đô2", "type": "half"},
		{"action": "speak", "text": "Thêm một nốt trắng nữa. Hãy gảy nốt Đô2 và giữ 2 phách nhé.", "highlight": 1, "note": "Đô2", "type": "half"},
		{"action": "speak", "text": "Tiếp theo là Nốt Đen. Nốt đen có đầu hình bầu dục đặc, có thân nốt, kéo dài 1 phách. Hãy gảy nốt Rê2.", "highlight": 2, "note": "Rê2", "type": "quarter"},
		{"action": "speak", "text": "Gảy thêm nốt đen Mi2 – 1 phách.", "highlight": 3, "note": "Mi2", "type": "quarter"},
		{"action": "speak", "text": "Và thêm nốt đen Mi2 – 1 phách.", "highlight": 4, "note": "Mi2", "type": "quarter"},
		{"action": "speak", "text": "Gảy nốt đen Sol2 – 1 phách.", "highlight": 5, "note": "Sol2", "type": "quarter"},
		{"action": "speak", "text": "Bây giờ là Nốt Móc Đơn. Nốt móc đơn có đầu đặc, thân nốt và 1 móc, kéo dài nửa phách. Hãy gảy nhanh nốt Sol2.", "highlight": 6, "note": "Sol2", "type": "eighth"},
		{"action": "speak", "text": "Thêm nốt móc đơn Sol2 – nửa phách.", "highlight": 7, "note": "Sol2", "type": "eighth"},
		{"action": "speak", "text": "Và nốt móc đơn Sol2 – nửa phách.", "highlight": 8, "note": "Sol2", "type": "eighth"},
		{"action": "speak", "text": "Cuối cùng là Nốt Móc Kép. Nốt móc kép có đầu đặc, thân nốt và 2 móc, kéo dài một phần tư phách. Rất nhanh! Hãy gảy nốt La2.", "highlight": 9, "note": "La2", "type": "sixteenth"},
		{"action": "speak", "text": "Gảy thêm nốt móc kép La2.", "highlight": 10, "note": "La2", "type": "sixteenth"},
		{"action": "speak", "text": "Tuyệt vời! Bạn đã hoàn thành bài học nhận diện trường độ. Tóm lại: Nốt trắng bằng 2 phách, nốt đen bằng 1 phách, nốt móc đơn bằng nửa phách, nốt móc kép bằng một phần tư phách.", "highlight": -1}
	],

	"dan_tranh_level_2_bai_4_practice": [
		{"action": "speak", "text": "Chào mừng bạn học về trường độ nốt Đen (1 phách) và nốt Trắng (2 phách).", "highlight": -1},
		{"action": "speak", "text": "Nốt trắng sẽ kéo dài gấp đôi nốt đen. Hãy chú ý giữ âm vang của dây khi gảy nốt trắng nhé.", "highlight": -1}
	],

	"dan_tranh_level_2_bai_5_practice": [
		{"action": "speak", "text": "Chào mừng bạn đến với Bài 5: Hệ thống nốt cơ bản và xác định vị trí nốt trên Đàn Tranh.", "highlight": -1},
		{"action": "speak", "text": "Đàn Tranh của chúng ta có 17 dây, được lên theo thang ngũ cung: Sol - La - Đô - Rê - Mi ở các quãng khác nhau.", "highlight": -1},
		{"action": "speak", "text": "Trong âm nhạc chuẩn quốc tế có 7 nốt cơ bản: Đô, Rê, Mi, Fa, Sol, La, Si ký hiệu lần lượt là C, D, E, F, G, A, B.", "highlight": -1},
		{"action": "speak", "text": "Để chơi các nốt Fa và Si trên đàn Tranh, ta sẽ gảy các dây Mi và La tương ứng rồi dùng tay trái nhấn nhẹ dây bên trái nhạn đàn để nâng cao độ.", "highlight": -1},
		{"action": "speak", "text": "Bây giờ, chúng ta sẽ tập luyện xác định vị trí nốt. Tôi sẽ gảy trước một nốt, sau đó bạn hãy gảy lặp lại nốt đó nhé. Đầu tiên là nốt Đô 2 ở dây số 3.", "highlight": 2, "note": "Đô2"},
		{"action": "speak", "text": "Tiếp theo là nốt Rê 2 ở dây số 4.", "highlight": 3, "note": "Rê2"},
		{"action": "speak", "text": "Nốt Mi 2 ở dây số 5.", "highlight": 4, "note": "Mi2"},
		{"action": "speak", "text": "Nốt Fa 2. Hãy gảy dây Mi 2 (dây 5) và nhấn nhẹ tay trái để tạo ra cao độ nốt Fa 2 nhé.", "highlight": 4, "note": "Fa2"},
		{"action": "speak", "text": "Nốt Sol 2 ở dây số 6.", "highlight": 5, "note": "Sol2"},
		{"action": "speak", "text": "Nốt La 2 ở dây số 7.", "highlight": 6, "note": "La2"},
		{"action": "speak", "text": "Nốt Si 2. Hãy gảy dây La 2 (dây 7) và dùng tay trái nhấn để tạo ra cao độ nốt Si 2.", "highlight": 6, "note": "Si2"},
		{"action": "speak", "text": "Và nốt Đô 3 ở dây số 8.", "highlight": 7, "note": "Đô3"},
		{"action": "speak", "text": "Sau đây là thử thách Mini Game: Hãy tìm nốt Sol 2 trên đàn và chọn gảy dây tương ứng nhé!", "highlight": 5, "note": "Sol2"},
		{"action": "speak", "text": "Rất tốt! Tiếp theo là Bài 2.3: Học viên nhận biết các nốt cùng tên ở các quãng khác nhau (khác cao độ).", "highlight": -1},
		{"action": "speak", "text": "Ví dụ: Đô thấp ở dây số 3. Hãy gảy nốt Đô 2.", "highlight": 2, "note": "Đô2"},
		{"action": "speak", "text": "Đô trung ở dây số 8. Hãy gảy nốt Đô 3.", "highlight": 7, "note": "Đô3"},
		{"action": "speak", "text": "Và Đô cao ở dây số 13. Hãy gảy nốt Đô 4.", "highlight": 12, "note": "Đô4"},
		{"action": "speak", "text": "Tuyệt vời! Nhận biết nốt cùng tên ở các quãng khác nhau là kiến thức nền để học các kỹ thuật: Song thanh, Vê, Quãng, Chuyển âm vực sau này. Bây giờ hãy luyện tập chơi chuỗi nốt nhé!", "highlight": -1}
	],

	"dan_tranh_level_2_bai_6_practice": [
		{"action": "speak", "text": "Hãy làm quen với nhịp 4/4 tiêu chuẩn và khuông nhạc khóa Sol.", "highlight": -1},
		{"action": "speak", "text": "Mỗi ô nhịp có 4 phách. Hãy tập trung nghe nhịp gõ và gảy thật đều đặn.", "highlight": -1}
	],

	"dan_tranh_level_3_bai_7_practice": [
		{"action": "speak", "text": "Chào mừng đến với thử thách luyện ngón tốc độ cao với bài nhạc Mã Vũ.", "highlight": -1},
		{"action": "speak", "text": "Bạn cần gảy nhanh, dứt khoát và di chuyển ngón tay linh hoạt qua các quãng xa.", "highlight": -1}
	],

	"dan_tranh_level_4_bai_9_practice": [
		{"action": "speak", "text": "Hôm nay chúng ta sẽ học kỹ thuật nhấn Rung tay trái đặc trưng của Đàn Tranh.", "highlight": -1},
		{"action": "speak", "text": "Sau khi tay phải gảy nốt, hãy dùng các ngón tay trái nhấn nhẹ liên tục lên phần dây bên trái nhạn đàn.", "highlight": -1}
	],

	"dan_tranh_level_7_bai_19_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ cùng tìm hiểu kỹ thuật nhấn trên đàn Tranh.", "highlight": -1},
		{"action": "speak", "text": "Kỹ thuật nhấn là dùng tay trái ấn dây ở phía bên trái của nhạn để nâng cao độ của âm thanh sau khi tay phải gảy dây.", "highlight": -1},
		{"action": "speak", "text": "Nhờ kỹ thuật này, đàn Tranh có thể tạo ra những nốt không có sẵn trên dây. Ví dụ, nhấn dây La để lên nốt Si, hoặc nhấn dây Mi để lên nốt Fa.", "highlight": -1},
		{"action": "speak", "text": "Khi thực hiện, tay phải gảy dây trước, sau đó tay trái nhấn nhẹ và đều đến đúng cao độ. Không nhấn quá mạnh vì tiếng đàn có thể bị gắt hoặc cao độ bị lệch. Bây giờ, chúng ta cùng bắt đầu phần thực hành nhé!", "highlight": -1}
	],

	"dan_tranh_level_7_bai_20_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ cùng tìm hiểu kỹ thuật song thanh trên đàn Tranh.", "highlight": -1},
		{"action": "speak", "text": "Song thanh là kỹ thuật gảy để hai nốt cùng phát ra một lúc. Song thanh truyền thống thường sử dụng quãng tám; các nhạc sĩ hiện đại còn kết hợp thêm những quãng khác.", "highlight": -1},
		{"action": "speak", "text": "Có hai cách tạo song thanh cơ bản: kết hợp ngón 1 với ngón 2, hoặc kết hợp ngón 1 với ngón 3.", "highlight": -1},
		{"action": "speak", "text": "Khi thực hiện, hai tiếng phải phát ra đồng thời, không bị chênh nhau và có âm lượng cân bằng. Bây giờ, chúng ta cùng bắt đầu phần thực hành nhé!", "highlight": -1}
	],

	"dan_tranh_level_7_bai_21_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ cùng tìm hiểu kỹ thuật rung dây trên đàn Tranh.", "highlight": -1},
		{"action": "speak", "text": "Kỹ thuật rung dây tạo tiếng đàn ngân liên tục, mềm mại và giàu cảm xúc. Có hai kiểu rung chính: rung nhanh với biên độ hẹp và rung chậm với biên độ rộng. Trong bài này, chúng ta luyện kiểu rung để thể hiện nét vui của giai điệu.", "highlight": -1},
		{"action": "speak", "text": "Sau khi tay phải gảy dây, tay trái rung ngay để tiếng đàn không bị ngắt quãng. Dùng ngón trỏ và ngón giữa tay trái đặt nhẹ lên dây ở phía bên trái nhạn, cách nhạn khoảng mười xen-ti-mét. Không tỳ mạnh xuống dây vì có thể làm sai cao độ.", "highlight": -1},
		{"action": "speak", "text": "Giữ cổ tay và các ngón tay mềm mại. Dùng hai ngón tay nhồi dây nhẹ nhàng lên xuống, đều tay, để tiếng rung tự nhiên và kéo dài. Bây giờ, chúng ta cùng bắt đầu phần thực hành nhé!", "highlight": -1}
	],

	"dan_tranh_level_8_bai_30_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ cùng tìm hiểu kỹ thuật vê trên đàn Tranh.", "highlight": -1},
		{"action": "speak", "text": "Kỹ thuật vê là gảy luân phiên thật nhanh và liên tục bằng hai ngón tay phải để tạo tiếng đàn ngân dài, dày và liền mạch.", "highlight": -1},
		{"action": "speak", "text": "Có hai cách vê cơ bản. Vê một dây là hai ngón thay phiên gảy trên cùng một dây.", "highlight": -1},
		{"action": "speak", "text": "Vê quãng tám là hai ngón thay phiên gảy trên hai dây cùng tên nốt nhưng khác quãng, ví dụ nốt Đô thấp và nốt Đô cao.", "highlight": -1},
		{"action": "speak", "text": "Kỹ thuật vê thường dùng để giữ âm, làm nổi bật giai điệu và tăng cảm xúc cho câu nhạc. Bây giờ, chúng ta cùng bắt đầu phần thực hành nhé!", "highlight": -1}
	],

	"dan_tranh_level_8_bai_31_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ cùng tìm hiểu hợp âm ba âm cơ bản trên đàn Tranh.", "highlight": -1},
		{"action": "speak", "text": "Hợp âm ba âm là ba nốt khác nhau được gảy cùng lúc, tạo âm thanh đầy đặn hơn một nốt đơn.", "highlight": -1},
		{"action": "speak", "text": "Trong bài này, chúng ta làm quen với hai hợp âm cơ bản để hiểu thêm về cách hòa âm trên đàn Tranh.", "highlight": -1},
		{"action": "speak", "text": "Phần hợp âm ba âm này được học để bạn biết thêm về khả năng tạo âm thanh hợp âm của đàn Tranh; nội dung này không áp dụng vào kiến thức nhạc cụ dân tộc Việt Nam. Bây giờ, chúng ta cùng bắt đầu phần thực hành nhé!", "highlight": -1}
	],

	"dan_tranh_level_8_bai_32_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ cùng tìm hiểu hợp âm Đô trưởng.", "highlight": -1},
		{"action": "speak", "text": "Hợp âm Đô trưởng gồm ba nốt: Đô, Mi và Sol.", "highlight": -1},
		{"action": "speak", "text": "Khi gảy, hãy cố gắng để cả ba nốt vang lên cùng lúc và có âm lượng cân bằng. Bây giờ, chúng ta cùng bắt đầu phần thực hành nhé!", "highlight": -1}
	],

	"dan_tranh_level_8_bai_33_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ cùng tìm hiểu hợp âm La thứ.", "highlight": -1},
		{"action": "speak", "text": "Hợp âm La thứ gồm ba nốt: La, Đô và Mi.", "highlight": -1},
		{"action": "speak", "text": "Hợp âm này có màu sắc nhẹ nhàng và trầm hơn hợp âm Đô trưởng. Bây giờ, chúng ta cùng bắt đầu phần thực hành nhé!", "highlight": -1}
	],

	"dan_tranh_level_5_bai_12_practice": [
		{"action": "speak", "text": "Thử thách độc tấu trọn vẹn tác phẩm Sứ Thanh Hoa!", "highlight": -1},
		{"action": "speak", "text": "Hãy kết hợp toàn bộ kỹ thuật tay phải gảy ngón và nhấn rung tay trái để hoàn thành bài nhạc xuất sắc nhất.", "highlight": -1}
	]
}

const SU_THANH_HOA_SHEET: Array[String] = [
	"Rê3", "Đô3", "La2", "Đô3", "Đô3", "La2", "Đô3", "Đô3", "La2", "Đô3", "La2", "Sol2",
	"Rê3", "Đô3", "La2", "Đô3", "Đô3", "La2", "Đô3", "Đô3", "Mi3", "Rê3", "Đô3", "Sol2", "La2", "Mi3",
	"Mi3", "Rê3", "Mi3", "Rê3", "Mi3", "Sol3", "Mi3", "Rest", "Mi3", "Mi3", "Rê3",
	"Đô3", "Mi3", "Rê3", "Rê3", "Đô3", "La2", "Đô3", "Đô3", "La2", "Đô3",
	"La2", "Sol2", "Sol2", "La2", "Mi3", "Sol3", "Sol3", "Mi3", "Sol3", "Sol3", "Mi3", "Rê3", "Đô3", "Đô3",
	"Rê3", "Đô3", "Rê3", "Mi3", "Rê3", "Rê3", "Đô3", "Rê3", "Đô3", "Rê3", "Đô3", "Đô3", "La2", "Đô3", "Rê3", "Rê3", "Rê3"
]

const SU_THANH_HOA_DURATIONS: Array[float] = [
	0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5, 2.0,
	0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5,
	0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 1.0, 0.5, 0.5, 2.0,
	0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 3.0,
	1.0, 1.0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5,
	0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 2.0
]

const NOTE_TO_STRING = {
	"Sol1": 0, "La1": 1, "Đô2": 2, "Rê2": 3, "Mi2": 4, "Fa2": 4,
	"Sol2": 5, "La2": 6, "Si2": 6, "Đô3": 7, "Rê3": 8, "Mi3": 9, "Fa3": 9,
	"Sol3": 10, "La3": 11, "Si3": 11, "Đô4": 12, "Rê4": 13, "Mi4": 14,
	"Sol4": 15, "La4": 16
}

const NOTE_FREQS = {
	"Sol1": 196.00, "La1": 220.00, "Đô2": 261.63, "Rê2": 293.66, "Mi2": 329.63,
	"Fa2": 349.23, "Sol2": 392.00, "La2": 440.00, "Si2": 493.88, "Đô3": 523.25,
	"Rê3": 587.33, "Mi3": 659.25, "Fa3": 698.46, "Sol3": 783.99, "La3": 880.00,
	"Si3": 987.77, "Đô4": 1046.50, "Rê4": 1174.66, "Mi4": 1318.51, "Sol4": 1567.98,
	"La4": 1760.00
}

func _ready():
	# The lesson covers every real string from Sol1 (196 Hz) to La4 (1760 Hz).
	# Fa/Si are produced by pressing Mi/La (same string, raised pitch) — keep them
	# in the profile so nhấn (press) exercises can be scored by pitch.
	var profile_script = load("res://scripts/InstrumentPitchProfile.gd")
	var profile = profile_script.new()
	var profile_notes: Array[String] = [
		"Sol1", "La1", "Đô2", "Rê2", "Mi2", "Fa2",
		"Sol2", "La2", "Si2", "Đô3", "Rê3", "Mi3", "Fa3",
		"Sol3", "La3", "Si3", "Đô4", "Rê4", "Mi4", "Sol4", "La4"
	]
	profile.notes.assign(profile_notes)
	var freqs: Array[float] = []
	var mappings: Array[int] = []
	for n in profile_notes:
		freqs.append(NOTE_FREQS[n])
		mappings.append(NOTE_TO_STRING[n])
	profile.frequencies = PackedFloat32Array(freqs)
	profile.physical_mappings = mappings
	profile.min_frequency = 180.0
	profile.max_frequency = 1900.0
	profile.volume_threshold_db = -58.0
	# A phone microphone and a real đàn tranh can drift more than a synthesized
	# reference. ±60 cents still keeps adjacent pentatonic strings well apart.
	profile.cents_tolerance = 60.0
	profile.hold_time_sec = 0.20
	profile.is_plucked_instrument = true
	
	analyzer.pitch_profile = profile
	
	analyzer.min_frequency = 180.0
	analyzer.max_frequency = 1900.0
	analyzer.volume_threshold_db = -58.0
	if not analyzer.dan_tranh_note_started.is_connected(_on_dan_tranh_note_started):
		analyzer.dan_tranh_note_started.connect(_on_dan_tranh_note_started)
	if not analyzer.dan_tranh_rapid_attack.is_connected(_on_dan_tranh_rapid_attack):
		analyzer.dan_tranh_rapid_attack.connect(_on_dan_tranh_rapid_attack)
	current_lesson_id = SecureDataManager.active_lesson_id
	if not current_lesson_id or current_lesson_id == "":
		current_lesson_id = "dan_tranh_level_1_bai_1_practice"
	# The selector sets this flag immediately before opening the Á lesson. The
	# title fallback also supports direct scene testing without stale lesson data.
	if force_glissando_start or PracticeRoom.current_song_title.begins_with(LEVEL_7_GLISSANDO_TITLE):
		current_lesson_id = LEVEL_7_GLISSANDO_ID
		force_glissando_start = false
		
	if not PracticeRoom.current_song_sheet.is_empty():
		lesson_sheet.assign(PracticeRoom.current_song_sheet)
		lesson_durations.assign(current_song_durations)
	else:
		# Fallback defaults for direct testing/debug
		if current_lesson_id == "dan_tranh_level_1_bai_1_practice":
			var intro_5 = ["Sol1", "La1", "Đô2", "Rê2", "Mi2"]
			lesson_sheet.assign(intro_5)
			var d_arr: Array[float] = []
			for i in range(intro_5.size()):
				d_arr.append(1.5)
			lesson_durations.assign(d_arr)
		elif current_lesson_id == "dan_tranh_level_1_bai_2_practice":
			var intro_10 = ["Sol1", "La1", "Đô2", "Rê2", "Mi2", "Sol2", "La2", "Đô3", "Rê3", "Mi3"]
			lesson_sheet.assign(intro_10)
			var d_arr: Array[float] = []
			for i in range(intro_10.size()):
				d_arr.append(1.5)
			lesson_durations.assign(d_arr)
		elif current_lesson_id == "dan_tranh_level_1_bai_4_practice":
			var tempo_sheet: Array[String] = [
				"Sol2", "La2", "Đô3", "Rê3",
				"Mi3", "Rê3", "Đô3", "La2",
				"Sol2", "La2", "Đô3", "Rê3",
				"Mi3", "Sol3", "Rê3", "Đô3"
			]
			lesson_sheet.assign(tempo_sheet)
			lesson_durations.assign([1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0])
		elif current_lesson_id == "dan_tranh_level_1_bai_5_practice":
			var dur_sheet: Array[String] = ["Đô2", "Đô2", "Rê2", "Mi2", "Mi2", "Sol2", "Sol2", "Sol2", "Sol2", "La2", "La2"]
			lesson_sheet.assign(dur_sheet)
			var dur_arr: Array[float] = [2.0, 2.0, 1.0, 1.0, 1.0, 1.0, 0.5, 0.5, 0.5, 0.25, 0.25]
			lesson_durations.assign(dur_arr)
		elif current_lesson_id == "dan_tranh_level_3_bai_17_practice":
			var press_sheet: Array[String] = ["Mi2", "Fa2", "La2", "Si2", "Mi3", "Fa3", "La3", "Si3"]
			lesson_sheet.assign(press_sheet)
			lesson_durations.assign([1.0, 1.5, 1.0, 1.5, 1.0, 1.5, 1.0, 2.0])
		elif current_lesson_id == "dan_tranh_level_3_bai_19_practice":
			var oct_sheet: Array[String] = ["Sol1+Sol2", "La1+La2", "Đô2+Đô3", "Rê2+Rê3", "Mi2+Mi3", "Sol2+Sol3", "La2+La3", "Đô3+Đô4"]
			lesson_sheet.assign(oct_sheet)
			lesson_durations.assign([1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 2.0])
		elif current_lesson_id == "dan_tranh_level_2_bai_15_practice":
			lesson_sheet.assign(SU_THANH_HOA_SHEET)
			lesson_durations.assign(SU_THANH_HOA_DURATIONS)
		else:
			lesson_sheet.assign(ALL_17_NOTES)
			var d_arr: Array[float] = []
			for i in range(ALL_17_NOTES.size()):
				d_arr.append(1.5)
			lesson_durations.assign(d_arr)

	
	staff_display = load("res://scripts/StaffDisplay.gd").new()
	staff_display.name = "StaffDisplay"
	
	# Calculate dynamic line spacing based on the note range of this lesson to make it as large and beautiful as possible
	var min_pos = 99.0
	var max_pos = -99.0
	for note in lesson_sheet:
		var pos = staff_display.NOTE_POSITIONS.get("ZT_" + note, staff_display.NOTE_POSITIONS.get(note, 0.0))
		if pos < min_pos: min_pos = pos
		if pos > max_pos: max_pos = pos
	
	var optimal_spacing = 65.0
	if max_pos > min_pos:
		var span = max_pos - min_pos
		if span > 4.0:
			optimal_spacing = clampf(520.0 / (span + 2.0), 50.0, 70.0)
	staff_display.line_spacing = optimal_spacing
	
	ai_audio = load("res://scripts/AIAudioManager.gd").new()
	ai_audio.name = "AIAudio"
	add_child(ai_audio)
	ai_audio.tts_started.connect(_on_teacher_tts_started)
	ai_audio.tts_finished.connect(_on_teacher_tts_finished)
	
	if teacher_char and _tex_mai_talk_sheet:
		_teacher_atlas = AtlasTexture.new()
		_teacher_atlas.atlas = _tex_mai_talk_sheet
		teacher_char.texture = _teacher_atlas
		_update_teacher_frame()
	staff_card = PanelContainer.new()
	staff_card.name = "StaffCard"
	staff_card.anchor_left = 0.0; staff_card.anchor_right = 1.0
	staff_card.offset_left = 55; staff_card.offset_right = -55
	staff_card.offset_top = 195; staff_card.offset_bottom = 675
	staff_card.clip_contents = true
	var card_sb = StyleBoxFlat.new()
	card_sb.bg_color = Color(0.995, 0.98, 0.93, 0.96)
	card_sb.border_color = Color(0.88, 0.72, 0.38, 1.0)
	card_sb.border_width_left = 3; card_sb.border_width_right = 3; card_sb.border_width_top = 3; card_sb.border_width_bottom = 3
	card_sb.corner_radius_top_left = 18; card_sb.corner_radius_top_right = 18; card_sb.corner_radius_bottom_left = 18; card_sb.corner_radius_bottom_right = 18
	card_sb.shadow_color = Color(0.45, 0.30, 0.12, 0.25); card_sb.shadow_size = 14; card_sb.shadow_offset = Vector2(0, 6)
	staff_card.add_theme_stylebox_override("panel", card_sb)
	add_child(staff_card)
	move_child(staff_card, get_node("Root").get_index())
	
	staff_card.add_child(staff_display)
	staff_display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	staff_display.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if _is_glissando_practice():
		_build_glissando_sheet()
	if _is_press_practice():
		_build_press_sheet_hud()
	if _is_vibrato_practice():
		_build_vibrato_sheet_hud()
	if _is_tremolo_practice():
		_build_tremolo_sheet_hud()
	# Build the visual layer for every lesson. Only lesson 99+ drives it from an
	# automatic timer; real lessons call it after a validated scoring error.
	_build_error_flash_overlay()
	
	_update_staff_layout()
	get_viewport().size_changed.connect(_update_staff_layout)
	staff_card.visible = false
	staff_display.visible = true
	
	var string_notes: Array[String] = ["Sol1", "La1", "Đô2", "Rê2", "Mi2", "Sol2", "La2", "Đô3", "Rê3", "Mi3", "Sol3", "La3", "Đô4", "Rê4", "Mi4", "Sol4", "La4"]
	var string_freqs: Array[float] = [196.00, 220.00, 261.63, 293.66, 329.63, 392.00, 440.00, 523.25, 587.33, 659.25, 783.99, 880.00, 1046.50, 1174.66, 1318.51, 1567.98, 1760.00]
	dan_tranh_string_streams.clear()
	dan_tranh_string_streams.resize(17)
	for i in range(17):
		dan_tranh_string_streams[i] = _generate_pluck_stream(string_freqs[i])
	zither_board.init(string_notes, dan_tranh_string_streams, string_freqs)
	technique_sample_player = AudioStreamPlayer.new()
	technique_sample_player.name = "TechniqueSamplePlayer"
	technique_sample_player.bus = "Master"
	technique_sample_player.volume_db = -3.0
	add_child(technique_sample_player)
	zither_board.visible = false
	
	# Giữ form và nút thực hành giống màn hướng dẫn của Sáo.
	var mode_buttons = teacher_area.get_node_or_null("DialogBox/M/V/ModeButtons")
	if mode_buttons:
		mode_buttons.visible = true
		
	# Style và định vị Giảng viên cùng Khung chat ở giữa màn hình (Lớn hơn)
	var dialog_sb = StyleBoxFlat.new()
	dialog_sb.bg_color = Color(0.95, 0.95, 0.95, 0.95)
	dialog_sb.corner_radius_top_left = 30; dialog_sb.corner_radius_top_right = 30
	dialog_sb.corner_radius_bottom_left = 30; dialog_sb.corner_radius_bottom_right = 30
	dialog_sb.border_width_top = 4; dialog_sb.border_width_bottom = 4
	dialog_sb.border_width_left = 4; dialog_sb.border_width_right = 4
	dialog_sb.border_color = C_GOLD
	
	_setup_top_pitch_box()
	_setup_pitch_hud_box()
	dialog_sb.shadow_color = Color(0, 0, 0, 0.15)
	dialog_sb.shadow_size = 12
	dialog_sb.shadow_offset = Vector2(0, 6)
	
	var dialog_box = $TeacherArea/DialogBox
	dialog_box.add_theme_stylebox_override("panel", dialog_sb)
	speech_text.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1, 1.0))
	var practice_button_style := StyleBoxFlat.new()
	practice_button_style.bg_color = C_GOLD
	practice_button_style.corner_radius_top_left = 15
	practice_button_style.corner_radius_top_right = 15
	practice_button_style.corner_radius_bottom_left = 15
	practice_button_style.corner_radius_bottom_right = 15
	real_mode_btn.text = "  Thực Hành Ngay  "
	real_mode_btn.add_theme_stylebox_override("normal", practice_button_style)
	real_mode_btn.add_theme_stylebox_override("hover", practice_button_style)
	real_mode_btn.add_theme_stylebox_override("pressed", practice_button_style)
	if not real_mode_btn.pressed.is_connected(_on_practice_now_pressed):
		real_mode_btn.pressed.connect(_on_practice_now_pressed)
	
	var teacher_char = $TeacherArea/TeacherChar
	
	var update_teacher_layout = func():
		var vp_size = get_viewport().get_visible_rect().size
		if vp_size.x < 1100:
			# Dành cho màn hình hẹp (mobile dọc): xếp dọc, phóng lớn
			teacher_char.anchor_left = 0.5; teacher_char.anchor_right = 0.5
			teacher_char.anchor_top = 0.5; teacher_char.anchor_bottom = 0.5
			teacher_char.offset_left = -180
			teacher_char.offset_right = 180
			teacher_char.offset_top = -340
			teacher_char.offset_bottom = 0
			dialog_box.anchor_left = 0.5; dialog_box.anchor_right = 0.5
			dialog_box.anchor_top = 0.5; dialog_box.anchor_bottom = 0.5
			dialog_box.offset_left = -300
			dialog_box.offset_right = 300
			dialog_box.offset_top = 20
			dialog_box.offset_bottom = 260
		else:
			# Sao chép đúng bố cục desktop/landscape của màn Sáo.
			teacher_char.anchor_left = 0.0; teacher_char.anchor_right = 0.0
			teacher_char.anchor_top = 1.0; teacher_char.anchor_bottom = 1.0
			teacher_char.offset_left = 20
			teacher_char.offset_right = 520
			teacher_char.offset_top = -800
			teacher_char.offset_bottom = 50
			dialog_box.anchor_left = 0.0; dialog_box.anchor_right = 0.0
			dialog_box.anchor_top = 1.0; dialog_box.anchor_bottom = 1.0
			dialog_box.offset_left = 460
			dialog_box.offset_right = 1400
			dialog_box.offset_top = -650
			dialog_box.offset_bottom = -250
		speech_text.add_theme_font_size_override("font_size", 32 if vp_size.x >= 1100 else 26)
			
	get_viewport().size_changed.connect(update_teacher_layout)
	update_teacher_layout.call()
	
	zither_board.string_plucked.connect(_on_string_plucked)
	
	# Tạo các nút HUD và Action bằng TextureRect + Shader để tùy biến màu sắc trắng/vàng kim thẩm mỹ
	back_btn.visible = false
	var custom_back_btn = _create_hud_icon_btn("res://icons8/icons8-back-100.png", _on_back)
	add_child(custom_back_btn)
	back_btn = custom_back_btn
	
	back_btn.anchor_left = 0.0; back_btn.anchor_right = 0.0
	back_btn.anchor_top = 0.0; back_btn.anchor_bottom = 0.0
	
	var update_back_btn_pos = func():
		back_btn.offset_left = 40
		back_btn.offset_right = 108  # Rộng 68px
		back_btn.offset_top = 24
		back_btn.offset_bottom = 92 # Cao 68px
	get_viewport().size_changed.connect(update_back_btn_pos)
	update_back_btn_pos.call()
	
	complete_btn.visible = false
	var custom_complete_btn = _create_aesthetic_btn(
		"Hoàn Thành", 
		"res://icons8/icons8-play-100.png", 
		true, 
		C_WOOD, 
		C_WOOD.lightened(0.12), 
		Color.WHITE, 
		C_GOLD, 
		16, 
		Vector2(200, 52)
	)
	add_child(custom_complete_btn)
	complete_btn = custom_complete_btn
	
	# Định vị complete_btn ở cạnh dưới căn giữa
	complete_btn.anchor_left = 0.5; complete_btn.anchor_right = 0.5
	complete_btn.anchor_top = 1.0; complete_btn.anchor_bottom = 1.0
	complete_btn.grow_horizontal = Control.GROW_DIRECTION_BOTH
	complete_btn.grow_vertical = Control.GROW_DIRECTION_BEGIN
	
	var update_complete_pos = func():
		complete_btn.offset_left = -100
		complete_btn.offset_right = 100
		complete_btn.offset_top = -120
		complete_btn.offset_bottom = -68
	get_viewport().size_changed.connect(update_complete_pos)
	update_complete_pos.call()
	
	complete_btn.pressed.connect(_on_complete)
	
	_create_pause_system()
	_create_skip_intro_button()
	
	if _should_have_speed_control():
		_create_speed_control_bar()
		
	is_challenge_mode = SecureDataManager.data.get("is_challenge_mode", false)
	if _is_error_flash_demo():
		# Do not show the shared welcome / audio-calibration lesson screen.
		# The automatic error demo opens directly into the staff exercise.
		call_deferred("_start_practice")
	else:
		# Technique Á reads cô Mai's theory before opening its three exercises.
		_start_intro()

func _build_glissando_sheet() -> void:
	glissando_sheet = Control.new()
	glissando_sheet.name = "GlissandoSheetHUD"
	glissando_sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	staff_card.add_child(glissando_sheet)
	glissando_sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var header_panel := PanelContainer.new()
	header_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_panel.anchor_left = 0.5
	header_panel.anchor_right = 0.5
	header_panel.offset_left = -410.0
	header_panel.offset_right = 410.0
	header_panel.offset_top = 18.0
	header_panel.offset_bottom = 105.0
	var header_style := StyleBoxFlat.new()
	header_style.bg_color = Color(1.0, 0.98, 0.91, 0.94)
	header_style.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.72)
	header_style.border_width_left = 2
	header_style.border_width_right = 2
	header_style.border_width_top = 2
	header_style.border_width_bottom = 2
	header_style.corner_radius_top_left = 14
	header_style.corner_radius_top_right = 14
	header_style.corner_radius_bottom_left = 14
	header_style.corner_radius_bottom_right = 14
	header_panel.add_theme_stylebox_override("panel", header_style)
	glissando_sheet.add_child(header_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 9)
	header_panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 2)
	margin.add_child(content)
	var title_row := HBoxContainer.new()
	content.add_child(title_row)
	glissando_instruction_label = Label.new()
	glissando_instruction_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	glissando_instruction_label.add_theme_color_override("font_color", C_JADE)
	glissando_instruction_label.add_theme_font_size_override("font_size", 21)
	var bold_font := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if bold_font:
		glissando_instruction_label.add_theme_font_override("font", bold_font)
	title_row.add_child(glissando_instruction_label)
	glissando_progress_label = Label.new()
	glissando_progress_label.add_theme_color_override("font_color", C_JADE)
	glissando_progress_label.add_theme_font_size_override("font_size", 15)
	title_row.add_child(glissando_progress_label)

	glissando_status_label = Label.new()
	glissando_status_label.text = "Micro đang nghe đàn thật..."
	glissando_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glissando_status_label.add_theme_color_override("font_color", Color(0.30, 0.26, 0.20, 0.92))
	glissando_status_label.add_theme_font_size_override("font_size", 14)
	content.add_child(glissando_status_label)
	glissando_progress_bar = ProgressBar.new()
	glissando_progress_bar.max_value = 17.0
	glissando_progress_bar.show_percentage = false
	glissando_progress_bar.custom_minimum_size = Vector2(0, 7)
	content.add_child(glissando_progress_bar)

func _build_vibrato_sheet_hud() -> void:
	# PanelContainer stretches every direct Control child to its full content area.
	# Keep the compact HUD inside a neutral full-size layer so its bottom anchors
	# are respected instead of letting its cream panel cover the whole staff.
	var hud_layer := Control.new()
	hud_layer.name = "VibratoHUDLayer"
	hud_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	staff_card.add_child(hud_layer)
	hud_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	vibrato_sheet_hud = PanelContainer.new()
	vibrato_sheet_hud.name = "VibratoSheetHUD"
	vibrato_sheet_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vibrato_sheet_hud.anchor_left = 0.5
	vibrato_sheet_hud.anchor_right = 0.5
	vibrato_sheet_hud.anchor_top = 1.0
	vibrato_sheet_hud.anchor_bottom = 1.0
	vibrato_sheet_hud.offset_left = -430.0
	vibrato_sheet_hud.offset_right = 430.0
	vibrato_sheet_hud.offset_top = -98.0
	vibrato_sheet_hud.offset_bottom = -18.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(1.0, 0.98, 0.91, 0.95)
	panel_style.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.72)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 14
	panel_style.corner_radius_top_right = 14
	panel_style.corner_radius_bottom_left = 14
	panel_style.corner_radius_bottom_right = 14
	vibrato_sheet_hud.add_theme_stylebox_override("panel", panel_style)
	hud_layer.add_child(vibrato_sheet_hud)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	vibrato_sheet_hud.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 2)
	margin.add_child(content)
	vibrato_instruction_label = Label.new()
	vibrato_instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vibrato_instruction_label.add_theme_color_override("font_color", C_JADE)
	vibrato_instruction_label.add_theme_font_size_override("font_size", 18)
	var bold_font := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if bold_font:
		vibrato_instruction_label.add_theme_font_override("font", bold_font)
	content.add_child(vibrato_instruction_label)
	vibrato_status_label = Label.new()
	vibrato_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vibrato_status_label.add_theme_color_override("font_color", Color(0.30, 0.26, 0.20, 0.92))
	vibrato_status_label.add_theme_font_size_override("font_size", 14)
	content.add_child(vibrato_status_label)
	vibrato_progress_bar = ProgressBar.new()
	vibrato_progress_bar.max_value = float(VIBRATO_NOTES.size())
	vibrato_progress_bar.show_percentage = false
	vibrato_progress_bar.custom_minimum_size = Vector2(0, 6)
	content.add_child(vibrato_progress_bar)

func _build_press_sheet_hud() -> void:
	# Use an intermediate layer for the same reason as the vibrato HUD: adding
	# the compact panel directly to StaffCard makes PanelContainer expand it and
	# its opaque background washes out the notes underneath.
	var hud_layer := Control.new()
	hud_layer.name = "PressHUDLayer"
	hud_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	staff_card.add_child(hud_layer)
	hud_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	press_sheet_hud = PanelContainer.new()
	press_sheet_hud.name = "PressSheetHUD"
	press_sheet_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	press_sheet_hud.anchor_left = 0.5
	press_sheet_hud.anchor_right = 0.5
	press_sheet_hud.anchor_top = 1.0
	press_sheet_hud.anchor_bottom = 1.0
	press_sheet_hud.offset_left = -440.0
	press_sheet_hud.offset_right = 440.0
	press_sheet_hud.offset_top = -98.0
	press_sheet_hud.offset_bottom = -18.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(1.0, 0.98, 0.91, 0.95)
	panel_style.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.72)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 14
	panel_style.corner_radius_top_right = 14
	panel_style.corner_radius_bottom_left = 14
	panel_style.corner_radius_bottom_right = 14
	press_sheet_hud.add_theme_stylebox_override("panel", panel_style)
	hud_layer.add_child(press_sheet_hud)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	press_sheet_hud.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 2)
	margin.add_child(content)
	press_instruction_label = Label.new()
	press_instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	press_instruction_label.add_theme_color_override("font_color", C_JADE)
	press_instruction_label.add_theme_font_size_override("font_size", 18)
	var bold_font := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if bold_font:
		press_instruction_label.add_theme_font_override("font", bold_font)
	content.add_child(press_instruction_label)
	press_status_label = Label.new()
	press_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	press_status_label.add_theme_color_override("font_color", Color(0.30, 0.26, 0.20, 0.92))
	press_status_label.add_theme_font_size_override("font_size", 14)
	content.add_child(press_status_label)
	press_progress_bar = ProgressBar.new()
	press_progress_bar.max_value = float(PRESS_EXERCISES.size())
	press_progress_bar.show_percentage = false
	press_progress_bar.custom_minimum_size = Vector2(0, 6)
	content.add_child(press_progress_bar)

func _build_tremolo_sheet_hud() -> void:
	var hud_layer := Control.new()
	hud_layer.name = "TremoloHUDLayer"
	hud_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	staff_card.add_child(hud_layer)
	hud_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	tremolo_sheet_hud = PanelContainer.new()
	tremolo_sheet_hud.name = "TremoloSheetHUD"
	tremolo_sheet_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tremolo_sheet_hud.anchor_left = 0.5
	tremolo_sheet_hud.anchor_right = 0.5
	tremolo_sheet_hud.anchor_top = 1.0
	tremolo_sheet_hud.anchor_bottom = 1.0
	tremolo_sheet_hud.offset_left = -450.0
	tremolo_sheet_hud.offset_right = 450.0
	tremolo_sheet_hud.offset_top = -102.0
	tremolo_sheet_hud.offset_bottom = -18.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(1.0, 0.98, 0.91, 0.96)
	panel_style.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.76)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 14
	panel_style.corner_radius_top_right = 14
	panel_style.corner_radius_bottom_left = 14
	panel_style.corner_radius_bottom_right = 14
	tremolo_sheet_hud.add_theme_stylebox_override("panel", panel_style)
	hud_layer.add_child(tremolo_sheet_hud)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	tremolo_sheet_hud.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 2)
	margin.add_child(content)
	tremolo_instruction_label = Label.new()
	tremolo_instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tremolo_instruction_label.add_theme_color_override("font_color", C_JADE)
	tremolo_instruction_label.add_theme_font_size_override("font_size", 18)
	var bold_font := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if bold_font:
		tremolo_instruction_label.add_theme_font_override("font", bold_font)
	content.add_child(tremolo_instruction_label)
	tremolo_status_label = Label.new()
	tremolo_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tremolo_status_label.add_theme_color_override("font_color", Color(0.30, 0.26, 0.20, 0.92))
	tremolo_status_label.add_theme_font_size_override("font_size", 14)
	content.add_child(tremolo_status_label)
	tremolo_progress_bar = ProgressBar.new()
	tremolo_progress_bar.max_value = float(TREMOLO_EXERCISES.size())
	tremolo_progress_bar.show_percentage = false
	tremolo_progress_bar.custom_minimum_size = Vector2(0, 6)
	content.add_child(tremolo_progress_bar)


func _build_error_flash_overlay() -> void:
	error_flash_overlay = Control.new()
	error_flash_overlay.name = "ErrorFlashOverlay"
	error_flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	staff_card.add_child(error_flash_overlay)
	error_flash_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	error_flash_overlay.modulate.a = 1.0

	error_flash_halo = PanelContainer.new()
	error_flash_halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	error_flash_halo.custom_minimum_size = Vector2(86, 68)
	var halo_style := StyleBoxFlat.new()
	halo_style.bg_color = Color(0.96, 0.20, 0.20, 0.10)
	halo_style.border_color = Color(1.0, 0.30, 0.28, 0.86)
	halo_style.border_width_left = 3
	halo_style.border_width_right = 3
	halo_style.border_width_top = 3
	halo_style.border_width_bottom = 3
	halo_style.corner_radius_top_left = 34
	halo_style.corner_radius_top_right = 34
	halo_style.corner_radius_bottom_left = 34
	halo_style.corner_radius_bottom_right = 34
	halo_style.shadow_color = Color(0.96, 0.12, 0.12, 0.26)
	halo_style.shadow_size = 12
	(error_flash_halo as PanelContainer).add_theme_stylebox_override("panel", halo_style)
	error_flash_overlay.add_child(error_flash_halo)
	error_flash_halo.pivot_offset = Vector2(43.0, 34.0)
	error_flash_halo.modulate.a = 0.0

	var error_tooltip := PanelContainer.new()
	error_flash_badge = error_tooltip
	error_tooltip.name = "ErrorNoteTooltip"
	error_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	error_tooltip.custom_minimum_size = Vector2(300.0, 92.0)
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(0.39, 0.075, 0.085, 0.98)
	badge_style.border_color = Color(0.93, 0.73, 0.28, 0.98)
	badge_style.set_border_width_all(2)
	badge_style.corner_radius_top_left = 16
	badge_style.corner_radius_top_right = 16
	badge_style.corner_radius_bottom_left = 16
	badge_style.corner_radius_bottom_right = 16
	badge_style.shadow_color = Color(0.10, 0.02, 0.02, 0.32)
	badge_style.shadow_size = 12
	badge_style.shadow_offset = Vector2(0.0, 6.0)
	error_tooltip.add_theme_stylebox_override("panel", badge_style)
	error_flash_overlay.add_child(error_tooltip)
	error_tooltip.size = Vector2(300.0, 92.0)
	error_tooltip.pivot_offset = Vector2(150.0, 92.0)
	error_tooltip.modulate.a = 0.0

	var tooltip_margin := MarginContainer.new()
	tooltip_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_margin.add_theme_constant_override("margin_left", 20)
	tooltip_margin.add_theme_constant_override("margin_top", 12)
	tooltip_margin.add_theme_constant_override("margin_right", 20)
	tooltip_margin.add_theme_constant_override("margin_bottom", 12)
	error_tooltip.add_child(tooltip_margin)
	tooltip_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var text_box := VBoxContainer.new()
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.alignment = BoxContainer.ALIGNMENT_CENTER
	text_box.add_theme_constant_override("separation", 2)
	tooltip_margin.add_child(text_box)

	var bold_font := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	var regular_font := load("res://assets/fonts/BeVietnamPro-Regular.ttf") as Font
	error_flash_title_label = Label.new()
	error_flash_title_label.text = "Chưa đúng"
	error_flash_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_flash_title_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55, 1.0))
	error_flash_title_label.add_theme_font_size_override("font_size", 20)
	if bold_font:
		error_flash_title_label.add_theme_font_override("font", bold_font)
	text_box.add_child(error_flash_title_label)

	error_flash_detail_label = Label.new()
	error_flash_detail_label.text = "Cần gảy: Sol₂"
	error_flash_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_flash_detail_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	error_flash_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	error_flash_detail_label.max_lines_visible = 2
	error_flash_detail_label.add_theme_color_override("font_color", Color(1.0, 0.97, 0.91, 1.0))
	error_flash_detail_label.add_theme_font_size_override("font_size", 15)
	if regular_font:
		error_flash_detail_label.add_theme_font_override("font", regular_font)
	text_box.add_child(error_flash_detail_label)

	# Hai tam giác chồng nhau tạo mũi chỉ đỏ có viền vàng, nối tooltip với nốt sai.
	var pointer_border := Polygon2D.new()
	pointer_border.polygon = PackedVector2Array([Vector2(-12.0, -1.0), Vector2(12.0, -1.0), Vector2(0.0, 15.0)])
	pointer_border.color = Color(0.93, 0.73, 0.28, 0.98)
	pointer_border.position = Vector2(150.0, 92.0)
	error_tooltip.add_child(pointer_border)
	var pointer_fill := Polygon2D.new()
	pointer_fill.polygon = PackedVector2Array([Vector2(-8.5, -2.0), Vector2(8.5, -2.0), Vector2(0.0, 10.5)])
	pointer_fill.color = badge_style.bg_color
	pointer_fill.position = Vector2(150.0, 92.0)
	error_tooltip.add_child(pointer_fill)

	error_feedback_player = AudioStreamPlayer.new()
	error_feedback_player.name = "ErrorFeedbackPlayer"
	error_feedback_player.volume_db = -20.0
	error_feedback_player.stream = _generate_error_feedback_stream()
	add_child(error_feedback_player)


func _is_glissando_practice() -> bool:
	return current_lesson_id == LEVEL_7_GLISSANDO_ID

func _is_press_practice() -> bool:
	return current_lesson_id == LEVEL_7_PRESS_ID

func _is_vibrato_practice() -> bool:
	return current_lesson_id == LEVEL_7_VIBRATO_ID

func _is_tremolo_practice() -> bool:
	return current_lesson_id == LEVEL_8_TREMOLO_ID


func _is_micro_scoring_blocked() -> bool:
	if _micro_scoring_locked:
		return true
	return analyzer != null and bool(analyzer.get("analysis_suspended"))


func _uses_mobile_audio_fallback() -> bool:
	return force_mobile_audio_fallback_for_tests \
		or (analyzer != null and analyzer.has_method("is_mobile_fallback") \
		and bool(analyzer.call("is_mobile_fallback")))


func _on_teacher_tts_started() -> void:
	# Invalidate any pending resume from an earlier sentence or interrupted TTS.
	_tts_resume_token += 1
	_set_micro_scoring_locked(true)


func _on_teacher_tts_finished() -> void:
	_tts_resume_token += 1
	var resume_token := _tts_resume_token
	get_tree().create_timer(TTS_MIC_RESUME_DELAY_SEC).timeout.connect(func() -> void:
		if not is_inside_tree() or resume_token != _tts_resume_token:
			return
		_set_micro_scoring_locked(false)
	)


func _set_micro_scoring_locked(locked: bool) -> void:
	_micro_scoring_locked = locked
	if locked:
		_clear_partial_micro_attempts()
	if analyzer and analyzer.has_method("set_analysis_suspended"):
		analyzer.set_analysis_suspended(locked)
	if mic_status_lbl:
		if locked:
			mic_status_lbl.text = "🔇 Tạm dừng nghe khi cô Mai đang nói..."
			mic_status_lbl.add_theme_color_override("font_color", Color(0.70, 0.45, 0.08, 1.0))
		else:
			mic_status_lbl.text = "🎙️ Đang nghe đàn thật..."
			mic_status_lbl.add_theme_color_override("font_color", Color(0.24, 0.56, 0.35, 1.0))


func _clear_partial_micro_attempts() -> void:
	var interrupted_attack_generation := _get_current_technique_attack_generation()
	time_correct = 0.0
	wrong_note_time = 0.0
	glissando_detected_strings.clear()
	glissando_detected_times.clear()
	glissando_detected_generations.clear()
	glissando_last_detection_time = 0.0
	press_cents_history.clear()
	press_sample_accumulator = 0.0
	press_attempt_elapsed = 0.0
	press_silence_elapsed = 0.0
	press_target_hold_elapsed = 0.0
	press_base_note_heard = false
	press_max_cents = 0.0
	press_attack_generation = -1
	press_consumed_attack_generation = interrupted_attack_generation
	press_contour_elapsed = 0.0
	press_min_amplitude_db = 0.0
	press_added_sound_elapsed = 0.0
	vibrato_pitch_history.clear()
	vibrato_sample_accumulator = 0.0
	vibrato_attempt_elapsed = 0.0
	vibrato_silence_elapsed = 0.0
	vibrato_base_note_heard = false
	vibrato_attack_generation = -1
	vibrato_consumed_attack_generation = interrupted_attack_generation
	vibrato_contour_elapsed = 0.0
	vibrato_min_amplitude_db = 0.0
	vibrato_added_sound_elapsed = 0.0
	tremolo_attack_strings.clear()
	tremolo_attack_times.clear()
	tremolo_attack_generations.clear()
	tremolo_attempt_started_at = 0.0
	tremolo_last_attack_at = 0.0
	tremolo_last_seen_generation = -1
	tremolo_wrong_attacks = 0


func _is_technique_sample_practice() -> bool:
	return _is_glissando_practice() or _is_press_practice() or _is_vibrato_practice() or _is_tremolo_practice()


func _is_error_flash_demo() -> bool:
	return current_lesson_id == ERROR_FLASH_DEMO_ID


func _uses_chord_lesson_flow() -> bool:
	# Các bài kỹ thuật kế thừa cùng luồng: tập từng hợp âm trước, rồi vào khuông nhạc.
	return current_lesson_id in [
		"dan_tranh_level_7_bai_20_practice",
		"dan_tranh_level_8_bai_31_practice",
		"dan_tranh_level_8_bai_32_practice",
		"dan_tranh_level_8_bai_33_practice"
	]


func _uses_chord_basics_lesson_flow() -> bool:
	return current_lesson_id == "dan_tranh_level_8_bai_31_practice"


func _setup_top_pitch_box():
	var l_title = "LUYỆN ĐÀN TRANH"
	var active_id = SecureDataManager.active_lesson_id
	if active_id:
		if active_id == ERROR_FLASH_DEMO_ID: l_title = "BÀI 22: DEMO PHẢN HỒI SAI"
		elif active_id == LEVEL_7_GLISSANDO_ID: l_title = "BÀI 10: KỸ THUẬT Á"
		elif active_id == LEVEL_7_PRESS_ID: l_title = "BÀI 11: KỸ THUẬT NHẤN"
		elif active_id == LEVEL_7_VIBRATO_ID: l_title = "BÀI 13: KỸ THUẬT RUNG DÂY"
		elif "bai1" in active_id: l_title = "BÀI 1: NỐT CƠ BẢN"
		elif "bai2" in active_id: l_title = "BÀI 2: KỸ THUẬT GẢY"
		elif "bai3" in active_id: l_title = "BÀI 3: HỢP ÂM"
		elif "bai4" in active_id: l_title = "BÀI 4: KẾT HỢP"
		elif "bai5" in active_id: l_title = "BÀI 5: NÂNG CAO"

	title_plaque = PanelContainer.new()
	title_plaque.name = "TitlePlaque"
	title_plaque.anchor_left = 0.5; title_plaque.anchor_right = 0.5
	title_plaque.offset_left = -250; title_plaque.offset_right = 250
	title_plaque.offset_top = 32; title_plaque.offset_bottom = 120
	var tp_sb = StyleBoxFlat.new()
	tp_sb.bg_color = Color(0.24, 0.16, 0.10, 0.95)
	tp_sb.border_color = Color(0.88, 0.72, 0.38, 1.0)
	tp_sb.border_width_left = 3; tp_sb.border_width_right = 3; tp_sb.border_width_top = 3; tp_sb.border_width_bottom = 3
	tp_sb.corner_radius_top_left = 16; tp_sb.corner_radius_top_right = 16; tp_sb.corner_radius_bottom_left = 16; tp_sb.corner_radius_bottom_right = 16
	tp_sb.shadow_color = Color(0.15, 0.10, 0.05, 0.4); tp_sb.shadow_size = 10; tp_sb.shadow_offset = Vector2(0, 4)
	title_plaque.add_theme_stylebox_override("panel", tp_sb)
	
	var pl_vbox = VBoxContainer.new()
	pl_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	pl_vbox.add_theme_constant_override("separation", 2)
	title_plaque.add_child(pl_vbox)
	
	var lbl_num = Label.new()
	lbl_num.text = "BÀI LUYỆN"
	lbl_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_num.add_theme_color_override("font_color", Color(0.92, 0.82, 0.60, 1.0))
	lbl_num.add_theme_font_size_override("font_size", 20)
	pl_vbox.add_child(lbl_num)
	
	var lbl_main = Label.new()
	lbl_main.text = "🌿   " + l_title + "   🌿"
	lbl_main.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_main.add_theme_color_override("font_color", Color(0.98, 0.84, 0.40, 1.0))
	lbl_main.add_theme_font_size_override("font_size", 34)
	pl_vbox.add_child(lbl_main)
	add_child(title_plaque)
	
	pill_badge = PanelContainer.new()
	pill_badge.name = "NotePillBadge"
	pill_badge.anchor_left = 0.5; pill_badge.anchor_right = 0.5
	pill_badge.offset_left = -125; pill_badge.offset_right = 125
	pill_badge.offset_top = 172; pill_badge.offset_bottom = 220
	var pill_sb = StyleBoxFlat.new()
	pill_sb.bg_color = Color(1.0, 0.99, 0.95, 1.0)
	pill_sb.border_color = Color(0.88, 0.70, 0.35, 1.0)
	pill_sb.border_width_left = 2; pill_sb.border_width_right = 2; pill_sb.border_width_top = 2; pill_sb.border_width_bottom = 2
	pill_sb.corner_radius_top_left = 24; pill_sb.corner_radius_top_right = 24; pill_sb.corner_radius_bottom_left = 24; pill_sb.corner_radius_bottom_right = 24
	pill_sb.shadow_color = Color(0.3, 0.2, 0.08, 0.2); pill_sb.shadow_size = 6; pill_sb.shadow_offset = Vector2(0, 3)
	pill_badge.add_theme_stylebox_override("panel", pill_sb)
	
	var pill_lbl = Label.new()
	pill_lbl.text = "🌿    ĐÀN TRANH    🌿"
	pill_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pill_lbl.add_theme_color_override("font_color", Color(0.78, 0.55, 0.18, 1.0))
	pill_lbl.add_theme_font_size_override("font_size", 26)
	pill_badge.add_child(pill_lbl)
	add_child(pill_badge)
	
	sub_instr_row = HBoxContainer.new()
	sub_instr_row.name = "SubInstrRow"
	sub_instr_row.anchor_left = 0.0; sub_instr_row.anchor_right = 1.0
	sub_instr_row.offset_left = 90; sub_instr_row.offset_right = -90
	sub_instr_row.offset_top = 698; sub_instr_row.offset_bottom = 738
	sub_instr_row.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var line_left_cont = CenterContainer.new()
	line_left_cont.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var line_l = ColorRect.new()
	line_l.custom_minimum_size = Vector2(240, 2)
	line_l.color = Color(0.85, 0.68, 0.35, 0.75)
	line_left_cont.add_child(line_l)
	sub_instr_row.add_child(line_left_cont)
	
	var sub_lbl = Label.new()
	sub_lbl.text = "   🌿   Gảy đúng dây và lắng nghe âm thanh   🌿   "
	sub_lbl.add_theme_color_override("font_color", Color(0.45, 0.30, 0.15, 1.0))
	sub_lbl.add_theme_font_size_override("font_size", 26)
	sub_instr_row.add_child(sub_lbl)
	
	var line_right_cont = CenterContainer.new()
	line_right_cont.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var line_r = ColorRect.new()
	line_r.custom_minimum_size = Vector2(240, 2)
	line_r.color = Color(0.85, 0.68, 0.35, 0.75)
	line_right_cont.add_child(line_r)
	sub_instr_row.add_child(line_right_cont)
	
	add_child(sub_instr_row)
	
	title_plaque.visible = false
	pill_badge.visible = false
	sub_instr_row.visible = false

func _setup_pitch_hud_box():
	# 1. Position and resize the FeedbackArea container to dock in the empty top-left space (next to the Back button)
	if feedback_area:
		feedback_area.custom_minimum_size = Vector2(320, 160)
		feedback_area.offset_left = 200
		feedback_area.offset_right = 520
		feedback_area.offset_top = 20
		feedback_area.offset_bottom = 180
		feedback_area.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		feedback_area.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	# 2. Hide the volume bar (thanh lực âm thanh) completely
	if volume_bar:
		volume_bar.visible = false

	# 3. Create the unified feedback card (pitch_box)
	pitch_box = PanelContainer.new()
	pitch_box.name = "PitchBox"
	pitch_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pitch_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Premium lacquer card styling matching the traditional zither theme
	var pb_style = StyleBoxFlat.new()
	pb_style.bg_color = Color(0.995, 0.985, 0.96, 0.97) # Aged Parchment / Cream
	pb_style.border_color = Color(0.88, 0.72, 0.38, 0.7) # Soft gold rim
	pb_style.border_width_left = 2; pb_style.border_width_right = 2
	pb_style.border_width_top = 2; pb_style.border_width_bottom = 2
	pb_style.corner_radius_top_left = 16; pb_style.corner_radius_top_right = 16
	pb_style.corner_radius_bottom_left = 16; pb_style.corner_radius_bottom_right = 16
	pb_style.shadow_color = Color(0.18, 0.12, 0.06, 0.12)
	pb_style.shadow_size = 6
	pb_style.shadow_offset = Vector2(0, 3)
	pitch_box.add_theme_stylebox_override("panel", pb_style)
	
	var pb_margin = MarginContainer.new()
	pb_margin.add_theme_constant_override("margin_left", 16)
	pb_margin.add_theme_constant_override("margin_right", 16)
	pb_margin.add_theme_constant_override("margin_top", 10)
	pb_margin.add_theme_constant_override("margin_bottom", 10)
	pitch_box.add_child(pb_margin)
	
	var pb_vbox = VBoxContainer.new()
	pb_vbox.add_theme_constant_override("separation", 6)
	pb_margin.add_child(pb_vbox)
	
	# Reparent MicStatus label into the unified feedback card for cohesive look
	var mic_lbl = feedback_area.get_node_or_null("MicStatus") as Label
	if mic_lbl:
		feedback_area.remove_child(mic_lbl)
		pb_vbox.add_child(mic_lbl)
		mic_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mic_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		mic_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		mic_lbl.add_theme_font_size_override("font_size", 16)
		mic_lbl.custom_minimum_size = Vector2(0, 36) # Compact space for 2-line instructions
		
		# Divider line below the instruction
		var divider = ColorRect.new()
		divider.custom_minimum_size = Vector2(0, 1)
		divider.color = Color(0.88, 0.72, 0.38, 0.3)
		pb_vbox.add_child(divider)
	
	# Pitch note label
	pitch_note_lbl = Label.new()
	pitch_note_lbl.text = "🎵 Nốt: ---"
	pitch_note_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pitch_note_lbl.add_theme_color_override("font_color", Color(0.28, 0.16, 0.10, 1.0))
	var f_bold = load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if f_bold: pitch_note_lbl.add_theme_font_override("font", f_bold)
	pitch_note_lbl.add_theme_font_size_override("font_size", 18)
	pb_vbox.add_child(pitch_note_lbl)
	
	# Pitch status label
	pitch_status_lbl = Label.new()
	pitch_status_lbl.text = "🎙️ Đang nghe..."
	pitch_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pitch_status_lbl.add_theme_color_override("font_color", Color(0.45, 0.35, 0.25, 1.0))
	pitch_status_lbl.add_theme_font_size_override("font_size", 14)
	pb_vbox.add_child(pitch_status_lbl)
	
	# Pitch meter (needle drawing)
	pitch_meter = PitchMeterDraw.new()
	pitch_meter.name = "PitchMeter"
	pitch_meter.custom_minimum_size = Vector2(0, 20)
	pb_vbox.add_child(pitch_meter)
	
	if feedback_area:
		feedback_area.add_child(pitch_box)

func _process(delta):
	# Update teacher talking animation
	if ai_audio and is_instance_valid(ai_audio.audio_player):
		_portrait_is_talking = ai_audio.audio_player.is_playing()
	else:
		_portrait_is_talking = false
		
	if _portrait_is_talking:
		_portrait_frame_elapsed += delta
		if _portrait_frame_elapsed >= PORTRAIT_FRAME_DURATION:
			_portrait_frame_elapsed = 0.0
			_portrait_frame = (_portrait_frame + 1) % PORTRAIT_FRAME_COUNT
			_update_teacher_frame()
	elif _portrait_frame != 0:
		_portrait_frame = 0
		_update_teacher_frame()

	if is_paused:
		return
	technique_sample_input_cooldown = maxf(0.0, technique_sample_input_cooldown - delta)
	if current_state == State.PRACTICE_SINGLE:
		_process_practice_single(delta)
	elif current_state == State.PRACTICE:
		if is_sample_mode and _is_technique_sample_practice():
			_process_technique_sample(delta)
		elif technique_sample_input_cooldown > 0.0 and _is_technique_sample_practice():
			pass
		elif _is_error_flash_demo():
			_process_error_demo_sheet(delta)
			_process_error_flash_demo(delta)
		elif _is_glissando_practice():
			_process_glissando_practice()
		elif _is_press_practice():
			_process_press_practice(delta)
		elif _is_vibrato_practice():
			_process_vibrato_practice(delta)
		elif _is_tremolo_practice():
			_process_tremolo_practice()
		else:
			_process_practice(delta)
	
	_update_continuous_pitch_hud(delta)


func _process_error_flash_demo(delta: float) -> void:
	error_flash_timer -= delta
	if error_flash_timer <= 0.0:
		error_flash_timer = 3.6
		_play_error_flash_demo()


func _process_error_demo_sheet(delta: float) -> void:
	if active_falling_notes.is_empty():
		return
	if error_feedback_showing:
		staff_display.set_notes(active_falling_notes)
		return
	var all_offscreen := true
	for note in active_falling_notes:
		note["x"] = float(note.get("x", 0.0)) - 180.0 * delta
		if float(note["x"]) > -100.0:
			all_offscreen = false
	if all_offscreen:
		_start_practice()
		return
	staff_display.set_notes(active_falling_notes)


func _play_error_flash_demo() -> void:
	error_feedback_target_note = ""
	error_feedback_title = "Chưa đúng"
	error_feedback_detail = ""
	_play_error_flash_effect()


func _show_practice_error_feedback(
	target_note: String,
	detail: String,
	title: String = "Chưa đúng"
) -> void:
	if _is_error_flash_demo() or current_state == State.COMPLETED:
		return
	if error_feedback_showing:
		return
	error_feedback_target_note = target_note
	error_feedback_title = title
	error_feedback_detail = detail
	_play_error_flash_effect()


func _play_error_flash_effect() -> void:
	if not error_flash_overlay or not staff_display:
		return
	if error_flash_tween and error_flash_tween.is_running():
		error_flash_tween.kill()
	if error_pulse_tween and error_pulse_tween.is_running():
		error_pulse_tween.kill()
	if error_shake_tween and error_shake_tween.is_running():
		error_shake_tween.kill()
	_set_error_demo_note_color(false)

	_set_error_demo_note_color(true)
	if error_flash_note.is_empty():
		error_feedback_showing = false
		return
	error_feedback_showing = true
	_position_error_flash_feedback()
	error_flash_overlay.modulate.a = 1.0
	error_flash_badge.position = error_tooltip_final_position + Vector2(0.0, 38.0)
	error_flash_badge.scale = Vector2(0.84, 0.84)
	error_flash_badge.modulate.a = 0.0
	error_flash_halo.scale = Vector2(0.78, 0.78)
	error_flash_halo.modulate.a = 0.0
	if error_feedback_player:
		error_feedback_player.play()

	# Tooltip bật lên từ nốt, nảy rất nhẹ rồi đứng yên đủ lâu để học viên đọc.
	error_flash_tween = create_tween()
	error_flash_tween.set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	error_flash_tween.tween_property(error_flash_badge, "position", error_tooltip_final_position, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	error_flash_tween.parallel().tween_property(error_flash_badge, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	error_flash_tween.parallel().tween_property(error_flash_badge, "scale", Vector2(1.04, 1.04), 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	error_flash_tween.tween_property(error_flash_badge, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	error_flash_tween.tween_interval(1.25)
	error_flash_tween.tween_property(error_flash_badge, "modulate:a", 0.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	error_flash_tween.parallel().tween_property(error_flash_badge, "position", error_tooltip_final_position + Vector2(0.0, 12.0), 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	error_flash_tween.parallel().tween_property(error_flash_badge, "scale", Vector2(0.94, 0.94), 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	error_flash_tween.parallel().tween_property(error_flash_halo, "modulate:a", 0.0, 0.18)
	error_flash_tween.tween_callback(_finish_error_flash_demo)

	# Hai nhịp sáng mềm quanh đúng một nốt, không chớp đỏ cả màn hình.
	error_pulse_tween = create_tween()
	error_pulse_tween.tween_property(error_flash_halo, "modulate:a", 0.78, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	error_pulse_tween.parallel().tween_property(error_flash_halo, "scale", Vector2(1.06, 1.06), 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	error_pulse_tween.tween_callback(_set_error_demo_note_pulse.bind(true))
	error_pulse_tween.tween_property(error_flash_halo, "modulate:a", 0.26, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	error_pulse_tween.parallel().tween_property(error_flash_halo, "scale", Vector2(0.96, 0.96), 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	error_pulse_tween.tween_callback(_set_error_demo_note_pulse.bind(false))
	error_pulse_tween.tween_property(error_flash_halo, "modulate:a", 0.70, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	error_pulse_tween.parallel().tween_property(error_flash_halo, "scale", Vector2(1.03, 1.03), 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	error_pulse_tween.tween_callback(_set_error_demo_note_pulse.bind(true))
	error_pulse_tween.tween_property(error_flash_halo, "modulate:a", 0.24, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	error_pulse_tween.parallel().tween_property(error_flash_halo, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	error_pulse_tween.tween_callback(_set_error_demo_note_pulse.bind(false))
	error_pulse_tween.tween_callback(_restore_error_demo_hit_line)

	# Rung ngang rất ngắn lúc lỗi vừa xuất hiện.
	error_shake_tween = create_tween()
	error_shake_tween.tween_callback(_offset_error_demo_note.bind(-3.5))
	error_shake_tween.tween_interval(0.045)
	error_shake_tween.tween_callback(_offset_error_demo_note.bind(3.5))
	error_shake_tween.tween_interval(0.045)
	error_shake_tween.tween_callback(_offset_error_demo_note.bind(-2.0))
	error_shake_tween.tween_interval(0.045)
	error_shake_tween.tween_callback(_offset_error_demo_note.bind(0.0))


func _finish_error_flash_demo() -> void:
	_set_error_demo_note_color(false)
	error_feedback_showing = false
	error_feedback_target_note = ""
	error_feedback_title = "Chưa đúng"
	error_feedback_detail = ""
	if error_flash_badge:
		error_flash_badge.modulate.a = 0.0
	if error_flash_halo:
		error_flash_halo.modulate.a = 0.0


func _offset_error_demo_note(offset_x: float) -> void:
	if error_flash_note.is_empty():
		return
	error_flash_note["x"] = float(error_flash_note.get("demo_base_x", error_flash_note.get("x", 0.0))) + offset_x
	staff_display.queue_redraw()


func _position_error_flash_feedback() -> void:
	if error_flash_note.is_empty() or not error_flash_badge or not error_flash_halo:
		return
	var note_x := float(error_flash_note.get("x", staff_display.hit_line_x))
	var raw_note := str(error_flash_note.get("note", "ZT_Sol2")).replace("ZT_", "")
	var mapped_note := raw_note
	if raw_note.length() > 1 and raw_note.right(1).is_valid_int():
		mapped_note = raw_note.left(-1) + "_" + raw_note.right(1)
	var note_position := float(staff_display.NOTE_POSITIONS.get(mapped_note, 1.0))
	var note_y: float = float(staff_display.size.y) * 0.5 + float(staff_display.line_spacing) * 0.45
	note_y += (2.0 - note_position) * staff_display.line_spacing

	error_flash_halo.position = Vector2(note_x - 43.0, note_y - 34.0)
	error_flash_halo.size = Vector2(86.0, 68.0)
	var badge_x := clampf(note_x - 150.0, 12.0, maxf(12.0, staff_display.size.x - 312.0))
	var badge_y := clampf(note_y - 119.0, 12.0, maxf(12.0, staff_display.size.y - 112.0))
	error_tooltip_final_position = Vector2(badge_x, badge_y)
	error_flash_badge.position = error_tooltip_final_position
	error_flash_badge.size = Vector2(300.0, 92.0)
	if error_flash_title_label:
		error_flash_title_label.text = error_feedback_title
	if error_flash_detail_label:
		if not error_feedback_detail.is_empty():
			error_flash_detail_label.text = error_feedback_detail
		else:
			error_flash_detail_label.text = "Cần gảy: " + _format_note_for_feedback(raw_note)


func _format_note_for_feedback(raw_note: String) -> String:
	if raw_note.length() <= 1 or not raw_note.right(1).is_valid_int():
		return raw_note
	var octave := raw_note.right(1)
	var subscripts := {"0": "₀", "1": "₁", "2": "₂", "3": "₃", "4": "₄", "5": "₅", "6": "₆", "7": "₇", "8": "₈", "9": "₉"}
	return raw_note.left(-1) + str(subscripts.get(octave, octave))


func _set_error_demo_note_pulse(bright: bool) -> void:
	if error_flash_note.is_empty():
		return
	error_flash_note["color"] = Color(1.0, 0.31, 0.27, 1.0) if bright else Color(0.88, 0.12, 0.14, 1.0)
	staff_display.queue_redraw()


func _restore_error_demo_hit_line() -> void:
	staff_display.hit_line_color = Color(0.2, 0.85, 0.3, 0.95)
	staff_display.hit_line_glow_color = Color(0.3, 0.9, 0.4, 0.3)
	staff_display.queue_redraw()


func _set_error_demo_note_color(show_error: bool) -> void:
	if not show_error:
		if not error_flash_note.is_empty():
			error_flash_note["color"] = error_flash_note.get("demo_base_color", Color(0.6, 0.6, 0.6, 0.9))
			error_flash_note["x"] = error_flash_note.get("demo_base_x", error_flash_note.get("x", 0.0))
			error_flash_note.erase("demo_base_color")
			error_flash_note.erase("demo_base_x")
			error_flash_note = {}
		staff_display.hit_line_color = Color(0.2, 0.85, 0.3, 0.95)
		staff_display.hit_line_glow_color = Color(0.3, 0.9, 0.4, 0.3)
		staff_display.queue_redraw()
		return

	var candidate_notes: Array = active_falling_notes
	if candidate_notes.is_empty() and staff_display.get("notes_to_draw") is Array:
		candidate_notes = staff_display.get("notes_to_draw")
	var target_components := error_feedback_target_note.split("+")
	var closest_note: Dictionary = {}
	var closest_distance := INF
	for note in candidate_notes:
		if note.get("hit", false) or note.get("missed", false):
			continue
		var clean_note := str(note.get("note", "")).replace("ZT_", "")
		if not error_feedback_target_note.is_empty() and clean_note not in target_components:
			continue
		var distance := absf(float(note.get("x", 0.0)) - staff_display.hit_line_x)
		if distance < closest_distance:
			closest_distance = distance
			closest_note = note
	if closest_note.is_empty() and not error_feedback_target_note.is_empty():
		for note in candidate_notes:
			if note.get("hit", false) or note.get("missed", false):
				continue
			var distance := absf(float(note.get("x", 0.0)) - staff_display.hit_line_x)
			if distance < closest_distance:
				closest_distance = distance
				closest_note = note
	if closest_note.is_empty():
		return
	error_flash_note = closest_note
	error_flash_note["demo_base_color"] = error_flash_note.get("color", Color(0.6, 0.6, 0.6, 0.9))
	error_flash_note["demo_base_x"] = error_flash_note.get("x", 0.0)
	error_flash_note["color"] = Color(0.96, 0.10, 0.13, 1.0)
	staff_display.hit_line_color = Color(0.96, 0.10, 0.13, 1.0)
	staff_display.hit_line_glow_color = Color(1.0, 0.16, 0.18, 0.34)
	staff_display.queue_redraw()

func _update_teacher_frame() -> void:
	if not _teacher_atlas or not _tex_mai_talk_sheet:
		return
	var frame_width := _tex_mai_talk_sheet.get_width() / float(PORTRAIT_SHEET_COLUMNS)
	var frame_height := _tex_mai_talk_sheet.get_height() / float(PORTRAIT_SHEET_ROWS)
	var source_rect := Rect2(
		float(_portrait_frame % PORTRAIT_SHEET_COLUMNS) * frame_width,
		float(_portrait_frame / PORTRAIT_SHEET_COLUMNS) * frame_height,
		frame_width,
		frame_height
	)
	_teacher_atlas.region = source_rect

func _update_continuous_pitch_hud(delta: float = 0.016):
	if not analyzer:
		return
	if _is_micro_scoring_blocked():
		unrecognized_audio_elapsed = 0.0
		if volume_bar:
			volume_bar.value = 0.0
		if pitch_note_lbl:
			pitch_note_lbl.text = "🎵 Nốt: ---"
		if pitch_status_lbl:
			pitch_status_lbl.text = "🔇 Tạm dừng nghe khi cô Mai đang nói"
			pitch_status_lbl.add_theme_color_override("font_color", Color(0.70, 0.45, 0.08, 1.0))
		if pitch_meter:
			pitch_meter.is_active = false
			pitch_meter.queue_redraw()
		return

	# Do not describe an empty iOS/Xogot capture stream as an unclear musical
	# note. This status tells testers that the failure happens before pitch or
	# đàn-tranh timbre recognition.
	var microphone_capture_status := str(analyzer.get("microphone_capture_status"))
	if microphone_capture_status in ["no_frames", "silent_stream"]:
		unrecognized_audio_elapsed = 0.0
		if volume_bar:
			volume_bar.value = 0.0
		if pitch_note_lbl:
			pitch_note_lbl.text = "🎵 Nốt: ---"
		if pitch_status_lbl:
			pitch_status_lbl.text = (
				"🔴 Luồng micro đang im lặng trên iOS/Xogot"
				if microphone_capture_status == "silent_stream"
				else "🔴 Không nhận được dữ liệu micro từ iOS/Xogot"
			)
			pitch_status_lbl.add_theme_color_override("font_color", Color(0.90, 0.22, 0.18, 1.0))
		if mic_status_lbl:
			mic_status_lbl.text = (
				"Có frame nhưng không có tín hiệu · kiểm tra audio session của Xogot"
				if microphone_capture_status == "silent_stream"
				else "Micro không có frame âm thanh · hãy đóng/mở lại Xogot"
			)
			mic_status_lbl.add_theme_color_override("font_color", Color(0.90, 0.22, 0.18, 1.0))
		if pitch_meter:
			pitch_meter.is_active = false
			pitch_meter.queue_redraw()
		return

	# Cập nhật thanh lực âm thanh (VolumeBar) theo thời gian thực
	if volume_bar:
		var db : float = analyzer.current_amplitude_db
		var threshold : float = analyzer.volume_threshold_db
		var val := 0.0
		if db > threshold:
			var max_expected_db := -10.0
			val = clampf((db - threshold) / (max_expected_db - threshold), 0.0, 1.0)
		volume_bar.value = val

	if not pitch_box or not pitch_box.visible:
		return
		
	var db: float = analyzer.current_amplitude_db
	var pitch: float = analyzer.current_pitch
	var has_valid_pluck := true
	if analyzer.has_method("has_recent_dan_tranh_attack"):
		has_valid_pluck = analyzer.has_recent_dan_tranh_attack()

	if db <= analyzer.volume_threshold_db:
		unrecognized_audio_elapsed = 0.0
		if mic_cooldown <= 0.0 and wrong_note_cooldown <= 0.0:
			if pitch_note_lbl: pitch_note_lbl.text = "🎵 Nốt: ---"
			if pitch_status_lbl:
				pitch_status_lbl.text = "🎙️ Đang chờ bạn gảy đàn..."
				pitch_status_lbl.add_theme_color_override("font_color", Color(0.9, 0.88, 0.78))
			if pitch_meter:
				pitch_meter.is_active = false
				pitch_meter.queue_redraw()
		return

	if pitch <= 0.0 or not has_valid_pluck:
		unrecognized_audio_elapsed += maxf(delta, 0.0)
		if mic_cooldown <= 0.0 and wrong_note_cooldown <= 0.0:
			if pitch_note_lbl: pitch_note_lbl.text = "🎵 Nốt: ---"
			if pitch_status_lbl:
				if unrecognized_audio_elapsed >= UNRECOGNIZED_AUDIO_HINT_DELAY:
					pitch_status_lbl.text = "🟡 Chưa nghe rõ tiếng đàn · hãy gảy lại gần micro"
					pitch_status_lbl.add_theme_color_override("font_color", Color(0.80, 0.55, 0.12, 1.0))
				else:
					pitch_status_lbl.text = "🎙️ Đang nhận diện tiếng đàn..."
					pitch_status_lbl.add_theme_color_override("font_color", Color(0.9, 0.88, 0.78))
			if pitch_meter:
				pitch_meter.is_active = false
				pitch_meter.queue_redraw()
		return

	unrecognized_audio_elapsed = 0.0

	# Use the stabilized pitch first; re-analyzing the rolling buffer can report a stale lower octave.
	var det_name := _get_closest_dan_tranh_note_name(pitch)
	if det_name == "":
		var note_info: Dictionary = analyzer.detect_dan_tranh_note(
			analyzer._analysis_buffer,
			AudioServer.get_mix_rate()
		)
		det_name = note_info.get("note_name", "None")

	if det_name != "None" and det_name != "":
		if pitch_note_lbl: pitch_note_lbl.text = "🎵 Nốt: " + det_name
	
	# Determine target frequency to calculate cents error
	var current_target_hz = 0.0
	if current_state == State.PRACTICE_SINGLE and single_practice_idx < unique_practice_notes.size():
		var t_n = unique_practice_notes[single_practice_idx].split("+")[0]
		current_target_hz = NOTE_FREQS.get(t_n, 0.0)
	elif current_state == State.PRACTICE:
		for note in active_falling_notes:
			if not note.get("hit", false):
				var clean_n = note["note"].replace("ZT_", "").split("+")[0]
				current_target_hz = NOTE_FREQS.get(clean_n, 0.0)
				break
				
	if current_target_hz > 0.0 and pitch > 0.0:
		var raw_cents = 1200.0 * log(pitch / current_target_hz) / log(2.0)
		var cents_meter = raw_cents
		while cents_meter > 600.0: cents_meter -= 1200.0
		while cents_meter < -600.0: cents_meter += 1200.0
		var target_note_name := ""
		if current_state == State.PRACTICE_SINGLE and single_practice_idx < unique_practice_notes.size():
			target_note_name = unique_practice_notes[single_practice_idx].split("+")[0]
		elif current_state == State.PRACTICE:
			for note in active_falling_notes:
				if not note.get("hit", false):
					target_note_name = note["note"].replace("ZT_", "").split("+")[0]
					break
		var robust_match := _is_pitch_match_robust(current_target_hz, target_note_name, pitch)
		
		if pitch_meter:
			pitch_meter.current_cents = 0.0 if robust_match else cents_meter
			pitch_meter.is_active = true
			pitch_meter.queue_redraw()
			
		# Update status label real-time continuously using robust pitch matching.
		if robust_match:
			if pitch_status_lbl:
				pitch_status_lbl.text = "🟢 CHÍNH XÁC!"
				pitch_status_lbl.add_theme_color_override("font_color", Color(0.25, 0.95, 0.45))
		elif raw_cents < -35.0:
			if pitch_status_lbl:
				pitch_status_lbl.text = "🔴 THẤP HƠN (%.0f cents)" % raw_cents
				pitch_status_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))
		else:
			if pitch_status_lbl:
				pitch_status_lbl.text = "🔴 CAO HƠN (+%.0f cents)" % raw_cents
				pitch_status_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))

func _get_closest_dan_tranh_note_name(freq: float) -> String:
	if freq <= 0.0: return ""
	var best_name = ""
	var min_c = 999.0
	for n in ALL_17_NOTES:
		var ref_f = NOTE_FREQS.get(n, 0.0)
		if ref_f > 0.0:
			var c = abs(1200.0 * log(freq / ref_f) / log(2.0))
			if c < min_c:
				min_c = c
				best_name = n
	return best_name if min_c <= 150.0 else ""

func _get_spectrum_band_db(center_hz: float, width_ratio: float = 0.025) -> float:
	if not analyzer or analyzer.get("_spectrum") == null or center_hz <= 0.0:
		return -80.0
	var spec = analyzer.get("_spectrum") as AudioEffectSpectrumAnalyzerInstance
	var magnitude = spec.get_magnitude_for_frequency_range(
		center_hz * (1.0 - width_ratio),
		center_hz * (1.0 + width_ratio)
	).length()
	return 20.0 * log(magnitude) / log(10) if magnitude > 0.0001 else -80.0

func _has_clear_spectrum_peak(center_hz: float, min_db: float) -> bool:
	if center_hz <= 0.0:
		return false
	var main_db := _get_spectrum_band_db(center_hz)
	if main_db < min_db:
		return false
	var semitone_ratio := pow(2.0, 1.0 / 24.0)
	var lower_db := _get_spectrum_band_db(center_hz / semitone_ratio)
	var upper_db := _get_spectrum_band_db(center_hz * semitone_ratio)
	return main_db >= lower_db + 2.0 and main_db >= upper_db + 2.0

func _is_pitch_match_robust(target_hz: float, target_note_name: String, pitch: float) -> bool:
	if target_hz <= 0.0 or pitch <= 0.0:
		return false

	var cents_error := absf(1200.0 * log(pitch / target_hz) / log(2.0))
	if cents_error <= 65.0:
		return true

	# Dây thấp (Sol1=196Hz, La1=220Hz): YIN thường bắt harmonic thứ 2 (×2 freq).
	# Khi pitch ≈ 2×target và target < 260Hz, chấp nhận là đúng dây vì context bài
	# học luôn chỉ yêu cầu 1 dây cụ thể tại một thời điểm.
	if target_hz < 260.0 and pitch > 0.0:
		var octave_cents := absf(1200.0 * log(pitch / (target_hz * 2.0)) / log(2.0))
		if octave_cents <= 65.0:
			return true

	# Dùng native detector như phép đo tần số thứ 2 cho cùng nốt đó.
	if analyzer and target_note_name != "":
		var detected_note: Dictionary = analyzer.detect_dan_tranh_note(
			analyzer._analysis_buffer,
			AudioServer.get_mix_rate()
		)
		var detected_frequency: float = detected_note.get("frequency", 0.0)
		if detected_note.get("note_name", "None") == target_note_name and detected_frequency > 0.0:
			var detected_cents := absf(1200.0 * log(detected_frequency / target_hz) / log(2.0))
			return detected_cents <= 65.0

	return false

func _is_harmonic_or_octave_of_target(det_note: String, det_idx: int, target_note: String, target_idx: int) -> bool:
	# Each đàn tranh string is distinct; matching the note root in another octave is incorrect.
	return det_note == target_note and det_idx == target_idx

func _start_calibration_state() -> void:
	current_state = State.CALIBRATION
	teacher_area.visible = true
	feedback_area.visible = true
	complete_btn.visible = false
	staff_display.visible = false
	if staff_card: staff_card.visible = false
	if title_plaque: title_plaque.visible = false
	if pill_badge: pill_badge.visible = false
	if sub_instr_row: sub_instr_row.visible = false
	if pitch_box:
		pitch_box.visible = true
	
	if mic_status_lbl:
		mic_status_lbl.text = "🎙️ Đang đo nhiễu nền..."
		mic_status_lbl.add_theme_color_override("font_color", Color(0.95, 0.72, 0.18))
	
	var msg = "Chào bạn! Hãy giữ im lặng trong 2 giây để tôi đo tiếng ồn nền của phòng nhé..."
	speech_text.text = msg
	if ai_audio:
		ai_audio.speak_vietnamese(msg)
		
	analyzer.start_calibration()
	get_tree().create_timer(2.2).timeout.connect(func():
		var db = analyzer.finish_calibration()
		if mic_status_lbl:
			mic_status_lbl.text = "🟢 Đã hiệu chuẩn: %.1f dB" % db
			mic_status_lbl.add_theme_color_override("font_color", Color(0.25, 0.95, 0.45))
		
		var cal_msg = "Xong! Tiếng nền ở mức %.1f dB. Tôi đã tối ưu hóa micro." % db
		speech_text.text = cal_msg
		if ai_audio:
			ai_audio.speak_vietnamese(cal_msg)
			
		get_tree().create_timer(2.0).timeout.connect(func():
			_start_intro()
		)
	)

func _start_intro():
	current_state = State.INTRO
	intro_step = 0
	teacher_area.visible = true
	feedback_area.visible = false
	complete_btn.visible = false
	staff_display.visible = false
	if staff_card: staff_card.visible = false
	if title_plaque: title_plaque.visible = false
	if pill_badge: pill_badge.visible = false
	if sub_instr_row: sub_instr_row.visible = false
	if speed_bar_container:
		speed_bar_container.visible = false
	if skip_intro_btn:
		skip_intro_btn.visible = true
	if previous_intro_btn:
		previous_intro_btn.visible = true
	if pause_btn:
		pause_btn.visible = false
	if pause_overlay:
		pause_overlay.visible = false
	if pitch_box:
		pitch_box.visible = false
	_play_next_intro_step()

func _on_practice_now_pressed() -> void:
	# Dừng lời đang phát và vô hiệu callback tự chuyển bước trước khi vào tập.
	intro_playback_token += 1
	if ai_audio and is_instance_valid(ai_audio.audio_player):
		ai_audio.audio_player.stop()
	if current_lesson_id.begins_with("dan_tranh_level_6") or _uses_chord_lesson_flow():
		_start_practice_single()
	else:
		_start_practice()

func _play_next_intro_step():
	intro_playback_token += 1
	var playback_token := intro_playback_token
	var dialogues = LESSON_DIALOGUES.get(current_lesson_id, [])
	if intro_step >= dialogues.size():
		# Bài 1 (bai_1), 2 (bai_5), 3 (bai_4) là lý thuyết thuần – khi hết dialogue
		# thì hoàn thành bài luôn, không hiện khuôn nhạc thực hành.
		const THEORY_ONLY_IDS := [
			"dan_tranh_level_1_bai_1_practice",
			"dan_tranh_level_1_bai_5_practice",
			"dan_tranh_level_1_bai_4_practice"
		]
		if current_lesson_id in THEORY_ONLY_IDS:
			_finish_practice()
			return
		if current_lesson_id.begins_with("dan_tranh_level_6") or _uses_chord_lesson_flow():
			_start_practice_single()
		else:
			_start_practice()
		return
		
	var step_data = dialogues[intro_step]
	if step_data["action"] == "speak":
		speech_text.text = step_data["text"]
		if ai_audio:
			ai_audio.speak_vietnamese(step_data["text"])
			
		# ── Theory shown live: speed bar / treble clef / time signature ──────
		if step_data.get("show_speed", false):
			if speed_bar_container:
				speed_bar_container.visible = true
		elif step_data.has("show_speed"):
			if speed_bar_container:
				speed_bar_container.visible = false
		
		if step_data.has("clef"):
			staff_display.show_clef = step_data["clef"]
			staff_display.clef_highlight = step_data["clef"]
		
		if step_data.has("time_sig"):
			staff_display.show_time_sig = true
			staff_display.time_sig_highlight = true
			staff_display.beats_per_measure = int(step_data["time_sig"])
			staff_display.time_sig_denominator = 4
		else:
			staff_display.time_sig_highlight = false
		
		var show_staff: bool = step_data.get("show_staff", false)
			
		# Highlight string
		zither_board.call("clear_lesson_markers")
		var highlight_idx = step_data.get("highlight", -1)
		if highlight_idx >= 0:
			zither_board.call("set_lesson_marker", highlight_idx, "Gảy", 1)
			
			# Redesign lesson 1 level 1, lesson 2 level 1 and lesson 5 level 2 to wait for player input on note introduction steps!
			if current_lesson_id in ["dan_tranh_level_1_bai_1_practice", "dan_tranh_level_1_bai_2_practice", "dan_tranh_level_1_bai_3_practice", "dan_tranh_level_1_bai_4_practice", "dan_tranh_level_1_bai_5_practice", "dan_tranh_level_2_bai_5_practice"]:
				current_state = State.PRACTICE_SINGLE
				var target_note = step_data.get("note", ALL_17_NOTES[highlight_idx])
				staff_display.visible = true
				if staff_card: staff_card.visible = true
				_update_staff_layout()
				var note_type = step_data.get("type", "quarter")
				staff_display.set_notes([{"note": "ZT_" + target_note, "x": staff_display.hit_line_x, "color": C_GOLD, "type": note_type}])
				staff_display.queue_redraw()
				intro_step += 1
				return

		elif show_staff:
			staff_display.visible = true
			if staff_card: staff_card.visible = true
			_update_staff_layout()
			staff_display.set_notes([])
			staff_display.queue_redraw()
		else:
			staff_display.visible = false
			
		# Wait for speech to finish then go to next step
		var wait_time = max(1.5, step_data["text"].length() * 0.1)
		get_tree().create_timer(wait_time).timeout.connect(func():
			if current_state == State.INTRO and playback_token == intro_playback_token:
				_play_next_intro_step()
		)
	intro_step += 1

func _start_practice_single():
	current_state = State.PRACTICE_SINGLE
	_apply_adaptive_speed()
	_shrink_teacher()
	feedback_area.visible = true
	staff_display.visible = true
	if staff_card: staff_card.visible = true
	if title_plaque: title_plaque.visible = true
	if pill_badge: pill_badge.visible = true
	if sub_instr_row: sub_instr_row.visible = true
	_update_staff_layout()
	if skip_intro_btn:
		skip_intro_btn.visible = false
	if previous_intro_btn:
		previous_intro_btn.visible = false
	if pause_btn:
		pause_btn.visible = true
	if pitch_box:
		pitch_box.visible = true
	

	unique_practice_notes.clear()
	if _uses_chord_basics_lesson_flow():
		unique_practice_notes = lesson_sheet.duplicate()
	else:
		for note in lesson_sheet:
			if not unique_practice_notes.has(note):
				unique_practice_notes.append(note)
			
	single_practice_idx = 0
	_schedule_next_single_note()

func _shrink_teacher() -> void:
	if not is_instance_valid(teacher_char) or not is_instance_valid(teacher_area):
		return

	teacher_area.visible = true
	var dialog_box := teacher_area.get_node_or_null("DialogBox")
	if dialog_box and dialog_box.visible:
		var dialog_tween := create_tween()
		dialog_tween.tween_property(dialog_box, "modulate:a", 0.0, 0.2)
		dialog_tween.tween_callback(func(): dialog_box.visible = false)

	if not is_instance_valid(_teacher_avatar_wrapper):
		_teacher_avatar_wrapper = Panel.new()
		_teacher_avatar_wrapper.name = "TeacherAvatarWrapper"
		_teacher_avatar_wrapper.clip_children = CanvasItem.CLIP_CHILDREN_ONLY

		var avatar_style := StyleBoxFlat.new()
		avatar_style.bg_color = Color.WHITE
		avatar_style.corner_radius_top_left = 500
		avatar_style.corner_radius_top_right = 500
		avatar_style.corner_radius_bottom_left = 500
		avatar_style.corner_radius_bottom_right = 500
		_teacher_avatar_wrapper.add_theme_stylebox_override("panel", avatar_style)
		_teacher_avatar_wrapper.size = Vector2(400.0, 400.0)
		_teacher_avatar_wrapper.pivot_offset = _teacher_avatar_wrapper.size * 0.5
		_teacher_avatar_wrapper.position = teacher_char.global_position + Vector2(100.0, 40.0)

		teacher_char.get_parent().remove_child(teacher_char)
		_teacher_avatar_wrapper.add_child(teacher_char)
		add_child(_teacher_avatar_wrapper)
		_teacher_avatar_wrapper.z_index = 100
		# Khung thu nhỏ của Sáo được căn theo ảnh cô Mai 500×850. Scene Đàn
		# Tranh ban đầu chỉ dùng 300×500 nên phải chuẩn hóa trước khi cắt tròn.
		teacher_char.set_anchors_preset(Control.PRESET_TOP_LEFT)
		teacher_char.size = Vector2(500.0, 850.0)
		teacher_char.position = Vector2(-120.0, -50.0)

		_teacher_avatar_wrapper.mouse_filter = Control.MOUSE_FILTER_PASS
		_teacher_avatar_wrapper.gui_input.connect(_on_compact_teacher_clicked)

	var target_position := Vector2(-80.0, get_viewport_rect().size.y - 320.0)
	var teacher_tween := create_tween()
	teacher_tween.tween_property(_teacher_avatar_wrapper, "scale", Vector2(0.35, 0.35), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	teacher_tween.parallel().tween_property(_teacher_avatar_wrapper, "position", target_position, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_compact_teacher_clicked(event: InputEvent) -> void:
	var activated: bool = false
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		activated = mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		activated = touch_event.pressed
	if not activated:
		return
	var chat := AIChatPopup.new()
	add_child(chat)
	chat.open_chat("dan_tranh", {"screenContext": "lesson_practice"})

func _schedule_next_single_note():
	if single_practice_idx >= unique_practice_notes.size():
		if _uses_chord_basics_lesson_flow():
			if ai_audio: ai_audio.speak_vietnamese("Chúc mừng em đã hoàn thành bài học mở đầu về hợp âm!")
			_finish_practice()
			return
			
		if ai_audio: ai_audio.speak_vietnamese("Rất tuyệt! Bây giờ chúng ta sẽ luyện tập với bản nhạc.")
		current_state = State.INTRO
		get_tree().create_timer(3.0).timeout.connect(_start_practice)
		return
		
	var raw_note_name = unique_practice_notes[single_practice_idx]
	var notes = raw_note_name.split("+")
	var text = ""
	
	if _uses_chord_basics_lesson_flow() and notes.size() > 1:
		text = "Đây là một hợp âm. Em hãy thử gảy ba dây cùng lúc để cảm nhận sự khác biệt."
	elif notes.size() > 1:
		text = "Hãy gảy hợp âm: " + raw_note_name.replace("+", " và ")
	else:
		var string_idx = NOTE_TO_STRING.get(raw_note_name, 0)
		text = "Hãy gảy dây thứ %d, nốt %s." % [string_idx + 1, raw_note_name]
		
	speech_text.text = text
	if ai_audio:
		ai_audio.speak_vietnamese(text)
		
	var staff_notes = []
	for n in notes:
		staff_notes.append({"note": "ZT_" + n, "x": staff_display.hit_line_x, "color": Color(0.6, 0.6, 0.6, 0.9)})
	staff_display.set_notes(staff_notes)

func _process_practice_single(delta: float) -> void:
	if _is_micro_scoring_blocked():
		return
	wrong_note_cooldown = max(0.0, wrong_note_cooldown - delta)
	
	var target_note := ""
	var target_string_idx := 0
	
	if current_lesson_id in ["dan_tranh_level_1_bai_1_practice", "dan_tranh_level_1_bai_2_practice", "dan_tranh_level_1_bai_3_practice", "dan_tranh_level_1_bai_4_practice", "dan_tranh_level_1_bai_5_practice", "dan_tranh_level_2_bai_5_practice"]:
		var dialogues = LESSON_DIALOGUES.get(current_lesson_id, [])
		var prev_step_idx = intro_step - 1
		if prev_step_idx < 0 or prev_step_idx >= dialogues.size():
			return
		var step_data = dialogues[prev_step_idx]
		var highlight_idx = step_data.get("highlight", -1)
		if highlight_idx < 0:
			return
			
		target_note = step_data.get("note", ALL_17_NOTES[highlight_idx])
		target_string_idx = NOTE_TO_STRING.get(target_note, highlight_idx)

	else:
		if single_practice_idx >= unique_practice_notes.size(): return
		target_note = unique_practice_notes[single_practice_idx]
		target_string_idx = NOTE_TO_STRING.get(target_note.split("+")[0], 0)
		
	var target_hz = NOTE_FREQS.get(target_note, 0.0) if "+" not in target_note else NOTE_FREQS.get(target_note.split("+")[0], 0.0)
	
	# 1. Check if user played correct pitch
	if _check_mic_pitch(target_hz, delta, target_note):

		if current_lesson_id in ["dan_tranh_level_1_bai_1_practice", "dan_tranh_level_1_bai_2_practice", "dan_tranh_level_1_bai_3_practice", "dan_tranh_level_1_bai_4_practice", "dan_tranh_level_1_bai_5_practice", "dan_tranh_level_2_bai_5_practice"]:
			_on_intro_note_correct(target_note)
		else:
			_on_single_note_correct(target_note)
		return

	# 2. Check if user played a WRONG note via microphone (requires 0.18s debounce hold time)
	if analyzer and wrong_note_cooldown <= 0.0:
		var db = analyzer.current_amplitude_db
		if db > -28.0:
			var note_info = analyzer.detect_dan_tranh_note(analyzer._analysis_buffer, AudioServer.get_mix_rate())
			var det_name = note_info.get("note_name", "None")
			var det_idx = note_info.get("string_index", -1)
			var is_partial_polyphonic: bool = "+" in target_note \
				and det_name in target_note.split("+")
			if det_name != "None" and det_idx >= 0 and is_partial_polyphonic:
				wrong_note_time += delta
				if wrong_note_time >= REQUIRED_WRONG_HOLD_TIME:
					wrong_note_time = 0.0
					wrong_note_cooldown = 2.0
					_show_polyphonic_incomplete(target_note)
				return
			var is_wrong = true
			if det_name == target_note or det_idx == target_string_idx:
				is_wrong = false
			elif _is_harmonic_or_octave_of_target(det_name, det_idx, target_note, target_string_idx):
				is_wrong = false
			elif time_correct > 0.0:
				is_wrong = false
				
			if det_name != "None" and is_wrong and det_idx >= 0:
				wrong_note_time += delta
				if wrong_note_time >= REQUIRED_WRONG_HOLD_TIME:
					wrong_note_time = 0.0
					wrong_note_cooldown = 3.5
					_on_wrong_note_played(det_name, det_idx, target_note, target_string_idx)
				return
			else:
				wrong_note_time = max(0.0, wrong_note_time - delta * 2.0)



				
	wrong_note_time = max(0.0, wrong_note_time - delta * 2.0)




func _on_wrong_note_played(detected_note: String, detected_idx: int, target_note: String, target_idx: int) -> void:
	_show_practice_error_feedback(
		target_note,
		"Cần gảy: " + target_note.replace("+", " + "),
		"Chưa đúng"
	)
	if pitch_note_lbl: pitch_note_lbl.text = "🎵 Nốt: " + detected_note
	if pitch_status_lbl:
		pitch_status_lbl.text = "🔴 CHƯA ĐÚNG! (Cần: " + target_note + ")"
		pitch_status_lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	
	# Turn note head RED on staff to signal wrong note, but DO NOT advance!
	for note in active_falling_notes:
		if not note.get("hit", false):
			note["color"] = Color(0.9, 0.15, 0.15, 1.0) # Red note head
			break
			
	zither_board.call("clear_lesson_markers")
	# Red marker on wrong string, Gold pulse marker on target string
	zither_board.call("set_lesson_marker", detected_idx, "Nhầm: " + detected_note, 3)
	zither_board.call("set_lesson_marker", target_idx, "Cần gảy: " + target_note, 1)
	
	var msg = "Bạn vừa gảy nhầm nốt %s (Dây %d). Hãy gảy nốt %s (Dây %d) nhé!" % [detected_note, detected_idx + 1, target_note, target_idx + 1]
	speech_text.text = msg
	
	if mic_status_lbl:
		mic_status_lbl.text = "Gảy nhầm %s (Dây %d) ➔ Hãy gảy %s (Dây %d)" % [detected_note, detected_idx + 1, target_note, target_idx + 1]
		mic_status_lbl.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
		
	# Red staff highlight for wrong note attempt (only in intro/explore static mode)
	if current_state == State.INTRO or current_state == State.PRACTICE_SINGLE:
		var note_type = "quarter"
		if current_lesson_id in ["dan_tranh_level_1_bai_1_practice", "dan_tranh_level_1_bai_2_practice", "dan_tranh_level_1_bai_3_practice", "dan_tranh_level_1_bai_4_practice", "dan_tranh_level_1_bai_5_practice", "dan_tranh_level_2_bai_5_practice"]:
			var dialogues = LESSON_DIALOGUES.get(current_lesson_id, [])
			var prev_step_idx = intro_step - 1
			if prev_step_idx >= 0 and prev_step_idx < dialogues.size():
				note_type = dialogues[prev_step_idx].get("type", "quarter")
		staff_display.set_notes([{"note": "ZT_" + target_note, "x": staff_display.hit_line_x, "color": Color(0.9, 0.15, 0.15, 1.0), "type": note_type}])
	
	if ai_audio:
		ai_audio.speak_vietnamese("Bạn gảy nhầm nốt %s rồi. Hãy gảy nốt %s ở dây số %d nhé!" % [detected_note, target_note, target_idx + 1])


func _show_polyphonic_incomplete(target_note: String) -> void:
	var target_notes := target_note.split("+")
	var target_label := target_note.replace("+", " và ")
	var required_count := target_notes.size()
	var feedback := "Cần gảy đồng thời đủ %d nốt: %s" % [required_count, target_label]
	var title := "Chưa đủ Song thanh" if required_count == 2 else "Chưa đủ hợp âm"
	_show_practice_error_feedback(target_note, feedback, title)
	if pitch_status_lbl:
		pitch_status_lbl.text = "🟡 CHƯA ĐỦ %d NỐT" % required_count
		pitch_status_lbl.add_theme_color_override("font_color", Color(0.80, 0.55, 0.12, 1.0))
	if mic_status_lbl:
		mic_status_lbl.text = feedback
		mic_status_lbl.add_theme_color_override("font_color", Color(0.80, 0.55, 0.12, 1.0))

func _on_intro_note_correct(note_name: String) -> void:
	current_state = State.INTRO
	var note_type = "quarter"
	if current_lesson_id in ["dan_tranh_level_1_bai_1_practice", "dan_tranh_level_1_bai_2_practice", "dan_tranh_level_1_bai_3_practice", "dan_tranh_level_1_bai_4_practice", "dan_tranh_level_1_bai_5_practice", "dan_tranh_level_2_bai_5_practice"]:
		var dialogues = LESSON_DIALOGUES.get(current_lesson_id, [])
		var prev_step_idx = intro_step - 1
		if prev_step_idx >= 0 and prev_step_idx < dialogues.size():
			note_type = dialogues[prev_step_idx].get("type", "quarter")
	staff_display.set_notes([{"note": "ZT_" + note_name, "x": staff_display.hit_line_x, "color": Color(0.2, 0.8, 0.3, 1.0), "type": note_type}])
	var string_idx = NOTE_TO_STRING.get(note_name, 0)
	zither_board.call("clear_lesson_markers")
	zither_board.call("set_lesson_marker", string_idx, note_name, 2)
	
	if mic_status_lbl:
		mic_status_lbl.text = "Chính xác! Nốt %s (Dây %d)" % [note_name, string_idx + 1]
		mic_status_lbl.add_theme_color_override("font_color", Color(0.18, 0.62, 0.42))
		
	if ai_audio:
		ai_audio.speak_vietnamese("Tốt lắm! Chính xác nốt %s." % note_name)
	get_tree().create_timer(1.8).timeout.connect(func():
		_play_next_intro_step()
	)


func _on_single_note_correct(raw_note_name: String) -> void:
	current_state = State.INTRO
	var notes = raw_note_name.split("+")
	var staff_notes = []
	zither_board.call("clear_lesson_markers")
	
	for n in notes:
		staff_notes.append({"note": "ZT_" + n, "x": staff_display.hit_line_x, "color": Color(0.2, 0.8, 0.3, 1.0)})
		var string_idx = NOTE_TO_STRING.get(n, 0)
		zither_board.call("set_lesson_marker", string_idx, n, 2)
		
	staff_display.set_notes(staff_notes)
	
	if mic_status_lbl:
		if notes.size() > 1:
			mic_status_lbl.text = "Chính xác hợp âm: %s" % raw_note_name.replace("+", " ")
		else:
			var string_idx = NOTE_TO_STRING.get(raw_note_name, 0)
			mic_status_lbl.text = "Chính xác! Nốt %s (Dây %d)" % [raw_note_name, string_idx + 1]
		mic_status_lbl.add_theme_color_override("font_color", Color(0.18, 0.62, 0.42))
		
	if ai_audio:
		ai_audio.speak_vietnamese("Tốt lắm!")
	
	single_practice_idx += 1
	get_tree().create_timer(2.0).timeout.connect(func():
		current_state = State.PRACTICE_SINGLE
		_schedule_next_single_note()
	)

func _on_string_plucked(idx: int, note_name: String) -> void:
	if is_sample_mode and _is_technique_sample_practice():
		return
	if current_state == State.PRACTICE_SINGLE:
		if current_lesson_id in ["dan_tranh_level_1_bai_1_practice", "dan_tranh_level_1_bai_2_practice", "dan_tranh_level_1_bai_3_practice", "dan_tranh_level_1_bai_4_practice", "dan_tranh_level_1_bai_5_practice", "dan_tranh_level_2_bai_5_practice"]:
			var dialogues = LESSON_DIALOGUES.get(current_lesson_id, [])
			var prev_step_idx = intro_step - 1
			if prev_step_idx >= 0 and prev_step_idx < dialogues.size():
				var step_data = dialogues[prev_step_idx]
				var highlight_idx = step_data.get("highlight", -1)
				var target_note = step_data.get("note", ALL_17_NOTES[highlight_idx])
				var target_string_idx = NOTE_TO_STRING.get(target_note, highlight_idx)
				if target_string_idx == idx:
					_on_intro_note_correct(target_note)
				else:
					_on_wrong_note_played(note_name, idx, target_note, target_string_idx)
		else:
			var target_note = unique_practice_notes[single_practice_idx]
			var is_correct = false
			if "+" in target_note:
				# A virtual single-string click must never complete Song thanh or a
				# chord. Polyphonic targets are scored only from one microphone window
				# containing every required fundamental.
				if note_name in target_note.split("+"):
					if mic_status_lbl:
						mic_status_lbl.text = "Hãy gảy đồng thời đủ các nốt: %s" % target_note.replace("+", " và ")
						mic_status_lbl.add_theme_color_override("font_color", C_GOLD)
					return
			else:
				if note_name == target_note:
					is_correct = true
					
			if is_correct:
				_on_single_note_correct(target_note)
			else:
				var target_idx = NOTE_TO_STRING.get(target_note.split("+")[0], 0)
				_on_wrong_note_played(note_name, idx, target_note, target_idx)

	elif current_state == State.PRACTICE:
		if _is_glissando_practice():
			# Á is a microphone technique exercise. Virtual clicks have not passed
			# the đàn-tranh attack classifier and therefore must not enter its chain.
			if glissando_status_label:
				glissando_status_label.text = "Hãy thực hiện kỹ thuật Á trên đàn thật để micro nhận chuỗi tiếng gảy."
				glissando_status_label.add_theme_color_override("font_color", C_GOLD)
			return
		if _is_tremolo_practice():
			# Vê is scored only from individually validated microphone attacks.
			if tremolo_status_label:
				tremolo_status_label.text = "Hãy thực hiện kỹ thuật Vê trên đàn thật để micro đo từng lần gảy."
				tremolo_status_label.add_theme_color_override("font_color", C_GOLD)
			return
		# Hỗ trợ gảy phím ảo bằng chạm/nhấp chuột trên màn hình đối với nốt khuyết
		var hit_x = staff_display.hit_line_x
		for note in active_falling_notes:
			if note.get("is_missing", false) and not note.get("hit", false) and not note.get("missed", false):
				if note["target_string"] == idx and abs(note["x"] - hit_x) < 40.0:
					note["color"] = Color(0.2, 0.8, 0.3, 1.0)
					note["hit"] = true
					consecutive_hits += 1
					consecutive_misses = 0
					if consecutive_hits >= 5:
						current_speed_multiplier = user_speed_multiplier
						break

func _on_dan_tranh_note_started(_note: Dictionary) -> void:
	# Á is scored from validated rapid-attack events below. Continuous pitch
	# changes are intentionally ignored so a sung glide cannot create an Á chain.
	pass

func _on_dan_tranh_rapid_attack(note: Dictionary) -> void:
	if _is_micro_scoring_blocked() or current_state != State.PRACTICE or is_sample_mode:
		return
	if not _is_validated_dan_tranh_rapid_attack(note):
		return
	var string_idx := int(note.get("string_index", -1))
	var attack_generation := int(note.get("attack_generation", -1))
	var attack_time_sec := float(note.get("attack_time_msec", 0)) / 1000.0
	if _is_glissando_practice():
		_append_glissando_detection(string_idx, attack_time_sec, attack_generation, true)
	elif _is_tremolo_practice():
		_append_tremolo_attack(string_idx, attack_time_sec, attack_generation, true)


func _is_validated_dan_tranh_rapid_attack(note: Dictionary) -> bool:
	var string_idx := int(note.get("string_index", -1))
	return bool(note.get("is_match", false)) \
		and bool(note.get("instrument_validated", false)) \
		and float(note.get("instrument_confidence", 0.0)) > 0.0 \
		and int(note.get("attack_generation", -1)) > 0 \
		and int(note.get("attack_time_msec", 0)) > 0 \
		and string_idx >= 0 and string_idx < ALL_17_NOTES.size() \
		and str(note.get("note_name", "")) == ALL_17_NOTES[string_idx]

func _append_glissando_detection(
	string_idx: int,
	attack_time_sec: float,
	attack_generation: int,
	instrument_validated: bool
) -> void:
	if glissando_round_locked or not instrument_validated:
		return
	if string_idx < 0 or string_idx >= ALL_17_NOTES.size() \
			or attack_time_sec <= 0.0 or attack_generation <= 0:
		return
	if not glissando_detected_generations.is_empty() \
			and attack_generation <= glissando_detected_generations.back():
		return
	if not glissando_detected_times.is_empty():
		var gap: float = attack_time_sec - float(glissando_detected_times.back())
		if gap > GLISSANDO_GAP_TIMEOUT:
			_evaluate_glissando_gesture()
			if glissando_round_locked:
				return
			glissando_detected_strings.clear()
			glissando_detected_times.clear()
			glissando_detected_generations.clear()

	glissando_detected_strings.append(string_idx)
	glissando_detected_times.append(attack_time_sec)
	glissando_detected_generations.append(attack_generation)
	glissando_last_detection_time = attack_time_sec
	_update_glissando_detection_feedback()

func _process_glissando_practice() -> void:
	if _is_micro_scoring_blocked() or glissando_round_locked or glissando_detected_times.is_empty():
		return
	var now_sec := Time.get_ticks_msec() / 1000.0
	var silence_gap := now_sec - glissando_last_detection_time
	var gesture_duration := now_sec - glissando_detected_times[0]
	var mode := str(GLISSANDO_ROUNDS[glissando_round_idx]["mode"])
	var max_duration := 3.8 if mode == "round" else 2.4
	if silence_gap >= GLISSANDO_GAP_TIMEOUT or gesture_duration >= max_duration:
		_evaluate_glissando_gesture()

func _start_glissando_round(round_index: int) -> void:
	if round_index >= GLISSANDO_ROUNDS.size():
		if analyzer:
			analyzer.rapid_sequence_mode = false
		_finish_practice()
		return

	glissando_round_idx = round_index
	glissando_round_locked = false
	glissando_detected_strings.clear()
	glissando_detected_times.clear()
	glissando_detected_generations.clear()
	glissando_last_detection_time = 0.0
	active_falling_notes.clear()
	staff_display.show_metronome = false
	staff_display.show_hit_line = false
	staff_display.show_time_sig = true
	staff_display.show_clef = true
	staff_display.beats_per_measure = 2
	staff_display.time_sig_denominator = 4
	staff_display.glissando_arrow_mode = str(GLISSANDO_ROUNDS[round_index]["mode"])
	_build_glissando_round_notes(str(GLISSANDO_ROUNDS[round_index]["mode"]))

	if speed_bar_container:
		speed_bar_container.visible = false
	if glissando_instruction_label:
		glissando_instruction_label.text = "%s · %s" % [
			GLISSANDO_ROUNDS[round_index]["title"],
			GLISSANDO_ROUNDS[round_index]["instruction"]
		]
	if glissando_progress_label:
		glissando_progress_label.text = "Lượt %d/3 · 0 dây" % (round_index + 1)
	if glissando_progress_bar:
		glissando_progress_bar.value = 0.0
	if glissando_status_label:
		glissando_status_label.text = "Micro đang nghe đàn thật... Hãy thực hiện một động tác liền mạch."
		glissando_status_label.add_theme_color_override("font_color", Color(0.30, 0.26, 0.20, 0.92))
	if mic_status_lbl:
		mic_status_lbl.text = "🎙️ Đang nhận diện chuỗi âm kỹ thuật Á"
		mic_status_lbl.add_theme_color_override("font_color", Color(0.24, 0.56, 0.35, 1.0))

func _build_glissando_round_notes(_mode: String) -> void:
	# Ba bài dùng cùng bảy nốt đi lên như sheet mẫu; hướng kỹ thuật được thể
	# hiện bằng ký hiệu Á xuống, Á lên hoặc Á vòng đặt trước từng nốt.
	var string_order: Array[int] = [0, 1, 2, 3, 4, 5, 6]

	var staff_width := maxf(staff_display.size.x, get_viewport_rect().size.x - 110.0)
	var start_x := 285.0
	var end_x := maxf(start_x + 700.0, staff_width - 70.0)
	var measure_width := (end_x - start_x) / float(string_order.size())
	glissando_display_notes.clear()
	for i in range(string_order.size()):
		var measure_start: float = start_x + measure_width * float(i)
		var cue_ratio: float = 0.18
		var note_ratio: float = 0.68
		if _mode == "round":
			# Á vòng phải đọc từ trái sang phải: mũi tên xuống, mũi tên lên, rồi đến nốt.
			cue_ratio = 0.10
			note_ratio = 0.72
		var cue_x: float = measure_start + measure_width * cue_ratio
		var second_cue_x: float = measure_start + measure_width * 0.38
		var note_x: float = measure_start + measure_width * note_ratio
		var bar_x: float = measure_start + measure_width
		glissando_display_notes.append({
			"note": "ZT_" + ALL_17_NOTES[string_order[i]],
			"x": note_x,
			"glissando_cue_x": cue_x,
			"glissando_second_cue_x": second_cue_x,
			"color": Color(0.16, 0.14, 0.12, 1.0),
			"type": "quarter",
			"bar_after": true,
			"bar_x": bar_x
		})
	staff_display.set_notes(glissando_display_notes)
	staff_display.queue_redraw()

func _update_glissando_detection_feedback() -> void:
	if glissando_detected_strings.is_empty():
		return
	var min_string := glissando_detected_strings[0]
	var max_string := glissando_detected_strings[0]
	for value in glissando_detected_strings:
		min_string = mini(min_string, value)
		max_string = maxi(max_string, value)
	var covered_strings := max_string - min_string + 1
	var distinct := {}
	for value in glissando_detected_strings:
		distinct[value] = true
	if glissando_progress_label:
		glissando_progress_label.text = "Lượt %d/3 · %d âm hợp lệ · %d dây khác nhau · phủ %d dây" % [
			glissando_round_idx + 1,
			glissando_detected_strings.size(),
			distinct.size(),
			covered_strings
		]
	if glissando_progress_bar:
		glissando_progress_bar.value = clampf(float(covered_strings), 0.0, 17.0)
	if glissando_status_label:
		glissando_status_label.text = "Đang nghe: %s (dây %d)" % [
			ALL_17_NOTES[glissando_detected_strings.back()],
			glissando_detected_strings.back() + 1
		]

	var colored_count := mini(glissando_display_notes.size(), glissando_detected_strings.size())
	for i in range(glissando_display_notes.size()):
		glissando_display_notes[i]["color"] = Color(0.20, 0.72, 0.34, 1.0) if i < colored_count else Color(0.16, 0.14, 0.12, 1.0)
	staff_display.queue_redraw()

func _direction_ratio(values: Array[int], expect_increasing: bool) -> float:
	if values.size() < 2:
		return 0.0
	var expected_weight := 0.0
	var total_weight := 0.0
	for i in range(1, values.size()):
		var delta := values[i] - values[i - 1]
		var weight := maxf(1.0, absf(float(delta)))
		total_weight += weight
		if (expect_increasing and delta > 0) or (not expect_increasing and delta < 0):
			expected_weight += weight
	return expected_weight / maxf(total_weight, 1.0)

func _evaluate_glissando_gesture() -> void:
	if glissando_round_locked or glissando_detected_strings.is_empty():
		return

	var mode := str(GLISSANDO_ROUNDS[glissando_round_idx]["mode"])
	var result := _analyze_glissando_gesture(
		glissando_detected_strings, glissando_detected_times, mode
	)

	glissando_round_locked = true
	if result.get("success", false):
		_on_glissando_round_success()
	else:
		_on_glissando_round_failed(result)


func _analyze_glissando_gesture(
	strings: Array[int],
	times: Array[float],
	mode: String
) -> Dictionary:
	var result := {
		"success": false,
		"event_count": strings.size(),
		"distinct_count": 0,
		"span": 0,
		"duration": 0.0,
		"max_gap": 0.0,
		"max_step": 0,
		"direction_ratio": 0.0,
		"enough_strings": false,
		"range_valid": false,
		"direction_valid": false,
		"continuous": false
	}
	if strings.is_empty() or strings.size() != times.size():
		return result

	var first: int = strings.front()
	var last: int = strings.back()
	var min_string := first
	var max_string := first
	var distinct := {}
	var max_gap := 0.0
	var max_step := 0
	var times_increasing := true
	for i in range(strings.size()):
		var string_idx := strings[i]
		if string_idx < 0 or string_idx >= ALL_17_NOTES.size():
			return result
		distinct[string_idx] = true
		min_string = mini(min_string, string_idx)
		max_string = maxi(max_string, string_idx)
		if i > 0:
			var gap := times[i] - times[i - 1]
			if gap <= 0.0:
				times_increasing = false
			max_gap = maxf(max_gap, gap)
			max_step = maxi(max_step, absi(strings[i] - strings[i - 1]))

	var span := max_string - min_string
	var duration: float = float(times.back()) - float(times.front())
	var distinct_count := distinct.size()
	var coverage_ratio := float(distinct_count) / float(maxi(1, span + 1))
	var mobile_fallback := _uses_mobile_audio_fallback()
	var max_duration := 4.5 if mode == "round" else 3.5
	var continuous: bool = times_increasing \
		and max_gap <= (0.60 if mobile_fallback else GLISSANDO_MAX_ATTACK_GAP) \
		and max_step <= (8 if mobile_fallback else GLISSANDO_MAX_STRING_STEP) \
		and duration <= max_duration
	var minimum_distinct := 4 if mobile_fallback else GLISSANDO_MIN_DISTINCT_STRINGS
	var minimum_events := 7 if mode == "round" else 5
	if mobile_fallback:
		minimum_events = 6 if mode == "round" else 4
	var enough_strings := distinct_count >= minimum_distinct \
		and strings.size() >= minimum_events
	var range_valid := false
	var direction_valid := false
	var direction_ratio := 0.0

	if mode == "down":
		direction_ratio = _direction_ratio(strings, false)
		range_valid = span >= (5 if mobile_fallback else 6) and first >= 7 and last <= 8 \
			and coverage_ratio >= (0.25 if mobile_fallback else 0.35)
		direction_valid = direction_ratio >= (0.55 if mobile_fallback else 0.65)
	elif mode == "up":
		direction_ratio = _direction_ratio(strings, true)
		range_valid = span >= (5 if mobile_fallback else 6) and first <= 8 and last >= 7 \
			and coverage_ratio >= (0.25 if mobile_fallback else 0.35)
		direction_valid = direction_ratio >= (0.55 if mobile_fallback else 0.65)
	elif mode == "round":
		var turn_idx := strings.find(min_string)
		var minimum_leg_events := 1 if mobile_fallback else 2
		if turn_idx >= minimum_leg_events and turn_idx <= strings.size() - minimum_leg_events - 1:
			var down_leg: Array[int] = []
			var up_leg: Array[int] = []
			for i in range(turn_idx + 1):
				down_leg.append(strings[i])
			for i in range(turn_idx, strings.size()):
				up_leg.append(strings[i])
			var down_ratio := _direction_ratio(down_leg, false)
			var up_ratio := _direction_ratio(up_leg, true)
			direction_ratio = minf(down_ratio, up_ratio)
			var minimum_leg_span := 4 if mobile_fallback else 5
			range_valid = min_string <= 7 and first >= 7 and last >= 7 \
				and first - min_string >= minimum_leg_span and last - min_string >= minimum_leg_span \
				and coverage_ratio >= (0.25 if mobile_fallback else 0.35)
			var minimum_direction_ratio := 0.52 if mobile_fallback else 0.60
			direction_valid = down_ratio >= minimum_direction_ratio and up_ratio >= minimum_direction_ratio

	result["distinct_count"] = distinct_count
	result["span"] = span
	result["duration"] = duration
	result["max_gap"] = max_gap
	result["max_step"] = max_step
	result["direction_ratio"] = direction_ratio
	result["enough_strings"] = enough_strings
	result["range_valid"] = range_valid
	result["direction_valid"] = direction_valid
	result["continuous"] = continuous
	result["success"] = enough_strings and range_valid and direction_valid and continuous
	return result

func _on_glissando_round_success() -> void:
	for note_data in glissando_display_notes:
		note_data["color"] = Color(0.12, 0.78, 0.30, 1.0)
	staff_display.queue_redraw()
	if glissando_progress_bar:
		glissando_progress_bar.value = 17.0
	if glissando_status_label:
		glissando_status_label.text = "✓ Đúng %s: chuỗi âm liền mạch và đúng hướng." % GLISSANDO_ROUNDS[glissando_round_idx]["title"]
		glissando_status_label.add_theme_color_override("font_color", Color(0.10, 0.58, 0.25, 1.0))
	_dan_tranh_attempts.append({
		"correct_string": true,
		"cents_error": 0.0,
		"timing": 95.0,
		"attack_clarity": 95.0,
		"sustain_duration": 100.0,
		"vibrato_detected": false,
		"bend_detected": true
	})
	if ai_audio:
		ai_audio.speak_vietnamese("Tốt lắm! Bạn đã thực hiện đúng %s." % GLISSANDO_ROUNDS[glissando_round_idx]["title"])
	var completed_round := glissando_round_idx
	get_tree().create_timer(1.7).timeout.connect(func():
		if current_state == State.PRACTICE and _is_glissando_practice() and glissando_round_idx == completed_round:
			_start_glissando_round(completed_round + 1)
	)

func _on_glissando_round_failed(result: Dictionary) -> void:
	var feedback := "Chuỗi âm chưa đúng hướng mũi tên. Hãy vuốt lại đúng chiều."
	var overlay_detail := "Cần vuốt đúng hướng mũi tên"
	if not result.get("enough_strings", false):
		feedback = "Chưa đủ số dây. Hãy vuốt qua ít nhất 6 dây khác nhau."
		overlay_detail = "Cần vuốt qua ít nhất 6 dây"
	elif not result.get("range_valid", false):
		feedback = "Phạm vi Á chưa đủ rộng hoặc chưa chạm đúng vùng dây đầu/cuối."
		overlay_detail = "Cần vuốt phạm vi dây rộng hơn"
	elif not result.get("continuous", false):
		feedback = "Chuỗi Á còn ngắt quãng hoặc bỏ cách quá nhiều dây. Hãy vuốt liền tay hơn."
		overlay_detail = "Cần vuốt liền mạch hơn"
	if glissando_status_label:
		glissando_status_label.text = feedback
		glissando_status_label.add_theme_color_override("font_color", Color(0.78, 0.22, 0.16, 1.0))
	var mode := str(GLISSANDO_ROUNDS[glissando_round_idx]["mode"])
	var anchor_note := "Sol1" if mode == "up" else "La4"
	_show_practice_error_feedback(anchor_note, overlay_detail, "Chưa đúng kỹ thuật Á")
	_dan_tranh_attempts.append({
		"correct_string": false,
		"cents_error": 50.0,
		"timing": 35.0,
		"attack_clarity": 55.0,
		"sustain_duration": 30.0,
		"vibrato_detected": false,
		"bend_detected": false
	})
	if ai_audio:
		ai_audio.speak_vietnamese("Chưa đúng. Hãy nhìn theo hướng mũi tên và vuốt liền mạch qua nhiều dây hơn nhé.")
	var failed_round := glissando_round_idx
	get_tree().create_timer(1.5).timeout.connect(func():
		if current_state == State.PRACTICE and _is_glissando_practice() and glissando_round_idx == failed_round:
			_start_glissando_round(failed_round)
	)

func _start_press_practice() -> void:
	press_exercise_idx = 0
	staff_display.show_metronome = false
	staff_display.show_hit_line = false
	staff_display.show_clef = true
	staff_display.show_time_sig = true
	staff_display.beats_per_measure = 4
	staff_display.time_sig_denominator = 4
	staff_display.glissando_arrow_mode = ""
	if speed_bar_container:
		speed_bar_container.visible = false
	_build_press_display_notes()
	_start_press_exercise(0)

func _build_press_display_notes() -> void:
	var staff_width: float = maxf(staff_display.size.x, get_viewport_rect().size.x - 110.0)
	var start_x := 320.0
	var end_x: float = maxf(start_x + 920.0, staff_width - 120.0)
	var pair_width := (end_x - start_x) / float(PRESS_EXERCISES.size())
	press_display_notes.clear()
	for i in range(PRESS_EXERCISES.size()):
		var exercise: Dictionary = PRESS_EXERCISES[i]
		var source_x := start_x + pair_width * float(i) + pair_width * 0.12
		var target_x := start_x + pair_width * float(i) + pair_width * 0.52
		var bar_x := start_x + pair_width * float(i + 1)
		press_display_notes.append({
			"note": "ZT_" + str(exercise["source"]),
			"x": source_x,
			"color": Color(0.16, 0.14, 0.12, 1.0),
			"type": "half",
			"press_target": "ZT_" + str(exercise["target"]),
			"press_target_x": target_x
		})
		press_display_notes.append({
			"note": "ZT_" + str(exercise["target"]),
			"x": target_x,
			"color": Color(0.16, 0.14, 0.12, 1.0),
			"type": "half",
			"bar_after": i < PRESS_EXERCISES.size() - 1,
			"bar_x": bar_x
		})
	staff_display.set_notes(press_display_notes)
	staff_display.queue_redraw()

func _start_press_exercise(exercise_index: int) -> void:
	if exercise_index >= PRESS_EXERCISES.size():
		if analyzer:
			analyzer.contour_tracking_mode = false
		_finish_practice()
		return
	press_exercise_idx = exercise_index
	press_cents_history.clear()
	press_sample_accumulator = 0.0
	press_attempt_elapsed = 0.0
	press_silence_elapsed = 0.0
	press_target_hold_elapsed = 0.0
	press_base_note_heard = false
	press_exercise_locked = false
	press_max_cents = 0.0
	press_attack_generation = -1
	press_contour_elapsed = 0.0
	press_min_amplitude_db = 0.0
	press_added_sound_elapsed = 0.0
	# Never reuse a still-ringing attack from the previous instruction/attempt.
	press_consumed_attack_generation = _get_current_technique_attack_generation()
	for pair_idx in range(PRESS_EXERCISES.size()):
		var color := Color(0.16, 0.14, 0.12, 1.0)
		if pair_idx < exercise_index:
			color = Color(0.12, 0.72, 0.30, 1.0)
		elif pair_idx == exercise_index:
			color = C_GOLD
		press_display_notes[pair_idx * 2]["color"] = color
		press_display_notes[pair_idx * 2 + 1]["color"] = color
	staff_display.queue_redraw()

	var exercise: Dictionary = PRESS_EXERCISES[exercise_index]
	var source := str(exercise["source"])
	var target := str(exercise["target"])
	var string_number := int(NOTE_TO_STRING.get(source, 0)) + 1
	if press_instruction_label:
		press_instruction_label.text = "Lượt %d/4 · %s → %s (dây %d)" % [exercise_index + 1, source, target, string_number]
	if press_status_label:
		press_status_label.text = "Gảy %s trước, sau đó nhấn tay trái lên đúng cao độ %s và giữ ổn định." % [source, target]
		press_status_label.add_theme_color_override("font_color", Color(0.30, 0.26, 0.20, 0.92))
	if press_progress_bar:
		press_progress_bar.value = float(exercise_index)
	if mic_status_lbl:
		mic_status_lbl.text = "🎙️ Đang nghe đường nhấn %s lên %s" % [source, target]
		mic_status_lbl.add_theme_color_override("font_color", Color(0.24, 0.56, 0.35, 1.0))

func _process_press_practice(delta: float) -> void:
	if _is_micro_scoring_blocked() or press_exercise_locked or press_exercise_idx >= PRESS_EXERCISES.size() or not analyzer:
		return
	press_attempt_elapsed += delta
	var exercise: Dictionary = PRESS_EXERCISES[press_exercise_idx]
	var source := str(exercise["source"])
	var target := str(exercise["target"])
	var source_hz := float(NOTE_FREQS.get(source, 0.0))
	var target_interval := float(exercise["interval"])
	var pitch := float(analyzer.current_pitch)
	var signal_active: bool = analyzer.current_amplitude_db > analyzer.volume_threshold_db and pitch > 0.0
	var attack_identity := _get_technique_attack_identity()

	if signal_active and source_hz > 0.0:
		var cents := 1200.0 * log(pitch / source_hz) / log(2.0)
		if not press_base_note_heard:
			var generation := int(attack_identity.get("generation", -1))
			if absf(cents) <= 65.0 \
					and generation != press_consumed_attack_generation \
					and _is_press_source_attack_valid(attack_identity, source):
				press_base_note_heard = true
				press_attack_generation = generation
				press_consumed_attack_generation = generation
				press_contour_elapsed = 0.0
				press_min_amplitude_db = float(analyzer.current_amplitude_db)
				press_added_sound_elapsed = 0.0
				press_silence_elapsed = 0.0
				press_cents_history.append(cents)
				if press_status_label:
					press_status_label.text = "Đã nhận đúng lần gảy dây %s. Hãy nhấn dần lên %s..." % [source, target]
			elif bool(attack_identity.get("active", false)) \
					and int(attack_identity.get("string_index", -1)) >= 0 \
					and press_status_label:
				var heard_note := str(attack_identity.get("note_name", "âm khác"))
				press_status_label.text = "Đang nghe %s; cần gảy đúng dây %s trước khi nhấn." % [heard_note, source]
				press_status_label.add_theme_color_override("font_color", Color(0.78, 0.22, 0.16, 1.0))
				_show_practice_error_feedback(
					source,
					"Đã nghe %s · cần gảy đúng dây %s trước" % [heard_note, source],
					"Sai dây"
				)
		else:
			if not _is_press_contour_session_valid(attack_identity, source, press_attack_generation):
				_reset_press_attempt_tracking("Âm nhấn không còn thuộc lần gảy dây %s. Hãy gảy lại đúng dây rồi nhấn." % source)
				return
			press_contour_elapsed += delta
			press_min_amplitude_db = minf(press_min_amplitude_db, float(analyzer.current_amplitude_db))
			if _is_press_added_sound_level(
					float(analyzer.current_amplitude_db),
					press_min_amplitude_db,
					press_contour_elapsed
			):
				press_added_sound_elapsed += delta
			else:
				press_added_sound_elapsed = maxf(0.0, press_added_sound_elapsed - delta * 2.0)
			if press_added_sound_elapsed >= PRESS_ADDED_SOUND_HOLD_SEC:
				_reset_press_attempt_tracking("Phát hiện âm mới chồng lên tiếng đàn. Hãy chỉ gảy dây rồi nhấn bằng tay trái.")
				return
			press_silence_elapsed = 0.0
			if cents >= -60.0 and cents <= target_interval + 110.0:
				press_max_cents = maxf(press_max_cents, cents)
				press_sample_accumulator += delta
				while press_sample_accumulator >= PRESS_SAMPLE_INTERVAL:
					press_sample_accumulator -= PRESS_SAMPLE_INTERVAL
					if not press_cents_history.is_empty() \
							and absf(cents - press_cents_history[-1]) > PRESS_MAX_SAMPLE_JUMP_CENTS:
						_reset_press_attempt_tracking("Cao độ bị nhảy đột ngột, không giống một lần nhấn dây liên tục. Hãy gảy và nhấn lại.")
						return
					press_cents_history.append(cents)
					if press_cents_history.size() > 180:
						press_cents_history.pop_front()
			if absf(cents - target_interval) <= 55.0:
				press_target_hold_elapsed += delta
			else:
				press_target_hold_elapsed = maxf(0.0, press_target_hold_elapsed - delta * 1.5)

			if press_status_label:
				if cents > target_interval + 65.0:
					press_status_label.text = "Cao quá (+%.0f cents). Hãy giảm lực tay trái." % cents
					press_status_label.add_theme_color_override("font_color", Color(0.78, 0.22, 0.16, 1.0))
				elif cents < target_interval - 55.0:
					press_status_label.text = "Đang nhấn: +%.0f/%d cents · cần nhấn thêm." % [cents, int(target_interval)]
					press_status_label.add_theme_color_override("font_color", Color(0.70, 0.45, 0.08, 1.0))
				else:
					press_status_label.text = "Đã tới %s · giữ cao độ thêm một chút..." % target
					press_status_label.add_theme_color_override("font_color", Color(0.10, 0.58, 0.25, 1.0))
	else:
		press_silence_elapsed += delta
		if press_base_note_heard and press_silence_elapsed >= PRESS_MAX_SIGNAL_GAP:
			_reset_press_attempt_tracking("Tiếng đàn bị ngắt trước khi tới nốt đích. Hãy gảy lại và nhấn liền mạch.")
			return

	var target_hold_needed := 0.12 if _uses_mobile_audio_fallback() else 0.20
	if press_base_note_heard and press_target_hold_elapsed >= target_hold_needed:
		var result := _analyze_press_contour(press_cents_history, target_interval)
		if result.get("detected", false):
			_on_press_exercise_success(result)
			return

	if press_attempt_elapsed >= PRESS_ATTEMPT_TIMEOUT:
		if press_base_note_heard:
			_on_press_exercise_failed(target_interval)
		else:
			press_attempt_elapsed = 0.0
			if press_status_label:
				press_status_label.text = "Chưa nghe thấy lần gảy đúng dây. Hãy gảy nốt được chỉ dẫn để bắt đầu nhấn."
				press_status_label.add_theme_color_override("font_color", Color(0.70, 0.45, 0.08, 1.0))


func _get_technique_attack_identity() -> Dictionary:
	if analyzer and analyzer.has_method("get_dan_tranh_attack_identity"):
		var identity = analyzer.call("get_dan_tranh_attack_identity")
		if identity is Dictionary:
			return identity
	return {}


func _get_current_technique_attack_generation() -> int:
	return int(_get_technique_attack_identity().get("generation", -1))


func _is_press_source_attack_valid(identity: Dictionary, source: String) -> bool:
	return _is_valid_technique_source_attack(identity, source)


func _is_press_contour_session_valid(identity: Dictionary, source: String, generation: int) -> bool:
	return generation > 0 \
		and int(identity.get("generation", -1)) == generation \
		and (_uses_mobile_audio_fallback() or _is_press_source_attack_valid(identity, source))


func _is_valid_technique_source_attack(identity: Dictionary, expected_note: String) -> bool:
	if not bool(identity.get("active", false)) \
			or int(identity.get("generation", -1)) <= 0 \
			or float(identity.get("confidence", 0.0)) <= 0.0:
		return false
	var expected_string := int(NOTE_TO_STRING.get(expected_note, -1))
	var identity_matches := expected_string >= 0 \
		and int(identity.get("string_index", -1)) == expected_string \
		and str(identity.get("note_name", "")) == expected_note
	if identity_matches:
		return true
	# Xogot has no native GDExtension. Its first short YIN window can map a
	# harmonic before the following contour stabilizes, so verify the expected
	# source directly from the live pitch instead of rejecting the whole gesture.
	if _uses_mobile_audio_fallback() and analyzer:
		var expected_hz := float(NOTE_FREQS.get(expected_note, 0.0))
		var live_pitch := float(analyzer.current_pitch)
		if expected_hz > 0.0 and live_pitch > 0.0:
			var cents := absf(1200.0 * log(live_pitch / expected_hz) / log(2.0))
			return cents <= 70.0
	return false


func _is_press_added_sound_level(current_db: float, minimum_db: float, contour_elapsed: float) -> bool:
	var rise_db := 16.0 if _uses_mobile_audio_fallback() else PRESS_ADDED_SOUND_RISE_DB
	return contour_elapsed >= 0.12 and current_db >= minimum_db + rise_db


func _reset_press_attempt_tracking(message: String) -> void:
	press_cents_history.clear()
	press_sample_accumulator = 0.0
	press_attempt_elapsed = 0.0
	press_silence_elapsed = 0.0
	press_target_hold_elapsed = 0.0
	press_base_note_heard = false
	press_attack_generation = -1
	press_max_cents = 0.0
	press_contour_elapsed = 0.0
	press_min_amplitude_db = 0.0
	press_added_sound_elapsed = 0.0
	if press_status_label:
		press_status_label.text = message
		press_status_label.add_theme_color_override("font_color", Color(0.78, 0.22, 0.16, 1.0))

func _analyze_press_contour(history: Array[float], target_interval: float) -> Dictionary:
	var result := {
		"detected": false,
		"max_cents": 0.0,
		"final_cents": 0.0,
		"rise_time": 0.0,
		"rise_delay": 0.0,
		"smoothness": 0.0,
		"max_step": 0.0,
		"reversals": 0
	}
	var mobile_fallback := _uses_mobile_audio_fallback()
	var minimum_samples := 8 if mobile_fallback else 10
	if history.size() < minimum_samples or target_interval <= 0.0:
		return result
	var smoothed: Array[float] = []
	for i in range(history.size()):
		var from_idx := maxi(0, i - 1)
		var to_idx := mini(history.size() - 1, i + 1)
		var sum := 0.0
		for j in range(from_idx, to_idx + 1):
			sum += history[j]
		smoothed.append(sum / float(to_idx - from_idx + 1))

	var max_cents := smoothed[0]
	var positive_motion := 0.0
	var negative_motion := 0.0
	var rise_start_idx := -1
	var target_idx := -1
	var max_step := 0.0
	var reversal_count := 0
	var previous_direction := 0
	for i in range(smoothed.size()):
		max_cents = maxf(max_cents, smoothed[i])
		if rise_start_idx < 0 and smoothed[i] >= target_interval * 0.12:
			rise_start_idx = i
		if target_idx < 0 and smoothed[i] >= target_interval - 38.0:
			target_idx = i
		if i > 0:
			var movement := smoothed[i] - smoothed[i - 1]
			max_step = maxf(max_step, absf(movement))
			if movement >= 0.0:
				positive_motion += movement
			elif absf(movement) > 3.0:
				negative_motion += absf(movement)
			if target_idx < 0 and absf(movement) > 4.0:
				var movement_direction := 1 if movement > 0.0 else -1
				if previous_direction != 0 and movement_direction != previous_direction:
					reversal_count += 1
				previous_direction = movement_direction
	var final_count := mini(8, smoothed.size())
	var final_sum := 0.0
	for i in range(smoothed.size() - final_count, smoothed.size()):
		final_sum += smoothed[i]
	var final_cents := final_sum / float(final_count)
	var rise_time := 0.0
	if rise_start_idx >= 0 and target_idx >= rise_start_idx:
		rise_time = float(target_idx - rise_start_idx) * PRESS_SAMPLE_INTERVAL
	var rise_delay := float(rise_start_idx) * PRESS_SAMPLE_INTERVAL if rise_start_idx >= 0 else 999.0
	var smoothness := positive_motion / maxf(positive_motion + negative_motion, 0.001)
	result["max_cents"] = max_cents
	result["final_cents"] = final_cents
	result["rise_time"] = rise_time
	result["rise_delay"] = rise_delay
	result["smoothness"] = smoothness
	result["max_step"] = max_step
	result["reversals"] = reversal_count
	var source_tolerance := 70.0 if mobile_fallback else 55.0
	var target_reach_tolerance := 55.0 if mobile_fallback else 38.0
	var final_tolerance := 70.0 if mobile_fallback else 42.0
	var minimum_rise_time := 0.05 if mobile_fallback else 0.10
	var maximum_rise_delay := 1.10 if mobile_fallback else PRESS_MAX_RISE_DELAY
	var maximum_step := 180.0 if mobile_fallback else PRESS_MAX_SAMPLE_JUMP_CENTS
	var minimum_smoothness := 0.55 if mobile_fallback else 0.68
	result["detected"] = absf(smoothed[0]) <= source_tolerance \
		and max_cents >= target_interval - target_reach_tolerance \
		and max_cents <= target_interval + 75.0 \
		and absf(final_cents - target_interval) <= final_tolerance \
		and rise_time >= minimum_rise_time and rise_time <= 2.5 \
		and rise_delay <= maximum_rise_delay \
		and max_step <= maximum_step \
		and reversal_count <= (5 if mobile_fallback else 3) \
		and smoothness >= minimum_smoothness
	return result

func _on_press_exercise_success(result: Dictionary) -> void:
	press_exercise_locked = true
	press_display_notes[press_exercise_idx * 2]["color"] = Color(0.12, 0.78, 0.30, 1.0)
	press_display_notes[press_exercise_idx * 2 + 1]["color"] = Color(0.12, 0.78, 0.30, 1.0)
	staff_display.queue_redraw()
	var exercise: Dictionary = PRESS_EXERCISES[press_exercise_idx]
	if press_progress_bar:
		press_progress_bar.value = float(press_exercise_idx + 1)
	if press_status_label:
		press_status_label.text = "✓ Nhấn đúng %s → %s · đích %.0f cents · độ mượt %.0f%%" % [
			exercise["source"],
			exercise["target"],
			float(result.get("final_cents", 0.0)),
			float(result.get("smoothness", 0.0)) * 100.0
		]
		press_status_label.add_theme_color_override("font_color", Color(0.10, 0.58, 0.25, 1.0))
	_dan_tranh_attempts.append({
		"correct_string": true,
		"cents_error": absf(float(result.get("final_cents", 0.0)) - float(exercise["interval"])),
		"timing": 92.0,
		"attack_clarity": 95.0,
		"sustain_duration": 100.0,
		"vibrato_detected": false,
		"bend_detected": true
	})
	if ai_audio:
		ai_audio.speak_vietnamese("Tốt lắm! Bạn đã nhấn đúng từ %s lên %s." % [exercise["source"], exercise["target"]])
	var completed_exercise := press_exercise_idx
	get_tree().create_timer(1.3).timeout.connect(func():
		if current_state == State.PRACTICE and _is_press_practice() and press_exercise_idx == completed_exercise:
			_start_press_exercise(completed_exercise + 1)
	)

func _on_press_exercise_failed(target_interval: float) -> void:
	press_exercise_locked = true
	press_display_notes[press_exercise_idx * 2]["color"] = Color(0.88, 0.16, 0.14, 1.0)
	press_display_notes[press_exercise_idx * 2 + 1]["color"] = Color(0.88, 0.16, 0.14, 1.0)
	staff_display.queue_redraw()
	var feedback := "Chưa nhận đúng nốt gốc. Hãy gảy đúng dây được chỉ dẫn trước."
	var overlay_detail := "Cần gảy đúng dây trước khi nhấn"
	if press_base_note_heard:
		if press_max_cents < target_interval - 38.0:
			feedback = "Chưa đủ cao. Hãy nhấn thêm một chút và giữ lực tay trái."
			overlay_detail = "Cần nhấn cao thêm"
		elif press_max_cents > target_interval + 62.0:
			feedback = "Cao quá. Hãy giảm lực nhấn để không vượt nốt đích."
			overlay_detail = "Cần giảm lực nhấn"
		else:
			feedback = "Đã gần đúng cao độ nhưng chưa giữ ổn định. Hãy nhấn đều và giữ nốt đích."
			overlay_detail = "Cần giữ cao độ ổn định"
	var exercise: Dictionary = PRESS_EXERCISES[press_exercise_idx]
	_show_practice_error_feedback(
		str(exercise["source"]),
		overlay_detail,
		"Chưa đúng kỹ thuật Nhấn"
	)
	if press_status_label:
		press_status_label.text = feedback
		press_status_label.add_theme_color_override("font_color", Color(0.78, 0.22, 0.16, 1.0))
	_dan_tranh_attempts.append({
		"correct_string": false,
		"cents_error": absf(target_interval - press_max_cents),
		"timing": 30.0,
		"attack_clarity": 55.0,
		"sustain_duration": 30.0,
		"vibrato_detected": false,
		"bend_detected": false
	})
	if ai_audio:
		ai_audio.speak_vietnamese(feedback)
	var failed_exercise := press_exercise_idx
	get_tree().create_timer(1.6).timeout.connect(func():
		if current_state == State.PRACTICE and _is_press_practice() and press_exercise_idx == failed_exercise:
			_start_press_exercise(failed_exercise)
	)

func _start_vibrato_practice() -> void:
	vibrato_note_idx = 0
	staff_display.show_metronome = false
	staff_display.show_hit_line = false
	staff_display.show_clef = true
	staff_display.show_time_sig = true
	staff_display.beats_per_measure = 4
	staff_display.time_sig_denominator = 4
	staff_display.glissando_arrow_mode = ""
	if speed_bar_container:
		speed_bar_container.visible = false
	_build_vibrato_display_notes()
	_start_vibrato_note(0)

func _build_vibrato_display_notes() -> void:
	var staff_width: float = maxf(staff_display.size.x, get_viewport_rect().size.x - 110.0)
	var start_x := 330.0
	var end_x: float = maxf(start_x + 780.0, staff_width - 120.0)
	vibrato_display_notes.clear()
	for i in range(VIBRATO_NOTES.size()):
		var ratio := float(i) / float(maxi(1, VIBRATO_NOTES.size() - 1))
		var note_x := lerpf(start_x, end_x, ratio)
		var next_x := lerpf(start_x, end_x, float(i + 1) / float(maxi(1, VIBRATO_NOTES.size() - 1))) if i + 1 < VIBRATO_NOTES.size() else end_x + 90.0
		vibrato_display_notes.append({
			"note": "ZT_" + VIBRATO_NOTES[i],
			"x": note_x,
			"color": Color(0.16, 0.14, 0.12, 1.0),
			"type": "half",
			"cue": "vibrato",
			"bar_after": i < VIBRATO_NOTES.size() - 1,
			"bar_x": (note_x + next_x) * 0.5
		})
	staff_display.set_notes(vibrato_display_notes)
	staff_display.queue_redraw()

func _start_vibrato_note(note_index: int) -> void:
	if note_index >= VIBRATO_NOTES.size():
		if analyzer:
			analyzer.contour_tracking_mode = false
		_finish_practice()
		return
	vibrato_note_idx = note_index
	vibrato_pitch_history.clear()
	vibrato_sample_accumulator = 0.0
	vibrato_attempt_elapsed = 0.0
	vibrato_silence_elapsed = 0.0
	vibrato_base_note_heard = false
	vibrato_note_locked = false
	vibrato_attack_generation = -1
	vibrato_contour_elapsed = 0.0
	vibrato_min_amplitude_db = 0.0
	vibrato_added_sound_elapsed = 0.0
	# A still-ringing note from the sample/instruction must not open a new turn.
	vibrato_consumed_attack_generation = _get_current_technique_attack_generation()
	for i in range(vibrato_display_notes.size()):
		if i < note_index:
			vibrato_display_notes[i]["color"] = Color(0.12, 0.72, 0.30, 1.0)
		elif i == note_index:
			vibrato_display_notes[i]["color"] = C_GOLD
		else:
			vibrato_display_notes[i]["color"] = Color(0.16, 0.14, 0.12, 1.0)
	staff_display.queue_redraw()

	var target_note := VIBRATO_NOTES[note_index]
	var target_string := int(NOTE_TO_STRING.get(target_note, 0)) + 1
	if vibrato_instruction_label:
		vibrato_instruction_label.text = "Nốt %d/7 · %s (dây %d)" % [note_index + 1, target_note, target_string]
	if vibrato_status_label:
		vibrato_status_label.text = "Gảy nốt rồi rung ngay bằng tay trái; giữ tiếng rung đều ít nhất 1 giây."
		vibrato_status_label.add_theme_color_override("font_color", Color(0.30, 0.26, 0.20, 0.92))
	if vibrato_progress_bar:
		vibrato_progress_bar.value = float(note_index)
	if mic_status_lbl:
		mic_status_lbl.text = "🎙️ Đang nghe nốt %s và dao động rung dây" % target_note
		mic_status_lbl.add_theme_color_override("font_color", Color(0.24, 0.56, 0.35, 1.0))

func _process_vibrato_practice(delta: float) -> void:
	if _is_micro_scoring_blocked() or vibrato_note_locked or vibrato_note_idx >= VIBRATO_NOTES.size() or not analyzer:
		return
	vibrato_attempt_elapsed += delta
	var target_note := VIBRATO_NOTES[vibrato_note_idx]
	var target_hz := float(NOTE_FREQS.get(target_note, 0.0))
	var pitch := float(analyzer.current_pitch)
	var signal_active: bool = analyzer.current_amplitude_db > analyzer.volume_threshold_db and pitch > 0.0
	var attack_identity := _get_technique_attack_identity()

	if signal_active and target_hz > 0.0:
		var cents := 1200.0 * log(pitch / target_hz) / log(2.0)
		if not vibrato_base_note_heard:
			var generation := int(attack_identity.get("generation", -1))
			if absf(cents) <= 65.0 \
					and generation != vibrato_consumed_attack_generation \
					and _is_vibrato_source_attack_valid(attack_identity, target_note):
				vibrato_base_note_heard = true
				vibrato_attack_generation = generation
				vibrato_consumed_attack_generation = generation
				vibrato_contour_elapsed = 0.0
				vibrato_min_amplitude_db = float(analyzer.current_amplitude_db)
				vibrato_added_sound_elapsed = 0.0
				vibrato_silence_elapsed = 0.0
				if vibrato_status_label:
					vibrato_status_label.text = "Đã nhận đúng lần gảy dây %s. Tiếp tục rung đều tay trái..." % target_note
			elif bool(attack_identity.get("active", false)) \
					and int(attack_identity.get("string_index", -1)) >= 0 \
					and vibrato_status_label:
				var heard_note := str(attack_identity.get("note_name", "âm khác"))
				vibrato_status_label.text = "Đang nghe %s; cần gảy đúng dây %s trước khi rung." % [heard_note, target_note]
				vibrato_status_label.add_theme_color_override("font_color", Color(0.78, 0.22, 0.16, 1.0))
				_show_practice_error_feedback(
					target_note,
					"Đã nghe %s · cần gảy đúng dây %s trước" % [heard_note, target_note],
					"Sai dây"
				)
		else:
			if not _is_vibrato_contour_session_valid(attack_identity, target_note, vibrato_attack_generation):
				_reset_vibrato_attempt_tracking("Tiếng rung không còn thuộc lần gảy dây %s. Hãy gảy lại rồi rung." % target_note)
				return
			vibrato_contour_elapsed += delta
			vibrato_min_amplitude_db = minf(vibrato_min_amplitude_db, float(analyzer.current_amplitude_db))
			if _is_vibrato_added_sound_level(
					float(analyzer.current_amplitude_db),
					vibrato_min_amplitude_db,
					vibrato_contour_elapsed
			):
				vibrato_added_sound_elapsed += delta
			else:
				vibrato_added_sound_elapsed = maxf(0.0, vibrato_added_sound_elapsed - delta * 2.0)
			if vibrato_added_sound_elapsed >= VIBRATO_ADDED_SOUND_HOLD_SEC:
				_reset_vibrato_attempt_tracking("Phát hiện giọng hoặc âm mới chồng lên tiếng đàn. Hãy chỉ gảy và rung dây bằng tay trái.")
				return
			vibrato_silence_elapsed = 0.0
			if cents >= -70.0 and cents <= 190.0:
				vibrato_sample_accumulator += delta
				while vibrato_sample_accumulator >= VIBRATO_SAMPLE_INTERVAL:
					vibrato_sample_accumulator -= VIBRATO_SAMPLE_INTERVAL
					vibrato_pitch_history.append(cents)
					if vibrato_pitch_history.size() > 160:
						vibrato_pitch_history.pop_front()
	else:
		vibrato_silence_elapsed += delta
		if vibrato_base_note_heard and vibrato_silence_elapsed >= VIBRATO_MAX_SIGNAL_GAP:
			_reset_vibrato_attempt_tracking("Tiếng đàn bị ngắt giữa quá trình rung. Hãy gảy lại và rung liền mạch.")
			return

	var vibrato_samples_needed := 20 if _uses_mobile_audio_fallback() else 24
	if vibrato_base_note_heard and vibrato_pitch_history.size() >= vibrato_samples_needed:
		var result := _analyze_vibrato_cents(vibrato_pitch_history)
		if result.get("detected", false):
			_on_vibrato_note_success(result)
			return
		if vibrato_status_label:
			vibrato_status_label.text = "Đang đo rung: %.0f cents · %.1f Hz" % [
				float(result.get("depth_cents", 0.0)),
				float(result.get("rate_hz", 0.0))
			]

	if vibrato_attempt_elapsed >= VIBRATO_ATTEMPT_TIMEOUT:
		if vibrato_base_note_heard:
			_on_vibrato_note_failed()
		else:
			vibrato_attempt_elapsed = 0.0
			if vibrato_status_label:
				vibrato_status_label.text = "Chưa nghe thấy lần gảy đúng dây. Hãy gảy nốt được chỉ dẫn rồi mới bắt đầu rung."
				vibrato_status_label.add_theme_color_override("font_color", Color(0.70, 0.45, 0.08, 1.0))


func _is_vibrato_source_attack_valid(identity: Dictionary, target_note: String) -> bool:
	return _is_valid_technique_source_attack(identity, target_note)


func _is_vibrato_contour_session_valid(identity: Dictionary, target_note: String, generation: int) -> bool:
	return generation > 0 \
		and int(identity.get("generation", -1)) == generation \
		and (_uses_mobile_audio_fallback() or _is_vibrato_source_attack_valid(identity, target_note))


func _is_vibrato_added_sound_level(current_db: float, minimum_db: float, contour_elapsed: float) -> bool:
	var rise_db := 16.0 if _uses_mobile_audio_fallback() else VIBRATO_ADDED_SOUND_RISE_DB
	return contour_elapsed >= 0.12 and current_db >= minimum_db + rise_db


func _reset_vibrato_attempt_tracking(message: String) -> void:
	vibrato_pitch_history.clear()
	vibrato_sample_accumulator = 0.0
	vibrato_attempt_elapsed = 0.0
	vibrato_silence_elapsed = 0.0
	vibrato_base_note_heard = false
	vibrato_attack_generation = -1
	vibrato_contour_elapsed = 0.0
	vibrato_min_amplitude_db = 0.0
	vibrato_added_sound_elapsed = 0.0
	if vibrato_status_label:
		vibrato_status_label.text = message
		vibrato_status_label.add_theme_color_override("font_color", Color(0.78, 0.22, 0.16, 1.0))

func _analyze_vibrato_cents(history: Array[float]) -> Dictionary:
	var result := {
		"detected": false,
		"depth_cents": 0.0,
		"rate_hz": 0.0,
		"cycles": 0.0,
		"low_cents": 0.0,
		"high_cents": 0.0,
		"center_cents": 0.0,
		"raw_low_cents": 0.0,
		"raw_high_cents": 0.0,
		"duration": 0.0
	}
	var mobile_fallback := _uses_mobile_audio_fallback()
	var minimum_samples := 20 if mobile_fallback else 24
	if history.size() < minimum_samples:
		return result
	var raw_low_cents := float(history[0])
	var raw_high_cents := float(history[0])
	for raw_cents in history:
		raw_low_cents = minf(raw_low_cents, float(raw_cents))
		raw_high_cents = maxf(raw_high_cents, float(raw_cents))
	var smoothed: Array[float] = []
	for i in range(history.size()):
		var from_idx := maxi(0, i - 1)
		var to_idx := mini(history.size() - 1, i + 1)
		var sum := 0.0
		for j in range(from_idx, to_idx + 1):
			sum += history[j]
		smoothed.append(sum / float(to_idx - from_idx + 1))

	var sorted := smoothed.duplicate()
	sorted.sort()
	var low_idx := clampi(int(float(sorted.size() - 1) * 0.10), 0, sorted.size() - 1)
	var high_idx := clampi(int(float(sorted.size() - 1) * 0.90), 0, sorted.size() - 1)
	var depth: float = sorted[high_idx] - sorted[low_idx]
	var center: float = (sorted[high_idx] + sorted[low_idx]) * 0.5
	var low_cents: float = sorted[low_idx]
	var high_cents: float = sorted[high_idx]
	var hysteresis := maxf(2.5, depth * 0.10)
	var state := 0
	var switches := 0
	for value in smoothed:
		var centered: float = value - center
		if centered >= hysteresis and state <= 0:
			if state < 0:
				switches += 1
			state = 1
		elif centered <= -hysteresis and state >= 0:
			if state > 0:
				switches += 1
			state = -1
	var cycles := float(switches) * 0.5
	var duration := float(smoothed.size()) * VIBRATO_SAMPLE_INTERVAL
	var rate := cycles / maxf(duration, 0.001)
	result["depth_cents"] = depth
	result["rate_hz"] = rate
	result["cycles"] = cycles
	result["low_cents"] = low_cents
	result["high_cents"] = high_cents
	result["center_cents"] = center
	result["raw_low_cents"] = raw_low_cents
	result["raw_high_cents"] = raw_high_cents
	result["duration"] = duration
	# Left-hand đàn-tranh vibrato bends an open string mainly upward from its
	# resting pitch. Symmetric modulation around the sung note is typical vocal
	# vibrato and must not pass even when its rate/depth looks convincing.
	result["detected"] = duration >= (0.45 if mobile_fallback else VIBRATO_MIN_DURATION_SEC) \
		and cycles >= (1.0 if mobile_fallback else 1.5) \
		and rate >= 2.5 and rate <= 10.0 \
		and depth >= (12.0 if mobile_fallback else 8.0) \
		and depth <= (180.0 if mobile_fallback else 160.0) \
		and low_cents >= (-50.0 if mobile_fallback else -35.0) \
		and high_cents >= 8.0 \
		and raw_low_cents >= (-60.0 if mobile_fallback else VIBRATO_MIN_RAW_CENTS) \
		and raw_high_cents <= (180.0 if mobile_fallback else VIBRATO_MAX_RAW_UPWARD_CENTS)
	return result

func _on_vibrato_note_success(result: Dictionary) -> void:
	vibrato_note_locked = true
	vibrato_display_notes[vibrato_note_idx]["color"] = Color(0.12, 0.78, 0.30, 1.0)
	staff_display.queue_redraw()
	if vibrato_progress_bar:
		vibrato_progress_bar.value = float(vibrato_note_idx + 1)
	if vibrato_status_label:
		vibrato_status_label.text = "✓ Rung đúng %s · %.0f cents · %.1f Hz" % [
			VIBRATO_NOTES[vibrato_note_idx],
			float(result.get("depth_cents", 0.0)),
			float(result.get("rate_hz", 0.0))
		]
		vibrato_status_label.add_theme_color_override("font_color", Color(0.10, 0.58, 0.25, 1.0))
	_dan_tranh_attempts.append({
		"correct_string": true,
		"cents_error": 0.0,
		"timing": 95.0,
		"attack_clarity": 95.0,
		"sustain_duration": 100.0,
		"vibrato_detected": true,
		"bend_detected": false
	})
	if ai_audio:
		ai_audio.speak_vietnamese("Tốt lắm! Bạn đã rung đúng nốt %s." % VIBRATO_NOTES[vibrato_note_idx])
	var completed_note := vibrato_note_idx
	get_tree().create_timer(1.2).timeout.connect(func():
		if current_state == State.PRACTICE and _is_vibrato_practice() and vibrato_note_idx == completed_note:
			_start_vibrato_note(completed_note + 1)
	)

func _on_vibrato_note_failed() -> void:
	vibrato_note_locked = true
	vibrato_display_notes[vibrato_note_idx]["color"] = Color(0.88, 0.16, 0.14, 1.0)
	staff_display.queue_redraw()
	var feedback := "Chưa nhận được rung đều. Hãy gảy lại rồi nhồi dây nhẹ, liên tục bằng tay trái."
	_show_practice_error_feedback(
		VIBRATO_NOTES[vibrato_note_idx],
		"Cần gảy lại và rung đều hơn",
		"Chưa đúng kỹ thuật Rung"
	)
	if vibrato_status_label:
		vibrato_status_label.text = feedback
		vibrato_status_label.add_theme_color_override("font_color", Color(0.78, 0.22, 0.16, 1.0))
	_dan_tranh_attempts.append({
		"correct_string": false,
		"cents_error": 50.0,
		"timing": 30.0,
		"attack_clarity": 55.0,
		"sustain_duration": 30.0,
		"vibrato_detected": false,
		"bend_detected": false
	})
	if ai_audio:
		ai_audio.speak_vietnamese("Chưa thấy tiếng rung đều. Bạn hãy gảy lại nốt rồi rung nhẹ và liên tục bằng tay trái nhé.")
	var failed_note := vibrato_note_idx
	get_tree().create_timer(1.5).timeout.connect(func():
		if current_state == State.PRACTICE and _is_vibrato_practice() and vibrato_note_idx == failed_note:
			_start_vibrato_note(failed_note)
	)

func _start_tremolo_practice() -> void:
	tremolo_exercise_idx = 0
	staff_display.show_metronome = false
	staff_display.show_hit_line = false
	staff_display.show_clef = true
	staff_display.show_time_sig = true
	staff_display.beats_per_measure = 4
	staff_display.time_sig_denominator = 4
	staff_display.glissando_arrow_mode = ""
	if speed_bar_container:
		speed_bar_container.visible = false
	_start_tremolo_exercise(0)

func _start_tremolo_exercise(exercise_index: int) -> void:
	if exercise_index >= TREMOLO_EXERCISES.size():
		if analyzer:
			analyzer.rapid_sequence_mode = false
		_finish_practice()
		return
	tremolo_exercise_idx = exercise_index
	tremolo_attack_strings.clear()
	tremolo_attack_times.clear()
	tremolo_attack_generations.clear()
	tremolo_attempt_started_at = 0.0
	tremolo_last_attack_at = 0.0
	tremolo_last_seen_generation = -1
	tremolo_exercise_locked = false
	tremolo_wrong_attacks = 0
	_build_tremolo_display_notes()

	var exercise: Dictionary = TREMOLO_EXERCISES[exercise_index]
	var mode := str(exercise["mode"])
	if tremolo_instruction_label:
		tremolo_instruction_label.text = "Lượt %d/6 · %s" % [exercise_index + 1, exercise["title"]]
	if tremolo_status_label:
		if mode == "single":
			tremolo_status_label.text = "Gảy luân phiên hai ngón trên cùng một dây, nhanh và đều trong khoảng 3 giây."
		else:
			tremolo_status_label.text = "Gảy luân phiên hai dây cùng tên nốt, khác quãng; không gảy đồng thời."
		tremolo_status_label.add_theme_color_override("font_color", Color(0.30, 0.26, 0.20, 0.92))
	if tremolo_progress_bar:
		tremolo_progress_bar.value = float(exercise_index)
	if mic_status_lbl:
		mic_status_lbl.text = "🎙️ Đang nghe tốc độ và độ đều của kỹ thuật vê"
		mic_status_lbl.add_theme_color_override("font_color", Color(0.24, 0.56, 0.35, 1.0))

func _build_tremolo_display_notes() -> void:
	var exercise: Dictionary = TREMOLO_EXERCISES[tremolo_exercise_idx]
	var mode := str(exercise["mode"])
	var notes: Array = exercise["notes"]
	var staff_width: float = maxf(staff_display.size.x, get_viewport_rect().size.x - 110.0)
	var center_x := maxf(440.0, staff_width * 0.58)
	tremolo_display_notes.clear()
	if mode == "single":
		tremolo_display_notes.append({
			"note": "ZT_" + str(notes[0]),
			"x": center_x,
			"color": C_GOLD,
			"type": "half",
			"cue": "tremolo_single"
		})
	else:
		var source_x := center_x - 120.0
		var target_x := center_x + 120.0
		tremolo_display_notes.append({
			"note": "ZT_" + str(notes[0]),
			"x": source_x,
			"color": C_GOLD,
			"type": "half",
			"tremolo_pair_target": "ZT_" + str(notes[1]),
			"tremolo_pair_target_x": target_x
		})
		tremolo_display_notes.append({
			"note": "ZT_" + str(notes[1]),
			"x": target_x,
			"color": C_GOLD,
			"type": "half"
		})
	staff_display.set_notes(tremolo_display_notes)
	staff_display.queue_redraw()

func _append_tremolo_attack(
	string_idx: int,
	attack_time_sec: float,
	attack_generation: int,
	instrument_validated: bool
) -> void:
	if tremolo_exercise_locked or tremolo_exercise_idx >= TREMOLO_EXERCISES.size() \
			or not instrument_validated:
		return
	if string_idx < 0 or string_idx >= ALL_17_NOTES.size() \
			or attack_time_sec <= 0.0 or attack_generation <= tremolo_last_seen_generation:
		return
	tremolo_last_seen_generation = attack_generation
	var exercise: Dictionary = TREMOLO_EXERCISES[tremolo_exercise_idx]
	var notes: Array = exercise["notes"]
	var allowed_strings: Array[int] = []
	for note_name in notes:
		allowed_strings.append(int(NOTE_TO_STRING.get(str(note_name), -1)))
	if not allowed_strings.has(string_idx):
		tremolo_wrong_attacks += 1
		var target_label := str(notes[0])
		if notes.size() > 1:
			target_label = "%s – %s" % [notes[0], notes[1]]
		if tremolo_status_label:
			tremolo_status_label.text = "Sai dây. Hãy vê đúng %s." % target_label
			tremolo_status_label.add_theme_color_override("font_color", Color(0.78, 0.22, 0.16, 1.0))
		_show_practice_error_feedback(
			str(notes[0]),
			"Cần vê đúng: %s" % target_label,
			"Sai dây"
		)
		return

	if not tremolo_attack_times.is_empty() and attack_time_sec <= tremolo_attack_times.back():
		return
	if tremolo_attack_times.is_empty():
		tremolo_attempt_started_at = attack_time_sec
	tremolo_attack_strings.append(string_idx)
	tremolo_attack_times.append(attack_time_sec)
	tremolo_attack_generations.append(attack_generation)
	tremolo_last_attack_at = attack_time_sec
	var duration := attack_time_sec - tremolo_attempt_started_at
	var rate := float(tremolo_attack_times.size() - 1) / maxf(duration, 0.25)
	if tremolo_status_label:
		tremolo_status_label.text = "Đã nghe %d lần gảy · %.1f lần/giây · tiếp tục giữ đều..." % [
			tremolo_attack_times.size(), rate
		]
		tremolo_status_label.add_theme_color_override("font_color", Color(0.70, 0.45, 0.08, 1.0))

func _process_tremolo_practice() -> void:
	if _is_micro_scoring_blocked() or tremolo_exercise_locked or tremolo_attack_times.is_empty():
		return
	var now_sec := Time.get_ticks_msec() / 1000.0
	var duration := now_sec - tremolo_attempt_started_at
	var silence_gap := now_sec - tremolo_last_attack_at
	if duration >= TREMOLO_REQUIRED_DURATION or silence_gap >= TREMOLO_GAP_TIMEOUT \
			or duration >= TREMOLO_EXERCISE_TIMEOUT:
		_evaluate_tremolo_attempt()

func _evaluate_tremolo_attempt() -> void:
	if tremolo_exercise_locked:
		return
	tremolo_exercise_locked = true
	var exercise: Dictionary = TREMOLO_EXERCISES[tremolo_exercise_idx]
	var mode := str(exercise["mode"])
	var allowed_strings: Array[int] = []
	for note_name in exercise["notes"]:
		allowed_strings.append(int(NOTE_TO_STRING.get(str(note_name), -1)))
	var result := _analyze_tremolo_sequence(
		tremolo_attack_strings,
		tremolo_attack_times,
		tremolo_attack_generations,
		mode,
		allowed_strings,
		tremolo_wrong_attacks
	)
	if result.get("success", false):
		_on_tremolo_success(
			float(result.get("rate", 0.0)),
			float(result.get("regularity", 0.0)),
			float(result.get("alternating_ratio", 1.0))
		)
	else:
		_on_tremolo_failed(result)


func _analyze_tremolo_sequence(
	strings: Array[int],
	times: Array[float],
	generations: Array[int],
	mode: String,
	allowed_strings: Array[int],
	wrong_attacks: int
) -> Dictionary:
	var count := times.size()
	var result := {
		"success": false,
		"count": count,
		"duration": 0.0,
		"rate": 0.0,
		"max_gap": 99.0,
		"regularity": 0.0,
		"alternating_ratio": 1.0,
		"balance_ok": mode != "octave",
		"all_attacks_valid": false,
		"correct_strings": false
	}
	if mode not in ["single", "octave"]:
		return result
	if (mode == "single" and allowed_strings.size() != 1) \
			or (mode == "octave" and allowed_strings.size() != 2):
		return result
	var unique_allowed_strings: Dictionary = {}
	for allowed_string in allowed_strings:
		if allowed_string < 0 or allowed_string >= ALL_17_NOTES.size() \
				or unique_allowed_strings.has(allowed_string):
			return result
		unique_allowed_strings[allowed_string] = true
	if count == 0 or strings.size() != count or generations.size() != count \
			or wrong_attacks < 0:
		return result

	var all_attacks_valid := true
	var correct_strings := wrong_attacks == 0
	for i in range(count):
		if generations[i] <= 0 or (i > 0 and generations[i] <= generations[i - 1]):
			all_attacks_valid = false
		if not allowed_strings.has(strings[i]):
			correct_strings = false

	var duration := 0.0
	if count >= 2:
		duration = times.back() - times.front()
	var intervals: Array[float] = []
	for i in range(1, count):
		var interval := times[i] - times[i - 1]
		if interval <= 0.0:
			all_attacks_valid = false
		intervals.append(interval)
	var mean_interval := 0.0
	var max_gap := 99.0
	var regularity := 0.0
	if not intervals.is_empty():
		max_gap = 0.0
		for interval in intervals:
			mean_interval += interval
			max_gap = maxf(max_gap, interval)
		mean_interval /= float(intervals.size())
		var variance := 0.0
		for interval in intervals:
			variance += pow(interval - mean_interval, 2.0)
		variance /= float(intervals.size())
		var variation := sqrt(variance) / maxf(mean_interval, 0.001)
		regularity = clampf(1.0 - variation, 0.0, 1.0)
	var rate := float(maxi(0, count - 1)) / maxf(duration, 0.25)
	var alternating_ratio := 1.0
	var balance_ok := true
	if mode == "octave":
		var transitions := 0
		var first_count := 0
		var second_count := 0
		var first_string := allowed_strings[0]
		for i in range(count):
			if strings[i] == first_string:
				first_count += 1
			else:
				second_count += 1
			if i > 0 and strings[i] != strings[i - 1]:
				transitions += 1
		alternating_ratio = float(transitions) / float(maxi(1, count - 1))
		balance_ok = first_count >= 2 and second_count >= 2

	var mobile_fallback := _uses_mobile_audio_fallback()
	var minimum_attacks := 4 if mobile_fallback else TREMOLO_MIN_ATTACK_COUNT
	var minimum_duration := 0.75 if mobile_fallback else TREMOLO_MIN_SCORED_DURATION
	var maximum_gap := 0.60 if mobile_fallback else TREMOLO_MAX_ATTACK_GAP
	var minimum_regularity := 0.25 if mobile_fallback else TREMOLO_MIN_REGULARITY
	var success := all_attacks_valid and correct_strings \
		and count >= minimum_attacks \
		and duration >= minimum_duration \
		and rate >= TREMOLO_MIN_RATE and rate <= TREMOLO_MAX_RATE \
		and max_gap <= maximum_gap \
		and regularity >= minimum_regularity
	if mode == "octave":
		success = success and alternating_ratio >= 0.50 and balance_ok

	result["duration"] = duration
	result["rate"] = rate
	result["max_gap"] = max_gap
	result["regularity"] = regularity
	result["alternating_ratio"] = alternating_ratio
	result["balance_ok"] = balance_ok
	result["all_attacks_valid"] = all_attacks_valid
	result["correct_strings"] = correct_strings
	result["success"] = success
	return result

func _set_tremolo_note_color(color: Color) -> void:
	for note in tremolo_display_notes:
		note["color"] = color
	staff_display.queue_redraw()

func _on_tremolo_success(rate: float, regularity: float, alternating_ratio: float) -> void:
	_set_tremolo_note_color(Color(0.12, 0.78, 0.30, 1.0))
	if tremolo_progress_bar:
		tremolo_progress_bar.value = float(tremolo_exercise_idx + 1)
	if tremolo_status_label:
		var extra := ""
		if str(TREMOLO_EXERCISES[tremolo_exercise_idx]["mode"]) == "octave":
			extra = " · luân phiên %.0f%%" % (alternating_ratio * 100.0)
		tremolo_status_label.text = "✓ Vê đạt · %.1f lần/giây · độ đều %.0f%%%s" % [
			rate, regularity * 100.0, extra
		]
		tremolo_status_label.add_theme_color_override("font_color", Color(0.10, 0.58, 0.25, 1.0))
	_dan_tranh_attempts.append({
		"correct_string": true,
		"cents_error": 0.0,
		"timing": regularity * 100.0,
		"attack_clarity": clampf(rate / 7.0 * 100.0, 0.0, 100.0),
		"sustain_duration": 100.0,
		"vibrato_detected": false,
		"bend_detected": false,
		"tremolo_detected": true
	})
	if ai_audio:
		ai_audio.speak_vietnamese("Tốt lắm! Bạn đã thực hiện kỹ thuật vê nhanh, đều và liền mạch.")
	var completed_exercise := tremolo_exercise_idx
	get_tree().create_timer(1.4).timeout.connect(func():
		if current_state == State.PRACTICE and _is_tremolo_practice() and tremolo_exercise_idx == completed_exercise:
			_start_tremolo_exercise(completed_exercise + 1)
	)

func _on_tremolo_failed(result: Dictionary) -> void:
	_set_tremolo_note_color(Color(0.88, 0.16, 0.14, 1.0))
	var count := int(result.get("count", 0))
	var duration := float(result.get("duration", 0.0))
	var rate := float(result.get("rate", 0.0))
	var max_gap := float(result.get("max_gap", 99.0))
	var regularity := float(result.get("regularity", 0.0))
	var alternating_ratio := float(result.get("alternating_ratio", 1.0))
	var feedback := "Chưa đủ số lần gảy. Hãy dùng hai ngón gảy liên tục và nhanh hơn."
	if not result.get("all_attacks_valid", false):
		feedback = "Có lần tấn công âm chưa được xác nhận là tiếng dây đàn. Hãy vê rõ từng tiếng trên đàn thật."
	elif not result.get("correct_strings", false):
		feedback = "Bạn đã gảy nhầm dây. Hãy nhìn đúng nốt đang được chỉ dẫn trên sheet."
	elif count >= TREMOLO_MIN_ATTACK_COUNT and duration < TREMOLO_MIN_SCORED_DURATION:
		feedback = "Bạn đang vê quá ngắn. Hãy duy trì tiếng vê liên tục khoảng 3 giây."
	elif max_gap > TREMOLO_MAX_ATTACK_GAP:
		feedback = "Tiếng vê đang bị ngắt quãng. Hãy giữ hai ngón luân phiên liên tục."
	elif rate < TREMOLO_MIN_RATE:
		feedback = "Tốc độ vê còn chậm. Hãy tăng dần tốc độ nhưng vẫn giữ rõ từng tiếng."
	elif rate > TREMOLO_MAX_RATE:
		feedback = "Tốc độ quá gấp và chưa rõ tiếng. Hãy giảm nhẹ tốc độ để từng tiếng đều hơn."
	elif regularity < TREMOLO_MIN_REGULARITY:
		feedback = "Các lần gảy chưa đều. Hãy giữ chuyển động hai ngón ổn định hơn."
	elif str(TREMOLO_EXERCISES[tremolo_exercise_idx]["mode"]) == "octave" \
			and (alternating_ratio < 0.78 or not result.get("balance_ok", false)):
		feedback = "Hãy gảy luân phiên nốt thấp và nốt cao; không lặp nhiều lần trên cùng một dây."
	var target_notes: Array = TREMOLO_EXERCISES[tremolo_exercise_idx]["notes"]
	_show_practice_error_feedback(
		str(target_notes[0]),
		"Cần vê nhanh, đều và đúng dây",
		"Chưa đúng kỹ thuật Vê"
	)
	if tremolo_status_label:
		tremolo_status_label.text = feedback
		tremolo_status_label.add_theme_color_override("font_color", Color(0.78, 0.22, 0.16, 1.0))
	_dan_tranh_attempts.append({
		"correct_string": bool(result.get("correct_strings", false)),
		"cents_error": 0.0,
		"timing": regularity * 100.0,
		"attack_clarity": clampf(rate / 7.0 * 100.0, 0.0, 100.0),
		"sustain_duration": clampf(duration / TREMOLO_REQUIRED_DURATION * 100.0, 0.0, 100.0),
		"vibrato_detected": false,
		"bend_detected": false,
		"tremolo_detected": false
	})
	if ai_audio:
		ai_audio.speak_vietnamese(feedback)
	var failed_exercise := tremolo_exercise_idx
	get_tree().create_timer(1.6).timeout.connect(func():
		if current_state == State.PRACTICE and _is_tremolo_practice() and tremolo_exercise_idx == failed_exercise:
			_start_tremolo_exercise(failed_exercise)
	)


# --- Nghe mẫu cho các kỹ thuật đàn tranh đặc biệt ---------------------------
func _stop_technique_sample(stop_board_audio: bool = true) -> void:
	technique_sample_kind = TechniqueSampleKind.NONE
	technique_sample_demo_idx = 0
	technique_sample_elapsed = 0.0
	technique_sample_event_elapsed = 0.0
	technique_sample_sequence.clear()
	technique_sample_sequence_idx = 0
	technique_sample_in_gap = false
	if technique_sample_player and technique_sample_player.playing:
		technique_sample_player.stop()
	if stop_board_audio and zither_board and zither_board.has_method("stop_all_audio"):
		zither_board.call("stop_all_audio")


func _play_sustained_technique_note(note_name: String) -> bool:
	var string_idx := int(NOTE_TO_STRING.get(note_name, -1))
	if string_idx < 0 or string_idx >= dan_tranh_string_streams.size() or not technique_sample_player:
		return false
	technique_sample_player.stop()
	technique_sample_player.stream = dan_tranh_string_streams[string_idx]
	technique_sample_player.pitch_scale = 1.0
	technique_sample_player.play()
	# Chỉ chạy hiệu ứng dây; âm thanh do player riêng phát để có thể đổi cao độ.
	zither_board.call("pluck", string_idx, false)
	return true


func _set_sample_listening_status(text: String) -> void:
	if mic_status_lbl:
		mic_status_lbl.text = "🔊 " + text
		mic_status_lbl.add_theme_color_override("font_color", Color(0.72, 0.46, 0.08, 1.0))


func _finish_technique_sample(message: String, status_label: Label = null) -> void:
	technique_sample_kind = TechniqueSampleKind.NONE
	technique_sample_in_gap = false
	if technique_sample_player and technique_sample_player.playing:
		technique_sample_player.stop()
	if status_label:
		status_label.text = message
		status_label.add_theme_color_override("font_color", Color(0.10, 0.58, 0.25, 1.0))
	_set_sample_listening_status("Đã nghe xong mẫu. Bấm Luyện tập để tự thực hành.")


func _begin_glissando_sample() -> void:
	technique_sample_kind = TechniqueSampleKind.GLISSANDO
	technique_sample_demo_idx = 0
	_prepare_glissando_sample_round()


func _prepare_glissando_sample_round() -> void:
	_start_glissando_round(technique_sample_demo_idx)
	technique_sample_sequence.clear()
	var mode := str(GLISSANDO_ROUNDS[technique_sample_demo_idx]["mode"])
	if mode == "up":
		for string_idx in range(ALL_17_NOTES.size()):
			technique_sample_sequence.append(string_idx)
	else:
		for string_idx in range(ALL_17_NOTES.size() - 1, -1, -1):
			technique_sample_sequence.append(string_idx)
		if mode == "round":
			for string_idx in range(1, ALL_17_NOTES.size()):
				technique_sample_sequence.append(string_idx)
	technique_sample_sequence_idx = 0
	technique_sample_elapsed = 0.0
	technique_sample_event_elapsed = GLISSANDO_SAMPLE_INTERVAL
	technique_sample_in_gap = false
	if glissando_status_label:
		glissando_status_label.text = "Đang nghe mẫu %s..." % GLISSANDO_ROUNDS[technique_sample_demo_idx]["title"]
		glissando_status_label.add_theme_color_override("font_color", Color(0.72, 0.46, 0.08, 1.0))
	_set_sample_listening_status("Mẫu %s" % GLISSANDO_ROUNDS[technique_sample_demo_idx]["title"])


func _process_glissando_sample(delta: float) -> void:
	if technique_sample_in_gap:
		technique_sample_elapsed += delta
		if technique_sample_elapsed >= TECHNIQUE_SAMPLE_GAP:
			technique_sample_demo_idx += 1
			if technique_sample_demo_idx >= GLISSANDO_ROUNDS.size():
				if glissando_progress_bar:
					glissando_progress_bar.value = 17.0
				_finish_technique_sample("Đã nghe xong Á xuống, Á lên và Á vòng.", glissando_status_label)
			else:
				_prepare_glissando_sample_round()
		return

	technique_sample_event_elapsed += delta
	while technique_sample_event_elapsed >= GLISSANDO_SAMPLE_INTERVAL \
			and technique_sample_sequence_idx < technique_sample_sequence.size():
		technique_sample_event_elapsed -= GLISSANDO_SAMPLE_INTERVAL
		var string_idx := technique_sample_sequence[technique_sample_sequence_idx]
		zither_board.call("pluck", string_idx)
		technique_sample_sequence_idx += 1
		if glissando_progress_bar:
			glissando_progress_bar.value = minf(17.0, float(technique_sample_sequence_idx))
	if technique_sample_sequence_idx >= technique_sample_sequence.size():
		technique_sample_in_gap = true
		technique_sample_elapsed = 0.0


func _begin_press_sample() -> void:
	technique_sample_kind = TechniqueSampleKind.PRESS
	technique_sample_demo_idx = 0
	_prepare_press_sample_exercise()


func _prepare_press_sample_exercise() -> void:
	_start_press_exercise(technique_sample_demo_idx)
	technique_sample_elapsed = 0.0
	technique_sample_in_gap = false
	var exercise: Dictionary = PRESS_EXERCISES[technique_sample_demo_idx]
	_play_sustained_technique_note(str(exercise["source"]))
	if press_status_label:
		press_status_label.text = "Đang nghe mẫu nhấn %s → %s..." % [exercise["source"], exercise["target"]]
		press_status_label.add_theme_color_override("font_color", Color(0.72, 0.46, 0.08, 1.0))
	_set_sample_listening_status("Mẫu nhấn %s lên %s" % [exercise["source"], exercise["target"]])


func _process_press_sample(delta: float) -> void:
	if technique_sample_in_gap:
		technique_sample_elapsed += delta
		if technique_sample_elapsed >= TECHNIQUE_SAMPLE_GAP:
			technique_sample_demo_idx += 1
			if technique_sample_demo_idx >= PRESS_EXERCISES.size():
				if press_progress_bar:
					press_progress_bar.value = float(PRESS_EXERCISES.size())
				_finish_technique_sample("Đã nghe xong các mẫu kỹ thuật nhấn.", press_status_label)
			else:
				_prepare_press_sample_exercise()
		return

	technique_sample_elapsed += delta
	var target_cents := float(PRESS_EXERCISES[technique_sample_demo_idx]["interval"])
	var current_cents := 0.0
	if technique_sample_elapsed > 0.30:
		var rise_ratio := clampf((technique_sample_elapsed - 0.30) / 1.05, 0.0, 1.0)
		current_cents = lerpf(0.0, target_cents, smoothstep(0.0, 1.0, rise_ratio))
	if technique_sample_player and technique_sample_player.playing:
		technique_sample_player.pitch_scale = pow(2.0, current_cents / 1200.0)
	if technique_sample_elapsed >= PRESS_SAMPLE_DURATION:
		if technique_sample_player:
			technique_sample_player.stop()
		technique_sample_in_gap = true
		technique_sample_elapsed = 0.0


func _begin_vibrato_sample() -> void:
	technique_sample_kind = TechniqueSampleKind.VIBRATO
	technique_sample_demo_idx = 0
	_prepare_vibrato_sample_note()


func _prepare_vibrato_sample_note() -> void:
	_start_vibrato_note(technique_sample_demo_idx)
	technique_sample_elapsed = 0.0
	technique_sample_in_gap = false
	var note_name := VIBRATO_NOTES[technique_sample_demo_idx]
	_play_sustained_technique_note(note_name)
	if vibrato_status_label:
		vibrato_status_label.text = "Đang nghe mẫu rung dây nốt %s..." % note_name
		vibrato_status_label.add_theme_color_override("font_color", Color(0.72, 0.46, 0.08, 1.0))
	_set_sample_listening_status("Mẫu rung dây nốt %s" % note_name)


func _process_vibrato_sample(delta: float) -> void:
	if technique_sample_in_gap:
		technique_sample_elapsed += delta
		if technique_sample_elapsed >= TECHNIQUE_SAMPLE_GAP:
			technique_sample_demo_idx += 1
			if technique_sample_demo_idx >= VIBRATO_NOTES.size():
				if vibrato_progress_bar:
					vibrato_progress_bar.value = float(VIBRATO_NOTES.size())
				_finish_technique_sample("Đã nghe xong các mẫu kỹ thuật rung dây.", vibrato_status_label)
			else:
				_prepare_vibrato_sample_note()
		return

	technique_sample_elapsed += delta
	var vibrato_cents := 0.0
	if technique_sample_elapsed > 0.25:
		var onset := clampf((technique_sample_elapsed - 0.25) / 0.25, 0.0, 1.0)
		vibrato_cents = onset * (18.0 + 18.0 * sin((technique_sample_elapsed - 0.25) * TAU * 5.5))
	if technique_sample_player and technique_sample_player.playing:
		technique_sample_player.pitch_scale = pow(2.0, vibrato_cents / 1200.0)
	if technique_sample_elapsed >= VIBRATO_DEMO_DURATION:
		if technique_sample_player:
			technique_sample_player.stop()
		technique_sample_in_gap = true
		technique_sample_elapsed = 0.0


func _begin_tremolo_sample() -> void:
	technique_sample_kind = TechniqueSampleKind.TREMOLO
	technique_sample_demo_idx = 0
	_prepare_tremolo_sample_exercise()


func _prepare_tremolo_sample_exercise() -> void:
	_start_tremolo_exercise(technique_sample_demo_idx)
	technique_sample_elapsed = 0.0
	technique_sample_event_elapsed = TREMOLO_SAMPLE_INTERVAL
	technique_sample_sequence_idx = 0
	technique_sample_in_gap = false
	var exercise: Dictionary = TREMOLO_EXERCISES[technique_sample_demo_idx]
	if tremolo_status_label:
		tremolo_status_label.text = "Đang nghe mẫu %s..." % exercise["title"]
		tremolo_status_label.add_theme_color_override("font_color", Color(0.72, 0.46, 0.08, 1.0))
	_set_sample_listening_status("Mẫu %s" % exercise["title"])


func _process_tremolo_sample(delta: float) -> void:
	if technique_sample_in_gap:
		technique_sample_elapsed += delta
		if technique_sample_elapsed >= TECHNIQUE_SAMPLE_GAP:
			technique_sample_demo_idx += 1
			if technique_sample_demo_idx >= TREMOLO_EXERCISES.size():
				if tremolo_progress_bar:
					tremolo_progress_bar.value = float(TREMOLO_EXERCISES.size())
				_finish_technique_sample("Đã nghe xong các mẫu kỹ thuật vê.", tremolo_status_label)
			else:
				_prepare_tremolo_sample_exercise()
		return

	technique_sample_elapsed += delta
	technique_sample_event_elapsed += delta
	var notes: Array = TREMOLO_EXERCISES[technique_sample_demo_idx]["notes"]
	while technique_sample_event_elapsed >= TREMOLO_SAMPLE_INTERVAL:
		technique_sample_event_elapsed -= TREMOLO_SAMPLE_INTERVAL
		var note_name := str(notes[technique_sample_sequence_idx % notes.size()])
		var string_idx := int(NOTE_TO_STRING.get(note_name, -1))
		if string_idx >= 0:
			zither_board.call("pluck", string_idx)
		technique_sample_sequence_idx += 1
	if technique_sample_elapsed >= TREMOLO_SAMPLE_DURATION:
		technique_sample_in_gap = true
		technique_sample_elapsed = 0.0


func _process_technique_sample(delta: float) -> void:
	match technique_sample_kind:
		TechniqueSampleKind.GLISSANDO:
			_process_glissando_sample(delta)
		TechniqueSampleKind.PRESS:
			_process_press_sample(delta)
		TechniqueSampleKind.VIBRATO:
			_process_vibrato_sample(delta)
		TechniqueSampleKind.TREMOLO:
			_process_tremolo_sample(delta)


func _is_note_missing(note_idx: int) -> bool:
	if current_lesson_id != "dan_tranh_level_1_bai_3_practice":
		return false
	# Mỗi nốt màu bạc cách nhau 15 nốt đen (tức là nốt khuyết xuất hiện sau mỗi 16 nốt: chỉ số 15, 31, 47, 63...)
	return note_idx % 16 == 15


func _start_practice():
	_stop_technique_sample()
	current_state = State.PRACTICE
	if error_flash_tween and error_flash_tween.is_running():
		error_flash_tween.kill()
	if error_pulse_tween and error_pulse_tween.is_running():
		error_pulse_tween.kill()
	if error_shake_tween and error_shake_tween.is_running():
		error_shake_tween.kill()
	_set_error_demo_note_color(false)
	error_feedback_showing = false
	error_feedback_target_note = ""
	error_feedback_title = "Chưa đúng"
	error_feedback_detail = ""
	_shrink_teacher()
	feedback_area.visible = true
	practice_idx = 0
	practice_time = 0.0
	active_falling_notes.clear()
	consecutive_hits = 0
	consecutive_misses = 0
	total_misses = 0
	# Every real practice can now pulse its exact target note on a validated error.
	# The 99+ lesson still keeps its separate automatic demo timer below.
	staff_display.use_note_colors = true
	if _is_error_flash_demo():
		error_flash_timer = 0.75
		error_flash_note = {}
		error_feedback_showing = false
		if error_flash_overlay:
			error_flash_overlay.modulate.a = 1.0
		if error_flash_badge:
			error_flash_badge.modulate.a = 0.0
		if error_flash_halo:
			error_flash_halo.modulate.a = 0.0
	_apply_adaptive_speed()
	if speed_bar_container:
		speed_bar_container.visible = true
	if skip_intro_btn:
		skip_intro_btn.visible = false
	if previous_intro_btn:
		previous_intro_btn.visible = false
	if pause_btn:
		pause_btn.visible = true
	
	# Căn giữa khuôn nhạc khi bắt đầu thực hành chính thức
	staff_display.visible = true
	if staff_card: staff_card.visible = true
	if title_plaque: title_plaque.visible = true
	if pill_badge: pill_badge.visible = true
	if sub_instr_row: sub_instr_row.visible = true
	_update_staff_layout()
	if pitch_box:
		pitch_box.visible = true
	if _is_error_flash_demo() and mic_status_lbl:
		mic_status_lbl.text = "Demo tự động: phản hồi sai bật lên từ nốt và lặp lại định kỳ"
		mic_status_lbl.add_theme_color_override("font_color", Color(0.74, 0.18, 0.16, 1.0))
	
	zither_board.call("clear_lesson_markers")
	if analyzer:
		analyzer.rapid_sequence_mode = _is_glissando_practice() or _is_tremolo_practice()
		analyzer.contour_tracking_mode = _is_press_practice() or _is_vibrato_practice()

	if _is_glissando_practice():
		_start_glissando_round(0)
		if is_sample_mode:
			_begin_glissando_sample()
		return
	if _is_press_practice():
		_start_press_practice()
		if is_sample_mode:
			_begin_press_sample()
		return
	if _is_vibrato_practice():
		_start_vibrato_practice()
		if is_sample_mode:
			_begin_vibrato_sample()
		return
	if _is_tremolo_practice():
		_start_tremolo_practice()
		if is_sample_mode:
			_begin_tremolo_sample()
		return
		
	# Determine BPM based on current lesson
	var lesson_bpm: float = 60.0
	if current_lesson_id == "dan_tranh_level_3_bai_7_practice": lesson_bpm = 80.0
	elif current_lesson_id.begins_with("dan_tranh_level_3"): lesson_bpm = 80.0
	elif current_lesson_id.begins_with("dan_tranh_level_4"): lesson_bpm = 85.0
	elif current_lesson_id.begins_with("dan_tranh_level_5"): lesson_bpm = 90.0
	
	var scroll_speed = 350.0
	var distance_per_beat = (scroll_speed * 60.0) / lesson_bpm
	var _staff_w := staff_display.size.x if staff_display.size.x > 50.0 else get_viewport_rect().size.x
	var start_x = _staff_w + 100.0
	
	var cur_beat: float = 0.0
	for i in range(lesson_sheet.size()):
		var raw_note_name = lesson_sheet[i]
		var dur = lesson_durations[i] if i < lesson_durations.size() else 1.0
		
		if raw_note_name != "Rest" and raw_note_name != "-":
			var notes_in_chord = raw_note_name.split("+")
			var tail_len = 0.0 # Dan Tranh is a plucked zither instrument, so no extended hold tail!
			var is_demo_lesson = false
			var missing = true
			var note_color = Color(0.6, 0.6, 0.6, 0.9) # Gray by default for fill-in notes
			
			if is_demo_lesson:
				missing = _is_note_missing(i)
				note_color = Color(0.6, 0.6, 0.6, 0.9) if missing else Color(0.1, 0.1, 0.1, 1.0)
				
			var cue_name = current_song_cues[i] if i < current_song_cues.size() else ""
			var fingering = current_song_fingerings[i] if i < current_song_fingerings.size() else ""
			
			var n_type = "quarter"
			if dur >= 3.5:
				n_type = "whole"
			elif dur >= 1.5:
				n_type = "half"
			elif dur >= 0.75:
				n_type = "quarter"
			elif dur >= 0.35:
				n_type = "eighth"
			else:
				n_type = "sixteenth"
				
			for chord_component_index in range(notes_in_chord.size()):
				var single_note = notes_in_chord[chord_component_index]
				var string_idx = NOTE_TO_STRING.get(single_note, 0)
				var final_color = note_color
						
				active_falling_notes.append({
					"note": "ZT_" + single_note,
					"x": start_x + cur_beat * distance_per_beat,
					"color": final_color,
					"target_string": string_idx,
					"hit": false,
					"duration": dur,
					"tail": tail_len,
					"is_missing": missing,
					"cue": cue_name,
					"fingering": fingering,
					"chord_group_id": i,
					"chord_component_index": chord_component_index,
					"raw_chord_name": raw_note_name,
					"type": n_type
				})
		cur_beat += dur

func _process_practice(delta):
	if active_falling_notes.size() == 0 and practice_idx >= lesson_sheet.size():
		_finish_practice()
		return
		
	if mic_cooldown > 0.0:
		mic_cooldown -= delta
	wrong_note_cooldown = maxf(0.0, wrong_note_cooldown - delta)

	practice_time += delta
	var hit_x = staff_display.hit_line_x
	var scroll_speed = 350.0
	
	var is_wait_mode = true # Always wait for the correct note sound before advancing past notes!
	
	# In Wait Mode, check if the first un-hit note has reached the hit line
	var freeze_unhit_notes = false
	if is_wait_mode:
		for note in active_falling_notes:
			if not note.get("hit", false):
				if note["x"] <= hit_x:
					note["x"] = hit_x # Hold note exactly on hit line
					freeze_unhit_notes = true
				break
				
	var move_dist = scroll_speed * current_speed_multiplier * delta if not freeze_unhit_notes else 0.0
	var all_passed = true
	
	for note in active_falling_notes:
		if not (freeze_unhit_notes and not note.get("hit", false)):
			note["x"] -= move_dist
			
		if note["x"] > -50.0:
			all_passed = false
			
		var clean_note = note["note"].replace("ZT_", "")
		var s_idx = note["target_string"]
		
		# Auto-play sample note in sample mode
		if (not note.get("is_missing", false) or is_sample_mode) and not note.get("hit", false):
			if note["x"] <= hit_x:
				note["color"] = Color(0.2, 0.8, 0.2)
				note["hit"] = true
				zither_board.call("pluck", s_idx)
				
				# Dynamic tempo: Hit logic
				consecutive_hits += 1
				consecutive_misses = 0
				if consecutive_hits >= 5:
					current_speed_multiplier = user_speed_multiplier
				
		# Active practice note handling
		if not is_sample_mode and note.get("is_missing", false) and not note.get("hit", false):
			if abs(note["x"] - hit_x) < 40.0 or (is_wait_mode and note["x"] <= hit_x):
				var raw_chord_name = note.get("raw_chord_name", clean_note)
				if not _should_score_polyphonic_component(
					raw_chord_name,
					int(note.get("chord_component_index", 0))
				):
					continue

				# Highlight target string on zither board
				zither_board.call("set_lesson_marker", s_idx, "Gảy: " + clean_note, 1)
				
				var target_hz = NOTE_FREQS.get(clean_note, 0.0)
				if mic_cooldown <= 0.0 and _check_mic_pitch(target_hz, delta, raw_chord_name):
					var cents_err = 0.0
					if analyzer:
						var pitch = analyzer.current_pitch
						if pitch > 0.0 and target_hz > 0.0:
							cents_err = 1200.0 * log(pitch / target_hz) / log(2.0)
					
					var tech_res = {"vibrato_detected": false, "bend_detected": false}
					if analyzer and analyzer._analyzer and target_hz > 0.0:
						tech_res = analyzer._analyzer.analyze_pitch_contour(analyzer._pitch_history, target_hz, AudioServer.get_mix_rate())
					
					var pluck_dist = abs(note["x"] - hit_x)
					var timing_score = clamp(100.0 - pluck_dist * 2.0, 0.0, 100.0)
					
					_dan_tranh_attempts.append({
						"correct_string": true,
						"cents_error": cents_err,
						"timing": timing_score,
						"attack_clarity": 100.0,
						"sustain_duration": 100.0,
						"vibrato_detected": tech_res.get("vibrato_detected", false),
						"bend_detected": tech_res.get("bend_detected", false)
					})

					var chord_group = note.get("chord_group_id", -1)
					if chord_group != -1:
						for other_note in active_falling_notes:
							if other_note.get("chord_group_id", -1) == chord_group:
								other_note["color"] = Color(0.2, 0.8, 0.3, 1.0)
								other_note["hit"] = true
								zither_board.call("pluck", other_note["target_string"])
					else:
						note["color"] = Color(0.2, 0.8, 0.3, 1.0)
						note["hit"] = true
						zither_board.call("pluck", s_idx)
						
					zither_board.call("clear_lesson_markers")
					zither_board.call("set_lesson_marker", s_idx, "Chính xác!", 2)
					if pitch_note_lbl: pitch_note_lbl.text = "🎵 Nốt: " + clean_note
					if pitch_status_lbl:
						pitch_status_lbl.text = "🟢 CHÍNH XÁC!"
						pitch_status_lbl.add_theme_color_override("font_color", Color(0.25, 0.95, 0.45))
					if ai_audio: ai_audio.speak_vietnamese("Tốt lắm! Chính xác hợp âm." if chord_group != -1 else "Tốt lắm! Chính xác nốt %s." % clean_note)
					wrong_note_time = 0.0
					consecutive_hits += 1
					consecutive_misses = 0
					mic_cooldown = 0.4
					continue
					
				# 2. Check if user played WRONG note (requires 0.18s debounce hold time)
				if not _is_micro_scoring_blocked() and analyzer and wrong_note_cooldown <= 0.0 and mic_cooldown <= 0.0:
					var db = analyzer.current_amplitude_db
					if db > -28.0:
						var note_info = analyzer.detect_dan_tranh_note(analyzer._analysis_buffer, AudioServer.get_mix_rate())
						var det_name = note_info.get("note_name", "None")
						var det_idx = note_info.get("string_index", -1)
						var is_partial_polyphonic: bool = "+" in raw_chord_name \
							and det_name in raw_chord_name.split("+")
						if det_name != "None" and det_idx >= 0 and is_partial_polyphonic:
							wrong_note_time += delta
							if wrong_note_time >= REQUIRED_WRONG_HOLD_TIME:
								wrong_note_time = 0.0
								wrong_note_cooldown = 2.0
								_show_polyphonic_incomplete(raw_chord_name)
							continue
						var is_wrong = true
						if "+" in raw_chord_name:
							if det_name in raw_chord_name.split("+"):
								is_wrong = false
						else:
							if det_name == clean_note or det_idx == s_idx or _is_harmonic_or_octave_of_target(det_name, det_idx, clean_note, s_idx):
								is_wrong = false
								
						if det_name != "None" and is_wrong and det_idx >= 0:

							wrong_note_time += delta
							if wrong_note_time >= REQUIRED_WRONG_HOLD_TIME:
								wrong_note_time = 0.0
								wrong_note_cooldown = 3.5 # Cooldown to avoid repeating speech
								_dan_tranh_attempts.append({
									"correct_string": false,
									"cents_error": 50.0,
									"timing": 0.0,
									"attack_clarity": 50.0,
									"sustain_duration": 0.0,
									"vibrato_detected": false,
									"bend_detected": false
								})
								_on_wrong_note_played(det_name, det_idx, clean_note, s_idx)
						else:
							wrong_note_time = max(0.0, wrong_note_time - delta * 2.0)
							
		# Clear string marker and mark as missed (chỉ khi không ở chế độ Nghe Mẫu)
		if not is_wait_mode and not is_sample_mode and not note.get("hit", false) and not note.get("missed", false) and note["x"] < hit_x - 30.0:

			note["missed"] = true
			note["color"] = Color(0.9, 0.15, 0.15, 1.0) # Solid red for missed/wrong note
			zither_board.call("clear_lesson_markers")
			
			# Dynamic tempo & Fail state logic
			consecutive_misses += 1
			consecutive_hits = 0
			total_misses += 1
			
			if total_misses >= 5:
				# sub_instruction_lbl.text = "Bạn đã đánh sai quá 5 nốt. Bài học được bắt đầu lại từ đầu!"
				get_tree().create_timer(2.0).timeout.connect(func():
					_start_practice()
				)
				return # Stop processing
			elif consecutive_misses >= 2:
				current_speed_multiplier = user_speed_multiplier * 0.7
			
	if all_passed and active_falling_notes.size() > 0:
		active_falling_notes.clear()
		zither_board.call("clear_lesson_markers")
		_finish_practice()
		
	staff_display.set_notes(active_falling_notes)
	if glissando_sheet:
		var completed := 0
		for note in active_falling_notes:
			if note.get("hit", false):
				completed += 1
		if glissando_progress_label:
			glissando_progress_label.text = "Tiến độ: %d/17" % completed
		if glissando_progress_bar:
			glissando_progress_bar.value = completed

func _check_mic_pitch(target_hz: float, delta: float = 0.016, _target_note_name: String = "") -> bool:
	if _is_micro_scoring_blocked() or not analyzer:
		time_correct = 0.0
		return false
	if analyzer.has_method("has_recent_dan_tranh_attack") \
			and not analyzer.has_recent_dan_tranh_attack():
		time_correct = 0.0
		return false

	var pitch: float = analyzer.current_pitch
	var db: float = analyzer.current_amplitude_db
	var is_poly = "+" in _target_note_name
	
	# Relaxed volume threshold to pick up standard acoustic instruments
	if db <= analyzer.volume_threshold_db:
		time_correct = 0.0
		if pitch_meter:
			pitch_meter.is_active = false
			pitch_meter.queue_redraw()
		return false

	var is_match = false
	if is_poly:
		# Every polyphonic target is spectrum-only. YIN returns one fundamental;
		# falling back to it would allow a single component to complete a chord.
		is_match = _are_all_chord_fundamentals_present(_target_note_name.split("+"))
	else:
		if target_hz > 0.0 and pitch > 0.0:
			var cents_error = 1200.0 * log(pitch / target_hz) / log(2.0)
			if pitch_meter:
				pitch_meter.current_cents = cents_error
				pitch_meter.is_active = true
				pitch_meter.queue_redraw()
			is_match = _is_pitch_match_robust(target_hz, _target_note_name, pitch)

	if is_poly:
		return _advance_polyphonic_confirmation(is_match, delta)

	var hold_time_needed = REQUIRED_HOLD_TIME
	if not is_poly and target_hz > 1000.0:
		hold_time_needed = 0.08  # ~5 frames for extremely high strings (Đô3, Mi3, Sol4, La4)
	elif not is_poly and target_hz > 600.0:
		hold_time_needed = 0.12  # ~7 frames for high strings (Sol3, La3)

	if not is_match:
		time_correct = max(0.0, time_correct - delta * 2.0)
		return false

	time_correct += delta
	if time_correct < hold_time_needed:
		return false

	time_correct = 0.0
	return true


func _should_score_polyphonic_component(raw_chord_name: String, component_index: int) -> bool:
	if "+" not in raw_chord_name:
		return true
	# All visual components belong to one microphone gesture. Only the first may
	# update the shared confirmation timer in a frame.
	return component_index == 0


func _advance_polyphonic_confirmation(all_fundamentals_present: bool, delta: float) -> bool:
	if not all_fundamentals_present:
		time_correct = maxf(0.0, time_correct - delta * 2.0)
		return false

	time_correct += maxf(delta, 0.0)
	var hold_time := 0.10 if _uses_mobile_audio_fallback() else CHORD_SIMULTANEOUS_HOLD_TIME
	if time_correct < hold_time:
		return false

	time_correct = 0.0
	return true


func _are_all_chord_fundamentals_present(
	notes: PackedStringArray,
	band_db_reader: Callable = Callable()
) -> bool:
	if notes.size() < 2:
		return false
	if not band_db_reader.is_valid() and (not analyzer or analyzer.get("_spectrum") == null):
		return false

	var target_names: Dictionary = {}
	var mobile_fallback := _uses_mobile_audio_fallback()
	var minimum_fundamental_db := -62.0 if mobile_fallback else CHORD_MIN_FUNDAMENTAL_DB
	var maximum_component_spread_db := 36.0 if mobile_fallback else CHORD_MAX_COMPONENT_SPREAD_DB
	var target_physical_strings: Dictionary = {}
	var target_frequencies: Array[float] = []
	var component_levels: Array[float] = []
	for note_name in notes:
		var frequency: float = NOTE_FREQS.get(note_name, 0.0)
		if frequency <= 0.0:
			return false
		var physical_string := int(NOTE_TO_STRING.get(note_name, -1))
		if physical_string < 0 or target_names.has(note_name) \
				or target_physical_strings.has(physical_string):
			return false
		target_names[note_name] = true
		target_physical_strings[physical_string] = true
		target_frequencies.append(frequency)

		var fundamental_db: float
		if band_db_reader.is_valid():
			fundamental_db = float(band_db_reader.call(frequency))
		else:
			fundamental_db = _get_spectrum_band_db(frequency, 0.05)

		if fundamental_db < minimum_fundamental_db:
			return false
		component_levels.append(fundamental_db)

	component_levels.sort()
	var weakest_target_db := float(component_levels[0])
	var strongest_target_db := float(component_levels[component_levels.size() - 1])
	if strongest_target_db - weakest_target_db > maximum_component_spread_db:
		return false

	# Reject a clearly played non-target string. Ignore bins that are integer
	# harmonics of a requested lower string because those naturally belong to its
	# timbre and are not independent extra notes.
	for physical_note in ALL_17_NOTES:
		if target_names.has(physical_note):
			continue
		var other_frequency: float = NOTE_FREQS.get(physical_note, 0.0)
		if other_frequency <= 0.0 or _is_target_harmonic(other_frequency, target_frequencies):
			continue
		var other_db: float
		if band_db_reader.is_valid():
			other_db = float(band_db_reader.call(other_frequency))
		else:
			other_db = _get_spectrum_band_db(other_frequency, 0.05)
		if not mobile_fallback and other_db >= CHORD_MIN_FUNDAMENTAL_DB \
				and other_db >= weakest_target_db - CHORD_UNEXPECTED_NOTE_MARGIN_DB:
			return false

	return true


func _is_target_harmonic(frequency: float, target_frequencies: Array[float]) -> bool:
	for target_frequency in target_frequencies:
		if target_frequency <= 0.0 or frequency <= target_frequency:
			continue
		var ratio := frequency / target_frequency
		var harmonic := roundf(ratio)
		if harmonic >= 2.0 and harmonic <= 4.0 and absf(ratio - harmonic) <= 0.05:
			return true
	return false





func _finish_practice():
	_stop_technique_sample()
	current_state = State.COMPLETED
	if analyzer:
		analyzer.rapid_sequence_mode = false
		analyzer.contour_tracking_mode = false
	complete_btn.visible = false # Managed by popup action button
	if speed_bar_container:
		speed_bar_container.visible = false
	if pause_btn:
		pause_btn.visible = false
	if pause_overlay:
		pause_overlay.visible = false
	
	var completed = SecureDataManager.data.completed_lessons.get("dan_tranh", [])
	if not completed.has(current_lesson_id):
		completed.append(current_lesson_id)
		SecureDataManager.data.completed_lessons["dan_tranh"] = completed
		SecureDataManager.save_data()

	# Compute separate ratings (Phase 3)
	var total_attempts = _dan_tranh_attempts.size()
	var pitch_score = 0.0
	var rhythm_score = 0.0
	var tech_score = 0.0
	
	var correct_strings = 0
	var sum_cents_score = 0.0
	var sum_timing = 0.0
	var sum_attack = 0.0
	var sum_sustain = 0.0
	var tech_hits = 0
	
	if total_attempts > 0:
		for att in _dan_tranh_attempts:
			if att["correct_string"]:
				correct_strings += 1
			sum_cents_score += clamp(100.0 - abs(att["cents_error"]) * 2.0, 0.0, 100.0)
			sum_timing += att["timing"]
			sum_attack += att["attack_clarity"]
			sum_sustain += att["sustain_duration"]
			if att.get("vibrato_detected", false) or att.get("bend_detected", false) or att.get("tremolo_detected", false):
				tech_hits += 1
		
		var string_acc = float(correct_strings) / total_attempts * 100.0
		var cents_acc = sum_cents_score / total_attempts
		pitch_score = clamp(string_acc * 0.6 + cents_acc * 0.4, 0.0, 100.0)
		
		var timing_acc = sum_timing / total_attempts
		var attack_acc = sum_attack / total_attempts
		rhythm_score = clamp(timing_acc * 0.7 + attack_acc * 0.3, 0.0, 100.0)
		
		var sustain_acc = sum_sustain / total_attempts
		var tech_rate = float(tech_hits) / total_attempts * 100.0
		tech_score = clamp(sustain_acc * 0.8 + max(tech_rate, 15.0), 0.0, 100.0)
	else:
		pitch_score = 90.0
		rhythm_score = 85.0
		tech_score = 80.0
		
	var composite_score = clamp(pitch_score * 0.5 + rhythm_score * 0.3 + tech_score * 0.2, 0.0, 100.0)
	SecureDataManager.record_practice_result(current_lesson_id, composite_score)
	
	var popup_scene = load("res://scenes/CustomPopup.tscn")
	if popup_scene:
		var popup = popup_scene.instantiate()
		add_child(popup)
		popup.setup_result(composite_score, pitch_score, rhythm_score, tech_score, 60, "Tiếp tục")
		var action = popup.get_node_or_null("CardContainer/MarginContainer/Content/ActionBtn") as Button
		if action:
			action.pressed.connect(func():
				_on_complete()
			)

func _on_back():
	_stop_technique_sample()
	if analyzer:
		analyzer.rapid_sequence_mode = false
		analyzer.contour_tracking_mode = false
	get_tree().change_scene_to_file("res://scenes/LessonDanTranhList.tscn")

func _on_complete():
	_on_back()

# --- Định dạng phong cách nút Quay Lại (kế thừa từ Virtual Music Room) ---
func _style_hud_icon_button(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", _flat_sb(Color(0,0,0,0), Color(0,0,0,0), 0))
	btn.add_theme_stylebox_override("hover", _flat_sb(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.12), Color(0,0,0,0), 28))
	btn.add_theme_stylebox_override("pressed", _flat_sb(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.22), Color(0,0,0,0), 28))
	btn.add_theme_stylebox_override("focus", _flat_sb(Color(0,0,0,0), Color(0,0,0,0), 0))
	btn.add_theme_color_override("icon_normal_color", Color(0.25, 0.18, 0.12)) # Warm bronze-brown
	btn.add_theme_color_override("icon_hover_color", C_GOLD)
	btn.add_theme_color_override("icon_pressed_color", Color(0.5, 0.4, 0.3))

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
		var t := create_tween()
		t.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)

# --- Điều khiển tốc độ trôi nốt (Bài 3) ---
var speed_bar_container: PanelContainer = null
var user_speed_multiplier: float = 1.0
var speed_buttons: Array[Button] = []

func _create_speed_control_bar():
	speed_bar_container = PanelContainer.new()
	speed_bar_container.name = "SpeedControlBar"
	
	# Background style - Đồng bộ với viền vàng và nền gỗ của nút HUD (không dùng màu đen)
	var style_bg = _flat_sb(Color(C_WOOD.r, C_WOOD.g, C_WOOD.b, 0.85), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45), 20)
	style_bg.content_margin_left = 16
	style_bg.content_margin_right = 16
	style_bg.content_margin_top = 8
	style_bg.content_margin_bottom = 8
	speed_bar_container.add_theme_stylebox_override("panel", style_bg)
	
	# Position at top right (left of pause button)
	add_child(speed_bar_container)
	speed_bar_container.anchor_left = 1.0
	speed_bar_container.anchor_right = 1.0
	speed_bar_container.anchor_top = 0.0
	speed_bar_container.anchor_bottom = 0.0
	speed_bar_container.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	speed_bar_container.offset_top = 34
	speed_bar_container.offset_right = -124
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 12)
	speed_bar_container.add_child(hbox)
	
	var speeds = [0.6, 0.8, 1.0, 1.2]
	var labels = ["60%", "80%", "100%", "120%"]
	
	var f_bold = load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	
	for i in range(speeds.size()):
		if i > 0:
			var sep = Label.new()
			sep.text = "|"
			sep.add_theme_color_override("font_color", Color(1, 1, 1, 0.35))
			if f_bold: sep.add_theme_font_override("font", f_bold)
			hbox.add_child(sep)
			
		var btn = Button.new()
		btn.text = labels[i]
		btn.custom_minimum_size = Vector2(70, 32)
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		if f_bold: btn.add_theme_font_override("font", f_bold)
		
		# Kết nối tín hiệu click
		var speed_val = speeds[i]
		btn.pressed.connect(func(): _select_speed(speed_val))
		hbox.add_child(btn)
		speed_buttons.append(btn)
		
	_select_speed(1.0) # Mặc định chọn 100%
	speed_bar_container.visible = false

func _select_speed(speed_val: float):
	user_speed_multiplier = speed_val
	current_speed_multiplier = user_speed_multiplier
	_highlight_speed_btn(speed_val)

## Adaptive difficulty FE: nếu người dùng chưa tự chọn tốc độ (vẫn 1.0 mặc định),
## dùng tempo gợi ý từ 10 lượt gần nhất của bài này.
func _apply_adaptive_speed():
	if user_speed_multiplier != 1.0:
		current_speed_multiplier = user_speed_multiplier
		return
	var adaptive := SecureDataManager.get_adaptive_tempo_multiplier(current_lesson_id)
	current_speed_multiplier = adaptive
	_highlight_speed_btn(adaptive)

func _highlight_speed_btn(speed_val: float):
	if speed_buttons.is_empty():
		return
	var speeds = [0.6, 0.8, 1.0, 1.2]
	for i in range(speeds.size()):
		var btn = speed_buttons[i]
		if speeds[i] == speed_val:
			# Nút được chọn (nền vàng kim sang trọng, chữ nâu gỗ tối)
			var sb_selected = StyleBoxFlat.new()
			sb_selected.bg_color = C_GOLD
			sb_selected.corner_radius_top_left = 12
			sb_selected.corner_radius_top_right = 12
			sb_selected.corner_radius_bottom_left = 12
			sb_selected.corner_radius_bottom_right = 12
			btn.add_theme_stylebox_override("normal", sb_selected)
			btn.add_theme_stylebox_override("hover", sb_selected)
			btn.add_theme_stylebox_override("pressed", sb_selected)
			btn.add_theme_color_override("font_color", Color(0.15, 0.1, 0.08))
			btn.add_theme_color_override("font_hover_color", Color(0.15, 0.1, 0.08))
		else:
			# Nút không được chọn (trong suốt, chữ trắng)
			var sb_empty = StyleBoxEmpty.new()
			btn.add_theme_stylebox_override("normal", sb_empty)
			btn.add_theme_stylebox_override("hover", sb_empty)
			btn.add_theme_stylebox_override("pressed", sb_empty)
			btn.add_theme_color_override("font_color", Color.WHITE)
			btn.add_theme_color_override("font_hover_color", C_GOLD)

func _generate_error_feedback_stream() -> AudioStreamWAV:
	const SAMPLE_RATE := 22050
	const DURATION := 0.12
	var sample_count := int(SAMPLE_RATE * DURATION)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in sample_count:
		var time := float(i) / float(SAMPLE_RATE)
		var progress := float(i) / float(sample_count)
		var frequency := 190.0 if progress < 0.48 else 145.0
		var envelope := pow(1.0 - progress, 2.2)
		var sample := sin(TAU * frequency * time) * envelope * 0.20
		var value_i16 := int(clampf(sample, -1.0, 1.0) * 32767.0)
		var value_u16 := value_i16 & 0xFFFF
		data[i * 2] = value_u16 & 0xFF
		data[i * 2 + 1] = (value_u16 >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream


func _generate_pluck_stream(freq: float) -> AudioStreamWAV:
	# Karplus-Strong synthesizer to generate traditional Zither tones procedurally
	const SAMPLE_RATE: int = 44100
	const DURATION: float  = 4.0
	var sample_count: int  = int(SAMPLE_RATE * DURATION)

	var delay_len: int = int(float(SAMPLE_RATE) / freq)
	if delay_len < 2:
		delay_len = 2

	var delay_buf := PackedFloat32Array()
	delay_buf.resize(delay_len)
	for k in delay_len:
		delay_buf[k] = randf_range(-1.0, 1.0)

	var freq_ratio := clampf(freq / 1000.0, 0.0, 1.0)
	var decay: float = clampf(0.9993 - freq_ratio * 0.002, 0.9972, 0.9993)

	var samples := PackedFloat32Array()
	samples.resize(sample_count)
	var buf_pos: int = 0

	for i in sample_count:
		var next_pos: int = (buf_pos + 1) % delay_len
		var new_sample: float = decay * 0.5 * (delay_buf[buf_pos] + delay_buf[next_pos])
		samples[i] = new_sample
		delay_buf[buf_pos] = new_sample
		buf_pos = (buf_pos + 1) % delay_len

	var attack_samps := int(SAMPLE_RATE * 0.01)
	for i in attack_samps:
		samples[i] *= (float(i) / float(attack_samps))

	var max_amp: float = 0.0
	for s in samples:
		var a := absf(s)
		if a > max_amp:
			max_amp = a
	if max_amp < 0.0001:
		max_amp = 1.0
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

# --- Tạo nút Skip (Bỏ qua hướng dẫn) ---
var skip_intro_btn: Button = null
var previous_intro_btn: Button = null

func _create_skip_intro_button():
	previous_intro_btn = _create_aesthetic_btn(
		"← TRƯỚC",
		"res://icons8/icons8-back-100.png",
		false,
		C_WOOD,
		C_WOOD.lightened(0.12),
		Color.WHITE,
		C_GOLD,
		16,
		Vector2(150, 48)
	)
	add_child(previous_intro_btn)
	previous_intro_btn.anchor_left = 1.0
	previous_intro_btn.anchor_right = 1.0
	previous_intro_btn.anchor_top = 1.0
	previous_intro_btn.anchor_bottom = 1.0
	previous_intro_btn.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	previous_intro_btn.grow_vertical = Control.GROW_DIRECTION_BEGIN

	skip_intro_btn = _create_aesthetic_btn(
		"SKIP", 
		"res://icons8/icons8-play-100.png", 
		true, 
		C_WOOD, 
		C_WOOD.lightened(0.12), 
		Color.WHITE, 
		C_GOLD, 
		16, 
		Vector2(140, 48)
	)
	
	# Đặt nút ở góc dưới cùng bên phải màn hình
	add_child(skip_intro_btn)
	skip_intro_btn.anchor_left = 1.0
	skip_intro_btn.anchor_right = 1.0
	skip_intro_btn.anchor_top = 1.0
	skip_intro_btn.anchor_bottom = 1.0
	skip_intro_btn.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	skip_intro_btn.grow_vertical = Control.GROW_DIRECTION_BEGIN
	
	# Cập nhật vị trí nút theo kích thước viewport (responsive)
	var update_skip_pos = func():
		previous_intro_btn.offset_left = -350
		previous_intro_btn.offset_right = -200
		previous_intro_btn.offset_top = -85
		previous_intro_btn.offset_bottom = -40
		skip_intro_btn.offset_left = -190
		skip_intro_btn.offset_right = -40
		skip_intro_btn.offset_top = -85
		skip_intro_btn.offset_bottom = -40
		
	get_viewport().size_changed.connect(update_skip_pos)
	update_skip_pos.call()
	
	# Sự kiện nhấn nút: Bỏ qua giới thiệu thoại và vào tập luyện trực tiếp
	skip_intro_btn.pressed.connect(func():
		_start_practice()
	)
	previous_intro_btn.pressed.connect(_play_previous_intro_step)


func _play_previous_intro_step() -> void:
	if current_state != State.INTRO:
		return
	# intro_step points to the next speech after the one currently on screen.
	# Move back two positions, then let the regular dialogue renderer replay it.
	if intro_step <= 1:
		return
	intro_step = max(0, intro_step - 2)
	_play_next_intro_step()

# --- Hệ thống Tạm dừng (Pause) & Nghe mẫu (Sample) ---
var pause_btn: Button = null
var is_paused: bool = false
var is_sample_mode: bool = false
var pause_overlay: ColorRect = null
var btn_sample_ref: Button = null
var progress_label: Label = null

func _should_have_speed_control() -> bool:
	var parts = current_lesson_id.split("_")
	for i in range(parts.size()):
		if parts[i] == "bai" and i + 1 < parts.size():
			var num = int(parts[i+1])
			if num >= 3:
				return true
	return false

func _create_pause_system():
	# 1. Tạo nút Pause ở góc trên cùng bên phải (HUD tròn chuyên nghiệp)
	pause_btn = _create_hud_icon_btn("res://icons8/icons8-pause-100.png", _toggle_pause)
	add_child(pause_btn)
	pause_btn.anchor_left = 1.0
	pause_btn.anchor_right = 1.0
	pause_btn.anchor_top = 0.0
	pause_btn.anchor_bottom = 0.0
	pause_btn.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	
	var update_pause_btn_pos = func():
		pause_btn.offset_left = -108 # Rộng 68px
		pause_btn.offset_right = -40
		pause_btn.offset_top = 24
		pause_btn.offset_bottom = 92  # Cao 68px
	get_viewport().size_changed.connect(update_pause_btn_pos)
	update_pause_btn_pos.call()
	
	pause_btn.visible = false
	
	# 2. Tạo Overlay màn hình mờ che phủ khi tạm dừng (Giống Simply Guitar, che nhẹ màn hình)
	pause_overlay = ColorRect.new()
	pause_overlay.name = "PauseOverlay"
	pause_overlay.color = Color(0, 0, 0, 0.45)
	add_child(pause_overlay)
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.visible = false
	
	# 3. Tạo thanh Top Bar màu gỗ đồng bộ full màn hình chiều ngang (Giống Simply Guitar nhưng dùng màu gỗ ấm)
	var top_bar = PanelContainer.new()
	top_bar.name = "PauseTopBar"
	
	var style_tb = StyleBoxFlat.new()
	style_tb.bg_color = Color(C_WOOD.r, C_WOOD.g, C_WOOD.b, 0.95) # Màu gỗ đồng bộ ấm áp
	style_tb.border_width_bottom = 3
	style_tb.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.4)
	top_bar.add_theme_stylebox_override("panel", style_tb)
	
	pause_overlay.add_child(top_bar)
	top_bar.anchor_left = 0.0; top_bar.anchor_right = 1.0
	top_bar.anchor_top = 0.0; top_bar.anchor_bottom = 0.0
	top_bar.offset_bottom = 96
	
	var margin_container = MarginContainer.new()
	margin_container.add_theme_constant_override("margin_left", 40)
	margin_container.add_theme_constant_override("margin_right", 40)
	margin_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top_bar.add_child(margin_container)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin_container.add_child(hbox)
	
	# Cụm nút chức năng bên trái (Tiếp tục, Chơi lại, Nghe mẫu - Đã bỏ nút Thoát) xếp song song
	var actions_box = HBoxContainer.new()
	actions_box.add_theme_constant_override("separation", 24)
	hbox.add_child(actions_box)
	
	var btn_resume = _create_pause_action_btn("Tiếp tục", "res://icons8/icons8-play-100.png", func():
		_toggle_pause()
	)
	actions_box.add_child(btn_resume)
	
	var btn_replay = _create_pause_action_btn("Chơi lại", "res://icons8/icons8-restart-100.png", func():
		_toggle_pause()
		is_sample_mode = false
		_start_practice()
	)
	actions_box.add_child(btn_replay)
	
	btn_sample_ref = _create_pause_action_btn("Nghe mẫu", "res://icons8/icons8-speaker-100.png", func():
		_toggle_pause()
		_toggle_sample_mode()
	)
	actions_box.add_child(btn_sample_ref)
	
	# Spacer đẩy phần chỉ số tiến độ sang góc bên phải
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)
	
	# Nhãn tiến độ (Progress Tracker) ở bên phải (Ví dụ: 25/40 nốt)
	progress_label = Label.new()
	progress_label.text = "0/0"
	progress_label.add_theme_color_override("font_color", C_GOLD)
	var f_bold = load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if f_bold: progress_label.add_theme_font_override("font", f_bold)
	progress_label.add_theme_font_size_override("font_size", 22)
	hbox.add_child(progress_label)

func _create_pause_action_btn(text: String, icon_path: String, pressed_callable: Callable) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(80, 80)
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	# Xóa nền nút bấm, tạo cảm giác phẳng (flat) chuyên nghiệp
	var empty_sb = StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty_sb)
	btn.add_theme_stylebox_override("hover", empty_sb)
	btn.add_theme_stylebox_override("pressed", empty_sb)
	btn.add_theme_stylebox_override("focus", empty_sb)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vbox)
	
	var texture_rect = TextureRect.new()
	texture_rect.texture = load(icon_path) as Texture2D
	texture_rect.custom_minimum_size = Vector2(28, 28)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = 5 # Keep aspect centered
	
	# Shader biến đổi màu icon xanh lá tối gốc thành màu Trắng/Vàng kim cực đẹp
	var mat = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = """shader_type canvas_item;
	uniform vec4 modulate_color : source_color = vec4(1.0);
	void fragment() {
		vec4 tex = texture(TEXTURE, UV);
		COLOR = vec4(modulate_color.rgb, tex.a * modulate_color.a);
	}"""
	mat.shader = shader
	mat.set_shader_parameter("modulate_color", Color.WHITE)
	texture_rect.material = mat
	vbox.add_child(texture_rect)
	
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_font_size_override("font_size", 12)
	
	var f_bold = load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if f_bold: label.add_theme_font_override("font", f_bold)
	vbox.add_child(label)
	
	# Hiệu ứng đổi màu bằng shader khi tương tác
	btn.mouse_entered.connect(func():
		mat.set_shader_parameter("modulate_color", C_GOLD)
		label.add_theme_color_override("font_color", C_GOLD)
	)
	btn.mouse_exited.connect(func():
		texture_rect.self_modulate = Color.WHITE
		label.add_theme_color_override("font_color", Color.WHITE)
	)
	btn.button_down.connect(func():
		texture_rect.self_modulate = Color(0.8, 0.8, 0.8)
		label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	)
	btn.button_up.connect(func():
		texture_rect.self_modulate = Color.WHITE
		label.add_theme_color_override("font_color", Color.WHITE)
	)
	
	btn.pressed.connect(pressed_callable)
	_make_btn_bouncy(btn)
	return btn

func _toggle_pause():
	is_paused = not is_paused
	pause_overlay.visible = is_paused
	
	if btn_sample_ref:
		var vbox = btn_sample_ref.get_child(0)
		var texture_node = vbox.get_child(0) as TextureRect
		var label_node = vbox.get_child(1) as Label
		
		if is_sample_mode:
			label_node.text = "Luyện tập"
			texture_node.texture = load("res://icons8/icons8-play-100.png") as Texture2D
		else:
			label_node.text = "Nghe mẫu"
			texture_node.texture = load("res://icons8/icons8-speaker-100.png") as Texture2D
			
	if progress_label:
		var total_notes = lesson_sheet.size()
		var current_note = min(practice_idx, total_notes)
		progress_label.text = str(current_note) + "/" + str(total_notes)

func _toggle_sample_mode():
	is_sample_mode = not is_sample_mode
	if not is_sample_mode:
		technique_sample_input_cooldown = 0.55
	_start_practice()

func _create_hud_icon_btn(icon_path: String, pressed_callable: Callable) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(68, 68)
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	# Viền vòng tròn vàng sang trọng, nền gỗ ấm đồng bộ với nhạc cụ (không dùng màu đen)
	var sb_normal = _flat_sb(Color(C_WOOD.r, C_WOOD.g, C_WOOD.b, 0.85), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45), 34)
	var sb_hover = _flat_sb(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.15), C_GOLD, 34)
	var sb_pressed = _flat_sb(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25), C_GOLD, 34)
	
	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_pressed)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	var texture_rect = TextureRect.new()
	texture_rect.texture = load(icon_path) as Texture2D
	texture_rect.custom_minimum_size = Vector2(36, 36) # Tăng kích cỡ icon từ 24 lên 36
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = 5 # Keep aspect centered
	
	btn.add_child(texture_rect)
	texture_rect.anchor_left = 0.5; texture_rect.anchor_right = 0.5
	texture_rect.anchor_top = 0.5; texture_rect.anchor_bottom = 0.5
	texture_rect.offset_left = -18; texture_rect.offset_right = 18
	texture_rect.offset_top = -18; texture_rect.offset_bottom = 18
	
	var mat = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = """shader_type canvas_item;
	uniform vec4 modulate_color : source_color = vec4(1.0);
	void fragment() {
		vec4 tex = texture(TEXTURE, UV);
		COLOR = vec4(modulate_color.rgb, tex.a * modulate_color.a);
	}"""
	mat.shader = shader
	mat.set_shader_parameter("modulate_color", Color.WHITE) # Màu trắng sáng mặc định
	texture_rect.material = mat
	
	btn.mouse_entered.connect(func():
		mat.set_shader_parameter("modulate_color", C_GOLD)
	)
	btn.mouse_exited.connect(func():
		mat.set_shader_parameter("modulate_color", Color.WHITE)
	)
	btn.button_down.connect(func():
		mat.set_shader_parameter("modulate_color", Color(0.8, 0.8, 0.8))
	)
	btn.button_up.connect(func():
		mat.set_shader_parameter("modulate_color", Color.WHITE)
	)
	
	btn.pressed.connect(pressed_callable)
	_make_btn_bouncy(btn)
	return btn


# Bài 1 có video giới thiệu riêng. Đặt lối vào ngay trong màn luyện để người học
# không phải quay về danh sách bài mới tìm được nút "Hướng dẫn".
func _create_aesthetic_btn(text: String, icon_path: String, is_icon_right: bool, bg_color: Color, hover_bg_color: Color, text_color: Color, hover_text_color: Color, radius: int, size: Vector2) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = size
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var sb_n = _flat_sb(bg_color, Color.TRANSPARENT, radius)
	var sb_h = _flat_sb(hover_bg_color, C_GOLD if bg_color == Color.TRANSPARENT else Color.TRANSPARENT, radius)
	var sb_p = _flat_sb(bg_color.darkened(0.1), Color.TRANSPARENT, radius)
	
	btn.add_theme_stylebox_override("normal", sb_n)
	btn.add_theme_stylebox_override("hover", sb_h)
	btn.add_theme_stylebox_override("pressed", sb_p)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 8)
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(hbox)
	
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", text_color)
	label.add_theme_font_size_override("font_size", 16)
	var f_bold = load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if f_bold: label.add_theme_font_override("font", f_bold)
	
	var texture_rect = TextureRect.new()
	texture_rect.texture = load(icon_path) as Texture2D
	texture_rect.custom_minimum_size = Vector2(24, 24)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = 5 # Keep aspect centered
	
	var mat = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = """shader_type canvas_item;
	uniform vec4 modulate_color : source_color = vec4(1.0);
	void fragment() {
		vec4 tex = texture(TEXTURE, UV);
		COLOR = vec4(modulate_color.rgb, tex.a * modulate_color.a);
	}"""
	mat.shader = shader
	mat.set_shader_parameter("modulate_color", text_color)
	texture_rect.material = mat
	
	if is_icon_right:
		hbox.add_child(label)
		hbox.add_child(texture_rect)
	else:
		hbox.add_child(texture_rect)
		hbox.add_child(label)
		
	btn.mouse_entered.connect(func():
		label.add_theme_color_override("font_color", hover_text_color)
		mat.set_shader_parameter("modulate_color", hover_text_color)
	)
	btn.mouse_exited.connect(func():
		label.add_theme_color_override("font_color", text_color)
		mat.set_shader_parameter("modulate_color", text_color)
	)
	btn.button_down.connect(func():
		label.add_theme_color_override("font_color", text_color.darkened(0.1))
		mat.set_shader_parameter("modulate_color", text_color.darkened(0.1))
	)
	btn.button_up.connect(func():
		label.add_theme_color_override("font_color", text_color)
		mat.set_shader_parameter("modulate_color", text_color)
	)
	
	_make_btn_bouncy(btn)
	return btn

func _update_staff_layout() -> void:
	if not staff_card or not staff_display: return
	var size = get_viewport_rect().size
	var v_height = size.y
	
	# Responsive positioning
	var title_top = clampf(v_height * 0.02, 10.0, 24.0)
	if title_plaque:
		title_plaque.offset_top = title_top
		title_plaque.offset_bottom = title_top + 80.0
		
	# Distribute space for staff_card
	var card_top = clampf(v_height * 0.14, 110.0, 135.0)
	var card_bottom = v_height - clampf(v_height * 0.14, 110.0, 130.0)
	
	# Clamp height to be at least 620 to prevent notes from ever being clipped
	var card_height = maxf(card_bottom - card_top, 620.0)
	card_bottom = card_top + card_height
	
	staff_card.offset_top = card_top
	staff_card.offset_bottom = card_bottom
	
	if pill_badge:
		pill_badge.offset_top = card_top - 20.0
		pill_badge.offset_bottom = card_top + 20.0
		
	if sub_instr_row:
		sub_instr_row.offset_top = card_bottom + 12.0
		sub_instr_row.offset_bottom = card_bottom + 52.0

	# Calculate dynamic optimal spacing for 17 zither notes
	# Zither notes span from Sol_1 (-3.5) to La_4 (7.5), a range of 11.0.
	# We want them to fit within card_height with comfortable top/bottom padding of 45px.
	var max_spacing = (card_height - 90.0) / 11.0
	var spacing = 32.0 if _is_glissando_practice() else clampf(max_spacing, 46.0, 78.0)
	staff_display.line_spacing = spacing
	if is_instance_valid(_teacher_avatar_wrapper):
		_teacher_avatar_wrapper.position = Vector2(-80.0, v_height - 320.0)
	if _is_glissando_practice() and current_state == State.PRACTICE and not glissando_round_locked:
		_build_glissando_round_notes(str(GLISSANDO_ROUNDS[glissando_round_idx]["mode"]))
	staff_display.queue_redraw()
