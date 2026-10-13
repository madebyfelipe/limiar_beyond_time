class_name SupplyStock
extends RefCounted
## Terminal supplies. Purchases change real stock; SAVE records it with progress.
## Dylan consumes medical kits; the weapon reloads from the ammunition stock.
const ITEMS: Array[Dictionary] = [
	{"name": "AMMO", "price": 300, "description": "30 ROUNDS", "kind": "ammo"},
	{"name": "MED KIT", "price": 500, "description": "1 MED KIT", "kind": "med_kits"},
	{"name": "WEAPON", "price": 1800, "description": "PISTOL", "kind": "weapon"},
	{"name": "RIFLE", "price": 2200, "description": "RIFLE", "kind": "rifle"},
]
static var credits: int = 2400
static var ammo: int = 90
static var med_kits: int = 0
static var weapon: bool = false
static var rifle: bool = false
static var loaded: bool = false

static func ensure_loaded() -> void:
	if not loaded:
		loaded = true
		restore(SaveGame.read().get("supplies", {}))

static func restore(value: Variant) -> void:
	var data: Dictionary = value if value is Dictionary else {}
	credits = clampi(int(data.get("credits", 2400)), 0, 999999)
	ammo = clampi(int(data.get("ammo", 90)), 0, 9999)
	med_kits = clampi(int(data.get("med_kits", 0)), 0, 99)
	weapon = bool(data.get("weapon", false))
	rifle = bool(data.get("rifle", false))
	loaded = true

static func snapshot() -> Dictionary:
	ensure_loaded()
	return {"credits": credits, "ammo": ammo, "med_kits": med_kits, "weapon": weapon, "rifle": rifle}

static func reset() -> void:
	restore({})

static func available(index: int) -> bool:
	ensure_loaded()
	if index < 0 or index >= ITEMS.size():
		return false
	if credits < int(ITEMS[index]["price"]):
		return false
	match index:
		0: return ammo <= 9969
		1: return med_kits < 99
		2: return not weapon
	return not rifle

static func buy(index: int) -> bool:
	if not available(index):
		return false
	credits -= int(ITEMS[index]["price"])
	match index:
		0: ammo += 30
		1: med_kits += 1
		2: weapon = true
		3: rifle = true
	return true

static func quantity(index: int) -> String:
	match index:
		0: return "%d ROUNDS" % ammo
		1: return "%d KITS" % med_kits
		2: return "OWNED" if weapon else "NOT OWNED"
		3: return "OWNED" if rifle else "NOT OWNED"
	return ""
