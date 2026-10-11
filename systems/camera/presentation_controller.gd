class_name PresentationController
extends Node

const CROP_SHADER: Shader = preload("res://systems/camera/background_crop.gdshader")

@export var background: TextureRect
@export var player: PlayerController
@export var shots: Array[ShotRig] = []
var current_shot: ShotRig

func apply_shot(shot: ShotRig) -> void:
	# No await: the complete presentation changes before the next render.
	for rig: ShotRig in shots:
		rig.set_active(rig == shot)
	background.texture = shot.definition.background
	_apply_crop(shot.definition)
	shot.camera.make_current()
	player.camera = shot.camera
	current_shot = shot

## The plate follows the same crop as the camera frustum, keeping the painted
## scene registered with the geometry it was authored against.
func _apply_crop(definition: ShotDefinition) -> void:
	if not definition.is_cropped():
		background.material = null
		return
	var material := background.material as ShaderMaterial
	if material == null or material.shader != CROP_SHADER:
		material = ShaderMaterial.new()
		material.shader = CROP_SHADER
		background.material = material
	material.set_shader_parameter("zoom", definition.zoom)
	material.set_shader_parameter("focus", definition.effective_focus())
