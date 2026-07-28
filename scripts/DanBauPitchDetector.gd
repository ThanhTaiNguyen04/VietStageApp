extends RefCounted
class_name DanBauPitchDetector

# ─── ĐÀN BẦU NATURAL HARMONIC NODES (BỔI ÂM TỰ NHIÊN) ──────────────────────
const HARMONIC_NODES = {
	2: {"name": "Đô 1 (2nd Harmonic)", "ratio": "1/2", "note": "C4", "freq": 261.63},
	3: {"name": "Sol 1 (3rd Harmonic)", "ratio": "1/3", "note": "G4", "freq": 392.00},
	4: {"name": "Đô 2 (4th Harmonic)", "ratio": "1/4", "note": "C5", "freq": 523.25},
	5: {"name": "Mi 2 (5th Harmonic)", "ratio": "1/5", "note": "E5", "freq": 659.25},
	6: {"name": "Sol 2 (6th Harmonic)", "ratio": "1/6", "note": "G5", "freq": 783.99},
	7: {"name": "Si giáng 2 (7th Harmonic)", "ratio": "1/7", "note": "Bb5", "freq": 932.33},
	8: {"name": "Đô 3 (8th Harmonic)", "ratio": "1/8", "note": "C6", "freq": 1046.50}
}



# ─── PITCH CONVERSION HELPER FUNCTIONS ───

static var NOTE_TABLE: Array = []
static var _is_loaded: bool = false
static var NOTE_DICT: Dictionary = {}

static func get_note_table() -> Array:
	if not _is_loaded:
		_load_data()
	return NOTE_TABLE

static func _load_data() -> void:
	var path = "res://data/dan_bau_notes.json"
	if not FileAccess.file_exists(path):
		push_error("Missing Dan Bau note data at " + path)
		return
	var file = FileAccess.open(path, FileAccess.READ)
	var json_str = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(json_str) == OK:
		NOTE_TABLE = json.get_data()
		for note in NOTE_TABLE:
			NOTE_DICT[note["note"]] = note
	_is_loaded = true

static func hz_to_midi(freq: float) -> float:
	if freq <= 0.0: return 0.0
	return 69.0 + 12.0 * (log(freq / 440.0) / log(2.0))

static func midi_to_hz(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)

static func get_cents_diff(freq1: float, freq2: float) -> float:
	if freq1 <= 0.0 or freq2 <= 0.0: return 9999.0
	return 1200.0 * (log(freq1 / freq2) / log(2.0))

static func find_nearest_note(freq: float) -> Dictionary:
	if freq <= 0.0:
		return {}
	
	var table = get_note_table()
	var best_note: Dictionary = {}
	var min_cents: float = 99999.0
	
	for entry in table:
		var cents = abs(get_cents_diff(freq, entry["hz"]))
		if cents < min_cents:
			min_cents = cents
			best_note = entry
			
	if best_note.size() > 0:
		best_note["cents_error"] = get_cents_diff(freq, best_note["hz"])
		best_note["abs_cents_error"] = min_cents
		
	return best_note

static func evaluate_pitch(detected_freq: float, target_note_name: String) -> Dictionary:
	var table = get_note_table()
	if not NOTE_DICT.has(target_note_name) or detected_freq <= 0.0:
		return {"match": false, "rank": "FAIL", "cents_error": 9999.0}
		
	var target = NOTE_DICT[target_note_name]
	var target_freq = target["hz"]
	var cents_err = get_cents_diff(detected_freq, target_freq)
	var abs_err = abs(cents_err)
	
	var rank = "FAIL"
	var is_match = false
	if abs_err <= 5.0:
		rank = "PERFECT"
		is_match = true
	elif abs_err <= 10.0:
		rank = "GOOD"
		is_match = true
	elif abs_err <= 20.0:
		rank = "PASS"
		is_match = true
	elif detected_freq >= target["min_hz"] and detected_freq <= target["max_hz"]:
		# Within JSON fallback boundaries
		rank = "PASS"
		is_match = true
		
	return {
		"is_match": is_match,
		"rank": rank,
		"cents_error": cents_err,
		"abs_cents_error": abs_err,
		"target_freq": target_freq
	}

static func evaluate_pitch_by_freq(detected_freq: float, expected_target_freq: float) -> Dictionary:
	var table = get_note_table()
	if detected_freq <= 0.0 or expected_target_freq <= 0.0:
		return {"is_match": false, "rank": "FAIL", "cents_error": 9999.0, "target_freq": 0.0}
		
	var target = {}
	for entry in table:
		if abs(entry["hz"] - expected_target_freq) < 1.0:
			target = entry
			break
			
	if target.is_empty():
		return {"is_match": false, "rank": "FAIL", "cents_error": 9999.0, "target_freq": 0.0}
		
	var target_freq = target["hz"]
	var cents_err = get_cents_diff(detected_freq, target_freq)
	var abs_err = abs(cents_err)
	
	var rank = "FAIL"
	var is_match = false
	if abs_err <= 5.0:
		rank = "PERFECT"
		is_match = true
	elif abs_err <= 10.0:
		rank = "GOOD"
		is_match = true
	elif abs_err <= 20.0:
		rank = "PASS"
		is_match = true
	elif detected_freq >= target["min_hz"] and detected_freq <= target["max_hz"]:
		# Within JSON fallback boundaries
		rank = "PASS"
		is_match = true
		
	return {
		"is_match": is_match,
		"rank": rank,
		"cents_error": cents_err,
		"abs_cents_error": abs_err,
		"target_freq": target_freq
	}

static func is_pitch_accurate(detected_freq: float, target_freq: float, max_cents_tolerance: float = 20.0, max_hz_tolerance: float = 15.0) -> bool:
	if detected_freq <= 0.0 or target_freq <= 0.0:
		return false
		
	var cents_err = abs(get_cents_diff(detected_freq, target_freq))
	var hz_err = abs(detected_freq - target_freq)
	
	return cents_err <= max_cents_tolerance or hz_err <= max_hz_tolerance
