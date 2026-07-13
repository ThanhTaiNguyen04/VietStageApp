extends Control
class_name LessonSaoTruc

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
@onready var virtual_mode_btn = $TeacherArea/DialogBox/M/V/ModeButtons/VirtualModeBtn
@onready var real_mode_btn = $TeacherArea/DialogBox/M/V/ModeButtons/RealModeBtn

@onready var analyzer = $Analyzer
@onready var feedback_area = $FeedbackArea
@onready var mic_status = $FeedbackArea/MicStatus
@onready var volume_bar = $FeedbackArea/VolumeBar

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

var complete_overlay: ColorRect
var _holes : Array[Control] = []
var _lanes : Array[ColorRect] = []

var is_virtual_mode := false
var virtual_holes_state := [false, false, false, false, false, false]

var target_hz := 0.0
var time_correct := 0.0
var REQUIRED_HOLD_TIME := 1.0 # 1 second of correct note to pass

var rhythm_time := 0.0
var spawned_notes := 0
var active_falling_notes := []
var _practice_note_node
var _practice_sequence = []
var _current_practice_idx = 0
var _practice_time: float = 0.0
var total_rhythm_duration: float = 0.0
var correct_rhythm_duration: float = 0.0
var has_rhythm_completed: bool = false

const FALL_SPEED := 90.0 # Tốc độ rơi cực chậm để dễ chơi hơn (trước là 150.0)
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
	"Si": 987.77,
	"Đô2": 1046.50,
	"Rê2": 1174.66,
	"Mi2": 1318.51,
	"Sol2": 1567.98
}

