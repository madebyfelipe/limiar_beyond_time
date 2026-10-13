extends SceneTree
## Phase 2 — the perimeter trail north of the guardhouse yard. Geometry and
## cameras are authored first, as the exterior and the save room were, so the
## layout can be walked and probed long before any plate exists for it.
##   godot --headless --path . --script res://tools/author_perimeter.gd
## Captures are written only when a renderer is available; the geometry source
## and the three shot definitions are written either way.
const OUT := "res://assets/backgrounds/perimeter"
const POSES := [Vector3(7,7,-11.5),Vector3(6,8,-6),Vector3(7.4,7,-17)]
const TARGETS := [Vector3(0,1,-4),Vector3(1,1,-13),Vector3(0,1.2,-24)]
const FOVS := [54.0,48.0,52.0]
## The walking corridor: banks at x = +-3.2, gate at z = 0, shed at z = -29.
const TRAIL_LENGTH := 34.0
## Each framing was chosen to hold the whole walkable volume of its own camera
## zone at 1920x1080, with the actor between about 110 and 190 px tall and the
## near bank and shoulder clear of its middle. See PERIMETER.md.
var source: Node3D

func _initialize() -> void:
	call_deferred("run")

func material(color: Color) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	result.albedo_color = color
	return result

func box(label: String, at: Vector3, size: Vector3, color: Color, solid: bool = false, shown: bool = true) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material(color)
	var node := MeshInstance3D.new()
	node.name = label
	node.position = at
	node.mesh = mesh
	node.visible = shown
	if solid:
		node.set_meta("collision_size",size)
	source.add_child(node)
	node.owner = source
	return node

func cone(label: String, at: Vector3, radius: float, height: float, color: Color) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	mesh.material = material(color)
	var node := MeshInstance3D.new()
	node.name = label
	node.position = at
	node.mesh = mesh
	source.add_child(node)
	node.owner = source

## Decorative pines, always outside the corridor the player walks.
func tree(index: int, at: Vector3, height: float) -> void:
	box("PineTrunk%02d" % index,at+Vector3(0,height*0.4,0),Vector3(0.35,height*0.8,0.35),Color("44494b"))
	for tier: int in range(3):
		var y: float = height*(0.35+tier*0.2)
		var radius: float = height*(0.25-tier*0.05)
		cone("Pine%02d_%d" % [index,tier],at+Vector3(0,y,0),radius,height*0.48,Color("263c40"))
		cone("PineSnow%02d_%d" % [index,tier],at+Vector3(0,y+height*0.055,0),radius*0.83,height*0.43,Color("a9bcc5"))

func build_source() -> void:
	source = Node3D.new()
	source.name = "PerimeterSource"
	root.add_child(source)
	box("Terrain",Vector3(0,-0.15,-15),Vector3(44,0.3,70),Color("b2bfcb"),true)
	box("Trail",Vector3(0,0.015,-15),Vector3(5,0.03,TRAIL_LENGTH),Color("637783"))
	for x: float in [-0.85,0.85]:
		box("TrailTrack",Vector3(x,0.035,-15),Vector3(0.32,0.012,TRAIL_LENGTH),Color("485e69"))
	# The corridor is closed on both sides for its whole length: snow bank,
	# wire line and the rock shoulder that reads as the perimeter itself.
	for x: float in [-3.2,3.2]:
		box("TrailBank",Vector3(x,0.45,-15),Vector3(1,0.9,TRAIL_LENGTH),Color("d0dbe0"),true)
		box("RockShoulder",Vector3(x*1.45,1.2,-15),Vector3(1.6,2.4,TRAIL_LENGTH),Color("5b676e"),true)
		box("WireLine",Vector3(x,1.05,-15),Vector3(0.06,0.08,TRAIL_LENGTH),Color("59666c"))
		for z: int in range(0,-32,-4):
			box("WirePost",Vector3(x,0.6,z),Vector3(0.14,1.2,0.14),Color("55636a"))
	# South fence and the service gate back to the guardhouse yard.
	for x: float in [-7.4,7.4]:
		box("SouthFence",Vector3(x,1,0),Vector3(9.4,2,0.15),Color("536570"),true)
	for x: float in [-2.6,2.6]:
		box("GatePost",Vector3(x,1.05,0),Vector3(0.3,2.1,0.3),Color("505e63"),true)
	box("GateLeaf",Vector3(0,0.98,0),Vector3(4.95,1.86,0.12),Color("6d7b6a"),true)
	for y: float in [0.45,1.5]:
		box("GateRail",Vector3(0,y,0.08),Vector3(4.9,0.1,0.06),Color("8a9480"))
	box("GateSign",Vector3(1.6,1.6,0.1),Vector3(0.8,0.5,0.04),Color("c7b672"))
	# The pen stretch: where the animal is kept, between z = -10 and z = -19.
	for z: float in [-10.0,-19.0]:
		for x: float in [-2.85,2.85]:
			box("PenPost",Vector3(x,0.75,z),Vector3(0.2,1.5,0.2),Color("5d5f55"))
		box("PenBeam",Vector3(0,1.4,z),Vector3(5.8,0.12,0.1),Color("5d5f55"))
	box("FeedTrough",Vector3(2.75,0.3,-12),Vector3(0.8,0.6,2.4),Color("6f7560"),true)
	box("TroughSnow",Vector3(2.75,0.62,-12),Vector3(0.82,0.04,2.42),Color("c4d2da"))
	box("StrawBed",Vector3(-2.3,0.025,-16.5),Vector3(1.7,0.05,3.2),Color("8d8663"))
	box("CrateA",Vector3(2.55,0.5,-8.4),Vector3(1.1,1,1.1),Color("7a826d"),true)
	box("CrateSnow",Vector3(2.55,1.02,-8.4),Vector3(1.12,0.05,1.12),Color("c4d2da"))
	box("CrateB",Vector3(-2.6,0.4,-21.8),Vector3(1,0.8,1.2),Color("747b67"),true)
	# A pine came down across the trail and leaves one way past it.
	var trunk := box("FallenPine",Vector3(-1.35,0.5,-22.6),Vector3(3.7,0.8,0.6),Color("4a4f4a"),true)
	trunk.rotation.y = deg_to_rad(6)
	box("FallenPineSnow",Vector3(-1.35,0.92,-22.6),Vector3(3.6,0.06,0.58),Color("c4d2da"))
	# Relay shed: the north cap of the corridor and the end of this content.
	box("RelayShed",Vector3(0,1.7,-29.4),Vector3(6.6,3.4,5),Color("79858b"),true)
	box("RelayFoundation",Vector3(0,0.2,-29.4),Vector3(6.8,0.4,5.2),Color("5f6d76"),true)
	box("RelayRoof",Vector3(0,3.47,-29.4),Vector3(7,0.14,5.4),Color("b7c8d1"))
	box("RelayDoor",Vector3(0,1.15,-26.86),Vector3(1.1,2.1,0.06),Color("394c59"))
	box("RelaySealPlate",Vector3(0,1.5,-26.8),Vector3(0.9,0.42,0.05),Color("b8ab6b"))
	box("RelayHandle",Vector3(0.41,1.05,-26.8),Vector3(0.2,0.05,0.05),Color("b9c0bb"))
	box("RelayLamp",Vector3(0,2.4,-26.78),Vector3(0.7,0.12,0.16),Color("f4dfa0"))
	box("RelayStep",Vector3(0,0.1,-26.45),Vector3(2.2,0.2,0.8),Color("899ba6"),true)
	box("RelayMast",Vector3(-2.4,4.7,-29.4),Vector3(0.12,2.6,0.12),Color("52626a"))
	for y: float in [4.3,4.8,5.3]:
		box("MastCrossbar",Vector3(-2.4,y,-29.4),Vector3(1.2,0.06,0.06),Color("52626a"))
	box("RelayDrum",Vector3(2.6,0.45,-26.6),Vector3(0.7,0.9,0.7),Color("6a6f62"),true)
	# Tree line outside both shoulders. Deterministic placements.
	var index: int = 0
	for z: int in range(-2,-32,-5):
		for x: float in [-12.0,12.0]:
			tree(index,Vector3(x,0,z),5.2+(index%4)*0.6)
			index += 1
	for x: float in [-6.5,0.0,6.5]:
		tree(index,Vector3(x,0,-33.5),5.4+(index%3)*0.5)
		index += 1
	var packed := PackedScene.new()
	assert(packed.pack(source) == OK)
	assert(ResourceSaver.save(packed,"res://environments/perimeter_source.tscn") == OK)

