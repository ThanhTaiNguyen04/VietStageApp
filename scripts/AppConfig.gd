extends RefCounted

const RUNTIME_ENV_PATH := "res://runtime.env"
const LOCAL_ENV_PATH := "res://.env"
const ENV_FILE_PATHS := [RUNTIME_ENV_PATH, LOCAL_ENV_PATH]
const PACKAGED_CONFIG = preload("res://config/runtime_config.tres")
const DEFAULT_API_TIMEOUT_SECONDS := 25.0

static var _dotenv_values: Dictionary = {}
static var _dotenv_loaded := false


static func get_api_base_url() -> String:
	var value := _get_value("VIETSTAGE_API_BASE_URL")
	return value.trim_suffix("/")


static func get_api_prefix() -> String:
	var value := _get_value("VIETSTAGE_API_PREFIX").strip_edges()
	if value.is_empty() or value == "/":
		return ""
	if not value.begins_with("/"):
		value = "/" + value
	return value.trim_suffix("/")


static func get_api_timeout_seconds() -> float:
	return DEFAULT_API_TIMEOUT_SECONDS


static func get_api_configuration_error() -> String:
	var base_url := get_api_base_url()
	if base_url.is_empty():
		return "Missing VIETSTAGE_API_BASE_URL in runtime.env or .env."
	if not base_url.begins_with("http://") and not base_url.begins_with("https://"):
		return "VIETSTAGE_API_BASE_URL must start with http:// or https://."
	if _get_value("VIETSTAGE_API_PREFIX").is_empty():
		return "Missing VIETSTAGE_API_PREFIX in runtime.env or .env."
	return ""


static func _get_value(key: String) -> String:
	var system_value := OS.get_environment(key).strip_edges()
	if not system_value.is_empty():
		return system_value

	_load_env_files()
	var dotenv_value := str(_dotenv_values.get(key, "")).strip_edges()
	if not dotenv_value.is_empty():
		return dotenv_value
	return _get_packaged_value(key)


static func _get_packaged_value(key: String) -> String:
	match key:
		"VIETSTAGE_API_BASE_URL":
			return str(PACKAGED_CONFIG.get("api_base_url")).strip_edges()
		"VIETSTAGE_API_PREFIX":
			return str(PACKAGED_CONFIG.get("api_prefix")).strip_edges()
		_:
			return ""


static func _load_env_files() -> void:
	if _dotenv_loaded:
		return
	_dotenv_loaded = true

	for env_path in ENV_FILE_PATHS:
		_load_env_file(env_path)


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
