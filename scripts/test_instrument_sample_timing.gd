extends SceneTree

const Player = preload("res://scripts/InstrumentSamplePlayer.gd")

var started_at := 0
var onsets: Array[float] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := Player.new()
	root.add_child(player)
	player.note_started.connect(func(_index: int) -> void:
		onsets.append(float(Time.get_ticks_msec() - started_at) / 1000.0)
	)
	var times: Array[float] = [0.0, 0.25, 0.75]
	var durations: Array[float] = [0.25, 0.5, 0.25]
	started_at = Time.get_ticks_msec()
	var result := player.play_timed_sequence("dan_tranh", ["Đô2", "Rê2", "Mi2"], times, durations)
	if not result.ok:
		push_error("Không tạo được âm mẫu đàn tranh")
		quit(1)
		return
	await player.playback_finished
	# Check both note intervals against the authored quarter- and half-second
	# gaps; loading the first stream may delay the start of the sequence.
	if onsets.size() != 3 or absf((onsets[1] - onsets[0]) - 0.25) > 0.10 or absf((onsets[2] - onsets[1]) - 0.5) > 0.10:
		push_error("Nốt mẫu không phát theo trường độ đã ghi: " + str(onsets))
		quit(1)
		return
	print("Recorded instrument timing: PASS ", onsets)
	player.queue_free()
	await process_frame
	quit()
