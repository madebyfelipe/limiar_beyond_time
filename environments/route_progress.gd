class_name RouteProgress
extends Node
## Level-local technical objective: reach the golden pad, then return to the
## blue start pad. Runs in physics, so pausing suspends progress and time.

signal endpoint_reached
signal route_completed(elapsed: float)

enum Stage { OUTBOUND, RETURNING, COMPLETED }

@export var player: PlayerController
## Pad centres at floor height; footprints match the authored 2 × 1,5 m pads.
@export var start_pad: Vector3 = Vector3(0, 0, 9)
@export var end_pad: Vector3 = Vector3(0, 1.2, -23)
@export var pad_half_extents: Vector2 = Vector2(1.0, 0.75)
@export_range(0.05, 1.0) var height_tolerance: float = 0.3
var stage: Stage = Stage.OUTBOUND
var elapsed: float = 0.0

func reset() -> void:
	stage = Stage.OUTBOUND
	elapsed = 0.0

func is_on_pad(center: Vector3) -> bool:
	var p: Vector3 = player.global_position
	return absf(p.x-center.x) <= pad_half_extents.x and absf(p.z-center.z) <= pad_half_extents.y and absf(p.y-center.y) <= height_tolerance

## Pad used to recover the actor: the last one reached on this attempt.
func checkpoint() -> Vector3:
	return end_pad if stage == Stage.RETURNING else start_pad

func _physics_process(delta: float) -> void:
	if stage == Stage.COMPLETED:
		return
	elapsed += delta
	if stage == Stage.OUTBOUND and is_on_pad(end_pad):
		stage = Stage.RETURNING
		endpoint_reached.emit()
	elif stage == Stage.RETURNING and is_on_pad(start_pad):
		stage = Stage.COMPLETED
		route_completed.emit(elapsed)
