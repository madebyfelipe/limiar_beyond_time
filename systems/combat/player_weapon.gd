class_name PlayerWeapon
extends Node3D
## The pistol in Dylan's hands: raising it, where it points, firing, reloading
## and what a shot hits. It is the single owner of the aim; PlayerController
## and DylanVisual only read `aiming`, `heading` and `turn_input` from here.
##
## Tank scheme -- Resident Evil / Dino Crisis. Raising the gun stops Dylan and,
## with auto-target on, turns him to the nearest target he can see. Left/right
## turn him by hand and up/down tilt the gun, either of which drops the lock;
## "next target" cycles through what is in sight.
##
## Modern scheme -- Dylan keeps walking in any direction while the gun follows
## the mouse around him. How the mouse becomes a heading is AimSettings.modern.
##
## Shots are 3D rays: walls stop them, the art does not.

signal fired(shot: Dictionary)
signal ammo_changed
signal target_changed(target: Hurtbox)
signal weapon_changed

const DEFAULT_DEFINITION := preload("res://resources/combat/pistol.tres")
const RIFLE_DEFINITION := preload("res://resources/combat/rifle.tres")
## The guns Dylan can carry, in the order the switch cycles through them.
const ARSENAL: Array[WeaponDefinition] = [DEFAULT_DEFINITION, RIFLE_DEFINITION]
const WORLD_MASK := 1
## Shots and sight lines leave from the chest: this fraction of the body's
## collision height, 1,2 m on the 1,8 m Dylan of the levels and 1,6 m on the
## 2,4 m rig of the studies. The ray starts on the body axis, not at the hand,
## so a gun pressed against a wall cannot shoot through it.
const CHEST_FRACTION := 0.67
## Tank up/down tilt: RE aims high and low, not at arbitrary angles.
const TANK_TILT := 0.52
## Assisted aim pulls onto a target within this angle of the cursor heading.
const ASSIST_CONE := 0.35
## A locked shot goes to the target only once the body has turned this close
## to it; before that it leaves along the body, like the rendered gun.
const LOCK_FIRE_TOLERANCE := 0.2
## Radius, in viewport pixels, of the circle the free reticle swings on. Mouse
## movement is measured against it, so it sets how far a flick turns Dylan.
const FREE_RADIUS := 220.0
## Selection tolerance relative to viewport height, independent of resolution.
const LOCK_PICK_RADIUS := 0.04

@export var definition: WeaponDefinition
@export var player: PlayerController
## A firing range lends the gun and does not draw on the real stock.
@export var practice: bool = false

## Rounds in the magazine. Static, so a door does not refill or empty it; -1
## is a gun not yet drawn, which comes loaded.
static var magazine: int = -1
## The gun in hand across scenes, and what each holstered one still holds.
static var equipped: StringName = &"pistol"
static var spare_magazines: Dictionary = {}

var aiming: bool = false
## Capture the aim's input source until L2/right mouse is released. A resting
## mouse must not drive a gamepad aim, including after a camera cut.
var gamepad_aim: bool = false
## Desired body yaw while aiming, in the convention of player.visual.rotation.
var heading: float = 0.0
var pitch: float = 0.0
var target: Hurtbox
## Tank only: +1 turning left by hand, -1 right, while the gun is up.
var turn_input: float = 0.0
var cooldown: float = 0.0
var reload_left: float = 0.0
var last_shot: Dictionary = {}
## Probes: a pointer position (viewport pixels) in place of the real mouse.
var pointer_override: Variant = null
## Probes: this frame's mouse movement for the free mode, in viewport pixels.
var free_motion_override: Variant = null
## The gun tip, when a visual provides one; tracers start there.
var muzzle_marker: Node3D
var muzzle_height: float = 1.6
var _window_anchor: Vector2 = Vector2.ZERO
var _marker: MeshInstance3D
var _marker_mesh := ImmediateMesh.new()
var _tracer: MeshInstance3D
var _tracer_mesh := ImmediateMesh.new()
var _tracer_left: float = 0.0
var _flash: OmniLight3D
var _aim_requires_release: bool = false
var _fire_requires_release: bool = false
var _active_mode: AimSettings.Modern
var _active_tank: bool
var _stick_cycle_ready: bool = true
var aim_cursor_hidden: bool = false
var _mouse_mode_before_aim: Input.MouseMode = Input.MOUSE_MODE_VISIBLE

