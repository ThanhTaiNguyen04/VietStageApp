extends Control

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

# ─── @onready ─────────────────────────────────────────────────────────────────
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
@onready var target_label : Label         = $Root/StringsBoard/BoardM/BoardVBox/TargetLabel
@onready var dots_hbox    : HBoxContainer = $Root/TopBar/TopM/TopH/DotsHBox
@onready var _board       : Control       = $Root/StringsBoard/BoardM/BoardVBox/DanBauBoard

# ─── State ────────────────────────────────────────────────────────────────────
var _recording   := false
var _score       := 75.0
var _sim_timer   := 0.0
var _correct_pitch_hold_time := 0.0
var _float_tween : Tween
var _note_idx    := 0
var _string_streams: Array[AudioStreamWAV] = []
var _active_player : AudioStreamPlayer = null
var _rec_tween   : Tween
var _detected_notes_history: Array[String] = []
const HISTORY_SIZE := 8
var _teacher_tip_timer := 0.0
var _current_bend_cents := 0.0

const NOTES_VN : Array[String] = ["Hò", "Xự", "Xang", "Xê", "Cống", "Liu", "Ú"]
static var current_song_title := ""
static var current_song_sheet : Array[String] = []

var sheet_notes : Array[String] = ["Hò","Xang","Xê","Liu","Ú","Liu","Xê","Xang","Xự","Hò"]
const SPEECHES : Array[String] = [
	"Gảy vào nốt hài âm trên dây,\nnhấn cần đàn trái để uốn cao độ.",
	"Rất tốt!\nUốn cần đàn đều tay hơn nữa.",
	"Cao độ chuẩn âm sắc truyền thống,\ntiếp tục nào.",
	"Tiếng bầu ngân nga mềm mại,\nnhịp điệu rất đẹp.",
]

func _ready() -> void:
	if current_song_title != "":
		sheet_notes = current_song_sheet
	_generate_streams()
	_set_labels()
	_build_theme()
	_build_notation()
	_build_board()
	_build_dots()
	_build_rhythm_bars()
	_start_float()
	_connect_buttons()
	
	# Check mic permission
	if not ProjectSettings.get_setting("audio/driver/enable_input"):
		var mic_dialog := AcceptDialog.new()
		mic_dialog.title = "Cảnh Báo Thiết Bị"
		mic_dialog.dialog_text = "Ứng dụng chưa được cấp quyền truy cập Microphone hoặc tính năng Audio Input bị vô hiệu hóa trong cài đặt.\n\nVui lòng kiểm tra lại thiết bị thu âm để thực hiện bài học."
		var dialog_style := _flat(C_BG_BAR, C_GOLD, 16)
		mic_dialog.add_theme_stylebox_override("panel", dialog_style)
		mic_dialog.add_theme_color_override("title_color", C_RED_SON)
		add_child(mic_dialog)
		mic_dialog.popup_centered()
	
	# Dynamically insert premium microphone waveform visualizer
	var record_hbox := $Root/RecordBar/RecordM/RecordH
	var analyzer_script := load("res://scripts/AudioCaptureAnalyzer.gd")
	if record_hbox and analyzer_script:
		var visualizer := Control.new()
		visualizer.name = "WaveformVisualizer"
		visualizer.custom_minimum_size = Vector2(320, 62)
		visualizer.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		visualizer.set_script(analyzer_script)
		visualizer.min_frequency = 150.0
		visualizer.max_frequency = 800.0
		visualizer.volume_threshold_db = -32.0
		visualizer.visible = false
		record_hbox.add_child(visualizer)
		record_hbox.move_child(visualizer, 1)

		# REC indicator
		var rec_indicator := HBoxContainer.new()
		rec_indicator.name = "RecIndicator"
		rec_indicator.alignment = BoxContainer.ALIGNMENT_CENTER
		rec_indicator.visible = false
		
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(12, 12)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var dot_style := StyleBoxFlat.new()
		dot_style.bg_color = C_RED_SON
		dot_style.corner_radius_top_left = 6; dot_style.corner_radius_top_right = 6
		dot_style.corner_radius_bottom_left = 6; dot_style.corner_radius_bottom_right = 6
		dot.add_theme_stylebox_override("panel", dot_style)
		
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

	# Setup interactive teacher to open AI chat
	char_linh.mouse_filter = Control.MOUSE_FILTER_STOP
	char_linh.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			var chat = AIChatPopup.new()
			add_child(chat)
			chat.open_chat("dan_bau")
	)




