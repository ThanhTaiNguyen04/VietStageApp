extends SceneTree

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("--- Running Minigame Contract & Screens Test ---")
	_test_rhythm_contract()
	_test_melody_contract()
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
				"bpm": 90,
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

	melody_screen.free()

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
