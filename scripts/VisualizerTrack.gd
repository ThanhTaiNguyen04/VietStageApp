extends Control
class_name VisualizerTrack

var practice_scene: Control
var column_offsets := [-102, -56.5, -13.5, 31.5, 75.5, 124.5]
var scroll_speed := 150.0 # pixels per second
var receptor_y := 0.0
const RECEPTOR_RING_RADIUS := 33.0
const NOTE_STOP_GAP := 4.0

# Realtime feedback - visual hold progress
var _visual_hold_progress := 0.0   # 0.0 -> 1.0: how far through the note
var _glow_pulse := 0.0             # oscillates for pulsing glow effect
const C_CORRECT   := Color(0.22, 0.85, 0.42, 1.0)   # emerald green
const C_WRONG     := Color(0.95, 0.35, 0.18, 1.0)   # orange-red
const C_NEUTRAL   := Color(0.85, 0.65, 0.13, 0.8)   # gold
const C_WAIT_BREATH := Color(0.20, 0.70, 0.95, 1.0) # sky blue for articulation wait

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	_glow_pulse += delta * 4.0  # Speed of pulsing
	if _glow_pulse > TAU:
		_glow_pulse -= TAU
		
	if practice_scene:
		var ps = practice_scene
		var is_correct = ps._active_note_is_correct
		var is_heard   = ps._active_note_is_heard
		var is_waiting = ps._waiting_for_breath_release
		
		if is_waiting:
			# Hold at 100%, waiting for breath cut
			_visual_hold_progress = 1.0
		elif is_correct:
			# Advance progress as user blows correctly
			var note_dur = ps.sheet_durations[ps._note_idx] * (60.0 / ps._song_bpm) if ps.sheet_notes.size() > 0 else 1.0
			var req = max(0.3, note_dur * 0.5)
			_visual_hold_progress = clamp(ps._correct_pitch_hold_time / req, 0.0, 1.0)
		elif is_heard and not is_correct:
			# Wrong note: retreat
			_visual_hold_progress = max(0.0, _visual_hold_progress - delta * 1.5)
		else:
			# Silence: slowly fade progress out
			_visual_hold_progress = max(0.0, _visual_hold_progress - delta * 0.8)
			
	queue_redraw()

