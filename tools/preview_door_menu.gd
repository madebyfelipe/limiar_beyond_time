extends SceneTree
## Deterministic visual review of authored materials and menu layout; no saves.
func _initialize() -> void:
	call_deferred("run")

func capture(label: String) -> void:
	for frame: int in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://.local/review-"+label+".png") == OK)

func run() -> void:
	root.size = Vector2i(1920,1080)
	var transition = load("res://systems/interaction/door_transition.gd").new()
	root.add_child(transition)
	transition.get_child(0).show()
	transition.curtain.modulate.a = 0.0
	transition.retro_filter.hide()
	transition.region_title.text = "GUARDHOUSE"
	await capture("door-closed")
	transition.hinge.rotation.y = -0.75
	await capture("door-opening")
	root.size = Vector2i(1280,960)
	transition.region_title.text = "PERIMETER TRAIL"
	await capture("door-4x3")
	transition.free()
	var menu = load("res://ui/pause_menu.tscn").instantiate()
	menu.pause_on_focus_loss = false
	root.add_child(menu)
	root.size = Vector2i(1920,1080)
	menu.open()
	await capture("pause")
	menu.filter_button.pressed.emit()
	await capture("presentation")
	menu._close_filter_page()
	menu.gameplay_button.pressed.emit()
	await capture("gameplay")
	menu._close_gameplay_page()
	menu.settings_button.pressed.emit()
	await capture("settings")
	root.size = Vector2i(1280,960)
	await capture("settings-4x3")
	menu.close()
	menu.free()
	print("DOOR AND MENU visual captures complete")
	quit()
