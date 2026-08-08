extends Control

class_name AudioCaptureAnalyzer

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

var _mic_player: AudioStreamPlayer = null
var _time_since_last_pitch := 0.0
var _analysis_buffer := PackedFloat32Array()
var _pitch_candidates: Array[float] = []
const PITCH_STABILITY_FRAMES := 4
const PITCH_STABILITY_CENTS := 24.0
const PITCH_JUMP_CENTS := 80.0

func _ready() -> void:
	# Try to instantiate the C++ AudioAnalyzer class from GDExtension
	if ClassDB.class_exists("AudioAnalyzer"):
		_analyzer = ClassDB.instantiate("AudioAnalyzer")
		
	_setup_audio_bus()
	
	# Pre-fill sample history
	for i in range(MAX_SAMPLES):
		_sample_history.append(0.0)

func _setup_audio_bus() -> void:
	# Programmatically check or create Record bus
	_bus_index = AudioServer.get_bus_index("Record")
	if _bus_index == -1:
		_bus_index = AudioServer.bus_count
		AudioServer.add_bus(_bus_index)
		AudioServer.set_bus_name(_bus_index, "Record")
	
	# Set volume to silent (-80dB) and keep unmuted so Godot processes the capture effect!
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
		
	# Add AudioEffectRecord for user recording
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
		
	# Add AudioEffectSpectrumAnalyzer for C++ high-precision pitch analysis
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

	# Setup microphone input player dynamically
	_mic_player = AudioStreamPlayer.new()
	_mic_player.stream = AudioStreamMicrophone.new()
	_mic_player.bus = "Record"
	add_child(_mic_player)

func _process(delta: float) -> void:
	if _mic_player and not _mic_player.playing:
		_mic_player.play()
	if not _effect: return
	
	_time_since_last_pitch += delta
	
	var samples_available = _effect.get_frames_available()
	if samples_available > 0:
		var frames = _effect.get_buffer(samples_available)
		if frames.size() > 0:
			# Convert frames to mono float array
			var mono_samples := PackedFloat32Array()
			mono_samples.resize(frames.size())
			for i in range(frames.size()):
				mono_samples[i] = (frames[i].x + frames[i].y) * 0.5
				
			# Append to rolling analysis buffer
			for val in mono_samples:
				_analysis_buffer.append(val)
			if _analysis_buffer.size() > 2048:
				var excess = _analysis_buffer.size() - 2048
				_analysis_buffer = _analysis_buffer.slice(excess)

				
			if _analyzer:
				# Use high-performance GDExtension C++ module for analysis
				current_amplitude_db = _analyzer.calculate_peak_db(mono_samples)
				
				if current_amplitude_db > volume_threshold_db:
					var detected_pitch = _analyzer.analyze_pitch_yin(_analysis_buffer, AudioServer.get_mix_rate(), 0.08, min_frequency, max_frequency)
					_update_reliable_pitch(detected_pitch)
					
					current_tone_quality = _analyzer.evaluate_tone_quality(_analysis_buffer)
					current_breath_purity = _analyzer.analyze_breath_pattern(_analysis_buffer)
				else:
					_clear_pitch_detection()
					current_tone_quality = lerp(current_tone_quality, 100.0, 0.5)
					current_breath_purity = lerp(current_breath_purity, 100.0, 0.5)
			else:
				# Fallback to pure GDScript analysis
				current_amplitude_db = _calculate_peak_db_gdscript(mono_samples)
				
				if current_amplitude_db > volume_threshold_db:
					var detected_pitch := _detect_pitch_yin_gdscript(_analysis_buffer, AudioServer.get_mix_rate(), 0.08)
					_update_reliable_pitch(detected_pitch)

					# Compute other metrics
					if _time_since_last_pitch >= 0.03:
						_time_since_last_pitch = 0.0
						if _analysis_buffer.size() >= 512:
							current_tone_quality = _evaluate_tone_quality_gdscript(_analysis_buffer)
							current_breath_purity = _analyze_breath_pattern_gdscript(_analysis_buffer)
				else:
					_clear_pitch_detection()
					current_tone_quality = lerp(current_tone_quality, 100.0, 0.5)
					current_breath_purity = lerp(current_breath_purity, 100.0, 0.5)
				
			# Add samples to history for visualization
			var step = max(1, mono_samples.size() / 10)
			for i in range(0, mono_samples.size(), step):
				var val = mono_samples[i]
				if _sample_history.size() > 0:
					_sample_history.remove_at(0)
				_sample_history.append(val)
				
			queue_redraw()

