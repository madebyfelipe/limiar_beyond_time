extends SceneTree
## Hip speed of the run-to-stop captures, sampled every STEP s of their kept
## window, in the capture's own metres per second: DylanVisual.STOP_PROFILES.
## The built clips freeze that travel (`plant`); the body brakes along it instead.
## Run: Godot --headless --path . --script res://tools/measure_stop_profiles.gd
const STEP := 0.05
const WINDOWS := {"run_stop": [0.0, 0.9], "rifle_run_stop": [0.5, 1.47]}
func _init() -> void:
	for file: String in WINDOWS:
		var scene: Node = load("res://assets/models/dylan_protagonist/mixamo/%s.fbx" % file).instantiate()
		var player: AnimationPlayer = scene.find_children("*", "AnimationPlayer", true, false)[0]
		var anim: Animation = player.get_animation(player.get_animation_list()[0])
		var track := -1
		for t in range(anim.get_track_count()):
			if anim.track_get_type(t) == Animation.TYPE_POSITION_3D and str(anim.track_get_path(t)).ends_with("mixamorig_Hips"):
				track = t
		var from: float = WINDOWS[file][0]
		var to: float = minf(WINDOWS[file][1], anim.length)
		var speeds: Array[String] = []
		var travel := 0.0
		var t := from
		while t <= to + 0.0001:
			var a: Vector3 = anim.position_track_interpolate(track, maxf(from, t - STEP * 0.5))
			var b: Vector3 = anim.position_track_interpolate(track, minf(to, t + STEP * 0.5))
			var span: float = minf(to, t + STEP * 0.5) - maxf(from, t - STEP * 0.5)
			var v: float = Vector2(b.x - a.x, b.z - a.z).length() / span
			speeds.append("%.2f" % v)
			t += STEP
		var start: Vector3 = anim.position_track_interpolate(track, from)
		var end: Vector3 = anim.position_track_interpolate(track, to)
		print("%s travel=%.2f m (capture) speeds=[%s]" % [file, Vector2(end.x - start.x, end.z - start.z).length(), ", ".join(speeds)])
		scene.free()
	quit()
