class_name ChestStore
extends RefCounted
## What every supply crate in the game still holds. A crate starts with its
## authored contents below and keeps whatever Dylan had no room for, so going
## back to it later finds the rest. The guardhouse crate is also where the
## terminal delivers purchases.
##
## Static and carried inside SupplyStock.snapshot(), so a crate emptied in one
## visit stays emptied through doors, saves and LOAD GAME.

## The crate in the guardhouse save room, next to the terminal that fills it.
const DELIVERY := &"guardhouse"
## Contents of each crate before anyone opens it, as [item id, amount].
const AUTHORED: Dictionary = {
	&"guardhouse": [[&"handgun_ammo", 30], [&"shotgun_shells", 10]],
}

## crate id -> Array of {"id": StringName, "count": int}. A crate absent here
## has never been touched and still holds its authored contents.
static var crates: Dictionary = {}

static func contents(crate: StringName) -> Array:
	SupplyStock.ensure_loaded()
	if not crates.has(crate):
		var fresh: Array = []
		for pair: Array in AUTHORED.get(crate, []):
			fresh.append({"id": pair[0], "count": int(pair[1])})
		crates[crate] = fresh
	return crates[crate]

static func is_empty(crate: StringName) -> bool:
	return contents(crate).is_empty()

static func holds(crate: StringName, id: StringName) -> bool:
	for item: Dictionary in contents(crate):
		if item["id"] == id:
			return true
	return false

## Adds to a crate, merging with what of the same item is already there.
static func deliver(crate: StringName, id: StringName, amount: int) -> void:
	var held: Array = contents(crate)
	for item: Dictionary in held:
		if item["id"] == id:
			item["count"] = int(item["count"]) + amount
			return
	held.append({"id": id, "count": amount})

## Moves everything that fits into the case. Each result reads
## {"id", "taken", "left"}; what did not fit stays in the crate.
static func collect(crate: StringName) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var held: Array = contents(crate)
	for item: Dictionary in held.duplicate():
		var amount: int = int(item["count"])
		var left: int = Inventory.add(item["id"], amount)
		results.append({"id": item["id"], "taken": amount - left, "left": left})
		if left > 0:
			item["count"] = left
		else:
			held.erase(item)
	return results

static func snapshot() -> Dictionary:
	var result: Dictionary = {}
	for crate: StringName in crates:
		var items: Array = []
		for item: Dictionary in crates[crate]:
			items.append({"id": String(item["id"]), "count": int(item["count"])})
		result[String(crate)] = items
	return result

static func restore(value: Variant) -> void:
	crates.clear()
	var data: Dictionary = value if value is Dictionary else {}
	for crate: Variant in data:
		var items: Array = []
		for raw: Variant in (data[crate] if data[crate] is Array else []):
			if raw is Dictionary and Inventory.ITEMS.has(StringName(str(raw.get("id", "")))) and int(raw.get("count", 0)) > 0:
				items.append({"id": StringName(str(raw["id"])), "count": int(raw["count"])})
		crates[StringName(str(crate))] = items
