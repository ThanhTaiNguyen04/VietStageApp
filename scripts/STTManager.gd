class_name STTManager
extends HTTPRequest

signal transcription_completed(file_path: String, text: String)
signal transcription_failed(file_path: String, reason: String)
signal recording_started()
signal recording_stopped(file_path: String)

var active_file_path: String = ""

var mic_player: AudioStreamPlayer = null
var record_bus_idx: int = -1
var record_effect: AudioEffectRecord = null
var is_recording: bool = false
var recording_start_time: int = 0

@export var stt_url: String = "http://127.0.0.1:5001/stt"

func _ready() -> void:
	request_completed.connect(_on_request_completed)
	
	# Wait a frame to ensure AudioServer is fully initialized
	call_deferred("_setup_recording_bus")

func _setup_recording_bus() -> void:
	# Check if RecordBus already exists
	record_bus_idx = AudioServer.get_bus_index("RecordBus")
	if record_bus_idx == -1:
		AudioServer.add_bus()
		record_bus_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(record_bus_idx, "RecordBus")
		AudioServer.set_bus_mute(record_bus_idx, true)
		
		record_effect = AudioEffectRecord.new()
		AudioServer.add_bus_effect(record_bus_idx, record_effect)
	else:
		record_effect = AudioServer.get_bus_effect(record_bus_idx, 0) as AudioEffectRecord
		
	# Create mic capture player
	mic_player = AudioStreamPlayer.new()
	mic_player.stream = AudioStreamMicrophone.new()
	mic_player.bus = "RecordBus"
	add_child(mic_player)
	mic_player.play()

func toggle_recording() -> void:
	if is_recording:
		stop_recording()
	else:
		start_recording()

func start_recording() -> void:
	if is_recording:
		return
	if record_effect:
		# Clear previous recording buffer by disabling and enabling
		record_effect.set_recording_active(false)
		record_effect.set_recording_active(true)
		is_recording = true
		recording_start_time = Time.get_ticks_msec()
		recording_started.emit()
		print("Microphone recording started...")

func stop_recording(custom_path: String = "d:/modelAO/user_voice.wav", send_to_stt: bool = true) -> void:
	if not is_recording:
		return
	if record_effect:
		record_effect.set_recording_active(false)
		is_recording = false
		
		# Prevent crashes by checking if the recording lasted less than 150 milliseconds
		if Time.get_ticks_msec() - recording_start_time < 150:
			print("Recording was too short (", Time.get_ticks_msec() - recording_start_time, "ms), skipping buffer retrieval to prevent crash.")
			return
			
		var recording = record_effect.get_recording()
		if recording and recording.data.size() > 0:
			# Ensure folder exists
			var dir = DirAccess.open("d:/")
			if dir:
				dir.make_dir_recursive("modelAO")
				
			# Check if the target file is locked by another process (Windows file lock)
			if FileAccess.file_exists(custom_path):
				var f = FileAccess.open(custom_path, FileAccess.WRITE)
				if not f:
					print("Warning: File ", custom_path, " is locked by another process (e.g. STT reader). Skipping save to prevent crash.")
					transcription_failed.emit(custom_path, "File is locked by another process.")
					return
				f.close() # Close immediately so save_to_wav can write
				
			var err = recording.save_to_wav(custom_path)
			if err == OK:
				recording_stopped.emit(custom_path)
				print("Recording saved to: ", custom_path)
				# Trigger transcription
				if send_to_stt:
					_send_to_stt_server(custom_path)
			else:
				transcription_failed.emit(custom_path, "Failed to save recording file.")
		else:
			transcription_failed.emit(custom_path, "Captured recording buffer was empty.")

func _send_to_stt_server(file_path: String) -> void:
	cancel_request() # Abort any pending/running request to prevent overlap
	active_file_path = file_path
	var headers = ["Content-Type: application/json"]
	var payload = {
		"file_path": file_path
	}
	var err = request(stt_url, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if err != OK:
		transcription_failed.emit(file_path, "Failed to send STT network request.")

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
	if data.has("text"):
		transcription_completed.emit(file_path, data["text"])
	elif data.has("error"):
		transcription_failed.emit(file_path, data["error"])
	else:
		transcription_failed.emit(file_path, "Unknown STT response format.")
