class_name KelekenWander
extends Node
## Patrol movement. Combat takes over when the actor perceives Dylan.
@export var bounds := Rect2(-1.55, 15.5, 3.1, 5.5)
@export var speed: float = 1.15
@export var turn_speed: float = 1.8
var actor: KelekenActor
var rng := RandomNumberGenerator.new()
var target := Vector3.ZERO
var idle_remaining := 0.6
var targets_chosen := 0
var _previous := Vector3.ZERO
var _blocked := 0.0

func _ready() -> void:
	actor = get_parent() as KelekenActor
	process_physics_priority = -1
	rng.randomize()
	reset()

func reset() -> void:
	actor.reset_combat()
	actor.position = Vector3(1.2, .06, 18)
	actor.home = actor.global_position
	actor.rotation.y = 0
	actor.velocity = Vector3.ZERO
	actor.drive_velocity = Vector3.ZERO
	_previous = actor.position
	_blocked = 0
	idle_remaining = .6
	target = actor.position
	actor.visual.play_clip(&"idle", 0, 0)

func _pick_target() -> void:
	for attempt in range(16):
		var point := Vector3(rng.randf_range(bounds.position.x + .15, bounds.end.x - .15), .08, rng.randf_range(bounds.position.y + .15, bounds.end.y - .15))
		if Vector2(point.x - actor.position.x, point.z - actor.position.z).length() < 1.2:
			continue
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = (actor.get_node("Collision") as CollisionShape3D).shape
		query.transform = Transform3D(Basis.IDENTITY, point + Vector3(0, .7, .2))
		query.collision_mask = 1
		query.exclude = [actor.get_rid()]
		if actor.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
			target = point
			targets_chosen += 1
			return
	# Keep retrying if the player occupies the available points.
	idle_remaining = .5

func _physics_process(delta: float) -> void:
	if actor.state != KelekenActor.State.PATROL:
		_previous = actor.position
		_blocked = 0.0
		return
	var actual := Vector2(actor.get_real_velocity().x, actor.get_real_velocity().z).length()
	var previous_clip := actor.visual.clip
	actor.visual.set_locomotion(actual)
	if previous_clip != &"idle" and actor.visual.clip == &"idle" and idle_remaining > 0:
		actor.visual.animator.seek(rng.randf_range(0, actor.visual.animator.get_animation(&"idle").length), true)
	if idle_remaining > 0:
		idle_remaining -= delta
		actor.drive_velocity = Vector3.ZERO
		if idle_remaining <= 0:
			_pick_target()
		_previous = actor.position
		return
	var direction := target - actor.position
	direction.y = 0
	if direction.length() < .3:
		actor.drive_velocity = Vector3.ZERO
		idle_remaining = rng.randf_range(.7, 1.8)
		return
	if actor.drive_velocity.length() > .2 and actor.position.distance_to(_previous) < .002:
		_blocked += delta
	else:
		_blocked = 0
	_previous = actor.position
	if _blocked > .8:
		actor.drive_velocity = Vector3.ZERO
		idle_remaining = .3
		_blocked = 0
		return
	direction = direction.normalized()
	var heading := atan2(-direction.x, -direction.z)
	actor.rotation.y = rotate_toward(actor.rotation.y, heading, turn_speed * delta)
	var forward := actor.basis * Vector3.FORWARD
	var desired := forward * speed * maxf(0, forward.dot(direction))
	var next := actor.position + desired * delta
	if not bounds.has_point(Vector2(next.x, next.z)):
		target = Vector3(bounds.get_center().x, .08, bounds.get_center().y)
		actor.drive_velocity = Vector3.ZERO
	else:
		actor.drive_velocity = desired