func _ready() -> void:
	# Ahead of the body, so the controller reads this frame's aim.
	process_physics_priority = -1
	if player == null:
		player = get_parent() as PlayerController
	if definition == null:
		definition = DEFAULT_DEFINITION
	if magazine < 0:
		magazine = definition.magazine
	var collision := player.get_node_or_null(^"Collision") as CollisionShape3D
	if collision != null and collision.shape is CapsuleShape3D:
		muzzle_height = CHEST_FRACTION * (collision.shape as CapsuleShape3D).height
	AimSettings.ensure_loaded()
	ControlScheme.ensure_loaded()
	_active_mode = AimSettings.modern
	_active_tank = ControlScheme.is_tank()
	_marker = _overlay_mesh(_marker_mesh)
	_tracer = _overlay_mesh(_tracer_mesh)
	_flash = OmniLight3D.new()
	_flash.top_level = true
	_flash.light_color = Color(1.0, 0.82, 0.5)
	_flash.light_energy = 0.0
	_flash.omni_range = 4.0
	add_child(_flash)

func _overlay_mesh(mesh: ImmediateMesh) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.top_level = true
	instance.mesh = mesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	return instance

## Loaded, ready to fire and lowered: what a restart hands back.
func reset_state() -> void:
	interrupt_input()
	# Refill the gun in hand, which may not have been settled into yet.
	var held: WeaponDefinition = _definition(equipped)
	magazine = (held if held != null else definition).magazine
	spare_magazines.clear()
	cooldown = 0.0
	reload_left = 0.0
	ammo_changed.emit()

func is_armed() -> bool:
	return owns(definition)

## Whether Dylan has this gun: everything on the range, purchases elsewhere.
func owns(candidate: WeaponDefinition) -> bool:
	if practice:
		return true
	SupplyStock.ensure_loaded()
	return SupplyStock.rifle if candidate.id == &"rifle" else SupplyStock.weapon

## Puts the next owned gun in hand. Raising, firing and reloading stop, so the
## switch can never leave a half-finished reload on either magazine.
func switch_weapon() -> bool:
	if not player.can_use_weapon():
		return false
	var at: int = ARSENAL.find(_definition(definition.id))
	for step: int in range(1, ARSENAL.size()):
		var candidate: WeaponDefinition = ARSENAL[(at + step) % ARSENAL.size()]
		if owns(candidate):
			equip(candidate)
			return true
	return false

func equip(next: WeaponDefinition) -> void:
	if next.id == definition.id:
		return
	interrupt_combat()
	_take(next, true)

func _take(next: WeaponDefinition, keep_current: bool) -> void:
	if keep_current:
		spare_magazines[definition.id] = magazine
	definition = next
	equipped = next.id
	magazine = int(spare_magazines.get(next.id, next.magazine))
	spare_magazines.erase(next.id)
	cooldown = 0.0
	ammo_changed.emit()
	weapon_changed.emit()

## Back in the hand that left the last scene, or on to the only gun owned.
## Checked every frame rather than at _ready: a scene may turn practice on, or
## a purchase may arrive, after the weapon has entered the tree.
func _settle() -> void:
	if equipped != definition.id:
		var carried: WeaponDefinition = _definition(equipped)
		if carried != null and owns(carried):
			# The static magazine already belongs to the gun carried over.
			definition = carried
			ammo_changed.emit()
			weapon_changed.emit()
			return
	if not owns(definition):
		for candidate: WeaponDefinition in ARSENAL:
			if owns(candidate):
				_take(candidate, false)
				return

func _definition(id: StringName) -> WeaponDefinition:
	for candidate: WeaponDefinition in ARSENAL:
		if candidate.id == id:
			return candidate
	return null

func reserve() -> int:
	if practice:
		return 999
	SupplyStock.ensure_loaded()
	return SupplyStock.ammo

func is_reloading() -> bool:
	return reload_left > 0.0

func muzzle() -> Vector3:
	return player.global_position + Vector3.UP * muzzle_height

## A held mouse button from a menu or a door must not resume the gun.
func interrupt_input() -> void:
	_aim_requires_release = Input.is_action_pressed(&"aim")
	_fire_requires_release = Input.is_action_pressed(&"fire")
	_lower()
	if _marker_mesh != null:
		_marker_mesh.clear_surfaces()

func interrupt_combat() -> void:
	# Reload transfers ammunition only on completion, so cancelling is atomic.
	reload_left = 0.0
	interrupt_input()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED and is_node_ready():
		interrupt_input()

