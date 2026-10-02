extends "res://scripts/LearningActivityBase.gd"

const InstrumentSamplePlayerScript = preload("res://scripts/InstrumentSamplePlayer.gd")
const DanTranhAudio = preload("res://scripts/DanTranhAudio.gd")
const PracticeControlHudScript = preload("res://scripts/PracticeControlHud.gd")

var challenge: Dictionary = {}
var challenge_id := 0
var lesson_id := 0
var melodies: Array = []
var melody_index := 0
var score := 0
var api_stars_earned := 0
var correct_rounds := 0
var started_at := ""
var challenge_scores: Dictionary = {}
var challenge_started_at: Dictionary = {}
var melody_staff: Control
var feedback_label: Label
var next_button: Button
var listen_button: Button
var reference_audio_url := ""
var audio_player: AudioStreamPlayer
var practice_hud: PracticeControlHud
var custom_top_bar: PanelContainer
var selected_speed_multiplier := 1.0
var microphone_paused := false
var answered := false
var _audio_generation := 0
var microphone_analyzer: AudioCaptureAnalyzer
var microphone_status_label: Label
var microphone_note_label: Label
var listen_for_note_button: Button
var microphone_armed := false
var microphone_candidate_elapsed := 0.0
var microphone_candidate_pitch := 0.0
var expected_note_raw := ""
var sample_player: Node
var sample_button: Button
var sample_playback_active := false
const MICROPHONE_HOLD_SECONDS := 0.18
const MICROPHONE_CENTS_TOLERANCE := 75.0

func _ready() -> void:
	super._ready()
	
	# Hide the inherited top panel navbar to use the unified sticky header
	var top_panel = root_box.get_child(0)
	if top_panel:
		top_panel.visible = false
		
	_setup_custom_header_and_backdrop()
	_setup_practice_hud()
	title_label.text = "Hoàn thiện giai điệu"
	_setup_microphone_analyzer()
	_setup_sample_player()
	get_viewport().size_changed.connect(_update_hud_layout)
	_update_hud_layout()
	_load_challenge()

func _setup_custom_header_and_backdrop() -> void:
	var room_background := get_child(0) as TextureRect
	if room_background:
		room_background.texture = load("res://assets/textures/bg_practice_room.png") as Texture2D
	var room_wash := get_child(1) as ColorRect
	if room_wash:
		room_wash.color = Color(0.95, 0.93, 0.89, 0.95)
	custom_top_bar = PanelContainer.new()
	custom_top_bar.name = "MelodyCustomTopBar"
	custom_top_bar.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	root_box.add_child(custom_top_bar)
	root_box.move_child(custom_top_bar, 0)

func _setup_practice_hud() -> void:
	practice_hud = PracticeControlHudScript.new() as PracticeControlHud
	practice_hud.name = "MelodyPracticeHud"
	add_child(practice_hud)
	practice_hud.back_requested.connect(_go_back)
	practice_hud.speed_selected.connect(_on_hud_speed_selected)
	practice_hud.pause_requested.connect(_pause_microphone)
	practice_hud.resume_requested.connect(_resume_microphone)
	practice_hud.restart_requested.connect(_restart_from_pause)
	practice_hud.sample_requested.connect(_play_sample_from_pause)
	practice_hud.set_speed_centered(false)
	practice_hud.set_speed(selected_speed_multiplier)
	practice_hud.set_pause_button_visible(false)

func _update_hud_layout() -> void:
	if not is_instance_valid(practice_hud) or not is_instance_valid(custom_top_bar):
		return
	var second_row := practice_hud.needs_second_row(get_viewport_rect().size.x)
	custom_top_bar.custom_minimum_size.y = 160.0 if second_row else 86.0
	practice_hud.set_pause_button_visible(microphone_armed and not microphone_paused)

func _on_hud_speed_selected(multiplier: float) -> void:
	selected_speed_multiplier = multiplier
	practice_hud.set_speed(multiplier)

func _pause_microphone() -> void:
	if not microphone_armed or not is_instance_valid(microphone_analyzer):
		return
	microphone_paused = true
	microphone_armed = false
	microphone_analyzer.set_analysis_suspended(true)
	practice_hud.set_pause_visible(true)
	_update_hud_layout()

func _resume_microphone() -> void:
	if not microphone_paused:
		return
	microphone_paused = false
	practice_hud.set_pause_visible(false)
	_arm_microphone_for_note()

func _restart_from_pause() -> void:
	microphone_paused = false
	practice_hud.set_pause_visible(false)
	_show_round()

func _play_sample_from_pause() -> void:
	microphone_paused = false
	practice_hud.set_pause_visible(false)
	_play_recorded_samples()

func _exit_tree() -> void:
	if microphone_analyzer and is_instance_valid(microphone_analyzer):
		microphone_analyzer.set_analysis_suspended(true)
	if sample_player and is_instance_valid(sample_player):
		sample_player.stop()

