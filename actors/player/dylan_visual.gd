extends Node3D
## Motion capture from Mixamo, applied to the auto-rigged Dylan by
## tools/build_dylan_animations.gd. Physics remains on PlayerController.
## The captures face +Z and stand 0.976 tall; gameplay forward is -Z.
const CLIPS: AnimationLibrary = preload("res://assets/models/dylan_protagonist/mixamo/dylan_clips.res")
## Loaded by path rather than class name, so it works before the editor has
## rescanned the project.
const GRIP_POSE := preload("res://actors/player/grip_pose.gd")
const PISTOL_MODEL: PackedScene = preload("res://assets/models/weapons/pistol/pistol_lowpoly.glb")
const SHOTGUN_MODEL: PackedScene = preload("res://assets/models/weapons/shotgun/shotgun_lowpoly.glb")
const SOURCE_HEIGHT := 0.9761
## Ground speed each capture carries on its own, measured from the planted foot
## travelling backwards under the hips. Playback follows the real speed, so the
## feet keep contact with the floor instead of skating over it.
## The armed captures were re-measured on 2026-10-13 by the planted toe sliding
## under hips held still (tools/measure_clip_speeds.gd), the method that gives the
## walk its 1,48; the earlier armed figures ran 20-45 % low, so the legs spun
## too fast and the feet skated.
const NATIVE_SPEED := {&"walk": 1.48, &"run": 2.91, &"walk_back": 0.61,
	&"aim_walk": 2.51, &"aim_walk_back": 1.42, &"strafe_left": 2.06, &"strafe_right": 2.35,
	&"rifle_walk": 1.05, &"rifle_run": 4.0, &"rifle_walk_back": 0.92, &"rifle_aim_walk": 1.83,
	&"rifle_aim_walk_back": 1.84, &"rifle_strafe_left": 1.73, &"rifle_strafe_right": 1.74}
## Hip speed of the run-to-stop captures over their kept windows, in the
## capture's metres per second every STOP_STEP s, cut where the hips settle
## under 0,1 m/s (tools/measure_stop_profiles.gd). The clips freeze that
## travel; letting go of a run hands the curve to the body, which brakes
## along it, so the stop slides 0,8 m unarmed and 1,25 m with the shotgun at
## the rig's 1,84x scale instead of halting in 0,1 s.
const STOP_STEP := 0.05
const STOP_PROFILES := {
	&"run_stop": [1.58, 1.62, 1.65, 1.43, 0.99, 0.69, 0.49, 0.36, 0.26, 0.19, 0.15, 0.12, 0.09],
	&"rifle_run_stop": [1.51, 1.35, 1.25, 1.24, 1.24, 1.24, 1.24, 1.17, 0.89, 0.66, 0.55, 0.54, 0.51, 0.46, 0.38, 0.26, 0.20, 0.18, 0.10],
}
## Turn rate of the pivot capture, in rad/s, measured over its own window.
const NATIVE_TURN := 0.887
## Below this cosine the body is travelling backwards rather than forwards.
const BACKWARD_COSINE := -0.4
## The escape is always the backward hop. The roll and the two sidesteps stay
## in the clip library, unused, from when the escape followed the stick.
const DODGE_CLIP := &"dodge_back"
## Standing this long without input breaks the idle with a look around.
const IDLE_LOOK_AFTER := 8.0
## A one-shot (a stop, a flinch, a look around) gives way to locomotion as
## soon as the body moves faster than this.
const ONE_SHOT_RELEASE := 0.3
## Braking passes through walking speed for a frame or two; a stop still
## counts as the end of a run when the run was this recent.
const RUN_STOP_GRACE := 0.25
@export_range(0.5, 3.0) var target_height: float = 2.4
@onready var model: Node3D = $Model
@onready var skeleton: Skeleton3D = $Model/Skeleton3D
@onready var player: PlayerController = get_parent().get_parent()
## How quickly the aim stance blends in and out, per second.
const AIM_BLEND := 10.0
## The imported prop has its origin at the grip; the hand bone is the wrist.
const PISTOL_HAND_OFFSET := 0.035
## Where the gun sits in the right hand's bone space when it is not aimed:
## the aimed placement measured in that space (2026-10-13; it varies by 3 mm
## across headings), so lowering the gun leaves it exactly where the hand
## holds it. The basis carries the prop's scale relative to the rig, 0,542.
const PISTOL_GRIP := Transform3D(
	Basis(Vector3(0.0353, 0.1015, -0.5314), Vector3(0.5398, -0.0422, 0.0278), Vector3(-0.0361, -0.5309, -0.1039)),
	Vector3(-0.0063, 0.0401, -0.0365))
