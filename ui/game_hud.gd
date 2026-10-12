class_name GameHud
extends RetroScreen
## Generated blank HUD skin, fed by the exploration and terminal stock state.
const SKIN := preload("res://assets/ui/retro_terminal/hud_overlay_skin_v02.png")
const OBJECTIVE_LABELS := {
	MissionState.Stage.ROAD: "SIGA A ESTRADA",
	MissionState.Stage.YARD: "ENTRE NA GUARITA",
	MissionState.Stage.TERMINAL: "USE O TERMINAL",
	MissionState.Stage.DONE: "PROGRESSO SALVO",
}
@export var player: PlayerController
var objective_provider: Callable
var status: Label
var supplies: Label
var objective_label: Label
var hint: Label
var hint_frame: TextureRect

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	build(null, false)
	SupplyStock.ensure_loaded()
	# Separate regions let the prompt disappear without leaving an empty box.
	for box: Rect2 in [Rect2(36, 45, 415, 150), Rect2(1252, 45, 383, 150), Rect2(36, 760, 419, 139), Rect2(697, 823, 286, 78)]:
		var atlas := AtlasTexture.new()
		atlas.atlas = SKIN
		atlas.region = box
		var panel := TextureRect.new()
		panel.texture = atlas
		panel.position = box.position
		panel.size = box.size
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(panel)
		hint_frame = panel
	status = label_at("", Rect2(72, 66, 343, 119), 34)
	supplies = label_at("", Rect2(1280, 67, 325, 119), 33)
	objective_label = label_at("", Rect2(68, 780, 350, 98), 32)
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint = label_at("", Rect2(715, 839, 250, 46), 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	refresh()

func _process(_delta: float) -> void:
	refresh()

func refresh() -> void:
	if status == null:
		return
	visible = not get_tree().paused and not get_tree().root.has_node("DoorTransition")
	if not visible:
		return
	status.text = "DYLAN\nCRÉDITOS %d\nKITS %d" % [SupplyStock.credits, SupplyStock.med_kits]
	supplies.text = "ESTOQUE\nMUNIÇÃO %d\nPISTOLA: %s" % [SupplyStock.ammo, "SIM" if SupplyStock.weapon else "NÃO"]
	objective_label.text = "OBJETIVO\n" + (String(objective_provider.call()) if objective_provider.is_valid() else String(OBJECTIVE_LABELS[MissionState.stage]))
	hint.text = ""
	for interaction: Node in get_tree().get_nodes_in_group(&"approach_prompts"):
		if interaction.player == player:
			interaction.prompt.modulate.a = 0.0
		if interaction.player == player and interaction.can_interact():
			hint.text = "[E] TERMINAL" if interaction is TerminalInteraction else "[E] PORTA"
			break
	hint.visible = not hint.text.is_empty()
	hint_frame.visible = hint.visible
