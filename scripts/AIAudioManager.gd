## ==============================================================================
## File: AIAudioManager.gd
## Mô tả: Quản lý phát âm thanh giọng nói (Text-To-Speech - TTS) cho nhân vật cô Mai.
## Chức năng chính:
##  1. Chuyển đổi văn bản câu trả lời thành giọng đọc tiếng Việt qua Google TTS API
##     (hoặc fallback về server cục bộ / Godot Native TTS nếu mất kết nối mạng).
##  2. Chia nhỏ văn bản thành các câu và tải trước (prefetch) để phát mượt mà liên tục.
##  3. Tính toán độ lớn âm thanh (amplitude) và nhận diện nguyên âm tiếng Việt (a, o, e, u, i)
##     theo thời gian thực để đồng bộ chuyển động khẩu hình miệng (Lip-Sync) cho model 3D cô Mai.
## ==============================================================================

class_name AIAudioManager
extends Node

## --- CÁC TÍN HIỆU (SIGNALS) ---
signal tts_started()                            ## Phát ra khi bắt đầu phát một câu thoại TTS
signal tts_finished()                           ## Phát ra khi đã phát hết toàn bộ hàng đợi câu thoại
signal audio_amplitude_updated(amplitude: float) ## Phát ra định kỳ cập nhật biên độ âm lượng hiện tại (0.0 -> 1.0)

## Node phát âm thanh chính
var audio_player: AudioStreamPlayer = null

## Thông tin mesh mặt 3D để điều khiển blendshape khẩu hình miệng
var face_mesh: MeshInstance3D
var mouth_a_idx: int = -1
var character_controller: Node = null # Tham chiếu tới controller nhân vật (dùng Node tránh circular reference)

## Hàng đợi xử lý câu thoại TTS
var sentence_queue: Array = []                 # Danh sách các câu đang chờ tải và phát
var current_playing_idx: int = -1              # Vị trí câu đang được phát trong hàng đợi
var current_sentence_text: String = ""         # Văn bản của câu đang phát
var current_sentence_vowels: Array[String] = [] # Danh sách các nguyên âm tương ứng của câu đang phát
var is_ai_finished: bool = true                # Đánh dấu xem AI đã gửi hết câu chưa (khi stream)

## Khởi tạo và kết nối node AudioStreamPlayer khi node sẵn sàng
func _ready() -> void:
	# Khởi tạo node AudioStreamPlayer nếu chưa có sẵn trong Scene
	if not has_node("AudioPlayer"):
		audio_player = AudioStreamPlayer.new()
		add_child(audio_player)
	else:
		audio_player = get_node("AudioPlayer")
		
	# Kết nối sự kiện khi phát xong 1 file âm thanh để tự động chuyển sang câu tiếp theo
	audio_player.finished.connect(_on_audio_finished)

## Nhận toàn bộ đoạn văn bản tiếng Việt, ngắt thành từng câu và bắt đầu phát TTS
func speak_vietnamese(text: String) -> void:
	# Dừng âm thanh và TTS đang phát hiện tại
	audio_player.stop()
	DisplayServer.tts_stop()
	current_playing_idx = -1
	sentence_queue.clear()
	is_ai_finished = true
	
	# Chia nhỏ đoạn văn bản thành danh sách từng câu
	var sentences = _split_into_sentences(text)
	if sentences.is_empty():
		return
		
	# Đưa từng câu vào hàng đợi với trạng thái ban đầu chưa tải
	for s in sentences:
		sentence_queue.append({
			"text": s,
			"stream": null,
			"downloading": false,
			"downloaded": false,
			"use_local_fallback": false
		})
		
	# Bắt đầu tải file âm thanh cho câu đầu tiên (index 0)
	_download_sentence(0)
	
	# Tải trước (prefetch) câu thứ hai nếu có để giảm độ trễ khi chuyển câu
	if sentence_queue.size() > 1:
		_download_sentence(1)

## Bắt đầu phiên phát âm thanh dạng Streaming (nhận dữ liệu từng phần từ AI)
func start_streaming_speech() -> void:
	audio_player.stop()
	current_playing_idx = -1
	sentence_queue.clear()
	is_ai_finished = false

## Thêm một đoạn văn bản mới vào hàng đợi streaming và kích hoạt tải âm thanh
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
			"downloaded": false,
			"use_local_fallback": false
		})
		
	# Nếu hàng đợi đang chờ ở vị trí mới hoặc chưa bắt đầu phát, kích hoạt tải ngay
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

