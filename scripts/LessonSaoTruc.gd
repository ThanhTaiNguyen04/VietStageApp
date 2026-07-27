extends Control
class_name LessonSaoTruc

@export var hole_offset_x: float = -40.0
@export var hole_offset_y: float = -27.0

const C_GOLD       := Color(0.961, 0.784, 0.259, 1.0)
const C_WOOD       := Color(0.18, 0.13, 0.08, 1.0)

enum State { INTRO, PRACTICE, MID_INTRO, RHYTHM_GAME, COMPLETED }
var current_state = State.INTRO

@onready var root = $Root
@onready var flute_body = $Root/CenterContainer/FluteBoard/BoardM/FluteFrame/FluteM/FluteStack/FluteBody
@onready var rhythm_area = $Root/CenterContainer/FluteBoard/BoardM/FluteFrame/FluteM/FluteStack/RhythmArea
@onready var holes_overlay = $Root/CenterContainer/FluteBoard/BoardM/FluteFrame/FluteM/FluteStack/HolesOverlay
@onready var instruction_lbl = $Root/TopMargin/InstructionLabel
@onready var sub_instruction_lbl = $Root/TopMargin/SubInstructionLabel
@onready var back_btn = $BackBtn
@onready var complete_btn = $CompleteBtn

@onready var teacher_area = $TeacherArea
@onready var speech_text = $TeacherArea/DialogBox/M/V/SpeechText
@onready var real_mode_btn = $TeacherArea/DialogBox/M/V/ModeButtons/RealModeBtn

@onready var analyzer = $Analyzer
@onready var feedback_area = $FeedbackArea
@onready var mic_status = $FeedbackArea/MicStatus
@onready var volume_bar = $FeedbackArea/VolumeBar

var staff_display: Control

var active_note := "Si"
var active_node_id := "Node2"

var record_btn: Button
var playback_btn: Button
var retry_btn: Button
var understood_btn: Button
var sample_btn: Button
var _is_recording := false
var _recorded_stream: AudioStreamWAV = null
var _playback_player: AudioStreamPlayer = null
var bgm_player: AudioStreamPlayer
var bgm_controls: HBoxContainer
var bgm_slider: HSlider
var bgm_toggle_btn: Button

var intro_overlay: ColorRect
var complete_overlay: ColorRect
var _holes : Array[Control] = []
var _lanes : Array[ColorRect] = []

var is_virtual_mode := false
var virtual_holes_state := [false, false, false, false, false, false]

var target_hz := 0.0
var time_correct := 0.0
var REQUIRED_HOLD_TIME := 0.4 # Quicker recognition (0.4s) to feel instant

var rhythm_time := 0.0
var spawned_notes := 0
var active_falling_notes := []
var _practice_note_node
var _practice_sequence = []
var _current_practice_idx = 0
var _practice_time: float = 0.0
var total_rhythm_duration: float = 0.0
var wrong_rhythm_duration: float = 0.0
var has_rhythm_completed: bool = false

var _current_note_color: Color = Color(0.96, 0.75, 0.25)
const HIT_WINDOW := 0.5 # Nới lỏng thời gian chấm điểm thêm nữa

var melody_sequence = []

const HOLES = 6

# Physical hole proportional positions (from Python analysis of saotruc.png)
const HOLE_PROPS_X = [0.3335, 0.4080, 0.4787, 0.5512, 0.6237, 0.7030]
const HOLE_PROP_Y = 0.375

const LESSON_NOTES = {
	"Node2": {"note": "Si", "desc": "Mở toàn bộ 6 lỗ, không che lỗ nào", "fingers": [false, false, false, false, false, false]}, # Si
	"Node3": {"note": "La", "desc": "Bấm ngón tay vào lỗ đầu tiên", "fingers": [true, false, false, false, false, false]},
	"Node4": {"note": "Sol", "desc": "Bấm ngón tay vào 2 lỗ đầu tiên", "fingers": [true, true, false, false, false, false]},
	"Node5": {"note": "Fa", "desc": "Bấm ngón tay vào 3 lỗ", "fingers": [true, true, true, false, false, false]},
	"Node6": {"note": "Mi", "desc": "Bấm ngón tay vào 4 lỗ", "fingers": [true, true, true, true, false, false]},
	"Node7": {"note": "Rê", "desc": "Bấm ngón tay vào 5 lỗ", "fingers": [true, true, true, true, true, false]},
	"Node8": {"note": "Đô", "desc": "Bấm cả 6 lỗ và thổi nhẹ", "fingers": [true, true, true, true, true, true]},
		"Node9": {"note": "Đô", "desc": "Tập thổi nốt Đô", "fingers": [true, true, true, true, true, true]},
	"Node10": {"note": "Sol", "desc": "Tập thổi nốt Sol", "fingers": [true, true, false, false, false, false]},
	"Node11": {"note": "Đô", "desc": "Ghép Đô và Sol", "fingers": [true, true, true, true, true, true]},
	"Node12": {"note": "La", "desc": "Tập thổi nốt La", "fingers": [true, false, false, false, false, false]},
	"Node13": {"note": "Đô", "desc": "Câu nhạc 1", "fingers": [true, true, true, true, true, true]},
	"Node14": {"note": "Fa", "desc": "Tập thổi nốt Fa", "fingers": [true, true, true, false, false, false]},
	"Node15": {"note": "Mi", "desc": "Tập thổi nốt Mi", "fingers": [true, true, true, true, false, false]},
	"Node16": {"note": "Rê", "desc": "Tập thổi nốt Rê", "fingers": [true, true, true, true, true, false]},
	"Node17": {"note": "Fa", "desc": "Câu nhạc 2", "fingers": [true, true, true, false, false, false]},
	"Node18": {"note": "Đô", "desc": "Thi Đậu Khúc Nhạc Vui", "fingers": [true, true, true, true, true, true]},
	"Node19": {"note": "Đô2", "desc": "Tập thổi nốt Đô2 (C6)", "fingers": [true, true, true, true, true, true], "title": "Tập nốt Đô2"},
	"Node20": {"note": "Rê2", "desc": "Tập thổi nốt Rê2 (D6)", "fingers": [true, true, true, true, true, false], "title": "Tập nốt Rê2"},
	"Node21": {"note": "Đô2", "desc": "Luyện chuyển ngón Đô2 - Rê2", "fingers": [true, true, true, true, true, true], "title": "Chuyển ngón C6-D6"},
	"Node22": {"note": "Sol", "desc": "Tập thổi nốt Sol trầm (G5)", "fingers": [true, true, false, false, false, false], "title": "Tập nốt Sol"},
	"Node23": {"note": "Đô2", "desc": "Thổi câu nhạc mở đầu bài Trống Cơm", "fingers": [true, true, true, true, true, true], "title": "Mở đầu Trống Cơm"},
	"Node24": {"note": "Fa", "desc": "Tập thổi nốt Fa trầm (F5)", "fingers": [true, true, true, false, false, false], "title": "Tập nốt Fa"},
	"Node25": {"note": "Đô2", "desc": "Khen ai khéo vỗ mấy bông", "fingers": [true, true, true, true, true, true], "title": "Câu nhạc 2"},
	"Node26": {"note": "Đô2", "desc": "Ghép toàn bộ Đoạn 1 hoàn chỉnh", "fingers": [true, true, true, true, true, true], "title": "Hoàn thành Đoạn 1"},
	"Node27": {"note": "Mi2", "desc": "Một vầy tang tình con sít", "fingers": [true, true, true, true, false, false], "title": "Học Đoạn 2"},
	"Node28": {"note": "Đô2", "desc": "Thổi trọn vẹn bài Trống Cơm với nhạc đệm", "fingers": [true, true, true, true, true, true], "title": "Thi Đấu Trống Cơm"}
}