func _ready():
	bgm_player = AudioStreamPlayer.new()
	bgm_player.volume_db = -5.0
	add_child(bgm_player)

	bgm_controls = HBoxContainer.new()
	bgm_controls.name = "BGMControls"
	bgm_controls.add_theme_constant_override("separation", 15)
	
	var lbl = Label.new()
	lbl.text = "Nhạc nền"
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
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
	bgm_controls.offset_right = -20
	bgm_controls.offset_top = 20
	bgm_controls.offset_bottom = 70
	
	if active_node_id == "Node42":
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
	virtual_mode_btn.pressed.connect(_start_virtual)
	real_mode_btn.pressed.connect(_start_real)
	
	var sb_btn = StyleBoxFlat.new()
	sb_btn.bg_color = C_GOLD
	sb_btn.corner_radius_top_left = 15; sb_btn.corner_radius_top_right = 15
	sb_btn.corner_radius_bottom_left = 15; sb_btn.corner_radius_bottom_right = 15
	complete_btn.add_theme_stylebox_override("normal", sb_btn)
	complete_btn.add_theme_stylebox_override("hover", sb_btn)
	virtual_mode_btn.add_theme_stylebox_override("normal", sb_btn)
	virtual_mode_btn.add_theme_stylebox_override("hover", sb_btn)
	real_mode_btn.add_theme_stylebox_override("normal", sb_btn)
	real_mode_btn.add_theme_stylebox_override("hover", sb_btn)
	
	var btn_vbox = VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 20)
	
	# Style cho nút Vàng (Nghe Mẫu, Thu Âm)
	var sb_gold = StyleBoxFlat.new()
	sb_gold.bg_color = Color(0.85, 0.65, 0.25, 1.0) # Gold
	sb_gold.border_width_left = 2; sb_gold.border_width_right = 2
	sb_gold.border_width_top = 2; sb_gold.border_width_bottom = 2
	sb_gold.border_color = Color(0.95, 0.85, 0.45, 1.0) # Lighter gold for border
	sb_gold.corner_radius_top_left = 20; sb_gold.corner_radius_top_right = 20
	sb_gold.corner_radius_bottom_left = 20; sb_gold.corner_radius_bottom_right = 20
	sb_gold.shadow_color = Color(0, 0, 0, 0.3)
	sb_gold.shadow_size = 4
	
	var sb_gold_hover = sb_gold.duplicate()
	sb_gold_hover.bg_color = Color(0.95, 0.75, 0.35, 1.0)
	
	# Style cho nút Tối (Nghe Lại)
	var sb_dark = StyleBoxFlat.new()
	sb_dark.bg_color = Color(0.2, 0.15, 0.1, 1.0) # Dark brown/black
	sb_dark.border_width_left = 2; sb_dark.border_width_right = 2
	sb_dark.border_width_top = 2; sb_dark.border_width_bottom = 2
	sb_dark.border_color = Color(0.5, 0.4, 0.2, 1.0) # Dark gold border
	sb_dark.corner_radius_top_left = 20; sb_dark.corner_radius_top_right = 20
	sb_dark.corner_radius_bottom_left = 20; sb_dark.corner_radius_bottom_right = 20
	sb_dark.shadow_color = Color(0, 0, 0, 0.3)
	sb_dark.shadow_size = 4
	
	var sb_dark_hover = sb_dark.duplicate()
	sb_dark_hover.bg_color = Color(0.3, 0.2, 0.15, 1.0)

	var icon_size = 32

	sample_btn = Button.new()
	sample_btn.text = " Nghe Mẫu"
	sample_btn.icon = load("res://assets/textures/lucide/music.svg")
	sample_btn.expand_icon = true
	sample_btn.custom_minimum_size = Vector2(250, 75)
	sample_btn.add_theme_font_size_override("font_size", 28)
	sample_btn.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1, 1.0))
	sample_btn.add_theme_color_override("font_hover_color", Color(0.1, 0.1, 0.1, 1.0))
	sample_btn.add_theme_color_override("icon_normal_color", Color(0.1, 0.1, 0.1, 1.0))
	sample_btn.add_theme_stylebox_override("normal", sb_gold)
	sample_btn.add_theme_stylebox_override("hover", sb_gold_hover)
	btn_vbox.add_child(sample_btn)
	
	record_btn = Button.new()
	record_btn.text = " Thu Âm"
	record_btn.icon = load("res://assets/textures/lucide/mic.svg")
	record_btn.expand_icon = true
	record_btn.custom_minimum_size = Vector2(250, 75)
	record_btn.add_theme_font_size_override("font_size", 28)
	record_btn.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1, 1.0))
	record_btn.add_theme_color_override("font_hover_color", Color(0.1, 0.1, 0.1, 1.0))
	record_btn.add_theme_color_override("icon_normal_color", Color(0.1, 0.1, 0.1, 1.0))
	record_btn.add_theme_stylebox_override("normal", sb_gold)
	record_btn.add_theme_stylebox_override("hover", sb_gold_hover)
	record_btn.visible = not is_virtual_mode
	btn_vbox.add_child(record_btn)
	
	playback_btn = Button.new()
	playback_btn.text = " Nghe Lại"
	playback_btn.icon = load("res://assets/textures/lucide/play.svg")
	playback_btn.expand_icon = true
	playback_btn.custom_minimum_size = Vector2(250, 75)
	playback_btn.add_theme_font_size_override("font_size", 28)
	playback_btn.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7, 1.0))
	playback_btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.9, 1.0))
	playback_btn.add_theme_color_override("icon_normal_color", Color(0.9, 0.85, 0.7, 1.0))
	playback_btn.add_theme_stylebox_override("normal", sb_dark)
	playback_btn.add_theme_stylebox_override("hover", sb_dark_hover)
	playback_btn.visible = not is_virtual_mode
	playback_btn.disabled = true
	btn_vbox.add_child(playback_btn)
	
	# For all buttons, adjust icon size and separation
	for b in [sample_btn, record_btn, playback_btn]:
		# Add a margin to the icon so it's not sticking to the left edge
		# Godot 4 doesn't have an easy "icon margin" without custom themes, 
		# but we can use alignment and separation
		b.alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.add_theme_constant_override("h_separation", 15)
		b.add_theme_constant_override("icon_max_width", 32)
	
	retry_btn = Button.new()
	retry_btn.text = "   Làm Lại   "
	retry_btn.custom_minimum_size = Vector2(250, 75)
	retry_btn.add_theme_font_size_override("font_size", 28)
	retry_btn.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1, 1.0))
	retry_btn.add_theme_stylebox_override("normal", sb_gold)
	retry_btn.add_theme_stylebox_override("hover", sb_gold_hover)
	retry_btn.visible = false
	btn_vbox.add_child(retry_btn)
	
	understood_btn = Button.new()
	understood_btn.text = "   Đã Hiểu   "
	understood_btn.custom_minimum_size = Vector2(250, 75)
	understood_btn.add_theme_font_size_override("font_size", 28)
	understood_btn.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1, 1.0))
	understood_btn.add_theme_stylebox_override("normal", sb_gold)
	understood_btn.add_theme_stylebox_override("hover", sb_gold_hover)
	understood_btn.visible = false
	btn_vbox.add_child(understood_btn)
	
	var btn_margin = MarginContainer.new()
	btn_margin.add_theme_constant_override("margin_top", 30)
	btn_margin.add_theme_constant_override("margin_right", 30)
	btn_margin.add_child(btn_vbox)
	add_child(btn_margin)
	btn_margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	
	sample_btn.pressed.connect(func(): _play_current_sample())
	record_btn.pressed.connect(func(): _toggle_recording())
	playback_btn.pressed.connect(func(): _play_recording())
	retry_btn.pressed.connect(func(): get_tree().reload_current_scene())
	understood_btn.pressed.connect(func(): _show_completion_modal())

	
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
	if LESSON_NOTES.has(active_node_id):
		var lesson_info = LESSON_NOTES[active_node_id]
		active_note = lesson_info["note"]
		instruction_lbl.text = "Học Nốt " + active_note
		sub_instruction_lbl.text = lesson_info["desc"]
		_show_fingers(lesson_info["fingers"])
		target_hz = NOTE_FREQS.get(active_note, 0.0)
		
		# Setup Intro Speech
		var txt = ""
		if LESSON_DIALOGUES.has(active_node_id):
			txt = LESSON_DIALOGUES[active_node_id]["intro"]
		else:
			txt = "Chào mừng bạn đến bài học! Hôm nay chúng ta sẽ làm quen với nốt " + active_note + ", để thổi nốt " + active_note + " bạn " + lesson_info["desc"].to_lower() + ". Nào cùng thử nhé!"
			
		speech_text.text = txt
		
		# Use AIAudioManager for high quality Google Translate TTS
		var ai_audio = load("res://scripts/AIAudioManager.gd").new()
		ai_audio.name = "AIAudio"
		add_child(ai_audio)
		ai_audio.speak_vietnamese(txt)
	
	# Initial UI State
	teacher_area.visible = true
	feedback_area.visible = false
	analyzer.visible = false
	current_state = State.INTRO

