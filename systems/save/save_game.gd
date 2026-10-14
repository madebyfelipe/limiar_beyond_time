class_name SaveGame
extends RefCounted
## Progress recorded at the guardhouse terminal. A static reader keeps it alive
## across scene changes without introducing an autoload, exactly as
## ControlScheme does for the input preference, and the file below carries it
## between sessions.
##
## The record is deliberately small: which room the player stood in, where, and
## how far the objective had got. Storing fields the game cannot restore would
## be a save that lies, so a field only appears here once something restores it.

## Bumped whenever a stored field changes meaning. A file from another format is
## ignored outright instead of being half-read into a broken game.
const FORMAT := 2
const DEFAULT_PATH := "user://save.cfg"
const PROBE_PATH := "res://.local/save_probe.cfg"
const SECTION := "progress"

## Probes run through --script and get a file of their own, so the suite never
## reads nor overwrites the save of whoever plays on this machine, and a room
## opened by a probe always starts from its documented spawn.
static var path: String = PROBE_PATH if OS.get_cmdline_args().has("--script") else DEFAULT_PATH

## NEW GAME ignores the previous terminal record for this session, while the
## file remains available to LOAD GAME until the player saves again.
static var resume_on_scene_entry: bool = true

static func has_record() -> bool:
	return not read().is_empty()

## The stored record, or an empty dictionary when there is nothing to trust:
## no file, an unreadable one, another format, or a room that no longer exists.
static func read() -> Dictionary:
	var file := ConfigFile.new()
	if file.load(path) != OK:
		return {}
	if int(file.get_value(SECTION, "format", 0)) != FORMAT:
		return {}
	var scene: String = str(file.get_value(SECTION, "scene", ""))
	if scene.is_empty() or not ResourceLoader.exists(scene):
		return {}
	return {
		"scene": scene,
		"position": file.get_value(SECTION, "position", Vector3.ZERO) as Vector3,
		"facing": float(file.get_value(SECTION, "facing", 0.0)),
		"saves": int(file.get_value(SECTION, "saves", 1)),
		"saved_at": int(file.get_value(SECTION, "saved_at", 0)),
		"stage": int(file.get_value(SECTION, "stage", MissionState.Stage.ROAD)),
		# Optional extension: existing format-2 saves restore the starter stock.
		"supplies": file.get_value(SECTION, "supplies", {}),
		"vitality": float(file.get_value(SECTION, "vitality", 100.0)),
		# Optional too: a record without it gets its rooms from the stage.
		"map": file.get_value(SECTION, "map", []),
	}

## Records where the player is standing, and how far the objective had got.
## Returns the stored record, or an empty dictionary when the file could not be
## written, so the terminal can say so instead of pretending the progress is
## safe.
static func write(scene: String, position: Vector3, facing: float, stage: int, vitality: float = 100.0) -> Dictionary:
	var record := {
		"scene": scene,
		"position": position,
		"facing": facing,
		"saves": int(read().get("saves", 0)) + 1,
		"saved_at": int(Time.get_unix_time_from_system()),
		"stage": stage,
		"supplies": SupplyStock.snapshot(),
		"vitality": clampf(vitality, 1.0, 100.0),
		"map": AreaMap.snapshot(),
	}
	var file := ConfigFile.new()
	file.set_value(SECTION, "format", FORMAT)
	for key: String in record:
		file.set_value(SECTION, key, record[key])
	if file.save(path) != OK:
		return {}
	# What is taken now is on record: a restart no longer gives it back.
	PickupStore.mark_recorded()
	return record

static func clear() -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

## Puts the player back where they saved, with the objective they had reached.
## Returns false when the scene has to use its own spawn instead: no record, or
## a record made in another room — opening that room was a deliberate start, so
## it begins from its documented beginning.
static func resume(player: PlayerController, scene: String) -> bool:
	if not resume_on_scene_entry:
		return false
	var record: Dictionary = read()
	if record.is_empty() or String(record["scene"]) != scene:
		return false
	player.reset_to(Transform3D(Basis.IDENTITY, record["position"] as Vector3))
	player.visual.rotation.y = float(record["facing"])
	MissionState.restore(int(record["stage"]))
	AreaMap.restore(record.get("map", []))
	SupplyStock.restore(record.get("supplies", {}))
	PickupStore.mark_recorded()
	player.restore_vitality(float(record.get("vitality", 100.0)))
	return true

## "11/10/2026 14:03", in local time, for the terminal to show.
static func stamp(record: Dictionary) -> String:
	var when: Dictionary = Time.get_datetime_dict_from_unix_time(int(record.get("saved_at", 0)) + int(Time.get_time_zone_from_system().get("bias", 0)) * 60)
	return "%02d/%02d/%04d %02d:%02d" % [when["day"], when["month"], when["year"], when["hour"], when["minute"]]
