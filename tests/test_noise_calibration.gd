extends SceneTree

const Analyzer = preload("res://scripts/AudioCaptureAnalyzer.gd")

func _initialize() -> void:
	assert(load("res://scripts/PracticeRoom.gd") != null)
	assert(load("res://scripts/LessonDanTranh.gd") != null)
	var mic := Analyzer.new()
	mic.pitch_profile = InstrumentPitchProfile.new()
	mic.volume_threshold_db = -58.0
	mic.start_calibration()
	mic.finish_calibration()
	assert(not mic.calibration_succeeded)
	assert(mic.volume_threshold_db == -58.0)
	mic.start_calibration()
	mic.calibration_elapsed = 3.0
	for i in range(100):
		mic.calibration_db_samples.append(-76.0)
	assert(is_equal_approx(mic.finish_calibration(), -64.0))
	assert(mic.calibration_succeeded)
	assert(mic.pitch_profile.volume_threshold_db == mic.volume_threshold_db)
	assert(mic.current_pitch == 0.0)
	mic.start_calibration()
	mic.calibration_elapsed = 3.0
	for i in range(100):
		mic.calibration_db_samples.append(-55.0)
	assert(is_equal_approx(mic.finish_calibration(), -43.0))
	mic.start_calibration()
	mic.calibration_elapsed = 3.0
	for i in range(100):
		mic.calibration_db_samples.append(-30.0)
	mic.finish_calibration()
	assert(not mic.calibration_succeeded)
	assert(is_equal_approx(mic.volume_threshold_db, -43.0))
	mic.start_calibration()
	mic.calibration_elapsed = 3.0
	for i in range(100):
		mic.calibration_db_samples.append(-70.0 if i < 50 else -40.0)
	mic.finish_calibration()
	assert(not mic.calibration_succeeded)
	mic.free()
	print("Noise calibration tests passed")
	quit()
