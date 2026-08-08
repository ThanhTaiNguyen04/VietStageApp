#include "instrument_pitch_profile.h"
#include <godot_cpp/core/class_db.hpp>
#include <cmath>

using namespace godot;

void NativeInstrumentPitchProfile::_bind_methods() {
	ClassDB::bind_method(D_METHOD("get_notes"), &NativeInstrumentPitchProfile::get_notes);
	ClassDB::bind_method(D_METHOD("set_notes", "notes"), &NativeInstrumentPitchProfile::set_notes);
	ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "notes"), "set_notes", "get_notes");

	ClassDB::bind_method(D_METHOD("get_frequencies"), &NativeInstrumentPitchProfile::get_frequencies);
	ClassDB::bind_method(D_METHOD("set_frequencies", "frequencies"), &NativeInstrumentPitchProfile::set_frequencies);
	ADD_PROPERTY(PropertyInfo(Variant::PACKED_FLOAT32_ARRAY, "frequencies"), "set_frequencies", "get_frequencies");

	ClassDB::bind_method(D_METHOD("get_physical_mappings"), &NativeInstrumentPitchProfile::get_physical_mappings);
	ClassDB::bind_method(D_METHOD("set_physical_mappings", "mappings"), &NativeInstrumentPitchProfile::set_physical_mappings);
	ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "physical_mappings"), "set_physical_mappings", "get_physical_mappings");

	ClassDB::bind_method(D_METHOD("get_min_frequency"), &NativeInstrumentPitchProfile::get_min_frequency);
	ClassDB::bind_method(D_METHOD("set_min_frequency", "val"), &NativeInstrumentPitchProfile::set_min_frequency);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "min_frequency"), "set_min_frequency", "get_min_frequency");

	ClassDB::bind_method(D_METHOD("get_max_frequency"), &NativeInstrumentPitchProfile::get_max_frequency);
	ClassDB::bind_method(D_METHOD("set_max_frequency", "val"), &NativeInstrumentPitchProfile::set_max_frequency);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "max_frequency"), "set_max_frequency", "get_max_frequency");

	ClassDB::bind_method(D_METHOD("get_volume_threshold_db"), &NativeInstrumentPitchProfile::get_volume_threshold_db);
	ClassDB::bind_method(D_METHOD("set_volume_threshold_db", "val"), &NativeInstrumentPitchProfile::set_volume_threshold_db);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "volume_threshold_db"), "set_volume_threshold_db", "get_volume_threshold_db");

	ClassDB::bind_method(D_METHOD("get_cents_tolerance"), &NativeInstrumentPitchProfile::get_cents_tolerance);
	ClassDB::bind_method(D_METHOD("set_cents_tolerance", "val"), &NativeInstrumentPitchProfile::set_cents_tolerance);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "cents_tolerance"), "set_cents_tolerance", "get_cents_tolerance");

	ClassDB::bind_method(D_METHOD("get_hold_time_sec"), &NativeInstrumentPitchProfile::get_hold_time_sec);
	ClassDB::bind_method(D_METHOD("set_hold_time_sec", "val"), &NativeInstrumentPitchProfile::set_hold_time_sec);
	ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "hold_time_sec"), "set_hold_time_sec", "get_hold_time_sec");

	ClassDB::bind_method(D_METHOD("match_pitch", "pitch"), &NativeInstrumentPitchProfile::match_pitch);
}

NativeInstrumentPitchProfile::NativeInstrumentPitchProfile() {
	min_frequency = 100.0f;
	max_frequency = 4200.0f;
	volume_threshold_db = -50.0f;
	cents_tolerance = 50.0f;
	hold_time_sec = 0.2f;
}

Dictionary NativeInstrumentPitchProfile::match_pitch(float pitch) const {
	Dictionary result;
	result["note_name"] = "None";
	result["string_index"] = -1;
	result["physical_index"] = Variant();
	result["cents_offset"] = 0.0f;
	result["frequency"] = pitch;
	result["reference_frequency"] = 0.0f;
	result["is_match"] = false;

	if (pitch <= 0.0f || notes.size() == 0) {
		return result;
	}

	int best_idx = -1;
	float min_cents = 1e10f;
	for (int i = 0; i < notes.size(); ++i) {
		float ref_f = (i < frequencies.size()) ? frequencies[i] : 0.0f;
		if (ref_f <= 0.0f) continue;
		float cents = 1200.0f * std::log2(pitch / ref_f);
		if (std::abs(cents) < std::abs(min_cents)) {
			min_cents = cents;
			best_idx = i;
		}
	}

	if (best_idx >= 0 && std::abs(min_cents) <= cents_tolerance) {
		result["note_name"] = notes[best_idx];
		Variant phys = (best_idx < physical_mappings.size()) ? physical_mappings[best_idx] : Variant();
		result["physical_index"] = phys;
		if (phys.get_type() == Variant::INT) {
			result["string_index"] = phys;
		}
		result["cents_offset"] = min_cents;
		result["reference_frequency"] = frequencies[best_idx];
		result["is_match"] = true;
	}
	return result;
}