func _clear_pitch_detection() -> void:
	# Never leave a stale pitch available after the microphone signal vanishes.
	_pitch_candidates.clear()
	current_pitch = 0.0
	current_pitch_confidence = 0.0
	current_pitch_is_reliable = false

func _update_reliable_pitch(detected_pitch: float) -> void:
	if detected_pitch < min_frequency or detected_pitch > max_frequency:
		_clear_pitch_detection()
		return

	# A new string may be far from the previous pitch. Start a fresh stability
	# window instead of averaging two notes into a false intermediate pitch.
	if not _pitch_candidates.is_empty():
		var previous := _pitch_candidates[_pitch_candidates.size() - 1]
		var jump_cents := absf(1200.0 * log(detected_pitch / previous) / log(2.0))
		if jump_cents > PITCH_JUMP_CENTS:
			_pitch_candidates.clear()

	_pitch_candidates.append(detected_pitch)
	if _pitch_candidates.size() > PITCH_STABILITY_FRAMES:
		_pitch_candidates.pop_front()
	if _pitch_candidates.size() < PITCH_STABILITY_FRAMES:
		current_pitch = 0.0
		current_pitch_confidence = float(_pitch_candidates.size()) / float(PITCH_STABILITY_FRAMES)
		current_pitch_is_reliable = false
		return

	var sorted := _pitch_candidates.duplicate()
	sorted.sort()
	var median: float = (sorted[1] + sorted[2]) * 0.5
	var spread_cents := absf(1200.0 * log(sorted[sorted.size() - 1] / sorted[0]) / log(2.0))
	current_pitch_confidence = clampf(1.0 - spread_cents / PITCH_STABILITY_CENTS, 0.0, 1.0)
	current_pitch_is_reliable = spread_cents <= PITCH_STABILITY_CENTS
	current_pitch = median if current_pitch_is_reliable else 0.0

func _detect_pitch_high_res(samples: PackedFloat32Array, sample_rate: float) -> float:
	var size = samples.size()
	if size < 512:
		return 0.0
		
	var peak := 0.0
	for v in samples:
		if abs(v) > peak:
			peak = abs(v)
	if peak < 0.01:
		return 0.0
		
	var min_lag = int(sample_rate / max_frequency)
	var max_lag = int(sample_rate / min_frequency)
	max_lag = min(max_lag, size / 2)
	
	var best_lag := -1
	var best_correlation := -1e9
	
	var window_size = min(256, size - max_lag)
	if window_size <= 0:
		return 0.0
		
	var energy_ref := 0.0
	for i in range(window_size):
		energy_ref += samples[i] * samples[i]
	if energy_ref < 0.0001:
		return 0.0
		
	var correlations := PackedFloat32Array()
	correlations.resize(max_lag + 1)
	
	for lag in range(min_lag, max_lag):
		var correlation := 0.0
		var energy_lag := 0.0
		for i in range(window_size):
			var x = samples[i]
			var y = samples[i + lag]
			correlation += x * y
			energy_lag += y * y
			
		if energy_lag > 0.0001:
			var normalized_corr = correlation / sqrt(energy_ref * energy_lag)
			correlations[lag] = normalized_corr
			if normalized_corr > best_correlation:
				best_correlation = normalized_corr
				best_lag = lag
				
	if best_correlation > 0.82 and best_lag > 0:
		var exact_lag = float(best_lag)
		if best_lag > min_lag and best_lag < max_lag - 1:
			var alpha = correlations[best_lag - 1]
			var gamma = correlations[best_lag]
			var beta = correlations[best_lag + 1]
			var denom = 2.0 * (2.0 * gamma - beta - alpha)
			if abs(denom) > 0.00001:
				var d = (beta - alpha) / denom
				exact_lag += clamp(d, -0.5, 0.5)
		return sample_rate / exact_lag
		
	return 0.0


