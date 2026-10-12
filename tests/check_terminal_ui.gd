extends SceneTree
## Command console through native key events: dispatch, editing, purchase and save.
var failures: int = 0
var room: Node
var menu: TerminalMenu

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

func press(code: Key, ctrl: bool = false) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		event.ctrl_pressed = ctrl
		root.push_input(event)

func type_text(value: String) -> void:
	for index: int in range(value.length()):
		var symbol: String = value.substr(index, 1)
		for down: bool in [true, false]:
			var event := InputEventKey.new()
			event.keycode = symbol.to_upper().unicode_at(0)
			event.physical_keycode = event.keycode
			event.unicode = symbol.unicode_at(0)
			event.pressed = down
			root.push_input(event)

func command(text: String) -> void:
	menu.input_field.clear()
	menu.input_field.grab_focus()
	type_text(text)
	check(menu.input_field.text == text, "Native typing lost characters: " + text)
	press(KEY_ENTER)
	await tick()

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await tick(5)
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("res://.local/console-%s.png" % name) == OK, "Capture failed")

func click(control: Control) -> void:
	var point: Vector2 = control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	for down: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)

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
	check(hud.visible and hud.gauge.ratio == 1.0, "Vitality HUD did not start full")
	room.player.vitality = 50
	await tick()
	check(is_equal_approx(hud.gauge.ratio, 0.5), "Vitality did not follow the player")
	room.player.vitality = 100
	press(KEY_E)
	await tick()
	menu = room.terminal.menu
	check(paused and menu.visible and menu.input_field.has_focus(), "Console did not open with input focused")
	check(menu.input_field.text.is_empty(), "Opening E leaked into the command line")
	check(not SaveGame.has_record() and not hud.visible, "Opening saved or left HUD visible")
	var standing: Vector3 = room.player.global_position
	Input.action_press("move_up")
	await tick(12)
	Input.action_release("move_up")
	check(room.player.global_position.distance_to(standing) < 0.001, "Actor moved behind console")
	await capture("boot")
	press(KEY_ENTER)
	await tick()
	check(not SaveGame.has_record(), "Empty Enter saved")
	await command("help")
	check(menu.output.text.contains("buy ammo") and menu.input_field.has_focus(), "Help or input focus failed")
	type_text("in")
	press(KEY_UP)
	check(menu.input_field.text == "help", "Up did not recall the last command")
	press(KEY_DOWN)
	check(menu.input_field.text == "in", "Down did not restore the unfinished draft")
	press(KEY_TAB)
	check(menu.input_field.text == "inventory", "Tab did not complete a command")
	press(KEY_ENTER)
	await tick()
	check(menu.output.text.contains("CARTUCHOS 90"), "Inventory did not report real stock")
	menu.input_field.text = "buy me"
	press(KEY_TAB)
	check(menu.input_field.text == "buy medkit", "Tab did not complete a product")
	menu.input_field.clear()
	# Failed saves leave progress alone and preserve the console for retry.
	SaveGame.path = "res://.local/missing-console-directory/save.cfg"
	await command("save")
	check(menu.output.text.contains("FALHA AO GRAVAR"), "Disk failure showed success")
	check(MissionState.stage == MissionState.Stage.TERMINAL, "Failed save advanced objective")
	SaveGame.path = SaveGame.PROBE_PATH
	await command("save now")
	check(not SaveGame.has_record(), "Malformed save wrote anyway")
	await command("exit now")
	check(menu.visible and paused, "Malformed exit closed the console")
	await command("unknown-command")
	check(menu.output.text.contains("Comando desconhecido"), "Unknown command had no response")
	await command("shop")
	check(menu.output.text.contains("medkit") and menu.output.text.contains("1800"), "Shop did not list products")
	await command("  BuY    AMMO  ")
	check(SupplyStock.credits == 2100 and SupplyStock.ammo == 120, "Case/whitespace or AMMO purchase failed")
	await command("comprar med kit")
	check(SupplyStock.credits == 1600 and SupplyStock.med_kits == 1, "Portuguese alias or multiword product failed")
	var acquired: Dictionary = SupplyStock.snapshot()
	await command("buy weapon")
	check(SupplyStock.snapshot() == acquired and menu.output.text.contains("Créditos insuficientes"), "Unaffordable buy changed stock")
	await command("buy medkit 2")
	check(SupplyStock.snapshot() == acquired, "Unsupported quantity was charged")
	SupplyStock.credits = 2400
	await command("buy weapon")
	check(SupplyStock.weapon and SupplyStock.credits == 600, "Weapon purchase failed")
	SupplyStock.credits = 2400
	await command("buy weapon")
	check(SupplyStock.credits == 2400 and menu.output.text.contains("já foi adquirida"), "Duplicate weapon was charged")
	SupplyStock.restore(acquired)
	await command("clear")
	check(menu.output.text.is_empty(), "Clear left old transcript")
	await command("shop")
	await command("inventory")
	await command("save")
	var record: Dictionary = SaveGame.read()
	check(record.get("supplies", {}) == acquired and MissionState.stage == MissionState.Stage.DONE, "Save did not store stock/objective")
	check(menu.output.text.contains("PROGRESSO E ESTOQUE SALVOS"), "Save acknowledgement missing")
	await capture("session")
	root.size = Vector2i(1280, 960)
	await tick(8)
	check(is_equal_approx(menu.canvas.scale.x, menu.canvas.scale.y), "Console stretched at 4:3")
	check(menu.canvas.position.y > 100, "4:3 console did not keep the composition letterbox")
	click(menu.input_field)
	check(menu.input_field.has_focus(), "Mouse could not focus the command line after resize")
	await capture("4x3")
	# Scrolling follows actual output and Ctrl+L clears without resetting history.
	for index: int in range(30):
		menu.execute_command("help")
	await tick(8)
	check(menu.lines.size() <= TerminalMenu.MAX_LINES, "Transcript grew without limit")
	var bottom: int = menu.scroll.scroll_vertical
	check(bottom > 0, "Long transcript did not scroll")
	press(KEY_PAGEUP)
	check(menu.scroll.scroll_vertical < bottom, "PageUp did not scroll history")
	press(KEY_L, true)
	await tick()
	check(menu.output.text.is_empty() and not menu.history.is_empty(), "Ctrl+L erased command history or left output")
	press(KEY_UP)
	check(menu.input_field.text == "help", "History disappeared after clear")
	menu.input_field.clear()
	await command("exit")
	check(not paused and not menu.visible and not room.operation.pause_menu.visible, "Exit did not resume or opened pause")
	await tick()
	check(hud.visible, "HUD did not return")
	press(KEY_E)
	await tick()
	check(menu.visible and menu.history.has("save"), "Reopening lost command history")
	press(KEY_ESCAPE)
	await tick()
	check(not paused and not menu.visible and not room.operation.pause_menu.visible, "Esc did not close only the console")
	press(KEY_ESCAPE)
	await tick()
	var pause: PauseMenu = room.operation.pause_menu
	check(pause.visible and paused and pause.resume_button.has_focus(), "Pause failed after console")
	click(pause.resume_button)
	check(not paused, "Mouse Continue did not resume")
	room.free()
	SupplyStock.reset()
	MissionState.reset()
	room = load("res://environments/save_room.tscn").instantiate()
	root.add_child(room)
	await tick(20)
	check(room.resumed and SupplyStock.snapshot() == acquired, "New session did not restore stock")
	room.free()
	# Older records without supplies retain their documented defaults.
	var legacy := ConfigFile.new()
	legacy.set_value(SaveGame.SECTION, "format", SaveGame.FORMAT)
	legacy.set_value(SaveGame.SECTION, "scene", "res://environments/save_room.tscn")
	legacy.set_value(SaveGame.SECTION, "position", Vector3.ZERO)
	check(legacy.save(SaveGame.path) == OK, "Legacy record failed")
	SupplyStock.loaded = false
	SupplyStock.ensure_loaded()
	check(SupplyStock.credits == 2400 and SupplyStock.ammo == 90 and not SupplyStock.weapon, "Legacy defaults broke")
	SaveGame.clear()
	SupplyStock.reset()
	MissionState.reset()
	print("TERMINAL_UI failures=%d" % failures)
	quit(0 if failures == 0 else 1)
