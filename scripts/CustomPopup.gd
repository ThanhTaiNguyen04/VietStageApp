## ==============================================================================
## File: CustomPopup.gd
## Mô tả: Quản lý hộp thoại Popup tùy biến hiển thị gợi ý kỹ thuật bài học và bảng kết quả luyện tập.
## Chức năng chính:
##  1. Hiển thị Popup Gợi ý Kỹ thuật (`setup_hint`): Trình bày nội dung văn bản hướng dẫn/lý thuyết có định dạng BBCode.
##  2. Hiển thị Popup Kết quả Luyện tập (`setup_result`):
##     - Điểm tổng kết (Score Circle) và đánh giá (Xuất sắc, Khá tốt, Cần cố gắng).
##     - Các thanh đo tiến độ chi tiết: Độ chuẩn cao độ (Pitch), Độ chuẩn tiết tấu (Rhythm), Kỹ thuật (Tech).
##     - Thông tin bài học kế tiếp được mở khóa.
##  3. Hiệu ứng hoạt họa chuyển cảnh mượt mà (Fade in/out, Scale bounce) và style giao diện phong cách giấy điệp/sơn mài.
## ==============================================================================

extends Control

# ─── Bảng màu giao diện (Phong cách truyền thống Sơn mài & Nhũ vàng) ───────────
const C_GOLD       := Color(0.77, 0.58, 0.15, 1.0) # Vàng kim
const C_GOLD_LIGHT := Color(0.95, 0.82, 0.45, 1.0) # Vàng sáng
const C_RED_SON    := Color(0.09, 0.27, 0.18, 1.0) # Đỏ sơn / Xanh đậm chủ đạo
const C_RED_ERR    := Color(0.70, 0.12, 0.08, 1.0) # Đỏ cảnh báo khi điểm thấp
const C_CREAM      := Color(1.00, 0.97, 0.88, 1.0) # Màu kem giấy điệp
const C_CREAM_DIM  := Color(0.80, 0.76, 0.66, 1.0)
const C_JADE       := Color(0.12, 0.37, 0.23, 1.0) # Xanh ngọc bích cho kết quả xuất sắc
const C_TEXT       := Color(0.13, 0.08, 0.05, 1.0)
const C_TEXT_MUTED := Color(0.43, 0.38, 0.33, 1.0)

# ─── Các tham chiếu Node trên cây giao diện ─────────────────────────────────────
@onready var dim_bg        : ColorRect      = $DimBG                                                                            ## Lớp nền tối mờ
@onready var card          : PanelContainer = $CardContainer                                                                    ## Khung bảng card chính
@onready var title_lbl     : Label          = $CardContainer/MarginContainer/Content/Title                                      ## Tiêu đề popup
@onready var hint_scroll   : ScrollContainer= $CardContainer/MarginContainer/Content/HintScroll                                 ## Khung cuộn nội dung gợi ý
@onready var hint_text     : RichTextLabel  = $CardContainer/MarginContainer/Content/HintScroll/HintText                        ## Văn bản gợi ý kỹ thuật
@onready var result_vbox   : VBoxContainer  = $CardContainer/MarginContainer/Content/ResultVBox                                 ## Khung chứa kết quả luyện tập
@onready var score_circle  : PanelContainer = $CardContainer/MarginContainer/Content/ResultVBox/MainRow/ScoreCircle            ## Khung tròn hiển thị điểm số
@onready var score_val     : Label          = $CardContainer/MarginContainer/Content/ResultVBox/MainRow/ScoreCircle/ScoreM/ScoreV/ScoreVal
@onready var score_lbl     : Label          = $CardContainer/MarginContainer/Content/ResultVBox/MainRow/ScoreCircle/ScoreM/ScoreV/ScoreLabel
@onready var rating_lbl    : Label          = $CardContainer/MarginContainer/Content/ResultVBox/MainRow/DetailsVBox/RatingLabel ## Nhãn đánh giá (Xuất sắc, Khá tốt...)
@onready var rewards_card  : PanelContainer = $CardContainer/MarginContainer/Content/ResultVBox/MainRow/DetailsVBox/RewardsCard
@onready var rewards_lbl   : Label          = $CardContainer/MarginContainer/Content/ResultVBox/MainRow/DetailsVBox/RewardsCard/RewardM/RewardsLabel
@onready var pitch_bar     : ProgressBar    = $CardContainer/MarginContainer/Content/ResultVBox/MetricsVBox/MetricPitch/PitchBar ## Thanh đo cao độ
@onready var pitch_val     : Label          = $CardContainer/MarginContainer/Content/ResultVBox/MetricsVBox/MetricPitch/PitchVal
@onready var rhythm_bar    : ProgressBar    = $CardContainer/MarginContainer/Content/ResultVBox/MetricsVBox/MetricRhythm/RhythmBar ## Thanh đo nhịp điệu
@onready var rhythm_val    : Label          = $CardContainer/MarginContainer/Content/ResultVBox/MetricsVBox/MetricRhythm/RhythmVal
@onready var tech_bar      : ProgressBar    = $CardContainer/MarginContainer/Content/ResultVBox/MetricsVBox/MetricTech/TechBar   ## Thanh đo kỹ thuật
@onready var tech_val      : Label          = $CardContainer/MarginContainer/Content/ResultVBox/MetricsVBox/MetricTech/TechVal
@onready var action_btn    : Button         = $CardContainer/MarginContainer/Content/ActionBtn                                  ## Nút hành động ("Đã hiểu" / "Tiếp tục")

