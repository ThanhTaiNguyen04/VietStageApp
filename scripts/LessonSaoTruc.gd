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
	"Node8": {"note": "Đô", "desc": "Bấm cả 6 lỗ và thổi nhẹ", "fingers": [true, true, true, true, true, true]}
}

const LESSON_DIALOGUES = {
	"Si": {
		"intro": "Chào bạn! Đây là bài học Sáo Trúc đầu tiên. Nốt Si là nốt cơ bản nhất, âm thanh thanh thoát và nhẹ nhàng. Để thổi nốt Si, bạn chỉ cần mở toàn bộ 6 lỗ, không che lỗ nào. Hãy cầm sáo lên và thổi một luồng hơi êm dịu nhé!",
		"mid": "Tuyệt vời! Bạn có thấy âm thanh nốt Si thật trong trẻo không? Bây giờ, hãy cùng chơi một bản nhạc nhỏ để làm quen với nhịp điệu nhé!"
	},
	"La": {
		"intro": "Chào mừng bạn trở lại! Hôm nay chúng ta sẽ chinh phục nốt La. Nốt La có âm sắc trầm hơn nốt Si một chút. Bấm ngón tay trỏ tay trái vào lỗ đầu tiên thật kín và thổi nhẹ nào!",
		"mid": "Rất tốt! Âm La nghe rất vang và ấm đúng không? Bây giờ hãy thử kết hợp nốt La với nốt Si vừa học trong một thử thách nhịp điệu nhé!"
	},
	"Sol": {
		"intro": "Bạn tiến bộ nhanh lắm! Nốt tiếp theo là nốt Sol. Hãy dùng hai ngón tay che kín 2 lỗ đầu tiên. Nhớ là các ngón tay phải bịt thật kín mặt lỗ để âm thanh không bị xì nhé!",
		"mid": "Xuất sắc! Việc chuyển ngón giữa các nốt Si, La, Sol là nền tảng của rất nhiều bài nhạc hay. Chúng ta cùng tập ghép chúng lại nào!"
	},
	"Fa": {
		"intro": "Hôm nay chúng ta học nốt Fa! Âm Fa mang lại cảm giác hơi man mác buồn. Bịt kín 3 lỗ đầu tiên nhé. Cẩn thận ngón áp út tay trái thường hay hở nhất đấy!",
		"mid": "Hay lắm! Càng bịt nhiều lỗ, hơi thổi của bạn cần phải đều đặn hơn. Hãy sẵn sàng cho thử thách bấm thả liên tục nhé!"
	},
	"Mi": {
		"intro": "Chào bạn! Đã đến lúc dùng đến bàn tay phải rồi. Để thổi nốt Mi, bạn che 4 lỗ đầu. Hãy thả lỏng cổ tay phải và đặt ngón trỏ thật tự nhiên nhé!",
		"mid": "Thật tuyệt vời! Bạn đã điều khiển được bàn tay phải rồi đó. Hãy cùng chơi một giai điệu để kết hợp cả hai tay nhé!"
	},
	"Rê": {
		"intro": "Sắp chinh phục được toàn bộ các nốt cơ bản rồi! Nốt Rê yêu cầu bạn bịt 5 lỗ. Cột hơi bây giờ cần phải sâu và nén tốt hơn. Hãy hít một hơi thật sâu nào!",
		"mid": "Giỏi lắm! Âm Rê rung lên rất êm ái. Chơi tốt nốt này chứng tỏ kỹ năng kiểm soát hơi của bạn đã tiến bộ vượt bậc!"
	},
	"Đô": {
		"intro": "Chúc mừng bạn đã đến với nốt trầm nhất của cây sáo: Nốt Đô! Bịt kín toàn bộ 6 lỗ. Hãy thổi thật khẽ và ấm, vì nếu thổi mạnh nó sẽ vút lên nốt cao đấy!",
		"mid": "Hoàn hảo! Cảm nhận độ rung của thân sáo khi thổi nốt Đô thật thích đúng không? Giờ là lúc kết hợp toàn bộ 6 nốt để tạo nên phép màu!"
	}
}

const NOTE_FREQS = {
	"Đô": 523.25,
	"Rê": 587.33,
	"Mi": 659.25,
	"Fa": 698.46,
	"Sol": 783.99,
	"La": 880.00,
	"Si": 987.77
}

