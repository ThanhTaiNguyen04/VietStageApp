extends Node
class_name InstrumentSamplePlayer

## Plays only packaged, recorded instrument samples. It deliberately has no
## synthesis fallback: an incomplete sample library is a content error.
signal note_started(sequence_index: int)
signal playback_finished()
signal playback_failed(details: Dictionary)

const DEFAULT_BPM := 80.0

const DAN_BAU_PATHS := {
	"c4": "res://assets/audio/dan_bau_do4.wav",
	"g4": "res://assets/audio/dan_bau_sol4.wav",
	"c5": "res://assets/audio/dan_bau_do5.wav",
	"e5": "res://assets/audio/dan_bau_mi5.wav",
	"g5": "res://assets/audio/dan_bau_sol5.wav",
	"c6": "res://assets/audio/dan_bau_do6.wav",
}

const DAN_TRANH_PATHS := {
	"g3": "res://assets/audio/dan_tranh_cc0/G3.wav", "a3": "res://assets/audio/dan_tranh_cc0/A3.wav",
	"c4": "res://assets/audio/dan_tranh_cc0/C4.wav", "d4": "res://assets/audio/dan_tranh_cc0/D4.wav",
	"e4": "res://assets/audio/dan_tranh_cc0/E4.wav", "f4": "res://assets/audio/dan_tranh_cc0/F4.wav",
	"g4": "res://assets/audio/dan_tranh_cc0/G4.wav", "a4": "res://assets/audio/dan_tranh_cc0/A4.wav",
	"b4": "res://assets/audio/dan_tranh_cc0/B4.wav", "c5": "res://assets/audio/dan_tranh_cc0/C5.wav",
	"d5": "res://assets/audio/dan_tranh_cc0/D5.wav", "e5": "res://assets/audio/dan_tranh_cc0/E5.wav",
	"f5": "res://assets/audio/dan_tranh_cc0/F5.wav", "g5": "res://assets/audio/dan_tranh_cc0/G5.wav",
	"a5": "res://assets/audio/dan_tranh_cc0/A5.wav", "b5": "res://assets/audio/dan_tranh_cc0/B5.wav",
	"c6": "res://assets/audio/dan_tranh_cc0/C6.wav", "d6": "res://assets/audio/dan_tranh_cc0/D6.wav",
	"e6": "res://assets/audio/dan_tranh_cc0/E6.wav", "g6": "res://assets/audio/dan_tranh_cc0/G6.wav",
	"a6": "res://assets/audio/dan_tranh_cc0/A6.wav",
}

const SAO_TRUC_PATHS := {
	"c5": "res://assets/audio/sao_truc/C5.wav", "d5": "res://assets/audio/sao_truc/D5.wav",
	"e5": "res://assets/audio/sao_truc/E5.wav", "f5": "res://assets/audio/sao_truc/F5.wav",
	"g5": "res://assets/audio/sao_truc/G5.wav", "a5": "res://assets/audio/sao_truc/A5.wav",
	"b5": "res://assets/audio/sao_truc/B5.wav", "c6": "res://assets/audio/sao_truc/C6.wav",
	"d6": "res://assets/audio/sao_truc/D6.wav", "e6": "res://assets/audio/sao_truc/E6.wav",
	"f6": "res://assets/audio/sao_truc/F6.wav", "g6": "res://assets/audio/sao_truc/G6.wav",
	"a6": "res://assets/audio/sao_truc/A6.wav", "b6": "res://assets/audio/sao_truc/B6.wav",
	"c7": "res://assets/audio/sao_truc/C7.wav",
}

var _player: AudioStreamPlayer
var _generation := 0
var _playing := false

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "RecordedInstrumentSample"
	add_child(_player)

func _exit_tree() -> void:
	stop()

func stop() -> void:
	_generation += 1
	_playing = false
	if _player and is_instance_valid(_player):
		_player.stop()

func is_playing() -> bool:
	return _playing

