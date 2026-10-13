extends SceneTree
## The rifle as a second gun: switching, separate magazines, the shop and the
## save, owning it without the pistol, and the two-handed visual.
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
	var rifle: WeaponDefinition = PlayerWeapon.RIFLE_DEFINITION
	check(rifle.id == &"rifle" and rifle.two_handed and rifle.magazine == 30, "Rifle definition is not a 30-round two-handed gun")
	check(rifle.damage > PlayerWeapon.DEFAULT_DEFINITION.damage and rifle.reach > PlayerWeapon.DEFAULT_DEFINITION.reach, "Rifle does not out-hit and out-reach the pistol")

	# Shop and save.
	SupplyStock.reset()
	check(not SupplyStock.rifle, "A new game already owns the rifle")
	check(SupplyStock.buy(3) and SupplyStock.rifle, "The rifle could not be bought")
	check(not SupplyStock.available(3), "The rifle can be bought twice")
	check(SupplyStock.snapshot().get("rifle", false), "The save snapshot leaves the rifle out")
	SupplyStock.restore({"rifle": true})
	check(SupplyStock.rifle and not SupplyStock.weapon, "Restoring a save lost the rifle")

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
	check(weapon.definition.id == &"rifle", "The switch action did not put the rifle in hand")
	check(PlayerWeapon.magazine == 30, "The rifle did not come with its own full magazine")
	check(visual.rifle.visible and not visual.pistol.visible, "The visual still shows the pistol")
	check(str(visual.animator.current_animation).begins_with("rifle_"), "The rifle is held with a pistol clip: " + visual.animator.current_animation)
	check(weapon.muzzle_marker == visual.rifle_muzzle, "Shots still leave from the pistol muzzle")
	var grip: Vector3 = visual.skeleton.global_transform * visual.skeleton.get_bone_global_pose(visual.skeleton.find_bone("mixamorig_RightHand")).origin
	check(visual.rifle.global_position.distance_to(grip) < 0.2, "The rifle is not in the right hand")
	Input.action_press("aim")
	await tick(20)
	check(visual.animator.current_animation == "rifle_aim_idle", "Aiming the rifle did not raise it: " + visual.animator.current_animation)
	check(visual.aim_pose.influence == 0.0, "The pistol stance was laid over the rifle")
	check(weapon.fire() and PlayerWeapon.magazine == 29, "The rifle did not fire from its own magazine")
	Input.action_release("aim")
	await tick(4)
	check(weapon.switch_weapon() and weapon.definition.id == &"pistol", "Could not switch back to the pistol")
	check(PlayerWeapon.magazine == pistol_left, "The pistol lost or gained rounds while holstered")
	check(PlayerWeapon.spare_magazines.get(&"rifle", -1) == 29, "The holstered rifle did not keep its 29 rounds")
	# A reload in progress is dropped by the switch, never finished on the other gun.
	PlayerWeapon.magazine = 1
	check(weapon.reload(), "Could not start a reload")
	check(weapon.switch_weapon() and not weapon.is_reloading() and PlayerWeapon.magazine == 29, "Switching mid-reload carried the reload over")
	scene.queue_free()
	await tick(3)

	# The rifle in hand crosses into the next room with its own rounds, and the
	# holstered pistol keeps what it had.
	SupplyStock.restore({"rifle": true, "weapon": true})
	PlayerWeapon.equipped = &"rifle"
	PlayerWeapon.magazine = 29
	PlayerWeapon.spare_magazines = {&"pistol": 7}
	var room: Node = load("res://environments/exterior.tscn").instantiate()
	root.add_child(room)
	await tick(8)
	check(room.player.weapon.definition.id == &"rifle" and PlayerWeapon.magazine == 29, "The rifle and its 29 rounds did not cross the scene change")
	check(room.player.weapon.switch_weapon() and PlayerWeapon.magazine == 7, "The holstered pistol lost its rounds across the scene change")
	room.queue_free()
	await tick(3)

	# Out of practice, with only the rifle bought, Dylan holds the rifle.
	PlayerWeapon.equipped = &"pistol"
	PlayerWeapon.magazine = -1
	PlayerWeapon.spare_magazines.clear()
	SupplyStock.restore({"rifle": true, "weapon": false})
	var exterior: Node = load("res://environments/exterior.tscn").instantiate()
	root.add_child(exterior)
	await tick(8)
	var outside: PlayerWeapon = exterior.player.weapon
	check(outside.definition.id == &"rifle" and outside.is_armed(), "Owning only the rifle did not arm Dylan with it")
	check(not outside.switch_weapon(), "Switched to a pistol that was never bought")
	exterior.queue_free()
	await tick(3)
	SupplyStock.reset()
	PlayerWeapon.equipped = &"pistol"
	PlayerWeapon.magazine = -1
	PlayerWeapon.spare_magazines.clear()
	print("RIFLE failures=", failures)
	quit(1 if failures > 0 else 0)
