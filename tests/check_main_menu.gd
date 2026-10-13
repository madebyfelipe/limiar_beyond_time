extends SceneTree
## Exercises title navigation, settings return and real save/new-game launches.
## Dedicated save fixture; optional graphical captures live under .local.
const ROOM := "res://environments/save_room.tscn"
const SAVED_AT := Vector3(-2.4, 0.06, 0.55)
var failures: int = 0
var menu: MainMenu

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func tick(count: int = 1) -> void:
	for i: int in range(count):
		await process_frame
		await physics_frame

func tap(code: Key) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await tick(2)

func pad_tap(code: JoyButton) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventJoypadButton.new()
		event.button_index = code
		event.device = 15
		event.pressed = pressed
		Input.parse_input_event(event)
		await tick(2)

func open_menu() -> void:
	if current_scene != null:
		current_scene.queue_free()
		await tick(2)
	menu = load("res://ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await tick(60)

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("res://.local/main-menu-%s.png" % name) == OK, "Screenshot failed")

func run() -> void:
	create_timer(100).timeout.connect(func() -> void: quit(124))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.local"))
	SaveGame.path = "res://.local/main_menu_save_probe.cfg"
	SaveGame.clear()
	root.size = Vector2i(1280, 720)
	await open_menu()
	check(menu.load_button.disabled, "Load must be unavailable without a save")
	check(root.gui_get_focus_owner() == menu.buttons[0], "Initial focus must be New Game")
	await tap(KEY_DOWN)
	check(root.gui_get_focus_owner() == menu.buttons[2], "Navigation must skip unavailable Load Game")
	await tap(KEY_ENTER)
	check(menu.settings.settings_menu.visible and paused, "Options must open the real settings pages")
	await tap(KEY_ESCAPE)
	check(not paused and menu.menu.visible and root.gui_get_focus_owner() == menu.buttons[2], "Back must return directly to the title menu")
	await tap(KEY_DOWN)
	await tap(KEY_ENTER)
	check(menu.extras.visible, "Extras must open")
	await pad_tap(JOY_BUTTON_B)
	check(not menu.extras.visible and root.gui_get_focus_owner() == menu.buttons[3], "Controller Back must return from Extras")
	menu.buttons[0].grab_focus()
	# Restore keyboard prompts after exercising the controller path.
	await tap(KEY_UP)
	await tap(KEY_DOWN)
	await capture("16x9")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var before_snow: PackedByteArray = root.get_texture().get_image().get_data()
		await tick(25)
		await RenderingServer.frame_post_draw
		check(before_snow != root.get_texture().get_image().get_data(), "Snow must animate after the title fade finishes")
	root.size = Vector2i(960, 720)
	await tick(5)
	var logo: Control = menu.canvas.get_node("Logo")
	check(root.get_visible_rect().encloses(logo.get_global_rect()), "Logo must fit a 4:3 viewport")
	check(root.get_visible_rect().encloses(menu.buttons[4].get_global_rect()), "Quit must fit a 4:3 viewport")
	await capture("4x3")
	var raw_logo: Image = MainMenu.LOGO.get_image()
	check(raw_logo.detect_alpha() != Image.ALPHA_NONE, "Standalone logo must preserve actual transparency")
	SupplyStock.restore({"credits": 1234, "ammo": 42, "med_kits": 2, "weapon": true})
	check(not SaveGame.write(ROOM, SAVED_AT, 0.7, MissionState.Stage.DONE, 61.0).is_empty(), "Save fixture must write")
	var saved_file: String = FileAccess.get_file_as_string(SaveGame.path)
	root.size = Vector2i(1280, 720)
	await open_menu()
	check(not menu.load_button.disabled, "Load must be available with a valid save")
	await tap(KEY_DOWN)
	check(root.gui_get_focus_owner() == menu.load_button, "Keyboard must select Load")
	await tap(KEY_ENTER)
	await tick(90)
	check(current_scene.scene_file_path == ROOM, "Load must enter the saved scene")
	check(current_scene.get("resumed") == true, "Load must restore the saved session")
	check(current_scene.get("player").global_position.distance_to(SAVED_AT) < 0.2, "Load must restore the saved position")
	check(SupplyStock.credits == 1234 and MissionState.stage == MissionState.Stage.DONE, "Load must restore inventory and mission")
	check(absf(current_scene.get("player").health.current - 61.0) < 0.1, "Load must restore health")
	await open_menu()
	await tap(KEY_ENTER)
	await tick(90)
	check(current_scene.scene_file_path == MainMenu.GAME_SCENE, "New Game must launch the exterior")
	check(SupplyStock.credits == 2400 and Inventory.entries.is_empty() and not SupplyStock.weapon, "New Game must reset inventory")
	check(MissionState.stage == MissionState.Stage.ROAD, "New Game must reset the objective")
	check(FileAccess.get_file_as_string(SaveGame.path) == saved_file, "New Game must preserve the existing save file")
	# Entering the guardhouse during a new game cannot restore the old run.
	current_scene.queue_free()
	await tick(2)
	var fresh_room: Node = load(ROOM).instantiate()
	root.add_child(fresh_room)
	current_scene = fresh_room
	await tick(10)
	check(not fresh_room.get("resumed"), "New Game must ignore the old save on room entry")
	SaveGame.resume_on_scene_entry = true
	SaveGame.clear()
	print("MAIN_MENU failures=", failures)
	quit(0 if failures == 0 else 1)
