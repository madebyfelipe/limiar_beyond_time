extends SceneTree
## Run: Godot --headless --path . --script res://tools/measure_clip_speeds.gd
## Native ground speed and travel direction of each locomotion clip: the
## planted (lowest) toe's horizontal velocity, in world metres, with the body
## held still. A forward walk slides the foot backwards (towards +Z of the model).
func _init() -> void:
	call_deferred("run")
func run() -> void:
	var scene: Node = load("res://environments/firing_range.tscn").instantiate()
	root.add_child(scene)
	for i in range(8):
		await physics_frame
	var player: PlayerController = scene.player
	player.set_physics_process(false)
	var visual: Node3D = player.visual.get_node("DylanVisual")
	visual.set_process(false)
	var animator: AnimationPlayer = visual.animator
	var skeleton: Skeleton3D = visual.skeleton
	var toes: Array[int] = [skeleton.find_bone("mixamorig_LeftToeBase"), skeleton.find_bone("mixamorig_RightToeBase")]
	var model: Node3D = visual.model
	for clip: StringName in [&"walk", &"run", &"walk_back", &"aim_walk", &"aim_walk_back", &"strafe_left", &"strafe_right", &"rifle_walk", &"rifle_run", &"rifle_walk_back", &"rifle_aim_walk", &"rifle_aim_walk_back", &"rifle_strafe_left", &"rifle_strafe_right"]:
		if not animator.has_animation(clip):
			print(clip, " MISSING")
			continue
		animator.play(clip, 0.0)
		animator.speed_scale = 1.0
		animator.seek(0.0, true)
		var length: float = animator.get_animation(clip).length
		var dt := 1.0 / 60.0
		var prev := {}
		var speeds: Array[float] = []
		var dir_sum := Vector3.ZERO
		var t := 0.0
		while t < length * 2.0:
			animator.advance(dt)
			t += dt
			var lowest := -1
			var low_y := INF
			var pos := {}
			for b in toes:
				var w: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(b).origin
				pos[b] = w
				if w.y < low_y:
					low_y = w.y
					lowest = b
			if prev.has(lowest):
				var v: Vector3 = (pos[lowest] - prev[lowest]) / dt
				v.y = 0
				speeds.append(v.length())
				dir_sum += v
			prev = pos
		speeds.sort()
		var med: float = speeds[speeds.size() / 2]
		# Foot slide direction in the model's own frame (captures face +Z).
		var local: Vector3 = model.global_basis.inverse() * dir_sum.normalized()
		print("%-20s native=%.2f m/s  foot_slide_model=(%.2f, %.2f)  table=%s" % [clip, med, local.x, local.z, str(visual.NATIVE_SPEED.get(clip, "-"))])
	quit()
