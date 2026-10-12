class_name ApproachPrompt
extends CanvasLayer
## One local interaction: E only works at its approach point, on the same floor,
## and the on-screen prompt is visible exactly while the key would do something.
## Doors and the save terminal share this so there is one definition of "near".

@export var player: PlayerController
@export var approach: Vector3
@export var radius: float = 0.85
var prompt: Label
var busy: bool = false

func _ready() -> void:
	layer = 5
	prompt = label(-78, -30)
	prompt.text = prompt_text()
	prompt.hide()

## Overridden by each interaction to name what E does there.
func prompt_text() -> String:
	return "E"

## A bottom-anchored line in the shared prompt style.
func label(top: float, bottom: float) -> Label:
	var result := Label.new()
	result.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	result.offset_top = top
	result.offset_bottom = bottom
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.add_theme_font_size_override("font_size", 24)
	result.add_theme_color_override("font_shadow_color", Color.BLACK)
	result.add_theme_constant_override("shadow_offset_x", 2)
	result.add_theme_constant_override("shadow_offset_y", 2)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(result)
	return result

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
	pass
