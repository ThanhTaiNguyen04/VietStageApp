extends SceneTree

const NOTES := [
	"Sol1", "La1", "Đô2", "Rê2", "Mi2",
	"Sol2", "La2", "Đô3", "Rê3", "Mi3",
	"Sol3", "La3", "Đô4", "Rê4", "Mi4", "Sol4", "La4",
]
const FREQUENCIES := [
	196.00, 220.00, 261.63, 293.66, 329.63,
	392.00, 440.00, 523.25, 587.33, 659.25,
	783.99, 880.00, 1046.50, 1174.66, 1318.51, 1567.98, 1760.00,
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://scenes/LessonDanTranh.tscn") as PackedScene
	var lesson := scene.instantiate()
	root.add_child(lesson)
	await process_frame
	var analyzer = lesson.get_node("Analyzer")
	var failures: Array[String] = []

	for index in FREQUENCIES.size():
		analyzer.current_amplitude_db = -40.0
		analyzer.current_pitch = FREQUENCIES[index]
		analyzer.current_pitch_is_reliable = true
		lesson.time_correct = 0.0
		if not lesson._check_mic_pitch(FREQUENCIES[index], 0.20, NOTES[index]):
			failures.append("Không nhận dây %d %s" % [index + 1, NOTES[index]])

	# Same note name in another octave must never pass.
	analyzer.current_pitch = 196.0
	lesson.time_correct = 0.0
	if lesson._check_mic_pitch(1567.98, 0.20, "Sol4"):
		failures.append("Sol1 bị nhận nhầm thành Sol4")

	# A weak but usable high-string signal must pass the configured gate.
	analyzer.current_amplitude_db = -52.0
	analyzer.current_pitch = 1760.0
	lesson.time_correct = 0.0
	if not lesson._check_mic_pitch(1760.0, 0.20, "La4"):
		failures.append("Âm La4 nhỏ hợp lệ bị ngưỡng micro loại")

	if failures.is_empty():
		print("PASS: LessonDanTranh nhận đúng 17/17 nốt thật, không nhầm quãng tám")
		lesson.queue_free()
		await process_frame
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)
