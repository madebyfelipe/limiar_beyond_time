extends Control
## Environment 5 — the service yard behind the relay shed, the hub the site plan
## hangs four doors on. Basic geometry: one authored spatial source owns
## collision and four fixed framings own the camera, as on the trail. No plate
## is authored yet. The relay's rear door is the way in and out; the other four
## doors are only drawn, as the rooms behind them are not built. The yard is
## reached at REAR_YARD and is not a phase of its own until something closes it.
const SOURCE := preload("res://environments/service_yard_source.tscn")
const DEFINITIONS := [preload("res://resources/service_yard/shot_1.tres"),preload("res://resources/service_yard/shot_2.tres"),preload("res://resources/service_yard/shot_3.tres"),preload("res://resources/service_yard/shot_4.tres")]
## Plate hook: dropping these files in turns art mode on, one framing at a time.
const ART_DIR := "res://assets/backgrounds/dc2_psx/"
const ART_FILES := ["service_yard_cam01.png","service_yard_cam02.png","service_yard_cam03.png","service_yard_cam04.png"]
## Middle, west and east strips of the yard, then the arm. The zones overlap by
## a metre and a half and share one priority, so the director keeps the framing
## it has until the actor is clear of its strip: no cut flickers on a border
## that a fight is being fought across.
const ZONE_CENTERS := [Vector3(0,2,-41.25),Vector3(-8.125,2,-41.125),Vector3(8.125,2,-41.25),Vector3(-9,2,-55.875)]
const ZONE_SIZES := [Vector3(9.5,6,20.5),Vector3(9.75,6,20.25),Vector3(9.75,6,20.5),Vector3(8,6,12.25)]
## Out of the shed's rear door, a pace into the yard, facing north.
const REAR_ARRIVAL := Vector3(2.4,0.06,-33.2)
const RELAY_ROOM := "res://environments/relay_room.tscn"
## Where the actor stands to use each door, by the id the site plan gives it.
## Only the relay's rear door travels.
const DOOR_APPROACHES := {
	&"relay_rear": Vector3(2.4,0,-32.9),
	&"kennel_north": Vector3(-9.3,0,-32.9),
	&"quarters_door": Vector3(11.1,0,-41.9),
	&"generator_front": Vector3(1.3,0,-49.6),
	&"generator_side": Vector3(-6.4,0,-55.75),
}
## The open ground kept clear of everything, for the scripted scene and for the
## fight or the run that follows it: x and z, 12 m a side.
const CLEARING := Rect2(-2.7,-50.2,11.9,11.9)
## Where the fence is down, by the floor point just inside each breach.
const BREACHES := {
	&"west": Vector3(-11.0,0.06,-46.25),
	&"north_east": Vector3(9.25,0.06,-49.5),
	&"arm": Vector3(-8.75,0.06,-60.0),
}
## Where a pack keeps to until it perceives Dylan: its ground and its animals'
## homes. Each pocket is out of sight of the rear door or beyond the 8 m an
## animal perceives, so nothing is on him as he steps out.
const PACKS: Array[Dictionary] = [
	{"id": &"north_east", "bounds": Rect2(3.0,-50.0,8.5,4.8), "homes": [Vector3(8.2,0.06,-48.2),Vector3(4.8,0.06,-47.0)]},
	{"id": &"west", "bounds": Rect2(-11.5,-50.0,7.5,6.8), "homes": [Vector3(-9.6,0.06,-48.6),Vector3(-5.4,0.06,-44.8)]},
	{"id": &"arm", "bounds": Rect2(-11.5,-60.5,5.7,5.5), "homes": [Vector3(-8.75,0.06,-58.0)]},
]
## Floating health packs, by PickupStore id. `rear_yard` kept its id when the
## provisional patch behind the shed gave way to this yard, so a record that
## took it still has it taken. It lies in the arm, past the pallets, on the
## ground one animal keeps: the pack is worth the risk of going for it.
const HEALTH_PACKS := {
	&"rear_yard": Vector3(-10.6,0.06,-56.5),
}
@onready var world: Node3D = $Frame/Composition/Actors/WorldViewport/World
@onready var background: TextureRect = $Frame/Composition/Background
@onready var player: PlayerController = $Frame/Composition/Actors/WorldViewport/World/Player
@onready var instructions: Label = $Instructions
## The yard is authored empty. `--dinos` after `--` on the command line, or this
## flag set before the scene enters the tree, puts an animal on every home so
## the space can be tried against them.
@export var populate: bool = false
var source: Node3D
var colliders: Node3D
var shots: Array[ShotRig] = []
var director: CameraDirector
var presentation: PresentationController
## True once at least one framing has a plate of its own.
var art_available: bool = false
var operation: LevelOperation
var rear_door: DoorInteraction
var health_packs: Array[HealthPack] = []
var kelekens: Array[KelekenActor] = []
var keleken_wanders: Array[KelekenWander] = []

