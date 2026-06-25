extends Control
class_name PracticeSaoTruc

# ─── Color Palette ─────────────────────────────────────────────────────────────
const C_GOLD       := Color(0.77, 0.58, 0.15, 1.0)
const C_GOLD_LIGHT := Color(0.95, 0.82, 0.45, 1.0)
const C_JADE       := Color(0.12, 0.37, 0.23, 1.0)
const C_RED_SON    := Color(0.70, 0.12, 0.08, 1.0)
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

@onready var char_linh    : TextureRect   = $Root/MiddleRow/LinhPanel/LinhVBox/CharLinh
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
var _score       := 75.0
var _sim_timer   := 0.0
var _correct_pitch_hold_time := 0.0
var _float_tween : Tween
var _note_idx    := 0
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

const FREQS := {
	"Đô": 261.63, # C4
	"Rê": 293.66, # D4
	"Mi": 329.63, # E4
	"Fa": 349.23, # F4
	"Sol": 392.00, # G4
	"La": 440.00, # A4
	"Si": 493.88  # B4
}

const FINGERINGS := {
	"Đô": [true, true, true, true, true, true],
	"Rê": [true, true, true, true, true, false],
	"Mi": [true, true, true, true, false, false],
	"Fa": [true, true, true, false, false, false],
	"Sol": [true, true, false, false, false, false],
	"La": [true, false, false, false, false, false],
	"Si": [false, false, false, false, false, false]
}

const NOTES_VN : Array[String] = ["Đô", "Rê", "Mi", "Fa", "Sol", "La", "Si"]
static var current_song_title := ""
static var current_song_sheet : Array[String] = []

var sheet_notes : Array[String] = ["Đô","Đô","Rê","Mi","Mi","Fa","Sol","Fa","Mi","Rê","Đô"]
const HOLES    := 6
const SPEECHES : Array[String] = [
	"Thở đều, môi khép nhẹ.",
	"Giữ hơi ổn định nhé.",
	"Tốt lắm, âm rõ rồi.",
	"Cổ tay thả lỏng, đừng gồng.",
]

