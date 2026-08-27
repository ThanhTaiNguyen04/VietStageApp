extends "res://scripts/LearningActivityBase.gd"

const RhythmModel = preload("res://scripts/RhythmChallengeModel.gd")

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
const C_GREEN_DARK := Color("#2f7d46")
const C_GREEN_SOFT := Color("#eaf6ed")
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

var round_accuracy_points := 0
var round_hits := 0
var challenge_accuracy_points := 0
var challenge_beat_count := 0
var total_accuracy_points := 0
var total_beat_count := 0
var total_score := 0
var total_max_score := 0
var backend_stars_earned := 0
var backend_points_earned := 0
var submitted_count := 0
var sync_failures: Array[Dictionary] = []
var online_session := false

var status_label: Label
var accuracy_label: Label
var hit_label: Label
var timeline: Control
var tap_button: Button
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
	title_label.text = "MINI-GAME 1 · THỬ THÁCH NHỊP ĐIỆU"
	click_stream = _make_click_stream(880.0)
	accent_stream = _make_click_stream(1174.66)
	click_player = AudioStreamPlayer.new()
	click_player.name = "RhythmClickPlayer"
	add_child(click_player)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_load_challenges()


func _exit_tree() -> void:
	load_generation += 1
	session_generation += 1
	preview_generation += 1
	playing = false


func _unhandled_input(event: InputEvent) -> void:
	if flow_state == FlowState.PLAYING and event.is_action_pressed("ui_accept"):
		_tap()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not playing or flow_state != FlowState.PLAYING:
		return
	var elapsed := float(Time.get_ticks_msec() - round_started_at_ms) / 1000.0
	for index in beat_times.size():
		if judgements[index].is_empty() and elapsed > beat_times[index] + GOOD_WINDOW:
			_set_judgement(index, "MISS")
	if is_instance_valid(timeline):
		timeline.call("update_progress", elapsed, judgements)
	_update_live_metrics()


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

	var seen_ids: Dictionary = {}
	for lesson_position in Context.local_lesson_ids.size():
		var local_id := Context.local_lesson_ids[lesson_position]
		var lesson := SecureDataManager.resolve_be_lesson(Context.instrument, local_id)
		if lesson.is_empty():
			continue
		var lesson_id := _safe_int(lesson.get("id", 0))
		if lesson_id <= 0:
			continue
		var minigames: Array = await report.ensure_minigame_list(lesson_id)
		if generation != load_generation or not is_inside_tree():
			return
		for item_value: Variant in minigames:
			if not item_value is Dictionary:
				continue
			var item: Dictionary = item_value
			if _normalize_type(str(item.get("challengeType", item.get("challenge_type", "")))) != "RHYTHM_MATCH":
				continue
			var item_id := _safe_int(item.get("id", 0))
			if item_id > 0 and seen_ids.has(item_id):
				continue
			if item_id > 0:
				seen_ids[item_id] = true
			var enriched := item.duplicate(true)
			enriched["lesson_id"] = lesson_id
			enriched["_lesson_position"] = lesson_position
			target_challenges.append(enriched)

	target_challenges.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var lesson_a := _safe_int(a.get("_lesson_position", 0))
		var lesson_b := _safe_int(b.get("_lesson_position", 0))
		if lesson_a != lesson_b:
			return lesson_a < lesson_b
		return _safe_int(a.get("orderIndex", a.get("order_index", 0))) < _safe_int(b.get("orderIndex", b.get("order_index", 0)))
	)

	rhythms = RhythmModel.parse_challenges(target_challenges)
	if rhythms.is_empty():
		_set_flow_state(FlowState.ERROR)
		_build_load_error(
			"Chưa tìm thấy thử thách RHYTHM_MATCH cho bài học này.",
			"Bạn có thể thử tải lại hoặc chơi bằng dữ liệu mẫu trên thiết bị."
		)
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
	rhythms = RhythmModel.parse_challenges([item])
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
	challenge_accuracy_points = 0
	challenge_beat_count = 0
	total_accuracy_points = 0
	total_beat_count = 0
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

	var current := rhythms[rhythm_index]
	var card_body := _add_centered_card(C_GREEN, 840.0)
	var eyebrow := _label("MINI-GAME 1", 12, C_GREEN_DARK)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(_chip(eyebrow, C_GREEN_SOFT, Color(C_GREEN.r, C_GREEN.g, C_GREEN.b, 0.28)))

	var icon := _label("♫", 62 if _is_mobile() else 72, C_GREEN)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(icon)

	var heading := _label(str(current.get("title", "Thử thách nhịp điệu")), 24 if _is_mobile() else 30, C_NAVY)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(heading)

	var round_text := "Vòng %d/%d" % [rhythm_index + 1, rhythms.size()]
	var detail_parts: Array[String] = [round_text, "%d phách" % beat_times.size()]
	var tempo := _safe_int(current.get("tempo_bpm", 0))
	if tempo > 0:
		detail_parts.append("%d BPM" % tempo)
	var difficulty := str(current.get("difficulty", "")).strip_edges()
	if not difficulty.is_empty():
		detail_parts.append(difficulty)
	var detail := _label("  ·  ".join(detail_parts), 14 if _is_mobile() else 16, C_MUTED)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(detail)

	var instruction := _label("Nghe mẫu, quan sát vạch quét và gõ khi vạch đi qua từng điểm nhịp.", 16 if _is_mobile() else 18, C_TEXT)
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(instruction)

	card_body.add_child(_build_beat_preview())
	preview_status = _label("PERFECT ±80 ms  ·  GOOD ±240 ms", 13 if _is_mobile() else 14, C_MUTED)
	preview_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(preview_status)

	var actions := BoxContainer.new()
	actions.vertical = _is_mobile()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_body.add_child(actions)
	preview_button = _secondary_button("▶  Nghe mẫu", 0, 56, C_GREEN_DARK)
	preview_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_button.pressed.connect(_play_sample)
	actions.add_child(preview_button)
	var start := _button("Bắt đầu  →", 0, 56, C_GREEN)
	start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start.pressed.connect(_start_round)
	actions.add_child(start)

	var mode_text := "Đã kết nối · kết quả sẽ được đồng bộ" if online_session else "Chế độ offline · điểm chỉ được tính trên thiết bị"
	var mode_color := C_OK if online_session else C_MUTED
	var mode := _label(mode_text, 13, mode_color)
	mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(mode)


