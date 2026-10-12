class_name Hurtbox
extends Area3D
## Where a shot can land. Lives on its own physics layer, so the world collision
## of a creature never decides what a bullet hits and level geometry still
## blocks it. Targetable hurtboxes are what auto-aim and assisted aim look for.

signal hit(damage: float, point: Vector3, direction: Vector3)

## Physics layer 3, "alvos".
const LAYER := 1 << 2
const GROUP := &"combat_targets"

@export var health: Health
@export_range(0.0, 10.0) var multiplier: float = 1.0
@export var targetable: bool = true
## The creature's own world collider, if it has one: a sight line to this
## hurtbox must not be blocked by the very body it belongs to.
@export var body: CollisionObject3D

func _ready() -> void:
	collision_layer = LAYER
	collision_mask = 0
	monitoring = false
	monitorable = true
	if targetable:
		add_to_group(GROUP)
	if health:
		health.died.connect(_on_died)

## The point auto-aim turns towards: the centre of this hurtbox.
func aim_point() -> Vector3:
	return global_position

func is_alive() -> bool:
	return health == null or health.alive()

func take_hit(damage: float, point: Vector3, direction: Vector3) -> void:
	if not is_alive():
		return
	hit.emit(damage * multiplier, point, direction)
	if health:
		health.apply(damage * multiplier)

## A body that is down neither stops bullets nor draws the aim any more.
func _on_died() -> void:
	set_deferred(&"collision_layer", 0)
	remove_from_group(GROUP)

## Back in play after its Health was restored, as a range target is.
func revive() -> void:
	collision_layer = LAYER
	if targetable:
		add_to_group(GROUP)
