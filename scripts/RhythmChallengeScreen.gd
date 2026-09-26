extends "res://scripts/LearningActivityBase.gd"

const RhythmModel = preload("res://scripts/RhythmChallengeModel.gd")
const RhythmStaffDisplayScript = preload("res://scripts/RhythmStaffDisplay.gd")
const InstrumentSamplePlayerScript = preload("res://scripts/InstrumentSamplePlayer.gd")
const AudioCaptureAnalyzerScript = preload("res://scripts/AudioCaptureAnalyzer.gd")
const DanTranhAudio = preload("res://scripts/DanTranhAudio.gd")
const PracticeControlHudScript = preload("res://scripts/PracticeControlHud.gd")

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
	PAUSED,
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
var event_modes: Array[String] = []
var current_time_signature: Array = [4, 4]
var current_durations_beats: Array[float] = []
var current_tempo_bpm: int = 80
var selected_speed_multiplier: float = 1.0
var practice_hud: PracticeControlHud
var paused_elapsed := 0.0
var sample_from_pause := false
var paused_sample_generation := 0
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
var status_label: Label
var microphone_label: Label
var accuracy_label: Label
var hit_label: Label
var timeline: Control
var countdown_label: Label
var preview_button: Button
var preview_status: Label
var compact_footer: PanelContainer
var click_player: AudioStreamPlayer
var click_stream: AudioStreamWAV
var accent_stream: AudioStreamWAV

var load_generation := 0
var session_generation := 0
var preview_generation := 0


func _ready() -> void:
	super._ready()
	_setup_custom_header_and_backdrop()
	_setup_practice_hud()
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


func _setup_practice_hud() -> void:
	practice_hud = PracticeControlHudScript.new() as PracticeControlHud
	practice_hud.name = "RhythmPracticeHud"
	add_child(practice_hud)
	practice_hud.back_requested.connect(_go_back)
	practice_hud.speed_selected.connect(_on_hud_speed_selected)
	practice_hud.pause_requested.connect(_pause_round)
	practice_hud.resume_requested.connect(_resume_round)
	practice_hud.restart_requested.connect(_restart_round_from_pause)
	practice_hud.sample_requested.connect(_play_sample_from_pause)
	practice_hud.set_speed(selected_speed_multiplier)
	# Match the instrument lessons: tempo is immediately left of Pause.
	practice_hud.set_speed_centered(false)
	practice_hud.set_playback_controls_visible(false)


func _set_hud_mode(playback_active: bool) -> void:
	if not is_instance_valid(practice_hud):
		return
	var compact := _is_compact_height()
	var content_margin := content_box.get_parent() as MarginContainer
	if is_instance_valid(content_margin):
		content_margin.add_theme_constant_override("margin_top", 4 if compact else (18 if _is_mobile() else 28))
		content_margin.add_theme_constant_override("margin_bottom", 4 if compact else _bottom_inset(_is_mobile()))
	if is_instance_valid(custom_top_bar):
		var speed_visible := flow_state in [FlowState.INTRO, FlowState.PREVIEW, FlowState.PLAYING, FlowState.PAUSED]
		var needs_second_row := speed_visible and practice_hud.needs_second_row(get_viewport_rect().size.x)
		custom_top_bar.custom_minimum_size.y = 160.0 if needs_second_row else (84.0 if _is_mobile() else 86.0)
	practice_hud.set_hud_visible(true)
	# The shared tempo control is available before a round starts; pause appears
	# only while the performance clock is active.
	practice_hud.set_speed_controls_visible(flow_state in [FlowState.INTRO, FlowState.PREVIEW, FlowState.PLAYING, FlowState.PAUSED])
	practice_hud.set_pause_button_visible(playback_active)
	if not playback_active and flow_state != FlowState.PAUSED:
		practice_hud.set_pause_visible(false)
	practice_hud.set_speed(selected_speed_multiplier)


func _on_hud_speed_selected(multiplier: float) -> void:
	# Tempo changes are intentionally committed before a round begins. Changing
	# the timing window mid-note would make a correct performance look incorrect.
	if flow_state not in [FlowState.INTRO, FlowState.PREVIEW, FlowState.PAUSED]:
		if is_instance_valid(practice_hud):
			practice_hud.set_speed(selected_speed_multiplier)
		return
	selected_speed_multiplier = multiplier
	_prepare_current_round()
	if flow_state in [FlowState.INTRO, FlowState.PREVIEW]:
		_build_intro()
	if is_instance_valid(practice_hud):
		practice_hud.set_speed(multiplier)


func _setup_custom_header_and_backdrop() -> void:
	# Hide default bulky top bar from LearningActivityBase
	if root_box.get_child_count() > 0:
		var default_top := root_box.get_child(0) as Control
		if default_top:
			default_top.visible = false
	# Use the same room and warm translucent wash as the instrument lessons.
	# The activity shell created these two layers before this screen initialized.
	var room_background := get_child(0) as TextureRect
	if room_background:
		room_background.texture = load("res://assets/textures/bg_practice_room.png") as Texture2D
	var room_wash := get_child(1) as ColorRect
	if room_wash:
		room_wash.color = Color(0.95, 0.93, 0.89, 0.95)

	# Transparent spacer for the shared HUD. Profile remains on the activity screen;
	# round progress is displayed with the round title instead.
	var mobile := _is_mobile()
	custom_top_bar = PanelContainer.new()
	custom_top_bar.name = "RhythmCustomTopBar"
	custom_top_bar.custom_minimum_size = Vector2(0, 84 if mobile else 86)
	custom_top_bar.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	root_box.add_child(custom_top_bar)
	root_box.move_child(custom_top_bar, 0)

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
	if Context.instrument == "dan_tranh":
		# Minigame 1 only accepts the 17 real strings and uses their physical
		# range, avoiding false matches to chromatic notes without a real sample.
		return DanTranhAudio.make_real_string_pitch_profile(60.0)
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


