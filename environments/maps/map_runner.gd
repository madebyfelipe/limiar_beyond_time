class_name MapRunner
extends Control
## Plays any editable map from maps/: the level the authored scripts assemble
## in code, assembled here from what the map scene holds instead. Which map:
##   -- --map=res://maps/name.tscn   on the command line (executar-mapa), or
##   F6 on the map itself            (MapRoot hands itself over), or
##   `map_path` set on this node.

const DEFAULT_MAP := "res://maps/exemplo.tscn"

## Set by MapRoot just before it changes to this scene.
static var pending_map: String = ""

@export_file("*.tscn") var map_path: String = ""
@onready var world: Node3D = $Frame/Composition/Actors/WorldViewport/World
@onready var background: TextureRect = $Frame/Composition/Background
@onready var player: PlayerController = $Frame/Composition/Actors/WorldViewport/World/Player
@onready var instructions: Label = $Instructions
var map: MapRoot
var shots: Array[ShotRig] = []
var director: CameraDirector
var presentation: MapPresentation
var art_available: bool = false
var operation: LevelOperation
var keleken_wanders: Array[KelekenWander] = []

func _ready() -> void:
	instructions.visible = OS.get_cmdline_args().has("--debug-instructions")
	world.get_node("Capsule").hide()
	world.get_node("Light").hide()
	background.hide()
	var path: String = _chosen_map()
	var scene: PackedScene = load(path) as PackedScene
	map = scene.instantiate() as MapRoot if scene else null
	if map == null:
		push_error("Mapa inválido ou sem MapRoot na raiz: %s" % path)
		get_tree().quit(1)
		return
	world.add_child(map)
	var environment_node: WorldEnvironment = world.get_node("Environment")
	environment_node.environment = environment_node.environment.duplicate()
	environment_node.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment_node.environment.ambient_light_color = map.ambient_color
	environment_node.environment.ambient_light_energy = map.ambient_energy
	_add_meta_colliders()
	var map_shots: Array[MapShot] = map.shots()
	if map_shots.is_empty():
		push_error("O mapa %s não tem nenhuma MapShot." % path)
		get_tree().quit(1)
		return
	var rigs := {}
	for map_shot: MapShot in map_shots:
		var definition: ShotDefinition = map_shot.to_definition()
		art_available = art_available or definition.background != null
		var rig := ShotRig.new()
		rig.name = "Rig_%s" % map_shot.name
		rig.definition = definition
		rig.camera = Camera3D.new()
		rig.add_child(rig.camera)
		rig.light = DirectionalLight3D.new()
		rig.light.rotation_degrees = Vector3(-60, -25, 0)
		rig.light.light_color = map.shot_light_color
		rig.light.light_energy = map.shot_light_energy
		rig.add_child(rig.light)
		world.add_child(rig)
		shots.append(rig)
		rigs[map_shot] = rig
	var zones: Array[CameraZone] = []
	for zone: MapZone in map.zones():
		if zone.camera == null or not rigs.has(zone.camera):
			push_warning("MapZone %s sem câmera válida; ignorada." % zone.get_path())
			continue
		zone.shot = rigs[zone.camera]
		zone.collision_layer = 0
		zone.collision_mask = 1
		zones.append(zone)
	presentation = MapPresentation.new()
	presentation.background = background
	presentation.player = player
	presentation.shots = shots
	for node: Node in map.geometry().find_children("*", "GeometryInstance3D", true, false):
		presentation.geometry.append(node)
	world.add_child(presentation)
	player.global_transform = map.player_start()
	player.spawn_transform = player.global_transform
	director = CameraDirector.new()
	director.player = player
	director.zones = zones
	director.initial_shot = _shot_at_start(zones)
	director.presentation = presentation
	director.process_physics_priority = 10
	director.shot_changed.connect(func(_previous: StringName, _current: StringName) -> void: _update_label())
	world.add_child(director)
	set_art_mode(art_available)
	operation = LevelOperation.new()
	operation.name = "Operation"
	operation.player = player
	operation.director = director
	operation.frame = $Frame/Composition
	operation.restart_requested.connect(restart)
	add_child(operation)
	_spawn_kelekens()
	_update_label()

func _chosen_map() -> String:
	for option: String in OS.get_cmdline_user_args():
		if option.begins_with("--map="):
			return option.trim_prefix("--map=")
	if pending_map != "":
		return pending_map
	return map_path if map_path != "" else DEFAULT_MAP

## The authored sources mark solid meshes with `collision_size` (a box) or
## `collision_points` (a convex wedge) instead of carrying bodies; the levels
## build them at load, and so does the runner.
func _add_meta_colliders() -> void:
	for node: Node in map.geometry().find_children("*", "MeshInstance3D", true, false):
		var shape: Shape3D
		if node.has_meta("collision_size"):
			var box := BoxShape3D.new()
			box.size = node.get_meta("collision_size")
			shape = box
		elif node.has_meta("collision_points"):
			var wedge := ConvexPolygonShape3D.new()
			wedge.points = node.get_meta("collision_points")
			shape = wedge
		else:
			continue
		var body := StaticBody3D.new()
		body.name = "%sBody" % node.name
		var collision := CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
		node.add_child(body)
		body.global_transform = node.global_transform

## The physics zones have not been sampled yet on the first frame, so the first
## framing is the one whose box contains the start point, by geometry.
func _shot_at_start(zones: Array[CameraZone]) -> ShotRig:
	var best: ShotRig = shots[0]
	var highest: int = -2147483648
	var probe: Vector3 = player.global_position + Vector3(0, 0.9, 0)
	for zone: CameraZone in zones:
		for child: Node in zone.get_children():
			if child is CollisionShape3D and child.shape is BoxShape3D:
				var local: Vector3 = child.global_transform.affine_inverse() * probe
				var half: Vector3 = child.shape.size * 0.5
				if absf(local.x) <= half.x and absf(local.y) <= half.y and absf(local.z) <= half.z and zone.shot_priority > highest:
					highest = zone.shot_priority
					best = zone.shot
	return best

func _spawn_kelekens() -> void:
	var radius: float = map.keleken_radius
	for marker: Marker3D in map.keleken_spawns():
		var animal: KelekenActor = preload("res://actors/keleken/keleken.tscn").instantiate()
		animal.name = String(marker.name)
		animal.combat_enabled = true
		animal.player = player
		world.add_child(animal)
		var home: Vector3 = marker.global_position
		var wander: KelekenWander = preload("res://actors/keleken/keleken_wander.gd").new()
		wander.home_position = home
		wander.bounds = Rect2(home.x - radius, home.z - radius, radius * 2.0, radius * 2.0)
		animal.add_child(wander)
		keleken_wanders.append(wander)

func restart() -> void:
	player.reset_to_start()
	for wander: KelekenWander in keleken_wanders:
		wander.reset()
	director.reset_to(director.initial_shot)
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
	if presentation == null:
		return
	var title: String = map.map_title if map.map_title != "" else String(map.name)
	var shot_name: String = String(presentation.current_shot.definition.shot_id) if presentation.current_shot else ""
	var movement: String = "arrows turn and move" if ControlScheme.is_tank() else "WASD/arrows move"
	instructions.text = "%s · %s · %s\n%s · Shift run · Q dodge · F4 filter · T controls (%s) · F3 diagnostics · R restart · Esc pause · %d animals" % [title.to_upper(), shot_name, "ART (B)" if presentation.art_mode else "3D GEOMETRY", movement, ControlScheme.label(), keleken_wanders.size()]
