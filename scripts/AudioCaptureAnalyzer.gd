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

func _ready() -> void:
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

func _process(_delta: float) -> void:
	if not _effect: return
	
	var samples_available = _effect.get_frames_available()
	if samples_available > 0:
		var frames = _effect.get_buffer(samples_available)
		if frames.size() > 0:
			# Analyze amplitude peak
			var peak := 0.0
			for frame in frames:
				var amp = (abs(frame.x) + abs(frame.y)) * 0.5
				if amp > peak:
					peak = amp
					
			# Convert peak to decibels
			if peak > 0.0001:
				current_amplitude_db = 20.0 * log(peak) / log(10)
			else:
				current_amplitude_db = -80.0
				
			# Add samples to history for visualization
			var step = max(1, frames.size() / 10)
			for i in range(0, frames.size(), step):
				var f = frames[i]
				var val = (f.x + f.y) * 0.5
				if _sample_history.size() > 0:
					_sample_history.remove_at(0)
				_sample_history.append(val)
				
			# Simulate low-latency pitch detection (YIN) based on real microphone volume
			if current_amplitude_db > -45.0:
				var sim_freq = 440.0 + sin(Time.get_ticks_msec() * 0.005) * 50.0
				current_pitch = lerp(current_pitch, sim_freq, 0.15)
			else:
				current_pitch = lerp(current_pitch, 0.0, 0.2)
				
			queue_redraw()

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
		if current_amplitude_db < -45.0:
			amp_multiplier *= 0.1 # damp visual noise when quiet
		var y = h / 2.0 + _sample_history[i] * amp_multiplier
		points.append(Vector2(x, y))
		
	if points.size() > 1:
		# Draw glowing 2D oscilloscope wave
		draw_polyline(points, Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.25), 6.0, true)
		draw_polyline(points, C_JADE, 2.0, true)
