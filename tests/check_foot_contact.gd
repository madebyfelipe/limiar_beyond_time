extends SceneTree
## A planted foot must stand still on the ground while the body travels. If the
## clip runs slower than the configured speed the foot skates forward, which is
## what this probe measures, walking and running, through the real controller.

var failures: int = 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		print("FAIL: ", message)

func tick(count: int = 1) -> void:
	for i: int in range(count):
		await physics_frame

func _init() -> void:
	create_timer(60).timeout.connect(func() -> void: quit(124))
	call_deferred("run")

## Median horizontal speed of whichever foot is on the ground, in m/s.
func sample(player: PlayerController, visual: Node, frames: int) -> float:
	var skeleton: Skeleton3D = visual.skeleton
	var toes: Array[int] = [skeleton.find_bone("mixamorig_LeftToeBase"), skeleton.find_bone("mixamorig_RightToeBase")]
	var previous: Dictionary = {}
	var speeds: Array[float] = []
	var delta: float = 1.0 / float(Engine.physics_ticks_per_second)
	for frame: int in range(frames):
		await tick()
		var lowest: int = -1
		var lowest_y: float = INF
		var positions: Dictionary = {}
		for bone: int in toes:
			var world: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(bone).origin
			positions[bone] = world
			if world.y < lowest_y:
				lowest_y = world.y
				lowest = bone
		# Only judge the foot that is down and carrying weight, and only while the
		# body runs free: sliding along a wall points travel away from the facing,
		# and no locomotion cycle can keep contact through that.
		if previous.has(lowest) and lowest_y < 0.12 and not player.is_on_wall():
			var travel: Vector3 = positions[lowest] - previous[lowest]
			speeds.append(Vector2(travel.x, travel.z).length() / delta)
		previous = positions
	speeds.sort()
	return speeds[speeds.size() / 2] if not speeds.is_empty() else -1.0

func run() -> void:
	var exterior: Node = load("res://environments/exterior.tscn").instantiate()
	root.add_child(exterior)
	await tick(25)
	var player: PlayerController = exterior.player
	var visual: Node = player.visual.get_node("DylanVisual")
	# Tank steering drives straight along the facing, which keeps the run on the
	# open road. The cadence being measured is shared by both schemes.
	ControlScheme.set_mode(ControlScheme.Mode.TANK)
	player.reset_to(Transform3D(Basis.IDENTITY, Vector3(0, 0.06, 24)))
	await tick(5)
	Input.action_press("move_up")
	await tick(30)
	check(not player.is_on_wall(), "Probe drove Dylan into a wall before sampling")
	var walking: float = await sample(player, visual, 90)
	var walk_speed: float = Vector2(player.get_real_velocity().x, player.get_real_velocity().z).length()
	Input.action_press("run")
	await tick(40)
	var running: float = await sample(player, visual, 60)
	var run_speed: float = Vector2(player.get_real_velocity().x, player.get_real_velocity().z).length()
	Input.action_release("move_up")
	Input.action_release("run")
	ControlScheme.set_mode(ControlScheme.Mode.CAMERA_RELATIVE)
	# A perfectly matched cycle leaves the contact foot still; the tolerance
	# covers the frames where weight transfers between the feet.
	check(walking >= 0.0 and walking < 0.45, "Foot skates while walking: %.2f m/s under a body at %.2f m/s" % [walking, walk_speed])
	check(running >= 0.0 and running < 0.75, "Foot skates while running: %.2f m/s under a body at %.2f m/s" % [running, run_speed])
	print("FOOT contact walk=%.2f m/s (body %.2f) run=%.2f m/s (body %.2f) failures=%d" % [walking, walk_speed, running, run_speed, failures])
	quit(1 if failures > 0 else 0)
