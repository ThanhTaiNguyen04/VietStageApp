extends SceneTree

const SAMPLE_RATE := 44100.0
const FRAME_SIZE := 735

const ALL_17_NOTES := [
	"Sol1", "La1", "Đô2", "Rê2", "Mi2", "Sol2", "La2", "Đô3", "Rê3", "Mi3",
	"Sol3", "La3", "Đô4", "Rê4", "Mi4", "Sol4", "La4",
]
const RUNTIME_PROFILE_NOTES := [
	"Sol1", "La1", "Đô2", "Rê2", "Mi2", "Fa2", "Sol2", "La2", "Si2",
	"Đô3", "Rê3", "Mi3", "Fa3", "Sol3", "La3", "Si3", "Đô4", "Rê4",
	"Mi4", "Sol4", "La4",
]
const NOTE_FREQS := {
	"Sol1": 196.00, "La1": 220.00, "Đô2": 261.63, "Rê2": 293.66, "Mi2": 329.63,
	"Fa2": 349.23, "Sol2": 392.00, "La2": 440.00, "Si2": 493.88,
	"Đô3": 523.25, "Rê3": 587.33, "Mi3": 659.25, "Fa3": 698.46,
	"Sol3": 783.99, "La3": 880.00, "Si3": 987.77, "Đô4": 1046.50,
	"Rê4": 1174.66, "Mi4": 1318.51,
	"Sol4": 1567.98, "La4": 1760.00,
}
const NOTE_TO_STRING := {
	"Sol1": 0, "La1": 1, "Đô2": 2, "Rê2": 3, "Mi2": 4, "Fa2": 4,
	"Sol2": 5, "La2": 6, "Si2": 6, "Đô3": 7, "Rê3": 8, "Mi3": 9,
	"Fa3": 9, "Sol3": 10, "La3": 11, "Si3": 11, "Đô4": 12,
	"Rê4": 13, "Mi4": 14, "Sol4": 15, "La4": 16,
}

func _make_analyzer() -> AudioCaptureAnalyzer:
	var analyzer = load("res://scripts/AudioCaptureAnalyzer.gd").new()
	var profile = load("res://scripts/InstrumentPitchProfile.gd").new()
	profile.notes.assign(RUNTIME_PROFILE_NOTES)
	var freqs: Array[float] = []
	var mappings: Array[int] = []
	for note in RUNTIME_PROFILE_NOTES:
		freqs.append(NOTE_FREQS[note])
		mappings.append(NOTE_TO_STRING[note])
	profile.frequencies = PackedFloat32Array(freqs)
	profile.physical_mappings = mappings
	profile.min_frequency = 180.0
	profile.max_frequency = 1900.0
	profile.volume_threshold_db = -58.0
	profile.cents_tolerance = 35.0
	profile.is_plucked_instrument = true
	analyzer.pitch_profile = profile
	analyzer.min_frequency = 180.0
	analyzer.max_frequency = 1900.0
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

func _silence(count: int) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(count)
	return samples

func _stream_with_shifted_pluck(frequency: float, silence_samples: int, pluck_samples: int) -> PackedFloat32Array:
	var samples := _silence(silence_samples)
	samples.append_array(_plucked_tone(frequency, pluck_samples))
	return samples

func _count_onsets(analyzer: AudioCaptureAnalyzer, stream: PackedFloat32Array, frame_size: int) -> int:
	var onset_count := 0
	var offset := 0
	while offset < stream.size():
		var frame_end := mini(offset + frame_size, stream.size())
		if analyzer._detect_onset(stream.slice(offset, frame_end)):
			onset_count += 1
		offset = frame_end
	return onset_count

func _split_frames(stream: PackedFloat32Array, frame_size: int) -> Array[PackedFloat32Array]:
	var frames: Array[PackedFloat32Array] = []
	var offset := 0
	while offset < stream.size():
		var frame_end := mini(offset + frame_size, stream.size())
		frames.append(stream.slice(offset, frame_end))
		offset = frame_end
	return frames

