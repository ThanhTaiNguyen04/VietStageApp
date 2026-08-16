extends SceneTree

const SAMPLE_RATE := 44100.0
const SAMPLE_COUNT := 4096


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


func _normal_speech_like() -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(SAMPLE_COUNT)
	var phase := 0.0
	for i in SAMPLE_COUNT:
		var time := float(i) / SAMPLE_RATE
		var fundamental := 145.0 + 24.0 * sin(TAU * 2.7 * time)
		phase += TAU * fundamental / SAMPLE_RATE
		var syllable_envelope := minf(1.0, time / 0.025) * (0.72 + 0.28 * sin(TAU * 6.0 * time))
		var consonant := 0.18 * sin(float(i * i) * 0.219) if i < 420 else 0.0
		samples[i] = syllable_envelope * 0.28 * (
			sin(phase) + 0.62 * sin(phase * 2.0) + 0.34 * sin(phase * 3.0)
		) + consonant
	return samples


func _pitch_glide_voice(start_frequency: float, end_frequency: float) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(SAMPLE_COUNT)
	var phase := 0.0
	for i in SAMPLE_COUNT:
		var ratio := float(i) / float(SAMPLE_COUNT - 1)
		var frequency := lerpf(start_frequency, end_frequency, ratio)
		phase += TAU * frequency / SAMPLE_RATE
		var envelope := minf(1.0, float(i) / (SAMPLE_RATE * 0.035))
		samples[i] = 0.32 * envelope * (
			sin(phase) + 0.48 * sin(phase * 2.0) + 0.22 * sin(phase * 3.0)
		)
	return samples


func _vocal_vibrato(frequency: float, depth_cents: float = 35.0, rate_hz: float = 5.5) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(SAMPLE_COUNT)
	var phase := 0.0
	for i in SAMPLE_COUNT:
		var time := float(i) / SAMPLE_RATE
		var cents := depth_cents * sin(TAU * rate_hz * time)
		var instant_frequency := frequency * pow(2.0, cents / 1200.0)
		phase += TAU * instant_frequency / SAMPLE_RATE
		var envelope := minf(1.0, time / 0.035)
		samples[i] = 0.32 * envelope * (
			sin(phase) + 0.50 * sin(phase * 2.0) + 0.24 * sin(phase * 3.0)
		)
	return samples


func _tap_or_click() -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(SAMPLE_COUNT)
	for i in 40:
		samples[i] = 0.9 * exp(-8.0 * float(i) / 40.0) * sin(float(i * i) * 0.37)
	return samples


func _clap() -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(SAMPLE_COUNT)
	for i in SAMPLE_COUNT:
		var envelope := exp(-18.0 * float(i) / 1200.0)
		var noise := sin(float(i * i) * 0.417) + 0.55 * sin(float(i * i) * 0.173 + 1.2)
		samples[i] = 0.52 * envelope * noise
	return samples


func _white_noise() -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(SAMPLE_COUNT)
	for i in SAMPLE_COUNT:
		samples[i] = 0.35 * sin(float(i * i) * 0.731 + float(i) * 1.913)
	return samples


func _room_noise() -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(SAMPLE_COUNT)
	for i in SAMPLE_COUNT:
		var time := float(i) / SAMPLE_RATE
		var electrical_hum := 0.045 * sin(TAU * 50.0 * time) + 0.018 * sin(TAU * 100.0 * time)
		var ambient := 0.055 * sin(float(i * i) * 0.0317 + float(i) * 1.71)
		samples[i] = electrical_hum + ambient
	return samples


