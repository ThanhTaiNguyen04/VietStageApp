extends Control
class_name PracticeTrongChau

static var current_song_title := ""
static var current_song_sheet : Array[String] = []

const C_GOLD := Color(0.85, 0.70, 0.35)

@onready var song_title_lbl : Label = $MainHBox/CenterArea/TopPillContainer/TopPill/SongTitle
@onready var combo_lbl : Label = $MainHBox/RightMargin/RightPanel/StatsVBox/ComboLbl
@onready var score_lbl : Label = $MainHBox/RightMargin/RightPanel/StatsVBox/ScoreLbl
@onready var highway = $MainHBox/CenterArea/Highway
@onready var board = $MainHBox/CenterArea/TrongChauBoard

var song_player = null
var _score := 0.0
var _combo := 0
var _is_demoing := false

func _ready() -> void:
	if not Engine.is_editor_hint():
		if current_song_title != "":
			song_title_lbl.text = current_song_title
			
		# Initialize song player for test
		song_player = Node.new()
		song_player.set_script(load("res://scripts/SongPlayer.gd"))
		add_child(song_player)
		# Hide the highway in Practice Mode without breaking layout
		if highway:
			highway.modulate.a = 0.0
			highway.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
		_setup_sidebar()

func _process(delta: float) -> void:
	if song_player and song_player._is_playing:
		song_player.current_song_time += delta
		_update_stats()

func _on_note_hit(note: Dictionary) -> void:
	_combo += 1
	_score += 100.0
	var lane = note.get("lane", 0)
	if board and board.has_method("hit_lane"):
		board.hit_lane(lane)

func _update_stats() -> void:
	if combo_lbl:
		combo_lbl.text = "Combo: %d" % _combo
	if score_lbl:
		score_lbl.text = "Điểm: %.0f" % _score

func _setup_sidebar() -> void:
	var ctrl_btns = $SettingsPanel/SettingsM/SettingsVBox/CtrlBtns
	if not ctrl_btns: return
	var settings_vbox = $SettingsPanel/SettingsM/SettingsVBox
	
	var settings_panel := $SettingsPanel as PanelContainer
	if settings_panel:
		settings_panel.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
		settings_panel.custom_minimum_size.x = 240
		settings_panel.size.x = 240
		settings_panel.position.x = -260
		settings_panel.visible = true
		settings_panel.z_index = 100
		
		var sp_style := StyleBoxFlat.new()
		sp_style.bg_color = Color(0.93, 0.91, 0.87, 0.6)
		sp_style.border_color = Color(0.8, 0.78, 0.73, 0.8)
		sp_style.border_width_right = 2
		settings_panel.add_theme_stylebox_override("panel", sp_style)
		
		# Hide unnecessary elements in the sidebar
		var prog_vbox = $SettingsPanel/SettingsM/SettingsVBox/ProgressVBox
		if prog_vbox: prog_vbox.visible = false
		var dots_box = $SettingsPanel/SettingsM/SettingsVBox/DotsHBox
		if dots_box: dots_box.visible = false
		
		var menu_title := $SettingsPanel/SettingsM/SettingsVBox/MenuTitle as Label
		# Add Hamburger Menu Button
		var menu_btn = Button.new()
		menu_btn.name = "MenuFAB"
		menu_btn.flat = true
		menu_btn.text = "≡"
		menu_btn.add_theme_font_size_override("font_size", 32)
		menu_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		menu_btn.add_theme_color_override("font_hover_color", Color(0.8, 0.8, 0.8))
		menu_btn.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0))
		menu_btn.add_theme_color_override("font_focus_color", Color(1.0, 1.0, 1.0))
		add_child(menu_btn)
		menu_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
		menu_btn.position = Vector2(16, 16)
		menu_btn.z_index = 101 # Ensure it stays above the sidebar
		
		# Connect the toggle action
		menu_btn.pressed.connect(func() -> void:
			var target_x = 0.0 if settings_panel.position.x < -10.0 else -260.0
			var t = create_tween()
			t.tween_property(settings_panel, "position:x", target_x, 0.4).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		)

	if "columns" in ctrl_btns:
		ctrl_btns.columns = 1
	
	# Dynamic Song Selector OptionButton setup
	var song_sel := OptionButton.new()
	song_sel.name = "SongSelector"
	song_sel.custom_minimum_size = Vector2(220, 44)
	song_sel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var sb_normal := _flat(Color(0.96, 0.93, 0.88, 1), C_GOLD, 8)
	var sb_hover := _flat(Color(0.96, 0.93, 0.88, 1), Color(0.9, 0.8, 0.5), 8)
	var sb_pressed := _flat(C_GOLD, Color(0.9, 0.8, 0.5), 8)
	
	song_sel.add_theme_stylebox_override("normal", sb_normal)
	song_sel.add_theme_stylebox_override("hover", sb_hover)
	song_sel.add_theme_stylebox_override("pressed", sb_pressed)
	song_sel.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 1))
	song_sel.add_theme_color_override("font_hover_color", Color(0.2, 0.2, 0.2, 1))
	song_sel.add_theme_font_size_override("font_size", 16)
	
	song_sel.add_item("Bài 1: Làm quen mặt trống (Tâm)", 0)
	song_sel.add_item("Bài 2: Gõ cạnh da (Cắc)", 1)
	song_sel.add_item("Bài 3: Kỹ thuật gõ vành (Rim)", 2)
	song_sel.add_item("Bài 4: Nhịp múa Lân cơ bản", 3)
	song_sel.add_item("Bài 5: Kỹ thuật trống dồn (Roll)", 4)
	song_sel.selected = 0
	
	song_sel.item_selected.connect(func(idx: int):
		if song_title_lbl:
			song_title_lbl.text = song_sel.get_item_text(idx)
	)
	settings_vbox.add_child(song_sel)
	settings_vbox.move_child(song_sel, 1)

	var hint_btn = ctrl_btns.get_node_or_null("HintBtn") as Button
	if hint_btn:
		hint_btn.text = "\nLuyện tập"
		_set_sidebar_icon(hint_btn, "graduation-cap")
		
	var stop_record_btn = Button.new()
	stop_record_btn.name = "StopRecordBtn"
	stop_record_btn.text = "\nKết thúc luyện tập"
	stop_record_btn.custom_minimum_size = Vector2(0, 48)
	ctrl_btns.add_child(stop_record_btn)
	ctrl_btns.move_child(stop_record_btn, 1)
	_style_sidebar_btn(stop_record_btn)
	_set_sidebar_icon(stop_record_btn, "pause")

	var reset_sidebar_btn = Button.new()
	reset_sidebar_btn.name = "ResetSidebarBtn"
	reset_sidebar_btn.text = "\nLàm lại"
	reset_sidebar_btn.custom_minimum_size = Vector2(0, 48)
	ctrl_btns.add_child(reset_sidebar_btn)
	ctrl_btns.move_child(reset_sidebar_btn, 2)
	_style_sidebar_btn(reset_sidebar_btn)
	_set_sidebar_icon(reset_sidebar_btn, "rotate-cw")

	var slow_btn = ctrl_btns.get_node_or_null("SlowBtn")
	if slow_btn:
		ctrl_btns.move_child(slow_btn, 3)

	var mic_btn = Button.new()
	mic_btn.name = "MicBtn"
	mic_btn.text = "\nMicro: Bật"
	mic_btn.custom_minimum_size = Vector2(0, 48)
	ctrl_btns.add_child(mic_btn)
	ctrl_btns.move_child(mic_btn, 4)
	_style_sidebar_btn(mic_btn)
	_set_sidebar_icon(mic_btn, "mic")

	var demo_btn = ctrl_btns.get_node_or_null("DemoBtn")
	if demo_btn:
		ctrl_btns.move_child(demo_btn, 5)
		demo_btn.pressed.connect(_on_demo_btn_pressed)

	var layout_btn = Button.new()
	layout_btn.name = "LayoutBtn"
	layout_btn.text = "\nĐàn ngang"
	layout_btn.custom_minimum_size = Vector2(0, 48)
	ctrl_btns.add_child(layout_btn)
	ctrl_btns.move_child(layout_btn, 6)
	_style_sidebar_btn(layout_btn)
	_set_sidebar_icon(layout_btn, "rotate-cw")

	var sep = HSeparator.new()
	sep.add_theme_constant_override("separation", 10)
	ctrl_btns.add_child(sep)

	var back_btn_sidebar = Button.new()
	back_btn_sidebar.name = "BackBtnSidebar"
	back_btn_sidebar.text = "\nQuay lại"
	ctrl_btns.add_child(back_btn_sidebar)
	_style_sidebar_btn(back_btn_sidebar)
	_set_sidebar_icon(back_btn_sidebar, "arrow-left")
	back_btn_sidebar.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))

	for child in ctrl_btns.get_children():
		if child is Button:
			child.custom_minimum_size = Vector2(0, 48)
			var clean_text = child.text.replace("\n", "").strip_edges()
			child.text = "\n" + clean_text
			if child.name == "DemoBtn":
				_set_sidebar_icon(child, "volume-x")
			elif child.name == "SlowBtn":
				_set_sidebar_icon(child, "hourglass")
			if child.name in ["HintBtn", "DemoBtn", "SlowBtn"]:
				_style_sidebar_btn(child)

