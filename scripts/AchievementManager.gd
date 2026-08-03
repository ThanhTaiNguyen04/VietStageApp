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
const C_FIELD := Color("#FFFFFF")

const CONDITION_PRESETS := [
	{"label": "Hoàn thành bài học", "type": "LESSONS_COMPLETED"},
	{"label": "Chuỗi ngày học", "type": "LEARNING_STREAK"},
	{"label": "Tích lũy điểm", "type": "TOTAL_POINTS"},
	{"label": "Luyện tập nhạc cụ", "type": "INSTRUMENT_PRACTICE"},
]

@onready var top_bar: PanelContainer = $Root/TopBar
@onready var top_margin: MarginContainer = $Root/TopBar/TopM
@onready var back_btn: Button = $Root/TopBar/TopM/TopH/BackBtn
@onready var title_box: VBoxContainer = $Root/TopBar/TopM/TopH/TitleBox
@onready var page_title: Label = $Root/TopBar/TopM/TopH/TitleBox/PageTitle
@onready var page_subtitle: Label = $Root/TopBar/TopM/TopH/TitleBox/PageSubtitle
@onready var new_btn: Button = $Root/TopBar/TopM/TopH/NewBtn
@onready var content_margin: MarginContainer = $Root/Content
@onready var workspace: BoxContainer = $Root/Content/Workspace
@onready var list_panel: PanelContainer = $Root/Content/Workspace/ListPanel
@onready var editor_panel: PanelContainer = $Root/Content/Workspace/EditorPanel
@onready var list_title: Label = $Root/Content/Workspace/ListPanel/ListM/ListV/ListHeader/ListTitle
@onready var count_label: Label = $Root/Content/Workspace/ListPanel/ListM/ListV/ListHeader/CountLabel
@onready var search_edit: LineEdit = $Root/Content/Workspace/ListPanel/ListM/ListV/SearchEdit
@onready var list_status: Label = $Root/Content/Workspace/ListPanel/ListM/ListV/ListStatus
@onready var item_scroll: ScrollContainer = $Root/Content/Workspace/ListPanel/ListM/ListV/ItemScroll
@onready var items: VBoxContainer = $Root/Content/Workspace/ListPanel/ListM/ListV/ItemScroll/Items
@onready var form_margin: MarginContainer = $Root/Content/Workspace/EditorPanel/EditorScroll/FormCard
@onready var form_v: VBoxContainer = $Root/Content/Workspace/EditorPanel/EditorScroll/FormCard/FormV
@onready var mobile_form_back: Button = $Root/Content/Workspace/EditorPanel/EditorScroll/FormCard/FormV/MobileFormBack
@onready var icon_preview_frame: PanelContainer = $Root/Content/Workspace/EditorPanel/EditorScroll/FormCard/FormV/FormHeader/IconPreviewFrame
@onready var icon_preview: TextureRect = $Root/Content/Workspace/EditorPanel/EditorScroll/FormCard/FormV/FormHeader/IconPreviewFrame/IconPreview
@onready var form_title: Label = $Root/Content/Workspace/EditorPanel/EditorScroll/FormCard/FormV/FormHeader/HeaderCopy/FormTitle
@onready var form_hint: Label = $Root/Content/Workspace/EditorPanel/EditorScroll/FormCard/FormV/FormHeader/HeaderCopy/FormHint
@onready var name_edit: LineEdit = $Root/Content/Workspace/EditorPanel/EditorScroll/FormCard/FormV/NameEdit
@onready var description_edit: TextEdit = $Root/Content/Workspace/EditorPanel/EditorScroll/FormCard/FormV/DescriptionEdit
@onready var icon_row: BoxContainer = $Root/Content/Workspace/EditorPanel/EditorScroll/FormCard/FormV/IconRow
@onready var icon_edit: LineEdit = $Root/Content/Workspace/EditorPanel/EditorScroll/FormCard/FormV/IconRow/IconEdit
@onready var preview_btn: Button = $Root/Content/Workspace/EditorPanel/EditorScroll/FormCard/FormV/IconRow/PreviewBtn
@onready var condition_label: Label = $Root/Content/Workspace/EditorPanel/EditorScroll/FormCard/FormV/ConditionHeader/ConditionLabel
@onready var condition_mode: OptionButton = $Root/Content/Workspace/EditorPanel/EditorScroll/FormCard/FormV/ConditionHeader/ConditionMode
@onready var preset_box: GridContainer = $Root/Content/Workspace/EditorPanel/EditorScroll/FormCard/FormV/PresetBox
@onready var type_option: OptionButton = $Root/Content/Workspace/EditorPanel/EditorScroll/FormCard/FormV/PresetBox/TypeOption
@onready var target_edit: LineEdit = $Root/Content/Workspace/EditorPanel/EditorScroll/FormCard/FormV/PresetBox/TargetEdit
@onready var value_spin: SpinBox = $Root/Content/Workspace/EditorPanel/EditorScroll/FormCard/FormV/PresetBox/ValueSpin
@onready var json_label: Label = $Root/Content/Workspace/EditorPanel/EditorScroll/FormCard/FormV/JsonLabel
@onready var json_edit: TextEdit = $Root/Content/Workspace/EditorPanel/EditorScroll/FormCard/FormV/JsonEdit
@onready var validation_label: Label = $Root/Content/Workspace/EditorPanel/EditorScroll/FormCard/FormV/ValidationLabel
@onready var actions: BoxContainer = $Root/Content/Workspace/EditorPanel/EditorScroll/FormCard/FormV/Actions
@onready var cancel_btn: Button = $Root/Content/Workspace/EditorPanel/EditorScroll/FormCard/FormV/Actions/CancelBtn
@onready var save_btn: Button = $Root/Content/Workspace/EditorPanel/EditorScroll/FormCard/FormV/Actions/SaveBtn
@onready var toast_wrap: MarginContainer = $ToastWrap
@onready var toast_panel: PanelContainer = $ToastWrap/Center/ToastPanel
@onready var toast_label: Label = $ToastWrap/Center/ToastPanel/ToastLabel

