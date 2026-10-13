extends SceneTree
## Renders a contact sheet per Mixamo capture on Dylan's skinned rig, to pick
## captures and windows for build_dylan_animations.gd.
## Run (graphical): Godot --path . --script res://tools/render_clip_candidates.gd -- <res://dir> [name ...]
## The folder may instead be a built AnimationLibrary (.res) to check the
## clips build_dylan_animations.gd produced. Without names every .fbx in the
## directory is rendered. A name may carry a
## window, name@from:to in seconds, to look closer at part of a capture.
## Output: .local/clip-candidates/<capture>.png, twelve frames side by side,
## each labelled in the console with its time step.

const FRAMES := 12
const SIZE := Vector2i(200, 260)
const OUT := "res://.local/clip-candidates"
const BUILD := preload("res://tools/build_dylan_animations.gd")

func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var folder: String = args[0] if args.size() > 0 else "res://assets/models/dylan_protagonist/mixamo"
	var files: Array[String] = []
	for name: String in args.slice(1):
		files.append(name)
	if files.is_empty():
		for file: String in DirAccess.get_files_at(folder):
			if file.ends_with(".fbx"):
				files.append(file.get_basename())
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var viewport := SubViewport.new()
	viewport.size = SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.own_world_3d = true
	get_root().add_child(viewport)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.32, 0.34, 0.38)
	env.environment.ambient_light_color = Color(0.7, 0.7, 0.7)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	viewport.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	viewport.add_child(sun)
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 40)
	floor.mesh = plane
	floor.position.y = -0.002
	viewport.add_child(floor)
	var camera := Camera3D.new()
	viewport.add_child(camera)
	camera.fov = 50

	var rig: Node3D = (load("res://assets/models/dylan_protagonist/mixamo/dylan_rig_idle.fbx") as PackedScene).instantiate()
	viewport.add_child(rig)
	var player := rig.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var skeleton := rig.find_child("Skeleton3D", true, false) as Skeleton3D
	var library := AnimationLibrary.new()
	if folder.ends_with(".res"):
		# A built library: render its clips by name instead of raw captures.
		library = (load(folder) as AnimationLibrary).duplicate()
		files = files.filter(func(name: String) -> bool: return library.has_animation(name.get_slice("@", 0)))
	for file: String in (files if not folder.ends_with(".res") else []):
		var scene: Node = (load("%s/%s.fbx" % [folder, file.get_slice("@", 0)]) as PackedScene).instantiate()
		var source := scene.find_child("AnimationPlayer", true, false) as AnimationPlayer
		library.add_animation(file.get_slice("@", 0), BUILD.metric(source.get_animation(source.get_animation_list()[0])).duplicate())
		scene.free()
	player.add_animation_library(&"cand", library)

	for file: String in files:
		var clip := StringName("cand/" + file.get_slice("@", 0))
		var start: float = 0.0
		var length: float = player.get_animation(clip).length
		if "@" in file:
			var window: String = file.get_slice("@", 1)
			start = window.get_slice(":", 0).to_float()
			length = minf(length, window.get_slice(":", 1).to_float()) - start
		var sheet := Image.create(SIZE.x * FRAMES, SIZE.y, false, Image.FORMAT_RGBA8)
		player.play(clip)
		for frame: int in range(FRAMES):
			player.seek(start + length * float(frame) / float(FRAMES - 1), true)
			player.pause()
			# Three-quarter front view that follows the hips; captures face +Z.
			var hips: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("mixamorig_Hips")).origin
			camera.look_at_from_position(Vector3(hips.x + 1.0, 0.75, hips.z + 1.7), Vector3(hips.x, 0.45, hips.z))
			if frame == 0:
				var toe: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("mixamorig_LeftToeBase")).origin
				print("%s hips %.3f toe %.3f" % [file, hips.y, toe.y])
			for i: int in range(3):
				await process_frame
			var shot := viewport.get_texture().get_image()
			shot.convert(Image.FORMAT_RGBA8)
			sheet.blit_rect(shot, Rect2i(Vector2i.ZERO, SIZE), Vector2i(frame * SIZE.x, 0))
		sheet.save_png(ProjectSettings.globalize_path("%s/%s.png" % [OUT, file.replace("@", "_").replace(":", "-")]))
		print("saved %s %.2fs step %.3fs" % [file, length, length / float(FRAMES - 1)])
	quit()