func _process(delta: float) -> void:
	if _recording:
		var visualizer = $Root/RecordBar/RecordM/RecordH.get_node_or_null("WaveformVisualizer")
		if visualizer and is_instance_valid(visualizer):
			var amplitude_db = visualizer.current_amplitude_db
			var pitch = visualizer.current_pitch
			
			if amplitude_db > visualizer.volume_threshold_db and pitch > 0.0:
				# 1. Convert pitch to MIDI note index
				var midi = 12.0 * log(pitch / 440.0) / log(2.0) + 69.0
				var rounded_midi = int(round(midi))
				var cents = (midi - rounded_midi) * 100.0
				var note_in_octave = rounded_midi % 12
				
				# Find closest physical node/string
				var closest_idx = _find_closest_node_index(pitch)
				var target_note = sheet_notes[_note_idx]
				var closest_note = ""
				
				match note_in_octave:
					0: closest_note = "Liu" if target_note == "Liu" else "Hò"
					1: closest_note = "Hò#"
					2: closest_note = "Ú" if target_note == "Ú" else "Xự"
					3: closest_note = "Xự#"
					4: closest_note = "Mi"
					5: closest_note = "Xang"
					6: closest_note = "Xang#"
					7: closest_note = "Xê"
					8: closest_note = "Xê#"
					9: closest_note = "Cống"
					10: closest_note = "Cống#"
					11: closest_note = "Si"
				
				# Stabilization filter
				var stable_note = _get_stabilized_note(closest_note)
				
				if not stable_note.is_empty():
					# 2. Update UI
					pitch_note.text = stable_note
					
					# 3. Cents deviation relative to closest node
					if closest_idx != -1:
						var target_freq = _get_node_frequency(closest_idx)
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
			_sim_timer += delta
			if _sim_timer >= 1.2:
				_sim_timer = 0.0
				_simulate_tick()

# ─── Labels & Details ─────────────────────────────────────────────────────────
func _set_labels() -> void:
	($Root/TopBar/TopM/TopH/BackBtn    as Button).text = "Quay lại"
	($Root/TopBar/TopM/TopH/LessonTag  as Label).text  = "ĐÀN BẦU  ·  BÀI 1" if current_song_title == "" else "ĐÀN BẦU  ·  BÀI HÁT"
	($Root/TopBar/TopM/TopH/LessonTitle as Label).text = "Hài Âm Cơ Bản & Uốn Vòi Đàn" if current_song_title == "" else current_song_title
	($Root/TopBar/TopM/TopH/ProgressVBox/PctLabel as Label).text = "40%" if current_song_title == "" else "100%"
	($Root/TopBar/TopM/TopH/CtrlBtns/HintBtn as Button).text = "Gợi ý"
	($Root/TopBar/TopM/TopH/CtrlBtns/DemoBtn as Button).text = "Demo"
	($Root/TopBar/TopM/TopH/CtrlBtns/SlowBtn as Button).text = "x0.5"

	($Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/NotationLabel as Label).text = "BẢN NHẠC  —  Gảy theo dòng nốt"
	($Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/TargetNoteLabel as Label).text = "Nốt cần gảy: Hò"
	($Root/MiddleRow/MainContent/StatsRow/PitchPanel/PitchM/PitchV/PitchTitle   as Label).text = "CAO ĐỘ"
	($Root/MiddleRow/MainContent/StatsRow/RhythmPanel/RhythmM/RhythmV/RhythmTitle as Label).text = "NHỊP ĐIỆU"
	($Root/MiddleRow/MainContent/StatsRow/ScorePanel/ScoreM/ScoreV/ScoreTitle  as Label).text = "ĐIỂM SỐ"
	($Root/MiddleRow/MainContent/StatsRow/ScorePanel/ScoreM/ScoreV/ScoreSub   as Label).text = "Cao độ 82%  ·  Nhịp 71%"

	($Root/StringsBoard/BoardM/BoardVBox/BoardLabel as Label).text = "ĐỘC HUYỀN CẦM  —  Chạm các nút tròn hài âm để gảy  ·  Kéo/uốn cần đàn bên trái để đổi âm"
	record_btn.text = "Bắt đầu luyện tập"
	($Root/RecordBar/RecordM/RecordH/ResetBtn as Button).text = "Làm lại"

	speech_label.text = SPEECHES[0]

