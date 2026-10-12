class_name SettingsMenu
extends Control
## Settings pages live inside the pause layer, so gameplay never receives a
## key captured for a binding. Menu navigation remains a fixed recovery path.
signal back_requested
signal gameplay_requested
signal presentation_requested

const SKIN := preload("res://assets/ui/retro_terminal/pause_menu_skin_v02.png")
const VIDEO_KEYS: Array[String] = ["window_mode", "resolution", "vsync", "fps_limit", "volume"]
const KEYBOARD_KEYS: Array[String] = ["mouse_sensitivity", "mouse_invert_y"]
const PAD_KEYS: Array[String] = ["stick_deadzone", "trigger_deadzone", "pad_invert_y"]
var pages: Dictionary = {}
var hub_buttons: Dictionary = {}
var options: Dictionary = {}
var binding_buttons: Dictionary = {}
var hints: Array[Label] = []
var first_buttons: Dictionary = {}
var current_page: String = "hub"
var message: Label
var capture_overlay: Control
var capture_label: Label
var capture_timer: Timer
var capture_cancel: Button
var capture_confirm: Button
var capture_action: String = ""
var capture_family: String = ""
var capture_slot: int = 0
var capture_event: InputEvent
var capture_conflict: Dictionary = {}
var _pending_modifier: InputEventKey
var _return_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	GeneralSettings.ensure_loaded()
	InputBindings.ensure_loaded()
	_build_hub()
	_build_video()
	_build_bindings(InputBindings.KEYBOARD)
	_build_bindings(InputBindings.GAMEPAD)
	_build_capture()
	GamepadControls.shared.changed.connect(refresh)
	refresh()
	hide()

func _page(id: String, title: String, subtitle: String) -> RetroScreen:
	var page := RetroScreen.new()
	add_child(page)
	page.build(SKIN)
	var heading_back := ColorRect.new()
	heading_back.position = Vector2(300, 126)
	heading_back.size = Vector2(1072, 98)
	heading_back.color = Color("071318")
	heading_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.canvas.add_child(heading_back)
	page.label_at(title, Rect2(322, 126, 1028, 54), 32)
	page.label_at(subtitle, Rect2(322, 180, 1028, 40), 20)
	var footer_back := ColorRect.new()
	footer_back.position = Vector2(300, 788)
	footer_back.size = Vector2(1072, 66)
	footer_back.color = Color("071318")
	footer_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.canvas.add_child(footer_back)
	var hint: Label = page.label_at("", Rect2(312, 788, 1048, 66), 21)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hints.append(hint)
	pages[id] = page
	page.hide()
	return page

func _build_hub() -> void:
	var page: RetroScreen = _page("hub", "SETTINGS", "Changes save automatically. Choose a category.")
	var rows: Array[Button] = []
	var entries := {"video": "VIDEO AND AUDIO", "gameplay": "GAMEPLAY", "keyboard": "KEYBOARD AND MOUSE", "gamepad": "CONTROLLER / GAMEPAD", "presentation": "PRESENTATION"}
	var y: float = 236
	for id: String in entries:
		var button: Button = page.button_at(entries[id], Rect2(300, y, 1072, 62), func() -> void: _open_category(id), 28)
		hub_buttons[id] = button
		rows.append(button)
		y += 76
	rows.append(page.button_at("BACK", Rect2(300, 704, 1072, 62), back_requested.emit, 28))
	page.focus_ring(rows)
	first_buttons.hub = rows[0]

func _open_category(id: String) -> void:
	if id == "gameplay":
		gameplay_requested.emit()
	elif id == "presentation":
		presentation_requested.emit()
	else:
		_show_page(id)

func _add_option(page: RetroScreen, key: String, title: String, y: float, rows: Array[Button], height: float = 62) -> void:
	var option: RetroOption = page.option_at(title, Rect2(300, y, 1072, height), func(direction: int) -> void: _step(key, direction), 26)
	options[key] = option
	rows.append(option)

