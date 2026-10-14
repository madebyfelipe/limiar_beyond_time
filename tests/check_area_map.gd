extends SceneTree
## The Episode 1 site plan and the MAP tab of the inventory console:
## - eight rooms, doors that join rooms that exist, scenes and previews on disk
## - a position in each authored level lands in the right room and at the right
##   place on the plan, the guardhouse a quarter turn round to meet its yard door
## - standing in a room marks it visited; a room behind a seen door is only
##   teased; sealed doors stay sealed whatever the objective
## - the objective marker follows the stage
## - SAVE stores the visited rooms, a tampered list is not trusted, and a record
##   from before the map gets its rooms from the stored objective
## - in the real yard: I opens the case, Tab reaches MAP, arrows walk the known
##   rooms only, the reload button zooms, a click picks a room, Esc closes;
##   a drag or the right stick carries the view, no further than the known
##   rooms, and picking a room in the list brings it back
##   godot --headless --path . --fixed-fps 60 --script res://tests/check_area_map.gd
const EXTERIOR := "res://environments/exterior.tscn"
const SAVE_ROOM := "res://environments/save_room.tscn"
const PERIMETER := "res://environments/perimeter.tscn"
const RELAY := "res://environments/relay_room.tscn"
var failures := 0
var ticks := 0
var room: Node

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

func press(code: Key, frames: int = 3) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.pressed = down
		Input.parse_input_event(event)
	await tick(frames)

func run() -> void:
	create_timer(120).timeout.connect(func() -> void: quit(124))
	root.size = Vector2i(1920, 1080)
	SaveGame.path = "res://.local/area_map_save.cfg"
	SaveGame.clear()
	check_data()
	check_locate()
	check_discovery()
	check_doors_and_objective()
	check_save()
	await check_tab()
	SaveGame.clear()
	SupplyStock.reset()
	MissionState.reset()
	AreaMap.reset()
	print("AREA_MAP ticks=", ticks, " failures=", failures)
	quit(1 if failures > 0 else 0)

func check_data() -> void:
	check(AreaMap.ROOMS.size() == 8, "The episode does not have eight rooms (%d)" % AreaMap.ROOMS.size())
	var ids: Dictionary = {}
	for entry: Dictionary in AreaMap.ROOMS:
		var id: StringName = entry["id"]
		check(not ids.has(id), "Room id used twice: %s" % id)
		ids[id] = true
		check(not (entry["shapes"] as Array).is_empty(), "%s has nothing to draw" % id)
		for shape: Rect2 in entry["shapes"]:
			check(shape.size.x > 0.0 and shape.size.y > 0.0, "%s has an empty shape" % id)
		var scene: String = entry["scene"]
		check(scene.is_empty() == (entry["parts"] as Array).is_empty(), "%s: a room has floor exactly when it has a scene" % id)
		if not scene.is_empty():
			check(ResourceLoader.exists(scene), "%s points at a missing scene" % id)
			check(ResourceLoader.exists(entry["preview"]), "%s points at a missing preview" % id)
		var frame: Rect2 = AreaMap.bounds([id]).grow(0.01)
		for part: Dictionary in entry["parts"]:
			check(frame.encloses(part["plan"]), "%s maps floor outside its own shapes" % id)
		check(frame.has_point(AreaMap.mark(id)), "%s puts its marker outside itself" % id)
	for door: Dictionary in AreaMap.DOORS:
		for id: StringName in door["rooms"]:
			check(ids.has(id), "Door %s joins a room that does not exist: %s" % [door["id"], id])
		# A door belongs to the wall of both rooms it joins.
		for id: StringName in door["rooms"]:
			var touches := false
			for shape: Rect2 in AreaMap.room(id)["shapes"]:
				touches = touches or shape.grow(0.05).has_point(door["at"])
			check(touches, "Door %s is not on %s" % [door["id"], id])

