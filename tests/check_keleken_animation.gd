extends SceneTree
## Validate the real baked rig, skin and planted feet, independent of the authoring solver.
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", message)
func _initialize() -> void:
	call_deferred("run")
func set_pose(visual: KelekenVisual, clip: StringName, time: float) -> void:
	visual.animator.play(clip, 0)
	visual.animator.seek(time, true)
	visual.animator.pause()
func deform(mesh: MeshInstance3D, skeleton: Skeleton3D, arrays: Array, vertex: int) -> Vector3:
	var p: Vector3 = arrays[Mesh.ARRAY_VERTEX][vertex]
	var result := Vector3.ZERO
	for influence in range(4):
		var bind: int = arrays[Mesh.ARRAY_BONES][vertex * 4 + influence]
		var weight: float = arrays[Mesh.ARRAY_WEIGHTS][vertex * 4 + influence]
		if weight == 0:
			continue
		var bone: int = mesh.skin.get_bind_bone(bind)
		if bone < 0:
			bone = skeleton.find_bone(mesh.skin.get_bind_name(bind))
		result += (skeleton.get_bone_global_pose(bone) * mesh.skin.get_bind_pose(bind) * p) * weight
	return result
func run() -> void:
	var actor: KelekenActor = load("res://actors/keleken/keleken.tscn").instantiate()
	root.add_child(actor)
	actor.set_physics_process(false)
	var visual := actor.visual
	var skeleton := visual.skeleton
	var mesh: MeshInstance3D = skeleton.get_node("KelekenMesh")
	var arrays := mesh.mesh.surface_get_arrays(0)
	check(skeleton.get_bone_count() == 24, "Expected 24 deform bones")
	check(skeleton.get_bone_global_rest(skeleton.find_bone("head")).origin.z < skeleton.get_bone_global_rest(skeleton.find_bone("pelvis")).origin.z, "Visual front is not -Z")
	check(mesh.get_active_material(0).get("albedo_texture") != null, "Source texture missing")
	for vertex in arrays[Mesh.ARRAY_VERTEX].size():
		var sum := 0.0
		for influence in range(4):
			sum += arrays[Mesh.ARRAY_WEIGHTS][vertex * 4 + influence]
		check(absf(sum - 1) < .001, "Unnormalized weights at vertex %d" % vertex)
	var durations := {&"idle": 6.4, &"walk": 1.2, &"run": .8, &"look": 2.4, &"alert": 1.2, &"attack_beak": 1., &"recover": 1., &"hit": .5, &"death": 1.6}
	# Counted from the exported library, so an extra or missing clip shows up.
	var visual_clip_count: int = visual.animator.get_animation_list().size()
	check(visual_clip_count == durations.size(), "Exported %d clips, expected %d" % [visual_clip_count, durations.size()])
	for clip: StringName in durations:
		check(visual.animator.has_animation(clip), "Missing " + str(clip))
		if not visual.animator.has_animation(clip):
			continue
		var duration := visual.animator.get_animation(clip).length
		check(absf(duration - float(durations[clip])) < .001, "Wrong duration for %s: %.4f" % [clip, duration])
		# Death ends lying down by design; every other clip loops or returns.
		if clip == &"death":
			continue
		set_pose(visual, clip, 0)
		var first: Array[Transform3D] = []
		for bone in skeleton.get_bone_count():
			first.append(skeleton.get_bone_global_pose(bone))
		set_pose(visual, clip, duration)
		for bone in skeleton.get_bone_count():
			var last := skeleton.get_bone_global_pose(bone)
			check(first[bone].origin.distance_to(last.origin) < .001, "Loop/return translation seam in %s:%s" % [clip, skeleton.get_bone_name(bone)])
			check(first[bone].basis.get_rotation_quaternion().angle_to(last.basis.get_rotation_quaternion()) < .003, "Loop/return rotation seam in %s:%s" % [clip, skeleton.get_bone_name(bone)])
	# The revised bird gestures must actually reach the exported head, not just
	# exist on an authoring controller that never reaches the game skeleton.
	for clip: StringName in [&"idle", &"look", &"walk"]:
		var yaw_min := INF
		var yaw_max := -INF
		var z_min := INF
		var z_max := -INF
		var y_min := INF
		var y_max := -INF
		var duration := visual.animator.get_animation(clip).length
		for frame in range(121):
			set_pose(visual, clip, duration * frame / 120.)
			var head := skeleton.get_bone_global_pose(skeleton.find_bone("head"))
			var facing := head.basis.y.normalized()
			var yaw := atan2(-facing.x, -facing.z)
			yaw_min = minf(yaw_min, yaw)
			yaw_max = maxf(yaw_max, yaw)
			z_min = minf(z_min, head.origin.z)
			z_max = maxf(z_max, head.origin.z)
			y_min = minf(y_min, head.origin.y)
			y_max = maxf(y_max, head.origin.y)
		check(yaw_max - yaw_min > (.14 if clip == &"walk" else .35), "Exported head is rigid in " + str(clip))
		if clip == &"walk":
			check(z_max - z_min > .06, "Walking neck does not advance/retract")
			check(y_max - y_min < .16, "Walking head bounces excessively")
		print("KELEKEN_HEAD %s yaw_span=%.1f deg forward_span=%.3f height_span=%.3f" % [clip, rad_to_deg(yaw_max - yaw_min), z_max - z_min, y_max - y_min])
	# Ground contact measured on baked toes, compensating the actor's translation.
	for clip: StringName in [&"walk", &"run"]:
		var speed: float = KelekenVisual.NATIVE_SPEED[clip]
		var duration := visual.animator.get_animation(clip).length
		var stance := .60 if clip == &"walk" else .42
		var worst_drift := 0.0
		var worst_y := 0.0
		var min_skin_y := INF
		for side: String in ["L", "R"]:
			var bone := skeleton.find_bone("toes." + side)
			check(bone >= 0, "Missing toes." + side)
			if bone < 0:
				continue
			var previous := Vector3.ZERO
			var prior_contact := false
			for frame in range(121):
				var time := duration * frame / 120.0
				var phase := fposmod(time / duration + (0.0 if side == "L" else .5), 1.0)
				set_pose(visual, clip, time)
				var p := skeleton.get_bone_global_pose(bone).origin
				p.z -= speed * time
				var contact := phase > .04 and phase < stance - .04
				if contact:
					worst_y = maxf(worst_y, absf(p.y - .139263802))
					if prior_contact:
						worst_drift = maxf(worst_drift, Vector2(p.x - previous.x, p.z - previous.z).length() / (duration / 120.0))
				previous = p
				prior_contact = contact
				if side == "L" and frame % 6 == 0:
					for vertex in arrays[Mesh.ARRAY_VERTEX].size():
						var deformed := deform(mesh, skeleton, arrays, vertex)
						check(deformed.is_finite(), "Non-finite skin vertex")
						min_skin_y = minf(min_skin_y, deformed.y)
		check(worst_drift < .18, "%s planted toe drift %.3f m/s" % [clip, worst_drift])
		check(worst_y < .025, "%s contact height error %.3f m" % [clip, worst_y])
		check(min_skin_y > -.035, "%s skin below ground %.3f m" % [clip, min_skin_y])
		print("KELEKEN_CONTACT %s drift=%.4f height_error=%.4f min_skin_y=%.4f" % [clip, worst_drift, worst_y, min_skin_y])
		visual.play_clip(clip, speed * 1.5, 0)
		check(absf(visual.animator.speed_scale - 1.5) < .001, "Cadence does not follow speed")
	# The hit must move the body visibly at its peak, not only exist.
	set_pose(visual, &"hit", .1)
	var recoil: float = skeleton.get_bone_global_pose(skeleton.find_bone("head")).origin.distance_to(skeleton.get_bone_global_rest(skeleton.find_bone("head")).origin)
	check(recoil > .08, "Hit reaction barely moves the head: %.3f m" % recoil)
	# Death: the head comes down near the ground, the feet stay where they stood
	# and the skin does not sink through the floor.
	set_pose(visual, &"death", 0)
	var toes_before: Array[Vector3] = []
	for side: String in ["L", "R"]:
		toes_before.append(skeleton.get_bone_global_pose(skeleton.find_bone("toes." + side)).origin)
	set_pose(visual, &"death", 1.6)
	var head_end: Vector3 = skeleton.get_bone_global_pose(skeleton.find_bone("head")).origin
	var pelvis_end: Vector3 = skeleton.get_bone_global_pose(skeleton.find_bone("pelvis")).origin
	var toe_slide := 0.0
	for index: int in range(2):
		toe_slide = maxf(toe_slide, skeleton.get_bone_global_pose(skeleton.find_bone("toes." + ["L", "R"][index])).origin.distance_to(toes_before[index]))
	var lowest := INF
	for vertex in arrays[Mesh.ARRAY_VERTEX].size():
		lowest = minf(lowest, deform(mesh, skeleton, arrays, vertex).y)
	check(head_end.y < .7, "Dead head stays up at %.2f m" % head_end.y)
	check(pelvis_end.y < .7, "Dead body does not go down: pelvis %.2f m" % pelvis_end.y)
	check(toe_slide < .05, "Feet slide while dying: %.3f m" % toe_slide)
	check(lowest > -.06, "Dead body sinks through the floor: %.3f m" % lowest)
	print("KELEKEN_DEATH head_y=%.3f pelvis_y=%.3f toe_slide=%.4f lowest=%.4f hit_recoil=%.3f" % [head_end.y, pelvis_end.y, toe_slide, lowest, recoil])
	visual.play_clip(&"attack_beak", -1, 0)
	visual.animator.advance(1.2)
	check(visual.clip == &"idle", "One-shot did not return to idle")
	check(visual.beak.get_parent() is BoneAttachment3D, "Beak is not bound to head")
	actor.queue_free()
	await process_frame
	# Exercise the actual physics/cadence path in the review scene as well.
	var study: Node3D = load("res://environments/keleken_animation_study.tscn").instantiate()
	root.add_child(study)
	for clip: StringName in [&"walk", &"run"]:
		study.select_clip(clip)
		for frame in range(30):
			await process_frame
		var previous: Dictionary = {}
		var worst := 0.0
		var samples := 0
		for frame in range(100):
			await process_frame
			var current: KelekenVisual = study.actor.visual
			var duration := current.animator.get_animation(clip).length
			var stance := .60 if clip == &"walk" else .42
			for side: String in ["L", "R"]:
				var phase := fposmod(current.animator.current_animation_position / duration + (0.0 if side == "L" else .5), 1.0)
				var position: Vector3 = current.skeleton.global_transform * current.skeleton.get_bone_global_pose(current.skeleton.find_bone("toes." + side)).origin
				var contact := phase > .08 and phase < stance - .08
				if contact and previous.has(side):
					var data: Dictionary = previous[side]
					if data.contact:
						worst = maxf(worst, Vector2(position.x - data.position.x, position.z - data.position.z).length() / study.get_process_delta_time())
						samples += 1
				previous[side] = {"position": position, "contact": contact}
		check(samples > 10, "No runtime foot contact samples for " + str(clip))
		check(worst < .22, "Runtime toe drift %s %.3f m/s" % [clip, worst])
		check(absf(study.actor.position.y) < .015, "Collision lifts or sinks the visual origin")
		print("KELEKEN_RUNTIME %s drift=%.4f samples=%d" % [clip, worst, samples])
	print("KELEKEN animation bones=24 clips=%d failures=%d" % [visual_clip_count, failures])
	quit(1 if failures else 0)
