extends "res://scripts/LearningMelodyStaffDisplay.gd"

## Staff renderer for RHYTHM_MATCH performance rounds.
## Draws treble clef, 5-line staff, note heads/stems, moving playhead, and per-note judgements.
var beat_times: Array[float] = []
var judgements: Array[String] = []
var current_time := 0.0
var duration := 1.0
var show_note_hints := true

const C_PERFECT := Color("#16a34a") # Emerald green for PERFECT / GOOD
const C_GOOD := Color("#16a34a")    # Emerald green
const C_MISS := Color("#dc2626")    # Rose / Red for WRONG_NOTE / MISS
const C_GOLD_ACTIVE := Color("#c59626") # Vibrant Gold for target/active note
const C_PLAYHEAD := Color("#0ea5e9") # Sky blue cursor


func configure_rhythm(note_values: Array, times: Array, total_duration: float, hints: bool = true) -> void:
	configure(note_values, -1)
	show_note_hints = hints
	beat_times.clear()
	for value: Variant in times:
		beat_times.append(float(value))
	judgements.clear()
	for _value in beat_times:
		judgements.append("")
	duration = maxf(1.0, total_duration)
	current_time = 0.0
	playback_index = 0 if not note_values.is_empty() else -1
	queue_redraw()


func update_progress(elapsed: float, states: Array) -> void:
	current_time = clampf(elapsed, 0.0, duration)
	judgements.clear()
	for state: Variant in states:
		judgements.append(str(state))
	playback_index = _active_index()
	queue_redraw()


func _active_index() -> int:
	for index in beat_times.size():
		if absf(current_time - beat_times[index]) <= 0.24:
			return index
		if current_time < beat_times[index]:
			return index
	return -1


