extends Control
class_name LessonDanTranh

const C_GOLD = Color(0.961, 0.784, 0.259, 1.0)
const C_WOOD = Color(0.18, 0.13, 0.08, 1.0)
const C_JADE = Color("#173f2d")

enum State { INTRO, PRACTICE_SINGLE, PRACTICE, COMPLETED }
var current_state = State.INTRO

@onready var root = $Root
@onready var zither_board = $Root/CenterContainer/ZitherBoard/BoardM/ZitherFrame/ZitherM/ZitherStack/DanTranhBoard
@onready var string_overlay = $Root/CenterContainer/ZitherBoard/BoardM/ZitherFrame/ZitherM/ZitherStack/StringOverlay
@onready var instruction_lbl = $Root/TopMargin/InstructionLabel
@onready var sub_instruction_lbl = $Root/TopMargin/SubInstructionLabel
@onready var back_btn = $BackBtn
@onready var complete_btn = $CompleteBtn
@onready var teacher_area = $TeacherArea
@onready var speech_text = $TeacherArea/DialogBox/M/V/SpeechText
@onready var real_mode_btn = $TeacherArea/DialogBox/M/V/ModeButtons/RealModeBtn
@onready var analyzer = $Analyzer
@onready var feedback_area = $FeedbackArea
var ai_audio = null

var staff_display: Control
var current_lesson_id: String
var lesson_data: Dictionary
var lesson_sheet: Array[String] = []

var practice_idx: int = 0
var intro_step: int = 0
var time_correct: float = 0.0
var REQUIRED_HOLD_TIME: float = 0.5
var active_falling_notes = []
var practice_time: float = 0.0

var single_practice_idx: int = 0
var unique_practice_notes: Array[String] = []

const STRINGS = 17

