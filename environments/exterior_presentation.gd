extends PresentationController
## Keep the shared source/collision/camera fixed while swapping surface rendering.
var source: Node3D
var art_mode: bool = false
const GATE_BLACK_SHADER := preload("res://systems/camera/gate_background_black.gdshader")

func apply_shot(shot: ShotRig) -> void:
	super.apply_shot(shot)
	_apply_material()

func set_art_mode(enabled: bool) -> void:
	art_mode = enabled
	if current_shot:
		_apply_material()

func _apply_material() -> void:
	var use_art: bool = art_mode and current_shot.definition.background != null
	background.visible = use_art
	var material: ShaderMaterial
	if use_art:
		material = ShaderMaterial.new()
		material.shader = preload("res://systems/camera/background_occluder.gdshader")
		material.set_shader_parameter("background",current_shot.definition.background)
		# Occluders repaint themselves with the plate, so they share its crop.
		material.set_shader_parameter("zoom",current_shot.definition.zoom)
		material.set_shader_parameter("focus",current_shot.definition.effective_focus())
		if current_shot.definition.shot_id == &"exterior_4":
			var gate_material := ShaderMaterial.new()
			gate_material.shader = GATE_BLACK_SHADER
			gate_material.set_shader_parameter("zoom", current_shot.definition.zoom)
			gate_material.set_shader_parameter("focus", current_shot.definition.effective_focus())
			background.material = gate_material
			# RGB 1 in the sRGB plate is about 0.0003035 in linear 3D sampling.
			material.set_shader_parameter("black_floor", 0.00031)
	elif background.material is ShaderMaterial and background.material.shader == GATE_BLACK_SHADER:
		_apply_crop(current_shot.definition)
	for mesh: MeshInstance3D in source.get_children():
		mesh.material_override = material
