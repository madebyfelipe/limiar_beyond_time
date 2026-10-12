class_name GamepadControls
extends Node
## Shared input family for prompts. Godot/SDL normalizes DualShock 4 and other
## pads to the same actions; no raw USB/Bluetooth button numbers are needed.

signal changed
signal active_disconnected

## The class reference also resolves when a SceneTree probe is compiled before
## Godot registers its autoload global identifiers.
static var shared: GamepadControls

var gamepad_active: bool = false
var device: int = -1
var playstation: bool = false

func _enter_tree() -> void:
	shared = self

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	InputBindings.ensure_loaded()
	GeneralSettings.ensure_loaded()
	Input.joy_connection_changed.connect(_on_connection_changed)
	var connected: Array[int] = Input.get_connected_joypads()
	if not connected.is_empty():
		playstation = is_playstation_name(Input.get_joy_name(connected[0]))

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		if event.pressed:
			_use_gamepad(event.device)
	elif event is InputEventJoypadMotion:
		# Resting axes must not steal the mouse or keyboard's prompts.
		var trigger: bool = event.axis == JOY_AXIS_TRIGGER_LEFT or event.axis == JOY_AXIS_TRIGGER_RIGHT
		var intentional: bool = event.axis_value > float(GeneralSettings.get_value("trigger_deadzone")) if trigger else absf(event.axis_value) > float(GeneralSettings.get_value("stick_deadzone"))
		if intentional:
			_use_gamepad(event.device)
	elif (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed) or (event is InputEventMouseMotion and event.relative.length() > 2.0):
		if gamepad_active:
			gamepad_active = false
			changed.emit()

func _use_gamepad(id: int) -> void:
	var family: bool = is_playstation_name(Input.get_joy_name(id))
	var update: bool = not gamepad_active or device != id or playstation != family
	gamepad_active = true
	device = id
	playstation = family
	if update:
		changed.emit()

func is_playstation_name(value: String) -> bool:
	var lower: String = value.to_lower()
	return lower.contains("ps4") or lower.contains("ps5") or lower.contains("dualshock") or lower.contains("dualsense") or lower.contains("playstation") or lower.contains("sony") or lower.contains("wireless controller")

func _on_connection_changed(id: int, connected: bool) -> void:
	if connected and not gamepad_active and device == -1:
		playstation = is_playstation_name(Input.get_joy_name(id))
		changed.emit()
	if not connected and id == device:
		var was_active: bool = gamepad_active
		device = -1
		gamepad_active = false
		changed.emit()
		if was_active:
			active_disconnected.emit()

func aim_vector() -> Vector2:
	var vector: Vector2 = Input.get_vector(&"aim_left", &"aim_right", &"aim_up", &"aim_down")
	if GeneralSettings.get_value("pad_invert_y"):
		vector.y = -vector.y
	return vector

func interact_label() -> String:
	return InputBindings.binding_label("interact", InputBindings.GAMEPAD if gamepad_active else InputBindings.KEYBOARD, 0, playstation)

func menu_hint() -> String:
	if not gamepad_active:
		return "Up/Down select · Enter confirm · Esc back"
	return "Stick / D-pad · %s confirm · %s back · %s pause" % ["✕" if playstation else "A", "○" if playstation else "B", "Options" if playstation else "Menu"]

func combat_hint() -> String:
	return "%s aim · %s fire · %s reload · %s / %s targets" % [InputBindings.binding_label("aim", InputBindings.GAMEPAD, 0, playstation), InputBindings.binding_label("fire", InputBindings.GAMEPAD, 0, playstation), InputBindings.binding_label("reload", InputBindings.GAMEPAD, 0, playstation), InputBindings.binding_label("lock_previous_target", InputBindings.GAMEPAD, 0, playstation), InputBindings.binding_label("next_target", InputBindings.GAMEPAD, 0, playstation)]
