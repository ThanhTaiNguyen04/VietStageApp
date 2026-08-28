extends Control

var notes: Array[String] = []
var missing_index := -1
var answer_visible := false
var answer_correct := false
var selected_note := ""

var clef_texture: Texture2D
var lora_font: Font
var bold_font: Font

func _ready() -> void:
	custom_minimum_size = Vector2(0, 210)
	if ResourceLoader.exists("res://icons8/icons8-treble-clef-120.png"):
		clef_texture = load("res://icons8/icons8-treble-clef-120.png")
	elif ResourceLoader.exists("res://assets/textures/treble_clef.svg"):
		clef_texture = load("res://assets/textures/treble_clef.svg")
	if ResourceLoader.exists("res://assets/fonts/Lora-Bold.ttf"):
		lora_font = load("res://assets/fonts/Lora-Bold.ttf")
	if ResourceLoader.exists("res://assets/fonts/BeVietnamPro-Bold.ttf"):
		bold_font = load("res://assets/fonts/BeVietnamPro-Bold.ttf")
	queue_redraw()

func configure(note_values: Array, missing: int) -> void:
	notes.clear()
	for value: Variant in note_values:
		notes.append(str(value).strip_edges())
	missing_index = missing
	answer_visible = false
	answer_correct = false
	selected_note = ""
	queue_redraw()

func show_answer(correct: bool, selected: String) -> void:
	answer_visible = true
	answer_correct = correct
	selected_note = selected
	queue_redraw()