func _build_beat_preview() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 74)
	panel.add_theme_stylebox_override("panel", _soft_panel(C_GOLD_SOFT, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.30), 16))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14 if _is_mobile() else 20)
	panel.add_child(row)
	for index in beat_times.size():
		var beat := _label("●", 22 if _is_mobile() else 26, C_GOLD)
		beat.tooltip_text = "Phách %d · %.2f giây" % [index + 1, beat_times[index]]
		row.add_child(beat)
	return panel


func _play_sample() -> void:
	if flow_state == FlowState.PREVIEW:
		preview_generation += 1
		if is_instance_valid(click_player):
			click_player.stop()
		_set_flow_state(FlowState.INTRO)
		if is_instance_valid(preview_button):
			preview_button.disabled = false
			preview_button.text = "▶  Nghe mẫu"
		if is_instance_valid(preview_status):
			preview_status.text = "Đã dừng mẫu nhịp"
		return
	if flow_state != FlowState.INTRO:
		return
	preview_generation += 1
	var generation := preview_generation
	_set_flow_state(FlowState.PREVIEW)
	preview_button.text = "■  Dừng nghe"
	preview_status.text = "Đang phát mẫu nhịp…"
	_run_preview(generation)


func _run_preview(generation: int) -> void:
	var previous_time := 0.0
	for index in beat_times.size():
		var wait_time := maxf(0.01, beat_times[index] - previous_time)
		await get_tree().create_timer(wait_time).timeout
		if generation != preview_generation or not is_inside_tree():
			return
		_play_click(index == 0)
		previous_time = beat_times[index]
	await get_tree().create_timer(0.35).timeout
	if generation != preview_generation or not is_inside_tree():
		return
	_set_flow_state(FlowState.INTRO)
	if is_instance_valid(preview_button):
		preview_button.text = "↻  Nghe lại"
	if is_instance_valid(preview_status):
		preview_status.text = "Mẫu nhịp đã phát xong · bạn đã sẵn sàng!"