func _start_virtual():
	is_virtual_mode = true
	if record_btn: record_btn.visible = false
	if playback_btn: playback_btn.visible = false
	# Reset holes to invisible so user can press them
	for h in _holes:
		h.visible = false
	virtual_holes_state = [false, false, false, false, false, false]
	_start_practice()

func _start_real():
	is_virtual_mode = false
	if record_btn: record_btn.visible = true
	if playback_btn: playback_btn.visible = true
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
	analyzer.visible = true
	
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
	_spawn_all_practice_notes()
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
	if not is_virtual_mode:
		for i in range(HOLES):
			_holes[i].get_child(0).visible = req[i]
			_holes[i].get_child(0).modulate = Color(0.2, 0.8, 0.2, 0.6)
	else:
		for i in range(HOLES):
			_holes[i].get_child(0).visible = virtual_holes_state[i]
			_holes[i].get_child(0).modulate = Color(1, 1, 1, 1)

	mic_status.text = "Hãy bấm nốt " + current_note_name + " và thổi..."
	mic_status.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

func _spawn_all_practice_notes():
	var container = Control.new()
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.clip_contents = true
	_practice_note_node = container
	
	var rect = holes_overlay.get_global_rect()
	var target_y = rect.position.y + rect.size.y * HOLE_PROP_Y + 140
	
	container.position = Vector2.ZERO
	container.size = Vector2(get_viewport_rect().size.x, target_y)
	
	var scroll_node = Control.new()
	scroll_node.name = "ScrollNode"
	container.add_child(scroll_node)
	
	for note_idx in range(_practice_sequence.size()):
		var note_data = _practice_sequence[note_idx]
		var note_name = note_data["note"]
		var n_time = note_data["time"]
		var n_dur = note_data.get("duration", 1.0)
		
		var req = []
		for k in LESSON_NOTES.keys():
			if LESSON_NOTES[k]["note"] == note_name:
				req = LESSON_NOTES[k]["fingers"]
				break
				
		var group = Control.new()
		group.name = "NoteGroup_" + str(note_idx)
		
		var visual_length = n_dur * FALL_SPEED
		var base_y = target_y - (n_time * FALL_SPEED) - visual_length
		group.position = Vector2(0, base_y)
		scroll_node.add_child(group)
		
		var blow_bar = ColorRect.new()
		blow_bar.color = Color(1.0, 1.0, 1.0, 0.1)
		blow_bar.size = Vector2(rect.size.x, visual_length)
		blow_bar.position = Vector2(rect.position.x, 0)
		blow_bar.name = "BlowBar"
		group.add_child(blow_bar)
		
		for i in range(HOLES):
			if i < req.size() and req[i]:
				var block = ColorRect.new()
				block.color = Color(0.9, 0.7, 0.2)
				var hx = rect.position.x + rect.size.x * HOLE_PROPS_X[i]
				block.size = Vector2(60, visual_length)
				block.position = Vector2(hx - 30, 0)
				
				var sb = StyleBoxFlat.new()
				sb.bg_color = block.color
				sb.corner_radius_top_left = 30; sb.corner_radius_top_right = 30
				sb.corner_radius_bottom_left = 30; sb.corner_radius_bottom_right = 30
				
				var p = Panel.new()
				p.add_theme_stylebox_override("panel", sb)
				p.size = block.size
				p.position = block.position
				p.name = "Block_" + str(i)
				group.add_child(p)
				
		var lbl = Label.new()
		lbl.text = note_name
		lbl.add_theme_font_size_override("font_size", 24)
		lbl.add_theme_color_override("font_color", Color(1, 1, 1))
		lbl.position = Vector2(rect.position.x - 60, visual_length - 42)
		lbl.name = "Label"
		group.add_child(lbl)
		
	rhythm_area.add_child(container)

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
			bgm_player.play(21.5)

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
		_holes[i].position = Vector2(hx - 50, hy - 50)
		
		var target_y = rect.position.y + rect.size.y * HOLE_PROP_Y
		_lanes[i].position = Vector2(hx - 2, 0)
		_lanes[i].size = Vector2(4, target_y)
		
	if current_state == State.PRACTICE:
		if _practice_note_node:
			var scroll = _practice_note_node.get_node_or_null("ScrollNode")
			if scroll:
				scroll.position.y = _practice_time * FALL_SPEED
					
		if sample_active:
			mic_status.text = "Đang phát nhạc mẫu..."
			mic_status.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
			
			_practice_time = sample_melody_time
			_check_auto_advance()
		else:
			if is_virtual_mode:
				_process_virtual(delta)
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
	volume_bar.value = lerp(volume_bar.value, vol_ratio, 15.0 * delta)
	
	# Determine if we should advance time
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
		var is_blowing = amp > -25.0
		var is_correct = false
		
		if is_virtual_mode:
			if is_blowing:
				var req = current_overlapping_note["fingers"]
				var matched = true
				for i in range(HOLES):
					if virtual_holes_state[i] != req[i]:
						matched = false
						break
				is_correct = matched
		else:
			if is_blowing and hz > 350.0 and analyzer.current_tone_quality > 65.0:
				var target_hz_note = NOTE_FREQS.get(current_overlapping_note["note_name"], 0.0)
				if abs(hz - target_hz_note) < 25.0:
					is_correct = true
					
		if is_correct:
			time_delta = delta
			correct_rhythm_duration += delta
			current_overlapping_note["node"].modulate = Color(0.2, 1.0, 0.2)
			mic_status.text = "Tuyệt! Giữ nốt..."
			mic_status.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
		else:
			time_delta = -delta * 1.5 # Tua lại nhanh gấp rưỡi nếu sai
			current_overlapping_note["node"].modulate = Color(1.0, 0.2, 0.2)
			if is_blowing:
				mic_status.text = "Sai ngón! Thổi lại..."
			else:
				mic_status.text = "Đang chờ nốt " + current_overlapping_note["note_name"] + "..."
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

	
	# Clamp time when rewinding so note stops at holes
	if current_overlapping_note != null:
		var target_time = current_overlapping_note["time"]
		if rhythm_time < target_time:
			rhythm_time = target_time
			
	if spawned_notes < melody_sequence.size():
		var next_note = melody_sequence[spawned_notes]
		var target_y = rect.position.y + rect.size.y * HOLE_PROP_Y
		var spawn_time = next_note["time"] - (target_y / FALL_SPEED)
		
		if rhythm_time >= spawn_time:
			_spawn_falling_note(next_note, rect)
			spawned_notes += 1
			
	var to_remove = []
	for note_data in active_falling_notes:
		var node = note_data["node"]
		var target_time = note_data["time"]
		
		var time_diff = target_time - rhythm_time
		var target_y = rect.position.y + rect.size.y * HOLE_PROP_Y
		var current_y = target_y - (time_diff * FALL_SPEED)
		node.position.y = current_y
		
		var duration = note_data.get("duration", 1.0)
		if time_diff < -(duration + 0.1):
			to_remove.append(note_data)
			node.queue_free()
			
	for r in to_remove:
		active_falling_notes.erase(r)
		
	if spawned_notes >= melody_sequence.size() and active_falling_notes.is_empty():
		has_rhythm_completed = true
		_complete_lesson()

