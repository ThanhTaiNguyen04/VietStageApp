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

	ClassDB::bind_method(D_METHOD("detect_dan_tranh_note", "samples", "sample_rate"), &AudioAnalyzer::detect_dan_tranh_note);
	ClassDB::bind_method(D_METHOD("detect_note_onset_and_duration", "samples", "sample_rate", "threshold_db"), &AudioAnalyzer::detect_note_onset_and_duration);
	ClassDB::bind_method(D_METHOD("evaluate_dan_tranh_note_performance", "detected_freq", "detected_duration", "target_freq", "target_duration", "pitch_tolerance_cents", "duration_tolerance_sec"), &AudioAnalyzer::evaluate_dan_tranh_note_performance);
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

	// Fallback to global minimum if no values fell below the threshold, but protect against harmonic period multiples
	if (best_tau == -1) {
		if (min_val < 0.35f && global_min_tau > 0) {
			int candidate_tau = global_min_tau;
			for (int t = min_period + 1; t <= global_min_tau / 2; ++t) {
				if (d_prime[t] < 0.35f && t > min_period && t < max_period) {
					if (d_prime[t] < d_prime[t - 1] && d_prime[t] < d_prime[t + 1]) {
						float ratio = static_cast<float>(global_min_tau) / static_cast<float>(t);
						float rounded_r = std::round(ratio);
						if (rounded_r >= 2.0f && rounded_r <= 4.0f && std::abs(ratio - rounded_r) < 0.15f) {
							candidate_tau = t;
							break;
						}
					}
				}
			}
			best_tau = candidate_tau;
		} else {
			best_tau = global_min_tau;
		}
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

// ─── Specialized C++ Dan Tranh Note & Fundamental Frequency Recognition ─────────
Dictionary AudioAnalyzer::detect_dan_tranh_note(const PackedFloat32Array &samples, float sample_rate) {
	Dictionary result;
	result["frequency"] = 0.0f;
	result["note_name"] = "None";
	result["string_index"] = -1;
	result["cents_offset"] = 0.0f;
	result["clarity"] = 0.0f;

	if (samples.size() < 256) {
		return result;
	}

	// 1. Detect fundamental pitch using YIN algorithm (range: 120 Hz to 4200 Hz for all 17 strings + harmonics)
	float freq = analyze_pitch_yin(samples, sample_rate, 0.15f, 120.0f, 4200.0f);


	if (freq <= 0.0f) {
		return result;
	}

	// 2. Dan Tranh 17-String Reference Frequencies & Note Names
	static const struct {
		const char *name;
		int string_idx;
		float freq;
	} DAN_TRANH_NOTES[] = {
		{"Sol1", 0,  196.00f},
		{"La1",  1,  220.00f},
		{"Đô1",  2,  261.63f},
		{"Rê1",  3,  293.66f},
		{"Mi1",  4,  329.63f},
		{"Sol2", 5,  392.00f},
		{"La2",  6,  440.00f},
		{"Đô2",  7,  523.25f},
		{"Rê2",  8,  587.33f},
		{"Mi2",  9,  659.25f},
		{"Sol3", 10, 783.99f},
		{"La3",  11, 880.00f},
		{"Đô3",  12, 1046.50f},
		{"Rê3",  13, 1174.66f},
		{"Mi3",  14, 1318.51f},
		{"Sol4", 15, 1567.98f},
		{"La4",  16, 1760.00f}
	};
	constexpr int NOTE_COUNT = sizeof(DAN_TRANH_NOTES) / sizeof(DAN_TRANH_NOTES[0]);

	// 3. Find closest reference note frequency
	int best_idx = -1;
	float min_ratio_diff = 1e10f;

	for (int i = 0; i < NOTE_COUNT; ++i) {
		float ref_freq = DAN_TRANH_NOTES[i].freq;
		float cents = 1200.0f * std::log2(freq / ref_freq);
		if (std::abs(cents) < min_ratio_diff) {
			min_ratio_diff = std::abs(cents);
			best_idx = i;
		}
	}

	if (best_idx >= 0 && min_ratio_diff < 600.0f) { // Map any pitch in spectrum to nearest 17-string note

		float ref_freq = DAN_TRANH_NOTES[best_idx].freq;
		float cents_offset = 1200.0f * std::log2(freq / ref_freq);
		float tone_q = evaluate_tone_quality(samples);

		result["frequency"] = freq;
		result["note_name"] = String(DAN_TRANH_NOTES[best_idx].name);
		result["string_index"] = DAN_TRANH_NOTES[best_idx].string_idx;
		result["cents_offset"] = cents_offset;
		result["clarity"] = tone_q;
	}

	return result;
}

// ─── Note Onset & Duration Detection in C++ ──────────────────────────────────
Dictionary AudioAnalyzer::detect_note_onset_and_duration(const PackedFloat32Array &samples, float sample_rate, float threshold_db) {
	Dictionary result;
	result["is_onset"] = false;
	result["duration_sec"] = 0.0f;
	result["peak_db"] = -80.0f;
	result["is_active"] = false;

	int size = samples.size();
	if (size < 128) {
		return result;
	}

	// Calculate overall RMS and peak
	float sum_sq = 0.0f;
	float peak = 0.0f;
	for (int i = 0; i < size; ++i) {
		float v = std::abs(samples[i]);
		sum_sq += v * v;
		if (v > peak) peak = v;
	}

	float rms = std::sqrt(sum_sq / static_cast<float>(size));
	float rms_db = (rms > 0.0001f) ? 20.0f * std::log10(rms) : -80.0f;
	float peak_db = (peak > 0.0001f) ? 20.0f * std::log10(peak) : -80.0f;
	result["peak_db"] = peak_db;

	if (peak_db < threshold_db) {
		return result;
	}

	result["is_active"] = true;

	// Spectral flux / Onset detection: compare first half and second half energy
	int half = size / 2;
	float e_first = 0.0f, e_second = 0.0f;
	for (int i = 0; i < half; ++i) {
		e_first += samples[i] * samples[i];
	}
	for (int i = half; i < size; ++i) {
		e_second += samples[i] * samples[i];
	}

	// Pluck onset condition: sharp initial energy spike followed by decay
	if (e_first > 0.0001f && (e_first / (e_second + 0.0001f)) > 2.5f) {
		result["is_onset"] = true;
	}

	// Estimate sustain duration based on energy window exceeding threshold
	float active_ratio = 0.0f;
	int active_samples = 0;
	int block = 32;
	for (int i = 0; i < size; i += block) {
		float b_peak = 0.0f;
		int limit = std::min(size, i + block);
		for (int j = i; j < limit; ++j) {
			b_peak = std::max(b_peak, std::abs(samples[j]));
		}
		if (b_peak > 0.01f) {
			active_samples += block;
		}
	}
	result["duration_sec"] = static_cast<float>(active_samples) / sample_rate;

	return result;
}

// ─── Dan Tranh Note Performance Evaluation (Pitch & Duration Score) ──────────
Dictionary AudioAnalyzer::evaluate_dan_tranh_note_performance(
	float detected_freq,
	float detected_duration,
	float target_freq,
	float target_duration,
	float pitch_tolerance_cents,
	float duration_tolerance_sec
) {
	Dictionary result;
	float pitch_score = 0.0f;
	float duration_score = 0.0f;
	String feedback = "Cần cố gắng thêm";

	if (detected_freq > 0.0f && target_freq > 0.0f) {
		float cents_diff = std::abs(1200.0f * std::log2(detected_freq / target_freq));
		if (cents_diff <= pitch_tolerance_cents) {
			pitch_score = 100.0f * (1.0f - (cents_diff / pitch_tolerance_cents));
		} else {
			pitch_score = std::max(0.0f, 100.0f - (cents_diff - pitch_tolerance_cents) * 2.0f);
		}
	}

	if (target_duration > 0.0f) {
		float dur_diff = std::abs(detected_duration - target_duration);
		if (dur_diff <= duration_tolerance_sec) {
			duration_score = 100.0f * (1.0f - (dur_diff / duration_tolerance_sec));
		} else {
			duration_score = std::max(0.0f, 100.0f - (dur_diff - duration_tolerance_sec) * 50.0f);
		}
	} else {
		duration_score = 100.0f;
	}

	float composite = 0.6f * pitch_score + 0.4f * duration_score;

	if (composite >= 90.0f) {
		feedback = "Tuyệt vời! Cao độ và trường độ rất chuẩn.";
	} else if (pitch_score >= 80.0f && duration_score < 70.0f) {
		feedback = "Cao độ chuẩn, hãy chú ý ngân đủ trường độ nốt.";
	} else if (pitch_score < 70.0f && duration_score >= 80.0f) {
		feedback = "Trường độ tốt, hãy gảy đúng phím dây đàn.";
	} else if (composite >= 70.0f) {
		feedback = "Khá tốt! Tiếp tục phát huy.";
	}

	result["pitch_score"] = std::clamp(pitch_score, 0.0f, 100.0f);
	result["duration_score"] = std::clamp(duration_score, 0.0f, 100.0f);
	result["composite_score"] = std::clamp(composite, 0.0f, 100.0f);
	result["feedback"] = feedback;

	return result;
}


