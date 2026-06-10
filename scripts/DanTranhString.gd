extends Control

# ─── Signals ──────────────────────────────────────────────────────────────────
signal string_plucked(idx: int, note_name: String)
signal string_pressed(idx: int, pitch_cents_offset: float)

# ─── Data ─────────────────────────────────────────────────────────────────────
var string_index:     int   = 0
var note_name:        String = ""
var base_frequency:   float  = 130.81

# ─── Visual States ────────────────────────────────────────────────────────────
var is_plucked        := false
var is_pressed        := false
var is_target         := false
var is_hovered        := false
var press_pos         := Vector2.ZERO

# ─── Animation ────────────────────────────────────────────────────────────────
var pluck_time        := 0.0   # thời gian kể từ lúc gảy (giây)
var pluck_amplitude   := 0.0   # biên độ rung hiện tại [0..1]
var glow_alpha        := 0.0   # độ sáng glow [0..1]
var pulse_phase       := 0.0   # pha cho hiệu ứng pulse target

# ─── Audio ────────────────────────────────────────────────────────────────────
var audio_player:  AudioStreamPlayer = null
var base_stream:   AudioStreamWAV    = null

# ─── Color Palette ────────────────────────────────────────────────────────────
const C_GOLD       := Color(0.95, 0.72, 0.18, 1.0)
const C_GOLD_LIGHT := Color(1.00, 0.92, 0.60, 1.0)
const C_GOLD_DIM   := Color(0.75, 0.55, 0.15, 1.0)
const C_SILVER     := Color(0.90, 0.88, 0.82, 1.0)
const C_ORANGE     := Color(1.00, 0.55, 0.15, 1.0)
const C_RED_GLOW   := Color(0.95, 0.25, 0.10, 1.0)
const C_TARGET     := Color(0.98, 0.82, 0.20, 1.0)

# Wood background colours (alternating rows)
const C_WOOD_A := Color(0.155, 0.088, 0.042, 1.0)  # dark rosewood
const C_WOOD_B := Color(0.205, 0.118, 0.058, 1.0)  # lighter rosewood

# ─── Init ─────────────────────────────────────────────────────────────────────
func init(idx: int, note: String, freq: float, stream: AudioStreamWAV) -> void:
	string_index    = idx
	note_name       = note
	base_frequency  = freq
	base_stream     = stream
	# Chiều cao thoải mái để dễ chạm tay trên mobile (28px mỗi dây)
	custom_minimum_size = Vector2(0, 28)
	size_flags_horizontal = SIZE_EXPAND_FILL
	mouse_filter = MOUSE_FILTER_STOP   # nhận tất cả mouse events

func _ready() -> void:
	queue_redraw()

# ─── Process ──────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	var need_redraw := false

	# Cập nhật animation sau khi gảy
	if pluck_amplitude > 0.0:
		pluck_time    += delta
		pluck_amplitude = max(0.0, pluck_amplitude - delta * 2.8)
		glow_alpha    = pluck_amplitude
		need_redraw   = true

	# Fade glow sau khi amplitude = 0
	if glow_alpha > 0.0 and pluck_amplitude <= 0.0:
		glow_alpha = max(0.0, glow_alpha - delta * 3.5)
		need_redraw = true

	# Pulse animation cho dây đích (target)
	if is_target:
		pulse_phase += delta * 3.5
		need_redraw  = true

	if need_redraw:
		queue_redraw()

