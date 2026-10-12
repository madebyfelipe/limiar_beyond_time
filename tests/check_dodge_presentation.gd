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
	var dodges: Array[String] = ["dodge_forward", "dodge_back", "dodge_left", "dodge_right"]
	for name: String in dodges:
		check(visual.animator.has_animation(name), "Mixamo dodge missing: " + name)
		var clip: Animation = visual.animator.get_animation(name)
		check(clip.loop_mode == Animation.LOOP_NONE and clip.get_track_count() > 30, "Dodge is not a full-body one-shot: " + name)
	var used := {}
	PlayerWeapon.magazine = 2
	check(player.weapon.reload(), "Could not start reload before dodge")
	check(player.start_dodge() and not player.weapon.is_reloading(), "Dodge did not cancel reload")
	await tick(60)
	check(PlayerWeapon.magazine == 2, "Cancelled reload still added ammunition")
	for action: String in ["move_right", "move_left", "move_up", "move_down"]:
		player.reset_to_start()
		Input.action_press(action)
		check(player.start_dodge(), "Could not start dodge")
		await tick(8)
		check(visual.animator.current_animation in dodges, "Locomotion interrupted dodge")
		used[visual.animator.current_animation] = true
		check(player.position.is_finite(), "Invalid dodge transform")
		await capture(action)
		Input.action_release(action)
		await tick(60)
		check(visual.animator.current_animation not in dodges, "Dodge did not return to locomotion")
		check(absf(angle_difference(visual.model.rotation.y, PI)) < 0.01, "Dodge left the model turned sideways")
	check(used.size() == 4, "Four escapes did not use four captures: %s" % [used.keys()])
	player.reset_to_start()
	check(player.start_dodge(), "Could not start neutral dodge")
	await tick(4)
	check(visual.animator.current_animation == "dodge_back", "Neutral dodge is not the backward hop")
	await tick(60)
	AimSettings.modern = AimSettings.Modern.CURSOR
	scene.restart()
	GamepadControls.shared.gamepad_active = false
	await tick(2)
	Input.action_press("aim")
	await tick(5)
	check(player.weapon.custom_cursor_active, "Ground aim did not install the custom cursor")
	await capture("cursor")
	Input.action_release("aim")
	scene.operation.pause_menu.open()
	check(not player.weapon.custom_cursor_active, "Pause did not restore the menu cursor")
	scene.operation.pause_menu._on_gameplay_pressed()
	await tick(3)
	await capture("menu")
	scene.operation.pause_menu.close()
	scene.queue_free()
	await tick(3)
	print("DODGE_PRESENTATION failures=", failures)
	quit(1 if failures else 0)