func _spawn_falling_note(note_data, rect):
	var n_name = note_data["note"]
	var target_time = note_data["time"]
	var duration = note_data.get("duration", 1.0)
	var length = duration * FALL_SPEED
	
	var fingers = []
	for k in LESSON_NOTES.keys():
		if LESSON_NOTES[k]["note"] == n_name:
			fingers = LESSON_NOTES[k]["fingers"]
			break
			
	if fingers.is_empty(): return
	
	var container = Control.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var blow_bar = ColorRect.new()
	blow_bar.color = Color(1.0, 1.0, 1.0, 0.1)
	blow_bar.size = Vector2(rect.size.x, length)
	blow_bar.position = Vector2(rect.position.x, -length)
	container.add_child(blow_bar)
	
	for i in range(HOLES):
		if i < fingers.size() and fingers[i]:
			var block = ColorRect.new()
			block.color = Color(0.3, 0.8, 0.9, 0.9)
			block.size = Vector2(60, length)
			var hx = rect.position.x + rect.size.x * HOLE_PROPS_X[i]
			block.position = Vector2(hx - 30, -length)
			
			var sb = StyleBoxFlat.new()
			sb.bg_color = block.color
			sb.corner_radius_top_left = 30; sb.corner_radius_top_right = 30
			sb.corner_radius_bottom_left = 30; sb.corner_radius_bottom_right = 30
			var pnl = Panel.new()
			pnl.add_theme_stylebox_override("panel", sb)
			pnl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			block.add_child(pnl)
			block.color = Color(1,1,1,0)
			
			container.add_child(block)
			
	var lbl = Label.new()
	lbl.text = n_name
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.position = Vector2(rect.position.x + rect.size.x / 2.0 - 20, -length - 40)
	container.add_child(lbl)
	
	rhythm_area.add_child(container)
	
	active_falling_notes.append({
		"node": container,
		"time": target_time,
		"duration": duration,
		"note_name": n_name,
		"fingers": fingers,
		"hit": false,
		"failed": false
	})

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
	["Rê", 0.5, 0.1], ["Rê", 0.25, 0.1], ["Rê", 0.25, 0.1], ["Rê", 0.5, 0.1],
	["La", 0.5, 0.1], ["Sol", 1.25, 0.4],

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
	elif target_note_key == "Node18":
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
	else:
		var keys_order = ["Node2", "Node3", "Node4", "Node5", "Node6", "Node7", "Node8"]
		var target_idx = keys_order.find(target_note_key)
		if target_idx == -1: target_idx = 0
		
		if target_idx == 0:
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
	if _practice_note_node:
		var scroll = _practice_note_node.get_node_or_null("ScrollNode")
		if scroll:
			var active_group = scroll.get_node_or_null("NoteGroup_" + str(_current_practice_idx))
			if active_group:
				for i in range(HOLES):
					var block = active_group.get_node_or_null("Block_" + str(i))
					if block:
						var sb = block.get_theme_stylebox("panel")
						if sb is StyleBoxFlat:
							sb.bg_color = color

