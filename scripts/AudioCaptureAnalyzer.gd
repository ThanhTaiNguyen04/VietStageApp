extends Control

class_name AudioCaptureAnalyzer

signal dan_tranh_note_started(note: Dictionary)
signal dan_tranh_note_ended(note: Dictionary)

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

# Keeps estimating the fundamental throughout a sustained note so technique
# lessons can measure periodic pitch movement (rung dây) after the attack.
var contour_tracking_mode := false

# Calibration (Phase 1)
var calibration_active := false
var calibration_db_samples: Array[float] = []

# Pluck state machine for plucked instruments like Dan Tranh (Phase 2)
var pluck_locked := false
var onset_detected := false
var pitch_estimation_done := false
var time_since_onset := 0.0
var pluck_release_time := 0.0

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

# ─── Standardised 7-Step DSP Pipeline ───
func _process(delta: float) -> void:
	if _mic_player and not _mic_player.playing:
		_mic_player.play()
	if not _effect: return
	
	# Step 1: Capture
	var samples = _capture_samples()
	if samples.is_empty(): return
	
	# Step 2: Noise Gate (with calibration monitoring)
	current_amplitude_db = _calculate_amplitude_db(samples)
	if calibration_active:
		calibration_db_samples.append(current_amplitude_db)
	
	var gate_open = current_amplitude_db > volume_threshold_db
	if not gate_open:
		_handle_silence(delta)
		_update_sample_history(samples)
		return
	
	# Step 3: Onset Detection (plucked instrument logic)
	var is_onset = _detect_onset(samples)
	var profile_plucked = pitch_profile != null and pitch_profile.is_plucked_instrument
	
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
	
	# Step 4: Pitch Estimation (estimate every frame inside the 30-150 ms onset
	# window so the stability gate can accumulate PITCH_STABILITY_FRAMES candidates)
	var raw_pitch := 0.0
	if rapid_sequence_mode or contour_tracking_mode:
		raw_pitch = _estimate_pitch(samples)
	elif profile_plucked:
		if onset_detected and time_since_onset >= 0.03 and time_since_onset <= 0.15:
			if not pitch_estimation_done:
				raw_pitch = _estimate_pitch(samples)
				if raw_pitch > 0.0 and current_pitch_is_reliable:
					pitch_estimation_done = true
	else:
		raw_pitch = _estimate_pitch(samples)
	
	# Step 5: Stabilization
	if raw_pitch > 0.0:
		_update_reliable_pitch(raw_pitch)
	
	# Step 6: Note Mapping (Standardised core note mapping using InstrumentPitchProfile)
	var mapped_note := {}
	if current_pitch_is_reliable and current_pitch > 0.0 and pitch_profile != null:
		mapped_note = pitch_profile.match_pitch(current_pitch)
	
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
			if _analysis_buffer.size() > 2048:
				var excess = _analysis_buffer.size() - 2048
				_analysis_buffer = _analysis_buffer.slice(excess)
	return mono_samples

func _calculate_amplitude_db(samples: PackedFloat32Array) -> float:
	if _analyzer:
		return _analyzer.calculate_peak_db(samples)
	return _calculate_peak_db_gdscript(samples)

func _detect_onset(samples: PackedFloat32Array) -> bool:
	if _analyzer:
		var onset_info = _analyzer.detect_note_onset_and_duration(samples, AudioServer.get_mix_rate(), volume_threshold_db)
		return onset_info.get("is_onset", false)
	
	var onset_info = _detect_note_onset_and_duration_gdscript(samples, AudioServer.get_mix_rate(), volume_threshold_db)
	return onset_info.get("is_onset", false)

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
	if pitch_profile:
		# Reject silence and continuous/non-plucked signals (voice hum, sustained
		# tones, room tone): a real pluck is a sharp attack followed by decay, so
		# the front half of the analysis window must clearly dominate the tail.
		if _calculate_amplitude_db(samples) < pitch_profile.volume_threshold_db:
			return {}
		if not _has_pluck_attack(samples):
			return {}
		# Reject transient clicks/taps: they are front-loaded but aperiodic,
		# so their autocorrelation periodicity score is far below a real tone.
		if _evaluate_tone_quality_gdscript(samples) < 50.0:
			return {}
		var f := 0.0
		if _analyzer:
			f = _analyzer.analyze_pitch_yin(samples, sample_rate, 0.08, min_frequency, max_frequency)
		else:
			f = _detect_pitch_yin_gdscript(samples, sample_rate, 0.08)
		return pitch_profile.match_pitch(f)
	return {}

func _has_pluck_attack(samples: PackedFloat32Array) -> bool:
	var size : int = samples.size()
	if size < 256:
		return false
	var half : int = size / 2
	var e_first := 0.0
	var e_second := 0.0
	for i in range(half):
		e_first += samples[i] * samples[i]
	for i in range(half, size):
		e_second += samples[i] * samples[i]
	if e_second <= 0.000001:
		return e_first > 0.000001
	return e_first / e_second > 1.8
