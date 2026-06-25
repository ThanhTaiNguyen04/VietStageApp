extends Control
class_name PracticeRoom

# ─── Color Palette ─────────────────────────────────────────────────────────────
const C_GOLD       := Color(0.77, 0.58, 0.15, 1.0)
const C_GOLD_LIGHT := Color(0.95, 0.82, 0.45, 1.0)
const C_JADE       := Color(0.12, 0.37, 0.23, 1.0)
const C_RED_SON    := Color(0.09, 0.27, 0.18, 1.0)
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

# ─── @onready ─────────────────────────────────────────────────────────────────
@onready var linh_panel   : PanelContainer = $Root/MiddleRow/LinhPanel
@onready var char_linh    : TextureRect   = $Root/MiddleRow/LinhPanel/LinhVBox/CharLinhWrapper/CharLinh
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
@onready var target_label : Label         = $Root/StringsBoard/BoardM/BoardVBox/TargetLabel
@onready var hint_dialog  : AcceptDialog  = $HintDialog
@onready var result_dialog: AcceptDialog  = $ResultDialog
@onready var dots_hbox    : HBoxContainer = $Root/TopBar/TopM/TopH/DotsHBox
@onready var _board       : Control       = $Root/StringsBoard/BoardM/BoardVBox/DanTranhBoard

# ─── State ────────────────────────────────────────────────────────────────────
var _recording   := false
var _mic_mode    := true
var _score       := 75.0
var _sim_timer   := 0.0
var _correct_pitch_hold_time := 0.0
var _float_tween : Tween
var _note_idx    := 2

# AI Analysis tracking variables
var _practice_time := 0.0
var _detected_onsets : PackedFloat32Array = PackedFloat32Array()
var _reference_onsets : PackedFloat32Array = PackedFloat32Array()
var _pitch_scores : Array[float] = []
var _tone_scores : Array[float] = []

var _string_streams: Array[AudioStreamWAV] = []
var _rec_tween   : Tween
var _detected_notes_history: Array[String] = []
const HISTORY_SIZE := 8
var _teacher_tip_timer := 0.0

var _eval_cooldown := 0.0
var _linh_collapsed := true
var linh_mini_btn : Button
var _collapse_timer : SceneTreeTimer = null

const NOTES_VN : Array[String] = [
	"Đô", "Rê", "Mi", "Fa", "Sol", "La", "Si",
	"Đô2", "Rê2", "Mi2", "Fa2", "Sol2", "La2", "Si2",
	"Đô3", "Rê3"
]
static var current_song_title := ""
static var current_song_sheet : Array[String] = []

var sheet_notes : Array[String] = ["Đô","Đô","Rê","Fa","Fa","Sol","La","Sol","Fa","Rê","Đô"]
const SPEECHES : Array[String] = [
	"Gảy nhẹ dây số 3,\nnhấn rung bên trái nhạn đàn.",
	"Rất tốt!\nGiữ ngón cố định hơn nhé.",
	"Cao độ đang chuẩn,\ntiếp tục nào.",
	"Âm rung mềm mại,\nnhịp đều hơn nhé.",
	"Cổ tay thả lỏng,\ngảy dứt khoát hơn.",
]