# ─── Draw ─────────────────────────────────────────────────────────────────────
func _draw() -> void:
	var w  := size.x
	var h  := size.y
	var cy := h * 0.5

	# ── Định nghĩa vùng không gian ─────────────────────────────────────────
	var left_x   := w * 0.035   # mép trái (số thứ tự dây)
	var str_l    := w * 0.075   # dây bắt đầu
	var bridge_x := w * 0.695   # vị trí nhạn đàn
	var str_r    := w * 0.945   # dây kết thúc
	var right_x  := w           # mép phải (tên nốt)

	# ── 1. Nền gỗ ──────────────────────────────────────────────────────────
	var bg := C_WOOD_A if string_index % 2 == 0 else C_WOOD_B
	draw_rect(Rect2(0, 0, w, h), bg)

	# Hơi sáng hơn ở giữa (highlight mặt gỗ)
	var mid_bright := Color(bg.r + 0.04, bg.g + 0.025, bg.b + 0.01, 0.5)
	draw_rect(Rect2(0, h * 0.15, w, h * 0.70), mid_bright)

	# Đường kẻ phân cách nhẹ ở đáy
	draw_line(Vector2(0, h - 0.5), Vector2(w, h - 0.5), Color(0.05, 0.02, 0.01, 0.7), 1.0)

	# Nếu dây này đang hover → tô sáng nhẹ
	if is_hovered and not is_plucked:
		draw_rect(Rect2(0, 0, w, h), Color(1.0, 0.9, 0.5, 0.05))

	# Nếu là dây đích → pulse glow ở nền
	if is_target:
		var p := (sin(pulse_phase) + 1.0) * 0.5    # 0..1
		draw_rect(Rect2(0, 0, w, h), Color(C_TARGET.r, C_TARGET.g, C_TARGET.b, 0.06 + p * 0.07))

	# ── 2. Nhạn đàn (bridge / saddle) ──────────────────────────────────────
	_draw_bridge(bridge_x, cy, h)

	# ── 3. Dây đàn ─────────────────────────────────────────────────────────
	# Màu dây: treble sáng bạch kim, bass vàng ấm
	var t_color := float(string_index) / 15.0  # 0=bass, 1=treble
	var str_base_col := Color(
		lerp(0.92, 0.78, t_color),   # R
		lerp(0.70, 0.82, t_color),   # G
		lerp(0.25, 0.80, t_color),   # B
		1.0)
	var string_color := str_base_col

	if is_plucked and pluck_amplitude > 0.1:
		string_color = C_GOLD_LIGHT.lerp(str_base_col, 1.0 - pluck_amplitude)
	elif is_pressed:
		string_color = C_ORANGE
	elif is_target:
		var p := (sin(pulse_phase) + 1.0) * 0.5
		string_color = str_base_col.lerp(C_TARGET, 0.3 + p * 0.25)

	# Độ dày dây: bass dày hơn treble
	var str_width := lerpf(2.8, 1.0, t_color)

	# Xây dựng các điểm của đường dây
	var pts := PackedVector2Array()
	pts.append(Vector2(str_l, cy))

	if is_pressed and press_pos.x > str_l and press_pos.x < bridge_x:
		# Nhấn → dây uốn cong xuống về phía ngón tay
		pts.append(Vector2(press_pos.x, press_pos.y))
		pts.append(Vector2(bridge_x, cy))
	else:
		pts.append(Vector2(bridge_x, cy))

	# Phần dây bên phải nhạn: rung nếu vừa gảy
	if pluck_amplitude > 0.005:
		var divs := 10
		var speed := 55.0 + base_frequency * 0.12  # tần số cao rung nhanh hơn
		for k in range(1, divs):
			var ratio := float(k) / float(divs)
			var sx := lerp(bridge_x, str_r, ratio)
			var env := sin(ratio * PI)              # envelope: 0 tại đầu & cuối
			var osc := sin(ratio * PI * 2.0 - pluck_time * speed) * pluck_amplitude * 4.5
			pts.append(Vector2(sx, cy + env * osc))
	pts.append(Vector2(str_r, cy))

	# Bóng đổ dưới dây (shadow)
	var shadow_pts := pts.duplicate()
	for i in shadow_pts.size():
		shadow_pts[i] = shadow_pts[i] + Vector2(0, str_width * 0.7)
	draw_polyline(shadow_pts, Color(0, 0, 0, 0.18), str_width * 0.6, true)

	# Vẽ dây chính
	draw_polyline(pts, string_color, str_width, true)

	# Highlight sáng ở cạnh trên dây (giả kim loại)
	var hl_col := Color(1.0, 1.0, 1.0, 0.22 * (1.0 - t_color * 0.5))
	var hl_pts := pts.duplicate()
	for i in hl_pts.size():
		hl_pts[i] = hl_pts[i] + Vector2(0, -str_width * 0.3)
	draw_polyline(hl_pts, hl_col, str_width * 0.4, true)

	# Target glow outline
	if is_target:
		var p := (sin(pulse_phase) + 1.0) * 0.5
		draw_polyline(pts, Color(C_TARGET.r, C_TARGET.g, C_TARGET.b, 0.28 + p * 0.22), str_width + 5.0, true)

	# Pluck glow (hào quang phát sáng khi gảy)
	if glow_alpha > 0.01:
		draw_polyline(pts, Color(C_GOLD_LIGHT.r, C_GOLD_LIGHT.g, C_GOLD_LIGHT.b, glow_alpha * 0.35), str_width + 7.0, true)
		draw_polyline(pts, Color(1.0, 0.95, 0.70, glow_alpha * 0.18), str_width + 14.0, true)

	# ── 4. Nhãn ─────────────────────────────────────────────────────────────
	var font      := ThemeDB.get_default_theme().get_default_font()
	var num_size  := 11
	var note_size := 12

	# Số thứ tự dây (bên trái)
	var num_alpha := 0.55 + glow_alpha * 0.45
	draw_string(font,
		Vector2(8.0, cy + 4.5),
		str(string_index + 1),
		HORIZONTAL_ALIGNMENT_LEFT, -1,
		num_size,
		Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, num_alpha))

	# Tên nốt (bên phải)
	var note_col := C_GOLD
	if is_target:
		note_col = C_TARGET
	draw_string(font,
		Vector2(str_r + 6.0, cy + 4.5),
		note_name,
		HORIZONTAL_ALIGNMENT_LEFT, -1,
		note_size,
		Color(note_col.r, note_col.g, note_col.b, 0.90))

	# Vòng tròn chỉ vị trí nhấn dây
	if is_pressed:
		draw_circle(press_pos, 5.5, Color(C_RED_GLOW.r, C_RED_GLOW.g, C_RED_GLOW.b, 0.85))
		draw_circle(press_pos, 3.0, Color(1, 0.7, 0.4, 0.9))

