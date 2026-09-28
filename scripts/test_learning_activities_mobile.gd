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

	screen.queue_free()
	await get_tree().process_frame
	get_tree().root.remove_meta("force_compact_layout")
	print("Learning activities mobile layout: PASS")
	get_tree().quit()
