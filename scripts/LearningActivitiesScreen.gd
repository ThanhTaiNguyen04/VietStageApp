extends "res://scripts/LearningActivityBase.gd"

var _canonical_lesson_id := 0
var _online_content := false
var _available := {"quiz_note": true, "quiz_knowledge": true, "rhythm": true, "melody": true}
var _quiz_count := 0
var _note_quiz_count := 0
var _knowledge_quiz_count := 0
var _rhythm_count := 0
var _melody_count := 0
var _current_category := ""

func _ready() -> void:
	super._ready()
	Context.activity = ""
	title_label.text = "HOẠT ĐỘNG BÀI HỌC"
	await _load_activity_content()
	_render()

## Attempts are submitted per activity. This screen only discovers which
## activities exist in the selected lesson and must not submit an assessment.
func _load_activity_content() -> void:
	Context.ensure_defaults()
	var report := _report()
	if report == null or not report.is_signed_in() or Context.local_lesson_ids.is_empty():
		return
	if SecureDataManager.be_catalog.is_empty():
		await report.fetch_and_install_catalog()
	var lesson := SecureDataManager.resolve_be_lesson_exact(Context.instrument, Context.local_lesson_ids[0])
	if lesson.is_empty():
		return
	Context.set_backend_lesson(lesson)
	_canonical_lesson_id = Context.backend_lesson_id
	if _canonical_lesson_id <= 0:
		return
	var quizzes: Array = await report.ensure_quizzes(_canonical_lesson_id)
	var minigames: Array = await report.ensure_minigame_list(_canonical_lesson_id)
	_online_content = not quizzes.is_empty() or not minigames.is_empty()
	_quiz_count = quizzes.size()
	_note_quiz_count = _count_quizzes(quizzes, "NOTE_IDENTIFICATION")
	_knowledge_quiz_count = _quiz_count - _note_quiz_count
	_rhythm_count = _count_challenges(minigames, ["RHYTHM_MATCH", "RHYTHM_MATCHING", "RHYTHM"])
	_melody_count = _count_challenges(minigames, ["MELODY_COMPLETION", "MELODY_COMPLETE", "MELODY"])
	_available["quiz_note"] = _note_quiz_count > 0
	_available["quiz_knowledge"] = _knowledge_quiz_count > 0
	_available["rhythm"] = _rhythm_count > 0
	_available["melody"] = _melody_count > 0

func _create_frosted_stage(is_mobile: bool) -> Dictionary:
	var stage_panel := PanelContainer.new()
	stage_panel.name = "FrostedStage"
	stage_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL if is_mobile else Control.SIZE_SHRINK_CENTER
	stage_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if not is_mobile:
		stage_panel.custom_minimum_size = Vector2(1180, 0)

	var stage_sb := StyleBoxFlat.new()
	stage_sb.bg_color = Color(1.0, 0.99, 0.97, 0.52) # Soft translucent frosted glass
	stage_sb.border_color = Color(0.77, 0.58, 0.15, 0.35) # Antique lacquer gold hairline border
	stage_sb.set_border_width_all(1)
	stage_sb.set_corner_radius_all(32)
	stage_sb.shadow_size = 28
	stage_sb.shadow_color = Color(0.08, 0.14, 0.10, 0.14) # Soft ambient diffused shadow
	stage_sb.shadow_offset = Vector2(0, 8)
	stage_panel.add_theme_stylebox_override("panel", stage_sb)

	# Frosted blur shader behind stage
	var blur_mat := ShaderMaterial.new()
	var blur_shader := Shader.new()
	blur_shader.code = """
	shader_type canvas_item;
	uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
	uniform float lod: hint_range(0.0, 5.0) = 2.4;
	void fragment() {
		COLOR = textureLod(screen_texture, SCREEN_UV, lod);
	}
	"""
	blur_mat.shader = blur_shader
	var blur_rect := ColorRect.new()
	blur_rect.name = "StageBlurRect"
	blur_rect.material = blur_mat
	blur_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blur_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blur_rect.show_behind_parent = true
	stage_panel.add_child(blur_rect)

	var stage_margin := MarginContainer.new()
	stage_margin.name = "StageMargin"
	stage_margin.add_theme_constant_override("margin_left", 24 if is_mobile else 42)
	stage_margin.add_theme_constant_override("margin_right", 24 if is_mobile else 42)
	stage_margin.add_theme_constant_override("margin_top", 28 if is_mobile else 36)
	stage_margin.add_theme_constant_override("margin_bottom", 28 if is_mobile else 36)
	stage_panel.add_child(stage_margin)

	var stage_vbox := VBoxContainer.new()
	stage_vbox.name = "StageVBox"
	stage_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	stage_vbox.add_theme_constant_override("separation", 22)
	stage_margin.add_child(stage_vbox)

	return {"panel": stage_panel, "vbox": stage_vbox}