func _ready() -> void:
	if current_song_title != "":
		sheet_notes = current_song_sheet
	_generate_streams()
	_set_labels()
	_build_theme()
	_build_notation()
	_build_flute()
	_build_dots()
	_build_rhythm_bars()
	_start_float()
	_connect_buttons()
	
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
		visualizer.max_frequency = 1200.0
		visualizer.volume_threshold_db = -32.0
		visualizer.visible = false
		record_hbox.add_child(visualizer)
		record_hbox.move_child(visualizer, 1) # Positioned beautifully between RecordBtn and ResetBtn

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
	# 1. Update breath pressure first
	_update_breath_physics(delta)
	
	# 2. Update zither backing track if recording and in Lesson 2
	if _recording and _lesson_mode == 1:
		_update_backing_track(delta)
		
	if _recording:
		var visualizer = $Root/RecordBar/RecordM/RecordH.get_node_or_null("WaveformVisualizer")
		if visualizer and is_instance_valid(visualizer):
			var amplitude_db = visualizer.current_amplitude_db
			var pitch = visualizer.current_pitch
			
			if amplitude_db > visualizer.volume_threshold_db and pitch > 0.0:
				# Convert pitch to MIDI note index
				var midi = 12.0 * log(pitch / 440.0) / log(2.0) + 69.0
				var rounded_midi = int(round(midi))
				var cents = (midi - rounded_midi) * 100.0
				var note_in_octave = rounded_midi % 12
				
				var note_names = {
					0: "Đô",
					1: "Đô#",
					2: "Rê",
					3: "Rê#",
					4: "Mi",
					5: "Fa",
					6: "Fa#",
					7: "Sol",
					8: "Sol#",
					9: "La",
					10: "La#",
					11: "Si"
				}
				var closest_note = note_names.get(note_in_octave, "")
				
				# Stabilization filter
				var stable_note = _get_stabilized_note(closest_note)
				
				if not stable_note.is_empty():
					# Update UI with stabilized note
					pitch_note.text = stable_note
					
					# Mirror the fingering of the detected note on the screen!
					_update_virtual_holes(stable_note)
					
					# Calculate cents deviation status
					var ac = absf(cents)
					if ac < 15.0:
						pitch_status.text = "Đúng cao độ"
						pitch_status.add_theme_color_override("font_color", C_GREEN_OK)
						pitch_note.add_theme_color_override("font_color",   C_GREEN_OK)
					elif ac < 35.0:
						pitch_status.text = ("Hơi thấp" if cents < 0 else "Hơi cao")
						pitch_status.add_theme_color_override("font_color", C_WARN)
						pitch_note.add_theme_color_override("font_color",   C_WARN)
					else:
						pitch_status.text = "Lệch cao độ"
						pitch_status.add_theme_color_override("font_color", C_RED_ERR)
						pitch_note.add_theme_color_override("font_color",   C_RED_ERR)
					
					# Enforce breath pressure check for note advancement [28.0, 85.0] (easier for beginners)
					var target_note = sheet_notes[_note_idx]
					var is_breath_ok = _breath_pressure >= 28.0 and _breath_pressure <= 85.0
					
					if stable_note == target_note and ac < 45.0:
						if is_breath_ok:
							_correct_pitch_hold_time += delta
							if _correct_pitch_hold_time >= 0.6:
								_correct_pitch_hold_time = 0.0
								_score = clamp(_score + randf_range(2.0, 5.0), 0, 100)
								_refresh_score()
								_update_rhythm()
								
								if _lesson_mode == 0:
									# Lesson 1: step-by-step note study
									_note_idx = (_note_idx + 1) % sheet_notes.size()
									_build_notation()
									_update_target_indicator()
									
									# Play guide for the next note!
									var next_note = sheet_notes[_note_idx]
									_play_zither_backing(next_note)
									_va_say("Đúng rồi! Hãy tiếp tục thổi nốt mẫu %s nhé." % next_note)
								else:
									# Lesson 2: backing track practice
									# Play zither pluck feedback
									_play_zither_backing(target_note)
									_va_say("Chuẩn nốt! Nhạc nền tiếp tục...")
									
									# Resume backing track!
									_backing_playing = true
									_backing_timer = BEAT_DURATION
						else:
							# Correct note but wrong breath pressure
							_correct_pitch_hold_time = max(0.0, _correct_pitch_hold_time - delta * 0.5)
					else:
						_correct_pitch_hold_time = max(0.0, _correct_pitch_hold_time - delta * 0.5)
					
					# Check and give teacher tips (rate limited to once every 2 seconds)
					_teacher_tip_timer += delta
					if _teacher_tip_timer >= 2.0:
						_teacher_tip_timer = 0.0
						_check_teacher_advice(stable_note, is_breath_ok)
				else:
					# Filter stage
					pitch_note.text = "---"
					pitch_status.text = "Đang phân tích..."
					pitch_status.add_theme_color_override("font_color", C_TEXT_MUTED)
					pitch_note.add_theme_color_override("font_color", C_TEXT_MUTED)
					_correct_pitch_hold_time = max(0.0, _correct_pitch_hold_time - delta)
					_update_virtual_holes(sheet_notes[_note_idx])
			else:
				# Quiet / Silence
				_get_stabilized_note("")
				pitch_note.text = "---"
				pitch_status.text = "Chờ hơi thổi..."
				pitch_status.add_theme_color_override("font_color", C_TEXT_MUTED)
				pitch_note.add_theme_color_override("font_color", C_TEXT_MUTED)
				_correct_pitch_hold_time = max(0.0, _correct_pitch_hold_time - delta)
				_update_virtual_holes(sheet_notes[_note_idx])
		else:
			# Fallback to simulation if visualizer doesn't exist
			_sim_timer += delta
			if _sim_timer >= 1.2:
				_sim_timer = 0.0
				_simulate_tick()

