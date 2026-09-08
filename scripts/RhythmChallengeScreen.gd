extends "res://scripts/LearningActivityBase.gd"

const RhythmModel = preload("res://scripts/RhythmChallengeModel.gd")
const RhythmStaffDisplayScript = preload("res://scripts/RhythmStaffDisplay.gd")
const InstrumentSamplePlayerScript = preload("res://scripts/InstrumentSamplePlayer.gd")
const AudioCaptureAnalyzerScript = preload("res://scripts/AudioCaptureAnalyzer.gd")

enum FlowState {
	LOADING,
	INTRO,
	PREVIEW,
	COUNTDOWN,
	PLAYING,
	ROUND_RESULT,
	SUBMITTING,
	FINAL_RESULT,
	ERROR,
}

const PERFECT_WINDOW := 0.08
const GOOD_WINDOW := 0.24
const C_GREEN_DARK := Color("#1e5c38")
const C_GREEN_SOFT := Color("#e8f5ed")
const C_GOLD_SOFT := Color("#fff7dc")

var flow_state := FlowState.LOADING
var rhythms: Array[Dictionary] = []
var rhythm_index := 0
var beat_times: Array[float] = []
var judgements: Array[String] = []
var round_duration := 1.0
var round_started_at_ms := 0
var challenge_started_at := ""
var playing := false
var performance_mode := false
var performance_notes: Array[String] = []
var staff: Control
var sample_player: Node
var audio_analyzer: AudioCaptureAnalyzer
var last_detected_at_ms := -1000

var round_accuracy_points := 0
var round_hits := 0
var round_correct_pitch_count := 0
var round_on_time_count := 0
var challenge_accuracy_points := 0
var challenge_beat_count := 0
var total_accuracy_points := 0
var total_beat_count := 0
var total_correct_pitch_count := 0
var total_on_time_count := 0
var total_score := 0
var total_max_score := 0
var backend_stars_earned := 0
var backend_points_earned := 0
var submitted_count := 0
var sync_failures: Array[Dictionary] = []
var online_session := false

var custom_top_bar: PanelContainer
var top_round_badge: Label
var status_label: Label
var microphone_label: Label
var accuracy_label: Label
var hit_label: Label
var timeline: Control
var countdown_label: Label
var preview_button: Button
var preview_status: Label
var click_player: AudioStreamPlayer
var click_stream: AudioStreamWAV
var accent_stream: AudioStreamWAV

var load_generation := 0
var session_generation := 0
var preview_generation := 0


func _ready() -> void:
	super._ready()
	_setup_custom_header_and_backdrop()
	click_stream = _make_click_stream(880.0)
	accent_stream = _make_click_stream(1174.66)
	click_player = AudioStreamPlayer.new()
	click_player.name = "RhythmClickPlayer"
	add_child(click_player)
	_setup_performance_audio()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_load_challenges()


func _exit_tree() -> void:
	load_generation += 1
	session_generation += 1
	preview_generation += 1
	playing = false
	if is_instance_valid(sample_player):
		sample_player.call("stop")
	if is_instance_valid(audio_analyzer):
		audio_analyzer.set_analysis_suspended(true)


func _setup_custom_header_and_backdrop() -> void:
	# Hide default bulky top bar from LearningActivityBase
	if root_box.get_child_count() > 0:
		var default_top := root_box.get_child(0) as Control
		if default_top:
			default_top.visible = false

	# Add a darkened backdrop wash layer for maximum contrast with white cards and staff
	var dark_wash := ColorRect.new()
	dark_wash.name = "RhythmBackdropDarkener"
	dark_wash.color = Color(0.04, 0.08, 0.06, 0.45)
	dark_wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dark_wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dark_wash)
	move_child(dark_wash, 2) # After background and background_wash, before root_box

	# Create clean, mobile-first top bar
	var mobile := _is_mobile()
	custom_top_bar = PanelContainer.new()
	custom_top_bar.name = "RhythmCustomTopBar"
	custom_top_bar.custom_minimum_size = Vector2(0, 68 if mobile else 76)
	custom_top_bar.add_theme_stylebox_override("panel", _panel(Color(1.0, 0.99, 0.97, 0.88), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35), 0, 1))
	root_box.add_child(custom_top_bar)
	root_box.move_child(custom_top_bar, 0)

	var bar_margin := MarginContainer.new()
	bar_margin.add_theme_constant_override("margin_left", 14 if mobile else 24)
	bar_margin.add_theme_constant_override("margin_right", 14 if mobile else 24)
	bar_margin.add_theme_constant_override("margin_top", 10 if mobile else 14)
	bar_margin.add_theme_constant_override("margin_bottom", 10 if mobile else 14)
	custom_top_bar.add_child(bar_margin)

	var bar_row := HBoxContainer.new()
	bar_row.add_theme_constant_override("separation", 12)
	bar_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bar_margin.add_child(bar_row)

	# Back button (>= 48x48 touch target)
	var back_btn := Button.new()
	back_btn.custom_minimum_size = Vector2(48, 48)
	back_btn.icon = load("res://assets/textures/lucide/arrow-left.svg") as Texture2D
	back_btn.expand_icon = true
	back_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	back_btn.add_theme_color_override("icon_normal_color", C_NAVY)
	back_btn.add_theme_constant_override("icon_max_width", 24)

	var sb_n := StyleBoxFlat.new()
	sb_n.bg_color = Color.WHITE
	sb_n.set_corner_radius_all(24)
	sb_n.border_width_bottom = 2
	sb_n.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45)
	var sb_h := sb_n.duplicate()
	sb_h.bg_color = Color("#FDFCF9")
	var sb_p := sb_n.duplicate()
	sb_p.bg_color = Color("#F5F0E5")
	sb_p.border_width_bottom = 0
	back_btn.add_theme_stylebox_override("normal", sb_n)
	back_btn.add_theme_stylebox_override("hover", sb_h)
	back_btn.add_theme_stylebox_override("pressed", sb_p)
	back_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	back_btn.pressed.connect(_go_back)
	bar_row.add_child(back_btn)

	# Header title
	var title_lbl := Label.new()
	title_lbl.text = "Mini-game 1"
	title_lbl.add_theme_font_size_override("font_size", 19 if mobile else 22)
	var bold_font := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if bold_font:
		title_lbl.add_theme_font_override("font", bold_font)
	title_lbl.add_theme_color_override("font_color", C_NAVY)
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar_row.add_child(title_lbl)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar_row.add_child(spacer)

	# Small round badge: Vòng 1/1
	top_round_badge = _label("Vòng 1/1", 12, C_GREEN_DARK)
	var badge_chip := _chip(top_round_badge, C_GREEN_SOFT, Color(C_GREEN.r, C_GREEN.g, C_GREEN.b, 0.35))
	bar_row.add_child(badge_chip)