func uses_locked_aim() -> bool:
	return not ControlScheme.is_tank() and (AimSettings.pad_target_lock if gamepad_aim else AimSettings.modern == AimSettings.Modern.LOCKED)

func _physics_process(delta: float) -> void:
	_settle()
	if _active_mode != AimSettings.modern or _active_tank != ControlScheme.is_tank():
		interrupt_input()
		_active_mode = AimSettings.modern
		_active_tank = ControlScheme.is_tank()
	if not Input.is_action_pressed(&"aim"):
		_aim_requires_release = false
	if not Input.is_action_pressed(&"fire"):
		_fire_requires_release = false
	cooldown = maxf(cooldown - delta, 0.0)
	if reload_left > 0.0:
		reload_left -= delta
		if reload_left <= 0.0:
			_finish_reload()
	var able: bool = player.can_use_weapon() and is_armed() and not Input.is_action_just_pressed("dodge")
	var want: bool = able and not _aim_requires_release and Input.is_action_pressed(&"aim")
	if want and not aiming:
		_raise()
	elif not want and aiming:
		_lower()
	if able and Input.is_action_just_pressed(&"reload"):
		reload()
	if player.can_use_weapon() and Input.is_action_just_pressed(&"switch_weapon"):
		switch_weapon()
	if aiming:
		if ControlScheme.is_tank():
			_aim_tank(delta)
		else:
			_aim_modern()
		var trigger: bool = Input.is_action_pressed(&"fire") if uses_locked_aim() or gamepad_aim else Input.is_action_just_pressed(&"fire")
		if trigger and not _fire_requires_release:
			fire()
	_draw_marker()
	_fade_tracer(delta)

func _raise() -> void:
	aiming = true
	gamepad_aim = GamepadControls.shared.gamepad_active
	_stick_cycle_ready = true
	# Absolute mouse aiming still reads the pointer; only its crosshair is hidden.
	# The weapon's laser is now the aiming feedback for every input device.
	_mouse_mode_before_aim = Input.mouse_mode
	aim_cursor_hidden = true
	if not _scripted():
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	heading = player.visual.rotation.y
	pitch = 0.0
	turn_input = 0.0
	_set_target(null)
	if ControlScheme.is_tank():
		if AimSettings.tank_auto_target:
			_set_target(_acquire(null))
	elif uses_locked_aim() and gamepad_aim and player.camera != null:
		# A pad has no pointer: start on the nearest visible target, then L1/R1
		# cycle in screen order. Walls and offscreen targets remain excluded.
		var found: Array[Hurtbox] = locked_candidates(player.camera)
		var nearest: Hurtbox = null
		for candidate: Hurtbox in found:
			if nearest == null or muzzle().distance_squared_to(candidate.aim_point()) < muzzle().distance_squared_to(nearest.aim_point()):
				nearest = candidate
		_set_target(nearest)
	elif AimSettings.modern == AimSettings.Modern.FREE and not gamepad_aim:
		_window_anchor = get_tree().root.get_mouse_position()
	elif uses_locked_aim() and player.camera != null:
		_set_target(_pick_locked(player.camera))

func _lower() -> void:
	if aim_cursor_hidden and not _scripted():
		Input.mouse_mode = _mouse_mode_before_aim
	aim_cursor_hidden = false
	_marker_mesh.clear_surfaces()
	aiming = false
	gamepad_aim = false
	pitch = 0.0
	turn_input = 0.0
	_set_target(null)

func _exit_tree() -> void:
	if aiming:
		_lower()

func _scripted() -> bool:
	return OS.get_cmdline_args().has("--script")

# --- Tank ---------------------------------------------------------------------

func _aim_tank(delta: float) -> void:
	var turn: float = Input.get_axis(&"move_right", &"move_left")
	var tilt: float = Input.get_axis(&"move_down", &"move_up")
	var stick: Vector2 = GamepadControls.shared.aim_vector() if gamepad_aim else Vector2.ZERO
	if not stick.is_zero_approx():
		turn = -stick.x
		tilt = -stick.y
	turn_input = turn if absf(turn) > 0.1 else 0.0
	# Taking the gun by hand drops the lock, as it does in the games this copies.
	if absf(turn) > 0.1 or absf(tilt) > 0.1:
		_set_target(null)
	if absf(turn) > 0.1:
		heading = wrapf(heading + turn * player.config.tank_turn_speed * delta, -PI, PI)
	pitch = tilt * TANK_TILT
	if AimSettings.tank_auto_target:
		if Input.is_action_just_pressed(&"next_target"):
			_set_target(_acquire(target))
		elif Input.is_action_just_pressed(&"lock_previous_target"):
			_set_target(_acquire(target, -1))
		elif target != null and not target.is_alive():
			# The one in front went down: the gun moves to the next one in sight.
			_set_target(_acquire(null))
	if target != null and not can_see(target):
		_set_target(null)
	if target != null:
		_face(target.aim_point())

