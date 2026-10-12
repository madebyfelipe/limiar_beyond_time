class_name MainMenu
extends Control
## Title art, live controls and two snowfall depths remain independent assets.
const DESIGN := Vector2(1672, 941)
const BACKGROUND := preload("res://assets/ui/main_menu/snow_outpost_v02.png")
const LOGO := preload("res://assets/ui/main_menu/limiar_logo_v01.png")
const TITLE_BUTTON := preload("res://ui/title_menu_button.gd")
const GAME_SCENE := "res://environments/exterior.tscn"
const CAMERA_MARGIN := 8.0
## Amplitude in design pixels; smooth noise avoids harsh frame-to-frame jitter.
@export_range(0.0, 6.0, 0.1) var camera_shake_strength: float = 2.5
var scenery: Control
var _camera_noise := FastNoiseLite.new()
var _camera_time: float = 0.0
var canvas: Control
var menu: Control
var buttons: Array[Button] = []
var snow_layers: Array[CPUParticles2D] = []
var settings: PauseMenu
var extras: Control
var extras_buttons: Array[Button] = []
var load_button: Button
var hint: Label
var status: Label
var fade: ColorRect
var launching: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Existing command-line benchmarks still exercise the technical route.
	if OS.get_cmdline_user_args().has("--benchmark"):
		get_tree().change_scene_to_file.call_deferred("res://environments/technical_route.tscn")
		return
	var backing := ColorRect.new()
	backing.color = Color("020509")
	backing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backing)
	canvas = Control.new()
	canvas.size = DESIGN
	canvas.clip_contents = true
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(canvas)
	scenery = Control.new()
	scenery.name = "Scenery"
	scenery.size = DESIGN
	scenery.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(scenery)
	_camera_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_camera_noise.seed = 4590
	_camera_noise.frequency = 1.0
	var background := TextureRect.new()
	background.texture = BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# A small overscan keeps the edges covered throughout the camera movement.
	background.position = -Vector2.ONE * CAMERA_MARGIN
	background.size = DESIGN + Vector2.ONE * CAMERA_MARGIN * 2.0
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scenery.add_child(background)
	_build_snow(140, 23.0, 0.8, 1.5, 22.0, 46.0, Color(0.65, 0.75, 0.86, 0.32))
	_build_snow(65, 16.0, 1.3, 2.4, 48.0, 85.0, Color(0.88, 0.91, 0.95, 0.56))
	var logo := TextureRect.new()
	logo.name = "Logo"
	logo.texture = LOGO
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.position = Vector2(126, 54)
	logo.size = Vector2(966, 322)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(logo)
	menu = Control.new()
	menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.size = DESIGN
	canvas.add_child(menu)
	buttons.append(_button(menu, "NEW GAME", 410, _new_game))
	load_button = _button(menu, "LOAD GAME", 468, _load_game)
	load_button.disabled = not SaveGame.has_record()
	load_button.tooltip_text = "Resume your last terminal save." if not load_button.disabled else "No saved game. Save at the guardhouse terminal first."
	buttons.append(load_button)
	buttons.append(_button(menu, "OPTIONS", 526, _open_settings))
	buttons.append(_button(menu, "EXTRAS", 584, _open_extras))
	buttons.append(_button(menu, "QUIT", 642, func() -> void: get_tree().quit()))
	_focus_ring(buttons.filter(func(button: Button) -> bool: return not button.disabled))
	status = _label(menu, "", Rect2(193, 723, 810, 48), 19)
	if load_button.disabled:
		status.text = "No saved game"
	status.modulate.a = 0.65
	_build_extras()
	hint = _label(canvas, "", Rect2(181, 849, 1280, 50), 22)
	GamepadControls.shared.changed.connect(_refresh_hint)
	_refresh_hint()
	settings = preload("res://ui/pause_menu.tscn").instantiate()
	settings.settings_only = true
	settings.pause_on_focus_loss = false
	add_child(settings)
	settings.closed.connect(_settings_closed)
	fade = ColorRect.new()
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.color = Color.BLACK
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	create_tween().tween_property(fade, "modulate:a", 0.0, 0.75)
	resized.connect(_fit)
	_fit()
	buttons[0].grab_focus()

func _process(delta: float) -> void:
	if scenery == null:
		return
	_camera_time += delta * 1.2
	scenery.position = Vector2(
		_camera_noise.get_noise_2d(_camera_time, 0.0),
		_camera_noise.get_noise_2d(_camera_time, 100.0)
	) * camera_shake_strength

func _fit() -> void:
	if canvas == null:
		return
	var ratio: float = minf(size.x / DESIGN.x, size.y / DESIGN.y)
	canvas.scale = Vector2.ONE * ratio
	canvas.position = (size - DESIGN * ratio) * 0.5

