extends Control
## Local level assembly. Runtime reuses the authored spatial source, while
## presentation remains TextureRect + transparent 3D actors/depth occluders.

@export var geometry: PackedScene
@export var definitions: Array[ShotDefinition]
@export var world: Node3D
@export var background: TextureRect
@export var player: PlayerController
@export var zone_centers: Array[Vector3]
@export var zone_sizes: Array[Vector3]
var director: CameraDirector
var presentation: PresentationController
var shots: Array[ShotRig] = []
var colliders: Node3D
var endpoint: Marker3D

func _ready() -> void:
	var source: Node3D = geometry.instantiate()
	source.name = "AuthoredGeometry"
	source.visible = false
	world.add_child(source)
	colliders = Node3D.new()
	colliders.name = "SharedColliders"
	world.add_child(colliders)
	for mesh: MeshInstance3D in source.get_children():
		var shape: Shape3D
		if mesh.has_meta("collision_size"):
			var box := BoxShape3D.new()
			box.size = mesh.get_meta("collision_size")
			shape = box
		elif mesh.has_meta("collision_points"):
			var wedge := ConvexPolygonShape3D.new()
			wedge.points = mesh.get_meta("collision_points")
			shape = wedge
		else:
			continue
		var body := StaticBody3D.new()
		body.name = mesh.name
		body.transform = mesh.transform
		var collision := CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
		colliders.add_child(body)
	for definition: ShotDefinition in definitions:
		var rig := ShotRig.new()
		rig.name = String(definition.shot_id)
		rig.definition = definition
		rig.camera = Camera3D.new()
		rig.camera.name = "Camera"
		rig.add_child(rig.camera)
		rig.light = DirectionalLight3D.new()
		rig.light.rotation = Vector3(-0.7,-0.5,0)
		rig.light.light_energy = 1.2
		rig.add_child(rig.light)
		var material := ShaderMaterial.new()
		material.shader = preload("res://systems/camera/background_occluder.gdshader")
		material.set_shader_parameter("background",definition.background)
		for original: MeshInstance3D in source.get_children():
			var occluder := MeshInstance3D.new()
			occluder.name = original.name
			occluder.mesh = original.mesh
			occluder.transform = original.transform
			occluder.material_override = material
			occluder.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			rig.add_child(occluder)
			rig.occluders.append(occluder)
		world.add_child(rig)
		shots.append(rig)
	presentation = PresentationController.new()
	presentation.name = "Presentation"
	presentation.background = background
	presentation.player = player
	presentation.shots = shots
	world.add_child(presentation)
	var zones: Array[CameraZone] = []
	for index: int in range(shots.size()):
		var zone := CameraZone.new()
		zone.name = "Zone%d" % (index+1)
		zone.position = zone_centers[index]
		zone.shot = shots[index]
		zone.shot_priority = index
		zone.collision_layer = 0
		zone.collision_mask = 1
		var shape := BoxShape3D.new()
		shape.size = zone_sizes[index]
		var collision := CollisionShape3D.new()
		collision.shape = shape
		zone.add_child(collision)
		world.add_child(zone)
		zones.append(zone)
	director = CameraDirector.new()
	director.name = "Director"
	director.player = player
	director.zones = zones
	director.initial_shot = shots[0]
	director.presentation = presentation
	director.process_physics_priority = 10
	world.add_child(director)
	endpoint = Marker3D.new()
	endpoint.name = "Endpoint"
	endpoint.position = Vector3(0,1.2,-23)
	world.add_child(endpoint)