func _ready() -> void:
	instructions.visible = OS.get_cmdline_args().has("--debug-instructions")
	populate = populate or OS.get_cmdline_user_args().has("--dinos")
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
		if ResourceLoader.exists(image_path):
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
	operation = LevelOperation.new()
	operation.name = "Operation"
	operation.player = player
	operation.director = director
	operation.frame = $Frame/Composition
	operation.restart_requested.connect(restart)
	add_child(operation)
	rear_door = DoorInteraction.new()
	rear_door.name = "RelayRearDoor"
	rear_door.player = player
	rear_door.approach = DOOR_APPROACHES[&"relay_rear"]
	rear_door.radius = 0.6
	rear_door.facing = PI
	rear_door.entry_id = &"relay_rear_in"
	rear_door.target_scene = RELAY_ROOM
	rear_door.destination_name = "Relay Room"
	add_child(rear_door)
	for id: StringName in HEALTH_PACKS:
		var pack: HealthPack = preload("res://actors/pickups/health_pack.tscn").instantiate()
		pack.name = "HealthPack_" + String(id)
		pack.pack_id = id
		pack.player = player
		pack.position = HEALTH_PACKS[id]
		world.add_child(pack)
		health_packs.append(pack)
	if populate:
		_populate()
	_update_label()

## One animal on every home, each keeping to its own pack's ground.
func _populate() -> void:
	for pack: Dictionary in PACKS:
		for home: Vector3 in pack["homes"]:
			var animal: KelekenActor = preload("res://actors/keleken/keleken.tscn").instantiate()
			animal.name = "Keleken%d" % (kelekens.size() + 1)
			animal.combat_enabled = true
			animal.player = player
			world.add_child(animal)
			var wander: KelekenWander = preload("res://actors/keleken/keleken_wander.gd").new()
			wander.home_position = home
			wander.bounds = pack["bounds"]
			animal.add_child(wander)
			kelekens.append(animal)
			keleken_wanders.append(wander)

## Out of the relay's rear door, the only way in so far.
func arrive_from_door() -> void:
	player.reset_to(Transform3D(Basis.IDENTITY,REAR_ARRIVAL))
	player.visual.rotation.y = 0.0
	director.reset_to(shots[0])
	operation.mark_safe()
	if MissionState.reach(MissionState.Stage.REAR_YARD):
		operation.show_notice("Objective: %s" % MissionState.objective(),3.0)
	_update_label()

## Esc → Reiniciar, and R: the actor back at the rear door, the animals back on
## their homes, the packs taken since the last save back where they lay. The
## objective and the stored record are left alone.
func restart() -> void:
	player.reset_to_start()
	PickupStore.rewind(HEALTH_PACKS.keys())
	for wander: KelekenWander in keleken_wanders:
		wander.reset()
	director.reset_to(shots[0])
	operation.mark_safe()
	operation.hide_notice()
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
	instructions.text = "SERVICE YARD · %s · %s
%s · Shift run · Q dodge · H med kit · E door · F4 filter · T controls (%s) · F3 diagnostics · R restart · Esc pause
%s" % [shot_name,"CANDIDATE ART — alignment under review" if presentation.art_mode else "3D GEOMETRY — no plate authored yet",movement,ControlScheme.label(),"%d animals" % kelekens.size() if populate else "no animals (run with -- --dinos)"]
