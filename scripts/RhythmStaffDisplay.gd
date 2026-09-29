extends "res://scripts/LearningMelodyStaffDisplay.gd"

## Enhanced Staff renderer for Mini-game 1 (Rhythm Challenge).
## Features:
## - 5-line staff with Treble Clef centered on Line 2 (G4 / Sol 4)
## - Configurable Time Signatures (2/4, 3/4, 4/4, 6/8)
## - Measure pagination (2 measures per page) with auto-flip on playhead crossing
## - Precise horizontal placement based on note start beats
## - Standard note shapes by duration (whole/half hollow, quarter/8th/16th solid, dots)
## - Standard beam grouping (3+3 in 6/8, quarter-beat groups in 2/4, 3/4, 4/4) and isolated flags
## - Minimalist UI: no bottom note tags, no top MISS badges, sleek playhead cursor

signal measure_changed(current_measure: int, total_measures: int)

const MUSIC_FONT = preload("res://assets/fonts/Bravura.otf")


func _notation_geometry(width: float, height: float) -> Dictionary:
	# Reserve room for the actual register, including ledger lines and stems.
	# Keep the scale stable across pages so turning a page never moves the staff.
	var above := 4.0
	var below := 4.0
	for note in notes:
		var step := _parse_diatonic_step(note)
		above = maxf(above, float(step - 6) * 0.5 + 1.0)
		below = maxf(below, float(6 - step) * 0.5 + 1.0)
	var spacing := minf(32.0 if width >= 700.0 else 20.0, (height - 16.0) / (above + below))
	var center_y := (height - (above + below) * spacing) * 0.5 + above * spacing
	var left := 12.0
	var clef_x := left + spacing * 0.5
	var ts_x := clef_x + spacing * 3.4
	return {"spacing": spacing, "center_y": center_y, "left": left,
		"right": width - 12.0, "clef_x": clef_x, "ts_x": ts_x,
		"start_x": ts_x + spacing * 2.7}


func _time_signature_glyphs(value: int) -> String:
	var result := ""
	for digit in str(value):
		result += String.chr(0xE080 + int(digit))
	return result