func _create_eyebrow(pill_text: String) -> PanelContainer:
	var badge_pill := PanelContainer.new()
	badge_pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var b_sb := StyleBoxFlat.new()
	b_sb.bg_color = Color(0.77, 0.58, 0.15, 0.12)
	b_sb.border_color = Color(0.85, 0.68, 0.22, 0.45)
	b_sb.set_border_width_all(1)
	b_sb.set_corner_radius_all(14)
	b_sb.content_margin_left = 16
	b_sb.content_margin_right = 16
	b_sb.content_margin_top = 5
	b_sb.content_margin_bottom = 5
	badge_pill.add_theme_stylebox_override("panel", b_sb)

	var badge_lbl := Label.new()
	badge_lbl.text = pill_text.to_upper()
	badge_lbl.add_theme_font_size_override("font_size", 12)
	var font_b := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if font_b: badge_lbl.add_theme_font_override("font", font_b)
	badge_lbl.add_theme_color_override("font_color", Color(0.68, 0.45, 0.08))
	badge_pill.add_child(badge_lbl)
	return badge_pill

func _create_accent_divider() -> ColorRect:
	var div := ColorRect.new()
	div.custom_minimum_size = Vector2(100, 3)
	div.color = Color(0.85, 0.68, 0.22, 0.50)
	div.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return div

func _render() -> void:
	_current_category = ""
	for child in content_box.get_children():
		content_box.remove_child(child)
		child.queue_free()
	content_box.alignment = BoxContainer.ALIGNMENT_CENTER
	content_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var mobile := get_viewport_rect().size.x < 650.0

	var stage := _create_frosted_stage(mobile)
	content_box.add_child(stage["panel"])
	var stage_v := stage["vbox"] as VBoxContainer

	# Eyebrow tag
	stage_v.add_child(_create_eyebrow("%s · LUYỆN TẬP TƯƠNG TÁC" % _instrument_title()))

	# Header VBox
	var header_v := VBoxContainer.new()
	header_v.alignment = BoxContainer.ALIGNMENT_CENTER
	header_v.add_theme_constant_override("separation", 6)
	stage_v.add_child(header_v)

	var title_h := Label.new()
	title_h.text = "HOẠT ĐỘNG LUYỆN TẬP"
	title_h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_h.add_theme_font_size_override("font_size", 26 if mobile else 30)
	var font_b := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if font_b: title_h.add_theme_font_override("font", font_b)
	title_h.add_theme_color_override("font_color", C_NAVY)
	header_v.add_child(title_h)

	var summary := Label.new()
	summary.text = _summary_text()
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.add_theme_font_size_override("font_size", 15 if mobile else 16)
	summary.add_theme_color_override("font_color", Color(0.35, 0.38, 0.35))
	header_v.add_child(summary)

	stage_v.add_child(_create_accent_divider())

	var is_stacked := get_viewport_rect().size.x < 1180.0
	var cards_row := BoxContainer.new()
	cards_row.vertical = is_stacked
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_row.add_theme_constant_override("separation", 24 if not is_stacked else 16)
	stage_v.add_child(cards_row)

	var quiz_meta := ("%d câu hỏi" % _quiz_count) if _quiz_count > 0 else "2 dạng bài"
	var minigame_count := _rhythm_count + _melody_count
	var minigame_meta := ("%d thử thách" % minigame_count) if minigame_count > 0 else "2 trò chơi"

	var quiz_items := [
		{"icon": "quiz", "text": quiz_meta},
		{"icon": "star", "text": "Kiến thức & Cảm âm"}
	]
	var minigame_items := [
		{"icon": "game", "text": minigame_meta},
		{"icon": "music", "text": "Nhịp điệu & Giai điệu"}
	]

	cards_row.add_child(_activity_card(
		"TRẮC NGHIỆM KIẾN THỨC",
		"Quiz",
		"Luyện tập nhận diện nốt nhạc và củng cố kiến thức nhạc cụ qua các câu hỏi tương tác.",
		quiz_items,
		"quiz_menu",
		"quiz"
	))

	cards_row.add_child(_activity_card(
		"TRÒ CHƠI ÂM NHẠC",
		"Minigame",
		"Rèn phản xạ phách nhịp và khả năng nghe ghép giai điệu truyền thống sống động.",
		minigame_items,
		"minigame_menu",
		"game"
	))

