extends Control
class_name LessonDanTranhList

const C_BG := Color("#faf8f5")
const C_SIDEBAR := Color("#f3efe3")
const C_JADE := Color("#173f2d")
const C_JADE_LIGHT := Color("#245f43")
const C_GOLD := Color("#c59626")
const C_GOLD_LIGHT := Color("#f0cb62")
const C_GOLD_DARK := Color("#7a5b12")
const C_TEXT := Color("#21140d")
const C_MUTED := Color("#6f6257")
const C_CARD := Color("#fffdf8")

const LearningActivityContextScript := preload("res://scripts/LearningActivityContext.gd")

static var selected_level: int = 1
const REQUIRE_SEQUENTIAL_UNLOCK := false # Tìm mở toàn bộ bài; đổi thành true để khôi phục lộ trình tuần tự.
var _sidebar_icon_cache: Dictionary = {}

const LEVELS := [
	{
		"level": 1,
		"title": "LÝ THUYẾT VÀ NHẠC LÝ CƠ BẢN",
		"sessions": "Bài 1–9",
		"objective": "Làm quen đàn tranh, tư thế, nhạc lý cơ bản và luyện từng nốt ở các quãng thấp, trung, cao.",
		"lessons": [
			{
				"number": 1,
				"title": "Giới thiệu, nhạc lý và tư thế tay & đàn",
				"type": "both",
				"video": "Xem video hướng dẫn lý thuyết nhạc lý, cấu tạo đàn tranh và tư thế ngồi, tư thế tay chuẩn.",
				"practice": "Nhận biết âm sắc dây đàn và làm quen tư thế tay gảy.",
				"practice_title": "Làm quen âm sắc & tư thế",
				"sheet": ["Sol1", "La1", "Đô2", "Rê2", "Mi2"],
				"durations": [1.5, 1.5, 1.5, 1.5, 2.0]
			},
			{
				"number": 2,
				"title": "Luyện tập 10 nốt cơ bản quãng thấp & trung",
				"type": "practice",
				"video": "Cách nhận diện cao độ 10 nốt nhạc cơ bản ở quãng thấp và trung trên Đàn Tranh.",
				"practice": "Gảy lần lượt từng nốt: Sol1, La1, Đô2, Rê2, Mi2, Sol2, La2, Đô3, Rê3, Mi3.",
				"practice_title": "Luyện tập 10 nốt cơ bản",
				"sheet": ["Sol1", "La1", "Đô2", "Rê2", "Mi2", "Sol2", "La2", "Đô3", "Rê3", "Mi3"],
				"durations": [1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 2.0]
			},
			{
				"number": 3,
				"title": "Luyện tập 7 nốt quãng cao",
				"type": "practice",
				"video": "Cách nhận diện cao độ 7 nốt nhạc ở quãng cao trên khuông nhạc.",
				"practice": "Gảy lần lượt từng nốt: Sol3, La3, Đô4, Rê4, Mi4, Sol4, La4.",
				"practice_title": "Luyện tập 7 nốt quãng cao",
				"sheet": ["Sol3", "La3", "Đô4", "Rê4", "Mi4", "Sol4", "La4"],
				"durations": [1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 2.0]
			},
			{
				"number": 4,
				"title": "Tempo, khóa Sol và số chỉ nhịp 4/4, 2/4",
				"type": "practice",
				"video": "Tìm hiểu định nghĩa Tempo (tốc độ bài nhạc), Khóa Sol, Nhịp 4/4 và Nhịp 2/4 — cách đếm phách và giữ nhịp đều khi chơi.",
				"practice": "Luyện tập giữ nhịp độ đều đặn theo máy đếm nhịp: gảy nốt đen theo nhịp 4/4 (đếm 1-2-3-4) rồi nhịp 2/4 (đếm 1-2).",
				"practice_title": "Tempo, Khóa Sol & Số chỉ nhịp",
				"sheet": [
					"Sol2", "La2", "Đô3", "Rê3",
					"Mi3", "Rê3", "Đô3", "La2",
					"Sol2", "La2", "Đô3", "Rê3",
					"Mi3", "Sol3", "Rê3", "Đô3"
				],
				"durations": [
					1.0, 1.0, 1.0, 1.0,
					1.0, 1.0, 1.0, 1.0,
					1.0, 1.0, 1.0, 1.0,
					1.0, 1.0, 1.0, 2.0
				]
			},
			{
				"number": 5,
				"title": "Nhạc lý: Trường độ nốt nhạc",
				"type": "practice",
				"video": "Tìm hiểu về trường độ nốt nhạc: nốt trắng (2 phách), nốt đen (1 phách), nốt móc đơn (nửa phách), nốt móc kép (1/4 phách).",
				"practice": "Luyện tập nhận diện và gảy phân biệt các nốt có trường độ khác nhau trên khuông nhạc.",
				"practice_title": "Trường độ nốt nhạc",
				"sheet": ["Đô2", "Đô2", "Rê2", "Mi2", "Mi2", "Sol2", "Sol2", "Sol2", "Sol2", "La2", "La2"],
				"durations": [2.0, 2.0, 1.0, 1.0, 1.0, 1.0, 0.5, 0.5, 0.5, 0.25, 0.25]
			},
			{
				"number": 6,
				"title": "Cấu tạo quãng thấp, cao, trầm",
				"type": "both",
				"video": "Tìm hiểu về cấu tạo các quãng âm trên Đàn Tranh và cách nhận biết các quãng trầm, trung, cao.",
				"practice": "Nhận biết âm vực quãng bằng cách gảy các dây tương ứng trên đàn.",
				"practice_title": "Cấu tạo quãng âm",
				"sheet": ["Sol1", "Sol2", "Sol3", "La1", "La2", "La3"],
				"durations": [1.0, 1.0, 1.0, 1.0, 1.0, 2.0]
			},
			{
				"number": 7,
				"title": "Vai trò hai tay & số ngón",
				"type": "both",
				"video": "Tìm hiểu vai trò tay phải gảy đàn, tay trái nhấn rung và quy ước số ngón tay trên đàn Tranh.",
				"practice": "Luyện tập tư thế tay phối hợp cơ bản.",
				"practice_title": "Kỹ thuật hai tay & Số ngón",
				"sheet": ["Đô2", "Rê2", "Mi2", "Sol2", "La2"],
				"durations": [1.0, 1.0, 1.0, 1.0, 2.0]
			},
			{
				"number": 8,
				"title": "Tư thế tay và tư thế đặt đàn",
				"type": "both",
				"video": "Hướng dẫn chi tiết tư thế ngồi khum tay gảy đàn chuẩn xác và tư thế đặt đàn.",
				"practice": "Luyện tập tư thế ngồi thẳng lưng và khum tay gảy thả lỏng.",
				"practice_title": "Tư thế đặt đàn & Tay gảy",
				"sheet": ["Sol1", "La1", "Đô2", "Rê2", "Mi2"],
				"durations": [1.0, 1.0, 1.0, 1.0, 2.0]
			},
			{
				"number": 9,
				"title": "Luyện ngón 1 ngón, 2 ngón, 3 ngón",
				"type": "practice",
				"video": "Bài tập luyện ngón chạy dây cơ bản sử dụng lần lượt 1 ngón, 2 ngón và 3 ngón tay phải.",
				"practice": "Thực hành gảy chuỗi nốt chạy đều sử dụng kỹ thuật luyện ngón phối hợp.",
				"practice_title": "Chạy ngón phối hợp",
				"sheet": ["Đô2", "Rê2", "Mi2", "Rê2", "Đô2", "La1", "Sol1"],
				"durations": [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0]
			}
		]
	},
	{
		"level": 2,
		"title": "LUYỆN THEO BÀI",
		"sessions": "Bài 10–15",
		"objective": "Tập từng đoạn rồi ghép hoàn chỉnh hai bản dân ca: Lý Cây Đa và Sứ Thanh Hoa.",
		"lessons": [
			{
				"number": 10,
				"title": "Lý Cây Đa – Đoạn đầu",
				"type": "practice",
				"video": "Hướng dẫn gảy đoạn đầu bài Lý Cây Đa: giai điệu và ngón gảy.",
				"practice": "Luyện gảy đoạn đầu bài Lý Cây Đa với nhịp độ chậm.",
				"practice_title": "Lý Cây Đa – Đoạn đầu",
				"sheet": ["Sol2", "Sol2", "La2", "Đô3", "Rê3", "Mi3", "Rê3", "Đô3", "La2", "Sol2"],
				"durations": [1.0, 1.0, 0.5, 0.5, 1.0, 1.0, 0.5, 0.5, 1.0, 2.0]
			},
			{
				"number": 11,
				"title": "Lý Cây Đa – Đoạn sau",
				"type": "practice",
				"video": "Hướng dẫn gảy đoạn sau bài Lý Cây Đa.",
				"practice": "Luyện gảy đoạn sau bài Lý Cây Đa.",
				"practice_title": "Lý Cây Đa – Đoạn sau",
				"sheet": ["La2", "Đô3", "Sol2", "La2", "Đô3", "Rê3", "Mi3", "Rê3", "Đô3", "La2", "Sol2", "La2", "Đô3", "Sol2"],
				"durations": [0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 2.0]
			},
			{
				"number": 12,
				"title": "Lý Cây Đa – Ghép cả bài",
				"type": "practice",
				"video": "Ôn tập và ghép hoàn chỉnh bài Lý Cây Đa.",
				"practice": "Luyện đánh cả bài Lý Cây Đa với tiết tấu ổn định.",
				"practice_title": "Lý Cây Đa – Cả bài",
				"sheet": ["Sol2", "Sol2", "La2", "Đô3", "Rê3", "Mi3", "Rê3", "Đô3", "La2", "Sol2", "La2", "Đô3", "Sol2"],
				"durations": [1.0, 1.0, 0.5, 0.5, 1.0, 1.0, 0.5, 0.5, 1.0, 1.0, 0.5, 0.5, 2.0]
			},
			{
				"number": 13,
				"title": "Sứ Thanh Hoa – Đoạn đầu",
				"type": "practice",
				"video": "Hướng dẫn gảy đoạn đầu bài Sứ Thanh Hoa: chuyển quãng và nhấn nhả nốt.",
				"practice": "Luyện gảy đoạn đầu bài Sứ Thanh Hoa ở tốc độ chậm.",
				"practice_title": "Sứ Thanh Hoa – Đoạn đầu",
				"sheet": ["Rê3", "Đô3", "La2", "Đô3", "Đô3", "La2", "Đô3", "Đô3", "La2", "Đô3", "La2", "Sol2"],
				"durations": [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5, 2.0]
			},
			{
				"number": 14,
				"title": "Sứ Thanh Hoa – Đoạn sau",
				"type": "practice",
				"video": "Hướng dẫn gảy đoạn sau bài Sứ Thanh Hoa.",
				"practice": "Luyện gảy đoạn sau bài Sứ Thanh Hoa.",
				"practice_title": "Sứ Thanh Hoa – Đoạn sau",
				"sheet": ["Rê3", "Đô3", "La2", "Đô3", "Đô3", "La2", "Đô3", "Đô3", "Mi3", "Rê3", "Đô3", "Sol2", "La2", "Mi3", "Mi3", "Rê3", "Mi3", "Rê3", "Mi3", "Sol3", "Mi3"],
				"durations": [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 2.0]
			},
			{
				"number": 15,
				"title": "Sứ Thanh Hoa – Ghép cả bài",
				"type": "practice",
				"video": "Ôn tập và ghép hoàn chỉnh bài Sứ Thanh Hoa.",
				"practice": "Luyện đánh cả bài Sứ Thanh Hoa ở BPM 80 với các quãng rộng.",
				"practice_title": "Sứ Thanh Hoa – Cả bài",
				"sheet": [
					"Rê3", "Đô3", "La2", "Đô3", "Đô3", "La2", "Đô3", "Đô3", "La2", "Đô3", "La2", "Sol2",
					"Rê3", "Đô3", "La2", "Đô3", "Đô3", "La2", "Đô3", "Đô3", "Mi3", "Rê3", "Đô3", "Sol2", "La2", "Mi3",
					"Mi3", "Rê3", "Mi3", "Rê3", "Mi3", "Sol3", "Mi3", "Rest", "Mi3", "Mi3", "Rê3",
					"Đô3", "Mi3", "Rê3", "Rê3", "Đô3", "La2", "Đô3", "Đô3", "La2", "Đô3",
					"La2", "Sol2", "Sol2", "La2", "Mi3", "Sol3", "Sol3", "Mi3", "Sol3", "Sol3", "Mi3", "Rê3", "Đô3", "Đô3",
					"Rê3", "Đô3", "Rê3", "Mi3", "Rê3", "Rê3", "Đô3", "Rê3", "Đô3", "Rê3", "Đô3", "Đô3", "La2", "Đô3", "Rê3", "Rê3", "Rê3"
				],
				"durations": [
					0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5, 2.0,
					0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5,
					0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 1.0, 0.5, 0.5, 2.0,
					0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 3.0,
					1.0, 1.0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5,
					0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 2.0
				]
			}
		]
	},
	{
		"level": 3,
		"title": "KỸ THUẬT NÂNG CAO",
		"sessions": "Bài 16–19",
		"objective": "Làm chủ các kỹ thuật tay trái và tay phải đặc trưng: á/vuốt, nhấn, rung và song thanh.",
		"lessons": [
			{
				"number": 16,
				"title": "Kỹ năng á (vuốt 17 dây)",
				"type": "practice",
				"video": "Kỹ thuật á/vuốt lướt qua các dây để tạo âm rền liền mạch trên cả 17 dây.",
				"practice": "Gảy vuốt từ dây trầm nhất lên dây cao nhất rồi ngược lại, giữ âm đều.",
				"practice_title": "Kỹ năng á – Vuốt 17 dây",
				"sheet": ["Sol1", "La1", "Đô2", "Rê2", "Mi2", "Sol2", "La2", "Đô3", "Rê3", "Mi3", "Sol3", "La3", "Đô4", "Rê4", "Mi4", "Sol4", "La4"],
				"durations": [0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 1.0]
			},
			{
				"number": 17,
				"title": "Kỹ năng nhấn ra nốt Si và nốt Fa",
				"type": "practice",
				"video": "Kỹ thuật nhấn dây bằng tay trái để tạo nốt Fa từ Mi và nốt Si từ La.",
				"practice": "Gảy Mi2 rồi nhấn thành Fa2; gảy La2 rồi nhấn thành Si2; lặp lại ở quãng cao.",
				"practice_title": "Nhấn ra Si và Fa",
				"sheet": ["Mi2", "Fa2", "La2", "Si2", "Mi3", "Fa3", "La3", "Si3"],
				"durations": [1.0, 1.5, 1.0, 1.5, 1.0, 1.5, 1.0, 2.0],
				"cues": ["circle", "press", "circle", "press", "circle", "press", "circle", "press"]
			},
			{
				"number": 18,
				"title": "Kỹ năng rung dây bằng tay trái",
				"type": "practice",
				"video": "Kỹ thuật rung tay trái (vibrato) tạo âm ngân luyến truyền cảm, linh hồn Đàn Tranh.",
				"practice": "Gảy nốt ngân dài và rung đều tay trái giữ âm vang.",
				"practice_title": "Rung dây Đàn Tranh",
				"sheet": ["Đô2", "Đô2", "Rê2", "Rê2", "Mi2", "Mi2", "Sol2", "Sol2"],
				"durations": [2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0],
				"cues": ["hold", "hold", "hold", "hold", "hold", "hold", "hold", "hold"]
			},
			{
				"number": 19,
				"title": "Kỹ năng song thanh (rung cùng 1 nốt trên 2 quãng)",
				"type": "practice",
				"video": "Kỹ thuật song thanh: gảy và rung cùng một nốt ở hai quãng cách nhau một quãng tám.",
				"practice": "Gảy đồng thời nốt Sol1+Sol2, La1+La2, Đô2+Đô3… để tạo âm song thanh vang rền.",
				"practice_title": "Song thanh 2 quãng",
				"sheet": ["Sol1+Sol2", "La1+La2", "Đô2+Đô3", "Rê2+Rê3", "Mi2+Mi3", "Sol2+Sol3", "La2+La3", "Đô3+Đô4"],
				"durations": [1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 2.0],
				"cues": ["chord", "chord", "chord", "chord", "chord", "chord", "chord", "chord"]
			}
		]
	},
	{
		"level": 6,
		"title": "HỢP ÂM CƠ BẢN",
		"sessions": "Bài 1-5",
		"objective": "Làm quen với khái niệm hợp âm, thực hành gảy song âm, hợp âm Đô trưởng, La thứ và chuyển hợp âm.",
		"lessons": [
			{
				"number": 13,
				"title": "Bài 1: Hợp âm là gì?",
				"type": "practice",
				"video": "res://Video/DanBauDoan12Bai1.ogv",
				"practice": "Phân biệt nốt đơn và hợp âm. Ôn lại các nốt cơ bản và gảy thử hợp âm Đô trưởng.",
				"practice_title": "Luyện tập: Hợp âm là gì",
				"sheet": ["Sol1", "La1", "Đô2", "Rê2", "Mi2", "Mi2", "Đô2", "La1", "Sol1", "Rê2", "Đô2+Mi2+Sol2"],
				"cues": ["circle", "circle", "circle", "circle", "circle", "triangle", "triangle", "triangle", "triangle", "triangle", "circle"]
			},
			{
				"number": 14,
				"title": "Bài 2: Song âm (2 dây)",
				"type": "practice",
				"video": "res://Video/DanBauDoan12Bai1.ogv",
				"practice": "Làm quen với việc gảy 2 dây cùng lúc (song âm).",
				"practice_title": "Luyện tập: Song âm",
				"sheet": [
					"Đô2+Mi2", "Đô2+Mi2", "Đô2+Mi2",
					"Mi2+Sol2", "Mi2+Sol2", "Mi2+Sol2",
					"La1+Đô2", "La1+Đô2", "La1+Đô2",
					"Đô2+Mi2", "Mi2+Sol2", "La1+Đô2"
				],
				"cues": ["circle", "circle", "circle", "triangle", "triangle", "triangle", "circle", "circle", "circle", "circle", "triangle", "circle"]
			},
			{
				"number": 15,
				"title": "Bài 3: Hợp âm Đô trưởng (C)",
				"type": "practice",
				"video": "res://Video/DanBauDoan12Bai1.ogv",
				"practice": "Hợp âm 3 nốt: Đô, Mi và Sol.",
				"practice_title": "Luyện tập: Đô trưởng",
				"sheet": [
					"Đô2+Mi2+Sol2", "Đô2+Mi2+Sol2", "Đô2+Mi2+Sol2", 
					"Đô2+Mi2+Sol2", "Đô2+Mi2+Sol2",
					"Đô2+Mi2+Sol2", "Đô2+Mi2+Sol2", "Đô2+Mi2+Sol2", "Đô2+Mi2+Sol2"
				],
				"cues": ["circle", "circle", "circle", "circle", "circle", "triangle", "triangle", "triangle", "triangle"]
			},
			{
				"number": 16,
				"title": "Bài 4: Hợp âm La thứ (Am)",
				"type": "practice",
				"video": "res://Video/DanBauDoan12Bai1.ogv",
				"practice": "Hợp âm 3 nốt: La, Đô và Mi.",
				"practice_title": "Luyện tập: La thứ",
				"sheet": [
					"La1+Đô2+Mi2", "La1+Đô2+Mi2", "La1+Đô2+Mi2",
					"Đô2+Mi2+Sol2", "La1+Đô2+Mi2", "Đô2+Mi2+Sol2", "La1+Đô2+Mi2",
					"La1+Đô2+Mi2", "La1+Đô2+Mi2", "La1+Đô2+Mi2", "La1+Đô2+Mi2"
				],
				"cues": ["circle", "circle", "circle", "triangle", "circle", "triangle", "circle", "circle", "circle", "circle", "circle"]
			},
			{
				"number": 17,
				"title": "Bài 5: Chuyển hợp âm",
				"type": "practice",
				"video": "res://Video/DanBauDoan12Bai1.ogv",
				"practice": "Chuyển mượt mà giữa Đô trưởng (C) và La thứ (Am).",
				"practice_title": "Luyện tập: Chuyển hợp âm",
				"sheet": [
					"Đô2+Mi2+Sol2", "La1+Đô2+Mi2", "Đô2+Mi2+Sol2", "La1+Đô2+Mi2",
					"Đô2+Mi2+Sol2", "La1+Đô2+Mi2", "Đô2+Mi2+Sol2", "La1+Đô2+Mi2",
					"Đô2+Mi2+Sol2", "La1+Đô2+Mi2", "La1+Đô2+Mi2", "Đô2+Mi2+Sol2", "Đô2+Mi2+Sol2", "La1+Đô2+Mi2"
				],
				"cues": ["circle", "circle", "circle", "circle", "triangle", "triangle", "triangle", "triangle", "circle", "circle", "triangle", "triangle", "circle", "triangle"]
			}
		]
	}
]

