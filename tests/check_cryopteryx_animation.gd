extends SceneTree
## Validate the baked Cryopteryx: the reduced mesh, the rebuilt symmetric rig,
## its skin and the six retargeted clips, measured on the exported GLB and
## independent of the authoring solver.
##   godot --headless --path . --fixed-fps 60 --script res://tests/check_cryopteryx_animation.gd
const MANIFEST := "res://assets/models/cryopteryx/animation_manifest.json"
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", message)

func _initialize() -> void:
	call_deferred("run")

func set_pose(visual: CryopteryxVisual, clip: StringName, time: float) -> void:
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

func lowest(mesh: MeshInstance3D, skeleton: Skeleton3D, arrays: Array) -> float:
	var result := INF
	for vertex in arrays[Mesh.ARRAY_VERTEX].size():
		result = minf(result, deform(mesh, skeleton, arrays, vertex).y)
	return result

## Whether the foot is inside its measured stance, `margin` in from both ends.
func planted(manifest: Dictionary, clip: StringName, side: String, phase: float, margin: float) -> bool:
	var window: Array = manifest["clips"][str(clip)]["contact"][side]
	var span: float = fposmod(float(window[1]) - float(window[0]), 1.0)
	var into: float = fposmod(phase - float(window[0]), 1.0)
	return span > 2.0 * margin and into > margin and into < span - margin