func _ready():
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
		if LESSON_DIALOGUES.has(active_note):
			txt = LESSON_DIALOGUES[active_note]["intro"]
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
	# Reset holes to invisible so user can press them
	for h in _holes:
		h.visible = false
	virtual_holes_state = [false, false, false, false, false, false]
	_start_practice()

func _start_real():
	is_virtual_mode = false
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
	mic_status.text = "Đang chờ âm thanh..."
	mic_status.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

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

# Biến lưu trữ các điểm chạm trên màn hình
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
			if touch_pos.distance_to(hole_center) < 70.0: # Bán kính siêu rộng 70px
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

func _process(delta):
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
		if is_virtual_mode:
			_process_virtual(delta)
		else:
			_process_real(delta)
	elif current_state == State.RHYTHM_GAME:
		_process_rhythm(delta, rect)

func _process_rhythm(delta, rect):
	var amp = analyzer.current_amplitude_db
	var hz = analyzer.current_pitch
	var vol_ratio = clamp((amp + 60.0) / 60.0, 0.0, 1.0)
	volume_bar.value = vol_ratio
	
	# Determine if there is a note currently overlapping the hit window
	var current_overlapping_note = null
	for note_data in active_falling_notes:
		var target_time = note_data["time"]
		var duration = note_data.get("duration", 1.0)
		var time_diff = target_time - rhythm_time
		if time_diff <= 0.0 and time_diff >= -duration:
			current_overlapping_note = note_data
			break
			
	var time_delta = delta
	
	if current_overlapping_note != null:
		var is_blowing = amp > -40.0
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
			if is_blowing and hz > 100.0:
				var target_hz_note = NOTE_FREQS.get(current_overlapping_note["note_name"], 0.0)
				if abs(hz - target_hz_note) < 25.0:
					is_correct = true
					
		if is_correct:
			time_delta = delta
			current_overlapping_note["node"].modulate = Color(0.2, 1.0, 0.2)
			mic_status.text = "Tuyệt! Giữ nốt..."
			mic_status.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
		else:
			time_delta = -delta * 1.5 # Tua lùi nhanh gấp rưỡi
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
	container.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	
	var blow_bar = ColorRect.new()
	blow_bar.color = Color(1.0, 1.0, 1.0, 0.1)
	blow_bar.size = Vector2(rect.size.x, length)
	blow_bar.position = Vector2(rect.position.x, -length)
	container.add_child(blow_bar)
	
	for i in range(HOLES):
		if i < fingers.size() and fingers[i]:
			var block = ColorRect.new()
			block.color = Color(0.3, 0.8, 0.9, 0.9)
			block.size = Vector2(30, length)
			var hx = rect.position.x + rect.size.x * HOLE_PROPS_X[i]
			block.position = Vector2(hx - 15, -length)
			
			var sb = StyleBoxFlat.new()
			sb.bg_color = block.color
			sb.corner_radius_top_left = 15; sb.corner_radius_top_right = 15
			sb.corner_radius_bottom_left = 15; sb.corner_radius_bottom_right = 15
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
	var keys_order = ["Node2", "Node3", "Node4", "Node5", "Node6", "Node7", "Node8"]
	var target_idx = keys_order.find(target_note_key)
	if target_idx == -1: target_idx = 0
	
	var seq = []
	var time = 1.0
	
	if target_idx == 0:
		# Only Si
		seq.append({"note": LESSON_NOTES["Node2"]["note"], "time": time, "duration": 1.5}); time += 2.0
		seq.append({"note": LESSON_NOTES["Node2"]["note"], "time": time, "duration": 1.0}); time += 1.5
		seq.append({"note": LESSON_NOTES["Node2"]["note"], "time": time, "duration": 2.0}); time += 2.5
	else:
		# Walk down
		for i in range(target_idx + 1):
			var note_name = LESSON_NOTES[keys_order[i]]["note"]
			seq.append({"note": note_name, "time": time, "duration": 1.0})
			time += 1.5
			
		# Do a little pattern at the end with the new note and the previous note
		var prev_note = LESSON_NOTES[keys_order[target_idx - 1]]["note"]
		var new_note = LESSON_NOTES[keys_order[target_idx]]["note"]
		
		seq.append({"note": prev_note, "time": time, "duration": 0.5}); time += 1.0
		seq.append({"note": new_note,  "time": time, "duration": 0.5}); time += 1.0
		seq.append({"note": prev_note, "time": time, "duration": 0.5}); time += 1.0
		seq.append({"note": new_note,  "time": time, "duration": 2.0}); time += 2.5
		
	return seq

