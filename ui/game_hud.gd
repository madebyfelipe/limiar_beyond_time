class_name GameHud
extends RetroScreen
## Minimal gameplay HUD following the supplied Dino Crisis 2 reference.
@export var player: PlayerController
var gauge: VitalityGauge

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	build(null, false)
	gauge = VitalityGauge.new()
	gauge.position = Vector2(30, 35)
	gauge.size = Vector2(460, 70)
	gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(gauge)
	var caption := label_at("VITALITY", Rect2(292, 68, 196, 42), 34)
	var lettering := SystemFont.new()
	lettering.font_names = PackedStringArray(["Arial", "DejaVu Sans"])
	lettering.font_weight = 800
	lettering.font_italic = true
	caption.add_theme_font_override("font", lettering)
	caption.add_theme_color_override("font_color", Color.WHITE)
	caption.add_theme_color_override("font_shadow_color", Color.BLACK)
	caption.add_theme_constant_override("shadow_offset_x", 2)
	caption.add_theme_constant_override("shadow_offset_y", 2)
	refresh()

func _process(_delta: float) -> void:
	refresh()

func refresh() -> void:
	if gauge == null:
		return
	visible = not get_tree().paused and not get_tree().root.has_node("DoorTransition")
	if is_instance_valid(player):
		gauge.ratio = player.vitality / 100.0
	for interaction: Node in get_tree().get_nodes_in_group(&"approach_prompts"):
		if interaction.player == player:
			interaction.prompt.modulate.a = 0.0
