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
@onready var logo_rect  : Control     = $Center/LogoRect

var _tip_timer := 0.0
var _tip_idx   := 0
var _drum_angle := 0.0

func _ready() -> void:
	modulate.a = 0.0
	_build_style()
	_random_first_tip()
	logo_rect.draw.connect(_draw_dong_son_drum)
	create_tween().tween_property(self, "modulate:a", 1.0, 0.45)
	_animate_bar()

	# Add dynamic vector spinner
	var spinner_script := load("res://scripts/Spinner.gd")
	if spinner_script:
		var spinner := Control.new()
		spinner.set_script(spinner_script)
		$Center.add_child(spinner)
		$Center.move_child(spinner, 4)

func _build_style() -> void:
	app_name.add_theme_color_override("font_color", C_GOLD) # Gold
	load_title.add_theme_color_override("font_color", Color(0.98, 0.97, 0.94, 0.85)) # Light Cream
	tip_label.add_theme_color_override("font_color", Color(0.98, 0.97, 0.94, 0.65)) # Dim Cream
	($BottomTag as Label).add_theme_color_override("font_color", Color(0.98, 0.97, 0.94, 0.30))

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
	_drum_angle += delta
	logo_rect.queue_redraw()
	
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
	t.tween_callback(func() -> void: load_title.text = "Đang tải nghệ sĩ ảo cô Mai...")
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

func _draw_dong_son_drum() -> void:
	var center := logo_rect.size / 2.0
	var gold_col := Color(0.95, 0.72, 0.18)
	var gold_dim := Color(0.95, 0.72, 0.18, 0.25)
	var gold_very_dim := Color(0.95, 0.72, 0.18, 0.10)

	# 1. Vòng tròn tiến trình ngoài cùng (Outer Progress Ring)
	var r_outer := minf(center.x, center.y) - 10.0
	# Vòng nền mờ
	logo_rect.draw_arc(center, r_outer, 0.0, TAU, 64, gold_very_dim, 1.5, true)
	# Cung tiến trình thực tế
	var progress := load_bar.value / 100.0
	logo_rect.draw_arc(center, r_outer, -PI/2.0, -PI/2.0 + progress * TAU, 64, gold_col, 2.5, true)

	# 2. Vòng tròn hình học trong (Outer Geometric rings - quay ngược chiều kim đồng hồ)
	var rot_ccw := -_drum_angle * 0.15
	logo_rect.draw_arc(center, r_outer - 15.0, 0.0, TAU, 64, gold_dim, 1.0, true)
	
	# Vẽ các vạch đứt khúc hoa văn hình học quay ngược chiều kim đồng hồ
	var dash_count := 36
	for i in range(dash_count):
		var angle := rot_ccw + i * (TAU / dash_count)
		var p1 := center + Vector2(cos(angle), sin(angle)) * (r_outer - 22.0)
		var p2 := center + Vector2(cos(angle), sin(angle)) * (r_outer - 27.0)
		logo_rect.draw_line(p1, p2, gold_very_dim, 1.0)

	# 3. Vòng tròn Chim Lạc (Lac Birds Ring - quay xuôi chiều kim đồng hồ)
	var rot_cw := _drum_angle * 0.25
	var r_birds := r_outer - 44.0
	logo_rect.draw_arc(center, r_birds, 0.0, TAU, 64, gold_very_dim, 1.0, true)
	
	var bird_count := 4
	for i in range(bird_count):
		var angle := rot_cw + i * (TAU / bird_count)
		var bird_pos := center + Vector2(cos(angle), sin(angle)) * r_birds
		
		# Hướng chuyển động của chim (tiếp tuyến với vòng tròn)
		var dir_tangent := Vector2(-sin(angle), cos(angle))
		var dir_normal := Vector2(cos(angle), sin(angle))
		
		# Vẽ hình Chim Lạc cách điệu từ 4 điểm đa giác
		var p1 := bird_pos + dir_tangent * 16.0 # Mỏ chim hướng về trước
		var p2 := bird_pos - dir_tangent * 10.0 + dir_normal * 4.0 # Cánh trên
		var p3 := bird_pos - dir_tangent * 10.0 - dir_normal * 4.0 # Cánh dưới
		var p4 := bird_pos - dir_tangent * 14.0 # Đuôi chim kéo dài
		
		logo_rect.draw_colored_polygon(PackedVector2Array([p1, p2, p4, p3]), gold_col)

	# 4. Biểu tượng Mặt Trời / Ngôi sao Trung Tâm trống đồng Đông Sơn
	var pulse := 1.0 + sin(_drum_angle * 3.0) * 0.06
	var r_sun := 22.0 * pulse
	logo_rect.draw_circle(center, r_sun, gold_col)
	logo_rect.draw_circle(center, r_sun - 3.0, Color(0.38, 0.0, 0.0, 1.0)) # Tạo rãnh màu đỏ giữa nhân và tia
	logo_rect.draw_circle(center, r_sun - 6.0, gold_col)
	
	# 12 tia mặt trời đối xứng
	var ray_count := 12
	for i in range(ray_count):
		var angle := _drum_angle * 0.04 + i * (TAU / ray_count)
		var p1 := center + Vector2(cos(angle), sin(angle)) * (r_sun - 4.0)
		
		var side_angle_1 := angle - 0.12
		var side_angle_2 := angle + 0.12
		
		var p2 := center + Vector2(cos(side_angle_1), sin(side_angle_1)) * (r_sun + 18.0)
		var p3 := center + Vector2(cos(angle), sin(angle)) * (r_sun + 28.0)
		var p4 := center + Vector2(cos(side_angle_2), sin(side_angle_2)) * (r_sun + 18.0)
		
		logo_rect.draw_colored_polygon(PackedVector2Array([p1, p2, p3, p4]), gold_col)
