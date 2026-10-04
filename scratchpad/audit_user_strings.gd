extends SceneTree

func _init() -> void:
	var analyzer = load("res://scripts/AudioCaptureAnalyzer.gd").new()
	analyzer._analyzer = ClassDB.instantiate("AudioAnalyzer")
	var standard := [196.0, 220.0, 261.63, 293.66, 329.63, 392.0, 440.0, 523.25, 587.33, 659.25, 783.99, 880.0, 1046.50, 1174.66, 1318.51, 1567.98, 1760.0]
	var report := "# Đối chiếu bản thu đàn tranh ngày 04/10/2026\n\nNguồn: `E:/amThanhDanTranh`, 15 file M4A, chuyển mono PCM 44.1 kHz bằng FFmpeg. Thiếu dây 7 và 10.\n\nĐo bằng YIN C++, lấy trung vị ba cửa sổ 4096 mẫu sau đỉnh tiếng gảy. Đây là kiểm tra file thu, chưa phải kiểm thử microphone trực tiếp. Chấm theo cao độ chuẩn, sai số cho phép ±65 cents. Không tự thay tần số chuẩn bằng bản thu lệch âm.\n\n| Dây | Chuẩn (Hz) | Đo (Hz) | Lệch (cents) | Khuyến nghị |\n|---|---:|---:|---:|---|\n"
	var failures: Array[String] = []
	for index in range(1, 18):
		var path := "res://test_fixtures/dan_tranh_user_recordings/string_%d.wav" % index
		if not FileAccess.file_exists(path):
			continue
		var stream := AudioStreamWAV.load_from_file(path)
		var samples := PackedFloat32Array()
		var bytes := stream.data
		for i in range(0, bytes.size(), 2):
			samples.append(float(bytes.decode_s16(i)) / 32768.0)
		var peak := 0.0
		var peak_idx := 0
		for i in samples.size():
			if absf(samples[i]) > peak:
				peak = absf(samples[i])
				peak_idx = i
		var pitches: Array[float] = []
		for offset in [0, 2048, 4096, 8192]:
			var start: int = maxi(0, peak_idx - 128) + offset
			var window := samples.slice(start, start + 4096)
			pitches.append(analyzer._analyzer.analyze_pitch_yin(window, 44100.0, 0.18, 100.0, 2100.0))
		var result: Dictionary = analyzer.analyze_dan_tranh_sound(samples.slice(maxi(0, peak_idx - 128), maxi(0, peak_idx - 128) + 4096))
		var stable: Array[float] = [pitches[1], pitches[2], pitches[3]]
		stable.sort()
		var measured := stable[1]
		var cents := 1200.0 * log(measured / standard[index - 1]) / log(2.0)
		var guidance := "Trong ngưỡng" if absf(cents) <= 65.0 else ("Cần chỉnh tăng" if cents < 0.0 else "Cần chỉnh giảm")
		report += "| %d | %.2f | %.2f | %+.1f | %s |\n" % [index, standard[index - 1], measured, cents, guidance]
		# Both implementations must reject sustained voice and judge the same real attack.
		var native = analyzer._analyzer
		analyzer._analyzer = null
		var fallback: Dictionary = analyzer.analyze_dan_tranh_sound(samples.slice(maxi(0, peak_idx - 128), maxi(0, peak_idx - 128) + 4096))
		analyzer._analyzer = native
		if fallback.accepted != result.accepted:
			failures.append("Native/fallback khác nhau ở dây %d" % index)
		if absf(cents) <= 65.0 and not result.accepted:
			failures.append("Bỏ sót tiếng gảy trong ngưỡng của dây %d" % index)
		print("STRING ", index, " peak=", snappedf(peak, 0.001), " time=", snappedf(peak_idx / 44100.0, 0.001), " pitches=", pitches, " timbre=", result)
	var file := FileAccess.open("res://docs/dan-tranh-recording-audit.md", FileAccess.WRITE)
	file.store_string(report + "\nDây 11, 13 và 15 còn bị bộ lọc từ chối vì cao độ ngoài dải tần dây chuẩn; không nới ngưỡng để chấm nhầm dây. Các bản thu khác được bộ lọc tiếng gảy chấp nhận, nhưng chỉ những dây trong ±65 cents mới đủ điều kiện cao độ.\n")
	for failure in failures:
		printerr(failure)
	analyzer.free()
	quit(0 if failures.is_empty() else 1)
