extends SceneTree
## The guardhouse terminal records progress where the player stands, the room
## resumes from that record on the next session, and a record it cannot trust
## is ignored instead of dropping the player somewhere wrong.

const ROOM := "res://environments/save_room.tscn"
const SPAWN := Vector3(-2.4, 0.06, 0.55)
var failures: int = 0
var ticks: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		print("FAIL: ", message)

func tick(count: int = 1) -> void:
	for frame: int in range(count):
		await physics_frame
		await process_frame
		ticks += 1

func key(code: Key, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	event.echo = echo
	Input.parse_input_event(event)
	event = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = false
	Input.parse_input_event(event)

## A freshly opened room, as a new session would open it.
func open_room() -> Node:
	var scene: Node = load(ROOM).instantiate()
	root.add_child(scene)
	await tick(20)
	return scene

## Writes a record straight to the file, to stand in for one the game did not
## produce: another room, a future format, a room that has been deleted.
func store(values: Dictionary) -> void:
	var file := ConfigFile.new()
	for key_name: String in values:
		file.set_value(SaveGame.SECTION, key_name, values[key_name])
	check(file.save(SaveGame.path) == OK, "Could not write the stand-in record")

func _init() -> void:
	create_timer(90).timeout.connect(func() -> void: quit(124))

func run() -> void:
	# The suite must never read or overwrite a player's own save.
	check(SaveGame.path == SaveGame.PROBE_PATH, "Probes are pointed at the player's save file: " + SaveGame.path)
	SaveGame.clear()
	check(not SaveGame.has_record(), "A cleared save still reports a record")

	# --- Nothing stored: the room uses its own spawn ---
	var room: Node = await open_room()
	var player: PlayerController = room.player
	var terminal: TerminalInteraction = room.terminal
	check(not room.resumed, "The room claimed to resume with no record stored")
	check(player.global_position.distance_to(SPAWN) < 0.2, "Without a record the player must start at the spawn, was %v" % player.global_position)
	check(not terminal.can_interact(), "The terminal answered from the doorway")
	check(not terminal.prompt.visible, "The terminal prompt showed from the doorway")
	# Out of reach of the terminal, and of the doorway too: the spawn stands at
	# the door, where E opens it and hands control to the transition.
	player.reset_to(Transform3D(Basis.IDENTITY, Vector3(0, 0.06, 0.8)))
	await tick(6)
	check(player.global_position.distance_to(Vector3(0, 0.06, 0.8)) < 0.2, "The mid-room test spot is not standable")
	check(not terminal.can_interact(), "The terminal answered from the middle of the room")
	key(KEY_E)
	await tick(4)
	check(not SaveGame.has_record(), "E saved from outside the terminal's reach")
	check(not root.has_node("DoorTransition"), "E in the middle of the room opened the door")
	check(player.control_enabled, "The player lost control without interacting with anything")

	# --- At the terminal: E records position and facing ---
	player.reset_to(Transform3D(Basis.IDENTITY, room.TERMINAL_APPROACH + Vector3.UP * 0.06))
	player.visual.rotation.y = 0.0
	await tick(6)
	check(terminal.can_interact(), "The terminal did not answer at its approach point")
	check(terminal.prompt.visible, "The terminal prompt stayed hidden at its approach point")
	var standing: Vector3 = player.global_position
	key(KEY_E, true)
	await tick(2)
	check(not SaveGame.has_record(), "A key repeat saved the game")
	key(KEY_E)
	await tick(4)
	var record: Dictionary = SaveGame.read()
	check(terminal.menu.visible and paused, "E did not open the terminal")
	check(record.is_empty(), "Opening the menu wrote a save before SAVE")
	terminal.menu.input_field.text = "save"
	key(KEY_ENTER)
	await tick(4)
	record = SaveGame.read()
	terminal.menu.close()
	check(not record.is_empty(), "E at the terminal wrote no record")
	check(String(record.get("scene", "")) == ROOM, "The record names '%s' instead of the save room" % record.get("scene", ""))
	check((record.get("position", Vector3.ZERO) as Vector3).distance_to(standing) < 0.01, "The record stored %v instead of where the player stood, %v" % [record.get("position", Vector3.ZERO), standing])
	check(absf(float(record.get("facing", 9.0))) < 0.01, "The record stored facing %f instead of 0" % record.get("facing", 9.0))
	check(int(record.get("saves", 0)) == 1, "The first save was numbered %d" % record.get("saves", 0))
	check(int(record.get("saved_at", 0)) > 1_700_000_000, "The record carries no plausible timestamp")
	check(terminal.notice.modulate.a > 0.9, "Saving gave the player no on-screen acknowledgement")
	check(room.label.text.contains("RECORD 1"), "The room's key list does not show the stored record")
	# Saving again counts up rather than starting over.
	player.visual.rotation.y = -PI / 2
	await tick(4)
	key(KEY_E)
	await tick(4)
	record = SaveGame.read()
	terminal.menu.input_field.text = "save"
	key(KEY_ENTER)
	await tick(4)
	record = SaveGame.read()
	terminal.menu.close()
	check(int(record.get("saves", 0)) == 2, "The second save was numbered %d" % record.get("saves", 0))
	check(absf(float(record.get("facing", 0.0)) + PI / 2) < 0.01, "The second save kept the old facing")
	var saved_at: Vector3 = record.get("position", Vector3.ZERO) as Vector3
	var saved_facing: float = float(record.get("facing", 0.0))
	room.free()

	# --- A new session resumes from the record ---
	room = await open_room()
	check(room.resumed, "The room did not resume from the stored record")
	check(room.player.global_position.distance_to(saved_at) < 0.1, "Resumed at %v instead of the stored %v" % [room.player.global_position, saved_at])
	check(absf(angle_difference(room.player.visual.rotation.y, saved_facing)) < 0.02, "Resumed facing %f instead of the stored %f" % [room.player.visual.rotation.y, saved_facing])
	check(room.label.text.contains("resumed"), "A resumed session does not say so on screen")
	# Walking in through the door means standing at the door, not at the record.
	room.arrive_from_door()
	await tick(4)
	check(not room.resumed, "Arriving through the door still claimed a resume")
	check(room.player.global_position.distance_to(SPAWN) < 0.2, "Arriving through the door placed the player at %v" % room.player.global_position)
	room.free()

	# --- A record made in another room does not move this one ---
	store({"format": SaveGame.FORMAT, "scene": "res://environments/exterior.tscn", "position": Vector3(0, 0.06, 20), "facing": 0.0, "saves": 7, "saved_at": 1_760_000_000})
	check(not SaveGame.read().is_empty(), "A record for another room should still read back")
	room = await open_room()
	check(not room.resumed, "A record made outside resumed the save room")
	check(room.player.global_position.distance_to(SPAWN) < 0.2, "A record made outside moved the player to %v" % room.player.global_position)
	room.free()

	# --- Records that cannot be trusted are ignored, not half-read ---
	store({"format": SaveGame.FORMAT + 99, "scene": ROOM, "position": Vector3(0, 0.06, 0), "facing": 1.0, "saves": 3, "saved_at": 1_760_000_000})
	check(SaveGame.read().is_empty(), "A record in an unknown format was read anyway")
	store({"format": SaveGame.FORMAT, "scene": "res://environments/deleted_room.tscn", "position": Vector3.ZERO, "facing": 0.0, "saves": 3, "saved_at": 1_760_000_000})
	check(SaveGame.read().is_empty(), "A record naming a missing room was read anyway")
	room = await open_room()
	check(not room.resumed, "An untrusted record resumed the room")
	check(room.player.global_position.distance_to(SPAWN) < 0.2, "An untrusted record moved the player to %v" % room.player.global_position)
	check(room.label.text.contains("NO SAVE"), "With no trustworthy record the room should say so")
	# And the terminal overwrites it with something valid.
	room.player.reset_to(Transform3D(Basis.IDENTITY, room.TERMINAL_APPROACH + Vector3.UP * 0.06))
	await tick(6)
	key(KEY_E)
	await tick(4)
	room.terminal.menu.input_field.text = "save"
	key(KEY_ENTER)
	await tick(4)
	room.terminal.menu.close()
	check(int(SaveGame.read().get("saves", 0)) == 1, "Saving over an untrusted record did not restart the count")
	room.free()

	SaveGame.clear()
	check(not FileAccess.file_exists(SaveGame.path), "The probe left its save file behind")
	print("SAVE persistence ticks=%d failures=%d" % [ticks, failures])
	quit(1 if failures > 0 else 0)
