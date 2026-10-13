extends SceneTree
## Phase 2 end to end: the declared chain, the gate that releases it, the trail
## geometry and its three framings, the animal that now lives there, and the way
## back. Real Input, real colliders, real cinematic; nothing is simulated here
## that the player would not drive.
const EXTERIOR := "res://environments/exterior.tscn"
const TRAIL := "res://environments/perimeter.tscn"
## Up the yard, past the guardhouse, to the service gate in the north fence.
const TO_GATE: Array[Vector3] = [Vector3(0,0,16),Vector3(0,0,10.5),Vector3(0,0,6),Vector3(0.6,0,1),Vector3(0.6,0,-3),Vector3(0,0,-5.9)]
## Up the trail: east of the fallen pine, to the relay shed door.
const UP_TRAIL: Array[Vector3] = [Vector3(0,0,-6),Vector3(1.2,0,-11),Vector3(1.2,0,-17),Vector3(1.6,0,-21.4),Vector3(1.6,0,-23.6),Vector3(0,0,-25.8)]
var failures: int = 0
var ticks: int = 0
var cuts: Array[StringName] = []
var scene: Node
var player: PlayerController
var inspect_frame: bool = false

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

func steer(direction: Vector3, running: bool = false) -> void:
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
	if running:
		Input.action_press("run")
	else:
		Input.action_release("run")

func tick(count: int = 1) -> void:
	for frame: int in range(count):
		await physics_frame
		await process_frame
		ticks += 1
		if not inspect_frame:
			continue
		# A new area's framings have to hold the actor they were authored for.
		var shot: ShotRig = scene.director.current_shot
		check(scene.presentation.current_shot == shot and player.camera == shot.camera,"Camera presentation out of sync")
		if scene.presentation.art_mode:
			# A framing without a plate shows geometry, never the previous plate.
			var painted: bool = shot.definition.background != null
			check(scene.background.visible == painted and (not painted or scene.background.texture == shot.definition.background),"Art plate out of sync at camera cut")
		for height: float in [0.0,1.8]:
			var point: Vector3 = player.global_position+Vector3(0,height,0)
			var pixel: Vector2 = shot.camera.unproject_position(point)
			if shot.camera.is_position_behind(point) or not Rect2(8,8,1904,1064).has_point(pixel):
				check(false,"Actor outside frame at %v height %s pixel %s shot %s" % [player.position,height,pixel,shot.name])
				inspect_frame = false
				return

func walk_to(target: Vector3, running: bool = false) -> void:
	release()
	await tick(10)
	var reached: bool = false
	for frame: int in range(900):
		var delta: Vector3 = target-player.position
		delta.y = 0
		if delta.length() < 0.15:
			reached = true
			break
		steer(delta.normalized(),running and delta.length() > 1.5)
		await tick()
		if failures > 4:
			break
	release()
	await tick(10)
	check(reached,"Waypoint blocked: %v; stopped at %v" % [target,player.position])

## Hold a direction against a boundary and report where it stops.
func push(direction: Vector3, frames: int = 110) -> Vector3:
	release()
	await tick(6)
	steer(direction)
	await tick(frames)
	release()
	await tick(10)
	return player.position

func enter(expected: String) -> void:
	key(KEY_E)
	await tick(2)
	check(root.has_node("DoorTransition"),"E did not start the gate cinematic")
	if not root.has_node("DoorTransition"):
		return
	var expected_title: String = "PERIMETER TRAIL" if expected == TRAIL else "GUARDHOUSE YARD"
	check(root.get_node("DoorTransition").region_title.text == expected_title,"Gate cinematic displayed the wrong destination")
	await root.get_node("DoorTransition").finished
	await tick(4)
	check(current_scene.scene_file_path == expected,"Wrong level after the gate: %s" % current_scene.scene_file_path)
	scene = current_scene
	player = scene.player

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("res://.local/perimeter-art-"+label+".png") == OK,"Could not capture "+label)