func check_locate() -> void:
	var road: Dictionary = AreaMap.locate(EXTERIOR, Vector3(0, 0, 22))
	check(road.get("room") == &"exterior" and road["point"].y > 10.0 and road["point"].y < 16.0, "The road is not drawn as a stub south of the yard: %s" % road)
	var yard: Dictionary = AreaMap.locate(EXTERIOR, Vector3(-4.45, 0, 6))
	check(yard.get("room") == &"exterior" and yard["point"].is_equal_approx(Vector2(-4.45, 6)), "The yard is not on the plan at its own coordinates: %s" % yard)
	# Just inside the guardhouse door, which the yard shows on the south face.
	var inside: Dictionary = AreaMap.locate(SAVE_ROOM, Vector3(-2.4, 0, 0.55))
	check(inside.get("room") == &"guardhouse", "The save room is not the guardhouse: %s" % inside)
	var yard_door: Vector2 = AreaMap.DOORS[0]["at"]
	check(inside["point"].distance_to(yard_door) < 1.0, "The guardhouse floor is not turned to meet its yard door (%.2f m off)" % inside["point"].distance_to(yard_door))
	check(AreaMap.heading(Vector3(-1, 0, 0), inside["quarter"]).is_equal_approx(Vector2(0, 1)), "Facing the room's west wall does not point south on the plan")
	check(AreaMap.heading(Vector3(0, 0, -1)).is_equal_approx(Vector2(0, -1)), "North in a level is not up on the plan")
	var trail: Dictionary = AreaMap.locate(PERIMETER, Vector3(0, 0, -2.2))
	check(trail.get("room") == &"trail" and trail["point"].y < -7.0 and trail["point"].y > -10.0, "The gate end of the trail is not next to the north gate: %s" % trail)
	var shed: Dictionary = AreaMap.locate(PERIMETER, Vector3(0, 0, -26.3))
	check(shed.get("room") == &"trail" and shed["point"].y < -24.0, "The far end of the trail is not at the relay door: %s" % shed)
	var behind: Dictionary = AreaMap.locate(PERIMETER, Vector3(2.4, 0, -33.2))
	var rear_door: Vector2 = AreaMap.DOORS[3]["at"]
	check(behind.get("room") == &"service_yard" and behind["point"].distance_to(rear_door) < 2.0, "Behind the shed is not the service yard at the rear door: %s" % behind)
	var relay: Dictionary = AreaMap.locate(RELAY, Vector3(1.8, 0, 1.35))
	check(relay.get("room") == &"relay" and relay["point"].y > -27.5 and relay["point"].y < -25.0, "The relay room's front door is not on its south side: %s" % relay)
	check(AreaMap.locate("res://environments/firing_range.tscn", Vector3.ZERO).is_empty(), "A scene off the plan was located on it")
	check(AreaMap.locate("", Vector3.ZERO).is_empty(), "No scene matched the rooms that are not built")

func check_discovery() -> void:
	MissionState.reset()
	AreaMap.reset()
	check(AreaMap.known_rooms().is_empty(), "A new game already knows rooms")
	var before: int = AreaMap.revision
	check(AreaMap.track(EXTERIOR, Vector3(0, 0, 22)) == &"exterior" and AreaMap.visited.has(&"exterior"), "Standing on the road did not mark the yard visited")
	check(AreaMap.revision == before + 1, "A new room did not ask for a redraw")
	AreaMap.track(EXTERIOR, Vector3(0, 0, 20))
	check(AreaMap.revision == before + 1, "Standing in a known room asked for a redraw")
	var teased: Array[StringName] = [&"exterior", &"guardhouse", &"trail", &"kennel"]
	check(AreaMap.known_rooms() == teased, "The yard does not tease exactly the rooms behind its doors: %s" % [AreaMap.known_rooms()])
	check(not AreaMap.visited.has(&"kennel") and not AreaMap.known(&"relay"), "A teased room counts as visited, or a room two doors away is known")
	check(AreaMap.track("res://environments/firing_range.tscn", Vector3.ZERO) == &"" and AreaMap.visited.size() == 1, "A scene off the plan marked a room")
	check(not AreaMap.visit(&"nowhere") and AreaMap.visited.size() == 1, "An unknown id was accepted as a room")

