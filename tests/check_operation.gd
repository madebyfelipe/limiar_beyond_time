extends SceneTree
## T08 on the real route scene: pause, restart, F3 readout, completion,
## recovery and focus loss. UI receives real InputEvents through push_input;
## locomotion uses Input actions like the T07 probe. The route itself is
## driven without teleports; the two teleports below only simulate leaving
## the level so the recovery path can be observed.
var scene: Control
var player: PlayerController
var menu: PauseMenu
var overlay: DiagnosticsOverlay
var progress: RouteProgress
var failures: int = 0
var cuts: Array[StringName] = []
var completions: Array[float] = []
var endpoint_events: int = 0
var recoveries: Array[Vector3] = []
var recovery_states: Array = []
var restarts: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	root.push_input(event)

## Press and release; the UI handles pushed events synchronously, so state
## may be checked before any physics tick runs.
func press(code: Key) -> void:
	key(code,true)
	key(code,false)

func tap(code: Key) -> void:
	press(code)
	await process_frame

func release() -> void:
	for action: String in ["move_left","move_right","move_up","move_down","run"]:
		Input.action_release(action)

func horizontal(vector: Vector3) -> Vector3:
	return Vector3(vector.x,0,vector.z).normalized()

func steer(direction: Vector3, running: bool = false) -> void:
	var right: Vector3 = player.movement_reference.right
	var back: Vector3 = player.movement_reference.back
	if not player.movement_reference.locked:
		right = horizontal(player.camera.global_basis.x)
		back = horizontal(player.camera.global_basis.z)
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
	for frame: int in range(count):
		await physics_frame
		await process_frame

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
	release()
	await tick(12)
	check(reached,"Could not reach waypoint %s; stopped at %s" % [target,player.position])

func capture(label: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png("user://t08-%s.png" % label) == OK,"Capture failed")

func presentation_matches(shot: ShotRig) -> bool:
	return scene.director.current_shot == shot and scene.presentation.current_shot == shot and player.camera == shot.camera and shot.camera.current and scene.background.texture == shot.definition.background

func fall_and_recover(start: Vector3) -> void:
	var count: int = recoveries.size()
	player.global_position = start
	for frame: int in range(240):
		await tick()
		if recoveries.size() > count:
			break
	check(recoveries.size() == count+1,"Fall below the level was not recovered from %s" % start)

