extends RefCounted

const SAMPLE_RATE := 44100
const DURATION := 3.0

const RECORDED_SAMPLES := {
	"sol1": "G3.wav",
	"la1": "A3.wav",
	"đô2": "C4.wav",
	"do2": "C4.wav",
	"rê2": "D4.wav",
	"re2": "D4.wav",
	"mi2": "E4.wav",
	"sol2": "G4.wav",
	"la2": "A4.wav",
	"đô3": "C5.wav",
	"do3": "C5.wav",
}

# The CC0 library contains one recording for each of the 17 physical strings
# used by the course. Keep this list deliberately pentatonic: Fa/Si are
# produced with a pressing technique and do not have a separate recorded
# string in this library.
const REAL_STRING_NOTES: Array[String] = [
	"G3", "A3", "C4", "D4", "E4", "G4", "A4", "C5", "D5",
	"E5", "G5", "A5", "C6", "D6", "E6", "G6", "A6"
]

const REAL_STRING_FREQUENCIES := [
	196.00, 220.00, 261.63, 293.66, 329.63, 392.00, 440.00, 523.25, 587.33,
	659.25, 783.99, 880.00, 1046.50, 1174.66, 1318.51, 1567.98, 1760.00
]


static func make_real_string_pitch_profile(cents_tolerance: float = 60.0) -> InstrumentPitchProfile:
	var profile := InstrumentPitchProfile.new()
	profile.notes = REAL_STRING_NOTES.duplicate()
	profile.frequencies = PackedFloat32Array(REAL_STRING_FREQUENCIES)
	var mappings: Array[int] = []
	for string_index in REAL_STRING_NOTES.size():
		mappings.append(string_index)
	profile.physical_mappings = mappings
	profile.min_frequency = 180.0
	profile.max_frequency = 1900.0
	profile.volume_threshold_db = -58.0
	profile.cents_tolerance = cents_tolerance
	profile.hold_time_sec = 0.20
	profile.is_plucked_instrument = true
	return profile

static func load_recorded_sample(note: String) -> AudioStreamWAV:
	var key := note.to_lower().strip_edges()
	if not RECORDED_SAMPLES.has(key):
		return null
	var path := "res://assets/audio/dan_tranh_cc0/%s" % str(RECORDED_SAMPLES[key])
	return load(path) as AudioStreamWAV if ResourceLoader.exists(path) else null

static func generate_pluck_stream(freq: float) -> AudioStreamWAV:
	var sample_count := int(SAMPLE_RATE * DURATION)
	var delay_len := maxi(2, int(float(SAMPLE_RATE) / maxf(freq, 1.0)))
	var delay_buf := PackedFloat32Array()
	delay_buf.resize(delay_len)
	for i in delay_len:
		delay_buf[i] = randf_range(-1.0, 1.0)

	var decay := clampf(0.9993 - clampf(freq / 1000.0, 0.0, 1.0) * 0.002, 0.9972, 0.9993)
	var samples := PackedFloat32Array()
	samples.resize(sample_count)
	var buffer_pos := 0
	for i in sample_count:
		var next_pos := (buffer_pos + 1) % delay_len
		var sample := decay * 0.5 * (delay_buf[buffer_pos] + delay_buf[next_pos])
		samples[i] = sample
		delay_buf[buffer_pos] = sample
		buffer_pos = next_pos

	var attack_samples := int(SAMPLE_RATE * 0.012)
	for i in attack_samples:
		samples[i] *= float(i) / float(attack_samples)

	var peak := 0.0
	for sample in samples:
		peak = maxf(peak, absf(sample))
	var gain := 0.85 / maxf(peak, 0.0001)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in sample_count:
		var value := clampf(samples[i] * gain, -1.0, 1.0)
		var sample_i16 := int(value * 32767.0) & 0xFFFF
		data[i * 2] = sample_i16 & 0xFF
		data[i * 2 + 1] = (sample_i16 >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream
