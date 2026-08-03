extends Control

const ApiClientScript = preload("res://scripts/ApiClient.gd")

const C_GOLD := Color("#C59626")
const C_GOLD_LIGHT := Color("#F1D178")
const C_JADE := Color("#173F2D")
const C_JADE_LIGHT := Color("#2F6B4B")
const C_RED := Color("#A63D32")
const C_INK := Color("#261A13")
const C_MUTED := Color("#75685E")
const C_PAPER := Color("#FFFDF8")

const STAT_DEFINITIONS := [
	{"key": "streak", "label": "Ngày liên tiếp", "icon": "flame", "accent": Color("#D9683A")},
	{"key": "points", "label": "Điểm tích lũy", "icon": "star", "accent": Color("#C59626")},
	{"key": "lessons", "label": "Bài hoàn thành", "icon": "graduation-cap", "accent": Color("#319365")},
	{"key": "record", "label": "Kỷ lục streak", "icon": "trophy", "accent": Color("#5876B7")},
]

@onready var top_bar: PanelContainer = $Root/TopBar
@onready var top_margin: MarginContainer = $Root/TopBar/TopM
@onready var back_btn: Button = $Root/TopBar/TopM/TopH/BackBtn
@onready var title_v: VBoxContainer = $Root/TopBar/TopM/TopH/TitleV
@onready var page_title: Label = $Root/TopBar/TopM/TopH/TitleV/PageTitle
@onready var page_subtitle: Label = $Root/TopBar/TopM/TopH/TitleV/PageSubtitle
@onready var refresh_btn: Button = $Root/TopBar/TopM/TopH/RefreshBtn
@onready var body_margin: MarginContainer = $Root/BodyMargin
@onready var content_v: VBoxContainer = $Root/BodyMargin/Scroll/Center/ContentV
@onready var hero_card: PanelContainer = $Root/BodyMargin/Scroll/Center/ContentV/HeroCard
@onready var hero_margin: MarginContainer = $Root/BodyMargin/Scroll/Center/ContentV/HeroCard/HeroM
@onready var hero_h: BoxContainer = $Root/BodyMargin/Scroll/Center/ContentV/HeroCard/HeroM/HeroH
@onready var profile_block: HBoxContainer = $Root/BodyMargin/Scroll/Center/ContentV/HeroCard/HeroM/HeroH/ProfileBlock
@onready var avatar_frame: PanelContainer = $Root/BodyMargin/Scroll/Center/ContentV/HeroCard/HeroM/HeroH/ProfileBlock/AvatarFrame
@onready var user_kicker: Label = $Root/BodyMargin/Scroll/Center/ContentV/HeroCard/HeroM/HeroH/ProfileBlock/ProfileCopy/UserKicker
@onready var user_name: Label = $Root/BodyMargin/Scroll/Center/ContentV/HeroCard/HeroM/HeroH/ProfileBlock/ProfileCopy/UserName
@onready var level_pill: PanelContainer = $Root/BodyMargin/Scroll/Center/ContentV/HeroCard/HeroM/HeroH/ProfileBlock/ProfileCopy/LevelPill
@onready var level_label: Label = $Root/BodyMargin/Scroll/Center/ContentV/HeroCard/HeroM/HeroH/ProfileBlock/ProfileCopy/LevelPill/PillM/LevelLabel
@onready var hero_divider: VSeparator = $Root/BodyMargin/Scroll/Center/ContentV/HeroCard/HeroM/HeroH/HeroDivider
@onready var progress_block: VBoxContainer = $Root/BodyMargin/Scroll/Center/ContentV/HeroCard/HeroM/HeroH/ProgressBlock
@onready var progress_title: Label = $Root/BodyMargin/Scroll/Center/ContentV/HeroCard/HeroM/HeroH/ProgressBlock/LevelRow/ProgressTitle
@onready var xp_label: Label = $Root/BodyMargin/Scroll/Center/ContentV/HeroCard/HeroM/HeroH/ProgressBlock/LevelRow/XpLabel
@onready var xp_bar: ProgressBar = $Root/BodyMargin/Scroll/Center/ContentV/HeroCard/HeroM/HeroH/ProgressBlock/XpBar
@onready var level_hint: Label = $Root/BodyMargin/Scroll/Center/ContentV/HeroCard/HeroM/HeroH/ProgressBlock/LevelHint
@onready var hero_divider_2: VSeparator = $Root/BodyMargin/Scroll/Center/ContentV/HeroCard/HeroM/HeroH/HeroDivider2
@onready var stat_grid: GridContainer = $Root/BodyMargin/Scroll/Center/ContentV/HeroCard/HeroM/HeroH/StatGrid
@onready var collection_card: PanelContainer = $Root/BodyMargin/Scroll/Center/ContentV/CollectionCard
@onready var collection_margin: MarginContainer = $Root/BodyMargin/Scroll/Center/ContentV/CollectionCard/CardM
@onready var collection_header: BoxContainer = $Root/BodyMargin/Scroll/Center/ContentV/CollectionCard/CardM/CardV/CollectionHeader
@onready var collection_title: Label = $Root/BodyMargin/Scroll/Center/ContentV/CollectionCard/CardM/CardV/CollectionHeader/HeaderCopy/CollectionTitle
@onready var collection_subtitle: Label = $Root/BodyMargin/Scroll/Center/ContentV/CollectionCard/CardM/CardV/CollectionHeader/HeaderCopy/CollectionSubtitle
@onready var summary_pill: PanelContainer = $Root/BodyMargin/Scroll/Center/ContentV/CollectionCard/CardM/CardV/CollectionHeader/SummaryPill
@onready var summary_label: Label = $Root/BodyMargin/Scroll/Center/ContentV/CollectionCard/CardM/CardV/CollectionHeader/SummaryPill/SummaryM/SummaryLabel
@onready var filters: HBoxContainer = $Root/BodyMargin/Scroll/Center/ContentV/CollectionCard/CardM/CardV/Filters
@onready var all_btn: Button = $Root/BodyMargin/Scroll/Center/ContentV/CollectionCard/CardM/CardV/Filters/AllBtn
@onready var earned_btn: Button = $Root/BodyMargin/Scroll/Center/ContentV/CollectionCard/CardM/CardV/Filters/EarnedBtn
@onready var locked_btn: Button = $Root/BodyMargin/Scroll/Center/ContentV/CollectionCard/CardM/CardV/Filters/LockedBtn
@onready var state_label: Label = $Root/BodyMargin/Scroll/Center/ContentV/CollectionCard/CardM/CardV/StateLabel
@onready var achievement_grid: GridContainer = $Root/BodyMargin/Scroll/Center/ContentV/CollectionCard/CardM/CardV/AchievementGrid
@onready var footer_note: Label = $Root/BodyMargin/Scroll/Center/ContentV/FooterNote

