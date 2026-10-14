extends SceneTree
## Phase 3 end to end: the relay shed door, the room's geometry, the terminal's
## boot and log, the letterboxed outage cutscene with the animal at the window,
## control handed back and the player's walk out of the rear door into the
## service yard behind the shed, and the way back in. Real Input for what the player drives; the cutscene runs faster.
const TRAIL := "res://environments/perimeter.tscn"
const ROOM := "res://environments/relay_room.tscn"
const YARD := "res://environments/service_yard.tscn"
## The console and the cutscene run at this multiple of their authored pace.
const SPEED := 6.0
var failures: int = 0
var ticks: int = 0
var scene: Node
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

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = false
	Input.parse_input_event(event)

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

func walk_to(target: Vector3) -> void:
	release()
	await tick(6)
	var reached: bool = false
	for frame: int in range(900):
		var delta: Vector3 = target-player.global_position
		delta.y = 0
		if delta.length() < 0.12:
			reached = true
			break
		steer(delta.normalized())
		await tick()
	release()
	await tick(8)
	check(reached,"Waypoint blocked: %v; stopped at %v" % [target,player.global_position])

func push(direction: Vector3, frames: int = 140) -> Vector3:
	release()
	await tick(4)
	steer(direction)
	await tick(frames)
	release()
	await tick(8)
	return player.global_position

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("res://.local/relay-"+label+".png") == OK,"Could not capture "+label)

## Through a door by E, waiting out its cinematic, into `expected`.
func travel(expected: String, title: String) -> void:
	key(KEY_E)
	await tick(2)
	check(root.has_node("DoorTransition"),"E did not start the door cinematic to "+title)
	if not root.has_node("DoorTransition"):
		return
	check(root.get_node("DoorTransition").region_title.text == title,"Cinematic named %s instead of %s" % [root.get_node("DoorTransition").region_title.text,title])
	await root.get_node("DoorTransition").finished
	await tick(4)
	check(current_scene.scene_file_path == expected,"Wrong level after the door: %s" % current_scene.scene_file_path)
	scene = current_scene
	player = scene.player