## The shotgun in the right hand's bone space: its placement on the aim
## capture, measured on 2026-10-13 and moved into the palm where the pistol's
## grip sits. Every long-gun capture keeps that hand on the grip, so the gun
## follows the hand in every clip. The wrist-to-wrist line it replaces swung
## the gun sideways in the low carry, where the hands sit side by side.
const SHOTGUN_GRIP := Transform3D(
	Basis(Vector3(0.0784, 0.1543, -0.5139), Vector3(0.5347, -0.0656, 0.0618), Vector3(-0.0445, -0.5157, -0.1617)),
	Vector3(-0.0063, 0.0401, -0.0365))
## Moves the shotgun in its own frame so its grip fills the palm: the palm
## (between the wrist and the middle knuckle) lands on the right face of the
## grip, the thumb comes over its left and the index finger reaches the guard.
## Measured on the low carry and the aim (2026-10-13); without it the hand
## closed 7-9 cm to the left of the gun.
const SHOTGUN_PALM_SHIFT := Vector3(-0.086, 0.047, 0.005)
## How the left hand holds the forend, in the gun's own frame (-Z out of the
## barrels, +X its right): the palm just under the forend's middle, the
## fingers wrapping up its right side and the thumb running forward along
## its left. The forend is 4 cm wide and spans z -0,155 to -0,345.
const SHOTGUN_SUPPORT_PALM := Vector3(0.0, 0.008, -0.25)
const SHOTGUN_SUPPORT_FINGERS := Vector3(0.85, 0.5, 0.0)
const SHOTGUN_SUPPORT_THUMB := Vector3(-0.2, 0.3, -1.0)
## How quickly the left hand settles on the forend or lets it go, per second.
const SUPPORT_BLEND := 8.0
const SUPPORT_HAND_POSE := preload("res://actors/player/support_hand_pose.gd")
## Closer than this, the barrel stops turning onto the aim point, so a target
## at the muzzle cannot swing the gun across the body.
const SHOTGUN_AIM_NEAREST := 1.5
var animator: AnimationPlayer
var interaction_active: bool = false
var locomotion: StringName = &"idle"
var aim_pose: AimPose
var support_hand: SkeletonModifier3D
var grip_pose: SkeletonModifier3D
var pistol: Node3D
var muzzle: Node3D
var shotgun: Node3D
var shotgun_muzzle: Node3D
var _hand: int = -1
var _support_hand: int = -1
## The transition or reaction playing over locomotion, if any.
var _one_shot: StringName = &""
var _idle_time: float = 0.0
var _since_run: float = INF

func _ready() -> void:
	model.scale = Vector3.ONE * (target_height / SOURCE_HEIGHT)
	model.rotation.y = PI
	animator = model.get_node("AnimationPlayer")
	animator.remove_animation_library(&"")
	animator.add_animation_library(&"", CLIPS)
	animator.play(&"idle")
	animator.advance(0)
	aim_pose = AimPose.new()
	aim_pose.influence = 0.0
	aim_pose.active = false
	skeleton.add_child(aim_pose)
	grip_pose = GRIP_POSE.new()
	grip_pose.setup(skeleton, CLIPS.get_animation(&"aim_idle") if CLIPS.has_animation(&"aim_idle") else Animation.new())
	skeleton.add_child(grip_pose)
	# Last, so the right hand and the gun it holds are final when it runs.
	support_hand = SUPPORT_HAND_POSE.new()
	support_hand.visual = self
	support_hand.influence = 0.0
	support_hand.active = false
	skeleton.add_child(support_hand)
	_hand = skeleton.find_bone("mixamorig_RightHand")
	pistol = PISTOL_MODEL.instantiate()
	pistol.name = "Pistol"
	pistol.top_level = true
	pistol.visible = false
	add_child(pistol)
	muzzle = pistol.find_child("Muzzle", true, false) as Node3D
	shotgun = SHOTGUN_MODEL.instantiate()
	shotgun.name = "Shotgun"
	shotgun.top_level = true
	shotgun.visible = false
	add_child(shotgun)
	shotgun_muzzle = shotgun.find_child("Muzzle", true, false) as Node3D
	_support_hand = skeleton.find_bone("mixamorig_LeftHand")
	# After the modifiers, so the gun sits in the hand the stance has placed.
	skeleton.skeleton_updated.connect(_place_pistol)
	player.damaged.connect(_on_damaged)

