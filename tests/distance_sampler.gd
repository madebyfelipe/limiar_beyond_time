extends Node
var player: PlayerController
var frames: int = 0
var start: Vector3
var elapsed: float = 0.0
var pressed_ticks: int = 0
var integrated: float = 0.0
func _physics_process(delta: float) -> void:
	frames += 1
	if frames > 10:
		elapsed += delta
		integrated += -player.velocity.z * delta
		if Input.is_action_pressed("move_up"):
			pressed_ticks += 1
	if frames == 10:
		for action: String in ["move_left","move_right","move_up","move_down","run"]:
			Input.action_release(action)
		player.global_position = Vector3(-2,0.05,2)
		player.velocity = Vector3.ZERO
		start = player.global_position
		var key: InputEventKey = InputEventKey.new()
		key.physical_keycode = KEY_W
		key.pressed = true
		Input.parse_input_event(key)
		print("T03 initial input=",Input.get_vector("move_left","move_right","move_up","move_down"))
	if frames == 130:
		var distance: float = start.z - player.global_position.z
		# 120 ticks from rest, integrated the way move_toward ramps each tick,
		# so the expectation follows PlayerConfig instead of a frozen constant.
		var expected: float = _expected(120, delta)
		print("T03 fixed-duration ticks=120 render_limit=",Engine.max_fps," distance=",distance," expected=",expected," elapsed=",elapsed," pressed=",pressed_ticks," integrated=",integrated," pos=",player.global_position)
		print("T03 final input=",Input.get_vector("move_left","move_right","move_up","move_down")," direction=",player.desired_direction)
		Input.action_release("move_up")
		get_tree().quit(0 if absf(distance - expected) < 0.01 else 1)

func _expected(ticks: int, delta: float) -> float:
	var step: float = player.config.acceleration * delta
	var speed: float = 0.0
	var distance: float = 0.0
	for tick: int in range(ticks):
		speed = minf(player.config.walk_speed, speed + step)
		distance += speed * delta
	return distance