func run() -> void:
	var graphical: bool = DisplayServer.get_name() != "headless"
	DirAccess.make_dir_recursive_absolute("res://resources/perimeter")
	if graphical:
		root.size = Vector2i(1920,1080)
		RenderingServer.set_default_clear_color(Color("243544"))
		DirAccess.make_dir_recursive_absolute(OUT)
	build_source()
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("b6c5d1")
	environment.environment.ambient_light_energy = 0.65
	root.add_child(environment)
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.make_current()
	var manifest: Array[Dictionary] = []
	for shot_index: int in range(3):
		camera.position = POSES[shot_index]
		camera.look_at(TARGETS[shot_index])
		camera.fov = FOVS[shot_index]
		var shot := ShotDefinition.new()
		var shot_path: String = "res://resources/perimeter/shot_%d.tres" % (shot_index+1)
		# The projective crop of a framing is tuned by hand against its plate.
		# Authoring the camera again must not throw that decision away.
		if ResourceLoader.exists(shot_path):
			var previous: ShotDefinition = load(shot_path)
			shot.zoom = previous.zoom
			shot.focus = previous.focus
		shot.shot_id = StringName("perimeter_%d" % (shot_index+1))
		shot.camera_position = camera.position
		shot.camera_rotation_degrees = camera.rotation_degrees
		shot.fov = camera.fov
		assert(ResourceSaver.save(shot,shot_path) == OK)
		var landmarks: Dictionary = {}
		for label: String in ["GateLeaf","FeedTrough","FallenPine","RelayDoor","CrateA"]:
			var at: Vector3 = source.get_node(label).position
			var pixel: Vector2 = camera.unproject_position(at)
			landmarks[label] = {"world":[at.x,at.y,at.z],"pixel":[pixel.x,pixel.y],"behind_camera":camera.is_position_behind(at)}
		manifest.append({"shot":shot_index+1,"position":[camera.position.x,camera.position.y,camera.position.z],"rotation_degrees":[camera.rotation_degrees.x,camera.rotation_degrees.y,camera.rotation_degrees.z],"fov":camera.fov,"landmarks":landmarks})
		if graphical:
			for frame: int in range(8):
				await process_frame
			await RenderingServer.frame_post_draw
			assert(root.get_texture().get_image().save_png(OUT+"/geometry_cam%02d.png" % (shot_index+1)) == OK)
	if graphical:
		var file := FileAccess.open(OUT+"/cameras.json",FileAccess.WRITE)
		file.store_string(JSON.stringify({"units":"meters","image_size":[1920,1080],"yard_gate_world":[0,0,-7],"shots":manifest},"\t"))
	print("PERIMETER authored one spatial source + three fixed cameras%s" % (" + captures" if graphical else " (geometry only, no renderer)"))
	quit()