func _draw() -> void:
	var w := size.x
	var h := size.y
	
	# Draw background grid lines
	var grid_color := Color(C_CREAM.r, C_CREAM.g, C_CREAM.b, 0.06)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.04, 0.015, 0.5), true)
	
	# Horizontal zero baseline
	draw_line(Vector2(0, h / 2.0), Vector2(w, h / 2.0), grid_color, 1.5)
	
	# Vertical markers
	var markers := 6
	for i in range(1, markers):
		var gx = w * (float(i) / float(markers))
		draw_line(Vector2(gx, 0), Vector2(gx, h), grid_color, 1.0)
		
	# Draw moving oscilloscope waveform line
	var points := PackedVector2Array()
	var size_history = _sample_history.size()
	for i in range(size_history):
		var x = w * (float(i) / float(size_history - 1))
		var amp_multiplier = h * 0.45
		if current_amplitude_db < volume_threshold_db:
			amp_multiplier *= 0.1 # damp visual noise when quiet
		var y = h / 2.0 + _sample_history[i] * amp_multiplier
		points.append(Vector2(x, y))
		
	if points.size() > 1:
		# Draw glowing 2D oscilloscope wave
		draw_polyline(points, Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.25), 6.0, true)
		draw_polyline(points, C_JADE, 2.0, true)

# ─── GDScript Advanced AI Fallbacks ───────────────────────────────────────────

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

func calculate_composite_score(pitch_score: float, rhythm_score: float, tone_score: float, breath_score: float) -> float:
	if _analyzer:
		return _analyzer.calculate_composite_score(pitch_score, rhythm_score, tone_score, breath_score)
	return clamp(0.35 * pitch_score + 0.35 * rhythm_score + 0.15 * tone_score + 0.15 * breath_score, 0.0, 100.0)

# Specialized Dan Tranh Note & Duration Recognition API
func detect_dan_tranh_note(samples: PackedFloat32Array, sample_rate: float) -> Dictionary:
	if _analyzer and _analyzer.has_method("detect_dan_tranh_note"):
		return _analyzer.detect_dan_tranh_note(samples, sample_rate)
	return _detect_dan_tranh_note_gdscript(samples, sample_rate)

func detect_note_onset_and_duration(samples: PackedFloat32Array, sample_rate: float, threshold_db: float = -45.0) -> Dictionary:
	if _analyzer and _analyzer.has_method("detect_note_onset_and_duration"):
		return _analyzer.detect_note_onset_and_duration(samples, sample_rate, threshold_db)
	return _detect_note_onset_and_duration_gdscript(samples, sample_rate, threshold_db)

func evaluate_dan_tranh_note_performance(detected_freq: float, detected_duration: float, target_freq: float, target_duration: float, pitch_tolerance_cents: float = 50.0, duration_tolerance_sec: float = 0.3) -> Dictionary:
	if _analyzer and _analyzer.has_method("evaluate_dan_tranh_note_performance"):
		return _analyzer.evaluate_dan_tranh_note_performance(detected_freq, detected_duration, target_freq, target_duration, pitch_tolerance_cents, duration_tolerance_sec)
	return _evaluate_dan_tranh_note_performance_gdscript(detected_freq, detected_duration, target_freq, target_duration, pitch_tolerance_cents, duration_tolerance_sec)

