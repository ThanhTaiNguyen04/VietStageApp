extends RefCounted

## Bundled SaoTruc data, independent from API DTOs and scene scripts.
## Preserve stable IDs used by saved progress/stars. Never overwrite from API.
## Mutable consumers use duplicate(true). Runtime logic and media remain separate.

# Source: LessonSaoTrucList.gd / ALL_LESSONS
const ALL_LESSONS = [
	{
		"id": "sao_truc_level1_1_video", "level": 1, "title": "BÀI 1", "note": "Làm quen Sáo Trúc",
		"video": "Cách cầm sáo trúc & lấy hơi.", "practice": "Thực hành cầm sáo.", "subtitles": []
	},
	{
		"id": "Node2", "level": 2, "title": "BÀI 1", "note": "Nốt Si (B4)",
		"video": "Hướng dẫn thổi nốt Si.", "practice": "Thực hành nốt Si.", "subtitles": []
	},
	{
		"id": "Node3", "level": 2, "title": "BÀI 2", "note": "Nốt La (A4)",
		"video": "Hướng dẫn thổi nốt La.", "practice": "Thực hành nốt La.", "subtitles": []
	},
	{
		"id": "Node4", "level": 2, "title": "BÀI 3", "note": "Nốt Sol (G4)",
		"video": "Hướng dẫn thổi nốt Sol.", "practice": "Thực hành nốt Sol.", "subtitles": []
	},
	{
		"id": "Node5", "level": 2, "title": "BÀI 4", "note": "Nốt Fa (F4)",
		"video": "Hướng dẫn thổi nốt Fa.", "practice": "Thực hành nốt Fa.", "subtitles": []
	},
	{
		"id": "Node6", "level": 2, "title": "BÀI 5", "note": "Nốt Mi (E4)",
		"video": "Hướng dẫn thổi nốt Mi.", "practice": "Thực hành nốt Mi.", "subtitles": []
	},
	{
		"id": "Node7", "level": 2, "title": "BÀI 6", "note": "Nốt Rê (D4)",
		"video": "Hướng dẫn thổi nốt Rê.", "practice": "Thực hành nốt Rê.", "subtitles": []
	},
	{
		"id": "Node8", "level": 2, "title": "BÀI 7", "note": "Nốt Đô (C4)",
		"video": "Hướng dẫn thổi nốt Đô.", "practice": "Thực hành nốt Đô.", "subtitles": []
	},
	{
		"id": "sao_truc_level3_1", "level": 3, "title": "BÀI 1", "note": "Khúc Nhạc Vui (Khung 1)"
	},
	{
		"id": "sao_truc_level3_2", "level": 3, "title": "BÀI 2", "note": "Khúc Nhạc Vui (Khung 2)"
	},
	{
		"id": "sao_truc_level3_3", "level": 3, "title": "BÀI 3", "note": "Khúc Nhạc Vui (Khung 3)"
	},
	{
		"id": "sao_truc_level3_4", "level": 3, "title": "BÀI 4", "note": "Khúc Nhạc Vui (Khung 4)"
	},
	{
		"id": "sao_truc_level3_5", "level": 3, "title": "BÀI 5", "note": "Khúc Nhạc Vui (Khung 5)"
	},
	{
		"id": "sao_truc_level3_6", "level": 3, "title": "BÀI 6", "note": "Khúc Nhạc Vui (Hoàn chỉnh)"
	},
	{
		"id": "sao_truc_level4_1", "level": 4, "title": "BÀI 1", "note": "Inh Lả Ơi (Câu 1)"
	},
	{
		"id": "sao_truc_level4_2", "level": 4, "title": "BÀI 2", "note": "Inh Lả Ơi (Câu 2)"
	},
	{
		"id": "sao_truc_level4_3", "level": 4, "title": "BÀI 3", "note": "Inh Lả Ơi (Câu 3)"
	},
	{
		"id": "sao_truc_level4_4", "level": 4, "title": "BÀI 4", "note": "Inh Lả Ơi (Câu 4)"
	},
	{
		"id": "sao_truc_level4_5", "level": 4, "title": "BÀI 5", "note": "Inh Lả Ơi (Hoàn chỉnh)"
	},
	{
		"id": "sao_truc_level5_1", "level": 5, "title": "BÀI 1", "note": "Futari no Kimochi (Đoạn 1 - P1)"
	},
	{
		"id": "sao_truc_level5_2", "level": 5, "title": "BÀI 2", "note": "Futari no Kimochi (Đoạn 1 - P2)"
	},
	{
		"id": "sao_truc_level5_3", "level": 5, "title": "BÀI 3", "note": "Futari no Kimochi (Đoạn 1 - HC)"
	},
	{
		"id": "sao_truc_level5_4", "level": 5, "title": "BÀI 4", "note": "Futari no Kimochi (Đoạn 2 - P1)"
	},
	{
		"id": "sao_truc_level5_5", "level": 5, "title": "BÀI 5", "note": "Futari no Kimochi (Đoạn 2 - P2)"
	},
	{
		"id": "sao_truc_level5_6", "level": 5, "title": "BÀI 6", "note": "Futari no Kimochi (Đoạn 2 - HC)"
	},
	{
		"id": "sao_truc_level5_7", "level": 5, "title": "BÀI 7", "note": "Futari no Kimochi (Hoàn chỉnh toàn bài)"
	},
	{ "id": "Node35", "level": 6, "title": "BÀI 1", "note": "Gặp Mẹ Trong Mơ (Khung 1)" },
	{ "id": "Node36", "level": 6, "title": "BÀI 2", "note": "Gặp Mẹ Trong Mơ (Khung 2)" },
	{ "id": "Node37", "level": 6, "title": "BÀI 3", "note": "Gặp Mẹ Trong Mơ (Khung 3)" },
	{ "id": "Node38", "level": 6, "title": "BÀI 4", "note": "Gặp Mẹ Trong Mơ (Khung 4)" },
	{ "id": "Node39", "level": 6, "title": "BÀI 5", "note": "Gặp Mẹ Trong Mơ (Khung 5)" },
	{ "id": "Node40", "level": 6, "title": "BÀI 6", "note": "Gặp Mẹ Trong Mơ (Khung 6)" },
	{ "id": "Node41", "level": 6, "title": "BÀI 7", "note": "Gặp Mẹ Trong Mơ (Khung 7)" },
	{ "id": "Node42", "level": 6, "title": "BÀI 8", "note": "Gặp Mẹ Trong Mơ (Hoàn chỉnh)" }
]

