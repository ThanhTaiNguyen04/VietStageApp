extends Control

class_name AudioCaptureAnalyzer

signal dan_tranh_note_started(note: Dictionary)
signal dan_tranh_note_ended(note: Dictionary)
# Emitted for every distinct string attack while rapid tracking is enabled.
# Unlike dan_tranh_note_started, repeated attacks on the same string are kept;
# technique lessons such as tremolo need their timing information.
signal dan_tranh_rapid_attack(note: Dictionary)

# Styling colors
const C_JADE        := Color(0.18, 0.62, 0.42, 1.0)
const C_GOLD        := Color(0.95, 0.72, 0.18, 1.0)
const C_GOLD_LIGHT  := Color(1.00, 0.87, 0.45, 1.0)
const C_CREAM       := Color(1.00, 0.97, 0.88, 1.0)

var _effect: AudioEffectCapture
var _record_effect: AudioEffectRecord
var _spectrum: AudioEffectSpectrumAnalyzerInstance
var _bus_index := -1
var _sample_history := PackedFloat32Array()
const MAX_SAMPLES := 180

# Real-time state metrics
var current_pitch := 0.0
var current_pitch_is_reliable := false
var current_pitch_confidence := 0.0
var current_amplitude_db := -80.0
var current_tone_quality := 100.0
var current_breath_purity := 100.0
var current_composite_score := 100.0
var recent_scores_history : Array[float] = []
var difficulty_tolerance_scale := 1.0
var analysis_suspended := false

var _analyzer: RefCounted = null

# Dynamic configurations for pitch detection and noise gating
var min_frequency := 140.0:
	set(val):
		min_frequency = val
		_update_hp_cutoff()
var max_frequency := 4200.0
var volume_threshold_db := -55.0

# Instrument Profile (Phase 1)
var pitch_profile: Resource = null

# Technique lessons such as đàn-tranh glissando need to follow a fast pitch
# trajectory instead of waiting for one isolated pluck to finish. This flag is
# enabled only by that lesson, so normal note exercises keep their stricter gate.
var rapid_sequence_mode := false
var _rapid_attack_pending := false
var _rapid_attack_pending_elapsed := 0.0
var _rapid_attack_last_emit_msec := -1000
const RAPID_ATTACK_REFRACTORY_MSEC := 65
const RAPID_ATTACK_PITCH_WINDOW := 0.18

# Keeps estimating the fundamental throughout a sustained note so technique
# lessons can measure periodic pitch movement (rung dây) after the attack.
var contour_tracking_mode := false

# Shared đàn-tranh timbre gate. Every scoring mode must first observe a real
# plucked-string attack before pitch data is exposed to the lesson.
var instrument_gate_open := false
var current_instrument_confidence := 0.0
var _instrument_gate_string_index := -1
var _instrument_gate_note_name := ""
var _instrument_gate_generation := 0
var _instrument_gate_elapsed := 0.0
var _instrument_gate_silence_elapsed := 0.0
var _instrument_attack_candidate_active := false
var _instrument_attack_candidate := PackedFloat32Array()
var _instrument_last_candidate_msec := -1000
const INSTRUMENT_ATTACK_ANALYSIS_SAMPLES := 4096
const INSTRUMENT_GATE_NORMAL_SEC := 0.65
const INSTRUMENT_GATE_CONTOUR_SEC := 7.0
const INSTRUMENT_GATE_SILENCE_SEC := 0.35
const INSTRUMENT_MIN_ATTACK_RATIO := 1.18
const INSTRUMENT_MIN_DECAY_DB := 2.0
const INSTRUMENT_MIN_LATE_DECAY_DB := 0.75
const INSTRUMENT_MIN_TAIL_RATIO := 0.04
const INSTRUMENT_MIN_PERIODICITY := 18.0
const INSTRUMENT_MIN_STRING_TONALITY := 0.055
const INSTRUMENT_MIN_CREST_FACTOR := 1.35
const DAN_TRANH_GATE_FREQUENCIES: Array[float] = [
	196.00, 220.00, 261.63, 293.66, 329.63, 392.00, 440.00,
	523.25, 587.33, 659.25, 783.99, 880.00, 1046.50, 1174.66,
	1318.51, 1567.98, 1760.00
]
const DAN_TRANH_GATE_TUNING_OFFSETS: Array[float] = [
	-0.03, -0.025, -0.02, -0.015, -0.01, -0.005,
	0.0,
	0.005, 0.01, 0.015, 0.02, 0.025, 0.03
]

# Calibration (Phase 1)
var calibration_active := false
var calibration_db_samples: Array[float] = []

# Pluck state machine for plucked instruments like Dan Tranh (Phase 2)
var pluck_locked := false
var onset_detected := false
var pitch_estimation_done := false
var time_since_onset := 0.0
var pluck_release_time := 0.0

# Stateful onset detector. AudioEffectCapture returns chunks aligned to render
# frames, not to the instant a string is plucked. Keep fixed-size energy blocks
# across calls so an attack can start anywhere inside (or across) a chunk.
var _onset_sample_buffer := PackedFloat32Array()
var _onset_previous_rms := 0.0
var _onset_noise_floor_rms := 0.000001
var _onset_refractory_remaining := 0.0
var _onset_state_initialized := false
var _last_onset_sample_offset := 0
const ONSET_BLOCK_SAMPLES := 256
const ONSET_PRE_ROLL_SAMPLES := 128
const ONSET_MIN_RISE_RATIO := 1.55
const ONSET_NOISE_FLOOR_RATIO := 2.20
const ONSET_REFRACTORY_SEC := 0.055
const ONSET_NOISE_FLOOR_SMOOTHING := 0.08

var _mic_player: AudioStreamPlayer = null
var _time_since_last_pitch := 0.0
var _analysis_buffer := PackedFloat32Array()
var _pitch_candidates: Array[float] = []
const PITCH_STABILITY_FRAMES := 4
const PITCH_STABILITY_CENTS := 24.0
const PITCH_JUMP_CENTS := 80.0

var current_dan_tranh_note: Dictionary = {}
var _dan_tranh_note_active := false
var _dan_tranh_note_duration := 0.0
var _dan_tranh_release_elapsed := 0.0

func _ready() -> void:
	if ClassDB.class_exists("AudioAnalyzer"):
		_analyzer = ClassDB.instantiate("AudioAnalyzer")
		
	_setup_audio_bus()
	
	for i in range(MAX_SAMPLES):
		_sample_history.append(0.0)