func _ready() -> void:
	var pentatonic_to_western = {
		"Hò": "Đô",
		"Xự": "Rê",
		"Xang": "Fa",
		"Xê": "Sol",
		"Công": "La",
		"Liu": "Đô2",
		"Ú": "Rê2"
	}
	if current_song_title != "":
		sheet_notes.clear()
		for note in current_song_sheet:
			sheet_notes.append(pentatonic_to_western.get(note, note))
	else:
		var mapped: Array[String] = []
		for note in sheet_notes:
			mapped.append(pentatonic_to_western.get(note, note))
		sheet_notes = mapped
	_generate_streams()
	_set_labels()
	_build_theme()
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
		visualizer.min_frequency = 150.0
		visualizer.max_frequency = 900.0
		visualizer.volume_threshold_db = -32.0
		visualizer.visible = false
		record_hbox.add_child(visualizer)
		record_hbox.move_child(visualizer, 1) # Positioned beautifully between RecordBtn and ResetBtn
		
		# Programmatic Mode Toggle Button
		var mode_btn := Button.new()
		mode_btn.name = "ModeToggleBtn"
		mode_btn.text = "Chế độ: Micro 🎙️"
		mode_btn.custom_minimum_size = Vector2(170, 44)
		mode_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		record_hbox.add_child(mode_btn)
		record_hbox.move_child(mode_btn, 0)
		_style_outlined_btn(mode_btn)
		_make_button_bouncy(mode_btn)
		
		mode_btn.pressed.connect(func() -> void:
			_mic_mode = not _mic_mode
			if _mic_mode:
				mode_btn.text = "Chế độ: Micro 🎙️"
				_va_say("Đã chuyển sang Chế độ luyện tập qua Micro.")
			else:
				mode_btn.text = "Chế độ: Chạm 📱"
				_va_say("Đã chuyển sang Chế độ tự học qua màn hình chạm.")
		)

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
		record_hbox.move_child(rec_indicator, 2)
		
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.35)

	char_linh.mouse_filter = Control.MOUSE_FILTER_STOP
	char_linh.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			var chat = AIChatPopup.new()
			add_child(chat)
			chat.open_chat("dan_tranh")
	)


func _process(delta: float) -> void:
	if _recording:
				# Find closest physical string
				var closest_idx = _find_closest_string_index(pitch)
				var target_note = sheet_notes[_note_idx]
				var closest_note = ""
				
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
				var base_note = note_names.get(note_in_octave, "")
				if not base_note.is_empty():
					var octave_offset = (rounded_midi / 12) - 4
					if octave_offset == 1:
						if base_note.ends_with("#"):
							closest_note = base_note.left(-1) + "2#"
						else:
							closest_note = base_note + "2"
					elif octave_offset >= 2:
						if base_note.ends_with("#"):
							closest_note = base_note.left(-1) + "3#"
						else:
							closest_note = base_note + "3"
					else:
						closest_note = base_note
				
				# Stabilization filter
				var stable_note = _get_stabilized_note(closest_note)
				
				if not stable_note.is_empty():
					# 2. Update UI
					pitch_note.text = stable_note
					
					# 3. Cents deviation relative to closest physical string
					if closest_idx != -1:
						var target_freq = _get_string_frequency(closest_idx)
						cents = 1200.0 * log(pitch / target_freq) / log(2.0)
					
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
						
					# 4. Check against target note in sheet
					if stable_note == target_note and ac < 45.0:
						_correct_pitch_hold_time += delta
						if _correct_pitch_hold_time >= 0.6:
							_correct_pitch_hold_time = 0.0
							# Pluck the string on board as feedback
							if _board and closest_idx != -1:
								_board.pluck(closest_idx)
							# Advance note
							_note_idx = (_note_idx + 1) % sheet_notes.size()
							_build_notation()
							_update_target_indicator()
							# Score bonus
							_score = clamp(_score + randf_range(2.0, 5.0), 0, 100)
							_refresh_score()
							_update_rhythm()
							if randi() % 3 == 0:
								_va_say(SPEECHES[randi() % SPEECHES.size()])
					else:
						_correct_pitch_hold_time = max(0.0, _correct_pitch_hold_time - delta * 0.5)
						
					# Check and give teacher tips (rate limited to once every 2 seconds)
					_teacher_tip_timer += delta
					if _teacher_tip_timer >= 2.0:
						_teacher_tip_timer = 0.0
						_check_teacher_advice(stable_note, ac)
				else:
					# Filter stage
					pitch_note.text = "---"
					pitch_status.text = "Đang phân tích..."
					pitch_status.add_theme_color_override("font_color", C_TEXT_MUTED)
					pitch_note.add_theme_color_override("font_color", C_TEXT_MUTED)
					_correct_pitch_hold_time = max(0.0, _correct_pitch_hold_time - delta)
			else:
				# Silence
				_get_stabilized_note("")
				pitch_note.text = "---"
				pitch_status.text = "Chờ âm thanh..."
				pitch_status.add_theme_color_override("font_color", C_TEXT_MUTED)
				pitch_note.add_theme_color_override("font_color", C_TEXT_MUTED)
				_correct_pitch_hold_time = max(0.0, _correct_pitch_hold_time - delta)
		else:
			# Fallback to simulation
