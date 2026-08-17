extends Node

const AuthSessionStore = preload("res://scripts/AuthSession.gd")
const AppConfig = preload("res://scripts/AppConfig.gd")
const ApiRoutes = preload("res://scripts/ApiRoutes.gd")


func login(email: String, password: String) -> Dictionary:
	return await _request_raw(
		ApiRoutes.build(ApiRoutes.AUTH_LOGIN),
		HTTPClient.METHOD_POST,
		{"email": email, "password": password}
	)


func register(email: String, password: String, full_name: String) -> Dictionary:
	return await _request_raw(
		ApiRoutes.build(ApiRoutes.AUTH_REGISTER),
		HTTPClient.METHOD_POST,
		{"email": email, "password": password, "fullName": full_name}
	)


func verify_registration(email: String, otp_code: String) -> Dictionary:
	return await _request_raw(
		ApiRoutes.build(ApiRoutes.AUTH_VERIFY_REGISTRATION),
		HTTPClient.METHOD_POST,
		{"email": email, "otpCode": otp_code}
	)


func forgot_password(email: String) -> Dictionary:
	return await _request_raw(
		ApiRoutes.build(ApiRoutes.AUTH_FORGOT_PASSWORD),
		HTTPClient.METHOD_POST,
		{"email": email}
	)


func reset_password(email: String, verification_code: String, new_password: String) -> Dictionary:
	return await _request_raw(
		ApiRoutes.build(ApiRoutes.AUTH_RESET_PASSWORD),
		HTTPClient.METHOD_POST,
		{
			"email": email,
			"verificationCode": verification_code,
			"newPassword": new_password,
		}
	)


func get_me() -> Dictionary:
	return await request_json(ApiRoutes.build(ApiRoutes.USERS_ME), HTTPClient.METHOD_GET)


# ── LEADERBOARD APIs ──────────────────────────────────────────────────

## Lấy danh sách Top bảng xếp hạng
func get_top_leaderboard(top: int = 100) -> Dictionary:
	var path = ApiRoutes.build(ApiRoutes.LEADERBOARDS) + "?top=" + str(top)
	return await request_json(path, HTTPClient.METHOD_GET)

## Lấy thông tin xếp hạng cá nhân
func get_my_leaderboard() -> Dictionary:
	return await request_json(ApiRoutes.build(ApiRoutes.LEADERBOARDS_ME), HTTPClient.METHOD_GET)


# ── INSTRUMENTS & LESSONS APIs ────────────────────────────────────────

## Lấy tất cả nhạc cụ
func get_instruments() -> Dictionary:
	return await request_json(ApiRoutes.build(ApiRoutes.INSTRUMENTS), HTTPClient.METHOD_GET)

## Lấy tất cả trình độ (PUBLIC)
func get_skill_levels() -> Dictionary:
	return await request_json(ApiRoutes.build(ApiRoutes.SKILL_LEVELS), HTTPClient.METHOD_GET)

## Lấy danh sách kỹ thuật (PUBLIC, lọc theo nhạc cụ)
func get_techniques(instrument_id: int = 0) -> Dictionary:
	var path := ApiRoutes.build(ApiRoutes.TECHNIQUES)
	if instrument_id > 0:
		path += "?instrument_id=" + str(instrument_id)
	return await request_json(path, HTTPClient.METHOD_GET)

## Lấy danh sách bài học (Lọc theo nhạc cụ / kỹ thuật / trình độ)
func get_lessons(instrument_id: int = 0, skill_level_id: int = 0, technique_id: int = 0) -> Dictionary:
	var query_params := []
	if instrument_id > 0:
		query_params.append("instrumentId=" + str(instrument_id))
	if skill_level_id > 0:
		query_params.append("skillLevelId=" + str(skill_level_id))
	if technique_id > 0:
		query_params.append("techniqueId=" + str(technique_id))
	
	var path := ApiRoutes.build(ApiRoutes.LESSONS)
	if query_params.size() > 0:
		path += "?" + "&".join(query_params)
		
	return await request_json(path, HTTPClient.METHOD_GET)

## Lấy chi tiết một bài học
func get_lesson_detail(lesson_id: int) -> Dictionary:
	var path := ApiRoutes.build(ApiRoutes.LESSONS) + "/" + str(lesson_id)
	return await request_json(path, HTTPClient.METHOD_GET)

