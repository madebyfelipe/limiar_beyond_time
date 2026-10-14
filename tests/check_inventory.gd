extends SceneTree
## The attaché case, the supply crate and the message strip:
## - the grid: footprints, stacks, turning, moving, a full case, save round-trip
## - the shop delivers to the crate; old saves migrate into the case
## - each gun reloads only from its own ammunition
## - the guardhouse crate on the room's existing SupplyChest box, reached on
##   foot, asked Yes/No in the message strip, handing over the bought gun and
##   ammunition for both guns
## - the inventory menu opened by its action: move, turn, equip, use
##   godot --headless --path . --fixed-fps 60 --script res://tests/check_inventory.gd
var failures := 0
var ticks := 0
var room: Node
var player: PlayerController

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", message)

func tick(count: int = 1) -> void:
	for frame: int in range(count):
		await physics_frame
		await process_frame
		ticks += 1

func key(code: Key) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.pressed = down
		Input.parse_input_event(event)

func press(code: Key, frames: int = 3) -> void:
	key(code)
	await tick(frames)

func release() -> void:
	for action: String in ["move_right", "move_left", "move_down", "move_up", "run"]:
		Input.action_release(action)

func steer(direction: Vector3) -> void:
	var right: Vector3 = player.movement_reference.right
	var back: Vector3 = player.movement_reference.back
	if not player.movement_reference.locked:
		right = player.camera.global_basis.x
		back = player.camera.global_basis.z
		right.y = 0
		back.y = 0
		right = right.normalized()
		back = back.normalized()
	var input := Vector2(direction.dot(right), direction.dot(back))
	for pair: Array in [["move_right", input.x], ["move_left", -input.x], ["move_down", input.y], ["move_up", -input.y]]:
		if pair[1] > 0.001:
			Input.action_press(pair[0], pair[1])
		else:
			Input.action_release(pair[0])

func walk_to(target: Vector3) -> bool:
	for frame: int in range(900):
		var delta: Vector3 = target - player.position
		delta.y = 0
		if delta.length() < 0.12:
			release()
			await tick(20)
			return true
		steer(delta.normalized())
		await tick()
	release()
	return false

## Reads every page of the open message strip; on the question, picks `answer`.
func answer_box(answer: int = -1) -> void:
	for page: int in range(16):
		var boxes: Array[Node] = get_nodes_in_group(&"message_boxes")
		if boxes.is_empty() or not (boxes[0] as MessageBox).visible:
			return
		var box: MessageBox = boxes[0]
		if box.options.size() > 0 and box._last_page() and box._page_done() and answer >= 0:
			while box.choice != answer:
				await press(KEY_RIGHT)
			await press(KEY_E)
			await tick(2)
			return
		await press(KEY_E)
	check(false, "The message strip never closed")

func run() -> void:
	create_timer(240).timeout.connect(func() -> void: quit(124))
	root.size = Vector2i(1920, 1080)
	SaveGame.path = "res://.local/inventory_save.cfg"
	SaveGame.clear()
	MissionState.reset()
	check_grid()
	check_shop_and_migration()
	await check_crate()
	await check_ammunition()
	await check_menu()
	await check_gate_message()
	SupplyStock.reset()
	SaveGame.clear()
	print("INVENTORY ticks=", ticks, " failures=", failures)
	quit(1 if failures > 0 else 0)

