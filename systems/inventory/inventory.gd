class_name Inventory
extends RefCounted
## Dylan's attaché case, in the Resident Evil 4 idiom: a grid of cells where
## every item takes a rectangle of its own size, can be turned a quarter and is
## arranged by hand. What the case holds is what Dylan has: a gun is in hand
## only while it is in the case, and reloads and med kits draw on its stacks.
##
## Static, like SupplyStock, so it crosses doors without an autoload. The case
## travels and is saved inside SupplyStock.snapshot(); this class only keeps
## the grid honest.

const COLUMNS := 10
const ROWS := 6
## Footprint in cells (unrotated) and how many of the item one place holds.
const ITEMS: Dictionary = {
	&"pistol": {"name": "PISTOL", "size": Vector2i(3, 2), "stack": 1, "kind": &"weapon"},
	&"shotgun": {"name": "SHOTGUN", "size": Vector2i(8, 2), "stack": 1, "kind": &"weapon"},
	&"handgun_ammo": {"name": "HANDGUN AMMO", "size": Vector2i(2, 1), "stack": 50, "kind": &"ammo"},
	&"shotgun_shells": {"name": "SHOTGUN SHELLS", "size": Vector2i(2, 1), "stack": 15, "kind": &"ammo"},
	&"med_kit": {"name": "MED KIT", "size": Vector2i(1, 2), "stack": 1, "kind": &"recovery"},
}

## One placed item: {"id": StringName, "count": int, "cell": Vector2i, "rotated": bool}.
static var entries: Array[Dictionary] = []
## Bumped on every change, so a menu can redraw without a signal on a static.
static var revision: int = 0

static func item_name(id: StringName) -> String:
	return String(ITEMS[id]["name"]) if ITEMS.has(id) else String(id).to_upper()

static func kind(id: StringName) -> StringName:
	return ITEMS[id]["kind"] if ITEMS.has(id) else &""

static func stack_limit(id: StringName) -> int:
	return int(ITEMS[id]["stack"]) if ITEMS.has(id) else 1

static func footprint(id: StringName, rotated: bool) -> Vector2i:
	var size: Vector2i = ITEMS[id]["size"]
	return Vector2i(size.y, size.x) if rotated else size

static func rect(entry: Dictionary) -> Rect2i:
	return Rect2i(entry["cell"], footprint(entry["id"], entry["rotated"]))

static func count(id: StringName) -> int:
	SupplyStock.ensure_loaded()
	var total: int = 0
	for entry: Dictionary in entries:
		if entry["id"] == id:
			total += int(entry["count"])
	return total

static func has(id: StringName) -> bool:
	return count(id) > 0

## The placed item covering this cell, or an empty dictionary.
static func entry_at(cell: Vector2i) -> Dictionary:
	SupplyStock.ensure_loaded()
	for entry: Dictionary in entries:
		if rect(entry).has_point(cell):
			return entry
	return {}

## Whether `id` fits with its corner on `cell`. `ignore` is the entry being
## carried by the menu, which does not block its own new place.
static func fits(id: StringName, cell: Vector2i, rotated: bool, ignore: Dictionary = {}, within: Array[Dictionary] = entries) -> bool:
	var area := Rect2i(cell, footprint(id, rotated))
	if area.position.x < 0 or area.position.y < 0 or area.end.x > COLUMNS or area.end.y > ROWS:
		return false
	for entry: Dictionary in within:
		if not is_same(entry, ignore) and rect(entry).intersects(area):
			return false
	return true

## First free place, row by row, upright before turned.
static func find_space(id: StringName, within: Array[Dictionary] = entries) -> Dictionary:
	for rotated: bool in [false, true]:
		for y: int in range(ROWS):
			for x: int in range(COLUMNS):
				if fits(id, Vector2i(x, y), rotated, {}, within):
					return {"cell": Vector2i(x, y), "rotated": rotated}
	return {}