## Lấy danh sách assets (âm thanh / beat map) của bài học
func get_lesson_assets(lesson_id: int, asset_type: String = "") -> Dictionary:
	var path := ApiRoutes.build(ApiRoutes.LESSON_ASSETS % str(lesson_id))
	if not asset_type.is_empty():
		path += "?type=" + asset_type
	return await request_json(path, HTTPClient.METHOD_GET)

## Lấy danh sách bài tập (exercises) của bài học
func get_lesson_exercises(lesson_id: int) -> Dictionary:
	var path := ApiRoutes.build(ApiRoutes.LESSON_EXERCISES % str(lesson_id))
	return await request_json(path, HTTPClient.METHOD_GET)

## Lấy danh sách câu hỏi trắc nghiệm của bài học
func get_lesson_quizzes(lesson_id: int) -> Dictionary:
	var path := ApiRoutes.build(ApiRoutes.LESSON_QUIZZES % str(lesson_id))
	return await request_json(path, HTTPClient.METHOD_GET)

## Nộp đáp án câu hỏi trắc nghiệm
func submit_quiz_attempt(quiz_id: int, selected_answer: String) -> Dictionary:
	var path := ApiRoutes.build(ApiRoutes.QUIZ_ATTEMPTS % str(quiz_id))
	return await request_json(path, HTTPClient.METHOD_POST, {
		"selectedAnswer": selected_answer
	})

## Lấy danh sách minigame của bài học
func get_lesson_minigames(lesson_id: int) -> Dictionary:
	var path := ApiRoutes.build(ApiRoutes.LESSON_MINIGAMES % str(lesson_id))
	return await request_json(path, HTTPClient.METHOD_GET)

## Nộp kết quả minigame
func submit_minigame_attempt(
	minigame_id: int,
	score: int,
	stars_earned: int,
	started_at: String,
	completed_at: String,
	client_attempt_id: String = ""
) -> Dictionary:
	var payload := {
		"score": score,
		"starsEarned": stars_earned,
		"startedAt": started_at,
		"completedAt": completed_at,
	}
	if not client_attempt_id.is_empty():
		payload["clientAttemptId"] = client_attempt_id
	var path := ApiRoutes.build(ApiRoutes.MINIGAME_ATTEMPTS % str(minigame_id))
	return await request_json(path, HTTPClient.METHOD_POST, payload)

## Tiến độ của một học viên trong một bài học (INSTRUCTOR)
func get_learner_lesson_progress(lesson_id: int, learner_id: int) -> Dictionary:
	var path := "/lessons/%d/learners/%d/progress" % [lesson_id, learner_id]
	return await request_json(ApiRoutes.build(path), HTTPClient.METHOD_GET)


# ── PRACTICE SESSIONS & ATTEMPTS APIs ─────────────────────────────────

## Bắt đầu một phiên tập luyện mới
func start_practice_session() -> Dictionary:
	return await request_json(ApiRoutes.build(ApiRoutes.PRACTICE_SESSIONS), HTTPClient.METHOD_POST, {})

## Kết thúc phiên tập luyện
func end_practice_session(session_id: int) -> Dictionary:
	var path := ApiRoutes.build(ApiRoutes.PRACTICE_SESSIONS) + "/" + str(session_id)
	var payload = {
		"ended_at": _iso_now()
	}
	return await request_json(path, HTTPClient.METHOD_PUT, payload)

## Gửi kết quả lượt luyện tập (AI chấm điểm)
func submit_practice_attempt(
	session_id: int,
	exercise_id: int,
	pitch: float,
	rhythm: float,
	dynamics: float = 0.0,
	tonal_quality: float = 0.0,
	breath: float = 0.0,
	client_uuid: String = "",
	created_at: String = ""
) -> Dictionary:
	var payload = {
		"session_id": session_id,
		"exercise_id": exercise_id,
		"pitch_score": pitch,
		"rhythm_score": rhythm,
		"dynamics_score": dynamics,
		"tonal_quality_score": tonal_quality,
		"breath_score": breath,
	}
	if not client_uuid.is_empty():
		payload["client_uuid"] = client_uuid
	if not created_at.is_empty():
		payload["created_at"] = created_at
	return await request_json(ApiRoutes.build(ApiRoutes.PRACTICE_ATTEMPTS), HTTPClient.METHOD_POST, payload)