## Báo hiệu phiên stream đã kết thúc, chuẩn bị hoàn tất phát toàn bộ hàng đợi
func finish_streaming_speech() -> void:
	is_ai_finished = true
	# Nếu đã phát xong hết các câu trong hàng đợi thì reset trạng thái ngay
	if current_playing_idx == -1 or current_playing_idx >= sentence_queue.size():
		current_playing_idx = -1
		sentence_queue.clear()
		_reset_mouth()
		tts_finished.emit()

## Kiểm tra và tải trước (prefetch) câu tiếp theo liền kề câu đang phát
func _check_prefetch() -> void:
	if current_playing_idx != -1:
		var next_idx = current_playing_idx + 1
		if next_idx < sentence_queue.size():
			_download_sentence(next_idx)

## Tách đoạn văn bản thành các câu dựa trên dấu câu (., ?, !, ;, xuống dòng)
## Đồng thời giới hạn độ dài mỗi câu <= 160 ký tự để phù hợp với Google Translate TTS API
func _split_into_sentences(text: String) -> Array[String]:
	var raw_sentences: Array[String] = []
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
				raw_sentences.append(trimmed)
			current_sentence = ""
		idx += 1
		
	var trimmed = current_sentence.strip_edges()
	if trimmed.length() > 0:
		raw_sentences.append(trimmed)
		
	# Cắt nhỏ thêm nếu câu vượt quá giới hạn 160 ký tự của Google TTS
	var final_sentences: Array[String] = []
	for s in raw_sentences:
		if s.length() <= 160:
			final_sentences.append(s)
		else:
			var parts = s.split(",")
			var current_chunk = ""
			for p in parts:
				var piece = p.strip_edges()
				if piece == "":
					continue
				if current_chunk.length() + piece.length() + 2 <= 160:
					if current_chunk != "":
						current_chunk += ", "
					current_chunk += piece
				else:
					if current_chunk != "":
						final_sentences.append(current_chunk)
					current_chunk = piece
			if current_chunk != "":
				final_sentences.append(current_chunk)
				
	return final_sentences

## Gửi HTTP GET request để tải file âm thanh MP3 từ TTS API cho câu ở vị trí `index`
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
	var url := ""
	if item.get("use_local_fallback", false):
		# Dùng server TTS nội bộ nếu đã bật cờ fallback
		url = "http://127.0.0.1:5001/tts?text=" + encoded_text
	else:
		# Dùng Google Translate TTS online
		url = "https://translate.google.com/translate_tts?ie=UTF-8&tl=vi&client=tw-ob&q=" + encoded_text
		
	var headers = ["User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"]
	var err = http.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		push_error("Failed to start request for sentence " + str(index))
		item["downloading"] = false
		http.queue_free()
		if not item.get("use_local_fallback", false):
			# Thử lại với server cục bộ nếu request Google thất bại
			item["use_local_fallback"] = true
			call_deferred("_download_sentence", index)
		else:
			item["downloaded"] = true
			call_deferred("_check_queue_playback")

## Xử lý khi nhận được phản hồi tải file âm thanh từ HTTP Request
func _on_sentence_download_completed(index: int, http: HTTPRequest, result: int, response_code: int, body: PackedByteArray) -> void:
	if is_instance_valid(http):
		http.queue_free()
		
	if index < 0 or index >= sentence_queue.size():
		return
		
	var item = sentence_queue[index]
	item["downloading"] = false
	
	# Nếu lỗi HTTP, chuyển sang thử server fallback hoặc dùng Native TTS
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		push_error("TTS download failed for sentence " + str(index) + ". Code: " + str(response_code))
		
		# Thử lại với server TTS cục bộ
		if not item.get("use_local_fallback", false):
			print("Retrying with local TTS server fallback for sentence ", index)
			item["use_local_fallback"] = true
			_download_sentence(index)
			return
			
		item["downloaded"] = true
		_check_queue_playback()
		return
		
	# Tạo AudioStreamMP3 từ dữ liệu byte tải về thành công
	var mp3_stream = AudioStreamMP3.new()
	mp3_stream.data = body
	item["stream"] = mp3_stream
	item["downloaded"] = true
	
	_check_queue_playback()

## Kiểm tra trạng thái hàng đợi để quyết định có phát tiếp câu đang sẵn sàng không
func _check_queue_playback() -> void:
	if current_playing_idx == -1:
		_play_next_sentence(0)
	elif current_playing_idx >= 0 and current_playing_idx < sentence_queue.size():
		var item = sentence_queue[current_playing_idx]
		if item["downloaded"] and not audio_player.playing:
			_play_next_sentence(current_playing_idx)

