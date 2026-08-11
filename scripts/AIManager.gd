class_name AIManager
extends HTTPRequest

signal response_received(text: String, emotion: String)
signal response_chunk_received(text: String, emotion: String)
signal response_finished()
signal request_failed(reason: String)

@export var api_url: String = "https://anew-handgrip-elope.ngrok-free.dev/api/chat"
@export var model_name: String = "mai-musician-fast"

var client: HTTPClient = null
var is_connecting: bool = false
var is_requesting: bool = false
var pending_prompt: String = ""
var instrument_context: String = "general"

var chunk_buffer: String = ""
var current_sentence: String = ""
var parsed_emotion: String = "neutral"
var emotion_checked: bool = false
var full_response_accumulated: String = ""

func _ready() -> void:
	# Disable automatic HTTPRequest completion processing since we use HTTPClient
	set_process(false)

func send_prompt(user_prompt: String) -> void:
	if _is_off_topic(user_prompt):
		call_deferred("_return_static_refusal")
		return
		
	if api_url.is_empty():
		request_failed.emit("API URL is not set.")
		return
		
	_close_client()
	
	pending_prompt = user_prompt
	chunk_buffer = ""
	current_sentence = ""
	parsed_emotion = "neutral"
	emotion_checked = false
	full_response_accumulated = ""
	
	var use_tls = api_url.begins_with("https://")
	var host = "127.0.0.1"
	var port = 11434
	
	var url_temp = api_url
	if url_temp.begins_with("http://"):
		url_temp = url_temp.substr(7)
	elif url_temp.begins_with("https://"):
		url_temp = url_temp.substr(8)
		
	var slash_idx = url_temp.find("/")
	if slash_idx != -1:
		url_temp = url_temp.substr(0, slash_idx)
		
	var colon_idx = url_temp.find(":")
	if colon_idx != -1:
		host = url_temp.substr(0, colon_idx)
		port = int(url_temp.substr(colon_idx + 1))
	else:
		host = url_temp
		port = 443 if use_tls else 80
	
	client = HTTPClient.new()
	var err = OK
	if use_tls:
		err = client.connect_to_host(host, port, TLSOptions.client())
	else:
		err = client.connect_to_host(host, port)
	if err != OK:
		request_failed.emit("Failed to initiate connection to " + host + ":" + str(port))
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
	var status = client.get_status()
	
	if is_connecting:
		if status == HTTPClient.STATUS_CONNECTED:
			is_connecting = false
			_send_http_request()
		elif status in [HTTPClient.STATUS_CONNECTION_ERROR, HTTPClient.STATUS_CANT_CONNECT, HTTPClient.STATUS_CANT_RESOLVE]:
			is_connecting = false
			request_failed.emit("Failed to connect to AI server host.")
			_close_client()
			
	elif is_requesting:
		if status == HTTPClient.STATUS_BODY:
			if client.has_response():
				var chunk = client.read_response_body_chunk()
				if chunk.size() > 0:
					_process_chunk(chunk)
		elif status == HTTPClient.STATUS_CONNECTED:
			is_requesting = false
			_finalize_response()
			_close_client()
		elif status in [HTTPClient.STATUS_CONNECTION_ERROR, HTTPClient.STATUS_DISCONNECTED]:
			is_requesting = false
			request_failed.emit("Connection lost during streaming.")
			_close_client()

func _send_http_request() -> void:
	var headers = ["Content-Type: application/json", "ngrok-skip-browser-warning: 1"]
	
	var payload: Dictionary = {
		"model": model_name,
		"prompt": pending_prompt,
		"instrument_context": instrument_context
	}
	
	var path = "/api/chat"
	var url_temp = api_url
	if url_temp.begins_with("http://"):
		url_temp = url_temp.substr(7)
	elif url_temp.begins_with("https://"):
		url_temp = url_temp.substr(8)
	var slash_idx = url_temp.find("/")
	if slash_idx != -1:
		path = url_temp.substr(slash_idx)
		
	var body = JSON.stringify(payload)
	var err = client.request(HTTPClient.METHOD_POST, path, headers, body)
	if err != OK:
		request_failed.emit("Failed to send request payload.")
		_close_client()
	else:
		is_requesting = true

func _process_chunk(chunk: PackedByteArray) -> void:
	chunk_buffer += chunk.get_string_from_utf8()
	
	while "\n" in chunk_buffer:
		var idx = chunk_buffer.find("\n")
		var line = chunk_buffer.substr(0, idx).strip_edges()
		chunk_buffer = chunk_buffer.substr(idx + 1)
		
		if not line.is_empty():
			_parse_json_line(line)