func _update_top_bar_badge() -> void:
	if is_instance_valid(top_round_badge):
		var total := maxi(1, rhythms.size())
		var current := clampi(rhythm_index + 1, 1, total)
		top_round_badge.text = "Vòng %d/%d" % [current, total]


func _setup_performance_audio() -> void:
	sample_player = InstrumentSamplePlayerScript.new()
	sample_player.name = "RhythmRecordedSamplePlayer"
	add_child(sample_player)
	sample_player.note_started.connect(_on_sample_note_started)
	sample_player.playback_finished.connect(_on_sample_finished)
	sample_player.playback_failed.connect(_on_sample_failed)
	audio_analyzer = AudioCaptureAnalyzerScript.new() as AudioCaptureAnalyzer
	if audio_analyzer == null:
		return
	audio_analyzer.name = "RhythmAudioCaptureAnalyzer"
	audio_analyzer.pitch_profile = _make_pitch_profile()
	add_child(audio_analyzer)
	audio_analyzer.set_analysis_suspended(true)


func _make_pitch_profile() -> InstrumentPitchProfile:
	var profile := InstrumentPitchProfile.new()
	profile.cents_tolerance = 75.0
	profile.min_frequency = 120.0
	profile.max_frequency = 2200.0
	profile.is_plucked_instrument = Context.instrument == "dan_tranh"
	var names: Array[String] = []
	var frequencies := PackedFloat32Array()
	for midi in range(48, 85):
		var note_names := ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
		names.append("%s%d" % [note_names[midi % 12], midi / 12 - 1])
		frequencies.append(440.0 * pow(2.0, (float(midi) - 69.0) / 12.0))
	profile.notes = names
	profile.frequencies = frequencies
	return profile


func _on_sample_note_started(index: int) -> void:
	if is_instance_valid(staff):
		staff.set_playback_index(index)


func _on_sample_finished() -> void:
	if flow_state == FlowState.PREVIEW:
		_set_flow_state(FlowState.INTRO)
		if is_instance_valid(preview_button):
			preview_button.text = "↻  Nghe lại"
		if is_instance_valid(preview_status):
			preview_status.text = "● Micro sẵn sàng"
			preview_status.add_theme_color_override("font_color", C_OK)
	if is_instance_valid(staff):
		staff.set_playback_index(0 if not performance_notes.is_empty() else -1)
	if is_instance_valid(audio_analyzer):
		audio_analyzer.set_analysis_suspended(true)


func _on_sample_failed(details: Dictionary) -> void:
	if flow_state == FlowState.PREVIEW:
		_set_flow_state(FlowState.INTRO)
	if is_instance_valid(preview_button):
		preview_button.disabled = false
		preview_button.text = "▶  Nghe mẫu"
	if is_instance_valid(preview_status):
		var missing: Array = details.get("missing", [])
		preview_status.text = "Thiếu WAV thu thật cho nốt mẫu (%d asset). Không dùng âm tổng hợp." % missing.size()
		preview_status.add_theme_color_override("font_color", C_BAD)


func _load_challenges() -> void:
	load_generation += 1
	var generation := load_generation
	_set_flow_state(FlowState.LOADING)
	_build_loading("Đang chuẩn bị thử thách nhịp điệu…")

	var report := _report()
	var target_challenges: Array = []
	online_session = report != null and report.is_signed_in()
	if not online_session:
		_use_offline_data()
		return

	if SecureDataManager.be_catalog.is_empty():
		await report.fetch_and_install_catalog()
	if generation != load_generation or not is_inside_tree():
		return
	if SecureDataManager.be_catalog.is_empty():
		_use_offline_data()
		return

	target_challenges = await report.fetch_minigames_for_level(Context.instrument, Context.local_lesson_ids, "RHYTHM_MATCH", true)
	if generation != load_generation or not is_inside_tree():
		return

	rhythms = RhythmModel.parse_challenges(target_challenges, Context.instrument)
	if rhythms.is_empty():
		_use_offline_data()
		return

	result_sync_status = "pending"
	_reset_run()
	_build_intro()


func _use_offline_data() -> void:
	var sample := _sample_data()
	var rhythm_value: Variant = sample.get("rhythm", {})
	if not rhythm_value is Dictionary:
		_set_flow_state(FlowState.ERROR)
		_build_load_error("Không có dữ liệu nhịp mẫu cho nhạc cụ này.", "Hãy quay lại sau khi dữ liệu được cập nhật.", false)
		return
	var item: Dictionary = (rhythm_value as Dictionary).duplicate(true)
	item["id"] = 0
	item["title"] = "Mẫu nhịp %s" % _instrument_title().to_lower()
	item["difficulty"] = "Luyện tập"
	rhythms = RhythmModel.parse_challenges([item], Context.instrument)
	if rhythms.is_empty():
		_set_flow_state(FlowState.ERROR)
		_build_load_error("Dữ liệu nhịp mẫu không hợp lệ.", "Không thể bắt đầu trò chơi ở chế độ offline.", false)
		return
	online_session = false
	result_sync_status = "offline"
	_reset_run()
	_build_intro()


