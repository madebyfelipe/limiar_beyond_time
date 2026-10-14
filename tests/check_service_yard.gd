extends SceneTree
## Environment 5, measured rather than looked at. The yard is where more animals
## appear, so what is checked is the space itself: that it holds, that it has no
## pocket to be cornered in, that the open ground is open, that tall cover breaks
## a line of sight and low cover does not, that nothing is on the actor as he
## steps out, and that the four framings hold him wherever he can stand.
const YARD := "res://environments/service_yard.tscn"
## The ground is sampled every quarter metre.
const STEP := 0.25
const ORIGIN := Vector2(-16,-66)
const COLUMNS := 129
const ROWS := 153
const ACTOR_RADIUS := 0.3
## Half the width of the narrowest lane the yard may have between two solids:
## an animal the size of the Cryopteryx turns in 2,3 m.
const LANE_RADIUS := 1.15
## How far an animal perceives (`KelekenActor.perception_range`).
const PERCEPTION := 8.0
## The round of the doors, with real Input: north to the generator, east to the
## quarters, west past the truck into the arm, back down the west lane to the
## kennel and along the south wall to the door Dylan came out of.
const ROUND: Array[Vector3] = [
	Vector3(1.8,0,-40),Vector3(1.3,0,-49.6),Vector3(4,0,-46),Vector3(8.4,0,-42.1),Vector3(11.1,0,-41.9),
	Vector3(8,0,-42.2),Vector3(2,0,-44.5),Vector3(-2,0,-44.5),Vector3(-5.9,0,-44.6),Vector3(-6.8,0,-52.5),Vector3(-6.4,0,-55.75),
	Vector3(-6.8,0,-51),Vector3(-10.6,0,-48.2),Vector3(-10.6,0,-38),Vector3(-9.3,0,-34.2),Vector3(-9.3,0,-32.9),
	Vector3(-4,0,-34),Vector3(2.4,0,-32.9),
]
const ROUND_CUTS: Array[StringName] = [&"service_yard_east",&"service_yard_mid",&"service_yard_west",&"service_yard_arm",&"service_yard_west",&"service_yard_mid"]
var failures: int = 0
var ticks: int = 0
var cuts: Array[StringName] = []
var scene: Node
var player: PlayerController
var inspect_frame: bool = false
var space: PhysicsDirectSpaceState3D

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		print("FAIL: ", message)

func release() -> void:
	for action: String in ["move_left","move_right","move_up","move_down","run"]:
		Input.action_release(action)

func steer(direction: Vector3, running: bool = false) -> void:
	var right: Vector3 = player.movement_reference.right
	var back: Vector3 = player.movement_reference.back
	if not player.movement_reference.locked:
		right = player.camera.global_basis.x
		back = player.camera.global_basis.z
		right.y = 0
		back.y = 0
		right = right.normalized()
		back = back.normalized()
	var input := Vector2(direction.dot(right),direction.dot(back))
	for pair: Array in [["move_right",input.x],["move_left",-input.x],["move_down",input.y],["move_up",-input.y]]:
		if pair[1] > 0.001:
			Input.action_press(pair[0],pair[1])
		else:
			Input.action_release(pair[0])
	if running:
		Input.action_press("run")
	else:
		Input.action_release("run")

func tick(count: int = 1) -> void:
	for frame: int in range(count):
		await physics_frame
		await process_frame
		ticks += 1
		if not inspect_frame:
			continue
		var shot: ShotRig = scene.director.current_shot
		check(scene.presentation.current_shot == shot and player.camera == shot.camera,"Camera presentation out of sync")
		for height: float in [0.0,1.8]:
			var point: Vector3 = player.global_position+Vector3(0,height,0)
			var pixel: Vector2 = shot.camera.unproject_position(point)
			if shot.camera.is_position_behind(point) or not Rect2(8,8,1904,1064).has_point(pixel):
				check(false,"Actor outside frame at %v height %s pixel %s shot %s" % [player.position,height,pixel,shot.name])
				inspect_frame = false
				return

