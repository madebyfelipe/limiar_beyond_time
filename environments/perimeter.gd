extends Control
## Phase 2 — the perimeter trail, north of the guardhouse yard. Same contract as
## the exterior: one authored spatial source owns collision, three fixed
## framings own the camera. Authored plates share the geometry's projection;
## B switches between art and geometry for inspection.
const SOURCE := preload("res://environments/perimeter_source.tscn")
const DEFINITIONS := [preload("res://resources/perimeter/shot_1.tres"),preload("res://resources/perimeter/shot_2.tres"),preload("res://resources/perimeter/shot_3.tres"),preload("res://resources/perimeter/shot_4.tres")]
## Plate hook: dropping these files in turns art mode on, one framing at a time.
## The fourth framing, the yard behind the relay shed, has no plate: it is a
## provisional way out until the next outdoor area exists, and shows geometry.
## The second framing was turned on 13/10/2026 to look up the trail like the
## third, so the stick keeps its meaning across the cut; its v02 plate belongs
## to the old side-on pose and stays out until a plate is painted for this one
## (ART_CAM02_V03_PROMPT.txt).
const ART_DIR := "res://assets/backgrounds/perimeter/authored/"
const ART_FILES := ["art_cam01_v02.png","","art_cam03_v02.png",""]
const ZONE_CENTERS := [Vector3(0,2,-5),Vector3(0,2,-15),Vector3(0,2,-25.5),Vector3(0,2,-36.5)]
const ZONE_SIZES := [Vector3(14,6,11),Vector3(16,6,10),Vector3(14,6,12),Vector3(13,6,9)]
## The relay shed's front door, from the step's foot on the trail (a 0,2 m
## step the capsule cannot climb), and where the room sends Dylan back out.
const RELAY_APPROACH := Vector3(0,0,-25.75)
const RELAY_ARRIVAL := Vector3(0,0,-25.45)
## The rear door cut into the shed's back wall, and the yard behind it. The
## yard is closed by invisible bounds: nothing is authored past them yet.
const REAR_DOOR_X := 2.4
const REAR_APPROACH := Vector3(2.4,0,-32.9)
const REAR_ARRIVAL := Vector3(2.4,0,-33.2)
const REAR_BOUNDS := [
	[Vector3(-6.6,1.5,-36.5),Vector3(0.2,3,9.4)],
	[Vector3(6.6,1.5,-36.5),Vector3(0.2,3,9.4)],
	[Vector3(0,1.5,-41.1),Vector3(13.4,3,0.2)],
	[Vector3(-4.95,1.5,-31.95),Vector3(3.3,3,0.2)],
	[Vector3(4.95,1.5,-31.95),Vector3(3.3,3,0.2)],
	# The three pines behind the shed are only drawn in the source; their trunks
	# stop the actor here.
	[Vector3(-6.5,1.5,-33.5),Vector3(0.5,3,0.5)],
	[Vector3(0,1.5,-33.5),Vector3(0.5,3,0.5)],
	[Vector3(6.5,1.5,-33.5),Vector3(0.5,3,0.5)],
]
## The service gate back to the yard, and where the player stands to use it.
const GATE_APPROACH := Vector3(0,0,-1.1)
const GATE_ARRIVAL := Vector3(0,0.06,-2.2)
## North of this line the relay shed has been reached and the phase closes.
const RELAY_Z := -24.0
## The animal keeps to the pen stretch until it perceives Dylan.
const KELEKEN_HOME := Vector3(0.6,0.06,-14.5)
const KELEKEN_BOUNDS := Rect2(-2.3,-19.0,4.6,8.5)
@onready var world: Node3D = $Frame/Composition/Actors/WorldViewport/World
@onready var background: TextureRect = $Frame/Composition/Background
@onready var player: PlayerController = $Frame/Composition/Actors/WorldViewport/World/Player
@onready var instructions: Label = $Instructions
var source: Node3D
var colliders: Node3D
var shots: Array[ShotRig] = []
var director: CameraDirector
var presentation: PresentationController
## True once at least one framing has a plate of its own.
var art_available: bool = false
var gate: DoorInteraction
var relay_door: PhaseGate
var rear_door: DoorInteraction
var operation: LevelOperation
var keleken: KelekenActor
var keleken_wander: KelekenWander

