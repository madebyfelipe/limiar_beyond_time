extends SceneTree
## Floating health packs (issue #3):
## - PickupStore: taken ids travel inside the supplies snapshot, a tampered list
##   is not trusted, a new game starts with every pack back
## - on the perimeter trail: two packs, clear of every collider, inside the
##   frame of the camera that covers each and with nothing between it and them,
##   hovering and turning (the third, `rear_yard`, is the service yard's, and its
##   own probe places it)
## - walking into one with full vitality leaves it there and says so once;
##   hurt, it heals 25 on the spot, is gone and stays gone; a dead player takes
##   nothing
## - SAVE keeps what was taken; a restart gives back only what was taken since
##   the last save; doors carry the state; the level built again shows it
##   godot --headless --path . --fixed-fps 60 --script res://tests/check_health_packs.gd
const PERIMETER := "res://environments/perimeter.tscn"
var failures := 0
var ticks := 0
var level: Node
var player: PlayerController
var messages: Array[String] = []

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

func pack(id: StringName) -> HealthPack:
	for candidate: HealthPack in level.health_packs:
		if candidate.pack_id == id:
			return candidate
	return null

func stand_on(id: StringName) -> void:
	player.reset_to(Transform3D(Basis.IDENTITY, level.HEALTH_PACKS[id]))
	await tick(3)

func open_level() -> void:
	level = load(PERIMETER).instantiate()
	root.add_child(level)
	current_scene = level
	await tick(10)
	player = level.player
	# The packs are the subject here, not the animals that guard one of them.
	for animal: KelekenActor in level.kelekens:
		animal.combat_enabled = false
	messages.clear()
	player.combat_message.connect(func(text: String) -> void: messages.append(text))

func close_level() -> void:
	release()
	level.queue_free()
	await tick(3)

func run() -> void:
	create_timer(180).timeout.connect(func() -> void: quit(124))
	root.size = Vector2i(1920, 1080)
	SaveGame.path = "res://.local/health_packs_save.cfg"
	SaveGame.clear()
	check_store()
	await check_placement()
	await check_pickup()
	await check_records()
	SaveGame.clear()
	SupplyStock.reset()
	MissionState.reset()
	AreaMap.reset()
	print("HEALTH_PACKS ticks=", ticks, " failures=", failures)
	quit(1 if failures > 0 else 0)

func check_store() -> void:
	SupplyStock.reset()
	check(PickupStore.snapshot().is_empty() and not PickupStore.is_collected(&"trail_pen"), "A new game starts with a pack taken")
	PickupStore.collect(&"trail_shed")
	PickupStore.collect(&"trail_pen")
	check(PickupStore.snapshot() == ["trail_pen", "trail_shed"], "Taken packs are not listed: %s" % [PickupStore.snapshot()])
	var carried: Dictionary = SupplyStock.snapshot()
	check(carried.get("pickups") == ["trail_pen", "trail_shed"], "The supplies snapshot does not carry the packs")
	SupplyStock.reset()
	check(PickupStore.snapshot().is_empty(), "A new game did not put the packs back")
	SupplyStock.restore(carried)
	check(PickupStore.is_collected(&"trail_pen") and PickupStore.is_collected(&"trail_shed") and not PickupStore.is_collected(&"rear_yard"), "A carried snapshot did not bring the packs' state")
	PickupStore.restore(["rear_yard", 7, "", ["trail_pen"], null])
	check(PickupStore.snapshot() == ["rear_yard"], "A tampered list was taken as written: %s" % [PickupStore.snapshot()])
	PickupStore.restore("trail_pen")
	check(PickupStore.snapshot().is_empty(), "A value that is not a list was read as packs")
	# A supplies record from before the packs existed: nothing taken.
	SupplyStock.restore({"credits": 100})
	check(PickupStore.snapshot().is_empty(), "An older record came back with packs taken")
	SupplyStock.reset()

