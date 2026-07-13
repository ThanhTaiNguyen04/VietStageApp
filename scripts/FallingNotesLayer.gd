extends Control

signal note_hit(lane: int)

# ── Palette ────────────────────────────────────────────────────────────────
const C_JADE       := Color("#0e3d26") # Deep Forest Green
const C_GOLD       := Color("#d4af37") # Metallic gold
const C_GOLD_GLOW  := Color(0.83, 0.68, 0.22, 0.4) # Transparent gold glow
const C_TEXT       := Color("#faf6eb") # Cream text

# ── Parameters ─────────────────────────────────────────────────────────────
const TRAVEL_TIME := 2.5 # Giây từ lúc xuất hiện đến lúc chạm dây
const NOTE_W      := 48.0
const NOTE_H      := 24.0

var _board: Control
var _song_player: SongPlayer
var _hit_notes: Dictionary = {} # Quản lý các nốt đã hit để khỏi hit lại

func _ready() -> void:
	# Cố gắng tìm DanBauBoard và SongPlayer
	_board = get_node_or_null("../../../StringsBoard/BoardM/BoardHBox/BoardVBox/DanBauBoard")
	_song_player = get_node_or_null("../SongPlayer")
	
	mouse_filter = MOUSE_FILTER_IGNORE
	z_index = 10
	resized.connect(queue_redraw)

func _process(_delta: float) -> void:
	if not _song_player or not _board:
		return
	queue_redraw()
	
	if _song_player.demo_active:
		var ct = _song_player.current_song_time
		
		# Quét qua các nốt để kiểm tra hit
		for i in _song_player.notes.size():
			if _hit_notes.has(i): continue
			
			var n = _song_player.notes[i]
			if ct >= n.hit_time:
				_hit_notes[i] = true
				note_hit.emit(n.lane)

func reset_hits() -> void:
	_hit_notes.clear()

func _draw() -> void:
	if not _song_player or not _board or _board._node_xs.size() == 0:
		return
		
	var W := size.x; var H := size.y
	if W < 10.0 or H < 10.0: return
	
	var ct = _song_player.current_song_time
	
	# Target Y
	var target_global_y = _board.global_position.y + _board._str_y
	var target_local_y = target_global_y - global_position.y
	
	var font = get_theme_font("font")
	var lane_names = ["Đố", "Sol", "Mi", "Đô", "Sol", "Đồ"]
	
	# Draw elegant lane threads (golden silk threads)
	for i in 6:
		if i >= _board._node_xs.size(): break
		var lx = (_board.global_position.x + _board._node_xs[i]) - global_position.x
		draw_line(Vector2(lx, 0), Vector2(lx, target_local_y), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.15), 1.0)
		
		if font:
			var fs = 13
			var ts = font.get_string_size(lane_names[i], HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
			draw_string(font, Vector2(lx - ts.x * 0.5, 30), lane_names[i], HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.4))

	# Draw falling notes (Jade & Gold amulets)
	for i in _song_player.notes.size():
		var n = _song_player.notes[i]
		var time_until_hit = n.hit_time - ct
		if time_until_hit < -0.5 or time_until_hit > TRAVEL_TIME: continue
		
		var lx = (_board.global_position.x + _board._node_xs[n.lane]) - global_position.x
		var t_progress = 1.0 - (time_until_hit / TRAVEL_TIME)
		var spawn_y = -NOTE_H
		var current_y = lerpf(spawn_y, target_local_y, t_progress)
		
		var is_active = time_until_hit > 0.0
		var alpha = 1.0 if is_active else maxf(0.0, 1.0 - (-time_until_hit)*2.0)
		
		var nw = 36.0 # Width of diamond
		var nh = 46.0 # Height of diamond
		
		if is_active:
			# Golden silk thread tail
			var tail_y = current_y - nh * 0.5
			var tail_len = 150.0 * (1.0 - t_progress)
			var tail_a = 0.4 * alpha
			draw_line(Vector2(lx, tail_y), Vector2(lx, tail_y - tail_len), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, tail_a), 1.5)
			
			# Glow halo
			draw_circle(Vector2(lx, current_y), nw * 0.9, Color(C_GOLD_GLOW.r, C_GOLD_GLOW.g, C_GOLD_GLOW.b, 0.5 * alpha))
		
		# Draw Diamond (Ngọc Bội)
		var diamond_pts = PackedVector2Array([
			Vector2(lx, current_y - nh*0.5),
			Vector2(lx + nw*0.5, current_y),
			Vector2(lx, current_y + nh*0.5),
			Vector2(lx - nw*0.5, current_y)
		])
		
		# Jade Fill
		var fill_col = C_JADE if is_active else Color(0.8, 0.8, 0.8)
		draw_colored_polygon(diamond_pts, Color(fill_col.r, fill_col.g, fill_col.b, alpha))
		
		# Gold Border
		var border_col = C_GOLD if is_active else Color(0.5, 0.5, 0.5)
		diamond_pts.append(diamond_pts[0]) # close path
		draw_polyline(diamond_pts, Color(border_col.r, border_col.g, border_col.b, alpha), 2.0, true)
		
		# Inner Gold Decoration (small diamond)
		var inner_nw = nw * 0.7
		var inner_nh = nh * 0.7
		var inner_pts = PackedVector2Array([
			Vector2(lx, current_y - inner_nh*0.5),
			Vector2(lx + inner_nw*0.5, current_y),
			Vector2(lx, current_y + inner_nh*0.5),
			Vector2(lx - inner_nw*0.5, current_y),
			Vector2(lx, current_y - inner_nh*0.5)
		])
		draw_polyline(inner_pts, Color(border_col.r, border_col.g, border_col.b, alpha * 0.4), 1.0, true)
		
		if font:
			var fs = 13
			var name = lane_names[n.lane]
			var ts = font.get_string_size(name, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
			draw_string(font, Vector2(lx - ts.x * 0.5, current_y + fs*0.35), name, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color(C_TEXT.r, C_TEXT.g, C_TEXT.b, alpha))
