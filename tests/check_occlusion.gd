extends SceneTree

var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
func capture() -> Image:
	for frame: int in range(3):
		await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func max_difference(a: Image, b: Image) -> float:
	var maximum: float = 0.0
	for y: int in range(a.get_height()):
		for x: int in range(a.get_width()):
			var ca: Color = a.get_pixel(x, y)
			var cb: Color = b.get_pixel(x, y)
			maximum = maxf(maximum, maxf(absf(ca.r - cb.r), maxf(absf(ca.g - cb.g), absf(ca.b - cb.b))))
	return maximum
func run() -> void:
	create_timer(30.0).timeout.connect(func() -> void: quit(124))
	var scene: Control = load("res://environments/occlusion.tscn").instantiate()
	scene.automatic = false
	root.add_child(scene)
	var viewport: SubViewport = scene.get_node("Frame/Composition/Actors/WorldViewport")
	var capsule: MeshInstance3D = scene.capsule
	var occluder: MeshInstance3D = viewport.get_node("World/Occluder")
	await physics_frame
	await physics_frame
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(Vector3(0, 1, 2), Vector3(0, 1, -2))
	check(not viewport.find_world_3d().direct_space_state.intersect_ray(query).is_empty(), "Physical obstacle missing")
	for size: Vector2i in [Vector2i(1920,1080), Vector2i(1280,720), Vector2i(1280,960)]:
		root.size = size
		capsule.hide()
		occluder.hide()
		var baseline: Image = await capture()
		occluder.show()
		var opaque: Image = await capture()
		var seam: float = max_difference(baseline, opaque)
		check(seam <= 2.0 / 255.0, "Occluder changed background colors: %s" % seam)
		capsule.show()
		scene.set_phase(0.0)
		var front: Image = await capture()
		check(max_difference(front, baseline) > 0.1, "Capsule not visible in front")
		front.save_png("user://t02-front-%dx%d.png" % [size.x,size.y])
		scene.set_phase(0.5)
		var behind: Image = await capture()
		check(max_difference(behind, opaque) <= 2.0 / 255.0, "Capsule not fully hidden behind obstacle")
		behind.save_png("user://t02-behind-%dx%d.png" % [size.x,size.y])
		scene.set_phase(1.0 / 6.0)
		var side: Image = await capture()
		check(max_difference(side, baseline) > 0.1, "Capsule not visible beside obstacle")
		side.save_png("user://t02-side-%dx%d.png" % [size.x,size.y])
		print("T02 size=", size, " seam=", seam)
	scene.automatic = true
	var starting_phase: float = scene.phase
	await create_timer(0.2).timeout
	check(scene.phase > starting_phase, "Automatic traversal did not advance")
	print("T02 failures=", failures)
	quit(0 if failures == 0 else 1)