const LESSON_DIALOGUES = {
	"Node2": {
		"intro": "Chào bạn! Đây là bài học Sáo Trúc đầu tiên. Nốt Si là nốt cơ bản nhất, âm thanh thanh thoát và nhẹ nhàng. Để thổi nốt Si, bạn chỉ cần mở toàn bộ 6 lỗ, không che lỗ nào. Hãy cầm sáo lên và thổi một luồng hơi ấm dịu nhé!",
		"mid": "Tuyệt vời! Bạn có thấy âm thanh nốt Si thật trong trẻo không? Bây giờ, hãy cùng chơi một bản nhạc nhỏ để làm quen với nhịp điệu nhé!"
	},
	"Node3": {
		"intro": "Chào mừng bạn trở lại! Hôm nay chúng ta sẽ chinh phục nốt La. Nốt La có âm sắc trầm hơn nốt Si một chút. Bấm ngón tay trỏ tay trái vào lỗ đầu tiên thật kín và thổi nhẹ nào!",
		"mid": "Rất tốt! Âm La nghe rất vang và ấm đúng không? Bây giờ hãy thử kết hợp nốt La với nốt Si vừa học trong một thử thách nhịp điệu nhé!"
	},
	"Node4": {
		"intro": "Bạn tiến bộ nhanh lắm! Nốt tiếp theo là nốt Sol. Hãy dùng hai ngón tay che kín 2 lỗ đầu tiên. Nhớ là các ngón tay phải bịt thật kín mặt lỗ để âm thanh không bị xì nhé!",
		"mid": "Xuất sắc! Việc chuyển ngón giữa các nốt Si, La, Sol là nền tảng của rất nhiều bài nhạc hay. Chúng ta cùng tập ghép chúng lại nào!"
	},
	"Node5": {
		"intro": "Hôm nay chúng ta học nốt Fa! Âm Fa mang lại cảm giác hơi man mác buồn. Bịt kín 3 lỗ đầu tiên nhé. Cẩn thận ngón áp út tay trái thường hay hở nhất đấy!",
		"mid": "Hay lắm! Càng bịt nhiều lỗ, hơi thổi của bạn cần phải đều đặn hơn. Hãy sẵn sàng cho thử thách bấm thả liên tục nhé!"
	},
	"Node6": {
		"intro": "Chào bạn! Đã đến lúc dùng đến bàn tay phải rồi. Để thổi nốt Mi, bạn che 4 lỗ đầu. Hãy thả lỏng cổ tay phải và đặt ngón trỏ thật tự nhiên nhé!",
		"mid": "Thật tuyệt vời! Bạn đã điều khiển được bàn tay phải rồi đó. Hãy cùng chơi một giai điệu để kết hợp cả hai tay nhé!"
	},
	"Node7": {
		"intro": "Sắp chinh phục được toàn bộ các nốt cơ bản rồi! Nốt Rê yêu cầu bạn bịt 5 lỗ. Cột hơi bây giờ cần phải sâu và nén tốt hơn. Hãy hít một hơi thật sâu nào!",
		"mid": "Giỏi lắm! Âm Rê rung lên rất êm ái. Chơi tốt nốt này chứng tỏ kỹ năng kiểm soát hơi của bạn đã tiến bộ vượt bậc!"
	},
	"Node8": {
		"intro": "Chúc mừng bạn đã đến với nốt trầm nhất của cây sáo: Nốt Đô! Bịt kín toàn bộ 6 lỗ. Hãy thổi thật khẽ và ấm, vì nếu thổi mạnh nó sẽ vút lên nốt cao đấy!",
		"mid": "Hoàn hảo! Cảm nhận độ rung của thân sáo khi thổi nốt Đô thật thích đúng không? Giờ là lúc kết hợp toàn bộ 6 nốt để tạo nên phép màu!"
	},
		"Node9": {
		"intro": "Chào mừng bạn đến với Hành Trình Khúc Nhạc Vui! Bài hát đầu tiên của chúng ta rất dễ thương. Bắt đầu bằng nốt Đô nhé.",
		"mid": "Tốt lắm! Nốt Đô là nốt trầm ấm. Hãy chuẩn bị bắt nhịp để thổi nốt Đô theo nhạc rơi nhé!"
	},
	"Node10": {
		"intro": "Tiếp theo, chúng ta học nốt Sol. Bấm 2 lỗ đầu tiên. Nốt Sol trong trẻo và vang vọng.",
		"mid": "Giỏi lắm! Giờ hãy thổi nốt Sol theo nhịp điệu rơi xuống nhé!"
	},
	"Node11": {
		"intro": "Bây giờ chúng ta ghép 2 nốt Đô và Sol với nhau nhé! Luyện tập chuyển ngón thật nhanh.",
		"mid": "Tay bạn đã bắt đầu dẻo dai rồi. Sẵn sàng cho thử thách rơi nốt Đô và Sol chưa?"
	},
	"Node12": {
		"intro": "Nốt La! Bấm 1 lỗ duy nhất. Đây là nốt cao nhất trong câu đầu tiên của bài hát.",
		"mid": "Tuyệt vời! Bây giờ luyện tập thổi nốt La theo nhịp điệu nhé."
	},
	"Node13": {
		"intro": "Lắp ráp câu nhạc 1: Đô Đô Sol Sol La La Sol. Bạn hãy chú ý nhịp điệu nhẹ nhàng và tươi vui nhé!",
		"mid": "Hoàn hảo! Tay và hơi của bạn đã sẵn sàng. Cùng thổi câu 1 nào!"
	},
	"Node14": {
		"intro": "Học tiếp nửa bài sau nhé. Bắt đầu với nốt Fa. Bấm 3 lỗ, âm thanh hơi trầm buồn một chút.",
		"mid": "Fa rất tốt! Cùng luyện tập nhịp điệu nốt Fa nhé."
	},
	"Node15": {
		"intro": "Thêm nốt Mi. Bấm 4 lỗ. Đừng quên giữ hơi thật đều để nốt không bị chênh phô nhé.",
		"mid": "Rất êm ái! Giờ hãy theo dõi nốt rơi và thổi nốt Mi."
	},
	"Node16": {
		"intro": "Nốt Rê! Bấm 5 lỗ. Gần như kín hết các lỗ rồi, hãy thổi hơi sâu hơn một chút.",
		"mid": "Kiểm soát hơi rất tốt! Chuẩn bị thổi nốt Rê theo nhịp nhé."
	},
	"Node17": {
		"intro": "Ghép câu nhạc 2: Fa Fa Mi Mi Rê Rê Đô. Các nốt đi dần xuống trầm, hãy thả lỏng tay.",
		"mid": "Tuyệt vời, bạn đã thuộc hết các nốt! Hãy thổi đoạn nhạc này nhé."
	},
	"Node18": {
		"intro": "Thử Thách Cuối Cùng! Thi Đậu Bài Hát Khúc Nhạc Vui trọn vẹn. Bạn cần đạt trên 75% độ chính xác để qua ván này!",
		"mid": "Sẵn sàng chưa? Khúc Nhạc Vui xin được phép bắt đầu!"
	},
	"Node19": {
		"intro": "Chào bạn! Bắt đầu học Trống Cơm nhé. Nốt Đô2 (C6) là nốt khá cao, hãy thổi hơi tập trung và bịt kín cả 6 lỗ nhé!",
		"mid": "Rất tốt! Cùng luyện tập nhịp điệu nốt Đô2 nào!"
	},
	"Node20": {
		"intro": "Học nốt Rê2. Che 5 lỗ đầu tiên và hé lỗ cuối. Thổi hơi sâu để nốt bay cao nhé!",
		"mid": "Tuyệt vời, Rê2 nghe rất vang. Thổi theo nhịp nào!"
	},
	"Node21": {
		"intro": "Bây giờ hãy tập ghép Đô2 và Rê2 nhé. Di chuyển ngón út thật linh hoạt!",
		"mid": "Sắp được rồi! Sẵn sàng chơi theo nhịp rơi Đô2 và Rê2 chưa?"
	},
	"Node22": {
		"intro": "Luyện lại nốt Sol trầm để chuẩn bị vào bài. Che 2 lỗ đầu tiên.",
		"mid": "Tốt lắm! Thổi nốt Sol thật ấm nhé."
	},
	"Node23": {
		"intro": "Học câu nhạc 1 của Trống Cơm: Sol Sol Đô2 Đô2 Rê2 Đô2 Sol. Giai điệu mở đầu siêu quen thuộc!",
		"mid": "Tuyệt lắm! Cùng chinh phục câu nhạc mở đầu nhé!"
	},
	"Node24": {
		"intro": "Ôn lại nốt Fa để chuẩn bị cho câu tiếp theo. Che 3 lỗ đầu tiên.",
		"mid": "Rất chuẩn! Thổi nốt Fa theo nhịp nào."
	},
	"Node25": {
		"intro": "Học câu nhạc 2: Khen ai khéo vỗ... Sol Fa Sol Đô2 Sol Đô2 Đô2 Đô2 Sol Sol Fa Sol. Hãy chú ý các nốt luyến!",
		"mid": "Hay lắm! Chuẩn bị thổi theo nhịp nào!"
	},
	"Node26": {
		"intro": "Ghép toàn bộ Đoạn 1 bài Trống Cơm! Nhịp điệu dồn dập, tươi vui và đầy sức sống.",
		"mid": "Chuẩn bị nhạc đệm. Cố gắng đạt độ chính xác cao nhé!"
	},
	"Node27": {
		"intro": "Bắt đầu Đoạn 2: Một vầy tang tình con sít... Đô2 Đô2 Rê2 Đô2 Rê2 Mi2. Chú ý nốt Mi2 cao nhé!",
		"mid": "Tốt lắm! Luyện tập câu sít lội sông nào!"
	},
	"Node28": {
		"intro": "Đã đến lúc Biểu Diễn Trống Cơm! Hãy thổi trọn vẹn bản nhạc dân ca Bắc Ninh đầy tự hào này nhé!",
		"mid": "Sẵn sàng chưa? Khúc nhạc Trống Cơm bắt đầu!"
	}
}

const NOTE_FREQS = {
	"Đô": 523.25,
	"Rê": 587.33,
	"Mi": 659.25,
	"Fa": 698.46,
	"Sol": 783.99,
	"La": 880.00,
	"Sib": 932.33,
	"Si": 987.77,
	"Đô2": 1046.50,
	"Rê2": 1174.66,
	"Mi2": 1318.51,
	"Fa2": 1396.91,
	"Sol2": 1567.98,
	"La2": 1760.00,
	"Sib2": 1864.66,
	"Si2": 1975.53
}

func _ready():
	volume_bar.visible = false
	bgm_player = AudioStreamPlayer.new()
	bgm_player.volume_db = -5.0
	add_child(bgm_player)

	bgm_controls = HBoxContainer.new()
	bgm_controls.name = "BGMControls"
	bgm_controls.add_theme_constant_override("separation", 15)
	
	var lbl = Label.new()
	lbl.text = "Nhạc nền"
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 1))
	bgm_controls.add_child(lbl)
	
	bgm_slider = HSlider.new()
	bgm_slider.custom_minimum_size = Vector2(150, 40)
	bgm_slider.min_value = -30
	bgm_slider.max_value = 10
	bgm_slider.value = -5
	bgm_slider.step = 1.0
	bgm_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bgm_controls.add_child(bgm_slider)
	
	bgm_toggle_btn = Button.new()
	bgm_toggle_btn.text = " Tắt"
	bgm_toggle_btn.icon = load("res://assets/textures/lucide/music.svg")
	bgm_toggle_btn.expand_icon = true
	bgm_toggle_btn.custom_minimum_size = Vector2(100, 40)
	var sb_btn2 = StyleBoxFlat.new()
	sb_btn2.bg_color = Color(0.85, 0.65, 0.25, 1.0)
	sb_btn2.corner_radius_top_left = 10; sb_btn2.corner_radius_top_right = 10
	sb_btn2.corner_radius_bottom_left = 10; sb_btn2.corner_radius_bottom_right = 10
	bgm_toggle_btn.add_theme_stylebox_override("normal", sb_btn2)
	bgm_toggle_btn.add_theme_stylebox_override("hover", sb_btn2)
	bgm_controls.add_child(bgm_toggle_btn)
	
	add_child(bgm_controls)
	
	# Anchors and positioning
	bgm_controls.anchor_left = 1.0
	bgm_controls.anchor_right = 1.0
	bgm_controls.anchor_top = 0.0
	bgm_controls.anchor_bottom = 0.0
	bgm_controls.offset_left = -450
	bgm_controls.offset_right = -30
	bgm_controls.offset_top = 130
	bgm_controls.offset_bottom = 180
	
	if SecureDataManager.active_lesson_id == "Node42":
		bgm_controls.visible = true
	else:
		bgm_controls.visible = false
		
	# Connect signals
	bgm_toggle_btn.pressed.connect(func():
		if bgm_player.volume_db <= -70.0:
			bgm_player.volume_db = bgm_slider.value
			bgm_toggle_btn.text = " Tắt"
			bgm_toggle_btn.modulate = Color(1, 1, 1, 1)
		else:
			bgm_player.volume_db = -80.0
			bgm_toggle_btn.text = " Bật"
			bgm_toggle_btn.modulate = Color(0.5, 0.5, 0.5, 1)
	)
	
	bgm_slider.value_changed.connect(func(val):
		if bgm_player.volume_db > -70.0:
			bgm_player.volume_db = val
	)

	
	back_btn.pressed.connect(_on_back)
	complete_btn.pressed.connect(_on_complete)
	real_mode_btn.pressed.connect(_start_real)
	
	var sb_btn = StyleBoxFlat.new()
	sb_btn.bg_color = C_GOLD
	sb_btn.corner_radius_top_left = 15; sb_btn.corner_radius_top_right = 15
	sb_btn.corner_radius_bottom_left = 15; sb_btn.corner_radius_bottom_right = 15
	real_mode_btn.text = "  Thực Hành Ngay  "
	
	complete_btn.add_theme_stylebox_override("normal", sb_btn)
	complete_btn.add_theme_stylebox_override("hover", sb_btn)
	real_mode_btn.add_theme_stylebox_override("normal", sb_btn)
	real_mode_btn.add_theme_stylebox_override("hover", sb_btn)

	
	_build_complete_overlay()
	_build_flute()
	
	# Style the DialogBox
	var dialog_sb = StyleBoxFlat.new()
	dialog_sb.bg_color = Color(0.95, 0.95, 0.95, 0.95)
	dialog_sb.corner_radius_top_left = 30; dialog_sb.corner_radius_top_right = 30
	dialog_sb.corner_radius_bottom_left = 30; dialog_sb.corner_radius_bottom_right = 30
	dialog_sb.border_width_top = 4; dialog_sb.border_width_bottom = 4
	dialog_sb.border_width_left = 4; dialog_sb.border_width_right = 4
	dialog_sb.border_color = C_GOLD
	$TeacherArea/DialogBox.add_theme_stylebox_override("panel", dialog_sb)
	speech_text.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1, 1.0))
	
	active_node_id = SecureDataManager.active_lesson_id
	var txt = ""
	if LESSON_NOTES.has(active_node_id):
		var lesson_info = LESSON_NOTES[active_node_id]
		active_note = lesson_info["note"]
		instruction_lbl.visible = false
		sub_instruction_lbl.visible = false
		_show_fingers(lesson_info["fingers"])
		target_hz = NOTE_FREQS.get(active_note, 0.0)
		
		# Setup Intro Speech
		if LESSON_DIALOGUES.has(active_node_id):
			txt = LESSON_DIALOGUES[active_node_id]["intro"]
		else:
			txt = "Chào mừng bạn đến bài học! Hôm nay chúng ta sẽ làm quen với nốt " + active_note + ", để thổi nốt " + active_note + " bạn " + lesson_info["desc"].to_lower() + ". Nào cùng thử nhé!"
	else:
		active_note = "Đô"
		instruction_lbl.visible = false
		sub_instruction_lbl.visible = false
		_show_fingers([true, true, true, true, true, true])
		target_hz = NOTE_FREQS.get(active_note, 0.0)
		
		var title = SecureDataManager.data.get("current_song_title", "Bài tập")
		txt = "Chào mừng bạn đến với bài học " + title + "! Hãy chuẩn bị sẵn sàng sáo trúc và làm theo các nốt nhạc rơi xuống nhé."

	speech_text.text = txt
	
	# Use AIAudioManager for high quality Google Translate TTS
	var ai_audio = load("res://scripts/AIAudioManager.gd").new()
	ai_audio.name = "AIAudio"
	add_child(ai_audio)
	
	var stream = null
	if active_node_id == "Node2":
		stream = load("res://audio/introSi.mp3")
	elif active_node_id in ["Node3", "Node4", "Node5", "Node6", "Node7", "Node8"]:
		stream = load("res://audio/intro" + active_node_id + ".mp3")
	if stream and is_instance_valid(ai_audio.audio_player):
		ai_audio.audio_player.stream = stream
		ai_audio.audio_player.play()
	else:
		ai_audio.speak_vietnamese(txt)
	
	# Initial UI State
	teacher_area.visible = true
	feedback_area.visible = false
	analyzer.visible = false
	current_state = State.INTRO
	
	# Setup Staff Display
	# Hide old rhythm UI
	if rhythm_area: rhythm_area.visible = false
	
	_setup_premium_practice_ui()
	
	intro_overlay = ColorRect.new()
	intro_overlay.color = Color(0, 0, 0, 0.5)
	intro_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(intro_overlay)
	move_child(intro_overlay, get_node("Root").get_index())
	
	staff_display.visible = true
	if active_node_id in ["Node2", "Node3", "Node4", "Node5", "Node6", "Node7", "Node8"]:
		staff_display.set_note(active_note)

