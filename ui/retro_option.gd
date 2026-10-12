class_name RetroOption
extends RetroButton
## A real bidirectional stepper: pointer buttons and focused keyboard/pad input.
signal stepped(direction: int)

var value_label: Label
var previous_button: Button
var next_button: Button
var value: String = ""
var _axis_directions: Dictionary = {}
const VALUE_WIDTH := 416.0
const ARROW_WIDTH := 56.0

func _ready() -> void:
	super()
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var style: StyleBox = get_theme_stylebox(state).duplicate()
		style.content_margin_right = VALUE_WIDTH
		add_theme_stylebox_override(state, style)
	clip_text = true
	pressed.connect(func() -> void: stepped.emit(1))
	previous_button = _arrow("‹", -1)
	next_button = _arrow("›", 1)
	value_label = Label.new()
	value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.add_theme_font_override("font", RetroScreen.font())
	value_label.add_theme_font_size_override("font_size", get_theme_font_size("font_size"))
	value_label.add_theme_color_override("font_color", Color("d2ffe0"))
	value_label.text = value
	value_label.clip_text = true
	add_child(value_label)
	resized.connect(_layout_value)
	focus_entered.connect(func() -> void: _axis_directions.clear())
	_layout_value()

func _arrow(caption: String, direction: int) -> Button:
	var button := Button.new()
	button.text = caption
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 30)
	button.add_theme_color_override("font_color", Color("b4ffd2"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("102c31")
	normal.set_content_margin_all(0)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color("24534a")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.mouse_entered.connect(grab_focus)
	button.pressed.connect(func() -> void: grab_focus(); stepped.emit(direction))
	add_child(button)
	return button

func _layout_value() -> void:
	if value_label == null:
		return
	previous_button.position = Vector2(size.x - VALUE_WIDTH, 6)
	next_button.position = Vector2(size.x - ARROW_WIDTH - 6, 6)
	for button: Button in [previous_button, next_button]:
		button.size = Vector2(ARROW_WIDTH - 8, size.y - 12)
	value_label.position = Vector2(size.x - VALUE_WIDTH + ARROW_WIDTH, 0)
	value_label.size = Vector2(VALUE_WIDTH - ARROW_WIDTH * 2 - 6, size.y)

func set_value(caption: String) -> void:
	value = caption
	if value_label != null:
		value_label.text = value

func _gui_input(event: InputEvent) -> void:
	if disabled:
		return
	if event is InputEventJoypadMotion:
		if event.axis != JOY_AXIS_LEFT_X:
			return
		var direction: int = int(signf(event.axis_value)) if absf(event.axis_value) > 0.5 else 0
		if direction == 0:
			_axis_directions[event.device] = 0
			return
		if direction == int(_axis_directions.get(event.device, 0)):
			accept_event()
			return
		_axis_directions[event.device] = direction
	var step: int = 0
	if event.is_action_pressed("ui_left", true, true):
		step = -1
	elif event.is_action_pressed("ui_right", true, true):
		step = 1
	if step != 0:
		stepped.emit(step)
		accept_event()
