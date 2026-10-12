class_name PlayerController
extends CharacterBody3D

@export var config: PlayerConfig
@export var camera: Camera3D
@export var visual: Node3D
@export var movement_reference: MovementReference
var control_enabled: bool = true
## HUD source for the exploration prototype; damage/combat is not implemented.
@export_range(0.0, 100.0) var vitality: float = 100.0
var desired_direction: Vector3 = Vector3.ZERO
## Tank steering only: +1 turning left, -1 turning right, 0 otherwise.
var turn_input: float = 0.0
var spawn_transform: Transform3D
## Optional: a PlayerWeapon child. While its gun is up it owns where Dylan
## points, and this body only follows.
var weapon: PlayerWeapon

func _ready() -> void:
	spawn_transform = global_transform
	ControlScheme.ensure_loaded()
	for child: Node in get_children():
		if child is PlayerWeapon:
			weapon = child

func set_control_enabled(enabled: bool) -> void:
	control_enabled = enabled
	if not enabled:
		movement_reference.reset()

func reset_to_start() -> void:
	reset_to(spawn_transform)

func reset_to(target: Transform3D) -> void:
	global_transform = target
	velocity = Vector3.ZERO
	desired_direction = Vector3.ZERO
	turn_input = 0.0
	visual.rotation = Vector3.ZERO
	movement_reference.reset()

func _notification(what: int) -> void:
	# Pausing interrupts input; the next directional input uses the current camera.
	if what == NOTIFICATION_PAUSED:
		movement_reference.reset()

## Where the body is pointing, which tank steering drives and turns.
func facing() -> Vector3:
	return Vector3(-sin(visual.rotation.y), 0.0, -cos(visual.rotation.y))

func _physics_process(delta: float) -> void:
	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down") if control_enabled else Vector2.ZERO
	var held: bool = control_enabled and (Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right") or Input.is_action_pressed("move_up") or Input.is_action_pressed("move_down"))
	var tank: bool = ControlScheme.is_tank()
	var aiming: bool = weapon != null and weapon.aiming
	if tank and aiming:
		# Resident Evil: a raised gun plants the feet. The weapon turns the body,
		# by hand or onto a target, and the pivot clips follow its turn input.
		turn_input = weapon.turn_input
		movement_reference.reset()
		desired_direction = Vector3.ZERO
	elif tank:
		# Steering is independent of travel, so Dylan can turn while standing.
		turn_input = -input.x
		visual.rotation.y = wrapf(visual.rotation.y + turn_input * config.tank_turn_speed * delta, -PI, PI)
		movement_reference.reset()
		desired_direction = facing() * -input.y
	else:
		turn_input = 0.0
		desired_direction = movement_reference.direction_for(input, camera, held)
	var speed: float = config.run_speed if Input.is_action_pressed("run") else config.walk_speed
	if aiming:
		speed = config.walk_speed * config.aim_move_factor
	# Tank reverse is a careful step back, never a full run.
	if tank and not aiming and input.y > 0.0:
		speed = config.walk_speed * config.tank_reverse_factor
	var rate: float = config.acceleration if not desired_direction.is_zero_approx() else config.deceleration
	var horizontal: Vector3 = Vector3(velocity.x, 0, velocity.z).move_toward(desired_direction * speed, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	velocity.y = -0.1 if is_on_floor() else velocity.y - config.gravity * delta
	move_and_slide()
	if aiming:
		# The body faces the gun in both schemes; in the modern one the legs keep
		# going where the keys say, which is what makes strafing possible.
		visual.rotation.y = rotate_toward(visual.rotation.y, weapon.heading, config.aim_turn_speed * delta)
	elif not tank and not desired_direction.is_zero_approx():
		var heading: float = atan2(-desired_direction.x, -desired_direction.z)
		visual.rotation.y = rotate_toward(visual.rotation.y, heading, config.rotation_speed * delta)
