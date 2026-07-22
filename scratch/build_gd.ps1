import sys

gd_content = '''extends Control
class_name LessonDanTranh

const C_GOLD = Color(0.961, 0.784, 0.259, 1.0)
const C_WOOD = Color(0.18, 0.13, 0.08, 1.0)
const C_JADE = Color("#173f2d")

enum State { INTRO, PRACTICE, COMPLETED }
var current_state = State.INTRO

@onready var root = 
@onready var zither_board = /CenterContainer/ZitherBoard/BoardM/ZitherFrame/ZitherM/ZitherStack/DanTranhBoard
@onready var string_overlay = /CenterContainer/ZitherBoard/BoardM/ZitherFrame/ZitherM/ZitherStack/StringOverlay
@onready var instruction_lbl = /TopMargin/InstructionLabel
@onready var sub_instruction_lbl = /TopMargin/SubInstructionLabel
@onready var back_btn = 
@onready var complete_btn = 
@onready var teacher_area = 
@onready var speech_text = /DialogBox/M/V/SpeechText
@onready var real_mode_btn = /DialogBox/M/V/ModeButtons/RealModeBtn
@onready var analyzer = 

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

const STRINGS = 17

const LESSON_DIALOGUES = {
	"dan_tranh_level_1_bai_1_practice": [
		{"action": "speak", "text": "Chào bạn! Đây là bài học Đàn Tranh đầu tiên. Hôm nay chúng ta sẽ làm quen với các nốt cơ bản.", "highlight": -1},
		{"action": "speak", "text": "Đầu tiên là nốt Sol1. Hãy nhìn lên khuông nhạc và dây được đánh dấu.", "highlight": 0},
		{"action": "speak", "text": "Tiếp theo là nốt La1.", "highlight": 1},
		{"action": "speak", "text": "Rất tốt. Bây giờ hãy gảy nốt Đô2.", "highlight": 2},
		{"action": "speak", "text": "Tiếp tục với nốt Rê2.", "highlight": 3},
		{"action": "speak", "text": "Và cuối cùng là nốt Mi2.", "highlight": 4},
		{"action": "speak", "text": "Tuyệt vời! Bây giờ chúng ta sẽ chuyển sang phần thực hành với sheet nhạc nhé.", "highlight": -1}
	]
}

const NOTE_TO_STRING = {
	"Sol1": 0, "La1": 1, "Đô2": 2, "Rê2": 3, "Mi2": 4,
	"Sol2": 5, "La2": 6, "Đô3": 7, "Rê3": 8, "Mi3": 9,
	"Sol3": 10, "La3": 11, "Đô4": 12, "Rê4": 13, "Mi4": 14,
	"Sol4": 15, "La4": 16
}

const NOTE_FREQS = {
	"Sol1": 196.00, "La1": 220.00, "Đô2": 261.63, "Rê2": 293.66, "Mi2": 329.63,
	"Sol2": 392.00, "La2": 440.00, "Đô3": 523.25, "Rê3": 587.33, "Mi3": 659.25,
	"Sol3": 783.99, "La3": 880.00, "Đô4": 1046.50, "Rê4": 1174.66, "Mi4": 1318.51,
	"Sol4": 1567.98, "La4": 1760.00
}

func _ready():
	current_lesson_id = SecureDataManager.active_lesson_id
	if not current_lesson_id or current_lesson_id == "":
		current_lesson_id = "dan_tranh_level_1_bai_1_practice"
		
	lesson_sheet.assign(PracticeRoom.current_song_sheet)
	if lesson_sheet.is_empty():
		lesson_sheet = ["Sol1", "La1", "Đô2", "Rê2", "Mi2"] # fallback
	
	staff_display = load("res://scripts/StaffDisplay.gd").new()
	staff_display.name = "StaffDisplay"
	staff_display.size_flags_vertical = Control.SIZE_EXPAND_FILL
	string_overlay.add_child(staff_display)
	
	zither_board.set_script(load("res://scripts/DanTranhBoard.gd"))
	zither_board.set_process(true)
	
	back_btn.pressed.connect(_on_back)
	complete_btn.pressed.connect(_on_complete)
	
	_start_intro()

func _process(delta):
	if current_state == State.PRACTICE:
		_process_practice(delta)

func _start_intro():
	current_state = State.INTRO
	intro_step = 0
	teacher_area.visible = true
	complete_btn.visible = false
	_play_next_intro_step()

func _play_next_intro_step():
	var dialogues = LESSON_DIALOGUES.get(current_lesson_id, [])
	if intro_step >= dialogues.size():
		_start_practice()
		return
		
	var step_data = dialogues[intro_step]
	if step_data["action"] == "speak":
		speech_text.text = step_data["text"]
		if AIAudioManager:
			AIAudioManager.speak_vietnamese(step_data["text"])
			
		# Highlight string
		zither_board.call("clear_lesson_markers")
		if step_data.get("highlight", -1) >= 0:
			zither_board.call("set_lesson_marker", step_data["highlight"], "Gảy", 1)
			
		# Wait for speech to finish then go to next step
		var wait_time = max(1.5, step_data["text"].length() * 0.1)
		get_tree().create_timer(wait_time).timeout.connect(_play_next_intro_step)
	intro_step += 1

func _start_practice():
	current_state = State.PRACTICE
	teacher_area.visible = false
	instruction_lbl.text = "THỰC HÀNH TƯƠNG TÁC"
	sub_instruction_lbl.text = "Gảy các nốt tương ứng trên màn hình hoặc dùng đàn thật"
	practice_idx = 0
	practice_time = 0.0
	active_falling_notes.clear()
	
	zither_board.call("clear_lesson_markers")
	if analyzer:
		analyzer.start_listening()
		
	_schedule_next_note()

func _schedule_next_note():
	if practice_idx >= lesson_sheet.size():
		get_tree().create_timer(2.0).timeout.connect(_finish_practice)
		return
		
	var note_name = lesson_sheet[practice_idx]
	var string_idx = NOTE_TO_STRING.get(note_name, 0)
	
	# Add to staff display
	active_falling_notes.append({
		"note": note_name,
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
		
		if abs(note["x"] - hit_x) < 30.0:
			# Highlight string on zither board when note hits the line
			var s_idx = note["target_string"]
			zither_board.call("set_lesson_marker", s_idx, note["note"], 2)
			
			# Check microphone for this string's frequency
			var target_hz = NOTE_FREQS.get(note["note"], 0.0)
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
		analyzer.stop_listening()
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
		analyzer.stop_listening()
	get_tree().change_scene_to_file("res://scenes/LessonDanTranhList.tscn")

func _on_complete():
	_on_back()
'''

with open('scripts/LessonDanTranh.gd', 'w', encoding='utf-8') as f:
    f.write(gd_content)