func _process(delta: float) -> void:
	_update_aim(delta)
	if player.is_dead():
		if animator.has_animation(&"death"):
			# Falls backwards once and stays down; the clip holds its last pose.
			if locomotion != &"death":
				locomotion = &"death"
				_one_shot = &""
				animator.speed_scale = 1.0
				animator.play(&"death", 0.1)
			return
		animator.pause()
		rotation.z = move_toward(rotation.z, -PI * 0.48, delta * 3.0)
		return
	if locomotion == &"death":
		# Revived by a reset: start over from the stance.
		locomotion = &""
	rotation.z = move_toward(rotation.z, 0.0, delta * 5.0)
	var tilt: bool = player.hit_stun_left > 0.0 and not animator.has_animation(&"hit")
	rotation.x = move_toward(rotation.x, 0.12 if tilt else 0.0, delta * 5.0)
	if interaction_active:
		return
	if player.dodge_left > 0.0:
		# The hop is aligned with the committed world-space direction: the
		# capture faces +Z and travels -Z. Rotating the visual never changes
		# the collision body or travel vector.
		if locomotion != DODGE_CLIP:
			locomotion = DODGE_CLIP
			animator.play(locomotion, 0.04)
		model.global_rotation.y = atan2(-player.dodge_direction.x, -player.dodge_direction.z)
		animator.speed_scale = 1.0
		animator.seek(CLIPS.get_animation(DODGE_CLIP).length * (1.0 - player.dodge_left / player.config.dodge_duration), true)
		return
	model.rotation.y = lerp_angle(model.rotation.y, PI, minf(1.0, delta * 18.0))
	var motion := Vector2(player.get_real_velocity().x, player.get_real_velocity().z)
	var speed: float = motion.length()
	var forward: Vector3 = player.facing()
	var base: StringName = _clip_for(motion, speed, Vector2(forward.x, forward.z))
	var next: StringName = _armed(base)
	_idle_time = _idle_time + delta if base == &"idle" else 0.0
	_since_run = 0.0 if base == &"run" and _one_shot == &"" else _since_run + delta
	# Let go of a run: the stop starts now, with the body braking along it.
	if _one_shot == &"" and base == &"run" and player.desired_direction.is_zero_approx() and not _aiming():
		var stop: StringName = _armed(&"run_stop")
		if animator.has_animation(stop) and STOP_PROFILES.has(stop):
			_brake_into(stop, speed)
	if _one_shot == &"" and base == &"idle":
		if _since_run < RUN_STOP_GRACE and locomotion != next and animator.has_animation(_armed(&"run_stop")):
			_play_one_shot(_armed(&"run_stop"), 0.1)
		elif _idle_time > IDLE_LOOK_AFTER and animator.has_animation(&"idle_look"):
			_idle_time = 0.0
			_play_one_shot(&"idle_look", 0.3)
	if _one_shot != &"":
		var holding: bool = animator.current_animation == _one_shot and animator.is_playing()
		if holding and (speed < ONE_SHOT_RELEASE or player.hit_stun_left > 0.0 or player.braking()):
			return
		_one_shot = &""
		locomotion = &""
	if next != locomotion:
		locomotion = next
		animator.play(next, 0.16)
	elif not animator.is_playing():
		animator.play(next, 0.16)
	animator.speed_scale = _rate_for(next, speed)

