extends SceneTree

const FIXTURE_DIRECTORY := "res://test_fixtures/dan_tranh_real_audio"
const MANIFEST_PATH := FIXTURE_DIRECTORY + "/manifest.json"
const WINDOW_SIZE := 4096
const WINDOW_HOP := 512
const MAX_AUDIO_SECONDS := 3.0


func _init() -> void:
	var failures: Array[String] = []
	var manifest := _load_manifest(failures)
	if manifest.is_empty():
		_finish(failures)
		return

	var required_categories: Array[String] = []
	var raw_required: Variant = manifest.get("required_categories", [])
	if raw_required is Array:
		for category_value in raw_required:
			var category := str(category_value).strip_edges()
			if not category.is_empty():
				required_categories.append(category)
	else:
		failures.append("manifest.json: required_categories phải là một mảng")

	var cases_value: Variant = manifest.get("cases", [])
	if not cases_value is Array:
		failures.append("manifest.json: cases phải là một mảng")
		_finish(failures)
		return
	var cases: Array = cases_value
	var present_categories: Dictionary = {}
	var validated_cases: Array[Dictionary] = []
	var seen_ids: Dictionary = {}

	for case_index in range(cases.size()):
		var case_value: Variant = cases[case_index]
		if not case_value is Dictionary:
			failures.append("manifest.json: cases[%d] phải là object" % case_index)
			continue
		var test_case: Dictionary = case_value
		var case_id := str(test_case.get("id", "")).strip_edges()
		var category := str(test_case.get("category", "")).strip_edges()
		var relative_path := str(test_case.get("path", "")).strip_edges()
		if case_id.is_empty() or category.is_empty() or relative_path.is_empty():
			failures.append("manifest.json: cases[%d] thiếu id/category/path" % case_index)
			continue
		if seen_ids.has(case_id):
			failures.append("manifest.json: id bị trùng: %s" % case_id)
			continue
		seen_ids[case_id] = true
		present_categories[category] = true
		if not test_case.has("expected") or not test_case["expected"] is bool:
			failures.append("manifest.json: %s phải có expected kiểu bool" % case_id)
			continue
		if relative_path.contains("..") or relative_path.begins_with("/") \
				or relative_path.contains(":"):
			failures.append("manifest.json: đường dẫn không an toàn ở %s" % case_id)
			continue
		var fixture_path := FIXTURE_DIRECTORY + "/" + relative_path
		if not FileAccess.file_exists(fixture_path):
			failures.append("Thiếu mẫu thu [%s]: %s" % [case_id, fixture_path])
			continue
		validated_cases.append(test_case)

	for required_category in required_categories:
		if not present_categories.has(required_category):
			failures.append("Thiếu nhóm kiểm thử bắt buộc: %s" % required_category)

	if not bool(manifest.get("ready", false)):
		failures.append(
			"Bộ mẫu thu thật chưa sẵn sàng: thêm đủ WAV theo README.md rồi đổi ready thành true"
		)

	if not failures.is_empty():
		_finish(failures)
		return

	var analyzer = load("res://scripts/AudioCaptureAnalyzer.gd").new()
	analyzer.volume_threshold_db = -58.0
	for test_case in validated_cases:
		_run_case(analyzer, test_case, failures)
	analyzer.free()
	_finish(failures)


func _load_manifest(failures: Array[String]) -> Dictionary:
	if not FileAccess.file_exists(MANIFEST_PATH):
		failures.append("Không tìm thấy manifest mẫu thu thật: %s" % MANIFEST_PATH)
		return {}
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		failures.append("Không mở được manifest: %s" % MANIFEST_PATH)
		return {}
	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	if parse_error != OK:
		failures.append(
			"manifest.json không hợp lệ ở dòng %d: %s" % [json.get_error_line(), json.get_error_message()]
		)
		return {}
	var parsed: Variant = json.data
	if not parsed is Dictionary:
		failures.append("manifest.json phải có object ở cấp cao nhất")
		return {}
	return parsed


