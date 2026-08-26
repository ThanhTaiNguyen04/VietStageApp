extends "res://scripts/LearningActivityBase.gd"

var challenge: Dictionary = {}
var challenge_id := 0
var lesson_id := 0
var melodies: Array = []
var melody_index := 0
var score := 0
var api_stars_earned := 0
var started_at := ""
var melody_staff: Control
var options_box: Container
var feedback_label: Label
var next_button: Button
var listen_button: Button
var reference_audio_url := ""
var audio_player: AudioStreamPlayer
var progress_bar: ProgressBar
var score_label: Label
var floating_back_button: Button

func _ready() -> void:
	super._ready()
	
	# Hide the inherited top panel navbar to match the Quiz screen
	var top_panel = root_box.get_child(0)
	if top_panel:
		top_panel.visible = false
		
	# Build the sticky progress bar and circular back button
	_build_sticky_progress_bar()
	
	title_label.text = "MINI-GAME 2 - HOÀN THIỆN GIAI ĐIỆU"
	_load_challenge()

func _load_challenge() -> void:
	var debug_lines: Array[String] = []
	debug_lines.append("=== MINIGAME DEBUG START ===")
	
	var report := _report()
	debug_lines.append("Report node exists: %s" % str(report != null))
	if report != null:
		debug_lines.append("Is signed in: %s" % str(report.is_signed_in()))
		
	debug_lines.append("Context.instrument: %s" % str(Context.instrument))
	debug_lines.append("Context.local_lesson_ids: %s" % str(Context.local_lesson_ids))
	debug_lines.append("be_catalog size: %d" % SecureDataManager.be_catalog.size())
	
	var target_challenges: Array = []
	
	if report != null and report.is_signed_in():
		result_sync_status = "be"
		if SecureDataManager.be_catalog.is_empty():
			debug_lines.append("be_catalog is empty, fetching...")
			await report.fetch_and_install_catalog()
			debug_lines.append("be_catalog size after fetch: %d" % SecureDataManager.be_catalog.size())
			
		for local_id: String in Context.local_lesson_ids:
			var lesson := SecureDataManager.resolve_be_lesson(Context.instrument, local_id)
			debug_lines.append("Resolved lesson for local_id %s: %s" % [local_id, str(lesson)])
			if lesson.is_empty():
				continue
			lesson_id = _safe_int(lesson.get("id", 0))
			debug_lines.append("Lesson ID: %d" % lesson_id)
			
			var minigames: Array = await report.ensure_minigame_list(lesson_id)
			debug_lines.append("Raw minigames list for lesson_id %d: %s" % [lesson_id, str(minigames)])
			
			for item: Variant in minigames:
				if item is Dictionary:
					var actual := str(item.get("challengeType", item.get("challenge_type", ""))).to_upper().replace("-", "_").replace(" ", "_")
					if actual in ["MELODY_COMPLETION", "MELODY_COMPLETE"]:
						target_challenges.append(item)
			break
			
	target_challenges.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var order_a = _safe_int(a.get("orderIndex", a.get("order_index", 0)))
		var order_b = _safe_int(b.get("orderIndex", b.get("order_index", 0)))
		return order_a < order_b
	)
	
	debug_lines.append("Target challenges count: %d" % target_challenges.size())
	debug_lines.append("=== MINIGAME DEBUG END ===")
	
	# Write debug log to disk
	var file := FileAccess.open("user://debug_minigame.txt", FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(debug_lines))
		file.close()

	_parse_challenges(target_challenges)
	_show_round()