func _reset_run() -> void:
	session_generation += 1
	preview_generation += 1
	playing = false
	rhythm_index = 0
	challenge_started_at = ""
	round_accuracy_points = 0
	round_hits = 0
	round_correct_pitch_count = 0
	round_on_time_count = 0
	challenge_accuracy_points = 0
	challenge_beat_count = 0
	total_accuracy_points = 0
	total_beat_count = 0
	total_correct_pitch_count = 0
	total_on_time_count = 0
	total_score = 0
	total_max_score = 0
	backend_stars_earned = 0
	backend_points_earned = 0
	submitted_count = 0
	sync_failures.clear()


func _build_intro() -> void:
	if rhythms.is_empty() or rhythm_index < 0 or rhythm_index >= rhythms.size():
		return
	_set_flow_state(FlowState.INTRO)
	_clear_content()
	_prepare_current_round()
	_update_top_bar_badge()

	var current := rhythms[rhythm_index]
	var mobile := _is_mobile()
	var card_body := _add_centered_card(C_GREEN, 780.0)

	# Clean title
	var heading := _label(str(current.get("title", "Đọc khuông nhạc")), 22 if mobile else 26, C_NAVY)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var bold_font := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if bold_font:
		heading.add_theme_font_override("font", bold_font)
	card_body.add_child(heading)

	# 1-line metadata: e.g. "6 nốt  ·  100 BPM"
	var detail_parts: Array[String] = ["%d nốt" % performance_notes.size()]
	var tempo := _safe_int(current.get("tempo_bpm", 0))
	if tempo > 0:
		detail_parts.append("%d BPM" % tempo)
	var difficulty := str(current.get("difficulty", "")).strip_edges()
	if not difficulty.is_empty() and difficulty != "Luyện tập":
		detail_parts.append(difficulty)
	var detail := _label("  ·  ".join(detail_parts), 14 if mobile else 15, C_MUTED)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(detail)

	# Primary visual area: Musical Staff with Note 0 illuminated in gold
	staff = Control.new()
	staff.name = "RhythmPreviewStaff"
	staff.set_script(RhythmStaffDisplayScript)
	staff.custom_minimum_size = Vector2(0, 200 if mobile else 235)
	staff.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	staff.call("configure_rhythm", performance_notes, beat_times, round_duration, true)
	staff.call("update_progress", 0.0, judgements)
	card_body.add_child(staff)

	# Microphone readiness indicator
	preview_status = _label("● Micro sẵn sàng", 14, C_OK)
	preview_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(preview_status)

	# 1-line concise instruction
	var instruction_text := "Nghe mẫu, sau đó chơi nốt vàng khi playhead đi qua."
	if Context.instrument == "trong_chau":
		instruction_text = "Nghe mẫu, sau đó gõ nốt vàng khi playhead đi qua."
	var instruction := _label(instruction_text, 14 if mobile else 16, C_TEXT)
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(instruction)

	# CTAs: Secondary Outline for Preview, Primary Green for Start
	var actions := BoxContainer.new()
	actions.vertical = mobile
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_body.add_child(actions)

	preview_button = _secondary_button("▶  Nghe mẫu", 0, 52, C_GREEN_DARK)
	preview_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_button.pressed.connect(_play_sample)
	actions.add_child(preview_button)

	var start := _button("Bắt đầu  →", 0, 54, C_GREEN)
	start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start.pressed.connect(_start_round)
	actions.add_child(start)

	var mode_text := "Đã kết nối · kết quả sẽ được đồng bộ" if online_session else "Chế độ offline · điểm chỉ được tính trên thiết bị"
	var mode_color := C_OK if online_session else C_MUTED
	var mode := _label(mode_text, 12 if mobile else 13, mode_color)
	mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(mode)


func _play_sample() -> void:
	if flow_state == FlowState.PREVIEW:
		if is_instance_valid(sample_player):
			sample_player.call("stop")
		if is_instance_valid(click_player):
			click_player.stop()
		preview_generation += 1
		_set_flow_state(FlowState.INTRO)
		if is_instance_valid(preview_button):
			preview_button.disabled = false
			preview_button.text = "▶  Nghe mẫu"
		if is_instance_valid(preview_status):
			preview_status.text = "● Micro sẵn sàng"
			preview_status.add_theme_color_override("font_color", C_OK)
		if is_instance_valid(staff):
			staff.set_playback_index(0 if not performance_notes.is_empty() else -1)
		return

	if flow_state != FlowState.INTRO:
		return

	preview_generation += 1
	var generation := preview_generation
	_set_flow_state(FlowState.PREVIEW)
	if is_instance_valid(preview_button):
		preview_button.text = "■  Dừng"
	if is_instance_valid(preview_status):
		preview_status.text = "Micro tạm dừng khi phát mẫu"
		preview_status.add_theme_color_override("font_color", C_MUTED)

	if is_instance_valid(audio_analyzer):
		audio_analyzer.set_analysis_suspended(true)

	var bpm := float(_safe_int(rhythms[rhythm_index].get("tempo_bpm", 80), 80))
	var sample_res: Dictionary = {}
	if is_instance_valid(sample_player):
		sample_res = sample_player.call("play_sequence", Context.instrument, performance_notes, -1, bpm)

	if not bool(sample_res.get("ok", false)):
		_run_preview(generation)


func _run_preview(generation: int) -> void:
	var previous_time := 0.0
	for index in beat_times.size():
		var wait_time := maxf(0.01, beat_times[index] - previous_time)
		await get_tree().create_timer(wait_time).timeout
		if generation != preview_generation or not is_inside_tree():
			return
		if is_instance_valid(staff):
			staff.set_playback_index(index)
		_play_click(index == 0)
		previous_time = beat_times[index]
	await get_tree().create_timer(0.35).timeout
	if generation != preview_generation or not is_inside_tree():
		return
	if is_instance_valid(staff):
		staff.set_playback_index(0 if not performance_notes.is_empty() else -1)
	_set_flow_state(FlowState.INTRO)
	if is_instance_valid(preview_button):
		preview_button.text = "↻  Nghe lại"
	if is_instance_valid(preview_status):
		preview_status.text = "● Micro sẵn sàng"
		preview_status.add_theme_color_override("font_color", C_OK)