func run() -> void:
	create_timer(300).timeout.connect(func() -> void: quit(124))
	root.size = Vector2i(1920,1080)
	SaveGame.path = "res://.local/perimeter_save.cfg"
	SaveGame.clear()
	SupplyStock.reset()
	MissionState.reset()
	ControlScheme.set_mode(ControlScheme.Mode.CAMERA_RELATIVE)

	# --- The declared chain ---
	var chain: Array[Phase] = Phase.chain()
	check(chain.size() == 3,"The phase chain no longer declares three phases")
	check(Phase.after(&"perimeter") == Phase.find(&"relay") and Phase.find(&"relay").opens_at == MissionState.Stage.RELAY,"The relay phase does not follow the trail")
	var guardhouse: Phase = Phase.find(&"guardhouse")
	var perimeter: Phase = Phase.find(&"perimeter")
	check(guardhouse != null and perimeter != null,"The chain lost one of its phases")
	check(ResourceLoader.exists(guardhouse.entry_scene) and ResourceLoader.exists(perimeter.entry_scene),"A phase points at a scene that does not exist")
	check(perimeter.entry_scene == TRAIL and guardhouse.entry_scene == EXTERIOR,"A phase points at the wrong entry scene")
	check(guardhouse.last_stage == perimeter.opens_at,"Phase 2 does not open on the stage that closes Phase 1")
	check(Phase.after(&"guardhouse") == perimeter and Phase.after(&"relay") == null,"The chain order is broken")
	check(Phase.of_stage(MissionState.Stage.ROAD) == guardhouse and Phase.of_stage(MissionState.Stage.DONE) == guardhouse,"Phase 1 stages map elsewhere")
	check(Phase.of_stage(MissionState.Stage.PERIMETER) == perimeter and Phase.of_stage(MissionState.Stage.RELAY) == perimeter,"Phase 2 stages map elsewhere")
	check(Phase.current() == guardhouse,"A fresh run does not start in Phase 1")
	check(not perimeter.unlocked() and not perimeter.entered(),"Phase 2 is open before Phase 1 is closed")
	# A stored record still resumes the stage it stored, with the longer enum.
	MissionState.restore(MissionState.Stage.RELAY)
	check(MissionState.stage == MissionState.Stage.RELAY,"The stored stage of Phase 2 does not restore")
	MissionState.restore(99)
	check(MissionState.stage == MissionState.Stage.ROAD,"An impossible stored stage was accepted")

	# --- The gate out of the yard ---
	scene = load(EXTERIOR).instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.player
	await tick(25)
	var gate: PhaseGate = scene.north_gate
	check(gate != null and gate.phase_id == &"perimeter","The exterior has no gate to Phase 2")
	check(gate.target_scene == TRAIL,"The gate does not lead to the perimeter trail")
	for point: Vector3 in TO_GATE:
		await walk_to(point,true)
		if point == Vector3(0.6,0,1):
			await capture("yard-approach")
	check(player.position.distance_to(scene.NORTH_GATE_APPROACH) < 0.3,"The gate approach is not walkable from the yard")
	check(scene.shots[3].definition.background != null and scene.background.visible,"North yard plate is missing")
	await capture("north-yard")
	check(gate.can_interact(),"No prompt at the gate approach")
	check(not gate.unlocked() and gate.prompt_text().contains("bolted"),"The gate does not read as bolted before the terminal")
	key(KEY_E)
	await tick(3)
	check(not root.has_node("DoorTransition"),"A bolted gate still travelled")
	check(MessageBox.is_open(self) and paused,"The bolted gate gave no reason")
	var reason: String = " ".join(PackedStringArray((get_nodes_in_group(&"message_boxes")[0] as MessageBox).pages)) if MessageBox.is_open(self) else ""
	check(reason.contains("bolted") and reason.contains("TERMINAL"),"The bolted gate does not say to save first: %s" % reason)
	for page: int in range(8):
		if not MessageBox.is_open(self):
			break
		key(KEY_E)
		await tick(3)
	check(not MessageBox.is_open(self) and not paused,"The gate message did not let the game go")
	# The terminal closes Phase 1; only then does the gate open.
	MissionState.reach(MissionState.Stage.YARD)
	MissionState.reach(MissionState.Stage.TERMINAL)
	MissionState.reach(MissionState.Stage.DONE)
	await tick(3)
	check(gate.unlocked() and gate.prompt_text().contains("North gate"),"The closed phase did not open the gate")
	await enter(TRAIL)

	# --- Arrival on the trail ---
	check(MissionState.stage == MissionState.Stage.PERIMETER,"Entering the trail did not advance the objective")
	check(Phase.current() == perimeter and perimeter.entered(),"The chain does not report Phase 2 as current")
	check(player.position.distance_to(scene.GATE_ARRIVAL) < 0.2,"Arrival is not at the gate: %v" % player.position)
	check(absf(angle_difference(player.visual.rotation.y,0.0)) < 0.2,"Arrival does not face up the trail")
	check(scene.director.current_shot == scene.shots[0],"Arrival selected the wrong framing")
	check(scene.shots.size() == 4 and scene.colliders.get_child_count() >= 18,"Spatial source or framings incomplete")
	for label: String in ["Terrain","TrailBank","RockShoulder","GateLeaf","FallenPine","RelayShed"]:
		check(scene.colliders.get_node_or_null(label) != null,"The trail lost the collider of "+label)
	check(scene.art_available and scene.presentation.art_mode,"Perimeter did not start with its authored plates")
	# All four current framings now have their own geometry-derived plate.
	for index: int in range(4):
		check(scene.shots[index].definition.background != null,"Missing authored plate: "+String(scene.shots[index].definition.shot_id))
	check(scene.shots[1].definition.background.resource_path.ends_with("art_cam02_v03.png"),"The pen reused its old camera's plate")
	# Up the trail is up the screen in the pen view and at the shed alike, so
	# the stick keeps its meaning across that cut.
	var pen_forward: Vector3 = -scene.shots[1].camera.global_basis.z
	var shed_forward: Vector3 = -scene.shots[2].camera.global_basis.z
	pen_forward.y = 0.0
	shed_forward.y = 0.0
	check(pen_forward.normalized().dot(Vector3.FORWARD) > 0.75,"The pen view does not look up the trail: %v" % pen_forward)
	check(pen_forward.normalized().dot(shed_forward.normalized()) > 0.9,"The pen and shed views disagree on screen-up: %v vs %v" % [pen_forward,shed_forward])
	scene.set_art_mode(false)
	check(not scene.background.visible,"Geometry comparison left the painted background visible")
	scene.set_art_mode(true)
	check(scene.background.visible,"Art comparison did not restore the background")
	await capture("entrance")
	var animal: KelekenActor = scene.keleken
	check(animal != null and animal.combat_enabled,"The animal is not on the trail, or cannot fight there")
	check(scene.KELEKEN_BOUNDS.has_point(Vector2(animal.position.x,animal.position.z)),"The animal started outside its pen: %v" % animal.position)
	check(scene.keleken_wander.home_position == scene.KELEKEN_HOME,"The patrol did not take the trail home")
	check(scene.kelekens.size() == 2,"The pen does not hold two animals: %d" % scene.kelekens.size())
	check(scene.kelekens[0].position.distance_to(scene.kelekens[1].position) > 2.0,"The two animals start on top of each other")
	for other: KelekenActor in scene.kelekens:
		check(scene.KELEKEN_BOUNDS.has_point(Vector2(other.position.x,other.position.z)),"An animal started outside its pen: %v" % other.position)
		# The walks below are unattended; combat has its own probe.
		other.combat_enabled = false
		other.collision_layer = 0

	# --- The corridor holds, and its framings hold the actor ---
	var east: Vector3 = await push(Vector3.RIGHT)
	check(east.x < 2.5,"The east bank let the player through: %v" % east)
	var west: Vector3 = await push(Vector3.LEFT)
	check(west.x > -2.5,"The west bank let the player through: %v" % west)
	await walk_to(scene.GATE_ARRIVAL)
	var south: Vector3 = await push(Vector3.BACK)
	check(south.z < 0.0,"The south gate let the player out of the level: %v" % south)
	scene.director.shot_changed.connect(func(_old: StringName,new: StringName) -> void: cuts.append(new))
	inspect_frame = true
	for point: Vector3 in UP_TRAIL:
		await walk_to(point)
		await capture(String(scene.director.current_shot.definition.shot_id)+"-"+str(int(-point.z)))
	inspect_frame = false
	check(cuts == [&"perimeter_2",&"perimeter_3"],"Missing or unstable cuts up the trail: %s" % str(cuts))
	check(MissionState.stage == MissionState.Stage.RELAY,"Reaching the shed did not close the phase")
	check(perimeter.closed(),"The chain does not report Phase 2 as closed")
	var north: Vector3 = await push(Vector3.FORWARD)
	check(north.z > -26.6,"The relay shed let the player through: %v" % north)
	# The shed door opens now that the phase is closed, from the foot of its step.
	check(scene.relay_door.unlocked() and scene.relay_door.target_scene == "res://environments/relay_room.tscn","The relay door does not lead into the shed")
	await walk_to(scene.RELAY_APPROACH)
	check(scene.relay_door.can_interact() and scene.relay_door.prompt_text().contains("Relay shed door"),"No prompt at the relay shed door")

	# --- Restart is a fresh attempt of this phase only ---
	var record: Dictionary = SaveGame.write("res://environments/save_room.tscn",Vector3(0,0,0),0.0,MissionState.Stage.DONE,100.0)
	check(not record.is_empty(),"The record could not be written")
	scene.restart()
	await tick(6)
	check(MissionState.stage == MissionState.Stage.PERIMETER,"Restart left the objective at %d instead of the start of Phase 2" % MissionState.stage)
	check(player.position.distance_to(scene.GATE_ARRIVAL) < 0.3,"Restart did not return the actor to the trail entrance")
	check(Vector2(animal.position.x-scene.KELEKEN_HOME.x,animal.position.z-scene.KELEKEN_HOME.z).length() < 0.05,"Restart did not return the animal to its pen: %v" % animal.position)
	check(int(SaveGame.read().get("stage",-1)) == MissionState.Stage.DONE,"Restart touched the stored record")

	# --- And back out through the same gate ---
	await walk_to(scene.gate.approach)
	check(scene.gate.can_interact(),"No prompt at the gate on the way back")
	await enter(EXTERIOR)
	check(player.position.distance_to(scene.NORTH_GATE_ARRIVAL) < 0.2,"Coming back did not land at the north gate: %v" % player.position)
	check(scene.director.current_shot == scene.shots[3],"Coming back selected the wrong framing")
	check(MissionState.stage == MissionState.Stage.PERIMETER,"Walking back undid the objective")
	SaveGame.clear()
	MissionState.reset()
	release()
	print("PERIMETER ticks=%d cuts=%s failures=%d" % [ticks,str(cuts),failures])
	quit(1 if failures else 0)