func _notation_notes() -> Array[String]:
	# The lesson/editor uses instrument labels (for example Đô4 on đàn tranh),
	# whereas standard notation needs the corresponding absolute pitch (C6).
	# Normalize only the renderer input: playback and assessment continue to use
	# the exact authored instrument label in performance_notes.
	var result: Array[String] = []
	for authored_note in performance_notes:
		var scientific := InstrumentSamplePlayer.normalize_note_key(Context.instrument, authored_note)
		result.append(scientific if not scientific.is_empty() else authored_note)
	return result


func _on_sample_note_started(index: int) -> void:
	if is_instance_valid(staff):
		staff.set_playback_index(index)


func _on_sample_finished() -> void:
	if sample_from_pause:
		_finish_paused_sample()
		return
	if flow_state == FlowState.PREVIEW:
		_set_flow_state(FlowState.INTRO)
		if is_instance_valid(preview_button):
			_set_preview_button_state("Nghe lại")
		_refresh_intro_microphone_status()
	if is_instance_valid(staff):
		staff.set_playback_index(0 if not performance_notes.is_empty() else -1)
	if is_instance_valid(audio_analyzer):
		audio_analyzer.set_analysis_suspended(true)


func _on_sample_failed(details: Dictionary) -> void:
	if sample_from_pause:
		_finish_paused_sample()
		return
	if flow_state == FlowState.PREVIEW:
		_set_flow_state(FlowState.INTRO)
	if is_instance_valid(preview_button):
		preview_button.disabled = false
		_set_preview_button_state("Nghe mẫu")
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
	_set_hud_mode(false)
	_clear_content()
	_prepare_current_round()

	var current := rhythms[rhythm_index]
	var mobile := _is_mobile()
	var card_body := _add_centered_card(C_GOLD, 1760.0)
	card_body.add_theme_constant_override("separation", 6 if mobile else 10)
	card_body.name = "RhythmIntroCard"
	_add_round_plaque(card_body, str(current.get("title", "Đọc khuông nhạc")))

	# Primary visual area: Musical Staff (2 measures per screen)
	staff = Control.new()
	staff.name = "RhythmPreviewStaff"
	staff.set_script(RhythmStaffDisplayScript)
	staff.custom_minimum_size = Vector2(0, 136 if _is_compact_height() else (190 if mobile else 285))
	staff.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	staff.call("configure_rhythm", _notation_notes(), beat_times, round_duration, false, false, event_modes, current_time_signature, current_durations_beats, current_tempo_bpm)
	staff.call("update_progress", 0.0, judgements)
	card_body.add_child(staff)

	# Dedicated measure navigator placed directly under staff (only if total_measures > 2)
	var nav_row := _create_measure_navigator(staff)
	if nav_row:
		card_body.add_child(nav_row)
	_add_event_legend(card_body, mobile)

	# Microphone readiness indicator
	preview_status = _label("Micro chưa kiểm tra", 14, C_MUTED)
	preview_status.name = "MicrophoneStatus"
	preview_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var micro_chip := _chip(preview_status, Color("#f0f9f3"), Color(C_OK.r, C_OK.g, C_OK.b, 0.24))
	if _is_compact_height():
		compact_footer = _create_compact_footer()
		var footer_stack := VBoxContainer.new()
		footer_stack.add_theme_constant_override("separation", 2)
		compact_footer.add_child(footer_stack)
		footer_stack.add_child(micro_chip)
	else:
		card_body.add_child(micro_chip)
	_refresh_intro_microphone_status()

	# CTAs: Secondary Outline for Preview, Primary Green for Start
	var actions := BoxContainer.new()
	# Landscape phones retain two equal-width actions above the safe area; a
	# portrait fallback stacks them to avoid narrow labels.
	actions.vertical = mobile and not _is_compact_height()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if _is_compact_height():
		var footer_stack := compact_footer.get_child(0) as VBoxContainer
		footer_stack.add_child(actions)
	else:
		card_body.add_child(actions)

	preview_button = _secondary_button("Nghe mẫu", 0, 54, C_GREEN_DARK)
	_set_preview_button_state("Nghe mẫu")
	preview_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_button.pressed.connect(_play_sample)
	actions.add_child(preview_button)

	var start := _button("Bắt đầu", 0, 54, C_GREEN)
	start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start.pressed.connect(_start_round)
	actions.add_child(start)


func _refresh_intro_microphone_status() -> void:
	if not is_instance_valid(preview_status):
		return
	if not is_instance_valid(audio_analyzer):
		preview_status.text = "Micro không khả dụng"
		preview_status.add_theme_color_override("font_color", C_BAD)
	elif not audio_analyzer.has_microphone_permission():
		preview_status.text = "Cần cấp quyền micro"
		preview_status.add_theme_color_override("font_color", C_BAD)
	else:
		# Capture starts with the round; permission alone does not prove input.
		preview_status.text = "Micro sẽ kiểm tra khi bắt đầu"
		preview_status.add_theme_color_override("font_color", C_MUTED)


