extends RefCounted

const SESSION_FILE_PATH := "user://vietstage_auth.dat"
const SESSION_ENCRYPTION_KEY := "VietStageAuthSession2026"

static var access_token := ""
static var refresh_token := ""
static var session_id := ""
static var user_code := ""
static var role := ""
static var _loaded := false


static func apply_auth_response(auth_data: Dictionary) -> bool:
	ensure_loaded()
	var next_access_token := str(auth_data.get("token", ""))
	if next_access_token.is_empty():
		return false

	access_token = next_access_token
	
	var next_refresh_token := str(auth_data.get("refreshToken", ""))
	if not next_refresh_token.is_empty():
		refresh_token = next_refresh_token
		
	var next_session_id := str(auth_data.get("sessionId", ""))
	if not next_session_id.is_empty():
		session_id = next_session_id
		
	if auth_data.has("userCode"):
		user_code = str(auth_data.get("userCode", ""))
	if auth_data.has("role"):
		role = str(auth_data.get("role", ""))
		
	save_session()
	return true


static func has_access_token() -> bool:
	ensure_loaded()
	return not access_token.is_empty()


static func can_refresh() -> bool:
	ensure_loaded()
	return not refresh_token.is_empty() and not session_id.is_empty()


static func clear_session() -> void:
	access_token = ""
	refresh_token = ""
	session_id = ""
	user_code = ""
	role = ""
	if FileAccess.file_exists(SESSION_FILE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SESSION_FILE_PATH))


static func save_session() -> void:
	var payload := {
		"access_token": access_token,
		"refresh_token": refresh_token,
		"session_id": session_id,
		"user_code": user_code,
		"role": role,
	}
	var file := FileAccess.open_encrypted_with_pass(
		SESSION_FILE_PATH,
		FileAccess.WRITE,
		SESSION_ENCRYPTION_KEY
	)
	if file == null:
		printerr("Could not persist the authentication session.")
		return
	file.store_string(JSON.stringify(payload))
	file.close()


static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	load_session()


static func load_session() -> void:
	if not FileAccess.file_exists(SESSION_FILE_PATH):
		return

	var file := FileAccess.open_encrypted_with_pass(
		SESSION_FILE_PATH,
		FileAccess.READ,
		SESSION_ENCRYPTION_KEY
	)
	if file == null:
		clear_session()
		return

	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is not Dictionary:
		clear_session()
		return

	access_token = str(parsed.get("access_token", ""))
	refresh_token = str(parsed.get("refresh_token", ""))
	session_id = str(parsed.get("session_id", ""))
	user_code = str(parsed.get("user_code", ""))
	role = str(parsed.get("role", ""))