func _draw() -> void:
	var width := maxf(size.x, 320.0)
	var height := maxf(size.y, 200.0)
	
	# Staff spacing: 22px on mobile / small, 24px on desktop
	var spacing := 22.0 if width < 500.0 else 24.0
	var center_y := height * 0.46 # Line 3 (Middle line B4 / Si)
	
	var left_margin := 26.0
	var right_margin := width - 26.0
	
	# 1. Draw 5 Staff Lines
	# Đếm từ dưới lên:
	# Dòng 1 (dưới cùng): center_y + 2.0 * spacing (Mi 4)
	# Dòng 2 (Sol 4):     center_y + 1.0 * spacing (Tâm Khóa Sol)
	# Dòng 3 (giữa - Si): center_y
	# Dòng 4 (Rê 5):      center_y - 1.0 * spacing
	# Dòng 5 (trên cùng): center_y - 2.0 * spacing (Fa 5)
	var staff_line_color := Color("#1e293b") # Slate-800
	for i in range(5):
		var y := center_y + (float(i) - 2.0) * spacing
		draw_line(Vector2(left_margin, y), Vector2(right_margin, y), staff_line_color, 2.0, true)

	# 2. Draw Start Bar Line
	var staff_top_y := center_y - 2.0 * spacing
	var staff_bot_y := center_y + 2.0 * spacing
	draw_line(Vector2(left_margin, staff_top_y), Vector2(left_margin, staff_bot_y), staff_line_color, 4.0, true)

	# 3. Draw Treble Clef (Khóa Sol) đồng bộ với StaffDisplay.gd trong Quiz
	var font := ThemeDB.fallback_font
	var clef_scale := 6.5
	var clef_font_size := int(spacing * clef_scale)
	var clef_y_offset := clef_font_size * 0.20
	var clef_x := left_margin - 16.0
	
	if font:
		draw_string(font, Vector2(clef_x, center_y + clef_y_offset), "𝄞", HORIZONTAL_ALIGNMENT_LEFT, -1, clef_font_size, staff_line_color)

	# 4. Draw Time Signature (4/4) đồng bộ với StaffDisplay.gd trong Quiz
	# Số 4 trên: chiếm 2 khe trên (giữa dòng 3 và dòng 5), baseline đặt tại dòng 3 (center_y + spacing * 0.05)
	# Số 4 dưới: chiếm 2 khe dưới (giữa dòng 1 và dòng 3), baseline đặt tại dòng 1 (center_y + spacing * 2.05)
	var num_font := bold_font if bold_font else font
	var ts_size := int(spacing * 2.2)
	var ts_x := clef_x + spacing * clef_scale * 0.68
	
	if num_font:
		# Top digit 4
		draw_string(num_font, Vector2(ts_x, center_y + spacing * 0.05), "4", HORIZONTAL_ALIGNMENT_LEFT, -1, ts_size, staff_line_color)
		# Bottom digit 4
		draw_string(num_font, Vector2(ts_x, center_y + spacing * 2.05), "4", HORIZONTAL_ALIGNMENT_LEFT, -1, ts_size, staff_line_color)

	if notes.is_empty():
		return

	# 5. Distribute Notes across usable width
	var start_note_x := ts_x + spacing * 2.4
	var end_note_x := right_margin - 36.0
	var total_note_slots := maxi(1, notes.size() - 1)
	var step_x := (end_note_x - start_note_x) / float(total_note_slots) if notes.size() > 1 else 0.0
	if notes.size() == 1:
		start_note_x = (start_note_x + end_note_x) * 0.5

	var note_head_rx := spacing * 0.65
	var note_head_ry := spacing * 0.45
	var stem_length := spacing * 2.8
	var stem_width := 2.6

	for i in range(notes.size()):
		var raw_note := notes[i]
		var is_missing := (i == missing_index)
		var note_x := start_note_x + step_x * float(i)
		var diatonic_step := _parse_diatonic_step(raw_note)
		
		# note_y: khoảng cách từ Dòng 3 (Si / B4, step = 6)
		# Step 0 (Đô 4): y = center_y + 3.0 * spacing (1 dòng phụ dưới Dòng 1)
		# Step 2 (Mi 4): y = center_y + 2.0 * spacing (Dòng 1)
		# Step 4 (Sol 4): y = center_y + 1.0 * spacing (Dòng 2)
		# Step 6 (Si 4): y = center_y (Dòng 3)
		# Step 10 (Fa 5): y = center_y - 2.0 * spacing (Dòng 5)
		var note_y := center_y - float(diatonic_step - 6) * (spacing * 0.5)

		# 5.A. Vẽ dòng phụ (Ledger Lines) cho nốt ngoài khuôn nhạc
		# Dòng phụ dưới (Đô 4 / C4 step 0 trở xuống)
		if diatonic_step <= 0:
			var num_ledgers := int(abs(diatonic_step) / 2) + 1
			for l in range(num_ledgers):
				var ledger_step := -l * 2
				var ly := center_y - float(ledger_step - 6) * (spacing * 0.5)
				draw_line(Vector2(note_x - note_head_rx * 1.55, ly), Vector2(note_x + note_head_rx * 1.55, ly), staff_line_color, 2.2, true)
		# Dòng phụ trên (La 5 / A5 step 12 trở lên)
		elif diatonic_step >= 12:
			var num_ledgers := int((diatonic_step - 12) / 2) + 1
			for l in range(num_ledgers):
				var ledger_step := 12 + l * 2
				var ly := center_y - float(ledger_step - 6) * (spacing * 0.5)
				draw_line(Vector2(note_x - note_head_rx * 1.55, ly), Vector2(note_x + note_head_rx * 1.55, ly), staff_line_color, 2.2, true)

		# 5.B. Màu nốt
		var note_color := Color("#0f172a") # Slate-900 cho nốt thông thường
		if is_missing:
			if not answer_visible:
				note_color = Color("#d97706") # Amber cho nốt còn thiếu
			else:
				note_color = Color("#16a34a") if answer_correct else Color("#dc2626")

		# 5.C. Vẽ đầu nốt (hình elip xoay -18 độ)
		if is_missing and not answer_visible:
			_draw_rotated_ellipse(note_x, note_y, note_head_rx, note_head_ry, deg_to_rad(-18), Color(0.96, 0.68, 0.15, 0.20))
			_draw_rotated_ellipse_outline(note_x, note_y, note_head_rx, note_head_ry, deg_to_rad(-18), note_color, 2.8)
		else:
			_draw_rotated_ellipse(note_x, note_y, note_head_rx, note_head_ry, deg_to_rad(-18), note_color)

		# 5.D. Vẽ đuôi nốt (Stem)
		# Quy tắc quốc tế: Nốt từ Dòng 3 (Si / B4, step >= 6) trở lên -> đuôi quay XUỐNG ở bên trái
		# Nốt dưới Dòng 3 (step < 6) -> đuôi quay LÊN ở bên phải
		var stem_up := diatonic_step < 6
		var stem_x := note_x + (note_head_rx * 0.85) if stem_up else note_x - (note_head_rx * 0.85)
		var stem_start_y := note_y
		var stem_end_y := note_y - stem_length if stem_up else note_y + stem_length
		draw_line(Vector2(stem_x, stem_start_y), Vector2(stem_x, stem_end_y), note_color, stem_width, true)

		# 5.E. Ký hiệu phía dưới (Dấu ? hoặc Tên nốt tiếng Việt khi đã trả lời)
		var label_font := bold_font if bold_font else ThemeDB.fallback_font
		if label_font:
			if is_missing and not answer_visible:
				var q_rect_y := height - 32.0
				var q_bg := Rect2(note_x - 13, q_rect_y - 2, 26, 24)
				draw_rect(q_bg, Color(0.96, 0.68, 0.15, 0.15), true)
				draw_rect(q_bg, Color(0.96, 0.68, 0.15, 0.6), false, 1.5)
				draw_string(label_font, Vector2(note_x - 5, q_rect_y + 16), "?", HORIZONTAL_ALIGNMENT_CENTER, 10, 15, Color("#d97706"))
			elif is_missing and answer_visible:
				var display_str := _to_vietnamese_solfege(raw_note)
				var ans_rect_y := height - 32.0
				var tag_color := Color("#16a34a") if answer_correct else Color("#dc2626")
				var tag_bg := Color(0.09, 0.64, 0.29, 0.15) if answer_correct else Color(0.86, 0.15, 0.15, 0.15)
				var tag_w := maxf(48.0, label_font.get_string_size(display_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 14).x + 16.0)
				var tag_rect := Rect2(note_x - tag_w * 0.5, ans_rect_y - 2, tag_w, 24)
				draw_rect(tag_rect, tag_bg, true)
				draw_rect(tag_rect, tag_color, false, 1.5)
				draw_string(label_font, Vector2(note_x - tag_w * 0.5, ans_rect_y + 15), display_str, HORIZONTAL_ALIGNMENT_CENTER, tag_w, 14, tag_color)