func _process(delta: float) -> void:
	if not microphone_armed or answered or microphone_analyzer == null or not is_instance_valid(microphone_analyzer):
		return
	var pitch := microphone_analyzer.current_pitch
	var amplitude := microphone_analyzer.current_amplitude_db
	if not microphone_analyzer.current_pitch_is_reliable or pitch <= 0.0 or amplitude <= microphone_analyzer.volume_threshold_db:
		microphone_candidate_elapsed = 0.0
		return
	# AudioCaptureAnalyzer obtains this pitch through the native C++ AudioAnalyzer
	# when the GDExtension is installed. Match it against the active instrument
	# profile before scoring, just as the practice screens do.
	var recognized: Dictionary = microphone_analyzer.pitch_profile.match_pitch(pitch)
	if not bool(recognized.get("is_match", false)):
		microphone_candidate_elapsed = 0.0
		if microphone_note_label and is_instance_valid(microphone_note_label):
			microphone_note_label.text = "Âm thanh chưa thuộc dải nốt của nhạc cụ đang học"
			microphone_note_label.add_theme_color_override("font_color", C_BAD)
		return
	var cents := _cents_from_expected(pitch, expected_note_raw)
	_update_microphone_labels(pitch, cents)
	if absf(cents) > MICROPHONE_CENTS_TOLERANCE:
		microphone_candidate_elapsed = 0.0
		return
	if microphone_candidate_pitch > 0.0 and absf(1200.0 * log(pitch / microphone_candidate_pitch) / log(2.0)) > 30.0:
		microphone_candidate_elapsed = 0.0
	microphone_candidate_pitch = pitch
	microphone_candidate_elapsed += delta
	if microphone_candidate_elapsed >= MICROPHONE_HOLD_SECONDS:
		microphone_armed = false
		_update_hud_layout()
		if listen_for_note_button and is_instance_valid(listen_for_note_button):
			listen_for_note_button.disabled = true
		_answer_from_microphone(pitch)

func _setup_microphone_analyzer() -> void:
	var analyzer_script := load("res://scripts/AudioCaptureAnalyzer.gd")
	if analyzer_script == null:
		return
	var analyzer_instance: AudioCaptureAnalyzer = analyzer_script.new() as AudioCaptureAnalyzer
	if analyzer_instance == null:
		return
	microphone_analyzer = analyzer_instance
	microphone_analyzer.name = "MelodyMicrophoneAnalyzer"
	microphone_analyzer.visible = false
	microphone_analyzer.set_analysis_suspended(true)
	var profile := DanTranhAudio.make_real_string_pitch_profile(MICROPHONE_CENTS_TOLERANCE) \
		if Context.instrument == "dan_tranh" else InstrumentPitchProfile.new()
	if Context.instrument != "dan_tranh":
		profile.notes.assign(["C3", "D3", "E3", "F3", "G3", "A3", "B3", "C4", "D4", "E4", "F4", "G4", "A4", "B4", "C5", "D5", "E5", "F5", "G5", "A5", "B5", "C6"])
		profile.frequencies = PackedFloat32Array([130.81, 146.83, 164.81, 174.61, 196.00, 220.00, 246.94, 261.63, 293.66, 329.63, 349.23, 392.00, 440.00, 493.88, 523.25, 587.33, 659.25, 698.46, 783.99, 880.00, 987.77, 1046.50])
		profile.min_frequency = 120.0
		profile.max_frequency = 2100.0
		profile.volume_threshold_db = -45.0
		profile.cents_tolerance = MICROPHONE_CENTS_TOLERANCE
		profile.hold_time_sec = MICROPHONE_HOLD_SECONDS
		profile.is_plucked_instrument = false
	microphone_analyzer.pitch_profile = profile
	microphone_analyzer.min_frequency = profile.min_frequency
	microphone_analyzer.max_frequency = profile.max_frequency
	microphone_analyzer.volume_threshold_db = profile.volume_threshold_db
	add_child(microphone_analyzer)

func _setup_sample_player() -> void:
	sample_player = InstrumentSamplePlayerScript.new()
	sample_player.name = "MelodyRecordedSamplePlayer"
	add_child(sample_player)
	sample_player.note_started.connect(_on_sample_note_started)
	sample_player.playback_finished.connect(_on_sample_playback_finished)
	sample_player.playback_failed.connect(_on_sample_playback_failed)

func _load_challenge() -> void:
	if Context.instrument == "trong_chau":
		_build_load_error(
			"Mini-game giai điệu không áp dụng cho Trống Chầu.",
			"Trống Chầu được đánh giá bằng nhịp điệu; hãy dùng Mini-game 1 để luyện với nhạc cụ thật.",
			false
		)
		return
	var report := _report()
	
	if report != null and report.is_signed_in():
		result_sync_status = "be"
		if SecureDataManager.be_catalog.is_empty():
			await report.fetch_and_install_catalog()
		var target_challenges: Array = await report.fetch_minigames_for_level(Context.instrument, Context.local_lesson_ids, "MELODY_COMPLETE", true)
		if not is_inside_tree():
			return
		
		_parse_challenges(target_challenges)
		if melodies.is_empty():
			_build_load_error(
				"Bài học này chưa có giai điệu để chơi.",
				"Bạn có thể thử lại sau hoặc chơi thử với giai điệu mẫu."
			)
			return
		_show_round()
	else:
		_use_offline_data()