# Mirrors AudioCaptureAnalyzer._process exactly (headless: no audio device needed).
func _run_frames(analyzer: AudioCaptureAnalyzer, frames: Array[PackedFloat32Array]) -> Dictionary:
	var buffer := PackedFloat32Array()
	var reliable_frames := 0
	var notes_seen := {}
	var string_indices_seen := {}
	for frame in frames:
		buffer.append_array(frame)
		if buffer.size() > analyzer.INSTRUMENT_ATTACK_ANALYSIS_SAMPLES:
			buffer = buffer.slice(
				buffer.size() - analyzer.INSTRUMENT_ATTACK_ANALYSIS_SAMPLES
			)
		analyzer._analysis_buffer = buffer

		var db := analyzer._calculate_amplitude_db(frame)
		analyzer.current_amplitude_db = db
		var is_onset := analyzer._detect_onset(frame)
		var profile_plucked: bool = analyzer.pitch_profile != null and analyzer.pitch_profile.is_plucked_instrument
		if db <= analyzer.volume_threshold_db:
			if profile_plucked and analyzer._instrument_attack_candidate_active:
				analyzer._update_instrument_sound_gate(frame, false, 0.016)
			analyzer._handle_silence(0.016)
			continue

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
			if analyzer.onset_detected and analyzer.time_since_onset >= 0.03 and analyzer.time_since_onset <= 0.25:
				if not analyzer.pitch_estimation_done:
					raw_pitch = analyzer._estimate_pitch(frame)
					if raw_pitch > 0.0 and analyzer.current_pitch_is_reliable:
						analyzer.pitch_estimation_done = true
		else:
			raw_pitch = analyzer._estimate_pitch(frame)

		if raw_pitch > 0.0:
			analyzer._update_reliable_pitch(raw_pitch)
		if profile_plucked and not analyzer.has_recent_dan_tranh_attack() \
				and not analyzer._instrument_attack_candidate_active:
			analyzer._clear_pitch_detection()

		if analyzer.current_pitch_is_reliable and analyzer.current_pitch > 0.0 \
				and analyzer.pitch_profile != null \
				and (not profile_plucked or analyzer.has_recent_dan_tranh_attack()):
			reliable_frames += 1
			var mapped: Dictionary = analyzer.pitch_profile.match_pitch(analyzer.current_pitch)
			if mapped.get("is_match", false):
				var name: String = mapped.get("note_name", "")
				var string_index := int(mapped.get("string_index", -1))
				notes_seen[name] = notes_seen.get(name, 0) + 1
				string_indices_seen[string_index] = string_indices_seen.get(string_index, 0) + 1

	return {
		"reliable_frames": reliable_frames,
		"notes_seen": notes_seen,
		"string_indices_seen": string_indices_seen,
	}

