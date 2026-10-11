extends SceneTree
## T09 unit cases on the real classes (no copies of their logic): input
## normalization, MovementReference, CameraDirector reset/selection state,
## RouteProgress stages, PauseMenu state and configuration contracts.
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func near(a: Vector3, b: Vector3) -> bool:
	return a.distance_to(b) < 0.0001

func run() -> void:
	create_timer(60).timeout.connect(func() -> void: quit(124))
	await process_frame
	normalization()
	movement_reference()
	contracts()
	await camera_director()
	await route_progress()
	await pause_menu()
	print("T09 units failures=", failures)
	quit(0 if failures == 0 else 1)

func normalization() -> void:
	# Project bindings and engine vector: diagonals never exceed unit length.
	for actions: Array in [["move_up","move_right"],["move_down","move_left"],["move_up","move_left","move_right"]]:
		for action: String in actions:
			Input.action_press(action)
		var vector: Vector2 = Input.get_vector("move_left","move_right","move_up","move_down")
		check(vector.length() <= 1.0001,"Input vector exceeds unit length for %s: %s" % [actions,vector])
		for action: String in actions:
			Input.action_release(action)
	Input.action_press("move_up")
	Input.action_press("move_down")
	check(Input.get_vector("move_left","move_right","move_up","move_down").is_zero_approx(),"Opposite keys must cancel")
	Input.action_release("move_up")
	Input.action_release("move_down")

func movement_reference() -> void:
	var reference := MovementReference.new()
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.rotation_degrees = Vector3(-35,30,0)
	var right := Vector3(camera.global_basis.x.x,0,camera.global_basis.x.z).normalized()
	var back := Vector3(camera.global_basis.z.x,0,camera.global_basis.z.z).normalized()
	var diagonal: Vector3 = reference.direction_for(Vector2(1,1),camera,true)
	check(absf(diagonal.length()-1.0) < 0.0001 and absf(diagonal.y) < 0.0001,"Diagonal must be horizontal and unit: %s" % diagonal)
	check(near(diagonal,(right+back).normalized()),"Diagonal must follow camera axes")
	check(reference.locked,"First held input must lock the reference")
	var partial: Vector3 = reference.direction_for(Vector2(0.5,0),camera,true)
	check(absf(partial.length()-0.5) < 0.0001,"Analog magnitude below one must be preserved")
	camera.rotation_degrees = Vector3(-35,-80,0)
	check(near(reference.direction_for(Vector2(1,0),camera,true),right),"Locked basis must ignore camera changes while held")
	check(reference.direction_for(Vector2.ZERO,camera,false) == Vector3.ZERO and not reference.locked,"Releasing all keys must unlock")
	var new_right := Vector3(camera.global_basis.x.x,0,camera.global_basis.x.z).normalized()
	check(near(reference.direction_for(Vector2(1,0),camera,true),new_right),"New input must use the current camera")
	reference.reset()
	check(not reference.locked,"reset() must unlock")
	check(near(reference.direction_for(Vector2(0,-1),null,true),Vector3.FORWARD),"Without camera, world axes are used")
	camera.free()
	reference.free()

func contracts() -> void:
	var config: PlayerConfig = load("res://actors/player/default_player_config.tres")
	check(config.walk_speed == 2.5 and config.run_speed == 5.0 and config.acceleration == 15.0 and config.deceleration == 20.0 and config.gravity == 20.0,"PlayerConfig drifted from the architecture contract")
	for action: String in ["move_left","move_right","move_up","move_down","run","pause","toggle_diagnostics"]:
		check(InputMap.has_action(action) and not InputMap.action_get_events(action).is_empty(),"Input action missing: %s" % action)
	var escape := InputEventKey.new()
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	check(escape.is_action_pressed("pause"),"Esc must trigger pause")
	var f3 := InputEventKey.new()
	f3.physical_keycode = KEY_F3
	f3.pressed = true
	check(f3.is_action_pressed("toggle_diagnostics"),"F3 must toggle diagnostics")
	var route: GDScript = load("res://environments/technical_route.gd")
	check(route.format_time(83.26) == "1:23,3" and route.format_time(5.0) == "0:05,0" and route.format_time(600.0) == "10:00,0","Completion time format incorrect")

func make_shot(id: StringName) -> ShotRig:
	var rig := ShotRig.new()
	rig.definition = ShotDefinition.new()
	rig.definition.shot_id = id
	rig.definition.background = PlaceholderTexture2D.new()
	rig.camera = Camera3D.new()
	rig.add_child(rig.camera)
	rig.light = DirectionalLight3D.new()
	rig.add_child(rig.light)
	return rig