func _setup_audio_bus() -> void:
	_bus_index = AudioServer.get_bus_index("Record")
	if _bus_index == -1:
		_bus_index = AudioServer.bus_count
		AudioServer.add_bus(_bus_index)
		AudioServer.set_bus_name(_bus_index, "Record")
	
	AudioServer.set_bus_mute(_bus_index, false)
	AudioServer.set_bus_volume_db(_bus_index, -80.0)
	
	# 1. Thêm bộ lọc tần số thấp (HighPassFilter) để cắt tạp âm quạt/gió/hơi thở
	var hp_idx := -1
	for i in range(AudioServer.get_bus_effect_count(_bus_index)):
		if AudioServer.get_bus_effect(_bus_index, i) is AudioEffectHighPassFilter:
			hp_idx = i
			break
	if hp_idx == -1:
		var hp = AudioEffectHighPassFilter.new()
		hp.cutoff_hz = clampf(min_frequency * 0.8, 20.0, 300.0)
		AudioServer.add_bus_effect(_bus_index, hp, 0)
	else:
		_update_hp_cutoff()
		
	# 2. Thêm bộ lọc tần số cao (LowPassFilter) để cắt tiếng xì/rè
	var lp_idx := -1
	for i in range(AudioServer.get_bus_effect_count(_bus_index)):
		if AudioServer.get_bus_effect(_bus_index, i) is AudioEffectLowPassFilter:
			lp_idx = i
			break
	if lp_idx == -1:
		var lp = AudioEffectLowPassFilter.new()
		lp.cutoff_hz = 4000.0 # Cắt các tần số cao không cần thiết
		AudioServer.add_bus_effect(_bus_index, lp, 1)

	# 3. Add AudioEffectCapture if not already present
	var effect_index := -1
	for i in range(AudioServer.get_bus_effect_count(_bus_index)):
		if AudioServer.get_bus_effect(_bus_index, i) is AudioEffectCapture:
			effect_index = i
			break
			
	if effect_index == -1:
		_effect = AudioEffectCapture.new()
		_effect.buffer_length = 0.5 # 500ms buffer
		AudioServer.add_bus_effect(_bus_index, _effect) # Không ép index 0 nữa để nó nằm sau filter
	else:
		_effect = AudioServer.get_bus_effect(_bus_index, effect_index) as AudioEffectCapture
		
	var rec_idx := -1
	for i in range(AudioServer.get_bus_effect_count(_bus_index)):
		if AudioServer.get_bus_effect(_bus_index, i) is AudioEffectRecord:
			rec_idx = i
			break
			
	if rec_idx == -1:
		_record_effect = AudioEffectRecord.new()
		AudioServer.add_bus_effect(_bus_index, _record_effect)
	else:
		_record_effect = AudioServer.get_bus_effect(_bus_index, rec_idx) as AudioEffectRecord
		
	var spec_idx := -1
	for i in range(AudioServer.get_bus_effect_count(_bus_index)):
		if AudioServer.get_bus_effect(_bus_index, i) is AudioEffectSpectrumAnalyzer:
			spec_idx = i
			break
			
	if spec_idx == -1:
		var spectrum_effect = AudioEffectSpectrumAnalyzer.new()
		spectrum_effect.buffer_length = 0.2
		spectrum_effect.tap_back_pos = 0.05
		spectrum_effect.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_4096
		AudioServer.add_bus_effect(_bus_index, spectrum_effect)
		spec_idx = AudioServer.get_bus_effect_count(_bus_index) - 1
		
	_spectrum = AudioServer.get_bus_effect_instance(_bus_index, spec_idx) as AudioEffectSpectrumAnalyzerInstance

	_mic_player = AudioStreamPlayer.new()
	_mic_player.stream = AudioStreamMicrophone.new()
	_mic_player.bus = "Record"
	add_child(_mic_player)

# Start / Stop noise calibration
func start_calibration() -> void:
	calibration_active = true
	calibration_db_samples.clear()

func finish_calibration() -> float:
	calibration_active = false
	if calibration_db_samples.is_empty():
		return volume_threshold_db
	
	var sum := 0.0
	var max_val := -80.0
	for val in calibration_db_samples:
		sum += val
		if val > max_val:
			max_val = val
	var avg = sum / calibration_db_samples.size()
	
	# Set volume threshold 8.0 dB above average noise floor, bounded to safe limits
	volume_threshold_db = clampf(avg + 8.0, -60.0, -42.0)
	print("Calibrated background noise. Avg: %.1f dB, threshold set to: %.1f dB" % [avg, volume_threshold_db])
	return volume_threshold_db


func set_analysis_suspended(suspended: bool) -> void:
	analysis_suspended = suspended
	_reset_live_analysis_state()
	if _effect:
		_effect.clear_buffer()


func _reset_live_analysis_state() -> void:
	_clear_pitch_detection()
	current_amplitude_db = -80.0
	_analysis_buffer.clear()
	_rapid_attack_pending = false
	_rapid_attack_pending_elapsed = 0.0
	pluck_locked = false
	onset_detected = false
	pitch_estimation_done = false
	time_since_onset = 0.0
	pluck_release_time = 0.0
	_dan_tranh_note_active = false
	_dan_tranh_note_duration = 0.0
	_dan_tranh_release_elapsed = 0.0
	current_dan_tranh_note = {}
	_reset_onset_detector()
	_close_instrument_gate()
	for i in range(_sample_history.size()):
		_sample_history[i] = 0.0


func _discard_captured_samples() -> void:
	if not _effect:
		return
	var frames_available := _effect.get_frames_available()
	if frames_available > 0:
		_effect.get_buffer(frames_available)

