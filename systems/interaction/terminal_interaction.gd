class_name TerminalInteraction
extends ApproachPrompt
## The guardhouse save terminal. E records where the player stands, so the next
## session resumes in this room instead of at the door.

signal saved(record: Dictionary)

@export var scene_path: String
var notice: Label

func prompt_text() -> String:
	return "E · Salvar progresso no terminal"

func _ready() -> void:
	super()
	notice = label(-118, -78)
	notice.add_theme_color_override("font_color", Color("9fd9a8"))
	notice.modulate.a = 0.0

func interact() -> void:
	if not can_interact():
		return
	var record: Dictionary = SaveGame.write(scene_path, player.global_position, player.visual.rotation.y)
	if record.is_empty():
		announce("TERMINAL SEM RESPOSTA — progresso não salvo")
		return
	saved.emit(record)
	announce("PROGRESSO SALVO · registro %d · %s" % [record["saves"], SaveGame.stamp(record)])

## Shows a line over the prompt and lets it fade, the way a terminal would
## acknowledge and then go quiet again.
func announce(text: String) -> void:
	notice.text = text
	notice.modulate.a = 1.0
	var fade := create_tween()
	fade.tween_interval(1.8)
	fade.tween_property(notice, "modulate:a", 0.0, 0.7)
