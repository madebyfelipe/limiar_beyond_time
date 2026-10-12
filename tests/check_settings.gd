extends SceneTree
## Live settings navigation, pointer/keyboard/pad steppers, binding capture and
## persisted preferences. Uses its own cfg and never touches the player's file.
var failures: int = 0
var fixture: Node
var menu: PauseMenu
var settings: SettingsMenu
var probe_path: String
const TEST_DEVICE := 15

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func tick(count: int = 1) -> void:
	for i: int in range(count):
		await physics_frame
		await process_frame

func key(code: Key, pressed: bool = true, ctrl: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	event.ctrl_pressed = ctrl
	Input.parse_input_event(event)

func tap(code: Key) -> void:
	key(code)
	await tick(2)
	key(code, false)
	await tick(2)

func pad_button(code: JoyButton, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = TEST_DEVICE
	event.button_index = code
	event.pressed = pressed
	Input.parse_input_event(event)

func pad_tap(code: JoyButton) -> void:
	pad_button(code, true)
	await tick(2)
	pad_button(code, false)
	await tick(2)

func axis(code: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = TEST_DEVICE
	event.axis = code
	event.axis_value = value
	Input.parse_input_event(event)

func click(control: Control) -> void:
	var at: Vector2 = control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = at
	root.push_input(motion, true)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = at
		event.global_position = at
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		root.push_input(event, true)
		await tick(2)

func capture(name: String) -> void:
	if DisplayServer.get_name() != "headless":
		await tick(4)
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png("res://.local/settings-%s.png" % name) == OK, "Screenshot failed")

func restore_button(kind: String) -> Button:
	for child: Node in settings.pages[kind].canvas.get_children():
		if child is Button and child.text == "RESTORE DEFAULTS":
			return child
	return null

func isolate_pad() -> void:
	for action: StringName in InputMap.get_actions():
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				InputMap.action_erase_event(action, event)
				event.device = TEST_DEVICE
				InputMap.action_add_event(action, event)

func run() -> void:
	create_timer(120, true).timeout.connect(func() -> void: quit(124))
	probe_path = "res://.local/settings-probe-%d.cfg" % Time.get_ticks_usec()
	var player_settings_before: String = FileAccess.get_file_as_string("user://settings.cfg") if FileAccess.file_exists("user://settings.cfg") else "<none>"
	# Seed an unrelated section and verify that later writes preserve it.
	var config := ConfigFile.new()
	config.set_value("unrelated", "marker", "preserved")
	config.save(probe_path)
	GeneralSettings.settings_path = probe_path
	GeneralSettings._loaded = false
	GeneralSettings.ensure_loaded()
	InputBindings.settings_path = probe_path
	InputBindings._loaded = false
	InputBindings.ensure_loaded()
	# Restrict this process to simulated pad input, despite a physical PS4.
	isolate_pad()
	fixture = load("res://environments/firing_range.tscn").instantiate()
	root.add_child(fixture)
	await tick(12)
	menu = fixture.operation.pause_menu
	settings = menu.settings_menu
	menu.open()
	# Legacy gameplay and filter selectors now have genuinely bidirectional input.
	menu.gameplay_button.pressed.emit()
	menu.modern_aim_button.grab_focus()
	var before: int = int(AimSettings.modern)
	await tap(KEY_RIGHT)
	check(int(AimSettings.modern) == posmod(before + 1, 4), "Keyboard right did not advance aim setting")
	await tap(KEY_LEFT)
	check(int(AimSettings.modern) == before, "Keyboard left did not reverse aim setting")
	await click(menu.modern_aim_button.previous_button)
	check(int(AimSettings.modern) == posmod(before - 1, 4), "Left arrow was not clickable")
	await click(menu.modern_aim_button.next_button)
	check(int(AimSettings.modern) == before, "Right arrow was not clickable")
	await pad_tap(JOY_BUTTON_DPAD_LEFT)
	check(int(AimSettings.modern) == posmod(before - 1, 4), "D-pad did not reverse setting")
	axis(JOY_AXIS_LEFT_X, 0.8)
	await tick(2)
	check(int(AimSettings.modern) == before, "Analog right did not adjust option")
	axis(JOY_AXIS_LEFT_X, 0.9)
	await tick(2)
	check(int(AimSettings.modern) == before, "Axis fluctuations repeatedly adjusted option")
	axis(JOY_AXIS_LEFT_X, 0.0)
	await tick(2)
	menu._close_gameplay_page()
	menu.filter_button.pressed.emit()
	before = RetroFilter.pixel_step
	await tap(KEY_LEFT)
	check(RetroFilter.pixel_step == posmod(before - 1, 4), "Filter selector did not decrement")
	await tap(KEY_RIGHT)
	check(RetroFilter.pixel_step == before, "Filter selector did not increment")
	menu._close_filter_page()
	menu.settings_button.pressed.emit()
	check(settings.visible and settings.current_page == "hub" and paused, "Settings hub did not open paused")
	await capture("hub")
	# Gameplay opened from settings must return to that hub, then to pause.
	settings.hub_buttons.gameplay.pressed.emit()
	check(menu.gameplay_screen.visible and not settings.visible, "Settings did not open gameplay")
	await tap(KEY_ESCAPE)
	check(settings.visible and settings.current_page == "hub" and paused, "Gameplay back lost settings context")
	settings.hub_buttons.presentation.pressed.emit()
	await tap(KEY_ESCAPE)
	check(settings.visible and paused, "Presentation back lost settings context")
	settings.hub_buttons.video.pressed.emit()
	settings.options.fps_limit.grab_focus()
	await tap(KEY_RIGHT)
	check(Engine.max_fps == 30 and GeneralSettings.get_value("fps_limit") == 30, "FPS limiter did not reach engine")
	await tap(KEY_LEFT)
	check(Engine.max_fps == 0, "FPS limiter did not return to unlimited")
	settings.options.vsync.grab_focus()
	await tap(KEY_RIGHT)
	check(not GeneralSettings.get_value("vsync"), "VSync option did not switch")
	if DisplayServer.get_name() != "headless":
		check(DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_DISABLED, "VSync did not reach display server")
	settings.options.volume.grab_focus()
	await tap(KEY_LEFT)
	check(GeneralSettings.get_value("volume") == 90 and AudioServer.get_bus_volume_db(0) < -0.1, "Volume did not reach audio bus")
	await capture("video")
	settings.options.window_mode.grab_focus()
	await tap(KEY_RIGHT)
	check(GeneralSettings.get_value("window_mode") == 1 and settings.options.resolution.disabled, "Fullscreen did not disable window resolution")
	if DisplayServer.get_name() != "headless":
		check(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN, "Fullscreen was not applied")
	await tap(KEY_RIGHT)
	check(GeneralSettings.get_value("window_mode") == 2, "Exclusive fullscreen option was not selected")
	if DisplayServer.get_name() != "headless":
		check(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN, "Exclusive fullscreen was not applied")
	await tap(KEY_LEFT)
	await tap(KEY_LEFT)
	check(not settings.options.resolution.disabled, "Window resolution remained disabled")
	if DisplayServer.get_name() != "headless":
		check(not DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS), "Window borders were not restored")
	settings.options.resolution.grab_focus()
	await tap(KEY_LEFT)
	if DisplayServer.get_name() != "headless":
		check(DisplayServer.window_get_size() == Vector2i(960, 540), "Window resolution was not applied")
	restore_button("video").pressed.emit()
	await tick(2)
	check(GeneralSettings.get_value("volume") == 100 and GeneralSettings.get_value("vsync") and Engine.max_fps == 0, "Video/audio defaults were not restored")
	settings.back()
	settings.hub_buttons.keyboard.pressed.emit()
	await capture("keyboard")
	var pad_interact: String = InputBindings.binding_label("interact", InputBindings.GAMEPAD)
	# Capture a keyboard binding through the actual button and input path.
	settings.binding_buttons.keyboard.interact[0].pressed.emit()
	await tap(KEY_F)
	check(settings.capture_action.is_empty() and InputBindings.binding_label("interact", InputBindings.KEYBOARD) == "F", "Key binding was not captured")
	check(InputBindings.binding_label("interact", InputBindings.GAMEPAD) == pad_interact, "Keyboard remap changed gamepad")
	check(menu.visible and paused, "Binding capture resumed gameplay")
	# Assigning an in-use key offers an explicit exchange, rather than creating
	# two gameplay actions on that key or silently destroying another binding.
	settings.binding_buttons.keyboard.fire[0].pressed.emit()
	await tap(KEY_F)
	check(not settings.capture_conflict.is_empty(), "Conflicting binding was silently accepted")
	await capture("binding-conflict")
	await tap(KEY_ENTER)
	check(InputBindings.binding_label("fire", InputBindings.KEYBOARD) == "F" and InputBindings.binding_label("interact", InputBindings.KEYBOARD) == "Left mouse", "Conflict exchange did not preserve both actions")
	settings.binding_buttons.keyboard.interact[1].pressed.emit()
	await tap(KEY_J)
	check(InputBindings.binding_label("interact", InputBindings.KEYBOARD, 1) == "J", "Alternative binding was not added")
	settings.binding_buttons.keyboard.interact[1].grab_focus()
	await tap(KEY_DELETE)
	check(InputBindings.binding_label("interact", InputBindings.KEYBOARD, 1) == "—" and InputBindings.binding_label("interact", InputBindings.KEYBOARD) == "Left mouse", "Clearing an alternative changed the primary")
	settings.binding_buttons.keyboard.interact[0].pressed.emit()
	var middle := InputEventMouseButton.new()
	middle.button_index = MOUSE_BUTTON_MIDDLE
	middle.pressed = true
	Input.parse_input_event(middle)
	await tick(2)
	middle = InputEventMouseButton.new()
	middle.button_index = MOUSE_BUTTON_MIDDLE
	Input.parse_input_event(middle)
	await tick(2)
	check(InputBindings.binding_label("interact", InputBindings.KEYBOARD) == "Middle mouse", "Mouse binding was not captured")
	settings.binding_buttons.keyboard.reload[0].pressed.emit()
	await tap(KEY_ESCAPE)
	check(settings.capture_action.is_empty() and settings.visible and paused, "Capture cancel closed settings")
	# A modifier alone is valid, and a chord is captured without binding its
	# first modifier key prematurely.
	settings.binding_buttons.keyboard.run[0].pressed.emit()
	await tap(KEY_SHIFT)
	check(InputBindings.binding_label("run", InputBindings.KEYBOARD) == "Shift", "Standalone modifier label/binding was incorrect")
	settings.binding_buttons.keyboard.reload[0].pressed.emit()
	key(KEY_CTRL, true, true)
	await tick(2)
	check(not settings.capture_action.is_empty(), "Ctrl was captured before its chord")
	key(KEY_K, true, true)
	await tick(2)
	key(KEY_K, false, true)
	key(KEY_CTRL, false)
	await tick(2)
	check(InputBindings.binding_label("reload", InputBindings.KEYBOARD) == "Ctrl+K", "Modifier chord was not captured")
	settings.back()
	settings.hub_buttons.gamepad.pressed.emit()
	await pad_tap(JOY_BUTTON_RIGHT_SHOULDER)
	GamepadControls.shared.playstation = true
	GamepadControls.shared.changed.emit()
	await capture("ps4")
	settings.options.stick_deadzone.grab_focus()
	await tap(KEY_RIGHT)
	check(is_equal_approx(InputMap.action_get_deadzone("move_left"), 0.3) and is_equal_approx(InputMap.action_get_deadzone("aim_left"), 0.3), "Stick deadzone did not reach InputMap")
	settings.binding_buttons.gamepad.reload[0].pressed.emit()
	await pad_tap(JOY_BUTTON_Y)
	check(settings.capture_conflict.get("action", "") == "dodge", "Dodge binding conflict was not detected")
	await pad_tap(JOY_BUTTON_A)
	check(InputBindings.binding_label("reload", InputBindings.GAMEPAD, 0, true) == "△", "Pad button binding was not captured")
	check(InputBindings.binding_label("dodge", InputBindings.GAMEPAD, 0, true) == "□", "Binding exchange lost the dodge action")
	check(InputBindings.binding_label("reload", InputBindings.KEYBOARD) == "Ctrl+K", "Pad remap changed keyboard")
	# Directional axes can be reassigned, with a reversible conflict exchange.
	settings.binding_buttons.gamepad.move_up[1].pressed.emit()
	axis(JOY_AXIS_RIGHT_Y, -0.2)
	await tick(2)
	check(not settings.capture_action.is_empty() and settings.capture_event == null, "Axis drift was captured as a binding")
	axis(JOY_AXIS_RIGHT_Y, -0.9)
	await tick(2)
	check(not settings.capture_conflict.is_empty(), "Axis conflict was not detected")
	await pad_tap(JOY_BUTTON_A)
	axis(JOY_AXIS_RIGHT_Y, 0.0)
	await tick(2)
	check(InputBindings.binding_label("move_up", InputBindings.GAMEPAD, 1).contains("Right stick"), "Directional axis was not captured")
	var left_up := InputEventJoypadMotion.new()
	left_up.axis = JOY_AXIS_LEFT_Y
	left_up.axis_value = -1.0
	InputBindings.rebind("move_up", InputBindings.GAMEPAD, 1, left_up, true)
	settings.binding_buttons.gamepad.reload[1].pressed.emit()
	axis(JOY_AXIS_TRIGGER_RIGHT, 0.9)
	await tick(2)
	await pad_tap(JOY_BUTTON_A)
	axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	await tick(2)
	check(InputBindings.binding_label("reload", InputBindings.GAMEPAD, 1, true) == "R2", "Trigger binding was not captured")
	var trigger := InputEventJoypadMotion.new()
	trigger.axis = JOY_AXIS_TRIGGER_RIGHT
	trigger.axis_value = 1.0
	InputBindings.rebind("fire", InputBindings.GAMEPAD, 0, trigger, true)
	# An empty secondary can also be cleared from the pad without a keyboard.
	settings.binding_buttons.gamepad.reload[1].pressed.emit()
	await pad_tap(JOY_BUTTON_BACK)
	settings.binding_buttons.gamepad.reload[1].grab_focus()
	await pad_tap(JOY_BUTTON_X)
	check(InputBindings.binding_label("reload", InputBindings.GAMEPAD, 1) == "—", "Pad clear shortcut did not remove alternative")
	settings.binding_buttons.gamepad.reload[0].pressed.emit()
	settings.capture_timer.timeout.emit()
	check(settings.capture_action.is_empty() and InputBindings.binding_label("reload", InputBindings.GAMEPAD, 0, true) == "△", "Capture timeout changed binding or remained open")
	# Persist and reload as on the next launch, while retaining unrelated data.
	GeneralSettings.set_value("mouse_sensitivity", 1.6)
	GeneralSettings._loaded = false
	GeneralSettings.values = GeneralSettings.DEFAULTS.duplicate()
	GeneralSettings.ensure_loaded()
	InputBindings._loaded = false
	InputBindings.ensure_loaded()
	isolate_pad()
	check(is_equal_approx(GeneralSettings.get_value("mouse_sensitivity"), 1.6) and is_equal_approx(GeneralSettings.get_value("stick_deadzone"), 0.3), "Preferences did not survive cfg reload")
	check(InputBindings.binding_label("reload", InputBindings.GAMEPAD, 0, true) == "△" and InputBindings.binding_label("fire", InputBindings.KEYBOARD) == "F", "Bindings did not survive cfg reload")
	# Bad persisted values fall back safely instead of crashing menu startup.
	config.load(probe_path)
	config.set_value("general", "fps_limit", 99999)
	config.set_value("general", "mouse_sensitivity", "bad")
	config.set_value("bindings_keyboard", "pause", [{"type": "key", "code": "bad"}])
	config.save(probe_path)
	GeneralSettings._loaded = false
	GeneralSettings.ensure_loaded()
	InputBindings._loaded = false
	InputBindings.ensure_loaded()
	isolate_pad()
	check(GeneralSettings.get_value("fps_limit") == 0 and GeneralSettings.get_value("mouse_sensitivity") == 1.0, "Malformed preferences were not sanitized")
	config.load(probe_path)
	check(config.get_value("unrelated", "marker") == "preserved", "Settings overwrote unrelated sections")
	# The configured action is used by the real weapon after leaving the menu.
	settings.back()
	settings.back()
	menu.close()
	fixture.restart()
	ControlScheme.set_mode(ControlScheme.Mode.CAMERA_RELATIVE)
	await tick(4)
	key(KEY_CTRL)
	await tick(4)
	var ammo: int = PlayerWeapon.magazine
	await tap(KEY_F)
	check(PlayerWeapon.magazine == ammo - 1, "Remapped fire key did not operate weapon")
	key(KEY_CTRL, false)
	await tick(2)
	# Menu recovery remains possible even when gameplay pause is remapped.
	var remapped_pause := InputEventKey.new()
	remapped_pause.physical_keycode = KEY_P
	InputBindings.rebind("pause", InputBindings.KEYBOARD, 0, remapped_pause)
	await tap(KEY_ESCAPE)
	check(menu.visible and paused, "Fixed Esc recovery was lost after pause remap")
	menu.settings_button.pressed.emit()
	settings.hub_buttons.keyboard.pressed.emit()
	restore_button("keyboard").pressed.emit()
	check(InputBindings.binding_label("fire", InputBindings.KEYBOARD) == "Left mouse" and GeneralSettings.get_value("mouse_sensitivity") == 1.0, "Keyboard defaults were not restored")
	check(InputBindings.binding_label("reload", InputBindings.GAMEPAD, 0, true) == "△", "Restoring keyboard reset pad bindings")
	settings.back()
	settings.hub_buttons.gamepad.pressed.emit()
	restore_button("gamepad").pressed.emit()
	check(InputBindings.binding_label("reload", InputBindings.GAMEPAD, 0, true) == "□" and is_equal_approx(InputMap.action_get_deadzone("move_left"), 0.25), "Gamepad defaults were not restored")
	settings.binding_buttons.gamepad.pause[0].pressed.emit()
	await pad_tap(JOY_BUTTON_B)
	check(not settings.capture_conflict.is_empty(), "Pause/run conflict was not reported")
	await pad_tap(JOY_BUTTON_A)
	check(paused and settings.visible and InputBindings.binding_label("pause", InputBindings.GAMEPAD) == "B", "Pause remap closed the menu")
	check(InputBindings.binding_label("run", InputBindings.GAMEPAD, 1) == "—", "Reserved Options binding was transferred into run")
	restore_button("gamepad").pressed.emit()
	if DisplayServer.get_name() != "headless":
		root.size = Vector2i(1280, 960)
		await capture("ps4-4x3")
		check(settings.pages.gamepad.get_global_rect().size == Vector2(root.get_visible_rect().size), "Settings did not fit 4:3 window")
	menu.close()
	fixture.free()
	var player_settings_after: String = FileAccess.get_file_as_string("user://settings.cfg") if FileAccess.file_exists("user://settings.cfg") else "<none>"
	check(player_settings_before == player_settings_after, "Probe modified player's settings")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(probe_path))
	print("SETTINGS failures=%d" % failures)
	quit(0 if failures == 0 else 1)