func check_grid() -> void:
	SupplyStock.reset()
	check(Inventory.entries.is_empty(), "A new game does not start with an empty case")
	check(Inventory.footprint(&"shotgun", false) == Vector2i(8, 2) and Inventory.footprint(&"shotgun", true) == Vector2i(2, 8), "Turning does not swap a footprint")
	check(Inventory.add(&"pistol", 1) == 0 and Inventory.entries[0]["cell"] == Vector2i.ZERO, "The first item was not placed in the corner")
	check(not Inventory.fits(&"med_kit", Vector2i(2, 1), false), "An item fits on top of another")
	check(not Inventory.fits(&"shotgun", Vector2i(3, 0), false), "An item fits past the right edge")
	check(not Inventory.fits(&"med_kit", Vector2i(0, 5), false), "An item fits past the bottom edge")
	check(Inventory.add(&"handgun_ammo", 70) == 0 and Inventory.count(&"handgun_ammo") == 70, "Ammunition was lost on the way in")
	var stacks: int = 0
	for entry: Dictionary in Inventory.entries:
		if entry["id"] == &"handgun_ammo":
			stacks += 1
			check(int(entry["count"]) <= 50, "A stack holds more than its limit")
	check(stacks == 2, "70 rounds did not take two places (%d)" % stacks)
	check(Inventory.add(&"handgun_ammo", 10) == 0 and Inventory.entries.size() == 3, "A partial stack was not topped up first")
	check(Inventory.take(&"handgun_ammo", 30) == 30 and Inventory.count(&"handgun_ammo") == 50, "Taking ammunition went wrong")
	check(Inventory.entries.size() == 2, "Taking did not empty the smaller stack first")
	# Moving and turning: the pistol to the far corner, turned.
	var pistol: Dictionary = Inventory.entry_at(Vector2i(1, 1))
	check(pistol.get("id") == &"pistol", "entry_at does not find the item under a cell")
	check(Inventory.move(pistol, Vector2i(8, 3), true) and Inventory.entry_at(Vector2i(9, 5)) == pistol, "A turned move did not land")
	check(not Inventory.move(pistol, Vector2i(9, 3), true), "A move past the edge was accepted")
	# A full case says how much did not fit.
	var room_left: int = Inventory.room_for(&"shotgun", 3)
	var count_before: int = Inventory.entries.size()
	check(Inventory.add(&"shotgun", 3) == 3 - room_left and Inventory.entries.size() == count_before + room_left, "room_for disagrees with add")
	var med_left: int = Inventory.add(&"med_kit", 99)
	check(med_left > 0, "99 med kits fit a 10x6 case")
	check(Inventory.add(&"med_kit", 1) == 1, "A full case accepted more")
	# Save round-trip, and a tampered snapshot is re-placed, not trusted.
	var saved: Array = Inventory.snapshot()
	Inventory.clear()
	Inventory.restore(saved)
	check(Inventory.snapshot() == saved, "The case did not survive a snapshot round-trip")
	Inventory.restore([{"id": "pistol", "count": 1, "cell": Vector2i(0, 0)}, {"id": "med_kit", "count": 1, "cell": Vector2i(1, 1)}, {"id": "nonsense", "count": 4}])
	check(Inventory.count(&"pistol") == 1 and Inventory.count(&"med_kit") == 1 and Inventory.entries.size() == 2, "An overlapping or unknown entry was trusted")
	var kit: Dictionary = Inventory.entry_at(Vector2i(1, 1))
	check(kit.get("id") == &"pistol", "The overlapping entry displaced the one placed first")

func check_shop_and_migration() -> void:
	SupplyStock.reset()
	check(SupplyStock.buy(2) and SupplyStock.weapon and SupplyStock.credits == 600, "The pistol could not be bought")
	check(not Inventory.has(&"pistol") and ChestStore.holds(ChestStore.DELIVERY, &"pistol"), "A purchase skipped the crate")
	check(not SupplyStock.available(2), "The pistol can be bought twice")
	check(SupplyStock.buy(4) and ChestStore.holds(ChestStore.DELIVERY, &"shotgun_shells"), "Shells could not be bought")
	var crate: Array = ChestStore.contents(ChestStore.DELIVERY)
	var shells: int = 0
	for item: Dictionary in crate:
		if item["id"] == &"shotgun_shells":
			shells = item["count"]
	check(shells == 20, "Bought shells did not join the crate's own (%d)" % shells)
	var carried: Dictionary = SupplyStock.snapshot()
	SupplyStock.reset()
	SupplyStock.restore(carried)
	check(SupplyStock.snapshot() == carried, "Credits, case and crates did not survive a snapshot")
	# A save from before the case owned guns outright with one pool of rounds.
	SupplyStock.restore({"credits": 100, "ammo": 42, "med_kits": 2, "weapon": true, "shotgun": true})
	check(Inventory.has(&"pistol") and Inventory.has(&"shotgun") and Inventory.count(&"handgun_ammo") == 42 and Inventory.count(&"med_kit") == 2, "A pre-case save did not migrate into the case")
	check(ChestStore.contents(ChestStore.DELIVERY).size() == 2, "A pre-case save lost the crate's authored contents")
	# And through the real file.
	check(not SaveGame.write("res://environments/save_room.tscn", Vector3.ZERO, 0.0, MissionState.Stage.DONE).is_empty(), "The save file could not be written")
	var before: Array = Inventory.snapshot()
	SupplyStock.reset()
	SupplyStock.loaded = false
	SupplyStock.ensure_loaded()
	check(Inventory.snapshot() == before, "The case did not come back from the save file")
	SaveGame.clear()

