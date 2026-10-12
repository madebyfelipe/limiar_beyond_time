class_name TerminalInteraction
extends ApproachPrompt
## E opens the console; the save command records position, objective and stock.

signal saved(record: Dictionary)

@export var scene_path: String
var notice: Label
var menu: TerminalMenu

func prompt_text() -> String:
	return GamepadControls.shared.interact_label() + " · Access terminal"

func _ready() -> void:
	super()
	layer = 20
	menu = TerminalMenu.new()
	menu.name = "TerminalMenu"
	add_child(menu)
	menu.save_requested.connect(save_progress)
	menu.closed.connect(func() -> void: busy = false)
	notice = label(-118, -78)
	notice.add_theme_color_override("font_color", Color("9fd9a8"))
	notice.modulate.a = 0.0

func interact() -> void:
	if not can_interact():
		return
	busy = true
	prompt.hide()
	menu.open()

func save_progress() -> void:
	if not busy or not menu.visible:
		return
	# Using the terminal is itself the Fase 1 objective, so the stage this press
	# reaches has to be in the record this press writes, not one press behind.
	# The live objective only moves once the file accepted it.
	var record: Dictionary = SaveGame.write(scene_path, player.global_position, player.visual.rotation.y, MissionState.Stage.DONE, player.vitality)
	if record.is_empty():
		announce("TERMINAL NOT RESPONDING — progress not saved")
		menu.write_line("SAVE FAILED: progress not saved. Try save again.")
		return
	MissionState.reach(MissionState.Stage.DONE)
	saved.emit(record)
	announce("PROGRESS SAVED · record %d · %s" % [record["saves"], SaveGame.stamp(record)])
	menu.write_line("PROGRESS AND SUPPLIES SAVED · RECORD %d · %s" % [record["saves"], SaveGame.stamp(record)])

## Shows a line over the prompt and lets it fade, the way a terminal would
## acknowledge and then go quiet again.
func announce(text: String) -> void:
	notice.visible = not menu.visible
	notice.text = text
	notice.modulate.a = 1.0
	var fade := create_tween()
	fade.tween_interval(1.8)
	fade.tween_property(notice, "modulate:a", 0.0, 0.7)
