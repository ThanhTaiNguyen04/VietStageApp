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

# Song catalog
# Lane mapping for Dan Bau harmonics:
#   0 = Đố (C6, 1/8 string)
#   1 = Sol (G5, 1/6 string)
#   2 = Mi  (E5, 1/5 string)
#   3 = Đô  (C5, 1/4 string)
#   4 = Sol (G4, 1/3 string)
#   5 = Đồ  (C4, 1/2 string)

var current_song_id: String = "long_me"

func _ready() -> void:
	load_song(current_song_id)

func load_song(song_id: String) -> void:
	current_song_id = song_id
	notes.clear()
	match song_id:
		"long_me":
			_load_long_me()
		"su_thanh_hoa":
			_load_su_thanh_hoa()
		_:
			_load_long_me()

func _load_long_me() -> void:
	# "Lòng Mẹ" - Y Vân (phiên bản Đàn Bầu truyền thống)
	# Giai điệu ngũ cung pentatonic, chuyển soạn cho 6 điểm hài âm
	# Lane: 0=Đố, 1=Sol(G5), 2=Mi, 3=Đô, 4=Sol(G4), 5=Đồ
	var t = 2.0 # Đợi 2 giây trước nốt đầu
	var beat = 0.85 # Chậm lại (từ 0.55 lên 0.85) để giống hát ru
	
	# Các nốt ngân được x2 thời lượng để file wav có thời gian phát hết âm thanh đuôi
	# ── Câu 1: "Lòng mẹ bao la như biển Thái Bình" ──
	var melody_1 = [
		[5, 1.5], [4, 0.5], [5, 1.0], [3, 1.5], [4, 0.5], [3, 1.0],
		[2, 1.5], [3, 1.0], [4, 3.0],
	]
	# ── Câu 2: "Dạt dào như nước trong nguồn" ──
	var melody_2 = [
		[4, 1.0], [3, 0.5], [2, 1.5], [3, 1.0], [4, 1.0],
		[5, 1.5], [4, 1.5], [5, 3.0],
	]
	# ── Câu 3: "Ôi lòng mẹ, bao la như biển Thái Bình" (cao trào) ──
	var melody_3 = [
		[3, 1.5], [2, 0.5], [1, 1.0], [2, 1.5], [3, 0.5], [2, 1.0],
		[1, 2.0], [2, 1.0], [3, 3.0],
	]
	# ── Câu 4: "Tình mẹ tha thiết như dòng suối hiền" ──
	var melody_4 = [
		[3, 1.0], [4, 1.0], [3, 1.5], [2, 0.5], [3, 1.0],
		[4, 1.5], [5, 1.5], [5, 3.0],
	]
	# ── Đoạn kết: "Mẹ ơi... con yêu mẹ" (ngân nga) ──
	var melody_5 = [
		[4, 1.5], [3, 2.0], [2, 1.0],
		[3, 1.5], [4, 1.5], [5, 4.0],
	]

	for section in [melody_1, melody_2, melody_3, melody_4, melody_5]:
		for note_info in section:
			var lane: int = note_info[0]
			var dur: float = note_info[1] * beat
			notes.append(NoteData.new(lane, t, 0.0, 0))
			t += dur
		t += beat # Nghỉ giữa các câu

func _load_su_thanh_hoa() -> void:
	# "Sứ Thanh Hoa" - phiên bản Đàn Bầu
	# Chuyển soạn từ bản gốc sang 6 điểm hài âm
	var t = 2.0
	var beat = 0.6
	
	var sheet = [
		5, 3, 4, 3, 3, 4, 3, 3, 4, 3, 4, 1,
		5, 3, 4, 3, 3, 4, 3, 3, 2, 5, 3, 1, 4, 2,
		2, 5, 2, 5, 2, 1, 2, -1, 2, 2, 5,
		3, 2, 5, 5, 3, 4, 3, 3, 4, 3,
		4, 1, 1, 4, 2, 1, 1, 2, 1, 1, 2, 5, 3, 3,
		5, 3, 5, 2, 5, 5, 3, 5, 3, 5, 3, 3, 4, 3, 5, 5
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
			notes.append(NoteData.new(lane, t, 0.0, 0))
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
