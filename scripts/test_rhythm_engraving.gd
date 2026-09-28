extends SceneTree

const Context = preload("res://scripts/LearningActivityContext.gd")
const Auth = preload("res://scripts/AuthSession.gd")
const Player = preload("res://scripts/InstrumentSamplePlayer.gd")
var failures := 0

func _init() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	Auth.access_token = ""
	Auth.refresh_token = ""
	Auth.session_id = ""
	Auth._loaded = true
	Context.configure("sao_truc", ["Node1"], "res://scenes/MainMenu.tscn")
	var syllables := ["Đô", "Rê", "Mi", "Fa", "Sol", "La", "Si", "Đô2"]
	var expected := ["c5", "d5", "e5", "f5", "g5", "a5", "b5", "c6"]
	for i in syllables.size():
		_check(Player.normalize_note_key("sao_truc", syllables[i]) == expected[i], "Wrong flute register: " + syllables[i])
	_check(Player.normalize_note_key("sao_truc", "Mí") == "e6", "Accented high Mi must stay E6")
	var player := Player.new()
	_check(player.preflight("sao_truc", syllables, -1).ok, "Flute pitches must resolve to existing audio assets")
	player.free()
	for dimensions in [Vector2i(1920, 886), Vector2i(844, 390)]:
		root.content_scale_size = Vector2i.ZERO
		root.size = dimensions
		root.set_meta("force_compact_layout", dimensions.x < 1000)
		var screen = load("res://scenes/RhythmChallengeScreen.tscn").instantiate()
		root.add_child(screen)
		for frame in range(12):
			await process_frame
		var staff = screen.staff
		var plaque = screen.find_child("RhythmTitlePlaque", true, false)
		_check(plaque.get_global_rect().end.y < staff.get_global_rect().position.y, "Title overlaps score")
		var records: Array = staff.compute_note_records()["records"]
		_check(records.size() == 6, "Flute sample must have six eighth notes")
		var steps := [0, 1, 2, 4, 5, 7]
		for i in records.size():
			_check(records[i].diatonic_step == steps[i], "Wrong staff pitch")
			_check(records[i].y > 0 and records[i].y < staff.size.y, "Note outside score bounds")
			_check(records[i].stem_tip_y > 0 and records[i].stem_tip_y < staff.size.y, "Stem outside score bounds")
		var groups: Dictionary = staff.compute_note_records()["pulse_map"]
		_check(groups.size() == 2 and groups[0].size() == 3 and groups[1].size() == 3, "6/8 must beam 3+3")
		var capture_dir := OS.get_environment("VIETSTAGE_CAPTURE_DIR")
		if DisplayServer.get_name() != "headless" and not capture_dir.is_empty():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(capture_dir.path_join("rhythm-review-%d.png" % dimensions.x))
		screen.queue_free()
		await process_frame
	print("Rhythm engraving: %d failures" % failures)
	quit(1 if failures else 0)