func _draw() -> void:
	super._draw()
	if notes.is_empty():
		return

	var width := maxf(size.x, 300.0)
	var height := maxf(size.y, 190.0)
	var spacing := 20.0 if width < 420.0 else (22.0 if width < 600.0 else 24.0)
	var center_y := height * 0.44

	var left_margin := 20.0 if width < 420.0 else 26.0
	var right_margin := width - (20.0 if width < 420.0 else 26.0)
	var clef_scale := 6.2
	var clef_x := left_margin - 14.0
	var ts_x := clef_x + spacing * clef_scale * 0.65

	var start_note_x := ts_x + spacing * (1.8 if width < 420.0 else 2.2)
	var end_note_x := right_margin - (24.0 if width < 420.0 else 32.0)
	var total_note_slots := maxi(1, notes.size() - 1)
	var step_x := (end_note_x - start_note_x) / float(total_note_slots) if notes.size() > 1 else 0.0
	if notes.size() == 1:
		start_note_x = (start_note_x + end_note_x) * 0.5

	var font := bold_font if bold_font else ThemeDB.fallback_font
	var note_head_rx := spacing * 0.64
	var note_head_ry := spacing * 0.44
	var stem_length := spacing * 2.7
	var stem_width := 2.4

	# 1. Draw note solfege name below each note & redraw colored note heads/stems
	for i in range(notes.size()):
		var raw_note := notes[i]
		var note_x := start_note_x + step_x * float(i)
		var solfege := _to_vietnamese_solfege(raw_note)
		var state := judgements[i] if i < judgements.size() else ""
		var diatonic_step := _parse_diatonic_step(raw_note)
		var note_y := center_y - float(diatonic_step - 6) * (spacing * 0.5)

		# Determine note color based on judgement or active playhead
		var note_color := Color("#0f172a")
		var is_active := (i == playback_index and state.is_empty())
		if not state.is_empty():
			if state in ["PERFECT", "GOOD"]:
				note_color = C_PERFECT
			else:
				note_color = C_MISS
		elif is_active:
			note_color = C_GOLD_ACTIVE

		# If note is active or judged, redraw note head and stem with state color
		if not state.is_empty() or is_active:
			if is_active:
				# Glowing halo around the active note head
				_draw_rotated_ellipse(note_x, note_y, note_head_rx * 1.5, note_head_ry * 1.5, deg_to_rad(-18), Color(0.96, 0.68, 0.15, 0.28))
			_draw_rotated_ellipse(note_x, note_y, note_head_rx, note_head_ry, deg_to_rad(-18), note_color)
			var stem_up := diatonic_step < 6
			var stem_x := note_x + (note_head_rx * 0.85) if stem_up else note_x - (note_head_rx * 0.85)
			var stem_start_y := note_y
			var stem_end_y := note_y - stem_length if stem_up else note_y + stem_length
			draw_line(Vector2(stem_x, stem_start_y), Vector2(stem_x, stem_end_y), note_color, stem_width, true)

		# Draw Solfege Name Tag below the staff if hints enabled
		if show_note_hints:
			var tag_y := height - 24.0
			var tag_w := maxf(36.0, (font.get_string_size(solfege, HORIZONTAL_ALIGNMENT_CENTER, -1, 12).x + 12.0) if font else 36.0)
			var tag_color := Color("#475569")
			var tag_bg := Color(0.94, 0.96, 0.98, 0.92)
			
			if not state.is_empty():
				if state in ["PERFECT", "GOOD"]:
					tag_color = C_PERFECT
					tag_bg = Color(0.09, 0.64, 0.29, 0.15)
				else:
					tag_color = C_MISS
					tag_bg = Color(0.86, 0.15, 0.15, 0.15)
			elif is_active:
				tag_color = Color("#b45309")
				tag_bg = Color(0.96, 0.68, 0.15, 0.22)

			var tag_rect := Rect2(note_x - tag_w * 0.5, tag_y - 2, tag_w, 20)
			draw_rect(tag_rect, tag_bg, true)
			draw_rect(tag_rect, tag_color, false, 1.2)
			if font:
				draw_string(font, Vector2(note_x - tag_w * 0.5, tag_y + 13), solfege, HORIZONTAL_ALIGNMENT_CENTER, tag_w, 12, tag_color)

		# 2. Draw Judgement Badge Above the staff
		if not state.is_empty():
			var judge_y := 20.0
			var judge_color := C_PERFECT if state in ["PERFECT", "GOOD"] else C_MISS
			var judge_text := state
			if state == "WRONG_NOTE":
				judge_text = "SAI NỐT"
			var jw := maxf(50.0, (font.get_string_size(judge_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 10).x + 10.0) if font else 50.0)
			var jrect := Rect2(note_x - jw * 0.5, judge_y - 12, jw, 16)
			draw_rect(jrect, Color(judge_color.r, judge_color.g, judge_color.b, 0.18), true)
			draw_rect(jrect, judge_color, false, 1.2)
			if font:
				draw_string(font, Vector2(note_x - jw * 0.5, judge_y + 1), judge_text, HORIZONTAL_ALIGNMENT_CENTER, jw, 10, judge_color)

	# 3. Draw Moving Playhead cursor if within active duration
	if current_time > 0.0 and current_time <= duration and not beat_times.is_empty():
		var playhead_x := start_note_x
		var first_beat := beat_times[0]
		var last_beat := beat_times[-1]
		
		if last_beat > first_beat:
			var t_ratio := clampf((current_time - first_beat) / (last_beat - first_beat), 0.0, 1.0)
			playhead_x = start_note_x + (end_note_x - start_note_x) * t_ratio
		elif current_time >= first_beat:
			playhead_x = start_note_x

		var top_y := center_y - 2.8 * spacing
		var bot_y := center_y + 2.8 * spacing
		# Playhead vertical line with soft glow
		draw_line(Vector2(playhead_x, top_y), Vector2(playhead_x, bot_y), Color(C_PLAYHEAD.r, C_PLAYHEAD.g, C_PLAYHEAD.b, 0.35), 6.0, true)
		draw_line(Vector2(playhead_x, top_y), Vector2(playhead_x, bot_y), C_PLAYHEAD, 2.4, true)
		# Top & bottom diamond marker
		draw_circle(Vector2(playhead_x, top_y), 4.0, C_PLAYHEAD)
		draw_circle(Vector2(playhead_x, bot_y), 4.0, C_PLAYHEAD)