func _start_round() -> void:
	if flow_state not in [FlowState.INTRO, FlowState.PREVIEW]:
		return
	preview_generation += 1
	if is_instance_valid(click_player):
		click_player.stop()
	if is_instance_valid(sample_player):
		sample_player.call("stop")
	if is_instance_valid(audio_analyzer):
		audio_analyzer.set_analysis_suspended(true)
	session_generation += 1
	var generation := session_generation
	playing = false
	round_accuracy_points = 0
	round_hits = 0
	round_correct_pitch_count = 0
	round_on_time_count = 0
	for index in judgements.size():
		judgements[index] = ""
	_run_countdown(generation)


func _run_countdown(generation: int) -> void:
	_set_flow_state(FlowState.COUNTDOWN)
	_clear_content()
	var mobile := _is_mobile()
	var card_body := _add_centered_card(C_GREEN, 580.0)
	var prompt := _label("Sẵn sàng diễn tấu theo khuông nhạc", 18 if mobile else 22, C_NAVY)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var bold_font := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if bold_font:
		prompt.add_theme_font_override("font", bold_font)
	card_body.add_child(prompt)

	countdown_label = _label("3", 72 if mobile else 88, C_GREEN)
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(countdown_label)

	var hint := _label("Chơi từng nốt trên nhạc cụ thật khi playhead đi qua nốt vàng.", 14, C_MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(hint)

	for value in ["3", "2", "1", "BẮT ĐẦU!"]:
		if generation != session_generation or not is_instance_valid(countdown_label):
			return
		countdown_label.text = value
		_play_click(value == "BẮT ĐẦU!")
		_pulse_control(countdown_label, 1.12)
		await get_tree().create_timer(0.65).timeout

	if generation != session_generation or not is_inside_tree():
		return
	if challenge_started_at.is_empty():
		challenge_started_at = _now_iso()
	round_started_at_ms = Time.get_ticks_msec()
	if is_instance_valid(audio_analyzer):
		audio_analyzer.set_analysis_suspended(false)
		audio_analyzer.start_microphone_capture()
	playing = true
	_set_flow_state(FlowState.PLAYING)
	_build_game()
	await get_tree().create_timer(round_duration).timeout
	if generation == session_generation and playing and is_inside_tree():
		_finish_round()


func _unhandled_input(_event: InputEvent) -> void:
	pass


func _process(_delta: float) -> void:
	if not playing or flow_state != FlowState.PLAYING:
		return
	var elapsed := float(Time.get_ticks_msec() - round_started_at_ms) / 1000.0
	for index in beat_times.size():
		if judgements[index].is_empty() and elapsed > beat_times[index] + GOOD_WINDOW:
			_set_judgement(index, "MISS")
	if performance_mode:
		_process_live_note(elapsed)
	if is_instance_valid(staff):
		staff.call("update_progress", elapsed, judgements)
	if performance_mode:
		_update_microphone_indicator()
	_update_live_metrics()


func _build_game() -> void:
	_clear_content(false)
	var current := rhythms[rhythm_index]
	var mobile := _is_mobile()
	var card_body := _add_centered_card(C_GREEN, 880.0)

	# Clean top row with round chip & mic listening chip
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 10)
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_body.add_child(top_row)

	var round_chip_label := _label("VÒNG %d/%d" % [rhythm_index + 1, rhythms.size()], 12, C_GREEN_DARK)
	top_row.add_child(_chip(round_chip_label, C_GREEN_SOFT, Color(C_GREEN.r, C_GREEN.g, C_GREEN.b, 0.28)))

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)

	var microphone_chip_label := _label("● MICRO ĐANG NGHE", 12, C_OK)
	top_row.add_child(_chip(microphone_chip_label, C_GREEN_SOFT, Color(C_GREEN.r, C_GREEN.g, C_GREEN.b, 0.28)))

	var heading := _label(str(current.get("title", "Đọc khuông nhạc")), 20 if mobile else 24, C_NAVY)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var bold_font := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if bold_font:
		heading.add_theme_font_override("font", bold_font)
	card_body.add_child(heading)

	# Top Live Metrics
	var metrics := HBoxContainer.new()
	metrics.alignment = BoxContainer.ALIGNMENT_CENTER
	metrics.add_theme_constant_override("separation", 24 if mobile else 48)
	card_body.add_child(metrics)
	hit_label = _label("Đúng  0/%d nốt" % beat_times.size(), 15 if mobile else 17, C_NAVY)
	accuracy_label = _label("Độ chính xác  0%", 15 if mobile else 17, C_NAVY)
	hit_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	accuracy_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	metrics.add_child(hit_label)
	metrics.add_child(accuracy_label)

	# Primary Musical Staff with moving Playhead
	staff = Control.new()
	staff.name = "RhythmStaff"
	staff.set_script(RhythmStaffDisplayScript)
	staff.custom_minimum_size = Vector2(0, 210 if mobile else 250)
	staff.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	staff.call("configure_rhythm", performance_notes, beat_times, round_duration, true)
	staff.call("update_progress", 0.0, judgements)
	card_body.add_child(staff)

	# Short, prominent feedback label right below staff
	status_label = _label("CHỜ NHỊP…", 18 if mobile else 22, C_MUTED)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.custom_minimum_size = Vector2(0, 26)
	if bold_font:
		status_label.add_theme_font_override("font", bold_font)
	card_body.add_child(status_label)

	# Dynamic live microphone diagnostics
	microphone_label = _label("● Micro đang nghe · Chờ bạn chơi nốt vàng", 13 if mobile else 14, C_OK)
	microphone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(microphone_label)

	# Bottom instruction (no touch prompt)
	var guidance := _label("Chơi đúng cao độ khi playhead đi qua nốt vàng. Không cần chạm màn hình.", 13 if mobile else 14, C_MUTED)
	guidance.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if Context.instrument == "trong_chau":
		guidance.text = "Gõ đúng nhịp khi playhead đi qua nốt vàng. Không cần chạm màn hình."
	card_body.add_child(guidance)


