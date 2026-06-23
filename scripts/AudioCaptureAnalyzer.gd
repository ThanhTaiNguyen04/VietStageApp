extends Control

class_name AudioCaptureAnalyzer

# Styling colors
const C_JADE        := Color(0.18, 0.62, 0.42, 1.0)
const C_GOLD        := Color(0.95, 0.72, 0.18, 1.0)
const C_GOLD_LIGHT  := Color(1.00, 0.87, 0.45, 1.0)
const C_CREAM       := Color(1.00, 0.97, 0.88, 1.0)

var _effect: AudioEffectCapture
var _bus_index := -1
var _sample_history := PackedFloat32Array()
const MAX_SAMPLES := 180

var current_pitch := 0.0
var current_amplitude_db := -80.0
var _analyzer: RefCounted = null
var _sliding_window := PackedFloat32Array()

# Dynamic configurations for pitch detection and noise gating
var min_frequency := 200.0
var max_frequency := 2200.0
var volume_threshold_db := -30.0

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
		# Mute to prevent loud feedback loops!
		AudioServer.set_bus_mute(_bus_index, true)
	
	# Add AudioEffectCapture if not already present
	var effect_index := -1
	for i in range(AudioServer.get_bus_effect_count(_bus_index)):
		if AudioServer.get_bus_effect(_bus_index, i) is AudioEffectCapture:
			effect_index = i
			break
			
	if effect_index == -1:
		_effect = AudioEffectCapture.new()
		_effect.buffer_length = 0.5 # 500ms buffer
		AudioServer.add_bus_effect(_bus_index, _effect, 0)
	else:
		_effect = AudioServer.get_bus_effect(_bus_index, effect_index) as AudioEffectCapture

	# Create and play AudioStreamMicrophone to enable audio capture on the Record bus
	var mic_player := AudioStreamPlayer.new()
	mic_player.stream = AudioStreamMicrophone.new()
	mic_player.bus = "Record"
	add_child(mic_player)
	mic_player.play()

func _process(_delta: float) -> void:
	if not _effect: return
	
	var samples_available = _effect.get_frames_available()
	if samples_available > 0:
		var frames = _effect.get_buffer(samples_available)
		if frames.size() > 0:
			# Convert frames to mono float array
			var mono_samples := PackedFloat32Array()
			mono_samples.resize(frames.size())
			for i in range(frames.size()):
				mono_samples[i] = (frames[i].x + frames[i].y) * 0.5
				
			# Accumulate samples in sliding window
			_sliding_window.append_array(mono_samples)
			if _sliding_window.size() > 2048:
				_sliding_window = _sliding_window.slice(_sliding_window.size() - 2048)
				
			if _analyzer:
				# Use high-performance GDExtension C++ module for analysis
				current_amplitude_db = _analyzer.calculate_peak_db(mono_samples)
				if current_amplitude_db > volume_threshold_db:
					var detected_pitch = _analyzer.analyze_pitch(mono_samples, AudioServer.get_mix_rate())
					if detected_pitch > 0.0:
						if current_pitch == 0.0:
							current_pitch = detected_pitch
						else:
							current_pitch = lerp(current_pitch, detected_pitch, 0.15)
				else:
					current_pitch = 0.0
			else:
				# Fallback to pure GDScript analysis using autocorrelation
				var peak := 0.0
				for val in mono_samples:
					var abs_val = abs(val)
					if abs_val > peak:
						peak = abs_val
						
				if peak > 0.0001:
					current_amplitude_db = 20.0 * log(peak) / log(10)
				else:
					current_amplitude_db = -80.0
					
				if current_amplitude_db > volume_threshold_db:
					var detected_pitch = _detect_pitch_high_res(_sliding_window, AudioServer.get_mix_rate())
					if detected_pitch > 0.0:
						if current_pitch == 0.0:
							current_pitch = detected_pitch
						else:
							current_pitch = lerp(current_pitch, detected_pitch, 0.3)
				else:
					current_pitch = 0.0
				
			# Add samples to history for visualization
			var step = max(1, mono_samples.size() / 10)
			for i in range(0, mono_samples.size(), step):
				var val = mono_samples[i]
				if _sample_history.size() > 0:
					_sample_history.remove_at(0)
				_sample_history.append(val)
				
			queue_redraw()

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
