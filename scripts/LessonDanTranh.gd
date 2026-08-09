extends Control
class_name LessonDanTranh

const C_GOLD = Color(0.961, 0.784, 0.259, 1.0)
const C_WOOD = Color(0.18, 0.13, 0.08, 1.0)
const C_JADE = Color("#173f2d")

enum State { CALIBRATION, INTRO, PRACTICE_SINGLE, PRACTICE, COMPLETED }
var current_state = State.CALIBRATION

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

# Virtual Teacher Portrait Animation States
var _tex_mai_talk_sheet = load("res://assets/textures/coMai/mai_upper_body_talk_16_frames.png") as Texture2D
var _teacher_atlas : AtlasTexture
var _portrait_is_talking := false
var _portrait_frame := 0
var _portrait_frame_elapsed := 0.0
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
var current_lesson_id: String
var lesson_data: Dictionary
static var current_song_durations: Array[float] = []
static var current_song_cues: Array[String] = []

var lesson_sheet: Array[String] = []
var lesson_durations: Array[float] = []

var practice_idx: int = 0
var intro_step: int = 0
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
	"dan_tranh_level_1_bai_1_practice": [
		{"action": "speak", "text": "Chào mừng bạn đến với bài học Đàn Tranh đầu tiên. Hãy ngồi thẳng lưng và đặt đàn trước mặt. Bên lớn hơn được gọi là đầu đàn sẽ nằm bên phía tay phải nhé. Chúng ta sẽ gảy đàn bằng tay phải và tay trái ấn, giữ dây đàn để tạo âm vang.", "highlight": -1},
		{"action": "speak", "text": "Đầu tiên, hãy làm quen với âm sắc của 5 nốt cơ bản nhất ở quãng trầm của đàn.", "highlight": -1},
		{"action": "speak", "text": "Dây 1: Nốt Sol1. Hãy gảy đúng nốt Sol1 ở dây thứ nhất đàn.", "highlight": 0},
		{"action": "speak", "text": "Dây 2: Nốt La1. Hãy gảy nốt La1 ở dây thứ 2 trên đàn.", "highlight": 1},
		{"action": "speak", "text": "Dây 3: Nốt Đô2. Hãy gảy nốt Đô2 ở dây thứ 3 trên đàn.", "highlight": 2},
		{"action": "speak", "text": "Dây 4: Nốt Rê2. Hãy gảy nốt Rê2 ở dây thứ 4 trên đàn.", "highlight": 3},
		{"action": "speak", "text": "Dây 5: Nốt Mi2. Hãy gảy nốt Mi2 ở dây thứ 5 trên đàn.", "highlight": 4},
		{"action": "speak", "text": "Tuyệt vời! Bạn đã hoàn thành gảy 5 nốt cơ bản đầu tiên của Đàn Tranh!", "highlight": -1}
	],

	"dan_tranh_level_1_bai_2_practice": [
		{"action": "speak", "text": "Chào mừng bạn đến với bài luyện tập 10 nốt cơ bản quãng thấp và trung. Chúng ta sẽ làm quen và gảy từng nốt tương ứng với từng dây nhé.", "highlight": -1},
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
		{"action": "speak", "text": "Chào mừng bạn đến với bài luyện tập 7 nốt quãng cao trên Đàn Tranh.", "highlight": -1},
		{"action": "speak", "text": "Hãy gảy lần lượt từng nốt từ Sol3 đến La4 khi chúng chạm vạch phách nhé.", "highlight": -1}
	],

	"dan_tranh_level_1_bai_9_practice": [
		{"action": "speak", "text": "Chào mừng bạn đến với bài Luyện ngón cơ bản.", "highlight": -1},
		{"action": "speak", "text": "Chúng ta sẽ sử dụng lần lượt 1 ngón, 2 ngón và 3 ngón tay phải để gảy chuỗi nốt chạy đều đặn nhé.", "highlight": -1}
	],

	"dan_tranh_level_1_bai_4_practice": [
		{"action": "speak", "text": "Chào mừng bạn đến với bài học nhạc lý: Trường độ nốt nhạc. Trường độ là thời gian mỗi nốt nhạc vang lên, được đo bằng phách.", "highlight": -1},
		{"action": "speak", "text": "Đầu tiên là Nốt Trắng. Nốt trắng có đầu hình bầu dục rỗng, có thân nốt, kéo dài 2 phách. Hãy gảy nốt Đô2 và giữ âm vang 2 phách.", "highlight": 2, "note": "Đô2"},
		{"action": "speak", "text": "Thêm một nốt trắng nữa. Hãy gảy nốt Đô2 và giữ 2 phách nhé.", "highlight": 2, "note": "Đô2"},
		{"action": "speak", "text": "Tiếp theo là Nốt Đen. Nốt đen có đầu hình bầu dục đặc, có thân nốt, kéo dài 1 phách. Hãy gảy nốt Rê2.", "highlight": 3, "note": "Rê2"},
		{"action": "speak", "text": "Gảy thêm nốt đen Mi2 – 1 phách.", "highlight": 4, "note": "Mi2"},
		{"action": "speak", "text": "Và thêm nốt đen Mi2 – 1 phách.", "highlight": 4, "note": "Mi2"},
		{"action": "speak", "text": "Gảy nốt đen Sol2 – 1 phách.", "highlight": 5, "note": "Sol2"},
		{"action": "speak", "text": "Bây giờ là Nốt Móc Đơn. Nốt móc đơn có đầu đặc, thân nốt và 1 móc, kéo dài nửa phách. Hãy gảy nhanh nốt Sol2.", "highlight": 5, "note": "Sol2"},
		{"action": "speak", "text": "Thêm nốt móc đơn Sol2 – nửa phách.", "highlight": 5, "note": "Sol2"},
		{"action": "speak", "text": "Và nốt móc đơn Sol2 – nửa phách.", "highlight": 5, "note": "Sol2"},
		{"action": "speak", "text": "Cuối cùng là Nốt Móc Kép. Nốt móc kép có đầu đặc, thân nốt và 2 móc, kéo dài một phần tư phách. Rất nhanh! Hãy gảy nốt La2.", "highlight": 6, "note": "La2"},
		{"action": "speak", "text": "Gảy thêm nốt móc kép La2.", "highlight": 6, "note": "La2"},
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

	"dan_tranh_level_3_bai_8_practice": [
		{"action": "speak", "text": "Hôm nay chúng ta sẽ tập bài dân ca Quan họ Bắc Ninh nổi tiếng: Lý Cây Đa.", "highlight": -1},
		{"action": "speak", "text": "Giai điệu cần sự lả lướt, duyên dáng và đúng nhịp điệu.", "highlight": -1}
	],

	"dan_tranh_level_4_bai_9_practice": [
		{"action": "speak", "text": "Hôm nay chúng ta sẽ học kỹ thuật nhấn Rung tay trái đặc trưng của Đàn Tranh.", "highlight": -1},
		{"action": "speak", "text": "Sau khi tay phải gảy nốt, hãy dùng các ngón tay trái nhấn nhẹ liên tục lên phần dây bên trái nhạn đàn.", "highlight": -1}
	],

	"dan_tranh_level_4_bai_10_practice": [
		{"action": "speak", "text": "Chúng ta sẽ làm quen với Song âm và Hợp âm Đô Trưởng.", "highlight": -1},
		{"action": "speak", "text": "Đặt ngón cái, ngón trỏ và ngón giữa để gảy vang đồng thời cả ba nốt Đô, Mi và Sol cùng một lúc.", "highlight": -1}
	],

	"dan_tranh_level_5_bai_11_practice": [
		{"action": "speak", "text": "Chào mừng bạn đến với cấp độ Master. Chúng ta bắt đầu chinh phục đoạn nhạc mở đầu của tác phẩm Sứ Thanh Hoa.", "highlight": -1},
		{"action": "speak", "text": "Hãy tập trung gảy đúng giai điệu dạo đầu với các quãng nhảy nốt rộng.", "highlight": -1}
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
	# Keep this explicit so scene/default changes cannot cut off the high strings.
	var profile_script = load("res://scripts/InstrumentPitchProfile.gd")
	var profile = profile_script.new()
	profile.notes.assign(ALL_17_NOTES)
	var freqs: Array[float] = []
	var mappings: Array[int] = []
	for n in ALL_17_NOTES:
		freqs.append(NOTE_FREQS[n])
		mappings.append(NOTE_TO_STRING[n])
	profile.frequencies = PackedFloat32Array(freqs)
	profile.physical_mappings = mappings
	profile.min_frequency = 180.0
	profile.max_frequency = 4200.0
	profile.volume_threshold_db = -58.0
	profile.cents_tolerance = 45.0 # robust pitch tolerance
	profile.hold_time_sec = 0.20
	profile.is_plucked_instrument = true
	
	analyzer.pitch_profile = profile
	
	analyzer.min_frequency = 180.0
	analyzer.max_frequency = 4200.0
	analyzer.volume_threshold_db = -58.0
	current_lesson_id = SecureDataManager.active_lesson_id
	if not current_lesson_id or current_lesson_id == "":
		current_lesson_id = "dan_tranh_level_1_bai_1_practice"
		
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
			var dur_sheet: Array[String] = ["Đô2", "Đô2", "Rê2", "Mi2", "Mi2", "Sol2", "Sol2", "Sol2", "Sol2", "La2", "La2"]
			lesson_sheet.assign(dur_sheet)
			var dur_arr: Array[float] = [2.0, 2.0, 1.0, 1.0, 1.0, 1.0, 0.5, 0.5, 0.5, 0.25, 0.25]
			lesson_durations.assign(dur_arr)
		elif current_lesson_id == "dan_tranh_level_2_bai_5_practice":
			var intro_8 = ["Đô2", "Rê2", "Mi2", "Fa2", "Sol2", "La2", "Si2", "Đô3"]
			lesson_sheet.assign(intro_8)
			var d_arr: Array[float] = []
			for i in range(intro_8.size()):
				d_arr.append(1.5)
			lesson_durations.assign(d_arr)
		elif current_lesson_id == "dan_tranh_level_5_bai_12_practice":
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
	
	_update_staff_layout()
	get_viewport().size_changed.connect(_update_staff_layout)
	staff_card.visible = false
	staff_display.visible = true
	
	var string_notes: Array[String] = ["Sol1", "La1", "Đô2", "Rê2", "Mi2", "Sol2", "La2", "Đô3", "Rê3", "Mi3", "Sol3", "La3", "Đô4", "Rê4", "Mi4", "Sol4", "La4"]
	var string_freqs: Array[float] = [196.00, 220.00, 261.63, 293.66, 329.63, 392.00, 440.00, 523.25, 587.33, 659.25, 783.99, 880.00, 1046.50, 1174.66, 1318.51, 1567.98, 1760.00]
	var string_streams: Array = []
	string_streams.resize(17)
	for i in range(17):
		string_streams[i] = _generate_pluck_stream(string_freqs[i])
	zither_board.init(string_notes, string_streams, string_freqs)
	zither_board.visible = false
	
	# Hide redundant mode selection buttons (e.g. "Dùng Đàn Thật")
	var mode_buttons = teacher_area.get_node_or_null("DialogBox/M/V/ModeButtons")
	if mode_buttons:
		mode_buttons.visible = false
		
	# Style và định vị Giảng viên cùng Khung chat ở giữa màn hình (Lớn hơn)
	var dialog_sb = StyleBoxFlat.new()
	dialog_sb.bg_color = Color(0.98, 0.97, 0.94, 0.96) # Cream sang trọng
	dialog_sb.corner_radius_top_left = 24; dialog_sb.corner_radius_top_right = 24
	dialog_sb.corner_radius_bottom_left = 24; dialog_sb.corner_radius_bottom_right = 24
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
	
	var teacher_char = $TeacherArea/TeacherChar
	
	# Đặt lại chế độ neo (anchor) căn giữa cho cả nhân vật và khung chat
	teacher_char.anchor_left = 0.5; teacher_char.anchor_right = 0.5
	teacher_char.anchor_top = 0.5; teacher_char.anchor_bottom = 0.5
	dialog_box.anchor_left = 0.5; dialog_box.anchor_right = 0.5
	dialog_box.anchor_top = 0.5; dialog_box.anchor_bottom = 0.5
	
	var update_teacher_layout = func():
		var vp_size = get_viewport().get_visible_rect().size
		if vp_size.x < 1100:
			# Dành cho màn hình hẹp (mobile dọc): xếp dọc, phóng lớn
			teacher_char.offset_left = -180
			teacher_char.offset_right = 180
			teacher_char.offset_top = -340
			teacher_char.offset_bottom = 0
			
			dialog_box.offset_left = -300
			dialog_box.offset_right = 300
			dialog_box.offset_top = 20
			dialog_box.offset_bottom = 260
		else:
			# Dành cho màn hình rộng (desktop/landscape): xếp song song, giảng viên bên trái, khung chat bên phải
			teacher_char.offset_left = -500
			teacher_char.offset_right = -100
			teacher_char.offset_top = -300
			teacher_char.offset_bottom = 300
			
			dialog_box.offset_left = -80
			dialog_box.offset_right = 560
			dialog_box.offset_top = -160
			dialog_box.offset_bottom = 160
			
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
		
	_start_calibration_state()

func _setup_top_pitch_box():
	var l_title = "LUYỆN ĐÀN TRANH"
	var active_id = SecureDataManager.active_lesson_id
	if active_id:
		if "bai1" in active_id: l_title = "BÀI 1: NỐT CƠ BẢN"
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
	if current_state == State.PRACTICE_SINGLE:
		_process_practice_single(delta)
	elif current_state == State.PRACTICE:
		_process_practice(delta)
	
	_update_continuous_pitch_hud()

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

func _update_continuous_pitch_hud():
	if not analyzer:
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
	
	if db <= analyzer.volume_threshold_db or pitch <= 0.0:
		if mic_cooldown <= 0.0 and wrong_note_cooldown <= 0.0:
			if pitch_note_lbl: pitch_note_lbl.text = "🎵 Nốt: ---"
			if pitch_status_lbl:
				pitch_status_lbl.text = "🎙️ Đang nghe..."
				pitch_status_lbl.add_theme_color_override("font_color", Color(0.9, 0.88, 0.78))
			if pitch_meter:
				pitch_meter.is_active = false
				pitch_meter.queue_redraw()
		return

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
	if cents_error <= 45.0:
		return true

	# Never accept an octave or harmonic as the requested string. Use the native
	# detector only as a second exact-frequency measurement of the same note.
	if analyzer and target_note_name != "":
		var detected_note: Dictionary = analyzer.detect_dan_tranh_note(
			analyzer._analysis_buffer,
			AudioServer.get_mix_rate()
		)
		var detected_frequency: float = detected_note.get("frequency", 0.0)
		if detected_note.get("note_name", "None") == target_note_name and detected_frequency > 0.0:
			var detected_cents := absf(1200.0 * log(detected_frequency / target_hz) / log(2.0))
			return detected_cents <= 45.0

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
	if pause_btn:
		pause_btn.visible = false
	if pause_overlay:
		pause_overlay.visible = false
	if pitch_box:
		pitch_box.visible = false
	_play_next_intro_step()

func _play_next_intro_step():
	var dialogues = LESSON_DIALOGUES.get(current_lesson_id, [])
	if intro_step >= dialogues.size():
		if current_lesson_id.begins_with("dan_tranh_level_6"):
			_start_practice_single()
		else:
			_start_practice()
		return
		
	var step_data = dialogues[intro_step]
	if step_data["action"] == "speak":
		speech_text.text = step_data["text"]
		if ai_audio:
			ai_audio.speak_vietnamese(step_data["text"])
			
		# Highlight string
		zither_board.call("clear_lesson_markers")
		var highlight_idx = step_data.get("highlight", -1)
		if highlight_idx >= 0:
			zither_board.call("set_lesson_marker", highlight_idx, "Gảy", 1)
			
			# Redesign lesson 1 level 1, lesson 2 level 1 and lesson 5 level 2 to wait for player input on note introduction steps!
			if current_lesson_id in ["dan_tranh_level_1_bai_1_practice", "dan_tranh_level_1_bai_2_practice", "dan_tranh_level_1_bai_4_practice", "dan_tranh_level_2_bai_5_practice"]:
				current_state = State.PRACTICE_SINGLE
				var target_note = step_data.get("note", ALL_17_NOTES[highlight_idx])
				staff_display.visible = true
				if staff_card: staff_card.visible = true
				_update_staff_layout()
				staff_display.set_notes([{"note": "ZT_" + target_note, "x": staff_display.hit_line_x, "color": C_GOLD}])
				intro_step += 1
				return



		else:
			staff_display.visible = false
			
		# Wait for speech to finish then go to next step
		var wait_time = max(1.5, step_data["text"].length() * 0.1)
		get_tree().create_timer(wait_time).timeout.connect(func():
			if current_state == State.INTRO:
				_play_next_intro_step()
		)
	intro_step += 1

func _start_practice_single():
	current_state = State.PRACTICE_SINGLE
	teacher_area.visible = true
	feedback_area.visible = true
	staff_display.visible = true
	if staff_card: staff_card.visible = true
	if title_plaque: title_plaque.visible = true
	if pill_badge: pill_badge.visible = true
	if sub_instr_row: sub_instr_row.visible = true
	_update_staff_layout()
	if skip_intro_btn:
		skip_intro_btn.visible = false
	if pause_btn:
		pause_btn.visible = true
	if pitch_box:
		pitch_box.visible = true
	

	unique_practice_notes.clear()
	if current_lesson_id == "dan_tranh_level_6_bai_13_practice":
		unique_practice_notes = lesson_sheet.duplicate()
	else:
		for note in lesson_sheet:
			if not unique_practice_notes.has(note):
				unique_practice_notes.append(note)
			
	single_practice_idx = 0
	_schedule_next_single_note()

func _schedule_next_single_note():
	if single_practice_idx >= unique_practice_notes.size():
		if current_lesson_id == "dan_tranh_level_6_bai_13_practice":
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
	
	if current_lesson_id == "dan_tranh_level_6_bai_13_practice" and notes.size() > 1:
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
	wrong_note_cooldown = max(0.0, wrong_note_cooldown - delta)
	
	var target_note := ""
	var target_string_idx := 0
	
	if current_lesson_id in ["dan_tranh_level_1_bai_1_practice", "dan_tranh_level_1_bai_2_practice", "dan_tranh_level_1_bai_4_practice", "dan_tranh_level_2_bai_5_practice"]:
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

		if current_lesson_id in ["dan_tranh_level_1_bai_1_practice", "dan_tranh_level_1_bai_2_practice", "dan_tranh_level_1_bai_4_practice", "dan_tranh_level_2_bai_5_practice"]:
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
		staff_display.set_notes([{"note": "ZT_" + target_note, "x": staff_display.hit_line_x, "color": Color(0.9, 0.15, 0.15, 1.0)}])
	
	if ai_audio:
		ai_audio.speak_vietnamese("Bạn gảy nhầm nốt %s rồi. Hãy gảy nốt %s ở dây số %d nhé!" % [detected_note, target_note, target_idx + 1])

func _on_intro_note_correct(note_name: String) -> void:
	current_state = State.INTRO
	staff_display.set_notes([{"note": "ZT_" + note_name, "x": staff_display.hit_line_x, "color": Color(0.2, 0.8, 0.3, 1.0)}])
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
	if current_state == State.PRACTICE_SINGLE:
		if current_lesson_id in ["dan_tranh_level_1_bai_1_practice", "dan_tranh_level_1_bai_2_practice", "dan_tranh_level_1_bai_4_practice", "dan_tranh_level_2_bai_5_practice"]:
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
				if note_name in target_note.split("+"):
					is_correct = true
			else:
				if note_name == target_note:
					is_correct = true
					
			if is_correct:
				_on_single_note_correct(target_note)
			else:
				var target_idx = NOTE_TO_STRING.get(target_note.split("+")[0], 0)
				_on_wrong_note_played(note_name, idx, target_note, target_idx)

	elif current_state == State.PRACTICE:
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

func _is_note_missing(note_idx: int) -> bool:
	if current_lesson_id != "dan_tranh_level_1_bai_3_practice":
		return false
	# Mỗi nốt màu bạc cách nhau 15 nốt đen (tức là nốt khuyết xuất hiện sau mỗi 16 nốt: chỉ số 15, 31, 47, 63...)
	return note_idx % 16 == 15


func _start_practice():
	current_state = State.PRACTICE
	teacher_area.visible = false
	feedback_area.visible = true
	practice_idx = 0
	practice_time = 0.0
	active_falling_notes.clear()
	consecutive_hits = 0
	consecutive_misses = 0
	total_misses = 0
	current_speed_multiplier = user_speed_multiplier
	if speed_bar_container:
		speed_bar_container.visible = true
	if skip_intro_btn:
		skip_intro_btn.visible = false
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
	
	zither_board.call("clear_lesson_markers")
	if analyzer:
		pass
		
	# Determine BPM based on current lesson
	var lesson_bpm: float = 60.0
	if current_lesson_id == "dan_tranh_level_3_bai_7_practice": lesson_bpm = 80.0
	elif current_lesson_id == "dan_tranh_level_3_bai_8_practice": lesson_bpm = 85.0
	elif current_lesson_id == "dan_tranh_level_5_bai_11_practice": lesson_bpm = 85.0
	elif current_lesson_id.begins_with("dan_tranh_level_3"): lesson_bpm = 80.0
	elif current_lesson_id.begins_with("dan_tranh_level_4"): lesson_bpm = 85.0
	elif current_lesson_id.begins_with("dan_tranh_level_5"): lesson_bpm = 90.0
	
	var scroll_speed = 350.0
	var distance_per_beat = (scroll_speed * 60.0) / lesson_bpm
	var start_x = staff_display.size.x + 100.0
	
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
			
			for single_note in notes_in_chord:
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
					"chord_group_id": i,
					"raw_chord_name": raw_note_name
				})
		cur_beat += dur

