extends SceneTree
## Real Input/controller/colliders; camera cuts do not teleport the actor.
const OUTWARD: Array[Vector3] = [Vector3(0,0,17),Vector3(0,0,13),Vector3(0,0,9),Vector3(0,0,6.4),Vector3(-2.4,0,6.4),Vector3(-4.45,0,6.45),Vector3(-4.45,0.3,5.6),Vector3(-4.45,0.6,4.5),Vector3(-4.45,0.6,3.7)]
var scene: Control
var player: PlayerController
var failures: int = 0
var cuts: Array[StringName] = []
var ticks: int = 0
var distance: float = 0
var inspect_frame: bool = true
var visual: bool = false

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

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

func floor_at(at: Vector3) -> float:
	if at.x >= -5.85 and at.x <= -3.05 and at.z >= 3.2 and at.z <= 4.7:
		return 0.6
	if absf(at.x+4.45) <= 0.75 and at.z >= 4.7 and at.z <= 6.5:
		return clampf((6.5-at.z)/1.8*0.6,0,0.6)
	return 0

func tick(count: int = 1) -> void:
	for frame: int in range(count):
		var before: Vector3 = player.position
		var previous_camera: Camera3D = player.camera
		var previous_right: Vector3 = player.movement_reference.right
		var previous_back: Vector3 = player.movement_reference.back
		var was_locked: bool = player.movement_reference.locked
		await physics_frame
		await process_frame
		ticks += 1
		distance += player.position.distance_to(before)
		check(player.position.distance_to(before) < 0.11,"Cut caused a discontinuity or movement exceeded run speed")
		check(absf(player.position.y-floor_at(player.position)) < 0.13,"Lost ground/platform contact at %s" % player.position)
		var shot: ShotRig = scene.director.current_shot
		check(scene.presentation.current_shot == shot and player.camera == shot.camera,"Camera presentation out of sync")
		if scene.presentation.art_mode:
			check(scene.background.texture == shot.definition.background and scene.background.visible,"Background out of sync at cut")
		if inspect_frame:
			for height: float in [0,1.8]:
				var point: Vector3 = player.global_position+Vector3(0,height,0)
				var pixel: Vector2 = shot.camera.unproject_position(point)
				if shot.camera.is_position_behind(point) or not Rect2(8,8,1904,1064).has_point(pixel):
					check(false,"Actor outside frame at %s height %s pixel %s shot %s" % [player.position,height,pixel,shot.name])
					quit(1)
					return
		if previous_camera != player.camera and was_locked and player.movement_reference.locked:
			check(player.movement_reference.right.is_equal_approx(previous_right) and player.movement_reference.back.is_equal_approx(previous_back),"Held movement reference changed at cut")

func walk_to(target: Vector3, running: bool = false) -> void:
	release()
	await tick(12)
	var reached := false
	for frame: int in range(1000):
		var delta: Vector3 = target-player.position
		delta.y = 0
		if delta.length() < 0.13:
			reached = true
			break
		steer(delta.normalized(),running and delta.length() > 1)
		await tick()
		if failures > 5:
			break
	release()
	await tick(12)
	check(reached,"Waypoint blocked: %s; stopped at %s" % [target,player.position])

func capture(label: String) -> void:
	if not visual:
		return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("res://.local/exterior-%s.png" % label) == OK,"Capture failed")

func round_trip(art: bool) -> void:
	scene.set_art_mode(art)
	player.reset_to_start()
	scene.director.reset_to(scene.shots[0])
	cuts.clear()
	await tick(25)
	var mode: String = "art" if art else "geometry"
	await capture(mode+"-road")
	for index: int in range(OUTWARD.size()):
		await walk_to(OUTWARD[index])
		if index in [2,5,8]:
			await capture(mode+"-out-%d" % index)
	check(scene.director.current_shot == scene.shots[2],"House shot not reached")
	check(player.position.distance_to(Vector3(-4.45,0.6,3.7)) < 0.25,"Door not reached")
	var returning: Array[Vector3] = OUTWARD.duplicate()
	returning.reverse()
	for point: Vector3 in returning:
		await walk_to(point,true)
	await walk_to(Vector3(0,0,22),true)
	await capture(mode+"-returned")
	check(cuts == [&"exterior_2",&"exterior_3",&"exterior_2",&"exterior_1"],"Missing or unstable cuts: %s" % str(cuts))
	check(scene.director.current_shot == scene.shots[0],"Road shot not restored")
	check(player.position.distance_to(Vector3(0,0,22)) < 0.25,"Return failed")
	print("EXTERIOR round_trip mode=",mode," cuts=",cuts)

## Whether the 1,8 m player capsule fits at a world position.
func free_at(at: Vector3) -> bool:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.3
	shape.height = 1.8
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY,at)
	return player.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()

func run() -> void:
	create_timer(180).timeout.connect(func() -> void: quit(124))
	visual = DisplayServer.get_name() != "headless"
	root.size = Vector2i(1920,1080)
	scene = load("res://environments/exterior.tscn").instantiate()
	root.add_child(scene)
	# This probe measures authored geometry and camera continuity. Combat has
	# its own probe; an active enemy would interrupt these unattended walks.
	scene.keleken.combat_enabled = false
	scene.keleken.collision_layer = 0
	player = scene.player
	check(scene.shots.size() == 3 and scene.colliders.get_child_count() >= 40,"Spatial source or cameras incomplete")
	# The painted plate puts the pole tens of pixels off the geometry, so it is a
	# visual and depth occluder only: a collider there would block empty snow.
	check(scene.colliders.get_node_or_null("LightPole") == null,"The light pole still has a collider")
	check(free_at(Vector3(5.5,0.96,8.9)),"Something still blocks the player where the pole stands")
	scene.director.shot_changed.connect(func(_old: StringName,new: StringName) -> void: cuts.append(new))
	await round_trip(false)
	if scene.art_available:
		await round_trip(true)
	# Separate challenges, not part of the continuous round trip.
	inspect_frame = false
	scene.set_art_mode(false)
	for item: Array in [[Vector3(0,0.06,20),Vector3.RIGHT,"snowbank"],[Vector3(0,0.06,26),Vector3.BACK,"road end"],[Vector3(-6.25,0.06,5.7),Vector3.FORWARD,"house wall"],[Vector3(-4.45,0.66,3.7),Vector3.FORWARD,"door"]]:
		release()
		player.reset_to(Transform3D(Basis.IDENTITY,item[0]))
		await tick(20)
		steer(item[1])
		await tick(120)
		release()
		await tick(12)
		check(player.get_last_motion().length() < 0.01,"Did not stop at "+item[2])
	# Bars preserve the same 16:9 composition in a 4:3 window.
	if visual:
		player.reset_to_start()
		scene.director.reset_to(scene.shots[0])
		scene.set_art_mode(scene.art_available)
		root.size = Vector2i(1280,960)
		await tick(10)
		await capture("4x3")
	print("EXTERIOR ticks=",ticks," distance_m=",distance," colliders=",scene.colliders.get_child_count()," failures=",failures)
	release()
	quit(0 if failures == 0 else 1)