func sample_path(instrument: String, raw_note: String) -> String:
	var key := normalize_note_key(instrument, raw_note)
	var paths: Dictionary = _paths_for(instrument)
	return str(paths.get(key, ""))

func preflight(instrument: String, notes: Array, missing_index: int) -> Dictionary:
	var missing: Array[Dictionary] = []
	for index in range(notes.size()):
		if index == missing_index:
			continue
		var raw_note := str(notes[index])
		var path := sample_path(instrument, raw_note)
		if path.is_empty() or not _file_or_resource_exists(path):
			missing.append({"index": index, "note": raw_note, "path": path})
	return {"ok": missing.is_empty(), "missing": missing}

func play_sequence(instrument: String, notes: Array, missing_index: int, bpm: float = DEFAULT_BPM) -> Dictionary:
	stop()
	var check := preflight(instrument, notes, missing_index)
	if not bool(check.get("ok", false)):
		playback_failed.emit(check)
		return check
	_generation += 1
	_playing = true
	_run_sequence(_generation, instrument, notes.duplicate(), missing_index, maxf(1.0, bpm))
	return {"ok": true}

func _run_sequence(generation: int, instrument: String, notes: Array, missing_index: int, bpm: float) -> void:
	var beat_seconds := 60.0 / bpm
	for index in range(notes.size()):
		if generation != _generation or not is_inside_tree():
			return
		if index == missing_index:
			continue
		var stream := _load_audio_stream(sample_path(instrument, str(notes[index])))
		if stream == null:
			_playing = false
			playback_failed.emit({"ok": false, "missing": [{"index": index, "note": str(notes[index])}]})
			return
		note_started.emit(index)
		_player.stream = stream
		_player.play()
		await get_tree().create_timer(beat_seconds).timeout
		_player.stop()
	if generation != _generation or not is_inside_tree():
		return
	_playing = false
	playback_finished.emit()

static func _file_or_resource_exists(path: String) -> bool:
	if path.is_empty():
		return false
	return ResourceLoader.exists(path) or FileAccess.file_exists(path)

static func _load_audio_stream(path: String) -> AudioStream:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		var res := load(path)
		if res is AudioStream:
			return res as AudioStream
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file:
			var bytes := file.get_buffer(file.get_length())
			file.close()
			var wav := AudioStreamWAV.load_from_buffer(bytes)
			if wav != null:
				return wav
	return null

