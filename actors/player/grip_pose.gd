extends SkeletonModifier3D
## Closes the right hand around the gun whatever the legs are playing. The
## finger rotations are read once from a capture that already holds a pistol
## (Mixamo "Pistol Idle", the `aim_idle` clip) and laid over every frame, so the
## unarmed cycles stop showing an open hand under the grip.

const FINGERS := ["Thumb", "Index", "Middle", "Ring", "Pinky"]

var _bones: PackedInt32Array = []
var _rotations: Array[Quaternion] = []

## Samples the finger pose of `clip` at its first frame.
func setup(skeleton: Skeleton3D, clip: Animation) -> void:
	_bones.clear()
	_rotations.clear()
	for finger: String in FINGERS:
		for joint: int in range(1, 4):
			var bone_name := "mixamorig_RightHand%s%d" % [finger, joint]
			var bone: int = skeleton.find_bone(bone_name)
			var track: int = _track(clip, bone_name)
			if bone < 0 or track < 0:
				continue
			_bones.append(bone)
			_rotations.append(clip.rotation_track_interpolate(track, 0.0))

func _track(clip: Animation, bone_name: String) -> int:
	for track: int in range(clip.get_track_count()):
		if clip.track_get_type(track) == Animation.TYPE_ROTATION_3D and str(clip.track_get_path(track)).ends_with(":" + bone_name):
			return track
	return -1

func _process_modification_with_delta(_delta: float) -> void:
	var skeleton: Skeleton3D = get_skeleton()
	if skeleton == null:
		return
	for i: int in range(_bones.size()):
		skeleton.set_bone_pose_rotation(_bones[i], _rotations[i])
