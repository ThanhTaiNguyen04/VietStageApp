extends SceneTree

const RhythmScene = preload("res://scenes/RhythmChallengeScreen.tscn")

var screen: Control

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	screen = RhythmScene.instantiate() as Control
	get_root().add_child(screen)
	await process_frame
	await process_frame
	var round: Array[Dictionary] = [{
		"title": "Kiểm thử HUD",
		"tempo_bpm": 80,
		"time_signature": [4, 4],
		"durations_beats": [1.0, 1.0],
		"notes": ["C4", "D4"],
		"max_score": 100,
	}]
	screen.rhythms = round
	screen.rhythm_index = 0
	screen.selected_speed_multiplier = 1.0
	screen._prepare_current_round()

	# Pause must preserve the elapsed playhead and suspend scoring.
	screen.flow_state = screen.FlowState.PLAYING
	screen.playing = true
	screen.round_started_at_ms = Time.get_ticks_msec() - 500
	screen._pause_round()
	var frozen_elapsed: float = screen._round_elapsed()
	assert(screen.flow_state == screen.FlowState.PAUSED)
	assert(not screen.playing)
	await create_timer(0.12).timeout
	assert(is_equal_approx(screen._round_elapsed(), frozen_elapsed), "Pause must freeze the playhead")

	screen._resume_round()
	assert(screen.flow_state == screen.FlowState.PLAYING and screen.playing)
	await create_timer(0.12).timeout
	assert(screen._round_elapsed() > frozen_elapsed, "Resume must continue from the frozen playhead")

	# Restart abandons only the current round; it must not record a result.
	screen.total_score = 31
	screen.total_max_score = 100
	screen._pause_round()
	screen._restart_round_from_pause()
	assert(screen.total_score == 31 and screen.total_max_score == 100, "Restart must not alter saved challenge totals")
	assert(screen.round_hits == 0 and screen.round_accuracy_points == 0, "Restart must reset current-round scoring")

	# Listening from Pause must not score a learner performance or submit data.
	screen.session_generation += 1
	screen.flow_state = screen.FlowState.PLAYING
	screen.playing = true
	screen.round_started_at_ms = Time.get_ticks_msec() - 450
	screen._pause_round()
	var frozen_sample_elapsed: float = screen._round_elapsed()
	var score_before_sample: int = screen.total_score
	var submitted_before_sample: int = screen.submitted_count
	screen._play_sample_from_pause()
	assert(screen.flow_state == screen.FlowState.PAUSED and not screen.playing)
	assert(is_equal_approx(screen._round_elapsed(), frozen_sample_elapsed))
	assert(screen.total_score == score_before_sample and screen.submitted_count == submitted_before_sample)
	assert(screen.audio_analyzer.analysis_suspended, "Sample must not read mic input")
	var sample_wait_started := Time.get_ticks_msec()
	while screen.sample_from_pause and Time.get_ticks_msec() - sample_wait_started < 4000:
		await process_frame
	assert(not screen.sample_from_pause, "Full sample must return to Pause")
	assert(screen.practice_hud.get_node("PracticeHudPauseOverlay").visible, "Sample must return to Pause")
	assert(screen.total_score == score_before_sample and screen.submitted_count == submitted_before_sample, "Sample must not save a result")

	print("Rhythm practice HUD state: PASS")
	screen.queue_free()
	quit()
