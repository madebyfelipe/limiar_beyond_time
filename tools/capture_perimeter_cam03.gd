extends SceneTree
## Capture the current playable camera, without rebuilding source or camera data.
## godot --path . --script res://tools/capture_perimeter_cam03.gd
const OUTPUT := "res://assets/backgrounds/perimeter/geometry_cam03_current.png"

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1920, 1080)
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
	trail.director.reset_to(trail.shots[2])
	for frame: int in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	var viewport: SubViewport = trail.get_node("Frame/Composition/Actors/WorldViewport")
	assert(viewport.get_texture().get_image().save_png(OUTPUT) == OK)
	print("ART_REFERENCE ", OUTPUT)
	quit()