# ─── Standardised 7-Step DSP Pipeline ───
func _process(delta: float) -> void:
	if _mic_player and not _mic_player.playing:
		_mic_player.play()
	if not _effect: return
	if analysis_suspended:
		# Keep draining the capture effect so cô Mai's speech cannot remain buffered
		# and be analyzed immediately after the post-TTS cooldown.
		_discard_captured_samples()
		return
	
	# Step 1: Capture
	var samples = _capture_samples()
	if samples.is_empty(): return
	
	# Step 2: Noise Gate (with calibration monitoring)
	current_amplitude_db = _calculate_amplitude_db(samples)
	if calibration_active:
		calibration_db_samples.append(current_amplitude_db)

	# Always feed the stateful onset detector, including quiet chunks. Those
	# chunks establish the live microphone floor and preserve continuity across
	# AudioEffectCapture frame boundaries.
	var is_onset := _detect_onset(samples)
	var profile_plucked = pitch_profile != null and pitch_profile.is_plucked_instrument
	
	var gate_open = current_amplitude_db > volume_threshold_db
	if not gate_open:
		# Once an attack starts, keep its natural decay in the 4096-sample
		# candidate even when later chunks fall below the live noise gate.
		if profile_plucked and _instrument_attack_candidate_active:
			_update_instrument_sound_gate(samples, false, delta)
		_rapid_attack_pending = false
		_rapid_attack_pending_elapsed = 0.0
		_handle_silence(delta)
		_update_sample_history(samples)
		return
	
	# Step 3: Onset Detection (plucked instrument logic)
	if profile_plucked:
		_update_instrument_sound_gate(samples, is_onset, delta)
	if rapid_sequence_mode:
		if _rapid_attack_pending:
			_rapid_attack_pending_elapsed += delta
			if _rapid_attack_pending_elapsed > RAPID_ATTACK_PITCH_WINDOW:
				_rapid_attack_pending = false
	
	if profile_plucked and not rapid_sequence_mode and not contour_tracking_mode:
		if is_onset and (not pluck_locked or pitch_estimation_done or time_since_onset > 0.15):
			if _dan_tranh_note_active:
				_finish_dan_tranh_note()
			onset_detected = true
			time_since_onset = 0.0
			pitch_estimation_done = false
			pluck_locked = true
			_clear_pitch_detection()
		
		if onset_detected:
			time_since_onset += delta
	
	# Step 4: Pitch Estimation (estimate every frame inside the 30-250 ms onset
	# window so the stability gate can accumulate PITCH_STABILITY_FRAMES candidates)
	var raw_pitch := 0.0
	if rapid_sequence_mode or contour_tracking_mode:
		raw_pitch = _estimate_pitch(samples)
	elif profile_plucked:
		# The timbre gate needs about 4096 samples (92.9 ms at 44.1 kHz).
		# Keep this open long enough to stabilize after that gate is validated.
		if onset_detected and time_since_onset >= 0.03 and time_since_onset <= 0.25:
			if not pitch_estimation_done:
				raw_pitch = _estimate_pitch(samples)
				if raw_pitch > 0.0 and current_pitch_is_reliable:
					pitch_estimation_done = true
	else:
		raw_pitch = _estimate_pitch(samples)
	
	# Step 5: Stabilization
	if raw_pitch > 0.0:
		_update_reliable_pitch(raw_pitch)
	if profile_plucked and not instrument_gate_open:
		# Do not expose stable vocal/noise pitch while no valid đàn-tranh attack
		# has opened the shared instrument gate.
		_clear_pitch_detection()
	
	# Step 6: Note Mapping (Standardised core note mapping using InstrumentPitchProfile)
	var mapped_note := {}
	if current_pitch_is_reliable and current_pitch > 0.0 and pitch_profile != null:
		mapped_note = pitch_profile.match_pitch(current_pitch)
	if instrument_gate_open and _instrument_gate_string_index < 0 \
			and not mapped_note.is_empty() and mapped_note.get("is_match", false):
		# Bind the gate to the first reliable pitch produced by this accepted
		# string attack. Contour lessons can then prove that a bend still belongs
		# to the original pluck instead of accepting a later vocal glide.
		_instrument_gate_string_index = int(mapped_note.get("string_index", -1))
		_instrument_gate_note_name = str(mapped_note.get("note_name", ""))
	if rapid_sequence_mode and _rapid_attack_pending \
			and not mapped_note.is_empty() and mapped_note.get("is_match", false):
		var rapid_note := mapped_note.duplicate()
		rapid_note["attack_time_msec"] = Time.get_ticks_msec()
		rapid_note["amplitude_db"] = current_amplitude_db
		# This event exists only after analyze_dan_tranh_sound() accepted the
		# onset. Carry that proof with the event so rapid-technique scorers never
		# confuse a continuous vocal pitch estimate with a plucked string.
		rapid_note["instrument_validated"] = true
		rapid_note["instrument_confidence"] = current_instrument_confidence
		rapid_note["attack_generation"] = _instrument_gate_generation
		dan_tranh_rapid_attack.emit(rapid_note)
		_rapid_attack_last_emit_msec = Time.get_ticks_msec()
		_rapid_attack_pending = false
		_rapid_attack_pending_elapsed = 0.0
	
	# Step 7: Lesson Scoring & Tracking
	if rapid_sequence_mode or contour_tracking_mode:
		_update_continuous_note_tracking(mapped_note, delta)
	elif profile_plucked:
		_update_dan_tranh_tracking_plucked(mapped_note, delta)
	else:
		_update_continuous_note_tracking(mapped_note, delta)
		
	_update_sample_history(samples)

func _capture_samples() -> PackedFloat32Array:
	var samples_available = _effect.get_frames_available()
	var mono_samples := PackedFloat32Array()
	if samples_available > 0:
		var frames = _effect.get_buffer(samples_available)
		if frames.size() > 0:
			mono_samples.resize(frames.size())
			for i in range(frames.size()):
				mono_samples[i] = (frames[i].x + frames[i].y) * 0.5
				
			for val in mono_samples:
				_analysis_buffer.append(val)
			if _analysis_buffer.size() > INSTRUMENT_ATTACK_ANALYSIS_SAMPLES:
				var excess = _analysis_buffer.size() - INSTRUMENT_ATTACK_ANALYSIS_SAMPLES
				_analysis_buffer = _analysis_buffer.slice(excess)
	return mono_samples

func _calculate_amplitude_db(samples: PackedFloat32Array) -> float:
	if _analyzer:
		return _analyzer.calculate_peak_db(samples)
	return _calculate_peak_db_gdscript(samples)

