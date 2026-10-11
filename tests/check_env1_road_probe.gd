extends SceneTree
## Tests the bounded local experiment, never claims cross-view calibration.
var scene: Control
var player: PlayerController
var failures: int = 0
var ticks: int = 0
# Independently traced on the original PNG: conservative visible road region.
var road_pixels := PackedVector2Array([Vector2(370,925),Vector2(1110,925),Vector2(1090,740),Vector2(1180,520),Vector2(1290,315),Vector2(1240,300),Vector2(1060,235),Vector2(840,345),Vector2(650,505),Vector2(450,720)])

func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func release() -> void:
	for action: String in ["move_left","move_right","move_up","move_down","run"]: Input.action_release(action)
func steer(direction: Vector3, running: bool = false) -> void:
	var right := player.camera.global_basis.x
	var back := player.camera.global_basis.z
	right.y = 0
	back.y = 0
	if player.movement_reference.locked:
		right = player.movement_reference.right
		back = player.movement_reference.back
	var input := Vector2(direction.dot(right.normalized()),direction.dot(back.normalized()))
	for pair: Array in [["move_right",input.x],["move_left",-input.x],["move_down",input.y],["move_up",-input.y]]:
		if pair[1] > 0.001: Input.action_press(pair[0],pair[1])
		else: Input.action_release(pair[0])
	if running: Input.action_press("run")
	else: Input.action_release("run")
func tick(count: int = 1) -> void:
	for frame: int in range(count):
		await physics_frame
		await process_frame
		ticks += 1
		check(absf(player.position.y) < 0.1,"Lost provisional floor contact")
		check(player.scale == Vector3.ONE,"Actor scale changed")
		var foot: Vector2 = scene.camera.unproject_position(player.position)
		# Presentation is 1920x1080; convert using the same native aspect fit as the PNG.
		var original := (foot-Vector2(0.5101,0)) * 941.0/1080.0
		check(Geometry2D.is_point_in_polygon(original,road_pixels),"Feet outside independently traced road: %s" % original)
		var actor_height: float = player.get_node("Collision").shape.height
		check(Rect2(4,4,1912,1072).has_point(scene.camera.unproject_position(player.position+Vector3(0,actor_height,0))),"Head left frame")
func walk(target: Vector3, running: bool = false) -> void:
	release()
	await tick(12)
	var reached := false
	for frame: int in range(900):
		var delta := target-player.position
		delta.y = 0
		if delta.length() < 0.13:
			reached = true
			break
		steer(delta.normalized(),running and delta.length() > 1.0)
		await tick()
		if failures > 8: break
	release()
	await tick(12)
	check(reached,"Could not reach %s; stopped at %s" % [target,player.position])
func capture(name: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png("user://env1-road-%s.png" % name) == OK,"Capture failed")
func run() -> void:
	create_timer(90).timeout.connect(func() -> void: quit(124))
	root.size = Vector2i(1920,1080)
	scene = load("res://environments/env1_road_probe.tscn").instantiate()
	root.add_child(scene)
	player = scene.player
	await tick(25)
	check(scene.background.texture == load("res://assets/backgrounds/env_1/env01_cam02_bg.png.png"),"Original render missing")
	await capture("start")
	for target: Vector3 in [Vector3(25,0,4.8),Vector3(21,0,5),Vector3(17.3,0,5.6),Vector3(14.7,0,5.5)]:
		await walk(target)
		if failures > 8: break
	await capture("far")
	for target: Vector3 in [Vector3(17.3,0,5.6),Vector3(21,0,5),Vector3(25,0,4.8),Vector3(28.5,0,3.4)]:
		await walk(target,true)
		if failures > 8: break
	await capture("returned")
	# Challenge both physical sides, independently of the centerline route.
	await walk(Vector3(24,0,4.8))
	steer(Vector3.BACK,true)
	await tick(65)
	release()
	await tick(15)
	check(player.position.z < 6.3 and player.position.z > 5.8,"Rail-side limit failed")
	await capture("rail-limit")
	steer(Vector3.FORWARD,true)
	await tick(70)
	release()
	await tick(15)
	check(player.position.z > 3.5 and player.position.z < 4.2,"Road-side limit failed")
	var key := InputEventKey.new()
	key.keycode = KEY_G
	key.pressed = true
	root.push_input(key)
	check(scene.bounds.visible,"G did not reveal trial limits")
	await capture("limits")
	await walk(Vector3(25,0,4.8))
	await walk(Vector3(28.5,0,3.4))
	steer(Vector3.RIGHT,true)
	await tick(60)
	release()
	await tick(15)
	check(player.position.x > 29.4 and player.position.x < 29.7,"Near end limit failed")
	for target: Vector3 in [Vector3(25,0,4.8),Vector3(21,0,5),Vector3(17.3,0,5.6),Vector3(14.7,0,5.5)]:
		await walk(target,true)
	steer(Vector3.LEFT,true)
	await tick(60)
	release()
	await tick(15)
	check(player.position.x > 14.3 and player.position.x < 14.6,"Far end limit failed")
	await capture("end-limit")
	root.size = Vector2i(1280,960)
	for frame: int in range(8): await process_frame
	check(is_equal_approx(scene.background.size.x/scene.background.size.y,16.0/9.0),"Aspect changed")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		check(image.get_pixel(640,60) == Color.BLACK and image.get_pixel(640,900) == Color.BLACK,"4:3 bars missing")
		image.save_png("user://env1-road-4x3.png")
	print("ENV1 road experiment ticks=",ticks," failures=",failures,"; calibration acceptance remains a separate gate")
	release()
	quit(0 if failures == 0 else 1)