func _render_category_picker(category: String) -> void:
	_current_category = category
	for child in content_box.get_children():
		content_box.remove_child(child)
		child.queue_free()
	content_box.alignment = BoxContainer.ALIGNMENT_CENTER
	content_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var mobile := get_viewport_rect().size.x < 650.0
	var is_quiz := category == "quiz"

	var stage := _create_frosted_stage(mobile)
	content_box.add_child(stage["panel"])
	var stage_v := stage["vbox"] as VBoxContainer

	# Eyebrow tag
	stage_v.add_child(_create_eyebrow("DẠNG BÀI TRẮC NGHIỆM" if is_quiz else "TRÒ CHƠI ÂM NHẠC"))

	var header_v := VBoxContainer.new()
	header_v.alignment = BoxContainer.ALIGNMENT_CENTER
	header_v.add_theme_constant_override("separation", 6)
	stage_v.add_child(header_v)

	var heading := Label.new()
	heading.text = "CHỌN DẠNG BÀI QUIZ" if is_quiz else "CHỌN TRÒ CHƠI MINIGAME"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 26 if mobile else 30)
	var font_b := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	if font_b: heading.add_theme_font_override("font", font_b)
	heading.add_theme_color_override("font_color", C_NAVY)
	header_v.add_child(heading)

	var subtitle := Label.new()
	subtitle.text = "Mỗi hoạt động có thử thách và lưu kết quả đánh giá riêng." if is_quiz else "Chọn trò chơi để bắt đầu rèn luyện kỹ năng âm nhạc."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 15 if mobile else 16)
	subtitle.add_theme_color_override("font_color", Color(0.35, 0.38, 0.35))
	header_v.add_child(subtitle)

	stage_v.add_child(_create_accent_divider())

	var is_stacked := get_viewport_rect().size.x < 1180.0
	var cards_row := BoxContainer.new()
	cards_row.vertical = is_stacked
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_row.add_theme_constant_override("separation", 24 if not is_stacked else 16)
	stage_v.add_child(cards_row)

	if is_quiz:
		var note_meta := ("%d câu hỏi" % _note_quiz_count) if _note_quiz_count > 0 else "Nhận biết nốt"
		var knowledge_meta := ("%d câu hỏi" % _knowledge_quiz_count) if _knowledge_quiz_count > 0 else "Kiến thức nhạc cụ"

		var q1_items := [
			{"icon": "quiz", "text": note_meta},
			{"icon": "star", "text": "Luyện tai cảm âm"}
		]
		var q2_items := [
			{"icon": "quiz", "text": knowledge_meta},
			{"icon": "star", "text": "Nhạc lý & Cấu tạo"}
		]
		cards_row.add_child(_activity_card(
			"DẠNG BÀI 1",
			"Nhận diện nốt nhạc",
			"Luyện nghe và chọn đúng cao độ, vị trí của nốt nhạc trên đàn.",
			q1_items,
			"quiz_note",
			"quiz"
		))
		cards_row.add_child(_activity_card(
			"DẠNG BÀI 2",
			"Kiến thức nhạc cụ",
			"Ôn lại cấu tạo, kỹ thuật diễn tấu và văn hóa nhạc cụ truyền thống.",
			q2_items,
			"quiz_knowledge",
			"quiz"
		))
	else:
		var rhythm_meta := ("%d thử thách" % _rhythm_count) if _rhythm_count > 0 else "Thử thách nhịp"
		var melody_meta := ("%d giai điệu" % _melody_count) if _melody_count > 0 else "Ghép giai điệu"

		var m1_items := [
			{"icon": "game", "text": rhythm_meta},
			{"icon": "star", "text": "Giữ nhịp & Phách"}
		]
		var m2_items := [
			{"icon": "melody", "text": melody_meta},
			{"icon": "star", "text": "Hoàn thiện câu nhạc"}
		]
		cards_row.add_child(_activity_card(
			"TRÒ CHƠI 1",
			"Thử thách nhịp điệu",
			"Nghe mẫu tiết tấu, quan sát phách và gõ chính xác theo nhịp bài hát.",
			m1_items,
			"rhythm",
			"game"
		))
		cards_row.add_child(_activity_card(
			"TRÒ CHƠI 2",
			"Hoàn thiện giai điệu",
			"Lắng nghe câu nhạc truyền thống và chọn nốt còn thiếu để tạo bài hoàn chỉnh.",
			m2_items,
			"melody",
			"melody"
		))