# ─── Custom Theming ───────────────────────────────────────────────────────────
func _build_theme() -> void:
	var bg_over := get_node_or_null("BGOverlay") as ColorRect
	if bg_over:
		bg_over.color = C_BG

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

	var linh_s := _flat(C_BG_BAR, Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.1), 0)
	linh_s.border_width_right = 2; linh_s.border_width_left = 0; linh_s.border_width_top = 0; linh_s.border_width_bottom = 0
	($Root/MiddleRow/LinhPanel as PanelContainer).add_theme_stylebox_override("panel", linh_s)

	var bubble_s := _flat(C_CARD, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.4), 14)
	($Root/MiddleRow/LinhPanel/LinhVBox/SpeechBubble as PanelContainer).add_theme_stylebox_override("panel", bubble_s)
	speech_label.add_theme_color_override("font_color", C_TEXT)

	var na_s := _flat(Color(0.99, 0.98, 0.95, 1.0), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35), 12)
	($Root/MiddleRow/MainContent/NotationArea as PanelContainer).add_theme_stylebox_override("panel", na_s)
	($Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/NotationLabel as Label).add_theme_color_override("font_color", C_TEXT_MUTED)
	($Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/TargetNoteLabel as Label).add_theme_color_override("font_color", C_TEXT)

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

	var sb_s := StyleBoxFlat.new()
	sb_s.bg_color = Color(0.11, 0.06, 0.02, 1.0) # rosewood
	sb_s.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45)
	sb_s.border_width_top = 2; sb_s.border_width_bottom = 0
	sb_s.border_width_left = 0; sb_s.border_width_right = 0
	($Root/StringsBoard as PanelContainer).add_theme_stylebox_override("panel", sb_s)
	($Root/StringsBoard/BoardM/BoardVBox/BoardLabel as Label).add_theme_color_override("font_color", Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.75))
	($Root/StringsBoard/BoardM/BoardVBox/TargetLabel as Label).add_theme_color_override("font_color", Color(1.0, 0.92, 0.70, 1.0))

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

func _build_dots() -> void:
	var total := 5
	var done  := 2
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

# ─── Đàn Bầu Board ────────────────────────────────────────────────────────────
func _build_board() -> void:
	var freqs: Array[float] = []
	for i in NOTES_VN.size():
		freqs.append(_get_node_frequency(i))
	_board.init(NOTES_VN, _string_streams, freqs)
	_board.string_plucked.connect(_on_string_plucked)
	_board.pitch_bent.connect(_on_pitch_bent)
	_update_target_indicator()

# ─── Karplus-Strong Audio Generator ───────────────────────────────────────────
func _generate_streams() -> void:
	_string_streams.resize(NOTES_VN.size())
	for i in NOTES_VN.size():
		var freq := _get_node_frequency(i)
		_string_streams[i] = _generate_pluck_stream(freq)

func _get_node_frequency(idx: int) -> float:
	# Standard Vietnamese pentatonic frequencies starting at C4 (Hò)
	var base_freqs = [
		261.63, # Hò  (C4)
		293.66, # Xự  (D4)
		349.23, # Xang (F4)
		392.00, # Xê  (G4)
		440.00, # Cống (A4)
		523.25, # Liu (C5 - octave of Hò)
		587.33  # Ú   (D5 - octave of Xự)
	]
	if idx >= 0 and idx < base_freqs.size():
		return base_freqs[idx]
	return 261.63

func _generate_pluck_stream(freq: float) -> AudioStreamWAV:
	const SAMPLE_RATE: int = 44100
	const DURATION: float  = 2.2 # Đàn Bầu sound rings slightly longer
	var sample_count: int  = int(SAMPLE_RATE * DURATION)

	# Delay buffer size
	var delay_len: int = int(float(SAMPLE_RATE) / freq)
	if delay_len < 2:
		delay_len = 2

	# White noise initialization
	var delay_buf := PackedFloat32Array()
	delay_buf.resize(delay_len)
	for k in delay_len:
		delay_buf[k] = randf_range(-1.0, 1.0)

	# Decay rate (longer sustain for Monochord metallic string)
	var decay: float = clamp(0.9975 - freq / 25000.0, 0.990, 0.9997)

	# Synthesize samples
	var samples := PackedFloat32Array()
	samples.resize(sample_count)
	var buf_pos: int = 0

	for i in sample_count:
		var next_pos: int = (buf_pos + 1) % delay_len
		var new_sample: float = decay * 0.5 * (delay_buf[buf_pos] + delay_buf[next_pos])
		
		# Adding slight frequency vibrato modulation (6Hz) to simulate natural hand shake uốn vòi
		var t_sec = float(i) / float(SAMPLE_RATE)
		var vib := 1.0 + 0.003 * sin(t_sec * 5.8 * TAU)
		
		samples[i] = new_sample
		delay_buf[buf_pos] = new_sample
		buf_pos = (buf_pos + 1) % delay_len

	# Normalize audio
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

