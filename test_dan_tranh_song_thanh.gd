extends SceneTree

const DO2 := 261.63
const MI2 := 329.63
const SOL2 := 392.00
const RE2 := 293.66
const SAMPLE_RATE := 44100.0
const WINDOW_SIZE := 4096


func _reader(levels: Dictionary, default_db: float = -80.0) -> Callable:
	return func(frequency: float) -> float:
		for target_frequency in levels:
			if absf(frequency - float(target_frequency)) < 1.0:
				return float(levels[target_frequency])
		return default_db


func _synthetic_window(frequencies: Array[float]) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(WINDOW_SIZE)
	for sample_index in WINDOW_SIZE:
		var value := 0.0
		for frequency in frequencies:
			value += 0.24 * sin(TAU * frequency * float(sample_index) / SAMPLE_RATE)
		samples[sample_index] = value
	return samples


func _tone_db(samples: PackedFloat32Array, frequency: float) -> float:
	var real := 0.0
	var imaginary := 0.0
	var window_sum := 0.0
	for sample_index in samples.size():
		var phase := TAU * frequency * float(sample_index) / SAMPLE_RATE
		var window := 0.5 - 0.5 * cos(TAU * float(sample_index) / float(samples.size() - 1))
		var windowed_sample := float(samples[sample_index]) * window
		real += windowed_sample * cos(phase)
		imaginary -= windowed_sample * sin(phase)
		window_sum += window
	var magnitude := 2.0 * sqrt(real * real + imaginary * imaginary) / maxf(window_sum, 0.000001)
	return 20.0 * log(maxf(magnitude, 0.00000001)) / log(10.0)


