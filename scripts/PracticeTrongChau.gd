extends Control
class_name PracticeTrongChau

# ─── Color Palette ─────────────────────────────────────────────────────────────
const C_GOLD       := Color("#c99a3c")
const C_GOLD_LIGHT := Color("#fce8b3")
const C_GOLD_TEXT  := Color("#8c6613")
const C_JADE       := Color("#0e3d26")
const C_RED_SON    := Color("#a82b2b") # Ruby/Vermilion red primary accent for drum
const C_CREAM      := Color("#faf6eb")
const C_CREAM_DIM  := Color("#ede7da")
const C_GREEN_OK   := Color("#27ae60")
const C_WARN       := Color("#b5882b")
const C_RED_ERR    := Color("#a82b2b")

const C_BG         := Color("#faf6eb")
const C_BG_BAR     := Color("#ede7da")
const C_CARD       := Color("#f6f2e5")
const C_TEXT       := Color("#0e3d26")
const C_TEXT_MUTED := Color("#5c503e")

# ─── @onready ─────────────────────────────────────────────────────────────────
@onready var linh_panel   : PanelContainer = $Root/MiddleRow/LinhPanel
@onready var char_linh    : TextureRect   = $Root/MiddleRow/LinhPanel/LinhVBox/CharLinhWrapper/CharLinh
@onready var speech_label : Label         = $Root/MiddleRow/LinhPanel/LinhVBox/SpeechBubble/SpeechM/SpeechLabel
@onready var lesson_bar   : ProgressBar   = $SettingsPanel/SettingsM/SettingsVBox/ProgressVBox/LessonBar
@onready var pitch_note   : Label         = $Root/MiddleRow/MainContent/StatsRow/PitchPanel/PitchM/PitchV/PitchNote
@onready var pitch_status : Label         = $Root/MiddleRow/MainContent/StatsRow/PitchPanel/PitchM/PitchV/PitchStatus
@onready var rhythm_bars  : HBoxContainer = $Root/MiddleRow/MainContent/StatsRow/RhythmPanel/RhythmM/RhythmV/RhythmBars
@onready var rhythm_acc   : Label         = $Root/MiddleRow/MainContent/StatsRow/RhythmPanel/RhythmM/RhythmV/RhythmAcc
@onready var score_num    : Label         = $Root/MiddleRow/MainContent/StatsRow/ScorePanel/ScoreM/ScoreV/ScoreNum
@onready var record_btn   : Button        = $Root/RecordBar/RecordM/RecordH/RecordBtn
@onready var notes_hbox   : HBoxContainer = $Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/NotesScroll/NotesHBox
@onready var target_note_label : Label    = $Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/TargetNoteLabel
@onready var target_label : Label         = $Root/StringsBoard/BoardM/BoardVBox/TargetLabel
@onready var dots_hbox    : HBoxContainer = $SettingsPanel/SettingsM/SettingsVBox/DotsHBox
@onready var _board       : Control       = $Root/StringsBoard/BoardM/BoardVBox/TrongChauBoard

# ─── State ────────────────────────────────────────────────────────────────────
var _recording   := false
var _is_demoing  := false
var _mic_mode    := false # Default to Touch mode for reliable drumming
var _score       := 100.0
var _time        := 0.0
var _note_idx    := 0
var _linh_collapsed := true
var linh_mini_btn : Button

var sheet_notes : Array[String] = ["Tịch", "Tịch", "Cắc", "Tịch", "Cắc", "Cắc", "Tịch"]

const SPEECHES : Array[String] = [
	"Gõ vào giữa mặt trống để tạo tiếng 'Tịch' trầm sâu,\ngõ vào vành gỗ để tạo tiếng 'Cắc' đanh thép.",
	"Rất tốt!\nGõ nhịp điệu Trống Chầu đều tay hơn nữa.",
	"Nhịp điệu chuẩn làn điệu Chèo cổ kính,\ntiếp tục nào.",
	"Tiếng trống giòn giã, giữ nhịp rất đẹp.",
]

static var current_song_title := ""
static var current_song_sheet : Array[String] = []

