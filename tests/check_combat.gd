extends SceneTree
## Weapons on the firing range: the tank scheme's Resident Evil auto-aim and
## the modern scheme's three aim modes, shots as 3D rays that walls stop,
## damage and death, reloading from the real stock, the stance that puts the
## gun where the shot goes, and the gameplay page that picks all of it.

var failures: int = 0
var ticks: int = 0
var range_scene: Node
var player: PlayerController
var weapon: PlayerWeapon
var targets: Dictionary

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		print("FAIL: ", message)

func tick(count: int = 1) -> void:
	for i: int in range(count):
		ticks += 1
		await physics_frame

func release_all() -> void:
	for action: String in ["move_left", "move_right", "move_up", "move_down", "run", "aim", "fire", "reload", "next_target"]:
		Input.action_release(action)

## One press of an action. A scripted press reads as "just pressed" only on
## the physics frame after it, so the tap waits that frame out before the next
## one, or two taps in a row would land on the same frame and count as one.
func tap(action: String) -> void:
	Input.action_press(action)
	await tick()
	Input.action_release(action)
	await tick(2)

func board(id: StringName) -> PracticeTarget:
	return targets[id]

func yaw_to(point: Vector3) -> float:
	return AimSolver.yaw_of(point - weapon.muzzle())

func fresh(scheme: ControlScheme.Mode) -> void:
	release_all()
	await tick(2)
	ControlScheme.set_mode(scheme)
	range_scene.restart()
	weapon.practice = true
	weapon.pointer_override = null
	weapon.free_motion_override = null
	player.camera = range_scene.camera
	await tick(3)

func _init() -> void:
	create_timer(120).timeout.connect(func() -> void: quit(124))
	call_deferred("run")

