import re

with open('scripts/LessonDanBau.gd', 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Add C_CARD and C_MUTED
code = code.replace(
    'const C_TEXT_MUTED   := Color(0.13, 0.08, 0.05, 0.35)',
    'const C_TEXT_MUTED   := Color(0.13, 0.08, 0.05, 0.35)\nconst C_MUTED        := Color("#6f6257")\nconst C_CARD         := Color("#fffdf8")'
)

# 2. Top bar blur
top_bar_old = 'top_bar.add_theme_stylebox_override("panel", _flat(Color("#fffdf8"), Color(C_GOLD, 0.28), 0, 1))'
top_bar_new = '''
	var top_s := StyleBoxFlat.new()
	top_s.bg_color = Color(0.93, 0.91, 0.87, 0.6)
	top_s.border_color = Color(0.8, 0.78, 0.73, 0.8)
	top_s.border_width_bottom = 2
	top_bar.add_theme_stylebox_override("panel", top_s)
	
	var top_blur_mat = ShaderMaterial.new()
	var top_blur_shader = Shader.new()
	top_blur_shader.code = """
	shader_type canvas_item;
	uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
	uniform float lod: hint_range(0.0, 5.0) = 2.0;
	void fragment() {
		COLOR = textureLod(screen_texture, SCREEN_UV, lod);
	}
	"""
	top_blur_mat.shader = top_blur_shader
	var top_blur_rect = ColorRect.new()
	top_blur_rect.material = top_blur_mat
	top_blur_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top_blur_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_blur_rect.show_behind_parent = true
	top_bar.add_child(top_blur_rect)
	top_bar.move_child(top_blur_rect, 0)
'''
code = code.replace(top_bar_old, top_bar_new.strip())

# 3. Sidebar blur
sidebar_old = '''	var side_s := _flat(Color(0.95, 0.93, 0.89, 1.0), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.15), 0, 0)
	side_s.border_width_left = 0; side_s.border_width_top = 0; side_s.border_width_bottom = 0
	side_s.border_width_right = 2
	side_s.shadow_size = 12
	side_s.shadow_color = Color(0.13, 0.08, 0.05, 0.15)
	side_s.shadow_offset = Vector2(4, 0)
	sidebar.add_theme_stylebox_override("panel", side_s)'''
	
sidebar_new = '''	var side_s := StyleBoxFlat.new()
	side_s.bg_color = Color(0.93, 0.91, 0.87, 0.6)
	side_s.border_color = Color(0.8, 0.78, 0.73, 0.8)
	side_s.border_width_right = 2
	sidebar.add_theme_stylebox_override("panel", side_s)
	
	var blur_mat = ShaderMaterial.new()
	var blur_shader = Shader.new()
	blur_shader.code = """
	shader_type canvas_item;
	uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
	uniform float lod: hint_range(0.0, 5.0) = 2.0;
	void fragment() {
		COLOR = textureLod(screen_texture, SCREEN_UV, lod);
	}
	"""
	blur_mat.shader = blur_shader
	var blur_rect = ColorRect.new()
	blur_rect.material = blur_mat
	blur_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blur_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blur_rect.show_behind_parent = true
	sidebar.add_child(blur_rect)
	sidebar.move_child(blur_rect, 0)'''
code = code.replace(sidebar_old, sidebar_new)

# 4. Update the _build_lesson_list where v_btn and p_btn are created
lesson_list_old = '''		if is_v_completed:
			v_btn.text = "🎬\\nHướng dẫn\\n✓"
		elif not is_v_unlocked:
			v_btn.text = "🔒"
		else:
			v_btn.text = "🎬\\nHướng dẫn\\n(%s)" % lesson_item["note"]
			
		_style_circle_btn(v_btn, is_v_unlocked, is_v_completed)
		_make_btn_bouncy(v_btn)
		row.add_child(v_btn)
		
		v_btn.pressed.connect(_on_video_pressed.bind(v_id, lesson_item["subtitles"], is_v_unlocked))
		
		# 2. Thực Hành Button (Right circle)
		var p_btn := Button.new()
		p_btn.name = "PracticeBtn"
		p_btn.custom_minimum_size = Vector2(180, 180)
		p_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		p_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		p_btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		if is_p_completed:
			p_btn.text = "🎵\\nThực hành\\n✓"
		elif not is_p_unlocked:
			p_btn.text = "🔒"
		else:
			p_btn.text = "🎵\\nThực hành\\n(%s)" % lesson_item["note"]
			
		_style_circle_btn(p_btn, is_p_unlocked, is_p_completed)
		_make_btn_bouncy(p_btn)
		row.add_child(p_btn)'''

lesson_list_new = '''		_setup_circle_btn(v_btn, "Hướng dẫn", lesson_item["note"], is_v_unlocked, is_v_completed, "video")
		row.add_child(v_btn)
		v_btn.pressed.connect(_on_video_pressed.bind(v_id, lesson_item["subtitles"], is_v_unlocked))
		
		# 2. Thực Hành Button (Right circle)
		var p_btn := Button.new()
		p_btn.name = "PracticeBtn"
		p_btn.custom_minimum_size = Vector2(180, 180)
		p_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		p_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		p_btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		_setup_circle_btn(p_btn, "Thực hành", lesson_item["note"], is_p_unlocked, is_p_completed, "practice")
		row.add_child(p_btn)'''
		
code = code.replace(lesson_list_old, lesson_list_new)

# 5. Redefine _style_circle_btn and add _setup_circle_btn
style_btn_old = '''func _style_circle_btn(btn: Button, is_unlocked: bool, is_completed: bool) -> void:
	# Jade Green & Gold Traditional Lacquer Theme
	var bg_color := Color(0.95, 0.93, 0.89, 0.6) # Light warm gray-cream for locked
	var border_color := Color(0.85, 0.82, 0.78, 1.0) # Gray border for locked
	var text_color := C_TEXT_MUTED # Translucent charcoal text for locked
	
	if is_completed:
		bg_color = C_JADE # Solid Jade Green for completed
		border_color = C_GOLD # Gold border
		text_color = Color.WHITE # White checkmark/text inside
	elif is_unlocked:
		bg_color = Color.WHITE # Solid white for active
		border_color = C_JADE_LIGHT # Jade border
		text_color = C_TEXT # Dark charcoal text
		
	var s_normal := StyleBoxFlat.new()
	s_normal.bg_color = bg_color
	s_normal.border_color = border_color
	s_normal.border_width_left = 6; s_normal.border_width_right = 6
	s_normal.border_width_top = 6; s_normal.border_width_bottom = 6
	s_normal.corner_radius_top_left = 90; s_normal.corner_radius_top_right = 90
	s_normal.corner_radius_bottom_left = 90; s_normal.corner_radius_bottom_right = 90
	
	# Glow effect for active step (using softer, wider gold shadow)
	if is_unlocked and not is_completed:
		s_normal.shadow_size = 24
		s_normal.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35)
		
	var s_hover := s_normal.duplicate() as StyleBoxFlat
	if is_unlocked:
		if is_completed:
			s_hover.bg_color = bg_color.lightened(0.1)
		else:
			s_hover.bg_color = Color(0.97, 0.97, 0.97, 1.0)
		
	btn.add_theme_stylebox_override("normal", s_normal)
	btn.add_theme_stylebox_override("hover", s_hover)
	btn.add_theme_stylebox_override("pressed", s_normal)
	btn.add_theme_stylebox_override("disabled", s_normal)
	btn.add_theme_color_override("font_color", text_color)
	btn.add_theme_color_override("font_hover_color", C_JADE if (is_unlocked and not is_completed) else text_color)
	btn.add_theme_color_override("font_pressed_color", text_color)
	btn.add_theme_color_override("font_disabled_color", text_color)
	
	var f_bold := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if f_bold:
		btn.add_theme_font_override("font", f_bold)
	btn.add_theme_font_size_override("font_size", 18)
	
	btn.disabled = not is_unlocked'''

style_btn_new = '''func _setup_circle_btn(btn: Button, action: String, lesson_title: String, unlocked: bool, completed: bool, type: String) -> void:
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if unlocked else Control.CURSOR_ARROW
	btn.disabled = not unlocked

	if completed:
		btn.text = "\\n\\n%s\\nHoàn thành" % action
	elif unlocked:
		btn.text = "\\n\\n%s\\n(%s)" % [action, lesson_title]
	else:
		btn.text = ""

	var bg_color := Color(0.95, 0.93, 0.89, 0.35) # Locked: Glassmorphism
	var border_color := Color(0.85, 0.82, 0.78, 0.5)
	var text_color := Color(C_MUTED, 0.8)
	
	if completed:
		bg_color = C_JADE
		border_color = C_GOLD
		text_color = Color.WHITE
	elif unlocked:
		bg_color = C_CARD
		border_color = C_JADE
		text_color = C_TEXT

	var s_normal := StyleBoxFlat.new()
	s_normal.bg_color = bg_color
	s_normal.border_color = border_color
	s_normal.border_width_left = 6; s_normal.border_width_right = 6
	s_normal.border_width_top = 6; s_normal.border_width_bottom = 6
	s_normal.corner_radius_top_left = 90; s_normal.corner_radius_top_right = 90
	s_normal.corner_radius_bottom_left = 90; s_normal.corner_radius_bottom_right = 90
	
	if unlocked and not completed:
		s_normal.shadow_size = 24
		s_normal.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.35)
		
	var s_hover := s_normal.duplicate() as StyleBoxFlat
	if unlocked:
		if completed:
			s_hover.bg_color = bg_color.lightened(0.1)
		else:
			s_hover.bg_color = Color(0.97, 0.97, 0.97, 1.0)

	btn.add_theme_stylebox_override("normal", s_normal)
	btn.add_theme_stylebox_override("hover", s_hover)
	btn.add_theme_stylebox_override("pressed", s_normal)
	btn.add_theme_stylebox_override("disabled", s_normal)
	btn.add_theme_color_override("font_color", text_color)
	
	var hover_color = text_color
	if unlocked and not completed: hover_color = C_JADE
	btn.add_theme_color_override("font_hover_color", hover_color)
	btn.add_theme_color_override("font_pressed_color", text_color)
	btn.add_theme_color_override("font_disabled_color", text_color)
	
	var f_bold := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if f_bold:
		btn.add_theme_font_override("font", f_bold)
	btn.add_theme_font_size_override("font_size", 18)

	btn.draw.connect(func():
		var tex_name = ""
		if not unlocked: tex_name = "lock"
		elif completed: tex_name = "check-circle"
		else: tex_name = "play-circle" if type == "video" else "music"
		
		var tex = load("res://assets/textures/lucide/" + tex_name + ".svg") as Texture2D
		if tex:
			var w = 32.0
			var rect = Rect2((btn.size.x - w) / 2.0, 32.0, w, w)
			
			var draw_color = text_color
			if unlocked and not completed and btn.is_hovered():
				draw_color = C_JADE
			
			btn.draw_texture_rect(tex, rect, false, draw_color)
	)
	_make_btn_bouncy(btn)'''

code = code.replace(style_btn_old, style_btn_new)

with open('scripts/LessonDanBau.gd', 'w', encoding='utf-8') as f:
    f.write(code)

print("Done")