func _check_advance(delta: float, is_correct: bool):
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
		if is_correct:
			_practice_time += delta
			_set_note_color(Color(0.2, 0.8, 0.2)) # Xanh lá
			var time_left = max(0, step_decimals(end_time - _practice_time))
			mic_status.text = "Thổi tốt! Giữ thêm " + str(time_left) + "s..."
			mic_status.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
			
			if _practice_time >= end_time:
				_advance_practice_note()
		else:
			# Lùi thời gian về lại vị trí bắt đầu nốt (rewind)
			_practice_time = max(start_time, _practice_time - delta * 2.5)
			_set_note_color(Color(0.9, 0.2, 0.2)) # Đỏ
			mic_status.text = "Sai nốt rồi! Hãy sửa lại."
			mic_status.add_theme_color_override("font_color", Color(0.9, 0.3, 0.2))

func _process_virtual(delta):
	var amp = analyzer.current_amplitude_db
	var vol_ratio = clamp((amp + 60.0) / 60.0, 0.0, 1.0)
	volume_bar.value = lerp(volume_bar.value, vol_ratio, 15.0 * delta)
	
	if _current_practice_idx >= _practice_sequence.size(): return
	
	var current_note_name = _practice_sequence[_current_practice_idx]["note"]
	var req = []
	for k in LESSON_NOTES.keys():
		if LESSON_NOTES[k]["note"] == current_note_name:
			req = LESSON_NOTES[k]["fingers"]
			break
			
	if req.size() < HOLES:
		req = [false, false, false, false, false, false]
			
	var matched = true
	var is_pressing_anything = false
	for i in range(HOLES):
		if virtual_holes_state[i]:
			is_pressing_anything = true
		if virtual_holes_state[i] != req[i]:
			matched = false
			
	if matched:
		_check_advance(delta, 1)
	elif is_pressing_anything:
		_check_advance(delta, -1)
	else:
		_check_advance(delta, 0)

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
	volume_bar.value = lerp(volume_bar.value, vol_ratio, 15.0 * delta)
	
	if _current_practice_idx >= _practice_sequence.size(): return
	
	if amp > -40.0 and hz > 0:
		var current_note_name = _practice_sequence[_current_practice_idx]["note"]
		var target_hz = NOTE_FREQS.get(current_note_name, 0.0)
			
		var matched = abs(hz - target_hz) < 30.0
		if matched:
			_check_advance(delta, 1)
		else:
			_check_advance(delta, -1)
	else:
		_check_advance(delta, 0)

