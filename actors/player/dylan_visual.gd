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
var animator: AnimationPlayer
var interaction_active: bool = false
var locomotion: StringName = &"idle"

func _ready() -> void:
	model.scale = Vector3.ONE * (target_height / SOURCE_HEIGHT)
	model.rotation.y = PI
	animator = model.get_node("AnimationPlayer")
	animator.remove_animation_library(&"")
	animator.add_animation_library(&"", CLIPS)
	animator.play(&"idle")
	animator.advance(0)

func _process(_delta: float) -> void:
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

func _clip_for(motion: Vector2, speed: float, forward: Vector2) -> StringName:
	if speed < 0.08:
		# Standing still, but tank steering may be pivoting the body on the spot.
		if absf(player.turn_input) > 0.1:
			return &"turn_left" if player.turn_input > 0.0 else &"turn_right"
		return &"idle"
	if motion.normalized().dot(forward) < BACKWARD_COSINE:
		return &"walk_back"
	return &"run" if speed > player.config.walk_speed + 0.4 else &"walk"

func _rate_for(clip: StringName, speed: float) -> float:
	if clip == &"idle":
		return 1.0
	if clip == &"turn_left" or clip == &"turn_right":
		return clampf(absf(player.turn_input) * player.config.tank_turn_speed / NATIVE_TURN, 0.5, 2.0)
	return clampf(speed / NATIVE_SPEED[clip], 0.6, 2.0)

func play_door_interaction() -> void:
	interaction_active = true
	animator.speed_scale = 1.0
	animator.play(&"door_interact", 0.12)

func end_interaction() -> void:
	interaction_active = false
	locomotion = &"idle"
	animator.play(&"idle", 0.12)
