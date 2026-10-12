class_name RetroScreen
extends Control
## Fixed design coordinates shared by the generated skins and live controls.
## Uniform fitting keeps artwork, hit targets and text aligned at 4:3/16:9.
const DESIGN := Vector2(1672, 941)
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
	canvas.size = DESIGN
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(canvas)
	backdrop = TextureRect.new()
	backdrop.texture = texture
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.size = DESIGN
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(backdrop)
	resized.connect(fit)
	fit()

func fit() -> void:
	if canvas == null:
		return
	var ratio: float = minf(size.x / DESIGN.x, size.y / DESIGN.y)
	canvas.scale = Vector2.ONE * ratio
	canvas.position = (size - DESIGN * ratio) * 0.5

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