func door(id: StringName) -> Dictionary:
	for entry: Dictionary in AreaMap.DOORS:
		if entry["id"] == id:
			return entry
	return {}

func check_doors_and_objective() -> void:
	MissionState.reset()
	check(AreaMap.door_open(door(&"guardhouse_door")) and not AreaMap.door_open(door(&"north_gate")), "On the road the guardhouse is not open or the north gate is")
	check(AreaMap.door_seen(door(&"kennel_south")) and not AreaMap.door_seen(door(&"quarters_door")), "The kennel door is not seen from the yard, or the quarters door is")
	check(AreaMap.objective_room() == &"exterior", "The first objective does not point at the yard")
	MissionState.restore(MissionState.Stage.TERMINAL)
	check(AreaMap.objective_room() == &"guardhouse", "The terminal objective does not point at the guardhouse")
	MissionState.restore(MissionState.Stage.DONE)
	check(AreaMap.door_open(door(&"north_gate")) and not AreaMap.door_open(door(&"relay_front")), "Saving did not release the north gate only")
	check(AreaMap.objective_room() == &"trail", "After saving the objective does not point at the trail")
	MissionState.restore(MissionState.Stage.OUTAGE)
	check(AreaMap.door_open(door(&"relay_front")) and AreaMap.door_open(door(&"relay_rear")), "The outage did not leave both relay doors open")
	check(AreaMap.objective_room() == &"service_yard", "The outage does not point behind the shed")
	MissionState.restore(MissionState.Stage.REAR_YARD)
	check(AreaMap.objective_room() == &"", "The end of the content still points somewhere")
	for id: StringName in [&"quarters_door", &"generator_front", &"generator_side", &"kennel_north", &"kennel_south"]:
		check(not AreaMap.door_open(door(id)), "%s opens although its room is not built" % id)
	MissionState.reset()

func check_save() -> void:
	MissionState.reset()
	AreaMap.reset()
	AreaMap.visit(&"exterior")
	AreaMap.visit(&"guardhouse")
	check(not SaveGame.write(SAVE_ROOM, Vector3.ZERO, 0.0, MissionState.Stage.DONE).is_empty(), "The probe save was not written")
	AreaMap.reset()
	var record: Dictionary = SaveGame.read()
	check(record.get("map") == ["exterior", "guardhouse"], "SAVE did not store the visited rooms: %s" % [record.get("map")])
	MissionState.restore(int(record["stage"]))
	AreaMap.restore(record["map"])
	check(AreaMap.visited.size() == 2 and AreaMap.visited.has(&"guardhouse"), "The stored rooms did not come back")
	# A list edited by hand is not trusted, and cannot hide a room either.
	MissionState.reset()
	AreaMap.restore(["relay", "nowhere", 7, ["trail"]])
	check(AreaMap.visited.keys() == [&"relay", &"exterior"], "A tampered list was taken as written: %s" % [AreaMap.visited.keys()])
	AreaMap.restore("exterior")
	check(AreaMap.visited.keys() == [&"exterior"], "A value that is not a list was read as rooms")
	# A record from before the map: the objective says where Dylan has been.
	MissionState.restore(MissionState.Stage.RELAY_ROOM)
	AreaMap.restore([])
	check(AreaMap.snapshot() == ["exterior", "guardhouse", "trail", "relay"], "An older record did not get its rooms from the objective: %s" % [AreaMap.snapshot()])
	MissionState.reset()
	AreaMap.reset()

func mouse(event: InputEventMouse, at: Vector2) -> void:
	event.position = at
	event.global_position = at
	Input.parse_input_event(event)

func left_button(down: bool, at: Vector2) -> void:
	var button := InputEventMouseButton.new()
	button.button_index = MOUSE_BUTTON_LEFT
	button.pressed = down
	mouse(button, at)
	await tick(2)

