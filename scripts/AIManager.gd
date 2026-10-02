## ==============================================================================
## File: AIManager.gd
## Mô tả: Quản lý kết nối mạng HTTP và gọi API dịch vụ MaiBrain AI (cô giáo Mai).
## Chức năng chính:
##  1. Gửi câu hỏi của người học lên máy chủ backend AI cùng với ngữ cảnh (context) hiện tại
##     (nhạc cụ nào, bài học nào, level nào, màn hình nào).
##  2. Nhận phản hồi dạng Structured JSON chuẩn hóa từ máy chủ, kiểm tra tính hợp lệ dữ liệu.
##  3. Bóc tách câu trả lời (answer), cảm xúc của cô Mai (emotion: vui, buồn, ngạc nhiên...),
##     và nguồn tài liệu tham khảo (sources).
##  4. Bắn các tín hiệu (signals) để giao diện chat và nhân vật 3D phản ứng tương ứng.
## ==============================================================================

class_name AIManager
extends HTTPRequest

const AppConfig = preload("res://scripts/AppConfig.gd")

## --- CÁC TÍN HIỆU (SIGNALS) ---
signal response_received(text: String, emotion: String)       ## Phát ra khi nhận đầy đủ câu trả lời từ AI
signal response_chunk_received(text: String, emotion: String) ## Phát ra khi nhận một đoạn câu trả lời (cho streaming)
signal response_finished()                                   ## Phát ra khi AI đã hoàn tất phản hồi
signal request_failed(reason: String)                         ## Phát ra khi có lỗi (mất mạng, lỗi server, timeout...)

## Cấu hình kết nối API
@export var api_url: String = ""
@export var model_name: String = "mai-musician-fast"
@export var use_structured_json: bool = true                 ## Bắt buộc dùng phản hồi JSON chuẩn hóa
@export var api_key: String = ""

## Đối tượng HTTPClient xử lý kết nối trực tiếp
var client: HTTPClient = null
var is_connecting := false
var is_requesting := false
var pending_prompt := ""                                     ## Câu hỏi người dùng đang chờ gửi

## Ngữ cảnh hội thoại (Context)
var instrument_context := "general"                          ## Ngữ cảnh nhạc cụ: "dan_tranh", "sao_truc", "general"
var level_code := ""                                         ## Mã cấp độ hiện tại (ví dụ: "level_1")
var lesson_code := ""                                        ## Mã bài học hiện tại (ví dụ: "dan_tranh_level_1_bai_1")
var screen_context := ""                                     ## Vị trí màn hình đang mở (ví dụ: "virtual_room")
var session_id := ""                                         ## Mã phiên hội thoại ngẫu nhiên để duy trì context
var last_sources: Array[String] = []                         ## Nguồn tài liệu AI tham khảo cho câu trả lời vừa nhận
var last_in_scope := false                                   ## Câu hỏi có nằm trong phạm vi âm nhạc dân tộc không
var last_status := ""                                        ## Trạng thái câu trả lời (ANSWERED, OUT_OF_SCOPE, INSUFFICIENT_KNOWLEDGE)
var _response_bytes := PackedByteArray()                     ## Buffer lưu dữ liệu byte trả về từ HTTP stream
var _request_started_ms := 0                                 ## Mốc thời gian bắt đầu gửi request (để tính timeout)

var structured_buffer := ""                                  ## Chuỗi JSON hoàn chỉnh nhận từ server
var parsed_emotion := "neutral"                              ## Cảm xúc đã bóc tách: joy, sad, angry, surprised, neutral
var _http_status := 0                                        ## Mã trạng thái HTTP (200, 404, 500...)

## Khởi tạo node, lấy URL cấu hình và reset phiên chat ban đầu
func _init() -> void:
	api_url = AppConfig.get_maibrain_chat_url()
	reset_conversation()

func _ready() -> void:
	set_process(false)
	if api_url.is_empty():
		api_url = AppConfig.get_maibrain_chat_url()
	if api_key.is_empty():
		api_key = OS.get_environment("MAIBRAIN_API_KEY")

## Khởi tạo lại phiên hội thoại mới: tạo sessionId ngẫu nhiên và xóa bộ đệm cũ
func reset_conversation() -> void:
	_close_client()
	var crypto := Crypto.new()
	var random_bytes: PackedByteArray = crypto.generate_random_bytes(16)
	session_id = random_bytes.hex_encode()
	last_sources.clear()
	_reset_response_state()

## Thiết lập ngữ cảnh phòng học (nhạc cụ, cấp độ, bài học) cho AI trước khi hỏi
func configure_context(context: Dictionary) -> void:
	instrument_context = str(context.get("instrumentContext", context.get("instrument_context", instrument_context)))
	level_code = str(context.get("levelCode", ""))
	lesson_code = str(context.get("lessonCode", ""))
	screen_context = str(context.get("screenContext", ""))

