extends Control

const C_NAVY := Color("#172f75")
const C_GOLD := Color("#e7ae22")
const C_GREEN := Color("#239653")
const C_BLUE := Color("#2d76df")
const C_RED := Color("#e04a43")
const C_TRACK := Color("#eef2f8")
const C_BORDER := Color("#d7deeb")

var beat_times: Array[float] = []
var judgements: Array[String] = []
var current_time := 0.0
var duration := 1.0
var active := false


func configure(times: Array[float], total_duration: float) -> void:
	beat_times = times.duplicate()
	duration = maxf(1.0, total_duration)
	judgements.clear()
	for _time in beat_times:
		judgements.append("")
	active = true
	queue_redraw()


func update_progress(elapsed: float, states: Array[String]) -> void:
	current_time = clampf(elapsed, 0.0, duration)
	judgements = states.duplicate()
	active = elapsed <= duration
	queue_redraw()


func _ready() -> void:
	custom_minimum_size = Vector2(0, 184)
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var horizontal_margin := 30.0 if size.x >= 420.0 else 18.0
	var track_width := maxf(40.0, size.x - horizontal_margin * 2.0)
	var track_y := size.y * 0.53
	var track_height := 48.0
	var lane := Rect2(horizontal_margin, track_y - track_height * 0.5, track_width, track_height)

	draw_style_box(_lane_style(), lane)
	draw_string(ThemeDB.fallback_font, Vector2(horizontal_margin, 22), "BẮT NHỊP", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(C_NAVY.r, C_NAVY.g, C_NAVY.b, 0.62))
	draw_string(ThemeDB.fallback_font, Vector2(size.x - horizontal_margin - 90, 22), "VỀ ĐÍCH", HORIZONTAL_ALIGNMENT_RIGHT, 90, 12, Color(C_NAVY.r, C_NAVY.g, C_NAVY.b, 0.62))

	for index in beat_times.size():
		var x := lane.position.x + clampf(beat_times[index] / duration, 0.0, 1.0) * lane.size.x
		var state := judgements[index] if index < judgements.size() else ""
		var color := C_GOLD
		var symbol := str(index + 1)
		if state == "PERFECT":
			color = C_GREEN
			symbol = "✓"
		elif state == "GOOD":
			color = C_BLUE
			symbol = "✓"
		elif state == "MISS":
			color = C_RED
			symbol = "×"
		draw_circle(Vector2(x, track_y), 21.0, Color(color.r, color.g, color.b, 0.14))
		draw_circle(Vector2(x, track_y), 12.0, color)
		draw_string(ThemeDB.fallback_font, Vector2(x - 11, track_y + 5), symbol, HORIZONTAL_ALIGNMENT_CENTER, 22, 13, Color.WHITE)
		if not state.is_empty():
			draw_string(ThemeDB.fallback_font, Vector2(x - 36, track_y - 36), state, HORIZONTAL_ALIGNMENT_CENTER, 72, 12, color)

	if active:
		var progress := clampf(current_time / duration, 0.0, 1.0)
		var play_x := lane.position.x + progress * lane.size.x
		draw_line(Vector2(play_x, track_y - 54), Vector2(play_x, track_y + 54), Color(C_NAVY.r, C_NAVY.g, C_NAVY.b, 0.92), 4.0, true)
		draw_circle(Vector2(play_x, track_y), 16.0, Color(C_NAVY.r, C_NAVY.g, C_NAVY.b, 0.15))
		draw_circle(Vector2(play_x, track_y), 8.0, C_NAVY)
		draw_colored_polygon(PackedVector2Array([
			Vector2(play_x - 7, track_y - 58),
			Vector2(play_x + 7, track_y - 58),
			Vector2(play_x, track_y - 48),
		]), C_NAVY)

	var elapsed_text := "%.1f s" % current_time
	var duration_text := "%.1f s" % duration
	draw_string(ThemeDB.fallback_font, Vector2(horizontal_margin, size.y - 10), elapsed_text, HORIZONTAL_ALIGNMENT_LEFT, 70, 12, Color(C_NAVY.r, C_NAVY.g, C_NAVY.b, 0.55))
	draw_string(ThemeDB.fallback_font, Vector2(size.x - horizontal_margin - 70, size.y - 10), duration_text, HORIZONTAL_ALIGNMENT_RIGHT, 70, 12, Color(C_NAVY.r, C_NAVY.g, C_NAVY.b, 0.55))


func _lane_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = C_TRACK
	style.border_color = C_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(24)
	style.shadow_color = Color(0.09, 0.18, 0.45, 0.10)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 3)
	return style
