extends SceneTree

# ─── Reference Tuning & Notes ───────────────────────────────────────────────
const NOTES_VN : Array[String] = [
	"Đô", "Rê", "Mi", "Fa", "Sol", "La", "Si",
	"Đô2", "Rê2", "Mi2", "Fa2", "Sol2", "La2", "Si2",
	"Đô3", "Rê3"
]

func _get_string_frequency(idx: int) -> float:
	var base_freqs = [
		130.81, # Đô (C3)
		146.83, # Rê (D3)
		164.81, # Mi (E3)
		174.61, # Fa (F3)
		196.00, # Sol (G3)
		220.00, # La (A3)
		246.94  # Si (B3)
	]
	var octave = idx / 7
	var note_in_octave = idx % 7
	return base_freqs[note_in_octave] * pow(2, octave)

# ─── Synthetic Audio Generator ─────────────────────────────────────────────────
func generate_sine_wave(freq: float, duration: float, sample_rate: float, amplitude: float = 0.8) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	var sample_count = int(duration * sample_rate)
	samples.resize(sample_count)
	for i in range(sample_count):
		var t = float(i) / sample_rate
		samples[i] = amplitude * sin(2.0 * PI * freq * t)
	return samples

func _init() -> void:
	print("=================================================================")
	print("    VERIFYING PRODUCTION PITCH DETECTION FOR ĐÀN TRANH           ")
	print("=================================================================")
	
	var sample_rate := 44100.0
	var buffer_size := 1024
	var min_freq := 120.0
	var max_freq := 900.0
	var threshold := 0.15
	
	# Load the production AudioCaptureAnalyzer
	var visualizer_script = load("res://scripts/AudioCaptureAnalyzer.gd")
	if not visualizer_script:
		print("FAILED to load res://scripts/AudioCaptureAnalyzer.gd")
		quit(1)
		return
		
	var visualizer = visualizer_script.new()
	visualizer.min_frequency = min_freq
	visualizer.max_frequency = max_freq
	
	var passed_tests := 0
	var total_tests := 16
	
	print("\nTuning Details for all 16 strings:")
	for i in range(total_tests):
		var expected_freq = _get_string_frequency(i)
		var note_name = NOTES_VN[i]
		print("  String %2d: %-5s -> Expected Frequency: %7.2f Hz" % [i + 1, note_name, expected_freq])
	
	print("\nRunning Note Detection Tests on production AudioCaptureAnalyzer...")
	for i in range(total_tests):
		var expected_freq = _get_string_frequency(i)
		var note_name = NOTES_VN[i]
		
		# Generate synthetic audio samples (1024 samples)
		var duration = float(buffer_size) / sample_rate
		var samples = generate_sine_wave(expected_freq, duration, sample_rate)
		
		# Use the production class methods to filter and detect pitch
		var detected = visualizer._detect_pitch_yin_gdscript(samples, sample_rate, threshold)
		
		# Calculate error in cents
		var cents := 0.0
		if detected > 0.0:
			cents = 1200.0 * log(detected / expected_freq) / log(2.0)
			
		var is_ok = detected > 0.0 and abs(cents) < 12.0 # 12 cents tolerance for "Đúng cao độ"
		
		print("String %2d (%-5s): Target: %7.2f Hz | Detected: %7.2f Hz (err: %5.2f cents, %s)" % [
			i + 1, 
			note_name, 
			expected_freq, 
			detected, 
			cents, 
			"PASS" if is_ok else "FAIL"
		])
		
		if is_ok:
			passed_tests += 1
			
	print("\n=================================================================")
	print("PRODUCTION VERIFICATION SUMMARY:")
	print("  Passed tests: %d / %d (%d%%)" % [passed_tests, total_tests, int(float(passed_tests)/total_tests * 100)])
	print("=================================================================")
	
	quit(0 if passed_tests == total_tests else 1)