static func normalize_note_key(instrument: String, raw_note: String) -> String:
	var raw := raw_note.strip_edges()
	if raw.begins_with("ZT_") or raw.begins_with("zt_"):
		raw = raw.substr(3)
	
	var note := raw.to_lower().replace(" ", "").replace("_", "")
	
	# Direct scientific pitch check: e.g. "c4", "g3", "a5", "d6"
	var scientific := RegEx.new()
	scientific.compile("^[a-g][1-8]$")
	if scientific.search(note):
		return note

	# Accented single syllable solfege checks:
	# Quãng trầm: sò -> g3, là -> a3, sì -> b3, đồ -> c3/c4
	if note == "so" or note == "so1" or note == "sol1" or note == "so" or note == "sò":
		if instrument == "dan_tranh": return "g3"
		elif instrument == "sao_truc": return "g5"
		elif instrument == "dan_bau": return "g4"
		return "g3"
	if note == "la1" or note == "la" or note == "là":
		if instrument == "dan_tranh": return "a3"
		elif instrument == "sao_truc": return "a5"
		elif instrument == "dan_bau": return "a4"
		return "a3"
	if note == "si1" or note == "si" or note == "sì":
		if instrument == "dan_tranh": return "b4"
		elif instrument == "sao_truc": return "b5"
		return "b4"
	if note == "do" or note == "do1" or note == "do" or note == "đồ":
		if instrument == "dan_tranh": return "c4"
		elif instrument == "sao_truc": return "c5"
		elif instrument == "dan_bau": return "c4"
		return "c4"

	# Quãng cao có dấu sắc: đố -> c5, rế -> d5, mí -> e5, fá -> f5, sól -> g5, lá -> a5, sĩ -> b5
	if note == "do" or note == "do" or note == "đố":
		if instrument == "sao_truc": return "c6"
		elif instrument == "dan_bau": return "c6"
		return "c5"
	if note == "re" or note == "re" or note == "rế":
		if instrument == "sao_truc": return "d6"
		return "d5"
	if note == "mi" or note == "mi" or note == "mí":
		if instrument == "sao_truc": return "e6"
		elif instrument == "dan_bau": return "e5"
		return "e5"
	if note == "fa" or note == "fa" or note == "fá":
		if instrument == "sao_truc": return "f6"
		return "f5"
	if note == "sol" or note == "sol" or note == "sol" or note == "sól":
		if instrument == "sao_truc": return "g6"
		elif instrument == "dan_bau": return "g5"
		return "g5"
	if note == "la" or note == "la" or note == "lá":
		if instrument == "sao_truc": return "a6"
		return "a5"
	if note == "si" or note == "si" or note == "si" or note == "sĩ":
		if instrument == "sao_truc": return "b6"
		return "b5"

	# Strip diacritics for structured parsing
	note = note.replace("đ", "d").replace("ô", "o").replace("ê", "e").replace("í", "i").replace("á", "a").replace("ố", "o").replace("ế", "e").replace("ó", "o")
	note = note.replace("á»‘", "o").replace("á»“", "o").replace("á» ", "e").replace("áº¿", "e")

	var solfege := {"do": "c", "re": "d", "mi": "e", "fa": "f", "sol": "g", "so": "g", "la": "a", "si": "b", "ti": "b"}
	var base := ""
	for name in solfege.keys():
		if note.begins_with(name):
			base = str(solfege[name])
			note = note.substr(name.length())
			break

	if base.is_empty():
		return ""

	var num_str := note.strip_edges()
	var ordinal := int(num_str) if num_str.is_valid_int() else 0

	# Instrument specific ordinal to octave translation
	if instrument == "dan_tranh":
		# Sol1 -> G3, La1 -> A3
		# Đô2 -> C4, Rê2 -> D4, Mi2 -> E4, Sol2 -> G4, La2 -> A4
		# Đô3 -> C5, Rê3 -> D5, Mi3 -> E5, Sol3 -> G5, La3 -> A5
		# Đô4 -> C6, Rê4 -> D6, Mi4 -> E6, Sol4 -> G6, La4 -> A6
		if ordinal == 1:
			if base == "g" or base == "a":
				return "%s3" % base
			return "%s4" % base
		elif ordinal == 2:
			return "%s4" % base
		elif ordinal == 3:
			return "%s5" % base
		elif ordinal == 4:
			return "%s6" % base
		else:
			return "%s4" % base
	elif instrument == "sao_truc":
		# Đô/Đô1 -> C5 ... Si1 -> B5
		# Đô2 -> C6 ... Si2 -> B6
		# Đô3 -> C7
		if ordinal <= 1:
			return "%s5" % base
		elif ordinal == 2:
			return "%s6" % base
		elif ordinal >= 3:
			return "%s7" % base
		return "%s5" % base
	elif instrument == "dan_bau":
		# Đồ -> C4, Sol -> G4, Đô -> C5, Mi -> E5, Sol -> G5, Đố -> C6
		if ordinal == 4 or ordinal == 0:
			if base == "c": return "c4"
			elif base == "g": return "g4"
			elif base == "e": return "e5"
		elif ordinal == 5:
			return "%s5" % base
		elif ordinal == 6:
			return "%s6" % base
		return "%s4" % base

	return "%s%d" % [base, 4 + ordinal]

static func _paths_for(instrument: String) -> Dictionary:
	match instrument:
		"dan_bau": return DAN_BAU_PATHS
		"sao_truc": return SAO_TRUC_PATHS
		_: return DAN_TRANH_PATHS
