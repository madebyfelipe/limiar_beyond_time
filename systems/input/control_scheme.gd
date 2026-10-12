class_name ControlScheme
extends RefCounted
## Player-facing input preference, shared by every scene. A static value keeps
## it alive across scene changes without introducing an autoload, and the file
## below carries it between sessions.

enum Mode {
	## Direction follows the active camera, locked while a key is held.
	CAMERA_RELATIVE,
	## Traditional tank: left/right turn Dylan in place, up/down drive him.
	TANK,
}

const SETTINGS_PATH := "user://settings.cfg"
const SECTION := "controls"
const KEY := "scheme"

static var mode: Mode = Mode.CAMERA_RELATIVE
static var _loaded: bool = false

## Reads the stored preference once per process. Absent or unreadable settings
## leave the camera-relative default in place.
static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	# Probes run through --script and must start from the documented default
	# instead of inheriting whatever the person playing last chose.
	if OS.get_cmdline_args().has("--script"):
		return
	var file := ConfigFile.new()
	if file.load(SETTINGS_PATH) != OK:
		return
	var stored: int = int(file.get_value(SECTION, KEY, Mode.CAMERA_RELATIVE))
	if stored == Mode.TANK or stored == Mode.CAMERA_RELATIVE:
		mode = stored as Mode

static func set_mode(next: Mode) -> void:
	_loaded = true
	mode = next
	# A probe already ignores the stored value; it must not write one either, or
	# running the suite would silently change the preference of whoever plays
	# on this machine.
	if OS.get_cmdline_args().has("--script"):
		return
	var file := ConfigFile.new()
	file.load(SETTINGS_PATH)
	file.set_value(SECTION, KEY, int(mode))
	file.save(SETTINGS_PATH)

static func toggle() -> Mode:
	set_mode(Mode.CAMERA_RELATIVE if mode == Mode.TANK else Mode.TANK)
	return mode

static func is_tank() -> bool:
	return mode == Mode.TANK

## Short label for the on-screen key list.
static func label() -> String:
	return "tank" if is_tank() else "camera"
