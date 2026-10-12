extends SceneTree
## Basic operation carried into the authored levels: Esc opens the pause menu
## instead of quitting, F3 shows the readout, the fall net returns the actor to
## firm ground, and the Fase 1 objective advances through the gate, the door and
## the terminal, surviving a session.

const EXTERIOR := "res://environments/exterior.tscn"
const ROOM := "res://environments/save_room.tscn"
var failures: int = 0
var ticks: int = 0

func _init() -> void:
	create_timer(120).timeout.connect(func() -> void: quit(124))
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

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = false
	Input.parse_input_event(event)

func open(path: String) -> Node:
	var scene: Node = load(path).instantiate()
	root.add_child(scene)
	await tick(20)
	return scene

func run() -> void:
	SaveGame.clear()
	MissionState.reset()
	ControlScheme.set_mode(ControlScheme.Mode.CAMERA_RELATIVE)

	# --- Exterior: the operation layer ---
	var scene: Node = await open(EXTERIOR)
	var player: PlayerController = scene.player
	var operation: LevelOperation = scene.operation
	check(operation != null and operation.pause_menu != null, "The exterior has no operation layer")
	check(not operation.pause_menu.visible and not paused, "The level opened already paused")
	# Esc used to quit outright; it must open the menu now.
	key(KEY_ESCAPE)
	await tick(3)
	check(paused, "Esc did not pause the exterior")
	check(operation.pause_menu.visible, "Esc did not show the pause menu")
	check(operation.pause_menu.resume_button.has_focus(), "The pause menu opened without focus on Continuar")
	# Paused means paused: held input must not move the actor.
	var held: Vector3 = player.global_position
	Input.action_press("move_up")
	await tick(20)
	check(player.global_position.distance_to(held) < 0.001, "The actor moved %.3f m while paused" % player.global_position.distance_to(held))
	Input.action_release("move_up")
	key(KEY_ESCAPE)
	await tick(3)
	check(not paused and not operation.pause_menu.visible, "Esc did not close the pause menu")
	# F3 readout.
	check(not operation.diagnostics.visible, "The readout started visible")
	key(KEY_F3)
	await tick(3)
	check(operation.diagnostics.visible, "F3 did not show the readout")
	check(operation.diagnostics.label.text.contains("exterior_"), "The readout does not name the active shot")
	key(KEY_F3)
	await tick(3)
	check(not operation.diagnostics.visible, "F3 did not hide the readout")
	# Focus loss still pauses in a real window; probes run with it off.
	operation.pause_menu.pause_on_focus_loss = true
	root.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	await tick(3)
	check(paused and operation.pause_menu.visible, "Losing focus did not pause the exterior")
	operation.pause_menu.close()
	operation.pause_menu.pause_on_focus_loss = false
	await tick(3)

	# --- Exterior: the fall safety net ---
	player.reset_to(Transform3D(Basis.IDENTITY, Vector3(0, 0.06, 18)))
	await tick(12)
	var firm: Vector3 = player.global_position
	check(operation.last_safe.origin.distance_to(firm) < 0.2, "The net did not record firm ground")
	player.global_position = Vector3(0, -40, 18)
	await tick(6)
	check(player.global_position.distance_to(firm) < 0.4, "The net left the actor at %v instead of %v" % [player.global_position, firm])
	check(operation.notice.visible, "Recovery gave the player no notice")

	# --- Exterior: the Fase 1 objective ---
	check(MissionState.stage == MissionState.Stage.ROAD, "The run did not start on the road")
	check(scene.instructions.text.contains(MissionState.objective()), "The key list does not carry the objective")
	player.reset_to(Transform3D(Basis.IDENTITY, Vector3(0, 0.06, 8)))
	await tick(6)
	check(MissionState.stage == MissionState.Stage.YARD, "Passing the gate did not advance the objective")
	check(scene.instructions.text.contains(MissionState.objective()), "The advanced objective did not reach the key list")
	# Walking back north must not undo an objective already seen.
	player.reset_to(Transform3D(Basis.IDENTITY, Vector3(0, 0.06, 20)))
	await tick(6)
	check(MissionState.stage == MissionState.Stage.YARD, "Walking back out of the gate undid the objective")
	# Restart is a fresh attempt: actor, camera and objective.
	scene.restart()
	await tick(6)
	check(MissionState.stage == MissionState.Stage.ROAD, "Restart did not reset the objective")
	check(player.global_position.distance_to(Vector3(0, 0.06, 22)) < 0.3, "Restart did not return the actor to the spawn")
	check(scene.director.current_shot == scene.shots[0], "Restart did not return the first shot")
	check(not operation.notice.visible, "Restart left a notice on screen")
	# And the menu's own Reiniciar reaches the same place.
	player.reset_to(Transform3D(Basis.IDENTITY, Vector3(0, 0.06, 8)))
	await tick(6)
	operation.pause_menu.open()
	await tick(2)
	operation.pause_menu.restart_button.pressed.emit()
	await tick(6)
	check(not paused, "Reiniciar left the game paused")
	check(MissionState.stage == MissionState.Stage.ROAD, "Reiniciar in the menu did not reset the objective")
	scene.free()

	# --- Guardhouse: arrival, saving and the record ---
	MissionState.reach(MissionState.Stage.YARD)
	var room: Node = await open(ROOM)
	check(room.operation != null, "The save room has no operation layer")
	room.arrive_from_door()
	await tick(4)
	check(MissionState.stage == MissionState.Stage.TERMINAL, "Entering the guardhouse did not advance the objective")
	check(room.label.text.contains(MissionState.objective()), "The room's key list does not carry the objective")
	room.player.reset_to(Transform3D(Basis.IDENTITY, room.TERMINAL_APPROACH + Vector3.UP * 0.06))
	await tick(6)
	room.terminal.interact()
	check(paused and room.terminal.menu.visible, "E did not open the terminal menu")
	check(not SaveGame.has_record(), "Opening the terminal saved without confirmation")
	room.terminal.menu.execute_command("save")
	room.terminal.menu.close()
	await tick(4)
	check(MissionState.stage == MissionState.Stage.DONE, "Saving did not close the objective")
	var record: Dictionary = SaveGame.read()
	check(int(record.get("stage", -1)) == MissionState.Stage.DONE, "The record stored stage %s" % record.get("stage", "none"))
	# Esc pauses here too, rather than quitting.
	key(KEY_ESCAPE)
	await tick(3)
	check(paused and room.operation.pause_menu.visible, "Esc did not pause the save room")
	room.operation.pause_menu.close()
	await tick(3)
	room.free()

	# --- A new session resumes the objective, not only the position ---
	MissionState.reset()
	room = await open(ROOM)
	check(room.resumed, "The room did not resume from the record")
	check(MissionState.stage == MissionState.Stage.DONE, "A resumed session restarted the objective")
	# Restart inside the room is a fresh attempt and leaves the record alone.
	room.restart()
	await tick(4)
	check(MissionState.stage == MissionState.Stage.ROAD, "Restart did not reset the objective in the room")
	check(int(SaveGame.read().get("stage", -1)) == MissionState.Stage.DONE, "Restart erased the stored progress")
	room.free()

	SaveGame.clear()
	MissionState.reset()
	print("OPERATION levels ticks=%d failures=%d" % [ticks, failures])
	quit(1 if failures > 0 else 0)
