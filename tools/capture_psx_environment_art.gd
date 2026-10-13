extends SceneTree
## Fresh source plates for every authored game space; never rebuild geometry.
## Cropped exterior cameras export their full plate before runtime crop.
const OUTPUT := "res://assets/backgrounds/psx_geometry/"

func _initialize() -> void:
	call_deferred("run")

func capture(scene: Node, label: String) -> void:
	for frame: int in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	var viewport: SubViewport = scene.get_node("Frame/Composition/Actors/WorldViewport")
	var path := OUTPUT + label + ".png"
	assert(viewport.get_texture().get_image().save_png(path) == OK)
	print("PSX_REFERENCE ", path)

func prepare(path: String) -> Node:
	var scene = load(path).instantiate()
	root.add_child(scene)
	current_scene = scene
	scene.set_art_mode(false)
	scene.player.hide()
	scene.player.set_physics_process(false)
	return scene

func run() -> void:
	root.size = Vector2i(1920, 1080)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var exterior = prepare("res://environments/exterior.tscn")
	exterior.director.set_physics_process(false)
	for index: int in range(exterior.shots.size()):
		var shot: ShotRig = exterior.shots[index]
		shot.definition.zoom = 1.0
		shot.definition.focus = Vector2(0.5, 0.5)
		shot._apply_crop()
		exterior.director.reset_to(shot)
		await capture(exterior, "exterior_cam%02d" % (index + 1))
	exterior.queue_free()
	await process_frame
	var guardhouse = prepare("res://environments/save_room.tscn")
	await capture(guardhouse, "guardhouse_cam01")
	guardhouse.queue_free()
	await process_frame
	MissionState.restore(MissionState.Stage.RELAY_ROOM)
	var room = prepare("res://environments/relay_room.tscn")
	await capture(room, "relay_powered")
	room._apply_power(false)
	room._emergency_pulse.kill()
	room.emergency_light.light_energy = 1.2
	await capture(room, "relay_outage")
	room.cutscene_camera.make_current()
	await capture(room, "relay_window")
	quit()
