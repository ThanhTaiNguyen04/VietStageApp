extends RefCounted

static var instrument := "dan_tranh"
static var local_lesson_ids: Array[String] = []
static var return_scene := "res://scenes/MainMenu.tscn"
static var activity := ""

static func configure(instrument_key: String, lesson_ids: Array, scene_path: String) -> void:
	instrument = instrument_key
	local_lesson_ids.clear()
	for lesson_id: Variant in lesson_ids:
		local_lesson_ids.append(str(lesson_id))
	return_scene = scene_path
	activity = ""

static func ensure_defaults() -> void:
	if local_lesson_ids.is_empty():
		local_lesson_ids.append("Node1")


# ─── Quiz data normalization (single source of truth for FE) ──────────────

## Parse `options` từ BE: ưu tiên Array → JSON array string → chuỗi `|` → chuỗi `,`.
## Mỗi phần tử được trim để tránh khoảng trắng thừa làm hỏng tra cứu nốt trên khuông.
static func parse_options(raw: Variant) -> Array:
	var options: Array = []
	if raw is Array:
		options = raw
	else:
		var text := str(raw).strip_edges()
		var parsed: Variant = null
		if text.begins_with("["):
			parsed = JSON.parse_string(text)
			if parsed is String:
				parsed = JSON.parse_string(parsed)
		if parsed is Array:
			options = parsed
		elif text.contains("|"):
			options = text.split("|")
		else:
			options = text.split(",")
	var result: Array = []
	for option: Variant in options:
		var clean := str(option).strip_edges()
		if not clean.is_empty():
			result.append(clean)
	return result


## Chuẩn hóa đáp án: trim, lowercase, bỏ prefix dạng "A.", "A)".
static func normalize_answer(value: String) -> String:
	var normalized := value.strip_edges().to_lower()
	var prefix := RegEx.new()
	prefix.compile("^[a-z][.)]\\s*")
	return prefix.sub(normalized, "", true).strip_edges()


## Tìm index của đáp án đúng trong options. Hỗ trợ:
## - dạng chữ cái "A" (0-based)
## - dạng nội dung option ("Sol")
## - dạng có prefix "A. Sol"
static func resolve_correct_index(quiz: Dictionary, options: Array) -> int:
	if options.is_empty():
		return -1
	var expected := normalize_answer(str(quiz.get("correctAnswer", quiz.get("correct_answer", ""))))
	if expected.is_empty():
		var note_val := str(quiz.get("note", quiz.get("targetNote", ""))).strip_edges()
		if not note_val.is_empty():
			expected = normalize_answer(note_val)
	if expected.is_empty():
		return -1
	if expected.length() == 1:
		var letter_index := expected.unicode_at(0) - "a".unicode_at(0)
		if letter_index >= 0 and letter_index < options.size():
			return letter_index
	for i in options.size():
		if normalize_answer(str(options[i])) == expected:
			return i
	return -1


## Nốt FE vẽ trên khuông nhạc.
## Ưu tiên `note`/`targetNote` từ BE; nếu thiếu thì lấy nội dung option đúng.
## Luôn trim và bỏ prefix chữ cái để khớp `StaffDisplay.NOTE_POSITIONS`.
static func resolve_staff_note(quiz: Dictionary, options: Array) -> String:
	var note := str(quiz.get("note", quiz.get("targetNote", ""))).strip_edges()
	if not note.is_empty():
		return normalize_note(note)
	var correct_index := resolve_correct_index(quiz, options)
	if correct_index >= 0 and correct_index < options.size():
		return normalize_note(str(options[correct_index]))
	return "Sol"


## Chuẩn hóa tên nốt cho khuông nhạc: trim + bỏ prefix "A."/"A)".
static func normalize_note(value: String) -> String:
	var note := value.strip_edges()
	var prefix := RegEx.new()
	prefix.compile("^[a-zA-Z][.)]\\s*")
	note = prefix.sub(note, "", true).strip_edges()
	return note


## Chuẩn hóa tên nốt để SO SÁNH: bỏ dấu tiếng Việt, lowercase, bỏ octave và khoảng trắng thừa.
## Dùng cho đối chiếu đáp án trong MelodyCompletion, không dùng để vẽ khuông nhạc.
static func normalize_note_compare(value: String) -> String:
	var note := normalize_note(value).to_lower()
	note = note.replace("đ", "d")
	note = note.replace("ố", "o").replace("ồ", "o").replace("ổ", "o").replace("ỗ", "o").replace("ộ", "o")
	note = note.replace("ô", "o")
	note = note.replace("ế", "e").replace("ề", "e").replace("ể", "e").replace("ễ", "e").replace("ệ", "e")
	note = note.replace("ê", "e")
	note = note.replace("ớ", "o").replace("ờ", "o").replace("ở", "o").replace("ỡ", "o").replace("ợ", "o")
	note = note.replace("ơ", "o")
	note = note.replace("ứ", "u").replace("ừ", "u").replace("ử", "u").replace("ữ", "u").replace("ự", "u")
	note = note.replace("ư", "u")
	note = note.replace("á", "a").replace("à", "a").replace("ả", "a").replace("ã", "a").replace("ạ", "a")
	note = note.replace("ấ", "a").replace("ầ", "a").replace("ẩ", "a").replace("ẫ", "a").replace("ậ", "a")
	note = note.replace("ắ", "a").replace("ằ", "a").replace("ẳ", "a").replace("ẵ", "a").replace("ặ", "a")
	note = note.replace("í", "i").replace("ì", "i").replace("ỉ", "i").replace("ĩ", "i").replace("ị", "i")
	note = note.replace("ó", "o").replace("ò", "o").replace("ỏ", "o").replace("õ", "o").replace("ọ", "o")
	note = note.replace("ú", "u").replace("ù", "u").replace("ủ", "u").replace("ũ", "u").replace("ụ", "u")
	note = note.replace("ý", "y").replace("ỳ", "y").replace("ỷ", "y").replace("ỹ", "y").replace("ỵ", "y")
	note = note.strip_edges()
	var octave_re := RegEx.new()
	octave_re.compile("[0-9]+\\s*$")
	note = octave_re.sub(note, "", true).strip_edges()
	return note
