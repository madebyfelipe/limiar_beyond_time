extends "res://tests/check_env1_road_probe.gd"
## Movement and presentation evidence only; the calibration gate is separate.
var cuts: Array[StringName] = []
var previous_position: Vector3
var travelled: float = 0
var polygons := {
	&"env1_cam01": PackedVector2Array([Vector2(600,800),Vector2(740,650),Vector2(840,585),Vector2(970,550),Vector2(1120,517),Vector2(1235,515),Vector2(1210,650),Vector2(1120,920),Vector2(700,920)]),
	&"env1_cam03": PackedVector2Array([Vector2(280,825),Vector2(560,710),Vector2(800,700),Vector2(1000,690),Vector2(1300,705),Vector2(1560,685),Vector2(1530,800),Vector2(1380,930),Vector2(400,930)])
}

func tick(count: int = 1) -> void:
	for frame: int in range(count):
		await physics_frame
		await process_frame
		ticks += 1
		var step := player.position.distance_to(previous_position)
		check(step < 0.13,"Unexpected position discontinuity: %f" % step)
		travelled += step
		previous_position = player.position
		check(absf(player.position.y) < 0.1,"Lost floor")
		check(player.scale == Vector3.ONE,"Actor scale changed")
		var rig: ShotRig = scene.director.current_shot
		check(scene.presentation.current_shot == rig and player.camera == rig.camera and scene.background.texture == rig.definition.background,"Cut is not atomic")
		check(player.camera.is_current(),"Wrong current camera")
		if rig.definition.shot_id == &"env1_cam01":
			check(player.position.x < 8.56,"Second shot navigation extends past the selected entry")
		var foot: Vector2 = player.camera.unproject_position(player.position)
		var original := (foot-Vector2(0.5101,0))*941.0/1080.0
		var polygon: PackedVector2Array = road_pixels if rig.definition.shot_id == &"env1_cam02" else polygons[rig.definition.shot_id]
		check(Geometry2D.is_point_in_polygon(original,polygon),"Feet outside road in %s: %s at %s" % [rig.definition.shot_id,original,player.position])
		check(Rect2(4,4,1912,1072).has_point(player.camera.unproject_position(player.position+Vector3(0,2.4,0))),"Head left frame")
		check(player.position.x >= 1.1 and player.position.x <= 17.9 and player.position.z >= 1.7 and player.position.z <= 4.1,"Escaped physical strip")

func capture(name: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png("user://env1-continuity-%s.png" % name) == OK,"Capture failed")

func on_cut(from: StringName, to: StringName) -> void:
	if from == &"env1_cam02":
		check(player.position.x <= 8.5 and player.position.x > 8.4,"Second shot did not start at the selected entry")
		# The user's marker is the foreground end of the visible road, not
		# the distant end. Check in original image coordinates at the cut.
		var source_pixel: Vector2 = (scene.shots[2].camera.unproject_position(player.position)-Vector2(0.5101,0))*941.0/1080.0
		check(Rect2(580,690,200,130).has_point(source_pixel),"Road cut is not at the indicated foreground end: %s" % source_pixel)
	cuts.append(to)
	print("CUT ",to," world=",player.position," scale=",player.scale)

func run() -> void:
	create_timer(90).timeout.connect(func() -> void: quit(124))
	root.size = Vector2i(1920,1080)
	scene = load("res://environments/env1_continuity_probe.tscn").instantiate()
	root.add_child(scene)
	player = scene.player
	previous_position = player.position
	scene.director.shot_changed.connect(on_cut)
	await tick(25)
	check(scene.director.current_shot.definition.shot_id == &"env1_cam02","Must start on the road")
	var dylan: Node3D = player.get_node("Visual/DylanVisual")
	check(dylan.skeleton.get_bone_count() == 65,"Dylan rig missing")
	check(not player.get_node("Visual/Capsule").visible,"Placeholder capsule still visible")
	check(is_equal_approx(dylan.model.scale.y*dylan.SOURCE_HEIGHT,2.4),"Dylan height adapter wrong")
	check(is_equal_approx(player.get_node("Collision").shape.height,2.4),"Physical capsule does not match Dylan")
	await capture("dylan-road-start")
	await walk(Vector3(10.2,0,3.6))
	check(cuts.is_empty(),"Road cut activated at the far end instead of the indicated near end")
	await capture("dylan-before-cut")
	await walk(Vector3(8.3,0,3.6))
	check(cuts == [&"env1_cam01"],"Missing near-end road cut")
	await capture("dylan-after-cut")
	await walk(Vector3(4.8,0,3.6))
	await walk(Vector3(1.5,0,3.6))
	await capture("dylan-guardhouse")
	check(cuts == [&"env1_cam01",&"env1_cam03"],"Wrong forward cuts")
	await walk(Vector3(4.8,0,3.6),true)
	await walk(Vector3(10.8,0,3.5),true)
	await capture("dylan-road-return")
	await walk(Vector3(14.2,0,2.4),true)
	await walk(Vector3(17.5,0,2.2),true)
	check(cuts == [&"env1_cam01",&"env1_cam03",&"env1_cam01",&"env1_cam02"],"Wrong return cuts")
	# Press the far cap and both sides; far end must remain cam02.
	for direction: Vector3 in [Vector3.RIGHT,Vector3.BACK,Vector3.FORWARD]:
		steer(direction,true)
		await tick(45)
		release()
		await tick(12)
	check(player.position.x > 17.5,"Far cap not exercised")
	check(cuts.size() == 4,"Far cap unexpectedly changes scene")
	await capture("dylan-far-limit")
	await walk(Vector3(14.2,0,2.4),true)
	await walk(Vector3(10.8,0,3.6),true)
	await walk(Vector3(8.3,0,3.6),true)
	await walk(Vector3(4.8,0,3.6),true)
	await walk(Vector3(1.5,0,3.6),true)
	for direction: Vector3 in [Vector3.LEFT,Vector3.BACK,Vector3.FORWARD]:
		steer(direction,true)
		await tick(45)
		release()
		await tick(12)
	var key := InputEventKey.new()
	key.keycode = KEY_G
	key.pressed = true
	root.push_input(key)
	check(scene.bounds.visible,"Missing bounds toggle")
	await capture("dylan-guardhouse-limits")
	root.size = Vector2i(1280,960)
	for frame: int in range(8): await process_frame
	check(is_equal_approx(scene.background.size.x/scene.background.size.y,16.0/9.0),"Aspect changed")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var output := root.get_texture().get_image()
		check(output.get_pixel(640,60) == Color.BLACK and output.get_pixel(640,900) == Color.BLACK,"4:3 bars missing")
	await capture("dylan-4x3")
	print("ENV1 Dylan/near-end cut ticks=",ticks," distance=",travelled," failures=",failures)
	release()
	quit(0 if failures == 0 else 1)
