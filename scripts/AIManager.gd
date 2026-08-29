class_name AIManager
extends HTTPRequest

signal response_received(text: String, emotion: String)
signal response_chunk_received(text: String, emotion: String)
signal response_finished()
signal request_failed(reason: String)

@export var api_url: String = "https://anew-handgrip-elope.ngrok-free.dev/api/chat"
@export var model_name: String = "mai-musician-fast"
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
var last_in_scope := true

var chunk_buffer := ""
var structured_buffer := ""
var current_sentence := ""
var parsed_emotion := "neutral"
var emotion_checked := false
var full_response_accumulated := ""

var _request_uses_json := false
var _fallback_attempted := false
var _http_status := 0

func _ready() -> void:
	set_process(false)
	if api_key.is_empty():
		api_key = OS.get_environment("MAIBRAIN_API_KEY")
	reset_conversation()

func reset_conversation() -> void:
	var crypto := Crypto.new()
	var random_bytes: PackedByteArray = crypto.generate_random_bytes(16)
	session_id = random_bytes.hex_encode()
	last_sources.clear()
	last_in_scope = true
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
	_fallback_attempted = false
	_request_uses_json = use_structured_json
	_reset_response_state()
	_connect_to_server()

func _reset_response_state() -> void:
	chunk_buffer = ""
	structured_buffer = ""
	current_sentence = ""
	parsed_emotion = "neutral"
	emotion_checked = false
	full_response_accumulated = ""
	_http_status = 0

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
			if _request_uses_json:
				structured_buffer += chunk.get_string_from_utf8()
			else:
				_process_stream_chunk(chunk)
	elif status == HTTPClient.STATUS_CONNECTED:
		is_requesting = false
		if _request_uses_json:
			var retried_with_streaming := _finish_structured_response()
			if retried_with_streaming:
				return
		else:
			_finish_streaming_response()
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

	if _request_uses_json:
		if path.ends_with("/api/chat"):
			path += "/json"
	elif path.ends_with("/api/chat/json"):
		path = path.trim_suffix("/json")

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
	if _http_status in [404, 405] and not _fallback_attempted:
		_retry_with_streaming_endpoint()
		return true
	if _http_status < 200 or _http_status >= 300:
		var server_message := _extract_json_error(structured_buffer)
		request_failed.emit(server_message if not server_message.is_empty() else "MaiBrain trả lỗi HTTP %d." % _http_status)
		return false

	var parsed: Variant = JSON.parse_string(structured_buffer)
	if not parsed is Dictionary:
		request_failed.emit("MaiBrain trả dữ liệu JSON không hợp lệ.")
		return false
	var data: Dictionary = parsed
	var answer := str(data.get("answer", "")).strip_edges()
	if answer.is_empty():
		request_failed.emit("MaiBrain không trả nội dung câu trả lời.")
		return false

	parsed_emotion = _normalize_emotion(str(data.get("emotion", "neutral")))
	last_in_scope = bool(data.get("inScope", true))
	last_sources.clear()
	var source_values: Variant = data.get("sources", [])
	if source_values is Array:
		for source: Variant in source_values:
			last_sources.append(str(source))

	response_chunk_received.emit(answer, parsed_emotion)
	response_received.emit(answer, parsed_emotion)
	response_finished.emit()
	return false

func _retry_with_streaming_endpoint() -> void:
	_fallback_attempted = true
	_request_uses_json = false
	_close_client()
	_reset_response_state()
	_connect_to_server()

func _extract_json_error(raw: String) -> String:
	var parsed: Variant = JSON.parse_string(raw)
	if parsed is Dictionary:
		return str(parsed.get("answer", parsed.get("message", parsed.get("error", ""))))
	return ""

func _process_stream_chunk(chunk: PackedByteArray) -> void:
	chunk_buffer += chunk.get_string_from_utf8()
	while "\n" in chunk_buffer:
		var index := chunk_buffer.find("\n")
		var line := chunk_buffer.substr(0, index).strip_edges()
		chunk_buffer = chunk_buffer.substr(index + 1)
		if not line.is_empty():
			_parse_stream_json_line(line)

func _parse_stream_json_line(line: String) -> void:
	var parsed: Variant = JSON.parse_string(line)
	if not parsed is Dictionary:
		return
	var data: Dictionary = parsed
	var token := str(data.get("response", ""))
	if not token.is_empty():
		_handle_token(token)

func _handle_token(token: String) -> void:
	current_sentence += token
	full_response_accumulated += token
	if not emotion_checked:
		var trimmed := current_sentence.strip_edges()
		if trimmed.begins_with("[") and "]" in trimmed:
			var close_index := trimmed.find("]")
			parsed_emotion = _normalize_emotion(trimmed.substr(1, close_index - 1))
			current_sentence = trimmed.substr(close_index + 1)
			emotion_checked = true
		elif not trimmed.begins_with("[") and trimmed.length() > 12:
			emotion_checked = true

	if emotion_checked and _contains_sentence_delimiter(token):
		var sentence := current_sentence.strip_edges()
		if sentence.length() > 2:
			response_chunk_received.emit(sentence, parsed_emotion)
			current_sentence = ""

func _contains_sentence_delimiter(value: String) -> bool:
	for delimiter: String in [".", "?", "!", ";", ":", "\n"]:
		if delimiter in value:
			return true
	return false

func _finish_streaming_response() -> void:
	if not chunk_buffer.strip_edges().is_empty():
		_parse_stream_json_line(chunk_buffer.strip_edges())
		chunk_buffer = ""
	var remaining := current_sentence.strip_edges()
	if not remaining.is_empty():
		response_chunk_received.emit(remaining, parsed_emotion)

	var text_content := full_response_accumulated.strip_edges()
	if text_content.begins_with("["):
		var close_bracket := text_content.find("]")
		if close_bracket != -1:
			text_content = text_content.substr(close_bracket + 1).strip_edges()
	if text_content.is_empty():
		request_failed.emit("Máy chủ AI không trả nội dung.")
		return
	response_received.emit(text_content, parsed_emotion)
	response_finished.emit()

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