func check_placement() -> void:
	MissionState.restore(MissionState.Stage.PERIMETER)
	await open_level()
	check(level.health_packs.size() == 2 and level.HEALTH_PACKS.size() == 2, "The trail does not hold two health packs")
	var space: PhysicsDirectSpaceState3D = level.world.get_world_3d().direct_space_state
	var body := SphereShape3D.new()
	body.radius = 0.3
	var covering := {&"trail_pen": 1, &"trail_shed": 2}
	var ids := {}
	for item: HealthPack in level.health_packs:
		var id: StringName = item.pack_id
		check(not ids.has(id) and level.HEALTH_PACKS.has(id), "Pack id missing or used twice: %s" % id)
		ids[id] = true
		check(item.visible and item.is_in_group(&"health_packs"), "%s is not shown" % id)
		check(item.position.is_equal_approx(level.HEALTH_PACKS[id]), "%s is not where the level declares it" % id)
		# Where Dylan's own body fits: no bank, crate, trunk or wall in the way.
		var probe := PhysicsShapeQueryParameters3D.new()
		probe.shape = body
		probe.transform = Transform3D(Basis.IDENTITY, item.global_position + Vector3(0, 0.6, 0))
		probe.collision_mask = 1
		var hits: Array[Dictionary] = space.intersect_shape(probe)
		check(hits.is_empty(), "%s sits inside %s" % [id, hits.map(func(hit: Dictionary) -> String: return str(hit["collider"].name))])
		# Seen by the camera that frames that stretch, with nothing in front.
		var camera: Camera3D = level.shots[covering[id]].camera
		var floating: Vector3 = item.global_position + Vector3(0, HealthPack.HOVER, 0)
		var view: Vector2 = camera.get_viewport().get_visible_rect().size
		var on_screen: Vector2 = camera.unproject_position(floating) / view
		check(not camera.is_position_behind(floating) and on_screen.x > 0.06 and on_screen.x < 0.94 and on_screen.y > 0.06 and on_screen.y < 0.94, "%s is at %s of its camera's frame" % [id, on_screen])
		var ray := PhysicsRayQueryParameters3D.create(camera.global_position, floating, 1)
		var blocked: Dictionary = space.intersect_ray(ray)
		check(blocked.is_empty(), "%s is hidden from its camera by %s" % [id, blocked.get("collider", null)])
	# Hovering and turning, about the height the level placed it at.
	var watched: HealthPack = pack(&"trail_shed")
	var low := INF
	var high := -INF
	var turned := 0.0
	var before: float = watched.body.rotation.y
	for frame: int in range(150):
		await tick()
		low = minf(low, watched.body.position.y)
		high = maxf(high, watched.body.position.y)
		turned += absf(angle_difference(before, watched.body.rotation.y))
		before = watched.body.rotation.y
	check(high - low > 0.1 and high - low < 0.16 and absf((high + low) * 0.5 - HealthPack.HOVER) < 0.01, "The pack does not hover about %.2f m: %.3f … %.3f" % [HealthPack.HOVER, low, high])
	check(turned > 3.0, "The pack does not turn: %.2f rad in 2,5 s" % turned)
	check(watched.position.is_equal_approx(level.HEALTH_PACKS[&"trail_shed"]), "Hovering moved the pick-up point")
	await close_level()

func check_pickup() -> void:
	SupplyStock.reset()
	MissionState.restore(MissionState.Stage.PERIMETER)
	await open_level()
	# Full vitality: nothing to heal, so the pack waits, and says so once.
	await stand_on(&"trail_shed")
	await tick(20)
	check(player.vitality == 100.0 and pack(&"trail_shed").visible and not PickupStore.is_collected(&"trail_shed"), "A pack was used up at full vitality")
	check(messages.count("Vitality is already full.") == 1, "Full vitality was not said exactly once: %s" % [messages])
	# Hurt while standing in it: it heals without leaving and coming back.
	messages.clear()
	player.restore_vitality(40.0)
	await tick(3)
	check(player.vitality == 65.0, "The pack did not heal 25: vitality %.0f" % player.vitality)
	check(not pack(&"trail_shed").visible and PickupStore.is_collected(&"trail_shed"), "The pack is still there after healing")
	check(messages == ["Health pack · +25 vitality"], "The pick-up was not announced once: %s" % [messages])
	check(level.operation.notice.visible and level.operation.notice.text.contains("+25"), "The pick-up did not reach the screen")
	await tick(30)
	check(player.vitality == 65.0, "A taken pack healed again")
	# Reached on foot, with the real controller, from the open side of the pine.
	messages.clear()
	player.reset_to(Transform3D(Basis.IDENTITY, Vector3(1.6, 0.06, -15.6)))
	player.restore_vitality(90.0)
	await tick(5)
	var target: Vector3 = level.HEALTH_PACKS[&"trail_pen"]
	for frame: int in range(240):
		if PickupStore.is_collected(&"trail_pen"):
			break
		var away: Vector3 = target - player.position
		away.y = 0
		steer(away.normalized())
		await tick()
	release()
	check(PickupStore.is_collected(&"trail_pen") and player.vitality == 100.0, "Walking into the pen pack did not top vitality up: %.0f" % player.vitality)
	check(messages == ["Health pack · +10 vitality"], "A partial heal was not announced by what it gave: %s" % [messages])
	var reached: Vector3 = player.position - target
	check(Vector2(reached.x, reached.z).length() <= pack(&"trail_pen").reach + 0.1, "The pen pack was taken from %.2f m away" % Vector2(reached.x, reached.z).length())
	# The dead take nothing. Both packs are taken by now and none is on record,
	# so a restart lays the pen's back down.
	level.restart()
	await tick(3)
	await stand_on(&"trail_pen")
	messages.clear()
	player.health.apply(1000.0)
	await tick(20)
	check(player.is_dead() and pack(&"trail_pen").visible and not PickupStore.is_collected(&"trail_pen") and messages.is_empty(), "A dead player used a pack: %s" % [messages])
	await close_level()