func _start_round() -> void:
	if flow_state not in [FlowState.INTRO, FlowState.PREVIEW]:
		return
	preview_generation += 1
	session_generation += 1
	var generation := session_generation
	playing = false
	round_accuracy_points = 0
	round_hits = 0
	for index in judgements.size():
		judgements[index] = ""
	_run_countdown(generation)


func _run_countdown(generation: int) -> void:
	_set_flow_state(FlowState.COUNTDOWN)
	_clear_content()
	var card_body := _add_centered_card(C_GREEN, 640.0)
	var prompt := _label("Sẵn sàng gõ theo nhịp", 20 if _is_mobile() else 24, C_NAVY)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(prompt)
	countdown_label = _label("3", 78 if _is_mobile() else 96, C_GREEN)
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(countdown_label)
	var hint := _label("Bạn có thể dùng nút TAP hoặc phím Space / Enter", 14, C_MUTED)
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
	playing = true
	_set_flow_state(FlowState.PLAYING)
	_build_game()
	await get_tree().create_timer(round_duration).timeout
	if generation == session_generation and playing and is_inside_tree():
		_finish_round()


func _build_game() -> void:
	_clear_content(false)
	var current := rhythms[rhythm_index]
	var card_body := _add_centered_card(C_GREEN, 980.0)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 10)
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_body.add_child(top_row)
	var round_chip_label := _label("VÒNG %d/%d" % [rhythm_index + 1, rhythms.size()], 12, C_GREEN_DARK)
	top_row.add_child(_chip(round_chip_label, C_GREEN_SOFT, Color(C_GREEN.r, C_GREEN.g, C_GREEN.b, 0.28)))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)
	var keyboard_hint := _label("SPACE / ENTER", 12, C_MUTED)
	top_row.add_child(_chip(keyboard_hint, Color("#f3f5f8"), Color("#d8deea")))

	var heading := _label(str(current.get("title", "Thử thách nhịp điệu")), 21 if _is_mobile() else 26, C_NAVY)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(heading)

	var metrics := HBoxContainer.new()
	metrics.alignment = BoxContainer.ALIGNMENT_CENTER
	metrics.add_theme_constant_override("separation", 24 if _is_mobile() else 48)
	card_body.add_child(metrics)
	accuracy_label = _label("Độ chính xác  0%", 16 if _is_mobile() else 18, C_NAVY)
	hit_label = _label("Đúng nhịp  0/%d" % beat_times.size(), 16 if _is_mobile() else 18, C_NAVY)
	accuracy_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	hit_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	metrics.add_child(accuracy_label)
	metrics.add_child(hit_label)

	timeline = Control.new()
	timeline.name = "BeatLane"
	timeline.set_script(load("res://scripts/LearningBeatLane.gd"))
	timeline.custom_minimum_size = Vector2(0, 150 if _is_mobile() else 168)
	timeline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timeline.call("configure", beat_times, round_duration)
	timeline.call("update_progress", 0.0, judgements)
	card_body.add_child(timeline)

	status_label = _label("CHỜ NHỊP…", 20 if _is_mobile() else 24, C_MUTED)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.custom_minimum_size = Vector2(0, 28)
	card_body.add_child(status_label)

	tap_button = _button("TAP  ·  GÕ NHỊP", 0, 76 if _is_mobile() else 84, C_GREEN)
	tap_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tap_button.add_theme_font_size_override("font_size", 22 if _is_mobile() else 26)
	tap_button.tooltip_text = "Gõ đúng lúc vạch quét đi qua điểm nhịp"
	tap_button.pressed.connect(_tap)
	card_body.add_child(tap_button)

	var guidance := _label("Chạm nút hoặc nhấn Space / Enter khi playhead đi qua chấm vàng.", 13 if _is_mobile() else 14, C_MUTED)
	guidance.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(guidance)