func _process_practice(delta):
	if active_falling_notes.size() == 0 and practice_idx >= lesson_sheet.size():
		_finish_practice()
		return
		
	if mic_cooldown > 0.0:
		mic_cooldown -= delta

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
				# Highlight target string on zither board
				zither_board.call("set_lesson_marker", s_idx, "Gảy: " + clean_note, 1)
				
				var target_hz = NOTE_FREQS.get(clean_note, 0.0)
				
				var raw_chord_name = note.get("raw_chord_name", clean_note)
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
				if analyzer and wrong_note_cooldown <= 0.0 and mic_cooldown <= 0.0:
					var db = analyzer.current_amplitude_db
					if db > -28.0:
						var note_info = analyzer.detect_dan_tranh_note(analyzer._analysis_buffer, AudioServer.get_mix_rate())
						var det_name = note_info.get("note_name", "None")
						var det_idx = note_info.get("string_index", -1)
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

func _check_mic_pitch(target_hz: float, delta: float = 0.016, _target_note_name: String = "") -> bool:
	if not analyzer:
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
		var notes = _target_note_name.split("+")
		if analyzer and analyzer.get("_spectrum") != null:
			var spec = analyzer.get("_spectrum") as AudioEffectSpectrumAnalyzerInstance
			var all_detected = true
			for n in notes:
				var freq = NOTE_FREQS.get(n, 0.0)
				if freq > 0.0:
					var mag1 = spec.get_magnitude_for_frequency_range(freq * 0.97, freq * 1.03).length()
					var mag2 = spec.get_magnitude_for_frequency_range(freq * 1.97, freq * 2.03).length()
					var max_mag = max(mag1, mag2)
					var freq_db = 20.0 * log(max_mag) / log(10) if max_mag > 0.0001 else -80.0
					# Relaxed threshold to -52.0 dB to prevent soft pluck chord recognition failure
					if freq_db < -52.0:
						all_detected = false
						break
			if all_detected:
				is_match = true
		
		# Fallback to monophonic YIN match of any note in the chord if spectrum analyzer did not match
		if not is_match:
			for n in notes:
				var freq = NOTE_FREQS.get(n, 0.0)
				if freq > 0.0 and pitch > 0.0:
					var cents_error = absf(1200.0 * log(pitch / freq) / log(2.0))
					if cents_error <= 45.0: # Match robust threshold
						is_match = true
						break
	else:
		if target_hz > 0.0 and pitch > 0.0:
			var cents_error = 1200.0 * log(pitch / target_hz) / log(2.0)
			if pitch_meter:
				pitch_meter.current_cents = cents_error
				pitch_meter.is_active = true
				pitch_meter.queue_redraw()
			is_match = _is_pitch_match_robust(target_hz, _target_note_name, pitch)
	var hold_time_needed = REQUIRED_HOLD_TIME
	if target_hz > 1000.0:
		hold_time_needed = 0.08  # ~5 frames for extremely high strings (Đô3, Mi3, Sol4, La4)
	elif target_hz > 600.0:
		hold_time_needed = 0.12  # ~7 frames for high strings (Sol3, La3)

	if not is_match:
		time_correct = max(0.0, time_correct - delta * 2.0)
		return false

	time_correct += delta
	if time_correct < hold_time_needed:
		return false

	time_correct = 0.0
	return true





func _finish_practice():
	current_state = State.COMPLETED
	if analyzer:
		pass
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
			if att["vibrato_detected"] or att["bend_detected"]:
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
	if analyzer:
		pass
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

func _create_skip_intro_button():
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
	shader.code = "shader_type canvas_item;
	uniform vec4 modulate_color : source_color = vec4(1.0);
	void fragment() {
		vec4 tex = texture(TEXTURE, UV);
		COLOR = vec4(modulate_color.rgb, tex.a * modulate_color.a);
	}"
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
	shader.code = "shader_type canvas_item;
	uniform vec4 modulate_color : source_color = vec4(1.0);
	void fragment() {
		vec4 tex = texture(TEXTURE, UV);
		COLOR = vec4(modulate_color.rgb, tex.a * modulate_color.a);
	}"
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
	shader.code = "shader_type canvas_item;
	uniform vec4 modulate_color : source_color = vec4(1.0);
	void fragment() {
		vec4 tex = texture(TEXTURE, UV);
		COLOR = vec4(modulate_color.rgb, tex.a * modulate_color.a);
	}"
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
	var spacing = clampf(max_spacing, 46.0, 78.0)
	staff_display.line_spacing = spacing
	staff_display.queue_redraw()
