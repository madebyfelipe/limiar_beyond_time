class_name DoorInteraction
extends ApproachPrompt
## One local doorway; E only works at its approach point, on the same floor.

@export var facing: float = 0.0
@export var target_scene: String
@export var returning_outside: bool = false
## Names this doorway for the level on the other side, which may be reachable
## through more than one of them and has to know where to put the player.
@export var entry_id: StringName = &""
## The doorway last used, read by the destination in `arrive_from_door()`.
static var arrived_from: StringName = &""

func prompt_text() -> String:
	return GamepadControls.shared.interact_label() + " · " + ("Exit" if returning_outside else "Enter")

func interact() -> void:
	if not can_interact():
		return
	var destination: PackedScene = load(target_scene) as PackedScene
	if destination == null:
		push_error("Door destination could not be loaded: " + target_scene)
		return
	busy = true
	arrived_from = entry_id
	prompt.hide()
	player.set_control_enabled(false)
	player.velocity = Vector3.ZERO
	player.desired_direction = Vector3.ZERO
	var turn := create_tween()
	turn.tween_property(player.visual, "rotation:y", player.visual.rotation.y + angle_difference(player.visual.rotation.y, facing), 0.15)
	var dylan: Node = player.visual.get_node_or_null("DylanVisual")
	if dylan:
		dylan.play_door_interaction()
	var transition := preload("res://systems/interaction/door_transition.gd").new()
	transition.name = "DoorTransition"
	get_tree().root.add_child(transition)
	transition.begin(destination, returning_outside, player)
