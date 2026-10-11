extends SceneTree
## Author geometry and camera first, then capture the actual 3D viewport.
const OUT := "res://assets/backgrounds/env_1/save_room"
var source: Node3D

func _initialize() -> void:
	call_deferred("run")

func box(label: String, at: Vector3, size: Vector3, color: Color, solid: bool = false, shown: bool = true) -> MeshInstance3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.roughness = 0.9
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = mat
	var node := MeshInstance3D.new()
	node.name = label
	node.position = at
	node.mesh = mesh
	node.visible = shown
	if solid:
		node.set_meta("collision_size", size)
	source.add_child(node)
	node.owner = source
	return node

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Authoring needs a graphical renderer")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(OUT)
	DirAccess.make_dir_recursive_absolute("res://resources/save_room")
	root.size = Vector2i(1920,1080)
	RenderingServer.set_default_clear_color(Color("18212a"))
	source = Node3D.new()
	source.name = "SaveRoomSource"
	root.add_child(source)
	box("Floor", Vector3(0,-0.15,0),Vector3(6,0.3,5),Color("77756f"),true)
	box("WestWall",Vector3(-3.1,1.55,0),Vector3(0.2,3.1,5.4),Color("898d8a"),true)
	box("NorthWall",Vector3(0,1.55,-2.6),Vector3(6,3.1,0.2),Color("969b96"),true)
	box("EastBoundary",Vector3(3.1,1.55,0),Vector3(0.2,3.1,5.4),Color.GRAY,true,false)
	box("SouthBoundary",Vector3(0,1.55,2.6),Vector3(6,3.1,0.2),Color.GRAY,true,false)
	for x: int in range(12):
		for z: int in range(10):
			var tint := Color("969186") if (x+z)%2 == 0 else Color("858175")
			box("Tile_%d_%d" % [x,z],Vector3(-2.75+x*0.5,0.006,-2.25+z*0.5),Vector3(0.49,0.012,0.49),tint)
	box("EntranceDoor",Vector3(-2.975,1.05,0.55),Vector3(0.04,2.1,1.1),Color("454f55"))
	box("DoorInset",Vector3(-2.94,1.65,0.55),Vector3(0.025,0.42,0.32),Color("293b44"))
	box("DoorHandle",Vector3(-2.9,0.95,0.98),Vector3(0.1,0.06,0.2),Color("b2b4ab"))
	box("EntranceMat",Vector3(-2.45,0.017,0.55),Vector3(0.85,0.025,1.25),Color("3f4442"))
	box("DoorLight",Vector3(-2.94,2.4,0.55),Vector3(0.1,0.12,0.7),Color("f3dfa4"))
	box("WindowFrame",Vector3(0.7,2.05,-2.475),Vector3(1.9,1.05,0.06),Color("454c50"))
	box("WindowGlass",Vector3(0.7,2.05,-2.43),Vector3(1.7,0.88,0.025),Color("4e7187"))
	box("WindowDivider",Vector3(0.7,2.05,-2.4),Vector3(0.045,0.94,0.035),Color("454c50"))
	box("Locker",Vector3(-2.12,1.02,-2.0),Vector3(0.9,2.04,0.85),Color("596761"),true)
	box("LockerDivider",Vector3(-2.12,1.03,-1.56),Vector3(0.025,1.92,0.035),Color("283831"))
	box("Desk",Vector3(0.6,0.4,-1.98),Vector3(2.4,0.8,0.85),Color("677277"),true)
	box("DeskTop",Vector3(0.6,0.82,-1.98),Vector3(2.48,0.06,0.9),Color("a6a191"))
	box("Monitor",Vector3(0.4,1.12,-2.08),Vector3(0.6,0.55,0.45),Color("525f5d"))
	box("MonitorScreen",Vector3(0.4,1.14,-1.845),Vector3(0.47,0.35,0.018),Color("5ea689"))
	box("Keyboard",Vector3(0.4,0.88,-1.7),Vector3(0.57,0.05,0.17),Color("cbc7b0"))
	box("Radio",Vector3(1.36,1.02,-2.06),Vector3(0.55,0.34,0.4),Color("4d5650"))
	box("ChairSeat",Vector3(0.55,0.48,-1.16),Vector3(0.55,0.12,0.5),Color("3b4342"),true)
	box("ChairBack",Vector3(0.55,0.84,-0.93),Vector3(0.55,0.65,0.1),Color("3b4342"))
	box("ChairStem",Vector3(0.55,0.24,-1.16),Vector3(0.08,0.48,0.08),Color("454e4f"))
	box("Shelf",Vector3(2.55,0.96,-1.4),Vector3(0.65,1.92,1.15),Color("5c656a"),true)
	for height: float in [0.05,0.65,1.25,1.92]:
		box("ShelfLip",Vector3(2.19,height,-1.4),Vector3(0.06,0.06,1.17),Color("abb0aa"))
	box("SupplyChest",Vector3(-2.5,0.32,1.82),Vector3(0.75,0.64,0.9),Color("6d7760"),true)
	var packed := PackedScene.new()
	assert(packed.pack(source) == OK)
	assert(ResourceSaver.save(packed,"res://environments/save_room_source.tscn") == OK)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("b6c5d1")
	environment.environment.ambient_light_energy = 0.65
	root.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-60,-25,0)
	light.light_energy = 1.0
	root.add_child(light)
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.position = Vector3(2.8,2.9,2.35)
	camera.look_at(Vector3(-0.5,0.9,-0.7))
	camera.fov = 45
	camera.make_current()
	var definition := ShotDefinition.new()
	definition.shot_id = &"save_room_01"
	definition.camera_position = camera.position
	definition.camera_rotation_degrees = camera.rotation_degrees
	definition.fov = camera.fov
	assert(ResourceSaver.save(definition,"res://resources/save_room/shot_01.tres") == OK)
	for frame: int in range(12):
		await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(OUT+"/geometry_cam01.png") == OK)
	var manifest := FileAccess.open(OUT+"/camera.json",FileAccess.WRITE)
	var landmarks: Dictionary = {}
	for point: String in ["EntranceDoor","Locker","Desk","WindowFrame","SupplyChest","Shelf"]:
		var mesh: MeshInstance3D = source.get_node(point)
		var pixel: Vector2 = camera.unproject_position(mesh.position)
		landmarks[point] = {"world":[mesh.position.x,mesh.position.y,mesh.position.z],"pixel":[pixel.x,pixel.y]}
	manifest.store_string(JSON.stringify({"units":"meters","room_inner_size":[6,3.1,5],"image_size":[1920,1080],"camera_position":[camera.position.x,camera.position.y,camera.position.z],"camera_rotation_degrees":[camera.rotation_degrees.x,camera.rotation_degrees.y,camera.rotation_degrees.z],"fov":camera.fov,"landmarks":landmarks},"\t"))
	print("SAVE_ROOM authored geometry + camera + 1920x1080 capture")
	quit()
