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
## Tank steering: how fast holding left/right turns Dylan on the spot. 1,5 rad/s
## is 86°/s, so a half turn takes about two seconds, and it keeps the pivot
## capture (0,887 rad/s on its own) inside a believable playback rate.
@export_range(0.5, 6.0) var tank_turn_speed: float = 1.5
## Backing up is a fraction of the walking speed, close to the 0,61 m/s the
## backward capture carries.
@export_range(0.1, 1.0) var tank_reverse_factor: float = 0.45