func _build_snow(amount: int, lifetime: float, scale_min: float, scale_max: float, speed_min: float, speed_max: float, ink: Color) -> void:
	var snow := CPUParticles2D.new()
	snow.name = "SnowFar" if snow_layers.is_empty() else "SnowNear"
	snow.amount = amount
	snow.lifetime = lifetime
	snow.preprocess = lifetime
	snow.position = DESIGN * 0.5
	snow.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	snow.emission_rect_extents = DESIGN * 0.5 + Vector2(140, 120)
	snow.direction = Vector2(0.2, 1)
	snow.spread = 14
	snow.gravity = Vector2(3, 3)
	snow.initial_velocity_min = speed_min
	snow.initial_velocity_max = speed_max
	snow.scale_amount_min = scale_min
	snow.scale_amount_max = scale_max
	snow.color = ink
	var speck := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	speck.fill(Color.WHITE)
	snow.texture = ImageTexture.create_from_image(speck)
	snow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scenery.add_child(snow)
	snow_layers.append(snow)

func _button(parent: Control, text: String, y: float, action: Callable) -> Button:
	var button: Button = TITLE_BUTTON.new()
	button.text = text
	button.position = Vector2(145, y)
	button.size = Vector2(530, 54)
	parent.add_child(button)
	button.pressed.connect(action)
	return button

func _label(parent: Control, text: String, box: Rect2, point_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = box.position
	label.size = box.size
	label.add_theme_font_override("font", TITLE_BUTTON.font())
	label.add_theme_font_size_override("font_size", point_size)
	label.add_theme_color_override("font_color", Color("a8afb7"))
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _focus_ring(rows: Array[Button]) -> void:
	for index: int in range(rows.size()):
		var button: Button = rows[index]
		button.focus_neighbor_top = button.get_path_to(rows[posmod(index - 1, rows.size())])
		button.focus_neighbor_bottom = button.get_path_to(rows[(index + 1) % rows.size()])
		button.focus_previous = button.focus_neighbor_top
		button.focus_next = button.focus_neighbor_bottom

func _refresh_hint() -> void:
	hint.text = GamepadControls.shared.menu_hint()

func _open_settings() -> void:
	menu.hide()
	settings.open()
	settings._on_settings_pressed()

func _settings_closed() -> void:
	menu.show()
	buttons[2].grab_focus()

func _build_extras() -> void:
	extras = Control.new()
	extras.size = DESIGN
	extras.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(extras)
	_label(extras, "EXTRAS", Rect2(193, 396, 600, 44), 27)
	extras_buttons.append(_button(extras, "FIRING RANGE", 458, func() -> void: _launch("res://environments/firing_range.tscn")))
	extras_buttons.append(_button(extras, "TECHNICAL ROUTE", 516, func() -> void: _launch("res://environments/technical_route.tscn")))
	extras_buttons.append(_button(extras, "CREATURE STUDY", 574, func() -> void: _launch("res://environments/keleken_animation_study.tscn")))
	extras_buttons.append(_button(extras, "BACK", 654, _close_extras))
	_focus_ring(extras_buttons)
	extras.hide()

func _open_extras() -> void:
	menu.hide()
	extras.show()
	extras_buttons[0].grab_focus()

func _close_extras() -> void:
	extras.hide()
	menu.show()
	buttons[3].grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if launching or settings == null or settings.visible:
		return
	if event.is_action_pressed("ui_cancel") and extras.visible:
		_close_extras()
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START:
		if extras.visible:
			_close_extras()
		else:
			_open_settings()
		get_viewport().set_input_as_handled()

func _new_game() -> void:
	SaveGame.resume_on_scene_entry = false
	MissionState.reset()
	SupplyStock.reset()
	_launch(GAME_SCENE)

func _load_game() -> void:
	var record: Dictionary = SaveGame.read()
	if record.is_empty():
		load_button.disabled = true
		_focus_ring(buttons.filter(func(button: Button) -> bool: return not button.disabled))
		status.text = "Save unavailable"
		buttons[0].grab_focus()
		return
	SaveGame.resume_on_scene_entry = true
	_launch(String(record["scene"]))

func _launch(path: String) -> void:
	if launching:
		return
	launching = true
	get_viewport().gui_release_focus()
	for button: Button in buttons + extras_buttons:
		button.disabled = true
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, 0.45)
	await tween.finished
	get_tree().paused = false
	var result: Error = get_tree().change_scene_to_file(path)
	if result != OK:
		launching = false
		fade.modulate.a = 0
		fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for button: Button in buttons + extras_buttons:
			button.disabled = false
		load_button.disabled = not SaveGame.has_record()
		status.text = "Could not open scene"
		_close_extras()