func _draw() -> void:
	if not practice_scene or practice_scene.sheet_notes.size() == 0:
		return
		
	var w = size.x
	var h = size.y
	receptor_y = h - 96 # Vị trí vòng tròn nhận nốt (receptor) - tăng số trừ để dịch lên trên, giảm để dịch xuống dưới
	
	# Calculate column X coordinates matching the flute holes below
	var center_x = w / 2.0
	var column_x : Array[float] = []
	for offset in column_offsets:
		column_x.append(center_x + offset * (w / 1369.0) * 1.8)
		
	# 1. Draw 6 semi-transparent lane backgrounds and vertical lines
	for cx in column_x:
		# Lane background
		draw_rect(Rect2(cx - 20, 0, 40, receptor_y), Color(0.92, 0.88, 0.82, 0.15))
		# Left border of the lane
		draw_line(Vector2(cx - 20, 0), Vector2(cx - 20, receptor_y), Color(0.85, 0.65, 0.13, 0.1), 1.0)
		# Right border of the lane
		draw_line(Vector2(cx + 20, 0), Vector2(cx + 20, receptor_y), Color(0.85, 0.65, 0.13, 0.1), 1.0)
		# Center guideline
		draw_line(Vector2(cx, 0), Vector2(cx, receptor_y), Color(0.85, 0.65, 0.13, 0.22), 1.5)
		
	# 2. Draw target receptors showing current note fingering guide
	var current_note_idx = practice_scene._note_idx
	var current_note = practice_scene.sheet_notes[current_note_idx]
	var current_fingering = practice_scene.FINGERINGS.get(current_note, [false, false, false, false, false, false])
	
	# Get user's current covered states for real-time finger feedback
	var user_covered = practice_scene._covered_states
	
	var is_correct  = practice_scene._active_note_is_correct
	var is_heard    = practice_scene._active_note_is_heard
	var is_waiting  = practice_scene._waiting_for_breath_release
	
	# Receptor glow color based on state
	var pulse_alpha = 0.5 + 0.5 * sin(_glow_pulse)
	var receptor_ring_color := C_NEUTRAL
	if is_waiting:
		receptor_ring_color = Color(C_WAIT_BREATH.r, C_WAIT_BREATH.g, C_WAIT_BREATH.b, 0.5 + 0.5 * pulse_alpha)
	elif is_correct:
		receptor_ring_color = Color(C_CORRECT.r, C_CORRECT.g, C_CORRECT.b, 0.5 + 0.5 * pulse_alpha)
	elif is_heard:
		receptor_ring_color = Color(C_WRONG.r, C_WRONG.g, C_WRONG.b, 0.6)
	
	for i in range(6):
		var cx = column_x[i]
		
		# Outer glow ring when correct
		if is_correct or is_waiting:
			draw_circle(Vector2(cx, receptor_y), 40, Color(receptor_ring_color.r, receptor_ring_color.g, receptor_ring_color.b, 0.18 * pulse_alpha))
		
		# Outer target ring (Vòng tròn viền ngoài)
		draw_circle(Vector2(cx, receptor_y), 33, receptor_ring_color)
		draw_circle(Vector2(cx, receptor_y), 22, Color.WHITE)
		
		# Target hole state (covered = dark orange/gold fill, open = light transparent)
		if current_fingering[i]:
			draw_circle(Vector2(cx, receptor_y), 18, Color(0.85, 0.65, 0.13, 0.8))
		else:
			draw_circle(Vector2(cx, receptor_y), 18, Color(0.85, 0.65, 0.13, 0.15))
			
		# Draw user's active finger feedback (a solid dark circle in the middle if they cover it)
		if i < user_covered.size() and user_covered[i]:
			draw_circle(Vector2(cx, receptor_y), 12, Color(0.18, 0.12, 0.08, 0.9))
			
	# 3. Draw falling note blocks
	# When user is playing correctly, freeze the track so the active block stays at receptor
	# Use visual offset to simulate the block "held" at receptor when progress>0
	var elapsed : float = practice_scene._current_note_elapsed
	var bpm : float = practice_scene._song_bpm
	
	# Time offset starts from current elapsed time
	var time_offset : float = -elapsed
	
	# Display next 5 notes
	var draw_limit = min(current_note_idx + 5, practice_scene.sheet_notes.size())
	for k in range(current_note_idx, draw_limit):
		var note_name = practice_scene.sheet_notes[k]
		var duration_beats = practice_scene.sheet_durations[k]
		var duration_seconds = duration_beats * (60.0 / bpm)
		
		var t_start = time_offset
		var t_end = t_start + duration_seconds
		time_offset += duration_seconds
		
		# Vertical positions: t_start = 0 stops at the top edge of the hole ring.
		# The falling note body must not run through the circular flute holes.
		var note_stop_y = receptor_y - RECEPTOR_RING_RADIUS - NOTE_STOP_GAP
		var y_bottom = note_stop_y - t_start * scroll_speed
		var y_top = note_stop_y - t_end * scroll_speed
		
		if y_bottom < 0:
			continue
		if y_top > h:
			continue
			
		# Tạo khoảng cách trống (gap) 12px giữa các nốt liên tiếp để gợi ý cắt hơi
		var y_draw_top = max(0.0, y_top + 10)
		var y_draw_bottom = min(note_stop_y, y_bottom - 2)
		var draw_height = y_draw_bottom - y_draw_top
		
		if draw_height <= 0:
			continue
			
		# Fingering for this note block
		var note_fingering = practice_scene.FINGERINGS.get(note_name, [false, false, false, false, false, false])
		
		# Rule: Nốt Si (không bấm lỗ nào) -> Vẽ một thanh ngang màu xanh ngọc (Teal/Cyan) phủ cả 6 làn chạy xuống
		var is_si = note_name.begins_with("Si")
		
		if is_si:
			var left_x = column_x[0] - 20
			var right_x = column_x[5] + 20
			var bar_width = right_x - left_x
			var block_rect := Rect2(left_x, y_draw_top, bar_width, draw_height)
			
			# Màu nốt Si: xanh ngọc mặc định, đổi theo trạng thái thổi
			var block_color := Color(0.16, 0.55, 0.72, 0.8)
			if k == current_note_idx and elapsed >= 0.0:
				if is_waiting:
					block_color = Color(C_WAIT_BREATH.r, C_WAIT_BREATH.g, C_WAIT_BREATH.b, 0.9)
				elif is_correct:
					block_color = Color(C_CORRECT.r, C_CORRECT.g, C_CORRECT.b, 0.9)
				elif is_heard:
					block_color = Color(C_WRONG.r, C_WRONG.g, C_WRONG.b, 0.75)
				
			draw_rect(block_rect, block_color)
			
			# Thanh tiến độ hold progress cho nốt Si
			if k == current_note_idx and _visual_hold_progress > 0.0 and elapsed >= 0.0:
				var prog_height = draw_height * _visual_hold_progress
				var prog_top    = y_draw_bottom - prog_height
				var prog_rect   = Rect2(left_x, prog_top, bar_width, prog_height)
				draw_rect(prog_rect, Color(1, 1, 1, 0.3 + 0.2 * sin(_glow_pulse)))
				if _visual_hold_progress < 1.0:
					draw_line(Vector2(left_x, prog_top), Vector2(right_x, prog_top), Color(1, 1, 1, 0.8 * pulse_alpha), 2.5)
			
			# Vẽ các chấm tròn cách điệu màu trắng ở giữa thanh nốt Si
			if y_bottom >= y_draw_top and y_bottom <= h:
				var cx_center = (left_x + right_x) / 2.0
				draw_circle(Vector2(cx_center, y_bottom), 10, Color(1, 1, 1, 0.6))
		else:
			# Các nốt thường (Đô, Rê, Mi, Fa, Sol, La): Vẽ các khối nốt rơi xuống trên làn tương ứng
			for i in range(6):
				if note_fingering[i]:
					var cx = column_x[i]
					var block_rect := Rect2(cx - 15, y_draw_top, 30, draw_height)
					
								# Màu block: vàng mặc định, xanh khi đúng, đỏ khi sai
					var block_color := C_NEUTRAL
					if k == current_note_idx and elapsed >= 0.0:
						if is_waiting:
							block_color = Color(C_WAIT_BREATH.r, C_WAIT_BREATH.g, C_WAIT_BREATH.b, 0.9)
						elif is_correct:
							block_color = Color(C_CORRECT.r, C_CORRECT.g, C_CORRECT.b, 0.9)
						elif is_heard:
							block_color = Color(C_WRONG.r, C_WRONG.g, C_WRONG.b, 0.75)
						
					draw_rect(block_rect, block_color)
					
					# Vẽ thanh tiến độ hold progress sáng chạy lên bên trong khối nốt hiện tại
					if k == current_note_idx and _visual_hold_progress > 0.0 and elapsed >= 0.0:
						var prog_height = draw_height * _visual_hold_progress
						var prog_top    = y_draw_bottom - prog_height
						var prog_rect   = Rect2(cx - 15, prog_top, 30, prog_height)
						var prog_color  = Color(1, 1, 1, 0.38 + 0.25 * sin(_glow_pulse))
						draw_rect(prog_rect, prog_color)
						# Bright leading edge line
						if _visual_hold_progress < 1.0:
							draw_line(Vector2(cx - 15, prog_top), Vector2(cx + 15, prog_top), Color(1, 1, 1, 0.8 * pulse_alpha), 2.0)
					
					# Vẽ đầu nốt tròn cách điệu màu trắng
					if y_bottom >= y_draw_top and y_bottom <= h:
						draw_circle(Vector2(cx, y_bottom), 8, Color(1, 1, 1, 0.5))