## Phát âm thanh cho câu ở vị trí `index`
func _play_next_sentence(index: int) -> void:
	# Nếu đã hết danh sách câu trong hàng đợi
	if index < 0 or index >= sentence_queue.size():
		_reset_mouth()
		if is_ai_finished:
			current_playing_idx = -1
			sentence_queue.clear()
			tts_finished.emit() # Thông báo đã nói xong toàn bộ
		else:
			current_playing_idx = index
		return
		
	var item = sentence_queue[index]
	if item["downloaded"]:
		current_playing_idx = index
		if item["stream"] != null:
			# Phát stream MP3 đã tải về
			audio_player.stream = item["stream"]
			tts_started.emit()
			audio_player.play()
			
			current_sentence_text = item["text"]
			current_sentence_vowels = _parse_sentence_vowels(current_sentence_text)
			
			# Tải trước câu kế tiếp
			if index + 1 < sentence_queue.size():
				_download_sentence(index + 1)
		else:
			# Fallback: sử dụng hệ thống TTS tích hợp của thiết bị (DisplayServer.tts)
			var voices = DisplayServer.tts_get_voices_for_language("vi")
			var voice_id = ""
			if not voices.is_empty():
				voice_id = voices[0]
				
			tts_started.emit()
			DisplayServer.tts_speak(item["text"], voice_id)
			
			current_sentence_text = item["text"]
			current_sentence_vowels = _parse_sentence_vowels(current_sentence_text)
			
			# Ước lượng thời gian phát của native TTS dựa vào số ký tự
			var duration = max(1.0, float(item["text"].length()) * 0.08)
			get_tree().create_timer(duration).timeout.connect(func():
				if current_playing_idx == index:
					_on_audio_finished()
			)
			
			# Tải trước câu kế tiếp
			if index + 1 < sentence_queue.size():
				_download_sentence(index + 1)
	else:
		current_playing_idx = index

## Callback được gọi khi AudioPlayer phát hết một câu thoại
func _on_audio_finished() -> void:
	if current_playing_idx != -1:
		_play_next_sentence(current_playing_idx + 1)

## Xử lý liên tục mỗi khung hình để phân tích âm thanh và cập nhật khẩu hình Lip-sync
func _process(_delta: float) -> void:
	if audio_player and audio_player.playing and audio_player.stream != null:
		var amplitude = _get_audio_amplitude()
		var vowel = _get_current_vowel()
		audio_amplitude_updated.emit(amplitude)
		
		# Cập nhật khẩu hình vào nhân vật controller hoặc trực tiếp vào Blendshape của mesh
		if character_controller and character_controller.has_method("set_speech_vowel"):
			character_controller.set_speech_vowel(vowel, amplitude)
		else:
			_update_mouth_blendshape(amplitude)
	else:
		_reset_mouth()

## Gán Mesh khuôn mặt 3D và tìm index của BlendShape mở miệng
func set_target_face_mesh(mesh: MeshInstance3D) -> void:
	face_mesh = mesh
	mouth_a_idx = -1
	if face_mesh and face_mesh.mesh:
		for i in face_mesh.mesh.get_blend_shape_count():
			var bs_name = face_mesh.mesh.get_blend_shape_name(i).to_lower()
			if bs_name in ["mouth_a", "vowel_a", "vrm_a", "mouth_open", "jaw_open"]:
				mouth_a_idx = i
				break

## Cập nhật trọng số độ mở miệng trên blendshape của 3D Face Mesh
func _update_mouth_blendshape(amount: float) -> void:
	if face_mesh and mouth_a_idx != -1:
		face_mesh.set_blend_shape_value(mouth_a_idx, amount)

## Đặt lại khẩu hình miệng về trạng thái đóng khi không nói
func _reset_mouth() -> void:
	if character_controller and character_controller.has_method("set_speech_vowel"):
		character_controller.set_speech_vowel("a", 0.0)
	elif face_mesh and mouth_a_idx != -1:
		face_mesh.set_blend_shape_value(mouth_a_idx, 0.0)

## Đo biên độ âm lượng (Peak Amplitude) từ Audio Bus để điều khiển độ mở của miệng
func _get_audio_amplitude() -> float:
	if audio_player == null or not audio_player.playing or audio_player.stream == null:
		return 0.0
	var bus_idx = AudioServer.get_bus_index(audio_player.bus)
	var db = AudioServer.get_bus_peak_volume_left_db(bus_idx, 0)
	var linear_volume = db_to_linear(db)
	return clamp(linear_volume * 1.8, 0.0, 1.0)

## Phân tích chuỗi văn bản thành mảng các nguyên âm chính của từng từ
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

## Lấy nguyên âm tương ứng tại vị trí thời gian bài phát hiện tại (dựa vào tiến độ audio)
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

## Xác định nguyên âm chính ('a', 'o', 'e', 'u', 'i') của một từ tiếng Việt dựa trên dấu câu và ký tự
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
