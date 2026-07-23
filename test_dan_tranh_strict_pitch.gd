extends SceneTree

const FREQUENCIES := [
	196.00, 220.00, 261.63, 293.66, 329.63,
	392.00, 440.00, 523.25, 587.33, 659.25,
	783.99, 880.00, 1046.50, 1174.66, 1318.51,
	1567.98, 1760.00,
]

func _sine(frequency: float, sample_rate: float, count: int) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		samples[i] = 0.75 * sin(TAU * frequency * float(i) / sample_rate)
	return samples

func _plucked_tone(frequency: float, sample_rate: float, count: int) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var phase := TAU * frequency * float(i) / sample_rate
		var envelope := exp(-3.0 * float(i) / float(count))
		# Deliberately bright zither tone with a stronger second harmonic.
		samples[i] = envelope * (0.25 * sin(phase) + 0.55 * sin(phase * 2.0) + 0.20 * sin(phase * 3.0))
	return samples

func _init() -> void:
	var analyzer = load("res://scripts/AudioCaptureAnalyzer.gd").new()
	analyzer.min_frequency = 180.0
	analyzer.max_frequency = 1900.0
	var sample_rate := 44100.0
	var failures: Array[String] = []

	for index in FREQUENCIES.size():
		var expected: float = FREQUENCIES[index]
		var detected: float = analyzer._detect_pitch_yin_gdscript(
			_sine(expected, sample_rate, 2048), sample_rate, 0.08
		)
		var cents := absf(1200.0 * log(detected / expected) / log(2.0)) if detected > 0.0 else INF
		if cents > 5.0:
			failures.append("Dây %d: %.2f Hz -> %.2f Hz (%.2f cent)" % [index + 1, expected, detected, cents])

		var plucked_detected: float = analyzer._detect_pitch_yin_gdscript(
			_plucked_tone(expected, sample_rate, 2048), sample_rate, 0.08
		)
		var plucked_cents := absf(1200.0 * log(plucked_detected / expected) / log(2.0)) if plucked_detected > 0.0 else INF
		if plucked_cents > 12.0:
			failures.append("Âm gảy dây %d bị nhầm quãng tám: %.2f Hz (%.2f cent)" % [index + 1, plucked_detected, plucked_cents])

	# A pitch is not exposed until multiple real analysis frames agree.
	for i in 3:
		analyzer._update_reliable_pitch(196.0)
	if analyzer.current_pitch_is_reliable or analyzer.current_pitch != 0.0:
		failures.append("Cổng ổn định đã nhận nốt quá sớm")
	analyzer._update_reliable_pitch(196.0)
	if not analyzer.current_pitch_is_reliable or absf(analyzer.current_pitch - 196.0) > 0.1:
		failures.append("Cổng ổn định không nhận Sol1 sau 4 khung đúng")

	# A different string must reset the window instead of being averaged in.
	analyzer._update_reliable_pitch(261.63)
	if analyzer.current_pitch_is_reliable or analyzer.current_pitch != 0.0:
		failures.append("Đổi dây không đặt lại cửa sổ cao độ")
	analyzer._clear_pitch_detection()
	if analyzer.current_pitch_is_reliable or analyzer.current_pitch != 0.0:
		failures.append("Mất tín hiệu vẫn để lại cao độ cũ")

	if failures.is_empty():
		print("PASS: 17/17 cao độ đàn tranh và cổng ổn định micro")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)
