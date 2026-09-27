extends Node

func _ready() -> void:
	print("Starting visual verification for LoginScreen and MainMenu Profile Dropdown...")
	call_deferred("_run_tests")

func _run_tests() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

	# 1. Test LoginScreen
	var login_scene := load("res://scenes/LoginScreen.tscn") as PackedScene
	var login_inst := login_scene.instantiate() as Control
	get_tree().root.add_child(login_inst)
	get_tree().root.size = Vector2i(1280, 720)
	
	await get_tree().create_timer(0.4).timeout
	var vp := get_tree().root.get_viewport()
	var img := vp.get_texture().get_image()
	img.save_png("res://captured_login_screen.png")
	print("Saved captured_login_screen.png")

	login_inst.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

	# 2. Test MainMenu with Account Dropdown open
	SecureDataManager.data["user_name"] = "Quách Thành Đạt"
	SecureDataManager.data["selected_instrument"] = "dan_tranh"
	SecureDataManager.data["daily_streak"] = 7
	SecureDataManager.data["total_points"] = 1240
	
	var menu_scene := load("res://scenes/MainMenu.tscn") as PackedScene
	var menu_inst := menu_scene.instantiate() as Control
	get_tree().root.add_child(menu_inst)
	
	await get_tree().create_timer(0.4).timeout
	
	# Open account dropdown
	if menu_inst.has_method("_open_account_menu"):
		menu_inst.call("_open_account_menu")
	
	await get_tree().create_timer(0.3).timeout
	
	var img2 := vp.get_texture().get_image()
	img2.save_png("res://captured_mainmenu_profile.png")
	print("Saved captured_mainmenu_profile.png")

	get_tree().quit(0)

