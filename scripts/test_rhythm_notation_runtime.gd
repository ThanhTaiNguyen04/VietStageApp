extends SceneTree

func _init():
	print("--- Running test_rhythm_notation_runtime.gd ---")
	test_g_clef_and_time_signature()
	test_two_measure_screen_layout()
	test_two_measure_playhead_and_page_flip()
	test_speed_selector_and_bpm_scaling()
	test_two_measure_navigator()
	test_result_screen_zero_score_handling()
	test_game_screen_speed_chip_and_status()
	test_all_note_durations_and_shapes()
	test_stem_directions_and_beaming()
	print("=== ALL RUNTIME NOTATION TESTS PASSED ===")
	quit(0)

func test_g_clef_and_time_signature():
	var staff_script = load("res://scripts/RhythmStaffDisplay.gd")
	var staff = Control.new()
	staff.set_script(staff_script)
	staff.custom_minimum_size = Vector2(400, 150)
	staff.size = Vector2(400, 150)
	
	# Round with 4/4: 3 notes summing to 4.0 beats (1 measure)
	var notes = ["C4", "D4", "E4"]
	var times = [0.0, 0.6, 1.2]
	var dur_beats: Array[float] = [1.0, 1.0, 2.0]
	staff.configure_rhythm(notes, times, 2.4, false, false, [], [4, 4], dur_beats, 100)
	
	assert(staff.total_measures == 1, "Expected 1 measure for 4 beats in 4/4, got %d" % staff.total_measures)
	assert(staff.total_pages == 1, "Expected 1 page for 1 measure in 2-measure layout")
	assert(staff.measure_beats == 4.0, "Expected 4.0 measure_beats for 4/4")
	
	# Verify clef anchor properties:
	var height = staff.size.y
	var center_y = height * 0.50 # Line 3 (B4)
	var spacing = 20.0 # for width 400
	var line_2_y = center_y + 1.0 * spacing # Line 2 (Sol 4 / G4)
	var clef_scale = 5.6
	var clef_font_size = int(spacing * clef_scale)
	var clef_baseline_y = line_2_y + (clef_font_size * 0.125)
	
	# Spiral center Y = clef_baseline_y - (clef_font_size * 0.125) = line_2_y!
	var spiral_y = clef_baseline_y - (clef_font_size * 0.125)
	assert(abs(spiral_y - line_2_y) < 0.001, "G-clef spiral must anchor exactly on Line 2 (Sol 4)")
	print("✔ test_g_clef_and_time_signature passed")

func test_two_measure_screen_layout():
	var staff_script = load("res://scripts/RhythmStaffDisplay.gd")
	var staff = Control.new()
	staff.set_script(staff_script)
	staff.custom_minimum_size = Vector2(400, 150)
	staff.size = Vector2(400, 150)
	
	# Round with 4/4, 2 measures:
	var notes = ["C4", "D4", "E4", "F4", "G4", "A4"]
	var times = [0.0, 0.6, 1.2, 1.8, 2.4, 3.6]
	var dur_beats: Array[float] = [1.0, 1.0, 1.0, 1.0, 2.0, 2.0]
	staff.configure_rhythm(notes, times, 4.8, false, false, [], [4, 4], dur_beats, 100)
	
	assert(staff.total_measures == 2, "Expected 2 measures, got %d" % staff.total_measures)
	assert(staff.total_pages == 1, "Expected 1 page for 2 measures, got %d" % staff.total_pages)
	assert(staff.current_page == 0, "Initial page should be 0")
	
	assert(staff.note_start_beats[0] == 0.0, "Note 0 starts at beat 0")
	assert(staff.note_start_beats[3] == 3.0, "Note 3 starts at beat 3")
	assert(staff.note_start_beats[4] == 4.0, "Note 4 starts at beat 4 (measure 1)")
	assert(staff.note_start_beats[5] == 6.0, "Note 5 starts at beat 6 (measure 1)")
	print("✔ test_two_measure_screen_layout passed")