func _parse_challenges(challenges: Array) -> void:
	melodies.clear()
	for challenge_item: Variant in challenges:
		if not challenge_item is Dictionary:
			continue
		var parsed: Variant = _extract_json(_safe_str(challenge_item.get("contentJson", challenge_item.get("content_json", ""))))
		var source: Dictionary = parsed if parsed is Dictionary else {}
		
		# 1. Parse standard single round layout at root
		if source.has("melody") and source.get("melody") is Array:
			var notes: Array = source.get("melody", []).duplicate()
			var missing_positions: Variant = source.get("missing_positions", source.get("missing_positions", [2]))
			var missing := 2
			if missing_positions is Array and not missing_positions.is_empty():
				missing = _safe_int(missing_positions[0], 2)
				
			var correct_ans := ""
			var correct_answers = source.get("correct_answers", source.get("correctAnswers", {}))
			if correct_answers is Dictionary:
				var key_str := str(missing)
				if correct_answers.has(key_str):
					correct_ans = str(correct_answers[key_str]).strip_edges()
					
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
				"audio_url": audio_url
			})
		else:
			# 2. Parse rounds array layout
			var raw_melodies: Array = source.get("melodies", source.get("rounds", []))
			for item: Variant in raw_melodies:
				if item is Dictionary:
					var notes: Array = item.get("notes", item.get("sequence", []))
					if not notes.is_empty():
						var raw_missing = item.get("missingIndex")
						if raw_missing == null: raw_missing = item.get("missing_idx")
						var missing := _safe_int(raw_missing, -1)
						if missing < 0:
							missing = maxi(0, int(notes.size() / 2))
							
						var audio_url := _get_challenge_audio(challenge_item, item)
						
						melodies.append({
							"notes": notes,
							"missing": missing,
							"options": item.get("options", []),
							"challenge_id": _safe_int(challenge_item.get("id", 0)),
							"max_score": _safe_int(challenge_item.get("maxScore", challenge_item.get("max_score", 100)), 100),
							"audio_url": audio_url
						})
						
	if melodies.is_empty():
		melodies.append({
			"notes": ["Đô", "Rê", "Mi", "Sol", "La"],
			"missing": 2,
			"options": [],
			"challenge_id": 0,
			"max_score": 100,
			"audio_url": ""
		})

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

