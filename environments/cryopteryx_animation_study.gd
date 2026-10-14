extends Node3D
## Isolated animation review of the Cryopteryx. The walk across the floor is a
## test lane at each cycle's own speed, not enemy AI: there is no actor yet.
const CLIPS: Array[StringName] = [&"idle", &"walk", &"run", &"attack", &"jump", &"death"]
const NAMES := ["1 · Idle", "2 · Walk", "3 · Run", "4 · Attack", "5 · Jump", "6 · Death"]
var visual: CryopteryxVisual
var camera: Camera3D
var caption: Label
var selected: StringName = &"idle"
var travel := true
var orbit := 1.05
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
	# A 1,8 m post beside the lane: Dylan's height, to judge the animal's size.
	var post := MeshInstance3D.new()
	var pole := BoxMesh.new()
	pole.size = Vector3(0.08, 1.8, 0.08)
	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color("c8a24a")
	pole.material = paint
	post.mesh = pole
	post.position = Vector3(-1.6, 0.9, 0)
	add_child(post)
	visual = CryopteryxVisual.new()
	visual.name = "Cryopteryx"
	add_child(visual)
	camera = Camera3D.new()
	camera.fov = 38
	add_child(camera)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 18)
	panel.custom_minimum_size.x = 430
	panel.theme = Theme.new()
	panel.theme.default_font_size = 28
	canvas.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	var title := Label.new()
	title.text = "CRYOPTERYX · ANIMATION STUDY"
	column.add_child(title)
	for index in CLIPS.size():
		var button := Button.new()
		button.text = NAMES[index]
		button.pressed.connect(select_clip.bind(CLIPS[index]))
		column.add_child(button)
	var moving := CheckButton.new()
	moving.text = "Move across the floor"
	moving.button_pressed = true
	moving.toggled.connect(func(value: bool) -> void: travel = value; select_clip(selected))
	column.add_child(moving)
	var help := Label.new()
	help.text = "Left / Right: rotate camera   ·   Esc: exit"
	column.add_child(help)
	caption = Label.new()
	column.add_child(caption)
	select_clip(&"idle")

func select_clip(next: StringName) -> void:
	selected = next
	visual.play_clip(next, float(CryopteryxVisual.NATIVE_SPEED.get(next, -1.0)) if travel else -1.0)

func _process(delta: float) -> void:
	orbit += (float(Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_LEFT))) * delta
	# A one-shot hands back to idle on its own; the lane follows what plays.
	selected = visual.clip
	speed = float(CryopteryxVisual.NATIVE_SPEED.get(selected, 0.0)) if travel else 0.0
	visual.position.z -= speed * delta
	if visual.position.z < -12:
		visual.position.z = 12
	var target := visual.position + Vector3(0, 0.9, -0.2)
	camera.position = target + Vector3(sin(orbit) * 7.5, 1.3, cos(orbit) * 7.5)
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
