extends SceneTree

var finished_count := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var manager = load("res://scripts/AIAudioManager.gd").new()
	root.add_child(manager)
	var analyzer = load("res://scripts/AudioCaptureAnalyzer.gd").new()
	manager.tts_started.connect(func(): analyzer.set_analysis_suspended(true))
	manager.tts_finished.connect(func():
		finished_count += 1
		analyzer.set_analysis_suspended(false)
	)
	var stream := AudioStreamWAV.new()
	stream.mix_rate = 44100
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	var data := PackedByteArray()
	data.resize(44100 * 2)
	stream.data = data
	manager.sentence_queue = [{"text": "audit", "stream": stream, "downloaded": true}]
	manager._play_next_sentence(0)
	print("Before stop: playing=", manager.audio_player.playing, " suspended=", analyzer.analysis_suspended)
	manager.stop_speech()
	await create_timer(1.5).timeout
	print("After stop: playing=", manager.audio_player.playing, " suspended=", analyzer.analysis_suspended, " tts_finished=", finished_count)
	var reproduced: bool = not analyzer.analysis_suspended and finished_count == 1
	manager.sentence_queue = [{"text": "audit", "stream": stream, "downloaded": true}]
	manager._play_next_sentence(0)
	manager._on_audio_finished()
	print("Natural completion control: suspended=", analyzer.analysis_suspended, " tts_finished=", finished_count)
	var control_ok: bool = not analyzer.analysis_suspended and finished_count == 2
	analyzer.free()
	manager.queue_free()
	quit(0 if reproduced and control_ok else 1)
