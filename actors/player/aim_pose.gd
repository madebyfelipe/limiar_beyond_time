class_name AimPose
extends SkeletonModifier3D
## Two-handed pistol stance laid over whatever clip the legs are playing: the
## right arm runs straight down the barrel and the left hand reaches for the
## grip. A stand-in for captured aim poses -- the Mixamo rig has no aim clips
## yet -- that still puts the gun where the shot actually goes, which is what
## check_combat measures. Blended in and out through `influence`.

const RIGHT_CHAIN := [&"mixamorig_RightArm", &"mixamorig_RightForeArm", &"mixamorig_RightHand"]
const LEFT_CHAIN := [&"mixamorig_LeftArm", &"mixamorig_LeftForeArm", &"mixamorig_LeftHand"]

## World-space direction of the shot, refreshed by DylanVisual every frame.
var direction: Vector3 = Vector3.FORWARD
var _right: PackedInt32Array = []
var _left: PackedInt32Array = []

func _resolve(skeleton: Skeleton3D) -> bool:
	if _right.is_empty():
		for name: StringName in RIGHT_CHAIN:
			_right.append(skeleton.find_bone(name))
		for name: StringName in LEFT_CHAIN:
			_left.append(skeleton.find_bone(name))
	return not (_right.has(-1) or _left.has(-1))

func _process_modification_with_delta(_delta: float) -> void:
	var skeleton: Skeleton3D = get_skeleton()
	if skeleton == null or not _resolve(skeleton):
		return
	var aim: Vector3 = (skeleton.global_basis.inverse() * direction).normalized()
	if aim.is_zero_approx():
		return
	_point(skeleton, _right[0], _right[1], aim)
	_point(skeleton, _right[1], _right[2], aim)
	# The left arm is aimed at the right hand, segment by segment. It is about
	# as long as the right one, so it ends at the grip or a few centimetres short.
	var grip: Vector3 = skeleton.get_bone_global_pose(_right[2]).origin
	_point(skeleton, _left[0], _left[1], (grip - skeleton.get_bone_global_pose(_left[0]).origin).normalized())
	_point(skeleton, _left[1], _left[2], (grip - skeleton.get_bone_global_pose(_left[1]).origin).normalized())

## Rotates one bone so its child lies along `toward`, in skeleton space.
func _point(skeleton: Skeleton3D, bone: int, child: int, toward: Vector3) -> void:
	var pose: Transform3D = skeleton.get_bone_global_pose(bone)
	var current: Vector3 = skeleton.get_bone_global_pose(child).origin - pose.origin
	if current.length() < 0.0001 or toward.is_zero_approx():
		return
	var arc := Quaternion(current.normalized(), toward)
	pose.basis = Basis(arc) * pose.basis
	skeleton.set_bone_global_pose(bone, pose)
