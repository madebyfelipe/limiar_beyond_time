class_name ShotDefinition
extends Resource

@export var shot_id: StringName
@export var background: Texture2D
@export var camera_position: Vector3
@export var camera_rotation_degrees: Vector3
@export_range(10.0, 100.0) var fov: float = 50.0
## Projective crop of the authored frame. The camera narrows by `zoom` while the
## background is magnified by the same factor around `focus`, so a shot can be
## framed tighter without regenerating its art: both sides describe the very
## same pinhole, only a smaller rectangle of its image plane.
@export_range(1.0, 3.0) var zoom: float = 1.0
## Point of the authored frame placed at the centre of the cropped one, in
## normalised coordinates. Kept inside the image by `effective_focus()`.
@export var focus: Vector2 = Vector2(0.5, 0.5)

## The crop window cannot leave the authored image, or the edge pixel smears.
func effective_focus() -> Vector2:
	var margin: float = 0.5 / zoom
	return Vector2(
		clampf(focus.x, margin, 1.0 - margin),
		clampf(focus.y, margin, 1.0 - margin))

func is_cropped() -> bool:
	return not is_equal_approx(zoom, 1.0)