func _detect_onset(samples: PackedFloat32Array) -> bool:
	if samples.is_empty():
		return false

	var buffered_sample_count := _onset_sample_buffer.size()
	_onset_sample_buffer.append_array(samples)
	_last_onset_sample_offset = 0
	var sample_rate := maxf(AudioServer.get_mix_rate(), 1.0)
	var threshold_rms := pow(10.0, volume_threshold_db / 20.0) * 0.5
	var onset_found := false
	var consumed := 0

	while _onset_sample_buffer.size() - consumed >= ONSET_BLOCK_SAMPLES:
		var energy := 0.0
		for i in range(consumed, consumed + ONSET_BLOCK_SAMPLES):
			var value := float(_onset_sample_buffer[i])
			energy += value * value
		var block_rms := sqrt(energy / float(ONSET_BLOCK_SAMPLES))
		var block_duration := float(ONSET_BLOCK_SAMPLES) / sample_rate
		_onset_refractory_remaining = maxf(
			0.0, _onset_refractory_remaining - block_duration
		)

		if not _onset_state_initialized:
			# A lesson can start while a pluck is already entering the first capture
			# chunk. Use the configured gate as a conservative initial reference
			# instead of discarding that first attack.
			_onset_noise_floor_rms = maxf(
				0.000001, minf(block_rms, threshold_rms * 0.5)
			)
			_onset_previous_rms = maxf(
				_onset_noise_floor_rms, threshold_rms * 0.25
			)
			_onset_state_initialized = true

		var reference_rms := maxf(
			_onset_previous_rms,
			maxf(_onset_noise_floor_rms, threshold_rms * 0.25)
		)
		var rise_ratio := block_rms / maxf(reference_rms, 0.000001)
		var above_input_gate := block_rms >= threshold_rms
		var above_noise_floor := block_rms >= (
			_onset_noise_floor_rms * ONSET_NOISE_FLOOR_RATIO
		)

		if not onset_found \
				and _onset_refractory_remaining <= 0.0 \
				and above_input_gate \
				and above_noise_floor \
				and rise_ratio >= ONSET_MIN_RISE_RATIO:
			onset_found = true
			_onset_refractory_remaining = ONSET_REFRACTORY_SEC
			# Translate the fixed-block position back to this capture chunk. A
			# short pre-roll preserves the transient used by the timbre classifier.
			_last_onset_sample_offset = clampi(
				consumed - buffered_sample_count - ONSET_PRE_ROLL_SAMPLES,
				0,
				samples.size()
			)

		# Learn only quiet/near-floor blocks. A loud sustained note must not raise
		# the floor and hide the attack of the next string.
		if block_rms <= maxf(threshold_rms, _onset_noise_floor_rms * 1.5):
			_onset_noise_floor_rms = lerpf(
				_onset_noise_floor_rms,
				maxf(block_rms, 0.000001),
				ONSET_NOISE_FLOOR_SMOOTHING
			)
		_onset_previous_rms = block_rms
		consumed += ONSET_BLOCK_SAMPLES

	if consumed > 0:
		_onset_sample_buffer = _onset_sample_buffer.slice(consumed)
	return onset_found


func _reset_onset_detector() -> void:
	_onset_sample_buffer.clear()
	_onset_previous_rms = 0.0
	_onset_noise_floor_rms = 0.000001
	_onset_refractory_remaining = 0.0
	_onset_state_initialized = false
	_last_onset_sample_offset = 0

func _estimate_pitch(samples: PackedFloat32Array) -> float:
	var min_f = pitch_profile.min_frequency if pitch_profile else min_frequency
	var max_f = pitch_profile.max_frequency if pitch_profile else max_frequency
	
	if _analyzer:
		return _analyzer.analyze_pitch_yin(_analysis_buffer, AudioServer.get_mix_rate(), 0.08, min_f, max_f)
	return _detect_pitch_yin_gdscript(_analysis_buffer, AudioServer.get_mix_rate(), 0.08)

func _handle_silence(delta: float) -> void:
	_time_since_last_pitch += delta
	_clear_pitch_detection()
	current_tone_quality = lerp(current_tone_quality, 100.0, 0.5)
	current_breath_purity = lerp(current_breath_purity, 100.0, 0.5)
	if instrument_gate_open:
		_instrument_gate_silence_elapsed += delta
		if _instrument_gate_silence_elapsed >= INSTRUMENT_GATE_SILENCE_SEC:
			_close_instrument_gate()
	
	# Release pluck lock when signal level is silent (Phase 2)
	pluck_release_time += delta
	if pluck_release_time >= 0.10:
		pluck_locked = false
		onset_detected = false
		pitch_estimation_done = false
		time_since_onset = 0.0
		
	# Finish active note if silence persists
	if _dan_tranh_note_active:
		_dan_tranh_release_elapsed += delta
		if _dan_tranh_release_elapsed >= 0.10:
			_finish_dan_tranh_note()

func _update_sample_history(mono_samples: PackedFloat32Array) -> void:
	if mono_samples.is_empty(): return
	var step = max(1, mono_samples.size() / 10)
	for i in range(0, mono_samples.size(), step):
		var val = mono_samples[i]
		if _sample_history.size() > 0:
			_sample_history.remove_at(0)
		_sample_history.append(val)
	queue_redraw()

func _update_dan_tranh_tracking_plucked(detected: Dictionary, delta: float) -> void:
	pluck_release_time = 0.0 # reset silence timer
	
	if detected.is_empty() or not detected.get("is_match", false):
		return
	
	# Plucked note is tracked and emitted once per pluck
	var detected_index := int(detected.get("string_index", -1))
	if not _dan_tranh_note_active:
		_start_dan_tranh_note(detected)
	else:
		_dan_tranh_note_duration += delta
		current_dan_tranh_note.merge(detected, true)
		current_dan_tranh_note["duration_sec"] = _dan_tranh_note_duration

func _update_continuous_note_tracking(detected: Dictionary, delta: float) -> void:
	if detected.is_empty() or not detected.get("is_match", false):
		if _dan_tranh_note_active:
			_dan_tranh_release_elapsed += delta
			if _dan_tranh_release_elapsed >= 0.12:
				_finish_dan_tranh_note()
		return

	_dan_tranh_release_elapsed = 0.0
	var detected_index := int(detected.get("string_index", -1))
	var active_index := int(current_dan_tranh_note.get("string_index", -1))
	
	if not _dan_tranh_note_active:
		_start_dan_tranh_note(detected)
	elif detected_index != active_index:
		_finish_dan_tranh_note()
		_start_dan_tranh_note(detected)
	else:
		_dan_tranh_note_duration += delta
		current_dan_tranh_note.merge(detected, true)
		current_dan_tranh_note["duration_sec"] = _dan_tranh_note_duration

