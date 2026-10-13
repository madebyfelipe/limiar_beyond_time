extends SceneTree
## Capture the current north-yard source without rewriting geometry or cameras.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1920,1080)
	RenderingServer.set_default_clear_color(Color("243544"))
	var source = load("res://environments/exterior_source.tscn").instantiate()
	root.add_child(source)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("b6c5d1")
	environment.environment.ambient_light_energy = 0.65
	root.add_child(environment)
	var shot_index: int = 2 if OS.get_cmdline_user_args().has("--yard") else 4
	if OS.get_cmdline_user_args().has("--guardhouse"):
		shot_index = 3
	var definition = load("res://resources/exterior/shot_%d.tres" % shot_index)
	var camera := Camera3D.new()
	camera.position = definition.camera_position
	camera.rotation_degrees = definition.camera_rotation_degrees
	camera.fov = definition.fov
	root.add_child(camera)
	camera.make_current()
	for frame: int in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	var output: String = "geometry_cam02_gate.png" if shot_index == 2 else "geometry_cam04.png"
	if shot_index == 3:
		output = "geometry_cam03_gate.png"
	assert(root.get_texture().get_image().save_png("res://assets/backgrounds/env_1/exterior_authored/"+output) == OK)
	for label: String in ["NorthGateLeaf", "NorthGatePost", "NorthGateSign"]:
		print(label, " pixel=", camera.unproject_position(source.get_node(label).position))
	print("EXTERIOR captured current source and shot_%d at 1920x1080" % shot_index)
	quit()