func _summary_text() -> String:
	if _canonical_lesson_id <= 0:
		return "Bài học ngoại tuyến · kết quả chỉ lưu trên thiết bị"
	return "Kết quả của từng hoạt động được lưu và đồng bộ riêng"

func _create_details_hbox(meta_items: Array, is_locked: bool) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	var text_color: Color = Color(0.52, 0.40, 0.15) if not is_locked else Color(0.35, 0.40, 0.35, 0.90)

	for i in range(meta_items.size()):
		var item: Dictionary = meta_items[i]
		var icon_name: String = item.get("icon", "")
		var text: String = item.get("text", "")
		if not icon_name.is_empty():
			var tex: Texture2D = _icons8_texture(icon_name)
			if tex == null:
				var icon_path := "res://assets/textures/lucide/" + icon_name + ".svg"
				if ResourceLoader.exists(icon_path):
					tex = load(icon_path) as Texture2D
			if tex != null:
				var tr := TextureRect.new()
				tr.texture = tex
				tr.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
				tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				tr.custom_minimum_size = Vector2(20, 20)
				tr.modulate = text_color
				hbox.add_child(tr)
		if not text.is_empty():
			var lbl := Label.new()
			lbl.text = text
			lbl.add_theme_font_size_override("font_size", 16)
			lbl.add_theme_color_override("font_color", text_color)
			hbox.add_child(lbl)
		if i < meta_items.size() - 1:
			var div := Label.new()
			div.text = "|"
			div.add_theme_font_size_override("font_size", 16)
			div.add_theme_color_override("font_color", Color(text_color.r, text_color.g, text_color.b, 0.5))
			hbox.add_child(div)
	return hbox

func _create_visual_emblem(icon_name: String, is_locked: bool) -> Control:
	var vis := Control.new()
	vis.custom_minimum_size = Vector2(96, 96)
	vis.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vis.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var icon_tex: Texture2D = _icons8_texture(icon_name)
	if icon_tex == null:
		var icon_path := "res://assets/textures/lucide/" + icon_name + ".svg"
		if ResourceLoader.exists(icon_path):
			icon_tex = load(icon_path) as Texture2D

	vis.draw.connect(func() -> void:
		var cx := vis.size.x / 2.0
		var cy := vis.size.y / 2.0
		var r := 40.0
		# Outer subtle ring
		var bg_color := Color(0.77, 0.58, 0.15, 0.20) if not is_locked else Color(0.18, 0.22, 0.19, 0.12)
		vis.draw_arc(Vector2(cx, cy), r, 0, TAU, 36, bg_color, 7.0, true)

		if not is_locked:
			# Gold glowing arc (matching level card rings)
			vis.draw_arc(Vector2(cx, cy), r, -PI/2.0, -PI/2.0 + TAU * 0.85, 36, Color(0.77, 0.58, 0.15, 1.0), 7.0, true)

		# Center Icon
		if icon_tex:
			var icon_sz := Vector2(40, 40)
			var icon_rect := Rect2(Vector2(cx - icon_sz.x / 2.0, cy - icon_sz.y / 2.0), icon_sz)
			var icon_tint := Color(0.09, 0.25, 0.18) if not is_locked else Color(0.18, 0.22, 0.19, 0.70)
			vis.draw_texture_rect(icon_tex, icon_rect, false, icon_tint)
	)
	return vis

