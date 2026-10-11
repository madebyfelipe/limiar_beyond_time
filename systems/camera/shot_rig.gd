class_name ShotRig
extends Node3D

@export var definition: ShotDefinition
@export var camera: Camera3D
@export var light: DirectionalLight3D
@export var occluders: Array[MeshInstance3D] = []

func _ready() -> void:
	camera.position = definition.camera_position
	camera.rotation_degrees = definition.camera_rotation_degrees
	camera.fov = definition.fov
	set_active(false)

func set_active(active: bool) -> void:
	light.visible = active
	for mesh: MeshInstance3D in occluders:
		mesh.visible = active
