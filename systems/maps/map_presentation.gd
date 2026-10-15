class_name MapPresentation
extends PresentationController
## The authored levels' art switch for any map: with a plate on the active shot,
## the geometry repaints itself with the plate so it occludes Dylan where the
## painting does; without one, the bare geometry shows.

var geometry: Array[GeometryInstance3D] = []
var art_mode: bool = false

func apply_shot(shot: ShotRig) -> void:
	super.apply_shot(shot)
	_apply_material()

func set_art_mode(enabled: bool) -> void:
	art_mode = enabled
	if current_shot:
		_apply_material()

func _apply_material() -> void:
	var definition: ShotDefinition = current_shot.definition
	var use_art: bool = art_mode and definition.background != null
	background.visible = use_art
	var material: ShaderMaterial = null
	if use_art:
		material = ShaderMaterial.new()
		material.shader = preload("res://systems/camera/background_occluder.gdshader")
		material.set_shader_parameter("background", definition.background)
		material.set_shader_parameter("zoom", definition.zoom)
		material.set_shader_parameter("focus", definition.effective_focus())
	for node: GeometryInstance3D in geometry:
		node.material_override = material
