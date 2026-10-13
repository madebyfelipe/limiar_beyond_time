extends SceneTree
## Traditional tank steering: left/right turn on the spot, up/down drive along
## the facing, the preference survives a scene change, and the camera-relative
## scheme is untouched when it is selected.

var failures: int = 0
var ticks: int = 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		print("FAIL: ", message)

func tick(count: int = 1) -> void:
	for i: int in range(count):
		ticks += 1
		await physics_frame

func press(action: String) -> void:
	Input.action_press(action)

func release_all() -> void:
	for action: String in ["move_left", "move_right", "move_up", "move_down", "run"]:
		Input.action_release(action)

## Feet centre in metres relative to the steered body. World-space positions
## also move when an off-centre stance rotates, which is not a sideways jump.
func feet_centre(visual: Node) -> Vector2:
	var skeleton: Skeleton3D = visual.skeleton
	var total := Vector2.ZERO
	for bone: String in ["mixamorig_LeftToeBase", "mixamorig_RightToeBase"]:
		var world: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(bone)).origin
		var local: Vector3 = visual.get_parent().to_local(world)
		total += Vector2(local.x, local.z)
	return total / 2.0

## Angle between the direction the rendered body faces and the steered heading.
func skew(player: PlayerController, visual: Node) -> float:
	var skeleton: Skeleton3D = visual.skeleton
	var hips: int = skeleton.find_bone("mixamorig_Hips")
	var axis: Vector3 = skeleton.global_transform.basis * skeleton.get_bone_global_pose(hips).basis.z
	var facing: Vector3 = player.facing()
	return rad_to_deg(Vector2(axis.x, axis.z).normalized().angle_to(Vector2(facing.x, facing.z).normalized()))

func _init() -> void:
	create_timer(60).timeout.connect(func() -> void: quit(124))
	call_deferred("run")

func run() -> void:
	var exterior: Node = load("res://environments/exterior.tscn").instantiate()
	root.add_child(exterior)
	await tick(25)
	var player: PlayerController = exterior.player
	var visual: Node = player.visual.get_node("DylanVisual")
	# --- Tank mode ---
	ControlScheme.set_mode(ControlScheme.Mode.TANK)
	player.reset_to(Transform3D(Basis.IDENTITY, Vector3(0, 0.06, 20)))
	await tick(5)
	var heading: float = player.visual.rotation.y
	var origin: Vector3 = player.global_position
	var stance: Vector2 = feet_centre(visual)
	press("move_left")
	await tick(30)
	# The pivot capture must be the one matching the side being turned to.
	check(visual.locomotion == &"turn_left", "Turning left played '%s'" % visual.locomotion)
	check(visual.animator.speed_scale > 3.3, "Pivot animation lagged behind the faster turn")
	# A window cut from the middle of a captured turn starts already rotated and
	# already stepped aside. Both would show up here, as a body pointing away
	# from where it is steered and as feet landing somewhere else.
	check(skew(player, visual) < 15.0, "Pivot points the body %.1f deg away from its heading" % skew(player, visual))
	check(stance.distance_to(feet_centre(visual)) < 0.15, "Pivot shifted the stance by %.2f m" % stance.distance_to(feet_centre(visual)))
	release_all()
	await tick(6)
	var turned: float = angle_difference(heading, player.visual.rotation.y)
	check(absf(turned - 1.5) < 0.06, "Half-second left turn should cover 1.5 rad: %f rad" % turned)
	check(origin.distance_to(player.global_position) < 0.12, "Turning in place moved the body %f m" % origin.distance_to(player.global_position))
	# Driving follows the body, not the camera.
	var facing: Vector3 = player.facing()
	origin = player.global_position
	heading = player.visual.rotation.y
	press("move_up")
	await tick(40)
	release_all()
	await tick(10)
	var travel: Vector3 = player.global_position - origin
	travel.y = 0.0
	check(travel.length() > 0.5, "Forward input did not drive Dylan: %f m" % travel.length())
	check(travel.normalized().dot(facing) > 0.96, "Dylan did not travel along his facing")
	check(absf(angle_difference(heading, player.visual.rotation.y)) < 0.05, "Driving forward rotated the body")
	# Reverse is slower than walking, goes backwards, and has its own capture.
	origin = player.global_position
	press("move_down")
	await tick(30)
	check(visual.locomotion == &"walk_back", "Reversing played '%s'" % visual.locomotion)
	release_all()
	await tick(10)
	var back: Vector3 = player.global_position - origin
	back.y = 0.0
	check(back.length() > 0.2, "Reverse did not move Dylan")
	check(back.normalized().dot(player.facing()) < -0.9, "Reverse did not go backwards")
	# And the mirrored pivot answers the other key.
	player.reset_to(Transform3D(Basis.IDENTITY, Vector3(0, 0.06, 20)))
	await tick(5)
	press("move_right")
	await tick(30)
	check(visual.locomotion == &"turn_right", "Turning right played '%s'" % visual.locomotion)
	check(absf(angle_difference(0.0, player.visual.rotation.y) + 1.5) < 0.06, "Half-second right turn should cover -1.5 rad")
	release_all()
	await tick(6)
	# --- Stopping is deliberate, not a slide ---
	player.reset_to(Transform3D(Basis.IDENTITY, Vector3(0, 0.06, 20)))
	await tick(5)
	press("move_up")
	await tick(45)
	var before_release: Vector3 = player.global_position
	release_all()
	await tick(20)
	var coast: float = before_release.distance_to(player.global_position)
	check(coast < 0.25, "Dylan skated %f m after the key was released" % coast)
	# --- Camera-relative mode is unaffected ---
	ControlScheme.set_mode(ControlScheme.Mode.CAMERA_RELATIVE)
	player.reset_to(Transform3D(Basis.IDENTITY, Vector3(0, 0.06, 20)))
	await tick(5)
	heading = player.visual.rotation.y
	origin = player.global_position
	press("move_left")
	await tick(30)
	release_all()
	await tick(6)
	check(origin.distance_to(player.global_position) > 0.5, "Camera-relative left must move, not pivot")
	# --- The preference crosses a scene change ---
	ControlScheme.set_mode(ControlScheme.Mode.TANK)
	exterior.free()
	var room: Node = load("res://environments/save_room.tscn").instantiate()
	root.add_child(room)
	await tick(25)
	check(ControlScheme.is_tank(), "Control scheme was lost when the scene changed")
	var inside: PlayerController = room.player
	var room_origin: Vector3 = inside.global_position
	press("move_right")
	await tick(25)
	release_all()
	await tick(5)
	check(room_origin.distance_to(inside.global_position) < 0.12, "Tank steering did not carry into the save room")
	ControlScheme.set_mode(ControlScheme.Mode.CAMERA_RELATIVE)
	print("TANK controls ticks=%d failures=%d" % [ticks, failures])
	quit(1 if failures > 0 else 0)
