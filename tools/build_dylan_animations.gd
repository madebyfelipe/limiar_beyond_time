@tool
extends SceneTree
## Assembles the Mixamo captures into one library consumed by dylan_visual.gd.
## Run: Godot --headless --path . --script res://tools/build_dylan_animations.gd
## The FBX files stay untouched; every edit happens on the copies saved here.

const OUTPUT := "res://assets/models/dylan_protagonist/mixamo/dylan_clips.res"
const SOURCE := "res://assets/models/dylan_protagonist/mixamo/%s.fbx"
const SAMPLE_RATE := 30.0
const HIPS := ":mixamorig_Hips"

## Clip name -> source file and what has to be done to the capture.
##   from/to  window kept, in seconds of the capture
##   plant    freeze the horizontal travel of the hips
##   unturn   remove the body rotation, leaving only the footwork
##   stitch   cross-fade the tail over the head so the window loops seamlessly
##   optional skip with a note while the capture has not been downloaded yet;
##            DylanVisual.play_scripted falls back for a missing clip
const CLIPS := {
	&"idle": {"file": "dylan_rig_idle", "loop": true},
	&"walk": {"file": "walk", "loop": true},
	&"run": {"file": "run", "loop": true},
	&"walk_back": {"file": "walk_back", "loop": true},
	# Dodges, exported from Mixamo on Dylan's own rig. Each window runs from the
	# first shift of weight to the settle, since the controller compresses the
	# whole clip into the 0,32 s escape.
	# "Dodging Right" (in place) and its mirror for the sidesteps.
	&"dodge_right": {"file": "dodge_right", "loop": false, "from": 0.1, "to": 1.1, "plant": true},
	&"dodge_left": {"file": "dodge_right", "loop": false, "from": 0.1, "to": 1.1, "plant": true, "mirror": true},
	# The backstep. Replaced on request: a new capture dropped in as
	# dodge_back_v2.fbx takes over the slot; until then "Dodging Back" (Jumping
	# Backwards Dodge) stays, the hop without the idle around it. Set the window
	# of the new capture after looking at it (tools/render_dodge_candidates.gd).
	&"dodge_back": {"file": "dodge_back", "loop": false, "from": 0.35, "to": 1.75, "plant": true,
		"replacement": {"file": "dodge_back_v2", "loop": false, "plant": true}},
	# "Stand To Roll": crouch, dive roll and the rise back to standing.
	&"dodge_forward": {"file": "roll_stand", "loop": false, "from": 0.45, "to": 1.95, "plant": true},
	# The capture walks up, opens and crosses in 6,37 s. Only the reach and the
	# push survive, matching the 0,72 s gesture stage in door_transition.gd.
	&"door_interact": {"file": "door_open", "loop": false, "from": 2.48, "to": 3.2, "plant": true},
	# A single 110° turn, not a cycle. The window below is the stretch whose end
	# pose sits closest to its start; the controller owns the rotation itself, so
	# only the stepping is kept and the seam is stitched shut.
	# turn_a turns to the right, turn_b is its mirror; measured from the hips.
	&"turn_right": {"file": "turn_a", "loop": true, "from": 1.8, "to": 2.5, "plant": true, "unturn": true, "stitch": 0.25},
	&"turn_left": {"file": "turn_b", "loop": true, "from": 1.8, "to": 2.5, "plant": true, "unturn": true, "stitch": 0.25},
	# Relay room cutscene: Dylan starts back from the window when the animal
	# looks in (Mixamo "Startled", In Place). Played once and held on its end.
	&"startled": {"file": "startled", "loop": false, "plant": true, "optional": true},
}

func _init() -> void:
	var library := AnimationLibrary.new()
	for name: StringName in CLIPS:
		var spec: Dictionary = CLIPS[name]
		if spec.has("replacement") and ResourceLoader.exists(SOURCE % spec["replacement"]["file"]):
			spec = spec["replacement"]
		if spec.get("optional", false) and not ResourceLoader.exists(SOURCE % spec["file"]):
			print("%s: skipped, %s.fbx not captured yet" % [name, spec["file"]])
			continue
		var scene: Node = (load(SOURCE % spec["file"]) as PackedScene).instantiate()
		var player := scene.find_child("AnimationPlayer", true, false) as AnimationPlayer
		var source: Animation = player.get_animation(player.get_animation_list()[0])
		var clip: Animation = _window(source, spec.get("from", 0.0), spec.get("to", source.length),
			spec.get("plant", false), spec.get("unturn", false), spec.get("stitch", 0.0))
		clip.loop_mode = Animation.LOOP_LINEAR if spec["loop"] else Animation.LOOP_NONE
		if spec.get("mirror", false):
			_mirror(clip)
		library.add_animation(name, clip)
		print("%s: %.2fs, %d tracks" % [name, clip.length, clip.get_track_count()])
		scene.free()
	await _recentre(library)
	var error: int = ResourceSaver.save(library, OUTPUT)
	print("saved ", OUTPUT, " error=", error)
	quit(error)

## Reflect the capture across the sagittal plane and exchange paired bones.
func _mirror(clip: Animation) -> void:
	for track: int in range(clip.get_track_count()):
		var path := String(clip.track_get_path(track))
		path = path.replace("Left", "MirrorSide").replace("Right", "Left").replace("MirrorSide", "Right")
		clip.track_set_path(track, NodePath(path))
		for key: int in range(clip.track_get_key_count(track)):
			if clip.track_get_type(track) == Animation.TYPE_ROTATION_3D:
				var q: Quaternion = clip.track_get_key_value(track, key)
				clip.track_set_key_value(track, key, Quaternion(q.x, -q.y, -q.z, q.w))
			elif clip.track_get_type(track) == Animation.TYPE_POSITION_3D:
				var p: Vector3 = clip.track_get_key_value(track, key)
				clip.track_set_key_value(track, key, Vector3(-p.x, p.y, p.z))

