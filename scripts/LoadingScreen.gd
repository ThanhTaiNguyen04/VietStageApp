extends Control

const C_GOLD      := Color(0.95, 0.72, 0.18, 1.0)
const C_WHITE_DIM := Color(1.00, 1.00, 1.00, 0.42)
const C_DIM       := Color(1.00, 1.00, 1.00, 0.24)

const TIPS: Array[String] = [
	"Đàn tranh có 16 dây, mỗi dây tương ứng một nốt nhạc ngũ cung.",
	"Kỹ thuật rung dây tạo âm thanh đặc trưng của nhạc dân tộc Việt Nam.",
	"Luyện tập 15-20 phút mỗi ngày hiệu quả hơn học dồn một lúc.",
	"Sáo trúc là nhạc cụ xuất hiện sớm nhất trong văn hóa Việt Nam.",
	"Nhã nhạc cung đình Huế được UNESCO công nhận năm 2003.",
	"Đàn bầu chỉ một dây nhưng chơi được toàn thang âm.",
]

@onready var load_bar   : ProgressBar = $BarArea/LoadBar
@onready var tip_label  : Label       = $Center/TipLabel
@onready var load_title : Label       = $Center/LoadTitle
@onready var app_name   : Label       = $Center/AppName

var _tip_timer := 0.0
var _tip_idx   := 0

func _ready() -> void:
	modulate.a = 0.0
	_build_style()
	_random_first_tip()
	create_tween().tween_property(self, "modulate:a", 1.0, 0.45)
	_animate_bar()

func _build_style() -> void:
	app_name.add_theme_color_override("font_color", Color(0.70, 0.12, 0.08, 1.0)) # lacquer red app name
	load_title.add_theme_color_override("font_color", Color(0.13, 0.08, 0.05, 0.70)) # Espresso
	tip_label.add_theme_color_override("font_color", Color(0.43, 0.38, 0.33, 1.0)) # Taupe
	($BottomTag as Label).add_theme_color_override("font_color", Color(0.13, 0.08, 0.05, 0.30))

	var pf := StyleBoxFlat.new()
	pf.bg_color = C_GOLD
	pf.corner_radius_top_left    = 3; pf.corner_radius_top_right    = 3
	pf.corner_radius_bottom_left = 3; pf.corner_radius_bottom_right = 3
	pf.shadow_size  = 6
	pf.shadow_color = Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.25)

	var pb := StyleBoxFlat.new()
	pb.bg_color = Color(0, 0, 0, 0)

	load_bar.add_theme_stylebox_override("fill",       pf)
	load_bar.add_theme_stylebox_override("background", pb)

func _random_first_tip() -> void:
	_tip_idx = randi() % TIPS.size()
	tip_label.text = TIPS[_tip_idx]

func _process(delta: float) -> void:
	_tip_timer += delta
	if _tip_timer >= 4.0:
		_tip_timer = 0.0
		_tip_idx = (_tip_idx + 1) % TIPS.size()
		var t := create_tween()
		t.tween_property(tip_label, "modulate:a", 0.0, 0.22)
		t.tween_callback(func() -> void: tip_label.text = TIPS[_tip_idx])
		t.tween_property(tip_label, "modulate:a", 1.0, 0.32)

func _animate_bar() -> void:
	var t := create_tween()
	t.tween_property(load_bar, "value", 22.0,  0.70).set_trans(Tween.TRANS_CUBIC)
	t.tween_callback(func() -> void: load_title.text = "Đang tải nhạc cụ...")
	t.tween_property(load_bar, "value", 51.0,  0.80).set_trans(Tween.TRANS_CUBIC)
	t.tween_callback(func() -> void: load_title.text = "Đang tải nhân vật Linh...")
	t.tween_property(load_bar, "value", 78.0,  0.60).set_trans(Tween.TRANS_CUBIC)
	t.tween_callback(func() -> void: load_title.text = "Đang tải bài học...")
	t.tween_property(load_bar, "value", 100.0, 0.45).set_trans(Tween.TRANS_CUBIC)
	t.tween_callback(func() -> void: load_title.text = "Sẵn sàng!")
	t.tween_interval(0.5)
	t.tween_callback(_go_main)

func _go_main() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.42).set_trans(Tween.TRANS_CUBIC)
	t.tween_callback(func() -> void:
		get_tree().change_scene_to_file("res://scenes/LoginScreen.tscn")
	)
