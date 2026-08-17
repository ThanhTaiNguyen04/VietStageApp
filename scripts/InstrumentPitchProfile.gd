extends Resource
class_name InstrumentPitchProfile

@export var notes: Array[String] = []
@export var frequencies: PackedFloat32Array = []
@export var physical_mappings: Array = []
@export var min_frequency: float = 100.0
@export var max_frequency: float = 4200.0
@export var volume_threshold_db: float = -50.0
@export var cents_tolerance: float = 75.0
@export var hold_time_sec: float = 0.2
@export var is_plucked_instrument: bool = false

var _native_profile = null

func _init() -> void:
	if ClassDB.class_exists("NativeInstrumentPitchProfile"):
		_native_profile = ClassDB.instantiate("NativeInstrumentPitchProfile")

func match_pitch(pitch: float) -> Dictionary:
	if _native_profile:
		_native_profile.notes = notes
		_native_profile.frequencies = frequencies
		_native_profile.physical_mappings = physical_mappings
		_native_profile.min_frequency = min_frequency
		_native_profile.max_frequency = max_frequency
		_native_profile.volume_threshold_db = volume_threshold_db
		_native_profile.cents_tolerance = cents_tolerance
		_native_profile.hold_time_sec = hold_time_sec
		return _native_profile.match_pitch(pitch)
	else:
		return _match_pitch_gdscript(pitch)

func _match_pitch_gdscript(pitch: float) -> Dictionary:
	var result := {
		"note_name": "None",
		"string_index": -1,
		"physical_index": null,
		"cents_offset": 0.0,
		"frequency": pitch,
		"reference_frequency": 0.0,
		"is_match": false
	}

	if pitch <= 0.0 or notes.is_empty():
		return result

	var best_idx := -1
	var min_cents := 1e10
	for i in range(notes.size()):
		var ref_f = frequencies[i] if i < frequencies.size() else 0.0
		if ref_f <= 0.0: continue
		var cents = 1200.0 * (log(pitch / ref_f) / log(2.0))
		if abs(cents) < abs(min_cents):
			min_cents = cents
			best_idx = i

	if best_idx >= 0 and abs(min_cents) <= cents_tolerance:
		result["note_name"] = notes[best_idx]
		var phys = physical_mappings[best_idx] if best_idx < physical_mappings.size() else null
		result["physical_index"] = phys
		if typeof(phys) == TYPE_INT:
			result["string_index"] = phys
		result["cents_offset"] = min_cents
		result["reference_frequency"] = frequencies[best_idx]
		result["is_match"] = true
	return result