func _ready() -> void:
	_setup_collapsible_linh()
	
	if current_song_title != "" and current_song_sheet.size() > 0:
		sheet_notes = current_song_sheet
	else:
		if SecureDataManager.active_lesson_id == "Node2":
			sheet_notes = ["Tịch", "Tịch", "Cắc", "Tịch", "Tịch", "Cắc"]
		elif SecureDataManager.active_lesson_id == "Node3":
			sheet_notes = ["Tịch", "Cắc", "Cắc", "Tịch", "Cắc", "Cắc", "Tịch"]
		elif SecureDataManager.active_lesson_id == "Node4":
			sheet_notes = ["Tịch", "Cắc", "Tịch", "Cắc", "Tịch", "Cắc", "Tịch", "Cắc"]

	_set_labels()
	_build_theme()
	_build_notation()
	_build_board()
	_build_dots()
	_build_rhythm_bars()
	_connect_buttons()

func _process(delta: float) -> void:
	_time += delta

func _set_labels() -> void:
	# ($Root/TopBar/TopM/TopH/BackBtn as Button).text = "Quay lại"
	
	var diff := "Cơ bản"
	if SecureDataManager.active_lesson_id == "Node3":
		diff = "Trung bình"
	elif SecureDataManager.active_lesson_id == "Node4":
		diff = "Nâng cao"
		
	var title_lbl := "Nhịp Trống Nhập Môn"
	if current_song_title != "":
		title_lbl = current_song_title
		diff = "Bài hát"
	else:
		if SecureDataManager.active_lesson_id == "Node2":
			title_lbl = "Nhịp Trống Cơ Bản"
		elif SecureDataManager.active_lesson_id == "Node3":
			title_lbl = "Tiếng Cắc Vành Gỗ"
		elif SecureDataManager.active_lesson_id == "Node4":
			title_lbl = "Liên Khúc Trống Chầu"

	($Root/TopBar/TopM/TopH/LessonTag as Label).text = "TRỐNG CHẦU  ·  KỸ THUẬT  ·  %s" % diff.to_upper()
	($Root/TopBar/TopM/TopH/LessonTitle as Label).text = title_lbl
	($SettingsPanel/SettingsM/SettingsVBox/ProgressVBox/PctLabel as Label).text = "0%" if current_song_title == "" else "100%"
	($SettingsPanel/SettingsM/SettingsVBox/CtrlBtns/HintBtn as Button).text = "Gợi ý"
	($SettingsPanel/SettingsM/SettingsVBox/CtrlBtns/DemoBtn as Button).text = "Demo"
	($SettingsPanel/SettingsM/SettingsVBox/CtrlBtns/SlowBtn as Button).text = "x0.5"

	($Root/MiddleRow/MainContent/NotationArea/NotationM/NotationVBox/NotationLabel as Label).text = "BẢN NHẠC TRỐNG  —  Gõ theo nhịp ký âm"
	($Root/MiddleRow/MainContent/StatsRow/PitchPanel/PitchM/PitchV/PitchTitle as Label).text = "CAO ĐỘ"
	($Root/MiddleRow/MainContent/StatsRow/RhythmPanel/RhythmM/RhythmV/RhythmTitle as Label).text = "NHỊP ĐIỆU"
	($Root/MiddleRow/MainContent/StatsRow/ScorePanel/ScoreM/ScoreV/ScoreTitle as Label).text = "ĐIỂM SỐ"
	($Root/MiddleRow/MainContent/StatsRow/ScorePanel/ScoreM/ScoreV/ScoreSub as Label).text = "Độ chính xác nhịp chèo"

	($Root/StringsBoard/BoardM/BoardVBox/BoardLabel as Label).text = "TRỐNG CHẦU DÂN TỘC  —  Chạm tâm mặt trống đánh tiếng TỊCH  ·  Chạm vành gỗ ngoài đánh tiếng CẮC"
	record_btn.text = "Bắt đầu luyện tập"
	($Root/RecordBar/RecordM/RecordH/ResetBtn as Button).text = "Làm lại"

	speech_label.text = SPEECHES[0]
	score_num.text = "100"

