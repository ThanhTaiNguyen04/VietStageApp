extends SceneTree


func _reader(levels: Dictionary, default_db: float = -80.0) -> Callable:
	return func(frequency: float) -> float:
		for expected_frequency in levels:
			if absf(frequency - float(expected_frequency)) < 1.0:
				return float(levels[expected_frequency])
		return default_db


func _fail_unless(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)


func _init() -> void:
	var lesson = load("res://scripts/LessonDanTranh.gd").new()
	lesson.force_mobile_audio_fallback_for_tests = true
	var failures: Array[String] = []

	var noisy_press: Array[float] = [
		8.0, 20.0, 44.0, 72.0, 101.0, 94.0, 108.0, 102.0, 100.0
	]
	_fail_unless(
		lesson._analyze_press_contour(noisy_press, 100.0).get("detected", false),
		"Mobile: bỏ sót đường Nhấn ngắn có nhiễu pitch nhẹ",
		failures
	)

	var short_vibrato: Array[float] = []
	for i in 24:
		var time := float(i) * lesson.VIBRATO_SAMPLE_INTERVAL
		short_vibrato.append(22.0 + 20.0 * sin(TAU * 5.0 * time))
	_fail_unless(
		lesson._analyze_vibrato_cents(short_vibrato).get("detected", false),
		"Mobile: bỏ sót Rung 5 Hz hợp lệ trong cửa sổ ngắn",
		failures
	)

	var glissando_strings: Array[int] = [15, 12, 9, 5]
	var glissando_times: Array[float] = [0.0, 0.18, 0.37, 0.58]
	_fail_unless(
		lesson._analyze_glissando_gesture(
			glissando_strings, glissando_times, "down"
		).get("success", false),
		"Mobile: Á xuống thất bại khi iOS bỏ sót một số transient trung gian",
		failures
	)

	var tremolo_strings: Array[int] = [6, 6, 6, 6]
	var tremolo_times: Array[float] = [0.0, 0.26, 0.52, 0.79]
	var tremolo_generations: Array[int] = [1, 2, 3, 4]
	var tremolo_allowed_strings: Array[int] = [6]
	_fail_unless(
		lesson._analyze_tremolo_sequence(
			tremolo_strings, tremolo_times, tremolo_generations,
			"single", tremolo_allowed_strings, 0
		).get("success", false),
		"Mobile: Vê hợp lệ với bốn onset không được chấp nhận",
		failures
	)

	_fail_unless(
		lesson._are_all_chord_fundamentals_present(
			PackedStringArray(["Đô2", "Mi2"]),
			_reader({261.63: -32.0, 329.63: -60.0})
		),
		"Mobile: Song thanh bị loại khi dây thứ hai yếu hơn trên micro điện thoại",
		failures
	)

	lesson.free()
	if failures.is_empty():
		print("PASS: mobile/Xogot fallback nhận Nhấn, Rung, Á, Vê và Song thanh")
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)
