@tool
class_name CalibrationDefinition
extends ShotDefinition

# Observations and hypotheses stay separate. An empty world list is intentional
# when the image has no identified spatial correspondence yet.
@export var source_dimensions: Vector2i
@export_multiline var scale_notes: String
@export var calibration_status: String = "UNVALIDATED HYPOTHESIS"
@export var reference_labels: PackedStringArray
@export var reference_pixels: PackedVector2Array
@export var reference_world: PackedVector3Array
# 1 marks a placement anchor obtained from the assumed plane, not an independent
# check of that plane/camera. Empty preserves legacy sheets with no such anchors.
@export var reference_anchor_mask: PackedByteArray
@export var capsule_position: Vector3
@export var grid_origin: Vector3

func has_correspondences() -> bool:
	return reference_world.size() - anchor_count() >= 6 and reference_world.size() == reference_pixels.size() and reference_labels.size() == reference_pixels.size() and (reference_anchor_mask.is_empty() or reference_anchor_mask.size() == reference_world.size())

func is_anchor(index: int) -> bool:
	return index < reference_anchor_mask.size() and reference_anchor_mask[index] == 1

func anchor_count() -> int:
	return reference_anchor_mask.count(1)