@onready var bg: TextureRect = $BG
@onready var sidebar: PanelContainer = $Root/Sidebar
@onready var btn_menu      : Button         = $Root/Sidebar/SideM/SideV/BtnMenu
@onready var btn_courses   : Button         = $Root/Sidebar/SideM/SideV/BtnCourses
@onready var btn_room      : Button         = $Root/Sidebar/SideM/SideV/BtnRoom
@onready var btn_songs     : Button         = $Root/Sidebar/SideM/SideV/BtnSongs
var btn_account   : Button
var btn_minigame : Button
var btn_leaderboard : Button

@onready var top_bar: PanelContainer = $Root/RightContent/TopBar
@onready var back_btn: Button = $Root/RightContent/TopBar/TopM/TopH/BackBtn
@onready var page_title: Label = $Root/RightContent/TopBar/TopM/TopH/TitleVBox/PageTitle
@onready var objective_label: Label = $Root/RightContent/TopBar/TopM/TopH/TitleVBox/Objective
var change_course_btn: Button
@onready var scroll_container: ScrollContainer = $Root/RightContent/ScrollContainer
@onready var lessons_hbox: HBoxContainer = $Root/RightContent/ScrollContainer/ContentMargin/LessonsHBox

func _ready() -> void:
	btn_account = get_node_or_null("Root/Sidebar/SideM/SideV/BtnAccount")
	change_course_btn = get_node_or_null("Root/RightContent/TopBar/TopM/TopH/ChangeCourseBtn")
	selected_level = clampi(selected_level, 1, LEVELS.size())
	InstrumentSelect.selected_instrument = "dan_tranh"
	SecureDataManager.data["selected_instrument"] = "dan_tranh"
	
	var side_v := $Root/Sidebar/SideM/SideV as VBoxContainer
	btn_minigame = Button.new()
	btn_minigame.name = "BtnMiniGame"
	btn_minigame.text = "Minigame"
	btn_minigame.flat = true
	btn_minigame.custom_minimum_size = Vector2(220, 100)
	side_v.add_child(btn_minigame)
	side_v.move_child(btn_minigame, 5) # after BtnSongs (index 4)
	
	btn_leaderboard = Button.new()
	btn_leaderboard.name = "BtnLeaderboard"
	btn_leaderboard.text = "Bảng xếp hạng"
	btn_leaderboard.flat = true
	btn_leaderboard.custom_minimum_size = Vector2(220, 100)
	side_v.add_child(btn_leaderboard)
	side_v.move_child(btn_leaderboard, 6)
	
	_build_theme()
	_build_sidebar()
	_build_lessons()
	_build_quiz_btn()
	_build_profile_btn()
	
	lessons_hbox.draw.connect(_draw_lesson_path)
	lessons_hbox.sort_children.connect(func() -> void: lessons_hbox.queue_redraw())
	_connect_navigation()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	lessons_hbox.mouse_filter = Control.MOUSE_FILTER_PASS
	var content_margin := lessons_hbox.get_parent() as Control
	if content_margin: content_margin.mouse_filter = Control.MOUSE_FILTER_PASS
	create_tween().tween_property(self, "modulate:a", 1.0, 0.28)

