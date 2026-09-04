extends SceneTree

const ActivityHistoryScreen = preload("res://scripts/ActivityHistoryScreen.gd")

func _init() -> void:
	var screen := ActivityHistoryScreen.new()
	var quiz_pending := screen._map_pending({"kind": "quiz", "client_attempt_id": "q-1"})
	assert(quiz_pending.get("type") == "QUIZ")
	assert(quiz_pending.get("status") == "PENDING_SYNC")
	assert(quiz_pending.get("starsEarned", null) == null)
	var graded_quiz_pending := screen._map_pending({
		"kind": "quiz", "client_attempt_id": "q-2", "score": 100, "maxScore": 100,
	})
	assert(screen._score_text(graded_quiz_pending).begins_with("100/100"))
	assert(screen._accuracy_text(graded_quiz_pending) == "100%")
	var game_pending := screen._map_pending({"kind": "minigame", "score": 72, "client_attempt_id": "m-1"})
	assert(game_pending.get("type") == "MINIGAME")
	assert(game_pending.get("score") == 72)
	assert(screen._score_text({"score": 72, "maxScore": 100}) == "72/100 điểm")
	assert(screen._filter_label("PRACTICE") == "Luyện tập")
	print("ActivityHistoryScreen pending mapping PASS")
	quit()
