extends SceneTree
## Render Dylan's own model for the equipment console, without gameplay nodes.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var view := SubViewport.new()
	view.size = Vector2i(384, 384)
	view.own_world_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	view.transparent_bg = false
	root.add_child(view)
	var world := Node3D.new()
	view.add_child(world)
	var model: Node3D = load("res://assets/models/dylan_protagonist/mixamo/dylan_rig_idle.fbx").instantiate()
	world.add_child(model)
	var bounds := AABB()
	var first := true
	for mesh: Node in model.find_children("*", "MeshInstance3D", true, false):
		var area: AABB = mesh.global_transform * mesh.get_aabb()
		bounds = area if first else bounds.merge(area)
		first = false
	var focus := bounds.get_center()
	focus.y = bounds.end.y - bounds.size.y * 0.16
	for skel: Node in model.find_children("*", "Skeleton3D", true, false):
		for bone: int in range(skel.get_bone_count()):
			if "head" in skel.get_bone_name(bone).to_lower():
				focus = skel.global_transform * skel.get_bone_global_pose(bone).origin + Vector3(0, -0.10, 0)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = bounds.size.y * 0.23
	world.add_child(camera)
	camera.position = focus + Vector3(0.18, 0.01, 1.0) * bounds.size.y
	camera.look_at(focus)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("04080b")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("7893a8")
	settings.ambient_light_energy = 0.65
	environment.environment = settings
	world.add_child(environment)
	var key := DirectionalLight3D.new()
	key.light_color = Color("dfd6c0")
	key.light_energy = 1.8
	key.rotation_degrees = Vector3(-20, -30, 0)
	world.add_child(key)
	for i: int in range(10):
		await process_frame
	await RenderingServer.frame_post_draw
	view.get_texture().get_image().save_png("res://assets/ui/inventory/dylan_portrait.png")
	print("Saved Dylan portrait")
	quit()
