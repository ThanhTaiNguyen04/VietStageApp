extends Control
class_name TrongChauFallingNotesLayer

signal note_hit(note: Dictionary)

const TRAVEL_TIME := 2.0
const HIT_Y_OFFSET := 40.0

var _song_player = null
var _hit_notes := {}

var _left_x := 0.0
var _right_x := 0.0

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	if not _song_player:
		return
	queue_redraw()
	
	if _song_player.demo_active or _song_player._is_playing:
		var ct = _song_player.current_song_time
		if not _song_player.notes: return
		
		for i in _song_player.notes.size():
			if _hit_notes.has(i): continue
			
			var n = _song_player.notes[i]
			var ht = n.get("hit_time", 0.0)
			if ct >= ht:
				_hit_notes[i] = true
				note_hit.emit(n)

func _draw() -> void:
	var rect = get_rect()
	var w = rect.size.x
	var h = rect.size.y
	_left_x = w * 0.5 - 90.0  # Center-left for blue lane
	_right_x = w * 0.5 + 90.0 # Center-right for orange lane
	var hit_y = h - HIT_Y_OFFSET
	
	# Draw Lanes (Glow effect)
	var lane_width = 70.0
	draw_rect(Rect2(_left_x - lane_width/2, 0, lane_width, hit_y), Color(0.1, 0.4, 1.0, 0.15))
	draw_line(Vector2(_left_x, 0), Vector2(_left_x, hit_y), Color(0.4, 0.8, 1.0, 0.5), 6.0)
	
	draw_rect(Rect2(_right_x - lane_width/2, 0, lane_width, hit_y), Color(1.0, 0.4, 0.1, 0.15))
	draw_line(Vector2(_right_x, 0), Vector2(_right_x, hit_y), Color(1.0, 0.8, 0.4, 0.5), 6.0)
	
	# Draw hit zones
	draw_circle(Vector2(_left_x, hit_y), lane_width/2, Color(0.2, 0.6, 1.0, 0.5))
	draw_circle(Vector2(_left_x, hit_y), lane_width/2 - 10, Color(0.2, 0.6, 1.0, 0.8))
	draw_arc(Vector2(_left_x, hit_y), lane_width/2 + 10, 0, TAU, 32, Color(0.4, 0.8, 1.0, 0.8), 3.0)
	
	draw_circle(Vector2(_right_x, hit_y), lane_width/2, Color(1.0, 0.5, 0.2, 0.5))
	draw_circle(Vector2(_right_x, hit_y), lane_width/2 - 10, Color(1.0, 0.5, 0.2, 0.8))
	draw_arc(Vector2(_right_x, hit_y), lane_width/2 + 10, 0, TAU, 32, Color(1.0, 0.7, 0.4, 0.8), 3.0)
	
	# Draw judgment line
	draw_line(Vector2(_left_x - 120, hit_y), Vector2(_right_x + 120, hit_y), Color(1, 1, 1, 0.6), 2.0)
	
	if not _song_player:
		return
		
	var ct = _song_player.current_song_time
	
	for i in _song_player.notes.size():
		if _hit_notes.has(i): continue
		
		var n = _song_player.notes[i]
		var ht = n.get("hit_time", 0.0)
		var t_until = ht - ct
		
		if t_until < -0.2 or t_until > TRAVEL_TIME: continue
		
		var ny = hit_y - (t_until / TRAVEL_TIME) * hit_y
		var nx = _left_x if n.get("lane", 0) == 0 else _right_x
		
		var c_inner = Color(0.6, 0.9, 1.0) if n.get("lane", 0) == 0 else Color(1.0, 0.9, 0.6)
		var c_outer = Color(0.2, 0.6, 1.0) if n.get("lane", 0) == 0 else Color(1.0, 0.5, 0.2)
		
		draw_circle(Vector2(nx, ny), 22.0, c_outer)
		draw_circle(Vector2(nx, ny), 12.0, c_inner)

func reset_hits() -> void:
	_hit_notes.clear()
