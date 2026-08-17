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