func _show_round() -> void:
	for child in content_box.get_children():
		child.queue_free()
	
	var melody: Dictionary = melodies[melody_index % melodies.size()]
	reference_audio_url = str(melody.get("audio_url", ""))
	
	# Update progress bar value (matching Quiz style)
	if progress_bar and melodies.size() > 0:
		progress_bar.value = (float(melody_index) / float(melodies.size())) * 100.0
	
	# 1. Minimalist transparent status bar above the card (identical to Quiz style)
	var status_bar := PanelContainer.new()
	status_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb_style := StyleBoxFlat.new()
	sb_style.bg_color = Color(1, 1, 1, 0.45) # transparent white
	sb_style.set_corner_radius_all(12)
	sb_style.set_border_width_all(1)
	sb_style.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.15)
	sb_style.content_margin_left = 12
	sb_style.content_margin_right = 12
	sb_style.content_margin_top = 8
	sb_style.content_margin_bottom = 8
	status_bar.add_theme_stylebox_override("panel", sb_style)
	content_box.add_child(status_bar)

	var status_hbox := HBoxContainer.new()
	status_bar.add_child(status_hbox)

	var status_spacer := Control.new()
	status_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_hbox.add_child(status_spacer)

	# Score Pill (Double size, gamified Duolingo style, identical to Quiz)
	var score_pill := PanelContainer.new()
	var s_style := StyleBoxFlat.new()
	s_style.bg_color = Color("#edf3ec") # jade bg
	s_style.border_color = Color("#2e7d32")
	s_style.set_border_width_all(2)
	s_style.set_corner_radius_all(16)
	s_style.content_margin_left = 20
	s_style.content_margin_right = 20
	s_style.content_margin_top = 8
	s_style.content_margin_bottom = 8
	score_pill.add_theme_stylebox_override("panel", s_style)
	status_hbox.add_child(score_pill)

	var s_hbox := HBoxContainer.new()
	s_hbox.add_theme_constant_override("separation", 8)
	score_pill.add_child(s_hbox)

	var s_icon := TextureRect.new()
	s_icon.texture = load("res://assets/textures/lucide/trophy.svg") as Texture2D
	s_icon.custom_minimum_size = Vector2(26, 26)
	s_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	s_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	s_icon.modulate = Color("#e7ae22") # Gold trophy icon
	s_hbox.add_child(s_icon)

	score_label = Label.new()
	score_label.text = str(score)
	score_label.add_theme_font_override("font", load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font)
	score_label.add_theme_font_size_override("font_size", 22)
	score_label.add_theme_color_override("font_color", Color("#1b5e20"))
	s_hbox.add_child(score_label)

	# 2. Main card (sand/gold frosted border like Quiz card)
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sheet_style := StyleBoxFlat.new()
	sheet_style.bg_color = Color(0.995, 0.99, 0.985, 0.95)
	sheet_style.set_corner_radius_all(20)
	sheet_style.set_border_width_all(2)
	sheet_style.border_color = Color("#e2d8c9")
	sheet_style.shadow_color = Color(0.08, 0.07, 0.05, 0.06)
	sheet_style.shadow_size = 8
	sheet_style.shadow_offset = Vector2(0, 4)
	sheet_style.content_margin_left = 24
	sheet_style.content_margin_right = 24
	sheet_style.content_margin_top = 24
	sheet_style.content_margin_bottom = 24
	card.add_theme_stylebox_override("panel", sheet_style)
	content_box.add_child(card)
	
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 20)
	card.add_child(body)
	
	# 3. Prompt Row: Centered heading + Right Speaker/Audio Button
	var prompt_row := HBoxContainer.new()
	prompt_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(prompt_row)
	
	var heading_spacer_l := Control.new()
	heading_spacer_l.custom_minimum_size = Vector2(48, 0)
	prompt_row.add_child(heading_spacer_l)
	
	var heading := _label("Nghe giai điệu rồi chọn nốt còn thiếu", 22 if get_viewport_rect().size.x < 600.0 else 26, C_NAVY)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_override("font", load("res://assets/fonts/Lora-Bold.ttf") as Font)
	prompt_row.add_child(heading)
	
	# Audio button at the top-right of the card (identical to Quiz style)
	listen_button = Button.new()
	listen_button.custom_minimum_size = Vector2(48, 48)
	listen_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	listen_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	listen_button.icon = load("res://assets/textures/lucide/volume-2.svg") as Texture2D
	listen_button.expand_icon = true
	listen_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	listen_button.add_theme_constant_override("icon_max_width", 24)
	
	var btn_style_n := StyleBoxFlat.new()
	btn_style_n.bg_color = Color.WHITE
	btn_style_n.border_color = Color("#cbd5e1")
	btn_style_n.set_border_width_all(2)
	btn_style_n.border_width_bottom = 4
	btn_style_n.set_corner_radius_all(24)
	
	var btn_style_h := btn_style_n.duplicate() as StyleBoxFlat
	btn_style_h.bg_color = Color("#f8fafc")
	
	var btn_style_p := btn_style_n.duplicate() as StyleBoxFlat
	btn_style_p.bg_color = Color("#f1f5f9")
	btn_style_p.border_width_top = 3
	btn_style_p.border_width_bottom = 1
	
	listen_button.add_theme_stylebox_override("normal", btn_style_n)
	listen_button.add_theme_stylebox_override("hover", btn_style_h)
	listen_button.add_theme_stylebox_override("pressed", btn_style_p)
	listen_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	listen_button.add_theme_color_override("icon_normal_color", C_NAVY)
	
	listen_button.pivot_offset = Vector2(24, 24)
	listen_button.mouse_entered.connect(func() -> void:
		create_tween().tween_property(listen_button, "scale", Vector2(1.08, 1.08), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	listen_button.mouse_exited.connect(func() -> void:
		create_tween().tween_property(listen_button, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	listen_button.pressed.connect(_play_reference_audio)
	prompt_row.add_child(listen_button)
	
	# 4. Staff Display (Larger size 260px)
	melody_staff = Control.new()
	melody_staff.set_script(load("res://scripts/LearningMelodyStaffDisplay.gd"))
	melody_staff.custom_minimum_size = Vector2(0, 260)
	melody_staff.call("configure", melody["notes"], int(melody["missing"]))
	body.add_child(melody_staff)
	
	# 5. Options Box styled in 2x2 GridContainer (identical to Quiz style)
	var options_grid := GridContainer.new()
	options_grid.columns = 2
	options_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options_grid.add_theme_constant_override("h_separation", 16)
	options_grid.add_theme_constant_override("v_separation", 16)
	body.add_child(options_grid)
	
	options_box = options_grid # compatibility reference
	
	var choices: Array = melody["options"]
	if choices.is_empty():
		choices = ["Đô", "Rê", "Mi", "Sol", "La"]
		
	for i in range(choices.size()):
		var choice = choices[i]
		var option_btn := _create_premium_option_button(i, str(choice))
		option_btn.pressed.connect(func() -> void: 
			_answer(option_btn, i, str(choice), str(melody["notes"][int(melody["missing"])]), melody, options_grid)
		)
		options_grid.add_child(option_btn)
		
	started_at = _now_iso()

func _answer(selected_btn: Button, selected_idx: int, selected: String, expected: String, melody: Dictionary, grid: GridContainer) -> void:
	if next_button != null and is_instance_valid(next_button):
		return
	var correct := _note_equal(selected, expected)
	var current_max := _safe_int(melody.get("max_score", 100), 100)
	
	if correct:
		score += current_max
		if score_label and is_instance_valid(score_label):
			score_label.text = str(score)
	melody_staff.call("show_answer", correct, selected)
	
	# Submit attempt for the current minigame challenge ID immediately
	var current_id := _safe_int(melody.get("challenge_id", 0))
	var report := _report()
	if report != null and current_id > 0:
		var round_score := current_max if correct else 0
		var round_stars := _stars(round_score, current_max)
		var result: Dictionary = await report.report_minigame_by_id(current_id, round_score, round_stars, started_at, _now_iso())
		if bool(result.get("submitted", false)):
			api_stars_earned += maxi(0, int(result.get("stars_earned", 0)))
	
	# Disable all option buttons and highlight correct/incorrect
	for child in grid.get_children():
		if child is Button:
			var btn := child as Button
			btn.disabled = true
			var btn_text := ""
			var lbl = btn.find_child("TextLabel", true, false) as Label
			if lbl:
				btn_text = lbl.text
			if _note_equal(btn_text, expected):
				_style_option_button_state(btn, "correct")
			elif btn == selected_btn and not correct:
				_style_option_button_state(btn, "incorrect")
				
	feedback_label = _label("Chính xác! Nốt còn thiếu là %s." % expected if correct else "Chưa đúng. Đáp án là %s." % expected, 18, C_OK if correct else C_BAD)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_box.add_child(feedback_label)
	
	if melody_index + 1 >= melodies.size():
		if progress_bar:
			progress_bar.value = 100.0
		if report != null and report.is_signed_in():
			await report.refresh_progress_from_backend()
		var stars := clampi(api_stars_earned, 0, 3)
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

func _create_premium_option_button(index: int, text_value: String) -> Button:
	var btn_height := 72.0
	var font_size_option := 18
	var badge_size := Vector2(42, 42)
	var badge_font_size := 16
	var badge_radius := 21

	var button := Button.new()
	button.custom_minimum_size = Vector2(0, btn_height)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	# Normal state (3D border bottom 5px)
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color.WHITE
	normal_style.border_color = Color("#cbd5e1") # slate-300
	normal_style.set_border_width_all(2)
	normal_style.border_width_bottom = 5
	normal_style.set_corner_radius_all(18)
	button.add_theme_stylebox_override("normal", normal_style)

	# Hover state
	var hover_style := normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color("#f8fafc") # slate-50
	hover_style.border_color = Color("#94a3b8") # slate-400
	button.add_theme_stylebox_override("hover", hover_style)

	# Pressed state
	var pressed_style := normal_style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color("#f1f5f9") # slate-100
	pressed_style.border_color = Color("#64748b") # slate-500
	pressed_style.border_width_top = 4
	pressed_style.border_width_bottom = 2
	button.add_theme_stylebox_override("pressed", pressed_style)

	# Disabled state default
	var disabled_style := normal_style.duplicate() as StyleBoxFlat
	button.add_theme_stylebox_override("disabled", disabled_style)

	# Internal layout container
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(hbox)

	# Circle badge container for letter (A, B, C, D)
	var badge_panel := PanelContainer.new()
	badge_panel.name = "Badge"
	badge_panel.custom_minimum_size = badge_size
	badge_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color("#f1f5f9")
	badge_style.border_color = Color("#cbd5e1")
	badge_style.set_border_width_all(1)
	badge_style.set_corner_radius_all(badge_radius) # circular
	badge_panel.add_theme_stylebox_override("panel", badge_style)

	var badge_label := Label.new()
	badge_label.text = char(65 + index)
	badge_label.add_theme_font_override("font", load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font)
	badge_label.add_theme_font_size_override("font_size", badge_font_size)
	badge_label.add_theme_color_override("font_color", C_NAVY)
	badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge_panel.add_child(badge_label)
	hbox.add_child(badge_panel)

	# Answer text label
	var text_label := Label.new()
	text_label.name = "TextLabel"
	text_label.text = text_value
	text_label.add_theme_font_override("font", load("res://assets/fonts/Nunito.ttf") as Font)
	text_label.add_theme_font_size_override("font_size", font_size_option)
	text_label.add_theme_color_override("font_color", C_TEXT)
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hbox.add_child(text_label)

	# Hover bouncy tween micro-interaction
	button.pivot_offset = Vector2(100, 32)
	button.mouse_entered.connect(func() -> void:
		if not button.disabled:
			create_tween().tween_property(button, "scale", Vector2(1.02, 1.02), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	)
	button.mouse_exited.connect(func() -> void:
		if not button.disabled:
			create_tween().tween_property(button, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	)
	button.button_down.connect(func() -> void:
		if not button.disabled:
			margin.add_theme_constant_override("margin_top", 9)
			margin.add_theme_constant_override("margin_bottom", 3)
	)
	button.button_up.connect(func() -> void:
		margin.add_theme_constant_override("margin_top", 6)
		margin.add_theme_constant_override("margin_bottom", 6)
	)

	return button

func _style_option_button_state(button: Button, state: String) -> void:
	var style := button.get_theme_stylebox("disabled") as StyleBoxFlat
	if style == null:
		style = StyleBoxFlat.new()
		style.set_corner_radius_all(16)
		style.set_border_width_all(2)
		style.border_width_bottom = 5
	else:
		style = style.duplicate() as StyleBoxFlat

	var badge_panel := button.find_child("Badge", true, false) as PanelContainer
	var text_label := button.find_child("TextLabel", true, false) as Label

	if state == "correct":
		style.bg_color = Color("#e8f5e9")
		style.border_color = Color("#4caf50")
		button.add_theme_stylebox_override("disabled", style)
		button.add_theme_color_override("font_disabled_color", Color("#2e7d32"))

		if badge_panel:
			var badge_style := badge_panel.get_theme_stylebox("panel") as StyleBoxFlat
			if badge_style:
				badge_style = badge_style.duplicate() as StyleBoxFlat
				badge_style.bg_color = Color("#4caf50")
				badge_style.border_color = Color("#2e7d32")
				badge_panel.add_theme_stylebox_override("panel", badge_style)
			var badge_label := badge_panel.get_child(0) as Label
			if badge_label:
				badge_label.add_theme_color_override("font_color", Color.WHITE)

		if text_label:
			text_label.add_theme_color_override("font_color", Color("#2e7d32"))
	elif state == "incorrect":
		style.bg_color = Color("#ffebee")
		style.border_color = Color("#ef5350")
		button.add_theme_stylebox_override("disabled", style)
		button.add_theme_color_override("font_disabled_color", Color("#c62828"))

		if badge_panel:
			var badge_style := badge_panel.get_theme_stylebox("panel") as StyleBoxFlat
			if badge_style:
				badge_style = badge_style.duplicate() as StyleBoxFlat
				badge_style.bg_color = Color("#ef5350")
				badge_style.border_color = Color("#c62828")
				badge_panel.add_theme_stylebox_override("panel", badge_style)
			var badge_label := badge_panel.get_child(0) as Label
			if badge_label:
				badge_label.add_theme_color_override("font_color", Color.WHITE)

		if text_label:
			text_label.add_theme_color_override("font_color", Color("#c62828"))

func _note_equal(left: String, right: String) -> bool:
	return left.to_lower().replace("đ", "d").replace("ô", "o").strip_edges() == right.to_lower().replace("đ", "d").replace("ô", "o").strip_edges()

func _restart() -> void:
	melody_index = 0
	score = 0
	api_stars_earned = 0
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

func _build_sticky_progress_bar() -> void:
	var mobile := get_viewport_rect().size.x < 600.0

	var progress_container := MarginContainer.new()
	progress_container.name = "MinigameProgressContainer"
	progress_container.add_theme_constant_override("margin_left", 16 if mobile else 28)
	progress_container.add_theme_constant_override("margin_right", 16 if mobile else 28)
	progress_container.add_theme_constant_override("margin_top", 12 if mobile else 16)
	progress_container.add_theme_constant_override("margin_bottom", 4)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	progress_container.add_child(hbox)

	# 1. Floating Back Button
	floating_back_button = Button.new()
	floating_back_button.custom_minimum_size = Vector2(76, 76)
	floating_back_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	floating_back_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(floating_back_button)

	floating_back_button.icon = load("res://assets/textures/lucide/arrow-left.svg") as Texture2D
	floating_back_button.expand_icon = true
	floating_back_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	floating_back_button.add_theme_constant_override("icon_max_width", 38)

	var style_n := StyleBoxFlat.new()
	style_n.bg_color = Color.WHITE
	style_n.set_corner_radius_all(38)
	style_n.border_width_bottom = 5
	style_n.border_color = Color("#cbd5e1")
	style_n.shadow_color = Color(0, 0, 0, 0.05)
	style_n.shadow_size = 4
	style_n.shadow_offset = Vector2(0, 2)

	var style_h := style_n.duplicate() as StyleBoxFlat
	style_h.bg_color = Color("#FDFCF9")

	var style_p := style_n.duplicate() as StyleBoxFlat
	style_p.bg_color = Color("#F5F0E5")
	style_p.border_width_bottom = 0

	floating_back_button.add_theme_stylebox_override("normal", style_n)
	floating_back_button.add_theme_stylebox_override("hover", style_h)
	floating_back_button.add_theme_stylebox_override("pressed", style_p)
	floating_back_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	floating_back_button.add_theme_color_override("icon_normal_color", C_NAVY)

	floating_back_button.pressed.connect(_go_back)

	floating_back_button.pivot_offset = Vector2(38, 38)
	floating_back_button.mouse_entered.connect(func() -> void:
		create_tween().tween_property(floating_back_button, "scale", Vector2(1.08, 1.08), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	floating_back_button.mouse_exited.connect(func() -> void:
		create_tween().tween_property(floating_back_button, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)

	# 2. Progress Bar
	progress_bar = ProgressBar.new()
	progress_bar.max_value = 100.0
	progress_bar.value = 0.0
	progress_bar.show_percentage = false
	progress_bar.custom_minimum_size = Vector2(0, 16 if mobile else 20)
	progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var bar_radius := 8 if mobile else 10
	progress_bar.add_theme_stylebox_override("background", _panel(Color("#e9edf5"), Color("#e9edf5"), bar_radius, 0))
	progress_bar.add_theme_stylebox_override("fill", _panel(C_BLUE, C_BLUE, bar_radius, 0))
	hbox.add_child(progress_bar)

	root_box.add_child(progress_container)
	root_box.move_child(progress_container, 1)

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