var _api_client: Node
var _achievements: Array[Dictionary] = []
var _selected_id := -1
var _is_loading := false
var _is_saving := false
var _is_compact := false
var _mobile_editor_open := false
var _form_dirty := false
var _suspend_form_signals := false
var _preview_request_version := 0
var _toast_version := 0


func _ready() -> void:
	_api_client = ApiClientScript.new()
	add_child(_api_client)
	_setup_options()
	_build_theme()
	_setup_interactions()
	_reset_form(false)
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	_animate_in()
	call_deferred("_load_achievements")


func _setup_options() -> void:
	condition_mode.clear()
	condition_mode.add_item("JSON tùy chỉnh", 0)
	condition_mode.add_item("Trình tạo điều kiện", 1)
	type_option.clear()
	for index: int in CONDITION_PRESETS.size():
		type_option.add_item(str(CONDITION_PRESETS[index]["label"]), index)
	condition_mode.select(0)
	type_option.select(0)


func _setup_interactions() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	new_btn.pressed.connect(func() -> void: _request_new_form())
	mobile_form_back.pressed.connect(_show_mobile_list)
	search_edit.text_changed.connect(func(_value: String) -> void: _render_list())
	preview_btn.pressed.connect(func() -> void: _load_icon_preview(icon_edit.text.strip_edges(), true))
	icon_edit.text_submitted.connect(func(_value: String) -> void: _load_icon_preview(icon_edit.text.strip_edges(), true))
	condition_mode.item_selected.connect(_on_condition_mode_changed)
	type_option.item_selected.connect(func(_index: int) -> void: _update_json_from_preset())
	target_edit.text_changed.connect(func(_value: String) -> void: _update_json_from_preset())
	value_spin.value_changed.connect(func(_value: float) -> void: _update_json_from_preset())
	cancel_btn.pressed.connect(func() -> void: _request_reset_form())
	save_btn.pressed.connect(_save_achievement)

	name_edit.text_changed.connect(func(_value: String) -> void: _mark_dirty())
	description_edit.text_changed.connect(_mark_dirty)
	icon_edit.text_changed.connect(func(_value: String) -> void: _mark_dirty())
	json_edit.text_changed.connect(_on_json_changed)