func _audio_reader(samples: PackedFloat32Array) -> Callable:
	return func(frequency: float) -> float:
		return _tone_db(samples, frequency)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _init() -> void:
	var lesson = load("res://scripts/LessonDanTranh.gd").new()
	var failures: Array[String] = []
	var song_thanh := PackedStringArray(["Đô2", "Mi2"])
	var do_major := PackedStringArray(["Đô2", "Mi2", "Sol2"])
	var a_minor := PackedStringArray(["La1", "Đô2", "Mi2"])

	# Song thanh: both fundamentals must be present in the same spectrum window.
	_expect(
		lesson._are_all_chord_fundamentals_present(
			song_thanh,
			_reader({DO2: -30.0, MI2: -33.0})
		),
		"Song thanh: rejected a balanced two-note window",
		failures
	)
	_expect(
		not lesson._are_all_chord_fundamentals_present(song_thanh, _reader({DO2: -30.0})),
		"Song thanh: accepted only the first note",
		failures
	)
	_expect(
		not lesson._are_all_chord_fundamentals_present(song_thanh, _reader({MI2: -30.0})),
		"Song thanh: accepted only the second note",
		failures
	)
	_expect(
		not lesson._are_all_chord_fundamentals_present(
			song_thanh,
			_reader({DO2: -30.0, MI2: -60.0})
		),
		"Song thanh: accepted a component below the minimum level",
		failures
	)
	_expect(
		not lesson._are_all_chord_fundamentals_present(
			song_thanh,
			_reader({DO2: -30.0, MI2: -51.0})
		),
		"Song thanh: accepted components with excessive level imbalance",
		failures
	)

	# Three-note chords use the same strict all-components rule.
	_expect(
		lesson._are_all_chord_fundamentals_present(
			do_major,
			_reader({DO2: -31.0, MI2: -34.0, SOL2: -33.0})
		),
		"Do major: rejected all three balanced notes",
		failures
	)
	for missing_frequency in [DO2, MI2, SOL2]:
		var present := {DO2: -31.0, MI2: -34.0, SOL2: -33.0}
		present.erase(missing_frequency)
		_expect(
			not lesson._are_all_chord_fundamentals_present(do_major, _reader(present)),
			"Do major: accepted a chord missing %.2f Hz" % missing_frequency,
			failures
		)
	_expect(
		lesson._are_all_chord_fundamentals_present(
			a_minor,
			_reader({220.00: -32.0, DO2: -30.0, MI2: -35.0})
		),
		"A minor: rejected all three balanced notes",
		failures
	)

	# Invalid targets and a clearly played extra string must not pass.
	_expect(
		not lesson._are_all_chord_fundamentals_present(
			PackedStringArray(["Đô2"]),
			_reader({DO2: -30.0})
		),
		"Accepted a one-note target as a chord",
		failures
	)
	_expect(
		not lesson._are_all_chord_fundamentals_present(
			PackedStringArray(["Đô2", "Đô2"]),
			_reader({DO2: -30.0})
		),
		"Accepted a duplicated note as Song thanh",
		failures
	)
	_expect(
		not lesson._are_all_chord_fundamentals_present(
			PackedStringArray(["Mi2", "Fa2"]),
			_reader({MI2: -30.0, 349.23: -32.0})
		),
		"Accepted two target names mapped to the same physical string",
		failures
	)
	_expect(
		not lesson._are_all_chord_fundamentals_present(
			do_major,
			_reader({DO2: -31.0, MI2: -34.0, SOL2: -33.0, RE2: -35.0})
		),
		"Accepted a chord with a strong unexpected string",
		failures
	)

	# Natural integer harmonics of target notes are not treated as extra strings.
	_expect(
		lesson._are_all_chord_fundamentals_present(
			PackedStringArray(["Sol1", "La1"]),
			_reader({196.00: -30.0, 220.00: -32.0, SOL2: -34.0})
		),
		"Rejected Song thanh because of a natural target harmonic",
		failures
	)

	# Deterministic 4096-sample audio windows exercise the spectral path rather
	# than only fixed mock dB values.
	_expect(
		lesson._are_all_chord_fundamentals_present(
			song_thanh,
			_audio_reader(_synthetic_window([DO2, MI2]))
		),
		"Synthetic audio: rejected both simultaneous Song thanh frequencies",
		failures
	)
	_expect(
		not lesson._are_all_chord_fundamentals_present(
			song_thanh,
			_audio_reader(_synthetic_window([DO2]))
		),
		"Synthetic audio: accepted one note as Song thanh",
		failures
	)
	_expect(
		lesson._are_all_chord_fundamentals_present(
			do_major,
			_audio_reader(_synthetic_window([DO2, MI2, SOL2]))
		),
		"Synthetic audio: rejected all three simultaneous chord frequencies",
		failures
	)
	_expect(
		not lesson._are_all_chord_fundamentals_present(
			do_major,
			_audio_reader(_synthetic_window([DO2, MI2]))
		),
		"Synthetic audio: accepted a two-note fragment as a three-note chord",
		failures
	)

	# A visual chord has several note heads but may update confirmation only once
	# per frame, for both two-note and three-note exercises.
	lesson.current_lesson_id = "dan_tranh_level_7_bai_20_practice"
	_expect(
		lesson._should_score_polyphonic_component("Đô2+Mi2", 0),
		"Song thanh: first visual component was not scored",
		failures
	)
	_expect(
		not lesson._should_score_polyphonic_component("Đô2+Mi2", 1),
		"Song thanh: confirmation advanced twice in one frame",
		failures
	)
	lesson.current_lesson_id = "dan_tranh_level_8_bai_32_practice"
	_expect(
		lesson._should_score_polyphonic_component("Đô2+Mi2+Sol2", 0),
		"Chord: first visual component was not scored",
		failures
	)
	_expect(
		not lesson._should_score_polyphonic_component("Đô2+Mi2+Sol2", 1)
			and not lesson._should_score_polyphonic_component("Đô2+Mi2+Sol2", 2),
		"Chord: confirmation advanced more than once in one frame",
		failures
	)

	# The full set must remain continuously present for at least 100 ms.
	lesson.time_correct = 0.0
	for _frame in 6:
		_expect(
			not lesson._advance_polyphonic_confirmation(true, 0.016),
			"Completed a polyphonic target before 100 ms",
			failures
		)
	_expect(
		lesson._advance_polyphonic_confirmation(true, 0.016),
		"Did not complete a continuous polyphonic target after 100 ms",
		failures
	)

	# Sequential/alternating notes are incomplete windows. Every incomplete window
	# resets the timer, so separate notes can never accumulate into a chord.
	lesson.time_correct = 0.0
	for _frame in 4:
		lesson._advance_polyphonic_confirmation(true, 0.016)
	lesson._advance_polyphonic_confirmation(false, 0.016)
	for _frame in 3:
		_expect(
			not lesson._advance_polyphonic_confirmation(true, 0.016),
			"Accumulated confirmation across an incomplete/sequential window",
			failures
		)
	_expect(
		lesson.time_correct <= 0.0481,
		"Did not reset confirmation after a missing chord component",
		failures
	)

	lesson.free()
	if failures.is_empty():
		print("PASS: Song thanh and three-note chords require every simultaneous component")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)