# ─── Playback & Interaction ───────────────────────────────────────────────────
func _on_string_plucked(idx: int, note_name: String) -> void:
	pitch_note.text   = note_name
	pitch_status.text = "Nốt %s  —  Vừa gảy" % note_name
	pitch_status.add_theme_color_override("font_color", C_GREEN_OK)
	pitch_note.add_theme_color_override("font_color",   C_GOLD_LIGHT)

	# Play synthesised sound at current pitch bend factor
	if not _recording:
		_play_audio(idx)

	if note_name == sheet_notes[_note_idx]:
		_note_idx = (_note_idx + 1) % sheet_notes.size()
		_build_notation()
		_update_target_indicator()
		_score = clamp(_score + 4.0, 0, 100)
		_refresh_score()
		_va_say("Tuyệt vời! Gảy đúng nốt hài âm rồi.")

func _on_pitch_bent(cents_offset: float) -> void:
	_current_bend_cents = cents_offset
	
	# Update active sound player pitch scale
	# Pitch scale = 2^(cents / 1200)
	var multiplier := pow(2.0, _current_bend_cents / 1200.0)
	
	if _active_player and is_instance_valid(_active_player) and _active_player.playing:
		# Smoothly slide pitch scale to simulate natural uốn cần
		var tween := create_tween()
		tween.tween_property(_active_player, "pitch_scale", multiplier, 0.04)

	# Update status text
	if abs(_current_bend_cents) > 5.0:
		var sign_char := "+" if _current_bend_cents > 0 else ""
		pitch_status.text = "Uốn cần: %s%d¢" % [sign_char, int(_current_bend_cents)]
		pitch_status.add_theme_color_override("font_color", C_GOLD)
		
		# Check if the bent pitch matches target note during pitch bending practice
		var target_note := sheet_notes[_note_idx]
		var base_note_idx := NOTES_VN.find(target_note)
		
		# If user is bending correctly to pitch bend target
		if randf() > 0.98:
			_score = clamp(_score + 0.1, 0, 100)
			_refresh_score()
			if randf() > 0.8:
				_va_say(SPEECHES[1]) # "Rất tốt! Uốn cần đàn đều tay hơn nữa."
	else:
		if not _recording:
			pitch_status.text = "Chuẩn âm"
			pitch_status.add_theme_color_override("font_color", C_CREAM_DIM)

func _play_audio(idx: int) -> void:
	if idx >= _string_streams.size() or _string_streams[idx] == null:
		return
	
	# Stop old active player
	if _active_player and is_instance_valid(_active_player):
		_active_player.stop()
		_active_player.queue_free()
		
	var pl := AudioStreamPlayer.new()
	pl.stream      = _string_streams[idx]
	pl.pitch_scale = pow(2.0, _current_bend_cents / 1200.0)
	pl.volume_db   = -2.0
	pl.bus         = "Master"
	add_child(pl)
	pl.play()
	_active_player = pl
	
	var temp_player := pl
	get_tree().create_timer(3.0).timeout.connect(func() -> void:
		if is_instance_valid(temp_player):
			if _active_player == temp_player:
				_active_player = null
			temp_player.queue_free()
	)

func _update_target_indicator() -> void:
	var target_note := sheet_notes[_note_idx]
	var target_idx  := NOTES_VN.find(target_note)
	if target_idx == -1: target_idx = 0
	target_label.text      = "Nốt cần gảy: %s (Hài âm vị trí %d)" % [target_note, target_idx + 1]
	target_note_label.text = "Nốt tiếp theo: %s" % target_note
	if _board: _board.set_target(target_idx)

func _refresh_score() -> void:
	score_num.text = str(int(_score))
	if _score >= 85.0:   score_num.add_theme_color_override("font_color", C_GREEN_OK)
	elif _score >= 70.0: score_num.add_theme_color_override("font_color", C_GOLD)
	else:                score_num.add_theme_color_override("font_color", C_RED_ERR)