func _load_achievements(preferred_name: String = "") -> void:
	if _is_loading:
		return
	_is_loading = true
	list_status.text = "Đang tải danh sách..."
	list_status.show()
	item_scroll.hide()
	var response: Dictionary = await _api_client.get_all_achievements()
	_is_loading = false
	if not _api_client._is_success(response):
		list_status.text = _api_client.error_message(response, "Không thể tải thành tích. Chạm để thử lại.")
		list_status.show()
		list_status.mouse_filter = Control.MOUSE_FILTER_STOP
		return

	_achievements.clear()
	var payload: Variant = response.get("body", {}).get("data", [])
	var source: Array = payload if payload is Array else []
	for value: Variant in source:
		if value is Dictionary:
			_achievements.append(value as Dictionary)
	_achievements.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("name", "")).naturalnocasecmp_to(str(b.get("name", ""))) < 0
	)
	_render_list()
	if not preferred_name.is_empty():
		for achievement: Dictionary in _achievements:
			if str(achievement.get("name", "")) == preferred_name:
				_select_achievement(achievement)
				break


func _render_list() -> void:
	for child: Node in items.get_children():
		child.queue_free()

	var query := search_edit.text.strip_edges().to_lower()
	var filtered: Array[Dictionary] = []
	for achievement: Dictionary in _achievements:
		var haystack := (str(achievement.get("name", "")) + " " + str(achievement.get("description", ""))).to_lower()
		if query.is_empty() or haystack.contains(query):
			filtered.append(achievement)

	count_label.text = "%d mục" % filtered.size()
	if filtered.is_empty():
		list_status.text = "Chưa có thành tích nào." if query.is_empty() else "Không tìm thấy kết quả phù hợp."
		list_status.show()
		item_scroll.hide()
		return

	list_status.hide()
	item_scroll.show()
	for index: int in filtered.size():
		var card := _create_achievement_card(filtered[index])
		items.add_child(card)
		card.modulate.a = 0.0
		create_tween().tween_property(card, "modulate:a", 1.0, 0.18).set_delay(minf(index * 0.025, 0.2))


func _create_achievement_card(achievement: Dictionary) -> PanelContainer:
	var achievement_id := int(achievement.get("id", -1))
	var selected := achievement_id == _selected_id
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 88)
	card.add_theme_stylebox_override("panel", _list_card_style(selected))
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	var icon_frame := PanelContainer.new()
	icon_frame.custom_minimum_size = Vector2(54, 54)
	icon_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_frame.add_theme_stylebox_override("panel", _flat(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.11), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.28), 16, 1))
	row.add_child(icon_frame)
	var icon := TextureRect.new()
	icon.texture = load("res://assets/textures/lucide/trophy.svg") as Texture2D
	icon.modulate = C_GOLD if selected else C_JADE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_frame.add_child(icon)

	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_theme_constant_override("separation", 3)
	row.add_child(copy)
	var title := Label.new()
	title.text = str(achievement.get("name", "Chưa đặt tên"))
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", C_INK)
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(title)
	var description := Label.new()
	var description_text := str(achievement.get("description", "")).replace("\n", " ").strip_edges()
	description.text = description_text if not description_text.is_empty() else "Chưa có mô tả"
	description.add_theme_font_size_override("font_size", 12)
	description.add_theme_color_override("font_color", C_MUTED)
	description.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(description)
	var id_label := Label.new()
	id_label.text = "ID #%d" % achievement_id
	id_label.add_theme_font_size_override("font_size", 11)
	id_label.add_theme_color_override("font_color", Color(C_MUTED.r, C_MUTED.g, C_MUTED.b, 0.72))
	id_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(id_label)

	var hit_area := Button.new()
	hit_area.flat = true
	hit_area.focus_mode = Control.FOCUS_ALL
	hit_area.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hit_area.add_theme_stylebox_override("normal", _flat(Color.TRANSPARENT, Color.TRANSPARENT, 18, 0))
	hit_area.add_theme_stylebox_override("hover", _flat(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.07), Color.TRANSPARENT, 18, 0))
	hit_area.add_theme_stylebox_override("pressed", _flat(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.13), Color.TRANSPARENT, 18, 0))
	hit_area.add_theme_stylebox_override("focus", _flat(Color.TRANSPARENT, C_GOLD, 18, 2))
	card.add_child(hit_area)
	hit_area.pressed.connect(func() -> void: _request_select_achievement(achievement))
	return card