func _use_offline_data() -> void:
	if Context.instrument == "trong_chau":
		return
	result_sync_status = "offline"
	var sample := _sample_data()
	var source: Variant = sample.get("melody", {})
	if not source is Dictionary:
		_build_load_error("Chưa thể bắt đầu trò chơi.", "Hãy thử lại khi có kết nối.", false)
		return
	var sample_challenge: Dictionary = (source as Dictionary).duplicate(true)
	sample_challenge["id"] = 0
	sample_challenge["title"] = "Mẫu giai điệu %s" % _instrument_title().to_lower()
	sample_challenge["contentJson"] = str(sample_challenge.get("contentJson", sample_challenge.get("content_json", "")))
	_parse_challenges([sample_challenge])
	if melodies.is_empty():
		_build_load_error("Dữ liệu mẫu giai điệu không hợp lệ.", "Hãy thử lại khi có kết nối.", false)
		return
	_show_round()

func _build_load_error(title: String, description: String, allow_retry: bool = true) -> void:
	for child in content_box.get_children():
		child.queue_free()
	content_box.alignment = BoxContainer.ALIGNMENT_CENTER
	content_box.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var card_panel := PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(minf(840.0, get_viewport_rect().size.x - 32.0), 0)
	card_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color.WHITE
	panel_style.border_color = Color("#f87171")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(24)
	panel_style.shadow_color = Color(0.9, 0.2, 0.2, 0.12)
	panel_style.shadow_size = 18
	panel_style.shadow_offset = Vector2(0, 6)
	panel_style.content_margin_left = 28
	panel_style.content_margin_right = 28
	panel_style.content_margin_top = 28
	panel_style.content_margin_bottom = 28
	card_panel.add_theme_stylebox_override("panel", panel_style)
	content_box.add_child(card_panel)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	card_panel.add_child(body)

	var icon_lbl := Label.new()
	icon_lbl.text = "!"
	if ResourceLoader.exists("res://assets/fonts/Lora-Bold.ttf"):
		icon_lbl.add_theme_font_override("font", load("res://assets/fonts/Lora-Bold.ttf") as Font)
	icon_lbl.add_theme_font_size_override("font_size", 48)
	icon_lbl.add_theme_color_override("font_color", Color("#dc2626"))
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(icon_lbl)

	var heading := Label.new()
	heading.text = title
	if ResourceLoader.exists("res://assets/fonts/Lora-Bold.ttf"):
		heading.add_theme_font_override("font", load("res://assets/fonts/Lora-Bold.ttf") as Font)
	heading.add_theme_font_size_override("font_size", 22)
	heading.add_theme_color_override("font_color", C_NAVY)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(heading)

	var detail := Label.new()
	detail.text = description
	if ResourceLoader.exists("res://assets/fonts/BeVietnamPro-Regular.ttf"):
		detail.add_theme_font_override("font", load("res://assets/fonts/BeVietnamPro-Regular.ttf") as Font)
	detail.add_theme_font_size_override("font_size", 15)
	detail.add_theme_color_override("font_color", C_MUTED)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(detail)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 14)
	body.add_child(actions)

	if allow_retry:
		var retry_btn := _button("Thử tải lại", 160, 48, C_NAVY)
		retry_btn.pressed.connect(func() -> void: _load_challenge())
		actions.add_child(retry_btn)

	var sample_btn := _secondary_button("Chơi thử", 160, 48, C_GREEN)
	sample_btn.pressed.connect(func() -> void: _use_offline_data())
	actions.add_child(sample_btn)

func _parse_challenges(challenges: Array) -> void:
	melodies.clear()
	for challenge_item: Variant in challenges:
		if not challenge_item is Dictionary:
			continue
		var parsed: Variant = _extract_json(_safe_str(challenge_item.get("contentJson", challenge_item.get("content_json", ""))))
		var source: Dictionary = parsed if parsed is Dictionary else {}
		
		# 1. Parse standard single round layout at root
		if source.has("melody") and source.get("melody") is Array and not source.get("melody", []).is_empty():
			var notes: Array = source.get("melody", []).duplicate()
			var missing_positions: Variant = source.get("missing_positions", source.get("missingPositions", [2]))
			var missing := _safe_int(source.get("missing_index", source.get("missingIndex", 2)), 2)
			if not source.has("missing_index") and not source.has("missingIndex") and missing_positions is Array and not missing_positions.is_empty():
				missing = _safe_int(missing_positions[0], 2)
			missing = clampi(missing, 0, notes.size() - 1)
				
			var correct_ans := ""
			var correct_answers = source.get("correct_answers", source.get("correctAnswers", {}))
			if correct_answers is Dictionary:
				var key_str := str(missing)
				if correct_answers.has(key_str):
					correct_ans = str(correct_answers[key_str]).strip_edges()
			if correct_ans.is_empty():
				correct_ans = _safe_str(source.get("correctAnswer", source.get("correct_answer", ""))).strip_edges()
					
			if not correct_ans.is_empty() and missing >= 0 and missing < notes.size():
				notes[missing] = correct_ans
				
			var options: Array = []
			var note_opts = source.get("note_options", source.get("noteOptions", {}))
			if note_opts is Dictionary:
				var key_str := str(missing)
				if note_opts.has(key_str) and note_opts[key_str] is Array:
					options = note_opts[key_str]
					
			if options.is_empty() and note_opts is Dictionary:
				for k in note_opts.keys():
					var opt_list = note_opts[k]
					if opt_list is Array:
						for opt in opt_list:
							if not opt in options:
								options.append(opt)
								
			var audio_url := _get_challenge_audio(challenge_item, source)
			
			melodies.append({
				"notes": notes,
				"missing": missing,
				"options": options,
				"challenge_id": _safe_int(challenge_item.get("id", 0)),
				"max_score": _safe_int(challenge_item.get("maxScore", challenge_item.get("max_score", 100)), 100),
				"audio_url": audio_url,
				"bpm": _safe_float(source.get("tempo_bpm", source.get("bpm", InstrumentSamplePlayerScript.DEFAULT_BPM)), InstrumentSamplePlayerScript.DEFAULT_BPM)
			})
		else:
			# 2. Parse rounds array layout
			var raw_melodies: Array = source.get("melodies", source.get("rounds", []))
			for item: Variant in raw_melodies:
				if item is Dictionary:
					var notes_value: Variant = item.get("notes", item.get("sequence", []))
					var notes: Array = notes_value.duplicate() if notes_value is Array else []
					if not notes.is_empty():
						var raw_missing = item.get("missingIndex", item.get("missing_index", item.get("missing_idx")))
						var missing := _safe_int(raw_missing, -1)
						if missing < 0:
							missing = maxi(0, int(notes.size() / 2))
						missing = clampi(missing, 0, notes.size() - 1)
						var correct_ans := _safe_str(item.get("correctAnswer", item.get("correct_answer", ""))).strip_edges()
						if not correct_ans.is_empty():
							notes[missing] = correct_ans
						var options_value: Variant = item.get("options", item.get("noteOptions", item.get("note_options", [])))
						var options: Array = options_value if options_value is Array else []
							
						var audio_url := _get_challenge_audio(challenge_item, item)
						
						melodies.append({
							"notes": notes,
							"missing": missing,
							"options": options,
							"challenge_id": _safe_int(challenge_item.get("id", 0)),
							"max_score": _safe_int(challenge_item.get("maxScore", challenge_item.get("max_score", 100)), 100),
							"audio_url": audio_url,
							"bpm": _safe_float(item.get("tempo_bpm", item.get("bpm", source.get("tempo_bpm", source.get("bpm", InstrumentSamplePlayerScript.DEFAULT_BPM)))), InstrumentSamplePlayerScript.DEFAULT_BPM)
						})
						
	_finalize_challenge_rounds()