func _build_theme() -> void:
	var bg_over := get_node_or_null("BGOverlay") as ColorRect
	if bg_over:
		bg_over.color = C_BG

	var top_s := _flat(C_BG_BAR, Color("#a82b2b", 0.35), 0)
	top_s.border_width_bottom = 2
	($Root/TopBar as PanelContainer).add_theme_stylebox_override("panel", top_s)

	($Root/TopBar/TopM/TopH/LessonTag as Label).add_theme_color_override("font_color", C_RED_SON)
	($Root/TopBar/TopM/TopH/LessonTitle as Label).add_theme_color_override("font_color", C_TEXT)
	($SettingsPanel/SettingsM/SettingsVBox/ProgressVBox/PctLabel as Label).add_theme_color_override("font_color", C_TEXT_MUTED)
	_style_progress_bar(lesson_bar, C_RED_SON, Color("#ede7da"))

	var back_btn := $Root/TopBar/TopM/TopH/BackBtn as Button
	back_btn.text = ""
	back_btn.icon = load("res://icons8/icons8-back-16.png") as Texture2D
	back_btn.expand_icon = true
	back_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	back_btn.custom_minimum_size = Vector2(44, 44)
	back_btn.add_theme_color_override("icon_normal_color", C_RED_SON)
	back_btn.add_theme_color_override("icon_hover_color", C_GOLD)
	back_btn.add_theme_color_override("icon_pressed_color", C_RED_SON)
	_style_text_btn(back_btn, C_RED_SON, C_RED_SON.lightened(0.15))
	
	var menu_btn := $Root/TopBar/TopM/TopH/MenuBtn as Button
	if menu_btn:
		_style_text_btn(menu_btn, C_RED_SON, C_RED_SON.lightened(0.15))

	for bn in ["HintBtn","DemoBtn","SlowBtn"]:
		_style_outlined_btn($SettingsPanel/SettingsM/SettingsVBox/CtrlBtns.get_node(bn) as Button)

	var settings_panel := $SettingsPanel as PanelContainer
	if settings_panel:
		var sp_style := StyleBoxFlat.new()
		sp_style.bg_color = C_CARD
		sp_style.border_color = C_GOLD
		sp_style.border_width_left = 2; sp_style.border_width_right = 2
		sp_style.border_width_top = 2; sp_style.border_width_bottom = 2
		sp_style.corner_radius_top_left = 14; sp_style.corner_radius_top_right = 14
		sp_style.corner_radius_bottom_left = 14; sp_style.corner_radius_bottom_right = 14
		settings_panel.add_theme_stylebox_override("panel", sp_style)

	var bubble_s := _flat(C_CARD, Color("#a82b2b", 0.35), 14)
	($Root/MiddleRow/LinhPanel/LinhVBox/SpeechBubble as PanelContainer).add_theme_stylebox_override("panel", bubble_s)
	speech_label.add_theme_color_override("font_color", C_TEXT)

	var na_s := _flat(Color("#fdfbf7"), Color("#a82b2b", 0.30), 12)
	($Root/MiddleRow/MainContent/NotationArea as PanelContainer).add_theme_stylebox_override("panel", na_s)
	
	var stat_bg := _flat(C_CARD, Color("#a82b2b", 0.30), 14)
	($Root/MiddleRow/MainContent/StatsRow/PitchPanel as PanelContainer).add_theme_stylebox_override("panel", stat_bg.duplicate())
	($Root/MiddleRow/MainContent/StatsRow/RhythmPanel as PanelContainer).add_theme_stylebox_override("panel", stat_bg.duplicate())
	($Root/MiddleRow/MainContent/StatsRow/ScorePanel as PanelContainer).add_theme_stylebox_override("panel", stat_bg.duplicate())

	pitch_note.add_theme_color_override("font_color", C_RED_SON)
	score_num.add_theme_color_override("font_color", C_RED_SON)
	
	# Show stats container but hide zither pitch panel for drum course
	($Root/MiddleRow/MainContent/StatsRow as HBoxContainer).visible = true
	($Root/MiddleRow/MainContent/StatsRow/PitchPanel as PanelContainer).visible = false

	var sb_s := StyleBoxFlat.new()
	sb_s.bg_color = Color("#1e120d") # Rosewood
	sb_s.border_color = Color("#a82b2b", 0.40)
	sb_s.border_width_top = 2; sb_s.border_width_bottom = 2
	($Root/StringsBoard as PanelContainer).add_theme_stylebox_override("panel", sb_s)
	($Root/StringsBoard/BoardM/BoardVBox/BoardLabel as Label).add_theme_color_override("font_color", Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.75))
	($Root/StringsBoard/BoardM/BoardVBox/TargetLabel as Label).add_theme_color_override("font_color", Color(1.0, 0.92, 0.70, 1.0))

	var rec_bar_s := _flat(C_BG_BAR, Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.15), 0)
	rec_bar_s.border_width_top = 2
	($Root/RecordBar as PanelContainer).add_theme_stylebox_override("panel", rec_bar_s)

	var rn := _flat(C_RED_SON, Color("#c99a3c", 0.65), 24)
	record_btn.add_theme_stylebox_override("normal", rn)
	_style_outlined_btn($Root/RecordBar/RecordM/RecordH/ResetBtn as Button)

