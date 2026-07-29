#ifndef AUDIO_ANALYZER_H
#define AUDIO_ANALYZER_H

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/string.hpp>

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

	// Advanced AI Analysis Features
	float analyze_pitch_yin(const PackedFloat32Array &samples, float sample_rate, float threshold, float min_freq, float max_freq);
	float evaluate_rhythm(const PackedFloat32Array &detected_onsets, const PackedFloat32Array &reference_onsets, float tolerance);
	float evaluate_tone_quality(const PackedFloat32Array &samples);
	float analyze_breath_pattern(const PackedFloat32Array &samples);
	float calculate_composite_score(float pitch_score, float rhythm_score, float tone_score, float breath_score);
	float adjust_difficulty(const PackedFloat32Array &recent_scores);
	PackedFloat32Array filter_background_noise(const PackedFloat32Array &samples, float noise_threshold);

	// Specialized Dan Tranh C++ Audio Detection
	Dictionary detect_dan_tranh_note(const PackedFloat32Array &samples, float sample_rate);
	Dictionary detect_note_onset_and_duration(const PackedFloat32Array &samples, float sample_rate, float threshold_db);
	Dictionary evaluate_dan_tranh_note_performance(float detected_freq, float detected_duration, float target_freq, float target_duration, float pitch_tolerance_cents, float duration_tolerance_sec);
};


#endif // AUDIO_ANALYZER_H