func _hit_note():
	if current_state == State.PRACTICE:
		current_state = State.MID_INTRO
		feedback_area.visible = false
		analyzer.visible = false
		teacher_area.visible = true
		virtual_mode_btn.visible = false
		real_mode_btn.visible = false
		
		# Clear old layout to add new button
		for c in virtual_mode_btn.get_parent().get_children():
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
			bgm_player.play(21.5)
	
	rhythm_time = -2.0 # 2 seconds delay
	spawned_notes = 0
	active_falling_notes.clear()
	total_rhythm_duration = 0.0
	correct_rhythm_duration = 0.0
	has_rhythm_completed = false
	for note in melody_sequence:
		total_rhythm_duration += note.get("duration", 1.0)


func _complete_lesson():
	current_state = State.COMPLETED
	feedback_area.visible = false
	analyzer.visible = false
	
	for lane in _lanes:
		lane.visible = false
	
	instruction_lbl.visible = false
	sub_instruction_lbl.visible = false
	
	if sample_btn: sample_btn.visible = false
	if record_btn: record_btn.visible = false
	if playback_btn: playback_btn.visible = false
	
	if retry_btn: retry_btn.visible = true
	if understood_btn: understood_btn.visible = true

func _show_completion_modal():
	if retry_btn: retry_btn.visible = false
	if understood_btn: understood_btn.visible = false
	
	var acc = 0.0
	if total_rhythm_duration > 0.0:
		acc = correct_rhythm_duration / total_rhythm_duration
		
	if complete_overlay:
		complete_overlay.visible = true
		if total_rhythm_duration > 0.0:
			var vbox = complete_overlay.get_node_or_null("MarginContainer/VBoxContainer")
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
	
	var retry_btn = Button.new()
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
		sb.corner_radius_top_left = 18; sb.corner_radius_top_right = 18
		sb.corner_radius_bottom_left = 18; sb.corner_radius_bottom_right = 18
		var pnl = Panel.new()
		pnl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pnl.add_theme_stylebox_override("panel", sb)
		pnl.custom_minimum_size = Vector2(36, 36)
		pnl.set_anchors_preset(Control.PRESET_CENTER)
		pnl.visible = false
		cover.add_child(pnl)
		
		holes_overlay.add_child(cover)
		_holes.append(cover)
		
		var lane = ColorRect.new()
		lane.color = Color(1.0, 1.0, 1.0, 0.15)
		lane.visible = true
		rhythm_area.add_child(lane)
		_lanes.append(lane)