func _request_select_achievement(achievement: Dictionary) -> void:
	var next_id := int(achievement.get("id", -1))
	if next_id == _selected_id:
		_show_mobile_editor()
		return
	_request_discard_if_needed(func() -> void: _select_achievement(achievement))


func _select_achievement(achievement: Dictionary) -> void:
	_suspend_form_signals = true
	_selected_id = int(achievement.get("id", -1))
	name_edit.text = str(achievement.get("name", ""))
	description_edit.text = str(achievement.get("description", ""))
	icon_edit.text = str(achievement.get("iconUrl", ""))
	json_edit.text = str(achievement.get("conditionJson", "{}"))
	condition_mode.select(0)
	preset_box.hide()
	json_edit.editable = true
	form_title.text = str(achievement.get("name", "Chỉnh sửa thành tích"))
	form_hint.text = "Đang chỉnh sửa ID #%d" % _selected_id
	save_btn.text = "Lưu thay đổi"
	validation_label.hide()
	_suspend_form_signals = false
	_form_dirty = false
	_load_icon_preview(icon_edit.text.strip_edges(), false)
	_render_list()
	_show_mobile_editor()


func _request_new_form() -> void:
	_request_discard_if_needed(func() -> void:
		_reset_form(true)
		_show_mobile_editor()
	)


func _request_reset_form() -> void:
	_request_discard_if_needed(func() -> void: _reset_form(true))


func _reset_form(focus_name: bool = true) -> void:
	_suspend_form_signals = true
	_selected_id = -1
	name_edit.clear()
	description_edit.clear()
	icon_edit.clear()
	json_edit.text = "{}"
	condition_mode.select(0)
	type_option.select(0)
	target_edit.clear()
	value_spin.value = 1
	preset_box.hide()
	json_edit.editable = true
	form_title.text = "Tạo thành tích mới"
	form_hint.text = "Các trường có dấu * là bắt buộc"
	save_btn.text = "Tạo thành tích"
	validation_label.hide()
	_set_fallback_icon()
	_suspend_form_signals = false
	_form_dirty = false
	_render_list()
	if focus_name:
		name_edit.grab_focus()


func _save_achievement() -> void:
	if _is_saving:
		return
	var name := name_edit.text.strip_edges()
	var icon_url := icon_edit.text.strip_edges()
	var condition_json := json_edit.text.strip_edges()
	var description := description_edit.text.strip_edges()
	var error := _validate_form(name, icon_url, condition_json)
	if not error.is_empty():
		_show_validation(error)
		return

	_is_saving = true
	save_btn.disabled = true
	cancel_btn.disabled = true
	save_btn.text = "Đang lưu..."
	var response: Dictionary
	if _selected_id < 0:
		response = await _api_client.create_achievement(name, icon_url, condition_json, description)
	else:
		response = await _api_client.update_achievement(_selected_id, name, icon_url, condition_json, description)
	_is_saving = false
	save_btn.disabled = false
	cancel_btn.disabled = false

	if not _api_client._is_success(response):
		save_btn.text = "Tạo thành tích" if _selected_id < 0 else "Lưu thay đổi"
		_show_validation(_api_client.error_message(response, "Không thể lưu thành tích. Vui lòng thử lại."))
		return

	_form_dirty = false
	validation_label.hide()
	_show_toast("Đã tạo thành tích mới" if _selected_id < 0 else "Đã cập nhật thành tích")
	await _load_achievements(name)