func _build_video() -> void:
	var page: RetroScreen = _page("video", "VIDEO AND AUDIO", "Use left / right or the onscreen arrows to adjust options.")
	var rows: Array[Button] = []
	var labels := {"window_mode": "WINDOW MODE", "resolution": "WINDOW RESOLUTION", "vsync": "VSYNC", "fps_limit": "FRAME RATE LIMIT", "volume": "MASTER VOLUME"}
	var y: float = 236
	for key: String in labels:
		_add_option(page, key, labels[key], y, rows)
		y += 68
	message = page.label_at("VSync may limit FPS to the monitor refresh rate. Fullscreen uses the monitor resolution.", Rect2(322, 584, 1028, 62), 20)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_footer_buttons(page, rows, func() -> void: GeneralSettings.restore(VIDEO_KEYS); refresh())
	page.focus_ring(rows)
	first_buttons.video = rows[0]

func _build_bindings(kind: String) -> void:
	var keyboard: bool = kind == InputBindings.KEYBOARD
	var page: RetroScreen = _page(kind, "KEYBOARD AND MOUSE" if keyboard else "CONTROLLER / GAMEPAD", "Select a binding to remap. Menu navigation uses the default controls.")
	var rows: Array[Button] = []
	if keyboard:
		_add_option(page, "mouse_sensitivity", "FREE AIM SENSITIVITY", 230, rows, 54)
		_add_option(page, "mouse_invert_y", "INVERT FREE AIM Y", 290, rows, 54)
	else:
		_add_option(page, "stick_deadzone", "STICK DEADZONE", 230, rows, 54)
		_add_option(page, "trigger_deadzone", "TRIGGER DEADZONE", 290, rows, 54)
		_add_option(page, "pad_invert_y", "INVERT AIM Y", 350, rows, 54)
	var scroll := ScrollContainer.new()
	scroll.name = "BindingsScroll"
	scroll.position = Vector2(300, 358 if keyboard else 418)
	scroll.size = Vector2(1072, 334 if keyboard else 274)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	page.canvas.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	var headings := HBoxContainer.new()
	headings.add_theme_constant_override("separation", 12)
	list.add_child(headings)
	for title: String in ["ACTION", "PRIMARY", "ALTERNATE"]:
		var header := Label.new()
		header.text = title
		header.add_theme_font_override("font", RetroScreen.font())
		header.add_theme_font_size_override("font_size", 18)
		header.add_theme_color_override("font_color", Color("719d9d"))
		if title == "ACTION":
			header.custom_minimum_size.x = 310
		else:
			header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		headings.add_child(header)
	binding_buttons[kind] = {}
	for action: String in InputBindings.actions_for(kind):
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 48
		row.add_theme_constant_override("separation", 12)
		list.add_child(row)
		var caption := Label.new()
		caption.text = InputBindings.ACTIONS[action]
		caption.custom_minimum_size.x = 310
		caption.add_theme_font_override("font", RetroScreen.font())
		caption.add_theme_font_size_override("font_size", 21)
		caption.add_theme_color_override("font_color", Color("b3e8db"))
		row.add_child(caption)
		var slots: Array[Button] = []
		for slot: int in range(2):
			var button := RetroButton.new()
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.clip_text = true
			button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			button.add_theme_font_size_override("font_size", 21)
			button.pressed.connect(func() -> void: begin_capture(action, kind, slot))
			row.add_child(button)
			slots.append(button)
			rows.append(button)
		slots[0].focus_neighbor_right = slots[0].get_path_to(slots[1])
		slots[1].focus_neighbor_left = slots[1].get_path_to(slots[0])
		binding_buttons[kind][action] = slots
	_footer_buttons(page, rows, func() -> void: InputBindings.restore(kind); GeneralSettings.restore(KEYBOARD_KEYS if keyboard else PAD_KEYS); refresh())
	page.focus_ring(rows)
	first_buttons[kind] = rows[0]

func _footer_buttons(page: RetroScreen, rows: Array[Button], restore: Callable) -> void:
	rows.append(page.button_at("RESTORE DEFAULTS", Rect2(300, 710, 520, 58), restore, 23))
	rows.append(page.button_at("BACK", Rect2(852, 710, 520, 58), back, 25))

func open() -> void:
	show()
	_show_page("hub")

func _show_page(id: String) -> void:
	current_page = id
	for name: String in pages:
		pages[name].visible = name == id
	refresh()
	first_buttons[id].grab_focus()

func back() -> void:
	if not capture_action.is_empty():
		_cancel_capture()
	elif current_page == "hub":
		back_requested.emit()
	else:
		var previous: String = current_page
		_show_page("hub")
		hub_buttons[previous].grab_focus()

