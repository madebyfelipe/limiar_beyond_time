class_name GameHud
extends RetroScreen
## Minimal gameplay HUD following the supplied Dino Crisis 2 reference.
@export var player: PlayerController
var gauge: VitalityGauge
var supplies: Label
var death_message: Label
var damage_flash: ColorRect
var flash_left: float = 0.0

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
	supplies = label_at("", Rect2(30, 123, 690, 38), 24)
	death_message = label_at("DYLAN DIED\nEsc / Menu · Restart", Rect2(356, 360, 960, 220), 48)
	death_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	death_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	death_message.add_theme_color_override("font_color", Color("f2b0a5"))
	damage_flash = ColorRect.new()
	damage_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	damage_flash.color = Color(0.8, 0.03, 0.02, 0.0)
	damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(damage_flash)
	if is_instance_valid(player):
		player.damaged.connect(func(_amount: float) -> void: flash_left = 0.25)
	refresh()

func _process(delta: float) -> void:
	if not get_tree().paused:
		flash_left = maxf(0.0, flash_left - delta)
	damage_flash.color.a = flash_left * 0.9
	refresh()

func refresh() -> void:
	if gauge == null:
		return
	visible = not get_tree().paused and not get_tree().root.has_node("DoorTransition") and not _letterboxed()
	if is_instance_valid(player):
		gauge.ratio = player.vitality / player.health.maximum
		SupplyStock.ensure_loaded()
		var family := InputBindings.GAMEPAD if GamepadControls.shared.gamepad_active else InputBindings.KEYBOARD
		var ps := GamepadControls.shared.playstation
		supplies.text = "%s · DODGE%s    %s · MED KIT ×%d" % [InputBindings.binding_label("dodge", family, 0, ps), " (cooldown)" if player.dodge_cooldown_left > 0.0 else "", InputBindings.binding_label("use_med_kit", family, 0, ps), SupplyStock.med_kits]
		death_message.visible = player.is_dead()
	for interaction: Node in get_tree().get_nodes_in_group(&"approach_prompts"):
		if interaction.player == player:
			interaction.prompt.modulate.a = 1.0 if GamepadControls.shared.gamepad_active else 0.0

## A cutscene's letterbox is down (CinematicBars): the picture is the scene's.
func _letterboxed() -> bool:
	for bars: Node in get_tree().get_nodes_in_group(&"cinematic_bars"):
		if bars is CanvasItem and (bars as CanvasItem).is_visible_in_tree():
			return true
	return false