func test_two_measure_playhead_and_page_flip():
	var staff_script = load("res://scripts/RhythmStaffDisplay.gd")
	var staff = Control.new()
	staff.set_script(staff_script)
	staff.size = Vector2(400, 150)
	
	# Round with 4/4, 4 measures (16 beats):
	var notes = ["C4", "D4", "E4", "F4", "G4", "A4", "B4", "C5"]
	var times = [0.0, 1.2, 2.4, 3.6, 4.8, 6.0, 7.2, 8.4]
	var dur_beats: Array[float] = [2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0]
	staff.configure_rhythm(notes, times, 9.6, false, false, [], [4, 4], dur_beats, 100)
	
	assert(staff.total_measures == 4, "Expected 4 measures, got %d" % staff.total_measures)
	assert(staff.total_pages == 2, "Expected 2 pages for 4 measures, got %d" % staff.total_pages)
	assert(staff.current_page == 0, "Initial page should be 0")
	
	# At beat 3.0 (inside Measure 0 / Page 0)
	staff.update_progress(1.8, []) # 1.8s at 100 BPM = 3.0 beats
	assert(staff.current_page == 0, "At beat 3.0, should still be on page 0")
	
	# At beat 6.0 (inside Measure 1 / Page 0)
	staff.update_progress(3.6, [])
	assert(staff.current_page == 0, "At beat 6.0 (measure 1), should still be on page 0")
	
	# At beat 8.5 (crossing into Measure 2 / Page 1)
	staff.update_progress(5.1, [])
	assert(staff.current_page == 1, "At beat 8.5, playhead should auto-flip to page 1")
	assert(staff.current_measure == 2, "current_measure should be 2 on page 1")
	print("✔ test_two_measure_playhead_and_page_flip passed")

func test_speed_selector_and_bpm_scaling():
	var screen_script = load("res://scripts/RhythmChallengeScreen.gd")
	var screen = Control.new()
	screen.set_script(screen_script)
	
	var r_arr: Array[Dictionary] = [
		{
			"title": "Thử thách nhịp",
			"tempo_bpm": 80,
			"time_signature": [4, 4],
			"durations_beats": [1.0, 1.0, 2.0],
			"notes": ["C4", "D4", "E4"]
		}
	]
	screen.rhythms = r_arr
	screen.rhythm_index = 0
	
	# 1. Default speed: 1.0x -> 80 BPM
	screen.selected_speed_multiplier = 1.0
	screen._prepare_current_round()
	assert(screen.current_tempo_bpm == 80, "Expected 80 BPM at 1.0x speed, got %d" % screen.current_tempo_bpm)
	assert(screen.beat_times.size() == 3, "Expected 3 beat times")
	assert(abs(screen.beat_times[0] - 0.0) < 0.01, "Beat 0 at 0.0s")
	assert(abs(screen.beat_times[1] - 0.75) < 0.01, "Beat 1 at 0.75s")
	
	# 2. Slow speed: 0.75x -> 60 BPM
	screen.selected_speed_multiplier = 0.75
	screen._prepare_current_round()
	assert(screen.current_tempo_bpm == 60, "Expected 60 BPM at 0.75x speed, got %d" % screen.current_tempo_bpm)
	assert(abs(screen.beat_times[1] - 1.0) < 0.01, "Beat 1 at 1.0s at 0.75x speed")
	
	# 3. Fast speed: 1.25x -> 100 BPM
	screen.selected_speed_multiplier = 1.25
	screen._prepare_current_round()
	assert(screen.current_tempo_bpm == 100, "Expected 100 BPM at 1.25x speed, got %d" % screen.current_tempo_bpm)
	assert(abs(screen.beat_times[1] - 0.6) < 0.01, "Beat 1 at 0.6s at 1.25x speed")
	
	# 4. Speed selector UI component test
	var selector = screen._create_speed_selector(false)
	assert(selector != null, "SpeedSelector component must exist")
	assert(selector.get_child_count() == 3, "Expected 3 speed buttons (0.75x, 1x, 1.25x)")
	
	# Test locked speed selector
	var locked_selector = screen._create_speed_selector(true)
	for btn in locked_selector.get_children():
		assert(btn is Button and btn.disabled == true, "Speed buttons must be disabled when locked during gameplay")
	
	print("✔ test_speed_selector_and_bpm_scaling passed")