func _setup_premium_practice_ui():
	var bg_ov = get_node_or_null("BGOverlay")
	if bg_ov and bg_ov is ColorRect:
		bg_ov.color = Color(0.965, 0.935, 0.875, 0.96)
		
	var screen_frame = Panel.new()
	screen_frame.name = "ScreenGoldFrame"
	screen_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_frame.offset_left = 16; screen_frame.offset_top = 16; screen_frame.offset_right = -16; screen_frame.offset_bottom = -16
	screen_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sf_sb = StyleBoxFlat.new()
	sf_sb.draw_center = false
	sf_sb.border_color = Color(0.85, 0.68, 0.35, 0.6)
	sf_sb.border_width_left = 2; sf_sb.border_width_right = 2; sf_sb.border_width_top = 2; sf_sb.border_width_bottom = 2
	sf_sb.corner_radius_top_left = 16; sf_sb.corner_radius_top_right = 16; sf_sb.corner_radius_bottom_left = 16; sf_sb.corner_radius_bottom_right = 16
	screen_frame.add_theme_stylebox_override("panel", sf_sb)
	add_child(screen_frame)
	move_child(screen_frame, get_node("Root").get_index())
	
	if is_instance_valid(back_btn):
		back_btn.offset_left = 32
		back_btn.offset_top = 26
		back_btn.custom_minimum_size = Vector2(155, 48)
		back_btn.text = "← Quay Lại"
		var btn_sb = StyleBoxFlat.new()
		btn_sb.bg_color = Color(0.24, 0.15, 0.09, 1.0)
		btn_sb.border_color = Color(0.88, 0.70, 0.35, 1.0)
		btn_sb.border_width_left = 2; btn_sb.border_width_right = 2; btn_sb.border_width_top = 2; btn_sb.border_width_bottom = 2
		btn_sb.corner_radius_top_left = 24; btn_sb.corner_radius_top_right = 24; btn_sb.corner_radius_bottom_left = 24; btn_sb.corner_radius_bottom_right = 24
		btn_sb.shadow_color = Color(0.1, 0.05, 0.0, 0.35); btn_sb.shadow_size = 5; btn_sb.shadow_offset = Vector2(0, 3)
		back_btn.add_theme_stylebox_override("normal", btn_sb)
		back_btn.add_theme_stylebox_override("hover", btn_sb)
		back_btn.add_theme_stylebox_override("pressed", btn_sb)
		back_btn.add_theme_color_override("font_color", Color(0.98, 0.92, 0.82, 1.0))
		back_btn.add_theme_font_size_override("font_size", 22)
		
	var top_right_box = HBoxContainer.new()
	top_right_box.name = "TopRightIcons"
	top_right_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	top_right_box.offset_left = -160; top_right_box.offset_top = 26; top_right_box.offset_right = -32; top_right_box.offset_bottom = 74
	top_right_box.add_theme_constant_override("separation", 16)
	top_right_box.alignment = BoxContainer.ALIGNMENT_END
	add_child(top_right_box)
	for icon_txt in ["⚙", "♫"]:
		var med_btn = Button.new()
		med_btn.text = icon_txt
		med_btn.custom_minimum_size = Vector2(48, 48)
		var med_sb = StyleBoxFlat.new()
		med_sb.bg_color = Color(0.24, 0.15, 0.09, 1.0)
		med_sb.border_color = Color(0.88, 0.70, 0.35, 1.0)
		med_sb.border_width_left = 2; med_sb.border_width_right = 2; med_sb.border_width_top = 2; med_sb.border_width_bottom = 2
		med_sb.corner_radius_top_left = 24; med_sb.corner_radius_top_right = 24; med_sb.corner_radius_bottom_left = 24; med_sb.corner_radius_bottom_right = 24
		med_sb.shadow_color = Color(0.1, 0.05, 0.0, 0.3); med_sb.shadow_size = 4; med_sb.shadow_offset = Vector2(0, 2)
		med_btn.add_theme_stylebox_override("normal", med_sb)
		med_btn.add_theme_stylebox_override("hover", med_sb)
		med_btn.add_theme_stylebox_override("pressed", med_sb)
		med_btn.add_theme_color_override("font_color", Color(0.96, 0.82, 0.45, 1.0))
		med_btn.add_theme_font_size_override("font_size", 24)
		top_right_box.add_child(med_btn)
		
	var lesson_map = {
		"Node2": {"num": "BÀI 1", "title": "LUYỆN NỐT SI"},
		"Node3": {"num": "BÀI 2", "title": "LUYỆN NỐT LA"},
		"Node4": {"num": "BÀI 3", "title": "LUYỆN NỐT SOL"},
		"Node5": {"num": "BÀI 4", "title": "LUYỆN NỐT FA"},
		"Node6": {"num": "BÀI 5", "title": "LUYỆN NỐT MI"},
		"Node7": {"num": "BÀI 6", "title": "LUYỆN NỐT RÊ"},
		"Node8": {"num": "BÀI 7", "title": "LUYỆN NỐT ĐÔ"}
	}
	var l_num = "BÀI LUYỆN"
	var l_title = "LUYỆN NỐT " + active_note.to_upper()
	if lesson_map.has(active_node_id):
		l_num = lesson_map[active_node_id]["num"]
		l_title = lesson_map[active_node_id]["title"]
	elif LESSON_NOTES.has(active_node_id) and LESSON_NOTES[active_node_id].has("title"):
		l_title = LESSON_NOTES[active_node_id]["title"].to_upper()
		
	var title_plaque = PanelContainer.new()
	title_plaque.name = "TitlePlaque"
	title_plaque.anchor_left = 0.5; title_plaque.anchor_right = 0.5
	title_plaque.offset_left = -265; title_plaque.offset_right = 265
	title_plaque.offset_top = 24; title_plaque.offset_bottom = 132
	var pl_sb = StyleBoxFlat.new()
	pl_sb.bg_color = Color(0.22, 0.14, 0.08, 0.96)
	pl_sb.border_color = Color(0.88, 0.72, 0.35, 1.0)
	pl_sb.border_width_left = 3; pl_sb.border_width_right = 3; pl_sb.border_width_top = 3; pl_sb.border_width_bottom = 3
	pl_sb.corner_radius_top_left = 24; pl_sb.corner_radius_top_right = 24; pl_sb.corner_radius_bottom_left = 24; pl_sb.corner_radius_bottom_right = 24
	pl_sb.shadow_color = Color(0.2, 0.12, 0.05, 0.35); pl_sb.shadow_size = 12; pl_sb.shadow_offset = Vector2(0, 5)
	title_plaque.add_theme_stylebox_override("panel", pl_sb)
	var pl_vbox = VBoxContainer.new()
	pl_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	pl_vbox.add_theme_constant_override("separation", 2)
	title_plaque.add_child(pl_vbox)
	var lbl_num = Label.new()
	lbl_num.text = l_num
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
	
	var staff_card = PanelContainer.new()
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
	
	staff_display = load("res://scripts/StaffDisplay.gd").new()
	staff_display.name = "StaffDisplay"
	staff_display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	staff_display.size_flags_vertical = Control.SIZE_EXPAND_FILL
	staff_card.add_child(staff_display)
	
	var pill_badge = PanelContainer.new()
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
	pill_lbl.text = "🌿    " + active_note.to_upper() + "    🌿"
	pill_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pill_lbl.add_theme_color_override("font_color", Color(0.78, 0.55, 0.18, 1.0))
	pill_lbl.add_theme_font_size_override("font_size", 26)
	pill_badge.add_child(pill_lbl)
	add_child(pill_badge)
	
	var sub_instr_row = HBoxContainer.new()
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
	sub_lbl.text = "   🌿   Thổi nhẹ và giữ hơi ổn định   🌿   "
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

func _start_real():
	if LESSON_NOTES.has(active_node_id):
		_show_fingers(LESSON_NOTES[active_node_id]["fingers"])
	_start_practice()

func _start_practice():
	var ai = get_node_or_null("AIAudio")
	if ai and ai.has_method("speak_vietnamese"):
		ai.audio_player.stop()
		
	current_state = State.PRACTICE
	teacher_area.visible = false
	feedback_area.visible = true
	if intro_overlay: intro_overlay.visible = false
	
	if _practice_note_node:
		_practice_note_node.queue_free()
		_practice_note_node = null
		
	# Populate practice sequence
	if active_node_id in ["Node2", "Node3", "Node4", "Node5", "Node6", "Node7", "Node8"]:
		_practice_sequence = [{"note": active_note, "duration": REQUIRED_HOLD_TIME, "time": 0.0}]
	else:
		_practice_sequence = _generate_melody(active_node_id)
		if _practice_sequence.is_empty():
			_practice_sequence.append({"note": active_note, "duration": REQUIRED_HOLD_TIME, "time": 0.0})
			
	_current_practice_idx = 0
	_practice_time = -1.5 # Reset thời gian và cho 1.5s chuẩn bị
	_update_practice_fingers()

