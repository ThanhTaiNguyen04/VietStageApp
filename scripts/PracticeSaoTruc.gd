extends Control
class_name PracticeSaoTruc

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
@onready var holes_hbox   : HBoxContainer = $Root/FluteBoard/BoardM/BoardVBox/FluteFrame/FluteM/FluteStack/HoleRow
@onready var target_label : Label         = $Root/FluteBoard/BoardM/BoardVBox/TargetLabel
@onready var hint_dialog  : AcceptDialog  = $HintDialog
@onready var result_dialog: AcceptDialog  = $ResultDialog
@onready var dots_hbox    : HBoxContainer = $Root/TopBar/TopM/TopH/DotsHBox
@onready var breath_progress : ProgressBar = $Root/FluteBoard/BoardM/BoardVBox/BreathHBox/BreathProgress
@onready var breath_status   : Label       = $Root/FluteBoard/BoardM/BoardVBox/BreathHBox/BreathStatus

var _recording   := false
var _mic_mode    := true
var _score       := 75.0
var _sim_timer   := 0.0
var _float_tween : Tween
var _note_idx    := 0

# AI Analysis tracking variables
var _practice_time := 0.0
var _detected_onsets : PackedFloat32Array = PackedFloat32Array()
var _reference_onsets : PackedFloat32Array = PackedFloat32Array()
var _pitch_scores : Array[float] = []
var _breath_scores : Array[float] = []

var _covered_states : Array[bool] = [true, true, true, true, true, true]
var _flute_streams : Dictionary = {}
var _active_player : AudioStreamPlayer = null
var _breath_pressure := 0.0
var _rec_tween   : Tween
var _eval_cooldown := 0.0
var _linh_collapsed := true
var linh_mini_btn : Button
var _collapse_timer : SceneTreeTimer = null

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
		# Position next to record button
		record_hbox.move_child(rec_indicator, 2)
		
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.35)

func _process(delta: float) -> void:
	if _recording:
		_practice_time += delta
		if _mic_mode:
			_process_real_audio(delta)
		else:
			_sim_timer += delta
			if _sim_timer >= 1.2:
				_sim_timer = 0.0
				_simulate_tick()
			
	_update_breath_physics(delta)

func _set_labels() -> void:
	($Root/TopBar/TopM/TopH/BackBtn    as Button).text = "Quay lại"
	
	var diff := "Cơ bản"
	if CourseMap.active_lesson_id == "Node3":
		diff = "Trung bình"
	elif CourseMap.active_lesson_id == "Node4":
		diff = "Nâng cao"
		
	var title_lbl := "Hơi thở & che lỗ cơ bản"
	if current_song_title != "":
		title_lbl = current_song_title
		diff = "Bài hát"
	else:
		if CourseMap.active_lesson_id == "Node3":
			title_lbl = "Luyện Ngón Sáo Trúc"
		elif CourseMap.active_lesson_id == "Node4":
			title_lbl = "Nhấp Ngón Kỹ Thuật"

	($Root/TopBar/TopM/TopH/LessonTag  as Label).text  = "SÁO TRÚC  ·  KỸ THUẬT  ·  %s" % diff.to_upper()
	($Root/TopBar/TopM/TopH/LessonTitle as Label).text = title_lbl
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
	_active_player.volume_db = -3.0
	add_child(_active_player)
	_active_player.play()