func check_records() -> void:
	SupplyStock.reset()
	SaveGame.clear()
	MissionState.restore(MissionState.Stage.PERIMETER)
	await open_level()
	# One pack before the save, one after it.
	player.restore_vitality(30.0)
	await stand_on(&"trail_shed")
	check(player.vitality == 55.0 and PickupStore.is_collected(&"trail_shed"), "Could not take the first pack")
	var record: Dictionary = SaveGame.write("res://environments/save_room.tscn", Vector3.ZERO, 0.0, MissionState.Stage.PERIMETER, player.vitality)
	check((record.get("supplies", {}) as Dictionary).get("pickups") == ["trail_shed"], "SAVE did not record the taken pack: %s" % [record.get("supplies", {}).get("pickups")])
	await stand_on(&"trail_pen")
	check(player.vitality == 80.0 and PickupStore.snapshot() == ["trail_pen", "trail_shed"], "Could not take the second pack")
	# A restart is a fresh attempt: what was taken since the save is back, what
	# the record holds is not.
	level.restart()
	await tick(3)
	check(pack(&"trail_pen").visible and not PickupStore.is_collected(&"trail_pen"), "Restart did not give back the pack taken after the save")
	check(not pack(&"trail_shed").visible and PickupStore.is_collected(&"trail_shed"), "Restart gave back a pack the save had recorded")
	# Through a door and back: the state rides the supplies snapshot. (The
	# restart also healed Dylan, and a pack is no use to a healthy man.)
	check(player.vitality == 100.0, "Restart did not restore vitality")
	player.restore_vitality(50.0)
	await stand_on(&"trail_pen")
	check(not pack(&"trail_pen").visible and player.vitality == 75.0, "A pack given back by the restart cannot be taken again")
	var carried: Dictionary = SupplyStock.snapshot()
	await close_level()
	SupplyStock.restore(carried)
	await open_level()
	check(not pack(&"trail_pen").visible and not pack(&"trail_shed").visible, "The level built again does not show what was taken")
	# The door did not put the second pack on record: a restart still returns it.
	level.restart()
	await tick(3)
	check(pack(&"trail_pen").visible and not pack(&"trail_shed").visible, "Passing a door recorded a pack as if it were a save")
	await close_level()
	# LOAD GAME: the file is all there is.
	SupplyStock.loaded = false
	PickupStore.restore([])
	PickupStore.mark_recorded()
	check(PickupStore.is_collected(&"trail_shed") and not PickupStore.is_collected(&"trail_pen"), "The first read of the file did not bring the recorded pack")
	await open_level()
	check(not pack(&"trail_shed").visible and pack(&"trail_pen").visible, "A loaded game does not show the recorded pack as taken")
	level.restart()
	await tick(3)
	check(not pack(&"trail_shed").visible, "Restart after loading gave back a recorded pack")
	await close_level()
	# NEW GAME: every pack is back, whatever the file says.
	SupplyStock.reset()
	await open_level()
	for item: HealthPack in level.health_packs:
		check(item.visible, "A new game starts without %s" % item.pack_id)
	level.restart()
	await tick(3)
	check(pack(&"trail_shed").visible, "Restart in a new game applied the old file")
	await close_level()