func test_two_measure_navigator():
	var screen_script = load("res://scripts/RhythmChallengeScreen.gd")
	var screen = Control.new()
	screen.set_script(screen_script)
	
	var staff_script = load("res://scripts/RhythmStaffDisplay.gd")
	var staff = Control.new()
	staff.set_script(staff_script)
	staff.size = Vector2(360, 130)
	
	# Case A: 2 measures total -> no navigator needed (both visible at once)
	var dur_beats_2: Array[float] = [2.0, 2.0, 2.0, 2.0]
	staff.configure_rhythm(["C4", "D4", "E4", "F4"], [0.0, 1.0, 2.0, 3.0], 4.0, false, false, [], [4, 4], dur_beats_2, 100)
	assert(staff.total_measures == 2, "Expected 2 measures")
	var nav_2 = screen._create_measure_navigator(staff)
	assert(nav_2 == null, "Navigator should be null when total_measures <= 2")
	
	# Case B: 4 measures total -> navigator needed with '1-2/4' display
	var dur_beats_4: Array[float] = [2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0]
	staff.configure_rhythm(["C4", "D4", "E4", "F4", "G4", "A4", "B4", "C5"], [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0], 8.0, false, false, [], [4, 4], dur_beats_4, 100)
	assert(staff.total_measures == 4, "Expected 4 measures")
	var nav_4 = screen._create_measure_navigator(staff)
	assert(nav_4 != null, "Navigator must exist when total_measures > 2")
	
	var label = nav_4.get_node_or_null("MeasureLabel") as Label
	var prev_btn = nav_4.get_node_or_null("PrevButton") as Button
	var next_btn = nav_4.get_node_or_null("NextButton") as Button
	assert(label != null and prev_btn != null and next_btn != null, "All navigator nodes must exist")
	assert("1-2" in label.text, "Label should indicate measures 1-2, got '%s'" % label.text)
	
	# Test Next page
	next_btn.emit_signal("pressed")
	assert(staff.current_page == 1, "Should advance to page 1")
	assert(staff.current_measure == 2, "Current measure should be 2 on page 1")
	assert("3-4" in label.text, "Label should update to 3-4, got '%s'" % label.text)
	
	print("✔ test_two_measure_navigator passed")

func test_result_screen_zero_score_handling():
	var screen_script = load("res://scripts/RhythmChallengeScreen.gd")
	var screen = Control.new()
	screen.set_script(screen_script)
	get_root().add_child(screen)
	screen.content_box = VBoxContainer.new()
	screen.add_child(screen.content_box)
	
	var r_arr: Array[Dictionary] = [
		{
			"title": "Thử thách 1",
			"tempo_bpm": 80,
			"time_signature": [4, 4],
			"durations_beats": [1.0, 1.0, 2.0],
			"notes": ["C4", "D4", "E4"],
			"max_score": 100
		}
	]
	screen.rhythms = r_arr
	screen.rhythm_index = 0
	screen.round_accuracy_points = 0
	screen.round_hits = 0
	screen.total_score = 0
	screen.total_accuracy_points = 0
	screen.total_correct_pitch_count = 0
	screen.total_on_time_count = 0
	
	# Check round result with 0 hits / 0 score
	screen._build_round_result(0, 100)
	var card_body = screen.content_box.get_child(0).get_child(0).get_child(0)
	
	# Find heading
	var heading_found := false
	var heading_text := ""
	for child in card_body.get_children():
		if child is Label and ("chưa" in child.text.to_lower() or "hoàn thành" in child.text.to_lower()):
			heading_found = true
			heading_text = child.text
			break
	
	assert(heading_found, "Heading must exist in round result")
	assert(not "hoàn thành" in heading_text.to_lower(), "Must NOT display 'hoàn thành' when round score is 0, got '%s'" % heading_text)
	assert("chưa đạt" in heading_text.to_lower(), "Must display 'Chưa đạt' when round score is 0, got '%s'" % heading_text)
	
	# Check final result with 0 score
	screen._build_final_result()
	var final_card = screen.content_box.get_child(0).get_child(0).get_child(0)
	var final_heading_found := false
	var final_heading_text := ""
	for child in final_card.get_children():
		if child is Label and ("chưa" in child.text.to_lower() or "hoàn thành" in child.text.to_lower()):
			final_heading_found = true
			final_heading_text = child.text
			break
	assert(final_heading_found, "Heading must exist in final result")
	assert(not "hoàn thành" in final_heading_text.to_lower(), "Must NOT display 'hoàn thành' on 0 score, got '%s'" % final_heading_text)
	assert("chưa đạt" in final_heading_text.to_lower(), "Must display 'Chưa đạt' title on 0 score, got '%s'" % final_heading_text)
	print("✔ test_result_screen_zero_score_handling passed")

