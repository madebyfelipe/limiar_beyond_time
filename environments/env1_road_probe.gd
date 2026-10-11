extends Control
## Isolated calibration experiment, not the continuous T07 level.
## A conservative walking strip tests unit actor scale against the original PNG.

@export var definition: CalibrationDefinition
@export var world: Node3D
@export var background: TextureRect
@export var player: PlayerController
@export var road_stations: PackedVector2Array
@export var rail_clearance: float = 0.8
@export var strip_width: float = 3.0
var camera: Camera3D
var bounds: MeshInstance3D
var boundary_vertices: PackedVector3Array = []

func _ready() -> void:
	background.texture = definition.background
	camera = Camera3D.new()
	camera.position = definition.camera_position
	camera.rotation_degrees = definition.camera_rotation_degrees
	camera.fov = definition.fov
	world.add_child(camera)
	camera.make_current()
	player.camera = camera
	_box("Floor", Vector3(24,-0.15,5), Vector3(40,0.3,20))
	for index: int in range(road_stations.size()):
		var station := road_stations[index]
		boundary_vertices.append(Vector3(station.x,0.03,station.y-rail_clearance))
	for index: int in range(road_stations.size()-1,-1,-1):
		var station := road_stations[index]
		boundary_vertices.append(Vector3(station.x,0.03,station.y-rail_clearance-strip_width))
	for index: int in range(boundary_vertices.size()):
		var start := boundary_vertices[index]
		var end := boundary_vertices[(index+1)%boundary_vertices.size()]
		var delta := end-start
		var wall := _box("Limit%d" % index, (start+end)*0.5+Vector3.UP, Vector3(delta.length()+0.2,2,0.2))
		wall.rotation.y = -atan2(delta.z,delta.x)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.15,1,0.65)
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP,material)
	for vertex: Vector3 in boundary_vertices: mesh.surface_add_vertex(vertex)
	mesh.surface_add_vertex(boundary_vertices[0])
	mesh.surface_end()
	bounds = MeshInstance3D.new()
	bounds.mesh = mesh
	bounds.visible = false
	world.add_child(bounds)

func _box(body_name: String, center: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = body_name
	body.position = center
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	collision.shape = box
	body.add_child(collision)
	world.add_child(body)
	return body

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_G:
		bounds.visible = not bounds.visible
		get_viewport().set_input_as_handled()