func _parse_json_line(line: String) -> void:
	var json = JSON.new()
	var err = json.parse(line)
	if err != OK:
		return
		
	var data = json.get_data()
	var token = ""
	var is_done = false
	
	if "/v1/chat/completions" in api_url or "/v1" in api_url:
		if data.has("choices") and data["choices"].size() > 0:
			var choice = data["choices"][0]
			if choice.has("delta") and choice["delta"].has("content"):
				token = choice["delta"]["content"]
			if choice.has("finish_reason") and choice["finish_reason"] != null:
				is_done = true
	else:
		if data.has("response"):
			token = data["response"]
		if data.has("done"):
			is_done = data["done"]
			
	if not token.is_empty():
		_handle_token(token)
		
	if is_done:
		is_requesting = false
		_finalize_response()
		_close_client()

func _handle_token(token: String) -> void:
	current_sentence += token
	full_response_accumulated += token
	
	if not emotion_checked:
		var trimmed = current_sentence.strip_edges()
		if trimmed.begins_with("[") and "]" in trimmed:
			var close_idx = trimmed.find("]")
			parsed_emotion = trimmed.substr(1, close_idx - 1).to_lower().strip_edges()
			current_sentence = trimmed.substr(close_idx + 1)
			emotion_checked = true
			
			var emotion_mapping = {
				"joy": "joy",
				"happy": "joy",
				"sad": "sad",
				"sorrow": "sad",
				"angry": "angry",
				"anger": "angry",
				"surprised": "surprised",
				"surprise": "surprised",
				"neutral": "neutral"
			}
			if parsed_emotion in emotion_mapping:
				parsed_emotion = emotion_mapping[parsed_emotion]
			else:
				parsed_emotion = "neutral"
		elif not trimmed.begins_with("[") and trimmed.length() > 6:
			emotion_checked = true
			
	if emotion_checked:
		var delimiters = [".", "?", "!", ";", ",", ":", "\n"]
		var found_delimiter = false
		for d in delimiters:
			if d in token:
				found_delimiter = true
				break
				
		if found_delimiter:
			var trimmed = current_sentence.strip_edges()
			if trimmed.length() > 2:
				response_chunk_received.emit(trimmed, parsed_emotion)
				current_sentence = ""

func _finalize_response() -> void:
	var trimmed = current_sentence.strip_edges()
	if not trimmed.is_empty():
		response_chunk_received.emit(trimmed, parsed_emotion)
		
	var text_content = full_response_accumulated.strip_edges()
	if text_content.begins_with("["):
		var close_bracket = text_content.find("]")
		if close_bracket != -1:
			text_content = text_content.substr(close_bracket + 1).strip_edges()
			
	response_received.emit(text_content, parsed_emotion)
	response_finished.emit()

func _close_client() -> void:
	is_connecting = false
	is_requesting = false
	if client != null:
		client.close()
		client = null
	set_process(false)

func _is_off_topic(user_prompt: String) -> bool:
	var prompt_lower = user_prompt.to_lower()
	
	# 1. Programming, technology and coding keywords
	var tech_keywords = [
		"code", "lập trình", "python", "javascript", "c++", "html", "css", 
		"gdscript", "thuật toán", "sắp xếp", "quicksort", "bubble sort", 
		"database", "sql", "git", "github", "compiler", "viết hàm", 
		"viết một hàm", "lập trình", "phần mềm", "app ", "website"
	]
	for kw in tech_keywords:
		if kw in prompt_lower:
			return true
			
	# 2. General math/science questions
	var math_keywords = [
		"phương trình", "toán học", "hóa học", "vật lý", "tích phân", 
		"đạo hàm", "bằng mấy", "giải toán"
	]
	if "bằng mấy" in prompt_lower:
		return true
	for kw in math_keywords:
		if kw in prompt_lower:
			return true
			
	# Math operation pattern (e.g. 1+1, 2 * 3, etc.)
	var regex = RegEx.new()
	regex.compile("[0-9]+\\s*[\\+\\-\\*\\/]\\s*[0-9]+")
	if regex.search(prompt_lower):
		return true
		
	return false

func _return_static_refusal() -> void:
	var response = "Xin lỗi học viên nhé, Mai chỉ biết chia sẻ về Đàn Tranh, Sáo Trúc và nhạc cụ cổ truyền thôi ạ. Chúng ta nói chuyện âm nhạc truyền thống nhé!"
	response_chunk_received.emit(response, "neutral")
	response_received.emit(response, "neutral")
	response_finished.emit()
