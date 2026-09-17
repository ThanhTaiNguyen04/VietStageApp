extends RefCounted

## Bundled DanTranh data, independent from API DTOs and scene scripts.
## Preserve stable IDs used by saved progress/stars. Never overwrite from API.
## Mutable consumers use duplicate(true). Runtime logic and media remain separate.

# Source: LessonDanTranh.gd / GLISSANDO_ROUNDS
const GLISSANDO_ROUNDS := [
	{"mode": "down", "title": "Á xuống", "instruction": "Vuốt liền mạch 6 nốt từ dây 1 đến dây 6"},
	{"mode": "up", "title": "Á lên", "instruction": "Vuốt liền mạch 6 nốt từ dây 17 về dây 12"}
]

# Source: LessonDanTranh.gd / VIBRATO_NOTES
const VIBRATO_NOTES: Array[String] = ["Sol2", "La2", "Đô3", "Rê3", "Mi3", "Sol3", "La3"]

# Source: LessonDanTranh.gd / PRESS_EXERCISES
const PRESS_EXERCISES := [
	# Lượt 1: mượn ba dây Mi ở ba quãng, nhấn 1/2 cung để ra Fa.
	{"source": "Mi2", "target": "Fa2", "interval": 100.0, "round": 0, "finger": "2"},
	{"source": "Mi3", "target": "Fa3", "interval": 100.0, "round": 0, "finger": "2"},
	{"source": "Mi4", "target": "Fa4", "interval": 100.0, "round": 0, "finger": "2"},
	# Lượt 2: mượn ba dây La ở ba quãng, nhấn một cung để ra Si.
	{"source": "La2", "target": "Si2", "interval": 200.0, "round": 1, "finger": "2"},
	{"source": "La3", "target": "Si3", "interval": 200.0, "round": 1, "finger": "2"},
	{"source": "La4", "target": "Si4", "interval": 200.0, "round": 1, "finger": "2"}
]

# Source: LessonDanTranh.gd / TREMOLO_EXERCISES
const TREMOLO_EXERCISES := [
	{
		"mode": "single",
		"title": "Vê một dây",
		"groups": [["Đô2"], ["Sol2"], ["Đô3"]]
	},
	{
		"mode": "octave",
		"title": "Vê hai dây cùng tên nốt",
		"groups": [["Đô2", "Đô3"], ["Sol2", "Sol3"], ["La2", "La3"]]
	}
]

# Source: LessonDanTranh.gd / ALL_17_NOTES
const ALL_17_NOTES: Array[String] = [
	"Sol1", "La1", "Đô2", "Rê2", "Mi2",
	"Sol2", "La2", "Đô3", "Rê3", "Mi3",
	"Sol3", "La3", "Đô4", "Rê4", "Mi4",
	"Sol4", "La4"
]

