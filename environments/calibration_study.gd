@tool
extends Control

@export var definition: CalibrationDefinition
@export var available_definitions: Array[CalibrationDefinition] = []
@export var background: TextureRect
@export var viewport: SubViewport
@export var camera: Camera3D
@export var capsule: MeshInstance3D
@export var grid: MeshInstance3D
@export var markers: MeshInstance3D
@export var caption: Label
@export_range(1,40) var grid_extent: int = 12
@export_range(0.1,5.0) var grid_spacing: float = 1.0
@export var show_grid: bool = true
@export var show_markers: bool = true
var _grid_signature: Vector2
var _marker_signature: PackedVector3Array

func _ready() -> void:
	_refresh()

func _process(_delta: float) -> void:
	_refresh()

func _unhandled_key_input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_1, KEY_2, KEY_3:
			var index: int = event.keycode - KEY_1
			if index >= available_definitions.size() or available_definitions[index] == null:
				return
			definition = available_definitions[index]
		KEY_G:
			show_grid = not show_grid
		KEY_M:
			show_markers = not show_markers
		_:
			return
	_refresh()
	get_viewport().set_input_as_handled()

func source_to_frame(pixel: Vector2) -> Vector2:
	var dimensions: Vector2 = Vector2(definition.source_dimensions)
	var scale: float = minf(background.size.x / dimensions.x, background.size.y / dimensions.y)
	return (background.size - dimensions * scale) * 0.5 + pixel * scale

func errors_1080p() -> PackedFloat32Array:
	var errors: PackedFloat32Array = []
	if not definition.has_correspondences() or background.size.y <= 0:
		return errors
	for index: int in range(definition.reference_world.size()):
		if camera.is_position_behind(definition.reference_world[index]):
			errors.append(INF)
			continue
		var actual: Vector2 = camera.unproject_position(definition.reference_world[index])
		actual *= background.size / Vector2(viewport.size)
		errors.append(actual.distance_to(source_to_frame(definition.reference_pixels[index])) * 1080.0 / background.size.y)
	return errors

func _refresh() -> void:
	if definition == null or not is_instance_valid(camera) or not is_instance_valid(background):
		return
	background.texture = definition.background
	camera.position = definition.camera_position
	camera.rotation_degrees = definition.camera_rotation_degrees
	camera.fov = definition.fov
	capsule.position = definition.capsule_position + Vector3(0,0.9,0)
	grid.visible = show_grid
	markers.visible = show_markers
	grid.position = definition.grid_origin
	var signature: Vector2 = Vector2(grid_extent, grid_spacing)
	if signature != _grid_signature:
		_grid_signature = signature
		_make_grid()
	if _marker_signature != definition.reference_world:
		_marker_signature = definition.reference_world.duplicate()
		_make_markers()
	var errors: PackedFloat32Array = errors_1080p()
	caption.text = "%s | capsule 1.8 m | grid %.2f m | %s\n" % [definition.shot_id,grid_spacing,definition.calibration_status]
	if errors.is_empty():
		caption.text += "3D correspondences pending; calibration error undetermined."
	else:
		var maximum: float = 0
		for index: int in range(errors.size()):
			if not definition.is_anchor(index):
				maximum = maxf(maximum,errors[index])
		caption.text += "Maximum hypothesis error: %.2f px at 1080p (target <= 8 px)." % maximum
		if definition.anchor_count() > 0:
			caption.text += " %d plane anchors excluded from maximum." % definition.anchor_count()
	caption.text += "\n1/2/3: change view | G: grid | M: markers | static preview"

func _material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	return material

func _make_grid() -> void:
	var mesh: ImmediateMesh = ImmediateMesh.new()
	var extent: float = grid_extent * grid_spacing
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, _material(Color(0.2,0.8,0.7)))
	for index: int in range(-grid_extent,grid_extent+1):
		var value: float = index * grid_spacing
		for point: Vector3 in [Vector3(value,0.02,-extent),Vector3(value,0.02,extent),Vector3(-extent,0.02,value),Vector3(extent,0.02,value)]:
			mesh.surface_add_vertex(point)
	mesh.surface_end()
	grid.mesh = mesh

func _make_markers() -> void:
	markers.mesh = null
	if definition.reference_world.is_empty():
		return
	var mesh: ImmediateMesh = ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, _material(Color.LIME_GREEN))
	for position: Vector3 in definition.reference_world:
		for point: Vector3 in [position-Vector3.RIGHT*0.1,position+Vector3.RIGHT*0.1,position-Vector3.UP*0.1,position+Vector3.UP*0.1]:
			mesh.surface_add_vertex(point)
	mesh.surface_end()
	markers.mesh = mesh
