extends SceneTree
## Uses the real player/input/collisions/director. No teleport during round trip.
var scene: Control
var player: PlayerController
var failures: int = 0
var cuts: Array[StringName] = []
var sampled_ticks: int = 0
var distance: float = 0.0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func release() -> void:
	for action: String in ["move_left","move_right","move_up","move_down","run"]:
		Input.action_release(action)

func steer(direction: Vector3, running: bool = false) -> void:
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
	if running:
		Input.action_press("run")
	else:
		Input.action_release("run")

func tick(count: int = 1, inspect: bool = true) -> void:
	for frame: int in range(count):
		var before: Vector3 = player.global_position
		await physics_frame
		await process_frame
		distance += before.distance_to(player.global_position)
		sampled_ticks += 1
		if inspect:
			var shot: ShotRig = scene.director.current_shot
			check(shot == scene.presentation.current_shot and shot.camera == player.camera, "Presentation/camera differs from selected shot")
			check(scene.background.texture == shot.definition.background, "Background did not change with camera")
			for height: float in [0.0,1.8]:
				var point: Vector3 = player.global_position + Vector3(0,height,0)
				var pixel: Vector2 = shot.camera.unproject_position(point)
				check(not shot.camera.is_position_behind(point) and Rect2(8,8,1904,1064).has_point(pixel), "Actor left the active frame at %s in %s" % [player.position,shot.name])
			var p: Vector3 = player.global_position
			var in_a: bool = absf(p.x) <= 5.71 and p.z >= -1 and p.z <= 10.71
			var in_b: bool = absf(p.x) <= 5.71 and p.z <= -13 and p.z >= -24.71
			var in_corridor: bool = absf(p.x) <= 1.21 and p.z >= -13 and p.z <= -1
			check(in_a or in_b or in_corridor, "Player crossed the visible level boundary: %s" % p)
			var floor_height: float = clampf((-p.z-6)*0.3,0,1.2)
			check(absf(p.y-floor_height) < 0.16, "Actor lost ground/ramp contact: %s expected y=%s" % [p,floor_height])

func capture(label: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png("user://t07-%s.png" % label) == OK,"Capture failed")

func walk_to(target: Vector3, running: bool = false) -> void:
	release()
	await tick(12)
	var reached: bool = false
	for frame: int in range(900):
		var delta: Vector3 = target-player.global_position
		delta.y = 0
		if delta.length() < 0.13:
			reached = true
			break
		steer(delta.normalized(),running and delta.length() > 1.0)
		await tick()
		if failures > 8:
			break
	release()
	await tick(12)
	check(reached,"Could not reach waypoint %s; stopped at %s" % [target,player.position])

func run() -> void:
	create_timer(120).timeout.connect(func() -> void: quit(124))
	root.size = Vector2i(1920,1080)
	scene = load("res://environments/technical_route.tscn").instantiate()
	root.add_child(scene)
	player = scene.player
	# Desktop focus changes must not pause this probe; T08 covers that path.
	scene.pause_menu.pause_on_focus_loss = false
	scene.director.shot_changed.connect(func(_from: StringName, to: StringName) -> void: cuts.append(to))
	await tick(25)
	check(scene.shots.size() == 3 and scene.director.zones.size() == 3,"Three shots/zones required")
	check(scene.colliders.get_child_count() >= 15,"Shared physical geometry missing")
	await capture("start")
	var outward: Array[Vector3] = [Vector3(-2.5,0,9),Vector3(-2.5,0,2),Vector3(0,0,2),Vector3(0,0,-4),Vector3(0,0.6,-8),Vector3(0,1.2,-11),Vector3(0,1.2,-15),Vector3(3.8,1.2,-15),Vector3(3.8,1.2,-20),Vector3(0,1.2,-23)]
	for index: int in range(outward.size()):
		await walk_to(outward[index])
		if index in [1,4,8,9]:
			await capture("outward-%d" % index)
		if failures > 8:
			break
	check(player.position.distance_to(scene.endpoint.position) < 0.25,"Endpoint not reached")
	var returning: Array[Vector3] = [Vector3(3.8,1.2,-20),Vector3(3.8,1.2,-15),Vector3(0,1.2,-15),Vector3(0,1.2,-11),Vector3(0,0,-4),Vector3(0,0,2),Vector3(2.5,0,2),Vector3(2.5,0,9),Vector3(0,0,9)]
	for target: Vector3 in returning:
		await walk_to(target,true)
		if failures > 8:
			break
	await capture("returned")
	check(player.position.distance_to(Vector3(0,0,9)) < 0.25,"Return to start failed")
	check(cuts == [&"route_2",&"route_3",&"route_2",&"route_1"],"Missing or oscillating cuts: %s" % str(cuts))
	print("T07 round_trip distance_m=",distance," simulated_seconds=",sampled_ticks/60.0," cuts=",cuts)
	# Separate collision challenges; round-trip above used no teleports.
	await walk_to(Vector3(0,0,8))
	steer(Vector3.FORWARD,true)
	await tick(90)
	release()
	await tick(15)
	check(player.position.z >= 6.39 and player.position.z <= 6.6,"Crate can be crossed or not reached")
	await capture("crate-front")
	await walk_to(Vector3(3,0,8))
	steer(Vector3.RIGHT,true)
	await tick(90)
	release()
	await tick(15)
	check(player.position.x <= 5.71 and player.position.x >= 5.5,"Outer wall can be crossed or not reached")
	print("T07 failures=",failures)
	release()
	quit(0 if failures == 0 else 1)
