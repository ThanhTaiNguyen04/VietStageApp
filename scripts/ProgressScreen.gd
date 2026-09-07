extends Control

const ApiClientScript = preload("res://scripts/ApiClient.gd")

# Minimalist UI colors
const C_BG_WARM := Color("#F7F6F3")       # Bone background
const C_CARD_BG := Color("#FFFFFF")       # Pure White background
const C_BORDER := Color("#EAEAEA")        # Crisp light border
const C_TEXT_MAIN := Color("#111111")     # Charcoal main text
const C_TEXT_MUTED := Color("#787774")    # Gray muted text

const C_GOLD := Color("#C59626")
const C_GOLD_LIGHT := Color("#F1D178")
const C_JADE := Color("#173F2D")
const C_JADE_LIGHT := Color("#2F6B4B")
const C_RED := Color("#A63D32")
const C_INK := Color("#261A13")
const C_MUTED := Color("#75685E")
const C_PAPER := Color("#FFFDF8")

# Spot pastels for stats
const C_PASTEL_GREEN_BG := Color("#EDF3EC")
const C_PASTEL_GREEN_TXT := Color("#346538")
const C_PASTEL_RED_BG := Color("#FDEBEC")
const C_PASTEL_RED_TXT := Color("#9F2F2D")
const C_PASTEL_BLUE_BG := Color("#E1F3FE")
const C_PASTEL_BLUE_TXT := Color("#1F6C9F")
const C_PASTEL_YELLOW_BG := Color("#FBF3DB")
const C_PASTEL_YELLOW_TXT := Color("#956400")

const STAT_DEFINITIONS := [
	{"key": "streak", "label": "Ngày liên tiếp", "icon": "flame", "accent": Color("#9F2F2D"), "bg_pastel": Color("#FDEBEC")},
	{"key": "points", "label": "Điểm tích lũy", "icon": "star", "accent": Color("#956400"), "bg_pastel": Color("#FBF3DB")},
	{"key": "lessons", "label": "Bài hoàn thành", "icon": "graduation-cap", "accent": Color("#346538"), "bg_pastel": Color("#EDF3EC")},
	{"key": "record", "label": "Kỷ lục streak", "icon": "trophy", "accent": Color("#956400"), "bg_pastel": Color("#FBF3DB")},
]

@onready var back_btn: Button = $FloatingMargin/BackBtn
@onready var title_v: VBoxContainer = $Root/BodyMargin/Scroll/Center/ContentV/TitleV
@onready var page_title: Label = $Root/BodyMargin/Scroll/Center/ContentV/TitleV/PageTitle
@onready var page_subtitle: Label = get_node_or_null("Root/BodyMargin/Scroll/Center/ContentV/TitleV/PageSubtitle")
@onready var body_margin: MarginContainer = $Root/BodyMargin
@onready var content_v: VBoxContainer = $Root/BodyMargin/Scroll/Center/ContentV
@onready var hero_card: PanelContainer = $Root/BodyMargin/Scroll/Center/ContentV/HeroCard
@onready var hero_margin: MarginContainer = $Root/BodyMargin/Scroll/Center/ContentV/HeroCard/HeroM
@onready var hero_h: BoxContainer = $Root/BodyMargin/Scroll/Center/ContentV/HeroCard/HeroM/HeroH
@onready var profile_block: HBoxContainer = $Root/BodyMargin/Scroll/Center/ContentV/HeroCard/HeroM/HeroH/ProfileBlock
@onready var avatar_frame: PanelContainer = $Root/BodyMargin/Scroll/Center/ContentV/HeroCard/HeroM/HeroH/ProfileBlock/AvatarFrame
@onready var avatar: TextureRect = $Root/BodyMargin/Scroll/Center/ContentV/HeroCard/HeroM/HeroH/ProfileBlock/AvatarFrame/Avatar
@onready var user_kicker: Label = get_node_or_null("Root/BodyMargin/Scroll/Center/ContentV/HeroCard/HeroM/HeroH/ProfileBlock/ProfileCopy/UserKicker")
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
@onready var avatar_request: HTTPRequest = $AvatarRequest