func _finalize_challenge_rounds() -> void:
	var round_counts: Dictionary = {}
	var max_scores: Dictionary = {}
	for melody_value: Variant in melodies:
		if not melody_value is Dictionary:
			continue
		var melody: Dictionary = melody_value
		var challenge_id := _safe_int(melody.get("challenge_id", 0))
		if challenge_id <= 0:
			continue
		round_counts[challenge_id] = int(round_counts.get(challenge_id, 0)) + 1
		max_scores[challenge_id] = _safe_int(melody.get("max_score", 100), 100)
	var round_indices: Dictionary = {}
	for index in melodies.size():
		var melody: Dictionary = melodies[index]
		var challenge_id := _safe_int(melody.get("challenge_id", 0))
		if challenge_id <= 0:
			continue
		var count := int(round_counts[challenge_id])
		var round_index := int(round_indices.get(challenge_id, 0))
		var challenge_max := int(max_scores[challenge_id])
		var base_score := challenge_max / count
		var remainder := challenge_max % count
		melody["max_score"] = base_score + (1 if round_index < remainder else 0)
		melody["submit_after"] = round_index == count - 1
		melodies[index] = melody
		round_indices[challenge_id] = round_index + 1
func _get_challenge_audio(challenge_item: Dictionary, source: Dictionary) -> String:
	var raw_url = challenge_item.get("referenceAudioUrl")
	if raw_url == null: raw_url = challenge_item.get("reference_audio_url")
	if raw_url == null: raw_url = challenge_item.get("audioUrl")
	if raw_url == null: raw_url = challenge_item.get("audio_url")
	if raw_url == null: raw_url = source.get("referenceAudioUrl")
	if raw_url == null: raw_url = source.get("reference_audio_url")
	if raw_url == null: raw_url = source.get("audioUrl")
	if raw_url == null: raw_url = source.get("audio_url")
	return _safe_str(raw_url)

var card_body: VBoxContainer
var action_box: VBoxContainer