## Gửi câu hỏi của người dùng lên AI server
func send_prompt(user_prompt: String) -> void:
	var clean_prompt := user_prompt.strip_edges()
	if clean_prompt.is_empty():
		request_failed.emit("Câu hỏi đang để trống.")
		return
	if api_url.is_empty():
		api_url = AppConfig.get_maibrain_chat_url()
	if api_url.is_empty():
		request_failed.emit("Chưa cấu hình URL MaiBrain.")
		return

	_close_client()
	pending_prompt = clean_prompt
	_reset_response_state()
	_request_started_ms = Time.get_ticks_msec()
	_connect_to_server()

## Xóa trạng thái và dữ liệu nhận về của câu hỏi trước
func _reset_response_state() -> void:
	structured_buffer = ""
	parsed_emotion = "neutral"
	_http_status = 0
	_response_bytes.clear()
	last_sources.clear()
	last_in_scope = false
	last_status = ""

## Khởi tạo kết nối Socket TCP/TLS tới server MaiBrain
func _connect_to_server() -> void:
	var target := _parse_api_target()
	if target.is_empty():
		request_failed.emit("URL MaiBrain không hợp lệ.")
		return

	client = HTTPClient.new()
	var use_tls: bool = bool(target.get("use_tls", false))
	var host: String = str(target.get("host", ""))
	var port: int = int(target.get("port", 443 if use_tls else 80))
	var err := OK
	if use_tls:
		err = client.connect_to_host(host, port, TLSOptions.client())
	else:
		err = client.connect_to_host(host, port)
	if err != OK:
		request_failed.emit("Không thể kết nối tới MaiBrain tại %s:%d." % [host, port])
		client = null
		return

	is_connecting = true
	is_requesting = false
	set_process(true)

## Vòng lặp xử lý trạng thái kết nối HTTP qua từng frame
func _process(_delta: float) -> void:
	if client == null:
		set_process(false)
		return
	# Kiểm tra timeout (110 giây) nếu server phản hồi quá lâu
	if Time.get_ticks_msec() - _request_started_ms > 110000:
		request_failed.emit("Mai trả lời quá lâu. Bạn vui lòng thử lại.")
		_close_client()
		return

	client.poll()
	var status := client.get_status()
	# Giai đoạn 1: Đang kết nối tới host
	if is_connecting:
		if status == HTTPClient.STATUS_CONNECTED:
			is_connecting = false
			_send_http_request()
		elif status in [HTTPClient.STATUS_CONNECTION_ERROR, HTTPClient.STATUS_CANT_CONNECT, HTTPClient.STATUS_CANT_RESOLVE]:
			request_failed.emit("Không thể kết nối tới máy chủ AI cô Mai.")
			_close_client()
		return

	if not is_requesting:
		return

	# Giai đoạn 2: Đang nhận dữ liệu body trả về từ server
	if status == HTTPClient.STATUS_BODY:
		if client.has_response():
			_http_status = client.get_response_code()
		var chunk := client.read_response_body_chunk()
		if not chunk.is_empty():
			_response_bytes.append_array(chunk)
	# Giai đoạn 3: Nhận xong toàn bộ dữ liệu phản hồi
	elif status == HTTPClient.STATUS_CONNECTED:
		is_requesting = false
		structured_buffer = _response_bytes.get_string_from_utf8()
		_finish_structured_response()
		_close_client()
	# Xử lý khi mất kết nối giữa chừng
	elif status in [HTTPClient.STATUS_CONNECTION_ERROR, HTTPClient.STATUS_DISCONNECTED]:
		is_requesting = false
		request_failed.emit("Mất kết nối trong lúc cô Mai đang trả lời.")
		_close_client()

## Đóng gói payload JSON và gửi HTTP POST request
func _send_http_request() -> void:
	var target := _parse_api_target()
	if target.is_empty():
		request_failed.emit("URL MaiBrain không hợp lệ.")
		_close_client()
		return

	var headers := PackedStringArray(["Content-Type: application/json"])
	if not api_key.is_empty():
		headers.append("X-MaiBrain-Key: " + api_key)

	# Dữ liệu gửi lên AI bao gồm prompt và ngữ cảnh học tập
	var payload: Dictionary = {
		"model": model_name,
		"prompt": pending_prompt,
		"instrument_context": instrument_context,
		"instrumentContext": instrument_context,
		"levelCode": level_code,
		"lessonCode": lesson_code,
		"screenContext": screen_context,
		"sessionId": session_id
	}
	var body := JSON.stringify(payload)
	var path: String = str(target.get("path", "/api/chat"))
	var err := client.request(HTTPClient.METHOD_POST, path, headers, body)
	if err != OK:
		request_failed.emit("Không thể gửi câu hỏi tới MaiBrain.")
		_close_client()
	else:
		is_requesting = true