=======
		_practice_time += delta
		if _mic_mode:
			_process_real_audio(delta)
		else:
>>>>>>> origin/dat
			_sim_timer += delta
			if _sim_timer >= 1.2:
				_sim_timer = 0.0
				_simulate_tick()

# ─── Labels ───────────────────────────────────────────────────────────────────
func _set_labels() -> void:
	($Root/TopBar/TopM/TopH/BackBtn    as Button).text = "Quay lại"
	
	var diff := "Cơ bản"
	if CourseMap.active_lesson_id == "Node3":
		diff = "Trung bình"
	elif CourseMap.active_lesson_id == "Node4":
		diff = "Nâng cao"
		
	var title_lbl := "Kỹ Thuật Nhấn Dây & Rung Âm"
	if current_song_title != "":
		title_lbl = current_song_title
		diff = "Bài hát"
	else:
		if CourseMap.active_lesson_id == "Node2":
			title_lbl = "3 Nốt Đầu (Đô - Rê - Mi)"
		elif CourseMap.active_lesson_id == "Node4":
			title_lbl = "Kỹ Thuật Song Thanh"

	($Root/TopBar/TopM/TopH/LessonTag  as Label).text  = "ĐÀN TRANH  ·  KỸ THUẬT  ·  %s" % diff.to_upper()
	($Root/TopBar/TopM/TopH/LessonTitle as Label).text = title_lbl
	($Root/TopBar/TopM/TopH/ProgressVBox/PctLabel as Label).text = "60%" if current_song_title == "" else "100%"
	($Root/TopBar/TopM/TopH/CtrlBtns/HintBtn as Button).text = "Gợi ý"
	($Root/TopBar/TopM/TopH/CtrlBtns/DemoBtn as Button).text = "Demo"
	($Root/TopBar/TopM/TopH/CtrlBtns/SlowBtn as Button).text = "x0.5"

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

	# Strings board — deep rosewood background
	var sb_s := StyleBoxFlat.new()
	sb_s.bg_color = Color(0.11, 0.06, 0.02, 1.0)
	sb_s.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45)
	sb_s.border_width_top = 2; sb_s.border_width_bottom = 0
	sb_s.border_width_left = 0; sb_s.border_width_right = 0
	($Root/StringsBoard as PanelContainer).add_theme_stylebox_override("panel", sb_s)
	($Root/StringsBoard/BoardM/BoardVBox/BoardLabel as Label).add_theme_color_override("font_color", Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.75))
	($Root/StringsBoard/BoardM/BoardVBox/TargetLabel as Label).add_theme_color_override("font_color", Color(1.0, 0.92, 0.70, 1.0))

	# Record bar
	var rec_bar_s := _flat(C_BG_BAR, Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.15), 0)
	rec_bar_s.border_width_top = 2; rec_bar_s.border_width_bottom = 0; rec_bar_s.border_width_left = 0; rec_bar_s.border_width_right = 0
	($Root/RecordBar as PanelContainer).add_theme_stylebox_override("panel", rec_bar_s)

	# Record button
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

