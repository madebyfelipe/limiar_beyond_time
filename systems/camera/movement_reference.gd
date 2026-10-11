class_name MovementReference
extends Node

var locked: bool = false
var right: Vector3 = Vector3.RIGHT
var back: Vector3 = Vector3.BACK

func reset() -> void:
	locked = false

func direction_for(input: Vector2, camera: Camera3D, directional_held: bool) -> Vector3:
	if not directional_held:
		reset()
		return Vector3.ZERO
	if not locked:
		right = camera.global_basis.x if camera else Vector3.RIGHT
		back = camera.global_basis.z if camera else Vector3.BACK
		right.y = 0.0
		back.y = 0.0
		right = right.normalized()
		back = back.normalized()
		locked = true
	return (right * input.x + back * input.y).limit_length()