## Lấy lịch sử lượt tập (hỗ trợ adaptive difficulty — 10 lượt gần nhất)
func get_practice_attempts(exercise_id: int = 0, page: int = 0, size: int = 10) -> Dictionary:
	var query_params := []
	if exercise_id > 0:
		query_params.append("exercise_id=" + str(exercise_id))
	query_params.append("page=" + str(page))
	query_params.append("size=" + str(size))
	var path := ApiRoutes.build(ApiRoutes.PRACTICE_ATTEMPTS) + "?" + "&".join(query_params)
	return await request_json(path, HTTPClient.METHOD_GET)

## Gửi phản hồi văn bản cho một lượt tập (INSTRUCTOR)
func submit_attempt_feedback(attempt_id: int, comment: String) -> Dictionary:
	var path := ApiRoutes.build(ApiRoutes.PRACTICE_ATTEMPT_FEEDBACK % str(attempt_id))
	return await request_json(path, HTTPClient.METHOD_POST, {"comment": comment})


# ── PROGRESS & ACHIEVEMENTS APIs ──────────────────────────────────────

## Lấy tiến độ học tập của bản thân
func get_my_progress(instrument_id: int = 0, skill_level_id: int = 0) -> Dictionary:
	var query_params := []
	if instrument_id > 0:
		query_params.append("instrument_id=" + str(instrument_id))
	if skill_level_id > 0:
		query_params.append("skill_level_id=" + str(skill_level_id))
	
	var path := ApiRoutes.build(ApiRoutes.USER_PROGRESS)
	if query_params.size() > 0:
		path += "?" + "&".join(query_params)
		
	return await request_json(path, HTTPClient.METHOD_GET)

## Lấy tổng quan tiến độ (Streak, XP, ...)
func get_my_progress_summary() -> Dictionary:
	return await request_json(ApiRoutes.build(ApiRoutes.USER_PROGRESS_SUMMARY), HTTPClient.METHOD_GET)

## Lấy thành tựu đã đạt
func get_all_achievements() -> Dictionary:
	return await request_json(ApiRoutes.build(ApiRoutes.ACHIEVEMENTS), HTTPClient.METHOD_GET)

func create_achievement(name: String, icon_url: String, condition_json: String, description: String = "") -> Dictionary:
	var payload := {
		"name": name,
		"iconUrl": icon_url,
		"conditionJson": condition_json,
	}
	if not description.is_empty():
		payload["description"] = description
	return await request_json(ApiRoutes.build(ApiRoutes.ACHIEVEMENTS), HTTPClient.METHOD_POST, payload)

func update_achievement(
	achievement_id: int,
	name: String,
	icon_url: String,
	condition_json: String,
	description: String = ""
) -> Dictionary:
	var payload := {
		"name": name,
		"iconUrl": icon_url,
		"conditionJson": condition_json,
	}
	if not description.is_empty():
		payload["description"] = description
	var path := ApiRoutes.build(ApiRoutes.ACHIEVEMENTS) + "/" + str(achievement_id)
	return await request_json(path, HTTPClient.METHOD_PUT, payload)

func get_my_achievements() -> Dictionary:
	return await request_json(ApiRoutes.build(ApiRoutes.MY_ACHIEVEMENTS), HTTPClient.METHOD_GET)

func revoke_achievement(learner_id: int, achievement_id: int) -> Dictionary:
	var path := ApiRoutes.build("/users/%d/achievements/%d" % [learner_id, achievement_id])
	return await request_json(path, HTTPClient.METHOD_DELETE)


# ── DAILY CHALLENGES & CONFIGS APIs ───────────────────────────────────

## Lấy thử thách hằng ngày
func get_daily_challenges(date: String = "") -> Dictionary:
	var path := ApiRoutes.build(ApiRoutes.DAILY_CHALLENGES)
	if not date.is_empty():
		path += "?date=" + date
	return await request_json(path, HTTPClient.METHOD_GET)

