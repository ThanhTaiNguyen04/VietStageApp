extends Control

# Colors (synchronized with CourseMap)
const C_RED_SON     := Color(0.72, 0.12, 0.08, 1.0)
const C_RED_SON_DK  := Color(0.38, 0.06, 0.04, 0.95)
const C_GOLD        := Color(0.95, 0.72, 0.18, 1.0)
const C_GOLD_LIGHT  := Color(1.00, 0.87, 0.45, 1.0)
const C_JADE        := Color(0.18, 0.62, 0.42, 1.0)
const C_JADE_LIGHT  := Color(0.35, 0.85, 0.60, 1.0)
const C_CREAM       := Color(1.00, 0.97, 0.88, 1.0)

@onready var map_hbox : HBoxContainer = $"../MapHBox"

# Traditional Vietnamese-themed background drawings that scroll!
var _sparkles = [
	Vector2(140, 110), Vector2(250, 480), Vector2(480, 140),
	Vector2(620, 460), Vector2(780, 110), Vector2(940, 470),
	Vector2(1080, 150), Vector2(1250, 460), Vector2(1410, 120),
	Vector2(1580, 480)
]

var _clouds = [
	Vector2(320, 160), Vector2(720, 440), Vector2(1180, 180), Vector2(1500, 420)
]

func _ready() -> void:
	# Hide the static PathLine ColorRect
	if has_node("PathLine"):
		get_node("PathLine").visible = false
	
	# Redraw on size changes or process
	item_rect_changed.connect(queue_redraw)

func _process(_delta: float) -> void:
	# Redraw to catch layout changes during Godot container sorting
	queue_redraw()

func _draw() -> void:
	if not map_hbox: return
	
	# 1. Draw beautiful traditional background clouds and sparkles first (so they are under the path line)
	for cloud_pos in _clouds:
		_draw_cloud(cloud_pos, 90.0)
		
	for sparkle_pos in _sparkles:
		_draw_sparkle(sparkle_pos, 12.0)
	
	# Get the nodes
	var nodes := []
	for i in range(1, 6):
		var n = map_hbox.get_node_or_null("Node" + str(i))
		if n and is_instance_valid(n):
			nodes.append(n)
	
	if nodes.size() < 2: return
	
	# 2. Draw segments
	for i in range(nodes.size() - 1):
		var n_curr = nodes[i]
		var n_next = nodes[i+1]
		
		# Compute centers relative to HBox container, which is identical to PathLineContainer coordinate space
		var p_curr = n_curr.position + n_curr.size / 2.0
		var p_next = n_next.position + n_next.size / 2.0
		
		# Bezier control points for a gorgeous smooth winding S-curve
		var ctrl1 := Vector2(p_curr.x + (p_next.x - p_curr.x) * 0.5, p_curr.y)
		var ctrl2 := Vector2(p_curr.x + (p_next.x - p_curr.x) * 0.5, p_next.y)
		
		var points := _get_bezier_points(p_curr, ctrl1, ctrl2, p_next, 28)
		
		# Determine segment colors based on progress state
		var is_completed := false
		var is_active := false
		
		if i == 0:
			# Node 1 to Node 2 segment
			if CourseMap.video_completed:
				is_completed = true
			else:
				is_active = true
		else:
			# Subsequent segments are locked in this demo
			pass
			
		var color_outline : Color
		var color_fill : Color
		var color_highlight : Color
		
		if is_completed:
			color_outline = C_JADE_LIGHT
			color_fill = C_JADE
			color_highlight = C_CREAM
		elif is_active:
			color_outline = C_GOLD_LIGHT
			color_fill = C_GOLD
			color_highlight = C_CREAM
		else:
			color_outline = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45)
			color_fill = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.28)
			color_highlight = Color(C_GOLD_LIGHT.r, C_GOLD_LIGHT.g, C_GOLD_LIGHT.b, 0.2)
		
		# Draw Shadow (3D offset bottom)
		draw_polyline(_offset_points(points, Vector2(0, 6)), Color(0.04, 0.02, 0.01, 0.45), 20.0, true)
		
		# Draw Outer Outline
		draw_polyline(points, color_outline, 18.0, true)
		
		# Draw Main Path Fill
		draw_polyline(points, color_fill, 12.0, true)
		
		# Draw Inner Glossy Highlight
		draw_polyline(_offset_points(points, Vector2(0, -2)), color_highlight, 4.0, true)

func _offset_points(pts_in: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var pts_out := PackedVector2Array()
	for p in pts_in:
		pts_out.append(p + offset)
	return pts_out

func _get_bezier_points(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, steps: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var q0 := p0.lerp(p1, t)
		var q1 := p1.lerp(p2, t)
		var q2 := p2.lerp(p3, t)
		var r0 := q0.lerp(q1, t)
		var r1 := q1.lerp(q2, t)
		var p := r0.lerp(r1, t)
		pts.append(p)
	return pts

func _draw_sparkle(cntr: Vector2, size_sparkle: float) -> void:
	# Beautiful gold sparkle polygon
	var points := PackedVector2Array([
		cntr + Vector2(0, -size_sparkle),
		cntr + Vector2(size_sparkle * 0.25, -size_sparkle * 0.25),
		cntr + Vector2(size_sparkle, 0),
		cntr + Vector2(size_sparkle * 0.25, size_sparkle * 0.25),
		cntr + Vector2(0, size_sparkle),
		cntr + Vector2(-size_sparkle * 0.25, size_sparkle * 0.25),
		cntr + Vector2(-size_sparkle, 0),
		cntr + Vector2(-size_sparkle * 0.25, -size_sparkle * 0.25),
	])
	draw_colored_polygon(points, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.38))
	
	var inner_points := PackedVector2Array([
		cntr + Vector2(0, -size_sparkle * 0.5),
		cntr + Vector2(size_sparkle * 0.12, -size_sparkle * 0.12),
		cntr + Vector2(size_sparkle * 0.5, 0),
		cntr + Vector2(size_sparkle * 0.12, size_sparkle * 0.12),
		cntr + Vector2(0, size_sparkle * 0.5),
		cntr + Vector2(-size_sparkle * 0.12, size_sparkle * 0.12),
		cntr + Vector2(-size_sparkle * 0.5, 0),
		cntr + Vector2(-size_sparkle * 0.12, -size_sparkle * 0.12),
	])
	draw_colored_polygon(inner_points, Color(C_GOLD_LIGHT.r, C_GOLD_LIGHT.g, C_GOLD_LIGHT.b, 0.75))
 
func _draw_cloud(cntr: Vector2, w: float) -> void:
	var cloud_color := Color(C_CREAM.r, C_CREAM.g, C_CREAM.b, 0.14)
	# Overlapping vector circles for a dreamy traditional cloud look
	draw_circle(cntr + Vector2(-w * 0.25, 0), w * 0.32, cloud_color)
	draw_circle(cntr + Vector2(w * 0.25, -w * 0.05), w * 0.28, cloud_color)
	draw_circle(cntr + Vector2(0, -w * 0.18), w * 0.42, cloud_color)
	
	var flat_base := PackedVector2Array([
		cntr + Vector2(-w * 0.5, 0),
		cntr + Vector2(w * 0.5, 0),
		cntr + Vector2(w * 0.4, w * 0.12),
		cntr + Vector2(-w * 0.4, w * 0.12),
	])
	draw_colored_polygon(flat_base, cloud_color)
