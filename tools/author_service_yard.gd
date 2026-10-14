extends SceneTree
## Environment 5 — the service yard behind the relay shed. Basic geometry only:
## what stops the actor and where the ground leads. Authored before any plate,
## as the trail was, so the space can be walked and measured first.
##   godot --headless --path . --script res://tools/author_service_yard.gd
## Captures (one per framing and a plan seen from above) are written only when
## a renderer is available; the geometry source and the four shot definitions
## are written either way.
##
## The yard keeps the trail's coordinates: north is -z, the shed's back wall is
## at z = -31,9 and its rear door at x = 2,4. It is the site plan of `AreaMap`
## at 4/3 of its schematic metres: 24 x 18,5 m, and a 6,5 x 10,5 m arm running
## north along the generator house.
const OUT := "res://assets/backgrounds/service_yard"
## Four framings that all look east, so up the screen is east in every one of
## them and the stick keeps its meaning across the cuts. Each camera hangs west
## of its own strip of the yard: the buildings it faces are its backdrop, and
## nothing tall stands between it and the ground it covers.
const POSES := [Vector3(-21.25,10.5,-41.25),Vector3(-27.8,9.5,-41.725),Vector3(-13.25,10.5,-41.25),Vector3(-19.8,11.0,-55.275)]
const TARGETS := [Vector3(-5.75,0.9,-41.25),Vector3(-12.8,0.9,-41.725),Vector3(2.25,0.9,-41.25),Vector3(-9.8,0.9,-55.275)]
## Chosen by sweep: feet and head inside the frame with margin on all the
## ground of the strip, the actor 116 to 199 px tall.
const FOVS := [32.0,35.0,32.0,30.0]
const SHOT_IDS := [&"service_yard_mid",&"service_yard_west",&"service_yard_east",&"service_yard_arm"]
const WEST := -12.0
const EAST := 12.0
const SOUTH := -32.0
const NORTH := -50.5
const ARM_EAST := -5.5
const ARM_NORTH := -61.0
const SNOW := Color("c4d2da")
const STEEL := Color("536570")
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

## Decorative pines, always outside the fence.
func tree(index: int, at: Vector3, height: float) -> void:
	box("PineTrunk%02d" % index,at+Vector3(0,height*0.4,0),Vector3(0.35,height*0.8,0.35),Color("44494b"))
	for tier: int in range(3):
		var y: float = height*(0.35+tier*0.2)
		var radius: float = height*(0.25-tier*0.05)
		cone("Pine%02d_%d" % [index,tier],at+Vector3(0,y,0),radius,height*0.48,Color("263c40"))
		cone("PineSnow%02d_%d" % [index,tier],at+Vector3(0,y+height*0.055,0),radius*0.83,height*0.43,SNOW)

## What actually stops the actor along a fence line. Hidden: a mesh this tall
## would stand between the west cameras and the ground they cover, and the
## posts and rails of `fence_run` are what the eye reads as the fence.
func fence_bound(label: String, from: Vector2, to: Vector2) -> void:
	var centre: Vector2 = (from+to)*0.5
	var span: Vector2 = (to-from).abs()
	box(label,Vector3(centre.x,1.5,centre.y),Vector3(maxf(span.x,0.4),3,maxf(span.y,0.4)),STEEL,true,false)

## Posts and two rails. Drawn only: `fence_bound` carries the collision, so a
## run can stop short of a breach while the bound behind it stays whole.
func fence_run(label: String, from: Vector2, to: Vector2) -> void:
	var length: float = from.distance_to(to)
	var centre: Vector2 = (from+to)*0.5
	var along_x: bool = absf(to.x-from.x) > absf(to.y-from.y)
	for y: float in [1.2,2.3]:
		box(label+"Rail",Vector3(centre.x,y,centre.y),Vector3(length if along_x else 0.06,0.06,0.06 if along_x else length),STEEL)
	var posts: int = maxi(1,roundi(length/3.0))
	for index: int in range(posts+1):
		var at: Vector2 = from.lerp(to,float(index)/posts)
		box(label+"Post",Vector3(at.x,1.2,at.y),Vector3(0.12,2.4,0.12),Color("55636a"))

