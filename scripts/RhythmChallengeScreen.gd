extends "res://scripts/LearningActivityBase.gd"

var rhythms: Array = []
var rhythm_index := 0
var challenge_id := 0
var beat_times: Array[float] = []
var judgements: Array[String] = []
var started_at := ""
var started_at_ms := 0
var playing := false
var countdown_active := false
var score := 0
var api_stars_earned := 0
var hits := 0
var accuracy_points := 0
var status_label: Label
var accuracy_label: Label
var timeline: Control
var tap_button: Button
var countdown_label: Label
var round_duration := 1.0

func _ready() -> void:
	super._ready()
	title_label.text = "MINI-GAME 1 - THỬ THÁCH NHỊP ĐIỆU"
	_load_challenge()

func _load_challenge() -> void:
	var report := _report()
	var target_challenges: Array = []
	
	if report != null and report.is_signed_in():
		result_sync_status = "be"
		if SecureDataManager.be_catalog.is_empty():
			await report.fetch_and_install_catalog()
		for local_id: String in Context.local_lesson_ids:
			var lesson := SecureDataManager.resolve_be_lesson(Context.instrument, local_id)
			if lesson.is_empty():
				continue
			var lesson_id := _safe_int(lesson.get("id", 0))
			var minigames: Array = await report.ensure_minigame_list(lesson_id)
			for item: Variant in minigames:
				if item is Dictionary:
					var actual := str(item.get("challengeType", item.get("challenge_type", ""))).to_upper().replace("-", "_").replace(" ", "_")
					if actual == "RHYTHM_MATCH":
						target_challenges.append(item)
			break
			
	target_challenges.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var order_a = _safe_int(a.get("orderIndex", a.get("order_index", 0)))
		var order_b = _safe_int(b.get("orderIndex", b.get("order_index", 0)))
		return order_a < order_b
	)
	
	_parse_challenges(target_challenges)
	_build_intro()

func _parse_challenges(challenges: Array) -> void:
	rhythms.clear()
	for challenge_item: Variant in challenges:
		if not challenge_item is Dictionary:
			continue
		var parsed: Variant = _extract_json(_safe_str(challenge_item.get("contentJson", challenge_item.get("content_json", ""))))
		var source: Dictionary = parsed if parsed is Dictionary else {}
		var beats: Array = source.get("beats", [])
		var rounds: Variant = source.get("rounds", [])
		if beats.is_empty() and rounds is Array and not rounds.is_empty():
			var first: Variant = rounds[0]
			if first is Dictionary:
				beats = first.get("beats", [])
				
		var times: Array[float] = []
		for beat: Variant in beats:
			times.append(float(beat))
		if times.is_empty():
			times = [0.5, 1.0, 1.5, 2.0]
			
		rhythms.append({
			"beats": times,
			"challenge_id": _safe_int(challenge_item.get("id", 0)),
			"max_score": _safe_int(challenge_item.get("maxScore", challenge_item.get("max_score", times.size() * 100)), times.size() * 100)
		})
		
	if rhythms.is_empty():
		rhythms.append({
			"beats": [0.5, 1.0, 1.5, 2.0],
			"challenge_id": 0,
			"max_score": 500
		})

func _build_intro() -> void:
	# Load current rhythm's data
	var rhythm: Dictionary = rhythms[rhythm_index % rhythms.size()]
	beat_times = rhythm["beats"]
	challenge_id = rhythm["challenge_id"]
	
	judgements.clear()
	for _beat in beat_times:
		judgements.append("")
		
	for child in content_box.get_children():
		child.queue_free()
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _panel(Color.WHITE, C_GREEN, 24, 2))
	content_box.add_child(card)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	card.add_child(body)
	var heading := _label("Nghe và gõ theo mẫu nhịp", 20 if get_viewport_rect().size.x < 600.0 else 23, C_NAVY)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(heading)
	var desc := _label("Giữ playhead trùng với beat để đạt Perfect hoặc Good.", 15 if get_viewport_rect().size.x < 600.0 else 17, C_MUTED)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(desc)
	var sample := _secondary_button("▶  Nghe mẫu", 220, 52, C_GREEN)
	sample.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	sample.pressed.connect(_play_sample)
	body.add_child(sample)
	var start := _button("Bắt đầu", 220, 54, C_BLUE)
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start.pressed.connect(_start_round)
	body.add_child(start)

func _play_sample() -> void:
	var sample_label := _label("Mẫu nhịp: %s" % ", ".join(PackedStringArray(beat_times.map(func(value: float) -> String: return "%.1f" % value))), 17, C_MUTED)
	sample_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_box.add_child(sample_label)

func _start_round() -> void:
	if playing or countdown_active:
		return
	countdown_active = true
	score = 0
	hits = 0
	accuracy_points = 0
	for i in judgements.size():
		judgements[i] = ""
	_run_countdown()

func _run_countdown() -> void:
	for child in content_box.get_children():
		child.queue_free()
	countdown_label = _label("3", 64, C_NAVY)
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_box.add_child(countdown_label)
	for value in ["3", "2", "1", "BẮT ĐẦU"]:
		if not is_instance_valid(countdown_label):
			return
		countdown_label.text = value
		await get_tree().create_timer(0.65).timeout
	countdown_active = false
	playing = true
	started_at = _now_iso()
	started_at_ms = Time.get_ticks_msec()
	_build_game()
	round_duration = (beat_times[-1] if not beat_times.is_empty() else 2.0) + 1.2
	get_tree().create_timer(round_duration).timeout.connect(_finish_round)

