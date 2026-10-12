class_name PracticeTarget
extends Node3D
## A plywood silhouette on the firing range: one Health, one Hurtbox the size
## of the board, and it falls back when it runs out. Built in code so the range
## and the probes place as many as they need with a height and a width.

@export_range(0.2, 4.0) var height: float = 1.9
@export_range(0.1, 2.0) var width: float = 0.6
@export_range(1.0, 1000.0) var toughness: float = 100.0

var health: Health
var hurtbox: Hurtbox
var board: MeshInstance3D
var _paint: StandardMaterial3D
var _flash_left: float = 0.0

func _ready() -> void:
	health = Health.new()
	health.maximum = toughness
	add_child(health)
	_paint = StandardMaterial3D.new()
	_paint.albedo_color = Color(0.62, 0.48, 0.3)
	_paint.roughness = 0.9
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, height, 0.06)
	mesh.material = _paint
	board = MeshInstance3D.new()
	board.mesh = mesh
	board.position.y = height * 0.5
	add_child(board)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = mesh.size
	shape.shape = box
	hurtbox = Hurtbox.new()
	hurtbox.health = health
	hurtbox.position.y = height * 0.5
	hurtbox.add_child(shape)
	add_child(hurtbox)
	hurtbox.hit.connect(func(_damage: float, _point: Vector3, _direction: Vector3) -> void: _flash_left = 0.08)
	health.died.connect(_fall)

func _process(delta: float) -> void:
	if _flash_left > 0.0:
		_flash_left -= delta
	_paint.albedo_color = Color(1.0, 0.85, 0.6) if _flash_left > 0.0 else Color(0.62, 0.48, 0.3)

## Tips over backwards about its foot.
func _fall() -> void:
	create_tween().tween_property(self, "rotation:x", -PI * 0.47, 0.35).set_ease(Tween.EASE_IN)

func reset() -> void:
	rotation.x = 0.0
	health.restore()
	hurtbox.revive()
