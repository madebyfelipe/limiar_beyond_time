extends SceneTree
## Exercise the perimeter trail's actual enemy, player, physics, weapon and HUD.
## The animal lives in Phase 2 now, so this probe drives that level.
var failures := 0
var trail: Node
var player: PlayerController
var enemy: KelekenActor

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", message)

func tick(count: int = 1) -> void:
	for frame in range(count):
		await physics_frame
		await process_frame

func release() -> void:
	for action: String in ["aim", "fire", "move_up", "move_down", "move_left", "move_right", "dodge", "use_med_kit"]:
		Input.action_release(action)

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("res://.local/combat-%s.png" % name) == OK, "Could not capture combat HUD")

## The pen stretch of the trail, with the animal facing the way in from the
## yard gate: south is +z, so a player "in front" stands at a greater z.
const ENEMY_AT := Vector3(0, 0.06, -14)

func fresh(distance: float = 1.4) -> void:
	release()
	trail.restart()
	trail.keleken_wander.set_physics_process(false)
	enemy.position = ENEMY_AT
	enemy.rotation.y = PI
	player.reset_to(Transform3D(Basis.IDENTITY, ENEMY_AT + Vector3(0, 0, distance)))
	await tick(3)

func run() -> void:
	var previous_bindings_path := InputBindings.settings_path
	var legacy_path := "res://.local/combat_legacy_bindings.cfg"
	var legacy := ConfigFile.new()
	legacy.set_value("bindings_gamepad", "toggle_diagnostics", [{"type": "button", "button": JOY_BUTTON_TOUCHPAD}, {"type": "button", "button": JOY_BUTTON_RIGHT_STICK}])
	check(legacy.save(legacy_path) == OK, "Could not prepare the legacy control profile")
	InputBindings.settings_path = legacy_path
	InputBindings._loaded = false
	InputBindings.ensure_loaded()
	check(InputBindings.events_for("toggle_diagnostics", InputBindings.GAMEPAD).size() == 1, "Old diagnostic profile still conflicts with medical kits")
	check(InputBindings.binding_label("use_med_kit", InputBindings.GAMEPAD) == "RS", "Legacy profile lost the medical-kit binding")
	InputBindings.settings_path = previous_bindings_path
	DirAccess.remove_absolute(legacy_path)
	SaveGame.path = "res://.local/enemy_combat_save.cfg"
	SaveGame.clear()
	SupplyStock.reset()
	trail = load("res://environments/perimeter.tscn").instantiate()
	root.add_child(trail)
	player = trail.player
	enemy = trail.keleken
	ControlScheme.set_mode(ControlScheme.Mode.TANK)
	await tick(8)
	await fresh(5.0)
	check(enemy.sees_player(), "Player in front was not perceived")
	player.position.z = -19.5
	check(not enemy.sees_player(), "Field of view detected a distant player behind")
	player.position.z = -15.8
	check(enemy.sees_player(), "Close player behind was not perceived")
	player.position.z = -4.5
	check(not enemy.sees_player(), "Player outside perception range was perceived")

	# Occlusion must block both awareness and attack damage.
	await fresh()
	var wall := StaticBody3D.new()
	wall.position = Vector3(0, 1.5, -13.3)
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3, 3, 0.15)
	collision.shape = box
	wall.add_child(collision)
	enemy.get_parent().add_child(wall)
	await tick(3)
	check(not enemy.sees_player(), "Enemy sees through a wall")
	enemy._strike()
	check(player.vitality == 100.0, "Attack damaged player through a wall")
	wall.queue_free()
	await tick(2)

	await fresh(5.0)
	var before := enemy.global_position.distance_to(player.global_position)
	await tick(60)
	check(enemy.global_position.distance_to(player.global_position) < before - 1.0, "Enemy did not pursue after alerting")
	check(enemy.state in [KelekenActor.State.CHASE, KelekenActor.State.ATTACK], "Enemy did not leave patrol")
	# Lost sight/range expires its memory instead of tracking forever.
	# Far up the trail, past the pen: the animal walks to where it last saw
	# Dylan and finds nothing within its perception there.
	player.position.z = -21.5
	await tick(210)
	check(enemy.state in [KelekenActor.State.RETURN, KelekenActor.State.PATROL], "Enemy did not abandon a lost target")

	await fresh()
	enemy._begin_attack()
	await tick(22)
	check(player.vitality == 100.0, "Attack applied damage before its hit window")
	await tick(7)
	check(player.vitality == 75.0, "Bicada did not apply 25 damage")
	await capture("damage")
	await tick(29)
	check(player.vitality == 75.0, "One bicada dealt damage more than once")
	check(not player.take_damage(25.0), "Damage immunity did not prevent repeated hits")

	# Dodge is bounded, moves through physics, grants brief immunity and cools down.
	await fresh()
	enemy._begin_attack()
	await tick(15)
	var start := player.position
	Input.action_press("move_right")
	Input.action_press("dodge")
	await tick(2)
	Input.action_release("dodge")
	Input.action_release("move_right")
	check(player.dodge_left > 0.0, "Dodge input did not start evasion")
	check(not player.take_damage(25.0), "Dodge did not grant immunity")
	check(not player.start_dodge(), "Dodge could be retriggered without cooldown")
	# 0,55 s of escape at 60 Hz, plus margin.
	await tick(36)
	check(player.position.distance_to(start) > 1.0, "Dodge did not move Dylan")
	check(player.vitality == 100.0, "Bicada hit the evading player")
	check(player.dodge_left == 0.0, "Dodge did not end")
	await tick(40)
	enemy.combat_enabled = false
	check(player.start_dodge(), "Dodge cooldown did not recover")
	await tick(30)
	# Camera controls use the camera reference for evasion. Collision still
	# stops the burst at a trail bank rather than teleporting through it.
	ControlScheme.set_mode(ControlScheme.Mode.CAMERA_RELATIVE)
	player.reset_combat()
	player.reset_to(Transform3D(Basis.IDENTITY, Vector3(2.2, 0.06, -6)))
	Input.action_press("move_right")
	check(player.start_dodge(), "Camera-relative dodge did not start")
	Input.action_release("move_right")
	await tick(36)
	check(player.position.x < 2.5, "Dodge passed through the trail boundary")
	check(player.dodge_left == 0.0, "Camera-relative dodge did not end")
	ControlScheme.set_mode(ControlScheme.Mode.TANK)
	player.reset_combat()
	player.restore_vitality(30.0)
	SupplyStock.med_kits = 2
	Input.action_press("use_med_kit")
	await tick(2)
	Input.action_release("use_med_kit")
	await tick(2)
	check(player.vitality == 80.0 and SupplyStock.med_kits == 1, "Kit input did not heal 50 and consume one kit")
	check(player.use_med_kit() and player.vitality == 100.0 and SupplyStock.med_kits == 0, "Kit healing did not cap at maximum")
	SupplyStock.med_kits = 1
	check(not player.use_med_kit() and SupplyStock.med_kits == 1, "Full health wasted a kit")
	player.restore_vitality(40.0)
	SupplyStock.med_kits = 0
	check(not player.use_med_kit() and player.vitality == 40.0, "Missing kit healed the player")
	SupplyStock.med_kits = 1
	player.set_control_enabled(false)
	check(not player.use_med_kit(), "Disabled control allowed healing")
	player.set_control_enabled(true)
	paused = true
	check(not player.use_med_kit() and not player.start_dodge(), "Paused combat accepted input")
	paused = false

	# Real pistol ray damages the enemy hurtbox; lethal damage removes targeting.
	enemy.combat_enabled = true
	await fresh()
	player.weapon.practice = true
	# The animal stands up the trail, to the north: that is where Dylan aims.
	player.visual.rotation.y = 0.0
	Input.action_press("aim")
	await tick(18)
	check(player.weapon.target == enemy.hurtbox, "Auto-aim did not select the enemy")
	check(player.weapon.fire(), "Pistol did not fire at the enemy")
	check(enemy.health.current < enemy.health.maximum, "Shot did not damage Keleken")
	check(enemy.state == KelekenActor.State.HURT, "Shot did not interrupt the enemy")
	enemy.hurtbox.take_hit(1000.0, enemy.global_position, Vector3.FORWARD)
	await tick(3)
	check(enemy.state == KelekenActor.State.DEAD and not enemy.health.alive(), "Enemy did not die")
	check(enemy.hurtbox.collision_layer == 0 and not enemy.hurtbox.is_in_group(Hurtbox.GROUP), "Dead enemy remains targetable")
	check(enemy.collision_layer == 0, "Dead enemy still blocks movement")

	player.reset_combat()
	SupplyStock.med_kits = 1
	player.take_damage(1000.0)
	await tick(3)
	check(player.is_dead() and not player.control_enabled and player.vitality == 0.0, "Lethal damage did not disable Dylan")
	check(not player.weapon.aiming and not player.start_dodge() and not player.use_med_kit(), "Dead player accepted combat input")
	check(not player.weapon.fire() and not player.weapon.reload(), "Dead player fired or reloaded")
	check(trail.operation.hud.death_message.visible, "Death offered no restart feedback")
	await capture("death")
	var death_position := player.position
	Input.action_press("move_up")
	await tick(20)
	check(Vector2(player.position.x - death_position.x, player.position.z - death_position.z).length() < 0.01, "Dead Dylan moved")
	trail.restart()
	await tick(3)
	check(player.vitality == 100.0 and player.control_enabled and not player.is_dead(), "Restart did not revive Dylan")
	check(enemy.state == KelekenActor.State.PATROL and enemy.health.alive() and enemy.hurtbox.collision_layer == Hurtbox.LAYER, "Restart did not revive Keleken")
	check(not trail.operation.hud.death_message.visible, "Restart kept the death screen")

	player.restore_vitality(45.0)
	SupplyStock.med_kits = 3
	var record := SaveGame.write("res://environments/perimeter.tscn", player.position, 0.0, MissionState.Stage.PERIMETER, player.vitality)
	check(not record.is_empty(), "Combat state could not be saved")
	player.restore_vitality(100.0)
	SupplyStock.med_kits = 0
	check(SaveGame.resume(player, "res://environments/perimeter.tscn"), "Combat save could not resume")
	check(player.vitality == 45.0 and SupplyStock.med_kits == 3, "Resume did not restore health and medical inventory")
	SaveGame.clear()
	release()
	trail.queue_free()
	await process_frame
	print("ENEMY_COMBAT failures=%d" % failures)
	quit(1 if failures else 0)
