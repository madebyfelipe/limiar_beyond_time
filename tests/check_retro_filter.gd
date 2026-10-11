extends SceneTree
## GPU evidence: real scene, real F4 events, framebuffer sampling and live resize.
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func capture() -> Image:
	for frame: int in range(5):
		await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func press_f4(echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_F4
	event.pressed = true
	event.echo = echo
	root.push_input(event)
	event = InputEventKey.new()
	event.physical_keycode = KEY_F4
	root.push_input(event)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Retro probe requires a graphical renderer")
		quit(1)
		return
	create_timer(90).timeout.connect(func() -> void: quit(124))
	root.size = Vector2i(1280, 720)
	var room: Node = load("res://environments/save_room.tscn").instantiate()
	root.add_child(room)
	await capture()
	room.process_mode = Node.PROCESS_MODE_DISABLED
	var filter: Control = room.get_node("Frame/Composition/RetroFilter")
	check(filter.selected_mode == 1, "PSX should be the default")
	press_f4(true)
	check(filter.selected_mode == 1, "Key repeat changed the mode")
	press_f4()
	check(filter.selected_mode == 2, "F4 did not select CRT")
	press_f4()
	check(filter.selected_mode == 0, "F4 did not select original")
	filter.mode_notice.hide()
	filter.notice_seconds = 0
	var original: Image = await capture()
	filter.set_mode(1)
	var psx: Image = await capture()
	check(original.get_data() != psx.get_data(), "PSX filter had no visible effect")
	filter.set_mode(2)
	var crt: Image = await capture()
	check(psx.get_data() != crt.get_data(), "CRT scanlines had no visible effect")
	filter.set_mode(0)
	var restored: Image = await capture()
	check(original.get_data() == restored.get_data(), "Original image was not fully restored")
	for pair: Array in [["original", original], ["psx", psx], ["crt", crt]]:
		check(pair[1].save_png("res://.local/retro-%s.png" % pair[0]) == OK, "Could not save retro comparison")
	filter.set_mode(1)
	for dimensions: Vector2i in [Vector2i(1280,720), Vector2i(1920,1080), Vector2i(1280,960)]:
		root.size = dimensions
		var image: Image = await capture()
		var block: int = dimensions.x / 320
		var top: int = (dimensions.y - block * 180) / 2
		var varied_blocks: int = 0
		# Avoid HUD; test interior pixels of hundreds of virtual pixels.
		for y: int in range(45, 150, 3):
			for x: int in range(40, 280, 3):
				if image.get_pixel(x * block + 1, top + y * block + 1) != image.get_pixel(x * block + block - 2, top + y * block + block - 2):
					varied_blocks += 1
		check(varied_blocks == 0, "Virtual pixels are not aligned at %s: %d blocks" % [dimensions, varied_blocks])
		if top > 0:
			check(image.get_pixel(640,60) == Color.BLACK and image.get_pixel(640,900) == Color.BLACK, "Filter contaminated letterbox bars")
		print("RETRO window=", dimensions, " inconsistent_blocks=", varied_blocks)
	# New gameplay instances must keep the chosen mode.
	filter.set_mode(2)
	room.queue_free()
	await process_frame
	room = load("res://environments/exterior.tscn").instantiate()
	root.add_child(room)
	await capture()
	filter = room.get_node("Frame/Composition/RetroFilter")
	check(filter.selected_mode == 2 and filter.effect.material.get_shader_parameter("crt_enabled"), "Filter selection lost between scenes")
	filter.set_mode(1)
	print("RETRO failures=", failures)
	quit(0 if failures == 0 else 1)