# Source: PracticeSaoTruc.gd / LANES
const PRACTICE_LANES := ["Đô", "Rê", "Mi", "Fa", "Sol", "La", "Si", "Đô2", "Rê2", "Mi2", "Fa2", "Sol2", "La2", "Si2", "Đô3"]

# Source: PracticeSaoTruc.gd / FREQS
const PRACTICE_FREQS := {
	"Đô": 523.25, # C5 (Vietnamese Sáo C5 Đô lowest note)
	"Rê": 587.33, # D5
	"Mi": 659.25, # E5
	"Fa": 698.46, # F5
	"Sol": 783.99, # G5
	"La": 880.00, # A5
	"Si": 987.77,  # B5
	"Đô2": 1046.50, # C6
	"Rê2": 1174.66, # D6
	"Mi2": 1318.51, # E6
	"Fa2": 1396.91, # F6
	"Sol2": 1567.98, # G6
	"La2": 1760.00, # A6
	"Si2": 1975.53,  # B6
	"Đô3": 2093.00 # C7
}

# Source: PracticeSaoTruc.gd / FINGERINGS
const PRACTICE_FINGERINGS := {
	"Đô": [true, true, true, true, true, true],
	"Rê": [true, true, true, true, true, false],
	"Mi": [true, true, true, true, false, false],
	"Fa": [true, true, true, false, false, false],
	"Sol": [true, true, false, false, false, false],
	"La": [true, false, false, false, false, false],
	"Si": [false, false, false, false, false, false],
	"Đô2": [true, true, true, true, true, true],
	"Rê2": [true, true, true, true, true, false],
	"Mi2": [true, true, true, true, false, false],
	"Fa2": [true, true, true, false, false, false],
	"Sol2": [true, true, false, false, false, false],
	"La2": [true, false, false, false, false, false],
	"Si2": [false, false, false, false, false, false],
	"Đô3": [true, true, true, true, true, true]
}