## Phân tích chuỗi URL thành cấu trúc (host, port, path, use_tls)
func _parse_api_target() -> Dictionary:
	var clean_url := api_url.strip_edges()
	var use_tls := clean_url.begins_with("https://")
	if clean_url.begins_with("http://"):
		clean_url = clean_url.substr(7)
	elif use_tls:
		clean_url = clean_url.substr(8)
	else:
		return {}

	var path := "/api/chat"
	var slash_index := clean_url.find("/")
	if slash_index != -1:
		path = clean_url.substr(slash_index)
		clean_url = clean_url.substr(0, slash_index)

	if path.ends_with("/api/chat"):
		path += "/json"

	var host := clean_url
	var port := 443 if use_tls else 80
	var colon_index := clean_url.rfind(":")
	if colon_index != -1:
		host = clean_url.substr(0, colon_index)
		port = int(clean_url.substr(colon_index + 1))
	if host.is_empty():
		return {}
	return {"use_tls": use_tls, "host": host, "port": port, "path": path}

## Bóc tách và kiểm tra tính hợp lệ của chuỗi JSON phản hồi từ AI
func _finish_structured_response() -> bool:
	if _http_status in [404, 405]:
		request_failed.emit("Máy chủ MaiBrain cần cập nhật API trả lời có kiểm soát.")
		return false
	if _http_status < 200 or _http_status >= 300:
		var server_message := _extract_json_error(structured_buffer)
		request_failed.emit(server_message if not server_message.is_empty() else "MaiBrain trả lỗi HTTP %d." % _http_status)
		return false

	var parsed: Variant = JSON.parse_string(structured_buffer)
	if not parsed is Dictionary:
		request_failed.emit("MaiBrain trả dữ liệu JSON không hợp lệ.")
		return false
	var data: Dictionary = parsed
	if not is_valid_chat_response(data):
		request_failed.emit("MaiBrain trả dữ liệu chưa được xác nhận. Bạn vui lòng thử lại.")
		return false
	var answer := str(data.get("answer", "")).strip_edges()
	if answer.is_empty():
		request_failed.emit("MaiBrain không trả nội dung câu trả lời.")
		return false

	# Chuẩn hóa cảm xúc và lưu danh sách nguồn trích dẫn
	parsed_emotion = _normalize_emotion(str(data.get("emotion", "neutral")))
	last_in_scope = data["inScope"]
	last_status = data["status"]
	last_sources.clear()
	var source_values: Variant = data.get("sources", [])
	if source_values is Array:
		for source: Variant in source_values:
			last_sources.append(str(source))

	# Bắn tín hiệu để UI và nhân vật 3D xử lý
	response_chunk_received.emit(answer, parsed_emotion)
	response_received.emit(answer, parsed_emotion)
	response_finished.emit()
	return false

## Kiểm tra cấu trúc dữ liệu JSON từ AI có đúng chuẩn quy định không
static func is_valid_chat_response(data: Dictionary) -> bool:
	if data.get("success") != true or not data.get("inScope") is bool:
		return false
	if not data.get("answer") is String or str(data["answer"]).strip_edges().is_empty():
		return false
	if not data.get("sources") is Array:
		return false
	for source: Variant in data["sources"]:
		if not source is String or str(source).is_empty():
			return false
	match data.get("status", ""):
		"ANSWERED":
			return data["inScope"] == true and not data["sources"].is_empty()
		"OUT_OF_SCOPE":
			return data["inScope"] == false and data["sources"].is_empty()
		"INSUFFICIENT_KNOWLEDGE":
			return data["inScope"] == true and data["sources"].is_empty()
	return false

## Trích xuất thông báo lỗi nếu server trả về dạng JSON lỗi
func _extract_json_error(raw: String) -> String:
	var parsed: Variant = JSON.parse_string(raw)
	if parsed is Dictionary:
		return str(parsed.get("answer", parsed.get("message", parsed.get("error", ""))))
	return ""

## Chuẩn hóa tên cảm xúc thành các nhãn cơ bản (joy, sad, angry, surprised, neutral)
func _normalize_emotion(value: String) -> String:
	var normalized := value.to_lower().strip_edges()
	var emotion_mapping := {
		"joy": "joy", "happy": "joy",
		"sad": "sad", "sorrow": "sad",
		"angry": "angry", "anger": "angry",
		"surprised": "surprised", "surprise": "surprised",
		"neutral": "neutral"
	}
	return str(emotion_mapping.get(normalized, "neutral"))

## Dọn dẹp và đóng kết nối HTTPClient
func _close_client() -> void:
	is_connecting = false
	is_requesting = false
	if client != null:
		client.close()
		client = null
	set_process(false)
