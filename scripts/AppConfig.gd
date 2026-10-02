## ==============================================================================
## File: AppConfig.gd
## Mô tả: Quản lý cấu hình ứng dụng, nạp biến môi trường (.env) và cung cấp các endpoint API (Backend API & MaiBrain AI Chat URL).
## Chức năng chính:
##  1. Đọc biến môi trường từ hệ thống (OS Environment), file `runtime.env`, file `.env` hoặc gói cấu hình đóng gói `runtime_config.tres`.
##  2. Cung cấp URL cho Backend API chính (`VIETSTAGE_API_BASE_URL`).
##  3. Cung cấp URL kết nối Box Chat AI cô Mai (`MAIBRAIN_CHAT_URL`).
##  4. Kiểm tra tính hợp lệ của cấu hình mạng khi khởi động.
## ==============================================================================

extends RefCounted

## Đường dẫn các file cấu hình môi trường
const RUNTIME_ENV_PATH := "res://runtime.env"
const LOCAL_ENV_PATH := "res://.env"
const ENV_FILE_PATHS := [RUNTIME_ENV_PATH, LOCAL_ENV_PATH]
## Gói tài nguyên cấu hình đóng gói sẵn
const PACKAGED_CONFIG = preload("res://config/runtime_config.tres")
## Thời gian chờ (timeout) mặc định cho các request API (25 giây)
const DEFAULT_API_TIMEOUT_SECONDS := 25.0

static var _dotenv_values: Dictionary = {}
static var _dotenv_loaded := false

## Lấy địa chỉ Base URL của backend VietStage (ví dụ: https://api.vietstage.vn)
static func get_api_base_url() -> String:
	var value := _get_value("VIETSTAGE_API_BASE_URL")
	return value.trim_suffix("/")

## Lấy tiền tố đường dẫn API (ví dụ: /api/v1)
static func get_api_prefix() -> String:
	var value := _get_value("VIETSTAGE_API_PREFIX").strip_edges()
	if value.is_empty() or value == "/":
		return ""
	if not value.begins_with("/"):
		value = "/" + value
	return value.trim_suffix("/")

## Lấy thời gian chờ timeout cho các tác vụ API
static func get_api_timeout_seconds() -> float:
	return DEFAULT_API_TIMEOUT_SECONDS

## Lấy URL dịch vụ AI Box Chat cô Mai (MaiBrain AI Chat Endpoint)
static func get_maibrain_chat_url() -> String:
	return _get_value("MAIBRAIN_CHAT_URL").trim_suffix("/")


## Kiểm tra cấu hình API hợp lệ, trả về chuỗi thông báo lỗi nếu cấu hình thiếu hoặc sai định dạng
static func get_api_configuration_error() -> String:
	var base_url := get_api_base_url()
	if base_url.is_empty():
		return "Missing VIETSTAGE_API_BASE_URL in runtime.env or .env."
	if not base_url.begins_with("http://") and not base_url.begins_with("https://"):
		return "VIETSTAGE_API_BASE_URL must start with http:// or https://."
	if _get_value("VIETSTAGE_API_PREFIX").is_empty():
		return "Missing VIETSTAGE_API_PREFIX in runtime.env or .env."
	return ""

## Lấy giá trị cấu hình theo thứ tự ưu tiên: OS Environment -> Dotenv file -> Gói đóng gói .tres
static func _get_value(key: String) -> String:
	var system_value := OS.get_environment(key).strip_edges()
	if not system_value.is_empty():
		return system_value

	_load_env_files()
	var dotenv_value := str(_dotenv_values.get(key, "")).strip_edges()
	if not dotenv_value.is_empty():
		return dotenv_value
	return _get_packaged_value(key)

## Đọc giá trị cấu hình mặc định từ tài nguyên đóng gói sẵn
static func _get_packaged_value(key: String) -> String:
	match key:
		"VIETSTAGE_API_BASE_URL":
			return str(PACKAGED_CONFIG.get("api_base_url")).strip_edges()
		"VIETSTAGE_API_PREFIX":
			return str(PACKAGED_CONFIG.get("api_prefix")).strip_edges()
		"MAIBRAIN_CHAT_URL":
			return str(PACKAGED_CONFIG.get("maibrain_chat_url")).strip_edges()
		_:
			return ""

## Nạp tất cả các file cấu hình môi trường (.env / runtime.env)
static func _load_env_files() -> void:
	if _dotenv_loaded:
		return
	_dotenv_loaded = true

	for env_path in ENV_FILE_PATHS:
		_load_env_file(env_path)

## Phân tích cú pháp từng dòng trong file .env và lưu vào từ điển `_dotenv_values`
static func _load_env_file(env_path: String) -> void:
	if not FileAccess.file_exists(env_path):
		return

	for raw_line in FileAccess.get_file_as_string(env_path).split("\n"):
		var line := raw_line.strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		if line.begins_with("export "):
			line = line.trim_prefix("export ").strip_edges()

		var separator_index := line.find("=")
		if separator_index <= 0:
			continue

		var key := line.substr(0, separator_index).strip_edges()
		var value := line.substr(separator_index + 1).strip_edges()
		if (
			value.length() >= 2
			and (
				(value.begins_with("\"") and value.ends_with("\""))
				or (value.begins_with("'") and value.ends_with("'"))
			)
		):
			value = value.substr(1, value.length() - 2)
		if not value.is_empty() and not _dotenv_values.has(key):
			_dotenv_values[key] = value