func walk_to(target: Vector3, running: bool = false) -> void:
	release()
	await tick(10)
	var reached: bool = false
	for frame: int in range(900):
		var delta: Vector3 = target-player.position
		delta.y = 0
		if delta.length() < 0.15:
			reached = true
			break
		steer(delta.normalized(),running and delta.length() > 1.5)
		await tick()
		if failures > 4:
			break
	release()
	await tick(10)
	check(reached,"Waypoint blocked: %v; stopped at %v" % [target,player.position])

func push(direction: Vector3, frames: int = 110) -> Vector3:
	release()
	await tick(6)
	steer(direction)
	await tick(frames)
	release()
	await tick(10)
	return player.position

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("res://.local/service-yard-"+label+".png") == OK,"Could not capture "+label)

# --- The ground as a grid ---

func cell_of(point: Vector2) -> Vector2i:
	return Vector2i(roundi((point.x-ORIGIN.x)/STEP),roundi((point.y-ORIGIN.y)/STEP))

func point_of(cell: Vector2i) -> Vector2:
	return ORIGIN+Vector2(cell)*STEP

## Whether a standing body of this radius fits with its axis on the point.
func fits(point: Vector2, radius: float) -> bool:
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = 1.5
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY,Vector3(point.x,0.95,point.y))
	query.collision_mask = 1
	query.exclude = [player.get_rid()]
	return space.intersect_shape(query,1).is_empty()

## Every cell a body of this radius can walk to from the start, as a set.
func flood(start: Vector2, radius: float) -> Dictionary:
	var reached: Dictionary = {}
	var first: Vector2i = cell_of(start)
	if not fits(point_of(first),radius):
		return reached
	reached[first] = true
	var frontier: Array[Vector2i] = [first]
	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_back()
		for offset: Vector2i in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]:
			var next: Vector2i = cell+offset
			if next.x < 0 or next.y < 0 or next.x >= COLUMNS or next.y >= ROWS or reached.has(next):
				continue
			if fits(point_of(next),radius):
				reached[next] = true
				frontier.append(next)
	return reached

## Distance from a point to the nearest cell of a set, searched within `limit`.
func gap(set: Dictionary, point: Vector2, limit: float) -> float:
	var centre: Vector2i = cell_of(point)
	var span: int = ceili(limit/STEP)
	var best: float = INF
	for x: int in range(-span,span+1):
		for y: int in range(-span,span+1):
			var cell := centre+Vector2i(x,y)
			if set.has(cell):
				best = minf(best,point_of(cell).distance_to(point))
	return best

func inside_yard(point: Vector2) -> bool:
	return Rect2(-12,-50.5,24,18.5).has_point(point) or Rect2(-12,-61,6.5,10.5).has_point(point)

