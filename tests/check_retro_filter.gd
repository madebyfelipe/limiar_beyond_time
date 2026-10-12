extends SceneTree
## GPU evidence: real scene, real F4 events, framebuffer sampling and live resize.
## The presentation is assembled, not chosen from a list: one step for how coarse
## the picture is and one independent switch per effect. Each switch has to show
## on screen by itself, and the tube has to bulge without leaving a black frame.
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

## Pixels carrying no picture at all, which is what a glass edge would leave.
func black_pixels(image: Image) -> int:
	var total: int = 0
	for y: int in range(0, image.get_height(), 4):
		for x: int in range(0, image.get_width(), 4):
			if image.get_pixel(x, y) == Color.BLACK:
				total += 1
	return total

## Average brightness step between one row of the picture and the next. A
## detailed scene already differs pixel by pixel, so counting changed pixels
## says nothing; what scanlines add is a whole row going dark together.
func row_contrast(image: Image) -> float:
	var columns: PackedInt32Array = []
	for x: int in range(60, image.get_width() - 60, 29):
		columns.append(x)
	var previous: float = -1.0
	var total: float = 0.0
	var rows: int = 0
	for y: int in range(60, image.get_height() - 60):
		var mean: float = 0.0
		for x: int in columns:
			mean += image.get_pixel(x, y).get_luminance()
		mean /= float(columns.size())
		if previous >= 0.0:
			total += absf(mean - previous)
			rows += 1
		previous = mean
	return total / maxf(1.0, float(rows))