## A stretch of fence brought down from outside: where the animals come in.
## The panel lies inward on the snow and the bound behind it is still closed;
## the scene that lets them through is the one that opens it.
func breach(label: String, at: Vector2, inward: Vector2) -> void:
	var across: bool = absf(inward.x) > 0.5
	var panel := box(label+"Panel",Vector3(at.x+inward.x*0.9,0.3,at.y+inward.y*0.9),Vector3(2.0 if across else 2.5,0.06,2.5 if across else 2.0),STEEL)
	if across:
		panel.rotation.z = -signf(inward.x)*deg_to_rad(16)
	else:
		panel.rotation.x = signf(inward.y)*deg_to_rad(16)
	box(label+"Trample",Vector3(at.x+inward.x*1.6,0.02,at.y+inward.y*1.6),Vector3(3.2 if across else 2.5,0.03,2.5 if across else 3.2),Color("485e69"))

func building(label: String, at: Vector3, size: Vector3, color: Color) -> void:
	box(label,at,size,color,true)
	box(label+"Roof",at+Vector3(0,size.y*0.5+0.07,0),Vector3(size.x+0.4,0.14,size.z+0.4),Color("b7c8d1"))

func build_source() -> void:
	source = Node3D.new()
	source.name = "ServiceYardSource"
	root.add_child(source)
	box("Terrain",Vector3(2,-0.15,-45),Vector3(56,0.3,50),Color("b2bfcb"),true)
	# The way through: a packed track from the shed's rear door to each of the
	# four doors of the yard. Drawn only; it is where the snow has been driven on.
	for part: Array in [
		["TrackSpine",Vector3(1.85,0.015,-41.25),Vector3(3,0.03,18.1)],
		["TrackEast",Vector3(6.825,0.015,-41.9),Vector3(9.95,0.03,2.6)],
		["TrackWest",Vector3(-3.075,0.015,-44.5),Vector3(9.85,0.03,2.6)],
		["TrackArm",Vector3(-6.8,0.015,-51.25),Vector3(2.4,0.03,13.5)],
		["TrackKennel",Vector3(-4.325,0.015,-33.9),Vector3(12.35,0.03,2.6)],
	]:
		box(part[0],part[1],part[2],Color("637783"))
	# --- South side: the shed Dylan comes out of, and the kennel block ---
	building("RelayShed",Vector3(0,1.7,-29.4),Vector3(6.6,3.4,5),Color("79858b"))
	box("RelayFoundation",Vector3(0,0.2,-29.455),Vector3(6.8,0.4,5.09),Color("5f6d76"),true)
	box("RelayRearDoor",Vector3(2.4,1.425,-31.95),Vector3(0.9,2.05,0.1),Color("394c59"))
	box("RelayRearSill",Vector3(2.4,0.02,-32.25),Vector3(1.1,0.04,0.5),Color("5f6d76"))
	box("RelayRearLamp",Vector3(2.4,2.7,-31.98),Vector3(0.7,0.12,0.16),Color("f4dfa0"))
	building("KennelBlock",Vector3(-10.35,1.5,-28.5),Vector3(8.7,3,7),Color("6f7b80"))
	box("KennelDoor",Vector3(-9.3,1.05,-32.03),Vector3(1.1,2.1,0.06),Color("394c59"))
	# --- East side: the crew quarters, the second safe room ---
	building("CrewQuarters",Vector3(16,1.6,-41.9),Vector3(8,3.2,6.6),Color("7d8a86"))
	box("QuartersDoor",Vector3(11.97,1.05,-41.9),Vector3(0.06,2.1,1.1),Color("394c59"))
	box("QuartersLamp",Vector3(11.9,2.5,-41.9),Vector3(0.16,0.12,0.7),Color("f4dfa0"))
	# --- North side: the generator house, with a door on the yard and one in the arm ---
	building("GeneratorHouse",Vector3(0.5,2.1,-56),Vector3(12,4.2,11),Color("6c777d"))
	box("GeneratorFrontDoor",Vector3(1.3,1.05,-50.47),Vector3(1.3,2.1,0.06),Color("394c59"))
	box("GeneratorSideDoor",Vector3(-5.53,1.05,-55.75),Vector3(0.06,2.1,1.1),Color("394c59"))
	box("GeneratorLamp",Vector3(1.3,2.6,-50.42),Vector3(0.7,0.12,0.16),Color("f4dfa0"))
	box("GeneratorStack",Vector3(4.5,5.2,-57),Vector3(0.5,2,0.5),Color("52626a"))
	# --- The fence: every side the buildings leave open ---
	fence_bound("WestBound",Vector2(WEST,SOUTH),Vector2(WEST,ARM_NORTH))
	fence_bound("ArmNorthBound",Vector2(WEST,ARM_NORTH),Vector2(ARM_EAST,ARM_NORTH))
	fence_bound("SouthGapBound",Vector2(-6,SOUTH),Vector2(-3.3,SOUTH))
	fence_bound("SouthEastBound",Vector2(3.3,SOUTH),Vector2(EAST,SOUTH))
	fence_bound("EastSouthBound",Vector2(EAST,SOUTH),Vector2(EAST,-38.6))
	fence_bound("EastNorthBound",Vector2(EAST,-45.2),Vector2(EAST,NORTH))
	fence_bound("NorthEastBound",Vector2(6.5,NORTH),Vector2(EAST,NORTH))
	fence_run("WestFenceA",Vector2(WEST,SOUTH),Vector2(WEST,-45))
	fence_run("WestFenceB",Vector2(WEST,-47.5),Vector2(WEST,ARM_NORTH))
	fence_run("ArmFenceA",Vector2(WEST,ARM_NORTH),Vector2(-10,ARM_NORTH))
	fence_run("ArmFenceB",Vector2(-7.5,ARM_NORTH),Vector2(ARM_EAST,ARM_NORTH))
	fence_run("SouthGapFence",Vector2(-6,SOUTH),Vector2(-3.3,SOUTH))
	fence_run("SouthEastFence",Vector2(3.3,SOUTH),Vector2(EAST,SOUTH))
	fence_run("EastSouthFence",Vector2(EAST,SOUTH),Vector2(EAST,-38.6))
	fence_run("EastNorthFence",Vector2(EAST,-45.2),Vector2(EAST,NORTH))
	fence_run("NorthEastFenceA",Vector2(6.5,NORTH),Vector2(8,NORTH))
	fence_run("NorthEastFenceB",Vector2(10.5,NORTH),Vector2(EAST,NORTH))
	# Three ways in for the animals, on three sides of the open ground and all
	# further from the rear door than an animal perceives.
	breach("BreachWest",Vector2(WEST,-46.25),Vector2(1,0))
	breach("BreachNorthEast",Vector2(9.25,NORTH),Vector2(0,1))
	breach("BreachArm",Vector2(-8.75,ARM_NORTH),Vector2(0,1))
	# --- Tall cover: it breaks an animal's line of sight (eye at 1,6 m) ---
	# Both lie east-west, end on to the cameras, so each hides a strip of ground
	# no wider than itself. Every one is an island: there is a lane all round.
	# The truck's cab is its west end, the one the middle camera does not look
	# over: the load is the lower of the two, so a body east of it keeps its head.
	box("TruckCab",Vector3(-8.3,1.3,-41.2),Vector3(1.8,2.6,2.3),Color("5d6a6c"),true)
	box("TruckLoad",Vector3(-5.1,1.0,-41.2),Vector3(4.6,2.0,2.4),Color("6d7b6a"),true)
	box("TruckCabSnow",Vector3(-8.3,2.63,-41.2),Vector3(1.76,0.06,2.26),SNOW)
	box("TruckLoadSnow",Vector3(-5.1,2.03,-41.2),Vector3(4.56,0.06,2.36),SNOW)
	# Two metres, not a container's 2,6: still over an animal's eye, and low
	# enough that the east camera, which sees it at a slant, keeps the actor's head.
	box("FuelTank",Vector3(6.7,1.0,-37),Vector3(5,2.0,2.4),Color("7a6f5c"),true)
	box("FuelTankSnow",Vector3(6.7,2.03,-37),Vector3(4.96,0.06,2.36),SNOW)
	# --- Low cover: a metre high or less, it stops the body and not the eye ---
	box("CrateStack",Vector3(-7,0.5,-36.25),Vector3(2,1,1.5),Color("7a826d"),true)
	box("Pallets",Vector3(-1.75,0.45,-36.45),Vector3(1.5,0.9,1.5),Color("8b8672"),true)
	box("Drums",Vector3(-4.3,0.45,-49.8),Vector3(2,0.9,1),Color("6a6f62"),true)
	box("BarrierWest",Vector3(-7.75,0.45,-46.6),Vector3(2.5,0.9,0.5),Color("8c9499"),true)
	# A wing wall off the quarters, north of its door: flush, so nothing hides behind it.
	box("BarrierQuarters",Vector3(10.7,0.45,-44.0),Vector3(2.2,0.9,0.5),Color("8c9499"),true)
	box("ArmPallets",Vector3(-8.65,0.5,-53.9),Vector3(1.0,1,1.4),Color("8b8672"),true)
	for label: String in ["CrateStack","Pallets","Drums","BarrierWest","BarrierQuarters","ArmPallets"]:
		var under: MeshInstance3D = source.get_node(label)
		var size: Vector3 = (under.mesh as BoxMesh).size
		box(label+"Snow",under.position+Vector3(0,size.y*0.5+0.02,0),Vector3(size.x-0.04,0.04,size.z-0.04),SNOW)
	# Tree line, outside the fence and never behind a camera's own strip.
	var index: int = 0
	for z: int in range(-30,-66,-6):
		tree(index,Vector3(24.5,0,z),5.4+(index%4)*0.6)
		index += 1
	for x: int in range(-10,22,6):
		tree(index,Vector3(x,0,-66.5),5.2+(index%3)*0.5)
		index += 1
	for x: float in [7.0,11.0,15.5]:
		tree(index,Vector3(x,0,-27.5),5.0+(index%3)*0.5)
		index += 1
	var packed := PackedScene.new()
	assert(packed.pack(source) == OK)
	assert(ResourceSaver.save(packed,"res://environments/service_yard_source.tscn") == OK)

