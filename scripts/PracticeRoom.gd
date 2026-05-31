extends Control

# ─── Color Palette ─────────────────────────────────────────────────────────────
const C_GOLD       := Color(0.95, 0.72, 0.18, 1.0)
const C_GOLD_LIGHT := Color(1.00, 0.87, 0.45, 1.0)
const C_JADE       := Color(0.18, 0.62, 0.42, 1.0)
const C_RED_SON    := Color(0.72, 0.12, 0.08, 1.0)
const C_CREAM      := Color(1.00, 0.97, 0.88, 1.0)
const C_CREAM_DIM  := Color(0.80, 0.76, 0.66, 1.0)
const C_GREEN_OK   := Color(0.28, 0.85, 0.48, 1.0)
const C_WARN       := Color(0.95, 0.75, 0.18, 1.0)
const C_RED_ERR    := Color(0.90, 0.25, 0.18, 1.0)

# ─── @onready ─────────────────────────────────────────────────────────────────
@onready var char_linh    : TextureRect   = $Root/MiddleRow/LinhPanel/LinhVBox/CharLinh
@onready var speech_label : Label         = $Root/MiddleRow/LinhPanel/LinhVBox/SpeechBubble/SpeechM/SpeechLabel
@onready var lesson_bar   : ProgressBar   = $Root/TopBar/TopM/TopH/ProgressVBox/LessonBar
@onready var pitch_note   : Label         = $Root/MiddleRow/MainContent/StatsRow/PitchPanel/PitchM/PitchV/PitchNote
@onready var pitch_status : Label         = $Root/MiddleRow/MainContent/StatsRow/PitchPanel/PitchM/PitchV/PitchStatus
@onready var rhythm_bars  : HBoxContainer = $Root/MiddleRow/MainContent/StatsRow/RhythmPanel/RhythmM/RhythmV/RhythmBars
@onready var rhythm_acc   : Label         = $Root/MiddleRow/MainContent/StatsRow/RhythmPanel/RhythmM/RhythmV/RhythmAcc
@onready var score_num    : Label         = $Root/MiddleRow/MainContent/StatsRow/ScorePanel/ScoreM/ScoreV/ScoreNum
@onready var record_btn   : Button        = $Root/MiddleRow/RightPanel/RecordBar/RecordM/RecordH/RecordBtn
@onready var notes_hbox   : HBoxContainer = $Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/NotesScroll/NotesHBox
@onready var target_note_label : Label    = $Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/TargetNoteLabel
@onready var strings_hbox : VBoxContainer = $Root/MiddleRow/RightPanel/StringsBoard/BoardM/BoardVBox/StringsFrame/StringsM/StringsHBox
@onready var target_label : Label         = $Root/MiddleRow/RightPanel/StringsBoard/BoardM/BoardVBox/TargetLabel
@onready var hint_dialog  : AcceptDialog  = $HintDialog
@onready var result_dialog: AcceptDialog  = $ResultDialog
@onready var dots_hbox    : HBoxContainer = $Root/TopBar/TopM/TopH/DotsHBox

# ─── State ────────────────────────────────────────────────────────────────────
var _recording   := false
var _score       := 75.0
var _sim_timer   := 0.0
var _float_tween : Tween
var _note_idx    := 2

const NOTES_VN : Array[String] = ["Hò", "Xự", "Xang", "Xê", "Công", "Liu", "Ú"]
const SHEET    : Array[String] = ["Hò","Hò","Xự","Xang","Xang","Xê","Công","Xê","Xang","Xự","Hò"]
const SPEECHES : Array[String] = [
	"Gảy nhẹ dây số 3,\nnhấn rung bên trái nhạn đàn.",
	"Rất tốt!\nGiữ ngón cố định hơn nhé.",
	"Cao độ đang chuẩn,\ntiếp tục nào.",
	"Âm rung mềm mại,\nnhịp đều hơn nhé.",
	"Cổ tay thả lỏng,\ngảy dứt khoát hơn.",
]

func _ready() -> void:
	_set_labels()
	_build_theme()
	_build_notation()
	_build_strings()
	_build_dots()
	_build_rhythm_bars()
	_start_float()
	_connect_buttons()
	
	# Dynamically insert premium real-time microphone waveform visualizer!
	var record_hbox := $Root/MiddleRow/RightPanel/RecordBar/RecordM/RecordH
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
		
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.35)

