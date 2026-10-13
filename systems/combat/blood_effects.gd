class_name BloodEffects
extends Node3D
## Wounds on flesh: a spray where a round lands, drops that reach the ground as
## stains, and a pool spreading under a body that went down. Lives in the
## creature's world, not on the creature, so stains stay put while it moves.
##
## Stains are flat quads laid a few millimetres over the floor collider, not
## Decals: the floors of the painted scenes draw the plate through an occluder
## shader, and a quad drawn over them reads the same on every floor.

## Oldest stains are recycled past this count, so a long fight cannot grow the
## scene without bound.
const MAX_STAINS := 40
const WORLD_MASK := 1
## Dark red, unshaded: it ignores the night lighting, so it is darkened by hand
## to sit in the plates instead of glowing on them.
const BLOOD := Color(0.33, 0.012, 0.018)
## Height of a stain over the floor collider it was laid on.
const LIFT := 0.05

static var _splat: Texture2D

var stains: Array[MeshInstance3D] = []
var sprays: int = 0

## Called by the creature on every hit it takes.
func wound(point: Vector3, direction: Vector3) -> void:
	sprays += 1
	_spray(point, direction)
	# Most of a wound's blood leaves with the round; some falls straight down.
	var flat := Vector3(direction.x, 0.0, direction.z)
	flat = flat.normalized() if not flat.is_zero_approx() else Vector3.ZERO
	for index: int in range(3):
		var reach: float = 0.35 + 0.45 * index
		var side: Vector3 = flat.cross(Vector3.UP) * randf_range(-0.25, 0.25)
		_stain_below(point + flat * reach + side, randf_range(0.22, 0.38) * (1.0 - 0.2 * index))
	_stain_below(point, randf_range(0.28, 0.36))

## A pool that grows under a body that went down.
func pool(at: Vector3) -> void:
	var stain: MeshInstance3D = _stain_below(at + Vector3.UP * 0.5, 0.2)
	if stain == null:
		return
	var grow := create_tween()
	grow.tween_property(stain, "scale", Vector3.ONE * 7.0, 4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

## Removes every stain, for a level restart.
func clear() -> void:
	for stain: MeshInstance3D in stains:
		if is_instance_valid(stain):
			stain.queue_free()
	stains.clear()
	for child: Node in get_children():
		if child is CPUParticles3D:
			child.queue_free()

func _spray(point: Vector3, direction: Vector3) -> void:
	var burst := CPUParticles3D.new()
	burst.name = "BloodSpray"
	burst.one_shot = true
	burst.emitting = false
	burst.amount = 36
	burst.lifetime = 0.6
	burst.explosiveness = 0.95
	burst.local_coords = false
	burst.direction = direction if not direction.is_zero_approx() else Vector3.UP
	burst.spread = 32.0
	burst.initial_velocity_min = 1.6
	burst.initial_velocity_max = 3.6
	burst.gravity = Vector3(0, -9.8, 0)
	# Seen from cameras 10–15 m away: smaller drops vanish into a pixel or two.
	burst.scale_amount_min = 0.05
	burst.scale_amount_max = 0.1
	var droplet := SphereMesh.new()
	droplet.radius = 0.5
	droplet.height = 1.0
	droplet.radial_segments = 6
	droplet.rings = 3
	var paint := StandardMaterial3D.new()
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.albedo_color = BLOOD
	droplet.material = paint
	burst.mesh = droplet
	add_child(burst)
	burst.global_position = point
	burst.emitting = true
	burst.finished.connect(burst.queue_free)
	# Headless runs never draw, so `finished` may never come. A freed burst
	# drops this connection by itself.
	get_tree().create_timer(1.5).timeout.connect(burst.queue_free)

func _stain_below(from: Vector3, radius: float) -> MeshInstance3D:
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from + Vector3.UP * 0.2, from + Vector3.DOWN * 3.0, WORLD_MASK)
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty() or (hit.normal as Vector3).dot(Vector3.UP) < 0.6:
		return null
	var stain := MeshInstance3D.new()
	stain.name = "BloodStain"
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * radius * 2.0
	quad.orientation = PlaneMesh.FACE_Y
	stain.mesh = quad
	stain.material_override = _stain_material()
	stain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(stain)
	# Floors carry visual-only layers (trail tracks, packed snow) up to ~4 cm over
	# their collider, and a stain under them is hidden. Seen from the fixed
	# cameras above, 5 cm reads as lying on the surface. Stacked stains would
	# z-fight; each lifts a hair above the previous.
	stain.global_position = (hit.position as Vector3) + (hit.normal as Vector3) * (LIFT + 0.0004 * (stains.size() % 10))
	stain.rotation.y = randf() * TAU
	stains.append(stain)
	while stains.size() > MAX_STAINS:
		var oldest: MeshInstance3D = stains.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()
	return stain

var _material: StandardMaterial3D

func _stain_material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_material.albedo_texture = splat()
		_material.albedo_color = BLOOD
		_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return _material

## A soft blob with irregular lobes, white so the material tints it. Built
## once in code, so there is no texture asset to keep in step with the effect.
static func splat() -> Texture2D:
	if _splat != null:
		return _splat
	var size := 64
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var noise := FastNoiseLite.new()
	noise.seed = 7
	noise.frequency = 0.09
	var centre := Vector2(size, size) * 0.5
	for y: int in range(size):
		for x: int in range(size):
			var offset := (Vector2(x, y) - centre) / (size * 0.5)
			var edge: float = 0.62 + 0.28 * noise.get_noise_2d(x, y)
			var alpha: float = clampf((edge - offset.length()) * 6.0, 0.0, 1.0)
			image.set_pixel(x, y, Color(1, 1, 1, alpha))
	image.generate_mipmaps()
	_splat = ImageTexture.create_from_image(image)
	return _splat
