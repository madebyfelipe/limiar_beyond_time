class_name PlayerController
extends CharacterBody3D

@export var config: PlayerConfig
@export var camera: Camera3D
@export var visual: Node3D
@export var movement_reference: MovementReference
var control_enabled: bool = true
signal damaged(amount: float)
signal died
signal combat_message(text: String)
@export_range(0.0, 100.0) var vitality: float = 100.0:
	set(value):
		vitality = clampf(value, 0.0, 100.0)
		if health != null:
			health.current = vitality
var health: Health
var dodge_left: float = 0.0
var dodge_cooldown_left: float = 0.0
var invulnerability_left: float = 0.0
var hit_stun_left: float = 0.0
var dodge_direction := Vector3.ZERO
var desired_direction: Vector3 = Vector3.ZERO
## Tank steering only: +1 turning left, -1 turning right, 0 otherwise.
var turn_input: float = 0.0
var spawn_transform: Transform3D
## Optional: a PlayerWeapon child. While its gun is up it owns where Dylan
## points, and this body only follows.
var weapon: PlayerWeapon

func _ready() -> void:
	spawn_transform = global_transform
	# Layer 2 is the enemy body; both actors must stop against each other.
	collision_mask |= 2
	health = Health.new()
	health.name = "Health"
	add_child(health)
	health.current = vitality
	health.changed.connect(func(current: float, _maximum: float) -> void: vitality = current)
	health.died.connect(_die)
	ControlScheme.ensure_loaded()
	for child: Node in get_children():
		if child is PlayerWeapon:
			weapon = child

func set_control_enabled(enabled: bool) -> void:
	control_enabled = enabled and not is_dead()
	if not enabled:
		dodge_left = 0.0
		movement_reference.reset()
		if weapon != null:
			weapon.interrupt_input()

func reset_to_start() -> void:
	reset_combat()
	reset_to(spawn_transform)

func is_dead() -> bool:
	return health != null and not health.alive()

func can_use_weapon() -> bool:
	return control_enabled and not is_dead() and dodge_left <= 0.0 and hit_stun_left <= 0.0

func take_damage(amount: float) -> bool:
	if amount <= 0.0 or is_dead() or not control_enabled or invulnerability_left > 0.0:
		return false
	dodge_left = 0.0
	hit_stun_left = config.hit_stun
	invulnerability_left = config.hit_invulnerability
	if weapon != null:
		weapon.interrupt_combat()
	health.apply(amount)
	damaged.emit(amount)
	return true

func _die() -> void:
	set_control_enabled(false)
	velocity = Vector3.ZERO
	desired_direction = Vector3.ZERO
	turn_input = 0.0
	died.emit()

func reset_combat() -> void:
	dodge_left = 0.0
	dodge_cooldown_left = 0.0
	invulnerability_left = 0.0
	hit_stun_left = 0.0
	health.restore()
	control_enabled = true
	if weapon != null:
		weapon.reset_state()

func restore_vitality(value: float) -> void:
	health.current = clampf(value, 1.0, health.maximum)
	health.changed.emit(health.current, health.maximum)

func use_med_kit() -> bool:
	if not can_use_weapon() or get_tree().paused or get_tree().root.has_node("DoorTransition"):
		return false
	SupplyStock.ensure_loaded()
	if SupplyStock.med_kits <= 0:
		combat_message.emit("No med kits. Buy supplies at the terminal.")
		return false
	var previous_vitality := vitality
	if not health.heal(config.med_kit_healing):
		combat_message.emit("Vitality is already full.")
		return false
	SupplyStock.med_kits -= 1
	combat_message.emit("Med kit used · +%d vitality" % int(vitality - previous_vitality))
	return true

func start_dodge() -> bool:
	if not can_use_weapon() or dodge_cooldown_left > 0.0 or get_tree().paused:
		return false
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if ControlScheme.is_tank():
		dodge_direction = facing() * -input.y + facing().cross(Vector3.UP) * input.x
	else:
		dodge_direction = movement_reference.direction_for(input, camera, not input.is_zero_approx())
	if dodge_direction.is_zero_approx():
		dodge_direction = -facing()
	dodge_direction = dodge_direction.normalized()
	dodge_left = config.dodge_duration
	dodge_cooldown_left = config.dodge_cooldown
	invulnerability_left = config.dodge_invulnerability
	if weapon != null:
		weapon.interrupt_combat()
	return true

func reset_to(target: Transform3D) -> void:
	global_transform = target
	velocity = Vector3.ZERO
	desired_direction = Vector3.ZERO
	turn_input = 0.0
	dodge_left = 0.0
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
	invulnerability_left = maxf(0.0, invulnerability_left - delta)
	dodge_cooldown_left = maxf(0.0, dodge_cooldown_left - delta)
	hit_stun_left = maxf(0.0, hit_stun_left - delta)
	if control_enabled and Input.is_action_just_pressed("use_med_kit"):
		use_med_kit()
	if control_enabled and Input.is_action_just_pressed("dodge"):
		start_dodge()
	if is_dead() or dodge_left > 0.0 or hit_stun_left > 0.0:
		desired_direction = dodge_direction if dodge_left > 0.0 else Vector3.ZERO
		turn_input = 0.0
		velocity.x = desired_direction.x * config.dodge_speed
		velocity.z = desired_direction.z * config.dodge_speed
		velocity.y = -0.1 if is_on_floor() else velocity.y - config.gravity * delta
		move_and_slide()
		dodge_left = maxf(0.0, dodge_left - delta)
		return
	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down") if control_enabled else Vector2.ZERO
	# A diagonal stick can clear the radial deadzone before either axis clears
	# its own threshold. Opposed keys still count as held until both release.
	var held: bool = control_enabled and (not input.is_zero_approx() or Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right") or Input.is_action_pressed("move_up") or Input.is_action_pressed("move_down"))
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
