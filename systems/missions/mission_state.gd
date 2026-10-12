class_name MissionState
extends RefCounted
## The Fase 1 objective, shared by the exterior and the guardhouse. Static, so
## it survives the door transition without an autoload, as ControlScheme and
## SaveGame already do. The terminal stores it, so a resumed session resumes the
## objective too and not only the position.

enum Stage {
	## On the road, before the gate.
	ROAD,
	## Past the gate, heading for the guardhouse door.
	YARD,
	## Inside, with the terminal still unused.
	TERMINAL,
	## Recorded at the terminal: the Fase 1 content is done.
	DONE,
}

const OBJECTIVES := {
	Stage.ROAD: "Siga a estrada nevada até a cancela.",
	Stage.YARD: "Atravesse o pátio e suba até a porta da guarita.",
	Stage.TERMINAL: "Registre o progresso no terminal da mesa.",
	Stage.DONE: "Objetivo cumprido. O terminal guardou o progresso.",
}

static var stage: Stage = Stage.ROAD

## Moves forward only. A player who walks back out of the gate has already seen
## that objective, and flipping the line back would read as losing progress.
static func reach(next: Stage) -> bool:
	if next <= stage:
		return false
	stage = next
	return true

static func restore(value: int) -> void:
	stage = (value as Stage) if value >= Stage.ROAD and value <= Stage.DONE else Stage.ROAD

static func reset() -> void:
	stage = Stage.ROAD

static func objective() -> String:
	return OBJECTIVES[stage]