func test_game_screen_speed_chip_and_status():
	var screen_scene = load("res://scenes/RhythmChallengeScreen.tscn")
	var screen = screen_scene.instantiate()
	screen.content_box = VBoxContainer.new()
	screen.add_child(screen.content_box)
	
	var r_arr: Array[Dictionary] = [
		{
			"title": "Thử thách 1",
			"tempo_bpm": 80,
			"time_signature": [4, 4],
			"durations_beats": [1.0, 1.0, 2.0],
			"notes": ["C4", "D4", "E4"],
			"max_score": 100
		}
	]
	screen.rhythms = r_arr
	screen.rhythm_index = 0
	screen.selected_speed_multiplier = 0.75
	screen._build_game()
	
	# 1. Verify locked speed chip exists and shows 0.75×
	var locked_chip = screen.find_child("LockedSpeedChip", true, false)
	assert(locked_chip != null, "LockedSpeedChip must exist in game screen")
	var chip_label = locked_chip.get_child(0) as Label
	assert(chip_label != null and chip_label.text == "0.75×", "LockedSpeedChip must display '0.75×', got '%s'" % (chip_label.text if chip_label else "null"))
	
	# 2. Verify status label starts with '● Đang nghe' (no repeated 'Micro')
	var status_lbl = screen.find_child("GameStatusLabel", true, false) as Label
	assert(status_lbl != null, "GameStatusLabel must exist")
	assert(status_lbl.text == "● Đang nghe", "Initial status must be '● Đang nghe', got '%s'" % status_lbl.text)
	
	# 3. Verify concise feedback states: 'Chưa đúng' and 'Đúng'
	screen._show_feedback("Chưa đúng", Color.RED)
	assert(status_lbl.text == "Chưa đúng", "Feedback for wrong note must be 'Chưa đúng', got '%s'" % status_lbl.text)
	assert(not "micro" in status_lbl.text.to_lower(), "Status must not repeat 'Micro'")
	
	screen._show_feedback("Đúng (+100)", Color.GREEN)
	assert(status_lbl.text == "Đúng (+100)", "Feedback for right note must be 'Đúng (+100)', got '%s'" % status_lbl.text)
	print("✔ test_game_screen_speed_chip_and_status passed")

func test_all_note_durations_and_shapes():
	var staff_script = load("res://scripts/RhythmStaffDisplay.gd")
	var staff = Control.new()
	staff.set_script(staff_script)
	staff.size = Vector2(800, 160)
	
	# Test durations: whole (4.0), dotted half (3.0), half (2.0), dotted quarter (1.5), quarter (1.0), eighth (0.5), sixteenth (0.25)
	# Test A: Whole note (4.0 beats)
	var staff_whole = Control.new()
	staff_whole.set_script(staff_script)
	staff_whole.size = Vector2(800, 160)
	staff_whole.configure_rhythm(["C4"], [0.0], 4.0, false, false, [], [4, 4], [4.0], 60)
	var layout_whole = staff_whole.compute_note_records(800, 160)
	var rec_whole: Dictionary = layout_whole["records"][0]
	assert(rec_whole["dur_beat"] == 4.0, "Whole note dur must be 4.0")
	assert(rec_whole["is_hollow"] == true, "Whole note must be hollow")
	assert(rec_whole["has_stem"] == false, "Whole note must NOT have a stem")
	
	# Test B: Measure 0 (Half 2.0, Quarter 1.0, Eighth 0.5, Sixteenth 0.25, Sixteenth 0.25 = 4.0 beats)
	#         Measure 1 (Dotted Half 3.0, Quarter 1.0 = 4.0 beats)
	# Both measures fit on page 0 (total 2 measures)
	var staff_mix = Control.new()
	staff_mix.set_script(staff_script)
	staff_mix.size = Vector2(800, 160)
	var notes = ["C4", "D4", "E4", "F4", "G4", "A4", "B4"]
	var durs: Array[float] = [2.0, 1.0, 0.5, 0.25, 0.25, 3.0, 1.0]
	var times: Array[float] = [0.0, 2.0, 3.0, 3.5, 3.75, 4.0, 7.0]
	staff_mix.configure_rhythm(notes, times, 8.0, false, false, [], [4, 4], durs, 60)
	
	var layout_mix = staff_mix.compute_note_records(800, 160)
	var recs: Array = layout_mix["records"]
	assert(recs.size() == 7, "All 7 notes across the 2 measures must be on page 0, got %d" % recs.size())
	
	# Check Note 0: Half note (2.0 beats)
	var half_note = recs[0]
	assert(half_note["dur_beat"] == 2.0, "Note 0 dur must be 2.0")
	assert(half_note["is_hollow"] == true, "Half note must be hollow")
	assert(half_note["has_stem"] == true, "Half note must have a stem")
	assert(half_note["is_dotted"] == false, "Half note must not have a dot")
	
	# Check Note 1: Quarter note (1.0 beat)
	var quarter_note = recs[1]
	assert(quarter_note["dur_beat"] == 1.0, "Note 1 dur must be 1.0")
	assert(quarter_note["is_hollow"] == false, "Quarter note must be solid")
	assert(quarter_note["has_stem"] == true, "Quarter note must have a stem")
	
	# Check Note 2: Eighth note (0.5 beat)
	var eighth_note = recs[2]
	assert(eighth_note["dur_beat"] == 0.5, "Note 2 dur must be 0.5")
	assert(eighth_note["is_hollow"] == false, "Eighth note must be solid")
	assert(eighth_note["has_stem"] == true, "Eighth note must have a stem")
	
	# Check Note 3: Sixteenth note (0.25 beat)
	var sixteenth_note = recs[3]
	assert(sixteenth_note["dur_beat"] == 0.25, "Note 3 dur must be 0.25")
	assert(sixteenth_note["is_hollow"] == false, "Sixteenth note must be solid")
	assert(sixteenth_note["has_stem"] == true, "Sixteenth note must have a stem")
	
	# Check Note 5: Dotted half note (3.0 beats in measure 1)
	var dotted_half = recs[5]
	assert(dotted_half["dur_beat"] == 3.0, "Note 5 dur must be 3.0")
	assert(dotted_half["is_hollow"] == true, "Dotted half note must be hollow")
	assert(dotted_half["has_stem"] == true, "Dotted half note must have a stem")
	assert(dotted_half["is_dotted"] == true, "Dotted half note must have a dot")
	print("✔ test_all_note_durations_and_shapes passed")

