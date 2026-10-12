class_name AimSettings
extends RefCounted
## How Dylan aims, chosen by the player on the gameplay page. Static and stored
## beside the control scheme, with the same rules: one value for every scene,
## read once per process, and never read or written by a probe.

## The modern (camera-relative) scheme turns the mouse into a heading in one of
## three ways. They are options rather than one design because each suits a
## different player, and the user asked for all three to be selectable.
enum Modern {
	## The system cursor stays visible; Dylan aims at the floor point under it.
	## Walking keeps the gun on that spot of the world.
	CURSOR,
	## No cursor: a reticle circles Dylan and the mouse swings it around him.
	## Walking keeps the gun pointing the same way relative to Dylan.
	FREE,
	## The cursor of CURSOR, pulled onto a visible target when it passes close.
	ASSISTED,
}

const MODERN_NAMES := {
	Modern.CURSOR: "cursor no chão",
	Modern.FREE: "livre 360",
	Modern.ASSISTED: "assistida",
}

const SETTINGS_PATH := "user://settings.cfg"
const SECTION := "aim"

static var modern: Modern = Modern.FREE
## Tank scheme: raising the gun turns Dylan to the nearest target he can see,
## as Resident Evil and Dino Crisis do. Off, the gun points where he faces.
static var tank_auto_target: bool = true
static var _loaded: bool = false

static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	if OS.get_cmdline_args().has("--script"):
		return
	var file := ConfigFile.new()
	if file.load(SETTINGS_PATH) != OK:
		return
	var stored: int = int(file.get_value(SECTION, "modern", modern))
	if MODERN_NAMES.has(stored):
		modern = stored as Modern
	tank_auto_target = bool(file.get_value(SECTION, "tank_auto_target", tank_auto_target))

static func _store() -> void:
	_loaded = true
	if OS.get_cmdline_args().has("--script"):
		return
	var file := ConfigFile.new()
	file.load(SETTINGS_PATH)
	file.set_value(SECTION, "modern", int(modern))
	file.set_value(SECTION, "tank_auto_target", tank_auto_target)
	file.save(SETTINGS_PATH)

static func set_modern(next: Modern) -> void:
	ensure_loaded()
	modern = next
	_store()

static func cycle_modern() -> Modern:
	ensure_loaded()
	set_modern(((int(modern) + 1) % MODERN_NAMES.size()) as Modern)
	return modern

static func set_tank_auto_target(value: bool) -> void:
	ensure_loaded()
	tank_auto_target = value
	_store()

static func modern_name() -> String:
	ensure_loaded()
	return MODERN_NAMES[modern]
