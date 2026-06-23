class_name AIAudioManager
extends Node

signal tts_started()
signal tts_finished()
signal audio_amplitude_updated(amplitude: float)

var audio_player: AudioStreamPlayer = null

var face_mesh: MeshInstance3D
var mouth_a_idx: int = -1
var character_controller: Node = null # Use Node to avoid circular reference issues

var sentence_queue: Array = []
var current_playing_idx: int = -1
var current_sentence_text: String = ""
var current_sentence_vowels: Array[String] = []
var is_ai_finished: bool = true

func _ready() -> void:
	# Set up AudioStreamPlayer child
	if not has_node("AudioPlayer"):
		audio_player = AudioStreamPlayer.new()
		add_child(audio_player)
	else:
		audio_player = get_node("AudioPlayer")
		
	audio_player.finished.connect(_on_audio_finished)

func speak_vietnamese(text: String) -> void:
	# Stop current audio
	audio_player.stop()
	current_playing_idx = -1
	sentence_queue.clear()
	is_ai_finished = true
	
	# Split text into sentences
	var sentences = _split_into_sentences(text)
	if sentences.is_empty():
		return
		
	# Initialize queue items
	for s in sentences:
		sentence_queue.append({
			"text": s,
			"stream": null,
			"downloading": false,
			"downloaded": false
		})
		
	# Start downloading first sentence
	_download_sentence(0)
	
	# Prefetch second sentence if it exists
	if sentence_queue.size() > 1:
		_download_sentence(1)

func start_streaming_speech() -> void:
	audio_player.stop()
	current_playing_idx = -1
	sentence_queue.clear()
	is_ai_finished = false

func append_vietnamese_speech(text: String) -> void:
	var sentences = _split_into_sentences(text)
	if sentences.is_empty():
		return
		
	var start_idx = sentence_queue.size()
	
	for s in sentences:
		sentence_queue.append({
			"text": s,
			"stream": null,
			"downloading": false,
			"downloaded": false
		})
		
	if current_playing_idx == start_idx:
		_download_sentence(start_idx)
		if start_idx + 1 < sentence_queue.size():
			_download_sentence(start_idx + 1)
	elif current_playing_idx == -1:
		current_playing_idx = start_idx
		_download_sentence(start_idx)
		if start_idx + 1 < sentence_queue.size():
			_download_sentence(start_idx + 1)
	else:
		_check_prefetch()

func finish_streaming_speech() -> void:
	is_ai_finished = true
	if current_playing_idx == -1 or current_playing_idx >= sentence_queue.size():
		current_playing_idx = -1
		sentence_queue.clear()
		_reset_mouth()
		tts_finished.emit()

func _check_prefetch() -> void:
	if current_playing_idx != -1:
		var next_idx = current_playing_idx + 1
		if next_idx < sentence_queue.size():
			_download_sentence(next_idx)

func _split_into_sentences(text: String) -> Array[String]:
	var sentences: Array[String] = []
	var delimiters = [".", "?", "!", ";", "\n"]
	var current_sentence = ""
	var length = text.length()
	var idx = 0
	while idx < length:
		var c = text[idx]
		current_sentence += c
		
		var is_boundary = false
		if c == "\n":
			is_boundary = true
		elif c in delimiters:
			if idx + 1 >= length:
				is_boundary = true
			else:
				var next_char = text[idx + 1]
				if next_char == " " or next_char == "\t" or next_char == "\n":
					is_boundary = true
					
		if is_boundary:
			var trimmed = current_sentence.strip_edges()
			if trimmed.length() > 0:
				sentences.append(trimmed)
			current_sentence = ""
		idx += 1
		
	var trimmed = current_sentence.strip_edges()
	if trimmed.length() > 0:
		sentences.append(trimmed)
		
	return sentences

