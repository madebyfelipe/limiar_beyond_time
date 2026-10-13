extends SceneTree
## Weapons on the firing range: the tank scheme's Resident Evil auto-aim and
## the modern scheme's four aim modes, shots as 3D rays that walls stop,
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
	for action: String in ["move_left", "move_right", "move_up", "move_down", "run", "aim", "fire", "reload", "next_target", "lock_next_target", "lock_previous_target"]:
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

func wheel(button: MouseButton) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	Input.parse_input_event(event)
	await tick(2)
	event = InputEventMouseButton.new()
	event.button_index = button
	event.pressed = false
	Input.parse_input_event(event)
	await tick(2)

func capture_locked(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://.local")
	check(root.get_texture().get_image().save_png("res://.local/lock-%s.png" % name) == OK, "Lock capture failed")

func check_laser() -> void:
	AimSettings.tank_auto_target = true
	await fresh(ControlScheme.Mode.TANK)
	check(weapon.laser_trace().is_empty(), "Lowered gun projected a laser")
	Input.action_press("aim")
	await tick(30)
	var trace: Dictionary = weapon.laser_trace()
	check(not trace.is_empty(), "Raised gun has no laser")
	if trace.is_empty():
		return
	check((trace.start as Vector3).distance_to(weapon.muzzle_marker.global_position) < 0.001, "Laser did not start at the gun tip")
	check(trace.hit.get("collider") == board(&"low").hurtbox, "Laser missed the selected board")
	weapon._draw_marker()
	check(weapon._marker_mesh.get_surface_count() == 2, "Laser must show a beam and impact dot")
	check(not weapon._laser_material().no_depth_test, "Laser can render through cover")
	await capture_locked("laser-target")
	trace = weapon.laser_trace()
	check(weapon.fire(), "Laser comparison shot failed")
	check((trace.end as Vector3).distance_to(weapon.last_shot.end) < 0.025, "Laser dot disagrees with the shot impact")
	check(weapon.reload(), "Laser reload check did not start reloading")
	weapon._draw_marker()
	check(weapon.laser_trace().is_empty() and weapon._marker_mesh.get_surface_count() == 0, "Reload kept the laser visible")
	weapon.interrupt_input()
	check(not weapon.aim_cursor_hidden, "Interrupted laser aim did not restore the cursor")

	AimSettings.tank_auto_target = false
	await fresh(ControlScheme.Mode.TANK)
	player.visual.rotation.y = yaw_to(board(&"hidden").hurtbox.aim_point())
	Input.action_press("aim")
	await tick(30)
	trace = weapon.laser_trace()
	check(not trace.is_empty() and trace.hit.get("collider") is StaticBody3D, "Laser crossed the cover wall")
	await capture_locked("laser-wall")
	# Model a barrel clipping through the wall; no beam may emerge behind it.
	var original_tip: Node3D = weapon.muzzle_marker
	var probe_tip := Node3D.new()
	range_scene.world.add_child(probe_tip)
	probe_tip.global_position = Vector3(0, weapon.muzzle().y, -4)
	weapon.muzzle_marker = probe_tip
	check(weapon.laser_trace().is_empty(), "A barrel through cover projected a laser behind the wall")
	# Empty air gets a beam, but never a floating impact dot.
	probe_tip.global_position = weapon.muzzle()
	weapon.pitch = PI * 0.5
	trace = weapon.laser_trace()
	check(not trace.is_empty() and trace.hit.is_empty(), "Upward laser should hit empty air")
	weapon._draw_marker()
	check(weapon._marker_mesh.get_surface_count() == 1, "Empty air displayed a false impact dot")
	weapon.muzzle_marker = original_tip
	probe_tip.free()
	weapon.interrupt_input()
	check(weapon._marker_mesh.get_surface_count() == 0, "Interrupted aim left a laser on screen")

func check_locked(camera: Camera3D) -> void:
	AimSettings.modern = AimSettings.Modern.LOCKED
	await fresh(ControlScheme.Mode.CAMERA_RELATIVE)
	weapon.pointer_override = camera.unproject_position(board(&"hidden").hurtbox.aim_point())
	Input.action_press("aim")
	await tick(2)
	check(weapon.target == null, "Locked aim acquired through a wall")
	release_all()
	await tick(2)
	weapon.pointer_override = camera.unproject_position(board(&"left").hurtbox.aim_point()) + Vector2(0, 3)
	Input.action_press("aim")
	await tick(30)
	check(weapon.target == board(&"left").hurtbox, "Locked aim did not select near the mouse")
	weapon.pointer_override = camera.unproject_position(board(&"low").hurtbox.aim_point())
	await tick(4)
	check(weapon.target == board(&"left").hurtbox, "Moving the pointer replaced the lock")
	await capture_locked("selected")
	# The actual wheel bindings, including inverse cycling and wraparound.
	var order: Array[Hurtbox] = weapon.locked_candidates(camera)
	var index: int = order.find(weapon.target)
	await wheel(MOUSE_BUTTON_WHEEL_DOWN)
	check(weapon.target == order[(index + 1) % order.size()], "Wheel down did not choose the next screen target")
	await wheel(MOUSE_BUTTON_WHEEL_UP)
	check(weapon.target == board(&"left").hurtbox, "Wheel up did not reverse the selection")
	await wheel(MOUSE_BUTTON_WHEEL_UP)
	check(weapon.target == order[-1], "Wheel selection did not wrap")
	await wheel(MOUSE_BUTTON_WHEEL_DOWN)
	var at: Vector3 = board(&"left").position
	board(&"left").position.x -= 0.5
	Input.action_press("move_right")
	await tick(30)
	Input.action_release("move_right")
	check(weapon.target == board(&"left").hurtbox, "Walking lost the lock")
	check(absf(angle_difference(weapon.heading, yaw_to(board(&"left").hurtbox.aim_point()))) < 0.01, "The lock did not track a moving target")
	board(&"left").position = at
	# Cut to a view facing away: the identity and world heading survive.
	var side := Camera3D.new()
	range_scene.world.add_child(side)
	side.position = Vector3(9, 6, -2)
	side.look_at(Vector3(12, 6, -2))
	side.make_current()
	player.camera = side
	await tick(5)
	check(weapon.target == board(&"left").hurtbox, "Camera cut changed the locked target")
	check(absf(angle_difference(weapon.heading, yaw_to(board(&"left").hurtbox.aim_point()))) < 0.01, "Camera cut rotated the locked aim")
	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		var indicator: Control = range_scene.operation.frame.get_node("LockIndicator")
		check(indicator.marker_offscreen, "Offscreen target has no edge indicator")
		await capture_locked("offscreen")
	player.camera = camera
	camera.make_current()
	side.queue_free()
	# A new wall blocks the bullet while preserving selection.
	var cover: StaticBody3D = range_scene._block((weapon.muzzle() + board(&"left").hurtbox.aim_point()) * 0.5, Vector3(1.4, 3, 1.4), Color.GRAY)
	await tick(30)
	check(weapon.target == board(&"left").hurtbox and weapon.lock_blocked(), "Temporary cover released the lock or did not warn")
	var hp: float = board(&"left").health.current
	check(weapon.fire() and weapon.last_shot.get("collider") == cover, "Locked shot ignored temporary cover")
	check(board(&"left").health.current == hp, "Blocked lock damaged the target")
	await capture_locked("blocked")
	cover.queue_free()
	await tick(25)
	# Held fire stops after release and death does not select a new enemy.
	board(&"left").health.current = 1000
	var loaded: int = PlayerWeapon.magazine
	Input.action_press("fire")
	await tick(65)
	check(PlayerWeapon.magazine == loaded - 4, "Held fire did not respect the 0.32s cadence: %d shots" % (loaded - PlayerWeapon.magazine))
	Input.action_release("fire")
	await tick(30)
	check(PlayerWeapon.magazine == loaded - 4, "Released trigger kept firing")
	Input.action_press("fire")
	await tick(2)
	board(&"left").health.apply(1000)
	await tick(3)
	loaded = PlayerWeapon.magazine
	await tick(30)
	check(weapon.target == null and PlayerWeapon.magazine == loaded, "Target death replaced the lock or kept consuming ammo")
	# Holding aim/trigger through pause and control changes requires release.
	range_scene.operation.pause_menu.open()
	await tick(2)
	check(not weapon.aiming, "Pause left the locked gun raised")
	range_scene.operation.pause_menu.close()
	await tick(30)
	check(not weapon.aiming and PlayerWeapon.magazine == loaded, "Pause resumed held buttons")
	release_all()
	await fresh(ControlScheme.Mode.CAMERA_RELATIVE)
	weapon.pointer_override = camera.unproject_position(board(&"left").hurtbox.aim_point())
	Input.action_press("aim")
	await tick(2)
	player.set_control_enabled(false)
	player.set_control_enabled(true)
	await tick(3)
	check(not weapon.aiming, "A short control interruption resumed a held aim")
	release_all()
	await tick(2)
	Input.action_press("aim")
	await tick(3)
	check(weapon.target == board(&"left").hurtbox, "Release and press did not restore aiming")
	# A removed/freed target must not be dereferenced or replaced.
	var temporary := PracticeTarget.new()
	temporary.position = Vector3(-4, 0, -6)
	range_scene.world.add_child(temporary)
	await tick(2)
	weapon._set_target(temporary.hurtbox)
	temporary.queue_free()
	await tick(3)
	check(weapon.target == null, "Freed target stayed selected")
	weapon._set_target(board(&"left").hurtbox)
	board(&"left").position = Vector3(-3, 0, -60)
	await tick(2)
	check(weapon.target == null, "Out-of-range target stayed selected")
	board(&"left").position = at
	AimSettings.modern = AimSettings.Modern.CURSOR
	await tick(3)
	check(not weapon.aiming, "Changing aim mode kept the gun raised")
	release_all()
	# Existing modes retain one shot per press even with the trigger held.
	await fresh(ControlScheme.Mode.CAMERA_RELATIVE)
	weapon.pointer_override = camera.unproject_position(board(&"left").hurtbox.aim_point())
	Input.action_press("aim")
	await tick(30)
	loaded = PlayerWeapon.magazine
	Input.action_press("fire")
	await tick(65)
	check(PlayerWeapon.magazine == loaded - 1, "Held fire leaked into cursor mode")
	release_all()
	AimSettings.modern = AimSettings.Modern.LOCKED
	await fresh(ControlScheme.Mode.CAMERA_RELATIVE)
	weapon.pointer_override = Vector2(-100, -100)
	Input.action_press("aim")
	await tick(2)
	check(weapon.target == null, "Pointer outside the viewport selected a target")
	weapon.practice = false
	SupplyStock.weapon = true
	SupplyStock.ammo = 3
	PlayerWeapon.magazine = 0
	Input.action_press("fire")
	await tick(2)
	check(weapon.is_reloading(), "Held trigger on empty did not start reload")
	await tick(175)
	check(SupplyStock.ammo == 0 and PlayerWeapon.magazine == 0 and not weapon.is_reloading(), "Held fire/reload created ammo or reloaded without stock")
	release_all()
	SupplyStock.reset()
	weapon.practice = true
	# Roundtrip the actual settings file using an explicitly isolated path.
	DirAccess.make_dir_recursive_absolute("res://.local")
	AimSettings.settings_path = "res://.local/lock-settings-probe.cfg"
	var config := ConfigFile.new()
	config.set_value("other", "keep", 42)
	check(config.save(AimSettings.settings_path) == OK, "Could not create isolated aim settings")
	AimSettings.set_modern(AimSettings.Modern.LOCKED)
	AimSettings.modern = AimSettings.Modern.FREE
	AimSettings._loaded = false
	AimSettings.ensure_loaded()
	check(AimSettings.modern == AimSettings.Modern.LOCKED, "Locked option did not survive a settings reload")
	config.load(AimSettings.settings_path)
	check(config.get_value("other", "keep") == 42, "Saving aim erased another settings section")
	DirAccess.remove_absolute(AimSettings.settings_path)
	AimSettings.settings_path = AimSettings.SETTINGS_PATH
	AimSettings.modern = AimSettings.Modern.FREE
	await tick(2)

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
	await check_laser()
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
	var prop: MeshInstance3D = visual.pistol.find_child("PistolMesh", true, false) as MeshInstance3D
	check(prop != null and prop.mesh != null, "The authored pistol GLB did not reach Dylan's hand")
	check(visual.muzzle != null and weapon.muzzle_marker == visual.muzzle, "The tracer has no imported muzzle marker")
	var prop_scale: float = visual.target_height / 1.8
	check((-visual.pistol.global_basis.z).normalized().dot(weapon.shot_direction()) > 0.999, "The imported pistol faces away from the shot")
	if visual.muzzle != null:
		var tip_offset: Vector3 = visual.muzzle.global_position - visual.pistol.global_position
		check(absf(tip_offset.dot(weapon.shot_direction()) - 0.173 * prop_scale) < 0.002, "The tracer origin is not at the modeled muzzle")
	check(visual.pistol.global_position.distance_to(arm[1]) < 0.06 * prop_scale if arm.size() == 2 else false, "The pistol grip is detached from the aiming hand")
	release_all()
	await tick(30)
	check(visual.aim_pose.influence == 0.0, "The stance stayed on after lowering the gun")
	# Lowered, the gun stays in the hand instead of vanishing.
	check(visual.pistol.visible and visual.pistol.global_position.distance_to(visual.skeleton.global_transform * visual.skeleton.get_bone_global_pose(visual.skeleton.find_bone("mixamorig_RightHand")).origin) < 0.2, "The lowered gun left the hand")

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
	await check_locked(camera)
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
	for i: int in range(4):
		seen.append(AimSettings.modern)
		menu.modern_aim_button.pressed.emit()
	var unique: Dictionary = {}
	for mode: int in seen:
		unique[mode] = true
	check(unique.size() == 4 and seen.has(AimSettings.Modern.LOCKED), "The aim row did not offer all four modern modes: %s" % [seen])
	check(AimSettings.modern == seen[0], "The aim row did not wrap around")
	AimSettings.set_modern(AimSettings.Modern.LOCKED)
	menu._update_gameplay_page()
	check(menu.modern_aim_button.value.contains("TARGET LOCK") and menu.aim_help.text.to_lower().contains("wheel"), "Menu does not explain locked mouse controls")
	await capture_locked("menu")
	if DisplayServer.get_name() != "headless":
		var old_size: Vector2i = root.size
		root.size = Vector2i(1280, 960)
		await tick(4)
		await capture_locked("menu-4x3")
		root.size = old_size
		await tick(4)
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