var _api_client: Node
var _achievements: Array[Dictionary] = []
var _summary: Dictionary = {}
var _filter := "all"
var _is_loading := false
var _achievement_error := ""
var _stat_values: Dictionary = {}
var _icon_cache: Dictionary = {}
var _card_width := 320.0


func _ready() -> void:
	SecureDataManager.load_data()
	_api_client = ApiClientScript.new()
	add_child(_api_client)
	_build_theme()
	_build_stat_cards()
	_setup_interactions()
	_apply_profile_data()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	_animate_in()
	call_deferred("_refresh_data")


func _setup_interactions() -> void:
	back_btn.pressed.connect(_go_back)
	refresh_btn.pressed.connect(_refresh_data)
	var filter_group := ButtonGroup.new()
	filter_group.allow_unpress = false
	for button: Button in [all_btn, earned_btn, locked_btn]:
		button.button_group = filter_group
	all_btn.toggled.connect(func(pressed: bool) -> void:
		if pressed:
			_set_filter("all")
	)
	earned_btn.toggled.connect(func(pressed: bool) -> void:
		if pressed:
			_set_filter("earned")
	)
	locked_btn.toggled.connect(func(pressed: bool) -> void:
		if pressed:
			_set_filter("locked")
	)


func _refresh_data() -> void:
	if _is_loading:
		return
	_is_loading = true
	_achievement_error = ""
	refresh_btn.disabled = true
	refresh_btn.text = "Đang tải..."
	state_label.text = "Đang mở bộ sưu tập thành tựu..."
	state_label.show()
	achievement_grid.hide()
	_apply_responsive_layout()

	var achievement_response: Dictionary = await _api_client.get_my_achievements()
	if _api_client._is_success(achievement_response):
		_parse_achievements(achievement_response.get("body", {}).get("data", {}))
	else:
		_achievements.clear()
		_achievement_error = _api_client.error_message(
			achievement_response,
			"Không thể tải thành tựu. Vui lòng thử lại."
		)

	var progress_response: Dictionary = await _api_client.get_my_progress()
	if _api_client._is_success(progress_response):
		var progress_data: Variant = progress_response.get("body", {}).get("data", [])
		if progress_data is Array:
			SecureDataManager.sync_backend_progress(progress_data)

	var summary_response: Dictionary = await _api_client.get_my_progress_summary()
	if _api_client._is_success(summary_response):
		var summary_data: Variant = summary_response.get("body", {}).get("data", {})
		_summary = summary_data if summary_data is Dictionary else {}
	else:
		_summary = {}

	_is_loading = false
	refresh_btn.disabled = false
	_apply_profile_data()
	_apply_responsive_layout()