func _update_practice_fingers():
	var current_note_name = _practice_sequence[_current_practice_idx]["note"]
	var req = []
	for k in LESSON_NOTES.keys():
		if LESSON_NOTES[k]["note"] == current_note_name:
			req = LESSON_NOTES[k]["fingers"]
			break
			
	if req.is_empty(): return
	
	# Hướng dẫn bấm ngón cho sáo thật
	for i in range(HOLES):
		_holes[i].get_child(0).visible = req[i]
		_holes[i].get_child(0).modulate = Color(0.2, 0.8, 0.2, 0.6)

	mic_status.text = "Hãy bấm nốt " + current_note_name + " và thổi..."
	mic_status.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

var sample_player: AudioStreamPlayer
var sample_playback: AudioStreamGeneratorPlayback
var sample_active := false
var sample_phase := 0.0
var sample_hz := 440.0
var sample_melody := []
var sample_melody_time := 0.0

func _setup_sample_player():
	sample_player = AudioStreamPlayer.new()
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 44100
	stream.buffer_length = 0.2
	sample_player.stream = stream
	add_child(sample_player)

func _play_current_sample():
	if bgm_player: bgm_player.stop()
	
	if active_node_id == "Node42":
		var stream = load("res://image/gmtm.mp3")
		if stream:
			bgm_player.stream = stream
			bgm_player.play(21.0)

	if not sample_player:
		_setup_sample_player()
	
	if current_state == State.PRACTICE:
		_start_practice()
	
	if active_node_id in ["Node2", "Node3", "Node4", "Node5", "Node6", "Node7", "Node8"]:
		sample_melody = [{"note": active_note, "time": 1.0, "duration": REQUIRED_HOLD_TIME}]
	else:
		sample_melody = _generate_melody(active_node_id)
		if sample_melody.is_empty():
			sample_melody.append({"note": active_note, "time": 1.0, "duration": REQUIRED_HOLD_TIME})
			
	sample_melody_time = 0.0
	sample_phase = 0.0
	sample_hz = 0.0
	sample_player.play()
	sample_playback = sample_player.get_stream_playback()
	sample_active = true

func _process_sample(delta):
	if not sample_active or not sample_playback: return
	
	sample_melody_time += delta
	var current_hz = 0.0
	var note_time_elapsed = 0.0
	var note_duration = 1.0
	
	for note_data in sample_melody:
		var n_time = note_data["time"]
		var duration = note_data.get("duration", 1.0)
		if sample_melody_time >= n_time and sample_melody_time <= n_time + duration:
			var note_name = note_data["note"]
			current_hz = NOTE_FREQS.get(note_name, 0.0)
			note_time_elapsed = sample_melody_time - n_time
			note_duration = duration
			break
			
	if current_hz > 0.0:
		sample_hz = current_hz
	else:
		sample_hz = 0.0
		
	var frames = sample_playback.get_frames_available()
	var increment = sample_hz / 44100.0
	
	for i in range(frames):
		var val = 0.0
		if sample_hz > 0.0:
			var env = 1.0
			if note_time_elapsed < 0.05:
				env = note_time_elapsed / 0.05
			elif note_time_elapsed > note_duration - 0.05:
				env = (note_duration - note_time_elapsed) / 0.05
			else:
				env = 1.0
			env = clamp(env, 0.0, 1.0)
			
			var fund = sin(sample_phase * TAU)
			var h2 = sin(sample_phase * 2.0 * TAU) * 0.3
			var h3 = sin(sample_phase * 3.0 * TAU) * 0.1
			var noise = (randf() * 2.0 - 1.0) * 0.03
			
			val = (fund + h2 + h3 + noise) * 0.2 * env
			
			sample_phase = fmod(sample_phase + increment, 1.0)
			note_time_elapsed += 1.0 / 44100.0
			
		sample_playback.push_frame(Vector2(val, val))
		
	if sample_melody.size() > 0:
		var last_note = sample_melody[sample_melody.size() - 1]
		var end_time = last_note["time"] + last_note.get("duration", 1.0)
		if sample_melody_time > end_time + 0.5:
			sample_active = false
			sample_player.stop()
			if bgm_player: bgm_player.stop()
			if current_state == State.PRACTICE:
				_start_practice()
			return

func _process(delta):
	_process_sample(delta)

	var rect = _get_flute_draw_rect()
	if rect.size.x == 0: return
	
	if flute_body.get_child_count() > 0:
		var tex = flute_body.get_child(0)
		tex.position = rect.position
		tex.size = rect.size
	
	# Update holes overlay positions
	for i in range(HOLES):
		var hx = rect.position.x + rect.size.x * HOLE_PROPS_X[i]
		var hy = rect.position.y + rect.size.y * HOLE_PROP_Y
		_holes[i].position = Vector2(hx - 50 + hole_offset_x, hy - 50 + hole_offset_y)
		
	if current_state == State.PRACTICE:
		if staff_display:
			var hit_x = staff_display.hit_line_x
			var notes = []
			for note_data in _practice_sequence:
				var time_diff = note_data["time"] - _practice_time
				var note_x = hit_x + (time_diff * 300.0) # SCROLL_SPEED
				var duration = note_data.get("duration", 1.0)
				var tail_w = duration * 300.0
				var color = Color(0.96, 0.75, 0.25)
				if _practice_time >= note_data["time"]:
					color = _current_note_color
				notes.append({"note": note_data["note"], "x": note_x, "color": color, "tail": tail_w})
			staff_display.set_notes(notes)
					
		if sample_active:
			mic_status.text = "Đang phát nhạc mẫu..."
			mic_status.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
			
			_practice_time = sample_melody_time
			_check_auto_advance()
		else:
			_process_real(delta)
	elif current_state == State.RHYTHM_GAME:
		_process_rhythm(delta, rect)

func _process_rhythm(delta, rect):
	if has_rhythm_completed:
		bgm_player.stop()
		return
	
	var amp = analyzer.current_amplitude_db
	var hz = analyzer.current_pitch
	var vol_ratio = clamp((amp + 60.0) / 60.0, 0.0, 1.0)
	
	var time_delta = delta
	
	var current_overlapping_note = null
	for note_data in active_falling_notes:
		var target_time = note_data["time"]
		var duration = note_data.get("duration", 1.0)
		var time_diff = target_time - rhythm_time
		if time_diff <= 0.0 and time_diff >= -duration:
			current_overlapping_note = note_data
			break
			
	if current_overlapping_note != null:
		var is_blowing = amp > -55.0 # Lenient volume threshold
		var is_correct = false
		
		if is_blowing and hz > 150.0:
			var target_hz_note = NOTE_FREQS.get(current_overlapping_note["note_name"], 0.0)
			if target_hz_note > 0.0:
				var tol = target_hz_note * 0.06 # 6% tolerance (~1 semitone)
				if abs(hz - target_hz_note) < tol or abs(hz / 2.0 - target_hz_note) < tol or abs(hz * 2.0 - target_hz_note) < tol:
					is_correct = true
					
		if is_correct:
			time_delta = delta
			current_overlapping_note["color"] = Color(0.2, 1.0, 0.2)
			mic_status.text = "Tuyệt! Giữ nốt..."
			mic_status.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
		else:
			time_delta = -delta * 1.5
			wrong_rhythm_duration += delta
			current_overlapping_note["color"] = Color(1.0, 0.2, 0.2)
			if is_blowing:
				mic_status.text = "Sai ngón! Thổi lại..."
			else:
				mic_status.text = ""
			mic_status.add_theme_color_override("font_color", Color(0.9, 0.3, 0.2))
	else:
		mic_status.text = "Chuẩn bị..."
		mic_status.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		
	rhythm_time += time_delta
	
	if active_node_id == "Node42" and bgm_player.stream != null:
		if time_delta <= 0:
			bgm_player.stream_paused = true
		else:
			bgm_player.stream_paused = false
	
	if current_overlapping_note != null:
		var target_time = current_overlapping_note["time"]
		if rhythm_time < target_time:
			rhythm_time = target_time
			
	var to_remove = []
	var hit_x = staff_display.hit_line_x if staff_display else 300.0
	var notes_for_staff = []
	
	for note_data in active_falling_notes:
		var target_time = note_data["time"]
		var time_diff = target_time - rhythm_time
		var duration = note_data.get("duration", 1.0)
		
		var note_x = hit_x + (time_diff * 300.0) # SCROLL_SPEED
		var tail_w = duration * 300.0
		
		if note_x < get_viewport_rect().size.x + 200 and note_x > -200 - tail_w:
			notes_for_staff.append({"note": note_data["note_name"], "x": note_x, "color": note_data.get("color", Color(0.96, 0.75, 0.25)), "tail": tail_w})
		
		if time_diff < -(duration + 0.1):
			to_remove.append(note_data)
			
	if staff_display: staff_display.set_notes(notes_for_staff)
			
	for r in to_remove:
		active_falling_notes.erase(r)
		
	if active_falling_notes.is_empty():
		has_rhythm_completed = true
		_complete_lesson()


