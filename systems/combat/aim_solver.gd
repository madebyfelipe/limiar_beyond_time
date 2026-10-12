class_name AimSolver
extends RefCounted
## Geometry shared by the aiming modes. The 3D world renders into a SubViewport
## inside the 16:9 frame, so the mouse has to be carried from the window into
## that viewport before a camera can turn it into a ray.

## Yaw in the convention of PlayerController.visual: 0 faces -Z.
static func yaw_of(vector: Vector3) -> float:
	return atan2(-vector.x, -vector.z)

static func direction(yaw: float, pitch: float) -> Vector3:
	return Vector3(-sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch))

static func pitch_of(vector: Vector3) -> float:
	return atan2(vector.y, Vector2(vector.x, vector.z).length())

static func _container(camera: Camera3D) -> SubViewportContainer:
	return camera.get_viewport().get_parent() as SubViewportContainer

## The mouse in pixels of the viewport this camera renders to.
static func pointer(camera: Camera3D) -> Vector2:
	var viewport: Viewport = camera.get_viewport()
	var container: SubViewportContainer = _container(camera)
	if container == null or container.size.x <= 0.0:
		return viewport.get_mouse_position()
	return container.get_local_mouse_position() * Vector2(viewport.get_visible_rect().size) / container.size

## A movement of the mouse in window (root viewport) units, in the camera
## viewport's pixels instead.
static func window_delta_to_viewport(camera: Camera3D, delta: Vector2) -> Vector2:
	var container: SubViewportContainer = _container(camera)
	if container == null or container.size.x <= 0.0:
		return delta
	var local: Vector2 = container.get_global_transform_with_canvas().basis_xform_inv(delta)
	return local * Vector2(camera.get_viewport().get_visible_rect().size) / container.size

## Where the camera ray through a viewport pixel meets the horizontal plane at
## this height, or null when it never does (the ray points above the horizon).
static func ground_point(camera: Camera3D, screen: Vector2, height: float) -> Variant:
	var origin: Vector3 = camera.project_ray_origin(screen)
	var normal: Vector3 = camera.project_ray_normal(screen)
	if absf(normal.y) < 0.0001:
		return null
	var distance: float = (height - origin.y) / normal.y
	if distance <= 0.0:
		return null
	return origin + normal * distance

## The screen direction a world heading takes on from a point on the floor:
## where the floor line along that heading is drawn. Projecting the same line
## back onto the floor returns the same heading, which is what lets a mouse
## movement nudge a heading kept in world space.
static func screen_heading(camera: Camera3D, feet: Vector3, yaw: float) -> Vector2:
	if camera.is_position_behind(feet):
		return Vector2.UP
	var from: Vector2 = camera.unproject_position(feet)
	var along: Vector3 = feet + direction(yaw, 0.0)
	if camera.is_position_behind(along):
		return Vector2.UP
	var screen: Vector2 = camera.unproject_position(along) - from
	return screen.normalized() if screen.length() > 0.001 else Vector2.UP