func _ready() -> void:
	instructions.visible = OS.get_cmdline_args().has("--debug-instructions")
	world.get_node("Capsule").hide()
	world.get_node("Light").hide()
	background.hide()
	var environment_node: WorldEnvironment = world.get_node("Environment")
	environment_node.environment = environment_node.environment.duplicate()
	environment_node.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment_node.environment.ambient_light_color = Color("b6c5d1")
	environment_node.environment.ambient_light_energy = 0.65
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
	_build_rear_yard()
	for index: int in range(DEFINITIONS.size()):
		var definition: ShotDefinition = DEFINITIONS[index].duplicate()
		var image_path: String = ART_DIR+ART_FILES[index]
		if ART_FILES[index] != "" and ResourceLoader.exists(image_path):
			definition.background = load(image_path)
			art_available = true
		var rig := ShotRig.new()
		rig.name = String(definition.shot_id)
		rig.definition = definition
		rig.camera = Camera3D.new()
		rig.add_child(rig.camera)
		rig.light = DirectionalLight3D.new()
		rig.light.rotation_degrees = Vector3(-60,-25,0)
		rig.light.light_color = Color("b6c5d1")
		rig.light.light_energy = 0.85
		rig.add_child(rig.light)
		world.add_child(rig)
		shots.append(rig)
	presentation = preload("res://environments/exterior_presentation.gd").new()
	presentation.background = background
	presentation.player = player
	presentation.shots = shots
	presentation.source = source
	world.add_child(presentation)
	var zones: Array[CameraZone] = []
	for index: int in range(DEFINITIONS.size()):
		var zone := CameraZone.new()
		zone.position = ZONE_CENTERS[index]
		zone.shot = shots[index]
		zone.shot_priority = index
		zone.collision_layer = 0
		zone.collision_mask = 1
		var shape := BoxShape3D.new()
		shape.size = ZONE_SIZES[index]
		var collision := CollisionShape3D.new()
		collision.shape = shape
		zone.add_child(collision)
		world.add_child(zone)
		zones.append(zone)
	director = CameraDirector.new()
	director.player = player
	director.zones = zones
	director.initial_shot = shots[0]
	director.presentation = presentation
	director.process_physics_priority = 10
	director.shot_changed.connect(func(_previous: StringName,_current: StringName) -> void: _update_label())
	world.add_child(director)
	set_art_mode(art_available)
	gate = DoorInteraction.new()
	gate.player = player
	gate.approach = GATE_APPROACH
	gate.facing = PI
	gate.entry_id = &"north_gate"
	gate.target_scene = Phase.find(&"guardhouse").entry_scene
	gate.destination_name = "Guardhouse Yard"
	gate.returning_outside = true
	add_child(gate)
	relay_door = PhaseGate.new()
	relay_door.name = "RelayDoor"
	relay_door.player = player
	relay_door.approach = RELAY_APPROACH
	relay_door.radius = 0.6
	relay_door.facing = 0.0
	relay_door.phase_id = &"relay"
	relay_door.entry_id = &"relay_front_in"
	relay_door.destination_name = "Relay Room"
	relay_door.open_hint = "Relay shed door"
	relay_door.locked_hint = "Relay shed door sealed"
	add_child(relay_door)
	rear_door = DoorInteraction.new()
	rear_door.name = "RelayRearDoor"
	rear_door.player = player
	rear_door.approach = REAR_APPROACH
	rear_door.radius = 0.6
	rear_door.facing = PI
	rear_door.entry_id = &"relay_rear_in"
	rear_door.target_scene = "res://environments/relay_room.tscn"
	rear_door.destination_name = "Relay Room"
	add_child(rear_door)
	operation = LevelOperation.new()
	operation.name = "Operation"
	operation.player = player
	operation.director = director
	operation.frame = $Frame/Composition
	operation.restart_requested.connect(restart)
	add_child(operation)
	keleken = preload("res://actors/keleken/keleken.tscn").instantiate()
	keleken.name = "Keleken"
	keleken.combat_enabled = true
	keleken.player = player
	world.add_child(keleken)
	keleken_wander = preload("res://actors/keleken/keleken_wander.gd").new()
	keleken_wander.home_position = KELEKEN_HOME
	keleken_wander.bounds = KELEKEN_BOUNDS
	keleken.add_child(keleken_wander)
	_update_label()