func drag(by: Vector2, at: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.relative = by
	mouse(motion, at)
	await tick(2)

## Looking around: the view follows a drag and the aim stick, stops at the edge
## of what is known, and selecting never throws it somewhere else under the hand.
func check_pan(menu: InventoryMenu, page: MapPage) -> void:
	var middle: Vector2 = MapPage.PLAN_RECT.get_center()
	var selected: StringName = page.selected
	var rest: Dictionary = page.plan_view()
	var scale: float = rest["scale"]
	# Pressed on empty ground, so the press itself selects nothing.
	var ground: Vector2 = MapPage.PLAN_RECT.position + Vector2(8, 8)
	await left_button(true, ground)
	await drag(Vector2(-80, 40), ground)
	var dragged: Vector2 = page.plan_view()["centre"]
	check(dragged.is_equal_approx(rest["centre"] + Vector2(80, -40) / scale), "A drag did not carry the plan with the pointer: %s" % [dragged - rest["centre"]])
	check(is_equal_approx(page.plan_view()["scale"], scale) and page.selected == selected, "A drag changed the scale or the selection")
	await left_button(false, ground)
	await drag(Vector2(-80, 40), ground)
	check((page.plan_view()["centre"] as Vector2).is_equal_approx(dragged), "The plan kept moving after the button was released")
	# A press outside the plan is not the start of a drag.
	await left_button(true, Vector2(1700, 1010))
	await drag(Vector2(50, 50), middle)
	check((page.plan_view()["centre"] as Vector2).is_equal_approx(dragged), "A press outside the plan dragged it")
	await left_button(false, middle)
	# The aim stick, held: the view travels, then stops at the edge.
	Input.action_press(&"aim_right", 1.0)
	await tick(6)
	check((page.plan_view()["centre"] as Vector2).x > dragged.x + 1.0, "The right stick did not move the view")
	await tick(240)
	Input.action_release(&"aim_right")
	await tick(2)
	var limit: float = AreaMap.bounds(AreaMap.known_rooms()).grow(MapPage.PAN_MARGIN).end.x
	var edge: Vector2 = page.plan_view()["centre"]
	check(is_equal_approx(edge.x, limit), "The view was not held at the edge of the known rooms: %.2f, edge %.2f" % [edge.x, limit])
	await tick(6)
	check((page.plan_view()["centre"] as Vector2).is_equal_approx(edge), "The view drifted with the stick released")
	# Zoomed, a room picked on the plan stays under the pointer; one picked in
	# the list is brought to the middle.
	page.pan = Vector2.ZERO
	page.selected = &"exterior"
	page.zoomed = true
	var lens: Dictionary = page.plan_view()
	var held: Vector2 = AreaMap.bounds([&"guardhouse"]).get_center()
	menu._click(MapPage.PLAN_RECT.position + MapPage.PLAN_RECT.size * 0.5 + (held - lens["centre"]) * float(lens["scale"]), false)
	check(page.selected == &"guardhouse", "Clicking the guardhouse on the zoomed plan did not select it")
	check((page.plan_view()["centre"] as Vector2).is_equal_approx(lens["centre"]), "Selecting on the plan threw the view elsewhere")
	menu._click(MapPage.LIST_AT + Vector2(40, 20), false)
	check(page.selected == &"exterior" and page.pan == Vector2.ZERO, "Picking a room in the list did not bring the view back")
	page.zoomed = false
	page.refresh()

func check_tab() -> void:
	SaveGame.clear()
	SupplyStock.reset()
	MissionState.reset()
	AreaMap.reset()
	room = load(EXTERIOR).instantiate()
	root.add_child(room)
	current_scene = room
	await tick(20)
	check(AreaMap.visited.keys() == [&"exterior"], "Running the yard did not mark it, and only it, visited: %s" % [AreaMap.visited.keys()])
	var menu: InventoryMenu = room.operation.inventory_menu
	var page: MapPage = menu.map_page
	await press(KEY_I)
	check(menu.visible and paused and not page.visible, "I did not open the case on its own tab")
	for index: int in range(InventoryMenu.MAP_TAB):
		await press(KEY_TAB)
	check(menu.selected_tab == InventoryMenu.MAP_TAB and page.visible, "Four Tabs did not reach the map")
	check(page.here.get("room") == &"exterior" and page.selected == &"exterior", "The map did not open on the room the player is in")
	var spawn: Vector3 = room.player.global_position
	check(page.here["point"].is_equal_approx(AreaMap.locate(EXTERIOR, spawn)["point"]), "The position marker is not where the player stands")
	var order: Array[StringName] = [&"guardhouse", &"trail", &"kennel", &"exterior"]
	for expected: StringName in order:
		await press(KEY_DOWN)
		check(page.selected == expected, "Down did not walk the known rooms in order: got %s, wanted %s" % [page.selected, expected])
	await press(KEY_UP)
	check(page.selected == &"kennel", "Up did not wrap to the last known room")
	var wide: float = page.plan_view()["scale"]
	await press(KEY_R)
	var close: Dictionary = page.plan_view()
	check(page.zoomed and is_equal_approx(close["scale"], wide * MapPage.ZOOM), "The reload button did not zoom the plan")
	check(close["centre"].is_equal_approx(AreaMap.bounds([&"kennel"]).get_center()), "The zoom is not centred on the selected room")
	await press(KEY_R)
	check(not page.zoomed, "The reload button did not zoom back out")
	# The list: row 2 is the guardhouse, row 4 a room nobody has seen yet.
	menu._click(MapPage.LIST_AT + Vector2(40, MapPage.LIST_STEP * 1 + 20), false)
	check(page.selected == &"guardhouse", "Clicking a row did not select its room")
	menu._click(MapPage.LIST_AT + Vector2(40, MapPage.LIST_STEP * 3 + 20), false)
	check(page.selected == &"guardhouse", "Clicking an unknown room selected it")
	# The plan: the middle of the trail, then empty ground.
	var lens: Dictionary = page.plan_view()
	menu._click(MapPage.PLAN_RECT.position + MapPage.PLAN_RECT.size * 0.5 + (Vector2(0, -16) - lens["centre"]) * float(lens["scale"]), false)
	check(page.selected == &"trail", "Clicking the trail on the plan did not select it")
	menu._click(MapPage.PLAN_RECT.position + Vector2(8, 8), false)
	check(page.selected == &"trail", "Clicking empty ground changed the selection")
	await check_pan(menu, page)
	await press(KEY_ENTER)
	check(page.selected == &"exterior" and page.pan == Vector2.ZERO, "Confirm did not return to the current room")
	var case: Array = Inventory.snapshot()
	await press(KEY_TAB)
	check(menu.selected_tab == 0 and not page.visible, "Tab did not wrap from the map to the case")
	check(Inventory.snapshot() == case, "Visiting the map changed the case")
	# The atlas has its own header hit targets, above the inventory's old tabs.
	for index: int in range(1, 5):
		menu._select_tab(InventoryMenu.MAP_TAB)
		menu._click(Vector2(197 + index * 258, 68), false)
		check(menu.selected_tab == index - 1 and not page.visible, "Atlas header did not open inventory category %d" % (index - 1))
	menu._select_tab(InventoryMenu.MAP_TAB)
	page.zoomed = true
	menu._click(MapPage.REGION_RECT.get_center(), false)
	check(not page.zoomed and page.visible, "Region overview did not restore the full map")
	menu._click(Vector2(1487, 68), false)
	check(not menu.visible and not paused, "Atlas EXIT did not close the menu")
	menu.open()
	menu._select_tab(InventoryMenu.MAP_TAB)
	await press(KEY_ESCAPE)
	check(not menu.visible and not paused, "Esc on the map did not close the case")
	check(not room.operation.pause_menu.visible, "Esc on the map also opened the pause menu")
	await press(KEY_I)
	check(menu.visible and menu.selected_tab == 0 and not page.visible, "The case reopened on the map")
	await press(KEY_ESCAPE)
	room.queue_free()
	await tick(2)
