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
	MessageBox.say(room, ["You obtained %s." % MessageBox.item(Inventory.item_name(results[0]["id"]))], ["No", "Yes"])
	await frames(90)
	await shot("res://.local/ui-message-box.png")
	for box: Node in get_nodes_in_group(&"message_boxes"):
		box._close()
	await frames(3)
	Inventory.add(&"shotgun", 1)
	Inventory.add(&"med_kit", 2)
	room.operation.inventory_menu.open()
	await frames(10)
	await shot("res://.local/ui-inventory.png")
	room.operation.inventory_menu.close()
	SaveGame.clear()
	SupplyStock.reset()
	quit()