func _run_case(analyzer: Node, test_case: Dictionary, failures: Array[String]) -> void:
	var case_id := str(test_case["id"])
	var category := str(test_case["category"])
	var fixture_path := FIXTURE_DIRECTORY + "/" + str(test_case["path"])
	var expected := bool(test_case["expected"])
	var wav := _read_pcm16_wav(fixture_path)
	if not bool(wav.get("ok", false)):
		failures.append("[%s/%s] WAV không hợp lệ: %s" % [
			category, case_id, str(wav.get("error", "lỗi không xác định"))
		])
		return

	var samples: PackedFloat32Array = wav["samples"]
	var sample_rate := float(wav["sample_rate"])
	var maximum_samples := mini(samples.size(), int(sample_rate * MAX_AUDIO_SECONDS))
	var accepted := false
	var accepted_offset := -1
	var best_confidence := -1.0
	var best_reason := "không có cửa sổ đủ dài"

	for offset in range(0, maximum_samples - WINDOW_SIZE + 1, WINDOW_HOP):
		var window := samples.slice(offset, offset + WINDOW_SIZE)
		var result: Dictionary = analyzer.analyze_dan_tranh_sound(window, sample_rate)
		var confidence := float(result.get("confidence", 0.0))
		if confidence > best_confidence:
			best_confidence = confidence
			best_reason = str(result.get("reason", ""))
		if bool(result.get("accepted", false)):
			accepted = true
			accepted_offset = offset
			best_confidence = confidence
			best_reason = str(result.get("reason", ""))
			break

	if accepted != expected:
		var error_kind := "FALSE REJECT" if expected else "FALSE ACCEPT"
		var time_ms := 1000.0 * float(maxi(0, accepted_offset)) / sample_rate
		failures.append("%s [%s/%s] confidence=%.1f reason=%s time=%.0fms" % [
			error_kind, category, case_id, best_confidence, best_reason, time_ms
		])
	else:
		print("PASS [%s/%s] expected=%s confidence=%.1f reason=%s" % [
			category, case_id, expected, best_confidence, best_reason
		])


func _read_pcm16_wav(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "không mở được file"}
	if file.get_length() < 44:
		return {"ok": false, "error": "file quá ngắn"}
	if file.get_buffer(4).get_string_from_ascii() != "RIFF":
		return {"ok": false, "error": "thiếu RIFF header"}
	file.get_32()
	if file.get_buffer(4).get_string_from_ascii() != "WAVE":
		return {"ok": false, "error": "không phải WAVE"}

	var audio_format := 0
	var channels := 0
	var sample_rate := 0
	var bits_per_sample := 0
	var data := PackedByteArray()
	while file.get_position() + 8 <= file.get_length():
		var chunk_id := file.get_buffer(4).get_string_from_ascii()
		var chunk_size := int(file.get_32())
		var chunk_start := file.get_position()
		if chunk_size < 0 or chunk_start + chunk_size > file.get_length():
			return {"ok": false, "error": "chunk WAV bị hỏng: %s" % chunk_id}
		if chunk_id == "fmt ":
			if chunk_size < 16:
				return {"ok": false, "error": "fmt chunk quá ngắn"}
			audio_format = int(file.get_16())
			channels = int(file.get_16())
			sample_rate = int(file.get_32())
			file.get_32()
			file.get_16()
			bits_per_sample = int(file.get_16())
		elif chunk_id == "data":
			data = file.get_buffer(chunk_size)
		file.seek(chunk_start + chunk_size + (chunk_size % 2))

	if audio_format != 1:
		return {"ok": false, "error": "chỉ hỗ trợ WAV PCM (format 1)"}
	if channels != 1 and channels != 2:
		return {"ok": false, "error": "chỉ hỗ trợ mono hoặc stereo"}
	if sample_rate != 44100:
		return {"ok": false, "error": "sample rate phải là 44100 Hz"}
	if bits_per_sample != 16:
		return {"ok": false, "error": "bit depth phải là PCM16"}
	if data.is_empty():
		return {"ok": false, "error": "không có data chunk"}

	var bytes_per_frame := channels * 2
	var frame_count := data.size() / bytes_per_frame
	if frame_count < WINDOW_SIZE:
		return {"ok": false, "error": "audio ngắn hơn %d mẫu" % WINDOW_SIZE}
	var samples := PackedFloat32Array()
	samples.resize(frame_count)
	for frame_index in range(frame_count):
		var mixed_sample := 0.0
		for channel_index in range(channels):
			var byte_index := frame_index * bytes_per_frame + channel_index * 2
			var raw_sample := int(data[byte_index]) | (int(data[byte_index + 1]) << 8)
			if raw_sample >= 32768:
				raw_sample -= 65536
			mixed_sample += float(raw_sample) / 32768.0
		samples[frame_index] = mixed_sample / float(channels)
	return {"ok": true, "sample_rate": float(sample_rate), "samples": samples}


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("PASS: bộ hồi quy mẫu thu thật không nhận nhầm giọng nói/tạp âm")
		quit(0)
		return
	for failure in failures:
		printerr(failure)
	quit(1)
