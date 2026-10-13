class_name SupplyStock
extends RefCounted
## Terminal account and everything Dylan carries. Purchases spend credits and
## are delivered to the guardhouse supply crate (ChestStore.DELIVERY); what he
## takes from a crate goes into the attaché case (Inventory). SAVE records the
## credits, the purchases, the case and every crate together, and doors carry
## the same snapshot.
const ITEMS: Array[Dictionary] = [
	{"name": "AMMO", "price": 300, "description": "30 HANDGUN ROUNDS", "item": &"handgun_ammo", "count": 30},
	{"name": "MED KIT", "price": 500, "description": "1 MED KIT", "item": &"med_kit", "count": 1},
	{"name": "WEAPON", "price": 1800, "description": "PISTOL", "item": &"pistol", "count": 1},
	{"name": "SHOTGUN", "price": 2200, "description": "SHOTGUN", "item": &"shotgun", "count": 1},
	{"name": "SHELLS", "price": 400, "description": "10 SHOTGUN SHELLS", "item": &"shotgun_shells", "count": 10},
]
static var credits: int = 2400
## Purchased at the terminal, whether or not it has left the crate yet. A gun
## is sold once; Dylan holds it only while it is in the case.
static var weapon: bool = false
static var shotgun: bool = false
static var loaded: bool = false

static func ensure_loaded() -> void:
	if not loaded:
		restore(SaveGame.read().get("supplies", {}))

static func restore(value: Variant) -> void:
	# First, so the case and crates below can read without reloading the file.
	loaded = true
	var data: Dictionary = value if value is Dictionary else {}
	credits = clampi(int(data.get("credits", 2400)), 0, 999999)
	weapon = bool(data.get("weapon", false))
	# Saves from before the shotgun replaced the rifle keep the long gun.
	shotgun = bool(data.get("shotgun", data.get("rifle", false)))
	ChestStore.restore(data.get("chests", {}))
	if data.has("case"):
		Inventory.restore(data["case"])
		return
	# A new game starts with an empty case. A save from before the case owned
	# its guns outright and shared one pool of rounds: those go straight in.
	Inventory.clear()
	if data.is_empty():
		return
	if weapon:
		Inventory.add(&"pistol", 1)
	if shotgun:
		Inventory.add(&"shotgun", 1)
	Inventory.add(&"med_kit", clampi(int(data.get("med_kits", 0)), 0, 99))
	Inventory.add(&"handgun_ammo", clampi(int(data.get("ammo", 90)), 0, 9999))

static func snapshot() -> Dictionary:
	ensure_loaded()
	return {"credits": credits, "weapon": weapon, "shotgun": shotgun, "case": Inventory.snapshot(), "chests": ChestStore.snapshot()}

static func reset() -> void:
	restore({})

static func available(index: int) -> bool:
	ensure_loaded()
	if index < 0 or index >= ITEMS.size():
		return false
	if credits < int(ITEMS[index]["price"]):
		return false
	match index:
		2: return not weapon
		3: return not shotgun
	return true

static func buy(index: int) -> bool:
	if not available(index):
		return false
	credits -= int(ITEMS[index]["price"])
	match index:
		2: weapon = true
		3: shotgun = true
	ChestStore.deliver(ChestStore.DELIVERY, ITEMS[index]["item"], int(ITEMS[index]["count"]))
	return true

static func quantity(index: int) -> String:
	ensure_loaded()
	match index:
		0: return "%d ROUNDS" % Inventory.count(&"handgun_ammo")
		1: return "%d KITS" % Inventory.count(&"med_kit")
		2: return "OWNED" if weapon else "NOT OWNED"
		3: return "OWNED" if shotgun else "NOT OWNED"
		4: return "%d SHELLS" % Inventory.count(&"shotgun_shells")
	return ""
