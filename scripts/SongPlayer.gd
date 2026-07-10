extends Node
class_name SongPlayer

class NoteData:
	var lane: int
	var hit_time: float
	var duration: float
	var type: int # 0: Normal, 1: Hold
	
	func _init(_lane: int, _hit_time: float, _duration: float = 0.0, _type: int = 0):
		lane = _lane
		hit_time = _hit_time
		duration = _duration
		type = _type

var current_song_time: float = 0.0
var demo_active: bool = false
var notes: Array = [] # Array of NoteData
var _is_playing: bool = false

# Sứ Thanh Hoa (Đô = 0, Rê = 1, Mi = 2, Fa = 3, Sol = 4, La = 5, Si = 6)
func _ready() -> void:
	_load_demo_song()

func _load_demo_song() -> void:
	notes.clear()
	var t = 2.0 # Wait 2 seconds before first note
	var beat = 0.6
	
	# Sứ Thanh Hoa from Dan Tranh
	var sheet = [
		1, 0, 5, 0, 0, 5, 0, 0, 5, 0, 5, 4,
		1, 0, 5, 0, 0, 5, 0, 0, 2, 1, 0, 4, 5, 2,
		2, 1, 2, 1, 2, 4, 2, -1, 2, 2, 1,
		0, 2, 1, 1, 0, 5, 0, 0, 5, 0,
		5, 4, 4, 5, 2, 4, 4, 2, 4, 4, 2, 1, 0, 0,
		1, 0, 1, 2, 1, 1, 0, 1, 0, 1, 0, 0, 5, 0, 1, 1
	]
	
	var durations = [
		0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5, 2.0,
		0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5,
		0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 1.0, 0.5, 0.5, 2.0,
		0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 3.0,
		1.0, 1.0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5,
		0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5
	]
	
	for i in range(sheet.size()):
		var lane = sheet[i]
		var dur = durations[i] * beat
		if lane != -1:
			notes.append(NoteData.new(lane, t, 0.0, 0)) # Normal notes
		t += dur

func play() -> void:
	current_song_time = 0.0
	demo_active = true
	_is_playing = true

func stop() -> void:
	demo_active = false
	_is_playing = false
	current_song_time = 0.0

func _process(delta: float) -> void:
	if _is_playing:
		current_song_time += delta