func _validate_form(name: String, icon_url: String, condition_json: String) -> String:
	if name.is_empty():
		name_edit.grab_focus()
		return "Vui lòng nhập tên thành tích."
	if icon_url.is_empty():
		icon_edit.grab_focus()
		return "Vui lòng nhập Icon URL."
	if not (icon_url.begins_with("https://") or icon_url.begins_with("http://") or icon_url.begins_with("res://")):
		icon_edit.grab_focus()
		return "Icon URL cần bắt đầu bằng https://, http:// hoặc res://."
	if condition_json.is_empty():
		json_edit.grab_focus()
		return "Vui lòng nhập conditionJson."
	var parser := JSON.new()
	if parser.parse(condition_json) != OK:
		json_edit.grab_focus()
		return "conditionJson chưa đúng cú pháp JSON: %s" % parser.get_error_message()
	if not (parser.data is Dictionary):
		json_edit.grab_focus()
		return "conditionJson cần là một JSON object, ví dụ {\"type\": \"...\"}."
	return ""


func _on_condition_mode_changed(index: int) -> void:
	var use_builder := condition_mode.get_item_id(index) == 1
	preset_box.visible = use_builder
	json_edit.editable = not use_builder
	json_label.text = "conditionJson · Tự động tạo từ mẫu" if use_builder else "conditionJson · JSON gửi nguyên dạng sang BE"
	if use_builder:
		_update_json_from_preset()
	_mark_dirty()


func _update_json_from_preset() -> void:
	if _suspend_form_signals or condition_mode.get_selected_id() != 1:
		return
	var preset_index := type_option.get_selected_id()
	if preset_index < 0 or preset_index >= CONDITION_PRESETS.size():
		return
	var payload := {
		"type": str(CONDITION_PRESETS[preset_index]["type"]),
		"value": int(value_spin.value),
	}
	var target := target_edit.text.strip_edges()
	if not target.is_empty():
		payload["target"] = target
	_suspend_form_signals = true
	json_edit.text = JSON.stringify(payload, "  ")
	_suspend_form_signals = false
	_mark_dirty()


func _on_json_changed() -> void:
	if _suspend_form_signals:
		return
	_mark_dirty()
	var parser := JSON.new()
	var content := json_edit.text.strip_edges()
	if not content.is_empty() and parser.parse(content) == OK and parser.data is Dictionary:
		validation_label.hide()


func _mark_dirty() -> void:
	if not _suspend_form_signals:
		_form_dirty = true