func _process(delta: float) -> void:
	if _recording:
		_sim_timer += delta
		if _sim_timer >= 1.2:
			_sim_timer = 0.0
			_simulate_tick()

# ─── Labels ───────────────────────────────────────────────────────────────────
func _set_labels() -> void:
	($Root/TopBar/TopM/TopH/BackBtn    as Button).text = "Quay lại"
	($Root/TopBar/TopM/TopH/LessonTag  as Label).text  = "ĐÀN TRANH  ·  BÀI 4"
	($Root/TopBar/TopM/TopH/LessonTitle as Label).text = "Kỹ Thuật Nhấn Dây & Rung Âm"
	($Root/TopBar/TopM/TopH/ProgressVBox/PctLabel as Label).text = "60%"
	($Root/TopBar/TopM/TopH/CtrlBtns/HintBtn as Button).text = "Gợi ý"
	($Root/TopBar/TopM/TopH/CtrlBtns/DemoBtn as Button).text = "Demo"
	($Root/TopBar/TopM/TopH/CtrlBtns/SlowBtn as Button).text = "x0.5"

	($Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/NotationLabel as Label).text = "BẢN NHẠC  —  Gảy theo dòng nốt"
	($Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/TargetNoteLabel as Label).text = "Nốt cần gảy: Hò"
	($Root/MiddleRow/MainContent/StatsRow/PitchPanel/PitchM/PitchV/PitchTitle   as Label).text = "CAO ĐỘ"
	($Root/MiddleRow/MainContent/StatsRow/RhythmPanel/RhythmM/RhythmV/RhythmTitle as Label).text = "NHỊP ĐIỆU"
	($Root/MiddleRow/MainContent/StatsRow/ScorePanel/ScoreM/ScoreV/ScoreTitle  as Label).text = "ĐIỂM SỐ"
	($Root/MiddleRow/MainContent/StatsRow/ScorePanel/ScoreM/ScoreV/ScoreSub   as Label).text = "Cao độ 82%  ·  Nhịp 71%"

	($Root/MiddleRow/RightPanel/StringsBoard/BoardM/BoardVBox/BoardLabel as Label).text = "ĐÀN TRANH 16 DÂY  —  Chạm dây để gảy"
	record_btn.text = "Bắt đầu luyện tập"
	($Root/MiddleRow/RightPanel/RecordBar/RecordM/RecordH/ResetBtn as Button).text = "Làm lại"

	speech_label.text = SPEECHES[0]

	hint_dialog.title = "Gợi ý kỹ thuật"
	hint_dialog.dialog_text = "Khi nhấn dây đàn tranh tạo rung âm:\n\n• Dùng đầu ngón trỏ tay trái\n• Nhấn nhẹ phía trái của nhạn đàn 2-3mm\n• Kéo dây rồi thả nhẹ nhàng\n• Giữ nhịp 2 lần rung mỗi phách\n• Đầu ngón tay vuông góc với dây"