const LESSON_DIALOGUES = {
	"dan_tranh_level_1_bai_1_practice": [
		{"action": "speak", "text": "Chào bạn! Đây là bài học Đàn Tranh đầu tiên. Hôm nay chúng ta sẽ làm quen với các nốt cơ bản.", "highlight": -1},
		{"action": "speak", "text": "Đầu tiên là nốt Sol1. Hãy nhìn lên khuông nhạc và dây tương ứng.", "highlight": 0},
		{"action": "speak", "text": "Tiếp theo là nốt La1.", "highlight": 1},
		{"action": "speak", "text": "Rất tốt. Bây giờ hãy gảy nốt Đô2.", "highlight": 2},
		{"action": "speak", "text": "Tiếp tục với nốt Rê2.", "highlight": 3},
		{"action": "speak", "text": "Và cuối cùng là nốt Mi2.", "highlight": 4},
		{"action": "speak", "text": "Tuyệt vời! Bây giờ chúng ta sẽ tập gảy thử từng nốt trước khi vào bản nhạc nhé.", "highlight": -1}
	],
	"dan_tranh_level_1_bai_2_practice": [
		{"action": "speak", "text": "Chào mừng bạn đến với bài gảy ngón cơ bản. Hôm nay chúng ta sẽ dùng ngón cái và ngón trỏ để gảy.", "highlight": -1},
		{"action": "speak", "text": "Chúng ta sẽ tập luân phiên trên 3 nốt: Đô2, Rê2 và Mi2.", "highlight": 2},
		{"action": "speak", "text": "Hãy tập trung giữ form bàn tay tròn đều như đang úp quả bóng nhé.", "highlight": -1}
	],
	"dan_tranh_level_1_bai_3_practice": [
		{"action": "speak", "text": "Hôm nay chúng ta sẽ đệm câu nhạc đầu tiên của bài Sứ Thanh Hoa.", "highlight": -1},
		{"action": "speak", "text": "Giai điệu này chuyển đổi nhịp nhàng từ quãng thấp lên quãng trung.", "highlight": -1},
		{"action": "speak", "text": "Hãy lắng nghe nhịp điệu và gảy thật thoải mái.", "highlight": -1}
	],
	"dan_tranh_level_2_bai_4_practice": [
		{"action": "speak", "text": "Chào bạn! Chúng ta cùng bước sang cấp độ 2 với bài Vào rừng hoa.", "highlight": -1},
		{"action": "speak", "text": "Ở đoạn 1 này, chúng ta sẽ tập trung vào quãng âm trung với các nốt Mi2, Sol2, La2 và Đô3.", "highlight": 4},
		{"action": "speak", "text": "Hãy chú ý sự liền mạch giữa các nốt khi trôi qua nhé.", "highlight": -1}
	],
	"dan_tranh_level_2_bai_5_practice": [
		{"action": "speak", "text": "Hôm nay chúng ta sẽ ghép hoàn chỉnh bài Vào Rừng Hoa.", "highlight": -1},
		{"action": "speak", "text": "Bài nhạc này đòi hỏi bạn di chuyển tay linh hoạt từ nốt trầm Sol1 lên quãng cao hơn.", "highlight": 0},
		{"action": "speak", "text": "Hãy hít thở sâu và gảy thật uyển chuyển nào.", "highlight": -1}
	],
	"dan_tranh_level_2_bai_6_practice": [
		{"action": "speak", "text": "Chúng ta sẽ khám phá điệu Xàng Xê của Nam Bộ.", "highlight": -1},
		{"action": "speak", "text": "Điệu nhạc này mang sắc thái khoan thai, mộc mạc và đầy chất thơ.", "highlight": -1},
		{"action": "speak", "text": "Hãy cùng cảm nhận giai điệu ngũ cung vô cùng độc đáo này.", "highlight": -1}
	],
	"dan_tranh_level_3_bai_7_practice": [
		{"action": "speak", "text": "Chào mừng đến với thử thách tốc độ cao với bài nhạc Mã Vũ.", "highlight": -1},
		{"action": "speak", "text": "Bạn cần gảy nốt nhanh và dứt khoát hơn để ra đúng chất hành khúc.", "highlight": -1},
		{"action": "speak", "text": "Hãy giữ khung tay thật vững chãi nhé.", "highlight": -1}
	],
	"dan_tranh_level_3_bai_8_practice": [
		{"action": "speak", "text": "Hôm nay chúng ta sẽ tập bài dân ca Quan họ Bắc Ninh nổi tiếng: Lý Cây Đa.", "highlight": -1},
		{"action": "speak", "text": "Giai điệu cần sự lả lướt, duyên dáng giống như giọng hát của các liền anh liền chị.", "highlight": -1},
		{"action": "speak", "text": "Hãy chú ý giữ đúng nhịp của bài.", "highlight": -1}
	],
	"dan_tranh_level_4_bai_9_practice": [
		{"action": "speak", "text": "Chào bạn! Hôm nay chúng ta sẽ làm quen với kỹ thuật Rung đặc trưng của Đàn Tranh.", "highlight": -1},
		{"action": "speak", "text": "Sau khi gảy nốt bằng tay phải, hãy dùng tay trái nhấn nhẹ liên tục vào phần dây bên trái nhạn đàn.", "highlight": -1},
		{"action": "speak", "text": "Tiếng đàn ngân lên rung động chính là linh hồn của nhạc cụ này.", "highlight": -1}
	],
	"dan_tranh_level_4_bai_10_practice": [
		{"action": "speak", "text": "Chúng ta sẽ tập hòa tấu bài dân ca Nam Bộ: Lý Cây Bông.", "highlight": -1},
		{"action": "speak", "text": "Hãy lắng nghe nhạc nền thật kỹ để gảy các nốt hòa quyện vào nhịp trống.", "highlight": -1},
		{"action": "speak", "text": "Bắt đầu gảy thử nào.", "highlight": -1}
	],
	"dan_tranh_level_5_bai_11_practice": [
		{"action": "speak", "text": "Chào mừng bạn tới cấp độ Master. Chúng ta sẽ chinh phục bài nhạc hiện đại Sứ Thanh Hoa hoàn chỉnh.", "highlight": -1},
		{"action": "speak", "text": "Giai điệu bài này chuyển quãng rất rộng và nhanh.", "highlight": -1},
		{"action": "speak", "text": "Hãy tập trung cao độ và phô diễn hết kỹ thuật nhé.", "highlight": -1}
	],
	"dan_tranh_level_5_bai_12_practice": [
		{"action": "speak", "text": "Chào mừng bạn đến với Thử thách sinh tồn cuối cùng của khóa học Đàn Tranh!", "highlight": -1},
		{"action": "speak", "text": "Bạn sẽ cần gảy lần lượt toàn bộ 17 dây đàn từ cực trầm đến cực cao.", "highlight": -1},
		{"action": "speak", "text": "Hãy chứng minh bạn đã hoàn toàn làm chủ cây Đàn Tranh này nào!", "highlight": -1}
	]
}

const NOTE_TO_STRING = {
	"Sol2": 0, "La2": 1, "Đô2": 2, "Rê2": 3, "Mi2": 4,
	"Sol": 5, "La": 6, "Đô": 7, "Rê": 8, "Mi": 9,
	"Sol3": 10, "La3": 11, "Đô3": 12, "Rê3": 13, "Mi3": 14,
	"Sol4": 15, "La4": 16
}

const NOTE_FREQS = {
	"Sol2": 196.00, "La2": 220.00, "Đô2": 261.63, "Rê2": 293.66, "Mi2": 329.63,
	"Sol": 392.00, "La": 440.00, "Đô": 523.25, "Rê": 587.33, "Mi": 659.25,
	"Sol3": 783.99, "La3": 880.00, "Đô3": 1046.50, "Rê3": 1174.66, "Mi3": 1318.51,
	"Sol4": 1567.98, "La4": 1760.00
}

