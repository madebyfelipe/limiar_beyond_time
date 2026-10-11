extends SceneTree

# GPU probe of the real scene, including live window resizing. No mock rendering.
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func _run() -> void:
	var scene: Control = load("res://environments/composition.tscn").instantiate()
	root.add_child(scene)
	var composition: Control = scene.get_node("Frame/Composition")
	var background: TextureRect = composition.get_node("Background")
	var container: SubViewportContainer = composition.get_node("Actors")
	var viewport: SubViewport = container.get_node("WorldViewport")
	var camera: Camera3D = viewport.get_node("World/Camera")
	check(viewport.transparent_bg, "Actors viewport must be transparent")
	check(camera.current, "The fixed camera must be current")
	for dimensions: Vector2i in [Vector2i(1920, 1080), Vector2i(1280, 720), Vector2i(1280, 960), Vector2i(1280, 720)]:
		root.size = dimensions
		for frame: int in range(5):
			await process_frame
		await RenderingServer.frame_post_draw
		check(background.get_global_rect() == container.get_global_rect(), "Layer rectangles differ")
		check(is_equal_approx(composition.size.x / composition.size.y, 16.0 / 9.0), "Composition aspect changed")
		var actor_image: Image = viewport.get_texture().get_image()
		check(actor_image.get_pixel(10, 10).a == 0.0, "Viewport corner is opaque")
		var center: Vector2 = camera.unproject_position(Vector3(0, 0.9, 0))
		check(actor_image.get_pixel(int(center.x), int(center.y)).a > 0.99, "Capsule is missing")
		var image: Image = root.get_texture().get_image()
		check(image.get_size() == dimensions, "Capture must include the entire window")
		if dimensions == Vector2i(1280, 960):
			check(image.get_pixel(640, 60) == Color.BLACK, "Top letterbox missing")
			check(image.get_pixel(640, 900) == Color.BLACK, "Bottom letterbox missing")
		var name: String = "user://t01-%dx%d.png" % [dimensions.x, dimensions.y]
		check(image.save_png(name) == OK, "Could not save render evidence")
		print("T01 window=", root.size, " image=", image.get_size(), " scene=", scene.size, " actor=", viewport.size, " center=", center, " capture=", ProjectSettings.globalize_path(name))
	scene.queue_free()
	await process_frame
	print("T01 failures=", failures)
	quit(0 if failures == 0 else 1)
