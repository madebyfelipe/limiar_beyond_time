extends SceneTree
## Render the actual study scene and loop frames for a reviewable preview.
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	root.size = Vector2i(960, 640)
	var study: Node3D = load("res://environments/keleken_animation_study.tscn").instantiate()
	root.add_child(study)
	await process_frame
	study.set_process(false)
	study.actor.set_physics_process(false)
	study.camera.position = Vector3(5, 2.3, 3)
	study.camera.look_at(Vector3(0, 1.2, 0))
	var output := "res://.local/keleken-preview"
	DirAccess.make_dir_recursive_absolute(output)
	for clip: StringName in [&"idle", &"walk", &"run", &"alert", &"attack_beak"]:
		study.select_clip(clip)
		study.actor.visual.play_clip(clip, -1, 0)
		study.actor.visual.animator.pause()
		var duration: float = study.actor.visual.animator.get_animation(clip).length
		for phase in range(4):
			study.actor.visual.animator.seek(duration * phase / 4., true)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output + "/%s-%d.png" % [clip, phase])
	# Side view without UI for the animated GIF, including floor contact.
	for child in study.get_children():
		if child is CanvasLayer:
			child.visible = false
	root.size = Vector2i(640, 640)
	study.camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	study.camera.size = 3.3
	study.camera.position = Vector3(5, 1.9, .5)
	study.camera.look_at(Vector3(0, 1.2, -.05))
	for clip: StringName in [&"idle", &"walk", &"run"]:
		study.actor.visual.play_clip(clip, -1, 0)
		study.actor.visual.animator.pause()
		var duration: float = study.actor.visual.animator.get_animation(clip).length
		var speed: float = KelekenVisual.NATIVE_SPEED.get(clip, 0.0)
		var marks: Array[MeshInstance3D] = []
		for child in study.get_children():
			if child is MeshInstance3D:
				marks.append(child)
		var frames := 96 if clip == &"idle" else 36
		for frame in range(frames):
			study.actor.visual.animator.seek(duration * frame / frames, true)
			for index in marks.size():
				marks[index].position.z = (index - 16) * maxf(1., speed * duration) + speed * duration * frame / frames
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output + "/%s-loop-%02d.png" % [clip, frame])
	print("KELEKEN preview complete")
	quit()
