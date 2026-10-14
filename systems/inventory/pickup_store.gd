class_name PickupStore
extends RefCounted
## Which one-time pickups lying about the levels have been taken. Static and
## carried inside SupplyStock.snapshot(), so a pickup taken in one visit stays
## taken through doors, saves and LOAD GAME, as a crate's contents do.
##
## A restart is a fresh attempt, not a save: `rewind` puts back what was taken
## since the last record, and leaves alone what the record already holds.

## Pickup ids taken, used as a set.
static var collected: Dictionary = {}
## The ids the stored record holds: what a restart does not give back.
static var recorded: Dictionary = {}

static func is_collected(id: StringName) -> bool:
	SupplyStock.ensure_loaded()
	return collected.has(id)

static func collect(id: StringName) -> void:
	SupplyStock.ensure_loaded()
	collected[id] = true

static func snapshot() -> Array:
	var result: Array = []
	for id: StringName in collected:
		result.append(String(id))
	result.sort()
	return result

## Takes a stored list and keeps only what can be an id.
static func restore(value: Variant) -> void:
	collected = {}
	if value is Array:
		for id: Variant in value:
			if (id is String or id is StringName) and not str(id).is_empty():
				collected[StringName(id)] = true

## The live state is now what the record holds: after SAVE, LOAD GAME, the
## first read of the file and a new game.
static func mark_recorded() -> void:
	recorded = collected.duplicate()

## A restart of the level that owns these pickups: each goes back to what the
## record says about it.
static func rewind(ids: Array) -> void:
	for id: StringName in ids:
		if recorded.has(id):
			collected[id] = true
		else:
			collected.erase(id)
