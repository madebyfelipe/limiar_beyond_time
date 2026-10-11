class_name PauseMenu
extends Control
## Esc toggles pause; losing focus pauses and regaining it does not resume.
## Processes while the tree is paused, so its buttons remain operable.

signal restart_requested

@export var resume_button: Button
@export var restart_button: Button
@export var quit_button: Button
## Probes that are not exercising focus loss may disable it.
@export var pause_on_focus_loss: bool = true

func _ready() -> void:
	hide()
	resume_button.pressed.connect(close)
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(func() -> void: get_tree().quit())

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if visible:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if (what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT) and pause_on_focus_loss and is_node_ready() and not visible:
		open()

func open() -> void:
	get_tree().paused = true
	show()
	resume_button.grab_focus()

func close() -> void:
	hide()
	get_tree().paused = false

func _on_restart_pressed() -> void:
	restart_requested.emit()
	close()