func _generate_melody(target_note_key: String) -> Array:
	var seq = []
	var time = 1.0
	
	
	if target_note_key == "Node9":
		# Đô, Sol
		for i in range(2):
			seq.append({"note": "Đô", "time": time, "duration": 1.0}); time += 1.5
		for i in range(2):
			seq.append({"note": "Sol", "time": time, "duration": 1.0}); time += 1.5
	elif target_note_key == "Node10":
		# La
		for i in range(3):
			seq.append({"note": "La", "time": time, "duration": 0.8}); time += 1.2
	elif target_note_key == "Node11":
		# Câu 1: Đô Đô Sol Sol La La Sol
		seq.append({"note": "Đô", "time": time, "duration": 0.5}); time += 0.8
		seq.append({"note": "Đô", "time": time, "duration": 0.5}); time += 0.8
		seq.append({"note": "Sol", "time": time, "duration": 0.5}); time += 0.8
		seq.append({"note": "Sol", "time": time, "duration": 0.5}); time += 0.8
		seq.append({"note": "La", "time": time, "duration": 0.5}); time += 0.8
		seq.append({"note": "La", "time": time, "duration": 0.5}); time += 0.8
		seq.append({"note": "Sol", "time": time, "duration": 1.5}); time += 2.0
	elif target_note_key == "Node12":
		# Fa, Mi
		for i in range(2):
			seq.append({"note": "Fa", "time": time, "duration": 1.0}); time += 1.5
		for i in range(2):
			seq.append({"note": "Mi", "time": time, "duration": 1.0}); time += 1.5
	elif target_note_key == "Node13":
		# Rê
		for i in range(3):
			seq.append({"note": "Rê", "time": time, "duration": 0.8}); time += 1.2
	elif target_note_key == "Node14":
		# Câu 2: Fa Fa Mi Mi Rê Rê Đô
		seq.append({"note": "Fa", "time": time, "duration": 0.5}); time += 0.8
		seq.append({"note": "Fa", "time": time, "duration": 0.5}); time += 0.8
		seq.append({"note": "Mi", "time": time, "duration": 0.5}); time += 0.8
		seq.append({"note": "Mi", "time": time, "duration": 0.5}); time += 0.8
		seq.append({"note": "Rê", "time": time, "duration": 0.5}); time += 0.8
		seq.append({"note": "Rê", "time": time, "duration": 0.5}); time += 0.8
		seq.append({"note": "Đô", "time": time, "duration": 1.5}); time += 2.0
	elif target_note_key == "Node15":
		# Câu 3: Sol Sol Fa Fa Mi Mi Rê
		seq.append({"note": "Sol", "time": time, "duration": 0.5}); time += 0.8
		seq.append({"note": "Sol", "time": time, "duration": 0.5}); time += 0.8
		seq.append({"note": "Fa", "time": time, "duration": 0.5}); time += 0.8
		seq.append({"note": "Fa", "time": time, "duration": 0.5}); time += 0.8
		seq.append({"note": "Mi", "time": time, "duration": 0.5}); time += 0.8
		seq.append({"note": "Mi", "time": time, "duration": 0.5}); time += 0.8
		seq.append({"note": "Rê", "time": time, "duration": 1.5}); time += 2.0
	elif target_note_key == "Node16":
		# Ghép nửa bài (Câu 1 & Câu 2)
		var notes1 = ["Đô", "Đô", "Sol", "Sol", "La", "La", "Sol"]
		for n in notes1:
			var dur = 1.0 if n == "Sol" and notes1.find(n, 4) != -1 else 0.5
			seq.append({"note": n, "time": time, "duration": dur}); time += dur + 0.3
		var notes2 = ["Fa", "Fa", "Mi", "Mi", "Rê", "Rê", "Đô"]
		for n in notes2:
			var dur = 1.0 if n == "Đô" else 0.5
			seq.append({"note": n, "time": time, "duration": dur}); time += dur + 0.3
	elif target_note_key == "Node17":
		# Tập nửa bài nhạc cuối (Câu 3 x2)
		var notes3 = ["Sol", "Sol", "Fa", "Fa", "Mi", "Mi", "Rê"]
		for i in range(2):
			for n in notes3:
				var dur = 1.0 if n == "Rê" else 0.5
				seq.append({"note": n, "time": time, "duration": dur}); time += dur + 0.3
	elif target_note_key == "Node19":
		# Tập nốt Đô2
		for i in range(4):
			seq.append({"note": "Đô2", "time": time, "duration": 1.0}); time += 1.5
	elif target_note_key == "Node20":
		# Tập nốt Rê2
		for i in range(4):
			seq.append({"note": "Rê2", "time": time, "duration": 1.0}); time += 1.5
	elif target_note_key == "Node21":
		# Chuyển ngón Đô2-Rê2
		seq.append({"note": "Đô2", "time": time, "duration": 1.0}); time += 1.5
		seq.append({"note": "Rê2", "time": time, "duration": 1.0}); time += 1.5
		seq.append({"note": "Đô2", "time": time, "duration": 1.0}); time += 1.5
		seq.append({"note": "Rê2", "time": time, "duration": 1.5}); time += 2.0
	elif target_note_key == "Node22":
		# Tập nốt Sol
		for i in range(4):
			seq.append({"note": "Sol", "time": time, "duration": 1.0}); time += 1.5
	elif target_note_key == "Node23":
		# Mở đầu Trống Cơm (Câu 1)
		var notes = ["Sol", "Sol", "Đô2", "Đô2", "Rê2", "Đô2", "Sol"]
		for n in notes:
			var dur = 1.5 if n == "Sol" and notes.find(n, 4) != -1 else 0.5
			seq.append({"note": n, "time": time, "duration": dur}); time += dur + 0.3
	elif target_note_key == "Node24":
		# Tập nốt Fa
		for i in range(4):
			seq.append({"note": "Fa", "time": time, "duration": 1.0}); time += 1.5
	elif target_note_key == "Node25":
		# Khen ai khéo vỗ (Câu 2)
		var notes = ["Sol", "Fa", "Sol", "Đô2", "Sol", "Đô2", "Đô2", "Đô2", "Sol", "Sol", "Fa", "Sol"]
		for n in notes:
			var dur = 0.5
			seq.append({"note": n, "time": time, "duration": dur}); time += dur + 0.3
	elif target_note_key == "Node26":
		# Hoàn thành Đoạn 1
		var notes = [
			"Sol", "Sol", "Đô2", "Đô2", "Rê2", "Đô2", "Sol", 
			"Sol", "Fa", "Sol", "Đô2", "Sol", "Đô2", "Đô2", "Đô2", "Sol", "Sol", "Fa", "Sol", 
			"Đô2", "Đô2", "Sol", "Sol", "Fa", "Sol"
		]
		for n in notes:
			var dur = 0.5
			seq.append({"note": n, "time": time, "duration": dur}); time += dur + 0.3
	elif target_note_key == "Node27":
		# Tang tình con sít
		var notes = ["Đô2", "Đô2", "Rê2", "Đô2", "Rê2", "Mi2", "Đô2", "Đô2", "Rê2", "Đô2", "Rê2", "Mi2"]
		for n in notes:
			var dur = 0.5
			seq.append({"note": n, "time": time, "duration": dur}); time += dur + 0.3
	elif target_note_key == "Node28":
		# Thi Đấu Trống Cơm
		var notes = [
			"Sol", "Sol", "Đô2", "Đô2", "Rê2", "Đô2", "Sol", 
			"Sol", "Fa", "Sol", "Đô2", "Sol", "Đô2", "Đô2", "Đô2", "Sol", "Sol", "Fa", "Sol", 
			"Đô2", "Đô2", "Sol", "Sol", "Fa", "Sol", 
			"Đô2", "Đô2", "Rê2", "Đô2", "Rê2", "Mi2", 
			"Mi2", "Mi2", "Sol2", "Sol", "La", "Sol", "La", "Sol", "La", "Sol", "La", "Đô2", "Đô2", "Đô2", "La", "Sol", "La", "Đô2", "Sol"
		]
		for n in notes:
			var dur = 0.5
			seq.append({"note": n, "time": time, "duration": dur}); time += dur + 0.2
	elif target_note_key == "Node35":
		# Format: ["Tên nốt", thời_gian_ngân, khoảng_nghỉ_sau]
		var notes = [
			["Rê", 0.5, 0.1], ["Rê", 0.25, 0.1], ["Rê", 0.25, 0.1], ["Rê", 0.5, 0.1],
			["La", 0.5, 0.1], ["Sol", 1.25, 0.5],
			["Sol", 0.25, 0.1], ["Mi", 0.5, 0.1], ["Mi", 0.5, 0.1], ["Mi", 0.25, 0.1], ["Mi", 0.5, 0.1],
			["Fa", 0.5, 0.1], ["Rê", 1.5, 0.5]
		]
		for n in notes:
			seq.append({"note": n[0], "time": time, "duration": n[1]}); time += n[1] + n[2]
	elif target_note_key == "Node36":
		# Format: ["Tên nốt", thời_gian_ngân, khoảng_nghỉ_sau]
		var notes = [
			["Rê", 0.5, 0.1], ["Rê", 0.5, 0.1], ["Rê", 0.5, 0.1], ["Rê", 0.5, 0.15],
			["La", 1.0, 0.15], ["Sol", 2.0, 0.4],
			["Đô2", 0.5, 0.1], ["Đô2", 0.5, 0.1], ["Đô2", 0.5, 0.1], ["Đô2", 0.5, 0.15],
			["Rê2", 1.0, 0.15], ["La", 2.0, 0.5]
		]
		for n in notes:
			seq.append({"note": n[0], "time": time, "duration": n[1]}); time += n[1] + n[2]
	elif target_note_key == "Node37":
		# Format: ["Tên nốt", thời_gian_ngân, khoảng_nghỉ_sau]
		var notes = [
			["La", 0.5, 0.1], ["La", 0.5, 0.15],
			["Rê2", 1.0, 0.1], ["Đô2", 1.0, 0.1], ["Rê2", 0.5, 0.05], ["Rê2", 1.5, 0.2],
			["Đô2", 0.5, 0.1], ["Rê2", 0.5, 0.1],
			["Đô2", 1.0, 0.1], ["La", 1.0, 0.15], ["Sol", 2.0, 0.5]
		]
		for n in notes:
			seq.append({"note": n[0], "time": time, "duration": n[1]}); time += n[1] + n[2]
	elif target_note_key == "Node38":
		# Format: ["Tên nốt", thời_gian_ngân, khoảng_nghỉ_sau]
		var notes = [
			["Fa", 0.5, 0.1], ["Fa", 0.5, 0.1], ["Fa", 1.0, 0.1], ["Fa", 1.0, 0.15],
			["Đô2", 0.5, 0.1], ["La", 1.0, 0.1], ["Đô2", 1.0, 0.2],
			["Sol", 0.5, 0.1], ["Sol", 0.5, 0.15],
			["La", 1.0, 0.15], ["Rê", 2.0, 0.5]
		]
		for n in notes:
			seq.append({"note": n[0], "time": time, "duration": n[1]}); time += n[1] + n[2]
	elif target_note_key == "Node39":
		# Format: ["Tên nốt", thời_gian_ngân, khoảng_nghỉ_sau]
		var notes = [
			["La", 0.5, 0.1], ["La", 0.5, 0.1], ["La", 1.0, 0.1], ["La", 1.0, 0.15],
			["Fa2", 0.5, 0.1], ["Rê2", 1.5, 0.2],
			["Đô2", 0.5, 0.1], ["Rê2", 0.5, 0.1],
			["Đô2", 1.0, 0.1], ["La", 1.0, 0.15], ["Sol", 2.0, 0.5]
		]
		for n in notes:
			seq.append({"note": n[0], "time": time, "duration": n[1]}); time += n[1] + n[2]
	elif target_note_key == "Node40":
		# Format: ["Tên nốt", thời_gian_ngân, khoảng_nghỉ_sau]
		var notes = [
			["Fa", 0.5, 0.1], ["Fa", 0.5, 0.1], ["Fa", 1.0, 0.1], ["Fa", 1.0, 0.15],
			["Đô2", 0.5, 0.1], ["La", 1.0, 0.1], ["Đô2", 1.0, 0.2],
			["Sol", 0.5, 0.1], ["Sol", 0.5, 0.15],
			["La", 1.0, 0.15], ["Rê", 2.0, 0.5]
		]
		for n in notes:
			seq.append({"note": n[0], "time": time, "duration": n[1]}); time += n[1] + n[2]
	elif target_note_key == "Node41":
		# Format: ["Tên nốt", thời_gian_ngân, khoảng_nghỉ_sau]
		var notes = [
			["Rê", 0.5, 0.1], ["Fa", 0.5, 0.1], ["Sol", 1.0, 0.1], ["La", 1.0, 0.1],
			["Đô2", 0.5, 0.1], ["Sol", 1.0, 0.1], ["La", 2.0, 0.3],
			["Rê", 0.5, 0.1], ["Fa", 0.5, 0.1], ["La", 1.0, 0.1], ["Sol", 1.0, 0.1],
			["La", 0.5, 0.1], ["Fa", 1.0, 0.1], ["Rê", 2.0, 0.4],
			["Rê2", 0.5, 0.1], ["La", 0.5, 0.1], ["Fa2", 1.0, 0.1], ["Mi2", 1.0, 0.1],
			["Rê2", 0.5, 0.05], ["Đô2", 1.0, 0.1], ["Rê2", 1.0, 0.1], ["Sol", 0.5, 0.1], ["La", 2.0, 0.3],
			["Rê", 0.5, 0.1], ["Fa", 0.5, 0.1], ["La", 1.0, 0.1], ["Sol", 1.0, 0.1],
			["La", 0.5, 0.1], ["Fa", 1.0, 0.1], ["Rê", 2.0, 0.5]
		]
		for n in notes:
			seq.append({"note": n[0], "time": time, "duration": n[1]}); time += n[1] + n[2]
	elif target_note_key == "Node42":
		# Format: ["Tên nốt", thời_gian_ngân, khoảng_nghỉ_sau]
		var notes = [
	# Này bầu trời rộng lớn ơi
	["Rê", 0.5, 0], ["Rê", 0.25, 0], ["Rê", 0.25, 0], ["Rê", 0.5, 0],
	["La", 0.5, 0], ["Sol", 1.25, 0.4],

	# Có nghe chăng tiếng em gọi
	["Sol", 0.25, 0.1],
	["Mi", 0.25, 0.1], ["Mi", 0.5, 0.1],
	["Fa", 0.5, 0.1], ["Mi", 0.5, 0.1], ["Rê", 1, 0.4],

	# Mẹ giờ này ở chốn nao
	["Rê", 0.5, 0.1], ["Rê", 0.25, 0.1], ["Rê", 0.25, 0.1], ["Rê", 0.5, 0.1],
	["La", 0.5, 0.1], ["Sol", 1, 0.4],

	# Con đang mong nhớ về mẹ
	["Đô2", 0.5, 0.1], ["Đô2", 0.25, 0.1], ["Đô2", 0.25, 0.1],
	["Rê2", 0.75, 0.1], ["La", 0.25, 0.1], ["La", 1, 0.4],

	# Mẹ ở phương trời xa xôi
	["La", 0.5, 0.1], ["La", 0.25, 0.1],
	["Rê2", 0.5, 0.1], ["Đô2", 0.5, 0.1],
	["Rê2", 0.25, 0.1], ["Rê2", 1.0, 0.4],

	# Hay sao sáng trên bầu trời
	["Rê2", 0.25, 0.1], ["Đô2", 0.5, 0.1], ["Rê2", 0.5, 0.1],
	["Đô2", 0.5, 0.1], ["La", 0.5, 0.1],
	["Sol", 1.5, 0.4],

	# Mẹ dịu hiền về với con nhé, con nhớ mẹ
	["Fa", 0.5, 0.1], ["Fa", 0.25, 0.1],
	["Fa", 0.5, 0.1], ["Fa", 0.25, 0.1],
	["Đô2", 0.5, 0.1], ["La", 0.25, 0.1],
	["Đô2", 0.5, 0.1], ["Sol", 0.25, 0.1],
	["La", 0.25, 0.1], ["Rê", 1.5, 1.5],

	# ===== ĐIỆP KHÚC =====

	# Lời nguyện cầu từ chốn xa
	["La", 0.25, 0.1], ["La", 0.25, 0.1],
	["La", 0.25, 0.1], ["La", 0.25, 0.1],
	["Fa2", 0.25, 0.1], ["Rê2", 1.0, 0.2],

	# Mong ước con yên bình
	["Đô2", 0.5, 0.1], ["Rê2", 0.5, 0.1],
	["Đô2", 0.5, 0.1], ["La", 0.5, 0.1],
	["Sol", 1.5, 0.6],

	# Mẹ thật hiền tựa nắng mai ấp ôm con tháng ngày
	["Fa", 0.5, 0.1], ["Fa", 0.25, 0.1],
	["Fa", 0.25, 0.1], ["Fa", 0.25, 0.1],
	["Đô2", 0.5, 0.1], ["La", 0.5, 0.1],
	["Đô2", 0.5, 0.1],
	["Sol", 0.25, 0.1], ["Sol", 0.25, 0.1],
	["La", 0.5, 0.1], ["Rê", 1.5, 0.8],
	
	
	# Mẹ giờ này ở chốn rất xa
	["Rê", 0.5, 0.1], ["Rê", 0.25, 0.1], ["Rê", 0.25, 0.1], ["Rê", 0.5, 0.1],
	["La", 0.25, 0.1], ["La", 0.25, 0.1], ["Sol", 2, 0.6],
	
	
	# trông mơ con đã thấy mẹ
	["Fa", 0.5, 0.1], ["Mi", 0.5, 0.1], ["Mi", 0.5, 0.1], ["Mi", 0.25, 0.1],
	["Mi", 0.25, 0.1], ["Fa", 0.5, 0.1], ["Rê", 2, 0.6],
	
	# trông mơ con đã thấy mẹ
	["Rê", 0.5, 0.1], ["Rê", 0.25, 0.1], ["Rê", 0.25, 0.1], ["La", 0.25, 0.1],
	["La", 0.5, 0.1], ["Sol", 1, 0.1], ["Đô2", 0.5, 0.1], ["Đô2", 0.25, 0.1], 
	["Đô2", 0.75, 0.1], ["La", 0.25, 0.1], ["La", 0.5, 0.1],
]
		for n in notes:
			seq.append({"note": n[0], "time": time, "duration": n[1]}); time += n[1] + n[2]
	elif target_note_key == "Node18" or target_note_key == "sao_truc_level3_6":
		# Đàn Gà Con hoàn chỉnh (Khúc Nhạc Vui)
		var parts = [
			["Đô", "Đô", "Sol", "Sol", "La", "La", "Sol", 1.5],
			["Fa", "Fa", "Mi", "Mi", "Rê", "Rê", "Đô", 1.5],
			["Sol", "Sol", "Fa", "Fa", "Mi", "Mi", "Rê", 1.5],
			["Sol", "Sol", "Fa", "Fa", "Mi", "Mi", "Rê", 1.5],
			["Đô", "Đô", "Sol", "Sol", "La", "La", "Sol", 1.5],
			["Fa", "Fa", "Mi", "Mi", "Rê", "Rê", "Đô", 1.5]
		]
		for p in parts:
			for i in range(7):
				var n = p[i]
				var dur = p[7] if i == 6 else 0.5
				seq.append({"note": n, "time": time, "duration": dur}); time += dur + 0.2
			time += 0.5
	elif target_note_key.begins_with("sao_truc_level3_"):
		var parts = [
			["Đô", "Đô", "Sol", "Sol", "La", "La", "Sol", 1.5],
			["Fa", "Fa", "Mi", "Mi", "Rê", "Rê", "Đô", 1.5],
			["Sol", "Sol", "Fa", "Fa", "Mi", "Mi", "Rê", 1.5],
			["Sol", "Sol", "Fa", "Fa", "Mi", "Mi", "Rê", 1.5],
			["Đô", "Đô", "Sol", "Sol", "La", "La", "Sol", 1.5],
			["Fa", "Fa", "Mi", "Mi", "Rê", "Rê", "Đô", 1.5]
		]
		var idx = int(target_note_key.replace("sao_truc_level3_", "")) - 1
		if idx >= 0 and idx < parts.size():
			var p = parts[idx]
			for i in range(7):
				var n = p[i]
				var dur = p[7] if i == 6 else 0.5
				seq.append({"note": n, "time": time, "duration": dur})
				time += dur + 0.2
			time += 0.5

	elif target_note_key == "sao_truc_level5_7":
		var parts = [
			["Mi", 0.25, 0], ["Sol", 0.25, 0], ["La", 1.0, 0],
			["La", 0.25, 0], ["Đô2", 0.25, 0], ["Rê2", 1.0, 0],
			["Mi2", 0.25, 0], ["Sol2", 0.25, 0], ["Mi2", 1.5, 0.2],
			["Rê2", 0.25, 0], ["Đô2", 0.25, 0], ["La", 1.0, 0],
			["Mi2", 0.25, 0], ["Rê2", 0.25, 0], ["La", 1.0, 0],
			["Mi2", 0.25, 0], ["Rê2", 0.25, 0], ["Rê2", 1.5, 0.5],
			["Mi", 0.25, 0], ["Sol", 0.25, 0], ["La", 1.0, 0],
			["La", 0.25, 0], ["Đô2", 0.25, 0], ["Rê2", 1.0, 0],
			["Mi2", 0.25, 0], ["Sol2", 0.25, 0], ["Mi2", 1.5, 0.2],
			["Rê2", 0.25, 0], ["Đô2", 0.25, 0], ["La", 1.0, 0],
			["Mi2", 0.25, 0], ["Rê2", 0.25, 0], ["La", 1.0, 0],
			["Mi2", 0.25, 0], ["Rê2", 0.25, 0], ["Đô2", 1.5, 0.5],

			["Si", 0.25, 0], ["Đô2", 0.25, 0], ["Rê2", 1.0, 0],
			["Rê2", 0.25, 0], ["Rê2", 0.25, 0], ["Mi2", 0.25, 0], ["Rê2", 0.25, 0], ["Đô2", 0.25, 0], ["Rê2", 1.0, 0.2],
			["Si", 0.25, 0], ["Đô2", 0.25, 0], ["Rê2", 1.0, 0],
			["Rê2", 0.25, 0], ["Đô2", 0.25, 0], ["Rê2", 0.25, 0], ["Mi2", 0.25, 0], ["Rê2", 0.25, 0], ["La", 1.0, 0.2],
			["Si", 0.25, 0], ["Đô2", 0.25, 0], ["Rê2", 1.0, 0],
			["Rê2", 0.25, 0], ["Rê2", 0.25, 0], ["Mi2", 0.25, 0], ["Rê2", 0.25, 0], ["Đô2", 0.25, 0], ["Rê2", 1.0, 0.2],
			["Si", 0.25, 0], ["Đô2", 0.25, 0], ["Rê2", 1.0, 0],
			["Rê2", 0.25, 0], ["Đô2", 0.25, 0], ["Rê2", 0.25, 0], ["Mi2", 0.25, 0], ["Rê2", 0.25, 0], ["Rê2", 1.0, 0.5]
		]
		for p in parts:
			seq.append({"note": p[0], "time": time, "duration": p[1] * 2.0})
			time += p[1] * 2.0 + p[2] * 2.0
		time += 0.5
	elif target_note_key.begins_with("sao_truc_level5_"):
		var parts = [
			[
				["Mi", 0.25, 0], ["Sol", 0.25, 0], ["La", 1.0, 0],
				["La", 0.25, 0], ["Đô2", 0.25, 0], ["Rê2", 1.0, 0],
				["Mi2", 0.25, 0], ["Sol2", 0.25, 0], ["Mi2", 1.5, 0.2]
			],
			[
				["Rê2", 0.25, 0], ["Đô2", 0.25, 0], ["La", 1.0, 0],
				["Mi2", 0.25, 0], ["Rê2", 0.25, 0], ["La", 1.0, 0],
				["Mi2", 0.25, 0], ["Rê2", 0.25, 0], ["Rê2", 1.5, 0.5]
			],
			[
				["Mi", 0.25, 0], ["Sol", 0.25, 0], ["La", 1.0, 0],
				["La", 0.25, 0], ["Đô2", 0.25, 0], ["Rê2", 1.0, 0],
				["Mi2", 0.25, 0], ["Sol2", 0.25, 0], ["Mi2", 1.5, 0.2],
				["Rê2", 0.25, 0], ["Đô2", 0.25, 0], ["La", 1.0, 0],
				["Mi2", 0.25, 0], ["Rê2", 0.25, 0], ["La", 1.0, 0],
				["Mi2", 0.25, 0], ["Rê2", 0.25, 0], ["Đô2", 1.5, 0.5]
			],
			[
				["Si", 0.25, 0], ["Đô2", 0.25, 0], ["Rê2", 1.0, 0],
				["Rê2", 0.25, 0], ["Rê2", 0.25, 0], ["Mi2", 0.25, 0], ["Rê2", 0.25, 0], ["Đô2", 0.25, 0], ["Rê2", 1.0, 0.5]
			],
			[
				["Si", 0.25, 0], ["Đô2", 0.25, 0], ["Rê2", 1.0, 0],
				["Rê2", 0.25, 0], ["Đô2", 0.25, 0], ["Rê2", 0.25, 0], ["Mi2", 0.25, 0], ["Rê2", 0.25, 0], ["La", 1.0, 0.5]
			],
			[
				["Si", 0.25, 0], ["Đô2", 0.25, 0], ["Rê2", 1.0, 0],
				["Rê2", 0.25, 0], ["Rê2", 0.25, 0], ["Mi2", 0.25, 0], ["Rê2", 0.25, 0], ["Đô2", 0.25, 0], ["Rê2", 1.0, 0.2],
				["Si", 0.25, 0], ["Đô2", 0.25, 0], ["Rê2", 1.0, 0],
				["Rê2", 0.25, 0], ["Đô2", 0.25, 0], ["Rê2", 0.25, 0], ["Mi2", 0.25, 0], ["Rê2", 0.25, 0], ["Rê2", 1.0, 0.5]
			]
		]
		var idx = int(target_note_key.replace("sao_truc_level5_", "")) - 1
		if idx >= 0 and idx < parts.size():
			var p = parts[idx]
			for n in p:
				var dur = n[1] * 2.0
				var wait = n[2] * 2.0
				seq.append({"note": n[0], "time": time, "duration": dur})
				time += dur + wait
			time += 0.5
	elif target_note_key == "sao_truc_level4_5":
		var parts = [
			["La", 0.5, 0], ["Mi", 0.5, 0], ["Sol", 0.5, 0], ["La", 0.5, 0], ["Sol", 0.5, 0], ["Mi", 0.5, 0], ["Rê", 1.0, 0.5],
			["La", 0.5, 0], ["Mi", 0.5, 0], ["Rê", 0.5, 0], ["Mi", 0.5, 0], ["La", 0.5, 0], ["La", 0.25, 0], ["Sol", 0.25, 0], ["Mi", 0.5, 0], ["Sol", 1.0, 0.5],
			["Rê", 0.5, 0], ["Mi", 0.5, 0], ["La", 0.5, 0], ["Mi", 0.5, 0], ["Sol", 0.5, 0], ["Sol", 0.25, 0], ["Mi", 0.25, 0], ["Rê", 1.0, 0.5],
			["La", 0.5, 0], ["Mi", 0.5, 0], ["Sol", 0.5, 0], ["La", 0.5, 0], ["Sol", 0.5, 0], ["Mi", 0.5, 0], ["Sol", 1.0, 0.5]
		]
		for p in parts:
			seq.append({"note": p[0], "time": time, "duration": p[1]})
			time += p[1] + p[2]
		time += 0.5
	elif target_note_key.begins_with("sao_truc_level4_"):
		var parts = [
			[["La", 0.5, 0], ["Mi", 0.5, 0], ["Sol", 0.5, 0], ["La", 0.5, 0], ["Sol", 0.5, 0], ["Mi", 0.5, 0], ["Rê", 1.0, 0.5]],
			[["La", 0.5, 0], ["Mi", 0.5, 0], ["Rê", 0.5, 0], ["Mi", 0.5, 0], ["La", 0.5, 0], ["La", 0.25, 0], ["Sol", 0.25, 0], ["Mi", 0.5, 0], ["Sol", 1.0, 0.5]],
			[["Rê", 0.5, 0], ["Mi", 0.5, 0], ["La", 0.5, 0], ["Mi", 0.5, 0], ["Sol", 0.5, 0], ["Sol", 0.25, 0], ["Mi", 0.25, 0], ["Rê", 1.0, 0.5]],
			[["La", 0.5, 0], ["Mi", 0.5, 0], ["Sol", 0.5, 0], ["La", 0.5, 0], ["Sol", 0.5, 0], ["Mi", 0.5, 0], ["Sol", 1.0, 0.5]]
		]
		var idx = int(target_note_key.replace("sao_truc_level4_", "")) - 1
		if idx >= 0 and idx < parts.size():
			var p = parts[idx]
			for n in p:
				seq.append({"note": n[0], "time": time, "duration": n[1]})
				time += n[1] + n[2]
			time += 0.5
	else:
		var keys_order = ["Node2", "Node3", "Node4", "Node5", "Node6", "Node7", "Node8"]
		var target_idx = keys_order.find(target_note_key)
		if target_idx == -1:
			# Fallback for completely unknown nodes
			seq.append({"note": "Đô", "time": time, "duration": 1.0}); time += 1.5
			seq.append({"note": "Rê", "time": time, "duration": 1.0}); time += 1.5
			seq.append({"note": "Mi", "time": time, "duration": 1.0}); time += 1.5
			seq.append({"note": "Fa", "time": time, "duration": 1.0}); time += 1.5
			seq.append({"note": "Sol", "time": time, "duration": 1.0}); time += 1.5
		elif target_idx == 0:
			seq.append({"note": LESSON_NOTES["Node2"]["note"], "time": time, "duration": 1.5}); time += 2.0
			seq.append({"note": LESSON_NOTES["Node2"]["note"], "time": time, "duration": 1.0}); time += 1.5
			seq.append({"note": LESSON_NOTES["Node2"]["note"], "time": time, "duration": 2.0}); time += 2.5
		else:
			for i in range(target_idx + 1):
				var note_name = LESSON_NOTES[keys_order[i]]["note"]
				seq.append({"note": note_name, "time": time, "duration": 1.0})
				time += 1.5
				
			var prev_note = LESSON_NOTES[keys_order[target_idx - 1]]["note"]
			var new_note = LESSON_NOTES[keys_order[target_idx]]["note"]
			
			seq.append({"note": prev_note, "time": time, "duration": 0.5}); time += 1.0
			seq.append({"note": new_note,  "time": time, "duration": 0.5}); time += 1.0
			seq.append({"note": prev_note, "time": time, "duration": 0.5}); time += 1.0
			seq.append({"note": new_note,  "time": time, "duration": 2.0}); time += 2.5
			
	return seq

