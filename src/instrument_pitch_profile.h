#ifndef INSTRUMENT_PITCH_PROFILE_H
#define INSTRUMENT_PITCH_PROFILE_H

#include <godot_cpp/classes/resource.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/dictionary.hpp>

using namespace godot;

class NativeInstrumentPitchProfile : public Resource {
	GDCLASS(NativeInstrumentPitchProfile, Resource);

protected:
	static void _bind_methods();

public:
	NativeInstrumentPitchProfile();
	~NativeInstrumentPitchProfile() override = default;

	// Properties
	Array notes;
	PackedFloat32Array frequencies;
	Array physical_mappings;
	float min_frequency;
	float max_frequency;
	float volume_threshold_db;
	float cents_tolerance;
	float hold_time_sec;

	// Getters and Setters
	Array get_notes() const { return notes; }
	void set_notes(const Array &p_notes) { notes = p_notes; }

	PackedFloat32Array get_frequencies() const { return frequencies; }
	void set_frequencies(const PackedFloat32Array &p_frequencies) { frequencies = p_frequencies; }

	Array get_physical_mappings() const { return physical_mappings; }
	void set_physical_mappings(const Array &p_mappings) { physical_mappings = p_mappings; }

	float get_min_frequency() const { return min_frequency; }
	void set_min_frequency(float p_val) { min_frequency = p_val; }

	float get_max_frequency() const { return max_frequency; }
	void set_max_frequency(float p_val) { max_frequency = p_val; }

	float get_volume_threshold_db() const { return volume_threshold_db; }
	void set_volume_threshold_db(float p_val) { volume_threshold_db = p_val; }

	float get_cents_tolerance() const { return cents_tolerance; }
	void set_cents_tolerance(float p_val) { cents_tolerance = p_val; }

	float get_hold_time_sec() const { return hold_time_sec; }
	void set_hold_time_sec(float p_val) { hold_time_sec = p_val; }

	// Unified pitch mapping function
	Dictionary match_pitch(float pitch) const;
};

#endif // INSTRUMENT_PITCH_PROFILE_H