## Puts up to `amount` of `id` in the case: existing stacks are topped up
## first, then new places are found. Returns how many did not fit.
static func add(id: StringName, amount: int) -> int:
	SupplyStock.ensure_loaded()
	var left: int = _store(id, amount, entries)
	if left != amount:
		revision += 1
	return left

## How many of `amount` would fit, without changing the case.
static func room_for(id: StringName, amount: int) -> int:
	SupplyStock.ensure_loaded()
	var trial: Array[Dictionary] = []
	for entry: Dictionary in entries:
		trial.append(entry.duplicate())
	return amount - _store(id, amount, trial)

static func _store(id: StringName, amount: int, within: Array[Dictionary]) -> int:
	if not ITEMS.has(id) or amount <= 0:
		return maxi(amount, 0)
	var limit: int = stack_limit(id)
	var left: int = amount
	for entry: Dictionary in within:
		if left > 0 and entry["id"] == id and int(entry["count"]) < limit:
			var moved: int = mini(limit - int(entry["count"]), left)
			entry["count"] = int(entry["count"]) + moved
			left -= moved
	while left > 0:
		var place: Dictionary = find_space(id, within)
		if place.is_empty():
			break
		var moved: int = mini(limit, left)
		within.append({"id": id, "count": moved, "cell": place["cell"], "rotated": place["rotated"]})
		left -= moved
	return left

## Removes up to `amount` of `id`, emptying the smallest stacks first so the
## case keeps its full ones. Returns how many were removed.
static func take(id: StringName, amount: int) -> int:
	SupplyStock.ensure_loaded()
	var owned: Array[Dictionary] = []
	for entry: Dictionary in entries:
		if entry["id"] == id:
			owned.append(entry)
	owned.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["count"]) < int(b["count"]))
	var taken: int = 0
	for entry: Dictionary in owned:
		if taken >= amount:
			break
		var moved: int = mini(int(entry["count"]), amount - taken)
		entry["count"] = int(entry["count"]) - moved
		taken += moved
		if int(entry["count"]) <= 0:
			entries.erase(entry)
	if taken > 0:
		revision += 1
	return taken

## Exactly `amount` of `id`, wherever it fits. For migrations and probes.
static func set_count(id: StringName, amount: int) -> void:
	take(id, count(id))
	add(id, amount)

## Places an entry somewhere else, turned or not. False leaves it where it was.
static func move(entry: Dictionary, cell: Vector2i, rotated: bool) -> bool:
	if not entries.has(entry) or not fits(entry["id"], cell, rotated, entry):
		return false
	entry["cell"] = cell
	entry["rotated"] = rotated
	revision += 1
	return true

static func clear() -> void:
	entries.clear()
	revision += 1

## Plain values only, so ConfigFile and the door carry write it verbatim.
static func snapshot() -> Array:
	var result: Array = []
	for entry: Dictionary in entries:
		result.append({"id": String(entry["id"]), "count": int(entry["count"]), "cell": entry["cell"], "rotated": bool(entry["rotated"])})
	return result

## Rebuilds the case from a snapshot. An entry that is unknown, overlapping or
## off the grid is re-placed wherever it fits instead of being trusted.
static func restore(value: Variant) -> void:
	entries.clear()
	var stray: Array[Dictionary] = []
	for raw: Variant in (value if value is Array else []):
		if not raw is Dictionary:
			continue
		var id := StringName(str(raw.get("id", "")))
		if not ITEMS.has(id):
			continue
		var amount: int = clampi(int(raw.get("count", 1)), 1, stack_limit(id))
		var cell: Variant = raw.get("cell", Vector2i(-1, -1))
		var rotated: bool = bool(raw.get("rotated", false))
		if cell is Vector2i and fits(id, cell, rotated):
			entries.append({"id": id, "count": amount, "cell": cell, "rotated": rotated})
		else:
			stray.append({"id": id, "count": amount})
	for item: Dictionary in stray:
		add(item["id"], item["count"])
	revision += 1
