class_name PauseMenu
extends Control
## Esc toggles pause; losing focus pauses and regaining it does not resume.
## Processes while the tree is paused, so its buttons remain operable.

signal restart_requested

@export var resume_button: Button
@export var restart_button: Button
## Main page row that opens the gameplay page.
@export var gameplay_button: Button
@export var filter_button: Button
@export var quit_button: Button
var settings_button: Button
var settings_menu: SettingsMenu
var _return_to_settings: bool = false
## Probes that are not exercising focus loss may disable it.
@export var pause_on_focus_loss: bool = true
var skin_layer: CanvasLayer
var screen: RetroScreen
## Second page: the presentation options, one row per effect.
var filter_screen: RetroScreen
var pixel_button: RetroOption
var scaling_button: RetroOption
var effect_buttons: Dictionary = {}
## Third page: how Dylan is steered and how he aims.
var gameplay_screen: RetroScreen
var scheme_button: RetroOption
var modern_aim_button: RetroOption
var tank_aim_button: RetroOption
var pad_aim_button: RetroOption
var aim_help: Label
var input_hints: Array[Label] = []

func _ready() -> void:
	_build_skin()
	GamepadControls.shared.changed.connect(_refresh_input_hints)
	GamepadControls.shared.active_disconnected.connect(open)
	hide()
	resume_button.pressed.connect(close)
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(func() -> void: get_tree().quit())
	if gameplay_button:
		ControlScheme.ensure_loaded()
		AimSettings.ensure_loaded()
		gameplay_button.pressed.connect(_on_gameplay_pressed)
		_update_gameplay_button()
	if filter_button:
		RetroFilter.ensure_loaded()
		filter_button.pressed.connect(_on_filter_pressed)
		_update_filter_button()

## Switches between camera-relative and traditional tank steering. The choice
## is stored by ControlScheme, so it survives scene changes and sessions.
func _on_scheme_pressed(_direction: int = 1) -> void:
	ControlScheme.toggle()
	_update_gameplay_page()

## The modern scheme's four aim modes are a player's choice, not a design
## decision taken for them; AimSettings stores it beside the scheme.
func _on_modern_aim_pressed(direction: int = 1) -> void:
	AimSettings.set_modern(posmod(int(AimSettings.modern) + direction, AimSettings.MODERN_NAMES.size()) as AimSettings.Modern)
	_update_gameplay_page()

func _on_tank_aim_pressed(_direction: int = 1) -> void:
	AimSettings.set_tank_auto_target(not AimSettings.tank_auto_target)
	_update_gameplay_page()

func _on_gameplay_pressed() -> void:
	_return_to_settings = settings_menu.visible
	settings_menu.hide()
	screen.hide()
	gameplay_screen.show()
	_update_gameplay_page()
	scheme_button.grab_focus()

func _close_gameplay_page() -> void:
	gameplay_screen.hide()
	if _return_to_settings:
		settings_menu.show()
		settings_menu.hub_buttons.gameplay.grab_focus()
		_return_to_settings = false
		return
	screen.show()
	_update_gameplay_button()
	gameplay_button.grab_focus()

func _is_gameplay_page_open() -> bool:
	return gameplay_screen != null and gameplay_screen.visible

