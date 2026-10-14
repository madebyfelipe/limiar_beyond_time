extends SceneTree
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
func capture(name: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.local/dodge-%s.png" % name)
func run() -> void:
	var original_path := AimSettings.settings_path
	AimSettings.settings_path = "res://.local/dodge_aim_settings.cfg"
	AimSettings.set_pad_target_lock(false)
	AimSettings.pad_target_lock = true
	AimSettings._loaded = false
	AimSettings.ensure_loaded()
	check(not AimSettings.pad_target_lock, "Gamepad aim preference did not persist")
	AimSettings.settings_path = original_path
	AimSettings.pad_target_lock = true
	DirAccess.remove_absolute("res://.local/dodge_aim_settings.cfg")
	var scene: Node = load("res://environments/firing_range.tscn").instantiate()
	root.add_child(scene)
	await tick(8)
	var player: PlayerController = scene.player
	var visual: Node3D = player.visual.get_node("DylanVisual")
	check(visual.animator.has_animation("dodge_back"), "Mixamo backward hop missing")
	var hop: Animation = visual.animator.get_animation("dodge_back")
	check(hop.loop_mode == Animation.LOOP_NONE and hop.get_track_count() > 30, "The backward hop is not a full-body one-shot")
	PlayerWeapon.magazine = 2
	check(player.weapon.reload(), "Could not start reload before dodge")
	check(player.start_dodge() and not player.weapon.is_reloading(), "Dodge did not cancel reload")
	await tick(60)
	check(PlayerWeapon.magazine == 2, "Cancelled reload still added ammunition")
	# Whatever the stick says, and with none, in either scheme and whichever way
	# Dylan faces: the escape is the backward hop, straight away from his front.
	var original_mode: ControlScheme.Mode = ControlScheme.mode
	for mode: ControlScheme.Mode in [ControlScheme.Mode.CAMERA_RELATIVE, ControlScheme.Mode.TANK]:
		ControlScheme.set_mode(mode)
		for action: String in ["move_right", "move_left", "move_up", "move_down", ""]:
			for yaw: float in [0.0, 2.2]:
				player.reset_combat()
				player.reset_to_start()
				player.visual.rotation.y = yaw
				var back: Vector3 = -player.facing()
				var from: Vector3 = player.position
				if not action.is_empty():
					Input.action_press(action)
				check(player.start_dodge(), "Could not start dodge")
				check(player.dodge_direction.is_equal_approx(back), "Dodge with %s held is not committed backwards" % action)
				await tick(8)
				check(visual.animator.current_animation == "dodge_back", "Dodge with %s held is not the backward hop: %s" % [action, visual.animator.current_animation])
				check(absf(angle_difference(player.visual.rotation.y, yaw)) < 0.01, "The stick turned Dylan during the escape")
				if mode == ControlScheme.Mode.CAMERA_RELATIVE and yaw == 0.0:
					await capture(action if not action.is_empty() else "neutral")
				# 0,55 s of escape at 60 Hz, with the stick still held.
				await tick(24)
				if not action.is_empty():
					Input.action_release(action)
				var travel: Vector3 = player.position - from
				travel.y = 0.0
				check(travel.length() > 1.0 and travel.normalized().dot(back) > 0.98, "Dodge with %s held went %s, not backwards %s" % [action, travel, back])
				await tick(50)
				check(visual.animator.current_animation != "dodge_back", "Dodge did not return to locomotion")
				check(absf(angle_difference(visual.model.rotation.y, PI)) < 0.01, "Dodge left the model turned sideways")
	ControlScheme.set_mode(original_mode)
	# Aiming: the body faces the aim, and the escape backs away from it.
	player.reset_combat()
	player.reset_to_start()
	# A reset asks for the trigger to be let go once before it raises again.
	await tick(2)
	Input.action_press("aim")
	await tick(8)
	check(player.weapon.aiming, "Could not raise the gun before the dodge")
	var aimed_back: Vector3 = -player.facing()
	var aimed_from: Vector3 = player.position
	check(player.start_dodge() and player.dodge_direction.is_equal_approx(aimed_back), "Dodge while aiming is not backwards from the aim")
	await tick(32)
	Input.action_release("aim")
	var aimed_travel: Vector3 = player.position - aimed_from
	aimed_travel.y = 0.0
	check(not player.weapon.aiming and aimed_travel.length() > 1.0 and aimed_travel.normalized().dot(aimed_back) > 0.98, "Dodge while aiming did not back away and lower the gun: %s" % aimed_travel)
	await tick(50)
	AimSettings.modern = AimSettings.Modern.CURSOR
	scene.restart()
	GamepadControls.shared.gamepad_active = false
	await tick(2)
	Input.action_press("aim")
	await tick(5)
	check(player.weapon.aim_cursor_hidden, "Laser aim did not hide the crosshair")
	await capture("cursor")
	Input.action_release("aim")
	scene.operation.pause_menu.open()
	check(not player.weapon.aim_cursor_hidden, "Pause did not restore the menu cursor")
	scene.operation.pause_menu._on_gameplay_pressed()
	await tick(3)
	await capture("menu")
	scene.operation.pause_menu.close()
	scene.queue_free()
	await tick(3)
	print("DODGE_PRESENTATION failures=", failures)
	quit(1 if failures else 0)