func _process_virtual(delta):
	var amp = analyzer.current_amplitude_db
	var vol_ratio = clamp((amp + 60.0) / 60.0, 0.0, 1.0)
	volume_bar.value = vol_ratio
	
	if amp > -40.0:
		# Check if fingers match exactly
		var req = LESSON_NOTES[active_node_id]["fingers"]
		var matched = true
		for i in range(HOLES):
			if virtual_holes_state[i] != req[i]:
				matched = false
				break
				
		if matched:
			time_correct += delta
			var time_left = max(0, step_decimals(REQUIRED_HOLD_TIME - time_correct))
			mic_status.text = "Thổi tốt! Giữ nguyên tay " + str(time_left) + "s..."
			mic_status.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
			
			if time_correct >= REQUIRED_HOLD_TIME:
				_hit_note()
		else:
			time_correct = 0.0
			mic_status.text = "Bấm sai lỗ sáo rồi! Hãy kiểm tra lại tay."
			mic_status.add_theme_color_override("font_color", Color(0.9, 0.3, 0.2))
	else:
		time_correct = 0.0
		mic_status.text = "Bấm các lỗ và thổi vào Microphone..."
		mic_status.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

func _process_real(delta):
	var amp = analyzer.current_amplitude_db
	var hz = analyzer.current_pitch
	
	# Update volume bar (assuming -60db to 0db range)
	var vol_ratio = clamp((amp + 60.0) / 60.0, 0.0, 1.0)
	volume_bar.value = vol_ratio
	
	if amp > -40.0 and hz > 100.0:
		# User is blowing!
		var diff = abs(hz - target_hz)
		
		if diff < 25.0:
			# CORRECT!
			time_correct += delta
			var time_left = max(0, step_decimals(REQUIRED_HOLD_TIME - time_correct))
			mic_status.text = "Thổi đúng! Giữ thêm " + str(time_left) + "s..."
			mic_status.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
			
			if time_correct >= REQUIRED_HOLD_TIME:
				_hit_note()
		else:
			# INCORRECT! Find closest note
			time_correct = 0.0
			var closest_n = ""
			var min_d = 9999.0
			for n in NOTE_FREQS.keys():
				var d = abs(NOTE_FREQS[n] - hz)
				if d < min_d:
					min_d = d
					closest_n = n
			
			mic_status.text = "Sai nốt rồi, nốt bạn thổi là " + closest_n + ". (Yêu cầu: " + active_note + ")"
			mic_status.add_theme_color_override("font_color", Color(0.9, 0.3, 0.2))
	else:
		time_correct = 0.0
		mic_status.text = "Hãy thổi vào Microphone..."
		mic_status.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

func step_decimals(val: float) -> float:
	return round(val * 10.0) / 10.0

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
		if LESSON_DIALOGUES.has(active_note):
			txt = LESSON_DIALOGUES[active_note]["mid"]
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
	
	rhythm_time = -2.0 # 2 seconds delay
	spawned_notes = 0
	active_falling_notes.clear()

func _complete_lesson():
	current_state = State.COMPLETED
	feedback_area.visible = false
	analyzer.visible = false
	
	for lane in _lanes:
		lane.visible = false
	
	instruction_lbl.visible = false
	sub_instruction_lbl.visible = false
	
	if complete_overlay:
		complete_overlay.visible = true
	
	if ResourceLoader.exists("res://assets/sounds/success.ogg"):
		var audio = AudioStreamPlayer.new()
		audio.stream = load("res://assets/sounds/success.ogg")
		add_child(audio)
		audio.play()

func _on_back():
	get_tree().change_scene_to_file("res://scenes/CourseDetailScreen.tscn")

func _on_retry():
	get_tree().reload_current_scene()

func _on_complete():
	var idx = LESSON_NOTES.keys().find(active_node_id)
	if idx != -1:
		SecureDataManager.complete_lesson(SecureDataManager.data.get("selected_instrument", "sao_truc"), active_node_id, 3)
	get_tree().change_scene_to_file("res://scenes/CourseDetailScreen.tscn")

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
