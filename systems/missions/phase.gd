class_name Phase
extends RefCounted
## The ordered chain of playable phases. One phase is a block of authored
## content with its own entry scene, the stage that releases it and the stage
## that closes it. A gate, an on-screen label, a menu or a probe all read the
## order from here instead of each repeating "what comes after the guardhouse".
##
## Phases are declared, not discovered: adding a scene to `environments/` does
## not put it in the chain, and the stages come from `MissionState`, which the
## save file already stores.

var id: StringName
var title: String
var entry_scene: String
## Stage from which the phase can be entered at all. The first phase opens with
## the run; a later one opens on the stage that closed the phase before it.
var opens_at: MissionState.Stage
## Stage the phase reaches once the player is inside its content.
var first_stage: MissionState.Stage
## Stage that closes it, and releases whatever comes next.
var last_stage: MissionState.Stage

static var _chain: Array[Phase] = []

static func chain() -> Array[Phase]:
	if _chain.is_empty():
		_chain = [
			_declare(&"guardhouse", "Phase 1 — Guardhouse", "res://environments/exterior.tscn",
				MissionState.Stage.ROAD, MissionState.Stage.ROAD, MissionState.Stage.DONE),
			_declare(&"perimeter", "Phase 2 — Perimeter", "res://environments/perimeter.tscn",
				MissionState.Stage.DONE, MissionState.Stage.PERIMETER, MissionState.Stage.RELAY),
			# Opens on the shed door; closed by the outage that sends Dylan out the
			# back. REAR_YARD, past it, is the provisional end of the content.
			_declare(&"relay", "Phase 3 — Relay", "res://environments/relay_room.tscn",
				MissionState.Stage.RELAY, MissionState.Stage.RELAY_ROOM, MissionState.Stage.OUTAGE),
		]
	return _chain

static func _declare(id: StringName, title: String, entry_scene: String, opens_at: MissionState.Stage, first_stage: MissionState.Stage, last_stage: MissionState.Stage) -> Phase:
	var phase := Phase.new()
	phase.id = id
	phase.title = title
	phase.entry_scene = entry_scene
	phase.opens_at = opens_at
	phase.first_stage = first_stage
	phase.last_stage = last_stage
	return phase

static func find(id: StringName) -> Phase:
	for phase: Phase in chain():
		if phase.id == id:
			return phase
	return null

## The phase a stage belongs to, or the last one for a stage beyond the chain.
static func of_stage(stage: MissionState.Stage) -> Phase:
	var result: Phase = chain()[0]
	for phase: Phase in chain():
		if stage >= phase.first_stage:
			result = phase
	return result

static func current() -> Phase:
	return of_stage(MissionState.stage)

static func after(id: StringName) -> Phase:
	var phases: Array[Phase] = chain()
	for index: int in range(phases.size() - 1):
		if phases[index].id == id:
			return phases[index + 1]
	return null

## Released by progress: the phase before it has been closed.
func unlocked() -> bool:
	return MissionState.stage >= opens_at

## The player has been inside this phase's content.
func entered() -> bool:
	return MissionState.stage >= first_stage

func closed() -> bool:
	return MissionState.stage >= last_stage

## A fresh attempt of this phase: the objective returns to the stage its own
## content opens with, without undoing the phases that were closed before it.
func rewind() -> void:
	MissionState.restore(first_stage)
