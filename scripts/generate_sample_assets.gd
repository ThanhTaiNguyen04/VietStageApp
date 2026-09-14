extends SceneTree

func _init() -> void:
	print("--- Generating Audio Sample Assets ---")
	_ensure_directories()
	_generate_dan_tranh_assets()
	_generate_sao_truc_assets()
	print("--- Finished Generating Audio Assets ---")
	quit(0)

func _ensure_directories() -> void:
	var dir := DirAccess.open("res://assets/audio")
	if dir:
		if not dir.dir_exists("dan_tranh_cc0"):
			dir.make_dir("dan_tranh_cc0")
		if not dir.dir_exists("sao_truc"):
			dir.make_dir("sao_truc")

func _generate_dan_tranh_assets() -> void:
	# Dan Tranh 21 notes mapping
	var notes = {
		"G3": 196.00, "A3": 220.00,
		"C4": 261.63, "D4": 293.66, "E4": 329.63, "F4": 349.23, "G4": 392.00, "A4": 440.00, "B4": 493.88,
		"C5": 523.25, "D5": 587.33, "E5": 659.25, "F5": 698.46, "G5": 783.99, "A5": 880.00, "B5": 987.77,
		"C6": 1046.50, "D6": 1174.66, "E6": 1318.51, "G6": 1567.98, "A6": 1760.00
	}
	for note_name in notes.keys():
		var freq: float = notes[note_name]
		var path := "res://assets/audio/dan_tranh_cc0/%s.wav" % note_name
		if not FileAccess.file_exists(path):
			_write_zither_wav(path, freq)
			print("Created: %s (%.2f Hz)" % [path, freq])
		else:
			print("Exists: %s" % path)

func _generate_sao_truc_assets() -> void:
	# Sao Truc 15 notes (Do to Do3: C5 to C7)
	var notes = {
		"C5": 523.25, "D5": 587.33, "E5": 659.25, "F5": 698.46, "G5": 783.99, "A5": 880.00, "B5": 987.77,
		"C6": 1046.50, "D6": 1174.66, "E6": 1318.51, "F6": 1396.91, "G6": 1567.98, "A6": 1760.00, "B6": 1975.53,
		"C7": 2093.00
	}
	for note_name in notes.keys():
		var freq: float = notes[note_name]
		var path := "res://assets/audio/sao_truc/%s.wav" % note_name
		if not FileAccess.file_exists(path):
			_write_flute_wav(path, freq)
			print("Created: %s (%.2f Hz)" % [path, freq])
		else:
			print("Exists: %s" % path)

func _write_zither_wav(path: String, freq: float) -> void:
	var sample_rate := 44100
	var duration := 1.6 # seconds
	var total_samples := int(sample_rate * duration)
	var buffer := PackedByteArray()
	buffer.resize(total_samples * 2)

	# Realistic plucked string synthesis: Karplus-Strong with wooden body acoustic resonance
	var period := int(float(sample_rate) / freq)
	var ring: Array[float] = []
	ring.resize(period)
	for i in range(period):
		ring[i] = randf_range(-1.0, 1.0)

	var ring_idx := 0
	for i in range(total_samples):
		var t := float(i) / float(sample_rate)
		# Pluck noise excitation + low pass string feedback loop
		var current: float = ring[ring_idx]
		var next_idx := (ring_idx + 1) % period
		var filtered: float = 0.5 * (current + ring[next_idx]) * 0.992
		ring[ring_idx] = filtered
		ring_idx = next_idx

		# Add metallic overtone and soundboard body warmth
		var body := sin(TAU * freq * t) * 0.45 + sin(TAU * freq * 2.0 * t) * 0.25 + sin(TAU * freq * 3.0 * t) * 0.12
		var env := exp(-t * (1.8 + freq * 0.001))
		var sample := (current * 0.65 + body * 0.35) * env
		sample = clampf(sample * 0.85, -1.0, 1.0)
		var pcm_val := int(sample * 32767.0)
		buffer.encode_s16(i * 2, pcm_val)

	_save_wav_file(path, buffer, sample_rate)

func _write_flute_wav(path: String, freq: float) -> void:
	var sample_rate := 44100
	var duration := 1.2 # seconds
	var total_samples := int(sample_rate * duration)
	var buffer := PackedByteArray()
	buffer.resize(total_samples * 2)

	for i in range(total_samples):
		var t := float(i) / float(sample_rate)
		# Flute envelope: smooth attack (0.08s) + sustain + gentle release (0.15s)
		var env := 1.0
		if t < 0.08:
			env = t / 0.08
		elif t > duration - 0.15:
			env = (duration - t) / 0.15
		env = clampf(env, 0.0, 1.0)

		# Flute acoustic harmonics: strong fundamental + soft 2nd/3rd harmonics + subtle breath noise
		var fundamental := sin(TAU * freq * t)
		var h2 := sin(TAU * freq * 2.0 * t) * 0.22
		var h3 := sin(TAU * freq * 3.0 * t) * 0.08
		var breath := randf_range(-1.0, 1.0) * 0.04
		var vibrato := 1.0 + 0.015 * sin(TAU * 5.5 * t)

		var sample := (fundamental * 0.72 + h2 + h3 + breath) * env * vibrato
		sample = clampf(sample * 0.8, -1.0, 1.0)
		var pcm_val := int(sample * 32767.0)
		buffer.encode_s16(i * 2, pcm_val)

	_save_wav_file(path, buffer, sample_rate)

func _save_wav_file(path: String, pcm_data: PackedByteArray, sample_rate: int) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("Cannot write to: %s" % path)
		return

	var num_channels := 1
	var bits_per_sample := 16
	var byte_rate := sample_rate * num_channels * (bits_per_sample / 8)
	var block_align := num_channels * (bits_per_sample / 8)
	var subchunk2_size := pcm_data.size()
	var chunk_size := 36 + subchunk2_size

	# RIFF header
	file.store_string("RIFF")
	file.store_32(chunk_size)
	file.store_string("WAVE")

	# fmt subchunk
	file.store_string("fmt ")
	file.store_32(16) # Subchunk1Size for PCM
	file.store_16(1)  # AudioFormat = PCM
	file.store_16(num_channels)
	file.store_32(sample_rate)
	file.store_32(byte_rate)
	file.store_16(block_align)
	file.store_16(bits_per_sample)

	# data subchunk
	file.store_string("data")
	file.store_32(subchunk2_size)
	file.store_buffer(pcm_data)
	file.close()
