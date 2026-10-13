extends CanvasLayer
## Isolated 3D passage cinematic, owned by root so it survives the room change.
## Dylan opens the way himself: one Mixamo capture ("Opening Door Inwards", the
## `door_cross` clip) plays on a figure of its own, and each leaf follows the
## palm that pushes it instead of an authored curve. A door and a gate are two
## sets built around that same performance.
## No autoload, physics teleport during traversal, or mutation of painted doors.

signal stage_changed(stage_name: StringName)
signal finished

const RIG: PackedScene = preload("res://assets/models/dylan_protagonist/mixamo/dylan_rig_idle.fbx")
const CLIPS: AnimationLibrary = preload("res://assets/models/dylan_protagonist/mixamo/dylan_clips.res")
const CROSSING := &"door_cross"
## The rig stands 0,9761 tall; both sets are built for the 1,8 m Dylan.
const FIGURE_SCALE := 1.8 / 0.9761
## Moments of the capture, in its own seconds. The gameplay gesture ends where
## the cinematic cuts in; the hand is on the handle from LATCH, pushes from
## PUSH and lets go at RELEASE; the body is in the opening from CROSS and the
## picture is black by CUT_OUT, before the capture turns round to shut the door.
const CUT_IN := 1.75
const LATCH := 2.0
const PUSH := 2.45
const RELEASE := 3.15
const CROSS := 3.3
const FADE := 3.85
const CUT_OUT := 4.45
const STEP := 1.0 / 60.0
const RIGHT_HAND := ["mixamorig_RightHand", "mixamorig_RightHandMiddle1"]
const LEFT_HAND := ["mixamorig_LeftHand", "mixamorig_LeftHandMiddle1"]

## One swinging leaf, opening away from the camera about a vertical hinge.
class Leaf:
	var pivot: Node3D
	## +1 when the leaf runs from its hinge toward +X, -1 toward -X.
	var reach: float = 1.0
	var limit: float = deg_to_rad(94.0)
	## Once no hand is on it: what the swing loses per second, and the pace
	## it keeps anyway, both in rad/s.
	var drag: float = 0.0
	var coast: float = 0.0
	## Hands that push it: bone pair, the stretch of the capture in which the
	## palm is on it, and how far in front of the hinge plane the palm rests.
	var pushes: Array[Dictionary] = []
	## A leaf carried along by another while that one is being pushed.
	var carried_by: Leaf
	var angle: float = 0.0
	var speed: float = 0.0

## Which set is built: &"door" or &"gate". Set before entering the tree.
var passage: StringName = &"door"
var stage: StringName = &""
var curtain: ColorRect
var cinema: SubViewportContainer
var cinema_frame: Control
var retro_filter: Control
var viewport: SubViewport
var camera: Camera3D
var handle: Node3D
var leaves: Array[Leaf] = []
var figure: Node3D
var skeleton: Skeleton3D
var animator: AnimationPlayer
var controlled_player: PlayerController
var latch: AudioStreamPlayer
var creak: AudioStreamPlayer
var playing: bool = false
var region_title: Label
## Capture time shown, and whether `_process` is advancing it.
var clock: float = CUT_IN
var running: bool = false
## Where the right palm closes on the handle, in the set.
var grip: Vector3
## How far the handle turns under the hand, in radians about Z.
var handle_turn: float = 0.38
var _camera_from: Vector3
var _camera_to: Vector3
var _look_from: Vector3
var _look_to: Vector3

func _ready() -> void:
	layer = 100
	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(screen)
	var black := ColorRect.new()
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.color = Color.BLACK
	screen.add_child(black)
	var frame := AspectRatioContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.ratio = 16.0 / 9.0
	screen.add_child(frame)
	cinema_frame = Control.new()
	cinema_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cinema_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cinema_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(cinema_frame)
	cinema = SubViewportContainer.new()
	cinema.stretch = true
	cinema.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cinema_frame.add_child(cinema)
	viewport = SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	cinema.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	camera = Camera3D.new()
	world.add_child(camera)
	camera.current = true
	if passage == &"gate":
		_build_gate(world)
	else:
		_build_door(world)
	_build_figure(world)
	pose_at(CUT_IN)
	retro_filter = preload("res://systems/rendering/retro_filter.tscn").instantiate()
	retro_filter.allow_mode_input = false
	cinema_frame.add_child(retro_filter)
	region_title = Label.new()
	region_title.name = "DestinationName"
	region_title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	region_title.anchor_top = 0.85
	region_title.anchor_bottom = 0.95
	region_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	region_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	region_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	region_title.add_theme_color_override("font_color", Color("dce6df"))
	region_title.add_theme_color_override("font_shadow_color", Color.BLACK)
	region_title.add_theme_constant_override("shadow_offset_x", 2)
	region_title.add_theme_constant_override("shadow_offset_y", 2)
	region_title.add_theme_font_override("font", RetroScreen.font())
	cinema_frame.add_child(region_title)
	cinema_frame.resized.connect(func() -> void:
		region_title.add_theme_font_size_override("font_size", maxi(16, roundi(cinema_frame.size.y / 1080.0 * 32.0))))
	curtain = ColorRect.new()
	curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	curtain.color = Color.BLACK
	screen.add_child(curtain)
	screen.hide()

