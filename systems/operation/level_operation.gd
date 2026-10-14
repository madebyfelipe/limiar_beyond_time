class_name LevelOperation
extends Node
## Esc pause, F3 diagnostics, transient notices and the fall safety net, for the
## levels that assemble their runtime in code. The technical route wires the
## same two overlays from its own scene file; this keeps the authored levels
## from repeating that layout and from each growing its own version of "put the
## player back".

signal restart_requested
signal recovered(at: Vector3)

const PAUSE_MENU := preload("res://ui/pause_menu.tscn")
const DIAGNOSTICS := preload("res://ui/diagnostics_overlay.tscn")

@export var player: PlayerController
## Optional: with a director wired, the readout also names the active shot.
@export var director: CameraDirector
## The 16:9 frame. The readout and the notice belong inside it, like the route's;
## the pause menu covers the whole window, bars included.
@export var frame: Control
## Feet below this height mean the actor left the level geometry.
@export var recovery_height: float = -4.0

var pause_menu: PauseMenu
var diagnostics: DiagnosticsOverlay
var notice: Label
var notice_timer: Timer
var hud: GameHud
## The attaché case, opened by the inventory action (I / Back-Share).
var inventory_menu: InventoryMenu
var weapon_readout: WeaponReadout
## Last place the actor stood on the floor; where the safety net returns them.
var last_safe: Transform3D

func _ready() -> void:
	var hud_layer := CanvasLayer.new()
	hud_layer.layer = 8
	add_child(hud_layer)
	hud = GameHud.new()
	hud.player = player
	hud_layer.add_child(hud)
	var case_layer := CanvasLayer.new()
	case_layer.layer = 15
	add_child(case_layer)
	inventory_menu = InventoryMenu.new()
	inventory_menu.name = "InventoryMenu"
	inventory_menu.player = player
	case_layer.add_child(inventory_menu)
	# A Control under a plain Node lays out against the window, which is what the
	# menu wants; the readout and the notice get the frame as parent instead.
	pause_menu = PAUSE_MENU.instantiate()
	# Probes drive these levels through --script with no real window; a focus
	# notification there would pause a run that is not testing pausing. The one
	# probe that does test it turns this back on, the way check_operation does.
	pause_menu.pause_on_focus_loss = not OS.get_cmdline_args().has("--script")
	add_child(pause_menu)
	pause_menu.restart_requested.connect(func() -> void: restart_requested.emit())
	diagnostics = DIAGNOSTICS.instantiate()
	diagnostics.player = player
	diagnostics.director = director
	frame.add_child(diagnostics)
	notice = Label.new()
	notice.name = "Notice"
	notice.modulate.a = 1.0 if OS.get_cmdline_args().has("--debug-instructions") else 0.0
	notice.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	notice.offset_top = 38.0
	notice.offset_bottom = 145.0
	notice.offset_left = -390.0
	notice.offset_right = 390.0
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.add_theme_font_size_override("font_size", 25)
	notice.add_theme_color_override("font_color", Color("f2e4b4"))
	notice.add_theme_color_override("font_shadow_color", Color.BLACK)
	notice.add_theme_constant_override("shadow_offset_x", 2)
	notice.add_theme_constant_override("shadow_offset_y", 2)
	notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notice.hide()
	frame.add_child(notice)
	# Pausable, so a notice does not expire behind the pause menu.
	notice_timer = Timer.new()
	notice_timer.name = "NoticeTimer"
	notice_timer.one_shot = true
	notice_timer.timeout.connect(notice.hide)
	add_child(notice_timer)
	last_safe = player.global_transform
	player.combat_message.connect(func(text: String) -> void: show_notice(text, 2.5))
	if player.weapon != null:
		weapon_readout = WeaponReadout.new()
		weapon_readout.name = "WeaponReadout"
		weapon_readout.weapon = player.weapon
		frame.add_child(weapon_readout)
		var lock_indicator: Control = preload("res://systems/combat/lock_indicator.gd").new()
		lock_indicator.name = "LockIndicator"
		lock_indicator.weapon = player.weapon
		frame.add_child(lock_indicator)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"inventory") and not event.is_echo() and not get_tree().paused and player.can_use_weapon() and not get_tree().root.has_node("DoorTransition"):
		get_viewport().set_input_as_handled()
		inventory_menu.open()

func _physics_process(_delta: float) -> void:
	if player.is_dead():
		return
	# The room under the player goes on the site plan (the MAP tab).
	var scene := get_tree().current_scene
	if scene != null:
		AreaMap.track(scene.scene_file_path, player.global_position)
	if player.global_position.y < recovery_height:
		recover()
	elif player.is_on_floor():
		last_safe = player.global_transform

## Safety net for leaving the geometry: back to the last spot actually stood on.
func recover() -> void:
	player.reset_to(last_safe)
	show_notice("Recovery: returned to the last safe position.", 3.0)
	recovered.emit(last_safe.origin)

## Seconds ≤ 0 keep the notice until something hides it.
func show_notice(text: String, seconds: float = 0.0) -> void:
	notice.text = text
	notice.modulate.a = 1.0
	notice.show()
	if seconds > 0.0:
		notice_timer.start(seconds)
	else:
		notice_timer.stop()

func hide_notice() -> void:
	notice_timer.stop()
	notice.hide()

## Called by the level after it teleports the actor on purpose, so the net does
## not send them back to where they were before the restart.
func mark_safe() -> void:
	last_safe = player.global_transform
