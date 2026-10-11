class_name CameraDirector
extends Node

signal shot_changed(previous_id: StringName, current_id: StringName)

@export var player: PlayerController
@export var zones: Array[CameraZone] = []
@export var initial_shot: ShotRig
@export var presentation: PresentationController
@export_range(0.0, 2.0) var minimum_residence: float = 0.2
var current_shot: ShotRig
var candidate: ShotRig
var candidate_time: float = 0.0

func _ready() -> void:
	_activate(initial_shot)

func _physics_process(delta: float) -> void:
	var selected: ShotRig = null
	var highest: int = -2147483648
	for zone: CameraZone in zones:
		if not zone.get_overlapping_bodies().has(player):
			continue
		if zone.shot_priority > highest:
			highest = zone.shot_priority
			selected = zone.shot
		elif zone.shot_priority == highest and zone.shot == current_shot:
			selected = current_shot
	if selected == null or selected == current_shot:
		candidate = null
		candidate_time = 0.0
		return
	if selected != candidate:
		candidate = selected
		candidate_time = 0.0
	candidate_time += delta
	if candidate_time + 0.000001 >= minimum_residence:
		_activate(candidate)
		candidate = null
		candidate_time = 0.0

func _activate(shot: ShotRig) -> void:
	var previous: StringName = current_shot.definition.shot_id if current_shot else &""
	presentation.apply_shot(shot)
	current_shot = shot
	shot_changed.emit(previous, shot.definition.shot_id)
