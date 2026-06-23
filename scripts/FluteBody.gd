extends Control

# Colors for bamboo texture
const C_BAMBOO_LIGHT := Color(0.78, 0.55, 0.24, 1.0)
const C_BAMBOO_DARK  := Color(0.40, 0.23, 0.08, 1.0)
const C_BAMBOO_SHADOW := Color(0.22, 0.11, 0.03, 1.0)
const C_THREAD        := Color(0.08, 0.08, 0.08, 1.0)
const C_THREAD_GOLD   := Color(0.85, 0.68, 0.20, 1.0)

# Dummy color property to satisfy parent scene bindings if any
var color := Color.WHITE
var is_overblowing := false

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var w = size.x
	var h = size.y
	var cy = h / 2.0
	
	# Draw the background shadow
	draw_rect(Rect2(0, 0, w, h), C_BAMBOO_SHADOW)
	
	# Render horizontal cylindrical gradient lighting for 3D bamboo tube appearance
	var steps = 18
	for i in steps:
		var y1 = float(i) / steps * h
		var y2 = float(i + 1) / steps * h
		var ratio = float(i) / steps
		
		# Cylindrical gradient intensity curve
		var light = sin(ratio * PI)
		var col = C_BAMBOO_DARK.lerp(C_BAMBOO_LIGHT, light)
		
		# Glossy top reflection highlight
		if ratio > 0.15 and ratio < 0.25:
			col = col.lerp(Color.WHITE, 0.25)
		# Bottom shadow gradient
		if ratio > 0.8:
			col = col.lerp(C_BAMBOO_SHADOW, (ratio - 0.8) / 0.2 * 0.6)
			
		draw_rect(Rect2(0, y1, w, y2 - y1), col)
		
	# Draw segment nodes (bamboo nodes/creases)
	var node_positions = [0.22 * w, 0.58 * w, 0.88 * w]
	for pos_x in node_positions:
		# Dark node line
		draw_line(Vector2(pos_x, 0), Vector2(pos_x, h), Color(0.12, 0.06, 0.02, 0.85), 3.0)
		# Soft highlight line
		draw_line(Vector2(pos_x + 3.0, 0), Vector2(pos_x + 3.0, h), Color(1.0, 0.85, 0.60, 0.25), 2.0)
		
	# Draw decorative thread wraps
	var thread_zones = [
		0.05 * w,   # Left end
		0.20 * w,   # Node 1 thread
		0.56 * w,   # Node 2 thread
		0.86 * w,   # Node 3 thread
		0.95 * w    # Right end
	]
	for tx in thread_zones:
		var tw = 14.0 # Thread band width
		# Black thread wraps
		draw_rect(Rect2(tx - tw/2.0, 0, tw, h), C_THREAD)
		# Gold accent lines
		draw_rect(Rect2(tx - 2.0, 0, 4.0, h), C_THREAD_GOLD)
		
	# Draw embouchure hole (lỗ thổi) on the left side
	var blow_hole_x = 0.12 * w
	# Outer hole
	draw_ellipse_angle(Vector2(blow_hole_x, cy), Vector2(12.0, 8.0), Color(0.12, 0.06, 0.02))
	# Inner shadow
	draw_ellipse_angle(Vector2(blow_hole_x + 1.0, cy + 1.0), Vector2(9.5, 6.0), Color(0.02, 0.02, 0.02))
	
	if is_overblowing:
		var pulse := (sin(Time.get_ticks_msec() * 0.015) + 1.0) * 0.5
		var glow_color := Color(0.95, 0.22, 0.08, 0.4 + pulse * 0.3)
		draw_arc(Vector2(blow_hole_x, cy), 16.0 + pulse * 3.0, 0.0, TAU, 24, glow_color, 2.0)

func draw_ellipse_angle(center: Vector2, radius: Vector2, color: Color) -> void:
	var points = PackedVector2Array()
	var steps = 24
	for i in range(steps + 1):
		var phi = float(i) / steps * TAU
		points.append(center + Vector2(cos(phi) * radius.x, sin(phi) * radius.y))
	draw_polygon(points, PackedColorArray([color]))