func _set_preview_button_state(label_text: String) -> void:
	if not is_instance_valid(preview_button):
		return
	preview_button.text = label_text


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
			_set_preview_button_state("Nghe mẫu")
		_refresh_intro_microphone_status()
		if is_instance_valid(staff):
			staff.set_playback_index(0 if not performance_notes.is_empty() else -1)
		return

	if flow_state != FlowState.INTRO:
		return

	preview_generation += 1
	var generation := preview_generation
	_set_flow_state(FlowState.PREVIEW)
	if is_instance_valid(preview_button):
		_set_preview_button_state("Dừng")
	if is_instance_valid(preview_status):
		preview_status.text = "Micro tạm dừng khi phát mẫu"
		preview_status.add_theme_color_override("font_color", C_MUTED)

	if is_instance_valid(audio_analyzer):
		audio_analyzer.set_analysis_suspended(true)

	var bpm := float(current_tempo_bpm)
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
		_set_preview_button_state("Nghe lại")
	_refresh_intro_microphone_status()


func _start_round() -> void:
	if flow_state not in [FlowState.INTRO, FlowState.PREVIEW]:
		return
	preview_generation += 1
	paused_elapsed = 0.0
	sample_from_pause = false
	paused_sample_generation += 1
	if is_instance_valid(practice_hud):
		practice_hud.set_pause_visible(false)
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
	_set_hud_mode(false)
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

	var hint := _label("Chơi từng nốt trên nhạc cụ thật khi playhead đi qua nốt xám.", 14, C_MUTED)
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
	_set_hud_mode(true)
	_build_game()
	while generation == session_generation and is_inside_tree():
		await get_tree().process_frame
		if playing and flow_state == FlowState.PLAYING and _round_elapsed() >= round_duration:
			_finish_round()
			return


func _unhandled_input(_event: InputEvent) -> void:
	pass


func _round_elapsed() -> float:
	if flow_state == FlowState.PAUSED:
		return paused_elapsed
	return maxf(0.0, float(Time.get_ticks_msec() - round_started_at_ms) / 1000.0)


func _pause_round() -> void:
	if flow_state != FlowState.PLAYING or not playing:
		return
	paused_elapsed = _round_elapsed()
	playing = false
	_set_flow_state(FlowState.PAUSED)
	if is_instance_valid(click_player):
		click_player.stop()
	if is_instance_valid(sample_player):
		sample_player.call("stop")
	if is_instance_valid(audio_analyzer):
		audio_analyzer.set_analysis_suspended(true)
	if is_instance_valid(practice_hud):
		practice_hud.set_action_labels("Tiếp tục", "Nghe mẫu")
		practice_hud.set_pause_visible(true)


func _resume_round() -> void:
	if flow_state != FlowState.PAUSED or sample_from_pause:
		return
	round_started_at_ms = Time.get_ticks_msec() - int(paused_elapsed * 1000.0)
	playing = true
	_set_flow_state(FlowState.PLAYING)
	if is_instance_valid(audio_analyzer):
		audio_analyzer.set_analysis_suspended(false)
		audio_analyzer.start_microphone_capture()
	if is_instance_valid(practice_hud):
		practice_hud.set_pause_visible(false)


func _restart_round_from_pause() -> void:
	if flow_state != FlowState.PAUSED:
		return
	sample_from_pause = false
	paused_sample_generation += 1
	if is_instance_valid(sample_player):
		sample_player.call("stop")
	if is_instance_valid(click_player):
		click_player.stop()
	if is_instance_valid(audio_analyzer):
		audio_analyzer.set_analysis_suspended(true)
	if is_instance_valid(practice_hud):
		practice_hud.set_pause_visible(false)
	paused_elapsed = 0.0
	_set_flow_state(FlowState.INTRO)
	_start_round()


func _play_sample_from_pause() -> void:
	if flow_state != FlowState.PAUSED or sample_from_pause:
		return
	sample_from_pause = true
	paused_sample_generation += 1
	var generation := paused_sample_generation
	if is_instance_valid(practice_hud):
		practice_hud.set_pause_visible(false)
	if is_instance_valid(audio_analyzer):
		audio_analyzer.set_analysis_suspended(true)
	var played := false
	if is_instance_valid(sample_player):
		var response: Dictionary = sample_player.call("play_sequence", Context.instrument, performance_notes, -1, float(current_tempo_bpm))
		played = bool(response.get("ok", false))
	if not played:
		_run_paused_sample(generation)


func _run_paused_sample(generation: int) -> void:
	var previous_time := 0.0
	for index in beat_times.size():
		await get_tree().create_timer(maxf(0.01, beat_times[index] - previous_time)).timeout
		if generation != paused_sample_generation or not is_inside_tree():
			return
		if is_instance_valid(staff):
			staff.set_playback_index(index)
		_play_click(index == 0)
		previous_time = beat_times[index]
	await get_tree().create_timer(0.25).timeout
	if generation == paused_sample_generation and is_inside_tree():
		_finish_paused_sample()


func _finish_paused_sample() -> void:
	if not sample_from_pause:
		return
	sample_from_pause = false
	if is_instance_valid(staff):
		staff.call("update_progress", paused_elapsed, judgements)
	if is_instance_valid(practice_hud):
		practice_hud.set_action_labels("Tiếp tục", "Nghe lại")
		practice_hud.set_pause_visible(true)


func _process(_delta: float) -> void:
	if not playing or flow_state != FlowState.PLAYING:
		return
	var elapsed := _round_elapsed()
	for index in beat_times.size():
		if index < event_modes.size() and event_modes[index] == "SAMPLE":
			if judgements[index].is_empty() and elapsed >= beat_times[index]:
				judgements[index] = "SAMPLE"
				call_deferred("_play_sample_event", index)
			continue
		if judgements[index].is_empty() and elapsed > beat_times[index] + GOOD_WINDOW:
			_set_judgement(index, "MISS")
	if performance_mode:
		_process_live_note(elapsed)
	if is_instance_valid(staff):
		staff.call("update_progress", elapsed, judgements)
	if performance_mode:
		_update_microphone_indicator()
	_update_live_metrics()


