class_name RelayTerminal
extends ApproachPrompt
## The relay room's terminal. E hands the moment to the room, which plays the
## console and what follows it; once the power is gone the terminal is dead
## and stops offering anything.

signal used

var powered: bool = true

func prompt_text() -> String:
	return GamepadControls.shared.interact_label() + " · Access relay terminal"

func can_interact() -> bool:
	return powered and super.can_interact()

func interact() -> void:
	if not can_interact():
		return
	busy = true
	prompt.hide()
	used.emit()
