class_name KelekenVisual
extends Node3D
## Original baked clips on an avian rig. Physics drives world translation.
const SOURCE_HEIGHT := 2.4
const NATIVE_SPEED := {&"walk": 1.0, &"run": 2.8}
const LOOPING: Array[StringName] = [&"idle", &"walk", &"run", &"look"]
@export_range(1.0, 4.0) var target_height: float = 2.4
@onready var model: Node3D = $Model
@onready var skeleton: Skeleton3D = $Model/Keleken/Skeleton3D
@onready var animator: AnimationPlayer = $Model/AnimationPlayer
var clip: StringName = &"idle"
var beak: Marker3D

func _ready() -> void:
	model.scale = Vector3.ONE * (target_height / SOURCE_HEIGHT)
	# Each instance owns loop flags; never mutate the imported shared library.
	var library := animator.get_animation_library(&"").duplicate(true) as AnimationLibrary
	animator.remove_animation_library(&"")
	animator.add_animation_library(&"", library)
	for name in library.get_animation_list():
		library.get_animation(name).loop_mode = Animation.LOOP_LINEAR if StringName(name) in LOOPING else Animation.LOOP_NONE
	var attachment := BoneAttachment3D.new()
	attachment.name = "BeakAttachment"
	attachment.bone_name = "head"
	skeleton.add_child(attachment)
	beak = Marker3D.new()
	beak.name = "BeakTip"
	beak.position = Vector3(0, 0.43, 0)
	attachment.add_child(beak)
	animator.animation_finished.connect(_on_finished)
	play_clip(&"idle", 0, 0)

func play_clip(next: StringName, ground_speed: float = -1.0, blend: float = 0.16) -> void:
	if not animator.has_animation(next):
		return
	clip = next
	animator.play(next, blend)
	if NATIVE_SPEED.has(next) and ground_speed >= 0:
		animator.speed_scale = ground_speed / (float(NATIVE_SPEED[next]) * target_height / SOURCE_HEIGHT)
	else:
		animator.speed_scale = 1.0

func set_locomotion(ground_speed: float, running: bool = false) -> void:
	var next: StringName = &"idle" if ground_speed < 0.05 else (&"run" if running else &"walk")
	if next != clip:
		play_clip(next, ground_speed)
	elif NATIVE_SPEED.has(next):
		animator.speed_scale = ground_speed / (float(NATIVE_SPEED[next]) * target_height / SOURCE_HEIGHT)

func _on_finished(_name: StringName) -> void:
	if get_parent() is KelekenActor and get_parent().state == KelekenActor.State.DEAD:
		return
	play_clip(&"idle")
