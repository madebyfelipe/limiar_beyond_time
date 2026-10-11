extends Node3D
## Original clips authored on the imported rig. Physics remains on PlayerController.
## Source faces +X and is 0.99608624 units tall; gameplay forward is -Z.
const SOURCE_HEIGHT := 0.9960862398147583
@export_range(0.5, 3.0) var target_height: float = 2.4
@onready var model: Node3D = $Model
@onready var skeleton: Skeleton3D = $Model/Armature/Skeleton3D
@onready var player: PlayerController = get_parent().get_parent()
var animator: AnimationPlayer
var interaction_active: bool = false
var locomotion: StringName = &"idle"
const BONES: PackedStringArray = [
	"tripo__Spine_0", "bone_4", "tripo__0_Right_Limb_2", "bone_14",
	"tripo__0_Right_Limb_3", "bone_15", "tripo__1_Left_Limb_0",
	"tripo__0_Left_Limb_0", "tripo__1_Left_Limb_1", "tripo__0_Left_Limb_1",
	"tripo__1_Left_Limb_2", "tripo__0_Left_Limb_2",
]

func _ready() -> void:
	model.scale = Vector3.ONE * (target_height / SOURCE_HEIGHT)
	model.rotation.y = PI / 2
	animator = AnimationPlayer.new()
	animator.name = "LocomotionAnimator"
	add_child(animator)
	var library := AnimationLibrary.new()
	for clip: StringName in [&"idle", &"walk", &"run", &"door_interact"]:
		library.add_animation(clip, _make_clip(clip))
	animator.add_animation_library(&"", library)
	animator.play(&"idle")
	animator.advance(0)

func _process(_delta: float) -> void:
	if interaction_active:
		return
	var speed: float = Vector2(player.get_real_velocity().x, player.get_real_velocity().z).length()
	var next: StringName = &"idle" if speed < 0.08 else (&"run" if speed > player.config.walk_speed + 0.4 else &"walk")
	if next != locomotion:
		locomotion = next
		animator.play(next, 0.16)
	var reference_speed: float = player.config.run_speed if next == &"run" else player.config.walk_speed
	animator.speed_scale = 1.0 if next == &"idle" else clampf(speed / reference_speed, 0.15, 1.5)

func play_door_interaction() -> void:
	interaction_active = true
	animator.speed_scale = 1.0
	animator.play(&"door_interact", 0.12)

func end_interaction() -> void:
	interaction_active = false
	locomotion = &"idle"
	animator.play(&"idle", 0.12)

func _rotation_for(bone_name: String, pose: Array[Vector3], cache: Dictionary) -> Quaternion:
	var bone: int = skeleton.find_bone(bone_name)
	assert(bone >= 0, "Dylan skeleton no longer matches the supplied asset: " + bone_name)
	var parent_basis: Basis = _posed_basis(skeleton.get_bone_parent(bone), pose, cache)
	return (parent_basis.inverse() * _posed_basis(bone, pose, cache)).get_rotation_quaternion().normalized()

func _posed_basis(bone: int, pose: Array[Vector3], cache: Dictionary) -> Basis:
	if bone < 0:
		return Basis.IDENTITY
	if cache.has(bone):
		return cache[bone]
	var parent_basis: Basis = _posed_basis(skeleton.get_bone_parent(bone), pose, cache)
	var rest_basis: Basis = skeleton.get_bone_rest(bone).basis.orthonormalized()
	# Convert axes through the POSED ancestors, including lowered upper arms.
	# Using the bind basis here twists elbows sideways when their parent moves.
	var basis: Basis = (parent_basis * rest_basis).inverse()
	var index: int = BONES.find(skeleton.get_bone_name(bone))
	var angles: Vector3 = pose[index] if index >= 0 else Vector3.ZERO
	var rest: Quaternion = skeleton.get_bone_rest(bone).basis.get_rotation_quaternion()
	var rotation: Quaternion = (rest * Quaternion((basis * Vector3.BACK).normalized(), angles.z)
		* Quaternion((basis * Vector3.RIGHT).normalized(), angles.x)
		* Quaternion((basis * Vector3.UP).normalized(), angles.y)).normalized()
	var result: Basis = parent_basis * Basis(rotation)
	cache[bone] = result
	return result

func _angles(clip: StringName, phase: float) -> Array[Vector3]:
	var pose: Array[Vector3] = []
	pose.resize(BONES.size())
	pose.fill(Vector3.ZERO)
	pose[2].x = -1.15
	pose[3].x = 1.15
	if clip == &"idle":
		pose[0].z = sin(phase * TAU) * 0.012
		pose[1].z = -pose[0].z * 0.5
		pose[2].x += sin(phase * TAU) * 0.018
		pose[3].x -= sin(phase * TAU) * 0.018
	elif clip == &"door_interact":
		var reach: float = sin(clampf(phase / 0.7, 0.0, 1.0) * PI * 0.5)
		pose[0].z = -0.07 * reach
		pose[1].z = 0.04 * reach
		pose[2] = Vector3(-1.35, 0.0, 0.85 * reach)
		pose[4].z = 0.35 * reach
	else:
		var running: bool = clip == &"run"
		var swing: float = sin(phase * TAU)
		var amplitude: float = 0.58 if running else 0.38
		pose[0].z = (-0.12 if running else -0.025) + sin(phase * TAU * 2) * 0.018
		pose[1].z = -pose[0].z * 0.45
		pose[2].z = -swing * (0.48 if running else 0.24)
		pose[3].z = swing * (0.48 if running else 0.24)
		pose[4].z = 0.85 if running else 0.15
		pose[5].z = 0.85 if running else 0.15
		pose[6].z = swing * amplitude
		pose[7].z = -swing * amplitude
		pose[8].z = -maxf(0, swing) * (1.05 if running else 0.62)
		pose[9].z = -maxf(0, -swing) * (1.05 if running else 0.62)
		pose[10].z = -(pose[6].z + pose[8].z) * 0.6
		pose[11].z = -(pose[7].z + pose[9].z) * 0.6
	return pose

func _make_clip(clip: StringName) -> Animation:
	var animation := Animation.new()
	animation.length = 3.6 if clip == &"idle" else (0.64 if clip == &"run" else (0.9 if clip == &"walk" else 0.72))
	animation.loop_mode = Animation.LOOP_NONE if clip == &"door_interact" else Animation.LOOP_LINEAR
	for bone_name: String in BONES:
		var track: int = animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(track, NodePath("Model/Armature/Skeleton3D:" + bone_name))
	for sample: int in range(33):
		var phase: float = float(sample) / 32.0
		var pose: Array[Vector3] = _angles(clip, phase)
		var cache: Dictionary = {}
		for bone: int in range(BONES.size()):
			animation.rotation_track_insert_key(bone, phase * animation.length, _rotation_for(BONES[bone], pose, cache))
	return animation