func _sound(stream: AudioStream, volume: float) -> AudioStreamPlayer:
	var sound := AudioStreamPlayer.new()
	sound.stream = stream
	sound.volume_db = volume
	add_child(sound)
	return sound

func _material(color: Color, metallic: float = 0.0, roughness: float = 0.65) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material

## Painted steel in the given colour, the texture laid on without unwrapping.
func _steel(color: Color, metallic: float = 0.5) -> StandardMaterial3D:
	var material := _material(color, metallic)
	material.albedo_texture = preload("res://assets/textures/doors/painted_steel_v01.png")
	material.uv1_triplanar = true
	material.uv1_scale = Vector3.ONE * 0.7
	return material

func _box(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = material
	mesh.position = at
	parent.add_child(mesh)
	return mesh

func _ambience(world: Node3D, ambient: Color, energy: float) -> void:
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color.BLACK
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = ambient
	environment.environment.ambient_light_energy = energy
	world.add_child(environment)

func _lamp(world: Node3D, at: Vector3, color: Color, energy: float, reach: float) -> void:
	var light := OmniLight3D.new()
	light.position = at
	light.light_color = color
	light.light_energy = energy
	light.omni_range = reach
	world.add_child(light)

func _leaf(world: Node3D, hinge_x: float, reach: float) -> Leaf:
	var leaf := Leaf.new()
	leaf.pivot = Node3D.new()
	leaf.pivot.position = Vector3(hinge_x, 0, 0)
	leaf.reach = reach
	world.add_child(leaf.pivot)
	leaves.append(leaf)
	return leaf

## A steel door in its wall, hinged on the left and pushed into the dark room
## beyond: the right hand turns the handle and pushes, the left steadies the
## open leaf as the body passes.
func _build_door(world: Node3D) -> void:
	_ambience(world, Color("7e9ba8"), 0.3)
	_lamp(world, Vector3(-0.5, 2.9, 2.5), Color("c1d2d6"), 2.3, 7.0)
	var frame_material := _steel(Color("515f62"))
	_box(world, Vector3(-0.64, 1.1, 0), Vector3(0.15, 2.35, 0.16), frame_material)
	_box(world, Vector3(0.64, 1.1, 0), Vector3(0.15, 2.35, 0.16), frame_material)
	_box(world, Vector3(0, 2.24, 0), Vector3(1.43, 0.15, 0.16), frame_material)
	_box(world, Vector3(0, -0.04, 0.1), Vector3(1.43, 0.08, 0.3), frame_material)
	# The wall the frame sits in and the floor Dylan stands on; past the
	# doorway the lamp runs out and the room is left dark.
	var wall := _material(Color("2c3539"), 0.0, 0.9)
	for x: float in [-2.6, 2.6]:
		_box(world, Vector3(x, 1.6, -0.02), Vector3(3.77, 3.2, 0.12), wall)
	_box(world, Vector3(0, 2.76, -0.02), Vector3(1.43, 0.89, 0.12), wall)
	_box(world, Vector3(0, -0.055, 0.5), Vector3(9, 0.1, 9), _material(Color("23292c"), 0.0, 0.85))
	var door := _leaf(world, -0.55, 1.0)
	door.drag = deg_to_rad(25.0)
	door.coast = deg_to_rad(14.0)
	door.pushes = [
		{"hand": RIGHT_HAND, "from": PUSH, "to": RELEASE, "offset": 0.13},
		{"hand": LEFT_HAND, "from": 3.5, "to": CUT_OUT, "offset": 0.07},
	]
	var hinge: Node3D = door.pivot
	var steel := ShaderMaterial.new()
	steel.shader = preload("res://systems/interaction/door_steel.gdshader")
	steel.set_shader_parameter("steel_texture", preload("res://assets/textures/doors/painted_steel_v01.png"))
	_box(hinge, Vector3(0.55, 1.075, 0), Vector3(1.1, 2.15, 0.075), steel)
	_box(hinge, Vector3(0.55, 1.64, 0.045), Vector3(0.39, 0.48, 0.045), frame_material)
	_box(hinge, Vector3(0.55, 1.64, 0.072), Vector3(0.31, 0.39, 0.014), _material(Color("0b1318")))
	_box(hinge, Vector3(0.55, 0.64, 0.048), Vector3(0.92, 0.8, 0.012), steel)
	var chrome := _material(Color("a1a8a1"), 0.85)
	_box(hinge, Vector3(0.93, 1.015, 0.065), Vector3(0.075, 0.23, 0.025), chrome)
	handle = Node3D.new()
	handle.position = Vector3(0.93, 1.06, 0.13)
	hinge.add_child(handle)
	_box(handle, Vector3(-0.085, 0, 0), Vector3(0.2, 0.036, 0.04), chrome)
	for y: float in [0.3, 1.8]:
		_box(hinge, Vector3(0, y, 0.06), Vector3(0.065, 0.15, 0.07), chrome)
	grip = hinge.position + handle.position + Vector3(-0.085, 0, 0)
	# Over his right shoulder, so the hand and the handle stay in view.
	_camera_from = Vector3(1.55, 1.5, 3.55)
	_camera_to = Vector3(1.0, 1.42, 2.75)
	_look_from = Vector3(0.05, 1.08, 0)
	_look_to = Vector3(0.0, 1.05, -0.4)
	camera.fov = 43
	latch = _sound(preload("res://assets/audio/door_latch.wav"), -8.0)
	creak = _sound(preload("res://assets/audio/door_creak.wav"), -12.0)

## The north service gate: two sheet leaves between concrete posts, in the
## snow. Dylan lifts the lever where they meet and pushes the right leaf, which
## carries the left one with it until his left hand sends that one on.
func _build_gate(world: Node3D) -> void:
	_ambience(world, Color("8ea6c2"), 0.42)
	_lamp(world, Vector3(-1.6, 3.4, 3.2), Color("e8d3a2"), 3.0, 9.0)
	_lamp(world, Vector3(2.4, 2.6, -3.0), Color("9db4d2"), 1.1, 8.0)
	var snow := _material(Color("c3d0d9"), 0.0, 0.95)
	var concrete := _material(Color("6b7378"), 0.0, 0.9)
	_box(world, Vector3(0, -0.05, -1), Vector3(16, 0.1, 14), snow)
	for x: float in [-0.85, 0.85]:
		_box(world, Vector3(x, 0.004, -1), Vector3(0.34, 0.012, 14), _material(Color("4d5d67"), 0.0, 0.8))
	for x: float in [-2.6, 2.6]:
		_box(world, Vector3(x, 1.05, 0), Vector3(0.3, 2.1, 0.3), concrete)
		_box(world, Vector3(x, 2.13, 0), Vector3(0.34, 0.07, 0.34), snow)
		_box(world, Vector3(x * 2.0, 1.0, 0), Vector3(4.9, 2.0, 0.16), concrete)
		_box(world, Vector3(x * 2.0, 2.03, 0), Vector3(4.9, 0.07, 0.2), snow)
	var sheet := _steel(Color("b9c79c"), 0.1)
	var rail := _steel(Color("8f9c79"), 0.2)
	for reach: float in [-1.0, 1.0]:
		var leaf := _leaf(world, -2.45 * reach, reach)
		leaf.limit = deg_to_rad(62.0)
		leaf.coast = deg_to_rad(13.0)
		var hinge: Node3D = leaf.pivot
		_box(hinge, Vector3(1.23 * reach, 0.98, 0), Vector3(2.42, 1.8, 0.035), sheet)
		for y: float in [0.12, 1.84]:
			_box(hinge, Vector3(1.23 * reach, y, 0), Vector3(2.42, 0.08, 0.075), rail)
		for y: float in [0.62, 1.38]:
			_box(hinge, Vector3(1.23 * reach, y, 0.03), Vector3(2.42, 0.06, 0.05), rail)
		for x: float in [0.06, 2.4]:
			_box(hinge, Vector3(x * reach, 0.98, 0), Vector3(0.08, 1.8, 0.075), rail)
		_box(hinge, Vector3(1.23 * reach, 1.9, 0), Vector3(2.42, 0.05, 0.1), snow)
		for y: float in [0.4, 1.56]:
			_box(hinge, Vector3(0.0, y, 0.05), Vector3(0.1, 0.16, 0.08), _material(Color("3d4648"), 0.7))
	var right: Leaf = leaves[0]
	var left: Leaf = leaves[1]
	right.pushes = [{"hand": RIGHT_HAND, "from": PUSH, "to": RELEASE, "offset": 0.13}]
	left.pushes = [{"hand": LEFT_HAND, "from": 3.5, "to": CUT_OUT, "offset": 0.075}]
	left.carried_by = right
	_box(right.pivot, Vector3(-0.82, 1.52, 0.03), Vector3(0.62, 0.4, 0.02), _material(Color("c7b672"), 0.2))
	# The lever pivots under the hand; its far end drops into a keeper on the
	# other leaf and lifts out of it as the hand turns.
	var iron := _material(Color("8d9490"), 0.8)
	_box(right.pivot, Vector3(-2.2, 1.06, 0.06), Vector3(0.16, 0.2, 0.05), iron)
	_box(left.pivot, Vector3(2.33, 1.03, 0.06), Vector3(0.12, 0.16, 0.05), iron)
	handle = Node3D.new()
	handle.position = Vector3(-2.2, 1.06, 0.13)
	right.pivot.add_child(handle)
	_box(handle, Vector3(-0.19, 0, 0), Vector3(0.46, 0.045, 0.045), iron)
	handle_turn = -0.75
	grip = right.pivot.position + handle.position
	# Lower and wider than the door, from the yard side of his right shoulder.
	_camera_from = Vector3(2.5, 1.25, 4.7)
	_camera_to = Vector3(1.9, 1.2, 3.9)
	_look_from = Vector3(0.1, 1.0, 0)
	_look_to = Vector3(0.1, 1.0, -0.5)
	camera.fov = 46
	latch = _sound(preload("res://assets/audio/gate_latch.wav"), -7.0)
	creak = _sound(preload("res://assets/audio/gate_swing.wav"), -11.0)

## Dylan's rig on its own, facing the set, stood where the capture puts his
## right palm on the handle as the push begins.
func _build_figure(world: Node3D) -> void:
	figure = RIG.instantiate()
	figure.scale = Vector3.ONE * FIGURE_SCALE
	# The captures face +Z; the way through is -Z.
	figure.rotation.y = PI
	world.add_child(figure)
	skeleton = figure.find_child("Skeleton3D", true, false) as Skeleton3D
	animator = figure.find_child("AnimationPlayer", true, false) as AnimationPlayer
	animator.remove_animation_library(&"")
	animator.add_animation_library(&"", CLIPS)
	# The clock below owns the time, so every frame poses the body first and
	# reads the hands from that same pose.
	animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	animator.play(CROSSING)
	animator.seek(PUSH, true)
	var reach: Vector3 = palm(RIGHT_HAND)
	figure.position += Vector3(grip.x - reach.x, 0, grip.z - reach.z)

## Middle of a palm in the set: halfway from the wrist to the middle knuckle.
func palm(hand: Array) -> Vector3:
	var wrist: Vector3 = skeleton.get_bone_global_pose(skeleton.find_bone(hand[0])).origin
	var knuckle: Vector3 = skeleton.get_bone_global_pose(skeleton.find_bone(hand[1])).origin
	return skeleton.global_transform * wrist.lerp(knuckle, 0.5)

## A bone of the figure in the set, by its Mixamo name without the prefix.
func bone_position(bone: String) -> Vector3:
	return skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("mixamorig_" + bone)).origin

