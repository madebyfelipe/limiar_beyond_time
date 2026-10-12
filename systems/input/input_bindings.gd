class_name InputBindings
extends RefCounted
## Two editable slots per action and device family, preserving the other family
## and fixed menu navigation. Persist plain dictionaries rather than objects.
const DEFAULT_PATH := "user://settings.cfg"
const KEYBOARD := "keyboard"
const GAMEPAD := "gamepad"
const ACTIONS := {
	"move_up": "FORWARD", "move_down": "BACKWARD", "move_left": "LEFT", "move_right": "RIGHT",
	"run": "RUN", "interact": "INTERACT", "aim": "ERGUER ARMA", "fire": "FIRE", "reload": "RELOAD",
	"dodge": "DODGE", "use_med_kit": "USE MED KIT",
	"next_target": "NEXT TARGET", "lock_previous_target": "PREVIOUS TARGET", "lock_next_target": "NEXT (WHEEL)",
	"pause": "PAUSE", "toggle_diagnostics": "DIAGNOSTICS", "cycle_retro_filter": "FILTER",
	"aim_up": "MIRA PARA CIMA", "aim_down": "MIRA PARA BAIXO", "aim_left": "MIRA À LEFT", "aim_right": "MIRA À RIGHT",
}
static var settings_path: String = DEFAULT_PATH
static var _loaded: bool = false
static var _defaults: Dictionary = {}

static func family(event: InputEvent) -> String:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return GAMEPAD
	if event is InputEventKey or event is InputEventMouseButton:
		return KEYBOARD
	return ""

static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	if _defaults.is_empty():
		for action: String in ACTIONS:
			var snapshot: Array[InputEvent] = []
			for event: InputEvent in InputMap.action_get_events(action):
				snapshot.append(event.duplicate())
			_defaults[action] = snapshot
	if _isolated_probe_required():
		return
	var file := ConfigFile.new()
	if file.load(settings_path) != OK:
		return
	for kind: String in [KEYBOARD, GAMEPAD]:
		for action: String in ACTIONS:
			if not file.has_section_key("bindings_" + kind, action):
				continue
			var raw: Variant = file.get_value("bindings_" + kind, action)
			if not raw is Array or raw.size() > 2:
				continue
			var decoded: Array[InputEvent] = []
			var valid: bool = true
			for entry: Variant in raw:
				var event: InputEvent = decode(entry)
				if event == null or family(event) != kind:
					valid = false
					break
				decoded.append(event)
			if valid:
				# Older default profiles used both touchpad and R3 for diagnostics.
				# Keep touchpad while giving the new medical-kit action its R3 slot.
				if kind == GAMEPAD and action == "toggle_diagnostics" and not file.has_section_key("bindings_gamepad", "use_med_kit") and decoded.size() == 2:
					if decoded[0] is InputEventJoypadButton and decoded[1] is InputEventJoypadButton and decoded[0].button_index == JOY_BUTTON_TOUCHPAD and decoded[1].button_index == JOY_BUTTON_RIGHT_STICK:
						decoded.remove_at(1)
				_replace(action, kind, decoded)

static func _isolated_probe_required() -> bool:
	return OS.get_cmdline_args().has("--script") and settings_path == DEFAULT_PATH

static func actions_for(kind: String) -> Array[String]:
	var result: Array[String] = []
	for action: String in ACTIONS:
		if kind == KEYBOARD and action.begins_with("aim_"):
			continue
		if kind == GAMEPAD and action == "lock_next_target":
			continue
		result.append(action)
	return result

static func events_for(action: String, kind: String) -> Array[InputEvent]:
	ensure_loaded()
	var result: Array[InputEvent] = []
	for event: InputEvent in InputMap.action_get_events(action):
		if family(event) == kind:
			result.append(event)
	return result

static func _replace(action: String, kind: String, events: Array[InputEvent]) -> void:
	Input.action_release(action)
	for old: InputEvent in InputMap.action_get_events(action):
		if family(old) == kind:
			InputMap.action_erase_event(action, old)
	for event: InputEvent in events:
		InputMap.action_add_event(action, event)

