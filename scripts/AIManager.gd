class_name AIManager
extends HTTPRequest

signal response_received(text: String, emotion: String)
signal response_chunk_received(text: String, emotion: String)
signal response_finished()
signal request_failed(reason: String)

@export var api_url: String = "https://anew-handgrip-elope.ngrok-free.dev/api/chat"
@export var model_name: String = "mai-musician-fast"
# Retained for existing scenes; validated JSON is now mandatory.
@export var use_structured_json: bool = true
@export var api_key: String = ""

var client: HTTPClient = null
var is_connecting := false
var is_requesting := false
var pending_prompt := ""

var instrument_context := "general"
var level_code := ""
var lesson_code := ""
var screen_context := ""
var session_id := ""
var last_sources: Array[String] = []
var last_in_scope := false
var last_status := ""
var _response_bytes := PackedByteArray()
var _request_started_ms := 0

var structured_buffer := ""
var parsed_emotion := "neutral"
var _http_status := 0

func _ready() -> void:
	set_process(false)
	if api_key.is_empty():
		api_key = OS.get_environment("MAIBRAIN_API_KEY")
	reset_conversation()

func reset_conversation() -> void:
	_close_client()
	var crypto := Crypto.new()
	var random_bytes: PackedByteArray = crypto.generate_random_bytes(16)
	session_id = random_bytes.hex_encode()
	last_sources.clear()
	_reset_response_state()

func configure_context(context: Dictionary) -> void:
	instrument_context = str(context.get("instrumentContext", context.get("instrument_context", instrument_context)))
	level_code = str(context.get("levelCode", ""))
	lesson_code = str(context.get("lessonCode", ""))
	screen_context = str(context.get("screenContext", ""))

func send_prompt(user_prompt: String) -> void:
	var clean_prompt := user_prompt.strip_edges()
	if clean_prompt.is_empty():
		request_failed.emit("Câu hỏi đang để trống.")
		return
	if api_url.is_empty():
		request_failed.emit("Chưa cấu hình URL MaiBrain.")
		return

	_close_client()
	pending_prompt = clean_prompt
	# Only the validated JSON contract can reach text and speech output.
	_reset_response_state()
	_request_started_ms = Time.get_ticks_msec()
	_connect_to_server()

func _reset_response_state() -> void:
	structured_buffer = ""
	parsed_emotion = "neutral"
	_http_status = 0
	_response_bytes.clear()
	last_sources.clear()
	last_in_scope = false
	last_status = ""

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

func _process(_delta: float) -> void:
	if client == null:
		set_process(false)
		return
	if Time.get_ticks_msec() - _request_started_ms > 110000:
		request_failed.emit("Mai trả lời quá lâu. Bạn vui lòng thử lại.")
		_close_client()
		return

	client.poll()
	var status := client.get_status()
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

	if status == HTTPClient.STATUS_BODY:
		if client.has_response():
			_http_status = client.get_response_code()
		var chunk := client.read_response_body_chunk()
		if not chunk.is_empty():
			_response_bytes.append_array(chunk)
	elif status == HTTPClient.STATUS_CONNECTED:
		is_requesting = false
		structured_buffer = _response_bytes.get_string_from_utf8()
		_finish_structured_response()
		_close_client()
	elif status in [HTTPClient.STATUS_CONNECTION_ERROR, HTTPClient.STATUS_DISCONNECTED]:
		is_requesting = false
		request_failed.emit("Mất kết nối trong lúc cô Mai đang trả lời.")
		_close_client()

func _send_http_request() -> void:
	var target := _parse_api_target()
	if target.is_empty():
		request_failed.emit("URL MaiBrain không hợp lệ.")
		_close_client()
		return

	var headers := PackedStringArray(["Content-Type: application/json", "ngrok-skip-browser-warning: 1"])
	if not api_key.is_empty():
		headers.append("X-MaiBrain-Key: " + api_key)

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

	parsed_emotion = _normalize_emotion(str(data.get("emotion", "neutral")))
	last_in_scope = data["inScope"]
	last_status = data["status"]
	last_sources.clear()
	var source_values: Variant = data.get("sources", [])
	if source_values is Array:
		for source: Variant in source_values:
			last_sources.append(str(source))

	response_chunk_received.emit(answer, parsed_emotion)
	response_received.emit(answer, parsed_emotion)
	response_finished.emit()
	return false

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

func _extract_json_error(raw: String) -> String:
	var parsed: Variant = JSON.parse_string(raw)
	if parsed is Dictionary:
		return str(parsed.get("answer", parsed.get("message", parsed.get("error", ""))))
	return ""

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

func _close_client() -> void:
	is_connecting = false
	is_requesting = false
	if client != null:
		client.close()
		client = null
	set_process(false)
