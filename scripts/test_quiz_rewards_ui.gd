extends SceneTree

const AuthSessionStore = preload("res://scripts/AuthSession.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	AuthSessionStore.ensure_loaded()
	var scene := load("res://scenes/LearningQuizScreen.tscn") as PackedScene
	var screen := scene.instantiate()
	get_root().add_child(screen)
	await process_frame
	screen.result_sync_status = "be"
	screen._show_result("Quiz hoàn thành!", "Bạn trả lời đúng 2 / 2 câu. Số dư sao có thể dùng: 8.", 20, 3, Callable(screen, "_restart"), 100.0, 20, 4, true)
	var labels := _all_labels(screen.content_box)
	if not labels.has("+20") or not labels.has("+4") or not labels.has("Đến Phòng nhạc") or not labels.any(func(value: String) -> bool: return value.contains("Số dư sao có thể dùng: 8.")):
		printerr("Quiz rewards UI FAIL: ", labels)
		quit(1)
		return
	print("Quiz rewards UI PASS: actual XP/stars and music-room action")
	screen.queue_free()
	quit()

func _all_labels(node: Node) -> Array[String]:
	var labels: Array[String] = []
	if node is Label:
		labels.append((node as Label).text)
	if node is Button:
		labels.append((node as Button).text)
	for child in node.get_children():
		labels.append_array(_all_labels(child))
	return labels