func check_crate() -> void:
	SupplyStock.reset()
	check(SupplyStock.buy(3), "The shotgun could not be bought")
	room = load("res://environments/save_room.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	await tick(20)
	room.arrive_from_door()
	player = room.player
	await tick(10)
	# Untyped on purpose: a typed ItemChest local here makes this probe leak
	# script instances at exit (engine-side; the room itself frees cleanly).
	var crate: Node = room.crate
	check(crate != null, "The save room has no crate")
	var box: MeshInstance3D = room.source.get_node_or_null(^"SupplyChest")
	check(box != null and box.has_meta("collision_size"), "The crate is not on the room's existing SupplyChest geometry")
	var door: Vector3 = room.doorway.approach
	check(Vector2(door.x - crate.approach.x, door.z - crate.approach.z).length() > room.doorway.radius + crate.radius, "Door and crate approach circles overlap")
	check(not crate.can_interact(), "The crate answers from the door")
	var walked: bool = await walk_to(Vector3(-1.6, 0.0, 0.95))
	walked = walked and await walk_to(room.CRATE_APPROACH)
	check(walked, "The crate approach cannot be reached on foot: %v" % player.position)
	check(crate.can_interact() and crate.prompt.visible, "No prompt at the crate")
	var pixel: Vector2 = room.camera.unproject_position(room.CRATE_APPROACH + Vector3.UP)
	check(Rect2(Vector2.ZERO, Vector2(root.size)).has_point(pixel), "The crate approach is off camera")
	# No leaves everything inside.
	await press(KEY_E)
	check(MessageBox.is_open(self) and paused, "E at the crate did not open the message strip")
	var strip: MessageBox = get_nodes_in_group(&"message_boxes")[0]
	check(strip.options == PackedStringArray(["No", "Yes"]), "The crate did not ask No/Yes")
	await answer_box(0)
	check(not MessageBox.is_open(self) and not paused, "Answering No left the game paused")
	check(not Inventory.has(&"shotgun") and ChestStore.holds(ChestStore.DELIVERY, &"shotgun"), "Answering No still emptied the crate")
	# Yes hands over the bought gun and ammunition for both guns, item by item.
	await tick(5)
	await press(KEY_E)
	strip = get_nodes_in_group(&"message_boxes")[0]
	await answer_box(1)
	await tick(3)
	strip = get_nodes_in_group(&"message_boxes")[0] if MessageBox.is_open(self) else null
	check(strip != null and strip.pages.size() == 3, "The crate did not read out three items")
	if strip != null:
		check(str(strip.pages[0]).contains("HANDGUN AMMO") and str(strip.pages[0]).contains("[color="), "Item names are not highlighted")
		check(str(strip.pages[2]).contains("SHOTGUN"), "The bought shotgun was not announced")
	await answer_box()
	check(Inventory.has(&"shotgun") and Inventory.count(&"handgun_ammo") == 30 and Inventory.count(&"shotgun_shells") == 10, "The crate did not hand over the shotgun and both ammunitions")
	check(ChestStore.is_empty(ChestStore.DELIVERY), "The crate kept what was taken")
	check(not paused and not crate.busy, "The crate left the game paused or busy")
	# A purchase made now lands in the same crate.
	SupplyStock.credits = 1800
	check(SupplyStock.buy(2), "The pistol could not be bought after the shotgun")
	await press(KEY_E)
	await answer_box(1)
	await tick(3)
	strip = get_nodes_in_group(&"message_boxes")[0] if MessageBox.is_open(self) else null
	check(strip != null and str(strip.pages[0]).contains("PISTOL"), "A later purchase was not in the crate")
	await answer_box()
	check(Inventory.has(&"pistol"), "The pistol did not reach the case")
	# An empty crate says so.
	await press(KEY_E)
	await answer_box(1)
	await tick(3)
	strip = get_nodes_in_group(&"message_boxes")[0] if MessageBox.is_open(self) else null
	check(strip != null and str(strip.pages[0]).contains("empty"), "An empty crate did not say so")
	await answer_box()
	# What does not fit stays inside for later.
	Inventory.add(&"med_kit", 99)
	ChestStore.deliver(ChestStore.DELIVERY, &"handgun_ammo", 400)
	await press(KEY_E)
	await answer_box(1)
	await tick(3)
	strip = get_nodes_in_group(&"message_boxes")[0] if MessageBox.is_open(self) else null
	check(strip != null and str(strip.pages[-1]).contains("stays in the crate"), "The leftover was not reported")
	await answer_box()
	check(Inventory.count(&"handgun_ammo") > 0 and ChestStore.holds(ChestStore.DELIVERY, &"handgun_ammo"), "Ammunition that did not fit was lost")

func check_ammunition() -> void:
	SupplyStock.reset()
	Inventory.add(&"pistol", 1)
	Inventory.add(&"shotgun", 1)
	Inventory.add(&"handgun_ammo", 7)
	Inventory.add(&"shotgun_shells", 3)
	var weapon: PlayerWeapon = player.weapon
	await tick(3)
	check(weapon.owns(PlayerWeapon.DEFAULT_DEFINITION) and weapon.owns(PlayerWeapon.SHOTGUN_DEFINITION), "Guns in the case are not owned")
	weapon.equip(PlayerWeapon.DEFAULT_DEFINITION)
	check(weapon.reserve() == 7, "The pistol does not reload from handgun ammo")
	weapon.equip(PlayerWeapon.SHOTGUN_DEFINITION)
	check(weapon.reserve() == 3, "The shotgun does not reload from shells")
	PlayerWeapon.magazine = 0
	check(weapon.reload(), "The shotgun would not reload")
	await tick(int(PlayerWeapon.SHOTGUN_DEFINITION.reload_time * 60.0) + 10)
	check(PlayerWeapon.magazine == 2 and Inventory.count(&"shotgun_shells") == 1 and Inventory.count(&"handgun_ammo") == 7, "Reloading the shotgun drew the wrong ammunition")
	Inventory.take(&"shotgun", 1)
	await tick(3)
	check(not weapon.owns(PlayerWeapon.SHOTGUN_DEFINITION) and weapon.definition.id == &"pistol", "A gun out of the case is still in hand")

func check_menu() -> void:
	SupplyStock.reset()
	Inventory.add(&"pistol", 1)
	Inventory.add(&"shotgun", 1)
	Inventory.add(&"med_kit", 1)
	await tick(3)
	var menu: InventoryMenu = room.operation.inventory_menu
	await press(KEY_I)
	check(menu.visible and paused, "I did not open the case")
	check(menu.cursor == Vector2i.ZERO, "The cursor did not start on the first item")
	# Health readout updates while paused, even without an inventory mutation.
	player.restore_vitality(20.0)
	await tick(2)
	check(menu.vitality.text == "DANGER  020", "The open inventory did not show critical health")
	player.restore_vitality(45.0)
	await tick(2)
	check(menu.vitality.text == "CAUTION  045", "The open inventory did not show caution health")
	player.restore_vitality(100.0)
	await tick(2)
	check(menu.vitality.text == "FINE  100", "The open inventory did not show restored health")
	# Tabs are a view of the same storage; hiding a kind cannot consume it.
	var before_filter: Array = Inventory.snapshot()
	await press(KEY_TAB)
	check(menu.selected_tab == 1 and Inventory.kind(menu._inspected["id"]) == &"weapon", "Tab did not select weapons")
	await press(KEY_TAB)
	check(menu.selected_tab == 2 and menu._inspected.is_empty(), "An empty ammo tab still inspects a weapon")
	await press(KEY_ENTER)
	check(menu.actions.is_empty(), "A dimmed weapon opened actions in the ammo tab")
	await press(KEY_TAB)
	check(menu.selected_tab == 3 and menu._inspected.get("id") == &"med_kit", "Recovery did not select the med kit")
	check(Inventory.snapshot() == before_filter, "Changing tabs changed storage")
	# The last tab is the site plan (check_area_map.gd); it holds no storage.
	await press(KEY_TAB)
	check(menu.selected_tab == InventoryMenu.MAP_TAB and menu.map_page.visible, "Tab did not reach the map")
	await press(KEY_TAB)
	check(menu.selected_tab == 0 and not menu.map_page.visible, "Tab did not wrap to all items")
	# Native mouse hit testing uses the same design coordinates at every scale.
	menu._click(Vector2(990, 90), false)
	check(menu.selected_tab == 2, "Clicking the ammo tab did not switch it")
	menu._select_tab(0)
	# Equip the shotgun from its actions.
	var shotgun: Dictionary = {}
	for entry: Dictionary in Inventory.entries:
		if entry["id"] == &"shotgun":
			shotgun = entry
	menu.cursor = shotgun["cell"]
	await press(KEY_ENTER)
	check(menu.actions == PackedStringArray(["EQUIP", "MOVE", "CANCEL"]), "A gun offers %s" % [menu.actions])
	await press(KEY_ENTER)
	check(player.weapon.definition.id == &"shotgun", "EQUIP did not put the shotgun in hand")
	check(menu.loadout.text == "MAIN / SHOTGUN", "Equipping did not update the loadout readout")
	# Move the pistol: pick it up, turn it, set it down at the bottom right.
	var pistol: Dictionary = Inventory.entry_at(Vector2i.ZERO)
	menu.cursor = Vector2i.ZERO
	await press(KEY_ENTER)
	await press(KEY_DOWN)
	check(menu.actions[menu.action_index] == "MOVE", "Down did not reach MOVE")
	await press(KEY_ENTER)
	check(menu.held == pistol, "MOVE did not pick the pistol up")
	await press(KEY_TAB)
	check(menu.selected_tab == 0 and menu.held == pistol, "A tab switch hid occupied cells during placement")
	await press(KEY_R)
	check(menu.held_rotated, "R did not turn the held item")
	for step: int in range(9):
		await press(KEY_RIGHT, 1)
	for step: int in range(5):
		await press(KEY_DOWN, 1)
	check(menu.cursor == Vector2i(9, 5), "The cursor left the grid")
	await press(KEY_ENTER)
	check(not menu.held.is_empty() and menu.status.text.contains("does not fit"), "An item was set down past the edge")
	await press(KEY_UP, 1)
	await press(KEY_UP, 1)
	await press(KEY_LEFT, 1)
	await press(KEY_ENTER)
	check(menu.held.is_empty() and pistol["cell"] == Vector2i(8, 3) and pistol["rotated"], "The turned pistol was not set down at (8,3)")
	# Use the med kit while hurt.
	player.restore_vitality(60.0)
	var hurt: float = player.vitality
	for entry: Dictionary in Inventory.entries:
		if entry["id"] == &"med_kit":
			menu.cursor = entry["cell"]
	await press(KEY_ENTER)
	check(menu.actions[0] == "USE", "A med kit does not offer USE")
	await press(KEY_ENTER)
	check(player.vitality > hurt and not Inventory.has(&"med_kit"), "USE did not heal and consume the kit")
	await press(KEY_ESCAPE)
	check(not menu.visible and not paused, "Esc did not close the case")
	check(not room.operation.pause_menu.visible, "Esc closing the case also opened the pause menu")

func check_gate_message() -> void:
	room.queue_free()
	await tick(3)
	MissionState.reset()
	room = load("res://environments/exterior.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	await tick(20)
	room._on_north_gate_refused()
	await tick(3)
	check(MessageBox.is_open(self) and paused, "The bolted gate did not speak in the message strip")
	var strip: MessageBox = get_nodes_in_group(&"message_boxes")[0]
	check(str(strip.pages[-1]).contains("TERMINAL"), "The gate message does not point at the terminal")
	await answer_box()
	check(not MessageBox.is_open(self) and not paused, "The gate message left the game paused")
	room.queue_free()
	await tick(2)