static func get_level_data(level_number: int) -> Dictionary:
	var index := clampi(level_number, 1, LEVELS.size()) - 1
	return LEVELS[index]

func _build_theme() -> void:
	bg.texture = load("res://assets/textures/dan_tranh_background.png")
	var top_s := _flat(Color(1.0, 0.99, 0.97, 0.7), Color(C_GOLD, 0.28), 0, 0)
	top_s.border_width_bottom = 1
	top_s.content_margin_bottom = 0
	top_bar.add_theme_stylebox_override("panel", top_s)
	
	var top_blur_mat = ShaderMaterial.new()
	var top_blur_shader = Shader.new()
	top_blur_shader.code = """
	shader_type canvas_item;
	uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
	uniform float lod: hint_range(0.0, 5.0) = 2.0;
	void fragment() {
		COLOR = textureLod(screen_texture, SCREEN_UV, lod);
	}
	"""
	top_blur_mat.shader = top_blur_shader
	var top_blur_rect = ColorRect.new()
	top_blur_rect.material = top_blur_mat
	top_blur_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top_blur_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_blur_rect.show_behind_parent = true
	top_bar.add_child(top_blur_rect)
	top_bar.move_child(top_blur_rect, 0)
	page_title.add_theme_color_override("font_color", C_JADE)
	objective_label.add_theme_color_override("font_color", C_MUTED)
	var heading_font := load("res://assets/fonts/Lora-Bold.ttf") as Font
	if heading_font:
		page_title.add_theme_font_override("font", heading_font)
	
	back_btn.text = ""
	back_btn.icon = load("res://assets/textures/lucide/arrow-left.svg") as Texture2D
	back_btn.expand_icon = true
	back_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	back_btn.custom_minimum_size = Vector2(48, 48)
	back_btn.add_theme_color_override("icon_normal_color", C_JADE)
	back_btn.add_theme_color_override("icon_hover_color", C_GOLD)
	back_btn.add_theme_color_override("icon_pressed_color", C_JADE)
	_style_text_btn(back_btn, C_JADE, C_GOLD)
	_make_bouncy(back_btn)
	
	if change_course_btn:
		_style_outline_button(change_course_btn)