# ─── Theme ────────────────────────────────────────────────────────────────────
func _build_theme() -> void:
	# Top bar
	var top_s := _flat(Color(0.05, 0.025, 0.010, 0.98), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25), 0)
	top_s.border_width_bottom = 2; top_s.border_width_top = 0; top_s.border_width_left = 0; top_s.border_width_right = 0
	($Root/TopBar as PanelContainer).add_theme_stylebox_override("panel", top_s)

	($Root/TopBar/TopM/TopH/LessonTag   as Label).add_theme_color_override("font_color", Color(C_GOLD.r,C_GOLD.g,C_GOLD.b,0.7))
	($Root/TopBar/TopM/TopH/LessonTitle as Label).add_theme_color_override("font_color", C_CREAM)
	($Root/TopBar/TopM/TopH/ProgressVBox/PctLabel as Label).add_theme_color_override("font_color", C_CREAM_DIM)
	_style_progress_bar(lesson_bar, C_GOLD, Color(0,0,0,0.4))

	var back := $Root/TopBar/TopM/TopH/BackBtn as Button
	_style_text_btn(back, C_GOLD, C_GOLD_LIGHT)
	for bn in ["HintBtn","DemoBtn","SlowBtn"]:
		_style_outlined_btn($Root/TopBar/TopM/TopH/CtrlBtns.get_node(bn) as Button)

	# Linh panel
	var linh_s := _flat(Color(0.06, 0.03, 0.012, 0.96), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.22), 0)
	linh_s.border_width_right = 2; linh_s.border_width_left = 0; linh_s.border_width_top = 0; linh_s.border_width_bottom = 0
	($Root/MiddleRow/LinhPanel as PanelContainer).add_theme_stylebox_override("panel", linh_s)

	var bubble_s := _flat(Color(0.20, 0.12, 0.04, 0.92), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.5), 14)
	($Root/MiddleRow/LinhPanel/LinhVBox/SpeechBubble as PanelContainer).add_theme_stylebox_override("panel", bubble_s)
	speech_label.add_theme_color_override("font_color", C_CREAM)

	# Notation area — warm amber "paper"
	var na_s := _flat(Color(0.52, 0.36, 0.08, 1.0), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45), 0)
	($Root/MiddleRow/MainContent/NotationArea as PanelContainer).add_theme_stylebox_override("panel", na_s)
	($Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/NotationLabel as Label).add_theme_color_override("font_color", Color(0.14,0.08,0.02,0.85))
	($Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/TargetNoteLabel as Label).add_theme_color_override("font_color", Color(0.14,0.08,0.02,0.95))

	# Stats panels
	var stat_bg := _flat(Color(0.07, 0.04, 0.015, 0.96), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.18), 0)
	($Root/MiddleRow/MainContent/StatsRow/PitchPanel  as PanelContainer).add_theme_stylebox_override("panel", stat_bg.duplicate())
	($Root/MiddleRow/MainContent/StatsRow/RhythmPanel as PanelContainer).add_theme_stylebox_override("panel", stat_bg.duplicate())
	($Root/MiddleRow/MainContent/StatsRow/ScorePanel  as PanelContainer).add_theme_stylebox_override("panel", stat_bg.duplicate())

	pitch_note.add_theme_color_override("font_color",   C_GOLD)
	pitch_status.add_theme_color_override("font_color", C_CREAM_DIM)
	($Root/MiddleRow/MainContent/StatsRow/PitchPanel/PitchM/PitchV/PitchTitle   as Label).add_theme_color_override("font_color", Color(C_GOLD.r,C_GOLD.g,C_GOLD.b,0.65))
	($Root/MiddleRow/MainContent/StatsRow/RhythmPanel/RhythmM/RhythmV/RhythmTitle as Label).add_theme_color_override("font_color", Color(C_JADE.r,C_JADE.g,C_JADE.b,0.9))
	rhythm_acc.add_theme_color_override("font_color", C_CREAM_DIM)
	($Root/MiddleRow/MainContent/StatsRow/ScorePanel/ScoreM/ScoreV/ScoreTitle as Label).add_theme_color_override("font_color", C_GOLD)
	score_num.add_theme_color_override("font_color", C_GOLD)
	($Root/MiddleRow/MainContent/StatsRow/ScorePanel/ScoreM/ScoreV/ScoreSub   as Label).add_theme_color_override("font_color", C_CREAM_DIM)

	# Strings board — mahogany wood
	var sb_s := _flat(Color(0.12, 0.065, 0.025, 1.0), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.5), 0)
	sb_s.border_width_top = 3; sb_s.border_width_bottom = 0; sb_s.border_width_left = 3; sb_s.border_width_right = 0
	($Root/MiddleRow/RightPanel/StringsBoard as PanelContainer).add_theme_stylebox_override("panel", sb_s)
	($Root/MiddleRow/RightPanel/StringsBoard/BoardM/BoardVBox/BoardLabel as Label).add_theme_color_override("font_color", Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.65))

	# Dan tranh frame
	var frame := $Root/MiddleRow/RightPanel/StringsBoard/BoardM/BoardVBox/StringsFrame as PanelContainer
	var frame_s := _flat(Color(0.16, 0.09, 0.03, 1.0), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35), 10)
	frame.add_theme_stylebox_override("panel", frame_s)
	($Root/MiddleRow/RightPanel/StringsBoard/BoardM/BoardVBox/StringsFrame/BridgeTop as ColorRect).color = Color(0.62, 0.38, 0.12, 1.0)
	($Root/MiddleRow/RightPanel/StringsBoard/BoardM/BoardVBox/StringsFrame/BridgeBottom as ColorRect).color = Color(0.62, 0.38, 0.12, 1.0)
	($Root/MiddleRow/RightPanel/StringsBoard/BoardM/BoardVBox/StringsFrame/BridgeLeft as ColorRect).color = Color(0.50, 0.30, 0.08, 1.0)
	($Root/MiddleRow/RightPanel/StringsBoard/BoardM/BoardVBox/StringsFrame/BridgeRight as ColorRect).color = Color(0.50, 0.30, 0.08, 1.0)

	# Record bar
	var rec_bar_s := _flat(Color(0.05, 0.025, 0.010, 1.0), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.20), 0)
	rec_bar_s.border_width_top = 2; rec_bar_s.border_width_bottom = 0; rec_bar_s.border_width_left = 0; rec_bar_s.border_width_right = 0
	($Root/MiddleRow/RightPanel/RecordBar as PanelContainer).add_theme_stylebox_override("panel", rec_bar_s)

	# Record button
	var rn := _flat(C_RED_SON, Color(1.0, 0.4, 0.2, 0.5), 22)
	rn.shadow_size = 14; rn.shadow_color = Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.40)
	var rh := _flat(C_RED_SON.lightened(0.14), Color(1.0, 0.4, 0.2, 0.7), 22)
	rh.shadow_size = 20; rh.shadow_color = Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.50)
	record_btn.add_theme_stylebox_override("normal",  rn)
	record_btn.add_theme_stylebox_override("hover",   rh)
	record_btn.add_theme_stylebox_override("pressed", _flat(C_RED_SON.darkened(0.18), Color(0,0,0,0.2), 22))
	record_btn.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	record_btn.add_theme_color_override("font_color", Color(1,1,1,1))

	_style_outlined_btn($Root/MiddleRow/RightPanel/RecordBar/RecordM/RecordH/ResetBtn as Button)

