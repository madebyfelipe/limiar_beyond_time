extends SceneTree
## Renders the Keleken in chosen clip poses from the side and front, for review.
##   godot --path . --script res://tools/capture_keleken_pose.gd -- hit:0.1 death:0.8 death:1.6
## Images: res://.local/keleken-pose-<clip>-<time>-<view>.png
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(960, 720)
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
	plane.size = Vector2(8, 8)
	floor.mesh = plane
	world.add_child(floor)
	var actor: KelekenActor = load("res://actors/keleken/keleken.tscn").instantiate()
	world.add_child(actor)
	actor.set_physics_process(false)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.current = true
	await process_frame
	var requests: PackedStringArray = OS.get_cmdline_user_args()
	if requests.is_empty():
		requests = ["hit:0.1", "death:0.8", "death:1.6"]
	DirAccess.make_dir_recursive_absolute("res://.local")
	for request: String in requests:
		var parts: PackedStringArray = request.split(":")
		var clip: StringName = StringName(parts[0])
		var time: float = float(parts[1]) if parts.size() > 1 else 0.0
		actor.visual.animator.play(clip, 0)
		actor.visual.animator.seek(time, true)
		actor.visual.animator.pause()
		for view: String in ["side", "front"]:
			camera.position = Vector3(5.2, 1.4, 0) if view == "side" else Vector3(0, 1.4, -5.2)
			camera.look_at(Vector3(0, 0.9, 0))
			for frame: int in range(3):
				await process_frame
			await RenderingServer.frame_post_draw
			var path := "res://.local/keleken-pose-%s-%s-%s.png" % [clip, str(time), view]
			root.get_texture().get_image().save_png(path)
			print("CAPTURE ", path)
	quit(0)