static func conflict(action: String, kind: String, event: InputEvent) -> Dictionary:
	for other: String in actions_for(kind):
		var events: Array[InputEvent] = events_for(other, kind)
		for slot: int in range(events.size()):
			if same(events[slot], event):
				if other == action:
					return {}
				return {"action": other, "slot": slot}
	return {}

static func rebind(action: String, kind: String, slot: int, event: InputEvent, swap: bool = false) -> bool:
	ensure_loaded()
	if not ACTIONS.has(action) or slot < 0 or slot > 1 or (event != null and family(event) != kind):
		return false
	if event != null and menu_reserved(event) and action != "pause":
		return false
	var current: Array[InputEvent] = events_for(action, kind)
	var clash: Dictionary = conflict(action, kind, event) if event != null else {}
	if not clash.is_empty():
		if not swap:
			return false
		var other: Array[InputEvent] = events_for(clash.action, kind)
		if slot < current.size() and (not menu_reserved(current[slot]) or clash.action == "pause"):
			other[int(clash.slot)] = current[slot]
		else:
			other.remove_at(int(clash.slot))
		_replace(clash.action, kind, other)
	# Selecting a binding already present in the other slot simply exchanges
	# the order, rather than duplicating it or silently dropping an alternative.
	var existing: int = -1
	if event != null:
		for i: int in range(current.size()):
			if same(current[i], event):
				existing = i
	if existing >= 0 and existing != slot:
		if slot < current.size():
			current[existing] = current[slot]
		else:
			return true
	if event == null:
		if slot < current.size():
			current.remove_at(slot)
	elif slot < current.size():
		current[slot] = decode(encode(event))
	else:
		current.append(decode(encode(event)))
	_replace(action, kind, current)
	store()
	_notify()
	return true

static func menu_reserved(event: InputEvent) -> bool:
	return (event is InputEventKey and (event.physical_keycode == KEY_ESCAPE or event.keycode == KEY_ESCAPE)) or (event is InputEventJoypadButton and event.button_index == JOY_BUTTON_START)

static func restore(kind: String) -> void:
	ensure_loaded()
	for action: String in ACTIONS:
		var events: Array[InputEvent] = []
		for event: InputEvent in _defaults[action]:
			if family(event) == kind:
				events.append(event.duplicate())
		_replace(action, kind, events)
	store()
	_notify()

static func store() -> void:
	if _isolated_probe_required():
		return
	var file := ConfigFile.new()
	file.load(settings_path)
	for kind: String in [KEYBOARD, GAMEPAD]:
		for action: String in ACTIONS:
			var data: Array[Dictionary] = []
			for event: InputEvent in events_for(action, kind):
				data.append(encode(event))
			file.set_value("bindings_" + kind, action, data)
	file.save(settings_path)

static func _notify() -> void:
	if GamepadControls.shared != null:
		GamepadControls.shared.changed.emit()

static func same(a: InputEvent, b: InputEvent) -> bool:
	return encode(a) == encode(b)