# --- Modern -------------------------------------------------------------------

func _aim_modern() -> void:
	turn_input = 0.0
	var camera: Camera3D = player.camera
	if camera == null or not camera.is_inside_tree():
		return
	if AimSettings.modern == AimSettings.Modern.FREE and not gamepad_aim:
		_aim_free(camera)
		return
	if uses_locked_aim():
		_aim_locked(camera)
		return
	_aim_cursor(camera)
	if not gamepad_aim and AimSettings.modern == AimSettings.Modern.ASSISTED:
		var pulled: Hurtbox = _assist_candidate()
		if pulled != null:
			_set_target(pulled)
			_face(pulled.aim_point())

func _aim_cursor(camera: Camera3D) -> void:
	if gamepad_aim:
		_aim_gamepad(camera)
		return
	var screen: Vector2 = pointer_override if pointer_override != null else AimSolver.pointer(camera)
	_set_target(null)
	pitch = 0.0
	var under: Dictionary = _ray(camera.project_ray_origin(screen), camera.project_ray_origin(screen) + camera.project_ray_normal(screen) * 200.0, WORLD_MASK | Hurtbox.LAYER)
	if not under.is_empty() and under.collider is Hurtbox:
		# Pointing straight at something that can be hit aims at it, height and all.
		_face(under.position)
	else:
		var point: Variant = AimSolver.ground_point(camera, screen, player.global_position.y)
		if point != null:
			var to: Vector3 = (point as Vector3) - player.global_position
			to.y = 0.0
			if to.length() > 0.05:
				heading = AimSolver.yaw_of(to)

func _locked_valid() -> bool:
	return is_instance_valid(target) and target.is_inside_tree() and target.targetable and target.is_alive() and muzzle().distance_to(target.aim_point()) <= definition.reach

func _aim_locked(camera: Camera3D) -> void:
	if gamepad_aim:
		var stick := GamepadControls.shared.aim_vector()
		if absf(stick.x) < 0.25:
			_stick_cycle_ready = true
		elif absf(stick.x) > 0.55 and _stick_cycle_ready:
			_stick_cycle_ready = false
			_cycle_locked(camera, 1 if stick.x > 0.0 else -1)
	# Obstruction and camera cuts keep the lock; death/removal/range do not.
	if target != null and not _locked_valid():
		_set_target(null)
		_fire_requires_release = Input.is_action_pressed(&"fire")
	if Input.is_action_just_pressed(&"lock_next_target") or Input.is_action_just_pressed(&"next_target"):
		_cycle_locked(camera, 1)
	elif Input.is_action_just_pressed(&"lock_previous_target"):
		_cycle_locked(camera, -1)
	if _locked_valid():
		_face(target.aim_point())
	else:
		_aim_cursor(camera)

## Only acquire boards the player and the camera can actually see.
func locked_candidates(camera: Camera3D) -> Array[Hurtbox]:
	var found: Array[Hurtbox] = []
	var rect: Rect2 = camera.get_viewport().get_visible_rect()
	for candidate: Hurtbox in visible_targets():
		var point: Vector3 = candidate.aim_point()
		if not candidate.targetable or camera.is_position_behind(point) or not rect.has_point(camera.unproject_position(point)):
			continue
		var exclude: Array[RID] = [player.get_rid()]
		if candidate.body != null:
			exclude.append(candidate.body.get_rid())
		if _ray(camera.global_position, point, WORLD_MASK, exclude).is_empty():
			found.append(candidate)
	found.sort_custom(func(a: Hurtbox, b: Hurtbox) -> bool:
		return camera.unproject_position(a.aim_point()).x < camera.unproject_position(b.aim_point()).x)
	return found