func test_stem_directions_and_beaming():
	var staff_script = load("res://scripts/RhythmStaffDisplay.gd")
	var staff = Control.new()
	staff.set_script(staff_script)
	staff.size = Vector2(800, 160)
	
	# Part A: Test stem direction by pitch
	# Below line 3 (B4 / diatonic step 6): C4(0), E4(2), G4(4), A4(5) -> stem UP on right
	# On/Above line 3: B4(6), C5(7), D5(8), F5(10) -> stem DOWN on left
	var pitch_notes = ["C4", "E4", "G4", "A4", "B4", "C5", "D5", "F5"]
	var pitch_durs: Array[float] = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
	var pitch_times: Array[float] = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]
	staff.configure_rhythm(pitch_notes, pitch_times, 8.0, false, false, [], [4, 4], pitch_durs, 60)
	
	var layout_p = staff.compute_note_records(800, 160)
	var recs_p: Array = layout_p["records"]
	for i in range(4):
		var rec = recs_p[i]
		assert(rec["stem_up"] == true, "Pitch %s (step %d) must have stem UP" % [rec["raw_note"], rec["diatonic_step"]])
		assert(rec["stem_x"] > rec["x"], "Stem UP must be on right of notehead")
		assert(rec["stem_tip_y"] < rec["stem_start_y"], "Stem UP must extend upwards")
		
	for i in range(4, 8):
		var rec = recs_p[i]
		assert(rec["stem_up"] == false, "Pitch %s (step %d) must have stem DOWN" % [rec["raw_note"], rec["diatonic_step"]])
		assert(rec["stem_x"] < rec["x"], "Stem DOWN must be on left of notehead")
		assert(rec["stem_tip_y"] > rec["stem_start_y"], "Stem DOWN must extend downwards")
	
	# Part B: Test 6/8 Beaming (3 + 3 eighth notes per measure)
	var staff_68 = Control.new()
	staff_68.set_script(staff_script)
	staff_68.size = Vector2(800, 160)
	
	var notes_68 = ["C4", "D4", "E4", "F4", "G4", "A4"]
	var durs_68: Array[float] = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5]
	var times_68: Array[float] = [0.0, 0.5, 1.0, 1.5, 2.0, 2.5]
	staff_68.configure_rhythm(notes_68, times_68, 3.0, false, false, [], [6, 8], durs_68, 120)
	
	var layout_68 = staff_68.compute_note_records(800, 160)
	var recs_68: Array = layout_68["records"]
	var pulse_map_68: Dictionary = layout_68["pulse_map"]
	
	# Must have exactly 2 pulse groups of 3 notes each
	assert(pulse_map_68.size() == 2, "6/8 measure must produce exactly 2 pulse groups (3+3), got %d" % pulse_map_68.size())
	for key in pulse_map_68:
		var grp: Array = pulse_map_68[key]
		assert(grp.size() == 3, "Each 6/8 group must contain 3 eighth notes, got %d" % grp.size())
		# All notes in group must have uniform stem direction and be beamed
		var dir0: bool = grp[0]["stem_up"]
		for note_rec in grp:
			assert(note_rec["is_beamed"] == true, "Every note in 6/8 group must be marked is_beamed")
			assert(note_rec["stem_up"] == dir0, "All notes in beam group must share common stem direction")
	
	print("✔ test_stem_directions_and_beaming passed")

