extends "res://scripts/LearningActivityBase.gd"

var _canonical_lesson_id := 0
var _online_content := false
var _available := {"quiz": true, "rhythm": true, "melody": true}
var _quiz_count := 0
var _rhythm_count := 0
var _melody_count := 0

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
	_rhythm_count = _count_challenges(minigames, ["RHYTHM_MATCH", "RHYTHM_MATCHING", "RHYTHM"])
	_melody_count = _count_challenges(minigames, ["MELODY_COMPLETION", "MELODY_COMPLETE", "MELODY"])
	_available["quiz"] = not quizzes.is_empty()
	_available["rhythm"] = _rhythm_count > 0
	_available["melody"] = _melody_count > 0

func _render() -> void:
	for child in content_box.get_children():
		child.queue_free()
	content_box.alignment = BoxContainer.ALIGNMENT_CENTER
	content_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var mobile := get_viewport_rect().size.x < 600.0
	var summary := _label(_summary_text(), 16 if mobile else 18, C_NAVY)
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_box.add_child(summary)
	var cards_row := BoxContainer.new()
	cards_row.vertical = mobile
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_row.add_theme_constant_override("separation", 16 if mobile else 24)
	content_box.add_child(cards_row)
	var quiz_meta := ("%d câu hỏi" % _quiz_count) if _quiz_count > 0 else "Trắc nghiệm nhận diện"
	var rhythm_meta := ("%d thử thách nhịp" % _rhythm_count) if _rhythm_count > 0 else "Thử thách nhịp điệu"
	var melody_meta := ("%d giai điệu" % _melody_count) if _melody_count > 0 else "Hoàn thiện giai điệu"
	cards_row.add_child(_activity_card("QUIZ", "Nhận diện nốt nhạc", "Luyện nghe và chọn đúng cao độ của nốt đàn.", quiz_meta, C_BLUE, "quiz"))
	cards_row.add_child(_activity_card("MINI-GAME 1", "Thử thách nhịp điệu", "Nghe mẫu, quan sát phách và gõ đúng thời điểm.", rhythm_meta, C_GREEN, "rhythm"))
	cards_row.add_child(_activity_card("MINI-GAME 2", "Hoàn thiện giai điệu", "Nghe câu nhạc và chọn nốt còn thiếu.", melody_meta, C_PURPLE, "melody"))

func _summary_text() -> String:
	if _canonical_lesson_id <= 0:
		return "Bài học ngoại tuyến · kết quả chỉ lưu trên thiết bị"
	return "Kết quả của từng hoạt động được lưu và đồng bộ riêng"

func _activity_card(kicker: String, heading: String, description: String, metadata: String, color: Color, activity_id: String) -> PanelContainer:
	var mobile := get_viewport_rect().size.x < 600.0
	var locked := _canonical_lesson_id > 0 and _online_content and not bool(_available.get(activity_id, false))
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not mobile: card.custom_minimum_size = Vector2(0, 378)
	card.add_theme_stylebox_override("panel", _panel(Color(1, 0.99, 0.97, 0.82), Color(color.r, color.g, color.b, 0.36), 24, 1))
	var body := VBoxContainer.new()
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 10 if mobile else 12)
	card.add_child(body)
	var badge := _label(_state_label(activity_id, locked), 14, color if not locked else C_MUTED)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(badge)
	var icon := _label("?" if activity_id == "quiz" else ("♫" if activity_id == "rhythm" else "♪"), 54 if mobile else 62, color if not locked else C_MUTED)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(icon)
	var title := _label(heading, 22 if mobile else 26, C_NAVY)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(title)
	var detail := _label(description, 16 if mobile else 18, C_MUTED)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.custom_minimum_size.y = 48 if mobile else 54
	body.add_child(detail)
	var meta := _label("Chưa có nội dung đánh giá trực tuyến" if locked else metadata, 14 if mobile else 16, C_MUTED if locked else C_GOLD)
	meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(meta)
	var button := _button("Không có nội dung" if locked else _cta(activity_id), 0, 52 if mobile else 56, C_MUTED if locked else C_NAVY)
	button.disabled = locked
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(func() -> void: _open_activity(activity_id))
	body.add_child(button)
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

func _open_activity(activity_id: String) -> void:
	Context.activity = activity_id
	var target := "res://scenes/LearningQuizScreen.tscn" if activity_id == "quiz" else ("res://scenes/RhythmChallengeScreen.tscn" if activity_id == "rhythm" else "res://scenes/MelodyCompletionScreen.tscn")
	get_tree().change_scene_to_file(target)
