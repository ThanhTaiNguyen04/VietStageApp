extends Node

## Regression coverage for the practice HUD contract.  This intentionally calls
## the state methods directly so it can run without microphone hardware.

const PRACTICE_SCENE := preload("res://scenes/PracticeSaoTruc.tscn")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var practice = PRACTICE_SCENE.instantiate()
	get_tree().root.add_child(practice)
	await get_tree().process_frame
	await get_tree().process_frame

	# Pause freezes the practice timeline and audio stream; resume preserves both.
	practice._recording = false
	practice._is_paused = false
	practice._is_sample_playback = false
	practice._is_wait_mode = false
	practice._is_demo_mode = false
	practice._count_in_timer = 2.0
	practice._current_note_elapsed = 0.35
	practice._speed_scale = 1.0
	var audio = AudioStreamPlayer.new()
	audio.stream = practice._flute_streams.get("Đô") as AudioStream
	practice.add_child(audio)
	audio.play()
	practice._active_player = audio
	practice._pause_practice()
	var paused_countdown: float = practice._count_in_timer
	var paused_playhead: float = practice._current_note_elapsed
	practice._process(1.0)
	assert(is_equal_approx(practice._count_in_timer, paused_countdown), "Pause must freeze countdown")
	assert(is_equal_approx(practice._current_note_elapsed, paused_playhead), "Pause must freeze playhead")
	assert(audio.stream_paused, "Pause must retain and pause the active audio stream")
	practice._resume_from_pause()
	assert(not audio.stream_paused, "Resume must continue the existing audio stream")
	practice._process(0.25)
	assert(practice._count_in_timer < paused_countdown, "Resume must advance from the paused countdown")

	# The selected speed is applied once to the timeline.
	practice._count_in_timer = 2.0
	practice._speed_scale = 0.6
	practice._user_override_speed = true
	practice._sync_practice_audio_speed()
	assert(is_equal_approx(audio.pitch_scale, 0.6), "Audio must use the selected speed once")
	practice._mic_mode = false
	practice._process(1.0)
	assert(is_equal_approx(practice._count_in_timer, 1.4), "60% speed must apply one multiplier")

	# Restart discards the paused run and starts a clean session at the selected speed.
	practice._is_paused = true
	practice._note_idx = min(2, practice.sheet_notes.size() - 1)
	practice._score = 31.0
	practice._current_note_elapsed = 0.8
	practice._restart_from_pause()
	assert(not practice._is_paused, "Restart must leave the practice running")
	assert(practice._recording, "Restart must start a fresh practice session")
	assert(practice._note_idx == 0, "Restart must return to the first note")
	assert(is_equal_approx(practice._score, 75.0), "Restart must reset the score")
	assert(is_equal_approx(practice._speed_scale, 0.6), "Restart must retain the selected speed")
	practice._stop_active_practice_without_result()

	# Sample playback never enters recording/scoring and must not persist a result.
	var history_before: Variant = SecureDataManager.data.get("adaptive_history", {}).duplicate(true)
	practice._score = 88.0
	practice._start_sample_from_pause()
	assert(practice._is_sample_playback, "Sample must enter non-scoring playback")
	assert(not practice._recording, "Sample must not record microphone input")
	assert(is_equal_approx(practice._score, 88.0), "Sample must not alter the score")
	assert(SecureDataManager.data.get("adaptive_history", {}) == history_before, "Sample must not save a practice result")
	var sample_guard := 0
	while practice._is_sample_playback and sample_guard < practice.sheet_notes.size() + 1:
		practice._process(10.0)
		sample_guard += 1
	assert(not practice._is_sample_playback, "Sample must finish after the last note")
	assert(practice._is_paused, "Sample completion must return to the action overlay")
	assert(practice._practice_hud._resume_label.text == "Luyện tập", "Sample completion must offer Luyện tập")
	assert(practice._practice_hud._sample_label.text == "Nghe lại", "Sample completion must offer Nghe lại")
	assert(SecureDataManager.data.get("adaptive_history", {}) == history_before, "Completed sample must not save a practice result")
	practice._stop_active_practice_without_result()

	practice.queue_free()
	await get_tree().process_frame
	print("Practice Sao Truc HUD state: PASS")
	get_tree().quit()