# Source: LessonDanTranh.gd / LESSON_DIALOGUES
const LESSON_DIALOGUES = {
	"dan_tranh_level_7_bai_18_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ cùng tìm hiểu kỹ thuật Á trên đàn Tranh.", "highlight": -1},
		{"action": "speak", "text": "Kỹ thuật Á là dùng ngón tay phải vuốt nhanh và liên tục qua nhiều dây để tạo thành một chuỗi âm thanh liền mạch.", "highlight": -1},
		{"action": "speak", "text": "Á xuống là vuốt từ vùng dây có âm cao xuống vùng dây có âm thấp. Á lên là vuốt theo chiều ngược lại, từ âm thấp lên âm cao.", "highlight": -1},
		{"action": "speak", "text": "Phần thực hành gồm hai lượt: Á xuống và Á lên. Ứng dụng sẽ nghe đàn thật, kiểm tra hướng vuốt, độ rộng và tính liên tục của chuỗi âm. Bây giờ chúng ta bắt đầu nhé!", "highlight": -1}
	],
	"dan_tranh_level_1_bai_1_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học đầu tiên, chúng ta sẽ cùng tìm hiểu nhạc cụ đàn Tranh.", "highlight": -1},
		{"action": "speak", "text": "Đàn Tranh là nhạc cụ dây truyền thống của Việt Nam. Đàn thường có mười sáu hoặc mười chín dây, thân đàn dạng hộp dài hình thang, dài khoảng một trăm mười đến một trăm hai mươi xen-ti-mét. Đầu lớn rộng hơn là nơi mắc dây và đặt cầu đàn; đầu nhỏ có các trục để lên dây.", "highlight": -1},
		{"action": "speak", "text": "Các bộ phận chính của đàn gồm có mặt đàn, thành và đáy đàn, cầu đàn, nhạn, trục đàn, dây đàn và móng gảy.", "highlight": -1},
		{"action": "speak", "text": "Mặt đàn làm từ gỗ nhẹ, thường là gỗ ngô đồng, có dạng vồng lên. Thành và đáy đàn làm từ các loại gỗ cứng; đáy đàn có lỗ thoát âm và vị trí cầm hoặc treo đàn.", "highlight": -1},
		{"action": "speak", "text": "Cầu đàn nằm ở đầu rộng, giúp cố định dây đàn. Nhạn, còn gọi là ngựa đàn, là các thanh gỗ nhỏ đỡ dây trên mặt đàn và có thể di chuyển để điều chỉnh cao độ của từng dây.", "highlight": -1},
		{"action": "speak", "text": "Trục đàn nằm ở đầu nhỏ, dùng để căng và lên dây. Dây đàn thường làm bằng thép hoặc inox, có độ dày khác nhau để tạo ra âm thanh cao thấp.", "highlight": -1},
		{"action": "speak", "text": "Móng gảy được đeo ở ngón cái, ngón trỏ và ngón giữa của tay phải để gảy đàn; có thể làm từ đồi mồi, sừng hoặc kim loại.", "highlight": -1},
		{"action": "speak", "text": "Đàn Tranh có thể diễn tấu giai điệu, gảy quãng tám, chập âm và vuốt dây để tạo âm thanh mềm mại, đặc trưng. Đàn được dùng để độc tấu, hòa tấu hoặc đệm cho hát; phù hợp với dân ca, nhạc truyền thống và cả các tác phẩm hiện đại.", "highlight": -1},
		{"action": "speak", "text": "Bây giờ, hãy ngồi thẳng lưng và đặt đàn trước mặt. Đầu lớn của đàn nằm phía tay phải. Chúng ta dùng tay phải để gảy và tay trái để nhấn, giữ dây tạo âm vang. Hãy cùng bắt đầu phần thực hành nhé!", "highlight": -1},
		{"action": "speak", "text": "Đầu tiên, hãy làm quen với âm sắc của 5 nốt cơ bản nhất ở quãng trầm của đàn.", "highlight": -1},
		{"action": "speak", "text": "Dây 1: Nốt Sol1. Hãy gảy đúng nốt Sol1 ở dây thứ nhất đàn.", "highlight": 0},
		{"action": "speak", "text": "Dây 2: Nốt La1. Hãy gảy nốt La1 ở dây thứ 2 trên đàn.", "highlight": 1},
		{"action": "speak", "text": "Dây 3: Nốt Đô2. Hãy gảy nốt Đô2 ở dây thứ 3 trên đàn.", "highlight": 2},
		{"action": "speak", "text": "Dây 4: Nốt Rê2. Hãy gảy nốt Rê2 ở dây thứ 4 trên đàn.", "highlight": 3},
		{"action": "speak", "text": "Dây 5: Nốt Mi2. Hãy gảy nốt Mi2 ở dây thứ 5 trên đàn.", "highlight": 4},
		{"action": "speak", "text": "Tuyệt vời! Bạn đã hoàn thành gảy 5 nốt cơ bản đầu tiên của Đàn Tranh!", "highlight": -1}
	],

	"dan_tranh_level_1_bai_2_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ luyện gảy các nốt cơ bản, phần một.", "highlight": -1},
		{"action": "speak", "text": "Chúng ta sẽ luyện tập lần lượt từng nốt: Sol một, La một, Đô hai, Rê hai, Mi hai, Sol hai, La hai, Đô ba, Rê ba và Mi ba.", "highlight": -1},
		{"action": "speak", "text": "Phần này giúp bạn luyện nhận biết và gảy lần lượt các nốt từ Sol một đến Mi ba. Hãy luân phiên ngón số hai rồi ngón số một, bắt đầu bằng ngón hai ở nốt đầu tiên. Ứng dụng sẽ nghe đàn thật qua micro và chỉ chuyển sang dây kế tiếp sau khi nhận diện đúng cao độ. Hãy gảy chậm, rõ tiếng và đúng vị trí từng dây. Bây giờ, chúng ta cùng bắt đầu nhé!", "highlight": -1},
		{"action": "speak", "text": "Đầu tiên là dây 1: Nốt Sol1 ở quãng thấp nhất. Hãy gảy dây 1.", "highlight": 0, "note": "Sol1"},
		{"action": "speak", "text": "Dây 2: Nốt La1. Hãy gảy dây 2.", "highlight": 1, "note": "La1"},
		{"action": "speak", "text": "Dây 3: Nốt Đô2. Hãy gảy dây 3.", "highlight": 2, "note": "Đô2"},
		{"action": "speak", "text": "Dây 4: Nốt Rê2. Hãy gảy dây 4.", "highlight": 3, "note": "Rê2"},
		{"action": "speak", "text": "Dây 5: Nốt Mi2. Hãy gảy dây 5.", "highlight": 4, "note": "Mi2"},
		{"action": "speak", "text": "Dây 6: Nốt Sol2. Hãy gảy dây 6.", "highlight": 5, "note": "Sol2"},
		{"action": "speak", "text": "Dây 7: Nốt La2. Hãy gảy dây 7.", "highlight": 6, "note": "La2"},
		{"action": "speak", "text": "Dây 8: Nốt Đô3. Hãy gảy dây 8.", "highlight": 7, "note": "Đô3"},
		{"action": "speak", "text": "Dây 9: Nốt Rê3. Hãy gảy dây 9.", "highlight": 8, "note": "Rê3"},
		{"action": "speak", "text": "Dây 10: Nốt Mi3. Hãy gảy dây 10.", "highlight": 9, "note": "Mi3"},
		{"action": "speak", "text": "Tuyệt vời! Bạn đã hoàn thành nhận diện và gảy đúng 10 nốt cơ bản quãng thấp và trung!", "highlight": -1}
	],

	"dan_tranh_level_1_bai_3_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ luyện gảy các nốt cơ bản, phần hai.", "highlight": -1},
		{"action": "speak", "text": "Chúng ta sẽ luyện tập lần lượt từng nốt: Sol ba, La ba, Đô bốn, Rê bốn, Mi bốn, Sol bốn và La bốn.", "highlight": -1},
		{"action": "speak", "text": "Ở phần này, hãy luân phiên ngón số ba, ngón số hai rồi ngón số một, bắt đầu bằng ngón ba ở nốt đầu tiên. Dãy số dưới sheet sẽ là ba, hai, một, ba, hai, một, ba.", "highlight": -1},
		{"action": "speak", "text": "Ứng dụng sẽ nghe đàn thật qua micro và chỉ chuyển sang dây kế tiếp sau khi nhận diện đúng cao độ. Hãy đổi ngón theo số dưới sheet, gảy rõ tiếng và chú ý không nhầm vị trí các dây cao. Bây giờ, chúng ta cùng bắt đầu nhé!", "highlight": -1},
		{"action": "speak", "text": "Dây 11: Nốt Sol3. Hãy gảy dây 11.", "highlight": 10, "note": "Sol3"},
		{"action": "speak", "text": "Dây 12: Nốt La3. Hãy gảy dây 12.", "highlight": 11, "note": "La3"},
		{"action": "speak", "text": "Dây 13: Nốt Đô4. Hãy gảy dây 13.", "highlight": 12, "note": "Đô4"},
		{"action": "speak", "text": "Dây 14: Nốt Rê4. Hãy gảy dây 14.", "highlight": 13, "note": "Rê4"},
		{"action": "speak", "text": "Dây 15: Nốt Mi4. Hãy gảy dây 15.", "highlight": 14, "note": "Mi4"},
		{"action": "speak", "text": "Dây 16: Nốt Sol4. Hãy gảy dây 16.", "highlight": 15, "note": "Sol4"},
		{"action": "speak", "text": "Dây 17: Nốt La4. Hãy gảy dây 17.", "highlight": 16, "note": "La4"},
		{"action": "speak", "text": "Tuyệt vời! Bạn đã hoàn thành nhận diện và gảy đúng 7 nốt ở âm vực cao!", "highlight": -1}
	],

	"dan_tranh_level_2_bai_10_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ luyện nửa đoạn đầu bài Lý cây đa.", "highlight": -1},
		{"action": "speak", "text": "Hãy áp dụng các nốt và ngón gảy đã học để luyện nửa đầu bài Lý cây đa. Bạn nên tập chậm từng câu và đếm nhịp đều. Bây giờ, chúng ta cùng bắt đầu phần thực hành nhé!", "highlight": -1}
	],

	"dan_tranh_level_2_bai_11_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ tiếp tục luyện nửa đoạn cuối bài Lý cây đa.", "highlight": -1},
		{"action": "speak", "text": "Hãy chú ý tên nốt, nhịp và ngón gảy của từng câu nhạc. Bây giờ, chúng ta cùng bắt đầu phần thực hành nhé!", "highlight": -1}
	],

	"dan_tranh_level_2_bai_12_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ hoàn thiện bài Lý cây đa.", "highlight": -1},
		{"action": "speak", "text": "Hãy ghép hai phần đã học để chơi hoàn chỉnh bài Lý cây đa. Bắt đầu chậm, gảy rõ tiếng và giữ nhịp đều. Bây giờ, chúng ta cùng bắt đầu phần thực hành nhé!", "highlight": -1}
	],

	"dan_tranh_level_2_bai_13_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ luyện nửa đoạn đầu bài Sứ thanh hoa.", "highlight": -1},
		{"action": "speak", "text": "Ở bài này, chúng ta áp dụng luyện tập các kỹ thuật gảy ngón vào nửa đầu bài Sứ thanh hoa. Hãy tập từng câu nhạc chậm, đúng nốt và đều nhịp. Bây giờ, chúng ta cùng bắt đầu phần thực hành nhé!", "highlight": -1}
	],

	"dan_tranh_level_2_bai_14_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ tiếp tục luyện nửa đoạn cuối bài Sứ thanh hoa.", "highlight": -1},
		{"action": "speak", "text": "Chú ý các chỗ đổi ngón, nhấn hoặc nếu có rung dây để giai điệu liền mạch và có cảm xúc. Bây giờ, chúng ta cùng bắt đầu phần thực hành nhé!", "highlight": -1}
	],

	"dan_tranh_level_2_bai_15_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ hoàn thiện bài Sứ thanh hoa.", "highlight": -1},
		{"action": "speak", "text": "Giờ ghép hai phần đã học để chơi hoàn chỉnh bài Sứ thanh hoa. Hãy giữ nhịp ổn định, gảy rõ nốt và thể hiện kỹ thuật đúng vị trí. Bây giờ, chúng ta cùng bắt đầu phần thực hành nhé!", "highlight": -1}
	],

	"dan_tranh_level_1_bai_7_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ luyện kỹ thuật gảy ngón số một trên năm dây giữa của đàn Tranh.", "highlight": -1},
		{"action": "speak", "text": "Ngón số một là ngón cái của tay phải. Ngón bốn tỳ nhẹ lên cầu đàn, các ngón còn lại khum tự nhiên; hãy giữ bàn tay và cổ tay thả lỏng khi gảy.", "highlight": -1},
		{"action": "speak", "text": "Phần thực hành gồm năm nốt: Sol hai ở dây sáu, La hai ở dây bảy, Đô ba ở dây tám, Rê ba ở dây chín và Mi ba ở dây mười. Ứng dụng sẽ nghe đàn thật và chỉ ghi nhận khi bạn gảy đúng cao độ. Bây giờ chúng ta bắt đầu nhé!", "highlight": -1}
	],

	"dan_tranh_level_1_bai_8_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ luyện kỹ thuật gảy ngón số hai trên năm dây đầu của đàn Tranh.", "highlight": -1},
		{"action": "speak", "text": "Ngón số hai là ngón trỏ của tay phải. Hãy giữ cổ tay thả lỏng, bàn tay khum tự nhiên và dùng ngón trỏ để gảy từng dây rõ tiếng.", "highlight": -1},
		{"action": "speak", "text": "Phần thực hành gồm năm nốt: Sol một ở dây một, La một ở dây hai, Đô hai ở dây ba, Rê hai ở dây bốn và Mi hai ở dây năm. Ứng dụng sẽ nghe đàn thật và chỉ ghi nhận khi bạn gảy đúng cao độ. Bây giờ chúng ta bắt đầu nhé!", "highlight": -1}
	],

	"dan_tranh_level_1_bai_9_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ luyện kỹ thuật gảy ngón số ba trên bảy dây cao của đàn Tranh.", "highlight": -1},
		{"action": "speak", "text": "Ngón số ba là ngón giữa của tay phải. Hãy giữ bàn tay khum tự nhiên, cổ tay thả lỏng và dùng ngón giữa để gảy từng dây rõ tiếng.", "highlight": -1},
		{"action": "speak", "text": "Phần thực hành gồm bảy nốt: Sol ba ở dây mười một, La ba ở dây mười hai, Đô bốn ở dây mười ba, Rê bốn ở dây mười bốn, Mi bốn ở dây mười lăm, Sol bốn ở dây mười sáu và La bốn ở dây mười bảy. Ứng dụng sẽ nghe đàn thật và chỉ ghi nhận khi bạn gảy đúng cao độ. Bây giờ chúng ta bắt đầu nhé!", "highlight": -1}
	],

	"dan_tranh_level_1_bai_4_practice": [
		{"action": "speak", "text": "Chào bạn! Trước khi đọc bản nhạc, chúng ta hãy nhận biết ba âm vực của 17 dây đàn Tranh. Âm vực là vùng âm thanh trầm, trung hoặc cao; khác với quãng là khoảng cách giữa hai nốt.", "highlight": -1},
		{"action": "speak", "text": "Âm vực trầm gồm các dây 1 đến 5: Sol1, La1, Đô2, Rê2 và Mi2. Đây là nhóm dây có âm thanh thấp nhất trên đàn.", "highlight": -1},
		{"action": "speak", "text": "Âm vực trung gồm các dây 6 đến 10: Sol2, La2, Đô3, Rê3 và Mi3. Âm vực cao gồm các dây 11 đến 17: Sol3, La3, Đô4, Rê4, Mi4, Sol4 và La4.", "highlight": -1},
		{"action": "speak", "text": "Các tên nốt có thể lặp lại ở những độ cao khác nhau, chẳng hạn Sol1, Sol2, Sol3 và Sol4. Con số sau tên nốt giúp chúng ta phân biệt đúng dây và đúng âm vực.", "highlight": -1},
		{"action": "speak", "text": "Khi đọc một bản nhạc, chúng ta còn cần chú ý đến tempo, khóa nhạc và nhịp.", "highlight": -1},
		{"action": "speak", "text": "Tempo là tốc độ nhanh hoặc chậm của bản nhạc. Tempo có thể được ghi bằng số B P M; ví dụ, sáu mươi B P M chậm hơn một trăm hai mươi B P M. Khi tập đàn, bạn nên bắt đầu chậm, giữ đều nhịp rồi mới tăng tốc.", "highlight": -1, "show_speed": true},
		{"action": "speak", "text": "Khóa Sol là ký hiệu thường đặt ở đầu khuông nhạc, giúp chúng ta xác định tên và độ cao của các nốt. Dấu khóa này bắt đầu từ dòng thứ hai của khuông nhạc, cho biết đó là vị trí của nốt Sol.", "highlight": -1, "show_staff": true, "clef": true},
		{"action": "speak", "text": "Nhịp bốn phần tư nghĩa là mỗi ô nhịp có bốn phách và nốt đen được tính là một phách. Ta đếm đều: một, hai, ba, bốn. Phách một thường mạnh hơn các phách còn lại.", "highlight": -1, "show_staff": true, "time_sig": 4},
		{"action": "speak", "text": "Nhịp hai phần tư nghĩa là mỗi ô nhịp có hai phách và nốt đen cũng được tính là một phách. Ta đếm: một, hai; trong đó phách một mạnh và phách hai nhẹ hơn.", "highlight": -1, "show_staff": true, "time_sig": 2},
		{"action": "speak", "text": "Hiểu tempo và nhịp sẽ giúp chúng ta gảy đàn đúng tốc độ, đúng điểm rơi của phách. Khóa Sol giúp chúng ta đọc đúng nốt trên bản nhạc. Bây giờ, chúng ta cùng bắt đầu phần thực hành nhé!", "highlight": -1, "show_staff": true, "time_sig": 4},
		{"action": "speak", "text": "Bây giờ chúng ta cùng luyện tập theo nhịp 4/4. Ta sẽ gảy nốt Sol2, đếm 1-2-3-4 cho mỗi ô nhịp. Hãy gảy nốt Sol2.", "highlight": 0, "note": "Sol2", "time_sig": 4},
		{"action": "speak", "text": "Gảy nốt La2 giữ đều nhịp 4/4.", "highlight": 1, "note": "La2", "time_sig": 4},
		{"action": "speak", "text": "Gảy nốt Đô3 giữ đều nhịp 4/4.", "highlight": 2, "note": "Đô3", "time_sig": 4},
		{"action": "speak", "text": "Gảy nốt Rê3 giữ đều nhịp 4/4.", "highlight": 3, "note": "Rê3", "time_sig": 4},
		{"action": "speak", "text": "Tiếp tục với nhịp 4/4: nốt Mi3.", "highlight": 4, "note": "Mi3", "time_sig": 4},
		{"action": "speak", "text": "Rồi nốt Rê3, giữ nhịp đều.", "highlight": 5, "note": "Rê3", "time_sig": 4},
		{"action": "speak", "text": "Nốt Đô3, giữ nhịp đều.", "highlight": 6, "note": "Đô3", "time_sig": 4},
		{"action": "speak", "text": "Nốt La2, giữ nhịp đều.", "highlight": 7, "note": "La2", "time_sig": 4},
		{"action": "speak", "text": "Giờ chuyển sang nhịp 2/4, nhanh gọn hơn: gảy nốt Sol2.", "highlight": 8, "note": "Sol2", "time_sig": 2},
		{"action": "speak", "text": "Nốt La2 theo nhịp 2/4.", "highlight": 9, "note": "La2", "time_sig": 2},
		{"action": "speak", "text": "Nốt Đô3 theo nhịp 2/4.", "highlight": 10, "note": "Đô3", "time_sig": 2},
		{"action": "speak", "text": "Nốt Rê3 theo nhịp 2/4.", "highlight": 11, "note": "Rê3", "time_sig": 2},
		{"action": "speak", "text": "Nốt Mi3 theo nhịp 2/4.", "highlight": 12, "note": "Mi3", "time_sig": 2},
		{"action": "speak", "text": "Nốt Sol3 theo nhịp 2/4.", "highlight": 13, "note": "Sol3", "time_sig": 2},
		{"action": "speak", "text": "Nốt Rê3 theo nhịp 2/4.", "highlight": 14, "note": "Rê3", "time_sig": 2},
		{"action": "speak", "text": "Và cuối cùng nốt Đô3, giữ nhịp 2/4 thật đều.", "highlight": 15, "note": "Đô3", "time_sig": 2},
		{"action": "speak", "text": "Tuyệt vời! Tóm lại: 17 dây đàn được chia thành âm vực trầm, trung và cao; tempo là tốc độ bài nhạc; khóa Sol xác định vị trí nốt trên khuông; nhịp 4/4 có 4 phách mỗi ô và nhịp 2/4 có 2 phách mỗi ô. Bạn đã hoàn thành bài học!", "highlight": -1}
	],

	"dan_tranh_level_1_bai_5_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ cùng tìm hiểu nhịp điệu cơ bản và trường độ của nốt nhạc.", "highlight": -1},
		{"action": "speak", "text": "Trường độ là độ dài ngắn của âm thanh. Khi gảy một nốt trên đàn Tranh, chúng ta cần biết âm đó kéo dài bao lâu trước khi chuyển sang nốt tiếp theo.", "highlight": -1},
		{"action": "speak", "text": "Trong nhịp bốn phần tư, nốt trắng dài hai phách; nốt đen dài một phách; nốt móc đơn dài nửa phách và hai nốt móc đơn bằng một nốt đen.", "highlight": -1},
		{"action": "speak", "text": "Nốt móc kép dài một phần tư phách và bốn nốt móc kép bằng một nốt đen. Bạn có thể hiểu đơn giản: nốt càng nhiều móc thì âm càng ngắn và cần gảy nhanh hơn.", "highlight": -1},
		{"action": "speak", "text": "Khi chơi đàn Tranh, hãy đếm đều nhịp trong đầu. Với nốt dài, chúng ta chỉ gảy một lần rồi để tiếng đàn ngân đủ số phách, không gảy lặp lại nhiều lần. Hiểu đúng trường độ sẽ giúp bản nhạc đều nhịp, rõ ràng và dễ nghe hơn. Bây giờ, chúng ta cùng bắt đầu phần thực hành nhé!", "highlight": -1},
		{"action": "speak", "text": "Đầu tiên là Nốt Trắng. Nốt trắng có đầu hình bầu dục rỗng, có thân nốt, kéo dài 2 phách. Hãy gảy nốt Đô2 và giữ âm vang 2 phách.", "highlight": 0, "note": "Đô2", "type": "half"},
		{"action": "speak", "text": "Thêm một nốt trắng nữa. Hãy gảy nốt Đô2 và giữ 2 phách nhé.", "highlight": 1, "note": "Đô2", "type": "half"},
		{"action": "speak", "text": "Tiếp theo là Nốt Đen. Nốt đen có đầu hình bầu dục đặc, có thân nốt, kéo dài 1 phách. Hãy gảy nốt Rê2.", "highlight": 2, "note": "Rê2", "type": "quarter"},
		{"action": "speak", "text": "Gảy thêm nốt đen Mi2 – 1 phách.", "highlight": 3, "note": "Mi2", "type": "quarter"},
		{"action": "speak", "text": "Và thêm nốt đen Mi2 – 1 phách.", "highlight": 4, "note": "Mi2", "type": "quarter"},
		{"action": "speak", "text": "Gảy nốt đen Sol2 – 1 phách.", "highlight": 5, "note": "Sol2", "type": "quarter"},
		{"action": "speak", "text": "Bây giờ là Nốt Móc Đơn. Nốt móc đơn có đầu đặc, thân nốt và 1 móc, kéo dài nửa phách. Hãy gảy nhanh nốt Sol2.", "highlight": 6, "note": "Sol2", "type": "eighth"},
		{"action": "speak", "text": "Thêm nốt móc đơn Sol2 – nửa phách.", "highlight": 7, "note": "Sol2", "type": "eighth"},
		{"action": "speak", "text": "Và nốt móc đơn Sol2 – nửa phách.", "highlight": 8, "note": "Sol2", "type": "eighth"},
		{"action": "speak", "text": "Cuối cùng là Nốt Móc Kép. Nốt móc kép có đầu đặc, thân nốt và 2 móc, kéo dài một phần tư phách. Rất nhanh! Hãy gảy nốt La2.", "highlight": 9, "note": "La2", "type": "sixteenth"},
		{"action": "speak", "text": "Gảy thêm nốt móc kép La2.", "highlight": 10, "note": "La2", "type": "sixteenth"},
		{"action": "speak", "text": "Tuyệt vời! Bạn đã hoàn thành bài học nhận diện trường độ. Tóm lại: Nốt trắng bằng 2 phách, nốt đen bằng 1 phách, nốt móc đơn bằng nửa phách, nốt móc kép bằng một phần tư phách.", "highlight": -1}
	],

	"dan_tranh_level_2_bai_4_practice": [
		{"action": "speak", "text": "Chào mừng bạn học về trường độ nốt Đen (1 phách) và nốt Trắng (2 phách).", "highlight": -1},
		{"action": "speak", "text": "Nốt trắng sẽ kéo dài gấp đôi nốt đen. Hãy chú ý giữ âm vang của dây khi gảy nốt trắng nhé.", "highlight": -1}
	],

	"dan_tranh_level_2_bai_5_practice": [
		{"action": "speak", "text": "Chào mừng bạn đến với Bài 5: Hệ thống nốt cơ bản và xác định vị trí nốt trên Đàn Tranh.", "highlight": -1},
		{"action": "speak", "text": "Đàn Tranh của chúng ta có 17 dây, được lên theo thang ngũ cung: Sol - La - Đô - Rê - Mi ở các quãng khác nhau.", "highlight": -1},
		{"action": "speak", "text": "Trong âm nhạc chuẩn quốc tế có 7 nốt cơ bản: Đô, Rê, Mi, Fa, Sol, La, Si ký hiệu lần lượt là C, D, E, F, G, A, B.", "highlight": -1},
		{"action": "speak", "text": "Để chơi các nốt Fa và Si trên đàn Tranh, ta sẽ gảy các dây Mi và La tương ứng rồi dùng tay trái nhấn nhẹ dây bên trái nhạn đàn để nâng cao độ.", "highlight": -1},
		{"action": "speak", "text": "Bây giờ, chúng ta sẽ tập luyện xác định vị trí nốt. Tôi sẽ gảy trước một nốt, sau đó bạn hãy gảy lặp lại nốt đó nhé. Đầu tiên là nốt Đô 2 ở dây số 3.", "highlight": 2, "note": "Đô2"},
		{"action": "speak", "text": "Tiếp theo là nốt Rê 2 ở dây số 4.", "highlight": 3, "note": "Rê2"},
		{"action": "speak", "text": "Nốt Mi 2 ở dây số 5.", "highlight": 4, "note": "Mi2"},
		{"action": "speak", "text": "Nốt Fa 2. Hãy gảy dây Mi 2 (dây 5) và nhấn nhẹ tay trái để tạo ra cao độ nốt Fa 2 nhé.", "highlight": 4, "note": "Fa2"},
		{"action": "speak", "text": "Nốt Sol 2 ở dây số 6.", "highlight": 5, "note": "Sol2"},
		{"action": "speak", "text": "Nốt La 2 ở dây số 7.", "highlight": 6, "note": "La2"},
		{"action": "speak", "text": "Nốt Si 2. Hãy gảy dây La 2 (dây 7) và dùng tay trái nhấn để tạo ra cao độ nốt Si 2.", "highlight": 6, "note": "Si2"},
		{"action": "speak", "text": "Và nốt Đô 3 ở dây số 8.", "highlight": 7, "note": "Đô3"},
		{"action": "speak", "text": "Sau đây là thử thách Mini Game: Hãy tìm nốt Sol 2 trên đàn và chọn gảy dây tương ứng nhé!", "highlight": 5, "note": "Sol2"},
		{"action": "speak", "text": "Rất tốt! Tiếp theo là Bài 2.3: Học viên nhận biết các nốt cùng tên ở các quãng khác nhau (khác cao độ).", "highlight": -1},
		{"action": "speak", "text": "Ví dụ: Đô thấp ở dây số 3. Hãy gảy nốt Đô 2.", "highlight": 2, "note": "Đô2"},
		{"action": "speak", "text": "Đô trung ở dây số 8. Hãy gảy nốt Đô 3.", "highlight": 7, "note": "Đô3"},
		{"action": "speak", "text": "Và Đô cao ở dây số 13. Hãy gảy nốt Đô 4.", "highlight": 12, "note": "Đô4"},
		{"action": "speak", "text": "Tuyệt vời! Nhận biết nốt cùng tên ở các quãng khác nhau là kiến thức nền để học các kỹ thuật: Song thanh, Vê, Quãng, Chuyển âm vực sau này. Bây giờ hãy luyện tập chơi chuỗi nốt nhé!", "highlight": -1}
	],

	"dan_tranh_level_2_bai_6_practice": [
		{"action": "speak", "text": "Hãy làm quen với nhịp 4/4 tiêu chuẩn và khuông nhạc khóa Sol.", "highlight": -1},
		{"action": "speak", "text": "Mỗi ô nhịp có 4 phách. Hãy tập trung nghe nhịp gõ và gảy thật đều đặn.", "highlight": -1}
	],

	"dan_tranh_level_3_bai_7_practice": [
		{"action": "speak", "text": "Chào mừng đến với thử thách luyện ngón tốc độ cao với bài nhạc Mã Vũ.", "highlight": -1},
		{"action": "speak", "text": "Bạn cần gảy nhanh, dứt khoát và di chuyển ngón tay linh hoạt qua các quãng xa.", "highlight": -1}
	],

	"dan_tranh_level_4_bai_9_practice": [
		{"action": "speak", "text": "Hôm nay chúng ta sẽ học kỹ thuật nhấn Rung tay trái đặc trưng của Đàn Tranh.", "highlight": -1},
		{"action": "speak", "text": "Sau khi tay phải gảy nốt, hãy dùng các ngón tay trái nhấn nhẹ liên tục lên phần dây bên trái nhạn đàn.", "highlight": -1}
	],

	"dan_tranh_level_7_bai_19_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ cùng tìm hiểu kỹ thuật nhấn trên đàn Tranh.", "highlight": -1},
		{"action": "speak", "text": "Kỹ thuật nhấn là dùng tay trái ấn dây ở phía bên trái của nhạn để nâng cao độ của âm thanh sau khi tay phải gảy dây.", "highlight": -1},
		{"action": "speak", "text": "Nhờ kỹ thuật này, đàn Tranh có thể tạo ra những nốt không có sẵn trên dây. Ví dụ, nhấn dây La để lên nốt Si, hoặc nhấn dây Mi để lên nốt Fa.", "highlight": -1},
		{"action": "speak", "text": "Khi thực hiện, tay phải gảy dây trước, sau đó tay trái nhấn nhẹ và đều đến đúng cao độ. Không nhấn quá mạnh vì tiếng đàn có thể bị gắt hoặc cao độ bị lệch. Bây giờ, chúng ta cùng bắt đầu phần thực hành nhé!", "highlight": -1}
	],

	"dan_tranh_level_7_bai_20_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ cùng tìm hiểu kỹ thuật song thanh trên đàn Tranh.", "highlight": -1},
		{"action": "speak", "text": "Song thanh là kỹ thuật gảy để hai nốt cùng phát ra một lúc. Song thanh truyền thống thường sử dụng quãng tám; các nhạc sĩ hiện đại còn kết hợp thêm những quãng khác.", "highlight": -1},
		{"action": "speak", "text": "Trong bài này, chúng ta dùng ngón 1 và ngón 2 của tay phải để gảy đồng thời hai dây.", "highlight": -1},
		{"action": "speak", "text": "Khi thực hiện, hai tiếng phải phát ra đồng thời, không bị chênh nhau và có âm lượng cân bằng. Bây giờ, chúng ta cùng bắt đầu phần thực hành nhé!", "highlight": -1}
	],

	"dan_tranh_level_7_bai_21_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ cùng tìm hiểu kỹ thuật rung dây trên đàn Tranh.", "highlight": -1},
		{"action": "speak", "text": "Kỹ thuật rung dây tạo tiếng đàn ngân liên tục, mềm mại và giàu cảm xúc. Có hai kiểu rung chính: rung nhanh với biên độ hẹp và rung chậm với biên độ rộng. Trong bài này, chúng ta luyện kiểu rung để thể hiện nét vui của giai điệu.", "highlight": -1},
		{"action": "speak", "text": "Sau khi tay phải gảy dây, tay trái rung ngay để tiếng đàn không bị ngắt quãng. Dùng ngón trỏ và ngón giữa tay trái đặt nhẹ lên dây ở phía bên trái nhạn, cách nhạn khoảng mười xen-ti-mét. Không tỳ mạnh xuống dây vì có thể làm sai cao độ.", "highlight": -1},
		{"action": "speak", "text": "Giữ cổ tay và các ngón tay mềm mại. Dùng hai ngón tay nhồi dây nhẹ nhàng lên xuống, đều tay, để tiếng rung tự nhiên và kéo dài. Bây giờ, chúng ta cùng bắt đầu phần thực hành nhé!", "highlight": -1}
	],

	"dan_tranh_level_8_bai_30_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ cùng tìm hiểu kỹ thuật vê trên đàn Tranh.", "highlight": -1},
		{"action": "speak", "text": "Kỹ thuật vê là gảy luân phiên thật nhanh và liên tục bằng hai ngón tay phải để tạo tiếng đàn ngân dài, dày và liền mạch.", "highlight": -1},
		{"action": "speak", "text": "Có hai cách vê cơ bản. Vê một dây là hai ngón thay phiên gảy trên cùng một dây.", "highlight": -1},
		{"action": "speak", "text": "Vê quãng tám là hai ngón thay phiên gảy trên hai dây cùng tên nốt nhưng khác quãng, ví dụ nốt Đô thấp và nốt Đô cao.", "highlight": -1},
		{"action": "speak", "text": "Kỹ thuật vê thường dùng để giữ âm, làm nổi bật giai điệu và tăng cảm xúc cho câu nhạc. Bây giờ, chúng ta cùng bắt đầu phần thực hành nhé!", "highlight": -1}
	],

	"dan_tranh_level_8_bai_31_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ cùng tìm hiểu hợp âm ba âm cơ bản trên đàn Tranh.", "highlight": -1},
		{"action": "speak", "text": "Hợp âm ba âm là ba nốt khác nhau được gảy cùng lúc, tạo âm thanh đầy đặn hơn một nốt đơn.", "highlight": -1},
		{"action": "speak", "text": "Trong bài này, chúng ta làm quen với hai hợp âm cơ bản để hiểu thêm về cách hòa âm trên đàn Tranh.", "highlight": -1},
		{"action": "speak", "text": "Phần hợp âm ba âm này được học để bạn biết thêm về khả năng tạo âm thanh hợp âm của đàn Tranh; nội dung này không áp dụng vào kiến thức nhạc cụ dân tộc Việt Nam. Bây giờ, chúng ta cùng bắt đầu phần thực hành nhé!", "highlight": -1}
	],

	"dan_tranh_level_8_bai_32_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ cùng tìm hiểu hợp âm Đô trưởng.", "highlight": -1},
		{"action": "speak", "text": "Hợp âm Đô trưởng gồm ba nốt: Đô, Mi và Sol.", "highlight": -1},
		{"action": "speak", "text": "Khi gảy, hãy cố gắng để cả ba nốt vang lên cùng lúc và có âm lượng cân bằng. Bây giờ, chúng ta cùng bắt đầu phần thực hành nhé!", "highlight": -1}
	],

	"dan_tranh_level_8_bai_33_practice": [
		{"action": "speak", "text": "Chào bạn! Trong bài học này, chúng ta sẽ cùng tìm hiểu hợp âm La thứ.", "highlight": -1},
		{"action": "speak", "text": "Hợp âm La thứ gồm ba nốt: La, Đô và Mi.", "highlight": -1},
		{"action": "speak", "text": "Hợp âm này có màu sắc nhẹ nhàng và trầm hơn hợp âm Đô trưởng. Bây giờ, chúng ta cùng bắt đầu phần thực hành nhé!", "highlight": -1}
	],

	"dan_tranh_level_5_bai_12_practice": [
		{"action": "speak", "text": "Thử thách độc tấu trọn vẹn tác phẩm Sứ Thanh Hoa!", "highlight": -1},
		{"action": "speak", "text": "Hãy kết hợp toàn bộ kỹ thuật tay phải gảy ngón và nhấn rung tay trái để hoàn thành bài nhạc xuất sắc nhất.", "highlight": -1}
	]
}

