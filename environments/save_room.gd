extends Control
## Geometry owns the camera, collision and scale. B previews the art candidate.
const SOURCE := preload("res://environments/save_room_source.tscn")
const SHOT := preload("res://resources/save_room/shot_01.tres")
const ART := "res://assets/backgrounds/env_1/save_room/art_cam01_close_v01.png"
@onready var world: Node3D = $Frame/Composition/Actors/WorldViewport/World
@onready var background: TextureRect = $Frame/Composition/Background
@onready var camera: Camera3D = $Frame/Composition/Actors/WorldViewport/World/Camera
@onready var player: PlayerController = $Frame/Composition/Actors/WorldViewport/World/Player
@onready var label: Label = $Instructions
var source: Node3D
var colliders: Node3D
var art_mode: bool = false
var overview: bool = false

func _ready() -> void:
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
	_update_label()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_B:
			set_art_mode(not art_mode)
		elif event.physical_keycode == KEY_R:
			player.reset_to_start()
		elif event.physical_keycode == KEY_C:
			set_overview(not overview)
		elif event.physical_keycode == KEY_ESCAPE:
			get_tree().quit()

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
	label.text = "SALA — %s | WASD/setas mover · B arte/geometria · C visão técnica/interior · R reiniciar · Esc sair" % ("ARTE CANDIDATA — alinhamento em revisão" if art_mode else ("GEOMETRIA · visão técnica" if overview else "GEOMETRIA · interior"))

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
