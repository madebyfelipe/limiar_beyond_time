class_name GeneralSettings
extends RefCounted
## Video, audio and aim preferences. Shares settings.cfg without replacing the
## existing aim/filter sections. Probes opt into a separate path explicitly.
const DEFAULT_PATH := "user://settings.cfg"
const SECTION := "general"
const WINDOW_NAMES := ["WINDOWED", "FULLSCREEN", "EXCLUSIVE"]
const WINDOW_MODES := [DisplayServer.WINDOW_MODE_WINDOWED, DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
const RESOLUTIONS: Array[Vector2i] = [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440)]
const FRAME_CAPS := [0, 30, 60, 90, 120, 144, 165, 240]
const DEFAULTS := {"window_mode": 0, "resolution": 1, "vsync": true, "fps_limit": 0, "volume": 100, "mouse_sensitivity": 1.0, "mouse_invert_y": false, "stick_deadzone": 0.25, "trigger_deadzone": 0.2, "pad_invert_y": false}
static var settings_path: String = DEFAULT_PATH
static var values: Dictionary = DEFAULTS.duplicate()
static var _loaded: bool = false

static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	if _isolated_probe_required():
		return
	var file := ConfigFile.new()
	if file.load(settings_path) == OK:
		for key: String in DEFAULTS:
			values[key] = _validated(key, file.get_value(SECTION, key, DEFAULTS[key]))
	apply()

static func _isolated_probe_required() -> bool:
	return OS.get_cmdline_args().has("--script") and settings_path == DEFAULT_PATH

static func _validated(key: String, value: Variant) -> Variant:
	if typeof(value) != typeof(DEFAULTS[key]):
		return DEFAULTS[key]
	match key:
		"window_mode": return clampi(value, 0, WINDOW_NAMES.size() - 1)
		"resolution": return clampi(value, 0, RESOLUTIONS.size() - 1)
		"fps_limit": return value if FRAME_CAPS.has(value) else 0
		"volume": return clampi(value, 0, 100)
		"mouse_sensitivity": return clampf(value, 0.2, 3.0)
		"stick_deadzone": return clampf(value, 0.1, 0.4)
		"trigger_deadzone": return clampf(value, 0.05, 0.5)
	return value

static func get_value(key: String) -> Variant:
	ensure_loaded()
	return values[key]

static func set_value(key: String, value: Variant) -> void:
	ensure_loaded()
	if not DEFAULTS.has(key):
		return
	values[key] = _validated(key, value)
	apply(key)
	store()

static func store() -> void:
	if _isolated_probe_required():
		return
	var file := ConfigFile.new()
	file.load(settings_path)
	for key: String in values:
		file.set_value(SECTION, key, values[key])
	file.save(settings_path)

static func restore(keys: Array[String]) -> void:
	ensure_loaded()
	for key: String in keys:
		values[key] = DEFAULTS[key]
		apply(key)
	store()

static func apply(only: String = "") -> void:
	if only.is_empty() or only == "fps_limit":
		Engine.max_fps = int(values.fps_limit)
	if only.is_empty() or only == "volume":
		var master: int = AudioServer.get_bus_index("Master")
		if master >= 0:
			AudioServer.set_bus_mute(master, int(values.volume) == 0)
			AudioServer.set_bus_volume_db(master, linear_to_db(maxf(0.001, float(values.volume) / 100.0)))
	if only.is_empty() or only == "stick_deadzone" or only == "trigger_deadzone":
		for action: StringName in [&"move_left", &"move_right", &"move_up", &"move_down", &"aim_left", &"aim_right", &"aim_up", &"aim_down"]:
			InputMap.action_set_deadzone(action, float(values.stick_deadzone))
		for action: StringName in [&"aim", &"fire"]:
			InputMap.action_set_deadzone(action, float(values.trigger_deadzone))
	if DisplayServer.get_name() == "headless":
		return
	if only.is_empty() or only == "vsync":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if values.vsync else DisplayServer.VSYNC_DISABLED)
	if only.is_empty() or only == "window_mode" or only == "resolution":
		DisplayServer.window_set_mode(WINDOW_MODES[int(values.window_mode)])
		if int(values.window_mode) == 0:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			var available: Rect2i = DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
			var requested: Vector2i = RESOLUTIONS[int(values.resolution)]
			var fitted: Vector2i = requested.min(available.size - Vector2i(32, 64))
			DisplayServer.window_set_size(fitted)
			DisplayServer.window_set_position(available.position + (available.size - fitted) / 2)
