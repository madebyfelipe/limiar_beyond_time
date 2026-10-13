class_name MissionState
extends RefCounted
## The pilot objective, shared by every authored level. Static, so it survives
## the door transitions without an autoload, as ControlScheme and SaveGame
## already do. The terminal stores it, so a resumed session resumes the
## objective too and not only the position.
##
## Stage values are written into the save file: append new ones at the end and
## never reorder, or a stored record would resume on a different objective.
## `Phase` groups these stages into the playable phases they belong to.

enum Stage {
	## On the road, before the gate.
	ROAD,
	## Past the gate, heading for the guardhouse door.
	YARD,
	## Inside, with the terminal still unused.
	TERMINAL,
	## Recorded at the terminal: the guardhouse content is done and the north
	## service gate is released.
	DONE,
	## Past the gate, on the perimeter trail.
	PERIMETER,
	## At the relay shed; its door now opens.
	RELAY,
	## Inside the relay room, with the operator's log still unread.
	RELAY_ROOM,
	## The log was read and the power went out: leave by the rear door.
	OUTAGE,
	## Out behind the shed, where the authored content currently stops.
	REAR_YARD,
}

const OBJECTIVES := {
	Stage.ROAD: "Follow the snowy road to the gate.",
	Stage.YARD: "Cross the yard and climb to the guardhouse door.",
	Stage.TERMINAL: "Save your progress at the desk terminal.",
	Stage.DONE: "Progress saved. Leave the yard by the north service gate.",
	Stage.PERIMETER: "Follow the perimeter trail north to the relay shed.",
	Stage.RELAY: "Relay shed reached. Go inside.",
	Stage.RELAY_ROOM: "Check the relay terminal for the operator's last log.",
	Stage.OUTAGE: "The power is out and something is outside. Leave by the rear door.",
	Stage.REAR_YARD: "Behind the relay shed. The authored content ends here for now.",
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
	stage = (value as Stage) if value >= Stage.ROAD and value <= Stage.REAR_YARD else Stage.ROAD

static func reset() -> void:
	stage = Stage.ROAD

static func objective() -> String:
	return OBJECTIVES[stage]
