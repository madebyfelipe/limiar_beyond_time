extends SceneTree
## The double-barrel shotgun as a second gun: two shells and a spread of shot,
## switching (switch action and mouse wheel), separate magazines, the shop and
## the save, owning it without the pistol, and the two-handed visual.
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", message)
func tick(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame
func run() -> void:
	var shotgun: WeaponDefinition = PlayerWeapon.SHOTGUN_DEFINITION
	var pistol: WeaponDefinition = PlayerWeapon.DEFAULT_DEFINITION
	check(shotgun.id == &"shotgun" and shotgun.two_handed and shotgun.magazine == 2, "Shotgun definition is not a two-shell two-handed gun")
	check(shotgun.pellets > 1 and shotgun.spread_degrees > 0.0, "The shotgun does not fire a spread of shot")
	check(shotgun.damage * shotgun.pellets > pistol.damage * 2.0 and shotgun.reach < pistol.reach, "The shotgun is not a close, heavy hitter")
	check(pistol.pellets == 1, "The pistol fires more than one bullet")

	# Shop and save; a save from the rifle days keeps the long gun.
	SupplyStock.reset()
	check(not SupplyStock.shotgun, "A new game already owns the shotgun")
	check(SupplyStock.buy(3) and SupplyStock.shotgun, "The shotgun could not be bought")
	check(not SupplyStock.available(3), "The shotgun can be bought twice")
	check(SupplyStock.snapshot().get("shotgun", false), "The save snapshot leaves the shotgun out")
	SupplyStock.restore({"shotgun": true})
	check(SupplyStock.shotgun and not SupplyStock.weapon, "Restoring a save lost the shotgun")
	SupplyStock.restore({"rifle": true})
	check(SupplyStock.shotgun, "A save that owned the rifle lost the long gun")

	# The range: both guns, switched by the action.
	PlayerWeapon.equipped = &"pistol"
	PlayerWeapon.magazine = -1
	PlayerWeapon.spare_magazines.clear()
	var scene: Node = load("res://environments/firing_range.tscn").instantiate()
	root.add_child(scene)
	await tick(8)
	var player: PlayerController = scene.player
	var weapon: PlayerWeapon = player.weapon
	var visual: Node3D = player.visual.get_node("DylanVisual")
	check(weapon.definition.id == &"pistol", "The range does not start on the pistol")
	Input.action_press("aim")
	await tick(6)
	Input.action_press("fire")
	await tick(2)
	Input.action_release("fire")
	await tick(30)
	var pistol_left: int = PlayerWeapon.magazine
	check(pistol_left < weapon.definition.magazine, "The pistol did not fire")
	Input.action_release("aim")
	await tick(4)
	Input.action_press("switch_weapon")
	await tick(2)
	Input.action_release("switch_weapon")
	await tick(10)
	check(weapon.definition.id == &"shotgun", "The switch action did not put the shotgun in hand")
	check(PlayerWeapon.magazine == 2, "The shotgun did not come with both barrels loaded")
	check(visual.shotgun.visible and not visual.pistol.visible, "The visual still shows the pistol")
	check(str(visual.animator.current_animation).begins_with("rifle_"), "The shotgun is held with a pistol clip: " + visual.animator.current_animation)
	check(weapon.muzzle_marker == visual.shotgun_muzzle, "Shots still leave from the pistol muzzle")
	var grip: Vector3 = visual.skeleton.global_transform * visual.skeleton.get_bone_global_pose(visual.skeleton.find_bone("mixamorig_RightHand")).origin
	check(visual.shotgun.global_position.distance_to(grip) < 0.2, "The shotgun is not in the right hand")
	# The left palm holds the forend. Modified poses only exist while the
	# skeleton reports its update, so it is read there, lowered and raised.
	var palm_gap := [INF]
	var read_palm := func() -> void:
		var knuckle: Vector3 = visual.skeleton.global_transform * visual.skeleton.get_bone_global_pose(visual.skeleton.find_bone("mixamorig_LeftHandMiddle1")).origin
		palm_gap[0] = knuckle.distance_to(visual.support_point())
	visual.skeleton.skeleton_updated.connect(read_palm)
	await tick(30)
	check(palm_gap[0] < 0.02, "The left hand is off the forend while lowered: %.3f m" % palm_gap[0])
	Input.action_press("aim")
	await tick(20)
	check(visual.animator.current_animation == "rifle_aim_idle", "Aiming the shotgun did not raise it: " + visual.animator.current_animation)
	check(visual.aim_pose.influence == 0.0, "The pistol stance was laid over the shotgun")
	check(palm_gap[0] < 0.02, "The left hand is off the forend while aiming: %.3f m" % palm_gap[0])
	visual.skeleton.skeleton_updated.disconnect(read_palm)
	check(weapon.fire() and PlayerWeapon.magazine == 1, "The shotgun did not fire its first barrel")
	check(weapon.last_shot.has("pellet_hits"), "The shot did not report its pellets")
	await tick(int(ceil(shotgun.fire_interval * 60.0)) + 2)
	check(weapon.fire() and PlayerWeapon.magazine == 0, "The shotgun did not fire its second barrel")
	await tick(int(ceil(shotgun.fire_interval * 60.0)) + 2)
	check(not weapon.fire() and weapon.is_reloading(), "Pulling the trigger on empty barrels did not reload")
	await tick(int(ceil(shotgun.reload_time * 60.0)) + 4)
	check(PlayerWeapon.magazine == 2, "The reload did not put two shells back")
	check(weapon.fire() and PlayerWeapon.magazine == 1, "The reloaded shotgun did not fire")
	Input.action_release("aim")
	await tick(4)
	check(weapon.switch_weapon() and weapon.definition.id == &"pistol", "Could not switch back to the pistol")
	check(PlayerWeapon.magazine == pistol_left, "The pistol lost or gained rounds while holstered")
	check(PlayerWeapon.spare_magazines.get(&"shotgun", -1) == 1, "The holstered shotgun did not keep its one shell")
	# A reload in progress is dropped by the switch, never finished on the other gun.
	PlayerWeapon.magazine = 1
	check(weapon.reload(), "Could not start a reload")
	check(weapon.switch_weapon() and not weapon.is_reloading() and PlayerWeapon.magazine == 1, "Switching mid-reload carried the reload over")
	# The mouse wheel switches guns while lowered, either way round.
	weapon.equip(PlayerWeapon.DEFAULT_DEFINITION)
	await tick(2)
	for button: MouseButton in [MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_UP]:
		var wheel := InputEventMouseButton.new()
		wheel.button_index = button
		wheel.pressed = true
		Input.parse_input_event(wheel)
		await tick(2)
		var expected: StringName = &"shotgun" if button == MOUSE_BUTTON_WHEEL_DOWN else &"pistol"
		check(weapon.definition.id == expected, "The mouse wheel did not switch to the " + expected)
	scene.queue_free()
	await tick(3)

	# The shotgun in hand crosses into the next room with its shell, and the
	# holstered pistol keeps what it had.
	SupplyStock.restore({"shotgun": true, "weapon": true})
	PlayerWeapon.equipped = &"shotgun"
	PlayerWeapon.magazine = 1
	PlayerWeapon.spare_magazines = {&"pistol": 7}
	var room: Node = load("res://environments/exterior.tscn").instantiate()
	root.add_child(room)
	await tick(8)
	check(room.player.weapon.definition.id == &"shotgun" and PlayerWeapon.magazine == 1, "The shotgun and its shell did not cross the scene change")
	check(room.player.weapon.switch_weapon() and PlayerWeapon.magazine == 7, "The holstered pistol lost its rounds across the scene change")
	room.queue_free()
	await tick(3)

	# Out of practice, with only the shotgun bought, Dylan holds the shotgun.
	PlayerWeapon.equipped = &"pistol"
	PlayerWeapon.magazine = -1
	PlayerWeapon.spare_magazines.clear()
	SupplyStock.restore({"shotgun": true, "weapon": false})
	var exterior: Node = load("res://environments/exterior.tscn").instantiate()
	root.add_child(exterior)
	await tick(8)
	var outside: PlayerWeapon = exterior.player.weapon
	check(outside.definition.id == &"shotgun" and outside.is_armed(), "Owning only the shotgun did not arm Dylan with it")
	check(not outside.switch_weapon(), "Switched to a pistol that was never bought")
	exterior.queue_free()
	await tick(3)
	SupplyStock.reset()
	PlayerWeapon.equipped = &"pistol"
	PlayerWeapon.magazine = -1
	PlayerWeapon.spare_magazines.clear()
	print("SHOTGUN failures=", failures)
	quit(1 if failures > 0 else 0)
