extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://scenes/PracticeRoom.tscn") as PackedScene
	if scene == null:
		printerr("FAILED: Không tải được PracticeRoom")
		quit(1)
		return

	var room := scene.instantiate()
	root.add_child(room)
	await process_frame
	var analyzer = room.get_node_or_null("Root/RecordBar/RecordM/RecordH/WaveformVisualizer")
	if analyzer == null:
		printerr("FAILED: Không tạo được bộ thu micro")
		quit(1)
		return

	if analyzer.min_frequency > 196.0 or analyzer.max_frequency < 1760.0:
		printerr("FAILED: Dải micro không bao phủ đủ 17 dây: %.1f–%.1f Hz" % [
			analyzer.min_frequency, analyzer.max_frequency
		])
		quit(1)
		return
	if analyzer.volume_threshold_db > -55.0:
		printerr("FAILED: Ngưỡng micro quá cao: %.1f dB" % analyzer.volume_threshold_db)
		quit(1)
		return

	print("PASS: Micro bao phủ 17 dây (196–1760 Hz), ngưỡng %.1f dB" % analyzer.volume_threshold_db)
	room.queue_free()
	await process_frame
	quit(0)