func _tap() -> void:
	if performance_mode or not playing or flow_state != FlowState.PLAYING:
		return
	var elapsed := float(Time.get_ticks_msec() - round_started_at_ms) / 1000.0
	var decision := RhythmModel.judge_tap(elapsed, beat_times, judgements, PERFECT_WINDOW, GOOD_WINDOW)
	var index := int(decision.get("index", -1))
	if index < 0:
		_show_feedback("CHỜ NHỊP…", C_MUTED)
		return
	var judgement := str(decision.get("judgement", ""))
	_set_judgement(index, judgement)
	if judgement in ["PERFECT", "GOOD"]:
		round_hits += 1
		Input.vibrate_handheld(18 if judgement == "PERFECT" else 10)
	_update_live_metrics()


func _process_live_note(elapsed: float) -> void:
	if not is_instance_valid(audio_analyzer):
		return
	var now_ms := Time.get_ticks_msec()
	if now_ms - last_detected_at_ms < 110:
		return

	if Context.instrument == "trong_chau":
		if audio_analyzer.current_amplitude_db > -45.0 or audio_analyzer.current_pitch_is_reliable:
			var decision := RhythmModel.judge_performance_note(elapsed, beat_times, judgements, true, PERFECT_WINDOW, GOOD_WINDOW)
			var index := int(decision.get("index", -1))
			if index >= 0 and index < performance_notes.size():
				last_detected_at_ms = now_ms
				var judgement := str(decision.get("judgement", "MISS"))
				_set_judgement(index, judgement)
				if judgement in ["PERFECT", "GOOD"]:
					round_hits += 1
					round_correct_pitch_count += 1
					round_on_time_count += 1
				_update_live_metrics()
		return

	if not audio_analyzer.current_pitch_is_reliable or audio_analyzer.current_pitch <= 0.0:
		return

	var candidate_decision := RhythmModel.judge_tap(elapsed, beat_times, judgements, PERFECT_WINDOW, GOOD_WINDOW)
	var index := int(candidate_decision.get("index", -1))
	if index < 0 or index >= performance_notes.size():
		return

	var is_correct_pitch := _matches_expected_pitch(audio_analyzer.current_pitch, performance_notes[index])
	var perf_decision := RhythmModel.judge_performance_note(elapsed, beat_times, judgements, is_correct_pitch, PERFECT_WINDOW, GOOD_WINDOW)
	last_detected_at_ms = now_ms
	var judgement := str(perf_decision.get("judgement", "MISS"))
	_set_judgement(index, judgement)
	if is_correct_pitch:
		round_correct_pitch_count += 1
	if bool(perf_decision.get("timing_ok", false)):
		round_on_time_count += 1
	if judgement in ["PERFECT", "GOOD"]:
		round_hits += 1
	_update_live_metrics()


func _matches_expected_pitch(frequency: float, expected_note: String) -> bool:
	var key := InstrumentSamplePlayer.normalize_note_key(Context.instrument, expected_note)
	if key.length() < 2 or frequency <= 0.0:
		return false
	var letter := key.substr(0, 1).to_upper()
	var octave_text := key.substr(1)
	if not octave_text.is_valid_int():
		return false
	var semitone_map := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
	if not semitone_map.has(letter):
		return false
	var midi := (int(octave_text) + 1) * 12 + int(semitone_map[letter])
	var reference := 440.0 * pow(2.0, (float(midi) - 69.0) / 12.0)
	var cents := 1200.0 * log(frequency / reference) / log(2.0)
	return absf(cents) <= 75.0


func _set_judgement(index: int, value: String) -> void:
	if index < 0 or index >= judgements.size() or not judgements[index].is_empty():
		return
	judgements[index] = value
	if value == "PERFECT":
		round_accuracy_points += 100
		_show_feedback("PERFECT  +100", C_OK)
	elif value == "GOOD":
		var points := 88 if performance_mode else 70
		round_accuracy_points += points
		_show_feedback("GOOD  +%d" % points, Color("#2563eb"))
	elif value == "WRONG_NOTE":
		_show_feedback("SAI NỐT", C_BAD)
	else:
		_show_feedback("MISS", C_BAD)
	if is_instance_valid(staff):
		staff.call("update_progress", float(Time.get_ticks_msec() - round_started_at_ms) / 1000.0, judgements)


func _show_feedback(text_value: String, color: Color) -> void:
	if not is_instance_valid(status_label):
		return
	status_label.text = text_value
	status_label.add_theme_color_override("font_color", color)
	_pulse_control(status_label, 1.08)


func _update_microphone_indicator() -> void:
	if not is_instance_valid(microphone_label) or not is_instance_valid(audio_analyzer):
		return
	if not audio_analyzer.has_microphone_permission():
		microphone_label.text = "! Cần cấp quyền micro để hệ thống chấm bài."
		microphone_label.add_theme_color_override("font_color", C_BAD)
		return
	var diagnostics := audio_analyzer.get_microphone_diagnostics()
	var capture_status := str(diagnostics.get("status", "starting"))
	if capture_status == "receiving":
		var pitch := audio_analyzer.current_pitch
		if audio_analyzer.current_pitch_is_reliable and pitch > 0.0:
			microphone_label.text = "● Micro đang nghe · Phát hiện %.1f Hz" % pitch
		else:
			microphone_label.text = "● Micro đang nghe · Chờ bạn chơi nốt vàng"
		microphone_label.add_theme_color_override("font_color", C_OK)
	elif capture_status in ["no_frames", "silent_stream"]:
		microphone_label.text = "! Không nhận được tín hiệu micro. Kiểm tra thiết bị đầu vào."
		microphone_label.add_theme_color_override("font_color", C_BAD)
	else:
		microphone_label.text = "Micro đang khởi động…"
		microphone_label.add_theme_color_override("font_color", C_MUTED)


