extends Node3D
## Non-destructive presentation adapter for the supplied, unanimated GLB.
## Source faces +X and is 0.99608624 units tall; gameplay forward is -Z.
const SOURCE_HEIGHT := 0.9960862398147583
const TARGET_HEIGHT := 2.4
@onready var model: Node3D = $Model
@onready var skeleton: Skeleton3D = $Model/Armature/Skeleton3D

func _ready() -> void:
	model.scale = Vector3.ONE * (TARGET_HEIGHT / SOURCE_HEIGHT)
	model.rotation.y = PI / 2
	# Upper arms, identified by the imported rest hierarchy. Keep the source
	# skin and rest transforms intact; apply only a local neutral presentation pose.
	_lower_arm("tripo__0_Right_Limb_2", -1.15)
	_lower_arm("bone_14", 1.15)

func _lower_arm(bone_name: String, angle: float) -> void:
	var bone := skeleton.find_bone(bone_name)
	assert(bone >= 0, "Dylan skeleton no longer matches the supplied asset")
	var local_axis := skeleton.get_bone_global_rest(bone).basis.inverse() * Vector3.RIGHT
	var rest := skeleton.get_bone_rest(bone).basis.get_rotation_quaternion()
	skeleton.set_bone_pose_rotation(bone, rest * Quaternion(local_axis.normalized(), angle))
