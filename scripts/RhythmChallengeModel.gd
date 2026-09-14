extends RefCounted

const PERFECT_WINDOW := 0.08
const GOOD_WINDOW := 0.24


static func parse_challenges(challenge_items: Array) -> Array[Dictionary]:
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
			var beats := normalize_beats(round_data.get("beats", []))
			if beats.is_empty():
				continue
			var inherited_tempo: Variant = content.get("tempoBpm", content.get("tempo_bpm", 0))
			var round_tempo: Variant = round_data.get("tempoBpm", round_data.get("tempo_bpm", inherited_tempo))
			valid_rounds.append({
				"beats": beats,
				"tempo_bpm": _positive_int(round_tempo, 0),
				"label": str(round_data.get("title", round_data.get("label", ""))).strip_edges(),
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
				"max_score": max_score,
				"order_index": _safe_int(item.get("orderIndex", item.get("order_index", 0))),
				"round_index": round_index,
				"round_count": valid_rounds.size(),
				"submit_after": round_index == valid_rounds.size() - 1,
			})
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


static func scaled_score(accuracy_points: int, beat_count: int, max_score: int) -> int:
	if beat_count <= 0 or max_score <= 0:
		return 0
	var ratio := clampf(float(accuracy_points) / float(beat_count * 100), 0.0, 1.0)
	return clampi(roundi(ratio * float(max_score)), 0, max_score)


static func accuracy_percent(accuracy_points: int, beat_count: int) -> float:
	if beat_count <= 0:
		return 0.0
	return clampf(float(accuracy_points) / float(beat_count * 100) * 100.0, 0.0, 100.0)


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