# ─── Vẽ nhạn đàn (bridge) ─────────────────────────────────────────────────────
func _draw_bridge(bx: float, cy: float, h: float) -> void:
	var bw := 14.0
	var bh := h * 0.72

	# Thân nhạn đàn hình thang
	var body := PackedVector2Array([
		Vector2(bx - bw * 0.5, h - 1.0),
		Vector2(bx - bw * 0.28, cy - bh * 0.35),
		Vector2(bx + bw * 0.28, cy - bh * 0.35),
		Vector2(bx + bw * 0.5, h - 1.0)
	])
	draw_polygon(body, PackedColorArray([
		Color(0.40, 0.22, 0.06),
		Color(0.65, 0.40, 0.14),
		Color(0.65, 0.40, 0.14),
		Color(0.30, 0.16, 0.05)
	]))

	# Đỉnh nhạn đàn (saddle) - ngà hoặc xương
	draw_rect(
		Rect2(bx - bw * 0.22, cy - bh * 0.35 - 2.5, bw * 0.44, 5.0),
		Color(0.94, 0.91, 0.84))

	# Highlight cạnh trái nhạn
	draw_line(
		Vector2(bx - bw * 0.5, h - 1.0),
		Vector2(bx - bw * 0.28, cy - bh * 0.35),
		Color(0.75, 0.50, 0.18, 0.6), 1.5)