func _draw_rotated_ellipse(cx: float, cy: float, rx: float, ry: float, angle: float, color: Color) -> void:
	var points := PackedVector2Array()
	var center := Vector2(cx, cy)
	var segments := 32
	for i in range(segments):
		var t := float(i) * TAU / float(segments)
		var px := cos(t) * rx
		var py := sin(t) * ry
		var rpx := px * cos(angle) - py * sin(angle)
		var rpy := px * sin(angle) + py * cos(angle)
		points.append(center + Vector2(rpx, rpy))
	draw_colored_polygon(points, color)

func _draw_rotated_ellipse_outline(cx: float, cy: float, rx: float, ry: float, angle: float, color: Color, line_w: float) -> void:
	var points := PackedVector2Array()
	var center := Vector2(cx, cy)
	var segments := 32
	for i in range(segments + 1):
		var t := float(i % segments) * TAU / float(segments)
		var px := cos(t) * rx
		var py := sin(t) * ry
		var rpx := px * cos(angle) - py * sin(angle)
		var rpy := px * sin(angle) + py * cos(angle)
		points.append(center + Vector2(rpx, rpy))
	draw_polyline(points, color, line_w, true)

# Ánh xạ nốt nhạc sang bước Diatonic chuẩn Khóa Sol (Middle C / Đô 4 = 0):
# Đô (C4)=0 (1 dòng phụ dưới Dòng 1)
# Rê (D4)=1 (khe dưới Dòng 1)
# Mi (E4)=2 (Dòng 1 - dưới cùng)
# Fa (F4)=3 (Khe 1)
# Sol (G4)=4 (Dòng 2 - tâm Khóa Sol)
# La (A4)=5 (Khe 2)
# Si (B4)=6 (Dòng 3 - giữa)
# Đố (C5)=7 (Khe 3)
# Rế (D5)=8 (Dòng 4)
# Mí (E5)=9 (Khe 4)
# Fá (F5)=10 (Dòng 5 - trên cùng)
# Sól (G5)=11 (Khe trên Dòng 5)
# Lá (A5)=12 (1 dòng phụ trên Dòng 5)
func _parse_diatonic_step(note_str: String) -> int:
	var s := note_str.to_lower().strip_edges()
	if s.begins_with("zt_"):
		s = s.substr(3)

	# 1. Tra cứu trực tiếp bảng nốt
	const EXACT_MAP = {
		# Xướng âm tiếng Việt chuẩn trung (Middle Octave)
		"do": 0, "dô": 0, "đo": 0, "đô": 0, "c": 0, "c4": 0, "c2": 0, "do2": 0, "đô2": 0, "đô_2": 0,
		"re": 1, "rê": 1, "d": 1, "d4": 1, "d2": 1, "re2": 1, "rê2": 1, "rê_2": 1,
		"mi": 2, "e": 2, "e4": 2, "e2": 2, "mi2": 2, "mi_2": 2,
		"fa": 3, "f": 3, "f4": 3, "f2": 3, "fa2": 3, "fa_2": 3,
		"sol": 4, "so": 4, "g": 4, "g4": 4, "g2": 4, "sol2": 4, "sol_2": 4,
		"la": 5, "a": 5, "a4": 5, "a2": 5, "la2": 5, "la_2": 5,
		"si": 6, "ti": 6, "b": 6, "b4": 6, "b2": 6, "si2": 6, "si_2": 6,
		
		# Quãng cao (Octave 5)
		"đố": 7, "do3": 7, "đô3": 7, "đô_3": 7, "c5": 7, "c3": 7,
		"rế": 8, "re3": 8, "rê3": 8, "rê_3": 8, "d5": 8, "d3": 8,
		"mí": 9, "mi3": 9, "mi_3": 9, "e5": 9, "e3": 9,
		"fá": 10, "fa3": 10, "fa_3": 10, "f5": 10, "f3": 10,
		"sól": 11, "sol3": 11, "sol_3": 11, "g5": 11, "g3": 11,
		"lá": 12, "la3": 12, "la_3": 12, "a5": 12, "a3": 12,
		"sĩ": 13, "si3": 13, "si_3": 13, "b5": 13, "b3": 13,
		
		# Quãng trầm (Octave 3)
		"sol1": -3, "sol_1": -3, "sò": -3, "g1": -3,
		"la1": -2, "la_1": -2, "là": -2, "a1": -2,
		"si1": -1, "si_1": -1, "sì": -1, "b1": -1,
		"c1": 0 # C1 trong bài tập cơ bản quy về Đô chuẩn
	}

	if EXACT_MAP.has(s):
		return int(EXACT_MAP[s])

	# 2. Phân tích tự động theo tiền tố âm
	if s.begins_with("c") or s.begins_with("do") or s.begins_with("đô"):
		return 0
	elif s.begins_with("d") or s.begins_with("re") or s.begins_with("rê"):
		return 1
	elif s.begins_with("e") or s.begins_with("mi"):
		return 2
	elif s.begins_with("f") or s.begins_with("fa"):
		return 3
	elif s.begins_with("g") or s.begins_with("sol") or s.begins_with("so"):
		return 4
	elif s.begins_with("a") or s.begins_with("la"):
		return 5
	elif s.begins_with("b") or s.begins_with("si") or s.begins_with("ti"):
		return 6

	return 0

