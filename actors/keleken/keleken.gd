class_name KelekenActor
extends CharacterBody3D
## Patrol is delegated to KelekenWander; combat owns movement once alerted.
enum State { PATROL, ALERT, CHASE, ATTACK, HURT, RETURN, DEAD }
@export var gravity: float = 24.0
@export var combat_enabled: bool = false
@export var player: PlayerController
@export var perception_range: float = 8.0
@export var field_of_view: float = 120.0
@export var proximity_range: float = 2.5
@export var chase_speed: float = 3.4
@export var attack_range: float = 1.65
@export var attack_damage: float = 25.0
@export var memory_duration: float = 3.0
@onready var visual: KelekenVisual = $Visual
var drive_velocity := Vector3.ZERO
var health: Health
var hurtbox: Hurtbox
var state: State = State.PATROL
var home := Vector3.ZERO
var last_seen := Vector3.ZERO
var memory_left: float = 0.0
var state_left: float = 0.0
var attack_elapsed: float = 0.0
var attack_cooldown: float = 0.0
var attack_hit: bool = false
var _death_tween: Tween
## Wounds and stains, parented to the level so they stay where they fell.
var blood: BloodEffects

func _ready() -> void:
	var size_factor := visual.target_height / KelekenVisual.SOURCE_HEIGHT
	var body_collision := $Collision as CollisionShape3D
	body_collision.shape = body_collision.shape.duplicate()
	body_collision.shape.radius *= size_factor
	body_collision.shape.height *= size_factor
	body_collision.position *= size_factor
	blood = BloodEffects.new()
	blood.name = "KelekenBlood"
	# The actor is still being added to its parent; the stains join it next frame.
	_attach_blood.call_deferred()
	health = Health.new()
	health.name = "Health"
	add_child(health)
	hurtbox = Hurtbox.new()
	hurtbox.name = "Hurtbox"
	hurtbox.health = health
	hurtbox.body = self
	hurtbox.targetable = combat_enabled
	hurtbox.position = Vector3(0, visual.target_height / 2.0, 0)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.5 * size_factor
	capsule.height = visual.target_height
	shape.shape = capsule
	hurtbox.add_child(shape)
	add_child(hurtbox)
	if not combat_enabled:
		hurtbox.collision_layer = 0
	hurtbox.hit.connect(_on_hit)
	health.died.connect(_die)
	home = position

func _attach_blood() -> void:
	if get_parent() != null and blood.get_parent() == null:
		get_parent().add_child(blood)

func _exit_tree() -> void:
	# The stains outlive a body that dies in place, but not one taken away.
	if is_queued_for_deletion() and is_instance_valid(blood) and blood.get_parent() == null:
		blood.free()

func reset_combat() -> void:
	if _death_tween != null:
		_death_tween.kill()
	state = State.PATROL
	memory_left = 0.0
	state_left = 0.0
	attack_elapsed = 0.0
	attack_cooldown = 0.0
	attack_hit = false
	velocity = Vector3.ZERO
	drive_velocity = Vector3.ZERO
	visual.rotation = Vector3.ZERO
	if blood != null:
		blood.clear()
	# Deferred death changes must be flushed before enabling the body again.
	set_deferred("collision_layer", 2)
	health.restore()
	hurtbox.revive()
	hurtbox.set_deferred("collision_layer", Hurtbox.LAYER)
	if not combat_enabled:
		hurtbox.set_deferred("collision_layer", 0)
	visual.play_clip(&"idle")

func _active_player() -> bool:
	return is_instance_valid(player) and not player.is_dead() and player.control_enabled

