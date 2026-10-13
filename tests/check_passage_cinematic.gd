extends SceneTree
## The door and gate cinematics, measured on the figure's own bones: the palm
## is on the handle when the push begins, each leaf stays on the palm that
## pushes it, nothing opens before it is pushed, the body never passes through
## a leaf, and Dylan is through the opening when the picture goes black.
const TRANSITION := preload("res://systems/interaction/door_transition.gd")
## Bones that must stay on the near side of every leaf they stand in front of.
const BODY: Array[String] = ["Hips", "Spine2", "Head", "LeftShoulder", "RightShoulder", "LeftArm", "RightArm", "LeftUpLeg", "RightUpLeg", "LeftLeg", "RightLeg", "LeftFoot", "RightFoot"]
## Half the thickness of the thickest part of a limb around its bone.
const BODY_RADIUS := 0.09
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		print("FAIL: ", message)

## How far a point is in front of a leaf's hinge plane (negative: through it),
## and where along the leaf it stands; outside the leaf's length it is clear.
func clearance(leaf, at: Vector3, length: float) -> float:
	var along_axis := Vector2(leaf.reach * cos(leaf.angle), -sin(leaf.angle))
	var normal := Vector2(leaf.reach * sin(leaf.angle), cos(leaf.angle))
	var offset := Vector2(at.x - leaf.pivot.position.x, at.z - leaf.pivot.position.z)
	var along: float = offset.dot(along_axis)
	if along < 0.0 or along > length:
		return INF
	return offset.dot(normal)

func probe(passage: StringName, leaf_length: float, opens_to: float) -> void:
	var transition = TRANSITION.new()
	transition.passage = passage
	root.add_child(transition)
	await process_frame
	check(transition.animator.has_animation(TRANSITION.CROSSING) and transition.animator.current_animation == TRANSITION.CROSSING, "%s: the figure is not playing the crossing capture" % passage)
	check(is_equal_approx(transition.animator.get_animation(TRANSITION.CROSSING).length, 6.3667) or transition.animator.get_animation(TRANSITION.CROSSING).length > TRANSITION.CUT_OUT, "%s: the capture ends before the cinematic does" % passage)
	# The gesture played in the level ends where the cinematic begins.
	check(is_equal_approx(transition.animator.get_animation(&"door_interact").length, 0.72), "%s: the gameplay gesture no longer lasts the 0,72 s stage" % passage)
	transition.pose_at(TRANSITION.CUT_IN)
	var start: Vector3 = transition.bone_position("Hips")
	check(start.z > 0.2, "%s: the figure starts inside the opening: %v" % [passage, start])
	# Closed until pushed, with the hand on the handle.
	transition.pose_at(TRANSITION.PUSH)
	for leaf in transition.leaves:
		check(absf(leaf.angle) < deg_to_rad(0.5), "%s: a leaf opened before the push: %.2f°" % [passage, rad_to_deg(leaf.angle)])
	var hand: Vector3 = transition.palm(TRANSITION.RIGHT_HAND)
	check(hand.distance_to(transition.grip) < 0.05, "%s: the palm is %.3f m from the handle at the push" % [passage, hand.distance_to(transition.grip)])
	check(absf(transition.handle.rotation.z) > 0.3, "%s: the handle did not turn under the hand" % passage)
	# Step the whole cinematic the way it plays.
	transition.pose_at(TRANSITION.CUT_IN)
	var worst_gap: float = 0.0
	var worst_clearance: float = INF
	var previous: Array[float] = []
	for leaf in transition.leaves:
		previous.append(0.0)
	while transition.clock < TRANSITION.CUT_OUT:
		transition._advance(TRANSITION.STEP)
		for index: int in range(transition.leaves.size()):
			var leaf = transition.leaves[index]
			check(leaf.angle >= previous[index] - 0.0001, "%s: leaf %d swung back at %.2f s" % [passage, index, transition.clock])
			# A leaf that starts away from the palm snaps onto it in one frame.
			check(leaf.angle - previous[index] < deg_to_rad(2.5), "%s: leaf %d jumped %.1f° in one frame at %.2f s" % [passage, index, rad_to_deg(leaf.angle - previous[index]), transition.clock])
			previous[index] = leaf.angle
			for push: Dictionary in leaf.pushes:
				if push["hand"] != TRANSITION.RIGHT_HAND or transition.clock < push["from"] or transition.clock > push["to"]:
					continue
				# While the right hand pushes, the leaf's handle plane is at the palm.
				var gap: float = absf(clearance(leaf, transition.palm(push["hand"]), leaf_length) - push["offset"])
				worst_gap = maxf(worst_gap, gap)
			for bone: String in BODY:
				worst_clearance = minf(worst_clearance, clearance(leaf, transition.bone_position(bone), leaf_length))
		if failures > 6:
			break
	check(worst_gap < 0.02, "%s: the pushed leaf left the palm by %.3f m" % [passage, worst_gap])
	check(worst_clearance > BODY_RADIUS, "%s: the body comes within %.3f m of a leaf's plane" % [passage, worst_clearance])
	for leaf in transition.leaves:
		check(leaf.angle > opens_to, "%s: a leaf only opened %.1f°" % [passage, rad_to_deg(leaf.angle)])
	var through: Vector3 = transition.bone_position("Hips")
	check(through.z < -0.5, "%s: Dylan is not through the opening at the cut: %v" % [passage, through])
	print("PASSAGE %s palm_gap=%.3f body_clearance=%.3f leaves=%s hips=%v" % [passage, worst_gap, worst_clearance, str(transition.leaves.map(func(leaf) -> float: return snappedf(rad_to_deg(leaf.angle), 0.1))), through])
	transition.free()

func run() -> void:
	create_timer(60).timeout.connect(func() -> void: quit(124))
	await probe(&"door", 1.1, deg_to_rad(85.0))
	await probe(&"gate", 2.44, deg_to_rad(24.0))
	print("PASSAGE_CINEMATIC failures=%d" % failures)
	quit(1 if failures else 0)