# Source: LessonDanTranh.gd / SU_THANH_HOA_SHEET
const SU_THANH_HOA_SHEET: Array[String] = [
	"Rê3", "Đô3", "La2", "Đô3", "Đô3", "La2", "Đô3", "Đô3", "La2", "Đô3", "La2", "Sol2",
	"Rê3", "Đô3", "La2", "Đô3", "Đô3", "La2", "Đô3", "Đô3", "Mi3", "Rê3", "Đô3", "Sol2", "La2", "Mi3",
	"Mi3", "Rê3", "Mi3", "Rê3", "Mi3", "Sol3", "Mi3", "Rest", "Mi3", "Mi3", "Rê3",
	"Đô3", "Mi3", "Rê3", "Rê3", "Đô3", "La2", "Đô3", "Đô3", "La2", "Đô3",
	"La2", "Sol2", "Sol2", "La2", "Mi3", "Sol3", "Sol3", "Mi3", "Sol3", "Sol3", "Mi3", "Rê3", "Đô3", "Đô3",
	"Rê3", "Đô3", "Rê3", "Mi3", "Rê3", "Rê3", "Đô3", "Rê3", "Đô3", "Rê3", "Đô3", "Đô3", "La2", "Đô3", "Rê3", "Rê3", "Rê3"
]

