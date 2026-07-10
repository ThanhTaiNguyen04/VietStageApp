extends Control
class_name MusicHighway

## ─────────────────────────────────────────────────────────────────────────────
##  MusicHighway — Simply Piano-style scrolling note lane for Đàn Bầu
##  Notes scroll RIGHT → LEFT. Fixed gold cursor at x = W * CURSOR_FRAC.
## ─────────────────────────────────────────────────────────────────────────────

signal note_hit(idx: int)

# ── Palette ────────────────────────────────────────────────────────────────
const C_LANE_BG   := Color(0.06, 0.03, 0.01, 1.0)
const C_CURSOR    := Color(0.85, 0.65, 0.18, 1.0)
const C_ACT       := Color(0.90, 0.62, 0.10, 1.0)   # current note: gold
const C_NEXT      := Color(0.95, 0.85, 0.55, 0.90)  # upcoming: cream
const C_DONE      := Color(0.18, 0.50, 0.30, 0.75)  # done: jade
const C_IDLE      := Color(0.48, 0.40, 0.28, 0.65)  # far future: dim
const C_TEXT      := Color(1.0, 1.0, 1.0, 1.0)
const C_GRID      := Color(1.0, 1.0, 1.0, 0.05)

# ── Layout ────────────────────────────────────────────────────────────────
const NOTE_W      := 64.0
const NOTE_H      := 36.0
const NOTE_GAP    := 16.0
const CURSOR_FRAC := 0.22
const DEMO_SPEED  := 90.0   # px/sec scroll during demo

# ── State ─────────────────────────────────────────────────────────────────
var _sheet       : Array[String] = []
var _note_idx    := 0
var _scroll_x    := 0.0
var _demo_active := false
var _demo_timer  := 0.0
var _demo_beat   := 1.4
var _pulse       := 0.0

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func load_sheet(notes: Array[String]) -> void:
	_sheet    = notes
	_note_idx = 0
	_scroll_x = 0.0
	queue_redraw()

func advance_to(idx: int) -> void:
	_note_idx = clampi(idx, 0, _sheet.size())
	var cx := size.x * CURSOR_FRAC
	_scroll_x = _raw_x(idx) - cx
	queue_redraw()

func play_demo() -> void:
	_demo_active = true
	_demo_timer  = 0.0

func stop_demo() -> void:
	_demo_active = false

func _process(delta: float) -> void:
	_pulse = fmod(_pulse + delta * 3.0, TAU)
	if _demo_active and _sheet.size() > 0:
		_demo_timer += delta
		if _demo_timer >= _demo_beat:
			_demo_timer -= _demo_beat
			if _note_idx < _sheet.size():
				note_hit.emit(_note_idx)
				_note_idx += 1
			if _note_idx >= _sheet.size():
				_demo_active = false
		_scroll_x += DEMO_SPEED * delta
	queue_redraw()

func _raw_x(i: int) -> float:
	return float(i) * (NOTE_W + NOTE_GAP)

func _screen_x(i: int) -> float:
	return size.x * CURSOR_FRAC + _raw_x(i) - _scroll_x