func _update_live_metrics() -> void:
	var accuracy := RhythmModel.accuracy_percent(round_accuracy_points, beat_times.size())
	if is_instance_valid(hit_label):
		hit_label.text = "Đúng  %d/%d nốt" % [round_hits, beat_times.size()]
	if is_instance_valid(accuracy_label):
		accuracy_label.text = "Độ chính xác  %.0f%%" % accuracy


func _finish_round() -> void:
	if not playing:
		return
	playing = false
	if is_instance_valid(audio_analyzer):
		audio_analyzer.set_analysis_suspended(true)
	_set_flow_state(FlowState.SUBMITTING)

	var current := rhythms[rhythm_index]
	var round_accuracy := RhythmModel.accuracy_percent(round_accuracy_points, beat_times.size())
	challenge_accuracy_points += round_accuracy_points
	challenge_beat_count += beat_times.size()
	total_accuracy_points += round_accuracy_points
	total_beat_count += beat_times.size()
	total_correct_pitch_count += round_correct_pitch_count
	total_on_time_count += round_on_time_count

	var max_score := _safe_int(current.get("max_score", 100), 100)
	var round_score := RhythmModel.scaled_score(round_accuracy_points, beat_times.size(), max_score)

	if bool(current.get("submit_after", true)):
		var challenge_score := RhythmModel.scaled_score(challenge_accuracy_points, challenge_beat_count, max_score)
		var preview_stars := RhythmModel.stars_for_score(challenge_score, max_score)
		total_score += challenge_score
		total_max_score += max_score
		var payload := {
			"minigame_id": _safe_int(current.get("challenge_id", 0)),
			"score": challenge_score,
			"stars": preview_stars,
			"started_at": challenge_started_at,
			"completed_at": _now_iso(),
			"client_attempt_id": _new_attempt_id(),
			"title": str(current.get("title", "Đọc khuông nhạc")),
		}
		if online_session and int(payload["minigame_id"]) > 0:
			_build_submitting("Đang lưu kết quả vòng %d…" % (rhythm_index + 1))
			var submitted := await _submit_payload(payload)
			if not submitted:
				sync_failures.append(payload)
		challenge_accuracy_points = 0
		challenge_beat_count = 0
		challenge_started_at = ""

	if rhythm_index + 1 < rhythms.size():
		_build_round_result(round_score, max_score)
		return
	if online_session and sync_failures.is_empty() and submitted_count > 0:
		var report := _report()
		if report != null:
			await report.refresh_progress_from_backend()
	_build_final_result()


func _submit_payload(payload: Dictionary) -> bool:
	var report := _report()
	if report == null or not report.is_signed_in():
		payload["error"] = "Phiên đăng nhập không còn hiệu lực."
		return false
	var minigame_id := int(payload.get("minigame_id", 0))
	if minigame_id <= 0:
		return true
	var score := int(payload.get("score", 0))
	var preview_stars := int(payload.get("stars", 0))
	var start_str := str(payload.get("started_at", ""))
	var completed_str := str(payload.get("completed_at", ""))
	var client_id := str(payload.get("client_attempt_id", ""))
	var result: Dictionary = await report.report_minigame_by_id(minigame_id, score, preview_stars, start_str, completed_str, client_id)
	if bool(result.get("submitted", false)):
		submitted_count += 1
		backend_stars_earned = maxi(backend_stars_earned, int(result.get("stars_earned", 0)))
		backend_points_earned = maxi(backend_points_earned, int(result.get("points_earned", 0)))
		result_sync_status = "be"
		return true
	elif bool(result.get("queued", false)) or str(result.get("reason", "")) == "attempt_failed":
		result_sync_status = "failed"
		return false
	else:
		result_sync_status = "offline"
		return false


func _build_round_result(round_score: int, round_max_score: int) -> void:
	_set_flow_state(FlowState.ROUND_RESULT)
	_clear_content()
	_update_top_bar_badge()

	var mobile := _is_mobile()
	var card_body := _add_centered_card(C_GREEN, 780.0)

	var icon := _label("✓", 56 if mobile else 64, C_OK)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(icon)

	var heading := _label("Vòng %d hoàn thành!" % (rhythm_index + 1), 22 if mobile else 26, C_NAVY)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var bold_font := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if bold_font:
		heading.add_theme_font_override("font", bold_font)
	card_body.add_child(heading)

	# Retain musical staff with colored judgements
	var result_staff: Control = Control.new()
	result_staff.name = "RoundResultStaff"
	result_staff.set_script(RhythmStaffDisplayScript)
	result_staff.custom_minimum_size = Vector2(0, 190 if mobile else 220)
	result_staff.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_staff.call("configure_rhythm", performance_notes, beat_times, round_duration, true)
	result_staff.call("update_progress", round_duration, judgements)
	card_body.add_child(result_staff)

	# Exactly 3 key metric cards
	var pitch_acc := RhythmModel.pitch_accuracy_percent(round_correct_pitch_count, beat_times.size())
	var time_acc := RhythmModel.timing_accuracy_percent(round_on_time_count, beat_times.size())

	var metrics := GridContainer.new()
	metrics.columns = 3
	metrics.add_theme_constant_override("h_separation", 10 if mobile else 14)
	metrics.add_theme_constant_override("v_separation", 10)
	metrics.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_body.add_child(metrics)

	metrics.add_child(_metric_card("♫", "Đúng cao độ", "%.0f%%" % pitch_acc, Color("#059669")))
	metrics.add_child(_metric_card("⏱", "Đúng nhịp", "%.0f%%" % time_acc, Color("#2563eb")))
	metrics.add_child(_metric_card("◆", "Điểm tổng", "%d / %d" % [round_score, round_max_score], Color("#c59626")))

	var next_title := str(rhythms[rhythm_index + 1].get("title", "Thử thách tiếp theo"))
	var next_hint := _label("Tiếp theo: %s" % next_title, 13 if mobile else 14, C_MUTED)
	next_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(next_hint)

	var next_button := _button("Vòng tiếp theo  →", 0, 56, C_GREEN)
	next_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_button.pressed.connect(func() -> void:
		rhythm_index += 1
		_build_intro()
	)
	card_body.add_child(next_button)


