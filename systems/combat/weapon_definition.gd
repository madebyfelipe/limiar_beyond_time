class_name WeaponDefinition
extends Resource
## Numbers of one firearm. Behaviour lives in PlayerWeapon; a second gun is a
## second resource, not a second script.

@export var display_name: String = "PISTOLA"
@export_range(0.0, 1000.0) var damage: float = 25.0
## Seconds between shots: the trigger is pulled once per press, never held.
@export_range(0.05, 3.0) var fire_interval: float = 0.32
@export_range(1, 100) var magazine: int = 15
@export_range(0.1, 10.0) var reload_time: float = 1.6
## Metres a shot travels before it stops counting.
@export_range(1.0, 200.0) var reach: float = 30.0