# Source: PracticeSaoTruc.gd / NOTES_VN
const PRACTICE_NOTES_VN : Array[String] = [
	"Đô", "Rê", "Mi", "Fa", "Sol", "La", "Si",
	"Đô2", "Rê2", "Mi2", "Fa2", "Sol2", "La2", "Si2", "Đô3"
]

# Source: PracticeSaoTruc.gd / SPEECHES
const PRACTICE_SPEECHES : Array[String] = [
	"Thở đều, môi khép nhẹ.",
	"Giữ hơi ổn định nhé.",
	"Tốt lắm, âm rõ rồi.",
	"Cổ tay thả lỏng, đừng gồng.",
]

# Source: PracticeSaoTruc.gd / sheet_notes
const PRACTICE_SHEET_NOTES : Array[String] = [
	"Đô", "Rê", "Mi", "Fa", "Sol", "La", "Si"
]

# Source: PracticeSaoTruc.gd / sheet_durations
const PRACTICE_SHEET_DURATIONS : Array[float] = [
	2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0
]

# Source: PracticeSaoTruc.gd / songs_list
const PRACTICE_SONGS_LIST : Array[Dictionary] = [
	{
		"title": "Inh Lả Ơi",
		"bpm": 110.0,
		"sheet": [
			"Đô2", "La", "Si", "Đô2", "Rest", "Đô2", "Sol", "La", "Rest", "Đô2", "Sol",
			"Fa", "Đô2", "Si", "La", "Sol", "Rest", "Fa", "La", "Đô2", "Sol",
			"Sol", "Sol", "Fa", "Fa", "Rest", "Đô2", "Sol", "La", "Rest", "Đô2", "Sol", "Đô2", "Rest"
		],
		"durations": [
			1.0, 0.5, 0.5, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
			1.0, 1.0, 0.5, 0.5, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
			1.0, 0.5, 0.5, 1.0, 1.0, 1.0, 0.5, 0.5, 1.0, 1.0, 1.0, 1.0, 1.0
		]
	},
	{
		"title": "Futari no Kimochi",
		"bpm": 88.0,
		"sheet": [
			"Rê", "Fa", "Sol", "Sol", "Sib", "Đô2", "Rê2", "Fa2", "Rê2", "Đô2", "Sib", "Sol",
			"Rê2", "Đô2", "Sol", "Rê2", "Đô2", "Sol", "Fa", "Rê",
			"Rê", "Fa", "Sol", "Sol", "Sib", "Đô2", "Rê2", "Fa2", "Rê2", "Đô2", "Sib", "Sol",
			"Rê2", "Đô2", "Sol", "Rê2", "Đô2", "Sol", "Fa", "Sol",
			"Rê2", "Fa2", "Sol2", "Fa2", "Sol2", "La2", "Fa2", "Sol2", "Fa2", "Đô2", "Rê2",
			"Rê2", "Fa2", "Sol2", "Fa2", "Sol2", "Sib2", "La2", "Fa2", "Rê2",
			"Rê2", "Fa2", "Sol2", "Fa2", "Sol2", "La2", "Fa2", "Sol2", "Fa2", "Đô2", "Rê2",
			"Rê2", "Đô2", "Sol", "Rê2", "Đô2", "Sol", "Fa", "Sol"
		],
		"durations": [
			0.5, 0.5, 0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5,
			0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 1.0, 2.0,
			0.5, 0.5, 0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5,
			0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 1.0, 2.0,
			0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5, 2.0,
			0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 1.0, 1.0, 2.0,
			0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5, 2.0,
			0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 1.0, 2.0
		]
	},
	{
		"title": "Lý Hoài Nam",
		"bpm": 80.0,
		"sheet": ["Đô", "Đô", "Rê", "Mi", "Mi", "Fa", "Sol", "Fa", "Mi", "Rê", "Đô"],
		"durations": [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0]
	},
	{
		"title": "Lòng Mẹ",
		"bpm": 76.0,
		"sheet": ["Đô", "Mi", "Sol", "La", "Sol", "Mi", "Rê", "Mi", "Rê", "Đô", "Đô"],
		"durations": [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0]
	},
	{
		"title": "Trống Cơm",
		"bpm": 100.0,
		"sheet": ["Sol", "La", "Si", "Sol", "La", "Sol", "Fa", "Mi", "Rê", "Mi", "Đô"],
		"durations": [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0]
	}
]