func _pick_locked(camera: Camera3D) -> Hurtbox:
	var screen: Vector2 = pointer_override if pointer_override != null else AimSolver.pointer(camera)
	var rect: Rect2 = camera.get_viewport().get_visible_rect()
	if not rect.has_point(screen):
		return null
	var found: Array[Hurtbox] = locked_candidates(camera)
	var under: Dictionary = _ray(camera.project_ray_origin(screen), camera.project_ray_origin(screen) + camera.project_ray_normal(screen) * 200.0, WORLD_MASK | Hurtbox.LAYER)
	if not under.is_empty() and under.collider is Hurtbox and found.has(under.collider):
		return under.collider as Hurtbox
	var best: Hurtbox = null
	var distance: float = rect.size.y * LOCK_PICK_RADIUS
	for candidate: Hurtbox in found:
		var near: float = screen.distance_to(camera.unproject_position(candidate.aim_point()))
		if near < distance:
			distance = near
			best = candidate
	return best

func _cycle_locked(camera: Camera3D, step: int) -> void:
	var found: Array[Hurtbox] = locked_candidates(camera)
	if found.is_empty():
		return
	var index: int = found.find(target)
	_set_target(found[posmod(index + step, found.size())] if index >= 0 else (found[0] if step > 0 else found[-1]))

func lock_blocked() -> bool:
	return uses_locked_aim() and _locked_valid() and not can_see(target)

## The heading lives in world space and the mouse only nudges it, so a camera
## cut leaves the gun where it was and walking carries it along with Dylan.
func _aim_free(camera: Camera3D) -> void:
	var motion: Vector2
	if free_motion_override != null:
		motion = free_motion_override
	else:
		var now: Vector2 = get_tree().root.get_mouse_position()
		motion = AimSolver.window_delta_to_viewport(camera, now - _window_anchor)
		# The cursor is hidden and pulled back to where it started, so it never
		# runs into the window edge however far the reticle has turned.
		if not _scripted() and motion != Vector2.ZERO:
			get_tree().root.warp_mouse(_window_anchor)
	motion *= float(GeneralSettings.get_value("mouse_sensitivity"))
	if GeneralSettings.get_value("mouse_invert_y"):
		motion.y = -motion.y
	pitch = 0.0
	if motion.length() < 0.01:
		return
	var feet: Vector3 = player.global_position
	var origin: Vector2 = camera.unproject_position(feet)
	var ring: Vector2 = AimSolver.screen_heading(camera, feet, heading) * FREE_RADIUS
	var point: Variant = AimSolver.ground_point(camera, origin + ring + motion, feet.y)
	if point != null:
		var to: Vector3 = (point as Vector3) - feet
		to.y = 0.0
		if to.length() > 0.01:
			heading = AimSolver.yaw_of(to)

## The right stick describes a direction on screen, projected onto the floor
## around Dylan. Neutral keeps the last world heading through camera cuts.
func _aim_gamepad(camera: Camera3D) -> void:
	_set_target(null)
	pitch = 0.0
	var stick: Vector2 = GamepadControls.shared.aim_vector()
	if stick.is_zero_approx():
		return
	var feet: Vector3 = player.global_position
	var screen: Vector2 = camera.unproject_position(feet) + stick.normalized() * FREE_RADIUS
	var point: Variant = AimSolver.ground_point(camera, screen, feet.y)
	if point != null:
		var to: Vector3 = (point as Vector3) - feet
		to.y = 0.0
		if to.length() > 0.01:
			heading = AimSolver.yaw_of(to)

func _assist_candidate() -> Hurtbox:
	var best: Hurtbox = null
	var best_angle: float = ASSIST_CONE
	for candidate: Hurtbox in visible_targets():
		var angle: float = absf(angle_difference(heading, AimSolver.yaw_of(candidate.aim_point() - muzzle())))
		if angle < best_angle:
			best_angle = angle
			best = candidate
	return best

# --- Targets ------------------------------------------------------------------

func _face(point: Vector3) -> void:
	var to: Vector3 = point - muzzle()
	if Vector2(to.x, to.z).length() < 0.05:
		return
	heading = AimSolver.yaw_of(to)
	pitch = AimSolver.pitch_of(to)

func _set_target(next: Hurtbox) -> void:
	if (target == null and next == null) or (is_instance_valid(target) and next == target):
		return
	target = next
	target_changed.emit(target)

