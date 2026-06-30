#include "audio_analyzer.h"
#include <godot_cpp/core/class_db.hpp>
#include <cmath>
#include <algorithm>

using namespace godot;

void AudioAnalyzer::_bind_methods() {
	ClassDB::bind_method(D_METHOD("analyze_pitch", "samples", "sample_rate"), &AudioAnalyzer::analyze_pitch);
	ClassDB::bind_method(D_METHOD("calculate_peak_db", "samples"), &AudioAnalyzer::calculate_peak_db);
	ClassDB::bind_method(D_METHOD("analyze_pitch_yin", "samples", "sample_rate", "threshold", "min_freq", "max_freq"), &AudioAnalyzer::analyze_pitch_yin);
	ClassDB::bind_method(D_METHOD("evaluate_rhythm", "detected_onsets", "reference_onsets", "tolerance"), &AudioAnalyzer::evaluate_rhythm);
	ClassDB::bind_method(D_METHOD("evaluate_tone_quality", "samples"), &AudioAnalyzer::evaluate_tone_quality);
	ClassDB::bind_method(D_METHOD("analyze_breath_pattern", "samples"), &AudioAnalyzer::analyze_breath_pattern);
	ClassDB::bind_method(D_METHOD("calculate_composite_score", "pitch_score", "rhythm_score", "tone_score", "breath_score"), &AudioAnalyzer::calculate_composite_score);
	ClassDB::bind_method(D_METHOD("adjust_difficulty", "recent_scores"), &AudioAnalyzer::adjust_difficulty);
	ClassDB::bind_method(D_METHOD("filter_background_noise", "samples", "noise_threshold"), &AudioAnalyzer::filter_background_noise);
}

AudioAnalyzer::AudioAnalyzer() {
}

AudioAnalyzer::~AudioAnalyzer() {
}

