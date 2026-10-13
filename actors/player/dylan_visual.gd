extends Node3D
## Motion capture from Mixamo, applied to the auto-rigged Dylan by
## tools/build_dylan_animations.gd. Physics remains on PlayerController.
## The captures face +Z and stand 0.976 tall; gameplay forward is -Z.
const CLIPS: AnimationLibrary = preload("res://assets/models/dylan_protagonist/mixamo/dylan_clips.res")
const PISTOL_MODEL: PackedScene = preload("res://assets/models/weapons/pistol/pistol_lowpoly.glb")
const SOURCE_HEIGHT := 0.9761
## Ground speed each capture carries on its own, measured from the planted foot
## travelling backwards under the hips. Playback follows the real speed, so the
## feet keep contact with the floor instead of skating over it.
const NATIVE_SPEED := {&"walk": 1.48, &"run": 2.73, &"walk_back": 0.61}
## Turn rate of the pivot capture, in rad/s, measured over its own window.
const NATIVE_TURN := 0.887
## Below this cosine the body is travelling backwards rather than forwards.
const BACKWARD_COSINE := -0.4
const DODGE_CLIPS: Array[StringName] = [&"dodge_forward", &"dodge_back", &"dodge_left", &"dodge_right"]
@export_range(0.5, 3.0) var target_height: float = 2.4
@onready var model: Node3D = $Model
@onready var skeleton: Skeleton3D = $Model/Skeleton3D
@onready var player: PlayerController = get_parent().get_parent()
## How quickly the aim stance blends in and out, per second.
const AIM_BLEND := 10.0
## The imported prop has its origin at the grip; the hand bone is the wrist.
const PISTOL_HAND_OFFSET := 0.035
var animator: AnimationPlayer
var interaction_active: bool = false
var locomotion: StringName = &"idle"
var aim_pose: AimPose
var pistol: Node3D
var muzzle: Node3D
var _hand: int = -1
var _dodge_clip: StringName = &"dodge_right"

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
	pistol = PISTOL_MODEL.instantiate()
	pistol.name = "Pistol"
	pistol.top_level = true
	pistol.visible = false
	add_child(pistol)
	muzzle = pistol.find_child("Muzzle", true, false) as Node3D
	# After the modifiers, so the gun sits in the hand the stance has placed.
	skeleton.skeleton_updated.connect(_place_pistol)

func _process(delta: float) -> void:
	_update_aim(delta)
	if player.is_dead():
		animator.pause()
		rotation.z = move_toward(rotation.z, -PI * 0.48, delta * 3.0)
		return
	rotation.z = move_toward(rotation.z, 0.0, delta * 5.0)
	rotation.x = move_toward(rotation.x, 0.12 if player.hit_stun_left > 0.0 else 0.0, delta * 5.0)
	if interaction_active:
		return
	if player.dodge_left > 0.0:
		# One capture per escape relative to the body: roll forward, hop back,
		# sidestep left or right. Each is then aligned with the committed
		# world-space direction; rotating the visual never changes the collision
		# body or travel vector.
		if not DODGE_CLIPS.has(locomotion):
			_dodge_clip = _dodge_clip_for(player.dodge_direction, player.facing())
			locomotion = _dodge_clip
			animator.play(locomotion, 0.04)
		model.global_rotation.y = _dodge_heading(_dodge_clip, player.dodge_direction)
		animator.speed_scale = 1.0
		animator.seek(CLIPS.get_animation(_dodge_clip).length * (1.0 - player.dodge_left / player.config.dodge_duration), true)
		return
	model.rotation.y = lerp_angle(model.rotation.y, PI, minf(1.0, delta * 18.0))
	var motion := Vector2(player.get_real_velocity().x, player.get_real_velocity().z)
	var speed: float = motion.length()
	var forward: Vector3 = player.facing()
	var next: StringName = _clip_for(motion, speed, Vector2(forward.x, forward.z))
	if next != locomotion:
		locomotion = next
		animator.play(next, 0.16)
	elif not animator.is_playing():
		animator.play(next, 0.16)
	animator.speed_scale = _rate_for(next, speed)

func _dodge_clip_for(direction: Vector3, forward: Vector3) -> StringName:
	var along: float = forward.dot(direction)
	var side: float = forward.cross(Vector3.UP).dot(direction)
	if absf(along) >= absf(side):
		return &"dodge_forward" if along > 0.0 else &"dodge_back"
	return &"dodge_right" if side > 0.0 else &"dodge_left"

## Model yaw that points the capture's own travel at the escape. The captures
## face +Z: the roll travels +Z, the hop -Z, the right sidestep -X, the left +X.
func _dodge_heading(clip: StringName, direction: Vector3) -> float:
	match clip:
		&"dodge_forward":
			return atan2(direction.x, direction.z)
		&"dodge_back":
			return atan2(-direction.x, -direction.z)
		&"dodge_right":
			return atan2(-direction.z, direction.x) + PI
	return atan2(-direction.z, direction.x)

func _aiming() -> bool:
	return player.can_use_weapon() and player.weapon != null and player.weapon.aiming and not interaction_active

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
	var prop_scale: float = target_height / 1.8
	pistol.global_transform = Transform3D(Basis.looking_at(along, side).scaled(Vector3.ONE * prop_scale), hand + along * PISTOL_HAND_OFFSET * prop_scale)

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
		# The faster tank pivot needs 3,38x playback at full input.
		return clampf(absf(player.turn_input) * player.config.tank_turn_speed / NATIVE_TURN, 0.5, 4.0)
	return clampf(speed / NATIVE_SPEED.get(clip, NATIVE_SPEED[&"walk"]), 0.6, 2.0)

func play_door_interaction() -> void:
	interaction_active = true
	animator.speed_scale = 1.0
	animator.play(&"door_interact", 0.12)

## A cutscene gesture by clip name. Captures still to be brought from Mixamo
## (typing, a startled turn) fall back to `fallback`, so a scene can name the
## clip it wants today and pick it up as soon as the build tool adds it.
## Returns the clip actually played.
func play_scripted(clip: StringName, fallback: StringName = &"idle") -> StringName:
	var chosen: StringName = clip if animator.has_animation(clip) else fallback
	interaction_active = true
	animator.speed_scale = 1.0
	animator.play(chosen, 0.2)
	return chosen

func end_interaction() -> void:
	interaction_active = false
	locomotion = &"idle"
	animator.play(&"idle", 0.12)