func _start_dan_tranh_note(note: Dictionary) -> void:
	_dan_tranh_note_active = true
	_dan_tranh_note_duration = 0.0
	_dan_tranh_release_elapsed = 0.0
	current_dan_tranh_note = note.duplicate()
	current_dan_tranh_note["duration_sec"] = 0.0
	dan_tranh_note_started.emit(current_dan_tranh_note.duplicate())

func _finish_dan_tranh_note() -> void:
	if not _dan_tranh_note_active:
		return
	current_dan_tranh_note["duration_sec"] = _dan_tranh_note_duration
	dan_tranh_note_ended.emit(current_dan_tranh_note.duplicate())
	_dan_tranh_note_active = false
	_dan_tranh_note_duration = 0.0
	_dan_tranh_release_elapsed = 0.0
	current_dan_tranh_note = {}

func _clear_pitch_detection() -> void:
	_pitch_candidates.clear()
	current_pitch = 0.0
	current_pitch_confidence = 0.0
	current_pitch_is_reliable = false

func _update_reliable_pitch(detected_pitch: float) -> void:
	var min_f = pitch_profile.min_frequency if pitch_profile else min_frequency
	var max_f = pitch_profile.max_frequency if pitch_profile else max_frequency
	var fast_tracking := rapid_sequence_mode or contour_tracking_mode
	var stability_frames := 2 if fast_tracking else PITCH_STABILITY_FRAMES
	var jump_limit := 420.0 if rapid_sequence_mode else (240.0 if contour_tracking_mode else PITCH_JUMP_CENTS)
	var stability_limit := 55.0 if rapid_sequence_mode else (85.0 if contour_tracking_mode else PITCH_STABILITY_CENTS)
	
	if detected_pitch < min_f or detected_pitch > max_f:
		_clear_pitch_detection()
		return

	if not _pitch_candidates.is_empty():
		var previous := _pitch_candidates[_pitch_candidates.size() - 1]
		var jump_cents := absf(1200.0 * log(detected_pitch / previous) / log(2.0))
		if jump_cents > jump_limit:
			_pitch_candidates.clear()

	_pitch_candidates.append(detected_pitch)
	if _pitch_candidates.size() > stability_frames:
		_pitch_candidates.pop_front()
	if _pitch_candidates.size() < stability_frames:
		current_pitch = 0.0
		current_pitch_confidence = float(_pitch_candidates.size()) / float(stability_frames)
		current_pitch_is_reliable = false
		return

	var sorted := _pitch_candidates.duplicate()
	sorted.sort()
	var middle := sorted.size() / 2
	var median: float
	if sorted.size() % 2 == 0:
		median = (float(sorted[middle - 1]) + float(sorted[middle])) * 0.5
	else:
		median = float(sorted[middle])
	var spread_cents := absf(1200.0 * log(sorted[sorted.size() - 1] / sorted[0]) / log(2.0))
	current_pitch_confidence = clampf(1.0 - spread_cents / stability_limit, 0.0, 1.0)
	current_pitch_is_reliable = spread_cents <= stability_limit
	current_pitch = median if current_pitch_is_reliable else 0.0

func get_current_dan_tranh_note() -> Dictionary:
	return current_dan_tranh_note.duplicate()


func has_recent_dan_tranh_attack() -> bool:
	return instrument_gate_open and not analysis_suspended


func get_dan_tranh_attack_identity() -> Dictionary:
	return {
		"active": has_recent_dan_tranh_attack(),
		"string_index": _instrument_gate_string_index,
		"note_name": _instrument_gate_note_name,
		"generation": _instrument_gate_generation,
		"confidence": current_instrument_confidence
	}


func _update_instrument_sound_gate(samples: PackedFloat32Array, is_onset: bool, delta: float) -> void:
	if instrument_gate_open:
		_instrument_gate_elapsed += delta
		_instrument_gate_silence_elapsed = 0.0
		var max_open_time := INSTRUMENT_GATE_CONTOUR_SEC if contour_tracking_mode else INSTRUMENT_GATE_NORMAL_SEC
		if _instrument_gate_elapsed >= max_open_time:
			_close_instrument_gate()

	var now_msec := Time.get_ticks_msec()
	var candidate_refractory := RAPID_ATTACK_REFRACTORY_MSEC if rapid_sequence_mode else 120
	if is_onset and not _instrument_attack_candidate_active \
			and now_msec - _instrument_last_candidate_msec >= candidate_refractory:
		_instrument_attack_candidate_active = true
		var candidate_start := clampi(_last_onset_sample_offset, 0, samples.size())
		_instrument_attack_candidate = samples.slice(candidate_start)
		_instrument_last_candidate_msec = now_msec
		instrument_gate_open = false
		current_instrument_confidence = 0.0
		_instrument_gate_string_index = -1
		_instrument_gate_note_name = ""
	elif _instrument_attack_candidate_active:
		_instrument_attack_candidate.append_array(samples)

	if not _instrument_attack_candidate_active:
		return
	if _instrument_attack_candidate.size() > INSTRUMENT_ATTACK_ANALYSIS_SAMPLES:
		_instrument_attack_candidate = _instrument_attack_candidate.slice(
			0, INSTRUMENT_ATTACK_ANALYSIS_SAMPLES
		)
	if _instrument_attack_candidate.size() < INSTRUMENT_ATTACK_ANALYSIS_SAMPLES:
		return

	var classification := analyze_dan_tranh_sound(
		_instrument_attack_candidate, AudioServer.get_mix_rate()
	)
	_instrument_attack_candidate_active = false
	_instrument_attack_candidate.clear()
	current_instrument_confidence = float(classification.get("confidence", 0.0))
	if classification.get("accepted", false):
		instrument_gate_open = true
		_instrument_gate_generation += 1
		_instrument_gate_string_index = -1
		_instrument_gate_note_name = ""
		_instrument_gate_elapsed = 0.0
		_instrument_gate_silence_elapsed = 0.0
		if rapid_sequence_mode and Time.get_ticks_msec() - _rapid_attack_last_emit_msec >= RAPID_ATTACK_REFRACTORY_MSEC:
			_rapid_attack_pending = true
			_rapid_attack_pending_elapsed = 0.0
	else:
		_close_instrument_gate()
		_clear_pitch_detection()