func run() -> void:
	range_scene = load("res://environments/firing_range.tscn").instantiate()
	root.add_child(range_scene)
	await tick(10)
	player = range_scene.player
	weapon = player.weapon
	targets = range_scene.targets
	check(weapon != null, "Dylan has no weapon node")
	# The range uses the 1,8 m Dylan of the levels; shots leave from his chest,
	# not from the head height of the 2,4 m study rig.
	var capsule: CapsuleShape3D = (player.get_node(^"Collision") as CollisionShape3D).shape
	check(is_equal_approx(capsule.height, 1.8), "The range does not use the 1,8 m Dylan")
	check(absf(weapon.muzzle_height - PlayerWeapon.CHEST_FRACTION * capsule.height) < 0.001, "Shots leave from %.2f m on a %.1f m body" % [weapon.muzzle_height, capsule.height])
	var origin: Vector3 = weapon.muzzle()
	# The fixture's premise: the hidden board is the nearest of all.
	for id: StringName in [&"low", &"left", &"far"]:
		check(origin.distance_to(board(&"hidden").hurtbox.aim_point()) < origin.distance_to(board(id).hurtbox.aim_point()), "Fixture: hidden is not nearer than %s" % id)

	# --- No gun, no aiming ---
	await fresh(ControlScheme.Mode.TANK)
	weapon.practice = false
	SupplyStock.weapon = false
	Input.action_press("aim")
	await tick(5)
	check(not weapon.aiming, "Dylan raised a gun he does not own")
	release_all()
	weapon.practice = true

	# --- Tank: auto-aim takes the nearest board in sight, never the one behind the wall ---
	AimSettings.tank_auto_target = true
	await fresh(ControlScheme.Mode.TANK)
	var start: Vector3 = player.global_position
	Input.action_press("aim")
	await tick()
	check(weapon.aiming, "Aim did not raise the gun")
	check(weapon.target == board(&"low").hurtbox, "Auto-aim picked %s instead of the nearest visible board" % (weapon.target.get_parent().name if weapon.target else "nothing"))
	check(not weapon.can_see(board(&"hidden").hurtbox), "The cover wall does not block the hidden board")
	Input.action_press("move_up")
	await tick(40)
	check(player.global_position.distance_to(start) < 0.05, "A raised gun did not plant the feet: moved %.3f m" % player.global_position.distance_to(start))
	Input.action_release("move_up")
	await tick(30)
	var off: float = absf(angle_difference(player.visual.rotation.y, yaw_to(board(&"low").hurtbox.aim_point())))
	check(off < 0.02, "Body did not turn onto the locked board: %.3f rad off" % off)
	# The lock survived the up key only because tilting drops it; re-acquire.
	await tap("next_target")
	var order: Array = []
	for i: int in range(4):
		order.append(weapon.target.get_parent().name if weapon.target else "none")
		await tap("next_target")
	print("COMBAT cycle=", order)
	check(order.has("Left") and order.has("Far") and order.has("Low"), "Next target did not visit every visible board: %s" % [order])
	check(not order.has("Hidden"), "Next target reached the board behind the wall")

	# --- Firing: four 25-point hits drop a 100-point board, and the gun moves on ---
	await fresh(ControlScheme.Mode.TANK)
	Input.action_press("aim")
	await tick(30)
	check(weapon.target == board(&"low").hurtbox, "Lost the lock before firing")
	var loaded: int = PlayerWeapon.magazine
	for shot: int in range(4):
		Input.action_press("fire")
		await tick()
		Input.action_release("fire")
		await tick(22)
	check(PlayerWeapon.magazine == loaded - 4, "Four shots took %d rounds" % (loaded - PlayerWeapon.magazine))
	check(not board(&"low").health.alive(), "Four hits did not drop the board: %.0f left" % board(&"low").health.current)
	check(not weapon.visible_targets().has(board(&"low").hurtbox), "A downed board still draws the aim")
	await tick()
	check(weapon.target != null and weapon.target != board(&"low").hurtbox, "The gun did not move on to the next board in sight")
	var cooldown_test: int = PlayerWeapon.magazine
	weapon.fire()
	weapon.fire()
	check(PlayerWeapon.magazine == cooldown_test - 1, "Two trigger pulls in one frame fired twice")
	release_all()

	# --- The wall stops the shot, not the art ---
	AimSettings.tank_auto_target = false
	await fresh(ControlScheme.Mode.TANK)
	player.visual.rotation.y = yaw_to(board(&"hidden").hurtbox.aim_point())
	Input.action_press("aim")
	await tick(2)
	check(weapon.target == null, "Auto-aim locked with auto-target off")
	var hidden_health: float = board(&"hidden").health.current
	check(weapon.fire(), "Could not fire at the wall")
	check(weapon.last_shot.get("collider") is StaticBody3D, "The shot at the covered board was not stopped by the wall")
	check(board(&"hidden").health.current == hidden_health, "A shot went through the cover wall")
	# Up/down tilt the gun, RE style.
	Input.action_press("move_up")
	await tick(2)
	check(is_equal_approx(weapon.pitch, PlayerWeapon.TANK_TILT) and weapon.shot_direction().y > 0.3, "Up did not tilt the gun up")
	release_all()
	# Turning by hand drops the lock and turns at the tank rate.
	AimSettings.tank_auto_target = true
	await fresh(ControlScheme.Mode.TANK)
	Input.action_press("aim")
	await tick()
	var locked_heading: float = weapon.heading
	Input.action_press("move_left")
	await tick(30)
	check(weapon.target == null, "Turning by hand kept the lock")
	var turned: float = angle_difference(locked_heading, weapon.heading)
	check(absf(turned - player.config.tank_turn_speed * 30.0 / 60.0) < 0.05, "Hand turn moved %.3f rad, expected %.3f" % [turned, player.config.tank_turn_speed * 0.5])
	release_all()

	# --- Reloading draws on the real stock ---
	await fresh(ControlScheme.Mode.TANK)
	weapon.practice = false
	SupplyStock.weapon = true
	SupplyStock.ammo = 5
	PlayerWeapon.magazine = 0
	Input.action_press("aim")
	await tick()
	check(not weapon.fire(), "An empty gun fired")
	check(weapon.is_reloading(), "Pulling the trigger on empty did not reload")
	await tick(int(weapon.definition.reload_time * 60.0) + 2)
	check(PlayerWeapon.magazine == 5 and SupplyStock.ammo == 0, "Reload gave %d rounds and left %d in stock" % [PlayerWeapon.magazine, SupplyStock.ammo])
	for i: int in range(5):
		weapon.fire()
		await tick(22)
	check(PlayerWeapon.magazine == 0 and not weapon.reload() and not weapon.is_reloading(), "Reloaded with nothing left in stock")
	SupplyStock.reset()
	weapon.practice = true
	release_all()

	# --- The stance points the gun where the shot goes ---
	await fresh(ControlScheme.Mode.TANK)
	Input.action_press("aim")
	await tick(40)
	var visual: Node = player.visual.get_node("DylanVisual")
	var skeleton: Skeleton3D = visual.skeleton
	# Modifier results only exist right after the stance has been applied, so the
	# arm is read there and not from a later, already restored, pose.
	var arm: Array[Vector3] = []
	# Filled in place: a lambda captures locals by value, so assigning a new
	# array inside it would never reach this scope.
	var read_arm := func() -> void:
		arm.clear()
		arm.append(skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("mixamorig_RightForeArm")).origin)
		arm.append(skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("mixamorig_RightHand")).origin)
	visual.aim_pose.modification_processed.connect(read_arm)
	await process_frame
	await process_frame
	visual.aim_pose.modification_processed.disconnect(read_arm)
	check(arm.size() == 2, "The skeleton never finished a pose")
	var arm_error: float = rad_to_deg((arm[1] - arm[0]).angle_to(weapon.shot_direction())) if arm.size() == 2 else 180.0
	print("COMBAT forearm_vs_shot_deg=%.2f" % arm_error)
	check(arm_error < 12.0, "The right forearm points %.1f deg away from the shot" % arm_error)
	check(visual.pistol.visible, "No pistol in Dylan's hand while aiming")
	release_all()
	await tick(30)
	check(not visual.pistol.visible and visual.aim_pose.influence == 0.0, "The stance stayed on after lowering the gun")

	# --- Modern, cursor on the floor: aims at what is under the mouse ---
	AimSettings.modern = AimSettings.Modern.CURSOR
	await fresh(ControlScheme.Mode.CAMERA_RELATIVE)
	var camera: Camera3D = range_scene.camera
	weapon.pointer_override = camera.unproject_position(board(&"left").hurtbox.aim_point())
	Input.action_press("aim")
	await tick(30)
	off = absf(angle_difference(weapon.heading, yaw_to(board(&"left").hurtbox.aim_point())))
	check(off < 0.01, "Cursor over a board aimed %.3f rad away from it" % off)
	check(weapon.fire() and weapon.last_shot.get("collider") == board(&"left").hurtbox, "Cursor over a board did not hit it")
	var floor_point := Vector3(-5.0, player.global_position.y, 0.0)
	weapon.pointer_override = camera.unproject_position(floor_point)
	await tick(30)
	var to_floor: Vector3 = floor_point - player.global_position
	off = absf(angle_difference(weapon.heading, AimSolver.yaw_of(to_floor)))
	check(off < 0.01, "Cursor on the floor aimed %.3f rad away from that spot" % off)
	# Strafing: the legs follow the keys, the body keeps facing the spot.
	floor_point = Vector3(0.0, player.global_position.y, -11.0)
	weapon.pointer_override = camera.unproject_position(floor_point)
	await tick(20)
	var cursor_heading: float = weapon.heading
	Input.action_press("move_right")
	await tick(40)
	var velocity := Vector3(player.velocity.x, 0.0, player.velocity.z)
	var expected_speed: float = player.config.walk_speed * player.config.aim_move_factor
	check(absf(velocity.length() - expected_speed) < 0.05, "Aimed walk ran at %.2f m/s, expected %.2f" % [velocity.length(), expected_speed])
	check(absf(velocity.normalized().dot(player.facing())) < 0.25, "Strafing turned the body into the walk")
	off = absf(angle_difference(player.visual.rotation.y, AimSolver.yaw_of(floor_point - player.global_position)))
	check(off < 0.03, "The body did not keep facing the cursor while strafing: %.3f rad" % off)
	check(absf(angle_difference(cursor_heading, weapon.heading)) > 0.05, "Cursor heading should swing as Dylan passes the spot")
	release_all()

	# --- Modern, free 360: the heading belongs to Dylan, not to the screen ---
	AimSettings.modern = AimSettings.Modern.FREE
	await fresh(ControlScheme.Mode.CAMERA_RELATIVE)
	weapon.free_motion_override = Vector2.ZERO
	Input.action_press("aim")
	await tick(5)
	var free_heading: float = weapon.heading
	Input.action_press("move_right")
	await tick(40)
	Input.action_release("move_right")
	check(absf(angle_difference(free_heading, weapon.heading)) < 0.0001, "A still mouse let the free heading drift while walking")
	# A camera cut does not move the gun either.
	var side_camera := Camera3D.new()
	range_scene.world.add_child(side_camera)
	side_camera.position = Vector3(9.0, 6.0, -2.0)
	side_camera.look_at(Vector3(0.0, 0.0, -2.0))
	player.camera = side_camera
	await tick(5)
	check(absf(angle_difference(free_heading, weapon.heading)) < 0.0001, "A camera cut moved the free aim")
	player.camera = camera
	await tick()
	# Seen from behind, a mouse movement to the right swings the gun clockwise.
	weapon.free_motion_override = Vector2(160.0, 0.0)
	await tick(3)
	weapon.free_motion_override = Vector2.ZERO
	check(angle_difference(free_heading, weapon.heading) < -0.3, "Mouse right did not swing the free aim clockwise: %.3f" % angle_difference(free_heading, weapon.heading))
	side_camera.queue_free()
	release_all()

	# --- Modern, assisted: near misses are pulled onto the board ---
	AimSettings.modern = AimSettings.Modern.ASSISTED
	await fresh(ControlScheme.Mode.CAMERA_RELATIVE)
	var left_feet: Vector3 = board(&"left").global_position
	var near_miss: Vector3 = player.global_position + (left_feet - player.global_position).rotated(Vector3.UP, 0.15)
	weapon.pointer_override = camera.unproject_position(Vector3(near_miss.x, player.global_position.y, near_miss.z))
	Input.action_press("aim")
	await tick(30)
	check(weapon.target == board(&"left").hurtbox, "Assisted aim did not pull a near miss onto the board")
	check(weapon.fire() and weapon.last_shot.get("collider") == board(&"left").hurtbox, "The assisted shot missed")
	var wide: Vector3 = player.global_position + (left_feet - player.global_position).rotated(Vector3.UP, 0.7)
	weapon.pointer_override = camera.unproject_position(Vector3(wide.x, player.global_position.y, wide.z))
	await tick(5)
	check(weapon.target == null, "Assisted aim grabbed a board 40 degrees off the cursor")
	release_all()

	# --- Losing control lowers the gun ---
	await fresh(ControlScheme.Mode.TANK)
	Input.action_press("aim")
	await tick(2)
	player.set_control_enabled(false)
	await tick(2)
	check(not weapon.aiming, "The gun stayed up with control taken away")
	player.set_control_enabled(true)
	release_all()

	# --- Readout, menu, and settings that a probe must not write ---
	await tick(2)
	var readout: WeaponReadout = range_scene.operation.weapon_readout
	check(readout != null and readout.visible and readout.text.contains(str(PlayerWeapon.magazine)), "The weapon readout does not show the magazine")
	var stored_before: String = FileAccess.get_file_as_string("user://settings.cfg") if FileAccess.file_exists("user://settings.cfg") else "<none>"
	var menu: PauseMenu = range_scene.operation.pause_menu
	menu.open()
	menu.gameplay_button.pressed.emit()
	check(menu._is_gameplay_page_open(), "The gameplay page did not open")
	var seen: Array = []
	for i: int in range(3):
		seen.append(AimSettings.modern)
		menu.modern_aim_button.pressed.emit()
	check(seen.size() == 3 and seen[0] != seen[1] and seen[1] != seen[2] and seen[0] != seen[2], "The aim row did not offer all three modern modes: %s" % [seen])
	check(AimSettings.modern == seen[0], "The aim row did not wrap around")
	var auto: bool = AimSettings.tank_auto_target
	menu.tank_aim_button.pressed.emit()
	check(AimSettings.tank_auto_target != auto, "The auto-target row did nothing")
	var scheme: int = ControlScheme.mode
	menu.scheme_button.pressed.emit()
	check(ControlScheme.mode != scheme, "The control row did nothing")
	menu._close_gameplay_page()
	check(not menu._is_gameplay_page_open() and menu.gameplay_button.has_focus(), "Back did not return to the main page")
	menu.close()
	var stored_after: String = FileAccess.get_file_as_string("user://settings.cfg") if FileAccess.file_exists("user://settings.cfg") else "<none>"
	check(stored_before == stored_after, "A probe changed the player's stored settings")
	ControlScheme.set_mode(ControlScheme.Mode.CAMERA_RELATIVE)
	print("COMBAT ticks=%d failures=%d" % [ticks, failures])
	quit(0 if failures == 0 else 1)
