class_name PauseMenu
extends Control
## Esc toggles pause; losing focus pauses and regaining it does not resume.
## Processes while the tree is paused, so its buttons remain operable.

signal restart_requested

@export var resume_button: Button
@export var restart_button: Button
@export var scheme_button: Button
@export var filter_button: Button
@export var quit_button: Button
## Probes that are not exercising focus loss may disable it.
@export var pause_on_focus_loss: bool = true
var skin_layer: CanvasLayer
var screen: RetroScreen
## Second page: the presentation options, one row per effect.
var filter_screen: RetroScreen
var pixel_button: Button
var effect_buttons: Dictionary = {}

func _ready() -> void:
	_build_skin()
	hide()
	resume_button.pressed.connect(close)
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(func() -> void: get_tree().quit())
	if scheme_button:
		ControlScheme.ensure_loaded()
		scheme_button.pressed.connect(_on_scheme_pressed)
		_update_scheme_button()
	if filter_button:
		RetroFilter.ensure_loaded()
		filter_button.pressed.connect(_on_filter_pressed)
		_update_filter_button()

## Switches between camera-relative and traditional tank steering. The choice
## is stored by ControlScheme, so it survives scene changes and sessions.
func _on_scheme_pressed() -> void:
	ControlScheme.toggle()
	_update_scheme_button()

## Opens the presentation page. Each effect is its own switch there, so the
## look is assembled instead of picked from a list; RetroFilter stores the
## settings, so they survive scene changes and sessions.
func _on_filter_pressed() -> void:
	screen.hide()
	filter_screen.show()
	_update_filter_page()
	pixel_button.grab_focus()

func _close_filter_page() -> void:
	filter_screen.hide()
	screen.show()
	_update_filter_button()
	filter_button.grab_focus()

func _is_filter_page_open() -> bool:
	return filter_screen != null and filter_screen.visible

func _update_filter_button() -> void:
	filter_button.text = "APRESENTAÇÃO: %s" % RetroFilter.describe().to_upper()

func _on_pixel_pressed() -> void:
	RetroFilter.set_pixel_step(self, (RetroFilter.pixel_step + 1) % RetroFilter.PIXEL_STEPS.size())
	_update_filter_page()

func _toggle_effect(id: int) -> void:
	RetroFilter.set_effect(self, id, not RetroFilter.is_effect_on(id))
	_update_filter_page()

func _update_filter_page() -> void:
	pixel_button.text = "PIXELIZAÇÃO:  < %s >" % RetroFilter.pixel_name().to_upper()
	for row: Dictionary in RetroFilter.EFFECTS:
		var id: int = int(row["id"])
		var button: Button = effect_buttons[id]
		button.text = "%s:  %s" % [String(row["name"]).to_upper(), "LIGADO" if RetroFilter.is_effect_on(id) else "DESLIGADO"]

func _update_scheme_button() -> void:
	# Upper case to match the rest of the panel, which is set in tracked capitals.
	scheme_button.text = "CONTROLES: %s" % ControlScheme.label().to_upper()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo():
		if _is_filter_page_open():
			# Esc steps back one page before it gives the game back.
			_close_filter_page()
		elif visible:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if (what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT) and pause_on_focus_loss and is_node_ready() and not visible and not get_tree().paused:
		open()

func open() -> void:
	if get_tree().paused and not visible:
		return
	_update_scheme_button()
	_update_filter_button()
	get_tree().paused = true
	show()
	skin_layer.show()
	filter_screen.hide()
	screen.show()
	resume_button.grab_focus()

func close() -> void:
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
	resume_button = screen.button_at("CONTINUAR", Rect2(424, 272, 824, 87), Callable(), 36)
	restart_button = screen.button_at("REINICIAR", Rect2(424, 373, 824, 87), Callable(), 36)
	scheme_button = screen.button_at("", Rect2(424, 474, 824, 87), Callable(), 33)
	filter_button = screen.button_at("", Rect2(424, 575, 824, 87), Callable(), 33)
	quit_button = screen.button_at("SAIR DO JOGO", Rect2(424, 676, 824, 87), Callable(), 36)
	screen.focus_ring([resume_button, restart_button, scheme_button, filter_button, quit_button])
	_build_filter_page()
	skin_layer.hide()

## The presentation page, over the same skin: one stepper for how coarse the
## picture is and one switch per effect, so scanlines and the tube are
## independent of each other.
func _build_filter_page() -> void:
	RetroFilter.ensure_loaded()
	filter_screen = RetroScreen.new()
	skin_layer.add_child(filter_screen)
	filter_screen.build(preload("res://assets/ui/retro_terminal/pause_menu_skin_v02.png"))
	filter_screen.label_at("APRESENTAÇÃO", Rect2(300, 130, 1072, 70), 34)
	var rows: Array[Button] = []
	var y: float = 236.0
	pixel_button = filter_screen.button_at("", Rect2(300, y, 1072, 72), _on_pixel_pressed, 29)
	rows.append(pixel_button)
	for row: Dictionary in RetroFilter.EFFECTS:
		y += 80.0
		var id: int = int(row["id"])
		var button: Button = filter_screen.button_at("", Rect2(300, y, 1072, 72), func() -> void: _toggle_effect(id), 29)
		effect_buttons[id] = button
		rows.append(button)
	y += 96.0
	rows.append(filter_screen.button_at("VOLTAR", Rect2(300, y, 1072, 72), _close_filter_page, 29))
	filter_screen.focus_ring(rows)
	_update_filter_page()
	filter_screen.hide()

func _exit_tree() -> void:
	if visible:
		get_tree().paused = false
