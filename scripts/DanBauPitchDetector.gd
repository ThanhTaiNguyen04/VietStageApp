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

# ─── STANDARD NOTE FREQUENCY TABLE (Hz & MIDI) ───
const NOTE_TABLE = [
	{"note": "A2", "vn_name": "La2", "freq": 110.00, "midi": 45},
	{"note": "A#2", "vn_name": "La#2", "freq": 116.54, "midi": 46},
	{"note": "B2", "vn_name": "Si2", "freq": 123.47, "midi": 47},
	{"note": "C3", "vn_name": "Đồ3", "freq": 130.81, "midi": 48},
	{"note": "C#3", "vn_name": "Đồ#3", "freq": 138.59, "midi": 49},
	{"note": "D3", "vn_name": "Rê3", "freq": 146.83, "midi": 50},
	{"note": "D#3", "vn_name": "Rê#3", "freq": 155.56, "midi": 51},
	{"note": "E3", "vn_name": "Mi3", "freq": 164.81, "midi": 52},
	{"note": "F3", "vn_name": "Fa3", "freq": 174.61, "midi": 53},
	{"note": "F#3", "vn_name": "Fa#3", "freq": 185.00, "midi": 54},
	{"note": "G3", "vn_name": "Sol3", "freq": 196.00, "midi": 55},
	{"note": "G#3", "vn_name": "Sol#3", "freq": 207.65, "midi": 56},
	{"note": "A3", "vn_name": "La3", "freq": 220.00, "midi": 57},
	{"note": "A#3", "vn_name": "Si giáng 3", "freq": 233.08, "midi": 58},
	{"note": "B3", "vn_name": "Si3", "freq": 246.94, "midi": 59},
	{"note": "C4", "vn_name": "Đồ / Đô4", "freq": 261.63, "midi": 60},
	{"note": "C#4", "vn_name": "Đô#4", "freq": 277.18, "midi": 61},
	{"note": "D4", "vn_name": "Rê4", "freq": 293.66, "midi": 62},
	{"note": "D#4", "vn_name": "Rê#4", "freq": 311.13, "midi": 63},
	{"note": "E4", "vn_name": "Mi4", "freq": 329.63, "midi": 64},
	{"note": "F4", "vn_name": "Fa4", "freq": 349.23, "midi": 65},
	{"note": "F#4", "vn_name": "Fa#4", "freq": 369.99, "midi": 66},
	{"note": "G4", "vn_name": "Sol4", "freq": 392.00, "midi": 67},
	{"note": "G#4", "vn_name": "Sol#4", "freq": 415.30, "midi": 68},
	{"note": "A4", "vn_name": "La4", "freq": 440.00, "midi": 69},
	{"note": "A#4", "vn_name": "Si giáng 4", "freq": 466.16, "midi": 70},
	{"note": "B4", "vn_name": "Si4", "freq": 493.88, "midi": 71},
	{"note": "C5", "vn_name": "Đô5", "freq": 523.25, "midi": 72},
	{"note": "C#5", "vn_name": "Đô#5", "freq": 554.37, "midi": 73},
	{"note": "D5", "vn_name": "Rê5", "freq": 587.33, "midi": 74},
	{"note": "D#5", "vn_name": "Rê#5", "freq": 622.25, "midi": 75},
	{"note": "E5", "vn_name": "Mi5", "freq": 659.25, "midi": 76},
	{"note": "F5", "vn_name": "Fa5", "freq": 698.46, "midi": 77},
	{"note": "F#5", "vn_name": "Fa#5", "freq": 739.99, "midi": 78},
	{"note": "G5", "vn_name": "Sol5", "freq": 783.99, "midi": 79},
	{"note": "G#5", "vn_name": "Sol#5", "freq": 830.61, "midi": 80},
	{"note": "A5", "vn_name": "La5", "freq": 880.00, "midi": 81},
	{"note": "A#5", "vn_name": "Si giáng 5", "freq": 932.33, "midi": 82},
	{"note": "B5", "vn_name": "Si5", "freq": 987.77, "midi": 83},
	{"note": "C6", "vn_name": "Đố / Đô6", "freq": 1046.50, "midi": 84}
]

# ─── PITCH CONVERSION HELPER FUNCTIONS ───

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
		
	var best_note: Dictionary = {}
	var min_cents: float = 99999.0
	
	for entry in NOTE_TABLE:
		var cents = abs(get_cents_diff(freq, entry["freq"]))
		if cents < min_cents:
			min_cents = cents
			best_note = entry
			
	if best_note.size() > 0:
		best_note["cents_error"] = get_cents_diff(freq, best_note["freq"])
		best_note["abs_cents_error"] = min_cents
		
	return best_note

static func is_pitch_accurate(detected_freq: float, target_freq: float, max_cents_tolerance: float = 20.0, max_hz_tolerance: float = 15.0) -> bool:
	if detected_freq <= 0.0 or target_freq <= 0.0:
		return false
		
	var cents_err = abs(get_cents_diff(detected_freq, target_freq))
	var hz_err = abs(detected_freq - target_freq)
	
	return cents_err <= max_cents_tolerance or hz_err <= max_hz_tolerance
