extends Control
## Phase 2 — the perimeter trail, north of the guardhouse yard. Same contract as
## the exterior: one authored spatial source owns collision, three fixed
## framings own the camera. Authored plates share the geometry's projection;
## B switches between art and geometry for inspection.
const SOURCE := preload("res://environments/perimeter_source.tscn")
const DEFINITIONS := [preload("res://resources/perimeter/shot_1.tres"),preload("res://resources/perimeter/shot_2.tres"),preload("res://resources/perimeter/shot_3.tres")]
## Plate hook: dropping these files in turns art mode on, one framing at a time.
## The three plates follow the revised geometry of 13/10/2026: open pen trail,
## side props, front door at grade. Behind the shed is the service yard, a level
## of its own since 14/10/2026; the provisional patch and its view are gone.
const ART_DIR := "res://assets/backgrounds/dc2_psx/"
const ART_FILES := ["perimeter_cam01.png","perimeter_cam02.png","perimeter_cam03.png"]
const ZONE_CENTERS := [Vector3(0,2,-5),Vector3(0,2,-15),Vector3(0,2,-25.5)]
const ZONE_SIZES := [Vector3(14,6,11),Vector3(16,6,10),Vector3(14,6,12)]
## The relay shed's front door, at grade: the trail runs flush to the wall at
## z = -26,9 and the capsule stops at -26,6, inside the prompt's radius. The
## room sends Dylan back out a pace further from the door.
const RELAY_APPROACH := Vector3(0,0,-26.25)
const RELAY_ARRIVAL := Vector3(0,0,-25.95)
## The service gate back to the yard, and where the player stands to use it.
const GATE_APPROACH := Vector3(0,0,-1.1)
const GATE_ARRIVAL := Vector3(0,0.06,-2.2)
## North of this line the relay shed has been reached and the phase closes.
const RELAY_Z := -24.0
## The animals keep to the pen stretch until they perceive Dylan. The first
## home is the original animal's; the second starts deeper in the pen.
const KELEKEN_HOME := Vector3(0.6,0.06,-14.5)
const KELEKEN_HOMES: Array[Vector3] = [KELEKEN_HOME, Vector3(-1.3,0.06,-17.6)]
const KELEKEN_BOUNDS := Rect2(-2.3,-19.0,4.6,8.5)
## Floating health packs, by PickupStore id, on the floor point each hovers
## over. One inside the animals' patrol, between the trough and the feed sacks;
## one past the fallen pine, on the side its passage does not lead to. The third,
## `rear_yard`, moved to the service yard with the patch it lay in.
const HEALTH_PACKS := {
	&"trail_pen": Vector3(2.0,0.06,-14.9),
	&"trail_shed": Vector3(-1.5,0.06,-24.5),
}
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
var operation: LevelOperation
## The first animal and its patrol, as before; `kelekens` holds them all.
var keleken: KelekenActor
var keleken_wander: KelekenWander
var kelekens: Array[KelekenActor] = []
var keleken_wanders: Array[KelekenWander] = []
var health_packs: Array[HealthPack] = []

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
	gate.passage = &"gate"
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
	operation = LevelOperation.new()
	operation.name = "Operation"
	operation.player = player
	operation.director = director
	operation.frame = $Frame/Composition
	operation.restart_requested.connect(restart)
	add_child(operation)
	for index: int in range(KELEKEN_HOMES.size()):
		var animal: KelekenActor = preload("res://actors/keleken/keleken.tscn").instantiate()
		animal.name = "Keleken" if index == 0 else "Keleken%d" % (index + 1)
		animal.combat_enabled = true
		animal.player = player
		world.add_child(animal)
		var wander: KelekenWander = preload("res://actors/keleken/keleken_wander.gd").new()
		wander.home_position = KELEKEN_HOMES[index]
		wander.bounds = KELEKEN_BOUNDS
		animal.add_child(wander)
		kelekens.append(animal)
		keleken_wanders.append(wander)
	keleken = kelekens[0]
	keleken_wander = keleken_wanders[0]
	for id: StringName in HEALTH_PACKS:
		var pack: HealthPack = preload("res://actors/pickups/health_pack.tscn").instantiate()
		pack.name = "HealthPack_" + String(id)
		pack.pack_id = id
		pack.player = player
		pack.position = HEALTH_PACKS[id]
		world.add_child(pack)
		health_packs.append(pack)
	_update_label()

## Two ways in: the yard gate, and the relay shed's front door coming back out.
func arrive_from_door() -> void:
	if DoorInteraction.arrived_from == &"relay_front":
		_place_at_shed()
	else:
		player.reset_to(Transform3D(Basis.IDENTITY,GATE_ARRIVAL))
		player.visual.rotation.y = 0.0
		director.reset_to(shots[0])
	operation.mark_safe()
	if MissionState.reach(MissionState.Stage.PERIMETER):
		operation.show_notice("Objective: %s" % MissionState.objective(),3.0)
	_update_label()

func _place_at_shed() -> void:
	player.reset_to(Transform3D(Basis.IDENTITY,RELAY_ARRIVAL))
	player.visual.rotation.y = PI
	director.reset_to(shots[2])

## Esc → Reiniciar, and R. A fresh attempt of this phase only: the actor, the
## camera, the animal and the objective go back to its start, while the phases
## already closed stay closed and the stored record is left alone. After the
## outage the relay is already behind the player, so a restart keeps the
## objective and puts him at the shed door. Health packs taken since the last
## save are back.
func restart() -> void:
	player.reset_to_start()
	PickupStore.rewind(HEALTH_PACKS.keys())
	for wander: KelekenWander in keleken_wanders:
		wander.reset()
	if MissionState.stage >= MissionState.Stage.OUTAGE:
		_place_at_shed()
	else:
		director.reset_to(shots[0])
		Phase.find(&"perimeter").rewind()
	operation.mark_safe()
	operation.hide_notice()
	_update_label()

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
