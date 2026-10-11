extends SceneTree
var failures: int = 0
var scene: Control
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
func difference(a: Image,b: Image) -> int:
	var left: PackedByteArray = a.get_data()
	var right: PackedByteArray = b.get_data()
	var count: int = 0
	for index: int in range(left.size()):
		if absi(int(left[index])-int(right[index])) > 2:
			count += 1
	return count
func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Rendering proof requires a graphical renderer")
		quit(1)
		return
	create_timer(90).timeout.connect(func() -> void: quit(124))
	scene = load("res://environments/technical_route.tscn").instantiate()
	root.add_child(scene)
	# Desktop focus changes must not pause this probe; T08 covers that path.
	scene.pause_menu.pause_on_focus_loss = false
	scene.director.set_physics_process(false)
	scene.player.set_physics_process(false)
	scene.player.hide()
	for size: Vector2i in [Vector2i(1920,1080),Vector2i(1280,720),Vector2i(1280,960)]:
		root.size = size
		for shot: ShotRig in scene.shots:
			scene.presentation.apply_shot(shot)
			for mesh: MeshInstance3D in shot.occluders:
				mesh.hide()
			var baseline: Image = await capture()
			for mesh: MeshInstance3D in shot.occluders:
				mesh.show()
			var composed: Image = await capture()
			var changed: int = difference(baseline,composed)
			check(changed == 0,"Occluder seam in %s at %s: %d channels" % [shot.name,size,changed])
			print("T07 seam shot=",shot.name," size=",size," changed_channels=",changed)
			if size == Vector2i(1280,960):
				check(composed.get_pixel(640,60) == Color.BLACK and composed.get_pixel(640,900) == Color.BLACK,"Window bars missing")
				composed.save_png("user://t07-%s-4x3.png" % shot.name)
	# Same capsule placed along camera's horizontal sightline, in front/behind crate.
	root.size = Vector2i(1920,1080)
	var shot: ShotRig = scene.shots[0]
	scene.presentation.apply_shot(shot)
	var clean: Image = await capture()
	scene.player.show()
	scene.player.position = Vector3(1.7,0,7.7)
	var front: Image = await capture()
	check(difference(clean,front) > 100,"Player not visible in front of crate")
	front.save_png("user://t07-occlusion-front.png")
	scene.player.position = Vector3(-0.65,0,3.9)
	var occluded: Image = await capture()
	for mesh: MeshInstance3D in shot.occluders:
		mesh.hide()
	var exposed: Image = await capture()
	check(difference(occluded,exposed) > 100,"Depth occlusion did not hide the actor behind the crate")
	check(difference(clean,occluded) < difference(clean,exposed),"Occlusion failed to reduce visible actor pixels")
	occluded.save_png("user://t07-occlusion-behind.png")
	exposed.save_png("user://t07-occlusion-disabled.png")
	print("T07 rendering failures=",failures)
	quit(0 if failures == 0 else 1)
