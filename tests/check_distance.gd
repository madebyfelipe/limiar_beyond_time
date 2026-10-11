extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	create_timer(10).timeout.connect(func() -> void: quit(124))
	var scene: Control = load("res://environments/locomotion.tscn").instantiate()
	root.add_child(scene)
	var player: PlayerController = scene.get_node("Frame/Composition/Actors/WorldViewport/World/Player")
	player.process_physics_priority = -10
	var sampler: Node = Node.new()
	sampler.set_script(load("res://tests/distance_sampler.gd"))
	sampler.player = player
	root.add_child(sampler)
	# Reassert deterministic input before each real physics tick. Window focus
	# changes can release synthetic key events during graphical test runs.
	physics_frame.connect(func() -> void:
		if sampler.frames >= 10 and sampler.frames < 130:
			for action: String in ["move_left","move_right","move_down","run"]:
				Input.action_release(action)
			Input.action_press("move_up")
	)