func _show_round() -> void:
	microphone_paused = false
	if is_instance_valid(practice_hud):
		practice_hud.set_pause_visible(false)
		practice_hud.set_pause_button_visible(false)
	for child in content_box.get_children():
		child.queue_free()
	
	_audio_generation += 1
	if audio_player and is_instance_valid(audio_player):
		audio_player.stop()
		audio_player.queue_free()
		audio_player = null
	answered = false
	microphone_armed = false
	microphone_candidate_elapsed = 0.0
	microphone_candidate_pitch = 0.0
	if microphone_analyzer and is_instance_valid(microphone_analyzer):
		microphone_analyzer.set_analysis_suspended(true)
	if sample_player and is_instance_valid(sample_player):
		sample_player.stop()
	sample_playback_active = false
	next_button = null
	content_box.alignment = BoxContainer.ALIGNMENT_CENTER
	content_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var melody: Dictionary = melodies[melody_index % melodies.size()]
	reference_audio_url = str(melody.get("audio_url", ""))
	var active_challenge_id := _safe_int(melody.get("challenge_id", 0))
	if active_challenge_id > 0 and not challenge_started_at.has(active_challenge_id):
		challenge_started_at[active_challenge_id] = _now_iso()
	
	var mobile := _is_compact_layout()
	var compact_height := get_viewport_rect().size.y < 780.0 or mobile

	# Keep the shared notation visible before the action controls.
	var card := PanelContainer.new()
	card.name = "MelodyRoundCard"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sheet_style := _panel(Color(0.995, 0.99, 0.985, 0.96), Color("#e2d8c9"), 18, 1)
	sheet_style.content_margin_left = 12 if mobile else 24
	sheet_style.content_margin_right = 12 if mobile else 24
	sheet_style.content_margin_top = 8 if compact_height else 16
	sheet_style.content_margin_bottom = 8 if compact_height else 16
	card.add_theme_stylebox_override("panel", sheet_style)
	content_box.add_child(card)

	card_body = VBoxContainer.new()
	card_body.add_theme_constant_override("separation", 8 if compact_height else 14)
	card.add_child(card_body)

	var prompt_row := HBoxContainer.new()
	prompt_row.add_theme_constant_override("separation", 8)
	card_body.add_child(prompt_row)
	var heading := _label("Giai điệu %d/%d · Chơi nốt còn thiếu" % [melody_index + 1, melodies.size()], 16 if mobile else 20, C_NAVY)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_row.add_child(heading)
	listen_button = _secondary_button("Nghe mẫu", 112 if mobile else 130, 48, C_GREEN)
	listen_button.tooltip_text = "Nghe giai điệu mẫu"
	listen_button.pressed.connect(_play_recorded_samples)
	prompt_row.add_child(listen_button)
	sample_button = listen_button

	melody_staff = Control.new()
	melody_staff.name = "MelodyStaff"
	melody_staff.set_script(load("res://scripts/LearningMelodyStaffDisplay.gd"))
	melody_staff.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_body.add_child(melody_staff)
	melody_staff.custom_minimum_size = Vector2(0, 148 if compact_height else 210)
	melody_staff.call("configure", melody["notes"], int(melody["missing"]))
	melody_staff.queue_redraw()
	# 4. The learner completes the blank by playing the physical instrument.
	expected_note_raw = str(melody["notes"][int(melody["missing"])])
	var microphone_panel := PanelContainer.new()
	microphone_panel.add_theme_stylebox_override("panel", _microphone_panel_style())
	card_body.add_child(microphone_panel)
	var microphone_body := VBoxContainer.new()
	microphone_body.add_theme_constant_override("separation", 8)
	microphone_panel.add_child(microphone_body)
	microphone_status_label = _label("Nghe mẫu, rồi chơi nốt khuyết bằng nhạc cụ của bạn.", 14 if mobile else 16, C_MUTED)
	microphone_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	microphone_body.add_child(microphone_status_label)
	microphone_note_label = _label("", 14 if mobile else 16, C_MUTED)
	microphone_note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	microphone_note_label.visible = false
	microphone_body.add_child(microphone_note_label)
	listen_for_note_button = _button("Bắt đầu chơi", 0, 54, C_GREEN)
	listen_for_note_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	listen_for_note_button.pressed.connect(_arm_microphone_for_note)
	microphone_body.add_child(listen_for_note_button)
	if microphone_analyzer and is_instance_valid(microphone_analyzer):
		microphone_analyzer.set_analysis_suspended(true)
	else:
		listen_for_note_button.disabled = true
		microphone_status_label.text = "Thiết bị này chưa khởi tạo được bộ thu âm. Hãy thử mở lại hoạt động."
	
	# 5. Dedicated Action/Feedback Container inside card
	action_box = VBoxContainer.new()
	action_box.add_theme_constant_override("separation", 12)
	action_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_box.alignment = BoxContainer.ALIGNMENT_CENTER
	card_body.add_child(action_box)
	started_at = _now_iso()

func _microphone_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#f0fdf4")
	style.border_color = Color("#86efac")
	style.set_border_width_all(1)
	style.set_corner_radius_all(16)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style

func _play_recorded_samples() -> void:
	if sample_playback_active or sample_player == null or not is_instance_valid(sample_player) or melodies.is_empty():
		return
	var melody: Dictionary = melodies[melody_index % melodies.size()]
	sample_playback_active = true
	microphone_armed = false
	microphone_candidate_elapsed = 0.0
	microphone_candidate_pitch = 0.0
	if microphone_analyzer and is_instance_valid(microphone_analyzer):
		microphone_analyzer.set_analysis_suspended(true)
	if melody_staff and is_instance_valid(melody_staff):
		melody_staff.call("set_playback_index", -1)
	if sample_button and is_instance_valid(sample_button):
		sample_button.disabled = true
	if listen_for_note_button and is_instance_valid(listen_for_note_button):
		listen_for_note_button.disabled = true
	if microphone_status_label and is_instance_valid(microphone_status_label):
		microphone_status_label.text = "Đang phát giai điệu mẫu…"
		microphone_status_label.add_theme_color_override("font_color", C_MUTED)
	var result: Dictionary = sample_player.play_sequence(
		Context.instrument,
		melody.get("notes", []),
		int(melody.get("missing", -1)),
		_safe_float(melody.get("bpm", InstrumentSamplePlayerScript.DEFAULT_BPM), InstrumentSamplePlayerScript.DEFAULT_BPM) * selected_speed_multiplier
	)
	if not bool(result.get("ok", false)):
		sample_playback_active = false
		if sample_button and is_instance_valid(sample_button):
			sample_button.disabled = false
		if listen_for_note_button and is_instance_valid(listen_for_note_button):
			listen_for_note_button.disabled = false