func camera_director() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var player: PlayerController = load("res://actors/player/player.tscn").instantiate()
	world.add_child(player)
	player.set_physics_process(false)
	var shots: Array[ShotRig] = [make_shot(&"a"),make_shot(&"b")]
	for shot: ShotRig in shots:
		world.add_child(shot)
	var background := TextureRect.new()
	root.add_child(background)
	var presentation := PresentationController.new()
	presentation.background = background
	presentation.player = player
	presentation.shots = shots
	world.add_child(presentation)
	var director := CameraDirector.new()
	director.player = player
	director.initial_shot = shots[0]
	director.presentation = presentation
	director.set_physics_process(false)
	var changes: Array = []
	director.shot_changed.connect(func(from: StringName, to: StringName) -> void: changes.append([from,to]))
	world.add_child(director)
	check(director.current_shot == shots[0] and player.camera == shots[0].camera,"Initial shot must be applied explicitly")
	check(changes == [[&"",&"a"]],"Initial activation must emit once: %s" % str(changes))
	changes.clear()
	director.candidate = shots[1]
	director.candidate_time = 0.15
	director.reset_to(shots[1])
	check(director.current_shot == shots[1] and presentation.current_shot == shots[1] and director.candidate == null and director.candidate_time == 0.0,"reset_to must apply immediately and clear the candidate")
	check(background.texture == shots[1].definition.background and player.camera == shots[1].camera and shots[1].light.visible and not shots[0].light.visible,"reset_to must apply the presentation atomically")
	check(changes == [[&"a",&"b"]],"reset_to must emit one shot change: %s" % str(changes))
	director.reset_to(shots[1])
	check(changes.size() == 1,"reset_to on the current shot must not emit")
	world.free()
	background.free()
	await process_frame

func route_progress() -> void:
	var player: PlayerController = load("res://actors/player/player.tscn").instantiate()
	root.add_child(player)
	player.set_physics_process(false)
	var progress := RouteProgress.new()
	progress.player = player
	progress.set_physics_process(false)
	root.add_child(progress)
	var reached: Array[int] = [0]
	var completed: Array[float] = []
	progress.endpoint_reached.connect(func() -> void: reached[0] += 1)
	progress.route_completed.connect(func(elapsed: float) -> void: completed.append(elapsed))
	player.global_position = progress.start_pad
	progress._physics_process(0.5)
	check(progress.stage == RouteProgress.Stage.OUTBOUND and completed.is_empty(),"Starting on the blue pad must not complete")
	check(progress.checkpoint() == progress.start_pad,"Outbound checkpoint must be the start pad")
	player.global_position = progress.end_pad + Vector3(0.99,0,0.74)
	progress._physics_process(0.5)
	check(progress.stage == RouteProgress.Stage.RETURNING and reached[0] == 1,"Pad edge must register the endpoint")
	check(progress.checkpoint() == progress.end_pad,"Return checkpoint must be the end pad")
	player.global_position = progress.end_pad + Vector3(0,-1.2,0)
	progress._physics_process(0.5)
	check(progress.stage == RouteProgress.Stage.RETURNING,"Pad footprint must respect height")
	player.global_position = progress.start_pad + Vector3(1.05,0,0)
	progress._physics_process(0.5)
	check(progress.stage == RouteProgress.Stage.RETURNING,"Outside the pad footprint must not complete")
	player.global_position = progress.start_pad
	progress._physics_process(0.5)
	check(progress.stage == RouteProgress.Stage.COMPLETED and completed == [2.5],"Return must complete with elapsed time: %s" % str(completed))
	progress._physics_process(0.5)
	check(progress.elapsed == 2.5 and completed.size() == 1,"Completed route must freeze its clock")
	check(progress.checkpoint() == progress.start_pad,"Completed checkpoint must be the start pad")
	progress.reset()
	check(progress.stage == RouteProgress.Stage.OUTBOUND and progress.elapsed == 0.0,"reset() must restore the outbound stage")
	player.free()
	progress.free()
	await process_frame

func pause_menu() -> void:
	var menu: PauseMenu = load("res://ui/pause_menu.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	var restarts: Array[int] = [0]
	menu.restart_requested.connect(func() -> void: restarts[0] += 1)
	check(not menu.visible and not paused,"Menu must start hidden and unpaused")
	menu.open()
	check(menu.visible and paused and menu.resume_button.has_focus(),"open() must pause and focus Continue")
	menu.close()
	check(not menu.visible and not paused,"close() must resume")
	menu.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(paused,"Focus loss must pause")
	menu.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	check(paused,"Focus return must not resume")
	menu.restart_button.pressed.emit()
	check(restarts[0] == 1 and not paused and not menu.visible,"Restart must signal and resume")
	menu.pause_on_focus_loss = false
	menu.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	check(not paused,"Disabled focus pause must not pause")
	menu.free()
	paused = false
