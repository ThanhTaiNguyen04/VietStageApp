extends "res://scripts/LearningActivityBase.gd"

var challenge: Dictionary = {}
var challenge_id := 0
var lesson_id := 0
var melodies: Array = []
var melody_index := 0
var score := 0
var started_at := ""
var melody_staff: Control
var options_box: HBoxContainer
var feedback_label: Label
var next_button: Button
var listen_button: Button
var reference_audio_url := ""
var audio_player: AudioStreamPlayer

func _ready() -> void:
	super._ready()
	title_label.text = "MINI-GAME 2 - HOÀN THIỆN GIAI ĐIỆU"
	_load_challenge()

func _load_challenge() -> void:
	var report := _report()
	if report != null and report.is_signed_in():
		result_sync_status = "be"
		for local_id: String in Context.local_lesson_ids:
			var lesson := SecureDataManager.resolve_be_lesson(Context.instrument, local_id)
			if lesson.is_empty():
				continue
			lesson_id = int(lesson.get("id", 0))
			challenge = await report.ensure_minigame_by_type(lesson_id, "MELODY_COMPLETION")
			if not challenge.is_empty():
				await _resolve_reference_audio(report)
				break
	if challenge.is_empty():
		result_sync_status = "offline"
		var samples: Dictionary = _sample_data()
		challenge = samples.get("melody", {"maxScore": 500, "contentJson": JSON.stringify({"melodies": [{"notes": ["Đô", "Rê", "Mi", "Sol", "La"], "missingIndex": 2}]})})
	challenge_id = int(challenge.get("id", 0))
	_parse_challenge()
	_show_round()

func _resolve_reference_audio(report: Node) -> void:
	var parsed: Variant = _extract_json(challenge.get("contentJson", ""))
	var source: Dictionary = parsed if parsed is Dictionary else {}
	reference_audio_url = str(challenge.get("referenceAudioUrl", challenge.get("audioUrl", source.get("referenceAudioUrl", source.get("audioUrl", "")))))
	var reference_asset_id := int(challenge.get("referenceAssetId", source.get("referenceAssetId", 0)))
	if reference_audio_url.is_empty() and reference_asset_id > 0 and lesson_id > 0:
		var assets: Array = await report.fetch_lesson_assets(lesson_id)
		for item: Variant in assets:
			if item is Dictionary and int(item.get("id", 0)) == reference_asset_id:
				reference_audio_url = str(item.get("assetUrl", ""))
				break

func _parse_challenge() -> void:
	var parsed: Variant = _extract_json(challenge.get("contentJson", ""))
	var source: Dictionary = parsed if parsed is Dictionary else {}
	var raw_melodies: Array = source.get("melodies", source.get("rounds", []))
	melodies.clear()
	for item: Variant in raw_melodies:
		if item is Dictionary:
			var notes: Array = item.get("notes", item.get("sequence", []))
			if not notes.is_empty():
				var missing := int(item.get("missingIndex", item.get("missing_idx", -1)))
				if missing < 0:
					missing = maxi(0, int(notes.size() / 2))
				melodies.append({"notes": notes, "missing": missing, "options": item.get("options", [])})
	if melodies.is_empty():
		melodies.append({"notes": ["Đô", "Rê", "Mi", "Sol", "La"], "missing": 2, "options": []})