func _play_sample_event(index: int) -> void:
	if index < 0 or index >= performance_notes.size() or not is_inside_tree():
		return
	# Do not let the device speaker's sample be judged as a learner note.
	if is_instance_valid(audio_analyzer):
		audio_analyzer.set_analysis_suspended(true)
	if is_instance_valid(sample_player):
		sample_player.call("play_sequence", Context.instrument, [performance_notes[index]], -1, 240.0)
	await get_tree().create_timer(0.32).timeout
	if is_inside_tree() and playing and is_instance_valid(audio_analyzer):
		audio_analyzer.set_analysis_suspended(false)


func _build_game() -> void:
	_clear_content(false)
	var mobile := _is_mobile()
	# During a round, notation and immediate feedback are the only information a
	# learner needs.  Round title, mic status, counts and legends are intentionally
	# removed to leave the largest possible visual field for the score.
	var card_body := _add_centered_card(C_GOLD, 1800.0)
	card_body.name = "RhythmPlayCard"
	card_body.add_theme_constant_override("separation", 8 if mobile else 12)
	if rhythm_index < rhythms.size():
		_add_round_plaque(card_body, str(rhythms[rhythm_index].get("title", "Đọc khuông nhạc")))

	# Primary Musical Staff with moving Playhead
	staff = Control.new()
	staff.name = "RhythmStaff"
	staff.set_script(RhythmStaffDisplayScript)
	staff.custom_minimum_size = Vector2(0, 136 if _is_compact_height() else (225 if mobile else 340))
	staff.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	staff.call("configure_rhythm", _notation_notes(), beat_times, round_duration, false, true, event_modes, current_time_signature, current_durations_beats, current_tempo_bpm)
	staff.call("update_progress", 0.0, judgements)
	card_body.add_child(staff)

	var nav_row := _create_measure_navigator(staff)
	if nav_row:
		card_body.add_child(nav_row)
	_add_event_legend(card_body, mobile)

	status_label = Label.new()
	status_label.name = "GameStatusLabel"
	status_label.text = "Đang nghe"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	status_label.custom_minimum_size = Vector2(156, 40)
	status_label.add_theme_font_size_override("font_size", 15 if mobile else 17)
	status_label.add_theme_color_override("font_color", C_OK)
	status_label.add_theme_font_override("font", _font_bold())
	var feedback_chip := _chip(status_label, Color("#f0f9f3"), Color(C_OK.r, C_OK.g, C_OK.b, 0.30))
	if _is_compact_height():
		compact_footer = _create_compact_footer()
		compact_footer.add_child(feedback_chip)
	else:
		card_body.add_child(feedback_chip)


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
		_show_feedback("Đúng (+100)", C_OK)
	elif value == "GOOD":
		var points := 88 if performance_mode else 70
		round_accuracy_points += points
		_show_feedback("Đúng (+%d)" % points, C_OK)
	elif value == "WRONG_NOTE":
		_show_feedback("Chưa đúng", C_BAD)
	else:
		_show_feedback("Chưa đúng", C_BAD)
	if is_instance_valid(staff):
		staff.call("update_progress", float(Time.get_ticks_msec() - round_started_at_ms) / 1000.0, judgements)


func _show_feedback(text_value: String, color: Color) -> void:
	if not is_instance_valid(status_label):
		return
	status_label.text = text_value
	status_label.add_theme_color_override("font_color", color)
	_pulse_control(status_label, 1.05)
	if not is_inside_tree() or get_tree() == null:
		return
	var gen := session_generation
	get_tree().create_timer(1.0).timeout.connect(func() -> void:
		if gen == session_generation and is_instance_valid(status_label) and playing:
			status_label.text = "● Đang nghe"
			status_label.add_theme_color_override("font_color", C_OK)
	)


func _update_microphone_indicator() -> void:
	if not is_instance_valid(status_label) or not is_instance_valid(audio_analyzer):
		return
	if not audio_analyzer.has_microphone_permission():
		status_label.text = "! Cần cấp quyền micro"
		status_label.add_theme_color_override("font_color", C_BAD)
		return
	var diagnostics := audio_analyzer.get_microphone_diagnostics()
	var capture_status := str(diagnostics.get("status", "starting"))
	if capture_status in ["no_frames", "silent_stream"]:
		status_label.text = "! Không có tín hiệu micro"
		status_label.add_theme_color_override("font_color", C_BAD)


func _update_live_metrics() -> void:
	var target_count := _target_event_count()
	var accuracy := RhythmModel.accuracy_percent(round_accuracy_points, target_count)
	if is_instance_valid(hit_label):
		hit_label.text = "Đúng  %d/%d" % [round_hits, target_count]
	if is_instance_valid(accuracy_label):
		accuracy_label.text = "Chính xác  %.0f%%" % accuracy


func _target_event_count() -> int:
	var count := 0
	for mode in event_modes:
		if mode != "SAMPLE":
			count += 1
	return maxi(1, count)


