extends Control

@export var capsule: MeshInstance3D
@export var automatic: bool = true
@export_range(1.0, 60.0) var cycle_seconds: float = 12.0
@export var waypoints: PackedVector3Array = PackedVector3Array([
	Vector3(0, 0.9, 1.6), Vector3(-2, 0.9, 1.6), Vector3(-2, 0.9, -1.6),
	Vector3(0, 0.9, -1.6), Vector3(2, 0.9, -1.6), Vector3(2, 0.9, 1.6), Vector3(0, 0.9, 1.6)
])
var phase: float = 0.0

func _ready() -> void:
	set_phase(0.0)

func _process(delta: float) -> void:
	if automatic:
		set_phase(phase + delta / cycle_seconds)

func set_phase(value: float) -> void:
	phase = fposmod(value, 1.0)
	var segment: float = phase * (waypoints.size() - 1)
	var index: int = int(segment)
	capsule.position = waypoints[index].lerp(waypoints[index + 1], segment - index)
