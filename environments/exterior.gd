extends Control
## Authored level; original ENV_1 images and their experimental scene stay separate.
const SOURCE := preload("res://environments/exterior_source.tscn")
const DEFINITIONS := [preload("res://resources/exterior/shot_1.tres"),preload("res://resources/exterior/shot_2.tres"),preload("res://resources/exterior/shot_3.tres"),preload("res://resources/exterior/shot_4.tres")]
const ART_DIR := "res://assets/backgrounds/env_1/exterior_authored/"
## One plate per framing. The north yard, added with the service gate, has no
## plate yet: that framing shows its geometry while the other three paint.
const ART_FILES := ["art_cam01_v01.png","art_cam02_v02.png","art_cam03_v01.png","art_cam04_v01.png"]
const ZONE_CENTERS := [Vector3(0,2,22),Vector3(-2,2,7),Vector3(-5,2,3.5),Vector3(1,2,-4)]
const ZONE_SIZES := [Vector3(7,6,16),Vector3(22,6,16),Vector3(8,6,10),Vector3(14,6,6)]
## North of the raised barrier the player is still on the road; south of it the
## yard objective has been reached. The barrier itself sits at z = 10.
const GATE_Z := 9.0
## The service gate out of the yard, where Phase 2 begins, and where the player
## stands when coming back through it.
const NORTH_GATE_APPROACH := Vector3(0,0,-5.9)
const NORTH_GATE_ARRIVAL := Vector3(0,0.06,-5.6)
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
var doorway: DoorInteraction
var north_gate: PhaseGate
var operation: LevelOperation

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
		var shape: Shape3D
		if mesh.has_meta("collision_size"):
			var box := BoxShape3D.new()
			box.size = mesh.get_meta("collision_size")
			shape = box
		elif mesh.has_meta("collision_points"):
			var ramp := ConvexPolygonShape3D.new()
			ramp.points = mesh.get_meta("collision_points")
			shape = ramp
		else:
			continue
		var body := StaticBody3D.new()
		body.name = mesh.name
		body.transform = mesh.transform
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
	doorway = DoorInteraction.new()
	doorway.player = player
	doorway.approach = Vector3(-4.45, 0.6, 3.7)
	doorway.facing = 0.0
	doorway.target_scene = "res://environments/save_room.tscn"
	add_child(doorway)
	operation = LevelOperation.new()
	operation.name = "Operation"
	operation.player = player
	operation.director = director
	operation.frame = $Frame/Composition
	operation.restart_requested.connect(restart)
	add_child(operation)
	# Phase 2 leaves through the north fence. It stays bolted until the terminal
	# has the progress, so the guardhouse content closes before the trail opens.
	north_gate = PhaseGate.new()
	north_gate.player = player
	north_gate.approach = NORTH_GATE_APPROACH
	north_gate.facing = 0.0
	north_gate.entry_id = &"yard_gate"
	north_gate.phase_id = &"perimeter"
	north_gate.open_hint = "North gate"
	north_gate.locked_hint = "North gate bolted"
	north_gate.refused.connect(func() -> void: operation.show_notice("The north gate stays bolted until your progress is recorded at the terminal.",3.0))
	add_child(north_gate)
	_update_label()

## Two ways in: the guardhouse door, on its platform, and the north service gate
## coming back from the perimeter trail.
func arrive_from_door() -> void:
	if DoorInteraction.arrived_from == &"north_gate":
		player.reset_to(Transform3D(Basis.IDENTITY, NORTH_GATE_ARRIVAL))
		player.visual.rotation.y = PI
		director.reset_to(shots[3])
	else:
		player.reset_to(Transform3D(Basis.IDENTITY, Vector3(-4.45, 0.66, 3.85)))
		player.visual.rotation.y = PI
		director.reset_to(shots[2])
	operation.mark_safe()
	_update_label()

## Esc → Reiniciar, and R. A fresh attempt of the Fase 1 content: the actor, the
## camera and the objective go back to the start. The stored record is not
## touched, because restarting an attempt is not erasing a save.
func restart() -> void:
	player.reset_to_start()
	director.reset_to(shots[0])
	MissionState.reset()
	operation.mark_safe()
	operation.hide_notice()
	_update_label()

func _physics_process(_delta: float) -> void:
	if MissionState.stage == MissionState.Stage.ROAD and player.global_position.z < GATE_Z:
		_advance(MissionState.Stage.YARD)

func _advance(stage: MissionState.Stage) -> void:
	if not MissionState.reach(stage):
		return
	operation.show_notice("Objective: %s" % MissionState.objective(), 3.0)
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
	instructions.text = "EXTERIOR · %s · %s
%s · Shift run · Q dodge · H med kit · E door/gate · B art/geometry · F4 filter · T controls (%s) · F3 diagnostics · R restart · Esc pause
%s" % [shot_name,"CANDIDATE ART — alignment under review" if presentation.art_mode else "3D GEOMETRY",movement,ControlScheme.label(),MissionState.objective()]
