extends SceneTree

const SAMPLE_RATE := 44100.0
const FRAME_SIZE := 735

const ALL_17_NOTES := [
	"Sol1", "La1", "Đô2", "Rê2", "Mi2", "Sol2", "La2", "Đô3", "Rê3", "Mi3",
	"Sol3", "La3", "Đô4", "Rê4", "Mi4", "Sol4", "La4",
]
const NOTE_FREQS := {
	"Sol1": 196.00, "La1": 220.00, "Đô2": 261.63, "Rê2": 293.66, "Mi2": 329.63,
	"Sol2": 392.00, "La2": 440.00, "Đô3": 523.25, "Rê3": 587.33, "Mi3": 659.25,
	"Sol3": 783.99, "La3": 880.00, "Đô4": 1046.50, "Rê4": 1174.66, "Mi4": 1318.51,
	"Sol4": 1567.98, "La4": 1760.00,
}

func _make_analyzer() -> AudioCaptureAnalyzer:
	var analyzer = load("res://scripts/AudioCaptureAnalyzer.gd").new()
	var profile = load("res://scripts/InstrumentPitchProfile.gd").new()
	profile.notes.assign(ALL_17_NOTES)
	var freqs: Array[float] = []
	var mappings: Array[int] = []
	for i in range(ALL_17_NOTES.size()):
		freqs.append(NOTE_FREQS[ALL_17_NOTES[i]])
		mappings.append(i)
	profile.frequencies = PackedFloat32Array(freqs)
	profile.physical_mappings = mappings
	profile.min_frequency = 180.0
	profile.max_frequency = 4200.0
	profile.volume_threshold_db = -58.0
	profile.cents_tolerance = 35.0
	profile.is_plucked_instrument = true
	analyzer.pitch_profile = profile
	analyzer.min_frequency = 180.0
	analyzer.max_frequency = 4200.0
	analyzer.volume_threshold_db = -58.0
	return analyzer

func _plucked_tone(frequency: float, count: int, start_offset: int = 0) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var idx := start_offset + i
		var phase := TAU * frequency * float(idx) / SAMPLE_RATE
		# Sharp pluck attack (fast transient) + natural exponential sustain decay.
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

func _sine_tone(frequency: float, count: int) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		samples[i] = 0.6 * sin(TAU * frequency * float(i) / SAMPLE_RATE)
	return samples

# Mirrors AudioCaptureAnalyzer._process exactly (headless: no audio device needed).
func _run_frames(analyzer: AudioCaptureAnalyzer, frames: Array[PackedFloat32Array]) -> Dictionary:
	var buffer := PackedFloat32Array()
	var reliable_frames := 0
	var notes_seen := {}
	for frame in frames:
		buffer.append_array(frame)
		if buffer.size() > 2048:
			buffer = buffer.slice(buffer.size() - 2048)
		analyzer._analysis_buffer = buffer

		var db := analyzer._calculate_amplitude_db(frame)
		analyzer.current_amplitude_db = db
		if db <= analyzer.volume_threshold_db:
			analyzer._handle_silence(0.016)
			continue

		var is_onset := analyzer._detect_onset(frame)
		var profile_plucked: bool = analyzer.pitch_profile != null and analyzer.pitch_profile.is_plucked_instrument
		if profile_plucked:
			analyzer._update_instrument_sound_gate(frame, is_onset, 0.016)

		if profile_plucked:
			if is_onset and (not analyzer.pluck_locked or analyzer.pitch_estimation_done or analyzer.time_since_onset > 0.15):
				if analyzer._dan_tranh_note_active:
					analyzer._finish_dan_tranh_note()
				analyzer.onset_detected = true
				analyzer.time_since_onset = 0.0
				analyzer.pitch_estimation_done = false
				analyzer.pluck_locked = true
				analyzer._clear_pitch_detection()
			if analyzer.onset_detected:
				analyzer.time_since_onset += 0.016

		var raw_pitch := 0.0
		if profile_plucked:
			if analyzer.onset_detected and analyzer.time_since_onset >= 0.03 and analyzer.time_since_onset <= 0.15:
				if not analyzer.pitch_estimation_done:
					raw_pitch = analyzer._estimate_pitch(frame)
					if raw_pitch > 0.0 and analyzer.current_pitch_is_reliable:
						analyzer.pitch_estimation_done = true
		else:
			raw_pitch = analyzer._estimate_pitch(frame)

		if raw_pitch > 0.0:
			analyzer._update_reliable_pitch(raw_pitch)
		if profile_plucked and not analyzer.has_recent_dan_tranh_attack():
			analyzer._clear_pitch_detection()

		if analyzer.current_pitch_is_reliable and analyzer.current_pitch > 0.0 and analyzer.pitch_profile != null:
			reliable_frames += 1
			var mapped: Dictionary = analyzer.pitch_profile.match_pitch(analyzer.current_pitch)
			if mapped.get("is_match", false):
				var name: String = mapped.get("note_name", "")
				notes_seen[name] = notes_seen.get(name, 0) + 1

	return {"reliable_frames": reliable_frames, "notes_seen": notes_seen}