var _api_client: Node
var _achievements: Array[Dictionary] = []
var _summary: Dictionary = {}
var _filter := "all"
var _is_loading := false
var _achievement_error := ""
var _stat_values: Dictionary = {}
var _icon_cache: Dictionary = {}
var _card_width := 320.0
var _requested_avatar_url := ""


func _ready() -> void:
	SecureDataManager.load_data()
	_api_client = ApiClientScript.new()
	add_child(_api_client)
	_build_theme()
	_build_stat_cards()
	_setup_interactions()
	avatar_request.request_completed.connect(_on_avatar_loaded)
	_apply_profile_data()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	
	# Bouncy hover/press micro-interactions for the floating back button
	back_btn.pivot_offset = Vector2(40, 40)
	back_btn.mouse_entered.connect(func() -> void:
		create_tween().tween_property(back_btn, "scale", Vector2(1.15, 1.15), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	back_btn.mouse_exited.connect(func() -> void:
		create_tween().tween_property(back_btn, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	back_btn.button_down.connect(func() -> void:
		create_tween().tween_property(back_btn, "scale", Vector2(0.9, 0.9), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	back_btn.button_up.connect(func() -> void:
		var tgt := Vector2(1.15, 1.15) if back_btn.is_hovered() else Vector2.ONE
		create_tween().tween_property(back_btn, "scale", tgt, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	
	_animate_in()
	call_deferred("_refresh_data")


func _setup_interactions() -> void:
	back_btn.pressed.connect(_go_back)
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
	state_label.text = "Đang mở bộ sưu tập thành tựu..."
	state_label.show()
	achievement_grid.hide()
	_apply_responsive_layout()

	var profile_response: Dictionary = await _api_client.get_me()
	if _api_client._is_success(profile_response):
		var profile_body: Variant = profile_response.get("body", {})
		var profile: Variant = profile_body.get("data", {}) if profile_body is Dictionary else {}
		if profile is Dictionary:
			var full_name := str(profile.get("fullName", "")).strip_edges()
			var avatar_url := str(profile.get("avatarUrl", "")).strip_edges()
			if not full_name.is_empty():
				SecureDataManager.data["user_name"] = full_name
			SecureDataManager.data["user_avatar_url"] = avatar_url
			SecureDataManager.save_data()
			_load_avatar(avatar_url)

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
		_parse_progress_summary(summary_response.get("body", {}).get("data", {}))
	else:
		_summary.clear()
		_update_stats_display()

	_is_loading = false
	if not _achievement_error.is_empty():
		state_label.text = _achievement_error
		state_label.show()
		achievement_grid.hide()
	else:
		_render_achievements()


func _apply_profile_data() -> void:
	var name_val: String = SecureDataManager.data.get("user_name", "")
	var avatar_val: String = SecureDataManager.data.get("user_avatar_url", "")
	user_name.text = name_val if not name_val.strip_edges().is_empty() else "Học viên"
	_load_avatar(avatar_val)


func _load_avatar(url: String) -> void:
	var cleaned := url.strip_edges()
	if cleaned.is_empty() or cleaned == _requested_avatar_url:
		return
	_requested_avatar_url = cleaned
	avatar.texture = load("res://assets/textures/default_avatar.png") as Texture2D
	if cleaned.begins_with("https://") or cleaned.begins_with("http://"):
		avatar_request.cancel_request()
		avatar_request.request(cleaned)


func _on_avatar_loaded(_result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code < 200 or response_code >= 300 or body.is_empty():
		return
	var image := Image.new()
	var decode_error := image.load_png_from_buffer(body)
	if decode_error != OK:
		decode_error = image.load_jpg_from_buffer(body)
	if decode_error != OK:
		decode_error = image.load_webp_from_buffer(body)
	if decode_error == OK:
		avatar.texture = ImageTexture.create_from_image(image)
	else:
		_requested_avatar_url = ""


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
		
		# Flat spot pastel icon frame
		var icon_wrap := PanelContainer.new()
		icon_wrap.custom_minimum_size = Vector2(34, 34)
		icon_wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon_wrap.add_theme_stylebox_override("panel", _flat(definition["bg_pastel"], Color.TRANSPARENT, 8, 0))
		row.add_child(icon_wrap)
		
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(20, 20)
		icon.texture = load("res://assets/textures/lucide/" + str(definition["icon"]) + ".svg") as Texture2D
		icon.modulate = definition["accent"]
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_wrap.add_child(icon)
		
		var copy := VBoxContainer.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		copy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		copy.add_theme_constant_override("separation", 0)
		row.add_child(copy)
		var value_label := Label.new()
		value_label.text = "0"
		value_label.add_theme_font_override("font", _font_bold())
		value_label.add_theme_font_size_override("font_size", 18)
		value_label.add_theme_color_override("font_color", C_TEXT_MAIN)
		copy.add_child(value_label)
		var caption := Label.new()
		caption.text = str(definition["label"])
		caption.add_theme_font_override("font", _font_regular())
		caption.add_theme_font_size_override("font_size", 11)
		caption.add_theme_color_override("font_color", C_TEXT_MUTED)
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
	
	# Flat spot pastel icon frame for achievements
	var icon_frame := PanelContainer.new()
	icon_frame.custom_minimum_size = Vector2(62, 62)
	icon_frame.add_theme_stylebox_override("panel", _achievement_icon_style(earned))
	top_row.add_child(icon_frame)
	
	var icon := TextureRect.new()
	icon.texture = load("res://assets/textures/lucide/" + ("trophy" if earned else "lock") + ".svg") as Texture2D
	icon.modulate = C_GOLD if earned else C_TEXT_MUTED
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
	status_label.add_theme_font_override("font", _font_bold())
	status_label.add_theme_font_size_override("font_size", 10)
	status_label.add_theme_color_override("font_color", C_PASTEL_GREEN_TXT if earned else C_TEXT_MUTED)
	status_pill.add_child(status_label)

	var title := Label.new()
	title.text = str(achievement["name"])
	title.add_theme_font_override("font", _font_bold())
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", C_TEXT_MAIN if earned else Color(C_TEXT_MAIN.r, C_TEXT_MAIN.g, C_TEXT_MAIN.b, 0.78))
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	stack.add_child(title)
	
	var description := Label.new()
	var description_text := str(achievement["description"]).strip_edges()
	description.text = description_text if not description_text.is_empty() else ("Một cột mốc đáng tự hào." if earned else "Tiếp tục học tập để mở khóa thành tựu này.")
	description.add_theme_font_override("font", _font_regular())
	description.add_theme_font_size_override("font_size", 12)
	description.add_theme_color_override("font_color", C_TEXT_MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.max_lines_visible = 2
	description.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	stack.add_child(description)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(spacer)

	var divider := HSeparator.new()
	divider.modulate = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.18) if earned else Color(C_BORDER.r, C_BORDER.g, C_BORDER.b, 0.5)
	stack.add_child(divider)
	
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 7)
	stack.add_child(footer)
	var footer_icon := TextureRect.new()
	footer_icon.custom_minimum_size = Vector2(16, 16)
	footer_icon.texture = load("res://assets/textures/lucide/" + ("check-circle" if earned else "hourglass") + ".svg") as Texture2D
	footer_icon.modulate = C_PASTEL_GREEN_TXT if earned else C_TEXT_MUTED
	footer_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	footer_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	footer.add_child(footer_icon)
	var footer_label := Label.new()
	footer_label.text = _achievement_footer(achievement)
	footer_label.add_theme_font_override("font", _font_regular())
	footer_label.add_theme_font_size_override("font_size", 11)
	footer_label.add_theme_color_override("font_color", C_PASTEL_GREEN_TXT if earned else C_TEXT_MUTED)
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
	var code := int(completed[1])
	var body: PackedByteArray = completed[3]
	if code < 200 or code >= 300 or body.is_empty():
		return
	var img := Image.new()
	var err := img.load_png_from_buffer(body)
	if err != OK:
		err = img.load_jpg_from_buffer(body)
	if err != OK:
		err = img.load_webp_from_buffer(body)
	if err == OK:
		var tex := ImageTexture.create_from_image(img)
		_icon_cache[url] = tex
		target.texture = tex
		target.modulate = Color.WHITE


func _parse_achievements(data: Variant) -> void:
	_achievements.clear()
	var raw_items: Array = []
	if data is Dictionary:
		var earned_list = data.get("earned", [])
		var locked_list = data.get("locked", [])
		if earned_list is Array:
			for item: Variant in earned_list:
				if item is Dictionary:
					var copy: Dictionary = item.duplicate()
					copy["earned"] = true
					raw_items.append(copy)
		if locked_list is Array:
			for item: Variant in locked_list:
				if item is Dictionary:
					var copy: Dictionary = item.duplicate()
					copy["earned"] = false
					raw_items.append(copy)
	elif data is Array:
		for item: Variant in data:
			if item is Dictionary:
				raw_items.append(item)
				
	for item: Dictionary in raw_items:
		var achievement := {
			"id": str(item.get("id", item.get("achievementId", ""))),
			"name": str(item.get("name", "Thành tựu chưa đặt tên")),
			"description": str(item.get("description", "")),
			"icon_url": str(item.get("iconUrl", "")),
			"earned": bool(item.get("earned", false)),
			"earned_at": str(item.get("earnedAt", "")),
			"requirement_type": str(item.get("requirementType", "")),
			"target_value": int(item.get("targetValue", 0)),
			"current_value": int(item.get("currentValue", 0))
		}
		_achievements.append(achievement)


func _parse_progress_summary(data: Variant) -> void:
	_summary.clear()
	if data is Dictionary:
		_summary = data
	_update_stats_display()


func _update_stats_display() -> void:
	var total_streak := _summary_value(["total_streak", "current_streak"])
	var total_points := _summary_value(["total_points", "score"])
	var completed_lessons := _summary_value(["completed_lessons", "lessons"])
	var record_streak := _summary_value(["longest_streak", "longestStreak"])

	_set_stat_value("streak", _format_number(total_streak))
	_set_stat_value("points", _format_number(total_points))
	_set_stat_value("lessons", _format_number(completed_lessons))
	_set_stat_value("record", _format_number(record_streak))


func _update_achievement_summary() -> void:
	var total := _achievements.size()
	var earned := 0
	for item: Dictionary in _achievements:
		if item["earned"]:
			earned += 1
	summary_label.text = "%d / %d đã đạt" % [earned, total]


func _achievement_footer(achievement: Dictionary) -> String:
	if bool(achievement["earned"]):
		return "Đã hoàn thành"
	var current := int(achievement["current_value"])
	var target := int(achievement["target_value"])
	if target <= 0:
		return "Đang chờ bạn chinh phục"
	return "Tiến độ: %s / %s" % [_format_number(current), _format_number(target)]


func _empty_message() -> String:
	match _filter:
		"earned":
			return "Bạn chưa mở khóa thành tựu nào.\nHãy bắt đầu từ bài học đầu tiên nhé."
		"locked":
			return "Tuyệt vời! Bạn đã chinh phục toàn bộ thành tựu hiện có."
		_:
			return "Chưa có thành tựu nào trong bộ sưu tập.\nNhững cột mốc mới sẽ xuất hiện tại đây."


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
	body_margin.add_theme_constant_override("margin_top", 112 if compact else 120) # Push content below floating back button
	body_margin.add_theme_constant_override("margin_bottom", 20)

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
		for control: Control in [back_btn, level_label, progress_title, xp_label, summary_label, all_btn, earned_btn, locked_btn]:
			control.add_theme_font_override("font", bold_font)
	if regular_font:
		for control: Control in [page_subtitle, user_kicker, level_hint, collection_subtitle, state_label, footer_note]:
			if control:
				control.add_theme_font_override("font", regular_font)

	hero_card.add_theme_stylebox_override("panel", _surface_style())
	collection_card.add_theme_stylebox_override("panel", _surface_style())
	avatar_frame.add_theme_stylebox_override("panel", _avatar_style())
	level_pill.add_theme_stylebox_override("panel", _flat(C_PASTEL_GREEN_BG, C_BORDER, 14, 1))
	summary_pill.add_theme_stylebox_override("panel", _flat(C_PASTEL_YELLOW_BG, C_BORDER, 16, 1))
	xp_bar.add_theme_stylebox_override("background", _flat(C_BORDER, Color.TRANSPARENT, 7, 0))
	xp_bar.add_theme_stylebox_override("fill", _flat(C_GOLD, Color.TRANSPARENT, 7, 0))

	page_title.add_theme_color_override("font_color", C_TEXT_MAIN)
	if page_subtitle:
		page_subtitle.add_theme_color_override("font_color", C_TEXT_MUTED)
	if user_kicker:
		user_kicker.add_theme_color_override("font_color", C_GOLD)
	user_name.add_theme_color_override("font_color", C_TEXT_MAIN)
	level_label.add_theme_color_override("font_color", C_PASTEL_GREEN_TXT)
	progress_title.add_theme_color_override("font_color", C_TEXT_MAIN)
	xp_label.add_theme_color_override("font_color", C_PASTEL_GREEN_TXT)
	level_hint.add_theme_color_override("font_color", C_TEXT_MUTED)
	collection_title.add_theme_color_override("font_color", C_TEXT_MAIN)
	collection_subtitle.add_theme_color_override("font_color", C_TEXT_MUTED)
	summary_label.add_theme_color_override("font_color", C_PASTEL_GREEN_TXT)
	state_label.add_theme_color_override("font_color", C_TEXT_MUTED)
	footer_note.add_theme_color_override("font_color", Color(1, 1, 1, 0.78))

	_style_back_button(back_btn)
	_set_button_icon(back_btn, "arrow-left")
	for button: Button in [all_btn, earned_btn, locked_btn]:
		_style_filter_button(button)


func _animate_in() -> void:
	# Wait for layout pass to complete so card positions are computed
	await get_tree().process_frame
	if not is_instance_valid(hero_card) or not is_instance_valid(collection_card):
		return
	
	hero_card.modulate.a = 0.0
	collection_card.modulate.a = 0.0
	
	var hero_target := hero_card.position.y
	var collection_target := collection_card.position.y
	
	# Apply offsets relative to actual positions
	hero_card.position.y += 14.0
	collection_card.position.y += 18.0
	
	var tween := create_tween().set_parallel(true)
	tween.tween_property(hero_card, "modulate:a", 1.0, 0.28)
	tween.tween_property(hero_card, "position:y", hero_target, 0.36).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(collection_card, "modulate:a", 1.0, 0.3).set_delay(0.08)
	tween.tween_property(collection_card, "position:y", collection_target, 0.4).set_delay(0.08).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)



func _go_back() -> void:
	var return_scene := str(SecureDataManager.data.get("navigation_return_scene", ""))
	if return_scene == "res://scenes/VirtualMusicRoom.tscn":
		SecureDataManager.data.erase("navigation_return_scene")
		SecureDataManager.save_data()
		get_tree().change_scene_to_file(return_scene)
		return
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _set_button_icon(button: Button, icon_name: String) -> void:
	button.icon = load("res://assets/textures/lucide/" + icon_name + ".svg") as Texture2D
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 78)


func _style_back_button(button: Button) -> void:
	button.add_theme_color_override("icon_normal_color", C_TEXT_MAIN)
	button.add_theme_color_override("icon_hover_color", C_TEXT_MAIN.lightened(0.2))
	button.add_theme_color_override("icon_pressed_color", C_TEXT_MAIN.darkened(0.2))
	button.add_theme_color_override("icon_focus_color", C_TEXT_MAIN)
	
	var empty := _flat(Color.TRANSPARENT, Color.TRANSPARENT, 0, 0)
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("hover", empty)
	button.add_theme_stylebox_override("pressed", empty)
	button.add_theme_stylebox_override("focus", empty)


func _style_secondary_button(button: Button) -> void:
	button.add_theme_color_override("font_color", C_TEXT_MAIN)
	button.add_theme_color_override("font_hover_color", C_TEXT_MAIN)
	button.add_theme_stylebox_override("normal", _flat(Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.07), C_BORDER, 15, 1))
	button.add_theme_stylebox_override("hover", _flat(Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.12), C_BORDER, 15, 1))
	button.add_theme_stylebox_override("pressed", _flat(Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.18), C_BORDER, 15, 1))
	button.add_theme_stylebox_override("focus", _flat(Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.08), C_GOLD, 15, 2))


func _style_filter_button(button: Button) -> void:
	button.add_theme_color_override("font_color", C_TEXT_MUTED)
	button.add_theme_color_override("font_hover_color", C_TEXT_MAIN)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _flat(C_CARD_BG, C_BORDER, 14, 1))
	button.add_theme_stylebox_override("hover", _flat(C_BG_WARM, C_BORDER, 14, 1))
	button.add_theme_stylebox_override("pressed", _flat(C_TEXT_MAIN, C_TEXT_MAIN, 14, 1))
	button.add_theme_stylebox_override("focus", _flat(Color.TRANSPARENT, C_GOLD, 14, 2))


func _surface_style() -> StyleBoxFlat:
	var style := _flat(Color(0.99, 0.99, 0.98, 0.85), Color(0, 0, 0, 0.08), 20, 1)
	style.shadow_color = Color(0, 0, 0, 0.02)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 4)
	return style