func _process(_delta: float) -> void:
	if not playing:
		return
	var elapsed := float(Time.get_ticks_msec() - started_at_ms) / 1000.0
	for i in beat_times.size():
		if judgements[i].is_empty() and elapsed > beat_times[i] + 0.24:
			_set_judgement(i, "MISS")
	if timeline:
		timeline.set("active", true)
		timeline.set("current_time", elapsed)
		timeline.set("judgements", judgements)
		timeline.queue_redraw()
	if accuracy_label:
		accuracy_label.text = "Độ chính xác: %.0f%%" % _accuracy_percent()

func _build_game() -> void:
	for child in content_box.get_children():
		child.queue_free()
	status_label = _label("Gõ đúng nhịp theo mẫu.", 20, C_MUTED)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_box.add_child(status_label)
	accuracy_label = _label("Độ chính xác: 0%", 18, C_NAVY)
	accuracy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_box.add_child(accuracy_label)
	timeline = Control.new()
	timeline.set_script(load("res://scripts/LearningBeatLane.gd"))
	timeline.custom_minimum_size = Vector2(0, 150)
	round_duration = (beat_times[-1] if not beat_times.is_empty() else 2.0) + 1.2
	timeline.call("configure", beat_times, round_duration)
	timeline.set("active", true)
	content_box.add_child(timeline)
	tap_button = _button("TAP / GÕ NHỊP", 300, 100, C_GREEN)
	tap_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tap_button.pressed.connect(_tap)
	content_box.add_child(tap_button)

func _tap() -> void:
	if not playing:
		return
	var elapsed := float(Time.get_ticks_msec() - started_at_ms) / 1000.0
	var closest := -1
	var closest_diff := 999.0
	for i in beat_times.size():
		if not judgements[i].is_empty():
			continue
		var diff := absf(elapsed - beat_times[i])
		if diff < closest_diff:
			closest = i
			closest_diff = diff
	if closest < 0:
		return
	if closest_diff <= 0.24:
		var judgement := "PERFECT" if closest_diff <= 0.08 else "GOOD"
		_set_judgement(closest, judgement)
		hits += 1
		score += 100 if judgement == "PERFECT" else 70
	else:
		_set_judgement(closest, "MISS")

func _set_judgement(index: int, value: String) -> void:
	if index < 0 or index >= judgements.size() or not judgements[index].is_empty():
		return
	judgements[index] = value
	if value == "PERFECT":
		accuracy_points += 100
	elif value == "GOOD":
		accuracy_points += 70
	if status_label:
		status_label.text = value
	if accuracy_label:
		accuracy_label.text = "Độ chính xác: %.0f%%" % _accuracy_percent()
	if timeline:
		timeline.set("judgements", judgements)
		timeline.queue_redraw()

func _accuracy_percent() -> float:
	return float(accuracy_points) / float(maxi(1, beat_times.size() * 100)) * 100.0

func _finish_round() -> void:
	if not playing:
		return
	playing = false
	if timeline:
		timeline.set("active", false)
		
	var current_rhythm: Dictionary = rhythms[rhythm_index % rhythms.size()]
	var current_id := _safe_int(current_rhythm.get("challenge_id", 0))
	var current_max := _safe_int(current_rhythm.get("max_score", 100), 100)
	
	var round_score := int(float(accuracy_points) / float(maxi(1, beat_times.size() * 100)) * float(current_max))
	var round_stars := _stars(round_score, current_max)
	
	var report := _report()
	if report != null and current_id > 0:
		var result: Dictionary = await report.report_minigame_by_id(current_id, round_score, round_stars, started_at, _now_iso())
		if bool(result.get("submitted", false)):
			api_stars_earned += maxi(0, int(result.get("stars_earned", 0)))
		
	score += round_score
	
	for child in content_box.get_children():
		child.queue_free()
		
	var detail_text := "Đúng %d / %d phách · Accuracy %.0f%%" % [hits, beat_times.size(), _accuracy_percent()]
	
	if rhythm_index + 1 >= rhythms.size():
		if report != null and report.is_signed_in():
			await report.refresh_progress_from_backend()
		var final_stars := clampi(api_stars_earned, 0, 3)
		_show_result("Nhịp điệu hoàn thành!", detail_text, score, final_stars, _restart, _accuracy_percent())
		return
		
	# Show round result card with a Next Round button
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _panel(Color.WHITE, C_GREEN, 24, 2))
	content_box.add_child(card)
	
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	card.add_child(body)
	
	var heading := _label("Vòng %d hoàn thành!" % (rhythm_index + 1), 22, C_NAVY)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(heading)
	
	var detail_lbl := _label(detail_text, 17, C_MUTED)
	detail_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(detail_lbl)
	
	var next_btn := _button("Vòng tiếp theo →", 220, 54, C_BLUE)
	next_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	next_btn.pressed.connect(func() -> void:
		rhythm_index += 1
		_build_intro()
	)
	body.add_child(next_btn)

func _restart() -> void:
	rhythm_index = 0
	score = 0
	api_stars_earned = 0
	_build_intro()

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