func _draw() -> void:
	var W := size.x; var H := size.y
	if W < 10.0 or H < 10.0: return

	draw_rect(Rect2(0, 0, W, H), C_LANE_BG)

	# 7 scale notes of Dan Bau
	var NOTES_PITCHES : Array[String] = ["Đô", "Rê", "Mi", "Fa", "Sol", "La", "Si"]
	var lane_count := 7
	var lane_h := H / float(lane_count + 1)

	# Draw horizontal lane guide lines
	var font := get_theme_font("font")
	for i in lane_count:
		var y := H - (i + 1) * lane_h
		# Draw horizontal lane staff lines
		draw_line(Vector2(0, y), Vector2(W, y), Color(C_CURSOR.r, C_CURSOR.g, C_CURSOR.b, 0.08), 1.0)
		# Label each lane on the left
		if font:
			var name : String = NOTES_PITCHES[i]
			draw_string(font, Vector2(12, y + 4), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(C_TEXT.r, C_TEXT.g, C_TEXT.b, 0.28))

	# Grid lines
	var beat := NOTE_W + NOTE_GAP
	var off  := fmod(_scroll_x, beat)
	var bx   := -off
	while bx < W:
		if bx >= 0.0:
			draw_line(Vector2(bx, 0), Vector2(bx, H), C_GRID, 1.0)
		bx += beat

	# Border
	draw_line(Vector2(0, 0), Vector2(W, 0), C_CURSOR.darkened(0.4), 1.2)
	draw_line(Vector2(0, H - 1), Vector2(W, H - 1), C_CURSOR.darkened(0.4), 1.2)

	for i in _sheet.size():
		var sx := _screen_x(i)
		if sx + NOTE_W < -NOTE_W: continue
		if sx > W + NOTE_W: break

		var name : String = _sheet[i]
		var is_cur  := (i == _note_idx)
		var is_done := (i < _note_idx)
		var is_next := (i == _note_idx + 1)

		# Get vertical lane position for this note
		var clean_name := name.replace("1","").replace("2","").replace("3","").replace("4","").strip_edges()
		var lane_idx := NOTES_PITCHES.find(clean_name)
		if lane_idx == -1: lane_idx = 0
		var py := H - (lane_idx + 1) * lane_h

		var col : Color
		# Scale size based on lane space
		var pw := 52.0
		var ph := 24.0
		if is_cur:
			col = C_ACT
			ph = 28.0 + sin(_pulse) * 2.0
			pw = 58.0 + sin(_pulse) * 2.0
		elif is_done: col = C_DONE
		elif is_next: col = C_NEXT
		else:         col = C_IDLE

		var pnr := ph * 0.5
		var rect := Rect2(sx + (NOTE_W - pw) * 0.5, py - pnr, pw, ph)

		if is_cur:
			var gc := Color(col.r, col.g, col.b, 0.15 + sin(_pulse) * 0.05)
			draw_rect(Rect2(rect.position - Vector2(8, 8), rect.size + Vector2(16, 16)), gc)
			draw_rect(Rect2(rect.position - Vector2(4, 4),  rect.size + Vector2(8, 8)), Color(gc.r, gc.g, gc.b, gc.a * 1.8))

		_pill(rect, 8.0, col)
		var border := C_CURSOR if is_cur else Color(0, 0, 0, 0.30)
		_pill_outline(rect, 8.0, border, 1.4)

		if font:
			var fs := 12 if is_cur else 10
			var ts := font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
			var tc := C_TEXT if (is_cur or is_next) else Color(1.0, 1.0, 1.0, 0.50)
			draw_string(font, Vector2(rect.position.x + (pw - ts.x) * 0.5, py + ts.y * 0.38),
				name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, tc)

		if is_done and font:
			draw_string(font, Vector2(rect.end.x - 14, py - 4),
				"✓", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.55, 1.0, 0.65, 0.9))

	# ── Timing cursor ──────────────────────────────────────────────────────
	var cx2 := W * CURSOR_FRAC
	draw_rect(Rect2(cx2 - 10, 0, 20, H), Color(C_CURSOR.r, C_CURSOR.g, C_CURSOR.b, 0.07))
	draw_rect(Rect2(cx2 - 3,  0,  6, H), Color(C_CURSOR.r, C_CURSOR.g, C_CURSOR.b, 0.20))
	draw_line(Vector2(cx2, 1), Vector2(cx2, H - 1), C_CURSOR, 2.5)
	var tip := 6.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx2, 1), Vector2(cx2 + tip, 1 + tip),
		Vector2(cx2, 1 + tip * 2), Vector2(cx2 - tip, 1 + tip)
	]), C_CURSOR)
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx2, H - 1), Vector2(cx2 + tip, H - 1 - tip),
		Vector2(cx2, H - 1 - tip * 2), Vector2(cx2 - tip, H - 1 - tip)
	]), C_CURSOR)

# ── Rounded rect helpers ───────────────────────────────────────────────────
func _pill(rect: Rect2, radius: float, col: Color) -> void:
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var pts := PackedVector2Array()
	var segs := 5
	var corners := [
		Vector2(rect.position.x + r, rect.position.y + r),
		Vector2(rect.end.x - r,       rect.position.y + r),
		Vector2(rect.end.x - r,       rect.end.y - r),
		Vector2(rect.position.x + r,  rect.end.y - r),
	]
	var starts: Array[float] = [PI, PI * 1.5, 0.0, PI * 0.5]
	for ci in 4:
		for s in segs + 1:
			var ang: float = starts[ci] + float(s) * (PI * 0.5) / float(segs)
			pts.append(corners[ci] + Vector2(cos(ang), sin(ang)) * r)
	draw_colored_polygon(pts, col)

func _pill_outline(rect: Rect2, radius: float, col: Color, w: float) -> void:
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var pts := PackedVector2Array()
	var segs := 5
	var corners := [
		Vector2(rect.position.x + r, rect.position.y + r),
		Vector2(rect.end.x - r,       rect.position.y + r),
		Vector2(rect.end.x - r,       rect.end.y - r),
		Vector2(rect.position.x + r,  rect.end.y - r),
	]
	var starts: Array[float] = [PI, PI * 1.5, 0.0, PI * 0.5]
	for ci in 4:
		for s in segs + 1:
			var ang: float = starts[ci] + float(s) * (PI * 0.5) / float(segs)
			pts.append(corners[ci] + Vector2(cos(ang), sin(ang)) * r)
	draw_polyline(pts, col, w, true)