## Hoàn thành thử thách hằng ngày (nhận điểm thưởng)
func complete_daily_challenge(challenge_id: int) -> Dictionary:
	var path := ApiRoutes.build(ApiRoutes.DAILY_CHALLENGE_COMPLETIONS % str(challenge_id))
	return await request_json(path, HTTPClient.METHOD_POST, {})

## Lấy cấu hình công khai cho game engine (độ khó, feature toggles, …)
func get_configs(group: String = "") -> Dictionary:
	var path := ApiRoutes.build(ApiRoutes.CONFIGS)
	if not group.is_empty():
		path += "?group=" + group
	return await request_json(path, HTTPClient.METHOD_GET)


# ── NOTIFICATIONS APIs ────────────────────────────────────────────────

## Lấy thông báo của người dùng
func get_notifications(is_read: int = -1, page: int = 0, size: int = 20) -> Dictionary:
	var query_params := []
	if is_read >= 0:
		query_params.append("isRead=" + str(is_read))
	query_params.append("page=" + str(page))
	query_params.append("size=" + str(size))
	var path := ApiRoutes.build(ApiRoutes.NOTIFICATIONS) + "?" + "&".join(query_params)
	return await request_json(path, HTTPClient.METHOD_GET)

## Đánh dấu một thông báo đã đọc
func mark_notification_read(notification_id: int) -> Dictionary:
	var path := ApiRoutes.build(ApiRoutes.NOTIFICATIONS) + "/" + str(notification_id)
	return await request_json(path, HTTPClient.METHOD_PUT, {})

## Đánh dấu tất cả thông báo đã đọc
func mark_all_notifications_read() -> Dictionary:
	return await request_json(ApiRoutes.build(ApiRoutes.NOTIFICATIONS), HTTPClient.METHOD_PUT, {})


# ── ADMIN APIs ────────────────────────────────────────────────────────

## Điều hành: danh sách người dùng
func admin_get_users(page: int = 0, size: int = 50, search: String = "", role: String = "") -> Dictionary:
	var query_params := ["page=" + str(page), "size=" + str(size)]
	if not search.is_empty():
		query_params.append("search=" + search)
	if not role.is_empty():
		query_params.append("role=" + role)
	var path := ApiRoutes.build(ApiRoutes.ADMIN_USERS) + "?" + "&".join(query_params)
	return await request_json(path, HTTPClient.METHOD_GET)

## Điều hành: kích hoạt / khóa tài khoản
func admin_update_user_status(user_id: int, status: String) -> Dictionary:
	var path := ApiRoutes.build(ApiRoutes.ADMIN_USER_STATUS % str(user_id))
	return await request_json(path, HTTPClient.METHOD_PUT, {"status": status})

## Điều hành: thống kê hệ thống
func admin_get_dashboard() -> Dictionary:
	return await request_json(ApiRoutes.build(ApiRoutes.ADMIN_DASHBOARD), HTTPClient.METHOD_GET)

## Điều hành: cập nhật cấu hình hệ thống
func admin_update_config(config_key: String, value: String) -> Dictionary:
	var path := ApiRoutes.build(ApiRoutes.ADMIN_CONFIGS) + "/" + config_key
	return await request_json(path, HTTPClient.METHOD_PUT, {"value": value})


# ── COSMETICS APIs ────────────────────────────────────────────────────

## Lấy danh sách trang bị trong cửa hàng
func get_all_cosmetics() -> Dictionary:
	return await request_json(ApiRoutes.build(ApiRoutes.COSMETICS), HTTPClient.METHOD_GET)

## Lấy danh sách trang bị sở hữu
func get_my_cosmetics() -> Dictionary:
	return await request_json(ApiRoutes.build(ApiRoutes.MY_COSMETICS), HTTPClient.METHOD_GET)

## Mua vật phẩm (Unlock)
func unlock_cosmetic(cosmetic_id: int) -> Dictionary:
	var path := ApiRoutes.build(ApiRoutes.MY_COSMETICS)
	var payload = {
		"cosmeticId": cosmetic_id
	}
	return await request_json(path, HTTPClient.METHOD_POST, payload)

