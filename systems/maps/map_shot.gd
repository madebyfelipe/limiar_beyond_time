@tool
class_name MapShot
extends Camera3D
## One fixed framing of an editable map. Pose it in the editor (the Preview
## toggle shows what it sees) and point one or more MapZone boxes at it: with
## Dylan inside one, the game cuts to this camera. The runner builds a ShotRig
## from the pose, so the camera node itself never renders in game.

## Optional painted plate for this framing; B toggles it over the geometry.
@export var background: Texture2D
## Projective crop of the plate, as ShotDefinition. Leave 1 for no crop.
@export_range(1.0, 3.0) var zoom: float = 1.0
@export var focus: Vector2 = Vector2(0.5, 0.5)

func _ready() -> void:
	if not Engine.is_editor_hint():
		current = false

func to_definition() -> ShotDefinition:
	var definition := ShotDefinition.new()
	definition.shot_id = StringName(name)
	definition.background = background
	definition.camera_position = global_position
	var euler: Vector3 = global_basis.get_euler()
	definition.camera_rotation_degrees = Vector3(rad_to_deg(euler.x), rad_to_deg(euler.y), rad_to_deg(euler.z))
	definition.fov = fov
	definition.zoom = zoom
	definition.focus = focus
	return definition