func _build_sidebar() -> void:
	var side_s := _flat(Color(0.95, 0.93, 0.89, 0.6), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.15), 0, 0)
	side_s.border_width_left = 0; side_s.border_width_top = 0; side_s.border_width_bottom = 0
	side_s.border_width_right = 2
	side_s.content_margin_right = 0
	side_s.shadow_size = 12
	side_s.shadow_color = Color(0.13, 0.08, 0.05, 0.15)
	side_s.shadow_offset = Vector2(4, 0)
	sidebar.add_theme_stylebox_override("panel", side_s)

	var blur_mat = ShaderMaterial.new()
	var blur_shader = Shader.new()
	blur_shader.code = """
	shader_type canvas_item;
	uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
	uniform float lod: hint_range(0.0, 5.0) = 2.0;
	void fragment() {
		COLOR = textureLod(screen_texture, SCREEN_UV, lod);
	}
	"""
	blur_mat.shader = blur_shader
	var blur_rect = ColorRect.new()
	blur_rect.material = blur_mat
	blur_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blur_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blur_rect.show_behind_parent = true
	sidebar.add_child(blur_rect)
	sidebar.move_child(blur_rect, 0)

	if btn_menu: _style_side_icon_btn(btn_menu,     false)
	if btn_courses: _style_side_icon_btn(btn_courses,  true)
	if btn_room: _style_side_icon_btn(btn_room,     false)
	if btn_songs: _style_side_icon_btn(btn_songs,    false)
	if btn_minigame: _style_side_icon_btn(btn_minigame, false)
	if btn_leaderboard: _style_side_icon_btn(btn_leaderboard, false)
	if btn_account: _style_side_icon_btn(btn_account,  false)

	if btn_menu: _attach_icon_draw(btn_menu,     0)
	if btn_courses: _attach_icon_draw(btn_courses,  1)
	if btn_room: _attach_icon_draw(btn_room,     6)
	if btn_songs: _attach_icon_draw(btn_songs,    2)
	if btn_minigame: _attach_icon_draw(btn_minigame, 3)
	if btn_leaderboard: _attach_icon_draw(btn_leaderboard, 4)
	if btn_account: _attach_icon_draw(btn_account,  5)

	for b in [btn_menu, btn_courses, btn_room, btn_songs, btn_minigame, btn_account, btn_leaderboard]:
		if b:
			_make_bouncy(b)