func _close_instrument_gate() -> void:
	instrument_gate_open = false
	current_instrument_confidence = 0.0
	_instrument_gate_string_index = -1
	_instrument_gate_note_name = ""
	_instrument_gate_elapsed = 0.0
	_instrument_gate_silence_elapsed = 0.0
	_instrument_attack_candidate_active = false
	_instrument_attack_candidate.clear()
	_rapid_attack_pending = false
	_rapid_attack_pending_elapsed = 0.0

# ─── GDScript Advanced AI Fallbacks ───
func _calculate_peak_db_gdscript(samples: PackedFloat32Array) -> float:
	var peak := 0.0
	for val in samples:
		var abs_val = abs(val)
		if abs_val > peak:
			max_frequency = max_frequency # dummy access
			peak = abs_val
	if peak > 0.0001:
		return 20.0 * log(peak) / log(10)
	return -80.0

func _detect_note_onset_and_duration_gdscript(samples: PackedFloat32Array, sample_rate: float, threshold_db: float) -> Dictionary:
	var result := {"is_onset": false, "duration_sec": 0.0, "peak_db": -80.0, "is_active": false}
	var size = samples.size()
	if size < 128: return result
	
	var sum_sq := 0.0
	var peak := 0.0
	for val in samples:
		var abs_v = abs(val)
		sum_sq += abs_v * abs_v
		if abs_v > peak: peak = abs_v
		
	var rms = sqrt(sum_sq / float(size))
	var peak_db = 20.0 * log(peak) / log(10) if peak > 0.0001 else -80.0
	result["peak_db"] = peak_db
	if peak_db < threshold_db: return result
	
	result["is_active"] = true
	var half = size / 2
	var e_first := 0.0
	var e_second := 0.0
	for i in range(half):
		e_first += samples[i] * samples[i]
	for i in range(half, size):
		e_second += samples[i] * samples[i]
		
	if e_first > 0.0001 and (e_first / (e_second + 0.0001)) > 2.5:
		result["is_onset"] = true
		
	var active_samples := 0
	var block := 32
	for i in range(0, size, block):
		var b_peak := 0.0
		var limit = min(size, i + block)
		for j in range(i, limit):
			b_peak = max(b_peak, abs(samples[j]))
		if b_peak > 0.01:
			active_samples += block
	result["duration_sec"] = float(active_samples) / sample_rate
	return result

func _detect_pitch_yin_gdscript(samples: PackedFloat32Array, sample_rate: float, threshold: float) -> float:
	var size = samples.size()
	var W = size / 2
	if W < 128: return 0.0
	
	var min_period = int(sample_rate / max_frequency)
	var max_period = min(W - 2, int(sample_rate / min_frequency))
	if min_period >= max_period: return 0.0
		
	var d := PackedFloat32Array()
	d.resize(max_period + 1)
	
	for tau in range(1, max_period + 1):
		var diff_sum := 0.0
		for t in range(0, W, 2):
			var diff = samples[t] - samples[t + tau]
			diff_sum += diff * diff
		d[tau] = diff_sum * 2.0
		
	var d_prime := PackedFloat32Array()
	d_prime.resize(max_period + 1)
	d_prime[0] = 1.0
	var running_sum := 0.0
	for tau in range(1, max_period + 1):
		running_sum += d[tau]
		if running_sum > 0.0:
			d_prime[tau] = d[tau] / ((1.0 / float(tau)) * running_sum)
		else:
			d_prime[tau] = 1.0
			
	var best_tau := -1
	var min_val := 1e10
	var global_min_tau := -1
	
	for tau in range(min_period, max_period + 1):
		if d_prime[tau] < threshold:
			if tau > min_period and tau < max_period:
				if d_prime[tau] < d_prime[tau - 1] and d_prime[tau] < d_prime[tau + 1]:
					best_tau = tau
					break
		if d_prime[tau] < min_val:
			min_val = d_prime[tau]
			global_min_tau = tau
			
	if best_tau == -1:
		if min_val < 0.35:
			var candidate_tau := global_min_tau
			for t in range(min_period + 1, global_min_tau / 2 + 1):
				if d_prime[t] < 0.35 and t > min_period and t < max_period:
					if d_prime[t] < d_prime[t - 1] and d_prime[t] < d_prime[t + 1]:
						var ratio = float(global_min_tau) / float(t)
						var rounded_r = round(ratio)
						if rounded_r >= 2.0 and rounded_r <= 4.0 and absf(ratio - rounded_r) < 0.15:
							candidate_tau = t
							break
			best_tau = candidate_tau
		else:
			best_tau = -1
		
	if best_tau <= 0 or best_tau >= max_period:
		return 0.0

	var precise_tau = float(best_tau)
	var alpha = d_prime[best_tau - 1]
	var beta = d_prime[best_tau]
	var gamma = d_prime[best_tau + 1]
	var denom = alpha - 2.0 * beta + gamma
	if abs(denom) > 0.0001:
		precise_tau = float(best_tau) + 0.5 * (alpha - gamma) / denom
		
	if precise_tau > 0.0:
		return sample_rate / precise_tau
	return 0.0

func _evaluate_tone_quality_gdscript(samples: PackedFloat32Array) -> float:
	var size = samples.size()
	if size < 128: return 0.0
	
	var sum_sq := 0.0
	for val in samples:
		sum_sq += val * val
	if sum_sq < 0.001: return 0.0
	
	var max_corr := 0.0
	var min_lag := 40
	var max_lag = min(size / 2, 300)
	
	for lag in range(min_lag, max_lag, 3):
		var corr := 0.0
		var sum_sq_shifted := 0.0
		for i in range(0, size - lag, 2):
			corr += samples[i] * samples[i + lag]
			sum_sq_shifted += samples[i + lag] * samples[i + lag]
		
		if sum_sq_shifted > 0.0:
			var norm_corr = corr / sqrt(sum_sq * sum_sq_shifted)
			if norm_corr > max_corr:
				max_corr = norm_corr
				
	return clamp(max_corr * 100.0, 0.0, 100.0)

