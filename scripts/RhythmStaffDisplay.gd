extends "res://scripts/LearningMelodyStaffDisplay.gd"

## Enhanced Staff renderer for Mini-game 1 (Rhythm Challenge).
## Features:
## - 5-line staff with Treble Clef centered on Line 2 (G4 / Sol 4)
## - Configurable Time Signatures (2/4, 3/4, 4/4, 6/8)
## - Measure pagination (1 measure per page) with auto-flip on playhead crossing
## - Precise horizontal placement based on note start beats
## - Standard note shapes by duration (whole/half hollow, quarter/8th/16th solid, dots)
## - Standard beam grouping (3+3 in 6/8, quarter-beat groups in 2/4, 3/4, 4/4) and isolated flags
## - Minimalist UI: no bottom note tags, no top MISS badges, sleek playhead cursor

signal measure_changed(current_measure: int, total_measures: int)

var beat_times: Array[float] = []
var judgements: Array[String] = []
var current_time := 0.0
var duration := 1.0
var show_note_hints := false
var show_student_targets := false
var event_modes: Array[String] = []

var time_signature: Array = [4, 4]
var measure_beats: float = 4.0
var tempo_bpm: int = 80
var durations_beats: Array[float] = []
var note_start_beats: Array[float] = []

const MEASURES_PER_PAGE: int = 2
var current_measure: int = 0
var total_measures: int = 1
var current_page: int = 0
var total_pages: int = 1

# Touch/swipe interaction state
var _drag_start_x := -1.0
var _is_dragging := false

const C_PERFECT := Color("#16a34a") # Emerald green
const C_GOOD := Color("#16a34a")
const C_MISS := Color("#dc2626")    # Red
const C_DEMO_NOTE := Color("#334155") # Dark slate
const C_TARGET_NOTE := Color("#94a3b8") # Slate-400 (unplayed learner note)
const C_PLAYHEAD := Color("#0ea5e9") # Sky blue cursor
const C_STAFF_LINE := Color("#1e293b") # Slate-800


func _ready() -> void:
	super._ready()
	mouse_filter = MOUSE_FILTER_PASS


func configure_rhythm(
	note_values: Array,
	times: Array,
	total_duration: float,
	hints: bool = false,
	student_mode: bool = false,
	modes: Array = [],
	p_time_sig: Array = [4, 4],
	p_durations_beats: Array = [],
	p_bpm: int = 80
) -> void:
	suppress_base_note_glyphs = true
	configure(note_values, -1)
	show_note_hints = hints
	show_student_targets = student_mode

	event_modes.clear()
	for value: Variant in modes:
		event_modes.append(str(value).to_upper())
	if event_modes.size() != note_values.size():
		event_modes.clear()
		for _note in note_values:
			event_modes.append("TARGET")

	beat_times.clear()
	for value: Variant in times:
		beat_times.append(float(value))

	judgements.clear()
	for _value in beat_times:
		judgements.append("")

	duration = maxf(1.0, total_duration)
	current_time = 0.0
	playback_index = 0 if not note_values.is_empty() else -1

	# Time signature & tempo
	time_signature = p_time_sig if p_time_sig.size() >= 2 else [4, 4]
	tempo_bpm = p_bpm if p_bpm > 0 else 80
	if time_signature[0] == 6 and time_signature[1] == 8:
		measure_beats = 3.0
	else:
		measure_beats = float(time_signature[0]) * (4.0 / float(maxi(1, time_signature[1])))

	# Durations in beats
	durations_beats.clear()
	if p_durations_beats.size() == note_values.size():
		for d: Variant in p_durations_beats:
			durations_beats.append(float(d))
	else:
		# Infer durations from times and tempo
		for i in range(beat_times.size()):
			if i + 1 < beat_times.size():
				var dt: float = beat_times[i + 1] - beat_times[i]
				var d_beat: float = dt * float(tempo_bpm) / 60.0
				durations_beats.append(maxf(0.25, snapped(d_beat, 0.25)))
			else:
				durations_beats.append(1.0)

	# Note start beats sequentially starting from 0.0
	note_start_beats.clear()
	var current_b := 0.0
	for i in range(note_values.size()):
		note_start_beats.append(current_b)
		var d: float = durations_beats[i] if i < durations_beats.size() else 1.0
		current_b += d

	# Compute total measures based on sequential beat accumulation
	total_measures = maxi(1, int(ceil((current_b - 0.001) / measure_beats)))
	total_pages = maxi(1, int(ceil(float(total_measures) / float(MEASURES_PER_PAGE))))
	current_measure = 0
	current_page = 0
	queue_redraw()
	measure_changed.emit(current_measure, total_measures)