## As an animal looks: from its eye to the actor's chest.
func sees(from: Vector3, to: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(Vector3(from.x,1.6,from.z),Vector3(to.x,1.2,to.z),1,[player.get_rid()])
	return space.intersect_ray(query).is_empty()

# --- What a camera can and cannot see ---

## The drawn boxes that can stand between a camera and the actor: everything
## with a body to it. The ground, the track and the fence's rails are not.
func occluders() -> Array[Array]:
	var result: Array[Array] = []
	for mesh: MeshInstance3D in scene.source.get_children():
		if not mesh.visible or not mesh.mesh is BoxMesh or mesh.name == &"Terrain":
			continue
		var size: Vector3 = (mesh.mesh as BoxMesh).size
		if minf(size.x,minf(size.y,size.z)) < 0.2:
			continue
		result.append([mesh.transform.affine_inverse(),size*0.5])
	return result

func hidden(from: Vector3, to: Vector3, boxes: Array[Array]) -> bool:
	for entry: Array in boxes:
		var inverse: Transform3D = entry[0]
		var half: Vector3 = entry[1]
		var a: Vector3 = inverse*from
		var d: Vector3 = inverse*to-a
		var enter: float = 0.0
		var leave: float = 1.0
		var miss: bool = false
		for axis: int in range(3):
			if absf(d[axis]) < 0.000001:
				if absf(a[axis]) > half[axis]:
					miss = true
					break
				continue
			var near: float = (-half[axis]-a[axis])/d[axis]
			var far: float = (half[axis]-a[axis])/d[axis]
			enter = maxf(enter,minf(near,far))
			leave = minf(leave,maxf(near,far))
			if enter > leave:
				miss = true
				break
		if not miss:
			return true
	return false

func run() -> void:
	create_timer(300).timeout.connect(func() -> void: quit(124))
	root.size = Vector2i(1920,1080)
	SaveGame.path = "res://.local/service_yard_save.cfg"
	SaveGame.clear()
	SupplyStock.reset()
	MissionState.reset()
	ControlScheme.set_mode(ControlScheme.Mode.CAMERA_RELATIVE)
	scene = load(YARD).instantiate()
	root.add_child(scene)
	current_scene = scene
	player = scene.player
	await tick(25)
	space = scene.world.get_world_3d().direct_space_state
	var arrival := Vector2(scene.REAR_ARRIVAL.x,scene.REAR_ARRIVAL.z)

	# --- The source, as the level reads it ---
	check(scene.shots.size() == 4 and scene.colliders.get_child_count() >= 22,"Spatial source or framings incomplete: %d colliders" % scene.colliders.get_child_count())
	for label: String in ["Terrain","RelayShed","KennelBlock","CrewQuarters","GeneratorHouse","WestBound","ArmNorthBound","SouthGapBound","SouthEastBound","EastSouthBound","EastNorthBound","NorthEastBound","TruckCab","TruckLoad","FuelTank","CrateStack","Pallets","Drums","BarrierWest","BarrierQuarters","ArmPallets"]:
		check(scene.colliders.get_node_or_null(label) != null,"The yard lost the collider of "+label)
	for label: String in ["RelayRearDoor","KennelDoor","QuartersDoor","GeneratorFrontDoor","GeneratorSideDoor","TrackSpine","BreachWestPanel","BreachNorthEastPanel","BreachArmPanel"]:
		check(scene.source.get_node_or_null(label) != null,"The yard lost its "+label)
	check(not scene.populate and scene.kelekens.is_empty(),"The yard is not authored empty")
	check(not scene.art_available and not scene.background.visible,"A plate is showing over geometry that has none")
	check(player.position.distance_to(scene.REAR_ARRIVAL) < 0.2 and scene.director.current_shot == scene.shots[0],"The actor does not start at the rear door in the middle framing: %v" % player.position)
	check(Phase.chain().size() == 3 and Phase.find(&"relay").entry_scene != YARD,"The yard was put in the phase chain")
	# The way back in: the shed's rear door, at its approach, into the relay room.
	check(scene.rear_door != null and scene.rear_door.target_scene == "res://environments/relay_room.tscn" and scene.rear_door.entry_id == &"relay_rear_in","The rear door does not lead back into the relay room")
	check(scene.rear_door.approach.is_equal_approx(scene.DOOR_APPROACHES[&"relay_rear"]),"The rear door's prompt is not at its approach")
	check(scene.health_packs.size() == 1 and scene.HEALTH_PACKS.has(&"rear_yard"),"The rear yard's pack did not come over with its id")

	# --- It holds, and all of it can be walked ---
	var walkable: Dictionary = flood(arrival,ACTOR_RADIUS)
	var leaks: int = 0
	for cell: Vector2i in walkable:
		if not inside_yard(point_of(cell)):
			leaks += 1
	check(leaks == 0,"The actor can walk out of the yard: %d cells beyond the fence" % leaks)
	check(walkable.size() * STEP * STEP > 380.0,"The walkable ground shrank to %.0f m2" % (walkable.size() * STEP * STEP))
	for id: StringName in scene.DOOR_APPROACHES:
		var at: Vector3 = scene.DOOR_APPROACHES[id]
		check(gap(walkable,Vector2(at.x,at.z),0.3) < 0.2,"The door %s cannot be reached" % id)
	for id: StringName in scene.BREACHES:
		var at: Vector3 = scene.BREACHES[id]
		check(gap(walkable,Vector2(at.x,at.z),0.3) < 0.2,"The breach %s opens on ground nobody can stand on" % id)

	# --- No pocket to be cornered in ---
	# A body 2,3 m wide gets everywhere the actor does: wherever he stands, the
	# nearest place it can stand is no further than its own extra width.
	var lanes: Dictionary = flood(scene.CLEARING.get_center(),LANE_RADIUS)
	check(not lanes.is_empty(),"The clearing does not take a body 2,3 m wide")
	var worst: float = 0.0
	var worst_at := Vector2.ZERO
	var cornered: int = 0
	for cell: Vector2i in walkable:
		var point: Vector2 = point_of(cell)
		var distance: float = gap(lanes,point,1.5)
		if distance > 1.4:
			cornered += 1
		if distance > worst:
			worst = distance
			worst_at = point
	check(cornered == 0,"A lane is narrower than 2,3 m: %d cells, the worst at %v" % [cornered,worst_at])
	for id: StringName in scene.DOOR_APPROACHES:
		var at: Vector3 = scene.DOOR_APPROACHES[id]
		check(gap(lanes,Vector2(at.x,at.z),1.5) < 1.3,"No wide way to the door %s" % id)
	# Every piece of cover out in the open is an island: a lane on all four sides.
	for island: Array in [["TruckCab","TruckLoad"],["FuelTank"],["CrateStack"],["Pallets"],["BarrierWest"],["ArmPallets"]]:
		var box := Rect2()
		for label: String in island:
			var body: StaticBody3D = scene.colliders.get_node(label)
			var size: Vector3 = (body.get_child(0) as CollisionShape3D).shape.size
			var part := Rect2(body.position.x-size.x*0.5,body.position.z-size.z*0.5,size.x,size.z)
			box = part if label == island[0] else box.merge(part)
		var centre: Vector2 = box.get_center()
		for side: Vector2 in [Vector2(box.position.x-LANE_RADIUS-0.1,centre.y),Vector2(box.end.x+LANE_RADIUS+0.1,centre.y),Vector2(centre.x,box.position.y-LANE_RADIUS-0.1),Vector2(centre.x,box.end.y+LANE_RADIUS+0.1)]:
			check(gap(lanes,side,0.5) < 0.3,"%s is not an island: no lane at %v" % [island[0],side])

	# --- The open ground is open ---
	var clearing: Rect2 = scene.CLEARING
	check(clearing.size.x >= 11.5 and clearing.size.y >= 11.5,"The clearing is smaller than 11,5 m a side")
	var open := BoxShape3D.new()
	open.size = Vector3(clearing.size.x,1.5,clearing.size.y)
	var open_query := PhysicsShapeQueryParameters3D.new()
	open_query.shape = open
	open_query.transform = Transform3D(Basis.IDENTITY,Vector3(clearing.get_center().x,0.95,clearing.get_center().y))
	open_query.collision_mask = 1
	open_query.exclude = [player.get_rid()]
	var in_the_way: Array[Dictionary] = space.intersect_shape(open_query,4)
	check(in_the_way.is_empty(),"Something stands in the clearing: %s" % str(in_the_way.map(func(hit: Dictionary) -> String: return hit["collider"].name)))
	check(Vector2(scene.DOOR_APPROACHES[&"quarters_door"].x,scene.DOOR_APPROACHES[&"quarters_door"].z).distance_to(clearing.get_center()) < 9.5,"The safe room's door is not on the clearing")

	# --- Tall cover breaks a line of sight; low cover does not ---
	check(not sees(Vector3(-5,0,-45.5),Vector3(-5,0,-37)),"The truck's load does not hide the actor")
	check(not sees(Vector3(-8.3,0,-45.5),Vector3(-8.3,0,-37)),"The truck's cab does not hide the actor")
	check(not sees(Vector3(6.7,0,-45),Vector3(6.7,0,-34)),"The fuel tank does not hide the actor")
	check(sees(Vector3(-7,0,-39),Vector3(-7,0,-33.5)),"The crate stack blocks an animal's eye")
	check(sees(Vector3(-1.75,0,-39),Vector3(-1.75,0,-33.5)),"The pallets block an animal's eye")
	check(sees(Vector3(-8,0,-49),Vector3(-8,0,-44.5)),"The west barrier blocks an animal's eye")
	check(sees(Vector3(10.7,0,-46),Vector3(10.7,0,-42)),"The quarters barrier blocks an animal's eye")
	check(sees(Vector3(-8.75,0,-57),Vector3(-8.75,0,-51.5)),"The arm's pallets block an animal's eye")

	# The pack: where a body fits, on the lanes, in the arm's frame and in view.
	var pack_at: Vector3 = scene.HEALTH_PACKS[&"rear_yard"]
	check(fits(Vector2(pack_at.x,pack_at.z),ACTOR_RADIUS) and gap(walkable,Vector2(pack_at.x,pack_at.z),0.3) < 0.2,"The yard's pack is where nobody can stand")
	var arm_camera: Camera3D = scene.shots[3].camera
	var floating: Vector3 = pack_at+Vector3(0,HealthPack.HOVER,0)
	var on_screen: Vector2 = arm_camera.unproject_position(floating)/Vector2(1920,1080)
	check(Rect2(0.06,0.06,0.88,0.88).has_point(on_screen),"The yard's pack is at %s of the arm's frame" % on_screen)
	check(not hidden(arm_camera.global_position,floating,occluders()),"Something in the arm hides the yard's pack")

	# --- Nothing is on the actor as he steps out ---
	for id: StringName in scene.BREACHES:
		var at: Vector3 = scene.BREACHES[id]
		check(Vector2(at.x,at.z).distance_to(arrival) > PERCEPTION + 4.0,"The breach %s is on top of the rear door: %.1f m" % [id,Vector2(at.x,at.z).distance_to(arrival)])
	var homes: int = 0
	for pack: Dictionary in scene.PACKS:
		var bounds: Rect2 = pack["bounds"]
		for home: Vector3 in pack["homes"]:
			homes += 1
			var at := Vector2(home.x,home.z)
			check(bounds.has_point(at),"A home of the pack %s is outside its ground: %v" % [pack["id"],home])
			check(fits(at,0.6),"A home of the pack %s is inside something: %v" % [pack["id"],home])
			check(gap(lanes,at,1.5) < 0.6,"A home of the pack %s is off the lanes: %v" % [pack["id"],home])
			check(at.distance_to(arrival) > PERCEPTION + 2.0,"An animal of the pack %s is within reach of the rear door: %.1f m" % [pack["id"],at.distance_to(arrival)])
		# And its whole ground is past what an animal perceives from the door.
		var nearest: Vector2 = arrival.clamp(bounds.position,bounds.end)
		check(nearest.distance_to(arrival) > PERCEPTION,"The ground of the pack %s comes within %.1f m of the rear door" % [pack["id"],nearest.distance_to(arrival)])
	check(scene.PACKS.size() >= 3 and homes > 2,"The yard does not hold more animals than the trail's two: %d" % homes)

	# --- The four framings hold him wherever he can stand ---
	var boxes: Array[Array] = occluders()
	for index: int in range(4):
		var shot: ShotRig = scene.shots[index]
		var zone := Rect2(scene.ZONE_CENTERS[index].x-scene.ZONE_SIZES[index].x*0.5,scene.ZONE_CENTERS[index].z-scene.ZONE_SIZES[index].z*0.5,scene.ZONE_SIZES[index].x,scene.ZONE_SIZES[index].z)
		var cells: int = 0
		var outside: int = 0
		var waist: int = 0
		var lost: int = 0
		var shortest: float = INF
		var tallest: float = 0.0
		for cell: Vector2i in walkable:
			var point: Vector2 = point_of(cell)
			if not zone.has_point(point):
				continue
			cells += 1
			var feet := Vector3(point.x,0.06,point.y)
			var head: Vector3 = feet+Vector3(0,1.8,0)
			var feet_pixel: Vector2 = shot.camera.unproject_position(feet)
			var head_pixel: Vector2 = shot.camera.unproject_position(head)
			if shot.camera.is_position_behind(feet) or not Rect2(24,24,1872,1032).has_point(feet_pixel) or not Rect2(24,24,1872,1032).has_point(head_pixel):
				outside += 1
			var tall: float = feet_pixel.distance_to(head_pixel)
			shortest = minf(shortest,tall)
			tallest = maxf(tallest,tall)
			var eye: Vector3 = shot.camera.global_position
			if hidden(eye,feet+Vector3(0,0.9,0),boxes):
				waist += 1
				if hidden(eye,feet+Vector3(0,1.7,0),boxes):
					lost += 1
		print("SERVICE_YARD framing %s cells=%d outside=%d actor=%.0f..%.0f px waist_hidden=%.1f%% lost=%.1f%%" % [shot.name,cells,outside,shortest,tallest,100.0*waist/maxi(cells,1),100.0*lost/maxi(cells,1)])
		check(cells > 400,"The framing %s covers almost no ground: %d cells" % [shot.name,cells])
		check(outside == 0,"The framing %s loses the actor off its edge on %d cells" % [shot.name,outside])
		check(shortest >= 100.0 and tallest <= 200.0,"The actor is %.0f to %.0f px tall in %s, outside 100..200" % [shortest,tallest,shot.name])
		check(waist <= cells*0.05,"Cover hides the actor to the waist on %.1f%% of %s" % [100.0*waist/maxi(cells,1),shot.name])
		check(lost <= cells*0.01,"Cover hides the whole actor on %.1f%% of %s" % [100.0*lost/maxi(cells,1),shot.name])
	# Up the screen is the same way in every framing: the stick keeps its meaning.
	var first_forward: Vector3 = -scene.shots[0].camera.global_basis.z
	first_forward.y = 0.0
	for index: int in range(1,4):
		var forward: Vector3 = -scene.shots[index].camera.global_basis.z
		forward.y = 0.0
		check(forward.normalized().dot(first_forward.normalized()) > 0.9,"The framing %s disagrees with the first on screen-up" % scene.shots[index].name)

	# --- The fence, pushed against with real input ---
	await capture("arrival")
	var south: Vector3 = await push(Vector3.BACK)
	check(south.z < -32.2,"The shed's back wall let the actor through: %v" % south)

	# --- The round of the doors ---
	scene.director.shot_changed.connect(func(_old: StringName,new: StringName) -> void: cuts.append(new))
	inspect_frame = true
	for point: Vector3 in ROUND:
		await walk_to(point,true)
		for id: StringName in scene.DOOR_APPROACHES:
			if scene.DOOR_APPROACHES[id].distance_to(point) < 0.01:
				await capture(String(id))
	inspect_frame = false
	check(cuts == ROUND_CUTS,"Missing or unstable cuts on the round: %s" % str(cuts))
	var east: Vector3 = await push(Vector3.RIGHT,200)
	check(east.x < 3.3 + 0.4 or east.x < 11.6,"The east side let the actor through: %v" % east)

	# --- Restart puts the actor back at the rear door ---
	scene.restart()
	await tick(6)
	check(player.position.distance_to(scene.REAR_ARRIVAL) < 0.3 and scene.director.current_shot == scene.shots[0],"Restart did not return the actor to the rear door")
	check(scene.rear_door.can_interact() and scene.rear_door.prompt_text().contains("Enter"),"No prompt at the rear door")
	check(MissionState.stage == MissionState.Stage.ROAD,"The yard moved the objective")

	# --- And with the animals in, for trying the space against them ---
	scene.queue_free()
	await tick(3)
	scene = load(YARD).instantiate()
	scene.populate = true
	root.add_child(scene)
	current_scene = scene
	player = scene.player
	await tick(20)
	check(scene.kelekens.size() == homes,"Populating put %d animals on %d homes" % [scene.kelekens.size(),homes])
	var index: int = 0
	for pack: Dictionary in scene.PACKS:
		for home: Vector3 in pack["homes"]:
			var animal: KelekenActor = scene.kelekens[index]
			check((pack["bounds"] as Rect2).grow(0.3).has_point(Vector2(animal.position.x,animal.position.z)),"An animal left the ground of the pack %s: %v" % [pack["id"],animal.position])
			check(animal.combat_enabled and animal.state == KelekenActor.State.PATROL,"An animal of the pack %s is not patrolling as the actor steps out" % pack["id"])
			index += 1
	await capture("populated")
	SaveGame.clear()
	MissionState.reset()
	release()
	print("SERVICE_YARD ticks=%d cuts=%s walkable=%.0fm2 failures=%d" % [ticks,str(cuts),walkable.size()*STEP*STEP,failures])
	quit(1 if failures else 0)