## Plays the stop clip at the run's own cadence (the faster of the rate that
## matches the body's speed and 1x, up to the run's cap) and hands its hip
## curve, at that rate and the rig's scale, to the body.
func _brake_into(stop: StringName, speed: float) -> void:
	var scale: float = skeleton.global_transform.basis.get_scale().x
	var profile := PackedFloat32Array()
	for value: float in STOP_PROFILES[stop]:
		profile.append(value * scale)
	var rate: float = clampf(speed / maxf(profile[0], 0.01), 1.0, 1.5)
	_play_one_shot(stop, 0.1)
	animator.speed_scale = rate
	player.brake_along(profile, STOP_STEP, rate)

## Plays a clip once over locomotion; _process hands back when it ends or
## when the body starts moving.
func _play_one_shot(clip: StringName, blend: float) -> void:
	_one_shot = clip
	locomotion = clip
	animator.speed_scale = 1.0
	animator.play(clip, blend)

func _on_damaged(_amount: float) -> void:
	if player.is_dead() or interaction_active or player.dodge_left > 0.0:
		return
	var clip: StringName = &"hit_aim" if _aiming() and animator.has_animation(&"hit_aim") else &"hit"
	if animator.has_animation(clip):
		_play_one_shot(clip, 0.05)

## Whether the gun in hand is held in both hands (the shotgun).
func _two_handed() -> bool:
	return player.weapon != null and player.weapon.definition.two_handed and player.weapon.is_armed()

## The two-handed version of a clip while the shotgun is in hand, when it
## exists. The Mixamo long-gun captures are the rifle ones, hence the prefix.
func _armed(clip: StringName) -> StringName:
	if _two_handed():
		var variant := StringName("rifle_" + clip)
		if animator.has_animation(variant):
			return variant
	return clip

func _aiming() -> bool:
	return player.can_use_weapon() and player.weapon != null and player.weapon.aiming and not interaction_active

func _update_aim(delta: float) -> void:
	var weapon: PlayerWeapon = player.weapon
	if weapon == null:
		return
	var two_handed: bool = _two_handed()
	weapon.muzzle_marker = shotgun_muzzle if two_handed else muzzle
	# The long-gun captures already raise it to the shoulder; the straight-arm
	# pistol stance is only laid over the one-handed gun.
	var goal: float = 1.0 if _aiming() and not two_handed else 0.0
	aim_pose.influence = move_toward(aim_pose.influence, goal, AIM_BLEND * delta)
	aim_pose.active = aim_pose.influence > 0.0
	if _aiming():
		aim_pose.direction = weapon.shot_direction()
	# The gun stays in the hand, lowered, whenever Dylan carries it.
	var armed: bool = weapon.is_armed()
	pistol.visible = armed and not two_handed
	shotgun.visible = armed and two_handed
	# The long-gun captures close the fingers themselves.
	grip_pose.active = armed and not two_handed
	# The left hand holds the forend whenever the shotgun is carried, not
	# through doors, cutscenes or the fall of a death.
	var holding: bool = armed and two_handed and not interaction_active and not player.is_dead()
	support_hand.influence = move_toward(support_hand.influence, 1.0 if holding else 0.0, SUPPORT_BLEND * delta)
	support_hand.active = support_hand.influence > 0.0

func _place_pistol() -> void:
	if _hand < 0 or not is_inside_tree():
		return
	if shotgun.visible:
		_place_shotgun()
		return
	if not pistol.visible:
		return
	var wrist: Transform3D = skeleton.global_transform * skeleton.get_bone_global_pose(_hand)
	var held: Transform3D = wrist * PISTOL_GRIP
	if aim_pose.influence <= 0.0:
		pistol.global_transform = held
		return
	var hand: Vector3 = wrist.origin
	var along: Vector3 = aim_pose.direction.normalized()
	var side: Vector3 = Vector3.UP if absf(along.dot(Vector3.UP)) < 0.95 else Vector3.FORWARD
	var prop_scale: float = target_height / 1.8
	var aimed := Transform3D(Basis.looking_at(along, side).scaled(Vector3.ONE * prop_scale), hand + along * PISTOL_HAND_OFFSET * prop_scale)
	pistol.global_transform = held.interpolate_with(aimed, aim_pose.influence)

