class_name PlayerController
extends CharacterBody3D

@export var config: PlayerConfig
@export var camera: Camera3D
@export var visual: Node3D
@export var movement_reference: MovementReference
var control_enabled: bool = true
var desired_direction: Vector3 = Vector3.ZERO
var spawn_transform: Transform3D

func _ready() -> void:
	spawn_transform = global_transform

func set_control_enabled(enabled: bool) -> void:
	control_enabled = enabled
	if not enabled:
		movement_reference.reset()

func reset_to_start() -> void:
	global_transform = spawn_transform
	velocity = Vector3.ZERO
	desired_direction = Vector3.ZERO
	visual.rotation = Vector3.ZERO
	movement_reference.reset()

func _physics_process(delta: float) -> void:
	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down") if control_enabled else Vector2.ZERO
	var held: bool = control_enabled and (Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right") or Input.is_action_pressed("move_up") or Input.is_action_pressed("move_down"))
	desired_direction = movement_reference.direction_for(input, camera, held)
	var speed: float = config.run_speed if Input.is_action_pressed("run") else config.walk_speed
	var rate: float = config.acceleration if not input.is_zero_approx() else config.deceleration
	var horizontal: Vector3 = Vector3(velocity.x, 0, velocity.z).move_toward(desired_direction * speed, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	velocity.y = -0.1 if is_on_floor() else velocity.y - config.gravity * delta
	move_and_slide()
	if not desired_direction.is_zero_approx():
		var heading: float = atan2(-desired_direction.x, -desired_direction.z)
		visual.rotation.y = rotate_toward(visual.rotation.y, heading, config.rotation_speed * delta)
