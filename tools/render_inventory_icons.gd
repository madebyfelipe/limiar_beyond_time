extends SceneTree
## Bake the actual equipped weapon models into transparent inventory portraits.
## godot --rendering-method gl_compatibility --path . --script res://tools/render_inventory_icons.gd
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/ui/inventory")
	for id: String in ["pistol", "shotgun"]:
		var view := SubViewport.new()
		view.size = Vector2i(768, 512) if id == "pistol" else Vector2i(1280, 320)
		view.transparent_bg = true
		view.own_world_3d = true
		view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(view)
		var world := Node3D.new()
		view.add_child(world)
		var env := WorldEnvironment.new()
		var settings := Environment.new()
		settings.background_mode = Environment.BG_CLEAR_COLOR
		settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		settings.ambient_light_color = Color("b4c0cb")
		settings.ambient_light_energy = 0.7
		env.environment = settings
		world.add_child(env)
		var model: Node3D = load("res://assets/models/weapons/%s/%s_lowpoly.glb" % [id, id]).instantiate()
		world.add_child(model)
		model.rotation.y = -PI / 2.0
		var bounds := AABB()
		var first := true
		for child: Node in model.find_children("*", "MeshInstance3D", true, false):
			var area: AABB = child.global_transform * child.get_aabb()
			bounds = area if first else bounds.merge(area)
			first = false
		var center := bounds.get_center()
		var camera := Camera3D.new()
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.keep_aspect = Camera3D.KEEP_HEIGHT
		camera.size = maxf(bounds.size.y, bounds.size.x * view.size.y / float(view.size.x)) * 1.22
		world.add_child(camera)
		camera.position = center + Vector3(0, 0.05 if id == "pistol" else 0.07, 2)
		camera.look_at(center)
		var key := DirectionalLight3D.new()
		key.light_energy = 2.2
		key.rotation_degrees = Vector3(-35, -25, 0)
		world.add_child(key)
		var rim := DirectionalLight3D.new()
		rim.light_energy = 1.0
		rim.rotation_degrees = Vector3(15, 145, 0)
		world.add_child(rim)
		for frame: int in range(8):
			await process_frame
		await RenderingServer.frame_post_draw
		var output := "res://assets/ui/inventory/%s.png" % id
		view.get_texture().get_image().save_png(output)
		print("saved ", output)
		view.queue_free()
		await process_frame
	quit()