func _init() -> void:
	var failures: Array[String] = []

	# 0. Onset must be independent of AudioEffectCapture chunk boundaries.
	# The attack is deliberately placed at the start, middle and final samples
	# of a 735-sample render frame.
	for onset_frequency in [196.0, 440.0, 1760.0]:
		for onset_offset in [0, 320, 720, 735, 1090]:
			var onset_analyzer := _make_analyzer()
			var shifted_stream := _stream_with_shifted_pluck(
				onset_frequency, onset_offset, 4096
			)
			var onset_count := _count_onsets(onset_analyzer, shifted_stream, FRAME_SIZE)
			if onset_count != 1:
				failures.append(
					"Onset %.0f Hz lệch %d mẫu phải được nhận đúng một lần, thực tế: %d" \
					% [onset_frequency, onset_offset, onset_count]
				)
			onset_analyzer.free()

	var steady_analyzer := _make_analyzer()
	var steady_stream := _sine_tone(440.0, FRAME_SIZE * 12)
	var steady_onsets := _count_onsets(steady_analyzer, steady_stream, FRAME_SIZE)
	if steady_onsets > 1:
		failures.append("Âm ngân ổn định tạo onset lặp: %d" % steady_onsets)
	steady_analyzer.free()

	# Two real attacks about 70 ms apart must remain distinct for Á/Vê.
	var rapid_onset_analyzer := _make_analyzer()
	var rapid_onset_stream := _plucked_tone(440.0, 3072)
	rapid_onset_stream.append_array(_plucked_tone(523.25, 4096))
	var rapid_onset_count := _count_onsets(
		rapid_onset_analyzer, rapid_onset_stream, FRAME_SIZE
	)
	if rapid_onset_count != 2:
		failures.append(
			"Hai lần gảy cách nhau khoảng 70 ms phải tạo 2 onset, thực tế: %d" \
			% rapid_onset_count
		)
	rapid_onset_analyzer.free()

	# The complete timbre/pitch flow must also survive an attack located at the
	# end of a capture frame, after collecting the full 4096-sample candidate.
	var boundary_flow_analyzer := _make_analyzer()
	var boundary_flow_stream := _stream_with_shifted_pluck(440.0, 720, 7000)
	var boundary_flow_result := _run_frames(
		boundary_flow_analyzer,
		_split_frames(boundary_flow_stream, FRAME_SIZE)
	)
	if not boundary_flow_result["notes_seen"].has("La2"):
		failures.append("Luồng 4096 mẫu bỏ sót La2 khi onset nằm cuối khung thu")
	boundary_flow_analyzer.free()

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
		if not result["string_indices_seen"].has(ALL_17_NOTES.find(note)):
			failures.append("Nốt %s không ánh xạ về đúng dây vật lý %d" % [
				note, ALL_17_NOTES.find(note) + 1
			])
		if result["notes_seen"].size() != 1 or result["string_indices_seen"].size() != 1:
			failures.append("Dây %s bị nhận lẫn sang nốt/dây khác: %s / %s" % [
				note, result["notes_seen"], result["string_indices_seen"]
			])

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

	# 5. Single-shot fallback must resolve every physical string exactly, including
	#    normal acoustic tuning drift, while still rejecting voice and clicks.
	var bow_analyzer := _make_analyzer()
	for string_index in ALL_17_NOTES.size():
		var expected_note: String = ALL_17_NOTES[string_index]
		for tuning_cents in [-30.0, 0.0, 30.0]:
			var tuned_frequency: float = float(NOTE_FREQS[expected_note]) \
				* pow(2.0, tuning_cents / 1200.0)
			var pluck_buf: PackedFloat32Array = _plucked_tone(tuned_frequency, 4096)
			var detected_note: Dictionary = bow_analyzer.detect_dan_tranh_note(
				pluck_buf, SAMPLE_RATE
			)
			if detected_note.get("note_name", "None") != expected_note \
					or int(detected_note.get("string_index", -1)) != string_index:
				failures.append(
					"Single-shot dây %d %s lệch %+.0f cents nhận thành %s/dây %d" % [
						string_index + 1,
						expected_note,
						tuning_cents,
						detected_note.get("note_name", "None"),
						int(detected_note.get("string_index", -1)) + 1,
					]
				)
	var voiced_buf: PackedFloat32Array = _sine_tone(440.0, 4096)
	if not bow_analyzer.detect_dan_tranh_note(voiced_buf, SAMPLE_RATE).is_empty():
		failures.append("Single-shot nhận nhầm nốt bền (hum 440 Hz)")
	var click_buf: PackedFloat32Array = _noise_burst(0.05)
	if not bow_analyzer.detect_dan_tranh_note(click_buf, SAMPLE_RATE).is_empty():
		failures.append("Single-shot nhận nhầm tiếng click/gõ")
	bow_analyzer._clear_pitch_detection()
	for stable_frame in 4:
		bow_analyzer._update_reliable_pitch(440.0)
	bow_analyzer.instrument_gate_open = true
	var stale_buffer_result: Dictionary = bow_analyzer.detect_dan_tranh_note(
		_silence(4096), SAMPLE_RATE
	)
	if stale_buffer_result.get("note_name", "None") != "La2" \
			or int(stale_buffer_result.get("string_index", -1)) != 6:
		failures.append("Pitch La2 đã xác nhận bị mất khi transient rời rolling buffer")
	bow_analyzer.instrument_gate_open = false

	# 6. Á accepts only instrument-validated attack events, then checks distinct
	#    strings, covered range, direction and timing continuity independently.
	var lesson = load("res://scripts/LessonDanTranh.gd").new()
	var validated_event := {
		"is_match": true,
		"instrument_validated": true,
		"instrument_confidence": 82.0,
		"attack_generation": 10,
		"attack_time_msec": 1000,
		"string_index": 16
	}
	if not lesson._is_validated_dan_tranh_rapid_attack(validated_event):
		failures.append("Á loại nhầm tiếng gảy đã qua bộ lọc tiếng đàn")
	var unfiltered_event := validated_event.duplicate()
	unfiltered_event["instrument_validated"] = false
	if lesson._is_validated_dan_tranh_rapid_attack(unfiltered_event):
		failures.append("Á nhận sự kiện chưa qua bộ lọc tiếng đàn")

	var down_strings: Array[int] = [16, 14, 12, 10, 8, 6, 4]
	var down_times: Array[float] = [1.00, 1.12, 1.24, 1.36, 1.48, 1.60, 1.72]
	var down_result: Dictionary = lesson._analyze_glissando_gesture(down_strings, down_times, "down")
	if not down_result.get("success", false):
		failures.append("Á xuống hợp lệ không vượt qua đủ dây/phạm vi/hướng/liên tục")

	var too_few_strings: Array[int] = [16, 13, 10, 7, 4]
	var too_few_times: Array[float] = [1.00, 1.12, 1.24, 1.36, 1.48]
	if lesson._analyze_glissando_gesture(too_few_strings, too_few_times, "down").get("success", false):
		failures.append("Á vẫn đúng khi chưa đủ số dây khác nhau")

	var narrow_strings: Array[int] = [12, 11, 10, 9, 8, 7]
	var narrow_times: Array[float] = [1.00, 1.10, 1.20, 1.30, 1.40, 1.50]
	if lesson._analyze_glissando_gesture(narrow_strings, narrow_times, "down").get("success", false):
		failures.append("Á vẫn đúng khi phạm vi dây quá hẹp")

	var wrong_direction := down_strings.duplicate()
	wrong_direction.reverse()
	if lesson._analyze_glissando_gesture(wrong_direction, down_times, "down").get("success", false):
		failures.append("Á xuống vẫn đúng khi chuỗi đi ngược hướng")

	var broken_times: Array[float] = [1.00, 1.12, 1.24, 1.62, 1.74, 1.86, 1.98]
	var broken_result: Dictionary = lesson._analyze_glissando_gesture(down_strings, broken_times, "down")
	if broken_result.get("success", false) or broken_result.get("continuous", true):
		failures.append("Á vẫn đúng khi khoảng nghỉ giữa hai tiếng gảy quá dài")
	var skipped_strings: Array[int] = [16, 11, 10, 9, 8, 7, 4]
	var skipped_result: Dictionary = lesson._analyze_glissando_gesture(skipped_strings, down_times, "down")
	if skipped_result.get("success", false) or skipped_result.get("continuous", true):
		failures.append("Á vẫn đúng khi bộ nhận bỏ cách quá nhiều dây liền nhau")

	var round_strings: Array[int] = [16, 14, 12, 10, 8, 6, 4, 6, 8, 10, 12, 14, 16]
	var round_times: Array[float] = []
	for i in round_strings.size():
		round_times.append(2.0 + float(i) * 0.12)
	if not lesson._analyze_glissando_gesture(round_strings, round_times, "round").get("success", false):
		failures.append("Á vòng hợp lệ không được nhận")

	# 7. Vê requires one validated generation per attack and independently checks
	#    target strings, speed, regularity and the longest pause.
	var tremolo_strings: Array[int] = []
	var tremolo_times: Array[float] = []
	var tremolo_generations: Array[int] = []
	for i in 12:
		tremolo_strings.append(2)
		tremolo_times.append(3.0 + float(i) * 0.20)
		tremolo_generations.append(30 + i)
	var allowed_single: Array[int] = [2]
	var single_tremolo: Dictionary = lesson._analyze_tremolo_sequence(
		tremolo_strings, tremolo_times, tremolo_generations, "single", allowed_single, 0
	)
	if not single_tremolo.get("success", false):
		failures.append("Vê một dây đúng, nhanh và đều không được nhận")

	var duplicate_generation: Array[int] = tremolo_generations.duplicate()
	duplicate_generation[6] = duplicate_generation[5]
	var duplicate_result: Dictionary = lesson._analyze_tremolo_sequence(
		tremolo_strings, tremolo_times, duplicate_generation, "single", allowed_single, 0
	)
	if duplicate_result.get("success", false) or duplicate_result.get("all_attacks_valid", true):
		failures.append("Vê tính một onset tiếng đàn lặp lại thành hai lần gảy")

	var wrong_tremolo_strings: Array[int] = tremolo_strings.duplicate()
	wrong_tremolo_strings[5] = 5
	var wrong_tremolo: Dictionary = lesson._analyze_tremolo_sequence(
		wrong_tremolo_strings, tremolo_times, tremolo_generations, "single", allowed_single, 0
	)
	if wrong_tremolo.get("success", false) or wrong_tremolo.get("correct_strings", true):
		failures.append("Vê vẫn đúng khi có lần gảy sai dây")

	var pause_times: Array[float] = tremolo_times.duplicate()
	for i in range(6, pause_times.size()):
		pause_times[i] += 0.36
	var pause_result: Dictionary = lesson._analyze_tremolo_sequence(
		tremolo_strings, pause_times, tremolo_generations, "single", allowed_single, 0
	)
	if pause_result.get("success", false) or float(pause_result.get("max_gap", 0.0)) <= 0.34:
		failures.append("Vê vẫn đúng khi có khoảng nghỉ quá dài")
	var slow_times: Array[float] = []
	for i in tremolo_times.size():
		slow_times.append(3.0 + float(i) * 0.30)
	var slow_result: Dictionary = lesson._analyze_tremolo_sequence(
		tremolo_strings, slow_times, tremolo_generations, "single", allowed_single, 0
	)
	if slow_result.get("success", false) or float(slow_result.get("rate", 99.0)) >= 3.5:
		failures.append("Vê vẫn đúng khi tốc độ thấp hơn yêu cầu")

	var uneven_times: Array[float] = [3.00]
	for i in 12:
		var uneven_interval := 0.08 if i % 2 == 0 else 0.32
		uneven_times.append(uneven_times.back() + uneven_interval)
	var uneven_strings: Array[int] = []
	var uneven_generations: Array[int] = []
	for i in uneven_times.size():
		uneven_strings.append(2)
		uneven_generations.append(60 + i)
	var uneven_result: Dictionary = lesson._analyze_tremolo_sequence(
		uneven_strings, uneven_times, uneven_generations, "single", allowed_single, 0
	)
	if uneven_result.get("success", false) or float(uneven_result.get("regularity", 1.0)) >= 0.62:
		failures.append("Vê vẫn đúng khi nhịp gảy không đều")

	var octave_strings: Array[int] = []
	for i in tremolo_times.size():
		octave_strings.append(2 if i % 2 == 0 else 7)
	var allowed_octave: Array[int] = [2, 7]
	var octave_result: Dictionary = lesson._analyze_tremolo_sequence(
		octave_strings, tremolo_times, tremolo_generations, "octave", allowed_octave, 0
	)
	if not octave_result.get("success", false):
		failures.append("Vê quãng tám luân phiên đúng hai dây không được nhận")
	var wrong_attack_result: Dictionary = lesson._analyze_tremolo_sequence(
		tremolo_strings, tremolo_times, tremolo_generations, "single", allowed_single, 1
	)
	if wrong_attack_result.get("success", false) or wrong_attack_result.get("correct_strings", true):
		failures.append("Vê vẫn hoàn thành sau một lần tấn công sai dây")
	lesson.free()

	if failures.is_empty():
		print("PASS: filtered plucks validate Á and Vê timing/string technique")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)