func refresh() -> void:
	for hint: Label in hints:
		hint.text = "Left / Right adjust · " + GamepadControls.shared.menu_hint()
	if hints.size() >= 4:
		hints[2].text += "\nDelete or right-click: clear binding."
		hints[3].text += "\n%s or Delete: clear binding." % ("□" if GamepadControls.shared.playstation else "X")
	for key: String in options:
		var value: Variant = GeneralSettings.get_value(key)
		var caption: String = ""
		match key:
			"window_mode": caption = GeneralSettings.WINDOW_NAMES[int(value)]
			"resolution":
				var resolution: Vector2i = GeneralSettings.RESOLUTIONS[int(value)]
				caption = "%d × %d" % [resolution.x, resolution.y]
			"fps_limit": caption = "UNLIMITED" if int(value) == 0 else "%d FPS" % int(value)
			"volume": caption = "%d%%" % int(value)
			"mouse_sensitivity": caption = "%.1f ×" % float(value)
			"stick_deadzone", "trigger_deadzone": caption = "%d%%" % roundi(float(value) * 100)
			_: caption = "ON" if bool(value) else "OFF"
		options[key].set_value(caption)
	# Window size is remembered while fullscreen follows the monitor.
	if options.has("resolution"):
		options.resolution.disabled = int(GeneralSettings.get_value("window_mode")) != 0
		options.resolution.previous_button.disabled = options.resolution.disabled
		options.resolution.next_button.disabled = options.resolution.disabled
	for kind: String in binding_buttons:
		for action: String in binding_buttons[kind]:
			for slot: int in range(2):
				binding_buttons[kind][action][slot].text = InputBindings.binding_label(action, kind, slot, GamepadControls.shared.playstation)
				binding_buttons[kind][action][slot].tooltip_text = binding_buttons[kind][action][slot].text

func _step(key: String, direction: int) -> void:
	var value: Variant = GeneralSettings.get_value(key)
	match key:
		"window_mode": value = posmod(int(value) + direction, GeneralSettings.WINDOW_NAMES.size())
		"resolution": value = posmod(int(value) + direction, GeneralSettings.RESOLUTIONS.size())
		"fps_limit": value = GeneralSettings.FRAME_CAPS[posmod(GeneralSettings.FRAME_CAPS.find(int(value)) + direction, GeneralSettings.FRAME_CAPS.size())]
		"volume": value = clampi(int(value) + direction * 10, 0, 100)
		"mouse_sensitivity": value = snappedf(clampf(float(value) + direction * 0.1, 0.2, 3.0), 0.1)
		"stick_deadzone": value = snappedf(clampf(float(value) + direction * 0.05, 0.1, 0.4), 0.05)
		"trigger_deadzone": value = snappedf(clampf(float(value) + direction * 0.05, 0.05, 0.5), 0.05)
		_: value = not bool(value)
	GeneralSettings.set_value(key, value)
	GamepadControls.shared.changed.emit()
	refresh()

func _build_capture() -> void:
	var overlay := RetroScreen.new()
	add_child(overlay)
	overlay.build(null)
	capture_overlay = overlay
	var panel := ColorRect.new()
	panel.position = Vector2(250, 260)
	panel.size = Vector2(1172, 412)
	panel.color = Color("0c2228")
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.canvas.add_child(panel)
	capture_label = overlay.label_at("", Rect2(300, 282, 1072, 254), 27)
	capture_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	capture_confirm = overlay.button_at("SWAP", Rect2(300, 558, 520, 64), _confirm_capture, 26)
	capture_cancel = overlay.button_at("CANCEL", Rect2(852, 558, 520, 64), _cancel_capture, 26)
	capture_timer = Timer.new()
	capture_timer.one_shot = true
	capture_timer.wait_time = 10
	capture_timer.timeout.connect(_cancel_capture)
	add_child(capture_timer)
	_capture_message()
	capture_overlay.hide()

func begin_capture(action: String, kind: String, slot: int) -> void:
	capture_action = action
	capture_family = kind
	capture_slot = slot
	capture_event = null
	_pending_modifier = null
	capture_conflict.clear()
	_return_button = binding_buttons[kind][action][slot]
	capture_overlay.show()
	capture_confirm.hide()
	capture_timer.start()
	_capture_message()

func _process(_delta: float) -> void:
	if not capture_action.is_empty():
		_capture_message()