# ─── Notation Track ───────────────────────────────────────────────────────────
func _build_notation() -> void:
	for c in notes_hbox.get_children(): c.queue_free()
	
	var scroll_container := notes_hbox.get_parent() as ScrollContainer
	if scroll_container:
		scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER

	for i in sheet_notes.size():
		var note     := sheet_notes[i]
		var is_active := i == _note_idx
		var is_done   := i < _note_idx

		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(60, 60)
		var cs := StyleBoxFlat.new()
		cs.border_width_left = 2; cs.border_width_right = 2; cs.border_width_top = 2; cs.border_width_bottom = 2
		cs.corner_radius_top_left = 30; cs.corner_radius_top_right = 30
		cs.corner_radius_bottom_left = 30; cs.corner_radius_bottom_right = 30
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
		lbl.add_theme_font_size_override("font_size", 17)
		lbl.add_theme_color_override("font_color",
			Color(1, 1, 1, 1) if (is_active or is_done) else C_TEXT_MUTED)
		card.add_child(lbl)
		notes_hbox.add_child(card)

	# Scroll smoothly to center the active note
	if scroll_container:
		var separation := 4.0 # default HBox container separation
		var active_x := 0.0
		var active_w := 60.0
		for j in range(_note_idx):
			active_x += 60.0 + separation
			
		var viewport_w : float = scroll_container.size.x if scroll_container.size.x > 0 else 800.0
		var target_scroll : float = active_x + (active_w / 2.0) - (viewport_w / 2.0)
		
		var tween = create_tween()
		tween.tween_property(scroll_container, "scroll_horizontal", int(max(0.0, target_scroll)), 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

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
	# Đàn tranh 16 dây - tần số chuẩn từ dây 1 (thấp) đến dây 16 (cao)
	# Tuning theo hệ thất cung (diatonic) Đô, Rê, Mi, Fa, Sol, La, Si
	var base_freqs = [
		130.81, # Đô (C3)
		146.83, # Rê (D3)
		164.81, # Mi (E3)
		174.61, # Fa (F3)
		196.00, # Sol (G3)
		220.00, # La (A3)
		246.94  # Si (B3)
	]
	var octave = idx / 7
	var note_in_octave = idx % 7
	return base_freqs[note_in_octave] * pow(2, octave)

func _generate_pluck_stream(freq: float) -> AudioStreamWAV:
	# ── Karplus-Strong Plucked String Algorithm ──────────────────────────────
	const SAMPLE_RATE: int = 44100
	const DURATION: float  = 2.0   # 2 giây — đủ dài cho tiếng đàn tranh tắt tự nhiên
	var sample_count: int  = int(SAMPLE_RATE * DURATION)

	# Độ dài delay buffer = SAMPLE_RATE / freq
	var delay_len: int = int(float(SAMPLE_RATE) / freq)
	if delay_len < 2:
		delay_len = 2

	# Khởi tạo delay line bằng nhiễu trắng
	var delay_buf := PackedFloat32Array()
	delay_buf.resize(delay_len)
	for k in delay_len:
		delay_buf[k] = randf_range(-1.0, 1.0)

	# Hệ số decay tự nhiên theo tần số
	var decay: float = clamp(0.996 - freq / 20000.0, 0.980, 0.9995)

	# Sinh toàn bộ audio samples
	var samples := PackedFloat32Array()
	samples.resize(sample_count)
	var buf_pos: int = 0

	for i in sample_count:
		var next_pos: int = (buf_pos + 1) % delay_len
		var new_sample: float = decay * 0.5 * (delay_buf[buf_pos] + delay_buf[next_pos])
		samples[i] = new_sample
		delay_buf[buf_pos] = new_sample
		buf_pos = (buf_pos + 1) % delay_len

	# ── Chuẩn hoá và encode PCM 16-bit ───────────────────────────────────────
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

# ─── String Signal Handlers ───────────────────────────────────────────────────
func _on_string_plucked(idx: int, plucked_note: String) -> void:
	pitch_note.text   = plucked_note
	pitch_status.text = "Dây %d  —  Vừa gảy" % (idx + 1)
	pitch_status.add_theme_color_override("font_color", C_GREEN_OK)
	pitch_note.add_theme_color_override("font_color",   C_GOLD_LIGHT)

	if plucked_note == sheet_notes[_note_idx]:
		_note_idx = (_note_idx + 1) % sheet_notes.size()
		_build_notation()
		_update_target_indicator()
		_score = clamp(_score + 4.0, 0, 100)
		_refresh_score()
		_va_say("Xuất sắc! Gảy đúng nốt rồi.")

func _on_string_pressed(idx: int, cents_offset: float) -> void:
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

func _toggle_record() -> void:
	_recording = not _recording
	var visualizer = $Root/RecordBar/RecordM/RecordH.get_node_or_null("WaveformVisualizer")
	_update_rec_pulse(_recording)
	if _recording:
		record_btn.text = "Dừng luyện tập"
		_va_say(SPEECHES[0])
		_start_pitch_detection()
		if visualizer and _mic_mode: visualizer.visible = true
		if _board:
			_board.audio_enabled = false
		
		# Reset AI tracking
		_practice_time = 0.0
		_detected_onsets.clear()
		_pitch_scores.clear()
		_tone_scores.clear()
		_reference_onsets = PackedFloat32Array()
		for i in range(sheet_notes.size()):
			_reference_onsets.append(1.0 + i * 1.5)
	else:
		record_btn.text = "Bắt đầu luyện tập"
		if visualizer:
			visualizer.add_practice_score(_score)
		_show_custom_result()
		_stop_pitch_detection()
		if visualizer: visualizer.visible = false
		if _board:
			_board.audio_enabled = true

func _demo() -> void:
	_va_say("Đây là kỹ thuật nhấn dây chuẩn.\nQuan sát và làm theo.")
	var t := create_tween()
	t.tween_property(char_linh, "modulate", Color(1.5, 1.1, 0.6, 1.0), 0.3)
	t.tween_property(char_linh, "modulate", Color.WHITE, 0.5)

	var target_note := sheet_notes[_note_idx]
	var target_idx  := NOTES_VN.find(target_note)
	if target_idx == -1: target_idx = 0
	if _board:
		var dt := create_tween()
		dt.tween_interval(0.35)
		dt.tween_callback(func() -> void: _board.pluck(target_idx))

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
			var note_name = NOTES_VN[i % 7]
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
				
				# Advance note
				_note_idx = (_note_idx + 1) % sheet_notes.size()
				_build_notation()
				_update_target_indicator()
				
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
				detected_note = NOTES_VN[i % 7]
				
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

	if _linh_collapsed:
		_linh_collapsed = false
		_update_linh_visibility()
		
	var active_timer = get_tree().create_timer(6.0)
	_collapse_timer = active_timer
	active_timer.timeout.connect(func():
		if _collapse_timer == active_timer and not _linh_collapsed:
			_linh_collapsed = true
			_update_linh_visibility()
	)

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
	if target_idx == -1: target_idx = 0
	target_label.text      = "Dây cần gảy: %d" % (target_idx + 1)
	target_note_label.text = "Nốt cần gảy: %s" % target_note
	if _board: _board.set_target(target_idx)

func _reset() -> void:
	_score = 75.0; _recording = false; _note_idx = 2
	_eval_cooldown = 0.0
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
		SecureDataManager.complete_lesson(inst, CourseMap.active_lesson_id, stars)
		
	var popup_scene := load("res://scenes/CustomPopup.tscn") as PackedScene
	if popup_scene:
		var popup = popup_scene.instantiate()
		add_child(popup)
		
		var next_lesson_name := "Khóa Học Tiếp"
		if CourseMap.active_lesson_id == "Node2":
			next_lesson_name = "Nhấn & Rung"
		elif CourseMap.active_lesson_id == "Node3":
			next_lesson_name = "Song Thanh"
			
		popup.setup_result(_score, 82.0, 71.0, 79.0, 80, "Đã mở khóa: " + next_lesson_name)

func _go_back() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.22)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/CourseMap.tscn"))

## Pitch-detection stubs — replace with real implementation or plugin integration
func _start_pitch_detection() -> void:
	# TODO: integrate a pitch-detection plugin or use FFT on input audio
	# For now we keep the simulated tick process running
	_sim_timer = 0.0

func _stop_pitch_detection() -> void:
	# Stop any audio capture or analysis. Placeholder for real integration.
	_sim_timer = 0.0

# ─── Helpers ──────────────────────────────────────────────────────────────────
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
