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
	if (
		int(response.get("status", 0)) == 401
		and retry_after_refresh
		and AuthSessionStore.can_refresh()
	):
		var refresh_response := await refresh_session()
		if _is_success(refresh_response):
			return await _request_raw(path, method, payload, true)
	return response


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


func error_message(response: Dictionary, fallback: String) -> String:
	var body = response.get("body", {})
	if body is Dictionary:
		var body_message := str(body.get("message", ""))
		if not body_message.is_empty():
			return body_message
	var message := str(response.get("message", ""))
	return message if not message.is_empty() else fallback


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
	var response_body: Dictionary = parsed if parsed is Dictionary else {}

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