func _on_sample_note_started(index: int) -> void:
	if melody_staff and is_instance_valid(melody_staff):
		melody_staff.call("set_playback_index", index)

func _on_sample_playback_finished() -> void:
	sample_playback_active = false
	microphone_armed = false
	microphone_candidate_elapsed = 0.0
	microphone_candidate_pitch = 0.0
	if microphone_analyzer and is_instance_valid(microphone_analyzer):
		microphone_analyzer.set_analysis_suspended(true)
	if melody_staff and is_instance_valid(melody_staff):
		melody_staff.call("set_playback_index", -1)
	if sample_button and is_instance_valid(sample_button):
		sample_button.disabled = false
	if listen_for_note_button and is_instance_valid(listen_for_note_button) and not answered:
		listen_for_note_button.disabled = false
		listen_for_note_button.text = "Bắt đầu chơi"
	if microphone_status_label and is_instance_valid(microphone_status_label):
		microphone_status_label.text = "Đến lượt bạn chơi nốt khuyết."
		microphone_status_label.add_theme_color_override("font_color", C_MUTED)

func _on_sample_playback_failed(details: Dictionary) -> void:
	sample_playback_active = false
	microphone_armed = false
	microphone_candidate_elapsed = 0.0
	microphone_candidate_pitch = 0.0
	if microphone_analyzer and is_instance_valid(microphone_analyzer):
		microphone_analyzer.set_analysis_suspended(true)
	if melody_staff and is_instance_valid(melody_staff):
		melody_staff.call("set_playback_index", -1)
	if sample_button and is_instance_valid(sample_button):
		sample_button.disabled = false
	if listen_for_note_button and is_instance_valid(listen_for_note_button) and not answered:
		listen_for_note_button.disabled = false
	var names: Array[String] = []
	for item_value: Variant in details.get("missing", []):
		if item_value is Dictionary:
			names.append(str((item_value as Dictionary).get("note", "?")))
	if microphone_status_label and is_instance_valid(microphone_status_label):
		microphone_status_label.text = "Chưa phát được mẫu cho nốt %s. Hãy thử lại." % ", ".join(names)
		microphone_status_label.add_theme_color_override("font_color", C_BAD)

func _arm_microphone_for_note() -> void:
	if sample_playback_active or microphone_analyzer == null or not is_instance_valid(microphone_analyzer) or answered:
		return
	microphone_candidate_elapsed = 0.0
	microphone_candidate_pitch = 0.0
	microphone_armed = true
	microphone_paused = false
	microphone_analyzer.set_analysis_suspended(false)
	microphone_analyzer.start_microphone_capture()
	_update_hud_layout()
	listen_for_note_button.text = "Đang lắng nghe…"
	microphone_status_label.text = "Hãy chơi một nốt rõ, giữ âm ổn định trong chốc lát."
	microphone_note_label.visible = true
	microphone_note_label.text = "Đang nghe nhạc cụ…"

func _cents_from_expected(pitch: float, expected: String) -> float:
	var reference := _frequency(expected)
	if pitch <= 0.0 or reference <= 0.0:
		return 9999.0
	return 1200.0 * log(pitch / reference) / log(2.0)

func _update_microphone_labels(pitch: float, cents: float) -> void:
	if microphone_note_label == null or not is_instance_valid(microphone_note_label):
		return
	var label_note := _to_vietnamese_solfege(_closest_note_name(pitch))
	microphone_note_label.text = "Đang nhận: %s" % label_note
	microphone_note_label.add_theme_color_override("font_color", C_OK if absf(cents) <= MICROPHONE_CENTS_TOLERANCE else C_BAD)

func _closest_note_name(pitch: float) -> String:
	var note_names := ["C3", "D3", "E3", "F3", "G3", "A3", "B3", "C4", "D4", "E4", "F4", "G4", "A4", "B4", "C5", "D5", "E5", "F5", "G5", "A5", "B5", "C6"]
	var closest := "C4"
	var smallest := INF
	for note in note_names:
		var distance := absf(_cents_from_expected(pitch, note))
		if distance < smallest:
			smallest = distance
			closest = note
	return closest

func _answer_from_microphone(pitch: float) -> void:
	microphone_armed = false
	_update_hud_layout()
	if microphone_analyzer and is_instance_valid(microphone_analyzer):
		microphone_analyzer.set_analysis_suspended(true)
	var melody: Dictionary = melodies[melody_index % melodies.size()]
	# Scoring has already checked octave-aware cents above. Feed the shared result
	# pipeline the expected value so it records a correct physical performance.
	_answer(expected_note_raw, expected_note_raw, melody)

func _to_vietnamese_solfege(raw: String) -> String:
	var s := raw.strip_edges()
	if s.begins_with("ZT_"):
		s = s.substr(3)
	
	var lower := s.to_lower()
	if lower.begins_with("c") or lower.begins_with("do") or lower.begins_with("đô") or lower.begins_with("đo") or lower.begins_with("đồ") or lower.begins_with("đố"):
		return "Đô"
	elif lower.begins_with("d") or lower.begins_with("re") or lower.begins_with("rê") or lower.begins_with("rề") or lower.begins_with("rế"):
		return "Rê"
	elif lower.begins_with("e") or lower.begins_with("mi") or lower.begins_with("mì") or lower.begins_with("mí"):
		return "Mi"
	elif lower.begins_with("f") or lower.begins_with("fa") or lower.begins_with("fà") or lower.begins_with("fá"):
		return "Fa"
	elif lower.begins_with("g") or lower.begins_with("sol") or lower.begins_with("so") or lower.begins_with("sò") or lower.begins_with("sól"):
		return "Sol"
	elif lower.begins_with("a") or lower.begins_with("la") or lower.begins_with("là") or lower.begins_with("lá"):
		return "La"
	elif lower.begins_with("b") or lower.begins_with("si") or lower.begins_with("ti") or lower.begins_with("sì") or lower.begins_with("sĩ"):
		return "Si"
		
	return s

