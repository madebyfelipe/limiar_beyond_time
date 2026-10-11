class_name ShotDefinition
extends Resource

@export var shot_id: StringName
@export var background: Texture2D
@export var camera_position: Vector3
@export var camera_rotation_degrees: Vector3
@export_range(10.0, 100.0) var fov: float = 50.0