func _parse_diatonic_step(note_str: String) -> int:
	var pitch := note_str.to_lower().strip_edges()
	if pitch.length() == 2 and pitch[0] in "cdefgab" and pitch[1].is_valid_int():
		return "cdefgab".find(pitch[0]) + (int(pitch[1]) - 4) * 7
	return super._parse_diatonic_step(note_str)

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
	# The base renderer defaults to 210 px; honor the responsive height set by
	# the game before this node enters the tree.
	var requested_height := custom_minimum_size.y
	super._ready()
	if requested_height > 0.0:
		custom_minimum_size.y = requested_height
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
	var height := maxf(size.y, 132.0)
	var geometry := _notation_geometry(width, height)
	var spacing: float = geometry.spacing
	var center_y: float = geometry.center_y
	var left_margin: float = geometry.left
	var right_margin: float = geometry.right

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
	var font := MUSIC_FONT
	var line_2_y := center_y + 1.0 * spacing
	var clef_scale := 4.0
	var clef_font_size := int(spacing * clef_scale)
	var clef_x: float = geometry.clef_x
	# Bravura's SMuFL origin is the G4 line; one staff space is 1/4 em.
	var clef_baseline_y := line_2_y
	if font:
		draw_string(font, Vector2(clef_x, clef_baseline_y), "\uE050", HORIZONTAL_ALIGNMENT_LEFT, -1, clef_font_size, C_STAFF_LINE)

	# 4. Draw Time Signature (Chỉ số nhịp ở đầu khuông)
	var num_font := MUSIC_FONT
	var ts_size := int(spacing * 4.0)
	var ts_x: float = geometry.ts_x
	if num_font:
		var num_str := _time_signature_glyphs(int(time_signature[0]))
		var den_str := _time_signature_glyphs(int(time_signature[1]))
		# Numerator: in upper 2 spaces (between line 3 and line 5), baseline near line 3
		draw_string(num_font, Vector2(ts_x, center_y - spacing), num_str, HORIZONTAL_ALIGNMENT_LEFT, -1, ts_size, C_STAFF_LINE)
		# Denominator: in lower 2 spaces (between line 1 and line 3), baseline near line 1
		draw_string(num_font, Vector2(ts_x, center_y + spacing), den_str, HORIZONTAL_ALIGNMENT_LEFT, -1, ts_size, C_STAFF_LINE)

	# 5. Determine the 2 measures on current screen
	var m_0 := current_page * MEASURES_PER_PAGE
	var m_1 := m_0 + 1
	var visible_measures := mini(MEASURES_PER_PAGE, maxi(1, total_measures - m_0))

	# 6. Horizontal layout: Usable width, mid barline, end barline
	var start_note_x: float = geometry.start_x
	var usable_width := maxf(160.0, right_margin - start_note_x)
	var meas_width := usable_width / float(visible_measures)
	var mid_barline_x := start_note_x + meas_width

	# An odd final page has only one measure: do not draw a phantom barline
	# or leave an empty second measure.
	if visible_measures > 1:
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

	var note_head_rx := spacing * 0.59
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

		# SMuFL noteheads preserve the engraved contour and hollow counter.
		var glyph := "\uE0A4"
		if not bool(rec["has_stem"]):
			glyph = "\uE0A2"
		elif bool(rec["is_hollow"]):
			glyph = "\uE0A3"
		var glyph_size := int(spacing * 4.0)
		var glyph_width := MUSIC_FONT.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, glyph_size).x
		draw_string(MUSIC_FONT, Vector2(note_x - glyph_width * 0.5, note_y), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, glyph_size, note_color)

		# Dotted note: draw dot in space adjacent to note head
		if bool(rec["is_dotted"]):
			var dot_x := note_x + note_head_rx * 1.45
			var dot_y := note_y
			if abs(diatonic_step % 2) == 0:
				dot_y -= spacing * 0.5 # center of the space above the line
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

			# Secondary beams only join adjacent sixteenths; an isolated
			# sixteenth gets a short beamlet, never a beam over an eighth.
			var offset_y := beam_w * 1.6 * (1.0 if bool(first_rec["stem_up"]) else -1.0)
			for i in range(group.size()):
				var rec: Dictionary = group[i]
				if float(rec["dur_beat"]) > 0.26:
					continue
				var from := Vector2(rec["stem_x"], rec["stem_tip_y"] + offset_y)
				var next_is_short := i + 1 < group.size() and float(group[i + 1]["dur_beat"]) <= 0.26
				var prev_is_short := i > 0 and float(group[i - 1]["dur_beat"]) <= 0.26
				if next_is_short:
					var next: Dictionary = group[i + 1]
					draw_line(from, Vector2(next["stem_x"], next["stem_tip_y"] + offset_y), beam_color, beam_w, true)
				elif not prev_is_short:
					var direction := -1.0 if i == group.size() - 1 else 1.0
					var neighbor: Dictionary = group[i - 1] if direction < 0.0 else group[i + 1]
					var hook_dx := direction * minf(spacing, absf(float(neighbor["stem_x"]) - from.x) * 0.4)
					var slope := (p2.y - p1.y) / maxf(1.0, p2.x - p1.x)
					draw_line(from, from + Vector2(hook_dx, hook_dx * slope), beam_color, beam_w, true)

	# SMuFL flags attach at the stem tip for either stem direction.
	for rec: Dictionary in note_records:
		var dur: float = rec["dur_beat"]
		if dur <= 0.76 and not beamed_indices.has(rec["index"]) and bool(rec["has_stem"]):
			var glyph := "\uE240" if bool(rec["stem_up"]) else "\uE241"
			if dur <= 0.26:
				glyph = "\uE242" if bool(rec["stem_up"]) else "\uE243"
			draw_string(MUSIC_FONT, Vector2(rec["stem_x"], rec["stem_tip_y"]), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, int(spacing * 4.0), rec["color"])

	# 10. Draw the playhead across the measures actually visible on this page.
	if current_time > 0.0 and current_time <= duration:
		var page_beats := measure_beats * float(visible_measures)
		var current_beat := current_time * float(tempo_bpm) / 60.0
		var beat_in_page := current_beat - float(m_0) * measure_beats
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
	var height := custom_height if custom_height > 0.0 else maxf(size.y, 132.0)
	var compact := width < 450.0
	var geometry := _notation_geometry(width, height)
	var spacing: float = geometry.spacing
	var center_y: float = geometry.center_y
	var right_margin: float = geometry.right
	var start_note_x: float = geometry.start_x
	var usable_width := maxf(160.0, right_margin - start_note_x)
	var m_0 := current_page * MEASURES_PER_PAGE
	var m_1 := m_0 + 1
	var visible_measures := mini(MEASURES_PER_PAGE, maxi(1, total_measures - m_0))
	var meas_width := usable_width / float(visible_measures)
	var mid_barline_x := start_note_x + meas_width

	var meas_0_indices: Array[int] = []
	var meas_1_indices: Array[int] = []
	for i in range(notes.size()):
		var b_start: float = note_start_beats[i] if i < note_start_beats.size() else (beat_times[i] * float(tempo_bpm) / 60.0)
		var m_idx := int(floor((b_start + 0.005) / measure_beats))
		if m_idx == m_0:
			meas_0_indices.append(i)
		elif m_idx == m_1:
			meas_1_indices.append(i)

	var note_head_rx := spacing * 0.59
	var stem_length := spacing * 3.5

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
		if dur_beat <= 0.76:
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
			var max_dy := spacing * 0.5
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
