extends SceneTree
## Render contact sheets of the authored clips without changing the supplied GLB.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	root.size = Vector2i(640, 640)
	var world := Node3D.new()
	root.add_child(world)
	var player: PlayerController = load("res://actors/player/player_dylan.tscn").instantiate()
	world.add_child(player)
	player.set_control_enabled(false)
	player.set_physics_process(false)
	var dylan: Node = player.visual.get_node("DylanVisual")
	dylan.set_process(false)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(3.6, 2.7, 4.3)
	camera.look_at(Vector3(0, 1.15, 0))
	camera.fov = 33
	player.camera = camera
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("17212b")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("b7cadc")
	environment.environment.ambient_light_energy = 0.6
	world.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -25, 0)
	light.light_energy = 1.5
	world.add_child(light)
	for clip: String in dylan.animator.get_animation_list():
		for frame: int in range(4):
			dylan.animator.play(clip)
			dylan.animator.seek((float(frame) / 4.0) * dylan.animator.get_animation(clip).length, true)
			dylan.animator.pause()
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.local/dylan-%s-%d.png" % [clip, frame])
	quit()