func _style_side_icon_btn(btn: Button, is_active: bool, is_locked: bool = false) -> void:
	var bg_n := _flat(Color(0, 0, 0, 0) if not is_active else Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.12), Color(0, 0, 0, 0), 18, 0)
	var bg_h := _flat(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.08) if not is_locked else Color(0, 0, 0, 0), Color(0, 0, 0, 0), 18, 0)
	var bg_p := _flat(Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.20) if not is_locked else Color(0, 0, 0, 0), Color(0, 0, 0, 0), 18, 0)

	bg_n.content_margin_top = 64
	bg_n.content_margin_bottom = 8
	bg_h.content_margin_top = 64
	bg_h.content_margin_bottom = 8
	bg_p.content_margin_top = 64
	bg_p.content_margin_bottom = 8

	if is_active:
		bg_n.border_width_left = 6
		bg_n.border_width_right = 0; bg_n.border_width_top = 0; bg_n.border_width_bottom = 0
		bg_n.border_color = C_GOLD

	btn.add_theme_stylebox_override("normal",  bg_n)
	btn.add_theme_stylebox_override("hover",   bg_h)
	btn.add_theme_stylebox_override("pressed", bg_p)
	btn.add_theme_stylebox_override("focus",   _flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0))
	btn.add_theme_color_override("font_color",         C_JADE if is_active else (Color(0.43, 0.38, 0.33, 0.40) if is_locked else Color(0.43, 0.38, 0.33, 1.0)))
	btn.add_theme_color_override("font_hover_color",   Color(0.43, 0.38, 0.33, 0.8) if is_locked else Color(0.13, 0.08, 0.05, 1.0))
	btn.add_theme_color_override("font_pressed_color", C_JADE if not is_locked else Color(0.43, 0.38, 0.33, 0.40))
	btn.add_theme_font_size_override("font_size", 22)

func _attach_icon_draw(btn: Button, icon_type: int, is_locked: bool = false) -> void:
	var ic := Control.new()
	ic.name = "IconDraw"
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic.layout_mode = 1
	ic.anchors_preset = Control.PRESET_CENTER_TOP
	ic.anchor_left = 0.5; ic.anchor_right = 0.5
	ic.anchor_top = 0.0;  ic.anchor_bottom = 0.0
	ic.offset_left = -40; ic.offset_right = 40
	ic.offset_top = 8;   ic.offset_bottom = 64
	ic.draw.connect(func() -> void: _draw_sidebar_icon(ic, icon_type, is_locked))
	btn.add_child(ic)