func _check_auto_advance():
	if _current_practice_idx >= _practice_sequence.size(): return
	var note_data = _practice_sequence[_current_practice_idx]
	var end_time = note_data["time"] + note_data.get("duration", 1.0)
	if _practice_time >= end_time:
		_advance_practice_note(true)

func _set_note_color(color: Color):
	_current_note_color = color

func _check_advance(delta: float, state: int):
	if _current_practice_idx >= _practice_sequence.size(): return
	var note_data = _practice_sequence[_current_practice_idx]
	var start_time = note_data["time"]
	var end_time = start_time + note_data.get("duration", 1.0)
	
	if _practice_time < start_time:
		_practice_time += delta
		mic_status.text = "Chuẩn bị..."
		mic_status.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		_set_note_color(Color(0.9, 0.7, 0.2)) # Vàng ban đầu
	else:
		if state == 1:
			_practice_time += delta
			_set_note_color(Color(0.2, 0.8, 0.2)) # Xanh lá
			var time_left = max(0, step_decimals(end_time - _practice_time))
			mic_status.text = "Thổi tốt! Giữ thêm " + str(time_left) + "s..."
			mic_status.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
			
			if _practice_time >= end_time:
				_advance_practice_note()
		elif state == -1:
			# Lùi thời gian về lại vị trí bắt đầu nốt (rewind)
			_practice_time = max(start_time, _practice_time - delta * 2.5)
			_set_note_color(Color(0.9, 0.2, 0.2)) # Đỏ
			mic_status.text = "Sai nốt rồi! Hãy sửa lại."
			mic_status.add_theme_color_override("font_color", Color(0.9, 0.3, 0.2))
		else:
			# state == 0 (idle)
			_practice_time = max(start_time, _practice_time - delta * 2.5)
			_set_note_color(Color(0.9, 0.7, 0.2)) # Vàng ban đầu
			mic_status.text = ""


