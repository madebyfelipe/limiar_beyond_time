extends SceneTree
## Transitions and reactions over Dylan's locomotion: the stop after a run, the
## look around after a long idle, the flinch on a hit, the pistol cycles with
## the gun up and the death fall, each handing back to locomotion.
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", message)
func tick(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame
func run() -> void:
	var scene: Node = load("res://environments/firing_range.tscn").instantiate()
	root.add_child(scene)
	await tick(8)
	var player: PlayerController = scene.player
	var visual: Node3D = player.visual.get_node("DylanVisual")
	var animator: AnimationPlayer = visual.animator
	for name: String in ["run_stop", "hit", "hit_aim", "death", "idle_look", "aim_idle", "aim_walk", "aim_walk_back", "strafe_left", "strafe_right", "startled", "terminal_type"]:
		check(animator.has_animation(name), "Clip missing from the library: " + name)
	for name: String in ["run_stop", "hit", "hit_aim", "death", "idle_look", "startled"]:
		check(animator.get_animation(name).loop_mode == Animation.LOOP_NONE, "One-shot loops: " + name)
	for name: String in ["aim_walk", "aim_walk_back", "strafe_left", "strafe_right", "terminal_type"]:
		check(animator.get_animation(name).loop_mode == Animation.LOOP_LINEAR, "Cycle does not loop: " + name)

	# Run, let go: the stop plays, then the idle.
	Input.action_press("move_up")
	Input.action_press("run")
	await tick(40)
	check(animator.current_animation == "run", "Holding run did not run: " + animator.current_animation)
	Input.action_release("move_up")
	Input.action_release("run")
	# Braking from 3,8 m/s takes about six frames.
	await tick(8)
	check(animator.current_animation == "run_stop", "Stopping a run did not play the stop: " + animator.current_animation)
	await tick(90)
	check(animator.current_animation == "idle", "The stop did not hand back to idle: " + animator.current_animation)

	# A long idle is broken by a look around, which walking cancels.
	visual._idle_time = 9.0
	await tick(3)
	check(animator.current_animation == "idle_look", "Long idle did not look around: " + animator.current_animation)
	Input.action_press("move_up")
	await tick(12)
	check(animator.current_animation == "walk", "Walking did not cancel the look around: " + animator.current_animation)
	Input.action_release("move_up")
	await tick(30)

	# A hit flinches, then returns to the stance.
	check(player.take_damage(5.0), "Damage was refused")
	await tick(3)
	check(animator.current_animation == "hit", "A hit did not flinch: " + animator.current_animation)
	await tick(80)
	check(animator.current_animation == "idle", "The flinch did not return to idle: " + animator.current_animation)

	# Gun up: the pistol cycles, never the unarmed walk.
	Input.action_press("aim")
	await tick(10)
	check(animator.current_animation in ["aim_idle", "turn_left", "turn_right"], "Raised gun did not take the pistol stance: " + animator.current_animation)
	for action: String in ["move_right", "move_left", "move_up", "move_down"]:
		Input.action_press(action)
		await tick(20)
		check(animator.current_animation in ["aim_walk", "aim_walk_back", "strafe_left", "strafe_right"], "Aimed step %s did not use a pistol cycle: %s" % [action, animator.current_animation])
		Input.action_release(action)
		await tick(10)
	Input.action_release("aim")
	await tick(30)

	# Death falls once and stays down; a reset brings back the stance.
	player.invulnerability_left = 0.0
	player.take_damage(1000.0)
	await tick(5)
	check(player.is_dead(), "Lethal damage did not kill")
	check(animator.current_animation == "death", "Death did not play its fall: " + animator.current_animation)
	await tick(240)
	check(animator.current_animation == "death" or animator.assigned_animation == "death", "Death did not hold its last pose")
	check(absf(visual.rotation.z) < 0.01, "Death still tilts the model as well as playing the fall")
	player.reset_to_start()
	await tick(10)
	check(animator.current_animation == "idle", "Reset did not bring back the idle: " + animator.current_animation)
	scene.queue_free()
	await tick(3)
	print("DYLAN_TRANSITIONS failures=", failures)
	quit(1 if failures > 0 else 0)