func capture(path: String) -> void:
	for frame: int in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(path) == OK)

func run() -> void:
	var graphical: bool = DisplayServer.get_name() != "headless"
	DirAccess.make_dir_recursive_absolute("res://resources/service_yard")
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
	for shot_index: int in range(POSES.size()):
		camera.position = POSES[shot_index]
		camera.look_at(TARGETS[shot_index])
		camera.fov = FOVS[shot_index]
		var shot := ShotDefinition.new()
		var shot_path: String = "res://resources/service_yard/shot_%d.tres" % (shot_index+1)
		# The projective crop of a framing is tuned by hand against its plate.
		# Authoring the camera again must not throw that decision away.
		if ResourceLoader.exists(shot_path):
			var previous: ShotDefinition = load(shot_path)
			shot.zoom = previous.zoom
			shot.focus = previous.focus
		shot.shot_id = SHOT_IDS[shot_index]
		shot.camera_position = camera.position
		shot.camera_rotation_degrees = camera.rotation_degrees
		shot.fov = camera.fov
		assert(ResourceSaver.save(shot,shot_path) == OK)
		var landmarks: Dictionary = {}
		for label: String in ["RelayRearDoor","KennelDoor","QuartersDoor","GeneratorFrontDoor","GeneratorSideDoor","TruckCab","FuelTank"]:
			var at: Vector3 = source.get_node(label).position
			var pixel: Vector2 = camera.unproject_position(at)
			landmarks[label] = {"world":[at.x,at.y,at.z],"pixel":[pixel.x,pixel.y],"behind_camera":camera.is_position_behind(at)}
		manifest.append({"shot":String(SHOT_IDS[shot_index]),"position":[camera.position.x,camera.position.y,camera.position.z],"rotation_degrees":[camera.rotation_degrees.x,camera.rotation_degrees.y,camera.rotation_degrees.z],"fov":camera.fov,"landmarks":landmarks})
		if graphical:
			await capture(OUT+"/geometry_cam%02d.png" % (shot_index+1))
	if graphical:
		# The plan: straight down, north up, 32 m of ground from top to bottom.
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = 34.0
		camera.position = Vector3(1,40,-46)
		camera.rotation_degrees = Vector3(-90,0,0)
		await capture(OUT+"/plan_top.png")
		var file := FileAccess.open(OUT+"/cameras.json",FileAccess.WRITE)
		file.store_string(JSON.stringify({"units":"meters","image_size":[1920,1080],"rear_door_world":[2.4,0,-31.95],"shots":manifest},"\t"))
	print("SERVICE_YARD authored one spatial source + four fixed cameras%s" % (" + captures" if graphical else " (geometry only, no renderer)"))
	quit()