func _update_gameplay_page() -> void:
	if pad_aim_button != null:
		pad_aim_button.set_value("TARGET LOCK" if AimSettings.pad_target_lock else "RIGHT STICK")
	scheme_button.set_value(ControlScheme.label().to_upper())
	modern_aim_button.set_value(AimSettings.modern_name().to_upper())
	tank_aim_button.set_value("ON" if AimSettings.tank_auto_target else "OFF")
	if aim_help != null:
		if GamepadControls.shared.gamepad_active:
			var ps: bool = GamepadControls.shared.playstation
			aim_help.text = GamepadControls.shared.combat_hint() + "\nLeft stick / D-pad: move · %s / %s: run.\n" % [InputBindings.binding_label("run", InputBindings.GAMEPAD, 0, ps), InputBindings.binding_label("run", InputBindings.GAMEPAD, 1, ps)]
			aim_help.text += ("Right stick turns / tilts aim. " if ControlScheme.is_tank() else ("Right-stick flicks cycle targets. " if AimSettings.pad_target_lock else "Right stick aims. "))
			aim_help.text += "%s dodge · %s med kit.\nCameras stay fixed. Dodge cancels aim and reload." % [InputBindings.binding_label("dodge", InputBindings.GAMEPAD, 0, ps), InputBindings.binding_label("use_med_kit", InputBindings.GAMEPAD, 0, ps)]
			return
		var aim_key: String = InputBindings.binding_label("aim", InputBindings.KEYBOARD)
		var fire_key: String = InputBindings.binding_label("fire", InputBindings.KEYBOARD)
		var next_key: String = InputBindings.binding_label("next_target", InputBindings.KEYBOARD)
		var wheel_key: String = InputBindings.binding_label("lock_next_target", InputBindings.KEYBOARD)
		var reload_key: String = InputBindings.binding_label("reload", InputBindings.KEYBOARD)
		aim_help.text = "TARGET LOCK: point and hold %s. %s / %s cycles targets. Hold %s to fire; release aim to unlock." % [aim_key, wheel_key, next_key, fire_key] if AimSettings.modern == AimSettings.Modern.LOCKED else "%s raises the weapon. %s fires. %s reloads. Mouse aim uses camera-relative controls." % [aim_key, fire_key, reload_key]
		if ControlScheme.is_tank() and AimSettings.modern == AimSettings.Modern.LOCKED:
			aim_help.text = "For mouse TARGET LOCK, choose CAMERA controls. %s raises the weapon; %s / %s cycles targets; %s fires." % [aim_key, wheel_key, next_key, fire_key]

## Opens the presentation page. Each effect is its own switch there, so the
## look is assembled instead of picked from a list; RetroFilter stores the
## settings, so they survive scene changes and sessions.
func _on_filter_pressed() -> void:
	_return_to_settings = settings_menu.visible
	settings_menu.hide()
	screen.hide()
	filter_screen.show()
	_update_filter_page()
	pixel_button.grab_focus()

func _close_filter_page() -> void:
	filter_screen.hide()
	if _return_to_settings:
		settings_menu.show()
		settings_menu.hub_buttons.presentation.grab_focus()
		_return_to_settings = false
		return
	screen.show()
	_update_filter_button()
	filter_button.grab_focus()

func _is_filter_page_open() -> bool:
	return filter_screen != null and filter_screen.visible

func _update_filter_button() -> void:
	filter_button.text = "PRESENTATION: %s" % RetroFilter.describe().to_upper()

func _on_pixel_pressed(direction: int = 1) -> void:
	RetroFilter.set_pixel_step(self, posmod(RetroFilter.pixel_step + direction, RetroFilter.PIXEL_STEPS.size()))
	_update_filter_page()

func _on_scaling_pressed(direction: int = 1) -> void:
	RetroFilter.set_scaling(self, posmod(RetroFilter.scaling + direction, RetroFilter.SCALING.size()))
	_update_filter_page()

func _toggle_effect(id: int, _direction: int = 1) -> void:
	RetroFilter.set_effect(self, id, not RetroFilter.is_effect_on(id))
	_update_filter_page()

func _update_filter_page() -> void:
	pixel_button.set_value(RetroFilter.pixel_name().to_upper())
	scaling_button.set_value(RetroFilter.scaling_name().to_upper())
	for row: Dictionary in RetroFilter.EFFECTS:
		var id: int = int(row["id"])
		var button: RetroOption = effect_buttons[id]
		button.set_value("ON" if RetroFilter.is_effect_on(id) else "OFF")

