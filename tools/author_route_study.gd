extends SceneTree
## Rebuild the authored technical studies. No image reconstruction or fitting.
## Run graphically; the source scene and camera poses are the editable originals.

const OUTPUT := "res://assets/backgrounds/route_study"
const POINTS := [
	Vector3(-4,0.025,8), Vector3(4,0.025,8), Vector3(-4,0.025,2), Vector3(4,0.025,2),
	Vector3(-4,0.025,-0.3), Vector3(4,0.025,-0.3), Vector3(-3,0.025,5), Vector3(3,0.025,5),
	Vector3(-0.6,0.025,-2), Vector3(0.6,0.025,-2), Vector3(-0.6,0.025,-5), Vector3(0.6,0.025,-5),
	Vector3(-0.6,1.225,-10.5), Vector3(0.6,1.225,-10.5), Vector3(-0.6,1.225,-12), Vector3(0.6,1.225,-12),
	Vector3(-4,1.225,-15), Vector3(4,1.225,-15), Vector3(-4,1.225,-22), Vector3(4,1.225,-22),
	Vector3(-4,1.225,-24), Vector3(4,1.225,-24), Vector3(-2,1.225,-23), Vector3(2,1.225,-23)
]
const POSES := [Vector3(11,16,22), Vector3(10,13,3), Vector3(-12,17,-5)]
const TARGETS := [Vector3(0,0,4), Vector3(0,0.6,-6.5), Vector3(0,1.2,-19)]
const FOVS := [49.0, 49.0, 49.0]
var source: Node3D
var camera: Camera3D

func _initialize() -> void:
	call_deferred("run")

func material(color: Color) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	result.albedo_color = color
	return result

func box(label: String, at: Vector3, size: Vector3, color: Color, solid: bool = false) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material(color)
	var node := MeshInstance3D.new()
	node.name = label
	node.position = at
	node.mesh = mesh
	if solid:
		node.set_meta("collision_size", size)
	source.add_child(node)
	node.owner = source
	return node

func marker_color(index: int) -> Color:
	# Quantized RGB identifiers measured from the raster, not camera projection.
	return Color8(55 + (index % 4)*60, 55 + ((index/4) % 3)*80, 80 + (index/12)*150)