func _analyze_breath_pattern_gdscript(samples: PackedFloat32Array) -> float:
	var size = samples.size()
	if size < 256: return 0.0
	
	var envelopes: Array[float] = []
	var amplitude_sum := 0.0
	var block_size := 64
	
	for i in range(0, size, block_size):
		var block_peak := 0.0
		var limit = min(size, i + block_size)
		for j in range(i, limit):
			block_peak = max(block_peak, abs(samples[j]))
		envelopes.append(block_peak)
		amplitude_sum += block_peak
		
	var avg_amp = amplitude_sum / envelopes.size()
	if avg_amp < 0.005: return 0.0
	
	var sq_diff_sum := 0.0
	for env in envelopes:
		var diff = env - avg_amp
		sq_diff_sum += diff * diff
	var variance = sq_diff_sum / envelopes.size()
	var stability_factor = max(0.0, 1.0 - (variance / (avg_amp * avg_amp + 0.0001)))
	
	var residual_energy := 0.0
	var total_energy := 0.0
	var period := 80
	for i in range(size - period):
		var periodic_diff = samples[i] - samples[i + period]
		residual_energy += periodic_diff * periodic_diff
		total_energy += samples[i] * samples[i]
		
	var purity_factor := 1.0
	if total_energy > 0.0:
		purity_factor = max(0.0, 1.0 - (residual_energy / total_energy))
		
	return clamp((0.7 * purity_factor + 0.3 * stability_factor) * 100.0, 0.0, 100.0)

func evaluate_rhythm(detected_onsets: PackedFloat32Array, reference_onsets: PackedFloat32Array, tolerance: float) -> float:
	if _analyzer:
		return _analyzer.evaluate_rhythm(detected_onsets, reference_onsets, tolerance)
	
	if detected_onsets.size() == 0 or reference_onsets.size() == 0:
		return 0.0
		
	var total_score := 0.0
	var matches := 0
	
	for det in detected_onsets:
		var min_diff := 1e10
		for ref in reference_onsets:
			var diff = abs(det - ref)
			if diff < min_diff:
				min_diff = diff
		
		if min_diff < tolerance * 2.0:
			var score = max(0.0, 100.0 * (1.0 - min_diff / tolerance))
			total_score += score
			matches += 1
			
	if matches > 0:
		var avg = total_score / float(max(detected_onsets.size(), reference_onsets.size()))
		return clamp(avg, 0.0, 100.0)
	return 0.0

func _update_hp_cutoff() -> void:
	if _bus_index == -1:
		return
	for i in range(AudioServer.get_bus_effect_count(_bus_index)):
		var effect = AudioServer.get_bus_effect(_bus_index, i)
		if effect is AudioEffectHighPassFilter:
			effect.cutoff_hz = clampf(min_frequency * 0.8, 20.0, 300.0)
			break

func calculate_composite_score(pitch_score: float, rhythm_score: float, tone_score: float, breath_score: float) -> float:
	if _analyzer:
		return _analyzer.calculate_composite_score(pitch_score, rhythm_score, tone_score, breath_score)
	return clamp(0.35 * pitch_score + 0.35 * rhythm_score + 0.15 * tone_score + 0.15 * breath_score, 0.0, 100.0)

func add_practice_score(score: float) -> void:
	recent_scores_history.append(score)
	if recent_scores_history.size() > 10:
		recent_scores_history.remove_at(0)
		
	if _analyzer:
		var float_scores := PackedFloat32Array()
		for s in recent_scores_history:
			float_scores.append(s)
		difficulty_tolerance_scale = _analyzer.adjust_difficulty(float_scores)
	else:
		difficulty_tolerance_scale = _adjust_difficulty_gdscript(recent_scores_history)

func _adjust_difficulty_gdscript(scores: Array[float]) -> float:
	if scores.size() < 3:
		return 1.0
	var sum := 0.0
	for s in scores:
		sum += s
	var avg = sum / scores.size()
	
	if avg > 88.0:
		return 1.25
	elif avg < 60.0:
		return 0.75
	return 1.0

func start_recording() -> bool:
	if _record_effect:
		_record_effect.set_recording_active(true)
		return true
	return false
	
func stop_recording() -> AudioStreamWAV:
	if _record_effect:
		_record_effect.set_recording_active(false)
		return _record_effect.get_recording()
	return null

func _draw() -> void:
	var w := size.x
	var h := size.y
	
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.04, 0.015, 0.5), true)
	var grid_color := Color(C_CREAM.r, C_CREAM.g, C_CREAM.b, 0.06)
	draw_line(Vector2(0, h / 2.0), Vector2(w, h / 2.0), grid_color, 1.5)
	
	var markers := 6
	for i in range(1, markers):
		var gx = w * (float(i) / float(markers))
		draw_line(Vector2(gx, 0), Vector2(gx, h), grid_color, 1.0)
		
	var points := PackedVector2Array()
	var size_history = _sample_history.size()
	for i in range(size_history):
		var x = w * (float(i) / float(size_history - 1))
		var amp_multiplier = h * 0.45
		if current_amplitude_db < volume_threshold_db:
			amp_multiplier *= 0.1
		var y = h / 2.0 + _sample_history[i] * amp_multiplier
		points.append(Vector2(x, y))
		
	if points.size() > 1:
		draw_polyline(points, Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.25), 6.0, true)
		draw_polyline(points, C_JADE, 2.0, true)

func detect_dan_tranh_note(samples: PackedFloat32Array, sample_rate: float) -> Dictionary:
	if analysis_suspended:
		return {}
	if pitch_profile:
		var classification := analyze_dan_tranh_sound(samples, sample_rate)
		if not classification.get("accepted", false):
			return {}
		var f := 0.0
		if _analyzer:
			f = _analyzer.analyze_pitch_yin(samples, sample_rate, 0.08, min_frequency, max_frequency)
		else:
			f = _detect_pitch_yin_gdscript(samples, sample_rate, 0.08)
		return pitch_profile.match_pitch(f)
	return {}


