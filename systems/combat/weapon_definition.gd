class_name WeaponDefinition
extends Resource
## Numbers of one firearm. Behaviour lives in PlayerWeapon; a second gun is a
## second resource, not a second script.

## Stable name used by saves, the shop and the visual.
@export var id: StringName = &"pistol"
@export var display_name: String = "PISTOL"
## Inventory item the gun reloads from; each gun has its own ammunition.
@export var ammo_item: StringName = &"handgun_ammo"
@export_range(0.0, 1000.0) var damage: float = 25.0
## Seconds between shots: the trigger is pulled once per press, never held.
@export_range(0.05, 3.0) var fire_interval: float = 0.32
@export_range(1, 100) var magazine: int = 15
@export_range(0.1, 10.0) var reload_time: float = 1.6
## Metres a shot travels before it stops counting.
@export_range(1.0, 200.0) var reach: float = 30.0
## Held in both hands: the visual uses the two-handed (rifle) captures.
@export var two_handed: bool = false
## Rays per trigger pull, each dealing `damage`: one for a bullet, a spread of
## shot for the shotgun. The first always flies straight down the aim.
@export_range(1, 16) var pellets: int = 1
## Half-angle of the cone the other pellets scatter in.
@export_range(0.0, 30.0) var spread_degrees: float = 0.0
