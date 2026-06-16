#include "audio_analyzer.h"
#include <godot_cpp/core/class_db.hpp>
#include <cmath>
#include <algorithm>

using namespace godot;

void AudioAnalyzer::_bind_methods() {
	ClassDB::bind_method(D_METHOD("analyze_pitch", "samples", "sample_rate"), &AudioAnalyzer::analyze_pitch);
	ClassDB::bind_method(D_METHOD("calculate_peak_db", "samples"), &AudioAnalyzer::calculate_peak_db);
}

AudioAnalyzer::AudioAnalyzer() {
}

AudioAnalyzer::~AudioAnalyzer() {
}

float AudioAnalyzer::analyze_pitch(const PackedFloat32Array &samples, float sample_rate) {
	int size = samples.size();
	if (size < 256) {
		return 0.0f;
	}

	// Autocorrelation pitch detection
	// We want to detect frequencies in the range 80Hz to 1000Hz.
	// For sample_rate = 44100, that corresponds to period lengths in samples:
	// max_period = 44100 / 80 = 551 samples
	// min_period = 44100 / 1000 = 44 samples

	int min_period = std::max(1, static_cast<int>(sample_rate / 1000.0f));
	int max_period = std::min(size / 2, static_cast<int>(sample_rate / 80.0f));

	if (min_period >= max_period) {
		return 0.0f;
	}

	float best_correlation = -1.0f;
	int best_period = -1;

	// Calculate correlation for each candidate period
	for (int period = min_period; period <= max_period; ++period) {
		float correlation = 0.0f;
		float sum_sq1 = 0.0f;
		float sum_sq2 = 0.0f;

		for (int i = 0; i < size - period; ++i) {
			float x = samples[i];
			float y = samples[i + period];
			correlation += x * y;
			sum_sq1 += x * x;
			sum_sq2 += y * y;
		}

		if (sum_sq1 > 0.0f && sum_sq2 > 0.0f) {
			float norm_correlation = correlation / std::sqrt(sum_sq1 * sum_sq2);
			if (norm_correlation > best_correlation) {
				best_correlation = norm_correlation;
				best_period = period;
			}
		}
	}

	// If the correlation is strong enough, return the frequency
	if (best_correlation > 0.7f && best_period > 0) {
		return sample_rate / static_cast<float>(best_period);
	}

	return 0.0f;
}

float AudioAnalyzer::calculate_peak_db(const PackedFloat32Array &samples) {
	float peak = 0.0f;
	for (int i = 0; i < samples.size(); ++i) {
		float val = std::abs(samples[i]);
		if (val > peak) {
			peak = val;
		}
	}

	if (peak > 0.0001f) {
		return 20.0f * std::log10(peak);
	}
	return -80.0f;
}
