extends SceneTree
var failures: int = 0
var player: PlayerController
func _initialize() -> void:
	call_deferred("run_test")
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
func place(position: Vector3) -> void:
	release()
	player.global_position = position
	player.velocity = Vector3.ZERO
	await ticks(10)
func speed(actions: Array[String]) -> float:
	await place(Vector3(-2,0.05,2))
	for action: String in actions:
		Input.action_press(action)
	await ticks(20)
	var measured: float = Vector2(player.velocity.x,player.velocity.z).length()
	release()
	return measured
func run_test() -> void:
	create_timer(60).timeout.connect(func() -> void: quit(124))
	var scene: Control = load("res://environments/locomotion.tscn").instantiate()
	root.add_child(scene)
	player = scene.get_node("Frame/Composition/Actors/WorldViewport/World/Player")
	var bindings: Dictionary = {"move_left": [KEY_A,KEY_LEFT], "move_right": [KEY_D,KEY_RIGHT], "move_up": [KEY_W,KEY_UP], "move_down": [KEY_S,KEY_DOWN], "run": [KEY_SHIFT]}
	for action: String in bindings:
		var configured: Array[int] = []
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey:
				configured.append(event.physical_keycode)
		for key: int in bindings[action]:
			check(configured.has(key), "Missing physical key binding for " + action)
	await ticks(10)
	var walk: float = await speed(["move_up"])
	var diagonal: float = await speed(["move_up","move_right"])
	var sprint: float = await speed(["move_up","run"])
	# The configured values are guarded by check_units; here the body must reach them.
	check(absf(walk - player.config.walk_speed) < 0.01, "Walk speed incorrect")
	check(absf(diagonal - walk) < 0.01, "Diagonal speed gain")
	check(absf(sprint - player.config.run_speed) < 0.01, "Run speed incorrect")
	await place(Vector3(-4,0.05,0))
	Input.action_press("move_left")
	await ticks(90)
	check(player.global_position.x > -4.61, "Left wall crossed")
	release()
	await ticks(30)
	var stopped: Vector3 = player.global_position
	await ticks(120)
	check(player.global_position.distance_to(stopped) < 0.001, "Idle drift")
	for case: Dictionary in [
		{"at":Vector3(4,0.05,0), "action":"move_right", "axis":0, "limit":4.61},
		{"at":Vector3(-2,0.05,4), "action":"move_down", "axis":2, "limit":4.61},
		{"at":Vector3(-2,0.05,-4), "action":"move_up", "axis":2, "limit":-4.61}
	]:
		await place(case.at)
		Input.action_press(case.action)
		await ticks(60)
		var coordinate: float = player.global_position[case.axis]
		check(coordinate < case.limit if case.limit > 0 else coordinate > case.limit, "Wall crossed: " + case.action)
	await place(Vector3(1.5,0.05,2.4))
	Input.action_press("move_up")
	# Climb until the ramp is cleared, so the budget follows the configured
	# walking speed instead of assuming one.
	var climbed: bool = false
	for frame: int in range(300):
		await ticks(1)
		if player.global_position.y > 0.7:
			climbed = true
			break
	check(climbed, "Ramp not walkable")
	check(player.is_on_floor(), "Lost floor on ramp")
	print("T03 ramp=", player.global_position)
	release()
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://t03-ramp.png")
	Input.action_press("move_down")
	await ticks(90)
	check(player.global_position.y < 0.35 and player.is_on_floor(), "Ramp descent lost ground")
	release()
	await ticks(30)
	player.set_control_enabled(false)
	var disabled_at: Vector3 = player.global_position
	Input.action_press("move_up")
	await ticks(30)
	check(player.global_position.distance_to(disabled_at) < 0.001, "Disabled control still moves")
	player.set_control_enabled(true)
	player.reset_to_start()
	check(player.velocity == Vector3.ZERO and player.global_transform == player.spawn_transform, "Reset failed")
	print("T03 walk=",walk," diagonal=",diagonal," run=",sprint," stopped=",stopped," failures=",failures)
	release()
	quit(0 if failures == 0 else 1)