func _tap() -> void:
	if not playing or flow_state != FlowState.PLAYING:
		return
	var elapsed := float(Time.get_ticks_msec() - round_started_at_ms) / 1000.0
	var decision := RhythmModel.judge_tap(elapsed, beat_times, judgements, PERFECT_WINDOW, GOOD_WINDOW)
	var index := int(decision.get("index", -1))
	if index < 0:
		_show_feedback("CHỜ NHỊP…", C_MUTED)
		_pulse_control(tap_button, 0.98)
		return
	var judgement := str(decision.get("judgement", ""))
	_set_judgement(index, judgement)
	if judgement in ["PERFECT", "GOOD"]:
		round_hits += 1
		Input.vibrate_handheld(18 if judgement == "PERFECT" else 10)
		_pulse_control(tap_button, 1.025)
	_update_live_metrics()


func _set_judgement(index: int, value: String) -> void:
	if index < 0 or index >= judgements.size() or not judgements[index].is_empty():
		return
	judgements[index] = value
	if value == "PERFECT":
		round_accuracy_points += 100
		_show_feedback("PERFECT  +100", C_OK)
	elif value == "GOOD":
		round_accuracy_points += 70
		_show_feedback("GOOD  +70", C_BLUE)
	else:
		_show_feedback("MISS", C_BAD)
	if is_instance_valid(timeline):
		timeline.call("update_progress", float(Time.get_ticks_msec() - round_started_at_ms) / 1000.0, judgements)


func _show_feedback(text_value: String, color: Color) -> void:
	if not is_instance_valid(status_label):
		return
	status_label.text = text_value
	status_label.add_theme_color_override("font_color", color)
	_pulse_control(status_label, 1.08)


func _update_live_metrics() -> void:
	var accuracy := RhythmModel.accuracy_percent(round_accuracy_points, beat_times.size())
	if is_instance_valid(accuracy_label):
		accuracy_label.text = "Độ chính xác  %.0f%%" % accuracy
	if is_instance_valid(hit_label):
		hit_label.text = "Đúng nhịp  %d/%d" % [round_hits, beat_times.size()]


func _finish_round() -> void:
	if not playing:
		return
	playing = false
	_set_flow_state(FlowState.SUBMITTING)
	if is_instance_valid(timeline):
		timeline.set("active", false)

	var current := rhythms[rhythm_index]
	var round_accuracy := RhythmModel.accuracy_percent(round_accuracy_points, beat_times.size())
	challenge_accuracy_points += round_accuracy_points
	challenge_beat_count += beat_times.size()
	total_accuracy_points += round_accuracy_points
	total_beat_count += beat_times.size()

	if bool(current.get("submit_after", true)):
		var max_score := _safe_int(current.get("max_score", 100), 100)
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
			"title": str(current.get("title", "Thử thách nhịp điệu")),
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
		_build_round_result(round_accuracy)
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
	var response: Dictionary = await report.report_minigame_by_id(
		int(payload.get("minigame_id", 0)),
		int(payload.get("score", 0)),
		int(payload.get("stars", 0)),
		str(payload.get("started_at", "")),
		str(payload.get("completed_at", "")),
		str(payload.get("client_attempt_id", ""))
	)
	if not bool(response.get("submitted", false)):
		payload["error"] = str(response.get("message", "Không thể đồng bộ kết quả."))
		return false
	submitted_count += 1
	backend_stars_earned += maxi(0, int(response.get("stars_earned", 0)))
	backend_points_earned += maxi(0, int(response.get("points_earned", 0)))
	return true


