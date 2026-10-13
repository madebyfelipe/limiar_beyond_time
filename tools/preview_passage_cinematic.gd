extends SceneTree
## Stills of the door and gate cinematics at chosen moments of the capture,
## without the filter, for visual review. No scene change, no saves.
##   godot --path . --script res://tools/preview_passage_cinematic.gd
##   ... -- gate 2.4 3.0 4.0     one passage, chosen moments
const MOMENTS: Array[float] = [1.75, 2.4, 2.8, 3.1, 3.5, 3.9, 4.2]

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1920, 1080)
	var passages: Array[StringName] = [&"door", &"gate"]
	var moments: Array[float] = MOMENTS
	var chosen: PackedStringArray = OS.get_cmdline_user_args()
	if chosen.size() > 0:
		passages = [StringName(chosen[0])]
	if chosen.size() > 1:
		moments = []
		for index: int in range(1, chosen.size()):
			moments.append(float(chosen[index]))
	for passage: StringName in passages:
		var transition = load("res://systems/interaction/door_transition.gd").new()
		transition.passage = passage
		root.add_child(transition)
		transition.get_child(0).show()
		transition.curtain.modulate.a = 0.0
		transition.retro_filter.hide()
		transition.region_title.text = "PERIMETER TRAIL" if passage == &"gate" else "RELAY ROOM"
		for moment: float in moments:
			transition.pose_at(moment)
			for frame: int in range(4):
				await process_frame
			await RenderingServer.frame_post_draw
			var path: String = "res://.local/passage-%s-%.2f.png" % [passage, moment]
			assert(root.get_texture().get_image().save_png(path) == OK)
			var angles: PackedStringArray = []
			for leaf in transition.leaves:
				angles.append("%.1f" % rad_to_deg(leaf.angle))
			print("PASSAGE %s t=%.2f leaves=[%s] right_palm=%v left_palm=%v hips=%v" % [passage, moment, ", ".join(angles), transition.palm(transition.RIGHT_HAND), transition.palm(transition.LEFT_HAND), transition.bone_position("Hips")])
		transition.free()
	quit()
