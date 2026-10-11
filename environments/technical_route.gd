extends Control
## Local level assembly. Runtime reuses the authored spatial source, while
## presentation remains TextureRect + transparent 3D actors/depth occluders.
## T08 operation: restart, recovery below the level and objective feedback.

signal restarted
signal recovered(checkpoint: Vector3)

const OBJECTIVES: PackedStringArray = [
	"Contorne o caixote, suba a rampa e alcance a marca dourada.",
	"Marca dourada alcançada. Volte à marca azul inicial.",
	"Percurso concluído. Esc → Reiniciar percurso para repetir.",
]

@export var geometry: PackedScene
@export var definitions: Array[ShotDefinition]
@export var world: Node3D
@export var background: TextureRect
@export var player: PlayerController
@export var zone_centers: Array[Vector3]
@export var zone_sizes: Array[Vector3]
@export var progress: RouteProgress
@export var pause_menu: PauseMenu
@export var diagnostics: DiagnosticsOverlay
@export var instructions: Label
@export var notice: Label
## Feet below this height mean the actor left the level geometry.
@export_range(-50.0, 0.0) var recovery_height: float = -4.0
var director: CameraDirector
var presentation: PresentationController
var shots: Array[ShotRig] = []
var colliders: Node3D
var endpoint: Marker3D
var notice_timer: Timer

func _ready() -> void:
	var source: Node3D = geometry.instantiate()
	source.name = "AuthoredGeometry"
	source.visible = false
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
			var wedge := ConvexPolygonShape3D.new()
			wedge.points = mesh.get_meta("collision_points")
			shape = wedge
		else:
			continue
		var body := StaticBody3D.new()
		body.name = mesh.name
		body.transform = mesh.transform
		var collision := CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
		colliders.add_child(body)
	for definition: ShotDefinition in definitions:
		var rig := ShotRig.new()
		rig.name = String(definition.shot_id)
		rig.definition = definition
		rig.camera = Camera3D.new()
		rig.camera.name = "Camera"
		rig.add_child(rig.camera)
		rig.light = DirectionalLight3D.new()
		rig.light.rotation = Vector3(-0.7,-0.5,0)
		rig.light.light_energy = 1.2
		rig.add_child(rig.light)
		var material := ShaderMaterial.new()
		material.shader = preload("res://systems/camera/background_occluder.gdshader")
		material.set_shader_parameter("background",definition.background)
		for original: MeshInstance3D in source.get_children():
			var occluder := MeshInstance3D.new()
			occluder.name = original.name
			occluder.mesh = original.mesh
			occluder.transform = original.transform
			occluder.material_override = material
			occluder.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			rig.add_child(occluder)
			rig.occluders.append(occluder)
		world.add_child(rig)
		shots.append(rig)
	presentation = PresentationController.new()
	presentation.name = "Presentation"
	presentation.background = background
	presentation.player = player
	presentation.shots = shots
	world.add_child(presentation)
	var zones: Array[CameraZone] = []
	for index: int in range(shots.size()):
		var zone := CameraZone.new()
		zone.name = "Zone%d" % (index+1)
		zone.position = zone_centers[index]
		zone.shot = shots[index]
		zone.shot_priority = index
		zone.collision_layer = 0
		zone.collision_mask = 1
		var shape := BoxShape3D.new()
		shape.size = zone_sizes[index]
		var collision := CollisionShape3D.new()
		collision.shape = shape
		zone.add_child(collision)
		world.add_child(zone)
		zones.append(zone)
	director = CameraDirector.new()
	director.name = "Director"
	director.player = player
	director.zones = zones
	director.initial_shot = shots[0]
	director.presentation = presentation
	director.process_physics_priority = 10
	world.add_child(director)
	endpoint = Marker3D.new()
	endpoint.name = "Endpoint"
	endpoint.position = progress.end_pad
	world.add_child(endpoint)
	progress.endpoint_reached.connect(_on_endpoint_reached)
	progress.route_completed.connect(_on_route_completed)
	pause_menu.restart_requested.connect(restart)
	diagnostics.player = player
	diagnostics.director = director
	diagnostics.progress = progress
	# Pausable: a notice does not expire behind the pause menu.
	notice_timer = Timer.new()
	notice_timer.name = "NoticeTimer"
	notice_timer.one_shot = true
	notice_timer.timeout.connect(notice.hide)
	add_child(notice_timer)
	_update_objective()

func _physics_process(_delta: float) -> void:
	if player.global_position.y < recovery_height:
		recover()

## Restores actor, presentation, movement reference and objective.
func restart() -> void:
	player.reset_to_start()
	director.reset_to(director.initial_shot)
	progress.reset()
	_hide_notice()
	_update_objective()
	restarted.emit()

## Safety net for falls through the level: last pad reached, same attempt.
func recover() -> void:
	var pad: Vector3 = progress.checkpoint()
	player.reset_to(Transform3D(Basis.IDENTITY, pad + Vector3(0,0.06,0)))
	director.reset_to(shot_for(pad))
	_show_notice("Recuperação: personagem devolvido à última marca alcançada.", 3.0)
	recovered.emit(pad)

## Same rule as the director: highest-priority zone containing the actor.
func shot_for(feet: Vector3) -> ShotRig:
	var selected: ShotRig = director.current_shot
	var highest: int = -2147483648
	for index: int in range(director.zones.size()):
		var zone: CameraZone = director.zones[index]
		var bounds := AABB(zone.position-zone_sizes[index]*0.5,zone_sizes[index])
		if bounds.has_point(feet+Vector3(0,0.9,0)) and zone.shot_priority > highest:
			highest = zone.shot_priority
			selected = zone.shot
	return selected

static func format_time(seconds: float) -> String:
	return ("%d:%04.1f" % [int(seconds/60.0),fmod(seconds,60.0)]).replace(".",",")

func _on_endpoint_reached() -> void:
	_update_objective()
	_show_notice("Marca dourada alcançada. Volte à marca azul.", 3.0)

func _on_route_completed(elapsed: float) -> void:
	_update_objective()
	_show_notice("PERCURSO TÉCNICO CONCLUÍDO · %s\nEsc → Reiniciar percurso para repetir" % format_time(elapsed))

func _update_objective() -> void:
	instructions.text = "LIMIAR / percurso técnico\n%s\nWASD / setas: mover   ·   Shift: correr   ·   Esc: pausa   ·   F3: diagnóstico" % OBJECTIVES[progress.stage]

## Seconds ≤ 0 keep the notice until restart.
func _show_notice(text: String, seconds: float = 0.0) -> void:
	notice.text = text
	notice.show()
	if seconds > 0.0:
		notice_timer.start(seconds)
	else:
		notice_timer.stop()

func _hide_notice() -> void:
	notice_timer.stop()
	notice.hide()
