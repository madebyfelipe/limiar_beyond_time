extends Node3D
## Motion capture from Mixamo, applied to the auto-rigged Dylan by
## tools/build_dylan_animations.gd. Physics remains on PlayerController.
## The captures face +Z and stand 0.976 tall; gameplay forward is -Z.
const CLIPS: AnimationLibrary = preload("res://assets/models/dylan_protagonist/mixamo/dylan_clips.res")
const SOURCE_HEIGHT := 0.9761
## Ground speed each capture carries on its own, measured from the planted foot
## travelling backwards under the hips. Playback follows the real speed, so the
## feet keep contact with the floor instead of skating over it.
const NATIVE_SPEED := {&"walk": 1.48, &"run": 2.73, &"walk_back": 0.61}
## Turn rate of the pivot capture, in rad/s, measured over its own window.
const NATIVE_TURN := 0.887
## Below this cosine the body is travelling backwards rather than forwards.
const BACKWARD_COSINE := -0.4
@export_range(0.5, 3.0) var target_height: float = 2.4
@onready var model: Node3D = $Model
@onready var skeleton: Skeleton3D = $Model/Skeleton3D
@onready var player: PlayerController = get_parent().get_parent()
## How quickly the aim stance blends in and out, per second.
const AIM_BLEND := 10.0
## Pistol at the 1,8 m Dylan of the levels; it scales with target_height.
const PISTOL_SIZE := Vector3(0.038, 0.1, 0.2)
var animator: AnimationPlayer
var interaction_active: bool = false
var locomotion: StringName = &"idle"
var aim_pose: AimPose
var pistol: MeshInstance3D
var muzzle: Marker3D
var _hand: int = -1

func _ready() -> void:
	model.scale = Vector3.ONE * (target_height / SOURCE_HEIGHT)
	model.rotation.y = PI
	animator = model.get_node("AnimationPlayer")
	animator.remove_animation_library(&"")
	animator.add_animation_library(&"", CLIPS)
	animator.play(&"idle")
	animator.advance(0)
	aim_pose = AimPose.new()
	aim_pose.influence = 0.0
	aim_pose.active = false
	skeleton.add_child(aim_pose)
	_hand = skeleton.find_bone("mixamorig_RightHand")
	pistol = MeshInstance3D.new()
	var body := BoxMesh.new()
	body.size = PISTOL_SIZE * (target_height / 1.8)
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(0.09, 0.09, 0.1)
	finish.roughness = 0.45
	body.material = finish
	pistol.mesh = body
	pistol.top_level = true
	pistol.visible = false
	add_child(pistol)
	muzzle = Marker3D.new()
	muzzle.position = Vector3(0.0, body.size.y * 0.3, -body.size.z * 0.5)
	pistol.add_child(muzzle)
	# After the modifiers, so the gun sits in the hand the stance has placed.
	skeleton.skeleton_updated.connect(_place_pistol)

func _process(delta: float) -> void:
	_update_aim(delta)
	if interaction_active:
		return
	var motion := Vector2(player.get_real_velocity().x, player.get_real_velocity().z)
	var speed: float = motion.length()
	var forward: Vector3 = player.facing()
	var next: StringName = _clip_for(motion, speed, Vector2(forward.x, forward.z))
	if next != locomotion:
		locomotion = next
		animator.play(next, 0.16)
	animator.speed_scale = _rate_for(next, speed)

func _aiming() -> bool:
	return player.weapon != null and player.weapon.aiming and not interaction_active

func _update_aim(delta: float) -> void:
	var weapon: PlayerWeapon = player.weapon
	if weapon == null:
		return
	weapon.muzzle_marker = muzzle
	var goal: float = 1.0 if _aiming() else 0.0
	aim_pose.influence = move_toward(aim_pose.influence, goal, AIM_BLEND * delta)
	aim_pose.active = aim_pose.influence > 0.0
	if _aiming():
		aim_pose.direction = weapon.shot_direction()
	pistol.visible = aim_pose.influence > 0.5

func _place_pistol() -> void:
	if not pistol.visible or _hand < 0:
		return
	var hand: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(_hand).origin
	var along: Vector3 = aim_pose.direction.normalized()
	var side: Vector3 = Vector3.UP if absf(along.dot(Vector3.UP)) < 0.95 else Vector3.FORWARD
	pistol.global_transform = Transform3D(Basis.looking_at(along, side), hand + along * (pistol.mesh as BoxMesh).size.z * 0.35)

func _clip_for(motion: Vector2, speed: float, forward: Vector2) -> StringName:
	if _aiming():
		return _aim_clip_for(motion, speed, forward)
	if speed < 0.08:
		# Standing still, but tank steering may be pivoting the body on the spot.
		if absf(player.turn_input) > 0.1:
			return &"turn_left" if player.turn_input > 0.0 else &"turn_right"
		return &"idle"
	if motion.normalized().dot(forward) < BACKWARD_COSINE:
		return &"walk_back"
	return &"run" if speed > player.config.walk_speed + 0.4 else &"walk"

## Legs while the gun is up. Strafing and aimed captures do not exist yet, so a
## sideways step borrows the walk until they are captured; the names below are
## the ones a future capture should take to be picked up on its own.
func _aim_clip_for(motion: Vector2, speed: float, forward: Vector2) -> StringName:
	if speed < 0.08:
		if absf(player.turn_input) > 0.1:
			return &"turn_left" if player.turn_input > 0.0 else &"turn_right"
		return &"aim_idle" if animator.has_animation(&"aim_idle") else &"idle"
	var along: float = motion.normalized().dot(forward)
	if along < BACKWARD_COSINE:
		return &"walk_back"
	if along < 0.5:
		var side: float = motion.normalized().cross(forward)
		# Facing -Z, left is -X, where this cross product turns positive.
		var strafe: StringName = &"strafe_left" if side > 0.0 else &"strafe_right"
		if animator.has_animation(strafe):
			return strafe
	return &"walk"

func _rate_for(clip: StringName, speed: float) -> float:
	if clip == &"idle" or clip == &"aim_idle":
		return 1.0
	if clip == &"turn_left" or clip == &"turn_right":
		return clampf(absf(player.turn_input) * player.config.tank_turn_speed / NATIVE_TURN, 0.5, 2.0)
	return clampf(speed / NATIVE_SPEED.get(clip, NATIVE_SPEED[&"walk"]), 0.6, 2.0)

func play_door_interaction() -> void:
	interaction_active = true
	animator.speed_scale = 1.0
	animator.play(&"door_interact", 0.12)

func end_interaction() -> void:
	interaction_active = false
	locomotion = &"idle"
	animator.play(&"idle", 0.12)
