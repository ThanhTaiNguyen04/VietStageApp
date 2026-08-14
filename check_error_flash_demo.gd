extends SceneTree

const DEMO_ID := "dan_tranh_level_7_bai_22_practice"

func _init() -> void:
	SecureDataManager.active_lesson_id = DEMO_ID
	InstrumentSelect.selected_instrument = "dan_tranh"
	call_deferred("_run_check")

func _fail(message: String) -> void:
	printerr("FAILED: " + message)
	quit(1)

func _run_check() -> void:
	var packed := load("res://scenes/LessonDanTranh.tscn") as PackedScene
	if packed == null:
		_fail("LessonDanTranh scene did not load")
		return
	var instance := packed.instantiate()
	root.add_child(instance)
	for _frame in 8:
		await process_frame

	if str(instance.get("current_lesson_id")) != DEMO_ID:
		_fail("99+ did not select the error-feedback lesson flow")
		return
	var badge := instance.get("error_flash_badge") as Control
	var halo := instance.get("error_flash_halo") as Control
	var beam := instance.get("error_flash_beam") as Control
	if badge == null or halo == null or beam == null:
		_fail("wrong-note feedback controls were not built")
		return
	if badge.modulate.a > 0.001 or halo.modulate.a > 0.001 or beam.modulate.a > 0.001:
		_fail("feedback is visible before a wrong-note event")
		return
	if badge.size.x < 350.0 or badge.size.y < 100.0:
		_fail("Simply-style feedback card is too small")
		return
	var notes: Array = instance.get("active_falling_notes")
	if notes.is_empty():
		_fail("99+ did not create its demo notes")
		return

	instance.call("_play_error_flash_demo")
	await create_timer(0.28).timeout
	if not bool(instance.get("error_feedback_showing")):
		_fail("wrong-note event did not open feedback")
		return
	if badge.modulate.a < 0.85 or halo.modulate.a < 0.25 or beam.modulate.a < 0.25:
		_fail("wrong-note card, halo or spotlight did not animate in")
		return

	instance.call("_finish_error_flash_demo")
	if bool(instance.get("error_feedback_showing")) or badge.modulate.a > 0.001 or halo.modulate.a > 0.001 or beam.modulate.a > 0.001:
		_fail("wrong-note feedback did not fully close")
		return

	print("OK: 99+ keeps feedback hidden until an error, slides it in, and clears it afterward")
	quit(0)
