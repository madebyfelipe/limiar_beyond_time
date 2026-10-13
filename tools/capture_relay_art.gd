extends SceneTree
## Capture the authored cameras and lighting without actors, HUD or retro filter.
const ROOM_DIR := "res://assets/backgrounds/relay_room/"

func _initialize() -> void:
	call_deferred("run")

func capture(scene: Node, path: String) -> void:
	for frame: int in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	var viewport: SubViewport = scene.get_node("Frame/Composition/Actors/WorldViewport")
	assert(viewport.get_texture().get_image().save_png(path) == OK)
	print("ART_REFERENCE ", path)

func run() -> void:
	root.size = Vector2i(1920, 1080)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOM_DIR))
	MissionState.restore(MissionState.Stage.RELAY_ROOM)
	var room = load("res://environments/relay_room.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	room.set_art_mode(false)
	room.player.hide()
	room.player.set_physics_process(false)
	await capture(room, ROOM_DIR + "geometry_powered.png")
	room._apply_power(false)
	room._emergency_pulse.kill()
	room.emergency_light.light_energy = 1.2
	await capture(room, ROOM_DIR + "geometry_outage.png")
	room.cutscene_camera.make_current()
	await capture(room, ROOM_DIR + "geometry_window.png")
	room.queue_free()
	await process_frame
	var trail = load("res://environments/perimeter.tscn").instantiate()
	root.add_child(trail)
	current_scene = trail
	trail.player.hide()
	trail.player.set_physics_process(false)
	trail.keleken.hide()
	trail.keleken.set_physics_process(false)
	trail.set_art_mode(false)
	trail.director.set_physics_process(false)
	trail.director.reset_to(trail.shots[3])
	await capture(trail, "res://assets/backgrounds/perimeter/geometry_cam04.png")
	trail.director.reset_to(trail.shots[1])
	await capture(trail, "res://assets/backgrounds/perimeter/geometry_cam02_current.png")
	quit()
