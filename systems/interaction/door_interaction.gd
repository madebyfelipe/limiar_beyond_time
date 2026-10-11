class_name DoorInteraction
extends CanvasLayer
## One local doorway; E only works at its approach point, on the same floor.

@export var player: PlayerController
@export var approach: Vector3
@export var facing: float = 0.0
@export var target_scene: String
@export var returning_outside: bool = false
@export var radius: float = 0.85
var prompt: Label
var busy: bool = false

func _ready() -> void:
	layer = 5
	prompt = Label.new()
	prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	prompt.offset_top = -78
	prompt.offset_bottom = -30
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 24)
	prompt.add_theme_color_override("font_shadow_color", Color.BLACK)
	prompt.add_theme_constant_override("shadow_offset_x", 2)
	prompt.add_theme_constant_override("shadow_offset_y", 2)
	prompt.text = "E · Abrir porta e " + ("sair" if returning_outside else "entrar")
	prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(prompt)
	prompt.hide()

func can_interact() -> bool:
	if busy or not player.control_enabled or get_tree().paused or get_tree().root.has_node("DoorTransition"):
		return false
	var offset: Vector3 = player.global_position - approach
	return absf(offset.y) < 0.25 and Vector2(offset.x, offset.z).length() <= radius

func _process(_delta: float) -> void:
	prompt.visible = can_interact()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_echo() and can_interact():
		get_viewport().set_input_as_handled()
		interact()

func interact() -> void:
	if not can_interact():
		return
	var destination: PackedScene = load(target_scene) as PackedScene
	if destination == null:
		push_error("Door destination could not be loaded: " + target_scene)
		return
	busy = true
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
