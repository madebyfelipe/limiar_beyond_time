extends CanvasLayer
## Isolated 3D door cinematic, owned by root so it survives the room change.
## No autoload, physics teleport during traversal, or mutation of painted doors.

signal stage_changed(stage_name: StringName)
signal finished

var stage: StringName = &""
var curtain: ColorRect
var cinema: SubViewportContainer
var cinema_frame: Control
var retro_filter: Control
var viewport: SubViewport
var camera: Camera3D
var hinge: Node3D
var handle: Node3D
var controlled_player: PlayerController
var latch: AudioStreamPlayer
var creak: AudioStreamPlayer
var playing: bool = false
var region_title: Label

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
	_build_door()
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
	latch = _sound(preload("res://assets/audio/door_latch.wav"), -8.0)
	creak = _sound(preload("res://assets/audio/door_creak.wav"), -12.0)
	screen.hide()

func _sound(stream: AudioStream, volume: float) -> AudioStreamPlayer:
	var sound := AudioStreamPlayer.new()
	sound.stream = stream
	sound.volume_db = volume
	add_child(sound)
	return sound

func _material(color: Color, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = 0.65
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

func _build_door() -> void:
	var world := Node3D.new()
	viewport.add_child(world)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color.BLACK
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("7e9ba8")
	environment.environment.ambient_light_energy = 0.3
	world.add_child(environment)
	var light := OmniLight3D.new()
	light.position = Vector3(-0.5, 2.9, 2.5)
	light.light_color = Color("c1d2d6")
	light.light_energy = 2.3
	light.omni_range = 7
	world.add_child(light)
	var frame_material := _material(Color("515f62"), 0.5)
	frame_material.albedo_texture = preload("res://assets/textures/doors/painted_steel_v01.png")
	frame_material.uv1_triplanar = true
	frame_material.uv1_scale = Vector3.ONE * 0.7
	_box(world, Vector3(-0.64, 1.1, 0), Vector3(0.15, 2.35, 0.16), frame_material)
	_box(world, Vector3(0.64, 1.1, 0), Vector3(0.15, 2.35, 0.16), frame_material)
	_box(world, Vector3(0, 2.24, 0), Vector3(1.43, 0.15, 0.16), frame_material)
	_box(world, Vector3(0, -0.04, 0.1), Vector3(1.43, 0.08, 0.3), frame_material)
	hinge = Node3D.new()
	hinge.position = Vector3(-0.55, 0, 0)
	world.add_child(hinge)
	var steel := ShaderMaterial.new()
	steel.shader = preload("res://systems/interaction/door_steel.gdshader")
	steel.set_shader_parameter("steel_texture", preload("res://assets/textures/doors/painted_steel_v01.png"))
	_box(hinge, Vector3(0.55, 1.075, 0), Vector3(1.1, 2.15, 0.075), steel)
	_box(hinge, Vector3(0.55, 1.64, 0.045), Vector3(0.39, 0.48, 0.045), frame_material)
	_box(hinge, Vector3(0.55, 1.64, 0.072), Vector3(0.31, 0.39, 0.014), _material(Color("0b1318")))
	_box(hinge, Vector3(0.55, 0.64, 0.048), Vector3(0.92, 0.8, 0.012), steel)
	var chrome := _material(Color("a1a8a1"), 0.85)
	_box(hinge, Vector3(0.93, 0.99, 0.065), Vector3(0.075, 0.23, 0.025), chrome)
	handle = Node3D.new()
	handle.position = Vector3(0.93, 1.035, 0.13)
	hinge.add_child(handle)
	_box(handle, Vector3(-0.085, 0, 0), Vector3(0.2, 0.036, 0.04), chrome)
	for y: float in [0.3, 1.8]:
		_box(hinge, Vector3(0, y, 0.06), Vector3(0.065, 0.15, 0.07), chrome)
	camera = Camera3D.new()
	camera.position = Vector3(0.12, 1.13, 3.65)
	world.add_child(camera)
	camera.look_at(Vector3(0, 1.1, 0))
	camera.fov = 43
	camera.current = true

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

func begin(destination: PackedScene, returning_outside: bool, source_player: PlayerController, destination_name: String = "") -> void:
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
	# Fade from the source gameplay before revealing the isolated doorway.
	screen.get_child(0).hide()
	curtain.modulate.a = 0.0
	_stage(&"fade_out")
	await _fade(1.0, 0.22)
	screen.get_child(0).show()
	cinema_frame.show()
	await _fade(0.0, 0.18)
	_stage(&"latch")
	if DisplayServer.get_name() != "headless":
		latch.play()
	var turn := create_tween()
	turn.tween_property(handle, "rotation:z", 0.38, 0.22)
	await turn.finished
	_stage(&"opening")
	if DisplayServer.get_name() != "headless":
		creak.play()
	var open := create_tween().set_parallel(true)
	open.tween_property(hinge, "rotation:y", 1.72 if returning_outside else -1.72, 1.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	open.tween_property(camera, "position:z", 2.9, 1.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await open.finished
	_stage(&"crossing")
	var advance := create_tween()
	advance.tween_property(camera, "position", Vector3(0.0, 1.13, 0.25), 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(0.24).timeout
	await _fade(1.0, 0.41)
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