func _build_submitting(message: String) -> void:
	_set_flow_state(FlowState.SUBMITTING)
	_build_loading(message)


func _build_final_result() -> void:
	_set_flow_state(FlowState.FINAL_RESULT)
	_clear_content()
	_update_top_bar_badge()

	content_box.alignment = BoxContainer.ALIGNMENT_CENTER
	content_box.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var mobile := _is_mobile()
	var card_body := _add_centered_card(C_GOLD, 820.0)
	var stars := RhythmModel.stars_for_score(total_score, total_max_score)
	var pitch_acc := RhythmModel.pitch_accuracy_percent(total_correct_pitch_count, total_beat_count)
	var time_acc := RhythmModel.timing_accuracy_percent(total_on_time_count, total_beat_count)

	var icon := _label("★" if stars > 0 else "✓", 58 if mobile else 70, C_GOLD if stars > 0 else C_OK)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(icon)

	var heading := _label("Nhịp điệu hoàn thành!", 22 if mobile else 28, C_NAVY)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var bold_font := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if bold_font:
		heading.add_theme_font_override("font", bold_font)
	card_body.add_child(heading)

	var detail := _label("Bạn đã hoàn thành %d phách trong %d vòng thử thách." % [total_beat_count, rhythms.size()], 14 if mobile else 16, C_MUTED)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(detail)

	# Retain musical staff with results
	if not performance_notes.is_empty():
		var final_staff: Control = Control.new()
		final_staff.name = "FinalResultStaff"
		final_staff.set_script(RhythmStaffDisplayScript)
		final_staff.custom_minimum_size = Vector2(0, 180 if mobile else 210)
		final_staff.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		final_staff.call("configure_rhythm", performance_notes, beat_times, round_duration, true)
		final_staff.call("update_progress", round_duration, judgements)
		card_body.add_child(final_staff)

	# Exactly 3 key metrics cards as requested
	var metrics := GridContainer.new()
	metrics.columns = 3
	metrics.add_theme_constant_override("h_separation", 10 if mobile else 14)
	metrics.add_theme_constant_override("v_separation", 10)
	metrics.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_body.add_child(metrics)

	metrics.add_child(_metric_card("♫", "Đúng cao độ", "%.0f%%" % pitch_acc, Color("#059669")))
	metrics.add_child(_metric_card("⏱", "Đúng nhịp", "%.0f%%" % time_acc, Color("#2563eb")))
	metrics.add_child(_metric_card("◆", "Điểm tổng", "%d / %d" % [total_score, total_max_score], Color("#c59626")))

	var sync_text := "○ Luyện tập offline · kết quả lưu trên thiết bị"
	var sync_color := C_MUTED
	if online_session and Context.backend_lesson_id > 0:
		if submitted_count > 0:
			sync_text = "✓ Đã xác nhận bởi hệ thống · Nhận %d sao" % backend_stars_earned
			sync_color = C_OK
		elif result_sync_status == "failed" or not sync_failures.is_empty():
			sync_text = "⚠ Đang chờ đồng bộ · XP và Sao đang là dự kiến"
			sync_color = C_BAD
		else:
			sync_text = "Chưa có kết quả hợp lệ để đồng bộ"
			sync_color = C_MUTED
	elif not online_session:
		var local_entry := {
			"kind": "minigame_local",
			"client_attempt_id": _new_attempt_id(),
			"title": "Đọc khuông nhạc",
			"lessonTitle": _instrument_title(),
			"score": total_score,
			"maxScore": total_max_score,
			"completedAt": _now_iso(),
			"status": "LOCAL_ONLY",
		}
		SecureDataManager.record_local_activity(local_entry)

	var sync := _label(sync_text, 13 if mobile else 14, sync_color)
	sync.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(sync)

	if not sync_failures.is_empty():
		var retry_sync := _secondary_button("↻  Thử đồng bộ lại", 0, 52, C_BAD)
		retry_sync.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		retry_sync.pressed.connect(_retry_sync)
		card_body.add_child(retry_sync)

	var actions := BoxContainer.new()
	actions.vertical = mobile
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_body.add_child(actions)

	var retry := _button("Chơi lại", 0, 56, C_GREEN)
	retry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	retry.pressed.connect(_restart)
	actions.add_child(retry)

	var back := _secondary_button("Về hoạt động", 0, 56, C_NAVY)
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.pressed.connect(_go_back)
	actions.add_child(back)


func _retry_sync() -> void:
	if sync_failures.is_empty():
		return
	_build_submitting("Đang thử đồng bộ lại…")
	var pending := sync_failures.duplicate(true)
	sync_failures.clear()
	for payload_value: Variant in pending:
		if not payload_value is Dictionary:
			continue
		var payload: Dictionary = payload_value
		var submitted := await _submit_payload(payload)
		if not submitted:
			sync_failures.append(payload)
	if sync_failures.is_empty():
		var report := _report()
		if report != null:
			await report.refresh_progress_from_backend()
	_build_final_result()


func _restart() -> void:
	_reset_run()
	_build_intro()


