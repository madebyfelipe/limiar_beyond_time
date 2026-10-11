extends PresentationController
## Keep the shared source/collision/camera fixed while swapping surface rendering.
var source: Node3D
var art_mode: bool = false

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
	for mesh: MeshInstance3D in source.get_children():
		mesh.material_override = material