## Live targets in reach with nothing solid between them and Dylan's chest,
## nearest first.
func visible_targets() -> Array[Hurtbox]:
	var found: Array[Hurtbox] = []
	var origin: Vector3 = muzzle()
	for node: Node in get_tree().get_nodes_in_group(Hurtbox.GROUP):
		var candidate := node as Hurtbox
		if candidate == null or not candidate.is_alive() or not candidate.is_inside_tree():
			continue
		if origin.distance_to(candidate.aim_point()) > definition.reach:
			continue
		if can_see(candidate):
			found.append(candidate)
	found.sort_custom(func(a: Hurtbox, b: Hurtbox) -> bool:
		return origin.distance_squared_to(a.aim_point()) < origin.distance_squared_to(b.aim_point()))
	return found

func can_see(candidate: Hurtbox) -> bool:
	var exclude: Array[RID] = [player.get_rid()]
	if candidate.body != null:
		exclude.append(candidate.body.get_rid())
	return _ray(muzzle(), candidate.aim_point(), WORLD_MASK, exclude).is_empty()

## Nearest visible target, or the one after `after` when cycling.
func _acquire(after: Hurtbox, step: int = 1) -> Hurtbox:
	var found: Array[Hurtbox] = visible_targets()
	if found.is_empty():
		return null
	var index: int = found.find(after)
	return found[posmod(index + step, found.size())] if index >= 0 else (found[0] if step > 0 else found[-1])

func _ray(from: Vector3, to: Vector3, mask: int, exclude: Array[RID] = []) -> Dictionary:
	if exclude.is_empty():
		exclude = [player.get_rid()]
	var query := PhysicsRayQueryParameters3D.create(from, to, mask, exclude)
	query.collide_with_areas = true
	return get_world_3d().direct_space_state.intersect_ray(query)

# --- Firing -------------------------------------------------------------------

## Where a shot leaves for: at the locked target once the body faces it,
## otherwise straight along the body with the gun's tilt.
func shot_direction() -> Vector3:
	var body_yaw: float = player.visual.rotation.y
	if is_instance_valid(target) and target.is_inside_tree() and target.is_alive():
		var to: Vector3 = target.aim_point() - muzzle()
		if absf(angle_difference(body_yaw, AimSolver.yaw_of(to))) < LOCK_FIRE_TOLERANCE:
			return to.normalized()
	return AimSolver.direction(body_yaw, pitch)

func fire() -> bool:
	if not player.can_use_weapon() or not aiming or reload_left > 0.0 or cooldown > 0.0:
		return false
	if magazine <= 0:
		# Pulling the trigger on an empty gun reloads it, when there is anything
		# to reload with.
		reload()
		return false
	magazine -= 1
	cooldown = definition.fire_interval
	var origin: Vector3 = muzzle()
	var direction: Vector3 = shot_direction()
	var hit: Dictionary = _ray(origin, origin + direction * definition.reach, WORLD_MASK | Hurtbox.LAYER)
	var end: Vector3 = hit.position if not hit.is_empty() else origin + direction * definition.reach
	var struck: Object = hit.get("collider")
	if struck is Hurtbox:
		(struck as Hurtbox).take_hit(definition.damage, end, direction)
	last_shot = {"origin": origin, "end": end, "collider": struck, "direction": direction}
	_show_tracer(end)
	fired.emit(last_shot)
	ammo_changed.emit()
	return true

func reload() -> bool:
	if not player.can_use_weapon() or not is_armed() or reload_left > 0.0 or magazine >= definition.magazine or reserve() <= 0:
		return false
	reload_left = definition.reload_time
	return true

func _finish_reload() -> void:
	reload_left = 0.0
	var taken: int = mini(definition.magazine - magazine, reserve())
	if not practice:
		SupplyStock.ammo -= taken
	magazine += taken
	ammo_changed.emit()

# --- Feedback -----------------------------------------------------------------

## Use the shot's impact, with a visible beam starting at the imported gun tip.
## A second ray clips the offset tip's path too. A muzzle pushed through cover
## cannot project a laser from the far side of that cover.
func laser_trace() -> Dictionary:
	if not aiming or is_reloading():
		return {}
	var origin: Vector3 = muzzle()
	var start: Vector3 = muzzle_marker.global_position if is_instance_valid(muzzle_marker) and muzzle_marker.is_inside_tree() else origin
	if origin.distance_squared_to(start) > 0.0001 and not _ray(origin, start, WORLD_MASK).is_empty():
		return {}
	var end: Vector3 = origin + shot_direction() * definition.reach
	var hit: Dictionary = _ray(origin, end, WORLD_MASK | Hurtbox.LAYER)
	if not hit.is_empty():
		end = hit.position
	var tip_hit: Dictionary = _ray(start, end, WORLD_MASK | Hurtbox.LAYER)
	if not tip_hit.is_empty():
		hit = tip_hit
		end = tip_hit.position
	return {"start": start, "end": end, "hit": hit}

