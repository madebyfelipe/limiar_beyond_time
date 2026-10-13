extends Control
## Phase 3 — inside the relay shed. The geometry owns collision and, with no
## plate painted yet, also the look; the room is lit by its own lamps so the
## power cut can be seen. The terminal plays the operator's log, the power
## dies and something passes the window; then the player takes Dylan out by
## the rear door.
const SOURCE := preload("res://environments/relay_room_source.tscn")
const SCENE_PATH := "res://environments/relay_room.tscn"
const KELEKEN := preload("res://actors/keleken/keleken.tscn")
const PERIMETER := "res://environments/perimeter.tscn"
## One fixed framing from the south-west corner, under the ceiling, taking in
## the racks, the window, the terminal and the rear door.
const CAMERA_POSITION := Vector3(-2.85, 2.6, 2.05)
const CAMERA_TARGET := Vector3(0.9, 0.55, -0.9)
const CAMERA_FOV := 62.0
## Doorways and the terminal, measured against the source boxes: the capsule
## (0,3 m) stands clear of the desk, the column and the door leaves.
const FRONT_APPROACH := Vector3(1.8, 0.0, 1.75)
const FRONT_ARRIVAL := Vector3(1.8, 0.0, 1.35)
const REAR_APPROACH := Vector3(2.3, 0.0, -1.75)
const REAR_ARRIVAL := Vector3(2.3, 0.0, -1.35)
const TERMINAL_APPROACH := Vector3(1.95, 0.0, -0.35)
## Cutscene: the over-the-shoulder view on the window and the line the animal
## takes behind the north wall.
const WINDOW_SHOT_POSITION := Vector3(2.15, 1.6, 0.55)
const WINDOW_SHOT_TARGET := Vector3(0.65, 1.65, -2.3)
const WINDOW_CENTRE := Vector3(0.65, 1.75, -2.3)
const ANIMAL_FROM := Vector3(-3.6, 0.0, -3.5)
const ANIMAL_TO := Vector3(4.2, 0.0, -3.5)
const ANIMAL_PAUSE_AT := Vector3(0.45, 0.0, -3.5)

@onready var world: Node3D = $Frame/Composition/Actors/WorldViewport/World
@onready var background: TextureRect = $Frame/Composition/Background
@onready var camera: Camera3D = $Frame/Composition/Actors/WorldViewport/World/Camera
@onready var player: PlayerController = $Frame/Composition/Actors/WorldViewport/World/Player
var source: Node3D
var colliders: Node3D
var front_door: DoorInteraction
var rear_door: DoorInteraction
var terminal: RelayTerminal
var console: RelayConsole
var operation: LevelOperation
var ceiling_light: OmniLight3D
var screen_light: OmniLight3D
var emergency_light: OmniLight3D
var yard_light: OmniLight3D
var cutscene_camera: Camera3D
var animal: KelekenActor
var bars: CinematicBars
var powered: bool = true
## Cutscene beat, for probes and for anything that must not interrupt it:
## "", "console", "outage", "window", "done".
var beat: StringName = &""
## Probes speed the console and the cutscene; 1 is the authored pace.
var cutscene_speed: float = 1.0
var _emergency_pulse: Tween
var _lit_materials: Dictionary = {}

func _ready() -> void:
	$Frame/Composition/Actors/WorldViewport/World/Capsule.hide()
	# The room is lit by its own lamps; the composition's sun would ignore the cut.
	world.get_node("Light").hide()
	background.hide()
	var environment_node: WorldEnvironment = world.get_node("Environment")
	environment_node.environment = environment_node.environment.duplicate()
	environment_node.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment_node.environment.ambient_light_color = Color("8fa3b8")
	environment_node.environment.ambient_light_energy = 0.28
	source = SOURCE.instantiate()
	world.add_child(source)
	colliders = Node3D.new()
	colliders.name = "SharedColliders"
	world.add_child(colliders)
	for mesh: MeshInstance3D in source.get_children():
		if not mesh.has_meta("collision_size"):
			continue
		var body := StaticBody3D.new()
		body.name = mesh.name
		body.transform = mesh.transform
		var shape := BoxShape3D.new()
		shape.size = mesh.get_meta("collision_size")
		var collision := CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
		colliders.add_child(body)
	camera.position = CAMERA_POSITION
	camera.look_at(CAMERA_TARGET)
	camera.fov = CAMERA_FOV
	player.camera = camera
	_build_lights()
	cutscene_camera = Camera3D.new()
	cutscene_camera.name = "CutsceneCamera"
	world.add_child(cutscene_camera)
	cutscene_camera.position = WINDOW_SHOT_POSITION
	cutscene_camera.look_at(WINDOW_SHOT_TARGET)
	cutscene_camera.fov = 48.0
	bars = CinematicBars.new()
	$Frame/Composition.add_child(bars)
	front_door = _door(&"relay_front", FRONT_APPROACH, PI, "Perimeter Trail")
	rear_door = _door(&"relay_rear", REAR_APPROACH, 0.0, "Behind the Relay Shed")
	terminal = RelayTerminal.new()
	terminal.name = "RelayTerminal"
	terminal.player = player
	terminal.approach = TERMINAL_APPROACH
	terminal.radius = 0.6
	terminal.used.connect(read_log)
	add_child(terminal)
	console = RelayConsole.new()
	console.name = "RelayConsole"
	add_child(console)
	operation = LevelOperation.new()
	operation.name = "Operation"
	operation.player = player
	operation.frame = $Frame/Composition
	operation.restart_requested.connect(restart)
	add_child(operation)
	# Being inside is the objective the shed door pointed at, however the room
	# was reached; a direct launch starts here too.
	if MissionState.stage < MissionState.Stage.RELAY_ROOM:
		MissionState.restore(MissionState.Stage.RELAY_ROOM)
	_apply_power(MissionState.stage < MissionState.Stage.OUTAGE)
	operation.mark_safe()

