extends Control

const C_GOLD       := Color(0.95, 0.72, 0.18, 1.0)
const C_GOLD_LIGHT := Color(1.00, 0.87, 0.45, 1.0)
const C_JADE       := Color(0.18, 0.62, 0.42, 1.0)
const C_RED_SON    := Color(0.72, 0.12, 0.08, 1.0)
const C_CREAM      := Color(1.00, 0.97, 0.88, 1.0)
const C_CREAM_DIM  := Color(0.75, 0.70, 0.58, 1.0)
const C_BG         := Color(0.07, 0.04, 0.015, 1.0)

const TIPS: Array[String] = [
	"Gợi ý: Đàn tranh có 16 dây, mỗi dây tương ứng một nốt nhạc ngũ cung.",
	"Gợi ý: Kỹ thuật rung dây tạo ra âm thanh đặc trưng của nhạc dân tộc Việt Nam.",
	"Gợi ý: Luyện tập mỗi ngày 15-20 phút hiệu quả hơn học dồn một lúc.",
	"Gợi ý: Sáo trúc là nhạc cụ xuất hiện sớm nhất trong văn hóa Việt Nam.",
	"Gợi ý: Nhạc cung đình Huế (Nhã nhạc) được UNESCO công nhận năm 2003.",
	"Gợi ý: Đàn bầu (độc huyền cầm) chỉ có một dây nhưng chơi được toàn thang âm.",
]

@onready var load_bar    : ProgressBar = $Center/LoadBar
@onready var tip_label   : Label       = $Center/TipLabel
@onready var dots        : HBoxContainer = $Center/Dots
@onready var load_title  : Label       = $Center/LoadTitle

var _progress    := 0.0
var _dot_idx     := 0
var _dot_timer   := 0.0
var _tip_timer   := 0.0
var _tip_idx     := 0

func _ready() -> void:
	modulate.a = 0.0
	_build_style()
	_random_first_tip()
	create_tween().tween_property(self, "modulate:a", 1.0, 0.4)
	_animate_bar()

func _build_style() -> void:
	# Logo
	($LogoSmall as Label).add_theme_color_override("font_color", C_GOLD)
	($LogoSmall as Label).add_theme_color_override("font_outline_color", Color(0.3,0.2,0.02,1))
	($LogoSmall as Label).add_theme_constant_override("outline_size", 5)

	# Load title
	load_title.text = "Đang chuẩn bị trải nghiệm..."
	load_title.add_theme_color_override("font_color", C_CREAM)

	# Progress bar
	var pf := StyleBoxFlat.new()
	pf.bg_color = C_GOLD
	pf.corner_radius_top_left = 12; pf.corner_radius_top_right = 12
	pf.corner_radius_bottom_left = 12; pf.corner_radius_bottom_right = 12
	pf.shadow_size = 14; pf.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.45)
	var pb := StyleBoxFlat.new()
	pb.bg_color = Color(0.18, 0.10, 0.04, 1.0)
	pb.corner_radius_top_left = 12; pb.corner_radius_top_right = 12
	pb.corner_radius_bottom_left = 12; pb.corner_radius_bottom_right = 12
	pb.border_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.3)
	pb.border_width_left = 2; pb.border_width_right = 2; pb.border_width_top = 2; pb.border_width_bottom = 2
	load_bar.add_theme_stylebox_override("fill", pf)
	load_bar.add_theme_stylebox_override("background", pb)

	# Tip
	tip_label.add_theme_color_override("font_color", C_CREAM_DIM)

	# Bottom tag
	($BottomTag as Label).text = "VietStage  ©  2025  ·  Trường Đại Học"
	($BottomTag as Label).add_theme_color_override("font_color", Color(0.40, 0.36, 0.26, 1.0))

	# Dots init
	for d in dots.get_children():
		var cr := d as ColorRect
		cr.color = Color(0.25, 0.16, 0.04, 1.0)
		var rs := StyleBoxFlat.new()
		rs.corner_radius_top_left = 8; rs.corner_radius_top_right = 8
		rs.corner_radius_bottom_left = 8; rs.corner_radius_bottom_right = 8

func _random_first_tip() -> void:
	_tip_idx = randi() % TIPS.size()
	tip_label.text = TIPS[_tip_idx]

func _process(delta: float) -> void:
	# Animate dots
	_dot_timer += delta
	if _dot_timer >= 0.4:
		_dot_timer = 0.0
		_dot_idx = (_dot_idx + 1) % 3
		for i in dots.get_child_count():
			var cr := dots.get_child(i) as ColorRect
			cr.color = C_GOLD if i == _dot_idx else Color(0.25, 0.16, 0.04, 1.0)

	# Rotate tips
	_tip_timer += delta
	if _tip_timer >= 3.5:
		_tip_timer = 0.0
		_tip_idx = (_tip_idx + 1) % TIPS.size()
		var t := create_tween()
		t.tween_property(tip_label, "modulate:a", 0.0, 0.25)
		t.tween_callback(func() -> void: tip_label.text = TIPS[_tip_idx])
		t.tween_property(tip_label, "modulate:a", 1.0, 0.35)

func _animate_bar() -> void:
	# Simulate staged loading
	var t := create_tween()
	t.tween_property(load_bar, "value", 28.0,  0.6).set_trans(Tween.TRANS_QUAD)
	t.tween_callback(func() -> void: load_title.text = "Đang tải nhạc cụ...")
	t.tween_property(load_bar, "value", 55.0,  0.7).set_trans(Tween.TRANS_QUAD)
	t.tween_callback(func() -> void: load_title.text = "Đang tải nhân vật Linh...")
	t.tween_property(load_bar, "value", 79.0,  0.5).set_trans(Tween.TRANS_QUAD)
	t.tween_callback(func() -> void: load_title.text = "Đang tải bài học...")
	t.tween_property(load_bar, "value", 100.0, 0.4).set_trans(Tween.TRANS_QUAD)
	t.tween_callback(func() -> void: load_title.text = "Sẵn sàng!")
	t.tween_callback(func() -> void: _go_main()).set_delay(0.5)

func _go_main() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.45)
	t.tween_callback(func() -> void:
		get_tree().change_scene_to_file("res://scenes/LoginScreen.tscn")
	)