func _request_discard_if_needed(action: Callable) -> void:
	if not _form_dirty:
		action.call()
		return
	var dialog := ConfirmationDialog.new()
	dialog.title = "Bỏ thay đổi chưa lưu?"
	dialog.dialog_text = "Các nội dung bạn vừa nhập chưa được lưu."
	dialog.ok_button_text = "Bỏ thay đổi"
	dialog.cancel_button_text = "Tiếp tục chỉnh sửa"
	dialog.exclusive = true
	dialog.confirmed.connect(func() -> void:
		_form_dirty = false
		action.call()
	)
	dialog.canceled.connect(func() -> void: dialog.queue_free())
	dialog.confirmed.connect(func() -> void: dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered(Vector2i(430, 190))


func _load_icon_preview(url: String, show_error: bool) -> void:
	_preview_request_version += 1
	var request_version := _preview_request_version
	if url.is_empty():
		_set_fallback_icon()
		return
	if url.begins_with("res://"):
		var local_texture := load(url) as Texture2D
		if local_texture:
			icon_preview.texture = local_texture
			icon_preview.modulate = Color.WHITE
		elif show_error:
			_show_validation("Không thể đọc icon trong dự án.")
		return
	if not (url.begins_with("https://") or url.begins_with("http://")):
		if show_error:
			_show_validation("Icon URL không hợp lệ.")
		return

	preview_btn.disabled = true
	preview_btn.text = "Đang tải..."
	var http := HTTPRequest.new()
	http.timeout = 12.0
	add_child(http)
	var request_error := http.request(url)
	if request_error != OK:
		http.queue_free()
		_finish_icon_preview(request_version, show_error, "Không thể gửi yêu cầu tải icon.")
		return
	var completed: Array = await http.request_completed
	http.queue_free()
	if request_version != _preview_request_version:
		return
	var result := int(completed[0])
	var status := int(completed[1])
	var bytes: PackedByteArray = completed[3]
	if result != HTTPRequest.RESULT_SUCCESS or status < 200 or status >= 300:
		_finish_icon_preview(request_version, show_error, "Không thể tải icon từ URL này.")
		return
	var image := Image.new()
	var load_error := image.load_png_from_buffer(bytes)
	if load_error != OK:
		load_error = image.load_jpg_from_buffer(bytes)
	if load_error != OK:
		load_error = image.load_webp_from_buffer(bytes)
	if load_error != OK:
		load_error = image.load_svg_from_buffer(bytes)
	if load_error != OK:
		_finish_icon_preview(request_version, show_error, "Định dạng icon chưa được hỗ trợ.")
		return
	icon_preview.texture = ImageTexture.create_from_image(image)
	icon_preview.modulate = Color.WHITE
	preview_btn.disabled = false
	preview_btn.text = "Xem icon"
	validation_label.hide()


func _finish_icon_preview(request_version: int, show_error: bool, message: String) -> void:
	if request_version != _preview_request_version:
		return
	preview_btn.disabled = false
	preview_btn.text = "Xem icon"
	_set_fallback_icon()
	if show_error:
		_show_validation(message)


func _set_fallback_icon() -> void:
	icon_preview.texture = load("res://assets/textures/lucide/trophy.svg") as Texture2D
	icon_preview.modulate = C_GOLD


func _show_validation(message: String) -> void:
	validation_label.text = message
	validation_label.show()
	validation_label.modulate.a = 0.0
	create_tween().tween_property(validation_label, "modulate:a", 1.0, 0.18)


func _show_toast(message: String) -> void:
	_toast_version += 1
	var version := _toast_version
	toast_label.text = message
	toast_wrap.show()
	toast_wrap.modulate.a = 0.0
	toast_wrap.position.y = 8.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(toast_wrap, "modulate:a", 1.0, 0.2)
	tween.tween_property(toast_wrap, "position:y", 0.0, 0.24).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(2.4).timeout
	if version != _toast_version:
		return
	var exit_tween := create_tween()
	exit_tween.tween_property(toast_wrap, "modulate:a", 0.0, 0.18)
	await exit_tween.finished
	if version == _toast_version:
		toast_wrap.hide()


func _on_back_pressed() -> void:
	if _is_compact and _mobile_editor_open:
		_show_mobile_list()
		return
	_request_discard_if_needed(func() -> void: get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))


func _show_mobile_list() -> void:
	_mobile_editor_open = false
	_apply_responsive_layout()


func _show_mobile_editor() -> void:
	if not _is_compact:
		return
	_mobile_editor_open = true
	_apply_responsive_layout()