func _draw_sidebar_icon(c: Control, t: int, is_locked: bool = false) -> void:
	var sz := c.size
	var cx := sz.x * 0.5
	var cy := sz.y * 0.5
	var col : Color = c.get_parent().get_theme_color("font_color", "Button")

	var tex_name := ""
	match t:
		0: tex_name = "menu"
		1: tex_name = "graduation-cap"
		2: tex_name = "music"
		3: tex_name = "gamepad-2"
		4: tex_name = "trending-up"
		5: tex_name = "user"
		6: tex_name = "home"
	
	var texture : Texture2D = null
	if _sidebar_icon_cache.has(t):
		texture = _sidebar_icon_cache[t]
	elif tex_name != "":
		texture = load("res://assets/textures/lucide/" + tex_name + ".svg") as Texture2D
		_sidebar_icon_cache[t] = texture
	
	if texture:
		var icon_sz := Vector2(36, 36)
		if t == 0:
			icon_sz = Vector2(28, 28)
		var rect := Rect2(Vector2(cx - icon_sz.x/2, cy - icon_sz.y/2), icon_sz)
		c.draw_texture_rect(texture, rect, false, col)

func _build_lessons() -> void:
	for child in lessons_hbox.get_children():
		child.queue_free()
	lessons_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	var level_data := get_level_data(selected_level)
	page_title.text = "ĐÀN TRANH · LEVEL %d" % selected_level
	objective_label.text = "%s · %s · %s" % [level_data["title"], level_data["sessions"], level_data["objective"]]
	var completed: Array = SecureDataManager.data.completed_lessons.get("dan_tranh", [])
	var lessons: Array = level_data["lessons"]
	for index in range(lessons.size()):
		var lesson_value = lessons[index]
		var lesson: Dictionary = lesson_value
		lessons_hbox.add_child(_create_lesson_path(lesson, index, lessons, completed))

func _create_lesson_path(lesson: Dictionary, index: int, lessons: Array, completed: Array) -> VBoxContainer:
	var lesson_number := int(lesson["number"])
	var lesson_type := str(lesson.get("type", "practice"))
	var practice_id := _lesson_id(lesson_number, "practice")
	var lesson_ready: bool = not REQUIRE_SEQUENTIAL_UNLOCK or index == 0
	if REQUIRE_SEQUENTIAL_UNLOCK and index > 0:
		var previous: Dictionary = lessons[index - 1]
		lesson_ready = completed.has(_lesson_id(int(previous["number"]), "practice"))
	var practice_completed := completed.has(practice_id)
	var practice_unlocked: bool = not REQUIRE_SEQUENTIAL_UNLOCK or practice_completed or lesson_ready

	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2.ZERO
	column.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	column.alignment = BoxContainer.ALIGNMENT_BEGIN
	column.add_theme_constant_override("separation", 18)

	var title := Label.new()
	title.text = "BÀI %d" % lesson_number
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", C_TEXT if lesson_ready else Color(C_MUTED, 0.45))
	var bold_font := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if bold_font:
		title.add_theme_font_override("font", bold_font)
	column.add_child(title)

	var main_action := "Luyện tập"
	var main_is_video := lesson_type == "video"
	if main_is_video:
		main_action = "Hướng dẫn"
	var lesson_button := _create_circle_button(main_action, str(lesson["title"]), practice_unlocked or main_is_video, practice_completed)
	lesson_button.name = "LessonBtn"
	if main_is_video:
		lesson_button.pressed.connect(_open_lesson.bind(lesson, "video"))
	else:
		lesson_button.pressed.connect(_open_lesson.bind(lesson, "practice"))
	column.add_child(lesson_button)

	if lesson_type == "both":
		var video_btn := _create_small_btn("🎬 Hướng dẫn", practice_unlocked)
		video_btn.name = "VideoBtn"
		video_btn.pressed.connect(_open_lesson.bind(lesson, "video"))
		column.add_child(video_btn)

	return column

func _create_small_btn(label: String, unlocked: bool) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(150, 42)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if unlocked else Control.CURSOR_ARROW
	button.text = label
	var bg := _flat(Color(0, 0, 0, 0), C_JADE, 18, 1)
	var hover := _flat(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.12), C_GOLD, 18, 1)
	button.add_theme_stylebox_override("normal", bg)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", _flat(Color(C_JADE, 0.12), C_JADE, 18, 1))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", C_JADE)
	button.add_theme_color_override("font_hover_color", C_GOLD)
	button.add_theme_font_size_override("font_size", 15)
	_make_bouncy(button)
	return button

func _create_circle_button(action: String, lesson_title: String, unlocked: bool, completed: bool) -> Button:
	var button := Button.new()
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.custom_minimum_size = Vector2(250, 250)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if unlocked else Control.CURSOR_ARROW
	button.disabled = not unlocked

	if completed:
		button.text = "✓\n%s\nHoàn thành" % action
	elif unlocked:
		var icon := "🎬" if action == "Hướng dẫn" else "🎵"
		button.text = "%s\n%s\n(%s)" % [icon, action, lesson_title]
	else:
		button.text = "🔒"

	var bg_color := Color(0.95, 0.93, 0.89, 0.6)
	var border_color := Color(0.85, 0.82, 0.78, 1.0)
	var text_color := Color(C_MUTED, 0.8)
	
	if completed:
		bg_color = C_JADE
		border_color = C_GOLD
		text_color = Color.WHITE
	elif unlocked:
		bg_color = Color.WHITE
		border_color = C_JADE_LIGHT
		text_color = C_TEXT

	var s_normal := StyleBoxFlat.new()
	s_normal.bg_color = bg_color
	s_normal.border_color = border_color
	s_normal.border_width_left = 6; s_normal.border_width_right = 6
	s_normal.border_width_top = 6; s_normal.border_width_bottom = 6
	s_normal.corner_radius_top_left = 125; s_normal.corner_radius_top_right = 125
	s_normal.corner_radius_bottom_left = 125; s_normal.corner_radius_bottom_right = 125
	
	if unlocked and not completed:
		s_normal.shadow_size = 24
		s_normal.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35)
		
	var s_hover := s_normal.duplicate() as StyleBoxFlat
	if unlocked:
		if completed:
			s_hover.bg_color = bg_color.lightened(0.1)
		else:
			s_hover.bg_color = Color(0.97, 0.97, 0.97, 1.0)

	button.add_theme_stylebox_override("normal", s_normal)
	button.add_theme_stylebox_override("hover", s_hover)
	button.add_theme_stylebox_override("pressed", s_normal)
	button.add_theme_stylebox_override("disabled", s_normal)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", C_JADE if (unlocked and not completed) else text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_disabled_color", text_color)
	var bold_font := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if bold_font:
		button.add_theme_font_override("font", bold_font)
	button.add_theme_font_size_override("font_size", 21)
	_make_bouncy(button)
	return button

