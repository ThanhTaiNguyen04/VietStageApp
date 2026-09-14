extends RefCounted

const PERFECT_WINDOW := 0.08
const GOOD_WINDOW := 0.24


static func default_notes_for_instrument(instrument: String, count: int) -> Array[String]:
	var result: Array[String] = []
	if count <= 0:
		return result
	var scale: Array[String] = []
	match instrument:
		"dan_tranh":
			scale = ["Đô2", "Rê2", "Mi2", "Sol2", "La2", "Đô3", "Rê3", "Mi3"]
		"dan_bau":
			scale = ["c4", "sol4", "c5", "mi5", "sol5", "c6"]
		"sao_truc":
			scale = ["Đô", "Rê", "Mi", "Fa", "Sol", "La", "Si", "Đố"]
		"trong_chau":
			scale = ["Tịch", "Cắc", "Tịch", "Cắc"]
		_:
			scale = ["Đô", "Rê", "Mi", "Sol", "La", "Đố"]
	for i in range(count):
		result.append(scale[i % scale.size()])
	return result


static func parse_challenges(challenge_items: Array, instrument: String = "") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var fallback_key := 0
	for item_value: Variant in challenge_items:
		if not item_value is Dictionary:
			continue
		var item: Dictionary = item_value
		var content := _content_dictionary(item.get("contentJson", item.get("content_json", {})))
		var raw_rounds: Array = []
		var content_rounds: Variant = content.get("rounds", [])
		if content_rounds is Array and not content_rounds.is_empty():
			raw_rounds = content_rounds
		else:
			raw_rounds = [content]

		var valid_rounds: Array[Dictionary] = []
		for round_value: Variant in raw_rounds:
			if not round_value is Dictionary:
				continue
			var round_data: Dictionary = round_value
			var inherited_tempo: Variant = content.get("tempoBpm", content.get("tempo_bpm", 0))
			var round_tempo: Variant = round_data.get("tempoBpm", round_data.get("tempo_bpm", inherited_tempo))
			var event_round := _event_round(round_data.get("events", []), _positive_int(round_tempo, 0))
			if not event_round.is_empty():
				event_round["tempo_bpm"] = _positive_int(round_tempo, 0)
				event_round["label"] = str(round_data.get("title", round_data.get("label", ""))).strip_edges()
				valid_rounds.append(event_round)
				continue
			var raw_beats: Variant = round_data.get("beats", [])
			var beats := normalize_beats(raw_beats)
			if beats.is_empty():
				continue
			var notes := normalize_notes(round_data.get("notes", round_data.get("melody", [])))
			var raw_durations: Variant = round_data.get("durations", [])
			var durations := normalize_durations(raw_durations)
			
			var performance_mode := not notes.is_empty() and notes.size() == beats.size() and _beats_are_strictly_ordered(raw_beats)
			if not performance_mode:
				if not instrument.is_empty():
					notes = default_notes_for_instrument(instrument, beats.size())
					performance_mode = true
				else:
					notes.clear()
					durations.clear()
			elif not durations.is_empty() and durations.size() != beats.size():
				durations.clear()
			valid_rounds.append({
				"beats": beats,
				"tempo_bpm": _positive_int(round_tempo, 0),
				"label": str(round_data.get("title", round_data.get("label", ""))).strip_edges(),
				"notes": notes,
				"durations": durations,
				"performance_mode": performance_mode,
				"event_modes": [],
			})
		if valid_rounds.is_empty():
			continue

		var challenge_id := _safe_int(item.get("id", item.get("challenge_id", 0)))
		var challenge_key := str(challenge_id) if challenge_id > 0 else "offline-%d" % fallback_key
		fallback_key += 1
		var title := str(item.get("title", "Thử thách nhịp điệu")).strip_edges()
		if title.is_empty():
			title = "Thử thách nhịp điệu"
		var max_score := _positive_int(item.get("maxScore", item.get("max_score", valid_rounds.size() * 100)), valid_rounds.size() * 100)
		for round_index in valid_rounds.size():
			var round_data := valid_rounds[round_index]
			result.append({
				"challenge_id": challenge_id,
				"challenge_key": challenge_key,
				"lesson_id": _safe_int(item.get("lesson_id", item.get("lessonId", 0))),
				"title": title,
				"difficulty": str(item.get("difficulty", "")).strip_edges(),
				"tempo_bpm": int(round_data.get("tempo_bpm", 0)),
				"round_label": str(round_data.get("label", "")),
				"beats": round_data["beats"],
				"notes": round_data.get("notes", []),
				"durations": round_data.get("durations", []),
				"event_modes": round_data.get("event_modes", []),
				"performance_mode": bool(round_data.get("performance_mode", false)),
				"max_score": max_score,
				"order_index": _safe_int(item.get("orderIndex", item.get("order_index", 0))),
				"round_index": round_index,
				"round_count": valid_rounds.size(),
				"submit_after": round_index == valid_rounds.size() - 1,
			})
	return result