func _capture_message() -> void:
	if capture_label == null or capture_action.is_empty():
		return
	var title: String = InputBindings.ACTIONS[capture_action]
	if capture_conflict.is_empty():
		capture_label.text = "%s · BINDING %d\n\nPress %s.\nEsc cancels · Backspace clears the binding.\n%sAutomatically cancels in %d s." % [title, capture_slot + 1, "a key or mouse button" if capture_family == InputBindings.KEYBOARD else "a button, trigger or stick direction", "Options/Menu cancels. " if capture_family == InputBindings.GAMEPAD and capture_action != "pause" else "", ceili(capture_timer.time_left)]
	else:
		var previous: Array[InputEvent] = InputBindings.events_for(capture_action, capture_family)
		var exchange: bool = capture_slot < previous.size() and not InputBindings.menu_reserved(previous[capture_slot])
		var transfer: String = "Swap the bindings between both actions?" if exchange else "Transfer to %s? The previous action will lose this binding." % title
		capture_label.text = "%s is already assigned to %s.\n\n%s\nEnter / Cross / A confirms · Esc / Options cancels.\nAutomatically cancels in %d s." % [InputBindings.event_label(capture_event, GamepadControls.shared.playstation), InputBindings.ACTIONS[capture_conflict.action], transfer, ceili(capture_timer.time_left)]

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if capture_action.is_empty():
		_clear_focused_binding(event)
		return
	# Native modal buttons remain clickable; every other input is captured here.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if capture_cancel.get_global_rect().has_point(event.position) or (capture_confirm.visible and capture_confirm.get_global_rect().has_point(event.position)):
			return
	get_viewport().set_input_as_handled()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE or event.keycode == KEY_ESCAPE:
			_cancel_capture()
			return
		if event.physical_keycode == KEY_BACKSPACE or event.keycode == KEY_BACKSPACE:
			InputBindings.rebind(capture_action, capture_family, capture_slot, null)
			_cancel_capture()
			return
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START and (capture_action != "pause" or not capture_conflict.is_empty()):
		_cancel_capture()
		return
	if not capture_conflict.is_empty():
		if (event is InputEventKey and event.pressed and event.keycode == KEY_ENTER) or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A):
			_confirm_capture()
		return
	if InputBindings.family(event) != capture_family or event.is_echo():
		return
	if event is InputEventKey:
		var code: Key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if code in [KEY_CTRL, KEY_ALT, KEY_SHIFT, KEY_META]:
			if event.pressed:
				_pending_modifier = event.duplicate()
			elif _pending_modifier != null:
				_offer_binding(_pending_modifier)
			return
	if event is InputEventJoypadMotion:
		if absf(event.axis_value) < 0.65:
			return
	elif not event.is_pressed():
		return
	_offer_binding(event)

func _clear_focused_binding(event: InputEvent) -> void:
	var mouse: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed
	var keyboard: bool = event is InputEventKey and event.pressed and event.physical_keycode == KEY_DELETE and not event.echo
	var pad: bool = event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_X
	if not (mouse or keyboard or pad) or not binding_buttons.has(current_page):
		return
	for action: String in binding_buttons[current_page]:
		for slot: int in range(2):
			var button: Button = binding_buttons[current_page][action][slot]
			var selected: bool = button.get_global_rect().has_point(event.position) if mouse else button.has_focus()
			if selected:
				get_viewport().set_input_as_handled()
				InputBindings.rebind(action, current_page, slot, null)
				return

func _offer_binding(event: InputEvent) -> void:
	_pending_modifier = null
	capture_event = InputBindings.decode(InputBindings.encode(event))
	if capture_event == null:
		return
	capture_conflict = InputBindings.conflict(capture_action, capture_family, capture_event)
	if capture_conflict.is_empty():
		_confirm_capture()
	else:
		capture_confirm.show()
		capture_timer.start()
		_capture_message()

func _confirm_capture() -> void:
	if capture_event == null or capture_action.is_empty():
		return
	InputBindings.rebind(capture_action, capture_family, capture_slot, capture_event, true)
	_cancel_capture()

func _cancel_capture() -> void:
	capture_timer.stop()
	capture_overlay.hide()
	capture_action = ""
	capture_event = null
	_pending_modifier = null
	capture_conflict.clear()
	refresh()
	if is_instance_valid(_return_button):
		_return_button.grab_focus()

func close() -> void:
	_cancel_capture()
	hide()