# ─── Notation Track ───────────────────────────────────────────────────────────
func _build_notation() -> void:
	for c in notes_hbox.get_children(): c.queue_free()
	for i in SHEET.size():
		var note     := SHEET[i]
		var is_active := i == _note_idx
		var is_done   := i < _note_idx

		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(88, 88)
		var cs := StyleBoxFlat.new()
		cs.border_width_left = 2; cs.border_width_right = 2; cs.border_width_top = 2; cs.border_width_bottom = 2
		cs.corner_radius_top_left = 44; cs.corner_radius_top_right = 44
		cs.corner_radius_bottom_left = 44; cs.corner_radius_bottom_right = 44
		if is_active:
			cs.bg_color     = C_GOLD
			cs.border_color = C_GOLD_LIGHT
			cs.shadow_size  = 18; cs.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.55)
		elif is_done:
			cs.bg_color     = C_JADE
			cs.border_color = Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.8)
		else:
			cs.bg_color     = Color(0.28, 0.18, 0.06, 0.75)
			cs.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25)
		card.add_theme_stylebox_override("panel", cs)

		var lbl := Label.new()
		lbl.text = note
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 24)
		lbl.add_theme_color_override("font_color",
			Color(0.10, 0.05, 0.01, 1) if is_active else C_CREAM)
		card.add_child(lbl)
		notes_hbox.add_child(card)

# ─── Dot progress indicators ──────────────────────────────────────────────────
func _build_dots() -> void:
	var total := 5
	var done  := 2
	for i in total:
		var d := dots_hbox.get_child(i) as ColorRect
		if d:
			d.color = C_GOLD if i < done else Color(0.25, 0.15, 0.04, 0.8)
			var rs := ReferenceRect.new()
			# Round dots with StyleBox trick:
			var style := StyleBoxFlat.new()
			style.bg_color = d.color
			style.corner_radius_top_left = 10; style.corner_radius_top_right = 10
			style.corner_radius_bottom_left = 10; style.corner_radius_bottom_right = 10
			# ColorRect doesn't support stylebox, just keep the color

