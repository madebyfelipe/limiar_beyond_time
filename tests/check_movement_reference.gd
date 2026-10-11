extends SceneTree
var failures: int = 0
var player: PlayerController
var director: CameraDirector
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
func ticks(count: int) -> void:
	for i: int in range(count):
		await physics_frame
	await process_frame
func capture(name: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://t05-%s.png" % name)
func run() -> void:
	create_timer(30).timeout.connect(func() -> void: quit(124))
	var scene: Control = load("res://environments/movement_study.tscn").instantiate()
	root.add_child(scene)
	world = scene.get_node("Frame/Composition/Actors/WorldViewport/World")
	player = world.get_node("Player")
	director = world.get_node("Director")
	var case_id: int = 0
	for actions: Array in [["move_up"], ["move_up","move_right"], ["move_up","run"], ["move_up","move_right","run"]]:
		release()
		player.reset_to_start()
		player.global_position = Vector3(-4,0.05,1.0)
		await ticks(25)
		check(director.current_shot.definition.shot_id == &"study_a", "Start camera incorrect")
		for action: String in actions:
			Input.action_press(action)
		await ticks(4)
		var expected: Vector3 = player.desired_direction
		await capture("before-%d" % case_id)
		for frame: int in range(100):
			await ticks(1)
			check(player.desired_direction.distance_to(expected) < 0.0001, "World direction changed while held")
			if director.current_shot.definition.shot_id == &"study_b":
				break
		check(director.current_shot.definition.shot_id == &"study_b", "No physical transition reached")
		await ticks(4)
		check(player.desired_direction.distance_to(expected) < 0.0001, "Direction changed after cut")
		await capture("after-%d" % case_id)
		release()
		await ticks(1)
		check(not player.movement_reference.locked, "Reference not released")
		Input.action_press("move_up")
		await ticks(1)
		var back: Vector3 = player.camera.global_basis.z
		back.y = 0
		check(player.desired_direction.distance_to(-back.normalized()) < 0.0001, "New input did not use current camera")
		print("T05 actions=", actions, " held=",expected," reacquired=",player.desired_direction)
		case_id += 1
	# Opposed directional keys produce zero vector but keep the saved base.
	release()
	await ticks(1)
	Input.action_press("move_up")
	await ticks(1)
	var saved: Vector3 = player.movement_reference.back
	Input.action_press("move_down")
	await ticks(1)
	check(player.movement_reference.locked, "Opposed keys released reference")
	player.camera = world.get_node("ShotA/Camera")
	Input.action_release("move_down")
	await ticks(1)
	check(player.desired_direction.distance_to(-saved) < 0.0001, "Opposed key release acquired wrong camera")
	player.reset_to_start()
	check(not player.movement_reference.locked, "Reset retained movement reference")
	release()
	print("T05 failures=",failures)
	quit(0 if failures == 0 else 1)
