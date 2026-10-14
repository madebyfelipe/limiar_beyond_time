extends Node3D
## Isolated animation review of the Cryopteryx. The walk across the floor is a
## test lane at each cycle's own speed, not enemy AI: there is no actor yet.
const CLIPS: Array[StringName] = [&"idle", &"walk", &"run", &"attack", &"jump", &"death"]
const NAMES := ["1 · Idle", "2 · Walk", "3 · Run", "4 · Attack", "5 · Jump", "6 · Death"]
const KELEKEN := preload("res://actors/keleken/keleken.tscn")
const PLAYER := preload("res://actors/player/player_dylan.tscn")
var visual: CryopteryxVisual
var references: Node3D
var camera: Camera3D
var caption: Label
var selected: StringName = &"idle"
var travel := false
var orbit := PI / 2.0
## Ground speed of the lane this frame, for the caption and the probe.
var speed := 0.0

func _ready() -> void:
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("19232e")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("d0dce9")
	environment.environment.ambient_light_energy = 0.6
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -30, 0)
	light.light_energy = 1.5
	light.shadow_enabled = true
	light.shadow_bias = .02
	light.shadow_normal_bias = .2
	add_child(light)
	var floor_mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(18, 0.2, 36)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("303c46")
	material.roughness = 1.0
	box.material = material
	floor_mesh.mesh = box
	floor_mesh.position.y = -0.1
	add_child(floor_mesh)
	# Ground markings let the moving-foot contact be judged visually.
	for line in range(-16, 17):
		var mark := MeshInstance3D.new()
		var stripe := BoxMesh.new()
		stripe.size = Vector3(9, 0.003, 0.025)
		var finish := StandardMaterial3D.new()
		finish.albedo_color = Color("687581")
		stripe.material = finish
		mark.mesh = stripe
		mark.position = Vector3(0, .002, line)
		add_child(mark)
	visual = CryopteryxVisual.new()
	visual.name = "Cryopteryx"
	add_child(visual)
	_build_references()
	camera = Camera3D.new()
	# Orthographic framing compares actual scale without perspective distortion.
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.size = 14.5
	add_child(camera)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 18)
	panel.custom_minimum_size.x = 430
	panel.theme = Theme.new()
	panel.theme.default_font_size = 24
	canvas.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	var title := Label.new()
	title.text = "CRYOPTERYX · ANIMATION STUDY"
	column.add_child(title)
	var buttons := HBoxContainer.new()
	column.add_child(buttons)
	for index in CLIPS.size():
		var button := Button.new()
		button.text = NAMES[index]
		button.pressed.connect(select_clip.bind(CLIPS[index]))
		buttons.add_child(button)
	var moving := CheckButton.new()
	moving.text = "Move across the floor (solo)"
	moving.button_pressed = travel
	moving.toggled.connect(set_travel)
	column.add_child(moving)
	var help := Label.new()
	help.text = "Left / Right: rotate camera   ·   Esc: exit"
	column.add_child(help)
	caption = Label.new()
	column.add_child(caption)
	select_clip(&"idle")

func _build_references() -> void:
	references = Node3D.new()
	references.name = "SizeReferences"
	add_child(references)
	# Reuse the game's visual at its authored scale, without enemy AI/collision.
	var actor := KELEKEN.instantiate()
	var keleken := actor.get_node("Visual") as KelekenVisual
	actor.remove_child(keleken)
	actor.free()
	keleken.name = "Keleken"
	keleken.position.z = -6.3
	references.add_child(keleken)
	var player := PLAYER.instantiate() as PlayerController
	player.name = "PlayerReference"
	player.position.z = -9.0
	references.add_child(player)
	player.set_control_enabled(false)
	player.set_physics_process(false)
	player.weapon.process_mode = Node.PROCESS_MODE_DISABLED
	player.visual.get_node("DylanVisual").play_scripted(&"idle")
	_size_label(references, "Cryopteryx · ~2.7 m tall", Vector3(0, -0.35, 0))
	_size_label(references, "Keleken · 2.4 m tall", Vector3(0, -0.35, -6.3))
	_size_label(references, "Player / Dylan · 1.8 m tall", Vector3(0, -0.35, -9.0))

func _size_label(parent: Node3D, text: String, at: Vector3) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.font_size = 40
	label.pixel_size = 0.0035
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	parent.add_child(label)

func set_travel(enabled: bool) -> void:
	travel = enabled
	references.visible = not enabled
	visual.position = Vector3.ZERO
	select_clip(selected)

func _ground_speed(clip: StringName) -> float:
	return float(CryopteryxVisual.NATIVE_SPEED.get(clip, 0.0)) * visual.target_length / CryopteryxVisual.SOURCE_LENGTH

func select_clip(next: StringName) -> void:
	selected = next
	visual.play_clip(next, _ground_speed(next) if travel else -1.0)

func _process(delta: float) -> void:
	orbit += (float(Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_LEFT))) * delta
	# A one-shot hands back to idle on its own; the lane follows what plays.
	selected = visual.clip
	speed = _ground_speed(selected) if travel else 0.0
	visual.position.z -= speed * delta
	if visual.position.z < -12:
		visual.position.z = 12
	var target := visual.position + Vector3(0, 2.7, -0.2) if travel else Vector3(0, 2.7, -3.4)
	camera.size = 13.0 if travel else 19.0
	camera.position = target + Vector3(sin(orbit) * 16.0, 1.3, cos(orbit) * 16.0)
	camera.look_at(target)
	caption.text = "Clip: %s   ·   %.2f m/s" % [selected, speed]

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.physical_keycode == KEY_ESCAPE:
		get_tree().quit()
	var index: int = event.physical_keycode - KEY_1
	if index >= 0 and index < CLIPS.size():
		select_clip(CLIPS[index])