func _apply_responsive_layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	_is_compact = viewport_size.x < 900.0 or viewport_size.x < viewport_size.y
	var phone := viewport_size.x < 640.0
	workspace.vertical = _is_compact
	list_panel.custom_minimum_size.x = 0.0 if _is_compact else minf(510.0, viewport_size.x * 0.34)
	list_panel.visible = not _is_compact or not _mobile_editor_open
	editor_panel.visible = not _is_compact or _mobile_editor_open
	mobile_form_back.visible = _is_compact

	top_bar.custom_minimum_size.y = 64.0 if _is_compact else 76.0
	top_margin.add_theme_constant_override("margin_left", 12 if _is_compact else 28)
	top_margin.add_theme_constant_override("margin_right", 12 if _is_compact else 28)
	content_margin.add_theme_constant_override("margin_left", 12 if _is_compact else 28)
	content_margin.add_theme_constant_override("margin_right", 12 if _is_compact else 28)
	content_margin.add_theme_constant_override("margin_top", 12 if _is_compact else 22)
	content_margin.add_theme_constant_override("margin_bottom", 12 if _is_compact else 22)
	form_margin.add_theme_constant_override("margin_left", 16 if _is_compact else 30)
	form_margin.add_theme_constant_override("margin_right", 16 if _is_compact else 30)
	form_margin.add_theme_constant_override("margin_top", 18 if _is_compact else 26)
	form_margin.add_theme_constant_override("margin_bottom", 24)

	back_btn.custom_minimum_size.x = 50.0 if phone else 126.0
	back_btn.text = "" if phone else "Quay lại"
	page_title.add_theme_font_size_override("font_size", 21 if _is_compact else 27)
	page_subtitle.visible = not _is_compact and viewport_size.x >= 1100.0
	title_box.visible = not (phone and _mobile_editor_open)
	new_btn.visible = not (_is_compact and _mobile_editor_open)
	new_btn.custom_minimum_size.x = 52.0 if phone else 148.0
	new_btn.text = "" if phone else "Tạo mới"

	icon_row.vertical = viewport_size.x < 560.0
	actions.vertical = viewport_size.x < 520.0
	preset_box.columns = 1 if viewport_size.x < 720.0 else 3
	condition_label.visible = viewport_size.x >= 500.0
	condition_mode.custom_minimum_size.x = 0.0 if viewport_size.x < 500.0 else 230.0
	condition_mode.size_flags_horizontal = Control.SIZE_EXPAND_FILL if viewport_size.x < 500.0 else Control.SIZE_SHRINK_END


func _build_theme() -> void:
	var font_display := load("res://assets/fonts/Lora-Bold.ttf") as Font
	var font_bold := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as Font
	var font_regular := load("res://assets/fonts/BeVietnamPro-Regular.ttf") as Font
	if font_display:
		page_title.add_theme_font_override("font", font_display)
		form_title.add_theme_font_override("font", font_display)
	if font_bold:
		for control: Control in [back_btn, new_btn, list_title, count_label, save_btn, cancel_btn, mobile_form_back]:
			control.add_theme_font_override("font", font_bold)
	if font_regular:
		for control: Control in [page_subtitle, form_hint, list_status, validation_label, json_label]:
			control.add_theme_font_override("font", font_regular)

	top_bar.add_theme_stylebox_override("panel", _flat(Color(1.0, 0.985, 0.94, 0.92), Color(1, 1, 1, 0.34), 0, 0))
	list_panel.add_theme_stylebox_override("panel", _surface_style())
	editor_panel.add_theme_stylebox_override("panel", _surface_style())
	icon_preview_frame.add_theme_stylebox_override("panel", _flat(Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.10), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.42), 20, 1))
	toast_panel.add_theme_stylebox_override("panel", _flat(C_JADE, C_GOLD, 18, 1))
	toast_label.add_theme_color_override("font_color", Color.WHITE)

	page_title.add_theme_color_override("font_color", C_JADE)
	page_subtitle.add_theme_color_override("font_color", C_MUTED)
	list_title.add_theme_color_override("font_color", C_INK)
	count_label.add_theme_color_override("font_color", C_JADE_LIGHT)
	list_status.add_theme_color_override("font_color", C_MUTED)
	form_title.add_theme_color_override("font_color", C_INK)
	form_hint.add_theme_color_override("font_color", C_MUTED)
	json_label.add_theme_color_override("font_color", C_MUTED)
	validation_label.add_theme_color_override("font_color", C_RED)

	_style_back_button(back_btn)
	_style_back_button(mobile_form_back)
	_style_primary_button(new_btn)
	_style_primary_button(save_btn)
	_style_secondary_button(cancel_btn)
	_style_secondary_button(preview_btn)
	_set_button_icon(back_btn, "arrow-left")
	_set_button_icon(mobile_form_back, "arrow-left")
	_set_button_icon(new_btn, "sparkles")
	_set_button_icon(save_btn, "check-circle")
	_set_button_icon(preview_btn, "rotate-cw")

	for field: Control in [search_edit, name_edit, description_edit, icon_edit, json_edit]:
		field.add_theme_color_override("font_color", C_INK)
		field.add_theme_color_override("font_placeholder_color", Color(C_MUTED.r, C_MUTED.g, C_MUTED.b, 0.72))
		field.add_theme_stylebox_override("normal", _flat(C_FIELD, Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.20), 14, 1))
		field.add_theme_stylebox_override("focus", _flat(C_FIELD, C_GOLD, 14, 2))
	condition_mode.add_theme_stylebox_override("normal", _flat(C_FIELD, Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.20), 13, 1))
	type_option.add_theme_stylebox_override("normal", _flat(C_FIELD, Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.20), 13, 1))
	var spin_line := value_spin.get_line_edit()
	spin_line.add_theme_color_override("font_color", C_INK)
	spin_line.add_theme_stylebox_override("normal", _flat(C_FIELD, Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.20), 13, 1))