# Source: LessonSaoTruc.gd / LESSON_NOTES
const LESSON_NOTES = {
	"Node1": {"note": "Đô", "desc": "Kỹ thuật đặt sáo vào môi và cách thổi sao cho ra âm thanh (tạo khẩu hình môi).", "fingers": [true, true, true, true, true, true]},
	"Node2": {"note": "Si", "desc": "Mở toàn bộ 6 lỗ, không che lỗ nào", "fingers": [false, false, false, false, false, false]}, # Si
	"Node3": {"note": "La", "desc": "Bấm ngón tay vào lỗ đầu tiên", "fingers": [true, false, false, false, false, false]},
	"Node4": {"note": "Sol", "desc": "Bấm ngón tay vào 2 lỗ đầu tiên", "fingers": [true, true, false, false, false, false]},
	"Node5": {"note": "Fa", "desc": "Bấm ngón tay vào 3 lỗ", "fingers": [true, true, true, false, false, false]},
	"Node6": {"note": "Mi", "desc": "Bấm ngón tay vào 4 lỗ", "fingers": [true, true, true, true, false, false]},
	"Node7": {"note": "Rê", "desc": "Bấm ngón tay vào 5 lỗ", "fingers": [true, true, true, true, true, false]},
	"Node8": {"note": "Đô", "desc": "Bấm cả 6 lỗ và thổi nhẹ", "fingers": [true, true, true, true, true, true]},
		"Node9": {"note": "Đô", "desc": "Tập thổi nốt Đô", "fingers": [true, true, true, true, true, true]},
	"Node10": {"note": "Sol", "desc": "Tập thổi nốt Sol", "fingers": [true, true, false, false, false, false]},
	"Node11": {"note": "Đô", "desc": "Ghép Đô và Sol", "fingers": [true, true, true, true, true, true]},
	"Node12": {"note": "La", "desc": "Tập thổi nốt La", "fingers": [true, false, false, false, false, false]},
	"Node13": {"note": "Đô", "desc": "Câu nhạc 1", "fingers": [true, true, true, true, true, true]},
	"Node14": {"note": "Fa", "desc": "Tập thổi nốt Fa", "fingers": [true, true, true, false, false, false]},
	"Node15": {"note": "Mi", "desc": "Tập thổi nốt Mi", "fingers": [true, true, true, true, false, false]},
	"Node16": {"note": "Rê", "desc": "Tập thổi nốt Rê", "fingers": [true, true, true, true, true, false]},
	"Node17": {"note": "Fa", "desc": "Câu nhạc 2", "fingers": [true, true, true, false, false, false]},
	"Node18": {"note": "Đô", "desc": "Thi Đậu Khúc Nhạc Vui", "fingers": [true, true, true, true, true, true]},
	"Node19": {"note": "Đô2", "desc": "Tập thổi nốt Đô2 (C6)", "fingers": [true, true, true, true, true, true], "title": "Tập nốt Đô2"},
	"Node20": {"note": "Rê2", "desc": "Tập thổi nốt Rê2 (D6)", "fingers": [true, true, true, true, true, false], "title": "Tập nốt Rê2"},
	"Node21": {"note": "Đô2", "desc": "Luyện chuyển ngón Đô2 - Rê2", "fingers": [true, true, true, true, true, true], "title": "Chuyển ngón C6-D6"},
	"Node22": {"note": "Sol", "desc": "Tập thổi nốt Sol trầm (G5)", "fingers": [true, true, false, false, false, false], "title": "Tập nốt Sol"},
	"Node23": {"note": "Đô2", "desc": "Thổi câu nhạc mở đầu bài Trống Cơm", "fingers": [true, true, true, true, true, true], "title": "Mở đầu Trống Cơm"},
	"Node24": {"note": "Fa", "desc": "Tập thổi nốt Fa trầm (F5)", "fingers": [true, true, true, false, false, false], "title": "Tập nốt Fa"},
	"Node25": {"note": "Đô2", "desc": "Khen ai khéo vỗ mấy bông", "fingers": [true, true, true, true, true, true], "title": "Câu nhạc 2"},
	"Node26": {"note": "Đô2", "desc": "Ghép toàn bộ Đoạn 1 hoàn chỉnh", "fingers": [true, true, true, true, true, true], "title": "Hoàn thành Đoạn 1"},
	"Node27": {"note": "Mi2", "desc": "Một vầy tang tình con sít", "fingers": [true, true, true, true, false, false], "title": "Học Đoạn 2"},
	"Node28": {"note": "Đô2", "desc": "Thổi trọn vẹn bài Trống Cơm với nhạc đệm", "fingers": [true, true, true, true, true, true], "title": "Thi Đấu Trống Cơm"}
}

