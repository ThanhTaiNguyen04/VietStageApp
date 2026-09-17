extends SceneTree

# Run: godot --headless --path . --script res://tests/test_bundled_lesson_data.gd
const DAN = preload("res://scripts/DanTranhBundledLessonData.gd")
const SAO = preload("res://scripts/SaoTrucBundledLessonData.gd")

func _init() -> void:
	assert(not DAN.LEVELS.is_empty())
	assert(not DAN.LESSON_DIALOGUES.is_empty())
	assert(DAN.ALL_17_NOTES.size() == 17)
	assert(DAN.SU_THANH_HOA_SHEET.size() == DAN.SU_THANH_HOA_DURATIONS.size())
	assert(not SAO.ALL_LESSONS.is_empty())
	assert(not SAO.LESSON_DIALOGUES.is_empty())
	assert(not SAO.LESSON_NOTES.is_empty())
	for song in SAO.PRACTICE_SONGS_LIST:
		assert(song["sheet"].size() == song["durations"].size())
	var songs: Array[Dictionary] = SAO.PRACTICE_SONGS_LIST.duplicate(true)
	var original_title: String = SAO.PRACTICE_SONGS_LIST[0]["title"]
	songs[0]["title"] = "changed runtime copy"
	assert(SAO.PRACTICE_SONGS_LIST[0]["title"] == original_title)
	print("Bundled lesson data: PASS")
	quit()