func _avatar_style() -> StyleBoxFlat:
	var style := _flat(Color.WHITE, C_BORDER, 43, 2)
	style.shadow_color = Color(0, 0, 0, 0.04)
	style.shadow_size = 6
	return style


func _stat_style(_accent: Color) -> StyleBoxFlat:
	var style := _flat(C_CARD_BG, C_BORDER, 12, 1)
	style.shadow_color = Color(0, 0, 0, 0.03)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	return style


func _achievement_style(earned: bool) -> StyleBoxFlat:
	var background := C_CARD_BG if earned else Color("#F9F9F8")
	var border := C_GOLD if earned else C_BORDER
	var style := _flat(background, border, 16, 1)
	style.shadow_color = Color(0, 0, 0, 0.04 if earned else 0.01)
	style.shadow_size = 8 if earned else 3
	style.shadow_offset = Vector2(0, 3)
	return style


func _achievement_icon_style(earned: bool) -> StyleBoxFlat:
	if earned:
		return _flat(C_PASTEL_YELLOW_BG, Color.TRANSPARENT, 12, 0)
	return _flat(Color(0, 0, 0, 0.04), Color.TRANSPARENT, 12, 0)


func _status_pill_style(earned: bool) -> StyleBoxFlat:
	if earned:
		return _flat(C_PASTEL_GREEN_BG, C_BORDER, 9, 1)
	return _flat(C_BORDER, Color.TRANSPARENT, 9, 0)


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


func _font_bold() -> Font:
	return load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font


func _font_regular() -> Font:
	return load("res://assets/fonts/BeVietnamPro-Regular.ttf") as Font