func _on_btn_leaderboard_pressed() -> void:
	_fade_to("res://scenes/LeaderboardScreen.tscn")

func _draw_lesson_path() -> void:
	if lessons_hbox.size.x <= 0.0:
		return
	var centers: Array[Vector2] = []
	var node_unlocked: Array[bool] = []
	
	for child in lessons_hbox.get_children():
		var col := child as VBoxContainer
		if not col: continue
		var l_btn := col.get_node_or_null("LessonBtn") as Button
		if l_btn:
			var l_center: Vector2 = col.position + l_btn.position + l_btn.size / 2.0
			centers.append(l_center)
			node_unlocked.append(not l_btn.disabled)
			
	if centers.is_empty():
		return
		
	# Ensure all circles lie on the exact same horizontal straight line (Y coordinate)
	var line_y := centers[0].y
	for idx in range(centers.size() - 1):
		var p1 := Vector2(centers[idx].x, line_y)
		var p2 := Vector2(centers[idx + 1].x, line_y)
		var active := node_unlocked[idx + 1]
		var line_color := C_JADE if active else Color(0.13, 0.08, 0.05, 0.08)
		var line_thickness := 14.0 if active else 7.0
		lessons_hbox.draw_line(p1, p2, line_color, line_thickness, true)

func _create_lesson_card(lesson: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(430, 560)
	var card_style := _flat(C_CARD, Color(C_GOLD, 0.36), 26, 2)
	card_style.shadow_size = 18
	card_style.shadow_color = Color(0.13, 0.08, 0.05, 0.12)
	card_style.shadow_offset = Vector2(0, 7)
	card.add_theme_stylebox_override("panel", card_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_bottom", 26)
	card.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	margin.add_child(content)

	var badge := Label.new()
	badge.text = "BÀI %d" % lesson["number"]
	badge.add_theme_color_override("font_color", C_GOLD)
	badge.add_theme_font_size_override("font_size", 17)
	content.add_child(badge)

	var title := Label.new()
	title.text = lesson["title"]
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_color_override("font_color", C_JADE)
	title.add_theme_font_size_override("font_size", 25)
	var heading_font := load("res://assets/fonts/Lora-Bold.ttf") as Font
	if heading_font:
		title.add_theme_font_override("font", heading_font)
	content.add_child(title)

	var divider := HSeparator.new()
	divider.add_theme_constant_override("separation", 2)
	content.add_child(divider)

	if str(lesson["video"]) != "":
		content.add_child(_create_description("VIDEO HƯỚNG DẪN", str(lesson["video"]), "🎬"))
	content.add_child(_create_description("THỰC HÀNH TRÊN ĐÀN ẢO", str(lesson["practice"]), "🎵"))

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	content.add_child(actions)
	var practice_btn := _create_action_button("Bắt đầu bài học", true)
	practice_btn.pressed.connect(_open_lesson.bind(lesson))
	actions.add_child(practice_btn)
	return card

func _create_description(label_text: String, description: String, icon: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _flat(Color(C_JADE, 0.045), Color(C_JADE, 0.10), 16, 1))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 13)
	margin.add_theme_constant_override("margin_bottom", 13)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)
	var heading := Label.new()
	heading.text = "%s  %s" % [icon, label_text]
	heading.add_theme_color_override("font_color", C_GOLD)
	heading.add_theme_font_size_override("font_size", 13)
	box.add_child(heading)
	var body := Label.new()
	body.text = description
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_color_override("font_color", C_TEXT)
	body.add_theme_font_size_override("font_size", 16)
	box.add_child(body)
	return panel

func _create_action_button(text_value: String, primary: bool) -> Button:
	var button := Button.new()
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 54)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 15)
	if primary:
		button.add_theme_stylebox_override("normal", _flat(C_JADE, C_GOLD, 18, 2))
		button.add_theme_stylebox_override("hover", _flat(C_JADE_LIGHT, C_GOLD_LIGHT, 18, 2))
		button.add_theme_color_override("font_color", Color.WHITE)
	else:
		button.add_theme_stylebox_override("normal", _flat(Color.TRANSPARENT, C_JADE, 18, 2))
		button.add_theme_stylebox_override("hover", _flat(Color(C_JADE, 0.08), C_GOLD, 18, 2))
		button.add_theme_color_override("font_color", C_JADE)
	button.add_theme_stylebox_override("pressed", _flat(Color(C_GOLD, 0.18), C_GOLD, 18, 2))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_make_bouncy(button)
	return button

func _connect_navigation() -> void:
	back_btn.pressed.connect(_go_to_levels)
	if change_course_btn:
		change_course_btn.pressed.connect(_go_to_levels)
	btn_menu.pressed.connect(func() -> void: _fade_to("res://scenes/MainMenu.tscn"))
	btn_courses.pressed.connect(_go_to_levels)
	btn_room.pressed.connect(func() -> void: _fade_to("res://scenes/VirtualMusicRoom.tscn"))
	btn_songs.pressed.connect(func() -> void: _fade_to("res://scenes/SongScreen.tscn"))
	btn_minigame.pressed.connect(func() -> void:
		LearningActivityContextScript.configure("dan_tranh", [SecureDataManager.active_lesson_id], "res://scenes/LessonDanTranhList.tscn")
		_fade_to("res://scenes/LearningActivitiesScreen.tscn")
	)
	btn_leaderboard.pressed.connect(_on_btn_leaderboard_pressed)
	if btn_account:
		btn_account.pressed.connect(func() -> void: _fade_to("res://scenes/AccountScreen.tscn"))

func _go_to_levels() -> void:
	_fade_to("res://scenes/MainMenu.tscn")

func _open_lesson(lesson: Dictionary, activity: String = "practice") -> void:
	var lesson_number := int(lesson["number"])
	
	# Load current lesson data so LessonDanTranh can read it
	PracticeRoom.current_song_title = str(lesson["title"])
	var typed_sheet: Array[String] = []
	typed_sheet.assign(lesson.get("sheet", []))
	PracticeRoom.current_song_sheet = typed_sheet
	
	var typed_durations: Array[float] = []
	typed_durations.assign(lesson.get("durations", []))
	LessonDanTranh.current_song_durations = typed_durations
	
	var typed_cues: Array[String] = []
	typed_cues.assign(lesson.get("cues", []))
	LessonDanTranh.current_song_cues = typed_cues
	
	var lesson_type := str(lesson.get("type", "practice"))
	if activity == "video":
		SecureDataManager.active_lesson_id = _lesson_id(lesson_number, "video")
		var VP = load("res://scripts/VideoPlayer.gd")
		var v_path := str(lesson.get("video", ""))
		if not v_path.begins_with("res://"):
			v_path = "res://Video/DT_LV1_B" + str(lesson_number) + ".ogv"
		if not ResourceLoader.exists(v_path):
			v_path = "res://Video/DT_LV1_B1.ogv"
		VP.custom_video_path = v_path
		VP.custom_subtitles = VP.SUBTITLES_DAN_TRANH
		_fade_to("res://scenes/VideoPlayer.tscn")
	else:
		SecureDataManager.active_lesson_id = _lesson_id(lesson_number, "practice")
		_fade_to("res://scenes/LessonDanTranh.tscn")

