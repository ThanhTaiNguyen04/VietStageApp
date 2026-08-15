extends SceneTree

const SAMPLE_RATE := 44100.0
const SAMPLE_COUNT := 2048


func _plucked_tone(frequency: float) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(SAMPLE_COUNT)
	for i in SAMPLE_COUNT:
		var phase := TAU * frequency * float(i) / SAMPLE_RATE
		var envelope := exp(-3.0 * float(i) / 12000.0) \
			* (1.0 + 3.0 * exp(-60.0 * float(i) / 12000.0))
		samples[i] = 0.5 * envelope * (
			0.25 * sin(phase) + 0.55 * sin(phase * 2.0) + 0.20 * sin(phase * 3.0)
		)
	return samples


func _plucked_chord(frequencies: Array[float]) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(SAMPLE_COUNT)
	for frequency in frequencies:
		var tone := _plucked_tone(frequency)
		for i in SAMPLE_COUNT:
			samples[i] += tone[i] / float(frequencies.size())
	return samples


func _sustained_voice(frequency: float, slow_attack: bool = false) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(SAMPLE_COUNT)
	for i in SAMPLE_COUNT:
		var time := float(i) / SAMPLE_RATE
		var envelope := minf(1.0, time / 0.035) if slow_attack else 1.0
		samples[i] = 0.34 * envelope * (
			sin(TAU * frequency * time)
			+ 0.45 * sin(TAU * frequency * 2.0 * time)
			+ 0.20 * sin(TAU * frequency * 3.0 * time)
		)
	return samples


func _consonant_then_voice(frequency: float) -> PackedFloat32Array:
	var samples := _sustained_voice(frequency)
	for i in mini(220, samples.size()):
		var consonant := 0.70 * exp(-5.0 * float(i) / 220.0) * sin(float(i * i) * 0.173)
		samples[i] = samples[i] * 0.30 + consonant
	for i in range(220, samples.size()):
		samples[i] *= 0.30
	return samples


func _tap_or_click() -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(SAMPLE_COUNT)
	for i in 40:
		samples[i] = 0.9 * exp(-8.0 * float(i) / 40.0) * sin(float(i * i) * 0.37)
	return samples


func _white_noise() -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(SAMPLE_COUNT)
	for i in SAMPLE_COUNT:
		samples[i] = 0.35 * sin(float(i * i) * 0.731 + float(i) * 1.913)
	return samples


func _init() -> void:
	var analyzer = load("res://scripts/AudioCaptureAnalyzer.gd").new()
	analyzer.volume_threshold_db = -58.0
	var failures: Array[String] = []

	for frequency in [196.0, 440.0, 1760.0]:
		var pluck_result: Dictionary = analyzer.analyze_dan_tranh_sound(_plucked_tone(frequency))
		if not pluck_result.get("accepted", false):
			failures.append("Bỏ sót tiếng gảy %.0f Hz: %s" % [frequency, pluck_result.get("reason", "")])
	var chord_result: Dictionary = analyzer.analyze_dan_tranh_sound(
		_plucked_chord([220.0, 261.63])
	)
	if not chord_result.get("accepted", false):
		failures.append("Bỏ sót Song thanh La1+Đô2: %s" % chord_result.get("reason", ""))
	var detuned_high := 1760.0 * pow(2.0, 45.0 / 1200.0)
	var detuned_result: Dictionary = analyzer.analyze_dan_tranh_sound(_plucked_tone(detuned_high))
	if not detuned_result.get("accepted", false):
		failures.append("Bỏ sót dây cao lệch 45 cents: %s" % detuned_result.get("reason", ""))

	var rejected_cases := {
		"giọng ngân": _sustained_voice(220.0),
		"giọng vào âm chậm": _sustained_voice(220.0, true),
		"phụ âm rồi tới nguyên âm": _consonant_then_voice(220.0),
		"tiếng gõ/click": _tap_or_click(),
		"tạp âm": _white_noise()
	}
	for case_name in rejected_cases:
		var rejected_result: Dictionary = analyzer.analyze_dan_tranh_sound(rejected_cases[case_name])
		if rejected_result.get("accepted", false):
			failures.append("Nhận nhầm %s là tiếng đàn (%.1f%%)" % [
				case_name, float(rejected_result.get("confidence", 0.0))
			])

	var pluck := _plucked_tone(440.0)
	analyzer._update_instrument_sound_gate(pluck.slice(0, 600), true, 0.016)
	analyzer._update_instrument_sound_gate(pluck.slice(600, 1200), false, 0.016)
	if not analyzer.has_recent_dan_tranh_attack():
		failures.append("Tiếng gảy hợp lệ không mở cổng tiếng đàn dùng chung")
	analyzer._handle_silence(0.36)
	if analyzer.has_recent_dan_tranh_attack():
		failures.append("Cổng tiếng đàn không đóng sau khi mất tín hiệu")

	analyzer.free()
	if failures.is_empty():
		print("PASS: bộ lọc chung nhận tiếng đàn và loại giọng nói/gõ/tạp âm")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)
