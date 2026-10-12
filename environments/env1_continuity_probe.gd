extends "res://environments/env1_road_probe.gd"
## Authored connection hypothesis, not a recovered or accepted ENV_1 map.
## Cam02's local road is turned into the shared floor; cuts never move actors.

const ROAD_ORIGIN := Vector3(39.2,0,7.2)
const ROAD_CUT_X := 9.6
const GUARDHOUSE_ENTRY := Vector3(8.5,0,3.6)
var shots: Array[ShotRig] = []
var director: CameraDirector
var presentation: PresentationController

func _ready() -> void:
	# Reuse the bounded-floor construction; replace its single camera with rigs.
	super._ready()
	camera.queue_free()
	for number: int in [3,1,2]:
		var source: CalibrationDefinition = load("res://resources/env_1/calibration_cam%02d.tres" % number)
		# A plain shot prevents translated poses being mistaken for calibration data.
		var shot := ShotDefinition.new()
		shot.shot_id = StringName("env1_cam%02d" % number)
		shot.background = source.background
		shot.camera_position = source.camera_position
		shot.camera_rotation_degrees = source.camera_rotation_degrees
		if number == 2:
			var turn := Basis(Vector3.UP, PI)
			shot.camera_position = ROAD_ORIGIN + turn * source.camera_position
			shot.camera_rotation_degrees = (turn * Basis.from_euler(source.camera_rotation_degrees * PI / 180.0)).get_euler() * 180.0 / PI
		shot.fov = source.fov
		var rig := ShotRig.new()
		rig.name = shot.shot_id
		rig.definition = shot
		rig.camera = Camera3D.new()
		rig.add_child(rig.camera)
		rig.light = DirectionalLight3D.new()
		rig.light.rotation = Vector3(-0.7,-0.5,0)
		rig.light.light_color = Color(0.68,0.77,0.9)
		rig.light.light_energy = 0.85
		rig.add_child(rig.light)
		world.add_child(rig)
		shots.append(rig)
	world.get_node("Light").hide()
	# Base probe floor is centered on local cam02. Extend support to the guardhouse.
	_box("GuardhouseFloor",Vector3(2,-0.15,4),Vector3(12,0.3,10))
	presentation = PresentationController.new()
	presentation.background = background
	presentation.player = player
	presentation.shots = shots
	world.add_child(presentation)
	var zones: Array[CameraZone] = []
	# Overlap uses the standard priority and residence rules. Leave room for
	# maximum-speed residence travel at both cuts and both travel directions.
	for index: int in range(3):
		var zone := CameraZone.new()
		zone.shot = shots[index]
		zone.shot_priority = index
		zone.position = [Vector3(0,1,4),Vector3(6,1,4),Vector3(18,1,4)][index]
		zone.collision_layer = 0
		zone.collision_mask = 1
		var shape := BoxShape3D.new()
		# Offset the road zone beyond the indicated x=9.6 endpoint to allow
		# the body radius and standard 0.2 s residence while approaching it.
		shape.size = [Vector3(7,4,10),Vector3(7,4,10),Vector3(2 * (18 - ROAD_CUT_X - 0.8),4,10)][index]
		var collision := CollisionShape3D.new()
		collision.shape = shape
		zone.add_child(collision)
		world.add_child(zone)
		zones.append(zone)
	director = preload("res://environments/env1_camera_director.gd").new()
	director.entry_x = GUARDHOUSE_ENTRY.x
	director.road_shot = shots[2]
	director.guardhouse_shot = shots[1]
	director.player = player
	director.zones = zones
	director.initial_shot = shots[2]
	director.presentation = presentation
	director.process_physics_priority = 10
	director.shot_changed.connect(_on_shot_changed)
	world.add_child(director)

func _on_shot_changed(_previous: StringName, current: StringName) -> void:
	camera = presentation.current_shot.camera
	$Frame/Composition/Instructions.text = "ENV_1 / three views · %s\nWASD / arrows: move · Shift: run · G: show strip\nExperimental connection; stairs and scale still under calibration." % current
