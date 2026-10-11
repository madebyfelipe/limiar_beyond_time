class_name DiagnosticsOverlay
extends PanelContainer
## F3 readout: frame rate, position, active shot and movement reference.
## Processes while paused, so the readout stays live under the pause menu.

@export var label: Label
## Wired by the level after it assembles its runtime nodes.
var player: PlayerController
var director: CameraDirector
var progress: RouteProgress
var frame_ms: float = 0.0

func _ready() -> void:
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_diagnostics"):
		visible = not visible
		if visible:
			label.text = describe()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	frame_ms = delta * 1000.0 if frame_ms == 0.0 else lerpf(frame_ms, delta * 1000.0, 0.1)
	if visible:
		label.text = describe()

func describe() -> String:
	if player == null or director == null:
		return "Diagnóstico indisponível"
	var p: Vector3 = player.global_position
	var reference: MovementReference = player.movement_reference
	var horizontal: float = Vector2(player.velocity.x, player.velocity.z).length()
	var shot: String = String(director.current_shot.definition.shot_id) if director.current_shot else "—"
	var candidate: String = "%s %s s" % [director.candidate.definition.shot_id, _n(director.candidate_time)] if director.candidate else "—"
	var lines: PackedStringArray = [
		"F3 · DIAGNÓSTICO",
		"FPS %d · quadro %s ms" % [Engine.get_frames_per_second(), _n(frame_ms)],
		"Posição  x %s · y %s · z %s" % [_n(p.x), _n(p.y), _n(p.z)],
		"Velocidade %s m/s · chão %s" % [_n(horizontal), "sim" if player.is_on_floor() else "não"],
		"Enquadramento %s · candidato %s" % [shot, candidate],
		"Referência %s · direita (%s; %s) · fundo (%s; %s)" % ["travada" if reference.locked else "livre", _n(reference.right.x), _n(reference.right.z), _n(reference.back.x), _n(reference.back.z)],
		"Direção desejada (%s; %s)" % [_n(player.desired_direction.x), _n(player.desired_direction.z)],
	]
	if progress:
		lines.append("Percurso %s · %s s" % [["ida", "volta", "concluído"][progress.stage], _n(progress.elapsed)])
	lines.append("Simulação %s" % ("pausada" if get_tree().paused else "ativa"))
	return "\n".join(lines)

func _n(value: float) -> String:
	return ("%.2f" % value).replace(".", ",")
