extends SceneTree
## Renders the Cryopteryx in chosen clip poses from the side and three-quarters,
## for review (needs a display).
##   godot --path . --script res://tools/capture_cryopteryx_pose.gd -- walk:0.3 attack:0.4 death:1.2
## Images: res://.local/cryopteryx/pose-<clip>-<time>-<view>.png
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(960, 600)
	var world := Node3D.new()
	root.add_child(world)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("40484c")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.6
	world.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	world.add_child(sun)
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(10, 10)
	floor.mesh = plane
	world.add_child(floor)
	var visual := CryopteryxVisual.new()
	world.add_child(visual)
	var camera := Camera3D.new()
	camera.fov = 40
	world.add_child(camera)
	camera.current = true
	await process_frame
	var requests: PackedStringArray = OS.get_cmdline_user_args()
	if requests.is_empty():
		requests = ["idle:0", "walk:0.3", "run:0.2", "attack:0.4", "jump:0.5", "death:1.25"]
	DirAccess.make_dir_recursive_absolute("res://.local/cryopteryx")
	for request: String in requests:
		var parts: PackedStringArray = request.split(":")
		var clip: StringName = StringName(parts[0])
		var time: float = float(parts[1]) if parts.size() > 1 else 0.0
		visual.animator.play(clip, 0)
		visual.animator.seek(time, true)
		visual.animator.pause()
		for view: String in ["side", "quarter"]:
			camera.position = Vector3(6.4, 1.1, -0.2) if view == "side" else Vector3(4.2, 2.0, -4.6)
			camera.look_at(Vector3(0, 0.8, -0.2))
			for frame: int in range(3):
				await process_frame
			await RenderingServer.frame_post_draw
			var path := "res://.local/cryopteryx/pose-%s-%s-%s.png" % [clip, str(time), view]
			root.get_texture().get_image().save_png(path)
			print("CAPTURE ", path)
	quit(0)
