extends CameraDirector
## The road/guardhouse handoff is defined by the actor's center, so camera
## residence time cannot carry navigation past the user-selected entry point.
var entry_x: float = 8.5
var road_shot: ShotRig
var guardhouse_shot: ShotRig

func _physics_process(delta: float) -> void:
	if current_shot == road_shot:
		candidate = null
		candidate_time = 0
		if player.position.x <= entry_x:
			_activate(guardhouse_shot)
		return
	if current_shot == guardhouse_shot and player.position.x >= entry_x + 0.05:
		candidate = null
		candidate_time = 0
		_activate(road_shot)
		return
	super._physics_process(delta)
