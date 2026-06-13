extends Node

signal cookies_changed(collected: int, total: int)

var _known_cookie_ids: Dictionary = {}
var _collected_cookie_ids: Dictionary = {}

var cookies_collected: int:
	get:
		return _collected_cookie_ids.size()

var total_cookies: int:
	get:
		return _known_cookie_ids.size()

func register_cookie(cookie_id: String) -> bool:
	if not _known_cookie_ids.has(cookie_id):
		_known_cookie_ids[cookie_id] = true
		cookies_changed.emit(cookies_collected, total_cookies)

	return _collected_cookie_ids.has(cookie_id)

func collect_cookie(cookie_id: String) -> bool:
	if cookie_id.is_empty() or _collected_cookie_ids.has(cookie_id):
		return false

	_known_cookie_ids[cookie_id] = true
	_collected_cookie_ids[cookie_id] = true
	cookies_changed.emit(cookies_collected, total_cookies)
	return true

func reset() -> void:
	_known_cookie_ids.clear()
	_collected_cookie_ids.clear()
	cookies_changed.emit(0, 0)

func get_cookie_summary() -> String:
	return "%d/%d" % [cookies_collected, total_cookies]