## Names the aim that the current scheme uses, since that is the one in play.
func _update_gameplay_button() -> void:
	# Upper case to match the rest of the panel, which is set in tracked capitals.
	var aim: String = ("auto" if AimSettings.tank_auto_target else "manual") if ControlScheme.is_tank() else AimSettings.modern_name()
	gameplay_button.text = "GAMEPLAY: %s · %s" % [ControlScheme.label().to_upper(), aim.to_upper()]

func _unhandled_input(event: InputEvent) -> void:
	# Esc and Options remain recovery shortcuts even after gameplay remapping.
	var fallback: bool = (event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE) or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START)
	if (fallback or event.is_action_pressed("pause") or (visible and event.is_action_pressed("ui_cancel"))) and not event.is_echo():
		if settings_menu.visible:
			settings_menu.back()
		elif _is_filter_page_open():
			# Esc steps back one page before it gives the game back.
			_close_filter_page()
		elif _is_gameplay_page_open():
			_close_gameplay_page()
		elif visible:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()

func _on_settings_pressed() -> void:
	screen.hide()
	settings_menu.open()

func _close_settings() -> void:
	settings_menu.close()
	screen.show()
	_update_gameplay_button()
	_update_filter_button()
	settings_button.grab_focus()

func _notification(what: int) -> void:
	if (what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT) and pause_on_focus_loss and is_node_ready() and not visible and not get_tree().paused:
		open()

func open() -> void:
	if get_tree().paused and not visible:
		return
	_update_gameplay_button()
	_update_filter_button()
	get_tree().paused = true
	show()
	skin_layer.show()
	_return_to_settings = false
	settings_menu.close()
	filter_screen.hide()
	gameplay_screen.hide()
	screen.show()
	resume_button.grab_focus()

func close() -> void:
	settings_menu.close()
	hide()
	skin_layer.hide()
	get_viewport().gui_release_focus()
	get_tree().paused = false

func _on_restart_pressed() -> void:
	restart_requested.emit()
	close()

func _build_skin() -> void:
	skin_layer = CanvasLayer.new()
	skin_layer.layer = 40
	add_child(skin_layer)
	screen = RetroScreen.new()
	skin_layer.add_child(screen)
	screen.build(preload("res://assets/ui/retro_terminal/pause_menu_skin_v02.png"))
	resume_button = screen.button_at("RESUME", Rect2(424, 236, 824, 72), Callable(), 34)
	restart_button = screen.button_at("RESTART", Rect2(424, 318, 824, 72), Callable(), 34)
	gameplay_button = screen.button_at("", Rect2(424, 400, 824, 72), Callable(), 30)
	filter_button = screen.button_at("", Rect2(424, 482, 824, 72), Callable(), 30)
	settings_button = screen.button_at("SETTINGS", Rect2(424, 564, 824, 72), _on_settings_pressed, 34)
	quit_button = screen.button_at("QUIT GAME", Rect2(424, 646, 824, 72), Callable(), 34)
	# The two summary rows grow with the settings they describe; past the frame
	# they trim with an ellipsis instead of stretching the button out of the skin.
	for summary: Button in [gameplay_button, filter_button]:
		summary.clip_text = true
		summary.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	screen.focus_ring([resume_button, restart_button, gameplay_button, filter_button, settings_button, quit_button])
	_build_filter_page()
	_build_gameplay_page()
	settings_menu = SettingsMenu.new()
	skin_layer.add_child(settings_menu)
	settings_menu.back_requested.connect(_close_settings)
	settings_menu.gameplay_requested.connect(_on_gameplay_pressed)
	settings_menu.presentation_requested.connect(_on_filter_pressed)
	for page: RetroScreen in [screen, filter_screen, gameplay_screen]:
		# Cover the keyboard legend printed on the skin with the current input.
		var backing := ColorRect.new()
		backing.position = Vector2(300, 790)
		backing.size = Vector2(1072, 64)
		backing.color = Color("071318")
		backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
		page.canvas.add_child(backing)
		input_hints.append(page.label_at("", Rect2(312, 790, 1048, 64), 24))
	_refresh_input_hints()
	skin_layer.hide()