func _finish_round() -> void:
	if not playing:
		return
	playing = false
	if is_instance_valid(audio_analyzer):
		audio_analyzer.set_analysis_suspended(true)
	_set_flow_state(FlowState.SUBMITTING)

	var current := rhythms[rhythm_index]
	var target_count := _target_event_count()
	var round_accuracy := RhythmModel.accuracy_percent(round_accuracy_points, target_count)
	challenge_accuracy_points += round_accuracy_points
	challenge_beat_count += target_count
	total_accuracy_points += round_accuracy_points
	total_beat_count += target_count
	total_correct_pitch_count += round_correct_pitch_count
	total_on_time_count += round_on_time_count

	var max_score := _safe_int(current.get("max_score", 100), 100)
	var round_score := RhythmModel.scaled_score(round_accuracy_points, target_count, max_score)

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
	_set_hud_mode(false)
	_clear_content()

	var mobile := _is_mobile()
	var card_body := _add_centered_card(C_GOLD, 1760.0)
	if rhythm_index < rhythms.size():
		_add_round_plaque(card_body, str(rhythms[rhythm_index].get("title", "Đọc khuông nhạc")))

	var is_valid := round_score > 0 and round_hits > 0
	# Retain musical staff with colored judgements
	var result_staff: Control = Control.new()
	result_staff.name = "RoundResultStaff"
	result_staff.set_script(RhythmStaffDisplayScript)
	result_staff.custom_minimum_size = Vector2(0, 210 if mobile else 315)
	result_staff.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_staff.call("configure_rhythm", _notation_notes(), beat_times, round_duration, false, true, event_modes, current_time_signature, current_durations_beats, current_tempo_bpm)
	result_staff.call("update_progress", round_duration, judgements)
	card_body.add_child(result_staff)

	var res_nav := _create_measure_navigator(result_staff)
	if res_nav:
		card_body.add_child(res_nav)

	var pitch_acc := RhythmModel.pitch_accuracy_percent(round_correct_pitch_count, _target_event_count())
	var time_acc := RhythmModel.timing_accuracy_percent(round_on_time_count, _target_event_count())
	var summary := _label("%s  ·  Điểm %d/%d  ·  Cao độ %.0f%%  ·  Nhịp %.0f%%" % ["Hoàn thành vòng" if is_valid else "Chưa đạt", round_score, round_max_score, pitch_acc, time_acc], 14 if mobile else 17, C_GREEN_DARK)
	summary.name = "RoundResultSummary"
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_body.add_child(summary)

	if is_valid:
		var next_button := _button("Vòng tiếp theo", 0, 56, C_GREEN)
		next_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		next_button.pressed.connect(func() -> void:
			rhythm_index += 1
			_build_intro()
		)
		card_body.add_child(next_button)
	else:
		var retry_button := _button("Thử lại", 0, 56, C_GREEN)
		retry_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		retry_button.pressed.connect(func() -> void:
			_build_intro()
		)
		card_body.add_child(retry_button)

		var skip_button := _secondary_button("Bỏ qua vòng này  →", 0, 48, C_GREEN_DARK)
		skip_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		skip_button.pressed.connect(func() -> void:
			rhythm_index += 1
			_build_intro()
		)
		card_body.add_child(skip_button)


func _build_submitting(message: String) -> void:
	_set_flow_state(FlowState.SUBMITTING)
	_build_loading(message)


func _build_final_result() -> void:
	_set_flow_state(FlowState.FINAL_RESULT)
	_set_hud_mode(false)
	_clear_content()

	content_box.alignment = BoxContainer.ALIGNMENT_CENTER
	content_box.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var mobile := _is_mobile()
	var card_body := _add_centered_card(C_GOLD, 1760.0)
	if rhythm_index < rhythms.size():
		_add_round_plaque(card_body, str(rhythms[rhythm_index].get("title", "Đọc khuông nhạc")))
	var has_valid_score := total_score > 0 and (total_correct_pitch_count + total_on_time_count) > 0
	var pitch_acc := RhythmModel.pitch_accuracy_percent(total_correct_pitch_count, total_beat_count)
	var time_acc := RhythmModel.timing_accuracy_percent(total_on_time_count, total_beat_count)

	# Retain musical staff with results
	if not performance_notes.is_empty():
		var final_staff: Control = Control.new()
		final_staff.name = "FinalResultStaff"
		final_staff.set_script(RhythmStaffDisplayScript)
		final_staff.custom_minimum_size = Vector2(0, 210 if mobile else 315)
		final_staff.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		final_staff.call("configure_rhythm", _notation_notes(), beat_times, round_duration, false, true, event_modes, current_time_signature, current_durations_beats, current_tempo_bpm)
		final_staff.call("update_progress", round_duration, judgements)
		card_body.add_child(final_staff)

		var fin_nav := _create_measure_navigator(final_staff)
		if fin_nav:
			card_body.add_child(fin_nav)

	var summary := _label("%s  ·  Điểm %d/%d  ·  Cao độ %.0f%%  ·  Nhịp %.0f%%" % ["Hoàn thành" if has_valid_score else "Chưa đạt", total_score, total_max_score, pitch_acc, time_acc], 14 if mobile else 17, C_GREEN_DARK)
	summary.name = "FinalResultSummary"
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.add_theme_font_override("font", _font_bold())
	card_body.add_child(summary)

	var sync_text := "Lượt này chưa lưu vào lịch sử"
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
	elif not online_session and has_valid_score:
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
		sync_text = "Kết quả lưu trên thiết bị"

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

	var retry := _button("Thử lại" if not has_valid_score else "Chơi lại", 0, 56, C_GREEN)
	retry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	retry.pressed.connect(_restart)
	actions.add_child(retry)



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
	_set_hud_mode(false)
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
	_set_hud_mode(false)
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
	performance_notes.clear()
	for value: Variant in current.get("notes", []):
		performance_notes.append(str(value))

	current_time_signature = current.get("time_signature", [4, 4])
	current_durations_beats.clear()
	for value: Variant in current.get("durations_beats", []):
		current_durations_beats.append(float(value))

	var base_bpm := _safe_int(current.get("tempo_bpm", 80), 80)
	if base_bpm <= 0:
		base_bpm = 80
	current_tempo_bpm = int(round(float(base_bpm) * selected_speed_multiplier))

	beat_times.clear()
	if not current_durations_beats.is_empty():
		var accum_b := 0.0
		for d in current_durations_beats:
			beat_times.append(accum_b * 60.0 / float(current_tempo_bpm))
			accum_b += float(d)
	else:
		var raw_beats: Array = current.get("beats", [])
		for value: Variant in raw_beats:
			beat_times.append(float(value) / selected_speed_multiplier)

	event_modes.clear()
	if performance_notes.is_empty() or performance_notes.size() != beat_times.size():
		performance_notes = RhythmModel.default_notes_for_instrument(Context.instrument, beat_times.size())
		for _beat in beat_times:
			event_modes.append("TARGET")
	else:
		for value: Variant in current.get("event_modes", []):
			event_modes.append(str(value).to_upper())
		if event_modes.size() != beat_times.size():
			event_modes.clear()
			for _beat in beat_times:
				event_modes.append("TARGET")
	performance_mode = true
	judgements.clear()
	for _beat in beat_times:
		judgements.append("")

	var last_beat_sec := beat_times[-1] if not beat_times.is_empty() else 2.0
	var last_dur_sec := (current_durations_beats[-1] * 60.0 / float(current_tempo_bpm)) if not current_durations_beats.is_empty() else (0.8 / selected_speed_multiplier)
	round_duration = last_beat_sec + last_dur_sec + 0.4
	last_detected_at_ms = -1000