func run() -> void:
	create_timer(240).timeout.connect(func() -> void: quit(124))
	root.size = Vector2i(1920,1080)
	scene = load("res://environments/technical_route.tscn").instantiate()
	root.add_child(scene)
	player = scene.player
	menu = scene.pause_menu
	overlay = scene.diagnostics
	progress = scene.progress
	scene.director.shot_changed.connect(func(_from: StringName, to: StringName) -> void: cuts.append(to))
	progress.route_completed.connect(func(elapsed: float) -> void: completions.append(elapsed))
	progress.endpoint_reached.connect(func() -> void: endpoint_events += 1)
	scene.recovered.connect(func(pad: Vector3) -> void:
		recoveries.append(pad)
		recovery_states.append([player.global_position,player.velocity,scene.director.current_shot]))
	scene.restarted.connect(func() -> void: restarts += 1)
	var shots: Array[ShotRig] = scene.shots
	# Real focus changes on the desktop -- another probe window, the person at
	# the machine -- would pause the walk and the falls below at random. Focus
	# pausing is switched on only for the section that tests it, with notices
	# sent by the probe itself.
	menu.pause_on_focus_loss = false
	await tick(20)

	# Initial state and process modes.
	check(not paused and not menu.visible and not overlay.visible and not scene.notice.visible,"Unexpected initial operation state")
	check(menu.process_mode == Node.PROCESS_MODE_ALWAYS and overlay.process_mode == Node.PROCESS_MODE_ALWAYS,"UI must process while paused")
	check(progress.stage == RouteProgress.Stage.OUTBOUND and scene.instructions.text.contains("Esc: pausa") and scene.instructions.text.contains("F3"),"Objective/controls missing")
	check(presentation_matches(shots[0]),"Initial presentation incoherent")

	# F3 readout.
	await tap(KEY_F3)
	check(overlay.visible,"F3 did not show diagnostics")
	await tick(3)
	for fragment: String in ["FPS","Posição","Enquadramento route_1","Referência livre","Percurso ida","Simulação ativa"]:
		check(overlay.label.text.contains(fragment),"Diagnostics missing '%s': %s" % [fragment,overlay.label.text])
	await capture("f3")

	# Esc pauses and resumes; UI keeps processing while paused.
	await tap(KEY_ESCAPE)
	check(paused and menu.visible and menu.resume_button.has_focus(),"Esc did not open focused pause menu")
	await tick(5)
	check(overlay.label.text.contains("Simulação pausada"),"Diagnostics stopped updating while paused")
	await tap(KEY_F3)
	check(not overlay.visible,"F3 inoperable while paused")
	await tap(KEY_F3)
	check(overlay.visible,"F3 inoperable while paused (show)")
	await capture("pause-menu")
	root.size = Vector2i(1280,960)
	await tick(3)
	check(menu.get_global_rect().size == Vector2(root.get_visible_rect().size),"Pause menu must cover the whole window, bars included")
	await capture("pause-menu-4x3")
	root.size = Vector2i(1920,1080)
	await tick(3)
	await tap(KEY_ESCAPE)
	check(not paused and not menu.visible,"Esc did not resume")

	# Pause suspends physics, the pending cut candidate and the route clock.
	for target: Vector3 in [Vector3(-2.5,0,9),Vector3(-2.5,0,2),Vector3(0,0,2)]:
		await walk_to(target)
	check(presentation_matches(shots[0]),"Cut happened before the pause test")
	steer(Vector3.FORWARD)
	for frame: int in range(120):
		await tick()
		if scene.director.candidate != null:
			break
	await tick(3)
	check(scene.director.candidate == shots[1] and scene.director.current_shot == shots[0],"No pending candidate before pausing")
	var frozen_position: Vector3 = player.global_position
	var frozen_velocity: Vector3 = player.velocity
	var frozen_candidate: float = scene.director.candidate_time
	var frozen_clock: float = progress.elapsed
	var frozen_cuts: int = cuts.size()
	await tap(KEY_ESCAPE)
	check(paused and not player.movement_reference.locked,"Pause did not interrupt the movement reference")
	await tick(90)
	check(player.global_position.distance_to(frozen_position) < 0.000001 and player.velocity == frozen_velocity,"Physics advanced while paused")
	check(scene.director.current_shot == shots[0] and is_equal_approx(scene.director.candidate_time,frozen_candidate) and cuts.size() == frozen_cuts,"Camera selection advanced while paused")
	check(is_equal_approx(progress.elapsed,frozen_clock),"Route clock advanced while paused")
	await tap(KEY_ESCAPE)
	var cut_ticks: int = 0
	for frame: int in range(30):
		await tick()
		cut_ticks += 1
		if cuts.size() > frozen_cuts:
			break
	check(cuts.size() == frozen_cuts+1 and cuts[-1] == &"route_2" and presentation_matches(shots[1]),"Cut did not resume after pause")
	check(cut_ticks <= 13,"Residence restarted from zero instead of resuming: %d ticks" % cut_ticks)
	check(horizontal(shots[0].camera.global_basis.x).distance_to(player.movement_reference.right) < 0.0001,"W held through the cut lost its reference")

	# Keys changed during a pause: new input uses the current camera.
	await tap(KEY_ESCAPE)
	release()
	Input.action_press("move_right")
	await tap(KEY_ESCAPE)
	await tick(2)
	var current_right: Vector3 = horizontal(shots[1].camera.global_basis.x)
	check(current_right.distance_to(player.movement_reference.right) < 0.0001 and current_right.distance_to(player.desired_direction) < 0.0001,"Input after pause did not use the current camera")
	release()
	await tick(15)

	# Restart from the pause menu with keyboard navigation, holding W.
	steer(Vector3.FORWARD)
	await tick(5)
	await tap(KEY_ESCAPE)
	await tap(KEY_DOWN)
	check(menu.restart_button.has_focus(),"Keyboard focus did not reach restart")
	press(KEY_ENTER)
	check(restarts == 1 and not paused and not menu.visible,"Restart button did not restart and resume")
	check(player.global_transform.is_equal_approx(player.spawn_transform) and player.velocity == Vector3.ZERO and player.visual.rotation == Vector3.ZERO,"Restart did not restore the actor")
	check(presentation_matches(shots[0]) and scene.director.candidate == null,"Restart did not restore the camera")
	check(progress.stage == RouteProgress.Stage.OUTBOUND and progress.elapsed == 0.0 and not scene.notice.visible,"Restart left route state")
	await tick(1)
	check(horizontal(shots[0].camera.global_basis.x).distance_to(player.movement_reference.right) < 0.0001,"Restart did not restore input reference")
	release()
	await tick(40)
	check(presentation_matches(shots[0]),"Stale camera state after restart")
	check(player.global_position.distance_to(player.spawn_transform.origin) < 1.0,"Actor drifted after restart")

	# Focus loss pauses; focus return does not resume.
	menu.pause_on_focus_loss = true
	root.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(paused and menu.visible,"Application focus loss did not pause")
	root.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	await tick(10)
	check(paused and menu.visible,"Focus return resumed automatically")
	await tap(KEY_ENTER)
	check(not paused and not menu.visible,"Continue button inoperable")
	root.propagate_notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	check(paused,"Window focus loss did not pause")
	root.propagate_notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_IN)
	await tick(10)
	check(paused,"Window focus return resumed automatically")
	await tap(KEY_ESCAPE)
	menu.pause_on_focus_loss = false
	root.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not paused,"Disabled focus pause still paused")

	# Recovery during the outbound leg: corridor (route_2) → start pad (route_1).
	await walk_to(Vector3(-2.5,0,9))
	await walk_to(Vector3(-2.5,0,2))
	await walk_to(Vector3(0,0,-4))
	check(presentation_matches(shots[1]),"Corridor shot expected before recovery")
	await fall_and_recover(Vector3(8.5,0.5,-6))
	check(recoveries.size() == 1 and recoveries[0] == progress.start_pad,"Outbound recovery used the wrong checkpoint")
	check(recovery_states[0][0].distance_to(progress.start_pad+Vector3(0,0.06,0)) < 0.001 and recovery_states[0][1] == Vector3.ZERO,"Actor not restored to the start pad")
	check(recovery_states[0][2] == shots[0] and presentation_matches(shots[0]) and progress.stage == RouteProgress.Stage.OUTBOUND,"Outbound recovery camera/stage incoherent")
	check(scene.notice.visible and scene.notice.text.contains("Recuperação"),"Recovery notice missing")
	await tick(2)
	await capture("recovered")
	await tick(200)
	check(not scene.notice.visible,"Recovery notice did not expire")

	# Outbound route without teleports; endpoint feedback.
	for target: Vector3 in [Vector3(-2.5,0,9),Vector3(-2.5,0,2),Vector3(0,0,2),Vector3(0,0,-4),Vector3(0,0.6,-8),Vector3(0,1.2,-11),Vector3(0,1.2,-15),Vector3(3.8,1.2,-15),Vector3(3.8,1.2,-20),Vector3(0,1.2,-23)]:
		await walk_to(target)
	check(endpoint_events == 1 and progress.stage == RouteProgress.Stage.RETURNING,"Endpoint not registered")
	check(scene.instructions.text.contains("Volte à marca azul") and scene.notice.visible,"Endpoint feedback missing")
	await capture("endpoint")

	# Recovery during the return leg: corridor (route_2) → end pad (route_3).
	for target: Vector3 in [Vector3(3.8,1.2,-20),Vector3(3.8,1.2,-15),Vector3(0,1.2,-15),Vector3(0,1.2,-11),Vector3(0,0,-4)]:
		await walk_to(target,true)
	check(presentation_matches(shots[1]),"Corridor shot expected before return recovery")
	await fall_and_recover(Vector3(8.5,0.5,-6))
	check(recoveries.size() == 2 and recoveries[1] == progress.end_pad,"Return recovery used the wrong checkpoint")
	check(recovery_states[1][0].distance_to(progress.end_pad+Vector3(0,0.06,0)) < 0.001 and recovery_states[1][1] == Vector3.ZERO,"Actor not restored to the end pad")
	check(recovery_states[1][2] == shots[2] and presentation_matches(shots[2]),"Camera not restored to the end pad shot")
	check(progress.stage == RouteProgress.Stage.RETURNING and endpoint_events == 1,"Recovery changed route progress")

	# Return to the start pad completes the route.
	for target: Vector3 in [Vector3(3.8,1.2,-20),Vector3(3.8,1.2,-15),Vector3(0,1.2,-15),Vector3(0,1.2,-11),Vector3(0,0,-4),Vector3(0,0,2),Vector3(2.5,0,2),Vector3(2.5,0,9),Vector3(0,0,9)]:
		await walk_to(target,true)
	check(completions.size() == 1 and progress.stage == RouteProgress.Stage.COMPLETED,"Completion not registered")
	if completions.size() == 1:
		check(completions[0] > 10.0 and is_equal_approx(completions[0],progress.elapsed),"Completion time implausible: %s" % completions[0])
		check(scene.notice.visible and scene.notice.text.contains("CONCLUÍDO") and scene.notice.text.contains(scene.format_time(completions[0])),"Completion notice missing")
	check(scene.instructions.text.contains("Percurso concluído") and overlay.label.text.contains("Percurso concluído"),"Completion objective/readout missing")
	var final_clock: float = progress.elapsed
	await tick(200)
	check(progress.elapsed == final_clock and scene.notice.visible and completions.size() == 1,"Completed state not stable")
	await capture("completed")
	print("T08 completion_seconds=",completions," recoveries=",recoveries," cuts=",cuts)

	# Restart after completion clears all route feedback.
	await tap(KEY_ESCAPE)
	await tap(KEY_DOWN)
	press(KEY_ENTER)
	check(restarts == 2 and not paused and progress.stage == RouteProgress.Stage.OUTBOUND and progress.elapsed == 0.0,"Restart after completion failed")
	check(not scene.notice.visible and scene.instructions.text.contains("alcance a marca dourada") and presentation_matches(shots[0]),"Restart left completion feedback")
	await tick(5)
	await capture("restarted")
	check(scene.format_time(83.26) == "1:23,3" and scene.format_time(5.0) == "0:05,0","Time format incorrect")
	print("T08 failures=",failures)
	release()
	paused = false
	quit(0 if failures == 0 else 1)