func _play_preview_or_sound() -> void:
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
		if visualizer and _mic_mode: visualizer.visible = true
		_play_flute_sound(_get_current_note())
		
		# Reset AI tracking
		_practice_time = 0.0
		_detected_onsets.clear()
		_pitch_scores.clear()
		_breath_scores.clear()
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
		var target_freq = FREQS.get(target_note, 261.63)
		var is_overblowing := _breath_pressure > 82.0
		var scale_mult := 2.0 if is_overblowing else 1.0
		var effective_target_freq : float = target_freq * scale_mult
		
		var cents = 1200.0 * log(pitch / effective_target_freq) / log(2.0)
		if abs(cents) < 50.0:
			pitch_note.text = target_note + ("²" if is_overblowing else "")
			
			# Scaled tolerance based on difficulty scale
			var tolerance_cents = 12.0 / visualizer.difficulty_tolerance_scale
			if abs(cents) < tolerance_cents:
				pitch_status.text = "Đúng cao độ" + (" (Quãng 2)" if is_overblowing else "")
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
			_breath_scores.append(visualizer.current_breath_purity)
			
			# Advance note
			_note_idx = (_note_idx + 1) % sheet_notes.size()
			_build_notation()
			_update_target_indicator()
			
			# Dynamic AI scoring
			var rhythm_score = visualizer.evaluate_rhythm(_detected_onsets, _reference_onsets, 0.3 * visualizer.difficulty_tolerance_scale)
			var avg_pitch_score = _get_average_score(_pitch_scores, 80.0)
			var avg_breath_score = _get_average_score(_breath_scores, 80.0)
			
			_score = visualizer.calculate_composite_score(avg_pitch_score, rhythm_score, 100.0, avg_breath_score)
			_refresh_score()
			_update_rhythm_real()
			rhythm_acc.text = "Nhịp điệu: %d%% | Cột hơi: %d%%" % [int(rhythm_score), int(avg_breath_score)]
			
			# Flute sound effect play
			_play_flute_sound(target_note)
			
			# Auto update covered states fingerings for visual help
			var target_fingering = FINGERINGS.get(target_note, [false, false, false, false, false, false])
			_covered_states = target_fingering.duplicate()
			_build_flute()
			
			_va_say("Tuyệt vời! Tiếng sáo rất trong.")
			_eval_cooldown = 1.0
			return
			
		# Check if it matches another note in the scale
		var detected_note := ""
		var closest_note := ""
		var min_diff := 999999.0
		for note in FREQS.keys():
			var note_freq = FREQS[note] * scale_mult
			var diff = abs(pitch - note_freq)
			if diff < min_diff:
				min_diff = diff
				closest_note = note
				
		if closest_note != "" and min_diff < 30.0:
			detected_note = closest_note + ("²" if is_overblowing else "")
			pitch_note.text = detected_note
			pitch_status.text = "Lệch cao độ (Cần: %s%s)" % [target_note, "²" if is_overblowing else ""]
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

func _show_custom_hint() -> void:
	var popup_scene := load("res://scenes/CustomPopup.tscn") as PackedScene
	if popup_scene:
		var popup = popup_scene.instantiate()
		add_child(popup)
		var text := "[b]🎵 HƠI THỞ:[/b]\nThổi hơi đều, ổn định, không quá mạnh để tránh bị quá quãng (overblow).\n\n[b]🎵 THẾ BẤM CHE LỖ:[/b]\nĐặt các đầu ngón tay phủ kín hoàn toàn các lỗ sáo sẫm màu theo thế bấm nốt nhạc mục tiêu.\n\n[b]💡 HƯỚNG DẪN KỸ THUẬT:[/b]\n• Giữ môi khép nhẹ, thổi luồng hơi tập trung.\n• Thả lỏng cổ tay và ngón tay khi che lỗ sáo.\n• Lắng nghe cao độ phản hồi để điều chỉnh thế bấm.\n• Luyện tập hơi dài và đều đặn mỗi ngày."
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
		var p := randf_range(70, 92)
		var r := randf_range(65, 90)
		var t := clampf((_score * 3.0 - p - r), 60, 95)
		
		var next_lesson_name := "Khóa Học Tiếp"
		if CourseMap.active_lesson_id == "Node2":
			next_lesson_name = "Luyện Ngón"
		elif CourseMap.active_lesson_id == "Node3":
			next_lesson_name = "Nhấp Ngón"
			
		popup.setup_result(_score, p, r, t, 80, "Đã mở khóa: " + next_lesson_name)

func _reset() -> void:
	_note_idx = 0
	_score = 75.0
	_eval_cooldown = 0.0
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
	# Placeholder: in future integrate microphone input + FFT/pitch detection
	_sim_timer = 0.0

func _stop_pitch_detection() -> void:
	_sim_timer = 0.0

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
		if _mic_mode and visualizer and visualizer.current_amplitude_db > -60.0:
			# Microphone volume-driven breath pressure
			var db = visualizer.current_amplitude_db
			target_breath = clamp((db + 60.0) / 45.0, 0.0, 1.0) * 100.0
		else:
			# Automatically simulate natural breath with slight organic lung pressure wobbling
			target_breath = 65.0 + sin(Time.get_ticks_msec() * 0.005) * 2.5
	else:
		# Decay breath pressure to 0 when not blowing
		target_breath = 0.0
		
	_breath_pressure = lerp(_breath_pressure, target_breath, 0.15)
	breath_progress.value = _breath_pressure
	
	var flute_body := $Root/FluteBoard/BoardM/BoardVBox/FluteFrame/FluteM/FluteStack/FluteBody as Control
	if flute_body:
		var overblown := _breath_pressure > 82.0
		if flute_body.get("is_overblowing") != overblown:
			flute_body.set("is_overblowing", overblown)
			flute_body.queue_redraw()
	
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
		_rec_tween.tween_property(rec_indicator, "scale", Vector2(1.0, 1.0), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _get_average_score(scores: Array, default_val: float) -> float:
	if scores.size() == 0:
		return default_val
	var sum := 0.0
	for s in scores:
		sum += s
	return sum / scores.size()

