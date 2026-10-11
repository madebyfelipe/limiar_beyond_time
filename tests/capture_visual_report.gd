extends SceneTree
## T09 manual visual report: captures for human inspection of collision,
## occlusion, resolution and cut continuity on the real route. The route is
## driven through the real controller; the actor is only placed directly for
## the static occlusion/resolution poses. Requires a graphical renderer.
## Saves user://t09-*.png; the inspection itself is recorded in TEST_REPORT.md.
var scene: Control
var player: PlayerController
var failures: int = 0
var cut_index: int = 0
var pending_after: String = ""

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
		right = Vector3(player.camera.global_basis.x.x,0,player.camera.global_basis.x.z).normalized()
		back = Vector3(player.camera.global_basis.z.x,0,player.camera.global_basis.z.z).normalized()
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

func frame() -> Image:
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func save(image: Image, label: String) -> void:
	check(image.save_png("user://t09-%s.png" % label) == OK,"Capture failed: %s" % label)

## One physics tick; captures the last frame before each cut and the first after.
func tick() -> void:
	await physics_frame
	await process_frame
	var director: CameraDirector = scene.director
	if pending_after != "":
		save(await frame(),pending_after)
		pending_after = ""
	elif director.candidate != null and director.candidate_time > director.minimum_residence-1.5/60.0:
		cut_index += 1
		save(await frame(),"cut%d-before-%s" % [cut_index,director.current_shot.name])
		pending_after = "cut%d-after-%s" % [cut_index,director.candidate.name]

func walk_to(target: Vector3, running: bool = false) -> void:
	release()
	for i: int in range(12):
		await tick()
	var reached: bool = false
	for i: int in range(900):
		var delta: Vector3 = target-player.global_position
		delta.y = 0
		if delta.length() < 0.13:
			reached = true
			break
		steer(delta.normalized(),running and delta.length() > 1.0)
		await tick()
	release()
	for i: int in range(12):
		await tick()
	check(reached,"Could not reach %s" % target)

func push_against(direction: Vector3, label: String) -> void:
	steer(direction)
	for i: int in range(70):
		await tick()
	save(await frame(),label)
	release()
	for i: int in range(15):
		await tick()

func visible_difference(a: Image, b: Image) -> int:
	var left: PackedByteArray = a.get_data()
	var right: PackedByteArray = b.get_data()
	var count: int = 0
	for index: int in range(0,left.size(),3):
		if absi(int(left[index])-int(right[index])) > 8:
			count += 1
	return count

func pose(position: Vector3, shot: ShotRig) -> Image:
	player.reset_to(Transform3D(Basis.IDENTITY,position))
	scene.director.reset_to(shot)
	for i: int in range(3):
		await process_frame
	return await frame()

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Visual report requires a graphical renderer")
		quit(1)
		return
	create_timer(300).timeout.connect(func() -> void: quit(124))
	root.size = Vector2i(1920,1080)
	scene = load("res://environments/technical_route.tscn").instantiate()
	root.add_child(scene)
	scene.pause_menu.pause_on_focus_loss = false
	player = scene.player
	for i: int in range(20):
		await tick()
	# Continuity: full round trip, frames around each cut.
	for target: Vector3 in [Vector3(-2.5,0,9),Vector3(-2.5,0,2),Vector3(0,0,2),Vector3(0,0,-4),Vector3(0,0.6,-8),Vector3(0,1.2,-11),Vector3(0,1.2,-15),Vector3(3.8,1.2,-15)]:
		await walk_to(target)
	# Collision: inside the 1,6 m passage beside the rack, then the end pad.
	await walk_to(Vector3(3.8,1.2,-18))
	save(await frame(),"collision-passage")
	await walk_to(Vector3(3.8,1.2,-20))
	await walk_to(Vector3(0,1.2,-23))
	save(await frame(),"endpoint")
	for target: Vector3 in [Vector3(3.8,1.2,-20),Vector3(3.8,1.2,-15),Vector3(0,1.2,-15),Vector3(0,1.2,-11),Vector3(0,0,-4),Vector3(0,0,2),Vector3(2.5,0,2),Vector3(2.5,0,9),Vector3(0,0,9)]:
		await walk_to(target,true)
	check(cut_index == 4,"Expected four cuts on the round trip, got %d" % cut_index)
	# Collision contacts with the real controller.
	await walk_to(Vector3(0,0,8))
	await push_against(Vector3.FORWARD,"collision-crate")
	await walk_to(Vector3(3,0,8))
	await push_against(Vector3.RIGHT,"collision-wall")
	await walk_to(Vector3(-2.5,0,2))
	await walk_to(Vector3(0,0,-4))
	await walk_to(Vector3(0,0.6,-8))
	save(await frame(),"collision-ramp")
	await push_against(Vector3.RIGHT,"collision-ramp-wall")
	# Static poses: occlusion in two shots, resolution sweep with actor visible.
	scene.director.set_physics_process(false)
	player.set_physics_process(false)
	var shots: Array[ShotRig] = scene.shots
	var behind_crate: Image = await pose(Vector3(-0.65,0,3.9),shots[0])
	save(behind_crate,"occlusion-crate")
	for mesh: MeshInstance3D in shots[0].occluders:
		mesh.hide()
	var crate_exposed: Image = await frame()
	for mesh: MeshInstance3D in shots[0].occluders:
		mesh.show()
	save(crate_exposed,"occlusion-crate-disabled")
	check(visible_difference(behind_crate,crate_exposed) > 100,"Crate occlusion not observable")
	var behind_rack: Image = await pose(Vector3(-2.5,1.2,-19.6),shots[2])
	save(behind_rack,"occlusion-rack")
	for mesh: MeshInstance3D in shots[2].occluders:
		mesh.hide()
	var rack_exposed: Image = await frame()
	for mesh: MeshInstance3D in shots[2].occluders:
		mesh.show()
	save(rack_exposed,"occlusion-rack-disabled")
	check(visible_difference(behind_rack,rack_exposed) > 100,"Rack occlusion not observable")
	var poses: Array[Vector3] = [Vector3(1.8,0,8.2),Vector3(0,0.6,-8),Vector3(2.5,1.2,-21)]
	for size: Vector2i in [Vector2i(1920,1080),Vector2i(1280,720),Vector2i(1280,960)]:
		root.size = size
		for index: int in range(shots.size()):
			var image: Image = await pose(poses[index],shots[index])
			check(image.get_size() == size,"Capture size differs from window")
			save(image,"resolution-%s-%dx%d" % [shots[index].name,size.x,size.y])
	print("T09 visual report cuts=",cut_index," failures=",failures)
	release()
	quit(0 if failures == 0 else 1)