func _parse_achievements(data: Variant) -> void:
	_achievements.clear()
	if not data is Dictionary:
		return
	var earned_items: Variant = data.get("earned", [])
	var locked_items: Variant = data.get("locked", [])
	if earned_items is Array:
		for value: Variant in earned_items:
			if value is Dictionary:
				_achievements.append(_normalize_achievement(value, true))
	if locked_items is Array:
		for value: Variant in locked_items:
			if value is Dictionary:
				_achievements.append(_normalize_achievement(value, false))
	_achievements.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if bool(a["earned"]) != bool(b["earned"]):
			return bool(a["earned"])
		return str(a["name"]).naturalnocasecmp_to(str(b["name"])) < 0
	)


func _normalize_achievement(item: Dictionary, earned: bool) -> Dictionary:
	return {
		"id": int(item.get("id", -1)),
		"name": str(item.get("name", "Thành tựu chưa đặt tên")),
		"description": str(item.get("description", "")),
		"icon_url": str(item.get("iconUrl", "")),
		"earned_at": str(item.get("earnedAt", "")),
		"earned": earned,
	}


func _apply_profile_data() -> void:
	user_name.text = str(SecureDataManager.data.get("user_name", "Học viên VietStage"))
	var total_points := _summary_value(["total_points", "totalPoints"])
	var streak := _summary_value(["current_streak", "currentStreak"])
	var longest := _summary_value(["longest_streak", "longestStreak"])
	var completed := _summary_value(["completed_lessons", "completedLessons"])
	var level := int(total_points / 1000) + 1
	var current_xp := total_points % 1000
	level_label.text = "Cấp độ %d" % level
	progress_title.text = "Tiến độ cấp %d" % level
	xp_label.text = "%s / 1.000 XP" % _format_number(current_xp)
	xp_bar.max_value = 1000.0
	xp_bar.value = current_xp
	level_hint.text = "%s XP nữa để đạt cấp %d" % [_format_number(1000 - current_xp), level + 1]
	_set_stat_value("streak", _format_number(streak))
	_set_stat_value("points", _format_number(total_points))
	_set_stat_value("lessons", _format_number(completed))
	_set_stat_value("record", _format_number(longest))
	_update_achievement_summary()


func _summary_value(keys: Array[String]) -> int:
	for key: String in keys:
		if _summary.has(key):
			return maxi(0, int(_summary[key]))
	return 0