func _show_round() -> void:
	for child in content_box.get_children():
		child.queue_free()
	var melody: Dictionary = melodies[melody_index % melodies.size()]
	var header := _label("Giai điệu %d / %d" % [melody_index + 1, melodies.size()], 19, C_MUTED)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_box.add_child(header)
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _panel(Color.WHITE, C_PURPLE, 24, 2))
	content_box.add_child(card)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	card.add_child(body)
	var heading := _label("Nghe giai điệu rồi chọn nốt còn thiếu", 20 if get_viewport_rect().size.x < 600.0 else 22, C_NAVY)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(heading)
	melody_staff = Control.new()
	melody_staff.set_script(load("res://scripts/LearningMelodyStaffDisplay.gd"))
	melody_staff.custom_minimum_size = Vector2(0, 190)
	melody_staff.call("configure", melody["notes"], int(melody["missing"]))
	body.add_child(melody_staff)
	listen_button = _secondary_button("▶  Nghe giai điệu", 230, 52, C_PURPLE)
	listen_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	listen_button.pressed.connect(_play_reference_audio)
	body.add_child(listen_button)
	options_box = HBoxContainer.new()
	options_box.alignment = BoxContainer.ALIGNMENT_CENTER
	options_box.add_theme_constant_override("separation", 10)
	body.add_child(options_box)
	var choices: Array = melody["options"]
	if choices.is_empty():
		choices = ["Đô", "Rê", "Mi", "Sol", "La"]
	for choice: Variant in choices:
		var option := _button(str(choice), 90, 52, C_BLUE)
		option.pressed.connect(func() -> void: _answer(str(choice), str(melody["notes"][int(melody["missing"])]), melody))
		options_box.add_child(option)
	started_at = _now_iso()

func _answer(selected: String, expected: String, melody: Dictionary) -> void:
	if next_button != null and is_instance_valid(next_button):
		return
	var correct := _note_equal(selected, expected)
	if correct:
		score += int(challenge.get("maxScore", 500)) / maxi(1, melodies.size())
	melody_staff.call("show_answer", correct, selected)
	for child in options_box.get_children():
		if child is Button:
			(child as Button).disabled = true
	feedback_label = _label("Chính xác! Nốt còn thiếu là %s." % expected if correct else "Chưa đúng. Đáp án là %s." % expected, 18, C_OK if correct else C_BAD)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_box.add_child(feedback_label)
	if melody_index + 1 >= melodies.size():
		var stars := _stars(score, maxi(1, int(challenge.get("maxScore", 500))))
		_submit_attempt(stars)
		_show_result("Giai điệu hoàn thành!", "Đáp án của bạn: %s · Đáp án đúng: %s" % [selected, expected], score, stars, _restart, 100.0 if correct else 0.0)
		return
	next_button = _button("Giai điệu tiếp theo →", 250, 52, C_NAVY)
	next_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	next_button.pressed.connect(func() -> void:
		melody_index += 1
		next_button = null
		_show_round()
	)
	content_box.add_child(next_button)

func _note_equal(left: String, right: String) -> bool:
	return left.to_lower().replace("đ", "d").replace("ô", "o").strip_edges() == right.to_lower().replace("đ", "d").replace("ô", "o").strip_edges()

func _restart() -> void:
	melody_index = 0
	score = 0
	next_button = null
	_show_round()

func _submit_attempt(stars: int) -> void:
	var report := _report()
	if report != null and challenge_id > 0:
		await report.report_minigame_by_id(challenge_id, score, stars, started_at, _now_iso())

func _play_reference_audio() -> void:
	if not reference_audio_url.is_empty():
		_download_and_play_reference()
	else:
		_play_melody_fallback(melodies[melody_index % melodies.size()]["notes"])

func _download_and_play_reference() -> void:
	var request := HTTPRequest.new()
	add_child(request)
	var error := request.request(reference_audio_url)
	if error != OK:
		request.queue_free()
		return
	var response: Array = await request.request_completed
	request.queue_free()
	if response.size() < 4 or int(response[1]) < 200 or int(response[1]) >= 300:
		return
	var body: PackedByteArray = response[3]
	var stream: AudioStream = _audio_stream_from_buffer(body, reference_audio_url)
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
	for note: Variant in notes:
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
	var root := note.to_lower().replace("đô", "do").replace("đố", "do").replace("đồ", "do")
	if root.begins_with("do"): return 261.63
	if root.begins_with("rê") or root.begins_with("re"): return 293.66
	if root.begins_with("mi"): return 329.63
	if root.begins_with("fa"): return 349.23
	if root.begins_with("sol"): return 392.0
	if root.begins_with("la"): return 440.0
	return 493.88
