extends Control
## Geometry owns the camera, collision and scale. B previews the art candidate.
const SOURCE := preload("res://environments/save_room_source.tscn")
const SHOT := preload("res://resources/save_room/shot_01.tres")
const ART := "res://assets/backgrounds/env_1/save_room/art_cam01_close_v01.png"
const SCENE_PATH := "res://environments/save_room.tscn"
## Closest spot the 1,8 m capsule can stand to the keyboard, measured against
## the room's own colliders; the chair keeps it just west of the monitor.
const TERMINAL_APPROACH := Vector3(-0.05, 0.0, -1.25)
@onready var world: Node3D = $Frame/Composition/Actors/WorldViewport/World
@onready var background: TextureRect = $Frame/Composition/Background
@onready var camera: Camera3D = $Frame/Composition/Actors/WorldViewport/World/Camera
@onready var player: PlayerController = $Frame/Composition/Actors/WorldViewport/World/Player
@onready var label: Label = $Instructions
var source: Node3D
var colliders: Node3D
var art_mode: bool = false
var overview: bool = false
var doorway: DoorInteraction
var terminal: TerminalInteraction
var operation: LevelOperation
## True when this session started from a stored record instead of the spawn.
var resumed: bool = false

func _ready() -> void:
	label.visible = OS.get_cmdline_args().has("--debug-instructions")
	$Frame/Composition/Actors/WorldViewport/World/Capsule.hide()
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
	camera.position = SHOT.camera_position
	camera.rotation_degrees = SHOT.camera_rotation_degrees
	camera.fov = SHOT.fov
	player.camera = camera
	set_art_mode(true)
	doorway = DoorInteraction.new()
	doorway.player = player
	doorway.approach = Vector3(-2.4, 0.0, 0.55)
	doorway.facing = PI / 2
	doorway.target_scene = "res://environments/exterior.tscn"
	doorway.entry_id = &"guardhouse_door"
	doorway.returning_outside = true
	add_child(doorway)
	terminal = TerminalInteraction.new()
	terminal.player = player
	terminal.approach = TERMINAL_APPROACH
	terminal.radius = 0.8
	terminal.scene_path = SCENE_PATH
	terminal.saved.connect(_on_saved)
	add_child(terminal)
	operation = LevelOperation.new()
	operation.name = "Operation"
	operation.player = player
	operation.frame = $Frame/Composition
	operation.restart_requested.connect(restart)
	add_child(operation)
	# Saving happens here, so this is the room a stored record sends you back to,
	# with the objective it had reached.
	resumed = SaveGame.resume(player, SCENE_PATH)
	operation.mark_safe()
	_update_label()

func arrive_from_door() -> void:
	resumed = false
	player.reset_to_start()
	player.visual.rotation.y = -PI / 2
	operation.mark_safe()
	# Being inside is the objective that the yard pointed at.
	if MissionState.reach(MissionState.Stage.TERMINAL):
		operation.show_notice("Objective: %s" % MissionState.objective(), 3.0)
	_update_label()

## Esc → Reiniciar, and R. Back to the door with the objective reset; the stored
## record is left alone, because restarting an attempt is not erasing a save.
func restart() -> void:
	resumed = false
	player.reset_to_start()
	MissionState.reset()
	operation.mark_safe()
	operation.hide_notice()
	_update_label()

func _on_saved(_record: Dictionary) -> void:
	operation.show_notice(MissionState.objective(), 4.0)
	_update_label()

func _unhandled_key_input(event: InputEvent) -> void:
	if InputBindings.is_custom_event(event):
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_B:
			set_art_mode(not art_mode)
		elif event.physical_keycode == KEY_R:
			if player.weapon == null or (not player.weapon.aiming and not player.weapon.is_reloading()):
				restart()
		elif event.physical_keycode == KEY_C:
			set_overview(not overview)
		elif event.physical_keycode == KEY_T:
			ControlScheme.toggle()
			_update_label()

func set_art_mode(enabled: bool) -> void:
	if enabled and not ResourceLoader.exists(ART):
		return
	art_mode = enabled
	if enabled and overview:
		set_overview(false)
	background.visible = enabled
	var material: ShaderMaterial
	if enabled:
		background.texture = load(ART)
		material = ShaderMaterial.new()
		material.shader = preload("res://systems/camera/background_occluder.gdshader")
		material.set_shader_parameter("background",background.texture)
	for mesh: MeshInstance3D in source.get_children():
		mesh.material_override = material
	_update_label()

func _update_label() -> void:
	var movement: String = "arrows turn and move" if ControlScheme.is_tank() else "WASD/arrows move"
	label.text = "ROOM — %s
%s · E door or terminal · B art/geometry · C overview/interior · F4 filter · T controls (%s) · F3 diagnostics · R restart · Esc pause
%s
%s" % [("CANDIDATE ART — alignment under review" if art_mode else ("GEOMETRY · overview" if overview else "GEOMETRY · interior")),movement,ControlScheme.label(),MissionState.objective(),_save_line()]

## What the stored record says, so resuming is visible instead of surprising.
func _save_line() -> String:
	var record: Dictionary = SaveGame.read()
	if record.is_empty():
		return "NO SAVE — use the desk terminal"
	return "RECORD %d · %s%s" % [record["saves"], SaveGame.stamp(record), " · resumed" if resumed else ""]

func set_overview(enabled: bool) -> void:
	if enabled and art_mode:
		set_art_mode(false)
	overview = enabled
	if enabled:
		camera.position = Vector3(8,8.5,10)
		camera.look_at(Vector3(0,0.7,0))
		camera.fov = 38
	else:
		camera.position = SHOT.camera_position
		camera.rotation_degrees = SHOT.camera_rotation_degrees
		camera.fov = SHOT.fov
	_update_label()