func _detect_dan_tranh_note_gdscript(samples: PackedFloat32Array, sample_rate: float) -> Dictionary:
	var result := {"frequency": 0.0, "note_name": "None", "string_index": -1, "cents_offset": 0.0, "clarity": 0.0}
	if samples.size() < 256: return result
	
	# Reject unpitched wind noise / blowing air into microphone!
	var clarity = _evaluate_tone_quality_gdscript(samples)
	if clarity < 0.15:
		return result
		
	var freq = _detect_pitch_yin_gdscript(samples, sample_rate, 0.12)
	if freq <= 0.0: return result
	
	const DAN_TRANH_NOTES = [
		{"name": "Sol1", "idx": 0, "freq": 196.00},
		{"name": "La1",  "idx": 1, "freq": 220.00},
		{"name": "Đô2",  "idx": 2, "freq": 261.63},
		{"name": "Rê2",  "idx": 3, "freq": 293.66},
		{"name": "Mi2",  "idx": 4, "freq": 329.63},
		{"name": "Sol2", "idx": 5, "freq": 392.00},
		{"name": "La2",  "idx": 6, "freq": 440.00},
		{"name": "Đô3",  "idx": 7, "freq": 523.25},
		{"name": "Rê3",  "idx": 8, "freq": 587.33},
		{"name": "Mi3",  "idx": 9, "freq": 659.25},
		{"name": "Sol3", "idx": 10, "freq": 783.99},
		{"name": "La3",  "idx": 11, "freq": 880.00},
		{"name": "Đô4",  "idx": 12, "freq": 1046.50},
		{"name": "Rê4",  "idx": 13, "freq": 1174.66},
		{"name": "Mi4",  "idx": 14, "freq": 1318.51},
		{"name": "Sol4", "idx": 15, "freq": 1567.98},
		{"name": "La4",  "idx": 16, "freq": 1760.00}
	]
	
	var best_item = null
	var min_ratio_diff := 1e10
	for item in DAN_TRANH_NOTES:
		var ref_f = item["freq"]
		var cents = abs(1200.0 * (log(freq / ref_f) / log(2.0)))
		if cents < min_ratio_diff:
			min_ratio_diff = cents
			best_item = item
			
	# Require strict pitch matching (within 80.0 cents to account for real-world tuning deviations)
	if best_item and min_ratio_diff <= 80.0:
		var ref_f = best_item["freq"]
		var cents_offset = 1200.0 * (log(freq / ref_f) / log(2.0))
		while cents_offset > 600.0: cents_offset -= 1200.0
		while cents_offset < -600.0: cents_offset += 1200.0
		result["frequency"] = freq
		result["note_name"] = best_item["name"]
		result["string_index"] = best_item["idx"]
		result["cents_offset"] = cents_offset
		result["clarity"] = clarity
	return result

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

