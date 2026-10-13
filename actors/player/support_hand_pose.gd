extends SkeletonModifier3D
## Keeps the left hand on the shotgun's forend. The long-gun captures hold a
## rifle whose handguard sits elsewhere, and the barrels turn onto the aim, so
## the captured left hand drifts off the gun. After the right hand has its
## final pose, this places the gun from it (DylanVisual._place_shotgun), turns
## the left hand palm-up under the forend with the fingers round its right
## side and the thumb along its left, and brings the arm there by two-bone IK,
## keeping the elbow in the plane the clip gave it. Loaded by preload, without
## class_name, like grip_pose.gd.

const CHAIN := [&"mixamorig_LeftArm", &"mixamorig_LeftForeArm", &"mixamorig_LeftHand"]
const KNUCKLE := &"mixamorig_LeftHandMiddle1"
const THUMB := &"mixamorig_LeftHandThumb1"

## DylanVisual, which owns the gun and says where its forend is.
var visual: Node3D
var _bones: PackedInt32Array = []
var _knuckle: int = -1
var _thumb: int = -1

func _resolve(skeleton: Skeleton3D) -> bool:
	if _bones.is_empty():
		for name: StringName in CHAIN:
			_bones.append(skeleton.find_bone(name))
		_knuckle = skeleton.find_bone(KNUCKLE)
		_thumb = skeleton.find_bone(THUMB)
	return not _bones.has(-1) and _knuckle >= 0 and _thumb >= 0

func _process_modification_with_delta(_delta: float) -> void:
	var skeleton: Skeleton3D = get_skeleton()
	if skeleton == null or visual == null or not _resolve(skeleton) or not visual.shotgun.visible:
		return
	visual._place_shotgun()
	var to_skeleton: Transform3D = skeleton.global_transform.affine_inverse() * visual.shotgun.global_transform
	var fingers: Vector3 = (to_skeleton.basis * visual.SHOTGUN_SUPPORT_FINGERS).normalized()
	var thumb_way: Vector3 = (to_skeleton.basis * visual.SHOTGUN_SUPPORT_THUMB).normalized()
	var palm: Vector3 = to_skeleton * visual.SHOTGUN_SUPPORT_PALM
	# The wrist sits a hand's length back from the palm along the fingers.
	var wrist: Vector3 = skeleton.get_bone_global_pose(_bones[2]).origin
	var hand_length: float = wrist.distance_to(skeleton.get_bone_global_pose(_knuckle).origin)
	_reach(skeleton, palm - fingers * hand_length)
	_turn_hand(skeleton, fingers, thumb_way)

## Two-bone IK of the arm onto `target`, in skeleton space.
func _reach(skeleton: Skeleton3D, target: Vector3) -> void:
	var shoulder: Vector3 = skeleton.get_bone_global_pose(_bones[0]).origin
	var elbow: Vector3 = skeleton.get_bone_global_pose(_bones[1]).origin
	var wrist: Vector3 = skeleton.get_bone_global_pose(_bones[2]).origin
	var upper: float = shoulder.distance_to(elbow)
	var lower: float = elbow.distance_to(wrist)
	var reach: Vector3 = target - shoulder
	var span: float = clampf(reach.length(), absf(upper - lower) + 0.001, upper + lower - 0.001)
	var along: Vector3 = reach.normalized()
	# The elbow stays on the side the clip bent it to.
	var bend: Vector3 = (elbow - shoulder) - along * (elbow - shoulder).dot(along)
	if bend.length() < 0.0001:
		bend = Vector3.DOWN - along * Vector3.DOWN.dot(along)
	bend = bend.normalized()
	var cosine: float = clampf((upper * upper + span * span - lower * lower) / (2.0 * upper * span), -1.0, 1.0)
	var new_elbow: Vector3 = shoulder + along * upper * cosine + bend * upper * sqrt(1.0 - cosine * cosine)
	_point(skeleton, _bones[0], _bones[1], (new_elbow - shoulder).normalized())
	var placed_elbow: Vector3 = skeleton.get_bone_global_pose(_bones[1]).origin
	_point(skeleton, _bones[1], _bones[2], (target - placed_elbow).normalized())

## Turns the hand about the wrist so the knuckles lie along `fingers` and the
## thumb root falls on the `thumb_way` side.
func _turn_hand(skeleton: Skeleton3D, fingers: Vector3, thumb_way: Vector3) -> void:
	var pose: Transform3D = skeleton.get_bone_global_pose(_bones[2])
	var now_fingers: Vector3 = skeleton.get_bone_global_pose(_knuckle).origin - pose.origin
	var now_thumb: Vector3 = skeleton.get_bone_global_pose(_thumb).origin - pose.origin
	var current: Basis = _frame(now_fingers, now_thumb)
	var wanted: Basis = _frame(fingers, thumb_way)
	if current == Basis() or wanted == Basis():
		return
	pose.basis = (wanted * current.inverse()) * pose.basis
	skeleton.set_bone_global_pose(_bones[2], pose)

## Orthonormal frame from a main axis and a side hint; identity if degenerate.
func _frame(main: Vector3, side: Vector3) -> Basis:
	var x: Vector3 = main.normalized()
	var z: Vector3 = x.cross(side).normalized()
	if x.is_zero_approx() or z.is_zero_approx():
		return Basis()
	return Basis(x, z.cross(x), z)

## Rotates one bone so its child lies along `toward`, in skeleton space.
func _point(skeleton: Skeleton3D, bone: int, child: int, toward: Vector3) -> void:
	var pose: Transform3D = skeleton.get_bone_global_pose(bone)
	var current: Vector3 = skeleton.get_bone_global_pose(child).origin - pose.origin
	if current.length() < 0.0001 or toward.is_zero_approx():
		return
	pose.basis = Basis(Quaternion(current.normalized(), toward)) * pose.basis
	skeleton.set_bone_global_pose(bone, pose)
