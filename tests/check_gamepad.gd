extends SceneTree
## Real standardized joypad events, through InputMap and the live controller,
## weapon, pause GUI and terminal. No physical controller is needed for this
## regression; USB/Bluetooth hardware still needs a manual acceptance pass.

var failures: int = 0
var saves: int = 0
var pad: Node
const TEST_DEVICE := 15

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", message)

func tick(count: int = 1) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame

func axis(id: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = TEST_DEVICE
	event.axis = id
	event.axis_value = value
	Input.parse_input_event(event)

func button(id: JoyButton, down: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = TEST_DEVICE
	event.button_index = id
	event.pressed = down
	Input.parse_input_event(event)

func tap(id: JoyButton) -> void:
	button(id, true)
	await tick(2)
	button(id, false)
	await tick(2)

func neutral() -> void:
	for id: JoyAxis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y, JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y, JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT]:
		axis(id, 0.0)
	for id: JoyButton in [JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_X, JOY_BUTTON_START, JOY_BUTTON_LEFT_STICK, JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER, JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT]:
		button(id, false)

func capture(name: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.local/gamepad-%s.png" % name)

func run() -> void:
	create_timer(120, true).timeout.connect(func() -> void: quit(124))
	pad = root.get_node("GamepadInput")
	print("Physical controllers: ", Input.get_connected_joypads())
	for id: int in Input.get_connected_joypads():
		print("Controller %d: %s" % [id, Input.get_joy_name(id)])
	# A connected physical pad can report its neutral axes during the probe.
	# Restrict only this process's bindings to a separate synthetic device.
	for action: StringName in InputMap.get_actions():
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				InputMap.action_erase_event(action, event)
				event.device = TEST_DEVICE
				InputMap.action_add_event(action, event)
	check(pad.is_playstation_name("PS4 Controller") and pad.is_playstation_name("Sony DualShock 4") and pad.is_playstation_name("Wireless Controller"), "DualShock name recognition")
	check(not pad.is_playstation_name("Xbox Series Controller"), "Xbox misidentified as PlayStation")
	var range_scene: Node = load("res://environments/firing_range.tscn").instantiate()
	root.add_child(range_scene)
	await tick(20)
	var player: PlayerController = range_scene.player
	var weapon: PlayerWeapon = player.weapon
	var menu: PauseMenu = range_scene.operation.pause_menu
	ControlScheme.set_mode(ControlScheme.Mode.CAMERA_RELATIVE)
	await tick(3)
	var origin: Vector3 = player.position
	axis(JOY_AXIS_LEFT_X, 0.12)
	axis(JOY_AXIS_LEFT_Y, 0.12)
	await tick(12)
	check(player.position.distance_to(origin) < 0.03 and not player.movement_reference.locked, "Stick drift moved player or locked camera")
	axis(JOY_AXIS_LEFT_Y, 0.0)
	axis(JOY_AXIS_LEFT_X, 0.5)
	await tick(5)
	var slow: float = Vector2(player.velocity.x, player.velocity.z).length()
	axis(JOY_AXIS_LEFT_X, 1.0)
	await tick(5)
	var walking: float = Vector2(player.velocity.x, player.velocity.z).length()
	check(slow > 0.1 and slow < walking * 0.7, "Analog movement lost proportional speed")
	var direction: Vector3 = player.desired_direction
	var camera_rotation: Vector3 = range_scene.camera.rotation
	range_scene.camera.rotation.y += 0.8
	await tick(3)
	check(player.desired_direction.dot(direction) > 0.99, "Held stick changed direction at camera cut")
	axis(JOY_AXIS_LEFT_X, 0.0)
	await tick(3)
	axis(JOY_AXIS_LEFT_X, 1.0)
	await tick(3)
	check(player.desired_direction.dot(direction) < 0.8, "New stick input ignored current camera")
	range_scene.camera.rotation = camera_rotation
	button(JOY_BUTTON_LEFT_STICK, true)
	await tick(6)
	check(Vector2(player.velocity.x, player.velocity.z).length() > walking * 1.3, "L3 did not run")
	neutral()
	await tick(8)
	check(not player.movement_reference.locked, "Neutral did not release camera reference")
	ControlScheme.set_mode(ControlScheme.Mode.TANK)
	range_scene.restart()
	await tick(5)
	origin = player.position
	button(JOY_BUTTON_DPAD_LEFT, true)
	await tick(18)
	check(player.visual.rotation.y > 0.2 and origin.distance_to(player.position) < 0.1, "D-pad did not turn tank in place")
	neutral()
	await tick(3)
	axis(JOY_AXIS_LEFT_Y, -1.0)
	await tick(20)
	check(player.position.distance_to(origin) > 0.3, "Tank stick did not move forward")
	neutral()
	AimSettings.tank_auto_target = false
	range_scene.restart()
	await tick(4)
	axis(JOY_AXIS_TRIGGER_LEFT, 1.0)
	axis(JOY_AXIS_RIGHT_X, 1.0)
	await tick(16)
	check(weapon.turn_input < -0.5 and weapon.heading < -0.2, "Right stick did not steer tank aim")
	axis(JOY_AXIS_RIGHT_X, 0.0)
	axis(JOY_AXIS_RIGHT_Y, -1.0)
	await tick(3)
	check(weapon.pitch > 0.3, "Right stick did not tilt tank gun")
	neutral()
	AimSettings.tank_auto_target = true
	await tick(4)
	# Modern aim must work in all four settings without any mouse movement.
	for mode: AimSettings.Modern in [AimSettings.Modern.FREE, AimSettings.Modern.CURSOR, AimSettings.Modern.ASSISTED, AimSettings.Modern.LOCKED]:
		ControlScheme.set_mode(ControlScheme.Mode.CAMERA_RELATIVE)
		AimSettings.modern = mode
		AimSettings.pad_target_lock = mode == AimSettings.Modern.LOCKED
		range_scene.restart()
		await tick(5)
		axis(JOY_AXIS_RIGHT_X, 1.0)
		axis(JOY_AXIS_TRIGGER_LEFT, 0.1)
		await tick(3)
		check(not weapon.aiming, "Trigger deadzone raised gun")
		axis(JOY_AXIS_TRIGGER_LEFT, 1.0)
		await tick(6)
		check(weapon.aiming and weapon.gamepad_aim, "L2 did not raise a gamepad aim")
		if mode == AimSettings.Modern.LOCKED:
			check(weapon.target != null and weapon.target != range_scene.targets[&"hidden"].hurtbox, "Pad lock missed visible target or selected through wall")
			var first: Hurtbox = weapon.target
			await tap(JOY_BUTTON_RIGHT_SHOULDER)
			check(weapon.target != first, "R1 did not cycle locked target")
			await tap(JOY_BUTTON_LEFT_SHOULDER)
			check(weapon.target == first, "L1 did not restore previous locked target")
			axis(JOY_AXIS_RIGHT_X, 0.0)
			await tick(3)
			axis(JOY_AXIS_RIGHT_X, 1.0)
			await tick(3)
			var flicked: Hurtbox = weapon.target
			check(flicked != first, "Right-stick flick did not cycle targets")
			await tick(20)
			check(weapon.target == flicked, "Held stick repeatedly cycled targets")
		else:
			check(absf(weapon.heading) > 0.3, "Right stick did not steer modern aim")
		axis(JOY_AXIS_RIGHT_X, 0.0)
		await tick(3)
		var heading: float = weapon.heading
		await tick(3)
		check(absf(angle_difference(heading, weapon.heading)) < 0.01, "Neutral aim followed idle mouse")
		var ammo: int = PlayerWeapon.magazine
		axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
		await tick(35)
		check(PlayerWeapon.magazine < ammo - 1, "Holding R2 did not fire at weapon cadence")
		axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
		await tick(3)
		await tap(JOY_BUTTON_X)
		check(weapon.is_reloading(), "Square did not reload")
		await tick(100)
		check(PlayerWeapon.magazine == weapon.definition.magazine, "Pad reload did not finish")
		# Menu releases neither trigger; resume must still require a fresh L2.
		axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
		await tick(2)
		await tap(JOY_BUTTON_START)
		check(paused and menu.visible and not weapon.aiming, "Options failed to pause/interupt gun")
		ammo = PlayerWeapon.magazine
		await tap(JOY_BUTTON_B)
		check(not paused and not menu.visible and not weapon.aiming, "Circle did not resume safely")
		check(PlayerWeapon.magazine == ammo, "Held R2 fired on resume")
		neutral()
		await tick(4)
	# Native focus navigation and cancel must work on both submenu pages.
	# Gamepad target locking is independent of the selected mouse mode.
	AimSettings.modern = AimSettings.Modern.FREE
	AimSettings.pad_target_lock = true
	range_scene.restart()
	await tick(4)
	axis(JOY_AXIS_TRIGGER_LEFT, 1.0)
	await tick(4)
	check(weapon.uses_locked_aim() and weapon.target != null, "Default pad aim depended on mouse mode")
	await tap(JOY_BUTTON_Y)
	check(player.dodge_left > 0.0 and not weapon.aiming, "Triangle/Y did not dodge and cancel targeting")
	# Past the 0,55 s escape: a kit cannot be used mid-dodge.
	await tick(36)
	check(not weapon.aiming, "Dodge re-raised a held aim trigger")
	neutral()
	await tick(4)
	Inventory.set_count(&"med_kit", 1)
	player.vitality = 40.0
	await tap(JOY_BUTTON_RIGHT_STICK)
	check(player.vitality == 90.0 and Inventory.count(&"med_kit") == 0, "R3/RS did not consume and apply a medical kit")
	await tap(JOY_BUTTON_START)
	await tap(JOY_BUTTON_DPAD_DOWN)
	await tap(JOY_BUTTON_DPAD_DOWN)
	check(menu.gameplay_button.has_focus(), "D-pad did not navigate pause")
	await tap(JOY_BUTTON_A)
	check(menu.gameplay_screen.visible and menu.scheme_button.has_focus(), "Cross did not open gameplay page")
	pad.playstation = true
	pad.changed.emit()
	check(menu.input_hints[0].text.contains("✕") and menu.aim_help.text.contains("L2"), "PS4 hints missing")
	await capture("ps4-gameplay")
	await tap(JOY_BUTTON_B)
	check(menu.screen.visible and menu.gameplay_button.has_focus(), "Circle did not return from submenu")
	await tap(JOY_BUTTON_DPAD_DOWN)
	await tap(JOY_BUTTON_A)
	check(menu.filter_screen.visible, "Pad did not open presentation page")
	await tap(JOY_BUTTON_B)
	await tap(JOY_BUTTON_START)
	axis(JOY_AXIS_LEFT_X, 1.0)
	await tick(2)
	Input.joy_connection_changed.emit(TEST_DEVICE, false)
	await tick(2)
	check(paused and menu.visible, "Disconnect did not pause")
	neutral()
	menu.close()
	range_scene.free()
	# Actual local interaction: this used to be keyboard-only input.
	var room: Node = load("res://environments/save_room.tscn").instantiate()
	root.add_child(room)
	await tick(20)
	room.player.reset_to(Transform3D(Basis.IDENTITY, room.TERMINAL_APPROACH + Vector3.UP * 0.06))
	await tick(4)
	await tap(JOY_BUTTON_A)
	var terminal: TerminalMenu = room.terminal.menu
	check(terminal.visible and paused, "Cross did not interact with terminal")
	check(terminal.input_field.text == "help", "Pad terminal did not offer command")
	await tap(JOY_BUTTON_DPAD_RIGHT)
	check(terminal.input_field.text == "save", "Pad did not select save command")
	# Exercise save dispatch without overwriting the person's stored progress.
	terminal.save_requested.disconnect(room.terminal.save_progress)
	terminal.save_requested.connect(func() -> void: saves += 1)
	await tap(JOY_BUTTON_A)
	check(saves == 1, "Cross did not dispatch save once")
	await tap(JOY_BUTTON_DPAD_RIGHT)
	await tap(JOY_BUTTON_A)
	check(terminal.output.text.contains("SUPPLIES"), "Pad did not run shop")
	await tap(JOY_BUTTON_DPAD_UP)
	check(terminal.input_field.text == "shop", "Pad did not recall history")
	axis(JOY_AXIS_LEFT_X, 0.7)
	await tick(2)
	var selected: String = terminal.input_field.text
	axis(JOY_AXIS_LEFT_X, 0.8)
	await tick(2)
	check(terminal.input_field.text == selected, "Held analog input repeatedly selected terminal commands")
	axis(JOY_AXIS_LEFT_X, 0.0)
	await tick(2)
	pad.playstation = true
	pad.changed.emit()
	await capture("ps4-terminal")
	await tap(JOY_BUTTON_B)
	check(not paused and not terminal.visible and not room.terminal.busy, "Circle did not exit terminal")
	neutral()
	var key_event := InputEventKey.new()
	key_event.physical_keycode = KEY_W
	key_event.pressed = true
	Input.parse_input_event(key_event)
	await tick(2)
	check(not pad.gamepad_active and room.terminal.prompt.text.begins_with("E"), "Keyboard did not restore prompts")
	key_event.pressed = false
	Input.parse_input_event(key_event)
	room.free()
	ControlScheme.set_mode(ControlScheme.Mode.CAMERA_RELATIVE)
	print("GAMEPAD failures=%d" % failures)
	quit(1 if failures > 0 else 0)
