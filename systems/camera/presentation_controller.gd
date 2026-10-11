class_name PresentationController
extends Node

@export var background: TextureRect
@export var player: PlayerController
@export var shots: Array[ShotRig] = []
var current_shot: ShotRig

func apply_shot(shot: ShotRig) -> void:
	# No await: the complete presentation changes before the next render.
	for rig: ShotRig in shots:
		rig.set_active(rig == shot)
	background.texture = shot.definition.background
	shot.camera.make_current()
	player.camera = shot.camera
	current_shot = shot
