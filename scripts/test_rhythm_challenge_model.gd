extends SceneTree

const RhythmModel = preload("res://scripts/RhythmChallengeModel.gd")

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_parser()
	_test_judgement()
	_test_scoring()
	if failures == 0:
		print("[RhythmChallengeModel] PASS")
		quit(0)
		return
	push_error("[RhythmChallengeModel] FAIL: %d assertion(s)" % failures)
	quit(1)


func _test_parser() -> void:
	var parsed := RhythmModel.parse_challenges([
		{
			"id": 42,
			"title": "Nhịp cơ bản",
			"challengeType": "RHYTHM_MATCH",
			"maxScore": 500,
			"difficulty": "BEGINNER",
			"contentJson": JSON.stringify({
				"tempoBpm": 90,
				"rounds": [
					{"beats": [1.0, 0.5, 1.0, "1.5"]},
					{"beats": [0.4, 0.8], "tempoBpm": 100},
				]
			}),
		}
	])
	_check(parsed.size() == 2, "parser phải giữ đủ hai vòng hợp lệ")
	if parsed.size() != 2:
		return
	_check(parsed[0]["beats"] == [0.5, 1.0, 1.5], "beat phải được sort và loại trùng")
	_check(int(parsed[0]["tempo_bpm"]) == 90, "vòng phải kế thừa tempo của challenge")
	_check(int(parsed[1]["tempo_bpm"]) == 100, "tempo riêng của vòng phải được ưu tiên")
	_check(not bool(parsed[0]["submit_after"]), "không submit ở vòng trung gian")
	_check(bool(parsed[1]["submit_after"]), "chỉ submit ở vòng cuối challenge")
	_check(int(parsed[1]["max_score"]) == 500, "mọi vòng phải giữ maxScore của challenge")

	_check(not bool(parsed[0]["performance_mode"]), "beats-only must stay on the legacy TAP path")
	var performance := RhythmModel.parse_challenges([{
		"contentJson": {"tempo_bpm": 80, "notes": ["C4", "D4"], "beats": [0.5, 1.0]}
	}])
	_check(performance.size() == 1 and bool(performance[0]["performance_mode"]), "ordered notes and beats must enable performance mode")
	if performance.size() == 1:
		_check(performance[0]["notes"] == ["C4", "D4"], "performance notes must retain their authored order")
	var authored_rounds := RhythmModel.parse_challenges([{
		"contentJson": {"tempo_bpm": 100, "rounds": [
			{"title": "Vòng 1", "beats": [1.0, 2.0], "notes": ["Sol1", "La1"]},
			{"title": "Vòng 2", "tempo_bpm": 120, "beats": [0.5, 1.0], "notes": ["Sol4", "La4"]}
		]}
	}])
	_check(authored_rounds.size() == 2, "payload nhiều vòng từ web phải tạo đủ round trong app")
	if authored_rounds.size() == 2:
		_check(authored_rounds[0]["notes"] == ["Sol1", "La1"] and authored_rounds[1]["notes"] == ["Sol4", "La4"], "app phải giữ đúng 17 dây đàn tranh mà tác giả đã soạn theo từng vòng")
	var event_rounds := RhythmModel.parse_challenges([{
		"contentJson": {"rounds": [{"title": "Sự kiện", "tempo_bpm": 120, "events": [
			{"note": "Sol1", "mode": "SAMPLE", "duration_beats": 1, "at_ms": 0, "duration_ms": 500},
			{"note": "La1", "mode": "TARGET", "duration_beats": 0.5, "at_ms": 500, "duration_ms": 250}
		]}]}
	}])
	_check(event_rounds.size() == 1, "payload events từ web phải tạo được một vòng")
	if event_rounds.size() == 1:
		_check(event_rounds[0]["beats"] == [0.0, 0.5], "events phải giữ đúng thời điểm đã tính từ trường độ")
		_check(event_rounds[0]["event_modes"] == ["SAMPLE", "TARGET"], "app phải phân biệt nốt nghe mẫu và nốt học viên chơi")
	var invalid_performance := RhythmModel.parse_challenges([{
		"contentJson": {"notes": ["C4", "D4"], "beats": [1.0, 0.5]}
	}])
	_check(invalid_performance.size() == 1 and not bool(invalid_performance[0]["performance_mode"]), "unordered beats must not desynchronize notes and timing")

	var invalid := RhythmModel.parse_challenges([{"contentJson": "{not-json}"}])
	_check(invalid.is_empty(), "challenge không có beat hợp lệ phải bị loại")


func _test_judgement() -> void:
	var beats: Array[float] = [0.5, 1.0]
	var states: Array[String] = ["", ""]
	var early := RhythmModel.judge_tap(0.1, beats, states)
	_check(int(early["index"]) == -1, "tap ngoài cửa sổ không được tiêu thụ beat tương lai")

	var perfect := RhythmModel.judge_tap(0.56, beats, states)
	_check(int(perfect["index"]) == 0 and perfect["judgement"] == "PERFECT", "tap trong ±80 ms phải là PERFECT")
	states[0] = "PERFECT"
	var good := RhythmModel.judge_tap(0.82, beats, states)
	_check(int(good["index"]) == 1 and good["judgement"] == "GOOD", "tap trong ±240 ms phải là GOOD")


func _test_scoring() -> void:
	_check(RhythmModel.scaled_score(270, 3, 500) == 450, "điểm phải scale đúng theo maxScore")
	_check(RhythmModel.scaled_score(500, 4, 300) == 300, "điểm phải clamp ở maxScore")
	_check(is_equal_approx(RhythmModel.accuracy_percent(170, 2), 85.0), "accuracy phải dùng cùng accuracy points")
	_check(RhythmModel.stars_for_score(450, 500) == 3, "90% phải nhận 3 sao")
	_check(RhythmModel.stars_for_score(349, 500) == 1, "dưới 70% nhưng từ 50% phải nhận 1 sao")
	_check(RhythmModel.stars_for_score(249, 500) == 0, "dưới 50% không nhận sao")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error("[RhythmChallengeModel] %s" % message)