func _build_notation() -> void:
	for c in notes_hbox.get_children(): c.queue_free()
	var scroll_container := notes_hbox.get_parent() as ScrollContainer
	
	for i in sheet_notes.size():
		var note := sheet_notes[i]
		var is_active := i == _note_idx
		var is_done := i < _note_idx

		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(70, 60)
		var cs := StyleBoxFlat.new()
		cs.border_width_left = 2; cs.border_width_right = 2; cs.border_width_top = 2; cs.border_width_bottom = 2
		cs.corner_radius_top_left = 12; cs.corner_radius_top_right = 12
		cs.corner_radius_bottom_left = 12; cs.corner_radius_bottom_right = 12
		if is_active:
			cs.bg_color = C_GOLD
			cs.border_color = Color(1.0, 0.9, 0.6, 1.0)
		elif is_done:
			cs.bg_color = C_JADE
			cs.border_color = Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.8)
		else:
			cs.bg_color = Color(0.95, 0.93, 0.89, 1.0)
			cs.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.2)
		card.add_theme_stylebox_override("panel", cs)

		var lbl := Label.new()
		lbl.text = note
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.add_theme_color_override("font_color", Color.WHITE if (is_active or is_done) else C_TEXT_MUTED)
		card.add_child(lbl)
		notes_hbox.add_child(card)

	if scroll_container:
		var target_scroll = max(0.0, _note_idx * 74.0 - 150.0)
		create_tween().tween_property(scroll_container, "scroll_horizontal", int(target_scroll), 0.25)

func _build_dots() -> void:
	for i in 5:
		var d := dots_hbox.get_child(i) as ColorRect
		if d:
			d.color = C_GOLD if i < 2 else Color(0.85, 0.82, 0.75, 1.0)

func _build_rhythm_bars() -> void:
	for c in rhythm_bars.get_children(): c.queue_free()
	for _i in range(14):
		var bar := ColorRect.new()
		bar.custom_minimum_size = Vector2(9, 10)
		bar.color = Color(0.85, 0.82, 0.75, 1.0)
		bar.size_flags_vertical = Control.SIZE_SHRINK_END
		rhythm_bars.add_child(bar)

func _build_board() -> void:
	_board.drum_hit.connect(_on_drum_hit)
	_update_target_indicator()

func _update_target_indicator() -> void:
	if _note_idx < sheet_notes.size():
		var target_note = sheet_notes[_note_idx]
		target_note_label.text = "Âm cần đánh: " + target_note.to_upper()
		target_label.text = "Hãy gõ: " + target_note
		_board.set_target(target_note)
		pitch_note.text = target_note

