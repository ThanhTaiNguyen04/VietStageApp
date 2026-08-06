extends SceneTree

const SAMPLE_RATE := 44100.0

func _sine(freq: float, count: int) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		samples[i] = 0.6 * sin(TAU * freq * float(i) / SAMPLE_RATE)
	return samples

func _plucked(freq: float, count: int) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var idx := i
		var phase := TAU * freq * float(idx) / SAMPLE_RATE
		var envelope := exp(-3.0 * float(idx) / 12000.0) * (1.0 + 3.0 * exp(-60.0 * float(idx) / 12000.0))
		samples[i] = 0.5 * envelope * (0.25 * sin(phase) + 0.55 * sin(phase * 2.0) + 0.20 * sin(phase * 3.0))
	return samples

func _noise_burst(duration_sec: float) -> PackedFloat32Array:
	var count := int(duration_sec * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var envelope := exp(-20.0 * float(i) / float(count))
		samples[i] = 0.8 * envelope * (randf() * 2.0 - 1.0)
	return samples

func _noise_flat(count: int) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		samples[i] = 0.3 * (randf() * 2.0 - 1.0)
	return samples

func _init() -> void:
	var analyzer = load("res://scripts/AudioCaptureAnalyzer.gd").new()
	analyzer.min_frequency = 180.0
	analyzer.max_frequency = 4200.0
	for freq in [196.0, 440.0, 1760.0]:
		var p: float = analyzer._evaluate_tone_quality_gdscript(_plucked(freq, 2048))
		var s: float = analyzer._evaluate_tone_quality_gdscript(_sine(freq, 2048))
		print("freq=%.0f  pluck_quality=%.1f  sine_quality=%.1f" % [freq, p, s])
	print("noise_burst_quality=%.1f" % analyzer._evaluate_tone_quality_gdscript(_noise_burst(0.05)))
	print("noise_flat_quality=%.1f" % analyzer._evaluate_tone_quality_gdscript(_noise_flat(2048)))
	quit(0)
