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
const UPLOAD := "/upload"

# Leaderboards
const LEADERBOARDS := "/leaderboards"
const LEADERBOARDS_ME := "/leaderboards/me"

# Instruments & Lessons
const INSTRUMENTS := "/instruments"
const LESSONS := "/lessons"
const SKILL_LEVELS := "/skill-levels"

# Practice Sessions & Attempts
const PRACTICE_SESSIONS := "/practice/sessions"
const PRACTICE_ATTEMPTS := "/practice/attempts"

# Cosmetics
const COSMETICS := "/cosmetics"
const MY_COSMETICS := "/users/me/cosmetics"

# Profile Progress & Achievements
const ACHIEVEMENTS := "/achievements"
const USER_PROGRESS := "/users/me/progress"
const USER_PROGRESS_SUMMARY := "/users/me/progress/summary"
const MY_ACHIEVEMENTS := "/users/me/achievements"
const USER_PASSWORD := "/users/me/password"


static func build(path: String) -> String:
	var prefix := AppConfig.get_api_prefix()
	if path.is_empty():
		return prefix
	if prefix.is_empty():
		return path
	return prefix + path
