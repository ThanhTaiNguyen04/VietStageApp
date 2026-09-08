extends SceneTree

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("--- Running Minigame Contract & Screens Test ---")
	_test_rhythm_contract()
	_test_melody_contract()
	_test_instrument_sample_player()
	_test_staff_display_playback_highlight()
	_test_melody_screen_instantiation()
	_test_rhythm_screen_instantiation()
	
	if failures == 0:
		print("[ALL MINIGAME TESTS PASSED]")
		quit(0)
	else:
		push_error("[MINIGAME TESTS FAILED] Failures: %d" % failures)
		quit(1)

func _test_rhythm_contract() -> void:
	var RhythmModel = load("res://scripts/RhythmChallengeModel.gd")
	var single_round_challenge := {
		"id": 101,
		"title": "Nhịp đơn",
		"challengeType": "RHYTHM_MATCH",
		"maxScore": 100,
		"contentJson": JSON.stringify({
			"tempo_bpm": 120,
			"beats": [1.0, 2.0, 3.0, 4.0]
		})
	}
	var parsed_single = RhythmModel.parse_challenges([single_round_challenge])
	_check(parsed_single.size() == 1, "Single round rhythm match should produce 1 item")
	if parsed_single.size() == 1:
		_check(parsed_single[0]["beats"] == [1.0, 2.0, 3.0, 4.0], "Beats must match exactly")
		_check(int(parsed_single[0]["tempo_bpm"]) == 120, "Tempo must be 120")
		_check(parsed_single[0]["submit_after"] == true, "Single round should submit_after == true")

	var multi_round_challenge := {
		"id": 102,
		"title": "Nhịp nhiều vòng",
		"challengeType": "RHYTHM_MATCH",
		"maxScore": 200,
		"contentJson": JSON.stringify({
			"rounds": [
				{"title": "Vòng 1", "tempo_bpm": 80, "beats": [0.5, 1.5]},
				{"title": "Vòng 2", "tempo_bpm": 100, "beats": [1.0, 2.0, 3.0]}
			]
		})
	}
	var parsed_multi = RhythmModel.parse_challenges([multi_round_challenge])
	_check(parsed_multi.size() == 2, "Multi round rhythm match should produce 2 items")
	if parsed_multi.size() == 2:
		_check(parsed_multi[0]["submit_after"] == false, "Round 1 should not submit_after")
		_check(parsed_multi[1]["submit_after"] == true, "Round 2 should submit_after")

func _test_melody_contract() -> void:
	var melody_screen = load("res://scripts/MelodyCompletionScreen.gd").new()
	var test_challenges = [
		{
			"id": 201,
			"title": "Điền nốt khuyết",
			"challengeType": "MELODY_COMPLETE",
			"maxScore": 100,
			"contentJson": JSON.stringify({
				"melody": ["C4", "E4", "G4", "C5"],
				"missing_positions": [2],
				"note_options": {
					"2": ["C4", "E4", "G4", "A4"]
				},
				"correct_answers": {
					"2": "G4"
				},
				"bpm": 95,
				"time_limit_sec": 30
			})
		}
	]
	
	melody_screen._parse_challenges(test_challenges)
	_check(melody_screen.melodies.size() == 1, "Melody parser should parse 1 melody round")
	if melody_screen.melodies.size() == 1:
		var item: Dictionary = melody_screen.melodies[0]
		_check(item.get("missing") == 2, "Missing position 0-based must be 2")
		_check(item.get("notes") == ["C4", "E4", "G4", "C5"], "Melody notes must match")
		_check(item.get("options") == ["C4", "E4", "G4", "A4"], "Note options must match")
		_check(item.get("challenge_id") == 201, "Challenge ID must be 201")
		_check(item.get("bpm") == 95.0, "Parsed BPM must be 95.0")
	_check(absf(melody_screen._frequency("D3") - 146.83) < 0.1, "Scientific D3 pitch must be octave-aware")
	_check(absf(melody_screen._cents_from_expected(392.0, "G4")) < 0.1, "Reference pitch must score at zero cents")

	melody_screen.free()