## Tín hiệu bắn ra khi popup đóng lại
signal closed

## Khởi tạo và kích hoạt hiệu ứng hoạt họa xuất hiện (Fade & Scale in)
func _ready() -> void:
	# Ẩn ban đầu để tạo hiệu ứng chuyển cảnh
	modulate.a = 0.0
	card.scale = Vector2(0.9, 0.9)
	card.pivot_offset = card.size / 2.0
	
	_style_card()
	_style_fonts()
	_connect_btn()
	
	# Hiệu ứng chuyển động xuất hiện popup
	var t := create_tween().set_parallel(true)
	t.tween_property(self, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(card, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Thiết lập StyleBox, viền vàng kim và bóng đổ cho Card và các thành phần con
func _style_card() -> void:
	# Khung card: phong cách giấy điệp ấm áp, viền vàng kim, bóng đổ mềm
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.99, 0.98, 0.95, 1.0)
	cs.border_color = C_GOLD
	cs.border_width_left = 4; cs.border_width_right = 4
	cs.border_width_top = 4; cs.border_width_bottom = 4
	cs.corner_radius_top_left = 24; cs.corner_radius_top_right = 24
	cs.corner_radius_bottom_left = 24; cs.corner_radius_bottom_right = 24
	cs.shadow_size = 28
	cs.shadow_color = Color(0.13, 0.08, 0.05, 0.22)
	cs.shadow_offset = Vector2(0, 10)
	card.add_theme_stylebox_override("panel", cs)
	
	# Khung tròn hiển thị điểm số
	var sc := StyleBoxFlat.new()
	sc.bg_color = Color(0.95, 0.93, 0.89, 1.0)
	sc.border_color = C_GOLD_LIGHT
	sc.border_width_left = 3; sc.border_width_right = 3
	sc.border_width_top = 3; sc.border_width_bottom = 3
	sc.corner_radius_top_left = 50; sc.corner_radius_top_right = 50
	sc.corner_radius_bottom_left = 50; sc.corner_radius_bottom_right = 50
	score_circle.add_theme_stylebox_override("panel", sc)
	
	# Khung thông tin phần thưởng / bài tiếp theo
	var rc := StyleBoxFlat.new()
	rc.bg_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.08)
	rc.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25)
	rc.border_width_left = 1; rc.border_width_right = 1
	rc.border_width_top = 1; rc.border_width_bottom = 1
	rc.corner_radius_top_left = 12; rc.corner_radius_top_right = 12
	rc.corner_radius_bottom_left = 12; rc.corner_radius_bottom_right = 12
	rewards_card.add_theme_stylebox_override("panel", rc)
	
	# Định dạng màu sắc các thanh tiến độ
	_style_bar(pitch_bar, C_JADE)
	_style_bar(rhythm_bar, C_GOLD)
	_style_bar(tech_bar, C_RED_SON)
	
	# Định dạng nút hành động chính
	var btn_n := StyleBoxFlat.new()
	btn_n.bg_color = C_RED_SON
	btn_n.border_color = C_GOLD
	btn_n.border_width_bottom = 4
	btn_n.corner_radius_top_left = 16; btn_n.corner_radius_top_right = 16
	btn_n.corner_radius_bottom_left = 16; btn_n.corner_radius_bottom_right = 16
	btn_n.shadow_size = 6
	btn_n.shadow_color = Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.25)
	
	var btn_h := StyleBoxFlat.new()
	btn_h.bg_color = C_RED_SON.lightened(0.12)
	btn_h.border_color = C_GOLD_LIGHT
	btn_h.border_width_bottom = 4
	btn_h.corner_radius_top_left = 16; btn_h.corner_radius_top_right = 16
	btn_h.corner_radius_bottom_left = 16; btn_h.corner_radius_bottom_right = 16
	btn_h.shadow_size = 10
	btn_h.shadow_color = Color(C_RED_SON.r, C_RED_SON.g, C_RED_SON.b, 0.35)
	
	var btn_p := StyleBoxFlat.new()
	btn_p.bg_color = C_RED_SON.darkened(0.15)
	btn_p.border_color = C_GOLD
	btn_p.border_width_bottom = 1
	btn_p.corner_radius_top_left = 16; btn_p.corner_radius_top_right = 16
	btn_p.corner_radius_bottom_left = 16; btn_p.corner_radius_bottom_right = 16
	
	action_btn.add_theme_stylebox_override("normal", btn_n)
	action_btn.add_theme_stylebox_override("hover", btn_h)
	action_btn.add_theme_stylebox_override("pressed", btn_p)
	action_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	action_btn.add_theme_color_override("font_color", C_CREAM)
	action_btn.add_theme_color_override("font_hover_color", C_CREAM)
	action_btn.add_theme_color_override("font_pressed_color", C_CREAM)