func _clear_content(stop_preview: bool = true) -> void:
	if stop_preview:
		preview_generation += 1
	if is_instance_valid(click_player):
		click_player.stop()
	for child in content_box.get_children():
		child.queue_free()
	if is_instance_valid(compact_footer):
		compact_footer.queue_free()
	compact_footer = null
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


func _create_compact_footer() -> PanelContainer:
	var footer := PanelContainer.new()
	footer.name = "RhythmCompactFooter"
	footer.custom_minimum_size.y = 64.0
	footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fffdf8")
	style.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.65)
	style.border_width_top = 2
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	footer.add_theme_stylebox_override("panel", style)
	root_box.add_child(footer)
	return footer


func _add_round_plaque(parent: VBoxContainer, round_title: String) -> void:
	var plaque := PanelContainer.new()
	plaque.name = "RhythmTitlePlaque"
	var viewport_width := get_viewport_rect().size.x if is_inside_tree() else 800.0
	var compact := _is_compact_height()
	plaque.custom_minimum_size.x = minf(600.0, maxf(280.0, viewport_width - (64.0 if compact else 96.0)))
	plaque.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var plaque_style := StyleBoxFlat.new()
	plaque_style.bg_color = Color("#38291e")
	plaque_style.border_color = Color("#d8ad56")
	plaque_style.set_border_width_all(2)
	plaque_style.set_corner_radius_all(20)
	plaque_style.content_margin_left = 22
	plaque_style.content_margin_right = 22
	plaque_style.content_margin_top = 3 if compact else 8
	plaque_style.content_margin_bottom = 3 if compact else 9
	plaque.add_theme_stylebox_override("panel", plaque_style)
	parent.add_child(plaque)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 1)
	plaque.add_child(stack)
	var total_rounds := maxi(1, rhythms.size())
	var current_round := clampi(rhythm_index + 1, 1, total_rounds)
	if not compact:
		var progress := _label("VÒNG %d/%d" % [current_round, total_rounds], 11 if _is_mobile() else 12, Color("#f3e6c7"))
		progress.name = "RoundProgressLabel"
		progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stack.add_child(progress)
	var heading := _label(round_title, 16 if compact else (19 if _is_mobile() else 26), Color("#f8d47a"))
	heading.name = "RhythmRoundTitle"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_theme_font_override("font", _font_bold())
	stack.add_child(heading)
	var num := int(current_time_signature[0]) if current_time_signature.size() > 0 else 4
	var den := int(current_time_signature[1]) if current_time_signature.size() > 1 else 4
	var metadata := "Vòng %d/%d  ·  %s  ·  %d/%d  ·  %d BPM" % [current_round, total_rounds, _instrument_title(), num, den, current_tempo_bpm] if compact else "%s  ·  %d/%d  ·  %d BPM" % [_instrument_title(), num, den, current_tempo_bpm]
	var meta := _label(metadata, 10 if compact else (11 if _is_mobile() else 13), Color("#f3e6c7"))
	meta.name = "MetaLabel"
	meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meta.autowrap_mode = TextServer.AUTOWRAP_OFF
	stack.add_child(meta)


func _add_event_legend(parent: VBoxContainer, mobile: bool) -> void:
	if not event_modes.has("SAMPLE") or not event_modes.has("TARGET"):
		return
	var legend := HBoxContainer.new()
	legend.name = "RhythmEventLegend"
	legend.alignment = BoxContainer.ALIGNMENT_CENTER
	legend.add_theme_constant_override("separation", 18)
	legend.add_child(_label("● Nốt mẫu", 12 if mobile else 14, RhythmStaffDisplayScript.C_DEMO_NOTE))
	legend.add_child(_label("● Nốt bạn chơi", 12 if mobile else 14, RhythmStaffDisplayScript.C_TARGET_NOTE))
	parent.add_child(legend)