## The angle at which the leaf's near face, `offset` in front of its hinge
## plane, meets a palm.
func contact_angle(leaf: Leaf, at: Vector3, offset: float) -> float:
	var along: float = leaf.reach * (at.x - leaf.pivot.position.x)
	var depth: float = at.z - leaf.pivot.position.z
	var radius: float = Vector2(along, depth).length()
	if along <= 0.0 or radius <= offset:
		return 0.0
	return asin(offset / radius) - atan2(depth, along)

## Shows the capture at `time`, stepped from the cut so the leaves arrive with
## the swing they would have. For previews and probes; the cinematic itself
## advances frame by frame.
func pose_at(time: float) -> void:
	clock = CUT_IN
	for leaf: Leaf in leaves:
		leaf.angle = 0.0
		leaf.speed = 0.0
	_advance(0.0)
	while clock < time - 0.0001:
		_advance(minf(STEP, time - clock))

func _advance(delta: float) -> void:
	clock += delta
	animator.seek(clock, true)
	for leaf: Leaf in leaves:
		_swing(leaf, delta)
	handle.rotation.z = handle_turn * smoothstep(LATCH, LATCH + 0.3, clock)
	var travel: float = smoothstep(PUSH, CUT_OUT, clock)
	camera.position = _camera_from.lerp(_camera_to, travel)
	camera.look_at(_look_from.lerp(_look_to, travel))

