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
	_apply_crop()
	set_active(false)

## Reproduces the authored perspective on a smaller rectangle of the same image
## plane. A frustum does it exactly, so painted and rendered geometry still meet.
func _apply_crop() -> void:
	if not definition.is_cropped():
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		return
	var viewport_size: Vector2 = camera.get_viewport().get_visible_rect().size
	var aspect: float = viewport_size.x / viewport_size.y if viewport_size.y > 0.0 else 16.0 / 9.0
	var half_height: float = camera.near * tan(deg_to_rad(definition.fov) * 0.5)
	var half_width: float = half_height * aspect
	var focus: Vector2 = definition.effective_focus()
	# Screen-space focus to near-plane offset; the y axis points up in the frustum.
	var offset := Vector2((focus.x - 0.5) * 2.0 * half_width, -(focus.y - 0.5) * 2.0 * half_height)
	camera.set_frustum(2.0 * half_height / definition.zoom, offset, camera.near, camera.far)

func set_active(active: bool) -> void:
	light.visible = active
	for mesh: MeshInstance3D in occluders:
		mesh.visible = active