func _download_sentence(index: int) -> void:
	if index < 0 or index >= sentence_queue.size():
		return
		
	var item = sentence_queue[index]
	if item["downloading"] or item["downloaded"]:
		return
		
	item["downloading"] = true
	
	var http = HTTPRequest.new()
	add_child(http)
	
	http.request_completed.connect(func(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
		_on_sentence_download_completed(index, http, result, response_code, body)
	)
	
	var encoded_text = item["text"].uri_encode()
	var url = "http://127.0.0.1:5001/tts?text=" + encoded_text
	var headers = ["User-Agent: Mozilla/5.0"]
	var err = http.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		push_error("Failed to start request for sentence " + str(index))
		item["downloading"] = false
		http.queue_free()

func _on_sentence_download_completed(index: int, http: HTTPRequest, result: int, response_code: int, body: PackedByteArray) -> void:
	if is_instance_valid(http):
		http.queue_free()
		
	if index < 0 or index >= sentence_queue.size():
		return
		
	var item = sentence_queue[index]
	item["downloading"] = false
	
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		push_error("TTS download failed for sentence " + str(index) + ". Code: " + str(response_code))
		item["downloaded"] = true
		_check_queue_playback()
		return
		
	var mp3_stream = AudioStreamMP3.new()
	mp3_stream.data = body
	item["stream"] = mp3_stream
	item["downloaded"] = true
	
	_check_queue_playback()

func _check_queue_playback() -> void:
	if current_playing_idx == -1:
		_play_next_sentence(0)
	elif current_playing_idx >= 0 and current_playing_idx < sentence_queue.size():
		var item = sentence_queue[current_playing_idx]
		if item["downloaded"] and not audio_player.playing:
			_play_next_sentence(current_playing_idx)

func _play_next_sentence(index: int) -> void:
	if index < 0 or index >= sentence_queue.size():
		_reset_mouth()
		if is_ai_finished:
			current_playing_idx = -1
			sentence_queue.clear()
			tts_finished.emit()
		else:
			current_playing_idx = index
		return
		
	var item = sentence_queue[index]
	if item["downloaded"]:
		if item["stream"] != null:
			current_playing_idx = index
			audio_player.stream = item["stream"]
			audio_player.play()
			tts_started.emit()
			
			current_sentence_text = item["text"]
			current_sentence_vowels = _parse_sentence_vowels(current_sentence_text)
			
			# Prefetch next sentence
			if index + 1 < sentence_queue.size():
				_download_sentence(index + 1)
		else:
			# Skip failed downloads
			_play_next_sentence(index + 1)
	else:
		current_playing_idx = index

func _on_audio_finished() -> void:
	if current_playing_idx != -1:
		_play_next_sentence(current_playing_idx + 1)

func _process(_delta: float) -> void:
	if audio_player and audio_player.playing and audio_player.stream != null:
		var amplitude = _get_audio_amplitude()
		var vowel = _get_current_vowel()
		audio_amplitude_updated.emit(amplitude)
		
		if character_controller and character_controller.has_method("set_speech_vowel"):
			character_controller.set_speech_vowel(vowel, amplitude)
		else:
			_update_mouth_blendshape(amplitude)
	else:
		_reset_mouth()

func set_target_face_mesh(mesh: MeshInstance3D) -> void:
	face_mesh = mesh
	mouth_a_idx = -1
	if face_mesh and face_mesh.mesh:
		for i in face_mesh.mesh.get_blend_shape_count():
			var bs_name = face_mesh.mesh.get_blend_shape_name(i).to_lower()
			if bs_name in ["mouth_a", "vowel_a", "vrm_a", "mouth_open", "jaw_open"]:
				mouth_a_idx = i
				break

func _update_mouth_blendshape(amount: float) -> void:
	if face_mesh and mouth_a_idx != -1:
		face_mesh.set_blend_shape_value(mouth_a_idx, amount)

func _reset_mouth() -> void:
	if character_controller and character_controller.has_method("set_speech_vowel"):
		character_controller.set_speech_vowel("a", 0.0)
	elif face_mesh and mouth_a_idx != -1:
		face_mesh.set_blend_shape_value(mouth_a_idx, 0.0)

func _get_audio_amplitude() -> float:
	if audio_player == null or not audio_player.playing or audio_player.stream == null:
		return 0.0
	var bus_idx = AudioServer.get_bus_index(audio_player.bus)
	var db = AudioServer.get_bus_peak_volume_left_db(bus_idx, 0)
	var linear_volume = db_to_linear(db)
	return clamp(linear_volume * 1.8, 0.0, 1.0)

func _parse_sentence_vowels(text: String) -> Array[String]:
	var vowels: Array[String] = []
	var words = text.split(" ", false)
	var punctuation = ".,?!;:\"'()[]{}<>-_+=@#$%^&*~`|\\/"
	for word in words:
		var clean_word = ""
		for i in range(word.length()):
			var c = word[i]
			if not c in punctuation:
				clean_word += c
		if not clean_word.is_empty():
			vowels.append(get_vietnamese_vowel(clean_word))
	if vowels.is_empty():
		vowels.append("a")
	return vowels

func _get_current_vowel() -> String:
	if current_sentence_vowels.is_empty():
		return "a"
	var playback_time = audio_player.get_playback_position()
	var total_duration = audio_player.stream.get_length()
	if total_duration <= 0.0:
		return "a"
	var progress = playback_time / total_duration
	var word_index = int(progress * current_sentence_vowels.size())
	word_index = clamp(word_index, 0, current_sentence_vowels.size() - 1)
	return current_sentence_vowels[word_index]

func get_vietnamese_vowel(word: String) -> String:
	word = word.to_lower()
	for c in ["a", "à", "á", "ả", "ã", "ạ", "ă", "ằ", "ắ", "ẳ", "ẵ", "ặ", "â", "ầ", "ấ", "ẩ", "ẫ", "ậ"]:
		if c in word:
			return "a"
	for c in ["o", "ò", "ó", "ỏ", "õ", "ọ", "ô", "ồ", "ố", "ổ", "ỗ", "ộ", "ơ", "ờ", "ớ", "ở", "ỡ", "ợ"]:
		if c in word:
			return "o"
	for c in ["e", "è", "é", "ẻ", "ẽ", "ẹ", "ê", "ề", "ế", "ể", "ễ", "ệ"]:
		if c in word:
			return "e"
	for c in ["u", "ù", "ú", "ủ", "ũ", "ụ", "ư", "ừ", "ứ", "ử", "ữ", "ự"]:
		if c in word:
			return "u"
	for c in ["i", "ì", "í", "ỉ", "ĩ", "ị", "y", "ỳ", "ý", "ỷ", "ỹ", "ỵ"]:
		if c in word:
			return "i"
	return "a"