## A leaf is never behind the palm that pushes it; left alone it keeps the
## swing it was given.
func _swing(leaf: Leaf, delta: float) -> void:
	var pushed: float = leaf.angle
	for push: Dictionary in leaf.pushes:
		if clock >= push["from"] and clock <= push["to"]:
			pushed = maxf(pushed, contact_angle(leaf, palm(push["hand"]), push["offset"]))
	if leaf.carried_by != null and clock <= RELEASE:
		pushed = maxf(pushed, leaf.carried_by.angle)
	if pushed > leaf.angle:
		if delta > 0.0:
			leaf.speed = lerpf(leaf.speed, minf((pushed - leaf.angle) / delta, deg_to_rad(140.0)), 0.3)
		leaf.angle = pushed
	elif leaf.angle > 0.0:
		leaf.speed = maxf(leaf.coast, leaf.speed - leaf.drag * delta)
		leaf.angle += leaf.speed * delta
	leaf.angle = minf(leaf.angle, leaf.limit)
	leaf.pivot.rotation.y = leaf.reach * leaf.angle

func _process(delta: float) -> void:
	if running:
		_advance(delta)

func _input(event: InputEvent) -> void:
	if playing and (event is InputEventKey or event is InputEventMouseButton):
		get_viewport().set_input_as_handled()

