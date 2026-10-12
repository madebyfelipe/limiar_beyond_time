class_name Health
extends Node
## Hit points of anything that can be hurt. Hurtboxes forward damage here, so a
## body with several hurtboxes (head, torso) still has one pool.

signal changed(current: float, maximum: float)
signal died

@export_range(1.0, 10000.0) var maximum: float = 100.0
var current: float

func _ready() -> void:
	current = maximum

func alive() -> bool:
	return current > 0.0

func apply(amount: float) -> void:
	if not alive() or amount <= 0.0:
		return
	current = maxf(current - amount, 0.0)
	changed.emit(current, maximum)
	if current <= 0.0:
		died.emit()

func restore() -> void:
	current = maximum
	changed.emit(current, maximum)

func heal(amount: float) -> bool:
	if not alive() or amount <= 0.0 or current >= maximum:
		return false
	current = minf(current + amount, maximum)
	changed.emit(current, maximum)
	return true
