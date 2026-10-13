class_name RetroScreen
extends Control
## Fixed design coordinates shared by the generated skins and live controls.
## Uniform fitting keeps artwork, hit targets and text aligned at 4:3/16:9.
const DESIGN := Vector2(1672, 941)
const MENU_SKIN := preload("res://assets/ui/retro_terminal/pause_menu_skin_v03.png")
var design_size: Vector2 = DESIGN
var canvas: Control
var backdrop: TextureRect
static var mono: Font

static func font() -> Font:
	if mono == null:
		var system := SystemFont.new()
		system.font_names = PackedStringArray(["Consolas", "Liberation Mono", "monospace"])
		var tracked := FontVariation.new()
		tracked.base_font = system
		tracked.spacing_glyph = 2
		mono = tracked
	return mono

func build(texture: Texture2D, opaque: bool = true) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP if opaque else Control.MOUSE_FILTER_IGNORE
	if opaque:
		var dim := ColorRect.new()
		dim.color = Color("020a0d")
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(dim)
	canvas = Control.new()
	canvas.size = design_size
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(canvas)
	backdrop = TextureRect.new()
	backdrop.texture = texture
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.size = design_size
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(backdrop)
	resized.connect(fit)
	fit()

## The skin has empty textured bands; runtime text never needs a cover patch.
func heading(title: String, subtitle: String = "") -> void:
	var caption := label_at(title, Rect2(300, 82, 1072, 60), 36)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var description := label_at(subtitle, Rect2(300, 170, 1072, 54), 20)
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func footer() -> Label:
	var hint := label_at("", Rect2(280, 814, 1112, 46), 19)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return hint

func fit() -> void:
	if canvas == null:
		return
	var ratio: float = minf(size.x / design_size.x, size.y / design_size.y)
	canvas.scale = Vector2.ONE * ratio
	canvas.position = (size - design_size * ratio) * 0.5

func label_at(text: String, box: Rect2, point_size: int = 30) -> Label:
	var result := Label.new()
	result.text = text
	result.position = box.position
	result.size = box.size
	result.add_theme_font_override("font", font())
	result.add_theme_font_size_override("font_size", point_size)
	result.add_theme_color_override("font_color", Color("b3e8db"))
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(result)
	return result

func button_at(text: String, box: Rect2, action: Callable, point_size: int = 38) -> Button:
	var result := RetroButton.new()
	result.text = text
	result.position = box.position
	result.size = box.size
	result.add_theme_font_size_override("font_size", point_size)
	canvas.add_child(result)
	if action.is_valid():
		result.pressed.connect(action)
	return result

func focus_ring(buttons: Array[Button]) -> void:
	for index: int in range(buttons.size()):
		var before: Button = buttons[posmod(index - 1, buttons.size())]
		var after: Button = buttons[(index + 1) % buttons.size()]
		buttons[index].focus_neighbor_top = buttons[index].get_path_to(before)
		buttons[index].focus_neighbor_bottom = buttons[index].get_path_to(after)
		buttons[index].focus_previous = buttons[index].get_path_to(before)
		buttons[index].focus_next = buttons[index].get_path_to(after)

func option_at(title: String, box: Rect2, change: Callable, point_size: int = 28) -> RetroOption:
	var result := RetroOption.new()
	result.text = title
	result.position = box.position
	result.size = box.size
	result.add_theme_font_size_override("font_size", point_size)
	canvas.add_child(result)
	result.stepped.connect(change)
	return result