func _door(id: StringName, approach: Vector3, facing: float, destination: String) -> DoorInteraction:
	var door := DoorInteraction.new()
	door.name = "Door_" + String(id)
	door.player = player
	door.approach = approach
	door.radius = 0.6
	door.facing = facing
	door.target_scene = PERIMETER
	door.destination_name = destination
	door.entry_id = id
	door.returning_outside = true
	add_child(door)
	return door

func _build_lights() -> void:
	ceiling_light = OmniLight3D.new()
	ceiling_light.name = "CeilingLight"
	# Under its fitting (see the source builder), low enough that the ceiling
	# right above it does not burn into a hot spot behind the objective line.
	ceiling_light.position = Vector3(-0.6, 2.2, 1.0)
	ceiling_light.light_color = Color("f1ead6")
	ceiling_light.light_energy = 1.7
	ceiling_light.omni_range = 7.5
	ceiling_light.shadow_enabled = true
	world.add_child(ceiling_light)
	screen_light = OmniLight3D.new()
	screen_light.name = "ScreenGlow"
	screen_light.position = Vector3(2.35, 1.0, -0.35)
	screen_light.light_color = Color("74f08a")
	screen_light.light_energy = 0.45
	screen_light.omni_range = 1.8
	world.add_child(screen_light)
	emergency_light = OmniLight3D.new()
	emergency_light.name = "EmergencyLight"
	emergency_light.position = Vector3(2.3, 2.3, -1.9)
	emergency_light.light_color = Color("ff2a1c")
	emergency_light.light_energy = 0.0
	emergency_light.omni_range = 6.5
	world.add_child(emergency_light)
	# Behind the shed, seen through the window: a cold lamp the animal crosses.
	yard_light = OmniLight3D.new()
	yard_light.name = "YardLamp"
	yard_light.position = Vector3(0.65, 2.6, -4.1)
	yard_light.light_color = Color("a9c4e8")
	yard_light.light_energy = 1.4
	yard_light.omni_range = 3.6
	yard_light.shadow_enabled = true
	world.add_child(yard_light)

## Lamps, screen and rack lights on or off. The red lamp takes over in the dark.
func _apply_power(on: bool) -> void:
	powered = on
	terminal.powered = on
	ceiling_light.light_energy = 1.7 if on else 0.0
	screen_light.light_energy = 0.45 if on else 0.0
	for mesh: MeshInstance3D in source.get_children():
		var material := mesh.material_override as StandardMaterial3D
		if material == null or not material.emission_enabled or mesh.name == "EmergencyLamp":
			continue
		if not _lit_materials.has(mesh.name):
			_lit_materials[mesh.name] = material
		if on:
			mesh.material_override = _lit_materials[mesh.name]
		else:
			var dark: StandardMaterial3D = material.duplicate()
			dark.emission_enabled = false
			dark.albedo_color = material.albedo_color.darkened(0.75)
			mesh.material_override = dark
	if _emergency_pulse != null:
		_emergency_pulse.kill()
		_emergency_pulse = null
	if on:
		emergency_light.light_energy = 0.0
	else:
		emergency_light.light_energy = 1.2
		_emergency_pulse = create_tween().set_loops()
		_emergency_pulse.tween_property(emergency_light, "light_energy", 0.35, 0.9).set_trans(Tween.TRANS_SINE)
		_emergency_pulse.tween_property(emergency_light, "light_energy", 1.4, 0.9).set_trans(Tween.TRANS_SINE)