func _activity_card(kicker: String, heading: String, description: String, meta_items: Array, activity_id: String, icon_lucide: String, _is_primary: bool = true) -> PanelContainer:
	var mobile := get_viewport_rect().size.x < 650.0
	var is_stacked := get_viewport_rect().size.x < 1180.0
	var menu_card := activity_id in ["quiz_menu", "minigame_menu"]
	var locked := not menu_card and _canonical_lesson_id > 0 and _online_content and not bool(_available.get(activity_id, false))

	var card := PanelContainer.new()
	if is_stacked:
		card.custom_minimum_size = Vector2(0, 260)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		card.custom_minimum_size = Vector2(530, 290)
		card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	# Stylebox: Frosted Glass Panel (Nền Kính Mờ Dát Vàng)
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(24)
	if locked:
		sb.bg_color = Color(0.96, 0.97, 0.95, 0.65)
		sb.border_color = Color(0.75, 0.73, 0.70, 0.45)
		sb.set_border_width_all(2)
	else:
		# Frosted Glass Card - Translucent warm ivory/white glass with Lacquer Gold borders
		sb.bg_color = Color(1.0, 1.0, 1.0, 0.72)
		sb.border_color = Color(0.77, 0.58, 0.15, 0.65)
		sb.set_border_width_all(2)
		sb.shadow_size = 20
		sb.shadow_color = Color(0.13, 0.08, 0.05, 0.10)
		sb.shadow_offset = Vector2(0, 6)

	card.add_theme_stylebox_override("panel", sb)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	card.add_child(margin)

	var row := HBoxContainer.new()
	row.name = "HBox"
	row.add_theme_constant_override("separation", 18)
	margin.add_child(row)

	# Left: Text column
	var text_v := VBoxContainer.new()
	text_v.name = "TextV"
	text_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_v.alignment = BoxContainer.ALIGNMENT_CENTER
	text_v.add_theme_constant_override("separation", 8)
	row.add_child(text_v)

	var font_bold := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font

	# Kicker
	var kicker_lbl := Label.new()
	kicker_lbl.name = "Kicker"
	kicker_lbl.text = kicker.to_upper()
	kicker_lbl.add_theme_font_size_override("font_size", 14)
	if font_bold: kicker_lbl.add_theme_font_override("font", font_bold)
	kicker_lbl.add_theme_color_override("font_color", Color(0.72, 0.50, 0.10) if not locked else Color(0.45, 0.48, 0.45))
	text_v.add_child(kicker_lbl)

	# Title (Bold uppercase, generous 28px)
	var title_lbl := Label.new()
	title_lbl.name = "Title"
	title_lbl.text = heading.to_upper()
	title_lbl.add_theme_font_size_override("font_size", 28)
	if font_bold: title_lbl.add_theme_font_override("font", font_bold)
	title_lbl.add_theme_color_override("font_color", C_NAVY if not locked else Color(0.18, 0.22, 0.19, 0.92))
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_lbl.custom_minimum_size = Vector2(310 if not is_stacked else 0, 58)
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_v.add_child(title_lbl)

	# Description
	var desc_lbl := Label.new()
	desc_lbl.name = "Desc"
	desc_lbl.text = description
	desc_lbl.add_theme_font_size_override("font_size", 17)
	desc_lbl.add_theme_color_override("font_color", Color(0.28, 0.26, 0.24) if not locked else Color(0.28, 0.32, 0.29, 0.85))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.custom_minimum_size = Vector2(310 if not is_stacked else 0, 52)
	desc_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_v.add_child(desc_lbl)

	# Details
	var details_box := _create_details_hbox(meta_items, locked)
	details_box.name = "Details"
	text_v.add_child(details_box)

	# Right: Visual Emblem
	var visual := _create_visual_emblem(icon_lucide, locked)
	visual.name = "Visual"
	row.add_child(visual)

	# Clickable HitArea button
	var hit := Button.new()
	hit.name = "HitArea"
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var emp := StyleBoxEmpty.new()
	hit.add_theme_stylebox_override("normal", emp)
	hit.add_theme_stylebox_override("hover", emp)
	hit.add_theme_stylebox_override("pressed", emp)
	hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not locked else Control.CURSOR_FORBIDDEN
	card.add_child(hit)

	card.pivot_offset = Vector2(265 if not is_stacked else 180, 145)
	hit.mouse_entered.connect(func() -> void:
		if not locked:
			sb.bg_color = Color(1.0, 1.0, 1.0, 0.88)
			sb.border_color = Color(0.85, 0.68, 0.22, 1.0)
			sb.shadow_color = Color(0.77, 0.58, 0.15, 0.22)
			create_tween().tween_property(card, "scale", Vector2(1.025, 1.025), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	hit.mouse_exited.connect(func() -> void:
		if not locked:
			sb.bg_color = Color(1.0, 1.0, 1.0, 0.72)
			sb.border_color = Color(0.77, 0.58, 0.15, 0.65)
			sb.shadow_color = Color(0.13, 0.08, 0.05, 0.10)
			create_tween().tween_property(card, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	hit.button_down.connect(func() -> void:
		if not locked:
			create_tween().tween_property(card, "scale", Vector2(0.975, 0.975), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	hit.button_up.connect(func() -> void:
		if not locked:
			var target := Vector2(1.025, 1.025) if hit.is_hovered() else Vector2.ONE
			create_tween().tween_property(card, "scale", target, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)

	if not locked:
		hit.pressed.connect(func() -> void: _open_activity(activity_id))

	return card

func _state_label(activity_id: String, locked: bool) -> String:
	if locked: return "CHƯA CÓ NỘI DUNG"
	if _canonical_lesson_id <= 0: return "TRÊN THIẾT BỊ"
	return "SẴN SÀNG"

func _cta(activity_id: String) -> String:
	return "Bắt đầu luyện" if _canonical_lesson_id <= 0 else "Bắt đầu"

func _has_challenge(items: Array, expected: Array) -> bool:
	return _count_challenges(items, expected) > 0

func _count_challenges(items: Array, expected: Array) -> int:
	var count := 0
	for value: Variant in items:
		if value is Dictionary and str((value as Dictionary).get("challengeType", (value as Dictionary).get("challenge_type", ""))).to_upper() in expected:
			count += 1
	return count

func _count_quizzes(items: Array, question_type: String) -> int:
	var count := 0
	for value: Variant in items:
		if value is Dictionary and str((value as Dictionary).get("questionType", (value as Dictionary).get("question_type", "NOTE_IDENTIFICATION"))).to_upper() == question_type:
			count += 1
	return count

func _open_activity(activity_id: String) -> void:
	if activity_id == "quiz_menu":
		_render_category_picker("quiz")
		return
	if activity_id == "minigame_menu":
		_render_category_picker("minigame")
		return
	Context.activity = activity_id
	var target := "res://scenes/LearningQuizScreen.tscn" if activity_id.begins_with("quiz_") else ("res://scenes/RhythmChallengeScreen.tscn" if activity_id == "rhythm" else "res://scenes/MelodyCompletionScreen.tscn")
	get_tree().change_scene_to_file(target)

func _go_back() -> void:
	if not _current_category.is_empty():
		_current_category = ""
		_render()
		return
	super._go_back()