func _test_instrument_sample_player() -> void:
	var PlayerScript = load("res://scripts/InstrumentSamplePlayer.gd")
	var player = PlayerScript.new()
	root.add_child(player)

	# 1. Normalization checks
	# Dan Tranh
	_check(PlayerScript.normalize_note_key("dan_tranh", "C4") == "c4", "Dan Tranh: C4 -> c4")
	_check(PlayerScript.normalize_note_key("dan_tranh", "Sol1") == "g3", "Dan Tranh: Sol1 -> g3")
	_check(PlayerScript.normalize_note_key("dan_tranh", "La1") == "a3", "Dan Tranh: La1 -> a3")
	_check(PlayerScript.normalize_note_key("dan_tranh", "Đô2") == "c4", "Dan Tranh: Đô2 -> c4")
	_check(PlayerScript.normalize_note_key("dan_tranh", "ZT_Mi2") == "e4", "Dan Tranh: ZT_Mi2 -> e4")
	_check(PlayerScript.normalize_note_key("dan_tranh", "Đô3") == "c5", "Dan Tranh: Đô3 -> c5")
	_check(PlayerScript.normalize_note_key("dan_tranh", "Sol3") == "g5", "Dan Tranh: Sol3 -> g5")
	_check(PlayerScript.normalize_note_key("dan_tranh", "Đô4") == "c6", "Dan Tranh: Đô4 -> c6")

	# Sao Truc
	_check(PlayerScript.normalize_note_key("sao_truc", "C5") == "c5", "Sao Truc: C5 -> c5")
	_check(PlayerScript.normalize_note_key("sao_truc", "Đô") == "c5", "Sao Truc: Đô -> c5")
	_check(PlayerScript.normalize_note_key("sao_truc", "Đô2") == "c6", "Sao Truc: Đô2 -> c6")
	_check(PlayerScript.normalize_note_key("sao_truc", "Đô3") == "c7", "Sao Truc: Đô3 -> c7")
	_check(PlayerScript.normalize_note_key("sao_truc", "Sol1") == "g5", "Sao Truc: Sol1 -> g5")

	# Dan Bau
	_check(PlayerScript.normalize_note_key("dan_bau", "c4") == "c4", "Dan Bau: c4 -> c4")
	_check(PlayerScript.normalize_note_key("dan_bau", "sol4") == "g4", "Dan Bau: sol4 -> g4")
	_check(PlayerScript.normalize_note_key("dan_bau", "c5") == "c5", "Dan Bau: c5 -> c5")
	_check(PlayerScript.normalize_note_key("dan_bau", "mi5") == "e5", "Dan Bau: mi5 -> e5")
	_check(PlayerScript.normalize_note_key("dan_bau", "sol5") == "g5", "Dan Bau: sol5 -> g5")
	_check(PlayerScript.normalize_note_key("dan_bau", "c6") == "c6", "Dan Bau: c6 -> c6")

	# 2. Preflight and WAV asset checking
	var check_tranh = player.preflight("dan_tranh", ["Sol1", "La1", "Đô2", "Rê2", "Mi2"], 2)
	_check(check_tranh.get("ok") == true, "Dan Tranh preflight should pass with packaged assets")

	var check_flute = player.preflight("sao_truc", ["C5", "D5", "E5", "G5", "C6"], 1)
	_check(check_flute.get("ok") == true, "Sao Truc preflight should pass with packaged assets")

	var check_bau = player.preflight("dan_bau", ["c4", "g4", "c5", "e5", "g5", "c6"], 3)
	_check(check_bau.get("ok") == true, "Dan Bau preflight should pass with packaged assets")

	# 3. Missing index skipping check: invalid note at missing index must NOT fail preflight
	var check_skip = player.preflight("dan_tranh", ["C4", "E4", "INVALID_NOTE_XYZ", "G4"], 2)
	_check(check_skip.get("ok") == true, "Preflight must ignore invalid note at missing_index (index 2)")

	# 4. Strict error reporting when missing required note (NO synthesis fallback)
	var check_missing = player.preflight("dan_tranh", ["C4", "UNKNOWN_NOTE_123", "G4"], 0)
	_check(check_missing.get("ok") == false, "Preflight must fail when a required note asset is missing")
	var missing_items: Array = check_missing.get("missing", [])
	_check(missing_items.size() == 1 and missing_items[0]["note"] == "UNKNOWN_NOTE_123", "Failure details must report missing note")

	player.queue_free()

func _test_staff_display_playback_highlight() -> void:
	var StaffScript = load("res://scripts/LearningMelodyStaffDisplay.gd")
	var staff = Control.new()
	staff.set_script(StaffScript)
	staff.custom_minimum_size = Vector2(400, 200)
	staff.call("configure", ["C4", "E4", "G4", "C5"], 2)
	_check(staff.get("playback_index") == -1, "Initial playback_index must be -1")

	staff.call("set_playback_index", 1)
	_check(staff.get("playback_index") == 1, "set_playback_index(1) should update playback_index to 1")

	staff.call("set_playback_index", -1)
	_check(staff.get("playback_index") == -1, "set_playback_index(-1) should reset playback_index to -1")
	staff.free()

func _test_melody_screen_instantiation() -> void:
	var packed: PackedScene = load("res://scenes/MelodyCompletionScreen.tscn")
	_check(packed != null, "MelodyCompletionScreen.tscn must be loaded")
	if packed:
		var instance = packed.instantiate()
		root.add_child(instance)
		_check(instance != null, "MelodyCompletionScreen must instantiate cleanly")
		instance.queue_free()

func _test_rhythm_screen_instantiation() -> void:
	var packed: PackedScene = load("res://scenes/RhythmChallengeScreen.tscn")
	_check(packed != null, "RhythmChallengeScreen.tscn must be loaded")
	if packed:
		var instance = packed.instantiate()
		root.add_child(instance)
		_check(instance != null, "RhythmChallengeScreen must instantiate cleanly")
		instance.queue_free()

func _check(condition: bool, message: String) -> void:
	if condition:
		print("  [PASS] %s" % message)
	else:
		failures += 1
		push_error("  [FAIL] %s" % message)
