extends SceneTree
var failures: int = 0
var changes: int = 0
var scene: Control
var player: PlayerController
var director: CameraDirector
var presentation: PresentationController
var world: Node3D
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
func release() -> void:
	for action: String in ["move_left","move_right","move_up","move_down","run"]:
		Input.action_release(action)
func coherent() -> void:
	var shot: ShotRig = director.current_shot
	check(shot != null and presentation.current_shot == shot, "Director/presentation mismatch")
	if shot == null:
		return
	check(presentation.background.texture == shot.definition.background, "Wrong background")
	check(player.camera == shot.camera and shot.camera.is_current(), "Wrong camera")
	for rig: ShotRig in presentation.shots:
		for mesh: MeshInstance3D in rig.occluders:
			check(mesh.visible == (rig == shot), "Wrong occluder set")
		check(rig.light.visible == (rig == shot), "Wrong light")
func tick(count: int = 1) -> void:
	for i: int in range(count):
		await physics_frame
		coherent()
	await process_frame
func position_at(at: Vector3) -> void:
	release()
	player.global_position = at
	player.velocity = Vector3.ZERO
	await tick(20)
func run() -> void:
	create_timer(90).timeout.connect(func() -> void: quit(124))
	scene = load("res://environments/camera_study.tscn").instantiate()
	root.add_child(scene)
	world = scene.get_node("Frame/Composition/Actors/WorldViewport/World")
	player = world.get_node("Player")
	director = world.get_node("Director")
	presentation = world.get_node("Presentation")
	director.shot_changed.connect(func(_a: StringName, _b: StringName) -> void:
		changes += 1
		coherent()
	)
	await position_at(Vector3(-2,0.05,1.8))
	check(director.current_shot.definition.shot_id == &"study_a", "Initial shot incorrect")
	changes = 0
	for crossing: int in range(40):
		var right: bool = crossing % 2 == 0
		# Start each pass in the front test lane; T05 will preserve direction
		# across cuts. The actual crossing itself uses the real controller.
		player.global_position.z = 1.8 if right else 0.9
		Input.action_press("move_right" if right else "move_left")
		for step: int in range(160):
			await tick()
			if (player.global_position.x > 1.0 if right else player.global_position.x < -1.0):
				break
		release()
		await tick(16)
		check(director.current_shot.definition.shot_id == (&"study_b" if right else &"study_a"), "Traversal did not select expected shot")
		check(changes == crossing + 1, "Unexpected camera oscillation or missing cut")
		if crossing < 2 and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("user://t04-shot-%s.png" % director.current_shot.definition.shot_id)
	# A candidate that leaves before 0.2 seconds must not cause a cut.
	await position_at(Vector3(-2,0.05,2.8))
	var before: int = changes
	player.global_position = Vector3(2,0.05,2.8)
	await tick(5)
	check(changes == before, "Minimum residence ignored")
	player.global_position = Vector3(-2,0.05,2.8)
	await tick(20)
	check(changes == before, "Short candidate caused delayed cut")
	# In equal-priority overlap, preserve whichever shot is current.
	var zone_b: CameraZone = world.get_node("ZoneB")
	zone_b.shot_priority = 0
	await position_at(Vector3(0,0.05,2.8))
	check(director.current_shot.definition.shot_id == &"study_a", "Tie failed to preserve A")
	await position_at(Vector3(2,0.05,2.8))
	await position_at(Vector3(0,0.05,2.8))
	check(director.current_shot.definition.shot_id == &"study_b", "Tie failed to preserve B")
	zone_b.shot_priority = 1
	var retained: ShotRig = director.current_shot
	await position_at(Vector3(0,3,8))
	check(director.current_shot == retained, "No-zone fallback lost last valid shot")
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(Vector3(0,1,2),Vector3(0,1,-2))
	check(not world.get_world_3d().direct_space_state.intersect_ray(query).is_empty(), "Shared obstacle disappeared after cut")
	release()
	print("T04 traversals=20 per direction failures=",failures," total_changes=",changes)
	quit(0 if failures == 0 else 1)