float AudioAnalyzer::analyze_pitch(const PackedFloat32Array &samples, float sample_rate) {
	// Original basic autocorrelation pitch detection fallback
	int size = samples.size();
	if (size < 256) {
		return 0.0f;
	}

	int min_period = std::max(1, static_cast<int>(sample_rate / 1000.0f));
	int max_period = std::min(size / 2, static_cast<int>(sample_rate / 80.0f));

	if (min_period >= max_period) {
		return 0.0f;
	}

	float best_correlation = -1.0f;
	int best_period = -1;

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

// ─── Real-Time YIN Pitch Detection Algorithm ──────────────────────────────────
float AudioAnalyzer::analyze_pitch_yin(const PackedFloat32Array &samples, float sample_rate, float threshold, float min_freq, float max_freq) {
	int size = samples.size();
	// YIN requires a integration window size W. We use half of the buffer size.
	int W = size / 2;
	if (W < 128) {
		return 0.0f;
	}

	int min_period = std::max(1, static_cast<int>(sample_rate / max_freq));
	int max_period = std::min(W - 2, static_cast<int>(sample_rate / min_freq));

	if (min_period >= max_period) {
		return 0.0f;
	}

	// Step 1: Difference function d(tau)
	// Populate d completely from 1 to max_period to ensure mathematically correct cumulative mean normalized difference
	std::vector<float> d(max_period + 1, 0.0f);
	for (int tau = 1; tau <= max_period; ++tau) {
		for (int t = 0; t < W; ++t) {
			float diff = samples[t] - samples[t + tau];
			d[tau] += diff * diff;
		}
	}

	// Step 2: Cumulative mean normalized difference d'(tau)
	std::vector<float> d_prime(max_period + 1, 1.0f);
	float running_sum = 0.0f;
	d_prime[0] = 1.0f;
	
	for (int tau = 1; tau <= max_period; ++tau) {
		running_sum += d[tau];
		if (running_sum > 0.0f) {
			d_prime[tau] = d[tau] / ((1.0f / tau) * running_sum);
		} else {
			d_prime[tau] = 1.0f;
		}
	}

	// Step 3: Absolute threshold (with local minimum check)
	int best_tau = -1;
	float min_val = 1e10f;
	int global_min_tau = -1;

	for (int tau = min_period; tau <= max_period; ++tau) {
		if (d_prime[tau] < threshold) {
			if (tau > min_period && tau < max_period) {
				if (d_prime[tau] < d_prime[tau - 1] && d_prime[tau] < d_prime[tau + 1]) {
					best_tau = tau;
					break;
				}
			}
		}
		if (d_prime[tau] < min_val) {
			min_val = d_prime[tau];
			global_min_tau = tau;
		}
	}

	// Fallback to global minimum if no values fell below the threshold
	if (best_tau == -1) {
		best_tau = global_min_tau;
	}

	if (best_tau <= 0 || best_tau >= max_period) {
		return 0.0f;
	}

	// Step 4: Parabolic interpolation for sub-sample accuracy
	float precise_tau = static_cast<float>(best_tau);
	float alpha = d_prime[best_tau - 1];
	float beta = d_prime[best_tau];
	float gamma = d_prime[best_tau + 1];
	
	float denom = alpha - 2.0f * beta + gamma;
	if (std::abs(denom) > 0.0001f) {
		precise_tau = best_tau + 0.5f * (alpha - gamma) / denom;
	}

	if (precise_tau > 0.0f) {
		return sample_rate / precise_tau;
	}
	return 0.0f;
}

// ─── Rhythm Timing Accuracy Evaluation ────────────────────────────────────────
float AudioAnalyzer::evaluate_rhythm(const PackedFloat32Array &detected_onsets, const PackedFloat32Array &reference_onsets, float tolerance) {
	if (detected_onsets.size() == 0 || reference_onsets.size() == 0) {
		return 0.0f;
	}

	float total_score = 0.0f;
	int matches = 0;

	// For each detected note onset, find the closest reference beat
	for (int i = 0; i < detected_onsets.size(); ++i) {
		float det = detected_onsets[i];
		float min_diff = 1e10f;

		for (int j = 0; j < reference_onsets.size(); ++j) {
			float diff = std::abs(det - reference_onsets[j]);
			if (diff < min_diff) {
				min_diff = diff;
			}
		}

		if (min_diff < tolerance * 2.0f) {
			// Linear grading: 100% score for exact match, sliding to 0% at maximum tolerance
			float score = std::max(0.0f, 100.0f * (1.0f - min_diff / tolerance));
			total_score += score;
			matches++;
		}
	}

	if (matches > 0) {
		// Divide by size of reference to penalize missed notes
		float avg_score = total_score / static_cast<float>(std::max(detected_onsets.size(), reference_onsets.size()));
		return std::clamp(avg_score, 0.0f, 100.0f);
	}

	return 0.0f;
}

// ─── String Instrument Tone Quality Assessment ────────────────────────────────
float AudioAnalyzer::evaluate_tone_quality(const PackedFloat32Array &samples) {
	int size = samples.size();
	if (size < 128) {
		return 0.0f;
	}

	// Evaluate periodicity of the string pluck signal using autocorrelation peak ratio.
	// Clear, stable notes have high periodic self-similarity. Noise/scratching results in low similarity.
	float sum_sq = 0.0f;
	for (int i = 0; i < size; ++i) {
		sum_sq += samples[i] * samples[i];
	}

	if (sum_sq < 0.001f) {
		return 0.0f; // Silent signal has no tone quality
	}

	// Find the maximum autocorrelation coefficient in the pitch period range (40 to 300 samples)
	float max_corr = 0.0f;
	int min_lag = 40;
	int max_lag = std::min(size / 2, 300);

	for (int lag = min_lag; lag < max_lag; ++lag) {
		float corr = 0.0f;
		float sum_sq_shifted = 0.0f;

		for (int i = 0; i < size - lag; ++i) {
			corr += samples[i] * samples[i + lag];
			sum_sq_shifted += samples[i + lag] * samples[i + lag];
		}

		if (sum_sq_shifted > 0.0f) {
			float norm_corr = corr / std::sqrt(sum_sq * sum_sq_shifted);
			if (norm_corr > max_corr) {
				max_corr = norm_corr;
			}
		}
	}

	// Standardize to 0 - 100 score
	float tone_score = max_corr * 100.0f;
	return std::clamp(tone_score, 0.0f, 100.0f);
}

// ─── Flute Breath & Wind Noise Analysis ────────────────────────────────────────
float AudioAnalyzer::analyze_breath_pattern(const PackedFloat32Array &samples) {
	int size = samples.size();
	if (size < 256) {
		return 0.0f;
	}

	// Flute breath analysis measures the ratio of periodic tone energy to turbulent wind noise.
	// Standard deviation of short-term amplitude envelope checks breathing stability.
	float amplitude_sum = 0.0f;
	std::vector<float> envelopes;
	int block_size = 64;

	for (int i = 0; i < size; i += block_size) {
		float block_peak = 0.0f;
		int limit = std::min(size, i + block_size);
		for (int j = i; j < limit; ++j) {
			block_peak = std::max(block_peak, std::abs(samples[j]));
		}
		envelopes.push_back(block_peak);
		amplitude_sum += block_peak;
	}

	float avg_amp = amplitude_sum / envelopes.size();
	if (avg_amp < 0.005f) {
		return 0.0f; // Silent
	}

	// Calculate envelope variance (stability of breathing pressure)
	float sq_diff_sum = 0.0f;
	for (float env : envelopes) {
		float diff = env - avg_amp;
		sq_diff_sum += diff * diff;
	}
	float variance = sq_diff_sum / envelopes.size();
	float stability_factor = std::max(0.0f, 1.0f - (variance / (avg_amp * avg_amp + 0.0001f)));

	// Non-harmonic noise estimation: YIN residual energy
	// Periodic energy vs noise energy ratio
	float residual_energy = 0.0f;
	float total_energy = 0.0f;
	int period = 80; // Default average period for typical flute notes

	for (int i = 0; i < size - period; ++i) {
		float periodic_diff = samples[i] - samples[i + period];
		residual_energy += periodic_diff * periodic_diff;
		total_energy += samples[i] * samples[i];
	}

	float purity_factor = 1.0f;
	if (total_energy > 0.0f) {
		purity_factor = std::max(0.0f, 1.0f - (residual_energy / total_energy));
	}

	// Blend purity (70%) and stability (30%) to form the breathing quality score
	float breath_score = (0.7f * purity_factor + 0.3f * stability_factor) * 100.0f;
	return std::clamp(breath_score, 0.0f, 100.0f);
}

// ─── Composite Technical Score Calculation ────────────────────────────────────
float AudioAnalyzer::calculate_composite_score(float pitch_score, float rhythm_score, float tone_score, float breath_score) {
	// Weighted balance score: Pitch (35%), Rhythm (35%), Tone (15%), Breath/Wind Control (15%)
	float total = 0.35f * pitch_score + 0.35f * rhythm_score + 0.15f * tone_score + 0.15f * breath_score;
	return std::clamp(total, 0.0f, 100.0f);
}

// ─── Adaptive Difficulty Auto-Tuning ──────────────────────────────────────────
float AudioAnalyzer::adjust_difficulty(const PackedFloat32Array &recent_scores) {
	int count = recent_scores.size();
	if (count < 3) {
		return 1.0f; // Default baseline scale multiplier
	}

	float sum = 0.0f;
	for (int i = 0; i < count; ++i) {
		sum += recent_scores[i];
	}
	float avg = sum / count;

	if (avg > 88.0f) {
		// Tighten tolerances by returning a scaling factor > 1.0 (e.g. 1.25x stricter)
		return 1.25f;
	} else if (avg < 60.0f) {
		// Loosen tolerances by returning a scaling factor < 1.0 (e.g. 0.75x easier)
		return 0.75f;
	}

	return 1.0f; // Maintain standard tolerance
}

// ─── Background Noise Gate & Bandpass Filtering ──────────────────────────────
PackedFloat32Array AudioAnalyzer::filter_background_noise(const PackedFloat32Array &samples, float noise_threshold) {
	int size = samples.size();
	PackedFloat32Array filtered_samples;
	filtered_samples.resize(size);

	// 1. Noise Gate Check
	float peak = 0.0f;
	for (int i = 0; i < size; ++i) {
		peak = std::max(peak, std::abs(samples[i]));
	}

	if (peak < noise_threshold) {
		// Signal is quiet: gate closed, fill with silence
		for (int i = 0; i < size; ++i) {
			filtered_samples[i] = 0.0f;
		}
		return filtered_samples;
	}

	// 2. Bandpass filter (simple IIR 2nd order Butterworth-like difference filter)
	// Eliminates low rumble (<80Hz) and high-frequency microphone hiss (>1500Hz)
	// Formula: y[i] = 0.95 * (x[i] - x[i-2]) + 0.9 * y[i-1] - 0.15 * y[i-2]
	float x1 = 0.0f, x2 = 0.0f;
	float y1 = 0.0f, y2 = 0.0f;

	for (int i = 0; i < size; ++i) {
		float x0 = samples[i];
		float y0 = 0.88f * (x0 - x2) + 0.75f * y1 - 0.25f * y2;
		
		filtered_samples[i] = std::clamp(y0, -1.0f, 1.0f);
		
		// Shift histories
		x2 = x1;
		x1 = x0;
		y2 = y1;
		y1 = y0;
	}

	return filtered_samples;
}