func _on_drum_hit(hit_type: String) -> void:
	if not _recording:
		# Let them test-play the sound without recording
		return
		
	var target_note = sheet_notes[_note_idx]
	if hit_type == target_note:
		_note_idx += 1
		_score = minf(100.0, _score + (100.0 - _score) * 0.15)
		score_num.text = str(int(_score))
		
		# Feedback
		rhythm_acc.text = "CHUẨN XÁC!"
		rhythm_acc.add_theme_color_override("font_color", C_GREEN_OK)
		
		_va_say(SPEECHES.pick_random())
		_build_notation()
		
		if _note_idx >= sheet_notes.size():
			_recording = false
			record_btn.text = "Hoàn Thành!"
			_va_say("Chúc mừng bạn đã đánh chính xác toàn bộ bản nhạc Trống Chầu!")
			SecureDataManager.record_practice_result(SecureDataManager.active_lesson_id, _score)
			_sync_practice_to_backend()
			
			get_tree().create_timer(1.8).timeout.connect(func() -> void:
				_fade_to("res://scenes/MainMenu.tscn")
			)
		else:
			_update_target_indicator()
	else:
		_score = maxf(10.0, _score - 6.0)
		score_num.text = str(int(_score))
		rhythm_acc.text = "SAI NHỊP!"
		rhythm_acc.add_theme_color_override("font_color", C_RED_ERR)

func _sync_practice_to_backend() -> void:
	if not BackendReport.is_signed_in():
		return
	BackendReport.report_practice_and_complete(
		"trong_chau",
		SecureDataManager.active_lesson_id,
		{"pitch": _score, "rhythm": _score, "dynamics": 0.0, "tonal_quality": 0.0, "breath": 0.0},
		_score
	)

func _connect_buttons() -> void:
	var back_btn := $Root/TopBar/TopM/TopH/BackBtn as Button
	back_btn.pressed.connect(func() -> void:
		_fade_to("res://scenes/MainMenu.tscn")
	)
	_make_button_bouncy(back_btn)
	
	var menu_btn := $Root/TopBar/TopM/TopH/MenuBtn as Button
	if menu_btn:
		_make_button_bouncy(menu_btn)
	
	record_btn.pressed.connect(func() -> void:
		if not _recording:
			_recording = true
			_note_idx = 0
			_score = 100.0
			score_num.text = "100"
			record_btn.text = "Đang luyện tập... (Chạm trống)"
			_build_notation()
			_update_target_indicator()
			_va_say("Hãy gõ trống theo đúng chuỗi nốt bản nhạc.")
	)
	_make_button_bouncy(record_btn)
	
	var reset_btn := $Root/RecordBar/RecordM/RecordH/ResetBtn as Button
	reset_btn.pressed.connect(func() -> void:
		_recording = false
		_note_idx = 0
		_score = 100.0
		score_num.text = "100"
		record_btn.text = "Bắt đầu luyện tập"
		_build_notation()
		_update_target_indicator()
		_va_say("Đã đặt lại bài học. Hãy gõ bắt đầu khi sẵn sàng.")
	)
	_make_button_bouncy(reset_btn)

	var demo_btn = $SettingsPanel/SettingsM/SettingsVBox/CtrlBtns.get_node_or_null("DemoBtn")
	if demo_btn:
		demo_btn.pressed.connect(_on_demo_btn_pressed)
		_make_button_bouncy(demo_btn)

func _va_say(txt: String) -> void:
	speech_label.text = txt

func _on_demo_btn_pressed() -> void:
	if _is_demoing or not _board: return
	_is_demoing = true
	
	var demo_btn = $SettingsPanel/SettingsM/SettingsVBox/CtrlBtns.get_node_or_null("DemoBtn")
	if demo_btn:
		demo_btn.text = "\nNghe mẫu: ĐANG PHÁT"
		
	var sz = _board.size
	var center = sz * 0.5
	var rim_r = minf(sz.x, sz.y) * 0.44
	var head_r = rim_r * 0.8
	
	var sequence = [
		{"type": "Center", "pos": center, "delay": 0.0},
		{"type": "Center", "pos": center, "delay": 0.5},
		{"type": "Rim", "pos": center + Vector2(-rim_r * 1.05, 0), "delay": 0.5},
		{"type": "Rim", "pos": center + Vector2(rim_r * 1.05, 0), "delay": 0.3},
		{"type": "Edge", "pos": center + Vector2(0, head_r * 0.95), "delay": 0.5},
		{"type": "OffCenter", "pos": center + Vector2(head_r * 0.6, head_r * 0.3), "delay": 0.4},
		{"type": "Center", "pos": center, "delay": 0.4},
		{"type": "Hard", "pos": center, "delay": 0.4},
		{"type": "Roll", "pos": center, "delay": 0.8},
		{"type": "Hard", "pos": center, "delay": 1.5}
	]
	
	for step in sequence:
		if step.delay > 0:
			await get_tree().create_timer(step.delay).timeout
		if _board and is_instance_valid(_board):
			_board.hit(step.type, step.pos)
			
	await get_tree().create_timer(1.2).timeout
	if demo_btn and is_instance_valid(demo_btn):
		demo_btn.text = "Demo"
	_is_demoing = false