## A windowed clip inherits whatever ground the actor had already covered, so a
## planted clip would drop the body away from where it stands. Each one is slid
## until its feet sit, on average, where the idle clip puts them.
func _recentre(library: AnimationLibrary) -> void:
	var rig: Node3D = (load(SOURCE % "dylan_rig_idle") as PackedScene).instantiate()
	get_root().add_child(rig)
	var skeleton := rig.find_child("Skeleton3D", true, false) as Skeleton3D
	var player := rig.find_child("AnimationPlayer", true, false) as AnimationPlayer
	player.remove_animation_library(&"")
	player.add_animation_library(&"", library)
	var reference: Vector2 = await _stance(player, skeleton, &"idle")
	for name: StringName in CLIPS:
		if not library.has_animation(name) or not CLIPS[name].get("plant", false):
			continue
		var stance: Vector2 = await _stance(player, skeleton, name)
		var shift: Vector2 = reference - stance
		var clip: Animation = library.get_animation(name)
		for track: int in range(clip.get_track_count()):
			if clip.track_get_type(track) != Animation.TYPE_POSITION_3D or not str(clip.track_get_path(track)).ends_with(HIPS):
				continue
			for key: int in range(clip.track_get_key_count(track)):
				var value: Vector3 = clip.track_get_key_value(track, key)
				clip.track_set_key_value(track, key, Vector3(value.x + shift.x, value.y, value.z + shift.y))
		print("%s: recentred by (%+.3f, %+.3f)" % [name, shift.x, shift.y])
	rig.free()

## Mean ground position of the two feet across a clip, in skeleton space.
func _stance(player: AnimationPlayer, skeleton: Skeleton3D, clip: StringName) -> Vector2:
	var animation: Animation = player.get_animation(clip)
	player.play(clip)
	var total := Vector2.ZERO
	var samples: int = 24
	for sample: int in range(samples + 1):
		player.seek(animation.length * float(sample) / float(samples), true)
		await process_frame
		for bone: String in ["mixamorig_LeftToeBase", "mixamorig_RightToeBase"]:
			var origin: Vector3 = skeleton.get_bone_global_pose(skeleton.find_bone(bone)).origin
			total += Vector2(origin.x, origin.z)
	return total / float((samples + 1) * 2)

## Resamples a time range into a new clip. Rebuilding the keys keeps the result
## independent of how the capture distributed them.
func _window(source: Animation, from: float, to: float, plant: bool, unturn: bool, stitch: float) -> Animation:
	var clip := Animation.new()
	var span: float = to - from
	# A stitched clip gives up its overlap: the tail is folded back over the head.
	var overlap: float = span * stitch
	clip.length = span - overlap
	var samples: int = maxi(2, int(round(clip.length * SAMPLE_RATE)) + 1)
	var hips_origin := Vector3.ZERO
	for track: int in range(source.get_track_count()):
		var path: NodePath = source.track_get_path(track)
		var type: int = source.track_get_type(track)
		if type != Animation.TYPE_POSITION_3D and type != Animation.TYPE_ROTATION_3D and type != Animation.TYPE_SCALE_3D:
			continue
		var is_hips: bool = str(path).ends_with(HIPS)
		var planted: bool = plant and type == Animation.TYPE_POSITION_3D and is_hips
		if planted:
			hips_origin = source.position_track_interpolate(track, from)
		var target: int = clip.add_track(type)
		clip.track_set_path(target, path)
		for sample: int in range(samples):
			var offset: float = clip.length * float(sample) / float(samples - 1)
			# Inside the overlap the pose comes from the tail, fading into the head.
			var weight: float = 1.0 if overlap <= 0.0 or offset >= overlap else smoothstep(0.0, 1.0, offset / overlap)
			var time: float = from + offset
			var tail: float = time + clip.length
			match type:
				Animation.TYPE_POSITION_3D:
					var position: Vector3 = source.position_track_interpolate(track, time)
					if weight < 1.0:
						position = source.position_track_interpolate(track, tail).lerp(position, weight)
					if planted:
						# Hold the body over its own feet; the controller owns ground travel.
						position = Vector3(hips_origin.x, position.y, hips_origin.z)
					clip.position_track_insert_key(target, offset, position)
				Animation.TYPE_ROTATION_3D:
					var rotation: Quaternion = _rotation(source, track, time, unturn and is_hips)
					if weight < 1.0:
						rotation = _rotation(source, track, tail, unturn and is_hips).slerp(rotation, weight)
					clip.rotation_track_insert_key(target, offset, rotation)
				Animation.TYPE_SCALE_3D:
					var scale: Vector3 = source.scale_track_interpolate(track, time)
					if weight < 1.0:
						scale = source.scale_track_interpolate(track, tail).lerp(scale, weight)
					clip.scale_track_insert_key(target, offset, scale)
	return clip

## Samples a rotation track. When asked, the body's heading is cancelled outright
## rather than merely frozen: a window taken from the middle of a turn starts
## already rotated, and keeping that would snap Dylan sideways the moment the
## pivot begins. What survives is the footwork; the controller owns the heading.
func _rotation(source: Animation, track: int, time: float, unturn: bool) -> Quaternion:
	var rotation: Quaternion = source.rotation_track_interpolate(track, time)
	if not unturn:
		return rotation
	return (Quaternion(Vector3.UP, -_yaw(rotation)) * rotation).normalized()

func _yaw(rotation: Quaternion) -> float:
	return Basis(rotation).get_euler().y
