extends SceneTree
## Renders a contact sheet per dodge candidate on Dylan's skinned rig.
## Run (graphical): Godot --path . --script res://tools/render_dodge_candidates.gd
## Output: .local/dodge-candidates/<capture>.png, twelve frames side by side,
## used to pick the windows in build_dylan_animations.gd.

const FILES := ["dodge_right", "dodge_back", "roll_stand"]
const FRAMES := 12
const SIZE := Vector2i(200, 260)
const OUT := "res://.local/dodge-candidates"

func _init() -> void:
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
	plane.size = Vector2(8, 8)
	floor.mesh = plane
	viewport.add_child(floor)
	var camera := Camera3D.new()
	viewport.add_child(camera)
	# Three-quarter front view; captures face +Z.
	camera.look_at_from_position(Vector3(1.6, 1.0, 2.6), Vector3(0, 0.5, 0.3))
	camera.fov = 50

	var rig: Node3D = (load("res://assets/models/dylan_protagonist/mixamo/dylan_rig_idle.fbx") as PackedScene).instantiate()
	viewport.add_child(rig)
	var player := rig.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var skeleton := rig.find_child("Skeleton3D", true, false) as Skeleton3D
	var library := AnimationLibrary.new()
	for file: String in FILES:
		var scene: Node = (load("res://assets/models/dylan_protagonist/mixamo/%s.fbx" % file) as PackedScene).instantiate()
		var source := scene.find_child("AnimationPlayer", true, false) as AnimationPlayer
		library.add_animation(file, source.get_animation(source.get_animation_list()[0]).duplicate())
		scene.free()
	player.add_animation_library(&"cand", library)

	for file: String in FILES:
		var clip := StringName("cand/" + file)
		var length: float = player.get_animation(clip).length
		var sheet := Image.create(SIZE.x * FRAMES, SIZE.y, false, Image.FORMAT_RGBA8)
		player.play(clip)
		for frame: int in range(FRAMES):
			player.seek(length * float(frame) / float(FRAMES - 1), true)
			player.pause()
			# Follow the hips so travelling captures stay framed.
			var hips: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("mixamorig_Hips")).origin
			camera.look_at_from_position(Vector3(hips.x + 1.6, 1.0, hips.z + 2.6), Vector3(hips.x, 0.5, hips.z + 0.3))
			for i: int in range(3):
				await process_frame
			var shot := viewport.get_texture().get_image()
			shot.convert(Image.FORMAT_RGBA8)
			sheet.blit_rect(shot, Rect2i(Vector2i.ZERO, SIZE), Vector2i(frame * SIZE.x, 0))
		sheet.save_png(ProjectSettings.globalize_path("%s/%s.png" % [OUT, file]))
		print("saved %s %.2fs step %.3fs" % [file, length, length / float(FRAMES - 1)])
	quit()