func _build_stat_cards() -> void:
	for child: Node in stat_grid.get_children():
		child.queue_free()
	_stat_values.clear()
	for definition: Dictionary in STAT_DEFINITIONS:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(142, 76)
		panel.add_theme_stylebox_override("panel", _stat_style(definition["accent"]))
		stat_grid.add_child(panel)
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_bottom", 10)
		panel.add_child(margin)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		margin.add_child(row)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(26, 26)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.texture = load("res://assets/textures/lucide/" + str(definition["icon"]) + ".svg") as Texture2D
		icon.modulate = definition["accent"]
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
		var copy := VBoxContainer.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		copy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		copy.add_theme_constant_override("separation", 0)
		row.add_child(copy)
		var value_label := Label.new()
		value_label.text = "0"
		value_label.add_theme_font_size_override("font_size", 18)
		value_label.add_theme_color_override("font_color", C_INK)
		copy.add_child(value_label)
		var caption := Label.new()
		caption.text = str(definition["label"])
		caption.add_theme_font_size_override("font_size", 11)
		caption.add_theme_color_override("font_color", C_MUTED)
		caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		copy.add_child(caption)
		_stat_values[str(definition["key"])] = value_label


func _set_stat_value(key: String, value: String) -> void:
	var label: Label = _stat_values.get(key) as Label
	if label:
		label.text = value


func _set_filter(filter_name: String) -> void:
	_filter = filter_name
	_render_achievements()


func _render_achievements() -> void:
	for child: Node in achievement_grid.get_children():
		child.queue_free()
	_update_achievement_summary()
	if not _achievement_error.is_empty():
		state_label.text = _achievement_error
		state_label.show()
		achievement_grid.hide()
		return

	var filtered: Array[Dictionary] = []
	for achievement: Dictionary in _achievements:
		var earned := bool(achievement["earned"])
		if _filter == "all" or (_filter == "earned" and earned) or (_filter == "locked" and not earned):
			filtered.append(achievement)
	if filtered.is_empty():
		state_label.text = _empty_message()
		state_label.show()
		achievement_grid.hide()
		return

	state_label.hide()
	achievement_grid.show()
	for index: int in filtered.size():
		var card := _create_achievement_card(filtered[index])
		achievement_grid.add_child(card)
		card.modulate.a = 0.0
		card.position.y += 10.0
		var target_y := card.position.y - 10.0
		var tween := create_tween().set_parallel(true)
		tween.tween_property(card, "modulate:a", 1.0, 0.22).set_delay(minf(index * 0.035, 0.24))
		tween.tween_property(card, "position:y", target_y, 0.28).set_delay(minf(index * 0.035, 0.24)).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)


