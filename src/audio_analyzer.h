#ifndef AUDIO_ANALYZER_H
#define AUDIO_ANALYZER_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>

using namespace godot;

class AudioAnalyzer : public RefCounted {
	GDCLASS(AudioAnalyzer, RefCounted);

protected:
	static void _bind_methods();

public:
	AudioAnalyzer();
	~AudioAnalyzer();

	float analyze_pitch(const PackedFloat32Array &samples, float sample_rate);
	float calculate_peak_db(const PackedFloat32Array &samples);
};

#endif // AUDIO_ANALYZER_H