func _refresh_input_hints() -> void:
	for hint: Label in input_hints:
		hint.text = "Left / Right adjust · " + GamepadControls.shared.menu_hint()
	_update_gameplay_page()

## The presentation page, over the same skin: one stepper for how coarse the
## picture is, one for how its pixels are scaled, and one switch per effect,
## so scanlines and the tube are independent of each other.
func _build_filter_page() -> void:
	RetroFilter.ensure_loaded()
	filter_screen = RetroScreen.new()
	skin_layer.add_child(filter_screen)
	filter_screen.build(preload("res://assets/ui/retro_terminal/pause_menu_skin_v02.png"))
	filter_screen.label_at("PRESENTATION", Rect2(300, 130, 1072, 70), 34)
	# Seven rows and the way back have to end above the key hints printed at the
	# foot of the skin (y ≈ 810), so the rows are 62 tall on a 68 pitch.
	var rows: Array[Button] = []
	var y: float = 236.0
	pixel_button = filter_screen.option_at("PIXELATION", Rect2(300, y, 1072, 62), _on_pixel_pressed, 28)
	rows.append(pixel_button)
	y += 68.0
	scaling_button = filter_screen.option_at("SCALING", Rect2(300, y, 1072, 62), _on_scaling_pressed, 28)
	rows.append(scaling_button)
	for row: Dictionary in RetroFilter.EFFECTS:
		y += 68.0
		var id: int = int(row["id"])
		var button: RetroOption = filter_screen.option_at(String(row["name"]).to_upper(), Rect2(300, y, 1072, 62), func(direction: int) -> void: _toggle_effect(id, direction), 28)
		effect_buttons[id] = button
		rows.append(button)
	y += 80.0
	rows.append(filter_screen.button_at("BACK", Rect2(300, y, 1072, 62), _close_filter_page, 28))
	filter_screen.focus_ring(rows)
	_update_filter_page()
	filter_screen.hide()

## The gameplay page, over the same skin and in the presentation page's rows.
func _build_gameplay_page() -> void:
	gameplay_screen = RetroScreen.new()
	skin_layer.add_child(gameplay_screen)
	gameplay_screen.build(preload("res://assets/ui/retro_terminal/pause_menu_skin_v02.png"))
	gameplay_screen.label_at("GAMEPLAY", Rect2(300, 130, 1072, 70), 34)
	var rows: Array[Button] = []
	var y: float = 236.0
	scheme_button = gameplay_screen.option_at("CONTROLS", Rect2(300, y, 1072, 62), _on_scheme_pressed, 28)
	rows.append(scheme_button)
	y += 68.0
	modern_aim_button = gameplay_screen.option_at("MOUSE AIM", Rect2(300, y, 1072, 62), _on_modern_aim_pressed, 28)
	rows.append(modern_aim_button)
	y += 68.0
	tank_aim_button = gameplay_screen.option_at("AUTO AIM (TANK)", Rect2(300, y, 1072, 62), _on_tank_aim_pressed, 28)
	rows.append(tank_aim_button)
	y += 68.0
	pad_aim_button = gameplay_screen.option_at("GAMEPAD AIM", Rect2(300, y, 1072, 62), func(_direction: int) -> void:
		AimSettings.set_pad_target_lock(not AimSettings.pad_target_lock)
		_update_gameplay_page(), 28)
	rows.append(pad_aim_button)
	y += 80.0
	rows.append(gameplay_screen.button_at("BACK", Rect2(300, y, 1072, 62), _close_gameplay_page, 28))
	aim_help = gameplay_screen.label_at("", Rect2(300, y + 92.0, 1072, 130), 24)
	aim_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gameplay_screen.focus_ring(rows)
	_update_gameplay_page()
	gameplay_screen.hide()

func _exit_tree() -> void:
	if visible:
		get_tree().paused = false