## Định dạng thanh ProgressBar với màu fill tùy chọn
func _style_bar(bar: ProgressBar, fill_col: Color) -> void:
	var f := StyleBoxFlat.new()
	f.bg_color = fill_col
	f.corner_radius_top_left = 6; f.corner_radius_top_right = 6
	f.corner_radius_bottom_left = 6; f.corner_radius_bottom_right = 6
	
	var b := StyleBoxFlat.new()
	b.bg_color = Color(0, 0, 0, 0.08)
	b.corner_radius_top_left = 6; b.corner_radius_top_right = 6
	b.corner_radius_bottom_left = 6; b.corner_radius_bottom_right = 6
	
	bar.add_theme_stylebox_override("fill", f)
	bar.add_theme_stylebox_override("background", b)

## Nạp các font chữ cao cấp cho tiêu đề, nhãn đánh giá và điểm số
func _style_fonts() -> void:
	var f_title := load("res://assets/fonts/Lora-Bold.ttf") as FontFile
	var f_body_bold := load("res://assets/fonts/BeVietnamPro-Bold.ttf") as FontFile
	var f_body := load("res://assets/fonts/BeVietnamPro-Regular.ttf") as FontFile
	var f_num := load("res://assets/fonts/Nunito.ttf") as FontFile
	
	if f_title:
		title_lbl.add_theme_font_override("font", f_title)
		title_lbl.add_theme_color_override("font_color", C_RED_SON)
		
	if f_body_bold:
		rating_lbl.add_theme_font_override("font", f_body_bold)
		rewards_lbl.add_theme_font_override("font", f_body_bold)
		action_btn.add_theme_font_override("font", f_body_bold)
		
		for path in ["PitchLabel", "RhythmLabel", "TechLabel"]:
			var lbl = result_vbox.get_node_or_null("MetricsVBox/Metric" + path.replace("Label","") + "/" + path) as Label
			if lbl: lbl.add_theme_font_override("font", f_body_bold)
			
	if f_body:
		hint_text.add_theme_font_override("normal_font", f_body)
		hint_text.add_theme_font_override("bold_font", f_body_bold)
		score_lbl.add_theme_font_override("font", f_body)
		
	if f_num:
		score_val.add_theme_font_override("font", f_num)
		pitch_val.add_theme_font_override("font", f_num)
		rhythm_val.add_theme_font_override("font", f_num)
		tech_val.add_theme_font_override("font", f_num)

	score_lbl.add_theme_color_override("font_color", C_TEXT_MUTED)
	rewards_lbl.add_theme_color_override("font_color", C_RED_SON)
	hint_text.add_theme_color_override("default_color", C_TEXT)
	
	for path in ["Pitch", "Rhythm", "Tech"]:
		var lbl_name = result_vbox.get_node_or_null("MetricsVBox/Metric" + path + "/" + path + "Label") as Label
		var lbl_val = result_vbox.get_node_or_null("MetricsVBox/Metric" + path + "/" + path + "Val") as Label
		if lbl_name: lbl_name.add_theme_color_override("font_color", C_TEXT)
		if lbl_val: lbl_val.add_theme_color_override("font_color", C_TEXT_MUTED)