func _add_centered_card(accent: Color, max_width: float) -> VBoxContainer:
	# Phones in landscape can have only ~300 px below the header. Keep the
	# complete round summary reachable instead of letting the card extend beyond
	# the viewport.
	var card_host: Control
	if _is_mobile() or _is_compact_height():
		var scroll := ScrollContainer.new()
		scroll.name = "RhythmCardScroll"
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		content_box.add_child(scroll)
		card_host = scroll
	else:
		card_host = content_box

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not (_is_mobile() or _is_compact_height()):
		center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	else:
		var vp_w := get_viewport_rect().size.x if is_inside_tree() and get_viewport() != null else 800.0
		center.custom_minimum_size.x = maxf(280.0, vp_w - (32.0 if _is_mobile() else 84.0))
	card_host.add_child(center)
	var card := PanelContainer.new()
	var vp_w := get_viewport_rect().size.x if is_inside_tree() and get_viewport() != null else 800.0
	# The base activity scroll already has 16 px margins on mobile. Keep the
	# inner card within that width so the root never grows beyond the viewport.
	var margin_side := 16.0 if _is_mobile() else 24.0
	var available := maxf(280.0, vp_w - margin_side * 2.0)
	card.custom_minimum_size = Vector2(minf(max_width, available), 0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# CenterContainer otherwise gives the panel the full available height on
	# widescreen devices, leaving a large blank area below the notation.
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	card.add_theme_stylebox_override("panel", _game_card_style(accent))
	center.add_child(card)
	var body := VBoxContainer.new()
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 10 if _is_mobile() else 14)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(body)
	return body


func _create_speed_selector(locked: bool = false) -> Control:
	var container := HBoxContainer.new()
	container.name = "SpeedSelector"
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 10 if _is_mobile() else 12)

	var speeds: Array[float] = [0.6, 0.8, 1.0, 1.2]
	for sp in speeds:
		var btn := Button.new()
		var sp_text := "%s×" % (str(sp).trim_suffix(".0") if sp != 1.0 else "1")
		btn.text = sp_text
		btn.name = "SpeedBtn_%s" % str(sp).replace(".", "_")
		btn.custom_minimum_size = Vector2(64 if _is_mobile() else 70, 44 if _is_mobile() else 42)
		btn.add_theme_font_size_override("font_size", 14 if _is_mobile() else 15)
		btn.add_theme_font_override("font", _font_bold())

		var is_selected := absf(selected_speed_multiplier - sp) < 0.05
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(16)
		sb.content_margin_left = 12
		sb.content_margin_right = 12
		sb.content_margin_top = 6
		sb.content_margin_bottom = 6

		if is_selected:
			sb.bg_color = C_GREEN
			sb.border_color = C_GREEN_DARK
			sb.set_border_width_all(1)
			btn.add_theme_color_override("font_color", Color.WHITE)
		else:
			sb.bg_color = Color(1, 1, 1, 0.92)
			sb.border_color = Color(C_GREEN.r, C_GREEN.g, C_GREEN.b, 0.35)
			sb.set_border_width_all(1)
			btn.add_theme_color_override("font_color", C_TEXT if not locked else C_MUTED)

		var hover := sb.duplicate()
		if not is_selected and not locked:
			hover.bg_color = Color(C_GREEN.r, C_GREEN.g, C_GREEN.b, 0.10)
			hover.border_color = C_GREEN
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", hover)
		btn.add_theme_stylebox_override("disabled", sb)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

		if locked:
			btn.disabled = true
		else:
			var target_sp := sp
			btn.pressed.connect(func() -> void:
				if selected_speed_multiplier != target_sp:
					selected_speed_multiplier = target_sp
					_prepare_current_round()
					_build_intro()
			)
		container.add_child(btn)
	return container


