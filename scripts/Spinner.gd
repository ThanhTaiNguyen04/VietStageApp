extends Control
class_name Spinner

const C_GOLD := Color(0.77, 0.58, 0.15, 1.0)
var _time := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(40, 40)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	var center := size / 2.0
	var r := 16.0
	var dot_count := 8
	var base_angle := _time * 6.0
	for i in range(dot_count):
		var angle := base_angle + i * (TAU / dot_count)
		var dot_pos := center + Vector2(cos(angle), sin(angle)) * r
		var alpha := float(i + 1) / dot_count
		var col := Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, alpha)
		draw_circle(dot_pos, 3.5, col)