func _animate_in() -> void:
	list_panel.modulate.a = 0.0
	editor_panel.modulate.a = 0.0
	list_panel.position.y += 14.0
	editor_panel.position.y += 14.0
	var list_target := list_panel.position.y - 14.0
	var editor_target := editor_panel.position.y - 14.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(list_panel, "modulate:a", 1.0, 0.25)
	tween.tween_property(list_panel, "position:y", list_target, 0.32).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(editor_panel, "modulate:a", 1.0, 0.28).set_delay(0.06)
	tween.tween_property(editor_panel, "position:y", editor_target, 0.34).set_delay(0.06).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)


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


func _style_primary_button(button: Button) -> void:
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _flat(C_GOLD, C_GOLD, 15, 0))
	button.add_theme_stylebox_override("hover", _flat(C_GOLD.lightened(0.08), C_GOLD_LIGHT, 15, 1))
	button.add_theme_stylebox_override("pressed", _flat(C_GOLD.darkened(0.08), C_GOLD, 15, 0))
	button.add_theme_stylebox_override("focus", _flat(C_GOLD, Color.WHITE, 15, 2))


func _style_secondary_button(button: Button) -> void:
	button.add_theme_color_override("font_color", C_JADE)
	button.add_theme_color_override("font_hover_color", C_JADE)
	button.add_theme_stylebox_override("normal", _flat(Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.07), Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.24), 15, 1))
	button.add_theme_stylebox_override("hover", _flat(Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.12), C_JADE, 15, 1))
	button.add_theme_stylebox_override("pressed", _flat(Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.18), C_JADE, 15, 1))
	button.add_theme_stylebox_override("focus", _flat(Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.08), C_GOLD, 15, 2))


func _surface_style() -> StyleBoxFlat:
	var style := _flat(Color(1.0, 0.992, 0.965, 0.97), Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.34), 24, 1)
	style.shadow_color = Color(0.02, 0.06, 0.035, 0.24)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 8)
	return style


func _list_card_style(selected: bool) -> StyleBoxFlat:
	var background := Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.11) if selected else Color.WHITE
	var border := C_GOLD if selected else Color(C_JADE.r, C_JADE.g, C_JADE.b, 0.14)
	var style := _flat(background, border, 18, 2 if selected else 1)
	style.shadow_color = Color(0.12, 0.08, 0.04, 0.06)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 2)
	return style


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
