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
const ACTIVITY_HISTORY := "/users/me/activity-history"
const UPLOAD := "/upload"

# Leaderboards
const LEADERBOARDS := "/leaderboards"
const LEADERBOARDS_ME := "/leaderboards/me"

# Instrument & Techniques & Skill levels
const INSTRUMENTS := "/instruments"
const LESSONS := "/lessons"
const SKILL_LEVELS := "/skill-levels"
const TECHNIQUES := "/techniques"

# Practice Sessions & Attempts
const PRACTICE_SESSIONS := "/practice/sessions"
const PRACTICE_ATTEMPTS := "/practice/attempts"
const PRACTICE_ATTEMPTS_BULK := "/practice/attempts/bulk"
const PRACTICE_ATTEMPT_FEEDBACK := "/practice/attempts/%s/feedback"

# Cosmetics
const COSMETICS := "/cosmetics"
const MY_COSMETICS := "/users/me/cosmetics"
const COSMETICS_LAYOUT := "/users/me/cosmetics/layout"

# Profile Progress & Achievements
const ACHIEVEMENTS := "/achievements"
const USER_PROGRESS := "/users/me/progress"
const USER_PROGRESS_SUMMARY := "/users/me/progress/summary"
const COMPLETE_LESSON := "/users/me/lessons/%s/complete"
const MY_ACHIEVEMENTS := "/users/me/achievements"
const USER_PASSWORD := "/users/me/password"
const USER_POINT_TRANSACTIONS := "/users/%s/point-transactions"
const USER_FCM_TOKEN := "/users/me/fcm-token"

# Daily challenges & configs
const DAILY_CHALLENGES := "/daily-challenges"
const DAILY_CHALLENGE_COMPLETIONS := "/daily-challenges/%s/completions"
const CONFIGS := "/configs"

# Lesson content subsets
const LESSON_ASSETS := "/lessons/%s/assets"
const LESSON_EXERCISES := "/lessons/%s/exercises"
const LESSON_QUIZZES := "/lessons/%s/quizzes"
const QUIZ_ATTEMPTS := "/quizzes/%s/attempts"
const LESSON_MINIGAMES := "/lessons/%s/minigames"
const MINIGAME_ATTEMPTS := "/minigames/%s/attempts"

# Notifications
const NOTIFICATIONS := "/notifications"

# Admin
const ADMIN_USERS := "/admin/users"
const ADMIN_USER_STATUS := "/admin/users/%s/status"
const ADMIN_DASHBOARD := "/admin/dashboard"
const ADMIN_CONFIGS := "/admin/configs"


static func build(path: String) -> String:
	var prefix := AppConfig.get_api_prefix()
	if path.is_empty():
		return prefix
	if prefix.is_empty():
		return path
	return prefix + path