func update_progress(elapsed: float, states: Array) -> void:
	current_time = clampf(elapsed, 0.0, duration)
	judgements.clear()
	for state: Variant in states:
		judgements.append(str(state))
	playback_index = _active_index()

	# Auto update measure and page when playhead advances
	var current_beat := current_time * float(tempo_bpm) / 60.0
	var target_m := clampi(int(floor((current_beat + 0.001) / measure_beats)), 0, maxi(0, total_measures - 1))
	if target_m != current_measure:
		current_measure = target_m
		current_page = int(floor(float(current_measure) / float(MEASURES_PER_PAGE)))
		measure_changed.emit(current_measure, total_measures)

	queue_redraw()


func set_page(page_idx: int) -> void:
	var next_p := clampi(page_idx, 0, maxi(0, total_pages - 1))
	if next_p != current_page:
		current_page = next_p
		current_measure = current_page * MEASURES_PER_PAGE
		queue_redraw()
		measure_changed.emit(current_measure, total_measures)


func next_page() -> void:
	set_page(current_page + 1)


func prev_page() -> void:
	set_page(current_page - 1)


func set_measure(index: int) -> void:
	var next_m := clampi(index, 0, maxi(0, total_measures - 1))
	if next_m != current_measure:
		current_measure = next_m
		current_page = int(floor(float(current_measure) / float(MEASURES_PER_PAGE)))
		queue_redraw()
		measure_changed.emit(current_measure, total_measures)


func next_measure() -> void:
	set_measure(current_measure + 1)


func prev_measure() -> void:
	set_measure(current_measure - 1)


func _active_index() -> int:
	for index in beat_times.size():
		if absf(current_time - beat_times[index]) <= 0.24:
			return index
		if current_time < beat_times[index]:
			return index
	return -1


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_drag_start_x = mb.position.x
				_is_dragging = true
			else:
				if _is_dragging:
					var delta_x := mb.position.x - _drag_start_x
					if delta_x > 45.0:
						prev_page()
					elif delta_x < -45.0:
						next_page()
					_is_dragging = false
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_drag_start_x = st.position.x
			_is_dragging = true
		else:
			if _is_dragging:
				var delta_x := st.position.x - _drag_start_x
				if delta_x > 45.0:
					prev_page()
				elif delta_x < -45.0:
					next_page()
				_is_dragging = false