func _answer(selected: String, expected: String, melody: Dictionary) -> void:
	if answered or (next_button != null and is_instance_valid(next_button)):
		return
	answered = true
	var correct := _note_equal(selected, expected)
	var current_max := _safe_int(melody.get("max_score", 100), 100)
	
	if correct:
		score += current_max
		correct_rounds += 1
	melody_staff.call("show_answer", correct, selected)
	
	# Aggregate all rounds of a minigame and submit one final attempt per challenge.
	var current_id := _safe_int(melody.get("challenge_id", 0))
	var report := _report()
	if current_id <= 0:
		result_sync_status = "offline"
	else:
		challenge_scores[current_id] = int(challenge_scores.get(current_id, 0)) + (current_max if correct else 0)
		if bool(melody.get("submit_after", true)):
			var challenge_score := int(challenge_scores[current_id])
			var challenge_max := 0
			for melody_value: Variant in melodies:
				if melody_value is Dictionary and _safe_int(melody_value.get("challenge_id", 0)) == current_id:
					challenge_max += _safe_int(melody_value.get("max_score", 0), 0)
			var challenge_stars := _stars(challenge_score, challenge_max)
			if report != null and report.is_signed_in():
				var challenge_start := str(challenge_started_at.get(current_id, started_at))
				var client_attempt_id := _client_attempt_id("melody")
				var play_data := JSON.stringify({"selectedNotes": [selected], "correctNotes": [expected], "isCorrect": correct, "correctRounds": correct_rounds})
				var result: Dictionary = await report.report_minigame_by_id(current_id, challenge_score, challenge_stars, challenge_start, _now_iso(), client_attempt_id, play_data)
				if bool(result.get("submitted", false)):
					result_sync_status = "be"
					api_stars_earned = maxi(api_stars_earned, int(result.get("stars_earned", 0)))
				elif bool(result.get("queued", false)) or str(result.get("reason", "")) == "attempt_failed":
					result_sync_status = "failed"
				else:
					result_sync_status = "offline"
			else:
				result_sync_status = "offline"
		else:
			result_sync_status = "pending"
	
	# Clear previous feedback if any
	for child in action_box.get_children():
		child.queue_free()

	# High contrast feedback banner panel
	var banner := PanelContainer.new()
	banner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var b_style := StyleBoxFlat.new()
	b_style.bg_color = Color("#ecfdf5") if correct else Color("#fef2f2")
	b_style.border_color = Color("#10b981") if correct else Color("#ef4444")
	b_style.set_border_width_all(1)
	b_style.set_corner_radius_all(12)
	b_style.content_margin_left = 24
	b_style.content_margin_right = 24
	b_style.content_margin_top = 8
	b_style.content_margin_bottom = 8
	banner.add_theme_stylebox_override("panel", b_style)
	action_box.add_child(banner)

	var fb_text := "✓ Chính xác! Nốt còn thiếu là %s." % expected if correct else "✕ Chưa đúng. Nốt đúng là %s." % expected
	feedback_label = Label.new()
	feedback_label.text = fb_text
	if ResourceLoader.exists("res://assets/fonts/BeVietnamPro-Bold.ttf"):
		feedback_label.add_theme_font_override("font", load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font)
	feedback_label.add_theme_font_size_override("font_size", 16)
	feedback_label.add_theme_color_override("font_color", Color("#15803d") if correct else Color("#b91c1c"))
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.add_child(feedback_label)
	
	if melody_index + 1 >= melodies.size():
		if report != null and report.is_signed_in() and result_sync_status == "be":
			await report.refresh_progress_from_backend()
		elif result_sync_status == "offline":
			var local_entry := {
				"kind": "melody_local",
				"client_attempt_id": _client_attempt_id("local-melody"),
				"title": "Hoàn thiện giai điệu",
				"lessonTitle": _instrument_title(),
				"score": score,
				"maxScore": melodies.size() * 100,
				"completedAt": _now_iso(),
				"status": "LOCAL_ONLY",
			}
			SecureDataManager.record_local_activity(local_entry)

		var total_max := 0
		for m in melodies:
			total_max += _safe_int(m.get("max_score", 100), 100)
		var stars := clampi(api_stars_earned, 0, 3)
		if stars == 0 and score > 0:
			stars = _stars(score, maxi(1, total_max))
		
		# Show complete button before result screen transition
		next_button = _button("Xem kết quả →", 240, 48, Color("#15803d") if correct else C_NAVY)
		next_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		next_button.pressed.connect(func() -> void:
			var accuracy := 100.0 * float(correct_rounds) / float(maxi(1, melodies.size()))
			var detail_msg := "Bạn đã hoàn thành tất cả %d giai điệu." % melodies.size()
			if result_sync_status == "failed":
				detail_msg += " Kết quả đang chờ đồng bộ lên máy chủ."
			elif result_sync_status == "offline":
				detail_msg += " Đây là lượt chơi thử."
			_show_result("Giai điệu hoàn thành!", detail_msg, score, stars, _restart, accuracy)
		)
		action_box.add_child(next_button)
		return
		
	next_button = _button("Giai điệu tiếp theo →", 240, 48, C_NAVY)
	next_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	next_button.pressed.connect(func() -> void:
		melody_index += 1
		next_button = null
		_show_round()
	)
	action_box.add_child(next_button)

