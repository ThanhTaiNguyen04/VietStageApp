extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if not bool(ProjectSettings.get_setting("audio/driver/enable_input", false)):
		printerr("FAILED: project.godot chưa bật audio/driver/enable_input")
		quit(1)
		return
	if int(ProjectSettings.get_setting("audio/general/ios/session_category", -1)) != 2:
		printerr("FAILED: iOS chưa dùng audio session PlayAndRecord")
		quit(1)
		return

	var export_config := ConfigFile.new()
	var export_error := export_config.load("res://export_presets.cfg")
	if export_error != OK:
		printerr("FAILED: Không đọc được export_presets.cfg: %s" % error_string(export_error))
		quit(1)
		return
	if not bool(export_config.get_value("preset.1.options", "permissions/record_audio", false)):
		printerr("FAILED: Android export chưa bật quyền RECORD_AUDIO")
		quit(1)
		return
	var ios_usage_description := str(export_config.get_value(
		"preset.0.options", "privacy/microphone_usage_description", ""
	)).strip_edges()
	if ios_usage_description.is_empty():
		printerr("FAILED: iOS export chưa có mô tả quyền microphone")
		quit(1)
		return

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
	if not analyzer.has_method("start_microphone_capture") \
			or not analyzer.has_method("get_microphone_diagnostics"):
		printerr("FAILED: Analyzer thiếu watchdog/chẩn đoán micro iOS")
		quit(1)
		return
	var diagnostics: Dictionary = analyzer.get_microphone_diagnostics()
	for required_key in ["status", "player_playing", "frames_received", "last_frame_count", "amplitude_db", "pitch_hz", "native_analyzer", "platform"]:
		if not diagnostics.has(required_key):
			printerr("FAILED: Chẩn đoán micro thiếu trường %s" % required_key)
			quit(1)
			return
	var record_bus_index := AudioServer.get_bus_index("Record")
	if record_bus_index < 0 or not AudioServer.is_bus_mute(record_bus_index):
		printerr("FAILED: Bus Record phải mute để tránh phát ngược tiếng micro ra loa")
		quit(1)
		return

	print(
		"PASS: Micro mobile đã cấu hình quyền; analyzer bao phủ 17 dây (196–1760 Hz), ngưỡng %.1f dB"
		% analyzer.volume_threshold_db
	)
	room.queue_free()
	await process_frame
	quit(0)