# ─── Input ────────────────────────────────────────────────────────────────────
func _gui_input(event: InputEvent) -> void:
	var w        := size.x
	var h        := size.y
	var cy       := h * 0.5
	var str_l    := w * 0.075
	var bridge_x := w * 0.695
	var str_r    := w * 0.945

	if event is InputEventMouseButton:
		var ev := event as InputEventMouseButton
		if ev.button_index == MOUSE_BUTTON_LEFT:
			if ev.pressed:
				var pos := ev.position
				# Gảy dây: chạm vào vùng bên phải nhạn đàn
				if pos.x >= bridge_x - 10.0 and pos.x <= str_r + 10.0:
					pluck()
				# Nhấn dây: chạm vào vùng bên trái nhạn đàn
				elif pos.x >= str_l - 5.0 and pos.x < bridge_x:
					is_pressed = true
					press_pos  = Vector2(
						clamp(pos.x, str_l + 5.0, bridge_x - 5.0),
						clamp(pos.y, cy, cy + h * 0.48))
					_update_press()
					queue_redraw()
			else:
				if is_pressed:
					is_pressed = false
					_update_press()
					queue_redraw()

	elif event is InputEventMouseMotion:
		var ev := event as InputEventMouseMotion
		# Cập nhật hover state
		is_hovered = true
		if is_pressed:
			press_pos = Vector2(
				clamp(ev.position.x, str_l + 5.0, bridge_x - 5.0),
				clamp(ev.position.y, cy, cy + h * 0.48))
			_update_press()
			queue_redraw()

func _mouse_exited() -> void:
	if is_hovered:
		is_hovered = false
		queue_redraw()
	if is_pressed:
		is_pressed = false
		_update_press()
		queue_redraw()

# ─── Pluck (Gảy dây) ──────────────────────────────────────────────────────────
func pluck() -> void:
	is_plucked    = true
	pluck_time    = 0.0
	pluck_amplitude = 1.0
	glow_alpha    = 1.0

	# Dừng player cũ nếu còn đang phát
	if audio_player and is_instance_valid(audio_player):
		audio_player.stop()
		audio_player.queue_free()
		audio_player = null

	# Tạo AudioStreamPlayer mới
	audio_player = AudioStreamPlayer.new()
	if base_stream != null and base_stream.data.size() > 0:
		audio_player.stream      = base_stream
		audio_player.pitch_scale = _get_current_pitch_scale()
		audio_player.volume_db   = 0.0
		audio_player.bus         = "Master"

		# Thêm AudioStreamPlayer vào scene root để tránh bị free cùng với string node
		var scene_root := get_tree().current_scene
		scene_root.add_child(audio_player)
		audio_player.play()

		# Dọn dẹp sau 3.5 giây (sau khi âm tắt hoàn toàn)
		var temp := audio_player
		get_tree().create_timer(3.5).timeout.connect(func() -> void:
			if is_instance_valid(temp):
				temp.queue_free()
		)
	else:
		# Không có stream → giải phóng player ngay
		audio_player.queue_free()
		audio_player = null

	string_plucked.emit(string_index, note_name)
	queue_redraw()

# ─── Pitch Bend ───────────────────────────────────────────────────────────────
func _get_current_pitch_scale() -> float:
	if not is_pressed:
		return 1.0
	var h       := size.y
	var cy      := h * 0.5
	var max_bend := h * 0.48
	var bend    := clamp((press_pos.y - cy) / max_bend, 0.0, 1.0)
	# Nhấn dây tạo semi-tone lên đến +200 cents (major second)
	return 1.0 + bend * 0.12246  # 2^(2/12) - 1 ≈ 0.12246

func _update_press() -> void:
	var scale := _get_current_pitch_scale()

	# Trượt pitch_scale mượt mà khi đang phát âm
	if audio_player and is_instance_valid(audio_player) and audio_player.playing:
		var tw := create_tween()
		tw.tween_property(audio_player, "pitch_scale", scale, 0.04)

	var cents := (scale - 1.0) * 1630.0
	string_pressed.emit(string_index, cents)
