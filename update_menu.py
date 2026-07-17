import sys

file_path = "d:/vietstage25d/scripts/MainMenu.gd"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# 1. Remove the old gui_input bindings for card_basic and card_essentials
old_gui_input = """	# Card Clicks
	card_basic.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			SecureDataManager.active_lesson_id = "Node1"
			_fade_to("res://scenes/VideoPlayer.tscn")
	)
	card_essentials.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			var inst := str(SecureDataManager.data.get("selected_instrument", "dan_tranh"))
			if SecureDataManager.is_lesson_completed(inst, "Node2"):
				SecureDataManager.active_lesson_id = "Node3"
				_go_practice_room_for_node(3)
			else:
				SecureDataManager.active_lesson_id = "Node2"
				_go_practice_room_for_node(2)
	)"""

if old_gui_input in content:
    content = content.replace(old_gui_input, "\t# Card clicks are now handled by individual lesson nodes inside the cards")
else:
    print("Could not find old gui_input block!")

# 2. Add a call to build lesson paths at the end of _build_roadmap_cards
old_build_end = """	# ── Style Card Pop Chords ────────────────────────────────────────────────
	var pop_sb := _flat(C_CARD_BG, Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.40), 20)
	pop_sb.border_width_left = 2; pop_sb.border_width_right = 2
	pop_sb.border_width_top = 2; pop_sb.border_width_bottom = 2
	card_pop_chords.add_theme_stylebox_override("panel", pop_sb)
	pop_chords_title.add_theme_color_override("font_color", C_CREAM)
	pop_chords_desc.add_theme_color_override("font_color", C_TEXT_MUTED)"""

new_build_end = old_build_end + """
	
	# Generate individual lesson nodes inside the cards
	var max_unlocked = _get_max_unlocked_node(instrument)
	_build_lesson_path_for_card(card_basic, 1, 2, max_unlocked)
	_build_lesson_path_for_card(card_essentials, 3, 3, max_unlocked)"""

if old_build_end in content:
    content = content.replace(old_build_end, new_build_end)
else:
    print("Could not find old build end block!")

# 3. Add the new functions at the end of the file
new_funcs = """
# ─── Dynamic Lesson Path Generation ──────────────────────────────────────────
func _get_max_unlocked_node(inst: String) -> int:
	if SecureDataManager.is_lesson_completed(inst, "Node4"): return 5
	if SecureDataManager.is_lesson_completed(inst, "Node3"): return 4
	if SecureDataManager.is_lesson_completed(inst, "Node2"): return 3
	if SecureDataManager.is_lesson_completed(inst, "Node1"): return 2
	return 1

func _build_lesson_path_for_card(card: PanelContainer, start_node_id: int, lesson_count: int, unlocked_up_to: int) -> void:
	var text_v = card.get_node_or_null("Margin/Row/TextV")
	if not text_v: return
	
	# Try to find existing path if any
	var existing = text_v.get_node_or_null("LessonPathWrapper")
	if existing:
		existing.queue_free()
		
	var details = text_v.get_node_or_null("Details")
	if details:
		details.visible = false
		
	var visual = card.get_node_or_null("Margin/Row/Visual")
	if visual:
		visual.visible = false
		
	var m = MarginContainer.new()
	m.name = "LessonPathWrapper"
	m.add_theme_constant_override("margin_top", 16)
	
	var path_box = HBoxContainer.new()
	path_box.name = "LessonPath"
	path_box.add_theme_constant_override("separation", 12)
	path_box.alignment = BoxContainer.ALIGNMENT_CENTER
	path_box.custom_minimum_size.y = 70
	m.add_child(path_box)
	text_v.add_child(m)
	
	for i in range(lesson_count):
		var node_id = start_node_id + i
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(50, 50)
		btn.text = str(i + 1)
		
		var is_locked = (node_id > unlocked_up_to)
		var is_completed = (node_id < unlocked_up_to)
		var is_current = (node_id == unlocked_up_to)
		
		var sb = StyleBoxFlat.new()
		sb.corner_radius_top_left = 25
		sb.corner_radius_top_right = 25
		sb.corner_radius_bottom_left = 25
		sb.corner_radius_bottom_right = 25
		
		if is_locked:
			sb.bg_color = Color(0.15, 0.1, 0.08, 1.0) # Dark mahogany
			btn.add_theme_color_override("font_color", Color(0.5, 0.4, 0.3, 1.0))
		else:
			if is_completed:
				sb.bg_color = Color(0.3, 0.69, 0.49, 1.0) # Jade
			else:
				sb.bg_color = Color(0.76, 0.42, 0.23, 1.0) # Terracotta
			btn.add_theme_color_override("font_color", Color.WHITE)
			btn.pressed.connect(func():
				SecureDataManager.active_lesson_id = "Node" + str(node_id)
				if node_id == 1:
					_fade_to("res://scenes/VideoPlayer.tscn")
				else:
					_go_practice_room_for_node(node_id)
			)
			_make_btn_bouncy(btn)
			
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		
		path_box.add_child(btn)
		
		if i < lesson_count - 1:
			var line = ColorRect.new()
			line.custom_minimum_size = Vector2(40, 4)
			line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			if is_locked or is_current:
				line.color = Color(0.2, 0.15, 0.1, 1.0)
			else:
				line.color = Color(0.3, 0.69, 0.49, 1.0)
			path_box.add_child(line)
"""

if "_build_lesson_path_for_card" not in content:
    content += new_funcs

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
print("Updated MainMenu.gd successfully!")
