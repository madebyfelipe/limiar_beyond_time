extends SceneTree

var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1
func run() -> void:
	create_timer(30).timeout.connect(func() -> void: quit(124))
	var authored: bool = OS.get_cmdline_user_args().has("--study")
	var scene: Control = load("res://environments/calibration_route_study.tscn" if authored else "res://environments/calibration_env1.tscn").instantiate()
	scene.show_grid = true
	root.add_child(scene)
	var acceptance: bool = OS.get_cmdline_user_args().has("--acceptance")
	var shared_geometry: CalibrationDefinition = load("res://resources/env_1/calibration_cam01.tres")
	root.size = Vector2i(1920,1080)
	check(scene.available_definitions.size() == 3, "Preview must expose its three calibration sheets")
	for id: String in ["01","02","03"]:
		var sheet_path: String = "res://resources/route_study/shot_%d.tres" % int(id) if authored else "res://resources/env_1/calibration_cam%s.tres" % id
		var key: InputEventKey = InputEventKey.new()
		key.keycode = KEY_1 + int(id) - 1
		key.pressed = true
		root.push_input(key)
		for frame: int in range(5):
			await process_frame
		var definition: CalibrationDefinition = scene.definition
		check(definition == load(sheet_path), "Preview key selected the wrong sheet")
		check(scene.background.texture == definition.background, "Preview key did not switch the background")
		if id == "03" and not authored:
			check(definition.reference_world == shared_geometry.reference_world, "cam01/cam03 must preserve their shared spatial hypothesis")
		check(definition.background.get_size() == Vector2(definition.source_dimensions), "Source dimensions disagree with imported texture")
		check(definition.reference_pixels.size() >= 6 and definition.reference_labels.size() == definition.reference_pixels.size(), "Missing six labeled observations")
		check(scene.camera.position == definition.camera_position, "Camera position differs from sheet")
		check(scene.camera.rotation_degrees.distance_to(definition.camera_rotation_degrees) < 0.001 and scene.camera.fov == definition.fov, "Camera settings differ from sheet")
		check(is_equal_approx(scene.capsule.mesh.height,1.8) and scene.capsule.scale == Vector3.ONE, "Reference capsule was distorted")
		check(scene.grid.mesh != null, "3D grid missing")
		check(scene.background.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "Image must keep its source proportions")
		var errors: PackedFloat32Array = scene.errors_1080p()
		var maximum: float = 0
		for index: int in range(errors.size()):
			if not definition.is_anchor(index):
				maximum = maxf(maximum,errors[index])
		print("T06 cam",id," source=",definition.source_dimensions," observations=",definition.reference_pixels.size()," pairs=",definition.reference_world.size()," plane_anchors=",definition.anchor_count()," errors_1080p=",errors," max_non_anchor=",maximum if not errors.is_empty() else "UNDETERMINED")
		if acceptance:
			check(definition.has_correspondences(), "cam" + id + ": spatial correspondences pending")
			check(not errors.is_empty() and maximum <= 8, "cam" + id + ": calibration exceeds 8 px or is undetermined")
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_png("user://t06-%scam%s.png" % ["study-" if authored else "",id]) == OK, "Capture failed")
	# Debug visibility is independent; repeated key events must not flicker it.
	for keycode: Key in [KEY_G, KEY_M]:
		var toggle: InputEventKey = InputEventKey.new()
		toggle.keycode = keycode
		toggle.pressed = true
		root.push_input(toggle)
		check(not scene.grid.visible if keycode == KEY_G else not scene.markers.visible, "Debug toggle did not hide its geometry")
		toggle.echo = true
		root.push_input(toggle)
		check(not scene.grid.visible if keycode == KEY_G else not scene.markers.visible, "Key repeat toggled debug visibility")
		toggle.echo = false
		toggle.pressed = false
		root.push_input(toggle)
		check(not scene.grid.visible if keycode == KEY_G else not scene.markers.visible, "Key release toggled debug visibility")
		toggle.pressed = true
		root.push_input(toggle)
		check(scene.grid.visible if keycode == KEY_G else scene.markers.visible, "Debug toggle did not restore its geometry")
	# Repeat a live resize without changing the camera or capsule's scale.
	root.size = Vector2i(1280,960)
	for frame: int in range(5):
		await process_frame
	check(is_equal_approx(scene.background.size.x/scene.background.size.y,16.0/9.0), "Presentation aspect changed")
	check(scene.capsule.scale == Vector3.ONE, "Resize distorted capsule")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var image: Image = root.get_texture().get_image()
		check(image.get_size() == Vector2i(1280,960), "Capture omits window bars")
		check(image.get_pixel(640,60) == Color.BLACK and image.get_pixel(640,900) == Color.BLACK, "4:3 bars missing")
		image.save_png("user://t06-%scam03-4x3.png" % ("study-" if authored else ""))
	print("T06 mode=", "acceptance" if acceptance else "tooling", " failures=",failures)
	quit(0 if failures == 0 else 1)
