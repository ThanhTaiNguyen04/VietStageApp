## ==============================================================================
## File: STTManager.gd
## Mô tả: Quản lý việc thu âm giọng nói từ Micro và gửi đến dịch vụ Speech-To-Text (STT) để nhận diện văn bản.
## Chức năng chính:
##  1. Thiết lập AudioBus riêng ("RecordBus") với hiệu ứng `AudioEffectRecord` để ghi âm luồng micro.
##  2. Bắt đầu/dừng thu âm micro và lưu dữ liệu âm thanh thành file .wav trên thiết bị.
##  3. Gửi file âm thanh đã thu qua HTTP POST tới máy chủ STT (Whisper/Speech-To-Text API).
##  4. Xử lý phản hồi JSON chứa đoạn văn bản (text) đã được nhận dạng và bắn tín hiệu (signals).
## ==============================================================================

class_name STTManager
extends HTTPRequest

## --- CÁC TÍN HIỆU (SIGNALS) ---
signal transcription_completed(file_path: String, text: String)  ## Bắn ra khi nhận diện giọng nói thành công thành chuỗi văn bản
signal transcription_failed(file_path: String, reason: String)   ## Bắn ra khi có lỗi trong quá trình thu âm hoặc nhận diện
signal recording_started()                                       ## Bắn ra khi bắt đầu mở micro ghi âm
signal recording_stopped(file_path: String)                      ## Bắn ra khi kết thúc ghi âm và file .wav đã được lưu

var active_file_path: String = ""                                ## Đường dẫn file âm thanh đang được xử lý

var mic_player: AudioStreamPlayer = null                         ## Node phát âm thanh micro vào bus ghi âm
var record_bus_idx: int = -1                                     ## Index của AudioBus dành riêng cho việc ghi âm
var record_effect: AudioEffectRecord = null                      ## Hiệu ứng ghi âm của Godot Audio Engine
var is_recording: bool = false                                   ## Cờ kiểm tra trạng thái micro có đang ghi âm hay không
var recording_start_time: int = 0                                ## Mốc thời gian (ms) bắt đầu ghi âm để tránh lỗi ghi quá ngắn

## Địa chỉ URL của máy chủ dịch vụ nhận diện giọng nói STT
@export var stt_url: String = "http://127.0.0.1:5001/stt"

## Khởi tạo kết nối hoàn thành request và thiết lập AudioBus ghi âm
func _ready() -> void:
	request_completed.connect(_on_request_completed)
	
	# Chờ 1 frame để AudioServer hoàn tất khởi tạo ban đầu
	call_deferred("_setup_recording_bus")

## Thiết lập Audio Bus và AudioEffectRecord cho Micro
func _setup_recording_bus() -> void:
	# Kiểm tra xem RecordBus đã tồn tại chưa
	record_bus_idx = AudioServer.get_bus_index("RecordBus")
	if record_bus_idx == -1:
		AudioServer.add_bus()
		record_bus_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(record_bus_idx, "RecordBus")
		AudioServer.set_bus_mute(record_bus_idx, true) # Tắt tiếng bus ghi âm để không bị vọng lại loa
		
		record_effect = AudioEffectRecord.new()
		AudioServer.add_bus_effect(record_bus_idx, record_effect)
	else:
		record_effect = AudioServer.get_bus_effect(record_bus_idx, 0) as AudioEffectRecord
		
	# Khởi tạo node thu âm Micro
	mic_player = AudioStreamPlayer.new()
	mic_player.stream = AudioStreamMicrophone.new()
	mic_player.bus = "RecordBus"
	add_child(mic_player)
	mic_player.play()

## Bật/tắt trạng thái thu âm của Micro
func toggle_recording() -> void:
	if is_recording:
		stop_recording()
	else:
		start_recording()

## Bắt đầu kích hoạt thu âm giọng nói từ Micro
func start_recording() -> void:
	if is_recording:
		return
	if record_effect:
		# Xóa bộ đệm ghi âm cũ bằng cách tắt/bật lại effect
		record_effect.set_recording_active(false)
		record_effect.set_recording_active(true)
		is_recording = true
		recording_start_time = Time.get_ticks_msec()
		recording_started.emit()
		print("Microphone recording started...")

## Dừng thu âm, lưu dữ liệu âm thanh ra file WAV và tùy chọn gửi tới STT Server
func stop_recording(custom_path: String = "d:/modelAO/user_voice.wav", send_to_stt: bool = true) -> void:
	if not is_recording:
		return
	if record_effect:
		record_effect.set_recording_active(false)
		is_recording = false
		
		# Bỏ qua nếu thời gian ghi âm quá ngắn (< 150ms) để tránh lỗi crash bộ đệm
		if Time.get_ticks_msec() - recording_start_time < 150:
			print("Recording was too short (", Time.get_ticks_msec() - recording_start_time, "ms), skipping buffer retrieval to prevent crash.")
			return
			
		var recording = record_effect.get_recording()
		if recording and recording.data.size() > 0:
			# Đảm bảo thư mục lưu file tồn tại
			var dir = DirAccess.open("d:/")
			if dir:
				dir.make_dir_recursive("modelAO")
				
			# Kiểm tra xem file có đang bị khóa bởi tiến trình khác (trên Windows) không
			if FileAccess.file_exists(custom_path):
				var f = FileAccess.open(custom_path, FileAccess.WRITE)
				if not f:
					print("Warning: File ", custom_path, " is locked by another process (e.g. STT reader). Skipping save to prevent crash.")
					transcription_failed.emit(custom_path, "File is locked by another process.")
					return
				f.close()
				
			# Lưu dữ liệu buffer thành file âm thanh .WAV
			var err = recording.save_to_wav(custom_path)
			if err == OK:
				recording_stopped.emit(custom_path)
				print("Recording saved to: ", custom_path)
				# Gửi file tới server nhận diện nếu bật cờ send_to_stt
				if send_to_stt:
					_send_to_stt_server(custom_path)
			else:
				transcription_failed.emit(custom_path, "Failed to save recording file.")
		else:
			transcription_failed.emit(custom_path, "Captured recording buffer was empty.")

## Gửi đường dẫn file WAV lên máy chủ STT Server qua HTTP POST
func _send_to_stt_server(file_path: String) -> void:
	cancel_request() # Hủy request cũ nếu còn đang chạy dở
	active_file_path = file_path
	var headers = ["Content-Type: application/json"]
	var payload = {
		"file_path": file_path
	}
	var err = request(stt_url, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if err != OK:
		transcription_failed.emit(file_path, "Failed to send STT network request.")

## Xử lý khi nhận được phản hồi HTTP từ máy chủ STT
func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var file_path = active_file_path
	active_file_path = ""
	
	if result != RESULT_SUCCESS:
		transcription_failed.emit(file_path, "STT network request failed.")
		return
	if response_code != 200:
		transcription_failed.emit(file_path, "STT server returned code: " + str(response_code))
		return
		
	var raw_response = body.get_string_from_utf8()
	var json = JSON.new()
	var err = json.parse(raw_response)
	if err != OK:
		transcription_failed.emit(file_path, "Failed to parse STT server response. Raw: '" + raw_response + "' Error: " + json.get_error_message())
		return
		
	var data = json.get_data()
	# Bóc tách chuỗi văn bản đã nhận dạng thành công
	if data.has("text"):
		transcription_completed.emit(file_path, data["text"])
	elif data.has("error"):
		transcription_failed.emit(file_path, data["error"])
	else:
		transcription_failed.emit(file_path, "Unknown STT response format.")
