extends SceneTree
## Copies an authored level into an editable map in maps/: its geometry with the
## same collision, its fixed cameras with their plates and crops, the boxes that
## cut between them, Dylan's start and the animals' places. Doors, terminals,
## cinematics and mission logic stay in the level's own script and are not
## copied; the original level is not touched.
##   godot --headless --path . --script res://tools/map_from_level.gd -- exterior [--force]
## Names: exterior, sala, perimetro, rele, patio-servico, percurso, or a
## res://….tscn path.

const LEVELS := {
	"exterior": "res://environments/exterior.tscn",
	"sala": "res://environments/save_room.tscn",
	"perimetro": "res://environments/perimeter.tscn",
	"rele": "res://environments/relay_room.tscn",
	"patio-servico": "res://environments/service_yard.tscn",
	"percurso": "res://environments/technical_route.tscn",
}

var level: Node
var map: MapRoot

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var force: bool = args.has("--force")
	var names: Array[String] = []
	for arg: String in args:
		if not arg.begins_with("--"):
			names.append(arg)
	if names.is_empty():
		push_error("Uso: --script res://tools/map_from_level.gd -- <%s|res://….tscn> [--force]" % "|".join(LEVELS.keys()))
		quit(1)
		return
	var key: String = names[0]
	var level_path: String = LEVELS.get(key, key)
	var map_name: String = key if LEVELS.has(key) else level_path.get_file().get_basename()
	var out_path: String = "res://maps/%s.tscn" % map_name.replace("-", "_")
	if FileAccess.file_exists(out_path) and not force:
		push_error("Já existe: %s. Use --force para recriar a partir da fase (perde edições)." % out_path)
		quit(1)
		return
	var scene: PackedScene = load(level_path) as PackedScene
	if scene == null:
		push_error("Fase não encontrada: %s" % level_path)
		quit(1)
		return
	level = scene.instantiate()
	root.add_child(level)
	for _frame: int in range(3):
		await process_frame
	if level.has_method("set_art_mode"):
		level.set_art_mode(false)
	map = MapRoot.new()
	map.name = map_name.to_pascal_case()
	map.map_title = map_name.capitalize()
	# In the tree, so global transforms resolve while the copy is put together.
	root.add_child(map)
	var world: Node3D = level.get_node("Frame/Composition/Actors/WorldViewport/World")
	var environment_node: WorldEnvironment = world.get_node_or_null("Environment")
	if environment_node and environment_node.environment.ambient_light_source == Environment.AMBIENT_SOURCE_COLOR:
		map.ambient_color = environment_node.environment.ambient_light_color
		map.ambient_energy = environment_node.environment.ambient_light_energy
	var geometry := Node3D.new()
	geometry.name = "Geometry"
	adopt(map, geometry)
	var source: Node3D = level.get("source") if level.get("source") is Node3D else world.get_node_or_null("AuthoredGeometry")
	var solid_names := {}
	if source:
		var copy: Node3D = source.duplicate()
		copy.name = "Source"
		# A local copy, not an instance of the level's source: edits stay in the map.
		copy.scene_file_path = ""
		copy.visible = true
		copy.transform = source.global_transform
		adopt(geometry, copy)
		for node: Node in copy.find_children("*", "", true, false):
			if node.has_meta("collision_size") or node.has_meta("collision_points"):
				solid_names[node.name] = true
	# Bodies the level adds on its own, not derived from a mesh: bounds and the like.
	var colliders: Node = level.get("colliders")
	if colliders:
		var extra := Node3D.new()
		extra.name = "ExtraCollision"
		adopt(geometry, extra)
		for body: Node in colliders.get_children():
			if body is StaticBody3D and not solid_names.has(body.name):
				var copy: StaticBody3D = body.duplicate()
				copy.transform = body.global_transform
				adopt(extra, copy)
	var shots_node := Node3D.new()
	shots_node.name = "Shots"
	adopt(map, shots_node)
	var by_rig := {}
	var rigs: Array = level.get("shots") if level.get("shots") is Array else []
	for rig: Variant in rigs:
		by_rig[rig] = add_shot(shots_node, rig.definition)
	if rigs.is_empty():
		var constants: Dictionary = level.get_script().get_script_constant_map()
		if constants.get("SHOT") is ShotDefinition:
			by_rig[null] = add_shot(shots_node, constants["SHOT"])
		elif level.get("camera") is Camera3D:
			# One fixed camera posed in code: take its pose and the plate on screen.
			var camera: Camera3D = level.get("camera")
			var definition := ShotDefinition.new()
			definition.shot_id = &"shot_1"
			definition.camera_position = camera.global_position
			var euler: Vector3 = camera.global_basis.get_euler()
			definition.camera_rotation_degrees = Vector3(rad_to_deg(euler.x), rad_to_deg(euler.y), rad_to_deg(euler.z))
			definition.fov = camera.fov
			var plate: TextureRect = level.get_node_or_null("Frame/Composition/Background")
			if plate and plate.texture and not plate.texture.resource_path.ends_with("composition_study.svg"):
				definition.background = plate.texture
			by_rig[null] = add_shot(shots_node, definition)
	var zones_node := Node3D.new()
	zones_node.name = "Zones"
	adopt(map, zones_node)
	for zone: Node in world.find_children("*", "CameraZone", true, false):
		if not by_rig.has(zone.shot):
			continue
		var copy := MapZone.new()
		copy.name = "Zone_%s" % by_rig[zone.shot].name
		copy.transform = zone.global_transform
		copy.camera = by_rig[zone.shot]
		copy.shot_priority = zone.shot_priority
		adopt(zones_node, copy)
		for child: Node in zone.get_children():
			if child is CollisionShape3D:
				var shape: CollisionShape3D = child.duplicate()
				shape.shape = child.shape.duplicate()
				adopt(copy, shape)
	if zones_node.get_child_count() == 0 and not by_rig.is_empty():
		cover_with_one_zone(zones_node, by_rig.values()[0], geometry)
	var player: PlayerController = world.get_node_or_null("Player")
	var start := Marker3D.new()
	start.name = "PlayerStart"
	start.transform = player.spawn_transform if player else Transform3D.IDENTITY
	adopt(map, start)
	var count: int = 0
	for animal: Node in world.find_children("*", "KelekenActor", true, false):
		count += 1
		var marker := Marker3D.new()
		marker.name = "Keleken%d" % count
		marker.position = animal.global_position
		adopt(map, marker)
	var packed := PackedScene.new()
	var error: int = packed.pack(map)
	if error == OK:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://maps"))
		error = ResourceSaver.save(packed, out_path)
	print("MAP from %s -> %s shots=%d zones=%d animals=%d error=%d" % [level_path, out_path, by_rig.size(), zones_node.get_child_count(), count, error])
	map.free()
	level.queue_free()
	quit(0 if error == OK else 1)

