extends SceneTree
## Exercise real locomotion, bone poses, E input, cinematic and scene replacement.
const PATH: Array[Vector3] = [Vector3(0,0,17), Vector3(0,0,13), Vector3(0,0,9), Vector3(0,0,6.4), Vector3(-2.4,0,6.4), Vector3(-4.45,0,6.45), Vector3(-4.45,0.3,5.6), Vector3(-4.45,0.6,4.5), Vector3(-4.45,0.6,3.7)]
var failures: int = 0
var stages: Array[StringName] = []
var leg_changed: bool = false
var ticks: int = 0
var capture_index: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func tick(count: int = 1) -> void:
	for frame: int in range(count):
		await physics_frame
		await process_frame
		ticks += 1

func release() -> void:
	for action: String in ["move_left", "move_right", "move_up", "move_down", "run"]:
		Input.action_release(action)

func key(code: Key, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	event.echo = echo
	Input.parse_input_event(event)
	event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = false
	Input.parse_input_event(event)

func walk_to(player: PlayerController, target: Vector3, running: bool = false) -> void:
	release()
	await tick(12)
	var visual: Node = player.visual.get_node("DylanVisual")
	var bone: int = visual.skeleton.find_bone("tripo__1_Left_Limb_0")
	var initial: Quaternion = visual.skeleton.get_bone_pose_rotation(bone)
	var reached: bool = false
	for frame: int in range(1000):
		var direction: Vector3 = target - player.position
		direction.y = 0
		if direction.length() < 0.13:
			reached = true
			break
		direction = direction.normalized()
		var right: Vector3 = player.movement_reference.right if player.movement_reference.locked else player.camera.global_basis.x
		var back: Vector3 = player.movement_reference.back if player.movement_reference.locked else player.camera.global_basis.z
		right.y = 0
		back.y = 0
		var input := Vector2(direction.dot(right.normalized()), direction.dot(back.normalized()))
		for pair: Array in [["move_right",input.x], ["move_left",-input.x], ["move_down",input.y], ["move_up",-input.y]]:
			if pair[1] > 0.001:
				Input.action_press(pair[0], pair[1])
			else:
				Input.action_release(pair[0])
		if running:
			Input.action_press("run")
		await tick()
		if frame == 20:
			check(visual.animator.current_animation == ("run" if running else "walk"), "Locomotion clip did not follow actual velocity")
		if not initial.is_equal_approx(visual.skeleton.get_bone_pose_rotation(bone)):
			leg_changed = true
	release()
	await tick(20 if running else 12)
	check(reached, "Dylan could not reach doorway waypoint: " + str(target))
	check(visual.animator.current_animation == "idle", "Locomotion did not return to idle after stopping")

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.local/dylan-%s.png" % label)

func on_stage(value: StringName) -> void:
	stages.append(value)
	if value == &"latch":
		await capture("door-closed-%d" % capture_index)
	elif value == &"opening":
		await create_timer(0.8).timeout
		await capture("door-opening-%d" % capture_index)
	elif value == &"loading":
		var transition: Node = root.get_node("DoorTransition")
		check(is_equal_approx(transition.curtain.modulate.a, 1.0), "Scene changed before the screen was black")

func travel(room: Node, expected: String, number: int) -> void:
	capture_index = number
	stages.clear()
	check(room.doorway.can_interact(), "Door prompt not available at the doorway")
	var source: PlayerController = room.player
	var before: Vector3 = source.position
	key(KEY_E, true)
	await tick(2)
	check(not root.has_node("DoorTransition"), "Echo triggered a duplicate interaction")
	key(KEY_E)
	await tick(2)
	check(root.has_node("DoorTransition"), "E did not start the door cinematic")
	if not root.has_node("DoorTransition"):
		return
	var transition: Node = root.get_node("DoorTransition")
	# The first stage precedes the test's connection.
	check(transition.retro_filter.effect.material.get_shader_parameter("crt_enabled"), "Door cinematic did not inherit CRT mode")
	key(KEY_F4)
	check(transition.retro_filter.selected_mode == 2, "Filter changed while cinematic input was locked")
	stages.append(transition.stage)
	transition.stage_changed.connect(on_stage)
	check(not source.control_enabled, "Player movement remained enabled during the cinematic")
	check(source.visual.get_node("DylanVisual").animator.current_animation == "door_interact", "Dylan interaction gesture did not play")
	Input.action_press("move_right")
	key(KEY_E)
	key(KEY_R)
	await tick(8)
	check(source.position.distance_to(before) < 0.08, "Player moved or restarted during the door gesture")
	check(root.get_children().filter(func(node: Node) -> bool: return node.name == "DoorTransition").size() == 1, "More than one door cinematic was started")
	release()
	await transition.finished
	await tick(3)
	check(current_scene.scene_file_path == expected, "Incorrect room after doorway transition")
	check(current_scene.player.control_enabled, "Control was not restored after arrival")
	check(not root.has_node("DoorTransition"), "Transition layer leaked after arrival")
	check(current_scene.get_node("Frame/Composition/RetroFilter").effect.material.get_shader_parameter("crt_enabled"), "Arrival lost CRT mode")
	check(stages == [&"gesture", &"fade_out", &"latch", &"opening", &"crossing", &"loading", &"fade_in", &"complete"], "Missing cinematic stages: " + str(stages))
	await capture("arrival-%d" % number)

func run() -> void:
	create_timer(60).timeout.connect(func() -> void: quit(124))
	root.size = Vector2i(1920, 1080)
	var exterior: Node = load("res://environments/exterior.tscn").instantiate()
	root.add_child(exterior)
	current_scene = exterior
	await tick(25)
	var visual: Node = exterior.player.visual.get_node("DylanVisual")
	check(visual.animator.has_animation("idle") and visual.animator.has_animation("walk") and visual.animator.has_animation("run") and visual.animator.has_animation("door_interact"), "Dylan clips missing")
	check(visual.animator.current_animation == "idle", "Idle animation not selected at rest")
	check(is_equal_approx(visual.target_height, 1.8), "Dylan no longer fits the authored guardhouse")
	key(KEY_E)
	await tick(3)
	check(not root.has_node("DoorTransition"), "Door interacted from the distant road")
	await walk_to(exterior.player, Vector3(0,0,20), true)
	check(leg_changed, "Skeleton legs did not animate while moving")
	for point: Vector3 in PATH:
		await walk_to(exterior.player, point)
	await capture("exterior-door")
	exterior.get_node("Frame/Composition/RetroFilter").set_mode(2)
	await travel(exterior, "res://environments/save_room.tscn", 0)
	var inside: Node = current_scene
	check(inside.player.position.distance_to(Vector3(-2.4,0,0.55)) < 0.15, "Interior arrival outside entrance")
	await walk_to(inside.player, Vector3(-1.2,0,0.55))
	key(KEY_E)
	await tick(2)
	check(not root.has_node("DoorTransition"), "Door triggered outside interaction range inside")
	await walk_to(inside.player, Vector3(-2.4,0,0.55))
	if DisplayServer.get_name() != "headless":
		root.size = Vector2i(1280,960)
	await travel(inside, "res://environments/exterior.tscn", 1)
	check(current_scene.player.position.distance_to(Vector3(-4.45,0.6,3.85)) < 0.15, "Exit returned to road spawn instead of the doorway")
	check(current_scene.director.current_shot == current_scene.shots[2], "Exit selected the wrong camera")
	key(KEY_R)
	await tick(4)
	check(current_scene.player.position.distance_to(Vector3(0,0,22)) < 0.15, "Restart broken after door travel")
	print("DYLAN doors round_trips=1 animated_legs=", leg_changed, " ticks=", ticks, " failures=", failures)
	quit(0 if failures == 0 else 1)
