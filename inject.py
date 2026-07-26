import sys

def inject(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    if 'var btn_leaderboard : Button' not in content:
        content = content.replace('var btn_minigame_mob : Button', 'var btn_minigame_mob : Button\nvar btn_leaderboard : Button\nvar btn_leaderboard_mob : Button')

    creation_code = '''
	# Programmatic instantiation of Leaderboard button
	btn_leaderboard = Button.new()
	btn_leaderboard.name = "BtnLeaderboard"
	btn_leaderboard.text = "Xếp hạng"
	btn_leaderboard.flat = true
	btn_leaderboard.custom_minimum_size = Vector2(220, 140)
	side_v.add_child(btn_leaderboard)
	side_v.move_child(btn_leaderboard, 6) # after BtnMinigame

	btn_leaderboard_mob = Button.new()
	btn_leaderboard_mob.name = "BtnLeaderboardMobile"
	btn_leaderboard_mob.text = "Xếp hạng"
	btn_leaderboard_mob.flat = true
	btn_leaderboard_mob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_h.add_child(btn_leaderboard_mob)
	bottom_h.move_child(btn_leaderboard_mob, 4)
'''
    if 'btn_leaderboard = Button.new()' not in content:
        target_str = 'bottom_h.move_child(btn_minigame_mob, 3) # after BtnSongsMobile (index 2)'
        content = content.replace(target_str, target_str + '\n' + creation_code)

    if '_style_bottom_icon_btn(btn_leaderboard_mob, false)' not in content:
        content = content.replace('_style_bottom_icon_btn(btn_minigame_mob, false)', '_style_bottom_icon_btn(btn_minigame_mob, false)\n\t_style_bottom_icon_btn(btn_leaderboard_mob, false)')

    if '_attach_bottom_icon_draw(btn_leaderboard_mob, 4)' not in content:
        content = content.replace('_attach_bottom_icon_draw(btn_minigame_mob, 3)', '_attach_bottom_icon_draw(btn_minigame_mob, 3)\n\t_attach_bottom_icon_draw(btn_leaderboard_mob, 4)')

    if '_style_side_icon_btn(btn_leaderboard, false)' not in content:
        content = content.replace('_style_side_icon_btn(btn_minigame, false)', '_style_side_icon_btn(btn_minigame, false)\n\t_style_side_icon_btn(btn_leaderboard, false)')

    if '_attach_icon_draw(btn_leaderboard, 4)' not in content:
        content = content.replace('_attach_icon_draw(btn_minigame, 3)', '_attach_icon_draw(btn_minigame, 3)\n\t_attach_icon_draw(btn_leaderboard, 4)')

    if 'btn_leaderboard.pressed.connect(_on_btn_leaderboard_pressed)' not in content:
        content = content.replace('btn_minigame.pressed.connect(func() -> void: _fade_to("res://scenes/MiniGame.tscn"))', 'btn_minigame.pressed.connect(func() -> void: _fade_to("res://scenes/MiniGame.tscn"))\n\tbtn_leaderboard.pressed.connect(_on_btn_leaderboard_pressed)')

    if 'btn_leaderboard_mob.pressed.connect(_on_btn_leaderboard_pressed)' not in content:
        content = content.replace('btn_minigame_mob.pressed.connect(func() -> void: _fade_to("res://scenes/MiniGame.tscn"))', 'btn_minigame_mob.pressed.connect(func() -> void: _fade_to("res://scenes/MiniGame.tscn"))\n\tbtn_leaderboard_mob.pressed.connect(_on_btn_leaderboard_pressed)')

    content = content.replace('for btn in [btn_courses, btn_room, btn_songs, btn_minigame, btn_account]:', 'for btn in [btn_courses, btn_room, btn_songs, btn_minigame, btn_account, btn_leaderboard]:')
    content = content.replace('for btn in [btn_courses_mob, btn_room_mob, btn_songs_mob, btn_minigame_mob, btn_account_mob]:', 'for btn in [btn_courses_mob, btn_room_mob, btn_songs_mob, btn_minigame_mob, btn_account_mob, btn_leaderboard_mob]:')

    if 'elif active == btn_leaderboard or active == btn_leaderboard_mob: active_desktop = btn_leaderboard' not in content:
        content = content.replace('elif active == btn_minigame or active == btn_minigame_mob: active_desktop = btn_minigame', 'elif active == btn_minigame or active == btn_minigame_mob: active_desktop = btn_minigame\n\telif active == btn_leaderboard or active == btn_leaderboard_mob: active_desktop = btn_leaderboard')
    
    content = content.replace('var all : Array[Button] = [btn_courses, btn_room, btn_songs, btn_minigame, btn_account]', 'var all : Array[Button] = [btn_courses, btn_room, btn_songs, btn_minigame, btn_account, btn_leaderboard]')

    handler = '''
func _on_btn_leaderboard_pressed() -> void:
	var popup = load("res://scripts/LeaderboardPopup.gd").new()
	popup.setup(InstrumentSelect.selected_instrument)
	add_child(popup)
'''
    if 'func _on_btn_leaderboard_pressed' not in content:
        content += handler

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

inject('d:/2.IT-FPT-EDU/1.Subject-Mon Hoc/SEP_Capstone/2.Project_SEP/1.Main_SEP/VietStageApp/scripts/MainMenu.gd')
print('Injected MainMenu.gd')
