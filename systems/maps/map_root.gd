@tool
class_name MapRoot
extends Node3D
## Root of an editable map in maps/. The map is plain 3D the editor can change:
##   Geometry     anything Dylan stands on or walks into. CSG with Use Collision,
##                StaticBody3D, or a MeshInstance3D carrying the `collision_size`
##                meta (the authored sources' convention) all collide.
##   Shots        MapShot cameras, posed with the editor's camera Preview.
##   Zones        MapZone boxes, each pointing at the MapShot it cuts to.
##   PlayerStart  Marker3D where Dylan appears, facing its -Z.
##   Keleken*     Marker3D: an animal wanders `keleken_radius` around each.
## F6 on a map runs it through the map runner, like executar-mapa.

const RUNNER := "res://environments/maps/map_runner.tscn"

@export var map_title: String = ""
@export var ambient_color: Color = Color("b6c5d1")
@export_range(0.0, 4.0) var ambient_energy: float = 0.65
@export var shot_light_color: Color = Color("b6c5d1")
@export_range(0.0, 4.0) var shot_light_energy: float = 0.85
## Half the side of the square each Keleken keeps to until it perceives Dylan.
@export_range(1.0, 20.0) var keleken_radius: float = 4.0

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	# Run directly (F6): hand the map to the runner, which builds the level round it.
	if get_tree().current_scene == self:
		MapRunner.pending_map = scene_file_path
		get_tree().change_scene_to_file.call_deferred(RUNNER)

func geometry() -> Node3D:
	var node: Node = get_node_or_null("Geometry")
	return node if node is Node3D else self

func shots() -> Array[MapShot]:
	var result: Array[MapShot] = []
	for node: Node in find_children("*", "MapShot", true, false):
		result.append(node)
	return result

func zones() -> Array[MapZone]:
	var result: Array[MapZone] = []
	for node: Node in find_children("*", "MapZone", true, false):
		result.append(node)
	return result

func player_start() -> Transform3D:
	var marker: Node = get_node_or_null("PlayerStart")
	return marker.global_transform if marker is Node3D else Transform3D.IDENTITY

func keleken_spawns() -> Array[Marker3D]:
	var result: Array[Marker3D] = []
	for node: Node in find_children("Keleken*", "Marker3D", true, false):
		result.append(node)
	return result

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if not has_node("PlayerStart"):
		warnings.append("Falta um Marker3D chamado PlayerStart.")
	if shots().is_empty():
		warnings.append("Nenhuma MapShot: o mapa precisa de ao menos uma câmera.")
	return warnings