func _draw() -> void:
	var width := maxf(size.x, 300.0)
	var height := maxf(size.y, 140.0 if width < 450.0 else 160.0)
	var compact := width < 450.0
	var spacing := 20.0 if compact else (23.0 if width < 700.0 else 26.0)
	var center_y := height * 0.48 # Line 3 (Middle line B4 / Si) is centered slightly above midpoint
	var left_margin := 8.0 if compact else 16.0
	var right_margin := width - (8.0 if compact else 16.0)

	# 1. Draw 5 Staff Lines
	# Line 1 (bottom): center_y + 2.0 * spacing (E4 / Mi 4)
	# Line 2:         center_y + 1.0 * spacing (G4 / Sol 4) - Treble Clef spiral anchor
	# Line 3 (middle): center_y                (B4 / Si 4)
	# Line 4:         center_y - 1.0 * spacing (D5 / Rê 5)
	# Line 5 (top):    center_y - 2.0 * spacing (F5 / Fa 5)
	for i in range(5):
		var y := center_y + (float(i) - 2.0) * spacing
		draw_line(Vector2(left_margin, y), Vector2(right_margin, y), C_STAFF_LINE, 2.2, true)

	# 2. Draw Start Bar Line (left)
	var staff_top_y := center_y - 2.0 * spacing
	var staff_bot_y := center_y + 2.0 * spacing
	draw_line(Vector2(left_margin, staff_top_y), Vector2(left_margin, staff_bot_y), C_STAFF_LINE, 3.8, true)

	# 3. Draw Treble Clef (Khóa Sol) centered on Line 2 (G4 / Sol 4)
	var font := ThemeDB.fallback_font
	var line_2_y := center_y + 1.0 * spacing
	var clef_scale := 5.6
	var clef_font_size := int(spacing * clef_scale)
	var clef_x := left_margin + (2.0 if compact else 4.0)
	# Anchor the spiral loop of the G-clef on Line 2 (spiral is 0.125 * font_size above font baseline)
	var clef_baseline_y := line_2_y + (clef_font_size * 0.125)
	if font:
		draw_string(font, Vector2(clef_x, clef_baseline_y), "𝄞", HORIZONTAL_ALIGNMENT_LEFT, -1, clef_font_size, C_STAFF_LINE)

	# 4. Draw Time Signature (Chỉ số nhịp ở đầu khuông)
	var num_font := bold_font if bold_font else font
	var ts_size := int(spacing * 2.1)
	var ts_x := clef_x + spacing * (2.2 if compact else 2.6)
	if num_font:
		var num_str := str(time_signature[0] if time_signature.size() > 0 else 4)
		var den_str := str(time_signature[1] if time_signature.size() > 1 else 4)
		# Numerator: in upper 2 spaces (between line 3 and line 5), baseline near line 3
		draw_string(num_font, Vector2(ts_x, center_y - spacing * 0.05), num_str, HORIZONTAL_ALIGNMENT_LEFT, -1, ts_size, C_STAFF_LINE)
		# Denominator: in lower 2 spaces (between line 1 and line 3), baseline near line 1
		draw_string(num_font, Vector2(ts_x, center_y + spacing * 1.95), den_str, HORIZONTAL_ALIGNMENT_LEFT, -1, ts_size, C_STAFF_LINE)

	# 5. Determine the 2 measures on current screen
	var m_0 := current_page * MEASURES_PER_PAGE
	var m_1 := m_0 + 1

	# 6. Horizontal layout: Usable width, mid barline, end barline
	var start_note_x := ts_x + spacing * (1.8 if compact else 2.2)
	var usable_width := maxf(160.0, right_margin - start_note_x)
	var meas_width := usable_width * 0.5
	var mid_barline_x := start_note_x + meas_width

	# Middle Barline (Vạch nhịp giữa 2 ô rõ nét)
	draw_line(Vector2(mid_barline_x, staff_top_y), Vector2(mid_barline_x, staff_bot_y), C_STAFF_LINE, 2.4, true)

	# Right Barline (Vạch nhịp cuối)
	if m_1 >= total_measures - 1:
		# Final double barline if this screen displays the end of the piece
		draw_line(Vector2(right_margin - 5.0, staff_top_y), Vector2(right_margin - 5.0, staff_bot_y), C_STAFF_LINE, 2.0, true)
		draw_line(Vector2(right_margin, staff_top_y), Vector2(right_margin, staff_bot_y), C_STAFF_LINE, 4.8, true)
	else:
		# Standard single barline
		draw_line(Vector2(right_margin, staff_top_y), Vector2(right_margin, staff_bot_y), C_STAFF_LINE, 2.4, true)

	if notes.is_empty():
		return

	# 7. Compute full notation geometry & records
	var layout_data := compute_note_records(width, height)
	var note_records: Array = layout_data.get("records", [])
	var pulse_map: Dictionary = layout_data.get("pulse_map", {})
	var beamed_indices: Array = layout_data.get("beamed_indices", [])

	var note_head_rx := spacing * 0.68
	var note_head_ry := spacing * 0.46
	var stem_width := 2.6

	# 8. Draw Ledger lines, Note heads, and Dots
	for rec: Dictionary in note_records:
		var diatonic_step: int = rec["diatonic_step"]
		var note_x: float = rec["x"]
		var note_y: float = rec["y"]
		var note_color: Color = rec["color"]

		# Ledger lines below staff (C4 / step 0 and below)
		if diatonic_step <= 0:
			var num_ledgers := int(abs(diatonic_step) / 2) + 1
			for l in range(num_ledgers):
				var ledger_step := -l * 2
				var ly := center_y - float(ledger_step - 6) * (spacing * 0.5)
				draw_line(Vector2(note_x - note_head_rx * 1.55, ly), Vector2(note_x + note_head_rx * 1.55, ly), C_STAFF_LINE, 1.8, true)
		# Ledger lines above staff (A5 / step 12 and above)
		elif diatonic_step >= 12:
			var num_ledgers_top := int((diatonic_step - 12) / 2) + 1
			for l in range(num_ledgers_top):
				var ledger_step := 12 + l * 2
				var ly := center_y - float(ledger_step - 6) * (spacing * 0.5)
				draw_line(Vector2(note_x - note_head_rx * 1.55, ly), Vector2(note_x + note_head_rx * 1.55, ly), C_STAFF_LINE, 1.8, true)

		# Note head
		var head_poly := PackedVector2Array()
		var segs := 18
		for s in range(segs):
			var a := float(s) * TAU / float(segs)
			var rx := note_head_rx * cos(a)
			var ry := note_head_ry * sin(a)
			# Standard italic slant ~ -18 degrees
			var rot := -0.32
			var sx := rx * cos(rot) - ry * sin(rot)
			var sy := rx * sin(rot) + ry * cos(rot)
			head_poly.append(Vector2(note_x + sx, note_y + sy))

		if bool(rec["is_hollow"]):
			# Hollow note head (half/whole note)
			draw_colored_polygon(head_poly, Color(1, 1, 1, 0.96))
			draw_polyline(head_poly, note_color, 2.4, true)
		else:
			# Solid note head (quarter/8th/16th)
			draw_colored_polygon(head_poly, note_color)

		# Dotted note: draw dot in space adjacent to note head
		if bool(rec["is_dotted"]):
			var dot_x := note_x + note_head_rx * 1.45
			var dot_y := note_y
			if abs(diatonic_step % 2) == 0:
				dot_y -= spacing * 0.35 # in the space above the line
			draw_circle(Vector2(dot_x, dot_y), spacing * 0.18, note_color)

	# 9. Draw Stems & Beams / Flags
	# Draw stems for notes
	for rec: Dictionary in note_records:
		if bool(rec["has_stem"]):
			draw_line(Vector2(float(rec["stem_x"]), float(rec["stem_start_y"])), Vector2(float(rec["stem_x"]), float(rec["stem_tip_y"])), Color(rec["color"]), stem_width, true)

	# Draw beams for beam groups
	for p_grp_key: Variant in pulse_map:
		var group: Array = pulse_map[p_grp_key]
		if group.size() >= 2:
			var first_rec: Dictionary = group[0]
			var last_rec: Dictionary = group[-1]
			var p1: Vector2 = first_rec.get("beam_p1", Vector2(float(first_rec["stem_x"]), float(first_rec["stem_tip_y"])))
			var p2: Vector2 = first_rec.get("beam_p2", Vector2(float(last_rec["stem_x"]), float(last_rec["stem_tip_y"])))
			var beam_color: Color = first_rec["color"]
			var beam_w := spacing * 0.28

			draw_line(p1, p2, beam_color, beam_w, true)

			# Check if sixteenth notes need secondary beam
			var has_16th := false
			for rec: Dictionary in group:
				if float(rec["dur_beat"]) <= 0.26:
					has_16th = true
					break
			if has_16th:
				var offset_y := (beam_w * 1.5) if bool(first_rec["stem_up"]) else -(beam_w * 1.5)
				draw_line(p1 + Vector2(0, offset_y), p2 + Vector2(0, offset_y), beam_color, beam_w, true)

	# Draw isolated flags for 8th and 16th notes not in a beam group
	for rec: Dictionary in note_records:
		var idx: int = rec["index"]
		var dur: float = rec["dur_beat"]
		if dur <= 0.55 and not beamed_indices.has(idx) and bool(rec["has_stem"]):
			var stem_x: float = rec["stem_x"]
			var tip_y: float = rec["stem_tip_y"]
			var stem_up: bool = rec["stem_up"]
			var note_color: Color = rec["color"]
			var flag_w := spacing * 0.75
			var dy_dir := 1.0 if stem_up else -1.0

			# Primary flag shape
			var poly1 := PackedVector2Array([
				Vector2(stem_x, tip_y),
				Vector2(stem_x + flag_w, tip_y + dy_dir * spacing * 0.85),
				Vector2(stem_x + flag_w * 0.5, tip_y + dy_dir * spacing * 1.15),
				Vector2(stem_x, tip_y + dy_dir * spacing * 0.65),
			])
			draw_colored_polygon(poly1, note_color)

			# Secondary flag for 16th note
			if dur <= 0.26:
				var offset_y := dy_dir * spacing * 0.45
				var poly2 := PackedVector2Array([
					Vector2(stem_x, tip_y + offset_y),
					Vector2(stem_x + flag_w, tip_y + offset_y + dy_dir * spacing * 0.85),
					Vector2(stem_x + flag_w * 0.5, tip_y + offset_y + dy_dir * spacing * 1.15),
					Vector2(stem_x, tip_y + offset_y + dy_dir * spacing * 0.65),
				])
				draw_colored_polygon(poly2, note_color)

	# 10. Draw Moving Playhead cursor across the 2 measures
	if current_time > 0.0 and current_time <= duration:
		var page_beats := measure_beats * float(MEASURES_PER_PAGE)
		var current_beat := current_time * float(tempo_bpm) / 60.0
		var beat_in_page := current_beat - float(current_page) * page_beats
		if beat_in_page >= -0.05 and beat_in_page <= page_beats + 0.05:
			var playhead_x := start_note_x + (clampf(beat_in_page, 0.0, page_beats) / page_beats) * usable_width
			var top_y := staff_top_y - 12.0
			var bot_y := staff_bot_y + 12.0
			# Playhead vertical line with soft glow
			draw_line(Vector2(playhead_x, top_y), Vector2(playhead_x, bot_y), Color(C_PLAYHEAD.r, C_PLAYHEAD.g, C_PLAYHEAD.b, 0.35), 6.0, true)
			draw_line(Vector2(playhead_x, top_y), Vector2(playhead_x, bot_y), C_PLAYHEAD, 2.4, true)
			draw_circle(Vector2(playhead_x, top_y), 4.5, C_PLAYHEAD)
			draw_circle(Vector2(playhead_x, bot_y), 4.5, C_PLAYHEAD)


