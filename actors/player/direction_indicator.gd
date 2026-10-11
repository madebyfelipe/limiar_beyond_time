extends MeshInstance3D

@export var player: PlayerController
var lines: ImmediateMesh = ImmediateMesh.new()
var line_material: StandardMaterial3D = StandardMaterial3D.new()

func _ready() -> void:
	mesh = lines
	line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line_material.albedo_color = Color(1, 0.9, 0.15)
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _physics_process(_delta: float) -> void:
	lines.clear_surfaces()
	var direction: Vector3 = player.desired_direction
	if direction.is_zero_approx():
		return
	var start: Vector3 = Vector3(0, 0.06, 0)
	var tip: Vector3 = start + direction * 1.2
	var perpendicular: Vector3 = Vector3(-direction.z, 0, direction.x) * 0.18
	lines.surface_begin(Mesh.PRIMITIVE_LINES, line_material)
	for point: Vector3 in [start,tip,tip,tip-direction*0.3+perpendicular,tip,tip-direction*0.3-perpendicular]:
		lines.surface_add_vertex(point)
	lines.surface_end()