func _set_labels() -> void:
	($Root/TopBar/TopM/TopH/BackBtn    as Button).text = "Quay lại"
	($Root/TopBar/TopM/TopH/LessonTag  as Label).text  = "SÁO TRÚC  ·  BÀI 1" if current_song_title == "" else "SÁO TRÚC  ·  BÀI HÁT"
	($Root/TopBar/TopM/TopH/LessonTitle as Label).text = "Hơi thở & che lỗ cơ bản" if current_song_title == "" else current_song_title
	($Root/TopBar/TopM/TopH/ProgressVBox/PctLabel as Label).text = "20%" if current_song_title == "" else "100%"
	($Root/TopBar/TopM/TopH/CtrlBtns/HintBtn as Button).text = "Gợi ý"
	($Root/TopBar/TopM/TopH/CtrlBtns/DemoBtn as Button).text = "Demo"
	($Root/TopBar/TopM/TopH/CtrlBtns/SlowBtn as Button).text = "x0.5"

	($Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/NotationLabel as Label).text = "BẢN NHẠC  —  Thổi theo dòng nốt"
	($Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/TargetNoteLabel as Label).text = "Nốt cần thổi: Đô"
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
	for c in notes_hbox.get_children(): c.queue_free()
	for i in sheet_notes.size():
		var note     := sheet_notes[i]
		var is_active := i == _note_idx
		var is_done   := i < _note_idx

		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(70, 70)
		var cs := StyleBoxFlat.new()
		cs.border_width_left = 2; cs.border_width_right = 2; cs.border_width_top = 2; cs.border_width_bottom = 2
		cs.corner_radius_top_left = 35; cs.corner_radius_top_right = 35
		cs.corner_radius_bottom_left = 35; cs.corner_radius_bottom_right = 35
		if is_active:
			cs.bg_color     = C_GOLD
			cs.border_color = Color(1.0, 0.9, 0.6, 1.0)
			cs.shadow_size  = 12; cs.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35)
		elif is_done:
			cs.bg_color     = C_JADE
			cs.border_color = Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.8)
		else:
			cs.bg_color     = Color(0.95, 0.93, 0.89, 1.0)
			cs.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.2)
		card.add_theme_stylebox_override("panel", cs)

		var lbl := Label.new()
		lbl.text = note
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.add_theme_color_override("font_color",
			Color(1, 1, 1, 1) if (is_active or is_done) else C_TEXT_MUTED)
		card.add_child(lbl)
		notes_hbox.add_child(card)

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
	demo_btn.pressed.connect(_demo)
	slow_btn.pressed.connect(func() -> void: _va_say("Xem chậm x0.5 – dễ học từng bước."))
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
		if visualizer: visualizer.visible = true
	else:
		record_btn.text = "Bắt đầu luyện tập"
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

func _show_custom_hint() -> void:
	var popup_scene := load("res://scenes/CustomPopup.tscn") as PackedScene
	if popup_scene:
		var popup = popup_scene.instantiate()
		add_child(popup)
		var text := "[b]🎵 HƠI THỞ:[/b]\nThổi hơi đều, ổn định, không quá mạnh để tránh bị quá quãng (overblow).\n\n[b]🎵 THẾ BẤM CHE LỖ:[/b]\nĐặt các đầu ngón tay phủ kín hoàn toàn các lỗ sáo sẫm màu theo thế bấm nốt nhạc mục tiêu.\n\n[b]💡 HƯỚNG DẪN KỸ THUẬT:[/b]\n• Giữ môi khép nhẹ, thổi luồng hơi tập trung.\n• Thả lỏng cổ tay và ngón tay khi che lỗ sáo.\n• Lắng nghe cao độ phản hồi để điều chỉnh thế bấm.\n• Luyện tập hơi dài và đều đặn mỗi ngày."
		popup.setup_hint("Gợi ý kỹ thuật", text)

func _show_custom_result() -> void:
	var popup_scene := load("res://scenes/CustomPopup.tscn") as PackedScene
	if popup_scene:
		var popup = popup_scene.instantiate()
		add_child(popup)
		var p := randf_range(70, 92)
		var r := randf_range(65, 90)
		var t := clampf((_score * 3.0 - p - r), 60, 95)
		popup.setup_result(_score, p, r, t, 80, "Đã mở khóa Bài 2")

func _reset() -> void:
	_note_idx = 0
	_score = 75.0
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
		_play_zither_backing(first_note)
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
		if _auto_blow:
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
	
	var fill_style = breath_progress.get_theme_stylebox("fill") as StyleBoxFlat
	if not fill_style:
		fill_style = StyleBoxFlat.new()
		fill_style.corner_radius_top_left = 6; fill_style.corner_radius_top_right = 6
		fill_style.corner_radius_bottom_left = 6; fill_style.corner_radius_bottom_right = 6
		breath_progress.add_theme_stylebox_override("fill", fill_style)
		
	if _breath_pressure < 15.0:
		breath_status.text = "Chờ hơi thổi..."
		breath_status.add_theme_color_override("font_color", C_CREAM_DIM)
		fill_style.bg_color = C_CREAM_DIM
		if _recording and _active_player and is_instance_valid(_active_player):
			_active_player.volume_db = -80.0
	elif _breath_pressure >= 15.0 and _breath_pressure < 40.0:
		breath_status.text = "Hơi yếu (Hơi thấp)"
		breath_status.add_theme_color_override("font_color", C_WARN)
		fill_style.bg_color = C_WARN
		if _recording and _active_player and is_instance_valid(_active_player):
			_active_player.volume_db = -12.0
			_active_player.pitch_scale = 0.985
	elif _breath_pressure >= 40.0 and _breath_pressure <= 82.0:
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
				_play_zither_backing(beat.note)
				_va_say("Nghe nhạc mẫu. Hãy thổi nốt %s!" % beat.note)