func _ready():
	current_lesson_id = SecureDataManager.active_lesson_id
	if not current_lesson_id or current_lesson_id == "":
		current_lesson_id = "dan_tranh_level_1_bai_1_practice"
		
	lesson_sheet.assign(PracticeRoom.current_song_sheet)
	if lesson_sheet.is_empty():
		lesson_sheet = ["Sol2", "La2", "Đô2", "Rê2", "Mi2"] # fallback
	
	staff_display = load("res://scripts/StaffDisplay.gd").new()
	staff_display.name = "StaffDisplay"
	
	# Calculate dynamic line spacing based on the note range of this lesson to make it as large and beautiful as possible
	var min_pos = 99.0
	var max_pos = -99.0
	for note in lesson_sheet:
		var pos = staff_display.NOTE_POSITIONS.get("ZT_" + note, staff_display.NOTE_POSITIONS.get(note, 0.0))
		if pos < min_pos: min_pos = pos
		if pos > max_pos: max_pos = pos
	
	var optimal_spacing = 80.0
	if max_pos > min_pos:
		var span = max_pos - min_pos
		if span > 4.0:
			optimal_spacing = clampf(480.0 / (span + 2.0), 35.0, 80.0)
	staff_display.line_spacing = optimal_spacing
	
	ai_audio = load("res://scripts/AIAudioManager.gd").new()
	ai_audio.name = "AIAudio"
	add_child(ai_audio)
	string_overlay.add_child(staff_display)
	staff_display.anchor_right = 1.0
	staff_display.anchor_bottom = 1.0
	staff_display.offset_left = 0
	staff_display.offset_top = 0
	staff_display.offset_right = 0
	staff_display.offset_bottom = 0
	
	var string_notes: Array[String] = ["Sol2", "La2", "Đô2", "Rê2", "Mi2", "Sol", "La", "Đô", "Rê", "Mi", "Sol3", "La3", "Đô3", "Rê3", "Mi3", "Sol4", "La4"]
	var string_freqs: Array[float] = [196.00, 220.00, 261.63, 293.66, 329.63, 392.00, 440.00, 523.25, 587.33, 659.25, 783.99, 880.00, 1046.50, 1174.66, 1318.51, 1567.98, 1760.00]
	var string_streams: Array = []
	string_streams.resize(17)
	string_streams.fill(null)
	zither_board.init(string_notes, string_streams, string_freqs)
	zither_board.visible = false
	
	# Hide redundant mode selection buttons (e.g. "Dùng Sáo Thật")
	var mode_buttons = teacher_area.get_node_or_null("DialogBox/M/V/ModeButtons")
	if mode_buttons:
		mode_buttons.visible = false
	
	back_btn.pressed.connect(_on_back)
	complete_btn.pressed.connect(_on_complete)
	
	_start_intro()

func _process(delta):
	if current_state == State.PRACTICE_SINGLE:
		_process_practice_single(delta)
	elif current_state == State.PRACTICE:
		_process_practice(delta)

func _start_intro():
	current_state = State.INTRO
	intro_step = 0
	teacher_area.visible = true
	feedback_area.visible = false
	complete_btn.visible = false
	_play_next_intro_step()

func _play_next_intro_step():
	var dialogues = LESSON_DIALOGUES.get(current_lesson_id, [])
	if intro_step >= dialogues.size():
		_start_practice_single()
		return
		
	var step_data = dialogues[intro_step]
	if step_data["action"] == "speak":
		speech_text.text = step_data["text"]
		if ai_audio:
			ai_audio.speak_vietnamese(step_data["text"])
			
		# Highlight string
		zither_board.call("clear_lesson_markers")
		if step_data.get("highlight", -1) >= 0:
			zither_board.call("set_lesson_marker", step_data["highlight"], "Gảy", 1)
			
		# Wait for speech to finish then go to next step
		var wait_time = max(1.5, step_data["text"].length() * 0.1)
		get_tree().create_timer(wait_time).timeout.connect(_play_next_intro_step)
	intro_step += 1

func _start_practice_single():
	current_state = State.PRACTICE_SINGLE
	teacher_area.visible = true
	feedback_area.visible = true
	instruction_lbl.text = "HỌC TỪNG NỐT"
	sub_instruction_lbl.text = "Hãy gảy nốt theo hướng dẫn bằng đàn thật"
	
	unique_practice_notes.clear()
	for note in lesson_sheet:
		if not unique_practice_notes.has(note):
			unique_practice_notes.append(note)
			
	single_practice_idx = 0
	_schedule_next_single_note()