func add_shot(parent: Node, definition: ShotDefinition) -> MapShot:
	var camera := MapShot.new()
	camera.name = String(definition.shot_id).to_pascal_case()
	camera.position = definition.camera_position
	camera.rotation_degrees = definition.camera_rotation_degrees
	camera.fov = definition.fov
	camera.background = definition.background
	camera.zoom = definition.zoom
	camera.focus = definition.focus
	adopt(parent, camera)
	return camera

## A level with a single framing and no zones: one box over all its geometry.
func cover_with_one_zone(parent: Node, camera: MapShot, geometry: Node3D) -> void:
	var bounds := AABB()
	var first: bool = true
	for node: Node in geometry.find_children("*", "MeshInstance3D", true, false):
		var box: AABB = node.global_transform * node.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	var zone := MapZone.new()
	zone.name = "Zone_%s" % camera.name
	zone.position = bounds.get_center()
	zone.camera = camera
	adopt(parent, zone)
	var collision := CollisionShape3D.new()
	collision.name = "Box"
	var shape := BoxShape3D.new()
	shape.size = bounds.size + Vector3(2, 4, 2)
	collision.shape = shape
	adopt(zone, collision)

## Adds `child` under `parent` and makes it and everything under it part of the
## saved map.
func adopt(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = map
	for node: Node in child.find_children("*", "", true, false):
		node.owner = map
