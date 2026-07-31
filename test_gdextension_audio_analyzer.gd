extends SceneTree

const SAMPLE_RATE := 44100.0
const SAMPLE_COUNT := 4096
const HIGH_NOTES := {
	"Sol3": 783.99,
	"La3": 880.00,
	"Đô3": 1046.50,
	"Rê3": 1174.66,
	"Mi3": 1318.51,
	"Sol4": 1567.98,
	"La4": 1760.00,
}

func _init() -> void:
	if not ClassDB.class_exists("AudioAnalyzer"):
		printerr("FAILED: AudioAnalyzer GDExtension class is not registered")
		quit(1)
		return

	var analyzer = ClassDB.instantiate("AudioAnalyzer")
	if analyzer == null:
		printerr("FAILED: Cannot instantiate native AudioAnalyzer")
		quit(1)
		return

	for note_name: String in HIGH_NOTES:
		var frequency: float = HIGH_NOTES[note_name]
		var samples := _make_plucked_tone(frequency)
		var detected: float = analyzer.analyze_pitch_yin(
			samples,
			SAMPLE_RATE,
			0.08,
			180.0,
			4200.0
		)
		var cents := absf(1200.0 * log(detected / frequency) / log(2.0)) if detected > 0.0 else INF
		var note: Dictionary = analyzer.detect_dan_tranh_note(samples, SAMPLE_RATE)

		if cents > 12.0 or note.get("note_name", "") != note_name:
			printerr(
				"FAILED: Native %s detection returned %.2f Hz (%.2f cents), note %s"
				% [note_name, detected, cents, note.get("note_name", "None")]
			)
			quit(1)
			return

	print("PASS: Native AudioAnalyzer detected all Sol3-La4 plucked tones")
	quit(0)

func _make_plucked_tone(frequency: float) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(SAMPLE_COUNT)
	for index in SAMPLE_COUNT:
		var phase := TAU * frequency * float(index) / SAMPLE_RATE
		var envelope := exp(-3.0 * float(index) / float(SAMPLE_COUNT))
		samples[index] = envelope * (
			0.25 * sin(phase)
			+ 0.55 * sin(phase * 2.0)
			+ 0.20 * sin(phase * 3.0)
		)
	return samples