## Only one effect on at a time, so what changes on screen is attributable.
func only(filter: RetroFilter, id: int) -> void:
	for row: Dictionary in RetroFilter.EFFECTS:
		RetroFilter.set_effect(filter, int(row["id"]), int(row["id"]) == id)

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Retro probe requires a graphical renderer")
		quit(1)
		return
	create_timer(120).timeout.connect(func() -> void: quit(124))
	root.size = Vector2i(1280, 720)
	var room: Node = load("res://environments/save_room.tscn").instantiate()
	root.add_child(room)
	await capture()
	room.process_mode = Node.PROCESS_MODE_DISABLED
	var filter: RetroFilter = room.get_node("FilterLayer/RetroFilter")
	# --- Documented defaults ---
	check(RetroFilter.enabled, "The filter should start on")
	check(RetroFilter.pixel_name() == "médio", "Pixelation should start at 'médio', was '%s'" % RetroFilter.pixel_name())
	check(RetroFilter.is_effect_on(RetroFilter.Effect.COLOR), "Reduced colour should start on")
	for row: Dictionary in RetroFilter.EFFECTS:
		if int(row["id"]) != RetroFilter.Effect.COLOR:
			check(not RetroFilter.is_effect_on(int(row["id"])), "%s should start off" % row["name"])
	# --- F4 is the master switch, not a cycle ---
	press_f4(true)
	check(RetroFilter.enabled, "Key repeat switched the filter")
	press_f4()
	check(not RetroFilter.enabled, "F4 did not switch the filter off")
	filter.mode_notice.hide()
	filter.notice_seconds = 0
	var untouched: Image = await capture()
	press_f4()
	check(RetroFilter.enabled, "F4 did not switch the filter back on")
	filter.mode_notice.hide()
	filter.notice_seconds = 0
	# --- Each step of pixelation is its own picture ---
	var by_step: Array[Image] = []
	for step: int in range(RetroFilter.PIXEL_STEPS.size()):
		RetroFilter.set_pixel_step(filter, step)
		by_step.append(await capture())
	for a: int in range(by_step.size()):
		for b: int in range(a + 1, by_step.size()):
			check(by_step[a].get_data() != by_step[b].get_data(), "Pixelation steps %s and %s render identically" % [RetroFilter.PIXEL_STEPS[a]["name"], RetroFilter.PIXEL_STEPS[b]["name"]])
	# --- Each effect shows on its own, over the same picture ---
	RetroFilter.set_pixel_step(filter, 2)
	only(filter, -1)
	var bare: Image = await capture()
	var measured: Dictionary = {}
	for row: Dictionary in RetroFilter.EFFECTS:
		var id: int = int(row["id"])
		only(filter, id)
		var image: Image = await capture()
		check(image.get_data() != bare.get_data(), "%s changes nothing on screen by itself" % row["name"])
		measured[id] = image
		check(image.save_png("res://.local/retro-effect-%d.png" % id) == OK, "Could not save the effect comparison")
	# Scanlines are horizontal bands: neighbouring rows must differ far more.
	var bare_rows: float = row_contrast(bare)
	var line_rows: float = row_contrast(measured[RetroFilter.Effect.SCANLINES])
	check(line_rows > bare_rows * 3.0, "Scanlines show no banding: row step %.4f against %.4f" % [line_rows, bare_rows])
	# The tube bulges and overscans: no black frame is left around the picture.
	var bare_black: int = black_pixels(bare)
	var tube_black: int = black_pixels(measured[RetroFilter.Effect.CURVE])
	check(tube_black < bare_black * 1.5 + 40, "The tube left a black frame: %d black pixels against %d" % [tube_black, bare_black])
	check(measured[RetroFilter.Effect.CURVE].get_pixel(640, 2) != Color.BLACK, "The tube emptied the top edge instead of filling it")
	check(measured[RetroFilter.Effect.CURVE].get_data() != bare.get_data(), "The tube bent nothing")
	print("RETRO row_step_bare=%.4f row_step_lines=%.4f black_bare=%d black_tube=%d" % [bare_rows, line_rows, bare_black, tube_black])
	# --- Switching everything off restores the composition exactly ---
	only(filter, -1)
	RetroFilter.set_pixel_step(filter, 0)
	var restored: Image = await capture()
	check(untouched.get_data() == restored.get_data(), "With everything off the image is not the untouched composition")
	# --- A virtual pixel stays a whole number of screen pixels ---
	for step: int in [2, 3]:
		RetroFilter.set_pixel_step(filter, step)
		var cells: Vector2 = RetroFilter.PIXEL_STEPS[step]["size"]
		for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(1280, 960)]:
			root.size = dimensions
			var image: Image = await capture()
			var block: int = int(dimensions.x / cells.x)
			var top: int = int((dimensions.y - block * cells.y) / 2)
			var varied: int = 0
			# Interior pixels of hundreds of virtual pixels, away from the edges.
			for y: int in range(int(cells.y * 0.25), int(cells.y * 0.8), 3):
				for x: int in range(int(cells.x * 0.12), int(cells.x * 0.88), 3):
					if image.get_pixel(x * block + 1, top + y * block + 1) != image.get_pixel(x * block + block - 2, top + y * block + block - 2):
						varied += 1
			check(varied == 0, "Virtual pixels are not aligned at %s, step %s: %d blocks" % [dimensions, RetroFilter.PIXEL_STEPS[step]["name"], varied])
			if top > 0:
				check(image.get_pixel(640, 60) == Color.BLACK and image.get_pixel(640, 900) == Color.BLACK, "Filter contaminated letterbox bars")
			print("RETRO window=", dimensions, " step=", RetroFilter.PIXEL_STEPS[step]["name"], " inconsistent_blocks=", varied)
	root.size = Vector2i(1280, 720)
	# --- The settings follow the player into the next scene ---
	RetroFilter.set_pixel_step(filter, 3)
	RetroFilter.set_effect(filter, RetroFilter.Effect.CURVE, true)
	room.queue_free()
	await process_frame
	room = load("res://environments/exterior.tscn").instantiate()
	root.add_child(room)
	await capture()
	filter = room.get_node("FilterLayer/RetroFilter")
	check(RetroFilter.pixel_step == 3 and RetroFilter.is_effect_on(RetroFilter.Effect.CURVE), "Presentation settings lost between scenes")
	check(float(filter.effect.material.get_shader_parameter("curve")) > 0.0, "The restored settings did not reach the shader")
	# --- The menu drives the same settings ---
	var menu: PauseMenu = room.operation.pause_menu
	menu.open()
	await capture()
	check(menu.filter_button != null, "The pause menu offers no presentation row")
	menu.filter_button.pressed.emit()
	await capture()
	check(menu._is_filter_page_open(), "The presentation page did not open")
	var before: int = RetroFilter.pixel_step
	menu.pixel_button.pressed.emit()
	await capture()
	check(RetroFilter.pixel_step != before, "The pixelation stepper did nothing")
	for row: Dictionary in RetroFilter.EFFECTS:
		var id: int = int(row["id"])
		var was: bool = RetroFilter.is_effect_on(id)
		menu.effect_buttons[id].pressed.emit()
		check(RetroFilter.is_effect_on(id) != was, "The switch for %s did nothing" % row["name"])
	await capture()
	check(float(filter.effect.material.get_shader_parameter("scanline")) > 0.0, "A switch flipped in the menu did not reach the shader")
	menu._close_filter_page()
	await capture()
	check(not menu._is_filter_page_open(), "The presentation page did not close")
	menu.close()
	print("RETRO failures=", failures)
	quit(0 if failures == 0 else 1)