## Trang bị / Tháo bỏ vật phẩm trang trí
func equip_cosmetic(cosmetic_id: int, is_equipped: bool) -> Dictionary:
	var path := ApiRoutes.build(ApiRoutes.MY_COSMETICS) + "/" + str(cosmetic_id)
	var payload = {
		"is_equipped": is_equipped
	}
	return await request_json(path, HTTPClient.METHOD_PUT, payload)

## Thay đổi mật khẩu người dùng
func change_password(old_pass: String, new_pass: String, confirm_pass: String) -> Dictionary:
	var payload = {
		"oldPassword": old_pass,
		"newPassword": new_pass,
		"confirmPassword": confirm_pass
	}
	return await request_json(ApiRoutes.build(ApiRoutes.USER_PASSWORD), HTTPClient.METHOD_PUT, payload)


## Cập nhật thông tin người dùng
func update_profile(full_name: String, avatar_url: String = "") -> Dictionary:
	var payload = {
		"fullName": full_name,
		"avatarUrl": avatar_url
	}
	return await request_json(ApiRoutes.build(ApiRoutes.USERS_ME), HTTPClient.METHOD_PUT, payload)


func upload_file(file_bytes: PackedByteArray, file_name: String, mime_type: String) -> Dictionary:
	var response := await _request_multipart_file(file_bytes, file_name, mime_type)
	if int(response.get("status", 0)) == 401 and AuthSessionStore.can_refresh():
		var refresh_response := await refresh_session()
		if _is_success(refresh_response):
			return await _request_multipart_file(file_bytes, file_name, mime_type)
	return response


func logout() -> Dictionary:
	var response := {"status": 200, "body": {}, "message": ""}
	if AuthSessionStore.has_access_token():
		response = await _request_raw(
			ApiRoutes.build(ApiRoutes.AUTH_LOGOUT),
			HTTPClient.METHOD_POST,
			{},
			true
		)
	AuthSessionStore.clear_session()
	return response


func request_json(
	path: String,
	method: HTTPClient.Method = HTTPClient.METHOD_GET,
	payload: Dictionary = {},
	retry_after_refresh: bool = true
) -> Dictionary:
	var response := await _request_raw(path, method, payload, true)
	
	# Xử lý Offline Mode (Lỗi kết nối / Mất mạng)
	if int(response.get("status", 0)) == 0:
		if method == HTTPClient.METHOD_GET:
			var cached_body = _read_cache(path)
			if typeof(cached_body) == TYPE_DICTIONARY and not cached_body.is_empty():
				print("OFFLINE MODE: Serving cached data for ", path)
				return {
					"status": 200,
					"body": cached_body,
					"message": "Đang chạy chế độ Ngoại tuyến (Offline)."
				}
		elif method in [HTTPClient.METHOD_POST, HTTPClient.METHOD_PUT, HTTPClient.METHOD_PATCH]:
			print("OFFLINE MODE: Queuing request for ", path)
			_add_to_sync_queue(path, method, payload)
			return {
				"status": 202,
				"body": {},
				"message": "Đã lưu kết quả cục bộ. Sẽ đồng bộ khi có mạng."
			}

	# Nếu request GET thành công, lưu cache và xử lý hàng đợi đồng bộ
	if method == HTTPClient.METHOD_GET and _is_success(response):
		var body = response.get("body", {})
		if typeof(body) == TYPE_DICTIONARY and not body.is_empty():
			_write_cache(path, body)
		_process_sync_queue()

	if (
		int(response.get("status", 0)) == 401
		and retry_after_refresh
		and AuthSessionStore.can_refresh()
	):
		var refresh_response := await refresh_session()
		if _is_success(refresh_response):
			return await _request_raw(path, method, payload, true)
	return response

# ── OFFLINE MODE HELPERS ──────────────────────────────────────────────

func _get_cache_path() -> String:
	return "user://offline_cache.json"
	
func _get_sync_queue_path() -> String:
	return "user://offline_sync_queue.json"

func _read_cache(path: String) -> Dictionary:
	var cache_file = _get_cache_path()
	if not FileAccess.file_exists(cache_file):
		return {}
	var file = FileAccess.open(cache_file, FileAccess.READ)
	if not file: return {}
	var content = file.get_as_text()
	var json = JSON.parse_string(content)
	if typeof(json) != TYPE_DICTIONARY: return {}
	if json.has(path) and typeof(json[path]) == TYPE_DICTIONARY:
		return json[path]
	return {}