func _lesson_id(lesson_number: int, activity: String) -> String:
	return "dan_tranh_level_%d_bai_%d_%s" % [selected_level, lesson_number, activity]

func _build_quiz_btn() -> void:
	var toph := $Root/RightContent/TopBar/TopM/TopH as HBoxContainer
	if toph == null or change_course_btn == null:
		return
	var quiz_btn := Button.new()
	quiz_btn.name = "QuizBtn"
	quiz_btn.text = "📝 Quiz"
	quiz_btn.custom_minimum_size = Vector2(148, 48)
	quiz_btn.add_theme_font_size_override("font_size", 17)
	quiz_btn.add_theme_stylebox_override("normal", _flat(Color.TRANSPARENT, C_JADE, 18, 2))
	quiz_btn.add_theme_stylebox_override("hover", _flat(Color(C_GOLD, 0.12), C_GOLD, 18, 2))
	quiz_btn.add_theme_stylebox_override("pressed", _flat(Color(C_GOLD, 0.15), C_GOLD, 18, 2))
	quiz_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	quiz_btn.add_theme_color_override("font_color", C_JADE)
	quiz_btn.add_theme_color_override("font_hover_color", C_GOLD)
	quiz_btn.pressed.connect(_open_quiz)
	_make_bouncy(quiz_btn)
	toph.add_child(quiz_btn)
	toph.move_child(quiz_btn, change_course_btn.get_index())

func _build_profile_btn() -> void:
	var toph := $Root/RightContent/TopBar/TopM/TopH as HBoxContainer
	if toph == null:
		return
	var spacer := Control.new()
	spacer.name = "TopSpacerRight"
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toph.add_child(spacer)
	var pill := DS.build_profile_pill()
	var trigger := pill.get_node_or_null("TriggerButton") as Button
	if trigger:
		trigger.pressed.connect(func() -> void: _fade_to("res://scenes/AccountScreen.tscn"))
	toph.add_child(pill)

func _open_quiz() -> void:
	var ids: Array[String] = []
	var level_data := get_level_data(selected_level)
	for lesson: Dictionary in level_data.get("lessons", []):
		var number := int(lesson.get("number", 0))
		if number > 0:
			ids.append(_lesson_id(number, "practice"))
	LearningActivityContextScript.configure("dan_tranh", ids, "res://scenes/LessonDanTranhList.tscn")
	_fade_to("res://scenes/LearningActivitiesScreen.tscn")

func _apply_responsive_layout() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var mobile: bool = viewport_size.x < 850.0 or viewport_size.x < viewport_size.y
	sidebar.visible = not mobile
	var top_margin := $Root/RightContent/TopBar/TopM as MarginContainer
	top_margin.add_theme_constant_override("margin_left", 16 if mobile else 36)
	top_margin.add_theme_constant_override("margin_right", 16 if mobile else 36)
	top_margin.add_theme_constant_override("margin_top", 16 if mobile else 24)
	top_margin.add_theme_constant_override("margin_bottom", 12 if mobile else 16)
	page_title.add_theme_font_size_override("font_size", 19 if mobile else 25)
	objective_label.visible = not mobile
	if change_course_btn:
		change_course_btn.custom_minimum_size.x = 108 if mobile else 164
		change_course_btn.text = "Levels" if mobile else "Đổi khóa học"
	var content_margin := $Root/RightContent/ScrollContainer/ContentMargin as MarginContainer
	content_margin.add_theme_constant_override("margin_left", 18 if mobile else 48)
	var sep := 32 if mobile else 64
	lessons_hbox.add_theme_constant_override("separation", sep)
	lessons_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	for col in lessons_hbox.get_children():
		if col is VBoxContainer:
			var col_min_h := 288.0 if mobile else 358.0
			col.custom_minimum_size = Vector2(0, col_min_h)
			col.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			col.alignment = BoxContainer.ALIGNMENT_BEGIN
			var btn := col.get_node_or_null("LessonBtn") as Button
			if btn:
				var sz := Vector2(180, 180) if mobile else Vector2(250, 250)
				btn.custom_minimum_size = sz
				btn.add_theme_font_size_override("font_size", 18 if mobile else 21)

func _style_text_btn(btn: Button, normal_color: Color, hover_color: Color) -> void:
	btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_color_override("font_color", normal_color)
	btn.add_theme_color_override("font_hover_color", hover_color)
	btn.add_theme_color_override("font_pressed_color", hover_color.darkened(0.15))

func _style_outline_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _flat(Color.TRANSPARENT, C_JADE, 18, 2))
	button.add_theme_stylebox_override("hover", _flat(Color(C_JADE, 0.08), C_GOLD, 18, 2))
	button.add_theme_stylebox_override("pressed", _flat(Color(C_GOLD, 0.15), C_GOLD, 18, 2))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", C_JADE)
	_make_bouncy(button)

func _flat(background: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.border_width_top = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style

func _make_bouncy(button: Button) -> void:
	button.resized.connect(func() -> void: button.pivot_offset = button.size * 0.5)
	button.mouse_entered.connect(func() -> void: create_tween().tween_property(button, "scale", Vector2(1.025, 1.025), 0.10))
	button.mouse_exited.connect(func() -> void: create_tween().tween_property(button, "scale", Vector2.ONE, 0.10))
	button.button_down.connect(func() -> void: create_tween().tween_property(button, "scale", Vector2(0.97, 0.97), 0.07))
	button.button_up.connect(func() -> void: create_tween().tween_property(button, "scale", Vector2.ONE, 0.10))

func _fade_to(path: String) -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.20)
	tween.tween_callback(func() -> void: get_tree().change_scene_to_file(path))
