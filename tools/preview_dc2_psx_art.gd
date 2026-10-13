extends SceneTree
## Capture every active campaign plate with the live actor, without UI/filter.
const OUTPUT := "res://.local/dc2-psx/"

func _initialize() -> void:
	call_deferred("run")

func prepare(path: String) -> Node:
	var scene = load(path).instantiate()
	root.add_child(scene)
	current_scene = scene
	scene.player.control_enabled = false
	RetroFilter.set_enabled(scene, false)
	scene.operation.hud.set_process(false)
	scene.operation.hud.hide()
	scene.operation.set_physics_process(false)
	scene.operation.notice.hide()
	if scene.operation.weapon_readout != null:
		scene.operation.weapon_readout.hide()
	return scene

func capture(label: String) -> void:
	for frame: int in range(8):
		await process_frame
	current_scene.operation.notice.hide()
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(OUTPUT + label + ".png") == OK)
	print("DC2_PREVIEW ", label)

func run() -> void:
	root.size = Vector2i(1920, 1080)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var exterior = prepare("res://environments/exterior.tscn")
	exterior.director.set_physics_process(false)
	var exterior_points := [Vector3(0,0.06,21), Vector3(0,0.06,7), Vector3(-4.45,0.66,3.7), Vector3(0,0.06,-5.5)]
	for index: int in range(exterior.shots.size()):
		exterior.player.reset_to(Transform3D(Basis.IDENTITY, exterior_points[index]))
		exterior.director.reset_to(exterior.shots[index])
		await capture("exterior_cam%02d" % (index + 1))
	exterior.queue_free()
	await process_frame
	var guardhouse = prepare("res://environments/save_room.tscn")
	guardhouse.player.reset_to(Transform3D(Basis.IDENTITY, guardhouse.TERMINAL_APPROACH))
	await capture("guardhouse_cam01")
	guardhouse.queue_free()
	await process_frame
	var trail = prepare("res://environments/perimeter.tscn")
	trail.director.set_physics_process(false)
	for animal in trail.kelekens:
		animal.hide()
		animal.set_physics_process(false)
	for wander in trail.keleken_wanders:
		wander.set_physics_process(false)
	var trail_points := [Vector3(0,0.06,-3), Vector3(1.2,0.06,-15), Vector3(1.6,0.06,-23.6), Vector3(2.4,0.06,-33.2)]
	for index: int in range(trail.shots.size()):
		trail.player.reset_to(Transform3D(Basis.IDENTITY, trail_points[index]))
		trail.director.reset_to(trail.shots[index])
		await capture("perimeter_cam%02d" % (index + 1))
	trail.queue_free()
	await process_frame
	MissionState.restore(MissionState.Stage.RELAY_ROOM)
	var room = prepare("res://environments/relay_room.tscn")
	room.player.reset_to(Transform3D(Basis.IDENTITY, room.TERMINAL_APPROACH))
	await capture("relay_powered")
	room._apply_power(false)
	room._emergency_pulse.kill()
	room.emergency_light.light_energy = 1.2
	await capture("relay_outage")
	room.player.hide()
	room.cutscene_camera.make_current()
	room._refresh_art()
	await capture("relay_window")
	print("DC2_PREVIEW cameras=12")
	quit()