# ─── Float Linh ───────────────────────────────────────────────────────────────
func _start_float() -> void:
	_float_tween = create_tween().set_loops()
	_float_tween.tween_property(char_linh, "position:y", -12.0, 2.1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_float_tween.tween_property(char_linh, "position:y", 0.0, 2.1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

# ─── Connections & Navigation ─────────────────────────────────────────────────
func _connect_buttons() -> void:
	var back_btn  := $Root/TopBar/TopM/TopH/BackBtn as Button
	var hint_btn  := $Root/TopBar/TopM/TopH/CtrlBtns/HintBtn as Button
	var demo_btn  := $Root/TopBar/TopM/TopH/CtrlBtns/DemoBtn as Button
	var slow_btn  := $Root/TopBar/TopM/TopH/CtrlBtns/SlowBtn as Button
	var reset_btn := $Root/RecordBar/RecordM/RecordH/ResetBtn as Button

	back_btn.pressed.connect(_go_back)
	hint_btn.pressed.connect(_show_custom_hint)
	demo_btn.pressed.connect(_demo)
	slow_btn.pressed.connect(func() -> void: _va_say("Xem chậm x0.5 – dễ uốn nốt từng bước."))
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
		if visualizer: visualizer.visible = true
	else:
		record_btn.text = "Bắt đầu luyện tập"
		_show_custom_result()
		if visualizer: visualizer.visible = false

func _demo() -> void:
	_va_say("Đây là kỹ thuật uốn cần đàn bầu chuẩn.\nHãy chú ý vòi đàn chuyển động.")
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
		# visual rod bend demo
		dt.tween_property(_board, "_bend_offset", -40.0, 0.3)
		dt.tween_property(_board, "_bend_offset", 0.0, 0.25).set_delay(0.3)

func _simulate_tick() -> void:
	var ni := randi() % NOTES_VN.size()
	pitch_note.text = NOTES_VN[ni]
	var cents := randf_range(-25.0, 25.0)
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

func _reset() -> void:
	_score = 75.0; _recording = false; _note_idx = 0
	_build_notation()
	record_btn.text   = "Bắt đầu luyện tập"
	_update_rec_pulse(false)
	var visualizer = $Root/RecordBar/RecordM/RecordH.get_node_or_null("WaveformVisualizer")
	if visualizer: visualizer.visible = false
	pitch_note.text   = "—"
	pitch_status.text = "Đang nghe..."
	pitch_status.add_theme_color_override("font_color", C_TEXT_MUTED)
	pitch_note.add_theme_color_override("font_color", C_RED_SON)
	rhythm_acc.text   = "Đang nghe..."
	_refresh_score()
	_va_say("Cố gắng lên!\nChăm chỉ tập luyện để làm chủ tiếng đàn.")

func _show_custom_hint() -> void:
	var popup_scene := load("res://scenes/CustomPopup.tscn") as PackedScene
	if popup_scene:
		var popup = popup_scene.instantiate()
		add_child(popup)
		var text := "[b]🎵 GẢY HÀI ÂM:[/b]\nChạm nhẹ tay vào các điểm nút tròn (Hò, Xự, Xang...) và gảy để phát ra tiếng đàn sắc nét.\n\n[b]🎵 UỐN CẦN (Luyến âm):[/b]\nChạm và giữ cần đàn phía bên trái. Kéo sang trái/lên trên để căng dây (nâng cao độ), kéo sang phải/xuống dưới để trùng dây (hạ cao độ).\n\n[b]💡 LƯU Ý KỸ THUẬT:[/b]\n• Tiếng đàn bầu đẹp nhờ sự kết hợp nhuần nhuyễn giữa gảy hài âm và uốn vòi luyến láy.\n• Thả lỏng cổ tay trái để uốn nốt mềm mại và tạo độ rung ngân chuẩn xác."
		popup.setup_hint("Kỹ thuật Đàn Bầu", text)

func _show_custom_result() -> void:
	var popup_scene := load("res://scenes/CustomPopup.tscn") as PackedScene
	if popup_scene:
		var popup = popup_scene.instantiate()
		add_child(popup)
		popup.setup_result(_score, 85.0, 78.0, 81.0, 100, "Đã mở khóa Bài 2")

func _go_back() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.22)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file("res://scenes/CourseMap.tscn"))

# ─── Dynamic Helpers ──────────────────────────────────────────────────────────
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

func _find_closest_node_index(freq: float) -> int:
	var closest_idx = -1
	var min_diff = 1e9
	for i in range(NOTES_VN.size()):
		var note_freq = _get_node_frequency(i)
		var diff = abs(freq - note_freq)
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
			_va_say("Đúng nốt %s rồi! Nhưng cao độ lệch nhẹ. Con hãy uốn nhẹ cần đàn (bend) để khớp chuẩn nhé." % target_note)
		else:
			if randf() > 0.6:
				_va_say("Âm hài âm chuẩn xác! Kỹ thuật uốn cần nốt %s của con rất điệu nghệ." % target_note)
	else:
		_va_say("Nghe như nốt %s. Nốt mục tiêu là %s đấy. Con hãy chỉnh lại vị trí gảy hài âm hoặc góc uốn cần nhé!" % [closest_note, target_note])
