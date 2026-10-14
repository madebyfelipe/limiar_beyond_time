class_name CryopteryxVisual
extends Node3D
## Baked clips on the raptor rig built by tools/rig_cryopteryx.py, all six
## retargeted from a CC0 raptor. The clips play in place: whoever owns this
## node moves it across the world.
const MODEL: PackedScene = preload("res://assets/models/cryopteryx/cryopteryx_animated.glb")
## Nose to tail tip of the exported model, in metres.
const SOURCE_LENGTH := 3.2
## Planted-foot speed of each cycle at SOURCE_LENGTH, from the build
## (animation_manifest.json, after the stride fit).
const NATIVE_SPEED := {&"walk": 1.236, &"run": 3.315}
const LOOPING: Array[StringName] = [&"idle", &"walk", &"run"]
## The animal's size is provisional: this scales the whole model.
@export_range(1.5, 6.0) var target_length: float = 3.2
var model: Node3D
var skeleton: Skeleton3D
var animator: AnimationPlayer
var clip: StringName = &"idle"

func _ready() -> void:
	model = MODEL.instantiate()
	model.name = "Model"
	model.scale = Vector3.ONE * (target_length / SOURCE_LENGTH)
	add_child(model)
	skeleton = model.find_child("Skeleton3D", true, false) as Skeleton3D
	animator = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	# Each instance owns loop flags; never mutate the imported shared library.
	var library := animator.get_animation_library(&"").duplicate(true) as AnimationLibrary
	animator.remove_animation_library(&"")
	animator.add_animation_library(&"", library)
	for name in library.get_animation_list():
		library.get_animation(name).loop_mode = Animation.LOOP_LINEAR if StringName(name) in LOOPING else Animation.LOOP_NONE
	animator.animation_finished.connect(_on_finished)
	play_clip(&"idle", -1.0, 0.0)

## A cycle given a ground speed plays at the rate that keeps its feet planted.
func play_clip(next: StringName, ground_speed: float = -1.0, blend: float = 0.16) -> void:
	if not animator.has_animation(next):
		return
	clip = next
	animator.play(next, blend)
	animator.speed_scale = _cadence(next, ground_speed)

func set_locomotion(ground_speed: float, running: bool = false) -> void:
	var next: StringName = &"idle" if ground_speed < 0.05 else (&"run" if running else &"walk")
	if next != clip:
		play_clip(next, ground_speed)
	else:
		animator.speed_scale = _cadence(next, ground_speed)

func _cadence(of: StringName, ground_speed: float) -> float:
	if not NATIVE_SPEED.has(of) or ground_speed < 0.0:
		return 1.0
	return ground_speed / (float(NATIVE_SPEED[of]) * target_length / SOURCE_LENGTH)

## One-shots hand back to idle, except the death, which stays down.
func _on_finished(finished: StringName) -> void:
	if finished != &"death":
		play_clip(&"idle")