func _clear_sight(point: Vector3) -> bool:
	var eye := global_position + Vector3.UP * 1.6
	var query := PhysicsRayQueryParameters3D.create(eye, point, 1, [get_rid(), player.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func sees_player() -> bool:
	if not _active_player():
		return false
	var offset := player.global_position - global_position
	if absf(offset.y) > 1.0 or offset.length() > perception_range:
		return false
	offset.y = 0.0
	if offset.length() > proximity_range and (basis * Vector3.FORWARD).dot(offset.normalized()) < cos(deg_to_rad(field_of_view * 0.5)):
		return false
	return _clear_sight(player.global_position + Vector3.UP * 1.2)

func _face(direction: Vector3, delta: float) -> void:
	if not direction.is_zero_approx():
		rotation.y = rotate_toward(rotation.y, atan2(-direction.x, -direction.z), 4.5 * delta)

func _pursue(point: Vector3, delta: float) -> void:
	var direction := point - global_position
	direction.y = 0.0
	direction = direction.normalized()
	# Local steering for the authored colliders; move_and_slide remains the
	# authority on walls. No navigation mesh is assumed by this prototype.
	var space := get_world_3d().direct_space_state
	var best := Vector3.ZERO
	var score: float = -INF
	for angle: float in [0.0, -0.7, 0.7, -1.3, 1.3]:
		var candidate := direction.rotated(Vector3.UP, angle)
		var clear := true
		for side: float in [-0.35, 0.35]:
			var from := global_position + Vector3.UP * 0.7 + candidate.cross(Vector3.UP) * side
			var query := PhysicsRayQueryParameters3D.create(from, from + candidate * 0.9, 1, [get_rid(), player.get_rid()])
			if not space.intersect_ray(query).is_empty():
				clear = false
				break
		if clear and candidate.dot(direction) > score:
			best = candidate
			score = candidate.dot(direction)
	_face(best if not best.is_zero_approx() else direction, delta)
	drive_velocity = best * chase_speed
	visual.set_locomotion(Vector2(get_real_velocity().x, get_real_velocity().z).length(), true)

func _begin_attack() -> void:
	state = State.ATTACK
	attack_elapsed = 0.0
	attack_hit = false
	drive_velocity = Vector3.ZERO
	visual.play_clip(&"attack_beak", -1.0, 0.08)

func _strike() -> void:
	if not _active_player():
		return
	var offset := player.global_position - global_position
	if absf(offset.y) > 0.8:
		return
	offset.y = 0.0
	if offset.length() <= attack_range + 0.15 and (basis * Vector3.FORWARD).dot(offset.normalized()) > 0.65 and _clear_sight(player.global_position + Vector3.UP * 1.2):
		player.take_damage(attack_damage)

func _on_hit(_damage: float, point: Vector3, direction: Vector3) -> void:
	if not combat_enabled or state == State.DEAD:
		return
	if blood != null and blood.is_inside_tree():
		blood.wound(point, direction)
	state = State.HURT
	state_left = 0.25
	attack_cooldown = 0.5
	drive_velocity = Vector3.ZERO
	if _active_player():
		last_seen = player.global_position
		memory_left = memory_duration
	visual.play_clip(&"hit" if visual.animator.has_animation(&"hit") else &"recover", -1.0, 0.05)

func _die() -> void:
	state = State.DEAD
	drive_velocity = Vector3.ZERO
	velocity = Vector3.ZERO
	set_deferred("collision_layer", 0)
	if blood != null and blood.is_inside_tree():
		blood.pool(global_position)
	if visual.animator.has_animation(&"death"):
		visual.play_clip(&"death", -1.0, 0.06)
		return
	visual.animator.pause()
	# Without a death clip, fall the visual while keeping physics upright.
	_death_tween = create_tween()
	_death_tween.tween_property(visual, "rotation:z", -PI * 0.48, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _combat_tick(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if state == State.DEAD:
		drive_velocity = Vector3.ZERO
		return
	if not _active_player():
		if state == State.PATROL:
			return
		# Doors, menus and death interrupt a prepared strike.
		if state != State.PATROL:
			state = State.RETURN
		drive_velocity = Vector3.ZERO
		visual.set_locomotion(0.0)
		return
	var visible_player := sees_player()
	if visible_player:
		last_seen = player.global_position
		memory_left = memory_duration
	else:
		memory_left = maxf(0.0, memory_left - delta)
	match state:
		State.PATROL:
			if visible_player:
				state = State.ALERT
				state_left = 0.45
				drive_velocity = Vector3.ZERO
				visual.play_clip(&"alert")
		State.ALERT, State.HURT:
			drive_velocity = Vector3.ZERO
			_face(last_seen - global_position, delta)
			state_left -= delta
			if state_left <= 0.0:
				state = State.CHASE
		State.CHASE:
			if memory_left <= 0.0:
				state = State.RETURN
			elif visible_player and global_position.distance_to(player.global_position) <= attack_range:
				_face(player.global_position - global_position, delta)
				drive_velocity = Vector3.ZERO
				visual.set_locomotion(0.0)
				if attack_cooldown <= 0.0:
					_begin_attack()
			else:
				_pursue(last_seen, delta)
		State.ATTACK:
			# Heading is committed at the start. A side step can leave the cone.
			attack_elapsed += delta
			if not attack_hit and attack_elapsed >= 0.42:
				attack_hit = true
				_strike()
			if attack_elapsed >= 1.0:
				state = State.CHASE
				attack_cooldown = 0.65
		State.RETURN:
			if visible_player:
				state = State.CHASE
			elif global_position.distance_to(home) < 0.4:
				state = State.PATROL
				drive_velocity = Vector3.ZERO
			else:
				_pursue(home, delta)

func _physics_process(delta: float) -> void:
	if combat_enabled:
		_combat_tick(delta)
	velocity.x = drive_velocity.x
	velocity.z = drive_velocity.z
	velocity.y = velocity.y - gravity * delta if not is_on_floor() else 0.0
	move_and_slide()
