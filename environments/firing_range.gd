extends Control
## Firing range: a lit yard with silhouettes, one fixed camera and the pistol
## on loan, for trying both control schemes and the three modern aim modes
## without buying the gun at the terminal. The layout doubles as the combat
## probe's fixture, so every distance below is a check in check_combat.gd.
##
## Seen from Dylan's start, facing -Z:
##   LOW  a short board, the nearest one in sight
##   LEFT, FAR  taller boards further out
##   HIDDEN  the nearest of all, behind the cover wall: auto-aim must skip it

const TARGETS := {
	&"low": {"at": Vector3(4.0, 0.0, -3.0), "height": 0.7, "width": 0.7},
	&"left": {"at": Vector3(-3.0, 0.0, -6.0), "height": 1.9, "width": 0.6},
	# Clear of the cover wall: from the start, the sight line passes 0,6 m
	# outside its corner.
	&"far": {"at": Vector3(4.5, 0.0, -9.0), "height": 1.9, "width": 0.6},
	&"hidden": {"at": Vector3(0.0, 0.0, -4.0), "height": 1.9, "width": 0.6},
}
const START := Vector3(0.0, 0.06, 2.0)
## The wall between the start and the hidden board.
const COVER_CENTER := Vector3(0.0, 1.3, -2.5)
const COVER_SIZE := Vector3(2.4, 2.6, 0.3)

@onready var world: Node3D = $Frame/Composition/Actors/WorldViewport/World
@onready var player: PlayerController = $Frame/Composition/Actors/WorldViewport/World/Player
var camera: Camera3D
var targets: Dictionary = {}
var operation: LevelOperation

func _ready() -> void:
	$Frame/Composition/Background.hide()
	world.get_node("Capsule").hide()
	camera = world.get_node("Camera")
	camera.position = Vector3(0.0, 9.0, 9.0)
	camera.rotation = Vector3(-0.6, 0.0, 0.0)
	camera.fov = 50.0
	camera.make_current()
	player.camera = camera
	player.weapon.practice = true
	_block(Vector3(0.0, -0.1, -4.0), Vector3(16.0, 0.2, 18.0), Color(0.3, 0.32, 0.34))
	_block(COVER_CENTER, COVER_SIZE, Color(0.45, 0.4, 0.36))
	_block(Vector3(0.0, 1.5, -13.0), Vector3(16.0, 3.0, 0.3), Color(0.36, 0.34, 0.32))
	for id: StringName in TARGETS:
		var spec: Dictionary = TARGETS[id]
		var board := PracticeTarget.new()
		board.name = String(id).capitalize()
		board.height = spec["height"]
		board.width = spec["width"]
		board.position = spec["at"]
		world.add_child(board)
		targets[id] = board
	operation = LevelOperation.new()
	operation.name = "Operation"
	operation.player = player
	operation.frame = $Frame/Composition
	add_child(operation)
	operation.restart_requested.connect(restart)
	restart()
	operation.show_notice("Estande de tiro. Botão direito ou Ctrl ergue a arma; esquerdo ou Espaço dispara; R recarrega; Tab troca de alvo no modo tanque.", 6.0)

func _block(center: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = center
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	var mesh := BoxMesh.new()
	mesh.size = size
	var paint := StandardMaterial3D.new()
	paint.albedo_color = color
	paint.roughness = 1.0
	mesh.material = paint
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	body.add_child(visual)
	world.add_child(body)
	return body

## Boards stand back up and Dylan returns to the line, gun lowered and loaded.
func restart() -> void:
	for board: PracticeTarget in targets.values():
		board.reset()
	player.reset_to(Transform3D(Basis.IDENTITY, START))
	player.weapon.reset_state()
	operation.mark_safe()