# Biáº¿n lÆ°u trá»_ cA¡c Ä`iá»ƒm cháº¡m trAªn mA n hA¬nh
var active_touches = {}

func _input(event):
	if (current_state != State.PRACTICE and current_state != State.RHYTHM_GAME) or not is_virtual_mode:
		return
		
	var is_touch_event = event is InputEventScreenTouch or event is InputEventScreenDrag
	var is_mouse_event = event is InputEventMouseButton or event is InputEventMouseMotion
	
	if is_touch_event:
		if event is InputEventScreenTouch:
			if event.pressed:
				active_touches[event.index] = event.position
			else:
				active_touches.erase(event.index)
		elif event is InputEventScreenDrag:
			active_touches[event.index] = event.position
	elif is_mouse_event:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			active_touches[-1] = event.position
		else:
			active_touches.erase(-1)
			
	# Update holes state based on all active touches
	for i in range(HOLES):
		var hole_center = _holes[i].global_position + Vector2(50, 50) # 50 is half of 100x100
		var is_covered = false
		for touch_pos in active_touches.values():
			if touch_pos.distance_to(hole_center) < 70.0: # BA¡n kA-nh siAªu rá»Tng 70px
				is_covered = true
				break
		virtual_holes_state[i] = is_covered
		_holes[i].get_child(0).visible = is_covered

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
	var y = avail_h - h - 50.0
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
	get_tree().change_scene_to_file("res://scenes/CourseDetailScreen.tscn")

func _on_complete():
	var inst = str(SecureDataManager.data.get("selected_instrument", "sao_truc"))
	SecureDataManager.complete_lesson(inst, active_node_id, 3)
	get_tree().change_scene_to_file("res://scenes/CourseDetailScreen.tscn")

func _on_retry():
	get_tree().reload_current_scene()
