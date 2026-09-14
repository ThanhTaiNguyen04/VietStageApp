extends "res://scripts/MiniGameBase.gd"

func get_instrument_id() -> String:
	return "dan_bau"

func get_instrument_title() -> String:
	return "ĐÀN BẦU"

func get_rhythm_desc() -> String:
	return "Uốn cần Đàn Bầu theo nhịp điệu khi vạch quét di chuyển qua các điểm nhịp."

func get_note_desc() -> String:
	return "Lắng nghe âm bồi Đàn Bầu và đoán tên nốt nhạc ngũ cung tương ứng."

func get_melody_desc() -> String:
	return "Lắng nghe chuỗi ngũ cung Đàn Bầu và tìm nốt nhạc còn thiếu [?] trong giai điệu."

func get_note_instrument_label() -> String:
	return "âm bồi sâu lắng của Đàn Bầu"

func get_melody_instrument_name() -> String:
	return "Đàn Bầu"

func get_rhythm_action_text() -> String:
	return "Uốn cần Đàn Bầu"

func get_rhythm_btn_text() -> String:
	return "🎸 UỐN CẦN ĐÀN BẦU (TAP)"
