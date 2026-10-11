extends SceneTree
## T10 robustness proxy: ten minutes of game time on the real route with the
## real controller — round trips walking and running, pauses, F3, restarts
## mid-lap and fall recoveries — failing on any engine/script error, a lap
## that cannot finish, or growth of nodes/objects/static memory.
## Optional: -- --minutes=N (default 10). Automated; not a human play session.

class ErrorCapture extends Logger:
	var errors: PackedStringArray = []
	var mutex := Mutex.new()
	func _log_error(_function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, _error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		mutex.lock()
		errors.append("%s:%d %s %s" % [file, line, code, rationale])
		mutex.unlock()
	func _log_message(_message: String, _error: bool) -> void:
		pass

const OUTWARD: Array[Vector3] = [Vector3(-2.5,0,9),Vector3(-2.5,0,2),Vector3(0,0,2),Vector3(0,0,-4),Vector3(0,0.6,-8),Vector3(0,1.2,-11),Vector3(0,1.2,-15),Vector3(3.8,1.2,-15),Vector3(3.8,1.2,-20),Vector3(0,1.2,-23)]
const RETURN: Array[Vector3] = [Vector3(3.8,1.2,-20),Vector3(3.8,1.2,-15),Vector3(0,1.2,-15),Vector3(0,1.2,-11),Vector3(0,0,-4),Vector3(0,0,2),Vector3(2.5,0,2),Vector3(2.5,0,9),Vector3(0,0,9)]
var scene: Control
var player: PlayerController
var failures: int = 0
var game_seconds: float = 0.0
var completions: int = 0
var recoveries: int = 0
var restarts: int = 0
var cuts: int = 0
var travelled: float = 0.0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func key(code: Key) -> void:
	for pressed: bool in [true,false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		root.push_input(event)

func release() -> void:
	for action: String in ["move_left","move_right","move_up","move_down","run"]:
		Input.action_release(action)

func steer(direction: Vector3, running: bool) -> void:
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

func tick(count: int = 1) -> void:
	for i: int in range(count):
		var before: Vector3 = player.global_position
		await physics_frame
		await process_frame
		if not paused:
			game_seconds += 1.0/60.0
			travelled += before.distance_to(player.global_position)

func walk_to(target: Vector3, running: bool) -> bool:
	for i: int in range(1200):
		var delta: Vector3 = target-player.global_position
		delta.y = 0
		if delta.length() < 0.13:
			return true
		steer(delta.normalized(),running and delta.length() > 1.0)
		await tick()
	release()
	return false

func follow(points: Array[Vector3], running: bool) -> bool:
	for target: Vector3 in points:
		if not await walk_to(target,running):
			check(false,"Stuck before %s at %s (%.1f s)" % [target,player.position,game_seconds])
			return false
	release()
	await tick(10)
	return true

func pause_briefly() -> void:
	key(KEY_ESCAPE)
	check(paused,"Esc did not pause during soak")
	await tick(30)
	key(KEY_F3)
	await tick(5)
	key(KEY_ESCAPE)
	check(not paused,"Esc did not resume during soak")

func restart_from_menu() -> void:
	key(KEY_ESCAPE)
	# Focus navigation needs the menu laid out once after becoming visible.
	await process_frame
	key(KEY_DOWN)
	key(KEY_ENTER)
	check(not paused and scene.progress.stage == RouteProgress.Stage.OUTBOUND and scene.director.current_shot == scene.shots[0],"Restart failed during soak")
	await tick(10)

func run() -> void:
	var minutes: float = 10.0
	for option: String in OS.get_cmdline_user_args():
		if option.begins_with("--minutes="):
			minutes = option.trim_prefix("--minutes=").to_float()
	create_timer(minutes*60.0+600.0).timeout.connect(func() -> void: quit(124))
	root.size = Vector2i(1920,1080)
	scene = load("res://environments/technical_route.tscn").instantiate()
	root.add_child(scene)
	scene.pause_menu.pause_on_focus_loss = false
	player = scene.player
	scene.progress.route_completed.connect(func(_elapsed: float) -> void: completions += 1)
	scene.recovered.connect(func(_pad: Vector3) -> void: recoveries += 1)
	scene.restarted.connect(func() -> void: restarts += 1)
	scene.director.shot_changed.connect(func(_from: StringName, _to: StringName) -> void: cuts += 1)
	var capture := ErrorCapture.new()
	OS.add_logger(capture)
	await tick(30)
	var baseline_nodes: float = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var baseline_objects: float = Performance.get_monitor(Performance.OBJECT_COUNT)
	var baseline_memory: float = Performance.get_monitor(Performance.MEMORY_STATIC)
	var lap: int = 0
	var expected_completions: int = 0
	while game_seconds < minutes*60.0 and failures == 0:
		lap += 1
		var running: bool = lap % 2 == 0
		if not await follow(OUTWARD.slice(0,5),running):
			break
		if lap % 3 == 0:
			await pause_briefly()
		if lap % 5 == 0:
			# Mid-lap restart from the corridor: the lap starts over.
			await restart_from_menu()
			continue
		if not await follow(OUTWARD.slice(5),running):
			break
		check(scene.progress.stage == RouteProgress.Stage.RETURNING,"Endpoint not registered on lap %d" % lap)
		if lap % 4 == 0:
			# Simulated fall from the upper area: back on the golden pad.
			var before: int = recoveries
			player.global_position = Vector3(8.5,1.7,-19)
			for i: int in range(240):
				await tick()
				if recoveries > before:
					break
			check(recoveries == before+1,"Recovery did not happen on lap %d" % lap)
			await tick(5)
		if not await follow(RETURN,true):
			break
		expected_completions += 1
		check(completions == expected_completions and scene.progress.stage == RouteProgress.Stage.COMPLETED,"Lap %d did not complete" % lap)
		await restart_from_menu()
		var nodes: float = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
		var objects: float = Performance.get_monitor(Performance.OBJECT_COUNT)
		var memory: float = Performance.get_monitor(Performance.MEMORY_STATIC)
		print("T10 soak lap=%d game_s=%.1f completions=%d recoveries=%d restarts=%d cuts=%d nodes=%d objects=%d static_mib=%.2f" % [lap,game_seconds,completions,recoveries,restarts,cuts,nodes,objects,memory/1048576.0])
		check(nodes <= baseline_nodes,"Node count grew: %d → %d" % [baseline_nodes,nodes])
		check(objects <= baseline_objects+50,"Object count grew: %d → %d" % [baseline_objects,objects])
		check(memory <= baseline_memory+8.0*1048576.0,"Static memory grew more than 8 MiB")
		check(capture.errors.is_empty(),"Engine/script errors during soak: %s" % "\n".join(capture.errors))
	OS.remove_logger(capture)
	check(game_seconds >= minutes*60.0,"Soak ended early at %.1f s" % game_seconds)
	check(completions >= 1 and recoveries >= 1 and restarts >= 2,"Soak did not exercise completion/recovery/restart")
	print("T10 soak minutes=%.1f game_s=%.1f laps=%d completions=%d recoveries=%d restarts=%d cuts=%d distance_m=%.1f failures=%d" % [minutes,game_seconds,lap,completions,recoveries,restarts,cuts,travelled,failures])
	release()
	paused = false
	quit(0 if failures == 0 else 1)