## Thin red ribbon and a small illuminated dot only on a real hit surface.
## Depth testing keeps both hidden behind scene geometry.
func _draw_marker() -> void:
	_marker_mesh.clear_surfaces()
	var camera: Camera3D = player.camera
	if not aiming or camera == null or not camera.is_inside_tree():
		return
	var trace: Dictionary = laser_trace()
	if trace.is_empty():
		return
	var start: Vector3 = trace.start
	var point: Vector3 = trace.end
	var hit: Dictionary = trace.hit
	var right: Vector3 = camera.global_basis.x
	var up: Vector3 = camera.global_basis.y
	var along: Vector3 = point - start
	if along.length_squared() < 0.0001:
		return
	var side: Vector3 = along.cross(camera.global_position - (start + point) * 0.5).normalized()
	if side.is_zero_approx():
		side = right
	# Measure in the internal viewport pixels so the retro downscale cannot
	# break a subpixel beam into disconnected dots.
	var width: float = _laser_pixel_size(camera, (start + point) * 0.5) * 0.7
	side *= width
	_marker_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _laser_material())
	for vertex: Vector3 in [start - side, start + side, point + side, start - side, point + side, point - side]:
		_marker_mesh.surface_add_vertex(vertex)
	_marker_mesh.surface_end()
	if hit.is_empty():
		return
	# Lift slightly off the collider to avoid z-fighting with its surface.
	point += (hit.normal as Vector3) * 0.012
	var radius: float = _laser_pixel_size(camera, point) * 1.4
	_marker_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _laser_material())
	for step: int in range(16):
		var a: float = TAU * step / 16.0
		var b: float = TAU * (step + 1) / 16.0
		_marker_mesh.surface_add_vertex(point)
		_marker_mesh.surface_add_vertex(point + (right * cos(a) + up * sin(a)) * radius)
		_marker_mesh.surface_add_vertex(point + (right * cos(b) + up * sin(b)) * radius)
	_marker_mesh.surface_end()

var _laser_paint: StandardMaterial3D

func _laser_pixel_size(camera: Camera3D, point: Vector3) -> float:
	var depth: float = maxf(camera.near, -camera.to_local(point).z)
	var pixels: float = 1.0
	if RetroFilter.enabled:
		var virtual_size: Vector2 = RetroFilter.PIXEL_STEPS[RetroFilter.pixel_step]["size"]
		if virtual_size.x > 0.0:
			pixels = maxf(1.0, camera.get_viewport().get_visible_rect().size.x / virtual_size.x)
	return camera.project_position(Vector2.ZERO, depth).distance_to(camera.project_position(Vector2(pixels, 0), depth))

func _laser_material() -> StandardMaterial3D:
	if _laser_paint == null:
		_laser_paint = StandardMaterial3D.new()
		_laser_paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_laser_paint.albedo_color = Color(1.0, 0.06, 0.035)
		_laser_paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _laser_paint

func _show_tracer(end: Vector3) -> void:
	var start: Vector3 = muzzle_marker.global_position if muzzle_marker != null and muzzle_marker.is_inside_tree() else muzzle()
	_tracer_mesh.clear_surfaces()
	_tracer_mesh.surface_begin(Mesh.PRIMITIVE_LINES, _line_material(Color(1.0, 0.9, 0.6)))
	_tracer_mesh.surface_add_vertex(start)
	_tracer_mesh.surface_add_vertex(end)
	_tracer_mesh.surface_end()
	_tracer_left = 0.06
	_flash.global_position = start
	_flash.light_energy = 3.0

func _fade_tracer(delta: float) -> void:
	if _tracer_left <= 0.0:
		return
	_tracer_left -= delta
	if _tracer_left <= 0.0:
		_tracer_mesh.clear_surfaces()
		_flash.light_energy = 0.0

var _materials: Dictionary = {}

func _line_material(color: Color) -> StandardMaterial3D:
	if not _materials.has(color):
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = color
		material.no_depth_test = true
		_materials[color] = material
	return _materials[color]