func _evaluate_dan_tranh_note_performance_gdscript(detected_freq: float, detected_duration: float, target_freq: float, target_duration: float, pitch_tolerance_cents: float, duration_tolerance_sec: float) -> Dictionary:
	var pitch_score := 0.0
	var duration_score := 0.0
	var feedback := "Cần cố gắng thêm"
	
	if detected_freq > 0.0 and target_freq > 0.0:
		var cents_diff = abs(1200.0 * (log(detected_freq / target_freq) / log(2.0)))
		if cents_diff <= pitch_tolerance_cents:
			pitch_score = 100.0 * (1.0 - (cents_diff / pitch_tolerance_cents))
		else:
			pitch_score = max(0.0, 100.0 - (cents_diff - pitch_tolerance_cents) * 2.0)
			
	if target_duration > 0.0:
		var dur_diff = abs(detected_duration - target_duration)
		if dur_diff <= duration_tolerance_sec:
			duration_score = 100.0 * (1.0 - (dur_diff / duration_tolerance_sec))
		else:
			duration_score = max(0.0, 100.0 - (dur_diff - duration_tolerance_sec) * 50.0)
	else:
		duration_score = 100.0
		
	var composite = 0.6 * pitch_score + 0.4 * duration_score
	if composite >= 90.0:
		feedback = "Tuyệt vời! Cao độ và trường độ rất chuẩn."
	elif pitch_score >= 80.0 and duration_score < 70.0:
		feedback = "Cao độ chuẩn, hãy chú ý ngân đủ trường độ nốt."
	elif pitch_score < 70.0 and duration_score >= 80.0:
		feedback = "Trường độ tốt, hãy gảy đúng phím dây đàn."
	elif composite >= 70.0:
		feedback = "Khá tốt! Tiếp tục phát huy."
		
	return {
		"pitch_score": clamp(pitch_score, 0.0, 100.0),
		"duration_score": clamp(duration_score, 0.0, 100.0),
		"composite_score": clamp(composite, 0.0, 100.0),
		"feedback": feedback
	}


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
		return 1.25 # Stricter tolerance
	elif avg < 60.0:
		return 0.75 # Looser tolerance
	return 1.0

func _calculate_peak_db_gdscript(samples: PackedFloat32Array) -> float:
	var peak := 0.0
	for val in samples:
		var abs_val = abs(val)
		if abs_val > peak:
			peak = abs_val
	if peak > 0.0001:
		return 20.0 * log(peak) / log(10)
	return -80.0

func _filter_background_noise_gdscript(samples: PackedFloat32Array, noise_threshold: float) -> PackedFloat32Array:
	var size = samples.size()
	var filtered := PackedFloat32Array()
	filtered.resize(size)
	
	var peak := 0.0
	for val in samples:
		peak = max(peak, abs(val))
	if peak < noise_threshold:
		# Quiet signal: noise gate closed
		for i in range(size):
			filtered[i] = 0.0
		return filtered
		
	# Bandpass filter
	var x1 := 0.0
	var x2 := 0.0
	var y1 := 0.0
	var y2 := 0.0
	for i in range(size):
		var x0 = samples[i]
		var y0 = 0.88 * (x0 - x2) + 0.75 * y1 - 0.25 * y2
		filtered[i] = clamp(y0, -1.0, 1.0)
		x2 = x1
		x1 = x0
		y2 = y1
		y1 = y0
	return filtered

func _detect_pitch_yin_gdscript(samples: PackedFloat32Array, sample_rate: float, threshold: float) -> float:
	var size = samples.size()
	var W = size / 2
	if W < 128: return 0.0
	
	var min_period = int(sample_rate / max_frequency)
	var max_period = min(W - 2, int(sample_rate / min_frequency))
	
	if min_period >= max_period:
		return 0.0
		
	var d := PackedFloat32Array()
	d.resize(max_period + 1)
	
	# Step 1: Difference
	# Populate d completely from 1 to max_period to ensure mathematically correct cumulative mean normalized difference
	# Using stride=2 inside difference loop for 60fps GDScript optimization
	for tau in range(1, max_period + 1):
		var diff_sum := 0.0
		for t in range(0, W, 2):
			var diff = samples[t] - samples[t + tau]
			diff_sum += diff * diff
		d[tau] = diff_sum * 2.0
		
	# Step 2: Cumulative mean normalized difference
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
			
	# Step 3: Absolute threshold (with local minimum check)
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

		
	# Step 4: Parabolic interpolation
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
	
	# Stride lag for speed
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


func _update_hp_cutoff() -> void:
	if _bus_index == -1:
		return
	for i in range(AudioServer.get_bus_effect_count(_bus_index)):
		var effect = AudioServer.get_bus_effect(_bus_index, i)
		if effect is AudioEffectHighPassFilter:
			effect.cutoff_hz = clampf(min_frequency * 0.8, 20.0, 300.0)
			break



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