func _create_achievement_card(achievement: Dictionary) -> PanelContainer:
	var earned := bool(achievement["earned"])
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(_card_width, 190)
	card.add_theme_stylebox_override("panel", _achievement_style(earned))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 17)
	margin.add_theme_constant_override("margin_bottom", 16)
	card.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 9)
	margin.add_child(stack)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 10)
	stack.add_child(top_row)
	var icon_frame := PanelContainer.new()
	icon_frame.custom_minimum_size = Vector2(62, 62)
	icon_frame.add_theme_stylebox_override("panel", _achievement_icon_style(earned))
	top_row.add_child(icon_frame)
	var icon := TextureRect.new()
	icon.texture = load("res://assets/textures/lucide/" + ("trophy" if earned else "lock") + ".svg") as Texture2D
	icon.modulate = C_GOLD if earned else C_MUTED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_frame.add_child(icon)
	_apply_achievement_icon(str(achievement["icon_url"]), icon, earned)

	var top_spacer := Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(top_spacer)
	var status_pill := PanelContainer.new()
	status_pill.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	status_pill.add_theme_stylebox_override("panel", _status_pill_style(earned))
	top_row.add_child(status_pill)
	var status_label := Label.new()
	status_label.text = "ĐÃ ĐẠT" if earned else "CHƯA ĐẠT"
	status_label.add_theme_font_size_override("font_size", 10)
	status_label.add_theme_color_override("font_color", C_JADE if earned else C_MUTED)
	status_pill.add_child(status_label)

	var title := Label.new()
	title.text = str(achievement["name"])
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", C_INK if earned else Color(C_INK.r, C_INK.g, C_INK.b, 0.78))
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	stack.add_child(title)
	var description := Label.new()
	var description_text := str(achievement["description"]).strip_edges()
	description.text = description_text if not description_text.is_empty() else ("Một cột mốc đáng tự hào." if earned else "Tiếp tục học tập để mở khóa thành tựu này.")
	description.add_theme_font_size_override("font_size", 12)
	description.add_theme_color_override("font_color", C_MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.max_lines_visible = 2
	description.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	stack.add_child(description)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(spacer)
	var divider := HSeparator.new()
	divider.modulate = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.18) if earned else Color(C_MUTED.r, C_MUTED.g, C_MUTED.b, 0.14)
	stack.add_child(divider)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 7)
	stack.add_child(footer)
	var footer_icon := TextureRect.new()
	footer_icon.custom_minimum_size = Vector2(16, 16)
	footer_icon.texture = load("res://assets/textures/lucide/" + ("check-circle" if earned else "hourglass") + ".svg") as Texture2D
	footer_icon.modulate = C_JADE if earned else C_MUTED
	footer_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	footer_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	footer.add_child(footer_icon)
	var footer_label := Label.new()
	footer_label.text = _achievement_footer(achievement)
	footer_label.add_theme_font_size_override("font_size", 11)
	footer_label.add_theme_color_override("font_color", C_JADE if earned else C_MUTED)
	footer.add_child(footer_label)
	return card


func _apply_achievement_icon(url: String, target: TextureRect, earned: bool) -> void:
	var cleaned := url.strip_edges()
	if cleaned.is_empty():
		return
	if _icon_cache.has(cleaned):
		target.texture = _icon_cache[cleaned]
		target.modulate = Color.WHITE
		return
	if cleaned.begins_with("res://"):
		var local_texture := load(cleaned) as Texture2D
		if local_texture:
			_icon_cache[cleaned] = local_texture
			target.texture = local_texture
			target.modulate = Color.WHITE
		return
	if cleaned.begins_with("https://") or cleaned.begins_with("http://"):
		_load_remote_icon(cleaned, target, earned)


func _load_remote_icon(url: String, target: TextureRect, _earned: bool) -> void:
	var http := HTTPRequest.new()
	http.timeout = 10.0
	add_child(http)
	if http.request(url) != OK:
		http.queue_free()
		return
	var completed: Array = await http.request_completed
	http.queue_free()
	if not is_instance_valid(target):
		return
	if int(completed[0]) != HTTPRequest.RESULT_SUCCESS or int(completed[1]) < 200 or int(completed[1]) >= 300:
		return
	var bytes: PackedByteArray = completed[3]
	var image := Image.new()
	var error := image.load_png_from_buffer(bytes)
	if error != OK:
		error = image.load_jpg_from_buffer(bytes)
	if error != OK:
		error = image.load_webp_from_buffer(bytes)
	if error != OK:
		error = image.load_svg_from_buffer(bytes)
	if error != OK:
		return
	var texture := ImageTexture.create_from_image(image)
	_icon_cache[url] = texture
	target.texture = texture
	target.modulate = Color.WHITE


func _achievement_footer(achievement: Dictionary) -> String:
	if not bool(achievement["earned"]):
		return "Đang chờ bạn chinh phục"
	var earned_at := str(achievement["earned_at"])
	if earned_at.length() >= 10:
		var parts := earned_at.substr(0, 10).split("-")
		if parts.size() == 3:
			return "Đạt ngày %s/%s/%s" % [parts[2], parts[1], parts[0]]
	return "Đã ghi dấu trên hành trình"