func _setup_collapsible_linh() -> void:
	var btn := Button.new()
	btn.name = "LinhMiniBtn"
	btn.text = "Cô Mai 👩‍🏫"
	btn.custom_minimum_size = Vector2(100, 32)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.flat = true
	$Root/MiddleRow.add_child(btn)
	$Root/MiddleRow.move_child(btn, 0)
	linh_mini_btn = btn
	btn.visible = false
	
	btn.pressed.connect(func() -> void:
		_linh_collapsed = false
		linh_panel.visible = true
		btn.visible = false
	)
	
	var close_btn := Button.new()
	close_btn.text = "Ẩn"
	close_btn.flat = true
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	$Root/MiddleRow/LinhPanel/LinhVBox.add_child(close_btn)
	
	close_btn.pressed.connect(func() -> void:
		_linh_collapsed = true
		linh_panel.visible = false
		btn.visible = true
	)

func _fade_to(path: String) -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.22)
	t.tween_callback(func() -> void: get_tree().change_scene_to_file(path))

# ─── Style Helpers ────────────────────────────────────────────────────────────
func _flat(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.border_color = border
	s.border_width_left = 1; s.border_width_right = 1
	s.border_width_top = 1; s.border_width_bottom = 1
	s.corner_radius_top_left = radius; s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius; s.corner_radius_bottom_right = radius
	return s

func _style_progress_bar(bar: ProgressBar, fill_col: Color, bg_col: Color) -> void:
	var f := StyleBoxFlat.new()
	f.bg_color = fill_col
	f.corner_radius_top_left = 3; f.corner_radius_top_right = 3
	f.corner_radius_bottom_left = 3; f.corner_radius_bottom_right = 3
	var b := StyleBoxFlat.new()
	b.bg_color = bg_col
	b.corner_radius_top_left = 3; b.corner_radius_top_right = 3
	b.corner_radius_bottom_left = 3; b.corner_radius_bottom_right = 3
	bar.add_theme_stylebox_override("fill", f)
	bar.add_theme_stylebox_override("background", b)

func _style_text_btn(btn: Button, color: Color, hover_col: Color) -> void:
	btn.add_theme_stylebox_override("normal", _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	btn.add_theme_stylebox_override("hover", _flat(Color(0,0,0,0.06), Color(0,0,0,0), 0))
	btn.add_theme_stylebox_override("pressed", _flat(Color(0,0,0,0.12), Color(0,0,0,0), 0))
	btn.add_theme_stylebox_override("focus", _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_color_override("font_hover_color", hover_col)

func _style_outlined_btn(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", _flat(Color(0,0,0,0), Color(0.13, 0.08, 0.05, 0.15), 14))
	btn.add_theme_stylebox_override("hover", _flat(Color(0,0,0,0.04), Color(0.13, 0.08, 0.05, 0.35), 14))
	btn.add_theme_stylebox_override("pressed", _flat(Color(0,0,0,0.08), C_GOLD, 14))
	btn.add_theme_stylebox_override("focus", _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	btn.add_theme_color_override("font_color", C_RED_SON)
	btn.add_theme_color_override("font_hover_color", C_RED_SON.lightened(0.12))

func _make_button_bouncy(btn: Button) -> void:
	btn.pivot_offset = btn.size / 2.0
	btn.resized.connect(func() -> void: btn.pivot_offset = btn.size / 2.0)
	btn.mouse_entered.connect(func() -> void:
		create_tween().tween_property(btn, "scale", Vector2(1.05, 1.05), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func() -> void:
		create_tween().tween_property(btn, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