func _schedule_next_single_note():
	if single_practice_idx >= unique_practice_notes.size():
		if ai_audio: ai_audio.speak_vietnamese("Rất tuyệt! Bây giờ chúng ta sẽ luyện tập với bản nhạc.")
		current_state = State.INTRO
		get_tree().create_timer(3.0).timeout.connect(_start_practice)
		return
		
	var note_name = unique_practice_notes[single_practice_idx]
	var string_idx = NOTE_TO_STRING.get(note_name, 0)
	
	var text = "Hãy gảy dây thứ %d, nốt %s." % [string_idx + 1, note_name]
	speech_text.text = text
	if ai_audio:
		ai_audio.speak_vietnamese(text)
		
	staff_display.set_notes([{"note": "ZT_" + note_name, "x": staff_display.hit_line_x, "color": C_JADE}])

func _process_practice_single(delta):
	if single_practice_idx >= unique_practice_notes.size(): return
	
	var note_name = unique_practice_notes[single_practice_idx]
	var target_hz = NOTE_FREQS.get(note_name, 0.0)
	
	if _check_mic_pitch(target_hz):
		staff_display.set_notes([{"note": "ZT_" + note_name, "x": staff_display.hit_line_x, "color": Color(0.2, 0.8, 0.2)}])
		if ai_audio:
			ai_audio.speak_vietnamese("Tốt lắm!")
			
		single_practice_idx += 1
		current_state = State.INTRO
		get_tree().create_timer(2.0).timeout.connect(func():
			current_state = State.PRACTICE_SINGLE
			_schedule_next_single_note()
		)


func _start_practice():
	current_state = State.PRACTICE
	teacher_area.visible = false
	feedback_area.visible = true
	instruction_lbl.text = "THỰC HÀNH TƯƠNG TÁC"
	sub_instruction_lbl.text = "Gảy các nốt tương ứng trên màn hình hoặc dùng đàn thật"
	practice_idx = 0
	practice_time = 0.0
	active_falling_notes.clear()
	
	zither_board.call("clear_lesson_markers")
	if analyzer:
		pass
		
	_schedule_next_note()

func _schedule_next_note():
	if practice_idx >= lesson_sheet.size():
		get_tree().create_timer(2.0).timeout.connect(_finish_practice)
		return
		
	var note_name = lesson_sheet[practice_idx]
	var string_idx = NOTE_TO_STRING.get(note_name, 0)
	
	# Add to staff display
	active_falling_notes.append({
		"note": "ZT_" + note_name,
		"x": staff_display.size.x + 100,
		"color": C_JADE,
		"target_string": string_idx
	})
	
	zither_board.call("set_target", string_idx)
	practice_idx += 1

func _process_practice(delta):
	practice_time += delta
	var hit_x = staff_display.hit_line_x
	var scroll_speed = 200.0
	
	var to_remove = []
	for note in active_falling_notes:
		note["x"] -= scroll_speed * delta
		
		var clean_note = note["note"].replace("ZT_", "")
		
		if abs(note["x"] - hit_x) < 30.0:
			# Highlight string on zither board when note hits the line
			var s_idx = note["target_string"]
			zither_board.call("set_lesson_marker", s_idx, clean_note, 2)
			
			# Check microphone for this string's frequency
			var target_hz = NOTE_FREQS.get(clean_note, 0.0)
			if _check_mic_pitch(target_hz):
				note["color"] = Color(0.2, 0.8, 0.2)
				zither_board.call("pluck", s_idx)
			
		if note["x"] < -50:
			to_remove.append(note)
			
	for r in to_remove:
		active_falling_notes.erase(r)
		zither_board.call("clear_lesson_markers")
		_schedule_next_note()
		
	staff_display.set_notes(active_falling_notes)

func _check_mic_pitch(target_hz: float) -> bool:
	if not analyzer: return false
	var pitch = analyzer.current_pitch
	var db = analyzer.current_amplitude_db
	if db > -40.0 and pitch > 50.0:
		var diff = abs(pitch - target_hz)
		if diff < 15.0:
			return true
	return false

func _finish_practice():
	current_state = State.COMPLETED
	if analyzer:
		pass
	complete_btn.visible = true
	instruction_lbl.text = "HOÀN THÀNH BÀI HỌC"
	sub_instruction_lbl.text = "Bạn đã làm rất tốt!"
	
	var completed = SecureDataManager.data.completed_lessons.get("dan_tranh", [])
	if not completed.has(current_lesson_id):
		completed.append(current_lesson_id)
		SecureDataManager.data.completed_lessons["dan_tranh"] = completed
		SecureDataManager.save_data()

func _on_back():
	if analyzer:
		pass
	get_tree().change_scene_to_file("res://scenes/LessonDanTranhList.tscn")

func _on_complete():
	_on_back()