func _update_achievement_summary() -> void:
	var earned_count := 0
	for achievement: Dictionary in _achievements:
		if bool(achievement["earned"]):
			earned_count += 1
	summary_label.text = "%d / %d đã đạt" % [earned_count, _achievements.size()]


func _empty_message() -> String:
	if _achievements.is_empty():
		return "Chưa có thành tựu nào trong bộ sưu tập.\nNhững cột mốc mới sẽ xuất hiện tại đây."
	if _filter == "earned":
		return "Bạn chưa mở khóa thành tựu nào.\nHãy bắt đầu từ bài học đầu tiên nhé."
	if _filter == "locked":
		return "Tuyệt vời! Bạn đã chinh phục toàn bộ thành tựu hiện có."
	return "Không có thành tựu phù hợp."


func _format_number(value: int) -> String:
	var raw := str(value)
	var formatted := ""
	var count := 0
	for index: int in range(raw.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			formatted = "." + formatted
		formatted = raw[index] + formatted
		count += 1
	return formatted


func _apply_responsive_layout() -> void:
	var viewport := get_viewport().get_visible_rect().size
	var compact := viewport.x < 820.0 or viewport.x < viewport.y
	var medium := viewport.x < 1180.0
	var horizontal_padding := 12 if compact else 28
	var available_width := maxf(300.0, viewport.x - float(horizontal_padding * 2))
	content_v.custom_minimum_size.x = minf(1480.0, available_width)
	body_margin.add_theme_constant_override("margin_left", horizontal_padding)
	body_margin.add_theme_constant_override("margin_right", horizontal_padding)
	body_margin.add_theme_constant_override("margin_top", 12 if compact else 22)
	body_margin.add_theme_constant_override("margin_bottom", 20)
	top_margin.add_theme_constant_override("margin_left", 12 if compact else 28)
	top_margin.add_theme_constant_override("margin_right", 12 if compact else 28)
	top_bar.custom_minimum_size.y = 64.0 if compact else 76.0
	back_btn.custom_minimum_size.x = 48.0 if viewport.x < 520.0 else 126.0
	back_btn.text = "" if viewport.x < 520.0 else "Quay lại"
	refresh_btn.custom_minimum_size.x = 50.0 if viewport.x < 520.0 else 132.0
	refresh_btn.text = "" if viewport.x < 520.0 else ("Đang tải..." if _is_loading else "Làm mới")
	title_v.visible = viewport.x >= 390.0
	page_subtitle.visible = not compact
	page_title.add_theme_font_size_override("font_size", 22 if compact else 27)

	hero_h.vertical = compact or medium
	hero_divider.visible = not (compact or medium)
	hero_divider_2.visible = not (compact or medium)
	profile_block.custom_minimum_size.x = 0.0 if compact or medium else 330.0
	progress_block.custom_minimum_size.x = 0.0 if compact or medium else 300.0
	stat_grid.columns = 2 if compact else 4
	hero_margin.add_theme_constant_override("margin_left", 18 if compact else 28)
	hero_margin.add_theme_constant_override("margin_right", 18 if compact else 28)
	hero_margin.add_theme_constant_override("margin_top", 20 if compact else 24)
	hero_margin.add_theme_constant_override("margin_bottom", 20 if compact else 24)

	collection_header.vertical = compact
	collection_margin.add_theme_constant_override("margin_left", 16 if compact else 28)
	collection_margin.add_theme_constant_override("margin_right", 16 if compact else 28)
	collection_margin.add_theme_constant_override("margin_top", 21 if compact else 26)
	collection_margin.add_theme_constant_override("margin_bottom", 24 if compact else 30)
	for button: Button in [all_btn, earned_btn, locked_btn]:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL if compact else Control.SIZE_SHRINK_BEGIN
		button.custom_minimum_size.x = 0.0 if compact else 116.0

	if viewport.x >= 1500.0:
		achievement_grid.columns = 4
		_card_width = 320.0
	elif viewport.x >= 1050.0:
		achievement_grid.columns = 3
		_card_width = 292.0
	elif viewport.x >= 650.0:
		achievement_grid.columns = 2
		_card_width = maxf(270.0, (available_width - 54.0) * 0.5)
	else:
		achievement_grid.columns = 1
		_card_width = maxf(268.0, available_width - 32.0)
	if not _is_loading:
		_render_achievements()


func _build_theme() -> void:
	var display_font := load("res://assets/fonts/Lora-Bold.ttf") as Font
	var bold_font := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	var regular_font := load("res://assets/fonts/BeVietnamPro-Regular.ttf") as Font
	if display_font:
		page_title.add_theme_font_override("font", display_font)
		user_name.add_theme_font_override("font", display_font)
		collection_title.add_theme_font_override("font", display_font)
	if bold_font:
		for control: Control in [back_btn, refresh_btn, level_label, progress_title, xp_label, summary_label, all_btn, earned_btn, locked_btn]:
			control.add_theme_font_override("font", bold_font)
	if regular_font:
		for control: Control in [page_subtitle, user_kicker, level_hint, collection_subtitle, state_label, footer_note]:
			control.add_theme_font_override("font", regular_font)

	top_bar.add_theme_stylebox_override("panel", _flat(Color(1.0, 0.985, 0.94, 0.93), Color(1, 1, 1, 0.32), 0, 0))
	hero_card.add_theme_stylebox_override("panel", _surface_style())
	collection_card.add_theme_stylebox_override("panel", _surface_style())
	avatar_frame.add_theme_stylebox_override("panel", _avatar_style())
	level_pill.add_theme_stylebox_override("panel", _flat(Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.10), Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.16), 14, 1))
	summary_pill.add_theme_stylebox_override("panel", _flat(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.12), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.32), 16, 1))
	xp_bar.add_theme_stylebox_override("background", _flat(Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.11), Color.TRANSPARENT, 7, 0))
	xp_bar.add_theme_stylebox_override("fill", _flat(C_GOLD, Color.TRANSPARENT, 7, 0))

	page_title.add_theme_color_override("font_color", C_JADE)
	page_subtitle.add_theme_color_override("font_color", C_MUTED)
	user_kicker.add_theme_color_override("font_color", C_GOLD)
	user_name.add_theme_color_override("font_color", C_INK)
	level_label.add_theme_color_override("font_color", C_JADE)
	progress_title.add_theme_color_override("font_color", C_INK)
	xp_label.add_theme_color_override("font_color", C_JADE)
	level_hint.add_theme_color_override("font_color", C_MUTED)
	collection_title.add_theme_color_override("font_color", C_INK)
	collection_subtitle.add_theme_color_override("font_color", C_MUTED)
	summary_label.add_theme_color_override("font_color", C_JADE)
	state_label.add_theme_color_override("font_color", C_MUTED)
	footer_note.add_theme_color_override("font_color", Color(1, 1, 1, 0.78))

	_style_back_button(back_btn)
	_style_secondary_button(refresh_btn)
	_set_button_icon(back_btn, "arrow-left")
	_set_button_icon(refresh_btn, "rotate-cw")
	for button: Button in [all_btn, earned_btn, locked_btn]:
		_style_filter_button(button)


