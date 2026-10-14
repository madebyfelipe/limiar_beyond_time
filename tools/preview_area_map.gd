extends SceneTree
## Captures the MAP tab of the inventory console, for whoever styles the UI to
## see the live layout (needs a display):
##   godot --path . --fixed-fps 60 --script res://tools/preview_area_map.gd
## Writes res://.local/ui-map-start.png (first minute, from the road),
## ui-map-outage.png (behind the relay shed, everything built visited),
## ui-map-zoom.png (the same, zoomed on the relay room) and ui-map-720.png.

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i: int in range(count):
		await process_frame

func shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
	print("saved ", path)

func open_map(level: Node) -> MapPage:
	var menu: InventoryMenu = level.operation.inventory_menu
	menu.open()
	menu._select_tab(InventoryMenu.MAP_TAB)
	return menu.map_page

func run() -> void:
	root.size = Vector2i(1920, 1080)
	SaveGame.path = "res://.local/preview_save.cfg"
	SaveGame.clear()
	SupplyStock.reset()
	MissionState.reset()
	AreaMap.reset()
	var level: Node = load("res://environments/exterior.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await frames(20)
	open_map(level)
	await frames(45)
	await shot("res://.local/ui-map-start.png")
	level.operation.inventory_menu.close()
	level.queue_free()
	await frames(3)
	# Behind the relay shed after the outage: every built room has been seen.
	MissionState.restore(MissionState.Stage.OUTAGE)
	AreaMap.restore(["exterior", "guardhouse", "trail", "relay"])
	level = load("res://environments/perimeter.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await frames(20)
	level.player.reset_to(Transform3D(Basis.IDENTITY, level.REAR_ARRIVAL + Vector3(1.5, 0.06, -2.0)))
	level.player.visual.rotation.y = PI * 0.25
	await frames(10)
	var page: MapPage = open_map(level)
	await frames(45)
	await shot("res://.local/ui-map-outage.png")
	page.selected = &"relay"
	page.zoomed = true
	page.refresh()
	await frames(5)
	await shot("res://.local/ui-map-zoom.png")
	page.zoomed = false
	page.selected = &"service_yard"
	page.refresh()
	root.size = Vector2i(1280, 720)
	await frames(8)
	await shot("res://.local/ui-map-720.png")
	root.size = Vector2i(1024, 768)
	await frames(8)
	await shot("res://.local/ui-map-4x3.png")
	root.size = Vector2i(1920, 1080)
	RetroFilter.set_enabled(level, false)
	await frames(8)
	await shot("res://.local/ui-map-native.png")
	page.selected = &"generator"
	page.refresh()
	await frames(4)
	await shot("res://.local/ui-map-unexplored.png")
	level.operation.inventory_menu.close()
	SaveGame.clear()
	quit()