func compute_note_records(custom_width: float = 0.0, custom_height: float = 0.0) -> Dictionary:
	var width := custom_width if custom_width > 0.0 else maxf(size.x, 300.0)
	var height := custom_height if custom_height > 0.0 else maxf(size.y, 140.0 if width < 450.0 else 160.0)
	var compact := width < 450.0
	var spacing := 20.0 if compact else (23.0 if width < 700.0 else 26.0)
	var center_y := height * 0.48
	var left_margin := 8.0 if compact else 16.0
	var right_margin := width - (8.0 if compact else 16.0)

	var clef_x := left_margin + (2.0 if compact else 4.0)
	var ts_x := clef_x + spacing * (2.2 if compact else 2.6)
	var start_note_x := ts_x + spacing * (1.8 if compact else 2.2)
	var usable_width := maxf(160.0, right_margin - start_note_x)
	var meas_width := usable_width * 0.5
	var mid_barline_x := start_note_x + meas_width

	var m_0 := current_page * MEASURES_PER_PAGE
	var m_1 := m_0 + 1

	var meas_0_indices: Array[int] = []
	var meas_1_indices: Array[int] = []
	for i in range(notes.size()):
		var b_start: float = note_start_beats[i] if i < note_start_beats.size() else (beat_times[i] * float(tempo_bpm) / 60.0)
		var m_idx := int(floor((b_start + 0.005) / measure_beats))
		if m_idx == m_0:
			meas_0_indices.append(i)
		elif m_idx == m_1:
			meas_1_indices.append(i)

	var note_head_rx := spacing * 0.68
	var note_head_ry := spacing * 0.46
	var stem_length := spacing * 2.85

	var note_records: Array[Dictionary] = []
	var inner_w := meas_width - (6.0 if compact else 14.0)
	var pad_x := 3.0 if compact else 7.0

	var all_page_indices: Array[int] = []
	all_page_indices.append_array(meas_0_indices)
	all_page_indices.append_array(meas_1_indices)

	for idx in all_page_indices:
		var raw_note := notes[idx]
		var b_start: float = note_start_beats[idx] if idx < note_start_beats.size() else 0.0
		var m_idx := int(floor((b_start + 0.005) / measure_beats))
		var beat_in_meas := b_start - float(m_idx) * measure_beats
		var dur_beat: float = durations_beats[idx] if idx < durations_beats.size() else 1.0

		var meas_origin_x := start_note_x if m_idx == m_0 else mid_barline_x
		var meas_indices := meas_0_indices if m_idx == m_0 else meas_1_indices

		var note_x: float
		if meas_indices.size() == 1 and dur_beat >= measure_beats:
			note_x = meas_origin_x + meas_width * 0.42
		else:
			note_x = meas_origin_x + pad_x + (clampf(beat_in_meas, 0.0, measure_beats) / measure_beats) * inner_w

		var diatonic_step := _parse_diatonic_step(raw_note)
		var note_y := center_y - float(diatonic_step - 6) * (spacing * 0.5)

		var state := judgements[idx] if idx < judgements.size() else ""
		var is_sample := idx < event_modes.size() and event_modes[idx] == "SAMPLE"

		var note_color := C_DEMO_NOTE if is_sample or not show_student_targets else C_TARGET_NOTE
		if not is_sample and not state.is_empty():
			if state in ["PERFECT", "GOOD"]:
				note_color = C_PERFECT
			else:
				note_color = C_MISS

		# Standard notation: Step 6 is Middle Line (B4 / Si 4). Notes below Line 3 have stem UP; notes on or above have stem DOWN.
		var stem_up := diatonic_step < 6
		var stem_x := note_x + (note_head_rx * 0.85) if stem_up else note_x - (note_head_rx * 0.85)
		var stem_start_y := note_y
		var stem_tip_y := note_y - stem_length if stem_up else note_y + stem_length

		var has_stem := dur_beat < 3.9
		var is_hollow := dur_beat >= 1.9
		var is_dotted := absf(dur_beat - 3.0) < 0.06 or absf(dur_beat - 1.5) < 0.06 or absf(dur_beat - 0.75) < 0.06

		var pulse_group := -1
		if dur_beat <= 0.55:
			var p_in_meas := 0
			if time_signature[0] == 6 and time_signature[1] == 8:
				p_in_meas = 0 if beat_in_meas < 1.49 else 1
			else:
				p_in_meas = int(floor(beat_in_meas + 0.01))
			pulse_group = m_idx * 100 + p_in_meas

		note_records.append({
			"index": idx,
			"raw_note": raw_note,
			"diatonic_step": diatonic_step,
			"x": note_x,
			"y": note_y,
			"color": note_color,
			"has_stem": has_stem,
			"stem_up": stem_up,
			"stem_x": stem_x,
			"stem_start_y": stem_start_y,
			"stem_tip_y": stem_tip_y,
			"is_hollow": is_hollow,
			"is_dotted": is_dotted,
			"dur_beat": dur_beat,
			"pulse_group": pulse_group,
			"is_beamed": false,
		})

	# Group notes for beaming (per pulse group)
	var pulse_map: Dictionary = {}
	for rec: Dictionary in note_records:
		var p_grp: int = rec["pulse_group"]
		if p_grp >= 0:
			if not pulse_map.has(p_grp):
				pulse_map[p_grp] = []
			(pulse_map[p_grp] as Array).append(rec)

	var beamed_indices: Array[int] = []
	for p_grp_key: Variant in pulse_map:
		var group: Array = pulse_map[p_grp_key]
		if group.size() >= 2:
			var sum_step := 0
			for rec: Dictionary in group:
				sum_step += int(rec["diatonic_step"])
			var avg_step := float(sum_step) / float(group.size())
			var common_stem_up := avg_step < 6.0
			for rec: Dictionary in group:
				rec["stem_up"] = common_stem_up
				rec["stem_x"] = float(rec["x"]) + (note_head_rx * 0.85) if common_stem_up else float(rec["x"]) - (note_head_rx * 0.85)

			var first_rec: Dictionary = group[0]
			var last_rec: Dictionary = group[-1]
			var x1 := float(first_rec["stem_x"])
			var x2 := float(last_rec["stem_x"])
			var dx := maxf(1.0, x2 - x1)

			var y_first := float(first_rec["y"])
			var y_last := float(last_rec["y"])
			var max_dy := spacing * 1.0
			var dy := clampf((y_last - y_first) * 0.5, -max_dy, max_dy)

			var base_p1_y := 0.0
			if common_stem_up:
				base_p1_y = INF
				for rec: Dictionary in group:
					var rx := float(rec["stem_x"])
					var t := (rx - x1) / dx
					var req := float(rec["y"]) - stem_length - t * dy
					if req < base_p1_y:
						base_p1_y = req
			else:
				base_p1_y = -INF
				for rec: Dictionary in group:
					var rx := float(rec["stem_x"])
					var t := (rx - x1) / dx
					var req := float(rec["y"]) + stem_length - t * dy
					if req > base_p1_y:
						base_p1_y = req

			var p1_y := base_p1_y
			var p2_y := base_p1_y + dy
			first_rec["beam_p1"] = Vector2(x1, p1_y)
			first_rec["beam_p2"] = Vector2(x2, p2_y)

			for rec: Dictionary in group:
				var rx := float(rec["stem_x"])
				var t := (rx - x1) / dx
				rec["stem_tip_y"] = lerpf(p1_y, p2_y, t)
				rec["is_beamed"] = true
				beamed_indices.append(int(rec["index"]))

	return {
		"records": note_records,
		"pulse_map": pulse_map,
		"beamed_indices": beamed_indices,
	}