func _animate_in() -> void:
	hero_card.modulate.a = 0.0
	collection_card.modulate.a = 0.0
	hero_card.position.y += 14.0
	collection_card.position.y += 18.0
	var hero_target := hero_card.position.y - 14.0
	var collection_target := collection_card.position.y - 18.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(hero_card, "modulate:a", 1.0, 0.28)
	tween.tween_property(hero_card, "position:y", hero_target, 0.36).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(collection_card, "modulate:a", 1.0, 0.3).set_delay(0.08)
	tween.tween_property(collection_card, "position:y", collection_target, 0.4).set_delay(0.08).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)


func _go_back() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _set_button_icon(button: Button, icon_name: String) -> void:
	button.icon = load("res://assets/textures/lucide/" + icon_name + ".svg") as Texture2D
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 20)


func _style_back_button(button: Button) -> void:
	button.add_theme_color_override("font_color", C_JADE)
	button.add_theme_color_override("font_hover_color", C_GOLD)
	button.add_theme_stylebox_override("normal", _flat(Color.TRANSPARENT, Color.TRANSPARENT, 12, 0))
	button.add_theme_stylebox_override("hover", _flat(Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.08), Color.TRANSPARENT, 12, 0))
	button.add_theme_stylebox_override("pressed", _flat(Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.14), Color.TRANSPARENT, 12, 0))
	button.add_theme_stylebox_override("focus", _flat(Color.TRANSPARENT, C_GOLD, 12, 2))


