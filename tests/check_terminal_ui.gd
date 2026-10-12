extends SceneTree
## Real keyboard/mouse flow, save failure, purchase limits and session restore.
var failures: int = 0
var room: Node

func _init() -> void:
	create_timer(90).timeout.connect(func() -> void: quit(124))
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func tick(count: int = 3) -> void:
	for frame: int in range(count):
		await physics_frame
		await process_frame

func press(code: Key) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		root.push_input(event)

func click(button: Button) -> void:
	var point: Vector2 = button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	for down: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await tick(5)
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("res://.local/ui-%s.png" % name) == OK, "Screenshot failed: " + name)

func run() -> void:
	SaveGame.clear()
	SupplyStock.reset()
	MissionState.reset()
	root.size = Vector2i(1280, 720)
	room = load("res://environments/save_room.tscn").instantiate()
	root.add_child(room)
	await tick(20)
	room.arrive_from_door()
	room.player.reset_to(Transform3D(Basis.IDENTITY, room.TERMINAL_APPROACH + Vector3.UP * 0.06))
	await tick(6)
	var hud: GameHud = room.operation.hud
	check(hud.visible and hud.hint.text == "[E] TERMINAL", "HUD did not show nearby terminal")
	await capture("hud")
	press(KEY_E)
	await tick()
	var menu: TerminalMenu = room.terminal.menu
	check(paused and menu.visible and menu.save_button.has_focus(), "Terminal did not open with SAVE focused")
	check(not SaveGame.has_record(), "E saved without SAVE")
	check(not hud.visible, "Gameplay HUD remained visible behind modal")
	var position: Vector3 = room.player.global_position
	Input.action_press("move_up")
	await tick(12)
	Input.action_release("move_up")
	check(room.player.global_position.distance_to(position) < 0.001, "Player moved behind terminal")
	await capture("terminal")
	# Disk failure must be visible and leave the live objective untouched.
	SaveGame.path = "res://.local/missing-ui-save-directory/save.cfg"
	press(KEY_ENTER)
	await tick()
	check(menu.message.text.contains("FALHA"), "Save failure displayed success")
	check(MissionState.stage == MissionState.Stage.TERMINAL, "Failed save advanced the mission")
	SaveGame.path = SaveGame.PROBE_PATH
	# Keyboard selects SHOP; mouse buys and changes real stock.
	press(KEY_DOWN)
	check(menu.shop_button.has_focus(), "Arrow key did not select SHOP")
	press(KEY_ENTER)
	await tick()
	check(menu.in_shop and menu.item_buttons[0].has_focus(), "SHOP did not open")
	click(menu.buy_button)
	await tick()
	check(SupplyStock.credits == 2100 and SupplyStock.ammo == 120, "AMMO purchase did not debit credits and add 30 rounds")
	click(menu.item_buttons[1])
	click(menu.buy_button)
	await tick()
	check(SupplyStock.credits == 1600 and SupplyStock.med_kits == 1, "MED KIT purchase failed")
	click(menu.item_buttons[2])
	check(menu.buy_button.disabled, "Unaffordable weapon remains buyable")
	click(menu.buy_button)
	check(SupplyStock.credits == 1600 and not SupplyStock.weapon, "Disabled BUY spent credits")
	# Boundary rules: an owned weapon cannot be purchased twice.
	var acquired: Dictionary = SupplyStock.snapshot()
	SupplyStock.credits = 2400
	check(SupplyStock.buy(2), "Affordable weapon could not be acquired")
	SupplyStock.credits = 2400
	check(not SupplyStock.buy(2) and SupplyStock.credits == 2400, "Owned weapon was charged twice")
	SupplyStock.restore(acquired)
	menu.select_item(0)
	await capture("shop")
	press(KEY_ESCAPE)
	check(menu.visible and not menu.in_shop and paused, "ESC in SHOP did not return to the terminal")
	check(not room.operation.pause_menu.visible, "Pause opened over SHOP")
	menu.show_shop()
	# Letterboxing and hit targets share the same transform at 4:3.
	root.size = Vector2i(1280, 960)
	await tick(8)
	check(is_equal_approx(menu.canvas.scale.x, menu.canvas.scale.y), "Menu stretched at 4:3")
	check(menu.canvas.position.y > 100, "4:3 menu was not letterboxed")
	click(menu.back_button)
	check(not menu.in_shop and paused, "BACK closed the terminal or left SHOP active")
	await capture("terminal-4x3")
	click(menu.save_button)
	await tick()
	var record: Dictionary = SaveGame.read()
	check(record.get("supplies", {}) == acquired, "SAVE did not store purchased stock")
	check(MissionState.stage == MissionState.Stage.DONE, "SAVE did not finish the objective")
	press(KEY_ESCAPE)
	await tick()
	check(not paused and not menu.visible and not room.operation.pause_menu.visible, "ESC opened pause over terminal exit")
	check(hud.visible and hud.status.text.contains("1600") and hud.supplies.text.contains("120"), "HUD did not refresh credits/ammo")
	press(KEY_ESCAPE)
	await tick()
	var pause: PauseMenu = room.operation.pause_menu
	check(pause.visible and paused and pause.resume_button.has_focus(), "Pause menu failed after terminal")
	# The control scheme lives on the gameplay page, behind its own row.
	var mode: int = ControlScheme.mode
	click(pause.gameplay_button)
	check(pause._is_gameplay_page_open(), "Gameplay page did not open from the menu")
	click(pause.scheme_button)
	check(ControlScheme.mode != mode, "Control scheme button stopped working")
	pause._close_gameplay_page()
	# The presentation row opens a page of its own; the stepper lives there.
	var step: int = RetroFilter.pixel_step
	click(pause.filter_button)
	check(pause._is_filter_page_open(), "Presentation page did not open from the menu")
	click(pause.pixel_button)
	check(RetroFilter.pixel_step != step, "Pixelation stepper stopped working")
	pause._close_filter_page()
	await tick()
	await capture("pause-4x3")
	click(pause.resume_button)
	check(not paused, "Mouse Continue did not resume")
	room.free()
	SupplyStock.reset()
	MissionState.reset()
	room = load("res://environments/save_room.tscn").instantiate()
	root.add_child(room)
	await tick(20)
	check(room.resumed and SupplyStock.snapshot() == acquired, "New room did not restore stock and credits")
	room.free()
	# Optional stock fields preserve compatibility with previous format-2 saves.
	var legacy := ConfigFile.new()
	legacy.set_value(SaveGame.SECTION, "format", SaveGame.FORMAT)
	legacy.set_value(SaveGame.SECTION, "scene", "res://environments/save_room.tscn")
	legacy.set_value(SaveGame.SECTION, "position", Vector3.ZERO)
	check(legacy.save(SaveGame.path) == OK, "Could not create legacy record")
	SupplyStock.loaded = false
	SupplyStock.ensure_loaded()
	check(SupplyStock.credits == 2400 and SupplyStock.ammo == 90 and not SupplyStock.weapon, "Legacy save did not get starter supplies")
	SaveGame.clear()
	SupplyStock.reset()
	MissionState.reset()
	print("TERMINAL_UI failures=%d" % failures)
	quit(0 if failures == 0 else 1)