func _build_round_result(round_accuracy: float) -> void:
	_set_flow_state(FlowState.ROUND_RESULT)
	_clear_content()
	var card_body := _add_centered_card(C_GREEN, 760.0)
	var icon := _label("✓", 64 if _is_mobile() else 76, C_OK)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(icon)
	var heading := _label("Vòng %d hoàn thành!" % (rhythm_index + 1), 24 if _is_mobile() else 28, C_NAVY)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(heading)
	var detail := _label("Đúng %d/%d phách  ·  Accuracy %.0f%%" % [round_hits, beat_times.size(), round_accuracy], 16 if _is_mobile() else 18, C_MUTED)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(detail)
	var next_title := str(rhythms[rhythm_index + 1].get("title", "Thử thách tiếp theo"))
	var next_hint := _label("Tiếp theo: %s" % next_title, 14, C_TEXT)
	next_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(next_hint)
	var next_button := _button("Vòng tiếp theo  →", 0, 58, C_GREEN)
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
	content_box.alignment = BoxContainer.ALIGNMENT_CENTER
	content_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var card_body := _add_centered_card(C_GOLD, 900.0)
	var stars := RhythmModel.stars_for_score(total_score, total_max_score)
	var accuracy := RhythmModel.accuracy_percent(total_accuracy_points, total_beat_count)
	var icon := _label("★" if stars > 0 else "✓", 66 if _is_mobile() else 78, C_GOLD if stars > 0 else C_OK)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(icon)
	var heading := _label("Nhịp điệu hoàn thành!", 25 if _is_mobile() else 30, C_NAVY)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(heading)
	var detail := _label("Bạn đã hoàn thành %d phách trong %d vòng thử thách." % [total_beat_count, rhythms.size()], 15 if _is_mobile() else 17, C_MUTED)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(detail)

	var metrics := GridContainer.new()
	metrics.columns = 2 if _is_mobile() else 4
	metrics.add_theme_constant_override("h_separation", 12)
	metrics.add_theme_constant_override("v_separation", 12)
	metrics.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_body.add_child(metrics)
	metrics.add_child(_metric_card("◆", "Điểm", "%d / %d" % [total_score, total_max_score], C_BLUE))
	metrics.add_child(_metric_card("%", "Accuracy", "%.0f%%" % accuracy, C_GREEN))
	metrics.add_child(_metric_card("★", "Xếp hạng", "%d / 3" % stars, C_GOLD))
	metrics.add_child(_metric_card("●", "Điểm thưởng", "+%d" % backend_points_earned if submitted_count > 0 else "—", C_PURPLE))

	var sync_text := "○ Offline · kết quả chưa gửi lên hệ thống"
	var sync_color := C_MUTED
	if online_session and sync_failures.is_empty():
		sync_text = "✓ Đã đồng bộ %d kết quả · nhận %d sao" % [submitted_count, backend_stars_earned]
		sync_color = C_OK
	elif online_session:
		sync_text = "⚠ Còn %d kết quả chưa đồng bộ" % sync_failures.size()
		sync_color = C_BAD
	var sync := _label(sync_text, 13 if _is_mobile() else 14, sync_color)
	sync.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(sync)

	if not sync_failures.is_empty():
		var retry_sync := _secondary_button("↻  Thử đồng bộ lại", 0, 54, C_BAD)
		retry_sync.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		retry_sync.pressed.connect(_retry_sync)
		card_body.add_child(retry_sync)

	var actions := BoxContainer.new()
	actions.vertical = _is_mobile()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_body.add_child(actions)
	var retry := _button("Chơi lại", 0, 58, C_GREEN)
	retry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	retry.pressed.connect(_restart)
	actions.add_child(retry)
	var back := _secondary_button("Về hoạt động", 0, 58, C_NAVY)
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
	var card_body := _add_centered_card(C_GREEN, 620.0)
	var icon := _label("♫", 64 if _is_mobile() else 76, C_GREEN)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(icon)
	var heading := _label(message, 19 if _is_mobile() else 22, C_NAVY)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(heading)
	var hint := _label("VietStage đang chuẩn bị dữ liệu và nhịp mẫu cho bạn.", 14, C_MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(hint)
	var tween := create_tween()
	tween.bind_node(icon)
	tween.set_loops(12)
	tween.tween_property(icon, "modulate:a", 0.35, 0.55)
	tween.tween_property(icon, "modulate:a", 1.0, 0.55)


func _build_load_error(title: String, description: String, allow_retry: bool = true) -> void:
	_clear_content()
	content_box.alignment = BoxContainer.ALIGNMENT_CENTER
	content_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var card_body := _add_centered_card(C_BAD, 700.0)
	var icon := _label("!", 62, C_BAD)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(icon)
	var heading := _label(title, 22 if _is_mobile() else 26, C_NAVY)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(heading)
	var detail := _label(description, 15 if _is_mobile() else 17, C_MUTED)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.add_child(detail)
	var actions := BoxContainer.new()
	actions.vertical = _is_mobile()
	actions.add_theme_constant_override("separation", 12)
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_body.add_child(actions)
	if allow_retry:
		var retry := _button("Thử tải lại", 0, 56, C_BLUE)
		retry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		retry.pressed.connect(_load_challenges)
		actions.add_child(retry)
	var offline := _secondary_button("Chơi offline", 0, 56, C_GREEN_DARK)
	offline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	offline.pressed.connect(_use_offline_data)
	actions.add_child(offline)


func _prepare_current_round() -> void:
	var current := rhythms[rhythm_index]
	beat_times.clear()
	for value: Variant in current.get("beats", []):
		beat_times.append(float(value))
	judgements.clear()
	for _beat in beat_times:
		judgements.append("")
	round_duration = (beat_times[-1] if not beat_times.is_empty() else 2.0) + 1.0


func _clear_content(stop_preview: bool = true) -> void:
	if stop_preview:
		preview_generation += 1
	if is_instance_valid(click_player):
		click_player.stop()
	for child in content_box.get_children():
		child.queue_free()
	content_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	content_box.size_flags_vertical = Control.SIZE_FILL
	content_box.add_theme_constant_override("separation", 18 if _is_mobile() else 22)
	status_label = null
	accuracy_label = null
	hit_label = null
	timeline = null
	tap_button = null
	countdown_label = null
	preview_button = null
	preview_status = null


func _add_centered_card(accent: Color, max_width: float) -> VBoxContainer:
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_box.add_child(center)
	var card := PanelContainer.new()
	var available := maxf(300.0, get_viewport_rect().size.x - (32.0 if _is_mobile() else 120.0))
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
	style.bg_color = Color(1.0, 1.0, 1.0, 0.95)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.58)
	style.set_border_width_all(2)
	style.set_corner_radius_all(22)
	style.shadow_color = Color(accent.r, accent.g, accent.b, 0.20)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 7)
	var horizontal_margin := 18.0 if _is_mobile() else 34.0
	var vertical_margin := 18.0 if _is_mobile() else 20.0
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
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


func _chip(label: Label, background: Color, border: Color) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	chip.add_theme_stylebox_override("panel", _soft_panel(background, border, 18))
	chip.add_child(label)
	return chip


func _set_flow_state(next_state: int) -> void:
	flow_state = next_state


func _on_viewport_size_changed() -> void:
	if flow_state == FlowState.INTRO:
		_build_intro()
	elif flow_state == FlowState.ROUND_RESULT:
		_build_round_result(RhythmModel.accuracy_percent(round_accuracy_points, beat_times.size()))
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
