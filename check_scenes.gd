extends SceneTree

func _collect_files(directory: String, extension: String) -> Array[String]:
	var paths: Array[String] = []
	var dir := DirAccess.open(directory)
	if dir == null:
		return paths

	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var path := directory.path_join(entry)
		if dir.current_is_dir():
			paths.append_array(_collect_files(path, extension))
		elif entry.get_extension().to_lower() == extension:
			paths.append(path)
		entry = dir.get_next()
	dir.list_dir_end()
	paths.sort()
	return paths

func _init():
	var log_file := FileAccess.open("res://scenes_check_results.log", FileAccess.WRITE)
	if not log_file:
		printerr("Cannot open log file")
		quit(1)
		return
		
	log_file.store_line("--- Headless Verification for All Scenes ---")

	var has_error = false

	var scenes := _collect_files("res://scenes", "tscn")
	for path in scenes:
		# These reusable components reference the DS autoload at compile time.
		# Test them through a normal project run, where autoloads are available.
		if path.begins_with("res://scenes/components/"):
			continue
		var scene := load(path)
		if not scene is PackedScene:
			log_file.store_line("  [ERROR] FAILED to load: " + path)
			has_error = true
		else:
			log_file.store_line("  [OK] Loaded: " + path)
			var instance := (scene as PackedScene).instantiate()
			if instance == null:
				log_file.store_line("  [ERROR] FAILED to instantiate: " + path)
				has_error = true
			else:
				log_file.store_line("  [OK] Instantiated: " + path)
				instance.queue_free()

	log_file.store_line("--- Verification Complete (has_error = " + str(has_error) + ") ---")
	log_file.close()
	quit(1 if has_error else 0)
