@tool
class_name MapZone
extends CameraZone
## A box on an editable map that cuts to `camera` while Dylan stands in it. Give
## it a CollisionShape3D with a BoxShape3D. Zones may overlap: the higher
## `shot_priority` wins, and on a tie the current framing is kept.

@export var camera: MapShot:
	set(value):
		camera = value
		update_configuration_warnings()

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if camera == null:
		warnings.append("Escolha a MapShot desta zona em Camera.")
	var has_box: bool = false
	for child: Node in get_children():
		has_box = has_box or (child is CollisionShape3D and child.shape is BoxShape3D)
	if not has_box:
		warnings.append("Adicione uma CollisionShape3D com BoxShape3D.")
	return warnings