## Cấu hình hiển thị Popup ở chế độ Gợi ý Kỹ thuật / Lý thuyết
func setup_hint(title: String, body_text: String) -> void:
	title_lbl.text = title.to_upper()
	hint_scroll.visible = true
	result_vbox.visible = false
	hint_text.text = body_text.replace("\n", "\n")
	action_btn.text = "Đã hiểu"

## Cấu hình hiển thị Popup ở chế độ Bảng Kết Quả Luyện Tập
func setup_result(score: float, pitch: float, rhythm: float, tech: float, _reward_xp: int, next_lesson: String) -> void:
	title_lbl.text = "KẾT QUẢ LUYỆN TẬP"
	hint_scroll.visible = false
	result_vbox.visible = true
	
	var iscore := int(score)
	score_val.text = str(iscore)
	
	# Đánh giá xếp loại theo mức điểm
	var rating_text := ""
	var rating_color := C_RED_ERR
	if iscore >= 85:
		rating_text = "Xuất sắc! 🎉"
		rating_color = C_JADE
		score_val.add_theme_color_override("font_color", C_JADE)
	elif iscore >= 70:
		rating_text = "Khá tốt! 👍"
		rating_color = C_GOLD
		score_val.add_theme_color_override("font_color", C_GOLD)
	else:
		rating_text = "Cần cố gắng! 💪"
		rating_color = C_RED_ERR
		score_val.add_theme_color_override("font_color", C_RED_ERR)
		
	rating_lbl.text = rating_text
	rating_lbl.add_theme_color_override("font_color", rating_color)
	
	# Tên bài học tiếp theo
	rewards_lbl.text = "☁ %s" % next_lesson
	
	# Cập nhật giá trị vào các thanh tiến độ chi tiết
	pitch_bar.value = pitch
	pitch_val.text = str(int(pitch)) + "%"
	
	rhythm_bar.value = rhythm
	rhythm_val.text = str(int(rhythm)) + "%"
	
	tech_bar.value = tech
	tech_val.text = str(int(tech)) + "%"
	
	action_btn.text = "Tiếp tục"

## Kết nối sự kiện và hiệu ứng nảy (scale bounce) cho nút hành động
func _connect_btn() -> void:
	action_btn.pressed.connect(_on_action_pressed)
	action_btn.pivot_offset = action_btn.size / 2.0
	action_btn.resized.connect(func() -> void: action_btn.pivot_offset = action_btn.size / 2.0)
	
	action_btn.mouse_entered.connect(func() -> void:
		create_tween().tween_property(action_btn, "scale", Vector2(1.05, 1.05), 0.12)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
			
	action_btn.mouse_exited.connect(func() -> void:
		create_tween().tween_property(action_btn, "scale", Vector2.ONE, 0.12)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))

## Xử lý khi nhấn nút hành động (thoát popup với hiệu ứng mượt và bắn signal closed)
func _on_action_pressed() -> void:
	var t := create_tween().set_parallel(true)
	t.tween_property(self, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.tween_property(card, "scale", Vector2(0.9, 0.9), 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(func() -> void:
		closed.emit()
		queue_free()
	)
