class_name PhaseGate
extends DoorInteraction
## The doorway between two phases. It travels like any other door, with the same
## approach point and the same cinematic, but it stays shut until the phase it
## leads to has been released by progress, and it says so on the prompt instead
## of silently refusing the key.

signal refused

## Phase this gate leads to, as declared in `Phase.chain()`.
@export var phase_id: StringName
## What the prompt reads while the gate is still shut.
@export var locked_hint: String = "Locked"
## What it reads once the phase is released.
@export var open_hint: String = "Open"
var _was_open: bool = false

func _ready() -> void:
	var destination: Phase = phase()
	if destination != null and target_scene == "":
		target_scene = destination.entry_scene
	_was_open = unlocked()
	super._ready()

func phase() -> Phase:
	return Phase.find(phase_id)

func unlocked() -> bool:
	var destination: Phase = phase()
	return destination == null or destination.unlocked()

func prompt_text() -> String:
	return GamepadControls.shared.interact_label() + " · " + (open_hint if unlocked() else locked_hint)

## The prompt is shown at the approach point either way: a gate the player can
## reach but not open has to read as shut, not as absent.
func _process(delta: float) -> void:
	super._process(delta)
	var open: bool = unlocked()
	if open != _was_open:
		_was_open = open
		prompt.text = prompt_text()

func interact() -> void:
	if not can_interact():
		return
	if not unlocked():
		refused.emit()
		return
	super.interact()
