extends SceneTree
## Starts an editable map in maps/ from a small template: a floor, a few blocks
## to walk round, two fixed cameras that cut on a line across the floor and a
## start point. Open the result in the editor and change anything.
##   godot --headless --path . --script res://tools/new_map.gd -- name
## Refuses to overwrite a map that already exists.

const MATERIALS := {
	"floor": Color("8d9aa3"),
	"block": Color("536570"),
	"ramp": Color("6f7f88"),
}

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.is_empty() or not args[0].is_valid_filename():
		push_error("Uso: --script res://tools/new_map.gd -- nome_do_mapa")
		quit(1)
		return
	var map_name: String = args[0]
	var path: String = "res://maps/%s.tscn" % map_name
	if FileAccess.file_exists(path):
		push_error("Já existe: %s (abra no editor para editar)" % path)
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://maps"))
	var root := build(map_name)
	var scene := PackedScene.new()
	var error: int = scene.pack(root)
	if error == OK:
		error = ResourceSaver.save(scene, path)
	root.free()
	if error != OK:
		push_error("Falha ao salvar %s: %d" % [path, error])
		quit(1)
		return
	print("MAP created %s" % path)
	quit(0)

static func build(map_name: String) -> MapRoot:
	var root := MapRoot.new()
	root.name = map_name.to_pascal_case()
	root.map_title = map_name.capitalize()
	var geometry := Node3D.new()
	geometry.name = "Geometry"
	adopt(root, root, geometry)
	box(root, geometry, "Floor", Vector3(0, -0.15, -6), Vector3(16, 0.3, 24), "floor")
	box(root, geometry, "Crate", Vector3(-3, 0.5, -3), Vector3(1, 1, 1), "block")
	box(root, geometry, "Wall", Vector3(2.5, 1.25, -8), Vector3(5, 2.5, 0.4), "block")
	box(root, geometry, "Pillar", Vector3(-4, 1.5, -13), Vector3(1, 3, 1), "block")
	var ramp := box(root, geometry, "Ramp", Vector3(4.5, 0.35, -14), Vector3(3, 0.3, 5), "ramp")
	ramp.rotation_degrees = Vector3(-8, 0, 0)
	var shots := Node3D.new()
	shots.name = "Shots"
	adopt(root, root, shots)
	var zones := Node3D.new()
	zones.name = "Zones"
	adopt(root, root, zones)
	# South half seen from behind the start; north half from its far corner.
	var south := shot(root, shots, "Shot1", Vector3(0, 8, 11), Vector3(0, 0.9, -2), 40.0)
	var north := shot(root, shots, "Shot2", Vector3(-7, 8, -20), Vector3(1, 0.9, -11), 42.0)
	zone(root, zones, "Zone1", south, Vector3(0, 2, -1.5), Vector3(16, 4, 15))
	zone(root, zones, "Zone2", north, Vector3(0, 2, -13.5), Vector3(16, 4, 10))
	var start := Marker3D.new()
	start.name = "PlayerStart"
	start.position = Vector3(0, 0.06, 2)
	adopt(root, root, start)
	return root

static func adopt(root: Node, parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = root

static func box(root: Node, parent: Node, box_name: String, at: Vector3, size: Vector3, kind: String) -> CSGBox3D:
	var node := CSGBox3D.new()
	node.name = box_name
	node.position = at
	node.size = size
	node.use_collision = true
	var material := StandardMaterial3D.new()
	material.albedo_color = MATERIALS[kind]
	node.material = material
	adopt(root, parent, node)
	return node

static func shot(root: Node, parent: Node, shot_name: String, at: Vector3, target: Vector3, fov: float) -> MapShot:
	var camera := MapShot.new()
	camera.name = shot_name
	camera.transform = Transform3D(Basis.looking_at(target - at), at)
	camera.fov = fov
	adopt(root, parent, camera)
	return camera

static func zone(root: Node, parent: Node, zone_name: String, camera: MapShot, center: Vector3, size: Vector3, priority: int = 0) -> MapZone:
	var node := MapZone.new()
	node.name = zone_name
	node.position = center
	node.camera = camera
	node.shot_priority = priority
	adopt(root, parent, node)
	var collision := CollisionShape3D.new()
	collision.name = "Box"
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	adopt(root, node, collision)
	return node