func _note_equal(left: String, right: String) -> bool:
	return _to_vietnamese_solfege(left) == _to_vietnamese_solfege(right)

func _restart() -> void:
	_audio_generation += 1
	melody_index = 0
	score = 0
	api_stars_earned = 0
	correct_rounds = 0
	challenge_scores.clear()
	challenge_started_at.clear()
	next_button = null
	_show_round()

func _play_reference_audio() -> void:
	if not reference_audio_url.is_empty():
		_download_and_play_reference()
	else:
		_play_melody_fallback(melodies[melody_index % melodies.size()]["notes"])

func _download_and_play_reference() -> void:
	var generation := _audio_generation
	var requested_url := reference_audio_url
	var request := HTTPRequest.new()
	add_child(request)
	var error := request.request(requested_url)
	if error != OK:
		request.queue_free()
		return
	var response: Array = await request.request_completed
	request.queue_free()
	if not is_inside_tree() or generation != _audio_generation or requested_url != reference_audio_url:
		return
	if response.size() < 4 or int(response[1]) < 200 or int(response[1]) >= 300:
		return
	var body: PackedByteArray = response[3]
	var stream: AudioStream = _audio_stream_from_buffer(body, requested_url)
	if stream == null:
		return
	if audio_player and is_instance_valid(audio_player):
		audio_player.queue_free()
	audio_player = AudioStreamPlayer.new()
	audio_player.stream = stream
	add_child(audio_player)
	audio_player.play()

func _audio_stream_from_buffer(buffer: PackedByteArray, url: String) -> AudioStream:
	var lower := url.to_lower()
	if lower.contains(".ogg") or lower.contains(".oga"):
		return AudioStreamOggVorbis.load_from_buffer(buffer)
	if lower.contains(".mp3"):
		return AudioStreamMP3.load_from_buffer(buffer)
	return AudioStreamWAV.load_from_buffer(buffer)

func _play_melody_fallback(notes: Array) -> void:
	var generation := _audio_generation
	for note: Variant in notes:
		if not is_instance_valid(self) or generation != _audio_generation:
			return
		_play_tone(_frequency(str(note)))
		await get_tree().create_timer(0.35).timeout

func _play_tone(frequency: float) -> void:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 44100
	stream.buffer_length = 0.25
	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	player.play()
	var playback := player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	var frames := PackedVector2Array()
	for i in range(9000):
		var sample := sin(TAU * frequency * float(i) / 44100.0) * exp(-float(i) / 2800.0) * 0.18
		frames.append(Vector2(sample, sample))
	playback.push_buffer(frames)
	get_tree().create_timer(0.3).timeout.connect(player.queue_free)

func _frequency(note: String) -> float:
	var s := note.to_lower().strip_edges()
	if s.begins_with("zt_"):
		s = s.substr(3)
	# Prefer an explicit scientific-pitch name supplied by the challenge. This
	# keeps microphone scoring octave-aware (for example C3 versus C4).
	if s.length() >= 2 and s[0] in ["a", "b", "c", "d", "e", "f", "g"]:
		var letter_index := ["c", "d", "e", "f", "g", "a", "b"].find(s[0])
		var octave_text := s.substr(1)
		if octave_text.is_valid_int():
			var semitones_from_c: int = [0, 2, 4, 5, 7, 9, 11][letter_index]
			var midi: int = (int(octave_text) + 1) * 12 + semitones_from_c
			return 440.0 * pow(2.0, float(midi - 69) / 12.0)
		
	if s.begins_with("c1") or s.begins_with("c2"): return 130.81
	if s.begins_with("c3"): return 130.81
	if s.begins_with("c4") or s.begins_with("do") or s.begins_with("đô"): return 261.63
	if s.begins_with("d4") or s.begins_with("re") or s.begins_with("rê"): return 293.66
	if s.begins_with("e4") or s.begins_with("mi"): return 329.63
	if s.begins_with("f4") or s.begins_with("fa"): return 349.23
	if s.begins_with("g4") or s.begins_with("sol") or s.begins_with("so"): return 392.00
	if s.begins_with("a4") or s.begins_with("la"): return 440.00
	if s.begins_with("b4") or s.begins_with("si"): return 493.88
	if s.begins_with("c5") or s.begins_with("đố"): return 523.25
	if s.begins_with("d5") or s.begins_with("rế"): return 587.33
	if s.begins_with("e5") or s.begins_with("mí"): return 659.25
	if s.begins_with("g5") or s.begins_with("sól"): return 783.99
	if s.begins_with("a5") or s.begins_with("lá"): return 880.00
	return 392.00

func _safe_int(val: Variant, default: int = 0) -> int:
	if val == null:
		return default
	if val is String and val.is_empty():
		return default
	return int(val)

func _safe_str(val: Variant, default: String = "") -> String:
	if val == null:
		return default
	return str(val)