func _write_cache(path: String, body: Dictionary) -> void:
	var cache_file = _get_cache_path()
	var json = {}
	if FileAccess.file_exists(cache_file):
		var file = FileAccess.open(cache_file, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			var parsed = JSON.parse_string(content)
			if typeof(parsed) == TYPE_DICTIONARY:
				json = parsed
	json[path] = body
	var file_out = FileAccess.open(cache_file, FileAccess.WRITE)
	if file_out:
		file_out.store_string(JSON.stringify(json))

func _add_to_sync_queue(path: String, method: HTTPClient.Method, payload: Dictionary) -> void:
	var sync_file = _get_sync_queue_path()
	var queue = []
	if FileAccess.file_exists(sync_file):
		var file = FileAccess.open(sync_file, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			var parsed = JSON.parse_string(content)
			if typeof(parsed) == TYPE_ARRAY:
				queue = parsed
	queue.append({
		"path": path,
		"method": method,
		"payload": payload
	})
	var file_out = FileAccess.open(sync_file, FileAccess.WRITE)
	if file_out:
		file_out.store_string(JSON.stringify(queue))

func _process_sync_queue() -> void:
	var sync_file = _get_sync_queue_path()
	if not FileAccess.file_exists(sync_file): return
	var file = FileAccess.open(sync_file, FileAccess.READ)
	if not file: return
	var content = file.get_as_text()
	var queue = JSON.parse_string(content)
	if typeof(queue) != TYPE_ARRAY or queue.size() == 0: return
	
	# Xoá queue file để tránh lặp vô hạn
	var clear_file = FileAccess.open(sync_file, FileAccess.WRITE)
	if clear_file: clear_file.store_string("[]")
	
	for item in queue:
		_request_raw(item.path, int(item.method), item.payload, true)


func refresh_session() -> Dictionary:
	if not AuthSessionStore.can_refresh():
		return {
			"status": 401,
			"body": {},
			"message": "Phiên đăng nhập đã hết hạn.",
		}

	var response := await _request_raw(
		ApiRoutes.build(ApiRoutes.AUTH_REFRESH),
		HTTPClient.METHOD_POST,
		{
			"sessionId": AuthSessionStore.session_id,
			"refreshToken": AuthSessionStore.refresh_token,
		}
	)
	if _is_success(response):
		var auth_data: Dictionary = response.get("body", {}).get("data", {})
		if not AuthSessionStore.apply_auth_response(auth_data):
			AuthSessionStore.clear_session()
			return {
				"status": 500,
				"body": {},
				"message": "Máy chủ trả về phiên đăng nhập không hợp lệ.",
			}
	elif int(response.get("status", 0)) in [401, 403]:
		AuthSessionStore.clear_session()
	return response


static func _iso_now() -> String:
	var current_time = Time.get_datetime_dict_from_system()
	return "%d-%02d-%02dT%02d:%02d:%02dZ" % [
		current_time.year, current_time.month, current_time.day,
		current_time.hour, current_time.minute, current_time.second
	]


func error_message(response: Dictionary, fallback: String) -> String:
	var status = int(response.get("status", 0))
	var body = response.get("body", {})
	var message := ""
	if body is Dictionary:
		message = str(body.get("message", ""))
	if message.is_empty():
		message = str(response.get("message", ""))
		
	if message.is_empty():
		if status == 500:
			return "Đã xảy ra lỗi kết nối hệ thống. Vui lòng thử lại sau."
		return fallback

	# Check for technical jargon or backend database errors
	var technical_keywords = [
		"internal server error", "jdbc", "sql", "exception", "database", "postgres", 
		"mysql", "syntax", "column", "table", "relation", "constraint", "connection",
		"refused", "driver", "hibernate", "entity", "jpa", "server error"
	]
	var lower_msg = message.to_lower()
	for kw in technical_keywords:
		if kw in lower_msg:
			return "Đã xảy ra lỗi kết nối hệ thống. Vui lòng thử lại sau."
			
	return message


func _request_raw(
	path: String,
	method: HTTPClient.Method,
	payload: Dictionary = {},
	with_auth: bool = false
) -> Dictionary:
	var configuration_error := AppConfig.get_api_configuration_error()
	if not configuration_error.is_empty():
		return {
			"status": 0,
			"body": {},
			"message": configuration_error,
		}

	var http := HTTPRequest.new()
	http.timeout = AppConfig.get_api_timeout_seconds()
	add_child(http)

	var headers := PackedStringArray(["Accept: application/json"])
	var body := ""
	if method != HTTPClient.METHOD_GET:
		headers.append("Content-Type: application/json")
		body = JSON.stringify(payload)
	if with_auth and AuthSessionStore.has_access_token():
		headers.append("Authorization: Bearer " + AuthSessionStore.access_token)

	var request_url := AppConfig.get_api_base_url() + path
	var request_error := http.request(request_url, headers, method, body)
	if request_error != OK:
		http.queue_free()
		return {
			"status": 0,
			"body": {},
			"message": "Không thể gửi yêu cầu đến máy chủ.",
		}

	var completed: Array = await http.request_completed
	http.queue_free()

	var transport_result := int(completed[0])
	var response_code := int(completed[1])
	var response_bytes: PackedByteArray = completed[3]
	var response_text := response_bytes.get_string_from_utf8()
	var parsed = JSON.parse_string(response_text) if not response_text.is_empty() else {}
	var response_body: Dictionary = {}
	if parsed is Dictionary:
		response_body = parsed
	elif parsed is Array:
		response_body = {"data": parsed}

	if transport_result != HTTPRequest.RESULT_SUCCESS:
		return {
			"status": 0,
			"body": response_body,
			"message": "Kết nối máy chủ bị gián đoạn. Vui lòng thử lại.",
		}

	return {
		"status": response_code,
		"body": response_body,
		"message": "",
	}


func _is_success(response: Dictionary) -> bool:
	var status := int(response.get("status", 0))
	return status >= 200 and status < 300


func _request_multipart_file(
	file_bytes: PackedByteArray,
	file_name: String,
	mime_type: String
) -> Dictionary:
	var configuration_error := AppConfig.get_api_configuration_error()
	if not configuration_error.is_empty():
		return {"status": 0, "body": {}, "message": configuration_error}

	var boundary := "VietStageBoundary%d" % Time.get_ticks_usec()
	var safe_name := file_name.replace("\"", "_").replace("\r", "").replace("\n", "")
	var body := PackedByteArray()
	var preamble := (
		"--%s\r\nContent-Disposition: form-data; name=\"file\"; filename=\"%s\"\r\n"
		+ "Content-Type: %s\r\n\r\n"
	) % [boundary, safe_name, mime_type]
	body.append_array(preamble.to_utf8_buffer())
	body.append_array(file_bytes)
	body.append_array(("\r\n--%s--\r\n" % boundary).to_utf8_buffer())

	var headers := PackedStringArray([
		"Accept: application/json",
		"Content-Type: multipart/form-data; boundary=" + boundary,
	])
	if AuthSessionStore.has_access_token():
		headers.append("Authorization: Bearer " + AuthSessionStore.access_token)

	var http := HTTPRequest.new()
	http.timeout = AppConfig.get_api_timeout_seconds()
	add_child(http)
	var request_url := AppConfig.get_api_base_url() + ApiRoutes.build(ApiRoutes.UPLOAD)
	var request_error := http.request_raw(request_url, headers, HTTPClient.METHOD_POST, body)
	if request_error != OK:
		http.queue_free()
		return {"status": 0, "body": {}, "message": "Không thể gửi ảnh đến máy chủ."}

	var completed: Array = await http.request_completed
	http.queue_free()
	var response_bytes: PackedByteArray = completed[3]
	var response_text := response_bytes.get_string_from_utf8()
	var parsed = JSON.parse_string(response_text) if not response_text.is_empty() else {}
	var response_body: Dictionary = parsed if parsed is Dictionary else {}
	if int(completed[0]) != HTTPRequest.RESULT_SUCCESS:
		return {
			"status": 0,
			"body": response_body,
			"message": "Kết nối tải ảnh bị gián đoạn. Vui lòng thử lại.",
		}
	return {"status": int(completed[1]), "body": response_body, "message": ""}
