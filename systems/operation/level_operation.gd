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
## Last place the actor stood on the floor; where the safety net returns them.
var last_safe: Transform3D

func _ready() -> void:
	var hud_layer := CanvasLayer.new()
	hud_layer.layer = 8
	add_child(hud_layer)
	hud = GameHud.new()
	hud.player = player
	hud_layer.add_child(hud)
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

func _physics_process(_delta: float) -> void:
	if player.global_position.y < recovery_height:
		recover()
	elif player.is_on_floor():
		last_safe = player.global_transform

## Safety net for leaving the geometry: back to the last spot actually stood on.
func recover() -> void:
	player.reset_to(last_safe)
	show_notice("Recuperação: personagem devolvido ao último ponto firme.", 3.0)
	recovered.emit(last_safe.origin)

## Seconds ≤ 0 keep the notice until something hides it.
func show_notice(text: String, seconds: float = 0.0) -> void:
	notice.text = text
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