func run() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	var visual := CryopteryxVisual.new()
	# Mesh/rig measurements below are in the exported asset's metres.
	visual.target_length = CryopteryxVisual.SOURCE_LENGTH
	root.add_child(visual)
	var skeleton := visual.skeleton
	var bones := skeleton.get_bone_count()
	var mesh: MeshInstance3D = skeleton.get_node("CryopteryxMesh")
	var arrays := mesh.mesh.surface_get_arrays(0)
	# The reduction: a few thousand triangles where the original had a million.
	var triangles: int = arrays[Mesh.ARRAY_INDEX].size() / 3
	check(triangles == int(manifest["triangles"]) and triangles <= 6000, "Mesh has %d triangles, the build wrote %d" % [triangles, int(manifest["triangles"])])
	check(mesh.get_active_material(0).get("albedo_texture") != null, "Source texture missing")
	var bounds := AABB(arrays[Mesh.ARRAY_VERTEX][0], Vector3.ZERO)
	for point: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
		bounds = bounds.expand(point)
	check(absf(bounds.size.z - CryopteryxVisual.SOURCE_LENGTH) < 0.02, "Model is %.3f m long, not %.1f" % [bounds.size.z, CryopteryxVisual.SOURCE_LENGTH])
	check(absf(bounds.size.z - float(manifest["length_m"])) < 0.005, "Length differs from the manifest")
	# The new rig: its own bones, facing -Z, and one side the mirror of the other.
	check(skeleton.get_bone_count() == 26 and skeleton.get_bone_count() == (manifest["bones"] as Array).size(), "Expected 26 deform bones, found %d" % skeleton.get_bone_count())
	for index in skeleton.get_bone_count():
		check(not skeleton.get_bone_name(index).contains("tripo"), "A bone of the discarded auto-rig survived: " + skeleton.get_bone_name(index))
	check(skeleton.get_bone_global_rest(skeleton.find_bone("head")).origin.z < skeleton.get_bone_global_rest(skeleton.find_bone("pelvis")).origin.z, "Visual front is not -Z")
	var mirrored := 0
	var worst_mirror := 0.0
	for index in skeleton.get_bone_count():
		var bone_name := skeleton.get_bone_name(index)
		if not bone_name.ends_with(".L"):
			continue
		var other := skeleton.find_bone(bone_name.trim_suffix(".L") + ".R")
		check(other >= 0, "No right-hand bone for " + bone_name)
		if other < 0:
			continue
		mirrored += 1
		var left := skeleton.get_bone_global_rest(index).origin
		var right := skeleton.get_bone_global_rest(other).origin
		worst_mirror = maxf(worst_mirror, left.distance_to(Vector3(-right.x, right.y, right.z)))
	check(mirrored == 7, "Expected 7 paired bones a side, found %d" % mirrored)
	check(worst_mirror < 0.001, "Left and right rest joints differ by %.4f m" % worst_mirror)
	for name: String in ["pelvis", "spine", "chest", "neck_01", "neck_02", "head", "tail_01", "tail_05"]:
		check(absf(skeleton.get_bone_global_rest(skeleton.find_bone(name)).origin.x) < 0.001, name + " is off the midline")
	for vertex in arrays[Mesh.ARRAY_VERTEX].size():
		var sum := 0.0
		for influence in range(4):
			sum += arrays[Mesh.ARRAY_WEIGHTS][vertex * 4 + influence]
		check(absf(sum - 1) < .001, "Unnormalized weights at vertex %d" % vertex)
	# Standing: both feet on the floor, neither sunk nor hovering.
	skeleton.reset_bone_poses()
	var feet := {"L": INF, "R": INF}
	for vertex in arrays[Mesh.ARRAY_VERTEX].size():
		var point: Vector3 = arrays[Mesh.ARRAY_VERTEX][vertex]
		var side := "L" if point.x < 0 else "R"
		feet[side] = minf(feet[side], point.y)
	check(absf(feet["L"]) < 0.03 and absf(feet["R"]) < 0.03, "Standing feet are not on the floor: L %.3f R %.3f" % [feet["L"], feet["R"]])
	var hip := skeleton.get_bone_global_rest(skeleton.find_bone("thigh.L")).origin.y
	check(absf(hip - float(manifest["hip_height_m"])) < 0.005, "Hip height %.3f differs from the manifest" % hip)
	# Clips: counted from the exported library, with the durations of the build.
	var clips: Dictionary = manifest["clips"]
	var exported: int = visual.animator.get_animation_list().size()
	check(exported == clips.size() and exported == 6, "Exported %d clips, expected 6" % exported)
	for clip_name: String in clips:
		var clip := StringName(clip_name)
		check(visual.animator.has_animation(clip), "Missing " + clip_name)
		if not visual.animator.has_animation(clip):
			continue
		var duration := visual.animator.get_animation(clip).length
		check(absf(duration - float(clips[clip_name]["frames"]) / float(manifest["fps"])) < .001, "Wrong duration for %s: %.4f" % [clip_name, duration])
		check((clip in CryopteryxVisual.LOOPING) == bool(clips[clip_name]["loop"]), "Loop flag of %s differs from the build" % clip_name)
		if not clip in CryopteryxVisual.LOOPING:
			continue
		set_pose(visual, clip, 0)
		var first: Array[Transform3D] = []
		for bone in skeleton.get_bone_count():
			first.append(skeleton.get_bone_global_pose(bone))
		set_pose(visual, clip, duration)
		for bone in skeleton.get_bone_count():
			var last := skeleton.get_bone_global_pose(bone)
			check(first[bone].origin.distance_to(last.origin) < .002, "Loop translation seam in %s:%s (%.4f m)" % [clip_name, skeleton.get_bone_name(bone), first[bone].origin.distance_to(last.origin)])
			check(first[bone].basis.get_rotation_quaternion().angle_to(last.basis.get_rotation_quaternion()) < .006, "Loop rotation seam in %s:%s" % [clip_name, skeleton.get_bone_name(bone)])
	for clip: StringName in CryopteryxVisual.NATIVE_SPEED:
		check(is_equal_approx(float(CryopteryxVisual.NATIVE_SPEED[clip]), float(clips[str(clip)]["speed"])), "NATIVE_SPEED of %s is not the build's %.3f" % [clip, float(clips[str(clip)]["speed"])])
	# The idle breathes: the retargeted trunk and tail reach the exported bones.
	var idle := visual.animator.get_animation(&"idle").length
	var tail_low := INF
	var tail_high := -INF
	for frame in range(61):
		set_pose(visual, &"idle", idle * frame / 60.0)
		var tip := skeleton.get_bone_global_pose(skeleton.find_bone("tail_05")).origin
		tail_low = minf(tail_low, tip.y)
		tail_high = maxf(tail_high, tip.y)
	check(tail_high - tail_low > 0.02, "Idle tail is rigid: %.4f m" % (tail_high - tail_low))
	# Ground contact measured on the baked toes, compensating the travel.
	var ball: float = skeleton.get_bone_global_rest(skeleton.find_bone("toes.L")).origin.y
	for clip: StringName in [&"walk", &"run"]:
		var speed: float = CryopteryxVisual.NATIVE_SPEED[clip]
		var duration := visual.animator.get_animation(clip).length
		var worst_drift := 0.0
		var worst_y := 0.0
		var min_skin_y := INF
		for side: String in ["L", "R"]:
			var bone := skeleton.find_bone("toes." + side)
			var previous := Vector3.ZERO
			var prior_contact := false
			for frame in range(121):
				var time := duration * frame / 120.0
				set_pose(visual, clip, time)
				var p := skeleton.get_bone_global_pose(bone).origin
				p.z -= speed * time
				var contact := planted(manifest, clip, side, time / duration, .04)
				if contact:
					worst_y = maxf(worst_y, absf(p.y - ball))
					if prior_contact:
						worst_drift = maxf(worst_drift, Vector2(p.x - previous.x, p.z - previous.z).length() / (duration / 120.0))
				previous = p
				prior_contact = contact
				if side == "L" and frame % 6 == 0:
					min_skin_y = minf(min_skin_y, lowest(mesh, skeleton, arrays))
		# Sampled every 1/120 of the cycle, a millimetre of interpolation between
		# baked keys already reads as 0,2 m/s on the run: a tenth of the clip's own
		# speed, and never above 0,18 m/s for the slow one.
		check(worst_drift < maxf(.18, .1 * speed), "%s planted toe drift %.3f m/s" % [clip, worst_drift])
		check(worst_y < .025, "%s contact height error %.3f m" % [clip, worst_y])
		check(min_skin_y > -.06, "%s skin below ground %.3f m" % [clip, min_skin_y])
		print("CRYOPTERYX_CONTACT %s drift=%.4f height_error=%.4f min_skin_y=%.4f" % [clip, worst_drift, worst_y, min_skin_y])
		visual.play_clip(clip, speed * 1.5, 0)
		check(absf(visual.animator.speed_scale - 1.5) < .001, "Cadence does not follow speed")
	# Attack: the head goes out at the moment the build recorded.
	var head := skeleton.find_bone("head")
	var attack := visual.animator.get_animation(&"attack").length
	set_pose(visual, &"attack", 0)
	var head_start := skeleton.get_bone_global_pose(head).origin
	set_pose(visual, &"attack", attack * float(clips["attack"]["strike"]))
	var reach: float = head_start.z - skeleton.get_bone_global_pose(head).origin.z
	check(reach > 0.25, "The strike barely moves the head forward: %.3f m" % reach)
	var furthest := 0.0
	for frame in range(61):
		set_pose(visual, &"attack", attack * frame / 60.0)
		furthest = maxf(furthest, head_start.z - skeleton.get_bone_global_pose(head).origin.z)
	check(reach > furthest - 0.03, "The recorded strike (%.3f m) is not the furthest reach (%.3f m)" % [reach, furthest])
	# Jump: the body leaves the floor and comes back to it.
	var jump := visual.animator.get_animation(&"jump").length
	var pelvis := skeleton.find_bone("pelvis")
	var rest_pelvis := skeleton.get_bone_global_rest(pelvis).origin.y
	var peak := -INF
	var clearance := -INF
	for frame in range(41):
		set_pose(visual, &"jump", jump * frame / 40.0)
		peak = maxf(peak, skeleton.get_bone_global_pose(pelvis).origin.y - rest_pelvis)
		clearance = maxf(clearance, minf(skeleton.get_bone_global_pose(skeleton.find_bone("toes.L")).origin.y, skeleton.get_bone_global_pose(skeleton.find_bone("toes.R")).origin.y) - ball)
	check(peak > 0.25 and clearance > 0.15, "The jump does not leave the floor: pelvis +%.3f m, feet +%.3f m" % [peak, clearance])
	set_pose(visual, &"jump", jump)
	check(lowest(mesh, skeleton, arrays) > -.06, "The jump lands under the floor")
	# Death: the body goes down, stays above the floor and the feet stay near.
	set_pose(visual, &"death", 0)
	var toes_before: Array[Vector3] = []
	for side: String in ["L", "R"]:
		toes_before.append(skeleton.get_bone_global_pose(skeleton.find_bone("toes." + side)).origin)
	var death := visual.animator.get_animation(&"death").length
	set_pose(visual, &"death", death)
	var head_end: Vector3 = skeleton.get_bone_global_pose(head).origin
	var pelvis_end: Vector3 = skeleton.get_bone_global_pose(pelvis).origin
	var toe_slide := 0.0
	for index: int in range(2):
		toe_slide = maxf(toe_slide, skeleton.get_bone_global_pose(skeleton.find_bone("toes." + ["L", "R"][index])).origin.distance_to(toes_before[index]))
	var sunk := lowest(mesh, skeleton, arrays)
	check(head_end.y < .6, "Dead head stays up at %.2f m" % head_end.y)
	check(pelvis_end.y < .6, "Dead body does not go down: pelvis %.2f m" % pelvis_end.y)
	check(toe_slide < 1.2, "Feet fly off while dying: %.3f m" % toe_slide)
	check(sunk > -.06, "Dead body sinks through the floor: %.3f m" % sunk)
	print("CRYOPTERYX_ACTIONS strike_reach=%.3f jump_pelvis=%.3f jump_feet=%.3f death_head_y=%.3f death_pelvis_y=%.3f death_toe_slide=%.3f death_lowest=%.4f" % [reach, peak, clearance, head_end.y, pelvis_end.y, toe_slide, sunk])
	# One-shots hand back to idle; the death does not get up.
	visual.play_clip(&"attack", -1, 0)
	visual.animator.advance(attack + 0.2)
	check(visual.clip == &"idle", "The attack did not return to idle")
	visual.play_clip(&"death", -1, 0)
	visual.animator.advance(death + 0.5)
	check(visual.clip == &"death", "The dead animal went back to idle")
	visual.queue_free()
	await process_frame
	# The review scene: the lane moves at the cycle's own speed, so the planted
	# toes stand still in the world.
	var study: Node3D = load("res://environments/cryopteryx_animation_study.tscn").instantiate()
	root.add_child(study)
	check(not study.travel and study.references.visible, "The study must open with the size comparison")
	check(study.visual.target_length == 8.5, "The study Cryopteryx lost its relative size")
	check(is_equal_approx(study.references.get_node("Keleken").target_height / 2.4, 2.4 / 1.8), "The Keleken is not 2.4 m relative to 1.8 m Dylan")
	# Compare the standing pose, not the source rest pose's raised tail tip.
	set_pose(study.visual, &"idle", 0.5)
	var study_mesh: MeshInstance3D = study.visual.skeleton.get_node("CryopteryxMesh")
	var cryo_height := 0.0
	for vertex in arrays[Mesh.ARRAY_VERTEX].size():
		cryo_height = maxf(cryo_height, deform(study_mesh, study.visual.skeleton, arrays, vertex).y * study.visual.target_length / CryopteryxVisual.SOURCE_LENGTH)
	check(cryo_height > 3.2 and cryo_height < 3.2 * 1.15, "Cryopteryx must be slightly taller than Keleken")
	check(study.references.get_node("PlayerReference/Visual/DylanVisual").target_height == 2.4, "The player reference changed scale")
	study.set_travel(true)
	var scale_factor: float = study.visual.target_length / CryopteryxVisual.SOURCE_LENGTH
	for clip: StringName in [&"walk", &"run"]:
		study.select_clip(clip)
		for frame in range(30):
			await process_frame
		check(is_equal_approx(study.speed, float(CryopteryxVisual.NATIVE_SPEED[clip]) * scale_factor), "The lane does not move at the scaled speed of " + str(clip))
		var previous: Dictionary = {}
		var worst := 0.0
		var samples := 0
		for frame in range(100):
			await process_frame
			var current: CryopteryxVisual = study.visual
			var duration := current.animator.get_animation(clip).length
			for side: String in ["L", "R"]:
				var phase := fposmod(current.animator.current_animation_position / duration, 1.0)
				var position: Vector3 = current.skeleton.global_transform * current.skeleton.get_bone_global_pose(current.skeleton.find_bone("toes." + side)).origin
				var contact := planted(manifest, clip, side, phase, .08)
				if contact and previous.has(side):
					var data: Dictionary = previous[side]
					# The lane wraps from one end to the other: not a slide.
					if data.contact and absf(position.z - data.position.z) < 5.0:
						worst = maxf(worst, Vector2(position.x - data.position.x, position.z - data.position.z).length() / study.get_process_delta_time())
						samples += 1
				previous[side] = {"position": position, "contact": contact}
		check(samples > 10, "No runtime foot contact samples for " + str(clip))
		check(worst / scale_factor < maxf(.22, .1 * float(CryopteryxVisual.NATIVE_SPEED[clip])), "Runtime toe drift %s %.3f m/s" % [clip, worst])
		print("CRYOPTERYX_RUNTIME %s drift=%.4f samples=%d" % [clip, worst, samples])
	study.select_clip(&"jump")
	for frame in range(120):
		await process_frame
	check(study.selected == &"idle" and is_zero_approx(study.speed), "The study did not settle on idle after a one-shot")
	print("CRYOPTERYX animation bones=%d clips=%d triangles=%d failures=%d" % [bones, exported, triangles, failures])
	quit(1 if failures else 0)
