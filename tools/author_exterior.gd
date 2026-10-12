extends SceneTree
## One authored spatial source drives all exterior cameras and physics.
const OUT := "res://assets/backgrounds/env_1/exterior_authored"
const POSES := [Vector3(6,8,27),Vector3(9,10,16),Vector3(2,7.5,12)]
const TARGETS := [Vector3(0,0.7,18),Vector3(-1,1,7),Vector3(-4.8,1.2,3.4)]
const FOVS := [52.0,52.0,50.0]
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

func tree(index: int, at: Vector3, height: float) -> void:
	box("PineTrunk%02d" % index,at+Vector3(0,height*0.4,0),Vector3(0.35,height*0.8,0.35),Color("44494b"),true)
	for tier: int in range(3):
		var y: float = height*(0.35+tier*0.2)
		var radius: float = height*(0.25-tier*0.05)
		cone("Pine%02d_%d" % [index,tier],at+Vector3(0,y,0),radius,height*0.48,Color("263c40"))
		cone("PineSnow%02d_%d" % [index,tier],at+Vector3(0,y+height*0.055,0),radius*0.83,height*0.43,Color("a9bcc5"))

func build_source() -> void:
	source = Node3D.new()
	source.name = "ExteriorSource"
	root.add_child(source)
	box("Terrain",Vector3(0,-0.15,10),Vector3(80,0.3,80),Color("b2bfcb"),true)
	box("ServiceRoad",Vector3(0,0.015,10),Vector3(5,0.03,44),Color("637783"))
	box("DoorApproach",Vector3(-3.3,0.018,6),Vector3(6.6,0.035,2.5),Color("7d8c95"))
	for x: float in [-0.85,0.85]:
		box("TireTrack",Vector3(x,0.035,10),Vector3(0.32,0.012,44),Color("485e69"))
	for x: float in [-3.2,3.2]:
		box("RoadSnowbank",Vector3(x,0.3,20),Vector3(1,0.6,20),Color("d0dbe0"),true)
		box("RoadRail",Vector3(x,0.95,20),Vector3(0.12,0.18,20),Color("59666c"),true)
		for z: int in range(10,31,3):
			box("RailPost",Vector3(x,0.6,z),Vector3(0.16,1.2,0.16),Color("55636a"),true)
	# The distant end and the fenced perimeter are visible physical boundaries.
	box("RoadEndBank",Vector3(0,0.45,29),Vector3(6.5,0.9,1),Color("d0dbe0"),true)
	box("NorthPerimeter",Vector3(0,1,-7),Vector3(24,2,0.15),Color("536570"),true)
	box("WestPerimeter",Vector3(-11,1,1.5),Vector3(0.15,2,17),Color("536570"),true)
	box("EastPerimeter",Vector3(6,1,1.5),Vector3(0.15,2,17),Color("536570"),true)
	box("SouthPerimeterLeft",Vector3(-7.5,1,10),Vector3(9.4,2,0.15),Color("536570"),true)
	box("SouthPerimeterRight",Vector3(4.5,1,10),Vector3(3.4,2,0.15),Color("536570"),true)
	for x: float in [-2.7,2.7]:
		box("GatePost",Vector3(x,1,10),Vector3(0.3,2,0.3),Color("505e63"),true)
	box("GateMotor",Vector3(2.7,0.6,9.5),Vector3(0.55,1.2,0.55),Color("8f9279"),true)
	var arm := box("RaisedBarrier",Vector3(1.7,2.7,10),Vector3(3.6,0.16,0.16),Color("d2c794"),true)
	arm.rotation.z = deg_to_rad(123.69)
	# The pole stays a visual and depth occluder only: the painted plate places it
	# 33-63 px from the geometry, so a collider there blocks where nothing is drawn.
	box("LightPole",Vector3(5.5,2.7,8.9),Vector3(0.18,5.4,0.18),Color("4c5b65"))
	box("PoleLamp",Vector3(5,5.35,8.9),Vector3(1.1,0.16,0.35),Color("ecdfa7"))
	# Matches the interior's 6x5 m plan after a 90 degree rotation, floor y=0.6.
	box("Guardhouse",Vector3(-5,2.15,0),Vector3(5.4,3.1,6.4),Color("7d898f"),true)
	box("Foundation",Vector3(-5,0.3,0),Vector3(5.6,0.6,6.6),Color("5f6d76"),true)
	box("Roof",Vector3(-5,3.76,0),Vector3(5.85,0.14,6.85),Color("b7c8d1"))
	box("RoofAntenna",Vector3(-5.7,5.1,-1),Vector3(0.1,2.6,0.1),Color("52626a"))
	for y: float in [4.7,5.2,5.7]:
		box("AntennaCrossbar",Vector3(-5.7,y,-1),Vector3(1.2,0.06,0.06),Color("52626a"))
	box("Door",Vector3(-4.45,1.65,3.215),Vector3(1.1,2.1,0.035),Color("394c59"))
	box("DoorGlass",Vector3(-4.45,2.2,3.24),Vector3(0.32,0.42,0.02),Color("273a45"))
	box("DoorHandle",Vector3(-4.04,1.55,3.26),Vector3(0.2,0.05,0.05),Color("b9c0bb"))
	box("DoorLamp",Vector3(-4.45,2.9,3.28),Vector3(0.7,0.12,0.16),Color("f4dfa0"))
	box("FrontWindowFrame",Vector3(-6.25,2.05,3.22),Vector3(0.9,1.1,0.05),Color("3c505b"))
	box("FrontWindowGlass",Vector3(-6.25,2.05,3.25),Vector3(0.72,0.92,0.02),Color("78988e"))
	box("SideWindow",Vector3(-2.285,2.05,-0.7),Vector3(0.035,1.05,1.9),Color("3f5a69"))
	box("Platform",Vector3(-4.45,0.3,3.95),Vector3(2.8,0.6,1.5),Color("83939f"),true)
	for step: int in range(6):
		var height: float = (step+1)*0.1
		box("Stair%d" % step,Vector3(-4.45,height*0.5,6.35-step*0.3),Vector3(1.5,height,0.3),Color("899ba6"))
	var ramp_points := PackedVector3Array([Vector3(-0.75,0,6.5),Vector3(0.75,0,6.5),Vector3(0.75,0.6,4.7),Vector3(-0.75,0.6,4.7),Vector3(-0.75,-0.1,6.5),Vector3(0.75,-0.1,6.5),Vector3(0.75,-0.1,4.7),Vector3(-0.75,-0.1,4.7)])
	var ramp := box("StairCollisionRamp",Vector3(-4.45,0,0),Vector3.ONE,Color.GRAY,false,false)
	ramp.set_meta("collision_points",ramp_points)
	for x: float in [-5.32,-3.58]:
		var rail := box("StairRail",Vector3(x,1,5.6),Vector3(0.06,0.08,1.92),Color("475e69"))
		rail.rotation.x = atan(0.6/1.8)
		for z: float in [4.75,6.45]:
			box("StairRailPost",Vector3(x,0.65 if z > 6 else 1,z),Vector3(0.06,1,0.06),Color("475e69"))
	box("CrateA",Vector3(-7.8,0.6,4.3),Vector3(1.3,1.2,1.2),Color("7a826d"),true)
	box("CrateB",Vector3(-8.2,0.4,5.7),Vector3(1.2,0.8,1.1),Color("747b67"),true)
	box("CrateSnow",Vector3(-7.8,1.22,4.3),Vector3(1.32,0.05,1.22),Color("c4d2da"))
	box("CabinApproachBank",Vector3(-9.6,0.35,7.9),Vector3(2.5,0.7,2.6),Color("c3d0d9"),true)
	# Trees never enter the authored walking route. Deterministic placements.
	var locations: Array[Vector3] = [Vector3(-5,0,27),Vector3(-6,0,23),Vector3(-5.5,0,19),Vector3(-6.1,0,15),Vector3(-8,0,12),Vector3(6,0,28),Vector3(6.5,0,24),Vector3(5.5,0,20),Vector3(6.4,0,16),Vector3(8,0,12),Vector3(-12,0,5),Vector3(-12,0,-1),Vector3(-10,0,-5),Vector3(-7,0,-7),Vector3(-3,0,-8),Vector3(1,0,-8),Vector3(5,0,-8),Vector3(8,0,-4),Vector3(9,0,2)]
	for index: int in range(locations.size()):
		tree(index,locations[index],5.5+(index%4)*0.7)
	var packed := PackedScene.new()
	assert(packed.pack(source) == OK)
	assert(ResourceSaver.save(packed,"res://environments/exterior_source.tscn") == OK)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Exterior capture requires graphical rendering")
		quit(1)
		return
	root.size = Vector2i(1920,1080)
	RenderingServer.set_default_clear_color(Color("243544"))
	DirAccess.make_dir_recursive_absolute(OUT)
	DirAccess.make_dir_recursive_absolute("res://resources/exterior")
	build_source()
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.make_current()
	var manifest: Array[Dictionary] = []
	for index: int in range(3):
		camera.position = POSES[index]
		camera.look_at(TARGETS[index])
		camera.fov = FOVS[index]
		var shot := ShotDefinition.new()
		shot.shot_id = StringName("exterior_%d" % (index+1))
		shot.camera_position = camera.position
		shot.camera_rotation_degrees = camera.rotation_degrees
		shot.fov = camera.fov
		assert(ResourceSaver.save(shot,"res://resources/exterior/shot_%d.tres" % (index+1)) == OK)
		for frame: int in range(8):
			await process_frame
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png(OUT+"/geometry_cam%02d.png" % (index+1)) == OK)
		var landmarks: Dictionary = {}
		for label: String in ["GateMotor","Door","FrontWindowFrame","Platform","CrateA","LightPole"]:
			var at: Vector3 = source.get_node(label).position
			var pixel: Vector2 = camera.unproject_position(at)
			landmarks[label] = {"world":[at.x,at.y,at.z],"pixel":[pixel.x,pixel.y],"behind_camera":camera.is_position_behind(at)}
		manifest.append({"shot":index+1,"position":[camera.position.x,camera.position.y,camera.position.z],"rotation_degrees":[camera.rotation_degrees.x,camera.rotation_degrees.y,camera.rotation_degrees.z],"fov":camera.fov,"landmarks":landmarks})
	var file := FileAccess.open(OUT+"/cameras.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"units":"meters","image_size":[1920,1080],"interior_origin":[-5,0.6,0],"interior_rotation_y_degrees":90,"shots":manifest},"\t"))
	print("EXTERIOR authored one spatial source + three fixed cameras + captures")
	quit()