func _create_measure_navigator(staff_ref: Control) -> Control:
	if not is_instance_valid(staff_ref):
		return null
	var total_m: int = staff_ref.get("total_measures")
	if total_m <= 2:
		return null

	var mobile := _is_mobile()
	var nav_row := HBoxContainer.new()
	nav_row.name = "MeasureNavigator"
	nav_row.alignment = BoxContainer.ALIGNMENT_CENTER
	nav_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	nav_row.add_theme_constant_override("separation", 8 if mobile else 12)

	var btn_size := Vector2(44, 44) if mobile else Vector2(36, 36)

	var prev_btn := Button.new()
	prev_btn.name = "PrevButton"
	prev_btn.text = "‹"
	prev_btn.custom_minimum_size = btn_size
	prev_btn.add_theme_font_size_override("font_size", 22 if mobile else 18)
	var sb_n := StyleBoxFlat.new()
	sb_n.bg_color = Color(1, 1, 1, 0.95)
	sb_n.border_color = Color(C_GREEN.r, C_GREEN.g, C_GREEN.b, 0.40)
	sb_n.set_border_width_all(1)
	sb_n.set_corner_radius_all(12 if mobile else 8)
	var sb_p := sb_n.duplicate()
	sb_p.bg_color = Color("#e8f5ed")
	prev_btn.add_theme_stylebox_override("normal", sb_n)
	prev_btn.add_theme_stylebox_override("hover", sb_n)
	prev_btn.add_theme_stylebox_override("pressed", sb_p)
	prev_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	prev_btn.add_theme_color_override("font_color", C_GREEN_DARK)

	var next_btn := Button.new()
	next_btn.name = "NextButton"
	next_btn.text = "›"
	next_btn.custom_minimum_size = btn_size
	next_btn.add_theme_font_size_override("font_size", 22 if mobile else 18)
	next_btn.add_theme_stylebox_override("normal", sb_n)
	next_btn.add_theme_stylebox_override("hover", sb_n)
	next_btn.add_theme_stylebox_override("pressed", sb_p)
	next_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	next_btn.add_theme_color_override("font_color", C_GREEN_DARK)

	var cur_m: int = staff_ref.get("current_measure")
	var end_m := mini(cur_m + 2, total_m)
	var page_lbl := Label.new()
	page_lbl.name = "MeasureLabel"
	page_lbl.text = "%d-%d/%d" % [cur_m + 1, end_m, total_m] if mobile else "Ô nhịp %d-%d / %d" % [cur_m + 1, end_m, total_m]
	page_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	page_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	page_lbl.custom_minimum_size = Vector2(64 if mobile else 100, btn_size.y)
	page_lbl.add_theme_font_size_override("font_size", 14 if mobile else 13)
	page_lbl.add_theme_color_override("font_color", C_NAVY)
	var bold_font := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if bold_font:
		page_lbl.add_theme_font_override("font", bold_font)

	prev_btn.pressed.connect(func() -> void:
		if is_instance_valid(staff_ref):
			staff_ref.call("prev_page")
	)
	next_btn.pressed.connect(func() -> void:
		if is_instance_valid(staff_ref):
			staff_ref.call("next_page")
	)
	staff_ref.connect("measure_changed", func(cur: int, tot: int) -> void:
		if is_instance_valid(page_lbl):
			var em := mini(cur + 2, tot)
			page_lbl.text = "%d-%d/%d" % [cur + 1, em, tot] if _is_mobile() else "Ô nhịp %d-%d / %d" % [cur + 1, em, tot]
	)

	nav_row.add_child(prev_btn)
	nav_row.add_child(page_lbl)
	nav_row.add_child(next_btn)
	return nav_row


func _game_card_style(accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fffdf8")
	style.border_color = Color(accent.r, accent.g, accent.b, 0.58)
	style.set_border_width_all(2)
	style.set_corner_radius_all(20 if _is_mobile() else 24)
	style.shadow_color = Color(accent.r, accent.g, accent.b, 0.18)
	style.shadow_size = 16
	style.shadow_offset = Vector2(0, 6)
	var horizontal_margin := 14.0 if _is_mobile() else 24.0
	var vertical_margin := 8.0 if _is_compact_height() else (14.0 if _is_mobile() else 18.0)
	style.content_margin_left = horizontal_margin
	style.content_margin_right = horizontal_margin
	style.content_margin_top = vertical_margin
	style.content_margin_bottom = vertical_margin
	return style


func _font_regular() -> Font:
	return load("res://assets/fonts/BeVietnamPro-Regular.ttf") as Font


func _font_bold() -> Font:
	return load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font


# Use the same Vietnamese typeface throughout the dynamically created UI.  The
# base activity shell provides colors and layout primitives; this override
# prevents the game-specific labels from falling back to Godot's default font.
func _label(text_value: String, font_size: int, color: Color = C_TEXT) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_override("font", _font_regular())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _button(text_value: String, width: float, height: float, color: Color) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(width, maxf(height, 48.0))
	button.add_theme_font_override("font", _font_bold())
	button.add_theme_font_size_override("font_size", 16 if _is_mobile() else 17)
	button.add_theme_stylebox_override("normal", _panel(color, color.lightened(0.18), 14, 1))
	button.add_theme_stylebox_override("hover", _panel(color.lightened(0.10), C_GOLD, 14, 2))
	button.add_theme_stylebox_override("pressed", _panel(color.darkened(0.10), C_GOLD, 14, 1))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	return button


func _secondary_button(text_value: String, width: float, height: float, color: Color) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(width, maxf(height, 48.0))
	button.add_theme_font_override("font", _font_bold())
	button.add_theme_font_size_override("font_size", 15 if _is_mobile() else 16)
	button.add_theme_stylebox_override("normal", _panel(Color.WHITE, Color(color.r, color.g, color.b, 0.55), 14, 1))
	button.add_theme_stylebox_override("hover", _panel(Color(color.r, color.g, color.b, 0.08), color, 14, 1))
	button.add_theme_stylebox_override("pressed", _panel(Color(color.r, color.g, color.b, 0.14), color, 14, 1))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_hover_color", color.darkened(0.15))
	return button


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
	_set_hud_mode(flow_state == FlowState.PLAYING)
	if flow_state == FlowState.INTRO:
		_build_intro()
	elif flow_state == FlowState.ROUND_RESULT:
		var current := rhythms[rhythm_index]
		var max_score := _safe_int(current.get("max_score", 100), 100)
		var round_score := RhythmModel.scaled_score(round_accuracy_points, _target_event_count(), max_score)
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
	if not is_inside_tree() or get_viewport() == null:
		return false
	# A landscape phone can report a wide canvas after stretch.  Runtime mobile
	# capability is therefore the primary signal; metadata keeps UI tests
	# deterministic without changing production behavior.
	return OS.has_feature("mobile") \
		or bool(get_tree().root.get_meta("force_compact_layout", false)) \
		or get_viewport_rect().size.x < 720.0


func _is_compact_height() -> bool:
	if not is_inside_tree() or get_viewport() == null:
		return false
	return get_viewport_rect().size.y < 520.0


func _safe_int(value: Variant, fallback: int = 0) -> int:
	if value == null:
		return fallback
	var text := str(value).strip_edges()
	return int(text) if text.is_valid_int() else fallback