func _style_secondary_button(button: Button) -> void:
	button.add_theme_color_override("font_color", C_JADE)
	button.add_theme_color_override("font_hover_color", C_JADE)
	button.add_theme_stylebox_override("normal", _flat(Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.07), Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.22), 15, 1))
	button.add_theme_stylebox_override("hover", _flat(Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.12), C_JADE, 15, 1))
	button.add_theme_stylebox_override("pressed", _flat(Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.18), C_JADE, 15, 1))
	button.add_theme_stylebox_override("focus", _flat(Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.08), C_GOLD, 15, 2))


func _style_filter_button(button: Button) -> void:
	button.add_theme_color_override("font_color", C_MUTED)
	button.add_theme_color_override("font_hover_color", C_JADE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _flat(Color.WHITE, Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.16), 14, 1))
	button.add_theme_stylebox_override("hover", _flat(Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.07), Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.28), 14, 1))
	button.add_theme_stylebox_override("pressed", _flat(C_JADE, C_JADE, 14, 1))
	button.add_theme_stylebox_override("focus", _flat(Color.TRANSPARENT, C_GOLD, 14, 2))


func _surface_style() -> StyleBoxFlat:
	var style := _flat(Color(1.0, 0.992, 0.965, 0.97), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.34), 24, 1)
	style.shadow_color = Color(0.02, 0.06, 0.035, 0.24)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 8)
	return style


func _avatar_style() -> StyleBoxFlat:
	var style := _flat(Color.WHITE, C_GOLD, 43, 3)
	style.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.22)
	style.shadow_size = 10
	return style


func _stat_style(accent: Color) -> StyleBoxFlat:
	var style := _flat(Color.WHITE, Color(accent.r, accent.g, accent.b, 0.24), 16, 1)
	style.shadow_color = Color(0.12, 0.08, 0.04, 0.05)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 2)
	return style


func _achievement_style(earned: bool) -> StyleBoxFlat:
	var background := Color("#FFFDF7") if earned else Color("#F5F2EA")
	var border := Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.48) if earned else Color(C_MUTED.r, C_MUTED.g, C_MUTED.b, 0.18)
	var style := _flat(background, border, 20, 1)
	style.shadow_color = Color(0.12, 0.08, 0.04, 0.09 if earned else 0.04)
	style.shadow_size = 8 if earned else 4
	style.shadow_offset = Vector2(0, 4)
	return style


func _achievement_icon_style(earned: bool) -> StyleBoxFlat:
	if earned:
		return _flat(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.13), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.34), 18, 1)
	return _flat(Color(C_MUTED.r, C_MUTED.g, C_MUTED.b, 0.08), Color(C_MUTED.r, C_MUTED.g, C_MUTED.b, 0.14), 18, 1)


func _status_pill_style(earned: bool) -> StyleBoxFlat:
	if earned:
		return _flat(Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.09), Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.15), 11, 1)
	return _flat(Color(C_MUTED.r, C_MUTED.g, C_MUTED.b, 0.08), Color(C_MUTED.r, C_MUTED.g, C_MUTED.b, 0.12), 11, 1)


func _flat(background: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.border_width_top = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	return style
