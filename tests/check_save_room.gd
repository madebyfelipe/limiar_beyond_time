extends SceneTree
## Actual controller + actual colliders; continuous walk before collision probes.
var scene: Control
var player: PlayerController
var failures: int = 0
var distance: float = 0
var ticks: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func release() -> void:
	for action: String in ["move_left","move_right","move_up","move_down","run"]:
		Input.action_release(action)

func steer(direction: Vector3) -> void:
	var right: Vector3 = player.movement_reference.right
	var back: Vector3 = player.movement_reference.back
	if not player.movement_reference.locked:
		right = player.camera.global_basis.x
		back = player.camera.global_basis.z
		right.y = 0
		back.y = 0
		right = right.normalized()
		back = back.normalized()
	var input := Vector2(direction.dot(right),direction.dot(back))
	for pair: Array in [["move_right",input.x],["move_left",-input.x],["move_down",input.y],["move_up",-input.y]]:
		if pair[1] > 0.001:
			Input.action_press(pair[0],pair[1])
		else:
			Input.action_release(pair[0])

func tick(count: int = 1) -> void:
	for frame: int in range(count):
		var before: Vector3 = player.position
		await physics_frame
		await process_frame
		distance += before.distance_to(player.position)
		ticks += 1
		check(absf(player.position.y) < 0.12,"Lost floor contact")
		check(absf(player.position.x) < 2.72 and absf(player.position.z) < 2.22,"Crossed room boundary")
		for height: float in [0,1.8]:
			var point: Vector3 = player.global_position+Vector3(0,height,0)
			check(not player.camera.is_position_behind(point),"Actor behind camera")
			if not Rect2(8,8,1904,1064).has_point(player.camera.unproject_position(point)):
				check(false,"Actor outside frame at %s height %s pixel %s" % [player.position,height,player.camera.unproject_position(point)])
				quit(1)
				return

func walk_to(target: Vector3) -> void:
	release()
	await tick(12)
	var reached := false
	for frame: int in range(400):
		var delta: Vector3 = target-player.position
		delta.y = 0
		if delta.length() < 0.13:
			reached = true
			break
		steer(delta.normalized())
		await tick()
		if failures > 5:
			break
	release()
	await tick(12)
	check(reached,"Waypoint blocked: %s; stopped %s" % [target,player.position])

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var viewport: SubViewport = scene.get_node("Frame/Composition/Actors/WorldViewport")
	check(viewport.get_texture().get_image().save_png("res://.local/save-room-%s.png" % label) == OK,"Capture failed")

func run() -> void:
	create_timer(90).timeout.connect(func() -> void: quit(124))
	root.size = Vector2i(1920,1080)
	scene = load("res://environments/save_room.tscn").instantiate()
	root.add_child(scene)
	player = scene.player
	await tick(25)
	check(scene.colliders.get_child_count() == 10,"Unexpected physical geometry")
	await capture("entrance")
	# Close interior shot: entrance -> save station -> return, without teleporting.
	for target: Vector3 in [Vector3(-1.2,0,0.55),Vector3(-1.15,0,-1.7),Vector3(-1.15,0,-0.4),Vector3(0.6,0,-0.4),Vector3(-1.15,0,-0.4),Vector3(-1.2,0,0.55),Vector3(-2.4,0,0.55)]:
		await walk_to(target)
	await capture("close-returned")
	# Overview is an explicit technical inspection camera for all room boundaries.
	scene.set_overview(true)
	for target: Vector3 in [Vector3(-1.2,0,0.55),Vector3(0,0,0.55),Vector3(0,0,-0.4),Vector3(-1.15,0,-0.4),Vector3(-1.15,0,-1.7),Vector3(-1.15,0,-0.4),Vector3(0.6,0,-0.4),Vector3(1.5,0,0.6),Vector3(1.5,0,1.65),Vector3(-1,0,1.65),Vector3(-1,0,0.55),Vector3(-2.4,0,0.55)]:
		await walk_to(target)
	await capture("returned")
	check(player.position.distance_to(Vector3(-2.4,0,0.55)) < 0.25,"Could not return to entrance")
	# Four sealed boundaries and furniture must block the real character.
	for item: Array in [[Vector3(-1.1,0.06,-0.3),Vector3.FORWARD,2],[Vector3(0,0.06,1),Vector3.BACK,2],[Vector3(-2,0.06,-0.3),Vector3.LEFT,0],[Vector3(2,0.06,0.5),Vector3.RIGHT,0],[Vector3(-2.12,0.06,-0.5),Vector3.FORWARD,2],[Vector3(1.2,0.06,-0.5),Vector3.FORWARD,2]]:
		release()
		player.reset_to(Transform3D(Basis.IDENTITY,item[0]))
		await tick(12)
		steer(item[1])
		await tick(90)
		release()
		await tick(12)
		check(player.get_last_motion().length() < 0.01,"Obstacle did not stop movement")
	player.reset_to_start()
	await tick(12)
	scene.set_overview(false)
	if ResourceLoader.exists(scene.ART):
		scene.set_art_mode(true)
		check(scene.art_mode and scene.background.visible,"Art comparison unavailable")
		await tick(5)
		await walk_to(Vector3(-1.2,0,0.55))
		await walk_to(Vector3(-1.15,0,-0.4))
		await walk_to(Vector3(0.6,0,-0.4))
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_png("res://.local/save-room-art.png") == OK,"Art capture failed")
		await walk_to(Vector3(-1.15,0,-0.4))
		await walk_to(Vector3(-1.2,0,0.55))
		await walk_to(Vector3(-2.4,0,0.55))
		scene.set_art_mode(false)
		check(not scene.art_mode and not scene.background.visible,"Geometry comparison unavailable")
	print("SAVE_ROOM ticks=",ticks," distance_m=",distance," failures=",failures)
	quit(0 if failures == 0 else 1)