func build_source() -> void:
	source = Node3D.new()
	source.name = "RouteStudySource"
	root.add_child(source)
	box("FoundationA",Vector3(0,-0.25,5),Vector3(12,0.5,12),Color("455963"),true)
	box("FoundationB",Vector3(0,0.95,-19),Vector3(12,0.5,12),Color("4c605e"),true)
	box("CorridorLower",Vector3(0,-0.25,-3.5),Vector3(3,0.5,5),Color("697578"),true)
	box("CorridorUpper",Vector3(0,0.95,-11.5),Vector3(3,0.5,3),Color("697578"),true)
	# Eight corners of a solid wedge; a single authored surface defines the slope.
	var vertices := PackedVector3Array([
		Vector3(-1.5,0,-6),Vector3(1.5,0,-6),Vector3(1.5,1.2,-10),Vector3(-1.5,1.2,-10),
		Vector3(-1.5,-0.4,-6),Vector3(1.5,-0.4,-6),Vector3(1.5,-0.4,-10),Vector3(-1.5,-0.4,-10)])
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face: Array in [[0,1,2,3],[4,7,6,5],[0,4,5,1],[3,2,6,7],[0,3,7,4],[1,5,6,2]]:
		for index: int in [face[0],face[1],face[2],face[0],face[2],face[3]]:
			surface.add_vertex(vertices[index])
	surface.generate_normals()
	var ramp := MeshInstance3D.new()
	ramp.name = "Ramp"
	ramp.mesh = surface.commit()
	var ramp_material := material(Color("8b957d"))
	ramp_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	ramp.material_override = ramp_material
	ramp.set_meta("collision_points",vertices)
	source.add_child(ramp)
	ramp.owner = source
	# Low retaining walls keep the traversable border explicit in every image.
	for x: float in [-6.15,6.15]:
		box("WallA",Vector3(x,0.65,5),Vector3(0.3,1.3,12.6),Color("263943"),true)
		box("WallB",Vector3(x,1.85,-19),Vector3(0.3,1.3,12.6),Color("263943"),true)
	box("SouthWall",Vector3(0,0.65,11.15),Vector3(12,1.3,0.3),Color("263943"),true)
	box("NorthWall",Vector3(0,1.85,-25.15),Vector3(12,1.3,0.3),Color("263943"),true)
	for x: float in [-3.9,3.9]:
		box("OpeningA",Vector3(x,0.65,-1.15),Vector3(4.8,1.3,0.3),Color("263943"),true)
		box("OpeningB",Vector3(x,1.85,-12.85),Vector3(4.8,1.3,0.3),Color("263943"),true)
	for x: float in [-1.65,1.65]:
		box("CorridorWallLower",Vector3(x,0.5,-3.5),Vector3(0.3,1,5),Color("30444e"),true)
		box("CorridorWallUpper",Vector3(x,1.7,-11.5),Vector3(0.3,1,3),Color("30444e"),true)
		var side := box("RampWall",Vector3(x,1.1,-8),Vector3(0.3,1.05,4.18),Color("30444e"),true)
		side.rotation.x = atan(1.2/4.0)
	# The crate can be circled on both sides. The upper rack makes a 1.6 m passage.
	box("Crate",Vector3(0,1.35,5),Vector3(2.2,2.7,2.2),Color("8c7660"),true)
	box("CrateTop",Vector3(0,2.71,5),Vector3(2.23,0.04,2.23),Color("c0ab7d"))
	for x: float in [-0.8,0.8]:
		box("CrateBand",Vector3(x,1.35,6.115),Vector3(0.14,2.7,0.04),Color("36454d"))
	box("StorageRack",Vector3(-1.15,2.4,-18),Vector3(8.3,2.4,1.2),Color("526975"),true)
	box("StorageCap",Vector3(-1.15,3.62,-18),Vector3(8.35,0.04,1.25),Color("a3b6b4"))
	box("NarrowBarrier",Vector3(5.3,2.0,-18),Vector3(1.4,1.6,2.5),Color("8c7660"),true)
	# Floor markings and panels are deliberately simple technical art.
	for z: int in range(-24,11,2):
		if z > -13 and z < -1:
			continue
		var height: float = 1.204 if z < -12 else 0.004
		box("FloorJoint",Vector3(0,height,z),Vector3(11.95,0.004,0.035),Color("314952"))
	for x: float in [-3,0,3]:
		box("FloorJointA",Vector3(x,0.005,5),Vector3(0.035,0.004,11.95),Color("314952"))
		box("FloorJointB",Vector3(x,1.205,-19),Vector3(0.035,0.004,11.95),Color("314952"))
	box("StartPad",Vector3(0,0.012,9),Vector3(2,0.02,1.5),Color("76a7a1"))
	box("EndPad",Vector3(0,1.212,-23),Vector3(2,0.02,1.5),Color("c0aa69"))
	for z: float in [-3,-4.5,-11]:
		box("LaneMark",Vector3(0,0.018 if z > -6 else 1.218,z),Vector3(0.13,0.018,0.65),Color("ddd0a2"))
	for index: int in range(POINTS.size()):
		box("SurveyMark%02d" % index, POINTS[index]-Vector3(0,0.005,0),Vector3(0.28,0.01,0.28),marker_color(index))
	var packed := PackedScene.new()
	assert(packed.pack(source) == OK)
	assert(ResourceSaver.save(packed,"res://environments/route_study_source.tscn") == OK)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Background authoring requires the graphical renderer")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	DirAccess.make_dir_recursive_absolute("res://resources/route_study")
	root.size = Vector2i(1920,1080)
	RenderingServer.set_default_clear_color(Color("101d29"))
	build_source()
	camera = Camera3D.new()
	root.add_child(camera)
	camera.make_current()
	for shot: int in range(3):
		camera.position = POSES[shot]
		camera.look_at(TARGETS[shot])
		camera.fov = FOVS[shot]
		for frame: int in range(8):
			await process_frame
		await RenderingServer.frame_post_draw
		var raster: Image = root.get_texture().get_image()
		var path: String = OUTPUT + "/shot_%d.png" % (shot+1)
		assert(raster.save_png(path) == OK)
		var sheet := CalibrationDefinition.new()
		sheet.calibration_status = "ESTUDO AUTORAL — REVISÃO PENDENTE"
		sheet.shot_id = StringName("route_%d" % (shot+1))
		sheet.source_dimensions = Vector2i(1920,1080)
		sheet.camera_position = camera.position
		sheet.camera_rotation_degrees = camera.rotation_degrees
		sheet.fov = camera.fov
		sheet.capsule_position = Vector3(0,0,9) if shot == 0 else (Vector3(0,0,-4) if shot == 1 else Vector3(0,1.2,-23))
		sheet.grid_origin = TARGETS[shot]
		sheet.scale_notes = "Estudo autoral, 1 unidade = 1 m. Fonte route_study_source.tscn. Pixels medidos por centroide da cor dos marcos no PNG; câmeras e geometria autoradas, sem ajuste automático."
		var sums: Array[Vector2] = []
		var counts: Array[int] = []
		sums.resize(8)
		counts.resize(8)
		# Raster measurement intentionally never calls unproject_position.
		for y: int in range(raster.get_height()):
			for x: int in range(raster.get_width()):
				var color: Color = raster.get_pixel(x,y)
				for local_index: int in range(8):
					var expected: Color = marker_color(shot*8+local_index)
					if absf(color.r-expected.r)+absf(color.g-expected.g)+absf(color.b-expected.b) < 0.008:
						sums[local_index] += Vector2(x+0.5,y+0.5)
						counts[local_index] += 1
		for index: int in range(8):
			if counts[index] < 4:
				push_error("Marker %d not visible in shot %d" % [shot*8+index,shot+1])
				quit(1)
				return
			sheet.reference_labels.append("SurveyMark%02d" % (shot*8+index))
			sheet.reference_pixels.append((sums[index]/counts[index]).round())
			sheet.reference_world.append(POINTS[shot*8+index])
		# Texture import occurs in a second, explicit editor import step.
		assert(ResourceSaver.save(sheet,"res://resources/route_study/shot_%d.tres" % (shot+1)) == OK)
		print("AUTHORED shot=",shot+1," pose=",camera.position," rotation=",camera.rotation_degrees," raster_pixels=",sheet.reference_pixels," counts=",counts)
	quit()
