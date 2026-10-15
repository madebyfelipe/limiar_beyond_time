extends SceneTree
## Editable maps, through the runner that plays them. On the template: the map
## loads with its two framings, Dylan appears on PlayerStart, CSG blocks stop
## him, and walking north across the zone line cuts to the second camera and
## walking back cuts to the first. Then every other map in maps/ (converted
## levels included) must load, stand Dylan on ground and pick a framing.
const RUNNER := "res://environments/maps/map_runner.tscn"
const TEMPLATE := "res://maps/exemplo.tscn"
var failures: int = 0
var ticks: int = 0
var scene: MapRunner
var player: PlayerController

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		print("FAIL: ", message)

func release() -> void:
	for action: String in ["move_left","move_right","move_up","move_down","run"]:
		Input.action_release(action)

func steer(direction: Vector3) -> void:
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

func tick(count: int = 1) -> void:
	for frame: int in range(count):
		await physics_frame
		await process_frame
		ticks += 1

func walk_to(target: Vector3) -> bool:
	release()
	await tick(10)
	for frame: int in range(900):
		var delta: Vector3 = target-player.position
		delta.y = 0
		if delta.length() < 0.15:
			release()
			await tick(10)
			return true
		steer(delta.normalized())
		await tick()
	release()
	await tick(10)
	return false

func open(path: String) -> void:
	if scene:
		scene.queue_free()
		await tick(2)
	MapRunner.pending_map = ""
	scene = load(RUNNER).instantiate()
	scene.map_path = path
	root.add_child(scene)
	current_scene = scene
	player = scene.player
	await tick(20)

func shot_id() -> StringName:
	return scene.director.current_shot.definition.shot_id

func run() -> void:
	create_timer(240).timeout.connect(func() -> void: quit(124))
	root.size = Vector2i(1920,1080)
	SaveGame.path = "res://.local/maps_save.cfg"
	SaveGame.clear()
	SupplyStock.reset()
	MissionState.reset()
	ControlScheme.set_mode(ControlScheme.Mode.CAMERA_RELATIVE)

	# --- The template ---
	await open(TEMPLATE)
	check(scene.shots.size() == 2 and scene.director.zones.size() == 2,"Template framings or zones missing: %d / %d" % [scene.shots.size(),scene.director.zones.size()])
	check(player.position.distance_to(Vector3(0,0.06,2)) < 0.3,"Dylan not on PlayerStart: %v" % player.position)
	check(shot_id() == &"Shot1","Template does not open on Shot1: %s" % shot_id())
	check(not scene.art_available and not scene.background.visible,"A plate shows on a map that has none")
	check(await walk_to(Vector3(-2,0,-11)),"Could not walk north past the wall: %v" % player.position)
	check(shot_id() == &"Shot2","No cut to Shot2 north of the line: %s" % shot_id())
	check(await walk_to(Vector3(1,0,0)),"Could not walk back to the start: %v" % player.position)
	check(shot_id() == &"Shot1","No cut back to Shot1: %s" % shot_id())
	# The wall stands across x 0..5 at z = -8: pushing north from in front of it stops short.
	check(await walk_to(Vector3(2.5,0,-6)),"Could not reach the wall: %v" % player.position)
	release()
	steer(Vector3(0,0,-1))
	await tick(90)
	release()
	await tick(5)
	check(player.position.z > -7.9,"Dylan walked through the CSG wall: %v" % player.position)
	check(player.position.y > -0.5,"Dylan fell through the template floor: %v" % player.position)
	scene.restart()
	await tick(5)
	check(player.position.distance_to(Vector3(0,0.06,2)) < 0.3 and shot_id() == &"Shot1","Restart did not return to the start")

	# --- Every other map loads and stands ---
	var others: int = 0
	for file: String in DirAccess.get_files_at("res://maps"):
		if not file.ends_with(".tscn") or "res://maps/"+file == TEMPLATE:
			continue
		others += 1
		await open("res://maps/"+file)
		check(not scene.shots.is_empty() and not scene.director.zones.is_empty(),"%s: no framings or zones" % file)
		var start: Vector3 = player.position
		await tick(60)
		check(player.position.y > start.y - 0.5,"%s: Dylan fell from the start %v to %v" % [file,start,player.position])
		check(scene.director.current_shot != null and player.camera == scene.director.current_shot.camera,"%s: no active framing" % file)
	release()
	print("MAPS ticks=%d other_maps=%d failures=%d" % [ticks,others,failures])
	quit(1 if failures > 0 else 0)