# Source: LessonDanTranh.gd / SU_THANH_HOA_DURATIONS
const SU_THANH_HOA_DURATIONS: Array[float] = [
	0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5, 2.0,
	0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5,
	0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 1.0, 0.5, 0.5, 2.0,
	0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 3.0,
	1.0, 1.0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5,
	0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 2.0
]

# Source: LessonDanTranh.gd / NOTE_TO_STRING
const NOTE_TO_STRING = {
	"Sol1": 0, "La1": 1, "Đô2": 2, "Rê2": 3, "Mi2": 4, "Fa2": 4,
	"Sol2": 5, "La2": 6, "Si2": 6, "Đô3": 7, "Rê3": 8, "Mi3": 9, "Fa3": 9,
	"Sol3": 10, "La3": 11, "Si3": 11, "Đô4": 12, "Rê4": 13, "Mi4": 14, "Fa4": 14,
	"Sol4": 15, "La4": 16, "Si4": 16
}

# Source: LessonDanTranh.gd / NOTE_FREQS
const NOTE_FREQS = {
	"Sol1": 196.00, "La1": 220.00, "Đô2": 261.63, "Rê2": 293.66, "Mi2": 329.63,
	"Fa2": 349.23, "Sol2": 392.00, "La2": 440.00, "Si2": 493.88, "Đô3": 523.25,
	"Rê3": 587.33, "Mi3": 659.25, "Fa3": 698.46, "Sol3": 783.99, "La3": 880.00,
	"Si3": 987.77, "Đô4": 1046.50, "Rê4": 1174.66, "Mi4": 1318.51, "Fa4": 1396.91,
	"Sol4": 1567.98, "La4": 1760.00, "Si4": 1975.53
}