func _build_loading(message: String) -> void:
	_clear_content()
	content_box.alignment = BoxContainer.ALIGNMENT_CENTER
	content_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var mobile := _is_mobile()
	var card_body := _add_centered_card(C_GREEN, 580.0)

	var heading := _label(message, 18 if mobile else 21, C_NAVY)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var bold_font := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if bold_font:
		heading.add_theme_font_override("font", bold_font)
	card_body.add_child(heading)

	var hint := _label("VietStage đang chuẩn bị dữ liệu và khuông nhạc cho bạn.", 14, C_MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(hint)


func _build_load_error(title: String, description: String, allow_retry: bool = true) -> void:
	_clear_content()
	content_box.alignment = BoxContainer.ALIGNMENT_CENTER
	content_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var mobile := _is_mobile()
	var card_body := _add_centered_card(C_BAD, 640.0)

	var icon := _label("!", 54, C_BAD)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(icon)

	var heading := _label(title, 20 if mobile else 24, C_NAVY)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var bold_font := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if bold_font:
		heading.add_theme_font_override("font", bold_font)
	card_body.add_child(heading)

	var detail := _label(description, 14 if mobile else 16, C_MUTED)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(detail)

	var actions := BoxContainer.new()
	actions.vertical = mobile
	actions.add_theme_constant_override("separation", 12)
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_body.add_child(actions)

	if allow_retry:
		var retry := _button("Thử tải lại", 0, 54, Color("#2563eb"))
		retry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		retry.pressed.connect(_load_challenges)
		actions.add_child(retry)

	var offline := _secondary_button("Chơi offline", 0, 54, C_GREEN_DARK)
	offline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	offline.pressed.connect(_use_offline_data)
	actions.add_child(offline)


func _prepare_current_round() -> void:
	var current := rhythms[rhythm_index]
	beat_times.clear()
	for value: Variant in current.get("beats", []):
		beat_times.append(float(value))
	performance_notes.clear()
	for value: Variant in current.get("notes", []):
		performance_notes.append(str(value))
	if performance_notes.is_empty() or performance_notes.size() != beat_times.size():
		performance_notes = RhythmModel.default_notes_for_instrument(Context.instrument, beat_times.size())
	performance_mode = true
	judgements.clear()
	for _beat in beat_times:
		judgements.append("")
	round_duration = (beat_times[-1] if not beat_times.is_empty() else 2.0) + 1.0
	last_detected_at_ms = -1000


func _clear_content(stop_preview: bool = true) -> void:
	if stop_preview:
		preview_generation += 1
	if is_instance_valid(click_player):
		click_player.stop()
	for child in content_box.get_children():
		child.queue_free()
	content_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	content_box.size_flags_vertical = Control.SIZE_FILL
	content_box.add_theme_constant_override("separation", 14 if _is_mobile() else 18)
	status_label = null
	microphone_label = null
	accuracy_label = null
	hit_label = null
	timeline = null
	staff = null
	countdown_label = null
	preview_button = null
	preview_status = null


func _add_centered_card(accent: Color, max_width: float) -> VBoxContainer:
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_box.add_child(center)
	var card := PanelContainer.new()
	var available := maxf(280.0, get_viewport_rect().size.x - (28.0 if _is_mobile() else 96.0))
	card.custom_minimum_size = Vector2(minf(max_width, available), 0)
	card.add_theme_stylebox_override("panel", _game_card_style(accent))
	center.add_child(card)
	var body := VBoxContainer.new()
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 10 if _is_mobile() else 12)
	card.add_child(body)
	return body


func _game_card_style(accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 1.0, 0.98)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.58)
	style.set_border_width_all(2)
	style.set_corner_radius_all(20)
	style.shadow_color = Color(accent.r, accent.g, accent.b, 0.18)
	style.shadow_size = 16
	style.shadow_offset = Vector2(0, 6)
	var horizontal_margin := 16.0 if _is_mobile() else 30.0
	var vertical_margin := 18.0 if _is_mobile() else 22.0
	style.content_margin_left = horizontal_margin
	style.content_margin_right = horizontal_margin
	style.content_margin_top = vertical_margin
	style.content_margin_bottom = vertical_margin
	return style


func _soft_panel(background: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func _chip(label: Label, background: Color, border: Color) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	chip.add_theme_stylebox_override("panel", _soft_panel(background, border, 16))
	chip.add_child(label)
	return chip


func _set_flow_state(next_state: int) -> void:
	flow_state = next_state


func _on_viewport_size_changed() -> void:
	if flow_state == FlowState.INTRO:
		_build_intro()
	elif flow_state == FlowState.ROUND_RESULT:
		var current := rhythms[rhythm_index]
		var max_score := _safe_int(current.get("max_score", 100), 100)
		var round_score := RhythmModel.scaled_score(round_accuracy_points, beat_times.size(), max_score)
		_build_round_result(round_score, max_score)
	elif flow_state == FlowState.FINAL_RESULT:
		_build_final_result()


func _pulse_control(control: Control, target_scale: float) -> void:
	if not is_instance_valid(control):
		return
	control.pivot_offset = control.size * 0.5
	var tween := create_tween()
	tween.tween_property(control, "scale", Vector2.ONE * target_scale, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _play_click(accent: bool = false) -> void:
	if not is_instance_valid(click_player):
		return
	click_player.stream = accent_stream if accent else click_stream
	click_player.play()


func _make_click_stream(frequency: float) -> AudioStreamWAV:
	const SAMPLE_RATE := 22050
	const DURATION := 0.09
	var sample_count := int(SAMPLE_RATE * DURATION)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for index in sample_count:
		var time := float(index) / float(SAMPLE_RATE)
		var envelope := exp(-time * 38.0)
		var sample := sin(TAU * frequency * time) * envelope * 0.42
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0) & 0xFFFF
		data[index * 2] = value & 0xFF
		data[index * 2 + 1] = (value >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream


func _new_attempt_id() -> String:
	return "rhythm-%d-%04x-%04x" % [int(Time.get_unix_time_from_system()), randi_range(0, 0xFFFF), randi_range(0, 0xFFFF)]


func _is_mobile() -> bool:
	return get_viewport_rect().size.x < 720.0


func _safe_int(value: Variant, fallback: int = 0) -> int:
	if value == null:
		return fallback
	var text := str(value).strip_edges()
	return int(text) if text.is_valid_int() else fallback
