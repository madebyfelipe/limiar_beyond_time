class_name PlayerConfig
extends Resource

## Walking and running track the captured stride (1,48 and 2,73 m/s at Dylan's
## 1,8 m), so the feet keep contact with the ground instead of sliding.
@export_range(0.1, 20.0) var walk_speed: float = 1.8
@export_range(0.1, 20.0) var run_speed: float = 3.8
## Firm ramps: the body reaches and leaves its speed in a couple of frames,
## which is what separates deliberate steps from gliding over ice.
@export_range(0.1, 100.0) var acceleration: float = 26.0
@export_range(0.1, 100.0) var deceleration: float = 40.0
@export_range(0.1, 100.0) var gravity: float = 20.0
@export_range(0.1, 30.0) var rotation_speed: float = 10.0
## Shared by keyboard/gamepad steering and manual aiming in tank mode.
## 3 rad/s is 172°/s: a half turn takes about 1,05 s at full input.
@export_range(0.5, 6.0) var tank_turn_speed: float = 3.0
## Backing up is a fraction of the walking speed, close to the 0,61 m/s the
## backward capture carries.
@export_range(0.1, 1.0) var tank_reverse_factor: float = 0.45
## With the gun up Dylan walks, never runs, at this fraction of his walk.
@export_range(0.1, 1.0) var aim_move_factor: float = 0.7
## How fast the body swings onto the aim. Faster than steering, so the gun
## arrives on a target in a fraction of a second, as in the games it follows.
@export_range(1.0, 40.0) var aim_turn_speed: float = 9.0

## The escape keeps its 2,24 m but takes 0,55 s instead of 0,32 s, so the
## captured roll, hop and sidesteps play at 2–2,7x instead of 3–4,7x and read
## as movements rather than snaps. Invulnerability keeps its 3/4 share and the
## gap between the end of one dodge and the next stays at about 0,5 s.
@export var dodge_speed: float = 4.07
@export var dodge_duration: float = 0.55
@export var dodge_invulnerability: float = 0.41
@export var dodge_cooldown: float = 1.05
@export var hit_invulnerability: float = 0.65
@export var hit_stun: float = 0.18
@export var med_kit_healing: float = 50.0
