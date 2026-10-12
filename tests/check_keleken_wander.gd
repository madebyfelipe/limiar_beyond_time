extends SceneTree
## Temporary exterior wander stays on the road and never drives camera cuts.
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	for seed_value in [7, 123, 932]:
		MissionState.reset()
		var exterior: Control = load("res://environments/exterior.tscn").instantiate()
		root.add_child(exterior)
		exterior.player.set_control_enabled(false)
		var npc: KelekenActor = exterior.keleken
		var wander: KelekenWander = exterior.keleken_wander
		wander.rng.seed = seed_value
		var distance := 0.0
		var walking_frames := 0
		var idle_frames := 0
		for frame in range(3600):
			var before := npc.position
			await physics_frame
			await process_frame
			distance += npc.position.distance_to(before)
			check(wander.bounds.grow(.02).has_point(Vector2(npc.position.x, npc.position.z)), "NPC left viewing area")
			check(absf(npc.position.y) < .12, "NPC lost floor contact")
			check(exterior.director.current_shot == exterior.shots[0], "NPC triggered a player camera cut")
			walking_frames += int(npc.visual.clip == &"walk")
			idle_frames += int(npc.visual.clip == &"idle")
		check(distance > 10, "NPC did not explore the area")
		check(wander.targets_chosen >= 4, "Too few random destinations")
		check(walking_frames > 300 and idle_frames > 30, "Walk/idle cycle missing")
		exterior.restart()
		check(npc.position.distance_to(Vector3(1.2, .06, 18)) < .01, "Restart did not reset NPC")
		print("KELEKEN_WANDER seed=%d distance=%.2f targets=%d walk=%d idle=%d" % [seed_value, distance, wander.targets_chosen, walking_frames, idle_frames])
		exterior.queue_free()
		await process_frame
	print("KELEKEN wander failures=%d" % failures)
	quit(1 if failures else 0)