## Converts the web editor's sequential musical events into the legacy beat lane.
## SAMPLE events stay in the timeline so the screen can trigger instrument audio,
## while TARGET events remain the events that receive learner pitch judgement.
static func _event_round(raw_events: Variant, tempo_bpm: int) -> Dictionary:
	if not raw_events is Array or raw_events.size() < 2 or tempo_bpm <= 0:
		return {}
	var beats: Array[float] = []
	var notes: Array[String] = []
	var durations: Array[float] = []
	var event_modes: Array[String] = []
	var elapsed_ms := 0.0
	for raw_event: Variant in raw_events:
		if not raw_event is Dictionary:
			return {}
		var event: Dictionary = raw_event
		var note := str(event.get("note", "")).strip_edges()
		var mode := str(event.get("mode", "")).strip_edges().to_upper()
		var duration_beats := float(event.get("duration_beats", 0.0))
		if note.is_empty() or mode not in ["SAMPLE", "TARGET"] or duration_beats <= 0.0:
			return {}
		var at_ms := float(event.get("at_ms", elapsed_ms))
		if at_ms < elapsed_ms - 0.5:
			return {}
		var duration_ms := float(event.get("duration_ms", duration_beats * 60000.0 / float(tempo_bpm)))
		if duration_ms <= 0.0:
			return {}
		beats.append(at_ms / 1000.0)
		notes.append(note)
		durations.append(duration_ms / 1000.0)
		event_modes.append(mode)
		elapsed_ms = at_ms + duration_ms
	if not event_modes.has("TARGET"):
		return {}
	return {"beats": beats, "notes": notes, "durations": durations, "event_modes": event_modes, "performance_mode": true}


static func normalize_durations(raw_durations: Variant) -> Array[float]:
	var result: Array[float] = []
	if not raw_durations is Array:
		return result
	for raw_value: Variant in raw_durations:
		if not raw_value is int and not raw_value is float and not raw_value is String:
			continue
		var text := str(raw_value).strip_edges()
		if text.is_empty() or not text.is_valid_float():
			continue
		var val := float(text)
		if val <= 0.0 or is_nan(val) or is_inf(val):
			continue
		result.append(val)
	return result


static func normalize_beats(raw_beats: Variant) -> Array[float]:
	var result: Array[float] = []
	if not raw_beats is Array:
		return result
	for raw_value: Variant in raw_beats:
		if not raw_value is int and not raw_value is float and not raw_value is String:
			continue
		var text := str(raw_value).strip_edges()
		if text.is_empty() or not text.is_valid_float():
			continue
		var beat := float(text)
		if beat < 0.0 or is_nan(beat) or is_inf(beat):
			continue
		result.append(beat)
	result.sort()
	var unique: Array[float] = []
	for beat: float in result:
		if unique.is_empty() or absf(beat - unique[-1]) > 0.001:
			unique.append(beat)
	return unique

static func normalize_notes(raw_notes: Variant) -> Array[String]:
	var result: Array[String] = []
	if not raw_notes is Array:
		return result
	for raw_note: Variant in raw_notes:
		var note := str(raw_note).strip_edges()
		if note.is_empty():
			return []
		result.append(note)
	return result


static func _beats_are_strictly_ordered(raw_beats: Variant) -> bool:
	if not raw_beats is Array or raw_beats.is_empty():
		return false
	var previous := -1.0
	for raw_value: Variant in raw_beats:
		var text := str(raw_value).strip_edges()
		if text.is_empty() or not text.is_valid_float():
			return false
		var beat := float(text)
		if beat < 0.0 or is_nan(beat) or is_inf(beat) or beat <= previous:
			return false
		previous = beat
	return true