# ─── 16 Dan Tranh Strings (horizontal lines) ────────────────────────────────
func _build_strings() -> void:
	for c in strings_hbox.get_children(): c.queue_free()

	for i in 16:
		var is_treble := i >= 8
		var row := Control.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.custom_minimum_size = Vector2(0, 12)

		var line := ColorRect.new()
		line.custom_minimum_size = Vector2(0, 3)
		line.color = Color(0.82, 0.60, 0.20, 0.85) if is_treble else Color(0.72, 0.52, 0.18, 0.85)
		line.anchor_left = 0.08
		line.anchor_right = 0.92
		line.anchor_top = 0.5
		line.anchor_bottom = 0.5
		line.offset_top = -1
		line.offset_bottom = 1
		line.layout_mode = 1
		row.add_child(line)

		var pluck_dot := ColorRect.new()
		pluck_dot.custom_minimum_size = Vector2(10, 10)
		pluck_dot.color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.55)
		pluck_dot.anchor_left = 0.86
		pluck_dot.anchor_right = 0.86
		pluck_dot.anchor_top = 0.5
		pluck_dot.anchor_bottom = 0.5
		pluck_dot.offset_left = -5
		pluck_dot.offset_right = 5
		pluck_dot.offset_top = -5
		pluck_dot.offset_bottom = 5
		pluck_dot.layout_mode = 1
		row.add_child(pluck_dot)

		var num_lbl := Label.new()
		num_lbl.text = str(i + 1)
		num_lbl.add_theme_font_size_override("font_size", 11)
		num_lbl.add_theme_color_override("font_color", Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.55))
		num_lbl.anchor_left = 0.0
		num_lbl.anchor_right = 0.08
		num_lbl.anchor_top = 0.0
		num_lbl.anchor_bottom = 1.0
		num_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num_lbl.layout_mode = 1
		row.add_child(num_lbl)

		var note_lbl := Label.new()
		note_lbl.text = NOTES_VN[i % NOTES_VN.size()]
		note_lbl.add_theme_font_size_override("font_size", 11)
		note_lbl.add_theme_color_override("font_color", Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.70))
		note_lbl.anchor_left = 0.92
		note_lbl.anchor_right = 1.0
		note_lbl.anchor_top = 0.0
		note_lbl.anchor_bottom = 1.0
		note_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		note_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		note_lbl.layout_mode = 1
		row.add_child(note_lbl)

		var idx := i
		row.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton and ev.pressed:
				_pluck_string(idx, line, row)
		)

		strings_hbox.add_child(row)

	_update_target_indicator()

func _build_rhythm_bars() -> void:
	for c in rhythm_bars.get_children(): c.queue_free()
	for _i in range(14):
		var bar := ColorRect.new()
		bar.custom_minimum_size = Vector2(9, 10)
		bar.color = Color(0.22, 0.14, 0.04, 0.6)
		bar.size_flags_vertical = Control.SIZE_SHRINK_END
		rhythm_bars.add_child(bar)

