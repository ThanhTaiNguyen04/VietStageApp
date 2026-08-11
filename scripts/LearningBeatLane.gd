extends Control

var beat_times: Array[float] = []
var judgements: Array[String] = []
var current_time := 0.0
var duration := 1.0
var active := false

func configure(times: Array[float], total_duration: float) -> void:
	beat_times = times
	duration = maxf(1.0, total_duration)
	judgements.clear()
	for _time in beat_times:
		judgements.append("")
	queue_redraw()

func _ready() -> void:
	custom_minimum_size = Vector2(0, 150)
	queue_redraw()

func _draw() -> void:
	var width := maxf(size.x, 280.0)
	var lane := Rect2(28, 48, width - 56, 42)
	draw_style_box(_lane_style(), lane)
	for i in beat_times.size():
		var x := lane.position.x + clampf(beat_times[i] / duration, 0.0, 1.0) * lane.size.x
		var state := judgements[i] if i < judgements.size() else ""
		var color := Color("#e7ae22")
		if state == "PERFECT": color = Color("#239653")
		elif state == "GOOD": color = Color("#2d76df")
		elif state == "MISS": color = Color("#e04a43")
		draw_circle(Vector2(x, lane.position.y + lane.size.y * 0.5), 15.0, Color(color.r, color.g, color.b, 0.18))
		draw_circle(Vector2(x, lane.position.y + lane.size.y * 0.5), 7.0, color)
		if not state.is_empty():
			draw_string(ThemeDB.fallback_font, Vector2(x - 30, 30), state, HORIZONTAL_ALIGNMENT_CENTER, 60, 12, color)
	if active:
		var play_x := lane.position.x + clampf(current_time / duration, 0.0, 1.0) * lane.size.x
		draw_line(Vector2(play_x, 24), Vector2(play_x, 112), Color("#172f75"), 4.0, true)
		draw_circle(Vector2(play_x, lane.position.y + lane.size.y * 0.5), 10.0, Color("#172f75"))

func _lane_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#eef2f8")
	style.border_color = Color("#d7deeb")
	style.set_border_width_all(2)
	style.set_corner_radius_all(21)
	return style