static func judge_tap(elapsed: float, beats: Array[float], judgements: Array[String], perfect_window: float = PERFECT_WINDOW, good_window: float = GOOD_WINDOW) -> Dictionary:
	var closest_index := -1
	var closest_diff := INF
	for index in beats.size():
		if index < judgements.size() and not judgements[index].is_empty():
			continue
		var difference := absf(elapsed - beats[index])
		if difference < closest_diff:
			closest_index = index
			closest_diff = difference
	if closest_index < 0 or closest_diff > good_window:
		return {"index": -1, "judgement": "", "points": 0, "difference": closest_diff}
	var judgement := "PERFECT" if closest_diff <= perfect_window else "GOOD"
	return {
		"index": closest_index,
		"judgement": judgement,
		"points": 100 if judgement == "PERFECT" else 70,
		"difference": closest_diff,
	}


static func judge_performance_note(elapsed: float, beats: Array[float], judgements: Array[String], is_pitch_correct: bool, perfect_window: float = PERFECT_WINDOW, good_window: float = GOOD_WINDOW) -> Dictionary:
	var closest_index := -1
	var closest_diff := INF
	for index in beats.size():
		if index < judgements.size() and not judgements[index].is_empty():
			continue
		var difference := absf(elapsed - beats[index])
		if difference < closest_diff:
			closest_index = index
			closest_diff = difference
	if closest_index < 0 or closest_diff > good_window:
		return {"index": -1, "judgement": "", "points": 0, "difference": closest_diff, "pitch_ok": is_pitch_correct, "timing_ok": false}
	
	if not is_pitch_correct:
		return {
			"index": closest_index,
			"judgement": "WRONG_NOTE",
			"points": 0,
			"difference": closest_diff,
			"pitch_ok": false,
			"timing_ok": closest_diff <= good_window,
		}
	
	var is_perfect := closest_diff <= perfect_window
	var judgement := "PERFECT" if is_perfect else "GOOD"
	# Hybrid scoring: 60% Pitch (60 pts) + 40% Timing (40 pts for PERFECT, 28 pts for GOOD)
	var points := 100 if is_perfect else 88
	return {
		"index": closest_index,
		"judgement": judgement,
		"points": points,
		"difference": closest_diff,
		"pitch_ok": true,
		"timing_ok": true,
	}


static func scaled_score(accuracy_points: int, beat_count: int, max_score: int) -> int:
	if beat_count <= 0 or max_score <= 0:
		return 0
	var ratio := clampf(float(accuracy_points) / float(beat_count * 100), 0.0, 1.0)
	return clampi(roundi(ratio * float(max_score)), 0, max_score)


static func accuracy_percent(accuracy_points: int, beat_count: int) -> float:
	if beat_count <= 0:
		return 0.0
	return clampf(float(accuracy_points) / float(beat_count * 100) * 100.0, 0.0, 100.0)


static func pitch_accuracy_percent(correct_pitch_count: int, beat_count: int) -> float:
	if beat_count <= 0:
		return 0.0
	return clampf(float(correct_pitch_count) / float(beat_count) * 100.0, 0.0, 100.0)


static func timing_accuracy_percent(on_time_count: int, beat_count: int) -> float:
	if beat_count <= 0:
		return 0.0
	return clampf(float(on_time_count) / float(beat_count) * 100.0, 0.0, 100.0)


static func stars_for_score(score: int, max_score: int) -> int:
	if max_score <= 0 or score <= 0:
		return 0
	var ratio := float(score) / float(max_score)
	if ratio >= 0.9:
		return 3
	if ratio >= 0.7:
		return 2
	if ratio >= 0.5:
		return 1
	return 0


static func _content_dictionary(raw_content: Variant) -> Dictionary:
	if raw_content is Dictionary:
		return raw_content
	var text := str(raw_content).strip_edges()
	if text.is_empty():
		return {}
	var parser := JSON.new()
	if parser.parse(text) != OK:
		return {}
	var parsed: Variant = parser.data
	if parsed is String:
		if parser.parse(parsed) != OK:
			return {}
		parsed = parser.data
	return parsed if parsed is Dictionary else {}


static func _safe_int(value: Variant, fallback: int = 0) -> int:
	if value == null:
		return fallback
	if value is int or value is float:
		return int(value)
	var text := str(value).strip_edges()
	return int(text) if text.is_valid_int() else fallback


static func _positive_int(value: Variant, fallback: int) -> int:
	var parsed := _safe_int(value, fallback)
	return parsed if parsed > 0 else maxi(0, fallback)