# Source: LessonDanTranhList.gd / LEVELS
const LEVELS := [
	{
		"level": 1,
		"title": "LÝ THUYẾT VÀ NHẠC LÝ CƠ BẢN",
		"sessions": "Bài 1–9 (gồm 4.1–4.3)",
		"objective": "Làm quen đàn tranh, nhạc lý cơ bản, luyện các nốt và hoàn thiện bài Lý Cây Đa.",
		"lessons": [
			{"number": 1, "display_number": "1", "video_id": "dan_tranh_level_1_bai_1_video", "practice_id": "dan_tranh_level_1_bai_1_practice", "quiz_lesson_id": "dan_tranh_level_1_bai_1_video", "title": "Tìm hiểu nhạc cụ Đàn tranh", "type": "video", "video": "Xem video hướng dẫn lý thuyết nhạc lý, cấu tạo đàn tranh và tư thế ngồi, tư thế tay chuẩn.", "video_path": "res://Video/DT_LV1_B1.ogv"},
			{"number": 5, "display_number": "2", "practice_id": "dan_tranh_level_1_bai_5_practice", "quiz_lesson_id": "dan_tranh_level_1_bai_2_video", "title": "Nhịp điệu cơ bản", "type": "theory", "practice": "Cô Mai giới thiệu trường độ: nốt trắng, nốt đen, nốt móc đơn và nốt móc kép."},
			{"number": 4, "display_number": "3", "practice_id": "dan_tranh_level_1_bai_4_practice", "quiz_lesson_id": "dan_tranh_level_1_bai_3_video", "title": "Đọc bản nhạc cơ bản", "type": "theory", "practice": "Cô Mai giới thiệu âm vực 17 dây, tempo, khóa Sol, nhịp 4/4 và 2/4."},
			{"number": 8, "display_number": "4.1", "title": "Kỹ thuật gảy ngón 2", "type": "both", "video": "Hướng dẫn sử dụng ngón trỏ tay phải (ngón 2), giữ bàn tay khum tự nhiên và thả lỏng khi gảy đàn.", "practice": "Dùng ngón 2 gảy lần lượt 5 nốt trên 5 dây đầu: Sol1, La1, Đô2, Rê2 và Mi2. Ứng dụng nhận diện cao độ của từng dây bằng micro.", "practice_title": "Gảy ngón 2 – 5 nốt cơ bản", "sheet": ["Sol1", "La1", "Đô2", "Rê2", "Mi2"], "durations": [1.0, 1.0, 1.0, 1.0, 2.0], "fingerings": ["2", "2", "2", "2", "2"]},
			{"number": 7, "display_number": "4.2", "title": "Kỹ thuật gảy ngón 1", "type": "both", "video": "Hướng dẫn sử dụng ngón cái tay phải (ngón 1), giữ cổ tay thả lỏng và gảy dây rõ tiếng.", "practice": "Dùng ngón 1 gảy lần lượt 5 nốt trên các dây 6 đến 10: Sol2, La2, Đô3, Rê3 và Mi3. Ứng dụng nhận diện cao độ của từng dây bằng micro.", "practice_title": "Gảy ngón 1 – 5 nốt cơ bản", "sheet": ["Sol2", "La2", "Đô3", "Rê3", "Mi3"], "durations": [1.0, 1.0, 1.0, 1.0, 2.0], "fingerings": ["1", "1", "1", "1", "1"]},
			{"number": 9, "display_number": "4.3", "title": "Kỹ thuật gảy ngón 3", "type": "practice", "video": "Hướng dẫn sử dụng ngón giữa tay phải (ngón 3), giữ bàn tay khum tự nhiên và gảy rõ tiếng ở âm vực cao.", "practice": "Dùng ngón 3 gảy lần lượt 7 nốt trên các dây 11 đến 17: Sol3, La3, Đô4, Rê4, Mi4, Sol4 và La4. Ứng dụng nhận diện cao độ của từng dây bằng micro.", "practice_title": "Gảy ngón 3 – 7 nốt âm vực cao", "sheet": ["Sol3", "La3", "Đô4", "Rê4", "Mi4", "Sol4", "La4"], "durations": [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0], "fingerings": ["3", "3", "3", "3", "3", "3", "3"]},
			{"number": 2, "display_number": "5", "title": "Luyện gảy các nốt cơ bản – Phần 1", "type": "practice", "video": "Cách nhận diện cao độ 10 nốt nhạc cơ bản ở âm vực trầm và trung trên Đàn Tranh.", "practice": "Gảy lần lượt dây 1 đến dây 10: Sol1, La1, Đô2, Rê2, Mi2, Sol2, La2, Đô3, Rê3 và Mi3. Luân phiên ngón 2 rồi ngón 1 từ nốt đầu tiên. Ứng dụng dùng micro nhận diện đúng cao độ từng dây trước khi chuyển sang nốt tiếp theo.", "practice_title": "Nhận diện 10 dây – Luân phiên ngón 2 và 1", "sheet": ["Sol1", "La1", "Đô2", "Rê2", "Mi2", "Sol2", "La2", "Đô3", "Rê3", "Mi3"], "durations": [1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 2.0], "fingerings": ["2", "1", "2", "1", "2", "1", "2", "1", "2", "1"]},
			{"number": 3, "display_number": "6", "title": "Luyện gảy các nốt cơ bản – Phần 2", "type": "practice", "video": "Cách nhận diện cao độ 7 nốt nhạc ở âm vực cao trên Đàn Tranh.", "practice": "Gảy lần lượt dây 11 đến dây 17: Sol3, La3, Đô4, Rê4, Mi4, Sol4 và La4. Luân phiên ngón 3, ngón 2 rồi ngón 1 từ nốt đầu tiên. Ứng dụng dùng micro nhận diện đúng cao độ từng dây trước khi chuyển sang nốt tiếp theo.", "practice_title": "Nhận diện 7 dây – Luân phiên ngón 3, 2 và 1", "sheet": ["Sol3", "La3", "Đô4", "Rê4", "Mi4", "Sol4", "La4"], "durations": [1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 2.0], "fingerings": ["3", "2", "1", "3", "2", "1", "3"]},
			{"number": 10, "display_number": "7", "practice_id": "dan_tranh_level_2_bai_10_practice", "video_id": "dan_tranh_level_2_bai_10_video", "title": "Luyện bài Lý cây đa – Nửa đoạn đầu", "type": "practice", "video": "Hướng dẫn gảy đoạn đầu bài Lý Cây Đa: giai điệu và ngón gảy.", "practice": "Luyện gảy đoạn đầu bài Lý Cây Đa với nhịp độ chậm.", "practice_title": "Lý Cây Đa – Đoạn đầu", "sheet": ["Sol2", "Sol2", "La2", "Đô3", "Rê3", "Mi3", "Rê3", "Đô3", "La2", "Sol2"], "durations": [1.0, 1.0, 0.5, 0.5, 1.0, 1.0, 0.5, 0.5, 1.0, 2.0]},
			{"number": 11, "display_number": "8", "practice_id": "dan_tranh_level_2_bai_11_practice", "video_id": "dan_tranh_level_2_bai_11_video", "title": "Luyện bài Lý cây đa – Nửa đoạn cuối", "type": "practice", "video": "Hướng dẫn gảy đoạn sau bài Lý Cây Đa.", "practice": "Luyện gảy đoạn sau bài Lý Cây Đa.", "practice_title": "Lý Cây Đa – Đoạn sau", "sheet": ["La2", "Đô3", "Sol2", "La2", "Đô3", "Rê3", "Mi3", "Rê3", "Đô3", "La2", "Sol2", "La2", "Đô3", "Sol2"], "durations": [0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 2.0]},
			{"number": 12, "display_number": "9", "practice_id": "dan_tranh_level_2_bai_12_practice", "video_id": "dan_tranh_level_2_bai_12_video", "title": "Hoàn thiện bài Lý cây đa", "type": "practice", "video": "Ôn tập và ghép hoàn chỉnh bài Lý Cây Đa.", "practice": "Luyện đánh cả bài Lý Cây Đa với tiết tấu ổn định.", "practice_title": "Lý Cây Đa – Cả bài", "sheet": ["Sol2", "Sol2", "La2", "Đô3", "Rê3", "Mi3", "Rê3", "Đô3", "La2", "Sol2", "La2", "Đô3", "Sol2"], "durations": [1.0, 1.0, 0.5, 0.5, 1.0, 1.0, 0.5, 0.5, 1.0, 1.0, 0.5, 0.5, 2.0]}
		]
	},
	{
		"level": 2,
		"title": "KỸ THUẬT DIỄN TẤU",
		"sessions": "Bài 10–16",
		"objective": "Luyện kỹ thuật Á, nhấn, song thanh, rung dây trước khi hoàn thiện Sứ Thanh Hoa.",
		"lessons": [
			{"number": 18, "display_number": "10", "practice_id": "dan_tranh_level_7_bai_18_practice", "practice_mode": "glissando", "practiceConfig": {"practiceMode": "glissando", "rounds": [{"direction": "down", "stringSequence": [1, 2, 3, 4, 5, 6], "finger": "2"}, {"direction": "up", "stringSequence": [17, 16, 15, 14, 13, 12], "finger": "1"}]}, "title": "Kỹ thuật Á", "video": "", "practice": "Thực hành Á xuống 6 dây từ dây 1 đến dây 6 và Á lên 6 dây từ dây 17 về dây 12.", "practice_title": "Kỹ thuật Á – Vuốt 6 dây", "sheet": ["Sol1", "La1", "Đô2", "Rê2", "Mi2", "Sol2"]},
			{"number": 19, "display_number": "11", "practice_id": "dan_tranh_level_7_bai_19_practice", "practice_mode": "press", "practiceConfig": {"practiceMode": "press", "noteSequence": ["Mi2", "Fa2", "La2", "Si2", "Mi3", "Fa3", "La3", "Si3"], "techniqueCues": ["press", "", "press", "", "press", "", "press", ""]}, "title": "Kỹ thuật nhấn", "video": "", "practice": "Gảy nốt gốc rồi nhấn đúng dây để nâng Mi lên Fa và La lên Si ở hai âm vực.", "practice_title": "Kỹ thuật nhấn – Mi lên Fa, La lên Si", "sheet": ["Mi2", "Fa2", "La2", "Si2", "Mi3", "Fa3", "La3", "Si3"], "durations": [1.0, 2.0, 1.0, 2.0, 1.0, 2.0, 1.0, 2.0], "cues": ["press", "", "press", "", "press", "", "press", ""]},
			{
				"number": 20,
				"display_number": "12",
				"practice_id": "dan_tranh_level_7_bai_20_practice",
				"practice_mode": "double_stop",
				"practiceConfig": {"practiceMode": "double_stop", "fingerings": ["1 + 2", "1 + 2", "1 + 2", "1 + 2", "1 + 2", "1 + 2", "1 + 2", "1 + 2", "1 + 2", "1 + 2", "1 + 2", "1 + 2"]},
				"title": "Kỹ thuật song thanh",
				"video": "",
				"practice": "Dùng ngón 1 và ngón 2 gảy đồng thời 2 dây để tạo song thanh.",
				"practice_title": "Luyện tập: Kỹ thuật song thanh",
				"sheet": [
					"Đô2+Mi2", "Đô2+Mi2", "Đô2+Mi2",
					"Mi2+Sol2", "Mi2+Sol2", "Mi2+Sol2",
					"La1+Đô2", "La1+Đô2", "La1+Đô2",
					"Đô2+Mi2", "Mi2+Sol2", "La1+Đô2"
				],
				"cues": ["circle", "circle", "circle", "triangle", "triangle", "triangle", "circle", "circle", "circle", "circle", "triangle", "circle"],
				"fingerings": ["1 + 2", "1 + 2", "1 + 2", "1 + 2", "1 + 2", "1 + 2", "1 + 2", "1 + 2", "1 + 2", "1 + 2", "1 + 2", "1 + 2"]
			},
			{"number": 21, "display_number": "13", "practice_id": "dan_tranh_level_7_bai_21_practice", "practice_mode": "vibrato", "practiceConfig": {"practiceMode": "vibrato", "noteSequence": ["Sol2", "La2", "Đô3", "Rê3", "Mi3", "Sol3", "La3"], "techniqueCues": ["vibrato", "vibrato", "vibrato", "vibrato", "vibrato", "vibrato", "vibrato"]}, "title": "Kỹ thuật rung dây", "video": "", "practice": "Gảy rồi rung lần lượt các nốt Sol2, La2, Đô3, Rê3, Mi3, Sol3 và La3 bằng tay trái.", "practice_title": "Kỹ thuật rung – Tay trái", "sheet": ["Sol2", "La2", "Đô3", "Rê3", "Mi3", "Sol3", "La3"], "durations": [2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0], "cues": ["vibrato", "vibrato", "vibrato", "vibrato", "vibrato", "vibrato", "vibrato"]},
			{"number": 13, "display_number": "14", "title": "Luyện bài Sứ thanh hoa – Nửa đoạn đầu", "type": "practice", "video": "Hướng dẫn gảy đoạn đầu bài Sứ Thanh Hoa: chuyển quãng và nhấn nhả nốt.", "practice": "Luyện gảy đoạn đầu bài Sứ Thanh Hoa ở tốc độ chậm.", "practice_title": "Sứ Thanh Hoa – Đoạn đầu", "sheet": ["Rê3", "Đô3", "La2", "Đô3", "Đô3", "La2", "Đô3", "Đô3", "La2", "Đô3", "La2", "Sol2"], "durations": [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5, 2.0]},
			{"number": 14, "display_number": "15", "title": "Luyện bài Sứ thanh hoa – Nửa đoạn cuối", "type": "practice", "video": "Hướng dẫn gảy đoạn sau bài Sứ Thanh Hoa.", "practice": "Luyện gảy đoạn sau bài Sứ Thanh Hoa.", "practice_title": "Sứ Thanh Hoa – Đoạn sau", "sheet": ["Rê3", "Đô3", "La2", "Đô3", "Đô3", "La2", "Đô3", "Đô3", "Mi3", "Rê3", "Đô3", "Sol2", "La2", "Mi3", "Mi3", "Rê3", "Mi3", "Rê3", "Mi3", "Sol3", "Mi3"], "durations": [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 2.0]},
			{"number": 15, "display_number": "16", "title": "Hoàn thiện bài Sứ thanh hoa", "type": "practice", "video": "Ôn tập và ghép hoàn chỉnh bài Sứ Thanh Hoa.", "practice": "Luyện đánh cả bài Sứ Thanh Hoa ở BPM 80 với các quãng rộng.", "practice_title": "Sứ Thanh Hoa – Cả bài", "sheet": ["Rê3", "Đô3", "La2", "Đô3", "Đô3", "La2", "Đô3", "Đô3", "La2", "Đô3", "La2", "Sol2", "Rê3", "Đô3", "La2", "Đô3", "Đô3", "La2", "Đô3", "Đô3", "Mi3", "Rê3", "Đô3", "Sol2", "La2", "Mi3", "Mi3", "Rê3", "Mi3", "Rê3", "Mi3", "Sol3", "Mi3", "Rest", "Mi3", "Mi3", "Rê3", "Đô3", "Mi3", "Rê3", "Rê3", "Đô3", "La2", "Đô3", "Đô3", "La2", "Đô3", "La2", "Sol2", "Sol2", "La2", "Mi3", "Sol3", "Sol3", "Mi3", "Sol3", "Sol3", "Mi3", "Rê3", "Đô3", "Đô3", "Rê3", "Đô3", "Rê3", "Mi3", "Rê3", "Rê3", "Đô3", "Rê3", "Đô3", "Rê3", "Đô3", "Đô3", "La2", "Đô3", "Rê3", "Rê3", "Rê3"], "durations": [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5, 2.0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 1.0, 1.0, 0.5, 0.5, 2.0, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 3.0, 1.0, 1.0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 2.0]}
		]
	},
	{
		"level": 3,
		"title": "LUYỆN NGÓN VÀ DÂN CA CỔ TRUYỀN",
		"sessions": "Bài 7",
		"objective": "Luyện ngón tay linh hoạt qua bài tập có tốc độ cao.",
		"lessons": [
			{
				"number": 7,
				"title": "Luyện ngón tốc độ cao – Mã Vũ",
				"video": "Kỹ thuật giữ khung bàn tay vững chãi và di chuyển ngón nhanh trên các phím đàn khi chơi điệu hành khúc Mã Vũ.",
				"practice": "Thực hành gảy bài nhạc Mã Vũ đoạn 1 đúng trường độ và nhịp độ nhanh.",
				"practice_title": "Luyện ngón: Mã Vũ",
				"sheet": ["Đô2", "Rê2", "Mi2", "Rê2", "Đô2", "La2", "Sol2", "Sol2", "Đô2", "Rê2", "Mi2", "Sol2", "Mi2", "Rê2", "Đô2", "Đô2", "La2", "Sol2", "Sol2", "Sol2", "Đô2", "Rê2", "Đô2", "Sol2"],
				"durations": [0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 1.0]
			}
		]
	},
	{
		"level": 4,
		"title": "KỸ THUẬT TAY TRÁI & HỢP ÂM",
		"sessions": "Bài 9",
		"objective": "Làm chủ kỹ thuật nhấn rung tay trái trên Đàn Tranh.",
		"lessons": [
			{
				"number": 9,
				"title": "Kỹ thuật nhấn Rung tay trái",
				"video": "Cách nhấn rung tay trái bên trái nhạn đàn để tạo âm ngân luyến truyền cảm, linh hồn Đàn Tranh.",
				"practice": "Thực hành gảy các nốt ngân dài kết hợp nhấn rung đều tay trái.",
				"practice_title": "Rung dây Đàn Tranh",
				"sheet": ["Đô2", "Đô2", "Rê2", "Rê2", "Mi2", "Mi2", "Sol2", "Sol2"],
				"durations": [2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0]
			}
		]
	},
	{
		"level": 5,
		"title": "MASTER – NHẠC HIỆN ĐẠI",
		"sessions": "Bài 12",
		"objective": "Thử thách tổng hợp khả năng nhận diện và gảy đủ 17 dây Đàn Tranh.",
		"lessons": [
			{
				"number": 12,
				"title": "Boss Stage – Thử thách sinh tồn",
				"video": "",
				"practice": "Chọn một bài đã học và biểu diễn bằng giao diện luyện tập hiện có.",
				"practice_title": "Thử thách sinh tồn 17 dây",
				"sheet": ["Sol1", "La1", "Đô2", "Rê2", "Mi2", "Sol2", "La2", "Đô3", "Rê3", "Mi3", "Sol3", "La3", "Đô4", "Rê4", "Mi4", "Sol4", "La4"]
			}
		]
	},
	{
		"level": 6,
		"title": "HỢP ÂM CƠ BẢN",
		"sessions": "Bài 5",
		"objective": "Luyện chuyển mượt mà giữa hợp âm Đô trưởng và La thứ.",
		"lessons": [
			{
				"number": 17,
				"title": "Bài 5: Chuyển hợp âm",
				"video": "res://Video/DanBauDoan12Bai1.ogv",
				"practice": "Chuyển mượt mà giữa Đô trưởng (C) và La thứ (Am).",
				"practice_title": "Luyện tập: Chuyển hợp âm",
				"sheet": [
					"Đô2+Mi2+Sol2", "La1+Đô2+Mi2", "Đô2+Mi2+Sol2", "La1+Đô2+Mi2",
					"Đô2+Mi2+Sol2", "La1+Đô2+Mi2", "Đô2+Mi2+Sol2", "La1+Đô2+Mi2",
					"Đô2+Mi2+Sol2", "La1+Đô2+Mi2", "La1+Đô2+Mi2", "Đô2+Mi2+Sol2", "Đô2+Mi2+Sol2", "La1+Đô2+Mi2"
				],
				"cues": ["circle", "circle", "circle", "circle", "triangle", "triangle", "triangle", "triangle", "circle", "circle", "triangle", "triangle", "circle", "triangle"],
				"fingerings": ["1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3"]
			}
		]
	},
	{
		"level": 7,
		"title": "KỸ THUẬT NÂNG CAO MỞ RỘNG",
		"sessions": "Bài 17–18 (gồm 18.1–18.2)",
		"objective": "Mở rộng khả năng diễn tấu với kỹ thuật vê và hợp âm ba âm cơ bản.",
		"lessons": [
			{
				"number": 30,
				"display_number": "17",
				"practice_id": "dan_tranh_level_8_bai_30_practice",
				"practice_mode": "tremolo",
				"practiceConfig": {"practiceMode": "tremolo", "noteSequence": ["Đô2", "Mi2", "Sol2", "Mi2", "Đô2", "Mi2", "Sol2", "Mi2"], "fingerings": ["2", "2", "2", "2", "2", "2", "2", "2"]},
				"title": "Kỹ thuật Vê",
				"video": "",
				"practice": "Thực hành kỹ thuật vê đều tay để tạo âm thanh liên tục và tròn tiếng.",
				"practice_title": "Kỹ thuật Vê",
				"sheet": ["Đô2", "Mi2", "Sol2", "Mi2", "Đô2", "Mi2", "Sol2", "Mi2"],
				"durations": [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0],
				"fingerings": ["2", "2", "2", "2", "2", "2", "2", "2"]
			},
			{
				"number": 31,
				"display_number": "18",
				"practice_id": "dan_tranh_level_8_bai_31_practice",
				"practice_mode": "triad",
				"practiceConfig": {"practiceMode": "triad", "fingerings": ["1", "2", "1", "2", "1", "1", "1", "2", "1", "2", "1 + 2 + 3"]},
				"title": "Hợp âm ba âm cơ bản",
				"video": "",
				"practice": "Phân biệt nốt đơn và hợp âm. Ôn lại các nốt cơ bản và gảy thử hợp âm Đô trưởng.",
				"practice_title": "Hợp âm ba âm cơ bản",
				"sheet": ["Sol1", "La1", "Đô2", "Rê2", "Mi2", "Mi2", "Đô2", "La1", "Sol1", "Rê2", "Đô2+Mi2+Sol2"],
				"cues": ["circle", "circle", "circle", "circle", "circle", "triangle", "triangle", "triangle", "triangle", "triangle", "circle"],
				"fingerings": ["1", "2", "1", "2", "1", "1", "1", "2", "1", "2", "1 + 2 + 3"]
			},
			{
				"number": 32,
				"display_number": "18.1",
				"practice_id": "dan_tranh_level_8_bai_32_practice",
				"practice_mode": "triad",
				"practiceConfig": {"practiceMode": "triad", "fingerings": ["1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3"]},
				"title": "Hợp âm Đô trưởng",
				"video": "",
				"practice": "Thực hành đánh hợp âm Đô trưởng bằng ba ngón, giữ tiếng đàn rõ và đồng đều.",
				"practice_title": "Hợp âm Đô trưởng – Ba ngón",
				"sheet": [
					"Đô2+Mi2+Sol2", "Đô2+Mi2+Sol2", "Đô2+Mi2+Sol2",
					"Đô2+Mi2+Sol2", "Đô2+Mi2+Sol2",
					"Đô2+Mi2+Sol2", "Đô2+Mi2+Sol2", "Đô2+Mi2+Sol2", "Đô2+Mi2+Sol2"
				],
				"cues": ["circle", "circle", "circle", "circle", "circle", "triangle", "triangle", "triangle", "triangle"],
				"fingerings": ["1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3"]
			},
			{
				"number": 33,
				"display_number": "18.2",
				"practice_id": "dan_tranh_level_8_bai_33_practice",
				"practice_mode": "triad",
				"practiceConfig": {"practiceMode": "triad", "fingerings": ["1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3"]},
				"title": "Hợp âm La thứ",
				"video": "",
				"practice": "Thực hành đánh hợp âm La thứ bằng ba ngón, giữ nhịp chắc và cân bằng các dây.",
				"practice_title": "Hợp âm La thứ – Ba ngón",
				"sheet": [
					"La1+Đô2+Mi2", "La1+Đô2+Mi2", "La1+Đô2+Mi2",
					"Đô2+Mi2+Sol2", "La1+Đô2+Mi2", "Đô2+Mi2+Sol2", "La1+Đô2+Mi2",
					"La1+Đô2+Mi2", "La1+Đô2+Mi2", "La1+Đô2+Mi2", "La1+Đô2+Mi2"
				],
				"cues": ["circle", "circle", "circle", "triangle", "circle", "triangle", "circle", "circle", "circle", "circle", "circle"],
				"fingerings": ["1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3", "1 + 2 + 3"]
			}
		]
	}
]

