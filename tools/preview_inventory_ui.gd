extends SceneTree
## Captures the message strip and the attaché case in the guardhouse room, for
## whoever styles the UI to see the live layout (needs a display):
##   godot --path . --fixed-fps 60 --script res://tools/preview_inventory_ui.gd
## Writes res://.local/ui-message-box.png and res://.local/ui-inventory.png.

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i: int in range(count):
		await process_frame

func shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
	print("saved ", path)

func run() -> void:
	root.size = Vector2i(1920, 1080)
	SaveGame.path = "res://.local/preview_save.cfg"
	SaveGame.clear()
	SupplyStock.reset()
	SupplyStock.buy(2)
	var room: Node = load("res://environments/save_room.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	await frames(20)
	room.arrive_from_door()
	room.player.reset_to(Transform3D(Basis.IDENTITY, room.CRATE_APPROACH + Vector3.UP * 0.05))
	await frames(10)
	var results: Array[Dictionary] = ChestStore.collect(ChestStore.DELIVERY)
	MessageBox.say(room, ["You obtained %s ×%d." % [MessageBox.item(Inventory.item_name(results[0]["id"])), results[0]["taken"]]])
	await frames(90)
	await shot("res://.local/ui-message-box.png")
	for box: Node in get_nodes_in_group(&"message_boxes"):
		box._close()
	await frames(3)
	MessageBox.say(room, ["Open the %s?" % MessageBox.item("SUPPLY CRATE")], ["No", "Yes"])
	await frames(90)
	await shot("res://.local/ui-message-question.png")
	for box: Node in get_nodes_in_group(&"message_boxes"):
		box._close()
	await frames(3)
	Inventory.add(&"shotgun", 1)
	Inventory.add(&"med_kit", 2)
	room.operation.inventory_menu.open()
	var menu: InventoryMenu = room.operation.inventory_menu
	for entry: Dictionary in Inventory.entries:
		if entry["id"] == &"pistol":
			menu.cursor = entry["cell"]
	menu._refresh()
	await frames(6)
	await shot("res://.local/ui-inventory-power-line.png")
	await frames(10)
	await shot("res://.local/ui-inventory-power-reveal.png")
	await frames(24)
	await shot("res://.local/ui-inventory.png")
	menu.confirm()
	await frames(5)
	await shot("res://.local/ui-inventory-actions.png")
	menu.actions = []
	for entry: Dictionary in Inventory.entries:
		if entry["id"] == &"shotgun":
			menu.cursor = entry["cell"]
	menu.confirm()
	await frames(5)
	await shot("res://.local/ui-inventory-shotgun.png")
	root.size = Vector2i(1920, 1080)
	await frames(5)
	await shot("res://.local/ui-inventory-reference.png")
	menu._select_tab(2)
	await frames(5)
	await shot("res://.local/ui-inventory-ammo-tab.png")
	root.size = Vector2i(1280, 720)
	await frames(5)
	await shot("res://.local/ui-inventory-ammo-720.png")
	root.size = Vector2i(1920, 1080)
	menu._select_tab(3)
	menu.confirm()
	await frames(5)
	await shot("res://.local/ui-inventory-recovery-tab.png")
	menu._select_tab(0)
	root.size = Vector2i(1920, 1080)
	menu.actions = []
	room.player.restore_vitality(20.0)
	await frames(5)
	await shot("res://.local/ui-inventory-danger.png")
	room.player.restore_vitality(45.0)
	await frames(5)
	await shot("res://.local/ui-inventory-caution.png")
	room.player.restore_vitality(100.0)
	for entry: Dictionary in Inventory.entries:
		if entry["id"] == &"pistol":
			menu.cursor = entry["cell"]
	menu.held = Inventory.entry_at(menu.cursor)
	menu.held_rotated = true
	menu.cursor = Vector2i(9, 5)
	menu._refresh()
	await frames(5)
	await shot("res://.local/ui-inventory-invalid.png")
	menu.cursor = Vector2i(8, 3)
	menu._refresh()
	await frames(5)
	await shot("res://.local/ui-inventory-rotated.png")
	menu.held = {}
	menu.status.text = ""
	root.size = Vector2i(1280, 960)
	menu._refresh()
	await frames(8)
	await shot("res://.local/ui-inventory-4x3.png")
	GamepadControls.shared.gamepad_active = true
	GamepadControls.shared.playstation = true
	menu._refresh()
	await frames(8)
	await shot("res://.local/ui-inventory-ps4-4x3.png")
	GamepadControls.shared.gamepad_active = false
	root.size = Vector2i(1280, 720)
	Inventory.clear()
	menu.cursor = Vector2i.ZERO
	menu._refresh()
	await frames(8)
	await shot("res://.local/ui-inventory-empty-720.png")
	room.operation.inventory_menu.close()
	root.size = Vector2i(1280, 960)
	MessageBox.say(room, ["The north gate is bolted.", "Record your progress at the %s before going on." % MessageBox.item("GUARDHOUSE TERMINAL")])
	await frames(90)
	var message: MessageBox = get_nodes_in_group(&"message_boxes")[0]
	message.page = 1
	message._show_page()
	await frames(140)
	await shot("res://.local/ui-message-4x3.png")
	message._close()
	await frames(3)
	SaveGame.clear()
	SupplyStock.reset()
	quit()