# Chuyển đổi tên nốt sang xướng âm tiếng Việt chuẩn (Đô, Rê, Mi, Fa, Sol, La, Si)
static func _to_vietnamese_solfege(raw: String) -> String:
	var s := raw.strip_edges()
	if s.begins_with("ZT_"):
		s = s.substr(3)
	
	var lower := s.to_lower()
	if lower.begins_with("c") or lower.begins_with("do") or lower.begins_with("đô") or lower.begins_with("đo") or lower.begins_with("đồ") or lower.begins_with("đố"):
		return "Đô"
	elif lower.begins_with("d") or lower.begins_with("re") or lower.begins_with("rê") or lower.begins_with("rề") or lower.begins_with("rế"):
		return "Rê"
	elif lower.begins_with("e") or lower.begins_with("mi") or lower.begins_with("mì") or lower.begins_with("mí"):
		return "Mi"
	elif lower.begins_with("f") or lower.begins_with("fa") or lower.begins_with("fà") or lower.begins_with("fá"):
		return "Fa"
	elif lower.begins_with("g") or lower.begins_with("sol") or lower.begins_with("so") or lower.begins_with("sò") or lower.begins_with("sól"):
		return "Sol"
	elif lower.begins_with("a") or lower.begins_with("la") or lower.begins_with("là") or lower.begins_with("lá"):
		return "La"
	elif lower.begins_with("b") or lower.begins_with("si") or lower.begins_with("ti") or lower.begins_with("sì") or lower.begins_with("sĩ"):
		return "Si"
		
	return s