func _set_sidebar_icon(btn: Button, icon_name: String) -> void:
	var tex = load("res://assets/textures/lucide/" + icon_name + ".svg")
	if tex:
		btn.icon = tex
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if "vertical_icon_alignment" in btn:
			btn.set("vertical_icon_alignment", 0) # VERTICAL_ALIGNMENT_TOP

func _style_sidebar_btn(btn: Button) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	var sb_hover := StyleBoxFlat.new()
	sb_hover.bg_color = Color(0.1, 0.35, 0.2, 0.08)
	
	btn.custom_minimum_size.y = 44 # Reduced from 60 so they fit in the panel
	btn.add_theme_font_size_override("font_size", 14) # Ensure text is small enough
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("focus", _flat(Color(0,0,0,0), Color(0,0,0,0), 0))
	btn.add_theme_color_override("font_color", Color(0.25, 0.22, 0.20))
	btn.add_theme_color_override("font_hover_color", Color(0.1, 0.35, 0.2))
	
	btn.add_theme_color_override("icon_normal_color", Color(0.1, 0.1, 0.1))

func _flat(bg: Color, border: Color, corner: int) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_width_bottom = 2
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_color = border
	sb.corner_radius_bottom_left = corner
	sb.corner_radius_bottom_right = corner
	sb.corner_radius_top_left = corner
	sb.corner_radius_top_right = corner
	return sb

func _on_demo_btn_pressed() -> void:
	if _is_demoing or not board: return
	_is_demoing = true
	
	var demo_btn = $SettingsPanel/SettingsM/SettingsVBox/CtrlBtns.get_node_or_null("DemoBtn")
	if demo_btn:
		demo_btn.text = "\nNghe mẫu: ĐANG PHÁT"
		
	var sz = board.size
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
		if board and is_instance_valid(board):
			board.hit(step.type, step.pos)
			
	await get_tree().create_timer(1.2).timeout
	if demo_btn and is_instance_valid(demo_btn):
		demo_btn.text = "\nNghe mẫu: TẮT"
	_is_demoing = false