static func encode(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		var code: int = int(event.physical_keycode if event.physical_keycode != 0 else event.keycode)
		return {"type": "key", "code": code, "ctrl": event.ctrl_pressed and code != KEY_CTRL, "alt": event.alt_pressed and code != KEY_ALT, "shift": event.shift_pressed and code != KEY_SHIFT, "meta": event.meta_pressed and code != KEY_META}
	if event is InputEventMouseButton:
		return {"type": "mouse", "button": int(event.button_index)}
	if event is InputEventJoypadButton:
		return {"type": "button", "button": int(event.button_index)}
	if event is InputEventJoypadMotion:
		return {"type": "axis", "axis": int(event.axis), "direction": int(signf(event.axis_value))}
	return {}

static func decode(data: Variant) -> InputEvent:
	if not data is Dictionary:
		return null
	match data.get("type", ""):
		"key":
			if not data.get("code") is int or int(data.code) <= 0:
				return null
			var event := InputEventKey.new()
			event.device = -1
			event.physical_keycode = int(data.code) as Key
			event.ctrl_pressed = bool(data.get("ctrl", false))
			event.alt_pressed = bool(data.get("alt", false))
			event.shift_pressed = bool(data.get("shift", false))
			event.meta_pressed = bool(data.get("meta", false))
			return event
		"mouse":
			if not data.get("button") is int or int(data.button) < 1 or int(data.button) > MOUSE_BUTTON_XBUTTON2:
				return null
			var event := InputEventMouseButton.new()
			event.device = -1
			event.button_index = int(data.button) as MouseButton
			return event
		"button":
			if not data.get("button") is int or int(data.button) < 0 or int(data.button) >= JOY_BUTTON_MAX:
				return null
			var event := InputEventJoypadButton.new()
			event.device = -1
			event.button_index = int(data.button) as JoyButton
			return event
		"axis":
			if not data.get("axis") is int or int(data.axis) < 0 or int(data.axis) >= JOY_AXIS_MAX or not data.get("direction") in [-1, 1]:
				return null
			var event := InputEventJoypadMotion.new()
			event.device = -1
			event.axis = int(data.axis) as JoyAxis
			event.axis_value = float(data.direction)
			return event
	return null

static func binding_label(action: String, kind: String, slot: int = 0, ps: bool = false) -> String:
	var events: Array[InputEvent] = events_for(action, kind)
	return event_label(events[slot], ps) if slot < events.size() else "—"

static func event_label(event: InputEvent, ps: bool = false) -> String:
	if event is InputEventKey:
		var prefix: String = ("Ctrl+" if event.ctrl_pressed else "") + ("Alt+" if event.alt_pressed else "") + ("Shift+" if event.shift_pressed else "") + ("Meta+" if event.meta_pressed else "")
		return prefix + OS.get_keycode_string(event.physical_keycode if event.physical_keycode != 0 else event.keycode)
	if event is InputEventMouseButton:
		return {1: "Left mouse", 2: "Right mouse", 3: "Middle mouse", 4: "Wheel ↑", 5: "Wheel ↓", 6: "Wheel ←", 7: "Wheel →", 8: "Mouse 4", 9: "Mouse 5"}.get(int(event.button_index), "Mouse")
	if event is InputEventJoypadButton:
		var names: Array = ["✕", "○", "□", "△", "Share", "PS", "Options", "L3", "R3", "L1", "R1", "D-pad ↑", "D-pad ↓", "D-pad ←", "D-pad →"] if ps else ["A", "B", "X", "Y", "View", "Guide", "Menu", "LS", "RS", "LB", "RB", "D-pad ↑", "D-pad ↓", "D-pad ←", "D-pad →"]
		if event.button_index < names.size():
			return names[event.button_index]
		return "Touchpad" if event.button_index == JOY_BUTTON_TOUCHPAD else "Button %d" % event.button_index
	if event is InputEventJoypadMotion:
		if event.axis == JOY_AXIS_TRIGGER_LEFT:
			return "L2" if ps else "LT"
		if event.axis == JOY_AXIS_TRIGGER_RIGHT:
			return "R2" if ps else "RT"
		var stick: String = "Left stick" if event.axis < 2 else "Right stick"
		var direction: String = ("←" if event.axis_value < 0 else "→") if event.axis % 2 == 0 else ("↑" if event.axis_value < 0 else "↓")
		return stick + " " + direction
	return "—"

static func is_custom_event(event: InputEvent) -> bool:
	ensure_loaded()
	for action: String in ACTIONS:
		for binding: InputEvent in InputMap.action_get_events(action):
			if same(binding, event):
				var original: bool = false
				for old: InputEvent in _defaults[action]:
					original = original or same(old, binding)
				if not original:
					return true
	return false
