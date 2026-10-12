@tool
extends SceneTree
## Prints length, hip travel and heading change of each dodge candidate capture.
## Run: Godot --headless --path . --script res://tools/probe_dodge_captures.gd

const FILES := ["dodge_right", "dodge_back", "roll_stand"]

func _init() -> void:
	for file: String in FILES:
		var scene: Node = (load("res://assets/models/dylan_protagonist/mixamo/%s.fbx" % file) as PackedScene).instantiate()
		var player := scene.find_child("AnimationPlayer", true, false) as AnimationPlayer
		var clip: Animation = player.get_animation(player.get_animation_list()[0])
		var pos := -1
		var rot := -1
		for t: int in range(clip.get_track_count()):
			if str(clip.track_get_path(t)).ends_with(":mixamorig_Hips"):
				if clip.track_get_type(t) == Animation.TYPE_POSITION_3D: pos = t
				if clip.track_get_type(t) == Animation.TYPE_ROTATION_3D: rot = t
		var line := "%-20s %.2fs" % [file, clip.length]
		if pos >= 0:
			var a: Vector3 = clip.position_track_interpolate(pos, 0.0)
			var b: Vector3 = clip.position_track_interpolate(pos, clip.length)
			var low := a.y
			var peak := Vector3.ZERO
			for i: int in range(31):
				var p: Vector3 = clip.position_track_interpolate(pos, clip.length * i / 30.0)
				low = minf(low, p.y)
				if Vector2(p.x - a.x, p.z - a.z).length() > Vector2(peak.x, peak.z).length():
					peak = p - a
			line += "  travel end=(%+.2f,%+.2f) peak=(%+.2f,%+.2f) hip_y %.2f->min %.2f" % [b.x - a.x, b.z - a.z, peak.x, peak.z, a.y, low]
		if rot >= 0:
			var ya: float = Basis(clip.rotation_track_interpolate(rot, 0.0)).get_euler().y
			var yb: float = Basis(clip.rotation_track_interpolate(rot, clip.length)).get_euler().y
			line += "  yaw %+.0f°" % rad_to_deg(wrapf(yb - ya, -PI, PI))
		print(line)
		scene.free()
	quit()
