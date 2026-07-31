extends RefCounted

const AppConfig = preload("res://scripts/AppConfig.gd")

const AUTH_LOGIN := "/auth/login"
const AUTH_REGISTER := "/auth/register"
const AUTH_VERIFY_REGISTRATION := "/auth/verify-registration"
const AUTH_FORGOT_PASSWORD := "/auth/forgot-password"
const AUTH_RESET_PASSWORD := "/auth/reset-password"
const AUTH_REFRESH := "/auth/refresh"
const AUTH_LOGOUT := "/auth/logout"
const USERS_ME := "/users/me"


static func build(path: String) -> String:
	var prefix := AppConfig.get_api_prefix()
	if path.is_empty():
		return prefix
	if prefix.is_empty():
		return path
	return prefix + path