## In the right hand as the capture holds it. Raised, the barrels then turn
## about the grip onto the point the shot will strike, so the laser leaves
## them straight instead of bending from the muzzle down to the chest's line.
## World point the left palm is brought to on the shotgun.
func support_point() -> Vector3:
	return shotgun.global_transform * SHOTGUN_SUPPORT_PALM

func _place_shotgun() -> void:
	var grip := Transform3D(SHOTGUN_GRIP.basis.orthonormalized().scaled(SHOTGUN_GRIP.basis.get_scale()), SHOTGUN_GRIP.origin)
	var held: Transform3D = skeleton.global_transform * skeleton.get_bone_global_pose(_hand) * grip * Transform3D(Basis.IDENTITY, SHOTGUN_PALM_SHIFT)
	if _aiming():
		var goal: Vector3 = player.weapon.aim_end()
		var barrel: Vector3 = (-held.basis.z).normalized()
		if held.origin.distance_to(goal) > SHOTGUN_AIM_NEAREST * target_height / 1.8:
			var onto: Vector3 = (goal - held.origin).normalized()
			var axis: Vector3 = barrel.cross(onto)
			if axis.length() > 0.0001:
				held.basis = Basis(axis.normalized(), barrel.signed_angle_to(onto, axis.normalized())) * held.basis
	shotgun.global_transform = held

func _clip_for(motion: Vector2, speed: float, forward: Vector2) -> StringName:
	if _aiming():
		return _aim_clip_for(motion, speed, forward)
	if speed < 0.08:
		# Standing still, but tank steering may be pivoting the body on the spot.
		if absf(player.turn_input) > 0.1:
			return &"turn_left" if player.turn_input > 0.0 else &"turn_right"
		return &"idle"
	if motion.normalized().dot(forward) < BACKWARD_COSINE:
		return &"walk_back"
	return &"run" if speed > player.config.walk_speed + 0.4 else &"walk"

## Legs while the gun is up: the pistol captures (stance, steps forward and
## back, strafes), each falling back to the unarmed cycle if it is missing.
func _aim_clip_for(motion: Vector2, speed: float, forward: Vector2) -> StringName:
	if speed < 0.08:
		if absf(player.turn_input) > 0.1:
			return &"turn_left" if player.turn_input > 0.0 else &"turn_right"
		return &"aim_idle" if animator.has_animation(&"aim_idle") else &"idle"
	var along: float = motion.normalized().dot(forward)
	if along < BACKWARD_COSINE:
		return &"aim_walk_back" if animator.has_animation(&"aim_walk_back") else &"walk_back"
	if along < 0.5:
		var side: float = motion.normalized().cross(forward)
		# Facing -Z, left is -X, where this cross product turns positive.
		var strafe: StringName = &"strafe_left" if side > 0.0 else &"strafe_right"
		if animator.has_animation(strafe):
			return strafe
	return &"aim_walk" if animator.has_animation(&"aim_walk") else &"walk"

func _rate_for(clip: StringName, speed: float) -> float:
	if str(clip).ends_with("idle"):
		return 1.0
	if clip == &"turn_left" or clip == &"turn_right":
		# The faster tank pivot needs 3,38x playback at full input.
		return clampf(absf(player.turn_input) * player.config.tank_turn_speed / NATIVE_TURN, 0.5, 4.0)
	return clampf(speed / NATIVE_SPEED.get(clip, NATIVE_SPEED[&"walk"]), 0.6, 2.0)

func play_door_interaction() -> void:
	interaction_active = true
	animator.speed_scale = 1.0
	animator.play(&"door_interact", 0.12)

## A cutscene gesture by clip name. Captures still to be brought from Mixamo
## (typing, a startled turn) fall back to `fallback`, so a scene can name the
## clip it wants today and pick it up as soon as the build tool adds it.
## Returns the clip actually played.
func play_scripted(clip: StringName, fallback: StringName = &"idle") -> StringName:
	var chosen: StringName = clip if animator.has_animation(clip) else fallback
	interaction_active = true
	animator.speed_scale = 1.0
	animator.play(chosen, 0.2)
	return chosen

func end_interaction() -> void:
	interaction_active = false
	_one_shot = &""
	_idle_time = 0.0
	locomotion = &"idle"
	animator.play(&"idle", 0.12)