# ─── Pluck ────────────────────────────────────────────────────────────────────
func _pluck_string(idx: int, line: ColorRect, row: Control) -> void:
	var base_color := line.color
	line.color = Color(1.0, 0.85, 0.25, 1.0)
	row.modulate = Color(1.2, 1.1, 0.9, 1.0)
	line.scale = Vector2(1.0, 1.0)

	var t := create_tween().set_parallel(true)
	t.tween_property(line, "color", base_color, 0.35)
	t.tween_property(row, "modulate", Color.WHITE, 0.35)
	t.tween_property(line, "scale:y", 2.6, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(line, "scale:y", 1.0, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	var plucked := NOTES_VN[idx % NOTES_VN.size()]
	pitch_note.text   = plucked
	pitch_status.text = "Dây %d  —  Vừa gảy" % (idx + 1)
	pitch_status.add_theme_color_override("font_color", C_GREEN_OK)
	pitch_note.add_theme_color_override("font_color",   C_GOLD_LIGHT)

	if plucked == SHEET[_note_idx]:
		_note_idx = (_note_idx + 1) % SHEET.size()
		_build_notation()
		_update_target_indicator()
		_score = clamp(_score + 4.0, 0, 100)
		_refresh_score()
		_va_say("Xuất sắc! Gảy đúng nốt rồi.")

	# Spawn a soft halo to emphasize the pluck
	var halo := ColorRect.new()
	halo.color = Color(1.0, 0.86, 0.30, 0.45)
	halo.custom_minimum_size = Vector2(8, 8)
	halo.anchor_left = 0.86; halo.anchor_right = 0.86
	halo.anchor_top = 0.5; halo.anchor_bottom = 0.5
	halo.offset_left = -12; halo.offset_right = 12
	halo.offset_top = -12; halo.offset_bottom = 12
	row.add_child(halo)
	var ht := create_tween()
	ht.tween_property(halo, "custom_minimum_size", Vector2(140, 140), 0.28)
	ht.tween_property(halo, "color", Color(1.0, 0.86, 0.30, 0.0), 0.38)
	ht.tween_callback(func() -> void: halo.queue_free())

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
	var reset_btn := $Root/MiddleRow/RightPanel/RecordBar/RecordM/RecordH/ResetBtn as Button

	back_btn.pressed.connect(_go_back)
	hint_btn.pressed.connect(func() -> void: hint_dialog.popup_centered())
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
	var visualizer = $Root/MiddleRow/RightPanel/RecordBar/RecordM/RecordH.get_node_or_null("WaveformVisualizer")
	if _recording:
		record_btn.text = "Dừng luyện tập"
		_va_say(SPEECHES[0])
		_start_pitch_detection()
		if visualizer: visualizer.visible = true
	else:
		record_btn.text = "Bắt đầu luyện tập"
		_show_result()
		_stop_pitch_detection()
		if visualizer: visualizer.visible = false

func _demo() -> void:
	_va_say("Đây là kỹ thuật nhấn dây chuẩn.\nQuan sát và làm theo.")
	var t := create_tween()
	t.tween_property(char_linh, "modulate", Color(1.5, 1.1, 0.6, 1.0), 0.3)
	t.tween_property(char_linh, "modulate", Color.WHITE, 0.5)

	# Demo: highlight and pluck the current target string for visual guidance
	var target_note := SHEET[_note_idx]
	var target_idx := NOTES_VN.find(target_note)
	if target_idx == -1:
		target_idx = 0
	var row := strings_hbox.get_child(target_idx) as Control
	if row and row.get_child_count() >= 2:
		var line := row.get_child(0) as ColorRect
		# small delay then pluck visually
		var dt := create_tween()
		dt.set_delay(0.35)
		dt.tween_callback(func() -> void: _pluck_string(target_idx, line, row))

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

	if NOTES_VN[ni] == SHEET[_note_idx] and randf() > 0.5:
		_note_idx = (_note_idx + 1) % SHEET.size()
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
			t.parallel().tween_property(cr, "color", Color(0.22, 0.14, 0.04, 0.6), 0.36)
	var pct := int(float(ok) / float(bars.size()) * 100.0)
	rhythm_acc.text = "Độ chính xác: %d%%" % pct
	rhythm_acc.add_theme_color_override("font_color",
		C_GREEN_OK if pct >= 80 else (C_WARN if pct >= 60 else C_RED_ERR))

func _va_say(text: String) -> void:
	speech_label.text = text
	var t := create_tween()
	t.tween_property(char_linh, "scale", Vector2(1.03, 0.97), 0.08)
	t.tween_property(char_linh, "scale", Vector2.ONE, 0.14)

func _update_target_indicator() -> void:
	var target_note := SHEET[_note_idx]
	var target_idx := NOTES_VN.find(target_note)
	if target_idx == -1:
		target_idx = 0
	target_label.text = "Dây cần gảy: %d" % (target_idx + 1)
	target_note_label.text = "Nốt cần gảy: %s" % target_note

	for i in strings_hbox.get_child_count():
		var row := strings_hbox.get_child(i) as Control
		if row and row.get_child_count() >= 2:
			var line := row.get_child(0) as ColorRect
			var dot := row.get_child(1) as ColorRect
			if line and dot:
				var is_target := i == target_idx
				line.color = Color(1.0, 0.85, 0.25, 0.95) if is_target else Color(0.82, 0.60, 0.20, 0.85)
				dot.color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.95) if is_target else Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45)

func _reset() -> void:
	_score = 75.0; _recording = false; _note_idx = 2
	_build_notation()
	record_btn.text   = "Bắt Đầu Luyện Tập"
	var visualizer = $Root/MiddleRow/RightPanel/RecordBar/RecordM/RecordH.get_node_or_null("WaveformVisualizer")
	if visualizer: visualizer.visible = false
	pitch_note.text   = "—"
	pitch_status.text = "Đang nghe..."
	pitch_status.add_theme_color_override("font_color", C_CREAM_DIM)
	pitch_note.add_theme_color_override("font_color", C_GOLD)
	rhythm_acc.text   = "Đang nghe..."
	_refresh_score()
	_va_say("Làm lại nào!\nLuyện tập giúp bạn cải thiện mỗi ngày.")

func _show_result() -> void:
	var rating := "Xuất sắc" if _score >= 85.0 else ("Tốt" if _score >= 70.0 else "Cần cố gắng")
	result_dialog.title = "Kết Quả Luyện Tập"
	result_dialog.dialog_text = (
		"Điểm tổng: %d / 100 (%s)\n\n" +
		"Cao độ: 82%%   ·   Nhịp điệu: 71%%   ·   Kỹ thuật: 79%%\n\n" +
		"+ 80 XP   ·   Đã mở khóa Bài 5"
	) % [int(_score), rating]
	result_dialog.popup_centered()

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