func _advance_practice_note(is_auto: bool = false):
	_current_practice_idx += 1
	
	if _current_practice_idx >= _practice_sequence.size():
		if not is_auto:
			_hit_note()
	else:
		_update_practice_fingers()
		# The container will naturally continue scrolling down via _practice_time.
		# Fade out the finished note block
		if _practice_note_node:
			var prev_group = _practice_note_node.get_node_or_null("NoteGroup_" + str(_current_practice_idx - 1))
			if prev_group:
				var tween = create_tween()
				tween.tween_property(prev_group, "modulate:a", 0.0, 0.3)
				tween.tween_callback(prev_group.queue_free)

func _process_real(delta):
	var amp = analyzer.current_amplitude_db
	var hz = analyzer.current_pitch
	var vol_ratio = clamp((amp + 60.0) / 60.0, 0.0, 1.0)
	
	if _current_practice_idx >= _practice_sequence.size(): return
	
	if amp > -55.0 and hz > 0:
		var current_note_name = _practice_sequence[_current_practice_idx]["note"]
		if hz > 150.0:
			var target_hz = NOTE_FREQS.get(current_note_name, 0.0)
			if target_hz > 0.0:
				var tol = target_hz * 0.06 # 6% tolerance (~1 semitone)
				if abs(hz - target_hz) < tol or abs(hz / 2.0 - target_hz) < tol or abs(hz * 2.0 - target_hz) < tol:
					# Đúng nốt -> Tiến lên
					_check_advance(delta, 1)
				else:
					# Sai nốt -> Lùi lại
					_check_advance(delta, -1)
			else:
				_check_advance(delta, 0)
		else:
			_check_advance(delta, 0)
	else:
		_check_advance(delta, 0)

func _hit_note():
	if current_state == State.PRACTICE:
		current_state = State.MID_INTRO
		feedback_area.visible = false
		teacher_area.visible = true
		real_mode_btn.visible = false
		
		# Clear old layout to add new button
		for c in real_mode_btn.get_parent().get_children():
			c.queue_free()
			
		var start_rhythm_btn = Button.new()
		start_rhythm_btn.text = "  Bắt đầu đoạn nhạc  "
		start_rhythm_btn.add_theme_font_size_override("font_size", 24)
		start_rhythm_btn.add_theme_color_override("font_color", Color.BLACK)
		var sb = StyleBoxFlat.new()
		sb.bg_color = C_GOLD
		sb.corner_radius_top_left = 15; sb.corner_radius_top_right = 15
		sb.corner_radius_bottom_left = 15; sb.corner_radius_bottom_right = 15
		start_rhythm_btn.add_theme_stylebox_override("normal", sb)
		start_rhythm_btn.add_theme_stylebox_override("hover", sb)
		$TeacherArea/DialogBox/M/V/ModeButtons.add_child(start_rhythm_btn)
		start_rhythm_btn.pressed.connect(_start_rhythm_game)
		
		var txt = ""
		if LESSON_DIALOGUES.has(active_node_id):
			txt = LESSON_DIALOGUES[active_node_id]["mid"]
		else:
			txt = "Tốt lắm! Bạn đã biết cách thổi nốt " + active_note + ". Bây giờ chúng ta cùng thử thổi một đoạn nhạc kết hợp nhé!"
			
		speech_text.text = txt
		
		var ai = get_node_or_null("AIAudio")
		if ai and ai.has_method("speak_vietnamese"):
			var stream = null
			if active_node_id == "Node2":
				stream = load("res://audio/practiceSi.mp3")
			elif active_node_id in ["Node3", "Node4", "Node5", "Node6", "Node7", "Node8"]:
				stream = load("res://audio/practice" + active_node_id + ".mp3")
			if stream and is_instance_valid(ai.audio_player):
				ai.audio_player.stream = stream
				ai.audio_player.play()
			else:
				ai.speak_vietnamese(txt)

