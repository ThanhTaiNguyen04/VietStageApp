extends "res://scripts/MiniGameBase.gd"

func get_instrument_id() -> String:
	return "dan_tranh"

func get_instrument_title() -> String:
	return "ĐÀN TRANH"

func get_rhythm_desc() -> String:
	return "Gảy phím Đàn Tranh theo nhịp điệu khi vạch quét di chuyển qua các điểm nhịp."

func get_note_desc() -> String:
	return "Lắng nghe âm sắc Đàn Tranh và đoán tên nốt nhạc ngũ cung tương ứng."

func get_melody_desc() -> String:
	return "Lắng nghe chuỗi ngũ cung Đàn Tranh và tìm nốt nhạc còn thiếu [?] trong giai điệu."

func get_note_instrument_label() -> String:
	return "gảy Đàn Tranh cổ truyền"

func get_melody_instrument_name() -> String:
	return "Đàn Tranh"

func get_rhythm_action_text() -> String:
	return "Gảy Đàn Tranh"

func get_rhythm_btn_text() -> String:
	return "🎶 GẢY ĐÀN TRANH (TAP)"