## Three ways in: the yard gate, the relay shed's front door coming back out,
## and its rear door after the outage.
func arrive_from_door() -> void:
	match DoorInteraction.arrived_from:
		&"relay_front":
			player.reset_to(Transform3D(Basis.IDENTITY,RELAY_ARRIVAL))
			player.visual.rotation.y = PI
			director.reset_to(shots[2])
		&"relay_rear":
			_place_in_rear_yard()
		_:
			player.reset_to(Transform3D(Basis.IDENTITY,GATE_ARRIVAL))
			player.visual.rotation.y = 0.0
			director.reset_to(shots[0])
	operation.mark_safe()
	var reached: MissionState.Stage = MissionState.Stage.REAR_YARD if DoorInteraction.arrived_from == &"relay_rear" else MissionState.Stage.PERIMETER
	if MissionState.reach(reached):
		operation.show_notice("Objective: %s" % MissionState.objective(),3.0)
	_update_label()

func _place_in_rear_yard() -> void:
	player.reset_to(Transform3D(Basis.IDENTITY,REAR_ARRIVAL))
	player.visual.rotation.y = 0.0
	director.reset_to(shots[3])

## Esc → Reiniciar, and R. A fresh attempt of this phase only: the actor, the
## camera, the animal and the objective go back to its start, while the phases
## already closed stay closed and the stored record is left alone. Out behind
## the shed the relay is already behind the player, so a restart there keeps
## the yard and the objective.
func restart() -> void:
	player.reset_to_start()
	keleken_wander.reset()
	if MissionState.stage >= MissionState.Stage.OUTAGE:
		_place_in_rear_yard()
	else:
		director.reset_to(shots[0])
		Phase.find(&"perimeter").rewind()
	operation.mark_safe()
	operation.hide_notice()
	_update_label()

## The rear door on the shed's back wall, its threshold, and the bounds of the
## provisional yard behind it.
func _build_rear_yard() -> void:
	var door_material := StandardMaterial3D.new()
	door_material.albedo_color = Color("5d6a6c")
	door_material.albedo_texture = preload("res://assets/textures/doors/painted_steel_v01.png")
	door_material.uv1_triplanar = true
	door_material.uv1_scale = Vector3.ONE * 0.7
	for part: Array in [["RelayRearDoor",Vector3(REAR_DOOR_X,1.425,-31.95),Vector3(0.9,2.05,0.1)],["RelayRearSill",Vector3(REAR_DOOR_X,0.02,-32.25),Vector3(1.1,0.04,0.5)]]:
		var mesh := MeshInstance3D.new()
		mesh.name = part[0]
		var box := BoxMesh.new()
		box.size = part[2]
		mesh.mesh = box
		mesh.material_override = door_material
		mesh.position = part[1]
		source.add_child(mesh)
	for index: int in range(REAR_BOUNDS.size()):
		var body := StaticBody3D.new()
		body.name = "RearYardBound%d" % index
		body.position = REAR_BOUNDS[index][0]
		var shape := BoxShape3D.new()
		shape.size = REAR_BOUNDS[index][1]
		var collision := CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
		colliders.add_child(body)

func _physics_process(_delta: float) -> void:
	if MissionState.stage == MissionState.Stage.PERIMETER and player.global_position.z < RELAY_Z:
		_advance(MissionState.Stage.RELAY)

func _advance(stage: MissionState.Stage) -> void:
	if not MissionState.reach(stage):
		return
	operation.show_notice("Objective: %s" % MissionState.objective(),4.0)
	_update_label()

func _unhandled_key_input(event: InputEvent) -> void:
	if InputBindings.is_custom_event(event):
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_B:
			set_art_mode(not presentation.art_mode)
		elif event.physical_keycode == KEY_T:
			ControlScheme.toggle()
			_update_label()
		elif event.physical_keycode == KEY_R:
			if player.weapon == null or (not player.weapon.aiming and not player.weapon.is_reloading()):
				restart()

func set_art_mode(enabled: bool) -> void:
	if enabled and not art_available:
		return
	presentation.set_art_mode(enabled)
	_update_label()

func _update_label() -> void:
	var shot_name: String = String(presentation.current_shot.definition.shot_id) if presentation.current_shot else ""
	var movement: String = "arrows turn and move" if ControlScheme.is_tank() else "WASD/arrows move"
	instructions.text = "PERIMETER · %s · %s
%s · Shift run · Q dodge · H med kit · E gate/door · F4 filter · T controls (%s) · F3 diagnostics · R restart · Esc pause
%s" % [shot_name,"CANDIDATE ART — alignment under review" if presentation.art_mode else "3D GEOMETRY — no plate authored yet",movement,ControlScheme.label(),MissionState.objective()]