func run() -> void:
	create_timer(400).timeout.connect(func() -> void: quit(124))
	root.size = Vector2i(1920,1080)
	SaveGame.path = "res://.local/relay_save.cfg"
	SaveGame.clear()
	SupplyStock.reset()
	ControlScheme.set_mode(ControlScheme.Mode.CAMERA_RELATIVE)
	MissionState.reset()
	MissionState.restore(MissionState.Stage.RELAY)

	# --- From the trail, through the shed's front door ---
	scene = load(TRAIL).instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.player
	scene.keleken.combat_enabled = false
	player.reset_to(Transform3D(Basis.IDENTITY,scene.RELAY_APPROACH + Vector3(0,0,0.6)))
	scene.director.reset_to(scene.shots[2])
	await tick(10)
	await walk_to(scene.RELAY_APPROACH)
	check(scene.relay_door.can_interact(),"No prompt at the relay shed door")
	await travel(ROOM,"RELAY ROOM")
	check(MissionState.stage == MissionState.Stage.RELAY_ROOM,"Entering the room did not advance the objective: %d" % MissionState.stage)
	check(player.global_position.distance_to(scene.FRONT_ARRIVAL) < 0.15,"Arrival is not inside the front door: %v" % player.global_position)
	check(scene.powered and scene.ceiling_light.light_energy > 1.0,"The room is dark before the log was read")
	check(scene.background.visible and scene.background.texture == scene.ART_POWERED,"Arrival did not show the powered room plate")
	key(KEY_B)
	await tick(2)
	check(not scene.background.visible and scene.source.get_node("TerminalScreen").material_override is StandardMaterial3D,"B did not restore the lit geometry")
	key(KEY_B)
	await tick(2)
	check(scene.background.visible,"B did not return to the painted room")
	await capture("arrival")

	# --- Geometry: a different room, and solid ---
	for label: String in ["Floor","WallWest","WallEast","WallNorthWest","RackA","RackB","RackC","BatteryBank","Transformer","Desk","RearDoor","FrontDoor"]:
		check(scene.colliders.get_node_or_null(label) != null,"The room lost the collider of "+label)
	var east: Vector3 = await push(Vector3.RIGHT,90)
	check(east.x < 3.0 - 0.25,"The east wall let the player through: %v" % east)
	var south: Vector3 = await push(Vector3.BACK,90)
	check(south.z < 2.2 - 0.25,"The front door let the player through: %v" % south)
	await walk_to(Vector3(0.9,0,0.6))
	var west: Vector3 = await push(Vector3.LEFT,160)
	# The battery bank stands between the middle of the room and the west wall.
	check(west.x > -1.8 + 0.25,"The battery bank let the player through: %v" % west)
	await walk_to(Vector3(1.0,0,0.3))
	await walk_to(Vector3(1.0,0,-1.1))
	var north: Vector3 = await push(Vector3.FORWARD,90)
	check(north.z > -2.2 + 0.25,"The north wall let the player through: %v" % north)
	# Barred from this side until the outage.
	await walk_to(scene.REAR_APPROACH)
	check(not scene.rear_door.can_interact(),"The rear door opened before the outage")

	# --- The terminal: boot, login, the log ---
	await walk_to(scene.TERMINAL_APPROACH)
	check(scene.terminal.can_interact(),"No prompt at the relay terminal")
	scene.cutscene_speed = SPEED
	key(KEY_E)
	await tick(3)
	check(scene.beat == &"console" and scene.console.visible and not player.control_enabled,"E did not hand the room to the console")
	var read: Array[bool] = [false]
	scene.console.log_read.connect(func() -> void: read[0] = true)
	for frame: int in range(1800):
		if read[0]:
			break
		await tick()
	check(read[0],"The console never reached the end of the log")
	await capture("console-log")
	var written: String = scene.console.text.text
	for fragment: String in ["[  OK  ]","[FAILED] Failed to start Uplink","relay-r2 login: operator","journalctl -u relay-log","AURORA","do not open the rear door after dark"]:
		check(written.contains(fragment),"The console did not show: "+fragment)
	check(MissionState.stage == MissionState.Stage.RELAY_ROOM,"The objective moved before the power went")

	# --- The outage and the window ---
	for frame: int in range(900):
		if scene.beat == &"window":
			break
		await tick()
	check(scene.beat == &"window","The cutscene never reached the window")
	check(MissionState.stage == MissionState.Stage.OUTAGE,"The outage did not advance the objective")
	check(not scene.powered and scene.ceiling_light.light_energy == 0.0 and scene.screen_light.light_energy == 0.0,"The lights stayed on through the outage")
	check(scene.emergency_light.light_energy > 0.0,"The emergency lamp did not take over")
	check(scene.cutscene_camera.current,"The cutscene did not cut to the window")
	check(scene.background.visible and scene.background.texture == scene.ART_WINDOW,"The window cut did not select its own painted camera")
	check(scene.source.get_node("WindowGlass").material_override is StandardMaterial3D,"The painted window blocks the live animal with opaque glass")
	check(not scene._geometry_materials[&"TerminalScreen"].emission_enabled,"The stored geometry relit the dead screen")
	check(scene.bars.visible and scene.bars.amount > 0.0 and scene.bars.top.size.y > 0.0,"The cutscene has no letterbox")
	check(not player.control_enabled,"The player kept control inside the cutscene")
	check(not scene.operation.hud.visible,"The HUD stayed over the letterbox")
	check(not scene.terminal.can_interact(),"A dead terminal still offers access")
	var seen: bool = false
	for frame: int in range(900):
		if scene.beat != &"window":
			break
		if is_instance_valid(scene.animal):
			# The head must pass inside the window opening as the camera sees it.
			var head: Vector3 = scene.animal.visual.skeleton.global_transform * scene.animal.visual.skeleton.get_bone_global_pose(scene.animal.visual.skeleton.find_bone("head")).origin
			var cam: Camera3D = scene.cutscene_camera
			var pixel: Vector2 = cam.unproject_position(head)
			var sill: Vector2 = cam.unproject_position(Vector3(0.65,1.45,-2.3))
			var lintel: Vector2 = cam.unproject_position(Vector3(0.65,2.05,-2.3))
			var left: Vector2 = cam.unproject_position(Vector3(0.2,1.75,-2.3))
			var right: Vector2 = cam.unproject_position(Vector3(1.1,1.75,-2.3))
			if not cam.is_position_behind(head) and pixel.y < sill.y and pixel.y > lintel.y and pixel.x > left.x and pixel.x < right.x:
				if not seen:
					await capture("window")
				seen = true
		await tick()
	check(seen,"The animal never showed in the window")

	# --- The bars lift and the player takes Dylan to the rear door ---
	for frame: int in range(900):
		if scene.beat == &"done":
			break
		await tick()
	check(scene.beat == &"done","The cutscene never handed the room back")
	check(player.control_enabled,"Control did not come back after the window")
	check(scene.bars.amount == 0.0 and not scene.bars.visible,"The letterbox stayed after the cutscene")
	check(scene.camera.current,"The room camera did not come back")
	check(scene.background.visible and scene.background.texture == scene.ART_OUTAGE,"The room returned to a lit plate after the outage")
	await tick(30)
	check(scene.operation.hud.visible,"The HUD did not come back after the cutscene")
	check(not root.has_node("DoorTransition"),"Dylan left on his own; the walk to the door is the player's")
	await walk_to(Vector3(1.95,0,-1.3))
	await walk_to(scene.REAR_APPROACH)
	check(scene.rear_door.can_interact(),"No prompt at the rear door after the outage")
	key(KEY_E)
	for frame: int in range(300):
		if root.has_node("DoorTransition"):
			break
		await tick()
	check(root.has_node("DoorTransition"),"E at the rear door did not take Dylan out")
	if root.has_node("DoorTransition"):
		check(root.get_node("DoorTransition").region_title.text == "SERVICE YARD","The exit cinematic named the wrong place")
		await root.get_node("DoorTransition").finished
		await tick(4)
	check(current_scene.scene_file_path == YARD,"The rear door did not lead to the service yard: %s" % current_scene.scene_file_path)
	scene = current_scene
	player = scene.player
	check(MissionState.stage == MissionState.Stage.REAR_YARD,"Leaving did not reach the service yard objective")
	check(player.global_position.distance_to(scene.REAR_ARRIVAL) < 0.15,"Arrival is not behind the shed: %v" % player.global_position)
	check(scene.director.current_shot == scene.shots[0],"The yard did not open on the view of the rear door")
	check(player.control_enabled,"Control did not come back outside")
	await capture("service-yard")

	# --- The shed wall holds behind him; the yard's own probe walks the rest ---
	await walk_to(Vector3(5.2,0,-33.4))
	var round_east: Vector3 = await push(Vector3.BACK,200)
	check(round_east.z < -32.0,"A gap east of the shed leads back to the trail: %v" % round_east)

	# --- And back in through the rear door, into the dark room ---
	await walk_to(scene.DOOR_APPROACHES[&"relay_rear"])
	check(scene.rear_door.can_interact(),"No prompt at the shed's rear door")
	await travel(ROOM,"RELAY ROOM")
	check(player.global_position.distance_to(scene.REAR_ARRIVAL) < 0.15,"Coming back in did not land at the rear door: %v" % player.global_position)
	check(not scene.powered and scene.emergency_light.light_energy > 0.0,"The power came back on its own")
	check(not scene.terminal.can_interact(),"The dead terminal came back")
	await capture("dark-room")

	# --- Restart puts the room back as entered ---
	scene.restart()
	await tick(4)
	check(scene.powered and MissionState.stage == MissionState.Stage.RELAY_ROOM,"Restart did not restore the room before the log")
	check(scene.background.visible and scene.background.texture == scene.ART_POWERED,"Restart left the outage plate showing")
	SaveGame.clear()
	MissionState.reset()
	release()
	print("RELAY_ROOM ticks=%d failures=%d" % [ticks,failures])
	quit(1 if failures else 0)
