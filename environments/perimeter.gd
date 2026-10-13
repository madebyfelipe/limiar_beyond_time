extends Control
## Phase 2 — the perimeter trail, north of the guardhouse yard. Same contract as
## the exterior: one authored spatial source owns collision, three fixed
## framings own the camera, and the plates are a later pass. No art exists for
## these framings yet, so the level runs its geometry and says so on screen.
const SOURCE := preload("res://environments/perimeter_source.tscn")
const DEFINITIONS := [preload("res://resources/perimeter/shot_1.tres"),preload("res://resources/perimeter/shot_2.tres"),preload("res://resources/perimeter/shot_3.tres")]
## Plate hook: dropping these files in turns art mode on, one framing at a time.
const ART_DIR := "res://assets/backgrounds/perimeter/authored/"
const ART_FILES := ["art_cam01_v01.png","art_cam02_v01.png","art_cam03_v01.png"]
const ZONE_CENTERS := [Vector3(0,2,-5),Vector3(0,2,-15),Vector3(0,2,-25.5)]
const ZONE_SIZES := [Vector3(14,6,11),Vector3(16,6,10),Vector3(14,6,12)]
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
	for index: int in range(3):
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
	for index: int in range(3):
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

## Arriving through the yard gate: the player steps in facing the trail.
func arrive_from_door() -> void:
	player.reset_to(Transform3D(Basis.IDENTITY,GATE_ARRIVAL))
	player.visual.rotation.y = 0.0
	director.reset_to(shots[0])
	operation.mark_safe()
	if MissionState.reach(MissionState.Stage.PERIMETER):
		operation.show_notice("Objective: %s" % MissionState.objective(),3.0)
	_update_label()

## Esc → Reiniciar, and R. A fresh attempt of this phase only: the actor, the
## camera, the animal and the objective go back to its start, while the phases
## already closed stay closed and the stored record is left alone.
func restart() -> void:
	player.reset_to_start()
	keleken_wander.reset()
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
%s · Shift run · Q dodge · H med kit · E gate · F4 filter · T controls (%s) · F3 diagnostics · R restart · Esc pause
%s" % [shot_name,"CANDIDATE ART — alignment under review" if presentation.art_mode else "3D GEOMETRY — no plate authored yet",movement,ControlScheme.label(),MissionState.objective()]
