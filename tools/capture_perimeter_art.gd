extends SceneTree
## All current playable framings, with no actors/UI and no geometry rebuild.
## godot --path . --script res://tools/capture_perimeter_art.gd
const OUTPUT_DIR := "res://assets/backgrounds/perimeter/revised_geometry/"

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1920, 1080)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var trail = load("res://environments/perimeter.tscn").instantiate()
	root.add_child(trail)
	current_scene = trail
	trail.player.hide()
	trail.player.set_physics_process(false)
	for animal in trail.kelekens:
		animal.hide()
		animal.set_physics_process(false)
	for wander in trail.keleken_wanders:
		wander.set_physics_process(false)
	trail.set_art_mode(false)
	trail.director.set_physics_process(false)
	var viewport: SubViewport = trail.get_node("Frame/Composition/Actors/WorldViewport")
	for index: int in range(trail.shots.size()):
		trail.director.reset_to(trail.shots[index])
		for frame: int in range(8):
			await process_frame
		await RenderingServer.frame_post_draw
		var path := OUTPUT_DIR + "geometry_cam%02d.png" % (index + 1)
		assert(viewport.get_texture().get_image().save_png(path) == OK)
		print("ART_REFERENCE ", path)
	quit()