func _speaker_playback_voice(frequency: float) -> PackedFloat32Array:
	var dry := _sustained_voice(frequency, true)
	var samples := PackedFloat32Array()
	samples.resize(SAMPLE_COUNT)
	var delay_samples := 290
	for i in SAMPLE_COUNT:
		var direct := dry[i]
		var reflected := dry[i - delay_samples] * 0.42 if i >= delay_samples else 0.0
		# Soft clipping and a short room reflection approximate phone/laptop speaker playback.
		samples[i] = tanh((direct + reflected) * 1.7) * 0.42
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
		failures.append("Bỏ sót dây cao lệch 45 cents: %s" % JSON.stringify(detuned_result))

	var rejected_cases := {
		"nói bình thường": _normal_speech_like(),
		"hát đúng nốt La2": _sustained_voice(440.0),
		"giọng ngân dài": _sustained_voice(220.0),
		"giọng vào âm chậm": _sustained_voice(220.0, true),
		"phụ âm rồi tới nguyên âm": _consonant_then_voice(220.0),
		"giọng luyến cao độ La2 lên Si2": _pitch_glide_voice(440.0, 493.88),
		"giọng có vocal vibrato": _vocal_vibrato(440.0),
		"tiếng gõ/click": _tap_or_click(),
		"tiếng vỗ tay": _clap(),
		"tạp âm trắng": _white_noise(),
		"nhiễu phòng": _room_noise(),
		"giọng phát lại từ loa": _speaker_playback_voice(440.0)
	}
	for case_name in rejected_cases:
		var rejected_result: Dictionary = analyzer.analyze_dan_tranh_sound(rejected_cases[case_name])
		if rejected_result.get("accepted", false):
			failures.append("Nhận nhầm %s là tiếng đàn (%.1f%%)" % [
				case_name, float(rejected_result.get("confidence", 0.0))
			])

	var pluck := _plucked_tone(440.0)
	var candidate_offset := 0
	while candidate_offset < SAMPLE_COUNT:
		var candidate_end := mini(candidate_offset + 600, SAMPLE_COUNT)
		analyzer._update_instrument_sound_gate(
			pluck.slice(candidate_offset, candidate_end),
			candidate_offset == 0,
			0.016
		)
		candidate_offset = candidate_end
		if candidate_offset < SAMPLE_COUNT and analyzer.has_recent_dan_tranh_attack():
			failures.append("Cổng tiếng đàn mở trước khi thu đủ 4096 mẫu")
			break
	if not analyzer.has_recent_dan_tranh_attack():
		failures.append("Tiếng gảy hợp lệ không mở cổng sau khi thu đủ 4096 mẫu")
	analyzer._handle_silence(0.36)
	if analyzer.has_recent_dan_tranh_attack():
		failures.append("Cổng tiếng đàn không đóng sau khi mất tín hiệu")

	# A single rejected timbre window must retain stable pitch and wait for
	# additional decay samples. Only the final failed retry may clear it.
	var retry_analyzer = load("res://scripts/AudioCaptureAnalyzer.gd").new()
	retry_analyzer.volume_threshold_db = -58.0
	for pitch_frame in 4:
		retry_analyzer._update_reliable_pitch(440.0)
	var rejected_voice := _sustained_voice(440.0)
	retry_analyzer._update_instrument_sound_gate(rejected_voice, true, 0.016)
	if not retry_analyzer._instrument_attack_candidate_active:
		failures.append("Cửa sổ âm sắc sai đầu tiên không được giữ lại để thử lại")
	if not retry_analyzer.current_pitch_is_reliable or retry_analyzer.current_pitch <= 0.0:
		failures.append("Pitch bị xóa ngay sau cửa sổ âm sắc sai đầu tiên")
	retry_analyzer._update_instrument_sound_gate(
		rejected_voice.slice(0, 512), false, 0.016
	)
	if not retry_analyzer._instrument_attack_candidate_active:
		failures.append("Cửa sổ âm sắc sai thứ hai không được giữ cho lần thử cuối")
	retry_analyzer._update_instrument_sound_gate(
		rejected_voice.slice(512, 1024), false, 0.016
	)
	if retry_analyzer._instrument_attack_candidate_active:
		failures.append("Ứng viên âm sắc vẫn treo sau ba cửa sổ đều bị từ chối")
	if retry_analyzer.current_pitch_is_reliable or retry_analyzer.current_pitch > 0.0:
		failures.append("Pitch không được xóa sau khi cả ba cửa sổ đều bị từ chối")
	retry_analyzer.free()

	analyzer.free()
	if failures.is_empty():
		print("PASS: bộ lọc chung nhận tiếng đàn và loại giọng nói/gõ/tạp âm")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)