## Through a doorway: the front one from the trail, the rear one coming back.
func arrive_from_door() -> void:
	if DoorInteraction.arrived_from == &"relay_rear_in":
		player.reset_to(Transform3D(Basis.IDENTITY, REAR_ARRIVAL))
		player.visual.rotation.y = PI
	else:
		player.reset_to(Transform3D(Basis.IDENTITY, FRONT_ARRIVAL))
		player.visual.rotation.y = 0.0
	operation.mark_safe()
	operation.show_notice("Objective: %s" % MissionState.objective(), 3.0)

## Esc → Restart, and R. The room as it was entered: power back, log unread.
func restart() -> void:
	if beat != &"" and beat != &"done":
		return
	beat = &""
	player.reset_to_start()
	player.reset_to(Transform3D(Basis.IDENTITY, FRONT_ARRIVAL))
	Phase.find(&"relay").rewind()
	terminal.busy = false
	_apply_power(true)
	bars.amount = 0.0
	if is_instance_valid(animal):
		animal.queue_free()
	operation.mark_safe()
	operation.hide_notice()

func _unhandled_key_input(event: InputEvent) -> void:
	if InputBindings.is_custom_event(event):
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_T:
			ControlScheme.toggle()
		elif event.physical_keycode == KEY_R and beat in [&"", &"done"]:
			if player.weapon == null or (not player.weapon.aiming and not player.weapon.is_reloading()):
				restart()

func _process(_delta: float) -> void:
	# The rear door is barred from this side until the outage sends Dylan out.
	rear_door.busy = MissionState.stage < MissionState.Stage.OUTAGE or (beat != &"" and beat != &"done")

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds / cutscene_speed, false).timeout

## The terminal: Dylan at the keyboard while the console plays, then the cut.
func read_log() -> void:
	beat = &"console"
	player.set_control_enabled(false)
	player.velocity = Vector3.ZERO
	var face := create_tween()
	face.tween_property(player.visual, "rotation:y", player.visual.rotation.y + angle_difference(player.visual.rotation.y, -PI / 2), 0.2)
	_dylan().play_scripted(&"terminal_type", &"idle")
	console.speed = cutscene_speed
	console.open()
	await console.finished
	await play_outage()

func _dylan() -> Node:
	return player.visual.get_node("DylanVisual")

## Lights fail, the red lamp takes over and the animal crosses the window,
## framed by the letterbox. Dylan starts back when it looks in; then the bars
## lift and the player walks him to the rear door.
func play_outage() -> void:
	beat = &"outage"
	MissionState.reach(MissionState.Stage.OUTAGE)
	bars.set_shown(true, 0.5 / cutscene_speed)
	for flicker: float in [0.0, 1.7, 0.0, 0.9, 0.0]:
		ceiling_light.light_energy = flicker
		await _wait(0.09)
	_apply_power(false)
	await _wait(0.7)
	# Over Dylan's shoulder, onto the window.
	beat = &"window"
	cutscene_camera.current = true
	var turn := create_tween()
	var to_window: Vector3 = WINDOW_CENTRE - player.global_position
	var heading: float = atan2(-to_window.x, -to_window.z)
	turn.tween_property(player.visual, "rotation:y", player.visual.rotation.y + angle_difference(player.visual.rotation.y, heading), 0.45 / cutscene_speed)
	_dylan().play_scripted(&"idle")
	animal = KELEKEN.instantiate()
	animal.name = "WindowKeleken"
	animal.combat_enabled = false
	world.add_child(animal)
	animal.set_physics_process(false)
	animal.collision_layer = 0
	animal.collision_mask = 0
	animal.position = ANIMAL_FROM
	animal.rotation.y = -PI / 2
	animal.visual.play_clip(&"walk", 1.0)
	var cross := create_tween()
	cross.tween_property(animal, "position", ANIMAL_PAUSE_AT, ANIMAL_FROM.distance_to(ANIMAL_PAUSE_AT) / 1.0 / cutscene_speed)
	await cross.finished
	# It stops in the lamp light and looks in; Dylan starts back from the glass.
	animal.visual.play_clip(&"look")
	_dylan().play_scripted(&"startled", &"idle")
	operation.show_notice("Something is circling the shed.", 3.0 / cutscene_speed)
	await _wait(1.6)
	animal.visual.play_clip(&"walk", 1.4)
	var leave := create_tween()
	leave.tween_property(animal, "position", ANIMAL_TO, ANIMAL_PAUSE_AT.distance_to(ANIMAL_TO) / 1.4 / cutscene_speed)
	await _wait(1.2)
	# Back to the room view; the bars lift and the rear door is the player's.
	camera.current = true
	_dylan().end_interaction()
	await bars.set_shown(false, 0.5 / cutscene_speed).finished
	if is_instance_valid(animal):
		animal.queue_free()
	beat = &"done"
	player.set_control_enabled(true)
	operation.show_notice("Objective: %s" % MissionState.objective(), 4.0)