func _start_rhythm_game():
	var ai = get_node_or_null("AIAudio")
	if ai and ai.has_method("speak_vietnamese"):
		ai.audio_player.stop()
		
	melody_sequence = _generate_melody(active_node_id)
		
	current_state = State.RHYTHM_GAME
	teacher_area.visible = false
	feedback_area.visible = true
	analyzer.visible = true
	mic_status.text = "Chuẩn bị..."
	mic_status.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	
	if active_node_id == "Node42":
		var stream = load("res://image/gmtm.mp3")
		if stream:
			bgm_player.stream = stream
			bgm_player.play(21.0)
	
	rhythm_time = -2.0 # 2 seconds delay
	spawned_notes = 0
	active_falling_notes.clear()
	
	for note in melody_sequence:
		active_falling_notes.append({
			"time": note["time"],
			"duration": note.get("duration", 1.0),
			"note_name": note["note"],
			"color": Color(0.96, 0.75, 0.25),
			"hit": false,
			"failed": false
		})
		
	total_rhythm_duration = 0.0
	wrong_rhythm_duration = 0.0
	has_rhythm_completed = false
	for note in melody_sequence:
		total_rhythm_duration += note.get("duration", 1.0)


func _complete_lesson():
	current_state = State.COMPLETED
	feedback_area.visible = false
	analyzer.visible = false
	instruction_lbl.visible = false
	sub_instruction_lbl.visible = false
	
	if sample_btn: sample_btn.visible = false
	if record_btn: record_btn.visible = false
	if playback_btn: playback_btn.visible = false
	
	if get_node_or_null("StaffDisplay"):
		get_node("StaffDisplay").visible = false
		
	_show_completion_modal()

func _show_completion_modal():
	if retry_btn: retry_btn.visible = false
	if understood_btn: understood_btn.visible = false
	
	var acc = 1.0
	if total_rhythm_duration > 0.0:
		acc = clamp(1.0 - (wrong_rhythm_duration / (total_rhythm_duration * 3.0)), 0.0, 1.0)
		
	if complete_overlay:
		complete_overlay.visible = true
		if total_rhythm_duration > 0.0:
			var center = complete_overlay.get_child(0)
			if center:
				var modal = center.get_child(0)
				if modal:
					var margin = modal.get_child(0)
					if margin:
						var vbox = margin.get_child(0)
						if vbox:
							var pct_lbl = vbox.get_node_or_null("AccuracyLbl")
							if not pct_lbl:
								pct_lbl = Label.new()
								pct_lbl.name = "AccuracyLbl"
								pct_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
								pct_lbl.add_theme_font_size_override("font_size", 42)
								pct_lbl.add_theme_color_override("font_color", C_GOLD)
								vbox.add_child(pct_lbl)
							pct_lbl.text = "Độ chính xác: %d%%" % int(acc * 100)

func _build_complete_overlay():
	complete_overlay = ColorRect.new()
	complete_overlay.color = Color(0, 0, 0, 0.85) # Dark overlay
	complete_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	complete_overlay.visible = false
	
	var center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	complete_overlay.add_child(center_container)
	
	var modal_bg = TextureRect.new()
	modal_bg.texture = load("res://image/modal.png")
	modal_bg.custom_minimum_size = Vector2(1300, 850)
	modal_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	modal_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	center_container.add_child(modal_bg)
	
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_top", 180)
	margin.add_theme_constant_override("margin_bottom", 100)
	margin.add_theme_constant_override("margin_left", 180)
	margin.add_theme_constant_override("margin_right", 180)
	modal_bg.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "Tuyệt vời!"
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var sub = Label.new()
	sub.text = "Bạn đã hoàn thành bài học " + active_note
	sub.add_theme_font_size_override("font_size", 24)
	sub.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub)
	
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer1)
	
	var msg_panel = PanelContainer.new()
	var msg_sb = StyleBoxFlat.new()
	msg_sb.bg_color = Color(0.1, 0.2, 0.1, 0.6)
	msg_sb.border_width_left = 2; msg_sb.border_width_top = 2
	msg_sb.border_width_right = 2; msg_sb.border_width_bottom = 2
	msg_sb.border_color = Color(0.3, 0.4, 0.2, 1.0)
	msg_sb.corner_radius_top_left = 15; msg_sb.corner_radius_top_right = 15
	msg_sb.corner_radius_bottom_left = 15; msg_sb.corner_radius_bottom_right = 15
	msg_sb.content_margin_left = 30; msg_sb.content_margin_right = 30
	msg_sb.content_margin_top = 20; msg_sb.content_margin_bottom = 20
	msg_panel.add_theme_stylebox_override("panel", msg_sb)
	
	var msg_hbox = HBoxContainer.new()
	msg_hbox.add_theme_constant_override("separation", 20)
	msg_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var leaf_icon = Label.new()
	leaf_icon.text = "🌿"
	leaf_icon.add_theme_font_size_override("font_size", 40)
	leaf_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	msg_hbox.add_child(leaf_icon)
	
	var msg_vbox = VBoxContainer.new()
	msg_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	var msg_title = Label.new()
	msg_title.text = "Bạn đã hoàn thành xuất sắc bài học!"
	msg_title.add_theme_font_size_override("font_size", 20)
	msg_title.add_theme_color_override("font_color", C_GOLD)
	msg_vbox.add_child(msg_title)
	
	var msg_sub = Label.new()
	msg_sub.text = "Tiếp tục luyện tập để nâng cao kỹ năng nhé!"
	msg_sub.add_theme_font_size_override("font_size", 18)
	msg_sub.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	msg_vbox.add_child(msg_sub)
	
	msg_hbox.add_child(msg_vbox)
	msg_panel.add_child(msg_hbox)
	vbox.add_child(msg_panel)
	
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer2)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 30)
	
	var retry_sb = StyleBoxFlat.new()
	retry_sb.bg_color = Color(0.12, 0.12, 0.12, 1.0)
	retry_sb.border_width_left = 2; retry_sb.border_width_top = 2
	retry_sb.border_width_right = 2; retry_sb.border_width_bottom = 2
	retry_sb.border_color = Color(0.3, 0.4, 0.2, 1.0)
	retry_sb.corner_radius_top_left = 20; retry_sb.corner_radius_top_right = 20
	retry_sb.corner_radius_bottom_left = 20; retry_sb.corner_radius_bottom_right = 20
	retry_sb.content_margin_left = 40; retry_sb.content_margin_right = 40
	retry_sb.content_margin_top = 15; retry_sb.content_margin_bottom = 15
	
	retry_btn = Button.new()
	retry_btn.text = "↻ Chơi Lại"
	retry_btn.add_theme_stylebox_override("normal", retry_sb)
	retry_btn.add_theme_stylebox_override("hover", retry_sb)
	retry_btn.add_theme_font_size_override("font_size", 24)
	retry_btn.add_theme_color_override("font_color", C_GOLD)
	retry_btn.pressed.connect(_on_retry)
	retry_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(retry_btn)
	
	var finish_sb = StyleBoxFlat.new()
	finish_sb.bg_color = C_GOLD
	finish_sb.corner_radius_top_left = 20; finish_sb.corner_radius_top_right = 20
	finish_sb.corner_radius_bottom_left = 20; finish_sb.corner_radius_bottom_right = 20
	finish_sb.content_margin_left = 40; finish_sb.content_margin_right = 40
	finish_sb.content_margin_top = 15; finish_sb.content_margin_bottom = 15
	
	var finish_btn = Button.new()
	finish_btn.text = "Hoàn Thành →"
	finish_btn.add_theme_stylebox_override("normal", finish_sb)
	finish_btn.add_theme_stylebox_override("hover", finish_sb)
	finish_btn.add_theme_font_size_override("font_size", 24)
	finish_btn.add_theme_color_override("font_color", Color.BLACK)
	finish_btn.pressed.connect(_on_complete)
	finish_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(finish_btn)
	
	vbox.add_child(hbox)
	
	add_child(complete_overlay)


# RESTORED FUNCTIONS
func _build_flute():
	var body_tex = TextureRect.new()
	if ResourceLoader.exists("res://image/saotruc.png"):
		body_tex.texture = load("res://image/saotruc.png")
	body_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	body_tex.stretch_mode = TextureRect.STRETCH_SCALE
	flute_body.add_child(body_tex)
	
	for i in range(HOLES):
		var cover = Control.new()
		cover.custom_minimum_size = Vector2(100, 100)
		cover.size = Vector2(100, 100)
		cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var sb = StyleBoxFlat.new()
		sb.bg_color = C_GOLD
		sb.corner_radius_top_left = 38; sb.corner_radius_top_right = 38
		sb.corner_radius_bottom_left = 38; sb.corner_radius_bottom_right = 38
		var pnl = Panel.new()
		pnl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pnl.add_theme_stylebox_override("panel", sb)
		pnl.custom_minimum_size = Vector2(76, 76)
		pnl.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		pnl.visible = false
		cover.add_child(pnl)
		
		holes_overlay.add_child(cover)
		_holes.append(cover)


func _show_fingers(fingers: Array):
	for i in range(HOLES):
		if i < fingers.size():
			_holes[i].get_child(0).visible = fingers[i]

func _get_flute_draw_rect() -> Rect2:
	var img_aspect = 1369.0 / 131.0
	var avail_w = flute_body.size.x
	var avail_h = flute_body.size.y
	if avail_h == 0: return Rect2()
	var container_aspect = avail_w / avail_h
	
	var w = 0.0
	var h = 0.0
	if container_aspect > img_aspect:
		h = avail_h
		w = h * img_aspect
	else:
		w = avail_w
		h = w / img_aspect
		
	var x = (avail_w - w) / 2.0
	var y = avail_h - h + 20
	if y < 0: y = 0
	
	return Rect2(x, y, w, h)



func step_decimals(val: float) -> float:
	return round(val * 10.0) / 10.0




func _toggle_recording():
	if _is_recording:
		_recorded_stream = analyzer.stop_recording()
		_is_recording = false
		record_btn.text = "   Thu Âm   "
		record_btn.add_theme_color_override("font_color", Color.BLACK)
		if _recorded_stream:
			playback_btn.disabled = false
	else:
		if analyzer.start_recording():
			_is_recording = true
			record_btn.text = " Đang Thu... "
			record_btn.add_theme_color_override("font_color", Color(0.8, 0.1, 0.1))
			playback_btn.disabled = true

func _play_recording():
	if not _playback_player:
		_playback_player = AudioStreamPlayer.new()
		add_child(_playback_player)
	
	if _recorded_stream:
		# Optionally, set the playback stream mix rate to match the recording
		# (AudioEffectRecord automatically records at the bus mix rate)
		_playback_player.stream = _recorded_stream
		_playback_player.play()

func _on_back():
	get_tree().change_scene_to_file("res://scenes/LessonSaoTrucList.tscn")

func _on_complete():
	var inst = str(SecureDataManager.data.get("selected_instrument", "sao_truc"))
	SecureDataManager.complete_lesson(inst, active_node_id, 3)
	get_tree().change_scene_to_file("res://scenes/LessonSaoTrucList.tscn")

func _on_retry():
	get_tree().reload_current_scene()
