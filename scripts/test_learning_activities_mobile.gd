extends Node

const ACTIVITIES_SCENE := preload("res://scenes/LearningActivitiesScreen.tscn")

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	get_tree().root.set_meta("force_compact_layout", true)
	var screen := ACTIVITIES_SCENE.instantiate()
	get_tree().root.add_child(screen)
	await get_tree().process_frame
	await get_tree().process_frame
	# _render can be deferred behind an offline content lookup; force its local
	# layout pass so this test remains independent of network state.
	screen._render()
	await get_tree().process_frame

	var profile_pill := screen.find_child("ProfilePill", true, false)
	assert(profile_pill != null and profile_pill.is_visible_in_tree(), "Mobile header must expose Hồ sơ và thành tựu")
	var profile_trigger := profile_pill.find_child("TriggerButton", true, false) as Button
	assert(profile_trigger != null, "Profile trigger is missing")
	assert(profile_pill.tooltip_text == "Mở hồ sơ và thành tựu", "Profile trigger needs an accessible purpose")
	assert(screen.find_child("ActivityHistoryAction", true, false) is Button, "Profile menu must include Lịch sử hoạt động")
	assert(screen.find_child("ActivityBackButton", true, false) is Button, "A circular back button is required")

	for child in screen.find_children("*", "Label", true, false):
		var label := child as Label
		assert(not (label.is_visible_in_tree() and label.text == "HOẠT ĐỘNG LUYỆN TẬP"), "Mobile must not repeat the Luyện tập heading")

	# The stretched phone viewport used to expand the glass across the screen,
	# leaving large empty wings beside the fixed-width activity cards.
	var original_size := get_tree().root.content_scale_size
	for viewport_size in [Vector2i(1920, 886), Vector2i(844, 390), Vector2i(390, 844)]:
		get_tree().root.content_scale_size = viewport_size
		for category in ["", "quiz", "minigame"]:
			if category.is_empty():
				screen._render()
			else:
				screen._render_category_picker(category)
			for frame in range(12):
				await get_tree().process_frame
			var stage := screen.find_child("FrostedStage", true, false) as Control
			var viewport_width: float = screen.get_viewport_rect().size.x
			assert(stage.size.x <= minf(1180.0, viewport_width - 32.0) + 1.0, "Glass must fit the viewport and stay bounded on wide phones")
			assert(stage.global_position.x >= 0.0 and stage.global_position.x + stage.size.x <= viewport_width, "Glass must not overflow horizontally")
	get_tree().root.content_scale_size = original_size

	screen.queue_free()
	await get_tree().process_frame
	get_tree().root.remove_meta("force_compact_layout")
	print("Learning activities mobile layout: PASS")
	get_tree().quit()
