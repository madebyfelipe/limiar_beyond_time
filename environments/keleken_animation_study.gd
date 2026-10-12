extends Node3D
## Isolated animation review. Auto movement is a test lane, not enemy AI.
const ACTOR: PackedScene = preload("res://actors/keleken/keleken.tscn")
const CLIPS: Array[StringName] = [&"idle", &"walk", &"run", &"look", &"alert", &"attack_beak", &"recover"]
var actor: KelekenActor
var camera: Camera3D
var caption: Label
var selected: StringName = &"idle"
var travel := true
var orbit := 1.05

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
	var floor_body := StaticBody3D.new()
	add_child(floor_body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(18, 0.2, 36)
	collision.shape = shape
	collision.position.y = -0.1
	floor_body.add_child(collision)
	var floor_mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = shape.size
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("303c46")
	material.roughness = 1.0
	box.material = material
	floor_mesh.mesh = box
	floor_mesh.position.y = -0.1
	floor_body.add_child(floor_mesh)
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
	actor = ACTOR.instantiate()
	add_child(actor)
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
	title.text = "KELEKEN · ANIMATION STUDY"
	column.add_child(title)
	var names := ["1 · Idle", "2 · Walk", "3 · Run", "4 · Look", "5 · Threat", "6 · Beak attack", "7 · Recover"]
	for index in CLIPS.size():
		var button := Button.new()
		button.text = names[index]
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
	actor.drive_velocity = Vector3.ZERO
	actor.visual.play_clip(next)
	caption.text = ""

func _process(delta: float) -> void:
	orbit += (float(Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_LEFT))) * delta
	var target := actor.position + Vector3(0, 1.2, -0.1)
	camera.position = target + Vector3(sin(orbit) * 6.0, 1.4, cos(orbit) * 6.0)
	camera.look_at(target)
	if selected != actor.visual.clip and selected not in KelekenVisual.LOOPING:
		selected = actor.visual.clip
	var speed: float = float(KelekenVisual.NATIVE_SPEED.get(selected, 0.0))
	actor.drive_velocity = Vector3(0, 0, -speed) if travel else Vector3.ZERO
	if travel and speed > 0:
		actor.visual.set_locomotion(Vector2(actor.get_real_velocity().x, actor.get_real_velocity().z).length(), selected == &"run")
	if actor.position.z < -12:
		actor.position.z = 12
	caption.text = "Clip: %s   ·   %.2f m/s" % [actor.visual.clip, Vector2(actor.get_real_velocity().x, actor.get_real_velocity().z).length()]

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.physical_keycode == KEY_ESCAPE:
		get_tree().quit()
	var index: int = event.physical_keycode - KEY_1
	if index >= 0 and index < CLIPS.size():
		select_clip(CLIPS[index])