func analyze_dan_tranh_sound(samples: PackedFloat32Array, sample_rate: float = 44100.0) -> Dictionary:
	var result := {
		"accepted": false,
		"confidence": 0.0,
		"attack_ratio": 0.0,
		"decay_db": 0.0,
		"late_decay_db": 0.0,
		"tail_ratio": 0.0,
		"periodicity": 0.0,
		"string_tonality": 0.0,
		"crest_factor": 0.0,
		"peak_position": 1.0,
		"reason": "too_short"
	}
	var size := samples.size()
	if size < INSTRUMENT_ATTACK_ANALYSIS_SAMPLES:
		return result

	var threshold: float = float(pitch_profile.volume_threshold_db) if pitch_profile else volume_threshold_db
	var amplitude_db := _calculate_amplitude_db(samples)
	if amplitude_db < threshold:
		result["reason"] = "too_quiet"
		return result

	var quarter := maxi(1, size / 4)
	var early_energy := 0.0
	var middle_energy := 0.0
	var second_quarter_energy := 0.0
	var tail_energy := 0.0
	var total_energy := 0.0
	var peak := 0.0
	var peak_index := 0
	for i in range(size):
		var value := float(samples[i])
		var energy := value * value
		total_energy += energy
		if i < quarter:
			early_energy += energy
		elif i < quarter * 3:
			middle_energy += energy
			if i < quarter * 2:
				second_quarter_energy += energy
		else:
			tail_energy += energy
		var absolute := absf(value)
		if absolute > peak:
			peak = absolute
			peak_index = i

	var early_rms := sqrt(early_energy / float(quarter))
	var middle_count := maxi(1, mini(size, quarter * 3) - quarter)
	var middle_rms := sqrt(middle_energy / float(middle_count))
	var second_quarter_count := maxi(1, mini(size, quarter * 2) - quarter)
	var second_quarter_rms := sqrt(second_quarter_energy / float(second_quarter_count))
	var tail_count := maxi(1, size - quarter * 3)
	var tail_rms := sqrt(tail_energy / float(tail_count))
	var total_rms := sqrt(total_energy / float(size))
	var attack_ratio := early_rms / maxf(middle_rms, 0.000001)
	var tail_ratio := tail_rms / maxf(early_rms, 0.000001)
	var decay_db := 20.0 * log(maxf(early_rms, 0.000001) / maxf(tail_rms, 0.000001)) / log(10.0)
	var late_decay_db := 20.0 * log(maxf(second_quarter_rms, 0.000001) / maxf(tail_rms, 0.000001)) / log(10.0)
	var periodicity := _evaluate_tone_quality_gdscript(samples)
	var string_tonality := _calculate_dan_tranh_string_tonality(samples, sample_rate)
	var crest_factor := peak / maxf(total_rms, 0.000001)
	var peak_position := float(peak_index) / float(maxi(1, size - 1))

	result["attack_ratio"] = attack_ratio
	result["decay_db"] = decay_db
	result["late_decay_db"] = late_decay_db
	result["tail_ratio"] = tail_ratio
	result["periodicity"] = periodicity
	result["string_tonality"] = string_tonality
	result["crest_factor"] = crest_factor
	result["peak_position"] = peak_position

	if attack_ratio < INSTRUMENT_MIN_ATTACK_RATIO:
		result["reason"] = "no_fast_attack"
		return result
	if decay_db < INSTRUMENT_MIN_DECAY_DB:
		result["reason"] = "no_string_decay"
		return result
	if late_decay_db < INSTRUMENT_MIN_LATE_DECAY_DB:
		result["reason"] = "sustained_voice_after_attack"
		return result
	if tail_ratio < INSTRUMENT_MIN_TAIL_RATIO:
		result["reason"] = "transient_too_short"
		return result
	if periodicity < INSTRUMENT_MIN_PERIODICITY:
		result["reason"] = "aperiodic_noise_or_tap"
		return result
	if string_tonality < INSTRUMENT_MIN_STRING_TONALITY:
		result["reason"] = "not_a_dan_tranh_frequency"
		return result
	if crest_factor < INSTRUMENT_MIN_CREST_FACTOR:
		result["reason"] = "flat_sustained_tone"
		return result
	if peak_position > 0.45:
		result["reason"] = "slow_or_late_attack"
		return result

	var attack_score := clampf((attack_ratio - 1.0) / 1.8, 0.0, 1.0)
	var decay_score := clampf(decay_db / 12.0, 0.0, 1.0)
	var periodicity_score := clampf(periodicity / 65.0, 0.0, 1.0)
	var tonality_score := clampf(string_tonality / 0.35, 0.0, 1.0)
	var sustain_score := clampf((tail_ratio - INSTRUMENT_MIN_TAIL_RATIO) / 0.30, 0.0, 1.0)
	result["confidence"] = 100.0 * (
		0.25 * attack_score + 0.20 * decay_score
		+ 0.20 * periodicity_score + 0.25 * tonality_score + 0.10 * sustain_score
	)
	result["accepted"] = true
	result["reason"] = "dan_tranh_pluck"
	return result


func _has_pluck_attack(samples: PackedFloat32Array) -> bool:
	return bool(analyze_dan_tranh_sound(samples).get("accepted", false))


func _calculate_dan_tranh_string_tonality(
	samples: PackedFloat32Array,
	sample_rate: float
) -> float:
	if samples.size() < 256 or sample_rate <= 0.0:
		return 0.0

	# Measure how much energy projects onto any real đàn-tranh string frequency.
	# Oscillator recurrence avoids running sin/cos for every individual sample.
	var sampled_energy := 0.0
	var sampled_count := 0
	for i in range(0, samples.size(), 2):
		var value := float(samples[i])
		sampled_energy += value * value
		sampled_count += 1
	if sampled_energy <= 0.000001 or sampled_count <= 0:
		return 0.0

	var strongest_ratio := 0.0
	for base_frequency in DAN_TRANH_GATE_FREQUENCIES:
		# Scan ±3% so a physically detuned string inside the lesson's pitch
		# tolerance is not rejected, especially on the highest strings.
		for tuning_offset in DAN_TRANH_GATE_TUNING_OFFSETS:
			var frequency := base_frequency * (1.0 + tuning_offset)
			var angle_step := TAU * frequency * 2.0 / sample_rate
			var step_cos := cos(angle_step)
			var step_sin := sin(angle_step)
			var oscillator_cos := 1.0
			var oscillator_sin := 0.0
			var real_projection := 0.0
			var imaginary_projection := 0.0
			for i in range(0, samples.size(), 2):
				var value := float(samples[i])
				real_projection += value * oscillator_cos
				imaginary_projection -= value * oscillator_sin
				var next_cos := oscillator_cos * step_cos - oscillator_sin * step_sin
				oscillator_sin = oscillator_sin * step_cos + oscillator_cos * step_sin
				oscillator_cos = next_cos
			var projection_power := real_projection * real_projection \
				+ imaginary_projection * imaginary_projection
			var ratio := 2.0 * projection_power / (float(sampled_count) * sampled_energy)
			strongest_ratio = maxf(strongest_ratio, ratio)

	return clampf(strongest_ratio, 0.0, 1.0)
