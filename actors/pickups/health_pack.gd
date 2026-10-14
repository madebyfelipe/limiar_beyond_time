class_name HealthPack
extends Node3D
## A floating first-aid pack: walking into it restores some vitality on the
## spot and uses it up for good. It differs from the med kit, which is bought,
## carried in the case and used with a button. A pack is left where it is while
## Dylan has nothing to heal.
##
## The node sits on the floor point; the case hovers and turns above it.

signal collected(id: StringName)

## Name of this pack in PickupStore; unique in the game.
@export var pack_id: StringName
@export var player: PlayerController
@export var healing: float = 25.0
## Horizontal distance from the floor point at which Dylan picks it up.
@export var reach: float = 0.7
const HOVER := 0.95
const BOB := 0.07
const BOB_PERIOD := 2.0
const SPIN := 1.8
var body: Node3D
var _time: float = 0.0
var _inside: bool = false

func _ready() -> void:
	add_to_group(&"health_packs")
	body = Node3D.new()
	body.name = "Body"
	body.position.y = HOVER
	add_child(body)
	var green := StandardMaterial3D.new()
	green.albedo_color = Color("2f9d5c")
	green.emission_enabled = true
	green.emission = Color("1f7a45")
	green.emission_energy_multiplier = 0.9
	var white := StandardMaterial3D.new()
	white.albedo_color = Color("f1f6ee")
	white.emission_enabled = true
	white.emission = Color("e8f4e4")
	white.emission_energy_multiplier = 1.1
	# A hard case with a cross on both faces: large flat shapes, so it still
	# reads as a first-aid pack through the low-resolution filter.
	for part: Array in [
		[Vector3(0.46, 0.34, 0.2), Vector3.ZERO, green],
		[Vector3(0.26, 0.08, 0.22), Vector3.ZERO, white],
		[Vector3(0.08, 0.26, 0.22), Vector3.ZERO, white],
		[Vector3(0.16, 0.04, 0.06), Vector3(0, 0.19, 0), white],
	]:
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = part[0]
		mesh.mesh = box
		mesh.position = part[1]
		mesh.material_override = part[2]
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		body.add_child(mesh)
	# A soft shell of light around the case: what the eye catches first on a
	# dark plate, before the shape is legible.
	var halo := MeshInstance3D.new()
	halo.name = "Halo"
	var shell := SphereMesh.new()
	shell.radius = 0.42
	shell.height = 0.84
	shell.radial_segments = 12
	shell.rings = 6
	halo.mesh = shell
	var haze := StandardMaterial3D.new()
	haze.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	haze.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	haze.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	haze.albedo_color = Color(0.35, 1.0, 0.6, 0.16)
	halo.material_override = haze
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(halo)
	var glow := OmniLight3D.new()
	glow.name = "Glow"
	glow.light_color = Color("7dffb0")
	glow.light_energy = 0.7
	glow.omni_range = 2.4
	glow.shadow_enabled = false
	body.add_child(glow)
	_refresh()

func _process(delta: float) -> void:
	_time += delta
	body.position.y = HOVER + BOB * sin(TAU * _time / BOB_PERIOD)
	body.rotation.y = fposmod(SPIN * _time, TAU)

func _physics_process(_delta: float) -> void:
	_refresh()
	if not visible or not is_instance_valid(player):
		return
	var offset: Vector3 = player.global_position - global_position
	var near: bool = absf(offset.y) < 1.0 and Vector2(offset.x, offset.z).length() <= reach
	if near and player.control_enabled and not player.is_dead() and not get_tree().root.has_node("DoorTransition"):
		var before: float = player.vitality
		if player.health.heal(healing):
			PickupStore.collect(pack_id)
			player.combat_message.emit("Health pack · +%d vitality" % int(player.vitality - before))
			collected.emit(pack_id)
			_refresh()
		elif not _inside:
			# Said once per visit, not every frame he stands in it.
			player.combat_message.emit("Vitality is already full.")
	_inside = near

## Taken packs stay in the level, hidden: a restart can put one back.
func _refresh() -> void:
	visible = not PickupStore.is_collected(pack_id)