func _init() -> void:
	var failures: Array[String] = []

	# 1. Every real string note must be recognized during a normal pluck.
	for note in ALL_17_NOTES:
		var analyzer := _make_analyzer()
		var frames: Array[PackedFloat32Array] = []
		var offset := 0
		for f in 28:
			frames.append(_plucked_tone(NOTE_FREQS[note], FRAME_SIZE, offset))
			offset += FRAME_SIZE
		var result := _run_frames(analyzer, frames)
		if not result["notes_seen"].has(note):
			failures.append("Dây %s không được nhận diện trong luồng gảy (reliable frames: %d)" % [note, result["reliable_frames"]])

	# 2. Tap / click noise (sharp short burst) must NOT produce a note.
	var tap_analyzer := _make_analyzer()
	var tap_frames: Array[PackedFloat32Array] = [_noise_burst(0.012)]
	for f in 20:
		tap_frames.append(PackedFloat32Array())
	var tap_result := _run_frames(tap_analyzer, tap_frames)
	if not tap_result["notes_seen"].is_empty():
		failures.append("Tiếng gõ bị nhận nhầm thành nốt: %s" % [tap_result["notes_seen"]])

	# 3. White noise (microphone hiss / applause-like) must NOT produce a note.
	var noise_analyzer := _make_analyzer()
	var noise_frames: Array[PackedFloat32Array] = []
	for f in 25:
		noise_frames.append(_noise_burst(float(FRAME_SIZE) / SAMPLE_RATE))
	var noise_result := _run_frames(noise_analyzer, noise_frames)
	if not noise_result["notes_seen"].is_empty():
		failures.append("Tạp âm trắng bị nhận nhầm thành nốt: %s" % [noise_result["notes_seen"]])

	# 4. Sustained voice-like tone (no pluck attack) must NOT produce a note.
	var voice_analyzer := _make_analyzer()
	var voice_frames: Array[PackedFloat32Array] = []
	for f in 25:
		voice_frames.append(_sine_tone(220.0, FRAME_SIZE))
	var voice_result := _run_frames(voice_analyzer, voice_frames)
	if not voice_result["notes_seen"].is_empty():
		failures.append("Giọng hát/hum 220 Hz bị nhận nhầm thành nốt: %s" % [voice_result["notes_seen"]])

	# 5. Single-shot fallback (detect_dan_tranh_note): accepts a pluck attack,
	#    but rejects sustained voice, ambient room tone, and click bursts.
	var bow_analyzer := _make_analyzer()
	var pluck_buf: PackedFloat32Array = _plucked_tone(440.0, 2048)
	if bow_analyzer.detect_dan_tranh_note(pluck_buf, SAMPLE_RATE).get("note_name", "None") != "La2":
		failures.append("Single-shot bỏ sót âm gảy La2")
	var voiced_buf: PackedFloat32Array = _sine_tone(440.0, 2048)
	if not bow_analyzer.detect_dan_tranh_note(voiced_buf, SAMPLE_RATE).is_empty():
		failures.append("Single-shot nhận nhầm nốt bền (hum 440 Hz)")
	var click_buf: PackedFloat32Array = _noise_burst(0.05)
	if not bow_analyzer.detect_dan_tranh_note(click_buf, SAMPLE_RATE).is_empty():
		failures.append("Single-shot nhận nhầm tiếng click/gõ")

	if failures.is_empty():
		print("PASS: plucked flow recognizes all 17 strings and rejects taps/noise/voice")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)