# Source: LessonSaoTruc.gd / LESSON_DIALOGUES
const LESSON_DIALOGUES = {
	"Node1": {
		"intro": "Chào bạn! Bài học quan trọng nhất của Sáo Trúc là kỹ thuật đặt khẩu hình môi. Hãy mỉm cười nhẹ, đặt lỗ thổi lên môi dưới, hướng luồng hơi cắt ngang qua lỗ thổi nhé!",
		"mid": "Tuyệt vời! Bạn đã thổi ra tiếng sáo chuẩn xác chứ không chỉ là tiếng gió. Giờ chúng ta sẽ bắt đầu học bấm ngón nhé!"
	},
	"Node2": {
		"intro": "Chào bạn! Đây là bài học Sáo Trúc thứ 2. Nốt Si là nốt cơ bản nhất, âm thanh thanh thoát và nhẹ nhàng. Để thổi nốt Si, bạn chỉ cần mở toàn bộ 6 lỗ, không che lỗ nào. Hãy cầm sáo lên và thổi một luồng hơi ấm dịu nhé!",
		"mid": "Tuyệt vời! Bạn có thấy âm thanh nốt Si thật trong trẻo không? Bây giờ, hãy cùng chơi một bản nhạc nhỏ để làm quen với nhịp điệu nhé!"
	},
	"Node3": {
		"intro": "Chào mừng bạn trở lại! Hôm nay chúng ta sẽ chinh phục nốt La. Nốt La có âm sắc trầm hơn nốt Si một chút. Bấm ngón tay trỏ tay trái vào lỗ đầu tiên thật kín và thổi nhẹ nào!",
		"mid": "Rất tốt! Âm La nghe rất vang và ấm đúng không? Bây giờ hãy thử kết hợp nốt La với nốt Si vừa học trong một thử thách nhịp điệu nhé!"
	},
	"Node4": {
		"intro": "Bạn tiến bộ nhanh lắm! Nốt tiếp theo là nốt Sol. Hãy dùng hai ngón tay che kín 2 lỗ đầu tiên. Nhớ là các ngón tay phải bịt thật kín mặt lỗ để âm thanh không bị xì nhé!",
		"mid": "Xuất sắc! Việc chuyển ngón giữa các nốt Si, La, Sol là nền tảng của rất nhiều bài nhạc hay. Chúng ta cùng tập ghép chúng lại nào!"
	},
	"Node5": {
		"intro": "Hôm nay chúng ta học nốt Fa! Âm Fa mang lại cảm giác hơi man mác buồn. Bịt kín 3 lỗ đầu tiên nhé. Cẩn thận ngón áp út tay trái thường hay hở nhất đấy!",
		"mid": "Hay lắm! Càng bịt nhiều lỗ, hơi thổi của bạn cần phải đều đặn hơn. Hãy sẵn sàng cho thử thách bấm thả liên tục nhé!"
	},
	"Node6": {
		"intro": "Chào bạn! Đã đến lúc dùng đến bàn tay phải rồi. Để thổi nốt Mi, bạn che 4 lỗ đầu. Hãy thả lỏng cổ tay phải và đặt ngón trỏ thật tự nhiên nhé!",
		"mid": "Thật tuyệt vời! Bạn đã điều khiển được bàn tay phải rồi đó. Hãy cùng chơi một giai điệu để kết hợp cả hai tay nhé!"
	},
	"Node7": {
		"intro": "Sắp chinh phục được toàn bộ các nốt cơ bản rồi! Nốt Rê yêu cầu bạn bịt 5 lỗ. Cột hơi bây giờ cần phải sâu và nén tốt hơn. Hãy hít một hơi thật sâu nào!",
		"mid": "Giỏi lắm! Âm Rê rung lên rất êm ái. Chơi tốt nốt này chứng tỏ kỹ năng kiểm soát hơi của bạn đã tiến bộ vượt bậc!"
	},
	"Node8": {
		"intro": "Chúc mừng bạn đã đến với nốt trầm nhất của cây sáo: Nốt Đô! Bịt kín toàn bộ 6 lỗ. Hãy thổi thật khẽ và ấm, vì nếu thổi mạnh nó sẽ vút lên nốt cao đấy!",
		"mid": "Hoàn hảo! Cảm nhận độ rung của thân sáo khi thổi nốt Đô thật thích đúng không? Giờ là lúc kết hợp toàn bộ 6 nốt để tạo nên phép màu!"
	},
		"Node9": {
		"intro": "Chào mừng bạn đến với Hành Trình Khúc Nhạc Vui! Bài hát đầu tiên của chúng ta rất dễ thương. Bắt đầu bằng nốt Đô nhé.",
		"mid": "Tốt lắm! Nốt Đô là nốt trầm ấm. Hãy chuẩn bị bắt nhịp để thổi nốt Đô theo nhạc rơi nhé!"
	},
	"Node10": {
		"intro": "Tiếp theo, chúng ta học nốt Sol. Bấm 2 lỗ đầu tiên. Nốt Sol trong trẻo và vang vọng.",
		"mid": "Giỏi lắm! Giờ hãy thổi nốt Sol theo nhịp điệu rơi xuống nhé!"
	},
	"Node11": {
		"intro": "Bây giờ chúng ta ghép 2 nốt Đô và Sol với nhau nhé! Luyện tập chuyển ngón thật nhanh.",
		"mid": "Tay bạn đã bắt đầu dẻo dai rồi. Sẵn sàng cho thử thách rơi nốt Đô và Sol chưa?"
	},
	"Node12": {
		"intro": "Nốt La! Bấm 1 lỗ duy nhất. Đây là nốt cao nhất trong câu đầu tiên của bài hát.",
		"mid": "Tuyệt vời! Bây giờ luyện tập thổi nốt La theo nhịp điệu nhé."
	},
	"Node13": {
		"intro": "Lắp ráp câu nhạc 1: Đô Đô Sol Sol La La Sol. Bạn hãy chú ý nhịp điệu nhẹ nhàng và tươi vui nhé!",
		"mid": "Hoàn hảo! Tay và hơi của bạn đã sẵn sàng. Cùng thổi câu 1 nào!"
	},
	"Node14": {
		"intro": "Học tiếp nửa bài sau nhé. Bắt đầu với nốt Fa. Bấm 3 lỗ, âm thanh hơi trầm buồn một chút.",
		"mid": "Fa rất tốt! Cùng luyện tập nhịp điệu nốt Fa nhé."
	},
	"Node15": {
		"intro": "Thêm nốt Mi. Bấm 4 lỗ. Đừng quên giữ hơi thật đều để nốt không bị chênh phô nhé.",
		"mid": "Rất êm ái! Giờ hãy theo dõi nốt rơi và thổi nốt Mi."
	},
	"Node16": {
		"intro": "Nốt Rê! Bấm 5 lỗ. Gần như kín hết các lỗ rồi, hãy thổi hơi sâu hơn một chút.",
		"mid": "Kiểm soát hơi rất tốt! Chuẩn bị thổi nốt Rê theo nhịp nhé."
	},
	"Node17": {
		"intro": "Ghép câu nhạc 2: Fa Fa Mi Mi Rê Rê Đô. Các nốt đi dần xuống trầm, hãy thả lỏng tay.",
		"mid": "Tuyệt vời, bạn đã thuộc hết các nốt! Hãy thổi đoạn nhạc này nhé."
	},
	"Node18": {
		"intro": "Thử Thách Cuối Cùng! Thi Đậu Bài Hát Khúc Nhạc Vui trọn vẹn. Bạn cần đạt trên 75% độ chính xác để qua ván này!",
		"mid": "Sẵn sàng chưa? Khúc Nhạc Vui xin được phép bắt đầu!"
	},
	"Node19": {
		"intro": "Chào bạn! Bắt đầu học Trống Cơm nhé. Nốt Đô2 (C6) là nốt khá cao, hãy thổi hơi tập trung và bịt kín cả 6 lỗ nhé!",
		"mid": "Rất tốt! Cùng luyện tập nhịp điệu nốt Đô2 nào!"
	},
	"Node20": {
		"intro": "Học nốt Rê2. Che 5 lỗ đầu tiên và hé lỗ cuối. Thổi hơi sâu để nốt bay cao nhé!",
		"mid": "Tuyệt vời, Rê2 nghe rất vang. Thổi theo nhịp nào!"
	},
	"Node21": {
		"intro": "Bây giờ hãy tập ghép Đô2 và Rê2 nhé. Di chuyển ngón út thật linh hoạt!",
		"mid": "Sắp được rồi! Sẵn sàng chơi theo nhịp rơi Đô2 và Rê2 chưa?"
	},
	"Node22": {
		"intro": "Luyện lại nốt Sol trầm để chuẩn bị vào bài. Che 2 lỗ đầu tiên.",
		"mid": "Tốt lắm! Thổi nốt Sol thật ấm nhé."
	},
	"Node23": {
		"intro": "Học câu nhạc 1 của Trống Cơm: Sol Sol Đô2 Đô2 Rê2 Đô2 Sol. Giai điệu mở đầu siêu quen thuộc!",
		"mid": "Tuyệt lắm! Cùng chinh phục câu nhạc mở đầu nhé!"
	},
	"Node24": {
		"intro": "Ôn lại nốt Fa để chuẩn bị cho câu tiếp theo. Che 3 lỗ đầu tiên.",
		"mid": "Rất chuẩn! Thổi nốt Fa theo nhịp nào."
	},
	"Node25": {
		"intro": "Học câu nhạc 2: Khen ai khéo vỗ... Sol Fa Sol Đô2 Sol Đô2 Đô2 Đô2 Sol Sol Fa Sol. Hãy chú ý các nốt luyến!",
		"mid": "Hay lắm! Chuẩn bị thổi theo nhịp nào!"
	},
	"Node26": {
		"intro": "Ghép toàn bộ Đoạn 1 bài Trống Cơm! Nhịp điệu dồn dập, tươi vui và đầy sức sống.",
		"mid": "Chuẩn bị nhạc đệm. Cố gắng đạt độ chính xác cao nhé!"
	},
	"Node27": {
		"intro": "Bắt đầu Đoạn 2: Một vầy tang tình con sít... Đô2 Đô2 Rê2 Đô2 Rê2 Mi2. Chú ý nốt Mi2 cao nhé!",
		"mid": "Tốt lắm! Luyện tập câu sít lội sông nào!"
	},
	"Node28": {
		"intro": "Đã đến lúc Biểu Diễn Trống Cơm! Hãy thổi trọn vẹn bản nhạc dân ca Bắc Ninh đầy tự hào này nhé!",
		"mid": "Sẵn sàng chưa? Khúc nhạc Trống Cơm bắt đầu!"
	}
}

# Source: LessonSaoTruc.gd / NOTE_FREQS
const NOTE_FREQS = {
	# Octave 5 (Vietnamese bamboo flute in C - primary range)
	"Đô": 523.25,
	"Rê": 587.33,
	"Mi": 659.25,
	"Fa": 698.46,
	"Sol": 783.99,
	"La": 880.00,
	"Sib": 932.33,
	"Si": 987.77,
	# Octave 6 (high register)
	"Đô2": 1046.50,
	"Rê2": 1174.66,
	"Mi2": 1318.51,
	"Fa2": 1396.91,
	"Sol2": 1567.98,
	"La2": 1760.00,
	"Sib2": 1864.66,
	"Si2": 1975.53,
	# Octave 4 aliases (some flutes produce one octave lower)
	"Đô_low": 261.63,
	"Rê_low": 293.66,
	"Mi_low": 329.63,
	"Fa_low": 349.23,
	"Sol_low": 392.00,
	"La_low": 440.00,
	"Si_low": 493.88
}