func _stage(value: StringName) -> void:
	stage = value
	stage_changed.emit(value)

func _fade(alpha: float, seconds: float) -> void:
	var tween := create_tween()
	tween.tween_property(curtain, "modulate:a", alpha, seconds)
	await tween.finished

## Waits for the capture to reach one of its moments.
func _until(time: float) -> void:
	while clock < time:
		await get_tree().process_frame

func _play(sound: AudioStreamPlayer) -> void:
	if DisplayServer.get_name() != "headless":
		sound.play()

func begin(destination: PackedScene, source_player: PlayerController, destination_name: String = "") -> void:
	if playing:
		return
	playing = true
	region_title.text = (destination_name if not destination_name.is_empty() else destination.resource_path.get_file().get_basename().capitalize()).to_upper()
	controlled_player = source_player
	var carried_vitality: float = source_player.vitality
	var carried_supplies: Dictionary = SupplyStock.snapshot()
	_stage(&"gesture")
	await get_tree().create_timer(0.72).timeout
	var screen: Control = get_child(0)
	screen.show()
	cinema_frame.hide()
	# Fade from the source gameplay before revealing the isolated passage.
	screen.get_child(0).hide()
	curtain.modulate.a = 0.0
	_stage(&"fade_out")
	await _fade(1.0, 0.22)
	screen.get_child(0).show()
	cinema_frame.show()
	# The hand is already rising to the handle as the picture comes up.
	pose_at(CUT_IN)
	running = true
	await _fade(0.0, 0.18)
	_stage(&"latch")
	await _until(LATCH)
	_play(latch)
	await _until(PUSH)
	_stage(&"opening")
	_play(creak)
	await _until(CROSS)
	_stage(&"crossing")
	await _until(FADE)
	await _fade(1.0, CUT_OUT - FADE)
	running = false
	_stage(&"loading")
	var error: Error = get_tree().change_scene_to_packed(destination)
	if error != OK:
		push_error("Door travel failed: " + error_string(error))
		_restore_control()
		finished.emit()
		queue_free()
		return
	await get_tree().scene_changed
	var room: Node = get_tree().current_scene
	room.arrive_from_door()
	controlled_player = room.player
	controlled_player.restore_vitality(carried_vitality)
	SupplyStock.restore(carried_supplies)
	controlled_player.set_control_enabled(false)
	cinema_frame.hide()
	screen.get_child(0).hide()
	_stage(&"fade_in")
	await _fade(0.0, 0.3)
	_restore_control()
	_stage(&"complete")
	finished.emit()
	queue_free()

func _restore_control() -> void:
	if is_instance_valid(controlled_player):
		controlled_player.set_control_enabled(true)
		var dylan: Node = controlled_player.visual.get_node_or_null("DylanVisual")
		if dylan:
			dylan.end_interaction()
	playing = false

func _exit_tree() -> void:
	if is_instance_valid(latch):
		latch.stop()
		latch.stream = null
	if is_instance_valid(creak):
		creak.stop()
		creak.stream = null
	_restore_control()
